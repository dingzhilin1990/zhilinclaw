/**
 * 执行层 Agent - 记录官
 * 
 * 核心职责：
 * - 过程文档撰写
 * - 成果归档
 * - 操作日志记录
 * 
 * 触发关键词：文档、记录、归档、日志
 */

import { AgentBase, AgentConfig, AgentContext, AgentResult, AgentRole, AgentLayer } from './AgentBase';

const recorderConfig: AgentConfig = {
  name: '记录官',
  role: AgentRole.RECORDER,
  layer: AgentLayer.EXECUTION,
  triggerKeywords: ['文档', '记录', '归档', '日志', '笔记', 'document', 'record'],
  maxIterations: 5,
  enableLogging: true
};

/**
 * 文档类型
 */
export enum DocumentType {
  MEETING_NOTES = 'meeting_notes',
  TECHNICAL_DOC = 'technical_doc',
  USER_GUIDE = 'user_guide',
  API_DOC = 'api_doc',
  PROJECT_REPORT = 'project_report',
  CHANGELOG = 'changelog'
}

/**
 * 文档接口
 */
export interface Document {
  /** 文档 ID */
  id: string;
  /** 文档标题 */
  title: string;
  /** 文档类型 */
  type: DocumentType;
  /** 内容 */
  content: string;
  /** 创建者 */
  author: string;
  /** 创建时间 */
  createdAt: number;
  /** 更新时间 */
  updatedAt: number;
  /** 标签列表 */
  tags?: string[];
  /** 关联任务 ID */
  relatedTaskId?: string;
  /** 版本号 */
  version?: string;
}

/**
 * 归档包接口
 */
export interface ArchivePackage {
  /** 归档 ID */
  id: string;
  /** 归档名称 */
  name: string;
  /** 包含的文档列表 */
  documents: Document[];
  /** 归档时间 */
  archivedAt: number;
  /** 归档说明 */
  description?: string;
}

/**
 * 记录官类
 */
export class Recorder extends AgentBase {
  private documents: Map<string, Document> = new Map();
  private archives: Map<string, ArchivePackage> = new Map();
  private logCounter: number = 0;

  constructor() {
    super(recorderConfig);
  }

  async process(input: string, context?: AgentContext): Promise<AgentResult> {
    const startTime = Date.now();
    
    await this.initialize(context || {
      taskId: `task_${Date.now()}`,
      taskDescription: input
    });

    try {
      this.log('开始记录文档...');

      // 1. 整理信息
      const organizedInfo = await this.organizeInformation(input);
      
      // 2. 编写文档
      const document = await this.writeDocument(organizedInfo);
      
      // 3. 存储文档
      await this.storeDocument(document);
      
      // 4. 生成索引
      const index = await this.generateIndex();

      return {
        success: true,
        output: `文档已创建：${document.title}`,
        documents: {
          document,
          index
        },
        executionTime: Date.now() - startTime
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      return {
        success: false,
        output: '文档创建失败',
        error: errorMessage,
        executionTime: Date.now() - startTime
      };
    }
  }

  private async organizeInformation(input: string): Promise<Record<string, any>> {
    this.log('整理信息...');
    
    return {
      source: input,
      keyPoints: this.extractKeyPoints(input),
      structure: this.determineStructure(input)
    };
  }

  private async writeDocument(info: Record<string, any>): Promise<Document> {
    this.log('编写文档...');
    
    const doc: Document = {
      id: `doc_${Date.now()}_${++this.logCounter}`,
      title: '文档标题',
      type: DocumentType.TECHNICAL_DOC,
      content: '# 文档内容\n\n这是文档正文...',
      author: this.config.name,
      createdAt: Date.now(),
      updatedAt: Date.now(),
      tags: ['技术', '文档'],
      version: '1.0.0'
    };

    return doc;
  }

  private async storeDocument(document: Document): Promise<void> {
    this.documents.set(document.id, document);
    this.log(`文档已存储：${document.id}`);
  }

  private async generateIndex(): Promise<Record<string, any>> {
    this.log('生成索引...');
    
    return {
      totalDocuments: this.documents.size,
      byType: this.getDocumentsByType(),
      recentDocuments: Array.from(this.documents.values())
        .sort((a, b) => b.updatedAt - a.updatedAt)
        .slice(0, 10)
    };
  }

  private extractKeyPoints(input: string): string[] {
    return ['关键点 1', '关键点 2'];
  }

  private determineStructure(input: string): string[] {
    return ['引言', '正文', '总结'];
  }

  private getDocumentsByType(): Record<string, number> {
    const result: Record<string, number> = {};
    this.documents.forEach(doc => {
      result[doc.type] = (result[doc.type] || 0) + 1;
    });
    return result;
  }

  /**
   * 添加文档
   */
  public addDocument(document: Document): void {
    this.documents.set(document.id, document);
    this.log(`添加文档：${document.title}`);
  }

  /**
   * 获取文档
   */
  public getDocument(id: string): Document | null {
    return this.documents.get(id) || null;
  }

  /**
   * 更新文档
   */
  public updateDocument(id: string, updates: Partial<Document>): boolean {
    const doc = this.documents.get(id);
    if (!doc) return false;

    Object.assign(doc, updates, { updatedAt: Date.now() });
    this.documents.set(id, doc);
    
    this.log(`更新文档：${id}`);
    return true;
  }

  /**
   * 删除文档
   */
  public deleteDocument(id: string): boolean {
    const deleted = this.documents.delete(id);
    if (deleted) {
      this.log(`删除文档：${id}`);
    }
    return deleted;
  }

  /**
   * 创建归档包
   */
  public createArchive(name: string, documentIds: string[], description?: string): ArchivePackage | null {
    const docs: Document[] = [];
    
    for (const id of documentIds) {
      const doc = this.getDocument(id);
      if (doc) {
        docs.push(doc);
      }
    }

    if (docs.length === 0) return null;

    const archive: ArchivePackage = {
      id: `archive_${Date.now()}`,
      name,
      documents: docs,
      archivedAt: Date.now(),
      description
    };

    this.archives.set(archive.id, archive);
    this.log(`创建归档包：${name}，包含${docs.length}个文档`);
    
    return archive;
  }

  /**
   * 获取所有文档
   */
  public getAllDocuments(): Document[] {
    return Array.from(this.documents.values());
  }

  /**
   * 搜索文档
   */
  public searchDocuments(query: string): Document[] {
    this.log(`搜索文档：${query}`);
    
    return Array.from(this.documents.values()).filter(doc =>
      doc.title.toLowerCase().includes(query.toLowerCase()) ||
      doc.content.toLowerCase().includes(query.toLowerCase())
    );
  }

  /**
   * 导出文档为 Markdown
   */
  public exportToMarkdown(documentId: string): string | null {
    const doc = this.getDocument(documentId);
    if (!doc) return null;

    return `# ${doc.title}\n\n${doc.content}`;
  }

  /**
   * 获取统计信息
   */
  public getStats(): Record<string, any> {
    return {
      totalDocuments: this.documents.size,
      totalArchives: this.archives.size,
      byType: this.getDocumentsByType(),
      recentActivity: Array.from(this.documents.values())
        .sort((a, b) => b.updatedAt - a.updatedAt)
        .slice(0, 5)
    };
  }
}
