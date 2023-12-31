//
//  ThreadAPI.swift
//  LarkThread
//
//  Created by zc09v on 2019/1/31.
//

import Foundation
import UIKit
import LarkModel
import RxSwift
import RustPB

// 传入一个负数，将来把他过滤掉。因为-1 -2有其他用，服务端下发了-3，端上就保持跟服务端的数一致
public let replyInThreadMessagePosition: Int32 = -3

public typealias ChatAndTopicGroupsResult = (chat: Chat, topicGroup: TopicGroup?, trackInfo: ThreadRequestTrackInfo)

public enum GetDataScene {
    case firstScreen
    case specifiedPosition(Int32)
    case previous(before: Int32)
    case after(after: Int32)

    public func description() -> String {
        switch self {
        case .firstScreen:
            return "firstScreen"
        case .previous(before: let position):
            return "previous from \(position)"
        case .after(after: let position):
            return "after from \(position)"
        case .specifiedPosition(let position):
            return "specifiedPosition \(position)"
        }
    }
}

public struct ThreadRequestTrackInfo {
    public let contextId: String
    public let parseCost: Double
    public let requestCost: Double
    public init(contextId: String, parseCost: Double, requestCost: Double) {
        self.contextId = contextId
        self.parseCost = parseCost
        self.requestCost = requestCost
    }

   public static func generateTrackInfo(by firstTrackInfo: ThreadRequestTrackInfo, other twoTrackInfo: ThreadRequestTrackInfo) -> ThreadRequestTrackInfo {
       return ThreadRequestTrackInfo(
            contextId: firstTrackInfo.contextId + "_" + twoTrackInfo.contextId,
            parseCost: firstTrackInfo.parseCost + twoTrackInfo.parseCost,
            requestCost: firstTrackInfo.requestCost + twoTrackInfo.requestCost
        )
    }
}

public struct GetThreadsResult {
    public let threadMessages: [ThreadMessage]
    public let invisiblePositions: [Int32]
    public let missedPositions: [Int32]
    /// 有几条回复我的消息数量
    public let newReplyCount: Int32
    /// 有几条@我的消息
    public let newAtReplyMessages: [Message]
    /// 有几条@我的消息数量
    public let newAtReplyCount: Int32
    public let localData: Bool
    public let needFetchRemote: Bool
    public let trackInfo: ThreadRequestTrackInfo
    public init(
        threadMessages: [ThreadMessage],
        invisiblePositions: [Int32],
        missedPositions: [Int32],
        newReplyCount: Int32,
        newAtReplyMessages: [Message],
        newAtReplyCount: Int32,
        localData: Bool,
        needFetchRemote: Bool = false,
        trackInfo: ThreadRequestTrackInfo
    ) {
        self.threadMessages = threadMessages
        self.invisiblePositions = invisiblePositions
        self.missedPositions = missedPositions
        self.newReplyCount = newReplyCount
        self.newAtReplyMessages = newAtReplyMessages
        self.newAtReplyCount = newAtReplyCount
        self.localData = localData
        self.needFetchRemote = needFetchRemote
        self.trackInfo = trackInfo
    }
}

public struct GetThreadMessagesResult {
    public let messages: [Message]
    public let invisiblePositions: [Int32]
    public let missedPositions: [Int32]
    public let localData: Bool
    public let sdkCost: Double
    public let trackInfo: ThreadRequestTrackInfo
    /// 当前的totalPositions = messages + invisiblePositions + missedPositions
    public private(set) var totalRange: (minPostion: Int32, maxPostion: Int32)?
    public var successMessages: [Message] {
        return messages.flatMap {
            guard $0.localStatus == .success else { return nil }
            return $0
        }
    }
    public var successMessagesTotalRange: (minPostion: Int32, maxPostion: Int32)? {
        return getTotalRange(of: successMessages)
    }

    public init(messages: [Message], invisiblePositions: [Int32], missedPositions: [Int32], localData: Bool, sdkCost: Double, trackInfo: ThreadRequestTrackInfo) {
        self.messages = messages
        self.invisiblePositions = invisiblePositions
        self.missedPositions = missedPositions
        self.localData = localData
        self.sdkCost = sdkCost
        self.trackInfo = trackInfo
        self.updateTotalRange()
    }

    private mutating func updateTotalRange() {
        self.totalRange = self.getTotalRange(of: self.messages)
    }

    private func getTotalRange(of messages: [Message]) -> (minPostion: Int32, maxPostion: Int32)? {
        var minPosition = messages.first?.threadPosition
        var maxPosition = messages.last?.threadPosition
        if !invisiblePositions.isEmpty {
            minPosition = minPosition == nil ? (invisiblePositions.first ?? 0) : min(invisiblePositions.first ?? 0, minPosition ?? 0)
            maxPosition = maxPosition == nil ? (invisiblePositions.last ?? 0) : max(invisiblePositions.last ?? 0, maxPosition ?? 0)
        }
        if !missedPositions.isEmpty {
            minPosition = minPosition == nil ? (missedPositions.first ?? 0) : min(missedPositions.first ?? 0, minPosition ?? 0)
            maxPosition = maxPosition == nil ? (missedPositions.last ?? 0) : max(missedPositions.last ?? 0, maxPosition ?? 0)
        }
        if minPosition != nil, maxPosition != nil {
             return (minPosition ?? 0, maxPosition ?? 0)
        }
        return nil
    }
}

public struct GetRecommendItemResult {
    public let recommendItems: [ThreadRecommendItem]
    public let nextCursor: String
    public let isRefreshed: Bool
    public let trackInfo: ThreadRequestTrackInfo

    public init(recommendItems: [ThreadRecommendItem], nextCursor: String, isRefreshed: Bool, trackInfo: ThreadRequestTrackInfo) {
        self.recommendItems = recommendItems
        self.nextCursor = nextCursor
        self.isRefreshed = isRefreshed
        self.trackInfo = trackInfo
    }
}
public typealias GetUnreadAtMessagesRequestQuary = RustPB.Im_V1_GetUnreadAtMessagesRequest.Query

public protocol ThreadAPI {
    /// 更新Thread免打扰状态
    func update(threadId: String, isRemind: Bool) -> Observable<Void>

    /// 更新Thread关注状态、Thread状态
    ///
    /// - Parameters:
    ///   - threadId: String
    ///   - isFollow: Bool? 关注状态，nil时不会修改关注状态。
    ///   - state: RustPB.Basic_V1_ThreadState? Thread状态，nil时不会修改thread状态
    /// - Returns: Observable<Void>
    func update(threadId: String, isFollow: Bool?, threadState: RustPB.Basic_V1_ThreadState?) -> Observable<Void>

    //更新Thread已读状态
    func updateThreadsMeRead(channel: RustPB.Basic_V1_Channel, threadIds: [String], readPosition: Int32, readPositionBadgeCount: Int32)

    /// 小组独立tab，发现页中。针对来自不同小组的话题，对RootMessage进行已读。
    /// - Parameter readPairs: RustPB.Im_V1_UpdateTopicsMeReadRequest.ReadPair
    func updateTopicsMeRead(readPairs: [RustPB.Im_V1_UpdateTopicsMeReadRequest.ReadPair])

    func fetchUnreadAtMessages(quaries: GetUnreadAtMessagesRequestQuary, ignoreBadged: Bool, needResponse: Bool) -> Observable<[ThreadMessage]>

    //更新Thread下回复消息已读状态
    func updateThreadMessagesMeRead(channel: RustPB.Basic_V1_Channel, threadId: String, messageIds: [String], maxPositionInThread: Int32, maxPositionBadgeCountInThread: Int32)

    //异步获取Threads
    /// forNormalChatMessage(是否为普通消息拉取thread): 在replyInThread场景中传入true
    func fetchThreads(_ threadIds: [String],
                      strategy: RustPB.Basic_V1_SyncDataStrategy,
                      forNormalChatMessage: Bool) -> Observable<(threadMessages: [ThreadMessage], trackInfo: ThreadRequestTrackInfo)>

    func transformEntityToThreadMessage(
        fromEntity entity: RustPB.Basic_V1_Entity
    ) -> [String: ThreadMessage]

    /// 我参与的话题，标记已读状态
    func putReadMyThreads(groupId: String) -> Observable<Void>

    /// 通过positions异步获取Threads。response threadMessage顺序不一定是按照positions的顺序。
    func fetchThreadsBy(
        positions: [Int32],
        channel: RustPB.Basic_V1_Channel) -> Observable<([ThreadMessage], invisiblePositions: [Int32])>

    /// 异步获取Threads，useIncompleteLocalData决定数据获取策略。
    ///
    /// - Parameters:
    ///   - channel: Channel
    ///   - scene: GetDataScene 场景
    ///   - redundancyCount: Int32 冗余数量
    ///   - count: Int32 请求数量
    ///   - useIncompleteLocalData: Bool 是否可使用不完整的本地数据,true时，即便本地数据不完整，也会返回，缺失消息在missedPositions中
    /// - Returns: Observable<GetThreadsResult?>
    func getThreads(
        channel: RustPB.Basic_V1_Channel,
        scene: GetDataScene,
        redundancyCount: Int32,
        count: Int32,
        useIncompleteLocalData: Bool,
        needReplyPrompt: Bool) -> Observable<GetThreadsResult>

    /// 异步获取Threads
    ///
    /// - Parameters:
    ///   - channel: Channel
    ///   - scene: GetDataScene 场景
    ///   - redundancyCount: Int32 冗余数量
    ///   - count: Int32 请求数量
    /// - Returns: Observable<GetThreadsResult>
    func fetchThreads(
        channel: RustPB.Basic_V1_Channel,
        scene: GetDataScene,
        redundancyCount: Int32,
        count: Int32,
        needReplyPrompt: Bool) -> Observable<GetThreadsResult>

    /// 异步获取过滤后的Threads
    ///
    /// - Parameters:
    ///   - channelID: String
    ///   - filterID: String，从哪一页
    ///   - extendFilterID: [String]
    ///   - scene: RustPB.Basic_V1_ChannelDataScene
    ///   - cursor: String 分页标示
    ///   - count: Int32 分页数量
    ///   - preloadCount: Int32 预加载数量
    /// - Returns: Observable<([ThreadMessage], String)>
    func fetchFilteredThreads(
        channelID: String,
        filterID: String,
        extendFilterID: [String],
        scene: RustPB.Basic_V1_ChannelDataScene,
        cursor: String?,
        count: Int32,
        preloadCount: Int32
    ) -> Observable<([ThreadMessage], String, String)>

    /// 获取推荐话题
    ///
    /// - Parameters:
    ///   - scene: RustPB.Im_V1_GetRecommendationsByUserRequest.RecommendationsScene firstScreen 首屏， refresh 下拉刷新，nextPage 下一页
    ///   - count: Int32 加载数量
    ///   - preloadCount: Int32 预加载数量
    ///   - cursor: String? 只在拉去旧的数据时会用到。
    /// - Returns: Observable<GetRecommendItemResult>
    func fetchRecommendThread(
        scene: RustPB.Im_V1_GetRecommendationsByUserRequest.RecommendationsScene,
        count: Int32,
        preloadCount: Int32,
        cursor: String?
        ) -> Observable<GetRecommendItemResult>

    /// 异步获取ThreadDetail中的回复消息，useIncompleteLocalData决定数据获取策略。
    ///
    /// - Parameters:
    ///   - threadId: String
    ///   - scene: GetDataScene 场景
    ///   - redundancyCount: Int32 冗余数量
    ///   - count: Int32 请求数量
    ///   - useIncompleteLocalData: 是否可使用不完整的本地数据,true时，即便本地数据不完整，也会返回，缺失消息在missedPositions中
    /// - Returns: Observable<GetThreadMessagesResult?>
    func getThreadMessages(
        threadId: String,
        isReplyInThread: Bool,
        scene: GetDataScene,
        redundancyCount: Int32,
        count: Int32,
        useIncompleteLocalData: Bool) -> Observable<GetThreadMessagesResult?>

    /// 异步获取 ThreadDetail 回复
    ///
    /// - Parameters:
    ///   - threadId: String
    ///   - scene: GetDataScene 场景
    ///   - redundancyCount: Int32 冗余数量
    ///   - count: Int32 请求数量
    /// - Returns: Observable<GetThreadMessagesResult>
    func fetchThreadMessages(
        threadId: String,
        scene: GetDataScene,
        redundancyCount: Int32,
        count: Int32) -> Observable<GetThreadMessagesResult>

    /// fetch RecommendedTopicGroups
    /// - Parameter scene: RustPB.Im_V1_GetRecommendedTopicGroupsRequest.RecommendedGroupScene
    /// - Parameter count: Int32
    /// - Parameter cursor: String
    func fetchRecommendedTopicGroups(
        scene: RustPB.Im_V1_GetRecommendedTopicGroupsRequest.RecommendedGroupScene,
        count: Int32,
        cursor: String?
    ) -> Observable<([ThreadRecommendedGroupItem], String)>

    /// 通过positions异步获取ThreadDetail 回复
    func fetchThreadMessagesBy(
        positions: [Int32],
        threadID: String) -> Observable<([LarkModel.Message], invisiblePositions: [Int32])>

    /// 订阅独立Tab的数据push
    ///
    /// - Parameter isSubscribe: 是否订阅独立Tab的数据push。true: 订阅，false: 取消订阅
    /// - Returns: Observable<Void>
    func subscribeThreadTab(isSubscribe: Bool) -> Observable<Void>

    func shareThreadTopic(threadId: String, chatId: String, toChatIds: [String]) -> Observable<Void>

    func shareThreadTopicWithResp(threadId: String, chatId: String, toChatIds: [String]) -> Observable<[String: String]>

    /// 发帖页中推荐的小组列表
    func getTopicGroupsForPost(cursor: String, count: Int) -> Observable<([TopicGroupWithChat], String)>

    /// 获取TopicGroup
    /// - Parameter topicGroupIDs: topicGroupID 和 ChatID一致
    /// - Parameter forceRemote: 是否请求远端。false: 优先使用本地数据如果本地没有则请求远端。
    func getTopicGroup(topicGroupIDs: [String], forceRemote: Bool) -> Observable<[String: TopicGroup]>

    /// fetch TopicGroup and Chat
    /// - Parameter chatID: chatID
    /// - Parameter forceRemote: true: sync server data
    /// - Parameter syncUnsubscribeGroups: true: sync unsubscribe topic group. true: SDK未订阅的TopicGrup会触发网络请求，现在的场景只在观察者模式 和 默认小组 中存在。
    func fetchChatAndTopicGroup(
        chatID: String,
        forceRemote: Bool,
        syncUnsubscribeGroups: Bool
    ) -> Observable<(ChatAndTopicGroupsResult?)>

    func dislikeTopicGroup(topicGroupID: String) -> Observable<Void>

    func dislikeTopic(threadID: String) -> Observable<Void>

    func dislikeUser(userID: String) -> Observable<Void>

    /// create topic group.
    func createTopicGroup(
           name: String,
           desc: String,
           userIds: [String],
           isPublic: Bool
       ) -> Observable<Chat>

    func addMembers(topicGroupID: String, memberIDs: [String], isDefaultFavorite: Bool) -> Observable<Void>

    /// 获取匿名次数
    func getThreadAnonymousInfo() -> Observable<RustPB.Im_V1_GetAnonymousInfoResponse>
}

public typealias ThreadAPIProvider = () -> ThreadAPI

public enum ThreadRecommendItemType {
    /// topic
    case topic
    /// recommend groups
    case groups
}

public struct ThreadRecommendGroup {
    public var recommendGroups: [ThreadRecommendedGroupItem]
    public var hasMoreRecommendedTopicGroups: Bool

    public init(recommendGroups: [ThreadRecommendedGroupItem], hasMoreRecommendedTopicGroups: Bool) {
        self.recommendGroups = recommendGroups
        self.hasMoreRecommendedTopicGroups = hasMoreRecommendedTopicGroups
    }
}

public struct ThreadRecommendItem {
    public let threadMessage: ThreadMessage?
    public let recommendGroup: ThreadRecommendGroup?
    public let type: ThreadRecommendItemType

    public init(
        threadMessage: ThreadMessage? = nil,
        recommendGroup: ThreadRecommendGroup? = nil,
        type: ThreadRecommendItemType
    ) {
        self.threadMessage = threadMessage
        self.recommendGroup = recommendGroup
        self.type = type
    }
}

public enum GroupJoinState {
    case loading
    case notJoined
    case applied
    case joined
}

public final class ThreadRecommendedGroupItem: ModelProtocol {
    /// save chatID
    public let itemID: String
    /// had i18n
    public let name: String
    /// avatarKey
    public let avatarKey: String
    /// join group state
    public let joinState: GroupJoinState
    /// users
    public let relatedUsers: [RustPB.Im_V1_RecommendedGroupItem.RelatedUser]
    /// group total count
    public let userCount: Int32

    public init(
        itemID: String,
        name: String,
        avatarKey: String,
        joinState: GroupJoinState,
        relatedUsers: [RustPB.Im_V1_RecommendedGroupItem.RelatedUser],
        userCount: Int32
    ) {
        self.itemID = itemID
        self.name = name
        self.avatarKey = avatarKey
        self.joinState = joinState
        self.relatedUsers = relatedUsers
        self.userCount = userCount
    }

    public static func transform(pb: Im_V1_RecommendedGroupItem) -> ThreadRecommendedGroupItem {
        let joinGroupState: GroupJoinState
        switch pb.joinState {
        case .unknown:
            joinGroupState = .notJoined
        case .notJoined:
            joinGroupState = .notJoined
        case .joined:
            joinGroupState = .joined
        case .applied:
            joinGroupState = .applied
        @unknown default:
            assert(false, "new value")
            joinGroupState = .notJoined
        }
        return ThreadRecommendedGroupItem(
            itemID: pb.itemID,
            name: pb.name,
            avatarKey: pb.avatarKey,
            joinState: joinGroupState,
            relatedUsers: pb.relatedUsers,
            userCount: pb.userCount
        )
    }

    public static func transform(recommendedGroups: [Im_V1_RecommendedGroupItem]) -> [ThreadRecommendedGroupItem] {
        var groups = [ThreadRecommendedGroupItem]()
        recommendedGroups.forEach { (pb) in
            groups.append(ThreadRecommendedGroupItem.transform(pb: pb))
        }

        return groups
    }
}

// TopicGroup is depending on chat in this time(Oct 2019). This class is binding TopicGroup and Chat, and will be
// deprecated after decoupling.
public final class TopicGroupWithChat {
    public init(topicGroup: TopicGroup?, chat: Chat) {
        self.topicGroup = topicGroup
        self.chat = chat
    }

    private let topicGroup: TopicGroup?
    // some existing view model need Chat, so we public it
    public let chat: Chat

    public var isDefaultTopicGroup: Bool {
        return topicGroup?.isDefaultTopicGroup ?? false
    }
}

public final class TopicGroup: ModelProtocol {
    public typealias PBModel = RustPB.Basic_V1_TopicGroup
    public typealias UserSetting = Basic_V1_TopicGroup.UserSetting
    public typealias TopicGroupType = RustPB.Basic_V1_TopicGroup.TypeEnum

    public let id: String
    public let type: TopicGroupType
    public let userSetting: UserSetting

    public var isDefaultTopicGroup: Bool {
        return type == .default
    }

    public var isParticipant: Bool {
        return userSetting.topicGroupRole == .participant
    }

    /// 在ThreadChat 和 ThreadDetail 入口中，强依赖TopicGroup。服务端有风险可能出现不会返回TopicGroup的异常，增加defaultTopicGroup作为兜底。
    public static func defaultTopicGroup(id: String) -> TopicGroup {
        return TopicGroup(id: id, type: .normal, userSetting: UserSetting())
    }

    internal init(id: String, type: TopicGroupType, userSetting: UserSetting) {
        self.id = id
        self.type = type
        self.userSetting = userSetting
    }

    public static func transform(pb: PBModel) -> TopicGroup {
        return TopicGroup(
            id: pb.id,
            type: pb.type,
            userSetting: pb.userSetting
        )
    }

    public static func transform(fromEntity entity: RustPB.Basic_V1_Entity, topicGroupIDs: [String]) -> [TopicGroup] {
        var topicGroups = [TopicGroup]()
        for topicGroupID in topicGroupIDs {
            if let pb = entity.topicGroups[topicGroupID] {
                let topicGroup = transform(pb: pb)
                topicGroups.append(topicGroup)
            }
        }

        return topicGroups
    }
}
