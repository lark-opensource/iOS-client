//
//  GetSystemInfoHandler.swift
//  LarkWeb
//
//  Created by 李论 on 2019/8/29.
//

import LKCommonsLogging
import WebBrowser
import UIKit
import LarkOPInterface

class GetSystemInfoHandler: JsAPIHandler {
    static let logger = Logger.log(CloseHandler.self, category: "Module.JSSDK")

    var needAuthrized: Bool {
        return true
    }

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let system = UIDevice.current.systemVersion
        let platform = "iOS"
        let model = UIDevice.current.lu.modelName()
        let pixeIRatio = UIScreen.main.scale
        
        guard let openplatformService = try? sdk.resolver.resolve(assert: OpenPlatformService.self) else {
            Self.logger.error("resolve OpenPlatformService failed")
            callback.callbackFailure(param: NewJsSDKErrorAPI.resolveServiceError.description())
            return
        }
        
        callback.callbackSuccess(param: [
            "code": 0,
            "appVersion": appVersion,
            "system": system,
            "platform": platform,
            "model": model,
            "pixeIRatio": pixeIRatio,
            "deviceID": openplatformService.getOpenPlatformDeviceID()
            ])
    }
}
