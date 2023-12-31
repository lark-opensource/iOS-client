//
//  MemoryStoreGetHandler.swift
//  LarkWeb
//
//  Created by zhenning on 2019/12/12.
//

import WebBrowser
import LKCommonsLogging

class MemoryStoreGetHandler: JsAPIHandler {

    private static let logger = Logger.log(MemoryStoreGetHandler.self, category: "MemoryStoreGetHandler")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        MemoryStoreGetHandler.logger.debug("handle args = \(args))")

        if let key = args["key"] as? String,
            let defaultValue = args["default"] as? String {
            let value = StoreForDynamic.value(forKey: key, defaultValue: defaultValue)
            if let onSuccess = args["onSuccess"] as? String {
                let arguments = [["value": value]] as [[String: Any]]
                callbackWith(api: api, funcName: onSuccess, arguments: arguments)
                MemoryStoreGetHandler.logger.debug("MemoryStoreGetHandler success, key = \(key), default = \(defaultValue)")
            }
        } else if let keys = args["keys"] as? [String] {
            let result = self.getResultByKeys(keys: keys)
            if let onSuccess = args["onSuccess"] as? String {
                let arguments = [["result": result]] as [[String: Any]]
                callbackWith(api: api, funcName: onSuccess, arguments: arguments)
                MemoryStoreGetHandler.logger.debug("MemoryStoreGetHandler success, keys = \(keys), resultCount = \(result.count)")
            }
        } else {
            if let onFailed = args["onFailed"] as? String {
                let arguments = [NewJsSDKErrorAPI.missingRequiredArgs.description()] as [[String: Any]]
                callbackWith(api: api, funcName: onFailed, arguments: arguments)
            }
            MemoryStoreGetHandler.logger.error("MemoryStoreGetHandler failed, key is empty")
        }
    }

    func getResultByKeys(keys: [String]) -> [String: Any] {
        let result = keys.reduce(into: [String: Any]()) {
            $0[$1] = StoreForDynamic.value(forKey: $1, defaultValue: "")
        }
        return result
    }
}
