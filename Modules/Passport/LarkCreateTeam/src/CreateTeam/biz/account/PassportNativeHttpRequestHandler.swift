//
//  PassportNativeHttpRequestHandler.swift
//  LarkCreateTeam
//
//  Created by ZhaoKejie on 2023/1/13.
//

import Foundation
import LKCommonsLogging
import WebBrowser
import LarkAccountInterface
import LarkContainer
import JsSDK


class PassportNativeHttpRequestHandler: JsAPIHandler {

    @Provider var dependency: PassportWebViewDependency

    static let logger = Logger.log(PassportNativeHttpRequestHandler.self, category: "Module.JSSDK")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        dependency.monitorSensitiveJsApi(apiName: "biz.passport.request_network", sourceUrl: api.browserURL, from: "LarkCreateTeam")
        dependency.nativeHttpRequest(args) { respData in
            callback.callbackSuccess(param: ["result": respData,
                                             "code": 0])
            Self.logger.info("n_action_jsb_nativeHttp_handler_succ")
        } failure: { respError in
            //code的逻辑放到具体的实现中（包含在respError里）
            callback.callbackSuccess(param: respError)
            Self.logger.error("n_action_jsb_nativeHttp_handler_error")
        }
    }

}
