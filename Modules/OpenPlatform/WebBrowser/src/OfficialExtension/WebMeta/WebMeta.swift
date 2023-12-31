//
//  WebMeta.swift
//  WebBrowser
//
//  Created by yinyuan on 2022/1/19.
//

import Foundation
import LKCommonsLogging

private let logger = Logger.webBrowserLog(LKMeta.self, category: "LKMeta")

/// 规划详见: https://bytedance.feishu.cn/wiki/wikcnh47uHK1d5bH9vSzspLYXIc
/// 需要注意，如果新增不适合日志的数据（例如敏感信息），应当重写其 description 函数避免被打印
public struct LKMeta: Decodable {
    let viewMeta: WebMeta?
    
    let pageMeta: WebMeta?
    
    enum CodingKeys: String, CodingKey {
        case pageMeta = "page-meta"
        case viewMeta = "view-meta"
    }
}

/// 规划详见: https://bytedance.feishu.cn/wiki/wikcnh47uHK1d5bH9vSzspLYXIc
/// 需要注意，如果新增不适合日志的数据（例如敏感信息），应当重写其 description 函数避免被打印
public struct WebMeta: Decodable {
    var orientation: String?
    var fixsafearea: String?
    var hideMenuItems: String?
    var slideToClose: String?
    var showNavBar: String?
    var showNavRBarBtn: String?
    var showNavLBarBtn: String?
    var navBgColor: String?
    var navFgColor: String?
    var hideNavBarItems: String?
    var shareLink: String?
    var showBottomNavBar: String?
    var allowBackForwardGestures: String?
}

public final class WebMetaTrackModel {
    var orientationSource: String?
}



extension LKMeta {
    
    /// 从 URL 中解析 Meta
    /// - Parameter url: 如果 url 为空，将解析出空的 LKMeta
    /// - Returns: 如果 url 为空，或则不存在合法的 lk_meta 参数，将返回空的 LKMeta
    static func resolveMeta(url: URL?) -> LKMeta? {
        var lkMeta: LKMeta?
        if let url = url {
            if let urlComponent = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                if let json = urlComponent.queryItems?.first(where: { item in
                    item.name == "lk_meta"
                })?.value {
                    if let data = json.data(using: .utf8) {
                        do {
                            logger.info("handle lk_meta query")
                            lkMeta = try JSONDecoder().decode(LKMeta.self, from: data)
                        } catch {
                            logger.error("lk_meta decode error.", tag: "WebMeta", additionalData: nil, error: error)
                        }
                    } else {
                        logger.warn("invalid lk_meta data")
                    }
                }
            } else {
                logger.warn("invalid url components")
            }
        } else {
            logger.info("url is nil")
        }
        return lkMeta
    }
}

