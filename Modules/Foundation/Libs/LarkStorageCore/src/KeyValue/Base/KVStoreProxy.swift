//
//  KVStoreProxy.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

// MARK: Proxy Type

public struct KVStoreProxyType: Hashable {
    public var name: String
    public init(name: String) {
        self.name = name
    }
}

public typealias KVStoreProxySet = Set<KVStoreProxyType>

public extension KVStoreProxyType {
    static let crypto = Self(name: "crypto")
    static let log = Self(name: "log")
    static let rekey = Self(name: "rekey")
    static let migrate = Self(name: "migrate")
    static let track = Self(name: "track")
    static let fail = Self(name: "fail")
    static let objc = Self(name: "objc")
}

extension KVStoreProxySet {
    static let commons = Self([.log, .rekey, .migrate, .track])
}

// MARK: Define Proxy

public protocol KVStoreProxy: KVStore {
    static var type: KVStoreProxyType { get }
    var wrapped: KVStore { get set }

    func object<O: NSCodingObject>(forKey key: String) -> O?
    func setObject<O: NSCodingObject>(_ obj: O, forKey key: String)
}

public extension KVStoreProxy {
    func value<T: Codable>(forKey key: String) -> T? {
        return wrapped.value(forKey: key)
    }

    func set<T: Codable>(_ value: T, forKey key: String) {
        wrapped.set(value, forKey: key)
    }

    func register(defaults: [String: Any]) {
        wrapped.register(defaults: defaults)
    }

    func migrate(values: [String: Any]) {
        wrapped.migrate(values: values)
    }

    func contains(key: String) -> Bool {
        wrapped.contains(key: key)
    }

    func removeValue(forKey key: String) {
        wrapped.removeValue(forKey: key)
    }

    func clearAll() {
        wrapped.clearAll()
    }

    func allKeys() -> [String] {
        return wrapped.allKeys()
    }

    func allValues() -> [String: Any] {
        return wrapped.allValues()
    }

    func synchronize() {
        wrapped.synchronize()
    }
}

// MARK: Others

/// 记录 store 的配置
struct KVStoreConfig {
    var space: Space
    var domain: DomainType
    var mode: KVStoreMode = .normal
    var type: KVStoreType = .udkv
}

extension KVStoreConfig: Hashable {
    public static func == (lhs: KVStoreConfig, rhs: KVStoreConfig) -> Bool {
        lhs.space == rhs.space &&
        lhs.domain.hashable == rhs.domain.hashable &&
        lhs.mode == rhs.mode &&
        lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.space)
        hasher.combine(self.domain.hashable)
        hasher.combine(self.mode)
        hasher.combine(self.type)
    }
}
