# 调研资料

调研基线：2026-08-14。以下以华为官方开发者文档、官方样例仓库和 AppGallery Connect 资料为主；外部博客不作为 API 或发布规则依据。

- [ArkTS 与 ArkUI 工具链](./arkts-toolchain.md)
- [组件、存储、文件与导入导出](./arkts-components.md)
- [参考文档与参考仓库](./references.md)
- [AppGallery Connect 与上架](./appgallery-release.md)

## 结论摘要

推荐技术栈为 DevEco Studio + ArkTS + ArkUI + Stage/UIAbility + Hvigor。首版只使用系统 UI、Preferences、文件 Picker、JSON 标准能力和基础布局自绘图表，不使用网络、第三方图表库、WebView 或云端 AI。

版本号不在这里硬编码：HarmonyOS、DevEco Studio 和 SDK 更新频繁，创建工程时应从官方稳定下载页选择兼容组合，并把实际版本写入工程 README/构建记录。
