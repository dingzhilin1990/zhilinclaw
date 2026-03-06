/**
 * 记忆管理器模块
 * 
 * 实现双模式记忆系统：
 * - 短期记忆：临时存储会话信息
 * - 长期记忆：持久化重要信息
 * 
 * 遵循本地优先原则，所有数据存储在本地
 */

import { EventBus } from '../events/EventBus';

/**
 * 记忆项类型
 */
export enum MemoryType {
  USER_INPUT = 'user_input',
  ASSISTANT_OUTPUT = 'assistant_output',
  SYSTEM_EVENT = 'system_event',
  KNOWLEDGE = 'knowledge',
  SKILL_RESULT = 'skill_result'
}

/**
 * 记忆项接口
 */
export interface MemoryItem {
  id?: string;
  type: MemoryType;
  content: any;
  timestamp: number;
  priority?: number; // 优先级，用于记忆淘汰
  tags?: string[];   // 标签，用于检索
}

/**
 * 记忆管理器类
 * 
 * 负责：
 * - 记忆的添加、查询、删除
 * - 记忆容量管理（LRU 淘汰策略）
 * - 记忆检索与过滤
 */
export class MemoryManager {
  private memories: MemoryItem[] = [];
  private maxItems: number;
  private memoryCounter: number = 0;
  private eventBus?: EventBus;

  constructor(maxItems: number = 1000) {
    this.maxItems = maxItems;
  }

  /**
   * 设置事件总线（用于发布记忆更新事件）
   */
  public setEventBus(eventBus: EventBus): void {
    this.eventBus = eventBus;
  }

  /**
   * 添加记忆
   * @param item 记忆项
   */
  public async add(item: MemoryItem): Promise<void> {
    // 生成 ID
    item.id = `mem_${++this.memoryCounter}`;
    
    // 默认优先级为 0
    if (item.priority === undefined) {
      item.priority = 0;
    }

    // 添加到记忆列表
    this.memories.push(item);

    // 检查是否超出容量限制
    if (this.memories.length > this.maxItems) {
      await this.evictLowPriorityMemories();
    }

    // 发布记忆更新事件
    if (this.eventBus) {
      await this.eventBus.publish('memory:updated', {
        key: item.id,
        type: item.type,
        action: 'added'
      });
    }
  }

  /**
   * 查询记忆（支持过滤）
   * @param options 查询选项
   */
  public query(options: {
    type?: MemoryType;
    tags?: string[];
    startTime?: number;
    endTime?: number;
    limit?: number;
  }): MemoryItem[] {
    let result = [...this.memories];

    // 按类型过滤
    if (options.type !== undefined) {
      result = result.filter(m => m.type === options.type);
    }

    // 按标签过滤
    if (options.tags && options.tags.length > 0) {
      result = result.filter(m => 
        m.tags && options.tags!.some(tag => m.tags!.includes(tag))
      );
    }

    // 按时间范围过滤
    if (options.startTime !== undefined) {
      result = result.filter(m => m.timestamp >= options.startTime!);
    }
    if (options.endTime !== undefined) {
      result = result.filter(m => m.timestamp <= options.endTime!);
    }

    // 按时间倒序排序（最新的在前）
    result.sort((a, b) => b.timestamp - a.timestamp);

    // 限制返回数量
    if (options.limit !== undefined) {
      result = result.slice(0, options.limit);
    }

    return result;
  }

  /**
   * 获取最近的记忆
   * @param limit 数量限制
   */
  public getRecent(limit: number = 10): MemoryItem[] {
    return this.memories
      .slice(-limit)
      .reverse();
  }

  /**
   * 根据 ID 获取记忆
   * @param id 记忆 ID
   */
  public getById(id: string): MemoryItem | null {
    const item = this.memories.find(m => m.id === id);
    return item || null;
  }

  /**
   * 删除记忆
   * @param id 记忆 ID
   */
  public async delete(id: string): Promise<boolean> {
    const index = this.memories.findIndex(m => m.id === id);
    if (index === -1) {
      return false;
    }

    this.memories.splice(index, 1);

    // 发布记忆更新事件
    if (this.eventBus) {
      await this.eventBus.publish('memory:updated', {
        key: id,
        action: 'deleted'
      });
    }

    return true;
  }

  /**
   * 清空所有记忆
   */
  public async clear(): Promise<void> {
    this.memories = [];
    this.memoryCounter = 0;

    if (this.eventBus) {
      await this.eventBus.publish('memory:cleared', {});
    }
  }

  /**
   * 获取记忆数量
   */
  public getItemsCount(): number {
    return this.memories.length;
  }

  /**
   * 获取记忆统计信息
   */
  public getStats(): Record<string, any> {
    const stats: Record<string, number> = {
      total: this.memories.length,
      maxItems: this.maxItems
    };

    // 按类型统计
    Object.values(MemoryType).forEach(type => {
      stats[type] = this.memories.filter(m => m.type === type).length;
    });

    return stats;
  }

  /**
   * 淘汰低优先级记忆（LRU 策略）
   */
  private async evictLowPriorityMemories(): Promise<void> {
    // 按优先级和时间戳排序（优先级低的、时间久的在前）
    this.memories.sort((a, b) => {
      if (a.priority !== b.priority) {
        return a.priority! - b.priority!;
      }
      return a.timestamp - b.timestamp;
    });

    // 删除最旧的 10% 记忆
    const evictCount = Math.ceil(this.maxItems * 0.1);
    const evicted = this.memories.splice(0, evictCount);

    console.log(`[MemoryManager] 已淘汰 ${evicted.length} 条记忆`);

    // 发布记忆淘汰事件
    if (this.eventBus) {
      await this.eventBus.publish('memory:evicted', {
        count: evicted.length,
        reason: 'capacity_limit'
      });
    }
  }

  /**
   * 导出记忆到 JSON
   */
  public exportToJSON(): string {
    return JSON.stringify(this.memories, null, 2);
  }

  /**
   * 从 JSON 导入记忆
   * @param json JSON 字符串
   */
  public importFromJSON(json: string): void {
    try {
      const items = JSON.parse(json) as MemoryItem[];
      this.memories = items;
      console.log(`[MemoryManager] 已导入 ${items.length} 条记忆`);
    } catch (error) {
      console.error('[MemoryManager] 导入记忆失败:', error);
    }
  }
}
