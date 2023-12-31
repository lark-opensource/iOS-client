//
//  PassportJoinByScanHandler.swift
//  LarkCreateTeam
//
//  Created by ZhaoKejie on 2023/1/17.
//

import Foundation
import LKCommonsLogging
import WebBrowser
import LarkAccountInterface
import LarkContainer
import JsSDK

class PassportJoinByScanHandler: JsAPIHandler {

    @Provider var dependency: PassportWebViewDependency

    static let logger = Logger.log(PassportJoinByScanHandler.self, category: "Module.JSSDK")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        if let data = args["data"] as? [String : Any], let stepInfo = data["step_info"] as? [String : Any] {

            self.dependency.monitorSensitiveJsApi(apiName: "biz.passport.join_by_scan", sourceUrl: api.browserURL, from: "LarkCreateTeam")
            
            Self.logger.info("n_action_jsb_scanCode_start")
            dependency.openNativeScanVC(stepInfo) { respUrl in
                if respUrl == "error" {
                    callback.callbackSuccess(param: ["code":-1, "message": respUrl])
                }
                callback.callbackSuccess(param: ["code":0, "scan_result": respUrl])
                Self.logger.info("n_action_jsb_scanCode_succ")
            }
        }
    }

}
