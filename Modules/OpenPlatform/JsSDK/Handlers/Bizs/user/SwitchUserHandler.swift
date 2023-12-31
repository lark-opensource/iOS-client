//
//  SwitchUserHandler.swift
//  JsSDK
//
//  Created by Miaoqi Wang on 2020/4/15.
//

import Foundation
import WebBrowser
import LarkAccountInterface
import LKCommonsLogging
import LarkFeatureGating
import LarkContainer

class SwitchUserHandler: JsAPIHandler {
    
    @Provider private var passportService: PassportService // Global
    
    static let logger = Logger.log(SwitchUserHandler.self)
    
    private let resolver: UserResolver
    
    init(resolver: UserResolver) {
        self.resolver = resolver
    }
    
    var needAuthrized: Bool {
        return resolver.fg.dynamicFeatureGatingValue(with: "lark.jsapi.permission.switch_user")
    }

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        guard let userId = args["user_id"] as? String else {
            SwitchUserHandler.logger.error("no userid")
            callback.callbackFailure(param: NewJsSDKErrorAPI.invalidParameter(extraMsg: "user_id").description())
            return
        }

        SwitchUserHandler.logger.info("start switch user")

        passportService.switchTo(userID: userId) { success in
            SwitchUserHandler.logger.info("switch user success \(success)")
            if success {
                callback.callbackSuccess(param: [String: Any]())
            } else {
                callback.callbackFailure(param: [String: Any]())
            }
        }
    }
}
