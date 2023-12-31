//
//  PushFeedEntityPreviewsHandler.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/9/13.
//

import Foundation
import RustPB
import LarkContainer
import LarkRustClient
import LKCommonsLogging
import LarkModel
import LarkSDKInterface

struct PushFeedFilterInfo {
    let type: Feed_V1_FeedFilter.TypeEnum
    let unread: Int
    let muteUnread: Int

    init(type: Feed_V1_FeedFilter.TypeEnum, unread: Int, muteUnread: Int) {
        self.type = type
        self.unread = unread
        self.muteUnread = muteUnread
    }

    static func transform(_ filterInfoPb: Feed_V1_FeedFilterInfo) -> PushFeedFilterInfo {
        return PushFeedFilterInfo(type: filterInfoPb.type.filterType,
                                  unread: Int(filterInfoPb.unreadCount),
                                  muteUnread: Int(filterInfoPb.muteUnreadCount))
    }

    static func transform(_ type: Feed_V1_FeedFilter.TypeEnum, _ pushFilterInfo: Feed_V1_FilterPushInfo) -> PushFeedFilterInfo {
        return PushFeedFilterInfo(type: type,
                                  unread: Int(pushFilterInfo.unread),
                                  muteUnread: Int(pushFilterInfo.muteUnread))
    }

    var description: String {
        let info = "\(type), \(unread), \(muteUnread)"
        return info
    }
}

struct PushFeedInfo {
    let feedPreview: FeedPreview
    let types: [FeedFilterType]

    init(feedPreview: FeedPreview, types: [FeedFilterType]) {
        self.feedPreview = feedPreview
        self.types = types
    }

    var description: String {
        let info = "types: \(types.map({ $0.description }).joined(separator: ",")), \(feedPreview.description)"
        return info
    }
}

struct PushRemoveFeed {
    let feedId: String
    let updateTime: Int
    let checker: FeedPreviewChecker
    let types: [FeedFilterType]

    init(feedId: String,
         updateTime: Int = FeedLocalCode.invalidUpdateTime,
         checker: FeedPreviewChecker = .default(),
         types: [FeedFilterType] = []) {
        self.feedId = feedId
        self.updateTime = updateTime
        self.checker = checker
        self.types = types
    }

    var description: String {
        let info = "id: \(feedId), types: \(types.map({ $0.description }).joined(separator: ",")), updateTime: \(updateTime)"
        return info
    }
}

public struct PushFeedPreview: PushMessage {
    var updateFeeds: [String: PushFeedInfo] // Feed更新
    let tempFeeds: [String: PushFeedInfo] // Feed透传
    let updateOrRemoveFeeds: [String: PushFeedInfo]
    let removeFeeds: [PushRemoveFeed] // Feed删除
    let filtersInfo: [Feed_V1_FeedFilter.TypeEnum: PushFeedFilterInfo] // 更新unreadCount 信息，包含 all
    let feedRuleMd5: String
    let trace: FeedListTrace
    init(updateFeeds: [String: PushFeedInfo],
         tempFeeds: [String: PushFeedInfo] = [:],
         updateOrRemoveFeeds: [String: PushFeedInfo] = [:],
         removeFeeds: [PushRemoveFeed],
         filtersInfo: [Feed_V1_FeedFilter.TypeEnum: PushFeedFilterInfo],
         feedRuleMd5: String = "",
         trace: FeedListTrace) {
        self.updateFeeds = updateFeeds
        self.tempFeeds = tempFeeds
        self.updateOrRemoveFeeds = updateOrRemoveFeeds
        self.removeFeeds = removeFeeds
        self.filtersInfo = filtersInfo
        self.feedRuleMd5 = feedRuleMd5
        self.trace = trace
    }

    var description: String {
        let info = "filtersInfo: count:\(filtersInfo.count), info: \(filtersInfo.map({ $1.description })), "
            + "updateFeeds: count:\(updateFeeds.count), \(updateFeeds.map { $1.description }), "
            + "removeFeeds: count:\(removeFeeds.count), \(removeFeeds.map { $0.description }), "
            + "tempFeeds: count:\(tempFeeds.count), \(tempFeeds.map { $1.description }), "
            + "updateOrRemoveFeeds: count:\(updateOrRemoveFeeds.count), \(updateOrRemoveFeeds.map { $1.description })"
        return info
    }

    public func getUnreadBadge(_ type: Feed_V1_FeedFilter.TypeEnum) -> Int? {
        return self.filtersInfo[type]?.unread
    }
}

final class PushFeedEntityPreviewsHandler: UserPushHandler {

    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: Feed_V1_PushFeedEntityPreviews) throws {
        guard let pushCenter = self.pushCenter else { return }
        let pushFeedPreview: PushFeedPreview
        let trace = FeedListTrace(traceId: FeedListTrace.genId(), dataFrom: .push)

        if Feed.Feature(userResolver).groupSettingEnable {
            pushFeedPreview = handlePushDataByOpt(message, trace: trace)
        } else {
            pushFeedPreview = handlePushDataByDefault(message, trace: trace)
        }

        let logs = pushFeedPreview.description.logFragment()
        for i in 0..<logs.count {
            let log = logs[i]
            FeedContext.log.info("feedlog/dataStream/pushFeed/<\(i)>. \(trace.description), \(log)")
        }
        pushCenter.post(pushFeedPreview)
    }

    /// 旧逻辑: 处理Push实体中需要更新和删除的信息
    private func handlePushDataByDefault(_ message: Feed_V1_PushFeedEntityPreviews, trace: FeedListTrace) -> PushFeedPreview {
        var updateFeeds: [String: PushFeedInfo] = [:]
        message.updatedFeeds.forEach { (_: String, pushFeedInfo: Feed_V1_FeedCardPushInfo) in
            let feed = FeedPreview.transformByEntityPreview(pushFeedInfo.preview)
            let types = pushFeedInfo.list.types.map({ FeedFilterType.transform(number: Int($0)) })
            let pushFeedInfo = PushFeedInfo(feedPreview: feed, types: types)
            updateFeeds[feed.id] = pushFeedInfo
        }

        let removeFeeds = message.removedFeed.map({
            let checker = FeedPreviewChecker(userID: $0.userID, checkUser: $0.checkUser)
            let pushFeed = PushRemoveFeed(feedId: String($0.feedID),
                                          updateTime: Int($0.updateTime),
                                          checker: checker)
            return pushFeed
        })

        var filtersInfo: [Feed_V1_FeedFilter.TypeEnum: PushFeedFilterInfo] = [:]
        message.filtersInfo.forEach { (number: Int32, pushFilterInfo: Feed_V1_FilterPushInfo) in
            guard let type = Feed_V1_FeedFilter.TypeEnum(rawValue: Int(number)) else {
                return
            }
            filtersInfo[type] = PushFeedFilterInfo.transform(type, pushFilterInfo)
        }
        let pushFeedPreview = PushFeedPreview(updateFeeds: updateFeeds,
                                              removeFeeds: removeFeeds,
                                              filtersInfo: filtersInfo,
                                              trace: trace)
        return pushFeedPreview
    }

    /// 新逻辑: 依赖ActionMap来决策信息的增删操作
    private func handlePushDataByOpt(_ message: Feed_V1_PushFeedEntityPreviews, trace: FeedListTrace) -> PushFeedPreview {
        let logs = message.description.logFragment()
        for i in 0..<logs.count {
            let log = logs[i]
            FeedContext.log.info("feedlog/dataStream/pushFeed/origin/<\(i)>. \(trace.description), \(log)")
        }
        var updateFeeds: [String: PushFeedInfo] = [:]
        var tempFeeds: [String: PushFeedInfo] = [:]
        var updateOrRemoveFeeds: [String: PushFeedInfo] = [:]
        var removeFeeds: [PushRemoveFeed] = []
        var filtersInfo: [Feed_V1_FeedFilter.TypeEnum: PushFeedFilterInfo] = [:]

        message.updatedFeeds.forEach { (_: String, pushFeedInfo: Feed_V1_FeedCardPushInfo) in
            let feed = FeedPreview.transformByEntityPreview(pushFeedInfo.preview)
            var actionShip: [Feed_V1_FeedCardPushInfo.Action: [Int32]] = [:]
            pushFeedInfo.listAction.forEach { (tab: Int32, action: Feed_V1_FeedCardPushInfo.Action) in
                var tabs = actionShip[action] ?? []
                tabs.append(tab)
                actionShip[action] = tabs
            }

            if let tabs = actionShip[.update], !tabs.isEmpty {
                let types = tabs.map({ FeedFilterType.transform(number: Int($0)) })
                let pushFeedInfo = PushFeedInfo(feedPreview: feed, types: types)
                updateFeeds[feed.id] = pushFeedInfo
            }

            if let tabs = actionShip[.updateCanTemp], !tabs.isEmpty {
                let types = tabs.map({ FeedFilterType.transform(number: Int($0)) })
                let pushFeedInfo = PushFeedInfo(feedPreview: feed, types: types)
                tempFeeds[feed.id] = pushFeedInfo
            }

            if let tabs = actionShip[.tempOrRemove], !tabs.isEmpty {
                let types = tabs.map({ FeedFilterType.transform(number: Int($0)) })
                let pushFeedInfo = PushFeedInfo(feedPreview: feed, types: types)
                updateOrRemoveFeeds[feed.id] = pushFeedInfo
            }

            if let tabs = actionShip[.remove], !tabs.isEmpty {
                let types = tabs.map({ FeedFilterType.transform(number: Int($0)) })
                let removeFeed: PushRemoveFeed
                if pushFeedInfo.hasRemoveInfo {
                    let checkerInfo = FeedPreviewChecker(userID: pushFeedInfo.removeInfo.userID,
                                                  checkUser: pushFeedInfo.removeInfo.checkUser)
                    removeFeed = PushRemoveFeed(
                        feedId: String(pushFeedInfo.removeInfo.feedID),
                        updateTime: Int(pushFeedInfo.removeInfo.updateTime),
                        checker: checkerInfo,
                        types: types)
                } else {
                    let checkerInfo = FeedPreviewChecker(userID: pushFeedInfo.preview.userID,
                                                  checkUser: pushFeedInfo.preview.checkUser)
                    removeFeed = PushRemoveFeed(
                        feedId: feed.id,
                        updateTime: feed.basicMeta.updateTime,
                        checker: checkerInfo,
                        types: types)
                }
                removeFeeds.append(removeFeed)
            }
        }

        message.filtersInfo.forEach { (number: Int32, pushFilterInfo: Feed_V1_FilterPushInfo) in
            guard let type = Feed_V1_FeedFilter.TypeEnum(rawValue: Int(number)) else {
                return
            }
            filtersInfo[type] = PushFeedFilterInfo.transform(type, pushFilterInfo)
        }
        let pushFeedPreview = PushFeedPreview(updateFeeds: updateFeeds,
                                              tempFeeds: tempFeeds,
                                              updateOrRemoveFeeds: updateOrRemoveFeeds,
                                              removeFeeds: removeFeeds,
                                              filtersInfo: filtersInfo,
                                              feedRuleMd5: message.filterDisplayFeedRuleMd5,
                                              trace: trace)
        return pushFeedPreview
    }
}

extension Feed_V1_FeedCardPushInfo {
    var description: String {
        let actions = listAction.compactMap { (key: Int32, value: Action) -> (String, String)? in
            let filterType = FeedFilterType.transform(number: Int(key))
            guard filterType != .unknown else { return nil }
            return (filterType.description, value.description)
        }
        return "id: \(preview.feedID), actions: \(actions), hasPreview: \(hasPreview), hasRemoveInfo: \(hasRemoveInfo)"
    }
}

extension RustPB.Feed_V1_FeedCardPushInfo.Action {
    func transform() -> String {
        switch self {
        case .update: return "update"
        case .remove: return "remove"
        case .updateCanTemp: return "temp"
        case .tempOrRemove: return "updateOrRemove"
        @unknown default: return "unknown"
        }
    }

    var description: String {
        return "\(transform())"
    }
}

extension Feed_V1_PushFeedEntityPreviews {
    var description: String {
        var info = ""
        updatedFeeds.forEach { (_: String, pushFeedInfo: Feed_V1_FeedCardPushInfo) in
            info.append("\(pushFeedInfo.description), ")
        }
        return info
    }
}
