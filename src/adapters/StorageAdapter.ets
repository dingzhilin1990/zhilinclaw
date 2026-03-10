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

export interface StorageConfig {
  type: 'preferences' | 'rdb' | 'file';
  name: string;
  path?: string;
}

export abstract class StorageAdapter {
  protected config: StorageConfig;

  constructor(config: StorageConfig) {
    this.config = config;
  }

  public abstract save(key: string, value: any): Promise<void>;
  public abstract load(key: string): Promise<any>;
  public abstract delete(key: string): Promise<void>;
  public abstract has(key: string): Promise<boolean>;
  public abstract clear(): Promise<void>;
}

export class PreferencesStorageAdapter extends StorageAdapter {
  private cache: Map<string, string> = new Map();
  private preferences: any = null;

  async save(key: string, value: any): Promise<void> {
    const stringValue = JSON.stringify(value);
    this.cache.set(key, stringValue);
    console.log(`[PreferencesStorage] 保存：${key}`);
    
    try {
      if (this.preferences) {
        await this.preferences.put(key, stringValue);
        await this.preferences.flush();
      }
    } catch (error) {
      console.warn('[PreferencesStorage] 持久化存储失败，使用内存缓存:', error);
    }
  }

  async load(key: string): Promise<any> {
    const value = this.cache.get(key);
    if (value === undefined) {
      try {
        if (this.preferences) {
          const stored = await this.preferences.get(key, null);
          if (stored !== null) {
            this.cache.set(key, stored);
            return JSON.parse(stored);
          }
        }
      } catch (error) {
        console.warn('[PreferencesStorage] 读取失败:', error);
      }
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
    
    try {
      if (this.preferences) {
        await this.preferences.delete(key);
        await this.preferences.flush();
      }
    } catch (error) {
      console.warn('[PreferencesStorage] 删除失败:', error);
    }
  }

  async has(key: string): Promise<boolean> {
    if (this.cache.has(key)) return true;
    
    try {
      if (this.preferences) {
        const value = await this.preferences.get(key, null);
        return value !== null;
      }
    } catch (error) {
      console.warn('[PreferencesStorage] 检查失败:', error);
    }
    return false;
  }

  async clear(): Promise<void> {
    this.cache.clear();
    console.log('[PreferencesStorage] 清空所有数据');
    
    try {
      if (this.preferences) {
        await this.preferences.clear();
        await this.preferences.flush();
      }
    } catch (error) {
      console.warn('[PreferencesStorage] 清空失败:', error);
    }
  }

  public setPreferences(prefs: any): void {
    this.preferences = prefs;
  }
}

export class FileStorageAdapter extends StorageAdapter {
  private cache: Map<string, string> = new Map();
  private fs: any = null;

  async save(key: string, value: any): Promise<void> {
    const filePath = `${this.config.path}/${key}.json`;
    const stringValue = JSON.stringify(value, null, 2);
    this.cache.set(key, stringValue);
    console.log(`[FileStorage] 保存到：${filePath}`);
    
    try {
      if (this.fs) {
        await this.fs.writeText(filePath, stringValue);
      }
    } catch (error) {
      console.warn('[FileStorage] 文件写入失败，使用内存缓存:', error);
    }
  }

  async load(key: string): Promise<any> {
    const cached = this.cache.get(key);
    if (cached !== undefined) {
      try {
        return JSON.parse(cached);
      } catch {
        return cached;
      }
    }
    
    const filePath = `${this.config.path}/${key}.json`;
    console.log(`[FileStorage] 从以下路径加载：${filePath}`);
    
    try {
      if (this.fs) {
        const content = await this.fs.readText(filePath);
        this.cache.set(key, content);
        return JSON.parse(content);
      }
    } catch (error) {
      console.warn('[FileStorage] 文件读取失败:', error);
    }
    
    return null;
  }

  async delete(key: string): Promise<void> {
    const filePath = `${this.config.path}/${key}.json`;
    this.cache.delete(key);
    console.log(`[FileStorage] 删除：${filePath}`);
    
    try {
      if (this.fs) {
        await this.fs.unlink(filePath);
      }
    } catch (error) {
      console.warn('[FileStorage] 文件删除失败:', error);
    }
  }

  async has(key: string): Promise<boolean> {
    if (this.cache.has(key)) return true;
    
    const filePath = `${this.config.path}/${key}.json`;
    try {
      if (this.fs) {
        return await this.fs.access(filePath);
      }
    } catch (error) {
      console.warn('[FileStorage] 文件检查失败:', error);
    }
    return false;
  }

  async clear(): Promise<void> {
    this.cache.clear();
    console.log('[FileStorage] 清空所有文件');
    
    try {
      if (this.fs && this.config.path) {
        const files = await this.fs.listDir(this.config.path);
        for (const file of files) {
          if (file.endsWith('.json')) {
            await this.fs.unlink(`${this.config.path}/${file}`);
          }
        }
      }
    } catch (error) {
      console.warn('[FileStorage] 清空目录失败:', error);
    }
  }

  public setFileSystem(fs: any): void {
    this.fs = fs;
  }
}

export class StorageFactory {
  public static create(config: StorageConfig): StorageAdapter {
    switch (config.type) {
      case 'preferences':
        return new PreferencesStorageAdapter(config);
      case 'file':
        return new FileStorageAdapter(config);
      case 'rdb':
        return new PreferencesStorageAdapter(config);
      default:
        throw new Error(`不支持的存储类型：${config.type}`);
    }
  }
}
