# ArkTS 开发环境与工程基线

## 1. 官方工具链

### DevEco Studio

DevEco Studio 是 HarmonyOS 应用的一站式 IDE，提供 ArkTS 编辑、ArkUI 预览、模拟器/真机调试、Hvigor 构建和性能分析。官方页面同时列出 macOS 与 Windows 的系统要求，安装前应按当前页面核对磁盘、内存和芯片架构要求。

官方入口：[DevEco Studio](https://developer.huawei.com/consumer/cn/deveco-studio/)

### ArkTS

ArkTS 是 HarmonyOS 应用开发的官方语言，保留 TypeScript 风格但增加静态约束。对本项目而言，重要的不是复用任意 TS 库，而是使用 ArkTS 可编译、可静态检查的类型和 ArkUI 状态管理。

官方入口：[ArkTS](https://developer.huawei.com/consumer/cn/arkts/)、[ArkTS 开发入门](https://developer.huawei.com/consumer/cn/arkts/devstart/)

### ArkUI

ArkUI 是声明式 UI 框架，负责组件、布局、状态、动画和手势。月历、分页、弹窗、Canvas 都可以留在 ArkUI 内完成，不需要引入 Web 技术。

官方入口：[HarmonyOS 设计与开发](https://developer.huawei.com/consumer/cn/app/planning)、[HarmonyOS 设计资源](https://developer.huawei.com/consumer/cn/design/)

### Hvigor 与 SDK

工程使用 DevEco Studio 创建的 Hvigor 配置完成编译和打包。API 版本、Kit 导入路径和组件属性会随 SDK 变化；实现时必须以当前 SDK 的 API Reference 和 IDE 编译结果为准，不复制旧版代码中的模块导入名。

## 2. 工程选择

创建项目时选择：

- Application，而不是 atomic service。
- ArkTS 工程模板。
- Stage 模型。
- 单个 `entry` 模块、单个 UIAbility。
- 手机为首要设备类型；保留后续窗口尺寸适配空间。

建议包名使用稳定、反向域名形式，例如 `com.hercula.app`；包名一旦发布不应随意修改。应用显示名为“月迹”，英文代号和工程标识使用 `hercula`。

## 3. 首次环境验证步骤

1. 从官方 DevEco Studio 页面安装当前稳定版，并安装对应 HarmonyOS SDK。
2. 创建空白 ArkTS Stage 工程，记录 IDE、SDK、Node/Java（若工程向导要求）和构建插件版本。
3. 在预览器中确认基础页面可渲染。
4. 在模拟器和至少一台真实设备上安装运行。
5. 打开编译器严格检查，修复 ArkTS 类型约束、弃用 API 和权限告警。
6. 在工程文档中记录 API 版本和设备型号，后续所有组件调研以此为准。

## 4. 为什么不选其他路线

- 不选 ArkUI-X：它面向跨平台部署，与“纯鸿蒙原生”目标不一致。
- 不选 WebView：会增加离线资源、渲染和隐私审查面，且本项目的日历/图表没有必须使用 Web 的能力。
- 不选 C/C++ NDK：数据规模和图形复杂度不足以抵消跨语言生命周期与构建复杂度。
- 不选第三方 UI 库：首版组件数量少，原生 ArkUI 更容易保证离线、兼容和上架审核可解释性。
