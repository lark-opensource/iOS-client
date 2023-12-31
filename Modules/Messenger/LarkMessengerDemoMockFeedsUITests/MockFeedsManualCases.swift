//
//  MockFeedsManualCase.swift
//  LarkMessengerDemoMockFeedsUITests
//
//  Created by bytedance on 2020/5/19.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import XCTest

class MockFeedsManualCases: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    ///
    /// 启动手动test cases
    ///
    /// - Parameters:
    ///   - mockFeedAPIName: MockFeedAPI class name，不需要bundle name
    ///   - maxFeedsLimit: 该API可提供的各类型feeds数量
    ///   - maxShortcutsLimit: 启动时加载的shortcuts总数量，不包括后续操作或PUSH
    ///   - timeout: 手工case待机状态，等待手工操作，避免test case自动退出
    private func launchManualCase(_ mockFeedAPIName: String,
                                  _ maxFeedsLimit: Int,
                                  _ maxShortcutsLimit: Int = 0,
                                  _ timeout: Int = 30 * 60) {
        let app = XCUIApplication()
        // 考虑到app内实现也未扩展传入的参数，故这里就不考虑自由输入，反而限制接口能传入的参数，表述清晰的用途
        app.launchArguments = [mockFeedAPIName, String(maxFeedsLimit), String(maxShortcutsLimit)]
        app.launch()

        // 设置timeout的时间，供手工操作，testcase不自动退出，默认30分钟
        let ret = app.wait(for: XCUIApplication.State.runningBackgroundSuspended, timeout: TimeInterval(timeout))
        print("""
              Manual test case # \(mockFeedAPIName) #
              maxFeedsLimit: \(maxFeedsLimit) maxShortcutsLimit: \(maxShortcutsLimit) ended: \(ret)
              """)
    }

    // MARK: Test cases

    ///
    /// 可以作为首次安装后，启动APP，加载最多7有个Feeds供展示
    ///
    /// 注：因为APP逻辑首次加载10个，这里不足，向上滑动可能会触发“loading more”的菊花一直转
    /// 不是必现，但大概率，加载200个的时候，也可能会出现
    ///
    func testInitialInstallationWithSevenRandomFeeds() throws {
        launchManualCase("InitialInstallationMockFeedAPI", 7)
    }

    ///
    /// 冷启动或首次安装均可，启动APP后，可以加载到最多200个Feeds
    ///
    func testColdBoostWithTwoHundredRandomFeeds() throws {
        launchManualCase("InitialInstallationMockFeedAPI", 200)
    }

    ///
    /// 冷启动加载5个聊天Feeds
    ///
    func testColdBoostWithFiveValidChatFeeds() throws {
        launchManualCase("ChatCellMockFeedAPI", 5)
    }

    ///
    /// 返回200个有效显示的ChatCell
    ///
    /// 注：拉到最后，会触发一个加载完offset的状态问题，加载完第200个后，弹回的位置offset错了，会被tabbar盖住一部分
    /// 需要再上拉一下才能看到第200个完整的cell
    ///
    /// 中间加载时好像有掉帧的现象，而且加载完cells的刷新体验要再观察下
    ///
    func testColdBoostWithTwoHundredValidChatFeeds() throws {
        launchManualCase("ChatCellMockFeedAPI", 200)
    }

    ///
    /// 冷启动加载6个文档Feeds
    ///
    func testColdBoostWithSixValidDocFeeds() throws {
        launchManualCase("DocFeedCellMockFeedAPI", 6)
    }

    ///
    /// 冷启动加载300个文档Feeds
    ///
    func testColdBoostWithThreeHundredValidDocFeeds() throws {
        launchManualCase("DocFeedCellMockFeedAPI", 300)
    }

    ///
    /// 冷启动加载400个Thread feeds
    ///
    func testColdBoostWithFourHundredValidThreadFeeds() throws {
        launchManualCase("ThreadCellMockFeedAPI", 400)
    }

    ///
    /// 加载消息盒子页面（不包含AutoChat相关内容）
    ///
    /// 注：在消息盒子页面内，每次向上拉（假设已经加载完毕到底的状态下），
    /// 都会触发 MockFeedAPIBaseImpl.swift - preloadFeedCards(by:)，为什么呢？
    ///
    func testColdBoostWithEightValidChatFeedsInBox() throws {
        // 1个BoxFeed + 15个属于该Box的Chat feeds
        launchManualCase("BoxCellMockFeedAPI", 16)
    }

    ///
    /// 消息盒子页面的分页加载，有菊花
    ///
    func testColdBoostWithTwoHundredValidChatFeedsInBox() throws {
        launchManualCase("BoxCellMockFeedAPI", 200)
    }

    ///
    /// 冷启动加载500个MiniApp feeds
    ///
    func testColdBoostWithFiveHundredValidOpenappFeeds() throws {
        launchManualCase("OpenappCellMockFeedAPI", 500)
    }

    ///
    /// 冷启动加载9个OpenappChat feeds
    ///
    func testColdBoostWithNineOpenappChatFeeds() throws {
        launchManualCase("OpenappChatCellMockFeedAPI", 9)
    }

    ///
    /// 冷启动加载14个Topic feeds
    ///
    func testColdBoostWithFourteenTopicFeeds() throws {
        launchManualCase("TopicCellMockFeedAPI", 14)
    }

    ///
    /// 每隔15秒就切换左上角的状态，inbox start -> inbox end -> done start -> done end (但是如下所述，Done页面不响应)
    ///
    /// 注：Done页面的顶部navbar是不响应 PushLoadFeedCardsStatus, By Design
    ///
    func testLoadFeedStatusSwitching() throws {
        launchManualCase("LoadFeedStatusSwitchingMockFeedAPI", 7)
    }

    ///
    /// 预加载100个feeds，冷启动20s后触发PushFeedCursor更新top的feed ids，列表应刷新增加10个feeds
    ///
    func testPushFeedCursorUpdate() throws {
        launchManualCase("InboxFeedCursorMockFeedAPI", 150)
    }

    ///
    /// 加载200个置顶按钮
    ///
    func testLoadTwoHundredShortcuts() throws {
        launchManualCase("LoadShortcutsMockFeedAPI", 0, 200)
    }

    ///
    /// 加载10个置顶按钮
    ///
    /// 注：不加载任何feeds，然后展开和收起shortcuts时，"Empty page"的样子比较奇怪 :-)
    ///
    func testLoadTenShortcuts() throws {
        launchManualCase("LoadShortcutsMockFeedAPI", 0, 10)
    }

    ///
    /// 初始加载15个shortcuts，等待20秒之后，会推送1条PushShortcutsResponse，其中包含3个shortcuts
    ///
    func testPushThreeShortcuts() throws {
        launchManualCase("PushShortcutsMockFeedAPI", 0, 15)
    }

    ///
    /// case:
    ///     1. 拖动置顶过程中，删除/更新shortcut
    ///     2. 置顶展开收起过程中，删除/更新shortcut
    ///
    /// 注：现存问题 - 拖动困难
    ///
    func testUpdateShortcuts() throws {
        launchManualCase("UpdateShortcutsMockFeedAPI", 0, 30)
    }

    ///
    /// 测试双击tabbar跳转到下一个未读/稍后处理状态的cell
    ///
    /// 注：发现的问题，当最后一屏的数据存在多个未读/稍后数据时，UI不会发生跳转行为
    ///
    func testDoubleClickTabbar() throws {
        launchManualCase("DoubleClickTabbarMockFeedAPI", 100, 100)
    }

    ///
    /// 接收push推送数据，进行增删改，看看列表是否同步更新变化
    /// 同时测试操作UI时freeze数据：比如上下滑动列表、左右滑动cell，操作完成后刷新列表.
    ///
    func testInboxPushFeedPreview() throws {
        launchManualCase("InboxPushFeedPreviewMockFeedAPI", 100, 100)
    }

    ///
    /// FeedCardPreviewsPushHandler测试
    /// 1. Feed更新：name, time, lastMessage, avatar, badge, readStatus
    /// 2. Feed删除
    /// 3. Badge更新：unreadCount, filteredUnreadCount, filteredMuteUnreadCount
    ///
    func testFeedCardPreviewsPush() throws {
        launchManualCase("PushCardPreviewMockFeedAPI", 100)
    }

    ///
    /// Move To Done 过程中，有Feed更新
    ///
    /// 结论：处在Done编辑态时，若该Feed有更新，不会刷新Feed，Done动画完成之后，该Feed又出来
    ///
    func testMoveToDoneWhenUpdate() throws {
        launchManualCase("MarkDoneWhenUpdateMockFeedAPI", 100)
    }

    ///
    /// Move To Done过程，有Feed删除
    /// 结论：处在Done编辑态时，若该Feed删除，不会立马移除，且会冻结所有Feed
    /// 优化：不冻结其他Feed刷新
    ///
    func testMoveToDoneWhenRemove() {
        launchManualCase("MarkDoneWhenRemoveMockFeedAPI", 100)
    }

    ///
    /// 通过模拟断网模拟添加/删除置顶失败成功：每30s网络状态反转一次，在添加/删除置顶过程中随机更新Feed
    /// 观察Feed左滑的状态以及Toast
    ///
    func testMarkShortcut() throws {
        launchManualCase("MarkShortcutMockFeedAPI", 100)
    }

    ///
    /// 通过模拟断网模拟添加/移除稍后处理失败成功：每30s网络状态反转一次，在添加/移除稍后处理过程中随机更新Feed
    /// 观察Feed左滑的状态以及Toast
    ///
    func testMarkLater() throws {
        launchManualCase("MarkLaterMockFeedAPI", 100)
    }

    ///
    /// 场景描述：
    /// * 启动时，加载feeds 100个，shortcuts 200个
    ///     * 包含会话盒子、自动会话盒子的内容
    /// * 持续行为
    ///     * 操作Feeds列表向上滑动几百个feeds
    ///     * 操作Feeds添加新的shortcuts，以及删除原有shortcuts
    ///     * 操作过滤器切换不同的feed类型
    ///     * 进入消息盒子，向上滑动几百个feeds
    ///     * 进入自动消息盒子，浏览全部内容（这个应该是不支持分页加载的）
    ///     * 进入稍后处理，向上滑动几百个feeds
    ///     * 在消息盒子、主Feed列表中，操作标记完成（取消）、稍后处理（取消）、置顶（取消）几十个feeds
    /// * 在上述持续行为发生时
    ///     * 后台触发当前页面内feeds内容数据的刷新
    ///     * 触发当前页面外不同feeds内容数据的刷新
    ///         * 含置顶内容、feeds列表已有内容、推送新feeds
    ///
    /// 结论：
    /// * 尚未定位原因：切换到subFilter中Feed为空时，上滑会触发菊花，且不会消失；用真实数据无此现象
    /// * 增删一个置顶时，置顶数据会全量push，当置顶数据很多时，置顶刷新缓慢；且手动展开首期置顶，动画延迟明显
    ///
    func testUltimateScenario() throws {
        launchManualCase("UltimateScenarioMockFeedAPI", 20_000, 200)
    }

    ///
    /// 查看和设置 filter 列表中【已完成】(done)的未读个数
    ///
    func testComputeDoneUnreadBadge() throws {
        launchManualCase("ComputeDoneUnreadBadgeMockFeedAPI", 0, 10)
    }

    ///
    /// 在稍后处理页面，获取列表数据
    ///
    /// 注： 发现一种情况，直接push消息不会触发显示稍后处理按钮的逻辑，延迟发送消息会触发
    ///
    func testGetDelayedFeedCards() throws {
        launchManualCase("GetDelayedFeedCardsMockAPI", 0, 10)
    }
}
