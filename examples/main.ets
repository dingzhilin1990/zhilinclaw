/**
 * ZhiLinClaw 主入口示例
 * 
 * 演示如何初始化和使用 ZhiLinClaw 核心系统
 */

import { ZhiLinClawCore } from '../src/core/ZhiLinClawCore';
import { MemoryType } from '../src/memory/MemoryManager';
import { WeatherPlugin } from './WeatherPlugin';
import { FileManagerPlugin } from './FileManagerPlugin';

/**
 * 初始化并启动 ZhiLinClaw 系统
 */
async function main() {
  console.log('='.repeat(50));
  console.log('ZhiLinClaw - 本地优先的 AI 助手框架');
  console.log('='.repeat(50));

  // 获取核心系统实例
  const core = ZhiLinClawCore.getInstance();

  // 初始化核心系统
  await core.initialize({
    name: 'ZhiLinClaw',
    version: '1.0.0',
    dataPath: '/data/local/zhilinclaw',
    enableLogging: true,
    maxMemoryItems: 500
  });

  // 创建插件实例
  const weatherPlugin = new WeatherPlugin();
  const fileManagerPlugin = new FileManagerPlugin();

  // 注册插件
  const pluginManager = core.getPluginManager();
  await pluginManager.register(weatherPlugin);
  await pluginManager.register(fileManagerPlugin);

  // 启用插件
  await pluginManager.enable('weather_plugin');
  await pluginManager.enable('file_manager_plugin');

  // 注册技能到技能注册表
  const skillRegistry = core.getSkillRegistry();
  
  // 从天气插件注册技能
  const weatherSkill = weatherPlugin.getSkill();
  if (weatherSkill) {
    await skillRegistry.register(weatherSkill);
  }

  // 从文件管理插件注册技能
  const fileSkills = fileManagerPlugin.getSkills();
  for (const skill of fileSkills) {
    await skillRegistry.register(skill);
  }

  console.log('\n' + '='.repeat(50));
  console.log('系统初始化完成!');
  console.log('='.repeat(50));

  // 显示系统状态
  const status = core.getStatus();
  console.log('\n系统状态:');
  console.log(`  名称：${status.name}`);
  console.log(`  版本：${status.version}`);
  console.log(`  已初始化：${status.initialized}`);
  console.log(`  已加载插件：${status.pluginsLoaded}`);
  console.log(`  已注册技能：${status.skillsRegistered}`);
  console.log(`  记忆项数量：${status.memoryItems}`);

  // 测试处理请求
  console.log('\n' + '='.repeat(50));
  console.log('测试请求处理:');
  console.log('='.repeat(50));

  const testInputs = [
    '今天天气怎么样？',
    '列出当前目录的文件',
    '读取 document.txt 文件'
  ];

  for (const input of testInputs) {
    console.log(`\n用户输入：${input}`);
    const response = await core.processRequest(input);
    console.log(`助手响应：${response}`);
  }

  // 显示记忆统计
  const memoryManager = core.getMemoryManager();
  console.log('\n记忆统计:');
  console.log(JSON.stringify(memoryManager.getStats(), null, 2));

  // 显示技能统计
  console.log('\n技能调用统计:');
  const skillStats = skillRegistry.getAllStats();
  console.log(JSON.stringify(skillStats, null, 2));

  return core;
}

// 运行示例
main()
  .then(core => {
    console.log('\n✓ 示例运行完成');
  })
  .catch(error => {
    console.error('\n✗ 示例运行失败:', error);
  });
