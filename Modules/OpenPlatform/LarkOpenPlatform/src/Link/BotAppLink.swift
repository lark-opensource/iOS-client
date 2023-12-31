//
//  BotAppLink.swift
//  LarkOpenPlatform
//
//  Created by Meng on 2020/11/23.
//

import Foundation
import LarkAppLinkSDK
import Swinject
import LarkSDKInterface
import RustPB
import LarkContainer
import LarkAppStateSDK
import RxSwift
import LarkMessengerInterface
import EENavigator
import LKCommonsLogging
import LarkOPInterface
import RoundedHUD

/// Bot Applink 处理逻辑
/// /client/bot/open?app_id={app_id}
class BotAppLinkHandler {
    static let logger = Logger.log(BotAppLinkHandler.self, category: "BotAppLinkHandler")

    func handle(applink: AppLink, resolver: UserResolver) {
        let queryParameters = applink.url.queryParameters
        Self.logger.info("start handle bot applink", additionalData: [
            "appId": "\(queryParameters["appId"] ?? "")"
        ])
        guard let appId = queryParameters["appId"] else {
            RoundedHUD.opShowFailure(
                with: BundleI18n.LarkOpenPlatform.Lark_OpenPlatform_ParamMissingMsg(list: "appId")
            )
            return
        }

        let body = OPOpenShareAppBody(appId: appId, ability: .bot)
        if let fromVC = applinkFrom(appLink: applink) {
            resolver.navigator.push(body: body, from: fromVC)
        } else {
            Self.logger.error("BotAppLinkHandler handle applink can not push vc because no fromViewController")
        }
    }
}
