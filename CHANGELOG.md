# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.7.0] - 2026-03-31

### 审查发现的问题 / Issues Found in Review

| # | 问题 | 严重性 | 状态 |
|---|------|--------|------|
| 1 | 联网搜索工具选择错误 - 使用 web_search 但未配置，应使用 tavily | 🔴 高 | ✅ 已修复 |
| 2 | CVE 编号编造 - 报告 CVE-2020-1948 为 Hessian 漏洞（实际是 Dubbo），CVE-2019-1323 为 Hessian XXE（实际是 Windows Update） | 🔴 高 | ✅ 已修复 |
| 3 | 行号定位不准 - 报告行号总是往前偏移几行 | 🟠 中 | ✅ 已修复 |
| 4 | 报告分析草草 - 未达到 L4 级别要求，缺少调用链、对比分析、未使用安全机制 | 🔴 高 | ✅ 已修复 |
| 5 | 报告格式问题 - 标题含严重程度标签、漏洞详情前有多余元信息块、分析写成标题式而非段落式 | 🟠 中 | ✅ 已修复 |
| 6 | 代码位置不使用完整路径 - 只写文件名，用户无法直接定位 | 🟠 中 | ✅ 已修复 |
| 7 | 分析不够详细 - 未达到 L4 级别，字数不足、要素缺失 | 🟠 中 | ✅ 已修复 |
| 8 | 缺少覆盖率统计 - 报告完成后未汇报 Layer 1/2/3 审计覆盖率 | 🟠 中 | ✅ 已修复 |
| 9 | 入口点统计不完整 - 未覆盖原生 Servlet、Struts、Jersey 等框架 | 🟠 中 | ✅ 已修复 |
| 10 | 审计流程问题 - Phase 4 位置、EALOC 时机、覆盖率回溯等 8 个问题 | 🔴 高 | ✅ 已修复 |
| 11 | README.md 功能介绍和流程介绍不够详细 | 🟠 中 | ✅ 已修复 |

### Changed / 变更

- **SKILL.md Phase 2-Deep 依赖安全检查**: 改为"必须使用 tavily"，添加详细命令示例
  ```bash
  node ~/.openclaw/workspace/skills/tavily-search/scripts/search.mjs "<组件名> <版本号> CVE" -n 10
  node ~/.openclaw/workspace/skills/tavily-search/scripts/extract.mjs "https://nvd.nist.gov/vuln/detail/CVE-XXX"
  ```
- **SKILL.md Phase 3 反幻觉铁律**: 从 5 条扩展为 7 条
  - 新增第 6 条：CVE 编号必须联网核实，禁止凭记忆编造
  - 新增第 7 条：行号必须用 Read 验证，禁止模糊范围或猜测
- **SKILL.md Phase 5 报告格式铁律**: 新增报告格式要求
  - 代码位置必须使用完整绝对路径
  - 分析必须达到 L4 级别（1500字以上）
  - 分析格式为连贯段落式（禁止标题式）
- **SKILL.md 执行检查清单**: 新增 5 个检查项
  - CVE 编号已联网核实（禁止凭记忆编造）
  - 行号已用 Read 验证（禁止模糊范围）
  - 依赖安全检查使用 tavily（禁止 web_search）
  - 分析达到 L4 级别（调用链+对比分析+攻击路径+未使用安全机制）
  - 代码位置使用完整绝对路径（禁止只写文件名）

### Added / 新增

- **references/report-template.md**: 新增"CVE 编号核实规范"章节
  - 核实流程（搜索 → 确认来源 → 确认组件对应关系）
  - 报告中的 CVE 描述格式（正确 vs 错误示例）
- **references/report-template.md**: 新增"报告格式禁忌"章节
  - 禁止在标题中添加严重程度标签
  - 禁止在漏洞详情前添加元信息块
  - 禁止代码位置不使用完整绝对路径
  - 禁止分析写成标题式（应为段落式）
- **references/report-template.md**: 新增"分析深度分级"章节
  - L1-L4 级别定义
  - java-audit-skill 要求 L4 级别（1500字以上）
- **references/report-template.md**: 新增"合格分析示例"章节
  - ❌ 不合格分析（三点式、标题式）
  - ✅ 合格分析（段落式、包含 7 要素）
- **references/security-checklist.md**: 依赖安全检查改为 tavily
- **references/vulnerability-conditions.md**: 18.2 节改为 tavily
- **REPORT-RULES.md**: 新增报告格式禁忌章节
- **REPORT-RULES.md**: 新增第 8 条铁律"代码位置必须使用完整绝对路径"
- **LEARNINGS.md**: 新增 LRN-20260331-001 至 LRN-20260331-007 学习记录
- **SKILL.md Phase 0**: 扩展入口点统计，支持多框架
- **SKILL.md Phase 1 Rule 2**: 新增入口点类定义，覆盖 6 种主流框架

### Fixed / 修复

- **CVE 编号核实**: 禁止凭记忆编造 CVE，必须从 NVD/Snyk 官方数据确认
- **联网搜索工具**: 依赖安全检查必须使用 tavily（已配置），不再使用 web_search（Brave API 未配置）
- **行号验证**: 反幻觉铁律添加"行号必须用 Read 验证"要求
- **分析深度**: 从 L3 提升到 L4 级别，要求 1500 字以上，包含完整 7 要素
- **报告格式**: 
  - 禁止在标题中添加严重程度标签
  - 禁止在漏洞详情前添加元信息块
  - 禁止分析写成标题式（应为连贯段落式）
- **代码位置**: 必须使用完整绝对路径，禁止只写文件名
- **覆盖率统计**: 每个报告末尾必须汇报 Layer 1/2/3 审计覆盖率
- **入口点统计**: 扩展支持多框架（Spring MVC、Servlet、Struts、Filter、Jersey、Play）
- **审计流程**: 修复 8 个流程问题
  - Phase 4 移到 Phase 5 之后
  - Phase 0 添加 EALOC 计算
  - Layer 2-Deep 明确执行时机
  - Phase 1 添加依赖安全检查
  - Phase 2.5 添加覆盖率回溯机制
  - Phase 3 添加与 Layer 3 区分说明
  - 添加完整输出文件清单
  - 添加小型项目简化流程
- **README.md**: 完全重写
  - 核心功能详细说明（6 阶段流水线、多层审计架构、覆盖率门禁、DKTSS 评分、反幻觉机制、调用链追踪）
  - 详细流程说明（每个 Phase 的 Step-by-step 执行步骤）
  - 使用介绍（环境要求、安装步骤、两种使用方式、具体命令示例）
  - 漏洞类型覆盖（P0/P1/P2 详细列表）
  - 中英文双语

### Improved / 改进

- CVE 核实流程更加严格：必须确认组件对应关系
- 报告分析示例更加清晰：合格示例包含完整的 7 个 L4 级别要素
- 反幻觉机制更加完善：从 5 条铁律扩展为 7 条
- 报告格式更加规范：明确禁忌事项和正确做法
- 审计可追溯性：每个报告都包含覆盖率统计

---

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

- **rules/semgrep/java-emerging.yaml**: 新增 14 条新兴技术安全规则
  - LLM/AI 安全（3条）：API Key 硬编码、Prompt 注入、Agent 无限制
  - GraphQL 安全（2条）：Introspection、深度限制
  - Kotlin 特有漏洞（2条）：!! 空安全绕过、GlobalScope
  - Java 21 新特性（1条）：Virtual Thread pinned
  - 并发安全（2条）：无界线程池、ThreadLocal 泄露
  - Fastjson 2.x（1条）：AutoType 配置
  - JWT 安全增强（2条）：弱密钥增强检测、alg=none
  - CORS 安全增强（1条）：* + Credentials 组合

- **rules/semgrep/java-microservice.yaml**: 新增 16 条微服务与数据库安全规则
  - 微服务安全（5条）：Feign 认证、Gateway CORS、Dubbo 协议、gRPC 明文、Istio mTLS
  - NoSQL 注入（3条）：MongoDB 注入、Elasticsearch 注入、Redis 命令注入
  - 数据库连接安全（3条）：凭证硬编码、MySQL/PostgreSQL SSL 禁用
  - 反序列化利用链（2条）：Commons BeanUtils、C3P0
  - OWASP Top 10 2021（3条）：ECB 模式、敏感日志、SSRF

- **rules/semgrep/java-config.yaml**: 新增 12 条组件配置安全规则
  - Log4j2（2条）：JNDI lookup、版本检查
  - Spring Security（2条）：CSRF 禁用、permitAll 配置
  - Actuator（1条）：端点暴露
  - Shiro（1条）：默认密钥
  - Swagger（1条）：开启检测
  - Druid（1条）：无认证
  - Fastjson（1条）：版本检查
  - Nacos（1条）：无认证
  - JWT（1条）：硬编码密钥
  - H2 Console（1条）：开启检测

- **rules/semgrep/java-api-security.yaml**: 新增 14 条 API 安全规则
  - REST API（4条）：DELETE/PUT 认证、批量操作限制、敏感数据返回、参数验证
  - 密码处理（2条）：明文存储、明文比较
  - 敏感信息（1条）：打印敏感数据
  - Token 安全（2条）：URL 参数、硬编码
  - 异常处理（2条）：堆栈泄露、空 catch
  - 重定向安全（1条）：开放重定向
  - 文件下载（1条）：路径遍历

- **scripts/layer1-scan.ps1**: Layer 1 危险模式预扫描 PowerShell 版本
- **scripts/tier-classify.ps1**: Tier 分类 PowerShell 版本
- **scripts/coverage-check.ps1**: 覆盖率门禁检查 PowerShell 版本
- **examples/vulnerable-springboot/src/**: 示例 Java 代码（4个漏洞示例）

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

### Improved / 改进

- **规则总数**: 198 → 314 条（+116 条新增）
- **技术覆盖**: LLM/AI、GraphQL、Kotlin、Java 21、微服务安全、NoSQL 注入、OWASP Top 10
- **覆盖率报告**: 更详细的分层统计，明确 T1 必须 100% 的硬性要求
- **Windows 支持**: 
  - 新增 3 个 PowerShell 脚本
  - 所有 Semgrep 规则兼容 Windows 编码环境
  - README 添加 Windows 使用说明

### Fixed / 修复

- 覆盖率检查正则误匹配问题：改进为优先匹配 markdown 表格格式
- DKTSS 评分超过 10 未处理：添加 `min(10, ...)` 上限
- Kotlin 项目漏检：所有扫描命令支持 `.kt` 文件
- **PowerShell 脚本缺失**：新增 `layer1-scan.ps1`、`tier-classify.ps1`、`coverage-check.ps1`
- **示例报告分析深度不足**：更新示例报告到 L3 级别，包含调用链追踪、对比分析、未使用安全机制
- **Semgrep 规则语法问题**：修复 10 个 YAML 文件中的 generic 语言、正则转义、编码问题
- **敏感信息泄露**：删除 report-template.md 中的真实项目路径

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
