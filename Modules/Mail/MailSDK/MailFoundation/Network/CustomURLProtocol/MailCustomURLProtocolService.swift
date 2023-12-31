//
//  MailCustomURLProtocolService.swift
//  MailSDK
//
//  Created by majx on 2019/6/21 from DocSDK
//

import Foundation
import WebKit

enum MailCustomScheme: String, CaseIterable {
    case cid = "cid"
    case mailAttachmentIcon = "mail-attachment-icon"
    case token = "token" // 读信页替换成token去加载图片
    case coverTokenThumbnail = "mail-cover-thumbnail"
    case coverTokenFull = "mail-cover-full"
    case https = "https"
    case http = "http"
    case template = "template"

    func makeSchemeHandler(provider: MailSharedServicesProvider?) -> WKURLSchemeHandler{
        switch self {
        case .cid, .mailAttachmentIcon, .token, .coverTokenThumbnail, .coverTokenFull, .template:
            return MailCustomSchemeHandler(provider: provider)
        case .https, .http:
            return MailNewCustomSchemeHandler(downloader: MailHttpSchemeDownloader(cacheService: provider?.cacheService))
        }
    }
}

// MARK: - 自定义协议服务支持
final class MailCustomURLProtocolService {
    private static let shouldInterceptHttp = FeatureManager.open(FeatureKey.init(fgKey: .interceptWebViewHttp, openInMailClient: true))
    /// 当前支持的协议
    static let schemes = getHandledSchemes()
    
    /// 是否属于支持的协议
    class func isSupportScheme(_ schemeStr: String?) -> Bool {
        if let schemeStr = schemeStr, let scheme = MailCustomScheme(rawValue: schemeStr) {
            return MailCustomURLProtocolService.schemes.contains(scheme)
        }
        return false
    }
    
    private static func getHandledSchemes() -> Set<MailCustomScheme> {
        if MailCustomURLProtocolService.shouldInterceptHttp {
            MailLogger.info("MailCustomProtocol interceptWebViewHttp fg open")
            if WKWebView.handlesURLScheme("http") && WKWebView.handlesURLScheme("https") {
                MailLogger.info("MailCustomProtocol interceptWebViewHttp try enable")
                let result = WKWebView.enableHttpIntercept()
                MailLogger.info("MailCustomProtocol interceptWebViewHttp try enable \(result)")
            }
        }
        
        // 对 handlesURLScheme return true 的case，WebKit会抛异常，此处进行过滤
        let toIntercept = Set(MailCustomScheme.allCases).filter({ !WKWebView.handlesURLScheme($0.rawValue) })
        MailLogger.info("MailCustomProtocol toIntercept \(toIntercept)")
        return toIntercept
    }

    /// 自定义 Session
    private var dataSession: MailSchemeDataSession?
    private static let handledKey = String(describing: MailCustomURLProtocolService.self) + "_handleKey"
}
