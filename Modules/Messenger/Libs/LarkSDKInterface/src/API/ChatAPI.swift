//
//  ChatAPI.swift
//  LarkSDKInterface
//
//  Created by liuwanlin on 2018/5/30.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import RxSwift
import LarkModel
import SuiteCodable
import RustPB
import ServerPB

public enum MyGroupType: Int {
    case manage = 1
    case join = 2
    case administrate = 3
}

public struct FetchMyGroupResult {
    public let chats: [Chat]
    public let nextCursor: Int
    public let hasMore: Bool

    public init(chats: [Chat], nextCursor: Int, hasMore: Bool) {
        self.chats = chats
        self.nextCursor = nextCursor
        self.hasMore = hasMore
    }
}

extension RustPB.Basic_V1_ContactSource: Codable, HasDefault {
    public static func `default`() -> RustPB.Basic_V1_ContactSource {
        return .unknownSource
    }
}

// doc：https://bytedance.larksuite.com/docs/docs1SEo8pPdkZX0cC8PRzIljXc
public struct CreateChatSource: Codable {
    public typealias CreateP2PChatSource = LarkModel.Chat.CreateP2PChatSource

    public var sourceType: RustPB.Basic_V1_ContactSource = .unknownSource
    public var sourceID: String = ""
    public var sourceName: String = ""
    public var senderIDV2: String = ""
    public var subSourceType: String = ""

    public init() {}

    public func transform() -> LarkModel.Chat.CreateP2PChatSource {
        var createP2PChatSource = CreateP2PChatSource()
        createP2PChatSource.sourceType = self.sourceType
        createP2PChatSource.sourceID = self.sourceID
        createP2PChatSource.sourceName = self.sourceName
        createP2PChatSource.senderIDV2 = self.senderIDV2
        createP2PChatSource.subSourceType = self.subSourceType

        return createP2PChatSource
    }
}

public struct CreateGroupParam {
    public let type: Chat.TypeEnum

    public var name: String = ""
    public var desc: String = ""
    public var fromChatId: String = ""
    public var messageIds: [String] = []
    public var messageId2Permissions: [String: RustPB.Im_V1_CreateChatRequest.DocPermissions] = [:]
    public var isPublic: Bool = false
    public var chatMode: LarkModel.Chat.ChatMode = .default
    public var chatterIds: [String] = []
    public var isCrypto: Bool = false
    public var isPrivateMode: Bool = false
    public var createChatSource: CreateChatSource?
    public var linkPageURL: String?
    public var pickEntities: [Basic_V1_PickEntities] = []

    public init(type: Chat.TypeEnum) {
        self.type = type
    }
}

public struct CreateChatResult {
    public let chat: Chat
    public let pageLinkResult: Im_V1_CreateChatResponse.ChatPageLinkResult?

    public init(chat: Chat, pageLinkResult: Im_V1_CreateChatResponse.ChatPageLinkResult?) {
        self.chat = chat
        self.pageLinkResult = pageLinkResult
    }
}

public struct FetchChatResourcesResult {
    public let messageMetas: [RustPB.Media_V1_GetChatResourcesResponse.MessageMeta]
    public let hasMoreBefore: Bool
    public let hasMoreAfter: Bool

    public init(messageMetas: [RustPB.Media_V1_GetChatResourcesResponse.MessageMeta], hasMoreBefore: Bool, hasMoreAfter: Bool) {
        self.messageMetas = messageMetas
        self.hasMoreBefore = hasMoreBefore
        self.hasMoreAfter = hasMoreAfter
    }
}

public enum ExpiredDay {
    case fixed(time: Int32) // 固定时间有效期
    case forever // 永久有效
}

public protocol ChatAPI {
    func getLocalChat(by id: String) -> Chat?

    func fetchChat(by id: String, forceRemote: Bool) -> Observable<Chat?>

    func getLocalChats(_ ids: [String]) throws -> [String: Chat]

    func fetchLocalChats(_ ids: [String]) -> Observable<[String: Chat]>

    /// fetch chats by chatIDs
    /// - Parameter ids: [String] chatIDs
    /// - Parameter forceRemote: Bool. true: fetch chat by network. false: first get chat from local. if no data fetch chat by network
    func fetchChats(by ids: [String], forceRemote: Bool) -> Observable<[String: Chat]>

    /// 群公告标记已读
    ///
    /// - Parameter chatID: String
    /// - Parameter updateTime: Int64 Chat.AnounceMent.updateTime
    /// - Returns: Observable<Void>
    func readChatAnnouncement(by chatID: String, updateTime: Int64) -> Observable<Void>

    func createChat(param: CreateGroupParam) -> Observable<CreateChatResult>

    func createFaceToFaceApplication(latitude: String, longitude: String, matchCode: Int32) -> Observable<RustPB.Im_V1_CreateFaceToFaceApplicationResponse>

    func joinFaceToFaceChat(token: String) -> Observable<(Chat, Bool)>

    func checkPublicChatName(chatName: String) -> Observable<Bool>

    func createDepartmentChat(departmentId: String) -> Observable<Chat>

    func createP2pChats(uids: [String]) -> Observable<[Chat]>

    func getLocalP2PChat(by uid: String) -> Chat?

    func fetchLocalP2PChat(by uid: String) -> Observable<Chat?>

    func getLocalP2PChatsByUserIds(uids: [String]) throws -> [String: Chat]

    func fetchLocalP2PChatsByUserIds(uids: [String]) -> Observable<[String: Chat]>

    func joinChat(joinToken: String, messageId: String) -> Observable<Chat>

    func addChatters(chatId: String, chatterIds: [String], chatIds: [String], departmentIds: [String]) -> Observable<Void>

    func addChatters(chatId: String, chatterIds: [String], chatIds: [String], departmentIds: [String], isMentionInvitation: Bool) -> Observable<Void>

    // 扫描群二维码加群
    func addChatter(to chatId: String, inviterId: String, token: String) -> Observable<Void>

    // 团队公开群申请入群
    func addChatters(teamId: Int64, chatId: String, chatterIds: [String]) -> Observable<Void>

    /// 通过关联页面入群
    func addChatters(chatId: String, chatterIds: [String], linkPageURL: String) -> Observable<Void>

    // join group by chat link
    func addChatterByLink(with token: String) -> Observable<Void>

    func deleteChatters(chatId: String, chatterIds: [String], newOwnerId: String?) -> Observable<Void>

    // 撤回群加人
    func withdrawAddChatters(chatId: String, chatterIds: [String], chatIds: [String], departmentIds: [String]) -> Observable<Void>

    func updateChat(chatId: String, name: String) -> Observable<Chat>

    func updateChat(chatId: String, description: String) -> Observable<Chat>

    func updateChat(chatId: String, isRemind: Bool) -> Observable<Chat>

    func updateChat(chatId: String, announcement: String) -> Observable<Chat>

    func updateChat(chatId: String, iconData: Data, avatarMeta: RustPB.Basic_V1_AvatarMeta?) -> Observable<Chat>

    func updateChat(chatId: String, avatarMeta: RustPB.Basic_V1_AvatarMeta?) -> Observable<Chat>

    func updateChat(chatId: String, offEditInfo: Bool) -> Observable<Chat>

    func updateChat(chatId: String, addMemberPermission: Chat.AddMemberPermission.Enum) -> Observable<Chat>

    func updateChat(chatId: String,
                    addMemberPermission: LarkModel.Chat.AddMemberPermission.Enum,
                    shareCardPermission: LarkModel.Chat.ShareCardPermission.Enum) -> Observable<LarkModel.Chat>

    func updateChat(chatId: String, shareCardPermission: Chat.ShareCardPermission.Enum) -> Observable<Chat>

    func updateChat(chatId: String, atAllPermission: Chat.AtAllPermission.Enum) -> Observable<Chat>

    func updateChat(chatId: String, allowSendMail: Bool) -> Observable<Chat>

    func updateChat(chatId: String, permissionType: Chat.MailPermissionType) -> Observable<Chat>

    func updateChat(chatId: String,
                    allowSendMail: Bool,
                    permissionType: Chat.MailPermissionType) -> Observable<Chat>

    func updateChat(chatId: String, leaveGroupNotiftType: Chat.SystemMessageVisible.Enum) -> Observable<Chat>

    func updateChat(chatId: String, joinGroupNotiftType: Chat.SystemMessageVisible.Enum) -> Observable<Chat>

    func updateChat(chatId: String, messagePosition: Chat.MessagePosition.Enum) -> Observable<Chat>

    func updateChat(chatId: String, isAutoTranslate: Bool) -> Observable<LarkModel.Chat>

    func updateChat(chatId: String, isRealTimeTranslate: Bool, realTimeTranslateLanguage: String) -> Observable<LarkModel.Chat>

    func updateChat(chatId: String, isDelayed: Bool) -> Observable<LarkModel.Chat>

    func updateChat(chatId: String, isMuteAtAll: Bool) -> Observable<LarkModel.Chat>

    func updateChat(chatId: String, burnLife: Int32) -> Observable<Chat>

    func updateChat(chatId: String, createUrgentSetting: Chat.CreateUrgentSetting) -> Observable<Chat>

    func updateChat(chatId: String, createVideoConferenceSetting: Chat.CreateVideoConferenceSetting) -> Observable<Chat>

    func updateChat(chatId: String, pinPermissionSetting: Chat.PinPermissionSetting) -> Observable<Chat>

    func updateChat(chatId: String, messageVisibilitySetting: Chat.MessageVisibilitySetting.Enum) -> Observable<LarkModel.Chat>

    func updateChat(chatId: String,
                    isPublic: Bool,
                    addMemberPermission: LarkModel.Chat.AddMemberPermission.Enum?,
                    shareCardPermission: LarkModel.Chat.ShareCardPermission.Enum?) -> Observable<LarkModel.Chat>

    func fetchChatAvatarMeta(chatId: String) -> Observable<RustPB.Basic_V1_AvatarMeta>

    func getChatLimitInfo(chatId: String) -> Observable<RustPB.Im_V1_GetChatLimitInfoResponse>

    func transferGroupOwner(chatId: String, ownerId: String) -> Observable<Chat>

    func clearChatMessages(chatId: String) -> Observable<RustPB.Im_V1_ClearChatMessagesResponse>

    func disbandGroup(chatId: String) -> Observable<Chat>

    func frozenGroup(chatId: String) -> Observable<Chat>

    //获取chat中最近的count个资源 resourceTypes传空取所有类型
    func fetchChatResources(chatId: String, count: Int32, resourceTypes: [RustPB.Media_V1_ChatResourceType]) -> Observable<FetchChatResourcesResult>

    //获取chat中以messageId为基准的count个资源 resourceTypes传空取所有类型
    func fetchChatResources(
        chatId: String,
        fromMessageId: String,
        count: Int32,
        direction: RustPB.Media_V1_GetChatResourcesRequest.Direction,
        resourceTypes: [RustPB.Media_V1_ChatResourceType]
    ) -> Observable<FetchChatResourcesResult>

    /// 获取群二维码 token
    func getChatQRCodeToken(chatId: String, expiredDay: ExpiredDay) -> Observable<RustPB.Im_V1_GetChatQRCodeTokenResponse>

    /// 通过群二维码Token获取ChatInfo
    func getChatQRCodeInfo(token: String) -> Observable<ChatQRCodeInfo>

    /// 获取群链接
    func getChatShareLink(chatId: String, expiredDay: ExpiredDay, appName: String) -> Observable<RustPB.Im_V1_GetChatLinkTokenResponse>

    /// 通过群 ViaLink Info
    func getChatViaLinkInfo(token: String) -> Observable<ChatLinkInfo>

    // 获取chat中可以发言的ChatterID
    func fetchChatPostChatterIds(chatId: String) -> Observable<([String], [String: Chatter])>

    // 更新群成员发言权限
    func updateChatPostChatters(chatId: String, postType: Chat.PostType, addChatterIds: [String], removeChatterIds: [String]) -> Observable<Void>

    //同步订阅(取消订阅)会话
    func subscribeChatEvent(chatIds: [String], subscribe: Bool)

    //异步订阅(取消订阅)会话
    func asyncSubscribeChatEvent(chatIds: [String], subscribe: Bool)

    // 入群申请
    func updateChat(chatId: String, applyType: Chat.AddMemberApply.Enum) -> Observable<Void>

    func getDynamicRule(chatId: String) -> Observable<ServerPB_Chats_PullChatRefDynamicRuleResponse>

    func getDynamicRuleOptionSettings(chatId: String) -> Observable<ServerPB_Chats_PullDynamicRuleOptionsByFieldResponse>

    func clearOrderedChatChatters(chatId: String, uid: String) -> Observable<Void>

    func createAddChatChatterApply(chatId: String,
                                   way: RustPB.Basic_V1_AddChatChatterApply.Ways,
                                   chatterIds: [String],
                                   reason: String?,
                                   inviterId: String?,
                                   joinToken: String?) -> Observable<Void>

    func createAddChatChatterApply(chatId: String,
                                   way: RustPB.Basic_V1_AddChatChatterApply.Ways,
                                   chatterIds: [String],
                                   reason: String?,
                                   inviterId: String?,
                                   joinToken: String?,
                                   teamId: Int64?,
                                   eventID: String?,
                                   linkPageURL: String?) -> Observable<Void>

    func getAddChatChatterApply(chatId: String, cursor: String?) -> Observable<RustPB.Im_V1_GetAddChatChatterApplyResponse>

    func updateAddChatChatterApply(chatId: String, showBanner: Bool) -> Observable<Void>

    func updateAddChatChatterApply(chatId: String, inviteeId: String, status: RustPB.Basic_V1_AddChatChatterApply.Status) -> Observable<Void>

    // 存储 last draft id
    func updateLastDraft(chatId: String, draftId: String) -> Observable<Void>

    /// 用户截屏时调用
    ///
    /// - Parameter chatId: 当前chat id
    /// - Returns: Observable<Void>
    func userTakeScreenshot(chatId: String) -> Observable<Void>

    func setChatLastRead(chatId: String, messagePosition: Int32, offsetInScreen: CGFloat) -> Observable<Void>

    //停用加人二维码或加人群名片 messageId: 拉人产生的系统消息的id
    func disableChatShared(messageId: String) -> Observable<Void>

    //判断chatter是否在群里，返回在群里的chatterIds
    func checkChattersInChat(chatterIds: [String], chatId: String) -> Observable<[String]>

    // 撤回时判断实体包含的人/群/部门是否全部不在群中，仅用在撤回中
    func checkChattersChatsDepartmentsInChat(chatterIds: [String], chatIds: [String], departmentIds: [String], chatId: String) -> Observable<[String: Bool]>

    /// 获取群分享历史
    func getGroupShareHistory(chatID: String, cursor: String?, count: Int32?) -> Observable<RustPB.Im_V1_PullChatShareHistoryResponse>
    /// 更新群分享历史状态
    func updateGroupShareHistory(tokens: [String], status: RustPB.Basic_V1_ChatShareInfo.ShareStatus) -> Observable<Void>

    /// 获取 SOS 紧急电话
    func getEmergencyCallNumber(callerPhoneNumber: String, calleeUserId: String) -> Observable<RustPB.Contact_V1_GetEmergencyCallNumberResponse>
    /// 提交紧急电话拨打缘由
    func setEmergencyCallReason(callId: String, reason: String) -> Observable<RustPB.Contact_V1_SetEmergencyCallReasonResponse>

    /// load group memebers join and leave history
    /// 加载群成员进退群历史
    func getChatJoinLeaveHistory(
        chatID: String,
        cursor: String?,
        count: Int32?
    ) -> Observable<RustPB.Im_V1_GetChatJoinLeaveHistoryResponse>

    /// 进入chat通知
    func enterChat(chatId: String) -> Observable<Void>
    /// 离开chat通知
    func exitChat(chatId: String) -> Observable<Void>

    func getKickInfo(chatId: String) -> Observable<String>

    func batchPutP2PChatMessage(toUserIds: [String], content: RustPB.Basic_V1_Content, type: RustPB.Basic_V1_Message.TypeEnum) -> Observable<RustPB.Im_V1_BatchPutP2PChatMessageResponse>

    func fetchChatAdminUsers(chatId: String, isFromServer: Bool) -> Observable<[Chatter]>

    func fetchChatAdminUsersWithLocalAndServer(chatId: String) -> Observable<[Chatter]>

    func patchChatAdminUsers(chatId: String,
                             toAddUserIds: [String],
                             toDeleteUserIds: [String]) -> Observable<Void>

    func fetchChatLinkedPages(chatID: Int64, isFromServer: Bool) -> Observable<RustPB.Im_V1_GetChatLinkedPagesResponse>

    func deleteChatLinkedPages(chatID: Int64, pageURLs: [String]) -> Observable<RustPB.Im_V1_DeleteChatLinkedPagesResponse>

    func getChatMenuItems(chatId: Int64) -> Observable<RustPB.Im_V1_GetChatMenuItemsResponse>

    func getChatWidgets(chatId: Int64) -> Observable<RustPB.Im_V1_GetChatWidgetsResponse>

    func deleteChatWidgets(chatId: Int64, widgetIds: [Int64]) -> Observable<RustPB.Im_V1_DeleteChatWidgetsResponse>

    func reorderChatWidgets(chatId: Int64, widgetIds: [Int64]) -> Observable<RustPB.Im_V1_ReorderChatWidgetsResponse>

    func triggerChatMenuEvent(chatId: Int64, menuId: Int64) -> Observable<ServerPB.ServerPB_Chats_TriggerMenuEventResponse>

    func fetchChatTab(chatId: Int64, fromLocal: Bool) -> Observable<RustPB.Im_V1_GetChatTabsResponse>

    func getChatPin(chatId: Int64, count: Int32, needPreview: Bool) -> Observable<RustPB.Im_V1_GetUniversalChatPinsResponse>

    func fetchChatPin(chatId: Int64, count: Int32, pageToken: String?, needPreview: Bool, getTopPins: Bool) -> Observable<RustPB.Im_V1_GetUniversalChatPinsResponse>

    func deleteChatPin(chatId: Int64, pinId: Int64) -> Observable<RustPB.Im_V1_DeleteUniversalChatPinResponse>

    func reorderChatPin(
        chatID: Int64,
        pinID: Int64,
        prevPinID: Int64?,
        clientPinIDs: [Int64],
        reorderType: RustPB.Im_V1_ReorderChatPinRequest.ReorderType,
        clientLogInfo: String
    ) -> Observable<RustPB.Im_V1_ReorderChatPinResponse>

    func getChatPinInfo(chatID: Int64) -> Observable<Im_V1_GetChatPinInfoResponse>

    func createMessageChatPin(messageID: Int64, chatID: Int64) -> Observable<Void>

    func updateURLChatPinTitle(chatId: Int64, pinId: Int64, title: String) -> Observable<RustPB.Im_V1_UpdateUrlChatPinResponse>

    func notifyCreateUrlChatPinPreview(chatId: Int64, url: String, deleteToken: String) -> Observable<RustPB.Im_V1_NotifyCreateUrlChatPinPreviewResponse>

    func deleteUrlChatPinPreview(chatId: Int64, deleteToken: String) -> Observable<RustPB.Im_V1_DeleteUrlChatPinPreviewResponse>

    func createUrlChatPin(chatId: Int64, params: [(RustPB.Im_V1_UrlChatPinPreviewInfo, Bool)], deleteToken: String) -> Observable<RustPB.Im_V1_CreateUrlChatPinResponse>

    func createAnnouncementChatPin(chatId: Int64) -> Observable<RustPB.Im_V1_CreateAnnouncementChatPinResponse>

    func stickAnnouncementChatPin(chatID: Int64) -> Observable<RustPB.Im_V1_StickChatPinToTopResponse>

    func stickChatPinToTop(chatID: Int64, pinID: Int64, stick: Bool) -> Observable<RustPB.Im_V1_StickChatPinToTopResponse>

    func addChatTab(chatId: Int64, name: String, type: RustPB.Im_V1_ChatTab.TypeEnum, jsonPayload: String?) -> Observable<RustPB.Im_V1_AddChatTabResponse>

    func deleteChatTab(chatId: Int64, tabId: Int64) -> Observable<RustPB.Im_V1_DeleteChatTabResponse>

    func updateChatTabsOrder(chatId: Int64, reorderTabIds: [Int64]) -> Observable<RustPB.Im_V1_UpdateChatTabOrdersResponse>

    func updateChatTabDetail(chatId: Int64, tab: RustPB.Im_V1_ChatTab) -> Observable<RustPB.Im_V1_UpdateChatTabResponse>

    // MARK: - 消息置顶相关
    /// 获取置顶通知内容
    func getChatTopNoticeWithChatId(_ chatId: Int64) -> Observable<RustPB.Im_V1_GetChatTopNoticeResponse>

    /// 替换置顶消息& 删除 & 关闭置顶消息
    func patchChatTopNoticeWithChatID(_ chatId: Int64,
                                      type: RustPB.Im_V1_PatchChatTopNoticeRequest.ActionType,
                                      senderId: Int64?,
                                      messageId: Int64?) -> Observable<RustPB.Im_V1_PatchChatTopNoticeResponse>

    /// 更新置顶的权限
    func updateChat(chatId: String, topNoticePermissionType: RustPB.Basic_V1_Chat.TopNoticePermissionSetting.Enum) -> Observable<LarkModel.Chat>

    /// 更新群 tab 管理权限
    func updateChat(chatId: String, chatTabPermissionSetting: LarkModel.Chat.ChatTabPermissionSetting) -> Observable<LarkModel.Chat>

    func updateChat(chatId: String, chatPinPermissionSetting: LarkModel.Chat.ChatPinPermissionSetting) -> Observable<LarkModel.Chat>

    func getChatSwitchWithLocalAndServer(chatId: String,
                                         actionType: Im_V1_ChatSwitchRequest.ActionType) -> Observable<Bool?>

    /// 更新群主题
    func updateChatTheme(chatId: String,
                         themeId: Int64?,
                         theme: Data,
                         isReset: Bool,
                         scope: Im_V2_ChatThemeType) -> Observable<RustPB.Im_V2_SetChatThemeResponse>

    func fetchChatThemeListRequest(chatID: String,
                                   themeType: Im_V2_ChatThemeType,
                                   limit: Int64?,
                                   pos: Int64?) -> Observable<RustPB.Im_V2_GetChatThemeListResponse>

    func pullChatMemberSetting(tenantId: Int64, chatId: Int64?) -> Observable<ServerPB.ServerPB_Chats_PullChatMemberSettingResponse>

    func putChatMemberSuppRoleApproval(chatId: Int64, applyUpperLimit: Int32, applyTypeKey: String?, description: String) -> Observable<ServerPB.ServerPB_Misc_PutChatMemberSuppRoleApprovalResponse>

    func pullChatMemberSuppRoleApprovalSetting(tenantId: Int64, applyUpperLimit: Int32?) -> Observable<ServerPB.ServerPB_Misc_PullChatMemberSuppRoleApprovalSettingResponse>

    // 拉取群上限审批人ids
    func pullChatMemberSuppRoleApprovalChatterIds(tenantId: Int64, applyTypeKey: String?, applyUpperLimit: Int32?) -> Observable<[Int64]>

    func pullChangeGroupMemberAuthorization(pickEntities: [ServerPB_Chats_PickEntities],
                                            chatMode: ServerPB_Entities_Chat.ChatMode?,
                                            fromChatId: Int64?) -> Observable<ServerPB.ServerPB_Chats_PullChangeGroupMemberAuthorizationResponse>

    func updateChat(chatId: String, expandWidgets: Bool) -> Observable<Chat>

    // 从服务端获取群举报页面的链接
    func getChatReportLink(chatId: String, language: String) -> Observable<ServerPB.ServerPB_Messages_GenLarkReportUrlResponse>

    //告诉服务端可能要发送“星标联系人”引导的系统消息（服务端还会做一些条件的校验）
    func specialFocusGuidance(targetUserID: Int64) -> Observable<ServerPB_Chatters_SpecialFocusGuidanceResponse>

    // 更新会话隐藏群人数设置
    func updateChat(chatID: String, userCountVisibleSetting: Basic_V1_Chat.UserCountVisibleSetting.Enum) -> Observable<Chat>

    // 更新会话防泄密设置
    func updateChat(chatId: String, restrictedModeSetting: Chat.RestrictedModeSetting) -> Observable<Chat>

    func getChatSwitch(chatId: String, actionTypes: [Im_V1_ChatSwitchRequest.ActionType], formServer: Bool) -> Observable<[Int: Bool]>

    func updateChat(chatId: String, displayModeInThread: Bool) -> Observable<Chat>

    // 部门群退出鉴权
    func exitDepartmentGroupAuthorization(chatId: String) -> Observable<Void>

    // 获取群邮箱地址
    func getChatGroupAddress(chatId: String) -> Observable<ServerPB_Mails_GetChatGroupAddressResponse>

    // 生成群邮箱地址
    func createChatGroupAddress(chatId: String) -> Observable<ServerPB_Mails_CreateChatGroupAddressResponse>

    // 导出群成员
    func exportChatMemebers(chatId: String) -> Observable<Void>
}

public typealias ChatAPIProvider = () -> ChatAPI

// Chat Group QR Code
public struct ChatQRCodeInfo {
    public private(set) var alreadyInChat: Bool
    public private(set) var chatID: String
    public private(set) var chat: Chat
    public private(set) var inviterID: String

    public private(set) var isInviterCanAddMember: Bool
    public private(set) var showMsg: String
    public private(set) var inviterURL: String

    public init?(with pb: Im_V1_GetChatQRCodeInfoResponse) {
        guard let chat = pb.entity.chats[pb.chatID] else { return nil }

        self.alreadyInChat = pb.alreadyInChat
        self.chatID = pb.chatID
        self.chat = Chat.transform(pb: chat)
        self.inviterID = pb.inviterID
        self.isInviterCanAddMember = pb.isInviterCanAddMember
        self.showMsg = pb.showMsg
        self.inviterURL = pb.inviterURL
    }
}

// ChatLink
public struct ChatLinkInfo {
    public private(set) var alreadyInChat: Bool
    public private(set) var chatID: String
    public private(set) var chat: Chat
    public private(set) var ownerChatterID: String
    public private(set) var inviterChatterID: String
    public private(set) var isInviterCanInviteMember: Bool
    public private(set) var expireTime: String

    public init?(with pb: Im_V1_GetChatLinkInfoResponse) {
        guard let chat = pb.entity.chats[pb.chatID] else { return nil }

        self.alreadyInChat = pb.alreadyInChat
        self.chatID = pb.chatID
        self.chat = Chat.transform(pb: chat)
        self.ownerChatterID = pb.ownerChatterID
        self.inviterChatterID = pb.inviterChatterID
        self.isInviterCanInviteMember = pb.isInviterCanInviteMember
        self.expireTime = pb.expireTime
    }
}
