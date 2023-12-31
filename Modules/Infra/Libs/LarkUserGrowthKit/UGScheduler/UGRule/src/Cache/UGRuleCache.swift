//
//  UGRuleCache.swift
//  UGRule
//
//  Created by zhenning on 2021/2/3.
//

import Foundation
import LKCommonsLogging

final class UGRuleCache {
    static let shared = UGRuleCache()
    private static let log = Logger.log(UGRuleCache.self, category: "UGScheduler")

    enum Strategy {
        case memory
        case disk
    }

    private lazy var cache: [String: Any] = {
        return [:]
    }()

    func getValueForKey(key: String) -> Any? {
        let storedValue = self.cache[key]
        Self.log.debug("[UGRule]: getValueForKey key = \(key), storedValue = \(storedValue ?? "")")
        return storedValue
    }

    func setValueForKey(key: String, value: Any) {
        self.cache[key] = value
        Self.log.debug("[UGRule]: setValueForkey key = \(key), value = \(value)")
    }
}
