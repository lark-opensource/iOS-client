//
//  Error.swift
//  LarkMeegoStorage
//
//  Created by shizhengyu on 2023/3/15.
//

import Foundation

/// Kv Storage Opt Error
public enum KvStorageOptError: LocalizedError {
    /// 查询和存储的数据类型不匹配
    case mismatchedType(debugMsg: String)
    /// 数据库文件不存在
    case databaseNotExist
    /// rust 调用或内部异常
    case rustInnerError(debugMsg: String)
    /// 未归类的错误
    case uncategorizedError(rawError: Error)

    public var errorDescription: String? {
        switch self {
        case .mismatchedType(let debugMsg): return "mismatchedType(\(debugMsg)"
        case .databaseNotExist: return "databaseNotExist"
        case .rustInnerError(let debugMsg): return "rustInnerError(\(debugMsg)"
        case .uncategorizedError(let rawError): return "uncategorizedError(\(rawError.localizedDescription)"
        @unknown default: return "unknown opt error"
        }
    }
}

/// Structure Storage Opt Error (such as sqlite3..)
public enum StructureStorageOptError: LocalizedError {
    /// 数据库文件不存在
    case databaseNotExist
    /// rust 调用或内部异常
    case rustInnerError(debugMsg: String)
    /// 未归类的错误
    case uncategorizedError(rawError: Error)

    public var errorDescription: String? {
        switch self {
        case .databaseNotExist: return "databaseNotExist"
        case .rustInnerError(let debugMsg): return "rustInnerError(\(debugMsg)"
        case .uncategorizedError(let rawError): return "uncategorizedError(\(rawError.localizedDescription)"
        @unknown default: return "unknown opt error"
        }
    }
}
