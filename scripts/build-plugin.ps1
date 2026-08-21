param(
    [string]$Plugin = 'AiCoding',
    [ValidateSet('Development', 'Release')]
    [string]$Configuration = 'Development',
    [switch]$Clean,
    [switch]$Verify,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

function Get-RepoRoot {
    $root = (& git -C $PSScriptRoot rev-parse --show-toplevel).Trim()
    if (-not $root) { throw 'Not inside a Git repository.' }
    return $root
}

function Test-TextFileForStableHash([string]$Path) {
    $name = [System.IO.Path]::GetFileName($Path).ToLowerInvariant()
    $ext = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()
    return ($name -eq '.generated') -or ($ext -in @('.md', '.json', '.html', '.ps1', '.py', '.toml', '.yaml', '.yml', '.txt'))
}

function Normalize-Text([string]$Text) {
    return ($Text.TrimStart([char]0xFEFF) -replace "`r`n", "`n" -replace "`r", "`n")
}

function Get-FileSha256([string]$Path) {
    if (Test-TextFileForStableHash $Path) {
        return Get-StringSha256 (Normalize-Text ([System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)))
    }
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

function Get-StringSha256([string]$Text) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()
}

function Get-TreeDigest([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    $base = (Resolve-Path -LiteralPath $Path).Path
    $filesByRelativePath = @{}
    Get-ChildItem -LiteralPath $base -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($base.Length).TrimStart('\') -replace '\\','/'
        $filesByRelativePath[$rel] = $_.FullName
    }
    $relativePaths = [string[]]@($filesByRelativePath.Keys)
    [Array]::Sort($relativePaths, [System.StringComparer]::Ordinal)
    $items = foreach ($rel in $relativePaths) {
        "$rel=$(Get-FileSha256 $filesByRelativePath[$rel])"
    }
    return Get-StringSha256 (($items -join "`n") + "`n")
}

function Normalize-GeneratedTextFiles([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return }
    Get-ChildItem -LiteralPath $Path -Recurse -File | Where-Object { Test-TextFileForStableHash $_.FullName } | ForEach-Object {
        $text = Normalize-Text ([System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8))
        [System.IO.File]::WriteAllText($_.FullName, $text, (New-Object System.Text.UTF8Encoding $false))
    }
}

function Copy-SkillSource($RepoRoot, $SourceRel, $TargetDir, [bool]$RootOnly) {
    $src = Join-Path $RepoRoot $SourceRel
    if (-not (Test-Path -LiteralPath $src)) { throw "Skill source not found: $SourceRel" }
    New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
    if ($RootOnly) {
        Get-ChildItem -LiteralPath $src -File | Where-Object { $_.Name -notlike '*.bak*' -and $_.Extension -ne '.zip' } | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $TargetDir $_.Name) -Force
        }
    } else {
        Copy-Item -Path (Join-Path $src '*') -Destination $TargetDir -Recurse -Force
    }
    Get-ChildItem -LiteralPath $TargetDir -Recurse -Force -File | Where-Object {
        $_.FullName -match '\\.git\\' -or $_.FullName -match '__pycache__' -or $_.Name -like '*.bak*' -or $_.Extension -eq '.zip'
    } | Remove-Item -Force
}

function Set-SkillName([string]$SkillDir, [string]$Name) {
    $skillFile = Join-Path $SkillDir 'SKILL.md'
    if (-not (Test-Path -LiteralPath $skillFile)) { throw "Missing SKILL.md in $SkillDir" }
    $text = ([System.IO.File]::ReadAllText($skillFile, [System.Text.Encoding]::UTF8)).TrimStart([char]0xFEFF)
    if ($text -notmatch '(?m)^name:\s*[^\r\n]+\s*$') { throw "Missing frontmatter name in $skillFile" }
    $text = $text -replace '(?m)^name:\s*[^\r\n]+\s*$', "name: $Name"
    [System.IO.File]::WriteAllText($skillFile, $text, (New-Object System.Text.UTF8Encoding $false))
}

function Get-SourceDirty([string]$RepoRoot) {
    $lines = @(& git -C $RepoRoot status --porcelain)
    foreach ($line in $lines) {
        $normalized = $line -replace '\\','/'
        if ($normalized -match '^.. plugins/AiCoding/skills(?:/|$)' -or
            $normalized -match '^.. plugins/AiCoding/BUILDINFO\.json$') {
            continue
        }
        return $true
    }
    return $false
}

$repoRoot = Get-RepoRoot
$configPath = Join-Path $repoRoot 'config/aicoding-plugin-pack.json'
$config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
$pluginPath = Join-Path $repoRoot $config.plugin.path
$skillsTarget = Join-Path $pluginPath 'skills'
$stagingRoot = Join-Path $repoRoot ".build/$Plugin/staging"
$stagingSkills = Join-Path $stagingRoot 'skills'

$actions = @(
    "Read $configPath",
    "Generate skills into $($config.plugin.path)/skills",
    "Generate $($config.plugin.path)/BUILDINFO.json"
)
if ($DryRun) {
    [pscustomobject]@{ plugin=$config.plugin.name; configuration=$Configuration; actions=$actions } | ConvertTo-Json -Depth 5
    exit 0
}

if ($Configuration -eq 'Release' -and (Get-SourceDirty $repoRoot)) {
    throw 'Release build requires a clean source tree excluding generated plugin outputs.'
}

if (Test-Path -LiteralPath $stagingRoot) { Remove-Item -LiteralPath $stagingRoot -Recurse -Force }
New-Item -ItemType Directory -Force -Path $stagingSkills | Out-Null

foreach ($entry in $config.skills) {
    if ($entry.enabled -eq $false) { continue }
    if ($entry.target -notmatch '^aicoding-[a-z0-9][a-z0-9-]*$') { throw "Plugin skill target must use aicoding- prefix: $($entry.target)" }
    $targetDir = Join-Path $stagingSkills $entry.target
    $rootOnly = $false
    if ($entry.PSObject.Properties.Name -contains 'rootOnly') { $rootOnly = [bool]$entry.rootOnly }
    Copy-SkillSource $repoRoot $entry.source $targetDir $rootOnly
    Set-SkillName $targetDir $entry.target
}

Normalize-GeneratedTextFiles $stagingSkills

$generatedMarker = @"
Generated by scripts/build-plugin.ps1.
Do not edit files under this directory manually.
Source mapping: config/aicoding-plugin-pack.json
"@
[System.IO.File]::WriteAllText((Join-Path $stagingSkills '.generated'), (Normalize-Text $generatedMarker), (New-Object System.Text.UTF8Encoding $false))

if (Test-Path -LiteralPath $skillsTarget) { Remove-Item -LiteralPath $skillsTarget -Recurse -Force }
Move-Item -LiteralPath $stagingSkills -Destination $skillsTarget
if (Test-Path -LiteralPath $stagingRoot) { Remove-Item -LiteralPath $stagingRoot -Recurse -Force }

$sourceCommit = (& git -C $repoRoot rev-parse HEAD).Trim()
$sourceTag = (@(& git -C $repoRoot tag --points-at HEAD) | Select-Object -First 1)
$commitTime = (& git -C $repoRoot show -s --format=%cI HEAD).Trim()
$pluginManifest = Join-Path $pluginPath '.codex-plugin/plugin.json'
$hooksDir = Join-Path $pluginPath 'hooks'
$buildInfo = [ordered]@{
    pluginName = $config.plugin.name
    pluginVersion = (Get-Content -Raw -LiteralPath $pluginManifest | ConvertFrom-Json).version
    sourceRepository = 'JiaxI2/Codex-Skills'
    sourceCommit = $sourceCommit
    sourceTag = if ($sourceTag) { $sourceTag.Trim() } else { $null }
    buildTimestampUtc = ([datetimeoffset]::Parse($commitTime).UtcDateTime.ToString('o'))
    buildInfoModel = 'non-self-referential: sourceCommit is the input HEAD before this generated BUILDINFO is committed; BUILDINFO is excluded from package digests'
    packManifestHash = Get-FileSha256 $configPath
    pluginManifestHash = Get-FileSha256 $pluginManifest
    skillsDigest = Get-TreeDigest $skillsTarget
    hooksDigest = Get-TreeDigest $hooksDir
    dirtySource = Get-SourceDirty $repoRoot
    generated = @('plugins/AiCoding/skills', 'plugins/AiCoding/BUILDINFO.json')
    manual = @('plugins/AiCoding/.codex-plugin/plugin.json', 'plugins/AiCoding/hooks', 'plugins/AiCoding/README.md', 'config/aicoding-plugin-pack.json', 'scripts/build-plugin.ps1', 'scripts/verify-plugin.ps1')
}
$buildInfo | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $pluginPath 'BUILDINFO.json') -Encoding utf8 -NoNewline

if ($Verify) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repoRoot 'scripts/verify-plugin.ps1') -PluginPath $pluginPath
}
