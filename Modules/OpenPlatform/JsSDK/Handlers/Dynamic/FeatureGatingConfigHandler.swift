//
//  FeatureGatingConfigHandler.swift
//  LarkWeb
//
//  Created by zhenning on 2019/12/12.
//

import Swinject
import LKCommonsLogging
import LarkFeatureGating
import WebBrowser
import LarkContainer
import LarkSetting

class FeatureGatingConfigHandler: JsAPIHandler {

    private let resolver: UserResolver
    private static let logger = Logger.log(FeatureGatingConfigHandler.self, category: "FeatureGatingConfigHandler")

    init(resolver: UserResolver) {
        self.resolver = resolver
    }

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        FeatureGatingConfigHandler.logger.debug("handle args = \(args))")
        if let featureGatingKey = args["key"] as? String {
            let fgKey = FeatureGatingManager.Key(stringLiteral: featureGatingKey)
            let featureGatingValue = resolver.fg.dynamicFeatureGatingValue(with: fgKey)
            if let onSuccess = args["onSuccess"] as? String {
                let arguments = [["result": "\(featureGatingValue)"]] as [[String: Any]]
                callbackWith(api: api, funcName: onSuccess, arguments: arguments)
            }
            FeatureGatingConfigHandler.logger.debug("FeatureGatingConfigHandler success, featureGatingKey = \(featureGatingKey), result = \(featureGatingValue)")
        } else {
            onFailedCallback(argus: args, webApi: api)
            FeatureGatingConfigHandler.logger.error("FeatureGatingConfigHandler failed, featureGatingKey is empty")
        }
    }

    func onFailedCallback(argus args: [String: Any], webApi api: WebBrowser) {
        let arguments = [NewJsSDKErrorAPI.missingRequiredArgs.description()] as [[String: Any]]
        if let onFailed = args["onFailed"] as? String {
            self.callbackWith(api: api, funcName: onFailed, arguments: arguments)
        }
    }

}
