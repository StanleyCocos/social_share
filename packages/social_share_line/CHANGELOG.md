# Changelog

## 0.0.1

- 从 `flutter_share` 提交 `48debc8f1dce843954b8613095af1ac950d3918b` 迁移 LINE Android Kotlin / iOS Objective-C 分享实现。
- 保留 Android Intent、目标 Activity 顺序、图片处理和网页兜底；保留 iOS URL Scheme、剪贴板分享及该提交的文字编码逻辑。
- 保留原成功 / 失败返回时序和语义；iOS 继续声明 `LineSDKSwift ~> 5.16` 依赖，实际分享仍使用 Scheme / 剪贴板。
- 保留 Android 插件 minSdk 16 和 iOS 最低版本 15.6 声明。
- 使用独立 Channel、原生类名和 FileProvider authority；移除 Facebook 实现及其原生依赖，导出 Core 公共 API。
- 提供配置与使用说明、兼容导入入口及 Dart 接入测试。
