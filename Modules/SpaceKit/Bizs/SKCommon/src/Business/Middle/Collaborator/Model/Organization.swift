//
//  Organization.swift
//  SKCommon
//
//  Created by liweiye on 2020/8/24.
//

import Foundation
import SKUIKit
import SKResource

extension OrganizationCellItem {
    var collaborator: Collaborator {
        var roleTypeValue = 0
        // 部门
        if self.organizationType == .department {
            roleTypeValue = CollaboratorType.organization.rawValue
        } else {
            // 顶层用户
            roleTypeValue = CollaboratorType.user.rawValue
        }
        return Collaborator(rawValue: roleTypeValue,
                            userID: self.id,
                            name: self.name,
                            avatarURL: self.avatarURL,
                            avatarImage: nil,
                            userPermissions: UserPermissionMask(rawValue: 1),
                            groupDescription: nil)
    }
}

class DepartmentInfo: OrganizationCellItem, Codable, SKBreadcrumbItem {
    var itemID: String { return id }
    var displayName: String { return name }
    var id: String
    var name: String
    var avatarURL: String
    var organizationType: OrganizationCellType {
        return .department
    }
    var selectType: SelectType
    var isExist: Bool

    enum CodingKeys: String, CodingKey {
        case id = "department_id"
        case name
        case avatar
    }

    init(departmentId: String, name: String, avatarURL: String) {
        self.id = departmentId
        self.name = name
        self.avatarURL = avatarURL
        self.selectType = .none
        self.isExist = false
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: CodingKeys.id)
        name = try container.decode(String.self, forKey: CodingKeys.name)
        avatarURL = try container.decode(String.self, forKey: CodingKeys.avatar)
        self.selectType = .none
        self.isExist = false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: CodingKeys.id)
        try container.encode(name, forKey: CodingKeys.name)
        try container.encode(avatarURL, forKey: CodingKeys.avatar)
    }
}

extension DepartmentInfo {

    public static var contactsId: String {
        return "contacts"
    }

    public static var rootDepartmentId: String {
        return "0"
    }

    public static var rootDepartment: DepartmentInfo {
        return DepartmentInfo(departmentId: DepartmentInfo.rootDepartmentId,
                              name: BundleI18n.SKResource.Doc_Permission_AddUserOrganization,
                              avatarURL: "")
    }

    public static var contacts: DepartmentInfo {
        return DepartmentInfo(departmentId: DepartmentInfo.contactsId,
                              name: BundleI18n.SKResource.Doc_Permission_DepContact,
                              avatarURL: "")
    }
}

class EmployeeInfo: OrganizationCellItem, Codable {
    var id: String
    var name: String
    var avatarURL: String
    var organizationType: OrganizationCellType {
        return .employee
    }
    var selectType: SelectType
    var isExist: Bool

    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case name = "user_name"
        case avatar
    }

    init(userId: String, name: String, avatarURL: String) {
        self.id = userId
        self.name = name
        self.avatarURL = avatarURL
        self.selectType = .none
        self.isExist = false
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: CodingKeys.id)
        name = try container.decode(String.self, forKey: CodingKeys.name)
        avatarURL = try container.decode(String.self, forKey: CodingKeys.avatar)
        self.selectType = .none
        self.isExist = false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: CodingKeys.id)
        try container.encode(name, forKey: CodingKeys.name)
        try container.encode(avatarURL, forKey: CodingKeys.avatar)
    }
}
