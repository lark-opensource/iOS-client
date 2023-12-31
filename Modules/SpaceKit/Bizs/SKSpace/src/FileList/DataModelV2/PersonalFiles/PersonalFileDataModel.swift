//
//  PersonalFileDataModel.swift
//  SKSpace
//
//  Created by Weston Wu on 2021/11/5.
//

import Foundation
import RxSwift
import RxRelay
import SKCommon
import SKFoundation

extension PersonalFileDataModel {
    typealias ListError = RecentListDataModel.RecentDataError
    private static let personalFileListPageCount = 100
    static let personalFileNeedUpdate = Notification.Name.Docs.RefreshPersonFile
    private static let dataModelIdentifier = "PersonalFilesService"
    private static let listToken = "PersonalFilesService"
}

class PersonalFileDataModel {
    private let disposeBag = DisposeBag()
    private(set) var sortHelper: SpaceSortHelper
    private(set) var filterHelper: SpaceFilterHelper
    let listContainer: SpaceListContainer
    let interactionHelper: SpaceInteractionHelper
    let currentUserID: String
    private let dataManager: SKDataManager
    private var hasBeenSetup = false
    private let workQueue = DispatchQueue(label: "space.personal-file.dm.queue")
    // 仅供 VM 区分 1.0 2.0 用，迁移完删掉
    let usingV2API: Bool
    private let api: PersonalFileListAPI.Type

    var itemChanged: Observable<[SpaceEntry]> {
        listContainer.itemsChanged
    }

    init(userID: String, usingV2API: Bool) {
        currentUserID = userID
        dataManager = SKDataManager.shared
        interactionHelper = SpaceInteractionHelper(dataManager: dataManager)
        listContainer = SpaceListContainer(listIdentifier: Self.dataModelIdentifier)
        self.usingV2API = usingV2API
        if usingV2API {
            sortHelper = SpaceSortHelper.personalFileV2
            filterHelper = SpaceFilterHelper.personalFileV2
            api = V2PersonalFileListAPI.self
        } else {
            sortHelper = SpaceSortHelper.personalFileV1
            filterHelper = SpaceFilterHelper.personalFileV1
            api = V1PersonalFileListAPI.self
        }
    }

    init(userID: String,
         api: PersonalFileListAPI.Type,
         sortHelper: SpaceSortHelper,
         filterHelper: SpaceFilterHelper) {
        currentUserID = userID
        dataManager = SKDataManager.shared
        usingV2API = api.isV2
        interactionHelper = SpaceInteractionHelper(dataManager: dataManager)
        listContainer = SpaceListContainer(listIdentifier: Self.dataModelIdentifier)
        self.api = api
        self.sortHelper = sortHelper
        self.filterHelper = filterHelper
    }

    func setup() {
        guard !hasBeenSetup else {
            DocsLogger.error("space.personal-file.dm --- skipping re-setup data model")
            spaceAssertionFailure("re-setup list DM")
            return
        }
        hasBeenSetup = true
        sortHelper.restore()
        filterHelper.restore()
        dataManager.addObserver(self)
        // 先发 Action 再调用 loadData，保证 addObserver 后一定能收到一次本地数据回调
        dataManager.loadFolderFileEntries(folderKey: api.folderKey, limit: .max)
        dataManager.loadData(currentUserID) { success in
            if !success {
                spaceAssertionFailure("Load DB 竟然失败了 cc @guoqingping")
            }
        }

        NotificationCenter.default.rx.notification(Self.personalFileNeedUpdate)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.refresh().subscribe().disposed(by: self.disposeBag)
            })
            .disposed(by: disposeBag)
    }

    func refresh() -> Completable {
        return api.queryList(count: Self.personalFileListPageCount,
                             sortOption: sortHelper.selectedOption,
                             filterOption: filterHelper.selectedOption,
                             extraParams: ThumbnailUrlConfig.gridThumbnailSizeParams)
            .do(onSuccess: { [weak self] dataDiff in
                guard let self = self else { return }
                let pagingState: SpaceListContainer.PagingState
                let pagingInfo = dataDiff.personalFilesPagingInfo
                let totalCount = pagingInfo.total ?? dataDiff.personalFileObjs.count
                if self.api.pagingEnabled, pagingInfo.hasMore, let lastLabel = pagingInfo.lastLabel {
                    pagingState = .hasMore(lastLabel: lastLabel)
                } else {
                    pagingState = .noMore
                }
                self.listContainer.update(pagingState: pagingState)
                self.listContainer.update(totalCount: totalCount)
                self.dataManager.updatePersionalFilesList(data: dataDiff, folderKey: self.api.folderKey)
            }, onError: { error in
                DocsLogger.error("space.personal-file.dm --- refresh failed", error: error)
            })
            .asCompletable()
    }

    func loadMore() -> Completable {
        guard self.api.pagingEnabled,
            case let .hasMore(lastLabel) = listContainer.pagingState else {
            DocsLogger.error("space.personal-file.dm --- cannot load more")
            return .error(ListError.unableToLoadMore)
        }
        return api.queryList(count: Self.personalFileListPageCount,
                             lastLabel: lastLabel,
                             sortOption: sortHelper.selectedOption,
                             filterOption: filterHelper.selectedOption,
                             extraParams: ThumbnailUrlConfig.gridThumbnailSizeParams)
            .do(onSuccess: { [weak self] dataDiff in
                guard let self = self else { return }
                let pagingState: SpaceListContainer.PagingState
                let pagingInfo = dataDiff.personalFilesPagingInfo
                let totalCount = pagingInfo.total ?? dataDiff.personalFileObjs.count
                if self.api.pagingEnabled, pagingInfo.hasMore, let lastLabel = pagingInfo.lastLabel {
                    pagingState = .hasMore(lastLabel: lastLabel)
                } else {
                    pagingState = .noMore
                }
                self.listContainer.update(pagingState: pagingState)
                self.listContainer.update(totalCount: totalCount)
                self.dataManager.appendPersionalFilesList(data: dataDiff, folderKey: self.api.folderKey)
            }, onError: { error in
                DocsLogger.error("space.my-folder.dm --- load more failed", error: error)
            })
            .asCompletable()
    }

    func update(filterIndex: Int) {
        guard api.filterEnabled else { return }
        filterHelper.update(filterIndex: filterIndex)
        filterHelper.store()
    }

    func update(filterOption: SpaceFilterHelper.FilterOption) {
        guard api.filterEnabled else { return }
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
}

private extension SKOperational {
    func isLocalDataForPersonalFileList(folderKey: DocFolderKey) -> Bool {
        switch self {
        case .loadNewDBData:
            return true
        case let .loadSpecialFolder(key):
            return folderKey == key
        default:
            return false
        }
    }

    var isServerDataForPersonalFileList: Bool {
        switch self {
        case .updatePersionalFilesList,
                .appendPersionalFilesList:
            return true
        default:
            return false
        }
    }
}

extension PersonalFileDataModel: SKListServiceProtocol {
    func dataChange(data: SKListData, operational: SKOperational) {
        DocsLogger.debug("space.personal-file.dm.debug --- data changed, operation: \(operational.descriptionInLog), dataCount: \(data.files.count)")
        if operational.isLocalDataForPersonalFileList(folderKey: api.folderKey) {
            self.listContainer.restore(localData: data.files)
        } else if operational.isServerDataForPersonalFileList {
            self.listContainer.sync(serverData: data.files)
        } else {
            self.listContainer.update(data: data.files)
        }
    }

    var type: SKObserverDataType {
        .specialList(folderKey: api.folderKey)
    }

    var token: String {
        return Self.listToken
    }
}

extension PersonalFileDataModel: FolderPickerDataModel {
    var pickerItems: [SpaceEntry] { listContainer.items }
    var pickerItemChanged: Observable<[SpaceEntry]> { itemChanged }
    var addToCurrentFolderEnabled: Observable<Bool> { .just(true) }

    func resetSortFilterForPicker() {
        filterHelper.update(selectedOption: .all)
        sortHelper.update(selectedOption: SortOption(type: .updateTime, descending: true, allowAscending: false))
    }
}
