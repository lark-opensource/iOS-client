//
//  ECOCookieGlobalPlugin.swift
//  ECOInfra
//
//  Created by Meng on 2021/2/18.
//

import Foundation
import LKCommonsLogging
import ECOProbe
import LarkSetting

/// ECOCookieGlobalPlugin
///
/// Cookie 全局存储
final class ECOCookieGlobalPlugin: NSObject, ECOCookieStorage {
    static let logger = Logger.oplog(ECOCookieGlobalPlugin.self, category: "ECOCookieGlobalPlugin")

    private lazy var enableCookieCheckDomain: Bool = {
        return FeatureGatingManager.realTimeManager.featureGatingValue(with: "openplatform.api.network.enable_cookie_save_check_domain") // Global
    }()

    var cookies: [HTTPCookie] {
        return HTTPCookieStorage.shared.cookies ?? []
    }

    func cookies(for url: URL) -> [HTTPCookie] {
        return HTTPCookieStorage.shared.cookies(for: url) ?? []
    }

    func saveCookies(_ cookies: [HTTPCookie], url: URL?) {
        Self.logger.info("save cookies", additionalData: [
            "url": "\(url?.safeURLString ?? "")",
            "domains": "\(cookies.map({ $0.domain }))",
            "names": "\(cookies.map({ $0.name.reuseCacheMask(except: ECOCookieConfig.cookieExceptMaskCharacters) }))"
        ])
        if enableCookieCheckDomain, let realUrl = url {
            HTTPCookieStorage.shared.setCookies(cookies, for: realUrl, mainDocumentURL: nil)
        } else {
            cookies.forEach({ HTTPCookieStorage.shared.setCookie($0) })
        }
    }

    func saveCookie(with response: HTTPURLResponse) {
        guard let header = response.allHeaderFields as? [String: String],
              let url = response.url else {
            OPMonitor(ECOCookieMonitorCode.save_response_cookie_failed)
                .addCategoryValue("url_domain", response.url?.host)
                .addCategoryValue("is_string_dict_header", response.allHeaderFields is [String: String])
                .addCategoryValue("status_code", response.statusCode)
                .flush()
            return
        }
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: header, for: url)
        self.saveCookies(cookies, url: response.url)
    }
}
