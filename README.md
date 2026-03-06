# ZhiLinClaw

本地优先的开源 AI助手框架 - Local-First AI Assistant Framework

基于 ArkTS 语言实现，参考 OpenClaw、IronClaw和汉武帝架构理念设计。

## 核心理念

### OpenClaw 理念
1. **本地优先** - 所有数据存储在本地，保护用户隐私
2. **模块化设计** - 各组件独立，可灵活替换
3. **插件化架构** - 支持动态扩展功能
4. **事件驱动** - 基于发布订阅模式实现解耦通信

### IronClaw 安全增强
1. **WASM 沙箱隔离** - 工具在隔离环境中执行，防止恶意代码
2. **加密保险柜** - 凭证加密存储，运行时动态注入
3. **多层安全过滤** - 防止提示词注入、XSS、命令注入等攻击
4. **OAuth 网关** - 安全的认证流程，支持多提供商

### 汉武帝 AI Agent 架构 ⭐ 新增
1. **决策层** - 策略师、研究员、顾问提供规划与知识支撑
2. **执行层** - 工程师、协调官、记录官负责落地实施
3. **监督层** - 质检员、修复师保障质量与问题闭环
4. **SOP 工作流** - Code = SOP(Team)，标准化作业流程具象化为协作规则

## 项目结构

```
zhilinclaw/
├── src/
│   ├── core/           # 核心内核模块
│   │   ├── ZhiLinClawCore.ets
│   │   └── index.ets
│   ├── events/         # 事件总线模块
│   │   ├── EventBus.ets
│   │   └── index.ets
│   ├── plugins/        # 插件容器模块
│   │   ├── PluginManager.ets
│   │   └── index.ets
│   ├── memory/         # 记忆管理器模块
│   │   ├── MemoryManager.ets
│   │   └── index.ets
│   ├── skills/         # 技能注册表模块
│   │   ├── SkillRegistry.ets
│   │   └── index.ets
│   ├── adapters/       # 接口适配层
│   │   ├── AIModelAdapter.ets
│   │   ├── StorageAdapter.ets
│   │   └── index.ets
│   ├── security/       # 安全模块 (IronClaw 理念)
│   │   ├── SecurityContext.ets
│   │   ├── CredentialVault.ets
│   │   ├── SecurityFilter.ets
│   │   ├── SandboxedExecutor.ets
│   │   ├── OAuthGateway.ets
│   │   └── index.ets
│   └── agents/         # AI Agent 团队 (汉武帝架构) ⭐ 新增
│       ├── AgentBase.ets
│       ├── Strategist.ets        # 策略师
│       ├── Researcher.ets        # 研究员
│       ├── Advisor.ets           # 顾问
│       ├── Engineer.ets          # 工程师
│       ├── Coordinator.ets       # 协调官
│       ├── Recorder.ets          # 记录官
│       ├── Inspector.ets         # 质检员
│       ├── Fixer.ets             # 修复师
│       └── HanwudiWorkflow.ets   # SOP 工作流引擎
├── examples/           # 示例代码
│   ├── WeatherPlugin.ets
│   ├── FileManagerPlugin.ets
│   ├── main.ets
│   ├── SecurityDemo.ets
│   └── HanwudiDemo.ets       # 汉武帝架构示例 ⭐ 新增
├── docs/                 # 文档
│   └── HANWUDI_ARCHITECTURE.md  # 汉武帝架构文档 ⭐ 新增
├── package.json
├── build-profile.json5
└── oh-package.json5
```

## 架构设计

采用 OpenClaw 的四层架构 + IronClaw 的安全层：

1. **核心内核层 (Core Kernel)** - ZhiLinClawCore
   - 系统初始化和协调
   - 请求处理和分发
   - 模块生命周期管理

2. **插件容器层 (Plugin Container)** - PluginManager
   - 插件注册与卸载
   - 插件生命周期控制
   - 沙箱隔离

3. **接口适配层 (Interface Adapter)** - Adapters
   - AI 模型适配（本地/云端）
   - 存储适配（Preferences/RDB/File）

4. **插件应用层 (Plugin Application)** - Plugins & Skills
   - 具体功能实现
   - 技能注册与执行

5. **安全层 (Security Layer)** - Security Module
   - WASM 沙箱隔离执行
   - 加密凭证管理
   - 输入输出过滤
   - OAuth 认证网关

## 快速开始

### 环境要求

- OpenHarmony SDK 5.0+
- ArkTS 编译器
- DevEco Studio（推荐）

### 安装依赖

```bash
npm install
```

### 构建项目

```bash
npm run build
```

### 运行示例

```bash
npm run start
```

## 核心模块说明

### ZhiLinClawCore

核心系统类，提供：
- 单例模式访问
- 模块初始化
- 请求处理入口
- 系统状态查询

```typescript
const core = ZhiLinClawCore.getInstance();
await core.initialize({
  name: 'ZhiLinClaw',
  version: '1.0.0',
  dataPath: '/data/local/zhilinclaw',
  enableLogging: true,
  maxMemoryItems: 500
});
```

### EventBus

事件总线，实现组件间解耦通信：
- 订阅/发布模式
- 一次性事件监听
- 异步事件处理

```typescript
eventBus.subscribe('plugin:loaded', (data) => {
  console.log('插件已加载:', data.pluginName);
});

await eventBus.publish('plugin:loaded', { pluginName: 'weather' });
```

### PluginManager

插件管理器，负责：
- 插件注册与注销
- 插件启用/禁用
- 生命周期钩子调用

```typescript
const plugin = new WeatherPlugin();
await pluginManager.register(plugin);
await pluginManager.enable('weather_plugin');
```

### MemoryManager

记忆管理器，实现双模式记忆系统：
- 短期记忆存储
- LRU 淘汰策略
- 记忆检索与过滤

```typescript
await memoryManager.add({
  type: MemoryType.USER_INPUT,
  content: '今天天气怎么样？',
  timestamp: Date.now()
});

const recent = memoryManager.getRecent(10);
```

### SkillRegistry

技能注册表，管理所有技能：
- 技能注册与发现
- 技能匹配与执行
- 调用统计

```typescript
await skillRegistry.register(weatherSkill);
const matched = skillRegistry.matchSkills('今天天气如何？');
const result = await skillRegistry.executeSkill('weather_query', input);
```

### Security Module (新增)

#### CredentialVault - 加密保险柜

```typescript
import { CredentialVault, CredentialType } from './security';

const vault = new CredentialVault(encryptionKey);

// 存储凭证
const apiKeyId = await vault.store(
  'openai_api_key',
  CredentialType.API_KEY,
  'sk-xxxx...',
  { tags: ['openai'], accessPolicy: { allowedExecutors: ['ai_service'] } }
);

// 获取凭证
const apiKey = await vault.get(apiKeyId, 'ai_service');
```

#### SecurityFilter - 安全过滤器

```typescript
import { SecurityFilter } from './security';

const filter = new SecurityFilter({
  enablePromptInjectionDetection: true,
  enableXSSDetection: true,
  riskThreshold: RiskLevel.HIGH
});

// 检查输入
const result = await filter.checkInput(userInput);
if (!result.passed) {
  console.log('检测到安全风险:', result.issues);
}

// 清理输出
const sanitized = filter.sanitizeOutput(aiOutput);
```

#### OAuthGateway - OAuth 认证网关

```typescript
import { OAuthGateway } from './security';

const gateway = new OAuthGateway(vault);

// 注册提供商
gateway.registerProvider({
  id: 'github',
  name: 'GitHub',
  authorizationUrl: 'https://github.com/login/oauth/authorize',
  tokenUrl: 'https://github.com/login/oauth/access_token',
  clientId: 'your_client_id',
  clientSecretCredentialId: secretId,
  redirectUri: 'http://localhost:3000/callback',
  scopes: ['user:email']
});

// 获取授权 URL
const authUrl = gateway.getAuthorizationUrl('github');

// 处理回调
await gateway.handleCallback('github', code, state);

// 获取访问令牌
const accessToken = await gateway.getAccessToken('github');
```

#### SandboxedExecutor - 沙箱执行器

```typescript
import { SandboxedExecutor } from './security';

const sandbox = new SandboxedExecutor({
  timeout: 5000,
  maxMemory: 64,
  allowNetwork: false
});

// 在沙箱中执行工具
const result = await sandbox.executeTool('calculator', [1, 2]);
```

## 开发插件

### 1. 创建插件类

```typescript
import { Plugin } from '../plugins/PluginManager';
import { Skill } from '../skills/SkillRegistry';

export class MyPlugin extends Plugin {
  constructor() {
    super({
      name: 'my_plugin',
      version: '1.0.0',
      description: '我的插件描述',
      author: '作者名',
      minCoreVersion: '1.0.0',
      permissions: ['network_access']
    });
  }

  async onEnable(): Promise<void> {
    // 插件启用时的初始化
  }

  async onDisable(): Promise<void> {
    // 插件禁用时的清理
  }
}
```

### 2. 创建技能

```typescript
class MySkill extends Skill {
  async execute(input: string, context?: any): Promise<SkillResult> {
    // 实现技能逻辑
    return {
      success: true,
      output: '执行结果',
      data: { /* 返回数据 */ }
    };
  }
}
```

## 安全特性详解

### 提示词注入防护

SecurityFilter 内置多种注入检测模式：
- 忽略指令检测 (`忽略之前的指令`)
- 越狱尝试检测 (`DAN`, `do anything now`)
- 角色扮演检测 (`你现在是一个`)
- 系统提示探测 (`系统提示：`)

### XSS 防护

检测和过滤：
- `<script>` 标签
- `javascript:` 协议
- `on*` 事件处理器
- `<iframe>`, `<object>` 等危险元素

### 命令注入防护

检测和阻止：
- Shell 元字符 (`;`, `|`, `` ` ``, `$`)
- 命令替换 (`$(...)`)
- 危险命令组合

### 敏感信息脱敏

自动识别并脱敏：
- 邮箱地址 → `[EMAIL_REDACTED]`
- 电话号码 → `[PHONE_REDACTED]`
- 身份证号 → `[ID_REDACTED]`
- API 密钥 → `[API_KEY_REDACTED]`

## 许可证

Apache-2.0 License

## 贡献

欢迎提交 Issue 和 Pull Request！

---

## 参考资料

- [OpenClaw](https://github.com/openclaw) - 本地优先 AI助手架构
- [IronClaw](https://github.com/nearai/ironclaw) - NEAR AI 的安全增强版本

---

🤖 Generated with ZhiLinClaw
