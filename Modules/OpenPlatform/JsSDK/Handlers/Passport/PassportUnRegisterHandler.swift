//
//  PassportUnRegisterHandler.swift
//  JsSDK
//
//  Created by bytedance on 2021/7/18.
//

import WebBrowser
import LKCommonsLogging
import LarkAccountInterface
import Swinject
import LarkSDKInterface
import LarkContainer
import LarkAccount
import EcosystemWeb

class PassportUnRegisterHandler: JsAPIHandler {

    @Provider var passportService: PassportService // Global

    @Provider var dependency: PassportWebViewDependency

    private let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    private static let logger = Logger.plog(UserInfoHandler.self, category: "PassportUnRegisterHandler")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        dependency.monitorSensitiveJsApi(apiName: "biz.account.unRegisterFinish", sourceUrl: api.browserURL, from: "JSSDK")
        if dependency.enableCheckSensitiveJsApi(), let currentUrl = api.browserURL {
            if !WebAppAuthStrategyManager.canEscapeeInnerDomainPrivateAPIAuth(apiName: "passportUnRegister", url: currentUrl) {
                Self.logger.info("no permission in api: passportUnRegister")
                let errorParam = ["error": "no permission in api: passportUnRegister"]
                callback.callbackFailure(param: errorParam)
                return
            }
        }
        Self.logger.passportInfo("n_action_jsb_unregister_handle", body: "start")
        Self.logger.passportInfo("n_action_switch_to_next_valid_user")

        // 主动触发session失效流程
        passportService.checkSessionInvalid()
    }
    
}

class PassportUnRegisterPacketHandler: JsAPIHandler {
    
    @Provider var passportService: PassportService // Global
    @Provider var dependency: PassportWebViewDependency

    private let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    private static let logger = Logger.plog(UserInfoHandler.self, category: "PassportUnRegisterPacketHandler")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        Self.logger.passportInfo("n_action_jsb_unregister_redpacket")
        self.dependency.monitorSensitiveJsApi(apiName: "biz.account.unRegisterRedPacket", sourceUrl: api.browserURL, from: "JSSDK")

        guard let data = args["data"] as? [String:Any] else {
            Self.logger.passportError("n_action_get_data_from_jsb_null")
            return
        }

        guard let url = data["url"] as? String else {
            Self.logger.passportError("n_action_get_url_from_jsb_null")
            return
        }

        Self.logger.passportInfo("n_action_open_money_h5page")
        passportService.openCJURL(url)
    }

}

