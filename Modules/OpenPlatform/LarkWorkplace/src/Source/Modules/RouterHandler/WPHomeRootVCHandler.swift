//
//  WPHomeRootVCHandler.swift
//  LarkWorkplace
//
//  Created by ByteDance on 2023/2/21.
//

import Foundation
import EENavigator
import Swinject
import LKCommonsLogging
import LarkSceneManager
import LarkUIKit
import LarkTab
import LarkSetting
import LarkNavigator
import LarkContainer

struct WPHomeRootBody: CodableBody {
    static let prefix = "//client/workplace/open"

    static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)", type: .path)
    }

    var _url: URL {
        return URL(string: Self.prefix)!
    }

    let originUrl: URL

    init(originUrl: URL) {
        self.originUrl = originUrl
    }
}

/// 工作台 AppLink 跳转能力
/// TODO: 这个行为和命名不是很匹配，需要整理下
final class WPHomeRootVCHandler: UserTypedRouterHandler {
    static let logger = Logger.log(WPHomeRootVCHandler.self)

    static func compatibleMode() -> Bool { WorkplaceScope.userScopeCompatibleMode }

    func handle(_ body: WPHomeRootBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        let configService = try userResolver.resolve(assert: WPConfigService.self)
        Self.logger.info("handle workplace applink")
        
        // applink 参数解析
        var queryParameters: [String: String] = [:]
        if let components = URLComponents(url: body.originUrl, resolvingAgainstBaseURL: false),
            let queryItems = components.queryItems {
            /// 从URL解析规则上来，如果query同名，前面的优先级比较高，因此需要把queryItems reversed
            /// eg./client/workplace/open?id=tpl_xxxx&path=html/Query.html&yyy=2&yyy=abc,最后解出来的queryitems应该是[id: tpl_xxxx, path:html/Query.html, yyy:2]
            queryItems.reversed().forEach({ queryParameters[$0.name] = $0.value })
        }

        guard !queryParameters.isEmpty else {
            // applink没有带query，不做任何处理
            Self.logger.info("applink home has no query parameters")
            res.end(resource: nil)
            return
        }

        let portalId = queryParameters["id"]
        let path = queryParameters["path_ios"] ?? queryParameters["path"]
        let pathAndroid = queryParameters["path_android"]
        let pathPc = queryParameters["path_pc"]
        if portalId == nil && path == nil && pathAndroid == nil && pathPc == nil {
            Self.logger.info("applink home has no id or path parameters")
            // applink没有带支持的参数，不做任何处理
            // 此处是为了防止extension applink带上自定的埋点参数
            res.end(resource: nil)
            return
        }

        guard let vc = navigator.navigation?.animatedTabBarController?.viewController(for: .appCenter)?.tabRootViewController as? WPHomeRootVC else {
            Self.logger.error("handle workplace home root vc route, cannot find vc")
            res.end(resource: nil)
            return
        }
        
        var encodePath = path?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        // 只判断有没有path参数，不判断encodePath.empty()
        // 如果有path参数但是path为空的情况，也需要替换原来H5门户首页的url path
        if encodePath != nil,
           !(encodePath?.starts(with:  "/") ?? true) {
           encodePath = "/" + encodePath!
        }
        
        let excludedKeys = [
            "id",
            "path_ios",
            "path",
            "path_android",
            "path_pc"
        ]
        var filteredQueryItems: [String: String] = queryParameters.filter { (key, value) in
            return !excludedKeys.contains(key)
        }
        
        var queryItems: [URLQueryItem] = []
        var queryItemDic: [String: String] = [:]
        if let pathWithQuery = encodePath,
           let urlComponents = URLComponents(string: pathWithQuery) {
            // 有path参数的情况下才会加上applink携带的其他参数
            // eg.https://applink.feishu.cn/client/workplace/open?id=tpl_xxxx&a=2&a=1 ，这种情况访问H5门户不会加上a=1这个query
            encodePath = urlComponents.path
            urlComponents.queryItems?.forEach({
                queryItemDic[$0.name] = $0.value
            })
            
            // applink &带的参数会被append到queryItems里，外层的query的参数优先级会高于path里带的参数
            // eg.https://applink.feishu.cn/client/workplace/open?id=tpl_xxxx&a=2&path=/path?a=1, 这种case下path：/path，queryItem：[a:2]
            queryItemDic.merge(filteredQueryItems) { _, last in last }
            
            queryItems = queryItemDic.compactMap({ (key, value) in
                return URLQueryItem(name: key, value: value)
            })
        }
        
        Self.logger.info("handle workplace home root vc route", additionalData: [
            "id" : portalId ?? "",
            "path": encodePath ?? ""
        ].merging(queryItemDic, uniquingKeysWith: { first, _ in first }))
        
        vc.handleApplinkRoute(
            portalId: portalId,
            path: encodePath,
            queryItems: queryItems
        )
        res.end(resource: nil)
    }
}
