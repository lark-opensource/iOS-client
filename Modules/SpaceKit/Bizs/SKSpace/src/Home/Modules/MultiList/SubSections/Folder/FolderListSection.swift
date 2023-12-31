//
//  FolderListSection.swift
//  SKECM
//
//  Created by Weston Wu on 2021/3/25.

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
import LarkContainer
import SKInfra

class FolderListSection: SpaceListSubSection, SpaceListSectionAutoLayout, SpaceListSectionAutoDataSource, SpaceListSectionCommonDelegate {

    let identifier: String = "share-folder"
    var subSectionTitle: String {
        if viewModel.folderListScene == .shareFolderList {
            return BundleI18n.SKResource.Doc_List_Shared_Folder
        } else {
            return BundleI18n.SKResource.LarkCCM_NewCM_Mobile_DocList_Title
        }
    }
    let subSectionIdentifier: String = "share-folder"

    var listTools: [SpaceListTool] {
        let tools: [SpaceListTool] = [
            .sort(stateRelay: viewModel.sortStateRelay,
                  titleRelay: viewModel.sortNameRelay,
                  isEnabled: viewModel.reachabilityChanged,
                  clickHandler: { [weak self] view in
                self?.changeSortState(sortView: view)
            }),
            .modeSwitch(modeRelay: displayModeRelay, clickHandler: { [weak self] _ in
                self?.switchDisplayMode()
            })
        ]
        return tools
    }

    var navTools: [SpaceListTool] {
        var tools: [SpaceListTool] = []
        if let moreAction = viewModel.folderMoreAction() {
            tools.insert(.more(isEnabled: viewModel.reachabilityChanged, clickHandler: moreAction), at: 0)
        }
        return tools
    }
    
    // iPad相关
    public var iPadListHeaderSortConfig: IpadListHeaderSortConfig? {
        let selectSortOptionDriver: Driver<(IpadSpaceSubListHeaderView.Index, SpaceSortHelper.SortOption)>
        selectSortOptionDriver = viewModel.selectSortOptionRelay
            .asDriver(onErrorJustReturn: SpaceSortHelper.SortOption(type: .title, descending: true, allowAscending: true))
            .compactMap { option  in
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
        
        return IpadListHeaderSortConfig(sortOption: [SpaceSortHelper.SortOption(type: .title, descending: true, allowAscending: true),
                                                     SpaceSortHelper.SortOption(type: .updateTime, descending: true, allowAscending: true),
                                                     SpaceSortHelper.SortOption(type: .createTime, descending: true, allowAscending: true)],
                                        displayModeRelay: displayModeRelay,
                                        selectSortOptionDriver: selectSortOptionDriver)
    }
    
    public var createIntent: SpaceCreateIntent {
        SpaceCreateIntent(context: viewModel.createContext, source: .other, createButtonLocation: .bottomRight)
    }

    private let displayModeRelay = BehaviorRelay<SpaceListDisplayMode>(value: .list)
    private var displayMode: SpaceListDisplayMode { displayModeRelay.value }

    private let reloadInput = PublishRelay<ReloadAction>()
    var reloadSignal: Signal<ReloadAction> {
        reloadInput.asSignal()
    }

    private let actionInput = PublishRelay<Action>()
    var actionSignal: Signal<Action> {
        actionInput.asSignal()
    }

    private var listState = ListState.loading

    private let viewModel: FolderListViewModel
    private var tracker: SpaceSubSectionTracker { viewModel.tracker }
    private lazy var stateHelper: SpaceSubSectionStateHelper = {
        let differ = SpaceListDifferFactory.createListStateDiffer()
        return SpaceSubSectionStateHelper(differ: differ,
                                          listID: identifier,
                                          stateProvider: self)
    }()

    private(set) lazy var sectionLayoutHelper: SpaceListSectionLayoutHelper = {
        if isShowInDetail {
            return IpadSpaceSubSectionLayoutHelper(delegate: self)
        } else {
            return SpaceSubSectionLayoutHelper(delegate: self)
        }
    }()

    private(set) lazy var sectionDataSourceHelper: SpaceListSectionDataSourceHelper = {
        if isShowInDetail {
            let firstSortTypeRelay = BehaviorRelay<SpaceSortHelper.SortType>(value: .updateTime)
            let secondSortTypeRelay = BehaviorRelay<SpaceSortHelper.SortType>(value: .createTime)
            viewModel.selectSortOptionRelay.compactMap { option in
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

    private(set) lazy var sectionDelegateProxy: SpaceListSectionDelegateProxy = {
        if isShowInDetail {
            return IpadSpaceSubSectionDelegateHelper(provider: self)
        } else {
            return SpaceSubSectionDelegateHelper(provider: self)
        }
    }()

    private let disposeBag = DisposeBag()

    private let isShowInDetail: Bool
    
    public let userResolver: UserResolver
    init(userResolver: UserResolver, viewModel: FolderListViewModel, isShowInDetail: Bool = false) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        self.isShowInDetail = isShowInDetail
    }

    func prepare() {
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
        guard let (options, changed) = viewModel.generateSortItems(), !options.isEmpty else {
            DocsLogger.error("space.recent.section --- unable to get sort filter config")
            return
        }
        guard viewModel.isReachable else {
            actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.Doc_Facade_Offline)))
            return
        }
        let selectedIndex = options.firstIndex(where: \.isSelected) ?? 0
        let panelController = SpaceSortPanelController(options: options, initialSelection: selectedIndex, canReset: changed)
        panelController.delegate = viewModel.sortPanelDelegate
        panelController.setupPopover(sourceView: sortView, direction: .any)
        panelController.popoverPresentationController?.sourceRect = sortView.bounds.inset(by: UIEdgeInsets(top: -4, left: -4, bottom: -4, right: -4)) // 向外偏移一点
        panelController.dismissalStrategy = .larkSizeClassChanged
        actionInput.accept(.present(viewController: panelController, popoverConfiguration: nil))
        tracker.reportClickFilterPanel()
        DocsTracker.reportSpaceFolderClick(params: .filter(isBlank: viewModel.isBlank, isShareFolder: viewModel.isShareFolder), bizParms: tracker.bizParameter)
        DocsTracker.reportSpaceHeaderFilterView(bizParms: tracker.bizParameter)
    }

    func notifyPullToRefresh() {
        viewModel.notifyPullToRefresh()
    }

    func notifyPullToLoadMore() {
        viewModel.notifyPullToLoadMore()
    }

    func didShowSubSection() {
        viewModel.didBecomeActive()
        switch listState {
        case .empty, .loading, .networkUnavailable:
            actionInput.accept(.stopPullToLoadMore(hasMore: false))
        default:
            break
        }
    }
    func willHideSubSection() {
        viewModel.willResignActive()
    }

    func reportClick(fromSubSectionId previousSubSectionId: String) {
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
}

extension FolderListSection: SpaceSubSectionLayoutDelegate {
    var layoutListState: SpaceListSubSection.ListState { listState }
    var layoutDisplayMode: SpaceListDisplayMode { displayMode }
}

extension FolderListSection: SpaceSectionLayout {}

extension FolderListSection: SpaceSubSectionDataSourceDelegate {
    var dataSourceListState: SpaceListSubSection.ListState { listState }
    var dataSourceDisplayMode: SpaceListDisplayMode { displayMode }
    var dataSourceCellTrackerModule: PageModule { tracker.module }
}

extension FolderListSection: SpaceSectionDataSource {}

extension FolderListSection: SpaceSubSectionDelegateProvider {
    var providerListState: SpaceListSubSection.ListState { listState }
    var listViewModel: SpaceListViewModel { viewModel }
    func open(newScene: Scene) {
        actionInput.accept(.newScene(newScene))
    }
}

extension FolderListSection: SpaceSectionDelegate {}

extension FolderListSection: SpaceSubSectionStateProvider {
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
        guard viewModel.localDataReady else {
            DocsLogger.info("space.folder.section --- DB data not ready, show loading")
            return .loading
        }
        guard viewModel.isReachable else { return .networkUnavailable }
        switch viewModel.serverDataState {
        case .loading:
            // 本地数据为空时，服务端请求还未结束，继续loading
            DocsLogger.info("space.folder.section --- still loading server data, show loading")
            return .loading
        case .synced:
            // 服务端数据返回空，展示空白页
            if viewModel.hiddenFolderListSection {
                return .none
            }
            return .empty(description: viewModel.emptyDescription,
                          emptyType: viewModel.emptyImageType,
                          createEnable: viewModel.createEnabledUpdated,
                          createButtonTitle: BundleI18n.SKResource.Doc_Facade_CreateDocument) { [weak self] button in
                guard let self = self else { return }
                let intent = SpaceCreateIntent(context: self.viewModel.createContext, source: .other, createButtonLocation: .blankPage)
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
