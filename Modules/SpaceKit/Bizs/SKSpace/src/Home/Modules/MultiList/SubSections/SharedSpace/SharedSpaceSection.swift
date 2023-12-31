//
//  SharedSpaceSection.swift
//  SKECM
//
//  Created by Weston Wu on 2021/2/19.

import UIKit
import RxSwift
import RxRelay
import RxCocoa
import SKCommon
import SKFoundation
import SKResource
import LarkSceneManager
import UniverseDesignColor
import UniverseDesignEmpty
import SKUIKit

public final class SharedSpaceSection: SpaceListSubSection, SpaceListSectionAutoLayout, SpaceListSectionAutoDataSource, SpaceListSectionCommonDelegate {

    public let identifier: String = "shared-space"
    public var subSectionTitle: String {
        if isShowInDetail {
            return BundleI18n.SKResource.Doc_List_Share_With_Me
        } else {
            return BundleI18n.SKResource.CreationMobile_ECM_ShareWithMe_Tab
        }
    }
    public let subSectionIdentifier: String = "sharetome"

    public var listTools: [SpaceListTool] {
        return [
            .sort(stateRelay: viewModel.sortStateRelay,
                  titleRelay: viewModel.sortNameRelay,
                  isEnabled: viewModel.reachabilityChanged,
                  clickHandler: { [weak self] view in
                self?.changeSortState(sortView: view)
            }),
            .filter(stateRelay: viewModel.filterStateRelay,
                    isEnabled: viewModel.reachabilityChanged,
                    clickHandler: { [weak self] view in
                        self?.changeFilterState(filterView: view)
                    }),
            .modeSwitch(modeRelay: displayModeRelay, clickHandler: { [weak self] _ in
                self?.switchDisplayMode()
            })
        ]
    }
    
    public var createIntent: SpaceCreateIntent {
        SpaceCreateIntent(context: .shared, source: .shareSpace, createButtonLocation: .blankPage)
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

    private var listState = ListState.loading

    private let viewModel: SharedSpaceViewModel
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
                self?.actionInput.accept(.customWithController(completion: { vc in
                    HostAppBridge.shared.call(ShowUserProfileService(userId: ownerId, fromVC: vc))
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

    // 同步获取当前可见的 item 下标，用于 Rust 列表自动刷新的判断
    public var visableIndicesHelper: (() -> [Int])?
    // 是否展示在iPad的右侧，用另一套UI
    private let isShowInDetail: Bool

    public init(viewModel: SharedSpaceViewModel, isShowInDetail: Bool = false) {
        self.viewModel = viewModel
        self.isShowInDetail = isShowInDetail
    }

    public func prepare() {
        setupDisplayMode()
        stateHelper.actionSignal.emit(to: actionInput).disposed(by: disposeBag)
        stateHelper.reloadSignal.emit(to: reloadInput).disposed(by: disposeBag)
        viewModel.itemsUpdated.observeOn(SerialDispatchQueueScheduler(internalSerialQueueName: "space.\(identifier).section"))
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
        tracker.reportChangeDisplayMode(newMode: newMode)
    }
    private func changeSortState(sortView: UIView) {
        guard let config = viewModel.generateSortFilterConfig() else {
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
        panelController.setupPopover(sourceView: sortView, direction: .any)
        panelController.popoverPresentationController?.sourceRect = sortView.bounds.inset(by: UIEdgeInsets(top: -4, left: -4, bottom: -4, right: -4)) // 向外偏移一点
        panelController.dismissalStrategy = .larkSizeClassChanged
        actionInput.accept(.present(viewController: panelController, popoverConfiguration: nil))
        tracker.reportClickFilterPanel()
        DocsTracker.reportSpaceHeaderFilterView(bizParms: tracker.bizParameter)
        DocsTracker.reportSpaceSharedPageClick(params: .filter)
    }

    private func changeFilterState(filterView: UIView) {
        guard let config = viewModel.generateSortFilterConfig() else {
            DocsLogger.error("space.recent.section --- unable to get sort filter config")
            return
        }
        let selectedIndex = config.filterItems.firstIndex(where: \.isSelected) ?? 0
        let panelController = SpaceFilterPanelController(options: config.filterItems, initialSelection: selectedIndex)
        panelController.delegate = viewModel
        panelController.setupPopover(sourceView: filterView, direction: .any)
        panelController.popoverPresentationController?.sourceRect = filterView.bounds.inset(by: UIEdgeInsets(top: -4, left: -4, bottom: -4, right: -4)) // 向外偏移一点
        panelController.dismissalStrategy = .larkSizeClassChanged
        actionInput.accept(.present(viewController: panelController, popoverConfiguration: nil))
        tracker.reportClickFilterPanel()
        DocsTracker.reportSpaceHeaderFilterView(bizParms: tracker.bizParameter)
        DocsTracker.reportSpaceSharedPageClick(params: .filter)
    }

    public func notifyPullToRefresh() {
        viewModel.notifyPullToRefresh()
    }

    public func notifyPullToLoadMore() {
        viewModel.notifyPullToLoadMore()
    }

    public func didShowSubSection() {
        viewModel.didBecomeActive()
        switch listState {
        case .empty, .loading, .networkUnavailable:
            actionInput.accept(.stopPullToLoadMore(hasMore: false))
        default:
            break
        }
    }
    public func willHideSubSection() {
        viewModel.willResignActive()
    }
}

extension SharedSpaceSection: SpaceSubSectionLayoutDelegate {
    var layoutListState: SpaceListSubSection.ListState { listState }
    var layoutDisplayMode: SpaceListDisplayMode { displayMode }
}

extension SharedSpaceSection: SpaceSectionLayout {}

extension SharedSpaceSection: SpaceSubSectionDataSourceDelegate {
    var dataSourceListState: SpaceListSubSection.ListState { listState }
    var dataSourceDisplayMode: SpaceListDisplayMode { displayMode }
    var dataSourceCellTrackerModule: PageModule { tracker.module }
}

extension SharedSpaceSection: SpaceSectionDataSource {}

extension SharedSpaceSection: SpaceSubSectionDelegateProvider {
    var providerListState: SpaceListSubSection.ListState { listState }
    var listViewModel: SpaceListViewModel { viewModel }
    func open(newScene: Scene) {
        actionInput.accept(.newScene(newScene))
    }
}

extension SharedSpaceSection: SpaceSectionDelegate {}

extension SharedSpaceSection: SpaceSubSectionStateProvider {
    var canReloadState: Bool { viewModel.isActive }
    func handle(newState: SpaceListSubSection.ListState, helper: SpaceSubSectionStateHelper) {
        listState = newState
    }
    func didShowListAfterLoading() {}

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
            return .loading
        case .synced:
            return .empty(description: BundleI18n.SKResource.Doc_Facade_EmptyShareVisit,
                          emptyType: .noContent,
                          createEnable: .just(false),
                          createButtonTitle: BundleI18n.SKResource.Doc_Facade_CreateDocument) { [weak self] button in
                guard let self = self else { return }
                // TODO: 初始化时配置好 context
                let intent = SpaceCreateIntent(context: .shared, source: .other, createButtonLocation: .blankPage)
                self.actionInput.accept(.create(with: intent, sourceView: button))
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

extension SharedSpaceSection {
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
}
