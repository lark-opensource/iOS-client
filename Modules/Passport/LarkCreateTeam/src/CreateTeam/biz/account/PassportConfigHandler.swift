//
//  PassportConfigHandler.swift
//  LarkCreateTeam
//
//  Created by quyiming@bytedance.com on 2019/10/12.
//

import Foundation
import WebBrowser
import LKCommonsLogging
import LarkContainer
import LarkAccountInterface
import JsSDK

class PassportConfigHandler: JsAPIHandler {

    static let logger = Logger.log(PassportConfigHandler.self, category: "Module.JSSDK")

    @Provider var dependency: PassportWebViewDependency

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {

        self.dependency.monitorSensitiveJsApi(apiName: "biz.account.ka_info", sourceUrl: api.browserURL, from: "LarkCreateTeam")
        if let config = dependency.getIDPConfig() {
            PassportConfigHandler.logger.info("get ka config success")
            callback.callbackSuccess(param: config)
        } else {
            PassportConfigHandler.logger.error("\(KaConfigError.kaConfigEmpty)")
            callback.callbackFailure(param: [:])
        }
    }

    enum KaConfigError: Error {
        case noOnSuccess([String: Any])
        case kaConfigEmpty
    }

}
