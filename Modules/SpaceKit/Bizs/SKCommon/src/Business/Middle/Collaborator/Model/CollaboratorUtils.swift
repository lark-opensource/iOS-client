//
//  CollaboratorUtils.swift
//  SKCommon
//
//  Created by liweiye on 2020/9/8.
//

import Foundation
import SKFoundation
import SKResource

public final class CollaboratorUtils {

    // 设置协作者的默认权限
    // 文件夹：跟随邀请人的权限，邀请人拥有编辑权限，则协作者拥有编辑权限
    // 文档：默认赋予阅读权限
    public static func setupSelectItemPermission(currentItem: Collaborator, objToken: String?, docsType: ShareDocsType, userPermissions: UserPermissionAbility?) {
        // 默认可读性权限
        if currentItem.userPermissions.canView() == false {
            currentItem.userPermissions = currentItem.userPermissions.updatePermRoleType(permRoleType: .viewer)
        }
    }

    // 是否含有组织架构类型的协作者
    public static func containsOrganizationCollaborators(_ collaborators: [Collaborator]) -> Bool {
        return CollaboratorUtils.containsOrganizationCollaboratorsCount(collaborators) > 0
    }
    // 含有组织架构类型的协作者数量
    public static func containsOrganizationCollaboratorsCount(_ collaborators: [Collaborator]) -> Int {
        return collaborators.filter { $0.type == .organization }.count
    }

    // 是否含有多个组织架构类型的协作者
    public static func containsMultiOrganizationCollaborators(_ collaborators: [Collaborator]) -> Bool {
        return CollaboratorUtils.containsOrganizationCollaboratorsCount(collaborators) > 1
    }

    // 是否含有人数超过500的群协作者
    public static func containsLargeGroupCollaborators(_ collaborators: [Collaborator]) -> Bool {
        return collaborators.filter {
            ($0.type == .group || $0.type == .temporaryMeetingGroup || $0.type == .permanentMeetingGroup) && $0.userCount > 500
        }.count > 0
    }

    // 是否含有外部协作者（群或用户）
    public static func containsExternalCollaborators(_ collaborators: [Collaborator]) -> Bool {
        let containsExternalUser = collaborators.filter { $0.isExternal }.count > 0
        let containsExternalGroup = collaborators.filter { $0.type == .group && $0.isCrossTenant }.count > 0
        return containsExternalUser || containsExternalGroup
    }

    // 是否含有内部群
    public static func containsInternalGroupCollaborators(_ collaborators: [Collaborator]) -> Bool {
        return collaborators.filter { $0.type == .group && !$0.isCrossTenant }.count > 0
    }
    //含有内部群协作者数量
    public static func containsGroupCollaboratorsCount(_ collaborators: [Collaborator]) -> Int {
        return collaborators.filter { $0.type == .group }.count
    }

    // 是否允许以组织架构的方式邀请协作者
    public static func addDepartmentEnable(source: CollaboratorInviteSource, docsType: ShareDocsType?) -> Bool {
        // 从模板进入不支持部门搜索
        if case .diyTemplate = source {
            return false
        }
        // C端用户不显示
        let isToNewC = (User.current.info?.isToNewC == true)
        return !isToNewC
    }

    public struct PlaceHolderContext {
        public let source: CollaboratorInviteSource
        public let docsType: ShareDocsType
        public let isForm: Bool
        public let isBitableAdvancedPermissions: Bool
        public let isSingleContainer: Bool
        public let isSameTenant: Bool
        public let isEmailSharingEnabled: Bool

    }
    public static func getCollaboratorSearchPlaceHolder(context: PlaceHolderContext) -> String {
        let departmentEnable = addDepartmentEnable(source: context.source, docsType: context.docsType)
        let userGroupEnable = addUserGroupEnable(context: context)
        // 不支持用户组和组织架构分享（模板分享、C端用户）
        if !departmentEnable && !userGroupEnable {
            return BundleI18n.SKResource.Doc_Facade_CollaboratorsSearchHint()
        }
        // 支持邮箱搜索
        if context.isEmailSharingEnabled && userGroupEnable {
            return BundleI18n.SKResource.LarkCCM_Docs_Share_SearchForEmailUserGroup_Placeholder
        } else if userGroupEnable {
            return BundleI18n.SKResource.LarkCCM_Workspace_Search_UserGroup_Placeholder
        } else if context.isEmailSharingEnabled {
            return BundleI18n.SKResource.LarkCCM_Docs_Share_SearchForEmail_Placeholder
        }
        // 只支持组织架构，不支持用户组（bitable 表单、高级权限，文件夹，1.0 文档）
        return BundleI18n.SKResource.Doc_Permission_AddUserHint
    }

    public static func addUserGroupEnable(context: PlaceHolderContext) -> Bool {
        // 非同租户不允许添加协作者
        guard context.isSameTenant else { return false }
        
        // Forms 支持搜索用户组
        if context.isForm { return UserScopeNoChangeFG.WJS.baseFormShareNotificationV2 }
        
        // Bitable 通用链接分享不支持用户组
        if context.docsType.isBitableSubType {
            return false
        }
        
        // space 文件夹不支持添加用户组为协作者
        if UserScopeNoChangeFG.TYP.permissionUserGroup {
            // space 1.0 文件夹不支持添加用户组为协作者
            if context.docsType == .folder && !context.isSingleContainer {
                return false
            }
        } else {
            // space 文件夹不支持添加用户组为协作者
            if context.docsType == .folder {
                return false
            }
        }
        // 从模板进入不支持部门搜索
        if case .diyTemplate = context.source {
            return false
        }

        if User.current.info?.isToNewC == true {
            return false
        }

        // 仅单容器文档支持用户组授权
        if !context.isBitableAdvancedPermissions, !context.isSingleContainer {
            return false
        }
        
        return true
    }
}

public enum UserGroupType: Int {
    case userGroupAssign = 1 //静态用户组
    case userGroupDynamic = 2 //动态用户组
    
    var collaboratorType: Int {
        switch self {
        case .userGroupAssign: return CollaboratorType.userGroupAssign.rawValue
        case .userGroupDynamic: return CollaboratorType.userGroup.rawValue
        }
    }
}
