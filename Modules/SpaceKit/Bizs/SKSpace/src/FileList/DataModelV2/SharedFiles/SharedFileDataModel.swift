//
//  SharedFileDataModel.swift
//  SKSpace
//
//  Created by Weston Wu on 2021/11/5.
//

import Foundation
import RxSwift
import RxRelay
import SKCommon
import SKFoundation

extension SharedFileDataModel {
    typealias ListError = RecentListDataModel.RecentDataError
    private var sharedFileListPageCount: Int {
        switch apiType {
        case .sharedFileV1, .sharedFileV2, .sharedFileV3:
            return 100
        case .sharedFileV4:
            // 新首页共享列表拉取数据少一些，拉取30条
            // disable-lint-next-line: magic number
            return 30
        }
    }
    
    private var sharedFileListDBPageCount: Int {
        switch apiType {
        case .sharedFileV1, .sharedFileV2, .sharedFileV3:
            return .max
        case .sharedFileV4:
            return 7
        }
    }
    
    static let sharedFileNeedUpdate = Notification.Name.Docs.refreshShareSpaceFolderList
    private static let dataModelIdentifier = "SharedFile"
    private static let listToken = "SharedFile"
}

enum SharedFileApiType: String {
    case sharedFileV1
    case sharedFileV2
    case sharedFileV3
    case sharedFileV4 // 新首页共享列表
}

class SharedFileDataModel {
    private let disposeBag = DisposeBag()
    private(set) var sortHelper: SpaceSortHelper
    private(set) var filterHelper: SpaceFilterHelper
    let listContainer: SpaceListContainer
    let interactionHelper: SpaceInteractionHelper
    let currentUserID: String
    private let dataManager: SKDataManager
    private var hasBeenSetup = false
    private let workQueue = DispatchQueue(label: "space.shared-file.dm.queue")
    let apiType: SharedFileApiType
    private let api: SharedFileListAPI.Type

    var deleteEnabled: Bool { api.deleteEnabled }

    var itemChanged: Observable<[SpaceEntry]> {
        listContainer.itemsChanged
    }

    init(userID: String, usingAPI: SharedFileApiType) {
        currentUserID = userID
        apiType = usingAPI
        dataManager = SKDataManager.shared
        sortHelper = SpaceSortHelper.sharedFile
        interactionHelper = SpaceInteractionHelper(dataManager: dataManager)
        listContainer = SpaceListContainer(listIdentifier: Self.dataModelIdentifier)
        switch usingAPI {
        case .sharedFileV1:
            api = V1SharedFileListAPI.self
            filterHelper = SpaceFilterHelper.sharedFileV1
        case .sharedFileV2:
            api = V2SharedFileListAPI.self
            filterHelper = SpaceFilterHelper.sharedFileV2
        case .sharedFileV3:
            api = V3SharedFileListAPI.self
            filterHelper = SpaceFilterHelper.sharedFileV3
        case .sharedFileV4:
            api = V4ShareFileListAPI.self
            filterHelper = SpaceFilterHelper.sharedFileV3
        }
    }

    func setup() {
        guard !hasBeenSetup else {
            DocsLogger.error("space.shared-file.dm --- skipping re-setup data model")
            spaceAssertionFailure("re-setup list DM")
            return
        }
        hasBeenSetup = true
        sortHelper.restore()
        filterHelper.restore()
        dataManager.addObserver(self)
        // 先发 Action 再调用 loadData，保证 addObserver 后一定能收到一次本地数据回调
        dataManager.loadFolderFileEntries(folderKey: api.folderKey, limit: sharedFileListDBPageCount)
        dataManager.loadData(currentUserID) { success in
            if !success {
                spaceAssertionFailure("Load DB 竟然失败了 cc @guoqingping")
            }
        }

        NotificationCenter.default.rx.notification(Self.sharedFileNeedUpdate)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.refresh().subscribe().disposed(by: self.disposeBag)
            })
            .disposed(by: disposeBag)
    }

    func refresh() -> Completable {
        return api.queryList(count: sharedFileListPageCount,
                             sortOption: sortHelper.selectedOption,
                             filterOption: filterHelper.selectedOption,
                             extraParams: ThumbnailUrlConfig.gridThumbnailSizeParams)
            .do(onSuccess: { [weak self] dataDiff in
                guard let self = self else { return }
                let pagingState: SpaceListContainer.PagingState
                let pagingInfo = dataDiff.sharePagingInfo
                let totalCount = pagingInfo.total ?? dataDiff.shareObjs.count
                if pagingInfo.hasMore, let lastLabel = pagingInfo.lastLabel {
                    pagingState = .hasMore(lastLabel: lastLabel)
                } else {
                    pagingState = .noMore
                }
                self.listContainer.update(pagingState: pagingState)
                self.listContainer.update(totalCount: totalCount)
                self.dataManager.resetShareFileList(data: dataDiff, folderKey: self.api.folderKey)
            }, onError: { error in
                DocsLogger.error("space.shared-file.dm --- refresh failed", error: error)
            })
            .asCompletable()
    }

    func loadMore() -> Completable {
        guard case let .hasMore(lastLabel) = listContainer.pagingState else {
            DocsLogger.error("space.shared-file.dm --- cannot load more")
            return .error(ListError.unableToLoadMore)
        }
        return api.queryList(count: sharedFileListPageCount,
                             lastLabel: lastLabel,
                             sortOption: sortHelper.selectedOption,
                             filterOption: filterHelper.selectedOption,
                             extraParams: ThumbnailUrlConfig.gridThumbnailSizeParams)
            .do(onSuccess: { [weak self] dataDiff in
                guard let self = self else { return }
                let pagingState: SpaceListContainer.PagingState
                let pagingInfo = dataDiff.sharePagingInfo
                let totalCount = pagingInfo.total ?? dataDiff.shareObjs.count
                if pagingInfo.hasMore, let lastLabel = pagingInfo.lastLabel {
                    pagingState = .hasMore(lastLabel: lastLabel)
                } else {
                    pagingState = .noMore
                }
                self.listContainer.update(pagingState: pagingState)
                self.listContainer.update(totalCount: totalCount)
                self.dataManager.appendShareFileList(data: dataDiff, folderKey: self.api.folderKey)
            }, onError: { error in
                DocsLogger.error("space.my-folder.dm --- load more failed", error: error)
            })
            .asCompletable()
    }

    func update(filterIndex: Int) {
        filterHelper.update(filterIndex: filterIndex)
        filterHelper.store()
    }

    func update(filterOption: SpaceFilterHelper.FilterOption) {
        filterHelper.update(selectedOption: filterOption)
        filterHelper.store()
    }

    func update(sortIndex: Int, descending: Bool) {
        sortHelper.update(sortIndex: sortIndex, descending: descending)
        sortHelper.store()
    }

    func update(sortOption: SpaceSortHelper.SortOption) {
        sortHelper.update(selectedOption: sortOption)
        sortHelper.store()
    }

    // 只有 v1 列表才有可能出现删除按钮
    func deleteFromShareFileList(objToken: FileListDefine.ObjToken) -> Completable {
        interactionHelper.removeFromShareFileList(objToken: objToken)
    }
}

private extension SKOperational {
    func isLocalDataForShareFolderList(_ key: DocFolderKey) -> Bool {
        switch self {
        case .loadNewDBData:
            return true
        case let .loadSpecialFolder(folderKey):
            return folderKey == key
        default:
            return false
        }
    }

    var isServerDataForSharedFileList: Bool {
        switch self {
        case .resetShareFileList,
                .appendShareFileList:
            return true
        default:
            return false
        }
    }
}

extension SharedFileDataModel: SKListServiceProtocol {

    func dataChange(data: SKListData, operational: SKOperational) {
        DocsLogger.debug("space.shared-file.dm.debug --- data changed, operation: \(operational.descriptionInLog), dataCount: \(data.files.count)")
        if operational.isLocalDataForShareFolderList(api.folderKey) {
            self.listContainer.restore(localData: data.files)
        } else if operational.isServerDataForSharedFileList {
            self.listContainer.sync(serverData: data.files)
        } else {
            self.listContainer.update(data: data.files)
        }
    }

    var type: SKObserverDataType {
        switch apiType {
        case .sharedFileV4:
            return .specialList(folderKey: .spaceTabShared)
        case .sharedFileV1, .sharedFileV2, .sharedFileV3:
            return .specialList(folderKey: .share)
        }
    }

    var token: String {
        return Self.listToken
    }
}

extension SharedFileDataModel: FolderPickerDataModel {
    var pickerItems: [SpaceEntry] { listContainer.items }
    var pickerItemChanged: Observable<[SpaceEntry]> { itemChanged }
    var addToCurrentFolderEnabled: Observable<Bool> { .just(false) }

    func resetSortFilterForPicker() {
        filterHelper.update(selectedOption: .all)
        sortHelper.update(selectedOption: SortOption(type: .updateTime, descending: true, allowAscending: false))
    }
}
