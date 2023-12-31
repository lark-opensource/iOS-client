//
//  CacheDirectory.swift
//  LarkCache
//
//  Created by Supeng on 2020/8/11.
//

import Foundation
import LarkStorage

/// Cache路径
public enum CacheDirectory: Hashable {
    // 对应Document目录
    case document
    // 对应Library目录
    case library
    // 对应Library/Cache目录
    case cache

    var dirName: String {
        switch self {
        case .document:
            return "document"
        case .library:
            return "library"
        case .cache:
            return "library/Caches"
        }
    }
    /// 缓存存放路径，cacheDirecotry标识的路径+biz标识的文件夹
    public var path: String {
        switch self {
        case .document:
            return AbsPath.document.absoluteString
        case .cache:
            return AbsPath.cache.absoluteString
        case .library:
            return AbsPath.library.absoluteString
        }
    }
}

// lint:enable lark_storage_check
