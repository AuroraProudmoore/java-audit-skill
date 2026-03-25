---
name: java-audit-skill
description: |
  AI驱动的Java代码安全审计技能，实现系统化、高覆盖率的漏洞挖掘。使用场景：
  (1) 审计Java/Kotlin项目寻找安全漏洞（0day挖掘、代码审计、安全评估）
  (2) 企业级代码库的安全审计（支持大型项目）
  (3) 需要高质量、低幻觉率的安全审计报告
  (4) CI/CD集成的前期漏洞发现
  触发关键词：Java审计、代码审计、安全审计、漏洞挖掘、0day、安全评估、Java security audit、code review for security
---

# AI+Java 代码审计 Skill

本 Skill 将资深审计员的工作方法和质量标准编码成 LLM 可执行的协议，解决裸跑 LLM 覆盖率低、幻觉高、优先级混乱等核心痛点。

## 核心理念

**LLM 有能力，缺纪律。** Skill 不教 LLM "什么是 SQL 注入"，而是给它装上资深审计员的工作骨架——定义工作流、分配资源、设置护栏、标准化输出。

## 6 阶段审计流水线

```
Phase 0 → Phase 1 → Phase 2 → Phase 2.5 → Phase 3 → Phase 4 → Phase 5
 代码度量   项目侦察   多层审计   覆盖率门禁  漏洞验证  规则沉淀  标准化报告
```

每个 Phase 有明确的输入、输出和质量标准，中间结果全量持久化到文件。

---

## Phase 0: 代码库度量

**目标**: 统计项目规模，计算审计工作量，为 Agent 分配提供依据。

### 执行脚本

```bash
# 统计代码行数和文件数（注意括号）
find . \( -name "*.java" -o -name "*.kt" -o -name "*.xml" \) | xargs wc -l | tail -1

# 统计各类型文件
find . -name "*.java" | wc -l
find . -name "*.kt" | wc -l
find . -name "*.xml" | wc -l

# 统计 Controller 数量
grep -r "@Controller\|@RestController\|@WebServlet" --include="*.java" | wc -l

# 统计模块数（Maven 多模块项目）
find . -name "pom.xml" | wc -l

# 统计模块数（Gradle 多模块项目）
find . -name "build.gradle" -o -name "build.gradle.kts" | wc -l
```

### 输出文件: `audit-metrics.json`

```json
{
  "total_loc": 131000,
  "java_files": 847,
  "kt_files": 0,
  "xml_files": 156,
  "controllers": 40,
  "modules": 5,
  "ealoc": 98750,
  "agents_needed": 7,
  "build_system": "maven"
}
```

**其他输出文件**：
- `tier-classification.md` - Tier 分类报告
- `scenario-tags.json` - API 场景标签（使用 `--scenario` 参数生成）
- `p0-critical.md`, `p1-high.md`, `p2-medium.md` - Layer 1 扫描报告（使用 `--scan` 参数生成）
- `coverage-report.md` - 覆盖率验证报告（使用 `--coverage` 参数生成）

---

## Phase 1: 项目侦察 & EALOC 资源分配

### 1.1 业务场景标签

**核心理念**：不是所有 API 都需要深度审计。通过业务场景标签快速识别高风险 API，精准分配审计资源。

#### 场景类型分类

| 场景类型 | 典型 API | 默认风险等级 | 重点检查 |
|----------|----------|-------------|----------|
| **FINANCIAL_TRANSACTION** | 支付、退款、转账 | CRITICAL | 金额篡改、并发竞争、状态机绕过 |
| **PRIVILEGED_OPERATION** | 用户管理、系统配置 | HIGH | 垂直越权、权限绕过 |
| **RESOURCE_ALLOCATION** | 下单、抢购、预约 | HIGH | 并发竞争、库存绕过 |
| **STATE_TRANSITION** | 审批、发货、退款 | HIGH | 状态机绕过、流程跳跃 |
| **DATA_ACCESS** | 订单详情、用户列表 | MEDIUM | 水平越权、信息泄露 |
| **USER_OPERATION** | 个人资料、修改密码 | MEDIUM | 认证绕过、密码安全 |
| **PUBLIC_ACCESS** | 首页、公告、公开文章 | LOW | XSS、SSRF（可快速模式） |

#### 自动识别脚本

```bash
# 识别资金交易接口
grep -rn "pay\|payment\|refund\|transfer\|withdraw" --include="*.java" | grep -i "mapping"

# 识别特权操作接口
grep -rn "@PreAuthorize.*ADMIN\|@Secured.*ADMIN\|hasRole.*ADMIN" --include="*.java"

# 识别公开访问接口
grep -rn "permitAll\|anonymous" --include="*.java"
```

**详细说明**: [references/business-scenario-tags.md](references/business-scenario-tags.md)

### 1.2 Tier 分类规则

| 规则 | 条件 | Tier | 分析深度 |
|------|------|------|----------|
| Rule 0 | 第三方库源码 | SKIP | 不审计 |
| Rule 1 | Layer 1 预扫描有 P0/P1 候选项 | T1 | 动态提升 |
| Rule 2 | 含 @Controller/@RestController/@WebServlet/Filter | T1 | 完整深度分析 |
| Rule 3 | 含 @Service/@Repository/@Mapper | T2 | 聚焦关键维度 |
| Rule 4 | 类名含 Util/Helper/Handler | T2 | 聚焦关键维度 |
| Rule 5 | .properties/.yml/security.xml | T2 | 聚焦关键维度 |
| Rule 6 | 含 @Entity/@Table/@Data | T3 | 快速模式匹配 |
| Rule 7 | 未匹配任何规则 | T2 | 保守兜底 |

### 1.3 EALOC 公式（场景标签修正）

```
基础 EALOC = T1_LOC × 1.0 + T2_LOC × 0.5 + T3_LOC × 0.1

场景修正系数：
- FINANCIAL_TRANSACTION: × 1.5
- PRIVILEGED_OPERATION / RESOURCE_ALLOCATION / STATE_TRANSITION: × 1.2
- DATA_ACCESS / USER_OPERATION: × 1.0
- PUBLIC_ACCESS: × 0.5

修正后 EALOC = Σ (API_EALOC × Scenario_Multiplier)
```

**Agent 分配**: `Agent数量 = ceil(Adjusted_EALOC / 15000)`

### 1.4 输出文件

- `tier-classification.md`: Tier 分类结果
- `scenario-tags.json`: API 场景标签

#### tier-classification.md 示例

```markdown
# Tier 分类结果

## 模块: module-biz (131,000 LOC)

| 子任务 | Agent | 文件范围 | 文件数 | Tier分布 | EALOC |
|--------|-------|---------|-------|---------|-------|
| 1a | Agent 1 | controller/ | 147 | T1: 14K | 14,000 |
| 1b | Agent 2 | service/ + dao/ | 200 | T2: 30K | 15,000 |
| 1c | Agent 3 | entity/ + vo/ | 500 | T3: 87K | 8,700 |

**总 EALOC**: 37,700 → 需要 3 个 Agent
```

---

## Phase 2: 多层审计架构

### Layer 1: 全量预扫描（不用 LLM）

使用 ripgrep + Semgrep 扫描所有文件，按 P0-P3 标记危险模式。

#### P0 级危险模式（RCE/反序列化）

```bash
# 反序列化全家族
grep -rn "ObjectInputStream\|XMLDecoder\|XStream" --include="*.java"
grep -rn "JSON\.parseObject\|JSON\.parse\|@type" --include="*.java"  # Fastjson
grep -rn "enableDefaultTyping\|activateDefaultTyping" --include="*.java"  # Jackson
grep -rn "HessianInput\|Hessian2Input" --include="*.java"  # Hessian

# SSTI 全引擎
grep -rn "Velocity\.evaluate\|VelocityEngine\|mergeTemplate" --include="*.java"
grep -rn "freemarker\.template\|Template\.process\|FreeMarkerConfigurer" --include="*.java"
grep -rn "SpringTemplateEngine\|TemplateEngine\.process" --include="*.java"  # Thymeleaf

# 表达式注入
grep -rn "SpelExpressionParser\|parseExpression\|evaluateExpression" --include="*.java"
grep -rn "OgnlUtil\|Ognl\.getValue\|ActionContext" --include="*.java"

# JNDI 注入
grep -rn "InitialContext\.lookup\|JdbcRowSetImpl\|setDataSourceName" --include="*.java"

# 命令执行
grep -rn "Runtime\.getRuntime\|ProcessBuilder\|exec(" --include="*.java"
```

#### P1 级危险模式（SQL 注入/SSRF/文件操作）

```bash
# SQL 注入风险
grep -rn "Statement\|createStatement\|executeQuery\|executeUpdate" --include="*.java"
grep -rn '\$\{' --include="*.xml"  # MyBatis ${} 注入

# SSRF
grep -rn "URL\(|HttpURLConnection\|HttpClient\|RestTemplate\|WebClient" --include="*.java"

# 文件操作
grep -rn "FileInputStream\|FileOutputStream\|FileWriter\|Files\.read\|Files\.write" --include="*.java"
grep -rn "getOriginalFilename\|transferTo\|MultipartFile" --include="*.java"  # 文件上传
```

#### P2 级危险模式（认证/授权/加密）

```bash
# 认证相关
grep -rn "@PreAuthorize\|@Secured\|@RolesAllowed\|hasRole\|hasAuthority" --include="*.java"
grep -rn "permitAll\|anonymous\|authenticated" --include="*.java"

# 加密相关
grep -rn "MessageDigest\|Cipher\|SecretKey\|PasswordEncoder" --include="*.java"
```

### Layer 2: 双轨审计模型

每个 Agent 执行两条并行的审计轨道：

#### 轨道 1: Sink-driven（从危险代码往上追）

发现 `Runtime.exec(cmd)` → 追踪 `cmd` 参数来源 → 检查是否有过滤 → 判断是否来自用户输入

#### 轨道 2: Control-driven（从端点往下查安全控制）

发现 `/api/admin/deleteUser` 端点 → 检查是否有认证注解 → 检查是否有权限校验

**为什么需要两条轨道？** 认证绕过这类漏洞，单独用 Sink-driven 找不到——该漏洞不是某行代码有问题，而是某个端点缺少了应有的权限检查。

### Layer 2-Deep: 代码分析深度检查

对于 Semgrep 规则无法覆盖的漏洞类型，需要通过代码分析进行判断。

#### 逻辑漏洞 CoT 四步推理

**核心理念**：逻辑漏洞的本质是"合法的代码执行了非预期的业务流程"，需要强制 AI 像安全专家一样进行攻防推演。

```
Step 1: 场景与入口识别 → 识别 API 功能场景，分析用户可控参数
Step 2: 防御机制审计 → 寻找代码中的"锁"和"盾"，分析完备性
Step 3: 对抗性沙箱模拟 → AI 设计 PoC，模拟真实链路处理
Step 4: 漏洞结果判定 → 基于推演给出负责任结论
```

**Step 1: 场景与入口识别**

```markdown
识别内容：
1. API 功能场景（资金交易/数据访问/状态变更等）
2. 用户可控参数列表
3. 参数风险标签：
   - ID 类（userId, orderId）→ 数据定位，可能越权
   - 金额类（amount, price）→ 资金相关，可能篡改
   - 状态类（status, state）→ 状态控制，可能绕过状态机
   - 数量类（count, quantity）→ 资源相关，可能并发问题
```

**Step 2: 防御机制审计**

寻找代码中的"锁"和"盾"：

| 锁类型 | 代码特征 | 检查点 |
|--------|----------|--------|
| 权限锁 | `@PreAuthorize`, `hasRole()` | 是否存在？是否完整？ |
| 归属锁 | `userId.equals(currentUser.getId())` | 数据是否校验归属？ |
| 状态锁 | `if (order.getStatus() == PAID)` | 状态前置条件是否完整？ |
| 金额锁 | `amount.equals(order.getAmount())` | 金额是否后端校验？ |
| 并发锁 | `synchronized`, `SELECT FOR UPDATE` | 是否有并发控制？ |

**Step 3: 对抗性沙箱模拟**

基于业务语义生成对抗性测试用例：

| 参数类型 | 测试值 | 目标漏洞 |
|----------|--------|----------|
| 金额 | 负数、0、极大值 | 0元支付、负金额退款 |
| 数量 | 负数、超库存上限 | 库存为负、超量下单 |
| 状态 | 跳跃状态值 | 状态机绕过 |
| ID | 他人 ID | 水平越权 |

**Step 4: 漏洞结果判定**

- **CONFIRMED**: PoC 可执行，调用链完整，影响明确
- **HYPOTHESIS**: 发现可疑模式但无法完全确认，需人工验证

**详细推理模板**: [references/logic-vulnerability-cot.md](references/logic-vulnerability-cot.md)

#### 业务逻辑漏洞检查要点

```
支付金额检查：
1. 金额是否来自前端？是否有后端校验？
2. 价格是否可被篡改？
3. 是否有金额一致性校验？

库存并发检查：
1. 是否有并发控制（锁/原子操作）？
2. 检查和扣减是否原子操作？

状态机检查：
1. 状态流转规则是否明确？
2. 敏感操作是否校验前置状态？
3. 是否有非法状态跳转？
```

#### 越权漏洞检查要点

```
水平越权检查：
1. 数据查询是否校验归属？
2. userId 是否从 Session 获取（不可伪造）？
3. UPDATE/DELETE 是否有 userId 条件？

垂直越权检查：
1. 管理接口是否有权限注解？
2. 前后端权限是否一致？
3. 是否有权限配置遗漏？
```

#### 依赖安全检查

```
检查要点：
1. 读取 pom.xml/build.gradle
2. 提取 Log4j、Fastjson、Shiro、Spring 等关键依赖版本
3. 使用 web_search 搜索漏洞信息
   - 搜索格式: "<组件名> <版本号> CVE vulnerability"
   - 示例: "log4j 2.14.1 CVE", "fastjson 1.2.79 vulnerability"
4. 分析搜索结果中的 NVD、官方公告
5. 标记需要升级的依赖
```

**联网搜索示例**：

```
发现依赖:
  <dependency>
    <groupId>org.apache.logging.log4j</groupId>
    <artifactId>log4j-core</artifactId>
    <version>2.14.1</version>
  </dependency>

使用 web_search:
  query: "log4j-core 2.14.1 CVE vulnerability"

分析结果:
  - CVE-2021-44228 (Log4Shell)
  - CVSS: 10.0 Critical
  - 影响版本: 2.0-beta9 to 2.15.0
  - 修复版本: 2.17.1+

结论: 需要升级到 2.17.1+
```

#### 运行时配置

```
检查要点：
1. Session 超时、Cookie Secure/HttpOnly
2. Actuator 端点暴露
3. 数据库密码明文存储
4. 调试模式开启
```

**详细判断方法见**: [references/vulnerability-conditions.md](references/vulnerability-conditions.md) 第 16-19 节

### Layer 3: 调用链语义级验证

优先使用 LSP 做语义级追踪：

```
候选 Sink (Statement.executeUpdate(sql))
↓ goToDefinition → 确认实际实现
↓ findReferences → 向上追踪所有调用者
↓ hover → 获取中间变量类型
↓ 重复 findReferences → 直到到达 Controller 入口或确认不可达
↓ 记录完整调用链，每一跳标注 文件:行号
```

LSP 不可用时退化到 Grep + Read 手动追踪。

---

## Phase 2.5: 覆盖率门禁

**这是反 LLM 天性的核心设计**——LLM 倾向于跳过"看起来不重要"的代码，而漏洞恰恰喜欢藏在那些地方。

### 模块覆盖矩阵

```markdown
| # | 模块路径 | LOC | EALOC | Controller数 | 风险评估 | 分配 Agent | Phase2 状态 | Phase3 状态 |
|---|---------|-----|-------|-------------|---------|-----------|------------|------------|
| 1 | module-auth | 8,000 | 5,200 | 6 | HIGH | Agent 1 | 完成 | 完成 |
| 2 | module-gateway | 12,000 | 7,800 | 8 | HIGH | Agent 2 | 完成 | 进行中 |
| 3 | module-biz | 131,000 | 37,700 | 40 | HIGH | Agent 3a~3c | 部分完成 | 未开始 |
```

### 文件级覆盖率验证

每个 Agent 输出必须包含审阅文件清单：

```markdown
| # | 文件路径 | Tier | 状态 | 发现数 |
|---|---------|------|------|-------|
| 1 | AuthController.java | T1 | 完成 已审阅 | 2 |
| 2 | ShiroConfig.java | T1 | 完成 已审阅 | 1 |
| 3 | UserServiceImpl.java | T2 | 完成 已审阅 | 0 |
| 4 | User.java | T3 | 完成 已审阅 | 0 |
| 5 | com/alibaba/fastjson/JSON.java | SKIP | 跳过 第三方库 | - |
```

**门禁检查**: 拿这份清单和 `find` 命令的实际文件列表做 diff。清单里没出现的文件 = 漏审。

### 门禁判断逻辑

```
收到每个 Agent 结果后立即执行：
1. 读取 Agent 输出的「审阅文件清单」
2. 与实际文件列表交叉验证
3. 覆盖率 = 100% → 该 Agent 通过
   覆盖率 < 100% → 立即为未覆盖文件启动补扫 Agent

所有 Agent 完成后：
- 全部模块 Phase2 = 完成 → 进入 Phase 3
- 存在 未开始 或 部分完成 → 启动补充 Agent → 循环直到 100%
```

**禁止在覆盖率 < 100% 时进入 Phase 3。没有例外。**

---

## Phase 3: 漏洞验证 & DKTSS 评分

### 反幻觉 5 条铁律

1. **报告漏洞前必须用 Read 验证文件存在**
2. **代码片段必须来自实际 Read 输出，不得编造**
3. **调用链每一跳必须标注 文件:行号**
4. **不确定的发现标记为 HYPOTHESIS，不得标记为 CONFIRMED**
5. **宁可漏报，不可误报**

### 分析深度铁律

**漏洞分析必须达到 L3 级别，禁止写成三点式（成因+攻击+影响）**：

必须包含以下所有要素：
- ✅ **具体方法名**：精确到 `ClassName.methodName()`
- ✅ **具体行为**：方法具体做了什么
- ✅ **缺少的安全控制**：什么保护措施没有
- ✅ **攻击路径**：攻击者可以如何利用
- ✅ **调用链追踪**：从入口到漏洞点的完整路径
- ✅ **漏洞类型归纳**：标准漏洞分类（CWE）
- ✅ **未使用的安全机制**：项目中存在但未启用的安全配置

**样例**（必须参照此格式）：
```
`HeaderModelUtils.getLoginUserByStr()` 方法仅对 Header 中的 Base64 编码数据进行解码，
然后直接反序列化为 LoginUserBo 对象。系统没有对用户信息进行任何签名验证或加密保护，
攻击者可以轻松伪造任意用户的登录信息。

控制器层（如 `FlightController.setFlightCityHistory()`）直接从请求头 `la517_loginUser`
获取用户信息，该信息未经服务器端验证就传递给服务层使用，形成**客户端信任漏洞**。

经审查 `pom.xml` 发现项目已引入 JWT 相关依赖（`jjwt`），但全局搜索显示实际并未使用。
`LogInterceptor` 拦截器仅用于日志追踪（requestId 生成），不包含任何认证逻辑。
```

### 漏洞成立条件判断

**详见 [references/vulnerability-conditions.md](references/vulnerability-conditions.md)**

示例 - Fastjson 反序列化判断流程：
```
发现 JSON.parseObject() / JSON.parse() 调用
↓
检查版本：
  < 1.2.68 → 直接可利用
  1.2.68-1.2.80 → 检查 classpath 是否有特定依赖（groovy/jython/aspectj/commons-io）
  ≥ 1.2.83 → 检查 safeMode 配置
```

### DKTSS 评分体系

**详见 [references/dktss-scoring.md](references/dktss-scoring.md)**

核心公式：`Score = Base - Friction + Weapon + Ver`

- **Base**: 按漏洞类型和实际影响评分
- **Friction**: 实战阻力（访问路径/权限门槛/交互复杂度）
- **Weapon**: 武器化程度
- **Ver**: 版本因子

### 状态定义

| 状态 | 定义 | 要求 |
|------|------|------|
| **CONFIRMED** | 已验证可利用 | PoC 可执行，调用链完整，影响明确 |
| **HYPOTHESIS** | 疑似漏洞，需人工验证 | 发现可疑模式但无法完全确认 |

**关键原则**: 宁可标记为 HYPOTHESIS 让人工验证，也不要把不确定的发现标记为 CONFIRMED 污染报告可信度。

---

## Phase 4: Semgrep 规则沉淀（可选）

**目标**：将确认的漏洞模式转换为 Semgrep 静态分析规则，可集成到 CI/CD 流水线。

### 执行条件

Phase 4 为**可选步骤**，在以下情况下执行：

- 发现了新的漏洞模式，现有 Semgrep 规则未覆盖
- 需要将漏洞检测集成到 CI/CD 流水线
- 项目需要长期的自动化安全检测

### 输出文件

| 文件 | 说明 |
|------|------|
| `custom-rules.yaml` | 自定义 Semgrep 规则文件 |
| `semgrep-results.json` | 规则测试结果 |

### 规则编写规范

```yaml
rules:
  - id: custom-vulnerability-id
    patterns:
      - pattern: 危险模式
      - pattern-not: 安全模式（排除误报）
    message: 规则描述，说明漏洞风险和修复建议
    severity: ERROR  # ERROR / WARNING / INFO
    languages: [java]
    metadata:
      category: security
      cwe: "CWE-XXX"
      references:
        - https://example.com/reference
```

### 示例规则

```yaml
rules:
  - id: velocity-ssti
    patterns:
      - pattern: Velocity.evaluate($CONTEXT, $WRITER, $NAME, $USER_INPUT)
      - pattern-not: Velocity.evaluate($CONTEXT, $WRITER, $NAME, "...")
    message: 检测到用户可控的 Velocity 模板输入，存在 SSTI 风险
    severity: ERROR
    languages: [java]
    metadata:
      category: security
      cwe: "CWE-94"
```

### 规则测试

```bash
# 测试单个规则
semgrep --config custom-rules.yaml /path/to/test/code

# 验证规则语法
semgrep --validate --config custom-rules.yaml
```

### 跳过条件

以下情况可跳过 Phase 4：

- 所有发现的漏洞都已被现有 Semgrep 规则覆盖
- 不需要 CI/CD 集成
- 时间紧迫，优先完成报告

---

## Phase 5: 标准化报告生成

**详见 [references/report-template.md](references/report-template.md)**

### 9 个必填字段组

1. **基本信息**: 状态、漏洞类型、CWE-ID、严重程度、DKTSS 评分、受影响组件、文件位置
2. **触发条件**: 漏洞触发的先决条件
3. **所需权限**: 利用漏洞需要的权限（无需认证/低权限/高权限）
4. **漏洞原理**: 详细的技术分析
5. **代码证据**: 实际代码片段（必须来自 Read 输出）
6. **调用链**: Source → Sink 的完整路径，每跳标注文件:行号
7. **PoC**: 可执行的验证代码
8. **验证结果**: PoC 执行结果
9. **修复建议**: 立即修复/架构优化/纵深防御

### 报告质量规范

**详见 [references/report-template.md](references/report-template.md)**

#### 行号定位规范

- **必须使用实际验证的行号**，禁止模糊范围
- 精确到方法起始行，多段代码分开标注
- 示例：`HttpUtil.java:252-253, 321` 而非 `HttpUtil.java:177-193`

#### 分析描述颗粒度规范

每个漏洞的"分析"部分必须包含：

| 要素 | 说明 |
|------|------|
| 具体方法名 | 精确到 `ClassName.methodName()` |
| 调用链追踪 | Controller → Service → DAO |
| 对比分析 | 与安全代码的差异 |
| 发现未使用的安全机制 | 如 JWT 依赖引入但未使用 |
| 归纳漏洞类型 | CWE 标准分类 |

**分析深度要求 L3 级别**：包含调用链、对比分析、未使用安全机制。

### 报告输出文件

- `findings-raw.md`: Phase 2 发现的候选漏洞
- `findings-verified.md`: Phase 3 验证后的确认漏洞（最终数据源）
- `audit-report.md`: Phase 5 格式化的最终报告

---

## AI 代码审计 6 大核心方法

### 1. 语义化规则匹配

传统工具的规则是"死"的——只能匹配固定参数名。AI 通过语义识别核心业务含义，适配任意命名规范。

**示例**：越权漏洞检测
- 传统规则：检查是否存在 `user_id` 参数
- AI 语义规则：识别接口中所有代表用户身份标识的参数，校验该参数用于定位业务数据归属时，是否与当前登录用户的身份存在强制绑定

**适用场景**：未授权访问、通用越权、验证码绕过、密码重置漏洞

### 2. 基于因果推理的业务流程异常审计

AI 先构建业务的因果关系基准与状态机模型，明确每个业务操作的强制前置条件（因）与合法后置状态（果），再通过反事实推理验证。

**示例**：电商支付场景
- 强制前置条件：订单已创建且未支付、支付金额一致、回调凭证合法
- 合法后置状态：订单变为待发货、库存扣减、生成发货单
- 测试用例：跳过支付直接调用发货确认接口

**适用场景**：流程绕过、步骤颠倒、非法状态跳转

### 3. 权限与访问控制的逻辑一致性审计

构建完整的权限-资源绑定模型，执行三类校验：

| 校验类型 | 方法 | 覆盖漏洞 |
|----------|------|----------|
| 水平越权校验 | 用同角色不同用户凭证测试 | 访问他人私有数据 |
| 垂直越权校验 | 用低权限凭证测试高权限接口 | 权限提升 |
| 一致性校验 | 对比同类接口权限校验逻辑 | 部分遗漏校验 |

**适用场景**：水平/垂直越权、未授权访问、前后端权限不一致

### 4. 边界条件与异常分支的对抗性生成审计

基于参数的业务语义生成对抗性测试用例，而非随机字符串：

| 参数类型 | 测试值 | 目标漏洞 |
|----------|--------|----------|
| 金额 | 负数、0、极大值、超2位小数 | 0元支付、负金额退款 |
| 数量 | 负数、超库存上限 | 库存为负、超量下单 |
| 时间 | 超期时间、早于当前时间 | 绕过有效期限制 |

**白盒扫描重点**：异常捕获分支是否存在"跳过权限校验"、"异常时返回成功"、"泄露敏感信息"

### 5. 多维度关联的漏洞链推理

将单个缺陷按业务场景、接口依赖、数据流转关系关联，自动识别可串联的漏洞点。

**示例漏洞链**：
1. `/api/user/list` 未授权访问 → 获取全量用户手机号和 user_id
2. `/api/user/password/reset` 仅校验手机号和 user_id，无验证码

→ 串联形成完整攻击链，实现任意用户密码重置

### 6. 白盒场景的代码语义级逻辑缺陷审计

重点扫描高频逻辑缺陷场景：

- 权限校验缺失（仅校验登录，未校验数据归属）
- 业务逻辑错误（金额计算顺序、库存扣减顺序）
- 异常处理缺陷（捕获异常后直接返回成功）
- 接口设计缺陷（无幂等性、敏感操作无二次校验）

---

## 长上下文问题 5 层解决方案

### 层级 1: 源头治理（性价比最高，降低 60%+ 上下文）

**必过滤内容**：
- 注释、空行、纯日志打印代码
- 单元测试文件
- 第三方依赖库
- 构建配置文件
- 自动生成代码（protobuf、MyBatis Mapper）

**可过滤低风险内容**：
- 仅含 get/set 的纯数据实体类
- 无安全风险的工具方法
- 非核心统计报表代码

**注意**：过滤必须基于语义识别，不能误删权限校验、加密解密、输入过滤等核心安全代码。

### 层级 2: 三层递进式审计架构（核心方案）

| 层级 | 内容 | Token 控制 |
|------|------|------------|
| 第一层：全局架构层 | 项目架构说明、模块划分、全局权限模型、核心拦截器规则、对外接口清单 | ≤ 8K |
| 第二层：模块级审计 | 按业务域拆分独立审计单元，输入模块代码+全局安全基线+依赖接口元数据 | 32K-64K |
| 第三层：跨模块验证 | 仅输入关联模块核心代码片段+调用链路元数据 | ≤ 64K |

### 层级 3: 结构化语义压缩（降低 70%+ Token）

将代码转化为结构化元数据：

```
函数名：updateOrder
输入参数：orderId（用户可控字符串）、orderStatus（整型枚举）
核心业务逻辑：根据 orderId 修改订单状态
安全特征：无订单归属用户校验，无操作权限校验
下游依赖：orderDao.update
风险标签：越权风险高
```

### 层级 4: RAG + 多轮对话（突破窗口物理限制）

1. **构建代码知识库**：按函数/类拆分，生成向量嵌入存入向量库
2. **精准检索相关上下文**：通过自然语言或风险特征检索相关代码片段
3. **多轮对话增量审计**：每轮处理一个细分目标，上一轮输出作为下一轮轻量上下文

### 层级 5: 增量审计机制（工程化落地）

与 Git/CI/CD 集成，仅审计本次提交变更的代码及相关调用链路，减少 90%+ 上下文量。

---

## 5 大落地误区

### ❌ 误区 1：简单按行数拆分代码

**问题**：破坏代码语义关联，导致跨文件调用链路无法理解，严重漏报

**正确做法**：按业务边界、依赖关系拆分，采用三层递进式架构

### ❌ 误区 2：过度依赖长窗口模型

**问题**：超过 128K token 后注意力严重衰减，且成本极高

**正确做法**：中等窗口 + 裁剪分块 + RAG，长窗口仅作跨模块验证辅助

### ❌ 误区 3：全量代码丢给 AI

**问题**：上下文溢出、无关信息干扰、误报率飙升、速度极慢

**正确做法**：完成无效信息过滤与风险分级，遵循"非必要不输入"

### ❌ 误区 4：完全抛弃传统工具

**问题**：大模型存在幻觉问题，无法被规则匹配弥补

**正确做法**：传统工具前置过滤 + AI 深度推理 + 传统工具后置验证

### ❌ 误区 5：只关注已知漏洞

**问题**：浪费 AI 核心能力——检测业务逻辑漏洞

**正确做法**：聚焦传统工具无法覆盖的逻辑缺陷、越权漏洞、流程绕过

---

## 参考文档

| 文档 | 内容 |
|------|------|
| [vulnerability-conditions.md](references/vulnerability-conditions.md) | 漏洞成立条件判断表（Fastjson、JNDI、SSTI 等） |
| [dktss-scoring.md](references/dktss-scoring.md) | DKTSS 评分体系详细说明 |
| [report-template.md](references/report-template.md) | 标准化漏洞报告模板 |
| [logic-vulnerability-cot.md](references/logic-vulnerability-cot.md) | 逻辑漏洞 CoT 四步推理流程 |
| [business-scenario-tags.md](references/business-scenario-tags.md) | 业务场景标签系统 |
| [security-checklist.md](references/security-checklist.md) | Java Web 应用安全审计检查清单 |

---

## 执行检查清单

### 审计开始前

- [ ] 确认项目路径和技术栈（Java/Kotlin 版本、框架）
- [ ] 运行 Phase 0 度量脚本
- [ ] 完成项目侦察，生成 Tier 分类和 EALOC 计算
- [ ] **生成业务场景标签（scenario-tags.json）**

### 审计过程中

- [ ] Layer 1 预扫描完成，P0-P3 标记到位
- [ ] 每个 Agent 双轨审计（Sink-driven + Control-driven）
- [ ] **逻辑漏洞执行 CoT 四步推理**
- [ ] 实时更新覆盖矩阵
- [ ] 文件级覆盖率验证（清单 vs 实际文件 diff）

### 审计完成后

- [ ] 覆盖率门禁 100% 通过
- [ ] 每个漏洞遵循反幻觉 5 条铁律
- [ ] **逻辑漏洞有完整 CoT 推理记录**
- [ ] DKTSS 评分完整
- [ ] 报告 9 个必填字段齐全
- [ ] CONFIRMED vs HYPOTHESIS 状态正确

---

## 注意事项

1. **不要信任 LLM 的"记忆"**：所有中间结果都持久化到文件
2. **"没有发现也是有效结果"**：每个文件必须有"已审阅，无发现"或发现记录
3. **javax.* 和 jakarta.* 双命名空间**：Java EE → Jakarta EE 迁移历史，扫描规则必须同时匹配两个命名空间
4. **大模块拆分追踪**：EALOC > 15000 的模块必须拆分成多个子任务

---

## 大型项目增强：CPG 工具支持

对于 EALOC > 50000 的大型项目，推荐使用代码属性图（CPG）工具增强分析能力。

### 推荐工具：Joern

**优势**：
- 支持反编译伪代码分析（可用于 jar 包审计）
- 提供完整的代码属性图（AST + CFG + PDG）
- 支持复杂的跨文件调用链追踪
- 内置查询语言（Joern Query）进行自定义规则

**集成方式**：

```bash
# 安装 Joern
./joern --script audit.sc

# audit.sc 示例
importCode("path/to/project")
cpg.method.name("exec").callIn.l.foreach { call =>
  println(s"Potential RCE: ${call.location}")
}
```

**适用场景**：
- 超大型项目（>50 万行）
- 需要跨模块调用链分析
- 反编译代码审计

### 与现有架构整合

```
Layer 0: Joern CPG 构建（大型项目可选）
    ↓
Layer 1: ripgrep + Semgrep 预扫描
    ↓
Layer 2: LLM 双轨审计
    ↓
Layer 2-Deep: CoT 四步推理（逻辑漏洞）
    ↓
Layer 3: LSP/Joern 语义级验证
```

