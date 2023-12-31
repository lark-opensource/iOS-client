//
//  WKHTTPTests.swift
//  LarkRustClientTests
//
//  Created by SolaWing on 2018/12/29.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

#if ENABLE_WKWebView
import UIKit
import Foundation
import XCTest
import RxSwift
@testable import LarkRustClient
@testable import LarkRustHTTP
import HTTProtocol
import WebKit
import Swifter

private let defaultTimeout: TimeInterval = 10

// iOS 11目前看来WKHTTP导流不稳定，不考虑支持
@available(iOS 12.0, *)
class WKHTTPTests: XCTestCase {
    override func invokeTest() {
        // @available不能阻止测试执行...
        // FIXME: 在最新iOS 16.2的模拟器上，已经跑不通了...。webView导流的能力暂时下掉
        // if (UIDevice.current.systemVersion as NSString).floatValue >= 12 {
        //     super.invokeTest()
        // }
    }

    enum TestError: Error {
        case fail(String)
        case timeout(String)
        case cast
    }

    var tasks = AtomicInt(0) // async running task counter
    var observer: AnyObject!
    var webView: WKWebView! {
        didSet {
            if webView != oldValue {
                observer = nil
                if let v = oldValue {
                    v.removeFromSuperview()
                }
                if let v = webView {
                    let root = rootViewController
                    v.frame = root.view.bounds
                    root.view.addSubview(v)
                    observer = v.observe(\.url, options: [.initial, .new]) { (_, changes) in
                        debug("URL Change: \(String(describing: changes.newValue))")
                    }
                }
            }
        }
    }
    var webViewDelegate = WKWebViewDelegate() // swiftlint:disable:this weak_delegate
    var isProtocolRegisterd = false
    var disposeBag: DisposeBag!
    var rootViewController: UIViewController {
        return UIApplication.shared.delegate!.window!!.rootViewController!
    }

    override class func setUp() {
        super.setUp()
        _ = HttpServer.testServer
        _ = rustClient
        // iOS 看起来cookie同步串数据好了，不需要单例进程池来同步数据了
        if #available(iOS 14.5, *) {
        } else {
            makeWKProcessPoolSingleton()
        }
    }
    override class func tearDown() {
        super.tearDown()
    }

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()

        // Put setup code here. This method is called before the invocation of each test method in the class.
        webView = makeWebView()
    }

    override func tearDown() {
        disposeBag = nil
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        webView = nil
        super.tearDown()
    }

    func makeWebView() -> WKWebView {
        let webView = WKWebView(frame: CGRect.zero, configuration: makeWKConfiguration())
        webView.navigationDelegate = webViewDelegate
        return webView
    }

    func makeWKConfiguration() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        // lazy init store before init process, so data like cookie can be synced
        _ = configuration.websiteDataStore
        WKHTTPHandler.shared.enable(in: configuration)
        isProtocolRegisterd = true
        configuration.applicationNameForUserAgent = "Test WKWebView"
        configuration.userContentController.add(webViewDelegate, name: "rpc")
        configuration.userContentController.addUserScript(WKUserScript(source: """
            /* eslint no-console:"off" */
            console.log("load iOS RPC")

            window.rpc = function (method, arg) {
                window.webkit.messageHandlers.rpc.postMessage({
                    api: method,
                    arg: arg
                })
            }
            function getURL(url, complete) {
                requestURL(url, "GET", null, complete)
            }

            /** wrap of oneshot XMLHttpRequest */
            function requestURL(url, method, body, complete) {
                var req = new XMLHttpRequest()
                req.addEventListener("error", function (e) {
                    this.responseError = e
                })
                req.addEventListener("loadend", complete)
                req.open(method, url)
                req.send(body)
            }
            """, injectionTime: .atDocumentStart, forMainFrameOnly: false))

        webViewDelegate.onReceiveMessage.subscribe(onNext: {
            guard
                let body = $0.body as? NSDictionary,
                let api = body["api"] as? String,
                let fn = self.jsFunctions[api]
            else { return }
            fn(body["arg"])
        }).disposed(by: disposeBag)
        return configuration
    }

    // MARK: js interact

    typealias JSRPCFunction = (Any?) -> Void
    var jsFunctions: [String: JSRPCFunction] = [:]
    /// return a js function literal object. closure can only be called once. and will release when called
    private var anonymousJSFunctionCount = 0
    /// return anonymous closure as jsfunction, and return a generated name
    func registerJSFunction(_ closure: @escaping JSRPCFunction) -> String {
        anonymousJSFunctionCount &+= 1
        let name = "__\(anonymousJSFunctionCount)"
        jsFunctions[name] = closure
        return name
    }

    func toJSFunctionOnce(_ closure: @escaping JSRPCFunction) -> String {
        var name: String!
        name = registerJSFunction { [unowned self] in
            self.jsFunctions[name] = nil
            closure($0)
        }
        return "(function(arg) { rpc('\(name!)', arg) })"
    }

    // MARK: Helper

    func waitTasks() {
        runUntil(condition: tasks.load() == 0)
    }
    func wait(completable: Completable) {
        completable
            .timeout(defaultTimeout + 10, other: .error(TestError.timeout("unknown")), scheduler: MainScheduler.instance) // swiftlint:disable:this line_length
            .do(onSubscribed: { self.tasks.add(1) }, onDispose: { self.tasks.sub(1) })
            .subscribe(onError: { XCTFail("test shouldn't fail. error: \($0)") })
            .disposed(by: disposeBag)

        waitTasks()
    }
    func evaluateJavaScript<T>(_ js: String) -> Single<T> {
        return Single.create { single in
            self.webView.evaluateJavaScript(js) { result, error in
                if let error = error {
                    single(SingleEvent.error(error))
                } else if let result = result as? T {
                    single(SingleEvent.success(result))
                } else {
                    single(.error(TestError.cast))
                }
            }
            return Disposables.create()
        }.do(onSubscribed: { self.tasks.add(1) },
             onDispose: { self.tasks.sub(1) })
    }

    /// evaluateJavaScript, use `callback` predefine var to indicate finish. param of callback will pass to Single
    func evaluateAsyncJavaScript<T>(_ js: String, timeout: TimeInterval? = nil) -> Single<T> {
        var result: Single<T> = Single.create { single in
            let callbackName = self.registerJSFunction {
                if let result = $0 as? T {
                    single(SingleEvent.success(result))
                } else {
                    single(SingleEvent.error(TestError.cast))
                }
            }
            let js = """
            (function() {
                var callback = function(arg) { rpc('\(callbackName)', arg) };
                \(js)
            })();
            """
            debug(js)
            self.webView.evaluateJavaScript(js)
            return Disposables.create {
                self.jsFunctions[callbackName] = nil
            }
        }.do(onSubscribed: { self.tasks.add(1) },
             onDispose: { self.tasks.sub(1) })
        let timeout = timeout ?? defaultTimeout
        if timeout > 0 {
            result = result.timeout(timeout, other: .error(TestError.timeout(js)),
                                    scheduler: MainScheduler.instance)
        }
        return result
    }

    func navigation(action: @escaping () -> Void) -> Completable {
        return Completable.create {
            defer { action() } // 先sub再执行跳转action
            self.tasks.add(1)
            return self.webViewDelegate.onMainFrameFinish
                .do(onDispose: { self.tasks.sub(1) })
                .subscribe($0)
        }
    }

    func loadRootPage() -> Completable {
        let req = URLRequest(url: HttpServer.makeURL(relativeString: "/web/page/index.html"))
        return navigation { self.webView.load(req) }
    }

    func navigation(id: String) -> Single<String> {
        return self.navigation { self.webView.evaluateJavaScript("document.getElementById('\(id)').click()") }
            .andThen(self.evaluateJavaScript("document.body.textContent"))
    }
    func navigationBack() -> Completable {
        return self.navigation { self.webView.goBack() }
    }

    func clearWebCache() -> Completable {
        return Completable.create { complete in
            URLCache.shared.removeAllCachedResponses() // 拦截会用系统共享的Cache，也一并清除
            HTTPCookieStorage.shared.removeCookies(since: Date.distantPast) // 系统共享的Cookie也一并清除
            let store = self.webView.configuration.websiteDataStore
            store.removeData(
                ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                modifiedSince: Date.distantPast,
                completionHandler: {
                    debug("clearWebCache")
                    complete(.completed)
                })
            return Disposables.create()
        }
    }

    // MARK: - Test Case
    /// 调试代码，在通用网页上跑跑对比看效果
    func atestRunInWeb() {
        let url = URL(string: "http://127.0.0.1/~wang/testLark.php")!
        _ = clearWebCache()
            .andThen(navigation { self.webView.load(URLRequest(url: url)) })
            .subscribe()

        runUntil(condition: false)
    }

    func testGoogleDocsBugs() {
        // https://forms.gle/57qTuTtq6xPKyr7a8
        // 这个页面加载会terminate process后卡死，无拦截能正常加载
        // 而且初始化加载和reload加载能成功，但是重定向加载则不行。
        // 这个页面会重定向到google的一个页面，有同样的问题，所以最终一定会失败。

        var url = URLComponents(url: HttpServer.makeURL(relativeString: "/web/page/googleDocsBugs.html"),
                                resolvingAgainstBaseURL: false)!
        url.host = "127.0.0.1" // need different to trigger bugs

        // let url = URL(string: "https://forms.gle/57qTuTtq6xPKyr7a8")!
        wait(completable: loadRootPage().andThen(
            navigation { self.webView.evaluateJavaScript( "window.location = '\(url.url!.absoluteString)'" ) }
        ))
    }

    func testPostForm() {
        // iOS11不一定支持body
        // https://github.com/WebKit/webkit/commit/0855276275eb1d29615dfb24f288697a238a96b1
        // 1 Dec 2017, 才提交WKURLSchemeHandler支持HttpBody的补丁... 具体哪个版本开始支持的还得再查查.

        // https://zh.wikipedia.org/wiki/IOS_11#iOS_11.1
        // 从上表看出至少iOS11.2后才可能打上上面HttpBody的补丁...
        wait(completable: loadRootPage().andThen(navigation(id: "post_direct"))
            .do( // post form should receive body
                onSuccess: { XCTAssertEqual($0, "btn=direct") }
            ).asCompletable())
    }

    func testPostRedirectForm() {
        wait(completable: loadRootPage().andThen(navigation(id: "post_redirect"))
            .do( // 307 redirect should receive body
                onSuccess: { XCTAssertEqual($0, "btn=redirect%2F307") }
            ).asCompletable())
    }

    func testRedirectToCustomScheme() {
        var lastScheme: String?
        webViewDelegate.delegateHandler = {
            switch $1 {
            case .request(action: let action, handler: let handler):
                guard let scheme = action.request.url?.scheme?.lowercased() else { return false }
                lastScheme = scheme
                switch scheme {
                case "app-settings":
                    handler(.cancel)
                    return true
                default: break
                }
            default: break
            }
            return false
        }

        wait(completable: loadRootPage()
            .andThen(navigation(id: "app_settings").asCompletable()
                .do(onCompleted: { XCTFail("redirect to app-settings will be canceled and throw error") })
                .catchError {
                    XCTAssertEqual(lastScheme, "app-settings"); lastScheme = nil
                    XCTAssertEqual( $0.localizedDescription, "Frame load interrupted" )
                    return .empty()
                })
            .andThen(self.navigation { self.webView.evaluateJavaScript("window.location = '../redirect2Unknown'" ) }
                .do(onCompleted: { XCTFail("redirect to unknown scheme should throw error") })
                .catchError {_ in
                    XCTAssertEqual(lastScheme, "unknown"); lastScheme = nil
                    // WK report redirect scheme error, but if request directly, report unsupport error.
                    // current implement only report unsupport error
                    return .empty()
                })
            )
    }

    func testAJAX() {
        let getShouldWork = evaluateAsyncJavaScript(
            "getURL('raw.html', function() { callback(this.responseText) })"
            ).do(onSuccess: { (result: String) in
                XCTAssertEqual(result.trimmingCharacters(in: .whitespacesAndNewlines), "hello, tester!")
            }).asCompletable()

        let headShouldntReceiveBody = evaluateAsyncJavaScript(
            "requestURL('raw.html', 'HEAD', null, function() { callback(Boolean(this.responseText)) })"
            ).do(onSuccess: { (result: Bool) in
                XCTAssertFalse(result) // header request shouldn't have body
            }).asCompletable()

        let variousPostShouldPassBodyEvenRedirect = ["post", "PUT", "DELETE", "PATCH"].flatMap({ method in
            // lowercase method also work
            [evaluateAsyncJavaScript(
                "requestURL('../post', '\(method)', '\(method)', function() { callback(this.responseText) })"
                ).do(onSuccess: { (result: String) in
                    XCTAssertEqual(result, method)
                }).asCompletable(),
             evaluateAsyncJavaScript( // redirect should keep body
                // swiftlint:disable:next line_length
                "requestURL('../redirect/307/post', '\(method)', '\(method)', function() { callback(this.responseText) })"
                ).do(onSuccess: { (result: String) in
                    XCTAssertEqual(result, method)
                }).asCompletable()]
        })

        wait(completable: loadRootPage()
            .andThen(Completable.merge([
                // methods and redirect should works
                getShouldWork,
                headShouldntReceiveBody
                ] + variousPostShouldPassBodyEvenRedirect
            )))
    }

    func testIFrame() {
        let requestInIframeShouldWork = Completable.create { complete in
            // can call iframe function from iframe.contentWindow, but still execute in mainframe's context
            // so simulate click in iframe and callback in iframe functions
            self.jsFunctions["HELLO_AJAX"] = {
                guard
                    let responseText = ($0 as? String),
                    let responseJSON = try? JSONDecoder().decode([String: String].self,
                                                                 from: responseText.data(using: .utf8)!)
                else {
                    complete(.error(TestError.fail("AJAX fail to get iframe request response")))
                    return
                }
                // iframe request can be captured correctly, Referer should be the request page url
                let refer = responseJSON
                .first { $0.key.caseInsensitiveCompare("Referer") == .orderedSame }?.value
                XCTAssertTrue(refer?.hasSuffix("hello.html") == true)
                complete(.completed)
            }
            // swiftlint:disable:next line_length
            self.webView.evaluateJavaScript("document.getElementById('hello').contentWindow.document.getElementById('AJAX').click()")
            return Disposables.create { self.jsFunctions["HELLO_AJAX"] = nil }
        }.timeout(defaultTimeout, other: .error(TestError.timeout("HELLO_AJAX")),
                  scheduler: MainScheduler.instance)

        wait(completable: loadRootPage()
            .andThen( requestInIframeShouldWork ))
    }

    func testCache() {
        let clickAndBack = { id in
            return self.navigation(id: id)
                .flatMap {
                    self.navigationBack()
                        .andThen(Single.just($0))
                }
        }

        wait(completable: loadRootPage().andThen(clearWebCache()).andThen(Completable.concat([
            // AJAX请求能被缓存
            self.evaluateAsyncJavaScript("getURL('../../cache/count', function() { callback(this.responseText) })")
                .flatMapCompletable { count in
                    self.evaluateAsyncJavaScript(
                        "getURL('../../cache/count', function() { callback(this.responseText) })"
                        ).do(onSuccess: { (v: String) in
                            XCTAssertEqual(Int(v), Int(count), "should use the same cache count")
                        }).asCompletable()
                },
            // 点击链接能被缓存
            clickAndBack("cache_count").map { v -> Int in
                    if let count = Int(v) { return count }
                    throw TestError.cast
                }.flatMapCompletable { count in
                    clickAndBack("cache_count").do(onSuccess: {
                        XCTAssertEqual(Int($0), count, "should use the same cache count")
                    }).asCompletable()
                    // window location也能复用缓存
                    .andThen(self.navigation { self.webView.evaluateJavaScript("window.location ='../../cache/count'") }
                             .andThen(self.evaluateJavaScript("document.body.textContent"))
                             .flatMapCompletable { (v: String) in
                                 XCTAssertEqual(Int(v), Int(count), "should use the same cache count")
                                 return self.navigationBack()
                             }
                    )
                    // 原生实现: AJAX能复用<a>跳转的缓存, <a>不能复用AJAX的缓存
                    // 拦截后: 跳转后AJAX的系统缓存就失效了? 而且不同路径引用的同一文件也没缓存...
                    // 最后实现和URLCache共用缓存
                    .andThen(self.evaluateAsyncJavaScript(
                            "getURL('../../cache/count', function() { callback(this.responseText) })"
                            ).do(onSuccess: { (v: String) in
                                XCTAssertEqual(Int(v), Int(count), "should use the same cache count")
                            }).asCompletable())
                }
        ])))
    }

    // swiftlint:disable:next function_body_length
    func testAuth() {
        // init, navigation, ajax auth
        // success, fail, loop fail

        let loginURL = HttpServer.makeURL(relativeString: "/auth/login")
        var challengeHandle: ((URLAuthenticationChallenge, (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) -> Void)? // swiftlint:disable:this line_length
        webViewDelegate.delegateHandler = {
            switch $1 {
            case .challenge(let v):
                if let handle = challengeHandle {
                    handle(v.challenge, v.handler)
                    return true
                }
            default: break
            }
            return false
        }

        // default will fail auth and return no user
        let loadAndGetFailPage = Completable.concat([
            navigation {
                    self.webView.load(URLRequest(url: loginURL))
                }.andThen(self.evaluateJavaScript("document.body.textContent")
                    .do(onSuccess: { XCTAssertEqual($0, "no user") })
                    .asCompletable()
                ),
            self.evaluateAsyncJavaScript("getURL('\(loginURL.path)', function() { callback(this.responseText) })")
                .do(onSuccess: { XCTAssertEqual($0, "no user") })
                .asCompletable()
        ])

        // avoid URLProtocolTests inteference
        URLCredentialStorage.shared.removeAll()
        AuthenticateCredentialStorage.shared.clearAllCache()

        // begin run
        wait(completable: loadAndGetFailPage)

        // fail auth will re challenge and final return no user
        challengeHandle = { challenge, handle in
            guard challenge.previousFailureCount == 0 else {
                // this should enter. see coverage execute count to confirm
                handle(.performDefaultHandling, nil)
                return
            }
            handle(.useCredential, URLCredential(user: "byte", password: "wrong", persistence: .forSession))
        }
        wait(completable: loadAndGetFailPage)

        // cancel auth will cause error
        challengeHandle = { $1(.cancelAuthenticationChallenge, nil) }
        wait(completable: Completable.concat([
            // main navigation will report cancel error
            navigation {
                    self.webView.load(URLRequest(url: loginURL))
                }.do(onCompleted: { XCTFail("should cancel") })
                .catchError {
                    XCTAssertEqual(($0 as? URLError)?.code, URLError.cancelled)
                    return .empty()
                },
            // AJAX request will response error
            self.evaluateAsyncJavaScript("getURL('\(loginURL.path)', function() { callback(Boolean(this.responseError)) })") // swiftlint:disable:this line_length
                .do(onSuccess: { XCTAssertEqual($0, true) })
                .asCompletable()
        ]))

        // correct auth get auth page
        challengeHandle = { $1(.useCredential, URLCredential(user: "byte", password: "dance", persistence: .none)) }
        wait(completable: Completable.concat([
            navigation {
                    self.webView.load(URLRequest(url: loginURL))
                }.andThen(self.evaluateJavaScript("document.body.textContent")
                    .do(onSuccess: { XCTAssertEqual($0, "byte:dance") })
                    .asCompletable()
                ),
            self.evaluateAsyncJavaScript("getURL('\(loginURL.path)', function() { callback(this.responseText) })")
                .do(onSuccess: { XCTAssertEqual($0, "byte:dance") })
                .asCompletable()
        ]))
    }
}
#endif
