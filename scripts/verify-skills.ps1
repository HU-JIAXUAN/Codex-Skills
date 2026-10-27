param([switch]$Json)
$ErrorActionPreference = 'Stop'
$repoRoot = (& git -C $PSScriptRoot rev-parse --show-toplevel).Trim()
$errors = New-Object System.Collections.Generic.List[string]
$externalRoot = Join-Path $repoRoot 'external'
$externalConfigPath = Join-Path $repoRoot 'config/external-skill-bindings.json'
$gitmodulesPath = Join-Path $repoRoot '.gitmodules'

if (Test-Path -LiteralPath $externalRoot) {
    if (-not (Test-Path -LiteralPath $externalConfigPath)) { $errors.Add('Missing config/external-skill-bindings.json for external Skills.') | Out-Null }
    if (-not (Test-Path -LiteralPath $gitmodulesPath)) { $errors.Add('Missing .gitmodules for external Skills.') | Out-Null }

    if ((Test-Path -LiteralPath $externalConfigPath) -and (Test-Path -LiteralPath $gitmodulesPath)) {
        $externalConfig = Get-Content -Raw -LiteralPath $externalConfigPath | ConvertFrom-Json
        $moduleRows = @(& git -C $repoRoot config -f .gitmodules --get-regexp '^submodule\..*\.path$')
        $modules = @()
        foreach ($row in $moduleRows) {
            if ($row -notmatch '^(?<key>\S+)\s+(?<path>.+)$') { continue }
            $section = $Matches.key -replace '\.path$',''
            $modules += [pscustomobject]@{
                path = ($Matches.path -replace '\\','/').TrimEnd('/')
                url = (& git -C $repoRoot config -f .gitmodules --get "$section.url").Trim()
            }
        }

        $boundSubmodules = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($binding in @($externalConfig.skills)) {
            $submodule = ([string]$binding.submodule -replace '\\','/').TrimEnd('/')
            $skillPath = ([string]$binding.skillPath -replace '\\','/').Trim('/')
            if (-not $binding.name -or -not $submodule -or -not $skillPath -or -not $binding.url -or -not $binding.updatePolicy -or -not $binding.tagPattern) {
                $errors.Add('External Skill bindings require name, submodule, skillPath, url, updatePolicy, and tagPattern.') | Out-Null
                continue
            }
            if (-not $submodule.StartsWith('external/', [System.StringComparison]::OrdinalIgnoreCase)) {
                $errors.Add("External Skill submodule must be under external/: $submodule") | Out-Null
                continue
            }
            $boundSubmodules.Add($submodule) | Out-Null
            $module = @($modules | Where-Object { $_.path -eq $submodule }) | Select-Object -First 1
            if (-not $module) {
                $errors.Add("External Skill is not a declared submodule: $submodule") | Out-Null
                continue
            }
            if ($module.url -ne [string]$binding.url) { $errors.Add("External Skill URL mismatch for $submodule") | Out-Null }
            if ([string]$binding.updatePolicy -ne 'latest-stable-tag') { $errors.Add("Unsupported external Skill update policy for $submodule") | Out-Null }
            $stage = @(& git -C $repoRoot ls-files --stage -- $submodule)
            if (-not ($stage -match '^160000 ')) { $errors.Add("External Skill is not tracked as a gitlink: $submodule") | Out-Null }
            $submoduleDir = Join-Path $repoRoot $submodule
            if (Test-Path -LiteralPath $submoduleDir) {
                $stableTags = @(& git -C $submoduleDir tag --list | Where-Object { $_ -match [string]$binding.tagPattern } | Sort-Object { [version]($_ -replace '^[vV]','') } -Descending)
                $currentTags = @(& git -C $submoduleDir tag --points-at HEAD | Where-Object { $_ -match [string]$binding.tagPattern })
                if ($currentTags.Count -eq 0) { $errors.Add("External Skill gitlink is not on a stable tag: $submodule") | Out-Null }
                elseif ($stableTags.Count -gt 0 -and $currentTags -notcontains $stableTags[0]) { $errors.Add("External Skill is not on the latest locally available stable tag: $submodule") | Out-Null }
            }
            $skillFile = Join-Path (Join-Path $repoRoot $submodule) (Join-Path $skillPath 'SKILL.md')
            if (-not (Test-Path -LiteralPath $skillFile)) {
                $errors.Add("Mapped external SKILL.md not found: $submodule/$skillPath/SKILL.md") | Out-Null
                continue
            }
            $skillText = [System.IO.File]::ReadAllText($skillFile, [System.Text.Encoding]::UTF8)
            if ($skillText -notmatch ('(?m)^name:\s*[''\"]?' + [regex]::Escape([string]$binding.name) + '[''\"]?\s*$')) {
                $errors.Add("External Skill name mismatch: $submodule/$skillPath") | Out-Null
            }
        }

        foreach ($module in @($modules | Where-Object { $_.path.StartsWith('external/', [System.StringComparison]::OrdinalIgnoreCase) })) {
            if (-not $boundSubmodules.Contains($module.path)) { $errors.Add("External submodule has no binding entry: $($module.path)") | Out-Null }
        }
        foreach ($child in Get-ChildItem -LiteralPath $externalRoot -Directory) {
            $relative = 'external/' + $child.Name
            if (-not @($modules | Where-Object { $_.path -eq $relative })) { $errors.Add("External directory is not a declared submodule: $relative") | Out-Null }
        }
    }
}

$skillFiles = @(Get-ChildItem -LiteralPath $repoRoot -Recurse -Filter SKILL.md | Where-Object {
    $_.FullName -notmatch '\\.system\\' -and $_.FullName -notmatch '\\plugins\\AiCoding\\skills\\'
})
foreach ($file in $skillFiles) {
    $relativePath = $file.FullName.Substring($repoRoot.TrimEnd('\').Length + 1).Replace('\', '/')
    if ($relativePath -notmatch '^(embedded|platform|standalone|external)/') {
        $errors.Add("Canonical SKILL.md is outside an approved source root: $relativePath") | Out-Null
    }
    if ($relativePath.StartsWith('standalone/', [System.StringComparison]::OrdinalIgnoreCase) -and
        $relativePath -notmatch '^standalone/[^/]+/SKILL\.md$') {
        $errors.Add("Local standalone Skill must use standalone/<skill-name>/SKILL.md: $relativePath") | Out-Null
    }
    $text = ([System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)).TrimStart([char]0xFEFF)
    if ($text -notmatch '(?s)^---\s*\r?\n.*?\r?\n---') { $errors.Add("Missing frontmatter: $($file.FullName)") | Out-Null }
    if ($text -notmatch '(?m)^name:\s*[^\r\n]+') { $errors.Add("Missing name: $($file.FullName)") | Out-Null }
    if ($text -notmatch '(?m)^description:\s*') { $errors.Add("Missing description: $($file.FullName)") | Out-Null }
}
$motorOutput = @(& python (Join-Path $repoRoot 'scripts/test-motor-contract.py') 2>&1)
if ($LASTEXITCODE -ne 0) { $errors.Add("Motor bundle source contract failed: $($motorOutput -join ' ')") | Out-Null }
if ($Json) { [pscustomobject]@{ ok=($errors.Count -eq 0); count=$skillFiles.Count; errors=$errors } | ConvertTo-Json -Depth 5 } elseif ($errors.Count -eq 0) { Write-Host "Skill verification passed ($($skillFiles.Count) SKILL.md files)." } else { $errors | ForEach-Object { Write-Error $_ } }
if ($errors.Count -gt 0) { exit 1 }
