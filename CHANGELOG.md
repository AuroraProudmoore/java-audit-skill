# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.5.0] - 2026-03-30

### 审查发现的问题 / Issues Found in Review

| # | 问题 | 严重性 | 状态 |
|---|------|--------|------|
| 1 | Kotlin 支持不完整 - 扫描命令只检查 `*.java`，遗漏 `*.kt` 文件 | 🔴 高 | ✅ 已修复 |
| 2 | 覆盖率检查逻辑缺陷 - 正则误匹配导致覆盖率虚高 | 🔴 高 | ✅ 已修复 |
| 3 | LLM/AI 安全规则缺失 - 新技术栈无防护 | 🔴 高 | ✅ 已修复 |
| 4 | GraphQL 安全规则缺失 - API 安全盲区 | 🔴 高 | ✅ 已修复 |
| 5 | Jakarta EE 覆盖不完整 - Spring Boot 3.x 漏检 | 🟠 中 | ✅ 已修复 |
| 6 | Spring Security 6 规则缺失 - 新框架漏检 | 🟠 中 | ✅ 已修复 |
| 7 | Kotlin 特有漏洞模式未覆盖 | 🟠 中 | ✅ 已修复 |
| 8 | Fastjson 2.x 版本判断缺失 | 🟠 中 | ✅ 已修复 |
| 9 | DKTSS 评分上限处理不一致 | 🟠 中 | ✅ 已修复 |
| 10 | 覆盖率门禁阈值设计问题 - 未分层要求 | 🟠 中 | ✅ 已修复 |
| 11 | JWT 弱密钥检测不完整 | 🟠 中 | ✅ 已修复 |
| 12 | CORS 安全检查不足 | 🟠 中 | ✅ 已修复 |
| 13 | Java 21 新特性安全规则缺失 | 🟠 中 | ✅ 已修复 |
| 14 | 幂等性检查缺失 | 🟡 低 | ✅ 已修复 |
| 15 | 并发安全检查不完整 | 🟡 低 | ✅ 已修复 |

### Added / 新增

- **rules/semgrep/java-emerging.yaml**: 新增 45 条新兴技术安全规则
  - LLM/AI 安全（4条）：API Key 硬编码、Prompt 注入、Agent 无限制、输出未验证
  - GraphQL 安全（4条）：Introspection、深度限制、批量限制、字段建议
  - Kotlin 特有漏洞（5条）：!! 空安全绕过、GlobalScope、runBlocking、非安全随机数、强制转换
  - Java 21 新特性（3条）：Virtual Thread pinned、FFI 内存操作、switch 覆盖
  - Jakarta EE / Spring Boot 3.x（4条）：Servlet Filter、JPA SQL注入、Validation、Native Image
  - 并发安全（3条）：无界线程池、竞态条件、ThreadLocal 泄露
  - 幂等性检查（2条）：支付接口、下单接口
  - Fastjson 2.x（2条）：AutoType 配置、版本检查
  - JWT 安全增强（3条）：弱密钥增强检测、无过期时间、alg=none
  - CORS 安全增强（2条）：* + Credentials 组合、暴露敏感头

- **rules/semgrep/java-microservice.yaml**: 新增 52 条微服务与数据库安全规则
  - 微服务安全（9条）：Feign 认证、Gateway 路由、Dubbo 协议、gRPC 明文、Istio mTLS
  - NoSQL 注入（4条）：MongoDB 注入、$where 注入、Elasticsearch 注入、Redis 命令注入
  - 数据库连接安全（3条）：凭证硬编码、MySQL/PostgreSQL SSL 禁用
  - 反序列化利用链（4条）：Commons BeanUtils、ROME、C3P0、AspectJWeaver
  - OWASP Top 10 2021（14条）：完整覆盖 A01-A10 十大风险类别

- **rules/semgrep/java-api-security.yaml**: 新增 54 条 API 安全与输入验证规则
  - REST API 安全（8条）：DELETE/PUT 认证、批量操作限制、幂等性、敏感数据返回、分页限制、API 文档
  - 参数验证缺失（6条）：字符串、数值、邮箱、手机号、身份证、可选参数
  - 敏感数据处理（7条）：密码明文、密码比较、敏感打印、toString、身份证/银行卡存储
  - 会话与 Token 安全（7条）：Session 敏感信息、Session ID 日志、Cookie 安全、Token URL/硬编码/时序攻击
  - 异常处理安全（5条）：堆栈泄露、异常消息返回、空 catch、通用 Exception、异常返回成功
  - 重定向与文件下载（5条）：开放重定向、文件下载路径遍历、响应类型

### Changed / 变更

- **SKILL.md**: 所有扫描命令添加 `--include="*.kt"` 或 PowerShell `Include *.java,*.kt`，支持 Kotlin 文件
- **SKILL.md Phase 2.5**: 覆盖率门禁改为分层要求
  - T1 (Controller/Filter): 必须 100%
  - T2 (Service/DAO): 90-95%
  - T3 (Entity/VO): 80-90%
  - 总体覆盖率按项目规模分级
- **references/vulnerability-conditions.md**: 所有 grep 命令添加 Kotlin 支持
- **references/dktss-scoring.md**: 核心公式改为 `Score = min(10, Base - Friction + Weapon + Ver)`
- **scripts/java_audit.py**: 重写 `run_coverage_check()` 函数
  - 分层统计 T1/T2/T3 覆盖率
  - 改进文件路径识别（支持 markdown 表格、代码块、行首格式）
  - 生成详细的分层覆盖率报告
- **rules/semgrep/java-config.yaml**: 
  - 添加 Kotlin 文件支持（`*.kt`）
  - 新增 Spring Security 6.x 规则（`authorizeHttpRequests`、Lambda DSL）
- **rules/semgrep/README.md**: 更新规则列表，总计 259 条规则

### Fixed / 修复

- 覆盖率检查正则误匹配问题：改进为优先匹配 markdown 表格格式
- DKTSS 评分超过 10 未处理：添加 `min(10, ...)` 上限
- Kotlin 项目漏检：所有扫描命令支持 `.kt` 文件
- **PowerShell 脚本缺失**：新增 `layer1-scan.ps1`、`tier-classify.ps1`、`coverage-check.ps1`
- **示例报告分析深度不足**：更新示例报告到 L3 级别，包含调用链追踪、对比分析、未使用安全机制

### Improved / 改进

- **规则总数**: 198 → 365 条（+167 条）
- **技术覆盖**: 新增 LLM/AI、GraphQL、Kotlin、Java 21、Spring Boot 3.x、微服务安全、NoSQL 注入、API 安全、输入验证、敏感数据处理、OWASP Top 10 2021 完整覆盖
- **覆盖率报告**: 更详细的分层统计，明确 T1 必须 100% 的硬性要求

---

## [1.4.0] - 2026-03-27

### 发现的问题 / Issues Found

| # | 文件 | 问题 | 严重性 | 状态 |
|---|------|------|--------|------|
| 1 | SKILL.md Phase 2.5 | 门禁阈值与判断逻辑不一致 | 中 | ✅ 已修复 |
| 2 | SKILL.md 检查清单 | "9个必填字段"已移除但检查清单未更新 | 中 | ✅ 已修复 |
| 3 | SKILL.md Phase 0 | scenario-tags.json 生成位置描述不一致 | 低 | ✅ 已修复 |
| 4 | SKILL.md 流程图 | Phase 4 标为必经阶段但实际可选 | 低 | ✅ 已修复 |
| 5 | SKILL.md Phase 1 | Agent 分配机制不清晰 | 低 | ✅ 已修复 |
| 6 | REPORT-RULES.md | 覆盖率阈值未同步更新 | 中 | ✅ 已修复 |
| 7 | README.md | 版本号和项目结构未更新 | 低 | ✅ 已修复 |

### Changed / 变更

- **SKILL.md Phase 2.5**: 统一门禁判断逻辑，移除"没有例外"表述，改为按项目规模分级
- **SKILL.md 检查清单**: 更新为"三段式格式齐全"，添加"已阅读 report-template.md"
- **SKILL.md Phase 0**: 明确标注各输出文件的生成条件（--tier/--scenario/--scan）
- **SKILL.md 流程图**: Phase 4 放到 Phase 3 后的分支，标注"（可选）"
- **SKILL.md Phase 1**: 添加 Agent 分配说明，解释不同规模项目的执行方式
- **REPORT-RULES.md**: 同步覆盖率阈值（小型 100%/中型 95%/大型 90%）
- **README.md**: 更新版本号、流程图、项目结构

---

## [1.3.0] - 2026-03-27

### 发现的问题 / Issues Found

| # | 文件 | 问题 | 严重性 | 状态 |
|---|------|------|--------|------|
| 1 | SKILL.md Phase 5 | references/ 文档未强制阅读，用户易跳过导致格式错误 | 高 | ✅ 已修复 |
| 2 | SKILL.md | "9个必填字段组" 与 report-template.md "三段式格式" 不一致 | 高 | ✅ 已修复 |
| 3 | SKILL.md 命令示例 | 只有 Linux bash 格式，Windows 用户需自行转换 | 中 | ✅ 已修复 |
| 4 | SKILL.md Phase 2.5 | 覆盖率门禁缺少自动化工具说明，100% 对大型项目不现实 | 中 | ✅ 已修复 |
| 5 | references/ | DKTSS 评分依赖联网查询 CVE，离线环境无法使用 | 中 | ✅ 已修复 |
| 6 | SKILL.md Phase 4 | Semgrep 安装说明缺失 | 低 | ✅ 已修复 |
| 7 | examples/ | 缺少示例项目和完整审计报告 | 低 | ✅ 已修复 |
| 8 | SKILL.md Phase 2.5 | 门禁阈值与判断逻辑不一致 | 中 | ✅ 已修复 |
| 9 | SKILL.md 检查清单 | "9个必填字段"已移除但检查清单未更新 | 中 | ✅ 已修复 |
| 10 | SKILL.md Phase 0 | scenario-tags.json 生成位置描述不一致 | 低 | ✅ 已修复 |
| 11 | SKILL.md 流程图 | Phase 4 标为必经阶段但实际可选 | 低 | ✅ 已修复 |
| 12 | SKILL.md Phase 1 | Agent 分配机制不清晰 | 低 | ✅ 已修复 |

### Added / 新增

- **references/cve-offline-lookup.md**: 离线 CVE 速查表，覆盖 Log4j、Fastjson、Spring、Shiro、Jackson、Tomcat、XStream 等常见组件
- **examples/README.md**: 示例项目目录说明
- **examples/vulnerable-springboot/audit-report.md**: 完整审计报告示例，包含 4 个漏洞（Velocity SSTI、Fastjson RCE、SQL注入、水平越权）的详细分析

### Changed / 变更

- **SKILL.md Phase 5**: 添加 "⚠️ 必须先阅读模板" 强制要求，确保用户阅读 report-template.md
- **SKILL.md Phase 5**: 移除重复的 "9个必填字段组" 定义，统一引用 report-template.md
- **SKILL.md Phase 2.5**: 添加 `java_audit.py --coverage` 自动化覆盖率检查说明
- **SKILL.md Phase 2.5**: 按项目规模分级覆盖率阈值（小型 100%、中型 95%、大型 90%），T1 文件必须 100%
- **SKILL.md Phase 4**: 添加 Semgrep 安装说明和快速扫描命令
- **SKILL.md 参考文档**: 添加 cve-offline-lookup.md 和 examples/ 链接

### Fixed / 修复

- **SKILL.md Phase 0**: 添加 Windows PowerShell 版本命令示例
- **SKILL.md Phase 1**: 场景识别脚本添加 PowerShell 版本
- **SKILL.md Layer 1**: P0/P1/P2 危险模式扫描命令添加 PowerShell 版本

### Improved / 改进

- 覆盖率门禁更加务实：按项目规模分级，大型项目不再强制 100%
- 离线环境支持：通过 cve-offline-lookup.md 可查常见 CVE 信息
- 学习曲线优化：示例报告帮助用户理解标准格式

---

## [1.2.0] - 2026-03-25

### 发现的问题 / Issues Found

| # | 文件 | 问题 | 严重性 | 状态 |
|---|------|------|--------|------|
| 1 | vulnerability-conditions.md | 文件末尾截断，内容不完整 | 高 | ✅ 已修复 |
| 2 | java_audit.py | 未生成 scenario-tags.json | 高 | ✅ 已修复 |
| 3 | security-checklist.md | 缺少 JWT 弱密钥、LDAP注入、CORS配置检查项 | 中 | ✅ 已修复 |
| 4 | SKILL.md | Phase 4 内容过于简略，缺少执行条件和输出要求 | 中 | ✅ 已修复 |
| 5 | REPORT-RULES.md | 缺少 scenario-tags.json 输出要求 | 高 | ✅ 已修复 |
| 6 | SKILL.md Phase 流程 | Phase 3 → Phase 5 跳过 Phase 4，流程不清晰 | 中 | ✅ 已修复 |
| 7 | layer1-scan.sh | 未检测 SnakeYAML、MVEL 等新增的危险模式 | 低 | ✅ 已修复 |
| 8 | README.md 示例路径 | Windows 用户需要不同命令，文档未说明 | 低 | ✅ 已修复 |
| 9 | coverage-check.sh | 依赖 python3，Windows 用户可能缺少 | 低 | ✅ 已修复 |

### 已修复 / Fixed in 1.2.0

- **security-checklist.md**: 补充 JWT 安全检查（弱密钥、算法混淆、过期时间）
- **security-checklist.md**: 补充 LDAP 注入检查
- **security-checklist.md**: 补充 CORS 配置检查
- **security-checklist.md**: 补充请求走私检查
- **security-checklist.md**: 补充其他检查项（限流、幂等性、批量操作、异步任务）
- **REPORT-RULES.md**: 添加 scenario-tags.json 到中间文件输出清单
- **SKILL.md Phase 4**: 完善 Phase 4 执行条件、输出文件、规则编写规范、跳过条件
- **REPORT-RULES.md**: 明确 Phase 4 为可选步骤
- **layer1-scan.sh**: 添加 SnakeYAML、MVEL 危险模式检测
- **README.md**: 添加 Windows 用户使用说明和 PowerShell 命令示例
- **java_audit.py**: 添加 `--scenario` 参数，支持生成 scenario-tags.json（API 场景标签）
- **coverage-check.sh**: 添加 Windows 用户兼容说明
- **vulnerability-conditions.md**: 修复文件末尾截断问题（删除乱码内容）
- **SKILL.md**: 修复输出文件名不一致问题（metrics.json → audit-metrics.json），补充脚本输出文件说明
- **REPORT-RULES.md**: 修复输出文件名不一致问题，补充 Layer 1 扫描输出文件说明
- **vulnerability-conditions.md**: 从 GitHub 仓库重新获取文件，修复中文字符编码问题

### 待修复 / To Fix in 1.3.0

- [ ] 暂无待修复问题

---

## [1.1.0] - 2026-03-25

### Added / 新增

- **REPORT-RULES.md**: New file defining strict report output rules / 新增报告输出规范文件
  - Report output path = Project scan path (no longer workspace or temp directories) / 报告输出路径 = 项目扫描路径（不再输出到工作区或临时目录）
  - Three-part report structure: Description → Details → Fix Recommendations / 三段式报告结构：描述 → 漏洞详情 → 修复建议
  - Precise line number requirements (no fuzzy ranges) / 行号精确要求（禁止模糊范围）
  - Code authenticity rules (must come from actual Read output) / 代码真实性规则（必须来自实际 Read 输出）
  - L3 analysis depth requirement (call chain + comparison + unused security mechanisms) / L3 分析深度要求（调用链 + 对比分析 + 未使用安全机制）

### Changed / 变更

- **Report Output Discipline / 报告输出纪律**: Reports must now be output to the scanned project directory / 报告必须输出到扫描项目目录
  - Example / 示例: `E:\华云\代码审计\26-3-24 商旅\audit-report.md`
  - Previously reports were often output to inconsistent locations / 之前报告经常输出到不一致的位置
- **Analysis Depth Standard / 分析深度标准**: Enforced L3 level analysis for all vulnerability reports / 强制所有漏洞报告达到 L3 级别分析
  - Must include: specific method names, call chain tracing, comparison with secure code, unused security mechanisms / 必须包含：具体方法名、调用链追踪、与安全代码对比、未使用安全机制
- **Analysis Format Requirement / 分析格式要求**: Prohibited three-point format (cause + attack + impact) / 禁止三点式格式（成因 + 攻击 + 影响）
  - Added detailed sample in SKILL.md and REPORT-RULES.md / 在 SKILL.md 和 REPORT-RULES.md 中添加详细样例
  - Must include: specific method name, behavior, missing controls, attack path, call chain, vulnerability type, unused security mechanisms / 必须包含：具体方法名、具体行为、缺少的安全控制、攻击路径、调用链追踪、漏洞类型归纳、未使用的安全机制

### Fixed / 修复

- **Line Number Precision / 行号精确性**: Eliminated fuzzy line ranges (e.g., `18-35` → `35`) / 消除模糊行号范围（如 `18-35` → `35`）
- **Code Authenticity / 代码真实性**: Prohibited fabricated code snippets; all must be from Read tool output / 禁止编造代码片段，所有代码必须来自 Read 工具输出
- **Analysis Depth / 分析深度**: Previously often wrote simple three-point format, now enforced L3 detailed analysis / 之前经常写成简单的三点式，现在强制 L3 详细分析

### Improved / 改进（举一反三检查）

- **11 Core Rules / 11条核心铁律**: Added comprehensive checklist to prevent common oversights / 添加综合检查清单防止常见遗漏
  1. Report output path / 报告输出路径
  2. Analysis depth (L3) / 分析深度（L3级别）
  3. Phase execution order (no skipping) / Phase执行顺序（禁止跳过）
  4. Intermediate file output / 中间文件输出
  5. Dual-track audit / 双轨审计
  6. Call chain tracing (every hop) / 调用链追踪（每一跳）
  7. Coverage gate (100%) / 覆盖率门禁（100%）
  8. DKTSS scoring (detailed) / DKTSS评分（详细）
  9. Vulnerability condition judgment / 漏洞成立条件判断
  10. Dependency security check (web search) / 依赖安全检查（联网搜索）
  11. CoT four-step reasoning (logic vulnerabilities) / CoT四步推理（逻辑漏洞）

---

## [1.0.0] - 2026-03-19

### Added

- **6-Phase Audit Pipeline**: Complete workflow from code metrics to standardized reports
- **Multi-Layer Audit Architecture**: Pre-scan + Dual-track audit + CoT reasoning + Semantic verification
- **Coverage Gate**: Enforces 100% code coverage before proceeding to verification
- **DKTSS Scoring System**: Practical vulnerability priority scoring (better than CVSS for real-world impact)
- **Anti-Hallucination Mechanism**: 5 iron rules ensuring report credibility
- **Cross-platform Python Scripts**: Unified entry point for Windows/Linux/macOS
- **Semgrep Rules**: 198 rules covering 55+ vulnerability types
- **Bilingual Documentation**: Full English and Chinese support

### Documentation

- `SKILL.md` - Complete audit protocol specification
- `references/dktss-scoring.md` - DKTSS scoring system details
- `references/vulnerability-conditions.md` - Vulnerability confirmation criteria
- `references/logic-vulnerability-cot.md` - CoT four-step reasoning for logic vulnerabilities
- `references/business-scenario-tags.md` - Business scenario tagging system
- `references/security-checklist.md` - Comprehensive security audit checklist
- `references/report-template.md` - Standardized vulnerability report template

### Vulnerability Coverage

#### P0 (Critical)

- Deserialization: Fastjson, Jackson, XStream, Hessian, SnakeYAML, Java native
- SSTI: Velocity, FreeMarker, Thymeleaf, Pebble
- Expression Injection: SpEL, OGNL, MVEL
- JNDI Injection
- Command Execution

#### P1 (High)

- SQL Injection (MyBatis `${}`, JDBC, JPA/HQL)
- SSRF
- Path Traversal / File Operations
- XXE

#### P2 (Medium)

- Authentication/Authorization issues
- Cryptographic weaknesses
- Information Disclosure
- Configuration vulnerabilities

---

## Future Roadmap

- [ ] RAG integration for large codebase handling
- [ ] LSP support for semantic call chain tracing
- [ ] CI/CD pipeline templates
- [ ] Web dashboard for audit management
- [ ] Multi-language support (Python, Go, PHP)
