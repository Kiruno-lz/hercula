# 参考文档与参考仓库

## 1. 优先阅读的官方资料

- [HarmonyOS 开发工具与平台](https://developer.huawei.com/consumer/cn/develop/index.html)：总入口，确认 ArkTS、ArkUI、SDK 和工具链位置。
- [DevEco Studio](https://developer.huawei.com/consumer/cn/deveco-studio/)：下载、系统要求、版本说明和 IDE 能力。
- [ArkTS](https://developer.huawei.com/consumer/cn/arkts/)：语言约束、声明式 UI 和开发入口。
- [ArkTS 开发入门](https://developer.huawei.com/consumer/cn/arkts/devstart/)：语言、ArkUI、ArkData 的学习路径。
- [HarmonyOS 设计与开发](https://developer.huawei.com/consumer/cn/app/planning)：应用开发全流程入口。
- [ArkUI 资源与开发工具](https://developer.huawei.com/consumer/cn/arkui/resources/)：组件、工具、示例和设计资源入口。
- [文件处理应用](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/file-processing-apps-startup)：文件 URI、读取与系统文件处理边界。
- [AppGallery Connect 概览](https://developer.huawei.com/consumer/cn/doc/overview/AppGallery-connect)：项目、质量、发布和测试能力入口。

## 2. 可借鉴的仓库

- [OpenHarmony applications_app_samples](https://github.com/openharmony/applications_app_samples)：OpenHarmony 官方应用样例集合，适合查看 ArkTS 页面组织、Ability 和常用 API 使用方式。
- [HarmonyOS Samples 组织](https://gitee.com/harmonyos_samples)：华为/鸿蒙样例仓库集合，可按当前 API 版本筛选。
- [HarmonyOS Codelabs 新仓库](https://gitee.com/harmonyos_codelabs)：逐步实验和基础能力样例；旧的 `harmonyos/codelabs` 仓库已标注停止维护，不应作为新项目唯一依据。

## 3. 使用仓库的规则

样例仓库只用于理解工程结构和 API 调用上下文，不直接复制版本敏感的导入路径。每个样例进入 hercula 前必须：

1. 对照当前 SDK API Reference。
2. 在本地工程编译。
3. 检查是否引入网络、权限、第三方 SDK 或与纯原生目标冲突的模块。
4. 当前阶段优先用 DevEco 模拟器验证文件选择、手势和窗口行为；真机仅在模拟器无法覆盖或发布前补充。

ArkUI-X 的样例可用于理解跨平台写法，但本项目不采用 ArkUI-X 工程路线。
