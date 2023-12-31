//
//  ShareFolderListViewModel.swift
//  SKSpace
//
//  Created by Weston Wu on 2021/10/26.
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
import SpaceInterface
import SKInfra

extension ShareFolderListViewModel {
    typealias Action = SpaceSection.Action
}

class ShareFolderListViewModel: FolderListViewModel {

    private let workQueue = DispatchQueue(label: "space.share-folder.list.vm")

    // 表示当前列表是否正在被展示，切换至其他子列表时，isActive 需要置 false
    private(set) var isActive = false

    var localDataReady: Bool { dataModel.listContainer.state != .restoring }
    // 表明是否请求过服务端数据，用于解决本地为空的情况下，继续展示loading
    private(set) var serverDataState = ServerDataState.loading

    private let actionInput = PublishRelay<Action>()
    var actionSignal: Signal<Action> {
        actionInput.asSignal()
    }

    let dataModel: ShareFolderDataModel

    let sortStateRelay = BehaviorRelay<SpaceListFilterState>(value: .deactivated)
    var sortState: SpaceListFilterState { sortStateRelay.value }
    var sortNameRelay = BehaviorRelay<String>(value: "")
    var selectSortOptionRelay = BehaviorRelay<SpaceSortHelper.SortOption?>(value: nil)
    var sortPanelDelegate: SpaceSortPanelDelegate { self }
    var hasActiveFilter: Bool { false }
    // 列表中的文档数据
    private let itemsRelay = BehaviorRelay<[SpaceListItem]>(value: [])
    private var items: [SpaceListItem] { itemsRelay.value }

    // 为了适配 隐藏文件夹分栏等特殊 cell，这里需要包装一层，和列表展示的数据对应
    private let itemTypesRelay = BehaviorRelay<[SpaceListItemType]>(value: [])
    private var itemTypes: [SpaceListItemType] { itemTypesRelay.value }
    var itemsUpdated: Observable<[SpaceListItemType]> {
        itemTypesRelay.skip(1).asObservable()
    }

    private let reachabilityRelay = BehaviorRelay(value: true)
    var reachabilityChanged: Observable<Bool> {
        reachabilityRelay.distinctUntilChanged().asObservable()
    }
    
    var hiddenFolderVisableRelay: BehaviorRelay<Bool> {
        dataModel.hiddenFolderVisableRelay
    }
    
    var hasHiddenFolderEntrance: Bool {
        dataModel.hiddenFolderVisableRelay.value
    }
    var isReachable: Bool { reachabilityRelay.value }

    var isBlank: Bool { dataModel.listContainer.isEmpty }

    var isShareFolder: Bool { false }
    
    var folderListScene: FolderListScene {
        .shareFolderList
    }

    var createContext: SpaceCreateContext {
        .sharedFolderRoot
    }

    var searchContext: SpaceSearchContext {
        SpaceSearchContext(searchFromType: .normal, module: .sharedFolderRoot, isShareFolder: false)
    }

    var createEnabledUpdated: Observable<Bool> {
        .just(false)
    }

    var emptyDescription: String {
        BundleI18n.SKResource.Doc_List_NoSharedFolder
    }

    var emptyImageType: UDEmptyType {
        .noContent
    }

    private lazy var slideActionHelper: SpaceListSlideDelegateProxyV2 = {
        return SpaceListSlideDelegateProxyV2(helper: self)
    }()

    public var hiddenFolderListSection: Bool {
        // 只在共享文件夹列表2.0下处理
        if dataModel.apiType == .newShareFolder {
            return items.isEmpty && hasHiddenFolderEntrance
        }
        return false
    }

    private(set) var tracker: SpaceSubSectionTracker
    private let disposeBag = DisposeBag()

    init(dataModel: ShareFolderDataModel) {
        self.dataModel = dataModel

        let pageModule: PageModule = {
            if UserScopeNoChangeFG.WWJ.newSpaceTabEnable {
                return .newDrive(.shared)
            }
            return .sharedFolderRoot
        }()
        self.tracker = SpaceSubSectionTracker(bizParameter: SpaceBizParameter(module: pageModule))
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

        updateSortState()
        NotificationCenter.default.rx.notification(.Docs.SpaceSortFilterStateUpdated)
            .filter { [weak self] notification in
                (notification.userInfo?["listToken"] as? String) == self?.dataModel.apiType.rawValue
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] notificaiton in
                guard let self else { return }
                if let sortOption = notificaiton.userInfo?["sortOption"] as? SpaceSortHelper.SortOption {
                    self.dataModel.update(sortOption: sortOption)
                }
            })
            .disposed(by: disposeBag)

        itemsRelay.skip(1).subscribe(onNext: { [weak self] items in
            guard let self = self else { return }
            self.updateItemTypes(items: items)
        }).disposed(by: disposeBag)
    }

    func didBecomeActive() {
        isActive = true
        actionInput.accept(.stopPullToLoadMore(hasMore: false))
    }

    func willResignActive() {
        isActive = false
    }

    func select(at index: Int, item: SpaceListItemType) {
        switch item {
        case .inlineSectionSeperator, .gridPlaceHolder, .driveUpload:
            return
        case let .spaceItem(item):
            didSelect(entry: item.entry)
            // 列表中可能存在drive上传进度等不属于文档的内容，在计算实际点击的位置时，需要排除掉
            let actualIndex: Int
            if let firstIndex = itemTypes.firstIndex(where: \.isDocument) {
                actualIndex = index - firstIndex
            } else {
                actualIndex = index
            }
            tracker.reportClick(entry: item.entry, at: actualIndex)
        }
    }

    private func didSelect(entry: SpaceEntry) {
        // 共享文件夹列表只有文件夹，文件夹离线都可点击
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
                                      SKEntryBody.fromKey: FileListStatistics.Module.sharedFolder]
        actionInput.accept(.open(entry: body, context: context))
        if let folder = entry as? FolderEntry {
            tracker.reportEnter(folderToken: folder.objToken,
                                isShareFolder: true,
                                currentModule: "shared_folder",
                                currentFolderToken: nil,
                                subModule: nil)
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
            DocsLogger.error("space.share-folder.list.vm --- pull to refresh failed with error", error: error)
            if let docsError = error as? DocsNetworkError {
                self.actionInput.accept(.showHUD(.failure(docsError.errorMsg)))
            }
            self.serverDataState = .fetchFailed
            self.itemsRelay.accept(self.items)
            return
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
            DocsLogger.error("space.share-folder.list.vm --- pull to load more failed with error", error: error)
        }
        .disposed(by: disposeBag)
    }

    private func updateList(entries: [SpaceEntry]) {
        workQueue.async { [weak self] in
            guard let self = self else { return }
            let items = SpaceModelConverter.convert(entries: entries,
                                                    context: .init(sortType: self.dataModel.sortHelper.selectedOption.type,
                                                                   folderEntry: nil,
                                                                   listSource: .share),
                                                    handler: self)
            self.itemsRelay.accept(items)
        }
    }

    private func updateItemTypes(items: [SpaceListItem]) {
        let itemTypes = addExtraItemTypes(items: items)
        itemTypesRelay.accept(itemTypes)
    }

    private func addExtraItemTypes(items: [SpaceListItem]) -> [SpaceListItemType] {
        var itemLists = items.map(SpaceListItemType.spaceItem(item:))
        //space2.0情况下，不展示隐藏文件夹
        guard !SettingConfig.singleContainerEnable else {
            return itemLists
        }
        // 共享文件夹根目录，需要增加隐藏文件夹的分栏
        guard let firstHiddenFolderIndex = items.firstIndex(where: {
            $0.entry.isHiddenStatus == true
        }) else {
            // 没有隐藏文件夹，不处理
            return itemLists
        }
        itemLists.insert(.hiddenFolderSeperator, at: firstHiddenFolderIndex)
        // 网格模式下，为了保证可见folder的最后一个cell居左，需要补充一个展位cell撑开
        itemLists.insert(.gridPlaceHolder, at: firstHiddenFolderIndex)
        return itemLists
    }

    func contextMenuConfig(for entry: SpaceEntry) -> SpaceListItem.SlideConfig? {
        generateSlideConfig(for: entry)
    }
}

extension ShareFolderListViewModel: SpaceSortPanelDelegate {

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

    private func sortOptionDidChanged() {
        NotificationCenter.default.post(name: .Docs.SpaceSortFilterStateUpdated,
                                        object: nil,
                                        userInfo: [
                                            "listToken": dataModel.apiType.rawValue,
                                            "sortOption": dataModel.sortHelper.selectedOption
                                        ])
        serverDataState = .loading
        dataModel.refresh().subscribe { [weak self] in
            guard let self = self else { return }
            let hasMore = self.dataModel.listContainer.hasMore
            self.actionInput.accept(.stopPullToLoadMore(hasMore: hasMore))
            self.serverDataState = .synced
        } onError: { [weak self] error in
            guard let self = self else { return }
            DocsLogger.error("space.share-folder.vm --- pull to refresh failed with error", error: error)
            self.actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.Doc_Doc_NetException)))
            self.serverDataState = .fetchFailed
        }
        .disposed(by: disposeBag)

        updateSortState()

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

    func sortPanel(_ panel: SpaceSortPanelController, didSelect selectionIndex: Int, descending: Bool) {
        dataModel.update(sortIndex: selectionIndex, descending: descending)
        sortOptionDidChanged()
    }

    func sortPanelDidClickReset(_ panel: SpaceSortPanelController) {
        dataModel.update(sortOption: dataModel.sortHelper.defaultOption)
        sortOptionDidChanged()
    }

    private func updateSortState() {
        let sortOption = dataModel.sortHelper.selectedOption
        sortNameRelay.accept(sortOption.legacyItem.fullDescription)
        selectSortOptionRelay.accept(sortOption)
        let newSortState = generateSortState()
        sortStateRelay.accept(newSortState)
        let sortAction = sortOption.type.reportName
        tracker.sortAction = sortAction
    }
}

extension ShareFolderListViewModel: SpaceListItemInteractHandler {

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
                                                             isShareFolder: true),
                                               bizParms: self.tracker.bizParameter)
        }
        return handler
    }

    // 共享文件夹列表不存在此场景
    func handlePermissionTips(for entry: SpaceEntry) -> ((UIView) -> Void)? {
        nil
    }

    func generateSlideConfig(for entry: SpaceEntry) -> SpaceListItem.SlideConfig? {
        let deleteAction: SlideAction = entry.stared ? .unstar : .star
        return SpaceListItem.SlideConfig(actions: [deleteAction, .share, .more]) { [weak self] (cell, action) in
            guard let self = self else { return }
            if entry.secretKeyDelete == true {
                self.actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.CreationDoc_Docs_KeyInvalidCanNotOperate)))
                return
            }
            self.tracker.source = .slide
            self.tracker.bizParameter.update(fileID: entry.objToken, fileType: entry.docsType, driveType: entry.fileType)
            self.tracker.reportClick(slideAction: action)
            switch action {
            case .star, .unstar:
                self.slideActionHelper.toggleFavorites(for: entry)
            case .share:
                self.slideActionHelper.share(entry: entry, sourceView: cell, shareSource: .list)
            case .more:
                // 共享文件夹列表，侧滑的 More 面板里也要有删除按钮，所以不再屏蔽了
                self.showMoreVC(for: entry, sourceView: cell, forbiddenItems: [.share])
            default:
                spaceAssertionFailure("space.my-folder.list.vm --- unhandle slide action: \(action)")
                return
            }
        }
    }

    private func showMoreVC(for entry: SpaceEntry, sourceView: UIView, forbiddenItems: [MoreItemType]) {
        var hiddenItems = forbiddenItems
        // 取决于从 1.0 or 2.0 的入口打开文件夹列表
        if !dataModel.toggleHiddenStatusEnabled {
            hiddenItems.append(.setHidden)
        }
        var moreProvider = SpaceMoreProviderFactory.createMoreProvider(for: entry, sourceView: sourceView, forbiddenItems: hiddenItems, listType: .shareFolder)
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
extension ShareFolderListViewModel: SpaceListSlideDelegateHelperV2 {

    func refreshForMoreAction() {
        if dataModel.apiType == .newShareFolder || dataModel.apiType == .hiddenFolder {
            DocsLogger.info("new share space can not refresh list")
            return
        }
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

extension ShareFolderListViewModel {

    func didSelectDeleteAction(file: SpaceEntry, completion: @escaping ((Bool) -> Void)) {
        if slideActionHelper.checkIsColorfulEgg(file: file) {
            let navi = UINavigationController(rootViewController: DocsSercetDebugViewController())
            actionInput.accept(.present(viewController: navi, popoverConfiguration: nil))
            return
        }

        let title = BundleI18n.SKResource.Doc_Contract_Remove_Owner_Document_Dialog_Title(file.type.i18Name, file.name)
        let content = BundleI18n.SKResource.CreationMobile_ECM_DeleteDesc_folder
        let caption = BundleI18n.SKResource.CreationMobile_Common_DeleteOthersContent
        let config = UDDialogUIConfig()
        config.contentMargin = .zero
        let dialog = UDDialog(config: config)
        dialog.setTitle(text: title)
        dialog.setContent(text: content, caption: caption)
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
        let nodeToken = file.nodeToken
        let isFolder = file.type == .folder
        let meta = SpaceMeta(objToken: file.objToken, objType: file.type)
        actionInput.accept(.showHUD(.customLoading(BundleI18n.SKResource.CreationMobile_Recent_Deleting_Toast)))
        dataModel.removeFromList(fileEntry: file)
            .subscribe { [weak self] response in
                guard let self = self else { return }
                self.actionInput.accept(.hideHUD)
                switch response {
                case .success:
                    self.actionInput.accept(.showHUD(.success(BundleI18n.SKResource.Doc_Facade_DeleteSuccessfullyToastTip)))
                case let .partialFailed(entries):
                    self.actionInput.accept(.showDeleteFailListView(files: entries))
                case let .needApply(reviewer):
                    self.slideActionHelper.applyDelete(meta: meta, isFolder: isFolder, reviewerInfo: reviewer)
                }
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
