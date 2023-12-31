//
//  MessageAPI.swift
//  LarkSDKInterface
//
//  Created by zc09v on 2018/5/30.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//
import Foundation
import LarkModel
import RxSwift
import RustPB
import ServerPB

public enum PullMessagesType: Int {
    case before = 1
    case after // = 2
    case latest // = 3

    public func calculatePosition(position: Int32, count: Int32) -> (Int32, Int32) {
        var smallerPosition = position
        var greaterPosition = position
        switch self {
        case .after:
            greaterPosition = position + count - 1
        case .before, .latest:
            smallerPosition = (position - count + 1) >= 0 ? (position - count + 1) : 0
        }
        return (smallerPosition, greaterPosition)
    }
}

public enum FetchChatMessagesScene {
    case firstScreen
    case specifiedPosition(Int32)
    case previous(before: Int32)
    case after(after: Int32)
}

public struct GetChatMessagesTrackInfo {
    //接口contextId
    public let contextId: String
    //sdk处理耗时
    public let sdkCost: Int64
    public let netCosts: [Int64]
    //端上模型转换解析耗时
    public let parseCost: Int64
    //端上打点使用，如果是 true 表示消息已经同步完管子
    public let messagesSyncPipeFinished: [String: Bool]

    public init(contextId: String, sdkCost: Int64, netCosts: [Int64], parseCost: Int64, messagesSyncPipeFinished: [String: Bool]) {
        self.contextId = contextId
        self.sdkCost = sdkCost
        self.netCosts = netCosts
        self.parseCost = parseCost
        self.messagesSyncPipeFinished = messagesSyncPipeFinished
    }
}

public struct GetChatMessagesResult {
    /// 整体消息
    public let messages: [Message]
    /// 不可见的Positions
    public let invisiblePositions: [Int32]
    /// 丢失的Positions
    public let missedPositions: [Int32]
    /// 折叠的区间
    public let foldPositionRange: [(Int32, Int32)]
    /// 当前的totalPositions = messages + invisiblePositions + missedPositions + foldPositions
    public private(set) var totalRange: (minPostion: Int32, maxPostion: Int32)?

    public let trackInfo: GetChatMessagesTrackInfo
    public let localData: Bool
    public init(messages: [Message],
                invisiblePositions: [Int32],
                missedPositions: [Int32],
                foldPositionRange: [(Int32, Int32)] = [],
                localData: Bool,
                trackInfo: GetChatMessagesTrackInfo) {
        self.messages = messages
        self.invisiblePositions = invisiblePositions
        self.missedPositions = missedPositions
        self.foldPositionRange = foldPositionRange
        self.localData = localData
        self.trackInfo = trackInfo
        self.updateTotalRange()
    }

    private mutating func updateTotalRange() {
        var minPosition = messages.first?.position
        var maxPosition = messages.last?.position
        if !invisiblePositions.isEmpty {
            minPosition = minPosition == nil ? (invisiblePositions.first ?? 0) : min(invisiblePositions.first ?? 0, minPosition ?? 0)
            maxPosition = maxPosition == nil ? (invisiblePositions.last ?? 0) : max(invisiblePositions.last ?? 0, maxPosition ?? 0)
        }
        if !missedPositions.isEmpty {
            minPosition = minPosition == nil ? (missedPositions.first ?? 0) : min(missedPositions.first ?? 0, minPosition ?? 0)
            maxPosition = maxPosition == nil ? (missedPositions.last ?? 0) : max(missedPositions.last ?? 0, maxPosition ?? 0)
        }
        foldPositionRange.forEach { range in
            minPosition = minPosition == nil ? range.0 : min(range.0, minPosition ?? 0)
            maxPosition = maxPosition == nil ? range.1 : max(range.1, maxPosition ?? 0)
        }
        if minPosition != nil, maxPosition != nil {
            self.totalRange = (minPosition ?? 0, maxPosition ?? 0)
        }
    }
}

public protocol MessageAPI {

    //有本地数据返回本地，否则从网上取
    func fetchMessage(id: String) -> Observable<Message>

    // 异步拉取本地数据
    // needTryLocal = true时 会在无本地数据时尝试从网上取
    func fetchMessagesMap(ids: [String], needTryLocal: Bool) -> Observable<[String: Message]>

    //仅返回本地数据，注意本地可能没有
    func getMessagesMap(ids: [String]) throws -> [String: Message]

    //仅返回本地数据，注意本地可能没有
    func fetchLocalMessage(id: String) -> Observable<LarkModel.Message>

    //有本地数据返回本地，否则从网上取
    func fetchMessages(ids: [String]) -> Observable<[Message]>

    //拉取某条消息的回复消息(裸消息)
    func fetchReplies(messageId: String) -> Observable<[Message]>

    //获取本地回复
    func getReplies(messageId: String) throws -> [Message]

    //设置聊天页面不同消息显示权重
    //weights: 不同消息类型与权重的映射关系 maxWeights: 最大权重限制,text/post等rust会根据字数叠加权重，但因为有折叠等逻辑，不能一直叠加，要有最大权重限制
    func setMessageDisplay(weights: [Int32: Double], maxWeights: [Int32: Double]) -> Observable<Void>

    func recall(messageId: String) -> Observable<Void>

    func recallGroupMessage(messageId: String) -> Observable<Void>

    //二次编辑消息
    func multiEditMessage(messageId: Int64, chatId: String, type: Basic_V1_Message.TypeEnum,
                          richText: Basic_V1_RichText, title: String?, lingoInfo: Basic_V1_LingoOption,
                          uploadMediaBlock: ((Basic_V1_RichTextElement.MediaProperty) -> Void)) -> Observable<RustPB.Basic_V1_RichText>

    func putReadMessages(channel: RustPB.Basic_V1_Channel,
                         messageIds: [String],
                         maxPosition: Int32,
                         maxPositionBadgeCount: Int32)

    func putReadMessages(channel: RustPB.Basic_V1_Channel,
                         messageIds: [String],
                         maxPosition: Int32,
                         maxPositionBadgeCount: Int32,
                         foldIds: [Int64])

    func delete(messageIds: [String]) -> Observable<Void>

    func delete(quasiMessageId: String) -> Observable<Void>

    func deleteEphemeral(messageId: String) -> Observable<Void>

    func deleteByNoTrace(with messageId: String) -> Observable<Void>

    func hideUrlPreview(messageId: String) -> Observable<Void>

    func fetchUnreadAtMessages(chatIds: [String]?, ignoreBadged: Bool, needResponse: Bool) -> Observable<[String: [Message]]>

    func getChatMessages(chatId: String,
                         scene: FetchChatMessagesScene,
                         redundancyCount: Int32,
                         count: Int32,
                         expectDisplayWeights: Int32?,
                         redundancyDisplayWeights: Int32?,
                         needResponse: Bool,
                         subscribChatEvent: Bool
        ) -> Observable<GetChatMessagesResult?>

    func fetchChatMessages(chatId: String,
                           scene: FetchChatMessagesScene,
                           redundancyCount: Int32,
                           count: Int32,
                           expectDisplayWeights: Int32?,
                           redundancyDisplayWeights: Int32?,
                           needResponse: Bool)
        -> Observable<GetChatMessagesResult>

    func fetchMessagesBy(positions: [Int32], channel: RustPB.Basic_V1_Channel) -> Observable<([Message], invisiblePositions: [Int32])>

    func getMessageReadStatus(messageId: String,
                              listType: RustPB.Im_V1_GetMessageReadStateRequest.ListType,
                              query: String?,
                              readCursor: String?,
                              unreadCursor: String?,
                              needUsers: Bool) -> Observable<RustPB.Im_V1_GetMessageReadStateResponse>

    // 获取系统消息的ActionPayload
    func getSystemMessageActionPayload(messageID: String, actionType: SystemContent.ActType) -> Observable<SystemContent.ActionPayload>
    // 返回当前位置向下的可选消息id, 过滤删除、撤回、不可见和系统消息, 多选消息时使用
    func getMessageIdsByPosition(chatId: String, startPosition: Int32, count: Int32) -> Observable<RustPB.Im_V1_GetMessageIdsByPositionResponse>
    // 系统消息 Lark Command
    func sendLarkCommandPayload(cmd: Int32, payload: Data) -> Observable<RustPB.Basic_V1_SendLarkCommandPayloadResponse>

    // 获取聚合消息详情页列表
    func messageFoldFollowListWith(foldId: Int64,
                                   count: Int32,
                                   chatId: Int64,
                                   startTimeMs: Int64) -> Observable<RustPB.Im_V1_GetMessageFoldFollowListResponse>
    // 撤回卡片
    func recallMessageFold(foldId: Int64,
                           recallByGroupAdmin: Bool) -> Observable<ServerPB.ServerPB_Messages_RecallMessageFoldResponse>

    // 点击 +1的接口
    func putMessageFoldFollow(foldId: Int64, count: Int32) -> Observable<ServerPB.ServerPB_Messages_PutMessageFoldFollowResponse>

    // 消息链接化：获取是否有消息链接权限
    func getMessageLinkPermission(token: String) -> Observable<ServerPB.ServerPB_Messages_GetMessageLinkPermissionResponse>

    /// 消息链接化：对一组消息生成链接
    /// fromID: chatID/threadID
    /// from:
    /// copiedIDs: messageIDs
    func putMessageLink(fromID: String,
                        from: ServerPB_Messages_PutMessageLinkRequest.LinkFrom,
                        copiedIDs: [String]) -> Observable<ServerPB.ServerPB_Messages_PutMessageLinkResponse>

    // 获取定时消息
    func getScheduleMessages(chatId: Int64,
                             threadId: Int64?,
                             rootId: Int64?,
                             isForceServer: Bool,
                             scene: GetScheduleMessagesScene) -> Observable<GetScheduleMessagesResponse>

    // 获取定时消息
    func getScheduleMessages(chatId: Int64,
                             threadId: Int64?,
                             rootId: Int64?,
                             scene: GetScheduleMessagesScene) -> Observable<GetScheduleMessagesResponse>

    // 修改定时消息
    func patchScheduleMessageRequest(chatID: Int64,
                                     messageType: Basic_V1_Message.TypeEnum?,
                                     patchObject: ScheduleMessageItem,
                                     patchType: PatchScheduleMessageType,
                                     scheduleTime: Int64?,
                                     isSendImmediately: Bool,
                                     needSuspend: Bool,
                                     content: QuasiContent?) -> Observable<PatchScheduleMessageResponse>

    // 将消息「设为保密」或「取消保密」
    func updateRestrictedMessage(chatId: Int64,
                                 messageId: Int64,
                                 isRestricted: Bool) -> Observable<UpdateRestrictedMessageResponse>

    // 拉取MessageLink
    func pullMessageLink(
        token: String,
        previewID: String,
        needMessageIDs: [Int64],
        syncDataStrategy: Basic_V1_SyncDataStrategy
    ) -> Observable<(response: Im_V1_PullMessageLinkMessagesResponse, sdkCost: Int64)>
}

public typealias MessageAPIProvider = () -> MessageAPI

public typealias PatchScheduleMessageType = RustPB.Im_V1_PatchScheduleMessageRequest.PatchType
public typealias ScheduleMessageItem = RustPB.Basic_V1_ScheduleMessageItem
public typealias QuasiContent = RustPB.Basic_V1_QuasiContent
public typealias PatchScheduleMessageResponse = RustPB.Im_V1_PatchScheduleMessageResponse
public typealias GetScheduleMessagesResponse = RustPB.Im_V1_GetScheduleMessagesResponse
public typealias GetScheduleMessagesScene = RustPB.Im_V1_GetScheduleMessagesRequest.Scene
//消息支持保密
public typealias UpdateRestrictedMessageRequest = RustPB.Im_V1_UpdateRestrictedMessageRequest
public typealias UpdateRestrictedMessageResponse = RustPB.Im_V1_UpdateRestrictedMessageResponse
