//
//  ShareFolderDataModel.swift
//  SKSpace
//
//  Created by Weston Wu on 2021/10/22.
//

import Foundation
import RxSwift
import RxRelay
import SKCommon
import SKFoundation
import UIKit
import SKWorkspace

extension ShareFolderDataModel {
    typealias SortOption = SpaceSortHelper.SortOption
    typealias ListError = RecentListDataModel.RecentDataError
    private static let dataModelIdentifier = "ShareFolders"
    private static let listToken = "shareRootFolder"
    static let shareFolderNeedUpdate = Notification.Name.Docs.refreshShareSpaceFolderList
}

enum ShareFolderAPIType: String {
    case shareFolderV1  // 1.0共享文件夹列表
    case shareFolderV2  // 2.0共享空间进1.0共享文件夹列表
    case newShareFolder // 2.0新共享空间共享文件夹列表
    case hiddenFolder   // 2.0新共享空间隐藏文件夹列表
}

class ShareFolderDataModel {
    private let disposeBag = DisposeBag()
    private(set) var sortHelper: SpaceSortHelper
    let listContainer: SpaceListContainer
    let interactionHelper: SpaceInteractionHelper
    let currentUserID: String
    private let dataManager: SKDataManager
    private var hasBeenSetup = false
    private let api: ShareFolderListAPI.Type
    private let workQueue = DispatchQueue(label: "space.share-folder.dm.queue")

    var itemChanged: Observable<[SpaceEntry]> {
        listContainer.itemsChanged
    }
    public let hiddenFolderVisableRelay = BehaviorRelay(value: false)
    public let apiType: ShareFolderAPIType

    var toggleHiddenStatusEnabled: Bool { api.toggleHiddenStatusEnabled }

    init(userID: String, usingAPI: ShareFolderAPIType) {
        currentUserID = userID
        apiType = usingAPI
        dataManager = SKDataManager.shared
        sortHelper = SpaceSortHelper.shareFolder
        interactionHelper = SpaceInteractionHelper(dataManager: dataManager)
        listContainer = SpaceListContainer(listIdentifier: Self.dataModelIdentifier)
        switch usingAPI {
        case .shareFolderV1:
            api = V1ShareFolderListAPI.self
        case .shareFolderV2:
            api = V2ShareFolderListAPI.self
        case .newShareFolder:
            api = V3ShareFolderListAPI.self
            sortHelper = SpaceSortHelper.shareFolderV2
        case .hiddenFolder:
            api = HiddenFolderListAPI.self
            sortHelper = SpaceSortHelper.hiddenFolder
        }
    }

    func setup() {
        guard !hasBeenSetup else {
            DocsLogger.error("space.my-folder.dm --- skipping re-setup data model")
            spaceAssertionFailure("re-setup list DM")
            return
        }
        hasBeenSetup = true
        sortHelper.restore()
        dataManager.addObserver(self)
        // 先发 Action 再调用 loadData，保证 addObserver 后一定能收到一次本地数据回调
        dataManager.loadFolderFileEntries(folderKey: api.folderKey, limit: .max)
        dataManager.loadData(currentUserID) { success in
            if !success {
                spaceAssertionFailure("Load DB 竟然失败了 cc @guoqingping")
            }
        }

        NotificationCenter.default.rx.notification(Self.shareFolderNeedUpdate)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.refresh().subscribe().disposed(by: self.disposeBag)
            })
            .disposed(by: disposeBag)
    }

    func refresh() -> Completable {
        return api.queryList(sortOption: sortHelper.selectedOption,
                             extraParams: ThumbnailUrlConfig.gridThumbnailSizeParams)
            .do(onSuccess: { [weak self] dataDiff in
                guard let self = self else { return }
                let pagingState: SpaceListContainer.PagingState
                let pagingInfo = dataDiff.shareFolderPagingInfo
                let totalCount = pagingInfo.total ?? dataDiff.shareFoldersObjs.count
                if pagingInfo.hasMore, let lastLabel = pagingInfo.lastLabel {
                    pagingState = .hasMore(lastLabel: lastLabel)
                    self.hiddenFolderVisableRelay.accept(false)
                } else {
                    pagingState = .noMore
                    self.showHiddenFolderTabIfNeed()
                }
                self.listContainer.update(pagingState: pagingState)
                self.listContainer.update(totalCount: totalCount)
                switch self.apiType {
                case .shareFolderV1, .shareFolderV2:
                    self.dataManager.setShareFolderList(data: dataDiff)
                case .newShareFolder:
                    self.dataManager.setShareFolderListV2(data: dataDiff)
                case .hiddenFolder:
                    self.dataManager.setHiddenFolderList(data: dataDiff)
                }
            }, onError: { error in
                DocsLogger.error("space.shared-folder.dm --- refresh failed", error: error)
            })
                .asCompletable()
    }

    func loadMore() -> Completable {
        guard case let .hasMore(lastLabel) = listContainer.pagingState else {
            listContainer.update(pagingState: .noMore)
            self.showHiddenFolderTabIfNeed()
            DocsLogger.error("space.shared-folder.dm -- cannot load more")
            return .error(ListError.unableToLoadMore)
        }
        
        return api.queryList(sortOption: sortHelper.selectedOption,
                             lastLabel: lastLabel,
                             extraParams: ThumbnailUrlConfig.gridThumbnailSizeParams)
            .do(onSuccess: { [weak self] dataDiff in
                guard let self = self else { return }
                let pagingState: SpaceListContainer.PagingState
                let pagingInfo = dataDiff.shareFolderPagingInfo
                let totalCount = pagingInfo.total ?? dataDiff.shareObjs.count
                if pagingInfo.hasMore, let lastLabel = pagingInfo.lastLabel {
                    pagingState = .hasMore(lastLabel: lastLabel)
                } else {
                    pagingState = .noMore
                    self.showHiddenFolderTabIfNeed()
                }
                self.listContainer.update(pagingState: pagingState)
                self.listContainer.update(totalCount: totalCount)
                if self.apiType == .hiddenFolder {
                    self.dataManager.appendHiddenFolderList(data: dataDiff)
                } else {
                    self.dataManager.appendShareFolderList(data: dataDiff)
                }
            }, onError: { error in
                DocsLogger.error("space.share-folder-listV2.dm -- load more failed", error: error)
            })
            .asCompletable()
    }

    func update(sortIndex: Int, descending: Bool) {
        sortHelper.update(sortIndex: sortIndex, descending: descending)
        sortHelper.store()
    }

    func update(sortOption: SpaceSortHelper.SortOption) {
        sortHelper.update(selectedOption: sortOption)
        sortHelper.store()
    }

    func removeFromList(fileEntry: SpaceEntry) -> Single<SpaceNetworkAPI.DeleteResponse> {
        switch apiType {
        case .shareFolderV1, .shareFolderV2:
            return interactionHelper.removeFromFolder(nodeToken: fileEntry.nodeToken, folderToken: nil).map { _ in .success }
        case .newShareFolder, .hiddenFolder:
            return interactionHelper.deleteV2(objToken: fileEntry.objToken,
                                              nodeToken: fileEntry.nodeToken,
                                              type: fileEntry.type,
                                              isShortCut: false,
                                              canApply: UserScopeNoChangeFG.WWJ.spaceApplyDeleteEnabled)
        }
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

    func isServerDataForShareFolderList(apiType: ShareFolderAPIType) -> Bool {
        switch self {
        case .setShareFolderList:
            return apiType == .shareFolderV1
        case .setShareFolderNewList:
            return apiType == .shareFolderV2
        case .setShareFolderV2List:
            return apiType == .newShareFolder
        case .setHiddenFolderList:
            return apiType == .hiddenFolder
        default:
            return false
        }
    }
    
    var isSetHiddenOperation: Bool {
        switch self {
        case .setHiddenV2:
            return true
        default:
            return false
        }
    }
}

extension ShareFolderDataModel: SKListServiceProtocol {
    public func dataChange(data: SKListData, operational: SKOperational) {
        DocsLogger.debug("space.share-folder.dm.debug --- data changed, operation: \(operational.descriptionInLog), dataCount: \(data.files.count)")
        if operational.isLocalDataForShareFolderList(api.folderKey) {
            self.listContainer.restore(localData: data.files)
        } else if operational.isServerDataForShareFolderList(apiType: apiType) {
            self.listContainer.sync(serverData: data.files)
        } else {
            self.listContainer.update(data: data.files)
        }
        
        if operational.isSetHiddenOperation {
            self.hiddenFolderVisableRelay.accept(true)
        }
    }

    public var type: SKObserverDataType {
        .specialList(folderKey: api.folderKey)
    }

    public var token: String {
        return Self.listToken
    }
}

extension ShareFolderDataModel: FolderPickerDataModel {
    var pickerItems: [SpaceEntry] { listContainer.items }
    var pickerItemChanged: Observable<[SpaceEntry]> { itemChanged }
    var addToCurrentFolderEnabled: Observable<Bool> { .just(false) }

    func resetSortFilterForPicker() {
//        var type: SpaceSortHelper.SortType = .updateTime
//        if apiType == .newShareFolder || apiType == .hiddenFolder {
//            type = .sharedTime
//        }
        sortHelper.update(selectedOption: SortOption(type: .updateTime, descending: true, allowAscending: false))
    }
}

extension ShareFolderDataModel {
    func showHiddenFolderTabIfNeed() {
        guard apiType == .newShareFolder else { return }
        let request = HiddenFolderListAPI.checkHasHiddenFolder()
        request.subscribe(onSuccess: { [weak self] haveHiddenFolder in
            guard let self = self else { return }
            self.hiddenFolderVisableRelay.accept(haveHiddenFolder)
        })
            .disposed(by: disposeBag)
    }
}
