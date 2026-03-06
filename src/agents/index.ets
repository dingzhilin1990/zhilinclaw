/**
 * Agent 团队模块 - 汉武帝架构实现
 * 
 * 基于「通用版汉武帝 AI Agent 架构」设计
 * Code = SOP(Team) - 将标准化作业流程具象化为 Agent 团队协作规则
 * 
 * 三层架构：
 * 1. 决策层 - 策略师、研究员、顾问
 * 2. 执行层 - 工程师、协调官、记录官
 * 3. 监督层 - 质检员、修复师
 */

export { AgentRole, AgentType, AgentLayer } from './AgentBase';
export type { AgentConfig, AgentContext, AgentMessage } from './AgentBase';

export { Strategist } from './Strategist';
export { Researcher } from './Researcher';
export { Advisor } from './Advisor';
export { Engineer } from './Engineer';
export { Coordinator } from './Coordinator';
export { Recorder } from './Recorder';
export { Inspector } from './Inspector';
export { Fixer } from './Fixer';

export { HanwudiWorkflow } from './HanwudiWorkflow';
export type { WorkflowConfig, TaskResult } from './HanwudiWorkflow';
