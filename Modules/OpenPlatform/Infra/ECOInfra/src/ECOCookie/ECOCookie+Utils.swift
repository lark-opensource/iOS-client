//
//  ECOCookie+Utils.swift
//  ECOInfra
//
//  Created by Meng on 2021/2/18.
//

import Foundation
import ECOProbe
import LarkContainer
import CryptoSwift

extension OPMonitor {
    @Provider private static var dependency: ECOCookieDependency // Global

    @discardableResult
    func setGadgetId(_ gadgetId: GadgetCookieIdentifier) -> OPMonitor {
        return Self.dependency.setGadgetId(gadgetId, for: self)
    }
}

extension GadgetCookieIdentifier {
    /// Cookie 隔离后缀
    private var isolateSuffix: String {
        return "gadget.lark"
    }

    /// Cookie 隔离 identifier, User + App 维度
    ///
    /// URL domain 最大长度为 256，隔离后缀取 appId-md5-prefix8.userId-md5-suffix8.gadget.lark
    ///
    func isolateIdentifier(uid: String) -> String {
        assert(!uid.isEmpty)
        let appIdHash = String(appID.md5().prefix(8))
        let userIdHash = String(uid.md5().suffix(8))
        return appIdHash + "." + userIdHash + "." + isolateSuffix
    }
}

extension URL {
    /// 转换 URL 的 host
    func convertHost(handler: (String) -> String) -> URL? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: true)
        let urlHost = components?.host ?? ""
        components?.host = handler(urlHost)
        return components?.url
    }
}

extension HTTPCookie {
    /// 转换 Cookie 的 domain，包含 originURL 的 host 及 domain 本身
    func convertDomain(handler: (String) -> String) -> HTTPCookie? {
        guard let domain = properties?[.domain] as? String,
              var convertProperties = properties else {
            return nil
        }
        convertProperties[.domain] = handler(domain)
        if let originURL = convertProperties[.originURL] as? URL {
            convertProperties[.originURL] = originURL.convertHost(handler: handler)
        }
        if let originURLStr = convertProperties[.originURL] as? String,
           let originURL = URL(string: originURLStr) {
            convertProperties[.originURL] = originURL.convertHost(handler: handler)
        }
        return HTTPCookie(properties: convertProperties)
    }
}
