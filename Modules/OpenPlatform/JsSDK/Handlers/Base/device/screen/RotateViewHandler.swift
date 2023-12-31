//
//  RotateViewHandler.swift
//  LarkWeb
//
//  Created by qihongye on 2019/4/22.
//

import Foundation
import LKCommonsLogging
import WebBrowser

class RotateViewHandler: JsAPIHandler {
    static let logger = Logger.log(RotateViewHandler.self, category: "Module.JSSDK")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        let toHorizontal = args["toHorizontal"] as? Bool ?? true
        let clockwise = args["clockwise"] as? Bool ?? true

        if toHorizontal {
            api.landscapeScreen(clockwise ? .landscapeLeft : .landscapeRight)
        } else {
            api.landscapeScreen(.portrait)
        }
        callback.callbackSuccess(param: [])
    }
}
