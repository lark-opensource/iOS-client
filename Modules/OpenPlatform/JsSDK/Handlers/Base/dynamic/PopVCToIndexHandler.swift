//
//  PopVCToIndexHandler.swift
//  LarkWeb
//
//  Created by zhenning on 2019/12/12.
//

import LKCommonsLogging
import WebBrowser
import EENavigator

class PopVCToIndexHandler: JsAPIHandler {

    private static let logger = Logger.log(PopVCToIndexHandler.self, category: "PopVCToIndexHandler")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        PopVCToIndexHandler.logger.debug("handle args = \(args))")

        if let indexStr = args["index"] as? String,
            let index = Int(indexStr),
            let currentVCs = api.navigationController?.viewControllers {
            let targetIndex = currentVCs.count - 1 + index
            PopVCToIndexHandler.logger.debug("PopVCToIndexHandler targetIndex = \(targetIndex), currentVCs = \(currentVCs), index = \(index)")
            if targetIndex >= 0 {
                api.navigationController?.popToViewController(currentVCs[targetIndex], animated: true)
            } else {
                PopVCToIndexHandler.logger.error("PopVCToIndexHandler failed, targetIndex not valid! targetIndex = \(targetIndex)")
            }
        } else {
            if let onFailed = args["onFailed"] as? String {
                let arguments = [NewJsSDKErrorAPI.missingRequiredArgs.description()] as [[String: Any]]
                callbackWith(api: api, funcName: onFailed, arguments: arguments)
            }
            PopVCToIndexHandler.logger.error("PopVCToIndexHandler failed, index not found!)")
        }
    }
}
