//
//  MarkLaterFeedsViewModelTest.swift
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

class MarkLaterFeedsViewModelTest: XCTestCase {
    var markLaterVM: MarkLaterFeedsViewModel!
    var mockDependency: MockMarkLaterViewModelDependency!
    var mockBaseDependency: MockBaseFeedsViewModelDependency!
    var disposeBag: DisposeBag!

    override class func setUp() {
        // Chat
        FeedSupplement.shared.registerTableViewCellAndViewModel(.chat, BaseFeedTableCell.self) { (feed, type) -> BaseFeedTableCellViewModel? in
            BaseFeedTableCellViewModel(feedCardPreview: feed, bizType: type)
        }
    }

    override func setUp() {
        mockDependency = MockMarkLaterViewModelDependency()
        mockBaseDependency = MockBaseFeedsViewModelDependency()
        let push = PushFeedPreview(updatePreviews: [],
                                   removePreviews: [],
                                   unreadCount: 0,
                                   filteredUnreadCount: 0,
                                   filteredMuteUnreadCount: 0,
                                   delayedChannelCount: 0)
        let threadAvatar = PushThreadFeedAvatarChanges(avatars: [:])
        markLaterVM = MarkLaterFeedsViewModel(dependency: mockDependency,
                                              baseDependency: mockBaseDependency,
                                              badgeDriver: .just(.none),
                                              is24HourTime: .init(value: true),
                                              feedPreviewPush: .just(push),
                                              badgeStylePush: .just(.strongRemind),
                                              threadFeedAvatarChangesPush: .just(threadAvatar))
        disposeBag = DisposeBag()
        super.setUp()
    }

    override func tearDown() {
        mockDependency = nil
        mockBaseDependency = nil
        markLaterVM = nil
        disposeBag = nil
        super.tearDown()
    }

    // MARK: - bizType

    /// case 1: bizType = .markLater
    func test_bizType() {
        XCTAssert(markLaterVM.bizType == .markLater)
    }

    // MARK: - hasDoneDelayedFeed

    /// case 1: 能正确获取和存储值
    func test_hasDoneDelayedFeed() {
        mockDependency.userSpace[UDKey.StandardModule.hasDoneDelayedFeed] = true
        XCTAssert(markLaterVM.hasDoneDelayedFeed == true)

        markLaterVM.hasDoneDelayedFeed = false
        XCTAssert(mockDependency.userSpace[UDKey.StandardModule.hasDoneDelayedFeed] == false)
    }

    // MARK: - displayFilter

    /// case 1: isShow = true, isDelayed = true, feedType = .inbox -> return true
    func test_displayFilter_1() {
        var feed = buildFeedPreview()
        feed.isDelayed = true
        feed.feedType = .inbox
        let cellVM = BaseFeedTableCellViewModel(feedCardPreview: feed, bizType: .inbox)

        XCTAssert(markLaterVM.displayFilter(cellVM!) == true)
    }

    /// case 2: isShow，isDelayed，feedType分开控制
    func test_displayFilter_2() {
        var feed = buildFeedPreview()
        feed.isDelayed = false
        feed.feedType = .inbox
        let cellVM = BaseFeedTableCellViewModel(feedCardPreview: feed, bizType: .inbox)!

        XCTAssert(markLaterVM.displayFilter(cellVM) == false)

        cellVM.feedCardPreview.isDelayed = true
        cellVM.feedCardPreview.feedType = .done
        XCTAssert(markLaterVM.displayFilter(cellVM) == false)
    }

    // MARK: - loadMore

    /// case 1: loadMore触发reload和数据更新
    func test_loadMore() {
        // 避免relay影响
        mainWait()

        // 自定义返回值
        mockDependency.getDelayedFeedCardsBuilder = {
            var feed1 = buildFeedPreview()
            feed1.id = "1"
            feed1.rankTime = 10
            feed1.type = .chat
            feed1.isDelayed = true
            feed1.feedType = .inbox
            var feed2 = buildFeedPreview()
            feed2.id = "2"
            feed2.feedType = .inbox
            feed2.type = .chat
            feed2.isDelayed = true
            feed2.rankTime = 20

            return .just([feed1, feed2])
        }

        // 初始值
        var section = SectionHolder()
        var feed = buildFeedPreview()
        feed.id = "1"
        feed.type = .chat
        feed.rankTime = 3
        feed.isDelayed = true
        let cellVM = BaseFeedTableCellViewModel(feedCardPreview: feed, bizType: .inbox)
        section.type = .ignore
        section.items = [cellVM!]
        markLaterVM.feedsRelay.accept(section)
        markLaterVM.provider.updateItems([cellVM!])

        markLaterVM.loadMore().subscribe(onNext: { hasMore in
            XCTAssert(hasMore == false)
        }).disposed(by: disposeBag)

        mainWait()

        // 校验
        let uiSection = markLaterVM.feedsRelay.value
        XCTAssert(uiSection.type == .reload)
        XCTAssert(uiSection.items.count == 2)
        XCTAssert(uiSection.items[0].feedCardPreview.id == "2")
        XCTAssert(uiSection.items[1].feedCardPreview.id == "1")
        XCTAssert(markLaterVM.provider.getItemsArray().count == 2)
    }

    // MARK: - setFeedPushSubscription

    /// case 1: MarkLaterViewController的调用方式固定为 (false, .delay)
    func test_setFeedPushSubscription() {
        mockDependency.setFeedPushSubscriptionBuilder = { on, scene -> Void in
            XCTAssert(on == false)
            XCTAssert(scene == .delay)
        }

        markLaterVM.setFeedPushSubscription()

        mainWait()
    }
}
