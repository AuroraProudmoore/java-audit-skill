# 覆盖率门禁检查脚本 (PowerShell 版本)
# 用于验证审计覆盖率是否达标

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath,
    
    [Parameter(Mandatory=$true)]
    [string]$ReviewedFile,
    
    [string]$OutputDir = "",
    
    [switch]$Help
)

if ($Help) {
    Write-Host @"
覆盖率门禁检查脚本

用法:
    .\coverage-check.ps1 -ProjectPath <项目路径> -ReviewedFile <审阅清单文件> [-OutputDir <输出目录>]

参数:
    -ProjectPath   项目根目录 (必需)
    -ReviewedFile  审阅清单文件路径 (必需)
    -OutputDir     输出目录 (可选，默认为项目目录下的 audit-output)
    -Help          显示帮助信息

门禁阈值:
    T1 (Controller/Filter): 必须 100% 覆盖
    T2 (Service/DAO): 95% 覆盖
    T3 (Entity/VO): 80% 覆盖
    总体: 大型项目 90%，中小型项目 95%
"@
    exit 0
}

# 设置输出目录
if ([string]::IsNullOrEmpty($OutputDir)) {
    $OutputDir = Join-Path $ProjectPath "audit-output"
}

# 创建输出目录
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

Write-Host "=" * 60
Write-Host "Phase 2.5: 覆盖率门禁检查"
Write-Host "=" * 60
Write-Host ""

# Tier 分类函数
function Get-Tier {
    param(
        [string]$FilePath,
        [string]$Content
    )
    
    if ($FilePath -match "target|node_modules|\.git|build|out") {
        return "SKIP"
    }
    
    if ($Content -match "@Controller|@RestController|@WebServlet|extends Filter|implements Filter|@HttpController") {
        return "T1"
    }
    
    if ($Content -match "@Service|@Repository|@Mapper|@Dao|@Component") {
        return "T2"
    }
    
    $filename = [System.IO.Path]::GetFileNameWithoutExtension($FilePath).ToLower()
    if ($filename -match "util|helper|handler|utils|config") {
        return "T2"
    }
    
    if ($Content -match "@Entity|@Table|@Data|extends BaseEntity|data class") {
        return "T3"
    }
    
    return "T2"
}

# 获取实际文件列表
$actualFiles = @{}
$t1Files = @{}
$t2Files = @{}
$t3Files = @{}

$files = Get-ChildItem -Path $ProjectPath -Recurse -Include *.java,*.kt -ErrorAction SilentlyContinue

foreach ($file in $files) {
    if ($file.FullName -match "target|node_modules|\.git|build|out|\.gradle|\.idea|test|tests") {
        continue
    }
    
    $fileName = $file.Name
    $actualFiles[$fileName] = $file.FullName
    
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { $content = "" }
    
    $tier = Get-Tier -FilePath $file.FullName -Content $content
    
    switch ($tier) {
        "T1" { $t1Files[$fileName] = $file.FullName }
        "T2" { $t2Files[$fileName] = $file.FullName }
        "T3" { $t3Files[$fileName] = $file.FullName }
    }
}

$actualCount = $actualFiles.Count
$t1Count = $t1Files.Count
$t2Count = $t2Files.Count
$t3Count = $t3Files.Count

# 读取审阅清单
$reviewedFiles = @{}
$reviewedT1 = @{}
$reviewedT2 = @{}
$reviewedT3 = @{}

if (Test-Path $ReviewedFile) {
    $content = Get-Content $ReviewedFile -Raw -ErrorAction SilentlyContinue
    
    # 方法1: 从 markdown 表格格式提取
    $tableMatches = [regex]::Matches($content, '\|\s*\d*\s*\|\s*`?([a-zA-Z0-9_/-]+\.(java|kt))`?\s*\|\s*(T[123])')
    foreach ($match in $tableMatches) {
        $filename = $match.Groups[1].Value
        $tier = $match.Groups[3].Value
        $reviewedFiles[$filename] = $true
        switch ($tier) {
            "T1" { $reviewedT1[$filename] = $true }
            "T2" { $reviewedT2[$filename] = $true }
            "T3" { $reviewedT3[$filename] = $true }
        }
    }
    
    # 方法2: 从代码块中的文件路径提取
    if ($reviewedFiles.Count -eq 0) {
        $codeMatches = [regex]::Matches($content, '`([a-zA-Z0-9_/-]+\.(java|kt))`')
        foreach ($match in $codeMatches) {
            $filename = $match.Groups[1].Value
            # 提取文件名（不含路径）
            $fileNameOnly = [System.IO.Path]::GetFileName($filename)
            $reviewedFiles[$fileNameOnly] = $true
        }
    }
    
    # 方法3: 从行首文件列表提取
    if ($reviewedFiles.Count -eq 0) {
        $lineMatches = [regex]::Matches($content, '^\s*([a-zA-Z0-9_/-]+\.(java|kt))\s*$', [System.Text.RegularExpressions.RegexOptions]::Multiline)
        foreach ($match in $lineMatches) {
            $filename = $match.Groups[1].Value
            $fileNameOnly = [System.IO.Path]::GetFileName($filename)
            $reviewedFiles[$fileNameOnly] = $true
        }
    }
}

$reviewedCount = $reviewedFiles.Count

# 计算遗漏
$missedFiles = @{}
foreach ($file in $actualFiles.Keys) {
    if (-not $reviewedFiles.ContainsKey($file)) {
        $missedFiles[$file] = $actualFiles[$file]
    }
}

$missedCount = $missedFiles.Count

# 计算各级别覆盖率
$t1Reviewed = ($reviewedT1.Keys | Where-Object { $t1Files.ContainsKey($_) }).Count
$t2Reviewed = ($reviewedT2.Keys | Where-Object { $t2Files.ContainsKey($_) }).Count
$t3Reviewed = ($reviewedT3.Keys | Where-Object { $t3Files.ContainsKey($_) }).Count

$t1Coverage = if ($t1Count -gt 0) { [Math]::Round($t1Reviewed / $t1Count * 100, 1) } else { 100 }
$t2Coverage = if ($t2Count -gt 0) { [Math]::Round($t2Reviewed / $t2Count * 100, 1) } else { 100 }
$t3Coverage = if ($t3Count -gt 0) { [Math]::Round($t3Reviewed / $t3Count * 100, 1) } else { 100 }

# 计算总体覆盖率
$coverage = if ($actualCount -gt 0) { [Math]::Round(($actualCount - $missedCount) / $actualCount * 100, 1) } else { 0 }

# T1 遗漏文件
$missedT1 = @{}
foreach ($file in $t1Files.Keys) {
    if (-not $reviewedT1.ContainsKey($file)) {
        $missedT1[$file] = $t1Files[$file]
    }
}

# 输出结果
Write-Host ""
Write-Host "[*] 覆盖率统计:"
Write-Host "  实际文件总数: $actualCount"
Write-Host "  已审阅文件数: $reviewedCount"
Write-Host "  遗漏文件数: $missedCount"
Write-Host "  总体覆盖率: $coverage%"

Write-Host ""
Write-Host "[*] 分层覆盖率:"
Write-Host "  T1 (Controller/Filter): $t1Reviewed/$t1Count = $t1Coverage%"
Write-Host "  T2 (Service/DAO): $t2Reviewed/$t2Count = $t2Coverage%"
Write-Host "  T3 (Entity/VO): $t3Reviewed/$t3Count = $t3Coverage%"

# 门禁判断
$t1Passed = $t1Coverage -eq 100
$overallPassed = $coverage -ge 90

if ($t1Passed -and $overallPassed) {
    Write-Host ""
    Write-Host "[OK] 门禁通过 - T1 覆盖率 100%，总体覆盖率 $coverage%" -ForegroundColor Green
    $passed = $true
} else {
    Write-Host ""
    Write-Host "[!] 门禁未通过:" -ForegroundColor Red
    if (-not $t1Passed) {
        Write-Host "  - T1 文件覆盖率 $t1Coverage% < 100%（必须 100%）" -ForegroundColor Red
    }
    if (-not $overallPassed) {
        Write-Host "  - 总体覆盖率 $coverage% < 90%" -ForegroundColor Red
    }
    
    if ($missedT1.Count -gt 0) {
        Write-Host ""
        Write-Host "[*] 遗漏的 T1 文件（必须补扫）:"
        $count = 0
        foreach ($file in $missedT1.Keys) {
            Write-Host "  - $file"
            $count++
            if ($count -ge 20) {
                Write-Host "  ... 还有 $($missedT1.Count - 20) 个文件"
                break
            }
        }
    }
    
    $passed = $false
}

# 生成报告
$reportPath = Join-Path $OutputDir "coverage-report.md"

$missedT1List = $missedT1.Keys | Select-Object -First 50
$missedOtherList = ($missedFiles.Keys | Where-Object { -not $missedT1.ContainsKey($_) }) | Select-Object -First 50

$reportContent = @"
# 覆盖率验证报告

## 覆盖率统计

| 指标 | 数值 |
|------|------|
| 实际文件总数 | $actualCount |
| 已审阅文件数 | $reviewedCount |
| 遗漏文件数 | $missedCount |
| **总体覆盖率** | **$coverage%** |

## 分层覆盖率

| Tier | 文件数 | 已审阅 | 覆盖率 | 要求 | 状态 |
|------|--------|--------|--------|------|------|
| T1 (Controller/Filter) | $t1Count | $t1Reviewed | $t1Coverage% | 100% | $(if ($t1Coverage -eq 100) { "✅ 通过" } else { "❌ 未通过" }) |
| T2 (Service/DAO) | $t2Count | $t2Reviewed | $t2Coverage% | 95% | $(if ($t2Coverage -ge 95) { "✅ 通过" } else { "⚠️ 需补扫" }) |
| T3 (Entity/VO) | $t3Count | $t3Reviewed | $t3Coverage% | 80% | $(if ($t3Coverage -ge 80) { "✅ 通过" } else { "⚠️ 需补扫" }) |

## 门禁状态

$(if ($passed) { "✅ **通过** - T1 覆盖率 100%，总体覆盖率 ≥ 90%" } else { "❌ **未通过** - T1 文件必须 100% 覆盖" })

"@

if ($missedCount -gt 0) {
    $reportContent += @"
## 遗漏文件列表

### T1 遗漏文件（必须补扫）
```
$(if ($missedT1.Count -gt 0) { $missedT1List -join "`n" } else { "无" })
$(if ($missedT1.Count -gt 50) { "... 还有 $($missedT1.Count - 50) 个文件" })
```

### 其他遗漏文件
```
$(if ($missedOtherList.Count -gt 0) { $missedOtherList -join "`n" } else { "无" })
$(if ($missedOtherList.Count -gt 50) { "... 还有 $($missedOtherList.Count - 50) 个文件" })
```
"@
}

$reportContent | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host ""
Write-Host "[OK] 覆盖率报告: $reportPath" -ForegroundColor Green

# 返回退出码
if ($passed) {
    exit 0
} else {
    exit 1
}