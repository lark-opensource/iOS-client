//
//  PassportSwitchIdpHandler.swift
//  LarkCreateTeam
//
//  Created by quyiming@bytedance.com on 2019/10/28.
//

import Foundation
import WebBrowser
import LKCommonsLogging
import LarkContainer
import LarkAccountInterface
import JsSDK

class PassportSwitchIdpHandler: JsAPIHandler {

    static let logger = Logger.log(PassportSwitchIdpHandler.self, category: "Module.JSSDK")
    @Provider var dependency: PassportWebViewDependency

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {

        dependency.monitorSensitiveJsApi(apiName: "biz.account.switch_idp", sourceUrl: api.browserURL, from: "LarkCreateTeam")

        PassportSwitchIdpHandler.logger.info("idp login result")
        guard let idp = args["idp_type"] as? String else {
            PassportSwitchIdpHandler.logger.error("\(PassportSwitchIdpError.invalidArgsNoIdpType)")
            callback.callbackFailure(param: [:])
            return
        }
        PassportSwitchIdpHandler.logger.info("idp handle switch idp")
        dependency.switchIDP(idp) { success, error in
            if success {
                callback.callbackSuccess(param: [
                    "success": true,
                    "code": 0
                ])
            } else {
                callback.callbackSuccess(param: [
                    "success": false,
                    "code": -1,
                    "msg": error?.localizedDescription ?? ""
                ])
            }
        }
    }

    enum PassportSwitchIdpError: Error {
        case invalidArgsNoIdpType
    }
}
