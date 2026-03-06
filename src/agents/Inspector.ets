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
  enableLogging: true
};

/**
 * 质量问题严重级别
 */
export enum IssueSeverity {
  CRITICAL = 'critical',  // 严重 - 必须立即修复
  MAJOR = 'major',        // 主要 - 需要修复
  MINOR = 'minor',        // 次要 - 建议修复
  COSMETIC = 'cosmetic'   // 外观 - 可选修复
}

/**
 * 质量问题接口
 */
export interface QualityIssue {
  /** 问题 ID */
  id: string;
  /** 问题描述 */
  description: string;
  /** 问题类型 */
  type: string;
  /** 严重级别 */
  severity: IssueSeverity;
  /** 所在位置 */
  location?: string;
  /** 复现步骤 */
  reproductionSteps?: string[];
  /** 预期结果 */
  expectedResult?: string;
  /** 实际结果 */
  actualResult?: string;
  /** 建议修复方案 */
  suggestedFix?: string;
}

/**
 * 质量报告接口
 */
export interface QualityReport {
  /** 报告 ID */
  reportId: string;
  /** 被检查的对象 */
  targetName: string;
  /** 检查时间 */
  inspectedAt: number;
  /** 总体评分（0-100） */
  overallScore: number;
  /** 是否通过 */
  passed: boolean;
  /** 发现的问题列表 */
  issues: QualityIssue[];
  /** 问题统计 */
  issueSummary: {
    critical: number;
    major: number;
    minor: number;
    cosmetic: number;
  };
  /** 改进建议 */
  recommendations: string[];
  /** 检查项清单 */
  checklist: ChecklistItem[];
}

interface ChecklistItem {
  item: string;
  passed: boolean;
  notes?: string;
}

/**
 * 质检员类
 */
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

      // 1. 定义检查标准
      const criteria = await this.defineCriteria(input);
      
      // 2. 执行检查
      const findings = await this.performInspection(input, criteria);
      
      // 3. 生成质量报告
      const report = await this.generateReport(input, findings);
      
      // 4. 判断是否通过
      const passed = this.evaluatePassFail(report);

      return {
        success: true,
        output: `质量检查完成，评分：${report.overallScore}/100，${passed ? '通过' : '未通过'}`,
        documents: {
          qualityReport: report
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

  private async defineCriteria(target: string): Promise<string[]> {
    this.log('定义检查标准...');
    
    return [
      '功能性 - 功能是否完整实现',
      '可靠性 - 是否稳定可靠',
      '性能 - 性能是否达标',
      '可维护性 - 代码是否易读易维护',
      '安全性 - 是否存在安全隐患'
    ];
  }

  private async performInspection(
    target: string, 
    criteria: string[]
  ): Promise<QualityIssue[]> {
    this.log('执行质量检查...');
    
    const issues: QualityIssue[] = [];

    // 模拟检查过程
    // 实际项目中应调用静态分析工具、运行测试等
    
    // 示例问题
    issues.push({
      id: `issue_${++this.issueCounter}`,
      description: '发现一个潜在问题',
      type: 'functionality',
      severity: IssueSeverity.MINOR,
      location: '模块 A',
      reproductionSteps: ['步骤 1', '步骤 2'],
      expectedResult: '应该正常工作的功能',
      actualResult: '出现异常行为',
      suggestedFix: '建议的修复方案'
    });

    return issues;
  }

  private async generateReport(
    target: string,
    issues: QualityIssue[]
  ): Promise<QualityReport> {
    this.log('生成质量报告...');
    
    // 计算问题统计
    const summary = {
      critical: issues.filter(i => i.severity === IssueSeverity.CRITICAL).length,
      major: issues.filter(i => i.severity === IssueSeverity.MAJOR).length,
      minor: issues.filter(i => i.severity === IssueSeverity.MINOR).length,
      cosmetic: issues.filter(i => i.severity === IssueSeverity.COSMETIC).length
    };

    // 计算总体评分
    const score = this.calculateScore(issues);

    // 生成检查清单
    const checklist = this.generateChecklist();

    return {
      reportId: `report_${Date.now()}`,
      targetName: target,
      inspectedAt: Date.now(),
      overallScore: score,
      passed: score >= 60 && summary.critical === 0,
      issues,
      issueSummary: summary,
      recommendations: this.generateRecommendations(issues),
      checklist
    };
  }

  private calculateScore(issues: QualityIssue[]): number {
    // 基础分 100，根据问题扣分
    let score = 100;
    
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

  private generateChecklist(): ChecklistItem[] {
    return [
      { item: '功能完整性检查', passed: true },
      { item: '代码规范检查', passed: true },
      { item: '单元测试覆盖', passed: false, notes: '覆盖率不足 80%' },
      { item: '文档完整性', passed: true },
      { item: '安全检查', passed: true }
    ];
  }

  private generateRecommendations(issues: QualityIssue[]): string[] {
    const recommendations: string[] = [];

    if (issues.some(i => i.severity === IssueSeverity.CRITICAL)) {
      recommendations.push('优先修复严重问题');
    }

    if (issues.length > 5) {
      recommendations.push('建议进行全面代码审查');
    }

    recommendations.push('加强单元测试覆盖');
    recommendations.push('完善文档说明');

    return recommendations;
  }

  private evaluatePassFail(report: QualityReport): boolean {
    return report.overallScore >= 60 && report.issueSummary.critical === 0;
  }

  /**
   * 快速检查（轻量级质检）
   */
  public async quickCheck(target: string): Promise<{score: number; majorIssues: number}> {
    this.log(`快速检查：${target}`);
    
    return {
      score: 85,
      majorIssues: 0
    };
  }

  /**
   * 复核问题
   */
  public async recheckIssue(issueId: string, fixed: boolean): Promise<boolean> {
    this.log(`复核问题：${issueId}, 已修复：${fixed}`);
    
    // 实际项目中应重新运行检查
    return fixed;
  }

  /**
   * 获取所有问题
   */
  public getIssuesBySeverity(severity: IssueSeverity): QualityIssue[] {
    // 实际项目中应从报告中筛选
    return [];
  }
}
