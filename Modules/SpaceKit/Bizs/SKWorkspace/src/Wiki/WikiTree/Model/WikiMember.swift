//
//  WikiMember.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/12/23.
//  

import Foundation
import SKCommon
import SKResource
import SKFoundation
import SpaceInterface

public enum WikiUserRole: Int {
    case visitor
    case member
    case admin
}

public struct WikiMember: Codable {

    public enum MemberType: Int, Codable {
        case user = 0             // 用户
        case group = 2            // 群聊
        case department = 18       // 组织架构
        case userGroup = 22       // 用户组
        case unknowned = -99

        public var displayIcon: UIImage? {
            switch self {
            case .user:
                return nil
            case .group:
                return nil
            case .department:
                return BundleResources.SKResource.Common.Icon.icon_organization_wiki
            case .userGroup:
                return BundleResources.SKResource.Common.Icon.icon_usergroup_wiki
            case .unknowned:
                return nil
            }
        }
    }

    public let memberID: String
    let type: Int
    let name: String
    let enName: String
    var aliasInfo: UserAliasInfo?

    private let iconPath: String
    var iconURL: URL? {
        return URL(string: iconPath)
    }

    let memberDescription: String
    let role: Int
    public var memberRole: WikiUserRole {
        WikiUserRole(rawValue: role) ?? .member
    }
    public var memberType: MemberType {
        MemberType(rawValue: type) ?? .unknowned
    }

    public init(memberID: String,
                type: Int,
                name: String,
                enName: String,
                aliasInfo: UserAliasInfo?,
                iconPath: String,
                memberDescription: String,
                role: Int) {
        self.memberID = memberID
        self.type = type
        self.name = name
        self.enName = enName
        self.aliasInfo = aliasInfo
        self.iconPath = iconPath
        self.memberDescription = memberDescription
        self.role = role
    }
    
    enum CodingKeys: String, CodingKey {
        case memberID           = "member_id"
        case type               = "member_type"
        case name               = "member_name"
        case enName             = "member_en_name"
        case iconPath           = "icon_url"
        case memberDescription  = "description"
        case role               = "member_role"
    }

    public static func isRoleGreater(lhs: WikiMember, rhs: WikiMember) -> Bool {
        return lhs.role > rhs.role
    }
}

extension WikiMember: WikiMemberListDisplayProtocol {
    public var displayName: String {
        if let aliasName = aliasInfo?.currentLanguageDisplayName {
            return aliasName
        }
        if DocsSDK.currentLanguage == .en_US {
            return enName.isEmpty ? name : enName
        } else {
            return name
        }
    }

    public var displayDescription: String {
        memberDescription
    }

    public var displayIcon: UIImage? {
        memberType.displayIcon
    }

    public var displayIconURL: URL? {
        iconURL
    }

    public var displayRole: String {
        if memberRole == .admin {
            return BundleI18n.SKResource.Doc_Wiki_SpaceDetail_RoleAdmin
        } else if memberRole == .member {
            return BundleI18n.SKResource.Doc_Wiki_SpaceDetail_RoleMember
        } else {
            DocsLogger.error("unknown member role found: \(role)")
            return BundleI18n.SKResource.Doc_Wiki_SpaceDetail_RoleMember
        }
    }
}
