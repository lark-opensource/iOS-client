//
//  ShortcutsViewModelTest.swift
//  LarkMessengerUnitTest
//
//  Created by 夏汝震 on 2020/8/25.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import XCTest
import RxSwift
import RxCocoa
import RustPB
import LarkModel
import LarkFeatureGating
import LarkAccountInterface
import RunloopTools
@testable import LarkFeed
@testable import LarkSDKInterface

// 前置条件：宽度 + 数据 + 展开收起状态
// 重要的输出测试：集合个数，数据详情，高度，display，expand，reloadCommand，expandtype
class ShortcutsViewModelTest: XCTestCase {

    private var disposeBag: DisposeBag!
    private var dependency: Dependency!
    private var shortViewModel: ShortcutsViewModel!

    private let timeout = 1 as TimeInterval // 在主线程等待执行异步任务完成的时间

    private let viewWidth = 414 as CGFloat // 默认设备宽度
    private let maxCountInLineFromViewWidth = 6 // 在上面手机宽度的前提下，默认的一行最大个数

    private let OneLineDataCount = 6 // 单行个数
    private static let OneLineHeight = 95 as CGFloat// 单行高度
    private let TwoLineDataCount = 11 // 两行个数
    private static let TwoLineHeight = 183 as CGFloat // 两行高度
    private let ThreeLineDataCount = 17 // 三行个数
    private static let ThreeLineHeight = 271 as CGFloat // 三行高度

    override class func setUp() {
        RunloopDispatcher.enable = true // 打开RunloopTool

        // 打开所用到的FG
        MockAccountService.login()
        LarkFeatureGating.shared.loadFeatureValues(with: AccountServiceAdapter.shared.currentChatterId)
        LarkFeatureGating.shared.updateFeatureBoolValue(for: FeatureGatingKey.feedCacheEnabled, value: true)
        LarkFeatureGating.shared.updateFeatureBoolValue(for: FeatureGatingKey.shortcutDiffEnabled, value: true)
        LarkFeatureGating.shared.updateFeatureBoolValue(for: FeatureGatingKey.partialSortEnabled, value: true)
    }

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
        dependency = Dependency()
        shortViewModel = ShortcutsViewModel(dependency: dependency)
        shortViewModel.containerWidth = viewWidth
    }

    override func tearDown() {
        disposeBag = nil
        dependency = nil
        shortViewModel = nil
        super.tearDown()
    }
}

// MARK: 从shortcut自身获取数据
extension ShortcutsViewModelTest {
    // MARK: 对通过pull接口获取的数据进行处理
    // 前置条件：数据集合 + 数据来源方式

    /* case1: 前一个环境为无数据，发送1行数据
     input: 发送1行数据
     */

    func test_handleDataFromShortcut_load1() {
        let count = OneLineDataCount
        let list = creatModels(count)
        shortViewModel.handleDataFromShortcut(list, source: ShortcutUpdateSource.load)
        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)
    }

    /* case2: 前一个环境为无数据，发送2行数据
     input: 发送2行数据
     */
    func test_handleDataFromShortcut_load2() {
        let count = TwoLineDataCount
        let list = creatModels(count)
        shortViewModel.handleDataFromShortcut(list, source: ShortcutUpdateSource.load)
        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)
    }

    /* case3: 前一个环境为单行数据，发送0个数据
     input: 发送0个数据
     */
    func test_handleDataFromShortcut_load3() {
        stuffingDataUntilFinish(count: OneLineDataCount)
        let count = 0
        let list = creatModels(count)
        shortViewModel.handleDataFromShortcut(list, source: ShortcutUpdateSource.load)
        testDataflow(count: count, display: false, expanded: false, height: 0 as CGFloat)
    }

    /* case4: 前一个环境为单行数据，发送1行数据，但是数目不一样
     input: 发送1行数据
     */
    func test_handleDataFromShortcut_load4() {
        stuffingDataUntilFinish(count: OneLineDataCount)
        let count = TwoLineDataCount - 1
        let list = creatModels(count)
        shortViewModel.handleDataFromShortcut(list, source: ShortcutUpdateSource.load)
        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)
    }

    /* case5: 前一个环境为单行数据，发送2行数据
     input: 发送2行数据
     */
    func test_handleDataFromShortcut_load5() {
        stuffingDataUntilFinish(count: OneLineDataCount)
        let count = TwoLineDataCount
        let list = creatModels(count)
        shortViewModel.handleDataFromShortcut(list, source: ShortcutUpdateSource.load)
        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)
    }

    /* case6: 前一个环境为多行数据（2行）且收起时，发送0个数据
     input: 发送0个数据
     */
    func test_handleDataFromShortcut_load6() {
        stuffingDataUntilFinish(count: TwoLineDataCount)
        let count = 0
        let list = creatModels(count)
        shortViewModel.handleDataFromShortcut(list, source: ShortcutUpdateSource.load)
        testDataflow(count: count, display: false, expanded: false, height: 0 as CGFloat)
    }

    /* case7: 前一个环境为多行数据（2行）且收起时，发送2行数据，但是数目不一样
     input: 发送2行数据
     */
    func test_handleDataFromShortcut_load7() {
        stuffingDataUntilFinish(count: TwoLineDataCount)
        let count = TwoLineDataCount - 1
        let list = creatModels(count)
        shortViewModel.handleDataFromShortcut(list, source: ShortcutUpdateSource.load)
        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)
    }

    /* case8: 前一个环境为多行数据（2行）且收起时，发送3行数据
     input: 发送3行数据
     */
    func test_handleDataFromShortcut_load8() {
        stuffingDataUntilFinish(count: TwoLineDataCount)
        let count = ThreeLineDataCount
        let list = creatModels(count)
        shortViewModel.handleDataFromShortcut(list, source: ShortcutUpdateSource.load)
        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)
    }

    /* case9: 前一个环境为多行数据（2行）且展开时，发送0个数据
     input: 发送0个数据
     */
    func test_handleDataFromShortcut_load9() {
        stuffingDataUntilFinish(count: TwoLineDataCount)
        let count = 0
        let list = creatModels(count)
        shortViewModel.handleDataFromShortcut(list, source: ShortcutUpdateSource.load)
        testDataflow(count: count, display: false, expanded: false, height: 0 as CGFloat)
    }

    /* case10: 前一个环境为多行数据（2行）且展开时，发送1行数据
     input: 发送1行数据
     */
    func test_handleDataFromShortcut_load10() {
        stuffingDataUntilFinish(count: TwoLineDataCount)
        shortViewModel.toggleExpandedAndCollapse()
        let count = OneLineDataCount
        let list = creatModels(count)
        shortViewModel.handleDataFromShortcut(list, source: ShortcutUpdateSource.load)
        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)
    }

    /* case11: 前一个环境为多行数据（2行）且展开时，发送2行数据
     input: 发送2行数据
     */
    func test_handleDataFromShortcut_load11() {
        stuffingDataUntilFinish(count: TwoLineDataCount)
        shortViewModel.toggleExpandedAndCollapse()
        let count = TwoLineDataCount - 1
        let list = creatModels(count)
        shortViewModel.handleDataFromShortcut(list, source: ShortcutUpdateSource.load)
        testDataflow(count: count, display: true, expanded: true, height: Self.TwoLineHeight)
    }

    /* case12: 前一个环境为多行数据（2行）且展开时，发送3行数据
     input: 发送3行数据
     */
    func test_handleDataFromShortcut_load12() {
        stuffingDataUntilFinish(count: TwoLineDataCount)
        shortViewModel.toggleExpandedAndCollapse()
        let count = ThreeLineDataCount
        let list = creatModels(count)
        shortViewModel.handleDataFromShortcut(list, source: ShortcutUpdateSource.load)
        testDataflow(count: count, display: true, expanded: true, height: Self.ThreeLineHeight)
    }

    // MARK: 对通过push接口获取的数据进行处理
    // 前置条件：数据集合 + 数据来源方式

    /* case1: 前一个环境为无数据，发送1行数据
     input: 发送1行数据
     */
    func test_handleDataFromShortcut_push1() {
        let count = OneLineDataCount
        let list = creatModels(count)
        shortViewModel.handleDataFromShortcut(list, source: ShortcutUpdateSource.push)
        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)
    }

    /* case2: 前一个环境为无数据，发送2行数据
     input: 发送2行数据
     */
    func test_handleDataFromShortcut_push2() {
        let count = TwoLineDataCount
        let list = creatModels(count)
        shortViewModel.handleDataFromShortcut(list, source: ShortcutUpdateSource.push)
        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)
    }

    /* case3: 前一个环境为单行数据，发送0个数据
     input: 发送0个数据
     */
    func test_handleDataFromShortcut_push3() {
        stuffingDataUntilFinish(count: OneLineDataCount)
        let count = 0
        let list = creatModels(count)
        shortViewModel.handleDataFromShortcut(list, source: ShortcutUpdateSource.push)
        testDataflow(count: count, display: false, expanded: false, height: 0 as CGFloat)
    }

    /* case4: 前一个环境为单行数据，发送1行数据，但是数目不一样
     input: 发送1行数据
     */
    func test_handleDataFromShortcut_push4() {
        stuffingDataUntilFinish(count: OneLineDataCount)
        let count = TwoLineDataCount - 1
        let list = creatModels(count)
        shortViewModel.handleDataFromShortcut(list, source: ShortcutUpdateSource.push)
        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)
    }

    /* case5: 前一个环境为单行数据，发送2行数据
     input: 发送2行数据
     */
    func test_handleDataFromShortcut_push5() {
        stuffingDataUntilFinish(count: OneLineDataCount)
        let count = TwoLineDataCount
        let list = creatModels(count)
        shortViewModel.handleDataFromShortcut(list, source: ShortcutUpdateSource.push)
        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)
    }

    /* case6: 前一个环境为多行数据（2行）且收起时，发送0个数据
     input: 发送0个数据
     */
    func test_handleDataFromShortcut_push6() {
        stuffingDataUntilFinish(count: TwoLineDataCount)
        let count = 0
        let list = creatModels(count)
        shortViewModel.handleDataFromShortcut(list, source: ShortcutUpdateSource.push)
        testDataflow(count: count, display: false, expanded: false, height: 0 as CGFloat)
    }

    /* case7: 前一个环境为多行数据（2行）且收起时，发送2行数据，但是数目不一样
     input: 发送2行数据
     */
    func test_handleDataFromShortcut_push7() {
        stuffingDataUntilFinish(count: TwoLineDataCount)
        let count = TwoLineDataCount - 1
        let list = creatModels(count)
        shortViewModel.handleDataFromShortcut(list, source: ShortcutUpdateSource.push)
        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)
    }

    /* case8: 前一个环境为多行数据（2行）且收起时，发送3行数据
     input: 发送3行数据
     */
    func test_handleDataFromShortcut_push8() {
        stuffingDataUntilFinish(count: TwoLineDataCount)
        let count = ThreeLineDataCount
        let list = creatModels(count)
        shortViewModel.handleDataFromShortcut(list, source: ShortcutUpdateSource.push)
        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)
    }

    /* case9: 前一个环境为多行数据（2行）且展开时，发送0个数据
     input: 发送0个数据
     */
    func test_handleDataFromShortcut_push9() {
        stuffingDataUntilFinish(count: TwoLineDataCount)
        let count = 0
        let list = creatModels(count)
        shortViewModel.handleDataFromShortcut(list, source: ShortcutUpdateSource.push)
        testDataflow(count: count, display: false, expanded: false, height: 0 as CGFloat)
    }

    /* case10: 前一个环境为多行数据（2行）且展开时，发送1行数据
     input: 发送1行数据
     */
    func test_handleDataFromShortcut_push10() {
        stuffingDataUntilFinish(count: TwoLineDataCount)
        shortViewModel.toggleExpandedAndCollapse()
        let count = OneLineDataCount
        let list = creatModels(count)
        shortViewModel.handleDataFromShortcut(list, source: ShortcutUpdateSource.push)
        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)
    }

    /* case11: 前一个环境为多行数据（2行）且展开时，发送2行数据
     input: 发送2行数据
     */
    func test_handleDataFromShortcut_push11() {
        stuffingDataUntilFinish(count: TwoLineDataCount)
        shortViewModel.toggleExpandedAndCollapse()
        let count = TwoLineDataCount - 1
        let list = creatModels(count)
        shortViewModel.handleDataFromShortcut(list, source: ShortcutUpdateSource.push)
        testDataflow(count: count, display: true, expanded: true, height: Self.TwoLineHeight)
    }

    /* case12: 前一个环境为多行数据（2行）且展开时，发送3行数据
     input: 发送3行数据
     */
    func test_handleDataFromShortcut_push12() {
        stuffingDataUntilFinish(count: TwoLineDataCount)
        shortViewModel.toggleExpandedAndCollapse()
        let count = ThreeLineDataCount
        let list = creatModels(count)
        shortViewModel.handleDataFromShortcut(list, source: ShortcutUpdateSource.push)
        testDataflow(count: count, display: true, expanded: true, height: Self.ThreeLineHeight)
    }

    // MARK: 从feed主列表获取数据

    // case1: 测试当shortcut自身有数据且收到feed数据命中的情况
    func test_handleDataFromFeed_1() {
        let count = OneLineDataCount
        let list = creatModels(count)
        shortViewModel.handleDataFromShortcut(list, source: ShortcutUpdateSource.load)
        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)

        var feed = feedPreview
        let id = "0"
        let name = "I update name"
        feed.id = id
        feed.name = name
        shortViewModel.handleDataFromFeed([feed])
        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)

        if case .partial(let changeset) = shortViewModel.update.viewReloadCommand {
            XCTAssert(changeset.reload.count == 1)
            XCTAssert(changeset.reload[0].item == 0)
            XCTAssert(shortViewModel.dataSource.first!.preview.name == name)
            XCTAssert(changeset.delete.isEmpty)
            XCTAssert(changeset.insert.isEmpty)
            XCTAssert(true)
        } else {
            XCTAssert(false)
        }
    }

    // case2: 测试当shortcut自身没数据且收到feed数据的情况
    func test_handleDataFromFeed_2() {
        let count = 0
        var feed = feedPreview
        let id = "0"
        let name = "I update name"
        feed.id = id
        feed.name = name
        shortViewModel.handleDataFromFeed([feed])

        testDataflow(count: count, display: false, expanded: false, height: 0 as CGFloat)
        if case .skipped = shortViewModel.update.viewReloadCommand {
            XCTAssert(true)
        } else {
            XCTAssert(false)
        }
    }

    /* case3: 测试当shortcut有数据，并且feed没有命中
     */
    func test_handleDataFromFeed_3() {

        let count = OneLineDataCount
        let list = creatModels(count)
        shortViewModel.handleDataFromShortcut(list, source: ShortcutUpdateSource.load)
        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)

        var feed = feedPreview
        let id = "10000"
        feed.id = id
        shortViewModel.handleDataFromFeed([feed])
        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)
        XCTAssert(shortViewModel.update.snapshot.filter({ $0.id == id }).isEmpty)
        if case .skipped = shortViewModel.update.viewReloadCommand {
            XCTAssert(true)
        } else {
            XCTAssert(false)
        }
    }

    // MARK: 当收到Badge信号时，需要强刷一次
    func test_handleBadgeStylePush() {
        shortViewModel.handleBadgeStylePush(style: .weakRemind)
        XCTAssert(BaseFeedsViewModel.badgeStyle == .weakRemind)

        shortViewModel.handleBadgeStylePush(style: .strongRemind)
        XCTAssert(BaseFeedsViewModel.badgeStyle == .strongRemind)
    }
}

extension ShortcutsViewModelTest {

    // MARK: 创建全量刷新的容器
    // 前置条件： 展开/收起状态
    // case1: 收起时发送1行数据
    func test_refreshInMainThread_full_1() {
        let count = OneLineDataCount
        let list = creatCellViewModels(count)
        let update = ShortcutViewModelUpdate.full(list)
        shortViewModel.refreshInMainThread(update)
        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)
        if case .full = shortViewModel.update.viewReloadCommand {
            XCTAssert(true)
        } else {
            XCTAssert(false)
        }
    }

    // case2: 收起时发送2行数据
    func test_refreshInMainThread_full_2() {
        let count = TwoLineDataCount
        let list = creatCellViewModels(count)
        let update = ShortcutViewModelUpdate.full(list)
        shortViewModel.refreshInMainThread(update)
        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)
        if case .full = shortViewModel.update.viewReloadCommand {
            XCTAssert(true)
        } else {
            XCTAssert(false)
        }
    }

    // case3: 展开时，发送1行数据
    func test_refreshInMainThread_full_3() {

        stuffingDataUntilFinish(count: TwoLineDataCount)
        shortViewModel.toggleExpandedAndCollapse()

        let count = OneLineDataCount
        let list = creatCellViewModels(count)
        let update = ShortcutViewModelUpdate.full(list)
        shortViewModel.refreshInMainThread(update)
        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)
        if case .skipped = shortViewModel.update.viewReloadCommand {
            XCTAssert(true)
        } else {
            XCTAssert(false)
        }
    }

    // case4: 展开时发送3行数据
    func test_refreshInMainThread_full_4() {
        stuffingDataUntilFinish(count: TwoLineDataCount)
        shortViewModel.toggleExpandedAndCollapse()

        let count = ThreeLineDataCount
        let list = creatCellViewModels(count)
        let update = ShortcutViewModelUpdate.full(list)
        shortViewModel.refreshInMainThread(update)
        testDataflow(count: count, display: true, expanded: true, height: Self.ThreeLineHeight)
        if case .full = shortViewModel.update.viewReloadCommand {
            XCTAssert(true)
        } else {
            XCTAssert(false)
        }
    }

    // case5: 有数据时，发送0行数据
    func test_refreshInMainThread_full_5() {
        stuffingDataUntilFinish(count: TwoLineDataCount)
        shortViewModel.toggleExpandedAndCollapse()

        let count = 0
        let list = creatCellViewModels(count)
        let update = ShortcutViewModelUpdate.full(list)
        shortViewModel.refreshInMainThread(update)
        testDataflow(count: count, display: false, expanded: false, height: 0 as CGFloat)
        if case .skipped = shortViewModel.update.viewReloadCommand {
            // 这里是不是用full更好一些
            XCTAssert(true)
        } else {
            XCTAssert(false)
        }
    }

    // MARK: 创建包含最新快照但不触发刷新的容器
    func test_refreshInMainThread_skipped() {
        let count = OneLineDataCount
        let list = creatCellViewModels(count)
        let update = ShortcutViewModelUpdate.full(list)
        shortViewModel.refreshInMainThread(update)

        let shortcut = list.first!
        var list1 = list
        list1.remove(at: 0)
        list1.insert(shortcut, at: list.count - 1)

        let update1 = ShortcutViewModelUpdate.skipped(list1)
        shortViewModel.refreshInMainThread(update1)
        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)
        XCTAssert(shortViewModel.update.snapshot.first!.id == list[1].id)
        XCTAssert(shortViewModel.update.snapshot.last!.id == list.first!.id)
        if case .skipped = shortViewModel.update.viewReloadCommand {
            XCTAssert(true)
        } else {
            XCTAssert(false)
        }
    }

    // MARK: 创建自动计算diff的容器
    // case1: 测试 局部 reload
    func test_refreshInMainThread_autoDiffing_1() {

        let count = OneLineDataCount

        let list = creatModels(count)
        var listCellVM = list.map({ ShortcutBaseCellViewModel(result: $0) })
        let update = ShortcutViewModelUpdate.full(listCellVM)
        shortViewModel.refreshInMainThread(update)

        var preview = list[0].preview
        preview.name = "i'm 0"
        var preview2 = list[2].preview
        preview2.name = "i'm 2"

        let shortcut = ShortcutResult(shortcut: list[0].shortcut, preview: preview)
        let shortcut2 = ShortcutResult(shortcut: list[2].shortcut, preview: preview2)

        let reload = [shortcut, shortcut2]
        let listCellVM1 = reload.map({ ShortcutBaseCellViewModel(result: $0) })
        listCellVM[0] = listCellVM1[0]
        listCellVM[2] = listCellVM1[1]
        let update1 = ShortcutViewModelUpdate.autoDiffing(listCellVM)
        shortViewModel.refreshInMainThread(update1)

        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)
        if case .partial(let changeset) = shortViewModel.update.viewReloadCommand {
            XCTAssert(shortViewModel.update.snapshot.count == list.count)
            XCTAssert(shortViewModel.update.snapshot[0].id == preview.id)
            XCTAssert(shortViewModel.update.snapshot[2].id == preview2.id)
            XCTAssert(shortViewModel.update.snapshot[0].name == "i'm 0")
            XCTAssert(shortViewModel.update.snapshot[2].name == "i'm 2")

            XCTAssert(changeset.reload[0].item == 0)
            XCTAssert(changeset.reload[1].item == 2)
            XCTAssert(changeset.insert.isEmpty)
            XCTAssert(changeset.delete.isEmpty)
        } else {
            XCTAssert(false)
        }
    }

    // case2: 测试 inset
    func test_refreshInMainThread_autoDiffing_2() {

        let count = 4
        let list = creatCellViewModels(count)
        let pre = [list[0], list[1]]
        let update = ShortcutViewModelUpdate.full(pre)
        shortViewModel.refreshInMainThread(update)
        let update1 = ShortcutViewModelUpdate.autoDiffing(list)
        shortViewModel.refreshInMainThread(update1)

        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)
        if case .partial(let changeset) = shortViewModel.update.viewReloadCommand {
            XCTAssert(shortViewModel.update.snapshot.count == count)
            XCTAssert(changeset.reload.isEmpty)
            XCTAssert(changeset.insert[0].item == 2)
            XCTAssert(changeset.insert[1].item == 3)
            XCTAssert(changeset.delete.isEmpty)
        } else {
            XCTAssert(false)
        }
    }

    // case3: 测试 delete
    func test_refreshInMainThread_autoDiffing_3() {

        var count = 4
        let list = creatCellViewModels(count)
        let update = ShortcutViewModelUpdate.full(list)
        shortViewModel.refreshInMainThread(update)

        // 保留0和3，删除1和2
        let list1 = [list[0], list[3]]
        count = list1.count
        let update1 = ShortcutViewModelUpdate.autoDiffing(list1)
        shortViewModel.refreshInMainThread(update1)
        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)
        if case .partial(let changeset) = shortViewModel.update.viewReloadCommand {
            XCTAssert(shortViewModel.update.snapshot.count == count)
            XCTAssert(changeset.reload.count == 1)
            XCTAssert(changeset.reload.first!.item == 1)
            XCTAssert(changeset.insert.isEmpty)
            XCTAssert(changeset.delete[0].item == 2)
            XCTAssert(changeset.delete[1].item == 3)
        } else {
            XCTAssert(false)
        }
    }

    // case4: 测试 reload + inset
    func test_refreshInMainThread_autoDiffing_4() {

        var count = 4
        let list = creatCellViewModels(count)

        let pre = [list[0], list[2]]
        let update = ShortcutViewModelUpdate.full(pre)
        shortViewModel.refreshInMainThread(update)

        // reload 0
        var preview = feedPreview
        let name = "update"
        preview.name = name
        let reloadObjc = list[0].update(cardPreview: preview)

        // inset 1和3
        let list1 = [reloadObjc, list[1], list[2], list[3]]
        count = list1.count
        let update1 = ShortcutViewModelUpdate.autoDiffing(list1)
        shortViewModel.refreshInMainThread(update1)
        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)
        if case .partial(let changeset) = shortViewModel.update.viewReloadCommand {
            /*diff:
             a: 0 2
             b: 0 1,2,3
             */
            XCTAssert(shortViewModel.update.snapshot.count == count)
            XCTAssert(changeset.reload.count == 2)
            XCTAssert(changeset.reload[0].item == 0)
            XCTAssert(shortViewModel.update.snapshot[0].preview.name == name)
            XCTAssert(shortViewModel.update.snapshot[1].preview.name == list[2].name)
            XCTAssert(changeset.insert.count == 2)
            XCTAssert(changeset.insert[0].item == 2)
            XCTAssert(changeset.insert[1].item == 3)
            XCTAssert(changeset.delete.isEmpty)
        } else {
            XCTAssert(false)
        }
    }

    // case5: 测试 reload+delete
    func test_refreshInMainThread_autoDiffing_5() {

        var count = 4
        let list = creatCellViewModels(count)
        let update = ShortcutViewModelUpdate.full(list)
        shortViewModel.refreshInMainThread(update)

        // reload 0
        var preview = feedPreview
        let name = "update"
        preview.name = name
        let reloadObjc = list[0].update(cardPreview: preview)

        // delete 1
        let last = [reloadObjc, list[1], list[3]]
        count = last.count
        let update1 = ShortcutViewModelUpdate.autoDiffing(last)
        shortViewModel.refreshInMainThread(update1)

        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)
        if case .partial(let changeset) = shortViewModel.update.viewReloadCommand {
            /*
             diff:
             a: 0 1 2 3
             b: 0 1 3
             */
            XCTAssert(shortViewModel.update.snapshot.count == count)
            XCTAssert(changeset.reload.count == 2)
            XCTAssert(changeset.reload[0].item == 0)
            XCTAssert(changeset.reload[1].item == 2)
            XCTAssert(shortViewModel.update.snapshot[0].preview.name == name)
            XCTAssert(changeset.insert.isEmpty)
            XCTAssert(changeset.delete.count == 1)
            XCTAssert(changeset.delete[0].item == 3)
        } else {
            XCTAssert(false)
        }
    }

    // case6: 测试 inset+delete
    func test_refreshInMainThread_autoDiffing_6() {

        var count = 4
        let list = creatCellViewModels(count)
        let update = ShortcutViewModelUpdate.full([list[0], list[1]])
        shortViewModel.refreshInMainThread(update)

        // 增加 2，3 删除 0
        let last = [list[1], list[2], list[3]]
        count = last.count
        let update1 = ShortcutViewModelUpdate.autoDiffing(last)
        shortViewModel.refreshInMainThread(update1)

        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)
        if case .partial(let changeset) = shortViewModel.update.viewReloadCommand {
            /*
             diff:
             a: 0 1
             b: 1 2 3
             */
            XCTAssert(shortViewModel.update.snapshot.count == count)
            XCTAssert(changeset.reload.count == 2)
            XCTAssert(changeset.reload[0].item == 0)
            XCTAssert(changeset.reload[1].item == 1)
            XCTAssert(changeset.insert.count == 1)
            XCTAssert(changeset.insert[0].item == 2)
            XCTAssert(changeset.delete.isEmpty)
        } else {
            XCTAssert(false)
        }
    }

    // MARK: 创建手动指定changeset的容器

    // case1: 测试收到feed数据且命中的情况
    func test_refreshInMainThread_manualDiffing_1() {

        let count = 2
        var list = creatCellViewModels(count)
        let update = ShortcutViewModelUpdate.full(list)
        shortViewModel.refreshInMainThread(update)

        let index = 0
        let shortcutVM = list[index]
        var feed = shortcutVM.preview
        let name = "manualDiffing"
        feed.name = name

        let reloadObjc = shortcutVM.update(cardPreview: feed)
        let changedIndices: [Int] = [index]

        list = [reloadObjc, list[1]]
        // 更新容器构造逻辑
        let changeset = ShortcutViewModelUpdate.Changeset(
            reload: ShortcutViewModelUpdate.convertIntToIndexPath(changedIndices),
            insert: [],
            delete: []
        )
        let update1 = ShortcutViewModelUpdate.manualDiffing(snapshot: list, changeset: changeset)
        shortViewModel.refreshInMainThread(update1)

        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)
        if case .partial(let changeset) = shortViewModel.update.viewReloadCommand {
            XCTAssert(shortViewModel.update.snapshot.count == count)
            XCTAssert(changeset.reload.count == 1)
            XCTAssert(changeset.reload[0].item == index)
            XCTAssert(shortViewModel.update.snapshot[0].preview.name == name)
            XCTAssert(changeset.insert.isEmpty)
            XCTAssert(changeset.delete.isEmpty)
        } else {
            XCTAssert(false)
        }
    }

    // case2: 测试收到feed数据且没有命中的情况
    func test_refreshInMainThread_manualDiffing_2() {

        let count = 2
        let list = creatCellViewModels(count)
        let update = ShortcutViewModelUpdate.full(list)
        shortViewModel.refreshInMainThread(update)

        let changedIndices: [Int] = [Int]()

        // 更新容器构造逻辑
        let changeset = ShortcutViewModelUpdate.Changeset(
            reload: ShortcutViewModelUpdate.convertIntToIndexPath(changedIndices),
            insert: [],
            delete: []
        )
        let update1 = ShortcutViewModelUpdate.manualDiffing(snapshot: list, changeset: changeset)
        shortViewModel.refreshInMainThread(update1)

        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)
        if case .skipped = shortViewModel.update.viewReloadCommand {
            XCTAssert(changeset.reload.isEmpty)
            XCTAssert(changeset.insert.isEmpty)
            XCTAssert(changeset.delete.isEmpty)
        } else {
            XCTAssert(false)
        }
    }

    /// 初始化空容器
    func test_refreshInMainThread_empty() {
        let update = ShortcutViewModelUpdate.empty()
        shortViewModel.refreshInMainThread(update)
        testDataflow(count: 0, display: false, expanded: false, height: 0 as CGFloat)
        if case .skipped = shortViewModel.update.viewReloadCommand {
            XCTAssert(true)
        } else {
            XCTAssert(false)
        }
    }

    /// 判断数据源刷新后置顶是否不再超过一行, 需要自动收起
    func test_shouldAutomaticallyCollapse() {
        // privite 因为权限的缘故所以从privite提到fileprivite
        // let result = shortViewModel.shouldAutomaticallyCollapse(shortcutViewModelUpdate)
    }
}

/// For iPad
extension ShortcutsViewModelTest {
    // 是否需要跳过: 避免重复跳转
    func test_shouldSkip() {
        // 需要依赖UI跳转，暂时无法测试
    }
}

// MARK: 数据获取及处理
extension ShortcutsViewModelTest {

    // MARK: 监听 shortcut pull

    // 拉取数据
    func test_loadFirstPageShortcuts() {

        let count = 8
        let models = creatModels(count)
        dependency.loadShortcutsBuilder = {
            let response = (response: models, contextID: "0")
            return .just(response)
        }

        shortViewModel.loadFirstPageShortcuts()
        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)
    }

    // MARK: 监听 shortcut push
    func test_subscribePushHandlers() {
        let count = 8
        let models = creatModels(count)

        dependency.pushShortcutsBuilder = {
            return .just(PushShortcuts(shortcuts: models))
        }

        let badgeStyle: Settings_V1_BadgeStyle = .weakRemind
        dependency.badgeStyleBuilder = {
            .just(badgeStyle)
        }

        shortViewModel.subscribePushHandlers(pushShortcutsOb: dependency.pushShortcutsOb,
                                   badgeStylePush: dependency.badgeStylePush)

        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)
        XCTAssert(BaseFeedsViewModel.badgeStyle == badgeStyle)
    }

    // MARK: 切换到主线程下执行任务(发送数据流)
    // case1: 在主线程下发送数据流
    func test_fireRefresh_1() {
        let count = OneLineDataCount
        let list = creatCellViewModels(count)
        let update = ShortcutViewModelUpdate.full(list)
        self.shortViewModel.fireRefresh(update)
        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight, isNeedMainWait: false)
        if case .full = shortViewModel.update.viewReloadCommand {
            XCTAssert(true)
        } else {
            XCTAssert(false)
        }
    }

    // case2: 在子线程下发送数据流
    func test_fireRefresh_2() {
        let count = self.OneLineDataCount
        async {
            // 不好测试
            let list = self.creatCellViewModels(count)
            let update = ShortcutViewModelUpdate.full(list)
            self.shortViewModel.fireRefresh(update)
        }
        mainWait()
        self.testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)
        if case .full = self.shortViewModel.update.viewReloadCommand {
            XCTAssert(true)
        } else {
            XCTAssert(false)
        }
    }

    // MARK: 更新ExpandMoreViewModel
    // 前置条件：数据 + 有无提醒badge + 展开/收起状态

    // case1: 1行数据 + 收起状态 + 无提醒badge
    func test_updateExpandMoreViewModel_1() {
        let count = OneLineDataCount
        let list = creatCellViewModels(count)

        shortViewModel.updateExpandMoreViewModel(list, expanded: false)
        testMoreDataflow(display: false, expanded: false, badgeInfo: (.none, .weak))
    }

    // case2: 多行数据 + 收起状态 + 无提醒badge
    func test_updateExpandMoreViewModel_2() {
        // 前置条件
        let count = TwoLineDataCount
        let list = creatCellViewModels(count)
        let expand = false
        shortViewModel.updateExpandMoreViewModel(list, expanded: expand)
        testMoreDataflow(display: true, expanded: false, badgeInfo: (.none, .weak))
    }

    // case3: 多行数据 + 收起状态 + 有提醒
    func test_updateExpandMoreViewModel_3() {
        // 前置条件
        let count = TwoLineDataCount
        var list = creatCellViewModels(count)

        // 加入提醒数据
        let firstFromBehind = list.last!
        var feed1 = firstFromBehind.preview
        feed1.hasAtInfo = true// 关系到是否显示@符号
        feed1.isRemind = true // 关系到是红点还是灰点
        feed1.unreadCount = 10
        let new1 = firstFromBehind.update(cardPreview: feed1)
        list[list.count - 1] = new1

        let secondFromFront = list[list.count - 2]
        var feed = secondFromFront.preview
        feed.hasAtInfo = true
        feed.isRemind = false //
        feed.unreadCount = 10
        let new = secondFromFront.update(cardPreview: feed)
        list[list.count - 2] = new

        let expand = false
        shortViewModel.updateExpandMoreViewModel(list, expanded: expand)
        testMoreDataflow(display: true, expanded: expand)
        XCTAssert(shortViewModel.expandMoreViewModel.badgeInfo.style == .weak)
        var isHasImage = false
        if case .image(let imageSource) = self.shortViewModel.expandMoreViewModel.badgeInfo.type {
            if case .image(_) = imageSource {
                isHasImage = true
            }
        }
        XCTAssert(isHasImage)
    }

    // case4: 多行数据 + 展开状态 + 无提醒
    func test_updateExpandMoreViewModel_4() {
        // 前置条件
        let count = TwoLineDataCount
        let list = creatCellViewModels(count)
        let expand = true
        shortViewModel.updateExpandMoreViewModel(list, expanded: expand)
        testMoreDataflow(display: true, expanded: expand, badgeInfo: (.none, .weak))
    }

    // case5: 多行数据 + 展开状态 + 有提醒
    func test_updateExpandMoreViewModel_5() {
        // 前置条件
        let count = TwoLineDataCount
        var list = creatCellViewModels(count)

        // 加入提醒数据
        let firstFromBehind = list.last!
        var feed = firstFromBehind.preview
        feed.isRemind = true // 关系到是红点还是灰点
        feed.unreadCount = 10
        let new = firstFromBehind.update(cardPreview: feed)
        list[list.count - 1] = new

        let expand = true
        shortViewModel.updateExpandMoreViewModel(list, expanded: expand)

        testMoreDataflow(display: true, expanded: expand)
        XCTAssert(shortViewModel.expandMoreViewModel.badgeInfo.style == .strong)

        if case .label(let badgeLabel) = self.shortViewModel.expandMoreViewModel.badgeInfo.type {
            if case .number(let number) = badgeLabel {
                feed.unreadCount = number
            }
        }
    }
}

// MARK: 展开
extension ShortcutsViewModelTest {

    // MARK: 切换展开/收起状态公用逻辑
    // case1: 展开操作
    func test_toggleExpandedAndCollapse_1() {
        let count = TwoLineDataCount
        stuffingDataUntilFinish(count: count)
        shortViewModel.toggleExpandedAndCollapse()
        testDataflow(count: count, display: true, expanded: true, height: Self.TwoLineHeight)
        if case .full = shortViewModel.update.viewReloadCommand {
            XCTAssert(shortViewModel.update.snapshot.count == count)
        } else {
            XCTAssert(false)
        }
    }

    // case2: 收起操作
    func test_toggleExpandedAndCollapse_2() {
        let count = TwoLineDataCount
        stuffingDataUntilFinish(count: count)
        shortViewModel.toggleExpandedAndCollapse()
        shortViewModel.toggleExpandedAndCollapse()

        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)
        if case .full = shortViewModel.update.viewReloadCommand {
            XCTAssert(shortViewModel.update.snapshot.count == count)
        } else {
            XCTAssert(false)
        }
    }

    // MARK: 向外界发布高度变化的信号
    // 前置条件：收起展开的状态

    // case1: 发送收起状态时的高度
    func test_fireViewHeight_1() {
        let count = OneLineDataCount
        stuffingDataUntilFinish(count: count)
        shortViewModel.fireViewHeight()
        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)
        if case .full = shortViewModel.update.viewReloadCommand {
            XCTAssert(shortViewModel.update.snapshot.count == count)
        } else {
            XCTAssert(false)
        }
    }

    // case2: 发送展开状态时的高度
    func test_fireViewHeight_2() {
        let count = TwoLineDataCount
        stuffingDataUntilFinish(count: count)
        shortViewModel.toggleExpandedAndCollapse()
        shortViewModel.fireViewHeight()
        mainWait()
        testDataflow(count: count, display: true, expanded: true, height: Self.TwoLineHeight)
        if case .full = shortViewModel.update.viewReloadCommand {
            XCTAssert(shortViewModel.update.snapshot.count == count)
        } else {
            XCTAssert(false)
        }
    }

    // MARK: 计算在给定状态下的可见置顶数
    func test_computeVisibleCount() {

        let itemMaxNumber = maxCountInLineFromViewWidth

        var totalCount = 0
        var expanded = false
        var currentCount = ShortcutsViewModel.computeVisibleCount(totalCount, expanded: expanded, itemMaxNumber: itemMaxNumber)
        XCTAssert(currentCount == 0)

        totalCount = OneLineDataCount
        expanded = false
        currentCount = ShortcutsViewModel.computeVisibleCount(totalCount, expanded: expanded, itemMaxNumber: itemMaxNumber)
        XCTAssert(currentCount == OneLineDataCount)

        totalCount = TwoLineDataCount
        expanded = false
        currentCount = ShortcutsViewModel.computeVisibleCount(totalCount, expanded: expanded, itemMaxNumber: itemMaxNumber)
        XCTAssert(currentCount == maxCountInLineFromViewWidth - 1)

        totalCount = 0
        expanded = true
        currentCount = ShortcutsViewModel.computeVisibleCount(totalCount, expanded: expanded, itemMaxNumber: itemMaxNumber)
        XCTAssert(currentCount == 0)

        totalCount = OneLineDataCount
        expanded = true
        currentCount = ShortcutsViewModel.computeVisibleCount(totalCount, expanded: expanded, itemMaxNumber: itemMaxNumber)
        XCTAssert(currentCount == OneLineDataCount)

        totalCount = TwoLineDataCount
        expanded = true
        currentCount = ShortcutsViewModel.computeVisibleCount(totalCount, expanded: expanded, itemMaxNumber: itemMaxNumber)
        XCTAssert(currentCount == TwoLineDataCount)
    }
}

// MARK: 控制冻结
extension ShortcutsViewModelTest {

    // MARK: 数据冻结
    // case1: 测试重复加锁
    func test_freeze_1() {
        // 重复加锁
        shortViewModel.freeze(true)
        shortViewModel.freeze(true)
        XCTAssert(shortViewModel.queue.isSuspended == true)

        shortViewModel.freeze(false)
        XCTAssert(shortViewModel.queue.isSuspended == false)
    }

    // case2: 重复解锁
    func test_freeze_2() {
        shortViewModel.freeze(true)
        XCTAssert(shortViewModel.queue.isSuspended == true)

        shortViewModel.freeze(false)
        shortViewModel.freeze(false)
        XCTAssert(shortViewModel.queue.isSuspended == false)
    }

    // case3: 先解锁再加锁
    func test_freeze_3() {
        shortViewModel.freeze(false)
        XCTAssert(shortViewModel.queue.isSuspended == false)

        shortViewModel.freeze(true)
        XCTAssert(shortViewModel.queue.isSuspended == true)
    }

    // case4: 一个线程加锁，一个线程解锁，测试各自在子线程下能否加解锁成功
    // 这个 case 不合适，因为不涉及多线程，先不移除代码，看看后期有什么好的想法
    func test_freeze_4() {
        /*
        async {
            self.shortViewModel.freeze(true)
            XCTAssert(self.shortViewModel.queue.isSuspended == true)
        }

        async {
            self.shortViewModel.freeze(false)
            XCTAssert(self.shortViewModel.queue.isSuspended == false)
        }
        mainWait()
         */
    }
}

// MARK: layout
extension ShortcutsViewModelTest {

    // MARK: 根据当前机型计算单行最大个数
    // 前置条件：view宽度
    func test_itemMaxNumber() {
        shortViewModel.containerWidth = 0
        XCTAssert(shortViewModel.itemMaxNumber == 0)

        shortViewModel.containerWidth = viewWidth
        XCTAssert(shortViewModel.itemMaxNumber == maxCountInLineFromViewWidth)

        shortViewModel.containerWidth = viewWidth * 2
        XCTAssert(shortViewModel.itemMaxNumber == 13)
    }

    // MARK: cell水平之间的间距
    // 前置条件：view宽度
    func test_itemSpacing() {
        shortViewModel.containerWidth = 0
        XCTAssert(shortViewModel.itemSpacing == 11.0)

        shortViewModel.containerWidth = viewWidth
        XCTAssert(shortViewModel.itemSpacing == CGFloat(17))

        shortViewModel.containerWidth = viewWidth * 2
        XCTAssert(shortViewModel.itemSpacing == CGFloat(14))
    }

    // MARK: 最大高度
    // 前置条件：数据集合的个数 + view宽度

    /* case1: 测试 仅存在1行数据 对最小高度的影响
     input: 存在1行数据
     output: OneLineHeight
     */
    func test_maxHeight_1() {
        stuffingDataUntilFinish(count: OneLineDataCount)
        XCTAssert(shortViewModel.maxHeight == Self.OneLineHeight as CGFloat)
    }

    /* case1: 测试 2行数据 对最小高度的影响
     input: 存在1行数据
     output: 2行数据的高度
     */
    func test_maxHeight_2() {
        stuffingDataUntilFinish(count: TwoLineDataCount)
        XCTAssert(shortViewModel.maxHeight == Self.TwoLineHeight as CGFloat)
    }

    /* case3: 测试 没有数据 对最小高度的影响
     input: 不存在数据
     output: 0
     */
    func test_maxHeight_3() {
        stuffingDataUntilFinish(count: 0)
        XCTAssert(shortViewModel.maxHeight == 0 as CGFloat)
    }

    // MARK: 最小高度
    // 前置条件： 是否有数据

    /* case1: 测试 仅存在1行数据 对最小高度的影响
     input: 存在1行数据
     output: OneLineHeight
     */
    func test_minHeight_2() {
        stuffingDataUntilFinish(count: OneLineDataCount)
        XCTAssert(shortViewModel.minHeight == Self.OneLineHeight as CGFloat)
    }

    /* case2: 测试 多行数据 对最小高度的影响
     input: 存在2行数据
     output: OneLineHeight
     */
    func test_minHeight_3() {
        stuffingDataUntilFinish(count: TwoLineDataCount)
        shortViewModel.toggleExpandedAndCollapse()
        XCTAssert(shortViewModel.minHeight == Self.OneLineHeight as CGFloat)
    }

    /* case3: 测试 没有数据 对最小高度的影响
     input: 不存在数据
     output: 0
     */
    func test_minHeight_1() {
        stuffingDataUntilFinish(count: 0)
        XCTAssert(shortViewModel.minHeight == 0 as CGFloat)
    }
}

// MARK: 移动 self.cell 相关
extension ShortcutsViewModelTest {
    // MARK: 移动置顶位置处理逻辑
    // 前置条件： 有>=2个数的数据 + 拖动的cell的索引和预期位置不能一样

    /* case1: 所有条件都符合
     input: 有>=2个数的数据 + 拖动的cell的索引和预期位置不能一样
     output: 可以移动
     */
    func test_updateItemPosition_1() {
        let count = OneLineDataCount
        stuffingDataUntilFinish()
        let section = 0

        let sourceIndex = 0
        let firstShortcut = shortViewModel.dataSource[sourceIndex]

        let destinationIndex = shortViewModel.dataSource.count - 2
        let lastShortcut = shortViewModel.dataSource[destinationIndex]

        dependency.updateBuilder = { shortcut, newPosition in
            XCTAssert(firstShortcut.shortcut == shortcut)
            XCTAssert(newPosition == destinationIndex)
            return .empty()
        }

        shortViewModel.updateItemPosition(sourceIndexPath: IndexPath(item: sourceIndex, section: section), destinationIndexPath: IndexPath(item: destinationIndex, section: section))
        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)
        if case .skipped = shortViewModel.update.viewReloadCommand {
            XCTAssert(firstShortcut.id == shortViewModel.update.snapshot[destinationIndex].id)
            XCTAssert(lastShortcut.id == shortViewModel.update.snapshot[destinationIndex - 1].id)
        } else {
            XCTAssert(false)
        }
    }

    /* case2: 主要测试 拖动的cell的索引和预期位置一样 对该接口的影响
     input: 有>=2个数的数据 + 拖动的cell的索引和预期位置不能一样
     output: 无法移动
     */
    func test_updateItemPosition_2() {
        let count = OneLineDataCount
        stuffingDataUntilFinish()
        let section = 0
        let index = 0
        let shortcut = shortViewModel.dataSource[index]

        dependency.updateBuilder = { _, _ in
            XCTAssert(false) // 如果回调了就不符合预期
            return .empty()
        }
        shortViewModel.updateItemPosition(sourceIndexPath: IndexPath(item: index, section: section), destinationIndexPath: IndexPath(item: index, section: section))
        testDataflow(count: count, display: true, expanded: false, height: Self.OneLineHeight)
        XCTAssert(shortcut.id == shortViewModel.update.snapshot[index].id)
    }
}

// MARK: Mainfeeds 预加载
extension ShortcutsViewModelTest {

    // MARK: 请求 feed 预加载接口
    // 前置条件： 有多行数据 + 第一次展开

    /* case1: 所有条件都符合
     input: 多行数据(符合条件) + 设置展开态(符合条件)
     output: isFirstExpand = true
     */
    func test_preloadFeeds_1() {
        stuffingDataUntilFinish(count: TwoLineDataCount)
        XCTAssert(shortViewModel.isFirstExpand == false)
        shortViewModel.expanded = true
        shortViewModel.preloadFeedCards()
        XCTAssert(shortViewModel.isFirstExpand == true)
    }

    /* case2: 主要测试 多次展开过 对该接口的影响
     input: 两行数据(符合条件) + 多次设置过展开状态(不符合条件)
     output: isFirstExpand = true
     */
    func test_preloadFeeds_2() {
        stuffingDataUntilFinish(count: TwoLineDataCount)
        XCTAssert(shortViewModel.isFirstExpand == false)
        shortViewModel.expanded = true
        XCTAssert(shortViewModel.isFirstExpand == true)
        shortViewModel.expanded = false
        shortViewModel.expanded = true
        XCTAssert(shortViewModel.isFirstExpand == true)
        shortViewModel.preloadFeedCards()
        XCTAssert(shortViewModel.isFirstExpand == true)
    }
}

// MARK: 与 vc 中的 scroll 滑动相关
extension ShortcutsViewModelTest {

    // MARK: 是否支持吸顶
    // 前置条件：存在多行数据 + 收起态 + scroll偏移量<=0

    /* case1: 所有条件都符合
     input: 多行数据(符合条件) + 收起态(符合条件) + offset<=0(符合条件)
     output: isNeedSnap = true
     */
    func test_isNeedSnap_1() {
        stuffingDataUntilFinish(count: TwoLineDataCount)
        let offsetY = 0 as CGFloat
        let isNeedSnap = shortViewModel.isNeedSnap(offsetY: offsetY)
        XCTAssert(isNeedSnap == true)
    }

    /* case2: 主要测试 无数据 变量对该接口的影响
     input: 无数据(不符合条件) + 收起态 + offset=0(符合条件)
     output: isNeedSnap = false
     */
    func test_isNeedSnap_2() {
        let offsetY = 0 as CGFloat
        let isNeedSnap = shortViewModel.isNeedSnap(offsetY: offsetY)
        XCTAssert(isNeedSnap == false)
    }

    /* case3: 主要测试 仅有单行数据 对该接口的影响
     input: 1行数据(不符合条件) + 收起态 + offset=0(符合条件)
     output: isNeedSnap = false
     */
    func test_isNeedSnap_3() {
        stuffingDataUntilFinish(count: OneLineDataCount)
        let offsetY = 0 as CGFloat
        let isNeedSnap = shortViewModel.isNeedSnap(offsetY: offsetY)
        XCTAssert(isNeedSnap == false)
    }

    /* case4: 主要测试 展开态 对该接口的影响
     input: 多行数据(符合条件) + 展开态(不符合条件) + offset=-1000(符合条件)
     output: isNeedSnap = false
     */
    func test_isNeedSnap_4() {
        stuffingDataUntilFinish(count: TwoLineDataCount)
        shortViewModel.toggleExpandedAndCollapse()
        let offsetY = 0 as CGFloat
        let isNeedSnap = shortViewModel.isNeedSnap(offsetY: offsetY)
        XCTAssert(isNeedSnap == false)
    }

    /* case5: 主要测试 offset 变量对该接口的影响
     input: 多行数据(符合条件) + 收起态(符合条件) + offset=1000(不符合条件)
     output: isNeedSnap = false
     */
    func test_isNeedSnap_5() {
        stuffingDataUntilFinish(count: TwoLineDataCount)
        shortViewModel.toggleExpandedAndCollapse()
        let offsetY = 1000 as CGFloat
        let isNeedSnap = shortViewModel.isNeedSnap(offsetY: offsetY)
        XCTAssert(isNeedSnap == false)
    }

    // MARK: 滑动展开
    // 前置条件：存在多行数据 + 收起态 + scroll偏移量<=-60

    /* case1: 所有条件都符合
     input: 多行数据(符合条件) + 收起态(符合条件) + offset=(-ShortcutLayout.shortcutsLoadingExpansionTrigger - 20)(符合条件)
     output: expanded = true
     */
    func test_expandIfNecessary_1() {
        stuffingDataUntilFinish(count: 100) // 符合条件
        let offsetY = (-ShortcutLayout.shortcutsLoadingExpansionTrigger - 20) as CGFloat // 符合条件
        shortViewModel.expandIfNecessary(offsetY: offsetY)
        XCTAssert(shortViewModel.expanded == true)
    }

    /* case2: 主要测试 无数据 变量对该接口的影响
     input: 无数据(不符合条件) + 收起态 + offset=(-ShortcutLayout.shortcutsLoadingExpansionTrigger - 20)(符合条件)
     output: expanded = false
     */
    func test_expandIfNecessary_2() {
        let offsetY = (-ShortcutLayout.shortcutsLoadingExpansionTrigger - 20) as CGFloat // 符合条件
        shortViewModel.expandIfNecessary(offsetY: offsetY)
        XCTAssert(shortViewModel.expanded == false)
    }

    /* case3: 主要测试 仅有单行数据 对该接口的影响
     input: 仅存在1行数据(不符合条件) + 收起态 + offset=(-ShortcutLayout.shortcutsLoadingExpansionTrigger - 20)(符合条件)
     output: expanded = false
     */
    func test_expandIfNecessary_3() {
        stuffingDataUntilFinish(count: OneLineDataCount) // 不符合条件
        let offsetY = (-ShortcutLayout.shortcutsLoadingExpansionTrigger - 20) as CGFloat // 符合条件
        shortViewModel.expandIfNecessary(offsetY: offsetY)
        XCTAssert(shortViewModel.expanded == false)
    }

    /* case4: 主要测试 展开态 对该接口的影响
     input: 多行数据(符合条件) + 展开态(不符合条件) + offset=-(-ShortcutLayout.shortcutsLoadingExpansionTrigger - 20)(符合条件)
     output: expanded = true
     */
    func test_expandIfNecessary_4() {
        stuffingDataUntilFinish(count: TwoLineDataCount)
        shortViewModel.toggleExpandedAndCollapse()
        let offsetY = (-ShortcutLayout.shortcutsLoadingExpansionTrigger - 20) as CGFloat
        shortViewModel.expandIfNecessary(offsetY: offsetY)
        XCTAssert(shortViewModel.expanded == true)
    }

    /* case5: 主要测试 offset 变量对该接口的影响
     input: 多行数据(符合条件) + 收起态(符合条件) + offset=0(不符合条件)
     output: expanded = false
     */
    func test_expandIfNecessary_5() {
        stuffingDataUntilFinish(count: 100) // 符合条件
        shortViewModel.toggleExpandedAndCollapse() // 不符合条件
        let offsetY = 0 as CGFloat // 符合条件
        shortViewModel.expandIfNecessary(offsetY: offsetY)
        XCTAssert(shortViewModel.expanded == true)
    }

    // MARK: 滑动收起
    // 前置条件：展开态 + (scroll偏移量 >= shortcut view 的 maxY 值)

    /* case1: 所有条件都符合
     input: 多行数据(符合条件) + 收起态(符合条件) + offset(符合条件)
     output: expanded = false
     */
    func test_collapseIfNecessary1() {
        stuffingDataUntilFinish(count: TwoLineDataCount) // 符合条件
        shortViewModel.toggleExpandedAndCollapse() // 符合条件
        let offsetY = 1000 as CGFloat // 符合条件
        let heightAboveShortcut = 500 as CGFloat // 符合条件
        shortViewModel.collapseIfNecessary(offsetY: offsetY, heightAboveShortcut: heightAboveShortcut)
        XCTAssert(shortViewModel.expanded == false)
    }

    /* case2: 主要测试 无数据 变量对该接口的影响
     input: 无数据(不符合条件) + 收起态 + offset(符合条件)
     output: expanded = false
     */
    func test_collapseIfNecessary2() {
        let offsetY = 1000 as CGFloat // 符合条件
        let heightAboveShortcut = 500 as CGFloat // 符合条件
        shortViewModel.collapseIfNecessary(offsetY: offsetY, heightAboveShortcut: heightAboveShortcut)
        XCTAssert(shortViewModel.expanded == false)
    }

    /* case3: 主要测试 仅有单行数据 对该接口的影响
     input: 仅存在1行数据(不符合条件) + 收起态 + offset(符合条件)
     output: expanded = false
     */
    func test_collapseIfNecessary3() {
        stuffingDataUntilFinish(count: OneLineDataCount) // 不符合条件
        let offsetY = 1000 as CGFloat // 符合条件
        let heightAboveShortcut = 500 as CGFloat // 符合条件
        shortViewModel.collapseIfNecessary(offsetY: offsetY, heightAboveShortcut: heightAboveShortcut)
        XCTAssert(shortViewModel.expanded == false)
    }

    /* case4: 主要测试 展开态 对该接口的影响
     input: 多行数据(符合条件) + 展开态(不符合条件) + offset(符合条件)
     output: expanded = false
     */
    func test_collapseIfNecessary4() {
        stuffingDataUntilFinish(count: TwoLineDataCount) // 符合条件
        let offsetY = 1000 as CGFloat // 符合条件
        let heightAboveShortcut = 500 as CGFloat // 符合条件
        shortViewModel.collapseIfNecessary(offsetY: offsetY, heightAboveShortcut: heightAboveShortcut)
        XCTAssert(shortViewModel.expanded == false)
    }

    /* case5: 主要测试 offset 变量对该接口的影响
     input: 多行数据(符合条件) + 展开态(符合条件) + offset(不符合条件)
     output: expanded = true
     */
    func test_collapseIfNecessary5() {
        stuffingDataUntilFinish(count: TwoLineDataCount)
        shortViewModel.toggleExpandedAndCollapse()
        let offsetY = -1000 as CGFloat
        let heightAboveShortcut = 500 as CGFloat
        shortViewModel.collapseIfNecessary(offsetY: offsetY, heightAboveShortcut: heightAboveShortcut)
        XCTAssert(shortViewModel.expanded == true)
    }
}

extension ShortcutsViewModelTest {
    private func testDataflow(count: Int, display: Bool, expanded: Bool, height: CGFloat, isNeedMainWait: Bool = true) {
        if isNeedMainWait {
            mainWait()
        }
        XCTAssert(self.shortViewModel.dataSource.count == count)
        XCTAssert(shortViewModel.display == display)
        XCTAssert(shortViewModel.expanded == expanded)
        XCTAssert(shortViewModel.viewHeight == height)
    }

    private func testMoreDataflow(display: Bool, expanded: Bool, badgeInfo: FeedBadgeInfo? = nil) {
        mainWait()
        XCTAssert(shortViewModel.expandMoreViewModel.display == display)
        XCTAssert(shortViewModel.expandMoreViewModel.isExpanded == expanded)
        if let badge = badgeInfo {
            XCTAssert(shortViewModel.expandMoreViewModel.badgeInfo.type == badge.0)
            XCTAssert(shortViewModel.expandMoreViewModel.badgeInfo.style == badge.1)
        }
    }

    private func testDataflow(dataComplete: ((ShortcutViewModelUpdate) -> Void)? = nil,
                              displayComplete: ((Bool) -> Void)? = nil,
                              expandedComplete: ((Bool) -> Void)? = nil,
                              heightDriverComplete: ((CGFloat) -> Void)? = nil) {

        mainWait()
        let expect = expectation(description: "testDataflow")
        expect.expectedFulfillmentCount = 4

        // 监听数据流
        shortViewModel.dataDriver.drive(onNext: { update in
            if let dataComplete = dataComplete {
                dataComplete(update)
            }
            expect.fulfill()
        }).disposed(by: disposeBag)

        // 监听shortcutsCollectionView是否显示：从无到有 + 从有到无
        shortViewModel.displayDriver.drive(onNext: { display in
            if let displayComplete = displayComplete {
                displayComplete(display)
            }
            expect.fulfill()
        }).disposed(by: disposeBag)

        // 监听展开/收起的信号
        shortViewModel.expandedObservable
            .asDriver(onErrorJustReturn: false)
            .drive(onNext: { expanded in
            if let expandedComplete = expandedComplete {
                expandedComplete(expanded)
            }
            expect.fulfill()
        }).disposed(by: disposeBag)

        // 监听shortcutsCollectionView高度信号
        shortViewModel.updateHeightDriver.drive(onNext: { height in
            if let heightDriverComplete = heightDriverComplete {
                heightDriverComplete(height)
            }
            expect.fulfill()
        }).disposed(by: disposeBag)

        wait(for: [expect], timeout: timeout)
    }

    private func testMoreDataflow(displayComplete: ((Bool) -> Void)? = nil,
                              expandedComplete: ((Bool) -> Void)? = nil,
                              dataComplete: ((ShortcutExpandMoreViewModel) -> Void)? = nil) {

        let expect = expectation(description: "testMoreDataflow")
        expect.expectedFulfillmentCount = 3

        // 监听是否显示的信号
        shortViewModel.expandMoreViewModel.displayDriver.drive(onNext: { display in
            if let displayComplete = displayComplete {
                displayComplete(display)
            }
            expect.fulfill()
        }).disposed(by: disposeBag)

        // 监听展开/收起的信号
        shortViewModel.expandMoreViewModel.expandedObservable
            .asDriver(onErrorJustReturn: false)
            .drive(onNext: { expand in
                if let expandedComplete = expandedComplete {
                    expandedComplete(expand)
                }
                expect.fulfill()
        }).disposed(by: disposeBag)

        // 监听更新badge的信号
        shortViewModel.expandMoreViewModel.updateContentObservable
            .asDriver(onErrorJustReturn: ())
            .drive(onNext: { [weak self]  in
                guard let self = self else { return }
                if let dataComplete = dataComplete {
                    dataComplete(self.shortViewModel.expandMoreViewModel)
                }
                expect.fulfill()
        }).disposed(by: disposeBag)

        wait(for: [expect], timeout: timeout)
    }
}

extension ShortcutsViewModelTest {

    /// 填充数据
    private func stuffingData(_ viewWidth: Int = 414, count: Int = 6) {
        shortViewModel.containerWidth = CGFloat(viewWidth)
        let list = creatCellViewModels(count)
        let update = ShortcutViewModelUpdate.full(list)
        shortViewModel.refreshInMainThread(update)
    }

    /// 填充数据并直到数据流的最后一个节点任务结束
    private func stuffingDataUntilFinish(_ viewWidth: Int = 414, count: Int = 6) {
        stuffingData(viewWidth, count: count)
        mainWait()
    }

    func creatCellViewModels(_ count: Int = 1) -> [ShortcutBaseCellViewModel] {
        let list = creatModels(count)
        return list.map({ ShortcutBaseCellViewModel(result: $0) })
    }

    func creatModels(_ count: Int = 1) -> [ShortcutResult] {
        var list = [ShortcutResult]()
        for i in 0..<count {
            let id = "\(i)"

            var short = shortcut
            short.position = Int32(i)
            short.channel.id = id

            var feed = feedPreview
            feed.id = id
            let obj = ShortcutResult(shortcut: short, preview: feed)
            list.append(obj)
        }
        return list
    }

    var shortcut: Shortcut {
        var shortcut = Shortcut()
        shortcut.position = 0
        shortcut.channel.id = "0"
        shortcut.channel.type = Channel.TypeEnum.allCases.randomElement()!
        return shortcut
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

    var atInfo: FeedPreviewAtInfo {
        return FeedPreviewAtInfo(type: .all,
                                 channelName: "",
                                 avatarKey: "",
                                 localizedUserName: "")
    }
}

private class Dependency: ShortCutViewModelDependency {

    // 获取列表数据
    var loadShortcutsBuilder: (() -> Observable<FeedContextResponse>)?
    func loadShortcuts(preCount: Int) -> Observable<FeedContextResponse> {
        if let builder = loadShortcutsBuilder {
            return builder()
        }
        return .empty()
    }

    // 通过拖拽更换了shortcut的位置，需要告诉server
    var updateBuilder: ((Shortcut, Int) -> Observable<Void>)?
    func update(shortcut: Shortcut, newPosition: Int) -> Observable<Void> {
        if let builder = updateBuilder {
            return builder(shortcut, newPosition)
        }
        return .empty()
    }

    // 预加载
    func preloadFeedCards(by ids: [String]) {}

    /// shortcut的推送
    var pushShortcutsBuilder: (() -> Observable<PushShortcuts>)?
    var pushShortcutsOb: Observable<PushShortcuts> {
        if let builder = pushShortcutsBuilder {
            return builder()
        }
        return .empty()
    }

    /// BadgeStyle的推送
    var badgeStyleBuilder: (() -> Observable<Settings_V1_BadgeStyle>)?
    var badgeStylePush: Observable<Settings_V1_BadgeStyle> {
        if let builder = badgeStyleBuilder {
            return builder()
        }
        return .empty()
    }

    /// 获取当前选中Feed的FeedId
    func getSelected() -> String? {
        return "0"
    }
}
