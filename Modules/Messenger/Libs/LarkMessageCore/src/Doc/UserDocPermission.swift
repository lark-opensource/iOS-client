//
//  UserDocPermission.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/19.
//

import Foundation
import RustPB

///第二人称(you) 第三人称(单聊的人名) 第三人称复数(群聊的赋予本会话成员)
public enum PermissionType: Int {
    case secondPerson = 0
    case thirdPerson
    case thirdPersonPlural
}

public protocol DocPermissionState {
    func displayNameWithPermissionType(_ permissionType: PermissionType) -> String
}

extension RustPB.Basic_V1_DocPermission.Permission: DocPermissionState {

    public func displayNameWithPermissionType(_ permissionType: PermissionType) -> String {
        var value = ""
        switch permissionType {
        case .secondPerson:
            value = self.secondPersonDisplayName
        case .thirdPerson:
            value = self.thirdPersonDisplayName
        case .thirdPersonPlural:
            value = self.thirdPersonPluralDisplayName
        }
        return value
    }

    /// 二单（你）别人发给自己需要展示的文案
    private var secondPersonDisplayName: String {
        switch self.code {
        case 1: return BundleI18n.LarkMessageCore.Lark_Legacy_ChatDocPermissionView.localizedLowercase
        case 4: return BundleI18n.LarkMessageCore.Lark_Legacy_ChatDocPermissionEdit.localizedLowercase
        default: return self.name
        }
    }

    // 发送给其他人的(三单(单聊对象)) 需要展示的 可编辑&可阅读文案
    private var thirdPersonDisplayName: String {
        switch self.code {
        case 1: return BundleI18n.LarkMessageCore.Lark_Docs_ChatDocPermissionRead.localizedLowercase
        case 4: return BundleI18n.LarkMessageCore.Lark_Docs_ChatDocPermissionEdit.localizedLowercase
        default: return self.name
        }
    }

    // 发送到群里的(三复（赋予本会话成员)) 需要展示的 可编辑&可阅读文案
    private var thirdPersonPluralDisplayName: String {
        switch self.code {
        case 1: return BundleI18n.LarkMessageCore.Lark_Docs_ChatDocPermissionRead3rdpl.localizedLowercase
        case 4: return BundleI18n.LarkMessageCore.Lark_Docs_ChatDocPermissionEdit3rdpl.localizedLowercase
        default: return self.name
        }
    }

}

public struct UserDocsPermission: OptionSet {
    public let rawValue: Int

    public static let read = UserDocsPermission(rawValue: 1 << 0)
    public static let comment = UserDocsPermission(rawValue: 1 << 1)
    public static let edit = UserDocsPermission(rawValue: 1 << 2)
    public static let share = UserDocsPermission(rawValue: 1 << 3)
    public static let noPerm = UserDocsPermission([])
    public static let unknown = UserDocsPermission(rawValue: -1)

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

}
public extension RustPB.Basic_V1_DocPermission {
    // 根据不同的人称 返回不同的文案
    func docsPermissionStringValueWith(permissionType: PermissionType) -> String {
        var value = ""
        switch permissionType {
        case .secondPerson:
            value = self.secondPersonDocsPermissionStringValue
        case .thirdPerson:
            value = self.thirdPersonDocsPermissionStringValue
        case .thirdPersonPlural:
            value = self.thirdPersonPluralDocsPermissionStringValue
        }
        return value
    }
    /// 二单（你）别人发给自己需要展示的文案
    private var secondPersonDocsPermissionStringValue: String {
        if userDocsPermission.contains(.edit) {
            return BundleI18n.LarkMessageCore.Lark_Legacy_ChatDocPermissionEdit.localizedLowercase
        } else if userDocsPermission.contains(.read) {
            return BundleI18n.LarkMessageCore.Lark_Legacy_ChatDocPermissionView.localizedLowercase
        } else {
            // Docs is private or more than 500 owners(TODO: @YouChaocai)
            return ""
        }
    }

    /// 三单(单聊对象) 单聊需要展示的文案
    private var thirdPersonDocsPermissionStringValue: String {
        if userDocsPermission.contains(.edit) {
            return BundleI18n.LarkMessageCore.Lark_Docs_ChatDocPermissionEdit.localizedLowercase
        } else if userDocsPermission.contains(.read) {
            return BundleI18n.LarkMessageCore.Lark_Docs_ChatDocPermissionRead.localizedLowercase
        } else {
            return ""
        }
    }

    /// 三复（赋予本会话成员）群组需要展示的文案
    private var thirdPersonPluralDocsPermissionStringValue: String {
        if userDocsPermission.contains(.edit) {
            return BundleI18n.LarkMessageCore.Lark_Docs_ChatDocPermissionEdit3rdpl.localizedLowercase
        } else if userDocsPermission.contains(.read) {
            return BundleI18n.LarkMessageCore.Lark_Docs_ChatDocPermissionRead3rdpl.localizedLowercase
        } else {
            return ""
        }
    }

    var userDocsPermission: UserDocsPermission {
        return UserDocsPermission(rawValue: Int(self.userPerm))
    }
}
