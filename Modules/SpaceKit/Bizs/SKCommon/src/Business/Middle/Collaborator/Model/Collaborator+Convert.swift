//  Created by Songwen Ding on 2018/5/14.

import Foundation
import SwiftyJSON
import SKFoundation
import SKResource
import SpaceInterface
import SKInfra

extension Collaborator {
    static func existCollaborators(_ collaborators: [[String: Any]]) -> [Collaborator] {
        var items = [Collaborator]()
        collaborators.forEach { (collaborator) in
            guard let memberType = collaborator["member_type"] as? Int,
                  let memberID = collaborator["member_id"] as? String,
                  let perm = collaborator["perm"] as? Int
            else {
                DocsLogger.info("参数不完整")
                return
            }
            let userPermissions = UserPermissionMask.create(withValue: perm)
            let item = Collaborator(rawValue: memberType, userID: memberID, name: "", avatarURL: "", avatarImage: nil, imageKey: "", userPermissions: userPermissions, groupDescription: "")
            items.append(item)
        }
        return items
    }

    static func existCollaboratorsForFolder(_ collaborators: [[String: Any]]) -> [Collaborator] {
        var items = [Collaborator]()
        collaborators.forEach { (collaborator) in
            guard let memberType = collaborator["collaborator_type"] as? Int,
                  let memberID = collaborator["collaborator_id"] as? String,
                  let perm = collaborator["perm_role"] as? Int
            else {
                DocsLogger.info("参数不完整")
                return
            }
            let userPermissions = UserPermissionMask.create(withPermRole: perm)
            let item = Collaborator(rawValue: memberType, userID: memberID, name: "", avatarURL: "", avatarImage: nil, imageKey: "", userPermissions: userPermissions, groupDescription: "")
            items.append(item)
        }
        return items
    }

    //解析表单
    static func collaborators(form collaborators: [[String: Any]]) -> [Collaborator] {
        var items = [Collaborator]()
        collaborators.forEach { (collaborator) in
            // https://bytedance.feishu.cn/docs/doccnx9x73yom9waPQqLicfEape#7W1pW1
            let collaboratorTypeKey = "memberType"
            let collaboratorIdKey = "memberId"
            let collaboratorName = "memberName"
            guard let typeRawValue = collaborator[collaboratorTypeKey] as? Int,
                  let collaboratorId = collaborator[collaboratorIdKey] as? String,
                  let collaboratorName = collaborator[collaboratorName] as? String
            else {
                spaceAssertionFailure()
                DocsLogger.info("参数不完整")
                return
            }

            var avatarURL = collaborator["avatarUrl"] as? String ?? ""
            var localImage: UIImage?

            // MARK: 加新协作者类型记得在这里补充 avatar 情形
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
                } else if typeRawValue == CollaboratorType.userGroup.rawValue || typeRawValue == CollaboratorType.userGroupAssign.rawValue {
                    avatarURL = "icon_usergroup"
                    localImage = BundleResources.SKResource.Common.Collaborator.icon_usergroup
                }
            }

            let item = Collaborator(rawValue: typeRawValue,
                                    userID: collaboratorId,
                                    name: collaboratorName,
                                    avatarURL: avatarURL,
                                    avatarImage: localImage,
                                    userPermissions: {
                                        var permissions: UserPermissionMask = []
                                        if let permissionsRaw = collaborator["permission"] as? Int {
                                            permissions = UserPermissionMask.create(withValue: permissionsRaw)
                                        }
                                        return permissions
                                    }(),
                                    groupDescription: collaborator["groupDescription"] as? String)
            item.tenantID = collaborator["tenantId"] as? String
            item.tenantName = collaborator["tenantName"] as? String
            item.departmentName = collaborator["departmentName"] as? String
            item.isOwner = collaborator["isOwner"] as? Bool ?? false
            item.isExternal = collaborator["isExternal"] as? Bool ?? false
            item.hasTips = collaborator["has_tips"] as? Bool ?? false
            item.isCrossTenant = collaborator["is_cross_tenant"] as? Bool ?? false
            item.permissionValue = collaborator["permissions"] as? Int ?? 0
            item.canModify = collaborator["can_modify_perm"] as? Bool ?? false
            item.inviterID = collaborator["inviter_id"] as? String
            item.isFriend = collaborator["is_friend"] as? Bool
            if let permSource = collaborator["perm_source"] as? String {
                item.permSource = permSource
            }
            if let blockStatusValue = collaborator["block_status"] as? Int {
                item.blockStatus = BlockStatus(blockStatusValue)
            }
            if let userTypeStr = collaborator["tenant_tag"] as? String, let userType = SKUserType(rawValue: userTypeStr) {
                item.userType = userType
            }
            item.isSingleProduct = collaborator["is_single_product"] as? Bool
            if let userCount = collaborator["user_count"] as? Int {
                item.userCount = userCount
            }
            item.localizeCollaboratorName(member: collaborator)
            if UserScopeNoChangeFG.HZK.b2bRelationTagEnabled {
                if let displayTag = collaborator["displayTag"] as? [String: Any],
                   let tagValue = displayTag["tag_value"] as? String,
                   !tagValue.isEmpty {
                    item.organizationTagValue = tagValue
                }
            }
            items.append(item)
        }
        return items
    }

    //isNewVersion true 2.0文件夹, isOldShareFolder true 1.0旧共享文件夹
    // swiftlint:disable cyclomatic_complexity
    static func collaborators(_ collaborators: [[String: Any]], isOldShareFolder: Bool, isNewVersion: Bool = false) -> [Collaborator] {
        var items = [Collaborator]()
        collaborators.forEach { (collaborator) in
            // 单容器文件夹版本字段不一样，需要区分 https://bytedance.feishu.cn/docs/doccnaVN8u5AB9A6OYoHeA1ZnHn#
            let isNewVersionForShareFolder = isOldShareFolder && isNewVersion
            let collaboratorTypeKey = isNewVersionForShareFolder ? "collaborator_type" : "owner_type"
            let collaboratorIdKey = isNewVersionForShareFolder ? "collaborator_id" : "owner_id"
            let collaboratorName = isNewVersionForShareFolder ? "collaborator_name" : "owner_name"
            guard let rawValue = collaborator[collaboratorTypeKey] as? Int,
                  let userID = collaborator[collaboratorIdKey] as? String,
                  let name = collaborator[collaboratorName] as? String
            else {
                spaceAssertionFailure()
                DocsLogger.info("参数不完整")
                return
            }

            if rawValue == CollaboratorType.ownerLeader.rawValue,
                !UserScopeNoChangeFG.WWJ.imShareLeaderEnable {
                return
            }

            var avatarURL = collaborator["avatar_url"] as? String ?? ""
            var localImage: UIImage?

            // MARK: 加新协作者类型记得在这里补充 avatar 情形
            if avatarURL.isEmpty {
                if rawValue == CollaboratorType.folder.rawValue {
                    avatarURL = "icon_tool_sharefolder"
                    localImage = BundleResources.SKResource.Common.Tool.icon_tool_sharefolder
                } else if rawValue == CollaboratorType.temporaryMeetingGroup.rawValue || rawValue == CollaboratorType.permanentMeetingGroup.rawValue {
                    avatarURL = "avatar_meeting"
                    localImage = BundleResources.SKResource.Common.Collaborator.avatar_meeting
                } else if rawValue == CollaboratorType.wikiUser.rawValue
                            || rawValue == CollaboratorType.newWikiAdmin.rawValue
                            || rawValue == CollaboratorType.newWikiMember.rawValue {
                    avatarURL = "avatar_wiki_user"
                    localImage = BundleResources.SKResource.Common.Collaborator.avatar_wiki_user
                } else if rawValue == CollaboratorType.organization.rawValue || rawValue == CollaboratorType.ownerLeader.rawValue {
                    avatarURL = "icon_collaborator_organization_32"
                    localImage = BundleResources.SKResource.Common.Collaborator.icon_collaborator_organization_32
                } else if rawValue == CollaboratorType.userGroup.rawValue || rawValue == CollaboratorType.userGroupAssign.rawValue {
                    avatarURL = "icon_usergroup"
                    localImage = BundleResources.SKResource.Common.Collaborator.icon_usergroup
                }
            }

//            guard !avatarURL.isEmpty else {
//                DocsLogger.error("无法根据类型得出头像 URL，不显示该协作者类型!")
//                return
//            }

            // 共享文件夹的协作者类型需要单独处理
            var value = rawValue
            if let type = (isOldShareFolder && !isNewVersion) ? CollaboratorType.shareFolderType(rawValue) : CollaboratorType(rawValue: rawValue) {
                value = type.rawValue
            }

            let iconToken = collaborator["icon_token"] as? String

            let item = Collaborator(rawValue: value,
                                    userID: userID,
                                    name: name,
                                    avatarURL: avatarURL,
                                    avatarImage: localImage,
                                    iconToken: iconToken ?? "",
                                    userPermissions: {
                                        var permissions: UserPermissionMask = []
                                        if let permissionsRaw = collaborator["permissions"] as? Int {
                                            permissions = UserPermissionMask.create(withValue: permissionsRaw)
                                        } else if let permissionsRaw = collaborator["perm"] as? Int {
                                            permissions = UserPermissionMask.create(withPermRole: permissionsRaw)
                                        } else if let permissionsRaw = collaborator["perm_role"] as? Int {
                                            // 单容器文件夹版本字段不一样
                                            permissions = UserPermissionMask.create(withPermRole: permissionsRaw)
                                        }
                                        return permissions
                                    }(),
                                    groupDescription: collaborator["group_description"] as? String)
            item.departmentName = collaborator["department_name"] as? String
            if isOldShareFolder && !isNewVersion {
                // 单容器之前版本文件夹接口 is_owner, int类型, 0/1
                if let isOwner = collaborator["is_owner"] as? Int {
                    item.isOwner = (isOwner == 1) ? true : false
                } else {
                    item.isOwner = false
                }
            } else {
                // 文件或单容器文件夹接口 is_owner, bool类型, false/true
                item.isOwner = collaborator["is_owner"] as? Bool ?? false
            }
            item.isExternal = collaborator["is_external"] as? Bool ?? false
            item.hasTips = collaborator["has_tips"] as? Bool ?? false
            item.isCrossTenant = collaborator["is_cross_tenant"] as? Bool ?? false
            item.permissionValue = collaborator["permissions"] as? Int ?? 0
            item.canModify = collaborator["can_modify_perm"] as? Bool ?? false
            item.inviterID = collaborator["inviter_id"] as? String
            item.isFriend = collaborator["is_friend"] as? Bool
            if let displayTag = collaborator["display_tag"] as? [String: Any],
               let tagValue = displayTag["tag_value"] as? String,
               !tagValue.isEmpty {
                item.organizationTagValue = tagValue
            }
            if let permSource = collaborator["perm_source"] as? String {
                item.permSource = permSource
            }
            if let blockStatusValue = collaborator["block_status"] as? Int {
                item.blockStatus = BlockStatus(blockStatusValue)
            }
            if let userTypeStr = collaborator["tenant_tag"] as? String, let userType = SKUserType(rawValue: userTypeStr) {
                item.userType = userType
            }
            item.isSingleProduct = collaborator["is_single_product"] as? Bool
            if let userCount = collaborator["user_count"] as? Int {
                item.userCount = userCount
            }
            item.wikiDescription = collaborator["wiki_description"] as? String
            item.tooltipsType = collaborator["tooltips_type"] as? Int ?? 0
            if let extraInfo = collaborator["extra_info"] as? [String : Any],
            let hostUrl = extraInfo["host_url"] as? String {
                item.extraInfo = ExtraInfo(hostUrl: hostUrl)
            }
            items.append(item)
        }
        return items
    }

    static func localizeCollaboratorName(collaborators: inout [Collaborator], users: [String: Any]) {
        let nameKey = DocsSDK.currentLanguage == .en_US ? "en_name" : "name"
        collaborators.forEach({ (item) in
            guard let info = users[item.userID] as? [String: Any] else { return }
            // 优先用别名
            if let aliasData = info["display_name"] as? [String: Any] {
                let aliasInfo = UserAliasInfo(data: aliasData)
                if let displayName = aliasInfo.currentLanguageDisplayName {
                    item.name = displayName
                    return
                }
            }
            // 其次用本名
            guard let localizedName = info[nameKey] as? String, localizedName.isEmpty == false else { return }
            item.name = localizedName
        })
    }

    func localizeCollaboratorName(member: [String: Any]) {
        let nameKey = DocsSDK.currentLanguage == .en_US ? "memberEnName" : "memberName"
        // 优先用别名
        if var aliasData = member["memberDisplayName"] as? [String: Any] {
            let aliasInfo = UserAliasInfo(data: aliasData)
            if let displayName = aliasInfo.currentLanguageDisplayName {
                self.name = displayName
                return
            }
        }
        // 其次用本名
        guard let localizedName = member[nameKey] as? String, localizedName.isEmpty == false else { return }
        self.name = localizedName
    }

    static func permissionStatistics(collaborators: inout [Collaborator], users: [String: Any]) {
        collaborators.forEach { (item) in
            guard item.type == .user else { return }
            guard let user = users[item.userID] as? [String: Any], let tenantID = user["tenant_id"] as? String else { return }
            item.tenantID = tenantID
            if let userTypeStr = user["tenant_tag"] as? String,
                let userType = SKUserType(rawValue: userTypeStr) {
                item.userType = userType
            }
            item.isSingleProduct = user["is_single_product"] as? Bool
            item.tenantName = user["tenant_name"] as? String
        }
    }

    /// If the user is searchable, all pre-shared records corresponding to the phone number will be converted into real authorization records
    /// related api documents: https://bytedance.feishu.cn/docs/doccnxigLzWtRdBGzcibNhRzQlf
    public static func shareConvert() {
        spaceAssert(DocsSDK.isInLarkDocsApp, "Make sure you really need to call this API because it's only designed for LarkDocs")
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.shareConvert, params: ["trigger_type": 1])
        request.set(method: .POST)
        request.makeSelfReferenced()
        request.start { (_, err) in
            guard err == nil else { DocsLogger.error("shareConvert error"); return }
        }
    }

    // MARK: 加新协作者类型记得在这里补充 case
    // nolint: magic number
    static func explorerSpaceType(type: CollaboratorType) -> Int? {
        switch type {
        case .user, .larkUser: return 0 // 人
        case .group: return 1           // 群
        case .organization: return 18
        case .app: return 19 //app
        case .userGroup: return 22 // 用户组
        case .email: return 29 // 邮箱
        case .userGroupAssign: return 30 //静态用户组
        case .hostDoc: return 110 //宿主文档
        case .ownerLeader: return 111
        case .common, .folder, .meeting, .knowledgeBase, .temporaryMeetingGroup, .permanentMeetingGroup, .wikiUser, .newWikiAdmin, .newWikiMember, .newWikiEditor: return nil
        }
    }

}
