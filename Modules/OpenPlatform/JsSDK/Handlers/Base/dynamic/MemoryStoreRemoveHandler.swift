//
//  MemoryStoreRemoveHandler.swift
//  LarkWeb
//
//  Created by zhenning on 2019/12/12.
//

import WebBrowser
import LKCommonsLogging

class MemoryStoreRemoveHandler: JsAPIHandler {

    private static let logger = Logger.log(MemoryStoreRemoveHandler.self, category: "MemoryStoreRemoveHandler")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        MemoryStoreRemoveHandler.logger.debug("handle args = \(args))")

        if let key = args["key"] as? String {
            StoreForDynamic.removeValue(key: key)
            if let onSuccess = args["onSuccess"] as? String {
                let arguments = [[]] as [Any]
                callbackWith(api: api, funcName: onSuccess, arguments: arguments)
                MemoryStoreRemoveHandler.logger.debug("MemoryStoreRemoveHandler success, key = \(key)")
            }
        } else if let keys = args["keys"] as? [String] {
            keys.forEach { StoreForDynamic.removeValue(key: $0) }

            if let onSuccess = args["onSuccess"] as? String {
                let arguments = [[]] as [[Any]]
                callbackWith(api: api, funcName: onSuccess, arguments: arguments)
                MemoryStoreRemoveHandler.logger.debug("MemoryStoreRemoveHandler success, keys = \(keys)")
            }
        } else {
            if let onFailed = args["onFailed"] as? String {
                let arguments = [NewJsSDKErrorAPI.missingRequiredArgs.description()] as [[String: Any]]
                callbackWith(api: api, funcName: onFailed, arguments: arguments)
            }
            MemoryStoreRemoveHandler.logger.error("MemoryStoreRemoveHandler failed, key or value is not founds")
        }
    }
}
