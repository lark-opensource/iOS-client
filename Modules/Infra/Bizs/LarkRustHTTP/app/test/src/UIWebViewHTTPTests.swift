//
//  UIWebViewHTTPTests.swift
//  LarkRustClientTests
//
//  Created by SolaWing on 2019/1/10.
//  Copyright © 2019年 Bytedance. All rights reserved.
//

#if ENABLE_UI_WEB_VIEW
import UIKit
import Foundation
import XCTest
import RxSwift
//import RxAtomic
@testable import LarkRustClient
@testable import LarkRustHTTP
import JavaScriptCore
import Swifter

private let defaultTimeout: TimeInterval = 10

/// 该测试只是一个简单跑UIWebView的环境，因为有WKHTTPTests和URLTests，功能应该都能正常使用
class UIWebViewHTTPTests: XCTestCase {
    enum TestError: Error {
        case fail(String)
        case timeout(String)
        case cast
    }

    var tasks = AtomicInt(0) // async running task counter
    var webView: UIWebView!
    var webViewDelegate = UIWebDelegate() // swiftlint:disable:this weak_delegate
    var isProtocolRegisterd = false
    var disposeBag: DisposeBag!
    var rootViewController: UIViewController {
        return UIApplication.shared.delegate!.window!!.rootViewController!
    }

    override class func setUp() {
        super.setUp()
        _ = HttpServer.testServer
        _ = rustClient
    }
    override class func tearDown() {
        super.tearDown()
    }

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()

        URLProtocol.registerClass(WebViewHttpProtocol.self)
        isProtocolRegisterd = true

        // Put setup code here. This method is called before the invocation of each test method in the class.
        webView = UIWebView(frame: CGRect.zero)
        webView.delegate = webViewDelegate
        webViewDelegate.injectInitJs = """
            console.log("load iOS RPC")

            function getURL(url, complete) {
                requestURL(url, "GET", null, complete)
            }

            /** wrap of oneshot XMLHttpRequest */
            function requestURL(url, method, body, complete) {
                var req = new XMLHttpRequest()
                // req.addEventListener("progress", console.log)
                // req.addEventListener("abort", console.log)
                req.addEventListener("error", function (e) {
                    this.responseError = e
                })
                // req.addEventListener("abort", console.log)
                req.addEventListener("loadend", complete)
                req.open(method, url)
                req.send(body)
                // window.req = req
            }
        """

        let root = rootViewController
        webView.frame = root.view.bounds
        root.view.addSubview(webView)
    }

    override func tearDown() {
        disposeBag = nil
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        webView.removeFromSuperview()
        webView.stopLoading()
        webView.delegate = nil
        if isProtocolRegisterd {
            URLProtocol.unregisterClass(WebViewHttpProtocol.self)
            isProtocolRegisterd = false
        }
        super.tearDown()
    }

    // MARK: js interact

    typealias JSRPCFunction = UIWebDelegate.JSRPCFunction
    /// return a js function literal object. closure can only be called once. and will release when called
    private var anonymousJSFunctionCount = 0
    /// return anonymous closure as jsfunction, and return a generated name
    func registerJSFunction(_ closure: @escaping JSRPCFunction) -> (String, Disposable) {
        anonymousJSFunctionCount &+= 1
        let name = "__\(anonymousJSFunctionCount)"
        webViewDelegate.jsFunctions[name] = closure
        return (name, Disposables.create { self.webViewDelegate.jsFunctions[name] = nil })
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

    func evaluateJavaScript(_ js: String) {
        debug("evaluateJavaScript: \(js)")
        self.webView.stringByEvaluatingJavaScript(from: js)
    }
    func evaluateJavaScript<T>(_ js: String) -> Single<T> {
        return Single.create { single in
            debug("evaluateJavaScript: \(js)")
            let result = self.webView.stringByEvaluatingJavaScript(from: js)
            if let result = result as? T {
                single(SingleEvent.success(result))
            } else {
                single(.error(TestError.cast))
            }
            return Disposables.create()
        }.do(onSubscribed: { self.tasks.add(1) },
             onDispose: { self.tasks.sub(1) })
    }
    /// evaluateJavaScript, use `callback` predefine var to indicate finish. param of callback will pass to Single
    func evaluateAsyncJavaScript<T>(_ js: String, timeout: TimeInterval? = nil) -> Single<T> {
        var result: Single<T> = Single.create { single in
            let (callbackName, disposable) = self.registerJSFunction {
                if let result = $0 as? T {
                    single(SingleEvent.success(result))
                } else {
                    single(SingleEvent.error(TestError.cast))
                }
            }
            debug("evaluateAsyncJavaScript: \(js)")
            let js = """
            (function() {
                var callback = function(arg) { rpc('\(callbackName)', arg) };
                \(js)
            })();
            """
            self.webView.stringByEvaluatingJavaScript(from: js)
            return disposable
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
        return navigation { self.webView.loadRequest(req) }
    }

    func navigation(id: String) -> Single<String> {
        return self.navigation {
                self.webView.stringByEvaluatingJavaScript(from: "document.getElementById('\(id)').click()")
            }.andThen(self.evaluateJavaScript("document.body.textContent"))
    }
    func navigationBack() -> Completable {
        return self.navigation { self.webView.goBack() }
    }
    func clearWebCache() -> Completable {
        return Completable.create { complete in
            URLCache.shared.removeAllCachedResponses() // 拦截会用系统共享的Cache，也一并清除
            HTTPCookieStorage.shared.removeCookies(since: Date.distantPast) // 系统共享的Cookie也一并清除
            complete(.completed)
            return Disposables.create()
        }
    }

    // MARK: Test Case

    func testPostForm() {
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
                }).asCompletable()
            ]
        })

        wait(completable: loadRootPage()
            .andThen(Completable.merge([
                // methods and redirect should works
                getShouldWork,
                headShouldntReceiveBody
                ] + variousPostShouldPassBodyEvenRedirect
            )))
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
            // 点击链接能被缓存
            clickAndBack("cache_count").map { v -> Int in
                    if let count = Int(v) { return count }
                    throw TestError.cast
                }.flatMapCompletable { (count: Int) in
                    clickAndBack("cache_count").do(onSuccess: {
                        XCTAssertEqual(Int($0), count, "should use the same cache count")
                    }).asCompletable()
                    // window location也能复用缓存
                    .andThen(self.navigation { self.evaluateJavaScript("window.location ='../../cache/count'") }
                             .andThen(self.evaluateJavaScript("document.body.textContent"))
                             .flatMapCompletable { (v: String) in
                                 XCTAssertEqual(Int(v), Int(count), "should use the same cache count")
                                 return self.navigationBack()
                             }
                    )
                    // UIWebView原生实现就不能复用缓存
                    // .andThen(self.evaluateAsyncJavaScript(
                    //         "getURL('../../cache/count', function() { callback(this.responseText) })"
                    //         ).do(onSuccess: { (v: String) in
                    //             XCTAssertEqual(Int(v), Int(count), "should use the same cache count")
                    //         }).asCompletable())
                },
            // AJAX请求能被缓存
            // NOTE: iOS10上，如果先请求AJAX, 然后跟着clickAndBack, 会被frame load interrupted.
            // 因为和不导流效果一样，就不处理了。
            self.evaluateAsyncJavaScript("getURL('../../cache/count', function() { callback(this.responseText) })")
                .flatMapCompletable { count in
                    self.evaluateAsyncJavaScript(
                        "getURL('../../cache/count', function() { callback(this.responseText) })"
                        ).do(onSuccess: { (v: String) in
                            XCTAssertEqual(Int(v), Int(count), "should use the same cache count")
                        }).asCompletable()
                }
        ])))
    }
}

class UIWebDelegate: NSObject, UIWebViewDelegate {
    enum Notification {
        case start
        case finish(error: Error?)
    }
    var loadingFrame = 0
    var injectInitJs: String?
    typealias JSRPCFunction = (Any?) -> Void
    var jsFunctions: [String: JSRPCFunction] = [:]

    let onEvent = PublishSubject<(UIWebDelegate, Notification)>()
    func notify(_ notification: Notification) {
        syncOnMain {
            debug(reflect(notification)) // track log
            self.onEvent.onNext((self, notification))
        }
    }
    var onMainFrameFinish: Completable {
        return Completable.create { complete in
            self.onEvent.subscribe {
                guard self.loadingFrame == 1 else { return }
                switch $0 {
                case let .next(_, .finish(error)):
                    if let error = error {
                        complete( .error(error) )
                    } else {
                        complete( .completed )
                    }
                default: break // ignore other event, 也不会发送非next的消息
                }
            }
        }
    }
    // MARK: UIWebViewDelegate
    func webViewDidStartLoad(_ webView: UIWebView) {
        loadingFrame += 1
        notify(.start)
    }
    func webViewDidFinishLoad(_ webView: UIWebView) {
        if loadingFrame == 1 {
            let context = webView.value(forKeyPath: "documentView.webView.mainFrame.javaScriptContext") as! JSContext // swiftlint:disable:this all
            let rpc: @convention(block) (String, Any?) -> Void = {[weak self] method, arg in
                DispatchQueue.main.async {
                    if let function = self?.jsFunctions[method] {
                        function(arg)
                    }
                }
            }
            context.setObject(rpc, forKeyedSubscript: "rpc" as NSString)

            if let js = injectInitJs {
                webView.stringByEvaluatingJavaScript(from: js)
            }
        }
        notify(.finish(error: nil))
        loadingFrame -= 1
    }
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        notify(.finish(error: error))
        loadingFrame -= 1
    }
}

private func syncOnMain(action: () -> Void) {
    if Thread.isMainThread {
        action()
    } else {
        DispatchQueue.main.sync { action() }
    }
}
#endif
