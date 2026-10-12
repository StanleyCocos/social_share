# Changelog

## 0.0.1

- 提供公共分享 API：`FlutterShare.share`、`ShareModel`、`SharePlatform`。
- 支持 text / image 参数、`{state, msg}` 返回值及可选结果回调。
- 按 Facebook / LINE 分发到独立 MethodChannel；未指定 platform 时向 LINE 发送 `"null"` 参数。
- 提供 iOS platformVersion 查询，支持仅集成 LINE 的工程。
- 不依赖具体平台插件或原生 SDK；提供参数传递和回调测试。
