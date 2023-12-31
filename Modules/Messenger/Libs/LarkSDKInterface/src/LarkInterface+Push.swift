//
//  LarkSDKInterface+Push.swift
//  LarkSDKInterface
//
//  Created by liuwanlin on 2018/4/24.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import LarkModel
import LarkContainer
import RustPB
import Foundation

public typealias ChatTimeTipStatus = RustPB.Im_V1_PushChatTimeTipNotify.TimeTipStatus
public typealias ExternalDisplayTimezoneSettingType = RustPB.Basic_V1_ExternalDisplayTimezoneSettingType
public typealias MessageReadStates = RustPB.Im_V1_PushMessageReadStates

/// MyAI会话轮次信息
public struct AIRoundInfo {
    public static let `default` = AIRoundInfo(chatId: 0, aiChatModeId: 0, roundId: 0, roundIdPosition: Int64.min, status: .unknown, roundLastPosition: Int64.min, updateTime: 0)

    public enum Status: Int {
        case unknown = 0
        /// 回复中
        case responding = 1
        /// 回复完成
        case done = 2
        /// 打断
        case interrupt = 3
        /// 流式异常，超时
        case roundError = 4

        public static func from(rustStatus: Im_V1_AIRoundInfo.Status) -> AIRoundInfo.Status {
            return Status(rawValue: rustStatus.rawValue) ?? .unknown
        }

        /// 一轮消息结束后，done \ interrupt \ roundError 三种状态都被认为已完成
        public var isFinished: Bool {
            switch self {
            case .interrupt, .roundError, .done:
                return true
            default:
                return false
            }
        }
    }
    /// chatId/aiChatModeId类型和AIChatInitRequest返回的一致
    public let chatId: Int64
    public let aiChatModeId: Int64
    public let roundId: Int64
    public let roundIdPosition: Int64
    public let status: AIRoundInfo.Status
    public let roundLastPosition: Int64
    public let updateTime: Int64
    public let sessionID: String?

    public init(chatId: Int64, aiChatModeId: Int64, roundId: Int64, roundIdPosition: Int64, status: AIRoundInfo.Status, roundLastPosition: Int64, updateTime: Int64, sessionID: String? = nil) {
        self.chatId = chatId
        self.aiChatModeId = aiChatModeId
        self.roundId = roundId
        self.roundIdPosition = roundIdPosition
        self.status = status
        self.roundLastPosition = roundLastPosition
        self.updateTime = updateTime
        self.sessionID = sessionID
    }

    public static func from(rustPB: Im_V1_AIRoundInfo) -> AIRoundInfo {
        return AIRoundInfo(
            chatId: rustPB.chatID,
            aiChatModeId: rustPB.aiChatModeID,
            roundId: rustPB.roundID,
            roundIdPosition: Int64(rustPB.roundIDPosition),
            status: AIRoundInfo.Status.from(rustStatus: rustPB.status),
            roundLastPosition: Int64(rustPB.roundLastPosition),
            updateTime: rustPB.updateTime,
            sessionID: rustPB.hasSessionID ? rustPB.sessionID : nil
        )
    }
}
public struct PushAIRoundInfo: PushMessage {
    public let aiRoundInfos: [AIRoundInfo]

    public init(aiRoundInfos: [AIRoundInfo]) {
        self.aiRoundInfos = aiRoundInfos
    }
}

public struct AISessionInfo {
    public static let `default` = AISessionInfo(lastNewTopicSystemMsgPosition: Int64.max, toolIds: [], sessionFirstMessageID: 0)
    public let lastNewTopicSystemMsgPosition: Int64
    public var toolIds: [String]
    /// 当前session下第一条消息的ID
    public var sessionFirstMessageID: Int64

    public init(lastNewTopicSystemMsgPosition: Int64,
                toolIds: [String],
                sessionFirstMessageID: Int64) {
        self.lastNewTopicSystemMsgPosition = lastNewTopicSystemMsgPosition
        self.toolIds = toolIds
        self.sessionFirstMessageID = sessionFirstMessageID
    }
    public static func from(rustPB: Im_V1_AISessionInfo) -> AISessionInfo {
        return AISessionInfo(lastNewTopicSystemMsgPosition: rustPB.lastNewTopicSystemMsgPosition,
                             toolIds: rustPB.toolIds,
                             sessionFirstMessageID: rustPB.sessionFirstMessageID)
    }
}

public struct AIExtensionConfig {
    public static let `default` = AIExtensionConfig(maxNum: 1)
    public var maxNum: Int
    public init(maxNum: Int) {
        self.maxNum = maxNum
    }
    public static func from(mode: Basic_V1_ExtensionMode) -> AIExtensionConfig {
        return AIExtensionConfig(maxNum: mode == .single ? 1 : 0)
    }
}

// 新消息
public struct PushChannelMessage: PushMessage {
    public let message: Message

    public init(message: Message) {
        self.message = message
    }
}

public struct PushChannelMessages: PushMessage {
    public let messages: [Message]

    public init(messages: [Message]) {
        self.messages = messages
    }
}

// 消息阅读状态
public struct PushMessageReadstatus: PushMessage {
    public let channelId: String
    public let messageId: String
    public let unreadCount: Int32
    public let readCount: Int32

    public init(
        channelId: String,
        messageId: String,
        unreadCount: Int32,
        readCount: Int32
    ) {
        self.channelId = channelId
        self.messageId = messageId
        self.unreadCount = unreadCount
        self.readCount = readCount
    }
}

public struct PushChat: PushMessage {
    public let chat: Chat
    public init(chat: Chat) {
        self.chat = chat
    }
}

//链接重连后push断线期间变更的chats
public struct PushOfflineChats: PushMessage {
    public let chats: [Chat]
    public init(chats: [Chat]) {
        self.chats = chats
    }
}

/// 群成员发生变化
public struct PushChatMemberChange: PushMessage {
    public var chatId: String
    public init(chatId: String) {
        self.chatId = chatId
    }
}

//链接重连后push断线期间变更的threads
public struct PushOfflineThreads: PushMessage {
    public let threads: [RustPB.Basic_V1_Thread]
    public init(threads: [RustPB.Basic_V1_Thread]) {
        self.threads = threads
    }
}

extension RustPB.Settings_V1_PushUserSetting: PushMessage {}

public struct PushDynamicNetStatus: PushMessage {
    public let dynamicNetStatus: RustPB.Basic_V1_DynamicNetStatusResponse.NetStatus

    public init(dynamicNetStatus: RustPB.Basic_V1_DynamicNetStatusResponse.NetStatus) {
        self.dynamicNetStatus = dynamicNetStatus
    }
}

// 加急
public struct PushUrgent: PushMessage {
    public let urgentInfo: UrgentInfo

    public init(urgentInfo: UrgentInfo) {
        self.urgentInfo = urgentInfo
    }
}

// 加急失败
public struct PushUrgentFail: PushMessage {
    public let urgentFailInfo: UrgentFailInfo

    public init(urgentFailInfo: UrgentFailInfo) {
        self.urgentFailInfo = urgentFailInfo
    }
}

// 加急确认
public struct PushUrgentAck: PushMessage {
    public let messageId: String
    public let ackId: String

    public init(messageId: String, ackId: String) {
        self.messageId = messageId
        self.ackId = ackId
    }
}

// 加急已读状态
public struct PushUrgentStatus: PushMessage {
    public let channelId: String
    public let messageId: String
    public let confirmedChatterIds: [String]
    public let unconfirmedChatterIds: [String]

    public init(
        channelId: String,
        messageId: String,
        confirmedChatterIds: [String],
        unconfirmedChatterIds: [String]
    ) {
        self.channelId = channelId
        self.messageId = messageId
        self.confirmedChatterIds = confirmedChatterIds
        self.unconfirmedChatterIds = unconfirmedChatterIds
    }
}

// stickers
public struct PushStickers: PushMessage {
    public var stickers: [RustPB.Im_V1_Sticker]
    public var updateTime: Int64
    public var operation: RustPB.Im_V1_PushCustomizedStickersRequest.Operation
    public var addDirection: RustPB.Im_V1_PushCustomizedStickersRequest.AddDirection

    public init(operation: RustPB.Im_V1_PushCustomizedStickersRequest.Operation,
                addDirection: RustPB.Im_V1_PushCustomizedStickersRequest.AddDirection,
                stickers: [RustPB.Im_V1_Sticker],
                updateTime: Int64) {
        self.operation = operation
        self.addDirection = addDirection
        self.stickers = stickers
        self.updateTime = updateTime
    }
}

// sticker sets
public struct PushStickerSets: PushMessage {
    public var stickerSets: [RustPB.Im_V1_StickerSet]
    public var updateTime: Int64
    public var operation: RustPB.Im_V1_PushStickerSetsRequest.Operation

    public init(operation: RustPB.Im_V1_PushStickerSetsRequest.Operation,
                stickerSets: [RustPB.Im_V1_StickerSet],
                updateTime: Int64) {
        self.operation = operation
        self.stickerSets = stickerSets
        self.updateTime = updateTime
    }
}

// appConfig
public struct PushAppConfig: PushMessage {
    public let appConfig: RustPB.Basic_V1_AppConfig

    public init(appConfig: RustPB.Basic_V1_AppConfig) {
        self.appConfig = appConfig
    }
}

// chatters
public struct PushChatters: PushMessage {
    public let chatters: [Chatter]

    public init(chatters: [Chatter]) {
        self.chatters = chatters
    }
}

// chat timezone
public struct PushChatTimeTipNotify: PushMessage {
    public let chatId: String
    @available(*, deprecated, message: "will deleted")
    public let copyWriting: String
    public let chatTimezone: String
    public let myTimezone: String
    public let myTimezoneType: ExternalDisplayTimezoneSettingType
    public let status: ChatTimeTipStatus

    public init(chatId: String,
                copyWriting: String,
                chatTimezone: String,
                myTimezone: String,
                myTimezoneType: ExternalDisplayTimezoneSettingType,
                status: ChatTimeTipStatus) {
        self.chatId = chatId
        self.chatTimezone = chatTimezone
        self.myTimezone = myTimezone
        self.myTimezoneType = myTimezoneType
        self.copyWriting = copyWriting
        self.status = status
    }
}

// chat statusTip
public struct PushChatStatusTipNotify: PushMessage {
    public let userID: String
    public let updateStatusWithDesc: Contact_V1_ChatterCustomStatusWithStatusDesc

    public init(userID: String, updateStatusWithDesc: Contact_V1_ChatterCustomStatusWithStatusDesc) {
        self.userID = userID
        self.updateStatusWithDesc = updateStatusWithDesc
    }
}

// chat topNotice
public struct PushChatTopNotice: PushMessage {
    public let chatId: Int64
    public let info: RustPB.Im_V1_ChatTopNotice

    public init(chatId: Int64, info: RustPB.Im_V1_ChatTopNotice) {
        self.chatId = chatId
        self.info = info
    }
}

// 群 widget
public struct PushChatWidgets: PushMessage {
    public let push: RustPB.Im_V1_PushChatWidgets
    public init(push: RustPB.Im_V1_PushChatWidgets) {
        self.push = push
    }
}

// 新版群架构首屏Push
public struct PushFirstScreenUniversalChatPins: PushMessage {
    public let push: RustPB.Im_V1_PushFirstScreenUniversalChatPins
    public init(push: RustPB.Im_V1_PushFirstScreenUniversalChatPins) {
        self.push = push
    }
}

// 新版群架构增量Push
public struct PushUniversalChatPinOperation: PushMessage {
    public let push: RustPB.Im_V1_PushUniversalChatPinOperation
    public init(push: RustPB.Im_V1_PushUniversalChatPinOperation) {
        self.push = push
    }
}

// ChatPin Message列表Push
public struct PushChatPinInfo: PushMessage {
    public let push: RustPB.Im_V1_PushChatPinInfo
    public init(push: RustPB.Im_V1_PushChatPinInfo) {
        self.push = push
    }
}

// 用户添加 Pin 卡片， 客户端触发
public struct PushAddChatPinFormLocal: PushMessage {
    public let chatId: Int64
    public let response: Im_V1_CreateUrlChatPinResponse

    public init(chatId: Int64, response: Im_V1_CreateUrlChatPinResponse) {
        self.chatId = chatId
        self.response = response
    }
}

// 用户删除 Pin 卡片， 客户端触发
public struct PushDeleteChatPinFormLocal: PushMessage {
    public let chatId: Int64
    public let deleteIds: [Int64]
    public let version: Int64
    public let pinCount: Int64

    public init(chatId: Int64, deleteIds: [Int64], version: Int64, pinCount: Int64) {
        self.chatId = chatId
        self.deleteIds = deleteIds
        self.version = version
        self.pinCount = pinCount
    }
}

// 用户更新 Pin 卡片， 客户端触发
public struct PushUpdateChatPinFormLocal: PushMessage {
    public let chatId: Int64
    public let response: Im_V1_UpdateUrlChatPinResponse

    public init(chatId: Int64, response: Im_V1_UpdateUrlChatPinResponse) {
        self.chatId = chatId
        self.response = response
    }
}

// 用户 固定 or 取消固定 Pin 卡片， 客户端触发
public struct PushStickChatPinToTop: PushMessage {
    public let chatID: Int64
    public let response: Im_V1_StickChatPinToTopResponse

    public init(chatID: Int64, response: Im_V1_StickChatPinToTopResponse) {
        self.chatID = chatID
        self.response = response
    }
}

// 群空间菜单
public struct PushChatMenuItems: PushMessage {
    public let version: Int64
    public let chatId: Int64
    public let menuItems: [RustPB.Im_V1_ChatMenuItem]

    public init(version: Int64, chatId: Int64, menuItems: [RustPB.Im_V1_ChatMenuItem]) {
        self.version = version
        self.chatId = chatId
        self.menuItems = menuItems
    }
}

// chat tab
public struct PushChatTabs: PushMessage {
    public let version: Int64
    public let chatId: Int64
    public let tabs: [RustPB.Im_V1_ChatTab]

    public init(version: Int64, chatId: Int64, tabs: [RustPB.Im_V1_ChatTab]) {
        self.version = version
        self.chatId = chatId
        self.tabs = tabs
    }
}

// chat pin count
public struct PushChatPinCount: PushMessage {
    public let chatId: Int64
    public let count: Int64

    public init(chatId: Int64, count: Int64) {
        self.chatId = chatId
        self.count = count
    }
}

// message reactions change
public struct PushMessageReactions: PushMessage {
    public let chatId: String
    public let messageReactions: [String: [Reaction]]

    public init(chatId: String, messageReactions: [String: [Reaction]]) {
        self.chatId = chatId
        self.messageReactions = messageReactions
    }
}

// message feedback change
public struct PushMessageFeedbackStatus: PushMessage {
    public let chatId: String
    public var messageFeedbackStatus: [String: Basic_V1_Message.AIMessageLikeFeedbackStatus] = [:]

    public init(chatId: String, messageFeedbackStatus: [Int64: Basic_V1_Message.AIMessageLikeFeedbackStatus]) {
        self.chatId = chatId
        messageFeedbackStatus.forEach({ self.messageFeedbackStatus["\($0.0)"] = $0.1 })
    }
}

// message read/unread/meread change
public struct PushMessageReadStates: PushMessage {
    public let messageReadStates: MessageReadStates

    public init(messageReadStates: MessageReadStates) {
        self.messageReadStates = messageReadStates
    }
}

// 面对面建群 申请人
public struct PushFaceToFaceApplicants: PushMessage {
    public let applicationId: String
    public let applicants: [RustPB.Im_V1_FaceToFaceApplicant]

    public init(applicationId: String, applicants: [RustPB.Im_V1_FaceToFaceApplicant]) {
        self.applicationId = applicationId
        self.applicants = applicants
    }
}

// RustPB.Basic_V1_GetWebSocketStatusResponse.Status
public struct PushWebSocketStatus: PushMessage {
    public let status: RustPB.Basic_V1_GetWebSocketStatusResponse.Status

    public init(status: RustPB.Basic_V1_GetWebSocketStatusResponse.Status) {
        self.status = status
    }
}

// TranslateLanguageSetting
extension TranslateLanguageSetting: PushMessage {}

// Contact
public typealias PushExternalContacts = ExternalContacts
extension ExternalContacts: PushMessage {}

// New External Contact
extension PushNewExternalContacts: PushMessage {}

// SelectionContact
public typealias PushExternalContactsWithChatterIds = ExternalContactsWithChatterIds
extension ExternalContactsWithChatterIds: PushMessage {}

// NewSelectionContact
public typealias NewPushExternalContactsWithChatterIds = NewExternalContactsWithChatterIds
extension NewExternalContactsWithChatterIds: PushMessage {}

// saveSpaceStore
public struct PushSaveToSpaceStoreState: PushMessage {
    public enum SaveState: Int {
        case success = 0
        case inProgress = 1
        case failed = 2
    }

    public let messageId: String
    public let state: SaveState
    public let sourceType: Message.SourceType
    public let sourceID: String

    public init(messageId: String, state: SaveState, sourceType: Message.SourceType, sourceID: String) {
        self.messageId = messageId
        self.state = state
        self.sourceType = sourceType
        self.sourceID = sourceID
    }
}

// downloadFile
public struct PushDownloadFile: PushMessage {
    public let messageId: String
    public let key: String
    public let path: String
    public let progress: Int32
    public let rate: Int64
    public let state: RustPB.Media_V1_FileState
    public let type: RustPB.Basic_V1_File.EntityType
    public let sourceType: Message.SourceType
    public let sourceID: String
    public let isEncrypted: Bool
    public let error: Basic_V1_LarkError?

    public init(
        messageId: String,
        key: String,
        path: String,
        progress: Int32,
        state: RustPB.Media_V1_FileState,
        type: RustPB.Basic_V1_File.EntityType,
        sourceType: Message.SourceType,
        sourceID: String,
        rate: Int64,
        isEncrypted: Bool,
        error: Basic_V1_LarkError?
    ) {
        self.messageId = messageId
        self.key = key
        self.path = path
        self.progress = progress
        self.state = state
        self.type = type
        self.sourceType = sourceType
        self.sourceID = sourceID
        self.rate = rate
        self.isEncrypted = isEncrypted
        self.error = error
    }
}

// deleteMeFromChannel
public struct PushRemoveMeFromChannel: PushMessage {
    public let channelId: String
    public let isDissolved: Bool

    public init(channelId: String, isDissolved: Bool) {
        self.channelId = channelId
        self.isDissolved = isDissolved
    }
}

// fileMessageNoAuthorize
public struct PushFileUnauthorized: PushMessage {
    public let messageId: String
    public let fileDeletedStatus: Message.FileDeletedStatus

    public init(messageId: String,
                fileDeletedStatus: Message.FileDeletedStatus) {
        self.messageId = messageId
        self.fileDeletedStatus = fileDeletedStatus
    }
}

public struct PushHideChannel: PushMessage {
    public let channelId: String

    public init(channelId: String) {
        self.channelId = channelId
    }
}

// PushSelfLeaveChannel/PushSelfWillLeaveChannel/PushSelfLeaveChannelFinish
// 是为了兼容主动退出 Channel 的情况
// 主动离开 channel， 客户端触发
public enum LocalLeaveGroupStatus {
    case none
    case start
    case success
    case completed
    case error
}
public struct PushLocalLeaveGroupChannnel: PushMessage {
    public let channelId: String
    public let status: LocalLeaveGroupStatus
    public init(channelId: String, status: LocalLeaveGroupStatus) {
        self.channelId = channelId
        self.status = status
    }
}

// 用户 删除收藏， 客户端触发
public struct PushDeleteFavorites: PushMessage {
    public let favoriteIds: [String]
    public init(favoriteIds: [String]) {
        self.favoriteIds = favoriteIds
    }
}

// 用户 pin list 中删除 pin， 客户端触发
public struct PushDeletePinList: PushMessage {
    public let pinId: String
    public init(pinId: String) {
        self.pinId = pinId
    }
}

// 用户删除群内关联 URL，客户端触发
public struct PushLocalDeleteChatLinkedPages: PushMessage {
    public let chatID: Int64
    public let pageURLs: [String]

    public init(chatID: Int64, pageURLs: [String]) {
        self.chatID = chatID
        self.pageURLs = pageURLs
    }
}

// nickname
public struct PushChannelNickname: PushMessage {
    public let chatterId: String
    public let channelId: String
    public let channerType: RustPB.Basic_V1_Channel.TypeEnum
    public let newNickname: String

    public init(chatterId: String, channelId: String, channerType: RustPB.Basic_V1_Channel.TypeEnum, newNickname: String) {
        self.chatterId = chatterId
        self.channelId = channelId
        self.channerType = channerType
        self.newNickname = newNickname
    }
}

// nickname
public struct PushChatPinReadStatus: PushMessage {
    public let chatId: String
    public let hasRead: Bool

    public init(chatId: String, hasRead: Bool) {
        self.chatId = chatId
        self.hasRead = hasRead
    }
}

public struct PushCardMessageActionResult: PushMessage {
    public let messageID: String
    public let cardVersion: Int32
    public let pushType: RustPB.Basic_V1_CardMessageActionResult.PushType
    public let infos: (start: String, success: String, fail: String)
    public let actionID: String
    public let errorCode: Int32
    public let errorMsg: String
    public init(messageID: String,
                cardVersion: Int32,
                pushType: RustPB.Basic_V1_CardMessageActionResult.PushType,
                infos: (start: String, success: String, fail: String),
                actionID: String,
                errorCode: Int32,
                errorMsg: String) {
        self.messageID = messageID
        self.cardVersion = cardVersion
        self.pushType = pushType
        self.infos = infos
        self.actionID = actionID
        self.errorCode = errorCode
        self.errorMsg = errorMsg
    }
}

public struct PushThreads: PushMessage {
    public let threads: [RustPB.Basic_V1_Thread]

    public init(threads: [RustPB.Basic_V1_Thread]) {
        self.threads = threads
    }
}

/// 话题头像更新push
public struct PushThreadFeedAvatarChanges: PushMessage {
    public let avatars: [String: Feed_V1_PushThreadFeedAvatarChanges.Avatar]

    public init(avatars: [String: Feed_V1_PushThreadFeedAvatarChanges.Avatar]) {
           self.avatars = avatars
       }
}

/// local chat join state push
public struct PushLocalChatJoinState: PushMessage {
    public let chatID: String
    public let joinState: GroupJoinState

    public init(chatID: String, joinState: GroupJoinState) {
        self.chatID = chatID
        self.joinState = joinState
    }
}

/// for PushTopicGroups in Thread
public struct PushTopicGroups: PushMessage {
    public let topicGroups: [TopicGroup]

    public init(topicGroups: [TopicGroup]) {
        self.topicGroups = topicGroups
    }
}

/// for RecommendGroupItem in Thread
public struct PushTopicGroupTabBadge: PushMessage {
    public let hasNewContent: Bool

    public init(hasNewContent: Bool) {
        self.hasNewContent = hasNewContent
    }
}

/// 针对小组独立tab的PushMessages
public struct PushMessagesForTab: PushMessage {
    public let messages: [Message]

    public init(messages: [Message]) {
        self.messages = messages
    }
}

/// deleteMeFromChannel just for RecommendList
public struct PushRemoveMeForRecommendList: PushMessage {
    public let channelId: String

    public init(channelId: String) {
        self.channelId = channelId
    }
}

public enum PushChatChatterType {
    case append
    case delete
}

public typealias ChatChatterDepartment = Basic_V1_Department

/// add chat chatter push
public struct PushChatChatter: PushMessage {
    public let chatId: String
    public let chatters: [Chatter]
    public let id2DepartmentsDic: [String: ChatChatterDepartment]
    public let type: PushChatChatterType
    public init(chatId: String,
                chatters: [Chatter],
                id2DepartmentsDic: [String: ChatChatterDepartment],
                type: PushChatChatterType) {
        self.chatId = chatId
        self.chatters = chatters
        self.type = type
        self.id2DepartmentsDic = id2DepartmentsDic
    }
}

public struct PushChatAdmin: PushMessage {
    public let chatId: String
    public let adminUsers: [Chatter]
    public let id2DepartmentsDic: [String: ChatChatterDepartment]
    public init(chatId: String,
                adminUsers: [Chatter],
                id2DepartmentsDic: [String: ChatChatterDepartment]) {
        self.chatId = chatId
        self.adminUsers = adminUsers
        self.id2DepartmentsDic = id2DepartmentsDic
    }
}

public struct PushChatChatterTag: PushMessage {
    public let chatId: String
    public let chattersMap: [String: Chatter]
    public init(chatId: String,
                chattersMap: [String: Chatter]) {
        self.chatId = chatId
        self.chattersMap = chattersMap
    }
}

public struct PushChatChatterListDepartmentName: PushMessage {
    public let chatId: String
    public let chatterIDToDepartmentName: [String: String]
    public init(chatId: String,
                chatterIDToDepartmentName: [String: String]) {
        self.chatId = chatId
        self.chatterIDToDepartmentName = chatterIDToDepartmentName
    }
}

//本地假消息，其他端来的新thread消息
public struct PushThreadMessages: PushMessage {
    public let messages: [ThreadMessage]

    public init(messages: [ThreadMessage]) {
        self.messages = messages
    }
}

public struct PushMyThreadsReplyPrompt: PushMessage {
    /// 对应那个群id
    public let groupId: String
    /// 有几条回复我的消息数量
    public let newReplyCount: Int32
    /// 有几条@我的消息
    public let newAtReplyMessages: [Message]
    /// 有几条@我的消息数量
    public let newAtReplyCount: Int32

    public init(groupId: String, newReplyCount: Int32, newAtReplyMessages: [Message], newAtReplyCount: Int32) {
        self.groupId = groupId
        self.newReplyCount = newReplyCount
        self.newAtReplyMessages = newAtReplyMessages
        self.newAtReplyCount = newAtReplyCount
    }
}

/// 翻译设置
public struct PushTranslateLanguageSetting: PushMessage {
    /// 翻译设置的目标语言key
    public let targetLanguage: String
    /// 服务器支持的所有语言key
    public let languageKeys: [String]
    /// 语言key->显示文案映射关系
    public let supportedLanguages: [String: String]

    public init(targetLanguage: String,
         languageKeys: [String],
         supportedLanguages: [String: String]) {
        self.targetLanguage = targetLanguage
        self.languageKeys = languageKeys
        self.supportedLanguages = supportedLanguages
    }
}

/// 翻译效果设置
public struct PushLanguagesConfiguration: PushMessage {
    /// 默认所有语言配置
    public let globalConf: RustPB.Im_V1_LanguagesConfiguration
    /// 语言key->语言翻译设置，只存用户后期修改过的，第一次获取时为空
    public let languagesConf: [String: RustPB.Im_V1_LanguagesConfiguration]

    public init(globalConf: RustPB.Im_V1_LanguagesConfiguration, languagesConf: [String: RustPB.Im_V1_LanguagesConfiguration]) {
        self.globalConf = globalConf
        self.languagesConf = languagesConf
    }
}

/// 翻译效果设置
public struct PushLanguagesConfigurationV2: PushMessage {
    /// 语言key->语言翻译设置
    public let languagesConf: [String: RustPB.Im_V1_LanguagesConfiguration]

    public init(languagesConf: [String: RustPB.Im_V1_LanguagesConfiguration]) {
        self.languagesConf = languagesConf
    }
}

/// 不自动翻译语言设置
public struct PushDisableAutoTranslateLanguages: PushMessage {
    /// 不自动翻译的语言key
    public let disAutoTranslateLanguagesConf: [String]

    public init(disAutoTranslateLanguagesConf: [String]) {
        self.disAutoTranslateLanguagesConf = disAutoTranslateLanguagesConf
    }
}

/// 翻译scope通知，全局Scope, 解释见TranslateLanguageSetting
public struct PushAutoTranslateScope: PushMessage {
    public let translateScope: Int32

    public init(translateScope: Int32) {
        self.translateScope = translateScope
    }
}

/// 翻译scope通知，语种纬度Scope
public struct PushAutoTranslateSrcLanguageScope: PushMessage {
    public let srcLanguagesScope: [String: Int32]
    public init(srcLanguagesScope: [String: Int32]) {
        self.srcLanguagesScope = srcLanguagesScope
    }
}

// 本地通知
public struct PushLocoalNotification: PushMessage {
    public let message: RustPB.Basic_V1_Notice

    public init(message: RustPB.Basic_V1_Notice) {
        self.message = message
    }
}

// 小程序更新
public struct PushMiniprogramNeedUpdate: PushMessage {
    public let client_id: String
    public let latency: Int
    public let extra: String

    public init(client_id: String, latency: Int, extra: String) {
        self.client_id = client_id
        self.latency = latency
        self.extra = extra
    }
}

// 开放平台通用push
public struct PushOpenCommonRequestEvent: PushMessage {
    public let events: [OpenEvent]

    public enum EventType: Int {
        case unknown = 0
        case userUploadSettingUpdated = 1
    }

    public struct OpenEvent {
        public let type: EventType
        public let pushTime: Int64
        public let appID: Int64?
        public let payload: String?

        public init(type: EventType,
                    pushTime: Int64,
                    appID: Int64?,
                    payload: String?) {
            self.type = type
            self.pushTime = pushTime
            self.appID = appID
            self.payload = payload
        }
    }

    public init(events: [OpenEvent]) {
        self.events = events
    }

    public func hasUserUploadSettingUpdated() -> Bool {
        return events.contains(where: { (event) -> Bool in
            event.type == .userUploadSettingUpdated
        })
    }
}

/// email unread thread count.
public struct MailUnreadThreadCount: PushMessage {
    public let count: Int64
    public init(count: Int64) {
        self.count = count
    }
}

public struct MailSettingChanged: PushMessage {
    public let setting: Email_Client_V1_Setting
    public init(setting: Email_Client_V1_Setting) {
        self.setting = setting
    }
}

/// Space
public struct SpaceNoticeMessage: PushMessage {
    public let body: String
    public init(body: String) {
        self.body = body
    }
}

/// email outbox state change.
public struct MailOutboxSendStateChange: PushMessage {
    public let threadId: String
    public let messageId: String
    public let deliveryState: RustPB.Email_Client_V1_Message.DeliveryState
    public let count: Int32
    public let lastUpdateTime: Int64
    public init(threadId: String,
                messageId: String,
                deliveryState: RustPB.Email_Client_V1_Message.DeliveryState,
                count: Int32,
                lastUpdateTime: Int64) {
        self.threadId = threadId
        self.messageId = messageId
        self.deliveryState = deliveryState
        self.count = count
        self.lastUpdateTime = lastUpdateTime
    }
}

/// MailThreadChange.
public struct MailThreadChange: PushMessage {
    public let labelIds: [String]
    public let threadId: String
    public init(labelIds: [String], threadId: String) {
        self.labelIds = labelIds
        self.threadId = threadId
    }
}

/// MailMultiThreadsChange.
public struct MailMultiThreadsChange: PushMessage {
    public var label2Threads: [String: (threadIds: [String], needReload: Bool)]
    public init(label2Threads: [String: (threadIds: [String], needReload: Bool)] ) {
        self.label2Threads = label2Threads
    }
}

/// MailLabelChange.
public struct MailLabelChange: PushMessage {
    public let labels: [RustPB.Email_Client_V1_Label]
    public init(labels: [RustPB.Email_Client_V1_Label]) {
        self.labels = labels
    }
}

/// MailLabelPropertyChange.
public struct MailLabelPropertyChange: PushMessage {
    public let label: RustPB.Email_Client_V1_Label
    public let isDelete: Bool
    public init(label: RustPB.Email_Client_V1_Label, isDelete: Bool) {
        self.label = label
        self.isDelete = isDelete
    }
}

/// MailRefreshLabelThreadsChange
public struct MailRefreshLabelThreadsChange: PushMessage {
    public let labelId: String
    public init(labelId: String) {
        self.labelId = labelId
    }
}

/// MailCacheInvalidChange
public struct MailCacheInvalidChange: PushMessage {
    public init() {
    }
}

/// MailShareThreadChange
public struct MailShareThreadChange: PushMessage {
    public var threadId: String
    public init(threadId: String) {
        self.threadId = threadId
    }
}

/// MailUnshareThreadChange
public struct MailUnshareThreadChange: PushMessage {
    public let threadId: String
    public let operatorUserID: String
    public init(threadId: String, operatorUserID: String) {
        self.threadId = threadId
        self.operatorUserID = operatorUserID
    }
}

/// mail change push.
public struct MailChangePush: PushMessage {
    public init() {
    }
}

/// mail migration change push
public struct MailMigrationChange: PushMessage {
    public let stage: Int
    public let progressPct: Int
    public init(stage: Int, progressPct: Int) {
        self.stage = stage
        self.progressPct = progressPct
    }
}

/// Mail google auth callback push
public struct MailOauthStatusPush: PushMessage {
    public static var notificationName: String {
        return "MailOauthStatusPush"
    }

    public enum Status {
        case unknown
        case success
        case fail
        case revoke
    }
    public let authStatus: Status
    public let emailAddress: String
    public let setting: Email_Client_V1_Setting

    public init (authStatus: Status, emailAddress: String, setting: Email_Client_V1_Setting) {
        self.authStatus = authStatus
        self.emailAddress = emailAddress
        self.setting = setting
    }
}

public struct PushAudioMessageRecognitionResult: PushMessage {
    public var channelID: String
    public var messageID: String
    public var seqID: Int32
    public var result: String
    /// 语音消息是否已经识别结束
    public var isEnd: Bool
    /// 当前片与上一片识别结果区别的索引
    public var diffIndexSlice: [Int32] = []

    public init(
        channelID: String,
        messageID: String,
        seqID: Int32,
        result: String,
        isEnd: Bool,
        diffIndexSlice: [Int32]
    ) {
        self.channelID = channelID
        self.messageID = messageID
        self.seqID = seqID
        self.result = result
        self.isEnd = isEnd
        self.diffIndexSlice = diffIndexSlice
    }
}

// App Feed Push
public struct PushAppFeeds: PushMessage {

    public struct AppFeed {
        public let appID: String
        public let lastNotificationSeqID: String
        public let url: URL?

        public init(appID: String,
                    lastNotificationSeqID: String,
                    url: URL?) {
            self.appID = appID
            self.lastNotificationSeqID = lastNotificationSeqID
            self.url = url
        }
    }

    public let appFeeds: [String: AppFeed]

    public init(appFeeds: [String: AppFeed]) {
        self.appFeeds = appFeeds
    }
}

/// 小程序预览
public struct PushMiniprogramPreview: PushMessage {
    public let client_id: String
    public let url: String
    public let extra: String?
    public let timeStamp: String?

    public init(client_id: String, url: String, extra: String?, timeStamp: String?) {
        self.client_id = client_id
        self.url = url
        self.extra = extra
        self.timeStamp = timeStamp
    }
}

// 用户最近使用 reaction
public struct PushUserReactions: PushMessage {
    public let keys: [String]

    public init(keys: [String]) {
        self.keys = keys
    }
}

// 用户最常使用 reaction
public struct PushUserMruReactions: PushMessage {
    public let keys: [String]

    public init(keys: [String]) {
        self.keys = keys
    }
}

// feed预加载同步消息结束通知
public struct PushPreloadUpdatedChatIds: PushMessage {
    public let ids: [String]

    public init(ids: [String]) {
        self.ids = ids
    }
}

/// 邮件通知设置变化
public struct PushMailNotificationSetting: PushMessage {
    public let notificationSettings: RustPB.Email_Client_V1_MailNotificationSettings

    public init(settings: RustPB.Email_Client_V1_MailNotificationSettings) {
        self.notificationSettings = settings
    }
}

// 二维码添加好友设置
public struct PushWayToAddMeSettingMessage: PushMessage {
    public let addMeSetting: Bool

    public init(addMeSetting: Bool) {
        self.addMeSetting = addMeSetting
    }
}

// 添加好友成功
public struct PushAddContactSuccessMessage: PushMessage {
    public let userId: String
/// Feed侧边栏远端下发的Sidebar
    public init(userId: String) {
        self.userId = userId
    }
}

public struct PushMineSidebar: PushMessage {
    public let sidebars: [RustPB.Passport_V1_GetUserSidebarResponse.SidebarInfo]
    public init(sidebars: [RustPB.Passport_V1_GetUserSidebarResponse.SidebarInfo]) {
        self.sidebars = sidebars
    }
}

extension PushTeams: PushMessage {}
extension PushTeamMembers: PushMessage {}
extension PushItems: PushMessage {}

public struct PushExtractPackage: PushMessage {
    public enum ExtractState {
        case success(result: Media_V1_BrowseFolderResponse)
        case inProgress(progress: Float)
        case failed(error: Basic_V1_LarkError)
    }
    public let status: ExtractState
    public let key: String?
    public init(status: ExtractState, key: String?) {
        self.key = key
        self.status = status
    }
}
public struct PushFocusChatterMessage: PushMessage {
    public let deleteChatterIds: [String]
    public let addChatters: [Chatter]
    public init(deleteChatterIds: [String], addChatters: [Chatter]) {
        self.deleteChatterIds = deleteChatterIds
        self.addChatters = addChatters
    }
}

public struct PushChatToolKits: PushMessage {
    public let toolKits: [RustPB.Basic_V1_Toolkit]

    public init(toolKits: [RustPB.Basic_V1_Toolkit]) {
        self.toolKits = toolKits
    }
}

public struct PushTenantMessageConf: PushMessage {
    public let conf: Im_V1_TenantMessageConf
    public init(conf: Im_V1_TenantMessageConf) {
        self.conf = conf
    }
}

// 定时消息推送
public struct PushScheduleMessage: PushMessage {
    public let messageItems: [RustPB.Basic_V1_ScheduleMessageItem]
    public let entity: RustPB.Basic_V1_Entity

    public init(messageItems: [RustPB.Basic_V1_ScheduleMessageItem],
                entity: RustPB.Basic_V1_Entity) {
        self.entity = entity
        self.messageItems = messageItems
    }
}

public struct PushAudioRecognition: PushMessage {
    public let push: Im_V1_SendSpeechRecognitionResponse
    public init(push: Im_V1_SendSpeechRecognitionResponse) {
        self.push = push
    }
}
