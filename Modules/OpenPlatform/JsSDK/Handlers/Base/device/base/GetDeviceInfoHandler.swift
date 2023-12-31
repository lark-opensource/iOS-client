//
//  GetDeviceInfoHandler.swift
//  LarkWeb
//
//  Created by qihongye on 2018/10/9.
//

import Foundation
import UIKit
import LKCommonsLogging
import WebBrowser

class GetDeviceInfoHandler: JsAPIHandler {
    static let logger = Logger.log(GetDeviceInfoHandler.self, category: "Module.JSSDK")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {

        callback.callbackSuccess(param: [
            "brand": "Apple",
            "model": UIDevice.current.lu.modelName(),
            "reolution": [
                "width": UIScreen.main.bounds.width * UIScreen.main.scale,
                "height": UIScreen.main.bounds.height * UIScreen.main.scale
            ]
        ])
    }
}
