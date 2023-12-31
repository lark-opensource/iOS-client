//
//  CheckJSAPIHandler.swift
//  LarkWeb
//
//  Created by zhenning on 2019/12/12.
//

import WebBrowser
import LKCommonsLogging
import LarkContainer

class CheckJSAPIHandler: JsAPIHandler {

    private static let logger = Logger.log(CheckJSAPIHandler.self, category: "CheckJSAPIHandler")
    private let resolver: UserResolver

    init(resolver: UserResolver) {
        self.resolver = resolver
    }

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        CheckJSAPIHandler.logger.debug("handle args = \(args))")

        if let apiName = args["api"] as? String {
            let apiDict: [String: () -> LarkWebJSAPIHandler] = DynamicJsAPIHandlerProvider(api: api, resolver: self.resolver).handlers
            if apiDict.keys.contains(apiName) {
                if let onSuccess = args["onSuccess"] as? String {
                    let arguments = [["api": "\(apiName)"]] as [[String: Any]]
                    callbackWith(api: api, funcName: onSuccess, arguments: arguments)
                }
                CheckJSAPIHandler.logger.debug("CheckJSAPIHandler success, apiName = \(apiName)")
            } else {
                onFailedCallback(argus: args, webApi: api)
                CheckJSAPIHandler.logger.error("CheckJSAPIHandler failed, apiName = \(apiName)")
            }
        } else {
            onFailedCallback(argus: args, webApi: api)
            CheckJSAPIHandler.logger.error("CheckJSAPIHandler failed, apiName is empty")
        }
    }

    func onFailedCallback(argus args: [String: Any], webApi api: WebBrowser) {
        let arguments = [NewJsSDKErrorAPI.missingRequiredArgs.description()] as [[String: Any]]
        if let onFailed = args["onFailed"] as? String {
            self.callbackWith(api: api, funcName: onFailed, arguments: arguments)
        }
    }

}
