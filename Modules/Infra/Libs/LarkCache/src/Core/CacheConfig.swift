//
//  CacheConfig.swift
//  LarkCache
//
//  Created by Supeng on 2020/8/11.
//

import Foundation

/// Cache配置
public struct CacheConfig {
    /// CacheConfig初始化
    /// - Parameters:
    ///   - relativePath: 相对路径
    ///   - cacheDirectory: cache存放的路径
    ///   - cleanIdentifier: 清理标识符，从下发配置中，根据cleanIdentifier找到配置，来清理缓存
    public init(relativePath: String, cacheDirectory: CacheDirectory, cleanIdentifier: String) {
        self.cachePath = cacheDirectory.path + "/" + relativePath
        self.cleanIdentifier = cleanIdentifier
    }

    /// 缓存存放路径，cacheDirecotry标识的路径+biz标识的文件夹
    public let cachePath: String
    /// 清理标识符
    let cleanIdentifier: String
}
