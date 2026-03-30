# Tier 分类脚本 (PowerShell 版本)
# 用于 Java/Kotlin 项目文件分类

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath,
    
    [string]$OutputDir = "",
    
    [switch]$Help
)

if ($Help) {
    Write-Host @"
Tier 分类脚本

用法:
    .\tier-classify.ps1 -ProjectPath <项目路径> [-OutputDir <输出目录>]

参数:
    -ProjectPath  项目根目录 (必需)
    -OutputDir    输出目录 (可选，默认为项目目录下的 audit-output)
    -Help         显示帮助信息

Tier 分类规则:
    T1 - Controller/Filter/Servlet (完整深度分析)
    T2 - Service/DAO/Util (聚焦关键维度)
    T3 - Entity/VO/DTO (快速模式匹配)
    SKIP - 第三方库源码 (不审计)
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
Write-Host "Phase 1: Tier 分类"
Write-Host "=" * 60
Write-Host ""

# Tier 分类函数
function Get-Tier {
    param(
        [string]$FilePath,
        [string]$Content
    )
    
    # Rule 0: 第三方库
    if ($FilePath -match "target|node_modules|\.git|build|out") {
        return "SKIP"
    }
    
    # Rule 2: Controller/Filter
    if ($Content -match "@Controller|@RestController|@WebServlet|extends Filter|implements Filter|@HttpController") {
        return "T1"
    }
    
    # Rule 3: Service/DAO
    if ($Content -match "@Service|@Repository|@Mapper|@Dao|@Component") {
        return "T2"
    }
    
    # Rule 4: Util/Helper
    $filename = [System.IO.Path]::GetFileNameWithoutExtension($FilePath).ToLower()
    if ($filename -match "util|helper|handler|utils|config") {
        return "T2"
    }
    
    # Rule 6: Entity
    if ($Content -match "@Entity|@Table|@Data|extends BaseEntity|data class") {
        return "T3"
    }
    
    # Rule 7: 未匹配，保守兜底
    return "T2"
}

# 分类统计
$tierFiles = @{
    "T1" = @()
    "T2" = @()
    "T3" = @()
    "SKIP" = @()
}

$tierLoc = @{
    "T1" = 0
    "T2" = 0
    "T3" = 0
    "SKIP" = 0
}

# 扫描文件
$files = Get-ChildItem -Path $ProjectPath -Recurse -Include *.java,*.kt -ErrorAction SilentlyContinue

foreach ($file in $files) {
    # 排除目录
    if ($file.FullName -match "target|node_modules|\.git|build|out|\.gradle|\.idea|test|tests") {
        continue
    }
    
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { $content = "" }
    
    $tier = Get-Tier -FilePath $file.FullName -Content $content
    
    $relPath = $file.FullName.Substring($ProjectPath.Length).TrimStart('\', '/')
    
    # 统计行数
    $lines = (Get-Content $file.FullName -ErrorAction SilentlyContinue | Measure-Object -Line).Lines
    
    $tierFiles[$tier] += $relPath
    $tierLoc[$tier] += $lines
}

# 计算 EALOC
$ealoc = $tierLoc["T1"] * 1.0 + $tierLoc["T2"] * 0.5 + $tierLoc["T3"] * 0.1
$agentsNeeded = [Math]::Ceiling($ealoc / 15000)
if ($agentsNeeded -lt 1) { $agentsNeeded = 1 }

# 输出统计
Write-Host ""
Write-Host "[*] Tier 分类统计:"
foreach ($tier in @("T1", "T2", "T3", "SKIP")) {
    Write-Host "  $tier`: $($tierFiles[$tier].Count) 文件, $($tierLoc[$tier].ToString('N0')) LOC"
}

Write-Host ""
Write-Host "[*] EALOC 计算:"
Write-Host "  EALOC = $([Math]::Round($ealoc).ToString('N0'))"
Write-Host "  建议 Agent 数: $agentsNeeded"

# 生成报告
$reportPath = Join-Path $OutputDir "tier-classification.md"

$reportContent = @"
# Tier 分类结果

## 统计摘要

| Tier | 文件数 | LOC | 权重 | EALOC 贡献 |
|------|--------|-----|------|------------|
| T1 (Controller/Filter) | $($tierFiles['T1'].Count) | $($tierLoc['T1'].ToString('N0')) | 1.0 | $($tierLoc['T1'].ToString('N0')) |
| T2 (Service/DAO/Util) | $($tierFiles['T2'].Count) | $($tierLoc['T2'].ToString('N0')) | 0.5 | $([Math]::Round($tierLoc['T2'] * 0.5).ToString('N0')) |
| T3 (Entity/VO/DTO) | $($tierFiles['T3'].Count) | $($tierLoc['T3'].ToString('N0')) | 0.1 | $([Math]::Round($tierLoc['T3'] * 0.1).ToString('N0')) |
| SKIP | $($tierFiles['SKIP'].Count) | - | - | - |

**总 EALOC**: $([Math]::Round($ealoc).ToString('N0'))  
**所需 Agent 数量**: $agentsNeeded (按 15,000 EALOC/Agent 预算)

## Tier 分类规则

| 规则 | 条件 | Tier |
|------|------|------|
| Rule 0 | 第三方库源码 | SKIP |
| Rule 2 | @Controller/@RestController/@WebServlet/Filter | T1 |
| Rule 3 | @Service/@Repository/@Mapper | T2 |
| Rule 4 | 类名含 Util/Helper/Handler | T2 |
| Rule 5 | .properties/.yml/security.xml | T2 |
| Rule 6 | @Entity/@Table/@Data | T3 |
| Rule 7 | 未匹配任何规则 | T2 (保守兜底) |

## 文件清单

### T1 文件 ($($tierFiles['T1'].Count) 个)
```
$($tierFiles['T1'] | Select-Object -First 50) -join "`n"
$(if ($tierFiles['T1'].Count -gt 50) { "... 还有 $($tierFiles['T1'].Count - 50) 个文件" })
```

### T2 文件 ($($tierFiles['T2'].Count) 个)
```
$($tierFiles['T2'] | Select-Object -First 30) -join "`n"
$(if ($tierFiles['T2'].Count -gt 30) { "... 还有 $($tierFiles['T2'].Count - 30) 个文件" })
```

### T3 文件 ($($tierFiles['T3'].Count) 个)
```
$($tierFiles['T3'] | Select-Object -First 30) -join "`n"
$(if ($tierFiles['T3'].Count -gt 30) { "... 还有 $($tierFiles['T3'].Count - 30) 个文件" })
```
"@

$reportContent | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host ""
Write-Host "[OK] Tier 分类报告: $reportPath" -ForegroundColor Green