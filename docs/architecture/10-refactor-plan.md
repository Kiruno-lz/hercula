# 初步重构计划

状态：阶段 0 已建立纯逻辑行为基线；阶段 1 已清理确认的独立死代码；阶段 2 已完成事实与存储边界收束；阶段 3 的导入协议已收束；阶段 4 的代码拆分和导入/导出页面复核已完成；阶段 5 已完成展示层边界核对；阶段 6 已完成最终引用、布局和文档收口。

本计划建立在 [第九步入口与全局引用审查](./09-entry-and-global-audit.md) 和三份汇总文档之上：

- [运行流程与数据流](./data-flow.md)
- [组件与通信](./components.md)
- [数据模型与业务规则](./data-model.md)

## 1. 重构目标

在不改变现有功能、页面结构、颜色、圆角、动效和四种布局行为的前提下：

1. 减少 Index 中混合的流程编排、窗口适配和 UI 状态处理；
2. 统一导入候选、校验和确认的通信协议；
3. 明确事实数据、持久化和派生统计的边界；
4. 删除有全仓引用证据证明无用的代码和资源；
5. 让每个阶段都有可执行的行为验证，而不是依赖最终一次整体验收。

## 2. 不可改变的行为基线

重构期间以下行为视为冻结：

| 范围 | 必须保持的行为 |
| --- | --- |
| 日期事实 | MenstrualDay.date 仍是唯一事实键；同一天最多一条记录 |
| 手动记录 | 点击过去/今天日期记录，再次点击取消；未来日期不触发记录 |
| 历史统计 | 按当前 derivePeriods 规则计算时长、进行中状态、年份分隔和柱体比例 |
| 预测 | 保留至少三个经期开始日、最近最多十二个周期间隔的时间加权概率范围、最新开始日锚点和可替换排卵策略 |
| 导入 | 解析/校验阶段不写入；只有确认 validDates 后才合并和保存 |
| JSON | 保留 schema v1 的字段检查、候选去重和来源合法性检查 |
| 页面模式 | compact、single、dual、scroll 的组合结构和菜单可见性不变 |
| 弹层 | 欢迎、文本导入、确认、关于的挂载顺序、按钮行为和关闭语义不变 |
| 启动 | EntryAbility 仍加载 pages/Index；系统启动窗口和 LoadingComponent 仍是两层状态 |
| 隐私 | 数据默认只在本地；导入/导出仍由用户主动选择文件 |

## 3. 阶段顺序

### 阶段 0：建立当前行为基线

目标：在改动前把当前实现中最容易被重构改变的行为固定成测试或可复现检查。

工作范围：

- 已补充 DateUtils 的合法日期、跨年、日期加减和本地日期键测试；
- 已补充 normalizeDays 的非法日期、重复日期和最后来源覆盖测试；未来日期保留由现有 `normalizeDays` 输入约束和 `derivePeriods` 的过滤规则分别固定；
- 已补充 `predictNextPeriod`/`predictCycleForecast` 的周期数量不足、时间加权概率范围、最新开始日锚点和排卵窗口测试；
- 已补充 JSON 候选回填文本、文本继续、问题合并、已有/未来/有效分类的组合测试；
- 保留四种布局的现有 ResponsiveLayout 测试；
- 阶段 0 当时未覆盖 PreferencesStore 的打开/读取/保存失败行为；该边界已在阶段 2 通过可替换 backend 的受控测试补齐；
- Index 的确认前后 `markedDays`、`dataRevision` 变化尚未直接测试，当前组合测试只验证不写入的校验阶段结果。

完成条件：

- 现有纯函数测试继续通过；
- 导入确认的 validDates、未来、已有、重复、无效分类有固定断言；
- 确认前不写入的校验阶段已固定；
- Index 确认回调对 `markedDays` 的写入和 `dataRevision` 的递增仍需通过 ArkUI/页面集成路径验证，未提前标记为完成。

本阶段不做：

- 不改变 UI；
- 不改变错误提示内容；
- 不删除未接入的备用模型；
- 不把测试替换成新的抽象框架。

阶段 0 当前结果：

- 新增 `entry/src/test/DateUtils.test.ets`、`entry/src/test/ImportPipeline.test.ets`，扩展 `entry/src/test/MenstrualData.test.ets` 和 `entry/src/test/List.test.ets`；
- 当前 `DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk hvigorw test --no-daemon`：56 项通过，0 失败，0 错误；
- `DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk hvigorw assembleApp --no-daemon --no-incremental`：构建成功；未配置签名，因此只保留未签名产物；
- 生产代码、UI 代码、`docs/assrt` 未修改；
- 不能从本阶段结果推出 PreferencesStore、文件选择器、文件读写、EntryAbility 生命周期或 Index ArkUI 提交路径已经通过测试；这些仍是下一步集成验证的明确边界。

### 阶段 1：清理独立、无调用方对象

前置条件：阶段 0 完成，并完成一次全仓引用复核。

本阶段已处理：

- 删除无生产调用方的 `DateUtils.monthTitle`；
- 删除无资源引用的 `history_export.svg`；

保留为后续核对项：

- EntryAbility 只保留实际的 WindowStage 页面加载职责，已删除空的 onCreate 覆盖；
- 与当前文档和资源相关的断链，单独作为文档/资源提交处理，不混入业务重构。

明确不在本阶段删除：

- dataRevision；
- 任何弹层遮罩空 onClick；
- Preview 标记和启动窗口资源。

完成条件：

- 全仓搜索不再出现被删除对象的生产引用；
- 模块构建和现有测试通过；
- 启动窗口、菜单图标和页面入口资源仍可解析。

阶段 1 当前结果：

- `DateUtils.monthTitle` 已从 `entry/src/main/ets/domain/DateUtils.ets` 删除；
- `history_export.svg` 已从模块资源目录删除；
- `EntryAbility.onCreate` 已删除；最新 HAP 在 Pura X 模拟器成功安装并启动，页面入口行为保持不变；
- `JsonTransfer.import`、`JsonImportResult`、`CalendarCell`、`buildCalendarCells` 均已在阶段 6 清理，并通过全仓引用检查、测试和构建复核。

### 阶段 2：稳定事实模型和持久化边界

目标：让日期事实的输入前提和 Preferences 行为可被明确调用，而不改变当前页面结果。

工作顺序：

1. 保留 DateUtils 的本地日期键语义，明确非法输入由哪一层拒绝；
2. 保留 normalizeDays 的去重、排序、非法日期过滤和最后来源覆盖行为；
3. 在不改变现有数据结果的前提下，决定是否为本地 MenstrualDay 增加运行时 source 校验；
4. 将 PreferencesStore 的读取失败、打开失败和保存失败结果表达为可测试的内部结果；
5. 先由 Index 继续按当前降级行为渲染，再单独评估是否需要向用户暴露失败状态；
6. 不引入本地数据迁移，除非先定义当前无版本 JSON 的兼容读取规则。

完成条件：

- 同一输入日期集合在重构前后 normalizeDays 结果一致；
- 历史时长、进行中状态和预测结果一致；
- Preferences 不可用时页面仍保持当前可渲染行为；
- 不把统计结果或布局结果写入 MenstrualDay。

阶段 2 当前结果：

- `PreferencesStore` 现在以 `PreferencesBackend` 表达最小读写协议，并由 ArkData 适配器连接真实 `preferences.Preferences`；`fromBackend()` 只作为受控失败测试入口，不引入事件总线或全局单例；
- `loadDays()`、`hasSeenWelcome()`、`saveDays()`、`markWelcomeShown()` 现在返回明确的 `success`、`unavailable` 或 `failed` 状态；失败时仍返回原有的空数组或 `false` 降级值，Index 只消费降级字段，因此没有新增 UI 文案或页面状态；
- 在 Pura X 独立 `Emulator` 上完成安装、启动和页面截图验证，启动后恢复已有日期标记且没有重复显示欢迎弹层；
- 通过“点击未标记的过去日期 14 日 -> 强制停止并重启 -> 确认 14 日仍被标记 -> 再次点击取消 -> 强制停止并重启”的闭环，确认 `Index` 内存更新、`PreferencesStore.saveDays()` 写入/恢复和二次取消后的持久化结果一致；
- `entry/src/test/PreferencesStore.test.ets` 通过 fake backend 覆盖不可用存储、损坏 JSON、读取失败、`put` 失败、`flush` 失败及欢迎标记读写；真实 ArkData 的成功路径由模拟器验证，操作系统级权限或沙箱故障未在模拟器中强行注入；
- 暂不增加 `normalizeDays()` 的运行时 `source` 过滤：这会在损坏或旧数据场景静默丢弃日期事实，当前没有迁移或错误反馈边界支持该行为；先保持日期合法性规范化与来源检查分属现有入口的规则。

阶段 2 完成判定：事实模型未改变；Preferences 结果协议已有可执行的成功/不可用/失败边界；模拟器成功路径与受控失败路径均有证据；Index 仍保持原有内存降级和 UI 行为。

### 阶段 3：统一导入候选协议

目标：减少文本和 JSON 两套相同结果接口，以及 Index 中分散的导入临时状态转换。

工作顺序：

1. 已把文本和 JSON 的共同结构明确为 `DateCandidateResult` 候选问题协议；
2. 保留 JSON 回填文本、继续时重新解析、用户确认后落库的当前页面路径；
3. 为 JSON 文件取消、读取失败、空文件和超大文件保留可区分的内部结果，但不擅自改变现有 UI 文案；
4. 处理 jsonImportIssues 与用户编辑文本之间的当前行为，先用组合测试固定，再决定是否重建问题数组；
5. 已将未接入的直接 JSON 导入入口删除，页面只保留候选加载和统一确认路径；
6. 保留 ImportValidator 的 duplicateDates 报告语义，不把重复日期直接改成 validDates 排除条件。

完成条件：

- 文本和 JSON 输入经过同一套 ImportValidationResult；
- 未来、已有、重复和无效分类结果与当前一致；
- JSON 中 source 的当前落库语义不被无意改变；
- 空 JSON、文件错误和用户取消都有可验证的分支；
- 确认前不修改 markedDays，确认后只写 validDates。

阶段 3 当前进度：

- 已新增 `entry/src/main/ets/domain/ImportTypes.ets`，由文本解析和 JSON 解析共用 `DateCandidateResult`，Index 只保存 `ImportIssues`；
- 已通过现有 56 项纯逻辑测试和应用构建，解析结果、确认前不写入和页面结构保持不变；
- 已将文件选择取消、读取失败、空文件和超大文件表达为 `JsonCandidateLoadResult.status`，但 Index 仍保持非成功结果静默；
- 已用 `mergeImportIssues()` 和组合测试固定 JSON 问题与用户编辑文本问题继续合并的现有行为；
- 已为成功加载且未编辑的空 JSON 保留一次性来源标记，使其进入现有确认页显示 0 条结果；手动空文本和用户编辑后的空文本仍直接返回；
- `JsonTransfer.import()` / `JsonImportResult` 已删除；`JsonTransfer.selectDateCandidates()` 是唯一文件候选入口，确认落库由 `ImportPipeline` 承担。

### 阶段 4：拆分 Index 的非 UI 编排

前置条件：阶段 2 和阶段 3 的数据协议稳定。

目标：减少 Index 同时管理导入、持久化和窗口生命周期的复杂度，同时保持 Index 为页面状态汇聚点。

建议拆分顺序：

1. 已提取无 UI 的导入编排函数：输入文本、JSON 问题、已有日期和 today，返回 ImportValidationResult；
2. 已提取确认结果到 MenstrualDay[] 的纯转换，保留 source='import'；
3. 已隔离 Window 获取、监听、避让区和方向策略的适配代码；
4. 保留 Index 对弹层布尔值、markedDays、dataRevision 和页面回调的最终所有权；
5. 只有在状态转换稳定后，才处理存储错误结果和异步确认忙状态；无消费者的 `feedback` 状态已删除。

完成条件：

- Index 仍是唯一事实状态拥有者；
- 手动记录、导入确认、导出和窗口变化的 UI 行为不变；
- dataRevision 仍能触发 Swiper 离屏历史重建；
- 窗口监听在 onPageHide 后仍然解绑；
- 拆出的模块不反向访问 UI 状态或使用全局单例。

阶段 4 当前进度：

- `entry/src/main/ets/domain/ImportPipeline.ets` 已承载文本解析、JSON 问题合并、校验分类和确认事实转换；
- `Index` 仍拥有 `markedDays`、`importValidation`、`dataRevision` 和所有弹层状态，只负责调用纯函数并更新页面状态；
- Window 获取、监听、避让区和方向策略已迁到 `entry/src/main/ets/platform/WindowMetricsController.ets`；构建和 56 项纯逻辑测试已重新执行。
- Pura X 模拟器已复核“记录 14 日→重启恢复→再次点击取消→重启确认取消”的持久化闭环，以及 JSON 导出取消、导出到 Download、文件选择器浏览和文件选择器取消。
- 真实导入路径已复核：有效 JSON 回填 3 个日期，确认页分类为“可导入 3 条”，确认后历史页出现 5 月 9 日、6 月 16 日和 7 月 18 日；重复 JSON 分类为“重复 3 条”，非法 schema 留在文本导入弹层并显示具体错误。
- `Index.confirmImport()` 已增加非 UI 的异步防重入标记；模拟器连续点击确认按钮后返回历史页，新增日期只出现一条，未改变确认弹层的视觉结构。
- Pura X 已复核 single（展开态 1320×2120）、compact（折叠态 980×980）和旋转后的 dual（展开态 2120×1320）真实页面；Pura 90 已复核 scroll（1320×2856）页面，确认日历与历史纵向连续、滚动条可见且操作菜单固定在右下角。
- 阶段 13 在 Pura X 上执行了 HOME 离开后重新启动，以及折叠 `980×980`、展开 `1320×2120` 后的重新启动；阶段 14 又通过 `motion,1` 得到 `2120×1320` 并确认日历与历史左右并列，随后用 `motion,0` 恢复展开态；在 Pura 90 上安装同一 HAP 后确认 `1320×2856` 的 scroll 组合。阶段 15 将 `detach()` 的三个 `off()` 调用改为独立异常隔离，并在 Pura X/Pura 90 上复核 HAP 启动与 HOME 恢复。生命周期与四种窗口均未观察到页面结构回归；系统仍不提供 `Window.off()` 的直接结果或回调计数。
- 已通过系统文件选择器访问空文件和超过 4 MiB 文件；两者均回到文本导入弹层，`Index` 不写入 `textImportNotice`，没有改变现有页面文案。
- 仍未完成的系统能力项只有导出写入失败的受控触发；阶段 12/17 已分别证明 `file_manager` 文件不可由 shell 改权限、shell 不能在目标目录创建文件，以及可创建的 `/data/local/tmp` 只读文件不被保存选择器暴露。该路径不能用纯逻辑测试替代，必须继续保留为明确的 E2E 边界。窗口解绑的代码路径已完成独立异常隔离，系统级调用结果因 API 不可观测而单独记录。

### 阶段 5：整理展示组件的重复承载

前置条件：数据协议和 Index 编排边界稳定。

处理顺序：

1. 先核对 ResponsiveLayout 中模式判定与布局度量的拆分，不改变任何断点和数值；
2. 再核对 HistoryComponent 的统计视图与 ActionMenu 承载是否可以物理分离；
3. 再核对 single/dual 与 scroll 的 ActionMenu 外层定位重复；
4. 最后处理四个弹层的重复遮罩/卡片外壳；
5. 每次抽取都保留各组件不同的 zIndex、固定尺寸、遮罩点击、关闭按钮和动效。

完成条件：

- 四种布局的组件组合和菜单显示规则不变；
- 弹层关闭语义不变；
- safe area 和布局度量的输入边界经过明确验证；
- 不把 LoadingComponent 与普通覆盖层合并；
- 不把业务动作下沉到展示组件。

阶段 5 当前结果：

- 已核对 `ResponsiveLayout`、`ResponsivePageShell`、`HistoryComponent`、`ActionMenuComponent` 和四个覆盖层的重复结构；
- 未抽取通用菜单或弹层外壳，因为现有重复结构伴随不同的定位拥有者、点击关闭语义、固定尺寸、zIndex 和动效，参数化后会增加分支而不是减少复杂度；
- 保留现有展示组件边界，避免为了消除文本重复改变 UI 事件传播和四种布局组合。

### 阶段 6：最终无用代码与文档收口

前置条件：前五阶段完成，构建、测试和关键 UI 路径复验通过。

处理对象：

- 确认独立无调用方函数和资源；
- 修正文档失效链接、缺失图片引用和过期目录描述；
- 核对并清理 entry/oh-package.json5 的无效 main 元数据；
- 更新架构文档中的当前实现快照和剩余边界。

完成条件：

- 全仓引用审查与删除清单逐项对应；
- 不存在“删除后才发现是配置入口/测试入口/资源入口”的对象；
- 文档只保留当前实现和最终重构后的指导边界，不保留过渡性架构描述。

阶段 6 当前进度：

- 已删除无业务调用方且绕过统一确认链路的 `JsonTransfer.import()` / `JsonImportResult`；
- `JsonTransfer.import()` / `JsonImportResult`、`CalendarCell` / `buildCalendarCells` 均已删除，当前页面保留唯一实际使用的导入和日历网格路径；
- 文档导航已统一指向归档的响应式布局文档；缺失的设计图片属于 `docs/assrt/` 范围，不修改；`entry/oh-package.json5` 的无效 `main` 已删除并通过构建和启动复核。
- 已补充模拟器中的导入/导出页面证据：有效导入、重复分类、非法 schema、文件选择器取消、导出取消和导出成功均已复核；剩余未验证项按具体系统触发条件记录，不用“已覆盖”替代。
- 已删除固定为 `false` 且没有配置入口的 `SHOW_LAYOUT_MODE_DEBUG` 及其页面壳调试分支；它从未进入正式 UI，不影响现有布局行为。
- 已删除无读取方的 `Index.feedback` 状态及其赋值、恒为 `Visible` 的 `CalendarComponent.isCalendarDayVisible()`，并将无调用方消费的 `JsonTransfer.export()` 返回值改为 `void`；这些改动不改变页面结构或文件写入路径。
- 已收窄 `JsonTransfer` 的导出 payload 类型和 `PreferencesStore` 的操作结果类型为模块内部类型，保留 `JsonCandidateLoadResult`、`PreferencesBackend` 等确有跨边界调用的接口。
- 已删除 `JsonTransfer` 和 `WindowMetricsController` 中只重复代码语义的功能层注释；保留 `ResponsiveLayout`、页面壳和 `Index` 中用于说明 UI 基线与缓存约束的注释。

## 4. 阶段依赖关系

    阶段 0 行为基线
      -> 阶段 1 独立无用对象核对
      -> 阶段 2 事实与存储边界
          -> 阶段 3 导入协议
              -> 阶段 4 Index 编排拆分
                  -> 阶段 5 展示层重复整理
                      -> 阶段 6 全局清理与文档收口

阶段 1 中的独立文档/资源修正可以单独进行，但不能用它替代阶段 0 的行为基线。阶段 4 之前不移动 Index 的事实状态所有权；阶段 5 之前不抽象通用弹窗或通用菜单系统。

## 5. 每个阶段的统一验证清单

每个阶段完成后都必须执行：

- ArkTS/HarmonyOS 模块构建；
- 当前 Hypium 测试入口；
- 手动记录、二次取消、未来日期阻断；
- 首次欢迎、文本导入、JSON 回填、确认返回、确认合并；
- 导入取消、空输入、非法 JSON、文件取消；
- 导出取消、导出成功和导出失败路径；
- 历史空状态、历史记录、预测和刷新；
- compact、single、dual、scroll 四种布局；
- 文档和全仓引用检查。

如果某阶段无法完成某项验证，必须把具体文件、具体路径和未验证原因记录在该阶段变更说明中，不用“基本不影响”替代证据。

## 5.1 测试分层与执行证据

统一验证清单按运行边界拆成三层。不能用低层测试的通过结果代替高层运行时路径的验证。

| 测试层 | 覆盖对象 | 执行方式 | 完成证据 |
| --- | --- | --- | --- |
| 纯逻辑单元测试 | `DateUtils`、`MenstrualData`、`TextDateParser`、`parseJsonDateCandidates`、`ImportValidator`、`ResponsiveLayout` | `hvigorw test --no-daemon` | Hypium 报告中的总数、失败数和具体失败用例 |
| HarmonyOS 运行时集成测试 | `PreferencesStore` 的真实打开/读取/保存；应用上下文、持久化失败降级 | 在 HarmonyOS 测试运行时使用真实 `UIAbilityContext` 和 Preferences 沙箱 | 运行日志、测试结果文件、重启后读取结果；失败分支必须记录触发方式 |
| 系统能力集成/E2E | 文件选择器取消/成功、URI 读取、空文件、超大文件、导出成功/取消/失败 | 在独立 `Emulator` 中运行应用并操作系统文件选择器；可控文件错误需使用明确的测试文件或受控 URI | 模拟器实际页面状态、系统选择器结果、应用日志和导出文件内容 |
| 页面启动与 UI/E2E | `EntryAbility` 启动、欢迎流程、手动记录、未来日期阻断、导入回填/确认/取消、弹层关闭、`markedDays` 和 `dataRevision` 变化 | 在独立 `Emulator` 中启动应用，按用户操作顺序执行 | 页面可见状态、操作后的日期结果、重启后的持久化结果；状态变化不能只凭日志推断 |
| 布局 UI/E2E | compact、single、dual、scroll 的真实组合、菜单挂载、弹层挂载和滚动行为 | 使用对应窗口尺寸在 `Emulator` 中逐模式运行 | 每种模式的页面实际状态和布局检查；不引用 `docs/assrt` 设计稿作为代码行为证据 |

边界约束：

1. `JsonTransfer` 的纯 JSON 解析属于单元测试；文件选择、URI 访问和导出写入不属于解析器单元测试。
2. `PreferencesStore` 的错误语义必须在真实存储 API 或明确的受控错误入口中验证；不能通过手工调用空对象伪造成功或失败。
3. `Index` 的 `markedDays`、`dataRevision` 是 ArkUI 运行时状态，必须通过页面操作和结果观察验证；不能因为导入校验单元测试通过就视为已覆盖。
4. 文件选择器取消、空文件、超大文件和导出失败必须分别记录触发条件；如果当前系统环境无法稳定触发某个分支，记录具体阻断点，不改写成“已验证”。
5. UI/E2E 只验证当前代码的交互和布局行为，不引入设计稿作为额外产品要求，也不把视觉资产纳入本重构范围。

阶段门槛：

- 阶段 0 已完成纯逻辑基线；其余运行时和 E2E 项作为后续集成验证项保留。
- 阶段 1 的无调用方对象清理可以先进行，但每次删除后必须重新执行纯逻辑测试和应用构建；涉及入口、资源或运行时状态的删除，必须先补齐对应的运行时证据。
- 阶段 2 至阶段 5 在变更说明中逐项引用本表对应的测试层和完成证据，不用单元测试总数替代 UI/E2E 结果。

## 6. 当前不进入重构的对象

- 不引入全局状态管理、事件总线或新的 UI 框架；
- 不把 JSON、文本、OCR 合并成未被当前需求证明的通用导入平台；
- 不改变经期时长、预测中位数、未来日期、重复日期的现有计算语义；
- 不在重构阶段补充产品功能或修改视觉设计；
- 不因为测试缺失就删除组件；
- 不把 docs/assrt 资产纳入本计划的业务代码清理范围。
