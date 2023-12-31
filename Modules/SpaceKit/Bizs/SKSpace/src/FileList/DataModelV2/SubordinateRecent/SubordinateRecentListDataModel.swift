//
//  SubordinateRecentListDataModel.swift
//  SKSpace
//
//  Created by peilongfei on 2023/9/13.
//  


import Foundation
import RxSwift
import RxRelay
import SKCommon
import SKFoundation
import SpaceInterface
import SKInfra
import SKResource

extension SubordinateRecentListDataModel {

    private static let dataModelIdentifier = "SubordinateRecent"
    static let listToken = "SubordinateRecent"

    enum RecentDataError: Error {
        // 列表无法加载更多
        case unableToLoadMore
    }

    var pageCount: Int {
        return 40
    }
}

public final class SubordinateRecentListDataModel {
    private let disposeBag = DisposeBag()
    private(set) var sortHelper: SpaceSortHelper
    private(set) var filterHelper: SpaceFilterHelper
    // 每次列表触发刷新后通知
    let reloadSignal = PublishRelay<Void>()
    let listContainer: SpaceListContainer
    let interactionHelper: SpaceInteractionHelper
    let currentUserID: String
    let subordinateID: String
    private let dataManager: SubordinateRecentListDataProvider
    private var hasBeenSetup = false
    private let api: SubordinateRecentListAPI.Type

    private let workQueue = DispatchQueue(label: "space.subordinate-recent.dm.queue")

    var itemChanged: Observable<[SpaceEntry]> {
        listContainer.itemsChanged
    }

    let titleRelay = BehaviorRelay<String>(value: BundleI18n.SKResource.LarkCCM_CM_LeaderAccess_RecentDocs_Title(BundleI18n.SKResource.Doc_Permission_AddUserSubDep))

    public convenience init(userID: String, subordinateID: String) {
        let dataManager = SKDataManager.shared
        let listAPI = SubordinateRecentListAPI.self

        self.init(userID: userID,
                  subordinateID: subordinateID,
                  dataManager: dataManager,
                  interactionHelper: SpaceInteractionHelper(dataManager: dataManager),
                  sortHelper: SpaceSortHelper.subordinateRecent(id: subordinateID),
                  filterHelper: SpaceFilterHelper.subordinateRecent(id: subordinateID),
                  listContainer: SpaceListContainer(listIdentifier: Self.dataModelIdentifier),
                  listAPI: listAPI)
    }

    // 单测注入用
    init(userID: String,
         subordinateID: String,
         dataManager: SubordinateRecentListDataProvider,
         interactionHelper: SpaceInteractionHelper,
         sortHelper: SpaceSortHelper,
         filterHelper: SpaceFilterHelper,
         listContainer: SpaceListContainer,
         listAPI: SubordinateRecentListAPI.Type) {
        self.currentUserID = userID
        self.subordinateID = subordinateID
        self.dataManager = dataManager
        self.interactionHelper = interactionHelper
        self.sortHelper = sortHelper
        self.filterHelper = filterHelper
        self.listContainer = listContainer
        self.api = listAPI
    }

    func setup() {
        guard !hasBeenSetup else {
            DocsLogger.error("space.subordinate-recent.dm --- skipping re-setup data model")
            spaceAssertionFailure("re-setup list DM")
            return
        }
        hasBeenSetup = true
        sortHelper.restore()
        filterHelper.restore()

        // 屏蔽特定的排序搜索组合
        if sortHelper.selectedOption.type == .lastModifiedTime,
           filterHelper.selectedOption == .wiki {
            // 重置为默认状态
            sortHelper.update(sortIndex: 0, descending: true)
            filterHelper.update(filterIndex: 0)
        }
        
        dataManager.addObserver(self)
        // 先发 Action 再调用 loadData，保证 addObserver 后一定能收到一次本地数据回调
        dataManager.loadSubordinateRecentEntries(subordinateID: subordinateID)
        dataManager.loadData(currentUserID) { success in
            if !success {
                spaceAssertionFailure("Load DB failed")
            }
        }
        dataManager.userInfoFor(subordinateID: subordinateID) { [weak self] userInfo in
            guard let userInfo else { return }
            let title = BundleI18n.SKResource.LarkCCM_CM_LeaderAccess_RecentDocs_Title(userInfo.nameForDisplay())
            self?.titleRelay.accept(title)
        }

        NotificationCenter.default.rx.notification(.Docs.SpaceSortFilterStateUpdated)
            .filter { [weak self] notification in
                (notification.userInfo?["listToken"] as? String) == self?.token
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] notificaiton in
                guard let self else { return }
                if let sortOption = notificaiton.userInfo?["sortOption"] as? SpaceSortHelper.SortOption {
                    self.sortHelper.update(selectedOption: sortOption)
                }
                if let filterOption = notificaiton.userInfo?["filterOption"] as? SpaceFilterHelper.FilterOption {
                    self.filterHelper.update(selectedOption: filterOption)
                }
            })
            .disposed(by: disposeBag)
    }

    func refresh() -> Completable {
        return api.queryList(subordinateID: subordinateID,
                             count: pageCount,
                             sortOption: sortHelper.selectedOption,
                             filterOption: filterHelper.selectedOption,
                             extraParams: ThumbnailUrlConfig.gridThumbnailSizeParams)
            .do(onSuccess: { [weak self] dataDiff, userInfo in
                guard let self = self else { return }
                self.titleRelay.accept(BundleI18n.SKResource.LarkCCM_CM_LeaderAccess_RecentDocs_Title(userInfo.nameForDisplay()))
                self.apply(refreshData: dataDiff)
            }, onError: { error in
                DocsLogger.error("space.subordinate-recent.dm --- refresh failed", error: error)
            })
            .asCompletable()
    }

    func apply(refreshData: FileDataDiff) {
        let pagingState: SpaceListContainer.PagingState
        let pagingInfo = refreshData.filePaingInfos[subordinateID]
        let totalCount = pagingInfo?.total ?? refreshData.nodes.count
        if pagingInfo?.hasMore == true, let lastLabel = pagingInfo?.lastLabel {
            pagingState = .hasMore(lastLabel: lastLabel)
        } else {
            pagingState = .noMore
        }
        self.listContainer.update(pagingState: pagingState)
        self.listContainer.update(totalCount: totalCount)

        self.dataManager.setRootFile(data: refreshData) { _ in }
        
        self.reloadSignal.accept(())
    }

    func loadMore() -> Completable {
        guard case let .hasMore(lastLabel) = listContainer.pagingState else {
            DocsLogger.error("space.subordinate-recent.dm --- cannot load more")
            return .error(RecentDataError.unableToLoadMore)
        }

        return api.queryList(subordinateID: subordinateID,
                             count: pageCount,
                             lastLabel: lastLabel,
                             sortOption: sortHelper.selectedOption,
                             filterOption: filterHelper.selectedOption,
                             extraParams: ThumbnailUrlConfig.gridThumbnailSizeParams)
            .do(onSuccess: { [weak self] dataDiff, _ in
                guard let self = self else { return }
                let pagingState: SpaceListContainer.PagingState
                let pagingInfo = dataDiff.filePaingInfos[self.subordinateID]
                let totalCount = pagingInfo?.total ?? dataDiff.nodes.count
                if pagingInfo?.hasMore == true, let lastLabel = pagingInfo?.lastLabel {
                    pagingState = .hasMore(lastLabel: lastLabel)
                } else {
                    pagingState = .noMore
                }
                self.listContainer.update(pagingState: pagingState)
                self.listContainer.update(totalCount: totalCount)
                self.dataManager.appendFileList(data: dataDiff)
            }, onError: { error in
                DocsLogger.error("space.subordinate-recent.dm --- load more failed", error: error)
            })
            .asCompletable()
    }

    func update(filterIndex: Int) {
        filterHelper.update(filterIndex: filterIndex)
    }

    func update(sortIndex: Int, descending: Bool) {
        sortHelper.update(sortIndex: sortIndex, descending: descending)
    }

    func resetFilterOption() {
        filterHelper.update(selectedOption: filterHelper.defaultOption)
    }

    func resetSortOption() {
        sortHelper.update(selectedOption: sortHelper.defaultOption)
    }

}

private extension SKOperational {

    func isLocalDataForSubordinateRecentList(subordinateID: String) -> Bool {
        switch self {
        case .openNoCacheFolderLink:
            return true
        case let .loadSubFolder(id):
            return subordinateID == id
        default:
            return false
        }
    }

    var isServerDataForSubordinateRecentList: Bool {
        switch self {
        case .setRootFile,
                .appendFileList:
            return true
        default:
            return false
        }
    }
}

extension SubordinateRecentListDataModel {

    func fetchCurrentList(size: Int, handler: @escaping (Result<FileDataDiff, Error>) -> Void) {
        DispatchQueue.main.async { [self] in
            api.queryList(subordinateID: subordinateID,
                          count: size,
                          sortOption: sortHelper.selectedOption,
                          filterOption: filterHelper.selectedOption,
                          extraParams: ThumbnailUrlConfig.gridThumbnailSizeParams)
                .subscribe { dataDiff, _ in
                    handler(.success(dataDiff))
                } onError: { error in
                    DocsLogger.error("space.subordinate-recent.dm --- auto refresh failed to reload in background", error: error)
                    handler(.failure(error))
                }
                .disposed(by: disposeBag)
        }
    }

}

extension SubordinateRecentListDataModel: SKListServiceProtocol {
    public func dataChange(data: SKListData, operational: SKOperational) {
        DocsLogger.debug("space.subordinate-recent.dm --- data changed, operation: \(operational.descriptionInLog), dataCount: \(data.files.count)")
        data.files.forEach { entry in
            entry.update(nodeToken: "")
        }
        if operational.isLocalDataForSubordinateRecentList(subordinateID: subordinateID) {
            listContainer.restore(localData: data.files)
        } else if operational.isServerDataForSubordinateRecentList {
            listContainer.sync(serverData: data.files)
        } else {
            listContainer.update(data: data.files)
        }
    }

    public var type: SKObserverDataType {
        .subFolder
    }

    public var token: String {
        subordinateID
    }
}
