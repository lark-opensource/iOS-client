//
//  TeamAPI.swift
//  LarkSDKInterface
//
//  Created by JackZhao on 2021/7/14.
//

import RustPB
import RxSwift
import ServerPB
import LarkModel
import Foundation

// model
public typealias AvatarMeta = RustPB.Basic_V1_AvatarMeta
public typealias PickEntities = RustPB.Basic_V1_PickEntities
public typealias Team = RustPB.Basic_V1_Team
public typealias NameAvailabilityCheckType = ServerPB.ServerPB_Team_CheckNameAvailabilityRequest.CheckType
public typealias PatchTeamUpdateFiled = RustPB.Im_V1_PatchTeamRequest.UpdateField
public typealias PatchTeamSettingUpdateFiled = RustPB.Im_V1_PatchTeamSettingRequest.UpdateField
public typealias AddTeamChatPermissionType = Basic_V1_TeamSetting.AddTeamChatPermission.TypeEnum
public typealias AddPrivateChatPermissionType = RustPB.Basic_V1_TeamSetting.AddPrivateTeamChatPermission.TypeEnum
public typealias AddMemberPermissionType = RustPB.Basic_V1_TeamSetting.AddMemberPermission.TypeEnum
public typealias TeamChatType = RustPB.Basic_V1_TeamChatType

// Team实体相关
public typealias CreateTeamResponse = RustPB.Im_V1_CreateTeamResponse // 创建团队
public typealias GetTeamsByIdsResponse = RustPB.Im_V1_GetTeamsByIdsResponse // 拉取Team接口
public typealias TeamCheckNameAvailabilityResponse = ServerPB.ServerPB_Team_CheckNameAvailabilityResponse // Team重名校验接口
public typealias PatchTeamResponse = RustPB.Im_V1_PatchTeamResponse // 团队信息修改： 头像、描述等
public typealias GetItemsByEntityIdsResponse = RustPB.Im_V1_GetItemsByEntityIdsResponse // 根据实体id获取item

// 团队权限相关
public typealias PatchTeamSettingResponse = RustPB.Im_V1_PatchTeamSettingResponse // 修改团队权限
public typealias PatchTeamMembersRoleResponse = RustPB.Im_V1_PatchTeamMembersRoleResponse // 添加/删除团队里的角色

// 团队群组
public typealias CreateTeamChatResponse = RustPB.Im_V1_CreateTeamChatResponse //  团队中新加群组
public typealias BindTeamChatResponse = RustPB.Im_V1_BindTeamChatResponse // 添加已有群组
public typealias UnbindTeamChatResponse = RustPB.Im_V1_UnbindTeamChatResponse // 将群从团队里解绑
public typealias UpgradeToTeamResponse = RustPB.Im_V1_UpgradeToTeamResponse // 群升级为团队

// 团队成员相关
public typealias PutTeamChatChattersResponse = RustPB.Im_V1_PutTeamChatChattersResponse // 添加团队成员同时添加群成员
public typealias PutTeamMemberResponse = RustPB.Im_V1_PutTeamMemberResponse // 添加团队成员
public typealias GetTeamMembersResponse = RustPB.Im_V1_GetTeamMembersResponse // 拉取团队成员
public typealias DeleteTeamMemberResponse = RustPB.Im_V1_DeleteTeamMemberResponse // 删除成员/退出团队
public typealias BindTeamChatPreCheckResponse = ServerPB.ServerPB_Team_BindTeamChatPreCheckResponse // 检查待加入团队的群的成员

public typealias PushTeams = RustPB.Im_V1_PushTeams
public typealias PushTeamMembers = RustPB.Im_V1_PushTeamMembers
public typealias PushItems = RustPB.Im_V1_PushItems

public protocol TeamAPI {
    // MARK: Team实体相关接口
    // 创建Team
    func createTeamRequest(name: String,
                           avatarEntity: TeamAvatarEntity?,
                           mode: Chat.ChatMode,
                           chatIds: [String],
                           chatterIds: [String],
                           description: String,
                           departmentIds: [String]) -> Observable<CreateTeamResponse>
    // Team重名校验接口
    func checkNameAvailabilityRequest(name: String,
                                      checkType: NameAvailabilityCheckType,
                                      identify: String?) -> Observable<TeamCheckNameAvailabilityResponse>

    // 拉取Team接口
    func getTeams(teamIds: [Int64], forceServer: Bool) -> Observable<GetTeamsByIdsResponse>
    // 拉取Team：聚合本地和网络请求
    func getTeamsFromLocalAndServer(teamIds: [Int64]) -> Observable<GetTeamsByIdsResponse>

    func getTeams(chatId: String, teamIds: [Int64]) -> Observable<Im_V1_GetTeamsForChatResponse>

    // 团队信息修改：头像、描述等
    func patchTeamRequest(teamId: Int64,
                          updateFiled: [PatchTeamUpdateFiled],
                          name: String?,
                          ownerId: Int64?,
                          isDissolved: Bool?) -> Observable<PatchTeamResponse>

    // 修改team描述
    func patchTeamDescriptionRequest(teamId: Int64,
                                     description: String) -> Observable<PatchTeamResponse>

    // 修改team头像
    func patchTeamAvatarRequest(teamId: Int64,
                                avatarEntity: TeamAvatarEntity) -> Observable<PatchTeamResponse>

// MARK: 团队成员相关
    // 拉取团队成员
    func getTeamMembers(teamId: Int64,
                        limit: Int,
                        nextOffset: Int64?) -> Observable<Im_V1_GetTeamMembersV2Response>

    // 添加团队成员
    func putTeamMemberRequest(teamId: Int64,
                              chatterIds: [String],
                              chatIds: [String],
                              departmentIds: [String]) -> Observable<PutTeamMemberResponse>

    // 删除成员/退出团队
    func deleteTeamMemberRequest(teamId: Int64,
                                 chatterIds: [Int64],
                                 chatIds: [Int64],
                                 newOwnerId: Int64?) -> Observable<DeleteTeamMemberResponse>

    // 搜索团队成员
    func searchTeamMember(scene: Im_V1_SearchTeamMembersRequest.Scene,
                          teamID: String,
                          key: String,
                          offset: String?,
                          limit: Int32) -> Observable<Im_V1_SearchTeamMembersResponse>

    func getTeamChatter(teamId: Int64,
                        limit: Int,
                        nextOffset: Int64?) -> Observable<Im_V1_GetTeamChattersResponse>
// MARK: 团队群组
    // 根据实体id获取item
    func getTeamItemByTeamId(_ teamId: String) -> Observable<GetItemsByEntityIdsResponse>
    func getChatItemByChatId(_ chatId: String) -> Observable<GetItemsByEntityIdsResponse>

    // 添加已有群组
    func bindTeamChatRequest(teamId: Int64,
                             chatId: Int64,
                             teamChatType: TeamChatType,
                             addMemberChat: Bool,
                             isDiscoverable: Bool?) -> Observable<BindTeamChatResponse>

    // 将群从团队中解绑
    func unbindTeamChatRequest(teamId: Int64, chatId: Int64) -> Observable<UnbindTeamChatResponse>

    // 团队中新加群组
    func createTeamChatRequest(teamId: Int64,
                               mode: Chat.ChatMode,
                               groupName: String,
                               isRemind: Bool,
                               teamChatType: TeamChatType,
                               addMemberChat: Bool,
                               isDiscoverable: Bool?) -> Observable<CreateTeamChatResponse>

    // 群升级为团队
    func upgradeToTeamRequest(name: String,
                              mode: Chat.ChatMode,
                              chatId: String) -> Observable<UpgradeToTeamResponse>

    // 设置团队群的类型
    func patchTeamChatByIdRequest(teamId: Int64,
                                  chatId: Int64,
                                  teamChatType: TeamChatType,
                                  isDiscoverable: Bool?) -> Observable<Void>

// MARK: 团队权限相关
    // 修改团队权限
    func patchTeamSettingRequest(teamId: Int64,
                                 updateFileds: [PatchTeamSettingUpdateFiled],
                                 addChatPermissionType: AddTeamChatPermissionType?,
                                 addPrivateChatPermissionType: AddPrivateChatPermissionType?,
                                 addMemberPermissionType: AddMemberPermissionType?) -> Observable<PatchTeamSettingResponse>

    // 添加/删除团队里的角色
    func patchTeamMembersRoleRequest(teamId: Int64,
                                     role: TeamRoleType,
                                     addChatterIds: [String],
                                     deleteChatterIds: [String]) -> Observable<PatchTeamMembersRoleResponse>
// MARK: 团队动态
    func pullTeamEvent(teamID: Int64, limit: Int32, offset: Int64) -> Observable<ServerPB.ServerPB_Team_PullTeamEventsResponse>

    // 获取团队头像meta
    func pullAvatarMeta(teamID: Int64) -> Observable<ServerPB.ServerPB_Team_PullAvatarMetaV2Response>
}

// MARK: 端上定义的结构
public enum TeamAvatarEntity {
    case normal(key: String)
    case customize(avatarData: Data, avatarMeta: AvatarMeta)
}

// MARK: 日志相关
extension Basic_V1_Item {
    public var description: String {
        return "itemid: \(id), "
            + "entityID: \(entityID), "
            + "type: \(entityType), "
            + "parentId: \( parentID), "
            + "isHidden: \(isHidden)"
    }
}

extension Basic_V1_Team {
    public var description: String {
        return "teamId: \(id), "
            + "status: \(status), "
            + "ownerID: \(ownerID), "
            + "memberCount: \(memberCount), "
            + "defaultChatID: \(defaultChatID), "
            + "userEntity: \(userEntity.description), "
            + "setting: \(setting.description)"
    }
}

extension Basic_V1_TeamSetting {
    public var description: String {
        return "addMember: \(addMemberPermission), "
                + "addChat: \(addTeamChatPermission), "
                + "addPrivateChat: \(addPrivateTeamChatPermission)"
    }
}

extension Basic_V1_TeamUserEntity {
    public var description: String {
        return "roles: \(userRoles.map { $0.description })"
    }
}

extension Basic_V1_TeamMemberMeta {
    public var description: String {
        return userRoles.description
    }
}

extension TeamRoles: CustomStringConvertible {
    public var description: String {
        return "\(self.map { $0.description })"
    }
}

extension Basic_V1_TeamRole {
    public var description: String {
        return "\(roleType)"
    }
}

extension GetTeamsResult {
    public var description: String {
        return
            "teamItemsCount: \(teamItems.count), list: \(teamItems.map({ "\($0.description )" })), "
            + "teamEntitiesCount: \(teamEntities.count), list: \(teamEntities.map({ "\($1.description)" }))"
    }
}

extension GetChatsResult {
    public var description: String {
        return
            "chatItemsCount: \(chatItems.count), list: \(chatItems.map({ "\($1.map({ $0.description }))" })), "
            + "chatEntitiesCount: \(chatEntities.count), list: \(chatEntities.map({ "\($1.description)" }))"
    }
}

extension Basic_V1_TeamMemberInfo {
    public var description: String {
        let detail: String
        if metaType == .chat {
            detail = chatInfo.description
        } else {
            detail = chatterInfo.description
        }
        return
        "id: \(memberID), type: \(metaType), order: \(orderedWeight), detail: \(detail)"
    }
}

extension Basic_V1_TeamMemberChatInfo {
    public var description: String {
        return
        "teamChatType: \(chat.teamChatType), operatorInChat: \(operatorInChat), hasLeaveChatter: \(hasLeaveChatter_p), count: \(count)"
    }
}

extension Basic_V1_TeamMemberChatterInfo {
    public var description: String {
        return "meta: \(meta.description)"
    }
}

// MARK: 角色与权限接口
extension Basic_V1_Team {

    // ‘我’在这个团队里的角色

    // 团队所有人
    public var isTeamOwnerForMe: Bool {
        return userEntity.userRoles.isTeamOwner
    }

    // 团队管理员
    public var isTeamAdminForMe: Bool {
        return userEntity.userRoles.isTeamAdmin
    }

    // 非普通团队成员
    public var isTeamManagerForMe: Bool {
        return userEntity.userRoles.isTeamManager
    }

    // 普通团队成员
    public var isOnlyTeamMemberForMe: Bool {
        return userEntity.userRoles.isOnlyTeamMember
    }

    // 权限，根据角色判断权限，权限是由角色来决定的

    // 是否可以往团队里添加群组
    public var isAllowAddTeamChat: Bool {
        switch setting.addTeamChatPermission {
        case .allMembers:
            return true
        case .onlyManager:
            return isTeamManagerForMe
        case .unknown:
            return false
        @unknown default:
            return false
        }
        return false
    }

    // 是否可以往团队里添加私有群组
    public var isAllowAddTeamPrivateChat: Bool {
        switch setting.addPrivateTeamChatPermission {
        case .allMembers:
            return true
        case .onlyManager:
            return isTeamManagerForMe
        case .unknown:
            return false
        @unknown default:
            return false
        }
        return false
    }

    // 是否可以往团队里添加成员
    public var isAllowAddTeamMember: Bool {
        switch setting.addMemberPermission {
        case .allMembers:
            return true
        case .onlyOwner:
            return isTeamManagerForMe
        case .unknown:
            return false
        @unknown default:
            return false
        }
        return false
    }
}

public typealias TeamRoles = [Basic_V1_TeamRole]
public typealias TeamRoleType = Basic_V1_TeamRole.RoleType
extension TeamRoles {

    // 角色大小判断

    private static let minRoleTypeValue = 10_000
    // key按权限从大到小排序
    public static let teamAllOrderedRoles: [Basic_V1_TeamRole.RoleType: Int] = [
        .owner: 1,
        .admin: 2]

    public static func < (lhs: TeamRoles, rhs: TeamRoles) -> Bool {
        let lhsLevel = teamAllOrderedRoles[lhs.maxRole] ?? minRoleTypeValue
        let rhsLevel = teamAllOrderedRoles[rhs.maxRole] ?? minRoleTypeValue
        return lhsLevel > rhsLevel
    }

    public static func == (lhs: TeamRoles, rhs: TeamRoles) -> Bool {
        let lhsLevel = teamAllOrderedRoles[lhs.maxRole] ?? minRoleTypeValue
        let rhsLevel = teamAllOrderedRoles[rhs.maxRole] ?? minRoleTypeValue
        return lhsLevel == rhsLevel
    }

    public static func > (lhs: TeamRoles, rhs: TeamRoles) -> Bool {
        let lhsLevel = teamAllOrderedRoles[lhs.maxRole] ?? minRoleTypeValue
        let rhsLevel = teamAllOrderedRoles[rhs.maxRole] ?? minRoleTypeValue
        return lhsLevel < rhsLevel
    }

    public var maxRole: TeamRoleType {
        var roles = self.filter({ $0.roleType != .unknown }).map({ $0.roleType })
        guard !roles.isEmpty else { return .unknown }
        var maxRole: TeamRoleType = .unknown
        for role in Self.teamAllOrderedRoles.keys {
            if roles.contains(role) {
                maxRole = role
                break
            }
        }
        return maxRole
    }

    // 角色判断
    public var isTeamOwner: Bool {
        return self.compactMap { $0.roleType }.contains(.owner)
    }

    public var isTeamAdmin: Bool {
        return self.compactMap { $0.roleType }.contains(.admin)
    }

    public var isTeamManager: Bool {
        return !isOnlyTeamMember
    }

    public var isOnlyTeamMember: Bool {
        return self.filter({ $0.roleType != .unknown }).isEmpty
    }
}
