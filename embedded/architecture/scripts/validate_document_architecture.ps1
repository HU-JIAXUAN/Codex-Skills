[CmdletBinding()]
param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$rootFull = [System.IO.Path]::GetFullPath($Root)
$manifestPath = Join-Path $rootFull 'document-architecture.json'
$errors = [System.Collections.Generic.List[string]]::new()

function Add-ValidationError {
    param([string]$Message)
    $errors.Add($Message)
}

function Convert-ToRelativePath {
    param([string]$Path)
    return $Path.Replace('\', '/')
}

if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    Write-Host 'FAIL: document-architecture.json is missing.'
    exit 1
}

try {
    $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding utf8 | ConvertFrom-Json
}
catch {
    Write-Host "FAIL: invalid manifest: $($_.Exception.Message)"
    exit 1
}

if ([int]$manifest.schema_version -ne 1) {
    Add-ValidationError "Unsupported schema_version '$($manifest.schema_version)'."
}

$docByPath = @{}
$topicOwner = @{}

foreach ($doc in @($manifest.documents)) {
    $docPath = Convert-ToRelativePath ([string]$doc.path)
    if ([string]::IsNullOrWhiteSpace($docPath)) {
        Add-ValidationError 'Manifest contains a document with an empty path.'
        continue
    }
    if ($docByPath.ContainsKey($docPath)) {
        Add-ValidationError "Duplicate document path '$docPath'."
        continue
    }
    $docByPath[$docPath] = $doc

    foreach ($topic in @($doc.owns)) {
        $topicName = [string]$topic
        if ($topicOwner.ContainsKey($topicName)) {
            Add-ValidationError "Responsibility '$topicName' is owned by both '$($topicOwner[$topicName])' and '$docPath'."
        }
        else {
            $topicOwner[$topicName] = $docPath
        }
    }
}

$entrypoint = Convert-ToRelativePath ([string]$manifest.entrypoint)
if (-not $docByPath.ContainsKey($entrypoint)) {
    Add-ValidationError "Entrypoint '$entrypoint' is not listed as a document."
}

$actualMarkdown = @(
    Get-ChildItem -LiteralPath $rootFull -Recurse -File -Filter '*.md' |
        ForEach-Object {
            Convert-ToRelativePath ([System.IO.Path]::GetRelativePath($rootFull, $_.FullName))
        }
)

foreach ($docPath in $docByPath.Keys) {
    $absolutePath = Join-Path $rootFull $docPath
    if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) {
        Add-ValidationError "Listed document '$docPath' does not exist."
    }
}

foreach ($actualPath in $actualMarkdown) {
    if (-not $docByPath.ContainsKey($actualPath)) {
        Add-ValidationError "Unlisted Markdown document '$actualPath'."
    }
}

$allowedRootMarkdown = @{}
foreach ($rootDoc in @($manifest.root_markdown)) {
    $allowedRootMarkdown[(Convert-ToRelativePath ([string]$rootDoc))] = $true
}

foreach ($actualPath in $actualMarkdown) {
    $parent = Split-Path -Parent $actualPath
    if ([string]::IsNullOrEmpty($parent) -and -not $allowedRootMarkdown.ContainsKey($actualPath)) {
        Add-ValidationError "Root-level Markdown '$actualPath' is not allowed by root_markdown."
    }
}

foreach ($allowedPath in $allowedRootMarkdown.Keys) {
    if (-not $docByPath.ContainsKey($allowedPath)) {
        Add-ValidationError "root_markdown entry '$allowedPath' is not a listed document."
    }
}

$contentByPath = @{}
foreach ($docPath in $docByPath.Keys) {
    $absolutePath = Join-Path $rootFull $docPath
    if (Test-Path -LiteralPath $absolutePath -PathType Leaf) {
        $content = Get-Content -LiteralPath $absolutePath -Raw -Encoding utf8
        $contentByPath[$docPath] = $content

        $titleMatch = [regex]::Match($content, '(?m)^#\s+(.+?)\r?$')
        if (-not $titleMatch.Success) {
            Add-ValidationError "Document '$docPath' has no level-one title."
        }
        elseif ($titleMatch.Groups[1].Value.Trim() -ne ([string]$docByPath[$docPath].title).Trim()) {
            Add-ValidationError "Document '$docPath' title does not match the manifest."
        }
    }
}

foreach ($docPath in $docByPath.Keys) {
    foreach ($dependency in @($docByPath[$docPath].depends_on)) {
        $dependencyPath = Convert-ToRelativePath ([string]$dependency)
        if (-not $docByPath.ContainsKey($dependencyPath)) {
            Add-ValidationError "Document '$docPath' declares unknown dependency '$dependencyPath'."
        }
        if ($dependencyPath -eq $docPath) {
            Add-ValidationError "Document '$docPath' depends on itself."
        }
    }
}

$visitState = @{}
function Visit-Document {
    param(
        [string]$Node,
        [string[]]$Trail
    )

    if ($visitState.ContainsKey($Node) -and $visitState[$Node] -eq 1) {
        $cycle = @($Trail + $Node) -join ' -> '
        Add-ValidationError "Document dependency cycle: $cycle"
        return
    }
    if ($visitState.ContainsKey($Node) -and $visitState[$Node] -eq 2) {
        return
    }

    $visitState[$Node] = 1
    foreach ($dependency in @($docByPath[$Node].depends_on)) {
        $dependencyPath = Convert-ToRelativePath ([string]$dependency)
        if ($docByPath.ContainsKey($dependencyPath)) {
            Visit-Document -Node $dependencyPath -Trail @($Trail + $Node)
        }
    }
    $visitState[$Node] = 2
}

foreach ($docPath in $docByPath.Keys) {
    Visit-Document -Node $docPath -Trail @()
}

$definitionById = @{}
$idPrefixes = @($manifest.id_owners.PSObject.Properties.Name | Sort-Object Length -Descending)
if ($idPrefixes.Count -eq 0) {
    Add-ValidationError 'Manifest defines no ID owners.'
    $idPrefixPattern = '(?!)'
}
else {
    $idPrefixPattern = @($idPrefixes | ForEach-Object { [regex]::Escape($_) }) -join '|'
}
$definitionPattern = '(?m)^###\s+(?<id>(?<prefix>' + $idPrefixPattern + ')-\d{3})\b'
$referencePattern = '\b(?:' + $idPrefixPattern + ')-\d{3}\b'

foreach ($docPath in $contentByPath.Keys) {
    $content = $contentByPath[$docPath]
    foreach ($match in [regex]::Matches($content, $definitionPattern)) {
        $id = $match.Groups['id'].Value
        $prefix = $match.Groups['prefix'].Value
        $ownerProperty = $manifest.id_owners.PSObject.Properties[$prefix]

        if ($null -eq $ownerProperty) {
            Add-ValidationError "ID prefix '$prefix' has no owner in the manifest."
        }
        else {
            $expectedOwner = Convert-ToRelativePath ([string]$ownerProperty.Value)
            if ($expectedOwner -ne $docPath) {
                Add-ValidationError "ID '$id' is defined by '$docPath', but prefix '$prefix' belongs to '$expectedOwner'."
            }
        }

        if ($definitionById.ContainsKey($id)) {
            Add-ValidationError "ID '$id' is defined in both '$($definitionById[$id])' and '$docPath'."
        }
        else {
            $definitionById[$id] = $docPath
        }

        $anchorPattern = '(?m)^<a id="' + [regex]::Escape($id) + '"></a>\r?$'
        if (-not [regex]::IsMatch($content, $anchorPattern)) {
            Add-ValidationError "Definition '$id' in '$docPath' has no explicit matching anchor."
        }
    }
}

foreach ($ownerProperty in $manifest.id_owners.PSObject.Properties) {
    $ownerPath = Convert-ToRelativePath ([string]$ownerProperty.Value)
    if (-not $docByPath.ContainsKey($ownerPath)) {
        Add-ValidationError "ID owner '$ownerPath' for prefix '$($ownerProperty.Name)' is not a listed document."
    }
    $ownedCount = @($definitionById.Keys | Where-Object { $_ -like "$($ownerProperty.Name)-*" }).Count
    if ($ownedCount -eq 0) {
        Add-ValidationError "ID prefix '$($ownerProperty.Name)' has no definitions."
    }
}

foreach ($docPath in $contentByPath.Keys) {
    foreach ($match in [regex]::Matches($contentByPath[$docPath], $referencePattern)) {
        $id = $match.Value
        if (-not $definitionById.ContainsKey($id)) {
            Add-ValidationError "Document '$docPath' references undefined ID '$id'."
        }
    }
}

$rootPrefix = $rootFull.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
$linkPattern = '(?<!!)\[[^\]\r\n]+\]\((?<target>[^)\r\n]+)\)'

foreach ($docPath in $contentByPath.Keys) {
    $content = $contentByPath[$docPath]
    $linkedDocuments = @{}

    foreach ($match in [regex]::Matches($content, $linkPattern)) {
        $rawTarget = $match.Groups['target'].Value.Trim()
        if ($rawTarget -match '^(?:https?://|mailto:)') {
            continue
        }

        $targetParts = $rawTarget -split '#', 2
        $pathPart = [System.Uri]::UnescapeDataString($targetParts[0])
        $fragment = if ($targetParts.Count -eq 2) { [System.Uri]::UnescapeDataString($targetParts[1]) } else { '' }

        if ([string]::IsNullOrEmpty($pathPart)) {
            $targetRelative = $docPath
            $targetAbsolute = Join-Path $rootFull $docPath
        }
        else {
            $sourceAbsolute = Join-Path $rootFull $docPath
            $sourceDirectory = Split-Path -Parent $sourceAbsolute
            $targetAbsolute = [System.IO.Path]::GetFullPath((Join-Path $sourceDirectory $pathPart))

            if (-not $targetAbsolute.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                Add-ValidationError "Document '$docPath' links outside the kit: '$rawTarget'."
                continue
            }
            $targetRelative = Convert-ToRelativePath ([System.IO.Path]::GetRelativePath($rootFull, $targetAbsolute))
        }

        if (-not (Test-Path -LiteralPath $targetAbsolute -PathType Leaf)) {
            Add-ValidationError "Document '$docPath' has broken local link '$rawTarget'."
            continue
        }

        if ($targetRelative.EndsWith('.md', [System.StringComparison]::OrdinalIgnoreCase) -and $targetRelative -ne $docPath) {
            if (-not $docByPath.ContainsKey($targetRelative)) {
                Add-ValidationError "Document '$docPath' links to unlisted document '$targetRelative'."
            }
            else {
                $linkedDocuments[$targetRelative] = $true
            }
        }

        if (-not [string]::IsNullOrEmpty($fragment)) {
            if (-not $contentByPath.ContainsKey($targetRelative)) {
                Add-ValidationError "Document '$docPath' uses an anchor on non-document target '$rawTarget'."
            }
            else {
                $escapedFragment = [regex]::Escape($fragment)
                $targetAnchorPattern = '(?m)^<a id="' + $escapedFragment + '"></a>\r?$'
                if (-not [regex]::IsMatch($contentByPath[$targetRelative], $targetAnchorPattern)) {
                    Add-ValidationError "Document '$docPath' links to missing anchor '$fragment' in '$targetRelative'."
                }
            }
        }
    }

    $declaredDependencies = @{}
    foreach ($dependency in @($docByPath[$docPath].depends_on)) {
        $declaredDependencies[(Convert-ToRelativePath ([string]$dependency))] = $true
    }

    foreach ($dependencyPath in $declaredDependencies.Keys) {
        if (-not $linkedDocuments.ContainsKey($dependencyPath)) {
            Add-ValidationError "Document '$docPath' declares '$dependencyPath' but does not link to it."
        }
    }
    foreach ($linkedPath in $linkedDocuments.Keys) {
        if (-not $declaredDependencies.ContainsKey($linkedPath)) {
            Add-ValidationError "Document '$docPath' links to '$linkedPath' without declaring the dependency."
        }
    }
}

if ($errors.Count -gt 0) {
    Write-Host "FAIL: $($errors.Count) document architecture error(s)."
    foreach ($message in @($errors | Sort-Object -Unique)) {
        Write-Host " - $message"
    }
    exit 1
}

$dependencyCount = 0
foreach ($doc in @($manifest.documents)) {
    $dependencyCount += @($doc.depends_on).Count
}

Write-Host "PASS: $($docByPath.Count) documents, $($topicOwner.Count) unique responsibilities, $($definitionById.Count) owned IDs, $dependencyCount acyclic declared dependencies."
exit 0
