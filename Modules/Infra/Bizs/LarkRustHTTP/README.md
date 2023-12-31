# LarkRustHTTP
在线更新文档：https://bytedance.feishu.cn/docx/VzXUdCQ9DoLgunxJd2tcbLObnOg

通用Rust HTTP导流库

## Install

Podfile中添加repo源: `source 'git@code.byted.org:ee/pods_specs.git'`
然后在集成的target上添加: `pod 'LarkRustHTTP'`

## 使用方法

### 基本使用

使用该模块前，先要对liblark.a的Rust环境进行**初始化**, 可参考测试中[RustClient初始化代码](app/test/src/Helper.swift)

对需要导流的URLSession, 注册`RustHttpURLProtocol`即可。Alamofire, Kingfisher等都可以用这个方法
(Cancel HTTP的支持需要对`RustHttpManager`配置上`RustService`的依赖)
导流信息相关的信息统计，可以通过URLSessionTask.rustMetrics获取. (URLSession本身的metrics代理可以获取总耗时，但不能获取细节耗时)

WKWebView可通过`WKHTTPHandler.shared.enable(in: configuration)`, 支持WKWebView的导流。
不过为了保证js的cookie能被正确同步上，要么保证所有WKWebView共用同一个pool(提供hook函数`makeWKProcessPoolSingleton`, 后续创建都将返回单例)，要么用私有的`+[WKWebsiteDataStore nonPersistentDataStore]`
另外iOS11苹果的Handler实现有bug，会丢body，iOS12以上才完美支持

UIWebView可通过注册`WebViewHttpProtocol`协议来支持导流HTTP. (做了过滤，不影响其它HTTP请求)

### 扩展配置

URLRequest.enableComplexConnect: 启用rust的复合链接，会延迟进度回调到结束时一次性返回。可能对网速和成功率有提升
RustHttpManager.globalProxyURL: 设置全局的rust请求, proxy配置，系统的配置可以通过RustHttpManager.systemProxyURL读取

### 注意事项
目前上传流量进度无法通知URLSession，会导致无响应超时变成总超时。
开启复合连接下载时，同样也会导致URLSession丢失进度响应。
所以长时间上传或下载时, URLSession的超时不要设置太短，容易被URLSession Cancel掉
Rust内部有默认的超时和无响应超时报错设置。

