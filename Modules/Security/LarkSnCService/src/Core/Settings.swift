//
//  Settings.swift
//  LarkSnCService
//
//  Created by Bytedance on 2022/8/15.
//

import Foundation

/// Settings 协议
public protocol Settings {
    /// 根据 key 获取 setting 值
    /// - Parameters:
    ///   - key: 键
    /// - Returns: 值
    func setting<T: Decodable>(key: String) throws -> T?
}

public extension Settings {
    /// 获取 Bool 类型的值
    /// - Parameters:
    ///   - key: 键
    ///   - default: 默认值
    /// - Returns: 值
    func bool(key: String, default: Bool) throws -> Bool {
        return try setting(key: key) ?? `default`
    }

    /// 获取 Int 类型的值
    /// - Parameters:
    ///   - key: 键
    ///   - default: 默认值
    /// - Returns: 值
    func int(key: String, default: Int) throws -> Int {
        return try setting(key: key) ?? `default`
    }

    /// 获取 String 类型的值
    /// - Parameters:
    ///   - key: 键
    ///   - default: 默认值
    /// - Returns: 值
    func string(key: String, default: String) throws -> String {
        return try setting(key: key) ?? `default`
    }
    
    /// 获取 [String] 类型的值
    /// - Parameters:
    ///   - key: 键
    ///   - default: 默认值
    /// - Returns: 值
    func stringList(key: String, default: [String]) throws -> [String] {
        return try setting(key: key) ?? `default`
    }
}
