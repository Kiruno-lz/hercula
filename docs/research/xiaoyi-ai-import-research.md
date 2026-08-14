# 小艺 AI、文本语义与图片识别调研

调研日期：2026-08-14。本文区分“小艺开放平台”与 HarmonyOS SDK 内可集成的 AI Kit，不把平台宣传中的系统级智能入口直接等同为应用内离线 API。

## 探索原因

月迹计划支持三阶段历史导入：JSON 文件、文本语义转严格 JSON、拍照识别文字后再转严格 JSON。后两阶段涉及经期日期这一类敏感健康数据，必须先确认能力来源、离线边界、可用设备、权限和上架限制，才能决定是否进入原生应用。

## 探索目标

确认以下问题：

1. 是否存在可在 ArkTS 应用内直接调用的小艺本地大模型解析接口。
2. 是否有官方文本实体抽取能力可识别日期。
3. 是否有官方端侧 OCR 能力可从照片或截图获得文本。
4. 这些能力是否与当前 HarmonyOS 6.1.1/API 24、纯本地隐私和无网络目标兼容。

## 探索结果

### 1. 小艺开放平台不是当前应用的直接本地解析依赖

官方小艺开放平台定位是 Agent/Skill 的创建、调试、审核、上架和系统入口分发平台，资料描述了大模型、鸿蒙端云插件和多模态入口。它适合构建一个被小艺触达的智能体或服务，不等同于“把一段文本交给设备内置小艺模型并同步返回严格 JSON”的通用 ArkTS API。

结论：当前不把小艺开放平台写入 hercula 的构建依赖，也不把它作为离线隐私方案的默认实现。

### 2. Natural Language Kit 是文本阶段的候选能力

官方 Natural Language Kit 页面列出分词和实体抽取能力，实体类型包含时间日期等，场景中也提到短信实体识别和自动填充。这与阶段 2 的“文本候选日期提取”方向匹配。

但公开能力页没有在本次调研中确认：当前 API 24 SDK 的准确 ArkTS 导入路径、具体日期实体返回结构、是否完全端侧执行、支持设备范围、模型资源体积和断网行为。

结论：它是阶段 2 的候选增强，不是当前可直接落地的依赖。必须先用当前 SDK API Reference、示例和断网设备测试确认。

### 3. Core Vision Kit/OCR 是图片阶段的候选能力

官方 Core Vision Kit 和 OCR 资料明确提供通用文字识别，可从收据、名片、文档照片等图片中提取文本；OCR 资料还描述了拍照 OCR 和手机截屏 OCR 场景。

这能覆盖阶段 3 的“拍照/截图 → 文本”，但 OCR 只负责文字提取，不负责判断哪些日期是经期开始日。后续仍必须复用确定性日期解析、候选预览和用户确认。

结论：图片阶段应拆成“选择/拍照 → OCR → 文本候选解析 → 严格 JSON 预览 → 用户确认”，不得把 OCR 结果直接写入记录。

### 4. AI Subsystem、Agent Framework 与当前 API 版本存在版本风险

官方 AI 能力总览列出 AI Subsystem、Agent Framework Kit、Core Vision Kit、Natural Language Kit 等方向，并注明 HarmonyOS 7/API 26 提供更丰富的视觉和语言 AI 能力。当前工程目标是 HarmonyOS 6.1.1/API 24，因此不能根据总览页面推断 API 24 已具备相同能力。

## 分阶段落地结论

| 阶段 | 当前方案 | 状态 | 阻塞条件 |
| --- | --- | --- | --- |
| 1. JSON | 按 v1 schema 读取，预览后合并 | 当前实现 | 完成严格字段校验和测试 |
| 2. 文本语义 | 规则解析为主，Natural Language Kit 作为可选增强 | 文档已确定 | API 24 可用性、离线性、返回结构和隐私验证 |
| 3. 图片识别 | OCR 提取文本，再复用阶段 2 | 文档已确定 | 图片选择/相机入口、Core Vision Kit 版本、端侧执行和性能验证 |

## 复现与验证说明

当前只完成官方资料检索，没有新增代码、没有申请权限、没有上传任何数据，也没有把 AI Kit 加入工程。下一次技术验证应在独立实验分支完成：

1. 用当前 DevEco Studio 和 API 24 SDK 搜索 Natural Language Kit、Core Vision Kit 的 ArkTS 声明与示例。
2. 构建最小文本实体抽取和 OCR 样例，记录实际 Kit 导入路径与 API 版本。
3. 断开网络，在 Pura X 模拟器和至少一台真实设备运行。
4. 记录首包体积、首次初始化耗时、内存峰值、识别语言、失败行为和原始数据是否离开设备。
5. 只有通过全部检查，才将能力接入导入流程；否则继续使用规则解析并明确提示无法识别。

## 注意事项与补充

- “小艺能理解”不能作为本地隐私或离线执行的证明。
- Agent/Skill 的系统入口分发会带来平台账号、审核、发布和可能的端云依赖，不应混入首版核心数据链路。
- 任何模型输出都必须先转成 `hercula-json-schema_SPEC.md` 定义的严格候选结构，经过用户确认后才能写入。
- 月经日期属于敏感健康信息，调研样例不得使用真实个人记录；应使用合成日期和脱敏文本。

## 官方资料

- [HarmonyOS AI 开放能力与服务一览](https://developer.huawei.com/consumer/cn/harmonyos-ai)
- [小艺开放平台](https://developer.huawei.com/consumer/cn/celia/)
- [Natural Language Kit](https://developer.huawei.com/consumer/cn/sdk/natural-language-kit/)
- [Core Vision Kit](https://developer.huawei.com/consumer/cn/sdk/core-vision-kit)
- [通用文字识别（OCR）](https://developer.huawei.com/consumer/cn/hiai/engine/screenshot-ocr/)
- [HarmonyOS AI 能力总览与 API 入口](https://developer.huawei.com/consumer/cn/doc/?catalogVersion=V2)
