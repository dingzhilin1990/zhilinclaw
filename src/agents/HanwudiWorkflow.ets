/**
 * 汉武帝工作流引擎
 * 
 * 基于 MetaGPT SOP 方法论实现，将标准化作业流程具象化为 Agent 团队协作规则
 * Code = SOP(Team)
 * 
 * 标准流程：
 * 1. 需求输入 → 研究员检索知识
 * 2. 策略规划 → 策略师制定方案，顾问评审
 * 3. 任务执行 → 协调官分配，工程师实现，记录官文档化
 * 4. 质量校验 → 质检员审核
 * 5. 问题闭环 → 修复师修复，质检员复核
 * 6. 成果归档 → 记录官归档
 */

import { AgentBase, AgentContext, AgentResult } from './AgentBase';
import { Strategist } from './Strategist';
import { Researcher } from './Researcher';
import { Advisor } from './Advisor';
import { Engineer } from './Engineer';
import { Coordinator, type TaskItem } from './Coordinator';
import { Recorder, type Document } from './Recorder';
import { Inspector, type QualityReport } from './Inspector';
import { Fixer } from './Fixer';

/**
 * 工作流配置接口
 */
export interface WorkflowConfig {
  /** 是否启用研究员 */
  enableResearcher: boolean;
  /** 是否启用顾问评审 */
  enableAdvisorReview: boolean;
  /** 是否启用完整文档 */
  enableFullDocumentation: boolean;
  /** 质量通过阈值（0-100） */
  qualityThreshold: number;
  /** 最大迭代次数 */
  maxIterations: number;
  /** 是否启用日志 */
  enableLogging: boolean;
}

/**
 * 任务结果接口
 */
export interface TaskResult {
  /** 是否成功 */
  success: boolean;
  /** 最终输出 */
  output: string;
  /** 生成的所有文档 */
  documents: Record<string, any>;
  /** 质量报告 */
  qualityReport?: QualityReport;
  /** 执行时间（毫秒） */
  executionTime: number;
  /** 流程日志 */
  workflowLog: WorkflowLogEntry[];
}

interface WorkflowLogEntry {
  step: number;
  agent: string;
  action: string;
  status: 'started' | 'completed' | 'failed';
  timestamp: number;
  details?: any;
}

/**
 * 默认配置
 */
const defaultConfig: WorkflowConfig = {
  enableResearcher: true,
  enableAdvisorReview: true,
  enableFullDocumentation: true,
  qualityThreshold: 70,
  maxIterations: 3,
  enableLogging: true
};

/**
 * 汉武帝工作流引擎类
 */
export class HanwudiWorkflow {
  private config: WorkflowConfig;
  private log: WorkflowLogEntry[] = [];
  
  // Agent 实例
  private researcher: Researcher;
  private strategist: Strategist;
  private advisor: Advisor;
  private coordinator: Coordinator;
  private engineer: Engineer;
  private recorder: Recorder;
  private inspector: Inspector;
  private fixer: Fixer;

  constructor(config?: Partial<WorkflowConfig>) {
    this.config = { ...defaultConfig, ...config };
    
    // 初始化所有 Agent
    this.researcher = new Researcher();
    this.strategist = new Strategist();
    this.advisor = new Advisor();
    this.coordinator = new Coordinator();
    this.engineer = new Engineer();
    this.recorder = new Recorder();
    this.inspector = new Inspector();
    this.fixer = new Fixer();

    if (this.config.enableLogging) {
      console.log('[HanwudiWorkflow] 工作流引擎已初始化');
    }
  }

  /**
   * 执行完整工作流
   * @param requirement 需求描述
   */
  async execute(requirement: string): Promise<TaskResult> {
    const startTime = Date.now();
    this.log = [];
    
    this.addLog(0, 'Workflow', '开始执行工作流', 'started');

    try {
      // 步骤 1: 研究调研
      const researchResult = await this.step1_Research(requirement);
      
      // 步骤 2: 策略规划
      const strategyResult = await this.step2_Planning(researchResult);
      
      // 步骤 3: 方案评审（可选）
      if (this.config.enableAdvisorReview) {
        await this.step3_Review(strategyResult);
      }
      
      // 步骤 4: 任务执行
      const executionResult = await this.step4_Execution(strategyResult);
      
      // 步骤 5: 质量检查
      const qualityResult = await this.step5_QualityCheck(executionResult);
      
      // 步骤 6: 问题修复（如有必要）
      let fixResult = null;
      if (!qualityResult.passed) {
        fixResult = await this.step6_FixIssues(qualityResult);
      }
      
      // 步骤 7: 成果归档
      const archiveResult = await this.step7_Archive(executionResult, qualityResult);

      const executionTime = Date.now() - startTime;
      
      this.addLog(7, 'Workflow', '工作流执行完成', 'completed', {
        totalSteps: 7,
        executionTime
      });

      return {
        success: qualityResult.passed || !!fixResult,
        output: '任务完成',
        documents: {
          ...researchResult.documents,
          ...strategyResult.documents,
          ...executionResult.documents,
          ...archiveResult
        },
        qualityReport: qualityResult,
        executionTime,
        workflowLog: this.log
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      this.addLog(0, 'Workflow', `工作流执行失败：${errorMessage}`, 'failed');
      
      return {
        success: false,
        output: `工作流执行失败：${errorMessage}`,
        documents: {},
        executionTime: Date.now() - startTime,
        workflowLog: this.log
      };
    }
  }

  /**
   * 步骤 1: 研究调研
   */
  private async step1_Research(requirement: string): Promise<any> {
    this.addLog(1, 'Researcher', '开始背景调研', 'started');
    
    const result = await this.researcher.process(requirement);
    
    this.addLog(1, 'Researcher', '背景调研完成', 
      result.success ? 'completed' : 'failed', 
      result.documents
    );
    
    return result;
  }

  /**
   * 步骤 2: 策略规划
   */
  private async step2_Planning(researchResult: any): Promise<any> {
    this.addLog(2, 'Strategist', '制定执行策略', 'started');
    
    const input = researchResult.output || '';
    const result = await this.strategist.process(input);
    
    this.addLog(2, 'Strategist', '策略规划完成', 
      result.success ? 'completed' : 'failed',
      result.documents
    );
    
    return result;
  }

  /**
   * 步骤 3: 方案评审
   */
  private async step3_Review(strategyResult: any): Promise<any> {
    this.addLog(3, 'Advisor', '开始方案评审', 'started');
    
    const input = JSON.stringify(strategyResult.documents);
    const result = await this.advisor.process(input);
    
    this.addLog(3, 'Advisor', '方案评审完成', 
      result.success ? 'completed' : 'failed',
      result.documents
    );
    
    return result;
  }

  /**
   * 步骤 4: 任务执行
   */
  private async step4_Execution(strategyResult: any): Promise<any> {
    this.addLog(4, 'Coordinator', '开始任务协调', 'started');
    
    // 4.1 协调官拆解任务
    const coordInput = JSON.stringify(strategyResult.documents);
    const coordResult = await this.coordinator.process(coordInput);
    
    this.addLog(4, 'Coordinator', '任务协调完成', 
      coordResult.success ? 'completed' : 'failed',
      coordResult.documents
    );
    
    // 4.2 工程师实现功能
    this.addLog(4, 'Engineer', '开始功能实现', 'started');
    
    const engInput = '根据策略实现功能';
    const engResult = await this.engineer.process(engInput);
    
    this.addLog(4, 'Engineer', '功能实现完成', 
      engResult.success ? 'completed' : 'failed',
      engResult.documents
    );
    
    // 4.3 记录官文档化
    if (this.config.enableFullDocumentation) {
      this.addLog(4, 'Recorder', '开始文档记录', 'started');
      
      const recInput = '整理项目文档';
      const recResult = await this.recorder.process(recInput);
      
      this.addLog(4, 'Recorder', '文档记录完成', 
        recResult.success ? 'completed' : 'failed',
        recResult.documents
      );
    }
    
    return engResult;
  }

  /**
   * 步骤 5: 质量检查
   */
  private async step5_QualityCheck(executionResult: any): Promise<QualityReport> {
    this.addLog(5, 'Inspector', '开始质量检查', 'started');
    
    const input = JSON.stringify(executionResult.documents);
    const result = await this.inspector.process(input);
    
    const qualityReport = result.documents?.qualityReport as QualityReport;
    
    this.addLog(5, 'Inspector', '质量检查完成', 
      result.success ? 'completed' : 'failed',
      { score: qualityReport?.overallScore, passed: qualityReport?.passed }
    );
    
    return qualityReport;
  }

  /**
   * 步骤 6: 问题修复
   */
  private async step6_FixIssues(qualityResult: QualityReport): Promise<any> {
    this.addLog(6, 'Fixer', '开始问题修复', 'started');
    
    const issues = qualityResult.issues;
    const fixResults = [];
    
    for (const issue of issues) {
      const fixResult = await this.fixer.process(JSON.stringify(issue));
      fixResults.push(fixResult);
    }
    
    this.addLog(6, 'Fixer', '问题修复完成', 'completed', {
      fixedCount: fixResults.length
    });
    
    // 重新检查
    const recheckResult = await this.inspector.process('复核已修复问题');
    
    return {
      fixResults,
      recheckResult
    };
  }

  /**
   * 步骤 7: 成果归档
   */
  private async step7_Archive(executionResult: any, qualityResult: any): Promise<any> {
    this.addLog(7, 'Recorder', '开始成果归档', 'started');
    
    const archiveResult = {
      finalDeliverables: executionResult.documents,
      qualityReport,
      archivedAt: Date.now()
    };
    
    this.addLog(7, 'Recorder', '成果归档完成', 'completed', archiveResult);
    
    return archiveResult;
  }

  /**
   * 添加日志条目
   */
  private addLog(
    step: number,
    agent: string,
    action: string,
    status: WorkflowLogEntry['status'],
    details?: any
  ): void {
    this.log.push({
      step,
      agent,
      action,
      status,
      timestamp: Date.now(),
      details
    });

    if (this.config.enableLogging) {
      console.log(`[Step ${step}] ${agent}: ${action} - ${status}`);
    }
  }

  /**
   * 获取工作流日志
   */
  public getWorkflowLog(): WorkflowLogEntry[] {
    return [...this.log];
  }

  /**
   * 导出工作流报告
   */
  public exportWorkflowReport(result: TaskResult): string {
    return JSON.stringify({
      summary: {
        success: result.success,
        executionTime: result.executionTime,
        totalSteps: this.log.length
      },
      qualityScore: result.qualityReport?.overallScore,
      logs: this.log,
      documents: Object.keys(result.documents)
    }, null, 2);
  }
}
