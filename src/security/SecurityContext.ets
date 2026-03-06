/**
 * 安全上下文模块
 * 
 * 定义安全级别、策略和审计日志
 */

/**
 * 安全级别枚举
 */
export enum SecurityLevel {
  /** 无限制 - 仅用于完全信任的内部操作 */
  NONE = 0,
  
  /** 低 - 只读操作，无敏感数据访问 */
  LOW = 1,
  
  /** 中 - 有限的写操作，需要基本验证 */
  MEDIUM = 2,
  
  /** 高 - 敏感操作，需要严格验证和审计 */
  HIGH = 3,
  
  /** 最高 - 关键安全操作，需要多重验证 */
  CRITICAL = 4
}

/**
 * 安全策略接口
 */
export interface SecurityPolicy {
  /** 允许的操作列表 */
  allowedActions: string[];
  
  /** 禁止的操作列表 */
  deniedActions: string[];
  
  /** 需要的权限 */
  requiredPermissions: string[];
  
  /** 最大执行时间（毫秒） */
  maxExecutionTime?: number;
  
  /** 是否启用审计日志 */
  enableAuditLog: boolean;
  
  /** 安全级别 */
  securityLevel: SecurityLevel;
}

/**
 * 审计日志条目
 */
export interface AuditLogEntry {
  /** 日志 ID */
  id: string;
  
  /** 时间戳 */
  timestamp: number;
  
  /** 操作类型 */
  action: string;
  
  /** 执行者（插件/技能名称） */
  executor: string;
  
  /** 安全级别 */
  securityLevel: SecurityLevel;
  
  /** 是否成功 */
  success: boolean;
  
  /** 详细信息 */
  details?: any;
  
  /** 错误信息 */
  error?: string;
}

/**
 * 安全上下文类
 * 
 * 提供：
 * - 安全策略管理
 * - 权限检查
 * - 审计日志记录
 */
export class SecurityContext {
  private policy: SecurityPolicy;
  private auditLog: AuditLogEntry[] = [];
  private logCounter: number = 0;

  constructor(policy: Partial<SecurityPolicy> = {}) {
    this.policy = {
      allowedActions: policy.allowedActions || [],
      deniedActions: policy.deniedActions || [],
      requiredPermissions: policy.requiredPermissions || [],
      maxExecutionTime: policy.maxExecutionTime || 30000, // 默认 30 秒
      enableAuditLog: policy.enableAuditLog !== false,
      securityLevel: policy.securityLevel || SecurityLevel.MEDIUM
    };
  }

  /**
   * 检查操作是否被允许
   * @param action 操作名称
   * @param permissions 当前权限列表
   */
  public checkPermission(action: string, permissions: string[]): boolean {
    // 首先检查是否被明确禁止
    if (this.policy.deniedActions.includes(action)) {
      return false;
    }

    // 检查是否在允许列表中（如果有设置）
    if (this.policy.allowedActions.length > 0) {
      if (!this.policy.allowedActions.includes(action)) {
        return false;
      }
    }

    // 检查是否需要特定权限
    for (const required of this.policy.requiredPermissions) {
      if (!permissions.includes(required)) {
        return false;
      }
    }

    return true;
  }

  /**
   * 记录审计日志
   * @param entry 日志条目信息
   */
  public async log(entry: Omit<AuditLogEntry, 'id' | 'timestamp'>): Promise<void> {
    if (!this.policy.enableAuditLog) {
      return;
    }

    const logEntry: AuditLogEntry = {
      ...entry,
      id: `audit_${++this.logCounter}`,
      timestamp: Date.now()
    };

    this.auditLog.push(logEntry);

    // 在控制台输出（实际项目中应该写入持久化存储）
    console.log(`[SecurityAudit] ${logEntry.id} - ${logEntry.action} - ${logEntry.success ? 'SUCCESS' : 'FAILED'}`);
  }

  /**
   * 获取审计日志
   * @param limit 返回数量限制
   */
  public getAuditLog(limit: number = 100): AuditLogEntry[] {
    return this.auditLog.slice(-limit).reverse();
  }

  /**
   * 获取安全策略
   */
  public getPolicy(): SecurityPolicy {
    return { ...this.policy };
  }

  /**
   * 更新安全策略
   * @param policy 新策略
   */
  public updatePolicy(policy: Partial<SecurityPolicy>): void {
    this.policy = { ...this.policy, ...policy };
  }

  /**
   * 清除审计日志
   */
  public clearAuditLog(): void {
    this.auditLog = [];
    this.logCounter = 0;
  }

  /**
   * 导出审计日志为 JSON
   */
  public exportAuditLog(): string {
    return JSON.stringify(this.auditLog, null, 2);
  }
}
