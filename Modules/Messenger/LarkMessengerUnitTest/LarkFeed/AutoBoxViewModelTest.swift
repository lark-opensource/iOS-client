//
//  AutoBoxViewModelTest.swift
//  LarkMessengerUnitTest
//
//  Created by 袁平 on 2020/9/15.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import XCTest
import RxSwift
import RustPB
import SwiftProtobuf
import RunloopTools
import LarkSDKInterface
import LarkNavigation
import AnimatedTabBar
@testable import LarkFeed
import LarkTab

class AutoBoxViewModelTest: XCTestCase {
    var autoBoxVM: AutoBoxViewModel!

    override class func setUp() {
        // 需要注册，否则测试PushFeedPreview时会命中assert
        TabRegistry.register(Tab.feed) { (_) -> TabRepresentable in
            return FeedTab()
        }

        // Chat
        FeedSupplement.shared.registerTableViewCellAndViewModel(.chat, BaseFeedTableCell.self) { (feed, type) -> BaseFeedTableCellViewModel? in
            BaseFeedTableCellViewModel(feedCardPreview: feed, bizType: type)
        }
    }

    override func setUp() {
        let push = PushFeedPreview(updatePreviews: [],
                                   removePreviews: [],
                                   unreadCount: 0,
                                   filteredUnreadCount: 0,
                                   filteredMuteUnreadCount: 0,
                                   delayedChannelCount: 0)
        let threadAvatar = PushThreadFeedAvatarChanges(avatars: [:])
        autoBoxVM = AutoBoxViewModel(dependency: MockAutoBoxDependency(),
                                     baseDependency: MockBaseFeedsViewModelDependency(),
                                     feedPreviewPush: .just(push),
                                     badgeStylePush: .just(.strongRemind),
                                     threadFeedAvatarChangesPush: .just(threadAvatar),
                                     is24HourTime: .init(value: true))
        super.setUp()
    }

    override func tearDown() {
        autoBoxVM = nil
        super.tearDown()
    }

    // MARK: - bizType

    /// case 1: bizType = .autoBox
    func test_bizType() {
        XCTAssert(autoBoxVM.bizType == .autoBox)
    }

    // MARK: - displayFilter

    /// case 1:
    /// parentCardID > 0 -> true
    /// parentCardID <= 0 -> false
    func test_displayFilter() {
        let feed = buildFeedPreview()
        let vm = BaseFeedTableCellViewModel(feedCardPreview: feed, bizType: .autoBox)!

        // parentCardID > 0
        vm.feedCardPreview.parentCardID = "100"
        XCTAssert(autoBoxVM.displayFilter(vm) == true)

        // 默认值 = 0
        vm.feedCardPreview.parentCardID = ""
        XCTAssert(autoBoxVM.displayFilter(vm) == false)

        // parentCardID <= 0
        vm.feedCardPreview.parentCardID = "0"
        XCTAssert(autoBoxVM.displayFilter(vm) == false)
    }

    // MARK: - loadNewBoxFeedCards

    /// case 1: 拉取数据 -> 触发数据更新和reload
    func test_loadNewBoxFeedCards() {
        // 避免relay等初始值影响
        mainWait()

        // 初始值
        var section = SectionHolder()
        section.type = .ignore
        autoBoxVM.feedsRelay.accept(section)

        autoBoxVM.loadNewBoxFeedCards()

        mainWait()

        let uiSection = autoBoxVM.feedsRelay.value
        XCTAssert(uiSection.type == .reload)
        XCTAssert(uiSection.items.count == 3)
    }
}
