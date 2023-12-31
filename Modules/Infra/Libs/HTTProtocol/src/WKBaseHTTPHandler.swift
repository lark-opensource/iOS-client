//
//  WKBaseHTTPHandler.swift
//  LarkRustClient
//
//  Created by SolaWing on 2018/12/28.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import Foundation
import WebKit
import EEAtomic

// 该功能没有实际上线使用，目前已经没有维护。通过条件编译避免误用。
// 后续如果有导流需求，可以充分完善测试重新上线。
#if ENABLE_WKWebView

/// 使WKWebView可以拦截HTTP和HTTPS，需要指定拦截使用的URLProtocol.
/// 推荐子类配置上相应的依赖，然后复用单例.
/// 子类需要覆盖HTTPTaskDelegate相应的method来配置相应的策略
///
/// 需要拦截转发的WKWebView, 直接注册该类为WKWebViewConfiguration的对应协议的处理者即可:
///   configuration.setURLSchemeHandler(WKHTTPHandler.shared, forURLScheme: "http")
///   configuration.setURLSchemeHandler(WKHTTPHandler.shared, forURLScheme: "https")
///   WKHTTPHandler.shared.patchJSCookieSetterForSync(in: configuration.userContentController)
///
/// 或者一行调用: WKHTTPHandler.shared.enable(in: configuration)
///
/// NOTE: iOS11不一定支持body
/// https://github.com/WebKit/webkit/commit/0855276275eb1d29615dfb24f288697a238a96b1
/// 1 Dec 2017, 才提交WKURLSchemeHandler支持HttpBody的补丁... 具体哪个版本开始支持的还得再查查.
///
/// https://zh.wikipedia.org/wiki/IOS_11#iOS_11.1
/// 从上表看出至少iOS11.2后才可能打上上面HttpBody的补丁...
///
/// 另外iOS 11各方面的稳定性也差很多，不推荐在iOS 11上开启HTTP导流
@available(iOS 11.0, *)
open class WKBaseHTTPHandler: NSObject, WKURLSchemeHandler, WKHTTPTaskDelegate {
    private var runningSchemeTasks = [ObjectIdentifier: Task]()
    public override init() {
        WKWebView.enableHttpScheme() // ensure the handler is usable
    }
    /// register http and https, patch js cookie setter, in one shot
    public func enable(in configuration: WKWebViewConfiguration) {
        configuration.setURLSchemeHandler(self, forURLScheme: "http")
        configuration.setURLSchemeHandler(self, forURLScheme: "https")
        patchJSCookieSetterForSync(in: configuration.userContentController)
    }

    // MARK: WKURLSchemeHandler
    /// WKWebview开始请求。回调应该在同一线程，否则可能崩溃
    public func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        debug("start handler: \(dump(request: urlSchemeTask.request))")
        syncNativeCookie(to: webView)

        // FIXME: 是否需要考虑和检查处理跨域攻击?
        let identifier = ObjectIdentifier(urlSchemeTask)
        let task = Task(task: urlSchemeTask, webView: webView, delegate: self)
        runningSchemeTasks[identifier] = task
        task.startLoading() // 使用缓存的情况，有可能在调用中直接结束, 所以要先把task保存下来
    }

    public func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        assert(Thread.isMainThread) // WKWebview会在主线程上进行回调

        // NOTE: 这个不一定调用, WKWebview取消时会调用. 调用后不应该再有后续回调
        debug("stop handler: \(dump(request: urlSchemeTask.request))")
        stop(urlSchemeTask: urlSchemeTask)
    }
    private func stop(urlSchemeTask: WKURLSchemeTask) {
        guard let task = runningSchemeTasks.removeValue(forKey: ObjectIdentifier(urlSchemeTask)) else {
            return
        }
        task.stopLoading()
    }

    open func syncNativeCookie(to: WKWebView) {
        WKCookieSyncer.shared.syncNativeCookie(to: to)
    }
    open func patchJSCookieSetterForSync(in controller: WKUserContentController) {
        WKCookieSyncer.shared.patchJSCookieSetterForSync(in: controller)
    }

    // MARK: WKHTTPTaskDelegate
    public func taskDidFinish(_ task: WKHTTPTask) {
        self.stop(urlSchemeTask: task.task)
    }
    open func taskURLProtocol(_ task: WKHTTPTask) -> URLProtocol.Type {
        return NativeHTTProtocol.self
    }
    open func taskWillLoad(_ task: WKHTTPTask, request: URLRequest) -> URLRequest? {
        return request
    }
}

// hack
@available(iOS 11.0, *)
extension WKWebView {
    /// hack WKWebView, 支持configuration里设置http scheme
    public static let isEnableHTTPSupport = AtomicBoolCell()
    /// 支持HTTP的URLSchemeHandlers
    public static func enableHttpScheme() {
        /// 这种方式支持通过Configuration适配支持的HTTP，但没法取消(configuration是不可变的)。
        if isEnableHTTPSupport.exchange(true) == false {
            switchHandlesURLScheme()
        }
    }
    private static func switchHandlesURLScheme() {
        if
            case let cls = WKWebView.self,
            let m1 = class_getClassMethod(cls, NSSelectorFromString("handlesURLScheme:")),
            let m2 = class_getClassMethod(cls, #selector(WKWebView.wrapHandles(urlScheme:)))
        {
            method_exchangeImplementations(m1, m2)
        }
    }
    /// 返回true如果WKWebview支持处理这种协议, 但WKWebview默认支持http，所以返回false支持用自定义的http Handlers
    ///
    /// NOTE: 如果不在configuration里注册http handlers, 则仍然会用WKWebView默认的HTTP进行处理
    @objc dynamic
    private static func wrapHandles(urlScheme: String) -> Bool {
        debug(urlScheme)
        if urlScheme == "http" || urlScheme == "https" { return false }
        return self.wrapHandles(urlScheme: urlScheme)
    }
}
#endif
