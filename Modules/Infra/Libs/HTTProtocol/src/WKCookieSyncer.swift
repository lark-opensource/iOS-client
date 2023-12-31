//
//  WKCookieSyncer.swift
//  HTTProtocol
//
//  Created by SolaWing on 2021/5/1.
//

#if ENABLE_WKWebView
import UIKit
import Foundation
import WebKit
import EEAtomic

/// 负责原生cookie到WKWebView的完全同步。（不负责WKWebView http请求到原生的cookie, 主要是给HTTP导流共用原生cookie使用）
/// 应该调用以下两个方法完成cookie的完全同步
///   public func patchJSCookieSetterForSync(in controller: WKUserContentController) {
///   public func syncNativeCookie(to: WKWebView) {
@available(iOS 11.0, *)
public final class WKCookieSyncer: NSObject, WKScriptMessageHandler {
    public static let shared = WKCookieSyncer() // swiftlint:disable:this all

    private var observeCookieChanged = false {
        didSet {
            if observeCookieChanged != oldValue {
                assert(Thread.isMainThread, "should occur on main thread!")
                if observeCookieChanged {
                    NotificationCenter.default.addObserver(
                        self, selector: #selector(_NSHTTPCookieManagerCookiesChanged(notification:)),
                        name: .NSHTTPCookieManagerCookiesChanged,
                        object: HTTPCookieStorage.shared)
                } else {
                    NotificationCenter.default.removeObserver(
                        self, name: .NSHTTPCookieManagerCookiesChanged, object: nil)
                }
            }
        }
    }
    private let webViews = NSHashTable<WKWebView>.weakObjects()

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Sync Native Cookie To WKWebView

    /// 自动同步nativeCookie变化到WebView
    public func syncNativeCookie(to: WKWebView) {
        webViews.add(to)
        observeCookieChanged = true

        let observer = to.observe(\.url, options: [.initial, .new]) { (webView, changes) in
            guard case let url?? = changes.newValue else { return }
            // 主frame首次加载，需要同步历史的
            Self.sync(to: webView, url: url)
        }
        /// https://developer.apple.com/library/archive/releasenotes/Foundation/RN-Foundation/index.html
        /// Relaxed Key-Value Observing Unregistration Requirements
        /// iOS 11 already relaxed Key-Value Observing for autonotify KVO (manual KVO exclude, eg: CoreData)
        objc_setAssociatedObject(to, UnsafeRawPointer(Unmanaged.passUnretained(self.webViews).toOpaque()),
                                 observer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    let throttle = Throttle()
    @objc
    func _NSHTTPCookieManagerCookiesChanged(notification: NSNotification) {
        // debug("cookie changed onMain? \(Thread.isMainThread) \(notification)")
        throttle.run(action: { [self] in
            if webViews.count == 0 { // swiftlint:disable:this all
                observeCookieChanged = false
                return
            }
            // debug("cookie changed in main")
            for webView in webViews.allObjects {
                guard let url = webView.url else { continue }
                // NOTE: notification只给了变化通知, 但没有具体变化的内容，所以不能做增量更新..
                // 而大量调用setCookie会导致堆积, 同步不上，所以需要自己做增量同步
                Self.sync(to: webView, url: url)
            }
        }, on: DispatchQueue.main, interval: 0.1)
    }
    /// 同步对应URL的Cookie到webView上
    static public func sync(to webView: WKWebView, url: URL) {
        // 同步分两种：全量和增量，按URL划分
        // 全量是首次URL加载时，增量是后续变更时
        // 需要考虑同步时效, 越及时越好(debounce之类的限频延迟会降低时效)
        // 目前测试看cookieChange的Notification调用很频繁
        // 而根据URL全量同步的，目前测试观察到会有通道堆积, 同步不即时的问题
        // 增量的话，还需要考虑删除后重新同步的情况(没有实时同步的话，之前同步过的, 删除后重加可能会漏掉)
        //   而HTTPCookieStorage没有提供是否有删除，获取全量cookie进行对比，担心有量变导致的性能和内存问题
        // 增量另外还要考虑内存占用和增量缓存清理的策略. 而URL没有生命周期的概念，可能只能按使用频次来清理..

        // NOTE: 暂时的结论
        // 主要使用和当前WebView相同的URL缓存，来实现增量。
        // 这样如果是删除，也可以通过通知绑定对应webView的URL，即时的删除和重加(避免全量cookie对比删除的性能问题)
        // FIXME: 但非关联到webView的URL，因为没有更新通知，所以不能即时的删除，重加cookie的场景可能会有部分旧cookie不同步..
        // 但因为清理机制，和删除发生少，所以不大可能成为问题
        // 而和WebView关联的URL缓存，通过限制URL数量和过期时间，内存占用也可控，且清理时机绑定webView生命周期

        assert(Thread.isMainThread, "should occur on main thread!")
        let cookieSyncInfo = webView.cookieSyncInfo
        let identifier = cookieIdentifier(for: url)
        guard var cookies = HTTPCookieStorage.shared.cookies(for: url), !cookies.isEmpty else {
            debug("no cookie for \(url) in \(webView)")
            cookieSyncInfo.cookiesByIdentifier.removeValue(forKey: identifier)
            return
        }
        let cookiesSet = Set(cookies)
        defer {
            cookieSyncInfo.cookiesByIdentifier[identifier] = .init(
                identifier: identifier, access: Date(), cookies: cookiesSet)
        }

        if let info = cookieSyncInfo.cookiesByIdentifier[identifier] {
            cookies.removeAll(where: info.cookies.contains(_:))
            if cookies.isEmpty {
                debug("no need sync cookie[\(cookiesSet.count)] for \(url) to \(webView)")
                return
            }
        }

        debug("sync cookie[\(cookies.count)] \(url) to \(webView)")
        let storage = webView.configuration.websiteDataStore.httpCookieStore
        for v in cookies {
            storage.setCookie(v)
        }
    }

    // MARK: Helper
    // https://tools.ietf.org/html/rfc6265#section-5.1.4
    // 计算使用相同的cookie的唯一标识, 去掉query和fragment的干扰
    // cookie path和url path相等也会匹配.., 可以给唯一页面设置cookie. 所以path不能压缩(虽然默认情况下是同目录的)
    static func cookieIdentifier(for url: URL) -> String {
        guard var components = url.canonicalURLComponents(allowNonHTTP: true) else { return url.absoluteString }
        components.percentEncodedQuery = nil
        components.percentEncodedFragment = nil

        return components.string ?? url.absoluteString
    }

    // MARK: - WKScriptMessageHandler: Sync Cookie From JS to native
    /// https://stackoverflow.com/questions/30685203/retrieving-document-cookie-getter-and-setter
    /// patch document.cookie.set, to notify cookie changes by js
    ///
    /// - Parameters:
    ///   - afterSetFn: should be a js function object, will be called once when cookie is setted
    /// - Returns: generate patch code for execute
    public static func patchJSCookieSetter(afterSetFn: String) -> String {
        return """
        ;(function () {
            var cookieProp = getPropertyDescriptorRecursive(Object.getPrototypeOf(document), "cookie")
            Object.defineProperty(document, "cookie", {
                get: function () {
                    return cookieProp.get.call(this);
                },
                set: function (v) {
                    cookieProp.set.call(this, v);
                    (\(afterSetFn)).call(this, v);
                },
                enumerable: true,
                configurable: true
            });
            Object.defineProperty(document, "origin_cookie", cookieProp);

            function getPropertyDescriptorRecursive(o, name) {
                var desc;
                do {
                    desc = Object.getOwnPropertyDescriptor(o, name);
                    o = Object.getPrototypeOf(o);
                } while (desc === undefined && o !== null);
                return desc;
            }
        })();
        """
    }

    /// set cookie to shared HTTPCookieStorage from WKWebView js setter
    ///
    /// - Parameters:
    ///   - cookie: js cookie assign value
    ///   - documentURL: frame URL of js environment
    public static func syncCookiesFromJS(_ cookie: String, documentURL: URL) {
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: ["Set-Cookie": cookie], for: documentURL)
        if cookies.isEmpty { return }
        HTTPCookieStorage.shared.setCookies(cookies, for: documentURL, mainDocumentURL: documentURL)
    }

    /// this function will inject patch script to sync js cookie assign to system cookie storage
    ///
    /// - Parameters:
    ///   - controller: controller which add the patch script
    public func patchJSCookieSetterForSync(in controller: WKUserContentController) {
        controller.add(self, name: "_didSetCookie")
        controller.addUserScript(WKUserScript(
            source: Self.patchJSCookieSetter(afterSetFn: "function(v) { window.webkit.messageHandlers._didSetCookie.postMessage([v, this.documentURI]) }"), // swiftlint:disable:this line_length
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false))
    }
    // swiftlint:disable:next line_length
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        assert(message.name == "_didSetCookie")
        guard let arg = message.body as? [String], arg.count > 1 else {
            assertionFailure("inner implementation shouldn't pass wrong type")
            return
        }
        guard let url = URL(string: arg[1]) else {
            debug("invalid url in arg: \(arg)")
            return
        }
        Self.syncCookiesFromJS(arg[0], documentURL: url)
    }
}

extension WKWebView {
    final class CookieSyncInfo {
        struct Cookies {
            let identifier: String
            let access: Date
            var cookies: Set<HTTPCookie>
        }
        var cookiesByIdentifier: [String: Cookies] = [:]
        static var key: Bool = false
        init() {
            NotificationCenter.default.addObserver(
                self, selector: #selector(didReceiveMemoryWarningNotification),
                name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        }
        @objc
        func didReceiveMemoryWarningNotification() {
            ensureRunOnMain { [self] in
                let now = Date()
                let expirdTime: TimeInterval = 60
                cookiesByIdentifier = cookiesByIdentifier.filter { ( element ) -> Bool in
                    return now.timeIntervalSince(element.value.access) > expirdTime
                }
            }
        }
    }
    var cookieSyncInfo: CookieSyncInfo {
        if let v = objc_getAssociatedObject(self, &CookieSyncInfo.key) as? CookieSyncInfo { return v }
        let v = CookieSyncInfo()
        objc_setAssociatedObject(self, &CookieSyncInfo.key, v, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return v
    }
}

/// a helper to ensure run action with min interval. latest action always run
final class Throttle {
    var lock = UnfairLockCell()
    private var latestDate = Date.distantPast
    private var latestAction: (() -> Void)?
    deinit {
        lock.deallocate()
    }
    func run(action: @escaping () -> Void, on queue: DispatchQueue, interval: TimeInterval) {
        lock.lock(); defer { lock.unlock() }
        if latestAction != nil {
            // 有队列中等待的任务，直接更新action
            // 如果queue一直被占用，那么after和run将得不到调度. 实际间隔时间大于interval
            // debug("Throttle update action")
            latestAction = action
        } else { // 没有等待队列，根据时间判断下一次schedule时间
            latestAction = action
            let elapsed = -latestDate.timeIntervalSinceNow
            if elapsed < interval {
                let interval = min(interval - elapsed, interval)
                // debug("Throttle after \(interval)")
                queue.asyncAfter(deadline: DispatchTime.now() + interval, execute: deque)
            } else { // 超出时间，直接schedule
                // debug("Throttle async")
                queue.async(execute: deque)
            }
        }
    }
    func deque() {
        lock.lock()
        let action = latestAction
        latestAction = nil
        latestDate = Date()
        lock.unlock()
        action?()
    }
}

func ensureRunOnMain(action: @escaping () -> Void) {
    if Thread.isMainThread {
        action()
    } else {
        DispatchQueue.main.async(execute: action)
    }
}
#endif
