# 第三步：CalendarComponent 日历组件解析

解析对象：entry/src/main/ets/components/CalendarComponent.ets。

## 1. 组件为什么存在

CalendarComponent 不是一个通用日期选择器，而是月迹主界面的“记录入口 + 月份浏览器”：

    用户手势/点击
        -> CalendarComponent
            -> 生成当前显示月份
            -> 展示已记录日期
            -> 屏蔽未来日期
            -> 通过 onToggleDate 把日期动作交回 Index

它被单独构建出来，是因为产品需要一个系统 Calendar 模板难以直接满足的界面：

- 自绘日期圆形标记；
- 横向拖动切换月份；
- 年/月浮动跳转面板；
- compact、single、dual、scroll 共享同一套日历内容；
- 日期点击只产生业务事件，不在日历组件内部写入数据。

因此它的角色是“有局部交互状态的受控展示组件”，不是数据仓库，也不是统计服务。

## 2. 与上下游的关系

### 上游：ResponsivePageShell

页面壳传入：

| 输入 | 作用 |
| --- | --- |
| markedDays | 决定哪些日期显示经期标记 |
| compact | compact 模式隐藏月迹/hercula 标题 |
| scrollLayout | scroll 模式让组件高度变为 auto |
| layoutMetrics | 提供尺寸、留白、字号和网格参数 |
| onToggleDate | 将日期点击交回 Index |

CalendarComponent 不知道自己处于哪一种设备，也不读取窗口 API；设备差异已经由 layoutMetrics 转换完成。

### 下游：Index

日期点击的唯一输出是 onToggleDate(date)。Index 再负责：

1. 判断日期是否为未来；
2. 判断是否已经存在；
3. 新增或删除 MenstrualDay；
4. 递增 dataRevision；
5. 保存 Preferences。

这形成双层保护：CalendarComponent 在 UI 事件中屏蔽未来日期，Index 在业务入口再次屏蔽。

### 同级：HistoryComponent

两者都从 ResponsivePageShell 接收同一份 markedDays，但互不直接通信：

    Index.markedDays
        ├─> CalendarComponent：显示日期事实
        └─> HistoryComponent：派生统计结果

日历切换月份不会触发历史统计；只有日期事实经 Index 改变后，页面壳才把更新后的数据和 dataRevision 传下去。

## 3. 局部状态的职责

| 状态 | 作用 | 是否属于业务事实 |
| --- | --- | --- |
| calendarDate | 当前显示的月份，默认为设备当前月份 | 否 |
| calendarRenderVersion | 在 A/B 两套网格轨道之间切换，强制重新构建网格 | 否 |
| calendarDragOffset | 当前横向拖动距离 | 否 |
| calendarViewportWidth | 记录月历轮播区域宽度，用于计算拖动位移 | 否 |
| calendarAnimationDuration | 控制拖动完成和回弹动画时长 | 否 |
| calendarSwipeSettling | 防止动画未完成时再次处理手势 | 否 |
| jumpMode | 当前是否打开 year 或 month 跳转面板 | 否 |

最重要的边界是 calendarDate：它只代表“用户正在浏览哪个月”，不代表用户修改了哪一天。它不会进入 Preferences，也不会传给 HistoryComponent。

## 4. 月份切换机制

组件没有使用系统 Calendar，也没有使用真正的横向 Swiper，而是自绘三个月份卡片：

    Stack
      ├─ 前一个月 offset=-1
      ├─ 当前月份 offset=0
      └─ 后一个月 offset=1

每张卡片的横向位置为：

    offset * calendarViewportWidth + calendarDragOffset

手势流程：

1. onActionUpdate 持续更新 calendarDragOffset，并把拖动限制在一个视口宽度内。
2. onActionEnd 使用 max(40, viewportWidth * 0.2) 作为切换阈值。
3. 超过阈值时，先把卡片动画到下一月位置。
4. 约 190ms 后调用 moveMonth(offset)，清空拖动状态并恢复可交互。
5. 未超过阈值时，执行约 160ms 的回弹动画。

calendarRenderVersion 的奇偶值决定使用 Track A 还是 Track B。A/B 两套 builder 的结构基本相同，作用不是两种视觉，而是让日期网格获得新的构建身份，避免月份变化后 ArkUI/ForEach 复用旧网格。

## 5. 年月跳转

年月按钮只改变局部导航状态：

    点击年份按钮 -> jumpMode = year
    点击月份按钮 -> jumpMode = month
    再次点击相同按钮 -> jumpMode = ''

年份面板提供当前年份前 5 年到后 6 年，共 12 个候选；月份面板提供 1 到 12 月。选择后：

- selectYear 保留当前月份，只替换年份；
- selectMonth 保留当前年份，只替换月份；
- 关闭跳转面板；
- 递增 calendarRenderVersion。

这条路径同样不触碰 markedDays，不触发保存和历史刷新。

## 6. 日历网格的当前实现

当前组件通过 calendarDayNumbersForOffset 生成 1 到当月最后一天的数字，再用 7 列 Grid 展示：

    当前月份
      -> monthDayCount
          -> [1, 2, 3, ..., 28/29/30/31]
              -> 7 列 Grid

月份天数由组件内部的 monthDayCount 和 isLeapYear 计算，不调用 DateUtils 的日历网格函数。

每个日期格的处理顺序是：

1. 用 calendarDayKey 生成 YYYY-MM-DD；
2. 用 markedDays.some 判断是否已记录；
3. 已记录显示 PERIOD_COLOR 和白色文字；
4. 未记录显示透明背景和正文颜色；
5. 点击时判断是否未来；
6. 非未来才调用 onToggleDate。

## 7. 日历网格的关键边界

当前 Grid 只有 7 列，但 calendarDayNumbersForOffset 没有加入月份第一天之前的空白格，也没有使用星期偏移。因此从代码事实看，每个月的 1 日都会从 Grid 的第一个位置开始，不会按真实星期对齐。

当前仓库只有 CalendarComponent 的连续日期网格实现；日历格生成责任已收敛在组件内部，MenstrualData 不再保留未接入的第二套网格模型。

## 8. 布局参数在组件中的角色

CalendarComponent 不自行决定尺寸，而是消费 RuntimeLayoutMetrics：

- calendarTopInsetVp / calendarBottomInsetVp：整个日历内容的上下位置；
- calendarContentWidthRatio：标题和主体内容宽度；
- calendarGridWidthRatio：网格宽度；
- calendarTitleFontSizeVp：品牌标题字号；
- calendarYearButtonWidthVp / calendarMonthButtonWidthVp：年月按钮尺寸；
- calendarGridHeightVp、calendarGridRowGapVp、calendarDateSizeVp：网格和触控区域；
- calendarInnerTopInsetRatio、calendarMonthCardTopInsetRatio：网格内部留白和卡片偏移。

compact 只影响标题是否渲染；scrollLayout 只影响外层高度是否为 auto。模式判定仍属于 ResponsivePageShell/ResponsiveLayout。

## 9. 边界问题记录

只记录代码已经明确存在、并会影响整理边界的问题：

1. CalendarComponent 自己实现 monthDayCount 和 isLeapYear，月份网格计算集中在展示组件内部，不再与 domain 保留第二份生成模型。
2. Track A/Track B 的月份网格 builder 结构重复，但 calendarRenderVersion 明确依赖它们强制重建；它们是“有用途的重复代码”，不能按死代码直接清理。
3. formatYearLabel 使用 layoutMetrics.viewportWidth，而该值是完整窗口宽度；dual 模式下它与 CalendarComponent 实际可用列宽不是同一层级的数据。

## 10. 本步骤结论

CalendarComponent 的核心职责可以收敛为：

    月份浏览状态
      + 自绘三月卡片
      + 年/月跳转
      + 日期标记展示
      + 日期点击事件

它的正确边界是：可以决定“用户正在看哪个月”和“用户点击了哪个日期”，但不能决定“这个日期是否写入应用事实”。后者必须继续交给 Index。
