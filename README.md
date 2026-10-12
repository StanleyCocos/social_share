# Social Share Bridge

Flutter 分享插件 Monorepo，使用 **FVM Flutter 3.38.10 / Dart 3.10.9**。

第一版从 [flutter_share 指定提交](https://github.com/StanleyCocos/flutter_share/tree/48debc8f1dce843954b8613095af1ac950d3918b) 拆分迁移 Facebook、LINE。保留旧 API、参数优先级、图片处理、网页兜底和原生回调语义。Threads 暂时只有插件骨架。

| 目录 | 职责 |
| --- | --- |
| `packages/social_share_core` | `FlutterShare`、`ShareModel`、`SharePlatform`，按平台分发 Channel |
| `packages/social_share_facebook` | Facebook Android Kotlin / iOS Objective-C 分享 |
| `packages/social_share_line` | LINE Android Kotlin / iOS Objective-C 分享 |
| `packages/social_share_threads` | Flutter 创建的插件骨架，尚无分享实现 |
| `example` | 同时集成 Facebook 和 LINE 的验证 App |
| `tool/verify_migration.py` | 与指定提交核对保留的原生方法体 |

## 开发

```sh
fvm use 3.38.10
fvm flutter pub get
fvm dart run melos bootstrap
fvm dart run melos run analyze --no-select
fvm dart run melos run test --no-select
cd example
fvm flutter run
```

Melos bootstrap 会生成各包的 `pubspec_overrides.yaml`，将 Core 版本依赖链接到本地包。平台插件保留独立发布的版本依赖；业务方开发接入未发布的源码时，也需要为 Core 提供本地覆盖，见各插件 README。

## 原 API 用法

只导入已依赖的平台包即可获得公共 API。两个包导出的公共类型来自同一个 Core，同时导入不会产生重复定义。

```dart
import 'package:social_share_facebook/social_share_facebook.dart';
import 'package:social_share_line/social_share_line.dart';

final response = await FlutterShare.share(
  ShareModel(
    platform: SharePlatform.Facebook,
    text: 'https://example.com/?a=1&b=2',
  ),
  result: (state, msg) {
    // 0 / 1 / 2：沿用旧插件返回值，详细语义见迁移说明。
  },
);
```

`platform` 请显式传入已集成的平台；`text`、`image` 默认空字符串，返回值仍为动态 `{state, msg}`。旧式文件名 `package:social_share_facebook/fluttershare.dart` 和 LINE 对应入口也可使用。

第一版不引入需求文档中建议的新 `ShareContent` / `ShareResult` 模型，不增加多图、视频、能力查询或 Threads 分享。

原生配置见 [Facebook README](packages/social_share_facebook/README.md)、[LINE README](packages/social_share_line/README.md)。迁移边界及保留行为见 [迁移说明](docs/migration.md)。
