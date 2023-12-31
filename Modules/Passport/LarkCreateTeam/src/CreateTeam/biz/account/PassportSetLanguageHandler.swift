//
//  PassportSetLanguageHandler.swift
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

/// Web 页通过这个 JSB 向客户端传入新的语言设置
class PassportSetLanguageHandler: JsAPIHandler {

    static let logger = Logger.log(PassportSetLanguageHandler.self, category: "Module.JSSDK")
    @Provider var dependency: PassportWebViewDependency

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {

        dependency.monitorSensitiveJsApi(apiName: "biz.passport.set_lang", sourceUrl: api.browserURL, from: "LarkCreateTeam")

        Self.logger.info("n_action_JSB_set_app_lang")
        
        dependency.setAppLanguage(args)
    }

}
