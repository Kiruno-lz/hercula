# 重构边界与观察项

本文件只记录下一阶段重构需要核对的对象，不在架构解析阶段删除代码、不改 UI、不调整业务规则。

阶段顺序和每阶段验证条件见[初步重构计划](./10-refactor-plan.md)；本文件保留对象级边界和清理候选，不重复展开执行步骤。

## 1. 当前高耦合点

### `Index.ets` 同时承担四种角色

它同时是页面根组件、应用状态容器、导入控制器和窗口适配生命周期对象。后续如果拆分，应优先把“无 UI 的输入编排”和“窗口事件适配”迁出，但保持 `Index` 仍是唯一状态汇聚点，避免一次重构引入多个事实源。

### `HistoryComponent` 既是统计视图又是操作菜单容器

统计派生、柱体布局、空状态和菜单挂载都在同一个组件。single/dual 需要菜单，compact/scroll 又由父层改变菜单策略。后续可拆出统计视图和菜单承载，但必须保留四种布局的菜单可见性。

### `ResponsiveLayout.ets` 的职责过宽

同一文件内既有模式判定，也有大量设计基线和组件尺寸。下一步可以按“模式判定”和“运行时度量”拆开，但不应把尺寸常量散落到各个 UI 组件，否则会破坏多设备一致性。

### 导入链路存在两种 JSON 入口模型

当前页面实际使用：`selectDateCandidates -> 回填文本 -> parseTextDates -> validateImportDates -> 用户确认`。`JsonTransfer.import -> JsonImportResult` 是另一条当前无调用方的直接导入模型，并且不执行 `ImportValidator`，会绕过未来日期、已有日期和确认步骤。两条路径的语义不等价，不能按普通重复函数直接删除或合并。

### JSON 问题状态与可编辑文本脱钩

`loadJsonIntoTextImport()` 只把合法去重日期回填到文本框，却把 JSON 的 `invalidTokens`、`duplicateDates` 留在 `jsonImportIssues`；`continueTextImport()` 再把这些旧问题与当前文本解析问题拼接。用户修改或清空文本时，原 JSON 问题仍会进入确认结果，问题状态没有随文本内容重建。

### 导入候选协议存在重复定义

`TextDateParseResult` 和 `JsonDateCandidateResult` 具有完全相同的三个字段，但定义在不同模块；`Index.jsonImportIssues` 又使用文本解析结果类型承载 JSON 问题。当前依赖结构兼容而没有共享协议，属于可以在纯类型层核对的重复边界。

### 弹层组件重复覆盖层结构并共享分散状态

`TextImportComponent`、`ImportConfirmationComponent`、`WelcomeComponent`、`AboutComponent` 都各自实现全屏遮罩和卡片外壳，但关闭语义、卡片尺寸和 `zIndex` 不同；`LoadingComponent` 则是 `isLoading` 分支下的互斥页面。四个弹层的打开状态由 `Index` 的独立布尔值持有，互斥关系依靠回调顺序、挂载顺序和固定层级共同维持。后续整理时需要分别处理外壳重复和状态协议，不能把加载页与覆盖层合并。

### 导入确认存在跨组件异步交互边界

`ImportConfirmationComponent` 只能发出无参数的 `onConfirm()`，`Index` 在回调中启动异步 `confirmImport()`；组件没有接收持久化进行中的状态，因此确认期间没有代码层面的重复点击保护。确认页的展示行还只遍历 `candidateDates` 和 `invalidTokens`，而摘要与状态反查依赖其他分类数组，行模型和校验结果模型并不完全一致。

### 数据基础层把错误折叠成默认值

`PreferencesStore.open()` 即使获取 Preferences 失败也返回实例；`loadDays()`、`hasSeenWelcome()` 在读取或解析异常时分别返回空数组和 `false`；`saveDays()`、`markWelcomeShown()` 吞掉写入异常且不返回结果。当前 `Index` 无法区分“没有本地记录”和“本地存储不可用”，也无法确认保存是否成功。

### 事实规范化与运行时来源校验不一致

`normalizeDays()` 只检查 `date`，不检查 `source`；JSON 文件解析会检查来源枚举，但 Preferences 恢复和导出前规范化不会重新检查。损坏的本地条目可能保留非法来源并进入下一次导出。

### 日期派生规则有隐式输入前提

`DateUtils.parseDateKey()` 会让非法日期发生 `Date` 进位，日期运算函数依赖调用方先通过 `isValidDateKey()`；`predictNextPeriod()` 依赖输入周期已按开始日升序，并在偶数间隔时取上侧中位位置。当前调用链满足这些前提，但函数签名没有表达或验证它们。

### 入口与测试没有流程级护栏

`EntryAbility` 只负责 `loadContent('pages/Index')`，加载失败只有日志出口；`List.test.ets` 只聚合五组纯函数测试，没有覆盖 `EntryAbility`、`Index`、Preferences、文件选择器或 ArkUI 组件。当前重构不能把纯函数测试通过误认为启动、恢复、确认落库和 UI 通信都已有保护。

### 全局引用存在代码、资源和文档三种漂移

当前无业务调用方的对象包括 `JsonTransfer.import()`/`JsonImportResult`、`CalendarCell`/`buildCalendarCells()`、`DateUtils.monthTitle()` 和 `history_export.svg`；它们分别属于备用协议、第二套日历模型、独立未使用函数和未引用资源。另有 README 图片、布局文档链接和 `parser/` 目录描述与仓库不一致，这些不应与业务代码删除混在一起。

## 2. 未使用或疑似冗余对象

以下对象有当前代码证据，但是否删除要在重构前补充编译/测试和 UI 验收：

| 对象 | 证据 | 初步判断 |
| --- | --- | --- |
| `Index.feedback` | 只有 `Index.ets` 内赋值，没有任何渲染/读取 | 高概率是无效状态；如果产品需要操作反馈，应补上 UI 后再保留 |
| `jsonImportIssues.dates` | 初始化和赋值存在，没有读取方 | 可删除字段，或明确用于确认页；当前不影响功能 |
| `JsonImportResult` 与 `JsonTransfer.import` | 只有定义，`Index` 使用的是 `selectDateCandidates` | 未接入的旧导入模型，优先核对测试和外部引用后清理 |
| `TextDateParseResult` 与 `JsonDateCandidateResult` | 两个接口字段完全相同，`Index` 用前者保存后者结果 | 候选协议重复定义；先确认是否统一类型，不改变运行时行为 |
| `CalendarCell` 与 `buildCalendarCells` | 只在 `MenstrualData.ets` 定义/内部生成，但包含周一偏移、固定 42 格和当前月标记字段 | 与当前 CalendarComponent 不是等价实现；代码中存在两套日历格生成责任，不能仅凭无调用方删除 |
| `DateUtils.monthTitle` | 只有定义，没有调用方 | 未使用格式化函数 |
| `CalendarComponent.isCalendarDayVisible` | 当前日期数组只生成有效日期，调用结果恒为可见 | 逻辑上冗余，但要先确认未来/月卡片布局没有依赖隐藏占位 |
| `SHOW_LAYOUT_MODE_DEBUG=false` | 作为 `@Prop` 传入但常量固定关闭 | 调试开关，不属于业务死代码；应保留在开发期或迁出正式入口 |
| 四个覆盖层中的空遮罩 `onClick` | 文本导入、确认、欢迎弹层用空回调拦截点击；关于弹层则调用关闭 | 不是无条件可删的死代码，删除前必须验证点击是否会穿透到主页面 |
| `JsonTransfer.selectDateCandidates()` 的 `undefined` | 取消选择、读取失败、空文件和超大文件都返回 `undefined` | 当前页面无法区分取消与文件错误；清理时不能把这些分支当成同一种业务结果 |
| `PreferencesStore` 的异常吞掉 | `open/load/save/hasSeenWelcome/markWelcomeShown` 都将失败折叠为默认值或无返回结果 | 不能在重构中误认为“空记录”就是成功恢复；需保留当前内存降级行为直到错误语义单独处理 |

“疑似冗余”不等于本轮删除清单。尤其是 `dataRevision` 虽然是间接刷新手段，但有明确的 `Swiper` 缓存背景，不能按普通未使用变量处理。

## 3. 文档与实现的已知偏差

- `docs/README.md` 的导航仍指向 `./research/responsive-layout.md`，而当前对应材料位于归档目录；架构文档不修复该历史链接，后续文档整理时单独处理。
- 产品/技术设计描述进行中经期时长时倾向于“含首尾天数”，但当前 `derivePeriods` 实际使用日期差并以 1 保底。必须先补行为测试并确认产品规则，再决定实现或文档谁调整。
- 设计文档提到的 `parser/` 目录并不存在；当前 JSON 和文本解析分别位于 `data/`、`domain/`。
- JSON 规格要求导入时过滤未来日期；当前过滤在统一 `ImportValidator` 阶段完成，`parseJsonDateCandidates` 本身只提取候选，这是分层设计而不是缺失。

## 4. 下一阶段建议顺序

1. 先为 `Index` 的手动记录、导入确认、导出反馈和窗口监听补最小行为基线；不先改 UI。
2. 决定并测试 `feedback` 的产品去留；如果保留，明确渲染位置和生命周期；如果删除，连同所有赋值一起删除。
3. 把 `JsonTransfer.import`、`JsonImportResult`、`CalendarCell`、`buildCalendarCells`、`monthTitle` 分别做全仓引用确认；其中 `CalendarCell/buildCalendarCells` 先明确日历格生成责任，再决定是否清理。
4. 在保持 `ResponsivePageShell` 四种模式不变的前提下，拆分布局判定与布局度量。
5. 只有纯逻辑和引用边界稳定后，才考虑把导入编排从 `Index` 迁出。
6. 每次改动后复验：日期点击/二次取消、首次欢迎、JSON 回填、确认导入、未来日期阻断、历史重建、导出取消与四种布局。

## 5. 不可变的验收边界

重构期间以下行为和 UI 结构视为冻结：

- 月历的自绘网格、横向换月、年月跳转和未来日期不可点击。
- 手动日期记录后二次点击取消，并立即保存到本地。
- 历史页的日期倒序、经期柱体、进行中状态、预测提示和空状态入口。
- single/compact 的纵向分页、dual 的左右双排、scroll 的纵向连续滚动。
- 导入文本框、JSON 文件回填、确认页分类、用户确认后才合并。
- 关于软件窗口、首次欢迎窗口、菜单项目和现有颜色/圆角/动效。
