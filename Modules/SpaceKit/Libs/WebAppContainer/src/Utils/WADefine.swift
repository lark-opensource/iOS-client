//
//  WADefine.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/25.
//

import Foundation
import LarkFoundation

struct WAHttpDefine {
    
    enum Header: String {
        case contentLength = "Content-Length"
        case contentType = "Content-Type"
        case allowOrigin = "Access-Control-Allow-Origin"
        case allowMethods = "Access-Control-Allow-Methods"
        case allowCredentials = "Access-Control-Allow-Credentials"
        case cookie = "Cookie"
        case larkCacheFrom = "LKCacheFrom"
        case requestID = "request-id"
        case xttLogId = "x-tt-logid"
    }
    
    enum Consts: String {
        case httpVersion = "HTTP/1.1"
        case local = "local"
        case allowMethods = "POST, GET, OPTIONS, PUT, DELETE"
    }
    
    static var defaultWebViewUA: String = {
        let version = Utils.appVersion
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "unknown" //Utils.appName
        let language = (Locale.preferredLanguages.first ?? Locale.current.identifier).hasPrefix("zh") ? "zh" : "en"
        var ua = "Mozilla/5.0 (\(UIDevice.current.lu.modelName()); CPU \(UIDevice.current.systemName) \(UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "_")) like Mac OS X) AppleWebKit/604.4.7 (KHTML, like Gecko) Mobile/15C153  [\(language)] Bytedance FastWebApp \(appName)/\(version) "
        return ua
    }()
}


