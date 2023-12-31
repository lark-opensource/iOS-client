//
//  BitableAdvancedPermissionsDefine.swift
//  SKCommon
//
//  Created by guoqp on 2021/9/15.
// 表单高级权限相关定义

import Foundation
import SwiftyJSON
import SKFoundation
import SKResource

public final class BitableBridgeDataTable: Codable {
    public private(set) var id: String = ""
    public private(set) var name: String = ""

    public init(params: [String: String]) {
        self.id = params["id"] ?? ""
        self.name = params["name"] ?? ""
    }
    public init() { }
}

public final class BitableBridgeData: Codable {
    public private(set) var isPro: Bool = false
    public private(set) var tables: [BitableBridgeDataTable] = []

    public init(params: [String: Any]?) {
        guard let params = params,
              let bridgeData = params["bitable"] as? [String: Any] else { return }
        if let isPro = bridgeData["isPro"] as? Bool {
            self.isPro = isPro
        }
        if let tables = bridgeData["tables"] as? [[String: String]] {
            self.tables = tables.compactMap({
                BitableBridgeDataTable(params: $0)
            })
        }
    }
    public init(
        isPro: Bool,
        tables: [BitableBridgeDataTable]
    ) {
        self.isPro = isPro
        self.tables = tables
    }

    func nameWith(_ tableID: String) -> String {
        if let table = tables.first(where: { $0.id == tableID }) {
            return table.name
        }
        return ""
    }
}

//数据表权限描述
public enum BitablePermissionRuleTableRoleDes: Int {
    case canEditAllFieldsAndRecords //可编辑全部字段和记录
    case canEditAllRecords//可编辑全部记录
    case canEditSomeRecordsAndReadOtherRecords//可编辑部分记录，可阅读其他记录
    case canEditSomeRecordsAndNoOtherRecordsAreVisible//可编辑部分记录，不可见其他记录
    case canReadAllRecords//可阅读全部记录
    case canReadsomeRecords//可阅读部分记录
    case noReadPermission//无权限查看

    var keyWord: String {
        switch self {
        case .canEditAllFieldsAndRecords:
            return BundleI18n.SKResource.Bitable_AdvancedPermission_CanEditFieldAndRecord
        case .canEditAllRecords:
            return BundleI18n.SKResource.Bitable_AdvancedPermission_CanEditAllRecord
        case .canEditSomeRecordsAndReadOtherRecords:
            return BundleI18n.SKResource.Bitable_AdvancedPermission_CanEditSomeRecordAndViewOthers
        case .canEditSomeRecordsAndNoOtherRecordsAreVisible:
            return BundleI18n.SKResource.Bitable_AdvancedPermission_CanEditSomeRecordOnly
        case .canReadAllRecords:
            return BundleI18n.SKResource.Bitable_AdvancedPermission_CanViewAllRecord
        case .canReadsomeRecords:
            return BundleI18n.SKResource.Bitable_AdvancedPermission_CanViewSomeRecord
        case .noReadPermission:
            return BundleI18n.SKResource.Bitable_AdvancedPermission_NoAccess
        }
    }
}

//数据表权限
public enum BitablePermissionRuleTableRole: Int {
    case noPermission = 0 //无权限
    case read = 1 //阅读
    case edit = 2 //编辑
    case own = 4 //管理
}

// 权限规则下的数据表
public final class BitablePermissionRuleTable {
    public private(set) var id: String
    public private(set) var role: BitablePermissionRuleTableRole = .noPermission
    public private(set) var roleDes: BitablePermissionRuleTableRoleDes = .noReadPermission
    public private(set) var name: String
    public private(set) var advanceRowPerm: Bool
    public private(set) var advanceFieldPerm: Bool

    public init(id: String,
                role: BitablePermissionRuleTableRole,
                roleDes: BitablePermissionRuleTableRoleDes,
                name: String,
                advanceRowPerm: Bool,
                advanceFieldPerm: Bool) {
        self.id = id
        self.role = role
        self.roleDes = roleDes
        self.name = name
        self.advanceRowPerm = advanceRowPerm
        self.advanceFieldPerm = advanceFieldPerm
    }
}

//权限规则分类
public enum BitablePermissionRuleType: Int {
    case defaultEdit = 0 //默认编辑
    case defaultRead = 1 //默认阅读
    case custom = 2 //自定义

    public var defaultRule: Bool {
        return self != .custom
    }
}

// 权限规则
public final class BitablePermissionRule {
    public private(set) var name: String
    public private(set) var ruleID: String
    public private(set) var tables: [BitablePermissionRuleTable] = []
    public private(set) var collaborators: [Collaborator] = []
    public private(set) var ruleType: BitablePermissionRuleType
    public private(set) var createdTime: TimeInterval
    public private(set) var updatedTime: TimeInterval

    public init(ruleID: String,
                tables: [BitablePermissionRuleTable],
                collaborators: [Collaborator],
                ruleType: BitablePermissionRuleType,
                name: String,
                createdTime: TimeInterval,
                updatedTime: TimeInterval) {
        self.ruleID = ruleID
        self.name = name
        self.tables = tables
        self.collaborators = collaborators
        self.ruleType = ruleType
        self.createdTime = createdTime
        self.updatedTime = updatedTime
    }

    func apped(_ members: [Collaborator]) {
        collaborators.append(contentsOf: members)
    }

    func removeAllMembers() {
        collaborators.removeAll()
    }

    var ruleDes: String {
        var editCount = 0
        var readCount = 0
        tables.forEach { table in
            if table.role.rawValue >= BitablePermissionRuleTableRole.edit.rawValue {
                editCount += 1
            } else if table.role.rawValue >= BitablePermissionRuleTableRole.read.rawValue {
                readCount += 1
            } else { }
        }

        if editCount > 0, readCount > 0 {
            return BundleI18n.SKResource.Bitable_AdvancedPermission_CanEditNumTable(editCount)
                +  BundleI18n.SKResource.CreationMobile_common_punctuation_comma
                + BundleI18n.SKResource.Bitable_AdvancedPermission_CanViewNumTable(readCount)
        } else if editCount > 0 {
            return BundleI18n.SKResource.Bitable_AdvancedPermission_CanEditNumTable(editCount)
        } else if readCount > 0 {
            return BundleI18n.SKResource.Bitable_AdvancedPermission_CanViewNumTable(readCount)
        } else {
            return BundleI18n.SKResource.Bitable_AdvancedPermission_NoAccessToAnyTable
        }
    }
}

// 表单高级权限结构体
public final class BitablePermissionRules {
    public struct AccessConfig: Codable {
        
        public enum Strategy: Int, Codable, Equatable {
            case forbidden = 0
            case bindRule = 1
        }
        
        public struct Config: Codable, Equatable {
            public let accessStrategy: Strategy
            public let roleId: String?
        }
        
        let defaultConfig: Config
    }
    
    public private(set) var accessConfig: AccessConfig?
    
    public private(set) var defaultEditRole: BitablePermissionRule?
    public private(set) var defaultReadRole: BitablePermissionRule?
    public private(set) var customRoles: [BitablePermissionRule] = []

    public private(set) var allRoles: [BitablePermissionRule] = []

    public init(defaultEditRole: BitablePermissionRule?,
                defaultReadRole: BitablePermissionRule?,
                customRoles: [BitablePermissionRule],
                accessConfig: AccessConfig?) {
        if let defaultEditRole = defaultEditRole {
            self.defaultEditRole = defaultEditRole
            allRoles.append(defaultEditRole)
        }
        if let defaultReadRole = defaultReadRole {
            self.defaultReadRole = defaultReadRole
            allRoles.append(defaultReadRole)
        }
        self.customRoles = customRoles
        allRoles.append(contentsOf: customRoles)

        allRoles.sort {
            $0.createdTime < $1.createdTime
        }
        
        self.accessConfig = accessConfig
    }

    func rule(ruleID: String) -> BitablePermissionRule? {
        return allRoles.first { $0.ruleID == ruleID }
    }

    public var isEmpty: Bool {
        return allRoles.isEmpty
    }
    
    var isFallbackConfigProperlySet: Bool {
        guard let config = accessConfig?.defaultConfig else {
            /// 后端没有返回任何配置
            return false
        }
        if config.accessStrategy == .bindRule {
            guard let roleId = config.roleId else {
                /// 绑定了角色但是 roleId 为空
                return false
            }
            if !allRoles.contains(where: { $0.ruleID == roleId }) {
                /// 绑定了角色但是 roleId 不在已有的 Role 列表里面（role 可能被删除）
                return false
            }
        }
        return true
    }
    
    func updateFallbackConfig(_ config: AccessConfig?) {
        accessConfig = config
    }
}

typealias DefaultCollaborators = (read: [Collaborator], edit: [Collaborator])

public final class BitablePermissionRuleParser: NSObject {
    static func parsePermissionRules(_ json: JSON, bridgeData: BitableBridgeData) -> BitablePermissionRules {

        var defaultEditRole: BitablePermissionRule?
        var defaultReadRole: BitablePermissionRule?
        var customRoles: [BitablePermissionRule] = []

        let roleMap = json["roleMap"].dictionaryValue
        let defaultEditRuleID = json["defaultEditRole"]["roleId"].string
        let defaultReadRuleID = json["defaultReadRole"]["roleId"].string
        let defaultCollaborators = parseExtraMembers(json["extraMembers"])

        for (ruleID, value) in roleMap {
            if ruleID == defaultEditRuleID {
                defaultEditRole = parsePermissionRule(value, ruleType: .defaultEdit, bridgeData: bridgeData)
                defaultEditRole?.apped(defaultCollaborators.edit)
            } else  if ruleID == defaultReadRuleID {
                defaultReadRole = parsePermissionRule(value, ruleType: .defaultRead, bridgeData: bridgeData)
                defaultReadRole?.apped(defaultCollaborators.read)
            } else {
                customRoles.append(parsePermissionRule(value, ruleType: .custom, bridgeData: bridgeData))
            }
        }
        
        let accessConfig: BitablePermissionRules.AccessConfig?
        do {
            let data = try json["accessConfig"].rawData()
            accessConfig = try CodableUtility.decode(BitablePermissionRules.AccessConfig.self, data: data)
        } catch(let error) {
            DocsLogger.error("BitablePermissionRules.AccessConfig decode error", error: error)
            accessConfig = nil
        }
        
        return BitablePermissionRules(defaultEditRole: defaultEditRole, defaultReadRole: defaultReadRole, customRoles: customRoles, accessConfig: accessConfig)
    }

    static func parsePermissionRule(_ json: JSON, ruleType: BitablePermissionRuleType, bridgeData: BitableBridgeData) -> BitablePermissionRule {
        let name = json["name"].stringValue
        let tables = parsePermissionRuleTables(json["tableRoleMap"], bridgeData: bridgeData)
        let collaborators = parsePermissionRuleCollaborators(json["members"].arrayValue)
        let ruleID = json["roleId"].stringValue
        let createdTime = json["createdTime"].doubleValue
        let updatedTime = json["updatedTime"].doubleValue
        return BitablePermissionRule(ruleID: ruleID, tables: tables, collaborators: collaborators, ruleType: ruleType, name: name, createdTime: createdTime, updatedTime: updatedTime)
    }

    static func parsePermissionRuleTables(_ json: JSON, bridgeData: BitableBridgeData) -> [BitablePermissionRuleTable] {
        var tables: [BitablePermissionRuleTable] = []
        for (_, value) in json.dictionaryValue {
            tables.append(parsePermissionRuleTable(value, bridgeData: bridgeData))
        }
        /// 排序
        let sortTables: [BitablePermissionRuleTable] = bridgeData.tables.compactMap { bridgeDataTable in
            if let ruleTable = tables.first(where: { $0.id == bridgeDataTable.id }) {
                return ruleTable
            }
            return BitablePermissionRuleTable(id: bridgeDataTable.id, role: .noPermission, roleDes: .noReadPermission, name: bridgeDataTable.name, advanceRowPerm: false, advanceFieldPerm: false)
        }
        return sortTables
    }

    static func parsePermissionRuleTable(_ json: JSON, bridgeData: BitableBridgeData) -> BitablePermissionRuleTable {

        let perm = json["perm"].intValue
        let recRule = json["recRule"].dictionaryValue
        let otherPerm = json["recRule"]["otherPerm"].intValue
        let roleDes: BitablePermissionRuleTableRoleDes
        let fieldPerm = json["fieldPerm"].dictionaryValue
        if perm == BitablePermissionRuleTableRole.own.rawValue {
            roleDes = .canEditAllFieldsAndRecords
        } else if perm == BitablePermissionRuleTableRole.edit.rawValue, recRule.isEmpty {
            roleDes = .canEditAllRecords
        } else if perm == BitablePermissionRuleTableRole.edit.rawValue, otherPerm == BitablePermissionRuleTableRole.read.rawValue {
            roleDes = .canEditSomeRecordsAndReadOtherRecords
        } else if perm == BitablePermissionRuleTableRole.edit.rawValue, otherPerm == BitablePermissionRuleTableRole.noPermission.rawValue {
            roleDes = .canEditSomeRecordsAndNoOtherRecordsAreVisible
        } else if perm == BitablePermissionRuleTableRole.read.rawValue, recRule.isEmpty {
            roleDes = .canReadAllRecords
        } else if perm == BitablePermissionRuleTableRole.read.rawValue, !recRule.isEmpty {
            roleDes = .canReadsomeRecords
        } else if perm == BitablePermissionRuleTableRole.noPermission.rawValue {
            roleDes = .noReadPermission
        } else {
            roleDes = .noReadPermission
        }

        let tableId = json["tableId"].stringValue
        let name = bridgeData.nameWith(tableId)
        return BitablePermissionRuleTable(id: tableId,
                                          role: BitablePermissionRuleTableRole(rawValue: json["perm"].intValue) ?? .noPermission,
                                          roleDes: roleDes,
                                          name: name,
                                          advanceRowPerm: !recRule.isEmpty,
                                          advanceFieldPerm: !fieldPerm.isEmpty)
    }

    static func parsePermissionRuleCollaborators(_ jsons: [JSON]) -> [Collaborator] {
        return jsons.compactMap { json in
            let typeRawValue = json["memberType"].intValue
            var avatarURL = json["memberAvatarUrl"].stringValue
            var localImage: UIImage?

            if avatarURL.isEmpty {
                if typeRawValue == CollaboratorType.folder.rawValue {
                    avatarURL = "icon_tool_sharefolder"
                    localImage = BundleResources.SKResource.Common.Tool.icon_tool_sharefolder
                } else if typeRawValue == CollaboratorType.temporaryMeetingGroup.rawValue
                            || typeRawValue == CollaboratorType.permanentMeetingGroup.rawValue {
                    avatarURL = "avatar_meeting"
                    localImage = BundleResources.SKResource.Common.Collaborator.avatar_meeting
                } else if typeRawValue == CollaboratorType.wikiUser.rawValue
                            || typeRawValue == CollaboratorType.newWikiAdmin.rawValue
                            || typeRawValue == CollaboratorType.newWikiMember.rawValue {
                    avatarURL = "avatar_wiki_user"
                    localImage = BundleResources.SKResource.Common.Collaborator.avatar_wiki_user
                } else if typeRawValue == CollaboratorType.organization.rawValue || typeRawValue == CollaboratorType.ownerLeader.rawValue {
                    avatarURL = "icon_collaborator_organization_32"
                    localImage = BundleResources.SKResource.Common.Collaborator.icon_collaborator_organization_32
                } else if typeRawValue == CollaboratorType.userGroup.rawValue {
                    avatarURL = "icon_usergroup"
                    localImage = BundleResources.SKResource.Common.Collaborator.icon_usergroup
                }
            }

            let defaultPerm: UserPermissionMask = [.read]
            let collaborator = Collaborator(rawValue: typeRawValue,
                                userID: json["memberId"].stringValue,
                                name: json["memberName"].stringValue,
                                avatarURL: avatarURL,
                                avatarImage: localImage,
                                userPermissions: defaultPerm,
                                groupDescription: json["memberDepartmentName"].stringValue)
            collaborator.departmentName = json["memberDepartmentName"].stringValue
            collaborator.localizeCollaboratorName(member: json.dictionaryObject ?? [:])
            if UserScopeNoChangeFG.HZK.b2bRelationTagEnabled {
                collaborator.isExternal = json["isExternal"].bool ?? false
                if let tagValue = json["displayTag"]["tag_value"].string,
                   !tagValue.isEmpty {
                    collaborator.organizationTagValue = tagValue
                }
            }
            return collaborator
        }
    }

    static func parseExtraMembers(_ json: JSON) -> DefaultCollaborators {
        let read: [Collaborator] = parsePermissionRuleCollaborators(json["readMembers"].arrayValue)
        let edit: [Collaborator] = parsePermissionRuleCollaborators(json["editMembers"].arrayValue)
        return DefaultCollaborators(read: read, edit: edit)
    }
}

struct BitablePermissionCostInfo: Codable {
    var rowPermitted: Bool?
    var fieldPermitted: Bool?
}
