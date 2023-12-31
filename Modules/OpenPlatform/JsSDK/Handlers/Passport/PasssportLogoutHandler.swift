//
//  PasssportLogoutHandler.swift
//  JsSDK
//
//  Created by Miaoqi Wang on 2020/8/23.
//

import Foundation
import WebBrowser
import LarkContainer
import LarkAccountInterface
import EcosystemWeb

///https://bytedance.feishu.cn/docs/doccnc38mORFN7DVX3rZAZ5pa7e
class PasssportLogoutHandler: CheckPermissionJsAPIHandler {
    
    @Provider private var passportService: PassportService // Global

    @Provider var dependency: PassportWebViewDependency

    override func validatedHandle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {

        dependency.monitorSensitiveJsApi(apiName: "biz.passport.logout", sourceUrl: api.browserURL, from: "JSSDK")

        if dependency.enableCheckSensitiveJsApi(), let currentUrl = api.browserURL {
            if !WebAppAuthStrategyManager.canEscapeeInnerDomainPrivateAPIAuth(apiName: "passportLogout", url: currentUrl) {
                Self.logger.info("no permission in api: passportLogout")
                let errorParam = ["error": "no permission in api: passportLogout"]
                callback.callbackFailure(param: errorParam)
                return
            }
        }

        let config: LogoutConf = .default
        if let clearData = args[Const.clearData] as? Bool {
            config.clearData = clearData
        }
        if let forceLogout = args[Const.forceLogout] as? Bool {
            config.forceLogout = forceLogout
        }
        if let needAlert = args[Const.needAlert] as? Bool {
            config.needAlert = needAlert
        }
        if let message = args[Const.message] as? String {
            config.message = message
        }

        Self.logger.info("passport logout bridge start with config: \(config)")

        passportService.logout(conf: config) {
            Self.logger.info("passport logout is interrupted")
            callback.callbackFailure(param: NewJsSDKErrorAPI.PassportLogout.interrupted.description())
        } onError: { message in
            Self.logger.error("passport logout failed: \(message)")
            callback.callbackFailure(param: NewJsSDKErrorAPI.PassportLogout.failed(msg: message).description())
        } onSuccess: { _, _ in
            Self.logger.info("passport logout success")
            callback.callbackSuccess(param: ["code": 0])
        } onSwitch: { _ in }
    }
}

extension PasssportLogoutHandler {
    enum Const {
        static let clearData = "clearData"
        static let forceLogout = "forceLogout"
        static let needAlert = "needAlert"
        static let message = "message"
    }
}
