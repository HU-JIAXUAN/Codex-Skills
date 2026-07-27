<#
.SYNOPSIS
    嵌入式架构分层检查器：按语义角色（SL-*）而非目录名检查源码依赖方向、公共头纯净度、
    组合根唯一性和过度抽象信号，并输出可复现的基线指标。

.DESCRIPTION
    本脚本与具体项目解耦：所有路径、角色映射、厂商头模式和例外都来自 -Map 指定的配置文件。
    脚本本身不包含任何仓库的目录名。配置示例见 scripts/arch-map.example.json。

    实现的门禁：
      GATE-001 依赖方向        -> DR-002 / DR-014
      GATE-002 公共头纯度      -> DR-003 / DR-006
      GATE-009 角色映射完整性  -> DR-014
      DR-004   组合根唯一可见  -> 非组合根不得包含实现私有头
      DR-012   新抽象准入      -> 单实现且无替身的 Port 作为警告

.PARAMETER Root
    被检查工程的根目录。

.PARAMETER Map
    角色映射与规则配置（JSON）。

.PARAMETER Strict
    把警告也视为失败。

.PARAMETER BaselineOnly
    只输出基线指标，不因违规返回非零退出码。

.EXAMPLE
    pwsh -File check_layering.ps1 -Root C:\proj -Map C:\proj\arch-map.json
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Root,
    [string]$Map,
    [switch]$Strict,
    [switch]$BaselineOnly,
    [switch]$Evidence
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$rootFull = [System.IO.Path]::GetFullPath($Root)
if (-not (Test-Path -LiteralPath $rootFull -PathType Container)) {
    Write-Host "FAIL: root '$Root' is not a directory."
    exit 2
}
$hasMap = -not [string]::IsNullOrWhiteSpace($Map)
if (-not $hasMap) {
    if (-not $Evidence) {
        Write-Host 'FAIL: -Map is required unless -Evidence is used.'
        exit 2
    }
}
elseif (-not (Test-Path -LiteralPath $Map -PathType Leaf)) {
    Write-Host "FAIL: map '$Map' does not exist."
    exit 2
}

if (-not $hasMap) {
    # 证据模式允许没有任何映射：先测事实，再由人确认角色。
    $config = [pscustomobject]@{}
}
else {
    try {
        $config = Get-Content -LiteralPath $Map -Raw -Encoding utf8 | ConvertFrom-Json
    }
    catch {
        Write-Host "FAIL: invalid map file: $($_.Exception.Message)"
        exit 2
    }
}

function Get-ConfigValue {
    param($Object, [string]$Name, $Default)
    if ($null -eq $Object) { return $Default }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property -or $null -eq $property.Value) { return $Default }
    return $property.Value
}

function ConvertTo-RelativePath {
    param([string]$FullPath)
    return ([System.IO.Path]::GetRelativePath($rootFull, $FullPath)).Replace('\', '/')
}

# ---------------------------------------------------------------- 默认角色矩阵
# 允许的源码 include 方向。项目可在配置中用 allowed_dependencies 覆盖整张表。
$defaultAllowed = @{
    'SL-001' = @('SL-001', 'SL-002', 'SL-003', 'SL-004')
    'SL-002' = @('SL-002', 'SL-003', 'SL-004')
    'SL-003' = @('SL-003', 'SL-004', 'SL-009')
    'SL-004' = @('SL-004')
    'SL-005' = @('SL-004', 'SL-005', 'SL-009')
    'SL-006' = @('SL-004', 'SL-005', 'SL-006', 'SL-007', 'SL-008', 'SL-009', 'SL-010')
    'SL-007' = @('SL-004', 'SL-007', 'SL-009', 'SL-010')
    'SL-008' = @('SL-004', 'SL-008', 'SL-009', 'SL-010')
    'SL-009' = @('SL-004', 'SL-009')
    'SL-010' = @('SL-001', 'SL-002', 'SL-003', 'SL-004', 'SL-005', 'SL-006', 'SL-007', 'SL-008', 'SL-009', 'SL-010', 'SL-011')
    'SL-011' = @('SL-001', 'SL-002', 'SL-003', 'SL-004', 'SL-005', 'SL-006', 'SL-007', 'SL-008', 'SL-009', 'SL-010', 'SL-011')
}

$allowed = @{}
foreach ($key in $defaultAllowed.Keys) { $allowed[$key] = @($defaultAllowed[$key]) }
$allowedOverride = Get-ConfigValue $config 'allowed_dependencies' $null
if ($null -ne $allowedOverride) {
    foreach ($property in $allowedOverride.PSObject.Properties) {
        $allowed[$property.Name] = @($property.Value)
    }
}

$sourceExtensions = @(Get-ConfigValue $config 'source_extensions' @('.c', '.h', '.cpp', '.hpp', '.cc'))
$excludePatterns = @(Get-ConfigValue $config 'exclude_patterns' @())
$defaultLanguageHeaders = @(
    '^(assert|complex|ctype|errno|fenv|float|inttypes|iso646|limits|locale|math|setjmp|signal|stdalign|stdarg|stdatomic|stdbool|stddef|stdint|stdio|stdlib|stdnoreturn|string|tgmath|threads|time|uchar|wchar|wctype)\.h$'
)
$languagePatterns = @(Get-ConfigValue $config 'language_include_patterns' $defaultLanguageHeaders)
$externalPatterns = @(Get-ConfigValue $config 'external_include_patterns' @())
$forbiddenTypes = @(Get-ConfigValue $config 'forbidden_public_types' @())
$doublePatterns = @(Get-ConfigValue $config 'test_double_patterns' @('fake', 'stub', 'mock'))
$portRoles = @(Get-ConfigValue $config 'port_roles' @('SL-004'))
$implRoles = @(Get-ConfigValue $config 'implementation_roles' @('SL-005', 'SL-006', 'SL-007', 'SL-008'))
$compositionRoles = @(Get-ConfigValue $config 'composition_roles' @('SL-006', 'SL-011'))
$publicHeaderRoles = @(Get-ConfigValue $config 'public_header_roles' @('SL-001', 'SL-002', 'SL-003', 'SL-004'))
$moduleRules = @(Get-ConfigValue $config 'modules' @())
$exceptions = @(Get-ConfigValue $config 'exceptions' @())

if (($moduleRules.Count -eq 0) -and (-not $Evidence)) {
    Write-Host 'FAIL: map defines no "modules" rules.'
    exit 2
}

# ---------------------------------------------------------------- 判断输入的完整性
# 本脚本不判断"什么是厂商代码""什么是用户代码""目录意图是什么"——那些是模型和人的
# 结论。缺少这些结论时必须大声失败，绝不能报出一个看起来干净的 0。
$inputErrors = @()

# 厂商代码有两种声明方式：头文件命名模式，或把它整目录映射到厂商角色。
# 两种都没有，才是真的没声明。
$vendorRoleNames = @(Get-ConfigValue $config 'vendor_roles' @('SL-010'))
$hasVendorRule = $false
foreach ($rule in $moduleRules) {
    if ($vendorRoleNames -contains ([string]$rule.role)) { $hasVendorRule = $true; break }
}
if (($externalPatterns.Count -eq 0) -and (-not $hasVendorRule)) {
    $inputErrors += 'external_include_patterns 为空且没有任何规则映射到厂商角色：未声明什么是厂商代码，环境接触面无法判定，任何"0 违规"都不成立。'
}

if ($forbiddenTypes.Count -eq 0) {
    $inputErrors += 'forbidden_public_types 为空：未声明哪些类型算环境类型，公共头纯度检查形同虚设。'
}

$confirmedBy = [string](Get-ConfigValue $config 'analysis_confirmed_by' '')
if ([string]::IsNullOrWhiteSpace($confirmedBy)) {
    $inputErrors += 'analysis_confirmed_by 为空：角色映射是人工判断的结论，必须记录确认人；未经确认的映射不得作为门禁依据。'
}

foreach ($rule in $moduleRules) {
    if ([string]::IsNullOrWhiteSpace([string]$rule.role)) {
        $inputErrors += ("模块规则 '{0}' 没有声明 role。" -f (Get-ConfigValue $rule 'name' $rule.path_pattern))
    }
    if ([string]::IsNullOrWhiteSpace([string](Get-ConfigValue $rule 'evidence' ''))) {
        $inputErrors += ("模块规则 '{0}' 没有 evidence 字段：该角色依据什么证据判定，必须写下来，否则无法复核。" -f (Get-ConfigValue $rule 'name' $rule.path_pattern))
    }
}

if (($inputErrors.Count -gt 0) -and (-not $Evidence)) {
    Write-Host 'FAIL: 判断输入不完整，拒绝给出结论。'
    foreach ($message in $inputErrors) {
        Write-Host " - $message"
    }
    Write-Host ''
    Write-Host '这些字段都不是工具能自己推断的。请先由模型/人完成分析，把结论写进 arch-map.json 再运行。'
    exit 2
}

# ---------------------------------------------------------------- 收集源文件
$files = @(
    Get-ChildItem -LiteralPath $rootFull -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $sourceExtensions -contains $_.Extension.ToLowerInvariant() }
)

$records = @()
foreach ($file in $files) {
    $relative = ConvertTo-RelativePath $file.FullName
    $skip = $false
    foreach ($pattern in $excludePatterns) {
        if ($relative -match $pattern) { $skip = $true; break }
    }
    if ($skip) { continue }

    $role = $null
    $moduleName = $null
    foreach ($rule in $moduleRules) {
        if ($relative -match ([string]$rule.path_pattern)) {
            $role = [string]$rule.role
            $moduleName = [string](Get-ConfigValue $rule 'name' $rule.path_pattern)
            break
        }
    }

    $records += [pscustomobject]@{
        Path     = $relative
        Name     = $file.Name
        IsHeader = ($file.Extension -match '^\.(h|hpp)$')
        Role     = $role
        Module   = $moduleName
        Includes = @()
    }
}

if ($records.Count -eq 0) {
    Write-Host "FAIL: no source files found under '$rootFull'."
    exit 2
}

# ---------------------------------------------------------------- 解析 include
$byBasename = @{}
foreach ($record in $records) {
    if (-not $byBasename.ContainsKey($record.Name)) { $byBasename[$record.Name] = @() }
    $byBasename[$record.Name] += $record
}

$includePattern = '(?m)^\s*#\s*include\s*[<"]\s*([^">]+)\s*[">]'
foreach ($record in $records) {
    $content = Get-Content -LiteralPath (Join-Path $rootFull $record.Path) -Raw -Encoding utf8 -ErrorAction SilentlyContinue
    if ([string]::IsNullOrEmpty($content)) { continue }
    $found = @()
    foreach ($match in [regex]::Matches($content, $includePattern)) {
        $found += $match.Groups[1].Value.Trim()
    }
    $record.Includes = $found
}

function Resolve-IncludeRole {
    param([string]$IncludeText)

    # 语言标准头不承担架构角色，任何层都可以使用。
    foreach ($pattern in $languagePatterns) {
        if ($IncludeText -match $pattern) {
            return [pscustomobject]@{ Role = $null; Target = $IncludeText; Resolved = $false }
        }
    }

    foreach ($pattern in $externalPatterns) {
        if ($IncludeText -match $pattern) {
            return [pscustomobject]@{ Role = 'SL-010'; Target = $IncludeText; Resolved = $true }
        }
    }

    $basename = Split-Path -Leaf ($IncludeText -replace '\\', '/')
    if ($byBasename.ContainsKey($basename)) {
        $candidates = @($byBasename[$basename])
        $best = $candidates | Where-Object { $_.Path.EndsWith(($IncludeText -replace '\\', '/')) } | Select-Object -First 1
        if ($null -eq $best) { $best = $candidates[0] }
        return [pscustomobject]@{ Role = $best.Role; Target = $best.Path; Resolved = $true }
    }

    return [pscustomobject]@{ Role = $null; Target = $IncludeText; Resolved = $false }
}

function Test-Exception {
    param([string]$FilePath, [string]$RuleId)
    foreach ($exception in $exceptions) {
        $exceptionPattern = [string](Get-ConfigValue $exception 'path_pattern' '')
        $exceptionRule = [string](Get-ConfigValue $exception 'rule' '')
        if ($exceptionPattern -ne '' -and $FilePath -match $exceptionPattern -and ($exceptionRule -eq '' -or $exceptionRule -eq $RuleId)) {
            return $true
        }
    }
    return $false
}

$violations = [System.Collections.Generic.List[object]]::new()
$warnings = [System.Collections.Generic.List[object]]::new()

function Add-Violation {
    param([string]$Rule, [string]$Gate, [string]$Path, [string]$Detail)
    if (Test-Exception -FilePath $Path -RuleId $Rule) { return }
    $violations.Add([pscustomobject]@{ Rule = $Rule; Gate = $Gate; Path = $Path; Detail = $Detail })
}

function Add-Warning {
    param([string]$Rule, [string]$Path, [string]$Detail)
    if (Test-Exception -FilePath $Path -RuleId $Rule) { return }
    $warnings.Add([pscustomobject]@{ Rule = $Rule; Path = $Path; Detail = $Detail })
}

# ---------------------------------------------------------------- 环境接触面（AM-011）
# 这一段刻意不依赖角色映射：一个头是否环境中立，是可以直接测出来的事实。
# 先测事实再判角色，可以避免"因为把整个目录判成实现层，就再也没去扫它的公共头"
# 这类误判 —— 参见 SIG-010。
$directExternal = @{}
foreach ($record in $records) {
    $hits = @()
    foreach ($include in $record.Includes) {
        $isLanguage = $false
        foreach ($pattern in $languagePatterns) {
            if ($include -match $pattern) { $isLanguage = $true; break }
        }
        if ($isLanguage) { continue }

        foreach ($pattern in $externalPatterns) {
            if ($include -match $pattern) { $hits += $include; break }
        }
    }
    $directExternal[$record.Path] = @($hits | Sort-Object -Unique)
}

# 传递闭包上的第一条污染链，用来解释"这个头为什么不中立"
$reachCache = @{}
function Get-ExternalTrace {
    param([string]$Path, [int]$Depth = 0)

    if ($reachCache.ContainsKey($Path)) { return $reachCache[$Path] }
    if ($Depth -gt 16) { return '' }
    $reachCache[$Path] = ''

    if ($directExternal.ContainsKey($Path) -and ($directExternal[$Path].Count -gt 0)) {
        $reachCache[$Path] = $directExternal[$Path][0]
        return $reachCache[$Path]
    }

    if ($recordByPathEnv.ContainsKey($Path)) {
        foreach ($include in $recordByPathEnv[$Path].Includes) {
            $resolved = Resolve-IncludeRole -IncludeText $include
            if (-not $resolved.Resolved) { continue }
            $target = [string]$resolved.Target
            if (-not $recordByPathEnv.ContainsKey($target)) { continue }

            $nested = Get-ExternalTrace -Path $target -Depth ($Depth + 1)
            if (-not [string]::IsNullOrEmpty($nested)) {
                $reachCache[$Path] = "$include -> $nested"
                return $reachCache[$Path]
            }
        }
    }

    return $reachCache[$Path]
}

$recordByPathEnv = @{}
foreach ($record in $records) { $recordByPathEnv[$record.Path] = $record }

$headerPurity = @{}
foreach ($record in $records) {
    if (-not $record.IsHeader) { continue }

    $trace = Get-ExternalTrace -Path $record.Path
    $typeHit = ''
    if ([string]::IsNullOrEmpty($trace)) {
        $content = Get-Content -LiteralPath (Join-Path $rootFull $record.Path) -Raw -Encoding utf8 -ErrorAction SilentlyContinue
        if (-not [string]::IsNullOrEmpty($content)) {
            foreach ($pattern in $forbiddenTypes) {
                $m = [regex]::Match($content, $pattern)
                if ($m.Success) { $typeHit = $m.Value; break }
            }
        }
    }

    $headerPurity[$record.Path] = [pscustomobject]@{
        Neutral = ([string]::IsNullOrEmpty($trace) -and [string]::IsNullOrEmpty($typeHit))
        Reason  = if (-not [string]::IsNullOrEmpty($trace)) { "include $trace" }
                  elseif (-not [string]::IsNullOrEmpty($typeHit)) { "type $typeHit" }
                  else { '' }
    }
}

# 一条映射规则同时盖住"中立的头"和"接触环境的源"，几乎一定是契约+实现两个角色
$splitSkipRoles = @(Get-ConfigValue $config 'vendor_roles' @('SL-010')) +
                  @(Get-ConfigValue $config 'composition_roles' @('SL-006', 'SL-011'))

$ruleSplit = @()
foreach ($rule in $moduleRules) {
    $ruleName = [string](Get-ConfigValue $rule 'name' $rule.path_pattern)
    $ruleRole = [string]$rule.role

    # 厂商树和组合/测试目录天然是"干净头 + 脏源"，不构成误判信号
    if ($splitSkipRoles -contains $ruleRole) { continue }

    # 按实际归属统计，尊重"先匹配先生效"，不要重新匹配 pattern
    $owned = @($records | Where-Object { $_.Module -eq $ruleName })
    $neutralHeaders = @($owned | Where-Object { $_.IsHeader -and $headerPurity.ContainsKey($_.Path) -and $headerPurity[$_.Path].Neutral })
    $dirtySources = @($owned | Where-Object { (-not $_.IsHeader) -and ($directExternal[$_.Path].Count -gt 0) })

    if (($neutralHeaders.Count -gt 0) -and ($dirtySources.Count -gt 0)) {
        $ruleSplit += [pscustomobject]@{
            Name    = $ruleName
            Pattern = [string]$rule.path_pattern
            Role    = [string]$rule.role
            Neutral = $neutralHeaders.Count
            Dirty   = $dirtySources.Count
        }
    }
}

# ---------------------------------------------------------------- GATE-009 角色映射完整性
foreach ($split in $ruleSplit) {
    Add-Warning -Rule 'DR-014' -Path $split.Pattern `
        -Detail ("映射 '{0}' 判为 {1}，但它同时盖住 {2} 个环境中立的头和 {3} 个直接接触环境的源；这通常是契约+实现两个角色，应分开映射" -f $split.Name, $split.Role, $split.Neutral, $split.Dirty)
}

$unmapped = @($records | Where-Object { [string]::IsNullOrEmpty($_.Role) })
foreach ($record in $unmapped) {
    Add-Violation -Rule 'DR-014' -Gate 'GATE-009' -Path $record.Path -Detail '模块未映射到语义角色'
}

# ---------------------------------------------------------------- GATE-001 依赖方向
foreach ($record in $records) {
    if ([string]::IsNullOrEmpty($record.Role)) { continue }
    $allowedTargets = @()
    if ($allowed.ContainsKey($record.Role)) { $allowedTargets = @($allowed[$record.Role]) }

    foreach ($include in $record.Includes) {
        $resolved = Resolve-IncludeRole -IncludeText $include
        if (-not $resolved.Resolved) { continue }
        if ([string]::IsNullOrEmpty($resolved.Role)) { continue }
        if ($allowedTargets -contains $resolved.Role) { continue }

        Add-Violation -Rule 'DR-002' -Gate 'GATE-001' -Path $record.Path `
            -Detail "$($record.Role) -> $($resolved.Role) via '$include' ($($resolved.Target))"
    }
}

# ---------------------------------------------------------------- GATE-002 公共头纯度
foreach ($record in $records) {
    if (-not $record.IsHeader) { continue }
    if ([string]::IsNullOrEmpty($record.Role)) { continue }
    if (-not ($publicHeaderRoles -contains $record.Role)) { continue }

    $content = Get-Content -LiteralPath (Join-Path $rootFull $record.Path) -Raw -Encoding utf8 -ErrorAction SilentlyContinue
    if ([string]::IsNullOrEmpty($content)) { continue }

    foreach ($pattern in $forbiddenTypes) {
        foreach ($match in [regex]::Matches($content, $pattern)) {
            Add-Violation -Rule 'DR-003' -Gate 'GATE-002' -Path $record.Path `
                -Detail "公共头暴露环境类型 '$($match.Value)'"
            break
        }
    }
}

# ---------------------------------------------------------------- DR-004 组合根唯一可见
foreach ($record in $records) {
    if ([string]::IsNullOrEmpty($record.Role)) { continue }
    if ($compositionRoles -contains $record.Role) { continue }
    if ($implRoles -contains $record.Role) { continue }
    if ($record.Role -eq 'SL-010') { continue }

    foreach ($include in $record.Includes) {
        $resolved = Resolve-IncludeRole -IncludeText $include
        if (-not $resolved.Resolved -or [string]::IsNullOrEmpty($resolved.Role)) { continue }
        if ($implRoles -contains $resolved.Role) {
            Add-Violation -Rule 'DR-004' -Gate 'GATE-001' -Path $record.Path `
                -Detail "非组合根包含实现私有头 '$include' ($($resolved.Role))"
        }
    }
}

# ---------------------------------------------------------------- DR-012 过度抽象信号
# 实现方常常通过自己的适配器头间接包含契约（impl.c -> impl.h -> port.h），
# 因此这里按传递闭包判断"谁消费了这个 Port"，只看直接 include 会把已接线的
# 契约误报成投机抽象。
$recordByPath = @{}
foreach ($record in $records) { $recordByPath[$record.Path] = $record }

$closureCache = @{}
function Get-IncludeClosure {
    param([string]$Path, [int]$Depth = 0)

    if ($closureCache.ContainsKey($Path)) { return $closureCache[$Path] }
    if ($Depth -gt 16) { return @{} }

    $closureCache[$Path] = @{}          # 先占位，避免循环包含时无限递归
    $reached = @{}

    if ($recordByPath.ContainsKey($Path)) {
        foreach ($include in $recordByPath[$Path].Includes) {
            $resolved = Resolve-IncludeRole -IncludeText $include
            if (-not $resolved.Resolved) { continue }
            $target = [string]$resolved.Target
            if (-not $recordByPath.ContainsKey($target)) { continue }
            if ($reached.ContainsKey($target)) { continue }

            $reached[$target] = $true
            foreach ($nested in (Get-IncludeClosure -Path $target -Depth ($Depth + 1)).Keys) {
                $reached[$nested] = $true
            }
        }
    }

    $closureCache[$Path] = $reached
    return $reached
}

$portHeaders = @($records | Where-Object { $_.IsHeader -and $null -ne $_.Role -and ($portRoles -contains $_.Role) })
foreach ($port in $portHeaders) {
    $consumers = @()
    foreach ($record in $records) {
        if ($record.Path -eq $port.Path) { continue }
        if ((Get-IncludeClosure -Path $record.Path).ContainsKey($port.Path)) {
            $consumers += $record
        }
    }

    $implementations = @($consumers | Where-Object { $null -ne $_.Role -and ($implRoles -contains $_.Role) -and -not $_.IsHeader })

    $doubles = @()
    foreach ($consumer in $consumers) {
        $candidate = $consumer.Path.ToLowerInvariant()
        foreach ($pattern in $doublePatterns) {
            if ($candidate -match $pattern) { $doubles += $consumer; break }
        }
    }

    if ($implementations.Count -eq 0 -and $doubles.Count -eq 0) {
        Add-Warning -Rule 'DR-012' -Path $port.Path -Detail 'Port 没有任何实现或替身：可能是占位或投机抽象'
        continue
    }
    if ($implementations.Count -le 1 -and $doubles.Count -eq 0) {
        Add-Warning -Rule 'DR-012' -Path $port.Path -Detail "Port 只有 $($implementations.Count) 个实现且无测试替身：需说明真实变化轴，否则考虑直接依赖"
    }

    # 只有当"每一个"实现都仅包装环境中立的接口时，这个 Port 才没有隔离任何东西。
    # 任意一个实现真的碰了环境，它就是有效边界 —— 逐个实现报会产生噪声。
    $neutralWrapOnly = @()
    foreach ($impl in $implementations) {
        $wrapped = @()
        $alreadyNeutral = @()
        foreach ($include in $recordByPathEnv[$impl.Path].Includes) {
            $resolved = Resolve-IncludeRole -IncludeText $include
            if (-not $resolved.Resolved) { continue }
            $target = [string]$resolved.Target
            if ($target -eq $port.Path) { continue }
            if (-not $headerPurity.ContainsKey($target)) { continue }

            $wrapped += $target
            if ($headerPurity[$target].Neutral) { $alreadyNeutral += $target }
        }

        if (($wrapped.Count -gt 0) -and ($wrapped.Count -eq $alreadyNeutral.Count)) {
            $neutralWrapOnly += ("{0} -> {1}" -f $impl.Path, ($alreadyNeutral -join ', '))
        }
    }

    if (($implementations.Count -gt 0) -and ($neutralWrapOnly.Count -eq $implementations.Count)) {
        Add-Warning -Rule 'DR-012' -Path $port.Path `
            -Detail ("全部 {0} 个实现都只包装了已经环境中立的接口（{1}）：该 Port 未隔离任何环境类型，考虑让上层直接依赖" -f $implementations.Count, ($neutralWrapOnly -join '; '))
    }
}

# ---------------------------------------------------------------- 输出
$mappedRecords = @($records | Where-Object { -not [string]::IsNullOrEmpty($_.Role) })
$roleSummary = $mappedRecords | Group-Object Role | Sort-Object Name

# 厂商树自己当然接触环境，这里只关心"用户代码里谁碰了环境"。
$vendorRoles = @(Get-ConfigValue $config 'vendor_roles' @('SL-010'))
$contactFiles = @(
    $records |
        Where-Object { $directExternal[$_.Path].Count -gt 0 } |
        Where-Object { [string]::IsNullOrEmpty($_.Role) -or (-not ($vendorRoles -contains $_.Role)) } |
        Sort-Object Path
)
$ownHeaderPaths = @(
    $records |
        Where-Object { $_.IsHeader -and ([string]::IsNullOrEmpty($_.Role) -or (-not ($vendorRoles -contains $_.Role))) } |
        ForEach-Object { $_.Path }
)
$neutralHeaders = @($ownHeaderPaths | Where-Object { $headerPurity.ContainsKey($_) -and $headerPurity[$_].Neutral } | Sort-Object)
$leakyHeaders = @($ownHeaderPaths | Where-Object { $headerPurity.ContainsKey($_) -and (-not $headerPurity[$_].Neutral) } | Sort-Object)

if ($Evidence) {
    Write-Host ''
    Write-Host '############################################################'
    Write-Host '# 证据模式：本脚本只抓取可复现的事实，不判断任何角色。'
    Write-Host '# 「哪些是用户代码」「哪些是厂商代码」「目录意图是什么」'
    Write-Host '# 都不是脚本能看出来的 —— 下面的输出是给模型和人做判断的'
    Write-Host '# 原材料，不是结论。判断完成后写进 arch-map.json 再跑校验。'
    Write-Host '############################################################'
    if ($externalPatterns.Count -eq 0) {
        Write-Host ''
        Write-Host '注意：external_include_patterns 为空，环境接触面一栏必然为空。'
        Write-Host '      先读一遍仓库，确定本项目厂商头的命名特征，再填进来重跑。'
    }
}

Write-Host ''
Write-Host '=== 环境接触面（谁直接 include 了被声明为厂商/HAL/RTOS 的头） ==='
if ($contactFiles.Count -eq 0) {
    Write-Host '  (无。检查 external_include_patterns 是否填了本项目实际的厂商头前缀)'
}
foreach ($record in $contactFiles) {
    Write-Host ("  {0,-52} {1}" -f $record.Path, ($directExternal[$record.Path] -join ', '))
}

Write-Host ''
Write-Host ("=== 公共头环境中立性（角色无关的事实）：中立 {0} / 泄漏 {1} ===" -f $neutralHeaders.Count, $leakyHeaders.Count)
foreach ($path in $leakyHeaders) {
    Write-Host ("  LEAK   {0,-50} {1}" -f $path, $headerPurity[$path].Reason)
}
if ($Evidence) {
    foreach ($path in $neutralHeaders) {
        Write-Host ("  CLEAN  {0}" -f $path)
    }
}
elseif ($neutralHeaders.Count -gt 0) {
    Write-Host ("  CLEAN  {0} 个（用 -Discover 查看清单）" -f $neutralHeaders.Count)
}

if ($Evidence) {
    Write-Host ''
    Write-Host '=== 目录线索（仅供模型参考，脚本不做判断） ==='
    $byDir = $records |
        Where-Object { [string]::IsNullOrEmpty($_.Role) -or (-not ($vendorRoles -contains $_.Role)) } |
        Group-Object { Split-Path -Parent $_.Path } | Sort-Object Name
    foreach ($group in $byDir) {
        $dir = if ([string]::IsNullOrEmpty($group.Name)) { '.' } else { $group.Name.Replace('\', '/') }
        $hdr = @($group.Group | Where-Object { $_.IsHeader })
        $neu = @($hdr | Where-Object { $headerPurity.ContainsKey($_.Path) -and $headerPurity[$_.Path].Neutral })
        $con = @($group.Group | Where-Object { $directExternal[$_.Path].Count -gt 0 })

        $hint = '无明显线索'
        if (($hdr.Count -gt 0) -and ($neu.Count -eq $hdr.Count) -and ($con.Count -eq 0)) {
            $hint = '公共头全部环境中立 —— 可能已经是契约层'
        }
        elseif ($con.Count -gt 0) {
            $hint = '直接接触环境 —— 可能是实现层'
        }

        Write-Host ("  {0,-44} 头 {1,2}/中立 {2,2}  接触环境 {3,2}  -> {4}" -f $dir, $hdr.Count, $neu.Count, $con.Count, $hint)
    }
    Write-Host ''
    Write-Host '  提示：同一父目录下若出现"头全中立 + 源接触环境"的一对子目录，'
    Write-Host '        它就是已经存在的契约层与实现层，按 DR-014 分开映射，不要整目录一刀切。'
}

Write-Host ''
Write-Host '=== 角色映射（GATE-009） ==='
foreach ($group in $roleSummary) {
    Write-Host ("  {0}  文件数 {1}" -f $group.Name, $group.Count)
}
Write-Host ("  未映射文件数 {0}" -f $unmapped.Count)

$duplicateModules = @()
foreach ($moduleGroup in ($mappedRecords | Group-Object Module)) {
    $topLevels = @($moduleGroup.Group | ForEach-Object { ($_.Path -split '/')[0] } | Sort-Object -Unique)
    if ($topLevels.Count -gt 1) { $duplicateModules += $moduleGroup }
}

Write-Host ''
Write-Host '=== 基线指标（SIG-008） ==='
Write-Host ("  源文件总数              : {0}" -f $records.Count)
Write-Host ("  未分类模块数            : {0}" -f $unmapped.Count)
Write-Host ("  依赖方向违规数          : {0}" -f @($violations | Where-Object { $_.Rule -eq 'DR-002' }).Count)
Write-Host ("  公共头环境类型违规数    : {0}" -f @($violations | Where-Object { $_.Rule -eq 'DR-003' }).Count)
Write-Host ("  非组合根引用实现头数    : {0}" -f @($violations | Where-Object { $_.Rule -eq 'DR-004' }).Count)
Write-Host ("  跨顶层目录分布的模块数  : {0}" -f $duplicateModules.Count)
Write-Host ("  过度抽象候选 Port 数    : {0}" -f @($warnings | Where-Object { $_.Rule -eq 'DR-012' }).Count)

if ($violations.Count -gt 0) {
    Write-Host ''
    Write-Host '=== 违规（阻塞） ==='
    foreach ($violation in ($violations | Sort-Object Rule, Path)) {
        Write-Host ("  [{0}/{1}] {2}: {3}" -f $violation.Rule, $violation.Gate, $violation.Path, $violation.Detail)
    }
}

if ($warnings.Count -gt 0) {
    Write-Host ''
    Write-Host '=== 警告（需说明变化轴或接受） ==='
    foreach ($warning in ($warnings | Sort-Object Rule, Path)) {
        Write-Host ("  [{0}] {1}: {2}" -f $warning.Rule, $warning.Path, $warning.Detail)
    }
}

Write-Host ''
if ($Evidence) {
    Write-Host ("EVIDENCE: {0} 个用户文件接触环境，{1} 个公共头泄漏。以上均为事实，角色判断请由模型/人完成后写入 arch-map.json。" -f $contactFiles.Count, $leakyHeaders.Count)
    exit 0
}

if ($BaselineOnly) {
    Write-Host ("BASELINE: {0} violation(s), {1} warning(s). 未按门禁阻塞。" -f $violations.Count, $warnings.Count)
    exit 0
}

if ($violations.Count -gt 0 -or ($Strict -and $warnings.Count -gt 0)) {
    Write-Host ("FAIL: {0} violation(s), {1} warning(s)." -f $violations.Count, $warnings.Count)
    exit 1
}

Write-Host ("PASS: 0 violation(s), {0} warning(s)." -f $warnings.Count)
exit 0
