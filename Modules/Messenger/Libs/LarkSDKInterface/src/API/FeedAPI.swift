//
//  FeedAPI.swift
//  Lark
//
//  Created by Yuguo on 2017/11/6.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import LarkModel
import RustPB
import ServerPB
import LKCommonsLogging

public protocol FeedAPI {
    // MARK: feeds列表数据
    // 拉取feeds列表数据
    func getFeedCardsV4(filterType: Feed_V1_FeedFilter.TypeEnum,
                        boxId: Int?,
                        cursor: Feed_V1_FeedCursor?,
                        count: Int,
                        spanID: UInt64?,
                        feedRuleMd5: String,
                        traceId: String) -> Observable<GetFeedCardsResult>

    func getFeedCards(filterType: Feed_V1_FeedFilter.TypeEnum,
                      pullType: FeedPullType,
                      feedCardID: String?,
                      cursor: Int?,
                      spanID: UInt64?,
                      count: Int) -> Observable<GetFeedCardsResult>

    // MARK: 找未读
    // 获取下一批未读列表
    func getNextUnreadFeedCardsV4(filterType: Feed_V1_FeedFilter.TypeEnum,
                                  cursor: Feed_V1_FeedCursor?,
                                  feedRuleMd5: String,
                                  traceId: String) -> Observable<NextUnreadFeedCardsResult>

    // MARK: 会话盒子
    func setFeedCardsIntoBox(feedCardId: String) -> Observable<String>

    func deleteFeedCardsFromBox(feedCardId: String, isRemind: Bool) -> Observable<Void>

    // MARK: 置顶
    func loadShortcuts(strategy: Basic_V1_SyncDataStrategy) -> Observable<FeedContextResponse>

    func createShortcuts(_ shortcuts: [RustPB.Feed_V1_Shortcut]) -> Observable<Void>

    func deleteShortcuts(_ shortcuts: [RustPB.Feed_V1_Shortcut]) -> Observable<Void>

    func update(shortcut: RustPB.Feed_V1_Shortcut, newPosition: Int) -> Observable<Void>

    // MARK: 对单个feed的操作
    func removeFeedCard(channel: RustPB.Basic_V1_Channel,
                        feedType: RustPB.Basic_V1_FeedCard.EntityType?) -> Observable<Void>

    func peakFeedCard(by id: String, entityType: RustPB.Basic_V1_FeedCard.EntityType) -> Observable<Void>

    func moveToDone(feedId: String, entityType: RustPB.Basic_V1_FeedCard.EntityType) -> Observable<Void>

    func flagFeedCard(_ id: String, isFlaged: Bool, entityType: Basic_V1_FeedCard.EntityType) -> Observable<Void>

    func markFeedCard(_ id: String, isDelayed: Bool) -> Observable<FeedPreview>
    func markChatLaunch(feedId: String, entityType: Basic_V1_FeedCard.EntityType)

    // MARK: 开启/关闭提醒功能
    func updateFeedCard(feedId: String, mute: Bool) -> Observable<Void>
    // 开启/关闭群的消息提醒功能
    func updateChatRemind(chatId: String, isRemind: Bool) -> Observable<RustPB.Im_V1_UpdateChatResponse>

    // 开启/关闭订阅号的消息提醒功能
    func updateSubscriptionRemind(subscriptionId: String, isRemind: Bool) -> Single<RustPB.Openplatform_V1_SetSubscriptionNotifyResponse>

// MARK: 预加载
    func preloadFeedCards(by ids: [String], feedPosition: Int32?) -> Observable<Void>

    // MARK: Feed分组
    // 获取筛选列表
    func getFeedFilterSettings(needAll: Bool, tryLocal: Bool) -> Observable<Feed_V1_GetFeedFilterSettingsResponse>

    // 免打扰分组开关
    func updateFeedFilterSettings(filterEnable: Bool, showMute: Bool?) -> Observable<Feed_V1_UpdateFeedFilterSettingsResponse>

    // 更新用户分组
    func updateAtFilterSettings(showAtAllInAtFilter: Bool) -> Observable<Feed_V1_UpdateFeedFilterSettingsResponse>

    // 保存feed分组设置
    func saveFeedFiltersSetting(_ filterEnable: Bool?,
                                _ commonlyUsedFilters: [Feed_V1_FeedFilter]?,
                                _ usedFilters: [Feed_V1_FeedFilter],
                                _ filterDisplayFeedRule: [Int32: Feed_V1_DisplayFeedRule],
                                _ feedGroupDisplayFeedRule: [Int64: Feed_V1_DisplayFeedRule]?)
    -> Observable<Feed_V1_UpdateFeedFilterSettingsResponse>

    // 更新消息分组展示设置
    func updateMsgDisplayRuleMap(_ displayFeedRuleMap: [Int32: Feed_V1_DisplayFeedRule]?,
                                 _ feedGroupDisplayFeedRule: [Int64: Feed_V1_DisplayFeedRule]?)
    -> Observable<Feed_V1_UpdateFeedFilterSettingsResponse>

    // 获取所有bagde：这个接口会触发pushFeed，以pushFeed的通道返回给端上filter badge数据
    func getAllBadge() -> Observable<Feed_V1_GetAllBadgeResponse>

    // MARK: - Feed三栏
    // 获取三栏设置数据
    func getThreeColumnsSettings(tryLocal: Bool) -> Observable<Feed_V1_GetThreeColumnsSettingResponse>

    // 更新三栏设置数据
    func updateThreeColumnsSettings(showEnable: Bool,
                                    scene: Feed_V1_ThreeColumnsSetting.TriggerScene)
    -> Observable<Feed_V1_SetThreeColumnsSettingResponse>

    // 更新常用分组项数据
    func updateCommonlyUsedFilters(_ commonlyUsedFilters: [Feed_V1_FeedFilter]) -> Observable<Feed_V1_UpdateFeedFilterSettingsResponse>

    // 获取未读feeds数量
    func getUnreadFeedsNum() -> Observable<Feed_V1_GetUnreadFeedsResponse>

    // MARK: 标签API
    func getAllLabels(pageCount: Int32,
                      maxTimes: Int) -> Observable<[FeedLabelPreview]>

    // 获取标签列表（一级列表）
    func getLabels(position: Int64?, count: Int32) -> Observable<GetLabelsResponse>

    // 获取指定标签下的child items（二级列表）
    func getLabelFeeds(labelId: Int64, nextCursor: Feed_V1_GroupCursor?, count: Int32, orderBy: Feed_V1_FeedGroupItemOrderRule) -> Observable<GetLabelFeedsResponse>

    // 获取 feed item 所在的标签集合
    func getLabelsForFeed(feedId: String) -> Observable<GetLabelsForFeedResponse>

    // 新建标签，可选添加child item
    func createLabel(labelName: String, feedId: Int64?) -> Observable<CreateLabelResponse>

    // 更新标签信息：排序、删除、自身属性
    func updateLabelInfo(id: Int64, name: String) -> Observable<UpdateLabelResponse>

    // 删除标签
    func deleteLabel(id: Int64) -> Observable<UpdateLabelResponse>

    // 往一个指定的标签里添加多个会话
    func addItemIntoLabel(labelId: Int64, itemIds: [Int64]) -> Observable<UpdateLabelResponse>

    // 添加/删除/更新 label，向label里添加/删除 feed
    func updateLabel(feedId: Int64, updateLabels: [Int64], deleteLabels: [Int64]) -> Observable<UpdateLabelResponse>

    // 删除单个 label 中的 feed
    func deleteLabelFeed(feedId: Int64, labelId: Int64) -> Observable<UpdateLabelResponse>

    // MARK: 团队
    // 拉取团队列表
    func getTeams() -> Observable<GetTeamsResult>

    // 拉取群组列表
    func getChats(parentIDs: [Int]) -> Observable<GetChatsResult>

    func preloadItems(parentIds: [Int]) -> Observable<Im_V1_PreloadItemsResponse>

    // 展示/隐藏群组
    func hideTeamChat(chatId: Int, isHidden: Bool) -> Observable<Im_V1_PatchItemResponse>

// MARK: Feed 按钮
    func appFeedCardButtonCallback(buttonId: String) -> Observable<ServerPB_Feed_AppFeedCardButtonCallbackResponse>

// MARK: 需要迁出去的api
    func setAppNotificationRead(appID: String, seqID: String) -> Observable<Void>

    // MARK: 信噪比相关
    func clearSingleBadge(taskID: String, feeds: [Feed_V1_FeedCardBadgeIdentity]) -> Observable<Void>

    func clearTeamBadge(taskID: String, teams: [Int64]) -> Observable<Void>

    func clearLabelBadge(taskID: String, labels: [Feed_V1_TagIdentity]) -> Observable<Void>

    func clearFilterGroupBadge(taskID: String,
                               filters: [Feed_V1_FeedFilter.TypeEnum]) -> Observable<Void>

    // 查询是否存在 免打扰、at all 提醒的feed
    func getBatchFeedsActionState(feeds: [Feed_V1_FeedCardBadgeIdentity],
                                  filters: [Feed_V1_FeedFilter.TypeEnum],
                                  teams: [Int64],
                                  tags: [Feed_V1_TagIdentity],
                                  queryMuteAtAll: Bool) -> Observable<RustPB.Feed_V1_QueryMuteFeedCardsResponse>
    // 批量操作：免打扰、at all 提醒
    func setBatchFeedsState(taskID: String,
                            feeds: [Feed_V1_FeedCardBadgeIdentity],
                            filters: [Feed_V1_FeedFilter.TypeEnum],
                            teams: [Int64],
                            tags: [Feed_V1_TagIdentity],
                            action: Feed_V1_BatchMuteFeedCardsRequest.MuteActionType) -> Observable<Void>

    // MARK: feed atcion setting
    func getFeedActionSetting(strategy: Basic_V1_SyncDataStrategy) -> Observable<Feed_V1_GetFeedActionSettingResponse>
    func updateFeedActionSetting(setting: Feed_V1_FeedSlideActionSetting) -> Observable<Feed_V1_UpdateFeedActionSettingResponse>
}

// MARK: Feed列表
public typealias FeedAPIProvider = () -> FeedAPI

public enum FeedPullType {
    case refresh
    case loadMore
}

public struct GetFeedCardsResult {
    static let log = Logger.log(GetFeedCardsResult.self, category: "LarkFeedLog")
    public let filterType: Feed_V1_FeedFilter.TypeEnum
    public let feeds: [FeedPreview]
    public let nextCursor: Feed_V1_FeedCursor // loadMore时使用的cursor值，如果为空或者小于等于0均表示已到达DB尽头
    public let timeCost: TimeInterval
    public let tempFeedIds: [String]
    public let feedRuleMd5: String
    public let traceId: String

    public init(filterType: Feed_V1_FeedFilter.TypeEnum,
                feeds: [FeedPreview],
                nextCursor: Feed_V1_FeedCursor,
                timeCost: TimeInterval,
                tempFeedIds: [String],
                feedRuleMd5: String,
                traceId: String) {
        self.filterType = filterType
        self.feeds = feeds
        self.nextCursor = nextCursor
        self.timeCost = timeCost
        self.tempFeedIds = tempFeedIds
        self.feedRuleMd5 = feedRuleMd5
        self.traceId = traceId
    }
}

public struct NextUnreadFeedCardsResult {
    public let filterType: Feed_V1_FeedFilter.TypeEnum
    public let previews: [FeedPreview]
    public let nextCursor: Feed_V1_FeedCursor // 当返回了端上没有的数据，导致端上 next_cursor 发生改变时有值，否则为空
    public let tempFeedIds: [String]
    public let feedRuleMd5: String
    public let traceId: String
    public init(filterType: Feed_V1_FeedFilter.TypeEnum,
                previews: [FeedPreview],
                nextCursor: Feed_V1_FeedCursor,
                tempFeedIds: [String],
                feedRuleMd5: String,
                traceId: String) {
        self.filterType = filterType
        self.previews = previews
        self.nextCursor = nextCursor
        self.tempFeedIds = tempFeedIds
        self.feedRuleMd5 = feedRuleMd5
        self.traceId = traceId
    }
}

public extension Feed_V1_FeedCursor {
    var description: String {
        return "[\(rankTime),\(id)]"
    }

    static var max: Feed_V1_FeedCursor = {
        var cursor = Feed_V1_FeedCursor()
        cursor.rankTime = Int64.max
        cursor.id = 0
        return cursor
    }()
}

public enum FeedChatType: Int {
    case unknown
    case p2p // 单聊
    case group // 群聊
    case threadChat // 话题群

    static func transform(chatType: RustPB.Basic_V1_Chat.TypeEnum, chatMode: RustPB.Basic_V1_Chat.ChatMode) -> FeedChatType {
        if chatMode == .threadV2 {
            return .threadChat
        } else {
            if chatType == .p2P {
                return .p2p
            } else if chatType == .group {
                return .group
            }
        }
        return .unknown
    }
}

public extension FeedPreview {
    var description: String {
        var bizDesc = ""
        switch basicMeta.feedCardType {
        case .chat: bizDesc = chatDesc
        case .thread, .topic, .msgThread: bizDesc = threadDesc
        case .docFeed: bizDesc = docDesc
        case .calendar: bizDesc = calendarDesc
        case .box: break
        case .microApp: break
        case .subscription: break
        case .appFeed: break
        case .mailFeed: break
        case .openAppFeed: break
        case .unknown: break
        @unknown default: break
        }
        return "\(basicDataDescription), \(uiDataDescription), \(bizDesc)"
    }

    var basicDataDescription: String {
        return "id: \(id), "
        + "greaterListType: \(feedCardGreaterListType), "
        + "category: \(basicMeta.feedCardBaseCategory), "
        + "feedCardType: \(basicMeta.feedCardType), "
        + "bizId: \(basicMeta.bizId), "
        + "rankTime: \(basicMeta.rankTime), "
        + "onTopRankTime: \(basicMeta.onTopRankTime), "
        + "isShortcut: \(basicMeta.isShortcut), "
        + "isFlaged: \(basicMeta.isFlaged), "
        + "isRemind: \(basicMeta.isRemind), "
        + "unread: \(basicMeta.unreadCount), "
        + "updateTime: \(basicMeta.updateTime)"
    }

    var uiDataDescription: String {
        return "nameLength: \(uiMeta.name.count), "
        + "hasMiniAvatar: \(!uiMeta.miniAvatarKey.isEmpty), "
        + "hasAvatar: \(!uiMeta.avatarKey.isEmpty), "
        + "tagsCount: \(uiMeta.tagDataItems.count), "
        + "displayTime: \(uiMeta.displayTime), "
        + "subtitleLength: \(uiMeta.subtitle.count), "
        + "reactionCount: \(uiMeta.reactions.count), "
        + "hasDigestText: \(!uiMeta.digestText.isEmpty), "
        + "mentionData: \(uiMeta.mention.description)"
        + "statusLabel: \(uiMeta.statusLabel.description)"
        + "buttonData: \(uiMeta.buttonData.description)"
    }

    var simpleDesc: String {
        var desc = "id: \(id), "
        + "unread: \(basicMeta.unreadCount), "
        + "updateTime: \(basicMeta.updateTime)"
        if basicMeta.feedPreviewPBType == .chat {
            desc.append(", lastMessagePosition: \(preview.chatData.lastMessagePosition)")
        }
        return desc
    }

    var minDesc: String {
        var desc = "\(id), \(basicMeta.updateTime), \(basicMeta.unreadCount)"
        return desc
    }

    var chatDesc: String {
        "chatType: \(FeedChatType.transform(chatType: preview.chatData.chatType, chatMode: preview.chatData.chatMode)), "
        + "isCrypto: \(preview.chatData.isCrypto), "
        + "msgStatus: \(uiMeta.digestStatus), " // 消息状态：已读、未读、发送中
        + "lastMessagePosition: \(preview.chatData.lastMessagePosition), "
        + "lastMessageType: \(preview.chatData.lastMessageType), "
        + "draftLength: \(uiMeta.draft.content.count), "
        + "teamNameCount: \(chatFeedPreview?.teamEntity.teamsName.count), "
        + "hasUrgent: \(!preview.chatData.urgents.isEmpty), "
        + "hasMedal: \(!preview.chatData.avatarMedal.key.isEmpty)"
    }

    var threadDesc: String {
        "threadDesc: "
        + "entityType: \(self.preview.threadData.entityType), "
        + "chatType: \(self.preview.threadData.chatType), "
        + "chatId: \(self.preview.threadData.chatID)"
    }

    var docDesc: String {
        "docType: \(preview.docData.docType), "
        + "hasAt: \(preview.docData.hasAtInfo)"
    }

    var calendarDesc: String {
        guard let calendarSubtitleData = try? Feed_V1_CalendarSubtitle(serializedData: extraMeta.bizPb.extraData) else {
            return "null"
        }
        return "calendarCount: \(calendarSubtitleData.calendarCount), "
        + "calendarType: \(calendarSubtitleData.calendarType), "
        + "isAllDay: \(calendarSubtitleData.isAllDay), "
        + "startTime: \(calendarSubtitleData.startTime), "
        + "endTime: \(calendarSubtitleData.endTime), "
        + "eventSetting: \(calendarSubtitleData.eventSetting), "
        + "meetingRoomCount: \(calendarSubtitleData.meetingRoom.count), "
        + "meetingID: \(calendarSubtitleData.meetingID)"
    }

    var feedCardGreaterListType: FeedCardGreaterListType {
        var feedCardGreaterListType: FeedCardGreaterListType
        switch self.basicMeta.feedCardBaseCategory {
        case .inbox:
            if basicMeta.parentCardID.isEmpty {
                feedCardGreaterListType = .inbox
            } else {
                feedCardGreaterListType = .box
            }
        case .done: feedCardGreaterListType = .done
        case .unknown: feedCardGreaterListType = .unknown
        @unknown default:
            feedCardGreaterListType = .unknown
            break
        }
        return feedCardGreaterListType
    }
}

// MARK: 置顶
public typealias FeedContextResponse = (response: [ShortcutResult], contextID: String)

public struct ShortcutResult {
    public let shortcut: RustPB.Feed_V1_Shortcut
    public let preview: FeedPreview

    public init(shortcut: RustPB.Feed_V1_Shortcut,
                preview: FeedPreview) {
        self.shortcut = shortcut
        self.preview = preview
    }

    public var description: String {
        return "shortcut: \(shortcut.description), feedPreview: \(preview.description)"
    }
}

public extension RustPB.Feed_V1_Shortcut {
    var description: String {
        return "\(channel.description), position: \((position))"
    }
}

public extension RustPB.Basic_V1_Channel {
    var description: String {
        return "id: \(id), type: \(type)"
    }
}

// MARK: 分组功能
public enum FeedCardGreaterListType {
    case unknown
    case inbox
    case done
    case box
}

// 从 0 开始计数
public enum FeedFilterType: Int {
    case unknown = 0,   // 未知
    inbox = 1,     // 全部
    atme = 2,    // @我
    unread = 3,    // 未读
    doc = 5,       // 云文档
    p2pChat = 6,  // 单聊
    groupChat = 7, // 群聊
    bot = 8,       // 机器人
    helpDesk = 9, // 服务台
    topicGroup = 10, // 话题群
    done = 11,     // 已完成
    cryptoChat = 12, // 密聊
    message = 13,  // 消息
    mute = 14,     // 免打扰
    team = 16,    // team
    label = 18,    // 标签
    flag = 19,      // 标记
    thread = 20,    // 话题帖子
    unreadOverDays = 21, // 超7天未读分组
    instantMeetingGroup = 22, // 临时会议群分组
    calendarGroup = 23, // 日程会议群分组
    shortcuts = 100, // 置顶卡片
    box = 101 // 新增 “会话盒子” 类型，虽然它不是分组，但处理方式类似

    public static func transform(number: Int) -> FeedFilterType {
        guard let filter = FeedFilterType(rawValue: number) else {
            // TODO: 高频日志问题治理,暂且端上注释掉,后续由Rust来修复
            // 群链接: https://applink.feishu.cn/client/chat/chatter/add_by_link?link_token=741p9b65-cbe2-4764-8941-b0411110f21e
            // GetFeedCardsResult.log.error("feedlog/dataStream/pushFeed/transform. \(number)")
            return .unknown
        }
        return filter
    }

    public var description: String {
        var info = ""
        switch self {
        case .unknown:
            info = "unknown"
        case .inbox:
            info = "inbox"
        case .atme:
            info = "atme"
        case .unread:
            info = "unread"
        case .doc:
            info = "doc"
        case .p2pChat:
            info = "p2pChat"
        case .groupChat:
            info = "groupChat"
        case .bot:
            info = "bot"
        case .helpDesk:
            info = "helpDesk"
        case .topicGroup:
            info = "topicGroup"
        case .done:
            info = "done"
        case .cryptoChat:
            info = "cryptoChat"
        case .message:
            info = "message"
        case .mute:
            info = "mute"
        case .label:
            info = "label"
        case .flag:
            info = "flag"
        case .team:
            info = "team"
        case .thread:
            info = "thread"
        case .unreadOverDays:
            info = "unreadOverDays"
        case .instantMeetingGroup:
            info = "instantMeetingGroup"
        case .calendarGroup:
            info = "calendarGroup"
        case .shortcuts:
            info = "shortcuts"
        case .box:
            info = "box"
        }
        return info
    }
}

public extension Feed_V1_FeedFilter {
    var description: String {
        return "\(filterType)"
    }
}

public extension Feed_V1_FeedFilterInfo {
    var description: String {
        return "\(self.type.filterType), \(self.unreadCount)"
    }
}

public extension Feed_V1_FeedFilterList {
    var description: String {
        return type.map({ "\($0.filterType)" }).joined(separator: ",")
    }
}

// MARK: feed 主消息列表展示规则
public extension Feed_V1_DisplayFeedRule {
    var description: String {
        return "mainRule: \(mainRule.description), msgTypes: \(msgTypes.map({ "\($0.description)" }))"
    }

    static func transform(rules: [Int32: Feed_V1_DisplayFeedRule]) -> [String] {
        return rules.compactMap({ (key: Int32, value: Feed_V1_DisplayFeedRule) -> String? in
            return transform(filterType: Int(key), rule: value)
        })
    }

    static func transform64(rules: [Int64: Feed_V1_DisplayFeedRule]) -> [String] {
        return rules.compactMap({ (key: Int64, value: Feed_V1_DisplayFeedRule) -> String? in
            return transform(filterType: Int(key), rule: value)
        })
    }

    static func transform(filterType: Int, rule: Feed_V1_DisplayFeedRule) -> String? {
        let filterType = FeedFilterType.transform(number: filterType)
        guard filterType != .unknown else { return nil }
        return "\(filterType.description): \(rule.mainRule.description)"
    }
}

public extension Feed_V1_DisplayFeedRule.DisplayFeedMainRule {
    func transform() -> String {
        switch self {
        case .alwaysDisplay: return "alwaysDisplay"
        case .displayWhenNewMsg: return "displayWhenNewMsg"
        case .neverDisplay: return "neverDisplay"
        case .displayWhenAnyNewMsg: return "displayWhenAnyNewMsg"
        case .displayWhenSpecificMsg: return "displayWhenSpecificMsg"
        case .unknownMainRule: return "unknown"
        @unknown default: return "unknown"
        }
    }

    var description: String {
        return "\(transform())"
    }
}

public extension Feed_V1_DisplayFeedRule.DisplayFeedMsgType {
    func transform() -> String {
        switch self {
        case .all: return "all"
        case .atMe: return "atMe"
        case .atAll: return "atAll"
        case .starContacts: return "starContacts"
        case .unknownMsgType: return "unknown"
        @unknown default: return "unknown"
        }
    }

    var description: String {
        return "\(transform())"
    }
}

// MARK: 标签功能
public typealias GetLabelsResponse = RustPB.Feed_V1_GetFeedGroupResponse
public typealias FeedLabelPreview = RustPB.Feed_V1_FeedGroupPreview
public typealias FeedLabel = RustPB.Feed_V1_FeedGroup
public typealias GetChildItemsForLabelResponse = RustPB.Feed_V1_GetFeedGroupItemResponse
public typealias GetLabelsForFeedResponse = RustPB.Feed_V1_GetFeedGroupListResponse
public typealias CreateLabelResponse = ServerPB.ServerPB_Feed_CreateFeedGroupResponse
public typealias UpdateLabelResponse = ServerPB.ServerPB_Feed_UpdateFeedGroupsResponse

public struct GetLabelFeedsResponse {
    public let feeds: [LabelFeedWrapperModel]
    public let hasMore: Bool
    public let nextCursor: Feed_V1_GroupCursor
    public init(feeds: [LabelFeedWrapperModel],
                hasMore: Bool,
                nextCursor: Feed_V1_GroupCursor) {
        self.feeds = feeds
        self.hasMore = hasMore
        self.nextCursor = nextCursor
    }
}

public struct LabelFeedWrapperModel {
    public let feedRelations: [Feed_V1_FeedGroupItem]
    public let feedEntity: FeedPreview
    public init(feedRelations: [Feed_V1_FeedGroupItem],
                feedEntity: FeedPreview) {
        self.feedRelations = feedRelations
        self.feedEntity = feedEntity
    }
}

public extension Feed_V1_FeedGroupPreview {
    var description: String {
        return "\(feedGroup.description), extraData: \(extraData.description), updateTime: \(updateTime)"
    }
}

public extension Feed_V1_FeedGroup {
    var description: String {
        return "\(id), position: \(position), namen: \(name.count)"
    }
}

public extension Feed_V1_GroupCursor {
    var description: String {
        return "itemId: \(itemID), position: \(position)"
    }
}

public extension Feed_V1_FeedGroupExtra {
    var description: String {
        return "[\(remindUnreadCount), \(muteUnreadCount)]"
    }
}

public extension LabelFeedWrapperModel {
    var description: String {
        return "relation: \(feedRelations.map({ $0.description })), entity: \(feedEntity.description)"
    }
}

public extension Feed_V1_FeedGroupItem {
    var description: String {
        return "feedId: \(feedCardID), feedCardType: \(feedCardType), groupID: \(groupID), position: \(position) "
    }
}

public extension ServerPB.ServerPB_Feed_FeedGroup {
    var desc: String {
        return "labelId: \(id), namen: \(name.count)"
    }
}

public extension ServerPB.ServerPB_Feed_FeedGroupItem {
    var desc: String {
        return "labelID: \(groupID), feedId: \(feedCardID), feedType: \(feedCardType)"
    }
}

// MARK: 团队
public struct GetTeamsResult {
    public let teamItems: [Basic_V1_Item]
    public let teamEntities: [Int: Basic_V1_Team]

    public init(teamItems: [Basic_V1_Item],
                teamEntities: [Int: Basic_V1_Team]) {
        self.teamItems = teamItems
        self.teamEntities = teamEntities
    }
}

public struct GetChatsResult {
    public let chatItems: [Int: [Basic_V1_Item]]
    public let chatEntities: [Int: FeedPreview]

    public init(chatItems: [Int: [Basic_V1_Item]],
                chatEntities: [Int: FeedPreview]) {
        self.chatItems = chatItems
        self.chatEntities = chatEntities
    }
}
