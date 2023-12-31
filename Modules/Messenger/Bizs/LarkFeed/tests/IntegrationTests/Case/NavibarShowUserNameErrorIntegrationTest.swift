//
//  NavibarShowUserNameErrorIntegrationTest.swift
//  LarkFeed-Unit-Tests
//
//  Created by 白镜吾 on 2023/9/18.
//

import XCTest
import UIKit
import RustPB
import RxSwift
import RxRelay
import LarkContainer
import LarkSDKInterface
import LarkAccountInterface
import LarkModel
import LarkOpenFeed
@testable import LarkFeed

// MARK: feed顶部左上角展示的是消息+租户名，切换个人状态后才展示了用户名+租户名
// https://meego.feishu.cn/larksuite/issue/detail/8188819
final class NavibarShowUserNameErrorIntegrationTest: XCTestCase {

    let container = MockAssembly.generateContainer()

    // 构造可能的边界条件
    let feed3BarStyles: [Feed3BarStyle] = Feed3BarStyle.allCases
    let dynamicNetStatuses: [Basic_V1_DynamicNetStatusResponse.NetStatus] = Basic_V1_DynamicNetStatusResponse.NetStatus.allCases
    let isSyncings = [true, false]

    func testFeedLeftTopShowUserNameMsgErrorUnitTest() {
        // 构造初始化参数
        let resolver = container.getCurrentUserResolver().resolver
        guard let pushCenter = try? resolver.userPushCenter else { return }
        guard let chatterManager = try? resolver.resolve(assert: ChatterManagerProtocol.self) else { return }
        guard let context = try? resolver.resolve(assert: FeedContextService.self) else { return }

        let semaphoreWaitForPush = DispatchSemaphore(value: 0)
        let semaphoreWaitForAssert = DispatchSemaphore(value: 0)
        let expect = expectation(description: "global_async_wait")
        expect.expectedFulfillmentCount = 1

        // 校验循环测试，防止发生漏了的情况
        var loopTimes = 0
        DispatchQueue.global().async {
            for style in self.feed3BarStyles {
                for netStatus in self.dynamicNetStatuses {
                    for isSyncing in self.isSyncings {
                        loopTimes += 1
                        let styleService = MockFeed3BarStyleService(style: style)
                        let pushNetStatus = pushCenter.observable(for: PushDynamicNetStatus.self)
                        let pushFeedCardsStatus = pushCenter.observable(for: Feed_V1_PushLoadFeedCardsStatus.self)

                        let naviViewModel = MockFeed.generateFeedNavigationBarViewModel(chatterId: "chatterId",
                                                                                        pushDynamicNetStatus: pushNetStatus,
                                                                                        pushLoadFeedCardsStatus: pushFeedCardsStatus,
                                                                                        chatterManager: chatterManager,
                                                                                        styleService: styleService,
                                                                                        context: context)
                        // 因为 naviViewModel 内部分信号是 Runloop 空闲时才监听，因为异步执行一下
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            let netWorkStatus = PushDynamicNetStatus(dynamicNetStatus: netStatus)
                            pushCenter.post(netWorkStatus)

                            var pushLoadFeedCardsStatus = Feed_V1_PushLoadFeedCardsStatus()
                            pushLoadFeedCardsStatus.feedType = .inbox
                            pushLoadFeedCardsStatus.status = isSyncing ? .start : .finished
                            pushCenter.post(pushLoadFeedCardsStatus)

                            let chatter = MockFeed.generateChatter(id: "chatterId", name: "Name", nameWithAnotherName: "NameWithAnotherName")
                            chatterManager.currentChatter = chatter

                            // 异步等待 Push 均更新完成，随后解锁
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                semaphoreWaitForPush.signal()
                            }
                        }
                        semaphoreWaitForPush.wait()

                        // 校验数据
                        DispatchQueue.main.async {
                            let testText = naviViewModel.titleText.value
                            guard !testText.isEmpty else {
                                semaphoreWaitForAssert.signal()
                                return
                            }
                            var expectedText: String = ""

                            switch netStatus {
                            case .netUnavailable, .serviceUnavailable, .offline:
                                expectedText = BundleI18n.LarkFeed.Lark_Legacy_ChatTableHeaderNotConnected
                                XCTAssertEqual(testText, expectedText)
                            case .excellent, .evaluating, .weak:
                                if isSyncing {
                                    expectedText = BundleI18n.LarkFeed.Lark_Legacy_ChatTableHeaderLoading
                                    XCTAssertEqual(testText, expectedText)
                                } else {
                                    switch style {
                                    case .phone:
                                        expectedText = chatterManager.currentChatter.nameWithAnotherName
                                        XCTAssertEqual(testText, expectedText)
                                    case .padRegular:
                                        let currentTab = context.dataSourceAPI?.currentFilterType ?? .unknown
                                        let currentTabName = FeedFilterTabSourceFactory.source(for: currentTab)?.titleProvider() ?? ""
                                        expectedText = currentTabName
                                        XCTAssertEqual(testText, expectedText)
                                    case .padCompact:
                                        expectedText = chatterManager.currentChatter.nameWithAnotherName
                                        XCTAssertEqual(testText, expectedText)
                                    default: XCTAssertFalse(true)
                                    }
                                }
                            default: XCTAssertFalse(true)
                            }
                            semaphoreWaitForAssert.signal()
                        }
                        semaphoreWaitForAssert.wait()
                    }
                }
            }
            XCTAssertEqual(loopTimes, self.feed3BarStyles.count * self.dynamicNetStatuses.count * self.isSyncings.count)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 200)
    }
}
