# social_share_facebook

从 [flutter_share 指定提交](https://github.com/StanleyCocos/flutter_share/tree/48debc8f1dce843954b8613095af1ac950d3918b) 迁移的 Facebook 分享插件。

支持 Android / iOS。最低 Flutter 3.38.10、Dart 3.10.9；Android 插件声明 minSdk 16（与源提交一致，宿主 App 仍需满足 Flutter 自身的系统要求），iOS 15.6。

## 依赖和用法

尚未发布时，可在业务项目中使用本地路径，并覆盖 Core 依赖：

```yaml
dependencies:
  social_share_facebook:
    path: /path/to/social_share/packages/social_share_facebook
dependency_overrides:
  social_share_core:
    path: /path/to/social_share/packages/social_share_core
```

发布后可以使用 `social_share_facebook: ^0.0.1`，Core 为传递依赖。

```dart
import 'package:social_share_facebook/social_share_facebook.dart';

await FlutterShare.share(
  ShareModel(
    platform: SharePlatform.Facebook,
    text: 'https://example.com/',
    // 单图时保持 text 为空，设置 image 为网络 URL 或本地路径。
  ),
  result: (state, msg) {
    // 沿用旧格式：0 成功、1 失败、2 取消。
  },
);
```

链接、单张网络图片 / 本地图片。不提供纯文字、多图、视频或 text + image 组合分享。

## 原生依赖

Android `facebook-share:12.0.0`；iOS `FBSDKShareKit ~> 18.0`、`FBSDKCoreKit ~> 18.0`。

## iOS 配置

业务 App 的 Info.plist 沿用原配置：

```xml
<key>FacebookAppID</key>
<string>YOUR_FACEBOOK_APP_ID</string>
<key>CFBundleURLTypes</key>
<array><dict><key>CFBundleURLSchemes</key>
<array><string>fbYOUR_FACEBOOK_APP_ID</string></array>
</dict></array>
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>fbapi</string>
  <string>fbapi20150629</string>
  <string>fbapi20150313</string>
  <string>fbapi20140116</string>
  <string>fbapi20140410</string>
  <string>fbapi20131219</string>
  <string>fbapi20131010</string>
  <string>fbapi20130702</string>
  <string>fbapi20130410</string>
  <string>fbapi20130214</string>
  <string>fb-messenger-api20140430</string>
  <string>fbauth</string>
  <string>fbshareextension</string>
  <string>fbauth2</string>
  <string>fb-messenger-api</string>
</array>
```

Example 的 Info.plist 与 AppDelegate 使用原示例配置，没有新增授权、初始化或 URL 回调逻辑。请使用你现有 App 已验证的 Facebook 配置。

## Android 配置

业务 App Manifest 保留 Facebook App ID 与 ContentProvider 配置：

```xml
<queries><package android:name="com.facebook.katana" /></queries>
<!-- 放在 application 内 -->
<meta-data android:name="com.facebook.sdk.ApplicationId"
    android:value="@string/facebook_app_id" />
<provider android:name="com.facebook.FacebookContentProvider"
    android:authorities="com.facebook.app.FacebookContentProviderYOUR_FACEBOOK_APP_ID"
    android:exported="true" />
```

在 strings.xml 定义 `facebook_app_id`。Example 沿用原示例 App ID，业务集成请保留自己的既有 ID。

插件 Manifest 自带 INTERNET、WebView Activity 和 FileProvider。FileProvider authority 已独立为 `${applicationId}.social_share_facebook.fileprovider`，仍只覆盖缓存目录。

## 结果与限制

参数、SDK 回调、图片处理、网页兜底全部沿用源提交。state=0 可能只表示打开成功，不能统一理解为发布成功。此版本没有新增能力查询或安装状态查询 API。

Android SDK 返回成功 / 取消 / 错误。Android 网页兜底不完成原 Channel 返回。iOS 保留 Native / Browser / Web / 外部网页兜底顺序。

完整迁移边界与保留限制见仓库 `docs/migration.md`。需要在 iOS / Android 真机以及官方 App 安装和未安装场景下验证。

## 官方参考

[Facebook iOS Sharing](https://developers.facebook.com/docs/sharing/ios/)、[Facebook Android Sharing](https://developers.facebook.com/docs/sharing/android/)。第一版按指定提交迁移，未根据最新官方能力改写实现。
