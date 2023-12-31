//
//  MainFeedsViewModelTest.swift
//  LarkMessengerUnitTest
//
//  Created by 袁平 on 2020/8/26.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import XCTest
import RustPB
import RxSwift
import LarkSDKInterface
import SwiftProtobuf
import LarkMessengerInterface
import RxRelay
import LarkNavigation
import AnimatedTabBar
import RunloopTools
import LarkFeatureGating
import LarkAccountInterface
import LarkModel
@testable import LarkFeed
import LarkTab

// swiftlint:disable all
class MainFeedsViewModelTest: XCTestCase {
    var mainFeedsVM: MainFeedsViewModel!
    fileprivate var mockDependency: MockTabFeedsViewModelDependency!
    fileprivate var mockBaseDependency: MockBaseFeedsViewModelDependency!
    var disposeBag: DisposeBag!

    override class func setUp() {
        // 需要注册，否则测试PushFeedPreview时会命中assert
        TabRegistry.register(Tab.feed) { (_) -> TabRepresentable in
            return FeedTab()
        }

        // Chat
        FeedSupplement.shared.registerTableViewCellAndViewModel(.chat, BaseFeedTableCell.self) { (feed, type) -> BaseFeedTableCellViewModel? in
            BaseFeedTableCellViewModel(feedCardPreview: feed, bizType: type)
        }

        // Thread
        FeedSupplement.shared.registerTableViewCellAndViewModel(.thread, BaseFeedTableCell.self) { feed, type in
            BaseFeedTableCellViewModel(feedCardPreview: feed, bizType: type)
        }

        RunloopDispatcher.enable = true

        MockAccountService.login()

        LarkFeatureGating.shared.loadFeatureValues(with: AccountServiceAdapter.shared.currentChatterId)
        // 打开cache FG
        LarkFeatureGating.shared.updateFeatureBoolValue(for: FeatureGatingKey.feedCacheEnabled, value: true)
    }

    override func setUp() {
        super.setUp()
        mockDependency = MockTabFeedsViewModelDependency()
        mockBaseDependency = MockBaseFeedsViewModelDependency()
        mainFeedsVM = MainFeedsViewModel(dependency: mockDependency,
                                         baseDependency: mockBaseDependency)

        disposeBag = DisposeBag()
    }

    override func tearDown() {
        mainFeedsVM = nil
        mockDependency = nil
        mockBaseDependency = nil
        disposeBag = nil
        super.tearDown()
    }

    // MARK: - updateFeeds: 更新Feed

    /// updateFeeds不再测试sort的内容，FeedProviderTest中已包括
    /// case 1: 正常触发信号更新
    func test_updateFeeds() {
        var feedCard = buildFeedPreview()
        feedCard.id = "123456"
        feedCard.type = .chat
        feedCard.feedType = .inbox
        mainFeedsVM.updateFeeds([feedCard], .none)

        mainWait()

        let section = self.mainFeedsVM.feedsRelay.value
        XCTAssert(section.items.count == 1)
        XCTAssert(section.items.first?.feedCardPreview.id == "123456")
        let allItems = self.mainFeedsVM.provider.getItemsArray()
        XCTAssert(allItems.count == 1)
        XCTAssert(allItems[0].feedCardPreview.id == "123456")
        // 拿到数据，取消Loading
        XCTAssert(mainFeedsVM.shouldShowLoading == false)
    }

    /// case 2: 空数组，触发reload
    func test_updateFeeds_empty() {
        // 初始数据: 要测试的是updateFeeds方法，所以初始数据不应该通过updateFeeds更新
        var feedCard = buildFeedPreview()
        feedCard.id = "123456"
        feedCard.type = .chat
        feedCard.feedType = .inbox
        let cellVM = BaseFeedTableCellViewModel(feedCardPreview: feedCard, bizType: .inbox)
        mainFeedsVM.provider.updateItems([cellVM!])

        mainFeedsVM.updateFeeds([], .reload)

        mainWait()

        let section = self.mainFeedsVM.feedsRelay.value
        XCTAssert(section.items.count == 1)
        XCTAssert(section.items.first?.feedCardPreview.id == "123456")
    }

    /// case 3: type = .ignore, 只更新总数据源，不触发刷新
    func test_updateFeeds_ignore() {
        // UI数据初始数据：用于验证是否触发UI数据更新
        var section1 = SectionHolder()
        var feedCard1 = buildFeedPreview()
        feedCard1.feedType = .inbox
        feedCard1.id = "123456"
        feedCard1.type = .chat
        feedCard1.rankTime = 123_456
        let cellVM1 = BaseFeedTableCellViewModel(feedCardPreview: feedCard1, bizType: .inbox)
        section1.items = [cellVM1!]
        section1.type = .reload
        mainFeedsVM.feedsRelay.accept(section1)

        // 总数据源初始数据：用于验证是否触发UI数据更新
        mainFeedsVM.provider.updateItems([cellVM1!])

        // 2s后再更新，因为BaseVM初始化时会监听relay，会有默认值
        asyncAfter(.now() + 2) {
            var feedCard2 = buildFeedPreview()
            feedCard2.id = "654321"
            feedCard2.type = .chat
            feedCard2.feedType = .inbox
            feedCard2.rankTime = 654_321
            // ignore触发更新
            self.mainFeedsVM.updateFeeds([feedCard2], .ignore)
        }

        mainWait(3)

        let uiSection = self.mainFeedsVM.feedsRelay.value
        XCTAssert(uiSection.items.count == 1)
        XCTAssert(uiSection.items.first?.feedCardPreview.id == "123456")

        let allItems = self.mainFeedsVM.provider.getItemsArray()
        XCTAssert(allItems.count == 2)
        XCTAssert(allItems[0].feedCardPreview.id == "654321")
        XCTAssert(allItems[1].feedCardPreview.id == "123456")
    }

    /// case 4: 多线程更新
    func test_updateFeeds_async() {
        async {
            var feedCard = buildFeedPreview()
            feedCard.id = "1"
            feedCard.rankTime = 1
            feedCard.type = .chat
            feedCard.feedType = .inbox
            self.mainFeedsVM.updateFeeds([feedCard], .reload)
        }
        async {
            var feedCard = buildFeedPreview()
            feedCard.id = "3"
            feedCard.rankTime = 3
            feedCard.type = .chat
            feedCard.feedType = .inbox
            self.mainFeedsVM.updateFeeds([feedCard], .reload)
        }
        async {
            var feedCard = buildFeedPreview()
            feedCard.id = "2"
            feedCard.rankTime = 2
            feedCard.type = .chat
            feedCard.feedType = .inbox
            self.mainFeedsVM.updateFeeds([feedCard], .reload)
        }

        mainWait()

        let uiSection = self.mainFeedsVM.feedsRelay.value
        XCTAssert(uiSection.items.count == 3)
        XCTAssert(uiSection.items[0].feedCardPreview.id == "3")
        XCTAssert(uiSection.items[1].feedCardPreview.id == "2")
        XCTAssert(uiSection.items[2].feedCardPreview.id == "1")

        let allItems = self.mainFeedsVM.provider.getItemsArray()
        XCTAssert(allItems.count == 3)
        XCTAssert(allItems[0].feedCardPreview.id == "3")
        XCTAssert(allItems[1].feedCardPreview.id == "2")
        XCTAssert(allItems[2].feedCardPreview.id == "1")
    }

    // MARK: - removeFeeds: 移除Feed

    // case 1: 正常触发remove和信号更新
    func test_removeFeeds() {
        // UI数据初始数据
        var section1 = SectionHolder()
        var feedCard1 = buildFeedPreview()
        feedCard1.id = "123456"
        feedCard1.type = .chat
        feedCard1.feedType = .inbox
        let cellVM1 = BaseFeedTableCellViewModel(feedCardPreview: feedCard1, bizType: .inbox)
        section1.items = [cellVM1!]
        section1.type = .reload
        mainFeedsVM.feedsRelay.accept(section1)
        // 总数据源初始数据
        mainFeedsVM.provider.updateItems([cellVM1!])

        self.mainFeedsVM.removeFeeds(["123456"], .reload)

        mainWait()

        let section = self.mainFeedsVM.feedsRelay.value
        XCTAssert(section.items.isEmpty)
        let allItems = self.mainFeedsVM.provider.getItemsArray()
        XCTAssert(allItems.isEmpty)
    }

    // case 2: 移除不存在的Id
    func test_removeFeeds_illegalId() {
        // UI数据初始数据
        var section1 = SectionHolder()
        var feedCard1 = buildFeedPreview()
        feedCard1.id = "123456"
        feedCard1.type = .chat
        feedCard1.feedType = .inbox
        let cellVM1 = BaseFeedTableCellViewModel(feedCardPreview: feedCard1, bizType: .inbox)
        section1.items = [cellVM1!]
        section1.type = .none
        mainFeedsVM.feedsRelay.accept(section1)
        // 总数据源初始数据
        mainFeedsVM.provider.updateItems([cellVM1!])

        self.mainFeedsVM.removeFeeds(["1"], .reload)

        mainWait()

        let section = self.mainFeedsVM.feedsRelay.value
        XCTAssert(section.items.count == 1)
        XCTAssert(section.items[0].feedCardPreview.id == "123456")
        let allItems = self.mainFeedsVM.provider.getItemsArray()
        XCTAssert(allItems.count == 1)
        XCTAssert(allItems[0].feedCardPreview.id == "123456")
    }

    // case 3: 多线程移除
    func test_removeFeeds_async() {
        // UI数据初始数据
        var section1 = SectionHolder()
        var feedCard1 = buildFeedPreview()
        feedCard1.id = "1"
        feedCard1.type = .chat
        feedCard1.feedType = .inbox
        let cellVM1 = BaseFeedTableCellViewModel(feedCardPreview: feedCard1, bizType: .inbox)
        var feedCard2 = buildFeedPreview()
        feedCard2.id = "2"
        feedCard2.type = .chat
        feedCard2.feedType = .inbox
        let cellVM2 = BaseFeedTableCellViewModel(feedCardPreview: feedCard2, bizType: .inbox)
        var feedCard3 = buildFeedPreview()
        feedCard3.id = "3"
        feedCard3.type = .chat
        feedCard3.feedType = .inbox
        let cellVM3 = BaseFeedTableCellViewModel(feedCardPreview: feedCard3, bizType: .inbox)
        section1.items = [cellVM1!, cellVM2!, cellVM3!]
        section1.type = .none
        mainFeedsVM.feedsRelay.accept(section1)
        // 总数据源初始数据
        mainFeedsVM.provider.updateItems([cellVM1!, cellVM2!, cellVM3!])

        async {
            self.mainFeedsVM.removeFeeds(["1"], .reload)
        }
        async {
            self.mainFeedsVM.removeFeeds(["2"], .reload)
        }
        async {
            self.mainFeedsVM.removeFeeds(["1"], .reload)
        }
        async {
            self.mainFeedsVM.removeFeeds(["4"], .reload)
        }

        mainWait()

        let section = self.mainFeedsVM.feedsRelay.value
        XCTAssert(section.items.count == 1)
        XCTAssert(section.items[0].feedCardPreview.id == "3")
        let allItems = self.mainFeedsVM.provider.getItemsArray()
        XCTAssert(allItems.count == 1)
        XCTAssert(allItems[0].feedCardPreview.id == "3")
    }

    // MARK: - removeAllFeeds: 移除所有Feed

    /// case 1: 正常removeAll和触发刷新
    func test_removeAllFeeds() {
        // UI数据初始数据
        var section1 = SectionHolder()
        var feedCard1 = buildFeedPreview()
        feedCard1.id = "123456"
        feedCard1.type = .chat
        feedCard1.feedType = .inbox
        let cellVM1 = BaseFeedTableCellViewModel(feedCardPreview: feedCard1, bizType: .inbox)
        section1.items = [cellVM1!]
        section1.type = .none
        mainFeedsVM.feedsRelay.accept(section1)
        // 总数据源初始数据
        mainFeedsVM.provider.updateItems([cellVM1!])

        mainFeedsVM.removeAllFeeds(.reload)

        mainWait()

        let section = self.mainFeedsVM.feedsRelay.value
        XCTAssert(section.items.isEmpty)
        let allItems = self.mainFeedsVM.provider.getItemsArray()
        XCTAssert(allItems.isEmpty)
    }

    /// case 2: 多线程移除
    func test_removeAllFeeds_async() {
        // UI数据初始数据
        var section1 = SectionHolder()
        var feedCard1 = buildFeedPreview()
        feedCard1.id = "123456"
        feedCard1.type = .chat
        feedCard1.feedType = .inbox
        let cellVM1 = BaseFeedTableCellViewModel(feedCardPreview: feedCard1, bizType: .inbox)
        section1.items = [cellVM1!]
        section1.type = .none
        mainFeedsVM.feedsRelay.accept(section1)
        // 总数据源初始数据
        mainFeedsVM.provider.updateItems([cellVM1!])

        async {
            self.mainFeedsVM.removeAllFeeds(.reload)
        }
        async {
            self.mainFeedsVM.removeAllFeeds(.reload)
        }
        async {
            self.mainFeedsVM.removeAllFeeds(.reload)
        }

        mainWait()

        let section = self.mainFeedsVM.feedsRelay.value
        XCTAssert(section.items.isEmpty)
        let allItems = self.mainFeedsVM.provider.getItemsArray()
        XCTAssert(allItems.isEmpty)
    }

    // MARK: - handleFeedPreviewPush

    /// case 1: push触发Feed更新
    func test_handleFeedPreviewPush_update() {
        var feedCard1 = buildFeedPreview()
        feedCard1.id = "1"
        feedCard1.type = .chat
        feedCard1.feedType = .inbox
        let push = PushFeedPreview(updatePreviews: [feedCard1],
                                   removePreviews: [],
                                   unreadCount: 0,
                                   filteredUnreadCount: 0,
                                   filteredMuteUnreadCount: 0,
                                   delayedChannelCount: 0)
        mainFeedsVM.handleFeedPreviewPush(push)

        mainWait()

        let section = self.mainFeedsVM.feedsRelay.value
        XCTAssert(section.items.count == 1)
        XCTAssert(section.items[0].feedCardPreview.id == "1")
        let allItems = self.mainFeedsVM.provider.getItemsArray()
        XCTAssert(allItems.count == 1)
        XCTAssert(allItems[0].feedCardPreview.id == "1")
    }

    /// case 2: push触发Feed删除
    func test_handleFeedPreviewPush_remove() {
        // UI数据初始数据
        var section1 = SectionHolder()
        var feedCard = buildFeedPreview()
        feedCard.id = "1"
        feedCard.type = .chat
        feedCard.feedType = .inbox
        let cellVM1 = BaseFeedTableCellViewModel(feedCardPreview: feedCard, bizType: .inbox)
        section1.items = [cellVM1!]
        section1.type = .none
        mainFeedsVM.feedsRelay.accept(section1)
        // 总数据源初始数据
        mainFeedsVM.provider.updateItems([cellVM1!])

        let removePreviews = ["1", "2"].map({ PushFeedPreview.CardPair(id: $0, type: .chat) })
        let push = PushFeedPreview(updatePreviews: [],
                                   removePreviews: removePreviews,
                                   unreadCount: 0,
                                   filteredUnreadCount: 0,
                                   filteredMuteUnreadCount: 0,
                                   delayedChannelCount: 0)
        mainFeedsVM.handleFeedPreviewPush(push)

        mainWait()

        let section = self.mainFeedsVM.feedsRelay.value
        XCTAssert(section.items.isEmpty)
        let allItems = self.mainFeedsVM.provider.getItemsArray()
        XCTAssert(allItems.isEmpty)
    }

    /// case 3: 更新 + 删除
    func test_handleFeedPreviewPush_updateAndRemove() {
        // UI数据初始数据
        var section1 = SectionHolder()
        var feedCard = buildFeedPreview()
        feedCard.id = "1"
        feedCard.type = .chat
        feedCard.feedType = .inbox
        let cellVM1 = BaseFeedTableCellViewModel(feedCardPreview: feedCard, bizType: .inbox)
        section1.items = [cellVM1!]
        section1.type = .none
        mainFeedsVM.feedsRelay.accept(section1)
        // 总数据源初始数据
        mainFeedsVM.provider.updateItems([cellVM1!])

        var feedCard1 = buildFeedPreview()
        feedCard1.id = "2"
        feedCard1.type = .chat
        feedCard1.feedType = .inbox
        var feedCard2 = buildFeedPreview()
        feedCard2.id = "3"
        feedCard2.type = .chat
        feedCard2.feedType = .inbox
        // 待删除数据中有当前正更新的，预期应该是该Feed（"2"）被删除
        let removePreviews = ["1", "2"].map({ PushFeedPreview.CardPair(id: $0, type: .chat) })
        let push = PushFeedPreview(updatePreviews: [feedCard1, feedCard2],
                                   removePreviews: removePreviews,
                                   unreadCount: 0,
                                   filteredUnreadCount: 0,
                                   filteredMuteUnreadCount: 0,
                                   delayedChannelCount: 0)
        mainFeedsVM.handleFeedPreviewPush(push)

        mainWait()

        let section = self.mainFeedsVM.feedsRelay.value
        XCTAssert(section.items.count == 1)
        XCTAssert(section.items[0].feedCardPreview.id == "3")
        let allItems = self.mainFeedsVM.provider.getItemsArray()
        XCTAssert(allItems.count == 1)
        XCTAssert(allItems[0].feedCardPreview.id == "3")
    }

    // MARK: - handleBadgeStylePush

    /// case 1: 触发table reload
    func test_handleBadgeStylePush() {
        // 2s后执行，去除relay初始值影响
        asyncAfter(.now() + 2) {
            // 初始值
            BaseFeedsViewModel.badgeStyle = .weakRemind
            var section = SectionHolder()
            section.type = .none
            self.mainFeedsVM.feedsRelay.accept(section)

            self.mainFeedsVM.handleBadgeStylePush(.strongRemind)
        }

        mainWait(3)

        XCTAssert(BaseFeedsViewModel.badgeStyle == .strongRemind)
        XCTAssert(self.mainFeedsVM.feedsRelay.value.type == .reload)
    }

    // MARK: - displayFilter

    /// case 1: 会话盒子数据不显示
    func test_displayFilter_box() {
        var feed = buildFeedPreview()
        // 会话盒子中Cell的parentCardID大于0
        feed.parentCardID = "1"
        let cellVM = BaseFeedTableCellViewModel(feedCardPreview: feed, bizType: .inbox)
        XCTAssert(mainFeedsVM.displayFilter(cellVM!) == false)
    }

    /// case 2: feedType != .inbox不显示
    func test_displayFilter_feedType() {
        var feed = buildFeedPreview()
        feed.feedType = .done
        let cellVM = BaseFeedTableCellViewModel(feedCardPreview: feed, bizType: .inbox)
        XCTAssert(mainFeedsVM.displayFilter(cellVM!) == false)
    }

    /// case 3: currentSubFilterType = .all, 全部显示
    func test_displayFilter_all() {
        mainFeedsVM.currentSubFilterType = .all
        var feed = buildFeedPreview()
        feed.feedType = .inbox
        let cellVM = BaseFeedTableCellViewModel(feedCardPreview: feed, bizType: .inbox)
        XCTAssert(mainFeedsVM.displayFilter(cellVM!) == true)
    }

    /// case 4: currentSubFilterType = .secretChat, 只显示Chat密聊
    func test_displayFilter_secretChat() {
        mainFeedsVM.currentSubFilterType = .secretChat
        // 非chat类型，不显示
        var feed1 = buildFeedPreview()
        feed1.feedType = .inbox
        feed1.type = .openappChat
        let cellVM1 = BaseFeedTableCellViewModel(feedCardPreview: feed1, bizType: .inbox)
        // chat类型，非密聊，不显示
        var feed2 = buildFeedPreview()
        feed2.feedType = .inbox
        feed2.type = .chat
        feed2.isCrypto = false
        let cellVM2 = BaseFeedTableCellViewModel(feedCardPreview: feed2, bizType: .inbox)
        // chat类型，密聊，显示
        var feed3 = buildFeedPreview()
        feed3.feedType = .inbox
        feed3.type = .chat
        feed3.isCrypto = true
        let cellVM3 = BaseFeedTableCellViewModel(feedCardPreview: feed3, bizType: .inbox)

        XCTAssert(mainFeedsVM.displayFilter(cellVM1!) == false)
        XCTAssert(mainFeedsVM.displayFilter(cellVM2!) == false)
        XCTAssert(mainFeedsVM.displayFilter(cellVM3!) == true)
    }

    /// case 5: currentSubFilterType = .external, 只显示外部
    func test_displayFilter_external() {
        mainFeedsVM.currentSubFilterType = .external

        // chat类型，外部，显示
        var feed1 = buildFeedPreview()
        feed1.feedType = .inbox
        feed1.type = .chat
        feed1.crossTenant = true
        let cellVM1 = BaseFeedTableCellViewModel(feedCardPreview: feed1, bizType: .inbox)
        // doc类型，外部，显示
        var feed2 = buildFeedPreview()
        feed2.feedType = .inbox
        feed2.type = .docFeed
        feed2.crossTenant = true
        let cellVM2 = BaseFeedTableCellViewModel(feedCardPreview: feed2, bizType: .inbox)
        // chat类型，非外部，不显示
        var feed3 = buildFeedPreview()
        feed3.feedType = .inbox
        feed3.type = .docFeed
        feed3.crossTenant = false
        let cellVM3 = BaseFeedTableCellViewModel(feedCardPreview: feed3, bizType: .inbox)

        XCTAssert(mainFeedsVM.displayFilter(cellVM1!) == true)
        XCTAssert(mainFeedsVM.displayFilter(cellVM2!) == true)
        XCTAssert(mainFeedsVM.displayFilter(cellVM3!) == false)
    }

    /// case 6: currentSubFilterType = .chat，显示chat，box，openapp，openappChat类型
    func test_displayFilter_chat() {
        mainFeedsVM.currentSubFilterType = .chat

        // chat类型，显示
        var feed1 = buildFeedPreview()
        feed1.feedType = .inbox
        feed1.type = .chat
        let cellVM1 = BaseFeedTableCellViewModel(feedCardPreview: feed1, bizType: .inbox)
        // box类型，显示
        var feed2 = buildFeedPreview()
        feed2.feedType = .inbox
        feed2.type = .box
        let cellVM2 = BaseFeedTableCellViewModel(feedCardPreview: feed2, bizType: .inbox)
        // openapp类型，不显示
        var feed3 = buildFeedPreview()
        feed3.feedType = .inbox
        feed3.type = .openapp
        let cellVM3 = BaseFeedTableCellViewModel(feedCardPreview: feed3, bizType: .inbox)
        // openappChat类型，显示
        var feed4 = buildFeedPreview()
        feed4.feedType = .inbox
        feed4.type = .openappChat
        let cellVM4 = BaseFeedTableCellViewModel(feedCardPreview: feed4, bizType: .inbox)
        // doc类型，不显示
        var feed5 = buildFeedPreview()
        feed5.feedType = .inbox
        feed5.type = .docFeed
        let cellVM5 = BaseFeedTableCellViewModel(feedCardPreview: feed5, bizType: .inbox)

        XCTAssert(mainFeedsVM.displayFilter(cellVM1!) == true)
        XCTAssert(mainFeedsVM.displayFilter(cellVM2!) == true)
        XCTAssert(mainFeedsVM.displayFilter(cellVM3!) == true)
        XCTAssert(mainFeedsVM.displayFilter(cellVM4!) == true)
        XCTAssert(mainFeedsVM.displayFilter(cellVM5!) == false)
    }

    /// case 7: currentSubFilterType = .doc, 只显示docFeed类型
    func test_displayFilter_doc() {
        mainFeedsVM.currentSubFilterType = .doc

        // chat类型，不显示
        var feed1 = buildFeedPreview()
        feed1.feedType = .inbox
        feed1.type = .chat
        let cellVM1 = BaseFeedTableCellViewModel(feedCardPreview: feed1, bizType: .inbox)
        // doc类型，显示
        var feed2 = buildFeedPreview()
        feed2.feedType = .inbox
        feed2.type = .docFeed
        let cellVM2 = BaseFeedTableCellViewModel(feedCardPreview: feed2, bizType: .inbox)

        XCTAssert(mainFeedsVM.displayFilter(cellVM1!) == false)
        XCTAssert(mainFeedsVM.displayFilter(cellVM2!) == true)
    }

    /// case 8: currentSubFilterType = .thread，只显示thread类型
    func test_displayFilter_thread() {
        mainFeedsVM.currentSubFilterType = .thread

        // chat类型，不显示
        var feed1 = buildFeedPreview()
        feed1.feedType = .inbox
        feed1.type = .chat
        let cellVM1 = BaseFeedTableCellViewModel(feedCardPreview: feed1, bizType: .inbox)
        // thread类型，显示
        var feed2 = buildFeedPreview()
        feed2.feedType = .inbox
        feed2.type = .thread
        let cellVM2 = BaseFeedTableCellViewModel(feedCardPreview: feed2, bizType: .inbox)

        XCTAssert(mainFeedsVM.displayFilter(cellVM1!) == false)
        XCTAssert(mainFeedsVM.displayFilter(cellVM2!) == true)
    }

    // MARK: - feedType

    /// case 1: feedType() == .inbox
    func test_feedType() {
        XCTAssert(mainFeedsVM.feedType() == .inbox)
    }

    // MARK: - reset

    /// case 1: 重置cursor和Feed数据
    func test_reset() {
        // 2s后开始重置，取消relay影响
        asyncAfter(.now() + 2) {
            // 初始值
            self.mainFeedsVM.nextCursor = 123
            var cursor = Feed_V1_Cursor()
            cursor.maxCursor = 456
            cursor.minCursor = 1
            self.mainFeedsVM.cursors = [cursor]
            var feedCard = buildFeedPreview()
            feedCard.id = "123456"
            feedCard.type = .chat
            feedCard.feedType = .inbox
            let cellVM = BaseFeedTableCellViewModel(feedCardPreview: feedCard, bizType: .inbox)
            self.mainFeedsVM.provider.updateItems([cellVM!])

            self.mainFeedsVM.reset()
        }

        mainWait(3)

        XCTAssert(self.mainFeedsVM.nextCursor == nil)
        XCTAssert(self.mainFeedsVM.cursors.isEmpty)
        XCTAssert(self.mainFeedsVM.provider.getItemsArray().isEmpty)
    }

    // MARK: - mergeCursors

    /// case 1: self.cursors为空，直接接收当前传入cursors
    func test_mergeCursors_empty() {
        // 初始数据
        mainFeedsVM.cursors.removeAll()
        var cursor = Feed_V1_Cursor()
        cursor.maxCursor = 1000
        cursor.minCursor = 1
        mainFeedsVM.mergeCursors([cursor], 1)

        mainWait()

        XCTAssert(mainFeedsVM.cursors.count == 1)
        XCTAssert(mainFeedsVM.cursors.first?.maxCursor == 1000)
        XCTAssert(mainFeedsVM.cursors.first?.minCursor == 1)
        XCTAssert(mainFeedsVM.nextCursor == 1)
    }

    /// case 2: 原始cursor区间连续，传入cursor区间在中间，merge之后，cursor区间不变
    /// 如：原始cursor是[(1000, 10)]，传入[(50, 20)]，[(100, 80)]， merge之后应为[(1000, 10)]
    func test_mergeCursors_1() {
        // 原始cursor
        var origin = Feed_V1_Cursor()
        origin.maxCursor = 1000
        origin.minCursor = 10
        mainFeedsVM.cursors = [origin]

        // 传入cursor
        var cursor1 = Feed_V1_Cursor()
        cursor1.maxCursor = 50
        cursor1.minCursor = 20
        var cursor2 = Feed_V1_Cursor()
        cursor2.maxCursor = 100
        cursor2.minCursor = 80

        // merge
        mainFeedsVM.mergeCursors([cursor1, cursor2], 1)

        mainWait()

        XCTAssert(mainFeedsVM.cursors.count == 1)
        XCTAssert(mainFeedsVM.cursors.first?.maxCursor == 1000)
        XCTAssert(mainFeedsVM.cursors.first?.minCursor == 10)
        XCTAssert(mainFeedsVM.nextCursor == 1)
    }

    /// case 3: 原始cursor区间连续，传入cursor区间与其有交集
    /// 如：原始cursor是[(1000, 10)]，传入[(50, 5)]，[(1200, 100)]，merge之后应是[(1200, 5)]
    func test_mergeCursors_2() {
        // 原始cursor
        var origin = Feed_V1_Cursor()
        origin.maxCursor = 1000
        origin.minCursor = 10
        mainFeedsVM.cursors = [origin]

        // 传入cursor
        var cursor1 = Feed_V1_Cursor()
        cursor1.maxCursor = 50
        cursor1.minCursor = 5
        var cursor2 = Feed_V1_Cursor()
        cursor2.maxCursor = 1200
        cursor2.minCursor = 100

        // merge
        mainFeedsVM.mergeCursors([cursor1, cursor2], 1)

        mainWait()

        XCTAssert(mainFeedsVM.cursors.count == 1)
        XCTAssert(mainFeedsVM.cursors.first?.maxCursor == 1200)
        XCTAssert(mainFeedsVM.cursors.first?.minCursor == 5)
        XCTAssert(mainFeedsVM.nextCursor == 1)
    }

    /// case 3: 原始cursor区间连续，传入cursor区间与其无交集
    /// 如：原始cursor是[(1000, 10)]，传入[(1200, 1100)]，[(5, 2)]，merge之后应是[(1200, 1100), (1000, 10), (5, 2)]
    func test_mergeCursor_3() {
        // 原始cursor
        var origin = Feed_V1_Cursor()
        origin.maxCursor = 1000
        origin.minCursor = 10
        mainFeedsVM.cursors = [origin]

        // 传入cursor
        var cursor1 = Feed_V1_Cursor()
        cursor1.maxCursor = 1200
        cursor1.minCursor = 1100
        var cursor2 = Feed_V1_Cursor()
        cursor2.maxCursor = 5
        cursor2.minCursor = 2

        // merge
        mainFeedsVM.mergeCursors([cursor1, cursor2], 1)

        mainWait()

        XCTAssert(mainFeedsVM.cursors.count == 3)
        XCTAssert(mainFeedsVM.cursors[0].maxCursor == 1200)
        XCTAssert(mainFeedsVM.cursors[0].minCursor == 1100)
        XCTAssert(mainFeedsVM.cursors[1].maxCursor == 1000)
        XCTAssert(mainFeedsVM.cursors[1].minCursor == 10)
        XCTAssert(mainFeedsVM.cursors[2].maxCursor == 5)
        XCTAssert(mainFeedsVM.cursors[2].minCursor == 2)
        XCTAssert(mainFeedsVM.nextCursor == 1)
    }

    /// case 4: 原始cursor区间不连续，传入cursor区间使其连续
    /// 如：原始cursor是[(1000, 500), (300, 10)]，传入cursor是[(600, 20)]，merge之后是[(1000, 10)]
    func test_mergeCursor_4() {
        // 原始cursor
        var origin1 = Feed_V1_Cursor()
        origin1.maxCursor = 1000
        origin1.minCursor = 500
        var origin2 = Feed_V1_Cursor()
        origin2.maxCursor = 300
        origin2.minCursor = 10
        mainFeedsVM.cursors = [origin1, origin2]

        // 传入cursor
        var cursor = Feed_V1_Cursor()
        cursor.maxCursor = 600
        cursor.minCursor = 20

        // merge
        mainFeedsVM.mergeCursors([cursor], 1)

        mainWait()

        XCTAssert(mainFeedsVM.cursors.count == 1)
        XCTAssert(mainFeedsVM.cursors.first?.maxCursor == 1000)
        XCTAssert(mainFeedsVM.cursors.first?.minCursor == 10)
        XCTAssert(mainFeedsVM.nextCursor == 1)
    }

    /// case 5: 原始cursor区间不连续，传入cursor区间与其中一个有交集
    /// 如：原始cursor是[(1000, 500), (300, 10)]，传入cursor是[(600, 400)]，merge之后[(1000, 400), (300, 10)]
    func test_mergeCursor_5() {
        // 原始cursor
        var origin1 = Feed_V1_Cursor()
        origin1.maxCursor = 1000
        origin1.minCursor = 500
        var origin2 = Feed_V1_Cursor()
        origin2.maxCursor = 300
        origin2.minCursor = 10
        mainFeedsVM.cursors = [origin1, origin2]

        // 传入cursor
        var cursor = Feed_V1_Cursor()
        cursor.maxCursor = 600
        cursor.minCursor = 400

        // merge
        mainFeedsVM.mergeCursors([cursor], 1)

        mainWait()

        XCTAssert(mainFeedsVM.cursors.count == 2)
        XCTAssert(mainFeedsVM.cursors[0].maxCursor == 1000)
        XCTAssert(mainFeedsVM.cursors[0].minCursor == 400)
        XCTAssert(mainFeedsVM.cursors[1].maxCursor == 300)
        XCTAssert(mainFeedsVM.cursors[1].minCursor == 10)
        XCTAssert(mainFeedsVM.nextCursor == 1)
    }

    /// case 6: 原始cursor区间不连续，传入cursor区间与其都无交集
    /// 如：原始cursor是[(1000, 500), (300, 10)]，传入cursor是[(1500, 1200)]，merge之后[(1500, 1200), (1000, 500), (300, 10)]
    func test_mergeCursor_6() {
        // 原始cursor
        var origin1 = Feed_V1_Cursor()
        origin1.maxCursor = 1000
        origin1.minCursor = 500
        var origin2 = Feed_V1_Cursor()
        origin2.maxCursor = 300
        origin2.minCursor = 10
        mainFeedsVM.cursors = [origin1, origin2]

        // 传入cursor
        var cursor = Feed_V1_Cursor()
        cursor.maxCursor = 1500
        cursor.minCursor = 1200

        // merge
        mainFeedsVM.mergeCursors([cursor], 1)

        mainWait()

        XCTAssert(mainFeedsVM.cursors.count == 3)
        XCTAssert(mainFeedsVM.cursors[0].maxCursor == 1500)
        XCTAssert(mainFeedsVM.cursors[0].minCursor == 1200)
        XCTAssert(mainFeedsVM.cursors[1].maxCursor == 1000)
        XCTAssert(mainFeedsVM.cursors[1].minCursor == 500)
        XCTAssert(mainFeedsVM.cursors[2].maxCursor == 300)
        XCTAssert(mainFeedsVM.cursors[2].minCursor == 10)
        XCTAssert(mainFeedsVM.nextCursor == 1)
    }

    /// case 7: 边界条件，当minCursor比下一个maxCursor大1时，cursor区间也会被合并、
    /// 如：原始cursor是[(1000, 10)]，传入cursor区间是[(9, 2)]，merge之后应是[(1000, 2)]
    func test_mergeCursor_7() {
        // 原始cursor
        var origin = Feed_V1_Cursor()
        origin.maxCursor = 1000
        origin.minCursor = 10
        mainFeedsVM.cursors = [origin]

        // 传入cursor
        var cursor = Feed_V1_Cursor()
        cursor.maxCursor = 9
        cursor.minCursor = 2

        // merge
        mainFeedsVM.mergeCursors([cursor], 1)

        mainWait()

        XCTAssert(mainFeedsVM.cursors.count == 1)
        XCTAssert(mainFeedsVM.cursors.first?.maxCursor == 1000)
        XCTAssert(mainFeedsVM.cursors.first?.minCursor == 2)
        XCTAssert(mainFeedsVM.nextCursor == 1)
    }

    /// case 8: 多线程访问
    func test_mergeCursor_8() {
        // 原始cursor
        var origin = Feed_V1_Cursor()
        origin.maxCursor = 1000
        origin.minCursor = 500
        mainFeedsVM.cursors = [origin]

        async {
            var cursor = Feed_V1_Cursor()
            cursor.maxCursor = 1200
            cursor.minCursor = 900
            self.mainFeedsVM.mergeCursors([cursor], 1)
        }
        async {
            var cursor = Feed_V1_Cursor()
            cursor.maxCursor = 200
            cursor.minCursor = 10
            self.mainFeedsVM.mergeCursors([cursor], 1)
        }
        async {
            var cursor = Feed_V1_Cursor()
            cursor.maxCursor = 500
            cursor.minCursor = 2
            self.mainFeedsVM.mergeCursors([cursor], 1)
        }

        mainWait()

        XCTAssert(mainFeedsVM.cursors.count == 1)
        XCTAssert(mainFeedsVM.cursors.first?.maxCursor == 1200)
        XCTAssert(mainFeedsVM.cursors.first?.minCursor == 2)
        XCTAssert(mainFeedsVM.nextCursor == 1)
    }

    /// case 9: 多线程触发nextCursor，预期nextCursor取最小值
    /// 如：传入nextCursor：100，50，30，20，merge之后应是nextCursor = 20
    func test_mergeCursor_9() {
        async {
            self.mainFeedsVM.mergeCursors([], 100)
        }

        async {
            self.mainFeedsVM.mergeCursors([], 20)
        }

        async {
            self.mainFeedsVM.mergeCursors([], 50)
        }

        async {
            self.mainFeedsVM.mergeCursors([], 30)
        }

        mainWait()

        XCTAssert(mainFeedsVM.nextCursor == 20)
    }

    // MARK: - handleIs24HourTime

    /// case 1: 检查是否触发reload
    func test_handleIs24HourTime() {
        // 2s后执行，去除relay初始值影响
        asyncAfter(.now() + 2) {
            // 初始值
            var section = SectionHolder()
            section.type = .none
            self.mainFeedsVM.feedsRelay.accept(section)

            self.mainFeedsVM.handleIs24HourTime()
        }

        mainWait(3)

        XCTAssert(self.mainFeedsVM.feedsRelay.value.type == .reload)
    }

    // MARK: - handleThreadAvatarChangePush

    /// case 1: 传入[]，预期不触发reload，无数据更新
    func test_handleThreadAvatarChangePush_1() {
        // 2s后执行，去除relay初始值影响
        asyncAfter(.now() + 2) {
            // 初始值
            var section = SectionHolder()
            var feedCard = buildFeedPreview()
            feedCard.id = "1"
            feedCard.type = .thread
            feedCard.avatarKey = "avatar_1"
            feedCard.feedType = .inbox
            let vm = BaseFeedTableCellViewModel(feedCardPreview: feedCard, bizType: .inbox)
            section.items = [vm!]
            section.type = .none
            self.mainFeedsVM.feedsRelay.accept(section)
            self.mainFeedsVM.provider.updateItems([vm!])

            self.mainFeedsVM.handleThreadAvatarChangePush(by: [:])
        }

        mainWait(3)

        let section = self.mainFeedsVM.feedsRelay.value
        // 不触发reload
        XCTAssert(section.type == .none)
        // 数据源无更新
        XCTAssert(section.items.count == 1)
        XCTAssert(section.items.first?.feedCardPreview.avatarKey == "avatar_1")
    }

    /// case 2: 传入匹配feedId与avatar，预期触发reload，触发数据源更新
    func test_handleThreadAvatarChangePush_2() {
        // 2s后执行，去除relay初始值影响
        asyncAfter(.now() + 2) {
            // 初始值
            var section = SectionHolder()
            var feedCard = buildFeedPreview()
            feedCard.id = "1"
            feedCard.type = .thread
            feedCard.avatarKey = "avatar_1"
            feedCard.feedType = .inbox
            let vm = BaseFeedTableCellViewModel(feedCardPreview: feedCard, bizType: .inbox)
            section.items = [vm!]
            section.type = .none
            self.mainFeedsVM.feedsRelay.accept(section)
            self.mainFeedsVM.provider.updateItems([vm!])

            // 更新
            var avatar = Feed_V1_PushThreadFeedAvatarChanges.Avatar()
            avatar.avatarKey = "new_avatar_1"
            self.mainFeedsVM.handleThreadAvatarChangePush(by: ["1": avatar])
        }

        mainWait(3)

        let section = self.mainFeedsVM.feedsRelay.value
        // 触发reload
        XCTAssert(section.type == .reload)
        // 数据源更新
        XCTAssert(section.items.count == 1)
        XCTAssert(section.items.first?.feedCardPreview.avatarKey == "new_avatar_1")
    }

    /// case 3: feedId匹配但是非thread类型，触发reload，不更新数据源
    func test_handleThreadAvatarChangePush_3() {
        // 2s后执行，去除relay初始值影响
        asyncAfter(.now() + 2) {
            // 初始值
            var section = SectionHolder()
            var feedCard1 = buildFeedPreview()
            feedCard1.id = "1"
            feedCard1.rankTime = 100
            feedCard1.type = .thread
            feedCard1.avatarKey = "avatar_1"
            feedCard1.feedType = .inbox
            let vm1 = BaseFeedTableCellViewModel(feedCardPreview: feedCard1, bizType: .inbox)
            var feedCard2 = buildFeedPreview()
            feedCard2.id = "2"
            feedCard2.rankTime = 10
            feedCard2.type = .chat // 非thread类型
            feedCard2.avatarKey = "avatar_2"
            feedCard2.feedType = .inbox
            let vm2 = BaseFeedTableCellViewModel(feedCardPreview: feedCard2, bizType: .inbox)
            section.items = [vm1!, vm2!]
            section.type = .none
            self.mainFeedsVM.feedsRelay.accept(section)
            self.mainFeedsVM.provider.updateItems([vm1!, vm2!])

            // 更新
            var avatar1 = Feed_V1_PushThreadFeedAvatarChanges.Avatar()
            avatar1.avatarKey = "new_avatar_1"
            var avatar2 = Feed_V1_PushThreadFeedAvatarChanges.Avatar()
            avatar2.avatarKey = "new_avatar_2"
            self.mainFeedsVM.handleThreadAvatarChangePush(by: ["1": avatar1,
                                                               "2": avatar2])
        }

        mainWait(3)

        let section = self.mainFeedsVM.feedsRelay.value
        // 触发reload
        XCTAssert(section.type == .reload)
        // 数据源更新
        XCTAssert(section.items.count == 2)
        XCTAssert(section.items[0].feedCardPreview.avatarKey == "new_avatar_1")
        XCTAssert(section.items[1].feedCardPreview.avatarKey == "avatar_2")
    }

    // MARK: - loadMissing

    /// case 1: loadMissingByCursorEnabled = true, 数据成功返回，预期：
    ///  - 触发reload，更新Feed数据
    ///  - 更新cursors，nextCursor
    func test_loadMissing_1() {
        // 开启FG
        mockDependency.loadMissingByCursorEnabledBuilder = { true }

        // 避免relay初始值影响
        mainWait()

        // 初始数据
        var section = SectionHolder()
        var feedCard = buildFeedPreview()
        feedCard.id = "1"
        feedCard.rankTime = 100
        feedCard.type = .chat
        feedCard.feedType = .inbox
        let vm = BaseFeedTableCellViewModel(feedCardPreview: feedCard, bizType: .inbox)
        section.items = [vm!]
        section.type = .none
        self.mainFeedsVM.feedsRelay.accept(section)
        self.mainFeedsVM.provider.updateItems([vm!])

        let expect = expectation(description: "loadMissing")
        mainFeedsVM.loadMissing(maxCursor: 1000, minCursor: 10, count: 10)
            .subscribe(onNext: { (hasMore) in
                XCTAssert(hasMore == true)
                expect.fulfill()
            }).disposed(by: disposeBag)
        // 等待数据处理与返回
        wait(for: [expect], timeout: 1)

        // 等待数据处理与返回
        mainWait()

        // 验证
        let newSection = mainFeedsVM.feedsRelay.value
        XCTAssert(newSection.type == .reload)
        XCTAssert(newSection.items.count == 2)
        XCTAssert(newSection.items[0].feedCardPreview.id == "2")
        XCTAssert(newSection.items[1].feedCardPreview.id == "1")

        XCTAssert(mainFeedsVM.nextCursor == 10)
        XCTAssert(mainFeedsVM.cursors.count == 1)
        XCTAssert(mainFeedsVM.cursors[0].maxCursor == 1000)
        XCTAssert(mainFeedsVM.cursors[0].minCursor == 10)
    }

    /// case 2: loadMissingByCursorEnabled = false，数据成功返回，预期：
    ///  - 触发reload，更新Feed数据
    ///  - 更新cursors，nextCursor
    func test_loadMissing_2() {
        // 关闭FG
        mockDependency.loadMissingByCursorEnabledBuilder = { false }
        // 准备返回值
        mockDependency.getFeedCardsBuilder = { feedType, pullType, feedCardID, cursor, count -> Observable<GetFeedCardsResult> in
            var feedCard = buildFeedPreview()
            feedCard.id = "2"
            feedCard.rankTime = 200
            feedCard.type = .chat
            feedCard.feedType = .inbox
            var cursor = Feed_V1_Cursor()
            cursor.maxCursor = 1000
            cursor.minCursor = 10
            let res = GetFeedCardsResult(feeds: [feedCard], nextCursor: 10, cursors: [cursor])
            return .just(res)
        }

        // 避免relay初始值影响
        mainWait()

        // 初始数据
        var section = SectionHolder()
        var feedCard = buildFeedPreview()
        feedCard.id = "1"
        feedCard.rankTime = 100
        feedCard.type = .chat
        feedCard.feedType = .inbox
        let vm = BaseFeedTableCellViewModel(feedCardPreview: feedCard, bizType: .inbox)
        section.items = [vm!]
        section.type = .none
        self.mainFeedsVM.feedsRelay.accept(section)
        self.mainFeedsVM.provider.updateItems([vm!])

        let expect = expectation(description: "loadMissing")
        mainFeedsVM.loadMissing(maxCursor: 1000, minCursor: 10, count: 10)
            .subscribe(onNext: { (hasMore) in
                XCTAssert(hasMore == true)
                expect.fulfill()
            }).disposed(by: disposeBag)
        // 等待数据处理与返回
        wait(for: [expect], timeout: 1)

        // 验证
        let newSection = mainFeedsVM.feedsRelay.value
        XCTAssert(newSection.type == .reload)
        XCTAssert(newSection.items.count == 2)
        XCTAssert(newSection.items[0].feedCardPreview.id == "2")
        XCTAssert(newSection.items[1].feedCardPreview.id == "1")

        XCTAssert(mainFeedsVM.nextCursor == 10)
        XCTAssert(mainFeedsVM.cursors.count == 1)
        XCTAssert(mainFeedsVM.cursors[0].maxCursor == 1000)
        XCTAssert(mainFeedsVM.cursors[0].minCursor == 10)
    }

    // MARK: - handlePushCursor

    /// case 1: feedType不匹配 -> 直接return(通过nextCursor是否更新和接口是否调用来判断)
    func test_handlePushCursor_1() {
        // 初始条件
        mockDependency.loadMissingByCursorEnabledBuilder = { false }
        mockDependency.getFeedCardsBuilder = { feedType, pullType, feedCardID, cursor, count -> Observable<GetFeedCardsResult> in
            // 不触发接口调用
            XCTAssert(false)
            return .empty()
        }
        mainFeedsVM.nextCursor = 0
        var cursor = Feed_V1_Cursor()
        cursor.maxCursor = 1000
        cursor.minCursor = 10
        mainFeedsVM.cursors = [cursor]

        // 输入
        var push = Feed_V1_PushFeedCursor()
        push.feedType = .done // feedType不匹配
        mainFeedsVM.handlePushCursor(pushCursor: push)

        mainWait()

        // 校验
        XCTAssert(mainFeedsVM.nextCursor == 0)
    }

    /// case 2: 已在原cursor范围中 -> 不更新，直接返回
    func test_handlePushCursor_2() {
        // 初始条件
        mockDependency.loadMissingByCursorEnabledBuilder = { false }
        mockDependency.getFeedCardsBuilder = { feedType, pullType, feedCardID, cursor, count -> Observable<GetFeedCardsResult> in
            // 不触发接口调用
            XCTAssert(false)
            return .empty()
        }
        mainFeedsVM.nextCursor = 0
        var cursor = Feed_V1_Cursor()
        cursor.maxCursor = 1000
        cursor.minCursor = 10
        mainFeedsVM.cursors = [cursor]

        // 输入
        var push = Feed_V1_PushFeedCursor()
        push.feedType = .inbox
        push.cursor.maxCursor = 100 // 在cursor范围中
        push.cursor.minCursor = 50
        mainFeedsVM.handlePushCursor(pushCursor: push)

        mainWait()

        // 校验
        XCTAssert(mainFeedsVM.nextCursor == 0)
    }

    /// case 3: nextCursor = 0，不在原cursor范围中且比原cursor范围老 -> 更新nextCursor，但是不触发接口调用
    func test_handlePushCursor_3() {
        // 初始条件
        mockDependency.loadMissingByCursorEnabledBuilder = { false }
        mockDependency.getFeedCardsBuilder = { feedType, pullType, feedCardID, cursor, count -> Observable<GetFeedCardsResult> in
            // 不触发接口调用
            XCTAssert(false)
            return .empty()
        }
        mainFeedsVM.nextCursor = 0
        var cursor = Feed_V1_Cursor()
        cursor.maxCursor = 1000
        cursor.minCursor = 10
        mainFeedsVM.cursors = [cursor]

        // 输入
        var push = Feed_V1_PushFeedCursor()
        push.feedType = .inbox
        push.cursor.maxCursor = 100
        push.cursor.minCursor = 5 // 比原cursor范围老
        mainFeedsVM.handlePushCursor(pushCursor: push)

        mainWait()

        // 校验
        XCTAssert(mainFeedsVM.nextCursor == 10) // 更新nextCursor
    }

    /// case 4: nextCursor = 0，不在原cursor范围中且比原cursor范围新 -> 更新nextCursor，触发接口调用
    func test_handlePushCursor_4() {
        // 初始条件
        mockDependency.loadMissingByCursorEnabledBuilder = { false }
        mockDependency.getFeedCardsBuilder = { feedType, pullType, feedCardID, cursor, count -> Observable<GetFeedCardsResult> in
            XCTAssert(cursor == 2000)
            XCTAssert(count == 10)
            return .empty()
        }
        mainFeedsVM.nextCursor = 0
        var cursor = Feed_V1_Cursor()
        cursor.maxCursor = 1000
        cursor.minCursor = 10
        mainFeedsVM.cursors = [cursor]

        // 输入
        var push = Feed_V1_PushFeedCursor()
        push.feedType = .inbox
        push.cursor.maxCursor = 2000
        push.cursor.minCursor = 100 // 比原cursor范围老
        push.count = 10
        mainFeedsVM.handlePushCursor(pushCursor: push)

        mainWait()

        // 校验
        XCTAssert(mainFeedsVM.nextCursor == 10) // 更新nextCursor
    }

    // MARK: - pullConfig

    /// case 1: 拉取+保存成功
    func test_pullConfig() {
        // 拉取 && 保存
        mainFeedsVM.pullConfig()

        mainWait(3)

        // 读取保存的数据，进行校验
        let storage = UserDefaults.standard.string(forKey: "Feed.Loadmessenger_feed_load_count")
        let data = storage!.data(using: .utf8)
        let setting = try! JSONDecoder().decode(LoadSetting.self, from: data!)
        XCTAssert(setting.buffer == 60)
        XCTAssert(setting.cache_total == 110)
        XCTAssert(setting.loadmore == 60)
        XCTAssert(setting.refresh == 30)
    }

    // MARK: - handleFeedPreviewByPreloadPull

    /// case 1: 正常清除缓存
    func test_handleFeedPreviewByPreloadPull_1() {
        // 避免relay影响
        mainWait()

        // 手动触发一下start，否则会命中assert
        FeedPerfTrack.trackLoadFirstPageFeeds(biz: .inbox, status: .start)
        // 初始值
        var feed1 = buildFeedPreview()
        feed1.id = "1"
        feed1.updateTime = -1
        feed1.feedType = .inbox
        feed1.type = .chat
        let vm1 = BaseFeedTableCellViewModel(feedCardPreview: feed1, bizType: .inbox)
        var feed2 = buildFeedPreview()
        feed2.id = "2"
        feed2.updateTime = 0
        feed2.feedType = .inbox
        feed2.type = .chat
        let vm2 = BaseFeedTableCellViewModel(feedCardPreview: feed2, bizType: .inbox)
        mainFeedsVM.provider.updateItems([vm1!, vm2!])

        let res = GetFeedCardsResult(feeds: [], nextCursor: 0, cursors: [])
        mainFeedsVM.handleFeedPreviewByPreloadPull(res)

        mainWait()

        let items = mainFeedsVM.provider.getItemsArray()
        XCTAssert(items.count == 1)
        XCTAssert(items[0].feedCardPreview.id == "2")
    }

    // MARK: - preload

    /// case 1: preload成功 -> 触发reload，cursor合并
    func test_preload_1() {
        // 排除relay初始值影响
        mainWait()

        mockDependency.getFeedCardsBuilder = { feedType, pullType, feedCardID, cursor, count -> Observable<GetFeedCardsResult> in
            // 参数校验
            XCTAssert(pullType == .refresh)
            XCTAssert(feedType == .inbox)
            XCTAssert(cursor == 0)
            XCTAssert(count == 20)

            var feedCard = buildFeedPreview()
            feedCard.id = "1"
            feedCard.rankTime = 100
            feedCard.type = .chat
            feedCard.feedType = .inbox
            var cursor = Feed_V1_Cursor()
            cursor.maxCursor = 1000
            cursor.minCursor = 10
            let res = GetFeedCardsResult(feeds: [feedCard], nextCursor: 10, cursors: [cursor])
            return .just(res)
        }
        // 初始值
        var section = SectionHolder()
        section.type = .ignore
        mainFeedsVM.feedsRelay.accept(section)

        // 触发preload
        mainFeedsVM.preload()
        mainWait()

        // 结果校验
        let uiSection = mainFeedsVM.feedsRelay.value
        XCTAssert(uiSection.type == .reload)
        XCTAssert(uiSection.items.count == 1)
        XCTAssert(uiSection.items[0].feedCardPreview.id == "1")
        XCTAssert(mainFeedsVM.nextCursor == 10)
        XCTAssert(mainFeedsVM.cursors.count == 1)
        XCTAssert(mainFeedsVM.cursors[0].maxCursor == 1000)
        XCTAssert(mainFeedsVM.cursors[0].minCursor == 10)
        XCTAssert(mainFeedsVM.firstLoadFeed == false)
    }

    /// case 2: preload失败 -> 不触发数据更新
    func test_preload_2() {
        // 排除relay初始值影响
        mainWait()

        mockDependency.getFeedCardsBuilder = { feedType, pullType, feedCardID, cursor, count -> Observable<GetFeedCardsResult> in
            // 参数校验
            XCTAssert(pullType == .refresh)
            XCTAssert(feedType == .inbox)
            XCTAssert(cursor == 0)
            XCTAssert(count == 20)

            return .error(NSError())
        }
        // 初始值
        var section = SectionHolder()
        section.type = .ignore
        mainFeedsVM.feedsRelay.accept(section)

        // 触发preload
        mainFeedsVM.preload()
        mainWait()

        // 结果校验
        XCTAssert(mainFeedsVM.feedsRelay.value.type == .ignore)
        XCTAssert(mainFeedsVM.firstLoadFeed == false)
    }

    // MARK: - loadMore

    /// case 1: nextCursor = 0 -> 不触发接口请求
    func test_loadMore_1() {
        // 避免relay初始值影响
        mainWait()

        // 初始条件
        mainFeedsVM.nextCursor = 0

        mockDependency.getFeedCardsBuilder = { feedType, pullType, feedCardID, cursor, count -> Observable<GetFeedCardsResult> in
            // 不触发接口调用
            XCTAssert(false)
            return .error(NSError())
        }

        mainFeedsVM.loadMore().subscribe(onNext: { hasMore in
            XCTAssert(false)
        }, onError: { error in
            // 应该返回onError
            XCTAssert(true)
        }).disposed(by: disposeBag)

        // 等待异步触发
        mainWait()
    }

    /// case 2: nextCursor != 0 -> 拉取数据触发刷新
    func test_loadMore_2() {
        // 避免relay初始值影响
        mainWait()

        // 初始条件
        mainFeedsVM.nextCursor = 100
        var section = SectionHolder()
        section.type = .ignore
        mainFeedsVM.feedsRelay.accept(section)

        mockDependency.getFeedCardsBuilder = { feedType, pullType, feedCardID, cursor, count -> Observable<GetFeedCardsResult> in
            // 参数校验
            XCTAssert(feedType == .inbox)
            XCTAssert(pullType == .loadMore)
            XCTAssert(cursor == 100)
            XCTAssert(count == 50)

            var feedCard = buildFeedPreview()
            feedCard.id = "1"
            feedCard.rankTime = 100
            feedCard.type = .chat
            feedCard.feedType = .inbox
            var cursor = Feed_V1_Cursor()
            cursor.maxCursor = 1000
            cursor.minCursor = 100
            let res = GetFeedCardsResult(feeds: [feedCard], nextCursor: 0, cursors: [cursor])
            return .just(res)
        }

        mainFeedsVM.loadMore().subscribe(onNext: { hasMore in
            XCTAssert(hasMore == false)
        }).disposed(by: disposeBag)

        // 等待异步触发
        mainWait()

        let uiSection = mainFeedsVM.feedsRelay.value
        XCTAssert(uiSection.type == .reload)
        XCTAssert(uiSection.items.count == 1)
        XCTAssert(uiSection.items[0].feedCardPreview.id == "1")
        XCTAssert(mainFeedsVM.nextCursor == 0)
        XCTAssert(mainFeedsVM.cursors.count == 1)
        XCTAssert(mainFeedsVM.cursors[0].maxCursor == 1000)
        XCTAssert(mainFeedsVM.cursors[0].minCursor == 100)
        XCTAssert(mainFeedsVM.provider.getItemsArray().count == 1)
    }

    // MARK: - hasMoreFeeds

    /// case 1: nextCursor = nil -> hasMoreFeeds = false
    func test_hasMoreFeeds_1() {
        // 初始值
        mainFeedsVM.nextCursor = nil

        // 校验
        XCTAssert(mainFeedsVM.hasMoreFeeds() == false)
    }

    /// case 2: nextCursor != nil -> hasMoreFeeds = (nextCursor != 0)
    func test_hasMoreFeeds_2() {
        // nextCursor = 0
        mainFeedsVM.nextCursor = 0
        XCTAssert(mainFeedsVM.hasMoreFeeds() == false)

        // nextCursor > 0
        mainFeedsVM.nextCursor = 10
        XCTAssert(mainFeedsVM.hasMoreFeeds() == true)
    }

    // MARK: - mergeNextUnreadFeedsResult

    /// case 1: NextUnreadFeedCardsResult.nextCursor = 0 -> 更新UI数据并触发reload，不更新cursor
    func test_mergeNextUnreadFeedsResult_1() {
        // 避免relay初始值影响
        mainWait()

        // 初始条件
        mainFeedsVM.nextCursor = 10
        var section = SectionHolder()
        section.type = .ignore
        mainFeedsVM.feedsRelay.accept(section)

        let res = NextUnreadFeedCardsResult(previews: [],
                                            nextCursor: 0,
                                            continuousCursors: [])
        mainFeedsVM.mergeNextUnreadFeedsResult(res)

        mainWait()

        // 校验
        XCTAssert(mainFeedsVM.feedsRelay.value.type == .reload)
        XCTAssert(mainFeedsVM.nextCursor == 10)
    }

    /// case 2: NextUnreadFeedCardsResult.nextCursor = 0 -> 更新UI数据和cursor并触发reload
    func test_mergeNextUnreadFeedsResult_2() {
        // 避免relay初始值影响
        mainWait()

        // 初始条件
        mainFeedsVM.nextCursor = 100
        var section = SectionHolder()
        section.type = .ignore
        mainFeedsVM.feedsRelay.accept(section)

        var feed = buildFeedPreview()
        feed.id = "1"
        var cursor = Feed_V1_Cursor()
        cursor.maxCursor = 1000
        cursor.minCursor = 500
        let res = NextUnreadFeedCardsResult(previews: [feed],
                                            nextCursor: 10,
                                            continuousCursors: [cursor])
        mainFeedsVM.mergeNextUnreadFeedsResult(res)

        mainWait()

        // 校验
        let uiSection = mainFeedsVM.feedsRelay.value
        XCTAssert(uiSection.type == .reload)
        XCTAssert(uiSection.items[0].feedCardPreview.id == "1")
        XCTAssert(mainFeedsVM.nextCursor == 10)
        XCTAssert(mainFeedsVM.cursors.count == 1)
        XCTAssert(mainFeedsVM.cursors[0].maxCursor == 1000)
        XCTAssert(mainFeedsVM.cursors[0].minCursor == 500)
    }

    // MARK: - updateSubFilter

    /// case 1: 当前subFilter与传入subFilter相等 -> 不触发接口调用，不清除数据，不重新拉数据
    func test_updateSubFilter_1() {
        // 初始值
        mainFeedsVM.currentSubFilterType = .chat
        mainFeedsVM.nextCursor = 10

        mockDependency.setFeedCardFilterBuilder = { filter -> Observable<Void> in
            // 不应触发接口调用
            XCTAssert(false)
            return .just(())
        }
        mockDependency.getFeedCardsBuilder = { feedType, pullType, feedCardID, cursor, count -> Observable<GetFeedCardsResult> in
            // 不应触发接口调用
            XCTAssert(false)
            return .error(NSError())
        }

        mainFeedsVM.updateSubFilter(.chat)

        mainWait()

        XCTAssert(mainFeedsVM.nextCursor == 10)
    }

    /// case 2: 当前subFilter与传入subFilter不等 -> 触发接口调用，清除老数据并重新拉取数据
    func test_updateSubFilter_2() {
        // 初始值
        mainFeedsVM.currentSubFilterType = .all
        mainFeedsVM.nextCursor = 1

        mockDependency.setFeedCardFilterBuilder = { filter -> Observable<Void> in
            return .just(())
        }

        mockDependency.getFeedCardsBuilder = { feedType, pullType, feedCardID, cursor, count -> Observable<GetFeedCardsResult> in
            // 参数校验
            XCTAssert(pullType == .refresh)
            XCTAssert(feedType == .inbox)
            XCTAssert(cursor == 0)
            XCTAssert(count == 20)

            var feedCard = buildFeedPreview()
            feedCard.id = "1"
            feedCard.rankTime = 100
            feedCard.type = .chat
            feedCard.feedType = .inbox
            var cursor = Feed_V1_Cursor()
            cursor.maxCursor = 1000
            cursor.minCursor = 10
            let res = GetFeedCardsResult(feeds: [feedCard], nextCursor: 10, cursors: [cursor])
            return .just(res)
        }

        mainFeedsVM.updateSubFilter(.chat)

        mainWait()

        // 重新拉取数据之后结果校验
        XCTAssert(mainFeedsVM.currentSubFilterType == .chat)
        XCTAssert(mainFeedsVM.nextCursor == 10)
        XCTAssert(mainFeedsVM.feedsRelay.value.items[0].feedCardPreview.id == "1")
        XCTAssert(mainFeedsVM.cursors[0].maxCursor == 1000)
        XCTAssert(mainFeedsVM.cursors[0].minCursor == 10)
    }
}

// MARK: - MainFeedsViewModel+Storage
extension MainFeedsViewModelTest {
    // MARK: - loadFeedsCache

    /// case 1: 有缓存时，读取缓存，触发reload
    func test_loadFeedsCache() {
        // 去除relay影响
        mainWait()

        // 初始缓存数据
        var feed = Feed_V1_FeedCardPreview()
        feed.pair.id = "1"
        feed.pair.type = .chat
        feed.feedType = .inbox
        feed.avatarKey = ""
        feed.name = ""
        feed.unreadCount = 1
        feed.isRemind = true
        feed.updateTime = Int64(CACurrentMediaTime())
        feed.isShortcut = true
        feed.localizedDigestMessage = ""
        feed.entityStatus = .normal
        feed.displayTime = Int64(CACurrentMediaTime())
        feed.rankTime = Int64(CACurrentMediaTime())
        feed.parentCardID = ""
        feed.crossTenant = false
        var list = [[String: Data]]()
        list.append(["type": "card".data(using: .utf8)!,
                     "data": try! feed.serializedData(partial: true)])
        UserDefaults.standard.set(list, forKey: "\(AccountServiceAdapter.shared.currentChatterId).larkFeed.feedKVStorage.v1.feed")
        var section = SectionHolder()
        section.type = .ignore
        mainFeedsVM.feedsRelay.accept(section)

        mainFeedsVM.loadFeedsCache()

        mainWait()

        // 校验
        let uiSection = mainFeedsVM.feedsRelay.value
        XCTAssert(uiSection.type == .reload)
        XCTAssert(uiSection.items.count == 1)
        XCTAssert(uiSection.items[0].feedCardPreview.id == "1")
        XCTAssert(uiSection.items[0].feedCardPreview.updateTime == -1)
        let items = mainFeedsVM.provider.getItemsArray()
        XCTAssert(items.count == 1)
        XCTAssert(items[0].feedCardPreview.id == "1")
        XCTAssert(items[0].feedCardPreview.updateTime == -1)
    }

    // MARK: - saveFeeds

    /// case 1: 缓存Feed正常
    func test_saveFeeds() {
        // 去除relay影响
        mainWait()

        // 初始缓存数据
        var feed = Feed_V1_FeedCardPreview()
        feed.pair.id = "1"
        feed.pair.type = .chat
        feed.feedType = .inbox
        feed.avatarKey = ""
        feed.name = ""
        feed.unreadCount = 1
        feed.isRemind = true
        feed.updateTime = Int64(CACurrentMediaTime())
        feed.isShortcut = true
        feed.localizedDigestMessage = ""
        feed.entityStatus = .normal
        feed.displayTime = Int64(CACurrentMediaTime())
        feed.rankTime = Int64(CACurrentMediaTime())
        feed.parentCardID = ""
        feed.crossTenant = false
        let preview = FeedPreview.transformByCardPreview(feed)
        let vm = BaseFeedTableCellViewModel(feedCardPreview: preview, bizType: .inbox)
        var section = SectionHolder()
        section.type = .reload
        section.items = [vm!]
        mainFeedsVM.setItems([section])

        mainFeedsVM.saveFeeds()

        // 校验
        let data = UserDefaults.standard.array(forKey: "\(AccountServiceAdapter.shared.currentChatterId).larkFeed.feedKVStorage.v1.feed") as! [[String: Data]]
        XCTAssert(data.count == 1)
        let feedRaw = data[0]["data"]
        let previews = try! Feed_V1_FeedCardPreview(serializedData: feedRaw!)
        XCTAssert(previews.pair.id == "1")
    }

    // MARK: - getJunkCache

    /// case 1: 正常获取脏数据
    func test_getJunkCache() {
        // 初始缓存数据
        var feed1 = buildFeedPreview()
        feed1.id = "1"
        feed1.updateTime = -1
        feed1.type = .chat
        feed1.feedType = .inbox
        let vm1 = BaseFeedTableCellViewModel(feedCardPreview: feed1, bizType: .inbox)
        var feed2 = buildFeedPreview()
        feed2.id = "2"
        feed2.type = .chat
        feed2.feedType = .inbox
        let vm2 = BaseFeedTableCellViewModel(feedCardPreview: feed2, bizType: .inbox)
        var section = SectionHolder()
        section.type = .reload
        section.items = [vm1!, vm2!]
        mainFeedsVM.feedsRelay.accept(section)
        mainFeedsVM.provider.updateItems([vm1!, vm2!])

        let id = mainFeedsVM.getJunkCache()

        // 校验
        XCTAssert(id?.count == 1)
        XCTAssert(id?[0] == "1")
    }
}

// MARK: - TabFeedsViewModel+TabbarDoubleTap
extension MainFeedsViewModelTest {
    // MARK: - findNextUnreadFeed

    /// case 1: 传入Id不在数据源中 -> return nil
    func test_findNextUnreadFeed_1() {
        // 初始数据
        var feed1 = buildFeedPreview()
        feed1.id = "1"
        feed1.unreadCount = 1
        let cellVM1 = BaseFeedTableCellViewModel(feedCardPreview: feed1, bizType: .inbox)
        var feed2 = buildFeedPreview()
        feed2.id = "2"
        feed2.unreadCount = 2
        let cellVM2 = BaseFeedTableCellViewModel(feedCardPreview: feed2, bizType: .inbox)
        var feed3 = buildFeedPreview()
        feed3.id = "3"
        feed3.unreadCount = 3
        let cellVM3 = BaseFeedTableCellViewModel(feedCardPreview: feed3, bizType: .inbox)
        var feed4 = buildFeedPreview()
        feed4.id = "4"
        feed4.unreadCount = 4
        let cellVM4 = BaseFeedTableCellViewModel(feedCardPreview: feed4, bizType: .inbox)
        var feed5 = buildFeedPreview()
        feed5.id = "5"
        feed5.unreadCount = 5
        let cellVM5 = BaseFeedTableCellViewModel(feedCardPreview: feed5, bizType: .inbox)
        var section = SectionHolder()
        section.items = [cellVM1!, cellVM2!, cellVM3!, cellVM4!, cellVM5!]
        mainFeedsVM.setItems([section])

        let index = mainFeedsVM.findNextUnreadFeed(after: "6")

        // 校验
        XCTAssert(index == nil)
    }

    /// case 2: 传入Id在数据源中且后面有未读 -> 返回后面第一条index
    func test_findNextUnreadFeed_2() {
        // 初始数据
        var feed1 = buildFeedPreview()
        feed1.id = "1"
        feed1.unreadCount = 1
        let cellVM1 = BaseFeedTableCellViewModel(feedCardPreview: feed1, bizType: .inbox)
        var feed2 = buildFeedPreview()
        feed2.id = "2"
        feed2.unreadCount = 2
        let cellVM2 = BaseFeedTableCellViewModel(feedCardPreview: feed2, bizType: .inbox)
        var feed3 = buildFeedPreview()
        feed3.id = "3"
        feed3.unreadCount = 3
        let cellVM3 = BaseFeedTableCellViewModel(feedCardPreview: feed3, bizType: .inbox)
        var feed4 = buildFeedPreview()
        feed4.id = "4"
        feed4.unreadCount = 4
        let cellVM4 = BaseFeedTableCellViewModel(feedCardPreview: feed4, bizType: .inbox)
        var feed5 = buildFeedPreview()
        feed5.id = "5"
        feed5.unreadCount = 5
        let cellVM5 = BaseFeedTableCellViewModel(feedCardPreview: feed5, bizType: .inbox)
        var section = SectionHolder()
        section.items = [cellVM1!, cellVM2!, cellVM3!, cellVM4!, cellVM5!]
        mainFeedsVM.setItems([section])

        let index = mainFeedsVM.findNextUnreadFeed(after: "3")

        XCTAssert(index == 3)
    }

    /// case 3: 传入Id在数据源中且后面无未读，前面有未读 -> 返回第一条index
    func test_findNextUnreadFeed_3() {
        // 初始数据
        var feed1 = buildFeedPreview()
        feed1.id = "1"
        feed1.unreadCount = 1
        let cellVM1 = BaseFeedTableCellViewModel(feedCardPreview: feed1, bizType: .inbox)
        var feed2 = buildFeedPreview()
        feed2.id = "2"
        feed2.unreadCount = 2
        let cellVM2 = BaseFeedTableCellViewModel(feedCardPreview: feed2, bizType: .inbox)
        var feed3 = buildFeedPreview()
        feed3.id = "3"
        feed3.unreadCount = 3
        let cellVM3 = BaseFeedTableCellViewModel(feedCardPreview: feed3, bizType: .inbox)
        var feed4 = buildFeedPreview()
        feed4.id = "4"
        feed4.unreadCount = 0
        let cellVM4 = BaseFeedTableCellViewModel(feedCardPreview: feed4, bizType: .inbox)
        var feed5 = buildFeedPreview()
        feed5.id = "5"
        feed5.unreadCount = 0
        let cellVM5 = BaseFeedTableCellViewModel(feedCardPreview: feed5, bizType: .inbox)
        var section = SectionHolder()
        section.items = [cellVM1!, cellVM2!, cellVM3!, cellVM4!, cellVM5!]
        mainFeedsVM.setItems([section])

        let index = mainFeedsVM.findNextUnreadFeed(after: "3")

        XCTAssert(index == 0)
    }

    /// case 4: 传入Id在数据源中且前后均无未读 -> return nil
    func test_findNextUnreadFeed_4() {
        // 初始数据
        var feed1 = buildFeedPreview()
        feed1.id = "1"
        feed1.unreadCount = 0
        let cellVM1 = BaseFeedTableCellViewModel(feedCardPreview: feed1, bizType: .inbox)
        var feed2 = buildFeedPreview()
        feed2.id = "2"
        feed2.unreadCount = 0
        let cellVM2 = BaseFeedTableCellViewModel(feedCardPreview: feed2, bizType: .inbox)
        var feed3 = buildFeedPreview()
        feed3.id = "3"
        feed3.unreadCount = 0
        let cellVM3 = BaseFeedTableCellViewModel(feedCardPreview: feed3, bizType: .inbox)
        var feed4 = buildFeedPreview()
        feed4.id = "4"
        feed4.unreadCount = 0
        let cellVM4 = BaseFeedTableCellViewModel(feedCardPreview: feed4, bizType: .inbox)
        var feed5 = buildFeedPreview()
        feed5.id = "5"
        feed5.unreadCount = 0
        let cellVM5 = BaseFeedTableCellViewModel(feedCardPreview: feed5, bizType: .inbox)
        var section = SectionHolder()
        section.items = [cellVM1!, cellVM2!, cellVM3!, cellVM4!, cellVM5!]
        mainFeedsVM.setItems([section])

        let index = mainFeedsVM.findNextUnreadFeed(after: "3")

        XCTAssert(index == nil)
    }
}

// MARK: - MainFeedsViewModel+FeedSyncDispatchService
extension MainFeedsViewModelTest {
    // MARK: - currentFeedsCellVM

    /// case 1: 多线程访问安全
    func test_currentFeedsCellVM() {
        // 初始数据
        var feed1 = buildFeedPreview()
        feed1.id = "1"
        let vm1 = BaseFeedTableCellViewModel(feedCardPreview: feed1, bizType: .inbox)
        var feed2 = buildFeedPreview()
        feed2.id = "2"
        let vm2 = BaseFeedTableCellViewModel(feedCardPreview: feed2, bizType: .inbox)
        mainFeedsVM.provider.updateItems([vm1!, vm2!])

        async {
            XCTAssert(self.mainFeedsVM.currentFeedsCellVM().count == 2)
        }
        async {
            XCTAssert(self.mainFeedsVM.currentFeedsCellVM().count == 2)
        }
        async {
            XCTAssert(self.mainFeedsVM.currentFeedsCellVM().count == 2)
        }
        async {
            XCTAssert(self.mainFeedsVM.currentFeedsCellVM().count == 2)
        }
        mainWait()
    }
}

// MARK: - MainFeedsViewModel+FeedSyncDispatchServiceForDoc
extension MainFeedsViewModelTest {
    // MARK: - getCellViewModel

    /// case 1: 多线程访问安全
    func test_getCellViewModel() {
        // 初始数据
        var feed1 = buildFeedPreview()
        feed1.id = "1"
        let vm1 = BaseFeedTableCellViewModel(feedCardPreview: feed1, bizType: .inbox)
        var feed2 = buildFeedPreview()
        feed2.id = "2"
        let vm2 = BaseFeedTableCellViewModel(feedCardPreview: feed2, bizType: .inbox)
        mainFeedsVM.provider.updateItems([vm1!, vm2!])

        async {
            XCTAssert(self.mainFeedsVM.getCellViewModel("1") != nil)
        }
        async {
            XCTAssert(self.mainFeedsVM.getCellViewModel("2") != nil)
        }
        async {
            XCTAssert(self.mainFeedsVM.getCellViewModel("3") == nil)
        }

        mainWait()
    }
}

// swiftlint:enable all
