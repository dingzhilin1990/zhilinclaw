# 汉武帝 AI Agent 架构文档

---
name: hanwudi-arch-zhilinclaw  
displayName: Hanwudi AI Agent Architecture for ZhiLinClaw  
description: 基于 MetaGPT SOP 方法论的 AI Agent 团队协作架构，实现「决策 - 执行 - 监督」三层设计  
version: 1.0.0  
type: architecture  
tags: ai, agent, persona, team, metagpt, workflow, hanwudi, zhilinclaw  
---

## 架构概述

本架构集成于 **ZhiLinClaw** 项目，基于「通用版汉武帝 AI Agent 架构」核心思想实现，保留「决策 - 执行 - 监督」三层架构设计，核心逻辑为 **Code = SOP(Team)**，将标准化作业流程（SOP）具象化为 Agent 团队的协作规则。

## 架构分层与核心角色

### 1. 决策层（核心规划与知识支撑）

| 角色 | 类名 | 核心职责 | 触发关键词 |
|------|------|----------|------------|
| **策略师** | `Strategist` | 需求分析、整体执行策略制定、资源分配 | 策略、规划、方案、分配 |
| **研究员** | `Researcher` | 行业知识检索、最佳实践调研、技术可行性分析 | 研究、学习、调研、验证 |
| **顾问** | `Advisor` | 专业领域建议、方案合理性评审、风险预判 | 咨询、建议、评审、风险 |

### 2. 执行层（落地实施与过程记录）

| 角色 | 类名 | 核心职责 | 触发关键词 |
|------|------|----------|------------|
| **工程师** | `Engineer` | 代码编写、功能实现、工具开发、任务落地 | 编码、构建、开发、实现 |
| **协调官** | `Coordinator` | 任务拆解、进度管控、角色协同、资源调度 | 任务、管理、协调、调度 |
| **记录官** | `Recorder` | 过程文档撰写、成果归档、操作日志记录 | 文档、记录、归档、日志 |

### 3. 监督层（质量保障与问题修复）

| 角色 | 类名 | 核心职责 | 触发关键词 |
|------|------|----------|------------|
| **质检员** | `Inspector` | 成果质量审核、标准符合性校验、漏洞检测 | 审核、检查、质检、验证 |
| **修复师** | `Fixer` | 问题定位、漏洞修复、成果优化、异常处理 | 修复、调试、优化、排障 |

## 标准协作流程（SOP）

```
┌─────────────────────────────────────────────────────────┐
│ 1. 需求输入                                              │
│    → 研究员检索相关知识与最佳实践                        │
│    → 输出《背景调研报告》                                │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ 2. 策略规划                                              │
│    → 策略师结合调研结果制定《执行策略与任务分工方案》    │
│    → 顾问对方案进行评审                                  │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ 3. 任务执行                                              │
│    → 协调官拆解具体任务并分配至对应角色                  │
│    → 工程师完成核心成果落地                              │
│    → 记录官同步记录执行过程                              │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ 4. 质量校验                                              │
│    → 质检员对工程师输出的成果进行全面审核                │
│    → 输出《质量校验报告》                                │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ 5. 问题闭环                                              │
│    → 修复师根据校验报告修复问题                          │
│    → 质检员复核直至问题闭环                              │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ 6. 成果归档                                              │
│    → 记录官整理所有过程文档与最终成果                    │
│    → 形成可追溯的完整链路                                │
└─────────────────────────────────────────────────────────┘
```

## 文件结构

```
src/agents/
├── index.ets              # 模块导出
├── AgentBase.ets          # Agent 基类定义
├── Strategist.ets         # 策略师实现
├── Researcher.ets         # 研究员实现
├── Advisor.ets            # 顾问实现
├── Engineer.ets           # 工程师实现
├── Coordinator.ets        # 协调官实现
├── Recorder.ets           # 记录官实现
├── Inspector.ets          # 质检员实现
├── Fixer.ets              # 修复师实现
└── HanwudiWorkflow.ets    # SOP 工作流引擎
```

## 使用方式

### 方式 1: 使用完整工作流引擎

```typescript
import { HanwudiWorkflow } from './src/agents';

// 创建工作流实例
const workflow = new HanwudiWorkflow({
  enableResearcher: true,        // 启用研究员
  enableAdvisorReview: true,     // 启用顾问评审
  enableFullDocumentation: true, // 启用完整文档
  qualityThreshold: 75,          // 质量阈值 75 分
  maxIterations: 3,              // 最多迭代 3 次
  enableLogging: true            // 启用日志
});

// 定义需求
const requirement = '开发一个天气查询应用，支持全国主要城市实时天气查询';

// 执行完整工作流
const result = await workflow.execute(requirement);

console.log(`✅ 成功：${result.success}`);
console.log(`📈 质量评分：${result.qualityReport?.overallScore}`);
```

### 方式 2: 单独使用特定 Agent

```typescript
import { Strategist, Researcher, Engineer } from './src/agents';

// 策略师 - 制定计划
const strategist = new Strategist();
const strategy = await strategist.process('如何开发一个电商网站？');

// 研究员 - 行业调研
const researcher = new Researcher();
const research = await researcher.process('AI Agent 技术的发展趋势');

// 工程师 - 编写代码
const engineer = new Engineer();
const code = await engineer.process('实现一个快速排序算法');

// 质检员 - 代码审查
const inspector = new Inspector();
const review = await inspector.process(JSON.stringify(code.documents));
```

### 方式 3: 场景化配置

#### 小型代码开发
```typescript
const workflow = new HanwudiWorkflow({
  enableResearcher: false,       // 跳过调研
  enableAdvisorReview: false,    // 跳过评审
  enableFullDocumentation: false,// 简化文档
  qualityThreshold: 60,          // 降低阈值
  maxIterations: 1               // 单次执行
});
```

#### 行业调研报告
```typescript
// 只需激活：研究员 + 顾问 + 记录官
const researcher = new Researcher();
const advisor = new Advisor();
const recorder = new Recorder();

// 调研 → 评审 → 归档
```

## 角色灵活启停规则

### 按场景激活角色

| 场景类型 | 核心激活角色 | 流程简化说明 |
|----------|--------------|--------------|
| 小型代码开发 | 策略师 + 工程师 + 质检员 | 跳过顾问评审，简化文档记录 |
| 行业调研报告撰写 | 研究员 + 顾问 + 记录官 | 无需工程师参与 |
| 复杂项目落地 | 全角色 | 按标准流程执行 |
| 紧急故障修复 | 修复师 + 质检员 | 跳过规划和文档，直接修复 |
| 技术方案评审 | 策略师 + 顾问 + 质检员 | 聚焦方案可行性分析 |

### 触发关键词扩展

各角色的触发关键词可根据具体场景扩展：

```typescript
// 工程师在数据分析场景可扩展
const dataEngineer = new Engineer();
dataEngineer.config.triggerKeywords.push('分析', '建模', '数据挖掘');

// 研究员在医疗场景可扩展
const medicalResearcher = new Researcher();
medicalResearcher.config.triggerKeywords.push('临床', '医学', '药物');
```

## 与其他模块集成

### 与安全模块集成

```typescript
import { SecurityFilter, SandboxedExecutor } from './src/security';
import { Engineer } from './src/agents';

const securityFilter = new SecurityFilter();
const sandbox = new SandboxedExecutor();
const engineer = new Engineer();

// 工程师生成的代码先经过安全过滤
const code = await engineer.process('编写工具函数');
const safetyCheck = await securityFilter.checkInput(code.output);

if (safetyCheck.passed) {
  // 在沙箱中执行
  const result = await sandbox.execute(code.output);
}
```

### 与插件模块集成

```typescript
import { PluginManager } from './src/plugins';
import { HanwudiWorkflow } from './src/agents';

const pluginManager = new PluginManager();
const workflow = new HanwudiWorkflow();

// 将 Agent 作为插件注册
await pluginManager.register({
  name: 'hanwudi_agent_team',
  onEnable: async () => {
    console.log('汉武帝 Agent 团队已启用');
  }
});
```

## 示例代码

完整示例请查看：
- [`examples/HanwudiDemo.ets`](../examples/HanwudiDemo.ets) - 5 个完整使用示例

## 设计原则

### 1. Code = SOP(Team)
将标准化作业流程具象化为 Agent 团队的协作规则，每个角色都有明确的职责和触发条件。

### 2. 灵活配置
支持按需激活角色、自定义流程节点、调整质量阈值，适配不同复杂度的任务。

### 3. 可追溯性
通过记录官全程记录、质检员质量报告、修复师修复记录，形成完整的可追溯链路。

### 4. 质量优先
内置多层质量检查机制，未达标的成果会自动触发修复流程，确保最终交付质量。

## 参考资料

- [MetaGPT 官方文档](https://github.com/geekan/MetaGPT)
- [通用版汉武帝 AI Agent 架构文档](./HANWUDI_ARCHITECTURE.md)
- [标准化作业流程（SOP）通用设计指南]
- [多 Agent协作框架技术白皮书]

---

🤖 Generated with ZhiLinClaw + Hanwudi Architecture
