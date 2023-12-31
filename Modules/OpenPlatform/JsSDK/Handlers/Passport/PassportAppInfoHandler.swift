//
//  PassportAppInfoHandler.swift
//  JsSDK
//
//  Created by Miaoqi Wang on 2020/9/10.
//

import Foundation
import LKCommonsLogging
import Swinject
import WebBrowser
import LarkAccountInterface
import LarkContainer
import EcosystemWeb

class PassportAppInfoHandler: JsAPIHandler {

    @Provider var dependency: PassportWebViewDependency
    
    private let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
    }
    
    private static let logger = Logger.log(UserInfoHandler.self, category: "PassportAppInfoHandler")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {

        dependency.monitorSensitiveJsApi(apiName: "biz.account.appInfo", sourceUrl: api.browserURL, from: "JSSDK")

        if dependency.enableCheckSensitiveJsApi(), let currentUrl = api.browserURL {
            if !WebAppAuthStrategyManager.canEscapeeInnerDomainPrivateAPIAuth(apiName: "passportGetAppInfo", url: currentUrl) {
                Self.logger.info("no permission in api: passportGetAppInfo")
                let errorParam = ["error": "no permission in api: passportGetAppInfo"]
                callback.callbackFailure(param: errorParam)
                return
            }
        }
        Self.logger.info("AppInfoHandler args: \(args)")
        callback.callbackSuccess(param: dependency.getAppInfo())
    }
}
