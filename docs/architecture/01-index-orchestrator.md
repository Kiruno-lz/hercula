# 第一步：Index.ets 应用编排器解析

解析对象：entry/src/main/ets/pages/Index.ets。

本章只解析 Index，不展开页面壳、日历、历史统计和弹层的内部实现。理解它的关键不是先看它画了什么，而是先看它掌握了什么、调用了谁、哪些动作可以改变事实数据。

## 1. 先建立一个简单认识

可以把 Index 看成当前应用的“总导演”：

外部事件
  - 页面生命周期
  - 用户点击日期
  - 用户导入/导出
  - 窗口尺寸变化
          |
          v
        Index
     /    |     \
  存储  领域函数  页面组件  系统窗口

它本身不负责绘制完整月历，也不负责实现经期统计算法；它负责决定何时调用这些能力，以及把结果放进哪一个状态字段。

## 2. 依赖清单

| 依赖 | 位置 | Index 使用它做什么 |
| --- | --- | --- |
| common.UIAbilityContext | HarmonyOS Ability Kit | 获取应用上下文 |
| display、window | ArkUI | 读取窗口、密度、安全区并设置方向 |
| PreferencesStore | data/PreferencesStore.ets | 读取/保存日期和欢迎标记 |
| JsonTransfer | data/JsonTransfer.ets | 选择 JSON、提取候选、保存导出文件 |
| DateUtils | domain/DateUtils.ets | 格式化日期、获取今天、判断未来 |
| TextDateParser | domain/TextDateParser.ets | 解析文本日期 |
| ImportValidator | domain/ImportValidator.ets | 分类导入候选 |
| ResponsiveLayout | domain/ResponsiveLayout.ets | 决定 scroll 模式的方向策略 |
| 页面/弹层组件 | components/ | 展示状态并把用户动作回调给 Index |

依赖方向是：

Index -> 读取/调用 data + domain
Index -> 传入状态 components
components -> 回调动作 Index

当前没有组件直接访问 PreferencesStore 或 JsonTransfer，这是现有架构最重要的边界之一。

## 3. 状态分组

### 3.1 事实数据

    @State private markedDays: Array<MenstrualDay> = [];

这是应用唯一的日期事实源：日历根据它显示标记，历史根据它计算统计，导出根据它生成 JSON，导入确认后把新日期合并回它。日期变化必须经过 toggleDate 或 confirmImport。

### 3.2 刷新与反馈

    @State private dataRevision: number = 0;
    @State private feedback: string = '';

dataRevision 不是业务数据。每次手动记录或确认导入后递增，再传给页面壳改变历史区域的 id，目的是规避 Swiper 离屏缓存导致的历史列表不重建。

feedback 保存“已记录”“已取消”“导出失败”等文本，但当前只有写入，没有任何 UI 读取或展示。它现在不是有效的用户反馈通道。

### 3.3 弹层状态

    welcomeDialogOpen
    aboutDialogOpen
    textImportDialogOpen
    importConfirmationOpen

这些布尔值控制 build() 中对应组件是否挂载。它们彼此独立，不是一个枚举，因此状态模型理论上允许多个弹层同时为 true；正常流程依靠回调顺序避免这种情况。

### 3.4 导入临时状态

    textImportInput       文本框内容
    textImportNotice      JSON 加载提示
    jsonImportIssues      JSON 解析阶段的问题
    importValidation      确认页的完整分类结果

这些都不是本地事实。取消导入或确认导入后会清理，不应进入 Preferences，也不应出现在导出文件中。

### 3.5 窗口状态

    windowWidth / windowHeight
    densityPixels
    safeAreaTopInset / safeAreaBottomInset

默认值用于预览器或窗口 API 不可用时保持可渲染。真实窗口可用时，Index 将它们传给页面壳计算布局参数。窗口对象和已应用方向属于非响应式资源状态。

## 4. 生命周期

### 页面出现

    aboutToAppear()
      -> loadLocalData()
          -> 获取 UIAbilityContext
          -> 打开 PreferencesStore
          -> 读取 markedDays
          -> 检查欢迎标记
          -> 首次打开：写欢迎标记并打开欢迎弹层
          -> finally：isLoading = false

加载结束前只显示 LoadingComponent。读取失败时保留空内存记录并写入 feedback，但由于反馈没有 UI 消费者，用户当前看不到错误文本。

当前行为还包括：欢迎标记在弹层打开前就写入。如果应用刚打开欢迎窗口就退出，下次不会再次显示。

### 窗口监听

    onPageShow()
      -> refreshWindowMetrics()
          -> 获取当前 Window
          -> 窗口变化时解绑旧监听、绑定新监听
          -> 读取 windowRect
          -> 读取 display density
          -> 读取系统避让区
          -> 更新 Index 的窗口状态

监听 windowSizeChange、windowRectChange 和 avoidAreaChange。窗口变化只影响布局和方向，不改变日期事实。

### 页面隐藏

onPageHide 解绑三个窗口监听，清空窗口引用和方向缓存。每个解绑操作单独捕获异常，以应对窗口已经被系统销毁的情况。

## 5. 操作与状态变化

| 动作 | 方法 | 状态变化 | 是否写本地 |
| --- | --- | --- | --- |
| 首次加载 | loadLocalData | markedDays、欢迎状态、isLoading | 可能写欢迎标记 |
| 点击未标记日期 | toggleDate | 新增日期、dataRevision、反馈 | 保存日期 |
| 再次点击日期 | toggleDate | 删除日期、dataRevision、反馈 | 保存删除后的日期 |
| 点击未来日期 | toggleDate | 不改变事实 | 不写 |
| 打开导入 | openTextImportDialog | 清空临时状态、打开弹层 | 不写 |
| 加载 JSON | loadJsonIntoTextImport | 回填文本、保存 JSON 问题、提示 | 不写 |
| 点击继续 | continueTextImport | 生成校验结果、切换确认弹层 | 不写 |
| 返回修改 | closeImportConfirmation | 关闭确认、重新打开文本弹层 | 不写 |
| 确认导入 | confirmImport | 合并日期、dataRevision、关闭弹层 | 保存日期 |
| 导出 | exportJson | 更新反馈 | 写用户选择的文件 |

## 6. 两条核心闭环

### 手动记录

    CalendarComponent
      -> onToggleDate(date)
          -> Index.toggleDate(date)
              -> 未来日期：直接返回
              -> 已存在：从 markedDays 移除
              -> 不存在：追加 source=manual
                  -> dataRevision += 1
                      -> PreferencesStore.saveDays

日历组件和 Index 各检查一次未来日期。真正改变事实数据的地方只有 Index。

### 导入确认

    文本输入 / JSON 文件
      -> continueTextImport
          -> parseTextDates
          -> 合并 JSON 阶段的问题
          -> validateImportDates
          -> ImportConfirmationComponent
              -> 返回：回到文本弹层
              -> 确认：validDates 映射为 MenstrualDay
                  -> 合并 markedDays
                  -> 保存并递增 dataRevision
                  -> 清理临时状态

Index 负责编排，不负责实现语法解析、JSON 文件读取或候选分类。

## 7. build() 的作用

build() 做的事情很少但很关键：

1. isLoading=true 时挂载启动页。
2. 加载完成后挂载 ResponsivePageShell，把事实数据、窗口数据和四个业务回调传下去。
3. 按布尔状态条件挂载导入文本框、导入确认、欢迎和关于窗口。
4. 所有子组件事件最终重新调用 Index 私有方法。

因此，build() 是“状态到组件”的出口；toggleDate、confirmImport、exportJson 等方法是“事件到状态/外部系统”的入口。

## 8. 当前边界问题

这些是观察项，不是本轮修改项：

1. Index 同时管理事实数据、导入临时状态、窗口资源和弹层，是后续最适合分层的文件。
2. feedback 没有 UI 消费者，所有反馈文案当前都不会显示。
3. jsonImportIssues.dates 只被赋值，没有被读取。
4. PreferencesStore.saveDays 吞掉保存异常，因此 Index 只能确认内存更新，不能确认磁盘写入成功。
5. JsonTransfer.export 用 false 同时表达“取消”和“写入失败”，Index 可能把写入失败提示成“已取消导出”。

## 9. 本步骤结论

当前 Index 汇聚四条流程：

    事实数据流：markedDays -> 保存 -> 页面组件
    导入数据流：输入 -> 解析 -> 校验 -> 确认 -> markedDays
    窗口适配流：Window -> 窗口度量 -> 页面壳
    弹层控制流：布尔状态 -> 条件挂载 -> 回调回 Index

下一步解析页面壳时，只需沿着 Index.build() 传出的这些输入继续向下追踪，不需要重新解释存储、导入算法或窗口 API。
