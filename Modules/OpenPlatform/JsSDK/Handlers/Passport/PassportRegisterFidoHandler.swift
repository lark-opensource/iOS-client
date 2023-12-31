//
//  PassportRegisterFidoHandler.swift
//  JsSDK
//
//  Created by ZhaoKejie on 2023/2/21.
//

import Foundation
import WebBrowser
import LKCommonsLogging
import LarkAccountInterface
import Swinject
import LarkSDKInterface
import LarkContainer

class PassportRegisterFidoHandler: JsAPIHandler {

    @Provider var dependency: PassportWebViewDependency // Global

    private let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    private static let logger = Logger.log(PassportRegisterFidoHandler.self, category: "PassportRegisterFidoHandler")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        self.dependency.monitorSensitiveJsApi(apiName: "biz.passport.fido.register", sourceUrl: api.browserURL, from: "JSSDK")
        PassportRegisterFidoHandler.logger.info("n_action_Fido_register_jsb_handler_start")
        dependency.registerFido(args) { args in
            PassportRegisterFidoHandler.logger.info("n_action_Fido_register_jsb_handler_succ")
            callback.callbackSuccess(param: args)
        } failure: { args in
            var addtionalParams: [String: String] = [:]
            if let code = args["code"] as? Int {
                addtionalParams["code"] = String(code)
            }
            if let message = args["message"] as? String {
                addtionalParams["message"] = message
            }
            PassportRegisterFidoHandler.logger.info("n_action_Fido_register_jsb_handler_fail", additionalData: addtionalParams)
            callback.callbackFailure(param: args)
        }

    }

}
