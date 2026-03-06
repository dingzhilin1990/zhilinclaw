# ZhiLinClaw 快速开始指南

> 5 分钟快速上手 ZhiLinClaw AI Agent 框架

---

## 📦 安装步骤

### 1. 环境准备

确保已安装以下工具：
- ✅ OpenHarmony SDK 5.0+
- ✅ DevEco Studio（推荐）或 VS Code + ArkTS 插件
- ✅ Node.js 16+

### 2. 克隆项目

```bash
git clone https://github.com/zhilinclaw/zhilinclaw.git
cd zhilinclaw
```

### 3. 安装依赖

```bash
npm install
```

---

## 🚀 快速体验

### 方式 1: 运行完整示例（推荐新手）

```bash
# 运行汉武帝架构演示 - 展示完整的 AI Agent 团队协作
npm run demo:hanwudi
```

**你将看到：**
- 📋 策略师制定项目计划
- 🔍 研究员进行背景调研  
- 💻 工程师编写代码
- 🔍 质检员进行质量检查
- 📝 记录官整理文档

### 方式 2: 运行安全功能演示

```bash
# 运行 IronClaw 安全功能演示
npm run demo:security
```

**你将看到：**
- 🔒 加密凭证管理
- 🛡️ 多层安全过滤
- 📦 WASM 沙箱隔离
- 🔐 OAuth 认证流程

### 方式 3: 运行主程序

```bash
# 运行核心系统演示
npm run start
```

---

## 💻 代码实战

### 场景 1: 开发一个小工具（3 行代码）

```typescript
import { HanwudiWorkflow } from './src/agents';

const workflow = new HanwudiWorkflow();
const result = await workflow.execute('编写一个日期格式化工具函数');

console.log(`✅ 完成！质量评分：${result.qualityReport?.overallScore}`);
```

### 场景 2: 行业调研报告（5 行代码）

```typescript
import { Researcher, Advisor, Recorder } from './src/agents';

const researcher = new Researcher();
const report = await researcher.process('2026 年 AI 发展趋势');

console.log('📚 调研完成:', report.documents.researchReport.title);
```

### 场景 3: 代码开发 + 审查（8 行代码）

```typescript
import { Engineer, Inspector } from './src/agents';

const engineer = new Engineer();
const code = await engineer.process('实现快速排序算法');

const inspector = new Inspector();
const review = await inspector.process(JSON.stringify(code.documents));

console.log(`📊 代码质量：${review.documents.qualityReport.overallScore}分`);
```

---

## 🎯 选择适合你的工作流

### 简单任务（< 1 小时）

```typescript
const workflow = new HanwudiWorkflow({
  enableResearcher: false,       // 跳过调研
  enableAdvisorReview: false,    // 跳过评审
  qualityThreshold: 60,          // 基础质量要求
  maxIterations: 1               // 单次执行
});
```

**适用场景：**
- 编写工具函数
- 代码片段生成
- 简单问题修复

### 中等任务（1-5 小时）

```typescript
const workflow = new HanwudiWorkflow({
  enableResearcher: true,        // 启用调研
  enableAdvisorReview: false,    // 跳过评审
  qualityThreshold: 75,          // 良好质量要求
  maxIterations: 2               // 允许迭代
});
```

**适用场景：**
- 小型模块开发
- 功能优化
- 技术文档撰写

### 复杂任务（> 5 小时）

```typescript
const workflow = new HanwudiWorkflow({
  enableResearcher: true,        // 启用调研
  enableAdvisorReview: true,     // 启用评审
  enableFullDocumentation: true, // 完整文档
  qualityThreshold: 85,          // 高质量要求
  maxIterations: 3               // 多次迭代
});
```

**适用场景：**
- 完整项目开发
- 系统架构设计
- 企业级解决方案

---

## 📚 下一步学习

### 深入理解

1. **阅读架构文档**
   - [`ARCHITECTURE.md`](ARCHITECTURE.md) - 完整架构说明
   - [`docs/HANWUDI_ARCHITECTURE.md`](docs/HANWUDI_ARCHITECTURE.md) - 汉武帝架构详解

2. **查看示例代码**
   - [`examples/main.ets`](examples/main.ets) - 主入口示例
   - [`examples/SecurityDemo.ets`](examples/SecurityDemo.ets) - 安全功能示例
   - [`examples/HanwudiDemo.ets`](examples/HanwudiDemo.ets) - Agent 团队示例

3. **学习最佳实践**
   - 选择合适的流程复杂度
   - 设置合理的质量阈值
   - 正确使用安全功能

### 进阶使用

#### 自定义 Agent 角色

```typescript
import { AgentBase, AgentConfig, AgentRole, AgentLayer } from './src/agents';

class CustomAgent extends AgentBase {
  constructor() {
    super({
      name: '我的自定义 Agent',
      role: AgentRole.ENGINEER,
      layer: AgentLayer.EXECUTION,
      triggerKeywords: ['自定义', '特殊'],
      enableLogging: true
    });
  }

  async process(input: string) {
    // 实现你的逻辑
    return { success: true, output: '完成' };
  }
}
```

#### 集成到现有项目

```typescript
// 1. 作为插件注册
import { PluginManager } from './src/plugins';
import { HanwudiWorkflow } from './src/agents';

const pluginManager = new PluginManager();
await pluginManager.register({
  name: 'hanwudi_team',
  onEnable: () => console.log('Agent 团队已启用')
});

// 2. 与安全模块集成
import { SecurityFilter } from './src/security';

const filter = new SecurityFilter();
const safetyCheck = await filter.checkInput(userInput);
```

---

## ❓ 常见问题

### Q1: 如何选择合适的 Agent？

**A:** 根据任务类型选择：
- 📋 **规划类** → 策略师 (Strategist)
- 🔍 **调研类** → 研究员 (Researcher)
- 💻 **开发类** → 工程师 (Engineer)
- 📝 **文档类** → 记录官 (Recorder)
- 🔍 **质检类** → 质检员 (Inspector)
- 🔧 **修复类** → 修复师 (Fixer)

### Q2: 如何提高输出质量？

**A:** 三种方法：
1. 提高质量阈值：`qualityThreshold: 85`
2. 增加迭代次数：`maxIterations: 3`
3. 启用顾问评审：`enableAdvisorReview: true`

### Q3: 如何保证安全性？

**A:** 必须启用的安全措施：
```typescript
const filter = new SecurityFilter({
  enablePromptInjectionDetection: true, // 防注入
  enableXSSDetection: true,             // 防 XSS
  riskThreshold: RiskLevel.HIGH         // 高风险阻止
});
```

### Q4: 如何保存和加载文档？

**A:** 使用记录官：
```typescript
const recorder = new Recorder();

// 保存文档
await recorder.process('保存项目文档');

// 加载文档
const doc = recorder.getDocument('doc_id');

// 导出为 Markdown
const md = recorder.exportToMarkdown('doc_id');
```

---

## 🆘 获取帮助

### 遇到问题？

1. **查看文档**
   - [完整架构文档](ARCHITECTURE.md)
   - [README.md](README.md)
   - [项目总结](PROJECT_SUMMARY.md)

2. **运行测试**
   ```bash
   npm run test
   ```

3. **检查日志**
   ```typescript
   // 启用详细日志
   const workflow = new HanwudiWorkflow({
     enableLogging: true
   });
   ```

4. **提交 Issue**
   - GitHub: https://github.com/zhilinclaw/zhilinclaw/issues

---

## 🎉 开始你的第一个项目

现在你已经掌握了基础知识，开始构建你的第一个 AI Agent 项目吧！

```typescript
import { HanwudiWorkflow } from './src/agents';

const workflow = new HanwudiWorkflow();
const result = await workflow.execute('帮我创建一个个人博客网站');

console.log('🚀 项目启动成功!');
```

---

🤖 Happy Coding with ZhiLinClaw!
