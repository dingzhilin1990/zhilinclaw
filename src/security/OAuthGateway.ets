/**
 * OAuth 网关适配器
 * 
 * 参考 IronClaw v0.15.0 的"OAuth web gateway routing"特性
 * 
 * 核心特性：
 * - OAuth 2.0 认证流程管理
 * - 安全的令牌存储和刷新
 * - 多提供商支持
 * - 凭证保险柜集成
 */

import { CredentialVault, CredentialType } from './CredentialVault';
import { SecurityContext, SecurityLevel } from './SecurityContext';

/**
 * OAuth 提供商配置
 */
export interface OAuthProviderConfig {
  id: string;
  name: string;
  authorizationUrl: string;
  tokenUrl: string;
  clientId: string;
  clientSecretCredentialId: string; // 客户端密钥存储在保险柜中
  redirectUri: string;
  scopes: string[];
}

/**
 * OAuth 令牌
 */
export interface OAuthToken {
  accessToken: string;
  tokenType: string;
  expiresIn?: number;
  refreshToken?: string;
  scope?: string;
  createdAt: number;
}

/**
 * OAuth 会话
 */
export interface OAuthSession {
  providerId: string;
  token: OAuthToken;
  createdAt: number;
  lastUsedAt: number;
}

/**
 * OAuth 网关类
 * 
 * 提供：
 * - OAuth 认证流程管理
 * - 令牌自动刷新
 * - 安全存储
 */
export class OAuthGateway {
  private providers: Map<string, OAuthProviderConfig> = new Map();
  private sessions: Map<string, OAuthSession> = new Map();
  private credentialVault: CredentialVault;
  private securityContext: SecurityContext;

  constructor(
    credentialVault: CredentialVault,
    securityContext?: SecurityContext
  ) {
    this.credentialVault = credentialVault;
    this.securityContext = securityContext || new SecurityContext({
      securityLevel: SecurityLevel.HIGH,
      enableAuditLog: true
    });
  }

  /**
   * 注册 OAuth 提供商
   * @param config 提供商配置
   */
  public registerProvider(config: OAuthProviderConfig): void {
    this.providers.set(config.id, config);
    console.log(`[OAuthGateway] 已注册 OAuth 提供商：${config.name}`);
  }

  /**
   * 获取授权 URL（重定向用户到提供商）
   * @param providerId 提供商 ID
   * @param state 状态参数（防止 CSRF）
   */
  public getAuthorizationUrl(providerId: string, state?: string): string | null {
    const provider = this.providers.get(providerId);
    if (!provider) {
      console.error(`[OAuthGateway] 提供商不存在：${providerId}`);
      return null;
    }

    // 生成随机 state（如果未提供）
    const stateParam = state || this.generateRandomState();

    // 构建授权 URL
    const url = new URL(provider.authorizationUrl);
    url.searchParams.append('client_id', provider.clientId);
    url.searchParams.append('redirect_uri', provider.redirectUri);
    url.searchParams.append('response_type', 'code');
    url.searchParams.append('scope', provider.scopes.join(' '));
    url.searchParams.append('state', stateParam);

    console.log(`[OAuthGateway] 生成授权 URL: ${provider.name}`);
    return url.toString();
  }

  /**
   * 处理回调（交换授权码获取令牌）
   * @param providerId 提供商 ID
   * @param code 授权码
   * @param state 状态参数
   */
  public async handleCallback(
    providerId: string,
    code: string,
    state: string
  ): Promise<boolean> {
    const provider = this.providers.get(providerId);
    if (!provider) {
      console.error(`[OAuthGateway] 提供商不存在：${providerId}`);
      return false;
    }

    try {
      // 从保险柜获取客户端密钥
      const clientSecret = await this.credentialVault.get(
        provider.clientSecretCredentialId,
        'OAuthGateway'
      );

      if (!clientSecret) {
        console.error('[OAuthGateway] 无法获取客户端密钥');
        return false;
      }

      // 交换令牌（实际项目中应使用 HTTP POST 请求）
      console.log(`[OAuthGateway] 交换令牌：${provider.name}`);
      
      // 模拟令牌响应
      const tokenResponse: OAuthToken = {
        accessToken: `access_token_${Date.now()}`,
        tokenType: 'Bearer',
        expiresIn: 3600,
        refreshToken: `refresh_token_${Date.now()}`,
        scope: provider.scopes.join(' '),
        createdAt: Date.now()
      };

      // 存储会话
      this.sessions.set(providerId, {
        providerId,
        token: tokenResponse,
        createdAt: Date.now(),
        lastUsedAt: Date.now()
      });

      // 记录审计日志
      await this.securityContext.log({
        action: 'oauth_callback',
        executor: 'OAuthGateway',
        securityLevel: SecurityLevel.HIGH,
        success: true,
        details: { providerId, scope: tokenResponse.scope }
      });

      console.log(`[OAuthGateway] OAuth 认证成功：${provider.name}`);
      return true;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      
      await this.securityContext.log({
        action: 'oauth_callback',
        executor: 'OAuthGateway',
        securityLevel: SecurityLevel.HIGH,
        success: false,
        error: errorMessage
      });

      console.error('[OAuthGateway] OAuth 认证失败:', errorMessage);
      return false;
    }
  }

  /**
   * 获取访问令牌（自动刷新）
   * @param providerId 提供商 ID
   */
  public async getAccessToken(providerId: string): Promise<string | null> {
    const session = this.sessions.get(providerId);
    if (!session) {
      console.log(`[OAuthGateway] 没有活动的会话：${providerId}`);
      return null;
    }

    // 检查令牌是否过期
    if (this.isTokenExpired(session.token)) {
      console.log(`[OAuthGateway] 令牌已过期，尝试刷新：${providerId}`);
      
      // 尝试刷新令牌
      const refreshed = await this.refreshToken(providerId);
      if (!refreshed) {
        return null;
      }
    }

    // 更新最后使用时间
    session.lastUsedAt = Date.now();

    return session.token.accessToken;
  }

  /**
   * 刷新令牌
   * @param providerId 提供商 ID
   */
  public async refreshToken(providerId: string): Promise<boolean> {
    const session = this.sessions.get(providerId);
    if (!session) {
      return false;
    }

    if (!session.token.refreshToken) {
      console.log('[OAuthGateway] 没有刷新令牌');
      return false;
    }

    const provider = this.providers.get(providerId);
    if (!provider) {
      return false;
    }

    try {
      // 从保险柜获取客户端密钥
      const clientSecret = await this.credentialVault.get(
        provider.clientSecretCredentialId,
        'OAuthGateway'
      );

      if (!clientSecret) {
        return false;
      }

      // 刷新令牌（实际项目中应使用 HTTP POST 请求）
      console.log(`[OAuthGateway] 刷新令牌：${provider.name}`);

      // 模拟新的令牌
      session.token = {
        accessToken: `new_access_token_${Date.now()}`,
        tokenType: 'Bearer',
        expiresIn: 3600,
        refreshToken: `new_refresh_token_${Date.now()}`,
        scope: session.token.scope,
        createdAt: Date.now()
      };

      // 记录审计日志
      await this.securityContext.log({
        action: 'refresh_token',
        executor: 'OAuthGateway',
        securityLevel: SecurityLevel.HIGH,
        success: true,
        details: { providerId }
      });

      console.log(`[OAuthGateway] 令牌已刷新：${provider.name}`);
      return true;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      
      await this.securityContext.log({
        action: 'refresh_token',
        executor: 'OAuthGateway',
        securityLevel: SecurityLevel.HIGH,
        success: false,
        error: errorMessage
      });

      return false;
    }
  }

  /**
   * 撤销会话（登出）
   * @param providerId 提供商 ID
   */
  public async revokeSession(providerId: string): Promise<boolean> {
    const session = this.sessions.get(providerId);
    if (!session) {
      return false;
    }

    // 实际项目中应调用提供商的撤销端点
    this.sessions.delete(providerId);

    // 记录审计日志
    await this.securityContext.log({
      action: 'revoke_session',
      executor: 'OAuthGateway',
      securityLevel: SecurityLevel.HIGH,
      success: true,
      details: { providerId }
    });

    console.log(`[OAuthGateway] 会话已撤销：${providerId}`);
    return true;
  }

  /**
   * 检查是否已认证
   * @param providerId 提供商 ID
   */
  public isAuthenticated(providerId: string): boolean {
    const session = this.sessions.get(providerId);
    if (!session) {
      return false;
    }

    return !this.isTokenExpired(session.token);
  }

  /**
   * 获取所有已认证的提供商
   */
  public getAuthenticatedProviders(): string[] {
    const authenticated: string[] = [];
    
    this.sessions.forEach((session, providerId) => {
      if (!this.isTokenExpired(session.token)) {
        authenticated.push(providerId);
      }
    });

    return authenticated;
  }

  /**
   * 检查令牌是否过期
   */
  private isTokenExpired(token: OAuthToken): boolean {
    if (!token.expiresIn) {
      return false; // 永不过期
    }

    const expiresAt = token.createdAt + (token.expiresIn * 1000);
    // 提前 5 分钟刷新
    const refreshThreshold = 5 * 60 * 1000;
    
    return Date.now() + refreshThreshold > expiresAt;
  }

  /**
   * 生成随机 state 参数
   */
  private generateRandomState(): string {
    const array = new Uint8Array(32);
    // 实际项目中应使用安全的随机数生成器
    for (let i = 0; i < array.length; i++) {
      array[i] = Math.floor(Math.random() * 256);
    }
    return Array.from(array).map(b => b.toString(16).padStart(2, '0')).join('');
  }

  /**
   * 获取会话统计
   */
  public getSessionStats(): Record<string, any> {
    return {
      totalSessions: this.sessions.size,
      providers: Array.from(this.sessions.keys()),
      authenticated: this.getAuthenticatedProviders()
    };
  }
}
