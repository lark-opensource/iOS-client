//
//  KVStore.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import LKCommonsLogging

// MARK: - KVStore

/// - SeeAlso: [How to use KVStore](https://bytedance.feishu.cn/wiki/S1wrwKsNCiIJjak6XShcP5n0nVe)
/// KeyValue Store -- 实现基础的 get/set
public protocol KVStore: AnyObject {
    func value<T: Codable>(forKey key: String) -> T?
    func set<T: Codable>(_ value: T, forKey key: String)

    /// 同 UserDefaults#register(defaults:)，数据不落盘
    func register(defaults: [String: Any])

    /// 迁移数据到 store 中，如果 store 已经存在该 key，则忽略
    func migrate(values: [String: Any])

    func contains(key: String) -> Bool
    func removeValue(forKey key: String)
    func clearAll()
    func allKeys() -> [String]
    func allValues() -> [String: Any]

    /// 同 UserDefaults#synchronize
    func synchronize()
}

public enum KVStores {
    static let logger = Logger.log(KVStores.self, category: "LarkStorage.KVStore")

    enum AssertEvent: String {
        case unexpectedLogic
        case wrongSpace
        case wrongDomain
        case wrongMode
        case migration
        case rekey
        case initBase
        case saveValue
        case loadValue
        case loadInt
        case encrypt
        case decrypt
        case unavailable
        case mmkvInt64
        case inconsistentType
        case nestedOptional
    }

    static func assert(
        _ condition: @autoclosure () -> Bool,
        _ message: @autoclosure () -> String = String(),
        event: AssertEvent,
        extra: [AnyHashable: Any]? = nil,
        file: String = #fileID,
        line: Int = #line
    ) {
        guard !condition() else { return }
        let msg = message()
        logger.error("msg: \(msg), extra: \(extra ?? [:])", file: file, line: line)
        let config = AssertReporter.AssertConfig(scene: "key_value", event: event.rawValue)
        AssertReporter.report(msg, config: config, extra: extra, file: file, line: line)
        // if AssertReporter.enableAssertionFailure {
        //     assertionFailure("message: \(msg), config: \(config)")
        // }
    }

    public static func assertionFailure(
        _ message: @autoclosure () -> String = String(),
        extra: [AnyHashable: Any]? = nil,
        file: String = #fileID,
        line: Int = #line
    ) {
        self.assert(false, message(), event: .unexpectedLogic, extra: extra, file: file, line: line)
    }
}

extension KVStores: TypedSpaceCompatible {}

extension KVStores {
    /// attach common proxies
    static func attachingCommonProxies(
        to base: KVStoreBase,
        with config: KVStoreConfig
    ) -> KVStore {
        return attachingProxies(.commons, config: config, to: base)
    }

    static func attachingProxies(
        _ proxies: KVStoreProxySet,
        config: KVStoreConfig,
        to base: KVStoreBase
    ) -> KVStore {
        var ret: KVStore = base
        if proxies.contains(.fail) {
            ret = KVStoreFailProxy(wrapped: ret, config: config)
        }
        if proxies.contains(.log) {
            ret = KVStoreLogProxy(wrapped: ret, config: config)
        }
        if proxies.contains(.rekey) {
            ret = KVStoreRekeyProxy(wrapped: ret, config: config)
        }
        if proxies.contains(.migrate) {
            ret = KVStoreMigrateProxy(wrapped: ret, config: config)
        }
        if proxies.contains(.track) {
            ret = KVStoreTrackProxy(wrapped: ret, config: config)
        }
        return ret
    }
}

extension KVStore {
    var log: Log { KVStores.logger }
    static var log: Log { KVStores.logger }
}

public enum KVStoreMode: Equatable {
    case normal
    case shared

    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.normal, .normal): return true
        case (.shared, .shared): return true
        default: return false
        }
    }
}

enum KVStoreAction: String {
    case getValue
    case setValue
    case getObject
    case setObject
    case registerDefaults
    case migrateValues
    case containsKey
    case removeValue
    case clearAll
    case getAll
    case getAllKeys
}
