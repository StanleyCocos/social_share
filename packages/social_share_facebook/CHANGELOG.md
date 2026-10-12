# Changelog

## 0.0.1

- 从 `flutter_share` 提交 `48debc8f1dce843954b8613095af1ac950d3918b` 迁移 Facebook Android Kotlin / iOS Objective-C 分享实现。
- 保留链接、单图、图片下载处理、SDK 回调以及原网页兜底顺序和返回语义。
- 保留 Android `facebook-share:12.0.0`，iOS `FBSDKShareKit ~> 18.0` 和 `FBSDKCoreKit ~> 18.0` 依赖约束。
- 保留 Android 插件 minSdk 16 和 iOS 最低版本 15.6 声明。
- 使用独立 Channel、原生类名和 FileProvider authority；移除 LINE 实现及其原生依赖，导出 Core 公共 API。
- 提供配置与使用说明、兼容导入入口及 Dart 接入测试。
