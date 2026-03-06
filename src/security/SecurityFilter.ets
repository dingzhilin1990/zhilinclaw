/**
 * 安全过滤器模块
 * 
 * 参考 IronClaw的"多层安全过滤"防止提示词注入
 * 
 * 核心特性：
 * - 输入验证和清理
 * - 提示词注入检测
 * - 输出过滤
 * - 敏感信息脱敏
 */

import { SecurityContext, SecurityLevel } from './SecurityContext';

/**
 * 安全检查结果
 */
export interface SecurityCheckResult {
  passed: boolean;
  riskLevel: RiskLevel;
  issues: SecurityIssue[];
  sanitizedInput?: string;
}

/**
 * 风险级别
 */
export enum RiskLevel {
  NONE = 0,
  LOW = 1,
  MEDIUM = 2,
  HIGH = 3,
  CRITICAL = 4
}

/**
 * 安全问题类型
 */
export enum SecurityIssueType {
  PROMPT_INJECTION = 'prompt_injection',
  XSS_ATTEMPT = 'xss_attempt',
  COMMAND_INJECTION = 'command_injection',
  SENSITIVE_DATA = 'sensitive_data',
  MALICIOUS_PATTERN = 'malicious_pattern',
  JAILBREAK_ATTEMPT = 'jailbreak_attempt'
}

/**
 * 安全问题
 */
export interface SecurityIssue {
  type: SecurityIssueType;
  severity: RiskLevel;
  description: string;
  pattern?: string;
  position?: number;
}

/**
 * 安全过滤器配置
 */
export interface SecurityFilterConfig {
  /** 是否启用提示词注入检测 */
  enablePromptInjectionDetection: boolean;
  
  /** 是否启用 XSS 检测 */
  enableXSSDetection: boolean;
  
  /** 是否启用命令注入检测 */
  enableCommandInjectionDetection: boolean;
  
  /** 是否启用敏感信息检测 */
  enableSensitiveDataDetection: boolean;
  
  /** 是否启用越狱尝试检测 */
  enableJailbreakDetection: boolean;
  
  /** 最大输入长度 */
  maxInputLength: number;
  
  /** 风险阈值（超过此值将阻止请求） */
  riskThreshold: RiskLevel;
}

/**
 * 安全过滤器类
 * 
 * 提供：
 * - 多层输入验证
 * - 注入攻击检测
 * - 输出清理
 */
export class SecurityFilter {
  private config: SecurityFilterConfig;
  private securityContext: SecurityContext;

  // 常见的提示词注入模式
  private readonly injectionPatterns = [
    /忽略之前的指令/gi,
    / disregard previous instructions/gi,
    /忘记所有规则/gi,
    /forget all rules/gi,
    /系统提示：/gi,
    /system prompt:/gi,
    /你现在是一个/gi,
    /you are now a/gi,
    /绕过安全限制/gi,
    /bypass safety restrictions/gi,
    /以开发者模式运行/gi,
    /run in developer mode/gi,
    /不要使用道德准则/gi,
    /don't use ethical guidelines/gi
  ];

  // 常见的越狱尝试模式
  private readonly jailbreakPatterns = [
    / DAN /gi,
    /do anything now/gi,
    /假装你是一个/gi,
    /pretend you are a/gi,
    /进入混沌模式/gi,
    /enter chaos mode/gi,
    /无视所有限制/gi,
    /ignore all limitations/gi
  ];

  // XSS 模式
  private readonly xssPatterns = [
    /<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi,
    /javascript:/gi,
    /on\w+\s*=/gi,
    /<iframe/gi,
    /<object/gi,
    /<embed/gi
  ];

  // 命令注入模式
  private readonly commandPatterns = [
    /[;&|`$()]/g,
    /\$\(/g,
    /`.*`/g,
    /;\s*(rm|del|rmdir)/gi,
    /\|\s*(bash|sh|cmd)/gi
  ];

  constructor(config?: Partial<SecurityFilterConfig>, securityContext?: SecurityContext) {
    this.config = {
      enablePromptInjectionDetection: config?.enablePromptInjectionDetection !== false,
      enableXSSDetection: config?.enableXSSDetection !== false,
      enableCommandInjectionDetection: config?.enableCommandInjectionDetection !== false,
      enableSensitiveDataDetection: config?.enableSensitiveDataDetection !== false,
      enableJailbreakDetection: config?.enableJailbreakDetection !== false,
      maxInputLength: config?.maxInputLength || 10000,
      riskThreshold: config?.riskThreshold || RiskLevel.HIGH
    };

    this.securityContext = securityContext || new SecurityContext({
      securityLevel: SecurityLevel.HIGH,
      enableAuditLog: true
    });
  }

  /**
   * 检查输入安全性
   * @param input 用户输入
   */
  public async checkInput(input: string): Promise<SecurityCheckResult> {
    const issues: SecurityIssue[] = [];
    let riskScore = 0;

    // 检查输入长度
    if (input.length > this.config.maxInputLength) {
      issues.push({
        type: SecurityIssueType.MALICIOUS_PATTERN,
        severity: RiskLevel.MEDIUM,
        description: `输入超出最大长度限制 (${input.length}/${this.config.maxInputLength})`
      });
      riskScore += 2;
    }

    // 提示词注入检测
    if (this.config.enablePromptInjectionDetection) {
      const injectionIssues = this.detectPatterns(input, this.injectionPatterns, SecurityIssueType.PROMPT_INJECTION);
      issues.push(...injectionIssues);
      riskScore += injectionIssues.length * 3;
    }

    // 越狱尝试检测
    if (this.config.enableJailbreakDetection) {
      const jailbreakIssues = this.detectPatterns(input, this.jailbreakPatterns, SecurityIssueType.JAILBREAK_ATTEMPT);
      issues.push(...jailbreakIssues);
      riskScore += jailbreakIssues.length * 4;
    }

    // XSS 检测
    if (this.config.enableXSSDetection) {
      const xssIssues = this.detectPatterns(input, this.xssPatterns, SecurityIssueType.XSS_ATTEMPT);
      issues.push(...xssIssues);
      riskScore += xssIssues.length * 3;
    }

    // 命令注入检测
    if (this.config.enableCommandInjectionDetection) {
      const cmdIssues = this.detectPatterns(input, this.commandPatterns, SecurityIssueType.COMMAND_INJECTION);
      issues.push(...cmdIssues);
      riskScore += cmdIssues.length * 2;
    }

    // 计算风险级别
    const riskLevel = this.calculateRiskLevel(riskScore);

    // 记录审计日志
    await this.securityContext.log({
      action: 'security_check',
      executor: 'SecurityFilter',
      securityLevel: SecurityLevel.HIGH,
      success: riskLevel < this.config.riskThreshold,
      details: {
        inputLength: input.length,
        issuesCount: issues.length,
        riskLevel: RiskLevel[riskLevel]
      }
    });

    return {
      passed: riskLevel < this.config.riskThreshold,
      riskLevel,
      issues,
      sanitizedInput: this.sanitizeInput(input)
    };
  }

  /**
   * 清理输出内容
   * @param output AI 生成的输出
   */
  public sanitizeOutput(output: string): string {
    let sanitized = output;

    // 移除潜在的脚本标签
    sanitized = sanitized.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '');

    // 移除潜在的危险 HTML
    sanitized = sanitized.replace(/<(iframe|object|embed|form|input)[^>]*>/gi, '');

    // 移除 javascript: 协议
    sanitized = sanitized.replace(/javascript:/gi, '');

    // 脱敏敏感信息
    if (this.config.enableSensitiveDataDetection) {
      sanitized = this.maskSensitiveData(sanitized);
    }

    return sanitized;
  }

  /**
   * 清理输入内容
   * @param input 用户输入
   */
  public sanitizeInput(input: string): string {
    let sanitized = input;

    // 移除 HTML 标签
    sanitized = sanitized.replace(/<[^>]*>/g, '');

    // 转义特殊字符
    sanitized = sanitized.replace(/[<>\"'&]/g, (char) => {
      const entities: Record<string, string> = {
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#39;',
        '&': '&amp;'
      };
      return entities[char] || char;
    });

    return sanitized;
  }

  /**
   * 检测模式匹配
   */
  private detectPatterns(
    input: string, 
    patterns: RegExp[], 
    issueType: SecurityIssueType
  ): SecurityIssue[] {
    const issues: SecurityIssue[] = [];

    for (const pattern of patterns) {
      const match = input.match(pattern);
      if (match) {
        issues.push({
          type: issueType,
          severity: RiskLevel.HIGH,
          description: `检测到可疑模式：${match[0].substring(0, 50)}...`,
          pattern: pattern.toString(),
          position: match.index
        });
      }
    }

    return issues;
  }

  /**
   * 计算风险级别
   */
  private calculateRiskLevel(score: number): RiskLevel {
    if (score === 0) return RiskLevel.NONE;
    if (score <= 2) return RiskLevel.LOW;
    if (score <= 5) return RiskLevel.MEDIUM;
    if (score <= 10) return RiskLevel.HIGH;
    return RiskLevel.CRITICAL;
  }

  /**
   * 脱敏敏感数据
   */
  private maskSensitiveData(text: string): string {
    let masked = text;

    // 脱敏邮箱地址
    masked = masked.replace(/\b[\w.-]+@[\w.-]+\.\w+\b/g, '[EMAIL_REDACTED]');

    // 脱敏电话号码（中国格式）
    masked = masked.replace(/(\+?86)?\s*1[3-9]\d{2}\s*\d{4}\s*\d{4}/g, '[PHONE_REDACTED]');

    // 脱敏身份证号
    masked = masked.replace(/\b\d{17}[\dXx]\b/g, '[ID_REDACTED]');

    // 脱敏银行卡号
    masked = masked.replace(/\b\d{4}\s*\d{4}\s*\d{4}\s*\d{4}\b/g, '[CARD_REDACTED]');

    // 脱敏 API 密钥（常见格式）
    masked = masked.replace(/\b(sk-[a-zA-Z0-9]{32,})\b/g, '[API_KEY_REDACTED]');
    masked = masked.replace(/\b(bearer\s+[a-zA-Z0-9._-]+)\b/gi, '[TOKEN_REDACTED]');

    return masked;
  }

  /**
   * 获取配置
   */
  public getConfig(): SecurityFilterConfig {
    return { ...this.config };
  }

  /**
   * 更新配置
   */
  public updateConfig(config: Partial<SecurityFilterConfig>): void {
    this.config = { ...this.config, ...config };
  }

  /**
   * 获取统计信息
   */
  public getStats(): Record<string, any> {
    return {
      enabledChecks: {
        promptInjection: this.config.enablePromptInjectionDetection,
        xss: this.config.enableXSSDetection,
        commandInjection: this.config.enableCommandInjectionDetection,
        sensitiveData: this.config.enableSensitiveDataDetection,
        jailbreak: this.config.enableJailbreakDetection
      },
      maxInputLength: this.config.maxInputLength,
      riskThreshold: RiskLevel[this.config.riskThreshold]
    };
  }
}
