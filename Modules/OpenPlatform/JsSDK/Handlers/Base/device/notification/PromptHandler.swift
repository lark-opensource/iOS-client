//
//  PromptHandler.swift
//  Lark
//
//  Created by liuwanlin on 2017/10/13.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LKCommonsLogging
import LarkAlertController
import EditTextView
import WebBrowser
import LarkUIKit

class PromptHandler: JsAPIHandler {
    static let logger = Logger.log(PromptHandler.self, category: "Module.JSSDK")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        guard let message = args["message"] as? String,
            let title = args["title"] as? String,
            let buttonLabels = args["buttonLabels"] as? [String] else {
            let errMsg = String(describing: args["message"])
            let errTitle = String(describing: args["title"])
            let errBtnLabels = String(describing: args["buttonLabels"])
            PromptHandler.logger.error("required parameters invalid, message: \(errMsg), title: \(errTitle), btnLabels: \(errBtnLabels)")
            return
        }

        PromptHandler.logger.info("handle prompt with title: \(title), message: \(message), buttonLabels: \(buttonLabels)")
        let alertController = LarkAlertController()
        alertController.setTitle(text: title)
        let customView = ContentWithTextFieldView(text: message)
        alertController.setContent(view: customView, padding: UIEdgeInsets(top: 10, left: 20, bottom: 18, right: 20))
        for (index, label) in buttonLabels.enumerated() {
            alertController.addPrimaryButton(text: label, dismissCompletion: { [weak api] in
                callback.callbackSuccess(param: [
                    "value": customView.textField.text ?? "",
                    "buttonIndex": index
                ])
                PromptHandler.logger.info("user tap button at \(index)")
            })
        }

        api.present(alertController, animated: true)
    }
}
