//
//  GetClipboardInfoHandler.swift
//  LarkWeb
//
//  Created by 李论 on 2019/8/29.
//

import LKCommonsLogging
import WebBrowser
import LarkEMM
import OPFoundation

class GetClipboardInfoHandler: JsAPIHandler {
    static let logger = Logger.log(CloseHandler.self, category: "Module.JSSDK")

    var needAuthrized: Bool {
        return true
    }
    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        GetClipboardInfoHandler.logger.info("GetClipboardInfoHandler call begin")
        let config = PasteboardConfig(token: OPSensitivityEntryToken.getClipboardInfoHandler.psdaToken)
        let data = SCPasteboard.general(config).string ?? ""
        callback.callbackSuccess(param: [
            "code": 0,
            "text": data
            ])
        GetClipboardInfoHandler.logger.info("GetClipboardInfoHandler callback end")
    }
}
