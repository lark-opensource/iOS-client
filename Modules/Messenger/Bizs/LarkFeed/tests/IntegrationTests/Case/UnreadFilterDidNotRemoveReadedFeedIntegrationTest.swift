//
//  UnreadFilterDidNotRemoveReadedFeedIntegrationTest.swift
//  LarkFeed-Unit-Tests
//
//  Created by 白镜吾 on 2023/9/4.
//

import XCTest
import LarkModel
import RustPB
import LarkContainer
import RxSwift
import LarkOpenFeed
import LarkSDKInterface
import LarkRustClient
import SwiftProtobuf
@testable import LarkFeed

// swiftlint:disable all
// MARK: 在未读分组下，已读的feed没有在适当的时机移除掉
// https://meego.feishu.cn/larksuite/issue/detail/8095270
// MARK: feed 未读分组列表，会意外移除不应该移除的feed
// https://meego.feishu.cn/larksuite/issue/detail/7871394
/*
 1. 构造初始 Feeds 100 个，取 10 的倍数为临时删除的值
 2. 构建 VM 让其处于 active 状态，拉取首屏的 result 和 temp 值
 3. vm active 时，预期全部展示 result 内的所有 feed 都展示
 - 校验一下 provider 的数量和预期值
 - push 新的 feeds，updateOrRemove 传要删除的值，provider 数量不变，校验结果
 4. vm resignActive 时，预期移除 temp 值
 - 校验一下 provider 的数量和预期值
 - push 新的 feeds，updateOrRemove 传要删除的值，provider 数量减少，校验结果
 */
final class UnreadFilterDidNotRemoveReadedFeedIntegrationTest: XCTestCase {

    let container = MockAssembly.generateContainer()

    let count: Int = 150
    let step: Int = 10

    func testUnreadFilterDidNotRemoveReadedFeed() {
        // 构造当前分组 FeedListViewModel
        let resolver = container.getCurrentUserResolver()
        let baseDependency = try? resolver.resolve(assert: BaseFeedsViewModelDependency.self)
        let dependency = try? resolver.resolve(assert: FeedListViewModelDependency.self)
        let feedContext = try? resolver.resolve(assert: FeedContextService.self)
        let feedListViewModel = MockFeed.generateFeedListViewModel(filterType: MockFeed.defaultFilter,
                                                                   dependency: dependency!,
                                                                   baseDependency: baseDependency!,
                                                                   feedContext: feedContext!)
        // 激活当前分组
        feedListViewModel.willActive()

        // 当前分组拉取首屏数据，构造初始 Feed 数据
        var originalFeeds = [FeedPreview]()
        var tempFeeds: [String: PushFeedInfo] = [:]
        var tempFeedIds: [String] = []
        var updateOrRemoveFeeds: [String: PushFeedInfo] = [:]

        for i in (1...count).reversed() {
            originalFeeds.append(MockFeed.generateFeedPreview(feedID: "\(i)", rankTime: Int64(i), avatarKey: "\(i)"))
            // 构造临时数据
            if i % step == 0 {
                let pushFeedInfo = MockFeed.generatePushFeedInfo(feedID: "\(i)", rankTime: Int64(i), avatarKey: "\(i)", types: [.inbox, .message, .unread])
                tempFeeds["\(i)"] = pushFeedInfo
                updateOrRemoveFeeds["\(i)"] = pushFeedInfo
                tempFeedIds.append("\(i)")
            }
        }
        let originalResult = GetFeedCardsResult(filterType: MockFeed.defaultFilter,
                                                feeds: originalFeeds,
                                                nextCursor: Feed_V1_FeedCursor.min,
                                                timeCost: 0.1,
                                                tempFeedIds: [],
                                                feedRuleMd5: MockFeed.feedRuleMd5,
                                                traceId: MockFeed.traceId)
        MockNetWorkResponse.getFeedCardsTriggerResult(originalResult)

        // Active 时 Push，预期 vm.provier 数量不变
        mainWait()
        let filtersInfo = PushFeedFilterInfo(type: .unread, unread: 0, muteUnread: 0)
        let pushFeedPreviewForDirty = MockFeed.generatePushFeedPreview(updateFeeds: [:],
                                                                       tempFeeds: tempFeeds,
                                                                       updateOrRemoveFeeds: [:],
                                                                       removeFeeds: [],
                                                                       filtersInfo: [.unread: filtersInfo])

        guard let userPushCenter = try? feedListViewModel.userResolver.userPushCenter else { return }

        userPushCenter.post(pushFeedPreviewForDirty)

        mainWait(0.5)
        let pushFeedPreview = MockFeed.generatePushFeedPreview(updateFeeds: [:],
                                                               tempFeeds: [:],
                                                               updateOrRemoveFeeds: updateOrRemoveFeeds,
                                                               removeFeeds: [],
                                                               filtersInfo: [.unread: filtersInfo])

        userPushCenter.post(pushFeedPreview)

        mainWait(0.5)
        feedListViewModel.queue.waitUntilAllOperationsAreFinished()
        for (id, _) in updateOrRemoveFeeds {
            XCTAssertTrue(feedListViewModel.provider.getItemBy(id: id) != nil)
        }

        let removedCount = Int(self.count / self.step)

        // 分组取消 Active 时，预期 vm.provier 移除 temp Feed
        feedListViewModel.willResignActive()
        feedListViewModel.queue.waitUntilAllOperationsAreFinished()
        feedListViewModel.commit { [weak self, weak feedListViewModel] in
            guard let self = self else { return }
            guard let feedListViewModel = feedListViewModel else { return }
            XCTAssertTrue(feedListViewModel.provider.getItemsArray().count == (self.count - removedCount))
        }
        feedListViewModel.queue.waitUntilAllOperationsAreFinished()
    }
}
// swiftlint:enable all
