/**
 * 接口适配层 - 存储适配器
 * 
 * 提供统一的本地存储接口，支持多种存储方式：
 * - Preferences（轻量级键值存储）
 * - RDB（关系型数据库）
 * - File（文件存储）
 * 
 * 遵循本地优先原则，所有数据存储在本地
 */

/**
 * 存储配置
 */
export interface StorageConfig {
  type: 'preferences' | 'rdb' | 'file';
  name: string;
  path?: string;
}

/**
 * 存储适配器基类
 */
export abstract class StorageAdapter {
  protected config: StorageConfig;

  constructor(config: StorageConfig) {
    this.config = config;
  }

  /**
   * 保存数据
   * @param key 键
   * @param value 值
   */
  public abstract save(key: string, value: any): Promise<void>;

  /**
   * 读取数据
   * @param key 键
   */
  public abstract load(key: string): Promise<any>;

  /**
   * 删除数据
   * @param key 键
   */
  public abstract delete(key: string): Promise<void>;

  /**
   * 检查键是否存在
   * @param key 键
   */
  public abstract has(key: string): Promise<boolean>;

  /**
   * 清空存储
   */
  public abstract clear(): Promise<void>;
}

/**
 * Preferences 存储适配器（轻量级键值存储）
 */
export class PreferencesStorageAdapter extends StorageAdapter {
  private cache: Map<string, string> = new Map();

  async save(key: string, value: any): Promise<void> {
    const stringValue = JSON.stringify(value);
    this.cache.set(key, stringValue);
    console.log(`[PreferencesStorage] 保存：${key}`);
    
    // 实际项目中应调用 OHOS Preferences API
    // await preferences.getPreferences().then(pref => {
    //   pref.put(key, stringValue);
    //   await pref.flush();
    // });
  }

  async load(key: string): Promise<any> {
    const value = this.cache.get(key);
    if (value === undefined) {
      return null;
    }
    try {
      return JSON.parse(value);
    } catch {
      return value;
    }
  }

  async delete(key: string): Promise<void> {
    this.cache.delete(key);
    console.log(`[PreferencesStorage] 删除：${key}`);
  }

  async has(key: string): Promise<boolean> {
    return this.cache.has(key);
  }

  async clear(): Promise<void> {
    this.cache.clear();
    console.log('[PreferencesStorage] 清空所有数据');
  }
}

/**
 * 文件存储适配器
 */
export class FileStorageAdapter extends StorageAdapter {
  async save(key: string, value: any): Promise<void> {
    const filePath = `${this.config.path}/${key}`;
    console.log(`[FileStorage] 保存到：${filePath}`);
    
    // 实际项目中应使用 OHOS 文件系统 API
    // const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
    // fs.write(file, JSON.stringify(value));
    // fs.close(file);
  }

  async load(key: string): Promise<any> {
    const filePath = `${this.config.path}/${key}`;
    console.log(`[FileStorage] 从以下路径加载：${filePath}`);
    
    // 实际项目中应使用 OHOS 文件系统 API
    // const content = fs.readTextFileSync(filePath);
    // return JSON.parse(content);
    
    return null;
  }

  async delete(key: string): Promise<void> {
    const filePath = `${this.config.path}/${key}`;
    console.log(`[FileStorage] 删除：${filePath}`);
    
    // 实际项目中应使用 OHOS 文件系统 API
    // fs.unlinkSync(filePath);
  }

  async has(key: string): Promise<boolean> {
    const filePath = `${this.config.path}/${key}`;
    
    // 实际项目中应检查文件是否存在
    // return fs.accessSync(filePath);
    
    return false;
  }

  async clear(): Promise<void> {
    console.log('[FileStorage] 清空所有文件');
    
    // 实际项目中应删除目录下所有文件
  }
}

/**
 * 存储工厂
 */
export class StorageFactory {
  /**
   * 创建存储适配器
   * @param config 存储配置
   */
  public static create(config: StorageConfig): StorageAdapter {
    switch (config.type) {
      case 'preferences':
        return new PreferencesStorageAdapter(config);
      case 'file':
        return new FileStorageAdapter(config);
      case 'rdb':
        // RDB 适配器实现类似
        return new PreferencesStorageAdapter(config);
      default:
        throw new Error(`不支持的存储类型：${config.type}`);
    }
  }
}
