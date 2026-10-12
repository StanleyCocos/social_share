# Changelog

## 0.0.1

- 使用 FVM Flutter 3.38.10 创建 Monorepo，通过 Melos 管理 Core、Facebook、LINE、Threads 和统一 Example。
- 提供 Facebook、LINE 的 Android / iOS 原生分享功能。
- 提供 `FlutterShare.share`、`ShareModel`、`SharePlatform` 和 `{state, msg}` 回调格式。
- 为各平台使用独立 Channel、原生类名和 FileProvider authority，支持按需依赖和同时集成。
- Threads 第一版仅创建插件骨架，尚未实现分享。
- 提供接入文档、平台实现说明、Dart 回归测试和双平台 Example。
