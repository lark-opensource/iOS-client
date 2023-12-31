//
//  AppShareLink.swift
//  LarkOpenPlatform
//
//  Created by Meng on 2020/11/23.
//

import Foundation
import LarkAppLinkSDK
import Swinject
import LarkContainer
import LKCommonsLogging
import RxSwift
import EENavigator
import RoundedHUD
import LarkFeatureGating
import LarkOPInterface
import OPFoundation
/// 应用分享AppLink处理逻辑
/// /client/app_share/open?app_id={app_id}
class AppShareLinkHandler {
    static let logger = Logger.log(AppShareLinkHandler.self, category: "AppShareLinkHandler")

    func handle(applink: AppLink, resolver: UserResolver) {
        OPMonitor("applink_handler_start").setAppLink(applink).flush()
        let queryParameters = applink.url.queryParameters
        OPMonitor(EPMClientOpenPlatformShareCode.share_applink_start)
            .addCategoryValue("app_id", queryParameters["appId"])
            .flush()
        guard let appId = queryParameters["appId"] else {
            RoundedHUD.opShowFailure(
                with: BundleI18n.LarkOpenPlatform.Lark_OpenPlatform_ParamMissingMsg(list: "appId")
            )
            OPMonitor(EPMClientOpenPlatformShareCode.share_applink_verify_failed)
                .addCategoryValue("param_name", "appId")
                .flush()
            return
        }
        let body = OPOpenShareAppBody(appId: appId, path: "/client/app_share/open", appLinkTraceId: applink.traceId)
        if let fromVC = applinkFrom(appLink: applink) {
            if let routercontext = applink.context, resolver.fg.dynamicFeatureGatingValue(with: "openplatform.applink.shareapp.touter.h5.context") {
                // 修复从Launchermore面板点击应用商店添加的应用路由参数丢失的问题
                resolver.navigator.push(body: body, context: routercontext, from: fromVC)
            } else {
                resolver.navigator.push(body: body, from: fromVC)
            }
        } else {
            Self.logger.error("AppShareLinkHandler handle applink can not push vc because no fromViewController")
        }
    }
}
