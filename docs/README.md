# 月迹（hercula）文档入口

月迹是一款纯 HarmonyOS 原生、离线优先的月经周期记录应用。产品只保留三个核心结果：记录经期日、统计经期时长、基于历史记录给出下一次经期的估算。

## 文档导航

- [产品与交互设计](./research/product-design.md)：产品边界、页面结构、状态与视觉方向。
- [技术设计](./research/technical-design.md)：ArkTS/ArkUI 架构、数据模型、导入导出与预测算法。
- [实施方案](./research/implementation-plan.md)：按可运行增量拆解的开发顺序、验收标准与风险控制。
- [需求审查归档](./_archive/requirements-review.md)：对原始想法中的歧义、技术误区和范围偏移进行审查。
- [JSON Schema 规格](./json_SPEC.md)：首版导入导出的数据契约与迁移规则。
- [导入测试案例](./examples/text-date-import-cases.md)：文本日期、JSON、重复、未来和错误 schema 的可复现案例。
- [UI 动效探索](./research/ui-motion-exploration.md)：已实现动效、候选动效和多设备动效约束。
- [响应式布局与组件边界探索](./research/responsive-layout-and-component-boundaries.md)：双排布局、窗口断点与 `Index.ets` 拆分顺序。
- [基础 UI 组件设计任务](./research/ui-component-design-tasks.md)：按组件逐项设计、评审和构建的任务列表。
- [研究资料](./research/README.md)：ArkTS 工具链、官方 API 入口、参考仓库和上架流程。

## 当前决策

1. 首版只做单模块应用，先完善记录、统计、预测、JSON 导入导出和基础 UI 组件；界面 1 的 Pura X 宽折叠展开态已完成。多设备重排随后推进，其中 Pura X 展开横向布局需要支持日历与历史的双排展示。
2. 数据只保存在应用本地；导入和导出由用户主动通过系统文件选择器完成。
3. 首版使用 ArkTS + ArkUI + Stage 模型，图表不引入第三方 UI/图表库；先按稳定的功能边界抽出基础组件，再由响应式页面壳组织单列或双排布局，不为每种设备复制一套页面。
4. 首版导入以 JSON schema 为主，同时补充确定性的简单文本日期解析；文本解析只处理明确的年月日分隔符并先转为 JSON 候选。OCR 导入和小艺/端侧 AI 暂时搁置。
5. 多设备验证以 DevEco 模拟器为主，真机验证降为发布前补充项或模拟器无法覆盖的专项问题。

## 文档约定

本文档以 2026-08-14 的官方资料与当前工程实现为调研基线。DevEco Studio、HarmonyOS SDK 与 API 版本必须在创建工程时记录为实际安装的稳定版本，不能在文档中猜测一个未验证的版本号。当前状态以 README 的能力表和实施方案为准。
