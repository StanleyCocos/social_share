# social_share_line

从 [flutter_share 指定提交](https://github.com/StanleyCocos/flutter_share/tree/48debc8f1dce843954b8613095af1ac950d3918b) 迁移的 LINE 分享插件。

支持 Android / iOS。最低 Flutter 3.38.10、Dart 3.10.9；Android 插件声明 minSdk 16（与源提交一致，宿主 App 仍需满足 Flutter 自身的系统要求），iOS 15.6。

## 依赖和用法

尚未发布时，可在业务项目中使用本地路径，并覆盖 Core 依赖：

```yaml
dependencies:
  social_share_line:
    path: /path/to/social_share/packages/social_share_line
dependency_overrides:
  social_share_core:
    path: /path/to/social_share/packages/social_share_core
```

发布后可以使用 `social_share_line: ^0.0.1`，Core 为传递依赖。

```dart
import 'package:social_share_line/social_share_line.dart';

await FlutterShare.share(
  ShareModel(
    platform: SharePlatform.Line,
    text: 'https://example.com/',
    // 单图时保持 text 为空，设置 image 为网络 URL 或本地路径。
  ),
  result: (state, msg) {
    // 沿用旧格式：0 成功、1 失败、2 取消。
  },
);
```

文字 / 链接、单张网络图片 / 本地图片。非空 text 优先于 image，不提供多图或视频。

## 原生依赖

Android 使用 Intent / FileProvider；iOS 使用 LINE URL Scheme / 剪贴板。保留 `LineSDKSwift ~> 5.16` 依赖声明，分享代码未调用该 SDK。

## iOS 配置

业务 App 的 Info.plist 保留原示例的 LINE 查询配置：

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>line</string>
  <string>lineauth</string>
  <string>line3rdp.$(PRODUCT_BUNDLE_IDENTIFIER)</string>
</array>
```

## Android 配置

业务 App Manifest 添加原包查询配置：

```xml
<queries><package android:name="jp.naver.line.android" /></queries>
```

目标 Activity 名称和轮询顺序沿用原实现。

插件 Manifest 自带 INTERNET、WebView Activity 和 FileProvider。FileProvider authority 已独立为 `${applicationId}.social_share_line.fileprovider`，仍只覆盖缓存目录。

## 结果与限制

参数、SDK 回调、图片处理、网页兜底全部沿用源提交。state=0 可能只表示打开成功，不能统一理解为发布成功。此版本没有新增能力查询或安装状态查询 API。

Android 在实际启动前即返回成功；iOS 返回打开 Scheme / 网页的结果，没有最终发布或取消确认。Android 网络图片仍保留原下载时序。

完整迁移边界与保留限制见仓库 `docs/migration.md`。需要在 iOS / Android 真机以及官方 App 安装和未安装场景下验证。

## 官方参考

[LINE URL Scheme](https://developers.line.biz/en/docs/messaging-api/using-line-url-scheme/)。第一版按指定提交迁移，未根据最新官方能力改写实现。
