//
//  PassportGetLanguageHandler.swift
//  LarkCreateTeam
//
//  Created by au on 2022/11/29.
//

import Foundation
import JsSDK
import LKCommonsLogging
import LarkContainer
import LarkAccountInterface
import WebBrowser

/// Web 页通过这个 JSB 获取客户端内的语言设置
class PassportGetLanguageHandler: JsAPIHandler {

    static let logger = Logger.log(PassportGetLanguageHandler.self, category: "Module.JSSDK")
    @Provider var dependency: PassportWebViewDependency

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {

        Self.logger.info("n_action_JSB_get_app_lang")

        self.dependency.monitorSensitiveJsApi(apiName: "biz.passport.get_lang", sourceUrl: api.browserURL, from: "LarkCreateTeam")

        let current = dependency.getAppLanguage()

        guard !current.isEmpty else {
            Self.logger.error("n_action_JSB_cannot_get_lang")
            callback.callbackFailure(param: [:])
            return
        }

        callback.callbackSuccess(param: current)
    }
}
