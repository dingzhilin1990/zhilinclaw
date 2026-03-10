/**
 * 决策层 Agent - 研究员
 * 
 * 核心职责：
 * - 行业知识检索
 * - 最佳实践调研
 * - 技术可行性分析
 * 
 * 触发关键词：研究、学习、调研、验证
 */

import { AgentBase, AgentConfig, AgentContext, AgentResult, AgentRole, AgentLayer } from './AgentBase';

const researcherConfig: AgentConfig = {
  name: '研究员',
  role: AgentRole.RESEARCHER,
  layer: AgentLayer.DECISION,
  triggerKeywords: ['研究', '学习', '调研', '验证', '搜索', 'research', 'study'],
  maxIterations: 10,
  enableLogging: true,
  systemPrompt: `你是一位专业的研究员。你的职责是：
1. 深入调研指定主题，收集相关信息
2. 分析行业最佳实践和技术趋势
3. 评估技术方案的可行性
4. 提供有数据支撑的研究报告

请以客观、专业的方式输出研究结果。`
};

export interface ResearchReport {
  title: string;
  executiveSummary: string;
  background: BackgroundInfo;
  bestPractices: PracticeItem[];
  technicalAnalysis: TechnicalAnalysis;
  feasibilityConclusion: FeasibilityResult;
  references: ReferenceItem[];
}

interface BackgroundInfo {
  industryStatus: string;
  marketTrends: string[];
  keyPlayers: string[];
}

interface PracticeItem {
  name: string;
  description: string;
  applicability: 'high' | 'medium' | 'low';
  pros: string[];
  cons: string[];
}

interface TechnicalAnalysis {
  recommendedTech: string[];
  alternatives: string[];
  complexity: 'low' | 'medium' | 'high';
  learningCurve: string;
}

interface FeasibilityResult {
  isFeasible: boolean;
  confidence: number;
  mainChallenges: string[];
  recommendations: string[];
}

interface ReferenceItem {
  title: string;
  source: string;
  url?: string;
  relevance: number;
}

export class Researcher extends AgentBase {
  constructor() {
    super(researcherConfig);
  }

  async process(input: string, context?: AgentContext): Promise<AgentResult> {
    const startTime = Date.now();
    
    await this.initialize(context || {
      taskId: `task_${Date.now()}`,
      taskDescription: input
    });

    try {
      this.log(`开始调研：${input}`);

      const researchPrompt = `请对以下主题进行深入研究：

研究主题：${input}

请按以下结构输出调研报告：
1. 执行摘要
2. 行业背景（现状、趋势、主要参与者）
3. 最佳实践（至少3个案例，包含优缺点分析）
4. 技术分析（推荐技术栈、替代方案、复杂度评估）
5. 可行性结论（可行性评分、主要挑战、建议）
6. 参考资料`;

      const aiResponse = await this.callAI(researchPrompt);
      
      const report = this.parseResearchReport(input, aiResponse);

      return {
        success: true,
        output: `调研完成：${report.title}`,
        documents: {
          researchReport: report,
          aiAnalysis: aiResponse
        },
        executionTime: Date.now() - startTime
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      return {
        success: false,
        output: '调研失败',
        error: errorMessage,
        executionTime: Date.now() - startTime
      };
    }
  }

  private parseResearchReport(topic: string, aiResponse: string): ResearchReport {
    return {
      title: `${topic} - 调研报告`,
      executiveSummary: this.extractSection(aiResponse, '执行摘要') || '基于 AI 分析的调研摘要',
      background: {
        industryStatus: '行业持续发展',
        marketTrends: ['数字化转型', '智能化升级', '云原生架构'],
        keyPlayers: ['主要厂商 A', '主要厂商 B', '主要厂商 C']
      },
      bestPractices: this.extractBestPractices(aiResponse),
      technicalAnalysis: {
        recommendedTech: ['推荐技术 1', '推荐技术 2'],
        alternatives: ['替代方案 1'],
        complexity: 'medium',
        learningCurve: '中等学习曲线，预计 2 周上手'
      },
      feasibilityConclusion: {
        isFeasible: true,
        confidence: 0.85,
        mainChallenges: ['技术难点 1', '资源限制'],
        recommendations: ['建议 1', '建议 2']
      },
      references: [
        {
          title: '参考资料 1',
          source: '技术文档',
          relevance: 0.9
        }
      ]
    };
  }

  private extractSection(text: string, sectionName: string): string | null {
    const regex = new RegExp(`${sectionName}[：:][\\s\\S]*?(?=\\n\\d|\\n[A-Z]|$)`, 'i');
    const match = text.match(regex);
    return match ? match[0].replace(new RegExp(`${sectionName}[：:]`, 'i'), '').trim() : null;
  }

  private extractBestPractices(text: string): PracticeItem[] {
    return [
      {
        name: '最佳实践 1',
        description: '基于 AI 分析的最佳实践',
        applicability: 'high',
        pros: ['优势 1', '优势 2'],
        cons: ['劣势 1']
      }
    ];
  }

  public async quickSearch(query: string): Promise<string[]> {
    this.log(`快速检索：${query}`);
    const response = await this.callAI(`请列出关于"${query}"的3个关键点：`);
    return response.split('\n').filter(line => line.trim().length > 0).slice(0, 3);
  }

  public async validateTechnicalSolution(solution: string): Promise<boolean> {
    this.log(`验证技术方案：${solution}`);
    const response = await this.callAI(`请评估以下技术方案的可行性（回答"可行"或"不可行"）：\n${solution}`);
    return response.includes('可行');
  }
}
