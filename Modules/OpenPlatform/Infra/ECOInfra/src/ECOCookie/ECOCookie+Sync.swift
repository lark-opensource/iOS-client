//
//  ECOCookie+Sync.swift
//  ECOInfra
//
//  Created by Meng on 2021/2/18.
//

import Foundation
import LarkContainer
import ECOProbe

/// gadget cookie 兼容同步策略
final class ECOCookieGadgetSync: NSObject, ECOCookieStorage {
    @Provider private var global: ECOCookieGlobalPlugin // Global
    private let gadget: ECOCookiePlugin
    
    private let resolver: UserResolver
    private let gadgetId: GadgetCookieIdentifier

    init(resolver: UserResolver, gadgetId: GadgetCookieIdentifier) throws {
        self.resolver = resolver
        self.gadgetId = gadgetId
        
        gadget = try resolver.resolve(assert: ECOCookiePlugin.self, argument: gadgetId.isolateIdentifier(uid: resolver.userID))
        
        super.init()
    }

    func cookies(for url: URL) -> [HTTPCookie] {
        let monitor = OPMonitor(name: ECOCookieMonitorCode.monitorName,
                                code: ECOCookieMonitorCode.read_app_cookie)
            .setGadgetId(gadgetId)
            .addCategoryValue("url_domain", url.host)
        var result: [HTTPCookie] = []
        // 如果 gadget 与 global 数据同时存在，则优先使用 gadget 数据
        let gadgetCookies = gadget.cookies(for: url)
        _ = monitor
            .addCategoryValue("isolate_domains", gadgetCookies.map({ $0.domain }))
            .addCategoryValue("isolate_names", gadgetCookies.map({ $0.name.reuseCacheMask(except: ECOCookieConfig.cookieExceptMaskCharacters) }))
        result.append(contentsOf: gadgetCookies)
        monitor.flush()
        return result
    }

    func saveCookies(_ cookies: [HTTPCookie], url: URL?) {
        if cookies.isEmpty {
            return
        }
        OPMonitor(name: ECOCookieMonitorCode.monitorName, code: ECOCookieMonitorCode.write_app_cookie)
            .setGadgetId(gadgetId)
            .addCategoryValue("names", cookies.map({ $0.name.reuseCacheMask(except: ECOCookieConfig.cookieExceptMaskCharacters) }))
            .addCategoryValue("domains", cookies.map({ $0.domain }))
            .flush()
        gadget.saveCookies(cookies, url: url)
    }

    func saveCookie(with response: HTTPURLResponse) {
        guard let header = response.allHeaderFields as? [String: String],
              let url = response.url else {
            OPMonitor(ECOCookieMonitorCode.save_response_cookie_failed)
                .setGadgetId(gadgetId)
                .addCategoryValue("url_domain", response.url?.host)
                .addCategoryValue("is_string_dict_header", response.allHeaderFields is [String: String])
                .addCategoryValue("status_code", response.statusCode)
                .flush()
            return
        }
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: header, for: url)
        if cookies.isEmpty {
            return
        }
        OPMonitor(name: ECOCookieMonitorCode.monitorName, code: ECOCookieMonitorCode.write_app_cookie)
            .setGadgetId(gadgetId)
            .addCategoryValue("names", cookies.map({ $0.name.reuseCacheMask(except: ECOCookieConfig.cookieExceptMaskCharacters) }))
            .addCategoryValue("domains", cookies.map({ $0.domain }))
            .addCategoryValue("url_domain", url.host)
            .flush()

        // 不直接调用 self.saveCookies(_:) 是因为避免重复埋点
        gadget.saveCookies(cookies, url: response.url)
    }
}
