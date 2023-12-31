//
//  ToastHandler.swift
//  Lark
//
//  Created by liuwanlin on 2017/10/13.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkUIKit
import LKCommonsLogging
import RoundedHUD
import WebBrowser

class ToastHandler: JsAPIHandler {
    static let logger = Logger.log(ToastHandler.self, category: "Module.JSSDK")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        guard let text = args["text"] as? String,
            let duration = args["duration"] as? TimeInterval else {
            let errText = String(describing: args["text"])
            let errDuration = String(describing: args["duration"])
            ToastHandler.logger.error("required parameters invalid, text: \(errText), duration: \(errDuration)")
            return
        }
        ToastHandler.logger.info("handle show toast with \(text), duration: \(duration)")
        RoundedHUD.showTips(with: text, on: api.view, delay: duration)
    }
}
