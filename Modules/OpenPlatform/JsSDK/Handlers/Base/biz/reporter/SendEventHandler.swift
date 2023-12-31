//
//  SendEventHandler.swift
//  Lark
//
//  Created by qihongye on 2017/12/7.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LKCommonsLogging
import LKCommonsTracker
import WebBrowser

class SendEventHandler: JsAPIHandler {
    static let logger = Logger.log(SendEventHandler.self, category: "Module.JSSDK")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        guard let action = args["action"] as? String,
            let category = args["category"] as? String else {
                SendEventHandler.logger.error("无效的参数: event")
                return
        }
        var params = args["params"] as? [String: Any] ?? [:]
        params["category"] = category
        Tracker.post(TeaEvent(action, params: params))
    }
}
