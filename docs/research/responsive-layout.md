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

## 4. 各模式的组件组合

### `compact`

```text
ResponsivePageShell
└── CalendarComponent(compact: true)
```

不加载 `HistoryComponent`，日历隐藏标题和品牌，仅保留年月控件、日期网格和日期操作。

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

外层滚动容器占满窗口高度。历史组件在该模式下不再创建内部滚动容器，避免嵌套滚动；日历和历史按纵向内容顺序连续展示。

## 5. 组件调整影响范围

| 调整目标 | 修改位置 | 会影响 | 不应影响 |
| --- | --- | --- | --- |
| 模式阈值、旋转保护、Mate X7 大窗口特例 | `domain/ResponsiveLayout.ets`、`pages/Index.ets` | 页面组合、窗口方向和页面级手势 | 日期业务、导入解析、历史统计算法 |
| 日历整体位置、标题、年月按钮 | `CalendarComponent.ets` | 所有包含日历的模式 | 历史数据和弹窗流程 |
| 双排列宽与历史滚动边界 | `ResponsivePageShell.ets`、`HistoryComponent.ets` | `dual` 和 `scroll` 的容器行为 | `single` 的日期逻辑 |
| 柱状图、预测、操作菜单 | `HistoryComponent.ets`、`ActionMenuComponent.ets` | 所有显示历史的模式 | 日历换月逻辑 |
| 欢迎、导入、关于等窗口 | `Index.ets` 与对应窗口组件 | 所有模式的覆盖层 | 主页面布局判断 |

## 6. 验收矩阵

每个基线画布至少检查：

1. 模式是否正确，且没有错误进入 `dual` 或 `compact`。
2. 旋转后是否遵守 `scroll` 屏幕的横置限制。
3. 日历日期、月份、历史记录和导入状态是否保持。
4. `dual` 右侧是否独立滚动，`scroll` 是否只有一个整体滚动容器。
5. 宽屏是否保持最大内容宽度，窄屏是否没有横向溢出。
6. 年月浮窗、月份拖动、日期点击和操作菜单是否没有手势冲突。

## 7. 当前实现状态

- 四种基础模式已经接入 `ResponsivePageShell`，分类纯逻辑集中在 `domain/ResponsiveLayout.ets`，边界测试集中在 `entry/src/test/ResponsiveLayout.test.ets`。
- `entry/src/main/module.json5` 已声明 `phone`、`tablet`、`2in1`，允许平板和电脑模拟器构建、安装和运行。
- `Index.ets` 在 `windowSizeChange` 与 `windowRectChange` 中更新完整窗口尺寸；除 `scroll` 外使用自动旋转，`scroll` 使用竖屏方向策略。
- DevEco 模拟器已验证：MatePad Pro 13 的 `dual 2880×1920 ↔ single 1920×2880`，Pura 90 旋转后保持 `scroll 1320×2856`。
- 当前仅剩完整九设备基线的截图、滚动和状态保持验收；组件变形与压缩按当前任务范围暂不处理。

## 8. 参考资料

- [屏幕类型布局场景：断点与多设备界面](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-multi-device-screen-layout)
- [如何获取窗口的宽高信息](https://developer.huawei.com/consumer/cn/doc/harmonyos-faqs/faqs-arkui-190)
- [ArkTS 状态管理与组件数据传递](https://developer.huawei.com/consumer/cn/blog/topic/03179252953834009)
- [FoldSplitContainer 参考](https://developer.huawei.com/consumer/en/doc/harmonyos-references/ohos-arkui-advanced-foldsplitcontainer)
