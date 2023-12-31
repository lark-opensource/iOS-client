//
//  BitableFavoritesViewModel.swift
//  SKSpace
//
//  Created by ByteDance on 2023/10/27.
//

import Foundation
import SKCommon
import RxSwift
import RxRelay
import RxCocoa
import SKFoundation
import SwiftyJSON
import EENavigator
import SKResource

extension BitableFavoritesViewModel {
    public typealias Action = SpaceSection.Action
}

public final class BitableFavoritesViewModel: SpaceListViewModel {
    private let workQueue = DispatchQueue(label: "bitable.favorites.list.vm")

    // 表示当前列表是否正在被展示，切换至其他子列表时，isActive 需要置 false
    private(set) var isActive = false
    // 表明是否请求过服务端数据，用于解决本地为空的情况下，继续展示loading
    private(set) var serverDataState = ServerDataState.loading

    private let actionInput = PublishRelay<Action>()
    public var actionSignal: Signal<Action> {
        actionInput.asSignal()
    }

    let dataModel: FavoritesDataModel
    let filterStateRelay = BehaviorRelay<SpaceListFilterState>(value: .deactivated)
    var filterState: SpaceListFilterState { filterStateRelay.value }
    var hasActiveFilter: Bool { filterState != .deactivated }
    let homeType: SpaceHomeType
    private let itemsRelay = BehaviorRelay<[SpaceListItem]>(value: [])
    private var items: [SpaceListItem] { itemsRelay.value }

    var itemsUpdated: Observable<[SpaceListItemType]> {
        itemsRelay.skip(1).map {
            $0.map(SpaceListItemType.spaceItem(item:))
        }.asObservable()
    }

    private let reachabilityRelay = BehaviorRelay(value: true)
    private var reachabilityChanged: Observable<Bool> {
        reachabilityRelay.distinctUntilChanged().asObservable()
    }

    var isReachable: Bool { reachabilityRelay.value }

    private lazy var slideActionHelper: SpaceListSlideDelegateProxyV2 = {
        return SpaceListSlideDelegateProxyV2(helper: self)
    }()

    private var listBag = DisposeBag()
    private let disposeBag = DisposeBag()
    private(set) var tracker = SpaceSubSectionTracker(bizParameter: SpaceBizParameter(module: .favorites))

    public init(dataModel: FavoritesDataModel, homeType: SpaceHomeType = .spaceTab) {
        self.dataModel = dataModel
        self.homeType = homeType
        
        if case let .baseHomeType(context) = homeType {
            tracker = SpaceSubSectionTracker(bizParameter: SpaceBizParameter(module: .baseHomePage(context: context)))
        }
    }

    func prepare() {
        RxNetworkMonitor.networkStatus(observerObj: self)
            .map { $1 }
            .bind(to: reachabilityRelay)
            .disposed(by: disposeBag)

        reachabilityChanged.skip(1)
            .subscribe(onNext: { [weak self] reachable in
                guard let self = self else { return }
                let entries = self.dataModel.listContainer.items
                self.updateList(entries: entries)
                // 切到有网时，若 DB 没有同步成功过服务端数据，主动刷新一次
                if reachable && !self.dataModel.listContainer.synced {
                    self.dataModel.refresh().subscribe().disposed(by: self.listBag)
                }
            })
            .disposed(by: disposeBag)

        dataModel.setup()
        dataModel.itemChanged.subscribe(onNext: { [weak self] entries in
            guard let self = self else { return }
            self.updateList(entries: entries)
        })
        .disposed(by: disposeBag)

        dataModel.refresh().subscribe { [weak self] in
            guard let self = self else { return }
            let hasMore = self.dataModel.listContainer.hasMore
            self.actionInput.accept(.stopPullToLoadMore(hasMore: hasMore))
            self.serverDataState = .synced
        } onError: { [weak self] error in
            guard let self = self else { return }
            // 过滤部分特殊的错误码，避免影响loading的展示
            let errorCode = (error as NSError).code
            if errorCode == SpecialError.running.rawValue || errorCode == SpecialError.notLogged.rawValue {
                DocsLogger.info("errorCode = \(errorCode)")
                return
            }

            self.serverDataState = .fetchFailed
            // 拉取失败的情况下，不会触发 didUpdate，需要主动触发一次列表数据更新的事件
            DocsLogger.warning("fetch recent file error \(error.localizedDescription)")
            self.itemsRelay.accept(self.items)
        }
        .disposed(by: listBag)

        let newFilterState = generateFilterState()
        filterStateRelay.accept(newFilterState)
        let filterAction = dataModel.filterHelper.selectedOption.reportName
        tracker.filterAction = filterAction

        NotificationCenter.default.rx.notification(.Docs.SpaceSortFilterStateUpdated)
            .filter { [weak self] notification in
                self?.dataModel.folderKey == (notification.userInfo?["listToken"] as? DocFolderKey)
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] notification in
                guard let self else { return }
                if let filterOption = notification.userInfo?["filterOption"] as? SpaceFilterHelper.FilterOption {
                    self.dataModel.update(filterOption: filterOption)
                }
                // 收到通知 更新后后同步下 UI
                let newFilterState = self.generateFilterState()
                self.filterStateRelay.accept(newFilterState)
            })
            .disposed(by: disposeBag)
    }

    func didBecomeActive() {
        isActive = true
        actionInput.accept(.stopPullToLoadMore(hasMore: false))
        tracker.reportEnter(module: "favorite", subModule: nil, srcModule: "home")
        
        if homeType.isBaseHomeType() {
            refresh()
        }
    }

    func willResignActive() {
        isActive = false
    }
    
    func select(at index: Int, item: SpaceListItemType) {
        guard case let .spaceItem(spaceItem) = item else { return }
        let entry = spaceItem.entry
        tracker.reportClick(entry: entry, at: index, pageModule: homeType.pageModule(), pageSubModule: .favorites)
        if !isReachable, entry.canOpenWhenOffline == false {
            offlineSelect(entry: entry)
            return
        }

        let entryLists = items.compactMap { item -> SpaceEntry? in
            let entry = item.entry
            if entry.type.isUnknownType { return nil }
            return entry
        }
        entry.fromModule = "favorites"
        FileListStatistics.curFileObjToken = entry.objToken
        FileListStatistics.curFileType = entry.type
        FileListStatistics.prepareStatisticsData(.favorites)
        let body = SKEntryBody(entry)
        var context: [String: Any] = [
            SKEntryBody.fileEntryListKey: entryLists,
            SKEntryBody.fromKey: FileListStatistics.Module.favorites,
            CCMOpenTypeKey: "lark_docs_favorites"
        ]
        if case let .baseHomeType(ctx) = homeType {
            context[SKEntryBody.fromKey] = ctx.containerEnv == .larkTab ? FileListStatistics.Module.baseHomeLarkTabFavoritesV4 : FileListStatistics.Module.baseHomeWorkbenchFavoritesV4
        }
        actionInput.accept(.open(entry: body, context: context))
        if let folder = entry as? FolderEntry {
            tracker.reportEnter(folderToken: folder.objToken,
                                isShareFolder: folder.isShareFolder,
                                currentModule: "favorite",
                                currentFolderToken: nil,
                                subModule: nil)
        }
    }

    // 离线时点击某文档
    private func offlineSelect(entry: SpaceEntry) {
        guard entry.canSetManualOffline, !entry.isSetManuOffline else {
            let tips: String
            if entry.type == .file {
                tips = BundleI18n.SKResource.Doc_List_OfflineClickTips
            } else {
                tips = BundleI18n.SKResource.Doc_List_OfflineOpenDocFail
            }
            actionInput.accept(.showHUD(.tips(tips)))
            return
        }
        if entry.docsType == .file, !DriveFeatureGate.driveEnabled {
            DocsLogger.info("bitable.recent.list.vm --- drive disable by FG, forbidden offline open drive action")
            actionInput.accept(.showHUD(.tips(BundleI18n.SKResource.Drive_Drive_FileSecurityRestrictDownloadActionGeneralMessage)))
            return
        }
        actionInput.accept(.showManualOfflineSuggestion(completion: { [weak self] shouldSetManualOffline in
            guard let self = self else { return }
            guard shouldSetManualOffline else { return }
            self.slideActionHelper.toggleManualOffline(for: entry)
        }))
    }

    private func updateList(entries: [SpaceEntry]) {
        workQueue.async { [weak self] in
            guard let self = self else { return }
            // 适配Base的方图标
            var config: SpaceModelConverter.Config
            switch self.homeType{
            case .baseHomeType:
                if UserScopeNoChangeFG.QYK.btSquareIcon { config = .baseHome } else { config = .default }
            default:
                config = .default
            }
            
            let items = SpaceModelConverter.convert(entries: entries,
                                                    context: .init(sortType: .addFavoriteTime,
                                                                   folderEntry: nil,
                                                                   listSource: .favorites),
                                                    config:config,
                                                    handler: self)
            self.itemsRelay.accept(items)
        }
    }

    func notifyPullToRefresh() {
        serverDataState = .loading
        refresh()
    }
    
    func refresh() {
        dataModel.refresh().subscribe { [weak self] in
            guard let self = self else { return }
            self.serverDataState = .synced
            let total = self.dataModel.listContainer.totalCount
            self.actionInput.accept(.stopPullToRefresh(total: total))
            let hasMore = self.dataModel.listContainer.hasMore
            self.actionInput.accept(.stopPullToLoadMore(hasMore: hasMore))
        } onError: { [weak self] error in
            guard let self = self else { return }
            self.actionInput.accept(.stopPullToRefresh(total: nil))
            DocsLogger.error("bitable.favorites.list.vm --- pull to refresh failed with error", error: error)
            // show error
            self.serverDataState = .fetchFailed
            self.itemsRelay.accept(self.items)
            return
        }
        .disposed(by: listBag)
    }

    func notifyPullToLoadMore() {
        dataModel.loadMore().subscribe { [weak self] in
            guard let self = self else { return }
            let hasMore = self.dataModel.listContainer.hasMore
            self.actionInput.accept(.stopPullToLoadMore(hasMore: hasMore))
        } onError: { [weak self] error in
            guard let self = self else { return }
            if let listError = error as? FavoritesDataModel.ListError, listError == .unableToLoadMore {
                self.actionInput.accept(.stopPullToLoadMore(hasMore: false))
            } else {
                self.actionInput.accept(.stopPullToLoadMore(hasMore: true))
            }
            DocsLogger.error("bitable.favorites.list.vm --- pull to load more failed with error", error: error)
        }
        .disposed(by: listBag)
    }

    func contextMenuConfig(for entry: SpaceEntry) -> SpaceListItem.SlideConfig? {
        generateSlideConfig(for: entry)
    }
}

extension BitableFavoritesViewModel: SpaceListFilterDelegate {
    var filterEnabled: Observable<Bool> {
        reachabilityChanged
    }

    func generateSortFilterConfig() -> SpaceSortFilterConfig? {
        let filterItems = dataModel.filterHelper.legacyItemsForFilterPanel
        let defaultFilterItems = dataModel.filterHelper.defaultLegacyItemsForFilterPanel
        // 不知道为啥，收藏没有 sortItems 的配置
        return SpaceSortFilterConfig(sortItems: [],
                                     defaultSortItems: [],
                                     filterItems: filterItems,
                                     defaultFilterItems: defaultFilterItems)
    }

    private func generateFilterState() -> SpaceListFilterState {
        var filterName: String?
        if dataModel.filterHelper.changed {
            filterName = dataModel.filterHelper.selectedOption.displayName
        }
        if filterName == nil {
            return .deactivated
        } else {
            return .activated(type: filterName, sortOption: nil, descending: true)
        }
    }
}

extension BitableFavoritesViewModel: SpaceFilterPanelDelegate {
    public func filterPanel(_ panel: SpaceFilterPanelController, didConfirmWith selection: FilterItem) {
        guard let index = panel.options.firstIndex(where: { $0.filterType == selection.filterType }) else {
            assertionFailure()
            return
        }
        updateFilter(selectionIndex: index)
        let filterAction = selection.reportName
        tracker.reportFilterPanelUpdated(action: "done",
                                         filterAction: filterAction,
                                         sortAction: nil)
    }

    public func didClickResetFor(filterPanel: SpaceFilterPanelController) {
        updateFilter(selectionIndex: 0)
        let filterAction = SpaceFilterHelper.FilterOption.all.reportName
        tracker.reportFilterPanelUpdated(action: "reset",
                                         filterAction: filterAction,
                                         sortAction: nil)
    }


    private func updateFilter(selectionIndex: Int) {
        // 切换筛选、排序项时，重置一下列表请求
        listBag = DisposeBag()
        actionInput.accept(.stopPullToRefresh(total: nil))
        actionInput.accept(.stopPullToLoadMore(hasMore: false))

        dataModel.update(filterIndex: selectionIndex)
        NotificationCenter.default.post(name: .Docs.SpaceSortFilterStateUpdated,
                                        object: nil,
                                        userInfo: [
                                            "listToken": dataModel.folderKey,
                                            "filterOption": dataModel.filterHelper.selectedOption
                                        ])
        serverDataState = .loading
        dataModel.refresh().subscribe { [weak self] in
            guard let self = self else { return }
            let hasMore = self.dataModel.listContainer.hasMore
            self.actionInput.accept(.stopPullToLoadMore(hasMore: hasMore))
            self.serverDataState = .synced
        } onError: { [weak self] error in
            guard let self = self else { return }
            DocsLogger.error("bitable.favorites.list.vm --- refresh after update filter option failed", error: error)
            self.actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.Doc_Doc_NetException)))
            self.serverDataState = .fetchFailed
        }
        .disposed(by: listBag)

        let newFilterState = generateFilterState()
        filterStateRelay.accept(newFilterState)
        actionInput.accept(.stopPullToLoadMore(hasMore: true))
    }
}

extension BitableFavoritesViewModel: SpaceListItemInteractHandler {
    // 网格模式下，more 按钮
    func handleMoreAction(for entry: SpaceEntry) -> ((UIView) -> Void)? {
        let handler: (UIView) -> Void = { [weak self] view in
            guard let self = self else { return }
            if entry.secretKeyDelete == true {
                self.actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.CreationDoc_Docs_KeyInvalidCanNotOperate)))
                return
            }
            self.tracker.source = .gridMore
            var forbiddenItems: [MoreItemType] = [.delete]
            /// 收藏列表里出现的已经不存在于知识库的wiki文档，禁掉快速访问
            if entry.type == .wiki, let wikiEntry = entry as? WikiEntry, !wikiEntry.contentExistInWiki {
                forbiddenItems = [.delete, .pin, .unPin]
            }
            self.showMoreVC(for: entry, sourceView: view, forbiddenItems: forbiddenItems)
            self.tracker.reportClickGridMore(entryType: entry.type)
        }
        return handler
    }

    func handlePermissionTips(for entry: SpaceEntry) -> ((UIView) -> Void)? {
        return nil
    }

    func generateSlideConfig(for entry: SpaceEntry) -> SpaceListItem.SlideConfig? {
        let actions: [SlideAction] = [.unstar, .share, .more]
        return SpaceListItem.SlideConfig(actions: actions) { [weak self] (cell, action) in
            guard let self = self else { return }
            if entry.secretKeyDelete == true {
                self.actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.CreationDoc_Docs_KeyInvalidCanNotOperate)))
                return
            }
            self.tracker.source = .slide
            self.tracker.bizParameter.update(fileID: entry.objToken, fileType: entry.docsType, driveType: entry.fileType)
            self.tracker.reportClick(slideAction: action)
            switch action {
            case .unstar:
                self.slideActionHelper.toggleFavorites(for: entry)
            case .share:
                self.slideActionHelper.share(entry: entry, sourceView: cell, shareSource: .list)
            case .more:
                var forbiddenItems: [MoreItemType] = [.share, .delete]
                /// 收藏列表里出现的已经不存在于知识库的wiki文档，禁掉快速访问
                if entry.type == .wiki, let wikiEntry = entry as? WikiEntry, !wikiEntry.contentExistInWiki {
                    forbiddenItems = [.share, .delete, .pin, .unPin]
                }
                self.showMoreVC(for: entry, sourceView: cell, forbiddenItems: forbiddenItems)
            default:
                spaceAssertionFailure("bitable.favorites.list.vm --- unhandle slide action: \(action)")
                return
            }
        }
    }

    private func showMoreVC(for entry: SpaceEntry, sourceView: UIView, forbiddenItems: [MoreItemType]) {
        var moreProvider = SpaceMoreProviderFactory.createMoreProvider(for: entry, sourceView: sourceView, forbiddenItems: forbiddenItems, listType: .favorites)
        var listMoreItemClickTracker = entry.listMoreItemClickTracker
        if case .baseHomeType = homeType {
            moreProvider = SpaceMoreProviderFactory.createMoreProvider(for: entry,
                                                                       sourceView: sourceView,
                                                                       forbiddenItems: forbiddenItems,
                                                                       needShowItems: [.copyLink, .copyFile, .sensitivtyLabel, .pin, .unPin, .star, .unStar], listType: .favorites)
            listMoreItemClickTracker.setIsBitableHome(true)
            listMoreItemClickTracker.setSubModule(.favorites)
        }
        moreProvider.handler = slideActionHelper
        let moreVM = MoreViewModel(dataProvider: moreProvider, docsInfo: entry.transform(), moreItemClickTracker: listMoreItemClickTracker)
        let moreVC = MoreViewControllerV2(viewModel: moreVM)
        actionInput.accept(.present(viewController: moreVC, popoverConfiguration: { controller in
            controller.modalPresentationStyle = .popover
            controller.popoverPresentationController?.sourceView = sourceView
            controller.popoverPresentationController?.sourceRect = sourceView.bounds
            controller.popoverPresentationController?.permittedArrowDirections = .any
        }))
    }
}

// SlideAction
extension BitableFavoritesViewModel: SpaceListSlideDelegateHelperV2 {

    var slideActionInput: PublishRelay<SpaceSection.Action> { actionInput }
    var slideTracker: SpaceSubSectionTracker { tracker }
    var interactionHelper: SpaceInteractionHelper { dataModel.interactionHelper }
    var listType: SKObserverDataType? { dataModel.type }
    var userID: String { dataModel.currentUserID }

    func refreshForMoreAction() {
        notifyPullToRefresh()
    }

    func handleDelete(for entry: SpaceEntry) {}
}
