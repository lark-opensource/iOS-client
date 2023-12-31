//
//  AppStateSDK+Bot.swift
//  LarkAppStateSDK
//
//  Created by Meng on 2020/11/23.
//

import Foundation
import RustPB
import RxSwift
import LarkRustClient
import LarkOPInterface
import LKCommonsLogging
import LarkNavigation
import RoundedHUD
import EEMicroAppSDK
import LarkContainer

public typealias BotLinkAccessHandler = (Bool, String?) -> Void

/// Bot AppLink应用机制处理逻辑
public protocol BotLinkStateEventListener: AnyObject {
    func onOpenBot(appId: String, accessHandler: @escaping BotLinkAccessHandler)
}

class BotLinkStateEventListenerImpl: BotLinkStateEventListener {
    private typealias BotRequest = RustPB.Openplatform_V1_GetBotControlInfoRequest
    private typealias BotResponse = RustPB.Openplatform_V1_GetBotControlInfoResponse

    static let logger = Logger.log(BotLinkStateEventListener.self, category: "BotLinkStateEventListener")
    private let disposeBag = DisposeBag()
    private let resolver: UserResolver

    private let rustService: RustService
    
    init(resolver: UserResolver) throws {
        self.resolver = resolver
        rustService = try resolver.resolve(assert: RustService.self)
    }

    func onOpenBot(appId: String, accessHandler: @escaping BotLinkAccessHandler) {
        Self.logger.info("BotLinkStateEventListener:start check bot control access", additionalData: ["appId": "\(appId)"])
        let hud = RoundedHUD.showLoading(on: RootNavigationController.shared.view)
        let resultHandler: (Bool, String?) -> Void = { result, botId in
            hud.remove()
            accessHandler(result, botId)
        }
        // 优先获取本地数据并处理
        var request = BotRequest()
        request.id = .appID(appId)
        request.strategy = .localOnly
        Self.logger.info("BotLinkStateEventListener: bot(\(appId)) start to request stateInfo with strategy local")
        rustService.sendAsyncRequest(request)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self](response: BotResponse) in
                Self.logger.info("BotLinkStateEventListener:did get local bot control response")
                OPMonitor(name: AppStateDefines.monitorName, code: EPMClientOpenPlatformAppStrategyCode.bot_state_success)
                    .setResultTypeSuccess()
                    .addCategoryValue("appID", appId)
                    .addCategoryValue("strategy", "local")
                    .flush()
                self?.handleBotControlInfo(
                    appId: appId,
                    request: request,
                    response: response,
                    accessHandler: resultHandler
                )
            }, onError: { (error) in
                Self.logger.error("BotLinkStateEventListener:get local bot control failed", error: error)
                OPMonitor(name: AppStateDefines.monitorName, code: EPMClientOpenPlatformAppStrategyCode.bot_state_fail)
                    .setResultTypeFail()
                    .addCategoryValue("appID", appId)
                    .addCategoryValue("strategy", "local")
                    .setError(error)
                    .flush()
                RoundedHUD.opShowFailure(
                    with: BundleI18n.LarkAppStateSDK.Lark_OpenPlatform_NetworkErrMsg
                )
                resultHandler(false, nil)
            })
            .disposed(by: disposeBag)
    }

    private func handleBotControlInfo(appId: String,
        request: BotRequest, response: BotResponse,
        accessHandler: @escaping BotLinkAccessHandler
    ) {
        // 不论本地结果如何，都会触发一次remote数据拉取刷新
        var refreshReq = request
        refreshReq.strategy = .netOnly

        if response.hasBotInfo
            && response.botInfo.hasBotID
            && response.botInfo.status == .usable {
            handleAccessForBot(response: response, accessHandler: accessHandler)
            Self.logger.info("BotLinkStateEventListener:bot localCache for App is useable, request from network")
            rustService.sendAsyncRequest(refreshReq).subscribe(onNext: { _ in
                OPMonitor(name: AppStateDefines.monitorName, code: EPMClientOpenPlatformAppStrategyCode.bot_state_success)
                    .setResultTypeSuccess()
                    .addCategoryValue("appID", appId)
                    .addCategoryValue("strategy", "network")
                    .flush()
            }, onError: { error in
                OPMonitor(name: AppStateDefines.monitorName, code: EPMClientOpenPlatformAppStrategyCode.bot_state_fail)
                    .setResultTypeFail()
                    .addCategoryValue("appID", appId)
                    .addCategoryValue("strategy", "network")
                    .setError(error)
                    .flush()
            }).disposed(by: disposeBag)
        } else {
            Self.logger.info("BotLinkStateEventListener:bot localCache for App is unAvailable, request from network")
            rustService
                .sendAsyncRequest(refreshReq)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self](response: BotResponse) in
                    Self.logger.info("did get remote bot control response")
                    OPMonitor(name: AppStateDefines.monitorName, code: EPMClientOpenPlatformAppStrategyCode.bot_state_success)
                        .setResultTypeSuccess()
                        .addCategoryValue("appID", appId)
                        .addCategoryValue("strategy", "network")
                        .flush()
                    self?.handleAccessForBot(response: response, accessHandler: accessHandler)
                }, onError: { error in
                    OPMonitor(name: AppStateDefines.monitorName, code: EPMClientOpenPlatformAppStrategyCode.bot_state_fail)
                        .setResultTypeFail()
                        .addCategoryValue("appID", appId)
                        .addCategoryValue("strategy", "network")
                        .setError(error)
                        .flush()

                    Self.logger.error("get remote bot control failed", error: error)
                    RoundedHUD.opShowFailure(
                        with: BundleI18n.LarkAppStateSDK.Lark_OpenPlatform_NetworkErrMsg
                    )
                    accessHandler(false, nil)
                })
                .disposed(by: disposeBag)
        }
    }

    private func handleAccessForBot(
        response: BotResponse, accessHandler: @escaping BotLinkAccessHandler
    ) {
        Self.logger.info("check bot access", additionalData: [
            "hasBotInfo": "\(response.hasBotInfo)",
            "hasBotID": "\(response.botInfo.hasBotID)",
            "useable": "\(response.botInfo.status == .usable)",
            "botID": "\(response.botInfo.botID)"
        ])

        if response.hasBotInfo
            && response.botInfo.hasBotID
            && response.botInfo.status == .usable {
            accessHandler(true, response.botInfo.botID)
        } else {
            accessHandler(false, nil)
            GuideTipHandler(resolver: resolver).presentAlert(
                appId: response.botInfo.appID,
                appName: response.botInfo.localName,
                tip: response.tips,
                appType: .bot
            )
        }
    }
}
