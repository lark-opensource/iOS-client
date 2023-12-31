//
//  SpaceQuickAccessSection.swift
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
import SKUIKit
import LarkContainer


public final class SpaceQuickAccessSection: SpaceListSubSection, SpaceListSectionAutoLayout, SpaceListSectionAutoDataSource, SpaceListSectionCommonDelegate {
    public let userResolver: UserResolver
    

    public let identifier: String = "quick-access"
    public var subSectionTitle: String = BundleI18n.SKResource.Doc_List_Quick_Access
    public let subSectionIdentifier: String = "pin"

    public var listTools: [SpaceListTool] {
        return [.modeSwitch(modeRelay: displayModeRelay, clickHandler: { [weak self] _ in
            self?.switchDisplayMode()
        })]
    }
    
    public var createIntent: SpaceCreateIntent {
        SpaceCreateIntent(context: .quickAccess, source: .quickAccess, createButtonLocation: .bottomRight)
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

    private let viewModel: QuickAccessViewModel
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
    
    private let isShowInDetail: Bool

    public init(userResolver: UserResolver,
                viewModel: QuickAccessViewModel,
                subTitle: String = BundleI18n.SKResource.Doc_List_Quick_Access,
                isShowInDetail: Bool = false) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        self.subSectionTitle = subTitle
        self.isShowInDetail = isShowInDetail
    }

    public func prepare() {
        setupDisplayMode()
        stateHelper.actionSignal.emit(to: actionInput).disposed(by: disposeBag)
        stateHelper.reloadSignal.emit(to: reloadInput).disposed(by: disposeBag)
        viewModel.itemsUpdated.observeOn(SerialDispatchQueueScheduler(internalSerialQueueName: "space.quickaccess.section"))
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
        tracker.reportChangeDisplayMode(newMode: newMode, subModule: .quickaccess)
    }

    public func notifyPullToRefresh() {
        viewModel.notifyPullToRefresh()
    }

    public func notifyPullToLoadMore() {
        viewModel.notifyPullToLoadMore()
    }

    public func notifySectionDidAppear() {}
    public func notifyViewDidLayoutSubviews(hostVCWidth: CGFloat) {}

    public func didShowSubSection() {
        viewModel.didBecomeActive()
        DocsLogger.info("space.quickaccess.section --- preload visable items when didShowSubSection")
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
}

extension SpaceQuickAccessSection: SpaceSubSectionLayoutDelegate {
    var layoutListState: SpaceListSubSection.ListState { listState }
    var layoutDisplayMode: SpaceListDisplayMode { displayMode }
}

extension SpaceQuickAccessSection: SpaceSectionLayout {}

extension SpaceQuickAccessSection: SpaceSubSectionDataSourceDelegate {
    var dataSourceListState: SpaceListSubSection.ListState { listState }
    var dataSourceDisplayMode: SpaceListDisplayMode { displayMode }
    var dataSourceCellTrackerModule: PageModule { tracker.module }
}

extension SpaceQuickAccessSection: SpaceSectionDataSource {}

extension SpaceQuickAccessSection: SpaceSubSectionDelegateProvider {
    var providerListState: SpaceListSubSection.ListState { listState }
    var listViewModel: SpaceListViewModel { viewModel }
    func open(newScene: Scene) {
        actionInput.accept(.newScene(newScene))
    }
}

extension SpaceQuickAccessSection: SpaceSectionDelegate {
    public func notifyDidEndDragging(willDecelerate: Bool) {
        if !willDecelerate {
            DocsLogger.info("space.quickaccess.section --- preload visable items when end dragging")
            preloadVisableItems()
        }
    }

    public func notifyDidEndDecelerating() {
        DocsLogger.info("space.quickaccess.section --- preload visable items when end decelerating")
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
                preloadKey.fromSource = PreloadFromSource(.quickAccess)
                return preloadKey
            }
            DocsLogger.info("space.quickaccess.section --- prepare to preload quickaccess \(preloadKeys.count) entries from index \(indices.first ?? 0)", component: LogComponents.preload)
            NotificationCenter.default.post(name: NSNotification.Name.Docs.addToPreloadQueue,
                                            object: nil,
                                            userInfo: [DocPreloaderManager.preloadNotificationKey: preloadKeys])
        }))
    }
}

extension SpaceQuickAccessSection: SpaceSubSectionStateProvider {
    var canReloadState: Bool { viewModel.isActive }
    func handle(newState: SpaceListSubSection.ListState, helper: SpaceSubSectionStateHelper) {
        listState = newState
    }
    func didShowListAfterLoading() {
        DocsLogger.info("space.quickaccess.section --- preload visable items when end loading")
        preloadVisableItems()
    }

    private func handle(newItems: [SpaceListItemType]) {
        let newState = newListState(from: newItems)
        stateHelper.handle(newState: newState)
    }

    private func newListState(from newItems: [SpaceListItemType]) -> ListState {
        guard newItems.isEmpty else { return .normal(itemTypes: newItems) }
        if viewModel.dataModel.listContainer.state == .restoring {
            DocsLogger.info("space.quickaccess.section --- DB data not ready, show loading")
            return .loading
        }
        guard viewModel.isReachable else { return .networkUnavailable }
        switch viewModel.serverDataState {
        case .loading:
            // 本地数据为空时，服务端请求还未结束，继续loading
            DocsLogger.info("space.quickaccess.section --- still loading server data, show loading")
            return .loading
        case .synced:
            // 服务端数据返回空，展示空白页
            return .empty(description: BundleI18n.SKResource.Doc_List_Pin_Empty_Tips,
                          emptyType: .noContent,
                          createEnable: .just(false),
                          createButtonTitle: BundleI18n.SKResource.Doc_Facade_CreateDocument) { [weak self] button in
                guard let self = self else { return }
                let intent = SpaceCreateIntent(context: .quickAccess, source: .other, createButtonLocation: .blankPage)
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

extension SpaceQuickAccessSection {
    public var iPadListHeaderSortConfig: IpadListHeaderSortConfig? {
        IpadListHeaderSortConfig(sortOption: [SpaceSortHelper.SortOption(type: .title, descending: true, allowAscending: false),
                                              SpaceSortHelper.SortOption(type: .updateTime, descending: true, allowAscending: false),
                                              SpaceSortHelper.SortOption(type: .createTime, descending: true, allowAscending: false)
                                             ],
                                 displayModeRelay: displayModeRelay,
                                 selectSortOptionDriver: .never())
    }
}
