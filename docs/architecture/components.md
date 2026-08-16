# 组件与通信

## 1. 组件树与依赖方向

```text
EntryAbility
└── Index (@Entry)
    ├── LoadingComponent
    ├── ResponsivePageShell
    │   ├── CalendarComponent
    │   ├── HistoryComponent
    │   │   └── ActionMenuComponent
    │   └── scroll 模式下的 ActionMenuComponent
    ├── TextImportComponent
    ├── ImportConfirmationComponent
    ├── WelcomeComponent
    └── AboutComponent
```

依赖方向当前是单向的：

```text
页面状态(Index)
  ├─ props ─> 页面壳/展示组件
  └─ callbacks <─ 用户动作

页面状态(Index)
  ├─> PreferencesStore / JsonTransfer
  └─> domain 纯函数
```

组件之间没有共享可变单例，没有 `@Link`，也没有事件总线。`@State` 只出现在拥有局部交互的组件中，应用级 `@State` 集中在 `Index`。

## 1.1 组件协议总表

| 组件 | 状态拥有者 | 输入 | 输出/回调 | 直接外部依赖 |
| --- | --- | --- | --- | --- |
| `EntryAbility` | HarmonyOS Ability | `WindowStage` | 页面加载回调 | WindowStage |
| `Index` | 自身 | Ability context、Window 事件、子组件回调 | 更新事实、流程和窗口状态 | Preferences、文件选择器、domain |
| `ResponsivePageShell` | 自身持有分页/scroll 菜单状态 | 日期事实、刷新 token、窗口度量 | 转发记录和菜单动作 | ResponsiveLayout |
| `CalendarComponent` | 自身 | `markedDays`、布局参数 | `onToggleDate(date)` | `todayKey()` |
| `HistoryComponent` | 自身持有菜单状态 | `markedDays`、刷新 token、布局参数 | 导入/导出/关于回调 | MenstrualData、DateUtils |
| `ActionMenuComponent` | 父组件 | 展开状态、布局参数 | 展开变化和三个业务回调 | 无业务外部依赖 |
| `TextImportComponent` | `Index` | 文本、提示 | 输入、加载 JSON、取消、继续 | 无 |
| `ImportConfirmationComponent` | `Index` | `ImportValidationResult` | 返回、确认 | 无 |
| `WelcomeComponent` | `Index` | 无 | 开始记录、导入 | 无 |
| `AboutComponent` | `Index` | 仓库地址 | 关闭 | 无 |
| `LoadingComponent` | `Index.isLoading` | 无 | 无 | 无 |

其中只有 `Index` 能改变 `markedDays`、调用持久化和文件操作；其他组件即使触发用户动作，也只能通过回调请求 `Index` 执行。

## 2. 应用入口与状态编排

### `entryability/EntryAbility.ets`

- `onWindowStageCreate` 调用 `windowStage.loadContent('pages/Index', ...)`，失败时只写错误日志。
- 它不持有业务数据，也不参与页面之间通信。

### `pages/Index.ets`

`Index` 是当前的应用控制器和根视图。职责可以分成四组：

| 职责 | 主要状态/方法 | 结果 |
| --- | --- | --- |
| 数据事实 | `markedDays`、`toggleDate`、`persistDays` | 手动记录和导入结果进入内存并写入本地 |
| 导入导出 | `openTextImportDialog`、`loadJsonIntoTextImport`、`continueTextImport`、`confirmImport`、`exportJson` | 管理页面状态，调用 ImportPipeline 编排解析/校验/确认转换并处理文件操作 |
| 弹层状态 | `welcomeDialogOpen`、`textImportDialogOpen`、`importConfirmationOpen`、`aboutDialogOpen` | 条件挂载覆盖层 |
| 窗口适配 | `platform/WindowMetricsController`、`refreshWindowMetrics` | 把窗口矩形、安全区和密度快照传给页面壳 |

应用级状态清单：

- `markedDays`：当前日期事实集合，组件树的唯一业务数据源。
- `dataRevision`：每次写入后递增，用于改变历史区域的 `id`，规避 `Swiper` 离屏缓存导致的派生列表不重建。
- `jsonImportIssues`：保存 JSON 解析阶段的 `invalidTokens` 和 `duplicateDates`；候选日期只进入文本框，不在该临时问题状态中重复保存。
- `jsonCandidateLoaded`：仅标记成功加载且尚未被用户编辑的 JSON 文本，用于让空 JSON 进入现有确认页；打开、关闭、继续或编辑文本时清除。
- `importValidation`：确认窗口的完整预览模型，包含候选、可导入、未来、重复、已存在和无效内容。
- 窗口状态：`windowWidth`、`windowHeight`、安全区上下边距、密度；默认值用于预览器或窗口 API 不可用时的渲染。

这些状态并不等价：`markedDays` 是事实，`importValidation` 和 `jsonImportIssues` 是一次导入会话的临时结果，`dataRevision` 只是 UI 重建信号，窗口字段只服务布局。它们不能在重构时合并成一个通用页面状态对象而不保留原有生命周期。

生命周期：

1. `aboutToAppear` 异步调用 `loadLocalData`。
2. `onPageShow` 调用 `refreshWindowMetrics`，由 `WindowMetricsController` 注册窗口尺寸、矩形和系统避让区监听。
3. `onPageHide` 让 `WindowMetricsController` 解绑监听并清空窗口引用。
4. 本地加载无论成功失败都会在 `finally` 中结束 `isLoading`；失败时保留内存空数据并设置反馈文本。

`PreferencesStore.open()` 即使打开失败也返回实例；读取方法返回带 `status` 的结果并附带空数组或 `false` 降级值，保存方法返回 `status`。`Index` 当前只消费读取结果中的数据字段并忽略保存结果，因此生命周期仍只保证页面继续渲染，不保证本地恢复或保存成功；失败区别已经保留在数据层，尚未接入 UI。

## 3. 页面壳与布局

### `components/ResponsivePageShell.ets`

这是组合组件，不读取文件、不计算经期统计。它接收：

| 输入 | 用途 |
| --- | --- |
| `markedDays` | 同时传给日历和历史 |
| `dataRevision` | 作为历史区域的重建 token |
| `viewportWidth/Height`、`safeAreaTop/BottomInset`、`densityPixels` | 生成运行时布局度量 |

回调只有四个：`onToggleDate`、`onImport`、`onExport`、`onAbout`。因此页面壳是纯粹的“布局适配器 + 回调转发器”。

四种布局：

| 模式 | 结构 | 关键通信/状态 |
| --- | --- | --- |
| `compact` | 纵向 `Swiper`，日历页 + 简化历史页 | 历史隐藏操作菜单，`compactHistory=true` |
| `single` | 纵向 `Swiper`，日历页 + 完整历史页 | 历史自带菜单，`cachedCount(0)` |
| `dual` | 横向 `Row`，左日历右历史 | 不使用外层页面 `Swiper` |
| `scroll` | 外层纵向 `Scroll`，日历和历史连续排列 | 历史隐藏自己的菜单，页面壳固定一个菜单 |

`currentPage` 是页面壳的局部分页状态。`scrollActionMenuOpen` 是 scroll 模式的局部菜单状态；点击外层滚动区域时关闭菜单。

页面模式变化不会重置 `currentPage` 或 `scrollActionMenuOpen`；它们是独立的局部状态，模式切换时是否保留旧值属于当前实现行为。页面壳也不拥有弹层状态，弹层仍由 `Index` 条件挂载。

### `domain/ResponsiveLayout.ets`

`classifyLayoutMode(width, height)` 只使用完整窗口像素尺寸判定模式，顺序为 `compact` → `scroll` → `dual` → `single`：

- `compact`：宽高都不超过 1000，宽高比 `0.82–1.22`。
- `scroll`：宽高比小于 `0.6` 或大于 `1.8`。
- `dual`：标准条件为宽高都大于 1000 且宽高比 `1.3–1.8`；另有大尺寸近方形横向例外。
- 其他有效尺寸为 `single`，无效尺寸也回退到 `single`。

`resolveRuntimeLayoutMetrics` 在同一个文件中继续计算顶部留白、日历尺寸、历史间距、操作菜单尺寸和模式开关。它把安全区从像素换算为 vp，但模式判定仍使用完整窗口尺寸。

## 4. 核心展示组件

### `components/CalendarComponent.ets`

输入：`markedDays`、`compact`、`scrollLayout`、`layoutMetrics`；输出：`onToggleDate(date)`。

局部状态：

- `calendarDate`：当前显示月份，默认当前月份。
- `calendarRenderVersion`：A/B 两套轨道交替渲染，用于切换后让网格重新构建。
- `calendarDragOffset`、`calendarViewportWidth`、`calendarAnimationDuration`、`calendarSwipeSettling`：月历横向拖拽和回弹动画。
- `jumpMode`：年面板、月面板或关闭。

实现特点：

- 手工生成前月、当月、后月三个卡片，使用 `Stack`、`Grid`、`ForEach` 和 `PanGesture`，不使用系统 Calendar 模板。
- 月份切换只改变本组件的 `calendarDate`，不会修改应用数据。
- 年份候选为当前显示年份前 5 年到后 6 年；月份候选为 1–12 月。
- 日期是否被标记通过 `markedDays.some` 判断；未来日期在组件内不触发回调，`Index` 也再次检查，形成两层保护。
- 组件直接读取传入的 `markedDays`，不调用 `normalizeDays`；事实集合的规范化责任在存储边界和 domain 派生函数，不在日历展示层。
- 视觉尺寸全部从 `RuntimeLayoutMetrics` 读取；组件不知道设备型号。

当前网格实际只生成当月的 1 到最后一天，并直接放入 7 列 Grid，没有加入第一天之前的星期偏移；日历格生成责任已收敛在 `CalendarComponent`，详见[第三步解析](./03-calendar-component.md)。

### `components/HistoryComponent.ets`

输入：`markedDays`、`refreshToken`、`embeddedInScroll`、`compactHistory`、`showActionMenu`、`layoutMetrics`；输出：`onImport`、`onExport`、`onAbout`。

它不保存统计结果，只保存 `actionMenuOpen`。渲染过程为：

1. `derivePeriods(markedDays, todayKey())` 得到按日期升序的经期摘要。
2. 拷贝后按开始日倒序显示。
3. `predictNextPeriod(currentPeriods())` 生成预测文案。
4. 以所有经期中最大 `durationDays` 为比例尺，计算各柱体宽度。
5. 年份变化时在行上方显示年份标识；短柱体按布局参数增加偏移。

完整历史页包含标题、下一次预计、空状态/历史列表和操作菜单。`compactHistory` 只展示列表并允许内部滚动，不展示标题、预测和菜单。`embeddedInScroll` 让自身高度变为 `auto`，避免嵌入页面的外层 `Scroll` 被内部整页高度限制。

`refreshToken` 本身不参与统计，只拼接到根节点 `id`。它是对 ArkUI/Swiper 缓存行为的重建补丁，后续重构需要保留等价的刷新保证，不能只删除字段。

历史组件依赖传入的 `markedDays` 已是可比较的日期键；它不自行校验 `source` 或非法日期。`currentPeriods()`、`periodScaleMax()` 和年份分隔判断在一次渲染中会重复派生数据。

### `components/ActionMenuComponent.ets`

这是受控菜单：`actionMenuOpen` 由父组件传入，`onOpenChange` 通知父组件，三个菜单项分别触发 `onImport`、`onExport`、`onAbout`。它只负责展开/收起动画、视觉层级和按钮事件，不决定业务动作。

菜单出现位置由 `RuntimeLayoutMetrics` 控制。single/dual 由 `HistoryComponent` 承载；scroll 由 `ResponsivePageShell` 单独承载；compact 隐藏。

single/dual 与 scroll 使用两套菜单状态拥有者和外层定位容器；`ActionMenuComponent` 只拥有菜单内部的受控展示，不负责外部点击关闭和最终定位。

## 5. 弹层组件

| 组件 | 输入 | 回调 | 当前职责 |
| --- | --- | --- | --- |
| `LoadingComponent` | 无 | 无 | `isLoading=true` 时展示启动占位，不读数据 |
| `WelcomeComponent` | 无 | `onStart`、`onImport` | 首次打开说明和“开始记录/导入数据”入口 |
| `TextImportComponent` | `textImportInput`、`textImportNotice` | 输入变化、加载 JSON、取消、继续 | 只收集输入，不解析、不写数据 |
| `ImportConfirmationComponent` | `ImportValidationResult` | 返回、确认 | 只展示候选状态，不修改数据 |
| `AboutComponent` | `repositoryUrl` | 关闭 | 展示项目说明和仓库地址 |

`LoadingComponent` 不与主页面叠加，而是 `isLoading` 分支下的互斥启动页；其余四个组件以全屏 `Stack` 覆盖在根页面上，通过 `zIndex` 分层。真正的覆盖层互斥逻辑不在组件内部，而在 `Index` 的布尔状态和回调中。详细挂载、关闭和导入确认边界见[第六步解析](./06-modal-components.md)。

覆盖层还没有接收安全区或 `RuntimeLayoutMetrics`，卡片尺寸由各自固定常量决定。四个覆盖层的空遮罩 `onClick` 与关于页的关闭点击语义不同；这些回调不能只按“空函数”或“重复结构”删除。

## 6. 通信契约

当前不存在跨组件共享状态；所有通信可归纳为下表：

| 来源 | 目标 | 方式 | 语义 |
| --- | --- | --- | --- |
| `Index` | `ResponsivePageShell` | `@Prop` | 传递事实日期、窗口度量和重建 token |
| `ResponsivePageShell` | `CalendarComponent/HistoryComponent` | `@Prop` | 分发同一份事实数据和布局参数 |
| 子组件 | `Index` | 函数回调 | 请求记录日期、打开导入/导出/关于、确认导入 |
| `Index` | `PreferencesStore` | 直接调用 | 恢复、保存日期和欢迎标记 |
| `Index` | `JsonTransfer` | 直接调用 | 选择 JSON、解析候选、保存导出文件 |
| `Index` | domain 纯函数 | 直接调用 | 解析文本、校验导入、判定未来日期和布局模式 |

重构时优先保持这个单向契约。若把逻辑迁出 `Index`，新模块应接收明确参数并返回明确结果，不能通过隐式全局状态反向修改 UI。

需要特别保留的通信顺序：

1. `CalendarComponent` 只发出日期字符串，真正的未来日期检查和事实变更在 `Index`。
2. `TextImportComponent` 的 JSON 按钮只请求文件候选加载，继续按钮才触发文本解析和校验。
3. `ImportConfirmationComponent.onConfirm()` 不携带日期，`Index.confirmImport()` 只读取 `validDates` 后写入事实。
4. `ActionMenuComponent` 点击菜单项时先通知父组件关闭，再触发导入/导出/关于回调。
5. `dataRevision` 不是业务数据，不能用它替代 `markedDays` 或把它下沉到统计组件作为事实版本。
