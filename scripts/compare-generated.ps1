param()
$ErrorActionPreference = 'Stop'

function ConvertTo-ComparableBuildInfo($BuildInfo) {
    $copy = [ordered]@{}
    foreach ($property in $BuildInfo.PSObject.Properties) {
        if ($property.Name -in @('sourceCommit', 'sourceTag', 'buildTimestampUtc', 'dirtySource')) { continue }
        $copy[$property.Name] = $property.Value
    }
    return ($copy | ConvertTo-Json -Depth 10 -Compress)
}

function Read-BuildInfoText([byte[]]$Bytes) {
    if ($null -eq $Bytes) { return $null }
    return ([System.Text.Encoding]::UTF8.GetString($Bytes)).TrimStart([char]0xFEFF)
}

function Convert-BuildInfoJson([string]$Text) {
    if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
    return ConvertTo-ComparableBuildInfo (ConvertFrom-Json -InputObject $Text)
}

$repoRoot = (& git -C $PSScriptRoot rev-parse --show-toplevel).Trim()
$lockHash = [System.Security.Cryptography.SHA256]::Create()
$lockDigest = ([BitConverter]::ToString($lockHash.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($repoRoot.ToLowerInvariant())))).Replace('-', '').ToLowerInvariant()
$lockHash.Dispose()
$buildMutex = [System.Threading.Mutex]::new($false, ('CodexSkillsBuild_' + $lockDigest.Substring(0, 24)))
$buildLockAcquired = $false
try {
try { $buildLockAcquired = $buildMutex.WaitOne(30000) }
catch [System.Threading.AbandonedMutexException] { $buildLockAcquired = $true }
if (-not $buildLockAcquired) { throw 'Timed out waiting for the repository plugin build lock.' }
$buildInfoRel = 'plugins/AiCoding/BUILDINFO.json'
$buildInfoPath = Join-Path $repoRoot $buildInfoRel
$beforeStatus = @(& git -C $repoRoot status --porcelain)
$beforeBuildInfoBytes = if (Test-Path -LiteralPath $buildInfoPath) { [System.IO.File]::ReadAllBytes($buildInfoPath) } else { $null }
$beforeBuildInfoComparable = Convert-BuildInfoJson (Read-BuildInfoText $beforeBuildInfoBytes)

try {
    & (Join-Path $repoRoot 'scripts/build-plugin.ps1') -Plugin AiCoding -Configuration Development -Clean
}
catch {
    Write-Error 'Generated plugin rebuild failed; stability was not verified.'
    exit 1
}

$afterBuildInfoBytes = if (Test-Path -LiteralPath $buildInfoPath) { [System.IO.File]::ReadAllBytes($buildInfoPath) } else { $null }
$afterBuildInfoComparable = Convert-BuildInfoJson (Read-BuildInfoText $afterBuildInfoBytes)

if ($beforeBuildInfoComparable -ne $afterBuildInfoComparable) {
    Write-Error 'Generated plugin BUILDINFO stable fields drifted after rebuild.'
    exit 1
}

if ($null -ne $beforeBuildInfoBytes) {
    [System.IO.File]::WriteAllBytes($buildInfoPath, $beforeBuildInfoBytes)
}

$afterStatus = @(& git -C $repoRoot status --porcelain)
if (($beforeStatus -join "`n") -ne ($afterStatus -join "`n")) {
    Write-Error 'Generated plugin output drifted after rebuild.'
    exit 1
}
Write-Host 'Generated plugin output is stable.'
}
finally {
    if ($buildLockAcquired) { $buildMutex.ReleaseMutex() }
    $buildMutex.Dispose()
}
