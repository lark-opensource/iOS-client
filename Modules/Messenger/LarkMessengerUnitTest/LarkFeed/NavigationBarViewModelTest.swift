//
//  NavigationBarViewModelTest.swift
//  LarkMessengerUnitTest
//
//  Created by 袁平 on 2020/9/17.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import XCTest
import RxSwift
import RustPB
import RunloopTools
@testable import LarkFeed

class NavigationBarViewModelTest: XCTestCase {
    var naviBarVM: NavigationBarViewModel!

    override func setUp() {
        naviBarVM = NavigationBarViewModel(netStatusObservable: .empty(),
                                           feedLoadStatusObservable: .empty())
        super.setUp()
    }

    override func tearDown() {
        naviBarVM = nil
        super.tearDown()
    }

    // MARK: - loadFeedStart

    /// case 1: loadFeedStart -> isSyncing = true
    func test_loadFeedStart() {
        // 初始值
        naviBarVM.isSyncing = false

        naviBarVM.loadFeedStart()
        XCTAssert(naviBarVM.isSyncing == true)
    }

    // MARK: - loadFeedEnd

    /// case 2: loadFeedEnd -> isSyncing = false
    func test_loadFeedEnd() {
        // 初始值
        naviBarVM.isSyncing = true

        naviBarVM.loadFeedEnd()
        XCTAssert(naviBarVM.isSyncing == false)
    }

    // MARK: - emissionFeedSatus

    /// case 1: netStatus = .netUnavailable || .serviceUnavailable || .offline
    func test_emissionFeedSatus_1() {
        // 1.1 .netUnavailable
        naviBarVM.netStatus = .netUnavailable
        // 代码里是main.async设置
        mainWait()
        XCTAssert(naviBarVM.titleText.value == BundleI18n.LarkFeed.Lark_Legacy_ChatTableHeaderNotConnected)
        XCTAssert(naviBarVM.isLoading.value == false)

        // 1.2 .serviceUnavailable
        naviBarVM.netStatus = .serviceUnavailable
        // 代码里是main.async设置
        mainWait()
        XCTAssert(naviBarVM.titleText.value == BundleI18n.LarkFeed.Lark_Legacy_ChatTableHeaderNotConnected)
        XCTAssert(naviBarVM.isLoading.value == false)

        // 1.3 .offline
        naviBarVM.netStatus = .offline
        // 代码里是main.async设置
        mainWait()
        XCTAssert(naviBarVM.titleText.value == BundleI18n.LarkFeed.Lark_Legacy_ChatTableHeaderNotConnected)
        XCTAssert(naviBarVM.isLoading.value == false)
    }

    /// case 2: netStatus = .excellent || .evaluating || .weak
    func test_emissionFeedStatus_2() {
        // 初始值
        naviBarVM.isSyncing = true
        // 避免初始值影响
        mainWait()

        // 2.1 .excellent
        naviBarVM.netStatus = .excellent
        // 代码里是main.async设置
        mainWait()
        XCTAssert(naviBarVM.titleText.value == BundleI18n.LarkFeed.Lark_Legacy_ChatTableHeaderLoading)
        XCTAssert(naviBarVM.isLoading.value == true)

        // 2.2 .evaluating
        naviBarVM.netStatus = .evaluating
        // 代码里是main.async设置
        mainWait()
        XCTAssert(naviBarVM.titleText.value == BundleI18n.LarkFeed.Lark_Legacy_ChatTableHeaderLoading)
        XCTAssert(naviBarVM.isLoading.value == true)

        // 2.3 .weak
        naviBarVM.netStatus = .weak
        // 代码里是main.async设置
        mainWait()
        XCTAssert(naviBarVM.titleText.value == BundleI18n.LarkFeed.Lark_Legacy_ChatTableHeaderLoading)
        XCTAssert(naviBarVM.isLoading.value == true)

        // ---------------

        // 初始值
        naviBarVM.isSyncing = false
        // 避免初始值影响
        mainWait()

        // 2.4 .excellent
        naviBarVM.feedType = .inbox
        naviBarVM.netStatus = .excellent
        // 代码里是main.async设置
        mainWait()
        XCTAssert(naviBarVM.titleText.value == BundleI18n.LarkFeed.Lark_Legacy_FeedInboxHead)
        XCTAssert(naviBarVM.isLoading.value == false)

        // 2.5 .excellent
        naviBarVM.feedType = .done
        naviBarVM.netStatus = .excellent
        // 代码里是main.async设置
        mainWait()
        XCTAssert(naviBarVM.titleText.value == BundleI18n.LarkFeed.Lark_Legacy_FeedDoneHead)
        XCTAssert(naviBarVM.isLoading.value == false)
    }
}
