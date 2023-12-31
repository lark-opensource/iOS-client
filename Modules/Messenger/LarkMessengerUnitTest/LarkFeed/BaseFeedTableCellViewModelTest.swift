//
//  BaseFeedTableCellViewModelTest.swift
//  LarkMessengerUnitTest
//
//  Created by 袁平 on 2020/9/6.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import XCTest
import RxSwift
import RustPB
import LarkExtensions
import LarkSDKInterface
import LarkFeatureSwitch
import LarkCore
@testable import LarkFeed
@testable import LarkModel

class BaseFeedTableCellViewModelTest: XCTestCase {
    var cellVM: BaseFeedTableCellViewModel!

    override func setUp() {
        var feed = buildFeedPreview()
        feed.id = "1"
        cellVM = BaseFeedTableCellViewModel(feedCardPreview: feed, bizType: .inbox)
        super.setUp()
    }

    override func tearDown() {
        cellVM = nil
        super.tearDown()
    }

    // MARK: - selected

    /// case 1: 默认值：selected = false
    func test_selected() {
        XCTAssert(cellVM.selected == false)
    }

    // MARK: - identity

    /// case 1: 默认值：identity = feedId
    func test_identity() {
        XCTAssert(cellVM.identity == "1")
    }

    // MARK: - cellRowHeight

    /// case 1: 默认值：cellRowHeight = 68
    func test_cellRowHeight() {
        XCTAssert(cellVM.cellRowHeight == 68)
    }

    // MARK: - leftActions && getLeftActions

    /// case 1: switch case
    func test_leftActions_1() {
        // bizType = .inbox -> leftActions = [.done]
        cellVM.bizType = .inbox
        XCTAssert(cellVM.leftActions == [.done])

        // bizType = .done -> leftActions = []
        cellVM.bizType = .done
        XCTAssert(cellVM.leftActions.isEmpty)

        // bizType = .box -> leftActions = []
        cellVM.bizType = .box
        XCTAssert(cellVM.leftActions.isEmpty)

        // bizType = .autoBox -> leftActions = []
        cellVM.bizType = .autoBox
        XCTAssert(cellVM.leftActions.isEmpty)

        // bizType = .markLater -> leftActions = []
        cellVM.bizType = .markLater
        XCTAssert(cellVM.leftActions == [.done])
    }

    // MARK: - rightActions && getRightActions

    /// case 1: switch case
    func test_rightActions_1() {
        // bizType = .inbox -> rightActions = [.markForLater, .quickSwitcher]
        cellVM.bizType = .inbox
        XCTAssert(cellVM.rightActions == [.markForLater, .quickSwitcher])

        // bizType = .done -> rightActions = []
        cellVM.bizType = .done
        XCTAssert(cellVM.rightActions.isEmpty)

        // bizType = .box -> rightActions = [.markForLater, .quickSwitcher]
        cellVM.bizType = .box
        XCTAssert(cellVM.rightActions == [.markForLater, .quickSwitcher])

        // bizType = .autoBox -> rightActions = [.markForLater, .quickSwitcher]
        cellVM.bizType = .autoBox
        XCTAssert(cellVM.rightActions == [.markForLater, .quickSwitcher])

        // bizType = .markLater -> rightActions = [.markForLater, .quickSwitcher]
        cellVM.bizType = .markLater
        XCTAssert(cellVM.rightActions == [.markForLater, .quickSwitcher])
    }

    // MARK: - isShow

    /// case 1: 默认值：isShow = true
    func test_isShow() {
        XCTAssert(cellVM.isShow == true)
    }

    // MARK: - channel

    /// channel是lazy var的，一次生成之后就不再重新生成，所以不能写在一个方法里
    /// case 1: switch case
    func test_channel_1() {
        // feedCardPreview.type = .chat -> channel.id = feedId, channle.type = .chat
        cellVM.feedCardPreview.type = .chat
        XCTAssert(cellVM.channel.type == .chat)
        XCTAssert(cellVM.channel.id == "1")
    }

    /// case 2: feedCardPreview.type = .docFeed -> channel.id = feedId, channle.type = .doc
    func test_channel_2() {
        cellVM.feedCardPreview.type = .docFeed
        XCTAssert(cellVM.channel.type == .doc)
        XCTAssert(cellVM.channel.id == "1")
    }

    /// case 3: feedCardPreview.type = .openapp -> channel.id = feedId, channle.type = .openapp
    func test_channel_3() {
        cellVM.feedCardPreview.type = .openapp
        XCTAssert(cellVM.channel.type == .openapp)
        XCTAssert(cellVM.channel.id == "1")
    }

    /// case 4: feedCardPreview.type = .openappChat -> channel.id = feedId, channle.type = .openappChat
    func test_channel_4() {
        cellVM.feedCardPreview.type = .openappChat
        XCTAssert(cellVM.channel.type == .openappChat)
        XCTAssert(cellVM.channel.id == "1")
    }

    /// case 5: feedCardPreview.type = .thread -> channel.id = feedId, channle.type = .unknown
    func test_channel_5() {
        cellVM.feedCardPreview.type = .thread
        XCTAssert(cellVM.channel.type == .unknown)
        XCTAssert(cellVM.channel.id == "1")
    }

    /// case 6: feedCardPreview.type = .topic -> channel.id = feedId, channle.type = .unknown
    func test_channel_6() {
        cellVM.feedCardPreview.type = .topic
        XCTAssert(cellVM.channel.type == .unknown)
        XCTAssert(cellVM.channel.id == "1")
    }

    // MARK: - miniIcon

    /// case 1: 默认值：miniIcon = nil
    func test_miniIcon() {
        XCTAssert(cellVM.miniIcon == nil)
    }

    // MARK: - lastMessage

    /// case 1: 默认值：lastMessage = ""
    func test_lastMessage() {
        XCTAssert(cellVM.lastMessage.isEmpty)
    }

    // MARK: - lastIcon && getLastIcon

    /// case 1: hasDraftPreview -> lastIcon = Resources.feed_draft_icon
    func test_lastIcon_1() {
        // 初始数据
        cellVM.feedCardPreview.draftPreview = FeedDraftPreview.transform(cardDraftPreview: Feed_V1_FeedCardPreview.DraftPreview())
        cellVM.feedCardPreview.hasDraftPreview = true

        XCTAssert(cellVM.lastIcon == Resources.feed_draft_icon)
    }

    /// case 2: switch case test
    func test_lastIcon_2() {
        // feedCardPreview.entityStatus = .normal -> lastIcon = nil
        cellVM.feedCardPreview.entityStatus = .normal
        XCTAssert(cellVM.lastIcon == nil)

        // feedCardPreview.entityStatus = .read -> lastIcon = Resources.feed_read_icon
        cellVM.feedCardPreview.entityStatus = .read
        XCTAssert(cellVM.lastIcon == Resources.feed_read_icon)

        // feedCardPreview.entityStatus = .unread -> lastIcon = Resources.feed_unread_icon
        cellVM.feedCardPreview.entityStatus = .unread
        XCTAssert(cellVM.lastIcon == Resources.feed_unread_icon)

        // feedCardPreview.entityStatus = .pending -> lastIcon = Resources.sending_message
        cellVM.feedCardPreview.entityStatus = .pending
        XCTAssert(cellVM.lastIcon == Resources.sending_message)

        // feedCardPreview.entityStatus = .failed -> lastIcon = Resources.send_message_failed
        cellVM.feedCardPreview.entityStatus = .failed
        XCTAssert(cellVM.lastIcon == Resources.send_message_failed)
    }

    // MARK: - avatarKey

    /// case 1: 默认值：avatarKey = feedCardPreview.avatarKey
    func test_avatarKey() {
        cellVM.feedCardPreview.avatarKey = "avatarKey_111"

        XCTAssert(cellVM.avatarKey == "avatarKey_111")
    }

    // MARK: - borderImage

    /// case 1: 无加急 -> borderImage = nil
    func test_borderImage_1() {
        cellVM.feedCardPreview.urgents = []

        XCTAssert(cellVM.borderImage == nil)
    }

    /// case 2: 有加急 -> borderImage = Resources.feed_avatar_inner_border
    func test_borderImage_2() {
        cellVM.feedCardPreview.urgents = [Basic_V1_Urgent()]

        XCTAssert(cellVM.borderImage == Resources.feed_avatar_inner_border)
    }

    // MARK: - topBadgeMaxCount

    /// case 1: 默认值：topBadgeMaxCount = 999
    func test_topBadgeMaxCount() {
        XCTAssert(cellVM.topBadgeMaxCount == 999)
    }

    // MARK: - topBadgeInfo && getTopBadgeInfo

    /// case 1: unreadCount <= 0 -> (.none, weak)
    func test_topBadgeInfo_1() {
        cellVM.feedCardPreview.unreadCount = 0

        XCTAssert(cellVM.topBadgeInfo == (.none, .weak))
    }

    /// case 2: isRemind = true -> switch case
    func test_topBadgeInfo_2() {
        cellVM.feedCardPreview.isRemind = true
        cellVM.feedCardPreview.unreadCount = 10

        // feedCardPreview.feedType = .inbox -> topBadgeInfo = (.label(.number(unreadCount)), .strong)
        cellVM.feedCardPreview.feedType = .inbox
        XCTAssert(cellVM.topBadgeInfo == (.label(.number(10)), .strong))

        // feedCardPreview.feedType = .done -> topBadgeInfo = (.label(.number(unreadCount)), .middle)
        cellVM.feedCardPreview.feedType = .done
        XCTAssert(cellVM.topBadgeInfo == (.label(.number(10)), .middle))

        // feedCardPreview.feedType = .unknown -> topBadgeInfo = (.none, .weak)
        cellVM.feedCardPreview.feedType = .unknown
        XCTAssert(cellVM.topBadgeInfo == (.none, .weak))
    }

    /// csae 3: feedCardPreview.feedType = .done, isRemind = false -> topBadgeInfo = (.dot(.lark), .weak)
    func test_topBadgeInfo_3() {
        cellVM.feedCardPreview.isRemind = false
        cellVM.feedCardPreview.feedType = .done
        cellVM.feedCardPreview.unreadCount = 10

        XCTAssert(cellVM.topBadgeInfo == (.dot(.lark), .weak))
    }

    /// case 4: unreadCount > 0, isRemind = false, feedType != .done -> switch case
    func test_topBadgeInfo_4() {
        cellVM.feedCardPreview.isRemind = false
        cellVM.feedCardPreview.feedType = .inbox
        cellVM.feedCardPreview.unreadCount = 10

        // BaseFeedsViewModel.badgeStyle = .weakRemind
        BaseFeedsViewModel.badgeStyle = .weakRemind
        XCTAssert(cellVM.topBadgeInfo == (.label(.number(10)), .weak))

        // BaseFeedsViewModel.badgeStyle = .strongRemind
        BaseFeedsViewModel.badgeStyle = .strongRemind
        XCTAssert(cellVM.topBadgeInfo == (.dot(.lark), .strong))
    }

    // MARK: - isDelayed && getIsDelayed

    /// case 1: bizType = .markLater -> isDelayed = false
    func test_isDelayed_1() {
        // 排除默认值影响
        cellVM.feedCardPreview.isDelayed = true

        cellVM.bizType = .markLater

        XCTAssert(cellVM.isDelayed == false)
    }

    /// case 2: bizType != .markLater
    func test_isDelayed_2() {
        cellVM.feedCardPreview.isDelayed = true

        cellVM.bizType = .inbox
        XCTAssert(cellVM.isDelayed == true)

        cellVM.bizType = .done
        XCTAssert(cellVM.isDelayed == true)

        cellVM.bizType = .box
        XCTAssert(cellVM.isDelayed == true)

        cellVM.bizType = .autoBox
        XCTAssert(cellVM.isDelayed == true)
    }

    // MARK: - name

    /// case 1: 默认值：name = feedCardPreview.name
    func test_name() {
        cellVM.feedCardPreview.name = "name123"

        XCTAssert(cellVM.name == "name123")
    }

    // MARK: - time

    /// case 1: 默认值：time = Date.lf.getNiceDateString(TimeInterval(feedCardPreview.displayTime))
    func test_time() {
        let time = Int(CACurrentMediaTime())
        cellVM.feedCardPreview.displayTime = time

        XCTAssert(cellVM.time == Date.lf.getNiceDateString(TimeInterval(time)))
    }

    // MARK: - tags

    /// case 1: 默认值：tags = []
    func test_tags() {
        XCTAssert(cellVM.tags.isEmpty)
    }

    // MARK: - getLastMessage

    /// case 1: 有草稿 -> 返回草稿
    func test_getLastMessage_1() {
        // 初始值：有草稿
        var draft = Feed_V1_FeedCardPreview.DraftPreview()
        draft.content = "Draft For Cell"
        cellVM.feedCardPreview.draftPreview = FeedDraftPreview.transform(cardDraftPreview: draft)
        cellVM.feedCardPreview.hasDraftPreview = true

        let lastMsg = cellVM.getLastMessage()

        XCTAssert(lastMsg == (RichTextTransformKit.transformDraftToText(content: draft.content) ?? ""))
    }

    /// case 2: 无草稿，BaseFeedsViewModel.badgeStyle = .strongRemind，unreadCount = 1，isRemind = false
    /// -> lastMsg = BundleI18n.LarkFeed.Lark_Legacy_UnReadCount("\(unreadCount)")
    func test_getLastMessage_2() {
        // 初始条件
        cellVM.feedCardPreview.unreadCount = 1
        cellVM.feedCardPreview.isRemind = false
        cellVM.feedCardPreview.localizedDigestMessage = "localizedDigestMessage"
        BaseFeedsViewModel.badgeStyle = .strongRemind

        let lastMsg = cellVM.getLastMessage()

        // 验证
        var target = BundleI18n.LarkFeed.Lark_Legacy_UnReadCount("\(1)")
        target.append("localizedDigestMessage")
        XCTAssert(lastMsg == target)
    }

    /// case 3: 无草稿，BaseFeedsViewModel.badgeStyle = .strongRemind，unreadCount > 1，isRemind = false
    /// -> lastMsg = BundleI18n.LarkFeed.Lark_Legacy_UnReadCounts("\(unreadCount)")
    func test_getLastMessage_3() {
        // 初始条件
        cellVM.feedCardPreview.unreadCount = 10
        cellVM.feedCardPreview.isRemind = false
        cellVM.feedCardPreview.localizedDigestMessage = "localizedDigestMessage"
        BaseFeedsViewModel.badgeStyle = .strongRemind

        let lastMsg = cellVM.getLastMessage()

        // 验证
        var target = BundleI18n.LarkFeed.Lark_Legacy_UnReadCounts("\(10)")
        target.append("localizedDigestMessage")
        XCTAssert(lastMsg == target)
    }

    /// case 4: 无草稿，BaseFeedsViewModel.badgeStyle = .weakRemind
    /// -> lastMsg = localizedDigestMessage
    func test_getLastMessage_4() {
        // 初始条件
        cellVM.feedCardPreview.unreadCount = 10
        cellVM.feedCardPreview.isRemind = false
        cellVM.feedCardPreview.localizedDigestMessage = "localizedDigestMessage"
        BaseFeedsViewModel.badgeStyle = .weakRemind

        let lastMsg = cellVM.getLastMessage()

        // 验证
        XCTAssert(lastMsg == "localizedDigestMessage")
    }

    /// case 5: Crash Fix Test
    /// fix crash on iOS11
    /// Jira：https://jira.bytedance.com/browse/SUITE-64239
    func test_getLastMessage_5() {
        // 初始条件
        cellVM.feedCardPreview.localizedDigestMessage = "?️localizedDigestMessage./\\?️?️?️"
        BaseFeedsViewModel.badgeStyle = .weakRemind

        let lastMsg = cellVM.getLastMessage()

        // 验证
        if #available(iOS 12.0, *) {
            XCTAssert(lastMsg == "?️localizedDigestMessage./\\?️?️?️")
        } else {
            XCTAssert(lastMsg == "?localizedDigestMessage./\\???")
        }
    }
}
