//
//  AppApplyAppLinkHandler.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/4/27.
//

import Foundation
import LKCommonsLogging
import LarkNavigator
import LarkContainer
import EENavigator
import LarkAppLinkSDK
import Blockit
import LarkOPInterface

/// 应用可见性申请: /client/app_apply_visibility/open
/// TODO: 这个应该不属于工作台业务，需要迁移
struct AppApplyAppLinkHandler {
    static let logger = Logger.log(AppApplyAppLinkHandler.self)

    static let pattern = "/client/app_apply_visibility/open"

    static func handle(applink: AppLink) {
        logger.info("start handle app apply applink", additionalData: ["url": applink.url.absoluteString])
        guard let from = applink.context?.from() else { return }
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: WorkplaceScope.userScopeCompatibleMode)
        let navigator = userResolver.navigator
        let url = applink.url

        let params = url.queryParameters
        let appID = params["appId"] ?? ""
        let appName = params["app_name"] ?? ""

        let body = ApplyForUseBody(appId: appID, appName: appName)
        navigator.push(body: body, from: from)
    }
}

