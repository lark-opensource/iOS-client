//
//  RustTeamAPI.swift
//  LarkSDK
//
//  Created by JackZhao on 2021/7/14.
//

import Foundation
import RustPB
import RxSwift
import ServerPB
import LarkModel
import LarkContainer
import LarkRustClient
import LarkSDKInterface
import LKCommonsLogging

final class RustTeamAPI: LarkAPI, TeamAPI {
    static private let logger = Logger.log(RustTeamAPI.self, category: "TeamAPI")
}

// MARK: Team实体相关
extension RustTeamAPI {
    // 创建Team
    func createTeamRequest(name: String,
                           avatarEntity: TeamAvatarEntity?,
                           mode: Chat.ChatMode,
                           chatIds: [String],
                           chatterIds: [String],
                           description: String,
                           departmentIds: [String]) -> Observable<CreateTeamResponse> {
        var createTeamRequest = RustPB.Im_V1_CreateTeamRequest()
        createTeamRequest.name = name
        createTeamRequest.defaultChatMode = mode
        if !chatterIds.isEmpty {
            var pickEntity = PickEntities()
            pickEntity.pickType = .user
            pickEntity.pickIds = chatterIds
            createTeamRequest.pickEntities.append(pickEntity)
        }
        if !chatIds.isEmpty {
            var pickEntity = PickEntities()
            pickEntity.pickType = .chat
            pickEntity.pickIds = chatIds
            createTeamRequest.pickEntities.append(pickEntity)
        }
        if !departmentIds.isEmpty {
            var pickEntity = PickEntities()
            pickEntity.pickType = .dept
            pickEntity.pickIds = departmentIds
            createTeamRequest.pickEntities.append(pickEntity)
        }

        createTeamRequest.description_p = description
        guard let avatarEntity = avatarEntity else {
            return client.sendAsyncRequest(createTeamRequest).subscribeOn(scheduler)
        }

        switch avatarEntity {
        case .normal(let key):
            createTeamRequest.avatarKey = key
            return client.sendAsyncRequest(createTeamRequest).subscribeOn(scheduler)
        case .customize(let data, let meta):
            var uploadAvatarRequest = RustPB.Media_V1_UploadAvatarRequest()
            uploadAvatarRequest.image = data
            return client.sendAsyncRequest(uploadAvatarRequest) { (response: RustPB.Media_V1_UploadAvatarResponse) -> String in
                return response.key
            }.flatMap({ [client] (key) -> Observable<CreateTeamResponse> in
                createTeamRequest.avatarKey = key
                createTeamRequest.avatarMeta = meta
                return client.sendAsyncRequest(createTeamRequest)
            }).subscribeOn(scheduler)
        }
    }

    // Team重名校验接口
    func checkNameAvailabilityRequest(name: String,
                                      checkType: NameAvailabilityCheckType,
                                      identify: String?) -> Observable<TeamCheckNameAvailabilityResponse> {
        var request = ServerPB.ServerPB_Team_CheckNameAvailabilityRequest()
        request.name = name
        if let id = identify {
            request.teamID = id
        }
        request.checkType = checkType
        return self.client.sendPassThroughAsyncRequest(request, serCommand: .checkNameAvailability)
            .do(onNext: { (response: TeamCheckNameAvailabilityResponse) in
                let message = "teamlog/CheckNameAvailabilityRequest success: "
                + "name.count: \(name.count), "
                + "checkType: \(checkType), "
                + "teamID: \(identify), "
                + "available: \(response.available)"
                Self.logger.info(message)
            }, onError: { (error) in
                let message = "teamlog/CheckNameAvailabilityRequest error: "
                + "name.count: \(name.count), "
                + "checkType: \(checkType), "
                + "teamID: \(identify), "
                + "error: \(error)"
                Self.logger.error(message)
            })
    }

    // 拉取Team：聚合本地和网络请求
    func getTeamsFromLocalAndServer(teamIds: [Int64]) -> Observable<GetTeamsByIdsResponse> {
        struct D: MergeDep {
            func isEmpty(response: GetTeamsByIdsResponse) -> Bool {
                response.teams.isEmpty
            }
        }
        let localObservable = getTeams(teamIds: teamIds, forceServer: false)
        let remoteObservable = getTeams(teamIds: teamIds, forceServer: true)
        return mergedObservables(local: localObservable, remote: remoteObservable, delegate: D()).map({ $0.0 })
    }

    // 通过teamId拉取Team实体
    func getTeams(teamIds: [Int64], forceServer: Bool) -> Observable<GetTeamsByIdsResponse> {
        var request = RustPB.Im_V1_GetTeamsByIdsRequest()
        request.teamIds = teamIds
        request.strategy = forceServer ? .forceServer : .tryLocal
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
            .do(onNext: { (response: GetTeamsByIdsResponse) in
                let message = "teamlog/GetTeamsByIdsRequest success: "
                + "teamIds: \(teamIds), "
                + "forceServer: \(forceServer), "
                + "teams: \(response.teams.values.map { $0.description })"
                Self.logger.info(message)
            }, onError: { (error) in
                let message = "teamlog/GetTeamsByIdsRequest error: "
                + "teamIds: \(teamIds), "
                + "forceServer: \(forceServer), "
                + "error: \(error)"
                Self.logger.error(message)
            })
    }

    // 拉取Team：通过chatId 和 teamIds拉取Team实体
    func getTeams(chatId: String, teamIds: [Int64]) -> Observable<Im_V1_GetTeamsForChatResponse> {
        var request = Im_V1_GetTeamsForChatRequest()
        request.chatID = Int64(chatId) ?? 0
        request.teamIds = teamIds
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
            .do(onNext: { (response: Im_V1_GetTeamsForChatResponse) in
                let message = "teamlog/getTeamsForChatRequest success: "
                + "chatId: \(chatId), "
                + "teamIds: \(teamIds), "
                + "teams: \(response.teams.count)"
                Self.logger.info(message)
            }, onError: { (error) in
                let message = "teamlog/getTeamsForChatRequest error: "
                + "chatId: \(chatId), "
                + "teamIds: \(teamIds), "
                + "error: \(error)"
                Self.logger.error(message)
            })
    }

    // 团队信息修改： 头像、描述等
    func patchTeamRequest(teamId: Int64,
                          updateFiled: [PatchTeamUpdateFiled],
                          name: String?,
                          ownerId: Int64?,
                          isDissolved: Bool?) -> Observable<PatchTeamResponse> {
        var request = RustPB.Im_V1_PatchTeamRequest()
        request.teamID = teamId
        request.updateFields = updateFiled
        if let name = name {
            request.name = name
        }
        if let ownerId = ownerId {
            request.ownerID = ownerId
        }
        if let isDissolved = isDissolved {
            request.isDissolved = isDissolved
        }
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
            .do(onNext: { (response: PatchTeamResponse) in
                let message = "teamlog/patchTeamRequest success: "
                + "teamId: \(teamId), "
                + "updateFiled: \(updateFiled), "
                + "name.count: \(name?.count), "
                + "ownerId: \(ownerId), "
                + "isDissolved: \(isDissolved), "
                + "team: \(response.team.description), "
                + "metas: \(response.metas.map { "\($0), \($1.description)" })"
                + "order: \(response.orderedWeight.map { "\($0), \($1)" })"
                Self.logger.info(message)
            }, onError: { (error) in
                let message = "teamlog/patchTeamRequest error: "
                + "teamId: \(teamId), "
                + "updateFiled: \(updateFiled), "
                + "name.count: \(name?.count), "
                + "ownerId: \(ownerId), "
                + "isDissolved: \(isDissolved), "
                + "error: \(error)"
                Self.logger.error(message)
            })
    }

    // 修改team描述
    func patchTeamDescriptionRequest(teamId: Int64,
                                     description: String) -> Observable<PatchTeamResponse> {
        var request = RustPB.Im_V1_PatchTeamRequest()
        request.teamID = teamId
        request.updateFields = [.description_]
        request.description_p = description
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    // 修改team头像
    func patchTeamAvatarRequest(teamId: Int64,
                                avatarEntity: TeamAvatarEntity) -> Observable<PatchTeamResponse> {
        var request = RustPB.Im_V1_PatchTeamRequest()
        request.teamID = teamId
        request.updateFields = [.avatar]
        switch avatarEntity {
        case .normal(let key):
            request.avatarKey = key
            return client.sendAsyncRequest(request).subscribeOn(scheduler)
        case .customize(let data, let meta):
            var uploadAvatarRequest = RustPB.Media_V1_UploadAvatarRequest()
            uploadAvatarRequest.image = data
            return client.sendAsyncRequest(uploadAvatarRequest) { (response: RustPB.Media_V1_UploadAvatarResponse) -> String in
                return response.key
            }.flatMap({ [client] (key) -> Observable<PatchTeamResponse> in
                request.avatarKey = key
                request.avatarMeta = meta
                return client.sendAsyncRequest(request)
            }).subscribeOn(scheduler)
        }
    }
}

// MARK: 团队成员相关
extension RustTeamAPI {
    // 拉取团队成员
    func getTeamMembers(teamId: Int64,
                        limit: Int,
                        nextOffset: Int64?) -> Observable<Im_V1_GetTeamMembersV2Response> {
        var request = Im_V1_GetTeamMembersV2Request()
        request.teamID = teamId
        request.limit = Int32(limit) // 返回的数量，大群或小群都需要传
        if let nextOffset = nextOffset {
            request.offset = nextOffset // 第一屏拉取不传，以后传上次返回的 next_offset
        }
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
            .do(onNext: { (response: Im_V1_GetTeamMembersV2Response) in
                let message = "teamlog/getTeamMembers success: "
                + "teamID: \(teamId), "
                + "limit: \(limit), "
                + "offset: \(nextOffset), "
                + "nextOffset: \(response.nextOffset), "
                + "hasMore: \(response.hasMore_p), "
                + "forbiddenBySecurity: \(response.forbiddenBySecurity), "
                + "membersCount: \(response.teamMemberInfos.count), "
                + "members: \(response.teamMemberInfos.map { $0.description })"
                Self.logger.info(message)
            }, onError: { (error) in
                let message = "teamlog/getTeamMembers error: "
                + "teamID: \(teamId), "
                + "limit: \(limit), "
                + "offset: \(nextOffset), "
                + "error: \(error)"
                Self.logger.error(message)
            })
                }

    // 添加团队成员
    func putTeamMemberRequest(teamId: Int64,
                              chatterIds: [String],
                              chatIds: [String],
                              departmentIds: [String]) -> Observable<PutTeamMemberResponse> {
        var request = RustPB.Im_V1_PutTeamMemberRequest()
        request.teamID = teamId
        if !chatterIds.isEmpty {
            var pickEntity = PickEntities()
            pickEntity.pickType = .user
            pickEntity.pickIds = chatterIds
            request.pickEntities.append(pickEntity)
        }
        if !chatIds.isEmpty {
            var pickEntity = PickEntities()
            pickEntity.pickType = .chat
            pickEntity.pickIds = chatIds
            request.pickEntities.append(pickEntity)
        }
        if !departmentIds.isEmpty {
            var pickEntity = PickEntities()
            pickEntity.pickType = .dept
            pickEntity.pickIds = departmentIds
            request.pickEntities.append(pickEntity)
        }

        return client.sendAsyncRequest(request).subscribeOn(scheduler)
            .do(onNext: { (response: PutTeamMemberResponse) in
                let message = "teamlog/PutTeamMemberRequest success: "
                + "teamId: \(teamId), "
                + "chatterIds: \(chatterIds), "
                + "chatIds: \(chatIds), "
                + "departmentIds: \(departmentIds), "
                + "team: \(response.team.description), "
                + "orderedWeightCount: \(response.orderedWeight.count), "
                + "chatterInfosCount: \(response.chatterInfos.count), "
                + "chatterInfos: \(response.chatterInfos.values.map { $0.description })"
                Self.logger.info(message)
            }, onError: { (error) in
                let message = "teamlog/PutTeamMemberRequest error: "
                + "teamId: \(teamId), "
                + "chatterIds: \(chatterIds), "
                + "chatIds: \(chatIds), "
                + "departmentIds: \(departmentIds), "
                + "error: \(error)"
                Self.logger.error(message)
            })
                }

    // 删除成员/退出团队
    func deleteTeamMemberRequest(teamId: Int64,
                                 chatterIds: [Int64],
                                 chatIds: [Int64],
                                 newOwnerId: Int64?) -> Observable<DeleteTeamMemberResponse> {
        var request = RustPB.Im_V1_DeleteTeamMembersRequest()
        request.teamID = teamId
        var members: [Im_V1_DeleteMembersEntity] = []
        if !chatterIds.isEmpty {
            var chatters = Im_V1_DeleteMembersEntity()
            chatters.teamMemberType = .individual
            chatters.memberIds = chatterIds
            members.append(chatters)
        }
        if !chatIds.isEmpty {
            var chats = Im_V1_DeleteMembersEntity()
            chats.teamMemberType = .chat
            chats.memberIds = chatIds
            members.append(chats)
        }
        request.deleteMembers = members
        if let newOwnerId = newOwnerId {
            request.newOwnerID = newOwnerId
        }
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
            .do(onNext: { (response: DeleteTeamMemberResponse) in
                let message = "teamlog/deleteTeamMemberRequest success: "
                + "teamID: \(teamId), "
                + "chatterIds: \(chatterIds), "
                + "chatIds: \(chatIds), "
                + "newOwnerId: \(newOwnerId), "
                + "team: \(response.team.description)"
                Self.logger.info(message)
            }, onError: { (error) in
                let message = "teamlog/deleteTeamMemberRequest error: "
                + "chatterIds: \(chatterIds), "
                + "chatIds: \(chatIds), "
                + "newOwnerId: \(newOwnerId), "
                + "error: \(error)"
                Self.logger.error(message)
            })
    }

    // 搜索团队成员
    func searchTeamMember(scene: Im_V1_SearchTeamMembersRequest.Scene,
                          teamID: String,
                          key: String,
                          offset: String?,
                          limit: Int32) -> Observable<Im_V1_SearchTeamMembersResponse> {
        var request = Im_V1_SearchTeamMembersRequest()
        request.searchScene = scene
        request.teamID = teamID
        request.query = key
        if let offset = offset {
            request.offset = offset
        }
        request.limit = limit
        let logInfo = "scene: \(scene.rawValue), "
        + "teamID: \(teamID), "
        + "key.count: \(key.count), "
        + "offset: \(offset ?? "nil"), "
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
            .do(onNext: { (response: Im_V1_SearchTeamMembersResponse) in
                let responseInfo = "teamlog/searchTeamMember/success: "
                + logInfo
                + "hasMore: \(response.hasMore_p), "
                + "offset: \(response.nextOffset), "
                + "count: \(response.teamMemberInfos.count)"
                Self.logger.info(responseInfo)
            }, onError: { (error) in
                let logInfo = "teamlog/searchTeamMemberRequest/error: \(logInfo)"
                Self.logger.error(logInfo, error: error)
            })
    }

    func getTeamChatter(teamId: Int64,
                        limit: Int,
                        nextOffset: Int64?) -> Observable<Im_V1_GetTeamChattersResponse> {
        var request = Im_V1_GetTeamChattersRequest()
        request.teamID = teamId
        request.limit = Int32(limit) // 返回的数量，大群或小群都需要传
        if let nextOffset = nextOffset {
            request.offset = nextOffset // 第一屏拉取不传，以后传上次返回的 next_offset
        }
        let loginfo = "teamID: \(teamId), "
        + "limit: \(limit), "
        + "offset: \(nextOffset ?? -1), "
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
            .do(onNext: { (response: Im_V1_GetTeamChattersResponse) in
                let message = "teamlog/getTeamChatter/success: "
                + loginfo
                + "nextOffset: \(response.nextOffset), "
                + "hasMore: \(response.hasMore_p), "
                + "forbiddenBySecurity: \(response.forbiddenBySecurity), "
                + "membersCount: \(response.teamMemberInfos.count), "
                + "members: \(response.teamMemberInfos.map { $0.description })"
                Self.logger.info(message)
            }, onError: { (error) in
                let message = "teamlog/getTeamChatter/error: \(loginfo)"
                Self.logger.error(message, error: error)
            })
    }
}

// MARK: 团队群组
extension RustTeamAPI {
    // 根据实体id获取item
    private func getItemById(_ id: String, entityType: Basic_V1_Item.TypeEnum) -> Observable<GetItemsByEntityIdsResponse> {
        var request = Im_V1_GetItemsByEntityIdsRequest()
        var itemUniqId = Im_V1_GetItemsByEntityIdsRequest.ItemUniqId()
        itemUniqId.entityType = entityType
        itemUniqId.entityID = id
        request.itemEntityIds = [itemUniqId]
        request.strategy = .tryLocal
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
            .do(onNext: { (response: GetItemsByEntityIdsResponse) in
                let message = "teamlog/GetItemsByEntityIdsRequest success: "
                + "id: \(id), "
                + "entityType: \(entityType), "
                + "items: \(response.items.values.map { $0.description })"
                Self.logger.info(message)
            }, onError: { (error) in
                let message = "teamlog/GetItemsByEntityIdsRequest error: "
                + "id: \(id), "
                + "entityType: \(entityType), "
                + "error: \(error)"
                Self.logger.error(message)
            })
    }

    func getTeamItemByTeamId(_ teamId: String) -> Observable<GetItemsByEntityIdsResponse> {
        return getItemById(teamId, entityType: .team)
    }

    func getChatItemByChatId(_ chatId: String) -> Observable<GetItemsByEntityIdsResponse> {
        return getItemById(chatId, entityType: .chat)
    }

    // 添加已有群组
    func bindTeamChatRequest(teamId: Int64,
                             chatId: Int64,
                             teamChatType: TeamChatType,
                             addMemberChat: Bool,
                             isDiscoverable: Bool?) -> Observable<BindTeamChatResponse> {
        var request = RustPB.Im_V1_BindTeamChatRequest()
        request.teamID = teamId
        request.chatID = chatId
        request.teamChatType = teamChatType
        request.isTeamMemberChat = addMemberChat
        if let isDiscoverable = isDiscoverable {
            request.isDiscoverable = isDiscoverable
        }
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
            .do(onNext: { (response: BindTeamChatResponse) in
                let message = "teamlog/BindTeamChatRequest success: "
                + "teamId: \(teamId), "
                + "chatId: \(chatId), "
                + "isDiscoverable: \(isDiscoverable), "
                + "teamChatType: \(teamChatType), "
                + "addMemberChat: \(addMemberChat), "
                + "item: \(response.item.description), "
                + "team: \(response.team.description), "
                + "chat: \(response.chat.id)"
                Self.logger.info(message)
            }, onError: { (error) in
                let message = "teamlog/BindTeamChatRequest error: "
                + "teamId: \(teamId), "
                + "chatId: \(chatId), "
                + "isDiscoverable: \(isDiscoverable), "
                + "teamChatType: \(teamChatType), "
                + "addMemberChat: \(addMemberChat), "
                + "error: \(error)"
                Self.logger.error(message)
            })
    }

    // 将群从团队中解绑
    func unbindTeamChatRequest(teamId: Int64, chatId: Int64) -> Observable<UnbindTeamChatResponse> {
        var request = RustPB.Im_V1_UnbindTeamChatRequest()
        request.teamID = teamId
        request.chatID = chatId
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
            .do(onNext: { (response: UnbindTeamChatResponse) in
                let message = "teamlog/UnbindTeamChatRequest success: "
                + "teamId: \(teamId), "
                + "chatId: \(chatId), "
                + "item: \(response.item.description), "
                + "chat: \(response.chat.id)"
                Self.logger.info(message)
            }, onError: { (error) in
                let message = "teamlog/UnbindTeamChatRequest error: "
                + "teamId: \(teamId), "
                + "chatId: \(chatId), "
                + "error: \(error)"
                Self.logger.error(message)
            })
    }

    // 团队中新加群组
    func createTeamChatRequest(teamId: Int64,
                               mode: Chat.ChatMode,
                               groupName: String,
                               isRemind: Bool,
                               teamChatType: TeamChatType,
                               addMemberChat: Bool,
                               isDiscoverable: Bool?) -> Observable<CreateTeamChatResponse> {
        var request = RustPB.Im_V1_CreateTeamChatRequest()
        request.teamID = teamId
        request.chatMode = mode
        request.groupName = groupName
        request.teamChatType = teamChatType
        if let isDiscoverable = isDiscoverable {
            request.isDiscoverable = isDiscoverable
        }
        request.isRemind = isRemind
        request.isTeamMemberChat = addMemberChat
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
            .do(onNext: { (response: CreateTeamChatResponse) in
                let message = "teamlog/CreateTeamChatRequest success: "
                + "teamId: \(teamId), "
                + "mode: \(mode), "
                + "isDiscoverable: \(isDiscoverable), "
                + "groupName.count: \(groupName.count), "
                + "isRemind: \(isRemind), "
                + "teamChatType: \(teamChatType), "
                + "addMemberChat: \(addMemberChat), "
                + "chat: \(response.chat.id)"
                Self.logger.info(message)
            }, onError: { (error) in
                let message = "teamlog/CreateTeamChatRequest error: "
                + "teamId: \(teamId), "
                + "mode: \(mode), "
                + "isDiscoverable: \(isDiscoverable), "
                + "groupName.count: \(groupName.count), "
                + "isRemind: \(isRemind), "
                + "teamChatType: \(teamChatType), "
                + "addMemberChat: \(addMemberChat), "
                + "error: \(error)"
                Self.logger.error(message)
            })
    }

    // 群升级为团队
    func upgradeToTeamRequest(name: String,
                              mode: Chat.ChatMode,
                              chatId: String) -> Observable<UpgradeToTeamResponse> {
        var request = RustPB.Im_V1_UpgradeToTeamRequest()
        request.name = name
        request.defaultChatMode = mode
        request.chatID = Int64(chatId) ?? 0
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
            .do(onNext: { (response: UpgradeToTeamResponse) in
                let message = "teamlog/UpgradeToTeamRequest success: "
                + "name.count: \(name.count), "
                + "mode: \(mode), "
                + "chatId: \(chatId), "
                + "team: \(response.team.description), "
                + "teamItem: \(response.teamItem.description), "
                + "chatItem: \(response.chatItem.description), "
                + "chat: \(response.chat.id)"
                Self.logger.info(message)
            }, onError: { (error) in
                let message = "teamlog/UpgradeToTeamRequest error: "
                + "name.count: \(name.count), "
                + "mode: \(mode), "
                + "chatId: \(chatId), "
                + "error: \(error)"
                Self.logger.error(message)
            })
    }

    // 设置团队群的类型
    func patchTeamChatByIdRequest(teamId: Int64,
                                  chatId: Int64,
                                  teamChatType: TeamChatType,
                                  isDiscoverable: Bool?) -> Observable<Void> {
        var request = ServerPB.ServerPB_Team_PatchTeamChatByIdRequest()
        request.teamID = teamId
        request.chatID = chatId
        request.updateFields = [.chatType]
        let chatType: ServerPB.ServerPB_Entities_TeamChatType
        switch teamChatType {
        case .private:
            chatType = .private
        case .public:
            chatType = .public
        case .open:
            chatType = .open
        case .default:
            chatType = .default
        case .unknown:
            chatType = .unknown
        @unknown default:
            chatType = .unknown
        }
        request.teamChatType = chatType
        if let isDiscoverable = isDiscoverable {
            request.isDiscoverable = isDiscoverable
        }
        var info = "teamlog/patchTeamChatByIdRequest "
        + "teamId: \(teamId), "
        + "chatId: \(chatId), "
        + "isDiscoverable: \(isDiscoverable), "
        + "teamChatType: \(teamChatType)"
        return self.client.sendPassThroughAsyncRequest(request, serCommand: .patchTeamChatByID)
            .do(onNext: { _ in
                Self.logger.info("success: \(info)")
            }, onError: { (error) in
                Self.logger.error("error: \(info), error: \(error)")
            })
    }
}

// MARK: 团队权限相关
extension RustTeamAPI {
    // 修改团队权限
    func patchTeamSettingRequest(teamId: Int64,
                                 updateFileds: [PatchTeamSettingUpdateFiled],
                                 addChatPermissionType: AddTeamChatPermissionType?,
                                 addPrivateChatPermissionType: AddPrivateChatPermissionType?,
                                 addMemberPermissionType: AddMemberPermissionType?) -> Observable<PatchTeamSettingResponse> {
        var request = RustPB.Im_V1_PatchTeamSettingRequest()
        request.teamID = teamId
        request.updateFields = updateFileds
        if let addChatPermission = addChatPermissionType {
            request.addTeamChatPermission = addChatPermission
        }
        if let addPrivateChatPermission = addPrivateChatPermissionType {
            request.addPrivateTeamChatPermission = addPrivateChatPermission
        }
        if let addMemberPermission = addMemberPermissionType {
            request.addMemberPermission = addMemberPermission
        }
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
            .do(onNext: { (response: PatchTeamSettingResponse) in
                let message = "teamlog/PatchTeamSettingRequest success: "
                + "teamId: \(teamId), "
                + "updateFileds: \(updateFileds), "
                + "addChatPermissionType: \(addChatPermissionType), "
                + "addPrivateChatPermissionType: \(addPrivateChatPermissionType), "
                + "addMemberPermissionType: \(addMemberPermissionType), "
                + "team: \(response.team.description)"
                Self.logger.info(message)
            }, onError: { (error) in
                let message = "teamlog/PatchTeamSettingRequest error: "
                + "teamId: \(teamId), "
                + "updateFileds: \(updateFileds), "
                + "addChatPermissionType: \(addChatPermissionType), "
                + "addPrivateChatPermissionType: \(addPrivateChatPermissionType), "
                + "addMemberPermissionType: \(addMemberPermissionType), "
                + "error: \(error)"
                Self.logger.error(message)
            })
    }

    // 添加/删除团队里的角色
    func patchTeamMembersRoleRequest(teamId: Int64,
                                     role: TeamRoleType,
                                     addChatterIds: [String],
                                     deleteChatterIds: [String]) -> Observable<PatchTeamMembersRoleResponse> {
        var request = Im_V1_PatchTeamMembersRoleRequest()
        request.teamID = teamId
        request.role = role
        var isAddRole = false
        if !addChatterIds.isEmpty {
            isAddRole = true
            request.addChatterIds = addChatterIds
        }
        if !deleteChatterIds.isEmpty {
            isAddRole = false
            request.deleteChatterIds = deleteChatterIds
        }
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
            .do(onNext: { (response: PatchTeamMembersRoleResponse) in
                let message = "teamlog/patchTeamMembersRoleRequest success: "
                    + "teamId: \(teamId), "
                    + "isAddRole: \(isAddRole), "
                    + "role: \(role), "
                    + "addChatterIds: \(addChatterIds), "
                    + "deleteChatterIds: \(deleteChatterIds), "
                    + "orderedWeight: \(response.orderedWeight), "
                    + "updatedMetas: \(response.updatedMetas.map { "\($0), \($1.description)" })"
                Self.logger.info(message)
            }, onError: { (error) in
                let message = "teamlog/patchTeamMembersRoleRequest error: "
                    + "teamId: \(teamId), "
                    + "isAddRole: \(isAddRole), "
                    + "role: \(role), "
                    + "addChatterIds: \(addChatterIds), "
                    + "deleteChatterIds: \(deleteChatterIds), "
                    + "error: \(error)"
                Self.logger.error(message)
            })
    }
}

 extension LarkAPI {
    /// 合并本地源和远端源，并按兜底策略处理对应的结果。兜底策略为：
    /// 并发请求，远端结果优先（可覆盖本地结果）
    /// 其中一端出错，取有结果的一端
    /// 都出错，报远端错误
    func mergedObservables<T, D>(
        local: Observable<T>, remote: Observable<T>,
        scheduler: SerialDispatchQueueScheduler? = nil, delegate: D
    ) -> Observable<(T, Bool)> where D: MergeDep, D.Response == T {
        let source = Observable.merge(
            local.materialize().map { (false, $0) },
            remote.materialize().map { (true, $0) }
            ).observeOn(scheduler ?? SerialDispatchQueueScheduler(qos: .userInitiated))
        // wrap to send completed, for canceling early
        return Observable.create { (observer) -> Disposable in
            var state = ReqState<T>()
            return source.subscribe { (event) in
                switch event {
                case let .next((isRemote, reqEvent)):
                    // 兜底策略：
                    // 并发请求，远端结果优先（可覆盖本地结果）
                    // 其中一端出错，取有结果的一端
                    // 都出错，报远端错误
                    let setter: (ReqStateCase<T>) -> Void
                    if isRemote {
                        setter = { state.remote = $0 }
                    } else {
                        setter = { state.local = $0 }
                    }
                    func update(_ cases: ReqStateCase<T>) {
                        setter(cases)
                        // after change state, check the status and response
                        switch (state.local, state.remote) {
                        case (_, .success):
                            // 远端成功，直接结束
                            observer.onCompleted()
                        case (.success, .some):
                            // 本地成功，远端失败，本地结束
                            observer.onCompleted()
                        case (.some, .empty(let response)):
                            // 本地失败，远端空, 通知空
                            observer.onNext((response, true))
                            observer.onCompleted()
                        case (.some, .failure(let error)):
                            // 本地失败，远端异常，报远端异常
                            observer.onError(error)
                        default: break
                        }
                    }

                    switch reqEvent {
                    case .next(let response):
                        if delegate.isEmpty(response: response) {
                            update(.empty(response))
                        } else {
                            observer.onNext((response, isRemote)) // 结果直接输出，是否结束下面综合判断
                            update(.success(response))
                        }
                    case .error(let error):
                        update(.failure(error))
                    default: break // ignore complete in single source
                    }
                // materialize has no error
                case .completed:
                    observer.on(.completed)
                default: break
                }
            }
        }
    }
}

// 团队动态
extension RustTeamAPI {
    func pullTeamEvent(teamID: Int64, limit: Int32, offset: Int64) -> Observable<ServerPB.ServerPB_Team_PullTeamEventsResponse> {
        var request = ServerPB_Team_PullTeamEventsRequest()
        request.teamID = teamID
        request.limit = limit
        request.offset = offset
        return self.client.sendPassThroughAsyncRequest(request, serCommand: .pullTeamEvents)
            .do(onNext: { (response: ServerPB_Team_PullTeamEventsResponse) in
                let message = "teamlog/TeamEventRequest success: "
                + "limit: \(limit), "
                + "teamID: \(teamID), "
                + "events.count: \(response.events.count)"
                Self.logger.info(message)
            }, onError: { (error) in
                let message = "teamlog/TeamEventRequest error: "
                + "limit: \(limit), "
                + "teamID: \(teamID), "
                + "error: \(error)"
                Self.logger.error(message)
            })
    }
}

// 获取团队头像meta
extension RustTeamAPI {
    func pullAvatarMeta(teamID: Int64) -> Observable<ServerPB.ServerPB_Team_PullAvatarMetaV2Response> {
        var request = ServerPB_Team_PullAvatarMetaV2Request()
        request.teamID = teamID
        return self.client.sendPassThroughAsyncRequest(request, serCommand: .pullAvatarMetaV2)
    }
}
