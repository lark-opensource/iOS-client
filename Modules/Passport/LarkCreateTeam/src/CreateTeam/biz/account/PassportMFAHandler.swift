//
//  PassportMFAHandler.swift
//  LarkCreateTeam
//
//  Created by YuankaiZhu on 2023/9/7.
//

import WebBrowser
import LKCommonsLogging
import LarkAccountInterface
import Swinject
import LarkSDKInterface
import LarkContainer
import LarkAccount
import JsSDK

class PassportFirstPartyMFAHandler: JsAPIHandler {

    @Provider var dependency: AccountServiceNewMFA // user:checked (global-resolve)

    @Provider var passportWebViewDependency: PassportWebViewDependency

    private let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    private static let logger = Logger.log(PassportFirstPartyMFAHandler.self, category: "PassportFirstPartyMFAHandler")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        passportWebViewDependency.monitorSensitiveJsApi(apiName: "biz.passport.firstPartyMFA", sourceUrl: api.browserURL, from: "LarkCreateTeam")
        PassportFirstPartyMFAHandler.logger.info("n_action_jsb_passport_first_party_MFA_handler_start")
        guard let scope = args["mfaScope"] as? String else {
            PassportFirstPartyMFAHandler.logger.info("n_action_jsb_passport_first_party_MFA_handler_fail", additionalData: ["error":"No MFA scope"])
            return
        }
        dependency.startNewMFA(scope: scope, from: api) { token in
            let param = [
                "code": 0,
                "message": "" ,
                "result": [
                  "mfaToken": token
                ]
            ] as [String : Any]
            callback.callbackSuccess(param: param)
        } onError: { error in
            PassportFirstPartyMFAHandler.logger.info("n_action_jsb_passport_first_party_MFA_handler_fail", additionalData: ["error":error.localizedDescription ])
            let param = [
                "code": -1,
                "message": error.localizedDescription
            ] as [String : Any]
            callback.callbackFailure(param: param)
        }

    }

}

class PassportCheckStatusMFAHandler: JsAPIHandler {

    @Provider var dependency: AccountServiceNewMFA // user:checked (global-resolve)

    @Provider var passportWebViewDependency: PassportWebViewDependency

    private let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    private static let logger = Logger.log(PassportCheckStatusMFAHandler.self, category: "PassportCheckStatusMFAHandler")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        passportWebViewDependency.monitorSensitiveJsApi(apiName: "biz.passport.checkMFAStatus", sourceUrl: api.browserURL, from: "LarkCreateTeam")
        PassportCheckStatusMFAHandler.logger.info("n_action_jsb_passport_check_status_MFA_handler_start")
        guard let scope = args["mfaScope"] as? String else {
            PassportCheckStatusMFAHandler.logger.info("n_action_jsb_passport_check_status_MFA_handler_fail", additionalData: ["error":"No MFA scope"])
            return
        }
        guard let token = args["mfaToken"] as? String else {
            PassportCheckStatusMFAHandler.logger.info("n_action_jsb_passport_check_status_MFA_handler_fail", additionalData: ["error":"No MFA token"])
            return
        }
        dependency.checkNewMFAStatus(token: token, scope: scope) { code in
            let param = [
                "code": 0,
                "message": "" ,
                "result": [
                    "status": code.rawValue
                ]
            ] as [String : Any]
            callback.callbackSuccess(param: param)
        } onError: { error in
            PassportCheckStatusMFAHandler.logger.info("n_action_jsb_passport_check_status_MFA_handler_fail", additionalData: ["error":error.localizedDescription ])
            let param = [
                "code": -1,
                "message": error.localizedDescription
            ] as [String : Any]
            callback.callbackFailure(param: param)
        }

    }

}
