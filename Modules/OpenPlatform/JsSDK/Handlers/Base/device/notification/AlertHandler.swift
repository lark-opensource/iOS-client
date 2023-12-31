//
//  AlertHandler.swift
//  Lark
//
//  Created by liuwanlin on 2017/10/13.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LKCommonsLogging
import LarkAlertController
import EENavigator
import WebBrowser

class AlertHandler: JsAPIHandler {
    static let logger = Logger.log(AlertHandler.self, category: "Module.JSSDK")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {

        guard let message = args["message"] as? String,
            let title = args["title"] as? String,
            let buttonName = args["buttonName"] as? String else {
            let errMsg = String(describing: args["message"])
            let errTitle = String(describing: args["title"])
            let errBtnNames = String(describing: args["buttonName"])
            AlertHandler.logger.error("required parameters invalid, message: \(errMsg), title: \(errTitle), btnNames: \(errBtnNames)")
            return
        }

        AlertHandler.logger.info("handle alert with title: \(title), message: \(message),buttonName: \(buttonName)")
        let alertController = LarkAlertController()
        alertController.setTitle(text: title)
        alertController.setContent(text: message)
        alertController.addPrimaryButton(text: buttonName)
        Navigator.shared.present(alertController, from: api) // Global
    }
}
