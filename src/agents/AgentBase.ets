/**
 * Agent 基础定义
 * 
 * 定义所有 Agent 角色的通用接口和基类
 */

import { AIModelAdapter, ChatMessage, AIResponse } from '../adapters/AIModelAdapter';

/**
 * Agent 所属层级
 */
export enum AgentLayer {
  /** 决策层 */
  DECISION = 'decision',
  /** 执行层 */
  EXECUTION = 'execution',
  /** 监督层 */
  SUPERVISION = 'supervision'
}

/**
 * Agent 角色类型
 */
export enum AgentRole {
  STRATEGIST = 'strategist',     // 策略师
  RESEARCHER = 'researcher',     // 研究员
  ADVISOR = 'advisor',           // 顾问
  ENGINEER = 'engineer',         // 工程师
  COORDINATOR = 'coordinator',   // 协调官
  RECORDER = 'recorder',         // 记录官
  INSPECTOR = 'inspector',       // 质检员
  FIXER = 'fixer'                // 修复师
}

/**
 * Agent 类型（用于触发关键词匹配）
 */
export enum AgentType {
  PLANNING = 'planning',         // 规划类
  KNOWLEDGE = 'knowledge',       // 知识类
  REVIEW = 'review',             // 评审类
  DEVELOPMENT = 'development',   // 开发类
  MANAGEMENT = 'management',     // 管理类
  DOCUMENTATION = 'documentation',// 文档类
  QUALITY = 'quality',           // 质量类
  DEBUGGING = 'debugging'        // 调试类
}

/**
 * Agent 配置接口
 */
export interface AgentConfig {
  /** Agent 名称 */
  name: string;
  /** 角色类型 */
  role: AgentRole;
  /** 所属层级 */
  layer: AgentLayer;
  /** 触发关键词列表 */
  triggerKeywords: string[];
  /** 最大迭代次数 */
  maxIterations?: number;
  /** 是否启用日志 */
  enableLogging?: boolean;
  /** 系统提示词 */
  systemPrompt?: string;
}

/**
 * Agent 上下文信息
 */
export interface AgentContext {
  /** 当前任务 ID */
  taskId: string;
  /** 任务描述 */
  taskDescription: string;
  /** 相关文档列表 */
  documents?: Record<string, any>;
  /** 历史消息 */
  messageHistory?: AgentMessage[];
  /** 资源限制 */
  resources?: {
    maxTime?: number;
    maxMemory?: number;
  };
}

/**
 * Agent 消息接口
 */
export interface AgentMessage {
  /** 发送者角色 */
  from: AgentRole;
  /** 接收者角色 */
  to?: AgentRole | 'all';
  /** 消息类型 */
  type: 'request' | 'response' | 'notification' | 'command';
  /** 消息内容 */
  content: string;
  /** 时间戳 */
  timestamp: number;
  /** 附加数据 */
  data?: any;
}

/**
 * Agent 执行结果
 */
export interface AgentResult {
  /** 是否成功 */
  success: boolean;
  /** 输出内容 */
  output: string;
  /** 生成的文档 */
  documents?: Record<string, any>;
  /** 错误信息 */
  error?: string;
  /** 执行耗时（毫秒） */
  executionTime?: number;
}

/**
 * Agent 基类
 */
export abstract class AgentBase {
  public config: AgentConfig;
  protected context?: AgentContext;
  protected aiModelAdapter?: AIModelAdapter;

  constructor(config: AgentConfig) {
    this.config = config;
  }

  /**
   * 设置 AI 模型适配器
   */
  public setAIModelAdapter(adapter: AIModelAdapter): void {
    this.aiModelAdapter = adapter;
    this.log('AI 模型适配器已设置');
  }

  /**
   * 调用 AI 模型生成响应
   */
  protected async callAI(prompt: string, systemPrompt?: string): Promise<string> {
    if (!this.aiModelAdapter) {
      this.log('警告：未设置 AI 模型适配器，使用模拟响应');
      return this.getSimulatedResponse(prompt);
    }

    try {
      const messages: ChatMessage[] = [];
      
      if (systemPrompt || this.config.systemPrompt) {
        messages.push({
          role: 'system',
          content: systemPrompt || this.config.systemPrompt || '',
          timestamp: Date.now()
        });
      }
      
      messages.push({
        role: 'user',
        content: prompt,
        timestamp: Date.now()
      });

      const response: AIResponse = await this.aiModelAdapter.chat(messages);
      
      if (response.success) {
        return response.content;
      } else {
        this.log(`AI 调用失败：${response.error}`);
        return this.getSimulatedResponse(prompt);
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      this.log(`AI 调用异常：${errorMessage}`);
      return this.getSimulatedResponse(prompt);
    }
  }

  /**
   * 获取模拟响应（当 AI 模型不可用时）
   */
  protected getSimulatedResponse(prompt: string): string {
    return `[模拟响应] 针对"${prompt.substring(0, 50)}..."的处理结果。实际部署时将使用真实的 AI 模型。`;
  }

  /**
   * 初始化 Agent
   */
  public async initialize(context: AgentContext): Promise<void> {
    this.context = context;
    this.log(`${this.config.name} 已初始化`);
  }

  /**
   * 处理任务（抽象方法，子类实现）
   */
  public abstract process(input: string, context?: AgentContext): Promise<AgentResult>;

  /**
   * 检查输入是否匹配此 Agent 的触发关键词
   */
  public matches(input: string): boolean {
    return this.config.triggerKeywords.some(keyword =>
      input.toLowerCase().includes(keyword.toLowerCase())
    );
  }

  /**
   * 发送消息
   */
  protected sendMessage(
    to: AgentRole | 'all',
    type: AgentMessage['type'],
    content: string,
    data?: any
  ): AgentMessage {
    const message: AgentMessage = {
      from: this.config.role,
      to,
      type,
      content,
      timestamp: Date.now(),
      data
    };

    this.log(`发送消息给 ${to}: ${content.substring(0, 50)}...`);
    return message;
  }

  /**
   * 日志输出
   */
  protected log(message: string): void {
    if (this.config.enableLogging !== false) {
      console.log(`[${this.config.name}] ${message}`);
    }
  }

  /**
   * 获取 Agent 状态
   */
  public getStatus(): Record<string, any> {
    return {
      name: this.config.name,
      role: this.config.role,
      layer: this.config.layer,
      isActive: !!this.context
    };
  }
}
