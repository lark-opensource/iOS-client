//
//  PopVCAtIndexHandler.swift
//  LarkWeb
//
//  Created by zhenning on 2019/12/12.
//

import LKCommonsLogging
import WebBrowser
import EENavigator

class PopVCAtIndexHandler: JsAPIHandler {

    private static let logger = Logger.log(PopVCAtIndexHandler.self, category: "PopVCAtIndexHandler")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        PopVCAtIndexHandler.logger.debug("handle args = \(args))")

        if let navigation = api.navigationController {
            let animated = ((args["animated"] as? String ?? "true") == "true")
            navigation.popViewController(animated: animated)
            PopVCAtIndexHandler.logger.debug("PopVCAtIndexHandler success, navigation = \(navigation)")
            return
        }
        if let navigation = Navigator.shared.mainSceneWindow?.fromViewController?.navigationController {  // Global
            let animated = ((args["animated"] as? String ?? "true") == "true")
            navigation.popViewController(animated: animated)
            PopVCAtIndexHandler.logger.debug("PopVCAtIndexHandler success, navigation = \(navigation)")
            return
        }
        PopVCAtIndexHandler.logger.error("PopVCAtIndexHandler failed, navigation is nil!")
    }
}
