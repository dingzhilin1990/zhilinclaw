/**
 * 决策层 Agent - 策略师
 * 
 * 核心职责：
 * - 需求分析
 * - 整体执行策略制定
 * - 资源分配
 * 
 * 触发关键词：策略、规划、方案、分配
 */

import { AgentBase, AgentConfig, AgentContext, AgentResult, AgentRole, AgentLayer } from './AgentBase';

const strategistConfig: AgentConfig = {
  name: '策略师',
  role: AgentRole.STRATEGIST,
  layer: AgentLayer.DECISION,
  triggerKeywords: ['策略', '规划', '方案', '分配', '计划', 'strategy', 'plan'],
  maxIterations: 5,
  enableLogging: true,
  systemPrompt: `你是一位资深的策略规划专家。你的职责是：
1. 深入分析用户需求，识别核心目标和关键约束
2. 制定清晰的执行策略，划分合理的阶段
3. 评估潜在风险并提供应对措施
4. 分配适当的资源确保项目成功

请以结构化的方式输出你的分析和建议。`
};

export interface ExecutionStrategy {
  objective: string;
  phases: StrategyPhase[];
  resourceAllocation: Record<string, any>;
  riskAssessment: RiskItem[];
  successCriteria: string[];
}

export interface StrategyPhase {
  name: string;
  objective: string;
  keyTasks: string[];
  deliverables: string[];
  estimatedTime?: number;
}

export interface RiskItem {
  description: string;
  level: 'low' | 'medium' | 'high' | 'critical';
  mitigation: string;
}

export class Strategist extends AgentBase {
  constructor() {
    super(strategistConfig);
  }

  async process(input: string, context?: AgentContext): Promise<AgentResult> {
    const startTime = Date.now();
    
    await this.initialize(context || {
      taskId: `task_${Date.now()}`,
      taskDescription: input
    });

    try {
      this.log('开始分析需求并制定策略...');

      const analysisPrompt = `请分析以下需求并制定执行策略：

需求描述：
${input}

请按以下格式输出：
1. 需求分析（核心需求、约束条件、利益相关者）
2. 执行策略（阶段划分、关键任务、预期产出）
3. 风险评估（潜在风险、风险等级、应对措施）
4. 成功标准`;

      const aiResponse = await this.callAI(analysisPrompt);
      
      const requirementAnalysis = this.parseRequirementAnalysis(aiResponse, input);
      const strategy = this.parseStrategy(aiResponse);
      const resourcePlan = this.generateResourcePlan(strategy);

      const executionTime = Date.now() - startTime;

      return {
        success: true,
        output: `策略规划完成：${strategy.objective}`,
        documents: {
          requirementAnalysis,
          strategy,
          resourcePlan,
          aiAnalysis: aiResponse
        },
        executionTime
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      return {
        success: false,
        output: '策略规划失败',
        error: errorMessage,
        executionTime: Date.now() - startTime
      };
    }
  }

  private parseRequirementAnalysis(aiResponse: string, originalInput: string): Record<string, any> {
    return {
      originalInput,
      coreNeeds: this.extractList(aiResponse, '核心需求') || ['需求分析中'],
      constraints: this.extractList(aiResponse, '约束条件') || ['待确定'],
      stakeholders: this.extractList(aiResponse, '利益相关者') || ['用户', '开发团队'],
      aiAnalysis: aiResponse
    };
  }

  private parseStrategy(aiResponse: string): ExecutionStrategy {
    return {
      objective: '实现用户需求',
      phases: [
        {
          name: '准备阶段',
          objective: '完成前期调研和资源准备',
          keyTasks: ['需求确认', '技术选型', '团队组建'],
          deliverables: ['需求文档', '技术方案', '团队分工表'],
          estimatedTime: 2
        },
        {
          name: '执行阶段',
          objective: '完成核心功能开发',
          keyTasks: ['架构设计', '编码实现', '单元测试'],
          deliverables: ['源代码', '测试报告', 'API 文档'],
          estimatedTime: 5
        },
        {
          name: '交付阶段',
          objective: '完成验收和部署',
          keyTasks: ['集成测试', '用户验收', '上线部署'],
          deliverables: ['验收报告', '部署文档', '运维手册'],
          estimatedTime: 1
        }
      ],
      resourceAllocation: {},
      riskAssessment: this.extractRisks(aiResponse),
      successCriteria: ['功能完整', '性能达标', '用户满意']
    };
  }

  private generateResourcePlan(strategy: ExecutionStrategy): Record<string, any> {
    return {
      humanResources: {
        decision: ['策略师', '研究员', '顾问'],
        execution: ['工程师', '协调官', '记录官'],
        supervision: ['质检员', '修复师']
      },
      timeResource: {
        total: strategy.phases.reduce((sum, phase) => sum + (phase.estimatedTime || 0), 0),
        unit: 'days'
      },
      technicalResources: ['开发环境', '测试环境', '部署平台']
    };
  }

  private extractList(text: string, keyword: string): string[] | null {
    const regex = new RegExp(`${keyword}[：:][\\s\\S]*?(?=\\n\\d|\\n[A-Z]|$)`, 'i');
    const match = text.match(regex);
    if (match) {
      const items = match[0].split('\n')
        .filter(line => line.trim().startsWith('-') || line.trim().match(/^\d/))
        .map(line => line.replace(/^[-\d\.\s]+/, '').trim())
        .filter(line => line.length > 0);
      return items.length > 0 ? items : null;
    }
    return null;
  }

  private extractRisks(text: string): RiskItem[] {
    const risks: RiskItem[] = [];
    const riskMatch = text.match(/风险[评估]*[：:][\s\S]*?(?=\n\d|\n[A-Z]|$)/i);
    if (riskMatch) {
      risks.push({
        description: '项目执行风险',
        level: 'medium',
        mitigation: '制定详细的应急预案'
      });
    }
    return risks;
  }

  public getStrategyDocument(): string {
    return JSON.stringify({
      agent: this.config.name,
      status: 'active',
      lastTask: this.context?.taskDescription
    }, null, 2);
  }
}
