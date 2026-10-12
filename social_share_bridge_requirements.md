# Social Share Bridge

## 1. 项目概述

**项目名称：** `social_share_bridge`

`social_share_bridge` 是一个面向 Flutter 的多社交平台原生分享组件集合。

项目采用 **Monorepo + 多 Package / Plugin** 架构，在同一个 Git
仓库中维护所有组件，但各个平台组件可以独立发布、独立依赖、独立升级。

首期支持：

-   Facebook
-   LINE
-   Threads

项目只负责
**分享（Share）能力**，不包含第三方登录、账号体系、用户资料获取等功能。

未来允许继续扩展 Instagram、WhatsApp、X、Telegram 等其他社交平台。

------------------------------------------------------------------------

## 2. 核心目标

### 2.1 按需依赖

业务项目只引入实际需要的平台。

例如：

**项目 A：Facebook + LINE**

``` yaml
dependencies:
  social_share_facebook: ^1.0.0
  social_share_line: ^1.0.0
```

**项目 B：仅 Facebook**

``` yaml
dependencies:
  social_share_facebook: ^1.0.0
```

**项目 C：Facebook + Threads**

``` yaml
dependencies:
  social_share_facebook: ^1.0.0
  social_share_threads: ^1.0.0
```

没有使用的平台，不应该因为 `social_share_bridge`
的设计而被强制引入对应的 iOS / Android 原生 SDK。

### 2.2 统一 Flutter API

虽然底层平台 SDK、Intent、URL Scheme 或系统能力不同，但 Flutter
层应尽可能提供统一的调用模型。

示例目标 API：

``` dart
await SocialShare.share(
  platform: SocialPlatform.facebook,
  content: ShareContent(
    text: 'Hello',
    url: Uri.parse('https://example.com'),
  ),
);
```

具体平台不支持某种内容类型时，应通过能力声明或明确错误返回告知调用方，而不是静默失败。

### 2.3 易于扩展

新增一个社交平台时，应尽可能做到：

1.  新建独立平台 Plugin。
2.  依赖 Core。
3.  实现统一接口。
4.  增加平台原生实现。
5.  增加测试和 Example。
6.  独立发布。

不应该为了新增平台大量修改已有 Facebook、LINE、Threads 的实现。

------------------------------------------------------------------------

## 3. 非目标

当前项目明确不包含：

-   Facebook Login
-   LINE Login
-   Threads OAuth 登录能力
-   社交账号绑定
-   用户 Profile 获取
-   好友列表
-   Feed 获取
-   社交平台数据分析

即：

``` text
social_share_bridge = Share Only
```

如果某个平台的官方分享能力本身需要授权，则只实现完成"分享"所必需的授权流程，不将项目扩展成通用登录
SDK。

------------------------------------------------------------------------

## 4. 仓库架构

采用 Monorepo：

``` text
social_share_bridge/
│
├── packages/
│   │
│   ├── social_share_core/
│   │   ├── lib/
│   │   ├── test/
│   │   └── pubspec.yaml
│   │
│   ├── social_share_facebook/
│   │   ├── lib/
│   │   ├── android/
│   │   ├── ios/
│   │   ├── test/
│   │   └── pubspec.yaml
│   │
│   ├── social_share_line/
│   │   ├── lib/
│   │   ├── android/
│   │   ├── ios/
│   │   ├── test/
│   │   └── pubspec.yaml
│   │
│   └── social_share_threads/
│       ├── lib/
│       ├── android/
│       ├── ios/
│       ├── test/
│       └── pubspec.yaml
│
├── example/
│
├── melos.yaml
├── pubspec.yaml
├── README.md
├── CHANGELOG.md
└── LICENSE
```

使用 **Melos** 管理整个 Dart / Flutter Monorepo。

------------------------------------------------------------------------

## 5. Package 职责

### 5.1 `social_share_core`

纯 Dart / Flutter 公共层。

主要负责：

-   公共 API 定义
-   `SocialPlatform`
-   `ShareContent`
-   `ShareResult`
-   `ShareException`
-   平台能力描述
-   平台实现接口
-   公共参数校验
-   公共错误定义

Core **不直接依赖 Facebook、LINE、Threads 的原生 SDK**。

建议尽量保持 Core 轻量。

### 5.2 `social_share_facebook`

Facebook 原生分享实现。

负责：

``` text
Flutter
   ↓
social_share_core
   ↓
social_share_facebook
   ↓
iOS / Android
   ↓
Facebook 官方支持的分享能力
```

所有 Facebook 特有的：

-   iOS 配置
-   Android 配置
-   SDK 依赖
-   Manifest
-   Info.plist
-   URL Scheme
-   原生调用

均放在该 Plugin 内处理或在 README 中明确要求业务方配置。

### 5.3 `social_share_line`

LINE 原生分享实现。

职责与 Facebook Plugin 相同，但只包含 LINE 相关实现和原生依赖。

### 5.4 `social_share_threads`

Threads 原生分享实现。

只处理 Threads 分享相关能力。

实现前必须根据 Threads / Meta 当前官方文档确认 iOS 与 Android
可使用的官方分享入口。

禁止依赖未经官方保证、可能随版本失效的私有接口。

------------------------------------------------------------------------

## 6. 依赖关系

依赖方向统一为：

``` text
                    ┌───────────────────────┐
                    │   Flutter Business    │
                    │          App          │
                    └───────────┬───────────┘
                                │
              ┌─────────────────┼─────────────────┐
              │                 │                 │
              ▼                 ▼                 ▼
    social_share_facebook  social_share_line  social_share_threads
              │                 │                 │
              └─────────────────┼─────────────────┘
                                ▼
                       social_share_core
```

平台 Plugin 可以依赖 Core。

Core **禁止反向依赖任何具体平台 Plugin**。

------------------------------------------------------------------------

## 7. 使用者依赖原则

业务项目原则上 **不需要显式添加 `social_share_core`**。

例如：

``` yaml
dependencies:
  social_share_facebook: ^1.0.0
  social_share_line: ^1.0.0
```

其中：

``` text
social_share_facebook
        ↓
social_share_core

social_share_line
        ↓
social_share_core
```

由平台组件自行声明 Core 依赖。

------------------------------------------------------------------------

## 8. Flutter API 设计

API 设计应保持平台无关。

建议核心模型：

``` dart
enum SocialPlatform {
  facebook,
  line,
  threads,
}
```

分享内容：

``` dart
class ShareContent {
  final String? text;
  final Uri? url;
  final List<String>? imagePaths;
  final List<String>? videoPaths;

  const ShareContent({
    this.text,
    this.url,
    this.imagePaths,
    this.videoPaths,
  });
}
```

调用示例：

``` dart
final result = await SocialShare.share(
  platform: SocialPlatform.facebook,
  content: ShareContent(
    text: 'Hello',
    url: Uri.parse('https://example.com'),
  ),
);
```

返回结果不要只使用 `bool`。

建议：

``` dart
enum ShareStatus {
  success,
  cancelled,
  unavailable,
  unsupported,
  failed,
}
```

``` dart
class ShareResult {
  final ShareStatus status;
  final String? message;

  const ShareResult({
    required this.status,
    this.message,
  });
}
```

这样业务方可以区分：

``` text
分享成功
用户取消
App 未安装 / 平台不可用
内容类型不支持
调用失败
```

需要注意：只有在平台官方接口能够可靠确认发布结果时，才能返回真正意义上的
`success`。如果原生能力只能确认"已成功打开分享界面"，应设计不同语义，避免把"打开成功"误认为"发布成功"。

------------------------------------------------------------------------

## 9. 平台能力差异

不能假设所有平台都支持完全相同的分享能力。

Core 应允许表达：

``` text
                    Facebook   LINE   Threads
Text                    ?        ?       ?
URL                     ?        ?       ?
Image                   ?        ?       ?
Multiple Images         ?        ?       ?
Video                   ?        ?       ?
Text + Image            ?        ?       ?
Text + URL              ?        ?       ?
```

具体支持情况在实现阶段根据各平台最新官方文档确认。

建议提供类似：

``` dart
final capability = await SocialShare.capability(
  SocialPlatform.threads,
);
```

返回：

``` dart
class ShareCapability {
  final bool text;
  final bool url;
  final bool image;
  final bool multipleImages;
  final bool video;
}
```

业务层因此可以提前决定 UI，而不是调用后才发现不支持。

------------------------------------------------------------------------

## 10. 平台可用性

建议统一提供：

``` dart
await SocialShare.isAvailable(
  SocialPlatform.facebook,
);
```

用于判断：

-   平台 App 是否存在
-   当前设备是否支持
-   当前平台 Plugin 是否可用

不要把：

``` text
Plugin 已安装
```

和：

``` text
Facebook / LINE / Threads App 已安装
```

混为一个概念。

------------------------------------------------------------------------

## 11. 原生层设计

各 Plugin 独立维护：

``` text
social_share_xxx
│
├── Dart API / Platform Interface
│
├── iOS
│   └── Swift
│
└── Android
    └── Kotlin
```

默认技术栈：

``` text
Flutter / Dart

iOS
└── Swift

Android
└── Kotlin
```

新代码不以 Objective-C / Java 作为默认实现语言。

------------------------------------------------------------------------

## 12. 平台通信

Flutter 与 Native 之间优先采用 Flutter 官方 Plugin 机制。

根据接口复杂度选择：

``` text
MethodChannel
```

或：

``` text
Pigeon
```

如果接口数量较少，第一阶段可以使用 MethodChannel。

如果后续：

-   参数模型复杂
-   平台数量增加
-   API 数量明显增加
-   类型安全需求提高

则优先考虑迁移到 Pigeon。

不要让业务项目直接调用各平台 MethodChannel。

------------------------------------------------------------------------

## 13. 平台组件独立发布

每个 Package 拥有自己的：

``` text
pubspec.yaml
README.md
CHANGELOG.md
版本号
```

例如：

``` text
social_share_core        1.0.0
social_share_facebook    1.0.0
social_share_line        1.0.0
social_share_threads     1.0.0
```

后续允许：

``` text
social_share_core        1.2.0
social_share_facebook    1.3.1
social_share_line        1.1.0
social_share_threads     2.0.0
```

各组件可以独立升级。

------------------------------------------------------------------------

## 14. Git Tag 建议

因为多个 Package 独立发布，Tag 不建议只使用：

``` text
v1.0.0
```

建议：

``` text
social_share_core-v1.0.0
social_share_facebook-v1.0.0
social_share_line-v1.0.0
social_share_threads-v1.0.0
```

这样可以明确知道哪个 Package 发布了哪个版本。

------------------------------------------------------------------------

## 15. Example

仓库必须提供可运行 Example。

建议 Example 可以动态展示当前集成的平台：

``` text
Social Share Bridge Example

Facebook
[ Share Text ]
[ Share URL ]
[ Share Image ]

LINE
[ Share Text ]
[ Share URL ]
[ Share Image ]

Threads
[ Share Text ]
[ Share URL ]
[ Share Image ]
```

Example 同时承担：

-   开发调试
-   SDK 验证
-   集成示例
-   回归测试
-   README 使用参考

------------------------------------------------------------------------

## 16. 测试要求

### Core

至少覆盖：

-   参数校验
-   ShareContent
-   ShareResult
-   Capability
-   错误模型
-   平台注册逻辑

### Platform Plugin

至少覆盖：

``` text
App 已安装
App 未安装
正常调用
用户取消（平台可判断时）
参数不支持
原生调用异常
```

### 真机测试

涉及第三方 App 的分享能力不能只依赖模拟器。

至少验证：

``` text
iOS 真机
Android 真机
```

并分别安装对应官方 App 测试。

------------------------------------------------------------------------

## 17. 错误处理

统一错误类型，不应该把 Native Error 原样暴露给业务。

例如：

``` dart
enum SocialShareErrorCode {
  platformUnavailable,
  appNotInstalled,
  unsupportedContent,
  invalidArgument,
  nativeError,
  unknown,
}
```

必要时保留：

``` dart
nativeCode
nativeMessage
```

用于日志和排查。

------------------------------------------------------------------------

## 18. 文档要求

每个平台 Plugin README 至少包含：

``` text
1. 支持的平台
2. 支持的分享类型
3. Flutter 最低版本
4. iOS 最低版本
5. Android 最低版本
6. pubspec 添加方式
7. iOS 配置
8. Android 配置
9. 调用示例
10. 返回结果说明
11. 已知限制
12. 官方文档链接
```

尤其需要明确：

``` text
Facebook / LINE / Threads
```

哪些能力来自官方 SDK，哪些来自系统分享能力，哪些存在平台限制。

------------------------------------------------------------------------

## 19. 新增平台规范

未来新增 Instagram，例如：

``` text
packages/
└── social_share_instagram/
```

流程：

``` text
创建 Plugin
    ↓
依赖 social_share_core
    ↓
实现统一 Share Interface
    ↓
实现 iOS Native
    ↓
实现 Android Native
    ↓
定义 Capability
    ↓
增加测试
    ↓
Example 接入
    ↓
README
    ↓
独立发布
```

原则：

> 新增平台不能要求已有平台 Plugin 互相依赖。

禁止出现：

``` text
social_share_threads
        ↓
social_share_facebook
```

除非某个平台官方技术机制明确要求，并经过架构评审。

------------------------------------------------------------------------

## 20. 后续扩展示例

最终仓库可以逐步演变为：

``` text
packages/
├── social_share_core
├── social_share_facebook
├── social_share_line
├── social_share_threads
├── social_share_instagram
├── social_share_whatsapp
├── social_share_x
└── social_share_telegram
```

业务项目始终按需选择：

``` yaml
dependencies:
  social_share_facebook: ^1.3.0
  social_share_threads: ^2.0.0
  social_share_whatsapp: ^1.0.0
```

------------------------------------------------------------------------

## 21. 架构原则总结

整个项目遵循以下原则：

``` text
一个 Git Repository
        ↓
一个 Monorepo
        ↓
多个独立 Flutter Package / Plugin
        ↓
Core 定义公共协议
        ↓
各社交平台独立实现
        ↓
各组件独立发布
        ↓
业务项目按需依赖
```

核心原则：

1.  **Share Only**：项目只解决社交平台分享。
2.  **按需依赖**：不强制引入未使用的平台 SDK。
3.  **平台隔离**：Facebook、LINE、Threads 实现互不耦合。
4.  **统一 API**：业务层尽量不感知 Native 差异。
5.  **尊重平台能力**：不强行把不同平台包装成实际上不存在的一致能力。
6.  **可扩展**：新增平台以新增 Plugin 为主，而不是修改整个架构。
7.  **原生优先官方能力**：优先使用平台官方 SDK / 官方公开接口。
8.  **独立发布**：各平台组件拥有独立版本生命周期。
9.  **Monorepo 管理**：统一使用 Melos 管理开发、测试和发布流程。
10. **可验证**：每个平台都必须有 Example、自动化测试以及必要的真机验证。
