//
//  PassportRouterHandler.swift
//  JsSDK
//
//  Created by quyiming on 2020/1/12.
//

import WebBrowser
import LKCommonsLogging
import LarkAccountInterface
import LarkContainer

class PassportStateMachineHandler: JsAPIHandler {
    
    @Provider var passportWebViewDependency: PassportWebViewDependency // Global
    
    private let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    private static let logger = Logger.log(PassportStateMachineHandler.self, category: "PassportStateMachineHandler")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        self.passportWebViewDependency.monitorSensitiveJsApi(apiName: "biz.passport.stateMachine", sourceUrl: api.browserURL, from: "JSSDK")
        passportWebViewDependency.open(data: args, success: {
            PassportStateMachineHandler.logger.debug("PassportStateMachineHandler open success")
            self.onSuccessCallback(argus: args, webApi: api)
        }, failure: { error in
            PassportStateMachineHandler.logger.debug("PassportStateMachineHandler open fail with error: \(error)")
            self.onFailedCallback(argus: args, webApi: api, jsArgs: NewJsSDKErrorAPI.requestError.description())
        })
        PassportStateMachineHandler.logger.debug("PassportStateMachineHandler success")
    }

    func onSuccessCallback(argus args: [String: Any], webApi api: WebBrowser) {
        if let onSuccess = args["onSuccess"] as? String {
            callbackWith(api: api, funcName: onSuccess, arguments: [])
        }
    }

    func onFailedCallback(argus args: [String: Any], webApi api: WebBrowser, jsArgs: [String: Any]) {
        if let onFailed = args["onFailed"] as? String {
            callbackWith(api: api, funcName: onFailed, arguments: [jsArgs])
        }
    }
}
