# 月迹 · hercula

一个纯 HarmonyOS 原生、离线优先的经期记录应用。

月迹只做三件事：记录经期开始日、从历史记录计算周期时长、给出透明的下一次经期估算。所有核心数据默认留在设备本地，不需要账号，不依赖云同步。

## 产品展示

当前已完成的界面 1 设计基准是 Pura X 宽折叠展开态：自绘月历、低饱和粉色渐变、圆角年份/月按钮、日期圆形标记，以及年月浮动选择窗。

![月迹界面 1 设计基准](./docs/assrt/阔折叠参考_1.png)

历史页采用无边框水平柱状图。日期位于左侧，柱体长度表示周期时长，时长文本放在柱体末端；跨年时年份标识穿插在日期行之间的空隙，不额外占用列表行高。

## 当前状态

| 能力 | 状态 |
| --- | --- |
| ArkTS + ArkUI 原生工程 | 已完成 |
| 本地日期记录、二次点击取消 | 已完成 |
| 未来日期禁止记录 | 已完成 |
| 自绘月历、横向换月、年月跳转 | 已完成 |
| 首次欢迎弹窗 | 已完成 |
| 基于下一条记录起点计算周期时长 | 已完成 |
| 无限历史列表、按日期倒序 | 已完成 |
| JSON v1 导入/导出 | 已完成，规格见 [JSON Schema](./docs/hercula-json-schema_SPEC.md) |
| 文本语义导入 | 未实现 |
| 图片 OCR 导入 | 未实现 |
| 小艺 AI 接入 | 调研中，暂不作为应用依赖 |
| 多设备 UI 适配 | 待推进，当前已验证 Pura X 宽折叠展开态 |
| Index.ets 多组件拆分 | 待多设备布局方案确定后推进 |
| Buy Me a Coffee 卡片 | 待确定入口与收款地址 |

## 设计原则

- 纯鸿蒙原生：ArkTS、ArkUI、Stage 模型、原生系统文件选择能力。
- 本地隐私：不声明网络权限，不接入分析、推送、云同步或远程大模型。
- 低认知负担：日历是主界面，点击日期即可记录，再次点击立即取消。
- 可解释统计：每个柱体都能追溯到日期记录，不把估算包装成医学结论。
- 渐进式建设：先完成 JSON 恢复闭环，再考虑文本语义和图片 OCR。

## 技术结构

```text
entry/src/main/ets/
├── entryability/     # UIAbility 生命周期
├── pages/            # 当前入口页面，暂时组装两页 UI
├── domain/           # 日期、周期时长和预测逻辑
├── data/             # Preferences 与 JSON 文件传输
├── components/       # TODO：多设备布局确定后拆分
└── parser/           # TODO：文本/OCR 候选解析
```

当前工程仍以 `Index.ets` 为主要页面文件；组件拆分会以多设备布局的稳定边界为前提，避免先拆出无法复用的屏幕专用组件。

## 开发环境与构建

使用当前稳定版 [DevEco Studio](https://developer.huawei.com/consumer/cn/deveco-studio/) 打开项目，并安装匹配的 HarmonyOS SDK。

当前已验证环境：DevEco Studio 6.1.1、内置 HarmonyOS SDK 6.1.1/API 24、Hvigor 6.24.4、ohpm 6.1.2 和 JDK 17.0.20。工程使用 DevEco 自带 SDK，而不是只包含 system-image 的用户 SDK 目录。

```bash
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
export DEVECO_SDK_HOME="/Applications/DevEco-Studio.app/Contents/sdk"
export PATH="/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin:/Applications/DevEco-Studio.app/Contents/tools/ohpm/bin:$JAVA_HOME/bin:$PATH"
/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw assembleApp --no-daemon
```

当前可生成未签名 APP/HAP。发布前仍需配置签名、隐私政策和 AppGallery Connect 资料。

## 导入路线

1. **阶段 1：JSON 导入** — 当前实现。读取 `schemaVersion: 1` 文件，完成基础版本检查、预览并合并日期；严格字段校验仍待补齐。
2. **阶段 2：文本语义导入** — 先使用确定性日期规则解析；Natural Language Kit 是否能作为离线增强能力，需要按当前 SDK 和目标设备验证。
3. **阶段 3：拍照/OCR 导入** — 图片先由 Core Vision Kit/OCR 转成文本，再复用阶段 2 的候选解析和确认流程。

小艺开放平台的 Agent/Skill 能力属于智能体开发与系统入口分发路线，不等同于应用内离线文本解析 API。相关结论记录在 [小艺 AI 调研](./docs/research/xiaoyi-ai-import-research.md)。

## 文档

从 [docs/README.md](./docs/README.md) 开始阅读：

- [产品与交互设计](./docs/product-design.md)
- [技术设计](./docs/technical-design.md)
- [实施方案与进度](./docs/implementation-plan.md)
- [JSON Schema 规格](./docs/hercula-json-schema_SPEC.md)
- [UI 动效探索](./docs/ui-motion-exploration.md)
- [小艺 AI 与 OCR 调研](./docs/research/xiaoyi-ai-import-research.md)
- [研究资料入口](./docs/research/README.md)

## 支持项目

Buy Me a Coffee 卡片暂不放入应用界面。需要确定收款平台、公开链接和展示位置后，再加入 README 或后续设置页；在此之前不放置虚构链接。
