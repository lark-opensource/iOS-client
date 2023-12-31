//
//  ConfirmHandler.swift
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

class ConfirmHandler: JsAPIHandler {
    static let logger = Logger.log(ConfirmHandler.self, category: "Module.JSSDK")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        guard let message = args["message"] as? String,
            let title = args["title"] as? String,
            let buttonLabels = args["buttonLabels"] as? [String] else {
            let errMsg = String(describing: args["message"])
            let errTitle = String(describing: args["title"])
            let errBtnLabels = String(describing: args["buttonLabels"])
            let errCallback = String(describing: args["callback"])
            ConfirmHandler.logger.error("required parameters invalid, message: \(errMsg), title: \(errTitle), btnLabels: \(errBtnLabels), callback: \(errCallback)")
            return
        }

        ConfirmHandler.logger.info("handle confirm with title: \(title), buttonLabels: \(buttonLabels)")
        let alertController = LarkAlertController()
        alertController.setTitle(text: title)
        alertController.setContent(text: message)
        for (index, label) in buttonLabels.enumerated() {
            alertController.addPrimaryButton(text: label, dismissCompletion: { [weak api] in
                callback.callbackSuccess(param: [
                    "buttonIndex": index
                ])
                ConfirmHandler.logger.info("user tap button at \(index)")
            })
        }

        Navigator.shared.present(alertController, from: api) // Global
    }
}
