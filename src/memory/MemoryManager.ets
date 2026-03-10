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
import { StorageAdapter, StorageFactory, StorageConfig } from '../adapters/StorageAdapter';

export enum MemoryType {
  USER_INPUT = 'user_input',
  ASSISTANT_OUTPUT = 'assistant_output',
  SYSTEM_EVENT = 'system_event',
  KNOWLEDGE = 'knowledge',
  SKILL_RESULT = 'skill_result'
}

export interface MemoryItem {
  id?: string;
  type: MemoryType;
  content: any;
  timestamp: number;
  priority?: number;
  tags?: string[];
}

export class MemoryManager {
  private memories: MemoryItem[] = [];
  private maxItems: number;
  private memoryCounter: number = 0;
  private eventBus?: EventBus;
  private storageAdapter?: StorageAdapter;
  private autoSave: boolean = true;
  private storageKey: string = 'memory_store';

  constructor(maxItems: number = 1000) {
    this.maxItems = maxItems;
  }

  public setEventBus(eventBus: EventBus): void {
    this.eventBus = eventBus;
  }

  public setStorageAdapter(adapter: StorageAdapter): void {
    this.storageAdapter = adapter;
    this.loadFromStorage();
  }

  public initializeStorage(config: StorageConfig): void {
    this.storageAdapter = StorageFactory.create(config);
    this.loadFromStorage();
  }

  private async loadFromStorage(): Promise<void> {
    if (!this.storageAdapter) return;
    
    try {
      const stored = await this.storageAdapter.load(this.storageKey);
      if (stored && Array.isArray(stored)) {
        this.memories = stored;
        this.memoryCounter = this.memories.length;
        console.log(`[MemoryManager] 从存储加载 ${this.memories.length} 条记忆`);
      }
    } catch (error) {
      console.warn('[MemoryManager] 加载存储失败:', error);
    }
  }

  private async saveToStorage(): Promise<void> {
    if (!this.storageAdapter || !this.autoSave) return;
    
    try {
      await this.storageAdapter.save(this.storageKey, this.memories);
    } catch (error) {
      console.warn('[MemoryManager] 保存存储失败:', error);
    }
  }

  public async add(item: MemoryItem): Promise<void> {
    item.id = `mem_${++this.memoryCounter}`;
    
    if (item.priority === undefined) {
      item.priority = 0;
    }

    this.memories.push(item);

    if (this.memories.length > this.maxItems) {
      await this.evictLowPriorityMemories();
    }

    if (this.eventBus) {
      await this.eventBus.publish('memory:updated', {
        key: item.id,
        type: item.type,
        action: 'added'
      });
    }

    await this.saveToStorage();
  }

  public query(options: {
    type?: MemoryType;
    tags?: string[];
    startTime?: number;
    endTime?: number;
    limit?: number;
  }): MemoryItem[] {
    let result = [...this.memories];

    if (options.type !== undefined) {
      result = result.filter(m => m.type === options.type);
    }

    if (options.tags && options.tags.length > 0) {
      result = result.filter(m => 
        m.tags && options.tags!.some(tag => m.tags!.includes(tag))
      );
    }

    if (options.startTime !== undefined) {
      result = result.filter(m => m.timestamp >= options.startTime!);
    }
    if (options.endTime !== undefined) {
      result = result.filter(m => m.timestamp <= options.endTime!);
    }

    result.sort((a, b) => b.timestamp - a.timestamp);

    if (options.limit !== undefined) {
      result = result.slice(0, options.limit);
    }

    return result;
  }

  public getRecent(limit: number = 10): MemoryItem[] {
    return this.memories
      .slice(-limit)
      .reverse();
  }

  public getById(id: string): MemoryItem | null {
    const item = this.memories.find(m => m.id === id);
    return item || null;
  }

  public async delete(id: string): Promise<boolean> {
    const index = this.memories.findIndex(m => m.id === id);
    if (index === -1) {
      return false;
    }

    this.memories.splice(index, 1);

    if (this.eventBus) {
      await this.eventBus.publish('memory:updated', {
        key: id,
        action: 'deleted'
      });
    }

    await this.saveToStorage();
    return true;
  }

  public async clear(): Promise<void> {
    this.memories = [];
    this.memoryCounter = 0;

    if (this.eventBus) {
      await this.eventBus.publish('memory:cleared', {});
    }

    await this.saveToStorage();
  }

  public getItemsCount(): number {
    return this.memories.length;
  }

  public getStats(): Record<string, any> {
    const stats: Record<string, number> = {
      total: this.memories.length,
      maxItems: this.maxItems
    };

    Object.values(MemoryType).forEach(type => {
      stats[type] = this.memories.filter(m => m.type === type).length;
    });

    return stats;
  }

  private async evictLowPriorityMemories(): Promise<void> {
    this.memories.sort((a, b) => {
      if (a.priority !== b.priority) {
        return a.priority! - b.priority!;
      }
      return a.timestamp - b.timestamp;
    });

    const evictCount = Math.ceil(this.maxItems * 0.1);
    const evicted = this.memories.splice(0, evictCount);

    console.log(`[MemoryManager] 已淘汰 ${evicted.length} 条记忆`);

    if (this.eventBus) {
      await this.eventBus.publish('memory:evicted', {
        count: evicted.length,
        reason: 'capacity_limit'
      });
    }
  }

  public exportToJSON(): string {
    return JSON.stringify(this.memories, null, 2);
  }

  public importFromJSON(json: string): void {
    try {
      const items = JSON.parse(json) as MemoryItem[];
      this.memories = items;
      this.memoryCounter = items.length;
      console.log(`[MemoryManager] 已导入 ${items.length} 条记忆`);
      this.saveToStorage();
    } catch (error) {
      console.error('[MemoryManager] 导入记忆失败:', error);
    }
  }

  public setAutoSave(enabled: boolean): void {
    this.autoSave = enabled;
  }

  public async flush(): Promise<void> {
    await this.saveToStorage();
  }
}
