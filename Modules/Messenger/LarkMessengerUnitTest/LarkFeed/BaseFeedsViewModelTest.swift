//
//  BaseFeedsViewModelTest.swift
//  LarkMessengerUnitTest
//
//  Created by 袁平 on 2020/8/24.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import XCTest
import RustPB
import RxSwift
import LarkSDKInterface
import RunloopTools
import LarkFeatureSwitch
import LarkFeatureGating
import LarkModel
@testable import LarkFeed

// 部分依赖于继承实现的方法，需要放到各继承的class中处理
class BaseFeedsViewModelTest: XCTestCase {
    var baseFeedsVM: BaseFeedsViewModel!
    private var dependency: MockBaseFeedsViewModelDependency!

    override class func setUp() {
        FeedSupplement.shared.registerTableViewCellAndViewModel(.chat, BaseFeedTableCell.self) { (feed, type) -> BaseFeedTableCellViewModel? in
            BaseFeedTableCellViewModel(feedCardPreview: feed, bizType: type)
        }

        RunloopDispatcher.enable = true
        // 开启全量日志FG
        LarkFeatureGating.shared.updateFeatureBoolValue(for: "lark.feedrefactor.all.log", value: true)
    }

    override func setUp() {
        super.setUp()
        dependency = MockBaseFeedsViewModelDependency()
        let pushFeedPreview = PushFeedPreview(updatePreviews: [],
                                              removePreviews: [],
                                              unreadCount: 0,
                                              filteredUnreadCount: 0,
                                              filteredMuteUnreadCount: 0,
                                              delayedChannelCount: 0)
        let pushThreadAvatar = PushThreadFeedAvatarChanges(avatars: [:])
        baseFeedsVM = BaseFeedsViewModel(baseDependency: dependency,
                                         feedPreviewPush: .just(pushFeedPreview),
                                         badgeStylePush: .just(.strongRemind),
                                         threadFeedAvatarChangesPush: .just(pushThreadAvatar),
                                         is24HourTime: .init(value: true))
    }

    override func tearDown() {
        baseFeedsVM = nil
        dependency = nil
        super.tearDown()
    }

    // MARK: - changeQueueState: 队列加锁/解锁

    /// case 1: 加锁/解锁正常
    func test_changeQueueState() {
        baseFeedsVM.changeQueueState(true)
        XCTAssert(baseFeedsVM.isQueueSuspended() == true)
        baseFeedsVM.changeQueueState(false)
        XCTAssert(baseFeedsVM.isQueueSuspended() == false)
    }

    /// case 2: 多线程加锁
    func test_changeQueueState_true_async() {
        self.baseFeedsVM.changeQueueState(false)
        let expect = expectation(description: "changeQueueState")
        expect.expectedFulfillmentCount = 2
        async {
            self.baseFeedsVM.changeQueueState(true)
            expect.fulfill()
        }
        async {
            self.baseFeedsVM.changeQueueState(true)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1)
        // 多线程加锁成功
        XCTAssert(baseFeedsVM.isQueueSuspended() == true)
    }

    /// case 3: 多线程解锁
    func test_changeQueueState_false_async() {
        self.baseFeedsVM.changeQueueState(true)
        let expect = expectation(description: "changeQueueState")
        expect.expectedFulfillmentCount = 2
        async {
            self.baseFeedsVM.changeQueueState(false)
            expect.fulfill()
        }
        async {
            self.baseFeedsVM.changeQueueState(false)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1)
        // 多线程解锁成功
        XCTAssert(baseFeedsVM.isQueueSuspended() == false)
    }

    // MARK: - allItems/setItems: 获取/更新UI数据

    /// case 1: 主线程更新/获取正常
    func test_setItems_allItems_mainThread() {
        var section = SectionHolder()
        var feedCard = buildFeedPreview()
        feedCard.id = "123456"
        let cellVM = BaseFeedTableCellViewModel(feedCardPreview: feedCard, bizType: .inbox)
        section.items = [cellVM!]

        mainWait()

        self.baseFeedsVM.setItems([section])
        let items = self.baseFeedsVM.allItems()
        XCTAssert(items.first?.feedCardPreview.id == "123456")
    }

    /// case 2: allItems仅支持单section获取
    func test_allItems_singleSection() {
        var section = SectionHolder()
        var feedCard = buildFeedPreview()
        feedCard.id = "123456"
        let cellVM = BaseFeedTableCellViewModel(feedCardPreview: feedCard, bizType: .inbox)
        section.items = [cellVM!]

        mainWait()

        // 需要先设置section，否则无法区分返回的[]是否正常
        self.baseFeedsVM.setItems([section])
        let items = self.baseFeedsVM.allItems(1)
        XCTAssert(items.isEmpty)
    }

    // MARK: - cellRowHeight: 获取cell高度

    /// case 1: 获取cellRowHeight正常
    func test_cellRowHeight() {
        var section = SectionHolder()
        let feedCard = buildFeedPreview()
        let cellVM = BaseFeedTableCellViewModel(feedCardPreview: feedCard, bizType: .inbox)
        section.items = [cellVM!]

        mainWait()

        self.baseFeedsVM.setItems([section])
        let index = IndexPath(row: 0, section: 0)
        let height = self.baseFeedsVM.cellRowHeight(index)
        XCTAssert(height == 68)
    }

    /// case 2: 数组越界，cellRowHeight返回nil
    func test_cellRowHeight_outOfIndex() {
        var section = SectionHolder()
        let feedCard = buildFeedPreview()
        let cellVM = BaseFeedTableCellViewModel(feedCardPreview: feedCard, bizType: .inbox)
        section.items = [cellVM!]
        self.baseFeedsVM.setItems([section])

        let index1 = IndexPath(row: 1, section: 0)
        let height1 = self.baseFeedsVM.cellRowHeight(index1)
        XCTAssert(height1 == nil)

        let index2 = IndexPath(row: 0, section: 1)
        let height2 = self.baseFeedsVM.cellRowHeight(index2)
        XCTAssert(height2 == nil)
    }

    // MARK: - cellViewModel: 获取cellVM

    /// case 1: 获取cellViewModel正常
    func test_cellViewModel() {
        var section = SectionHolder()
        var feedCard = buildFeedPreview()
        feedCard.id = "123456"
        let cellVM = BaseFeedTableCellViewModel(feedCardPreview: feedCard, bizType: .inbox)
        section.items = [cellVM!]

        mainWait()

        self.baseFeedsVM.setItems([section])
        let index = IndexPath(row: 0, section: 0)
        let vm = self.baseFeedsVM.cellViewModel(index)
        XCTAssert(vm?.feedCardPreview.id == "123456")
    }

    /// case 2: 数组越界，cellViewModel返回nil
    func test_cellViewModel_outOfIndex() {
        var section = SectionHolder()
        var feedCard = buildFeedPreview()
        feedCard.id = "123456"
        let cellVM = BaseFeedTableCellViewModel(feedCardPreview: feedCard, bizType: .inbox)
        section.items = [cellVM!]

        mainWait()

        self.baseFeedsVM.setItems([section])
        let index1 = IndexPath(row: 1, section: 0)
        let vm1 = self.baseFeedsVM.cellViewModel(index1)
        XCTAssert(vm1 == nil)

        let index2 = IndexPath(row: 0, section: 1)
        let vm2 = self.baseFeedsVM.cellViewModel(index2)
        XCTAssert(vm2 == nil)
    }

    // MARK: - handleThreadAvatarChangePush
    // FeedProvider.updateThreadAvatars在FeedProviderTest中有测试，此处不再覆盖

    /// case 1: avatar非空，触发table reload
    func test_handleThreadAvatarChangePush_reload() {
        // 2s后执行，去除relay初始值影响
        asyncAfter(.now() + 2) {
            var section = SectionHolder()
            section.type = .none
            self.baseFeedsVM.feedsRelay.accept(section)
            let avatar = ["1": Feed_V1_PushThreadFeedAvatarChanges.Avatar()]
            self.baseFeedsVM.handleThreadAvatarChangePush(by: avatar)
        }

        mainWait(3)

        XCTAssert(self.baseFeedsVM.feedsRelay.value.type == .reload)
    }

    /// case 2: avatar为空，不触发table reload
    func test_handleThreadAvatarChangePush_empty() {
        // 2s后执行，去除relay初始值影响
        asyncAfter(.now() + 2) {
            var section = SectionHolder()
            section.type = .none
            self.baseFeedsVM.feedsRelay.accept(section)
            self.baseFeedsVM.handleThreadAvatarChangePush(by: [:])
        }

        mainWait(3)

        XCTAssert(self.baseFeedsVM.feedsRelay.value.type == .none)
    }

    // MARK: - handleIs24HourTime

    /// case 1: 触发table reload
    func test_handleIs24HourTime() {
        // 2s后执行，去除relay初始值影响
        asyncAfter(.now() + 2) {
            // 初始值
            var section = SectionHolder()
            section.type = .none
            self.baseFeedsVM.feedsRelay.accept(section)

            self.baseFeedsVM.handleIs24HourTime()
        }

        mainWait(3)

        XCTAssert(self.baseFeedsVM.feedsRelay.value.type == .reload)
    }

    // MARK: - preloadFeedCards

    /// case 1: 预加载Chat和Docs类型，判断类型正确
    func test_preloadFeedCards_1() {
        dependency.preloadFeedCardsBuilder = { ids -> Observable<Void> in
            XCTAssert(ids.count == 1)
            XCTAssert(ids[0] == "Chat_1")
            return .just(())
        }

        dependency.preloadDocFeedBuilder = { url -> Void in
            XCTAssert(url == "https://1234")
        }

        var feed1 = buildFeedPreview()
        feed1.id = "Chat_1"
        feed1.type = .chat
        let vm1 = BaseFeedTableCellViewModel(feedCardPreview: feed1, bizType: .inbox)
        var feed2 = buildFeedPreview()
        feed2.id = "Doc_1"
        feed2.type = .docFeed
        feed2.docURL = "https://1234"
        let vm2 = BaseFeedTableCellViewModel(feedCardPreview: feed2, bizType: .inbox)
        var feed3 = buildFeedPreview()
        feed3.id = "thread_1"
        feed3.type = .thread
        let vm3 = BaseFeedTableCellViewModel(feedCardPreview: feed3, bizType: .inbox)
        baseFeedsVM.preloadFeedCards([vm1!, vm2!, vm3!])

        // 等待CPU Free触发
        mainWait()
    }

    // MARK: - preloadChatFeed

    /// 对preloadChatFeed补充测试[]场景，正常触发场景在preloadFeedCards中已测
    /// case 1: ids为[]，不触发接口调用
    func test_preloadChatFeed_1() {
        dependency.preloadFeedCardsBuilder = { ids -> Observable<Void> in
            // 不触发接口调用
            XCTAssert(false)
            return .just(())
        }

        baseFeedsVM.preloadChatFeed([])

        mainWait()
    }

    // MARK: - preloadDocFeed

    /// 对preloadDocFeed补充测试，正常触发场景在preloadFeedCards中已测
    /// case 1: urls为[]，不触发接口调用
    func test_preloadDocFeed_1() {
        dependency.preloadDocFeedBuilder = { url -> Void in
            // 不触发
            XCTAssert(false)
        }
        baseFeedsVM.preloadDocFeed([])

        mainWait()
    }

    /// case 2: 重复url，只触发一次(去重)
    func test_preloadDocFeed_2() {
        var preloaded = [String]()
        dependency.preloadDocFeedBuilder = { url -> Void in
            preloaded.append(url)
        }

        let urls = [
            "https://1",
            "https://2",
            "https://1",
            "https://1",
            "https://3"
        ]
        baseFeedsVM.preloadDocFeed(urls)

        // 等待执行完成
        mainWait()

        XCTAssert(preloaded.count == 3)
        XCTAssert(preloaded.contains("https://1"))
        XCTAssert(preloaded.contains("https://2"))
        XCTAssert(preloaded.contains("https://3"))
    }

    // MARK: - markForDone

    /// case 1: 主动删除该Feed并触发接口调用
    func test_markForDone() {
        // 避免relay初始值影响
        mainWait()
        dependency.moveToDoneBuilder = { feedId, entityType -> Observable<Void> in
            // 参数校验
            XCTAssert(feedId == "1")
            XCTAssert(entityType == .chat)
            return .just(())
        }
        // 初始数据
        var feed = buildFeedPreview()
        feed.id = "1"
        feed.type = .chat
        let vm = BaseFeedTableCellViewModel(feedCardPreview: feed, bizType: .inbox)
        var section = SectionHolder()
        section.items = [vm!]
        baseFeedsVM.feedsRelay.accept(section)
        baseFeedsVM.provider.updateItems([vm!])

        // markForDone
        baseFeedsVM.markForDone(vm!)

        mainWait()

        // 校验
        XCTAssert(baseFeedsVM.feedsRelay.value.items.isEmpty)
        XCTAssert(baseFeedsVM.feedsRelay.value.type == .animate(.fade))
        XCTAssert(baseFeedsVM.provider.getItemsArray().isEmpty)
    }

    // MARK: - markForShortcut

    /// case 1: 调用接口标记/取消置顶
    func test_markForShortcut() {
        // 取消置顶
        var feed1 = buildFeedPreview()
        feed1.isShortcut = true
        feed1.id = "1"
        feed1.type = .chat
        let vm1 = BaseFeedTableCellViewModel(feedCardPreview: feed1, bizType: .inbox)
        dependency.deleteShortcutsBuilder = { shortcuts -> Observable<Void> in
            // 参数校验
            XCTAssert(shortcuts[0].channel.id == "1")
            XCTAssert(shortcuts[0].channel.type == .chat)
            return .just(())
        }

        baseFeedsVM.markForShortcut(vm1!)

        // 等待接口触发调用
        mainWait()

        // 标记置顶
        var feed2 = buildFeedPreview()
        feed2.isShortcut = false
        feed2.id = "2"
        feed2.type = .chat
        let vm2 = BaseFeedTableCellViewModel(feedCardPreview: feed2, bizType: .inbox)
        dependency.createShortcutsBuilder = { shortcuts -> Observable<Void> in
            // 参数校验
            XCTAssert(shortcuts[0].channel.id == "2")
            XCTAssert(shortcuts[0].channel.type == .chat)
            return .just(())
        }

        baseFeedsVM.markForShortcut(vm2!)

        // 等待接口触发调用
        mainWait()
    }

    // MARK: - markForLater

    /// case 1: 标记/取消稍后处理，接口调用
    func test_markForLater() {
        var feed = buildFeedPreview()
        feed.id = "1"
        feed.type = .chat
        feed.isDelayed = true
        let vm = BaseFeedTableCellViewModel(feedCardPreview: feed, bizType: .inbox)

        dependency.markFeedCardBuilder = { id, isDelayed -> Observable<FeedPreview> in
            // 参数校验
            XCTAssert(id == "1")
            XCTAssert(isDelayed == false)
            return .empty()
        }

        baseFeedsVM.markForLater(vm!)

        // 等待接口触发调用
        mainWait()
    }
}

// MARK: - BaseFeedsViewModel+iPadSelection
extension BaseFeedsViewModelTest {
    // MARK: - setSelected
    /// case 1: 设置选中，触发接口调用
    func test_setSelected() {
        dependency.setSelectedBuilder = { feedId in
            XCTAssert(feedId == "1")
        }
        baseFeedsVM.setSelected(feedId: "1")

        mainWait()
    }

    // MARK: - shouldSkip

    /// case 1: feedSelection关闭（默认iPhone测试环境）-> return false
    func test_shouldSkip_1() {
        Feature.applyConfigs[.feedSelection] = .apply(pad: .on, others: .off)
        dependency.getSelectedBuilder = {
            return "1"
        }

        XCTAssert(baseFeedsVM.shouldSkip(feedId: "1", traitCollection: .regular) == false)
    }

    /// case 2: feedSelection打开（默认iPhone测试环境）-> feedId和traitCollection决定
    func test_shouldSkip_2() {
        Feature.applyConfigs[.feedSelection] = .apply(pad: .on, others: .on)

        // feedId匹配，traitCollection = .regular -> return true
        dependency.getSelectedBuilder = {
            return "1"
        }
        XCTAssert(baseFeedsVM.shouldSkip(feedId: "1", traitCollection: .regular) == true)

        // feedId不匹配，traitCollection = .regular -> return false
        dependency.getSelectedBuilder = {
            return "2"
        }
        XCTAssert(baseFeedsVM.shouldSkip(feedId: "1", traitCollection: .regular) == false)

        // feedId匹配，traitCollection = .compact -> return false
        dependency.getSelectedBuilder = {
            return "1"
        }
        XCTAssert(baseFeedsVM.shouldSkip(feedId: "1", traitCollection: .compact) == false)
    }

    // MARK: - findNextSelectFeed

    /// case 1: 输入无效feedId -> return nil
    func test_findNextSelectFeed_1() {
        // 初始数据
        var section = SectionHolder()
        section.type = .reload
        var feed1 = buildFeedPreview()
        feed1.id = "1"
        let vm1 = BaseFeedTableCellViewModel(feedCardPreview: feed1, bizType: .inbox)!
        var feed2 = buildFeedPreview()
        feed2.id = "2"
        let vm2 = BaseFeedTableCellViewModel(feedCardPreview: feed2, bizType: .inbox)!
        var feed3 = buildFeedPreview()
        feed3.id = "3"
        let vm3 = BaseFeedTableCellViewModel(feedCardPreview: feed3, bizType: .inbox)!
        var feed4 = buildFeedPreview()
        feed4.id = "4"
        let vm4 = BaseFeedTableCellViewModel(feedCardPreview: feed4, bizType: .inbox)!
        section.items = [vm1, vm2, vm3, vm4]
        baseFeedsVM.setItems([section])

        let id = baseFeedsVM.findNextSelectFeed(feedId: "5")
        XCTAssert(id == nil)
    }

    /// case 2: 输入有效feedId，匹配到第一条 -> 返回其后第一条非box数据
    func test_findNextSelectFeed_2() {
        // 初始数据
        var section = SectionHolder()
        section.type = .reload
        var feed1 = buildFeedPreview()
        feed1.id = "1"
        let vm1 = BaseFeedTableCellViewModel(feedCardPreview: feed1, bizType: .inbox)!
        var feed2 = buildFeedPreview()
        feed2.id = "2"
        feed2.type = .box
        let vm2 = BaseFeedTableCellViewModel(feedCardPreview: feed2, bizType: .inbox)!
        var feed3 = buildFeedPreview()
        feed3.id = "3"
        let vm3 = BaseFeedTableCellViewModel(feedCardPreview: feed3, bizType: .inbox)!
        var feed4 = buildFeedPreview()
        feed4.id = "4"
        let vm4 = BaseFeedTableCellViewModel(feedCardPreview: feed4, bizType: .inbox)!
        section.items = [vm1, vm2, vm3, vm4]
        baseFeedsVM.setItems([section])

        let id = baseFeedsVM.findNextSelectFeed(feedId: "1")
        XCTAssert(id == "3")
    }

    /// case 2: 输入有效feedId，匹配到最后一条 -> 返回其前第一条非box数据
    func test_findNextSelectFeed_3() {
        // 初始数据
        var section = SectionHolder()
        section.type = .reload
        var feed1 = buildFeedPreview()
        feed1.id = "1"
        let vm1 = BaseFeedTableCellViewModel(feedCardPreview: feed1, bizType: .inbox)!
        var feed2 = buildFeedPreview()
        feed2.id = "2"
        let vm2 = BaseFeedTableCellViewModel(feedCardPreview: feed2, bizType: .inbox)!
        var feed3 = buildFeedPreview()
        feed3.id = "3"
        feed3.type = .box
        let vm3 = BaseFeedTableCellViewModel(feedCardPreview: feed3, bizType: .inbox)!
        var feed4 = buildFeedPreview()
        feed4.id = "4"
        let vm4 = BaseFeedTableCellViewModel(feedCardPreview: feed4, bizType: .inbox)!
        section.items = [vm1, vm2, vm3, vm4]
        baseFeedsVM.setItems([section])

        let id = baseFeedsVM.findNextSelectFeed(feedId: "4")
        XCTAssert(id == "2")
    }
}

// MARK: - BaseFeedsViewModel+iPadKeyBind
extension BaseFeedsViewModelTest {
    // MAKR: - findNextFeedForKeyCommand

    /// case 1: 当前无选中Feed -> return nil
    func test_findNextFeedForKeyCommand_1() {
        // 初始数据
        var section = SectionHolder()
        section.type = .reload
        var feed1 = buildFeedPreview()
        feed1.id = "1"
        let vm1 = BaseFeedTableCellViewModel(feedCardPreview: feed1, bizType: .inbox)!
        var feed2 = buildFeedPreview()
        feed2.id = "2"
        let vm2 = BaseFeedTableCellViewModel(feedCardPreview: feed2, bizType: .inbox)!
        var feed3 = buildFeedPreview()
        feed3.id = "3"
        let vm3 = BaseFeedTableCellViewModel(feedCardPreview: feed3, bizType: .inbox)!
        var feed4 = buildFeedPreview()
        feed4.id = "4"
        let vm4 = BaseFeedTableCellViewModel(feedCardPreview: feed4, bizType: .inbox)!
        section.items = [vm1, vm2, vm3, vm4]
        baseFeedsVM.setItems([section])

        let next = baseFeedsVM.findNextFeedForKeyCommand(arrowUp: true)

        XCTAssert(next == nil)
    }

    /// case 2: 当前有选中Feed，方向向下 -> 返回后一条非box Feed
    func test_findNextFeedForKeyCommand_2() {
        // 初始数据
        // 当前选中非最后一条，返回后一条非box Feed
        var section = SectionHolder()
        section.type = .reload
        var feed1 = buildFeedPreview()
        feed1.id = "1"
        let vm1 = BaseFeedTableCellViewModel(feedCardPreview: feed1, bizType: .inbox)!
        var feed2 = buildFeedPreview()
        feed2.id = "2"
        let vm2 = BaseFeedTableCellViewModel(feedCardPreview: feed2, bizType: .inbox)!
        vm2.selected = true
        var feed3 = buildFeedPreview()
        feed3.id = "3"
        feed3.type = .box
        let vm3 = BaseFeedTableCellViewModel(feedCardPreview: feed3, bizType: .inbox)!
        var feed4 = buildFeedPreview()
        feed4.id = "4"
        let vm4 = BaseFeedTableCellViewModel(feedCardPreview: feed4, bizType: .inbox)!
        section.items = [vm1, vm2, vm3, vm4]
        baseFeedsVM.setItems([section])

        let next1 = baseFeedsVM.findNextFeedForKeyCommand(arrowUp: false)
        XCTAssert(next1?.0 == "4")
        XCTAssert(next1?.1 == 3)

        // 当前选中为最后一条，返回nil
        // 重新构造条件
        vm2.selected = false
        vm4.selected = true
        section.items = [vm1, vm2, vm3, vm4]
        baseFeedsVM.setItems([section])
        let next2 = baseFeedsVM.findNextFeedForKeyCommand(arrowUp: false)
        XCTAssert(next2 == nil)
    }

    /// case 2: 当前有选中Feed，方向向上 -> 返回前一条非box Feed
    func test_findNextFeedForKeyCommand_3() {
        // 初始数据
        // 当前选中非第一条，返回前一条非box Feed
        var section = SectionHolder()
        section.type = .reload
        var feed1 = buildFeedPreview()
        feed1.id = "1"
        let vm1 = BaseFeedTableCellViewModel(feedCardPreview: feed1, bizType: .inbox)!
        var feed2 = buildFeedPreview()
        feed2.id = "2"
        feed2.type = .box
        let vm2 = BaseFeedTableCellViewModel(feedCardPreview: feed2, bizType: .inbox)!
        var feed3 = buildFeedPreview()
        feed3.id = "3"
        let vm3 = BaseFeedTableCellViewModel(feedCardPreview: feed3, bizType: .inbox)!
        vm3.selected = true
        var feed4 = buildFeedPreview()
        feed4.id = "4"
        let vm4 = BaseFeedTableCellViewModel(feedCardPreview: feed4, bizType: .inbox)!
        section.items = [vm1, vm2, vm3, vm4]
        baseFeedsVM.setItems([section])

        let next1 = baseFeedsVM.findNextFeedForKeyCommand(arrowUp: true)
        XCTAssert(next1?.0 == "1")
        XCTAssert(next1?.1 == 0)

        // 当前选中为第一条，返回nil
        // 重新构造条件
        vm1.selected = true
        vm3.selected = false
        section.items = [vm1, vm2, vm3, vm4]
        baseFeedsVM.setItems([section])
        let next2 = baseFeedsVM.findNextFeedForKeyCommand(arrowUp: true)
        XCTAssert(next2 == nil)
    }
}
