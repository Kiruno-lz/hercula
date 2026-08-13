# 月迹（hercula）

月迹是一个纯 HarmonyOS 原生、离线优先的月经周期记录应用。

## 当前开发状态

当前第一版已建立 ArkTS Stage 工程骨架，包含：

- 本地每日记录和撤销确认；
- 月历网格与当前日期状态；
- Preferences 本地持久化；
- 无边框水平历史柱状图；
- 基于历史记录的透明估算文案。

导入、导出、文本解析和发布资料仍按 [实施方案](./docs/implementation-plan.md) 分阶段接入。

## 开发环境

使用当前稳定版 [DevEco Studio](https://developer.huawei.com/consumer/cn/deveco-studio/) 打开项目，并安装对应 HarmonyOS SDK。工程中的 SDK/API 版本应以本机 DevEco 的稳定版本为准。

本仓库当前开发环境没有 DevEco Studio、HarmonyOS SDK 和 Java Runtime，因此本地命令行构建尚未执行；首次打开工程后需要在 DevEco 中同步依赖并完成 API/设备验证。

## 文档

从 [docs/README.md](./docs/README.md) 开始阅读产品、技术、研究和实施文档。
