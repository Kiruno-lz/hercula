# 月迹响应式布局规范

本文件是月迹当前有效的多设备布局基线和响应式设计规范。历史实施计划、已完成拆分过程和暂不考虑的方案保留在 `docs/_archive/`，不在本文件重复维护。

## 1. 设计原则

- 使用一个 `ResponsivePageShell` 统一选择布局，不为每个设备复制页面和业务状态。
- 运行时依据窗口宽高和布局能力判断，不直接以设备型号作为业务分支。
- `CalendarComponent`、`HistoryComponent` 和导入弹窗共享 `Index.ets` 的状态与回调。
- 日历内部继续使用横向换月；页面级手势由布局模式决定。
- 设备旋转只改变窗口形态，不应重置日期、月份、导入内容或历史滚动状态。
- 宽屏使用最大内容宽度和固定触控目标，不能把日期格随屏幕无限拉伸。

## 2. 窗口度量与模式

页面入口在 `onPageShow` 阶段通过窗口对象的 `windowRect` 获取初始完整窗口尺寸；窗口变化同时监听 `windowSizeChange` 和 `windowRectChange`，页面壳接收最新尺寸并计算：

```text
aspectRatio = viewportWidth / viewportHeight
```

模式判断使用 `WindowProperties.windowRect` 的完整窗口宽高，不使用根组件的 `onAreaChange`、`drawableRect` 或扣除系统安全区后的可绘制区域。安全区只参与内容避让和视觉布局，不参与窗口模式分类；旋转优先通过 `windowSizeChange` 捕获，窗口移动、缩放和折叠变化由 `windowRectChange` 补充更新。

当前布局模式只有四种：

| 模式 | 宽高比规则 | 页面组合 | 手势策略 |
| --- | --- | --- | --- |
| `compact` | 宽高皆不超过 `1000`，且 `0.82 ≤ ratio ≤ 1.22` | 只显示核心日历，隐藏品牌标题 | 日期点击与日历内部横向换月 |
| `single` | `0.6 ≤ ratio < 1.3`，排除已命中的 `compact` | 日历页与历史页纵向排列 | 外层纵向分页，日历内部横向换月 |
| `dual` | `1.3 ≤ ratio ≤ 1.8` 且宽高均大于 `1000`，或高分辨率近方形窗口横屏 | 左侧日历、右侧历史统计 | 取消页面级纵向分页，历史区域独立滚动 |
| `scroll` | `ratio < 0.6`，或 `ratio > 1.8` 的旋转保护回退 | 日历和历史位于同一全高纵向滚动页面 | 只允许整体纵向滚动，不使用纵向分页 |

### 2.1 旋转约束

`scroll` 是直板窄屏的纵向设计，不允许通过横置旋转转化为 `dual`：

- 宽高比小于 `0.6` 的窗口按 `scroll` 设计验证。
- 对应屏幕如果横置后宽高比大于 `1.8`，不得进入 `dual`。
- 当前代码采用两层保护：`ratio > 1.8` 保持 `scroll`，并在 `scroll` 模式将窗口方向策略切回竖屏；其他模式使用 `auto_rotation`，允许旋转后重新分类。产品层仍可根据设备策略进一步限制横置。
- 不允许因为横置后的宽高比变大，就把直板窄屏升级为 `dual`。

### 2.2 Mate X7 特殊规则

Mate X7 只是设备参考名称，不是运行时模式名称。其展开态可能接近 1:1，但分辨率明显大于 Pura X 折叠态，因此不能仅依据宽高比归入 `compact`：

- 高分辨率、接近 1:1 的大窗口横屏允许进入 `dual`，竖屏保持 `single`。
- Pura X 的 `980×980` 小方形窗口继续使用 `compact`。
- 该例外需要同时判断窗口尺寸级别、横竖方向和宽高比；不能依赖字符串匹配 `Mate X7`。
- 如果当前窗口 API 只提供逻辑尺寸，必须先确认逻辑尺寸与设备分辨率的映射，再确定“大窗口”的阈值。

## 3. 多设备基线

以下数据是布局设计和 DevEco 模拟器验收基线，不代表运行时读取设备型号。

| 机型/形态 | 分辨率 | 宽高比 | 目标模式 | 设计重点 |
| --- | ---: | ---: | --- | --- |
| Pura X Max 展开态 | 2584×1828 | 1.414 | `dual` | 日历与历史双排 |
| Pura X Max 折叠态 | 1264×1848 | 0.684 | `single` | 保持完整品牌和日历层级，验证窄竖向内容宽度 |
| Pura X 展开竖向 | 1320×2120 | 0.623 | `single` | 界面 1 当前基准 |
| Pura X 折叠态 | 980×980 | 1.000 | `compact` | 只保留核心日历，不展示 logo |
| Mate X7 展开竖向 | 2210×2416 | 0.915 | `single` | 高分辨率近方形竖屏，不进入双排 |
| Mate X7 展开横向 | 2416×2210 | 1.093 | `dual` 特例 | 高分辨率近方形横屏，允许双排 |
| Mate X7 折叠态 | 1080×2444 | 0.442 | `scroll` | 直板窄屏纵向滚动，禁止横置进入双排 |
| MatePad Pro 13 | 2880×1920 | 1.500 | `dual` | 复用双排，限制最大内容宽度 |
| MateBook Pro | 3120×2080 | 1.500 | `dual` | 复用双排，验证窗口缩放 |
| Pura 90 | 1320×2856 | 0.462 | `scroll` | 日历和历史同页整体滚动 |

## 4. 组件 UI 调整计划

本计划只调整运行时布局表现，不改变日期记录、历史统计、导入导出和预测业务。执行顺序固定，前一项完成并通过基线检查后再进入下一项。

### 4.1 建立运行时布局参数边界

状态：已完成第一版参数边界。

- 由 `domain/ResponsiveLayout.ets` 生成当前窗口对应的 `RuntimeLayoutMetrics`。
- `ResponsivePageShell` 负责选择运行时并向日历、历史统计和操作菜单传递参数。
- 页面顶部/底部间距、日历与历史的外部间距、标题字号、日历网格间距、操作菜单尺寸和边缘偏移均归入运行时参数域。
- 基础组件只消费参数，不自行决定与其他基础组件之间的页面级间距。
- 第一版参数保留现有视觉基线，避免建立参数边界时引入额外视觉变化。

### 4.2 统一标题顶部间距

状态：已完成。

以 Pura X single（`1320×2120`）的视觉基线计算顶部留白比例：原设计的 `25% × 1320 = 330` 转换为完整窗口高度比例。窗口尺寸和安全区来自像素单位，传入 ArkUI padding 前必须除以当前屏幕 `densityPixels` 转换为 vp；顶部 padding 使用“目标视觉留白减去安全区顶部”的内容区值。single/dual 保留日历固有高度后的底部余量，并设置最低底部留白，避免短窗口压缩到底部或无底部缓冲。compact 保留紧凑顶部策略，scroll 使用同一 Pura X 顶部比例但只保留最低底部留白，以免把日历和历史之间的滚动内容强行撑满。

### 4.3 根据组件宽度缩放标题字号

状态：已完成。

标题字号依据日历实际可用宽度计算，设置 `48–68vp` 的范围，并同步保留副标题的响应式基线；已验证 `dual` 半屏宽度和 `scroll` 窄屏宽度。

### 4.4 修复年月按钮文字压缩

状态：已完成。

年月按钮根据日历区域宽度计算最小可用宽度，按钮填满浮窗网格单元并收紧列间距，保持文字单行完整显示。窗口宽度小于 `1200px` 时，年份显示为 `26年` 形式；已验证 `compact` 与窄列布局。

### 4.5 调整日历内部网格间距

状态：已完成。

日期网格行间距仅在完整窗口高度小于 `1000px` 且运行时为 `compact` 时压缩为 `3vp`；当前值由 `RuntimeLayoutMetrics.calendarGridRowGapVp` 提供，其他运行时保持 `15vp`。scroll 的四个微调入口集中在 `ResponsiveLayout.ets` 的 `mode === 'scroll' ?` 分支及其数值常量：顶部留白使用 `SCROLL_CALENDAR_TOP_INSET_RATIO`，标题左侧留白使用 `SCROLL_CALENDAR_HORIZONTAL_PADDING_VP`，标题与年月选择器的内部顶部留白使用 `SCROLL_CALENDAR_INNER_TOP_INSET_RATIO`，网格行距使用 `SCROLL_CALENDAR_GRID_ROW_GAP_VP`。只需修改这些数值，不要改动组件内部间距。

为避免窄窗口下日期标记圆形被网格列裁切，compact/scroll 使用 `calendarContentWidthRatio = 1`；compact 使用 `calendarGridWidthRatio = 1`，scroll、single、dual 保持 `0.92` 的网格宽度，single/dual 继续保持原有 `0.85` 内容宽度。

### 4.6 修复 scroll 下日历与历史统计的间距

状态：已完成。

scroll 下移除 `CalendarComponent` 底部和 `HistoryComponent` 顶部重复承担的页面级留白，由 `ResponsivePageShell` 的纵向容器通过 `scrollCalendarHistoryGapVp` 统一控制 section gap；当前 scroll 值为 `56vp`。历史组件底部额外留白由 `scrollHistoryBottomInsetVp` 独立控制，当前为 `64vp`，不影响 single、dual、compact。scroll 日历网格高度按 `5 × 40vp + 4 × SCROLL_CALENDAR_GRID_ROW_GAP_VP` 动态计算，当前行距 `3vp` 时为 `212vp`；将行距改回 `15vp` 时高度自动恢复为 `260vp`。single、dual、compact 保持原有日历高度与间距。

### 4.7 统一 ActionMenu 定位与尺寸

状态：已完成。

将折叠尺寸、展开尺寸和右下边缘偏移作为独立运行时参数，定位相对于窗口右边缘和下边缘计算，不再依赖固定的内部 `x/y` 偏移。所有运行时统一使用百分比参数 `actionMenuRightInsetRatio` 和 `actionMenuBottomInsetRatio` 控制边缘留白，当前分别为 `3%` 和 `3%`。

### 4.8 增加空白区域关闭 ActionMenu

状态：已完成。

该问题仅存在于 scroll。scroll 的外层纵向 `Scroll` 负责接收空白区域点击并关闭菜单；ActionMenu 仍作为页面顶层固定层保持可点击。single、dual 的现有关闭行为保持不变，不增加跨运行时的点击拦截。

### 4.9 为 compact 增加简略历史统计页

状态：已完成。

将 compact 改为与 `single` 类似的纵向分页，增加简略历史统计页。该页只渲染日期、跨年小标识、水平柱体、持续时长和短柱偏移；`HistoryComponent` 通过 `compactHistory` 分支复用既有排序、年份标识、动态 scale 和柱体偏移逻辑，不显示标题、预测、导入按钮和 ActionMenu。首条历史记录仅在属于当前年份时省略年份标识；柱体长度低于总长度 `5%` 时使用 `historyShortBarOffsetVp` 偏移。历史列表在组件内部独立纵向滚动，外层 `Swiper` 不被历史数量撑高。

### 4.10 回归验收顺序

每次只验证当前修改项及其交叉影响，至少覆盖：

| 运行时 | 重点检查 |
| --- | --- |
| `compact` | 年月按钮、日历行距、上下留白、简略历史页 |
| `single` | 标题顶部间距、标题字号、纵向分页 |
| `dual` | 半屏标题字号、顶部间距、历史区独立滚动 |
| `scroll` | 标题顶部间距、日历与历史间距、固定操作菜单、空白关闭 |

基线尺寸继续使用 `980×980`、`1320×2856`、`2880×1920`、`1920×2880` 和 `2210×2416`。

## 5. 各模式的组件组合

### `compact`

```text
ResponsivePageShell
└── Swiper(vertical)
    ├── CalendarComponent(compact: true)
    └── HistoryComponent(compactHistory: true)
```

日历页隐藏标题和品牌，仅保留年月控件、日期网格和日期操作；下滑进入简略历史统计页，页内只显示历史水平柱状图及其日期、跨年小标识、持续时长和短柱偏移。

### `single`

```text
ResponsivePageShell
└── Swiper(vertical)
    ├── CalendarComponent
    └── HistoryComponent
```

保留现有两页纵向切换。页面状态只保留一份，切换页面不能重新加载数据。

### `dual`

```text
ResponsivePageShell
└── Row
    ├── CalendarComponent
    └── HistoryComponent
```

取消外层 `Swiper`。右侧历史统计拥有独立滚动区域，左侧日历继续处理月份横向拖动。

### `scroll`

```text
ResponsivePageShell
└── Scroll(vertical)
    └── Column
        ├── CalendarComponent
        └── HistoryComponent(embeddedInScroll: true)
```

外层滚动容器占满窗口高度。历史组件在该模式下不再创建内部滚动容器，避免嵌套滚动；日历和历史按纵向内容顺序连续展示，二者之间的距离由 `scrollCalendarHistoryGapVp` 控制。

## 6. 组件调整影响范围

| 调整目标 | 修改位置 | 会影响 | 不应影响 |
| --- | --- | --- | --- |
| 模式阈值、旋转保护、Mate X7 大窗口特例 | `domain/ResponsiveLayout.ets`、`pages/Index.ets` | 页面组合、窗口方向和页面级手势 | 日期业务、导入解析、历史统计算法 |
| 日历整体位置、标题、年月按钮 | `CalendarComponent.ets` | 所有包含日历的模式 | 历史数据和弹窗流程 |
| 双排列宽与历史滚动边界 | `ResponsivePageShell.ets`、`HistoryComponent.ets` | `dual` 和 `scroll` 的容器行为 | `single` 的日期逻辑 |
| 柱状图、预测、操作菜单 | `HistoryComponent.ets`、`ActionMenuComponent.ets` | 所有显示历史的模式 | 日历换月逻辑 |
| 欢迎、导入、关于等窗口 | `Index.ets` 与对应窗口组件 | 所有模式的覆盖层 | 主页面布局判断 |

## 7. 验收矩阵

每个基线画布至少检查：

1. 模式是否正确，且没有错误进入 `dual` 或 `compact`。
2. 旋转后是否遵守 `scroll` 屏幕的横置限制。
3. 日历日期、月份、历史记录和导入状态是否保持。
4. `dual` 右侧是否独立滚动，`scroll` 是否只有一个整体滚动容器。
5. 宽屏是否保持最大内容宽度，窄屏是否没有横向溢出。
6. 年月浮窗、月份拖动、日期点击和操作菜单是否没有手势冲突。

## 8. 当前实现状态

- 四种基础模式已经接入 `ResponsivePageShell`，分类纯逻辑集中在 `domain/ResponsiveLayout.ets`，边界测试集中在 `entry/src/test/ResponsiveLayout.test.ets`。
- `entry/src/main/module.json5` 已声明 `phone`、`tablet`、`2in1`，允许平板和电脑模拟器构建、安装和运行。
- `Index.ets` 在 `windowSizeChange` 与 `windowRectChange` 中更新完整窗口尺寸；除 `scroll` 外使用自动旋转，`scroll` 使用竖屏方向策略。
- `RuntimeLayoutMetrics` 已建立并由 `ResponsivePageShell` 传递给基础组件；顶部留白已按 Pura X single 基线和系统安全区计算，后续视觉调整按第 4 节逐项推进。
- `Index.ets` 通过 `getWindowAvoidArea(TYPE_SYSTEM)` 和 `avoidAreaChange` 获取安全区，模式分类仍使用完整窗口矩形，安全区只参与内容内的视觉避让。
- `Index.ets` 通过窗口关联的 `displayId` 获取 `densityPixels`，所有基于分辨率的视觉留白先从 px 转换为 vp，避免高密度设备上的 padding 被放大。
- DevEco 模拟器已验证：MatePad Pro 13 的 `dual 2880×1920 ↔ single 1920×2880`，Pura 90 旋转后保持 `scroll 1320×2856`。
- 当前待处理内容为第 4.9 项，以及完整九设备基线的截图、滚动和状态保持验收；组件变形与压缩按当前任务范围暂不处理。

## 9. 参考资料

- [屏幕类型布局场景：断点与多设备界面](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-multi-device-screen-layout)
- [如何获取窗口的宽高信息](https://developer.huawei.com/consumer/cn/doc/harmonyos-faqs/faqs-arkui-190)
- [ArkTS 状态管理与组件数据传递](https://developer.huawei.com/consumer/cn/blog/topic/03179252953834009)
- [FoldSplitContainer 参考](https://developer.huawei.com/consumer/en/doc/harmonyos-references/ohos-arkui-advanced-foldsplitcontainer)
