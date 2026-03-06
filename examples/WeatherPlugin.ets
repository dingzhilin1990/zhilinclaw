/**
 * 示例插件 - 天气查询插件
 * 
 * 演示如何实现一个完整的插件：
 * - 插件元数据定义
 * - 生命周期钩子
 * - 技能注册
 */

import { Plugin, type PluginMetadata } from '../../plugins/PluginManager';
import { Skill, type SkillResult } from '../../skills/SkillRegistry';
import { EventBus } from '../../events/EventBus';

/**
 * 天气查询技能
 */
class WeatherQuerySkill extends Skill {
  private eventBus: EventBus;

  constructor(eventBus: EventBus) {
    super({
      name: 'weather_query',
      description: '查询天气信息',
      version: '1.0.0',
      author: 'ZhiLinClaw Team',
      triggers: ['天气', '气温', '下雨', '晴天', 'weather']
    });
    this.eventBus = eventBus;
  }

  async execute(input: string, context?: any): Promise<SkillResult> {
    console.log('[WeatherSkill] 执行天气查询:', input);

    // 发布技能执行事件
    await this.eventBus.publish('skill:weather:querying', {
      input,
      timestamp: Date.now()
    });

    // 模拟天气查询（实际项目中应调用天气 API）
    const weatherData = {
      city: '北京',
      temperature: 25,
      condition: '晴',
      humidity: 60,
      windSpeed: 10
    };

    const response = `今天${weatherData.city}的天气：${weatherData.condition}，气温${weatherData.temperature}°C，湿度${weatherData.humidity}%，风速${weatherData.windSpeed}km/h。`;

    return {
      success: true,
      output: response,
      data: weatherData
    };
  }
}

/**
 * 天气查询插件
 */
export class WeatherPlugin extends Plugin {
  private eventBus?: EventBus;
  private skill?: WeatherQuerySkill;

  constructor() {
    super({
      name: 'weather_plugin',
      version: '1.0.0',
      description: '天气查询插件 - 提供实时天气信息查询服务',
      author: 'ZhiLinClaw Team',
      minCoreVersion: '1.0.0',
      permissions: ['network_access']
    });
  }

  /**
   * 插件加载时的初始化
   */
  async onLoad(): Promise<void> {
    console.log('[WeatherPlugin] 插件加载中...');
    // 初始化资源
  }

  /**
   * 插件启用时注册技能
   */
  async onEnable(): Promise<void> {
    console.log('[WeatherPlugin] 插件启用中...');
    
    // 获取事件总线并注册技能
    // 实际使用中通过核心系统注入
    this.eventBus = new EventBus();
    this.skill = new WeatherQuerySkill(this.eventBus);
    
    console.log('[WeatherPlugin] 天气查询技能已就绪');
  }

  /**
   * 插件禁用时清理资源
   */
  async onDisable(): Promise<void> {
    console.log('[WeatherPlugin] 插件禁用中...');
    // 清理资源
    this.skill = undefined;
  }

  /**
   * 插件卸载时的清理
   */
  async onUnload(): Promise<void> {
    console.log('[WeatherPlugin] 插件卸载中...');
    // 释放资源
  }

  /**
   * 获取插件的技能
   */
  getSkill(): WeatherQuerySkill | undefined {
    return this.skill;
  }
}
