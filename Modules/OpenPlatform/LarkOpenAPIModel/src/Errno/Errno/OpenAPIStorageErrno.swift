//
//  OpenAPIStorageErrno.swift
//  LarkOpenAPIModel
//
//  Created by ByteDance on 2022/10/11.
//

import Foundation

/// 数据缓存 - setStorageErrno
public enum OpenAPISetStorageErrno: OpenAPIErrnoProtocol {
    // 超过最大存储值
    case storageExceed
    // 总存储超过最大限制
    case totalStorageExceed

    public var bizDomain: Int { 18 }
    public var funcDomain: Int { 1 }

    public var rawValue: Int {
        switch self {
        case .storageExceed:
            return 1
        case .totalStorageExceed:
            return 2
        }
    }
    
    public var errString: String {
        switch self {
        case .storageExceed:
            return "Storage limit exceeded. No larger than 1 MB for one single key."
        case .totalStorageExceed:
            return "Storage limit exceeded. No larger than 10 MB for total data storage."
        }
    }
}

/// 数据缓存 - getStorageErrno
public enum OpenAPIGetStorageErrno: OpenAPIErrnoProtocol {
    // 找不到 key 对应的 value
    case keyNotFound(key: String)

    public var bizDomain: Int { 18 }
    public var funcDomain: Int { 2 }

    public var rawValue: Int {
        switch self {
        case .keyNotFound:
            return 1
        }
    }
    
    public var errString: String {
        switch self {
        case .keyNotFound(let key):
            return "Key `\(key)` not found."
        }
    }
}

// 数据缓存 - removeStorageErrno
public enum OpenAPIRemoveStorageErrno: OpenAPIErrnoProtocol {
    // removeStorage 中某个 key: %s 失败
    case unableToRemoveKey(key: String)

    public var bizDomain: Int { 18 }
    public var funcDomain: Int { 3 }

    public var rawValue: Int {
        switch self {
        case .unableToRemoveKey:
            return 1
        }
    }
    
    public var errString: String {
        switch self {
        case .unableToRemoveKey(let key):
            return "Unable to remove key `\(key)`"
        }
    }
}

/// 数据缓存 - clearStorageErrno
public enum OpenAPIClearStorageErrno: OpenAPIErrnoProtocol {
    // 清除数据失败
    case clearStorageFail

    public var bizDomain: Int { 18 }
    public var funcDomain: Int { 4 }

    public var rawValue: Int {
        switch self {
        case .clearStorageFail:
            return 1
        }
    }
    
    public var errString: String {
        switch self {
        case .clearStorageFail:
            return "Unable to clear storage"
        }
    }
}
