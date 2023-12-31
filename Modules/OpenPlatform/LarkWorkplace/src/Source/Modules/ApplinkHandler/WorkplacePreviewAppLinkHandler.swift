//
//  WorkplacePreviewAppLinkHandler.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/10/11.
//

import Foundation
import LarkAppLinkSDK
import LKCommonsLogging
import EENavigator
import LarkNavigator
import LarkNavigation
import LarkTab
import LarkUIKit
import LarkContainer

/// 模版化工作台预览 Applink handler
///
/// Applink: /client/workplace/preview
struct WorkplacePreviewAppLinkHandler {
    static let logger = Logger.log(WorkplacePreviewAppLinkHandler.self)

    static let pattern = "/client/workplace/preview"

    static func handle(applink: AppLink) {
        Self.logger.info("start handle workplace preview applink", additionalData: [
            "url": applink.url.absoluteString,
            "hasFrom": "\(applink.context?.from() != nil)"
        ])
        guard let from = applink.context?.from() else { return }

        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: WorkplaceScope.userScopeCompatibleMode)
        let navigator = userResolver.navigator

        // applink 参数解析
        var queryParameters: [String: String] = [:]
        if let components = URLComponents(url: applink.url, resolvingAgainstBaseURL: false),
            let queryItems = components.queryItems {
            queryItems.forEach({ queryParameters[$0.name] = $0.value })
        }

        guard let token = queryParameters["token"] else {
            Self.logger.error("workplace preview applink has no token")
            return
        }

        let previewBody = WorkplacePreviewBody(token: token)
        navigator.showAfterSwitchIfNeeded(
            tab: Tab.appCenter.url,
            body: previewBody,
            wrap: LkNavigationController.self,
            from: from,
            completion: { error in
                Self.logger.error("workplace preview route failed", error: error)
            }
        )
    }
}
