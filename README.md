# 月迹（hercula）

月迹是一个纯 HarmonyOS 原生、离线优先的月经周期记录应用。

## 当前开发状态

当前第一版已建立 ArkTS Stage 工程骨架，包含：

- 本地每日记录和撤销确认；
- 月历网格与当前日期状态；
- Preferences 本地持久化；
- 无边框水平历史柱状图；
- 基于历史记录的透明估算文案；
- 版本化 JSON 导入、预览确认、合并去重和系统文件导出。

规则文本解析、端侧 AI 解析、签名和发布资料仍按 [实施方案](./docs/implementation-plan.md) 分阶段接入。

## 开发环境

使用当前稳定版 [DevEco Studio](https://developer.huawei.com/consumer/cn/deveco-studio/) 打开项目，并安装对应 HarmonyOS SDK。工程中的 SDK/API 版本应以本机 DevEco 的稳定版本为准。

当前 macOS 工具链已完成命令行构建验证：DevEco Studio 6.1.1、内置 HarmonyOS 6.1.1 API 24、Hvigor 6.24.4、ohpm 6.1.2 和 JDK 17.0.20。工程使用 DevEco 自带 SDK，而不是只包含系统镜像的外部 SDK 目录。

```bash
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
export DEVECO_SDK_HOME="/Applications/DevEco-Studio.app/Contents/sdk"
export PATH="/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin:/Applications/DevEco-Studio.app/Contents/tools/ohpm/bin:$JAVA_HOME/bin:$PATH"
/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw assembleApp --no-daemon
```

当前命令可生成 `build/outputs/default/hercula-default-unsigned.app` 和 `entry/build/default/outputs/default/entry-default-unsigned.hap`。项目尚未配置签名，且最近一次验证没有连接模拟器或真机；安装运行前需在 DevEco 中配置自动签名并启动设备。

## 文档

从 [docs/README.md](./docs/README.md) 开始阅读产品、技术、研究和实施文档。
