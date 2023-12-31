//
//  SecurityPolicyCache.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/8/4.
//

import Foundation
import LarkSecurityComplianceInfra

extension SecurityPolicyV2 {
    enum CacheType {
        case fifo(maxSize: Int)
        case lru(maxSize: Int)
        case unordered
    }
}

protocol SecurityPolicyCache {
    var type: SecurityPolicyV2.CacheType { get }

    /// 当前缓存内容的数量
    var count: Int { get }

    /// 初始化方法
    /// - Parameters:
    ///   - userID: 用户id，用于做用户数据隔离
    ///   - maxSize: 缓存上限，部分缓存类型例如 UnorderedCache，暂不支持缓存上限
    ///   - cacheKey: 缓存标识符
    init(userID: String, maxSize: Int, cacheKey: String)
    
    /// write Cache
    /// - Parameters:
    ///   - value: 存储的value值
    ///   - rawKey: 存储用的原始key值，内部会做md5
    func write<T: Codable>(value: T, forKey rawKey: String)
    
    /// read Cache
    /// - Parameter rawKey: 从磁盘中获取缓存的key值
    /// - Returns: 磁盘中缓存的数据value
    func read<T: Codable>(forKey rawKey: String) -> T?

    /// remove key in Cache
    /// - Parameter rawKey: 从磁盘中获取缓存的key值
    func removeValue(forKey rawKey: String)
    
    /// 某 key 是否有值
    func contains(forKey rawKey: String) -> Bool
    
    /// 清理缓存的内容
    func cleanAll()
    
}
