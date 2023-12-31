//
//  File.swift
//  LarkContact
//
//  Created by SuPeng on 5/12/19.
//

import UIKit
import Foundation
import LarkModel
import RustPB
import LarkSearchCore
import LarkSDKInterface
import Homeric

typealias Department = Basic_V1_Department

extension Department: PickerSelectionTrackable {
    public var optionIdentifier: OptionIdentifier { OptionIdentifier.department(id: self.id) }
    public var selectType: PickerSearchSelectType { return .department }
}

extension Department: SelectedOptionInfoConvertable, SelectedOptionInfo {
    public var avaterIdentifier: String { "" }
    public var avatarKey: String { "" }
    public var backupImage: UIImage? { Resources.department_picker_default_icon }
}

enum DepartmentSectionModel {
    /// 部门群
    case ChatInfoSection(chatInfos: [SectionItem])
    /// 部门负责人
    case LeaderSection(leaders: [SectionItem])
    /// 子部门
    case SubDepartmentSection(departments: [SectionItem])
    /// 租户
    case TenantSection(tenants: [SectionItem])
    /// 直属成员
    case ChatterSection(chatters: [SectionItem])
}

enum SectionItem {
    case ChatInfoSectionItem(chatInfo: RustPB.Contact_V1_ChatInfo)
    case LeaderSectionItem(leader: Chatter, type: LeaderType)
    case SubDepartmentSectionItem(tenantId: String?, department: Department, isShowMemberCount: Bool)
    case TenantSectionItem(tenantId: String, tenantName: String, memberCount: Int32, isShowMemberCount: Bool)
    case ChatterSectionItem(chatter: Chatter)
}

extension DepartmentSectionModel {
    var items: [SectionItem] {
        switch self {
        case .ChatInfoSection(chatInfos: let items):
            return items.map { $0 }
        case .LeaderSection(leaders: let items):
            return items.map { $0 }
        case .SubDepartmentSection(departments: let items):
            return items.map { $0 }
        case .TenantSection(tenants: let items):
            return items.map { $0 }
        case .ChatterSection(chatters: let items):
            return items.map { $0 }
        }
    }
}
