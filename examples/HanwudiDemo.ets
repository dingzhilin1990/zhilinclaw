/**
 * 汉武帝架构使用示例
 * 
 * 演示如何使用 Hanwudi Workflow 实现 AI Agent 团队协作
 */

import { HanwudiWorkflow } from '../src/agents/HanwudiWorkflow';
import { Strategist, Researcher, Engineer } from '../src/agents';

/**
 * 示例 1: 完整工作流 - 复杂项目落地
 */
async function example1_FullWorkflow() {
  console.log('='.repeat(60));
  console.log('示例 1: 完整工作流 - 开发一个天气查询应用');
  console.log('='.repeat(60));

  // 创建工作流实例
  const workflow = new HanwudiWorkflow({
    enableResearcher: true,        // 启用研究员
    enableAdvisorReview: true,     // 启用顾问评审
    enableFullDocumentation: true, // 启用完整文档
    qualityThreshold: 75,          // 质量阈值 75 分
    maxIterations: 3,              // 最多迭代 3 次
    enableLogging: true            // 启用日志
  });

  // 定义需求
  const requirement = `
    开发一个天气查询应用，需要满足以下要求：
    1. 支持查询全国主要城市的实时天气
    2. 显示温度、湿度、风速、空气质量等数据
    3. 提供未来 7 天天气预报
    4. 界面简洁美观，支持深色模式
    5. 响应速度快，加载时间小于 2 秒
    6. 支持离线查看缓存的天气数据
  `;

  console.log('\n📋 需求描述:');
  console.log(requirement);
  console.log('\n🚀 开始执行工作流...\n');

  // 执行完整工作流
  const result = await workflow.execute(requirement);

  // 输出结果
  console.log('\n' + '='.repeat(60));
  console.log('📊 执行结果:');
  console.log('='.repeat(60));
  console.log(`✅ 成功：${result.success}`);
  console.log(`⏱️  执行时间：${(result.executionTime / 1000).toFixed(2)}秒`);
  console.log(`📈 质量评分：${result.qualityReport?.overallScore || 'N/A'}`);
  console.log(`📄 生成文档：${Object.keys(result.documents).length}个`);

  // 显示工作流日志
  console.log('\n📝 工作流日志:');
  result.workflowLog.forEach(log => {
    const icon = log.status === 'completed' ? '✅' : log.status === 'failed' ? '❌' : '🔄';
    console.log(`  ${icon} Step ${log.step} [${log.agent}]: ${log.action}`);
  });

  // 导岀报告
  const report = workflow.exportWorkflowReport(result);
  console.log('\n📑 工作流报告:');
  console.log(report);

  return result;
}

/**
 * 示例 2: 简化流程 - 小型代码开发
 */
async function example2_SimpleWorkflow() {
  console.log('\n' + '='.repeat(60));
  console.log('示例 2: 简化流程 - 编写一个工具函数');
  console.log('='.repeat(60));

  const workflow = new HanwudiWorkflow({
    enableResearcher: false,       // 不需要调研
    enableAdvisorReview: false,    // 跳过评审
    enableFullDocumentation: false,// 简化文档
    qualityThreshold: 60,          // 降低质量阈值
    maxIterations: 1,              // 单次执行
    enableLogging: true
  });

  const requirement = '编写一个日期格式化工具函数，支持多种格式转换';

  console.log('\n📋 需求:', requirement);
  console.log('\n🚀 开始执行...\n');

  const result = await workflow.execute(requirement);

  console.log('\n✅ 完成!');
  console.log(`质量评分：${result.qualityReport?.overallScore}`);

  return result;
}

/**
 * 示例 3: 单独使用特定 Agent - 调研报告
 */
async function example3_SingleAgent() {
  console.log('\n' + '='.repeat(60));
  console.log('示例 3: 单独使用研究员 - 行业调研');
  console.log('='.repeat(60));

  const researcher = new Researcher();

  const topic = 'AI Agent 技术在企业中的应用现状和发展趋势';

  console.log('\n📚 调研主题:', topic);
  console.log('\n🔍 开始调研...\n');

  const result = await researcher.process(topic);

  if (result.success) {
    console.log('\n✅ 调研完成!');
    console.log('📄 生成的报告:');
    console.log(JSON.stringify(result.documents, null, 2));
  } else {
    console.log('\n❌ 调研失败:', result.error);
  }

  return result;
}

/**
 * 示例 4: 单独使用特定 Agent - 代码审查
 */
async function example4_CodeReview() {
  console.log('\n' + '='.repeat(60));
  console.log('示例 4: 使用工程师 + 质检员 - 代码审查');
  console.log('='.repeat(60));

  const engineer = new Engineer();
  const inspector = new Inspector();

  // 工程师先实现功能
  const codeRequirement = '实现一个快速排序算法';
  console.log('\n💻 实现功能:', codeRequirement);
  
  const codeResult = await engineer.process(codeRequirement);
  
  if (codeResult.success) {
    console.log('✅ 代码实现完成');
    
    // 质检员进行代码审查
    console.log('\n🔍 开始代码审查...');
    const reviewResult = await inspector.process(
      JSON.stringify(codeResult.documents)
    );

    if (reviewResult.success) {
      const report = reviewResult.documents?.qualityReport;
      console.log('\n📊 审查结果:');
      console.log(`  评分：${report?.overallScore}`);
      console.log(`  通过：${report?.passed}`);
      console.log(`  问题数：${report?.issues.length}`);
    }
  }

  return { codeResult, reviewResult };
}

/**
 * 示例 5: 场景化配置 - 行业调研报告
 */
async function example5_ReportWriting() {
  console.log('\n' + '='.repeat(60));
  console.log('示例 5: 场景化配置 - 撰写行业调研报告');
  console.log('='.repeat(60));

  // 只需要研究员 + 顾问 + 记录官
  const researcher = new Researcher();
  const advisor = new Advisor();
  const recorder = new Recorder();

  const topic = '2026 年人工智能发展趋势报告';

  console.log('\n📝 主题:', topic);
  console.log('\n✍️  开始撰写...\n');

  // 1. 研究员调研
  const research = await researcher.process(topic);
  
  // 2. 顾问评审
  const review = await advisor.process(JSON.stringify(research.documents));
  
  // 3. 记录官整理文档
  const doc = await recorder.process('整理调研报告');

  console.log('\n✅ 报告撰写完成!');
  console.log(`📄 文档数量：${recorder.getAllDocuments().length}`);

  return { research, review, doc };
}

/**
 * 运行所有示例
 */
async function runAllExamples() {
  try {
    // 示例 1: 完整工作流
    await example1_FullWorkflow();

    // 示例 2: 简化流程
    await example2_SimpleWorkflow();

    // 示例 3: 单独 Agent
    await example3_SingleAgent();

    // 示例 4: 代码审查
    await example4_CodeReview();

    // 示例 5: 场景化配置
    await example5_ReportWriting();

    console.log('\n' + '='.repeat(60));
    console.log('🎉 所有示例运行完成!');
    console.log('='.repeat(60));
  } catch (error) {
    console.error('\n❌ 示例运行失败:', error);
  }
}

// 运行示例
runAllExamples()
  .then(() => {
    console.log('\n✓ 演示结束');
  })
  .catch(error => {
    console.error('\n✗ 错误:', error);
  });
