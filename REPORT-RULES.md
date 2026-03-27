# 报告输出规范

## ⚠️ 核心铁律（必须遵守）

### 1. 报告输出路径
**项目扫描路径 = 报告输出路径**
```
项目路径: E:\华云\代码审计\26-3-24 商旅
报告位置: E:\华云\代码审计\26-3-24 商旅\audit-report.md
```

### 2. 分析深度要求（L3级别）
**禁止写成三点式（成因+攻击+影响）**，必须包含：
- ✅ 具体方法名：`ClassName.methodName()`
- ✅ 具体行为：方法做了什么
- ✅ 缺少的安全控制
- ✅ 攻击路径
- ✅ 调用链追踪
- ✅ 漏洞类型归纳（CWE）
- ✅ 未使用的安全机制

### 3. Phase 执行顺序（禁止跳过）
```
Phase 0 (度量) → Phase 1 (侦察) → Phase 2 (审计) → Phase 2.5 (覆盖率门禁) → Phase 3 (验证) → Phase 5 (报告)
```
**禁止跳过 Phase 0-1 直接审计！**

**注意**：Phase 4 (Semgrep规则沉淀) 为可选步骤，根据需要执行。

### 4. 中间文件输出（必须输出）
| 文件 | 说明 | 生成阶段 |
|------|------|---------|
| `audit-metrics.json` | 项目度量 | Phase 0 |
| `tier-classification.md` | Tier 分类 | Phase 1 |
| `scenario-tags.json` | API 场景标签 | Phase 1 |
| `findings-raw.md` | 候选漏洞（未验证） | Phase 2 |
| `findings-verified.md` | 验证后漏洞（已确认） | Phase 3 |
| `audit-report.md` | 最终报告 | Phase 5 |

**Layer 1 扫描输出**（`--scan` 参数）：
- `p0-critical.md` - RCE/反序列化模式
- `p1-high.md` - SQL注入/SSRF/文件操作
- `p2-medium.md` - 认证/授权/加密

### 5. 双轨审计（必须执行）
- **Sink-driven**：从危险代码往上追
- **Control-driven**：从端点往下查安全控制
**两条轨道都要执行，不能只做一个！**

### 6. 调用链追踪（每一跳都要标注）
```
❌ 错误: Controller → DAO
✅ 正确: UserController.java:45 → UserService.java:123 → UserDao.java:67
```

### 7. 覆盖率门禁（按项目规模分级）
| 项目规模 | 覆盖率要求 |
|----------|------------|
| 小型（EALOC < 15,000） | 100% |
| 中型（EALOC 15,000-50,000） | 95% |
| 大型（EALOC > 50,000） | 90% |

**T1 文件（Controller/Filter）必须 100% 覆盖，无例外。**

### 8. DKTSS 评分（必须详细评分）
```
Score = Base - Friction + Weapon + Ver
```
不能只写"高危"，必须写明评分过程。

### 9. 漏洞成立条件判断（必须按流程）
参考 `references/vulnerability-conditions.md`，不能看到危险函数就报漏洞。

### 10. 依赖安全检查（必须联网搜索）
发现危险依赖版本，必须使用 web_search 验证是否存在 CVE。

### 11. CoT 四步推理（逻辑漏洞必须执行）
```
Step 1: 场景与入口识别
Step 2: 防御机制审计
Step 3: 对抗性沙箱模拟
Step 4: 漏洞结果判定
```
**逻辑漏洞必须执行四步推理，记录推理过程！**

---

## 输出位置规则

**核心原则：报告输出路径 = 项目扫描路径**

```
项目路径: E:\华云\代码审计\26-3-24 商旅
报告位置: 
  - E:\华云\代码审计\26-3-24 商旅\audit-report.md       # 最终报告
  - E:\华云\代码审计\26-3-24 商旅\findings-raw.md       # 候选漏洞
  - E:\华云\代码审计\26-3-24 商旅\findings-verified.md  # 验证后漏洞
  - E:\华云\代码审计\26-3-24 商旅\audit-metrics.json    # 项目度量
  - E:\华云\代码审计\26-3-24 商旅\tier-classification.md # Tier分类
  - E:\华云\代码审计\26-3-24 商旅\scenario-tags.json    # API场景标签
```

## 报告模板

详见 [references/report-template.md](references/report-template.md)

### 三段式结构

```markdown
### [漏洞标题]

#### 描述
[200字以内，漏洞类型 + 成因 + 核心风险点]

#### 漏洞详情

**代码位置**：
`完整文件路径:精确行号`

**代码片段**：
```java
// 必须来自实际 Read 输出，带行号
```

**分析**：
- 具体方法名：`ClassName.methodName()`
- 调用链追踪：Controller → Service → DAO
- 对比分析：与安全代码的差异
- 未使用安全机制：如 JWT 依赖引入但未使用
- 漏洞类型归纳：CWE-XXX

#### 修复建议
[具体修复方案 + 可执行修复代码]
```

## 关键铁律

1. **行号精确**：禁止模糊范围，必须用 Read/Select-String 验证
2. **代码真实**：必须来自实际 Read 输出，不得编造
3. **分析深度**：L3 级别（含对比分析、调用链、未使用安全机制）
4. **输出路径**：项目路径 = 报告路径，不允许输出到其他位置
5. **分析格式**：禁止写成三点式，必须按照样例格式书写

## 分析深度要求（最重要！）

**❌ 禁止的模糊分析**：
```
1. **漏洞成因**：系统信任客户端传来的用户身份信息，仅做Base64解码，无签名验证。
2. **攻击方式**：攻击者可构造恶意JSON伪造身份。
3. **影响范围**：任意用户身份伪造。
```

**✅ 必须的详细分析（包含以下所有要素）**：

| 要素 | 说明 | 示例 |
|------|------|------|
| 具体方法名 | 精确到 `ClassName.methodName()` | `HeaderModelUtils.getLoginUserByStr()` |
| 具体行为 | 方法做了什么 | 仅对 Header 中的 Base64 编码数据进行解码，然后直接反序列化为 LoginUserBo 对象 |
| 缺少的安全控制 | 什么保护措施没有 | 没有对用户信息进行任何签名验证或加密保护 |
| 攻击路径 | 攻击者可以如何利用 | 可以轻松伪造任意用户的登录信息 |
| 调用链追踪 | 从入口到漏洞点的完整路径 | 控制器层 `FlightController.setFlightCityHistory()` 直接从请求头 `la517_loginUser` 获取用户信息，未经服务器端验证就传递给服务层使用 |
| 漏洞类型归纳 | 标准漏洞分类 | 形成客户端信任漏洞 |
| 未使用的安全机制 | 项目中存在但未启用的安全配置 | 经审查 `pom.xml` 发现项目已引入 JWT 相关依赖（`jjwt`），但实际并未使用。`LogInterceptor` 拦截器仅用于日志追踪（requestId 生成），不包含任何认证逻辑 |

**样例**：
```
`HeaderModelUtils.getLoginUserByStr()` 方法仅对 Header 中的 Base64 编码数据进行解码，
然后直接反序列化为 LoginUserBo 对象。系统没有对用户信息进行任何签名验证或加密保护，
攻击者可以轻松伪造任意用户的登录信息。

控制器层（如 `FlightController.setFlightCityHistory()`）直接从请求头 `la517_loginUser`
获取用户信息，该信息未经服务器端验证就传递给服务层使用，形成**客户端信任漏洞**。

经审查 `pom.xml` 发现项目已引入 JWT 相关依赖（`jjwt`），但全局搜索显示实际并未使用。
`LogInterceptor` 拦截器仅用于日志追踪（requestId 生成），不包含任何认证逻辑。
```

## 禁止行为

❌ 报告输出到工作区（`~/.openclaw/workspace/`）
❌ 报告输出到临时目录
❌ 使用模糊行号（如 `18-35` 应改为精确行号）
❌ 编造代码片段
❌ 分析停留在 L1/L2 级别