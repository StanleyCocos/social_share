# Changelog

## 0.0.1

- 提供 LINE Android Kotlin / iOS Objective-C 分享功能。
- Android 使用 Intent、FileProvider 和网页兜底；iOS 使用 URL Scheme、剪贴板及文字编码。
- iOS 声明 `LineSDKSwift ~> 5.16` 依赖，实际分享使用 Scheme / 剪贴板。
- Android 插件声明 minSdk 16，iOS 最低版本 15.6。
- 使用独立 Channel、原生类名和 FileProvider authority，导出 Core 公共 API。
- 提供配置与使用说明、公共导入入口及 Dart 接入测试。
