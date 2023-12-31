//
//  PushFeedHandler..swift
//  LarkFlag
//
//  Created by phoenix on 2022/5/29.
//

import Foundation
import RustPB
import LarkContainer
import LarkRustClient
import LKCommonsLogging
import LarkModel

// 从 0 开始计数
enum FlagFeedFilterType: Int {
    case unknown = 0,   // 未知
    inbox = 1,     // 全部
    atme = 2,    // @我
    unread = 3,    // 未读
    delayed = 4,   // 稍后处理-废弃
    doc = 5,       // 云文档
    p2pChat = 6,  // 单聊
    groupChat = 7, // 群聊
    bot = 8,       // 机器人
    helpDesk = 9, // 服务台
    topicGroup = 10, // 话题圈
    done = 11,     // 已完成
    cryptoChat = 12, // 密聊
    message = 13,  // 消息
    mute = 14,     // 免打扰
    group = 15,    // 分组-废弃
    team = 16,    // team
    label = 18,    // 标签
    flag = 19,      // 标记
    shortcuts = 100, // 置顶卡片
    box = 101 // 新增 “会话盒子” 类型，虽然它不是分组，但处理方式类似

    static func transform(number: Int) -> FlagFeedFilterType {
        guard let filter = FlagFeedFilterType(rawValue: number) else {
            return .unknown
        }
        return filter
    }

    var description: String {
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
        case .delayed:
            info = "delayed"
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
        case .shortcuts:
            info = "shortcuts"
        case .box:
            info = "box"
        default: break
        }
        return info
    }
}

struct FlagPushFeedFilterInfo {
    let type: Feed_V1_FeedFilter.TypeEnum
    let unread: Int
    let muteUnread: Int

    init(type: Feed_V1_FeedFilter.TypeEnum, unread: Int, muteUnread: Int) {
        self.type = type
        self.unread = unread
        self.muteUnread = muteUnread
    }

    static func transform(_ filterInfoPb: Feed_V1_FeedFilterInfo) -> FlagPushFeedFilterInfo {
        return FlagPushFeedFilterInfo(type: filterInfoPb.type.filterType,
                                      unread: Int(filterInfoPb.unreadCount),
                                      muteUnread: Int(filterInfoPb.muteUnreadCount))
    }

    static func transform(_ type: Feed_V1_FeedFilter.TypeEnum, _ pushFilterInfo: Feed_V1_FilterPushInfo) -> FlagPushFeedFilterInfo {
        return FlagPushFeedFilterInfo(type: type,
                                      unread: Int(pushFilterInfo.unread),
                                      muteUnread: Int(pushFilterInfo.muteUnread))
    }

    var description: String {
        let info = "\(type), \(unread), \(muteUnread)"
        return info
    }
}

struct PushUpdateFeedInfo {
    let feedPreview: FeedPreview
    let types: [FlagFeedFilterType]

    init(feedPreview: FeedPreview, types: [FlagFeedFilterType]) {
        self.feedPreview = feedPreview
        self.types = types
    }

    var description: String {
        let info = "types: \(types.map({ $0.description }).joined(separator: ",")), \(feedPreview.description)"
        return info
    }
}

struct PushRemoveFeedInfo {
    let feedId: String
    let updateTime: Int

    init(feedId: String, updateTime: Int = -2) {
        self.feedId = feedId
        self.updateTime = updateTime
    }

    var description: String {
        let info = "feedId: \(feedId), updateTime: \(updateTime)"
        return info
    }
}

public struct PushFeedMessage: PushMessage {
    // Feed更新
    var updateFeeds: [String: PushUpdateFeedInfo]
    // Feed删除
    let removeFeeds: [PushRemoveFeedInfo]
    // 更新unreadCount 信息，包含 all
    let filtersInfo: [Feed_V1_FeedFilter.TypeEnum: FlagPushFeedFilterInfo]

    init(updateFeeds: [String: PushUpdateFeedInfo],
         removeFeeds: [PushRemoveFeedInfo],
         filtersInfo: [Feed_V1_FeedFilter.TypeEnum: FlagPushFeedFilterInfo]) {
        self.updateFeeds = updateFeeds
        self.removeFeeds = removeFeeds
        self.filtersInfo = filtersInfo
    }

    var description: String {
        let info = "filtersInfo: count \(filtersInfo.count), info: \(filtersInfo.map({ $1.description })), "
            + "removeFeeds: count \(removeFeeds.count), \(removeFeeds.map { $0.description }), "
            + "updateFeeds: count \(updateFeeds.count), \(updateFeeds.map { $1.description })"
        return info
    }
}

final class PushFeedHandler: UserPushHandler {

    private var pushCenter: PushNotificationCenter? {
        return try? userResolver.userPushCenter
    }

    func process(push message: Feed_V1_PushFeedEntityPreviews) throws {
        guard let pushCenter = self.pushCenter else { return }
        var updateFeeds: [String: PushUpdateFeedInfo] = [:]
        message.updatedFeeds.forEach { (_: String, pushFeedInfo: Feed_V1_FeedCardPushInfo) in
            let feed = FeedPreview.transformByEntityPreview(pushFeedInfo.preview)
            let types = pushFeedInfo.list.types.map({ FlagFeedFilterType.transform(number: Int($0)) })
            let pushFeedInfo = PushUpdateFeedInfo(feedPreview: feed, types: types)
            updateFeeds[feed.id] = pushFeedInfo
        }

        let removeFeeds = message.removedFeed
            .map({ PushRemoveFeedInfo(feedId: String($0.feedID),
                                      updateTime: Int($0.updateTime)) })

        var filtersInfo: [Feed_V1_FeedFilter.TypeEnum: FlagPushFeedFilterInfo] = [:]
        message.filtersInfo.forEach { (number: Int32, pushFilterInfo: Feed_V1_FilterPushInfo) in
            guard let type = Feed_V1_FeedFilter.TypeEnum(rawValue: Int(number)) else {
                return
            }
            filtersInfo[type] = FlagPushFeedFilterInfo.transform(type, pushFilterInfo)
        }

        let pushFeedMessage = PushFeedMessage(updateFeeds: updateFeeds,
                                              removeFeeds: removeFeeds,
                                              filtersInfo: filtersInfo)
        pushCenter.post(pushFeedMessage)
    }
}
