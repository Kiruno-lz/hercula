# 月迹架构解析

状态：当前实现快照（2026-08-16）。

本目录记录当前工程真实代码的组件、数据模型、通信方式和运行流程。它是下一阶段重构的边界基线，不把理想中的分层描述成已经存在的代码。架构解析已完成；阶段 0 已补充纯逻辑行为基线，未改动生产代码与 UI。

## 1. 解析结论

月迹目前是一个单模块、单 `UIAbility`、单入口页面的 ArkTS/ArkUI 应用。实际架构不是完整的 MVVM 或服务层架构，而是：

```text
EntryAbility
  └─ pages/Index.ets                         应用级状态与流程编排器
      └─ components/ResponsivePageShell.ets  窗口模式与页面组合
          ├─ CalendarComponent.ets            月历展示与月份交互
          ├─ HistoryComponent.ets             统计展示与菜单承载
          └─ ActionMenuComponent.ets          导入/导出/关于操作菜单

Index ──> data/PreferencesStore.ets           本地状态持久化
Index ──> data/JsonTransfer.ets               文件选择、JSON 读写与候选解析
Index ──> domain/*.ets                        日期、统计、解析、导入校验、布局纯逻辑
Index ──> modal components                    欢迎、文本导入、导入确认、关于、加载
```

关键事实：

- `Index` 持有 `markedDays`、导入流程状态、窗口度量和持久化对象；目前没有独立的页面状态对象或应用服务对象。
- 展示组件不直接访问 `PreferencesStore`、文件选择器或文件系统，通过 `@Prop` 接收数据、通过回调把用户动作返回给 `Index`。
- `HistoryComponent` 在渲染时调用 `derivePeriods` 和 `predictNextPeriod` 现场派生统计；统计结果不是持久化数据。
- `ResponsiveLayout.ets` 同时负责布局模式判定和大量尺寸/间距计算，是当前最明显的“布局规则集中点”。
- 导入是“两阶段候选确认”：解析器只产生候选和问题，`ImportValidator` 再结合今天日期与现有记录，只有确认回调才写入本地数据。

## 2. 基础组件拆分与解析顺序

解析顺序按调用图从外到内、按用户主流程从启动到数据闭环排列：

| 顺序 | 组件/模块 | 先解析它的原因 | 当前要回答的问题 |
| --- | --- | --- | --- |
| 1 | `EntryAbility` + `Index` | 是唯一入口和最高层编排点 | 应用从哪里启动？谁拥有状态？哪些动作会写数据？ |
| 2 | `ResponsivePageShell` + `ResponsiveLayout` | 决定所有展示组件如何组合 | 窗口尺寸如何变成 `compact/single/dual/scroll`？页面如何通信？ |
| 3 | `CalendarComponent` | 是最短、最核心的手动记录闭环 | 月份状态是否本地持有？日期点击如何回到应用状态？未来日期如何阻断？ |
| 4 | `HistoryComponent` | 消费同一份日期事实并展示统计 | 经期时长和预测怎样派生？历史列表怎样刷新？菜单在哪里挂载？ |
| 5 | `ActionMenuComponent` 与弹层组件 | 承载跨页面操作和导入确认 | 操作如何通过回调回到 `Index`？弹层状态是否互斥？ |
| 6 | `TextDateParser` + `JsonTransfer` + `ImportValidator` | 是唯一复杂数据输入链路 | 输入如何变成候选、问题、有效新增日期？何时才允许落库？ |
| 7 | `PreferencesStore` + `DateUtils` + `MenstrualData` | 收束事实数据、持久化和纯函数规则 | 数据不变量是什么？哪些结果是可重算的？ |
| 8 | 测试与未使用符号 | 验证架构边界并为下一阶段重构定基线 | 哪些路径已有测试？哪些导出函数/状态没有消费者？ |

从第 1 项开始，而不是直接从视觉组件开始，是因为当前组件的全部数据来源、回调目的地和重建策略都由 `Index` 决定。没有先读入口，容易把 `dataRevision`、弹层状态和窗口监听误判成组件内部职责。

## 3. 文档入口

- [第一步：Index 编排器](./01-index-orchestrator.md)：逐状态、逐流程解析当前入口页面。
- [第二步：ResponsivePageShell 页面壳](./02-responsive-page-shell.md)：逐模式解析窗口适配和组件组合。
- [第三步：CalendarComponent 日历组件](./03-calendar-component.md)：解析月份浏览、日期网格和记录事件边界。
- [第四步：HistoryComponent 历史统计](./04-history-component.md)：解析统计派生、历史行和菜单承载。
- [第五步：ActionMenuComponent 操作菜单](./05-action-menu-component.md)：解析受控状态、菜单回调和父级承载边界。
- [第六步：弹层展示组件](./06-modal-components.md)：解析加载、欢迎、导入、确认和关于弹层的挂载与通信。
- [第七步：导入链路](./07-import-pipeline.md)：解析文本、JSON 候选、统一校验和确认落库。
- [第八步：数据基础层](./08-data-foundation.md)：解析本地持久化、日期工具、事实规范化和统计派生。
- [第九步：入口与全局引用审查](./09-entry-and-global-audit.md)：核对启动链路、测试入口、未接入符号和资源/文档漂移。
- [初步重构计划](./10-refactor-plan.md)：按行为基线、数据契约、Index 编排、展示层和最终清理排列执行顺序。
- [组件与通信](./components.md)：逐文件说明组件职责、输入、输出、内部状态和依赖方向。
- [数据模型与规则](./data-model.md)：说明事实数据、派生数据、导入 DTO、本地存储和业务不变量。
- [运行流程与数据流](./data-flow.md)：说明启动、记录、统计、导入、导出和窗口变化的时序。
- [重构边界与观察项](./refactor-boundaries.md)：列出当前架构中的高耦合点、冗余候选和必须保持的 UI/功能约束；本轮只记录，不执行删除。

## 4. 当前解析进度

已完成：

- Index 编排器；
- ResponsivePageShell 与 ResponsiveLayout；
- CalendarComponent；
- HistoryComponent；
- ActionMenuComponent；
- 弹层展示组件：LoadingComponent、WelcomeComponent、TextImportComponent、ImportConfirmationComponent、AboutComponent。
- 导入链路：TextDateParser、JsonTransfer、ImportValidator。
- 数据基础层：PreferencesStore、DateUtils、MenstrualData。
- 入口与全局引用审查：EntryAbility、测试聚合入口、生产符号和资源引用。
- 阶段 0 纯逻辑行为基线：DateUtils、MenstrualData、导入候选/校验组合和现有响应式布局测试已执行。

待分析：无。

全部组件、数据、入口和全局引用分析已完成；阶段 0 的执行结果与未覆盖边界、以及后续重构顺序见[初步重构计划](./10-refactor-plan.md)。

每一项先记录代码目的、输入输出和调用关系，再记录明确的整理边界；最终重构计划等全部模块分析完成后统一制定。

## 5. 阅读与重构约束

后续重构必须遵守以下边界：

1. `MenstrualDay.date` 仍是唯一事实键；不能把经期时长、预测结果或 UI 布局结果写回事实数据。
2. 手动记录、导入确认、导出和本地恢复的用户可见行为保持不变。
3. 组件继续通过输入属性和回调通信，除非先证明当前单向边界不足；不引入全局事件总线。
4. 先给可被测试覆盖的纯逻辑迁移，再迁移 ArkUI 组装代码；每一步都要保持现有 UI 结构和交互。
5. 本文档描述的是代码事实；若产品文档或归档设计与代码不一致，以代码和测试为当前实现证据，并在重构前显式修正文档或补测试。
