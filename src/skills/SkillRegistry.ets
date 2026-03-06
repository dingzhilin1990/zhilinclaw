/**
 * 技能注册表模块
 * 
 * 技能是 ZhiLinClaw执行具体任务的能力单元
 * 支持：
 * - 技能注册与发现
 * - 技能匹配与执行
 * - 技能组合与链式调用
 */

import { EventBus } from '../events/EventBus';

/**
 * 技能元数据接口
 */
export interface SkillMetadata {
  name: string;
  description: string;
  version: string;
  author: string;
  triggers: string[]; // 触发关键词或模式
}

/**
 * 技能执行结果
 */
export interface SkillResult {
  success: boolean;
  output: string;
  data?: any;
  error?: string;
}

/**
 * 技能基类
 */
export abstract class Skill {
  public metadata: SkillMetadata;

  constructor(metadata: SkillMetadata) {
    this.metadata = metadata;
  }

  /**
   * 判断输入是否匹配此技能
   * @param input 用户输入
   */
  public match(input: string): boolean {
    return this.metadata.triggers.some(trigger => 
      input.toLowerCase().includes(trigger.toLowerCase())
    );
  }

  /**
   * 执行技能
   * @param input 输入内容
   * @param context 执行上下文
   */
  public abstract execute(input: string, context?: any): Promise<SkillResult>;
}

/**
 * 技能包装器
 */
interface SkillWrapper {
  skill: Skill;
  registeredAt: number;
  callCount: number;
}

/**
 * 技能注册表类
 * 
 * 负责：
 * - 技能的注册与管理
 * - 技能匹配与调度
 * - 技能执行统计
 */
export class SkillRegistry {
  private skills: Map<string, SkillWrapper> = new Map();
  private eventBus: EventBus;

  constructor(eventBus: EventBus) {
    this.eventBus = eventBus;
  }

  /**
   * 注册技能
   * @param skill 技能实例
   */
  public async register(skill: Skill): Promise<void> {
    const name = skill.metadata.name;

    if (this.skills.has(name)) {
      throw new Error(`技能已存在：${name}`);
    }

    const wrapper: SkillWrapper = {
      skill,
      registeredAt: Date.now(),
      callCount: 0
    };

    this.skills.set(name, wrapper);

    // 发布技能注册事件
    await this.eventBus.publish('skill:registered', {
      skillName: name,
      version: skill.metadata.version,
      timestamp: Date.now()
    });

    console.log(`[SkillRegistry] 技能已注册：${name}`);
  }

  /**
   * 注销技能
   * @param name 技能名称
   */
  public async unregister(name: string): Promise<boolean> {
    if (!this.skills.has(name)) {
      return false;
    }

    this.skills.delete(name);

    await this.eventBus.publish('skill:unregistered', {
      skillName: name,
      timestamp: Date.now()
    });

    console.log(`[SkillRegistry] 技能已注销：${name}`);
    return true;
  }

  /**
   * 获取技能
   * @param name 技能名称
   */
  public getSkill<T extends Skill>(name: string): T | undefined {
    const wrapper = this.skills.get(name);
    return wrapper?.skill as T;
  }

  /**
   * 获取所有技能
   */
  public getAllSkills(): Skill[] {
    return Array.from(this.skills.values()).map(w => w.skill);
  }

  /**
   * 根据输入匹配技能
   * @param input 用户输入
   */
  public matchSkills(input: string): Skill[] {
    const matched: Skill[] = [];

    this.skills.forEach(wrapper => {
      if (wrapper.skill.match(input)) {
        matched.push(wrapper.skill);
      }
    });

    // 按触发器匹配度排序（更长的触发器优先）
    matched.sort((a, b) => {
      const aScore = Math.max(...a.metadata.triggers
        .filter(t => input.toLowerCase().includes(t.toLowerCase()))
        .map(t => t.length));
      const bScore = Math.max(...b.metadata.triggers
        .filter(t => input.toLowerCase().includes(t.toLowerCase()))
        .map(t => t.length));
      return bScore - aScore;
    });

    return matched;
  }

  /**
   * 执行技能
   * @param name 技能名称
   * @param input 输入内容
   * @param context 上下文
   */
  public async executeSkill(
    name: string, 
    input: string, 
    context?: any
  ): Promise<SkillResult | null> {
    const wrapper = this.skills.get(name);
    if (!wrapper) {
      return {
        success: false,
        output: '',
        error: `技能不存在：${name}`
      };
    }

    try {
      wrapper.callCount++;
      
      // 发布技能执行事件
      await this.eventBus.publish('skill:executing', {
        skillName: name,
        input,
        timestamp: Date.now()
      });

      const result = await wrapper.skill.execute(input, context);

      // 发布技能完成事件
      await this.eventBus.publish('skill:completed', {
        skillName: name,
        success: result.success,
        timestamp: Date.now()
      });

      return result;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      
      await this.eventBus.publish('skill:error', {
        skillName: name,
        error: errorMessage,
        timestamp: Date.now()
      });

      return {
        success: false,
        output: '',
        error: errorMessage
      };
    }
  }

  /**
   * 获取技能数量
   */
  public getSkillsCount(): number {
    return this.skills.size;
  }

  /**
   * 获取技能调用统计
   */
  public getSkillStats(name: string): Record<string, any> | null {
    const wrapper = this.skills.get(name);
    if (!wrapper) return null;

    return {
      name: wrapper.skill.metadata.name,
      version: wrapper.skill.metadata.version,
      registeredAt: wrapper.registeredAt,
      callCount: wrapper.callCount,
      uptime: Date.now() - wrapper.registeredAt
    };
  }

  /**
   * 获取所有技能统计
   */
  public getAllStats(): Record<string, any>[] {
    return Array.from(this.skills.values()).map(w => ({
      name: w.skill.metadata.name,
      version: w.skill.metadata.version,
      callCount: w.callCount,
      registeredAt: w.registeredAt
    }));
  }
}
