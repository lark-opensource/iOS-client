//
//  OpenChatLinkHandler.swift
//  LarkOpenPlatform
//
//  Created by yinyuan on 2019/9/16.
//

import Foundation
import EENavigator
import RxSwift
import SwiftyJSON
import LKCommonsLogging
import LKCommonsTracker
import RoundedHUD
import LarkFeatureGating
import LarkMessengerInterface
import LarkAppLinkSDK
import Swinject
import LarkSDKInterface
import EEMicroAppSDK
import LarkOPInterface
import LarkContainer

class OpenChatLinkHandler {

    private static let logger = Logger.log(OpenChatLinkHandler.self, category: "OpenChatLinkHandler")
    /// 延迟释放bot会话打开相关
    private let disposeBag = DisposeBag()
    func handle(appLink: AppLink,
                httpClient: OpenPlatformHttpClient?,
                resolver: UserResolver) {
        guard let fromVC = applinkFrom(appLink: appLink) else {
            OpenChatLinkHandler.logger.error("handle applink can not find from viewcontroller")
            return
        }
        let queryParameters = appLink.url.queryParameters
        if let chatId = queryParameters["chatId"] {
            let position = Int32(queryParameters["position"] ?? "")
            let body = ChatControllerByIdBody(chatId: chatId, position: position)
            resolver.navigator.push(body: body, from: fromVC)
            OpenChatLinkHandler.postMonitor(success: true, type: "chat_id")
        } else if let openId = queryParameters["openId"], let client = httpClient {
            let hud = RoundedHUD.showLoading(on: fromVC.view, disableUserInteraction: true)
            client.request(api: OpenPlatformAPI.GetChatIdAPI(openId: openId, resolver: resolver))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (apiResponse: GetChatIdAPIResponse) in
                    hud.remove()
                    guard apiResponse.code == 0, let chatId = apiResponse.chatId else {
                        OpenChatLinkHandler.logger.error("request chatId error \(String(describing: apiResponse.code)) \(String(describing: apiResponse.msg))")
                        OpenChatLinkHandler.postMonitor(success: false, type: "open_id", code: apiResponse.code, msg: apiResponse.msg)
                        return
                    }
                    let body = ChatControllerByIdBody(chatId: chatId)
                    resolver.navigator.push(body: body, from: fromVC)
                    OpenChatLinkHandler.postMonitor(success: true, type: "open_id")
                }, onError: { (error) in
                    hud.remove()
                    OpenChatLinkHandler.logger.error("request chatId error \(error.localizedDescription)")
                }).disposed(by: client.disposeBag)
        } else if let openChatId = queryParameters["openChatId"], let client = httpClient {
            let hud = RoundedHUD.showLoading(on: fromVC.view, disableUserInteraction: true)
            client.request(api: OpenPlatformAPI.GetChatIdAPI(openChatId: openChatId, resolver: resolver))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (apiResponse: GetChatIdAPIResponse) in
                    hud.remove()
                    guard apiResponse.code == 0,
                        let chatId = apiResponse.chatIdWithOpenChatId(openChatId: openChatId) else {
                            OpenChatLinkHandler.logger.error("request chatId by open_chat_id error \(String(describing: apiResponse.code)) \(String(describing: apiResponse.msg))")
                            OpenChatLinkHandler.postMonitor(success: false, type: "open_chat_id", code: apiResponse.code, msg: apiResponse.msg)
                            return
                    }
                    let body = ChatControllerByIdBody(chatId: chatId)
                    resolver.navigator.push(body: body, from: fromVC)
                    OpenChatLinkHandler.postMonitor(success: true, type: "open_chat_id")
                }, onError: { (error) in
                    hud.remove()
                    OpenChatLinkHandler.logger.error("request chatId by open_chat_id error \(error.localizedDescription)")
                }).disposed(by: client.disposeBag)
        } else if let botId = queryParameters["botId"] {
            if let opService = try? resolver.resolve(assert: OpenPlatformService.self) {
                opService.openBot(botId: botId)
            }
        } else {
            OpenChatLinkHandler.logger.error("invalid params \(appLink.url)")
            OpenChatLinkHandler.postMonitor(success: false)
        }
    }

    private static func postMonitor(success: Bool, type: String? = nil, code: Int? = nil, msg: String? = nil) {
        var params: [String: Any] = [:]
        params["result"] = success ? "success" : "fail"
        params["type"] = type
        params["rsp_code"] = code
        params["rsp_msg"] = msg
        Tracker.post(TeaEvent("applink_open_chat", params: params))
    }
}
