//
//  FeedPreloaderServiceImplTest.swift
//  LarkMessengerUnitTest
//
//  Created by 袁平 on 2020/9/11.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import XCTest
import RxSwift
import RustPB
import SwiftProtobuf
import LarkSDKInterface
import RunloopTools
import LarkFeatureGating
import LarkAccountInterface
import LarkNavigation
import AnimatedTabBar
@testable import LarkFeed
import LarkTab

class FeedPreloaderServiceImplTest: XCTestCase {
    var mockDependency: MockFeedPreloaderServiceDependency!
    var mockTabDependency: MockTabFeedsViewModelDependency!
    var preloader: FeedPreloaderServiceImpl!
    var mainFeedsVM: MainFeedsViewModel!

    override class func setUp() {
        // 需要注册，否则测试PushFeedPreview时会命中assert
        TabRegistry.register(Tab.feed) { (_) -> TabRepresentable in
            return FeedTab()
        }

        // Chat
        FeedSupplement.shared.registerTableViewCellAndViewModel(.chat, BaseFeedTableCell.self) { (feed, type) -> BaseFeedTableCellViewModel? in
            BaseFeedTableCellViewModel(feedCardPreview: feed, bizType: type)
        }

        RunloopDispatcher.enable = true

        MockAccountService.login()

        LarkFeatureGating.shared.loadFeatureValues(with: AccountServiceAdapter.shared.currentChatterId)
        // 开启FG
        LarkFeatureGating.shared.updateFeatureBoolValue(for: "lark.autochatbox", value: true)

        // 打开cache FG
        LarkFeatureGating.shared.updateFeatureBoolValue(for: FeatureGatingKey.feedCacheEnabled, value: true)
    }

    override func setUp() {
        MockAccountService.login()

        mockDependency = MockFeedPreloaderServiceDependency()
        mockTabDependency = MockTabFeedsViewModelDependency()
        mainFeedsVM = MainFeedsViewModel(dependency: mockTabDependency,
                                         baseDependency: MockBaseFeedsViewModelDependency())
        preloader = FeedPreloaderServiceImpl(mockDependency, mainFeedsVM)
        super.setUp()
    }

    override func tearDown() {
        mockDependency = nil
        preloader = nil
        super.tearDown()
    }

    // MARK: - preload

    /// case 1: 多线程触发，仅调用一次，并触发数据刷新与reload
    func test_preload_1() {
        // 避免relay影响
        mainWait()
        var section = SectionHolder()
        section.type = .ignore
        mainFeedsVM.feedsRelay.accept(section)
        var getFeedCardsTrigger = false

        mockTabDependency.getFeedCardsBuilder = { feedType, pullType, feedCardID, cursor, count -> Observable<GetFeedCardsResult> in
            // 触发一次
            XCTAssert(getFeedCardsTrigger == false)
            getFeedCardsTrigger = true
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

        var bootRequestTrigger = false
        mockDependency.putUserColdBootRequestBuilder = {
            // 触发调用
            XCTAssert(bootRequestTrigger == false)
            bootRequestTrigger = true
        }

        async {
            self.preloader.preload()
        }
        async {
            self.preloader.preload()
        }
        async {
            self.preloader.preload()
        }

        mainWait()

        // 触发数据刷新
        XCTAssert(mainFeedsVM.nextCursor == 10)
        XCTAssert(mainFeedsVM.cursors.count == 1)
        XCTAssert(mainFeedsVM.cursors[0].maxCursor == 1000)
        XCTAssert(mainFeedsVM.cursors[0].minCursor == 10)
        let uiSection = mainFeedsVM.feedsRelay.value
        XCTAssert(uiSection.type == .reload)
        XCTAssert(uiSection.items.count == 1)
        XCTAssert(uiSection.items[0].feedCardPreview.id == "1")
    }
}
