//
//  BoxFeedsViewModelTest.swift
//  LarkMessengerUnitTest
//
//  Created by 袁平 on 2020/9/7.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import XCTest
import RxSwift
import RustPB
import SwiftProtobuf
import LarkSDKInterface
import LarkAccountInterface
@testable import LarkFeed

class BoxFeedsViewModelTest: XCTestCase {
    let parentId = "1234"
    var boxVM: BoxFeedsViewModel!
    var mockDependency: MockBoxFeedsDependency!
    var mockBaseDependency: MockBaseFeedsViewModelDependency!
    var disposeBag: DisposeBag!

    override class func setUp() {
        // Chat
        FeedSupplement.shared.registerTableViewCellAndViewModel(.chat, BaseFeedTableCell.self) { (feed, type) -> BaseFeedTableCellViewModel? in
            BaseFeedTableCellViewModel(feedCardPreview: feed, bizType: type)
        }
    }

    override func setUp() {
        // LoadConfig移除测试的初始值，避免相互影响
        UserDefaults.standard.removeObject(forKey: "Feed.Loadmessenger_feed_load_count")
        mockDependency = MockBoxFeedsDependency()
        mockBaseDependency = MockBaseFeedsViewModelDependency()
        let push = PushFeedPreview(updatePreviews: [],
                                   removePreviews: [],
                                   unreadCount: 0,
                                   filteredUnreadCount: 0,
                                   filteredMuteUnreadCount: 0,
                                   delayedChannelCount: 0)
        let threadAvatar = PushThreadFeedAvatarChanges(avatars: [:])
        boxVM = BoxFeedsViewModel(dependency: mockDependency,
                                  baseDependency: mockBaseDependency,
                                  badgeDriver: .just(.none),
                                  boxId: parentId,
                                  isAutoBoxFGEnable: true,
                                  pushSettings: .just(Settings_V1_PushUserSetting()),
                                  feedPreviewPush: .just(push),
                                  badgeStylePush: .just(.strongRemind),
                                  threadFeedAvatarChangesPush: .just(threadAvatar),
                                  is24HourTime: .init(value: true))
        disposeBag = DisposeBag()
        super.setUp()
    }

    override func tearDown() {
        mockDependency = nil
        mockBaseDependency = nil
        disposeBag = nil
        boxVM = nil
        super.tearDown()
    }

    // MARK: - bizType

    /// case 1: bizType = .box
    func test_bizType() {
        XCTAssert(boxVM.bizType == .box)
    }

    // MARK: - preload

    /// case 1: nextCursor = 0 -> 不触发preload
    func test_preload_1() {
        mockDependency.getFeedCardsBuilder = { feedType, pullType, feedCardID, cursor, count -> Observable<GetFeedCardsResult> in
            // 不应触发方法调用
            XCTAssert(false)
            return .error(NSError())
        }

        // 初始值
        boxVM.nextCursor = 0
        boxVM.preload()

        mainWait()
    }

    /// case 2: nextCursor != 0 -> 触发preload并触发数据更新与reload
    func test_preload_2() {
        // 避免Relay影响
        mainWait()

        mockDependency.getFeedCardsBuilder = { feedType, pullType, feedCardID, cursor, count -> Observable<GetFeedCardsResult> in
            // 参数校验
            XCTAssert(feedType == .inbox)
            XCTAssert(pullType == .refresh)
            XCTAssert(feedCardID == self.parentId)
            XCTAssert(cursor == Int.max)
            XCTAssert(count == 20)

            var feedCard = buildFeedPreview()
            feedCard.id = "1"
            feedCard.type = .chat
            feedCard.feedType = .inbox
            feedCard.parentCardID = self.parentId
            let res = GetFeedCardsResult(feeds: [feedCard], nextCursor: 10, cursors: [])
            return .just(res)
        }

        // 初始值
        var section = SectionHolder()
        section.type = .ignore
        boxVM.feedsRelay.accept(section)

        // nextCursor默认值Int.max
        boxVM.preload()

        mainWait()

        let uiSection = boxVM.feedsRelay.value
        XCTAssert(uiSection.type == .reload)
        XCTAssert(uiSection.items.count == 1)
        XCTAssert(uiSection.items[0].feedCardPreview.id == "1")
        XCTAssert(boxVM.nextCursor == 10)
    }

    // MARK: - loadMore

    /// case 1: nextCursor = 0 -> 不触发方法调用，返回false
    func test_loadMore_1() {
        mockDependency.getFeedCardsBuilder = { feedType, pullType, feedCardID, cursor, count -> Observable<GetFeedCardsResult> in
            // 不应触发方法调用
            XCTAssert(false)
            return .error(NSError())
        }

        // 初始值
        boxVM.nextCursor = 0
        boxVM.loadMore().subscribe(onNext: { hasMore in
            XCTAssert(hasMore == false)
        }).disposed(by: disposeBag)

        mainWait()
    }

    /// case 2: nextCursor != 0 => 触发接口调用并触发数据更新与reload
    func test_loadMore_2() {
        // 避免Relay影响
        mainWait()

        mockDependency.getFeedCardsBuilder = { feedType, pullType, feedCardID, cursor, count -> Observable<GetFeedCardsResult> in
            // 参数校验
            XCTAssert(feedType == .inbox)
            XCTAssert(pullType == .loadMore)
            XCTAssert(feedCardID == self.parentId)
            XCTAssert(cursor == Int.max)
            XCTAssert(count == 50)

            var feedCard = buildFeedPreview()
            feedCard.id = "1"
            feedCard.type = .chat
            feedCard.feedType = .inbox
            feedCard.parentCardID = self.parentId
            let res = GetFeedCardsResult(feeds: [feedCard], nextCursor: 10, cursors: [])
            return .just(res)
        }

        // 初始值
        var section = SectionHolder()
        section.type = .ignore
        boxVM.feedsRelay.accept(section)

        // nextCursor默认值Int.max
        boxVM.loadMore().subscribe(onNext: { hasMore in
            XCTAssert(hasMore == true)
        }).disposed(by: disposeBag)

        mainWait()

        let uiSection = boxVM.feedsRelay.value
        XCTAssert(uiSection.type == .reload)
        XCTAssert(uiSection.items.count == 1)
        XCTAssert(uiSection.items[0].feedCardPreview.id == "1")
        XCTAssert(boxVM.nextCursor == 10)
    }

    // MARK: - hasMoreFeeds

    /// case 1:
    /// nextCursor = 0 -> hasMoreFeeds() = false
    /// nextCursor != 0 -> hasMoreFeeds() = true
    func test_hasMoreFeeds_1() {
        boxVM.nextCursor = 0
        XCTAssert(boxVM.hasMoreFeeds() == false)

        boxVM.nextCursor = 10
        XCTAssert(boxVM.hasMoreFeeds() == true)
    }

    // MARK: - displayFilter

    /// case 1: isShow = true, parentId > 0 -> displayFilter = true
    func test_displayFilter_1() {
        var feed = buildFeedPreview()
        feed.parentCardID = "100"
        let cellVM = BaseFeedTableCellViewModel(feedCardPreview: feed, bizType: .box)

        XCTAssert(boxVM.displayFilter(cellVM!) == true)
    }

    /// case 2: parentId <= 0 -> displayFilter = false
    func test_displayFilter_2() {
        var feed = buildFeedPreview()
        feed.parentCardID = "0"
        let cellVM = BaseFeedTableCellViewModel(feedCardPreview: feed, bizType: .box)

        XCTAssert(boxVM.displayFilter(cellVM!) == false)
    }
}

// MARK: - AutoBox
extension BoxFeedsViewModelTest {
    // MARK: - loadNewBoxFeedCards
    /// case 1: 拉取数据
    func test_loadNewBoxFeedCards() {
        boxVM.loadNewBoxFeedCards()

        mainWait()

        let autoFeeds = boxVM.autoBoxRelay.value
        XCTAssert(autoFeeds.count == 3)
        XCTAssert(autoFeeds[0] == "1")
        XCTAssert(autoFeeds[1] == "2")
        XCTAssert(autoFeeds[2] == "3")
    }

    // MARK: - cleanNewBoxFeedCards
    /// case 1: 触发接口调用
    func test_cleanNewBoxFeedCards() {
        mockDependency.cleanNewBoxFeedCardsBuilder = { isNoticeHidden -> Observable<Void> in
            XCTAssert(isNoticeHidden == false)
            return .just(())
        }

        boxVM.cleanNewBoxFeedCards(isNoticeHidden: false)

        mainWait()
    }
}
