//
//  tests.swift
//  LarkFeed-Unit-Tests
//
//  Created by 白镜吾 on 2023/8/24.
//

import UIKit
import LarkModel
import RustPB
import RxSwift
import RxRelay
import LarkContainer
import Foundation
import LarkOpenFeed
import LarkSDKInterface
@testable import LarkFeed
import XCTest

// swiftlint:disable all
public class MockFeed {
    static var feedRuleMd5: String = "feedRuleMd5"

    static var traceId: String = "traceId"

    static var defaultFilter: Feed_V1_FeedFilter.TypeEnum = .unread

    static var networkResp: MockNetWorkResponse = MockNetWorkResponse()

    // MARK: 构造 /Feed_V1_ChatData
    static func generateChatData(rankTime: Int64, avatarKey: String, isRemind: Bool = false, unreadCount: Int32 = 0) -> Feed_V1_ChatData {
        var chatData = Feed_V1_ChatData()
        chatData.name = "chatData name"
        chatData.avatarKey = avatarKey
        chatData.localizedDigestMessage = "xKshb1bEiU: gNQle1LHe0mT2uEwgNQle1LHe0mT2uEw[完成]@xKshb1bEiU@Test"
        chatData.entityStatus = .normal
        chatData.displayTime = Int64(123)
        chatData.rankTime = rankTime
        chatData.chatType = .p2P
        chatData.chatMode = .default
        chatData.isRemind = isRemind
        chatData.unreadCount = unreadCount
        return chatData
    }

    // MARK: 构造 /Feed_V1_FeedEntityPreview
    static func generatePreviewEntity(feedID: String,
                                      rankTime: Int64,
                                      avatarKey: String,
                                      extraData: Feed_V1_FeedEntityPreview.OneOf_ExtraData? = nil) -> Feed_V1_FeedEntityPreview {
        var pb = Feed_V1_FeedEntityPreview()
        pb.feedID = feedID
        pb.feedType = .inbox
        pb.updateTime = Int64(CACurrentMediaTime() * 1_000_000_000)
        pb.checkUser = false
        pb.userID = Int64(feedID)!
        pb.extraData = extraData ?? .chatData(generateChatData(rankTime: rankTime, avatarKey: avatarKey))
        return pb
    }

    // MARK: 构造 /FeedPreview
    static func generateFeedPreview(feedID: String, 
                                    rankTime: Int64,
                                    avatarKey: String,
                                    extraData: Feed_V1_FeedEntityPreview.OneOf_ExtraData? = nil) -> FeedPreview {
        let pb = generatePreviewEntity(feedID: feedID, rankTime: rankTime, avatarKey: avatarKey, extraData: extraData)
        return FeedPreview.transformByEntityPreview(pb)
    }

    // MARK: 构造 /FeedCardCellViewModel
    static func generateFeedCardCellViewModel(feedID: String,
                                              rankTime: Int64,
                                              avatarKey: String,
                                              bizType: FeedBizType = .inbox,
                                              filterType: Feed_V1_FeedFilter.TypeEnum = .unread,
                                              extraData: Feed_V1_FeedEntityPreview.OneOf_ExtraData? = nil) -> FeedCardCellViewModel {
        let preview = generateFeedPreview(feedID: feedID, rankTime: rankTime, avatarKey: avatarKey, extraData: extraData)
        let feedCardModuleManager = try? MockAssembly.mockContainer.getCurrentUserResolver().resolver.resolve(assert: FeedCardModuleManager.self)
        return FeedCardCellViewModel.build(feedPreview: preview,
                                           userResolver: MockAssembly.mockContainer.getCurrentUserResolver(),
                                           feedCardModuleManager: feedCardModuleManager!,
                                           bizType: bizType,
                                           filterType: filterType,
                                           extraData: [:])!
    }

    // MARK: 构造 /FeedListViewModel
    static func generateFeedListViewModel(filterType: Feed_V1_FeedFilter.TypeEnum,
                                          dependency: FeedListViewModelDependency,
                                          baseDependency: BaseFeedsViewModelDependency,
                                          feedContext: FeedContextService) -> FeedListViewModel {
        return FeedListViewModel(filterType: filterType,
                                 dependency: dependency,
                                 baseDependency: baseDependency,
                                 feedContext: feedContext)
    }

    // MARK: 构造 AllFeedListViewModel
    static func generateAllFeedListViewModel(allFeedsDependency: AllFeedsDependency,
                                             dependency: FeedListViewModelDependency,
                                             baseDependency: BaseFeedsViewModelDependency,
                                             feedContext: FeedContextService) -> AllFeedListViewModel {
        return AllFeedListViewModel(allFeedsDependency: allFeedsDependency,
                                    dependency: dependency,
                                    baseDependency: baseDependency,
                                    feedContext: feedContext)
    }

    static func generateFeedNavigationBarViewModel(chatterId: String,
                                                   pushDynamicNetStatus: Observable<PushDynamicNetStatus>,
                                                   pushLoadFeedCardsStatus: Observable<Feed_V1_PushLoadFeedCardsStatus>,
                                                   chatterManager: ChatterManagerProtocol,
                                                   styleService: Feed3BarStyleService,
                                                   context: FeedContextService) -> FeedNavigationBarViewModel {
        return FeedNavigationBarViewModel(chatterId: chatterId,
                                          pushDynamicNetStatus: pushDynamicNetStatus,
                                          pushLoadFeedCardsStatus: pushLoadFeedCardsStatus,
                                          chatterManager: chatterManager,
                                          styleService: styleService,
                                          context: context)
    }

    // MARK: 构造 /PushFeedPreview
    static func generatePushFeedPreview(updateFeeds: [String: PushFeedInfo],
                                        tempFeeds: [String: PushFeedInfo],
                                        updateOrRemoveFeeds: [String: PushFeedInfo],
                                        removeFeeds: [PushRemoveFeed],
                                        filtersInfo: [Feed_V1_FeedFilter.TypeEnum: PushFeedFilterInfo]) -> PushFeedPreview {
        return PushFeedPreview(updateFeeds: updateFeeds,
                               tempFeeds: tempFeeds,
                               updateOrRemoveFeeds: updateOrRemoveFeeds,
                               removeFeeds: removeFeeds,
                               filtersInfo: filtersInfo,
                               feedRuleMd5: MockFeed.feedRuleMd5,
                               trace: FeedListTrace(traceId: "", dataFrom: .push))
    }

    // MARK: 构造 /PushFeedInfo
    static func generatePushFeedInfo(feedID: String, 
                                     rankTime: Int64,
                                     avatarKey: String,
                                     types: [FeedFilterType],
                                     extraData: Feed_V1_FeedEntityPreview.OneOf_ExtraData? = nil) -> PushFeedInfo {
        return PushFeedInfo(feedPreview: MockFeed.generateFeedPreview(feedID: feedID, rankTime: rankTime, avatarKey: avatarKey, extraData: extraData),
                            types: types)
    }

    // MARK: 构造 /GetFeedCardsResult
    static func generateGetFeedCardsResult(filterType: Feed_V1_FeedFilter.TypeEnum = .inbox,
                                           start: Int,
                                           count: Int,
                                           tempFeedIds: [String],
                                           hasMore: Bool = false) -> GetFeedCardsResult {
        var feeds = [FeedPreview]()
        for i in (start...count).reversed() {
            feeds.append(generateFeedPreview(feedID: "\(i)", rankTime: Int64(i), avatarKey: "\(i)"))
        }
        return GetFeedCardsResult(filterType: filterType,
                                  feeds: feeds,
                                  nextCursor: Feed_V1_FeedCursor.min,
                                  timeCost: 0.1,
                                  tempFeedIds: tempFeedIds,
                                  feedRuleMd5: MockFeed.feedRuleMd5,
                                  traceId: MockFeed.traceId)
    }

    /// empty chatter
    static func generateChatter(id: String, name: String, nameWithAnotherName: String) -> Chatter {
        return Chatter(
            id: id,
            isAnonymous: false,
            isFrozen: false,
            name: name,
            localizedName: "",
            enUsName: "",
            namePinyin: "",
            alias: "",
            anotherName: "",
            nameWithAnotherName: nameWithAnotherName,
            type: .unknown,
            avatarKey: "",
            avatar: .init(),
            updateTime: .zero,
            creatorId: "",
            isResigned: false,
            isRegistered: false,
            description: .init(),
            withBotTag: "",
            canJoinGroup: false,
            tenantId: "",
            workStatus: .init(),
            majorLanguage: "",
            profileEnabled: false,
            focusStatusList: [],
            chatExtra: nil,
            accessInfo: .init(),
            email: "",
            doNotDisturbEndTime: .zero,
            openAppId: "",
            acceptSmsPhoneUrgent: false)
    }
}

extension MockFeed {

    // MARK: 生成指定数量的 /FeedCardCellViewModel 数组
    static func populateFeeds(of count: Int) -> [FeedCardCellViewModel] {
        guard count > 0 else { return [] }

        var vms = [FeedCardCellViewModel]()
        for i in (1...count).reversed() {
            vms.append(generateFeedCardCellViewModel(feedID: "\(i)", rankTime: Int64(i), avatarKey: "\(i)"))
        }
        return vms
    }

    // MARK: FeedCardCellViewModel 排序规则
    static func shouldRankHigher(_ lhs: FeedCardCellViewModel, _ rhs: FeedCardCellViewModel) -> Bool {
        return lhs.feedPreview.basicMeta.rankTime != rhs.feedPreview.basicMeta.rankTime ?
        lhs.feedPreview.basicMeta.rankTime > rhs.feedPreview.basicMeta.rankTime :
        lhs.feedPreview.id > rhs.feedPreview.id
    }

    // MARK: 判断前者是否应排于后者之前
    static func shouldRankHigher(_ lhs: FeedPreview, _ rhs: FeedPreview) -> Bool {
        return lhs.basicMeta.rankTime != rhs.basicMeta.rankTime ? lhs.basicMeta.rankTime > rhs.basicMeta.rankTime : lhs.id > rhs.id
    }
}

extension XCTestCase {
    func mainWait(_ time: TimeInterval = 1, _ name: String = "mainWait") {
        let expect = expectation(description: name)
        expect.expectedFulfillmentCount = 1
        mainAfter(.now() + time) {
            expect.fulfill()
        }
        wait(for: [expect], timeout: time + 1)
    }

    func mainAfter(_ deadline: DispatchTime, _ work: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: deadline, execute: work)
    }
}

// swiftlint:enable all
