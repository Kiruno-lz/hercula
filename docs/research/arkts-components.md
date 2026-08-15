# ArkTS 组件与系统能力调研

## 1. UI 组件

### 月历：自定义 Grid

推荐用 `Grid`、`GridItem` 或等价的 ArkUI 基础布局构成 7 列网格，再由领域层传入月份网格和日期状态。原因是主界面需要同时显示每个日期的状态、渐变、圆角、图例和无障碍描述；系统 `CalendarPicker` 更像日期选择能力，不能先假定它能满足完整视觉。

可在后续 API 验证中参考官方组件资料：[ArkUI 组件与 API 文档](https://developer.huawei.com/consumer/cn/arkui/)

### 整页切换：Swiper 优先

两个满屏展示页应使用纵向 `Swiper` 语义实现整页吸附。`Scroll` 的 snap 适合可滚动内容，但手势可能停在中间，只有在当前 SDK/真机验证不满足时才作为备选。分页切换必须补充当前页语义和无障碍操作。

### 柱状图：基础布局

数据量很小，优先实现为自定义 `HistoryChart`，使用 `Column` 排列记录行，每行用 `Row` 放置日期、水平柱条和末端时长：

- 不绘制边框、持续天数坐标轴、网格线或刻度。
- 柱条宽度由 `durationDays / maxDurationDays` 归一化；当前短柱体额外使用 3vp 起点偏移改善视觉贴边问题。
- 持续天数显示在柱条末端；最后一条显示“进行中/截至今天”。
- 跨年年份标识叠加在相邻日期行之间的空隙，不额外增加列表行高；不绘制虚线。
- 不把最大值设为 0；空数据使用专门空状态。
- 同时渲染文字摘要，避免柱条只对视觉用户可用。

## 2. 数据持久化

首版使用 User Preferences（当前 SDK 对应的 ArkData API）保存一个版本化 JSON 字符串：数据量小、读写模型简单、没有复杂查询需求。Preferences 不是数据库查询层，repository 要负责序列化、校验、去重、迁移和写入失败处理。具体 Kit 导入名以当前 SDK API Reference 为准。

如果未来加入症状、备注、复杂筛选或大量历史，再评估关系型数据库；不能因为“健康数据”就默认引入数据库或云同步。

官方 API 入口：[ArkData / 数据持久化与 API 参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkdata)

## 3. 文件导入导出

公共文件不能通过猜测路径或遍历存储空间直接访问。正确边界是：

- 导入：调用系统 DocumentViewPicker，取得用户选择的 URI 和临时授权，再使用 Core File Kit 读取内容。
- 导出：调用系统保存文件能力，让用户选择文件名和位置，再写入 UTF-8 JSON。
- 授权失效、文件类型不匹配、读取失败和保存失败都必须转成用户可理解的错误。

官方参考：[文件处理应用](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/file-processing-apps-startup)、[文件与用户文件概览](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-package-glossary)

当前工程以已安装 SDK 的 Kit 声明为准：导入使用 `picker.DocumentSelectOptions.fileSuffixFilters` 和 `DocumentViewPicker.select()`，导出使用 `picker.DocumentSaveOptions.fileSuffixChoices` 和 `DocumentViewPicker.save()`，内容读写使用 `fileIo.openSync/readSync/writeSync/closeSync`。选择器返回的 URI 只在用户授权生命周期内有效，不能把它当作永久路径保存。

## 4. JSON 与本地文本解析

ArkTS 标准能力足以完成 JSON 的序列化、反序列化和 schema 校验。不要把 JSON 解析当作“AI 解析”；二者是不同的可靠性等级。

解析设计：

- JSON 只接受明确 schema，并拒绝未知的关键字段组合或非法日期。
- 文本解析只提取明确日期候选，保留原文行和错误。
- 每次导入先预览，不直接覆盖。
- 合并以日期去重，旧数据保留。

当前第一版已实现 schema `1` 的 JSON 文件导入导出，导入文件限制为 JSON 且读取上限为 4 MiB；文本日期解析和粘贴入口已接入同一个导入窗口。JSON 有效日期会回填为标准行文本，之后与文本输入共同进入确认流程；OCR 入口暂时搁置。数据契约见 [`json_SPEC.md`](../json_SPEC.md)。

## 5. 端侧 AI 的边界

需求中的“鸿蒙内置或者自带小 AI”目前不能作为工程依赖写死。Natural Language Kit 和 Core Vision Kit 是文本实体抽取、OCR 的候选原生能力；小艺开放平台主要是 Agent/Skill 开发与系统入口分发。要纳入后续版本，必须先验证：官方可分发 Kit、是否真正离线、模型和权限体积、支持设备、数据是否离开设备、断网失败行为、隐私政策要求和 AppGallery 审核要求。详见 [小艺 AI 调研](./xiaoyi-ai-import-research.md)。

当前 JSON 和简单文本规则解析都已实现为本地输入方式，二者最终都转换为日期候选并经过确认。Natural Language Kit 和 OCR 暂不接入，未来重新立项时仍须经过独立验证，避免把敏感日期发送到云端。
