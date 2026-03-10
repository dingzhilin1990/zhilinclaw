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
  enableLogging: true,
  systemPrompt: `你是一位专业的技术文档撰写专家。你的职责是：
1. 整理和记录项目过程信息
2. 编写清晰、结构化的技术文档
3. 归档项目成果和知识资产
4. 确保文档的完整性和可追溯性

请输出规范的文档格式。`
};

export enum DocumentType {
  MEETING_NOTES = 'meeting_notes',
  TECHNICAL_DOC = 'technical_doc',
  USER_GUIDE = 'user_guide',
  API_DOC = 'api_doc',
  PROJECT_REPORT = 'project_report',
  CHANGELOG = 'changelog'
}

export interface Document {
  id: string;
  title: string;
  type: DocumentType;
  content: string;
  author: string;
  createdAt: number;
  updatedAt: number;
  tags?: string[];
  relatedTaskId?: string;
  version?: string;
}

export interface ArchivePackage {
  id: string;
  name: string;
  documents: Document[];
  archivedAt: number;
  description?: string;
}

export class Recorder extends AgentBase {
  private documents: Map<string, Document> = new Map();
  private archives: Map<string, ArchivePackage> = new Map();
  private docCounter: number = 0;

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

      const docPrompt = `请根据以下信息编写技术文档：

内容描述：${input}

请按以下结构输出：
# 文档标题

## 概述
简要描述文档目的和范围

## 详细内容
详细说明相关内容

## 总结
总结要点和后续行动

## 附录
相关参考资料`;

      const aiResponse = await this.callAI(docPrompt);
      
      const organizedInfo = this.organizeInformation(input, aiResponse);
      const document = this.createDocument(organizedInfo, aiResponse);
      await this.storeDocument(document);
      const index = this.generateIndex();

      return {
        success: true,
        output: `文档已创建：${document.title}`,
        documents: {
          document,
          index,
          aiContent: aiResponse
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

  private organizeInformation(input: string, aiResponse: string): Record<string, any> {
    return {
      source: input,
      keyPoints: this.extractKeyPoints(aiResponse),
      structure: ['概述', '详细内容', '总结', '附录'],
      aiContent: aiResponse
    };
  }

  private createDocument(info: Record<string, any>, aiResponse: string): Document {
    const titleMatch = aiResponse.match(/^#\s+(.+)$/m);
    const title = titleMatch ? titleMatch[1] : '技术文档';

    const doc: Document = {
      id: `doc_${Date.now()}_${++this.docCounter}`,
      title: title,
      type: DocumentType.TECHNICAL_DOC,
      content: aiResponse,
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

  private generateIndex(): Record<string, any> {
    return {
      totalDocuments: this.documents.size,
      byType: this.getDocumentsByType(),
      recentDocuments: Array.from(this.documents.values())
        .sort((a, b) => b.updatedAt - a.updatedAt)
        .slice(0, 10)
    };
  }

  private extractKeyPoints(text: string): string[] {
    const points: string[] = [];
    const lines = text.split('\n');
    for (const line of lines) {
      if (line.trim().startsWith('-') || line.trim().match(/^\d+\./)) {
        points.push(line.replace(/^[-\d\.\s]+/, '').trim());
      }
    }
    return points.slice(0, 5);
  }

  private getDocumentsByType(): Record<string, number> {
    const result: Record<string, number> = {};
    this.documents.forEach(doc => {
      result[doc.type] = (result[doc.type] || 0) + 1;
    });
    return result;
  }

  public addDocument(document: Document): void {
    this.documents.set(document.id, document);
    this.log(`添加文档：${document.title}`);
  }

  public getDocument(id: string): Document | null {
    return this.documents.get(id) || null;
  }

  public updateDocument(id: string, updates: Partial<Document>): boolean {
    const doc = this.documents.get(id);
    if (!doc) return false;

    Object.assign(doc, updates, { updatedAt: Date.now() });
    this.documents.set(id, doc);
    this.log(`更新文档：${id}`);
    return true;
  }

  public deleteDocument(id: string): boolean {
    const deleted = this.documents.delete(id);
    if (deleted) {
      this.log(`删除文档：${id}`);
    }
    return deleted;
  }

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

  public getAllDocuments(): Document[] {
    return Array.from(this.documents.values());
  }

  public searchDocuments(query: string): Document[] {
    this.log(`搜索文档：${query}`);
    
    return Array.from(this.documents.values()).filter(doc =>
      doc.title.toLowerCase().includes(query.toLowerCase()) ||
      doc.content.toLowerCase().includes(query.toLowerCase())
    );
  }

  public exportToMarkdown(documentId: string): string | null {
    const doc = this.getDocument(documentId);
    if (!doc) return null;

    return doc.content;
  }

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
