/**
 * 执行层 Agent - 协调官
 * 
 * 核心职责：
 * - 任务拆解
 * - 进度管控
 * - 角色协同
 * - 资源调度
 * 
 * 触发关键词：任务、管理、协调、调度
 */

import { AgentBase, AgentConfig, AgentContext, AgentResult, AgentRole, AgentLayer } from './AgentBase';

const coordinatorConfig: AgentConfig = {
  name: '协调官',
  role: AgentRole.COORDINATOR,
  layer: AgentLayer.EXECUTION,
  triggerKeywords: ['任务', '管理', '协调', '调度', '进度', 'coordinate', 'manage'],
  maxIterations: 15,
  enableLogging: true,
  systemPrompt: `你是一位专业的项目协调官。你的职责是：
1. 将复杂目标拆解为可执行的任务
2. 合理分配任务给合适的角色
3. 跟踪进度并识别阻塞点
4. 协调资源确保项目顺利进行

请输出清晰的任务列表和进度计划。`
};

export interface TaskItem {
  id: string;
  name: string;
  description: string;
  assignee: AgentRole;
  priority: 'low' | 'medium' | 'high' | 'critical';
  status: 'pending' | 'in_progress' | 'completed' | 'blocked';
  estimatedHours?: number;
  actualHours?: number;
  dependencies?: string[];
}

export interface ProgressReport {
  overallProgress: number;
  completedTasks: number;
  totalTasks: number;
  inProgressTasks: TaskItem[];
  blockedTasks: TaskItem[];
  risks: string[];
  nextSteps: string[];
}

export class Coordinator extends AgentBase {
  private tasks: Map<string, TaskItem> = new Map();
  private taskCounter: number = 0;

  constructor() {
    super(coordinatorConfig);
  }

  async process(input: string, context?: AgentContext): Promise<AgentResult> {
    const startTime = Date.now();
    
    await this.initialize(context || {
      taskId: `task_${Date.now()}`,
      taskDescription: input
    });

    try {
      this.log('开始协调任务...');

      const breakdownPrompt = `请将以下目标拆解为具体任务：

目标：${input}

请按以下格式输出任务列表：
1. 任务名称 - 负责角色 - 优先级 - 预计耗时
   - 任务描述
   - 依赖关系

负责角色可选：策略师、研究员、顾问、工程师、记录官、质检员、修复师
优先级可选：低、中、高、紧急`;

      const aiResponse = await this.callAI(breakdownPrompt);
      
      const taskList = this.parseTasks(aiResponse);
      await this.assignTasks(taskList);
      const progress = this.calculateProgress();
      const report = this.generateReport(progress, aiResponse);

      return {
        success: true,
        output: `任务协调完成，共${taskList.length}个任务`,
        documents: {
          taskList,
          progressReport: report,
          aiAnalysis: aiResponse
        },
        executionTime: Date.now() - startTime
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      return {
        success: false,
        output: '任务协调失败',
        error: errorMessage,
        executionTime: Date.now() - startTime
      };
    }
  }

  private parseTasks(aiResponse: string): TaskItem[] {
    const tasks: TaskItem[] = [];
    const lines = aiResponse.split('\n');
    
    for (const line of lines) {
      if (line.match(/^\d+\./)) {
        const task = this.parseTaskLine(line);
        if (task) {
          tasks.push(task);
          this.tasks.set(task.id, task);
        }
      }
    }

    if (tasks.length === 0) {
      tasks.push(
        {
          id: `task_${++this.taskCounter}`,
          name: '需求分析',
          description: '分析项目需求',
          assignee: AgentRole.STRATEGIST,
          priority: 'high',
          status: 'pending',
          estimatedHours: 2
        },
        {
          id: `task_${++this.taskCounter}`,
          name: '技术实现',
          description: '实现核心功能',
          assignee: AgentRole.ENGINEER,
          priority: 'high',
          status: 'pending',
          estimatedHours: 8
        },
        {
          id: `task_${++this.taskCounter}`,
          name: '质量检查',
          description: '检查代码质量',
          assignee: AgentRole.INSPECTOR,
          priority: 'medium',
          status: 'pending',
          estimatedHours: 2
        }
      );
      
      tasks.forEach(task => this.tasks.set(task.id, task));
    }

    return tasks;
  }

  private parseTaskLine(line: string): TaskItem | null {
    const match = line.match(/(\d+)\.\s*(.+?)\s*-\s*(.+?)\s*-\s*(.+?)\s*-\s*(.+)/);
    if (!match) return null;

    const roleMap: Record<string, AgentRole> = {
      '策略师': AgentRole.STRATEGIST,
      '研究员': AgentRole.RESEARCHER,
      '顾问': AgentRole.ADVISOR,
      '工程师': AgentRole.ENGINEER,
      '记录官': AgentRole.RECORDER,
      '质检员': AgentRole.INSPECTOR,
      '修复师': AgentRole.FIXER
    };

    const priorityMap: Record<string, 'low' | 'medium' | 'high' | 'critical'> = {
      '低': 'low', '中': 'medium', '高': 'high', '紧急': 'critical'
    };

    return {
      id: `task_${++this.taskCounter}`,
      name: match[2].trim(),
      description: match[2].trim(),
      assignee: roleMap[match[3].trim()] || AgentRole.ENGINEER,
      priority: priorityMap[match[4].trim()] || 'medium',
      status: 'pending',
      estimatedHours: parseInt(match[5]) || 4
    };
  }

  private async assignTasks(tasks: TaskItem[]): Promise<void> {
    this.log('分配任务...');
    for (const task of tasks) {
      this.log(`分配任务 ${task.name} 给 ${task.assignee}`);
    }
  }

  private calculateProgress(): ProgressReport {
    const taskArray = Array.from(this.tasks.values());
    const completed = taskArray.filter(t => t.status === 'completed').length;
    const inProgress = taskArray.filter(t => t.status === 'in_progress');
    const blocked = taskArray.filter(t => t.status === 'blocked');

    return {
      overallProgress: taskArray.length > 0 ? (completed / taskArray.length) * 100 : 0,
      completedTasks: completed,
      totalTasks: taskArray.length,
      inProgressTasks: inProgress,
      blockedTasks: blocked,
      risks: blocked.length > 0 ? ['存在阻塞任务'] : [],
      nextSteps: inProgress.length > 0 ? ['继续执行进行中任务'] : ['开始新任务']
    };
  }

  private generateReport(progress: ProgressReport, aiResponse: string): ProgressReport {
    return {
      ...progress,
      risks: [...progress.risks, '进度风险'],
      nextSteps: [...progress.nextSteps, '按计划推进']
    };
  }

  public async updateTaskStatus(taskId: string, status: TaskItem['status']): Promise<boolean> {
    const task = this.tasks.get(taskId);
    if (!task) return false;

    task.status = status;
    this.tasks.set(taskId, task);
    this.log(`任务 ${taskId} 状态更新为 ${status}`);
    return true;
  }

  public getAllTasks(): TaskItem[] {
    return Array.from(this.tasks.values());
  }

  public getTaskStats(): Record<string, number> {
    const tasks = Array.from(this.tasks.values());
    return {
      total: tasks.length,
      pending: tasks.filter(t => t.status === 'pending').length,
      inProgress: tasks.filter(t => t.status === 'in_progress').length,
      completed: tasks.filter(t => t.status === 'completed').length,
      blocked: tasks.filter(t => t.status === 'blocked').length
    };
  }

  public identifyCriticalPath(): string[] {
    this.log('识别关键路径...');
    return Array.from(this.tasks.values())
      .filter(t => t.priority === 'critical' || t.priority === 'high')
      .map(t => t.id);
  }

  public optimizeResourceAllocation(): void {
    this.log('优化资源分配...');
  }
}
