//
//  UDResource.swift
//  UniverseDesignTheme
//
//  Created by bytedance on 2021/6/9.
//

import Foundation

/// Universe Design Key
public protocol UDKey: Hashable {
    var key: String { get }
}

/// Universe Design Theme Protocol
public protocol UDResource {

    /// Value
    associatedtype Value

    /// Key
    associatedtype Key: UDKey

    /// Store Map
    var store: SafeDictionary<Key, Value> { get }

    /// Current Theme
    static var current: Self { get set }

    /// init
    /// - Parameter store: store map
    init(store: [Key: Value])

    /// Update Theme
    /// - Parameter theme: UDResource
    static func updateCurrent(_ theme: Self)

    /// Update Store Map
    /// - Parameter store: Store Map
    static func updateCurrent(_ store: [Key: Value])

    /// Get Value By Key
    /// - Parameter key:
    static func getValueByKey(_ key: Key) -> Value?

    /// Get Value By Key
    /// - Parameter key:
    func getValueByKey(_ key: Key) -> Value?

    /// Get Current Store
    static func getCurrentStore() -> [Key: Value]

    /// Get Current Store
    func getCurrentStore() -> [Key: Value]
}

public extension UDResource {
    /// Update Theme
    /// - Parameter theme: UDResource
    static func updateCurrent(_ theme: Self) {
        Self.current = theme
    }

    /// Update Store Map
    /// - Parameter store: Store Map
    static func updateCurrent(_ store: [Key: Value]) {
        let theme = Self(store: store)
        Self.updateCurrent(theme)
    }

    /// Get Value By Key
    /// - Parameter key:
    static func getValueByKey(_ key: Key) -> Value? {
        return current.getValueByKey(key)
    }

    /// Get Value By Key
    /// - Parameter key:
    func getValueByKey(_ key: Key) -> Value? {
        return self.store[key]
    }

    /// Get Current Store
    static func getCurrentStore() -> [Key: Value] {
        return self.current.store.data
    }

    /// Get Current Store
    func getCurrentStore() -> [Key: Value] {
        return self.store.data
    }
}
