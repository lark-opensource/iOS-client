//
//  MyFolderListViewModel.swift
//  SKSpace
//
//  Created by Weston Wu on 2021/10/25.
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
import UniverseDesignColor
import UniverseDesignEmpty
import SKUIKit
import UniverseDesignDialog

extension MyFolderListViewModel {
    public typealias Action = SpaceSection.Action
}

public final class MyFolderListViewModel: FolderListViewModel {

    private let workQueue = DispatchQueue(label: "space.my-folder.list.vm")

    // 表示当前列表是否正在被展示，切换至其他子列表时，isActive 需要置 false
    private(set) var isActive = false

    var localDataReady: Bool { dataModel.listContainer.state != .restoring }
    // 表明是否请求过服务端数据，用于解决本地为空的情况下，继续展示loading
    private(set) var serverDataState = ServerDataState.loading

    private let actionInput = PublishRelay<Action>()
    public var actionSignal: Signal<Action> {
        actionInput.asSignal()
    }

    let dataModel: MyFolderDataModel

    let sortStateRelay = BehaviorRelay<SpaceListFilterState>(value: .deactivated)
    var sortState: SpaceListFilterState { sortStateRelay.value }
    let sortNameRelay = BehaviorRelay<String>(value: "")
    var selectSortOptionRelay = BehaviorRelay<SpaceSortHelper.SortOption?>(value: nil)
    var sortPanelDelegate: SpaceSortPanelDelegate { self }
    var hasActiveFilter: Bool { false }

    // 列表中的文档数据
    private let itemsRelay = BehaviorRelay<[SpaceListItem]>(value: [])
    private var items: [SpaceListItem] { itemsRelay.value }

    var itemsUpdated: Observable<[SpaceListItemType]> {
        itemsRelay.skip(1).map {
            $0.map(SpaceListItemType.spaceItem(item:))
        }.asObservable()
    }

    private let reachabilityRelay = BehaviorRelay(value: true)
    var reachabilityChanged: Observable<Bool> {
        reachabilityRelay.distinctUntilChanged().asObservable()
    }
    var isReachable: Bool { reachabilityRelay.value }

    var isBlank: Bool { dataModel.listContainer.isEmpty }

    var isShareFolder: Bool { false }
    
    var folderListScene: FolderListScene {
        .myFolderList
    }

    var createEnabledUpdated: Observable<Bool> { .just(true) }

    var createContext: SpaceCreateContext {
        .personalFolderRoot
    }

    var searchContext: SpaceSearchContext {
        SpaceSearchContext(searchFromType: .normal, module: .personalFolderRoot, isShareFolder: false)
    }

    var emptyImageType: UDEmptyType {
        .noContent
    }

    var emptyDescription: String {
        BundleI18n.SKResource.Doc_Facade_EmptyDocumentTips
    }

    private lazy var slideActionHelper: SpaceListSlideDelegateProxyV2 = {
        return SpaceListSlideDelegateProxyV2(helper: self)
    }()

    private let disposeBag = DisposeBag()
    private(set) var tracker = SpaceSubSectionTracker(bizParameter: SpaceBizParameter(module: .personalFolderRoot))
    public var hiddenFolderListSection: Bool { false }

    init(dataModel: MyFolderDataModel) {
        self.dataModel = dataModel
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
                    self.dataModel.refresh().subscribe().disposed(by: self.disposeBag)
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
        .disposed(by: disposeBag)

        sortNameRelay.accept(dataModel.sortHelper.selectedOption.legacyItem.fullDescription)
        selectSortOptionRelay.accept(dataModel.sortHelper.selectedOption)
        let newSortState = generateSortState()
        sortStateRelay.accept(newSortState)

        let sortAction = dataModel.sortHelper.selectedOption.type.reportName
        tracker.sortAction = sortAction
    }

    func didBecomeActive() {
        isActive = true
        actionInput.accept(.stopPullToLoadMore(hasMore: false))
    }

    func willResignActive() {
        isActive = false
    }

    func select(at index: Int, item: SpaceListItemType) {
        guard case let .spaceItem(spaceItem) = item else { return }
        let entry = spaceItem.entry
        tracker.reportClick(entry: entry, at: index)
        // 我的文件夹列表只有文件夹，文件夹离线都可点击
        let entryLists = items.compactMap { item -> SpaceEntry? in
            let entry = item.entry
            if entry.type.isUnknownType { return nil }
            return entry
        }
        entry.fromModule = "inner_folder"
        FileListStatistics.curFileObjToken = entry.objToken
        FileListStatistics.curFileType = entry.type
        FileListStatistics.prepareStatisticsData(.myFolderList)
        let body = SKEntryBody(entry)
        let context: [String: Any] = [SKEntryBody.fileEntryListKey: entryLists,
                                      SKEntryBody.fromKey: FileListStatistics.Module.personalFolder]
        actionInput.accept(.open(entry: body, context: context))
        if let folder = entry as? FolderEntry {
            tracker.reportEnter(folderToken: folder.objToken,
                                isShareFolder: folder.isShareFolder,
                                currentModule: "folder",
                                currentFolderToken: nil,
                                subModule: nil)
        }
    }

    private func updateList(entries: [SpaceEntry]) {
        workQueue.async { [weak self] in
            guard let self = self else { return }
            let items = SpaceModelConverter.convert(entries: entries,
                                                    context: .init(sortType: self.dataModel.sortHelper.selectedOption.type,
                                                                   folderEntry: nil,
                                                                   listSource: .personal),
                                                    handler: self)
            self.itemsRelay.accept(items)
        }
    }

    func notifyPullToRefresh() {
        serverDataState = .loading
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
            DocsLogger.error("space.favorites.list.vm --- pull to refresh failed with error", error: error)
            // show error
            self.serverDataState = .fetchFailed
            self.itemsRelay.accept(self.items)
        }
        .disposed(by: disposeBag)
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
            DocsLogger.error("space.favorites.list.vm --- pull to load more failed with error", error: error)
        }
        .disposed(by: disposeBag)
    }

    func contextMenuConfig(for entry: SpaceEntry) -> SpaceListItem.SlideConfig? {
        generateSlideConfig(for: entry)
    }
}

extension MyFolderListViewModel: SpaceSortPanelDelegate {

    func generateSortItems() -> ([SortItem], Bool)? {
        (dataModel.sortHelper.legacyItemsForSortPanel, dataModel.sortHelper.changed)
    }

    private func generateSortState() -> SpaceListFilterState {
        if dataModel.sortHelper.changed {
            let sortOption = dataModel.sortHelper.selectedOption
            return .activated(type: nil, sortOption: sortOption.type.displayName, descending: sortOption.descending)
        } else {
            return .deactivated
        }
    }

    public func sortPanel(_ panel: SpaceSortPanelController, didSelect selectionIndex: Int, descending: Bool) {
        dataModel.update(sortIndex: selectionIndex, descending: descending)
        sortOptionDidChanged()
    }

    public func sortPanelDidClickReset(_ panel: SpaceSortPanelController) {
        dataModel.update(sortOption: dataModel.sortHelper.defaultOption)
        sortOptionDidChanged()
    }

    private func sortOptionDidChanged() {
        serverDataState = .loading
        dataModel.refresh().subscribe { [weak self] in
            guard let self = self else { return }
            let hasMore = self.dataModel.listContainer.hasMore
            self.actionInput.accept(.stopPullToLoadMore(hasMore: hasMore))
            self.serverDataState = .synced
        } onError: { [weak self] error in
            guard let self = self else { return }
            DocsLogger.error("space.recent.vm --- pull to refresh failed with error", error: error)
            self.actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.Doc_Doc_NetException)))
            self.serverDataState = .fetchFailed
        }
        .disposed(by: disposeBag)

        sortNameRelay.accept(dataModel.sortHelper.selectedOption.legacyItem.fullDescription)
        selectSortOptionRelay.accept(dataModel.sortHelper.selectedOption)
        let newSortState = generateSortState()
        sortStateRelay.accept(newSortState)
        actionInput.accept(.stopPullToLoadMore(hasMore: true))
        let sortOption = dataModel.sortHelper.selectedOption
        tracker.reportFilterPanelUpdated(action: "",
                                         filterAction: nil,
                                         sortAction: sortOption.type.reportName)
        DocsTracker.reportSpaceHeaderFilterClick(by: nil,
                                                 by: sortOption.legacyItem,
                                                 lastActionName: "",
                                                 eventType: DocsTracker.EventType.spaceFolderView,
                                                 bizParms: tracker.bizParameter)
    }
}

extension MyFolderListViewModel: SpaceListItemInteractHandler {

    func folderMoreAction() -> ((UIView) -> Void)? { nil }
    // 网格模式下，more 按钮
    func handleMoreAction(for entry: SpaceEntry) -> ((UIView) -> Void)? {
        let handler: (UIView) -> Void = { [weak self] view in
            guard let self = self else { return }
            if entry.secretKeyDelete == true {
                self.actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.CreationDoc_Docs_KeyInvalidCanNotOperate)))
                return
            }
            self.tracker.source = .gridMore
            self.showMoreVC(for: entry, sourceView: view, forbiddenItems: [])
            self.tracker.reportClickGridMore(entryType: entry.type)
            DocsTracker.reportSpaceFolderClick(params: .more(isBlank: false,
                                                             isShareFolder: false),
                                               bizParms: self.tracker.bizParameter)
        }
        return handler
    }

    // 我的文件夹列表不存在此场景
    func handlePermissionTips(for entry: SpaceEntry) -> ((UIView) -> Void)? {
        nil
    }

    func generateSlideConfig(for entry: SpaceEntry) -> SpaceListItem.SlideConfig? {
        SpaceListItem.SlideConfig(actions: [.delete, .share, .more]) { [weak self] (cell, action) in
            guard let self = self else { return }
            if entry.secretKeyDelete == true {
                self.actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.CreationDoc_Docs_KeyInvalidCanNotOperate)))
                return
            }
            self.tracker.source = .slide
            self.tracker.bizParameter.update(fileID: entry.objToken, fileType: entry.docsType, driveType: entry.fileType)
            self.tracker.reportClick(slideAction: action)
            switch action {
            case .readyToDelete, .delete:
                self.handleDelete(for: entry)
            case .share:
                self.slideActionHelper.share(entry: entry, sourceView: cell, shareSource: .list)
            case .more:
                self.showMoreVC(for: entry, sourceView: cell, forbiddenItems: [.share, .delete])
            default:
                spaceAssertionFailure("space.my-folder.list.vm --- unhandle slide action: \(action)")
                return
            }
        }
    }

    private func showMoreVC(for entry: SpaceEntry, sourceView: UIView, forbiddenItems: [MoreItemType]) {
        var moreProvider = SpaceMoreProviderFactory.createMoreProvider(for: entry, sourceView: sourceView, forbiddenItems: forbiddenItems, listType: .myFolder)
        moreProvider.handler = slideActionHelper
        let moreVM = MoreViewModel(dataProvider: moreProvider, docsInfo: entry.transform(), moreItemClickTracker: entry.listMoreItemClickTracker)
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
extension MyFolderListViewModel: SpaceListSlideDelegateHelperV2 {

    func refreshForMoreAction() {
        notifyPullToRefresh()
    }

    var slideActionInput: PublishRelay<SpaceSection.Action> { actionInput }
    var slideTracker: SpaceSubSectionTracker { tracker }
    var interactionHelper: SpaceInteractionHelper { dataModel.interactionHelper }
    var listType: SKObserverDataType? { dataModel.type }
    var userID: String { dataModel.currentUserID }

    func handleDelete(for entry: SpaceEntry) {
        didSelectDeleteAction(file: entry, completion: { [weak self] confirm in
            guard let self = self, confirm else { return }
            self.deleteFile(entry)
        })
    }
}

extension MyFolderListViewModel {

    func didSelectDeleteAction(file: SpaceEntry, completion: @escaping ((Bool) -> Void)) {
        if slideActionHelper.checkIsColorfulEgg(file: file) {
            let navi = UINavigationController(rootViewController: DocsSercetDebugViewController())
            actionInput.accept(.present(viewController: navi, popoverConfiguration: nil))
            return
        }

        let fileName = file.name
        let title = BundleI18n.SKResource.Doc_List_Remove_Item(fileName)
        let content = BundleI18n.SKResource.Doc_List_Remove_Item_Confirm

        let config = UDDialogUIConfig()
        config.contentMargin = .zero
        let dialog = UDDialog(config: config)
        dialog.setTitle(text: title, checkButton: false)
        dialog.setContent(text: content, checkButton: false)
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel, dismissCompletion: {
            completion(false)
        })
        dialog.addDestructiveButton(text: BundleI18n.SKResource.Doc_Facade_Delete, dismissCompletion: {
            completion(true)
        })
        actionInput.accept(.present(viewController: dialog, popoverConfiguration: nil))
    }

    func deleteFile(_ file: SpaceEntry) {
        guard isReachable else {
            actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.CreationMobile_Docs_OffLineDelete_Toast)))
            return
        }
        actionInput.accept(.showHUD(.customLoading(BundleI18n.SKResource.CreationMobile_Recent_Deleting_Toast)))
        dataModel.removeFromList(nodeToken: file.objToken).subscribe { [weak self] in
            guard let self = self else { return }
            self.actionInput.accept(.hideHUD)
            self.actionInput.accept(.showHUD(.success(BundleI18n.SKResource.Doc_Facade_DeleteSuccessfullyToastTip)))
        } onError: { [weak self] error in
            guard let self = self else { return }
            self.actionInput.accept(.hideHUD)
            DocsLogger.error("space.recent.list.vm --- failed to delete origin file", error: error)
            if let docsError = error as? DocsNetworkError, docsError.code == .cacDeleteBlocked {
                DocsLogger.info("cac delete blocked, should not show tips")
                return
            }
            if let docsError = error as? DocsNetworkError,
            let message = docsError.code.errorMessage {
                self.actionInput.accept(.showHUD(.failure(message)))
            } else {
                self.actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.Doc_Facade_DeleteFailToastTip)))
            }
        }
        .disposed(by: disposeBag)
    }
}
