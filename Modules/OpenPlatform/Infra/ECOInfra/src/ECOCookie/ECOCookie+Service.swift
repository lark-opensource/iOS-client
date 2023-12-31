//
//  ECOCookie+Service.swift
//  ECOInfra
//
//  Created by Meng on 2021/2/9.
//

import Foundation
import LarkContainer
import Swinject
import WebKit
import ECOProbe
import LKCommonsLogging
import LarkFoundation
import LarkAccountInterface

@objc(ECOCookie)
public final class ECOCookieForObjc: NSObject {
    static let logger = Logger.oplog(ECOCookieForObjc.self, category: "ECOCookieForObjc")
    
    @objc
    public class func resolveService() -> ECOCookieService? {
        // TODOZJX
        if let service = try? OPUserScope.userResolver().resolve(assert: ECOCookieService.self) {
            return service
        } else {
            Self.logger.error("resolve ECOCookieService failed")
            return nil
        }
    }
}

final class ECOCookieServiceImpl: NSObject, ECOCookieService {
    static let logger = Logger.oplog(ECOCookieService.self, category: "ECOCookieService")

    private let resolver: UserResolver
    private let config: ECOCookieConfig
    private let userService: PassportUserService

    init(resolver: UserResolver) throws {
        self.resolver = resolver
        config = try resolver.resolve(assert: ECOCookieConfig.self)
        userService = try resolver.resolve(assert: PassportUserService.self)
    }

    func cookieStorage(withIdentifier identifier: String?) -> ECOCookieStorage? {
        if let identifier = identifier {
            if let storage = try? resolver.resolve(assert: ECOCookiePlugin.self, argument: identifier) {
                return storage
            } else {
                Self.logger.error("resolve ECOCookiePlugin failed")
                return nil
            }
        } else {
            return Injected<ECOCookieGlobalPlugin>().wrappedValue // Global
        }
    }

    func gadgetCookieStorage(with gadgetId: GadgetCookieIdentifier?) -> ECOCookieStorage? {
        if let gadgetId = gadgetId {
            if let storage = try? resolver.resolve(assert: ECOCookieGadgetSync.self, argument: gadgetId) {
                return storage
            } else {
                Self.logger.error("resolve ECOCookieGadgetSync failed")
                return nil
            }
        } else {
            return cookieStorage(withIdentifier: nil)
        }
    }

    func syncGadgetWebsiteDataStore(with gadgetId: GadgetCookieIdentifier, dataStore: WKWebsiteDataStore) {
        Self.logger.info("sync gadget website data store", additionalData: [
            "uniqueId": gadgetId.fullString,
            "isPersistent": "\(dataStore.isPersistent)"
        ])
        
        // 小程序 同步 Cookie 至 WebView 策略控制
        var gadgetWebViewCookieIsolated = false
        if config.gadgetWebViewCookieIsolationAllApplied {
            gadgetWebViewCookieIsolated = true
        } else {
            let tenantID = userService.userTenant.tenantID
            let appID = gadgetId.appID
            gadgetWebViewCookieIsolated = config.gadgetWebViewCookieIsolated(tenantID: tenantID, appID: appID)
        }
        
        if !gadgetWebViewCookieIsolated {
            if let gadgetCookieStorage = try? resolver.resolve(assert: ECOCookiePlugin.self, argument: gadgetId.isolateIdentifier(uid: resolver.userID)) {
                let start = Date().timeIntervalSince1970
                var isolateCookies = gadgetCookieStorage.cookies
                if let whiteList = config.requestCookieURLWhiteListForWebview {
                    isolateCookies = isolateCookies.filter({ whiteList.contains($0.domain) })
                }
                let end = Date().timeIntervalSince1970

                OPMonitor(ECOCookieMonitorCode.sync_webview_cookies)
                    .setGadgetId(gadgetId)
                    .addCategoryValue("isPersistent", dataStore.isPersistent)
                    .addCategoryValue("isolate_domains", isolateCookies.map({ $0.domain }))
                    .addCategoryValue("cost", Int((end - start) * 1000))
                    .flush()

                isolateCookies.forEach({
                    dataStore.httpCookieStore.setCookie($0, completionHandler: nil)
                })
            } else {
                Self.logger.error("resolve ECOCookiePlugin failed")
            }
        }
    }

    func getDiagnoseInfo(with gadgetId: GadgetCookieIdentifier) -> [[String : String]] {
        guard let gadgetCookieStorage = try? resolver.resolve(assert: ECOCookiePlugin.self, argument: gadgetId.isolateIdentifier(uid: resolver.userID)) else {
            Self.logger.error("resolve ECOCookiePlugin failed")
            return []
        }
        
        return gadgetCookieStorage.cookies.map({ cookie in
            let expiresDataStr = cookie.expiresDate?.string(withFormat: "yyyy-MM-dd HH:mm") ?? ""
            return [
                "domain": cookie.domain,
                "name": cookie.name.reuseCacheMask(except: ECOCookieConfig.cookieExceptMaskCharacters),
                "value_length": "\(cookie.value.count)",
                "path": cookie.path.reuseCacheMask(except: ["/", "."]),
                "expires_date": cookie.isSessionOnly ? "Session" : expiresDataStr
            ]
        })
    }
}
 
