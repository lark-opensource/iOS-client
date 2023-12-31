//
//  ShortcutBaseCellViewModelTest.swift
//  LarkMessengerUnitTest
//
//  Created by 夏汝震 on 2020/9/24.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import XCTest
import RxSwift
import RustPB
import LarkExtensions
import LarkSDKInterface
import LarkFeatureGating
import LarkCore
import LarkAccountInterface
@testable import LarkFeed
@testable import LarkModel

class ShortcutBaseCellViewModelTest: XCTestCase {

    var cellVM: ShortcutBaseCellViewModel!

    override class func setUp() {
        // 打开所用到的FG
        MockAccountService.login()
        LarkFeatureGating.shared.loadFeatureValues(with: AccountServiceAdapter.shared.currentChatterId)
        LarkFeatureGating.shared.updateFeatureBoolValue(for: "lark_feature_doc_icon_custom", value: true)
    }

    override func setUp() {
        cellVM = creatCellViewModel()
        super.setUp()
    }

    override func tearDown() {
        cellVM = nil
        super.tearDown()
    }

    // MARK: avatarKey
    // case1: 测试 docCustomAvatarEnable 对avatarKey的影响
    func test_avatarKey_1() {
        var preview = feedPreview
        let avatarKey = "avatarKey"
        preview.avatarKey = avatarKey
        let vm = cellVM.update(cardPreview: preview)
        XCTAssert(vm.avatarKey == avatarKey)
    }

    // case2: 测试 icon.type == .unknown 对avatarKey的影响
    func test_avatarKey_2() {
        var preview = feedPreview
        let avatarKey = "avatarKey"
        preview.avatarKey = avatarKey
        preview.type = .docFeed
        preview.hasIcon = true
        preview.icon.type = .unknown
        let vm = cellVM.update(cardPreview: preview)
        XCTAssert(vm.avatarKey == avatarKey)
    }

    // case3: 测试 icon.type = .image 对avatarKey 的影响
    func test_avatarKey_3() {
        var preview = feedPreview
        let avatarKey = "avatarKey"
        preview.avatarKey = avatarKey
        preview.type = .docFeed
        preview.hasIcon = true
        preview.icon.type = .image
        preview.icon.value = "iconValue "
        let vm = cellVM.update(cardPreview: preview)
        XCTAssert(vm.avatarKey == preview.icon.value)
    }

    // MARK: appURL
    // case1: 测试 无 preview.type 对avatarKey 的影响
    func test_appURL_1() {
        var preview = feedPreview
        preview.type = .openapp
        preview.iosSchema = "iosSchema"
        let vm = self.cellVM.update(cardPreview: preview)
        XCTAssert(vm.appURL == preview.iosSchema)
    }

    // case2: 测试 preview.type = .openapp 对avatarKey 的影响
    func test_appURL_2() {
        var preview = feedPreview
        preview.type = .openappChat
        preview.openAppCard.appNotificationSchema = "appNotificationSchema"
        let vm = cellVM.update(cardPreview: preview)
        XCTAssert(vm.appURL == preview.openAppCard.appNotificationSchema)
    }

    // case3: 测试 preview.type = .openappChat 对avatarKey 的影响
    func test_appURL_3() {
        var preview = feedPreview
        preview.type = .docFeed
        let vm = cellVM.update(cardPreview: preview)
        XCTAssert(vm.appURL.isEmpty)
    }

    // MARK: seqID
    // case1: 测试 无 preview.type 对avatarKey 的影响
    func test_seqID_1() {
        var preview = feedPreview
        preview.type = .openapp
        preview.lastNotificationSeqID = "lastNotificationSeqID"
        let vm = cellVM.update(cardPreview: preview)
        XCTAssert(vm.seqID == preview.lastNotificationSeqID)
    }

    // case2: 测试 preview.type = .openapp 对avatarKey 的影响
    func test_seqID_2() {
        var preview = feedPreview
        preview.type = .openappChat
        preview.openAppCard.lastNotificationSeqID = "lastNotificationSeqID"
        let vm = cellVM.update(cardPreview: preview)
        XCTAssert(vm.seqID == preview.openAppCard.lastNotificationSeqID)
    }

    // case3: 测试 preview.type = .openappChat 对avatarKey 的影响
    func test_seqID_3() {
        var preview = feedPreview
        preview.type = .docFeed
        let vm = cellVM.update(cardPreview: preview)
        XCTAssert(vm.seqID.isEmpty)
    }

    // MARK: topBadgeInfo
    func test_topBadgeInfo_() {
        var preview = feedPreview

        // 测试加急对topBadgeInfo的影响
        preview.urgents = [Basic_V1_Urgent()]
        var vm = cellVM.update(cardPreview: preview)
        //XCTAssert(cellVM.topBadgeInfo == (.image(.image(Resources.badge_urgent_icon)), .weak))
        preview.urgents = []
        vm = vm.update(cardPreview: preview)

        // 测试at对topBadgeInfo的影响
        preview.hasAtInfo = true
        vm = vm.update(cardPreview: preview)
        XCTAssert(vm.topBadgeInfo == (.image(.image(Resources.badge_at_icon)), .weak))
        preview.hasAtInfo = false
        vm = vm.update(cardPreview: preview)

        // 测试未读对topBadgeInfo的影响
        var unreadCount = 0
        preview.unreadCount = unreadCount
        vm = vm.update(cardPreview: preview)
        XCTAssert(vm.topBadgeInfo == (.none, .weak))

        unreadCount = 10
        preview.unreadCount = unreadCount
        vm = vm.update(cardPreview: preview)

        // 测试isRemind对topBadgeInfo的影响
        preview.isRemind = true

        // 测试feedType对topBadgeInfo的影响
        preview.feedType = .inbox
        vm = vm.update(cardPreview: preview)
        XCTAssert(vm.topBadgeInfo == (.label(.number(unreadCount)), .strong))

        preview.feedType = .done
        vm = vm.update(cardPreview: preview)
        XCTAssert(vm.topBadgeInfo == (.label(.number(unreadCount)), .middle))

        preview.feedType = .unknown
        vm = vm.update(cardPreview: preview)
        XCTAssert(vm.topBadgeInfo == (.none, .weak))

        // 测试.done对topBadgeInfo的影响
        preview.isRemind = false
        preview.feedType = .done
        vm = vm.update(cardPreview: preview)
        XCTAssert(vm.topBadgeInfo == (.dot(.lark), .weak))

        // 测试badgeStyle对topBadgeInfo的影响
        preview.feedType = .inbox
        vm = vm.update(cardPreview: preview)
        BaseFeedsViewModel.badgeStyle = .weakRemind
        XCTAssert(vm.topBadgeInfo == (.label(.number(unreadCount)), .weak))

        BaseFeedsViewModel.badgeStyle = .strongRemind
        XCTAssert(vm.topBadgeInfo == (.dot(.lark), .strong))
    }
}

extension ShortcutBaseCellViewModelTest {

    /// 填充数据
    func creatCellViewModel() -> ShortcutBaseCellViewModel {
        let id = "0"
        var short = Shortcut()
        short.position = 0
        short.channel.id = id
        short.channel.type = Channel.TypeEnum.allCases.randomElement()!
        short.position = Int32(0)
        short.channel.id = id

        var feed = feedPreview
        feed.id = id
        let obj = ShortcutResult(shortcut: short, preview: feed)
        return ShortcutBaseCellViewModel(result: obj)
    }

    var feedPreview: FeedPreview {
        var feed = FeedPreview()
        feed.id = "0"
        feed.type = Basic_V1_FeedCard.EntityType.allCases.randomElement()!
        feed.name = "name"
        let time = Int(NSDate().timeIntervalSince1970)
        feed.displayTime = time
        feed.rankTime = time
        feed.feedType = .inbox
        return feed
    }
}
