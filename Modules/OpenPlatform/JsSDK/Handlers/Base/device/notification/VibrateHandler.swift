//
//  VibrateHandler.swift
//  Lark
//
//  Created by ChalrieSu on 2018/4/12.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import AudioToolbox
import LKCommonsLogging
import WebBrowser

class VibrateHandler: JsAPIHandler {
    static let logger = Logger.log(VibrateHandler.self, category: "Module.JSSDK")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {

        VibrateHandler.logger.info("handle vibrate")
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        callback.callbackSuccess(param: ["code": 0])
    }
}
