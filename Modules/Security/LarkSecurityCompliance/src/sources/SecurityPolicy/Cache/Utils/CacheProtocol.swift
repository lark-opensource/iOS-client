//
//  CacheProtocol.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/8/4.
//

import Foundation
import LarkSecurityComplianceInfra

enum CacheType {
    case fifo(maxSize: Int)
    case lru(maxSize: Int)
}
protocol CacheProtocol {
    
    var type: CacheType { get }
    
    /// 初始化方法
    /// - Parameters:
    ///   - userID: 用户id，用于做用户数据隔离
    ///   - maxSize: 缓存上限
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
    
    // TODO: 这个方法在这里提供不合适，但为了最小化改动，临时放一下，后续优化
    /// 给所有缓存标记待清理标记
    func markInvalid()
    
    // TODO: 下面的方法为debug使用，后续优化
    /// 当前缓存数量
    var count: Int { get }
    
    /// 触发缓存清理
    func cleanAll()
    
    /// 获取所有缓存
    /// - Returns: 返回当前缓存容器中的所有缓存的数组
    func getAllRealCache<T: Codable>() -> [T]
    
    /// 获取缓存的第一个和最后一个数据
    /// - Returns: 缓存第一个和最后一个拼接的字符串
    func getSceneCacheHeadAndTail() -> String
}

extension CacheProtocol {
    func markInvalid() {
        SCLogger.info("CacheProtocol mark deleteable", additionalData: ["cacheType": "\(self.type)"])
    }
    
    func cleanAll() {
        SCLogger.info("CacheProtocol clear all", additionalData: ["cacheType": "\(self.type)"])
    }
    
    func getAllRealCache<T: Codable>() -> [T] {
        return []
    }
    
    func getSceneCacheHeadAndTail() -> String {
        return ""
    }
    
    var count: Int {
        return 0
    }
}
