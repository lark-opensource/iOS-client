//
//  PermissionCode.swift
//  LarkMinutesAPI
//
//  Created by lvdaqian on 2021/1/29.
//

import Foundation

public struct PermissionCode: OptionSet, Codable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let none = PermissionCode(rawValue: 0)
    public static let view = PermissionCode(rawValue: 1 << 0)
    public static let comment = PermissionCode(rawValue: 1 << 1)
    public static let edit = PermissionCode(rawValue: 1 << 2)
    public static let share = PermissionCode(rawValue: 1 << 3)
    public static let copy = PermissionCode(rawValue: 1 << 4)
    public static let owner = PermissionCode(rawValue: 1 << 7)

    public static func type(value: Int) -> PermissionCode {
        if (value & PermissionCode.owner.rawValue) != 0 {
            return .owner
        } else if (value & PermissionCode.edit.rawValue) != 0 {
            return .edit
        } else if (value & PermissionCode.view.rawValue) != 0 {
            return .view
        } else {
            return .none
        }
    }
}
