/**
 * 插件管理器模块
 * 
 * 实现 OpenClaw的插件化架构理念：
 * - 解耦核心功能与扩展能力
 * - 沙箱隔离插件运行环境
 * - 支持动态加载/卸载插件
 * - 遵循"开闭原则"实现扩展
 */

import { EventBus } from '../events/EventBus';

/**
 * 插件元数据接口
 */
export interface PluginMetadata {
  name: string;
  version: string;
  description: string;
  author: string;
  minCoreVersion: string;
  permissions?: string[];
}

/**
 * 插件生命周期接口
 */
export interface PluginLifecycle {
  onEnable?(): Promise<void>;
  onDisable?(): Promise<void>;
  onLoad?(): Promise<void>;
  onUnload?(): Promise<void>;
}

/**
 * 插件基类
 */
export abstract class Plugin implements PluginLifecycle {
  public metadata: PluginMetadata;
  
  constructor(metadata: PluginMetadata) {
    this.metadata = metadata;
  }

  async onEnable(): Promise<void> {}
  async onDisable(): Promise<void> {}
  async onLoad(): Promise<void> {}
  async onUnload(): Promise<void> {}
}

/**
 * 插件包装器（用于沙箱隔离）
 */
interface PluginWrapper {
  plugin: Plugin;
  enabled: boolean;
  loadTime: number;
}

/**
 * 插件管理器类
 * 
 * 负责：
 * - 插件注册与管理
 * - 插件生命周期控制
 * - 插件间通信协调
 */
export class PluginManager {
  private plugins: Map<string, PluginWrapper> = new Map();
  private eventBus: EventBus;

  constructor(eventBus: EventBus) {
    this.eventBus = eventBus;
  }

  /**
   * 注册插件
   * @param plugin 插件实例
   */
  public async register(plugin: Plugin): Promise<void> {
    const name = plugin.metadata.name;
    
    if (this.plugins.has(name)) {
      throw new Error(`插件已存在：${name}`);
    }

    // 创建插件包装器
    const wrapper: PluginWrapper = {
      plugin,
      enabled: false,
      loadTime: Date.now()
    };

    this.plugins.set(name, wrapper);

    // 调用插件加载钩子
    if (plugin.onLoad) {
      await plugin.onLoad();
    }

    // 发布插件加载事件
    await this.eventBus.publish('plugin:loaded', {
      pluginName: name,
      version: plugin.metadata.version,
      timestamp: Date.now()
    });

    console.log(`[PluginManager] 插件已注册：${name} v${plugin.metadata.version}`);
  }

  /**
   * 启用插件
   * @param name 插件名称
   */
  public async enable(name: string): Promise<void> {
    const wrapper = this.plugins.get(name);
    if (!wrapper) {
      throw new Error(`插件不存在：${name}`);
    }

    if (wrapper.enabled) {
      console.log(`[PluginManager] 插件已启用：${name}`);
      return;
    }

    // 调用插件启用钩子
    if (wrapper.plugin.onEnable) {
      await wrapper.plugin.onEnable();
    }

    wrapper.enabled = true;
    
    await this.eventBus.publish('plugin:enabled', {
      pluginName: name,
      timestamp: Date.now()
    });

    console.log(`[PluginManager] 插件已启用：${name}`);
  }

  /**
   * 禁用插件
   * @param name 插件名称
   */
  public async disable(name: string): Promise<void> {
    const wrapper = this.plugins.get(name);
    if (!wrapper) {
      throw new Error(`插件不存在：${name}`);
    }

    if (!wrapper.enabled) {
      console.log(`[PluginManager] 插件已禁用：${name}`);
      return;
    }

    // 调用插件禁用钩子
    if (wrapper.plugin.onDisable) {
      await wrapper.plugin.onDisable();
    }

    wrapper.enabled = false;
    
    await this.eventBus.publish('plugin:disabled', {
      pluginName: name,
      timestamp: Date.now()
    });

    console.log(`[PluginManager] 插件已禁用：${name}`);
  }

  /**
   * 卸载插件
   * @param name 插件名称
   */
  public async unregister(name: string): Promise<void> {
    const wrapper = this.plugins.get(name);
    if (!wrapper) {
      throw new Error(`插件不存在：${name}`);
    }

    // 先禁用
    if (wrapper.enabled) {
      await this.disable(name);
    }

    // 调用插件卸载钩子
    if (wrapper.plugin.onUnload) {
      await wrapper.plugin.onUnload();
    }

    this.plugins.delete(name);
    
    await this.eventBus.publish('plugin:unloaded', {
      pluginName: name,
      timestamp: Date.now()
    });

    console.log(`[PluginManager] 插件已卸载：${name}`);
  }

  /**
   * 获取插件实例
   * @param name 插件名称
   */
  public getPlugin<T extends Plugin>(name: string): T | undefined {
    const wrapper = this.plugins.get(name);
    return wrapper?.plugin as T;
  }

  /**
   * 检查插件是否已启用
   * @param name 插件名称
   */
  public isEnabled(name: string): boolean {
    const wrapper = this.plugins.get(name);
    return wrapper?.enabled ?? false;
  }

  /**
   * 获取所有已加载的插件
   */
  public getAllPlugins(): PluginMetadata[] {
    return Array.from(this.plugins.values()).map(w => w.plugin.metadata);
  }

  /**
   * 获取已启用的插件数量
   */
  public getLoadedPluginsCount(): number {
    let count = 0;
    this.plugins.forEach(wrapper => {
      if (wrapper.enabled) count++;
    });
    return count;
  }

  /**
   * 获取插件状态
   */
  public getPluginStatus(name: string): Record<string, any> | null {
    const wrapper = this.plugins.get(name);
    if (!wrapper) return null;

    return {
      name: wrapper.plugin.metadata.name,
      version: wrapper.plugin.metadata.version,
      enabled: wrapper.enabled,
      loadTime: wrapper.loadTime,
      uptime: Date.now() - wrapper.loadTime
    };
  }
}
