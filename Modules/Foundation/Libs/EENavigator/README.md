# EENavigator

EENavigator 主要提供了通过URL来进行页面导航的功能。

## 简介

### 目录结构

```
├── Extensions
│   └── RouteHandler.swift
├── Navigator
│   ├── AsyncResource.swift
│   ├── Extension+Navigator.swift
│   ├── Extension+UITabBarController.swift
│   ├── Extension+UIViewController.swift
│   ├── NaviParams.swift
│   ├── Navigator.swift
│   ├── NavigatorUtils.swift
│   ├── Protocols.swift
│   ├── Swizzling.swift
│   ├── UIViewController+Hook.h
│   └── UIViewController+Hook.m
├── Router
│   ├── Body.swift
│   ├── ContextKeys.swift
│   ├── Extensions+Router.swift
│   ├── Middleware.swift
│   ├── Request.swift
│   ├── Response.swift
│   ├── Router.swift
│   └── RouterError.swift
└── URLMatcher
    ├── BlockURLMatcher.swift
    ├── Extensions.swift
    ├── MatchResult.swift
    ├── PathPatternURLMatcher.swift
    ├── PathToRegExp
    │   ├── Options.swift
    │   ├── String+Parse.swift
    │   └── Token.swift
    ├── RegExpURLMatcher.swift
    └── URLMatcher.swift
```

`URLMatcher` 包含 `PathPatternURLMatcher`，`RegExpURLMatcher`和`BlockURLMatcher`

- `PathPatternURLMatcher` 用于按特定的格式匹配URL
- `RegExpURLMatcher` 用于通过自定义的正则表达式来匹配URL
- `BlockURLMatcher` 用于通过函数来匹配URL

这3个类主要用于 `EERouter` 的URL匹配。`URLMatcher`可以作为一个模块单独使用。

```swift
protocol URLMatcher {
    func match(url: URL) -> MatchResult
}

struct MatchResult {
    var matched: Bool = false
    var params: [String: String] = [:]
    var groups: [String?] = []
    var url: String = ""
}
```

`Swizzling` 的作用是在swift里进行方法交换。

`EERouter` 提供了通过URL定位资源的功能，也就是路由的能力，这里的资源可以是任何对象，并没有限制只是 view controller或者view。`EERouter`也可以作为一个模块单独使用。

```swift
open class Router {
    open func registerRoute(
        pattern: String,
        priority: Priority = .default,
        tester: @escaping Tester = defaultTester,
        _ routeHandler: @escaping MiddlewareHandler
    )
    open func registerRoute(
        regExpPattern: String,
        priority: Priority = .default,
        tester: @escaping Tester = defaultTester,
        _ routeHandler: @escaping MiddlewareHandler
    )
    open func registerRoute<T: Body>(
        type: T.Type,
        priority: Priority = .default,
        tester: @escaping Tester = defaultTester,
        _ routeHandler: @escaping (T, Request, Response) -> Void
    )
    open func registerRoute(
        match: @escaping MatchBlock,
        priority: Priority = .default,
        tester: @escaping Tester = { _ in true },
        _ routeHandler: @escaping MiddlewareHandler
    )

    open func registerMiddleware(pattern: String = "", postRoute: Bool = false, _ middlewareHandlers: [MiddlewareHandler])
    open func registerMiddleware(pattern: String = "", postRoute: Bool = false, _ middlewareHandler: @escaping MiddlewareHandler)
    open func registerMiddleware(regExpPattern: String, postRoute: Bool = false, _ middlewareHandler: @escaping MiddlewareHandler)
    open func registerMiddleware(regExpPattern: String, postRoute: Bool = false, _ middlewareHandlers: [MiddlewareHandler])

    open func deregisterRoute(_ pattern: String)
    open func deregisterMiddleware(_ pattern: String)

    open func resource(for url: URL, context: [String: Any] = [:]) -> Response
    open func contains(_ url: URL) -> Bool
}
```

`EENavigator` 是对 `EERouter` 的封装，主要提供的能力是定位对应的view controller和push、present、switch tab等操作。

```swift
open class Navigator: Router {
    open func open(_ url: URL, context: [String: Any] = [:], completion: MiddlewareHandler? = nil)

    open func present(
        _ url: URL,
        context: [String: Any] = [:],
        wrap: UINavigationController.Type? = nil,
        from: UIViewController? = nil,
        animated: Bool = true,
        completion: MiddlewareHandler? = nil
    )

    open func push(
        _ url: URL,
        context: [String: Any] = [:],
        from: UIViewController? = nil,
        animated: Bool = true,
        completion: MiddlewareHandler? = nil
    )

    open func switchTab(_ url: URL, completion: Completion? = nil)

    open func popTo(_ url: URL, animated: Bool = true, completion: Completion? = nil)
    open func popTo(_ ancestor: UIViewController, animated: Bool = true, completion: Completion? = nil)
}
```

针对通用导航和Model参数，对Navigator进行了拓展
```swift
extension Navigator {
    public func push(
        _ viewController: UIViewController,
        from: UIViewController? = nil,
        animated: Bool = true
    )

    public func present(
        _ viewController: UIViewController,
        wrap: UINavigationController.Type?,
        from: UIViewController? = nil,
        animated: Bool = true,
        completion: Completion? = nil
    )

    public func present<T: Body>(
        body: T,
        naviParams: NaviParams? = nil,
        wrap: UINavigationController.Type? = nil,
        from: UIViewController? = nil,
        animated: Bool = true,
        completion: MiddlewareHandler? = nil
    )

    public func push<T: Body>(
        body: T,
        naviParams: NaviParams? = nil,
        from: UIViewController? = nil,
        animated: Bool = true,
        completion: MiddlewareHandler? = nil
    )

    public func open<T: Body>(
        body: T,
        naviParams: NaviParams? = nil,
        completion: MiddlewareHandler? = nil
    )
```

### 关键概念

#### 1. URL

![image](https://ws4.sinaimg.cn/large/006tNbRwly1fv8w418ausj30f206a74b.jpg)

#### 2. URL pattern

URL patterns 可以包含一些占位符，占位符会被 URL 中匹配的值替换，占位符的格式是 `:placeholder`。 占位符和 URL 中的 query 参数类似，主要的不同是占位符位于 path 中，并且参与资源标识的计算（query 参数和 fragment 不参与资源标识符的计算）

举个例子， `myapp://chat/:chatId` 可以匹配以下URL

* `myapp://chat/123`
* `myapp://chat/abc`

但是下面的不可以：

* `//chat/123` (缺少scheme)
* `myapp://chat/123/posts` (结构不一致)

如果想将 `chatId` 限制为 int 类型，可以使用 `myapp://chat/:chatId(\d+)`，那么 `myapp://chat/abc` 就不会命中了。

`myapp://chat/:chatId/:position?` 可以命中以下URL：

* `myapp://chat/123`
* `myapp://chat/123/234`

`myapp://chat/a+b` 可以命中以下URL：

* `myapp://chat/aab`
* `myapp://chat/aaab`

#### 3. Request and Response

`Request` 用于保存请求的上下文，包含请求的 URL （会对原始有一些规范化的处理，例如：去除通用scheme等操作）和 请求处理中的上下文（成功回调、匹配的path参数、正则匹配的分组等）。

```swift
public class Request {
    public let url: URL
    public var context: [String: Any]
    // 包含url的path参数、query和传入的context
    public var parameters: [String: Any]
    // 如果请求体是类型参数可以通过这个字段获取
    public var body: Body?
}
```

以下 key 是保留的，不允许外部使用：

```swift
public struct ContextKeys {
    /// Key for matched groups of custom url matcher
    public static let matchedGroups = "_kMatchedGroups"
    /// Key for matched path parameters of default url matcher
    public static let matchedParameters = "_kMatchedParameters"

    /// Key for redirect callback
    static let acyncRedirect = "_kAnsyncRedirect"
    /// Key for redirect times
    static let redirectTimes = "_kRedirectTimes"

    /// Key for request body
    static let body = "_kBody"

    /// Key for matched or not
    static let matched = "_kMatched"
}
```

`Response` 用于保存请求的结果（例如状态码和定位到的资源），以及重定向、发送资源等方法

```swift
public class Response {
    /// Resource
    public private(set) var resource: Resource?
    /// Error from routes or middlewares
    public private(set) var error: Error?
    /// Associated request
    public let request: Request
    /// Status
    public private(set) var status: Status = .handling

    public func redirect<T: Body>(body: T, naviParams: NaviParams? = nil)
    public func redirect(_ url: URL, context: [String: Any] = [:])

    public func append(error: Error)
    public func end(resource: Resource?)
    public func end(error: Error?)
    public func wait()
}
```

`Resource`的定义如下：
```swift
public protocol Resource {
    var identifier: String? { get set }
}
```

#### 4. Middleware and Route

`Middleware` 顾名思义就是中间件，是 `EERouter` 的一个核心概念，用于存储用户注册的中间件，定义如下：

```swift
struct Middleware {
    let pattern: String
    let handler: MiddlewareHandler
    let tester: Tester
    let matcher: URLMatcher
}
```

其中 `pattern` 是原始的 URL pattern 或自定义正则表达式，`matcher` 用于匹配对应的请求是否命中，`handler` 是命中时执行的处理函数，定义如下：

```swift
public typealias MiddlewareHandler = (Request, Response) -> Void
```

每一层中间件处理完成之后，通过调用 next，来执行下一个中间件。

完整的路由处理过程如下图所示，整个过程分为三部分，路由前、路由中、路由后，任何一个中间件调用`response.end`或`ressponse.redirect`都会结果整个路由过程，下游的中间件不会继续匹配。

![image](https://ws1.sinaimg.cn/large/006tNbRwly1fv8w2zk1fbj30lo0qedh2.jpg)

`Route` 和 `Middleware` 本质上没有区别，都是中间件，唯一的区别就是所处的位置，位于中间部分，而且路由是唯一匹配，也就是只要路由匹配了，其他路由是不会继续处理的

#### 5. Error handling

中间件的处理过程可能发生错误，错误可以通过 `res.append(error)` 传递给下游中间件，这里使用的是 `RouterError` 对象，定义如下：

```swift
public class RouterError: Error {
    /// Error message
    public let message: String
    /// Error code
    public let code: Int

    /// Error stack, contains all the error
    public private(set) var stack: [Error] = []
    /// Top most error of error stack
    public var current: Error {
        return stack.last ?? self
    }
}
```

每一层中间件的 error 都会加入到 stack 中，下游中间件可以获得前面所有的报错信息。

## 使用

### 注册路由
使用path pattern来匹配

```swift
EENavigator.shared.registerRoute(pattern: "//chat/:chatId") { (req, res) in
    let vc = ChatViewController()
    res.end(resource: vc)
}
```
使用自定义正则匹配
```swift
EENavigator.shared.registerRoute(regExpPattern: "^http://") { (req, res) in
    let vc = WebViewController()
    res.end(resource: vc)
}
```
使用自定义block匹配
```swift
EENavigator.shared.registerRoute(match: { url in
    return url.port > 10000
}) { (req, res) in
    let vc = WebViewController()
    res.end(resource: vc)
}
```
使用强类型的Body匹配（回调里会增加body参数）
```swift
EENavigator.shared.registerRoute(type: ChatControllerBody.self) { (body, req, res) in
    let vc = ChatViewController()
    vc.chatId = body.chatId
    res.end(resource: vc)
}
```
为路由增加优先级，默认为`default`（`high`>`default`>`low`）
```swift
Navigator.shared.registerRoute(regExpPattern: "^http(s)?\\://", priority: .low) {
    // ...
}
```
### 路由重定向
同步重定向，处理url需要映射为其他url的情况

```swift
Navigator.shared.registerRoute(regExpPattern: "^http(s)?\\://") { req, res in
    if req.url.host == "docs.bytedance.com" {
        res.redirect("//docs/floder")
        return
    }
    return res.end(resouece: WebViewController())
}
```

### 注册中间件

注册路由前的中间件，下面是一个简单的打印log的中间件：

``` swift
EENavigator.shared.registerMiddleware { (req, _) in
    print(req.url.absoluteString)
}
```

注册路由后的中间件，下面处理404的中间件：

```swift
EENavigator.shared.registerMiddleware(postRoute: true) { (_, res) in
    if res.error == .notFound {
        res.end(resource: NotFoundViewController())
    }
}
```

重定向
```swift
// A fake redirect map
var redirects: [(URLMatcher, String)] = []
EENavigator.shared.registerMiddleware(postRoute: false) { (req, res) in
    if let redirect = redirects.first(where: {
        $0.match(req.url)
    }) {
        res.redirect(redirect.1);
    }
}
```

### 打开页面
Push页面

```swift
EENavigator.shared.push(URL(string: "//chat/123#abc")!)
```

Present页面
```swift
// 直接present
EENavigator.shared.push(URL(string: "//chat/123#abc")!, animated: true)

// 包裹导航
EENavigator.shared.push(URL(string: "//chat/123#abc")!, animated: true, wrap: UINavigationController.self)
```

直接open
```swift
EENavigator.shared.open(URL(string: "//chat/123")!) { req, res in
    // 没有传递导航参数的情况下，需要自己处理结果
    // res.resource
}
```

### 打开页面结束回调

```swift
EENavigator.shared.push(URL(string: "//chat/123#abc")!) { _, _ in
    print("push chat success")
}
```

### 传递自定义context

对于一些没有序列化的对象，也就是没有通过 URL 来传递的参数，可以通过context来传递，例如要传递

```swift
// 调用
ENavigator.shared.push(URL(string: "//chat/123#abc")!, context: ["name": "lwl"])
// 注册
EENavigator.shared.registerRoute(pattern: "//chat/:chatId") { (req, res) in
    print(req.parameters["name"]) // lwl
}
```

## 拓展功能

### 传递导航参数
路由跳转时有时候需要切换tab、pop页面等操作，此时可以传递导航参数，这些参数也支持通过字典或者url的query传递，反序列化为对应的model已经由路由处理了
```swift
public enum OpenType: String, RawEnum {
    case push, present, none
}

public struct NaviParams {
    public var openType: OpenType = .none
    public var popTo: URL?
    public var switchTab: URL?
    public var animated: Bool = true
}
```

例如，调到一个页面是需要切换tab到feed
```swift
let body = ChatControllerBody()

var naviParams = NaviParams()
naviParams.switchTab = URL(string: "//feed/home")!

let context = [String: Any].with(body: body).merging(naviParams: naviParams)

Navigator.shared.push(url: body.url, context: context)
```

### 通过fragment进行页面内定位
页面只要符合`FragmentLocate`协议就可以了
```swift
public protocol FragmentLocate {
    func customLocate(by fragment: String, with context: [String: Any], animated: Bool)
}
```

使用
```swift
Navigator.shared.switchTab(URL(string: "//chat/home#folder")!)

// docs首页controller的处理
extension ChatViewController: FragmentLocate {
    func customLocate(by fragment: String, with context: [String: Any], animated: Bool) {
        if fragment == "folder" {
            print(fragment)
        }
    }
}
```

### 导航通知
路由对页面进行操作时，需要通知响应的controller，可以使用`NavigatorNotification`协议，目前只支持在页面被dismiss时通知相应的controller
```swift
public protocol NavigatorNotification where Self: UIViewController {
    func willDismiss(animated: Bool)
}
```

### 异步

异步返回结果
```swift
Navigator.shared.registerRoute(pattern: "/async") { (_, res) in
    chatAPI.getChat() { chat in
        let controller = ChatViewController()
        controller.chat = chat
        res.end(resouce: controller)
    }
    res.wait()
}
```

异步重定向，主要用于需要异步请求接口，然后跳转到一个同步的接口上
```swift
Navigator.shared.registerRoute(pattern: "/async") { (_, res) in
    chatAPI.getChat() {
        res.redirect(URL(string: "//chat/async")!)
    }
    res.wait()
}
```

## 需要注意的点

* URL 的`scheme`和`host`是不区分大小写的，但是 `path`、`query`、`fragment`是区分的
* `//a/b` 和 `/a/b` 有区别，前者 a 是 host，后者 a 是path的一部分
* URL pattern里不要添加 `scheme`，主要是出于迁移和对 `scheme` 变更的考虑，内部请求也是。但对于和应用 `scheme` 不一致的请求则需要明确 `scheme`，例如: `http`、`https`

* 能够唯一标识资源的参数应该放到路径中，例如`//chat/:id`

## TODO
- [x] 参数序列化（目前都是字符串，需要提供序列化参数的能力）
- [x] 参数校验（可选，类型检查，保证请求的参数都是符合要求的）
- [x] 重定向
- [x] Swift方法替换耗时
- [x] pattern判重
- [ ] 规则排序
- [x] 异步error
- [x] 增加参数设置方法
