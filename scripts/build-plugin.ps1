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
    $stream = [System.IO.File]::OpenRead($Path)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-', '').ToLowerInvariant()
    }
    finally {
        $stream.Dispose()
        $sha.Dispose()
    }
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

function Resolve-ContainedPath([string]$Base, [string]$Relative) {
    if ([string]::IsNullOrWhiteSpace($Relative) -or [System.IO.Path]::IsPathRooted($Relative)) {
        throw "Expected a relative source path: $Relative"
    }
    $basePath = [System.IO.Path]::GetFullPath($Base).TrimEnd([char[]]'\/')
    $fullPath = [System.IO.Path]::GetFullPath((Join-Path $basePath $Relative))
    if ($fullPath -ne $basePath -and -not $fullPath.StartsWith($basePath + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Source path escapes its root: $Relative"
    }
    return $fullPath
}

function Resolve-PackEntries($RepoRoot, $Config) {
    $entries = New-Object 'System.Collections.Generic.List[object]'
    foreach ($entry in $Config.skills) {
        if ($entry.enabled -ne $false) { $entries.Add($entry) }
    }
    foreach ($kit in $Config.skillKits) {
        if ($kit.enabled -eq $false) { continue }
        $kitPath = Resolve-ContainedPath $RepoRoot $kit.source
        $kitConfig = [System.IO.File]::ReadAllText($kitPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
        if ($kitConfig.schemaVersion -notin @(1, 2)) { throw "Unsupported skillkit schema: $($kit.source)" }
        $kitRoot = Split-Path -Parent $kitPath
        $members = @($kitConfig.skills | Where-Object { $_.enabled -ne $false })
        if ($kitConfig.schemaVersion -eq 2) {
            $runtimeSkill = [string]$kitConfig.runtimeSkill
            $runtimeEntries = @($members | Where-Object { $_.target -eq $runtimeSkill -and $_.source -eq '.' -and $_.entrypoint -eq 'SKILL.md' })
            if ($runtimeEntries.Count -ne 1) { throw "Single-entry kit requires one root SKILL.md: $($kit.source)" }
            $memberIds = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
            foreach ($member in $members) {
                if ($member.target -notmatch '^aicoding-[a-z0-9][a-z0-9-]*$' -or -not $memberIds.Add($member.target)) {
                    throw "Invalid or duplicate kit capability: $($member.target)"
                }
                $memberRoot = Resolve-ContainedPath $kitRoot $member.source
                $expectedEntrypoint = if ($member.target -eq $runtimeSkill) { 'SKILL.md' } else { 'GUIDE.md' }
                if ($member.entrypoint -ne $expectedEntrypoint -or
                    -not (Test-Path -LiteralPath (Join-Path $memberRoot $expectedEntrypoint) -PathType Leaf)) {
                    throw "Missing or invalid kit entrypoint: $($member.source)/$expectedEntrypoint"
                }
            }
            $nestedSkills = @(Get-ChildItem -LiteralPath $kitRoot -Recurse -Filter SKILL.md -File | Where-Object { $_.DirectoryName -ne $kitRoot })
            if ($nestedSkills.Count -ne 0) { throw "Single-entry kit contains nested SKILL.md: $($kit.source)" }
            $members = $runtimeEntries
        }
        foreach ($entry in $members) {
            $sourcePath = Resolve-ContainedPath $kitRoot $entry.source
            $sourceRel = $sourcePath.Substring($RepoRoot.Length).TrimStart([char[]]'\/') -replace '\\','/'
            $entries.Add([pscustomobject]@{
                source = $sourceRel; target = $entry.target
                rootOnly = [bool]$entry.rootOnly; include = $entry.include
            })
        }
    }
    $targets = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($entry in $entries) {
        if ($entry.target -notmatch '^aicoding-[a-z0-9][a-z0-9-]*$') { throw "Plugin skill target must use aicoding- prefix: $($entry.target)" }
        if (-not $targets.Add($entry.target)) { throw "Duplicate plugin skill target: $($entry.target)" }
        $sourcePath = Resolve-ContainedPath $RepoRoot $entry.source
        if (-not (Test-Path -LiteralPath (Join-Path $sourcePath 'SKILL.md') -PathType Leaf)) { throw "Missing skill source: $($entry.source)" }
        if ($entry.rootOnly -and $null -ne $entry.include -and @($entry.include).Count -gt 0) { throw "rootOnly and include are mutually exclusive: $($entry.source)" }
        foreach ($item in $entry.include) {
            $includePath = Resolve-ContainedPath $sourcePath $item
            if ($includePath -eq $sourcePath -or -not (Test-Path -LiteralPath $includePath)) { throw "Invalid skill include: $($entry.source)/$item" }
        }
    }
    return $entries.ToArray()
}

function Copy-SkillSource($RepoRoot, $SourceRel, $TargetDir, [bool]$RootOnly, $IncludePaths) {
    $src = Join-Path $RepoRoot $SourceRel
    if (-not (Test-Path -LiteralPath $src)) { throw "Skill source not found: $SourceRel" }
    New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
    if ($null -ne $IncludePaths -and @($IncludePaths).Count -gt 0) {
        foreach ($item in $IncludePaths) {
            $includePath = Resolve-ContainedPath $src $item
            $destination = Resolve-ContainedPath $TargetDir $item
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination) | Out-Null
            Copy-Item -LiteralPath $includePath -Destination $destination -Recurse -Force
        }
    } elseif ($RootOnly) {
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
    $lines = @(& git -C $RepoRoot -c core.quotepath=false status --porcelain)
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
$buildMutex = [System.Threading.Mutex]::new($false, ('CodexSkillsBuild_' + (Get-StringSha256 ($repoRoot.ToLowerInvariant())).Substring(0, 24)))
$buildLockAcquired = $false
try {
try { $buildLockAcquired = $buildMutex.WaitOne(30000) }
catch [System.Threading.AbandonedMutexException] { $buildLockAcquired = $true }
if (-not $buildLockAcquired) { throw 'Timed out waiting for the repository plugin build lock.' }
$configPath = Join-Path $repoRoot 'config/aicoding-plugin-pack.json'
$config = [System.IO.File]::ReadAllText($configPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$packEntries = @(Resolve-PackEntries $repoRoot $config)
$pluginPath = Resolve-ContainedPath $repoRoot $config.plugin.path
$skillsTarget = Resolve-ContainedPath $pluginPath 'skills'
$stagingRoot = Resolve-ContainedPath $repoRoot ".build/$Plugin/staging"
$stagingSkills = Join-Path $stagingRoot 'skills'

$actions = @(
    "Read $configPath",
    "Generate skills into $($config.plugin.path)/skills",
    "Generate $($config.plugin.path)/BUILDINFO.json"
)
if ($DryRun) {
    [pscustomobject]@{ plugin=$config.plugin.name; configuration=$Configuration; actions=$actions; skillCount=$packEntries.Count; skills=$packEntries } | ConvertTo-Json -Depth 6
    exit 0
}

if ($Configuration -eq 'Release' -and (Get-SourceDirty $repoRoot)) {
    throw 'Release build requires a clean source tree excluding generated plugin outputs.'
}

if (Test-Path -LiteralPath $stagingRoot) { Remove-Item -LiteralPath $stagingRoot -Recurse -Force }
New-Item -ItemType Directory -Force -Path $stagingSkills | Out-Null

foreach ($entry in $packEntries) {
    $targetDir = Join-Path $stagingSkills $entry.target
    $rootOnly = $false
    if ($entry.PSObject.Properties.Name -contains 'rootOnly') { $rootOnly = [bool]$entry.rootOnly }
    Copy-SkillSource $repoRoot $entry.source $targetDir $rootOnly $entry.include
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
$packInputs = [ordered]@{ 'config/aicoding-plugin-pack.json' = (Get-FileSha256 $configPath) }
foreach ($kit in $config.skillKits) {
    if ($kit.enabled -ne $false) { $packInputs[$kit.source] = Get-FileSha256 (Resolve-ContainedPath $repoRoot $kit.source) }
}
$buildInfo = [ordered]@{
    pluginName = $config.plugin.name
    pluginVersion = (Get-Content -Raw -LiteralPath $pluginManifest | ConvertFrom-Json).version
    sourceRepository = 'JiaxI2/Codex-Skills'
    sourceCommit = $sourceCommit
    sourceTag = if ($sourceTag) { $sourceTag.Trim() } else { $null }
    buildTimestampUtc = ([datetimeoffset]::Parse($commitTime).UtcDateTime.ToString('o'))
    buildInfoModel = 'non-self-referential: sourceCommit is the input HEAD before this generated BUILDINFO is committed; BUILDINFO is excluded from package digests'
    packManifestHash = Get-FileSha256 $configPath
    packInputHashes = $packInputs
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
    if ($LASTEXITCODE -ne 0) { throw 'Generated plugin verification failed.' }
}
}
finally {
    if ($buildLockAcquired) { $buildMutex.ReleaseMutex() }
    $buildMutex.Dispose()
}
