/**
 * ZhiLinClaw 核心内核模块
 * 
 * 核心理念：
 * 1. 本地优先 - 所有数据存储在本地，保护用户隐私
 * 2. 模块化设计 - 各组件独立，可灵活替换
 * 3. 插件化架构 - 支持动态扩展功能
 * 4. 事件驱动 - 基于发布订阅模式实现解耦
 */

import { EventBus } from '../events/EventBus';
import { PluginManager } from '../plugins/PluginManager';
import { MemoryManager } from '../memory/MemoryManager';
import { SkillRegistry } from '../skills/SkillRegistry';

/**
 * 核心配置接口
 */
export interface CoreConfig {
  name: string;
  version: string;
  dataPath: string;
  enableLogging: boolean;
  maxMemoryItems: number;
}

/**
 * ZhiLinClaw 核心类
 * 
 * 作为系统的中枢，负责：
 * - 初始化和协调各个模块
 * - 处理用户请求
 * - 管理插件生命周期
 * - 调度技能执行
 */
export class ZhiLinClawCore {
  private static instance: ZhiLinClawCore;
  private config: CoreConfig;
  private eventBus: EventBus;
  private pluginManager: PluginManager;
  private memoryManager: MemoryManager;
  private skillRegistry: SkillRegistry;
  private initialized: boolean = false;

  private constructor() {
    this.eventBus = new EventBus();
    this.config = {
      name: 'ZhiLinClaw',
      version: '1.0.0',
      dataPath: '',
      enableLogging: true,
      maxMemoryItems: 1000
    };
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): ZhiLinClawCore {
    if (!ZhiLinClawCore.instance) {
      ZhiLinClawCore.instance = new ZhiLinClawCore();
    }
    return ZhiLinClawCore.instance;
  }

  /**
   * 初始化核心系统
   */
  public async initialize(config: Partial<CoreConfig>): Promise<void> {
    if (this.initialized) {
      this.log('核心系统已初始化');
      return;
    }

    // 合并配置
    this.config = { ...this.config, ...config };
    
    this.log(`初始化 ${this.config.name} v${this.config.version}`);

    // 初始化各个模块
    this.memoryManager = new MemoryManager(this.config.maxMemoryItems);
    this.pluginManager = new PluginManager(this.eventBus);
    this.skillRegistry = new SkillRegistry(this.eventBus);

    // 注册内部事件处理器
    this.registerInternalHandlers();

    this.initialized = true;
    this.log('核心系统初始化完成');
  }

  /**
   * 注册内部事件处理器
   */
  private registerInternalHandlers(): void {
    // 处理插件加载事件
    this.eventBus.subscribe('plugin:loaded', (data: any) => {
      this.log(`插件已加载：${data.pluginName}`);
    });

    // 处理技能注册事件
    this.eventBus.subscribe('skill:registered', (data: any) => {
      this.log(`技能已注册：${data.skillName}`);
    });

    // 处理内存更新事件
    this.eventBus.subscribe('memory:updated', (data: any) => {
      this.log(`内存已更新：${data.key}`);
    });
  }

  /**
   * 处理用户请求
   */
  public async processRequest(input: string): Promise<string> {
    if (!this.initialized) {
      throw new Error('核心系统未初始化');
    }

    this.log(`处理请求：${input}`);

    // 发布请求事件
    this.eventBus.publish('request:received', { input, timestamp: Date.now() });

    // 存储到短期记忆
    await this.memoryManager.add({
      type: 'user_input',
      content: input,
      timestamp: Date.now()
    });

    // 通过事件总线分发请求，由相应的插件或技能处理
    const response = await this.dispatchToSkills(input);

    // 存储响应到记忆
    await this.memoryManager.add({
      type: 'assistant_output',
      content: response,
      timestamp: Date.now()
    });

    // 发布响应事件
    this.eventBus.publish('response:generated', { output: response });

    return response;
  }

  /**
   * 分发请求到技能处理器
   */
  private async dispatchToSkills(input: string): Promise<string> {
    // 获取所有已注册的技能
    const skills = this.skillRegistry.getAllSkills();
    
    // 简单的意图识别（实际项目中应该使用 AI 模型）
    for (const skill of skills) {
      if (skill.match(input)) {
        this.log(`匹配到技能：${skill.name}`);
        return await skill.execute(input);
      }
    }

    // 默认响应
    return `收到您的请求：${input}。当前尚未配置相应的处理技能。`;
  }

  /**
   * 获取事件总线实例
   */
  public getEventBus(): EventBus {
    return this.eventBus;
  }

  /**
   * 获取插件管理器
   */
  public getPluginManager(): PluginManager {
    return this.pluginManager;
  }

  /**
   * 获取记忆管理器
   */
  public getMemoryManager(): MemoryManager {
    return this.memoryManager;
  }

  /**
   * 获取技能注册表
   */
  public getSkillRegistry(): SkillRegistry {
    return this.skillRegistry;
  }

  /**
   * 日志输出
   */
  private log(message: string): void {
    if (this.config.enableLogging) {
      console.log(`[ZhiLinClaw] ${message}`);
    }
  }

  /**
   * 获取系统状态
   */
  public getStatus(): Record<string, any> {
    return {
      name: this.config.name,
      version: this.config.version,
      initialized: this.initialized,
      pluginsLoaded: this.pluginManager?.getLoadedPluginsCount() || 0,
      skillsRegistered: this.skillRegistry?.getSkillsCount() || 0,
      memoryItems: this.memoryManager?.getItemsCount() || 0
    };
  }
}
