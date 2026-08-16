# 第二步：ResponsivePageShell 页面壳解析

解析对象：

- entry/src/main/ets/components/ResponsivePageShell.ets
- entry/src/main/ets/domain/ResponsiveLayout.ets

本章只解析“页面如何组合和适配窗口”，不解析 CalendarComponent 和 HistoryComponent 内部如何画月历、计算统计。

## 1. 组件定位

ResponsivePageShell 是当前应用的布局适配器：

    Index
      -> ResponsivePageShell
          -> CalendarComponent
          -> HistoryComponent
          -> ActionMenuComponent

它做三件事：

1. 接收 Index 的事实数据、窗口数据和业务回调。
2. 根据窗口尺寸选择 compact、single、dual、scroll 四种页面结构。
3. 把同一份 markedDays、dataRevision、布局参数和回调传给下层组件。

它不负责：

- 读取 Preferences；
- 读取或保存文件；
- 计算经期时长；
- 计算下一次预测；
- 决定某个日期是否属于经期事实。

## 2. 输入与局部状态

### 输入属性

| 属性 | 来源 | 用途 |
| --- | --- | --- |
| markedDays | Index | 同时传给日历和历史 |
| dataRevision | Index | 让历史区域的 id 发生变化，触发重建 |
| viewportWidth、viewportHeight | Index 的窗口监听 | 选择布局模式和计算尺寸 |
| safeAreaTopInset、safeAreaBottomInset | Index 的系统避让区 | 计算可用高度和上下留白 |
| densityPixels | Index 的显示屏信息 | 将像素安全区换算为 vp |

### 局部状态

| 状态 | 使用位置 | 作用 |
| --- | --- | --- |
| currentPage | compact、single 的 Swiper | 保存当前是日历页还是历史页 |
| scrollActionMenuOpen | scroll 模式 | 控制页面壳固定菜单的展开状态 |

页面壳没有自己的业务事实状态。currentPage 和 scrollActionMenuOpen 都是展示状态。

## 3. 回调通信

页面壳接收四个回调：

| 回调 | 最终动作 |
| --- | --- |
| onToggleDate(date) | 交回 Index.toggleDate |
| onImport() | 交回 Index.openTextImportDialog |
| onExport() | 交回 Index.exportJson |
| onAbout() | 交回 Index 打开关于窗口 |

页面壳不修改回调代表的业务状态，只负责把回调放到正确的子组件上。

## 4. 模式选择

build() 先调用 ResponsiveLayout.resolveRuntimeLayoutMetrics，读取返回的 mode，然后选择一个布局构建方法。

模式判定由 classifyLayoutMode(width, height) 完成，使用完整窗口矩形，而不是去掉系统安全区后的内容尺寸：

| 模式 | 当前判定 |
| --- | --- |
| compact | 宽高都不超过 1000，宽高比 0.82–1.22 |
| scroll | 宽高比小于 0.6 或大于 1.8 |
| dual | 大尺寸标准横向窗口，或大尺寸近方形横向窗口 |
| single | 其余有效窗口；宽高无效时也回退到 single |

判定顺序很重要：compact 先于 scroll，scroll 先于 dual，最后才是 single。

例如：

- 980 × 980：compact；
- 2584 × 1828：dual；
- 1080 × 2444：scroll；
- 1320 × 2120：single。

这些边界已经在 ResponsiveLayout.test.ets 中有单元测试。

## 5. 四种布局的实际结构

### 5.1 compact

结构：

    vertical Swiper
      ├─ CalendarComponent(compact=true)
      └─ HistoryComponent(compactHistory=true, showActionMenu=false)

特点：

- 仍然有日历页和历史页，不是只渲染日历。
- 历史页隐藏操作菜单，使用 compactHistory 分支。
- 外层 Swiper 纵向切换，禁止循环，隐藏指示器。
- cachedCount(0)，避免历史页复用旧的离屏内容。
- 历史区域 id 包含 dataRevision。

这里要记录一个“实现与部分旧描述可能不同”的事实：当前代码的 compact 模式仍包含简化历史页，不能只根据旧文档把它理解成纯日历模式。

### 5.2 single

结构：

    vertical Swiper
      ├─ CalendarComponent
      └─ HistoryComponent(showActionMenu=true)

特点：

- 日历和历史分别占满一个页面。
- 使用 currentPage 记录当前页。
- 外层 Swiper 不循环，隐藏指示器。
- cachedCount(0)。
- 历史页 id 包含 dataRevision。

single 是默认的主要页面结构，也是 Pura X 单页基线对应的运行模式。

### 5.3 dual

结构：

    horizontal Row
      ├─ 左侧 Column(layoutWeight=1)
      │    └─ CalendarComponent
      └─ 右侧 Column(layoutWeight=1)
           └─ HistoryComponent(showActionMenu=true)

特点：

- 不使用外层纵向 Swiper。
- 日历和历史各占一列。
- 左右区域共享同一份 markedDays。
- 历史面板 id 包含 dataRevision。
- 月历自己的横向换月行为由 CalendarComponent 负责，页面壳不介入。

### 5.4 scroll

结构：

    外层纵向 Scroll
      └─ Column
          ├─ CalendarComponent(scrollLayout=true)
          └─ HistoryComponent(embeddedInScroll=true, showActionMenu=false)
    外层 Scroll 之上
      └─ 固定 ActionMenuComponent

特点：

- 日历和历史连续出现在一个纵向滚动容器中。
- HistoryComponent 使用 embeddedInScroll=true，改为自适应高度，避免内部再占满整屏。
- 历史自身不显示菜单，菜单由页面壳固定在窗口右下角。
- 点击外层滚动区域时关闭固定菜单。
- 固定菜单的开关状态由 scrollActionMenuOpen 持有。

## 6. RuntimeLayoutMetrics 的作用

resolveRuntimeLayoutMetrics 接收：

    width
    height
    safeAreaTopInset
    safeAreaBottomInset
    densityPixels

并返回一个 RuntimeLayoutMetrics 对象，内容包括：

- 当前 mode；
- 原始窗口宽高；
- 安全区和内容高度；
- 日历顶部/底部留白；
- 日历内容宽度、标题字号、年月按钮尺寸；
- 日期网格高度、行距、日期尺寸；
- 历史间距、柱体短条偏移；
- ActionMenu 尺寸和边缘留白；
- compactHistoryEnabled、fixedActionMenu 两个模式描述字段。

计算分为两层：

1. 用完整窗口宽高决定结构模式。
2. 用安全区和 densityPixels 计算实际 vp 尺寸与留白。

这样做的结果是：系统安全区会影响内容位置，但不会直接改变 compact/single/dual/scroll 的结构判断。

## 7. 页面壳的通信图

    Index.markedDays
        ├─> CalendarComponent.markedDays
        └─> HistoryComponent.markedDays

    Index.dataRevision
        └─> HistoryComponent.refreshToken
            └─> 历史根节点 id

    Index 窗口状态
        └─> ResponsivePageShell
            └─> resolveRuntimeLayoutMetrics
                └─> Calendar / History / ActionMenu.layoutMetrics

    子组件用户动作
        └─> ResponsivePageShell 回调转发
            └─> Index

页面壳只传递和组合，不建立第二份 markedDays。

## 8. 当前边界问题

这些问题先记录，不在本轮修改：

1. build() 在一次构建过程中多次调用 layoutMetrics()，会重复创建等价的 RuntimeLayoutMetrics 对象。
2. RuntimeLayoutMetrics 中的 compactHistoryEnabled 和 fixedActionMenu 主要用于测试和描述，页面壳实际通过 mode 分支直接决定行为。
3. currentPage 在窗口模式变化时没有显式重置。模式从 single/compact 切换到 dual 再切回来时，旧分页位置可能继续保留。
4. scrollActionMenuOpen 在离开 scroll 模式时没有显式清理，重新进入 scroll 时是否应保持上次展开状态，需要在 UI 验收中确认。
5. compact 分支仍包含历史页，和“compact 只保留核心日历”的部分旧描述存在边界差异。
6. 页面壳同时负责模式选择、四种结构组合和 scroll 菜单承载；它是布局层中最适合后续统筹拆分的对象，但现在不应提前拆。

## 9. 本步骤结论

ResponsivePageShell 的核心不是“响应式样式”，而是一个结构选择器：

    窗口度量
      -> mode
          -> 选择页面结构
              -> 注入相同事实数据
                  -> 转发相同业务回调

下一步解析 CalendarComponent 时，只需要关注它接收的 markedDays、layoutMetrics、compact、scrollLayout 和 onToggleDate；不再重复分析页面壳的四种模式。
