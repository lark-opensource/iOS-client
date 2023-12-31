//
//  AppInfoHandler.swift
//  Pods
//
//  Created by Yiming Qu on 2019/5/26.
//

import LarkUIKit
import WebBrowser
import Swinject
import LKCommonsLogging
import LarkAccountInterface
import LarkContainer
import JsSDK

class AppInfoHandler: JsAPIHandler {

    static let logger = Logger.log(AppInfoHandler.self, category: "Module.JSSDK")

    @Provider var dependency: PassportWebViewDependency

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        dependency.monitorSensitiveJsApi(apiName: "biz.account.appInfo", sourceUrl: api.browserURL, from: "LarkCreateTeam")
        AppInfoHandler.logger.info("AppInfoHandler args: \(args)")
        callback.callDeprecatedFunction(name: "onDeviceInfo", param: dependency.getAppInfo())
    }
}
