//
//  LarkFilterViewModelTest.swift
//  LarkMessengerUnitTest
//
//  Created by 袁平 on 2020/9/17.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import XCTest
import RxSwift
import RustPB
import LarkBadge
import LarkFeatureGating
import LarkAccountInterface
@testable import LarkFeed

class LarkFilterViewModelTest: XCTestCase {
    var filterVM: LarkFilterViewModel!

    override class func setUp() {
        // 模拟登陆：FG需要userId
        MockAccountService.login()
        LarkFeatureGating.shared.loadFeatureValues(with: AccountServiceAdapter.shared.currentChatterId)
    }

    override func setUp() {
        filterVM = buildFilterVM()
        super.setUp()
    }

    override func tearDown() {
        filterVM = nil
        super.tearDown()
    }

    private func buildFilterVM() -> LarkFilterViewModel {
        let push = PushFeedPreview(updatePreviews: [],
                                   removePreviews: [],
                                   unreadCount: 0,
                                   filteredUnreadCount: 0,
                                   filteredMuteUnreadCount: 0,
                                   delayedChannelCount: 0)
        return LarkFilterViewModel(inboxBadgeType: .init(value: push),
                                   doneBadgeType: .just(Feed_V1_ComputeDoneCardsResponse()),
                                   defaultSelect: (.inbox, .all))
    }

    // MARK: - filterItems & columnCount & totalHeight

    /// case 1: FG开启
    func test_filterItems_1() {
        // 开启密聊
        LarkFeatureGating.shared.updateFeatureBoolValue(for: "secretchat.main", value: true)
        // LarkFilterViewModel初始化方法中会调用filterItems，需要在FG设置之后重新构造一遍
        filterVM = buildFilterVM()

        // filterItems
        let filterItems = filterVM.filterItems
        XCTAssert(filterItems.count == 2)
        let inbox = filterItems[0]
        XCTAssert(inbox.title == BundleI18n.LarkFeed.Lark_Legacy_FeedInboxHead)
        XCTAssert(inbox.feedType == .inbox)
        XCTAssert(inbox.subFilters == [.all, .chat, .doc, .secretChat, .external, .thread])
        let done = filterItems[1]
        XCTAssert(done.title == BundleI18n.LarkFeed.Lark_Legacy_FeedDoneHead)
        XCTAssert(done.feedType == .done)
        XCTAssert(done.subFilters == [.all, .chat, .doc, .secretChat, .external, .thread])

        // columnCount
        XCTAssert(filterVM.columnCount == 2)

        // totalHeight
        XCTAssert(filterVM.totalHeight == 53 * 6)
    }

    /// case 2: FG关闭
    func test_filterItems_2() {
        // 关闭密聊
        LarkFeatureGating.shared.updateFeatureBoolValue(for: "secretchat.main", value: false)
        // LarkFilterViewModel初始化方法中会调用filterItems，需要在FG设置之后重新构造一遍
        filterVM = buildFilterVM()

        let filterItems = filterVM.filterItems
        XCTAssert(filterItems.count == 2)
        let inbox = filterItems[0]
        XCTAssert(inbox.title == BundleI18n.LarkFeed.Lark_Legacy_FeedInboxHead)
        XCTAssert(inbox.feedType == .inbox)
        XCTAssert(inbox.subFilters == [.all, .chat, .doc, .external])
        let done = filterItems[1]
        XCTAssert(done.title == BundleI18n.LarkFeed.Lark_Legacy_FeedDoneHead)
        XCTAssert(done.feedType == .done)
        XCTAssert(done.subFilters == [.all, .chat, .doc, .external])

        // columnCount
        XCTAssert(filterVM.columnCount == 2)

        // totalHeight
        XCTAssert(filterVM.totalHeight == 53 * 4)
    }

    // MARK: - selectFilter

    /// case 1: 选中inbox/done或者其subFilter
    func test_selectFilter() {
        // 开启密聊
        LarkFeatureGating.shared.updateFeatureBoolValue(for: "secretchat.main", value: true)

        // LarkFilterViewModel初始化方法中会调用filterItems，需要在FG设置之后重新构造一遍
        filterVM = buildFilterVM()

        filterVM.selectFilter(index: 1, isSub: true)

        XCTAssert(filterVM.highlightFilter == (.inbox, .chat))
        XCTAssert(filterVM.selectedFilter == (.inbox, .chat))

        filterVM.selectFilter(index: 1, isSub: false)
        XCTAssert(filterVM.highlightFilter == (.done, nil))
        XCTAssert(filterVM.selectedFilter == (.inbox, .chat))
    }

    // MARK: updateInboxBadge

    /// case 1: 如下三种case
    func test_updateInboxBadge() {
        // 1.1 filteredUnreadCount > 0 -> badgeType = (.label(.number(filteredUnreadCount)), .strong)
        let push1 = PushFeedPreview(updatePreviews: [],
                                    removePreviews: [],
                                    unreadCount: 0,
                                    filteredUnreadCount: 10,
                                    filteredMuteUnreadCount: 0,
                                    delayedChannelCount: 0)
        filterVM.updateInboxBadge(push1)
        XCTAssert(filterVM.filterItems[0].badgeType == (.label(.number(10)), .strong))

        // 1.2 filteredUnreadCount <= 0 && filteredMuteUnreadCount > 0
        let push2 = PushFeedPreview(updatePreviews: [],
                                    removePreviews: [],
                                    unreadCount: 0,
                                    filteredUnreadCount: 0,
                                    filteredMuteUnreadCount: 10,
                                    delayedChannelCount: 0)
        BaseFeedsViewModel.badgeStyle = .weakRemind
        filterVM.updateInboxBadge(push2)
        XCTAssert(filterVM.filterItems[0].badgeType == (.label(.number(10)), .weak))
        BaseFeedsViewModel.badgeStyle = .strongRemind
        filterVM.updateInboxBadge(push2)
        XCTAssert(filterVM.filterItems[0].badgeType == (.dot(.lark), .strong))

        // 1.3 filteredUnreadCount <= 0 && filteredMuteUnreadCount <= 0
        let push3 = PushFeedPreview(updatePreviews: [],
                                    removePreviews: [],
                                    unreadCount: 0,
                                    filteredUnreadCount: 0,
                                    filteredMuteUnreadCount: 0,
                                    delayedChannelCount: 0)
        filterVM.updateInboxBadge(push3)
        XCTAssert(filterVM.filterItems[0].badgeType == (.none, .weak))
    }

    // MARK: - updateDoneBadge

    /// case 1: 如下三种case
    func test_updateDoneBadge() {
        // 1.1 unreadCount > 0
        var response = Feed_V1_ComputeDoneCardsResponse()
        response.unreadCount = 10
        filterVM.updateDoneBadge(response)
        XCTAssert(filterVM.filterItems[1].badgeType == (.label(.number(Int(10))), .middle))

        // 1.2 unreadCount <= 0 & hasUnreadDot_p = true
        response.unreadCount = 0
        response.hasUnreadDot_p = true
        filterVM.updateDoneBadge(response)
        XCTAssert(filterVM.filterItems[1].badgeType == (.dot(.lark), .weak))

        // 1.3 unreadCount <= 0 & hasUnreadDot_p = false
        response.unreadCount = 0
        response.hasUnreadDot_p = false
        filterVM.updateDoneBadge(response)
        XCTAssert(filterVM.filterItems[1].badgeType == (.none, .weak))
    }
}
