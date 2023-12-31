//
//  RustChatAPI.swift
//  Lark
//
//  Created by linlin on 2017/10/27.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import RxSwift
import RustPB
import LarkModel
import LarkSDKInterface
import LKCommonsLogging
import LarkAccountInterface
import LarkRustClient
import ServerPB
import LarkContainer
import LarkSetting

typealias FetchChatsResult = [String: LarkModel.Chat]

final class RustChatAPI: LarkAPI, ChatAPI, UserResolverWrapper {
    static let logger = Logger.log(RustChatAPI.self, category: "RustSDK.Chat")

    let userResolver: UserResolver
    private let currentChatterId: String
    @ScopedInjectedLazy private var chatterManager: ChatterManagerProtocol?
    let featureGatingService: FeatureGatingService

    init(userResolver: UserResolver,
         client: SDKRustService,
         currentChatterId: String,
         featureGatingService: FeatureGatingService,
         onScheduler: ImmediateSchedulerType? = nil) {
        self.userResolver = userResolver
        self.currentChatterId = currentChatterId
        self.featureGatingService = featureGatingService
        super.init(client: client, onScheduler: onScheduler)
    }

    func getLocalChat(by id: String) -> LarkModel.Chat? {
        do {
            let chatsMap = try getLocalChats([id])
            return chatsMap[id]
        } catch {
            RustChatAPI.logger.error("Can not find chat in local",
                                     additionalData: ["chatId": "\(id)"],
                                     error: error)
            return nil
        }
    }

    func fetchChat(by id: String, forceRemote: Bool) -> Observable<Chat?> {
        return fetchChats(by: [id], forceRemote: forceRemote)
            .map({ (chatsMap: FetchChatsResult) -> Chat? in
                return chatsMap[id]
            })
            .do(onError: { (error) in
                RustChatAPI.logger.error("Can not find chat in local",
                                         additionalData: ["chatId": "\(id)"],
                                         error: error)
            })
    }

    func getLocalChats(_ ids: [String]) throws -> [String: LarkModel.Chat] {
        return try RustChatAPI.loadLocalChats(ids, client: client)
    }

    func fetchLocalChats(_ ids: [String]) -> Observable<[String: Chat]> {
        let chatIds = ids.filter { !$0.isEmpty }
        guard !chatIds.isEmpty else {
            return Observable.empty()
        }
        var request = RustPB.Im_V1_MGetChatsRequest()
        request.chatIds = chatIds
        request.shouldAuth = false
        request.strategy = .local
        return client.sendAsyncRequest(request) { (res: RustPB.Im_V1_MGetChatsResponse) -> FetchChatsResult in
            return RustAggregatorTransformer.transformToChatsMap(
                fromEntity: res.entity,
                chatOptionInfos: res.chatOptionInfo
            )
        }.subscribeOn(scheduler)
        .do(onError: { (error) in
            let idsInfo = ids.joined(separator: ", ")
            let message = "Get local chats failed. \(idsInfo)"
            RustChatAPI.logger.error(message, error: error)
        })
    }

    func fetchChats(by ids: [String], forceRemote: Bool) -> Observable<FetchChatsResult> {
        return RustChatAPI.fetchChats(by: ids, forceRemote: forceRemote, client: client)
            .subscribeOn(scheduler)
    }

    func readChatAnnouncement(by chatID: String, updateTime: Int64) -> Observable<Void> {
        return RustChatAPI.readChatAnnouncement(by: chatID, updateTime: updateTime, client: client)
    }

    func createChat(param: CreateGroupParam) -> Observable<CreateChatResult> {
        return RustChatAPI.createChat(
            type: param.type,
            chatterIds: param.chatterIds,
            groupName: param.name,
            groupDesc: param.desc,
            fromChatID: param.fromChatId,
            isCrypto: param.isCrypto,
            isPrivateMode: param.isPrivateMode,
            initMessageIds: param.messageIds,
            messageId2Permissions: param.messageId2Permissions,
            isPublic: param.isPublic,
            chatMode: param.chatMode,
            client: client,
            currentChatterId: self.currentChatterId,
            createChatSource: param.createChatSource,
            linkPageURL: param.linkPageURL,
            pickEntities: param.pickEntities
        )
        .subscribeOn(scheduler)
    }

    func createFaceToFaceApplication(latitude: String, longitude: String, matchCode: Int32) -> Observable<RustPB.Im_V1_CreateFaceToFaceApplicationResponse> {
        var request = RustPB.Im_V1_CreateFaceToFaceApplicationRequest()
        var location = Basic_V1_LocationContent()
        location.latitude = latitude
        location.longitude = longitude
        request.location = location
        request.matchCode = matchCode
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func joinFaceToFaceChat(token: String) -> Observable<(Chat, Bool)> {
        var request = RustPB.Im_V1_JoinFaceToFaceChatRequest()
        request.token = token
        return client.sendAsyncRequest(request) { (res: RustPB.Im_V1_JoinFaceToFaceChatResponse) -> (LarkModel.Chat, Bool) in
            if let chat = RustAggregatorTransformer.transformToChatsMap(fromEntity: res.entity)[res.chatID] {
                return (chat, res.isCreateChat)
            } else {
                throw APIError(type: .entityIncompleteData(message: "JoinFaceToFaceChatResponse has no chat"))
            }
        }.subscribeOn(scheduler)
    }

    func checkPublicChatName(chatName: String) -> Observable<Bool> {
        return RustChatAPI.checkPublicChatName(chatName: chatName, client: client)
    }

    func createDepartmentChat(departmentId: String) -> Observable<LarkModel.Chat> {
        var request = RustPB.Im_V1_CreateDepartmentChatRequest()
        request.departmentID = departmentId
        return client.sendAsyncRequest(request, transform: { (res: RustPB.Im_V1_CreateDepartmentChatResponse) -> LarkModel.Chat in
            if let chat = RustAggregatorTransformer.transformToChatsMap(fromEntity: res.entity)[res.chatID] {
                return chat
            } else {
                throw APIError(type: .entityIncompleteData(message: "CreateChatResponse has no chat"))
            }
        }).subscribeOn(scheduler)
    }

    func createP2pChats(uids: [String]) -> Observable<[LarkModel.Chat]> {
        return RustChatAPI.createP2PChats(chatterIds: uids, client: client)
            .subscribeOn(scheduler)
    }

    func getLocalP2PChat(by uid: String) -> LarkModel.Chat? {
        do {
            let chatMap = try getLocalP2PChatsByUserIds(uids: [uid])
            return chatMap[uid]
        } catch {
            return nil
        }
    }

    func fetchLocalP2PChat(by uid: String) -> Observable<Chat?> {
        return fetchLocalP2PChatsByUserIds(uids: [uid]).map { (chatsMap) -> Chat? in
            return chatsMap[uid]
        }
    }

    func getLocalP2PChatsByUserIds(uids: [String]) throws -> [String: LarkModel.Chat] {
        var request = RustPB.Im_V1_GetP2PChatsByChatterIdsRequest()
        request.chatterIds = uids
        let response: ContextResponse<RustPB.Im_V1_GetP2PChatsByChatterIdsResponse> = try client.sendSyncRequest(request, allowOnMainThread: true)
        return response.response.chatterID2Chat.mapValues { (chat) -> LarkModel.Chat in
            return LarkModel.Chat.transform(pb: chat)
        }
    }

    func fetchLocalP2PChatsByUserIds(uids: [String]) -> Observable<[String: Chat]> {
        var request = RustPB.Im_V1_GetP2PChatsByChatterIdsRequest()
        request.chatterIds = uids
        return client.sendAsyncRequest(request) { (res: RustPB.Im_V1_GetP2PChatsByChatterIdsResponse) -> [String: Chat] in
            return res.chatterID2Chat.mapValues { (chat) -> LarkModel.Chat in
                return LarkModel.Chat.transform(pb: chat)
            }
        }.subscribeOn(scheduler)
    }

    func joinChat(joinToken: String, messageId: String) -> Observable<LarkModel.Chat> {
        return RustChatAPI.joinChat(joinToken: joinToken, messageId: messageId, client: client)
            .subscribeOn(scheduler)
    }

    func addChatters(chatId: String, chatterIds: [String], chatIds: [String], departmentIds: [String]) -> Observable<Void> {
        return self.addChatters(chatId: chatId, chatterIds: chatterIds, chatIds: chatIds, departmentIds: departmentIds, isMentionInvitation: false)
    }

    func addChatters(chatId: String, chatterIds: [String], chatIds: [String], departmentIds: [String], isMentionInvitation: Bool) -> Observable<Void> {
        var request = RustPB.Im_V1_AddChatChattersRequest()
        request.type = isMentionInvitation ? .mentionInvitation : .invitation
        request.chatID = chatId
        request.chatterIds = chatterIds
        if !chatIds.isEmpty {
            var pickEntity = Basic_V1_PickEntities()
            pickEntity.pickType = .chat
            pickEntity.pickIds = chatIds
            request.pickEntities.append(pickEntity)
        }
        if !departmentIds.isEmpty {
            var pickEntity = Basic_V1_PickEntities()
            pickEntity.pickType = .dept
            pickEntity.pickIds = departmentIds
            request.pickEntities.append(pickEntity)
        }
        if !chatterIds.isEmpty {
            var pickEntity = Basic_V1_PickEntities()
            pickEntity.pickType = .user
            pickEntity.pickIds = chatterIds
            request.pickEntities.append(pickEntity)
        }
        return client.sendAsyncRequest(request)
            .subscribeOn(scheduler)
    }

    // 扫描群二维码加群
    func addChatter(to chatId: String, inviterId: String, token: String) -> Observable<Void> {
        var request = RustPB.Im_V1_AddChatChattersRequest()
        request.type = .qrcode
        request.chatID = chatId
        request.inviterID = inviterId
        request.joinToken = token
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func addChatterByLink(with token: String) -> Observable<Void> {
        var request = RustPB.Im_V1_SendChatterViaLinkRequest()
        request.token = token
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    // 团队公开群申请入群
    func addChatters(teamId: Int64, chatId: String, chatterIds: [String]) -> Observable<Void> {
        var request = RustPB.Im_V1_AddChatChattersRequest()
        request.type = .openChat
        request.teamID = teamId
        request.chatID = chatId
        request.chatterIds = chatterIds
        return client.sendAsyncRequest(request)
            .subscribeOn(scheduler)
    }

    func addChatters(chatId: String, chatterIds: [String], linkPageURL: String) -> Observable<Void> {
        var request = RustPB.Im_V1_AddChatChattersRequest()
        request.type = .linkedPage
        request.chatID = chatId
        request.source = .chatLinkedPage
        var chatPageContext = Im_V1_ChatPageContext()
        chatPageContext.targetURL = linkPageURL
        request.fromPage = chatPageContext
        var pickEntity = Basic_V1_PickEntities()
        pickEntity.pickType = .user
        pickEntity.pickIds = chatterIds
        request.pickEntities.append(pickEntity)
        return client.sendAsyncRequest(request)
            .subscribeOn(scheduler)
    }

    func deleteChatters(chatId: String, chatterIds: [String], newOwnerId: String? = nil) -> Observable<Void> {
        var request = RustPB.Im_V1_DeleteChatChattersRequest()
        request.chatID = chatId
        request.chatterIds = chatterIds
        if let newID = newOwnerId, !newID.isEmpty {
            request.newOwnerID = newID
        }
        return client.sendAsyncRequest(request)
            .subscribeOn(scheduler)
    }

    func withdrawAddChatters(chatId: String, chatterIds: [String], chatIds: [String], departmentIds: [String]) -> Observable<Void> {
        var request = RustPB.Im_V1_DeleteChatChattersRequest()
        request.chatID = chatId
        request.chatterIds = chatterIds
        var option = DeleteChatChattersRequest.DeleteChatChatterOption()
        option.withdraw = true
        request.option = option
        if !chatterIds.isEmpty {
            var pickEntity = Basic_V1_PickEntities()
            pickEntity.pickType = .user
            pickEntity.pickIds = chatterIds
            request.pickEntities.append(pickEntity)
        }
        if !chatIds.isEmpty {
            var pickEntity = Basic_V1_PickEntities()
            pickEntity.pickType = .chat
            pickEntity.pickIds = chatIds
            request.pickEntities.append(pickEntity)
        }
        if !departmentIds.isEmpty {
            var pickEntity = Basic_V1_PickEntities()
            pickEntity.pickType = .dept
            pickEntity.pickIds = departmentIds
            request.pickEntities.append(pickEntity)
        }
        return client.sendAsyncRequest(request)
            .subscribeOn(scheduler)
    }

    func disableChatShared(messageId: String) -> Observable<Void> {
        var request = RustPB.Im_V1_DisableChatSharedRequest()
        request.messageID = messageId
        return client.sendAsyncRequest(request)
            .subscribeOn(scheduler)
    }

    func checkChattersInChat(chatterIds: [String], chatId: String) -> Observable<[String]> {
        var request = RustPB.Im_V1_CheckChattersInChatRequest()
        request.chatterIds = chatterIds
        request.chatID = chatId
        return client.sendAsyncRequest(request, transform: { (res: RustPB.Im_V1_CheckChattersInChatResponse) -> [String] in
            let keys = res.chatters.filter({ (result) -> Bool in
                return result.value
            }).keys
            return Array(keys)
        }).subscribeOn(scheduler)
    }

    func checkChattersChatsDepartmentsInChat(chatterIds: [String], chatIds: [String], departmentIds: [String], chatId: String) -> Observable<[String: Bool]> {
        var request = ServerPB_Chats_CheckWithdrawPickEntitiesInChatRequest()
        request.chatID = chatId
        if !chatterIds.isEmpty {
            var pickEntity = ServerPB_Chats_PickEntities()
            pickEntity.pickType = .user
            pickEntity.pickIds = chatterIds
            request.pickEntities.append(pickEntity)
        }
        if !chatIds.isEmpty {
            var pickEntity = ServerPB_Chats_PickEntities()
            pickEntity.pickType = .chat
            pickEntity.pickIds = chatIds
            request.pickEntities.append(pickEntity)
        }
        if !departmentIds.isEmpty {
            var pickEntity = ServerPB_Chats_PickEntities()
            pickEntity.pickType = .dept
            pickEntity.pickIds = departmentIds
            request.pickEntities.append(pickEntity)
        }
        return client.sendPassThroughAsyncRequest(request, serCommand: .checkWithdrawPickEntitiesInChat) { (res: ServerPB_Chats_CheckWithdrawPickEntitiesInChatResponse) -> [String: Bool] in
            return res.allowWithdraw
        }.subscribeOn(scheduler)
    }

    func updateChat(chatId: String, name: String) -> Observable<LarkModel.Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        request.name = name

        return RustChatAPI.updateChat(request: request, security: true, client: client)
            .subscribeOn(scheduler)
    }

    func updateChat(chatId: String, description: String) -> Observable<LarkModel.Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        request.description_p = description

        return RustChatAPI.updateChat(request: request, security: true, client: client)
            .subscribeOn(scheduler)
    }

    func updateChat(chatId: String, isRemind: Bool) -> Observable<LarkModel.Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        request.isRemind = isRemind

        return RustChatAPI.updateChat(request: request, client: client)
            .subscribeOn(scheduler)
    }

    func updateChat(chatId: String, announcement: String) -> Observable<LarkModel.Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        request.announcement = announcement

        return RustChatAPI.updateChat(request: request, client: client)
            .subscribeOn(scheduler)
    }

    func updateChat(chatId: String, iconData: Data, avatarMeta: RustPB.Basic_V1_AvatarMeta?) -> Observable<LarkModel.Chat> {
        var request = RustPB.Media_V1_UploadAvatarRequest()
        request.image = iconData
        return client.sendAsyncSecurityRequest(request) { (response: RustPB.Media_V1_UploadAvatarResponse) -> String in
            return response.key
        }.flatMap({ [client] (key) -> Observable<LarkModel.Chat> in
            var request = RustPB.Im_V1_UpdateChatRequest()
            request.chatID = chatId
            request.iconKey = key
            if let meta = avatarMeta { request.avatarMeta = meta }
            return RustChatAPI.updateChat(request: request, client: client)
        }).subscribeOn(scheduler)
    }

    func updateChat(chatId: String, avatarMeta: RustPB.Basic_V1_AvatarMeta?) -> Observable<LarkModel.Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        request.iconKey = ""
        if let meta = avatarMeta { request.avatarMeta = meta }
        return RustChatAPI.updateChat(request: request, client: client)
            .subscribeOn(scheduler)
    }

    func updateChat(chatId: String, offEditInfo: Bool) -> Observable<LarkModel.Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        request.offEditInfo = offEditInfo
        return RustChatAPI.updateChat(request: request, client: client)
            .subscribeOn(scheduler)
    }

    func updateChat(chatId: String, addMemberPermission: LarkModel.Chat.AddMemberPermission.Enum) -> Observable<LarkModel.Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        request.addMemberPermission = addMemberPermission

        return RustChatAPI.updateChat(request: request, client: client)
            .subscribeOn(scheduler)
    }

    func updateChat(chatId: String, shareCardPermission: LarkModel.Chat.ShareCardPermission.Enum) -> Observable<LarkModel.Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        request.shareCardPermission = shareCardPermission

        return RustChatAPI.updateChat(request: request, client: client)
            .subscribeOn(scheduler)
    }

    /// 更新群主题
    func updateChatTheme(chatId: String,
                         themeId: Int64?,
                         theme: Data,
                         isReset: Bool,
                         scope: Im_V2_ChatThemeType) -> Observable<RustPB.Im_V2_SetChatThemeResponse> {
        var request = RustPB.Im_V2_SetChatThemeRequest()
        if let themeId = themeId {
            request.themeID = themeId
        }
        request.reset = isReset
        request.chatID = Int64(chatId) ?? 0
        request.chatTheme = theme
        request.themeType = scope

        return client.sendAsyncRequest(request)
            .subscribeOn(scheduler)
    }

    func fetchChatThemeListRequest(chatID: String,
                                   themeType: Im_V2_ChatThemeType,
                                   limit: Int64?,
                                   pos: Int64?) -> Observable<RustPB.Im_V2_GetChatThemeListResponse> {
        var request = RustPB.Im_V2_GetChatThemeListRequest()
        request.chatID = Int64(chatID) ?? 0
        request.themeType = themeType
        if let limit = limit {
            request.limit = limit
        }
        if let pos = pos {
            request.pos = pos
        }
        return client.sendAsyncRequest(request)
            .subscribeOn(scheduler)
    }

    func updateChat(chatId: String, createUrgentSetting: Chat.CreateUrgentSetting) -> Observable<Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        request.createUrgentSetting = createUrgentSetting

        return RustChatAPI.updateChat(request: request, client: client)
            .subscribeOn(scheduler)
    }

    func updateChat(chatId: String, createVideoConferenceSetting: Chat.CreateVideoConferenceSetting) -> Observable<Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        request.createVideoConferenceSetting = createVideoConferenceSetting

        return RustChatAPI.updateChat(request: request, client: client)
            .subscribeOn(scheduler)
    }

    func updateChat(chatId: String, pinPermissionSetting: Chat.PinPermissionSetting) -> Observable<Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        request.pinPermissionSetting = pinPermissionSetting

        return RustChatAPI.updateChat(request: request, client: client)
            .subscribeOn(scheduler)
    }

    func updateChat(chatId: String,
                    addMemberPermission: LarkModel.Chat.AddMemberPermission.Enum,
                    shareCardPermission: LarkModel.Chat.ShareCardPermission.Enum) -> Observable<LarkModel.Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        request.shareCardPermission = shareCardPermission
        request.addMemberPermission = addMemberPermission

        return RustChatAPI.updateChat(request: request, client: client)
            .subscribeOn(scheduler)
    }

    func updateChat(chatId: String, atAllPermission: LarkModel.Chat.AtAllPermission.Enum) -> Observable<LarkModel.Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        request.atAllPermission = atAllPermission

        return RustChatAPI.updateChat(request: request, client: client)
            .subscribeOn(scheduler)
    }

    func updateChat(chatId: String, allowSendMail: Bool) -> Observable<Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        request.allowMailSend = allowSendMail
        return RustChatAPI.updateChat(request: request, client: client)
            .subscribeOn(scheduler)
    }

    func updateChat(chatId: String, permissionType: Chat.MailPermissionType) -> Observable<Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        request.mailSendPermission = permissionType
        return RustChatAPI.updateChat(request: request, client: client)
            .subscribeOn(scheduler)
    }

    func updateChat(chatId: String,
                    allowSendMail: Bool,
                    permissionType: Chat.MailPermissionType) -> Observable<Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        request.allowMailSend = allowSendMail
        request.mailSendPermission = permissionType
        return RustChatAPI.updateChat(request: request, client: client)
            .subscribeOn(scheduler)
    }

    func updateChat(chatId: String, messagePosition: LarkModel.Chat.MessagePosition.Enum) -> Observable<LarkModel.Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        request.messagePosition = messagePosition

        return RustChatAPI.updateChat(request: request, client: client)
            .subscribeOn(scheduler)
    }

    func updateChat(chatId: String, burnLife: Int32) -> Observable<LarkModel.Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        request.burnLife = burnLife
        return RustChatAPI.updateChat(request: request, client: client)
            .subscribeOn(scheduler)
    }

    func updateChat(chatId: String, leaveGroupNotiftType: LarkModel.Chat.SystemMessageVisible.Enum) -> Observable<LarkModel.Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        request.quitMessageVisible = leaveGroupNotiftType
        return RustChatAPI.updateChat(request: request, client: client)
            .subscribeOn(scheduler)
    }

    func updateChat(chatId: String, messageVisibilitySetting: LarkModel.Chat.MessageVisibilitySetting.Enum) -> Observable<Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        request.messageVisibilitySetting = messageVisibilitySetting
        return RustChatAPI.updateChat(request: request, client: client)
            .subscribeOn(scheduler)
    }

    func updateChat(chatId: String,
                    isPublic: Bool,
                    addMemberPermission: LarkModel.Chat.AddMemberPermission.Enum?,
                    shareCardPermission: LarkModel.Chat.ShareCardPermission.Enum?) -> Observable<LarkModel.Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        request.isPublicV2 = isPublic
        if let addMemberPermission = addMemberPermission {
            request.addMemberPermission = addMemberPermission
        }
        if let shareCardPermission = shareCardPermission {
            request.shareCardPermission = shareCardPermission
        }
        return RustChatAPI.updateChat(request: request, client: client)
            .subscribeOn(scheduler)
    }

    func updateChat(chatId: String, joinGroupNotiftType: LarkModel.Chat.SystemMessageVisible.Enum) -> Observable<LarkModel.Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        request.joinMessageVisible = joinGroupNotiftType
        return RustChatAPI.updateChat(request: request, client: client)
            .subscribeOn(scheduler)
    }

    func updateChat(chatId: String, isAutoTranslate: Bool) -> Observable<LarkModel.Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        request.isAutoTranslate = isAutoTranslate
        return RustChatAPI.updateChat(request: request, client: client)
            .subscribeOn(scheduler)
    }

    func updateChat(chatId: String, isRealTimeTranslate: Bool, realTimeTranslateLanguage: String) -> Observable<LarkModel.Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        request.typingTranslateSetting.isOpen = isRealTimeTranslate
        var targetLanguage = realTimeTranslateLanguage
        if targetLanguage.isEmpty {
            targetLanguage = (chatterManager?.currentChatter.majorLanguage ?? "").lowercased() == "en" ? "zh" : "en"
        }
        request.typingTranslateSetting.targetLanguage = targetLanguage
        return RustChatAPI.updateChat(request: request, client: client)
            .subscribeOn(scheduler)
    }

    func updateChat(chatId: String, isDelayed: Bool) -> Observable<LarkModel.Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        request.isDelayed = isDelayed
        return RustChatAPI.updateChat(request: request, client: client)
            .subscribeOn(scheduler)
    }

    func updateChat(chatId: String, isMuteAtAll: Bool) -> Observable<LarkModel.Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        request.isMuteAtAll = isMuteAtAll
        return RustChatAPI.updateChat(request: request, client: client)
            .subscribeOn(scheduler)
    }

    func fetchChatAvatarMeta(chatId: String) -> Observable<RustPB.Basic_V1_AvatarMeta> {
        var request = RustPB.Im_V1_GetChatAvatarMetaRequest()
        request.chatID = chatId
        return client.sendAsyncRequest(request) { (res: RustPB.Im_V1_GetChatAvatarMetaResponse) -> RustPB.Basic_V1_AvatarMeta in
            return res.avatarMeta
        }.subscribeOn(scheduler)
    }

    func getChatLimitInfo(chatId: String) -> Observable<RustPB.Im_V1_GetChatLimitInfoResponse> {
        var request = RustPB.Im_V1_GetChatLimitInfoRequest()
        request.chatID = chatId
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func transferGroupOwner(chatId: String, ownerId: String) -> Observable<LarkModel.Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        request.ownerID = ownerId
        return RustChatAPI.updateChat(request: request, client: client)
            .subscribeOn(scheduler)
    }

    func getDynamicRule(chatId: String) -> Observable<ServerPB_Chats_PullChatRefDynamicRuleResponse> {
        var request = ServerPB_Chats_PullChatRefDynamicRuleRequest()
        request.chatID = chatId
        return client.sendPassThroughAsyncRequest(request, serCommand: .pullChatRefDynamicRule)
    }

    func getDynamicRuleOptionSettings(chatId: String) -> Observable<ServerPB_Chats_PullDynamicRuleOptionsByFieldResponse> {
        var request = ServerPB_Chats_PullDynamicRuleOptionsByFieldRequest()
        request.chatID = chatId
        request.field = .department
        return client.sendPassThroughAsyncRequest(request, serCommand: .pullDynamicRuleOptions)
    }

    func clearChatMessages(chatId: String) -> Observable<RustPB.Im_V1_ClearChatMessagesResponse> {
        var request = RustPB.Im_V1_ClearChatMessagesRequest()
        request.chatID = chatId
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func disbandGroup(chatId: String) -> Observable<LarkModel.Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        request.isDissolved = true
        return RustChatAPI.updateChat(request: request, client: client)
            .subscribeOn(scheduler)
    }

    func frozenGroup(chatId: String) -> Observable<Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        request.isFrozen = true
        return RustChatAPI.updateChat(request: request, client: client)
            .subscribeOn(scheduler)
    }

    func fetchChatResources(chatId: String, count: Int32, resourceTypes: [RustPB.Media_V1_ChatResourceType]) -> Observable<FetchChatResourcesResult> {
        return self.fetchChatResources(chatId: chatId, fromMessageId: "", count: count, direction: .before, resourceTypes: resourceTypes)
    }

    func fetchChatResources(chatId: String,
                            fromMessageId: String,
                            count: Int32,
                            direction: RustPB.Media_V1_GetChatResourcesRequest.Direction,
                            resourceTypes: [RustPB.Media_V1_ChatResourceType]) -> Observable<FetchChatResourcesResult> {
        print("Media_V1_GetChatResourcesRequest trace \(direction)")
        var request = RustPB.Media_V1_GetChatResourcesRequest()
        request.chatID = chatId
        request.count = count
        if !fromMessageId.isEmpty {
            request.messageID = fromMessageId
        }
        request.direction = direction
        request.resourceTypes = resourceTypes
        return client.sendAsyncRequest(request) { (res: RustPB.Media_V1_GetChatResourcesResponse) -> FetchChatResourcesResult in
            return FetchChatResourcesResult(messageMetas: res.messages, hasMoreBefore: res.hasMoreBefore_p, hasMoreAfter: res.hasMoreAfter_p)
        }
    }

    /// 获取群二维码 token
    func getChatQRCodeToken(chatId: String, expiredDay: ExpiredDay) -> Observable<RustPB.Im_V1_GetChatQRCodeTokenResponse> {
        var request = GetChatQRCodeTokenRequest()
        request.chatID = chatId
        if case .fixed(let time) = expiredDay {
            request.expiredDay = time
        } else if case .forever = expiredDay {
            request.isUnlimited = true
        }
        return client.sendAsyncRequest(request)
    }

    /// 通过群二维码Token获取ChatInfo
    func getChatQRCodeInfo(token: String) -> Observable<ChatQRCodeInfo> {
        var request = GetChatQRCodeInfoRequest()
        request.token = token
        return client.sendAsyncRequest(request)
            .flatMap { (info: Im_V1_GetChatQRCodeInfoResponse) -> Observable<ChatQRCodeInfo> in
                if let newInfo = ChatQRCodeInfo(with: info) {
                    return .just(newInfo)
                }
                return .error(NSError(domain: "QRCode info read chat failed.", code: -1, userInfo: nil))
            }
    }

    /// 获取群链接
    func getChatShareLink(chatId: String, expiredDay: ExpiredDay, appName: String) -> Observable<RustPB.Im_V1_GetChatLinkTokenResponse> {
        var request = ServerPB_Chats_PullChatLinkTokenRequest()
        request.chatID = chatId
        if case .fixed(let time) = expiredDay {
            request.expiredDay = time
        } else if case .forever = expiredDay {
            request.isUnlimited = true
        }
        request.appName = appName
        return client.sendPassThroughAsyncRequest(request, serCommand: .pullChatLinkToken)
    }

    /// 通过群 ViaLink Info
    func getChatViaLinkInfo(token: String) -> Observable<ChatLinkInfo> {
        var request = Im_V1_GetChatLinkInfoRequest()
        request.token = token
        return client.sendAsyncRequest(request)
            .flatMap { (info: Im_V1_GetChatLinkInfoResponse) -> Observable<ChatLinkInfo> in
                if let newInfo = ChatLinkInfo(with: info) {
                    return .just(newInfo)
                }
                return .error(NSError(domain: "VIALink read chat failed.", code: -1, userInfo: nil))
            }
    }

    // 获取chat中可以发言的ChatterID
    func fetchChatPostChatterIds(chatId: String) -> Observable<([String], [String: LarkModel.Chatter])> {
        var request = GetChatPostUsersRequest()
        request.chatID = chatId
        return client.sendAsyncRequest(request, transform: { (response: GetChatPostUsersResponse) -> ([String], [String: LarkModel.Chatter]) in
            let chatters = response.entity.chatChatters[chatId]?.chatters
                .filter { response.userIds.contains($0.key) }
                .mapValues { LarkModel.Chatter.transform(pb: $0) }

            return (response.userIds, chatters ?? [:])
        })
    }

    // 更新群成员发言权限
    func updateChatPostChatters(chatId: String, postType: LarkModel.Chat.PostType, addChatterIds: [String], removeChatterIds: [String]) -> Observable<Void> {
        var request = UpdateChatPostUsersRequest()
        request.chatID = chatId
        request.postType = postType
        request.toAddUserIds = addChatterIds
        request.toDelUserIds = removeChatterIds
        return client.sendAsyncRequest(request, transform: { (_: UpdateChatPostUsersResponse) -> Void in return })
    }

    func subscribeChatEvent(chatIds: [String], subscribe: Bool) {
        var request = SubscribeChatEventRequest()
        if subscribe {
            request.subscribeChatIds = chatIds
        } else {
            request.unsubscribeChatIds = chatIds
        }
        do {
            try client.sendSyncRequest(request)
        } catch {
            RustChatAPI.logger.error("Subscribe chat event failed.",
                                     additionalData: ["chatIds": "\(chatIds)", "subscribe": "\(subscribe)"],
                                     error: error)
        }
    }

    func asyncSubscribeChatEvent(chatIds: [String], subscribe: Bool) {
        var request = SubscribeChatEventRequest()
        if subscribe {
            request.subscribeChatIds = chatIds
        } else {
            request.unsubscribeChatIds = chatIds
        }
        var disposeBag: DisposeBag = DisposeBag()
        client.sendAsyncRequest(request).subscribe(onError: { (error) in
            RustChatAPI.logger.error("Subscribe chat event failed.",
                                     additionalData: ["chatIds": "\(chatIds)", "subscribe": "\(subscribe)"],
                                     error: error)
            disposeBag = DisposeBag()
        }).disposed(by: disposeBag)
    }

    // --- 入群申请 Start ---
    func updateChat(chatId: String, applyType: RustPB.Basic_V1_Chat.AddMemberApply.Enum) -> Observable<Void> {
        var request = UpdateChatRequest()
        request.chatID = chatId
        request.addMemberApply = applyType
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func createAddChatChatterApply(chatId: String,
                                   way: RustPB.Basic_V1_AddChatChatterApply.Ways,
                                   chatterIds: [String],
                                   reason: String?,
                                   inviterId: String?,
                                   joinToken: String?) -> Observable<Void> {
        return createAddChatChatterApply(chatId: chatId,
                                         way: way,
                                         chatterIds: chatterIds,
                                         reason: reason,
                                         inviterId: inviterId,
                                         joinToken: joinToken,
                                         teamId: nil,
                                         eventID: nil,
                                         linkPageURL: nil)
    }

    func createAddChatChatterApply(chatId: String,
                                   way: RustPB.Basic_V1_AddChatChatterApply.Ways,
                                   chatterIds: [String],
                                   reason: String?,
                                   inviterId: String?,
                                   joinToken: String?,
                                   teamId: Int64?,
                                   eventID: String?,
                                   linkPageURL: String?) -> Observable<Void> {
        var request = CreateAddChatChatterApplyRequest()
        request.chatID = chatId
        request.way = way
        request.chatterIds = chatterIds
        if let teamId = teamId {
            request.teamID = teamId
        }
        if let eventID = eventID { request.eventID = eventID }
        if let reason = reason { request.reason = reason }
        if let inviterId = inviterId { request.inviterID = inviterId }
        if let joinToken = joinToken { request.joinToken = joinToken }
        if let linkPageURL = linkPageURL {
            var chatPageContext = Im_V1_ChatPageContext()
            chatPageContext.targetURL = linkPageURL
            request.fromPage = chatPageContext
        }
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func getAddChatChatterApply(chatId: String, cursor: String?) -> Observable<RustPB.Im_V1_GetAddChatChatterApplyResponse> {
        var request = GetAddChatChatterApplyRequest()
        request.chatID = chatId
        if let cursor = cursor {
            request.cursor = cursor
        }
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)

    }

    func updateAddChatChatterApply(chatId: String, showBanner: Bool) -> Observable<Void> {
        var request = UpdateAddChatChatterApplyRequest()
        request.chatID = chatId
        request.showBanner = showBanner
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func updateAddChatChatterApply(chatId: String, inviteeId: String, status: RustPB.Basic_V1_AddChatChatterApply.Status) -> Observable<Void> {
        var request = UpdateAddChatChatterApplyRequest()
        request.chatID = chatId
        request.inviteeID = inviteeId
        request.status = status
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }
    // --- 入群申请 End ---

    func updateLastDraft(chatId: String, draftId: String) -> Observable<Void> {
        var request = CreateOrDeleteChatLastDraftIdRequest()
        request.chatID = chatId
        request.draftID = draftId
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    //code_block_start tag CryptChat
    func userTakeScreenshot(chatId: String) -> Observable<Void> {
        var request = RustPB.Im_V1_PutUserScreenshotActionRequest()
        request.chatID = chatId
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }
    //code_block_end

    func setChatLastRead(chatId: String, messagePosition: Int32, offsetInScreen: CGFloat) -> Observable<Void> {
        var request = CreateChatLastReadPositionRequest()
        request.chatID = chatId
        request.position = messagePosition
        request.offset = Float(offsetInScreen)
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    /// 获取群分享历史
    func getGroupShareHistory(chatID: String, cursor: String?, count: Int32?) -> Observable<RustPB.Im_V1_PullChatShareHistoryResponse> {
        var request = PullChatShareHistoryRequest()
        request.chatID = chatID
        if let cursor = cursor { request.cursor = cursor }
        if let count = count { request.count = count }

        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }
    /// 更新群分享历史状态
    func updateGroupShareHistory(tokens: [String], status: RustPB.Basic_V1_ChatShareInfo.ShareStatus) -> Observable<Void> {
        var request = PatchChatShareStatusRequest()
        request.tokens = tokens
        request.status = status
        return self.client.sendAsyncRequest(request)
            .map { (_: PatchChatShareStatusResponse) in }
            .subscribeOn(scheduler)
    }

    /// 获取 SOS 紧急电话
    func getEmergencyCallNumber(callerPhoneNumber: String, calleeUserId: String) -> Observable<RustPB.Contact_V1_GetEmergencyCallNumberResponse> {
        var request = GetEmergencyCallNumberRequest()
        request.calleeUserID = calleeUserId
        request.callerPhoneNumber = callerPhoneNumber
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    /// 提交紧急电话拨打缘由
    func setEmergencyCallReason(callId: String, reason: String) -> Observable<RustPB.Contact_V1_SetEmergencyCallReasonResponse> {
        var request = SetEmergencyCallReasonRequest()
        request.callID = callId
        request.reason = reason
        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    /// load group memebers join and leave history
    /// 加载群成员进退群历史
    func getChatJoinLeaveHistory(
        chatID: String,
        cursor: String?,
        count: Int32?
    ) -> Observable<Im_V1_GetChatJoinLeaveHistoryResponse> {
        var request = Im_V1_GetChatJoinLeaveHistoryRequest()
        request.chatID = chatID
        if let cursor = cursor { request.cursor = cursor }
        if let count = count { request.count = count }

        return self.client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    /// 进入chat通知
    func enterChat(chatId: String) -> Observable<Void> {
        var requset = Behavior_V1_EnterChatRequest()
        requset.chatID = chatId
        return self.client.sendAsyncRequest(requset).subscribeOn(scheduler)
    }

    /// 离开chat通知
    func exitChat(chatId: String) -> Observable<Void> {
        var requset = Behavior_V1_ExitChatRequest()
        requset.chatID = chatId
        return self.client.sendAsyncRequest(requset).subscribeOn(scheduler)
    }

    func getKickInfo(chatId: String) -> Observable<String> {
        var requset = RustPB.Im_V1_GetChatChatterKickRequest()
        requset.chatID = chatId
        return self.client.sendAsyncRequest(requset).map { (res: RustPB.Im_V1_GetChatChatterKickResponse) -> String in
            if res.chatChatterKickInfo.reason.isEmpty {
                throw APIError(type: .unknowError)
            }
            return res.chatChatterKickInfo.reason
        }
    }

    func batchPutP2PChatMessage(toUserIds: [String], content: RustPB.Basic_V1_Content, type: RustPB.Basic_V1_Message.TypeEnum) -> Observable<RustPB.Im_V1_BatchPutP2PChatMessageResponse> {
        var request = RustPB.Im_V1_BatchPutP2PChatMessageRequest()
        request.toUserIds = toUserIds
        request.content = content
        request.type = type
        return self.client.sendAsyncRequest(request)
    }

    func fetchChatAdminUsers(chatId: String, isFromServer: Bool) -> Observable<[Chatter]> {
        var request = RustPB.Im_V1_GetChatAdminUsersRequest()
        request.syncDataStrategy = isFromServer ? .forceServer : .local
        request.chatID = chatId
        return self.client.sendAsyncRequest(request, transform: { (response: RustPB.Im_V1_GetChatAdminUsersResponse) -> [Chatter] in
            let chattersDic = response.entity.chatChatters[chatId]?.chatters ?? [:]
            return response.adminUsers.compactMap({ (id) -> Chatter? in
                if let model = chattersDic.first(where: { $0.key == id })?.value {
                    return LarkModel.Chatter.transform(pb: model)
                }
                return nil
            })
        })
    }

    func fetchChatAdminUsersWithLocalAndServer(chatId: String) -> Observable<[Chatter]> {
        struct D: MergeDep {
            func isEmpty(response: [Chatter]) -> Bool {
                response.isEmpty
            }
        }
        let localObservable = fetchChatAdminUsers(chatId: chatId, isFromServer: false)
        let remoteObservable = fetchChatAdminUsers(chatId: chatId, isFromServer: true)
        return mergedObservable(local: localObservable, remote: remoteObservable, delegate: D(), featureGatingService: featureGatingService).map({ $0.0 })
    }

    func patchChatAdminUsers(chatId: String,
                             toAddUserIds: [String],
                             toDeleteUserIds: [String]) -> Observable<Void> {
        var request = RustPB.Im_V1_PatchChatAdminUsersRequest()
        if !toAddUserIds.isEmpty {
            request.toAddUserIds = toAddUserIds
        }
        if !toDeleteUserIds.isEmpty {
            request.toDelUserIds = toDeleteUserIds
        }
        request.chatID = chatId
        return self.client.sendAsyncRequest(request)
    }

    func fetchChatLinkedPages(chatID: Int64, isFromServer: Bool) -> Observable<RustPB.Im_V1_GetChatLinkedPagesResponse> {
        var request = Im_V1_GetChatLinkedPagesRequest()
        request.chatID = chatID
        if isFromServer {
            request.syncDataStrategy = .forceServer
        } else {
            request.syncDataStrategy = .local
        }
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func deleteChatLinkedPages(chatID: Int64, pageURLs: [String]) -> Observable<RustPB.Im_V1_DeleteChatLinkedPagesResponse> {
        var request = Im_V1_DeleteChatLinkedPagesRequest()
        request.chatID = chatID
        request.pageUrls = pageURLs
        return client.sendAsyncRequest(request)
            .do(onNext: { [weak self] _ in
                try? self?.userResolver.userPushCenter.post(PushLocalDeleteChatLinkedPages(chatID: chatID, pageURLs: pageURLs))
            }).subscribeOn(self.scheduler)
    }

    func getChatMenuItems(chatId: Int64) -> Observable<RustPB.Im_V1_GetChatMenuItemsResponse> {
        var request = RustPB.Im_V1_GetChatMenuItemsRequest()
        request.chatID = chatId
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func getChatWidgets(chatId: Int64) -> Observable<RustPB.Im_V1_GetChatWidgetsResponse> {
        var request = RustPB.Im_V1_GetChatWidgetsRequest()
        request.chatID = chatId
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func deleteChatWidgets(chatId: Int64, widgetIds: [Int64]) -> Observable<RustPB.Im_V1_DeleteChatWidgetsResponse> {
        var request = RustPB.Im_V1_DeleteChatWidgetsRequest()
        request.chatID = chatId
        request.widgetIds = widgetIds
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func reorderChatWidgets(chatId: Int64, widgetIds: [Int64]) -> Observable<RustPB.Im_V1_ReorderChatWidgetsResponse> {
        var request = RustPB.Im_V1_ReorderChatWidgetsRequest()
        request.chatID = chatId
        request.widgetIds = widgetIds
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func triggerChatMenuEvent(chatId: Int64, menuId: Int64) -> Observable<ServerPB.ServerPB_Chats_TriggerMenuEventResponse> {
        var request = ServerPB.ServerPB_Chats_TriggerMenuEventRequest()
        request.chatID = chatId
        request.menuID = menuId
        return client.sendPassThroughAsyncRequest(request, serCommand: .triggerMenuEvent).subscribeOn(scheduler)
    }

    func fetchChatTab(chatId: Int64, fromLocal: Bool) -> Observable<RustPB.Im_V1_GetChatTabsResponse> {
        var request = RustPB.Im_V1_GetChatTabsRequest()
        request.chatID = chatId
        if fromLocal {
            request.strategy = .oldThenTrigger
        } else {
            request.strategy = .sync
        }
        return client.sendAsyncRequest(request)
            .subscribeOn(scheduler)
    }

    func getChatPin(chatId: Int64, count: Int32, needPreview: Bool) -> Observable<RustPB.Im_V1_GetUniversalChatPinsResponse> {
        var request = RustPB.Im_V1_GetUniversalChatPinsRequest()
        request.chatID = chatId
        request.count = count
        request.needPreview = needPreview
        request.getTopPins = true
        request.syncDataStrategy = .local
        return client.sendAsyncRequest(request)
            .subscribeOn(scheduler)
    }

    func fetchChatPin(chatId: Int64, count: Int32, pageToken: String?, needPreview: Bool, getTopPins: Bool) -> Observable<RustPB.Im_V1_GetUniversalChatPinsResponse> {
        var request = RustPB.Im_V1_GetUniversalChatPinsRequest()
        request.chatID = chatId
        request.count = count
        request.needPreview = needPreview
        request.getTopPins = getTopPins
        if let pageToken = pageToken {
            request.pageToken = pageToken
        }
        request.syncDataStrategy = .forceServer
        return client.sendAsyncRequest(request)
            .subscribeOn(scheduler)
    }

    func deleteChatPin(chatId: Int64, pinId: Int64) -> Observable<RustPB.Im_V1_DeleteUniversalChatPinResponse> {
        var request = RustPB.Im_V1_DeleteUniversalChatPinRequest()
        request.chatID = chatId
        request.pinID = pinId
        return client.sendAsyncRequest(request)
            .do(onNext: { [weak self] response in
                try? self?.userResolver.userPushCenter.post(PushDeleteChatPinFormLocal(chatId: chatId, deleteIds: [pinId], version: response.meta.version, pinCount: response.meta.pinCount))
            })
            .subscribeOn(scheduler)
    }

    func reorderChatPin(
        chatID: Int64,
        pinID: Int64,
        prevPinID: Int64?,
        clientPinIDs: [Int64],
        reorderType: RustPB.Im_V1_ReorderChatPinRequest.ReorderType,
        clientLogInfo: String
    ) -> Observable<RustPB.Im_V1_ReorderChatPinResponse> {
        var request = RustPB.Im_V1_ReorderChatPinRequest()
        request.chatID = chatID
        request.pinID = pinID
        request.clientPinIds = clientPinIDs
        request.reorderType = reorderType
        if let prevPinID = prevPinID {
            request.prevPinID = prevPinID
        } else {
            switch reorderType {
            case .normal:
                request.prevPinID = Int64(RustPB.Im_V1_ReorderChatPinRequest.PinIdCase.start.rawValue)
            case .top:
                request.prevPinID = Int64(RustPB.Im_V1_ReorderChatPinRequest.PinIdCase.topStart.rawValue)
            @unknown default:
                break
            }
        }
        request.clientLogInfo = clientLogInfo
        return client.sendAsyncRequest(request)
            .subscribeOn(scheduler)
    }

    func getChatPinInfo(chatID: Int64) -> Observable<Im_V1_GetChatPinInfoResponse> {
        var request = Im_V1_GetChatPinInfoRequest()
        request.chatID = chatID
        return self.client.sendAsyncRequest(request).subscribeOn(self.scheduler)
    }

    func createMessageChatPin(messageID: Int64, chatID: Int64) -> Observable<Void> {
        var request = Im_V1_CreateMessageChatPinRequest()
        request.messageID = messageID
        request.chatID = chatID
        return self.client.sendAsyncRequest(request).subscribeOn(self.scheduler)
    }

    func updateURLChatPinTitle(chatId: Int64, pinId: Int64, title: String) -> Observable<RustPB.Im_V1_UpdateUrlChatPinResponse> {
        var request = RustPB.Im_V1_UpdateUrlChatPinRequest()
        request.chatID = chatId
        request.pinID = pinId
        request.updateFields = [.title]
        request.newTitle = title
        return client.sendAsyncRequest(request)
            .do(onNext: { [weak self] response in
                try? self?.userResolver.userPushCenter.post(PushUpdateChatPinFormLocal(chatId: chatId, response: response))
            })
            .subscribeOn(scheduler)
    }

    func notifyCreateUrlChatPinPreview(chatId: Int64, url: String, deleteToken: String) -> Observable<RustPB.Im_V1_NotifyCreateUrlChatPinPreviewResponse> {
        var request = RustPB.Im_V1_NotifyCreateUrlChatPinPreviewRequest()
        request.chatID = chatId
        request.url = url
        request.deleteToken = deleteToken
        return client.sendAsyncRequest(request)
            .subscribeOn(scheduler)
    }

    func deleteUrlChatPinPreview(chatId: Int64, deleteToken: String) -> Observable<RustPB.Im_V1_DeleteUrlChatPinPreviewResponse> {
        var request = RustPB.Im_V1_DeleteUrlChatPinPreviewRequest()
        request.chatID = chatId
        request.deleteToken = deleteToken
        return client.sendAsyncRequest(request)
            .subscribeOn(scheduler)
    }

    func createUrlChatPin(chatId: Int64, params: [(RustPB.Im_V1_UrlChatPinPreviewInfo, Bool)], deleteToken: String) -> Observable<RustPB.Im_V1_CreateUrlChatPinResponse> {
        var request = RustPB.Im_V1_CreateUrlChatPinRequest()
        request.chatID = chatId
        request.params = params.map { (previewInfo, titleUpdated) in
            var createParam = RustPB.Im_V1_CreateUrlChatPinRequest.CreateParam()
            createParam.type = .previewInfo
            createParam.title = previewInfo.title
            createParam.previewInfo = previewInfo
            createParam.titleUpdated = titleUpdated
            return createParam
        }
        request.deleteToken = deleteToken
        return client.sendAsyncRequest(request)
            .do(onNext: { [weak self] response in
                try? self?.userResolver.userPushCenter.post(PushAddChatPinFormLocal(chatId: chatId, response: response))
            })
            .subscribeOn(scheduler)
    }

    func createAnnouncementChatPin(chatId: Int64) -> Observable<RustPB.Im_V1_CreateAnnouncementChatPinResponse> {
        var request = RustPB.Im_V1_CreateAnnouncementChatPinRequest()
        request.chatID = chatId
        return client.sendAsyncRequest(request)
            .subscribeOn(scheduler)
    }

    func stickAnnouncementChatPin(chatID: Int64) -> Observable<RustPB.Im_V1_StickChatPinToTopResponse> {
        var request = RustPB.Im_V1_StickChatPinToTopRequest()
        request.chatID = chatID
        request.stickAnnouncementParam = Im_V1_StickChatPinToTopRequest.StickAnnouncementParam()
        request.actionType = .stickAnnouncement
        return client.sendAsyncRequest(request)
            .subscribeOn(scheduler)
    }

    func stickChatPinToTop(chatID: Int64, pinID: Int64, stick: Bool) -> Observable<RustPB.Im_V1_StickChatPinToTopResponse> {
        var request = RustPB.Im_V1_StickChatPinToTopRequest()
        request.chatID = chatID
        if stick {
            request.actionType = .stickPin
            var stickPinParam = Im_V1_StickChatPinToTopRequest.StickPinParam()
            stickPinParam.pinID = pinID
            request.stickPinParam = stickPinParam
        } else {
            request.actionType = .unstickPin
            var unstickPinParam = Im_V1_StickChatPinToTopRequest.UnstickPinParam()
            unstickPinParam.pinID = pinID
            request.unstickPinParam = unstickPinParam
        }
        return client.sendAsyncRequest(request)
            .do(onNext: { [weak self] response in
                try? self?.userResolver.userPushCenter.post(PushStickChatPinToTop(chatID: chatID, response: response))
            })
            .subscribeOn(scheduler)
    }

    func addChatTab(chatId: Int64, name: String, type: RustPB.Im_V1_ChatTab.TypeEnum, jsonPayload: String?) -> Observable<RustPB.Im_V1_AddChatTabResponse> {
        var request = RustPB.Im_V1_AddChatTabRequest()
        request.chatID = chatId
        request.name = name
        request.type = type
        if let jsonPayload = jsonPayload {
            request.payloadJson = jsonPayload
        }
        return client.sendAsyncSecurityRequest(request)
            .subscribeOn(scheduler)
    }

    func deleteChatTab(chatId: Int64, tabId: Int64) -> Observable<RustPB.Im_V1_DeleteChatTabResponse> {
        var request = RustPB.Im_V1_DeleteChatTabRequest()
        request.chatID = chatId
        request.tabID = tabId
        return client.sendAsyncRequest(request)
            .subscribeOn(scheduler)
    }

    func updateChatTabsOrder(chatId: Int64, reorderTabIds: [Int64]) -> Observable<RustPB.Im_V1_UpdateChatTabOrdersResponse> {
        var request = RustPB.Im_V1_UpdateChatTabOrdersRequest()
        request.chatID = chatId
        request.reOrderedIds = reorderTabIds
        return client.sendAsyncRequest(request)
            .subscribeOn(scheduler)
    }

    func updateChatTabDetail(chatId: Int64, tab: RustPB.Im_V1_ChatTab) -> Observable<RustPB.Im_V1_UpdateChatTabResponse> {
        var request = RustPB.Im_V1_UpdateChatTabRequest()
        request.chatID = chatId
        request.updateTabDetails = [tab.id: tab]
        return client.sendAsyncSecurityRequest(request)
            .subscribeOn(scheduler)
    }

    /// 获取置顶消息
    func getChatTopNoticeWithChatId(_ chatId: Int64) -> Observable<RustPB.Im_V1_GetChatTopNoticeResponse> {
        var request = RustPB.Im_V1_GetChatTopNoticeRequest()
        request.chatID = chatId
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    /// 替换置顶消息& 删除 & 关闭置顶消息
    func patchChatTopNoticeWithChatID(_ chatId: Int64,
                                      type: RustPB.Im_V1_PatchChatTopNoticeRequest.ActionType,
                                      senderId: Int64?,
                                      messageId: Int64?) -> Observable<RustPB.Im_V1_PatchChatTopNoticeResponse> {
        var request = RustPB.Im_V1_PatchChatTopNoticeRequest()
        request.chatID = chatId
        request.type = type
        /// 群公告需要指定信息的发送者
        if let senderId = senderId {
            request.senderID = senderId
        }
        if let messageId = messageId {
            request.messageID = messageId
        }
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    /// 更新置顶的权限
    func updateChat(chatId: String,
                    topNoticePermissionType: RustPB.Basic_V1_Chat.TopNoticePermissionSetting.Enum) -> Observable<LarkModel.Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        request.topNoticePermissionSetting = topNoticePermissionType
        return RustChatAPI.updateChat(request: request, client: client)
            .subscribeOn(scheduler)
    }

    func clearOrderedChatChatters(chatId: String, uid: String) -> Observable<Void> {
        var request = RustPB.Im_V1_ClearOrderedChatChattersRequest()
        request.chatID = Int64(chatId) ?? 0
        request.uid = uid
        return client.sendAsyncRequest(request)
    }

    func updateChat(chatId: String,
                    chatTabPermissionSetting: LarkModel.Chat.ChatTabPermissionSetting) -> Observable<LarkModel.Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        request.chatTabPermissionSetting = chatTabPermissionSetting
        return RustChatAPI.updateChat(request: request, client: client)
            .subscribeOn(scheduler)
    }

    func updateChat(chatId: String, chatPinPermissionSetting: LarkModel.Chat.ChatPinPermissionSetting) -> Observable<LarkModel.Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        request.chatPinPermissionSetting = chatPinPermissionSetting
        return RustChatAPI.updateChat(request: request, client: client)
            .subscribeOn(scheduler)
    }

    func pullChatMemberSetting(tenantId: Int64, chatId: Int64?) -> Observable<ServerPB.ServerPB_Chats_PullChatMemberSettingResponse> {
        var request = ServerPB.ServerPB_Chats_PullChatMemberSettingRequest()
        request.tenantID = tenantId
        if let chatId = chatId {
            request.chatID = chatId
        }
        return client.sendPassThroughAsyncRequest(request, serCommand: .pullChatMemberSetting).subscribeOn(scheduler)
    }

    func putChatMemberSuppRoleApproval(chatId: Int64, applyUpperLimit: Int32, applyTypeKey: String?, description: String) -> Observable<ServerPB.ServerPB_Misc_PutChatMemberSuppRoleApprovalResponse> {
        var request = ServerPB.ServerPB_Misc_PutChatMemberSuppRoleApprovalRequest()
        request.chatID = chatId
        request.applyUpperLimit = applyUpperLimit
        request.description_p = description
        if let applyTypeKey = applyTypeKey {
            request.applyTypeKey = applyTypeKey
        }
        return client.sendPassThroughAsyncRequest(request, serCommand: .putChatMemberSuppRoleApproval).subscribeOn(scheduler)
    }

    func pullChatMemberSuppRoleApprovalSetting(tenantId: Int64, applyUpperLimit: Int32?) -> Observable<ServerPB.ServerPB_Misc_PullChatMemberSuppRoleApprovalSettingResponse> {
        var request = ServerPB.ServerPB_Misc_PullChatMemberSuppRoleApprovalSettingRequest()
        request.tenantID = tenantId
        if let applyUpperLimit = applyUpperLimit {
            request.applyUpperLimit = applyUpperLimit
        }
        return client.sendPassThroughAsyncRequest(request, serCommand: .pullChatMemberSuppRoleApprovalSetting).subscribeOn(scheduler)
    }

    func pullChatMemberSuppRoleApprovalChatterIds(tenantId: Int64, applyTypeKey: String?, applyUpperLimit: Int32?) -> Observable<[Int64]> {
        var request = ServerPB.ServerPB_Misc_PullChatMemberSuppRoleApprovalSettingRequest()
        request.tenantID = tenantId
        if let applyTypeKey = applyTypeKey {
            request.applyTypeKey = applyTypeKey
        }
        if let applyUpperLimit = applyUpperLimit {
            request.applyUpperLimit = applyUpperLimit
        }
        return client.sendPassThroughAsyncRequest(request,
                                                  serCommand: .pullChatMemberSuppRoleApprovalSetting,
                                                  transform: { (res: ServerPB.ServerPB_Misc_PullChatMemberSuppRoleApprovalSettingResponse) -> [Int64] in
            return res.approverIds
        })
    }

    func pullChangeGroupMemberAuthorization(pickEntities: [ServerPB_Chats_PickEntities],
                                            chatMode: ServerPB_Entities_Chat.ChatMode?,
                                            fromChatId: Int64?) -> Observable<ServerPB.ServerPB_Chats_PullChangeGroupMemberAuthorizationResponse> {
        var request = ServerPB.ServerPB_Chats_PullChangeGroupMemberAuthorizationRequest()
        request.pickEntities = pickEntities
        if let chatMode = chatMode {
            request.chatMode = chatMode
        }
        if let fromChatId = fromChatId {
            request.fromChatID = fromChatId
        }
        return client.sendPassThroughAsyncRequest(request, serCommand: .pullChangeGroupMemberAuthorization)
    }

    func updateChat(chatId: String, expandWidgets: Bool) -> Observable<Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        request.patchChatterExtraStates = [Int32(Chat.ChatterExtraStatesType.widgetStatus.rawValue):
                                            Int32(expandWidgets ? RustPB.Basic_V1_Chat.WidgetState.expand.rawValue :
                                                    RustPB.Basic_V1_Chat.WidgetState.fold.rawValue)]
        return RustChatAPI.updateChat(request: request, client: client)
            .subscribeOn(scheduler)
    }

    func getChatReportLink(chatId: String, language: String) -> Observable<ServerPB.ServerPB_Messages_GenLarkReportUrlResponse> {
        var request = ServerPB.ServerPB_Messages_GenLarkReportUrlRequest()
        request.chatID = Int64(chatId) ?? 0
        request.langType = language
        return client.sendPassThroughAsyncRequest(request, serCommand: .generateMessageReportURL)
            .do(onNext: { (response: ServerPB.ServerPB_Messages_GenLarkReportUrlResponse) in
                let message = "ChatSettingLog-GetChatReportLink success: "
                + "chatID: \(chatId), "
                + "hasReportURL: \(response.hasReportURL)"
                + "reportURL: \(response.reportURL)"
                Self.logger.info(message)
            }, onError: { (error) in
                let message = "ChatSettingLog-GetChatReportLink error: "
                + "chatID: \(chatId), "
                + "error: \(error)"
                Self.logger.error(message)
            })
    }

    func specialFocusGuidance(targetUserID: Int64) -> Observable<ServerPB_Chatters_SpecialFocusGuidanceResponse> {
        var request = ServerPB.ServerPB_Chatters_SpecialFocusGuidanceRequest()
        request.targetUserID = targetUserID
        return client.sendPassThroughAsyncRequest(request, serCommand: .specialFocusGuidance)
    }

    func updateChat(chatID: String, userCountVisibleSetting: Basic_V1_Chat.UserCountVisibleSetting.Enum) -> Observable<Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatID
        request.userCountVisibleSetting = userCountVisibleSetting
        return RustChatAPI.updateChat(request: request, client: client)
            .subscribeOn(scheduler)
    }

    func updateChat(chatId: String, restrictedModeSetting: Chat.RestrictedModeSetting) -> Observable<Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        request.restrictedModeSetting = restrictedModeSetting
        return RustChatAPI.updateChat(request: request, client: client)
            .subscribeOn(scheduler)
    }

    func getChatSwitch(chatId: String, actionTypes: [Im_V1_ChatSwitchRequest.ActionType], formServer: Bool) -> Observable<[Int: Bool]> {
        var request = RustPB.Im_V1_ChatSwitchRequest()
        request.chatID = Int64(chatId) ?? 0
        request.actionType = actionTypes
        request.strategy = formServer ? .forceServer : .local
        return client.sendAsyncRequest(request) { (res: RustPB.Im_V1_ChatSwitchResponse) -> [Int: Bool] in
            var result: [Int: Bool] = [:]
            for key in res.authInfos.keys {
                result[Int(key)] = res.authInfos[key]?.isAllow ?? false
            }
            return result
        }
    }

    private func getChatSwitch(chatId: String,
                               actionType: Im_V1_ChatSwitchRequest.ActionType,
                               formServer: Bool) -> Observable<Bool?> {
        var request = RustPB.Im_V1_ChatSwitchRequest()
        request.chatID = Int64(chatId) ?? 0
        request.actionType = [actionType]
        request.strategy = formServer ? .forceServer : .local
        return client.sendAsyncRequest(request) { (res: RustPB.Im_V1_ChatSwitchResponse) -> Bool? in
            return res.authInfos[Int32(actionType.rawValue)]?.isAllow
        }
    }

    func getChatSwitchWithLocalAndServer(chatId: String,
                                         actionType: Im_V1_ChatSwitchRequest.ActionType) -> Observable<Bool?> {
        struct D: MergeDep {
            func isEmpty(response: Bool?) -> Bool {
                response == nil
            }
        }
        let localObservable = getChatSwitch(chatId: chatId, actionType: actionType, formServer: false)
        let remoteObservable = getChatSwitch(chatId: chatId, actionType: actionType, formServer: true)
        return mergedObservable(local: localObservable, remote: remoteObservable, delegate: D(), featureGatingService: featureGatingService).map({ $0.0 })
    }

    func updateChat(chatId: String, displayModeInThread: Bool) -> Observable<Chat> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        if displayModeInThread {
            request.chatDisplayModeSetting = .thread
        } else {
            request.chatDisplayModeSetting = .default
        }
        return RustChatAPI.updateChat(request: request, client: client)
            .subscribeOn(scheduler)
    }

    func exitDepartmentGroupAuthorization(chatId: String) -> Observable<Void> {
        var req = ServerPB_Chats_PullExitDepartmentGroupAuthorizationRequest()
        req.chatID = Int64(chatId) ?? 0
        return client.sendPassThroughAsyncRequest(req,
                                                  serCommand: .pullExitDepartmentGroupAuthorization)
        .subscribeOn(scheduler)
    }

    func getChatGroupAddress(chatId: String) -> Observable<ServerPB_Mails_GetChatGroupAddressResponse> {
        var req = ServerPB_Mails_GetChatGroupAddressRequest()
        req.chatID = Int64(chatId) ?? 0
        return client.sendPassThroughAsyncRequest(req, serCommand: .mailGetChatGroupAddress)
    }

    func createChatGroupAddress(chatId: String) -> Observable<ServerPB_Mails_CreateChatGroupAddressResponse> {
        var req = ServerPB_Mails_CreateChatGroupAddressRequest()
        req.chatID = Int64(chatId) ?? 0
        return client.sendPassThroughAsyncRequest(req, serCommand: .mailCreateChatGroupAddress)
    }

    func exportChatMemebers(chatId: String) -> Observable<Void> {
        var req = RustPB.Im_V1_ExportChatChatterBitableRequest()
        req.chatID = Int64(chatId) ?? 0
        return client.sendAsyncRequest(req).subscribeOn(scheduler)
    }
}

private extension RustChatAPI {
    class func loadLocalChats(_ ids: [String], client: SDKRustService) throws -> [String: LarkModel.Chat] {
        let chatIds = ids.filter { !$0.isEmpty }
        guard !chatIds.isEmpty else {
            return [:]
        }
        var request = RustPB.Im_V1_MGetChatsRequest()
        request.chatIds = chatIds
        request.shouldAuth = false
        let res: Im_V1_MGetChatsResponse = try client.sendSyncRequest(request, allowOnMainThread: true).response
        return RustAggregatorTransformer.transformToChatsMap(
            fromEntity: res.entity,
            chatOptionInfos: res.chatOptionInfo
        )
    }

    class func fetchChats(by ids: [String], forceRemote: Bool, client: SDKRustService) -> Observable<FetchChatsResult> {
        let chatIds = ids.filter { !$0.isEmpty }
        guard !chatIds.isEmpty else {
            return Observable.just(FetchChatsResult())
        }
        var request = RustPB.Im_V1_MGetChatsRequest()
        request.chatIds = chatIds
        request.strategy = forceRemote ? .forceServer : .tryLocal
        return client.sendAsyncRequest(request) { (res: RustPB.Im_V1_MGetChatsResponse) -> FetchChatsResult in
            return RustAggregatorTransformer.transformToChatsMap(
                fromEntity: res.entity,
                chatOptionInfos: res.chatOptionInfo
            )
        }
    }

    class func readChatAnnouncement(by chatId: String, updateTime: Int64, client: SDKRustService) -> Observable<Void> {
        var request = RustPB.Im_V1_ReadChatAnnouncementRequest()
        request.chatID = chatId
        request.announceTime = updateTime
        return client.sendAsyncRequest(request)
    }

    // swiftlint:disable function_parameter_count
    class func createChat(
        type: LarkModel.Chat.TypeEnum,
        chatterIds: [String],
        groupName: String,
        groupDesc: String,
        fromChatID: String,
        isCrypto: Bool,
        isPrivateMode: Bool,
        initMessageIds: [String],
        messageId2Permissions: [String: RustPB.Im_V1_CreateChatRequest.DocPermissions],
        isPublic: Bool,
        chatMode: LarkModel.Chat.ChatMode,
        client: SDKRustService,
        currentChatterId: String,
        createChatSource: CreateChatSource?,
        linkPageURL: String?,
        pickEntities: [Basic_V1_PickEntities]
    ) -> Observable<CreateChatResult> {
        // swiftlint:enable function_parameter_count
        var request = RustPB.Im_V1_CreateChatRequest()
        request.type = RustPB.Basic_V1_Chat.TypeEnum(rawValue: Int(type.rawValue)) ?? .p2P
        request.chatterIds = chatterIds
        request.groupName = groupName
        request.groupDesc = groupDesc
        request.isPublic = false
        request.fromChatID = fromChatID
        request.isCrypto = isCrypto
        request.isPrivateMode = isPrivateMode
        request.initMessageIds = initMessageIds
        request.messageDocPermissions = messageId2Permissions
        request.chatMode = chatMode
        request.isPublicV2 = isPublic
        request.pickEntities = pickEntities
        if let linkPageURL = linkPageURL {
            var chatPageContext = Im_V1_ChatPageContext()
            chatPageContext.targetURL = linkPageURL
            request.toLinkPages = [chatPageContext]
            request.source = .toLinkPage
        }
        if let createChatSource = createChatSource {
            request.createP2PChatSource = createChatSource.transform()
        }

        return client.sendAsyncRequest(request) { (res: RustPB.Im_V1_CreateChatResponse) -> CreateChatResult in
            if let chat = RustAggregatorTransformer.transformToChatsMap(fromEntity: res.entity)[res.chatID] {
                return CreateChatResult(chat: chat, pageLinkResult: res.hasPageLinkResult ? res.pageLinkResult : nil)
            } else {
                throw APIError(type: .entityIncompleteData(message: "CreateChatResponse has no chat"))
            }
        }
    }

    class func checkPublicChatName(chatName: String, client: SDKRustService) -> Observable<Bool> {
        var request = RustPB.Im_V1_CheckPublicChatNameIsExistRequest()
        request.chatName = chatName

        return client.sendAsyncRequest(request) { (res: RustPB.Im_V1_CheckPublicChatNameIsExistResponse) -> Bool in
            return res.isExist
        }
    }

    class func createP2PChats(chatterIds: [String], client: SDKRustService) -> Observable<[LarkModel.Chat]> {
        var request = RustPB.Im_V1_CreateP2PChatsRequest()
        request.chatterIds = chatterIds
        return client.sendAsyncRequest(request) { (res: RustPB.Im_V1_CreateP2PChatsResponse) -> [LarkModel.Chat] in
            res.entity.chats.values.map { (chat) -> LarkModel.Chat in
                LarkModel.Chat.transform(pb: chat)
            }
        }
    }

    class func joinChat(joinToken: String, messageId: String, client: SDKRustService) -> Observable<LarkModel.Chat> {
        var request = RustPB.Im_V1_AddChatChattersRequest()
        request.type = .share
        request.joinToken = joinToken
        request.messageID = messageId
        return client.sendAsyncRequest(request) { (res: RustPB.Im_V1_AddChatChattersResponse) -> LarkModel.Chat in
            if let chat = res.entity.chats[res.chatID] {
                return LarkModel.Chat.transform(pb: chat)
            } else {
                throw APIError(type: .entityIncompleteData(message: "AddChatChattersResponse has no chat"))
            }
        }
    }

    class func updateChat(request: RustPB.Im_V1_UpdateChatRequest,
                          security: Bool = false,
                          client: SDKRustService) -> Observable<LarkModel.Chat> {
        if security {
            return client.sendAsyncSecurityRequest(request) { (res: RustPB.Im_V1_UpdateChatResponse) -> LarkModel.Chat in
                if let chat = res.entity.chats.first?.value {
                    return LarkModel.Chat.transform(pb: chat)
                } else {
                    throw APIError(type: .entityIncompleteData(message: "UpdateChatResponse has no chat"))
                }
            }
        } else {
            return client.sendAsyncRequest(request) { (res: RustPB.Im_V1_UpdateChatResponse) -> LarkModel.Chat in
                if let chat = res.entity.chats.first?.value {
                    return LarkModel.Chat.transform(pb: chat)
                } else {
                    throw APIError(type: .entityIncompleteData(message: "UpdateChatResponse has no chat"))
                }
            }
        }
    }
}
