//
//  ResetViewHandler.swift
//  LarkWeb
//
//  Created by qihongye on 2019/4/22.
//

import Foundation
import LKCommonsLogging
import WebBrowser

class ResetViewHandler: JsAPIHandler {
    static let logger = Logger.log(ResetViewHandler.self, category: "Module.JSSDK")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        api.landscapeScreen(.unknown)
        callback.callbackSuccess(param: [])
    }
}
