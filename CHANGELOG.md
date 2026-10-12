# Changelog

## 0.0.1

- 使用 FVM Flutter 3.38.10 创建 Monorepo，通过 Melos 管理 Core、Facebook、LINE、Threads 和统一 Example。
- 从 `StanleyCocos/flutter_share` 提交 `48debc8f1dce843954b8613095af1ac950d3918b` 拆分迁移 Facebook、LINE 的 Android / iOS 实现。
- 保留 `FlutterShare.share`、`ShareModel`、`SharePlatform`、原参数优先级、图片处理、网页兜底和 `{state, msg}` 回调格式。
- 为各平台使用独立 Channel、原生类名和 FileProvider authority，避免同时集成时发生冲突。
- Threads 第一版仅创建插件骨架，尚未实现分享。
- 提供各包接入文档、迁移边界说明、源码对照工具、Dart 回归测试和双平台 Example。
