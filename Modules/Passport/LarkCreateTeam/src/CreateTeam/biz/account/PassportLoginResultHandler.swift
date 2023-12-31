//
//  PassportLoginResultHandler.swift
//  LarkCreateTeam
//
//  Created by quyiming@bytedance.com on 2019/10/12.
//

import Foundation
import LKCommonsLogging
import WebBrowser
import LarkAccountInterface
import LarkContainer
import JsSDK

class PassportLoginResultHandler: JsAPIHandler {

    static let logger = Logger.log(PassportLoginResultHandler.self, category: "Module.JSSDK")

    @Provider var dependency: PassportWebViewDependency

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {

        self.dependency.monitorSensitiveJsApi(apiName: "biz.account.h5_login_result", sourceUrl: api.browserURL, from: "LarkCreateTeam")

        PassportLoginResultHandler.logger.info("passport login result")
        dependency.finishedLogin(args)
        callback.callDeprecatedFunction(name: args["callback"] as? String ?? "", param: [:])
    }

}
