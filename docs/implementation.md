# 第一版实现说明

## 组件与调用链

业务 App 按需依赖 Facebook / LINE 插件。各平台插件依赖 Core 并导出公共 API，Core 不反向依赖平台插件或原生 SDK。

`FlutterShare.share` 将 `ShareModel` 的 platform、text、image 通过对应 MethodChannel 发送给原生插件，返回 `{state, msg}` 并触发可选结果回调。

| 平台 | Channel | 原生插件类 |
| --- | --- | --- |
| Facebook | `social_share_facebook` | `SocialShareFacebookPlugin` |
| LINE | `social_share_line` | `SocialShareLinePlugin` |

Flutter 自动注册原生插件，业务无需手动注册。Android 包名、Objective-C 类名和 FileProvider authority 均按平台隔离，支持两个插件共存。

FileProvider authority 为 `${applicationId}.social_share_facebook.fileprovider` 和 `${applicationId}.social_share_line.fileprovider`，文件路径配置只暴露 cache-path。

`platformVersion` 先查询 Facebook Channel，没有对应插件时尝试 LINE Channel；该方法只在 iOS 实现。

## 原生依赖与环境

| 插件 | Android | iOS |
| --- | --- | --- |
| Facebook | `facebook-share:12.0.0` | `FBSDKShareKit ~> 18.0`、`FBSDKCoreKit ~> 18.0` |
| LINE | Intent / FileProvider | 声明 `LineSDKSwift ~> 5.16`，实际分享使用 Scheme / 剪贴板 |

仓库使用 FVM Flutter 3.38.10。Android Facebook / LINE 插件声明 minSdk 16，宿主最低版本由 Flutter 和业务工程决定。iOS Facebook / LINE 最低版本为 15.6。

Example 的 Podfile.lock 固定当前解析的 FBSDK 18.1.0 和 LineSDKSwift 5.17.0。

## 参数处理与平台流程

- Android 两个平台优先处理非空 text；text 为空时才处理图片。
- Facebook Android 将 text 作为链接；iOS 将以 http 开头的 text 识别为链接，链接优先于图片。
- Facebook iOS 按 Native → Browser → Web → 外部网页尝试分享。Native 调用后延迟 1.2 秒，根据 App 是否仍在前台决定是否继续兜底。
- Facebook iOS 的 ShareHelper 保持活动对象存活，并防止重复完成回调。SDK 错误可以继续尝试网页兜底。
- LINE Android 按预设顺序尝试三个目标 Activity。
- LINE iOS 使用编码后的 `line://msg/text/…` 分享文字，使用剪贴板与 `line://msg/image/…` 分享图片。文字网页兜底为 `https://line.me/R/share?text=…`。
- iOS 网络图片同步下载；以 .webp 结尾的图片 URL 会替换成 .png 后尝试下载。
- 未指定 platform 时向 LINE 发送 `platform: "null"`。iOS 使用 LINE 分支，Android 不处理该平台值。业务请显式指定平台。

## 结果语义和已知限制

state=0 为成功、1 为失败、2 为取消（可判断时）。不同路径的成功含义不同，不能统一作为最终发布确认。

- LINE Android 在启动目标 App 前返回 state=0。
- LINE iOS 和外部网页的 state=0 表示打开成功，不能确认最终发布。
- Facebook Android SDK 提供成功 / 取消 / 错误回调，但网页兜底不会完成 MethodChannel 返回，调用可能一直等待。
- LINE Android 网络图片下载线程尚未结束时就交出文件 URI。
- Facebook Android 网络图片分支在下载线程调用 SDK。
- text 与 image 同时传入时不做组合分享。
- 尚未提供多图、视频、能力查询、安装状态查询或 Threads 分享。

## 测试和构建

Dart 测试覆盖公共参数、双平台 Channel 分发、state / msg 返回值、回调和平台包导出。Example 同时集成 Facebook / LINE，用于验证原生注册及插件共存。

自动测试与编译不能替代真机分享验证。需要在双端分别测试目标 App 安装 / 未安装、链接、本地图片、网络图片及 Facebook 回调。

本机 Xcode 27 下，Flutter 3.38.10 多架构模拟器构建可能在 `lipo -verify_arch arm64 x86_64` 调用处失败，可使用以下单 arm64 目标验证集成：

```sh
cd example/ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner \
  -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=YES \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO \
  -derivedDataPath /tmp/social_share_ios_build build
```

Example 的 Podfile 将依赖中的过旧部署版本提升到 Example 要求的 iOS 15.6，用于适配本机工具链。
