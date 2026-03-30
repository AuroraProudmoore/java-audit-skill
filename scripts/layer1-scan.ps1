# Layer 1 危险模式预扫描 (PowerShell 版本)
# 用于 Java/Kotlin 项目安全审计

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath,
    
    [string]$OutputDir = "",
    
    [switch]$Help
)

if ($Help) {
    Write-Host @"
Layer 1 危险模式预扫描

用法:
    .\layer1-scan.ps1 -ProjectPath <项目路径> [-OutputDir <输出目录>]

参数:
    -ProjectPath  项目根目录 (必需)
    -OutputDir    输出目录 (可选，默认为项目目录下的 audit-output)
    -Help         显示帮助信息

示例:
    .\layer1-scan.ps1 -ProjectPath C:\Projects\myapp
    .\layer1-scan.ps1 -ProjectPath C:\Projects\myapp -OutputDir C:\Reports
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
Write-Host "Layer 1: 危险模式预扫描"
Write-Host "=" * 60
Write-Host ""

# P0 危险模式定义
$P0_PATTERNS = @{
    "反序列化" = @("ObjectInputStream", "XMLDecoder", "XStream", "JSON.parseObject", "JSON.parse", "@type",
                   "enableDefaultTyping", "activateDefaultTyping", "HessianInput", "Hessian2Input",
                   "new Yaml(", "SnakeYAML")
    "SSTI" = @("Velocity.evaluate", "VelocityEngine", "freemarker.template", "Template.process",
               "SpringTemplateEngine", "TemplateEngine.process")
    "表达式注入" = @("SpelExpressionParser", "parseExpression", "evaluateExpression", "OgnlUtil", "Ognl.getValue",
                   "MVEL.eval", "MVEL.executeExpression")
    "JNDI" = @("InitialContext.lookup", "JdbcRowSetImpl", "setDataSourceName")
    "命令执行" = @("Runtime.getRuntime", "ProcessBuilder", ".exec(")
}

# P1 危险模式定义
$P1_PATTERNS = @{
    "SQL注入" = @("Statement", "createStatement", "executeQuery", "executeUpdate",
                 "createQuery", "createNativeQuery")
    "MyBatis注入" = @('${')
    "SSRF" = @("new URL(", "HttpURLConnection", "HttpClient", "RestTemplate", "WebClient", "OkHttpClient")
    "文件操作" = @("FileInputStream", "FileOutputStream", "FileWriter", "Files.read", "Files.write",
                 "getOriginalFilename", "transferTo", "MultipartFile", "Paths.get")
    "XXE" = @("DocumentBuilder", "SAXParser", "XMLReader", "XMLInputFactory", "SAXReader", "SAXBuilder")
}

# P2 危险模式定义
$P2_PATTERNS = @{
    "认证" = @("@PreAuthorize", "@Secured", "@RolesAllowed", "hasRole", "hasAuthority", "permitAll")
    "加密" = @("MessageDigest", "Cipher", "SecretKey", "PasswordEncoder", "MD5", "SHA-1")
    "配置" = @("debug:", "swagger", "actuator", "h2.console")
}

# 扫描函数
function Invoke-Scan {
    param(
        [string]$Level,
        [hashtable]$Patterns
    )
    
    $results = @{}
    
    foreach ($category in $Patterns.Keys) {
        $keywords = $Patterns[$category]
        $findings = @()
        
        foreach ($keyword in $keywords) {
            # 扫描 Java 和 Kotlin 文件
            $files = Get-ChildItem -Path $ProjectPath -Recurse -Include *.java,*.kt -ErrorAction SilentlyContinue
            
            foreach ($file in $files) {
                # 排除目录
                if ($file.FullName -match "target|node_modules|\.git|build|out|\.gradle|\.idea|test|tests") {
                    continue
                }
                
                $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
                if ($content -and $content -match [regex]::Escape($keyword)) {
                    $relPath = $file.FullName.Substring($ProjectPath.Length).TrimStart('\', '/')
                    
                    # 找到行号
                    $lines = Get-Content $file.FullName -ErrorAction SilentlyContinue
                    for ($i = 0; $i -lt $lines.Count; $i++) {
                        if ($lines[$i] -match [regex]::Escape($keyword)) {
                            $findings += @{
                                File = $relPath
                                Line = $i + 1
                                Keyword = $keyword
                                Snippet = $lines[$i].Trim().Substring(0, [Math]::Min(100, $lines[$i].Trim().Length))
                            }
                            break
                        }
                    }
                }
            }
        }
        
        if ($findings.Count -gt 0) {
            $results[$category] = $findings
        }
    }
    
    return $results
}

# 执行扫描
Write-Host "[*] 扫描 P0 级危险模式..."
$p0Results = Invoke-Scan -Level "P0" -Patterns $P0_PATTERNS

Write-Host "[*] 扫描 P1 级危险模式..."
$p1Results = Invoke-Scan -Level "P1" -Patterns $P1_PATTERNS

Write-Host "[*] 扫描 P2 级危险模式..."
$p2Results = Invoke-Scan -Level "P2" -Patterns $P2_PATTERNS

# 输出结果
$totalFindings = 0

Write-Host ""
Write-Host "=" * 60
Write-Host "扫描结果"
Write-Host "=" * 60

# P0 结果
if ($p0Results.Count -gt 0) {
    Write-Host ""
    Write-Host "[!] P0 级发现 (Critical):" -ForegroundColor Red
    foreach ($category in $p0Results.Keys) {
        $findings = $p0Results[$category]
        Write-Host "  [$category] $($findings.Count) 处" -ForegroundColor Yellow
        foreach ($f in $findings | Select-Object -First 5) {
            Write-Host "    - $($f.File):$($f.Line) ($($f.Keyword))"
        }
        if ($findings.Count -gt 5) {
            Write-Host "    ... 还有 $($findings.Count - 5) 处"
        }
        $totalFindings += $findings.Count
    }
}

# P1 结果
if ($p1Results.Count -gt 0) {
    Write-Host ""
    Write-Host "[!] P1 级发现 (High):" -ForegroundColor Yellow
    foreach ($category in $p1Results.Keys) {
        $findings = $p1Results[$category]
        Write-Host "  [$category] $($findings.Count) 处" -ForegroundColor Yellow
        foreach ($f in $findings | Select-Object -First 5) {
            Write-Host "    - $($f.File):$($f.Line) ($($f.Keyword))"
        }
        if ($findings.Count -gt 5) {
            Write-Host "    ... 还有 $($findings.Count - 5) 处"
        }
        $totalFindings += $findings.Count
    }
}

# P2 结果
if ($p2Results.Count -gt 0) {
    Write-Host ""
    Write-Host "[!] P2 级发现 (Medium):" -ForegroundColor Cyan
    foreach ($category in $p2Results.Keys) {
        $findings = $p2Results[$category]
        Write-Host "  [$category] $($findings.Count) 处"
        foreach ($f in $findings | Select-Object -First 3) {
            Write-Host "    - $($f.File):$($f.Line) ($($f.Keyword))"
        }
        if ($findings.Count -gt 3) {
            Write-Host "    ... 还有 $($findings.Count - 3) 处"
        }
        $totalFindings += $findings.Count
    }
}

Write-Host ""
Write-Host "[*] 总计发现: $totalFindings 处危险模式"

# 生成报告
$p0ReportPath = Join-Path $OutputDir "p0-critical.md"
$p1ReportPath = Join-Path $OutputDir "p1-high.md"
$p2ReportPath = Join-Path $OutputDir "p2-medium.md"

# P0 报告
$p0Content = "# P0 级危险模式`n`n## 发现记录`n`n"
if ($p0Results.Count -gt 0) {
    foreach ($category in $p0Results.Keys) {
        $p0Content += "### $category`n`n"
        foreach ($f in $p0Results[$category]) {
            $p0Content += "- ``$($f.File):$($f.Line)`` - ``$($f.Keyword)```n"
        }
        $p0Content += "`n"
    }
} else {
    $p0Content += "未发现该级别危险模式。`n"
}
$p0Content | Out-File -FilePath $p0ReportPath -Encoding UTF8

# P1 报告
$p1Content = "# P1 级危险模式`n`n## 发现记录`n`n"
if ($p1Results.Count -gt 0) {
    foreach ($category in $p1Results.Keys) {
        $p1Content += "### $category`n`n"
        foreach ($f in $p1Results[$category]) {
            $p1Content += "- ``$($f.File):$($f.Line)`` - ``$($f.Keyword)```n"
        }
        $p1Content += "`n"
    }
} else {
    $p1Content += "未发现该级别危险模式。`n"
}
$p1Content | Out-File -FilePath $p1ReportPath -Encoding UTF8

# P2 报告
$p2Content = "# P2 级危险模式`n`n## 发现记录`n`n"
if ($p2Results.Count -gt 0) {
    foreach ($category in $p2Results.Keys) {
        $p2Content += "### $category`n`n"
        foreach ($f in $p2Results[$category]) {
            $p2Content += "- ``$($f.File):$($f.Line)`` - ``$($f.Keyword)```n"
        }
        $p2Content += "`n"
    }
} else {
    $p2Content += "未发现该级别危险模式。`n"
}
$p2Content | Out-File -FilePath $p2ReportPath -Encoding UTF8

Write-Host ""
Write-Host "[OK] 扫描报告:" -ForegroundColor Green
Write-Host "  - $p0ReportPath"
Write-Host "  - $p1ReportPath"
Write-Host "  - $p2ReportPath"