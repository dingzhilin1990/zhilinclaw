/**
 * 示例插件 - 文件管理插件
 * 
 * 演示文件操作相关的插件实现
 */

import { Plugin, type PluginMetadata } from '../../plugins/PluginManager';
import { Skill, type SkillResult } from '../../skills/SkillRegistry';
import { EventBus } from '../../events/EventBus';

/**
 * 文件列表技能
 */
class FileListSkill extends Skill {
  async execute(input: string, context?: any): Promise<SkillResult> {
    console.log('[FileSkill] 执行文件列表查询:', input);

    // 模拟文件列表（实际项目中应访问文件系统）
    const files = [
      { name: 'document.txt', size: '1.2 KB', type: 'file' },
      { name: 'images/', size: '-', type: 'folder' },
      { name: 'data.json', size: '3.4 KB', type: 'file' }
    ];

    const fileList = files.map(f => 
      `${f.type === 'folder' ? '📁' : '📄'} ${f.name} (${f.size})`
    ).join('\n');

    return {
      success: true,
      output: `当前目录内容:\n${fileList}`,
      data: files
    };
  }
}

/**
 * 文件读取技能
 */
class FileReadSkill extends Skill {
  async execute(input: string, context?: any): Promise<SkillResult> {
    // 从输入中提取文件名
    const fileNameMatch = input.match(/(?:读取 | 打开)\s*(.+)/i);
    const fileName = fileNameMatch ? fileNameMatch[1].trim() : 'unknown.txt';

    console.log('[FileSkill] 读取文件:', fileName);

    // 模拟文件读取
    const fileContent = `这是文件 ${fileName} 的模拟内容。\n实际项目中应读取真实文件。`;

    return {
      success: true,
      output: fileContent,
      data: { fileName, content: fileContent }
    };
  }
}

/**
 * 文件管理插件
 */
export class FileManagerPlugin extends Plugin {
  private skills: Skill[] = [];

  constructor() {
    super({
      name: 'file_manager_plugin',
      version: '1.0.0',
      description: '文件管理插件 - 提供文件浏览、读取、写入等功能',
      author: 'ZhiLinClaw Team',
      minCoreVersion: '1.0.0',
      permissions: ['file_system_access']
    });
  }

  async onEnable(): Promise<void> {
    console.log('[FileManagerPlugin] 插件启用中...');
    
    this.skills = [
      new FileListSkill({
        name: 'file_list',
        description: '列出目录内容',
        version: '1.0.0',
        author: 'ZhiLinClaw Team',
        triggers: ['文件列表', '目录', 'ls', 'list']
      }),
      new FileReadSkill({
        name: 'file_read',
        description: '读取文件内容',
        version: '1.0.0',
        author: 'ZhiLinClaw Team',
        triggers: ['读取', '打开文件', 'cat', 'read']
      })
    ];

    console.log('[FileManagerPlugin] 已注册', this.skills.length, '个技能');
  }

  async onDisable(): Promise<void> {
    console.log('[FileManagerPlugin] 插件禁用中...');
    this.skills = [];
  }

  getSkills(): Skill[] {
    return [...this.skills];
  }
}
