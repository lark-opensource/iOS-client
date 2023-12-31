//
//  SpaceFavoritesSection.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/18.
//

import UIKit
import RxSwift
import RxRelay
import RxCocoa
import SKCommon
import SKFoundation
import SKResource
import SKUIKit
import UniverseDesignColor
import UniverseDesignEmpty
import LarkSceneManager
import LarkContainer

public final class SpaceFavoritesSection: SpaceListSubSection, SpaceListSectionAutoLayout, SpaceListSectionAutoDataSource, SpaceListSectionCommonDelegate {
    
    public let identifier: String = "favorites"
    public let subSectionTitle: String
    public let subSectionIdentifier: String = "favorite"
    
    public var listTools: [SpaceListTool] {
        var listTools: [SpaceListTool] = []
        if !homeType.isBaseHomeType() {
            listTools.append(.filter(stateRelay: viewModel.filterStateRelay,
                                     isEnabled: viewModel.filterEnabled,
                                     clickHandler: { [weak self] view in
                self?.changeFilterState(filterView: view)
            }))
        }
        listTools.append(.modeSwitch(modeRelay: displayModeRelay, clickHandler: { [weak self] _ in
            self?.switchDisplayMode()
        }))
        return listTools
    }
    
    public var iPadListHeaderSortConfig: IpadListHeaderSortConfig? {
        IpadListHeaderSortConfig(sortOption: [SpaceSortHelper.SortOption(type: .title, descending: true, allowAscending: false),
                                              SpaceSortHelper.SortOption(type: .owner, descending: true, allowAscending: false),
                                              SpaceSortHelper.SortOption(type: .addFavoriteTime, descending: true, allowAscending: false)
                                             ],
                                 displayModeRelay: displayModeRelay,
                                 selectSortOptionDriver: .just((.thrid, SpaceSortHelper.SortOption(type: .addFavoriteTime, descending: true, allowAscending: false))))
    }
    
    public var createIntent: SpaceCreateIntent {
        SpaceCreateIntent(context: .favorites, source: .favorites, createButtonLocation: .bottomRight)
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

    private let viewModel: FavoritesViewModel
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
    
    private let homeType: SpaceHomeType
    
    private let isShowInDetail: Bool

    public init(viewModel: FavoritesViewModel, homeType: SpaceHomeType, isShowInDetail: Bool = false) {
        self.viewModel = viewModel
        self.homeType = homeType
        self.isShowInDetail = isShowInDetail
        if case .baseHomeType = homeType {
            subSectionTitle = BundleI18n.SKResource.Bitable_Workspace_Favorites_Tab
        } else {
            if isShowInDetail {
                subSectionTitle = BundleI18n.SKResource.Doc_List_MainTabHomeFavorite
            } else {
                subSectionTitle = SpaceSortHelper.SortOption(type: .addFavoriteTime, descending: true, allowAscending: false)
                    .legacyItem.fullDescription
            }
        }
    }

    public func prepare() {
        setupDisplayMode()
        stateHelper.actionSignal.emit(to: actionInput).disposed(by: disposeBag)
        stateHelper.reloadSignal.emit(to: reloadInput).disposed(by: disposeBag)
        viewModel.itemsUpdated.observeOn(SerialDispatchQueueScheduler(internalSerialQueueName: "space.favorite.section"))
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
        tracker.reportChangeDisplayMode(newMode: newMode, subModule: .favorites)
    }

    private func changeFilterState(filterView: UIView) {
        guard let config = viewModel.generateSortFilterConfig() else {
            DocsLogger.error("space.favorites.section --- unable to get sort filter config")
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
    }

    public func notifyPullToRefresh() {
        viewModel.notifyPullToRefresh()
    }

    public func notifyPullToLoadMore() {
        viewModel.notifyPullToLoadMore()
    }

    public func notifySectionDidAppear() {
        if homeType.isBaseHomeType() {
            viewModel.refresh()
        }
    }
    
    public func didShowSubSection() {
        viewModel.didBecomeActive()
        switch listState {
        case .empty, .loading, .networkUnavailable:
            actionInput.accept(.stopPullToLoadMore(hasMore: false))
        default:
            break
        }
        DocsLogger.info("space.favorites.section --- preload visable items when didShowSubSection")
        preloadVisableItems()
    }
    public func willHideSubSection() {
        viewModel.willResignActive()
    }
}

extension SpaceFavoritesSection: SpaceSubSectionLayoutDelegate {
    var layoutListState: SpaceListSubSection.ListState { listState }
    var layoutDisplayMode: SpaceListDisplayMode { displayMode }
}

extension SpaceFavoritesSection: SpaceSectionLayout {}

extension SpaceFavoritesSection: SpaceSubSectionDataSourceDelegate {
    var dataSourceListState: SpaceListSubSection.ListState { listState }
    var dataSourceDisplayMode: SpaceListDisplayMode { displayMode }
    var dataSourceCellTrackerModule: PageModule { tracker.module }
}

extension SpaceFavoritesSection: SpaceSectionDataSource {}

extension SpaceFavoritesSection: SpaceSubSectionDelegateProvider {
    var providerListState: SpaceListSubSection.ListState { listState }
    var listViewModel: SpaceListViewModel { viewModel }
    func open(newScene: Scene) {
        actionInput.accept(.newScene(newScene))
    }
}

extension SpaceFavoritesSection: SpaceSectionDelegate {

    public func notifyDidEndDragging(willDecelerate: Bool) {
        if !willDecelerate {
            DocsLogger.info("space.favorites.section --- preload visable items when end dragging")
            preloadVisableItems()
        }
    }

    public func notifyDidEndDecelerating() {
        DocsLogger.info("space.favorites.section --- preload visable items when end decelerating")
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
            DocsLogger.info("space.favorites.section --- prepare to preload recent \(preloadKeys.count) entries from index \(indices.first ?? 0)", component: LogComponents.preload)
            NotificationCenter.default.post(name: NSNotification.Name.Docs.addToPreloadQueue,
                                            object: nil,
                                            userInfo: [DocPreloaderManager.preloadNotificationKey: preloadKeys])
        }))
    }
}

extension SpaceFavoritesSection: SpaceSubSectionStateProvider {
    var canReloadState: Bool { viewModel.isActive }
    func handle(newState: SpaceListSubSection.ListState, helper: SpaceSubSectionStateHelper) {
        listState = newState
    }
    func didShowListAfterLoading() {
        preloadVisableItems()
    }

    private func handle(newItems: [SpaceListItemType]) {
        let newState = newListState(from: newItems)
        stateHelper.handle(newState: newState)
    }

    private func newListState(from newItems: [SpaceListItemType]) -> ListState {
        guard newItems.isEmpty else { return .normal(itemTypes: newItems) }
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        guard SKDataManager.shared.dbDataHadReady == true else {
            DocsLogger.info("space.favorites.section --- DB data not ready, show loading")
            return .loading
        }
        guard viewModel.isReachable else { return .networkUnavailable }
        switch viewModel.serverDataState {
        case .loading:
            // 本地数据为空时，服务端请求还未结束，继续loading
            DocsLogger.info("space.favorites.section --- still loading server data, show loading")
            return .loading
        case .synced:
            // 服务端数据返回空，展示空白页
            return .empty(description: BundleI18n.SKResource.Doc_Facade_NoStar,
                          emptyType: .noContent,
                          createEnable: .just(false),
                          createButtonTitle: BundleI18n.SKResource.Doc_Facade_CreateDocument) { [weak self] button in
                guard let self = self else { return }
                let intent = SpaceCreateIntent(context: .favorites, source: .other, createButtonLocation: .blankPage)
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
