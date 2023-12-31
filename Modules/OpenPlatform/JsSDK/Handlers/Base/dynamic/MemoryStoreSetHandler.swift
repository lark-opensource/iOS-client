//
//  MemoryStoreSetHandler.swift
//  LarkWeb
//
//  Created by zhenning on 2019/12/12.
//

import WebBrowser
import LKCommonsLogging

class MemoryStoreSetHandler: JsAPIHandler {

    private static let logger = Logger.log(MemoryStoreSetHandler.self, category: "MemoryStoreSetHandler")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        MemoryStoreSetHandler.logger.debug("handle args = \(args))")

        if let key = args["key"] as? String,
            let value = args["value"] as? String {
            StoreForDynamic.setValue(value: value, forKey: key)
            if let onSuccess = args["onSuccess"] as? String {
                let arguments = [[]] as [Any]
                callbackWith(api: api, funcName: onSuccess, arguments: arguments)
                MemoryStoreSetHandler.logger.debug("MemoryStoreSetHandler success, key = \(key)")
            }
        } else if let keys = args["keys"] as? [String],
            let values = args["values"] as? [String] {
            self.setValuesByKeys(keys: keys, values: values)
            if let onSuccess = args["onSuccess"] as? String {
                let arguments = [[]] as [[Any]]
                callbackWith(api: api, funcName: onSuccess, arguments: arguments)
                MemoryStoreSetHandler.logger.debug("MemoryStoreSetHandler success, keys = \(keys))")
            }
        } else {
            if let onFailed = args["onFailed"] as? String {
                let arguments = [NewJsSDKErrorAPI.missingRequiredArgs.description()] as [[String: Any]]
                callbackWith(api: api, funcName: onFailed, arguments: arguments)
            }
            MemoryStoreSetHandler.logger.error("MemoryStoreSetHandler failed, key or value is not founds")
        }
    }

    func setValuesByKeys(keys: [String], values: [String]) {
        if keys.count != values.count {
            MemoryStoreSetHandler.logger.error("setvalues keys count not match! keys = \(keys)")
            return
        }

        for (key, value) in zip(keys, values) {
            StoreForDynamic.setValue(value: value, forKey: key)
        }
    }

}
