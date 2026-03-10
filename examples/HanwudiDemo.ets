/**
 * 汉武帝架构使用示例
 * 
 * 演示如何使用 Hanwudi Workflow 实现 AI Agent 团队协作
 */

import { HanwudiWorkflow, Strategist, Researcher, Engineer, Advisor, Recorder, Inspector } from '../src/agents';

async function example1_FullWorkflow() {
  console.log('='.repeat(60));
  console.log('示例 1: 完整工作流 - 开发一个天气查询应用');
  console.log('='.repeat(60));

  const workflow = new HanwudiWorkflow({
    enableResearcher: true,
    enableAdvisorReview: true,
    enableFullDocumentation: true,
    qualityThreshold: 75,
    maxIterations: 3,
    enableLogging: true
  });

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

  const result = await workflow.execute(requirement);

  console.log('\n' + '='.repeat(60));
  console.log('📊 执行结果:');
  console.log('='.repeat(60));
  console.log(`✅ 成功：${result.success}`);
  console.log(`⏱️  执行时间：${(result.executionTime / 1000).toFixed(2)}秒`);
  console.log(`📈 质量评分：${result.qualityReport?.overallScore || 'N/A'}`);
  console.log(`📄 生成文档：${Object.keys(result.documents || {}).length}个`);

  console.log('\n📝 工作流日志:');
  (result.workflowLog || []).forEach(log => {
    const icon = log.status === 'completed' ? '✅' : log.status === 'failed' ? '❌' : '🔄';
    console.log(`  ${icon} Step ${log.step} [${log.agent}]: ${log.action}`);
  });

  const report = workflow.exportWorkflowReport(result);
  console.log('\n📑 工作流报告:');
  console.log(report);

  return result;
}

async function example2_SimpleWorkflow() {
  console.log('\n' + '='.repeat(60));
  console.log('示例 2: 简化流程 - 编写一个工具函数');
  console.log('='.repeat(60));

  const workflow = new HanwudiWorkflow({
    enableResearcher: false,
    enableAdvisorReview: false,
    enableFullDocumentation: false,
    qualityThreshold: 60,
    maxIterations: 1,
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

async function example4_CodeReview() {
  console.log('\n' + '='.repeat(60));
  console.log('示例 4: 使用工程师 + 质检员 - 代码审查');
  console.log('='.repeat(60));

  const engineer = new Engineer();
  const inspector = new Inspector();

  const codeRequirement = '实现一个快速排序算法';
  console.log('\n💻 实现功能:', codeRequirement);
  
  const codeResult = await engineer.process(codeRequirement);
  let reviewResult = null;
  
  if (codeResult.success) {
    console.log('✅ 代码实现完成');
    
    console.log('\n🔍 开始代码审查...');
    reviewResult = await inspector.process(
      JSON.stringify(codeResult.documents)
    );

    if (reviewResult.success) {
      const report = reviewResult.documents?.qualityReport;
      console.log('\n📊 审查结果:');
      console.log(`  评分：${report?.overallScore}`);
      console.log(`  通过：${report?.passed}`);
      console.log(`  问题数：${report?.issues?.length || 0}`);
    }
  }

  return { codeResult, reviewResult };
}

async function example5_ReportWriting() {
  console.log('\n' + '='.repeat(60));
  console.log('示例 5: 场景化配置 - 撰写行业调研报告');
  console.log('='.repeat(60));

  const researcher = new Researcher();
  const advisor = new Advisor();
  const recorder = new Recorder();

  const topic = '2026 年人工智能发展趋势报告';

  console.log('\n📝 主题:', topic);
  console.log('\n✍️  开始撰写...\n');

  const research = await researcher.process(topic);
  
  const review = await advisor.process(JSON.stringify(research.documents));
  
  const doc = await recorder.process('整理调研报告');

  console.log('\n✅ 报告撰写完成!');
  console.log(`📄 文档状态：${doc.success ? '成功' : '失败'}`);

  return { research, review, doc };
}

async function runAllExamples() {
  try {
    await example1_FullWorkflow();

    await example2_SimpleWorkflow();

    await example3_SingleAgent();

    await example4_CodeReview();

    await example5_ReportWriting();

    console.log('\n' + '='.repeat(60));
    console.log('🎉 所有示例运行完成!');
    console.log('='.repeat(60));
  } catch (error) {
    console.error('\n❌ 示例运行失败:', error);
  }
}

runAllExamples()
  .then(() => {
    console.log('\n✓ 演示结束');
  })
  .catch(error => {
    console.error('\n✗ 错误:', error);
  });
