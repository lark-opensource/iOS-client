//
//  MyFolderDataModel.swift
//  SKSpace
//
//  Created by Weston Wu on 2021/10/21.
//

import Foundation
import RxSwift
import RxRelay
import SKCommon
import SKFoundation
import SKInfra

extension MyFolderDataModel {
    typealias SortOption = SpaceSortHelper.SortOption
    typealias ListError = RecentListDataModel.RecentDataError
    static let myFolderListPageCount = 100
    static var myFolderNeedUpdate: Notification.Name { PersonalFileDataModel.personalFileNeedUpdate }
    private static let dataModelIdentifier = "myFolderRootPath"
}

class MyFolderDataModel {
    private let disposeBag = DisposeBag()
    private(set) var sortHelper: SpaceSortHelper
    let listContainer: SpaceListContainer
    let interactionHelper: SpaceInteractionHelper
    let currentUserID: String
    private let dataManager: SpaceListDataProvider
    private let networkAPI: MyFolderListAPIType.Type
    private var hasBeenSetup = false
    private let workQueue = DispatchQueue(label: "space.my-folder.dm.queue")

    var itemChanged: Observable<[SpaceEntry]> {
        listContainer.itemsChanged
    }

    convenience init(userID: String) {
        let dataManager = SKDataManager.shared
        self.init(userID: userID,
                  dataManager: dataManager,
                  sortHelper: .myFolder,
                  interactionHelper: SpaceInteractionHelper(dataManager: dataManager),
                  listContainer: SpaceListContainer(listIdentifier: Self.dataModelIdentifier),
                  networkAPI: MyFolderListAPI.self)
    }

    init(userID: String,
         dataManager: SpaceListDataProvider,
         sortHelper: SpaceSortHelper,
         interactionHelper: SpaceInteractionHelper,
         listContainer: SpaceListContainer,
         networkAPI: MyFolderListAPIType.Type) {
        currentUserID = userID
        self.dataManager = dataManager
        self.sortHelper = sortHelper
        self.interactionHelper = interactionHelper
        self.listContainer = listContainer
        self.networkAPI = networkAPI
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
        dataManager.loadFolderFileEntries(folderKey: .myFolderList, limit: .max)
        dataManager.loadData(currentUserID) { success in
            if !success {
                spaceAssertionFailure("Load DB 竟然失败了 cc @guoqingping")
            }
        }

        NotificationCenter.default.rx.notification(Self.myFolderNeedUpdate)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.refresh().subscribe().disposed(by: self.disposeBag)
            })
            .disposed(by: disposeBag)
    }

    func refresh() -> Completable {
        networkAPI.queryList(count: Self.myFolderListPageCount,
                             lastLabel: nil,
                             sortOption: sortHelper.selectedOption,
                             extraParams: ThumbnailUrlConfig.gridThumbnailSizeParams)
            .do(onSuccess: { [weak self] result in
                guard let self = self else { return }
                let dataDiff = result.dataDiff
                let folderToken = result.rootToken ?? ""
                Self.update(rootToken: folderToken)
                let pagingState: SpaceListContainer.PagingState
                let totalCount: Int
                if let pagingInfo = dataDiff.filePaingInfos[folderToken] {
                    if pagingInfo.hasMore, let lastLabel = pagingInfo.lastLabel {
                        pagingState = .hasMore(lastLabel: lastLabel)
                    } else {
                        pagingState = .noMore
                    }
                    totalCount = pagingInfo.total ?? dataDiff.folders[folderToken]?.count ?? 0
                } else {
                    spaceAssertionFailure()
                    pagingState = .noMore
                    totalCount = dataDiff.folders[folderToken]?.count ?? 0
                }
                self.listContainer.update(pagingState: pagingState)
                self.listContainer.update(totalCount: totalCount)
                self.dataManager.setRootFile(data: dataDiff)
            }, onError: { error in
                DocsLogger.error("space.my-folder.dm --- refresh failed", error: error)
            })
            .asCompletable()
    }

    func loadMore() -> Completable {
        guard case let .hasMore(lastLabel) = listContainer.pagingState else {
            DocsLogger.error("space.favorites.dm --- cannot load more")
            return .error(ListError.unableToLoadMore)
        }
        return networkAPI.queryList(count: Self.myFolderListPageCount,
                                    lastLabel: lastLabel,
                                    sortOption: sortHelper.selectedOption,
                                    extraParams: ThumbnailUrlConfig.gridThumbnailSizeParams)
            .do(onSuccess: { [weak self] result in
                guard let self = self else { return }
                let dataDiff = result.dataDiff
                let folderToken = result.rootToken ?? ""
                let pagingState: SpaceListContainer.PagingState
                let totalCount: Int
                if let pagingInfo = dataDiff.filePaingInfos[folderToken] {
                    if pagingInfo.hasMore, let lastLabel = pagingInfo.lastLabel {
                        pagingState = .hasMore(lastLabel: lastLabel)
                    } else {
                        pagingState = .noMore
                    }
                    totalCount = pagingInfo.total ?? dataDiff.folders[folderToken]?.count ?? 0
                } else {
                    spaceAssertionFailure()
                    pagingState = .noMore
                    totalCount = dataDiff.folders[folderToken]?.count ?? 0
                }
                self.listContainer.update(pagingState: pagingState)
                self.listContainer.update(totalCount: totalCount)
                self.dataManager.appendFileList(data: dataDiff)
            }, onError: { error in
                DocsLogger.error("space.my-folder.dm --- load more failed", error: error)
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

    func removeFromList(nodeToken: FileListDefine.NodeToken) -> Completable {
        interactionHelper.removeFromFolder(nodeToken: nodeToken, folderToken: nil).asCompletable()
    }
}

private extension SKOperational {
    var isLocalDataForMyFolderList: Bool {
        switch self {
        case .loadNewDBData:
            return true
        case let .loadSpecialFolder(folderKey):
            return folderKey == .myFolderList
        default:
            return false
        }
    }

    var isServerDataForMyFolderList: Bool {
        switch self {
        case .setRootFile,
            .appendFileList:
            return true
        default:
            return false
        }
    }
}

extension MyFolderDataModel: SKListServiceProtocol {
    public func dataChange(data: SKListData, operational: SKOperational) {
        // 我的文件夹列表需要本地排序逻辑
        let modifier = networkAPI.listModifier(sortOption: sortHelper.selectedOption)
        workQueue.async { [weak self] in
            let entries = modifier.handle(entries: data.files)
            DocsLogger.debug("space.my-folder.dm.debug --- data changed, operation: \(operational.descriptionInLog), dataCount: \(data.files.count), handledCount: \(entries.count)")
            DispatchQueue.main.async {
                guard let self = self else { return }
                if operational.isLocalDataForMyFolderList {
                    self.listContainer.restore(localData: data.files)
                } else if operational.isServerDataForMyFolderList {
                    self.listContainer.sync(serverData: data.files)
                } else {
                    self.listContainer.update(data: data.files)
                }
            }
        }
    }

    public var type: SKObserverDataType {
        .subFolder
    }

    public var token: String {
        return Self.rootToken
    }
}

// 处理 rootToken 逻辑
extension MyFolderDataModel {

    static func update(rootToken: String) {
        CCMKeyValue.userDefault(User.current.basicInfo?.userID ?? "unknown")
            .set(rootToken, forKey: UserDefaultKeys.spaceMyFolderToken)
    }

    static var rootToken: String {
        let kvStorage = CCMKeyValue.userDefault(User.current.basicInfo?.userID ?? "unknown")
        let token = kvStorage.string(forKey: UserDefaultKeys.spaceMyFolderToken)
        return token ?? ""
    }

    static func fetchRootToken(api: MyFolderListAPIType.Type = MyFolderListAPI.self) -> Disposable {
        api.queryList(count: 1).subscribe(onSuccess: { result in
            guard let rootToken = result.rootToken else { return }
            update(rootToken: rootToken)
        })
    }
}

extension MyFolderDataModel: FolderPickerDataModel {
    var pickerItems: [SpaceEntry] { listContainer.items }
    var pickerItemChanged: Observable<[SpaceEntry]> { itemChanged }
    var addToCurrentFolderEnabled: Observable<Bool> { .just(true) }

    func resetSortFilterForPicker() {
        sortHelper.update(selectedOption: SortOption(type: .updateTime, descending: true, allowAscending: false))
    }
}
