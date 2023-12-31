//
//  Permission.swift
//  Calendar
//
//  Created by 张威 on 2020/3/10.
//

import Foundation

// PermissionOption 可以成为全局对象

/// 权限选项
struct PermissionOption: OptionSet {
    let rawValue: Int

    /// 空权限
    static let none = PermissionOption(rawValue: 1 << 0)

    /// 可读/可见
    static let readable = PermissionOption(rawValue: 1 << 1)

    /// 可写/可编辑/可删除；`writable` 包含 `readable` 权限
    static let writable: Self = [.readable, Self(rawValue: 1 << 2)]
}

extension PermissionOption {
    var isReadable: Bool { contains(.readable) }
    var isVisible: Bool { isReadable }

    var isWritable: Bool { contains(.writable) }
    var isEditable: Bool { isWritable }
    var isDeletable: Bool { isWritable }

    var isReadOnly: Bool { contains(.readable) && !contains(.writable) }
}

extension PermissionOption: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return (lhs.rawValue == rhs.rawValue)
    }
}

extension PermissionOption: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

protocol CustomPermissionConvertible {
    var permission: PermissionOption { get }
}
