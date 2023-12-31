//
//  NoJumpToMuteTabClickWithOnlyMuteBadgeIntegrationTest.swift
//  LarkFeed-Unit-Tests
//
//  Created by 白镜吾 on 2023/11/1.
//

import Foundation
import XCTest
import LarkContainer
import LarkSDKInterface
import LarkOpenFeed
import LarkModel
import RustPB
@testable import LarkFeed

// MARK: 当仅有 mute badge 时，命中分组设置优化 fg，双击不会跳转到免打扰分组
// https://meego.feishu.cn/larksuite/issue/detail/10021939
final class NoJumpToMuteTabClickWithOnlyMuteBadgeIntegrationTest: XCTestCase {

    let container = MockAssembly.generateContainer()

    let feedCounts = 20
    let unReadIndex = 10
    let muteUnreadIndex = 15
    let defaultUnreadCount = 1
    let defaultMuteUnreadCount = 1

    func testNoJumpToMuteTabClickWithOnlyMuteBadgeIntegrationTest() {
        let resolver = container.getCurrentUserResolver().resolver

        // 第 10 个为红点未读 Feed: item.isRemind && item.unreadCount > 0
        // 第 15 个为灰点未读 Feed: !item.isRemind && item.unreadCount > 0
        // 最多存在 1 个红点和 1 个灰点
        let unreadCounts: [Int] = [0, defaultUnreadCount]
        let muteUnreadCounts = [0, defaultMuteUnreadCount]
        let defaultFilterTypes: [Feed_V1_FeedFilter.TypeEnum] = [.unread, .message]
        let position = IndexPath(row: FindUnreadConfig.invalidValue, section: 0)
        var logInfo = [String: Any]()

        for defaultFilterType in defaultFilterTypes {
            for unreadCount in unreadCounts {
                for muteUnreadCount in muteUnreadCounts {
                    guard let baseDependency = try? resolver.resolve(assert: BaseFeedsViewModelDependency.self) else { return }
                    guard let dependency = try? resolver.resolve(assert: FeedListViewModelDependency.self) else { return }
                    guard let feedContext = try? resolver.resolve(assert: FeedContextService.self) else { return }
                    let data = generateValidationData(filterType: defaultFilterType, unread: unreadCount, muteUnread: muteUnreadCount)
                    // 构造的 Feed 初始化时的首屏数据
                    let originalResult = data.getFeedCardsResult
                    // 构造的 Feed Push 更新数据（包含未读、免打扰未读信息）
                    let pushFeedPreview = data.pushFeedPreview
                    // 设置 Feed 处于未读分组，之后双击 Tab 会进行 【未读 -> 消息】 分组的改变
                    let feedListViewModel = MockFeed.generateFeedListViewModel(filterType: defaultFilterType,
                                                                               dependency: dependency,
                                                                               baseDependency: baseDependency,
                                                                               feedContext: feedContext)
                    guard let feedListVC = try? FeedListViewController(listViewModel: feedListViewModel) else { return }
                    // bind()在 viewdidiLoad 时调用，这儿 VC 不会进入 ViewDidiload，所以手动调用
                    feedListVC.bind()
                    feedListVC.willActive()
                    MockNetWorkResponse.getFeedCardsTriggerResult(originalResult)
                    mainWait()

                    guard let userPushCenter = try? feedListViewModel.userResolver.userPushCenter else { return }
                    userPushCenter.post(pushFeedPreview)
                    mainWait()

                    feedListVC.listViewModel.queue.waitUntilAllOperationsAreFinished()

                    // 双击 tab 触发 doubleClickTabbar() -> getNextUnreadFeedPosition()
                    // 因为 doubleClickTabbar 涉及到更上层的 VC 刷新调整，因此此处仅验证 feedListVC 数据是否合法
                    let result = feedListVC.feedFindUnreadPlugin.getNextUnreadFeedPosition(provider: feedListVC, fromPosition: position, logInfo: &logInfo)
                    // 校验结果
                    self.verifyTestValue(vc: feedListVC, currentFilter: defaultFilterType, unread: unreadCount, muteUnread: muteUnreadCount, finderResult: result)
                }
            }
        }
    }
}

extension NoJumpToMuteTabClickWithOnlyMuteBadgeIntegrationTest {
    func verifyTestValue(vc: FeedListViewController,
                         currentFilter: Feed_V1_FeedFilter.TypeEnum,
                         unread: Int,
                         muteUnread: Int,
                         finderResult: FeedFinderItemPosition?) {
        guard let finderResult = finderResult else {
            // 均为 0 的情况下，返回 nil
            XCTAssertEqual(unread, 0)
            XCTAssertEqual(muteUnread, 0)
            return
        }
        let feeds = vc.listViewModel.provider.getItemsArray()

        if unread > 0 {
            guard case .position(let indexPath) = finderResult else { XCTAssertTrue(false); return }
            // 消息分组下，有红点，无论灰点的数量如何，都应该优先返回红点所在的 index
            let index = indexPath.row
            for (id, feed) in feeds.enumerated() {
                let isRemind = feed.isRemind
                let unreadCount = feed.unreadCount
                let feedID = Int(feed.feedPreview.id)
                XCTAssertNotNil(feedID)
                if feedID == self.unReadIndex {
                    XCTAssertEqual(isRemind, true)
                    XCTAssertEqual(unreadCount, self.defaultUnreadCount)
                    XCTAssertEqual(id, index)
                } else {
                    XCTAssertEqual(isRemind, false)
                }
            }
        } else {
            if currentFilter == .message {
                if muteUnread > 0 {
                    guard case .position(let indexPath) = finderResult else { XCTAssertTrue(false); return }
                    // 消息分组下，有红点，无论灰点的数量如何，都应该优先返回红点所在的 index
                    let index = indexPath.row
                    for (id, feed) in feeds.enumerated() {
                        let isRemind = feed.isRemind
                        let unreadCount = feed.unreadCount
                        let feedID = Int(feed.feedPreview.id)
                        XCTAssertNotNil(feedID)
                        if feedID == self.muteUnreadIndex {
                            XCTAssertEqual(isRemind, false)
                            XCTAssertEqual(unreadCount, self.defaultMuteUnreadCount)
                            XCTAssertEqual(id, index)
                        } else {
                            XCTAssertEqual(unreadCount, 0)
                        }
                    }
                } else {
                    guard case .tab(let filterType) = finderResult else { XCTAssertTrue(false); return }
                    XCTAssertEqual(filterType, vc.defaultTab)
                }
            } else if currentFilter == .unread {
                if muteUnread > 0 {
                    guard case .tab(let filterType) = finderResult else { XCTAssertTrue(false); return }
                    XCTAssertEqual(filterType, .mute)
                } else {
                    guard case .tab(let filterType) = finderResult else { XCTAssertTrue(false); return }
                    XCTAssertEqual(filterType, vc.defaultTab)
                }
            }
        }
    }

    // 构造数据，分别构造红点存在/不存在、灰点存在/不存在的数据
    func generateValidationData(filterType: Feed_V1_FeedFilter.TypeEnum,
                                unread: Int,
                                muteUnread: Int) -> (getFeedCardsResult: GetFeedCardsResult, pushFeedPreview: PushFeedPreview) {
        // 当前分组拉取首屏数据，构造初始 Feed 数据
        var originalFeeds = [FeedPreview]()
        var updateFeeds: [String: PushFeedInfo] = [:]

        for i in (1...self.feedCounts).reversed() {
            let feedID = "\(i)"
            let rankTime = Int64(i)
            let avatarKey = "\(i)"
            var isRemind: Bool = false
            var unreadCount: Int32 = 0
            var types: [FeedFilterType] = [.inbox, .message]
            originalFeeds.append(MockFeed.generateFeedPreview(feedID: feedID, rankTime: rankTime, avatarKey: avatarKey))
            // 构造未读数据，
            // 第 10 和 第 20 个为 红点未读 Feed: item.isRemind && item.unreadCount > 0
            // 第 15 和 第 30 个为 灰点未读 Feed: !item.isRemind && item.unreadCount > 0
            if unread > 0, i == unReadIndex {
                isRemind = true
                unreadCount = Int32(self.defaultUnreadCount)
                types.append(.unread)
            }
            if muteUnread > 0, i == muteUnreadIndex {
                isRemind = false
                unreadCount = Int32(self.defaultMuteUnreadCount)
                types.append(.mute)
            }
            let chatData = MockFeed.generateChatData(rankTime: rankTime,
                                                     avatarKey: avatarKey,
                                                     isRemind: isRemind,
                                                     unreadCount: unreadCount)
            let pushFeedInfo = MockFeed.generatePushFeedInfo(feedID: feedID,
                                                             rankTime: rankTime,
                                                             avatarKey: avatarKey,
                                                             types: types,
                                                             extraData: .chatData(chatData))
            updateFeeds["\(i)"] = pushFeedInfo
        }
        // 生成首屏数据
        let originalResult = GetFeedCardsResult(filterType: filterType,
                                                feeds: originalFeeds,
                                                nextCursor: Feed_V1_FeedCursor.min,
                                                timeCost: 0.1,
                                                tempFeedIds: [],
                                                feedRuleMd5: MockFeed.feedRuleMd5,
                                                traceId: MockFeed.traceId)

        // 生成 Push Feed 数据
        let inboxFilterInfo: PushFeedFilterInfo = PushFeedFilterInfo(type: .inbox, unread: unread, muteUnread: muteUnread)
        let messageFilterInfo: PushFeedFilterInfo = PushFeedFilterInfo(type: .message, unread: unread, muteUnread: muteUnread)
        let unreadFilterInfo: PushFeedFilterInfo = PushFeedFilterInfo(type: .unread, unread: unread, muteUnread: 0)
        let muteFilterInfo: PushFeedFilterInfo = PushFeedFilterInfo(type: .mute, unread: 0, muteUnread: muteUnread)
        let pushFeedPreview = MockFeed.generatePushFeedPreview(updateFeeds: updateFeeds,
                                                               tempFeeds: [:],
                                                               updateOrRemoveFeeds: [:],
                                                               removeFeeds: [],
                                                               filtersInfo: [.inbox: inboxFilterInfo,
                                                                             .unread: unreadFilterInfo,
                                                                             .message: messageFilterInfo,
                                                                             .mute: muteFilterInfo])
        return (originalResult, pushFeedPreview)
    }
}
