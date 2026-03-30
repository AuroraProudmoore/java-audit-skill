# Semgrep Rules for Java Security Audit

本目录包含 Java 代码安全审计的 Semgrep 规则，对应 Java Audit Skill 的 Phase 4 输出。

## 规则文件

| 文件 | 风险等级 | 规则数 | 覆盖漏洞 |
|------|----------|--------|----------|
| `java-rce.yaml` | P0 (Critical) | 21 | 反序列化、SSTI、表达式注入、JNDI注入、命令注入、脚本引擎注入、Fastjson配置、SnakeYAML、XStream |
| `java-sqli.yaml` | P1 (High) | 12 | SQL 注入、MyBatis `${}` 注入、JPA/HQL 注入、JdbcTemplate 注入 |
| `java-ssrf.yaml` | P1 (High) | 8 | SSRF (URL、HttpClient、RestTemplate、WebClient、OkHttp) |
| `java-file.yaml` | P1 (High) | 14 | 路径遍历、任意文件读写/删除/重命名、文件上传、目录遍历 |
| `java-crypto.yaml` | P2 (Medium) | 8 | 弱加密算法、弱哈希算法、不安全随机数、硬编码密钥、SSL 禁用 |
| `java-misc.yaml` | P1/P2 | 56 | XXE、XSS、敏感数据泄露、认证授权、会话管理、日志安全、配置安全、接口安全、开放重定向、LDAP注入、EL注入、JDBC Attack、内存马、拒绝服务 |
| `java-config.yaml` | P0/P1/P2 | 95 | **组件配置安全**：Log4j2、Spring Security 5/6、Spring Boot Actuator、Shiro、Swagger/Knife4j、Druid、Fastjson、Jackson、Nacos、Sentinel、Dubbo、Tomcat、Redis、MongoDB、RabbitMQ、Kafka、JPA/Hibernate、XXL-JOB、Apollo、Eureka、Spring Cloud Gateway、Zuul、Consul、Zookeeper、RocketMQ、ActiveMQ、MinIO/OSS、JWT、OAuth2、GraphQL、gRPC、WebFlux、Memcached、Solr、Velocity、FreeMarker、Thymeleaf、Drools、Activiti/Flowable、SnakeYAML、XStream、Hessian、H2、Jakarta EE 等 60+ 组件 |
| `java-emerging.yaml` | P0/P1/P2 | 45 | **新兴技术安全**：LLM/AI 安全（Prompt 注入、API Key 泄露）、GraphQL 安全、Kotlin 特有漏洞、Java 21 新特性、Virtual Threads、并发安全、幂等性检查、Fastjson 2.x、JWT 增强、CORS 增强 |
| `java-microservice.yaml` | P0/P1/P2 | 52 | **微服务与数据库安全**：Feign、Spring Cloud Gateway、Dubbo、gRPC、Istio、NoSQL 注入（MongoDB、Elasticsearch、Redis）、数据库连接安全、反序列化利用链增强、OWASP Top 10 2021 完整覆盖 |
| `java-api-security.yaml` | P1/P2 | 54 | **API 安全与输入验证**：REST API 安全、参数验证、敏感数据处理、会话安全、Token 安全、异常处理、安全头配置、重定向安全、文件下载安全 |

**总计**: 365 条规则

## 规则详情

### java-rce.yaml (P0 - Critical)

| 规则 ID | 漏洞类型 | 严重程度 |
|---------|----------|----------|
| `java-unsafe-deserialization-objectinputstream` | Java 原生反序列化 | ERROR |
| `java-unsafe-deserialization-xmldecoder` | XMLDecoder 反序列化 | ERROR |
| `java-unsafe-deserialization-xstream` | XStream 反序列化 | ERROR |
| `java-fastjson-autotype-enabled` | Fastjson autoType 开启 | ERROR |
| `java-fastjson-parse` | Fastjson 解析方法 | WARNING |
| `java-jackson-defaultTyping` | Jackson 多态类型 | ERROR |
| `java-hessian-deserialization` | Hessian 反序列化 | ERROR |
| `java-snakeyaml-unsafe` | SnakeYAML 不安全使用 | WARNING |
| `java-velocity-ssti` | Velocity SSTI | ERROR |
| `java-freemarker-ssti` | FreeMarker SSTI | ERROR |
| `java-thymeleaf-ssti` | Thymeleaf SSTI | WARNING |
| `java-spel-injection` | SpEL 表达式注入 | ERROR |
| `java-ognl-injection` | OGNL 表达式注入 | ERROR |
| `java-mvel-injection` | MVEL 表达式注入 | ERROR |
| `java-jndi-injection` | JNDI 注入 | ERROR |
| `java-command-injection-runtime-exec` | Runtime.exec 命令注入 | ERROR |
| `java-command-injection-processbuilder` | ProcessBuilder 命令注入 | ERROR |
| `java-command-injection-processbuilder-list` | ProcessBuilder List 参数 | WARNING |
| `java-script-engine-injection` | 脚本引擎代码注入 | ERROR |

### java-sqli.yaml (P1 - High)

| 规则 ID | 漏洞类型 | 严重程度 |
|---------|----------|----------|
| `java-sqli-statement-execute` | Statement 动态 SQL | ERROR |
| `java-sqli-createstatement` | createStatement 使用 | WARNING |
| `java-sqli-string-concat` | SQL 字符串拼接 | ERROR |
| `java-mybatis-dollar-sign` | MyBatis ${} 占位符 | ERROR |
| `java-jpa-native-query-concat` | JPA 原生 SQL 拼接 | ERROR |
| `java-jpa-native-query-string` | JPA 原生 SQL 变量 | WARNING |
| `java-hql-injection` | HQL 注入 | WARNING |
| `java-jdbc-template-concat` | JdbcTemplate 拼接 | ERROR |
| `java-sqli-order-by` | ORDER BY 注入 | WARNING |
| `java-sqli-in-clause` | IN 子句注入 | WARNING |

### java-ssrf.yaml (P1 - High)

| 规则 ID | 漏洞类型 | 严重程度 |
|---------|----------|----------|
| `java-ssrf-url-constructor` | URL 构造 | ERROR |
| `java-ssrf-httpurlconnection` | HttpURLConnection | ERROR |
| `java-ssrf-resttemplate-get` | RestTemplate GET | ERROR |
| `java-ssrf-resttemplate-post` | RestTemplate POST | ERROR |
| `java-ssrf-resttemplate-exchange` | RestTemplate exchange | ERROR |
| `java-ssrf-webclient` | WebClient | ERROR |
| `java-ssrf-httpclient` | HttpClient | WARNING |
| `java-ssrf-okhttp` | OkHttp | WARNING |

### java-file.yaml (P1 - High)

| 规则 ID | 漏洞类型 | 严重程度 |
|---------|----------|----------|
| `java-path-traversal-fileinputstream` | FileInputStream 路径遍历 | ERROR |
| `java-path-traversal-filereader` | FileReader 路径遍历 | ERROR |
| `java-path-traversal-fileoutputstream` | FileOutputStream 路径遍历 | ERROR |
| `java-path-traversal-filewriter` | FileWriter 路径遍历 | ERROR |
| `java-file-upload-filename` | 文件上传文件名 | WARNING |
| `java-file-upload-transferTo` | 文件上传 transferTo | WARNING |
| `java-arbitrary-file-read-nio` | NIO 文件读取 | ERROR |
| `java-arbitrary-file-read-lines` | Files.readAllLines | ERROR |
| `java-arbitrary-file-write-nio` | NIO 文件写入 | ERROR |
| `java-arbitrary-file-delete` | 文件删除 | ERROR |
| `java-temp-file-insecure` | 临时文件 | WARNING |
| `java-file-copy-insecure` | 文件复制 | WARNING |

### java-crypto.yaml (P2 - Medium)

| 规则 ID | 漏洞类型 | 严重程度 |
|---------|----------|----------|
| `java-weak-hash-md5` | MD5 哈希 | WARNING |
| `java-weak-hash-sha1` | SHA-1 哈希 | WARNING |
| `java-weak-crypto-des` | DES 加密 | ERROR |
| `java-weak-crypto-3des` | 3DES 加密 | WARNING |
| `java-weak-crypto-aes-ecb` | AES ECB 模式 | ERROR |
| `java-insecure-random` | 不安全随机数 | WARNING |
| `java-hardcoded-secret` | 硬编码密钥 | WARNING |
| `java-ssl-disabled` | SSL 验证禁用 | ERROR |

### java-misc.yaml (P1/P2 - 综合安全)

#### XXE (XML External Entity)

| 规则 ID | 漏洞类型 | 严重程度 |
|---------|----------|----------|
| `java-xxe-documentbuilder` | DocumentBuilder XXE | ERROR |
| `java-xxe-saxparser` | SAXParser XXE | ERROR |
| `java-xxe-xmlreader` | XMLReader XXE | ERROR |
| `java-xxe-xmlinputfactory` | XMLInputFactory XXE | ERROR |
| `java-xxe-unmarshaller` | JAXB Unmarshaller XXE | WARNING |
| `java-xxe-dom4j` | dom4j SAXReader XXE | WARNING |
| `java-xxe-jdom` | JDOM SAXBuilder XXE | WARNING |

#### XSS (Cross-Site Scripting)

| 规则 ID | 漏洞类型 | 严重程度 |
|---------|----------|----------|
| `java-xss-response-writer` | Response Writer XSS | WARNING |
| `java-xss-printwriter` | PrintWriter XSS | WARNING |
| `java-xss-jsp-expression` | JSP 表达式 XSS | WARNING |

#### 敏感数据泄露

| 规则 ID | 漏洞类型 | 严重程度 |
|---------|----------|----------|
| `java-sensitive-log-password` | 密码记录日志 | ERROR |
| `java-sensitive-log-token` | Token 记录日志 | WARNING |
| `java-sensitive-printstacktrace` | printStackTrace 泄露 | WARNING |
| `java-sensitive-exception-message` | 异常消息泄露 | WARNING |

#### 认证授权

| 规则 ID | 漏洞类型 | 严重程度 |
|---------|----------|----------|
| `java-auth-permitAll` | permitAll 配置 | WARNING |
| `java-auth-anonymous` | anonymous 配置 | WARNING |
| `java-auth-jwt-weak-secret` | JWT 弱密钥 | WARNING |
| `java-auth-bcrypt-weak-rounds` | BCrypt 迭代轮数 | INFO |

#### 会话管理

| 规则 ID | 漏洞类型 | 严重程度 |
|---------|----------|----------|
| `java-session-cookie-secure-missing` | Cookie 安全属性缺失 | WARNING |
| `java-session-insecure-id` | 不安全 Session ID | ERROR |
| `java-session-fixation` | 会话固定风险 | INFO |

#### 日志安全 (Log4j)

| 规则 ID | 漏洞类型 | 严重程度 |
|---------|----------|----------|
| `java-log4j-jndi-lookup` | Log4j JNDI Lookup | ERROR |
| `java-log4j-context-lookup` | Log4j Context Lookup | WARNING |

#### 配置安全

| 规则 ID | 漏洞类型 | 严重程度 |
|---------|----------|----------|
| `java-config-debug-enabled` | Debug 模式开启 | WARNING |
| `java-config-swagger-enabled` | Swagger 开启 | WARNING |
| `java-config-actuator-exposed` | Actuator 暴露 | ERROR |
| `java-config-h2-console` | H2 Console 开启 | ERROR |

#### 接口安全

| 规则 ID | 漏洞类型 | 严重程度 |
|---------|----------|----------|
| `java-api-cors-wildcard` | CORS 通配符 | WARNING |
| `java-api-cors-credentials` | CORS 凭证配置 | WARNING |
| `java-api-request-size-unlimited` | 请求大小无限制 | WARNING |
| `java-ssl-disabled` | SSL 验证禁用 | ERROR |

### java-microservice.yaml (P0/P1/P2 - 微服务与数据库安全)

#### 微服务安全

| 规则 ID | 漏洞类型 | 严重程度 |
|---------|----------|----------|
| `java-feign-no-auth` | Feign 服务间无认证 | WARNING |
| `java-feign-url-hardcoded` | Feign URL 硬编码 | INFO |
| `java-feign-insecure-ssl` | Feign SSL 禁用 | ERROR |
| `java-gateway-route-no-auth` | Gateway 路由无认证 | WARNING |
| `java-gateway-filter-bypass` | Gateway 过滤器绕过 | WARNING |
| `java-dubbo-protocol-unsafe` | Dubbo 协议安全 | WARNING |
| `java-dubbo-token-missing` | Dubbo Token 缺失 | WARNING |
| `java-grpc-insecure-channel` | gRPC 明文通道 | WARNING |
| `java-istio-mtls-disabled` | Istio mTLS 禁用 | WARNING |

#### NoSQL 注入

| 规则 ID | 漏洞类型 | 严重程度 |
|---------|----------|----------|
| `java-mongodb-injection` | MongoDB 注入 | ERROR |
| `java-mongodb-where-clause` | MongoDB $where 注入 | ERROR |
| `java-elasticsearch-injection` | Elasticsearch 注入 | ERROR |
| `java-redis-command-injection` | Redis 命令注入 | WARNING |

#### 数据库连接安全

| 规则 ID | 漏洞类型 | 严重程度 |
|---------|----------|----------|
| `java-datasource-credentials-hardcoded` | 数据库凭证硬编码 | ERROR |
| `java-mysql-ssl-disabled` | MySQL SSL 禁用 | WARNING |
| `java-postgres-ssl-disabled` | PostgreSQL SSL 禁用 | WARNING |

#### 反序列化利用链增强

| 规则 ID | 漏洞类型 | 严重程度 |
|---------|----------|----------|
| `java-deserialization-gadget-commons-beanutils` | CB 利用链 | WARNING |
| `java-deserialization-gadget-rome` | ROME 利用链 | WARNING |
| `java-deserialization-gadget-c3p0` | C3P0 利用链 | WARNING |
| `java-deserialization-gadget-aspectjweaver` | AspectJWeaver 利用链 | WARNING |

#### OWASP Top 10 2021 完整覆盖

| 规则 ID | 漏洞类型 | OWASP 分类 |
|---------|----------|------------|
| `java-access-control-path-bypass` | 路径访问控制绕过 | A01:2021 |
| `java-crypto-hardcoded-iv` | 硬编码 IV | A02:2021 |
| `java-crypto-ecb-mode` | AES ECB 模式 | A02:2021 |
| `java-sql-order-by-injection` | ORDER BY 注入 | A03:2021 |
| `java-sql-like-injection` | LIKE 子句注入 | A03:2021 |
| `java-design-missing-rate-limit` | 缺少限流 | A04:2021 |
| `java-config-error-verbose` | 详细错误信息 | A05:2021 |
| `java-dependency-snapshot-vulnerable` | 不安全版本声明 | A06:2021 |
| `java-auth-session-fixation` | 会话固定 | A07:2021 |
| `java-auth-weak-password-policy` | 弱密码策略 | A07:2021 |
| `java-integrity-autoType-enabled` | AutoType 开启 | A08:2021 |
| `java-logging-sensitive-data` | 敏感信息日志 | A09:2021 |
| `java-logging-missing-audit` | 缺少审计日志 | A09:2021 |
| `java-ssrf-url-validation-missing` | SSRF URL 验证缺失 | A10:2021 |

### java-api-security.yaml (P1/P2 - API 安全与输入验证)

#### REST API 安全

| 规则 ID | 漏洞类型 | 严重程度 |
|---------|----------|----------|
| `java-api-delete-no-auth` | DELETE 接口无认证 | WARNING |
| `java-api-put-no-auth` | PUT 接口无认证 | WARNING |
| `java-api-batch-operation-no-limit` | 批量操作无限制 | WARNING |
| `java-api-no-idempotency-key` | 缺少幂等性控制 | WARNING |
| `java-api-response-sensitive-data` | 敏感数据返回 | ERROR |
| `java-api-pagination-no-limit` | 分页无限制 | WARNING |
| `java-api-version-in-url` | API 版本控制 | INFO |
| `java-api-docs-exposed` | API 文档暴露 | WARNING |

#### 参数验证缺失

| 规则 ID | 漏洞类型 | 严重程度 |
|---------|----------|----------|
| `java-validation-missing-string` | 字符串参数无验证 | WARNING |
| `java-validation-missing-number` | 数值参数无验证 | WARNING |
| `java-validation-email-missing` | 邮箱格式未验证 | INFO |
| `java-validation-phone-missing` | 手机号格式未验证 | INFO |
| `java-validation-idcard-missing` | 身份证格式未验证 | INFO |
| `java-validation-optional-bypass` | 可选参数验证绕过 | INFO |

#### 敏感数据处理

| 规则 ID | 漏洞类型 | 严重程度 |
|---------|----------|----------|
| `java-password-plaintext` | 密码明文 | ERROR |
| `java-password-compare-plaintext` | 密码明文比较 | ERROR |
| `java-password-in-url` | URL 包含密码 | ERROR |
| `java-sensitive-print` | 敏感信息打印 | ERROR |
| `java-sensitive-tostring` | toString 包含敏感信息 | WARNING |
| `java-idcard-plaintext-storage` | 身份证明文存储 | WARNING |
| `java-bankcard-plaintext` | 银行卡明文存储 | WARNING |

#### 会话与 Token 安全

| 规则 ID | 漏洞类型 | 严重程度 |
|---------|----------|----------|
| `java-session-attribute-sensitive` | Session 存敏感信息 | ERROR |
| `java-session-id-logging` | Session ID 日志 | WARNING |
| `java-session-cookie-httponly-false` | HttpOnly=false | WARNING |
| `java-session-cookie-secure-false` | Secure=false | WARNING |
| `java-token-url-param` | Token 在 URL 中 | WARNING |
| `java-token-hardcoded` | Token 硬编码 | ERROR |
| `java-token-compare-unsafe` | Token 时序攻击 | WARNING |

#### 异常处理安全

| 规则 ID | 漏洞类型 | 严重程度 |
|---------|----------|----------|
| `java-exception-stacktrace-expose` | 堆栈信息泄露 | WARNING |
| `java-exception-message-return` | 异常消息返回 | WARNING |
| `java-exception-catch-empty` | 空 catch 块 | WARNING |
| `java-exception-catch-exception` | 捕获通用 Exception | INFO |
| `java-exception-return-success` | 异常返回成功 | WARNING |

#### 重定向与文件下载安全

| 规则 ID | 漏洞类型 | 严重程度 |
|---------|----------|----------|
| `java-redirect-open` | 开放重定向 | WARNING |
| `java-redirect-url-param` | 重定向 URL 参数 | WARNING |
| `java-file-download-path-traversal` | 文件下载路径遍历 | ERROR |
| `java-file-download-no-auth` | 文件下载无认证 | WARNING |
| `java-file-response-type-missing` | 文件响应类型缺失 | INFO |

## 使用方法

### 安装 Semgrep

```bash
# macOS
brew install semgrep

# Linux
pip install semgrep

# 或使用 Docker
docker pull returntocorp/semgrep
```

### 扫描项目

```bash
# 扫描单个规则文件
semgrep --config rules/semgrep/java-rce.yaml /path/to/project

# 扫描所有规则
semgrep --config rules/semgrep/ /path/to/project

# 输出 JSON 格式
semgrep --config rules/semgrep/ --json /path/to/project > results.json

# 仅显示 ERROR 级别
semgrep --config rules/semgrep/ --severity ERROR /path/to/project

# 输出 SARIF 格式 (用于 GitHub Code Scanning)
semgrep --config rules/semgrep/ --sarif /path/to/project > results.sarif
```

### CI/CD 集成

```yaml
# GitHub Actions 示例
name: Security Audit
on: [push, pull_request]

jobs:
  semgrep:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: returntocorp/semgrep-action@v1
        with:
          config: >-
            p/security-audit
            p/secrets
            ./rules/semgrep/
```

## 规则优先级

| 严重程度 | 说明 | 响应时效 |
|----------|------|----------|
| ERROR | 确认存在漏洞，需立即修复 | 24h 内 |
| WARNING | 疑似漏洞或潜在风险，需人工确认 | 7 天内 |

### java-emerging.yaml (P0/P1/P2 - 新兴技术安全)

#### LLM/AI 安全

| 规则 ID | 漏洞类型 | 严重程度 |
|---------|----------|----------|
| `java-llm-apikey-hardcoded` | LLM API Key 硬编码 | ERROR |
| `java-llm-prompt-injection` | Prompt 注入 | ERROR |
| `java-llm-langchain-agent-unrestricted` | LangChain Agent 无限制 | WARNING |
| `java-llm-output-unsafe` | LLM 输出未验证 | INFO |

#### GraphQL 安全

| 规则 ID | 漏洞类型 | 严重程度 |
|---------|----------|----------|
| `java-graphql-introspection-enabled` | Introspection 开启 | WARNING |
| `java-graphql-depth-limit-missing` | 无深度限制 | WARNING |
| `java-graphql-batch-limit-missing` | 无批量限制 | INFO |
| `java-graphql-field-suggestion-enabled` | 字段建议开启 | INFO |

#### Kotlin 特有漏洞

| 规则 ID | 漏洞类型 | 严重程度 |
|---------|----------|----------|
| `kotlin-null-safety-bypass` | !! 操作符绕过空安全 | WARNING |
| `kotlin-coroutine-unsafe-globalscope` | GlobalScope 使用 | WARNING |
| `kotlin-coroutine-runblocking` | runBlocking 使用 | INFO |
| `kotlin-insecure-random` | 非安全随机数 | WARNING |
| `kotlin-unsafe-cast` | 强制类型转换 | INFO |

#### Java 21 新特性

| 规则 ID | 漏洞类型 | 严重程度 |
|---------|----------|----------|
| `java21-virtual-thread-pinned` | Virtual Thread pinned | WARNING |
| `java21-foreign-function-unsafe` | FFI 内存操作 | WARNING |
| `java21-pattern-matching-exhaustive` | switch 覆盖检查 | INFO |

#### Jakarta EE / Spring Boot 3.x

| 规则 ID | 漏洞类型 | 严重程度 |
|---------|----------|----------|
| `jakarta-servlet-filter-config` | Servlet Filter 配置 | INFO |
| `jakarta-persistence-sqli` | JPA SQL 注入风险 | WARNING |
| `jakarta-validation-missing` | 输入验证缺失 | INFO |
| `springboot3-native-image-reflection` | Native Image 反射 | INFO |

#### 并发安全

| 规则 ID | 漏洞类型 | 严重程度 |
|---------|----------|----------|
| `java-concurrent-threadpool-unbounded` | 无界线程池 | WARNING |
| `java-concurrent-race-condition` | 竞态条件 | WARNING |
| `java-concurrent-threadlocal-leak` | ThreadLocal 泄露 | WARNING |

#### 幂等性检查

| 规则 ID | 漏洞类型 | 严重程度 |
|---------|----------|----------|
| `java-idempotency-missing-payment` | 支付接口幂等性 | WARNING |
| `java-idempotency-missing-order` | 下单接口幂等性 | INFO |

#### Fastjson 2.x

| 规则 ID | 漏洞类型 | 严重程度 |
|---------|----------|----------|
| `java-fastjson2-unsafe-config` | Fastjson 2.x AutoType | ERROR |
| `java-fastjson2-version-check` | Fastjson 2.x 版本检查 | WARNING |

#### JWT 安全增强

| 规则 ID | 漏洞类型 | 严重程度 |
|---------|----------|----------|
| `java-jwt-weak-secret-enhanced` | JWT 弱密钥增强检测 | ERROR |
| `java-jwt-no-expiration` | JWT 无过期时间 | WARNING |
| `java-jwt-alg-none` | JWT alg=none | ERROR |

#### CORS 安全增强

| 规则 ID | 漏洞类型 | 严重程度 |
|---------|----------|----------|
| `java-cors-credentials-wildcard` | CORS * + Credentials | ERROR |
| `java-cors-exposed-headers-sensitive` | 暴露敏感头 | WARNING |

## 自定义规则

添加新规则到对应文件中：

```yaml
rules:
  - id: your-rule-id
    patterns:
      - pattern: 危险模式
      - pattern-not: 安全模式
    message: 规则描述
    severity: ERROR
    languages: [java]
    metadata:
      category: security
      cwe: "CWE-XXX"
```

## 误报处理

如果规则产生误报，可以：

1. **在代码中添加注释**:
```java
// nosemgrep: java-weak-hash-md5
MessageDigest md = MessageDigest.getInstance("MD5"); // 用于非安全场景
```

2. **修改规则添加更多排除条件**

3. **调整规则严重程度**

## 参考

- [Semgrep 官方文档](https://semgrep.dev/docs/)
- [Semgrep 规则编写指南](https://semgrep.dev/docs/writing-rules/overview/)
- [CWE 漏洞分类](https://cwe.mitre.org/)
- [OWASP Top 10](https://owasp.org/Top10/)