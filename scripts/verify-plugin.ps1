param(
    [string]$PluginPath = 'plugins/AiCoding',
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
$errors = New-Object System.Collections.Generic.List[string]

function Add-Err([string]$Message) { $script:errors.Add($Message) | Out-Null }
function Read-FrontmatterName([string]$SkillFile) {
    $text = Get-Content -Raw -LiteralPath $SkillFile
    $match = [regex]::Match($text, '(?m)^name:\s*([^\r\n]+)\s*$')
    if (-not $match.Success) { return $null }
    return $match.Groups[1].Value.Trim().Trim('"').Trim("'")
}
function Has-AbsolutePersonalPath([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $files = @(Get-ChildItem -LiteralPath $Path -Recurse -File -ErrorAction SilentlyContinue)
    if ($files.Count -eq 0) { return $false }
    $hits = @($files | Select-String -Pattern 'C:\\Users\\24322|F:\\Study\\AI\\AiCoding' -ErrorAction SilentlyContinue)
    return $hits.Count -gt 0
}

$repoRoot = (& git -C $PSScriptRoot rev-parse --show-toplevel).Trim()
if (-not [System.IO.Path]::IsPathRooted($PluginPath)) { $PluginPath = Join-Path $repoRoot $PluginPath }
$manifestPath = Join-Path $PluginPath '.codex-plugin/plugin.json'
$skillsPath = Join-Path $PluginPath 'skills'
$hooksPath = Join-Path $PluginPath 'hooks/hooks.json'
$buildInfoPath = Join-Path $PluginPath 'BUILDINFO.json'

if (-not (Test-Path -LiteralPath $manifestPath)) { Add-Err "Missing plugin manifest: $manifestPath" } else {
    $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
    if ($manifest.name -ne 'aicoding') { Add-Err "plugin.json name must be aicoding." }
    if ($manifest.skills -ne './skills/') { Add-Err "plugin.json skills must be ./skills/." }
}
if (-not (Test-Path -LiteralPath $hooksPath)) { Add-Err "Missing hooks/hooks.json." } else { Get-Content -Raw -LiteralPath $hooksPath | ConvertFrom-Json | Out-Null }
if (-not (Test-Path -LiteralPath $buildInfoPath)) { Add-Err "Missing BUILDINFO.json." } else { Get-Content -Raw -LiteralPath $buildInfoPath | ConvertFrom-Json | Out-Null }
if (-not (Test-Path -LiteralPath (Join-Path $skillsPath '.generated'))) { Add-Err "Missing generated marker in plugin skills directory." }

if (Test-Path -LiteralPath $skillsPath) {
    $skillDirs = @(Get-ChildItem -LiteralPath $skillsPath -Directory)
    foreach ($dir in $skillDirs) {
        if ($dir.Name -like 'obsidian-*') { Add-Err "Obsidian skill must not be packaged: $($dir.Name)" }
        if ($dir.Name -notmatch '^aicoding-[a-z0-9][a-z0-9-]*$') { Add-Err "Plugin skill lacks aicoding- prefix: $($dir.Name)" }
        $skillFile = Join-Path $dir.FullName 'SKILL.md'
        if (-not (Test-Path -LiteralPath $skillFile)) { Add-Err "Missing SKILL.md: $($dir.Name)"; continue }
        $name = Read-FrontmatterName $skillFile
        if ($name -ne $dir.Name) { Add-Err "Skill name mismatch: dir=$($dir.Name), frontmatter=$name" }
        $nestedSkills = @(Get-ChildItem -LiteralPath $dir.FullName -Recurse -Filter SKILL.md -File | Where-Object { $_.DirectoryName -ne $dir.FullName })
        foreach ($nested in $nestedSkills) { Add-Err "Nested registered skill is not allowed: $($nested.FullName)" }
    }
}
if (Has-AbsolutePersonalPath (Join-Path $PluginPath 'hooks')) { Add-Err 'Hooks contain personal absolute paths.' }

$motorRoot = Join-Path $skillsPath 'aicoding-motor-control'
$packConfig = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'config/aicoding-plugin-pack.json') | ConvertFrom-Json
$motorSelected = @($packConfig.skillKits | Where-Object { $_.enabled -ne $false -and $_.source -eq 'embedded/motorcontrol/skillkit.json' }).Count -gt 0
if ($errors.Count -eq 0 -and ($motorSelected -or (Test-Path -LiteralPath $motorRoot -PathType Container))) {
    $motorOutput = @(& python (Join-Path $repoRoot 'scripts/test-motor-contract.py') --package --plugin-path $PluginPath 2>&1)
    if ($LASTEXITCODE -ne 0) { Add-Err "Motor bundle contract failed: $($motorOutput -join ' ')" }
}

if ($Json) {
    [pscustomobject]@{ ok=($errors.Count -eq 0); errors=$errors } | ConvertTo-Json -Depth 5
} elseif ($errors.Count -eq 0) {
    Write-Host 'AiCoding plugin verification passed.'
} else {
    $errors | ForEach-Object { Write-Error $_ }
}
if ($errors.Count -gt 0) { exit 1 }
