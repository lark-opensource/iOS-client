//
//  PassportGetStepInfoHandler.swift
//  LarkCreateTeam
//
//  Created by zhaokejie on 2023/01/12.
//

import Foundation
import LKCommonsLogging
import WebBrowser
import LarkAccountInterface
import LarkContainer
import JsSDK


class PassportGetStepInfoHandler: JsAPIHandler {

    @Provider var dependency: PassportWebViewDependency

    static let logger = Logger.log(PassportGetStepInfoHandler.self, category: "Module.JSSDK")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {

        self.dependency.monitorSensitiveJsApi(apiName: "biz.passport.get_remote_register_info", sourceUrl: api.browserURL, from: "LarkCreateTeam")

        let stepInfo = dependency.getStepInfo()
        if !stepInfo.isEmpty {
            callback.callbackSuccess(param: ["code": 0, "step_info": dependency.getStepInfo()])
            Self.logger.info("n_action_jsb_get_StepInfo_succ")
        } else {
            callback.callbackSuccess(param: ["code": -1])
            Self.logger.info("n_action_jsb_get_StepInfo_fail")
        }

    }

}
