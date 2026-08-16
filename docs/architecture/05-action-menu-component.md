# 第五步：ActionMenuComponent 操作菜单解析

解析对象：entry/src/main/ets/components/ActionMenuComponent.ets。

## 1. 组件为什么存在

ActionMenuComponent 是一个可复用的受控操作菜单，提供三个固定动作：

    导入日期
    导出日期
    关于软件

它被单独构建出来，是为了让 single、dual 和 scroll 三种页面场景复用相同的菜单内容、展开动画和回调顺序。

它不负责：

- 判断当前页面是否允许导入或导出；
- 打开导入窗口；
- 生成导出文件；
- 打开关于窗口；
- 决定菜单在页面中的最终位置。

## 2. 输入与输出

### 输入

| 属性 | 用途 |
| --- | --- |
| actionMenuOpen | 父组件传入的展开/收起状态 |
| layoutMetrics | 提供菜单尺寸、图标尺寸、内边距和锚点偏移 |

### 输出回调

| 回调 | 触发时机 |
| --- | --- |
| onOpenChange(true) | 点击收起状态的菜单按钮 |
| onOpenChange(false) | 点击导入、导出或关于菜单项 |
| onImport() | 点击导入日期 |
| onExport() | 点击导出日期 |
| onAbout() | 点击关于软件 |

组件没有自己的 actionMenuOpen 状态。它是受控组件，父组件必须接收 onOpenChange 并把新值重新传回。

## 3. 两个父级承载位置

### HistoryComponent 承载

single 和 dual 模式下，HistoryComponent：

1. 保存 actionMenuOpen；
2. 创建菜单外层定位容器；
3. 处理历史区域点击时的关闭；
4. 把菜单动作转发给 ResponsivePageShell。

### ResponsivePageShell 承载

scroll 模式下，ResponsivePageShell：

1. 保存 scrollActionMenuOpen；
2. 把菜单放在外层滚动区域之上；
3. 处理外层 Scroll 点击时的关闭；
4. 把菜单动作直接转发给自己的上层回调。

因此 ActionMenuComponent 只负责“菜单内部行为”，父组件负责“菜单放置和外部关闭”。

## 4. 展开与收起行为

收起状态：

- 显示图标按钮；
- 菜单内容透明、禁用并带有位移/模糊；
- 外层尺寸使用 collapsedSize；
- 图标按钮点击后请求父组件将状态改为 true。

展开状态：

- 图标按钮透明并禁用；
- 菜单内容启用并显示三个按钮；
- 外层尺寸切换为 expandedWidth 和 expandedHeight；
- 外层位置使用 expandedAnchorOffsetY；
- 菜单项依次显示导入、导出、关于。

点击菜单项时，代码先调用 onOpenChange(false)，再调用具体业务回调。这样父组件先收起菜单，再进入导入、导出或关于流程。

## 5. 动画与布局参数

组件内部定义四个动画时长：

- 外层展开：160ms；
- 外层收起：180ms；
- 菜单文字：160ms；
- 菜单文字展开延迟：120ms。

布局参数来自 RuntimeLayoutMetrics：

- actionMenuCollapsedSizeVp；
- actionMenuIconSizeVp；
- actionMenuExpandedWidthVp；
- actionMenuExpandedHeightVp；
- actionMenuItemHeightVp；
- actionMenuHorizontalPaddingVp；
- actionMenuVerticalPaddingVp；
- actionMenuCollapsedAnchorOffsetVp；
- actionMenuExpandedAnchorOffsetYVp。

组件使用这些参数决定自身尺寸和内部位置，但不决定父级容器的 margin、zIndex 或点击区域。

## 6. 通信闭环

    HistoryComponent / ResponsivePageShell
        -> actionMenuOpen
        -> ActionMenuComponent
            -> onOpenChange
            -> onImport / onExport / onAbout
                -> 父组件
                    -> Index

菜单本身没有业务依赖，只有布局依赖和回调依赖。

## 7. 当前明确的边界问题

只记录代码中已经明确存在的问题：

1. 菜单的展开状态由父组件持有，但空白区域关闭逻辑分别写在 HistoryComponent 和 ResponsivePageShell 中；ActionMenuComponent 自身不能独立完成完整的关闭行为。
2. HistoryComponent 和 ResponsivePageShell 都各自创建菜单外层定位容器，并分别设置尺寸、边距或层级；菜单内容复用，但承载布局逻辑存在两份。
3. ActionMenuComponent 同时消费菜单自身尺寸和父级定位偏移，菜单视觉尺寸与页面位置依赖同一个 RuntimeLayoutMetrics 对象，布局职责跨越组件和页面壳。
4. ActionMenuComponent 的业务项是固定三项，父组件却分别暴露三个独立回调；当前没有动作配置或动态菜单需求，因此这些回调只是固定协议，不应额外抽象成通用菜单系统。

## 8. 本步骤结论

ActionMenuComponent 的实际职责可以收敛为：

    受控展开状态
      + 固定三个菜单项
      + 展开/收起动画
      + 回调顺序保证

它不是菜单状态拥有者，也不是业务动作执行者。后续整理时，优先保留受控通信和“先关闭、后执行动作”的顺序；菜单位置和外部关闭行为应继续由父组件负责。
