//
//  PassportBioAuthHandler.swift
//  JsSDK
//
//  Created by Nix Wang on 2022/12/26.
//

import LKCommonsLogging
import WebBrowser
import LarkAccountInterface
import LarkContainer
import JsSDK

class PassportBioAuthHandler: JsAPIHandler {

    private static let logger = Logger.log(PassportBioAuthHandler.self, category: "PassportBioAuthHandler")
    @Provider private var dependency: PassportWebViewDependency

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {

        self.dependency.monitorSensitiveJsApi(apiName: "biz.passport.startFaceIdentify", sourceUrl: api.browserURL, from: "LarkCreateTeam")
        dependency.startFaceIdentify(args, success: {
            Self.logger.debug("PassportBioAuthHandler startFaceIdentify success")
            callback.callbackSuccess(param: [
                "success": true
            ])
        }, failure: { error in
            Self.logger.debug("PassportBioAuthHandler startFaceIdentify fail with error: \(error)")
            var code = -1
            var msg = ""
            if let error = error as? NSError {
                code = error.code
                msg = error.localizedDescription
            }
            callback.callbackSuccess(param: [
                "success": false,
                "code": code,
                "msg": msg
            ])
        })
        Self.logger.debug("PassportBioAuthHandler success")
    }
}

