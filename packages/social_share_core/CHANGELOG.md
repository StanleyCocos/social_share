# Changelog

## 0.0.1

- 从 `flutter_share` 提交 `48debc8f1dce843954b8613095af1ac950d3918b` 提取公共 Dart API。
- 提供原 `FlutterShare.share`、`ShareModel` 和 `SharePlatform`；保留字段、默认值、枚举顺序、原始结果和可选回调格式。
- 按 Facebook / LINE 分发到独立 MethodChannel，未指定 platform 时向 LINE 发送原 `"null"` 参数。
- 保留 platformVersion 查询入口，并支持仅集成 LINE 的 iOS 工程。
- 不依赖具体平台插件或原生 SDK；提供参数传递和回调兼容性回归测试。
