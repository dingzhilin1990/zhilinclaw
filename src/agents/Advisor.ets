/**
 * 决策层 Agent - 顾问
 * 
 * 核心职责：
 * - 专业领域建议
 * - 方案合理性评审
 * - 风险预判
 * 
 * 触发关键词：咨询、建议、评审、风险
 */

import { AgentBase, AgentConfig, AgentContext, AgentResult, AgentRole, AgentLayer } from './AgentBase';

const advisorConfig: AgentConfig = {
  name: '顾问',
  role: AgentRole.ADVISOR,
  layer: AgentLayer.DECISION,
  triggerKeywords: ['咨询', '建议', '评审', '风险', '评估', 'advisor', 'review'],
  maxIterations: 3,
  enableLogging: true
};

/**
 * 评审意见接口
 */
export interface ReviewOpinion {
  /** 方案名称 */
  proposalName: string;
  /** 总体评价 */
  overallRating: 'excellent' | 'good' | 'fair' | 'poor';
  /** 优点列表 */
  strengths: string[];
  /** 缺点列表 */
  weaknesses: string[];
  /** 风险点 */
  risks: RiskAssessment[];
  /** 改进建议 */
  recommendations: string[];
  /** 是否通过评审 */
  approved: boolean;
}

/**
 * 风险评估接口
 */
export interface RiskAssessment {
  /** 风险描述 */
  description: string;
  /** 发生概率 */
  probability: 'low' | 'medium' | 'high';
  /** 影响程度 */
  impact: 'low' | 'medium' | 'high' | 'critical';
  /** 风险等级 */
  riskLevel: number; // 1-5
  /** 应对措施 */
  mitigation: string;
}

/**
 * 顾问类
 */
export class Advisor extends AgentBase {
  constructor() {
    super(advisorConfig);
  }

  async process(input: string, context?: AgentContext): Promise<AgentResult> {
    const startTime = Date.now();
    
    await this.initialize(context || {
      taskId: `task_${Date.now()}`,
      taskDescription: input
    });

    try {
      this.log('开始评审方案...');

      // 1. 分析方案
      const analysis = await this.analyzeProposal(input);
      
      // 2. 识别风险
      const risks = await this.identifyRisks(analysis);
      
      // 3. 生成评审意见
      const opinion = await this.generateReview(analysis, risks);

      return {
        success: true,
        output: `评审完成：${opinion.overallRating}`,
        documents: {
          reviewOpinion: opinion
        },
        executionTime: Date.now() - startTime
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      return {
        success: false,
        output: '评审失败',
        error: errorMessage,
        executionTime: Date.now() - startTime
      };
    }
  }

  private async analyzeProposal(proposal: string): Promise<Record<string, any>> {
    this.log('分析方案内容...');
    
    return {
      originalProposal: proposal,
      objectives: this.extractObjectives(proposal),
      methodology: this.extractMethodology(proposal),
      resources: this.estimateResources(proposal)
    };
  }

  private async identifyRisks(analysis: Record<string, any>): Promise<RiskAssessment[]> {
    this.log('识别潜在风险...');
    
    return [
      {
        description: '技术风险',
        probability: 'medium',
        impact: 'high',
        riskLevel: 4,
        mitigation: '提前进行技术预研'
      },
      {
        description: '进度风险',
        probability: 'medium',
        impact: 'medium',
        riskLevel: 3,
        mitigation: '设置缓冲时间'
      }
    ];
  }

  private async generateReview(
    analysis: Record<string, any>,
    risks: RiskAssessment[]
  ): Promise<ReviewOpinion> {
    this.log('生成评审意见...');
    
    const avgRiskLevel = risks.reduce((sum, r) => sum + r.riskLevel, 0) / risks.length;
    
    return {
      proposalName: '方案评审',
      overallRating: avgRiskLevel < 3 ? 'good' : 'fair',
      strengths: [
        '方案结构清晰',
        '目标明确',
        '方法论合理'
      ],
      weaknesses: [
        '部分细节待完善',
        '资源估算偏乐观'
      ],
      risks: risks,
      recommendations: [
        '建议增加风险评估章节',
        '细化实施步骤',
        '预留充足的测试时间'
      ],
      approved: avgRiskLevel < 4
    };
  }

  /**
   * 提取目标
   */
  private extractObjectives(proposal: string): string[] {
    // 实际项目中应使用 NLP 提取
    return ['目标 1', '目标 2'];
  }

  /**
   * 提取方法论
   */
  private extractMethodology(proposal: string): string {
    return '描述方法论';
  }

  /**
   * 估算资源
   */
  private estimateResources(proposal: string): Record<string, any> {
    return {
      time: '预计时间',
      human: '所需人力',
      technical: '技术资源'
    };
  }

  /**
   * 快速咨询（轻量级建议）
   */
  public async quickConsult(question: string): Promise<string[]> {
    this.log(`快速咨询：${question}`);
    
    return ['建议 1', '建议 2', '建议 3'];
  }

  /**
   * 检查合规性
   */
  public async checkCompliance(proposal: any): Promise<boolean> {
    this.log('检查合规性...');
    
    // 实际项目中应检查各项标准
    return true;
  }
}
