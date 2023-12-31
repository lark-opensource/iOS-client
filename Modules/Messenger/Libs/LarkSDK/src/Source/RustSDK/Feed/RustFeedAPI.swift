//
//  RustFeedAPI.swift
//  Lark
//
//  Created by Yuguo on 2017/12/10.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import RxCocoa
import RxSwift
import RustPB
import ServerPB
import LarkModel
import LarkSDKInterface
import LarkContainer
import LKCommonsLogging
import LarkAccountInterface
import LarkRustClient
import ThreadSafeDataStructure
import LarkPerf

final class RustFeedAPI: LarkAPI, FeedAPI {

    static private let logger = Logger.log(RustFeedAPI.self, category: "RustSDK.Feed")
    private var rustService: RustService { client.wrapped }

    override init(client: SDKRustService,
                  onScheduler: ImmediateSchedulerType? = nil) {
        super.init(client: client, onScheduler: onScheduler)
    }
}

// MARK: feeds列表数据
extension RustFeedAPI {
    // 拉取feeds列表数据
    func getFeedCardsV4(filterType: Feed_V1_FeedFilter.TypeEnum,
                        boxId: Int?,
                        cursor: Feed_V1_FeedCursor?,
                        count: Int,
                        spanID: UInt64?,
                        feedRuleMd5: String,
                        traceId: String) -> Observable<GetFeedCardsResult> {
        let startTime = CACurrentMediaTime()
        var request = Feed_V1_GetFeedCardsV4Request()
        request.filter = filterType // 传 INBOX 或者不存在表示全部，分组信息
        request.count = Int32(count)
        if let boxId = boxId {
            request.boxID = Int64(boxId) // 会话盒子 id
        }
        if let cursor = cursor {
            request.feedCursor = cursor
        } else {
            // REFRESH 时传入 rank_time = i64::MAX，feed_Id = 0
            request.feedCursor = Feed_V1_FeedCursor.max
        }
        let logInfo = "filterType: \(filterType), "
            + "traceId: \(traceId), "
            + "request.count: \(count), "
            + "boxId: \(boxId), "
            + "feedRuleMd5: \(feedRuleMd5), "
            + "request.cursor: \(cursor?.description ?? "nil")"
        RustFeedAPI.logger.info("feedlog/dataStream/getFeedCardsV4/start. \(logInfo)")
        func getFeedCardsRes(response: RustPB.Feed_V1_GetFeedCardsV4Response, feedRuleMd5: String) -> GetFeedCardsResult {
            let previews = FeedPreview.transforms( response.previews)
            let timeCost = (CACurrentMediaTime() - startTime) * 1000
            var responseCursor = Feed_V1_FeedCursor()
            responseCursor = response.feedCursor
            let tempFeedIds = response.canTempFeedIds.map({ String($0) })
            return GetFeedCardsResult(filterType: filterType,
                                      feeds: previews,
                                      nextCursor: responseCursor,
                                      timeCost: timeCost,
                                      tempFeedIds: tempFeedIds,
                                      feedRuleMd5: feedRuleMd5,
                                      traceId: traceId)
        }

        func onNextUpload(_ response: GetFeedCardsResult) {
            // 通过非0的cursor拉到远端最新的数据
            if let cursor = cursor, cursor.rankTime > 0 {
                ColdStartup.shared?.do(.fullDataReady)
            }
            if cursor == nil {
                //只在第一次上报
                ColdStartup.shared?.doForRust(.stateReciableGetFeedCards, response.timeCost)
            }
            let cost = (String(format: "%.0f ms", response.timeCost))
            let message = "\(logInfo), "
                + "response.count: \(response.feeds.count), "
                + "response.nextCursor: \(response.nextCursor.description), "
                + "cost: \(cost), "
                + "response.tempFeedIds: \(response.tempFeedIds), "
                + "feedlist: \(response.feeds.map { $0.description })"
            let logs = message.logFragment()
            for i in 0..<logs.count {
                let log = logs[i]
                RustFeedAPI.logger.info("feedlog/dataStream/getFeedCardsV4/success/<\(i)>. \(log)")
            }
        }

        func onErrorUpload(error: Error) {
            if cursor == nil {
                //只在第一次上报
                ColdStartup.shared?.reportForAppReciableError(.reciableErrorTypeUnknown, 0)
                ColdStartup.shared?.reportForAppReciableFirstFeedError(.reciableErrorTypeUnknown, 0)
            }
            let message = "feedlog/dataStream/getFeedCardsV4/failed. \(logInfo)"
            RustFeedAPI.logger.error(message, error: error)
        }

        if let spanID = spanID {
            return client.sendAsyncRequest(request, spanID: spanID) { (response: RustPB.Feed_V1_GetFeedCardsV4Response) in
                return getFeedCardsRes(response: response, feedRuleMd5: feedRuleMd5)
            }.subscribeOn(scheduler)
            .do(onNext: { (response: GetFeedCardsResult) in
                onNextUpload(response)
            }, onError: { (error) in
                onErrorUpload(error: error)
            })
        }

        return client.sendAsyncRequest(request) { (response: RustPB.Feed_V1_GetFeedCardsV4Response) in
            return getFeedCardsRes(response: response, feedRuleMd5: feedRuleMd5)
        }.subscribeOn(scheduler)
        .do(onNext: { (response: GetFeedCardsResult) in
            onNextUpload(response)
        }, onError: { (error) in
            onErrorUpload(error: error)
        })
    }

    func getFeedCards(filterType: Feed_V1_FeedFilter.TypeEnum,
                      pullType: FeedPullType,
                      feedCardID: String?,
                      cursor: Int?,
                      spanID: UInt64?,
                      count: Int) -> Observable<GetFeedCardsResult> {
        return getFeedCards(filterType: filterType,
                            pullType: pullType,
                            feedCardID: feedCardID,
                            cursor: cursor ?? 0,
                            count: count)
    }

    private func getFeedCards(filterType: Feed_V1_FeedFilter.TypeEnum,
                              pullType: FeedPullType,
                              feedCardID: String?,
                              cursor: Int?,
                              count: Int?) -> Observable<GetFeedCardsResult> {
        func transform(getType: FeedPullType) -> RustPB.Feed_V1_GetFeedCardsV3Request.GetType {
            switch getType {
            case .refresh:
                return .refresh
            case .loadMore:
                return .loadMore
            @unknown default:
                return .refresh
            }
        }
        var request = Feed_V1_GetFeedCardsV3Request()
        request.getType = transform(getType: pullType)
        var filter = Feed_V1_FeedFilter()
        filter.filterType = filterType
        request.filter = filter
        if let feedCardID = feedCardID {
            request.feedCardID = feedCardID
        }
        if let cursor = cursor {
            request.cursor = Int64(cursor)
        }
        if let count = count {
            request.count = Int32(count)
        }

        func getFeedCardsRes(response: RustPB.Feed_V1_GetFeedCardsV3Response) -> GetFeedCardsResult {
            let previews = FeedPreview.transforms( response.entityPreviews)
            var responseCursor = Feed_V1_FeedCursor()
            responseCursor.rankTime = response.nextCursor
            return GetFeedCardsResult(filterType: response.filter.filterType,
                                      feeds: previews,
                                      nextCursor: responseCursor,
                                      timeCost: 0,
                                      tempFeedIds: [],
                                      feedRuleMd5: "",
                                      traceId: "")
        }

        func onNextUpload(_ response: GetFeedCardsResult) {
            let message = "filterType: \(filter.filterType), "
                + "pullType: \(pullType), "
                + "request.count: \(count as Int?), "
                + "feedCardID: \(feedCardID ?? "nil"), "
                + "request.cursor: \(cursor as Int?), "
                + "response.count: \(response.feeds.count), "
                + "nextCursor: \(response.nextCursor.description), "
                + "feedlist: \(response.feeds.map { $0.description })"
            let logs = message.logFragment()
            for i in 0..<logs.count {
                let log = logs[i]
                RustFeedAPI.logger.info("feedlog/dataStream/getFeedCards/success/<\(i)>. \(log)")
            }
        }

        func onErrorUpload(error: Error) {
            if pullType == .refresh {
                //只在第一次上报
                ColdStartup.shared?.reportForAppReciableError(.reciableErrorTypeUnknown, 0)
                ColdStartup.shared?.reportForAppReciableFirstFeedError(.reciableErrorTypeUnknown, 0)
            }
            let message = "feedlog/dataStream/getFeedCards/failed. "
                + "filterType: \(filter.filterType), "
                + "pullType: \(pullType), "
                + "request.count: \(count as Int?), "
                + "feedCardID: \(feedCardID ?? "nil"), "
                + "cursor: \(cursor as Int?)"
            RustFeedAPI.logger.error(message, error: error)
        }

        return client.sendAsyncRequest(request) { (response: RustPB.Feed_V1_GetFeedCardsV3Response) in
            return getFeedCardsRes(response: response)
        }.subscribeOn(scheduler)
        .do(onNext: { (response: GetFeedCardsResult) in
            onNextUpload(response)
        }, onError: { (error) in
            onErrorUpload(error: error)
        })
    }
}

// MARK: 找未读
extension RustFeedAPI {
    // 获取下一批未读列表
    func getNextUnreadFeedCardsV4(
        filterType: Feed_V1_FeedFilter.TypeEnum,
        cursor: Feed_V1_FeedCursor?,
        feedRuleMd5: String,
        traceId: String) -> Observable<NextUnreadFeedCardsResult> {
        var request = RustPB.Feed_V1_GetNextUnreadFeedCardsV4Request()
        request.filter = filterType // 当前所在分组，传 INBOX 或者不存在表示全部
        request.additionalCount = 15 // 额外返回的 feed 数量
        if let cursor = cursor {
            request.currentCursor = cursor
        } else {
            request.currentCursor = Feed_V1_FeedCursor.max
        }
        let logInfo = "filterType: \(filterType), "
            + "traceId: \(traceId), "
            + "request.cursor: \(cursor?.description ?? "nil"), "
            + "additionalCount: \(request.additionalCount), "
            + "feedRuleMd5: \(feedRuleMd5)"
        RustFeedAPI.logger.info("feedlog/dataStream/getNextUnreadV4/start. \(logInfo)")
        return client.sendAsyncRequest(request) { (response: RustPB.Feed_V1_GetNextUnreadFeedCardsV4Response) in
            let previews = FeedPreview.transforms(response.previews)
            let nextCursor = response.feedCursor
            let tempFeedIds = response.canTempFeedIds.map({ String($0) })
            let info = "\(logInfo), "
                + "response.nextId: \(response.nextID), " // 下一个未读id
                + "response.nextCursor: \(nextCursor.description), " // 当返回了端上没有的数据，导致端上 next_cursor 发生改变时有值，否则为空
                + "response.tempFeedIds: \(tempFeedIds), "
                + "count: \(previews.count), "
                + "feedlist: \(previews.map { $0.description })"
            let logs = info.logFragment()
            for i in 0..<logs.count {
                let log = logs[i]
                RustFeedAPI.logger.info("feedlog/dataStream/getNextUnreadV4/success/<\(i)>. \(log)")
            }
            let result = NextUnreadFeedCardsResult(filterType: filterType,
                                                   previews: previews,
                                                   nextCursor: nextCursor,
                                                   tempFeedIds: tempFeedIds,
                                                   feedRuleMd5: feedRuleMd5,
                                                   traceId: traceId)
            return result
        }.subscribeOn(scheduler)
        .do(onError: { error in
            let info = "feedlog/dataStream/getNextUnreadV4/failed. \(logInfo)"
            RustFeedAPI.logger.error(info, error: error)
        })
    }
}

// MARK: 标记
extension RustFeedAPI {
        func flagFeedCard(_ id: String, isFlaged: Bool, entityType: Basic_V1_FeedCard.EntityType) -> Observable<Void> {
            var request = ServerPB.ServerPB_Feed_UpdateFlagsRequest()
            var item: ServerPB_Feed_FlagItem = ServerPB_Feed_FlagItem()
            let flagType: ServerPB.ServerPB_Feed_FlagItem.FlagType = .feed
            let itemType = entityType.rawValue
            item.flagType = Int32(flagType.rawValue)
            item.itemType = Int32(itemType)
            item.itemID = Int64(id) ?? 0
            if isFlaged {
                request.items = [item]
            } else {
                request.deletedItems = [item]
            }
            return self.client.sendPassThroughAsyncRequest(request, serCommand: ServerPB_Improto_Command.updateFlags).subscribeOn(scheduler)
                .do(onNext: { _ in
                    let info = "feedlog/feedcard/action/flag/success. "
                    + "id: \(id), "
                    + "isFlaged: \(isFlaged)"
                    RustFeedAPI.logger.info(info)
                }, onError: { error in
                    let info = "feedlog/feedcard/action/flag/failed. "
                    + "id: \(id), "
                    + "isFlaged: \(isFlaged)"
                    RustFeedAPI.logger.error(info, error: error)
                })
        }
}

// MARK: 会话盒子
extension RustFeedAPI {
    func setFeedCardsIntoBox(feedCardId: String) -> Observable<String> {
        var request = RustPB.Feed_V1_SetFeedCardsIntoBoxRequest()
        request.feedCardsIds = [feedCardId]
        let info = "feedlog/box/set. feedId: \(feedCardId)"
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
            .map { (response: RustPB.Feed_V1_SetFeedCardsIntoBoxResponse) in
                return response.feedCardID
            }
            .do(onNext: { _ in
                RustFeedAPI.logger.info("success: \(info)")
            }, onError: { (error) in
                RustFeedAPI.logger.error("failed: \(info)", error: error)
            })
    }

    func deleteFeedCardsFromBox(feedCardId: String, isRemind: Bool) -> Observable<Void> {
        var request = RustPB.Feed_V1_DeleteFeedCardsFromBoxRequest()
        request.feedCardsIds = [feedCardId]
        request.isRemind = isRemind
        let info = "feedlog/box/delete. id: \(feedCardId), isRemind: \(isRemind)"
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
            .map { _ in return }
            .do(onNext: { _ in
                RustFeedAPI.logger.info("success: \(info)")
            }, onError: { (error) in
                RustFeedAPI.logger.error("failed: \(info)", error: error)
            })
    }
}

// MARK: 置顶
extension RustFeedAPI {
    func loadShortcuts(strategy: Basic_V1_SyncDataStrategy) -> Observable<FeedContextResponse> {
        var request = RustPB.Feed_V1_GetShortcutsRequest()
        request.syncDataStrategy = strategy
        return client.sendAsyncRequest(request)
            .map { (response: RustPB.Feed_V1_GetShortcutsResponse) in
                let results = response.shortcuts.compactMap { (shortcut) -> ShortcutResult? in
                    if let preview = FeedPreview.transform(id: shortcut.channel.id,
                                                           entityPreviews: response.entityPreview) {
                        return ShortcutResult(shortcut: shortcut, preview: preview)
                    }
                    return nil
                }
                RustFeedAPI.logger.info("feedlog/shortcut/dataflow/get/success. "
                    + "resultsCount: \(results.count), "
                    + "shortcutsCount: \(response.shortcuts.count), "
                    + "entityPreviewsCount: \(response.entityPreview.count), "
                    + "list: \(results.map { $0.description })")
                return (results, "")
            }.subscribeOn(scheduler)
            .do(onError: { error in
                RustFeedAPI.logger.error("feedlog/shortcut/dataflow/get/failed", error: error)
            })
    }

    func createShortcuts(_ shortcuts: [RustPB.Feed_V1_Shortcut]) -> Observable<Void> {
        var request = RustPB.Feed_V1_CreateShortcutsRequest()
        request.shortcuts = shortcuts
        let info = "feedlog/shortcut/create. \(shortcuts.map { $0.description })"
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
            .do(onNext: { _ in
                RustFeedAPI.logger.info("success: \(info)")
            }, onError: { (error) in
                RustFeedAPI.logger.error("failed: \(info)", error: error)
            })
    }

    func deleteShortcuts(_ shortcuts: [RustPB.Feed_V1_Shortcut]) -> Observable<Void> {
        var request = RustPB.Feed_V1_DeleteShortcutsRequest()
        request.shortcuts = shortcuts
        let info = "feedlog/shortcut/delete. \(shortcuts.map { $0.description })"
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
            .do(onNext: { _ in
                RustFeedAPI.logger.info("success: \(info)")
            }, onError: { (error) in
                RustFeedAPI.logger.error("failed: \(info)", error: error)
            })
    }

    func update(shortcut: RustPB.Feed_V1_Shortcut, newPosition: Int) -> Observable<Void> {
        var request = RustPB.Feed_V1_UpdateShortcutsRequest()
        request.shortcuts = [shortcut]
        request.id2Position = [shortcut.channel.id: Int32(newPosition)]
        let info = "feedlog/shortcut/updatePostion. shortcut: \(shortcut.description), newPosition: \(newPosition)"
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
            .do(onNext: { _ in
                RustFeedAPI.logger.info("success: \(info)")
            }, onError: { (error) in
                RustFeedAPI.logger.error("failed: \(info)", error: error)
            })
    }
}

// MARK: 对单个feed的操作
extension RustFeedAPI {
    func removeFeedCard(channel: RustPB.Basic_V1_Channel,
                        feedType: RustPB.Basic_V1_FeedCard.EntityType?) -> Observable<Void> {
        var request = RustPB.Statistics_V1_PushHideChannelRequest()
        request.channel = channel
        if let feedType = feedType {
            request.type = feedType
        }
        let info = "feedlog/feedcard/remove. channel: \(channel.description), entityType: \(feedType)"
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
            .do(onNext: { _ in
                RustFeedAPI.logger.info("success: \(info)")
            }, onError: { (error) in
                RustFeedAPI.logger.error("failed: \(info)", error: error)
            })
    }

    func peakFeedCard(by id: String, entityType: RustPB.Basic_V1_FeedCard.EntityType) -> Observable<Void> {
        var request = RustPB.Feed_V1_PeakFeedCardRequest()
        request.id = id
        request.entityType = entityType
        let info = "feedlog/feedcard/peak. id: \(id), entityType: \(entityType)"
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
            .do(onNext: { _ in
                RustFeedAPI.logger.info("success: \(info)")
            }, onError: { (error) in
                RustFeedAPI.logger.error("failed: \(info)", error: error)
            })
    }

    func moveToDone(feedId: String, entityType: RustPB.Basic_V1_FeedCard.EntityType) -> Observable<Void> {
        var request = RustPB.Feed_V1_UpdateFeedCardsRequest()
        var pair = RustPB.Feed_V1_UpdateFeedCardsRequest.Pair()
        pair.id = feedId
        pair.entityType = entityType
        request.pairs = [pair]
        request.feedType = .done
        let info = "feedlog/feedcard/done. feedId: \(feedId), entityType: \(entityType)"
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
            .do(onNext: { _ in
                RustFeedAPI.logger.info("success: \(info)")
            }, onError: { (error) in
                RustFeedAPI.logger.error("failed: \(info)", error: error)
            })
    }

    func markFeedCard(_ id: String, isDelayed: Bool) -> Observable<FeedPreview> {
        var request = RustPB.Feed_V1_SetFeedCardPreviewDelayedRequest()
        request.feedCardID = id
        request.isDelayed = isDelayed
        let info = "feedlog/feedcard/delay. id: \(id), isDelayed: \(isDelayed)"
        return client.sendAsyncRequest(request) { (res: RustPB.Feed_V1_SetFeedCardPreviewDelayedResponse) in
            return FeedPreview.transform(delayedResponse: res)
        }.subscribeOn(scheduler)
        .do(onNext: { _ in
            RustFeedAPI.logger.info("success: \(info)")
        }, onError: { (error) in
            RustFeedAPI.logger.error("failed: \(info)", error: error)
        })
    }

    func markChatLaunch(feedId: String, entityType: Basic_V1_FeedCard.EntityType) {
        var request = Feed_V1_SetRecentVisitTargetsRequest()
        var target = Feed_V1_RecentVisitTarget()
        target.targetID = feedId
        target.feedEntityType = entityType
        request.targets.append(target)
        _ = client.sendAsyncRequest(request)
            .subscribe()
    }

    func clearSingleBadge(taskID: String, feeds: [Feed_V1_FeedCardBadgeIdentity]) -> Observable<Void> {
        return clearBadge(taskID: taskID, feeds: feeds, filters: [], teams: [], labels: [])
    }

    func clearTeamBadge(taskID: String, teams: [Int64]) -> Observable<Void> {
        return clearBadge(taskID: taskID, feeds: [], filters: [], teams: teams, labels: [])
    }

    func clearLabelBadge(taskID: String, labels: [Feed_V1_TagIdentity]) -> Observable<Void> {
        return clearBadge(taskID: taskID, feeds: [], filters: [], teams: [], labels: labels)
    }

    func clearFilterGroupBadge(taskID: String,
                    filters: [Feed_V1_FeedFilter.TypeEnum]) -> Observable<Void> {
        return clearBadge(taskID: taskID, feeds: [], filters: filters, teams: [], labels: [])
    }

    func clearBadge(taskID: String,
                    feeds: [Feed_V1_FeedCardBadgeIdentity],
                    filters: [Feed_V1_FeedFilter.TypeEnum],
                    teams: [Int64],
                    labels: [Feed_V1_TagIdentity]) -> Observable<Void> {
        var request = RustPB.Feed_V1_BatchClearFeedBadgeRequest()
        request.taskID = taskID
        request.feedFilters = filters
        request.teams = teams
        request.tags = labels
        request.feeds = feeds
        var info = [String: Any]()
        info["taskID"] = taskID
        if !feeds.isEmpty {
            info["feeds"] = feeds.map({ $0.feedID })
        }
        if !filters.isEmpty {
            info["filters"] = filters
        }
        if !teams.isEmpty {
            info["teams"] = teams
        }
        if !labels.isEmpty {
            info["labels"] = labels.map({ $0.tagID })
        }
        return client.sendAsyncRequest(request).subscribeOn(scheduler).do(onNext: { _ in
                RustFeedAPI.logger.info("feedlog/feedcardaction/clearbadge. \(info)")
            }, onError: { (error) in
                RustFeedAPI.logger.error("feedlog/feedcardaction/clearbadge. \(info)", error: error)
            })
    }
    // 查询是否存在 免打扰、at all 提醒的feed
    func getBatchFeedsActionState(feeds: [Feed_V1_FeedCardBadgeIdentity],
                                   filters: [Feed_V1_FeedFilter.TypeEnum],
                                   teams: [Int64],
                                   tags: [Feed_V1_TagIdentity],
                                   queryMuteAtAll: Bool) -> Observable<RustPB.Feed_V1_QueryMuteFeedCardsResponse> {
        var request = RustPB.Feed_V1_QueryMuteFeedCardsRequest()
        request.teams = teams
        request.feeds = feeds
        request.feedFilters = filters
        request.tags = tags
        // 是否也需要查询群聊的at all提醒开关
        request.queryMuteAtAll = queryMuteAtAll

        var info = [String: Any]()
        if !feeds.isEmpty {
            info["feeds"] = feeds.map({ $0.feedID })
        }
        if !filters.isEmpty {
            info["filters"] = filters
        }
        if !teams.isEmpty {
            info["teams"] = teams
        }
        if !tags.isEmpty {
            info["tags"] = tags.map({ $0.tagID })
        }
        info["queryMuteAtAll"] = queryMuteAtAll
        return client.sendAsyncRequest(request)
            .subscribeOn(scheduler).do(onNext: { response in
                var result = "feedCount: \(response.feedCount), "
                + "isMute: \(response.hasUnmuteFeeds_p), "
                + "muteAtAllType: \(response.muteAtAllType)"
                RustFeedAPI.logger.info("feedlog/feedcard/batch/action/query. \(info), \(result)")
            }, onError: { (error) in
                RustFeedAPI.logger.error("feedlog/feedcard/batch/action/query. \(info)", error: error)
            })
    }
    // 批量操作：免打扰、at all 提醒
    func setBatchFeedsState(taskID: String,
                      feeds: [Feed_V1_FeedCardBadgeIdentity],
                      filters: [Feed_V1_FeedFilter.TypeEnum],
                      teams: [Int64],
                      tags: [Feed_V1_TagIdentity],
                      action: Feed_V1_BatchMuteFeedCardsRequest.MuteActionType) -> Observable<Void> {
        var request = RustPB.Feed_V1_BatchMuteFeedCardsRequest()
        request.taskID = taskID
        request.feeds = feeds
        request.feedFilters = filters
        request.teams = teams
        request.tags = tags
        // action 要执行的任务类型，优先级高于unmute字段（如果有值且值不为UNKNOWN，则sdk会忽略unmute字段，只由本字段决定要执行的任务类型）
        request.muteActionType = action
        var info = [String: Any]()
        info["taskID"] = taskID
        if !feeds.isEmpty {
            info["feedCards"] = feeds.map({ $0.feedID })
        }
        if !filters.isEmpty {
            info["filters"] = filters
        }
        if !teams.isEmpty {
            info["teams"] = teams
        }
        if !tags.isEmpty {
            info["tags"] = tags.map({ $0.tagID })
        }
        info["action"] = action
        return client.sendAsyncRequest(request)
            .subscribeOn(scheduler).do(onNext: { _ in
                RustFeedAPI.logger.info("feedlog/feedcard/batch/action. \(info)")
            }, onError: { (error) in
                RustFeedAPI.logger.error("feedlog/feedcard/batch/action. \(info)", error: error)
            })
    }
}

// MARK: 开启/关闭提醒功能
extension RustFeedAPI {
    // 开启/关闭提醒功能
    func updateFeedCard(feedId: String, mute: Bool) -> Observable<Void> {
        var settingData = Feed_V1_AppFeedCard.SettingData()
        settingData.mute = mute
        return updateFeedCardSetting(feedId: feedId,
                                     fields: [.mute],
                                     settingData: settingData).map { _ in }
    }

    // 更新 feed card 的设置
    func updateFeedCardSetting(
        feedId: String,
        fields: [Feed_V1_UpdateAppFeedCardSettingRequest.SettingDataField],
        settingData: Feed_V1_AppFeedCard.SettingData) -> Observable<RustPB.Feed_V1_UpdateAppFeedCardSettingResponse> {
        var request = RustPB.Feed_V1_UpdateAppFeedCardSettingRequest()
        request.cardID = Int64(feedId) ?? 0
        request.fields = fields
        request.settingData = settingData
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
            .do(onError: { (error) in
                let log = "feedlog/feedCardSetting/. id: \(feedId), fields: \(fields), mute: \(settingData.mute)"
                RustFeedAPI.logger.error(log, error: error)
            })
    }

    // 开启/关闭群的消息提醒功能
    func updateChatRemind(chatId: String, isRemind: Bool) -> Observable<RustPB.Im_V1_UpdateChatResponse> {
        var request = RustPB.Im_V1_UpdateChatRequest()
        request.chatID = chatId
        request.isRemind = isRemind
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
            .do(onError: { (error) in
                let log = "feedlog/remind/chat. id: \(chatId), isRemind: \(isRemind)"
                RustFeedAPI.logger.error(log, error: error)
            })
    }

    // 开启/关闭订阅号的消息提醒功能
    func updateSubscriptionRemind(subscriptionId: String, isRemind: Bool) -> Single<RustPB.Openplatform_V1_SetSubscriptionNotifyResponse> {
        var request = RustPB.Openplatform_V1_SetSubscriptionNotifyRequest()
        request.subscriptionID = subscriptionId
        request.isNotify = isRemind
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
            .do(onError: { (error) in
                let log = "feedlog/remind/subscription. id: \(subscriptionId), isRemind: \(isRemind)"
                RustFeedAPI.logger.error(log, error: error)
            }).asSingle()
    }
}

// MARK: 预加载
extension RustFeedAPI {
    func preloadFeedCards(by ids: [String], feedPosition: Int32? = nil) -> Observable<Void> {
        let preloadFeedCards = preloadFeedCards(feedIds: ids)
        let fetchFeedCardsDependency = fetchFeedCardsDependency(feedIds: ids, feedPosition: feedPosition)
        return Observable.merge(preloadFeedCards, fetchFeedCardsDependency)
    }

    private func preloadFeedCards(feedIds: [String]) -> Observable<Void> {
        var request = RustPB.Feed_V1_PreloadFeedCardsDataRequest()
        request.feedCardIds = feedIds
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    private func fetchFeedCardsDependency(feedIds: [String], feedPosition: Int32? = nil) -> Observable<Void> {
        var request = RustPB.Feed_V1_FetchFeedCardsMessageDependencyRequest()
        request.feedCardIds = feedIds
        if let feedPosition = feedPosition {
            request.feedPosition = feedPosition
        }
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }
}

// MARK: Feed分组
extension RustFeedAPI {
    // 获取筛选列表
    func getFeedFilterSettings(needAll: Bool, tryLocal: Bool) -> Observable<Feed_V1_GetFeedFilterSettingsResponse> {
        var request = Feed_V1_GetFeedFilterSettingsRequest()
        request.needAll = needAll // 是否需要返回全部分组
        if tryLocal {
            request.syncStrategy = .tryLocal
        } else {
            request.syncStrategy = .forceServer
        }
        return client.sendAsyncRequest(request) { (response: RustPB.Feed_V1_GetFeedFilterSettingsResponse) in
            let message = "feedlog/filter/get/success. "
                + "needAll: \(needAll), "
                + "tryLocal: \(tryLocal), "
                + "filterEnable: \(response.filterEnable), "
                + "hasShowMute: \(response.hasShowMute), "
                + "showMute: \(response.showMute), "
                + "hasShowAtAllInAtFilter: \(response.hasShowAtAllInAtFilter), "
                + "showAtAllInAtFilter: \(response.showAtAllInAtFilter), "
            + "usedFilters: count: \(response.usedFilters.count), info: \(response.usedFilters.map({ FeedFilterType.transform(number: Int($0.filterType.rawValue)).description })), "
            + "commonlyUsedFilters: count: \(response.commonlyUsedFilters.count), "
            + "info: \(response.commonlyUsedFilters.map({ FeedFilterType.transform(number: Int($0.filterType.rawValue)).description })), "
            + "allFilters: count: \(response.allFilters.count), info: \(response.allFilters.map({ FeedFilterType.transform(number: Int($0.filterType.rawValue)).description })), "
                + "filterDisplayRule: count: \(response.filterDisplayFeedRule.keys.count), "
                + "ruleInfo: \(Feed_V1_DisplayFeedRule.transform(rules: response.filterDisplayFeedRule))"
            RustFeedAPI.logger.info(message)
            return response
        }.subscribeOn(scheduler)
        .do(onError: { (error) in
            let message = "feedlog/filter/get/failed. "
                + "needAll: \(needAll), "
                + "tryLocal: \(tryLocal)"
            RustFeedAPI.logger.error(message, error: error)
        })
    }

    // 免打扰分组开关
    func updateFeedFilterSettings(filterEnable: Bool, showMute: Bool?) -> Observable<Feed_V1_UpdateFeedFilterSettingsResponse> {
        var request = RustPB.Feed_V1_UpdateFeedFilterSettingsRequest()
        request.filterEnable = filterEnable
        if let muteEnable = showMute {
            request.showMute = muteEnable
        }
        return client.sendAsyncRequest(request) { (response: RustPB.Feed_V1_UpdateFeedFilterSettingsResponse) in
            let message = "feedlog/filter/mute/success. "
                + "filterEnable: \(filterEnable), "
                + "showMute: \(showMute), "
            RustFeedAPI.logger.info(message)
            return response
        }.subscribeOn(scheduler)
        .do(onError: { (error) in
            let message = "feedlog/filter/mute/failed. "
                + "filterEnable: \(filterEnable), "
                + "showMute: \(showMute)"
            RustFeedAPI.logger.error(message, error: error)
        })
    }

    // 更新用户分组
    func updateAtFilterSettings(showAtAllInAtFilter: Bool) -> Observable<Feed_V1_UpdateFeedFilterSettingsResponse> {
        var request = RustPB.Feed_V1_UpdateFeedFilterSettingsRequest()
        request.showAtAllInAtFilter = showAtAllInAtFilter
        return client.sendAsyncRequest(request) { (response: RustPB.Feed_V1_UpdateFeedFilterSettingsResponse) in
            let message = "feedlog/filter/at/success. \(showAtAllInAtFilter)"
            RustFeedAPI.logger.info(message)
            return response
        }.subscribeOn(scheduler)
        .do(onError: { (error) in
            let message = "feedlog/filter/at/failed. \(showAtAllInAtFilter)"
            RustFeedAPI.logger.error(message, error: error)
        })
    }

    // 保存feed分组设置
    func saveFeedFiltersSetting(_ filterEnable: Bool?,
                                _ commonlyUsedFilters: [Feed_V1_FeedFilter]?,
                                _ usedFilters: [Feed_V1_FeedFilter],
                                _ filterDisplayFeedRule: [Int32: Feed_V1_DisplayFeedRule],
                                _ feedGroupDisplayFeedRule: [Int64: Feed_V1_DisplayFeedRule]?) -> Observable<Feed_V1_UpdateFeedFilterSettingsResponse> {
        var request = RustPB.Feed_V1_UpdateFeedFilterSettingsRequest()

        if let filterEnable = filterEnable {
            request.filterEnable = filterEnable
        }

        if let commonlyUsedFilters = commonlyUsedFilters {
            if commonlyUsedFilters.isEmpty {
                RustFeedAPI.logger.info("feedlog/filter/updateFilters. remove all commonlyFilters")
                request.clearCommonlyUsedFilters_p = true
            } else {
                request.commonlyUsedFilters = commonlyUsedFilters
            }
        }

        if usedFilters.isEmpty {
            RustFeedAPI.logger.info("feedlog/filter/updateFilters. remove all usedFilters")
            request.removeUsedFilters = true
        } else {
            request.usedFilters = usedFilters
        }

        request.filterDisplayFeedRule = filterDisplayFeedRule

        var feedGroupInfo: String
        if let feedGroupDisplayFeedRule = feedGroupDisplayFeedRule {
            request.feedGroupDisplayFeedRule = feedGroupDisplayFeedRule
            feedGroupInfo = "\(Feed_V1_DisplayFeedRule.transform64(rules: feedGroupDisplayFeedRule))"
        } else {
            feedGroupInfo = "nil"
        }

        return client.sendAsyncRequest(request) { (response: RustPB.Feed_V1_UpdateFeedFilterSettingsResponse) in
            let message = "feedlog/filter/updateFilters/success. "
                        + "filterEnable: \(filterEnable), "
                        + "commonlyUsedFilters: \(commonlyUsedFilters?.map { $0.description }), "
                        + "usedFilters: \(usedFilters.map { $0.description }), "
                        + "filterDisplayFeedRule: \(Feed_V1_DisplayFeedRule.transform(rules: filterDisplayFeedRule)), "
                        + "feedGroupDisplayFeedRule: \(feedGroupInfo)"
            RustFeedAPI.logger.info(message)
            return response
        }.subscribeOn(scheduler)
        .do(onError: { (error) in
            let message = "feedlog/filter/updateFilters/failed. "
                        + "filterEnable: \(filterEnable), "
                        + "commonlyUsedFilters: \(commonlyUsedFilters?.map { $0.description }), "
                        + "usedFilters: \(usedFilters.map { $0.description })"
                        + "filterDisplayFeedRule: \(Feed_V1_DisplayFeedRule.transform(rules: filterDisplayFeedRule)), "
                        + "feedGroupDisplayFeedRule: \(feedGroupInfo)"
            RustFeedAPI.logger.error(message, error: error)
        })
    }

    func updateMsgDisplayRuleMap(_ displayFeedRuleMap: [Int32: Feed_V1_DisplayFeedRule]?,
                                 _ feedGroupDisplayFeedRule: [Int64: Feed_V1_DisplayFeedRule]?) -> Observable<Feed_V1_UpdateFeedFilterSettingsResponse> {
        var request = RustPB.Feed_V1_UpdateFeedFilterSettingsRequest()
        var needRequest = false
        var ruleInfo = "nil"
        var feedGroupInfo = "nil"

        if let ruleMap = displayFeedRuleMap {
            request.filterDisplayFeedRule = ruleMap
            ruleInfo = "\(Feed_V1_DisplayFeedRule.transform(rules: ruleMap))"
            needRequest = true
        }
        if let labelRuleMap = feedGroupDisplayFeedRule {
            request.feedGroupDisplayFeedRule = labelRuleMap
            feedGroupInfo = "\(Feed_V1_DisplayFeedRule.transform64(rules: labelRuleMap))"
            needRequest = true
        }
        if !needRequest { return Observable.empty() }
        return client.sendAsyncRequest(request) { (response: RustPB.Feed_V1_UpdateFeedFilterSettingsResponse) in
            let message = "feedlog/filter/updateFilters/success. "
                        + "displayFeedRuleMap: \(ruleInfo), "
                        + "feedGroupDisplayFeedRule: \(feedGroupInfo)"
            RustFeedAPI.logger.info(message)
            return response
        }.subscribeOn(scheduler)
        .do(onError: { (error) in
            let message = "feedlog/filter/updateFilters/failed. "
                        + "displayFeedRuleMap: \(ruleInfo), "
                        + "feedGroupDisplayFeedRule: \(feedGroupInfo)"
            RustFeedAPI.logger.error(message, error: error)
        })
    }

    // 获取所有bagde：这个接口会触发pushFeed，以pushFeed的通道返回给端上filter badge数据
    func getAllBadge() -> Observable<Feed_V1_GetAllBadgeResponse> {
        RustFeedAPI.logger.info("feedlog/filter/getAllBadge")
        let request = Feed_V1_GetAllBadgeRequest()
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    // 获取Feed快捷操作设置
    func getFeedActionSetting(strategy: Basic_V1_SyncDataStrategy) -> Observable<Feed_V1_GetFeedActionSettingResponse> {
        RustFeedAPI.logger.info("feedlog/actionSetting/getFeedActionSetting")
        var request = Feed_V1_GetFeedActionSettingRequest()
        request.syncDataStrategy = strategy
        return client.sendAsyncRequest(request)
            .subscribeOn(scheduler)
            .do(onError: { (error) in
            let message = "feedlog/actionSetting/getFeedActionSetting/failed. "
            RustFeedAPI.logger.error(message, error: error)
        })

    }

    // 更新Feed快捷操作设置
    func updateFeedActionSetting(setting: Feed_V1_FeedSlideActionSetting) -> Observable<Feed_V1_UpdateFeedActionSettingResponse> {
        RustFeedAPI.logger.info("feedlog/actionSetting/updateFeedActionSetting")
        var request = Feed_V1_UpdateFeedActionSettingRequest()
        request.slideAction = setting
        return client.sendAsyncRequest(request)
            .subscribeOn(scheduler)
            .do(onError: { (error) in
            let message = "feedlog/actionSetting/updateFeedActionSetting/failed. "
                + "leftSlideActions: \(setting.leftSlideAction), "
                + "rightSlideActions: \(setting.rightSlideAction)"
            RustFeedAPI.logger.error(message, error: error)
        })
    }
}

// MARK: - Feed三栏
extension RustFeedAPI {
    // 获取三栏设置数据
    func getThreeColumnsSettings(tryLocal: Bool) -> Observable<Feed_V1_GetThreeColumnsSettingResponse> {
        var request = Feed_V1_GetThreeColumnsSettingRequest()
        if tryLocal {
            request.syncDataStrategy = .tryLocal
        } else {
            request.syncDataStrategy = .forceServer
        }
        return client.sendAsyncRequest(request) { (response: RustPB.Feed_V1_GetThreeColumnsSettingResponse) in
            let message = "feedlog/threeColumns/getSettings/success. "
                        + "tryLocal: \(tryLocal), "
                        + "showMobileThreeColumns: \(response.setting.showMobileThreeColumns), "
                        + "showPcThreeColumns: \(response.setting.showPcThreeColumns), "
                        + "mobileThreeColumnsNewUser: \(response.setting.mobileThreeColumnsNewUser), "
                        + "mobileTriggerScene: \(response.setting.mobileTriggerScene), "
                        + "updateTime: \(response.setting.updateTime)"
            RustFeedAPI.logger.info(message)
            return response
        }.subscribeOn(scheduler)
        .do(onError: { (error) in
            let message = "feedlog/threeColumns/getSettings/failed. "
                + "tryLocal: \(tryLocal)"
            RustFeedAPI.logger.error(message, error: error)
        })
    }

    // 更新三栏设置数据
    func updateThreeColumnsSettings(showEnable: Bool,
                                    scene: Feed_V1_ThreeColumnsSetting.TriggerScene)
                                    -> Observable<Feed_V1_SetThreeColumnsSettingResponse> {
        var request = RustPB.Feed_V1_SetThreeColumnsSettingRequest()
        var setting = Feed_V1_ThreeColumnsSetting()
        setting.showMobileThreeColumns = showEnable
        setting.mobileTriggerScene = scene
        request.setting = setting
        return client.sendAsyncRequest(request) { (response: RustPB.Feed_V1_SetThreeColumnsSettingResponse) in
            let message = "feedlog/threeColumns/updateSettings/success. "
                + "showEnable: \(showEnable), "
                + "mobileTriggerScene: \(scene)"
            RustFeedAPI.logger.info(message)
            return response
        }.subscribeOn(scheduler)
        .do(onError: { (error) in
            let message = "feedlog/threeColumns/updateSettings/error. "
                + "showEnable: \(showEnable), "
                + "mobileTriggerScene: \(scene)"
            RustFeedAPI.logger.error(message, error: error)
        })
    }

    // 更新常用分组项数据
    func updateCommonlyUsedFilters(_ commonlyUsedFilters: [Feed_V1_FeedFilter]) -> Observable<Feed_V1_UpdateFeedFilterSettingsResponse> {
        var request = RustPB.Feed_V1_UpdateFeedFilterSettingsRequest()
        request.commonlyUsedFilters = commonlyUsedFilters
        return client.sendAsyncRequest(request) { (response: RustPB.Feed_V1_UpdateFeedFilterSettingsResponse) in
            let message = "feedlog/filter/commonlyUsedFilters/success. "
                        + "commonlyUsedFilters: \(commonlyUsedFilters.map { $0.description })"
            RustFeedAPI.logger.info(message)
            return response
        }.subscribeOn(scheduler)
        .do(onError: { (error) in
            let message = "feedlog/filter/commonlyUsedFilters/failed. "
                        + "commonlyUsedFilters: \(commonlyUsedFilters.map { $0.description })"
            RustFeedAPI.logger.error(message, error: error)
        })
    }

    // 获取未读feeds数量
    func getUnreadFeedsNum() -> Observable<Feed_V1_GetUnreadFeedsResponse> {
        var request = Feed_V1_GetUnreadFeedsRequest()
        return client.sendAsyncRequest(request) { (response: RustPB.Feed_V1_GetUnreadFeedsResponse) in
            let message = "feedlog/threeColumns/getUnreadFeedsNum/success. "
                        + "allUnreadPreviewCount: \(response.allUnreadPreviewCount)"
            RustFeedAPI.logger.info(message)
            return response
        }.subscribeOn(scheduler)
        .do(onError: { (error) in
            let message = "feedlog/threeColumns/getUnreadFeedsNum/failed"
            RustFeedAPI.logger.error(message, error: error)
        })
    }
}

// MARK: 标签API
extension RustFeedAPI {
    func getAllLabels(pageCount: Int32,
                      maxTimes: Int) -> Observable<[FeedLabelPreview]> {
        let subject = PublishSubject<[FeedLabelPreview]>()
        var list: [FeedLabelPreview] = []
        getLabels(nextPosition: nil,
                  pageCount: pageCount,
                  maxTimes: maxTimes,
                  times: 0,
                  successCallback: { stop, items in
                    items.forEach({ list.append($0) })
                    if stop {
                        // 对全量数据进行排序
                        list = list.sorted(by: { $0.feedGroup.position > $1.feedGroup.position })
                        subject.onNext(list)
                        subject.onCompleted()
                    }
                  },
                  errorCallback: { error in
                    subject.onError(error)
                  })
        return subject
    }

    private func getLabels(nextPosition: Int64?,
                           pageCount: Int32,
                           maxTimes: Int,
                           times: Int,
                           successCallback: @escaping(Bool, [FeedLabelPreview]) -> Void,
                           errorCallback: @escaping(Error) -> Void) {
        var disposeBag = DisposeBag()
        getLabels(position: nextPosition, count: pageCount).subscribe(onNext: { [weak self] response in
            let resume = response.hasMore_p && !response.groupInfos.isEmpty && times < maxTimes
            successCallback(!resume, response.groupInfos)
            disposeBag = DisposeBag()
            guard resume else { return }
            self?.getLabels(nextPosition: response.nextPosition,
                           pageCount: pageCount,
                           maxTimes: maxTimes,
                           times: times + 1,
                           successCallback: successCallback,
                           errorCallback: errorCallback)
        }, onError: { error in
            errorCallback(error)
        }).disposed(by: disposeBag)
    }

    // 获取标签列表（一级列表）
    func getLabels(position: Int64?, count: Int32) -> Observable<GetLabelsResponse> {
        var request = RustPB.Feed_V1_GetFeedGroupRequest()
        if let position = position {
            request.position = position
        }
        request.count = count
        let info = "feedlog/label/getLabels"
        let parameters = "position: \(position), count: \(count), "
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
            .do(onNext: { (response: GetLabelsResponse) in
                let detail = parameters
                    + "hasMore: \(response.hasMore_p), "
                    + "hasNextPosition: \(response.hasNextPosition), "
                    + "nextPosition: \(response.nextPosition), "
                    + "count: \(response.groupInfos.count), "
                    + "labels: \(response.groupInfos.map({ $0.description }))"
                let logs = detail.logFragment()
                for i in 0..<logs.count {
                    let log = logs[i]
                    RustFeedAPI.logger.info("\(info)/success/<\(i)>. \(log)")
                }
            }, onError: { (error) in
                RustFeedAPI.logger.error("\(info)/failed. \(parameters)", error: error)
            })
    }

    // 获取指定标签下的child items（二级列表）
    func getLabelFeeds(labelId: Int64, nextCursor: Feed_V1_GroupCursor?, count: Int32, orderBy: Feed_V1_FeedGroupItemOrderRule) -> Observable<GetLabelFeedsResponse> {
        var request = RustPB.Feed_V1_GetFeedGroupItemRequest()
        request.groupID = labelId
        if let nextCursor = nextCursor {
            request.cursor = nextCursor
        }
        request.count = count
        request.orderBy = orderBy
        let info = "feedlog/label/getLabelFeeds"
        let parameters = "labelId: \(labelId), "
            + "nextCursor: \(nextCursor?.description), "
            + "count: \(count), "
            + "orderBy: \(orderBy), "
        return client.sendAsyncRequest(request) { (response: GetChildItemsForLabelResponse) in
            let feeds: [LabelFeedWrapperModel] = response.feedInfos.map({
                let feedEntity = FeedPreview.transformByEntityPreview($0.feedEntityPreview)
                return LabelFeedWrapperModel(feedRelations: $0.groupItems, feedEntity: feedEntity)
            })
            return GetLabelFeedsResponse(feeds: feeds, hasMore: response.hasMore_p, nextCursor: response.nextCursor)
        }.subscribeOn(scheduler)
        .do(onNext: { (result: GetLabelFeedsResponse) in
            let detail = parameters
                + "res.hasMore: \(result.hasMore), "
                + "res.nextCursor: \(result.nextCursor.description), "
                + "res.count: \(result.feeds.count), "
                + "feeds: \(result.feeds.map({ $0.description }))"
            let logs = detail.logFragment()
            for i in 0..<logs.count {
                let log = logs[i]
                RustFeedAPI.logger.info("\(info)/success/<\(i)>. \(log)")
            }
        }, onError: { (error) in
            RustFeedAPI.logger.error("\(info)/failed. \(parameters)", error: error)
        })
    }

    // 获取 feed item 所在的标签集合
    func getLabelsForFeed(feedId: String) -> Observable<GetLabelsForFeedResponse> {
        var feed = RustPB.Feed_V1_GetFeedGroupListRequest.Pair()
        feed.id = feedId
        feed.entityType = .chat
        return getLabelsForFeed(feed: feed)
    }

    private func getLabelsForFeed(feed: RustPB.Feed_V1_GetFeedGroupListRequest.Pair) -> Observable<GetLabelsForFeedResponse> {
        var request = RustPB.Feed_V1_GetFeedGroupListRequest()
        request.pairs = feed
        let info = "feedlog/label/getLabelsForItem. feedId: \(feed.id), entityType: \(feed.entityType)"
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
            .do(onNext: { (response: GetLabelsForFeedResponse) in
                RustFeedAPI.logger.info("success: \(info), existedGroupCount: \(response.existedGroupIds.count), groupsCount: \(response.groups.count)")
            }, onError: { (error) in
                RustFeedAPI.logger.error("failed: \(info)", error: error)
            })
    }

    // 新建标签，可选添加child item
    func createLabel(labelName: String, feedId: Int64?) -> Observable<CreateLabelResponse> {
        var request = ServerPB.ServerPB_Feed_CreateFeedGroupRequest()
        var label = ServerPB.ServerPB_Feed_FeedGroup()
        label.name = labelName
        label.type = .normal
        var feeds: [ServerPB.ServerPB_Feed_FeedGroupItem]?
        if let feedId = feedId {
            var feed = ServerPB.ServerPB_Feed_FeedGroupItem()
            feed.feedCardID = feedId
            feed.feedCardType = .chat
            feeds = [feed]
        }
        return createLabel(label: label, feeds: feeds)
    }

    private func createLabel(label: ServerPB.ServerPB_Feed_FeedGroup,
                             feeds: [ServerPB.ServerPB_Feed_FeedGroupItem]?) -> Observable<CreateLabelResponse> {
        var request = ServerPB.ServerPB_Feed_CreateFeedGroupRequest()
        request.feedGroup = label
        if let feeds = feeds {
            request.feedGroupItems = feeds
        }
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .createFeedGroup)
            .do(onError: { (error) in
                let info = "namen: \(label.name.count), "
                            "label: \(label.desc), "
                            "feeds: \(feeds?.map { $0.desc })"
                RustFeedAPI.logger.error("feedlog/label/createLabel. \(info)", error: error)
            })
    }

    // 更新标签信息：排序、删除、自身属性
    func updateLabelInfo(id: Int64, name: String) -> Observable<UpdateLabelResponse> {
        var label = ServerPB.ServerPB_Feed_FeedGroup()
        label.id = id
        label.name = name
        label.isDefault = false
        label.type = .normal
        return updateLabel(updatedLabels: [label],
                           deletedLabels: nil,
                           updatedFeeds: nil,
                           deletedFeeds: nil)
    }

    func deleteLabel(id: Int64) -> Observable<UpdateLabelResponse> {
        var label = ServerPB.ServerPB_Feed_FeedGroup()
        label.id = id
        label.isDefault = false
        label.type = .normal
        return updateLabel(updatedLabels: nil,
                           deletedLabels: [label],
                           updatedFeeds: nil,
                           deletedFeeds: nil)
    }

    // 往一个指定的标签里添加多个会话
    func addItemIntoLabel(labelId: Int64, itemIds: [Int64]) -> Observable<UpdateLabelResponse> {
        let updatedFeeds: [ServerPB.ServerPB_Feed_FeedGroupItem] = itemIds.map({
            var feed = ServerPB.ServerPB_Feed_FeedGroupItem()
            feed.groupID = labelId
            feed.feedCardID = $0
            feed.feedCardType = .chat
            return feed
        })
        return updateLabel(updatedLabels: nil,
                           deletedLabels: nil,
                           updatedFeeds: updatedFeeds,
                           deletedFeeds: nil)
    }

    // 添加/删除/更新 label，向label里添加/删除 feed
    func updateLabel(feedId: Int64, updateLabels: [Int64], deleteLabels: [Int64]) -> Observable<UpdateLabelResponse> {
        return updateLabel(updatedLabels: nil,
            deletedLabels: nil,
            updatedFeeds: updateLabels.map({
               var groupItem = ServerPB.ServerPB_Feed_FeedGroupItem()
               groupItem.feedCardID = feedId
               groupItem.groupID = $0
               groupItem.feedCardType = .chat
               return groupItem
            }),
            deletedFeeds: deleteLabels.map({
                var groupItem = ServerPB.ServerPB_Feed_FeedGroupItem()
                groupItem.feedCardID = feedId
                groupItem.groupID = $0
                groupItem.feedCardType = .chat
                return groupItem
            }))
    }

    // 删除单个 label 中的 feed
    func deleteLabelFeed(feedId: Int64, labelId: Int64) -> Observable<UpdateLabelResponse> {
        var groupItem = ServerPB.ServerPB_Feed_FeedGroupItem()
        groupItem.feedCardID = feedId
        groupItem.groupID = labelId
        groupItem.feedCardType = .chat
        return updateLabel(updatedLabels: nil,
                           deletedLabels: nil,
                           updatedFeeds: nil,
                           deletedFeeds: [groupItem])
    }

    private func updateLabel(updatedLabels: [ServerPB.ServerPB_Feed_FeedGroup]?,
                         deletedLabels: [ServerPB.ServerPB_Feed_FeedGroup]?,
                         updatedFeeds: [ServerPB.ServerPB_Feed_FeedGroupItem]?,
                         deletedFeeds: [ServerPB.ServerPB_Feed_FeedGroupItem]?) -> Observable<UpdateLabelResponse> {
        var request = ServerPB.ServerPB_Feed_UpdateFeedGroupsRequest()
        if let updatedLabels = updatedLabels {
            request.feedGroups = updatedLabels
        }
        if let deletedLabels = deletedLabels {
            request.deletedGroups = deletedLabels
        }
        if let updatedFeeds = updatedFeeds {
            request.feedGroupItems = updatedFeeds
        }
        if let deletedFeeds = deletedFeeds {
            request.deletedFeedGroupItems = deletedFeeds
        }

        return rustService.sendPassThroughAsyncRequest(request, serCommand: .updateFeedGroups)
            .do(onError: { (error) in
                let info = "updatedLabels: \(updatedLabels?.map { $0.desc }), "
                            + "deletedLabels: \(deletedLabels?.map { $0.desc }), "
                            + "updatedFeeds: \(updatedFeeds?.map { $0.desc }), "
                            + "deletedFeeds: \(deletedFeeds?.map { $0.desc })"
                RustFeedAPI.logger.error("feedlog/label/updateLabel. \(info)", error: error)
            })
    }
}

// MARK: 团队
extension RustFeedAPI {
    // 拉取团队列表
    func getTeams() -> Observable<GetTeamsResult> {
        var request = RustPB.Feed_V1_GetItemsRequest()
        var param = Feed_V1_GetItemsRequest.Param()
        let teamParentID = Int64(0)
        param.parentID = teamParentID
        request.params = [param]
        return client.sendAsyncRequest(request) { (response: RustPB.Feed_V1_GetItemsResponse) -> GetTeamsResult in
            guard let teamItems = response.results[teamParentID]?.items else {
                let emptyTeams = GetTeamsResult(teamItems: [], teamEntities: [:])
                let message = "teamlog/getTeams/error. emptyTeams"
                RustFeedAPI.logger.error(message)
                return emptyTeams
            }
            var teamEntitys = [Int: Basic_V1_Team]()
            for (teamEntityId, teamEntity) in response.teams {
                teamEntitys[Int(teamEntityId)] = teamEntity
            }
            let teams = GetTeamsResult(teamItems: teamItems, teamEntities: teamEntitys)
            let message = teams.description
            let logs = message.logFragment()
            for i in 0..<logs.count {
                let log = logs[i]
                RustFeedAPI.logger.info("teamlog/getTeams/success/<\(i)>. \(log)")
            }
            RustFeedAPI.logger.info(message)
            return teams
        }.subscribeOn(scheduler)
        .do(onError: { (error) in
            let message = "teamlog/getTeams/failed"
            RustFeedAPI.logger.error(message, error: error)
        })
    }

    // 拉取群组列表
    func getChats(parentIDs: [Int]) -> Observable<GetChatsResult> {
        let params = parentIDs.map { id -> Feed_V1_GetItemsRequest.Param in
            var param = Feed_V1_GetItemsRequest.Param()
            param.parentID = Int64(id)
            return param
        }
        var request = RustPB.Feed_V1_GetItemsRequest()
        request.params = params
        return client.sendAsyncRequest(request) { (response: RustPB.Feed_V1_GetItemsResponse) -> GetChatsResult in
            var chatItems = [Int: [RustPB.Basic_V1_Item]]()
            var chatEntites = [Int: FeedPreview]()
            for (teamItemId, value) in response.results {
                let aChatItems = value.items
                chatItems[Int(teamItemId)] = aChatItems
            }
            for (chatEntityId, chatEntity) in response.chats {
                let feed = FeedPreview.transformByEntityPreview(chatEntity)
                chatEntites[Int(chatEntityId)] = feed
            }
            let chats = GetChatsResult(chatItems: chatItems, chatEntities: chatEntites)
            let message = "parentIDs: \(parentIDs), chats: \(chats.description)"
            let logs = message.logFragment()
            for i in 0..<logs.count {
                let log = logs[i]
                RustFeedAPI.logger.info("teamlog/getChats/success/<\(i)>. \(log)")
            }
            return chats
        }.subscribeOn(scheduler)
        .do(onError: { (error) in
            let log = "teamlog/getChats/failed. "
                + "parentIDs: \(parentIDs)"
            RustFeedAPI.logger.error(log, error: error)
        })
    }

    func preloadItems(parentIds: [Int]) -> Observable<Im_V1_PreloadItemsResponse> {
        let message = "teamlog/preloadItems/invoke. parentIDs: \(parentIds)"
        RustFeedAPI.logger.info(message)
        var request = RustPB.Im_V1_PreloadItemsRequest()
        request.parentIds = parentIds.map({ Int64($0) })
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
        .do(onError: { (error) in
            let message = "teamlog/preloadItems/failed. "
                + "parentIDs: \(parentIds)"
            RustFeedAPI.logger.error(message, error: error)
        })
    }

    // 展示/隐藏群组
    func hideTeamChat(chatId: Int, isHidden: Bool) -> Observable<Im_V1_PatchItemResponse> {
        var request = RustPB.Im_V1_PatchItemRequest()
        request.itemID = Int64(chatId)
        request.updateFields = [.isHidden]
        request.isHidden = isHidden
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
        .do(onNext: { (response: Im_V1_PatchItemResponse) in
            let message = "teamlog/hideTeamChat/success. "
                + "chatId: \(chatId), "
                + "isHidden: \(isHidden), "
                + "response: \(response.item.description)"
            RustFeedAPI.logger.info(message)
        }, onError: { (error) in
            let message = "teamlog/hideTeamChat/failed. "
                + "chatId: \(chatId), "
                + "isHidden: \(isHidden)"
            RustFeedAPI.logger.error(message, error: error)
        })
    }
}

// MARK: Feed 按钮
extension RustFeedAPI {
    func appFeedCardButtonCallback(buttonId: String) -> Observable<ServerPB_Feed_AppFeedCardButtonCallbackResponse> {
        var request = ServerPB.ServerPB_Feed_AppFeedCardButtonCallbackRequest()
        request.buttonID = buttonId
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .appFeedCardButtonCallback)
            .do(onError: { (error) in
                let info = "buttonId: \(buttonId)"
                RustFeedAPI.logger.error("feedlog/feedcard/cta. \(info)", error: error)
            })
    }
}

// MARK: 需要迁出去的api
extension RustFeedAPI {
    func setAppNotificationRead(appID: String, seqID: String) -> Observable<Void> {
        var request = RustPB.Openplatform_V1_SetAppNotificationReadRequest()
        request.appID = appID
        request.seqID = seqID
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }
}

// MARK: 其他
extension String {
    // 将过长的日志字符串分片，防止被截断
    fileprivate func logFragment() -> [String] {
        let maxLength = 14_000 // 日志里的【字符串截断】 限制的最大长度
        let count = self.count
        let times: Int
        if count % maxLength == 0 {
            times = count / maxLength
        } else {
            times = count / maxLength + 1
        }
        var list: [String] = []
        for i in 0..<times {
            let start = i * maxLength
            var end = (i + 1) * maxLength
            if end > count {
                end = count
            }
            let str = self[start..<end]
            list.append(str)
        }
        return list
    }

    subscript (r: Range<Int>) -> String {
        let lowerBound = r.lowerBound
        let upperBound = r.upperBound
        let count = self.count
        guard lowerBound <= upperBound,
              lowerBound >= 0,
              upperBound >= 0,
              lowerBound <= count,
              upperBound <= count else { return "" }
        let start = index(startIndex, offsetBy: lowerBound)
        let end = index(startIndex, offsetBy: upperBound)
        return String(self[start..<end])
    }
}
