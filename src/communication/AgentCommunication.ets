/**
 * Agent 间通信模块
 * 
 * 提供结构化的 Agent 间通信机制：
 * - 消息传递
 * - 协作请求
 * - 状态同步
 * - 任务委派
 */

import { EventBus } from '../events/EventBus';
import { AgentRole } from '../agents/AgentBase';

export enum MessageType {
  TASK = 'task',
  QUERY = 'query',
  RESPONSE = 'response',
  NOTIFICATION = 'notification',
  COLLABORATION = 'collaboration',
  STATUS_UPDATE = 'status_update',
  ERROR = 'error'
}

export enum MessagePriority {
  LOW = 0,
  NORMAL = 1,
  HIGH = 2,
  URGENT = 3
}

export interface AgentMessage {
  id: string;
  type: MessageType;
  from: AgentRole;
  to: AgentRole | AgentRole[];
  content: any;
  priority: MessagePriority;
  timestamp: number;
  correlationId?: string;
  metadata?: Record<string, any>;
}

export interface CollaborationRequest {
  taskId: string;
  requester: AgentRole;
  collaborators: AgentRole[];
  description: string;
  deadline?: number;
  requirements?: string[];
}

export interface CollaborationResponse {
  requestId: string;
  responder: AgentRole;
  accepted: boolean;
  estimatedTime?: number;
  notes?: string;
}

export class AgentCommunication {
  private eventBus: EventBus;
  private messageCounter: number = 0;
  private pendingRequests: Map<string, CollaborationRequest> = new Map();
  private messageHistory: AgentMessage[] = [];
  private maxHistorySize: number = 1000;

  constructor(eventBus: EventBus) {
    this.eventBus = eventBus;
    this.setupInternalHandlers();
  }

  private setupInternalHandlers(): void {
    this.eventBus.subscribe('agent:message', async (message: AgentMessage) => {
      this.addToHistory(message);
    });

    this.eventBus.subscribe('agent:collaboration:request', async (request: CollaborationRequest) => {
      this.pendingRequests.set(request.taskId, request);
    });

    this.eventBus.subscribe('agent:collaboration:response', async (response: CollaborationResponse) => {
      const request = this.pendingRequests.get(response.requestId);
      if (request) {
        console.log(`[AgentCommunication] 协作请求 ${response.requestId} 被 ${response.responder} ${response.accepted ? '接受' : '拒绝'}`);
      }
    });
  }

  public async sendMessage(message: Omit<AgentMessage, 'id' | 'timestamp'>): Promise<string> {
    const fullMessage: AgentMessage = {
      ...message,
      id: `msg_${++this.messageCounter}`,
      timestamp: Date.now()
    };

    this.addToHistory(fullMessage);

    const eventTopic = this.getEventTopic(message.to);
    await this.eventBus.publish(eventTopic, fullMessage);

    console.log(`[AgentCommunication] 消息已发送：${fullMessage.id} 从 ${message.from} 到 ${Array.isArray(message.to) ? message.to.join(',') : message.to}`);

    return fullMessage.id;
  }

  public async sendTask(from: AgentRole, to: AgentRole | AgentRole[], task: any, priority: MessagePriority = MessagePriority.NORMAL): Promise<string> {
    return this.sendMessage({
      type: MessageType.TASK,
      from,
      to,
      content: task,
      priority
    });
  }

  public async sendQuery(from: AgentRole, to: AgentRole, query: string, correlationId?: string): Promise<string> {
    return this.sendMessage({
      type: MessageType.QUERY,
      from,
      to,
      content: query,
      priority: MessagePriority.NORMAL,
      correlationId
    });
  }

  public async sendResponse(from: AgentRole, to: AgentRole, response: any, correlationId: string): Promise<string> {
    return this.sendMessage({
      type: MessageType.RESPONSE,
      from,
      to,
      content: response,
      priority: MessagePriority.NORMAL,
      correlationId
    });
  }

  public async notify(from: AgentRole, to: AgentRole | AgentRole[], notification: string, metadata?: Record<string, any>): Promise<string> {
    return this.sendMessage({
      type: MessageType.NOTIFICATION,
      from,
      to,
      content: notification,
      priority: MessagePriority.LOW,
      metadata
    });
  }

  public async requestCollaboration(request: CollaborationRequest): Promise<string> {
    this.pendingRequests.set(request.taskId, request);

    await this.eventBus.publish('agent:collaboration:request', request);

    console.log(`[AgentCommunication] 协作请求已发送：${request.taskId}，参与者：${request.collaborators.join(', ')}`);

    return request.taskId;
  }

  public async respondToCollaboration(response: CollaborationResponse): Promise<void> {
    await this.eventBus.publish('agent:collaboration:response', response);
  }

  public subscribeToMessages(role: AgentRole, handler: (message: AgentMessage) => void | Promise<void>): string {
    const topic = this.getEventTopic(role);
    return this.eventBus.subscribe(topic, handler);
  }

  public subscribeToCollaborationRequests(role: AgentRole, handler: (request: CollaborationRequest) => void | Promise<void>): string {
    return this.eventBus.subscribe('agent:collaboration:request', async (request: CollaborationRequest) => {
      if (request.collaborators.includes(role)) {
        await handler(request);
      }
    });
  }

  public unsubscribe(subscriptionId: string): void {
    const events = this.eventBus.getAllEvents();
    for (const event of events) {
      this.eventBus.unsubscribe(event, subscriptionId);
    }
  }

  private getEventTopic(to: AgentRole | AgentRole[]): string {
    if (Array.isArray(to)) {
      return `agent:message:${to.join(':')}`;
    }
    return `agent:message:${to}`;
  }

  private addToHistory(message: AgentMessage): void {
    this.messageHistory.push(message);
    
    if (this.messageHistory.length > this.maxHistorySize) {
      this.messageHistory.shift();
    }
  }

  public getMessageHistory(filter?: {
    from?: AgentRole;
    to?: AgentRole;
    type?: MessageType;
    limit?: number;
  }): AgentMessage[] {
    let result = [...this.messageHistory];

    if (filter) {
      if (filter.from !== undefined) {
        result = result.filter(m => m.from === filter.from);
      }
      if (filter.to !== undefined) {
        result = result.filter(m => {
          if (Array.isArray(m.to)) {
            return m.to.includes(filter.to!);
          }
          return m.to === filter.to;
        });
      }
      if (filter.type !== undefined) {
        result = result.filter(m => m.type === filter.type);
      }
      if (filter.limit !== undefined) {
        result = result.slice(-filter.limit);
      }
    }

    return result;
  }

  public getPendingRequests(): CollaborationRequest[] {
    return Array.from(this.pendingRequests.values());
  }

  public getStats(): Record<string, any> {
    const stats: Record<string, any> = {
      totalMessages: this.messageHistory.length,
      pendingRequests: this.pendingRequests.size,
      byType: {},
      byPriority: {}
    };

    Object.values(MessageType).forEach(type => {
      stats.byType[type] = this.messageHistory.filter(m => m.type === type).length;
    });

    Object.values(MessagePriority).forEach(priority => {
      if (typeof priority === 'number') {
        stats.byPriority[priority] = this.messageHistory.filter(m => m.priority === priority).length;
      }
    });

    return stats;
  }

  public clearHistory(): void {
    this.messageHistory = [];
    console.log('[AgentCommunication] 消息历史已清空');
  }
}
