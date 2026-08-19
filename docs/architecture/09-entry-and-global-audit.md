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

EntryAbility 只有一个有效运行职责：

1. onWindowStageCreate() 调用 windowStage.loadContent('pages/Index', callback)，加载失败时输出错误码。

它不持有日期事实、不打开 Preferences、不注册窗口尺寸监听，也不参与弹层和导入通信。窗口尺寸、安全区和方向策略从页面创建后由 `WindowMetricsController` 处理，Index 只接收快照。

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

`WindowMetricsController` 运行后还会根据布局模式将 scroll 模式设为竖向偏好，其他模式设为自动旋转。因此 module.json5 的 auto_rotation 是初始配置，运行时方向策略由窗口适配边界二次调整。

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

当前唯一显式的测试聚合入口调用八个测试注册函数：

    List.test.ets
      ├─ DateUtils.test.ets
      ├─ TextDateParser.test.ets
      ├─ ImportValidator.test.ets
      ├─ ImportPipeline.test.ets
      ├─ JsonTransfer.test.ets
      ├─ PreferencesStore.test.ets
      ├─ ResponsiveLayout.test.ets
      └─ MenstrualData.test.ets

测试文件通过 @ohos/hypium 的 describe/it/expect 注册测试。entry/src/test/ 没有覆盖页面组件、EntryAbility 或 Preferences 的测试文件。

### 覆盖矩阵

| 区域 | 当前测试 | 未覆盖的具体路径 |
| --- | --- | --- |
| TextDateParser | 日期格式、重复、非法日期、年份和紧凑格式 | 与 JSON 回填、用户编辑组合后的行为 |
| ImportValidator | 未来日期、已有日期、问题保留 | Index.continueTextImport() 与确认页切换 |
| JsonTransfer | 纯 JSON 候选解析、重复和 schema 错误；模拟器已复核文件选择器浏览/取消、有效文件回填、空文件、超过 4 MiB 文件和导出取消/成功；Pura X/Pura 90 的只读目标注入均被文件权限或选择器可见路径阻断 | 导出写入失败 |
| ResponsiveLayout | 模式判定和运行时度量；Pura X 已复核 single 1320×2120、compact 980×980 和旋转后的 dual 2120×1320 页面；Pura 90 已复核 scroll 1320×2856 页面 | 完整窗口事件、方向切换和组件重排 |
| MenstrualData | 时长、规范化、未来日期、预测测试 | 真实 CalendarComponent 的日期网格与标记交互 |
| DateUtils | 合法性、跨日计算、格式化测试 | 设备时区/DST 边界 |
| PreferencesStore | `PreferencesStore.test.ets`：fake backend 受控覆盖 | 真实 ArkData 的打开/成功读写由模拟器覆盖；操作系统级权限或沙箱故障未强行注入 |
| EntryAbility / Index | 模拟器：页面启动、启动恢复、手动记录、重启恢复和二次取消；导入回填/确认/落库、重复分类、非法 schema、空文件、超过 4 MiB 文件、文件选择器取消、导出取消/成功；single/compact/dual/scroll 页面；HOME 离开后重新启动；折叠/展开后的页面恢复；阶段 15 的独立解绑路径 | 导出失败和系统级 `Window.off()` 返回结果/回调计数 |
| ArkUI 组件 | 无；single/compact/dual/scroll 页面已有截图和布局树证据 | 弹层全覆盖、菜单、日历交互、历史刷新和 UI 层级的完整组合 |

当前测试体系是纯函数和受控数据边界回归测试，不是应用流程集成测试。List.test.ets 只保证已注册测试入口被调用，不覆盖未导入的模块和组件。

## 4. 全局代码引用结果

### 4.1 已确认有运行时调用方的主要对象

| 对象 | 调用方/入口 |
| --- | --- |
| EntryAbility | module.json5.mainElement |
| Index | main_pages.json 的 pages/Index |
| ResponsivePageShell、页面和弹层组件 | Index.build() 或页面壳内部组合 |
| PreferencesStore.open/loadDays/saveDays | Index.loadLocalData()、toggleDate()、confirmImport() |
| JsonTransfer.selectDateCandidates/export | Index.loadJsonIntoTextImport()、exportJson() |
| validateTextImport、createImportedDays | Index.continueTextImport()、confirmImport() |
| derivePeriods、predictNextPeriod | HistoryComponent |
| ResponsiveLayout 导出函数 | Index、ResponsivePageShell、组件默认度量和测试 |
| action_menu_rose.svg、action_menu_sage.svg、action_menu_coral.svg、action_menu_indigo.svg | ActionMenuComponent 按当前主题选择的展开按钮图标 |
| 启动窗口资源 | module.json5、start_window.json |

### 4.2 当前仓库无业务调用方的对象

阶段 6 已对生产源码、测试入口和配置引用完成复核，当前没有待删除的独立无调用方对象。

### 4.3 不应误判为无用的对象

- Index.@Preview 没有生产调用方，但它是 DevEco Preview 入口标记，不是业务死代码。
- EntryAbility 已不再覆盖空的 onCreate 生命周期；其唯一入口行为是加载 `pages/Index`。
- start_window_idle.png、start_window_transparent.svg、app_icon.svg 和资源字符串/颜色都由配置文件引用，不能因为 ArkTS 源码中没有资源调用而删除。
- List.test.ets 的测试导入不是业务引用；它只服务测试注册，不能从生产调用图判断为无用。

## 5. 配置、资源与文档漂移

以下是当前仓库中可以直接确认的非业务代码问题：

1. README.md 引用 ./docs/assrt/阔折叠参考_1.png，该文件当前不存在。docs/assrt 属于其他 agent 的资产范围，本次只记录，不修改。
2. docs/README.md、研究入口和产品设计文档已统一指向 docs/_archive/responsive-layout.md。
3. README.md 的技术结构已改为列出实际存在的 platform/ 目录；当前 JSON 代码位于 data/JsonTransfer.ets，文本解析位于 domain/TextDateParser.ets。
4. `entry/oh-package.json5` 不再声明无效的 `main` 字段；实际 Stage 入口由 `module.json5.mainElement` 和 `main_pages.json` 指向 `EntryAbility/pages/Index`。

## 6. 当前明确的入口与全局边界问题

1. **入口错误只有日志出口。** EntryAbility.onWindowStageCreate() 加载页面失败时只输出错误码，没有页面级错误状态或备用页面；EntryAbility 也没有重试或恢复分支。当前页面只有在 loadContent 成功后才会进入 Index。

2. **测试入口没有覆盖全部跨模块行为。** 纯函数测试不能证明 TextImportComponent -> Index -> ImportValidator -> PreferencesStore 的确认落库；这条有效导入、重复分类、非法 schema、空文件、超大文件、导出成功/取消、HOME 离开后重新启动以及 single/compact/dual/scroll 页面已有模拟器证据。导出失败仍未触发；`detach()` 的三个解绑调用已有独立异常隔离和生命周期复核，但系统不暴露 `Window.off()` 的返回结果或回调计数。

3. **当前未发现待清理的生产无调用方对象。** JSON 直接导入模型和第二套日历格模型已经删除，并通过全仓引用、测试和构建复核。

4. **启动方向配置存在两层来源。** module.json5 初始声明 auto_rotation，`WindowMetricsController` 在窗口尺寸变化后又设置偏好方向；入口配置和页面运行策略不是单一来源。保留窗口模式行为时，不能只改其中一层。

5. **仍有一条文档资源断链。** README.md 引用的展示图片位于 `docs/assrt/`，文件当前不存在；它不改变运行时，且属于其他 agent 的资产范围，本计划不修改。其他已纳入本次审查的架构导航已统一到归档路径。

## 7. 全局审查结论

当前应用的运行入口足够简单：

    module.json5
      -> EntryAbility
          -> main_pages.json
              -> pages/Index
                  -> loadLocalData / window metrics / page components

阶段 6 已清理未接入的直接 JSON 导入模型和第二套日历格模型；阶段 15 又补强了窗口解绑路径。当前系统能力专项验证已覆盖有效导入、重复分类、非法 schema、空文件、超大文件、文件选择器取消、导出取消、导出成功、HOME 离开后重新启动以及 single/compact/dual/scroll 页面，仍剩导出失败和系统级 `Window.off()` 结果不可观测的明确边界，不再保留备用业务模型。
