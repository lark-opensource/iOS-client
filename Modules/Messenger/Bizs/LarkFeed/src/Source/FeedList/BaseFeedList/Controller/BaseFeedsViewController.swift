//
//  BaseFeedsViewController.swift
//  LarkFeed
//
//  Created by bytedance on 2020/6/5.
//

import Foundation
import UIKit
import RxSwift
import LarkUIKit
import EENavigator
import RxDataSources
import LarkSDKInterface
import LarkMessengerInterface
import LarkSwipeCellKit
import UniverseDesignToast
import LKCommonsLogging
import LarkKeyCommandKit
import LarkPerf
import AppReciableSDK
import LarkZoomable
import LarkModel
import LarkSceneManager
import UniverseDesignEmpty
import LarkContainer
import LarkOpenFeed
import RustPB

///
/// VC 均继承自 BaseUIViewController
///
class BaseFeedsViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource, UITableViewDragDelegate, UserResolverWrapper {
    var userResolver: UserResolver { feedsViewModel.userResolver }
    let feedDependency: FeedDependency
    let feedGuideDependency: FeedGuideDependency
    private let feedThreeBarService: FeedThreeBarService?

    let disposeBag: DisposeBag
    let feedsViewModel: BaseFeedsViewModel
    var context: FeedContextService?
    let tableView = FeedTableView(frame: .zero, style: .grouped)

    weak var emptyView: UDEmptyView?
    var trace = FeedListTrace.genDefault()

    // leftOrientation、rightOrientation 用于缓存
    static var leftOrientation: SwipeOptions?
    static var rightOrientation: SwipeOptions?

    // 是否能进行下一次 preload
    var preloadEnabled = true
    var loadMoreCostKey: DisposedKey? // loadmore 打点用

    // 滑动时禁止使用 diff 刷新的兜底方案，如果滑动时，尽力去锁队列，锁不住使用 reload 刷新，不要用 diff 刷新
    var isScrolling = false

    // 记录侧滑的cell
    weak var swipingCell: SwipeTableViewCell?
    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }

    var iPadStatus: String? {
        if let unfold = feedThreeBarService?.padUnfoldStatus {
            return unfold ? "unfold" : "fold"
        }
        return nil
    }

    lazy var feedActionService: FeedActionService? = {
        return try? userResolver.resolve(assert: FeedActionService.self)
    }()

    init(feedsViewModel: BaseFeedsViewModel) throws {
        self.disposeBag = DisposeBag()
        self.feedDependency = try feedsViewModel.baseDependency.resolver.resolve(assert: FeedDependency.self)
        self.feedGuideDependency = try feedsViewModel.baseDependency.resolver.resolve(assert: FeedGuideDependency.self)
        self.feedThreeBarService = try? feedsViewModel.baseDependency.resolver.resolve(assert: FeedThreeBarService.self)
        self.feedsViewModel = feedsViewModel
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 延迟 Cell 取消选中到 willAppear 中，如果放在 TableView didSelectRowAt 处，轻轻的点选 Cell 点击态不明显
        // 因为 deselectRow 调用之后将调用 Cell 的 setSelected，将取消选中态
        if let selectIndexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: selectIndexPath, animated: false)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sendFeedListState(state: .viewAppear)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        viewWillTransitionForPad(to: size, with: coordinator)
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feedsViewModel.allItems().count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        func printError(info: String) {
            let errorMsg = "\(info), row: \(indexPath.row), \(feedsViewModel.listBaseLog), \(trace.description)"
            let info = FeedBaseErrorInfo(type: .error(), errorMsg: errorMsg)
            FeedExceptionTracker.DataStream.onscreen(node: .cellForRow, info: info)
        }
        guard let item = feedsViewModel.cellViewModel(indexPath) else {
            printError(info: "can't get feed.")
            return getCell(tableView, cellForRowAt: indexPath)
        }
        guard let cell = FeedCardContext.dequeueReusableCell(
            feedCardModuleManager: feedsViewModel.feedCardModuleManager,
            viewModel: item,
            tableView: tableView,
            indexPath: indexPath) else {
            printError(info: "can't get cell. \(item.feedPreview.description)")
            return getCell(tableView, cellForRowAt: indexPath)
        }
        cell.delegate = self
        if let cell = cell as? UIView & FeedUniversalListCellProtocol {
            feedsViewModel.tracklogCurrentCell(cell: cell, indexPath: indexPath, cellVM: cell.viewModel, feedCardVM: item, trace: trace)
        }
        return cell
    }

    // MARK: - UITableViewDelegate

    // ↓↓↓↓↓↓↓↓↓↓ MyAI 引导入口 ↓↓↓↓↓↓↓↓↓↓

    /// 列表最上方的 MyAI 初始化引导视图，位于 Feed 最上方，点击后跳转 MyAI Onboarding
    /// - NOTE: Onboarding 完成不再显示，所以是 lazy，正常状态下不创建
    private lazy var aiHeaderView: FeedAIHeaderView = {
        let viewModel = FeedAIHeaderViewModel(
            resolver: feedsViewModel.userResolver,
            fromVC: self)
        return FeedAIHeaderView(viewModel: viewModel)
    }()

    private func shouldShowAiHeader(in section: Int) -> Bool {
        // 目前只有一个 section
        guard section == 0 else { return false }
        // 只在 "Chats" 列表上展示 MyAI 初始化引导
        guard feedsViewModel.getFilterType() == .message else { return false }
        // 判断 MyAI 的可用状态，和是否已完成 Onboarding
        guard let myAiService = feedsViewModel.myAIService else {
            let info = FeedBaseErrorInfo(type: .warning(), errorMsg: "could not find MyAIService.")
            FeedExceptionTracker.MyAI.onboarding(node: .shouldShowAiHeader, info: info)
            return false
        }
        guard myAiService.enable.value, myAiService.needOnboarding.value else {
            return false
        }
        return true
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return shouldShowAiHeader(in: section) ? aiHeaderView.headerHeight : .leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return shouldShowAiHeader(in: section) ? aiHeaderView : nil
    }

    // ↑↑↑↑↑↑↑↑↑↑ MyAI 引导入口 ↑↑↑↑↑↑↑↑↑↑

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        feedsViewModel.cellRowHeight(indexPath) ?? 0
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? FeedCardCellInterface else { return }
        cell.willDisplay()
        loadMore(index: indexPath.row)
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? FeedCardCellInterface else { return }
        cell.didEndDisplay()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectedCell = tableView.cellForRow(at: indexPath) as? FeedUniversalListCellProtocol else {
            let errorMsg = "tap unfind, \(feedsViewModel.listBaseLog), \(trace.description), row: \(indexPath.row)"
            let info = FeedBaseErrorInfo(type: .error(), errorMsg: errorMsg)
            FeedExceptionTracker.FeedCard.action(node: .didSelectRow, info: info)
            return
        }
        if let feedId = selectedCell.feedPreview?.id,
           feedsViewModel.shouldSkip(feedId: feedId, traitCollection: view.horizontalSizeClass) {
            let logInfo = "\(feedsViewModel.listBaseLog), \(trace.description), row: \(indexPath.row)"
            FeedContext.log.info("feedlog/feedcard/action/tap/skip. \(logInfo), feedId: \(feedId)")
            return
        }
        selectedCell.didSelectCell(from: self, trace: self.trace, filterType: self.feedsViewModel.getFilterType())
    }

    // MARK: - UITableViewDragDelegate
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let cell = tableView.cellForRow(at: indexPath) as? FeedCardCellInterface,
              let scene = cell.supportDragScene() else {
            return []
        }
        scene.sceneSourceID = self.currentSceneID()
        let activity = SceneTransformer.transform(scene: scene)
        let itemProvider = NSItemProvider()
        itemProvider.registerObject(activity, visibility: .all)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        return [dragItem]
    }

    func tableView(_ tableView: UITableView, dragPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return nil
        }
        let parameters = UIDragPreviewParameters()
        parameters.visiblePath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: 12)
        return parameters
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // 用户手指按住 feeds list 时，挂起 feeds 相关的任务
        sendFeedListState(state: .startScrolling)
        onlyFullReloadWhenScrolling(true, taskType: .draging)
        feedsViewModel.changeQueueState(true, taskType: .draging)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // 手指抬起
        if !decelerate {
            sendFeedListState(state: .stopScrolling(position: findLastVisibleCellIndex()))
            tracklogVisibleFeeds()
        }
        if !decelerate {
            // 彻底停止滑动
            onlyFullReloadWhenScrolling(false, taskType: .draging)
        }
        // 恢复 feeds 刷新
        feedsViewModel.changeQueueState(false, taskType: .draging)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // 彻底停止滑动
        // 触发预加载
        sendFeedListState(state: .stopScrolling(position: findLastVisibleCellIndex()))

        tracklogVisibleFeeds()
        // 如果 tableView 停止时，发现 loadmore 还处于 loading 状态，则终止掉
        endBottomLoadMore()
        onlyFullReloadWhenScrolling(false, taskType: .draging)
    }

    // MARK: Swipe - 方便业务集成，提供默认实现，放这里便于 subclass override
    ///
    /// 标记完成：VC 中转一下，方便 override
    ///
    func markForDone(_ cellViewModel: FeedCardCellViewModel) {
        FeedActionFactoryManager.performSomeActionOnce(type: .done,
                                                       feedPreview: cellViewModel.feedPreview,
                                                       context: cellViewModel.feedCardModule.feedCardContext,
                                                       channel: cellViewModel.bizData.shortcutChannel,
                                                       from: self)
        // iPad: 自动选中下一 Feed
        selectNextFeedIfNeeded(feedId: cellViewModel.feedPreview.id)
    }

    func markForFlagAction(vm: FeedCardCellViewModel) {}

    /// override 和 @objc iOS13 以下不能放到 extension 里
    // MARK: - iPad
    override func keyBindings() -> [KeyBindingWraper] {
        guard feedsViewModel.getActiveState() else { return [] }
        return super.keyBindings() + selectFeedKeyCommand()
    }

    @objc
    func selectPrevForKC() {
        selectPrevFeedForPad()
    }

    @objc
    func selectNextForKC() {
        selectNextFeedForPad()
    }

    @objc
    func selectPrevUnreadForKC() {
        selectPrevUnreadFeedForPad()
    }

    @objc
    func selectNextUnreadForKC() {
        selectNextUnreadFeedForPad()
    }

    @objc
    func selectPrevRecordForKC() {
        selectPrevFeedRecordForPad()
    }

    @objc
    func selectNextRecordForKC() {
        selectNextFeedRecordForPad()
    }

    @objc
    func markCurrentFeedForDone() {
        markCurrentFeedDoneForPad()
    }
}
