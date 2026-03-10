/**
 * 执行层 Agent - 工程师
 * 
 * 核心职责：
 * - 代码编写
 * - 功能实现
 * - 工具开发
 * - 任务落地
 * 
 * 触发关键词：编码、构建、开发、实现
 */

import { AgentBase, AgentConfig, AgentContext, AgentResult, AgentRole, AgentLayer } from './AgentBase';

const engineerConfig: AgentConfig = {
  name: '工程师',
  role: AgentRole.ENGINEER,
  layer: AgentLayer.EXECUTION,
  triggerKeywords: ['编码', '构建', '开发', '实现', '编程', 'code', 'build', 'develop'],
  maxIterations: 20,
  enableLogging: true,
  systemPrompt: `你是一位资深软件工程师。你的职责是：
1. 理解需求并设计技术方案
2. 编写高质量、可维护的代码
3. 确保代码符合最佳实践和安全标准
4. 编写必要的测试用例

请输出结构化的代码和技术文档。`
};

export class Engineer extends AgentBase {
  constructor() {
    super(engineerConfig);
  }

  async process(input: string, context?: AgentContext): Promise<AgentResult> {
    const startTime = Date.now();
    
    await this.initialize(context || {
      taskId: `task_${Date.now()}`,
      taskDescription: input
    });

    try {
      this.log('开始实现功能...');

      const devPrompt = `请根据以下需求实现功能：

需求描述：${input}

请输出：
1. 技术设计（架构、模块划分、接口设计）
2. 代码实现（完整的可运行代码）
3. 测试用例（至少3个测试场景）
4. 使用说明`;

      const aiResponse = await this.callAI(devPrompt);
      
      const requirement = this.parseRequirement(input, aiResponse);
      const design = this.parseDesign(aiResponse);
      const code = this.extractCode(aiResponse);
      const testResult = await this.selfTest(code);

      return {
        success: testResult.passed,
        output: testResult.passed ? '功能实现完成' : '功能实现但测试未通过',
        documents: {
          requirement,
          design,
          code,
          testReport: testResult,
          aiAnalysis: aiResponse
        },
        executionTime: Date.now() - startTime
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      return {
        success: false,
        output: '功能实现失败',
        error: errorMessage,
        executionTime: Date.now() - startTime
      };
    }
  }

  private parseRequirement(input: string, aiResponse: string): Record<string, any> {
    return {
      originalInput: input,
      functionalRequirements: this.extractList(aiResponse, '功能需求') || ['实现核心功能'],
      nonFunctionalRequirements: this.extractList(aiResponse, '非功能需求') || ['性能要求', '安全要求'],
      constraints: ['技术约束', '时间约束']
    };
  }

  private parseDesign(aiResponse: string): Record<string, any> {
    return {
      architecture: '模块化架构设计',
      modules: this.extractList(aiResponse, '模块') || ['核心模块', '工具模块'],
      interfaces: this.extractList(aiResponse, '接口') || ['API 接口 1', 'API 接口 2'],
      dataModel: {
        entities: ['实体 1', '实体 2'],
        relationships: []
      }
    };
  }

  private extractCode(aiResponse: string): string {
    const codeMatch = aiResponse.match(/```[\s\S]*?```/g);
    if (codeMatch && codeMatch.length > 0) {
      return codeMatch.map(block => block.replace(/```\w*\n?/g, '')).join('\n\n');
    }
    return aiResponse;
  }

  private async selfTest(code: string): Promise<{passed: boolean; issues: string[]}> {
    this.log('进行自检测试...');
    
    const testPrompt = `请检查以下代码是否存在明显问题：

${code.substring(0, 1000)}

请回答：
1. 是否存在语法错误？
2. 是否存在逻辑问题？
3. 是否符合最佳实践？

如果代码看起来没问题，请回答"通过"，否则列出问题。`;

    const response = await this.callAI(testPrompt);
    const passed = response.includes('通过') || response.includes('没有问题');
    
    return {
      passed,
      issues: passed ? [] : [response.substring(0, 200)]
    };
  }

  private extractList(text: string, keyword: string): string[] | null {
    const regex = new RegExp(`${keyword}[：:][\\s\\S]*?(?=\\n\\d|\\n[A-Z]|$)`, 'i');
    const match = text.match(regex);
    if (match) {
      const items = match[0].split('\n')
        .filter(line => line.trim().startsWith('-') || line.trim().match(/^\d/))
        .map(line => line.replace(/^[-\d\.\s]+/, '').trim())
        .filter(line => line.length > 0);
      return items.length > 0 ? items : null;
    }
    return null;
  }

  public async reviewCode(code: string): Promise<Record<string, any>> {
    this.log('代码审查...');
    
    const reviewPrompt = `请对以下代码进行审查：

${code}

请评估：
1. 代码质量（1-10分）
2. 存在的问题
3. 改进建议`;

    const response = await this.callAI(reviewPrompt);
    
    return {
      quality: response.includes('质量') ? 'good' : 'needs_improvement',
      issues: [],
      suggestions: [response.substring(0, 200)],
      aiReview: response
    };
  }

  public async refactor(code: string): Promise<string> {
    this.log('代码重构...');
    
    const refactorPrompt = `请重构以下代码，使其更加清晰和高效：

${code}`;

    return await this.callAI(refactorPrompt);
  }
}
