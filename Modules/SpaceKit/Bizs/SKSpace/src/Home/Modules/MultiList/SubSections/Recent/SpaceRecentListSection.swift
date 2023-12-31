//
//  SpaceRecentListSection.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/4.
//

import UIKit
import RxSwift
import RxRelay
import RxCocoa
import SKCommon
import SKFoundation
import SKResource
import LarkSceneManager
import UniverseDesignEmpty
import UniverseDesignColor
import UniverseDesignIcon
import SKUIKit
import LarkContainer

public final class SpaceRecentListSection: SpaceListSubSection, SpaceListSectionAutoLayout, SpaceListSectionAutoDataSource, SpaceListSectionCommonDelegate {

    public let identifier: String = "recent"
    public var subSectionTitle: String  {
        if isShowInDetail {
            return BundleI18n.SKResource.LarkCCM_NewCM_RecentVisits_Header
        } else {
            return BundleI18n.SKResource.Doc_List_Recent
        }
    }
    public let subSectionIdentifier: String = "recent"

    public var listTools: [SpaceListTool] {
        switch homeType {
        case .baseHomeType:
            return bitableHomeListTools
        case let .defaultHome(isFromV2Tab):
            if isShowInDetail {
                return SpaceTabIpadListToos
            }
            if isFromV2Tab {
                return v2SpaceTabListTools
            } else {
                // 非v2的云文档tab下，根据新首页FG控制listTool展示方式
                return UserScopeNoChangeFG.WWJ.newSpaceTabEnable ? homeListTools : spaceTabListTools
            }
        }
    }

    private var bitableHomeListTools: [SpaceListTool] {
        [
            .modeSwitch(modeRelay: displayModeRelay, clickHandler: { [weak self] _ in
                self?.switchDisplayMode()
            })
        ]
    }

    // 改版前的 space 首页最近列表
    private var spaceTabListTools: [SpaceListTool] {
        [
            .filter(stateRelay: viewModel.filterAndSortStateRelay,
                    isEnabled: viewModel.filterEnabled,
                    clickHandler: { [weak self] view in
                        self?.changeFilterAndSortState(filterView: view)
                    }),
            .modeSwitch(modeRelay: displayModeRelay, clickHandler: { [weak self] _ in
                self?.switchDisplayMode()
            })
        ]
    }
    
    // ipad上的最近列表
    private var SpaceTabIpadListToos: [SpaceListTool] {
        [
            .sort(stateRelay: viewModel.sortStateRelay,
                  titleRelay: viewModel.sortNameRelay,
                  isEnabled: viewModel.reachabilityChanged,
                  clickHandler: { [weak self] view in
                      self?.changeSortState(sourceView: view)
                  }),
            .filter(stateRelay: viewModel.filterStateRelay,
                    isEnabled: viewModel.reachabilityChanged,
                    clickHandler: { [weak self] view in
                        self?.changeFilterState(sourceView: view)
                    }),
            .modeSwitch(modeRelay: displayModeRelay,
                        clickHandler: { [weak self] _ in
                            self?.switchDisplayMode()
                        })
        ]
    }
    
    // 全部文档(主页)中最近列表
    private var homeListTools: [SpaceListTool] {
        [
            .sort(stateRelay: viewModel.sortStateRelay,
                  titleRelay: viewModel.sortNameRelay,
                  isEnabled: viewModel.filterEnabled,
                  clickHandler: { [weak self] view in
                      self?.changeSortState(sourceView: view)
                  }),
            .filter(stateRelay: viewModel.filterStateRelay,
                    isEnabled: viewModel.filterEnabled,
                    clickHandler: { [weak self] view in
                        self?.changeFilterState(sourceView: view)
                    }),
            .modeSwitch(modeRelay: displayModeRelay, clickHandler: { [weak self] _ in
                self?.switchDisplayMode()
            })
        ]
    }
    
    public var iPadListHeaderSortConfig: IpadListHeaderSortConfig? {
        let selectOptionDriver: Driver<(IpadSpaceSubListHeaderView.Index, SpaceSortHelper.SortOption)>
        selectOptionDriver = viewModel.selectSortOptionRelay
            .asDriver(onErrorJustReturn: viewModel.dataModel.sortHelper.selectedOption)
            .compactMap { sortOption in
                guard let sortOption else { return nil }
                return (.thrid, sortOption)
            }
        return IpadListHeaderSortConfig(sortOption: [SpaceSortHelper.SortOption(type: .title, descending: true, allowAscending: false),
                                                     SpaceSortHelper.SortOption(type: .owner, descending: true, allowAscending: false),
                                                     viewModel.dataModel.sortHelper.selectedOption],
                                        displayModeRelay: displayModeRelay,
                                        selectSortOptionDriver: selectOptionDriver)
    }

    // 改版后的 space 首页最近列表
    private var v2SpaceTabListTools: [SpaceListTool] {
        [
            .controlPanel(filterStateRelay: viewModel.filterStateRelay,
                          sortStateRelay: viewModel.sortStateRelay,
                          clickHandler: { [weak self] view in
                              self?.showListControlPanel(sourceView: view)
                          })
        ]
    }
    
    public var createIntent: SpaceCreateIntent {
        SpaceCreateIntent(context: UserScopeNoChangeFG.WWJ.newSpaceTabEnable ? .spaceNewHome : .recent,
                          source: .recent,
                          createButtonLocation: .blankPage)
    }

    private let displayModeRelay = BehaviorRelay<SpaceListDisplayMode>(value: .list)
    private var displayMode: SpaceListDisplayMode { displayModeRelay.value }

    private let reloadInput = PublishRelay<ReloadAction>()
    public var reloadSignal: Signal<ReloadAction> {
        reloadInput.asSignal()
    }

    private let actionInput = PublishRelay<Action>()
    public var actionSignal: Signal<Action> {
        actionInput.asSignal()
    }

    // UI 数据源，负责 CollectionView 的 Item 数据，注意只在主线程进行操作，且需要刷新 UI
    private var listState = ListState.loading

    private let viewModel: RecentListViewModel
    private var tracker: SpaceSubSectionTracker { viewModel.tracker }
    private lazy var stateHelper: SpaceSubSectionStateHelper = {
        let differ = SpaceListDifferFactory.createListStateDiffer()
        return SpaceSubSectionStateHelper(differ: differ,
                                          listID: identifier,
                                          stateProvider: self)
    }()

    public private(set) lazy var sectionLayoutHelper: SpaceListSectionLayoutHelper = {
        if isShowInDetail {
            return IpadSpaceSubSectionLayoutHelper(delegate: self)
        } else {
            return SpaceSubSectionLayoutHelper(delegate: self)
        }
    }()

    public private(set) lazy var sectionDataSourceHelper: SpaceListSectionDataSourceHelper = {
        if isShowInDetail {
            return IpadSpaceSubSectionDataSourceHelper(delegate: self) { [weak self] ownerId in
                self?.actionInput.accept(.customWithController(completion: { from in
                    HostAppBridge.shared.call(ShowUserProfileService(userId: ownerId, fromVC: from))
                }))
            }
        } else {
            return SpaceSubSectionDataSourceHelper(delegate: self)
        }
    }()

    public private(set) lazy var sectionDelegateProxy: SpaceListSectionDelegateProxy = {
        if isShowInDetail {
            return IpadSpaceSubSectionDelegateHelper(provider: self)
        } else {
            return SpaceSubSectionDelegateHelper(provider: self)
        }
    }()

    private let disposeBag = DisposeBag()
    private let homeType: SpaceHomeType
    // 是否展示在iPad的右侧
    private let isShowInDetail: Bool

    // 同步获取当前可见的 item 下标，用于 Rust 列表自动刷新的判断
    public var visableIndicesHelper: (() -> [Int])?

    public let userResolver: UserResolver
    init(userResolver: UserResolver,
         viewModel: RecentListViewModel,
         homeType: SpaceHomeType = .spaceTab,
         isShowInDetail: Bool = false) {
        self.userResolver = userResolver
        self.homeType = homeType
        self.viewModel = viewModel
        self.isShowInDetail = isShowInDetail
    }

    public func prepare() {
        setupDisplayMode()
        stateHelper.actionSignal.emit(to: actionInput).disposed(by: disposeBag)
        stateHelper.reloadSignal.emit(to: reloadInput).disposed(by: disposeBag)
        viewModel.update(refreshPresenter: self)
        viewModel.itemsUpdated.observeOn(SerialDispatchQueueScheduler(internalSerialQueueName: "space.recent.section"))
            .subscribe(onNext: { [weak self] newItems in
                self?.handle(newItems: newItems)
            }).disposed(by: disposeBag)
        viewModel.actionSignal.emit(to: actionInput).disposed(by: disposeBag)
        viewModel.prepare()
    }

    private func setupDisplayMode() {
        let mode: SpaceListDisplayMode = LayoutManager.shared.isGrid ? .grid : .list
        displayModeRelay.accept(mode)

        NotificationCenter.default.rx
            .notification(LayoutManager.layoutChangeNotification)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                let mode: SpaceListDisplayMode = LayoutManager.shared.isGrid ? .grid : .list
                self.displayModeRelay.accept(mode)
                self.reloadInput.accept(.reloadSection(animated: false))
            })
            .disposed(by: disposeBag)
    }

    private func switchDisplayMode() {
        LayoutManager.shared.isGrid = !LayoutManager.shared.isGrid
        let newMode: SpaceListDisplayMode
        if LayoutManager.shared.isGrid {
            newMode = .grid
        } else {
            newMode = .list
        }
        tracker.reportChangeDisplayMode(newMode: newMode, subModule: .recent)
    }

    private func changeFilterAndSortState(filterView: UIView) {
        let config = viewModel.listFilterSortConfig
        let panelController = SpaceFilterSortPanelController(config: config)
        panelController.delegate = viewModel
        panelController.setupPopover(sourceView: filterView, direction: .any)
        panelController.popoverPresentationController?.sourceRect = filterView.bounds.inset(by: UIEdgeInsets(top: -4, left: -4, bottom: -4, right: -4)) // 向外偏移一点
        panelController.dismissalStrategy = .larkSizeClassChanged
        actionInput.accept(.present(viewController: panelController, popoverConfiguration: nil))
        tracker.reportClickFilterPanel()
        DocsTracker.reportSpaceHeaderFilterView(bizParms: tracker.bizParameter)
        DocsTracker.reportSpaceHomePageClick(params: .filter, bizParms: tracker.bizParameter)
    }

    private func changeFilterState(sourceView: UIView) {
        guard let config = viewModel.generateLegacySortFilterConfig() else {
            DocsLogger.error("space.recent.section --- unable to get sort filter config")
            return
        }
        let selectedIndex = config.filterItems.firstIndex(where: \.isSelected) ?? 0
        let panelController = SpaceFilterPanelController(options: config.filterItems, initialSelection: selectedIndex)
        panelController.delegate = viewModel
        panelController.setupPopover(sourceView: sourceView, direction: .any)
        panelController.popoverPresentationController?.sourceRect = sourceView.bounds.inset(by: UIEdgeInsets(top: -4, left: -4, bottom: -4, right: -4)) // 向外偏移一点
        panelController.dismissalStrategy = .larkSizeClassChanged
        actionInput.accept(.present(viewController: panelController, popoverConfiguration: nil))
        tracker.reportClickFilterPanel()
        DocsTracker.reportSpaceHeaderFilterView(bizParms: tracker.bizParameter)
        DocsTracker.reportSpaceSharedPageClick(params: .filter)
    }

    private func changeSortState(sourceView: UIView) {
        guard let config = viewModel.generateLegacySortFilterConfig() else {
            DocsLogger.error("space.recent.section --- unable to get sort filter config")
            return
        }
        guard viewModel.isReachable else {
            actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.Doc_Facade_Offline)))
            return
        }
        let selectedIndex = config.sortItems.firstIndex(where: \.isSelected) ?? 0
        let panelController = SpaceSortPanelController(options: config.sortItems, initialSelection: selectedIndex, canReset: config.sortChanged)
        panelController.delegate = viewModel
        panelController.setupPopover(sourceView: sourceView, direction: .any)
        panelController.popoverPresentationController?.sourceRect = sourceView.bounds.inset(by: UIEdgeInsets(top: -4, left: -4, bottom: -4, right: -4)) // 向外偏移一点
        panelController.dismissalStrategy = .larkSizeClassChanged
        actionInput.accept(.present(viewController: panelController, popoverConfiguration: nil))
        tracker.reportClickFilterPanel()
        DocsTracker.reportSpaceHeaderFilterView(bizParms: tracker.bizParameter)
        DocsTracker.reportSpaceSharedPageClick(params: .filter)
    }
    
    private func showListControlPanel(sourceView: UIView) {
        let sortModel = SpaceCommonListItem(leadingTitle: .init(title: BundleI18n.SKResource.Doc_List_SortBy, color: UDColor.textTitle, font: .systemFont(ofSize: 16)),
                                            trailingRightIcon: .init(image: UDIcon.rightOutlined, color: UDColor.iconN3, size: CGSize(width: 14, height: 14)),
                                            trailingTitle: .init(title: viewModel.dataModel.sortHelper.selectedOption.legacyItem.fullDescription,
                                                                 color: UDColor.textCaption,
                                                                 font: .systemFont(ofSize: 14)),
                                            enableObservable: viewModel.reachabilityChanged) { [weak self] in
            self?.changeSortState(sourceView: sourceView)
        }
        let filterModel = SpaceCommonListItem(leadingTitle: .init(title: BundleI18n.SKResource.LarkCCM_NewCM_Filter_Button, color: UDColor.textTitle, font: .systemFont(ofSize: 16)),
                                              trailingRightIcon: .init(image: UDIcon.rightOutlined, color: UDColor.iconN3, size: CGSize(width: 14, height: 14)),
                                              trailingTitle: .init(title: viewModel.dataModel.filterHelper.selectedOption.displayName,
                                                                   color: UDColor.textCaption,
                                                                   font: .systemFont(ofSize: 14)),
                                              enableObservable: viewModel.reachabilityChanged) { [weak self] in
            self?.changeFilterState(sourceView: sourceView)
        }
        let displayTitle = LayoutManager.shared.isGrid ? BundleI18n.SKResource.LarkCCM_NewCM_Mobile_SwitchToListView_Menu :
                                                         BundleI18n.SKResource.LarkCCM_NewCM_Mobile_SwitchToGridView_Menu
        let displayModeModel = SpaceCommonListItem(leadingTitle: .init(title: displayTitle,
                                                                       color: UDColor.textTitle,
                                                                       font: .systemFont(ofSize: 16))) { [weak self] in
            self?.switchDisplayMode()
        }
        
        var resetHandler: (() -> Void)?
        if viewModel.filterState.isActive || viewModel.sortStateRelay.value.isActive {
            resetHandler = { [weak self] in
                self?.viewModel.resetSortState()
                self?.viewModel.resetFilterState()
            }
        }
        
        let config = SpaceCommonListConfig(items: [sortModel, filterModel, displayModeModel], resetHandler: resetHandler)
        let panel = SpaceCommonListPanel(title: BundleI18n.SKResource.LarkCCM_NewCM_Mobile_ListSettings_Title, config: config)
        panel.dismissalStrategy = .larkSizeClassChanged
        panel.setupPopover(sourceView: sourceView, direction: .any)
        actionInput.accept(.present(viewController: panel, popoverConfiguration: nil))
    }

    public func notifyPullToRefresh() {
        viewModel.notifyPullToRefresh()
    }

    public func notifyPullToLoadMore() {
        viewModel.notifyPullToLoadMore()
    }

    // TODO: 优化后台加载逻辑
    public func notifySectionDidAppear() {
        viewModel.notifySectionDidAppear()
        NotificationCenter.default.post(name: .Docs.notifySelectedSpaceEntarnce, object: (SpaceEntranceSection.EntranceIdentifier.ipadHome, true))
    }
    public func notifySectionWillDisappear() {
        viewModel.notifySectionWillDisappear()
        NotificationCenter.default.post(name: .Docs.notifySelectedSpaceEntarnce, object: (SpaceEntranceSection.EntranceIdentifier.ipadHome, false))
    }

    public func didShowSubSection() {
        viewModel.didBecomeActive()
        switch listState {
        case .empty, .loading, .networkUnavailable:
            actionInput.accept(.stopPullToLoadMore(hasMore: false))
        default:
            break
        }
        DocsLogger.info("space.recent.section --- preload visable items when didShowSubSection")
        preloadVisableItems()
    }
    public func willHideSubSection() {
        viewModel.willResignActive()
    }

    public func reportClick(fromSubSectionId previousSubSectionId: String) {
        guard let previousModule = PageModule.typeFor(tabID: previousSubSectionId) else {
            DocsLogger.debug("Can not retrieve PageModule for " +
                             "previous sub section id(\(previousSubSectionId)")
            return
        }

        guard let params = SpacePageClickParameter.typeFor(subTab: subSectionIdentifier) else {
            DocsLogger.debug("Can not retrieve SpacePageClickParameter for " +
                             "current sub section id(\(subSectionIdentifier)")
            return
        }

        let bizParms = SpaceBizParameter(module: previousModule)
        DocsTracker.reportSpaceHomePageClick(params: params, bizParms: bizParms)
    }

    func emptyListCreatButtonAction(button: UIView) {
        let context: SpaceCreateContext
        if homeType.isBaseHomeType(), let module = homeType.pageModule() {
            context = .bitableHome(module)
        } else {
            context = .recent
        }
        let intent = SpaceCreateIntent(context: UserScopeNoChangeFG.WWJ.newSpaceTabEnable ? .spaceNewHome : context, source: .other, createButtonLocation: .blankPage)
        self.actionInput.accept(.create(with: intent, sourceView: button))
    }
    
    deinit {
        NotificationCenter.default.post(name: .Docs.notifySelectedSpaceEntarnce, object: (SpaceEntranceSection.EntranceIdentifier.ipadHome, false))
    }
}

extension SpaceRecentListSection: SpaceSubSectionLayoutDelegate {
    var layoutListState: SpaceListSubSection.ListState { listState }
    var layoutDisplayMode: SpaceListDisplayMode { displayMode }
}

extension SpaceRecentListSection: SpaceSectionLayout {}

extension SpaceRecentListSection: SpaceSubSectionDataSourceDelegate {
    var dataSourceListState: SpaceListSubSection.ListState { listState }
    var dataSourceDisplayMode: SpaceListDisplayMode { displayMode }
    var dataSourceCellTrackerModule: PageModule { tracker.module }
}

extension SpaceRecentListSection: SpaceSectionDataSource {}

extension SpaceRecentListSection: SpaceSubSectionDelegateProvider {
    var providerListState: SpaceListSubSection.ListState { listState }
    var listViewModel: SpaceListViewModel { viewModel }
    func open(newScene: Scene) {
        actionInput.accept(.newScene(newScene))
    }
}

extension SpaceRecentListSection: SpaceSectionDelegate {
    public func notifyDidEndDragging(willDecelerate: Bool) {
        if !willDecelerate {
            DocsLogger.info("space.recent.section --- preload visable items when end dragging")
            preloadVisableItems()
        }
    }

    public func notifyDidEndDecelerating() {
        DocsLogger.info("space.recent.section --- preload visable items when end decelerating")
        preloadVisableItems()
    }

    private func preloadVisableItems() {
        reloadInput.accept(.getVisableIndices(callback: { [weak self] (indices, _) in
            guard let self = self else { return }
            guard case let .normal(items) = self.listState else {
                return
            }
            let preloadKeys = indices.compactMap { index -> PreloadKey? in
                guard index < items.count else {
                    assertionFailure()
                    return nil
                }
                let itemType = items[index]
                guard case let .spaceItem(item) = itemType else { return nil }
                let entry = item.entry
                guard entry.type.shouldPreloadClientVar else { return nil }
                var preloadKey = entry.preloadKey
                preloadKey.fromSource = PreloadFromSource(.recentPreload)
                return preloadKey
            }
            DocsLogger.info("space.recent.section --- prepare to preload recent \(preloadKeys.count) entries from index \(indices.first ?? 0)", component: LogComponents.preload)
            NotificationCenter.default.post(name: NSNotification.Name.Docs.addToPreloadQueue,
                                            object: nil,
                                            userInfo: [DocPreloaderManager.preloadNotificationKey: preloadKeys])
        }))
    }
}

extension SpaceRecentListSection: SpaceSubSectionStateProvider {
    var canReloadState: Bool { viewModel.isActive }
    func handle(newState: SpaceListSubSection.ListState, helper: SpaceSubSectionStateHelper) {
        listState = newState
    }
    func didShowListAfterLoading() {
        DocsLogger.info("space.recent.section --- preload visable items when end loading")
        preloadVisableItems()
        let dataModel = viewModel.dataModel
        if case .defaultHome = homeType {
            userResolver.docs.spacePerformanceTracker?.reportOpenFinish(filterOption: dataModel.filterHelper.selectedOption,
                                                                        sortType: dataModel.sortHelper.selectedOption.type,
                                                                        displayMode: displayMode,
                                                                        scene: .recent)
        }
    }

    private func handle(newItems: [SpaceListItemType]) {
        let newState = newListState(from: newItems)
        stateHelper.handle(newState: newState)
    }

    private func newListState(from newItems: [SpaceListItemType]) -> ListState {
        guard newItems.isEmpty else { return .normal(itemTypes: newItems) }
        if viewModel.dataModel.listContainer.state == .restoring {
            DocsLogger.info("space.recent.section --- DB data not ready, show loading")
            return .loading
        }
        guard viewModel.isReachable else { return .networkUnavailable }
        switch viewModel.serverDataState {
        case .loading:
            // 本地数据为空时，服务端请求还未结束，继续loading
            DocsLogger.info("space.recent.section --- still loading server data, show loading")
            return .loading
        case .synced:
            // 服务端数据返回空，展示空白页
            let emptyTip: String
            var createButtonTitle = BundleI18n.SKResource.Doc_Facade_CreateDocument
            if viewModel.hasActiveFilter {
                emptyTip = BundleI18n.SKResource.Doc_Facade_FilterEmptyDocTips
            } else if case .baseHomeType = homeType {
                emptyTip = BundleI18n.SKResource.Bitable_Base_ExploreBitable_Description
                createButtonTitle = BundleI18n.SKResource.CreationMobile_Template_Bitable_Blanklabel
            } else {
                emptyTip = BundleI18n.SKResource.Doc_Facade_EmptyRecentVisit
            }
            return .empty(description: emptyTip,
                          emptyType: .documentDefault,
                          createEnable: .just(true),
                          createButtonTitle: createButtonTitle) { [weak self] button in
                guard let self = self else { return }
                // TODO: 初始化时配置好 context
                self.emptyListCreatButtonAction(button: button)
            }
        case .fetchFailed:
            // 服务端数据拉取失败，本地数据为空，展示失败重试页
            return .failure(description: BundleI18n.SKResource.Doc_Facade_LoadFailed) { [weak self] in
                guard let self = self else { return }
                self.listState = .loading
                self.reloadInput.accept(.reloadSection(animated: false))
                self.viewModel.notifyPullToRefresh()
            }
        }
    }
}

extension SpaceRecentListSection: SpaceRefreshPresenter {
    public func showRefreshTips(callback: @escaping () -> Void) {
        // 新刷新策略FG关闭时走旧的通知刷新逻辑
        guard !UserScopeNoChangeFG.MJ.newRecentListRefreshStrategy else {
            return
        }
        actionInput.accept(.showRefreshTips(callback: callback))
    }

    public func dismissRefreshTips(result: Result<Void, Error>) {
        let needScrollToTop: Bool
        switch result {
        case .success:
            needScrollToTop = true
        case let .failure(error):
            DocsLogger.error("space.recent.list.vm -- dismiss refresh tips with error", error: error)
            needScrollToTop = false
        }
        actionInput.accept(.dismissRefreshTips(needScrollToTop: needScrollToTop))
    }
}
