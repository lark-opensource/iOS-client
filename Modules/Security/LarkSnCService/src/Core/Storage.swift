//
//  Storage.swift
//  LarkSnCService
//
//  Created by Bytedance on 2022/8/8.
//

import Foundation

public enum StorageSpace {
    case global
    case user
}

/// 存储协议
public protocol Storage {
    /// 存储 key: value 数据， 如果 value 为 nil，将删除存储的值
    /// - Parameters:
    ///   - value: 数据
    ///   - forKey: 键
    func set<T: Codable>(_ value: T?, forKey: String, space: StorageSpace) throws
    /// 根据 key 读取数据 value
    /// - Parameter key: 键
    /// - Returns: 值
    func get<T: Codable>(key: String, space: StorageSpace) throws -> T?
    /// 移除 key 对应的 value
    /// - Parameter key: 键
    /// - Returns: 值
    func remove<T: Codable>(key: String, space: StorageSpace) throws -> T?
    /// 清除所有数据
    func clearAll(space: StorageSpace)
}

public extension Storage {
    /// 存储 key: value 数据， 如果 value 为 nil，将删除存储的值
    /// - Parameters:
    ///   - value: 数据
    ///   - forKey: 键
    func set<T: Codable>(_ value: T?, forKey: String) throws {
        try set(value, forKey: forKey, space: .user)
    }
    /// 根据 key 读取数据 value
    /// - Parameter key: 键
    /// - Returns: 值
    func get<T: Codable>(key: String) throws -> T? {
        return try get(key: key, space: .user)
    }
    /// 移除 key 对应的 value
    /// - Parameter key: 键
    /// - Returns: 值
    func remove<T: Codable>(key: String) throws -> T? {
        return try remove(key: key, space: .user)
    }
    /// 清除所有数据
    func clearAll() {
        clearAll(space: .user)
    }
}
