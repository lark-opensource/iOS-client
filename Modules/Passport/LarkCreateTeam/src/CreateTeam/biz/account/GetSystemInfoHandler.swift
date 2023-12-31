//
//  GetSystemInfoHandler.swift
//  LarkCreateTeam
//
//  Created by quyiming@bytedance.com on 2019/10/21.
//

import Foundation
import WebBrowser
import LKCommonsLogging
import JsSDK
import LarkOPInterface
import LarkContainer
import LarkAccountInterface

class GetSystemInfoHandler: JsAPIHandler {

    static let logger = Logger.log(GetSystemInfoHandler.self, category: "Module.JSSDK")

    private let openPlatform: OpenPlatformService

    @Provider var dependency: PassportWebViewDependency

    init(openPlatform: OpenPlatformService) {
        self.openPlatform = openPlatform
    }

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        self.dependency.monitorSensitiveJsApi(apiName: "device.base.getSystemInfo", sourceUrl: api.browserURL, from: "LarkCreateTeam")
        guard let callbackName = args["callback"] as? String else {
            GetSystemInfoHandler.logger.error("params error no failback")
            return
        }
        let onFailed = args["onFailed"] as? String
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let system = UIDevice.current.systemVersion
        let platform = "iOS"
        let model = UIDevice.current.lu.modelName()
        let pixeIRatio = UIScreen.main.scale
        let deviceID = openPlatform.getOpenPlatformDeviceID()
        if deviceID.isEmpty {
            let msg = "params device id is empty"
            GetSystemInfoHandler.logger.error(msg)
            callbackWith(
                api: api,
                funcName: onFailed,
                arguments: [msg]
            )
        }
        callback.callDeprecatedFunction(name: callbackName, param: [
            "code": 0,
            "appVersion": appVersion,
            "system": system,
            "platform": platform,
            "model": model,
            "pixeIRatio": pixeIRatio,
            "deviceID": deviceID
        ])
    }
}
