//
//  LarkCookieInstrument.swift
//  CookieManager
//
//  Created by au on 2023/12/21.
//

import Foundation
import LarkFeatureGating
import LarkSetting
import LKCommonsLogging
import WebKit

private var LarkCookieInstrumentIDKey: Void?

/// 用于定位线上 cookie 丢失问题
public final class LarkCookieInstrument {

    static let shared = LarkCookieInstrument()

    static var shouldHookURLSessionAndWebKitMethods: Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "lark.cookie_instrument.url_session_and_web_kit_hook"))
    }
    static var shouldObserveCookieNotification: Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "lark.cookie_instrument.cookie_notification_observe"))
    }

    private init() {
        if LarkCookieInstrument.shouldHookURLSessionAndWebKitMethods {
            injectURLSessionMethods()
            URLSession.hookURLSessionMethods()
            WKHTTPCookieStore.hookWKHTTPCookieStoreMethods()
        }
        if LarkCookieInstrument.shouldObserveCookieNotification {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(observeCookiesChange),
                                                   name: .NSHTTPCookieManagerCookiesChanged,
                                                   object: nil)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    func observeCookiesChange() {
        InstrumentUtils.inspectNSStorageCookies()
    }

    enum InstrumentUtils {
        static let ci_queue = DispatchQueue(label: "com.larksuite.CookieInstrument")
        static let logger = Logger.log(InstrumentUtils.self, category: "LarkCookieInstrument.InstrumentUtils")

        // 检视请求返回的 header
        static func inspectHeader(with response: URLResponse?, fromDelegate: Bool = false) {
            Self.ci_queue.async {
                // here `cookie` is a string 
                // 当接口下发多条 set-cookie 时，系统会 merge 成单条，中间以逗号分隔
                // 接口 set-cookie 的大小写不影响这里获取的结果，Set-Cookie 总是可以获取到全部内容
                guard let response = response,
                      let httpResponse = response as? HTTPURLResponse,
                      let cookie = httpResponse.allHeaderFields["Set-Cookie"] as? String else { 
                    return
                }
                var message = "[CookieInstrument] inspect HEADER: \(cookie);"
                if fromDelegate {
                    message += " fromDelegate;"
                }
                if cookie.contains(".feishu.cn") {
                    InstrumentUtils.logger.error(message + " ### url: \(httpResponse.url?.absoluteString ?? "(empty)")")
                } else {
                    InstrumentUtils.logger.info(message)
                }
            }
        }

        static func inspectNSStorageCookies() {
            Self.ci_queue.async {
                let feishuCookies = HTTPCookieStorage.shared.cookies?.filter({ $0.domain.hasSuffix(".feishu.cn")}) ?? []
                if feishuCookies.isEmpty {
                    InstrumentUtils.logger.error("[CookieInstrument] Now cookie storage no feishu cookies")
                } else {
                    feishuCookies.forEach { cookie in
                        if cookie.name == "session" || cookie.name == "osession" || cookie.name == "bear-session" {
                            InstrumentUtils.logger.error("[CookieInstrument] cookie: \(cookie); from: NC_cookiesChanged")
                        } else {
                            InstrumentUtils.logger.info("[CookieInstrument] cookie: \(cookie); from: NC_cookiesChanged")
                        }
                    }
                }
            }
        }

        // 检视 cookie
        static func inspectCookie(cookie: HTTPCookie, from: String) {
            Self.ci_queue.async {
                if cookie.domain.hasSuffix(".feishu.cn") {
                    if cookie.name == "session" || cookie.name == "osession" || cookie.name == "bear-session" {
                        InstrumentUtils.logger.error("[CookieInstrument] cookie: \(cookie); from: \(from)")
                    } else {
                        InstrumentUtils.logger.info("[CookieInstrument] cookie: \(cookie); from: \(from)")
                    }
                }
            }
        }

        static func objc_getClassList() -> [AnyClass] {
            let expectedClassCount = ObjectiveC.objc_getClassList(nil, 0)
            let allClasses = UnsafeMutablePointer<AnyClass>.allocate(capacity: Int(expectedClassCount))
            let autoreleasingAllClasses = AutoreleasingUnsafeMutablePointer<AnyClass>(allClasses)
            let actualClassCount: Int32 = ObjectiveC.objc_getClassList(autoreleasingAllClasses, expectedClassCount)

            var classes = [AnyClass]()
            for i in 0 ..< actualClassCount {
                classes.append(allClasses[Int(i)])
            }
            allClasses.deallocate()
            return classes
        }

        static func instanceRespondsAndImplements(cls: AnyClass, selector: Selector) -> Bool {
            var implements = false
            if cls.instancesRespond(to: selector) {
                var methodCount: UInt32 = 0
                guard let methodList = class_copyMethodList(cls, &methodCount) else {
                    return implements
                }
                defer { free(methodList) }
                if methodCount > 0 {
                    enumerateCArray(array: methodList, count: methodCount) { _, m in
                        let sel = method_getName(m)
                        if sel == selector {
                            implements = true
                            return
                        }
                    }
                }
            }
            return implements
        }

        private static func enumerateCArray<T>(array: UnsafePointer<T>, count: UInt32, f: (UInt32, T) -> Void) {
            var ptr = array
            for i in 0 ..< count {
                f(i, ptr.pointee)
                ptr = ptr.successor()
            }
        }
    }
}

extension LarkCookieInstrument {
    private func injectURLSessionMethods() {
        let selectors = [#selector(URLSessionDataDelegate.urlSession(_:dataTask:didReceive:completionHandler:))]
        let classes = InstrumentUtils.objc_getClassList()
        let selectorsCount = selectors.count
        DispatchQueue.concurrentPerform(iterations: classes.count) { iteration in
            let theClass: AnyClass = classes[iteration]
            guard theClass != Self.self else { return }
            var selectorFound = false
            var methodCount: UInt32 = 0
            guard let methodList = class_copyMethodList(theClass, &methodCount) else { return }
            defer { free(methodList) }

            for j in 0 ..< selectorsCount {
                for i in 0 ..< Int(methodCount) {
                    if method_getName(methodList[i]) == selectors[j] {
                        selectorFound = true
                        injectIntoDelegateClass(cls: theClass)
                        break
                    }
                }
                if selectorFound {
                    break
                }
            }
        }
    }

    private func injectIntoDelegateClass(cls: AnyClass) {
        injectTaskDidReceiveResponseIntoDelegateClass(cls: cls)
    }

    // 拦截 urlSession delegate 方法实现，先执行我们的方法逻辑，再执行原逻辑
    private func injectTaskDidReceiveResponseIntoDelegateClass(cls: AnyClass) {
        let selector = #selector(URLSessionDataDelegate.urlSession(_:dataTask:didReceive:completionHandler:))
        guard let original = class_getInstanceMethod(cls, selector) else {
            return
        }
        var originalIMP: IMP?
        let block: @convention(block) (Any, URLSession, URLSessionDataTask, URLResponse, @escaping (URLSession.ResponseDisposition) -> Void) -> Void = { object, session, dataTask, response, completion in
            if objc_getAssociatedObject(session, &LarkCookieInstrumentIDKey) == nil {
                self.urlSession(session, dataTask: dataTask, didReceive: response, completionHandler: completion)
            }
            let key = String(selector.hashValue)
            objc_setAssociatedObject(session, key, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            let castedIMP = unsafeBitCast(originalIMP, to: (@convention(c) (Any, Selector, URLSession, URLSessionDataTask, URLResponse, @escaping (URLSession.ResponseDisposition) -> Void) -> Void).self)
            castedIMP(object, selector, session, dataTask, response, completion)
            objc_setAssociatedObject(session, key, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        let swizzledIMP = imp_implementationWithBlock(unsafeBitCast(block, to: AnyObject.self))
        originalIMP = method_setImplementation(original, swizzledIMP)
    }

    private func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        InstrumentUtils.inspectHeader(with: response, fromDelegate: true)
    }
}

extension URLSession {
    static func hookURLSessionMethods() {
        swizzlingForClass(URLSession.self,
                          originalSelector: #selector(URLSession.dataTask(with:completionHandler:) as (URLSession) -> (URLRequest, @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask),
                          swizzledSelector: #selector(self.ci_dataTask(withR:completionHandler:)))
        swizzlingForClass(URLSession.self,
                          originalSelector: #selector(URLSession.dataTask(with:completionHandler:) as (URLSession) -> (URL, @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask),
                          swizzledSelector: #selector(self.ci_dataTask(withU:completionHandler:)))

        swizzlingForClass(URLSession.self,
                          originalSelector: #selector(URLSession.uploadTask(with:fromFile:completionHandler:)),
                          swizzledSelector: #selector(self.ci_uploadTask(with:fromFile:completionHandler:)))
        swizzlingForClass(URLSession.self,
                          originalSelector: #selector(URLSession.uploadTask(with:from:completionHandler:)),
                          swizzledSelector: #selector(self.ci_uploadTask(with:from:completionHandler:)))

        swizzlingForClass(URLSession.self,
                          originalSelector: #selector(URLSession.downloadTask(with:completionHandler:) as (URLSession) -> (URLRequest, @escaping @Sendable (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask),
                          swizzledSelector: #selector(self.ci_downloadTask(withR:completionHandler:)))
        swizzlingForClass(URLSession.self,
                          originalSelector: #selector(URLSession.downloadTask(with:completionHandler:) as (URLSession) -> (URL, @escaping @Sendable (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask),
                          swizzledSelector: #selector(self.ci_downloadTask(withU:completionHandler:)))
        swizzlingForClass(URLSession.self,
                          originalSelector: #selector(URLSession.downloadTask(withResumeData:completionHandler:)),
                          swizzledSelector: #selector(self.ci_downloadTask(withResumeData:completionHandler:)))
    }

    static func swizzlingForClass(_ forClass: AnyClass, originalSelector: Selector, swizzledSelector: Selector) {
        guard let originalMethod = class_getInstanceMethod(forClass, originalSelector),
              let swizzledMethod = class_getInstanceMethod(forClass, swizzledSelector) else {
            return
        }
        if class_addMethod(forClass, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod)) {
            class_replaceMethod(forClass, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }

    // MARK: - Data Task
    @objc
    func ci_dataTask(withR request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return ci_dataTask(withR: request) { data, response, error in
            LarkCookieInstrument.InstrumentUtils.inspectHeader(with: response)
            completionHandler(data, response, error)
        }
    }

    @objc
    func ci_dataTask(withU url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return ci_dataTask(withU: url) { data, response, error in
            LarkCookieInstrument.InstrumentUtils.inspectHeader(with: response)
            completionHandler(data, response, error)
        }
    }

    // MARK: - Upload Task
    @objc
    func ci_uploadTask(with request: URLRequest, fromFile fileURL: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionUploadTask {
        return ci_uploadTask(with: request, fromFile: fileURL) { data, response, error in
            LarkCookieInstrument.InstrumentUtils.inspectHeader(with: response)
            completionHandler(data, response, error)
        }
    }

    @objc
    func ci_uploadTask(with request: URLRequest, from bodyData: Data?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionUploadTask {
        return ci_uploadTask(with: request, from: bodyData) { data, response, error in
            LarkCookieInstrument.InstrumentUtils.inspectHeader(with: response)
            completionHandler(data, response, error)
        }
    }

    // MARK: - Download Task
    @objc
    func ci_downloadTask(withR request: URLRequest, completionHandler: @escaping @Sendable (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        return ci_downloadTask(withR: request) { url, response, error in
            LarkCookieInstrument.InstrumentUtils.inspectHeader(with: response)
            completionHandler(url, response, error)
        }
    }

    @objc
    func ci_downloadTask(withU url: URL, completionHandler: @escaping @Sendable (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        return ci_downloadTask(withU: url) { url, response, error in
            LarkCookieInstrument.InstrumentUtils.inspectHeader(with: response)
            completionHandler(url, response, error)
        }
    }

    @objc
    func ci_downloadTask(withResumeData resumeData: Data, completionHandler: @escaping @Sendable (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        return ci_downloadTask(withResumeData: resumeData) { url, response, error in
            LarkCookieInstrument.InstrumentUtils.inspectHeader(with: response)
            completionHandler(url, response, error)
        }
    }
}

extension WKHTTPCookieStore {
    static func hookWKHTTPCookieStoreMethods() {
        swizzlingForClass(WKHTTPCookieStore.self,
                          originalSelector: #selector(WKHTTPCookieStore.setCookie(_:completionHandler:)),
                          swizzledSelector: #selector(self.ci_setCookie(_:completionHandler:)))

        swizzlingForClass(WKHTTPCookieStore.self,
                          originalSelector: #selector(WKHTTPCookieStore.delete(_:completionHandler:)),
                          swizzledSelector: #selector(self.ci_delete(_:completionHandler:)))
    }

    static func swizzlingForClass(_ forClass: AnyClass, originalSelector: Selector, swizzledSelector: Selector) {
        guard let originalMethod = class_getInstanceMethod(forClass, originalSelector),
              let swizzledMethod = class_getInstanceMethod(forClass, swizzledSelector) else {
            return
        }
        if class_addMethod(forClass, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod)) {
            class_replaceMethod(forClass, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }

    @objc
    func ci_setCookie(_ cookie: HTTPCookie, completionHandler: (() -> Void)?) {
        self.ci_setCookie(cookie) {
            LarkCookieInstrument.InstrumentUtils.inspectCookie(cookie: cookie, from: "WK_setCookie")
            completionHandler?()
        }
    }

    @objc
    func ci_delete(_ cookie: HTTPCookie, completionHandler: (() -> Void)?) {
        self.ci_delete(cookie) {
            LarkCookieInstrument.InstrumentUtils.inspectCookie(cookie: cookie, from: "WK_deleteCookie")
            completionHandler?()
        }
    }
}
