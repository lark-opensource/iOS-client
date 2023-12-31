//
//  SubFolderListViewModelV2.swift
//  SKSpace
//
//  Created by Weston Wu on 2021/11/3.
// swiftlint:disable file_length

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
import SKUIKit
import UniverseDesignDialog
import UniverseDesignEmpty
import SpaceInterface

extension SubFolderListViewModelV2 {
    typealias Action = SpaceSection.Action
}

class SubFolderListViewModelV2: PermissionRestrictedFolderListViewModel {

    private let vmIdentifier = "sub-folder-list-v2"
    private let workQueue = DispatchQueue(label: "space.sub-folder-list-v2.list.vm")

    // 表示当前列表是否正在被展示，切换至其他子列表时，isActive 需要置 false
    private(set) var isActive = false

    var localDataReady: Bool { dataModel.listContainer.state != .restoring }
    // 表明是否请求过服务端数据，用于解决本地为空的情况下，继续展示loading
    private(set) var serverDataState = ServerDataState.loading

    private let actionInput = PublishRelay<Action>()
    var actionSignal: Signal<Action> {
        actionInput.asSignal()
    }

    let dataModel: SubFolderDataModelV2

    var folderToken: FileListDefine.ObjToken { dataModel.folderToken }
    var folderType: FolderType { dataModel.folderType }
    var folderEntry: FolderEntry? { dataModel.folderEntry }

    private let listStatusRelay = PublishRelay<Result<Void, FolderListError>>()
    var listStatusChanged: Signal<Result<Void, FolderListError>> { listStatusRelay.asSignal() }

    let sortStateRelay = BehaviorRelay<SpaceListFilterState>(value: .deactivated)
    var sortState: SpaceListFilterState { sortStateRelay.value }
    var sortPanelDelegate: SpaceSortPanelDelegate { self }
    var sortNameRelay = BehaviorRelay<String>(value: "")
    var selectSortOptionRelay = BehaviorRelay<SpaceSortHelper.SortOption?>(value: nil)
    var hasActiveFilter: Bool { false }

    let updateItemInput = PublishRelay<Void>()

    // 列表中的文档数据
    private let itemsRelay = BehaviorRelay<[SpaceListItem]>(value: [])
    private var items: [SpaceListItem] { itemsRelay.value }

    // 为了适配 drive 的上传进度特殊 cell，这里需要包装一层，和列表展示的数据对应
    private let itemTypesRelay = BehaviorRelay<[SpaceListItemType]>(value: [])
    private var itemTypes: [SpaceListItemType] { itemTypesRelay.value }

    private let createEnableRelay = BehaviorRelay<Bool>(value: false)
    var createEnabledUpdated: Observable<Bool> { createEnableRelay.asObservable() }

    var itemsUpdated: Observable<[SpaceListItemType]> {
        itemTypesRelay.skip(1).asObservable()
    }

    private let reachabilityRelay = BehaviorRelay(value: true)
    var reachabilityChanged: Observable<Bool> {
        reachabilityRelay.distinctUntilChanged().asObservable()
    }
    var isReachable: Bool { reachabilityRelay.value }

    var createContext: SpaceCreateContext {
        guard let folderEntry = dataModel.folderEntry else {
            return .recent
        }
        let module: PageModule = folderEntry.folderType.isShareFolder ? .sharedSubFolder : .personalSubFolder
        let context = SpaceCreateContext(module: module, mountLocationToken: folderEntry.objToken, folderType: folderEntry.folderType, ownerType: folderEntry.ownerType)
        return context
    }

    var searchContext: SpaceSearchContext {
        guard let folderEntry = dataModel.folderEntry else {
            return SpaceSearchContext(searchFromType: .normal, module: .personalSubFolder, isShareFolder: false)
        }
        let isShareFolder = folderEntry.folderType.isShareFolder
        let module: PageModule = isShareFolder ? .sharedSubFolder : .personalSubFolder
        return SpaceSearchContext(searchFromType: .folder(token: folderEntry.objToken,
                                                          name: folderEntry.name,
                                                          isShareFolder: folderEntry.folderType.isShareFolder),
                                  module: module,
                                  isShareFolder: isShareFolder)
    }

    var isBlank: Bool {
        dataModel.listContainer.isEmpty
    }

    var isShareFolder: Bool {
        dataModel.isShareFolder
    }
    
    var folderListScene: FolderListScene {
        .subFolderList
    }

    var emptyDescription: String {
        if createEnableRelay.value {
            return BundleI18n.SKResource.Doc_Facade_EmptyDocumentTips
        } else {
            return BundleI18n.SKResource.Doc_List_EmptyFolderInArchive
        }
    }

    var emptyImageType: UDEmptyType {
        .documentDefault
    }
    
    var hiddenFolderListSection: Bool { false }

    private lazy var slideActionHelper: SpaceListSlideDelegateProxyV2 = {
        return SpaceListSlideDelegateProxyV2(helper: self)
    }()

    private let uploadHelper: SpaceListDriveUploadHelper
    private var driveListConfig: DriveListConfig { uploadHelper.driveListConfig }
    private var listBag = DisposeBag()
    private let disposeBag = DisposeBag()

    private(set) var tracker: SpaceSubSectionTracker
    
    private let isShowInDetail: Bool

    init(dataModel: SubFolderDataModelV2, isShowInDetail: Bool = false) {
        self.dataModel = dataModel
        self.isShowInDetail = isShowInDetail
        
        let isShareFolder: Bool = dataModel.isShareFolder
        let module: PageModule = isShareFolder ? .sharedSubFolder : .personalSubFolder
        tracker = SpaceSubSectionTracker(bizParameter: SpaceBizParameter(module: module, containerID: dataModel.folderToken, containerType: .folder))
        uploadHelper = SpaceListDriveUploadHelper(mountToken: dataModel.folderToken,
                                                  mountPoint: DriveConstants.driveMountPoint,
                                                  scene: .unknown,
                                                  identifier: tracker.module.rawValue)
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
        dataModel.itemChanged
            .subscribe(onNext: { [weak self] entries in
                guard let self = self else { return }
                self.updateList(entries: entries)
            })
            .disposed(by: disposeBag)

        dataModel.listContainer.stateChanged
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] state in
                guard let self = self else { return }
                guard state == .ready else {
                    return
                }
                self.serverDataState = .synced
            })
            .disposed(by: disposeBag)

        dataModel.refresh().subscribe { [weak self] in
            // err 为空表示拉取成功，走 itemChanged 内的逻辑
            guard let self = self else { return }
            let hasMore = self.dataModel.listContainer.hasMore
            self.actionInput.accept(.stopPullToLoadMore(hasMore: hasMore))
            self.listStatusRelay.accept(.success(()))
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
            if let listError = error as? FolderListError {
                self.listStatusRelay.accept(.failure(listError))
            }
        }
        .disposed(by: listBag)

        setupEditPermission()

        itemsRelay.skip(1).subscribe(onNext: { [weak self] items in
            guard let self = self else { return }
            self.updateItemTypes(driveConfig: self.driveListConfig, items: items)
        }).disposed(by: disposeBag)

        updateItemInput.subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            self.updateItemTypes(driveConfig: self.driveListConfig, items: self.items)
        }).disposed(by: disposeBag)

        uploadHelper.uploadStateChanged.bind(to: updateItemInput).disposed(by: disposeBag)
        uploadHelper.fileDidUploaded.subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            self.dataModel.refresh().subscribe().disposed(by: self.listBag)
        }).disposed(by: disposeBag)
        uploadHelper.setup()

        sortNameRelay.accept(dataModel.sortHelper.selectedOption.legacyItem.fullDescription)
        let newSortState = generateSortState()
        sortStateRelay.accept(newSortState)
        selectSortOptionRelay.accept(dataModel.sortHelper.selectedOption)

        let sortAction = dataModel.sortHelper.selectedOption.type.reportName
        tracker.sortAction = sortAction

        listStatusChanged.emit { [weak self] state in
            guard let self,
                  case let .failure(error) = state else {
                return
            }
            switch error {
            case .blockByTNS:
                // 需要清空下文件夹缓存
                self.dataModel.deleteAllChildren()
            default:
                break
            }
        }
    }

    func didBecomeActive() {
        isActive = true
    }

    func willResignActive() {
        isActive = false
    }

    private func setupEditPermission() {
        dataModel.createPermRelay.bind(to: createEnableRelay).disposed(by: disposeBag)
    }

    func select(at index: Int, item: SpaceListItemType) {
        switch item {
        case .inlineSectionSeperator, .gridPlaceHolder:
            return
        case .driveUpload:
            actionInput.accept(.showDriveUploadList(folderToken: uploadHelper.mountToken))
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
        if !isReachable, entry.canOpenWhenOffline == false {
            offlineSelect(entry: entry)
            return
        }

        let entryLists = items.compactMap { item -> SpaceEntry? in
            let entry = item.entry
            if entry.type.isUnknownType { return nil }
            return entry
        }
        entry.fromModule = "inner_folder"
        FileListStatistics.curFileObjToken = entry.objToken
        FileListStatistics.curFileType = entry.type
        FileListStatistics.prepareStatisticsData(.folderDetail)
        let body = SKEntryBody(entry)
        let context: [String: Any] = [SKEntryBody.fileEntryListKey: entryLists,
                                      SKEntryBody.fromKey: FileListStatistics.Module.folder]
        actionInput.accept(.open(entry: body, context: context))
        if let folder = entry as? FolderEntry {
            tracker.reportEnter(folderToken: folder.objToken,
                                isShareFolder: folder.isShareFolder,
                                currentModule: isShareFolder ? "shared_folder" : "folder",
                                currentFolderToken: dataModel.folderToken,
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
            DocsLogger.info("space.sub-folder.vm --- drive disable by FG, forbidden offline open drive action")
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
            let items = SpaceModelConverter.convert(entries: entries,
                                                    context: .init(sortType: self.dataModel.sortHelper.selectedOption.type,
                                                                   folderEntry: self.dataModel.folderEntry,
                                                                   listSource: .subFolder),
                                                    handler: self)
            self.itemsRelay.accept(items)
        }
    }

    func notifyPullToRefresh() {
        serverDataState = .loading
        dataModel.refresh().subscribe { [weak self] in
            guard let self = self else { return }
            let total = self.dataModel.listContainer.totalCount
            self.actionInput.accept(.stopPullToRefresh(total: total))
            let hasMore = self.dataModel.listContainer.hasMore
            self.actionInput.accept(.stopPullToLoadMore(hasMore: hasMore))
            self.listStatusRelay.accept(.success(()))
        } onError: { [weak self] error in
            guard let self = self else { return }
            self.actionInput.accept(.stopPullToRefresh(total: nil))
            DocsLogger.error("space.favorites.list.vm --- pull to refresh failed with error", error: error)
            // show error
            self.serverDataState = .fetchFailed
            self.itemsRelay.accept(self.items)
            if let listError = error as? FolderListError {
                self.listStatusRelay.accept(.failure(listError))
            }
        }
        .disposed(by: listBag)
        checkFolderPermission()
    }

    func notifyPullToLoadMore() {
        dataModel.loadMore().subscribe { [weak self] in
            guard let self = self else { return }
            let hasMore = self.dataModel.listContainer.hasMore
            self.actionInput.accept(.stopPullToLoadMore(hasMore: hasMore))
        } onError: { [weak self] error in
            guard let self = self else { return }
            if let listError = error as? SubFolderDataModelV1.CommonListError, listError == .unableToLoadMore {
                self.actionInput.accept(.stopPullToLoadMore(hasMore: false))
            } else {
                self.actionInput.accept(.stopPullToLoadMore(hasMore: true))
            }
            DocsLogger.error("space.favorites.list.vm --- pull to load more failed with error", error: error)
            if let listError = error as? FolderListError {
                self.listStatusRelay.accept(.failure(listError))
            }
        }
        .disposed(by: listBag)
    }

    private func updateItemTypes(driveConfig: DriveListConfig, items: [SpaceListItem]) {
        var itemTypes: [SpaceListItemType] = []
        if !isShowInDetail {
            if driveConfig.isNeedUploading {
                DocsLogger.debug("[Drive Upload] uploadCount: \(driveConfig.remainder) progress: \(driveConfig.progress)")
                let status: DriveStatusItem.Status = driveConfig.failed ? .failed : .uploading
                let count = self.driveListConfig.failed ? driveConfig.errorCount : driveConfig.remainder
                let driveStatusItem = DriveStatusItem(count: count, total: driveConfig.totalCount,
                                                      progress: driveConfig.progress, status: status)
                itemTypes.append(.driveUpload(item: driveStatusItem))
            }
        }
        let listItems = items.map(SpaceListItemType.spaceItem(item:))
        itemTypes.append(contentsOf: listItems)
        itemTypesRelay.accept(itemTypes)
    }

    func contextMenuConfig(for entry: SpaceEntry) -> SpaceListItem.SlideConfig? {
        if entry.type.isBiz, !entry.hasPermission {
            return generateSlideConfigForNoPermissionEntry(entry: entry)
        }
        return generateSlideConfig(for: entry)
    }

    func checkFolderPermission() {
        dataModel.checkFolderPermission()
    }

    func requestPermission(message: String, roleToRequest: Int) -> Completable {
        dataModel.requestPermission(message: message, roleToRequest: roleToRequest)
    }
}

extension SubFolderListViewModelV2: SpaceSortPanelDelegate {

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
    func sortPanel(_ panel: SpaceSortPanelController, didSelect selectionIndex: Int, descending: Bool) {
        dataModel.update(sortIndex: selectionIndex, descending: descending)
        sortOptionDidChanged()
    }

    func sortPanelDidClickReset(_ panel: SpaceSortPanelController) {
        dataModel.update(sortOption: dataModel.sortHelper.defaultOption)
        sortOptionDidChanged()
    }

    private func sortOptionDidChanged() {
        // 切换筛选、排序项时，重置一下列表请求
        listBag = DisposeBag()
        actionInput.accept(.stopPullToRefresh(total: nil))
        actionInput.accept(.stopPullToLoadMore(hasMore: false))
        serverDataState = .loading
        dataModel.refresh().subscribe(onError: { [weak self] error in
            guard let self = self else { return }
            DocsLogger.error("space.recent.vm --- pull to refresh failed with error", error: error)
            self.actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.Doc_Doc_NetException)))
            self.serverDataState = .fetchFailed
            if let listError = error as? FolderListError {
                self.listStatusRelay.accept(.failure(listError))
            }
        })
        .disposed(by: listBag)

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

extension SubFolderListViewModelV2: SpaceListItemInteractHandler {
    // 网格模式下，more 按钮
    fileprivate func createMoreActionHandler(for entry: SpaceEntry, forbiddenItems: [MoreItemType]) -> (UIView) -> Void {
        return { [weak self] view in
            guard let self = self else { return }
            if entry.secretKeyDelete == true {
                self.actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.CreationDoc_Docs_KeyInvalidCanNotOperate)))
                return
            }
            self.tracker.source = .gridMore
            self.showMoreVC(for: entry, sourceView: view, forbiddenItems: forbiddenItems)
            self.tracker.reportClickGridMore(entryType: entry.type)
            DocsTracker.reportSpaceFolderClick(params: .more(isBlank: self.isBlank,
                                                             isShareFolder: entry.isShareFolder),
                                               bizParms: self.tracker.bizParameter)
        }
    }

    func handleMoreAction(for entry: SpaceEntry) -> ((UIView) -> Void)? {
        return createMoreActionHandler(for: entry, forbiddenItems: [])
    }

    func folderMoreAction() -> ((UIView) -> Void)? {
        // 只有子文件夹可以展示自己的More菜单
        return { [weak self] view in
            guard let self = self else { return }
            guard var folderEntry = self.dataModel.folderEntry else {
                return
            }
            if folderEntry.nodeToken.isEmpty {
                folderEntry = folderEntry.makeCopy(newNodeToken: folderEntry.objToken, newObjToken: folderEntry.objToken)
            }
            var forbiddenItems: [MoreItemType] = [.delete, .moveTo]
            //2.0文件夹详情页 & 申请移动、删除 FG 关，navbar的更多面板不显示“移动到”、“删除”
            if UserScopeNoChangeFG.WWJ.spaceApplyDeleteEnabled {
                // FG 开就能删文件夹自己
                forbiddenItems.removeAll { $0 == .delete }
                // FG 开且同租户，才能删自己
                if folderEntry.isSameTenantWithOwner {
                    forbiddenItems.removeAll { $0 == .moveTo }
                }
            }
            let handler = self.createMoreActionHandler(for: folderEntry, forbiddenItems: forbiddenItems)
            handler(view)
        }
    }

    func handlePermissionTips(for entry: SpaceEntry) -> ((UIView) -> Void)? {
        guard entry.ownerIsCurrentUser else {
            return { [weak self] _ in
                self?.actionInput.accept(.showHUD(.tips(BundleI18n.SKResource.Doc_List_PermTipMemberContent)))
            }
        }
        return { [weak self] _ in
            guard let self = self else { return }
            let dialog = UDDialog()
            dialog.setTitle(text: BundleI18n.SKResource.Doc_Widget_Tip)
            dialog.setContent(text: BundleI18n.SKResource.Doc_List_PermTipAlertContent(entry.docsType.i18Name))
            dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel)
            dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Facade_Ok, dismissCompletion: { [weak self] in
                self?.updateExternalPermission(for: entry)
            })
            self.actionInput.accept(.present(viewController: dialog, popoverConfiguration: nil))
        }
    }

    // 将特定文件的外部链接共享能力打开
    private func updateExternalPermission(for entry: SpaceEntry) {
        let params: [String: Any] = ["type": entry.type.rawValue,
                                     "token": entry.objToken,
                                     "link_share_entity": 1,
                                     "external_access": true]
        PermissionManager.updateBizsPublicPermission(params: params)
            .subscribe { [weak self] json in
                guard let self = self else { return }
                guard let json = json else {
                    DocsLogger.error("space.folder.list.vm --- update external permission failed, no json resposne")
                    self.actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.Doc_AppUpdate_FailRetry)))
                    return
                }
                guard let code = json["code"].int else {
                    DocsLogger.error("space.folder.list.vm --- update external permission failed, code not found in json")
                    self.actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.Doc_AppUpdate_FailRetry)))
                    return
                }
                guard code == 0 else {
                    DocsLogger.error("space.folder.list.vm --- update external permission failed, code is \(code)")
                    if code == ExplorerErrorCode.dataUpgradeLocked.rawValue {
                        self.actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.CreationMobile_DataUpgrade_Locked_toast)))
                    } else {
                        self.actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.Doc_AppUpdate_FailRetry)))
                    }
                    return
                }
                self.actionInput.accept(.showHUD(.success(BundleI18n.SKResource.Doc_Facade_SetSuccess)))
                self.notifyPullToRefresh()

            } onError: { [weak self] error in
                DocsLogger.error("space.folder.list.vm --- update external permission failed with error", error: error)
                guard let self = self else { return }
                if let docsError = error as? DocsNetworkError,
                   let message = docsError.code.errorMessage {
                    self.actionInput.accept(.showHUD(.failure(message)))
                } else {
                    self.actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.Doc_Normal_PermissionModify + BundleI18n.SKResource.Doc_AppUpdate_FailRetry)))
                }
            }
            .disposed(by: disposeBag)

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
                spaceAssertionFailure("space.folder.list.vm --- unhandle slide action: \(action)")
                return
            }
        }
    }

    func generateSlideConfigForNoPermissionEntry(entry: SpaceEntry) -> SpaceListItem.SlideConfig? {
        let deleteAction: SlideAction = .delete
        return SpaceListItem.SlideConfig(actions: [deleteAction]) { [weak self] (_, action) in
            guard let self = self else { return }
            self.tracker.source = .slide
            self.tracker.bizParameter.update(fileID: entry.objToken, fileType: entry.docsType, driveType: entry.fileType)
            self.tracker.reportClick(slideAction: action)
            switch action {
            case .readyToDelete, .delete:
                self.handleDelete(for: entry)
            default:
                spaceAssertionFailure("space.folder.list.vm --- unhandle slide action: \(action)")
                return
            }
        }
    }

    private func showMoreVC(for entry: SpaceEntry, sourceView: UIView, forbiddenItems: [MoreItemType]) {
        let listType: SpaceMoreAPI.ListType
        if isShareFolder {
            listType = .subFolder(type: .v2Share)
        } else {
            listType = .subFolder(type: .v2Personal)
        }
        var moreProvider = SpaceMoreProviderFactory.createMoreProvider(for: entry, sourceView: sourceView, forbiddenItems: forbiddenItems, listType: listType)
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

extension SubFolderListViewModelV2: SpaceListSlideDelegateHelperV2 {

    func refreshForMoreAction() {
        notifyPullToRefresh()
    }
    var slideActionInput: PublishRelay<SpaceSection.Action> { actionInput }
    var slideTracker: SpaceSubSectionTracker { tracker }
    var interactionHelper: SpaceInteractionHelper { dataModel.interactionHelper }
    var listType: SKObserverDataType? { dataModel.type }
    var userID: String { User.current.info?.userID ?? "" }

    func handleDelete(for entry: SpaceEntry) {
        didSelectDeleteAction(file: entry, completion: { [weak self] confirm in
            guard let self = self, confirm else { return }
            self.deleteFile(entry)
        })
    }
}

extension SubFolderListViewModelV2 {
    // 回调第一个 Bool 表明是否确认删除操作
    func didSelectDeleteAction(file: SpaceEntry, completion: @escaping ((Bool) -> Void)) {
        if slideActionHelper.checkIsColorfulEgg(file: file) {
            let navi = UINavigationController(rootViewController: DocsSercetDebugViewController())
            actionInput.accept(.present(viewController: navi, popoverConfiguration: nil))
            return
        }

        let fileName = file.name
        let title: String
        let content: String
        var caption: String?

        //针对新类型的文案，先这么写，GA后调整
        if file.isShortCut {
            title = BundleI18n.SKResource.CreationMobile_ECM_DeleteTitle(fileName)
            content = BundleI18n.SKResource.CreationMobile_ECM_DeleteDesc
        } else {
            title = BundleI18n.SKResource.CreationMobile_ECM_DeleteConfirmTitle(fileName)
            if file.type == .folder {
                content = BundleI18n.SKResource.CreationMobile_ECM_DeleteDesc_folder
                caption = BundleI18n.SKResource.CreationMobile_Common_DeleteOthersContent
            } else {
                content = BundleI18n.SKResource.CreationMobile_ECM_DeleteDesc
                if !file.ownerIsCurrentUser {
                    caption = BundleI18n.SKResource.CreationMobile_Common_DeleteOthersNotify
                }
            }
        }

        let config = UDDialogUIConfig()
        config.contentMargin = .zero
        let dialog = UDDialog(config: config)
        dialog.setTitle(text: title)
        if let caption = caption {
            dialog.setContent(text: content, caption: caption)
        } else {
            dialog.setContent(text: content)
        }

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

        var tokenToDelete = file.nodeToken
        var isDeletingSelf = false
        if tokenToDelete.isEmpty {
            tokenToDelete = file.objToken
        }
        let isFolder = file.type == .folder
        if isFolder && tokenToDelete == dataModel.token {
            tokenToDelete = file.objToken
            isDeletingSelf = true
        }
        let meta = SpaceMeta(objToken: file.objToken, objType: file.type)
        interactionHelper.deleteV2(objToken: file.objToken,
                                   nodeToken: file.nodeToken,
                                   type: file.type,
                                   isShortCut: file.isShortCut,
                                   canApply: UserScopeNoChangeFG.WWJ.spaceApplyDeleteEnabled)
            .subscribe { [weak self] response in
                guard let self = self else { return }
                self.actionInput.accept(.hideHUD)
                switch response {
                case let .partialFailed(entries):
                    self.actionInput.accept(.showDeleteFailListView(files: entries))
                case .success:
                    self.actionInput.accept(.showHUD(.success(BundleI18n.SKResource.Doc_Facade_DeleteSuccessfullyToastTip)))
                    guard isDeletingSelf else { return }
                    // 文件夹自己被删除后，发送通知给其他 FolderVM，刷新列表，然后退出当前VC
                    NotificationCenter.default.post(name: SubFolderDataModelV2.subFolderNeedUpdate, object: nil)
                    self.actionInput.accept(.exit)
                case let .needApply(reviewer):
                    // 申请逻辑
                    self.slideActionHelper.applyDelete(meta: meta, isFolder: isFolder, reviewerInfo: reviewer)
                }
            } onError: { [weak self] error in
                guard let self = self else { return }
                self.actionInput.accept(.hideHUD)
                DocsLogger.error("space.sub-folder-v2.list.vm --- failed to delete v2 file", error: error)
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
