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
  enableLogging: true,
  systemPrompt: `你是一位资深顾问专家。你的职责是：
1. 评估方案的合理性和可行性
2. 识别潜在风险并提供应对建议
3. 提供专业领域的改进意见
4. 确保方案符合最佳实践

请以客观、专业的角度进行评审。`
};

export interface ReviewOpinion {
  proposalName: string;
  overallRating: 'excellent' | 'good' | 'fair' | 'poor';
  strengths: string[];
  weaknesses: string[];
  risks: RiskAssessment[];
  recommendations: string[];
  approved: boolean;
}

export interface RiskAssessment {
  description: string;
  probability: 'low' | 'medium' | 'high';
  impact: 'low' | 'medium' | 'high' | 'critical';
  riskLevel: number;
  mitigation: string;
}

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

      const reviewPrompt = `请对以下方案进行专业评审：

方案内容：
${input}

请按以下结构输出评审意见：
1. 总体评价（优秀/良好/一般/较差）
2. 方案优点（至少3点）
3. 方案缺点（至少2点）
4. 风险评估（识别主要风险及应对措施）
5. 改进建议（具体可行的建议）
6. 是否推荐通过（是/否）`;

      const aiResponse = await this.callAI(reviewPrompt);
      
      const analysis = this.parseAnalysis(input, aiResponse);
      const risks = this.extractRisks(aiResponse);
      const opinion = this.generateOpinion(aiResponse, risks);

      return {
        success: true,
        output: `评审完成：${opinion.overallRating}`,
        documents: {
          reviewOpinion: opinion,
          analysis,
          aiReview: aiResponse
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

  private parseAnalysis(proposal: string, aiResponse: string): Record<string, any> {
    return {
      originalProposal: proposal,
      objectives: this.extractList(aiResponse, '目标') || ['待分析'],
      methodology: this.extractSection(aiResponse, '方法论') || '标准方法论',
      aiAnalysis: aiResponse
    };
  }

  private extractRisks(aiResponse: string): RiskAssessment[] {
    const risks: RiskAssessment[] = [];
    if (aiResponse.includes('风险')) {
      risks.push({
        description: '项目执行风险',
        probability: 'medium',
        impact: 'high',
        riskLevel: 4,
        mitigation: '提前进行风险评估和预案准备'
      });
    }
    return risks;
  }

  private generateOpinion(aiResponse: string, risks: RiskAssessment[]): ReviewOpinion {
    const rating = this.determineRating(aiResponse);
    
    return {
      proposalName: '方案评审',
      overallRating: rating,
      strengths: this.extractList(aiResponse, '优点') || ['方案结构清晰', '目标明确'],
      weaknesses: this.extractList(aiResponse, '缺点') || ['部分细节待完善'],
      risks: risks,
      recommendations: this.extractList(aiResponse, '建议') || ['建议增加风险评估', '细化实施步骤'],
      approved: rating !== 'poor'
    };
  }

  private determineRating(text: string): 'excellent' | 'good' | 'fair' | 'poor' {
    if (text.includes('优秀') || text.includes('excellent')) return 'excellent';
    if (text.includes('良好') || text.includes('good')) return 'good';
    if (text.includes('一般') || text.includes('fair')) return 'fair';
    return 'good';
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

  private extractSection(text: string, sectionName: string): string | null {
    const regex = new RegExp(`${sectionName}[：:][\\s\\S]*?(?=\\n\\d|\\n[A-Z]|$)`, 'i');
    const match = text.match(regex);
    return match ? match[0].replace(new RegExp(`${sectionName}[：:]`, 'i'), '').trim() : null;
  }

  public async quickConsult(question: string): Promise<string[]> {
    this.log(`快速咨询：${question}`);
    const response = await this.callAI(`请针对以下问题提供3条简短建议：\n${question}`);
    return response.split('\n').filter(line => line.trim().length > 0).slice(0, 3);
  }

  public async checkCompliance(proposal: any): Promise<boolean> {
    this.log('检查合规性...');
    const response = await this.callAI(`请检查以下方案是否符合最佳实践（回答"符合"或"不符合"）：\n${JSON.stringify(proposal)}`);
    return response.includes('符合');
  }
}
