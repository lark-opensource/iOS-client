//
//  ECOCookiePlugin.swift
//  ECOInfra
//
//  Created by Meng on 2021/2/18.
//

import Foundation
import LKCommonsLogging
import ECOProbe
import LarkContainer

/// ECOCookiePlugin
///
/// Cookie Gadget 存储，不同 Gadget 数据隔离
final class ECOCookiePlugin: NSObject, ECOCookieStorage {
    static let logger = Logger.oplog(ECOCookiePlugin.self, category: "ECOCookiePlugin")

    let identifier: String
    @Provider private var global: ECOCookieGlobalPlugin // Global

    private var domainSuffix: String {
        return "." + identifier
    }
    
    private let resolver: UserResolver

    init(resolver: UserResolver, identifier: String) {
        self.resolver = resolver
        self.identifier = identifier
        super.init()
    }

    var cookies: [HTTPCookie] {
        return global.cookies
            .filter({ $0.domain.hasSuffix(domainSuffix) })
            .compactMap({ cookie in
                if let convertCookie = cookie.convertDomain(handler: removeMask) {
                    return convertCookie
                } else {
                    OPMonitor(ECOCookieMonitorCode.domain_convert_failed)
                        .addCategoryValue("isolate_id", identifier)
                        .addCategoryValue("remove", true)
                        .addCategoryValue("name", cookie.name.reuseCacheMask(except: ECOCookieConfig.cookieExceptMaskCharacters))
                        .addCategoryValue("domain", cookie.domain)
                        .flush()
                    return nil
                }
            })
    }

    func cookies(for url: URL) -> [HTTPCookie] {
        Self.logger.info("read cookies", additionalData: [
            "isolate_id": "\(identifier)",
            "url_domain": url.host ?? ""
        ])
        if let maskURL = url.convertHost(handler: addMask) {
            let maskCookies = global.cookies(for: maskURL)
            return maskCookies.compactMap({ cookie in
                if let convertCookie = cookie.convertDomain(handler: removeMask) {
                    return convertCookie
                } else {
                    OPMonitor(ECOCookieMonitorCode.domain_convert_failed)
                        .addCategoryValue("isolate_id", identifier)
                        .addCategoryValue("url_domain", url.host)
                        .addCategoryValue("remove", true)
                        .addCategoryValue("name", cookie.name.reuseCacheMask(except: ECOCookieConfig.cookieExceptMaskCharacters))
                        .addCategoryValue("domain", cookie.domain)
                        .flush()
                    return nil
                }
            })
        } else {
            OPMonitor(ECOCookieMonitorCode.domain_convert_failed)
                .addCategoryValue("isolate_id", identifier)
                .addCategoryValue("url_domain", url.host)
                .addCategoryValue("remove", false)
                .flush()
            return []
        }
    }

    func saveCookies(_ cookies: [HTTPCookie], url: URL?) {
        Self.logger.info("save cookies", additionalData: [
            "isolate_id": "\(identifier)",
            "domains": "\(cookies.map({ $0.domain }))",
            "names": "\(cookies.map({ $0.name.reuseCacheMask(except: ECOCookieConfig.cookieExceptMaskCharacters) }))"
        ])
        let maskURL = url?.convertHost(handler: addMask)
        let maskCookies = cookies.compactMap({ $0.convertDomain(handler: addMask) })
        global.saveCookies(maskCookies, url: maskURL)
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

    private func addMask(_ originDomain: String) -> String {
        if originDomain.hasSuffix(domainSuffix) {
            assertionFailure("origin domain already have suffix.")
            OPMonitor(ECOCookieMonitorCode.domain_convert_failed)
                .addCategoryValue("isolate_id", identifier)
                .addCategoryValue("remove", false)
                .addCategoryValue("domain", originDomain)
                .flush()
        }
        return originDomain + domainSuffix
    }

    private func removeMask(_ maskDomain: String) -> String {
        if maskDomain.hasSuffix(domainSuffix) {
            return String(maskDomain.dropLast(domainSuffix.count))
        } else {
            assertionFailure("mask domain has no match suffix.")
            OPMonitor(ECOCookieMonitorCode.domain_convert_failed)
                .addCategoryValue("isolate_id", identifier)
                .addCategoryValue("remove", true)
                .addCategoryValue("domain", maskDomain)
                .flush()
            return maskDomain
        }
    }
}
