//
//  NotStrictly.swift
//  LarkStorage
//
//  Created by 7Up on 2022/9/14.
//

import Foundation

/// 使用 `.notStrictly` 包装一些非严格的接口，譬如：
///
///     ```
///     let path: AbsPath
///     try path.notStrictly.removeItem()
///     ```
///
/// 严格模式下，不允许基于 AbsPath 删除某个文件/目录；但为了存量兼容，在非严格模式下开放该能力

public final class NotStrictlyExtension<BaseType> {
    public var base: BaseType
    public init(_ base: BaseType) {
        self.base = base
    }
}

public protocol NotStrictlyExtensionCompatible {
    associatedtype NotStrictlyCompatibleType
    var notStrictly: NotStrictlyCompatibleType { get }
    static var notStrictly: NotStrictlyCompatibleType.Type { get }
}

public extension NotStrictlyExtensionCompatible {
    var notStrictly: NotStrictlyExtension<Self> {
        return NotStrictlyExtension(self)
    }

    static var notStrictly: NotStrictlyExtension<Self>.Type {
        return NotStrictlyExtension.self
    }
}
