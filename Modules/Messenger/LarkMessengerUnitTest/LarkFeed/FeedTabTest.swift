//
//  FeedTabTest.swift
//  LarkMessengerUnitTest
//
//  Created by 袁平 on 2020/9/3.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import XCTest
import AnimatedTabBar
@testable import LarkFeed

class FeedTabTest: XCTestCase {
    var tab: FeedTab!

    override class func setUp() {
    }

    override func setUp() {
        tab = FeedTab()
        super.setUp()
    }

    override func tearDown() {
        tab = nil
        super.tearDown()
    }

    // MARK: - tab

    /// case 1: tab == .feed
    func test_tab() {
        XCTAssert(tab.tab == .feed)
    }

    // MARK: - updateBadge

    /// case 1: filteredUnreadCount > 0 -> badgeType == .number(filteredUnreadCount)
    func test_updateBadge_1() {
        let push = PushFeedPreview(updatePreviews: [],
                                   removePreviews: [],
                                   unreadCount: 10,
                                   filteredUnreadCount: 10,
                                   filteredMuteUnreadCount: 10,
                                   delayedChannelCount: 10)
        tab.updateBadge(push: push)

        XCTAssert(tab.badge?.value == .number(10))
    }

    /// case 2: filteredUnreadCount = 0, filteredMuteUnreadCount > 0 -> badgeType = .dot(filteredMuteUnreadCount)
    func test_updateBadge_2() {
        let push = PushFeedPreview(updatePreviews: [],
                                   removePreviews: [],
                                   unreadCount: 10,
                                   filteredUnreadCount: 0,
                                   filteredMuteUnreadCount: 10,
                                   delayedChannelCount: 10)
        tab.updateBadge(push: push)

        XCTAssert(tab.badge?.value == .dot(10))
    }

    /// case 3: filteredUnreadCount = 0, filteredMuteUnreadCount = 0 -> badgeType = .none
    func test_updateBadge_3() {
        let push = PushFeedPreview(updatePreviews: [],
                                   removePreviews: [],
                                   unreadCount: 10,
                                   filteredUnreadCount: 0,
                                   filteredMuteUnreadCount: 0,
                                   delayedChannelCount: 10)
        tab.updateBadge(push: push)

        XCTAssert(tab.badge?.value == BadgeType.none)
    }

    // MARK: - set

    /// case 1: badge = .number, BaseFeedsViewModel.badgeStyle = .strongRemind -> springBoardBadgeEnable = true, badgeStyle == .strong
    func test_set_1() {
        BaseFeedsViewModel.badgeStyle = .strongRemind
        tab.set(.number(10))

        XCTAssert(tab.springBoardBadgeEnable?.value == true)
        XCTAssert(tab.badgeStyle?.value == .strong)
    }

    /// case 2: badge = .dot, BaseFeedsViewModel.badgeStyle = .weakRemind -> springBoardBadgeEnable = false, badgeStyle == .weak
    func test_set_2() {
        BaseFeedsViewModel.badgeStyle = .weakRemind
        tab.set(.dot(10))

        XCTAssert(tab.springBoardBadgeEnable?.value == false)
        XCTAssert(tab.badgeStyle?.value == .weak)
    }

    /// case 3: badge = .none, BaseFeedsViewModel.badgeStyle = .weakRemind -> springBoardBadgeEnable = false, badgeStyle == .weak
    func test_set_3() {
        BaseFeedsViewModel.badgeStyle = .weakRemind
        tab.set(.none)

        XCTAssert(tab.springBoardBadgeEnable?.value == false)
        XCTAssert(tab.badgeStyle?.value == .weak)
    }
}
