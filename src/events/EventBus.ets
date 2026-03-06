/**
 * 事件总线模块
 * 
 * 基于发布 - 订阅模式实现组件间解耦通信
 * 遵循 OpenClaw的"发布 - 订阅事件模型"与"沙箱隔离"设计思想
 */

/**
 * 事件处理器类型
 */
export type EventHandler = (data: any) => void | Promise<void>;

/**
 * 事件订阅描述
 */
interface Subscription {
  id: string;
  handler: EventHandler;
  once: boolean;
}

/**
 * 事件总线类
 * 
 * 提供：
 * - 事件订阅/发布
 * - 一次性事件监听
 * - 事件取消订阅
 * - 异步事件处理
 */
export class EventBus {
  private subscribers: Map<string, Subscription[]> = new Map();
  private subscriptionCounter: number = 0;

  /**
   * 订阅事件
   * @param event 事件名称
   * @param handler 事件处理器
   * @returns 订阅 ID，用于取消订阅
   */
  public subscribe(event: string, handler: EventHandler): string {
    if (!this.subscribers.has(event)) {
      this.subscribers.set(event, []);
    }

    const id = `sub_${++this.subscriptionCounter}`;
    const subscription: Subscription = {
      id,
      handler,
      once: false
    };

    this.subscribers.get(event)!.push(subscription);
    return id;
  }

  /**
   * 订阅一次性事件（触发后自动取消订阅）
   * @param event 事件名称
   * @param handler 事件处理器
   * @returns 订阅 ID
   */
  public subscribeOnce(event: string, handler: EventHandler): string {
    if (!this.subscribers.has(event)) {
      this.subscribers.set(event, []);
    }

    const id = `sub_once_${++this.subscriptionCounter}`;
    const subscription: Subscription = {
      id,
      handler,
      once: true
    };

    this.subscribers.get(event)!.push(subscription);
    return id;
  }

  /**
   * 取消订阅
   * @param event 事件名称
   * @param subscriptionId 订阅 ID
   */
  public unsubscribe(event: string, subscriptionId: string): void {
    const subs = this.subscribers.get(event);
    if (!subs) return;

    const index = subs.findIndex(s => s.id === subscriptionId);
    if (index !== -1) {
      subs.splice(index, 1);
    }

    // 清理空数组
    if (subs.length === 0) {
      this.subscribers.delete(event);
    }
  }

  /**
   * 发布事件
   * @param event 事件名称
   * @param data 事件数据
   */
  public async publish(event: string, data?: any): Promise<void> {
    const subs = this.subscribers.get(event);
    if (!subs) return;

    // 并行执行所有处理器
    const promises = subs.map(async (subscription) => {
      try {
        await subscription.handler(data);
      } catch (error) {
        console.error(`[EventBus] 事件处理器错误 [${event}]:`, error);
      }
    });

    await Promise.all(promises);

    // 清理一次性订阅
    const remainingSubs = subs.filter(s => !s.once);
    if (remainingSubs.length === 0) {
      this.subscribers.delete(event);
    } else {
      this.subscribers.set(event, remainingSubs);
    }
  }

  /**
   * 同步发布事件（不等待处理器完成）
   * @param event 事件名称
   * @param data 事件数据
   */
  public publishSync(event: string, data?: any): void {
    const subs = this.subscribers.get(event);
    if (!subs) return;

    subs.forEach(subscription => {
      try {
        subscription.handler(data);
      } catch (error) {
        console.error(`[EventBus] 事件处理器错误 [${event}]:`, error);
      }
    });

    // 清理一次性订阅
    const remainingSubs = subs.filter(s => !s.once);
    if (remainingSubs.length === 0) {
      this.subscribers.delete(event);
    } else {
      this.subscribers.set(event, remainingSubs);
    }
  }

  /**
   * 获取事件的订阅者数量
   * @param event 事件名称
   */
  public getSubscriberCount(event: string): number {
    const subs = this.subscribers.get(event);
    return subs ? subs.length : 0;
  }

  /**
   * 清空所有订阅
   */
  public clear(): void {
    this.subscribers.clear();
    this.subscriptionCounter = 0;
  }

  /**
   * 获取所有已注册的事件
   */
  public getAllEvents(): string[] {
    return Array.from(this.subscribers.keys());
  }
}
