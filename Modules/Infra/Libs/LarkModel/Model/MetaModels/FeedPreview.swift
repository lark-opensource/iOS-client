//
//  FeedPreview.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/9/12.
//

import Foundation
import RustPB
import SwiftProtobuf

public struct FeedPreview: Equatable {
    public let id: String
    // 给外界提供 preview，目前用于序列化数据存储在端上
    public var preview: Feed_V1_FeedEntityPreview {
        return _previewPb
    }
    // 内部用于判等
    private var _previewPb: Feed_V1_FeedEntityPreview
    public var basicMeta: FeedPreviewBasicMeta
    public var uiMeta: FeedPreviewUIMeta
    public let extraMeta: FeedPreviewExtraMeta

    public mutating func updateAvatar(key: String) {
        // 需要同步修改pb中的updateTime，因为【判等】或许会使用到
        _previewPb.threadData.avatarKey = key
        uiMeta.avatarKey = key
    }

    public mutating func updateUpdateTime(timestamp: Int) {
        // 需要同步修改pb中的updateTime，因为【判等】或许会使用到
        _previewPb.updateTime = Int64(timestamp)
        basicMeta.updateTime = timestamp
    }

    // TODO: 暂时兼容下，后续在7.3版本删除
    public let chatFeedPreview: ChatFeedPreview?
    public var isRemind: Bool {
        basicMeta.isRemind
    }
    public var type: Basic_V1_FeedCard.EntityType {
        basicMeta.feedPreviewPBType
    }
    public var chatType: Basic_V1_Chat.TypeEnum {
        preview.chatData.chatType
    }
    public var isCrypto: Bool {
        preview.chatData.isCrypto
    }
    public var lastMessageType: Basic_V1_Message.TypeEnum {
        preview.chatData.lastMessageType
    }
    public var lastVisibleMessageID: String {
        preview.chatData.lastVisibleMessageID
    }
    public var docURL: String {
        preview.docData.docURL
    }

    init(previewPb: Feed_V1_FeedEntityPreview,
         basicMeta: FeedPreviewBasicMeta,
         uiMeta: FeedPreviewUIMeta,
         extraMeta: FeedPreviewExtraMeta,
         chatFeedPreview: ChatFeedPreview? = nil) {
        // 基础字段
        self.id = previewPb.feedID
        self._previewPb = previewPb
        self.basicMeta = basicMeta
        self.uiMeta = uiMeta
        self.extraMeta = extraMeta
        self.chatFeedPreview = chatFeedPreview
    }

    // 判等，目前用于UI reload 中的 diff
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs._previewPb == rhs._previewPb
    }
}

// MARK: 基础字段
public extension FeedPreview {
    struct FeedPreviewBasicMeta {
        // feed card所属大的集合类型
        public let feedCardBaseCategory: Basic_V1_FeedCard.FeedType
        // feed card类型
        public let feedPreviewPBType: Basic_V1_FeedCard.EntityType
        // feed card类型
        public var feedCardType: FeedPreviewType
        // 新增的基础字段
        public let bizId: String
        // 排序字段
        public let rankTime: Int
        public let onTopRankTime: Int

        // 是否属于折叠盒子里的feed
        public let parentCardID: String
        // 是否被置顶
        public let isShortcut: Bool
        // 是否被标记
        public let isFlaged: Bool
        // 是否开启免打扰
        public let isRemind: Bool
        // 未读数
        public let unreadCount: Int
        // version，保证数据更新正确（实际为时间戳）
        public var updateTime: Int
        // 用户数据检查
        public let checker: FeedPreviewChecker

        init(previewPb: Feed_V1_FeedEntityPreview,
             feedPreviewPBType: Basic_V1_FeedCard.EntityType,
             bizId: String,
             rankTime: Int,
             isShortcut: Bool,
             isRemind: Bool,
             unreadCount: Int) {
            self.feedCardBaseCategory = previewPb.feedType
            self.feedPreviewPBType = feedPreviewPBType
            if feedPreviewPBType == .appFeed {
                self.feedCardType = FeedPreviewType.transform(pbType: previewPb.appFeedCardData.type)
            } else {
                self.feedCardType = FeedPreviewType.transform(pbType: feedPreviewPBType)
            }
            self.bizId = bizId
            self.rankTime = rankTime
            self.onTopRankTime = Int(previewPb.onTopRankTime)
            self.parentCardID = previewPb.parentCardID
            self.isShortcut = isShortcut
            self.isFlaged = previewPb.isFlag
            self.isRemind = isRemind
            self.unreadCount = unreadCount
            self.updateTime = Int(previewPb.updateTime)
            self.checker = FeedPreviewChecker(userID: previewPb.userID, checkUser: previewPb.checkUser)
        }
    }
}

// MARK: 基础 UI 字段
public extension FeedPreview {
    struct FeedPreviewUIMeta {
        // 标题
        public let name: String
        // 头像
        public let miniAvatarKey: String
        public var avatarKey: String
        // Tag
        public let tagDataItems: [Basic_V1_TagData.TagDataItem]
        // 显示的时间
        public let displayTime: Int
        // 副标题
        public let subtitle: String
        // reaction，目前只有chat、thread、doc在用
        public let reactions: [Basic_V1_Message.Reaction]
        // 草稿状态
        public let draft: FeedPreviewDraft
        // 摘要状态
        public let digestStatus: FeedPreviewDigestStatus
        // 摘要内容
        public let digestText: String
        public let digest: Feed_V1_Digest

        // at 人，目前只有chat、thread、doc在用
        public let mention: FeedPreviewMention
        
        // 状态标签
        public let statusLabel: FeedStatusLabel

        // 按钮
        public let buttonData: FeedCardButtonData

        init(name: String,
             miniAvatarKey: String,
             avatarKey: String,
             tagDataItems: [Basic_V1_TagData.TagDataItem],
             displayTime: Int,
             subtitle: String,
             reactions: [Basic_V1_Message.Reaction],
             draft: FeedPreviewDraft,
             digestStatus: FeedPreviewDigestStatus,
             digestText: String,
             digest: Feed_V1_Digest,
             mention: FeedPreviewMention,
             statusLabel: FeedStatusLabel,
             buttonData: FeedCardButtonData) {
            self.name = name
            self.miniAvatarKey = miniAvatarKey
            self.avatarKey = avatarKey
            self.tagDataItems = tagDataItems
            self.displayTime = displayTime
            self.subtitle = subtitle
            self.reactions = reactions
            self.draft = draft
            self.digestStatus = digestStatus
            self.digestText = digestText
            self.digest = digest
            self.mention = mention
            self.statusLabel = statusLabel
            self.buttonData = buttonData
        }
    }
}

// MARK: 额外的数据
public extension FeedPreview {
    struct FeedPreviewExtraMeta {
        // 是否是跨租户，目前只有chat和doc在用
        public let crossTenant: Bool
        // 业务数据
        public let bizPb: Feed_V1_AppFeedCard.ExtraData
        init(crossTenant: Bool,
             bizPb: Feed_V1_AppFeedCard.ExtraData) {
            self.crossTenant = crossTenant
            self.bizPb = bizPb
        }
    }
}

// MARK: 转换 Feed_V1_FeedEntityPreview -> FeedPreview
extension FeedPreview {
    public static func transformByEntityPreview(_ previewPb: Feed_V1_FeedEntityPreview) -> FeedPreview {
        switch previewPb.extraData {
        case .chatData(let chatData):
            return Self.get(chatData: chatData, previewPb: previewPb)
        case .docData(let docData):
            return Self.get(docData: docData, previewPb: previewPb)
        case .threadData(let threadData):
            return Self.get(threadData: threadData, previewPb: previewPb)
        case .openAppData(let microAppData):
            return Self.get(microAppData: microAppData, previewPb: previewPb)
        case .boxData(let boxData):
            return Self.get(boxData: boxData, previewPb: previewPb)
        case .subscriptionsData(let subscriptionData):
            return Self.get(subscriptionData: subscriptionData, previewPb: previewPb)
        case .appFeedCardData(let universalFeedData):
            return Self.get(universalFeedData: universalFeedData, previewPb: previewPb)
        case .none:
            return Self.get(universalFeedData: Feed_V1_AppFeedCard(), previewPb: previewPb)
        @unknown default:
            return Self.get(universalFeedData: Feed_V1_AppFeedCard(), previewPb: previewPb)
        }
    }

    private static func get(universalFeedData: Feed_V1_AppFeedCard, previewPb: Feed_V1_FeedEntityPreview) -> FeedPreview {
        let basicMeta = FeedPreviewBasicMeta(
            previewPb: previewPb,
            feedPreviewPBType: .appFeed,
            bizId: universalFeedData.bizID,
            rankTime: Int(universalFeedData.feedDefaultData.rankTime),
            isShortcut: universalFeedData.feedDefaultData.isShortcut,
            isRemind: !universalFeedData.settingData.mute,
            unreadCount: Int(universalFeedData.badgeData.badge))

        let ms: Int64 = 1000
        let statusLabel = FeedStatusLabel(text: universalFeedData.statusLabelData.label.text,
                                          type: universalFeedData.statusLabelData.label.type)
        let buttonData = FeedCardButtonData(buttonData: universalFeedData.buttonData)
        let uiMeta = FeedPreviewUIMeta(name: universalFeedData.titleData.title,
                                       miniAvatarKey: "",
                                       avatarKey: universalFeedData.avatarData.avatar.key,
                                       tagDataItems: [],
                                       displayTime: Int(universalFeedData.displayTimeData.displayTimeMs / ms),
                                       subtitle: "",
                                       reactions: [],
                                       draft: .default(),
                                       digestStatus: .default(),
                                       digestText: universalFeedData.previewData.preview,
                                       digest: .init(),
                                       mention: .default(),
                                       statusLabel: statusLabel,
                                       buttonData: buttonData)

        let extraMeta = FeedPreviewExtraMeta(
            crossTenant: false,
            bizPb: universalFeedData.bizExtraData)

        return FeedPreview(
                    previewPb: previewPb,
                    basicMeta: basicMeta,
                    uiMeta: uiMeta,
                    extraMeta: extraMeta)
    }

    private static func get(chatData: Feed_V1_ChatData, previewPb: Feed_V1_FeedEntityPreview) -> FeedPreview {
        let basicMeta = FeedPreviewBasicMeta(
            previewPb: previewPb,
            feedPreviewPBType: .chat,
            bizId: "",
            rankTime: Int(chatData.rankTime),
            isShortcut: chatData.isShortcut,
            isRemind: chatData.isRemind,
            unreadCount: Int(chatData.unreadCount))

        let atInfo = FeedPreviewAt.transform(atInfo: chatData.atInfo)
        let mention = FeedPreviewMention(hasAtInfo: chatData.hasAtInfo,
                                                atInfo: atInfo,
                                                atInfosCount: Int(chatData.atInfosCount))

        let draft = FeedPreviewDraft.transform(draft: chatData.draftPreview)
        let digestStatus = FeedPreviewDigestStatus.transform(entityStatus: chatData.entityStatus)
        let buttonData = FeedCardButtonData(buttonData: previewPb.buttonData)
        let uiMeta = FeedPreviewUIMeta(name: chatData.name,
                                       miniAvatarKey: chatData.miniAvatarKey,
                                       avatarKey: chatData.avatarKey,
                                       tagDataItems: chatData.tagInfo.tagDataItems,
                                       displayTime: Int(chatData.displayTime),
                                       subtitle: "",
                                       reactions: chatData.reactions,
                                       draft: draft,
                                       digestStatus: digestStatus,
                                       digestText: chatData.localizedDigestMessage,
                                       digest: chatData.digest,
                                       mention: mention,
                                       statusLabel: .default(),
                                       buttonData: buttonData)

        let extraMeta = FeedPreviewExtraMeta(
            crossTenant: chatData.crossTenant,
            bizPb: .init())

        let teamNames = chatData.joinedTeamInfos.sorted(by: {
            $0.orderWeight < $1.orderWeight
        }).compactMap {
            chatData.joinedTeams[$0.teamID]?.name
        }
        let teamsChatType = Dictionary.init(chatData.joinedTeamInfos.compactMap {
            return ($0.teamID, $0.teamChatType)
        }) { $1 }
        let teamEntity = ChatFeedPreview.TeamEntity(teamsName: teamNames,
                                    joinedTeams: chatData.joinedTeams,
                                    teamsChatType: teamsChatType)

        let chatFeedPreview = ChatFeedPreview(teamEntity: teamEntity)

        return FeedPreview(
                    previewPb: previewPb,
                    basicMeta: basicMeta,
                    uiMeta: uiMeta,
                    extraMeta: extraMeta,
                    chatFeedPreview: chatFeedPreview)
    }

    private static func get(docData: Feed_V1_DocData, previewPb: Feed_V1_FeedEntityPreview) -> FeedPreview {
        let basicMeta = FeedPreviewBasicMeta(
            previewPb: previewPb,
            feedPreviewPBType: .docFeed,
            bizId: "",
            rankTime: Int(docData.rankTime),
            isShortcut: docData.isShortcut,
            isRemind: docData.isRemind,
            unreadCount: Int(docData.unreadCount))

        let atInfo = FeedPreviewAt.transform(atInfo: docData.atInfo)
        let mention = FeedPreviewMention(hasAtInfo: docData.hasAtInfo,
                                                atInfo: atInfo,
                                                atInfosCount: Int(docData.atInfosCount))
        let uiMeta = FeedPreviewUIMeta(name: docData.name,
                                       miniAvatarKey: "",
                                       avatarKey: "",
                                       tagDataItems: docData.tagInfo.tagDataItems,
                                       displayTime: Int(docData.displayTime),
                                       subtitle: "",
                                       reactions: docData.reactions,
                                       draft: .default(),
                                       digestStatus: .default(),
                                       digestText: docData.localizedDigestMessage,
                                       digest: docData.digest,
                                       mention: mention,
                                       statusLabel: .default(),
                                       buttonData: .default())

        let extraMeta = FeedPreviewExtraMeta(
            crossTenant: docData.crossTenant,
            bizPb: .init())

        return FeedPreview(
                    previewPb: previewPb,
                    basicMeta: basicMeta,
                    uiMeta: uiMeta,
                    extraMeta: extraMeta)
    }

    private static func get(threadData: Feed_V1_ThreadData, previewPb: Feed_V1_FeedEntityPreview) -> FeedPreview {
        var type = Basic_V1_FeedCard.EntityType.thread
        switch threadData.entityType {
        case .thread, .msgThread:
            type = .thread
        case .topic:
            type = .topic
        @unknown default:
            assertionFailure("unknow type")
        }

        let basicMeta = FeedPreviewBasicMeta(
            previewPb: previewPb,
            feedPreviewPBType: type,
            bizId: "",
            rankTime: Int(threadData.rankTime),
            isShortcut: false,
            isRemind: threadData.isRemind,
            unreadCount: Int(threadData.unreadCount))

        let atInfo = FeedPreviewAt.transform(atInfo: threadData.atInfo)
        let mention = FeedPreviewMention(hasAtInfo: threadData.hasAtInfo,
                                         atInfo: atInfo,
                                         atInfosCount: Int(threadData.atInfosCount))

        let draft = FeedPreviewDraft.transform(draft: threadData.draftPreview)
        let digestStatus = FeedPreviewDigestStatus.transform(entityStatus: threadData.entityStatus)
        let uiMeta = FeedPreviewUIMeta(name: threadData.name,
                                       miniAvatarKey: "",
                                       avatarKey: threadData.avatarKey,
                                       tagDataItems: [],
                                       displayTime: Int(threadData.displayTime),
                                       subtitle: "",
                                       reactions: threadData.reactions,
                                       draft: draft,
                                       digestStatus: digestStatus,
                                       digestText: threadData.localizedDigestMessage,
                                       digest: threadData.digest,
                                       mention: mention,
                                       statusLabel: .default(),
                                       buttonData: .default())

        let extraMeta = FeedPreviewExtraMeta(
            crossTenant: false,
            bizPb: .init())

        return FeedPreview(
                    previewPb: previewPb,
                    basicMeta: basicMeta,
                    uiMeta: uiMeta,
                    extraMeta: extraMeta)
    }

    private static func get(microAppData: Feed_V1_OpenAppData, previewPb: Feed_V1_FeedEntityPreview) -> FeedPreview {
        let basicMeta = FeedPreviewBasicMeta(
            previewPb: previewPb,
            feedPreviewPBType: .openapp,
            bizId: "",
            rankTime: Int(microAppData.rankTime),
            isShortcut: microAppData.isShortcut,
            isRemind: microAppData.isRemind,
            unreadCount: Int(microAppData.unreadCount))

        let uiMeta = FeedPreviewUIMeta(name: microAppData.name,
                                       miniAvatarKey: "",
                                       avatarKey: microAppData.avatarKey,
                                       tagDataItems: [],
                                       displayTime: Int(microAppData.displayTime),
                                       subtitle: "",
                                       reactions: [],
                                       draft: .default(),
                                       digestStatus: .default(),
                                       digestText: microAppData.localizedDigestMessage,
                                       digest: microAppData.digest,
                                       mention: .default(),
                                       statusLabel: .default(),
                                       buttonData: .default())

        let extraMeta = FeedPreviewExtraMeta(
            crossTenant: false,
            bizPb: .init())
        return FeedPreview(
                    previewPb: previewPb,
                    basicMeta: basicMeta,
                    uiMeta: uiMeta,
                    extraMeta: extraMeta)
    }

    private static func get(boxData: Feed_V1_BoxData, previewPb: Feed_V1_FeedEntityPreview) -> FeedPreview {
        let basicMeta = FeedPreviewBasicMeta(
            previewPb: previewPb,
            feedPreviewPBType: .box,
            bizId: "",
            rankTime: Int(boxData.rankTime),
            isShortcut: boxData.isShortcut,
            isRemind: boxData.isRemind,
            unreadCount: Int(boxData.unreadCount))
        let atInfo = FeedPreviewAt.transform(atInfo: boxData.atInfo)
        let mention = FeedPreviewMention(
            hasAtInfo: boxData.hasAtInfo,
            atInfo: atInfo,
            atInfosCount: Int(boxData.atInfos.count))
        let uiMeta = FeedPreviewUIMeta(name: "",
                                       miniAvatarKey: "",
                                       avatarKey: "",
                                       tagDataItems: [],
                                       displayTime: Int(boxData.displayTime),
                                       subtitle: "",
                                       reactions: [],
                                       draft: .default(),
                                       digestStatus: .default(),
                                       digestText: boxData.localizedDigestMessage,
                                       digest: boxData.digest,
                                       mention: mention,
                                       statusLabel: .default(),
                                       buttonData: .default())

        let extraMeta = FeedPreviewExtraMeta(
            crossTenant: false,
            bizPb: .init())

        return FeedPreview(
                    previewPb: previewPb,
                    basicMeta: basicMeta,
                    uiMeta: uiMeta,
                    extraMeta: extraMeta)
    }

    private static func get(subscriptionData: Feed_V1_SubscriptionsData, previewPb: Feed_V1_FeedEntityPreview) -> FeedPreview {

        let basicMeta = FeedPreviewBasicMeta(
            previewPb: previewPb,
            feedPreviewPBType: .subscription,
            bizId: "",
            rankTime: Int(subscriptionData.rankTime),
            isShortcut: subscriptionData.isShortcut,
            isRemind: subscriptionData.isRemind,
            unreadCount: Int(subscriptionData.unreadCount))
        let uiMeta = FeedPreviewUIMeta(name: subscriptionData.name,
                                       miniAvatarKey: "",
                                       avatarKey: subscriptionData.avatarKey,
                                       tagDataItems: [],
                                       displayTime: Int(subscriptionData.displayTime),
                                       subtitle: "",
                                       reactions: [],
                                       draft: .default(),
                                       digestStatus: .default(),
                                       digestText: subscriptionData.localizedDigestMessage,
                                       digest: subscriptionData.digest,
                                       mention: .default(),
                                       statusLabel: .default(),
                                       buttonData: .default())

        let extraMeta = FeedPreviewExtraMeta(
            crossTenant: false,
            bizPb: .init())
        return FeedPreview(
                    previewPb: previewPb,
                    basicMeta: basicMeta,
                    uiMeta: uiMeta,
                    extraMeta: extraMeta)
    }
}

// MARK: 具体的业务场景中的转换
extension FeedPreview {
    // 数组转换
    public static func transforms(_ entityPreviews: [Feed_V1_FeedEntityPreview]) -> [FeedPreview] {
        entityPreviews.map { Self.transformByEntityPreview($0) }
    }

    // 字典转换
    public static func transforms(_ entityPreviews: [String: Feed_V1_FeedEntityPreview]) -> [FeedPreview] {
        entityPreviews.map { Self.transformByEntityPreview($0.value) }
    }

    // 用于 shortcut 中的转换
    public static func transform(id: String, entityPreviews: [String: Feed_V1_FeedEntityPreview]) -> FeedPreview? {
        if let preview = entityPreviews[id] {
            return Self.transformByEntityPreview(preview)
        }
        return nil
    }

    // 用于 markLater 中的转换
    public static func transform(delayedResponse: Feed_V1_SetFeedCardPreviewDelayedResponse) -> FeedPreview {
        return Self.transformByEntityPreview(delayedResponse.feedEntityPreview)
    }
}

// MARK: 端上创建的对应的结构
public enum FeedPreviewType: Int {
    public static let boundaryNumber = 1000
    case unknown = 0,
         chat = 1,
         docFeed = 3,
         thread = 4,
         box = 5,
         microApp = 6,
         topic = 7,
         subscription = 10,
         msgThread = 11,
         appFeed = 13,
         mailFeed = 1001,
         calendar = 1002,
         openAppFeed = 1003

    public static func transform(pbType: Basic_V1_FeedCard.EntityType) -> FeedPreviewType {
        guard let feedCardType = FeedPreviewType(rawValue: pbType.rawValue) else {
            return .unknown
        }
        return feedCardType
    }

    public static func transform(pbType: Feed_V1_AppFeedCardType) -> FeedPreviewType {
        guard let feedCardType = FeedPreviewType(rawValue: Self.boundaryNumber + pbType.rawValue) else {
            return .unknown
        }
        return feedCardType
    }
}

// 排序结构
public enum FeedCardRankTime {
    case topRankTime(Int)   // 级别最高, 返回 feedPreview.basicMeta.onTopRankTime
    case rankTime(Int)      // 级别默认, 返回 feedPreview.basicMeta.rankTime

    public static func > (lhs: FeedCardRankTime, rhs: FeedCardRankTime) -> Bool {
        switch (lhs, rhs) {
        case (.topRankTime(let lt), .topRankTime(let rt)): return lt > rt
        case (.rankTime(let lt), .rankTime(let rt)): return lt > rt
        case (.topRankTime, .rankTime): return true
        case (.rankTime, .topRankTime): return false
        }
    }

    public static func == (lhs: FeedCardRankTime, rhs: FeedCardRankTime) -> Bool {
        switch (lhs, rhs) {
        case (.topRankTime(let lt), .topRankTime(let rt)): return lt == rt
        case (.rankTime(let lt), .rankTime(let rt)): return lt == rt
        default: return false
        }
    }

    public static func != (lhs: FeedCardRankTime, rhs: FeedCardRankTime) -> Bool {
        return !(lhs == rhs)
    }
}

// 实体增加 user_id 校验
public struct FeedPreviewChecker {
    public let userID: Int64
    public let checkUser: Bool

    public init(userID: Int64, checkUser: Bool) {
        self.userID = userID
        self.checkUser = checkUser
    }

    public static func `default`() -> FeedPreviewChecker {
        return FeedPreviewChecker(userID: 0, checkUser: false)
    }

    public var description: String {
        "checkUser: \(self.checkUser), userID: \(self.userID)"
    }
}

public struct FeedPreviewDraft {
    public var content: String
    public init(content: String) {
        self.content = content
    }

    public static func transform(draft: Feed_V1_DraftPreview) -> FeedPreviewDraft {
        return FeedPreviewDraft(content: draft.content)
    }

    public static func `default`() -> FeedPreviewDraft {
        return FeedPreviewDraft(content: "")
    }
}

public enum FeedPreviewDigestStatus: Int {
    case normal = 1
    case pending = 2
    case failed = 3
    case read = 4
    case unread = 5

    public static func transform(entityStatus: Feed_V1_EntityStatus) -> FeedPreviewDigestStatus {
        return FeedPreviewDigestStatus(rawValue: entityStatus.rawValue) ?? .normal
    }

    public static func `default`() -> FeedPreviewDigestStatus {
        return .normal
    }
}

public struct FeedPreviewMention {
    // at 人，目前只有chat、thread、doc在用
    public let hasAtInfo: Bool
    public let atInfo: FeedPreviewAt
    public let atInfosCount: Int

    public static func `default`() -> FeedPreviewMention {
        return FeedPreviewMention(hasAtInfo: false,
                                  atInfo: .default(),
                                  atInfosCount: 0)
    }

    public var description: String {
        return "hasAt: \(hasAtInfo ? ("\(atInfo.type), count: \(atInfosCount)"): "false") "
    }
}

public struct FeedPreviewAt {
    public enum AtType: Int {
        case all = 1
        case user = 2
    }

    public var type: AtType
    public var channelName: String
    public var avatarKey: String
    public var userID: String
    public var localizedUserName: String
    public var atContent: String
    public var atDisplayTime: Int
    public var atRankTime: Int

    public init(type: AtType,
                channelName: String,
                avatarKey: String,
                userID: String,
                localizedUserName: String,
                atContent: String,
                atDisplayTime: Int,
                atRankTime: Int) {
        self.type = type
        self.channelName = channelName
        self.avatarKey = avatarKey
        self.userID = userID
        self.localizedUserName = localizedUserName
        self.atContent = atContent
        self.atDisplayTime = atDisplayTime
        self.atRankTime = atRankTime
    }

    // Feed_V1_AtInfo -> FeedPreviewMention
    public static func transform(atInfo: Feed_V1_AtInfo) -> FeedPreviewAt {
        let type = FeedPreviewAt.AtType(rawValue: atInfo.type.rawValue)
        if type == nil {
            assertionFailure("AtInfo's types do not match exactly")
        }
        return FeedPreviewAt(type: type ?? .all,
                                 channelName: atInfo.channelName,
                                 avatarKey: atInfo.avatarKey,
                                 userID: atInfo.userID,
                                 localizedUserName: atInfo.localizedUserName,
                                 atContent: atInfo.atContent,
                                 atDisplayTime: Int(atInfo.atDisplayTime),
                                 atRankTime: Int(atInfo.atRankTime))
    }

    public static func transform(atInfos: [Feed_V1_AtInfo]) -> [FeedPreviewAt] {
        return atInfos.map({ atInfo in
            return transform(atInfo: atInfo)
        })
    }

    public static func `default`() -> FeedPreviewAt {
        return FeedPreviewAt(type: .all,
                             channelName: "",
                             avatarKey: "",
                             userID: "",
                             localizedUserName: "",
                             atContent: "",
                             atDisplayTime: 0,
                             atRankTime: 0)
    }
}

public struct ChatFeedPreview {
    public struct TeamEntity {
        public let teamsName: [String]
        public let joinedTeams: [Int64: Basic_V1_Team]
        public let teamsChatType: [Int64: Basic_V1_TeamChatType]

        public init(teamsName: [String],
                    joinedTeams: [Int64: Basic_V1_Team],
                    teamsChatType: [Int64: Basic_V1_TeamChatType]) {
            self.teamsName = teamsName
            self.joinedTeams = joinedTeams
            self.teamsChatType = teamsChatType
        }

        public static func `default`() -> TeamEntity {
            return TeamEntity(teamsName: [], joinedTeams: [:], teamsChatType: [:])
        }
    }

    public let teamEntity: TeamEntity

    public init(teamEntity: TeamEntity) {
        self.teamEntity = teamEntity
    }
}

public struct FeedStatusLabel {
    public enum LabelType: Int {
        case unknownLabelType // = 0
        /// 蓝色
        case primary // = 1
        /// 灰色
        case secondary // = 2
        /// 绿色
        case success // = 3
    }
    public let text: String
    public let type: LabelType
    public var isValid: Bool {
        return (!text.isEmpty && type != .unknownLabelType)
    }
    init(text: String, type: Feed_V1_FeedStatusLabel.LabelType) {
        self.text = text
        self.type = LabelType(rawValue: type.rawValue) ?? .unknownLabelType
    }
    public static func `default`() -> FeedStatusLabel {
        return FeedStatusLabel(text: "", type: .unknownLabelType)
    }
    public var description: String {
        return "text: \(text), type: \(type) "
    }
}

public struct FeedCardButton {
    public enum ActionType: Int {
        case unknown // = 0
        ///跳转
        case urlPage // = 1
        ///回传
        case webhook // = 2
    }
    public enum ButtonType: Int {
        case unknownButtonType // = 0
        // 灰色
        case `default` // = 1
        // 蓝色
        case primary // = 2
        // 绿色
        case success // = 3
    }
    public let id: String
    public let actionType: ActionType
    public let buttonType: ButtonType
    public let text: String
    public let url: String
    init(button: Basic_V1_AppFeedCardButton) {
        self.id = button.id
        self.actionType = ActionType(rawValue: button.actionType.rawValue) ?? .unknown
        self.buttonType = ButtonType(rawValue: button.buttonType.rawValue) ?? .unknownButtonType
        self.text = button.text.content
        if !button.multiURL.iosURL.isEmpty {
            self.url = button.multiURL.iosURL
        } else {
            self.url = button.multiURL.url
        }
    }
    public static func `default`() -> FeedCardButton {
        return FeedCardButton(button: Basic_V1_AppFeedCardButton())
    }
    public var description: String {
        return "id: \(id), actionType: \(actionType), buttonType: \(buttonType), text: \(text)"
    }
}

extension FeedCardButton: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return (lhs.id == rhs.id &&
        lhs.actionType == rhs.actionType &&
        lhs.buttonType == rhs.buttonType &&
        lhs.text == rhs.text &&
        lhs.url == rhs.url)
    }
}

public struct FeedCardButtonData {
    public let firstButton: FeedCardButton?
    public let secondButton: FeedCardButton?

    init(buttonData: Basic_V1_FeedButtonData) {
        if buttonData.buttons.count >= 1 {
            self.firstButton = FeedCardButton(button: buttonData.buttons[0])
            if buttonData.buttons.count >= 2 {
                self.secondButton = FeedCardButton(button: buttonData.buttons[1])
            } else {
                self.secondButton = nil
            }
        } else {
            self.firstButton = nil
            self.secondButton = nil
        }
    }
    public static func `default`() -> FeedCardButtonData {
        return FeedCardButtonData(buttonData: Basic_V1_FeedButtonData())
    }
    public var description: String {
        return "first: \(firstButton?.description ?? ""), second: \(secondButton?.description ?? "")"
    }
}

extension FeedCardButtonData: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.firstButton == rhs.firstButton && lhs.secondButton == rhs.secondButton
    }
}
