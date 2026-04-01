# 标准化漏洞报告模板

每个漏洞报告包含核心三部分：**描述**、**漏洞详情**、**修复建议**，并配合**漏洞列表**和**审计进度**展示。

---

## 报告整体结构

```markdown
# [项目名称] 安全审计报告

## 漏洞列表

| 序号 | 漏洞名称 |
|------|---------|
| 1 | [漏洞名称1] |
| 2 | [漏洞名称2] |
| ... | ... |

## 审计进度

| 审计层级 | 进度 | 说明 |
|---------|------|------|
| L1 危险模式扫描 | ✅ 已完成 | 发现 X 个候选漏洞 |
| L2 双轨审计 | ✅ 已完成 | 确认 Y 个有效漏洞 |
| L3 调用链验证 | ✅ 已完成 | 全部漏洞已验证 |

---

## 详细漏洞报告

# [漏洞名称1]

### 描述

[漏洞归纳描述，100字左右]

### 漏洞详情

**代码位置**：

[问题代码的完整绝对路径]:[行号]

**问题代码展示**：

```java
// 带行号的问题代码展示，包含上下文
```

**漏洞分析**：

[细颗粒度整体分析，300字以上，面面俱到]

### 修复建议

[完整的解决方案，贴合代码实际情况]

---

# [漏洞名称2]

...
```

---

## ⚠️ 报告格式规范

### 1. 标题层级

| 内容 | 标签 | 说明 |
|------|------|------|
| 漏洞名称 | h1 (`#`) | 单独一个大名称 |
| 描述 | h3 (`###`) | 漏洞归纳描述 |
| 漏洞详情 | h3 (`###`) | 包含代码位置、代码展示、漏洞分析 |
| 修复建议 | h3 (`###`) | 完整解决方案 |

### 2. 禁止在标题中添加严重程度标签

```markdown
❌ 错误：
# 任意文件上传漏洞（Critical）

✅ 正确：
# 任意文件上传漏洞
```

### 3. 代码位置必须使用完整绝对路径

```markdown
❌ 错误：
**代码位置**：
CommonController.java:49-62

✅ 正确：
**代码位置**：
E:\工作代码\xx\xx\src\main\java\com\example\controller\CommonController.java:49-62
```

---

## 各部分详细规范

### 一、描述（h3）

**要求**：对漏洞进行归纳描述，字数在100字左右。

**必须包含**：
- 漏洞类型
- 核心成因
- 主要风险点

**示例**：
```markdown
### 描述

在文件导入后，解析 Excel 时使用 EasyExcel 对数据进行解析，没有配置禁用 XML 外部实体的选项，
MultipartFile file 来自用户输入导致存在 XXE 风险。该文件导入接口没有文件类型校验和文件大小限制，
存在任意文件导入和 DoS 问题。
```

---

### 二、漏洞详情（h3）

漏洞详情细分为三个模块：**代码位置**、**问题代码展示**、**漏洞分析**。

#### 2.1 代码位置

**要求**：书写问题代码的完整绝对路径。

**格式**：
```markdown
**代码位置**：

E:\项目路径\src\main\java\com\example\controller\ExcelController.java:35
E:\项目路径\src\main\java\com\example\util\ExcelUtil.java:79
```

#### 2.2 问题代码展示

**要求**：对问题代码进行展示，包含其上下文。

**格式**：
```markdown
**问题代码展示**：

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
```

#### 2.3 漏洞分析

**要求**：对该漏洞进行细颗粒度的整体分析，要面面俱到，详细完整阐述该问题，字数在300字以上。

**必须包含**：
1. **具体方法名**：精确到 `ClassName.methodName()`
2. **调用链追踪**：从入口到漏洞点的完整路径，每一跳标注 文件:行号
3. **缺少的安全控制**：表格形式列出
4. **攻击路径**：步骤形式（1、2、3...）
5. **对比分析**：与安全代码的差异
6. **未使用的安全机制**：项目中存在但未启用
7. **漏洞类型归纳**：CWE 标准分类

**示例**：
```markdown
**漏洞分析**：

`ExcelController.importExcel()` 方法（ExcelController.java:35）接收 MultipartFile 参数，
直接调用 `ExcelUtil.importExcel()` 保存到服务器，路径为 `/var/www/uploads/`。

**调用链追踪**：
```
ExcelController.importExcel() (ExcelController.java:35)
  → ExcelUtil.importExcel() (ExcelUtil.java:79)
    → EasyExcel.read() (ExcelUtil.java:82)
```

**缺少的安全控制**：

| 控制类型 | 状态 | 说明 |
|---------|------|------|
| 文件类型校验 | ❌ 缺失 | 未检查 Content-Type 和文件扩展名 |
| 文件内容校验 | ❌ 缺失 | 未检查文件魔数/文件头 |
| 文件大小限制 | ❌ 缺失 | 可上传超大文件触发 DoS |
| XXE 防护 | ❌ 缺失 | 未禁用 XML 外部实体 |

**攻击路径**：

1. 攻击者构造恶意 Excel 文件，在 XML 中定义外部实体
2. 外部实体指向 `/etc/passwd` 等敏感文件
3. 上传文件到服务器进行解析
4. 解析过程中 XML 外部实体被加载，读取服务器敏感文件
5. 文件内容通过响应返回给攻击者

**恶意输入示例**：
```xml
<!DOCTYPE data [
    <!ENTITY secret SYSTEM "file:///etc/passwd">
]>
<data>&secret;</data>
```

**对比分析**：
同类方法 `ImageController.uploadImage()` 在 Service 层有完整的校验：
- 检查 Content-Type 是否为 image/*
- 检查文件扩展名白名单
- 配置了安全的 XML 解析器

而 `ExcelController.importExcel()` 完全没有这些校验。

**未使用的安全机制**：
项目已引入 Apache POI 的安全配置选项，但未启用：
```xml
<dependency>
    <groupId>org.apache.poi</groupId>
    <artifactId>poi-ooxml</artifactId>
</dependency>
```

**漏洞类型归纳**：XXE 外部实体注入（CWE-611）、任意文件上传（CWE-434）
```

---

### 三、修复建议（h3）

**要求**：对该问题提出完整的解决方案，贴合代码实际情况书写。

**必须包含**：
1. 具体的修复方案（分点说明）
2. 可直接使用的修复代码

**示例**：
```markdown
### 修复建议

**1. 限制上传类型和文件大小**：

```java
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
    // ...
}
```

**2. 禁用 XML 外部实体解析**：

```java
SAXParserFactory factory = SAXParserFactory.newInstance();
factory.setFeature(XMLConstants.FEATURE_SECURE_PROCESSING, true);
factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
factory.setFeature("http://xml.org/sax/features/external-general-entities", false);
factory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
```
```

---

## 完整示例

### 示例1: XXE 漏洞（文件上传接口）

# EasyExcel XXE 外部实体注入漏洞

### 描述

在文件导入后，解析 Excel 时使用 EasyExcel 对数据进行解析，没有配置禁用 XML 外部实体的选项，
MultipartFile file 来自用户输入导致存在 XXE 风险。该文件导入接口没有文件类型校验和文件大小限制，
存在任意文件导入和 DoS 问题。

### 漏洞详情

**代码位置**：

```
E:\工作代码\项目名\src\main\java\com\example\controller\ExcelController.java:35
E:\工作代码\项目名\src\main\java\com\example\util\ExcelUtil.java:79
```

**问题代码展示**：

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

**漏洞分析**：

`ExcelController.importExcel()` 方法（ExcelController.java:35）接收 MultipartFile 参数，
直接调用 `ExcelUtil.importExcel()` 进行 Excel 解析，未配置任何安全防护措施。

**调用链追踪**：
```
ExcelController.importExcel() (ExcelController.java:35)
  → ExcelUtil.importExcel() (ExcelUtil.java:79)
    → EasyExcel.read().sheet().doRead() (ExcelUtil.java:82)
```

**缺少的安全控制**：

| 控制类型 | 状态 | 说明 |
|---------|------|------|
| 文件类型校验 | ❌ 缺失 | 未检查 Content-Type 和文件扩展名 |
| 文件内容校验 | ❌ 缺失 | 未检查文件魔数/文件头 |
| 文件大小限制 | ❌ 缺失 | 可上传超大文件触发 DoS |
| XXE 防护 | ❌ 缺失 | 未禁用 XML 外部实体 |

**攻击路径**：

1. 攻击者构造恶意 Excel 文件（.xlsx 本质是 ZIP 压缩的 XML 文件集合）
2. 在 XML 中定义外部实体指向敏感文件：
   ```xml
   <!DOCTYPE data [
       <!ENTITY secret SYSTEM "file:///etc/passwd">
   ]>
   <data>&secret;</data>
   ```
3. 通过文件上传接口提交恶意 Excel 文件
4. EasyExcel 解析时触发 XXE，读取服务器敏感文件
5. 文件内容可能通过错误消息或响应返回给攻击者

**对比分析**：
同类项目中的 `ImageController.uploadImage()` 方法有完整的安全校验：
- 检查 Content-Type 白名单
- 检查文件扩展名白名单
- 使用 UUID 重命名文件防止路径遍历
- 配置了安全的 XML 解析器禁用外部实体

而 `ExcelController.importExcel()` 完全没有这些校验，形成明显对比。

**未使用的安全机制**：
项目已引入 Apache POI 依赖，POI 提供了安全解析选项，但未启用：
```xml
<dependency>
    <groupId>org.apache.poi</groupId>
    <artifactId>poi-ooxml</artifactId>
    <version>5.2.3</version>
</dependency>
```

**漏洞类型归纳**：XXE 外部实体注入（CWE-611）、任意文件上传（CWE-434）

### 修复建议

**1. 添加文件类型和大小校验**：

```java
private static final Set<String> ALLOWED_TYPES = Set.of(
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
);
private static final long MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB

public Result importExcel(@RequestParam("file") MultipartFile file) {
    // 校验文件类型
    String contentType = file.getContentType();
    if (!ALLOWED_TYPES.contains(contentType)) {
        throw new RuntimeException("不支持的文件类型");
    }
    
    // 校验文件大小
    if (file.getSize() > MAX_FILE_SIZE) {
        throw new RuntimeException("文件大小超过限制（最大10MB）");
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
    InputStream is = file.getInputStream();
    BufferedInputStream ipt = new BufferedInputStream(is);
    
    // 配置安全的 XML 解析器
    SAXParserFactory factory = SAXParserFactory.newInstance();
    factory.setNamespaceAware(true);
    factory.setFeature(XMLConstants.FEATURE_SECURE_PROCESSING, true);
    factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
    factory.setFeature("http://xml.org/sax/features/external-general-entities", false);
    factory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
    factory.setXIncludeAware(false);
    
    XMLReader xmlReader = factory.newSAXParser().getXMLReader();
    
    ExcelReaderBuilder builder = EasyExcel.read(ipt, GeographicalInformationDto.class, listener);
    builder.xmlReader(xmlReader);
    builder.sheet().doRead();
    // ...
}
```

---

### 示例2: Velocity SSTI 远程代码执行

# Velocity 模板注入远程代码执行漏洞

### 描述

TemplateController.renderTemplate() 方法接收用户输入的 template 参数，直接传入 Velocity.evaluate() 
进行模板渲染，未配置 SecureUberspector 限制反射调用。攻击者可构造恶意 Velocity 模板代码，
通过反射调用 Runtime.exec() 执行任意系统命令，导致服务器被完全控制。

### 漏洞详情

**代码位置**：

```
E:\工作代码\项目名\src\main\java\com\example\controller\TemplateController.java:45-52
```

**问题代码展示**：

```java
// TemplateController.java
@PostMapping("/render")
public String renderTemplate(@RequestParam String template) {
    VelocityContext context = new VelocityContext();
    StringWriter writer = new StringWriter();
    // 危险：用户输入直接作为模板内容
    Velocity.evaluate(context, writer, "userTemplate", template);
    return writer.toString();
}
```

**漏洞分析**：

`TemplateController.renderTemplate()` 方法（TemplateController.java:45-52）接收用户输入的 
`template` 参数，未经任何过滤或白名单校验，直接作为模板内容传入 `Velocity.evaluate()` 
进行渲染。Velocity 模板引擎默认允许通过反射调用任意 Java 类和方法，形成严重的 SSTI 漏洞。

**调用链追踪**：
```
TemplateController.renderTemplate() (TemplateController.java:45)
  → Velocity.evaluate() (TemplateController.java:49)
    → Velocity 模板引擎解析执行
```

**缺少的安全控制**：

| 控制类型 | 状态 | 说明 |
|---------|------|------|
| 输入过滤 | ❌ 缺失 | 未对模板内容进行任何过滤 |
| 白名单校验 | ❌ 缺失 | 未限制可使用的模板语法 |
| SecureUberspector | ❌ 缺失 | 未配置限制反射调用 |
| 沙箱隔离 | ❌ 缺失 | 未启用模板沙箱 |

**攻击路径**：

1. 攻击者构造包含恶意 Velocity 语法的模板字符串：
   ```velocity
   #set($x='')
   #set($rt=$x.class.forName('java.lang.Runtime'))
   #set($ex=$rt.getRuntime().exec('whoami'))
   ```
2. 通过 HTTP 请求将恶意模板提交到 `/render` 接口
3. Velocity 引擎解析模板，通过反射链获取 Runtime 对象
4. 调用 `Runtime.exec('whoami')` 执行系统命令
5. 攻击者获得服务器完全控制权

**恶意输入示例**：
```velocity
#set($x='')
#set($rt=$x.class.forName('java.lang.Runtime'))
#set($chr=$x.class.forName('java.lang.Character'))
#set($str=$x.class.forName('java.lang.String'))
#set($ex=$rt.getRuntime().exec('id'))
$ex.waitFor()
#set($is=$ex.getInputStream())
#set($br=$x.class.forName('java.io.BufferedReader').newInstance($x.class.forName('java.io.InputStreamReader').newInstance($is)))
#set($line=$br.readLine())
$line
```

**对比分析**：
安全的模板渲染实现应：
- 使用预定义模板文件，而非用户输入
- 配置 SecureUberspector 限制反射调用
- 启用模板沙箱隔离
- 对输出进行 HTML 编码防止 XSS

当前实现完全违反了这些安全原则。

**未使用的安全机制**：
Velocity 提供了 `SecureUberspector` 用于限制反射调用，但未配置：
```java
// 安全配置示例（未启用）
VelocityEngine ve = new VelocityEngine();
ve.setProperty("runtime.introspector.uberspect", 
    "org.apache.velocity.util.introspection.SecureUberspector");
```

**漏洞类型归纳**：服务端模板注入（CWE-94）、远程代码执行（CWE-78）

### 修复建议

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

// 使用预定义模板文件
Template template = ve.getTemplate("templates/safe-template.vm");
VelocityContext context = new VelocityContext();
context.put("userContent", sanitizedInput);  // 用户内容作为参数注入

StringWriter writer = new StringWriter();
template.merge(context, writer);
return writer.toString();
```

**3. 纵深防御 - 输入白名单校验**：

```java
private static final Pattern SAFE_CONTENT = Pattern.compile("^[a-zA-Z0-9\\s\\.,!?]+$");

public String renderTemplate(@RequestParam String template) {
    // 白名单校验
    if (!SAFE_CONTENT.matcher(template).matches()) {
        throw new SecurityException("非法输入：仅允许字母、数字和基本标点");
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

### 行号验证方法

```powershell
# 使用 Select-String 验证行号
Select-String -Path $file -Pattern "getLoginUserByStr|TrustAllTrustManager" | 
  ForEach-Object { Write-Host "Line $($_.LineNumber): $($_.Line.Trim())" }
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
  某个 CVE 可能只影响特定框架/组件
  
  示例：
  - CVE-2020-1948 → Apache Dubbo（不是 Hessian）
  - CVE-2021-44228 → Log4j 2.0-beta9 to 2.15.0
```

---

## 漏洞分析验证检查清单

### ⚠️ 关键验证步骤（必须执行）

在写入报告前，必须验证以下内容：

#### 1. 类继承关系验证

当涉及"覆盖"、"绕过"等描述时，**必须验证继承关系**：

```powershell
# 验证方法：搜索类定义
Select-String -Pattern "class.*Controller.*extends|class.*Controller\s*\{"
```

**错误示例**：
```
❌ 错误结论：FeignServiceController 覆盖了 BaseController 的防护
✅ 事实：FeignServiceController 根本没有继承 BaseController
```

**教训案例**（2026-04-01）：
> 报告中写"批量分配防护被覆盖"，但 FeignServiceController 等并未继承 BaseController。
> 错误原因：只看 `@InitBinder` 方法，未验证类继承关系。
> 正确做法：先检查 `extends`，再判断是"覆盖"还是"缺失"。

#### 2. 配置生效条件验证

当涉及"配置失效"、"安全机制未启用"等描述时，**必须验证配置生效条件**：

| 描述 | 需验证 |
|------|--------|
| "配置被覆盖" | 是否真的继承了父类？ |
| "机制未启用" | 启用条件是什么？是否满足？ |
| "绕过验证" | 真的有验证逻辑吗？还是根本就没有？ |

#### 3. 因果关系验证

| 描述 | 验证问题 |
|------|----------|
| A 导致 B | A 真的是 B 的原因吗？有其他因素吗？ |
| 绕过了 X | X 真的存在吗？真的被绕过了吗？ |
| 覆盖了 Y | Y 真的被继承了吗？ |

### 验证命令速查

```powershell
# 1. 验证类继承关系
Select-String -Path $file -Pattern "class.*extends"

# 2. 验证方法是否存在
Select-String -Path $file -Pattern "methodName"

# 3. 验证调用关系
Select-String -Path $files -Pattern "ClassName\.|new ClassName"
```

### 报告中的正确表述

| 场景 | ❌ 错误表述 | ✅ 正确表述 |
|------|-----------|-----------|
| 未继承父类 | "覆盖了父类防护" | "未继承父类，缺少防护" |
| 配置未启用 | "禁用了安全配置" | "未配置安全选项" |
| 功能缺失 | "绕过了验证" | "无验证逻辑" |

---

## 报告生成检查清单

### 描述部分
- [ ] 字数控制在100字左右
- [ ] 清晰说明漏洞类型、成因、核心风险点

### 漏洞详情部分
- [ ] 代码位置准确（完整绝对路径 + 行号）
- [ ] 问题代码展示包含上下文
- [ ] 漏洞分析300字以上，包含：
  - [ ] 调用链追踪
  - [ ] 缺少的安全控制（表格形式）
  - [ ] 攻击路径
  - [ ] 对比分析
  - [ ] 漏洞类型归纳

### 修复建议部分
- [ ] 针对具体问题给出修复方案
- [ ] 提供可直接使用的修复代码

---

## 状态定义

| 状态 | 定义 | 要求 |
|------|------|------|
| **CONFIRMED** | 已验证可利用 | PoC 可执行，调用链完整，影响明确 |
| **HYPOTHESIS** | 疑似漏洞，需人工验证 | 发现可疑模式但无法完全确认 |

**关键原则**：宁可标记为 HYPOTHESIS 让人工验证，也不要把不确定的发现标记为 CONFIRMED 污染报告可信度。