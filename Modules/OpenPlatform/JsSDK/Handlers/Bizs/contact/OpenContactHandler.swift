//
//  OpenContactHandler.swift
//  LarkWeb
//
//  Created by 李论 on 2019/9/11.
//

import UIKit
import LarkFoundation
import EENavigator
import LKCommonsLogging
import LarkUIKit
import WebBrowser
import LarkNavigation
import AnimatedTabBar
import LarkTab

class OpenContactHandler: JsAPIHandler {
    static let logger = Logger.log(OpenContactHandler.self, category: "Module.JSSDK")

    var needAuthrized: Bool {
        return true
    }

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        OpenContactHandler.logger.info("OpenContactHandler call begin")
        Navigator.shared.push(
            Tab.contact.url,
            context: ["showNormalNavigationBar": true],
            from: api,
            animated: true,
            completion: nil
        )
        callback.callbackSuccess(param: ["code": 0])
        OpenContactHandler.logger.info("OpenContactHandler call end")
    }
}
