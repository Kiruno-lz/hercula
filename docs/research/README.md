# 调研资料

调研基线：2026-08-14。以下以华为官方开发者文档、官方样例仓库和 AppGallery Connect 资料为主；外部博客不作为 API 或发布规则依据。

- [ArkTS 与 ArkUI 工具链](./arkts-toolchain.md)
- [参考文档与参考仓库](./references.md)
- [AppGallery Connect 与上架](./appgallery-release.md)
- [响应式布局规范](./responsive-layout.md)

已完成或暂不考虑的调研材料统一放在 [`docs/_archive/`](../_archive/) 中。

## 结论摘要

推荐技术栈为 DevEco Studio + ArkTS + ArkUI + Stage/UIAbility + Hvigor。当前首版只使用系统 UI、Preferences、文件 Picker、JSON 标准能力和基础布局自绘图表，不使用网络、第三方图表库、WebView 或云端 AI。JSON schema 是唯一数据契约；简单文本日期只作为确定性输入形式，复杂文本语义、OCR 和小艺 AI 暂时搁置。多设备布局优先使用 DevEco 模拟器验证，真机仅作发布前补充。

版本号不在这里硬编码：HarmonyOS、DevEco Studio 和 SDK 更新频繁，创建工程时应从官方稳定下载页选择兼容组合，并把实际版本写入工程 README/构建记录。
