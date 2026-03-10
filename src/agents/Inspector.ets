/**
 * 监督层 Agent - 质检员
 * 
 * 核心职责：
 * - 成果质量审核
 * - 标准符合性校验
 * - 漏洞检测
 * 
 * 触发关键词：审核、检查、质检、验证
 */

import { AgentBase, AgentConfig, AgentContext, AgentResult, AgentRole, AgentLayer } from './AgentBase';

const inspectorConfig: AgentConfig = {
  name: '质检员',
  role: AgentRole.INSPECTOR,
  layer: AgentLayer.SUPERVISION,
  triggerKeywords: ['审核', '检查', '质检', '验证', '测试', 'inspect', 'quality'],
  maxIterations: 10,
  enableLogging: true,
  systemPrompt: `你是一位专业的质量审核专家。你的职责是：
1. 全面审核交付成果的质量
2. 检查是否符合标准和规范
3. 识别潜在问题和风险
4. 提供改进建议

请输出详细的审核报告。`
};

export enum IssueSeverity {
  CRITICAL = 'critical',
  MAJOR = 'major',
  MINOR = 'minor',
  COSMETIC = 'cosmetic'
}

export interface QualityIssue {
  id: string;
  description: string;
  type: string;
  severity: IssueSeverity;
  location?: string;
  reproductionSteps?: string[];
  expectedResult?: string;
  actualResult?: string;
  suggestedFix?: string;
}

export interface QualityReport {
  reportId: string;
  targetName: string;
  inspectedAt: number;
  overallScore: number;
  passed: boolean;
  issues: QualityIssue[];
  issueSummary: {
    critical: number;
    major: number;
    minor: number;
    cosmetic: number;
  };
  recommendations: string[];
  checklist: ChecklistItem[];
}

interface ChecklistItem {
  item: string;
  passed: boolean;
  notes?: string;
}

export class Inspector extends AgentBase {
  private issueCounter: number = 0;

  constructor() {
    super(inspectorConfig);
  }

  async process(input: string, context?: AgentContext): Promise<AgentResult> {
    const startTime = Date.now();
    
    await this.initialize(context || {
      taskId: `task_${Date.now()}`,
      taskDescription: `质检任务：${input}`
    });

    try {
      this.log('开始质量检查...');

      const inspectPrompt = `请对以下内容进行质量审核：

审核对象：
${input}

请按以下结构输出审核报告：
1. 总体评分（0-100分）
2. 发现的问题（按严重程度分类）
   - 严重问题：影响核心功能
   - 主要问题：影响用户体验
   - 次要问题：建议改进
   - 外观问题：可选改进
3. 改进建议
4. 是否通过审核（通过/不通过）`;

      const aiResponse = await this.callAI(inspectPrompt);
      
      const criteria = this.defineCriteria(input);
      const findings = this.extractIssues(aiResponse);
      const report = this.generateReport(input, findings, aiResponse);
      const passed = this.evaluatePassFail(report);

      return {
        success: true,
        output: `质量检查完成，评分：${report.overallScore}/100，${passed ? '通过' : '未通过'}`,
        documents: {
          qualityReport: report,
          aiInspection: aiResponse
        },
        executionTime: Date.now() - startTime
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      return {
        success: false,
        output: '质量检查失败',
        error: errorMessage,
        executionTime: Date.now() - startTime
      };
    }
  }

  private defineCriteria(target: string): string[] {
    return [
      '功能性 - 功能是否完整实现',
      '可靠性 - 是否稳定可靠',
      '性能 - 性能是否达标',
      '可维护性 - 代码是否易读易维护',
      '安全性 - 是否存在安全隐患'
    ];
  }

  private extractIssues(aiResponse: string): QualityIssue[] {
    const issues: QualityIssue[] = [];
    
    if (aiResponse.includes('严重') || aiResponse.includes('critical')) {
      issues.push({
        id: `issue_${++this.issueCounter}`,
        description: '发现严重问题',
        type: 'critical',
        severity: IssueSeverity.CRITICAL,
        suggestedFix: '需要立即修复'
      });
    }
    
    if (aiResponse.includes('主要') || aiResponse.includes('major')) {
      issues.push({
        id: `issue_${++this.issueCounter}`,
        description: '发现主要问题',
        type: 'major',
        severity: IssueSeverity.MAJOR,
        suggestedFix: '建议尽快修复'
      });
    }

    if (issues.length === 0) {
      issues.push({
        id: `issue_${++this.issueCounter}`,
        description: '整体质量良好',
        type: 'info',
        severity: IssueSeverity.MINOR,
        suggestedFix: '继续保持'
      });
    }

    return issues;
  }

  private generateReport(
    target: string,
    issues: QualityIssue[],
    aiResponse: string
  ): QualityReport {
    const summary = {
      critical: issues.filter(i => i.severity === IssueSeverity.CRITICAL).length,
      major: issues.filter(i => i.severity === IssueSeverity.MAJOR).length,
      minor: issues.filter(i => i.severity === IssueSeverity.MINOR).length,
      cosmetic: issues.filter(i => i.severity === IssueSeverity.COSMETIC).length
    };

    const score = this.calculateScore(issues, aiResponse);
    const checklist = this.generateChecklist(aiResponse);

    return {
      reportId: `report_${Date.now()}`,
      targetName: target,
      inspectedAt: Date.now(),
      overallScore: score,
      passed: score >= 60 && summary.critical === 0,
      issues,
      issueSummary: summary,
      recommendations: this.generateRecommendations(issues, aiResponse),
      checklist
    };
  }

  private calculateScore(issues: QualityIssue[], aiResponse: string): number {
    let score = 100;
    
    const scoreMatch = aiResponse.match(/(\d+)\s*分/);
    if (scoreMatch) {
      return parseInt(scoreMatch[1]);
    }
    
    issues.forEach(issue => {
      switch (issue.severity) {
        case IssueSeverity.CRITICAL:
          score -= 30;
          break;
        case IssueSeverity.MAJOR:
          score -= 15;
          break;
        case IssueSeverity.MINOR:
          score -= 5;
          break;
        case IssueSeverity.COSMETIC:
          score -= 1;
          break;
      }
    });

    return Math.max(0, score);
  }

  private generateChecklist(aiResponse: string): ChecklistItem[] {
    return [
      { item: '功能完整性检查', passed: !aiResponse.includes('功能缺失') },
      { item: '代码规范检查', passed: !aiResponse.includes('规范问题') },
      { item: '单元测试覆盖', passed: aiResponse.includes('测试通过') || aiResponse.includes('覆盖') },
      { item: '文档完整性', passed: !aiResponse.includes('文档缺失') },
      { item: '安全检查', passed: !aiResponse.includes('安全') || aiResponse.includes('安全良好') }
    ];
  }

  private generateRecommendations(issues: QualityIssue[], aiResponse: string): string[] {
    const recommendations: string[] = [];

    if (issues.some(i => i.severity === IssueSeverity.CRITICAL)) {
      recommendations.push('优先修复严重问题');
    }

    if (issues.some(i => i.severity === IssueSeverity.MAJOR)) {
      recommendations.push('尽快处理主要问题');
    }

    recommendations.push('加强单元测试覆盖');
    recommendations.push('完善文档说明');

    return recommendations;
  }

  private evaluatePassFail(report: QualityReport): boolean {
    return report.overallScore >= 60 && report.issueSummary.critical === 0;
  }

  public async quickCheck(target: string): Promise<{score: number; majorIssues: number}> {
    this.log(`快速检查：${target}`);
    
    const response = await this.callAI(`请快速评估以下内容的质量（给出0-100分）：\n${target.substring(0, 500)}`);
    const scoreMatch = response.match(/(\d+)/);
    const score = scoreMatch ? parseInt(scoreMatch[1]) : 75;
    
    return {
      score,
      majorIssues: score < 60 ? 1 : 0
    };
  }

  public async recheckIssue(issueId: string, fixed: boolean): Promise<boolean> {
    this.log(`复核问题：${issueId}, 已修复：${fixed}`);
    return fixed;
  }

  public getIssuesBySeverity(severity: IssueSeverity): QualityIssue[] {
    return [];
  }
}
