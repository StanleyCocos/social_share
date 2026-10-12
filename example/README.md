# Social Share Bridge Example

在仓库根目录运行 `fvm flutter pub get` 和 `fvm dart run melos bootstrap` 后：

```sh
cd example
fvm flutter run
```

提供 Facebook 链接 / 单图、LINE 文字或链接 / 单图的手动验证入口。图片输入接受 URL 或缓存目录内的本地路径。Example 同时依赖两个插件，用于验证原生注册、Objective-C 命名和 FileProvider 共存。

Facebook App ID 为示例配置；业务验证请使用自己的配置。iOS 最低 15.6。Threads 未接入。

返回值原样展示，不将“打开成功”解释为“发布成功”。
