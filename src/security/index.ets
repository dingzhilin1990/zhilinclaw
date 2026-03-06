/**
 * 安全模块 - ZhiLinClaw 的安全核心
 * 
 * 参考 IronClaw 的安全理念设计：
 * - WASM 沙箱隔离工具执行
 * - 加密保险柜管理凭证
 * - 多层安全过滤防止提示词注入
 * - OAuth 网关路由认证
 * 
 * 核心原则：
 * 1. 最小权限原则 - 工具只能访问必要的资源
 * 2. 隔离执行 - 不受信任的代码在沙箱中运行
 * 3. 凭证保护 - 敏感信息加密存储，运行时注入
 * 4. 深度防御 - 多层安全检查
 */

export { SecurityContext } from './SecurityContext';
export type { 
  SecurityLevel, 
  SecurityPolicy, 
  AuditLogEntry 
} from './SecurityContext';

export { CredentialVault } from './CredentialVault';
export type { 
  CredentialType, 
  Credential, 
  CredentialMetadata 
} from './CredentialVault';

export { SecurityFilter } from './SecurityFilter';
export type { 
  SecurityCheckResult, 
  RiskLevel, 
  SecurityIssue 
} from './SecurityFilter';

export { SandboxedExecutor } from './SandboxedExecutor';
export type { 
  SandboxConfig, 
  SandboxResult 
} from './SandboxedExecutor';

export { OAuthGateway } from './OAuthGateway';
export type { 
  OAuthProviderConfig, 
  OAuthToken, 
  OAuthSession 
} from './OAuthGateway';
