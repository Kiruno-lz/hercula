# 重构边界与观察项

本文件记录重构需要核对的对象、已完成的阶段 1 清理和仍需保留的边界；不改 UI、不调整业务规则。

阶段顺序和每阶段验证条件见[初步重构计划](./10-refactor-plan.md)；本文件保留对象级边界和清理候选，不重复展开执行步骤。

## 1. 当前高耦合点

### `Index.ets` 同时承担三种角色

它同时是页面根组件、应用状态容器和导入控制器。无 UI 的文本导入校验和确认事实转换已迁到 `domain/ImportPipeline.ets`，窗口获取和监听已迁到 `platform/WindowMetricsController.ets`；Index 仍是唯一状态汇聚点，避免一次重构引入多个事实源。

### `HistoryComponent` 既是统计视图又是操作菜单容器

统计派生、柱体布局、空状态和菜单挂载都在同一个组件。single/dual 需要菜单，compact/scroll 又由父层改变菜单策略。后续可拆出统计视图和菜单承载，但必须保留四种布局的菜单可见性。

### `ResponsiveLayout.ets` 的职责过宽

同一文件内既有模式判定，也有大量设计基线和组件尺寸。下一步可以按“模式判定”和“运行时度量”拆开，但不应把尺寸常量散落到各个 UI 组件，否则会破坏多设备一致性。

### 导入链路必须经过统一确认模型

当前页面实际使用：`selectDateCandidates -> 回填文本 -> parseTextDates -> validateTextImport -> 用户确认`。`selectDateCandidates` 只提供文件候选和读取状态，不能直接生成 `MenstrualDay`；未来日期、已有日期和确认前阻断必须由统一校验链路承担。

### JSON 问题状态与可编辑文本脱钩

`loadJsonIntoTextImport()` 只把合法去重日期回填到文本框，却把 JSON 的 `invalidTokens`、`duplicateDates` 留在 `jsonImportIssues`；`continueTextImport()` 再把这些旧问题与当前文本解析问题拼接。用户修改或清空文本时，原 JSON 问题仍会进入确认结果，问题状态没有随文本内容重建。

### 导入候选协议已收束

文本和 JSON 解析现在都返回 `domain/ImportTypes.ets` 中的 `DateCandidateResult`；`Index.jsonImportIssues` 只保留同文件中的 `ImportIssues`。候选协议承载日期候选、无效片段和重复日期，临时问题状态只承载无效片段和重复日期，不承载 JSON 原始 `source` 或校验阶段的未来/已有分类。

### 弹层组件重复覆盖层结构并共享分散状态

`TextImportComponent`、`ImportConfirmationComponent`、`WelcomeComponent`、`AboutComponent` 都各自实现全屏遮罩和卡片外壳，但关闭语义、卡片尺寸和 `zIndex` 不同；`LoadingComponent` 则是 `isLoading` 分支下的互斥页面。四个弹层的打开状态由 `Index` 的独立布尔值持有，互斥关系依靠回调顺序、挂载顺序和固定层级共同维持。后续整理时需要分别处理外壳重复和状态协议，不能把加载页与覆盖层合并。

### 导入确认存在跨组件异步交互边界

`ImportConfirmationComponent` 只能发出无参数的 `onConfirm()`，`Index` 在回调中启动异步 `confirmImport()`；组件仍没有接收持久化进行中的状态，但 `Index.confirmImport()` 已用非 UI 的进行中标记忽略重叠调用，并在 `finally` 中释放标记。确认页的展示行还只遍历 `candidateDates` 和 `invalidTokens`，而摘要与状态反查依赖其他分类数组，行模型和校验结果模型并不完全一致。

### 数据基础层把错误折叠成默认值

`PreferencesStore.open()` 即使获取 Preferences 失败也返回实例；`loadDays()`、`hasSeenWelcome()` 返回带 `status` 的结果，并在失败时分别附带空数组和 `false`；`saveDays()`、`markWelcomeShown()` 返回写入 `status`。当前 `Index` 仍只消费读取结果中的数据字段并忽略保存结果，因此 UI 仍无法显示存储失败，但数据层已经具备明确的可测试边界。

### 事实规范化与运行时来源校验不一致

`normalizeDays()` 只检查 `date`，不检查 `source`；JSON 文件解析会检查来源枚举，但 Preferences 恢复和导出前规范化不会重新检查。损坏的本地条目可能保留非法来源并进入下一次导出。

### 日期派生规则有隐式输入前提

`DateUtils.parseDateKey()` 会让非法日期发生 `Date` 进位，日期运算函数依赖调用方先通过 `isValidDateKey()`；`predictNextPeriod()` 依赖输入周期已按开始日升序，并在偶数间隔时取上侧中位位置。当前调用链满足这些前提，但函数签名没有表达或验证它们。

### 入口与测试没有完整流程级护栏

`EntryAbility` 只负责 `loadContent('pages/Index')`，加载失败只有日志出口；`List.test.ets` 聚合八组纯函数测试，没有覆盖 `Index`、文件选择器或 ArkUI 组件。当前重构不能把纯函数测试通过误认为全部 UI 通信已有保护；启动、手动记录、重启恢复、有效导入、重复/非法分类、空/超大文件、文件选择器取消、导出取消/成功以及 single/compact/dual/scroll 页面已通过独立模拟器操作复核，导出失败仍需页面证据；窗口解绑代码路径已补强并经生命周期复核，但系统没有提供 `Window.off()` 的直接结果或回调计数。

### 全局引用仍有代码与资源边界需要保留

阶段 1 已删除经全仓引用确认的 `DateUtils.monthTitle()` 和 `history_export.svg`；阶段 6 已删除 `JsonTransfer.import()`/`JsonImportResult`、`CalendarCell`/`buildCalendarCells()`。当前仍有 README 图片引用缺失，但它属于 `docs/assrt/` 资产范围；架构导航已统一，不应把该资产问题与业务代码删除混在一起。

## 2. 未使用或疑似冗余对象

以下对象有当前代码证据，但是否删除要在重构前补充编译/测试和 UI 验收：

| 对象 | 证据 | 初步判断 |
| --- | --- | --- |
| `jsonImportIssues` | 只保存 `invalidTokens` 和 `duplicateDates`，候选日期由文本框重新解析 | 已删除未消费的 `dates` 状态字段；保持 JSON 问题与用户编辑文本的现有合并行为 |
| `DateCandidateResult` / `ImportIssues` | 文本和 JSON 解析共用 `DateCandidateResult`；Index 只保存 `ImportIssues` | 已完成协议收束；不要把校验分类或 JSON source 混入候选类型 |
| 四个覆盖层中的空遮罩 `onClick` | 文本导入、确认、欢迎弹层用空回调拦截点击；关于弹层则调用关闭 | 不是无条件可删的死代码，删除前必须验证点击是否会穿透到主页面 |
| `JsonTransfer.selectDateCandidates()` 的结果 | 返回 `JsonCandidateLoadResult.status`，区分取消、读取失败、空文件、超大文件和成功；Index 暂不消费非成功状态 | 保持当前非成功路径静默；后续只能在明确 UI 需求后决定是否展示状态 |
| `PreferencesStore` 的异常降级 | Store 返回 `status` 与默认值；Index 继续使用 `days/seen` 并忽略保存结果 | 不能在重构中把空记录当作成功恢复；保持当前内存降级行为，是否展示失败状态留到后续页面编排阶段 |

“疑似冗余”不等于本轮删除清单。尤其是 `dataRevision` 虽然是间接刷新手段，但有明确的 `Swiper` 缓存背景，不能按普通未使用变量处理。

## 3. 文档与实现的已知偏差

- `docs/README.md` 的导航已指向实际的 `./_archive/responsive-layout.md`，架构入口也已纳入文档导航。
- 产品/技术设计描述进行中经期时长时倾向于“含首尾天数”，但当前 `derivePeriods` 实际使用日期差并以 1 保底。必须先补行为测试并确认产品规则，再决定实现或文档谁调整。
- 当前 JSON 和文本解析分别位于 `data/`、`domain/`；系统窗口适配位于 `platform/`。
- JSON 规格要求导入时过滤未来日期；当前过滤在统一 `ImportValidator` 阶段完成，`parseJsonDateCandidates` 本身只提取候选，这是分层设计而不是缺失。

## 4. 当前剩余验证顺序

1. 已通过系统文件选择器访问空文件和超过 4 MiB 文件；两者均返回文本导入弹层，`JsonCandidateLoadResult.status` 没有被转成页面提示，符合当前代码的非成功状态静默返回边界。
2. 导出失败的受控触发已在 Pura X/Pura 90 被系统边界阻断：目标文件 `/storage/media/100/local/files/Docs/Download/hercula-2026-08-17.json` 由 `file_manager` 用户持有，shell 执行 `chmod 444` 返回 `Permission denied`；shell 在同一目标目录执行 `touch readonly-shell-phase17.json` 也返回 `Permission denied`；可在 `/data/local/tmp` 创建的 `0444` 文件不出现在保存文件选择器的 `Download`/`Documents` 目录中。因而尚不能证明 `JsonTransfer.export()` 的写入异常分支，代码仍对取消和写入异常静默结束，页面没有结果反馈。
3. 阶段 14 已在 Pura X 运行 compact、single 和旋转后的 dual，并在 Pura 90 运行 scroll，确认四种页面组合、菜单挂载和 scroll 固定菜单；四种布局的窗口证据已齐全。
4. 阶段 15 将 `WindowMetricsController.detach()` 的三个 `off()` 调用改为相互独立的异常隔离；阶段 13/15 已通过 HOME 离开后重新启动、折叠和展开后的重新启动复核页面生命周期与窗口恢复。当前系统没有提供 `Window.off()` 的直接返回结果或回调计数，因此只能证明代码会逐项尝试解绑，不能取得系统级调用结果证据。
5. 以上验证完成前，不继续抽取展示层公共外壳，也不删除空遮罩回调；这些对象当前都有可见的代码边界，不能仅凭“未渲染”或“重复”删除。

## 5. 不可变的验收边界

重构期间以下行为和 UI 结构视为冻结：

- 月历的自绘网格、横向换月、年月跳转和未来日期不可点击。
- 手动日期记录后二次点击取消，并立即保存到本地。
- 历史页的日期倒序、经期柱体、进行中状态、预测提示和空状态入口。
- single/compact 的纵向分页、dual 的左右双排、scroll 的纵向连续滚动。
- 导入文本框、JSON 文件回填、确认页分类、用户确认后才合并。
- 关于软件窗口、首次欢迎窗口、菜单项目和现有颜色/圆角/动效。
