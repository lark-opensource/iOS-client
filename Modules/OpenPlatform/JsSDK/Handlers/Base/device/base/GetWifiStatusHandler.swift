//
//  GetWifiStatusHandler.swift
//  Lark
//
//  Created by ChalrieSu on 2018/4/12.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import LKCommonsLogging
import WebBrowser

class GetWifiStatusHandler: JsAPIHandler {
    static let logger = Logger.log(GetWifiStatusHandler.self, category: "Module.JSSDK")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {

        if GetInterfaceHandler.getWifiInfo() != nil {
            callback.callbackSuccess(param: ["status": 1])
        } else {
            callback.callbackSuccess(param: ["status": 0])
        }
    }
}
