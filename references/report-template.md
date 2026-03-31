# 标准化漏洞报告模板

每个漏洞报告必须包含三个核心部分：**描述**、**漏洞详情**、**修复建议**。

---

## ⚠️ 报告格式禁忌

### 1. 禁止在标题中添加严重程度标签

```markdown
❌ 错误：
### 任意文件上传漏洞（Critical）

✅ 正确：
### 任意文件上传漏洞
```

### 2. 禁止在漏洞详情前添加元信息块

```markdown
❌ 错误：
#### 漏洞详情

**漏洞位置**: CommonController.java:49-62
**漏洞类型**: CWE-434: 危险类型文件上传
**DKTSS评分**: 8.5

**代码位置**：
...

✅ 正确：
#### 漏洞详情

**代码位置**：
`E:\项目\src\main\java\com\example\controller\CommonController.java:49-62`
...
```

**说明**：严重程度、漏洞类型、DKTSS评分应在报告末尾的"漏洞清单"汇总表中体现，不应在每个漏洞详情中重复。

### 3. 代码位置必须使用完整绝对路径

```markdown
❌ 错误：
**代码位置**：
`CommonController.java:49-62`

✅ 正确：
**代码位置**：
`E:\工作代码\xx\xx\template\ibatis\generator-output\ibatis\template\java_src\com\xx\uap\mainacct\dao\UapMainAcctDao.java:49-62`
```

**说明**：代码位置必须是完整的绝对路径，方便用户直接定位文件。

---

## 报告格式规范

```markdown
### [漏洞标题]

#### 描述

[漏洞概述，200字以内，说明漏洞类型、成因、核心风险点]

#### 漏洞详情

**代码位置**：

[完整绝对路径]:[行号]

**代码片段**：

```java
// 带行号的代码片段（必须来自实际 Read 输出，不得编造）
```

**分析**：

[详细的漏洞分析，必须特别详细，包含以下所有要素]

#### 修复建议

[贴合问题代码的具体修复方案，分点说明并给出可执行的修复代码]

**修复代码示例**：

```java
// 具体的修复代码
```
```

---

## 完整示例

### 示例1: XXE 漏洞（文件上传接口）

#### 描述

在文件导入后，解析 Excel 时使用 EasyExcel 对数据进行解析，没有配置禁用 XML 外部实体的选项，并且 MultipartFile file 来自用户输入导致存在 XXE 风险。该文件导入接口没有文件类型校验（只检查是否为空），没有文件大小限制，存在任意文件导入，以及大文件导入时所触发的 DoS 问题。

#### 漏洞详情

**代码位置**：

```
E:\工作代码\项目名\src\main\java\com\example\controller\ExcelController.java:35
E:\工作代码\项目名\src\main\java\com\example\util\ExcelUtil.java:79
```

**代码片段**：

```java
// ExcelController.java
@PostMapping("/import")
public Result importExcel(@RequestParam("file") MultipartFile file) {
    if (file == null || file.isEmpty()) {
        throw new RuntimeException("没有文件或者文件内容为空！");
    }
    // 第35行：直接传入 ExcelUtil.importExcel 进行解析
    List<GeographicalInformationDto> dataList = ExcelUtil.importExcel(file);
    // ...
}

// ExcelUtil.java 第79行
public static List<GeographicalInformationDto> importExcel(MultipartFile file) {
    // ...
    ExcelListener<GeographicalInformationDto> listener = new ExcelListener<>();
    // 没有配置禁用 XML 外部实体的选项
    EasyExcel.read(ipt, GeographicalInformationDto.class, listener).sheet().doRead();
    // ...
}
```

**分析**：

1. **XXE 风险成因**：EasyExcel/POI 在底层解析 Excel（特别是 .xlsx 格式）时，会用到 XML 解析器。代码中没有配置禁用 XML 外部实体的选项，MultipartFile file 来自用户输入，没有进行充分的安全校验。

2. **文件本质**：.xlsx 文件本质上是 ZIP 压缩的 XML 文件集合。如果攻击者构造恶意的 Excel 文件，在 XML 中定义外部实体，可能导致：
   - 读取本地文件（如 `/etc/passwd`）
   - 发起 SSRF 请求
   - 拒绝服务攻击

3. **恶意输入示例**：
```xml
<!DOCTYPE data [
    <!ENTITY secret SYSTEM "file:///etc/passwd">
]>
<data>&secret;</data>
```

4. **其他风险**：
   - 没有文件类型校验（只检查是否为空）
   - 没有文件大小限制，可能触发 DDoS

#### 修复建议

**1. 限制上传类型和文件大小**：

```java
// 进行文件类型限制
private static final Set<String> ALLOWED_TYPES = Set.of(
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
);
private static final long MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB

public static List<GeographicalInformationDto> importExcel(MultipartFile file) {
    // 校验文件类型
    String contentType = file.getContentType();
    if (!ALLOWED_TYPES.contains(contentType)) {
        throw new RuntimeException("不支持的文件类型");
    }
    
    // 校验文件大小
    if (file.getSize() > MAX_FILE_SIZE) {
        throw new RuntimeException("文件大小超过限制");
    }
    
    // 校验文件扩展名
    String filename = file.getOriginalFilename();
    if (filename == null || !filename.toLowerCase().endsWith(".xlsx")) {
        throw new RuntimeException("文件扩展名不合法");
    }
    // ...
}
```

**2. 禁用 XML 外部实体解析**：

```java
public static List<GeographicalInformationDto> importExcel(MultipartFile file) {
    if (file == null || file.isEmpty()) {
        throw new RuntimeException("没有文件或者文件内容为空！");
    }
    List<GeographicalInformationDto> dataList = null;
    BufferedInputStream ipt = null;
    try {
        InputStream is = file.getInputStream();
        ipt = new BufferedInputStream(is);

        ExcelListener<GeographicalInformationDto> listener = new ExcelListener<>();
        
        // 配置安全的 XML 解析器
        SAXParserFactory factory = SAXParserFactory.newInstance();
        factory.setNamespaceAware(true);
        factory.setFeature(XMLConstants.FEATURE_SECURE_PROCESSING, true);
        factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
        factory.setFeature("http://xml.org/sax/features/external-general-entities", false);
        factory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
        factory.setXIncludeAware(false);
        factory.setValidating(false);
        
        XMLReader xmlReader = factory.newSAXParser().getXMLReader();
        
        ExcelReaderBuilder builder = EasyExcel.read(ipt, GeographicalInformationDto.class, listener);
        builder.xmlReader(xmlReader);
        builder.sheet().doRead();
        
        dataList = listener.getDataList();
    } catch (Exception e) {
        log.error(String.valueOf(e));
        throw new RuntimeException("数据导入失败！" + e);
    } finally {
        try {
            if (ipt != null) {
                ipt.close();
            }
        } catch (Exception e) {
            log.error("关闭输入流失败：" + e.getMessage());
        }
    }
    return dataList;
}
```

---

### 示例2: Velocity SSTI 导致远程代码执行

#### 描述

TemplateController.renderTemplate() 方法接收用户输入的 template 参数，直接传入 Velocity.evaluate() 进行模板渲染，未配置 SecureUberspector 限制反射调用。攻击者可构造恶意 Velocity 模板代码，通过反射调用 Runtime.exec() 执行任意系统命令，导致服务器被完全控制。

#### 漏洞详情

**代码位置**：

```
E:\工作代码\项目名\src\main\java\com\example\controller\TemplateController.java:45-52
```

**代码片段**：

```java
@PostMapping("/render")
public String renderTemplate(@RequestParam String template) {
    VelocityContext context = new VelocityContext();
    StringWriter writer = new StringWriter();
    // 危险：用户输入直接作为模板内容
    Velocity.evaluate(context, writer, "userTemplate", template);
    return writer.toString();
}
```

**分析**：

1. **漏洞成因**：用户输入的 `template` 参数未经任何过滤，直接作为模板内容传入 `Velocity.evaluate()`。Velocity 默认允许通过反射调用任意 Java 类和方法。

2. **攻击方式**：攻击者可构造包含恶意代码的 Velocity 模板：
```velocity
#set($x='')
#set($rt=$x.class.forName('java.lang.Runtime'))
#set($ex=$rt.getRuntime().exec('whoami'))
```

3. **影响范围**：
   - 执行任意系统命令
   - 读取服务器敏感文件
   - 植入后门实现持久化控制
   - 横向移动至内网其他系统

#### 修复建议

**1. 立即修复 - 配置 SecureUberspector**：

```java
VelocityEngine ve = new VelocityEngine();
ve.setProperty("runtime.introspector.uberspect", 
    "org.apache.velocity.util.introspection.SecureUberspector");
ve.init();

VelocityContext context = new VelocityContext();
StringWriter writer = new StringWriter();
ve.evaluate(context, writer, "userTemplate", template);
```

**2. 架构优化 - 使用预定义模板**：

```java
// 安全做法：不将用户输入直接作为模板内容
VelocityEngine ve = new VelocityEngine();
ve.init();

// 使用预定义模板
Template template = ve.getTemplate("templates/safe-template.vm");
VelocityContext context = new VelocityContext();
context.put("userContent", sanitizedInput);  // 用户内容作为参数注入

StringWriter writer = new StringWriter();
template.merge(context, writer);
return writer.toString();
```

**3. 纵深防御**：

```java
// 添加输入白名单校验
private static final Pattern SAFE_CONTENT = Pattern.compile("^[a-zA-Z0-9\\s\\.,!?]+$");

public String renderTemplate(@RequestParam String template) {
    // 白名单校验
    if (!SAFE_CONTENT.matcher(template).matches()) {
        throw new SecurityException("非法输入");
    }
    // ...
}
```

---

## 行号定位规范

### 精确行号要求

**必须使用实际 Read/Select-String 验证的行号**，禁止模糊范围或猜测。

| 错误示例 | 正确示例 | 说明 |
|----------|----------|------|
| `HeaderModelUtils.java:18-35` | `HeaderModelUtils.java:35` | 精确到方法起始行 |
| `HttpUtil.java:177-193` | `HttpUtil.java:252-253, 321` | 多段代码分开标注 |
| `SupplierBaseService.java:138-143` | `SupplierBaseService.java:186,188` | 精确到具体行 |

### 行号验证方法

```bash
# 使用 Select-String 验证行号
Select-String -Path $file -Pattern "getLoginUserByStr|TrustAllTrustManager" | 
  ForEach-Object { Write-Host "Line $($_.LineNumber): $($_.Line.Trim())" }
```

### 多位置标注格式

当漏洞涉及多个代码位置时：

```markdown
**代码位置**：

```
HttpUtil.java:252-253        # SSLContext 初始化
HttpUtil.java:321-335        # TrustAllTrustManager 定义
```
```

---

## 分析描述颗粒度规范

### 分析必须包含的要素

每个漏洞的"分析"部分必须包含以下要素，缺一不可：

| 要素 | 说明 | 示例 |
|------|------|------|
| **具体方法名** | 精确到类名.方法名() | `HeaderModelUtils.getLoginUserByStr()` |
| **调用链追踪** | 从入口到漏洞点的完整路径 | Controller → Header → Service |
| **对比分析** | 与同类安全代码的差异 | `querySheetList()` 有校验 vs `querySheetDetail()` 无校验 |
| **发现未使用的安全机制** | 项目中存在但未启用的安全配置 | JWT依赖引入但未使用 |
| **归纳漏洞类型** | 标准漏洞分类 | 客户端信任漏洞、IDOR、中间人攻击 |

### ⚠️ 禁止片面分析

**分析必须全面深入，不能只写表面现象。**

```markdown
❌ 片面分析（不可接受）：
`CommonController.uploadFile()` 方法接收用户上传的文件，没有对文件类型进行校验，
攻击者可以上传恶意文件。

问题：
- 没有说明具体哪个方法有问题
- 没有调用链追踪
- 没有说明缺少哪些具体的安全控制
- 没有对比分析
- 没有攻击路径说明

✅ 全面分析（符合要求）：
`CommonController.uploadFile()` 方法（CommonController.java:49）接收 MultipartFile 参数，
直接调用 `FileUtil.saveFile()` 保存到服务器，路径为 `/var/www/uploads/`。

**调用链追踪**：
```
CommonController.uploadFile() (CommonController.java:49)
  → FlightCommonServiceImpl.uploadAttachment() (FlightCommonServiceImpl.java:216)
    → FileUtil.saveFile() (FileUtil.java:102)
```

**缺少的安全控制**：
1. **文件类型校验**：未检查 Content-Type 和文件扩展名
2. **文件内容校验**：未检查文件魔数/文件头
3. **文件名处理**：使用原始文件名，未重命名
4. **上传路径**：路径固定且可访问

**对比分析**：
同类方法 `ImageController.uploadImage()` 在 Service 层有完整的校验：
- 检查 Content-Type 是否为 image/*
- 检查文件扩展名白名单
- 使用 UUID 重命名文件
而 `CommonController.uploadFile()` 完全没有这些校验。

**攻击路径**：
1. 攻击者构造恶意 JSP WebShell
2. 修改 Content-Type 为 image/jpeg 绕过前端校验
3. 上传到 `/var/www/uploads/shell.jsp`
4. 访问 `https://target.com/uploads/shell.jsp` 执行任意命令

**归纳漏洞类型**：任意文件上传（CWE-434）
```

### 分析模板

```markdown
`ClassName.methodName()` 方法[具体行为描述]。系统[缺少的安全控制]，
攻击者可以[攻击路径]。形成**[漏洞类型]**（CWE-XXX）。

对比同类方法 `OtherClass.safeMethod()`，该方法[差异描述]，
进一步验证了安全控制的缺失。

经审查 `pom.xml` 发现项目已引入[安全依赖]，但全局搜索显示实际并未使用。
```

### 颗粒度对比

#### ❌ 模糊分析（不可接受）

```
1. **漏洞成因**：系统信任客户端传来的用户身份信息，仅做Base64解码，无签名验证。
2. **攻击方式**：攻击者可构造恶意JSON伪造身份。
3. **影响范围**：任意用户身份伪造。
```

#### ✅ 精准分析（符合要求）

```
`HeaderModelUtils.getLoginUserByStr()` 方法仅对 Header 中的 Base64 编码数据
进行解码，然后直接调用 `GsonUtil.getGson2().fromJson()` 反序列化为 LoginUserBo 对象。
系统没有对用户信息进行任何签名验证或加密保护，攻击者可以轻松伪造任意用户的登录信息。

控制器层（如 `FlightController.setFlightCityHistory()`）直接从请求头 `la517_loginUser`
获取用户信息，该信息未经服务器端验证就传递给服务层使用，形成**客户端信任漏洞**。

经审查 `pom.xml` 发现项目已引入 JWT 相关依赖（`jjwt`），但全局搜索显示实际并未使用。
`LogInterceptor` 拦截器仅用于日志追踪（requestId 生成），不包含任何认证逻辑。
```

---

## CVE 编号核实规范

### ⚠️ 禁止凭记忆编造 CVE 编号

**铁律**：所有 CVE 编号必须联网核实，禁止凭记忆/猜测编造。

#### 核实流程

```markdown
Step 1: 使用 tavily 搜索
  node ~/.openclaw/workspace/skills/tavily-search/scripts/search.mjs "<组件名> <版本号> CVE" -n 10

Step 2: 确认来源可靠
  ✅ NVD (nvd.nist.gov)
  ✅ Snyk (security.snyk.io)
  ✅ 官方公告 (Apache/GitHub Security Advisories)
  ❌ 随机博客/论坛帖子

Step 3: 确认组件对应关系
  某个 CVE 可能只影响特定框架/组件，需确认 artifact 对应关系
  
  示例：
  - CVE-2020-1948 → Apache Dubbo（不是 Hessian）
  - CVE-2020-11995 → com.caucho:hessian（不是 dubbo-hessian-lite）
  - CVE-2024-46983 → com.alipay.sofa:hessian（不是 com.caucho:hessian）
```

#### 报告中的 CVE 描述格式

```markdown
✅ 正确格式：
  **CVE-2021-44228** (Log4Shell) - CVSS 10.0 Critical
  来源：https://nvd.nist.gov/vuln/detail/CVE-2021-44228
  影响版本：log4j-core 2.0-beta9 to 2.15.0
  当前版本 2.14.1 处于影响范围内

❌ 错误格式：
  CVE-2020-1948: Hessian 反序列化远程代码执行
  （未核实，CVE-2020-1948 实际是 Dubbo 漏洞，与 Hessian 无关）
```

---

## 不合格示例对比

### ❌ 不合格的漏洞分析（三点式）

```markdown
**分析**：

1. **漏洞成因**：系统信任客户端传来的用户身份信息，仅做Base64解码，无签名验证。
2. **攻击方式**：攻击者可构造恶意JSON伪造身份。
3. **影响范围**：任意用户身份伪造。
```

**问题**：
- ❌ 缺少具体方法名
- ❌ 缺少调用链追踪
- ❌ 缺少对比分析
- ❌ 缺少未使用的安全机制
- ❌ 分析过于笼统，无法验证

---

### ✅ 合格的漏洞分析（L3 级别）

```markdown
**分析**：

`HeaderModelUtils.getLoginUserByStr()` 方法（位于 HeaderModelUtils.java:35）
仅对 Header 中的 Base64 编码数据进行解码，然后直接调用 
`GsonUtil.getGson2().fromJson()` 反序列化为 LoginUserBo 对象。

**调用链追踪**：
```
FlightController.setFlightCityHistory() (FlightController.java:102)
  → HeaderModelUtils.getLoginUserByStr() (HeaderModelUtils.java:35)
    → GsonUtil.getGson2().fromJson() (GsonUtil.java:28)
```

**缺少的安全控制**：
- 无签名验证（JWT 未使用）
- 无加密保护（Base64 仅编码，非加密）
- 无服务器端身份核验

**对比分析**：
同类方法 `querySheetList()` 在 Service 层使用 `SecurityUtils.getCurrentUser()`
获取用户身份（从 Session 获取，不可伪造），而 `setFlightCityHistory()` 
直接从请求头获取用户信息，跳过了 Session 验证。

**未使用的安全机制**：
经审查 `pom.xml` 发现项目已引入 JWT 相关依赖（`io.jsonwebtoken:jjwt:0.9.1`），
但全局搜索显示：
```
Select-String -Path "*.java" -Pattern "JwtBuilder|JwtParser" → 无结果
```
`LogInterceptor` 拦截器（LogInterceptor.java:45）仅用于日志追踪（requestId 生成），
不包含任何认证逻辑。

**归纳漏洞类型**：客户端信任漏洞（CWE-287）
```

---

## 分析深度分级

| 级别 | 要求 | 适用场景 |
|------|------|----------|
| L1 基础 | 说明漏洞存在原因 | 快速扫描结果 |
| L2 标准 | +调用链+漏洞类型 | 常规审计报告 |
| L3 深度 | +对比分析+未使用安全机制 | 详细漏洞报告 |

**java-audit-skill 审计要求 L3 深度级别**。

---

## 报告生成检查清单

每个漏洞报告提交前，确认以下要求：

### 描述部分
- [ ] 字数控制在200字以内
- [ ] 清晰说明漏洞类型（如XXE、SSTI、SQL注入等）
- [ ] 说明漏洞成因和核心风险点

### 漏洞详情部分
- [ ] 代码位置准确（完整路径 + 行号）
- [ ] 代码片段来自实际 Read 输出，带行号
- [ ] 分析内容详细，包括：
  - [ ] 为什么存在安全问题
  - [ ] 攻击者如何利用
  - [ ] 恶意输入示例（如适用）
  - [ ] 影响范围

### 修复建议部分
- [ ] 针对具体问题给出修复方案
- [ ] 提供可直接使用的修复代码
- [ ] 如有多处需要修复，分点说明

---

## 状态定义

| 状态 | 定义 | 要求 |
|------|------|------|
| **CONFIRMED** | 已验证可利用 | PoC 可执行，调用链完整，影响明确 |
| **HYPOTHESIS** | 疑似漏洞，需人工验证 | 发现可疑模式但无法完全确认 |

**关键原则**：宁可标记为 HYPOTHESIS 让人工验证，也不要把不确定的发现标记为 CONFIRMED 污染报告可信度。

---

## 多漏洞报告格式

当一个项目存在多个漏洞时，按以下格式组织：

```markdown
# [项目名称] 安全审计报告

**审计日期**：YYYY-MM-DD  
**审计人员**：[审计员名称]  
**项目规模**：[代码行数/文件数]  
**风险统计**：Critical X个 / High X个 / Medium X个 / Low X个

---

## 漏洞清单

| 编号 | 漏洞标题 | 严重程度 | 状态 | 文件位置 |
|------|---------|---------|------|---------|
| VULN-001 | XXE文件上传漏洞 | Critical | CONFIRMED | ExcelController.java:35 |
| VULN-002 | Velocity SSTI 远程代码执行 | Critical | CONFIRMED | TemplateController.java:45 |

---

## 详细漏洞报告

### VULN-001: XXE文件上传漏洞

[按上述三段式格式填写]

### VULN-002: Velocity SSTI 远程代码执行

[按上述三段式格式填写]

---

## 修复优先级建议

1. **立即修复**：[Critical 级别漏洞列表]
2. **本周修复**：[High 级别漏洞列表]
3. **计划修复**：[Medium/Low 级别漏洞列表]
```