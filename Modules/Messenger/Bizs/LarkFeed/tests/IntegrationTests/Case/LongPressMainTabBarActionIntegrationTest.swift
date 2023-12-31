//
//  LongPressMainTabBarActionIntegrationTest.swift
//  LarkFeed-Unit-Tests
//
//  Created by 白镜吾 on 2023/9/12.
//

import XCTest
import LarkModel
import RustPB
import LarkContainer
import RxSwift
import LarkOpenFeed
import LarkSDKInterface
import LarkRustClient
@testable import LarkFeed

// MARK: iOS 端长按导航栏消息，没有清除未读的提示
// https://meego.feishu.cn/larksuite/issue/detail/8401369
// 长按主导航 Tab 的 Action
final class LongPressMainTabBarActionIntegrationTest: XCTestCase {

    let container = MockAssembly.generateContainer()

    let filters = Feed_V1_FeedFilter.TypeEnum.allCases

    var resp: Feed_V1_QueryMuteFeedCardsResponse?

    /// 测试长按主导航 消息分组的事件
    func testLongPressNaviNotShowUnreadDialogOnTab() {
        // 声明是主导航的点击事件，主导航栏上的点击事件由 msgTab 决定
        let isTab = true
        let unReadCounts = [-1, 0, 10]
        let muteUnreadCounts = [-1, 0, 10]
        let msgTabs = [true, false] // 是否是消息 Tab

        for msgTab in msgTabs {
            // 初始化 [清除未读] Settings
            let clearBadgeActionSetting = self.generateFeedGroupActionSetting(feedGroupMap: [:], msgTab: msgTab)
            // 初始化长按事件
            let handler = try? generateFilterActionHandler(muteActionSetting: self.generateFeedGroupActionSetting(),
                                                           clearBadgeActionSetting: clearBadgeActionSetting,
                                                           atAllSetting: self.generateFeedAtAllSetting(),
                                                           displayRuleSetting: self.generateFeedGroupActionSetting())
            guard let clearBadgeHandler = handler else { return }

            for unReadCount in unReadCounts {
                for muteUnreadCount in muteUnreadCounts {
                    let filterModel = PushFeedFilterInfo(type: .message, unread: unReadCount, muteUnread: muteUnreadCount)
                    // [清除未读]与 response 无关，传 nil
                    let actions = clearBadgeHandler.getAllActionTypes(filterModel: filterModel, response: nil, isTab: isTab)
                    let isValidFeed = unReadCount > 0 || muteUnreadCount > 0
                    if isValidFeed && msgTab {
                        XCTAssertTrue(actions.count == 1 && actions.contains(.clearBadge))
                    } else {
                        XCTAssertTrue(actions.isEmpty)
                    }
                }
            }
        }
    }
}

extension LongPressMainTabBarActionIntegrationTest {
    func generateFilterActionHandler(muteActionSetting: FeedSetting.FeedGroupActionSetting,
                                     clearBadgeActionSetting: FeedSetting.FeedGroupActionSetting,
                                     atAllSetting: FeedAtAllSetting,
                                     displayRuleSetting: FeedSetting.FeedGroupActionSetting) throws -> FilterActionHandler {
        let resolver = self.container.getCurrentUserResolver()
        let feedAPI = try resolver.resolve(assert: FeedAPI.self)
        let filterDataStore = try resolver.resolve(assert: FilterDataStore.self)
        let batchClearBadgeService = try resolver.resolve(assert: BatchClearBagdeService.self)
        let batchMuteFeedCardsService = try resolver.resolve(assert: BatchMuteFeedCardsService.self)
        let feedContextService = try resolver.resolve(assert: FeedContextService.self)
        return try FilterActionHandler(userResolver: resolver,
                                       feedContextService: feedContextService,
                                       filterDataStore: filterDataStore,
                                       feedAPI: feedAPI,
                                       batchMuteFeedCardsService: batchMuteFeedCardsService,
                                       batchClearBadgeService: batchClearBadgeService,
                                       muteActionSetting: muteActionSetting,
                                       clearBadgeActionSetting: clearBadgeActionSetting,
                                       atAllSetting: atAllSetting,
                                       displayRuleSetting: displayRuleSetting)

    }

    func generateFeedGroupActionSetting(feedGroupMap: [Feed_V1_FeedFilter.TypeEnum: Bool] = [:],
                                        msgTab: Bool = false,
                                        secondryLabel: Bool = false,
                                        secondryTeam: Bool = false) -> FeedSetting.FeedGroupActionSetting {
        return FeedSetting.FeedGroupActionSetting(groupSetting: FeedGroupSetting(feedGroupMap: feedGroupMap),
                                                  msgTab: msgTab,
                                                  secondryLabel: secondryLabel,
                                                  secondryTeam: secondryTeam)
    }

    func generateFeedAtAllSetting(feedGroupSetting: [Feed_V1_FeedFilter.TypeEnum: Bool] = [:],
                                  timeout: Int = 3,
                                  secondryLabel: Bool = false,
                                  secondryTeam: Bool = false) -> FeedAtAllSetting {
        return FeedAtAllSetting(groupSetting: FeedGroupSetting(feedGroupMap: feedGroupSetting),
                                timeout: timeout,
                                secondryLabel: secondryLabel,
                                secondryTeam: secondryTeam)
    }
}
