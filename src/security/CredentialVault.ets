/**
 * 加密保险柜模块
 * 
 * 参考 IronClaw 的"加密保险柜管理凭证"理念
 * 
 * 核心特性：
 * - 敏感凭证加密存储
 * - 运行时动态注入（不暴露给工具代码）
 * - 访问控制和审计日志
 * - 自动过期和轮换机制
 */

import { SecurityContext, SecurityLevel } from './SecurityContext';

/**
 * 凭证类型
 */
export enum CredentialType {
  API_KEY = 'api_key',
  OAUTH_TOKEN = 'oauth_token',
  PASSWORD = 'password',
  PRIVATE_KEY = 'private_key',
  ACCESS_TOKEN = 'access_token',
  REFRESH_TOKEN = 'refresh_token'
}

/**
 * 凭证元数据
 */
export interface CredentialMetadata {
  id: string;
  name: string;
  type: CredentialType;
  createdAt: number;
  expiresAt?: number;
  lastUsedAt?: number;
  usageCount: number;
  tags: string[];
}

/**
 * 凭证接口（不包含实际值）
 */
export interface Credential extends CredentialMetadata {
  /** 加密后的值 */
  encryptedValue: string;
}

/**
 * 凭证访问策略
 */
export interface CredentialAccessPolicy {
  /** 允许访问的插件/技能列表 */
  allowedExecutors: string[];
  
  /** 是否需要额外验证 */
  requireVerification: boolean;
  
  /** 最大使用次数 */
  maxUsageCount?: number;
  
  /** 是否允许自动轮换 */
  enableAutoRotation: boolean;
}

/**
 * 加密保险柜类
 * 
 * 提供：
 * - 凭证加密存储
 * - 安全访问控制
 * - 使用审计
 * - 自动轮换
 */
export class CredentialVault {
  private credentials: Map<string, Credential> = new Map();
  private accessPolicies: Map<string, CredentialAccessPolicy> = new Map();
  private securityContext: SecurityContext;
  private encryptionKey: Uint8Array;

  constructor(encryptionKey: Uint8Array, securityContext?: SecurityContext) {
    if (encryptionKey.length !== 32) {
      throw new Error('加密密钥必须是 32 字节（256 位）');
    }
    
    this.encryptionKey = encryptionKey;
    this.securityContext = securityContext || new SecurityContext({
      securityLevel: SecurityLevel.CRITICAL,
      enableAuditLog: true
    });
  }

  /**
   * 存储凭证
   * @param name 凭证名称
   * @param type 凭证类型
   * @param value 凭证值（明文）
   * @param options 可选配置
   */
  public async store(
    name: string,
    type: CredentialType,
    value: string,
    options?: {
      expiresAt?: number;
      tags?: string[];
      accessPolicy?: Partial<CredentialAccessPolicy>;
    }
  ): Promise<string> {
    const id = `cred_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;

    // 加密凭证值
    const encryptedValue = await this.encrypt(value);

    const credential: Credential = {
      id,
      name,
      type,
      encryptedValue,
      createdAt: Date.now(),
      expiresAt: options?.expiresAt,
      usageCount: 0,
      tags: options?.tags || []
    };

    this.credentials.set(id, credential);

    // 设置访问策略
    if (options?.accessPolicy) {
      const policy: CredentialAccessPolicy = {
        allowedExecutors: options.accessPolicy.allowedExecutors || [],
        requireVerification: options.accessPolicy.requireVerification || false,
        enableAutoRotation: options.accessPolicy.enableAutoRotation || false,
        maxUsageCount: options.accessPolicy.maxUsageCount
      };
      this.accessPolicies.set(id, policy);
    }

    // 记录审计日志
    await this.securityContext.log({
      action: 'store_credential',
      executor: 'CredentialVault',
      securityLevel: SecurityLevel.CRITICAL,
      success: true,
      details: { credentialId: id, credentialName: name, type }
    });

    console.log(`[CredentialVault] 凭证已存储：${name} (${type})`);
    return id;
  }

  /**
   * 获取凭证值（解密后）
   * @param id 凭证 ID
   * @param executor 请求者（插件/技能名称）
   * @param context 验证上下文
   */
  public async get(
    id: string, 
    executor: string,
    context?: any
  ): Promise<string | null> {
    const credential = this.credentials.get(id);
    if (!credential) {
      await this.logAccess(id, executor, false, '凭证不存在');
      return null;
    }

    // 检查是否过期
    if (credential.expiresAt && Date.now() > credential.expiresAt) {
      await this.logAccess(id, executor, false, '凭证已过期');
      return null;
    }

    // 检查访问权限
    const policy = this.accessPolicies.get(id);
    if (policy) {
      if (policy.allowedExecutors.length > 0 && 
          !policy.allowedExecutors.includes(executor)) {
        await this.logAccess(id, executor, false, '无访问权限');
        return null;
      }

      if (policy.requireVerification) {
        // 需要额外验证（实际项目中应实现验证逻辑）
        console.log('[CredentialVault] 需要额外验证');
      }

      if (policy.maxUsageCount && credential.usageCount >= policy.maxUsageCount) {
        await this.logAccess(id, executor, false, '超过最大使用次数');
        return null;
      }
    }

    try {
      // 解密凭证值
      const value = await this.decrypt(credential.encryptedValue);

      // 更新使用统计
      credential.lastUsedAt = Date.now();
      credential.usageCount++;

      // 记录审计日志
      await this.securityContext.log({
        action: 'get_credential',
        executor,
        securityLevel: SecurityLevel.CRITICAL,
        success: true,
        details: { credentialId: id, credentialName: credential.name }
      });

      return value;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      await this.logAccess(id, executor, false, errorMessage);
      return null;
    }
  }

  /**
   * 删除凭证
   * @param id 凭证 ID
   */
  public async delete(id: string): Promise<boolean> {
    const credential = this.credentials.get(id);
    if (!credential) {
      return false;
    }

    this.credentials.delete(id);
    this.accessPolicies.delete(id);

    // 记录审计日志
    await this.securityContext.log({
      action: 'delete_credential',
      executor: 'CredentialVault',
      securityLevel: SecurityLevel.CRITICAL,
      success: true,
      details: { credentialId: id, credentialName: credential.name }
    });

    console.log(`[CredentialVault] 凭证已删除：${credential.name}`);
    return true;
  }

  /**
   * 列出所有凭证（不包含值）
   */
  public list(): CredentialMetadata[] {
    return Array.from(this.credentials.values()).map(cred => ({
      id: cred.id,
      name: cred.name,
      type: cred.type,
      createdAt: cred.createdAt,
      expiresAt: cred.expiresAt,
      lastUsedAt: cred.lastUsedAt,
      usageCount: cred.usageCount,
      tags: cred.tags
    }));
  }

  /**
   * 轮换凭证（生成新的凭证值）
   * @param id 凭证 ID
   * @param newValue 新凭证值
   */
  public async rotate(id: string, newValue: string): Promise<boolean> {
    const credential = this.credentials.get(id);
    if (!credential) {
      return false;
    }

    // 加密新值
    credential.encryptedValue = await this.encrypt(newValue);
    credential.createdAt = Date.now();
    credential.usageCount = 0;

    // 记录审计日志
    await this.securityContext.log({
      action: 'rotate_credential',
      executor: 'CredentialVault',
      securityLevel: SecurityLevel.CRITICAL,
      success: true,
      details: { credentialId: id, credentialName: credential.name }
    });

    console.log(`[CredentialVault] 凭证已轮换：${credential.name}`);
    return true;
  }

  /**
   * 清理过期凭证
   */
  public async cleanupExpired(): Promise<number> {
    const now = Date.now();
    let count = 0;

    for (const [id, credential] of this.credentials.entries()) {
      if (credential.expiresAt && now > credential.expiresAt) {
        await this.delete(id);
        count++;
      }
    }

    console.log(`[CredentialVault] 已清理 ${count} 个过期凭证`);
    return count;
  }

  /**
   * 加密数据
   */
  private async encrypt(plaintext: string): Promise<string> {
    // 实际项目中应使用 OHOS 的 Crypto Framework
    // 这里仅作示例，使用简单的 Base64 编码
    console.log('[CredentialVault] 加密数据...');
    
    // 模拟加密（实际应使用 AES-256-GCM 等强加密算法）
    const encoder = new TextEncoder();
    const data = encoder.encode(plaintext);
    
    // 实际项目中应使用：
    // import crypto from '@ohos.security.huks';
    // 进行真正的加密
    
    return btoa(String.fromCharCode(...data));
  }

  /**
   * 解密数据
   */
  private async decrypt(ciphertext: string): Promise<string> {
    // 实际项目中应使用 OHOS 的 Crypto Framework
    console.log('[CredentialVault] 解密数据...');
    
    // 模拟解密
    const decoded = atob(ciphertext);
    return decoded;
  }

  /**
   * 记录访问日志
   */
  private async logAccess(
    id: string, 
    executor: string, 
    success: boolean, 
    reason?: string
  ): Promise<void> {
    await this.securityContext.log({
      action: 'access_credential',
      executor,
      securityLevel: SecurityLevel.CRITICAL,
      success,
      details: { credentialId: id },
      error: reason
    });
  }

  /**
   * 获取凭证统计信息
   */
  public getStats(): Record<string, any> {
    const credentials = Array.from(this.credentials.values());
    
    return {
      total: credentials.length,
      byType: Object.values(CredentialType).reduce((acc, type) => {
        acc[type] = credentials.filter(c => c.type === type).length;
        return acc;
      }, {} as Record<string, number>),
      expired: credentials.filter(c => 
        c.expiresAt && Date.now() > c.expiresAt
      ).length,
      neverUsed: credentials.filter(c => c.usageCount === 0).length
    };
  }
}
