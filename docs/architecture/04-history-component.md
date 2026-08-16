# 第四步：HistoryComponent 历史统计组件解析

解析对象：entry/src/main/ets/components/HistoryComponent.ets。

## 1. 组件为什么存在

HistoryComponent 是月迹的“统计展示页”：

    Index.markedDays
        -> derivePeriods
        -> predictNextPeriod
        -> 历史列表、柱体、预测文案

它被单独构建出来，是因为历史页同时需要：

- 将日期事实解释为经期摘要；
- 显示下一次经期估算；
- 将每次经期显示成日期 + 时长柱体；
- 处理空历史状态；
- 在适用的布局中承载 ActionMenu。

它不产生新的日期事实，也不负责保存或导入数据。所有导入、导出和关于操作都通过回调返回 Index。

## 2. 与上下游的关系

### 上游：ResponsivePageShell

页面壳传入：

| 输入 | 作用 |
| --- | --- |
| markedDays | 统计和历史行的唯一事实输入 |
| refreshToken | 拼接到根节点 id，强制历史区域重建 |
| embeddedInScroll | 决定自身是否使用 auto 高度 |
| compactHistory | 切换简化历史分支 |
| showActionMenu | 决定是否在组件内部挂载菜单 |
| layoutMetrics | 提供历史间距、柱体偏移和菜单尺寸 |

页面壳负责决定当前是哪种布局；HistoryComponent 只根据传入的三个显示开关组织内部结构。

### 下游：领域函数

HistoryComponent 直接调用：

- derivePeriods(markedDays, todayKey())：生成经期摘要；
- predictNextPeriod(periods)：生成预测结果；
- formatShortDate(startDate)：生成历史行日期文本。

派生结果只在渲染过程中生成，不写回 Preferences。

### 同级：ActionMenuComponent

HistoryComponent 在 single/dual 中承载 ActionMenu；scroll 模式由 ResponsivePageShell 承载，compact 模式不显示菜单。

HistoryComponent 只保存菜单是否展开的局部状态，并把菜单动作继续转发给 Index。

## 3. 三种内部展示分支

### 普通历史页

当 compactHistory=false 且 embeddedInScroll=false：

    HistoryComponent
      ├─ 内部 Scroll
      │   └─ 标题、预测、空状态或历史列表
      └─ 可选 ActionMenu

内部 Scroll 使用 nestedScroll SELF_FIRST。点击滚动区域时，如果菜单展开，则关闭菜单。

### 嵌入 scroll 页面

当 embeddedInScroll=true：

    外层 Scroll
      └─ HistoryComponent
          └─ 标题、预测、空状态或历史列表

组件不再创建自己的 Scroll，根高度改为 auto，避免和页面壳的外层纵向滚动形成双重容器。

### compact 历史页

当 compactHistory=true：

    HistoryComponent
      └─ 内部 Scroll
          └─ 仅历史行或空白占位

此分支不显示标题、预测和 ActionMenu，只复用历史行、年份标识和柱体逻辑。

## 4. 统计数据流

HistoryComponent 没有统计状态字段，所有结果都从 markedDays 重新派生：

    markedDays
      -> currentPeriods()
          -> derivePeriods(markedDays, todayKey())
      -> currentPeriodsDescending()
          -> 按 startDate 倒序显示
      -> currentPrediction()
          -> predictNextPeriod(currentPeriods())

每个 PeriodSummary 再进入：

    buildHistoryPeriodItem
      -> buildPeriodRow
          -> formatShortDate(startDate)
          -> periodRatio(period)
          -> periodBarOffset(period)
          -> ongoing ? 进行中 : durationDays + 天

柱体比例以当前历史中最大的 durationDays 为 100%，实际宽度为比例乘以 82%。最大值至少为 1，避免空数据或异常数据造成除零。

## 5. 历史行的展示规则

每条历史行包含：

- 左侧月日文本；
- 中间水平柱体；
- 右侧时长文本或“进行中”。

柱体颜色：

- 已结束经期使用 PERIOD_COLOR；
- 最后一条进行中经期使用 ACCENT_COLOR。

年份标识由 shouldShowYearDivider 决定：

- 列表按日期倒序；
- 第一条记录如果不属于当前年份，显示它的年份；
- 后续记录只在与上一条记录年份不同时显示年份。

periodRenderKey 由开始日期、时长和 ongoing 状态组成，用于 ForEach 稳定识别历史行。

## 6. 空状态与操作入口

普通历史页没有记录时显示：

- “还没有历史记录”；
- 引导文字；
- “导入已有记录”按钮；
- 虚线圆角占位框。

有记录时，普通历史页不显示空状态导入按钮，导入/导出/关于动作由 ActionMenu 提供。

compact 历史页没有导入按钮，也没有 ActionMenu；它只显示虚线占位或历史行。

## 7. 菜单通信

HistoryComponent 的 actionMenuOpen 是局部状态：

    ActionMenuComponent.onOpenChange(open)
        -> HistoryComponent.actionMenuOpen

菜单项动作再向上传递：

    ActionMenuComponent
        -> onImport / onExport / onAbout
            -> HistoryComponent 同名回调
                -> ResponsivePageShell
                    -> Index

HistoryComponent 不知道导入弹层或导出文件的具体实现。

## 8. refreshToken 的真实作用

refreshToken 不参与经期计算，也不改变任何展示数值。它只进入根节点 id，例如 history-content-加上-refreshToken。

ResponsivePageShell 还会把同一个 dataRevision 放入不同布局下的历史区域 id。这样做是为了在 Swiper 或离屏页面缓存旧派生列表时，强制历史区域获得新的节点身份。

因此 refreshToken 是 UI 生命周期耦合，不是领域版本号。后续若改用更直接的刷新机制，必须保留“日期事实变化后历史页一定重建”的行为。

## 9. 当前明确的边界问题

只记录代码中已经明确存在的问题：

1. currentPeriods() 在同一次渲染中被多个路径重复调用；每次都会重新执行 derivePeriods、normalizeDays 和未来日期过滤。
2. 每个历史行的 periodRatio 会重新计算 periodScaleMax；periodScaleMax 又重新调用 currentPeriods。历史行越多，重复派生越多。
3. shouldShowYearDivider 为每一行重新生成倒序列表并查找当前行索引，存在重复排序和查找。
4. compactHistory 分支仍接收 onImport、onExport、onAbout 三个回调，但该分支不渲染 ActionMenu，也没有其它按钮调用它们；这些输入在 compact 实例中没有消费者。
5. compactHistory、embeddedInScroll、showActionMenu 是三个独立布尔属性，组件允许多种组合，但不同组合的容器和菜单语义并不相同；当前正确组合依赖 ResponsivePageShell 的调用约定。
6. HistoryComponent 同时承担统计视图和 ActionMenu 承载；菜单状态与统计展示状态位于同一个组件，但菜单实际业务动作属于 Index。

## 10. 本步骤结论

HistoryComponent 的核心职责是：

    markedDays
      -> 派生 PeriodSummary / Prediction
          -> 展示历史行、柱体和预测

ActionMenu 是它的附属承载职责，不是统计逻辑的一部分。后续整理时，必须先保留两条边界：

- 统计结果只能由 markedDays 派生；
- 菜单动作只能通过回调返回 Index。
