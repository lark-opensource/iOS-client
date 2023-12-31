//
//  KVStoreFailProxy.swift
//  LarkStorage
//
//  Created by 7Up on 2022/10/21.
//

import Foundation

/// KVStore Fail Proxy.
/// 拦截上游接口，进行空操作
final class KVStoreFailProxy: KVStoreProxy {
    static var type: KVStoreProxyType { .fail }
    var wrapped: KVStore
    let config: KVStoreConfig

    init(wrapped: KVStore, config: KVStoreConfig) {
        self.wrapped = wrapped
        self.config = config
    }

    // MARK: KVStore Impl

    func value<T: Codable>(forKey key: String) -> T? {
        return nil
    }

    func set<T: Codable>(_ value: T, forKey key: String) {
        // do nothing
    }

    func object<O: NSCodingObject>(forKey key: String) -> O? {
        return nil
    }

    func setObject<O: NSCodingObject>(_ obj: O, forKey key: String) {
        // do nothing
    }

    func register(defaults: [String: Any]) {
        // do nothing
    }

    func contains(key: String) -> Bool {
        return false
    }

    func removeValue(forKey key: String) {
        // do nothing
    }

    func clearAll() {
        // do nothing
    }

    func allKeys() -> [String] {
        return []
    }

    func allValues() -> [String: Any] {
        return [:]
    }
}
