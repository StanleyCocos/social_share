# Social Share Bridge

面向 Flutter 的多平台原生分享组件，采用 Monorepo 管理，各平台插件可以独立依赖和发布。

| 平台 | 当前状态 |
| --- | --- |
| Facebook | 支持 Android / iOS 链接、单图分享 |
| LINE | 支持 Android / iOS 文字或链接、单图分享 |
| Threads | 仅提供插件骨架，尚未实现分享 |

## 环境要求

仓库使用 FVM 固定 Flutter **3.38.10** / Dart **3.10.9**。

业务项目要求 Flutter ≥ 3.38.10、Dart ≥ 3.10.9 且 < 4.0.0；Facebook / LINE 的 iOS 最低版本为 15.6。Android 插件声明 minSdk 16，宿主 App 仍需满足 Flutter 自身的系统要求。

## 本地接入业务项目

当前包尚未发布，使用本地路径接入，将 `/path/to/social_share` 替换成仓库实际路径：

```yaml
dependencies:
  social_share_facebook:
    path: /path/to/social_share/packages/social_share_facebook
  social_share_line:
    path: /path/to/social_share/packages/social_share_line

dependency_overrides:
  social_share_core:
    path: /path/to/social_share/packages/social_share_core
```

可以只依赖需要的平台。Core 的版本依赖需要通过上述本地覆盖解析，业务无需再将 Core 添加到 dependencies。

在业务项目目录运行 `fvm flutter pub get`。完成原生配置后，完全停止 App，再运行 `fvm flutter run`，让新增插件完成原生注册。

原生配置见 [Facebook README](packages/social_share_facebook/README.md) 和 [LINE README](packages/social_share_line/README.md)。Facebook 使用业务项目自己的 App ID。

## 分享调用

任一已依赖的平台包都会导出公共 API；两个包的公共类型来自同一个 Core。

```dart
import 'package:social_share_facebook/social_share_facebook.dart';

// Facebook 链接分享
final response = await FlutterShare.share(
  ShareModel(
    platform: SharePlatform.Facebook,
    text: 'https://example.com/?a=1&b=2',
  ),
  result: (state, msg) {
    // 与 response 使用相同的 state、msg。
  },
);

// LINE 文字或链接分享（业务需依赖 LINE 插件）
await FlutterShare.share(
  ShareModel(
    platform: SharePlatform.Line,
    text: '分享测试 https://example.com/',
  ),
);

// 单图分享，platform 也可以指定 Facebook
await FlutterShare.share(
  ShareModel(
    platform: SharePlatform.Line,
    image: 'https://example.com/photo.jpg',
  ),
);
```

`platform` 请显式传入已集成的平台。`text` 和 `image` 默认空字符串；图片分享时保持 text 为空。image 接受网络图片 URL 或 App 缓存目录中的本地图片绝对路径。

## 返回值和限制

返回动态 Map：`{state, msg}`。state 为 0（成功）、1（失败）或 2（取消，平台可判断时）。

**部分路径的 state=0 仅表示分享入口打开成功，不能确认最终发布。** Android LINE 在实际启动分享前返回成功；Android Facebook 网页兜底不会完成 Channel 返回，调用可能一直等待。

当前不支持多图、视频或 text + image 组合分享，也没有能力查询、安装状态查询或 Threads 分享 API。完整平台行为见 [实现说明](docs/implementation.md)。

## Example 和仓库开发

在仓库根目录执行：

```sh
fvm use 3.38.10
fvm flutter pub get
fvm dart run melos bootstrap
fvm dart run melos run analyze --no-select
fvm dart run melos run test --no-select
cd example
fvm flutter run
```

Melos bootstrap 会生成各包的 `pubspec_overrides.yaml`，将 Core 版本依赖链接到本地包。业务项目使用本地依赖接入时，无需运行本仓库的 Melos 流程。

Example 同时集成 Facebook 和 LINE。测试分享需要 iOS / Android 真机，以及目标 App 安装和未安装两种场景。

| 目录 | 职责 |
| --- | --- |
| `packages/social_share_core` | 公共分享 API 和 Channel 分发 |
| `packages/social_share_facebook` | Facebook 原生分享插件 |
| `packages/social_share_line` | LINE 原生分享插件 |
| `packages/social_share_threads` | Threads 插件骨架 |
| `example` | 双平台分享验证 App |
| `docs` | 实现方式与平台限制说明 |
