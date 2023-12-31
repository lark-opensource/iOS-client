//
//  GoBackHandler.swift
//  Lark
//
//  Created by ChalrieSu on 2018/4/12.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import LKCommonsLogging
import WebBrowser

class GoBackHandler: JsAPIHandler {
    static let logger = Logger.log(GoBackHandler.self, category: "Module.JSSDK")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        let result = api.goBack()
        let code = result ? 0 : 1
        callback.callbackSuccess(param: ["code": code])
    }
}
