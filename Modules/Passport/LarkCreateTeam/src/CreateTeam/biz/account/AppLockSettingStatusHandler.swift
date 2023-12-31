//
//  AppLockSettingStatusHandler.swift
//  LarkCreateTeam
//
//  Created by ByteDance on 2023/11/2.
//

import WebBrowser
import LKCommonsLogging
import LarkAccountInterface
import Swinject
import LarkSDKInterface
import LarkContainer
import LarkAccount
import JsSDK

class AppLockSettingStatusHandler: JsAPIHandler {
    @Provider var service: AppLockSettingDependency

    private let resolver: Resolver // Global

    init(resolver: Resolver) {
        self.resolver = resolver
        Self.logger.info("AppLockSettingStatusHandler init")
    }

    private static let logger = Logger.log(AppLockSettingStatusHandler.self, category: "AppLockSettingStatusHandler")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        service.checkAppLockSettingStatus { isActive in
            Self.logger.info("H5 get app lock settings status :\(isActive)")
            let param:[String: Any] = [
                "res": isActive
            ]
            callback.callbackSuccess(param: param)
        }
    }
}
