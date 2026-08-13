# AppGallery Connect 与上架调研

## 1. 发布前置

HarmonyOS 应用发布需要在华为开发者联盟注册开发者、完成所需身份认证，并在 AppGallery Connect 创建应用。包名、应用名称、签名和版本号从第一版开始就要稳定管理。

官方入口：[AppGallery Connect](https://developer.huawei.com/consumer/cn/doc/overview/AppGallery-connect)、[配置 AppGallery Connect](https://developer.huawei.com/consumer/cn/doc/HMSCore-Guides/harmonyos-sdk-config-agc-0000001101459188)

## 2. 签名与构建

- 开发签名只用于本地调试，发布签名必须单独管理。
- 记录证书、Profile、包名和签名指纹的归属，不把私钥提交 Git。
- 上架前决定是否使用 AppGallery Connect App Signing，并保持后续升级的签名一致性。
- 每次发布保存可复现的版本号、构建产物校验信息和变更说明。

官方参考：[App Signing 服务](https://developer.huawei.com/consumer/en/doc/AppGallery-connect-Guides/agc-appsigning-introduction-0000001051379577)、[配置签名证书指纹](https://developer.huawei.com/consumer/en/doc/connectivity-guides/screen-sharing-config-agc-0000001051143088)

## 3. 应用资料

准备以下资料：

- 应用名称：月迹。
- 应用英文代号：hercula。
- 应用图标、启动图和真实设备截图。
- 功能描述：本地记录、历史统计、JSON/文本导入导出、估算说明。
- 隐私政策 URL 或可访问的隐私政策页面。
- 权限和数据处理清单。
- 测试账号：本应用无账号，因此不应虚构账号流程。
- 已知限制：规则文本解析范围、预测不是医疗建议、应用默认不联网。

## 4. 隐私与合规重点

“不联网”不能替代隐私政策。经期记录与健康状态相关，发布前应明确：

- 收集什么：首版仅保存用户主动记录的日期。
- 保存在哪里：应用本地沙箱；导入和导出文件只在用户主动选择后读写。
- 用于什么：展示日历、统计和本地估算。
- 是否共享：不共享给服务器、广告、分析或第三方 SDK。
- 用户如何删除：提供清空本地记录的入口，并说明导出的外部文件不由应用控制。
- 备份边界：验证系统备份行为，避免“完全不出设备”的文案与系统级备份实际行为冲突。
- 导入边界：只处理用户选择的文件/文本，不后台扫描文件。

华为官方合规资料强调隐私政策、敏感个人信息处理和用户权利，应以目标发布地区的最新规则为准：[SDK 合规使用指南](https://developer.huawei.com/consumer/cn/doc/AppGallery-connect-Guides/agc-auth-web-personal-data-0000001502650472)。本项目不接入该 SDK，但其中的合规原则仍可作为发布检查参考。

## 5. 测试与提交流程

1. 本地 Debug：模拟器 + 真实设备验证核心闭环。
2. Release 构建：检查签名、包大小、权限和资源。
3. AppGallery Connect 集成检查/质量检查，修复阻断项。
4. 开放测试或内部测试：验证安装、升级、导入导出、隐私说明和异常设备行为。
5. 填写版本信息、截图、分类、隐私政策和发布区域，提交审核。
6. 审核通过后再做小范围发布或正式发布；保存最终审核资料和已发布包信息。

官方参考：[正式版本发布](https://developer.huawei.com/consumer/en/doc/development/AppGallery-connect-Guides/agcapi-release_app)、[AppGallery Connect 概览](https://developer.huawei.com/consumer/en/doc/distribution/app/agc-help-overview-0000001100246618)

## 6. 与本项目直接相关的上架检查

- [ ] 未声明网络权限，且依赖清单无联网 SDK。
- [ ] 没有把“AI 解析”写成已具备的联网服务。
- [ ] 文件访问仅通过用户选择器。
- [ ] 隐私政策可从主功能界面 4 次以内访问，内容独立、清晰。
- [ ] 应用截图展示真实的本地数据处理和导入预览，不展示不存在的云同步。
- [ ] 预测文案包含“估算/参考”，不涉及医疗诊断或避孕承诺。
- [ ] 发布包在无网环境下仍能完成核心功能。
- [ ] 导出文件格式、版本号和恢复流程在发布说明中可查。
