//
//  BoxFeedTableCellViewModelTest.swift
//  LarkMessengerUnitTest
//
//  Created by 袁平 on 2020/9/15.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import XCTest
import RxSwift
import RustPB
import SwiftProtobuf
import RunloopTools
@testable import LarkModel
@testable import LarkFeed

class BoxFeedTableCellViewModelTest: XCTestCase {
    var boxCellVM: BoxFeedTableCellViewModel!

    override func setUp() {
        var feed = buildFeedPreview()
        feed.id = "1"
        feed.type = .box
        boxCellVM = BoxFeedTableCellViewModel(feedCardPreview: feed, bizType: .inbox)
        super.setUp()
    }

    override func tearDown() {
        boxCellVM = nil
        super.tearDown()
    }

    // MARK: - badgeStyle

    /// case 1: 三种case如下
    func test_badgeStyle() {
        // unreadCount <= 0 -> return nil
        boxCellVM.feedCardPreview.unreadCount = 0
        XCTAssert(boxCellVM.badgeStyle == nil)

        // unreadCount > 0, BaseFeedsViewModel.badgeStyle = .weakRemind
        boxCellVM.feedCardPreview.unreadCount = 1
        BaseFeedsViewModel.badgeStyle = .weakRemind
        XCTAssert(boxCellVM.badgeStyle == .weak)

        // unreadCount > 0, BaseFeedsViewModel.badgeStyle = .strongRemind
        boxCellVM.feedCardPreview.unreadCount = 1
        BaseFeedsViewModel.badgeStyle = .strongRemind
        XCTAssert(boxCellVM.badgeStyle == .strong)
    }

    // MARK: - leftActions

    /// case 1: leftActions = []
    func test_leftActions() {
        XCTAssert(boxCellVM.leftActions.isEmpty == true)
    }

    // MARK: - rightActions

    /// case 1: rightActions = []
    func test_rightActions() {
        XCTAssert(boxCellVM.rightActions.isEmpty == true)
    }

    // MARK: - name

    /// case 1: name = BundleI18n.LarkFeed.Lark_Legacy_ChatBox
    func test_name() {
        XCTAssert(boxCellVM.name == BundleI18n.LarkFeed.Lark_Legacy_ChatBox)
    }

    // MARK: - lastMessage

    /// case 1: lastMessage = feedCardPreview.localizedDigestMessage
    func test_lastMessage() {
        // 初始条件
        boxCellVM.feedCardPreview.localizedDigestMessage = "localizedDigestMessage"

        XCTAssert(boxCellVM.lastMessage == "localizedDigestMessage")
    }

    // MARK: - lastMessageAttr

    /// case 1: unreadCount <= 0 -> return nil
    func test_lastMessageAttr_1() {
        // 初始条件
        boxCellVM.feedCardPreview.unreadCount = 0

        XCTAssert(boxCellVM.lastMessageAttr == nil)
    }

    /// case 2: unreadCount > 0, atInfos = [] ->
    /// return NSAttributedString(string: "[\(feedCardPreview.localizedDigestMessage)]")
    func test_lastMessageAttr_2() {
        // 初始条件
        boxCellVM.feedCardPreview.unreadCount = 10
        boxCellVM.feedCardPreview.atInfos = []
        boxCellVM.feedCardPreview.localizedDigestMessage = "localizedDigestMessage"

        let res = NSAttributedString(string: "[localizedDigestMessage]")
        XCTAssert(boxCellVM.lastMessageAttr == res)
    }

    /// case 3: unreadCount > 0, atInfos非空 ->
    func test_lastMessageAttr_3() {
        // 初始条件
        boxCellVM.feedCardPreview.unreadCount = 10
        var atInfo1 = Feed_V1_FeedCardPreview.AtInfo()
        atInfo1.channelName = "name1"
        // atInfos.count = 1
        boxCellVM.feedCardPreview.atInfos = [FeedPreviewAtInfo.transform(cardAtInfo: atInfo1)]
        boxCellVM.feedCardPreview.localizedDigestMessage = "localizedDigestMessage"

        let attrStr1 = NSAttributedString(string: BundleI18n.LarkFeed.Lark_Legacy_FeedBoxOneGroupHasAt("name1"),
                                            attributes: [.foregroundColor: UIColor.ud.colorfulBlue])
        let res1 = NSMutableAttributedString(attributedString: attrStr1)
        res1.append(NSAttributedString(string: "[localizedDigestMessage]"))
        XCTAssert(boxCellVM.lastMessageAttr == res1)

        // atInfos.count > 1
        var atInfo2 = Feed_V1_FeedCardPreview.AtInfo()
        atInfo2.channelName = "name2"
        boxCellVM.feedCardPreview.atInfos = FeedPreviewAtInfo.transform(cardAtInfos: [atInfo1, atInfo2])

        let attrStr2 = NSAttributedString(string: BundleI18n.LarkFeed.Lark_Legacy_AtInGroups("2"),
                                          attributes: [.foregroundColor: UIColor.ud.colorfulBlue])
        let res2 = NSMutableAttributedString(attributedString: attrStr2)
        res2.append(NSAttributedString(string: "[localizedDigestMessage]"))
        XCTAssert(boxCellVM.lastMessageAttr == res2)
    }
}
