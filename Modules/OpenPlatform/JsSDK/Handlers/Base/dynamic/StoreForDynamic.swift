//
//  StoreForDynamic.swift
//  LarkWeb
//
//  Created by zhenning on 2019/12/12.
//

import LKCommonsLogging

public class StoreForDynamic {

    private static var memoryStore: [String: String] = [:]
    private static let logger = Logger.log(StoreForDynamic.self, category: "StoreForDynamic")

    /// default value is for the case when store doesn`t have the value for key.
    public class func value(forKey key: String, defaultValue: String) -> String {
        guard let value = self.memoryStore[key] else {
            StoreForDynamic.logger.debug("get value, memoryStore return default for no key: key = \(key))")
            return defaultValue
        }
        return value
    }

    public class func setValue(value: String, forKey key: String) {
        guard !key.isEmpty  else {
            StoreForDynamic.logger.error("set value, key isEmpty!")
            return
        }
        self.memoryStore[key] = value
        StoreForDynamic.logger.debug("set value, memoryStore set key: key = \(key)")
    }

    public class func removeValue(key: String) {
        guard !key.isEmpty  else {
            StoreForDynamic.logger.error("remove value, key isEmpty!")
            return
        }
        self.memoryStore.removeValue(forKey: key)
        StoreForDynamic.logger.debug("remove value, memoryStore remove key: key = \(key)")
    }

}
