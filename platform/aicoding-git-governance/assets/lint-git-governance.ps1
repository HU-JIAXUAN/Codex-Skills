param(
    [ValidateSet("all", "working-tree", "pre-commit", "commit-msg")]
    [string]$Mode = "all",

    [string]$CommitMsgPath = ""
)

$ErrorActionPreference = "Stop"

$CanonicalStandardUrl = "https://github.com/JiaxI2/Codex-Skills/blob/main/platform/aicoding-git-governance/references/aicoding-git-governance-standard.md"
$CanonicalStandardRawUrl = "https://raw.githubusercontent.com/JiaxI2/Codex-Skills/main/platform/aicoding-git-governance/references/aicoding-git-governance-standard.md"

function Fail([string]$Message) {
    Write-Error $Message
    exit 1
}

function Require-Content([string]$Path, [string]$Pattern, [string]$Message) {
    $content = Get-Content -LiteralPath $Path -Raw -Encoding utf8
    if ($content -notmatch $Pattern) {
        Fail $Message
    }
}

function Get-TomlSection([string]$Content, [string]$SectionName) {
    $pattern = "(?ms)^\[$([regex]::Escape($SectionName))\]\s*(.*?)(?=^\[|\z)"
    if ($Content -match $pattern) { return $Matches[1] }
    return ""
}

function Get-TomlStringValue([string]$SectionContent, [string]$Key) {
    $pattern = "(?m)^$([regex]::Escape($Key))\s*=\s*`"([^`"]*)`""
    if ($SectionContent -match $pattern) { return $Matches[1] }
    return ""
}

function Require-HeadToken([string]$Path, [string]$Token, [string]$Message) {
    $head = (Get-Content -LiteralPath $Path -Encoding utf8 | Select-Object -First 24) -join "`n"
    if (-not $head.Contains($Token)) { Fail $Message }
}

$repoRoot = (& git rev-parse --show-toplevel).Trim()
if (-not $repoRoot) { Fail "Not inside a Git repository." }
Set-Location $repoRoot

$requiredFiles = @(
    "README.md",
    "README_CN.md",
    "README_EN.md",
    "CHANGELOG.md",
    ".github/repository-governance.toml",
    ".githooks/pre-commit",
    ".githooks/commit-msg"
)

foreach ($file in $requiredFiles) {
    if (-not (Test-Path -LiteralPath $file)) {
        Fail "Required governance file missing: $file"
    }
}

$governance = Get-Content -LiteralPath ".github/repository-governance.toml" -Raw -Encoding utf8
$projectSection = Get-TomlSection $governance "project"
$readmeSection = Get-TomlSection $governance "readme"
$standardSection = Get-TomlSection $governance "governance_standard"
$changelogSection = Get-TomlSection $governance "changelog"

$portableReadmePolicyEnabled = $governance -match '(?m)^\[readme\.(structure|banner|badges|architecture_graph|capability_showcase|evolution|star_history)\]\s*$'
if ($portableReadmePolicyEnabled) {
    $readmeValidator = Join-Path $repoRoot "scripts/validate_readme_governance.py"
    if (-not (Test-Path -LiteralPath $readmeValidator)) {
        Fail "Portable README policy requires scripts/validate_readme_governance.py."
    }
    $readmeValidationOutput = @(& python $readmeValidator --config ".github/repository-governance.toml" --repo-root $repoRoot 2>&1)
    $readmeValidationExitCode = $LASTEXITCODE
    $readmeValidationOutput | ForEach-Object { Write-Host $_ }
    if ($readmeValidationExitCode -ne 0) { exit $readmeValidationExitCode }
}

$repoUrl = Get-TomlStringValue $projectSection "repository_url"
$repoSlug = ""
if ($repoUrl -match 'github\.com[:/]([^/]+)/([^/.]+)(\.git)?$') {
    $repoSlug = "$($Matches[1])/$($Matches[2])"
}
if (-not $repoSlug) { Fail ".github/repository-governance.toml must set project.repository_url to a GitHub repository URL." }

if ((Get-TomlStringValue $standardSection "id") -ne "aicoding-git-governance") {
    Fail ".github/repository-governance.toml must declare governance_standard.id = aicoding-git-governance."
}
if ((Get-TomlStringValue $standardSection "source_url") -ne $CanonicalStandardUrl) {
    Fail ".github/repository-governance.toml must reference the canonical governance standard source_url."
}
if ((Get-TomlStringValue $standardSection "raw_url") -ne $CanonicalStandardRawUrl) {
    Fail ".github/repository-governance.toml must reference the canonical governance standard raw_url."
}
if ((Get-TomlStringValue $standardSection "sync_policy") -ne "track-canonical-url") {
    Fail ".github/repository-governance.toml must set governance_standard.sync_policy = track-canonical-url."
}

if ((Get-TomlStringValue $readmeSection "primary_language") -ne "zh-CN") {
    Fail ".github/repository-governance.toml must set README primary_language to zh-CN."
}
if ((Get-TomlStringValue $readmeSection "english_language_file") -ne "README_EN.md") {
    Fail ".github/repository-governance.toml must define README_EN.md as the English README file."
}
if ((Get-TomlStringValue $readmeSection "secondary_language_surface") -ne "top-file-language-switch-and-github-about") {
    Fail ".github/repository-governance.toml must route the Chinese README through the top file-level language switch and GitHub About/Homepage."
}
if ($governance -notlike '*quick_environment_preview = true*') {
    Fail ".github/repository-governance.toml must require the README badge environment preview."
}
if ($governance -notmatch '(?m)^\[github_about\]' -or $governance -notlike '*require_bilingual = true*') {
    Fail ".github/repository-governance.toml must require bilingual GitHub About metadata."
}

$scanFiles = @("README.md", "README_CN.md", "README_EN.md", "CHANGELOG.md", ".github/repository-governance.toml")
foreach ($file in $scanFiles) {
    $content = Get-Content -LiteralPath $file -Raw -Encoding utf8
    if ($content -match "\{\{[^}]+\}\}|UNRESOLVED_PLACEHOLDER|TODO_PLACEHOLDER") {
        Fail "Unresolved placeholder found in $file"
    }
}

$readmeTop = (Get-Content -LiteralPath "README.md" -Encoding utf8 | Select-Object -First 24) -join "`n"
if ($readmeTop -notmatch "README_CN\.md") { Fail "README.md must include a visible top-of-file README_CN.md link for bilingual switching." }
if ($readmeTop -notmatch "README_EN\.md") { Fail "README.md must include a visible top-of-file README_EN.md link for English switching." }
if ($readmeTop -match "README\.md#english") { Fail "README.md must not use an in-page English anchor; link to README_EN.md instead." }
if ($readmeTop -notmatch "[\u4e00-\u9fff]") { Fail "README.md must be the Chinese-first default repository entry." }

Require-HeadToken "README.md" "img.shields.io/github/v/release/$repoSlug" "README.md must keep the Release badge link."
Require-HeadToken "README.md" "https://learn.microsoft.com/powershell/" "README.md must keep the PowerShell environment preview badge."
Require-HeadToken "README.md" "https://www.python.org/" "README.md must keep the Python environment preview badge."
Require-HeadToken "README.md" "github/license/$repoSlug" "README.md must keep the License badge link."

$localPathFragments = @(
    "C:\Users",
    "F:\Study",
    "AppData\Local\Temp"
)
foreach ($file in @("README.md", "README_CN.md", "README_EN.md")) {
    $content = Get-Content -LiteralPath $file -Raw -Encoding utf8
    foreach ($fragment in $localPathFragments) {
        if ($content.Contains($fragment)) {
            Fail "README files must not hard-code personal local paths: $file"
        }
    }
}

Require-Content "README.md" "Git 治理标准|Git Governance Standard" "README.md must document the Git governance standard."
Require-Content "README.md" "feat.+fix.+docs.+style.+refactor.+perf.+test.+build.+ci.+chore|feat.+fix.+docs.+build.+ci.+chore" "README.md must document the standard commit type taxonomy."
Require-Content "README.md" "main.+develop.+feature.+test.+release.+hotfix|main.+master.+develop.+feature.+test.+release.+hotfix" "README.md must document branch naming and environment mapping."
Require-Content "README.md" "Release notes|Release.+主类型|按主类型汇总|按类型汇总" "README.md must document that Release notes group commits by type and state the primary release type."
Require-Content "README_EN.md" "Git Governance Standard|Git 治理标准" "README_EN.md must document the Git governance standard."
Require-Content "README_EN.md" "feat.+fix.+docs.+style.+refactor.+perf.+test.+build.+ci.+chore|feat.+fix.+docs.+build.+ci.+chore" "README_EN.md must document the standard commit type taxonomy."

$changelogMode = Get-TomlStringValue $changelogSection "mode"
$changelog = Get-Content -LiteralPath "CHANGELOG.md" -Raw -Encoding utf8
if ($changelogMode -eq "unreleased" -and $changelog -notmatch "\[Unreleased\]") {
    Fail "CHANGELOG.md must contain [Unreleased] when changelog.mode is unreleased."
}
if ($changelog -notmatch "\*\*(feat|fix|docs|style|refactor|perf|test|build|ci|chore)(\([^)]*\))?\*\*") {
    Fail "CHANGELOG.md must include typed entries such as **docs** or **chore**."
}

# Index completeness belongs to the commit gate, not routine repository checks.
if ($Mode -eq "pre-commit") {
    $staged = @(& git diff --cached --name-only --diff-filter=ACMR)
    if ($staged.Count -gt 0 -and -not ($staged -contains "CHANGELOG.md")) {
        if ($env:AICODING_SKIP_CHANGELOG -ne "1") {
            Fail "CHANGELOG.md must be staged for normal commits. Set AICODING_SKIP_CHANGELOG=1 only for an approved exclusion."
        }
    }
}

if ($Mode -eq "commit-msg") {
    if (-not $CommitMsgPath) { Fail "Commit message path is required." }
    $subject = (Get-Content -LiteralPath $CommitMsgPath -Encoding utf8 | Where-Object { $_ -and -not $_.StartsWith("#") } | Select-Object -First 1)
    if (-not $subject) { Fail "Commit message subject is empty." }
    $pattern = "^(feat|fix|docs|style|refactor|perf|test|build|ci|chore)(\([a-z0-9._/-]+\))?: .{8,}$"
    if ($subject -notmatch $pattern) {
        Fail "Commit subject must match <type>(<scope>): <summary>. Got: $subject"
    }
}

Write-Host "Git governance lint passed ($Mode)."
