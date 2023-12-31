//
//  OpenPlatformThirdRateBusinessViewControllerHandler.swift
//  LarkAppCenter
//
//  Created by 武嘉晟 on 2020/2/27.
//

import EENavigator
import RxSwift
import Swinject
import EEMicroAppSDK
import LarkFeatureGating
import LarkSetting
import LarkOPInterface
import LarkNavigator

/// 这整个文件都是拷贝的老代码，开放平台第三方业务的页面的路由的相关的注册都在这个文件
class AppDetailHandler: UserTypedRouterHandler {

    func handle(_ body: AppDetailBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        if body.appId.isEmpty, body.botId.isEmpty {
            res.end(error: RouterError.invalidParameters("body.botId and body.appId"))
            return
        } else {
            let detailModel = try AppDetailViewModel(
                appId: body.appId, botId: body.botId, params: body.params,
                scene: body.scene, chatID: body.chatID, resolver: userResolver
            )
            let controller = AppDetailViewController(detailModel: detailModel, resolver: userResolver)
            res.end(resource: controller)
        }
    }
}

class AppDetailPatternHandler: UserRouterHandler {
    public static let pattern = "//client/app_profile"
    /// 飞书路由回调
    public func handle(req: EENavigator.Request, res: Response) throws {
        let appId = req.parameters["appId"] as? String ?? ""
        let botId = req.parameters["botId"] as? String ?? ""
        if appId.isEmpty, botId.isEmpty {
            res.end(error: RouterError.invalidParameters("body.botId and body.appId"))
        } else {
            /// 机器人 & 小程序profile页
            let detailModel = try AppDetailViewModel(
                appId: appId, botId: botId, params: [:], scene: nil, chatID: nil, resolver: userResolver
            )
            let controller = AppDetailViewController(detailModel: detailModel, resolver: userResolver)
            res.end(resource: controller)
        }
    }
}

class AppSettingHandler: UserTypedRouterHandler {

    func handle(_ body: AppSettingBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        if body.appId.isEmpty, body.botId.isEmpty {
            res.end(error: RouterError.invalidParameters("body.botId and body.appId"))
            return
        } else {
            let controller = try AppSettingViewController(
                botId: body.botId, appId: body.appId, params: body.params, scene: body.scene, resolver: userResolver
            )
            res.end(resource: controller)
        }
    }
}

class ApplyForUseHandler: UserTypedRouterHandler {

    func handle(_ body: ApplyForUseBody, req: EENavigator.Request, res: EENavigator.Response) {
        if body.appId == nil, body.botId == nil {
            res.end(error: RouterError.invalidParameters("body.appId or body.botId"))
            return
        } else {
            // https://app.feishu.cn/napi/app-apply?appId=xxx&botId=xxx
            let host = AppDetailUtils(resolver: userResolver).internalDependency?.host(for: .openAppstore)
            var urlComponets = URLComponents()
            urlComponets.scheme = "https"
            urlComponets.host = host
            urlComponets.path = "/napi/app-apply"
            var queryItems: [URLQueryItem] = []
            queryItems.append(URLQueryItem(name: "appId", value: body.appId))
            queryItems.append(URLQueryItem(name: "botId", value: body.botId))
            
            urlComponets.queryItems = queryItems
            
            if let url = urlComponets.url {
                res.redirect(url, context: req.context)
            } else {
                res.end(error: RouterError.invalidParameters("url"))
            }
        }
    }
}
