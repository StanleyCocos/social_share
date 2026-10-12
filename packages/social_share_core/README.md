# social_share_core

Social Share Bridge 公共 API 层，最低 Flutter 3.38.10 / Dart 3.10.9。

提供 `FlutterShare`、`ShareModel`、`SharePlatform`，不包含原生 SDK。

业务项目依赖具体平台包即可；平台包导出本包的公共 API。`FlutterShare.share` 按 `SharePlatform` 选择独立 Channel，Flutter 原生插件自动注册处理器。

返回 `{state, msg}`，其中 0 为成功、1 为失败、2 为取消。不同调用路径的成功含义不同，详细限制见仓库 `docs/implementation.md`。
