//
//  LarkCookieDoctor.swift
//  CookieManager
//
//  Created by Nix Wang on 2023/2/20.
//

import EEAtomic
import Foundation
import Heimdallr
import LarkAccountInterface
import LarkAppConfig
import LarkContainer
import LarkSetting
import LKCommonsLogging

public final class LarkCookieDoctor {
    public static let shared = LarkCookieDoctor()
    static let logger = Logger.log(LarkCookieDoctor.self, category: "LarkCookieDoctor")
    static let threadExceptionType = "cookie_doctor_thread"
    static let baseExceptionType = "cookie_doctor_base"

    static let clearCookieHookFGKey = "lark.cookie_doctor.http_hook.clear_cookie"   // hook clear & remove
    static let setCookieHookFGKey = "lark.cookie_doctor.http_hook.set_cookie"       // hook set
    static let getCookieHookFGKey = "lark.cookie_doctor.http_hook.get_cookie"       // hook get

    static var shouldHookClearCookie: Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: LarkCookieDoctor.clearCookieHookFGKey))
    }
    static var shouldHookSetCookie: Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: LarkCookieDoctor.setCookieHookFGKey))
    }

    var passportUserService: PassportUserService? { Container.shared.getCurrentUserResolver().resolve(PassportUserService.self) }

    private init() { }

    static func trackBaseException(customParams: [String: Any]? = nil) {
        Self.logger.info("[CookieDoctor] Track base exception: \(customParams ?? [:])")

        HMDUserExceptionTracker.shared().trackUserException(withExceptionType: self.baseExceptionType,
                                                            title: "cookie_doctor_base",
                                                            subTitle: "session_cookie",
                                                            customParams: customParams,
                                                            filters: nil) { error in
            guard let error = error else { return }
            /// errcode的定义:
            /// 1: user exception模块没有开启工作
            /// 2: 类型缺失
            /// 3: 超出客户端限流，1min内同一种类型的自定义异常不可以超过1条
            /// 4: 写入数据库失败
            /// 5: 参数缺失
            /// 6: hitting blockList
            /// 7: 日志生成失败
            Self.logger.error("[CookieDoctor] Failed to track base logs", error: error)
        }
    }

    static func trackThreadException(_ skippedDepth: UInt = 0,
                                     customParams: [String: Any]? = nil,
                                     filters: [String: Any]? = nil) {

        Self.logger.info("[CookieDoctor] Track thread exception: \(customParams ?? [:])")

        HMDUserExceptionTracker.shared().trackAllThreadsLogExceptionType(Self.threadExceptionType, skippedDepth: skippedDepth, customParams: customParams, filters: filters, callback: { error in
            guard let error = error else { return }
            /// errcode的定义:
            /// 1: user exception模块没有开启工作
            /// 2: 类型缺失
            /// 3: 超出客户端限流，1min内同一种类型的自定义异常不可以超过1条
            /// 4: 写入数据库失败
            /// 5: 参数缺失
            /// 6: hitting blockList
            /// 7: 日志生成失败
            Self.logger.error("[CookieDoctor] Failed to track thread logs", error: error)
        })
    }

    @AtomicObject
    fileprivate var isCookieManagerAccessing: Bool = false

    func setup() {
        HTTPCookieStorage.shared.hookIfNeeded()
    }

    // 调用此方法对主域名的 session cookie 进行操作不会上报, 详情请联系 Passport
    public func performCookieStorageOperation(_ operation: () -> Void) {
        isCookieManagerAccessing = true
        operation()
        isCookieManagerAccessing = false
    }

    fileprivate static func dropDotPrefixIfNeeded(domain: String) -> String {
        let dot = "."
        guard domain.hasPrefix(dot) else { return domain }
        return String(domain.dropFirst(dot.count))
    }

}

extension HTTPCookieStorage {

    // MARK: - Hook

    func hookIfNeeded() {
        LarkCookieDoctor.logger.info("[CookieDoctor] Hook if needed")

        // Set Cookie 相关方法
        if LarkCookieDoctor.shouldHookSetCookie {
            LarkCookieDoctor.logger.info("[CookieDoctor] Hook set cookie")
            swizzlingForClass(HTTPCookieStorage.self,
                              originalSelector: #selector(HTTPCookieStorage.setCookies(_:for:mainDocumentURL:)),
                              swizzledSelector: #selector(self.cd_setCookies(_:for:mainDocumentURL:)))
            swizzlingForClass(HTTPCookieStorage.self, originalSelector: #selector(HTTPCookieStorage.setCookie(_:)), swizzledSelector: #selector(self.cd_setCookie(_:)))
        }

        // Clear Cookie 相关方法
        if LarkCookieDoctor.shouldHookClearCookie {
            LarkCookieDoctor.logger.info("[CookieDoctor] Hook clear cookie")
            swizzlingForClass(HTTPCookieStorage.self, originalSelector: #selector(HTTPCookieStorage.deleteCookie(_:)), swizzledSelector: #selector(self.cd_deleteCookie(_:)))
            swizzlingForClass(HTTPCookieStorage.self, originalSelector: #selector(HTTPCookieStorage.removeCookies(since:)), swizzledSelector: #selector(self.cd_removeCookies(since:)))
        }
    }

    func swizzlingForClass(_ forClass: AnyClass, originalSelector: Selector, swizzledSelector: Selector) {
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
    func cd_setCookies(_ cookies: [HTTPCookie], for URL: URL?, mainDocumentURL: URL?) {
        if !LarkCookieDoctor.shared.isCookieManagerAccessing && containsMainDomainSessionCookie(cookies: cookies) {
            // id是为了让日志和slardar上报匹配 下同
            let id = UUID().uuidString
            let urlString = URL?.host ?? ""
            let maskedText = Self.maskCookies(cookies)
            LarkCookieDoctor.logger.warn("[CookieDoctor] setCookies: \(maskedText) for URL:\(String(describing: URL)) id:\(id)")

            assertionFailure("Session cookie for main domains must be managed by CookieManager, please contact Passport")
            LarkCookieDoctor.trackThreadException(customParams: ["setCookies": maskedText,
                                                                 "id": id,
                                                                 "URL": urlString])
        }
        
        self.cd_setCookies(cookies, for: URL, mainDocumentURL: mainDocumentURL)
    }
    
    @objc
    func cd_setCookie(_ cookie: HTTPCookie) {
        if !LarkCookieDoctor.shared.isCookieManagerAccessing && containsMainDomainSessionCookie(cookies: [cookie]) {
            let id = UUID().uuidString
            let maskedText = Self.maskCookies([cookie])
            LarkCookieDoctor.logger.warn("[CookieDoctor] setCookie: \(maskedText) id:\(id)")
            
            assertionFailure("Session cookie for main domains must be managed by CookieManager, please contact Passport")
            LarkCookieDoctor.trackThreadException(customParams: ["setCookie": maskedText,
                                                                 "id": id])
        }
        
        self.cd_setCookie(cookie)
    }
    
    @objc
    func cd_deleteCookie(_ cookie: HTTPCookie) {
        if !LarkCookieDoctor.shared.isCookieManagerAccessing && containsMainDomainSessionCookie(cookies: [cookie]) {
            let id = UUID().uuidString
            let maskedText = Self.maskCookies([cookie])
            LarkCookieDoctor.logger.warn("[CookieDoctor] deleteCookie: \(maskedText) id:\(id)")
            
            assertionFailure("Session cookie for main domains must be managed by CookieManager, please contact Passport")
            LarkCookieDoctor.trackThreadException(customParams: ["setCookie": maskedText,
                                                                 "id": id])
        }
        
        self.cd_deleteCookie(cookie)
    }
    
    @objc
    func cd_removeCookies(since date: Date) {
        if !LarkCookieDoctor.shared.isCookieManagerAccessing {
            let id = UUID().uuidString
            LarkCookieDoctor.logger.warn("[CookieDoctor] deleteCookie since:\(date) id:\(id)")
            
            assertionFailure("Cookie must be cleaned by CookieManager, please contact Passport")
            LarkCookieDoctor.trackThreadException(customParams: ["deleteCookie": "since \(date)",
                                                                 "id": id])
        }
        
        self.cd_removeCookies(since: date)
    }
    
    
    // MARK: - Utils
    
    func containsMainDomainSessionCookie(cookies: [HTTPCookie]) -> Bool {
        // app config domains are like 'feishu.cn' / 'feishu.net'
        // cookie domains are like '.feishu.cn' / '.feishu.net' so have to remove the dot
        let appConfigDomains = ConfigurationManager.shared.mainDomains.map { LarkCookieDoctor.dropDotPrefixIfNeeded(domain: $0) }
        let sessionCookieNames = [LarkCookieManager.sessionName, LarkCookieManager.openSessionName, LarkCookieManager.bearSessionName]
        for cookie in cookies {
            let cookieDomain = LarkCookieDoctor.dropDotPrefixIfNeeded(domain: cookie.domain.lowercased())
            let isMainDomain = appConfigDomains.contains(cookieDomain)
            let isSessionCookie = sessionCookieNames.contains(cookie.name.lowercased())
            if isMainDomain && isSessionCookie {
                return true
            }
        }
        return false
    }
    
    private static func maskCookies(_ cookies: [HTTPCookie]) -> String {
        let cookieStrings: [String] = cookies.map { "name=\($0.name) value=\($0.value.cookie_mask()) expiresDate=\($0.expiresDate ?? Date(timeIntervalSince1970: 0)) domain=\($0.domain)" }
        return cookieStrings.joined(separator: "\n")
    }
    
}
