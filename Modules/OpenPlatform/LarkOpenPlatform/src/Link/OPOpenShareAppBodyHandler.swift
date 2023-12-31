//
//  H5AppHandler.swift
//  LarkOpenPlatform
//
//  Created by Meng on 2020/11/26.
//

import Foundation
import EENavigator
import Swinject
import LarkContainer
import RxSwift
import LKCommonsLogging
import LarkNavigation
import LarkAppStateSDK
import LarkOPInterface
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkUIKit
import AnimatedTabBar
import RoundedHUD
import Reachability
import LarkMicroApp
import LarkNavigator
import LarkFoundation
import OPFoundation
import SwiftyJSON

/// 常驻Handler，处理打开应用的各种能力
class OPOpenShareAppBodyHandler: UserTypedRouterHandler {
    static let logger = Logger.log(OPOpenShareAppBodyHandler.self, category: "OPOpenShareAppBodyHandler")

    private struct Context {
        let req: EENavigator.Request
        let res: EENavigator.Response
    }

    @ScopedProvider
    private var accountService: PassportUserService?
    
    @ScopedProvider
    private var client: OpenPlatformHttpClient?
    
    @ScopedProvider
    private var chatService: ChatService?
    
    private let disposeBag = DisposeBag()
    
    private static var service: ECONetworkService {
        return Injected<ECONetworkService>().wrappedValue
    }

    func handle(_ body: OPOpenShareAppBody, req: EENavigator.Request, res: EENavigator.Response) {
        let context = Context(req: req, res: res)
        Self.logger.info("handle open app", additionalData: [
            "appId": "\(body.appId)",
            "ability": "\(body.ability?.rawValue ?? "")"
        ])
        let appId = body.appId
        if let ability = body.ability {
            OPMonitor(EPMClientOpenPlatformShareCode.share_applink_open_ability)
                .addCategoryValue("app_id", appId)
                .addCategoryValue("ability_type", ability.rawValue)
                .flush()
            switch ability {
            case .gadget:
                openGadget(body: body, context: context)
            case .h5:
                openH5(body: body, context: context)
            case .bot:
                openBot(body: body, context: context)
            }
        } else {
            openAppDefault(body: body, context: context)
        }
    }

    /// 使用appId打开应用小程序能力
    private func openGadget(body: OPOpenShareAppBody, context: Context) {
        var microBody = MicroAppBody(appId: body.appId)
        microBody.isShareLink = true
        OPMonitor("applink_handler_success")
            .addCategoryValue("path", body.path)
            .addCategoryValue("app_id", body.appId)
            .addCategoryValue("applink_trace_id", body.appLinkTraceId)
            .flush()

        context.res.redirect(body: microBody)
    }

    /// 使用appId打开H5能力
    private func openH5(body: OPOpenShareAppBody, context: Context) {
        let tenantId = accountService?.userTenant.tenantID ?? ""
        let cachekey = H5ApplinkHandler.H5ApplinkCacheKeyPrefix(h5AppID: body.appId) + tenantId
        // 临时方案，H5App实现逻辑需要改造
        // 最终应当与 H5ApplinkHandler, H5App 做通用逻辑整合
        H5App(
            resolver: userResolver,
            appId: body.appId,
            urlParameters: [H5ApplinkHandler.urlParamAppIdKey: body.appId],
            cacheKey: cachekey,
            path: body.path,
            appLinkTraceId: body.appLinkTraceId,
            routerContext: context.req.context
        )
        .open(with: userResolver, openType: .push, from: context.req.from, fromScene: .app_share_applink)
        context.res.end(resource: EmptyResource())
    }

    /// 使用appId打开应用Bot能力
    private func openBot(body: OPOpenShareAppBody, context: Context) {
        guard let botEventListener = try? userResolver.resolve(assert: BotLinkStateEventListener.self) else {
            Self.logger.error("BotLinkStateEventListener impl is nil")
            return
        }
        botEventListener.onOpenBot(appId: body.appId) { [weak self](access, botId) in
            self?.handleOpenBot(access: access, botId: botId, context: context, body: body)
        }
        context.res.wait()
    }

    /// 处理默认app打开能力
    private func openAppDefault(body: OPOpenShareAppBody, context: Context) {
        let onError: (Error) -> Void = { error in
            Self.logger.error("get share app info error: \(error)")
            OPMonitor(EPMClientOpenPlatformShareCode.share_get_app_info_failed)
                .addCategoryValue("appId", body.appId)
                .setError(error)
                .flush()
            DispatchQueue.main.async {
                RoundedHUD.opShowFailure(with: BundleI18n.LarkOpenPlatform.Lark_OpenPlatform_NetworkErrMsg)
                context.res.end(resource: nil)
            }
        }
        let onSuccess: (GetShareAppInfoResponse) -> Void = { [weak self] response in
            Self.logger.error("get share app info success")
            OPMonitor(EPMClientOpenPlatformShareCode.share_get_app_info_success)
                .addCategoryValue("appId", body.appId)
                .flush()
            DispatchQueue.main.async {
                self?.handleOpenAppDefault(with: response, context: context, body: body)
            }
        }
        if OPNetworkUtil.basicUseECONetworkEnabled() {
            guard let url = OPNetworkUtil.getShareAppInfoURL() else {
                Self.logger.error("get share app info url failed")
                return
            }
            var header: [String: String] = [APIHeaderKey.Content_Type.rawValue: "application/json"]
            if let userService = try? userResolver.resolve(assert: PassportUserService.self) {
                let sessionID: String? = userService.user.sessionKey
                header[APIHeaderKey.X_Session_ID.rawValue] = sessionID
            }
            let platform = Display.pad ? PlatformType.iPad : PlatformType.iphone
            let params: [String: Any] = [APIParamKey.lark_version.rawValue: Utils.appVersion,
                                         APIParamKey.cli_id.rawValue: body.appId,
                                         APIParamKey.platform.rawValue: platform.rawValue,
                                         APIParamKey.locale.rawValue: OpenPlatformAPI.curLanguage()]
            let networkContext = OpenECONetworkContext(trace: OPTrace(traceId: body.appLinkTraceId ?? ""), source: .other)
            let completionHandler: (ECOInfra.ECONetworkResponse<[String: Any]>?, ECOInfra.ECONetworkError?) -> Void = { [weak self] response, error in
                if let error = error {
                    onError(error)
                    return
                }
                guard let self = self else {
                    let error = "get share app info failed because self is nil"
                    let nsError = NSError(domain: error, code: -1, userInfo: nil)
                    onError(nsError)
                    return
                }
                let logID = OPNetworkUtil.reportLog(Self.logger, response: response)
                guard let response = response,
                      let result = response.result else {
                    let error = "get share app info failed because response or result is nil"
                    let nsError = NSError(domain: error, code: -1, userInfo: nil)
                    onError(nsError)
                    return
                }
                let json = JSON(result)
                let obj = GetShareAppInfoResponse(json: json, api: OpenPlatformAPI(path: .empty, resolver: self.userResolver))
                obj.lobLogID = logID
                onSuccess(obj)
            }
            let task = Self.service.post(url: url, header: header, params: params, context: networkContext, requestCompletionHandler: completionHandler)
            if let task = task {
                Self.service.resume(task: task)
            } else {
                Self.logger.error("get share app info url econetwork task failed")
            }
            context.res.wait()
            return
        }
        
        guard let client = self.client else {
            Self.logger.error("PlatformHttpClient impl is nil")
            return
        }
        client
            .request(api: .getShareAppInfoAPI(appId: body.appId, resolver: userResolver))
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (response: GetShareAppInfoResponse) in
                onSuccess(response)
            }, onError: { error in
                onError(error)
            })
            .disposed(by: disposeBag)
        context.res.wait()
    }
}

extension OPOpenShareAppBodyHandler {
    private func handleOpenBot(access: Bool, botId: String?, context: Context, body: OPOpenShareAppBody) {
        Self.logger.info("handle bot open", additionalData: [
            "access": "\(access)",
            "botId": "\(botId ?? "")"
        ])
        // LarkAppStateSDK已经处理过弹窗兜底逻辑
        guard access, let botId = botId else {
            context.res.end(resource: nil)
            return
        }
        OPMonitor("applink_handler_success")
            .addCategoryValue("path", body.path)
            .addCategoryValue("app_id", botId)
            .addCategoryValue("applink_trace_id", body.appLinkTraceId)
            .flush()
        chatService?
            .createP2PChat(userId: botId, isCrypto: false, chatSource: nil)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (chat) in
                let body = ChatControllerByChatBody(chat: chat)
                context.res.redirect(body: body, naviParams: nil, context: [
                    FeedSelection.contextKey: FeedSelection(feedId: chat.id, selectionType: .skipSame)
                ])
            }, onError: { error in
                Self.logger.error("handle bot open failed", error: error)
                context.res.end(resource: nil)
            }).disposed(by: disposeBag)
    }

    private func handleOpenAppDefault(with res: GetShareAppInfoResponse, context: Context, body: OPOpenShareAppBody) {
        Self.logger.info("handle app ability open", additionalData: [
            "appId": "\(res.appId ?? "")",
            "abilities": "\(res.appAbility?.description ?? "")",
            "resultCode": "\(res.resultCode?.description ?? "")"
        ])
        guard let resultCode = res.resultCode else {
            context.res.end(resource: nil)
            return
        }
        guard resultCode.isSuccess else {
            switch resultCode {
            case .success:
                assertionFailure("success 已经判断过了，不应当走到这个逻辑")
            case .noApplication:
                RoundedHUD.opShowFailure(
                    with: BundleI18n.LarkOpenPlatform.Lark_OpenPlatform_PageUnavailableMsg
                )
            case .server(_):
                RoundedHUD.opShowFailure(
                    with: BundleI18n.LarkOpenPlatform.Lark_OpenPlatform_ServerErrMsg
                )
            }
            context.res.end(resource: nil)
            return
        }
        guard let appId = res.appId, let ability = res.appAbility else {
            if res.extra.supportPC {
                RoundedHUD.opShowFailure(
                    with: BundleI18n.OpenPlatformShare.OpenPlatform_AppCenter_OpenAppOnPC
                )
            } else {
                RoundedHUD.opShowFailure(
                    with: BundleI18n.LarkOpenPlatform.Lark_OpenPlatform_PageUnavailableMsg
                )
            }
            context.res.end(resource: nil)
            return
        }
        OPMonitor(EPMClientOpenPlatformShareCode.share_applink_open_ability)
            .addCategoryValue("app_id", appId)
            .addCategoryValue("ability_type", ability.rawValue)
            .flush()
        switch ability {
        case .gadget:
            openGadget(body: body, context: context)
        case .h5:
            openH5(body: body, context: context)
        case .bot:
            openBot(body: body, context: context)
        }
    }
}
