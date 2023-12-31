//
//  LongPressTabsActionIntegrationTest.swift
//  LarkFeed-Unit-Tests
//
//  Created by 白镜吾 on 2023/10/24.
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

// MARK: Feed分组批量免打扰setting配置失效
// https://meego.feishu.cn/larksuite/issue/detail/8780659
// 长按分组时的 Action
final class LongPressFiltersActionIntegrationTest: XCTestCase {

    let container = MockAssembly.generateContainer()

    let filters = Feed_V1_FeedFilter.TypeEnum.allCases

    var resp: Feed_V1_QueryMuteFeedCardsResponse?

    // 校验是否包含 [清除未读]
    func testUnreadActionOnFilter() {
        // 声明不是主导航栏的点击事件，分组上的点击事件由对应的 Setting 决定
        let isTab = false
        let unReadCounts = [0, 10]
        let muteUnreadCounts = [0, 10]

        // 初始化 [清除未读] Settings, isTab 为 false, 会走 Setting. 配置为仅在 message, group 下展示未读
        let clearBadgeActionSetting = self.generateFeedGroupActionSetting(feedGroupMap: [.message: true, .group: true])
        // 初始化长按事件
        let handler = try? generateFilterActionHandler(muteActionSetting: self.generateFeedGroupActionSetting(),
                                                       clearBadgeActionSetting: clearBadgeActionSetting,
                                                       atAllSetting: self.generateFeedAtAllSetting(),
                                                       displayRuleSetting: self.generateFeedGroupActionSetting())
        guard let clearBadgeHandler = handler else { return }
        for filter in filters {
            for unReadCount in unReadCounts {
                for muteUnreadCount in muteUnreadCounts {
                    let filterModel = PushFeedFilterInfo(type: filter, unread: unReadCount, muteUnread: muteUnreadCount)
                    // [清除未读]与 response 无关，可以传 nil，考虑到代码覆盖率，额外对网络请求的部分，进行判断
                    let actions = clearBadgeHandler.getAllActionTypes(filterModel: filterModel, response: nil, isTab: isTab)
                    let isValidFeed = unReadCount > 0 || muteUnreadCount > 0
                    if isValidFeed && (filter == .message || filter == .group) {
                        XCTAssertTrue(actions.count == 1 && actions.contains(.clearBadge))
                    } else {
                        XCTAssertTrue(actions.isEmpty)
                    }
                }
            }
        }
    }

    // 校验是否包含 [免打扰]
    func testMuteActionOnFilter() {
        // 声明不是主导航栏的点击事件，主导航栏上的点击事件由 msgTab 决定，分组上的点击事件由对应的 Setting 决定
        let isTab = false
        let feedCounts: [Int32] = [0, 10]
        let hasUnmuteFeeds_ps = [true, false]

        // 初始化 [免打扰] Settings, isTab 为 false, 会走 Setting. 配置为仅在 message, group 下展示免打扰
        let muteActionSetting = self.generateFeedGroupActionSetting(feedGroupMap: [.message: true, .group: true])
        // 初始化长按事件
        let handler = try? generateFilterActionHandler(muteActionSetting: muteActionSetting,
                                                       clearBadgeActionSetting: self.generateFeedGroupActionSetting(),
                                                       atAllSetting: self.generateFeedAtAllSetting(),
                                                       displayRuleSetting: self.generateFeedGroupActionSetting())
        guard let muteHandler = handler else { return }

        for filter in filters {
            for feedCount in feedCounts {
                for hasUnmuteFeeds_p in hasUnmuteFeeds_ps {
                    // 免打扰仅与 feedCount 和 hasUnmuteFeeds_p 相关
                    let filterModel = PushFeedFilterInfo(type: filter, unread: 10, muteUnread: 5)
                    let preCheckActions = muteHandler.preCheck(filterType: filterModel.type, isTab: isTab)
                    if preCheckActions.isEmpty {
                        resp = nil
                    } else {
                        resp = Feed_V1_QueryMuteFeedCardsResponse()
                        resp?.feedCount = feedCount
                        resp?.hasUnmuteFeeds_p = hasUnmuteFeeds_p
                    }
                    let actions = muteHandler.getAllActionTypes(filterModel: filterModel, response: resp, isTab: isTab)
                    let isShowMute = feedCount > 0
                    if isShowMute && (filter == .message || filter == .group) {
                        if hasUnmuteFeeds_p {
                            XCTAssertTrue(actions.count == 1 && actions.contains(.mute(.on)))
                        } else {
                            XCTAssertTrue(actions.count == 1 && actions.contains(.mute(.off)))
                        }
                    } else {
                        XCTAssertTrue(actions.isEmpty)
                    }
                }
            }
        }
    }

    // 校验是否包含 [@所有人的消息提示]
    func testAtAllActionOnFilter() {
        // 声明不是主导航栏的点击事件，主导航栏上的点击事件由 msgTab 决定，分组上的点击事件由对应的 Setting 决定
        let isTab = false
        let muteAtAllTypes = Feed_V1_QueryMuteFeedCardsResponse.MuteAtAllDisplayType.allCases

        // 初始化 [@所有人的消息提示] Settings, 配置为仅在 message, group 下展示免打扰
        let atAllactionSetting = self.generateFeedAtAllSetting(feedGroupSetting: [.message: true, .group: true])
        // 初始化长按事件
        let handler = try? generateFilterActionHandler(muteActionSetting: self.generateFeedGroupActionSetting(),
                                                       clearBadgeActionSetting: self.generateFeedGroupActionSetting(),
                                                       atAllSetting: atAllactionSetting,
                                                       displayRuleSetting: self.generateFeedGroupActionSetting())
        guard let atAllHandler = handler else { return }

        for filter in filters {
            for muteAtAllType in muteAtAllTypes {
                // at 信息仅与 muteAtAllType 及 分组类型相关
                let filterModel = PushFeedFilterInfo(type: filter, unread: 10, muteUnread: 5)
                let preCheckActions = atAllHandler.preCheck(filterType: filterModel.type, isTab: isTab)
                if preCheckActions.isEmpty {
                    resp = nil
                } else {
                    resp = Feed_V1_QueryMuteFeedCardsResponse()
                    resp?.muteAtAllType = muteAtAllType
                }
                let actions = atAllHandler.getAllActionTypes(filterModel: filterModel, response: resp, isTab: isTab)

                if filter == .message || filter == .group {
                    switch muteAtAllType {
                    case .unknown, .shouldNotDisplay:
                        XCTAssertTrue(actions.isEmpty)
                    case .displayMuteAtAll:
                        XCTAssertTrue(actions.count == 1 && actions.contains(.atAll(.on)))
                    case .displayRemindAtAll:
                        XCTAssertTrue(actions.count == 1 && actions.contains(.atAll(.off)))
                    @unknown default:
                        XCTAssertTrue(actions.isEmpty)
                    }
                } else {
                    XCTAssertTrue(actions.isEmpty)
                }
            }
        }
    }

    // 校验是否包含 [消息展示设置]
    func testMsgDisplayActionOnFilter() {
        // 声明不是主导航栏的点击事件，主导航栏上的点击事件由 msgTab 决定，分组上的点击事件由对应的 Setting 决定
        let isTab = false

        // 初始化 [消息展示设置] Settings, 1. 一级团队和标签分组默认不展示入口, 2. 如何不是1，则根据 setting 内的配置来，结合 分组设置（已全量）、分组设置优化（已全量）两个 FG
        let msgDisplayActionSetting = self.generateFeedGroupActionSetting(feedGroupMap: [.message: true, .group: true])
        // 初始化长按事件
        let handler = try? generateFilterActionHandler(muteActionSetting: self.generateFeedGroupActionSetting(),
                                                       clearBadgeActionSetting: self.generateFeedGroupActionSetting(),
                                                       atAllSetting: self.generateFeedAtAllSetting(),
                                                       displayRuleSetting: msgDisplayActionSetting)
        guard let msgDisplayHandler = handler else { return }

        for filter in filters {
            let filterModel = PushFeedFilterInfo(type: filter, unread: 10, muteUnread: 5)
            resp = Feed_V1_QueryMuteFeedCardsResponse()
            let actions = msgDisplayHandler.getAllActionTypes(filterModel: filterModel, response: resp, isTab: isTab)
            if filter == .message || filter == .group {
                XCTAssertTrue(actions.count == 1 && actions.contains(.displayRule))
            } else {
                XCTAssertTrue(actions.isEmpty)
            }
        }
    }
}

extension LongPressFiltersActionIntegrationTest {
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
