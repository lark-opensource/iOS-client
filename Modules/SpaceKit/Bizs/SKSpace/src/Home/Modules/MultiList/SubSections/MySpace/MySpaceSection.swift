//
//  MySpaceSection.swift
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
import UniverseDesignToast
import SKUIKit
import SKInfra
import LarkContainer

public final class MySpaceSection: SpaceListSubSection, SpaceListSectionAutoLayout, SpaceListSectionAutoDataSource, SpaceListSectionCommonDelegate {

    public let identifier: String = "my-space"
    public var subSectionTitle: String {
        if isShowInDetail {
            return BundleI18n.SKResource.LarkCCM_NewCM_MyFolder_Menu
        } else {
            return BundleI18n.SKResource.Doc_List_Create_By_Me
        }
    }
    public let subSectionIdentifier: String = "personal"

    public var listTools: [SpaceListTool] {
        let sortTool: SpaceListTool = .sort(stateRelay: viewModel.sortStateRelay,
                                            titleRelay: viewModel.sortNameRelay,
                                            isEnabled: viewModel.reachabilityChanged,
                                            clickHandler: { [weak self] view in
                                          self?.changeSortState(sortView: view)
                                      })
        let filterTool: SpaceListTool = .filter(stateRelay: viewModel.filterStateRelay,
                                                isEnabled: viewModel.reachabilityChanged,
                                                clickHandler: { [weak self] view in
                                                    self?.changeFilterState(filterView: view)
                                                })

        let modeSwitchTool: SpaceListTool = .modeSwitch(modeRelay: displayModeRelay, clickHandler: { [weak self] _ in
                                            self?.switchDisplayMode()
                                                })

        if SettingConfig.singleContainerEnable {
            return [sortTool, modeSwitchTool]
        } else {
            return [sortTool, filterTool, modeSwitchTool]
        }
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

    private let viewModel: MySpaceViewModel
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
            let firstSortTypeRelay = BehaviorRelay<SpaceSortHelper.SortType>(value: .updateTime)
            let secondSortTypeRelay = BehaviorRelay<SpaceSortHelper.SortType>(value: .createTime)
            viewModel.sortSelectOptionRelay.compactMap { option in
                guard let option else { return nil }
                if option.type == .title { return nil }
                return option.type
            }.bind(to: secondSortTypeRelay).disposed(by: disposeBag)
            
            return IpadSpaceSubSectionDataSourceHelper(delegate: self,
                                                       firstSortTypeRelay: firstSortTypeRelay,
                                                       secondSortTypeRelay: secondSortTypeRelay)
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

    private let createContext: SpaceCreateContext

    // 同步获取当前可见的 item 下标，用于 Rust 列表自动刷新的判断
    public var visableIndicesHelper: (() -> [Int])?
    // 是否在ipad上打开
    private let isShowInDetail: Bool

    public let userResolver: UserResolver
    public init(userResolver: UserResolver,
                viewModel: MySpaceViewModel,
                createContext: SpaceCreateContext,
                isShowInDetail: Bool = false) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        self.createContext = createContext
        self.isShowInDetail = isShowInDetail
    }

    public func prepare() {
        setupDisplayMode()
        stateHelper.actionSignal.emit(to: actionInput).disposed(by: disposeBag)
        stateHelper.reloadSignal.emit(to: reloadInput).disposed(by: disposeBag)
        viewModel.itemsUpdated.observeOn(SerialDispatchQueueScheduler(internalSerialQueueName: "space.my-space.section"))
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
        DocsTracker.reportSpacePersonalPageClick(params: .filter)
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
        DocsTracker.reportSpacePersonalPageClick(params: .filter)
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

    public func reportClick(fromSubSectionId previousSubSectionId: String) {
        guard UserScopeNoChangeFG.WWJ.newSpaceTabEnable else {
            DocsLogger.debug("New cloud drive is not enabled")
            return
        }

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
        DocsTracker.reportNewDrivePageClick(params: params, bizParms: bizParms)
    }

    public func notifySectionDidAppear() {
        NotificationCenter.default.post(name: .Docs.notifySelectedSpaceEntarnce, object: (SpaceEntranceSection.EntranceIdentifier.ipadCloudDriver, true))
    }
    
    public func notifySectionWillDisappear() {
        NotificationCenter.default.post(name: .Docs.notifySelectedSpaceEntarnce, object: (SpaceEntranceSection.EntranceIdentifier.ipadCloudDriver, false))
    }
    
    deinit {
        NotificationCenter.default.post(name: .Docs.notifySelectedSpaceEntarnce, object: (SpaceEntranceSection.EntranceIdentifier.ipadCloudDriver, false))
    }
}

extension MySpaceSection: SpaceSubSectionLayoutDelegate {
    var layoutListState: SpaceListSubSection.ListState { listState }
    var layoutDisplayMode: SpaceListDisplayMode { displayMode }
}

extension MySpaceSection: SpaceSectionLayout {}

extension MySpaceSection: SpaceSubSectionDataSourceDelegate {
    var dataSourceListState: SpaceListSubSection.ListState { listState }
    var dataSourceDisplayMode: SpaceListDisplayMode { displayMode }
    var dataSourceCellTrackerModule: PageModule { tracker.module }
}

extension MySpaceSection: SpaceSectionDataSource {}

extension MySpaceSection: SpaceSubSectionDelegateProvider {
    var providerListState: SpaceListSubSection.ListState { listState }
    var listViewModel: SpaceListViewModel { viewModel }
    func open(newScene: Scene) {
        actionInput.accept(.newScene(newScene))
    }
}
extension MySpaceSection: SpaceSectionDelegate {}

extension MySpaceSection: SpaceSubSectionStateProvider {
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
            DocsLogger.info("space.my-space.section --- DB data not ready, show loading")
            return .loading
        }
        guard viewModel.isReachable else { return .networkUnavailable }
        switch viewModel.serverDataState {
        case .loading:
            return .loading
        case .synced:
            let emptyTip: String
            if viewModel.hasActiveFilter {
                emptyTip = BundleI18n.SKResource.Doc_Facade_FilterEmptyDocTips
            } else {
                emptyTip = BundleI18n.SKResource.Doc_Facade_EmptyDocumentTips
            }
            return .empty(description: emptyTip,
                          emptyType: .documentDefault,
                          createEnable: .just(true),
                          createButtonTitle: BundleI18n.SKResource.Doc_Facade_CreateDocument) { [weak self] button in
                guard let self = self else { return }
                // TODO: 初始化时配置好 context
                let intent = SpaceCreateIntent(context: self.createContext, source: .other, createButtonLocation: .blankPage)
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

// Ipad相关
extension MySpaceSection {
    public var iPadListHeaderSortConfig: IpadListHeaderSortConfig? {
        let selectOptionDriver: Driver<(IpadSpaceSubListHeaderView.Index, SpaceSortHelper.SortOption)>
        selectOptionDriver = viewModel.sortSelectOptionRelay
            .asDriver(onErrorJustReturn: viewModel.dataModel.sortHelper.selectedOption)
            .compactMap { option in
                guard let option else { return nil }
                var index: IpadSpaceSubListHeaderView.Index
                if option.type == .title {
                    index = .first
                } else if option.type == .updateTime {
                    index = .second
                } else {
                    index = .thrid
                }
                return (index, option)
            }
        
        return IpadListHeaderSortConfig(sortOption: SpaceSortHelper.personalFileV2.options,
                                        displayModeRelay: displayModeRelay,
                                        selectSortOptionDriver: selectOptionDriver)
    }
    
    public var createIntent: SpaceCreateIntent {
        SpaceCreateIntent(context: self.createContext, source: .other, createButtonLocation: .bottomRight)
    }
}
