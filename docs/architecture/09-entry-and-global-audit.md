# 第九步：入口与全局引用审查

审查对象：

- entry/src/main/ets/entryability/EntryAbility.ets
- entry/src/main/module.json5
- entry/src/main/resources/base/profile/main_pages.json
- entry/src/test/List.test.ets 及全部测试文件
- entry/src/main/ets/、entry/src/main/resources/ 的全仓引用
- 根目录、docs/ 中与当前工程结构相关的链接和目录描述

本章的目标是收口前八步的事实：确认应用从哪里启动、测试实际注册了什么、哪些导出符号和资源确实没有调用方，以及哪些问题只是文档或元数据漂移。

## 1. 应用启动链路

    HarmonyOS
      -> entry/module.json5: mainElement=EntryAbility
          -> EntryAbility.onWindowStageCreate
              -> WindowStage.loadContent('pages/Index')
                  -> main_pages.json: pages/Index
                      -> pages/Index.ets
                          -> aboutToAppear / onPageShow

### EntryAbility

EntryAbility 只有两个有效运行职责：

1. onCreate() 当前不初始化网络、分析 SDK、推送或其他第三方服务；方法体为空，只保留说明性注释。
2. onWindowStageCreate() 调用 windowStage.loadContent('pages/Index', callback)，加载失败时输出错误码。

它不持有日期事实、不打开 Preferences、不注册窗口尺寸监听，也不参与弹层和导入通信。窗口尺寸、安全区和方向策略从页面创建后由 Index 自己处理。

### module.json5 与页面配置

| 配置 | 当前值 | 实际作用 |
| --- | --- | --- |
| mainElement | EntryAbility | 指定 UIAbility 类 |
| srcEntry | ./ets/entryability/EntryAbility.ets | 指定 Ability 源文件 |
| pages | $profile:main_pages | 指向页面列表资源 |
| main_pages.src | pages/Index | 指定根页面 |
| orientation | auto_rotation | 初始 Ability 方向策略 |
| deviceTypes | phone、tablet、2in1 | 模块声明支持的设备类型 |
| exported | true | 允许系统按 Ability 配置启动 |

Index.applyOrientationPolicy() 运行后还会根据布局模式将 scroll 模式设为竖向偏好，其他模式设为自动旋转。因此 module.json5 的 auto_rotation 是初始配置，运行时方向策略由 Index 二次调整。

## 2. 启动窗口与应用加载页

启动阶段存在两层不同的视觉状态：

    系统启动窗口
      -> start_window.json
          -> start_window_idle.png / start_window_transparent.svg

    Ability 加载页面后
      -> Index.isLoading=true
          -> LoadingComponent
      -> loadLocalData finally
          -> isLoading=false

start_window.json 是系统启动窗口配置，LoadingComponent 是 ArkUI 页面树中的应用加载占位。二者生命周期不同：系统启动窗口由 Ability/系统控制，LoadingComponent 由 Index.isLoading 控制；不能把其中一个按普通未使用 UI 删除。

## 3. 测试入口与实际覆盖

### List.test.ets

当前唯一显式的测试聚合入口调用五个测试注册函数：

    List.test.ets
      ├─ TextDateParser.test.ets
      ├─ ImportValidator.test.ets
      ├─ JsonTransfer.test.ets
      ├─ ResponsiveLayout.test.ets
      └─ MenstrualData.test.ets

测试文件通过 @ohos/hypium 的 describe/it/expect 注册测试。entry/src/test/ 没有覆盖页面组件、EntryAbility 或 Preferences 的测试文件。

### 覆盖矩阵

| 区域 | 当前测试 | 未覆盖的具体路径 |
| --- | --- | --- |
| TextDateParser | 日期格式、重复、非法日期、年份和紧凑格式 | 与 JSON 回填、用户编辑组合后的行为 |
| ImportValidator | 未来日期、已有日期、问题保留 | Index.continueTextImport() 与确认页切换 |
| JsonTransfer | 纯 JSON 候选解析、重复和 schema 错误 | DocumentViewPicker、文件读取、文件大小、导出写入、JsonTransfer.import() |
| ResponsiveLayout | 模式判定和运行时度量 | 真实窗口事件、方向切换和组件重排 |
| MenstrualData | 两组经期时长 | normalizeDays、预测、中位数规则、日历格生成 |
| DateUtils | 无直接测试 | 合法性、跨日计算、非法键、时区/DST 边界 |
| PreferencesStore | 无 | 打开失败、损坏数据、读写失败、欢迎标记持久化 |
| EntryAbility / Index | 无 | Ability 页面加载、启动恢复、手动记录、确认落库、窗口监听 |
| ArkUI 组件 | 无 | 四种布局、弹层、菜单、日历交互、历史刷新和 UI 层级 |

当前测试体系是纯函数回归测试，不是应用流程集成测试。List.test.ets 只保证上述五个测试注册函数被调用，不覆盖未导入的模块和组件。

## 4. 全局代码引用结果

### 4.1 已确认有运行时调用方的主要对象

| 对象 | 调用方/入口 |
| --- | --- |
| EntryAbility | module.json5.mainElement |
| Index | main_pages.json 的 pages/Index |
| ResponsivePageShell、页面和弹层组件 | Index.build() 或页面壳内部组合 |
| PreferencesStore.open/loadDays/saveDays | Index.loadLocalData()、toggleDate()、confirmImport() |
| JsonTransfer.selectDateCandidates/export | Index.loadJsonIntoTextImport()、exportJson() |
| parseTextDates、validateImportDates | Index.continueTextImport() |
| derivePeriods、predictNextPeriod | HistoryComponent |
| ResponsiveLayout 导出函数 | Index、ResponsivePageShell、组件默认度量和测试 |
| action_menu.svg | ActionMenuComponent 的 app.media.action_menu |
| 启动窗口资源 | module.json5、start_window.json |

### 4.2 当前仓库无业务调用方的对象

这些对象经过源码和测试目录引用检索，当前没有业务调用方：

| 对象 | 当前位置 | 当前判断 |
| --- | --- | --- |
| JsonImportResult | data/JsonTransfer.ets | 与 JsonTransfer.import() 绑定的备用返回模型；不是当前页面路径 |
| JsonTransfer.import() | data/JsonTransfer.ets | 未接入页面，且绕过 ImportValidator 和确认流程 |
| CalendarCell | domain/MenstrualData.ets | 只服务于未接入的 buildCalendarCells() |
| buildCalendarCells() | domain/MenstrualData.ets | 当前日历组件使用自己的连续日期生成逻辑，二者不等价 |
| DateUtils.monthTitle() | domain/DateUtils.ets | 无调用方的日期标题格式化函数 |
| history_export.svg | entry/src/main/resources/base/media/ | 没有 app.media.history_export 或其他源码引用 |

这些是全局清理候选，但不能全部按同一类死代码处理：前两组属于未接入的备用数据模型/第二套日历模型，monthTitle 和 history_export.svg 才更接近无调用方的独立对象。

### 4.3 不应误判为无用的对象

- Index.@Preview 没有生产调用方，但它是 DevEco Preview 入口标记，不是业务死代码。
- EntryAbility.onCreate() 虽然为空，但它是 Ability 生命周期覆盖点；其当前作用是明确没有额外初始化。是否删除只能作为空生命周期覆盖项单独处理，不能与未引用函数混同。
- start_window_idle.png、start_window_transparent.svg、app_icon.svg 和资源字符串/颜色都由配置文件引用，不能因为 ArkTS 源码中没有资源调用而删除。
- List.test.ets 的测试导入不是业务引用；它只服务测试注册，不能从生产调用图判断为无用。

## 5. 配置、资源与文档漂移

以下是当前仓库中可以直接确认的非业务代码问题：

1. README.md 引用 ./docs/assrt/阔折叠参考_1.png，该文件当前不存在。docs/assrt 属于其他 agent 的资产范围，本次只记录，不修改。
2. README.md、docs/README.md 和产品设计文档引用 docs/research/responsive-layout.md，当前实际文件位于 docs/_archive/responsive-layout.md。
3. README.md 的技术结构仍列出 parser/ 目录，但仓库没有该目录；当前 JSON 代码位于 data/JsonTransfer.ets，文本解析位于 domain/TextDateParser.ets。
4. entry/oh-package.json5 声明 main 为 Index.ets，仓库不存在 entry/Index.ets；实际 Stage 入口由 module.json5.mainElement 和 main_pages.json 指向 EntryAbility/pages/Index。该字段当前没有参与已确认的页面启动链路，是元数据一致性候选，不等同于运行时入口。
5. history_export.svg 仍位于模块资源目录，但当前导出操作使用文字按钮，没有资源引用；它与配置引用的启动资源不同。

## 6. 当前明确的入口与全局边界问题

1. **入口错误只有日志出口。** EntryAbility.onWindowStageCreate() 加载页面失败时只输出错误码，没有页面级错误状态或备用页面；EntryAbility 也没有重试或恢复分支。当前页面只有在 loadContent 成功后才会进入 Index。

2. **空的 onCreate 是生命周期覆盖项，不是功能代码。** 当前方法没有运行逻辑，唯一内容是说明无网络/第三方初始化；它与真正被调用的 Ability 生命周期方法混在同一个类中，属于后续可单独核对的空覆盖。

3. **测试入口没有覆盖跨模块行为。** 纯函数测试不能证明 EntryAbility -> Index -> PreferencesStore 的启动恢复，也不能证明 TextImportComponent -> Index -> ImportValidator -> PreferencesStore 的确认落库。当前任何组件/入口重构都缺少自动化流程护栏。

4. **未引用对象的性质不同。** JsonTransfer.import()/JsonImportResult 和 buildCalendarCells() 是有完整实现的备用协议/第二套模型；monthTitle() 与 history_export.svg 没有任何当前调用方。后续清理必须按类别分别验证，不能用一次全局删除处理。

5. **启动方向配置存在两层来源。** module.json5 初始声明 auto_rotation，Index 在窗口尺寸变化后又设置偏好方向；入口配置和页面运行策略不是单一来源。保留窗口模式行为时，不能只改其中一层。

6. **文档与资源引用存在可见断链。** 缺失的展示图片、归档后的布局文档链接和不存在的 parser/ 目录不会直接改变运行时，但会使工程结构说明和实际仓库不一致；它们不应混入业务重构提交中无记录地改变。

## 7. 全局审查结论

当前应用的运行入口足够简单：

    module.json5
      -> EntryAbility
          -> main_pages.json
              -> pages/Index
                  -> loadLocalData / window metrics / page components

当前生产代码中已经确认的无业务调用方对象为：

    JsonTransfer.import + JsonImportResult
    CalendarCell + buildCalendarCells
    DateUtils.monthTitle
    history_export.svg

其中前两组仍带有独立实现和不同数据语义，不能在未决定责任归属前删除；后两项可以进入最终清理候选。测试、配置和文档层还存在明确缺口，但本轮不把它们改造成新的架构层，只作为最终统筹规划的证据。
