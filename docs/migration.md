# 第一版迁移边界

唯一实现基线：`StanleyCocos/flutter_share` 的 `48debc8f1dce843954b8613095af1ac950d3918b`，提交说明为 `fix: iOS分享链接拼接问题`。未使用默认分支的新实现。

## 必要的结构调整

- 用 `fvm flutter create` 创建 Core、Facebook、LINE、Threads 和 Example。
- `ShareModel` 和 `SharePlatform` 移入 Core；字段、默认值及枚举顺序保持一致。
- `FlutterShare.share` 保留原方法签名、参数 Map、原始返回值和可选回调；根据平台使用独立 Channel。
- Facebook Channel：`social_share_facebook`；LINE Channel：`social_share_line`。由 Flutter 自动注册对应原生插件，业务无需手动注册。
- Android 包名分别改为 `com.addcn.social_share_facebook` / `com.addcn.social_share_line`，插件类名分别为 `SocialShareFacebookPlugin` / `SocialShareLinePlugin`。
- Objective-C 的插件类、ShareHelper 和 ShareModel 增加平台前缀，避免两个插件共存时同名类冲突。iOS 没有改写为 Swift。
- FileProvider authority 分别为 `${applicationId}.social_share_facebook.fileprovider` 和 `${applicationId}.social_share_line.fileprovider`，匹配对应代码；文件路径配置仍只暴露 cache-path。
- 从每个平台插件删除另一平台的调用分支和 SDK 依赖；LINE 生命周期中不再访问 Facebook CallbackManager。
- 使用 Flutter 3.38.10 生成的 Gradle / Kotlin 构建配置。Android Facebook / LINE 插件 minSdk 沿用源提交的 16，Example 使用 Flutter 模板的宿主最低版本。iOS Facebook / LINE 仍声明 15.6。
- Example 的 Podfile 将传递依赖的过旧部署版本提升至 Example 已要求的 iOS 15.6，以适配本机 Xcode；插件分享逻辑不变。
- `platformVersion` 先访问 Facebook Channel；没有该插件时尝试 LINE Channel，使仅集成 LINE 的 iOS 工程也能读取旧版本信息。Android 仍未实现该方法，与源提交一致。

## 原生依赖

| 插件 | Android | iOS |
| --- | --- | --- |
| Facebook | `facebook-share:12.0.0` | `FBSDKShareKit ~> 18.0`、`FBSDKCoreKit ~> 18.0` |
| LINE | 原 Intent / FileProvider 实现 | 保留源提交声明的 `LineSDKSwift ~> 5.16`；分享代码仍用 Scheme / 剪贴板 |

iOS 约束与源提交一致，源仓库没有提交 Podfile.lock。当前 Example 解析为 FBSDK 18.1.0、LineSDKSwift 5.17.0，见 Example 的 Podfile.lock。

## 原行为保留

- Android 两个平台均优先处理非空 text；图片仅在 text 为空时处理。
- Facebook Android 将 text 作为链接；iOS 只将以 http 开头的 text 识别为链接，链接优先于图片。
- Facebook iOS 保留 Native → Browser → Web → 外部网页的兜底顺序、1.2 秒延迟判断、对象保活和单次完成逻辑。
- Facebook iOS SDK 错误仍按原逻辑尝试网页兜底。
- LINE iOS 保留此提交的文字编码和 `https://line.me/R/share?text=…` 兜底。
- LINE Android 保留三个目标 Activity 类名以及原顺序。
- 图片下载、压缩、WebP 后缀替换、WebView 配置保持原实现。
- 返回 `state=0/1/2`、`msg` 和原始错误文字，不转换成新的结果或异常模型。
- 未指定 platform 时仍向 LINE 发送原 `platform: "null"` 参数，保留原 iOS 的 LINE 默认分支；原 Android 不处理此平台值，仍不会完成分享回调。业务请显式指定平台。

以下限制也保持原样，本次没有修复：

- LINE Android 在启动目标应用前返回 state=0，不能据此判断最终分享结果。
- LINE iOS 和外部网页的 state=0 表示打开成功，不能确认最终发布。
- Facebook Android 网页兜底没有完成原 MethodChannel 返回，调用可能一直等待。
- LINE Android 网络图片下载线程尚未结束时就返回文件 URI。
- Facebook Android 网络图片分支仍在原下载线程调用 SDK；iOS 网络图片仍同步下载。
- text 与 image 同时传入时不做组合分享。

## 源码核对

```sh
git clone https://github.com/StanleyCocos/flutter_share.git /tmp/flutter_share_reference
git -C /tmp/flutter_share_reference checkout --detach 48debc8f1dce843954b8613095af1ac950d3918b
python3 tool/verify_migration.py /tmp/flutter_share_reference
```

脚本校验源仓库提交、源文件是否被修改、保留的原生方法体及共享文件。方法体比对仅归一化命名空间和必要的 LINE Facebook 状态移除。平台入口分发和注册调整由 Dart 路由测试及 Example 双端编译验证。

自动测试与编译不等于真机分享验证。迁移后仍需在业务 App 上验证双端、官方 App 安装/未安装、链接/本地图片/网络图片以及 Facebook 回调。

## 本机 iOS 模拟器构建

本次环境为 Xcode 27。`fvm flutter build ios --simulator` 的多架构构建在 Flutter 3.38.10 的 `lipo -verify_arch arm64 x86_64` 调用处失败；这属于工具链组合问题，两个迁移插件的源码已编译。

使用以下单 arm64 目标完成集成构建，不修改 SDK 或插件业务代码：

```sh
cd example/ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner \
  -configuration Debug -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=YES \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO \
  -derivedDataPath /tmp/social_share_ios_build build
```

`example/ios/Podfile` 的部署版本设置仅用于宿主 Example，未改写插件中的图片、分享、回调或兜底实现。
