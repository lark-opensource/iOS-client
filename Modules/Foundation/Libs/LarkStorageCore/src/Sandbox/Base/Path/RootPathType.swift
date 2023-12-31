//
//  StorageType.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

public enum RootPathType {

    /// 内置的沙盒目录类型
    public enum Normal: String {
        /// 对应内置的 Documents 目录：path/to/sandbox/Documents
        case document

        /// 对应内置的 Library 目录：path/to/sandbox/Library
        case library

        /// 对应内置的 Library/Caches 目录：path/to/sandbox/Library/Caches
        case cache

        /// 对应内置的 tmp 目录：path/to/sandbox/tmp
        case temporary
    }

    case normal(Normal)

    /// 跨进程共享场景用的内置沙盒目录类型
    public enum Shared: String {
        /// path/to/sharedContainer/
        case root

        /// path/to/sharedContainer/Library
        case library

        /// path/to/sharedContainer/Library/Caches
        case cache
    }

    case shared(Shared)
}

extension RootPathType: CustomStringConvertible, Hashable {

    public var description: String {
        switch self {
        case .normal(let normal):
            return "normal_" + normal.rawValue
        case .shared(let shared):
            return "shared_" + shared.rawValue
        }
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.description == rhs.description
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(description)
    }

}

extension RootPathType.Normal {

    /// 相对于 HomeDirectory 的路径
    var relativePath: String {
        switch self {
        case .document: return "Documents"
        case .library: return "Library"
        case .cache: return "Library/Caches"
        case .temporary: return "tmp"
        }
    }

    public var absPath: AbsPath {
        switch self {
        case .library: return .library
        case .cache: return .cache
        case .document: return .document
        case .temporary: return .temporary
        }
    }

}
