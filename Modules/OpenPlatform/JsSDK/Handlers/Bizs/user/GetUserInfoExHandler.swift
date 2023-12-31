//
//  GetUserInfoExHandler.swift
//  LarkWeb
//
//  Created by 武嘉晟 on 2019/9/22.
//

import UIKit
import LKCommonsLogging
import WebBrowser
import LarkOPInterface
import LarkContainer

class GetUserInfoExHandler: JsAPIHandler {
    static let logger = Logger.log(GetUserInfoExHandler.self, category: "Module.JSSDK")

    private let resolver: UserResolver

    init(resolver: UserResolver) {
        self.resolver = resolver
    }

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {

        if let openPlatformService = try? resolver.resolve(assert: OpenPlatformService.self) {
            openPlatformService.getUserInfoEx(onSuccess: { info in
                GetUserInfoExHandler.logger.info("get userInfoEx success")
                callback.callbackSuccess(param: info)
            }, onFail: { error in
                GetUserInfoExHandler.logger.error("invalid user extra info: \(error)")
                callback.callbackFailure(param: [String: Any]())
            })
        } else {
            GetUserInfoExHandler.logger.error("resolve OpenPlatformService failed")
            callback.callbackFailure(param: NewJsSDKErrorAPI.resolveServiceError.description())
        }
    }
}
