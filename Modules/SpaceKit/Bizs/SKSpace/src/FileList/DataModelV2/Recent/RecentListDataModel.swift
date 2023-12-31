//
//  RecentListDataModel.swift
//  SKSpace
//
//  Created by Weston Wu on 2021/6/23.
//  https://bytedance.feishu.cn/docs/doccnZ8NIowhQC1UetOXigWWgdc#86TNMB
// disable-lint: magic number

import Foundation
import RxSwift
import RxRelay
import SKCommon
import SKFoundation
import SpaceInterface
import SKInfra
import LarkContainer

extension Notification.Name.Docs {
    /// Space 列表的排序过滤选项发生变化，方便多个相同列表间同步筛选过滤状态
    /// userInfo 格式:
    /// [
    ///     "listToken": String,
    ///     "sortOption": SpaceSortHelper.SortOption,
    ///     "filterOption" SpaceSortHelper.FilterOption
    /// ]
    static let SpaceSortFilterStateUpdated = Notification.Name(rawValue: "docs.bytedance.notification.name.Docs.SpaceSortFilterStateUpdated")
}

extension RecentListDataModel {
    // 从配置获取需要拉取的列表数量
    private static var configPageCount: Int? {
        guard let configCount = SettingConfig.workspaceConfig?["workspace_fetch_size"] as? Int,
              configCount > 0 else {
            return nil
        }
        return configCount
    }
    
    static var recentListPageCount: Int {
        let defaultCount = 100
        return configPageCount ?? defaultCount
    }
}

extension RecentListDataModel {
//    typealias FilterOption = SpaceFilterHelper.FilterOption
//    typealias SortOption = SpaceSortHelper.SortOption
    static let recentListNeedUpdate = Notification.Name.Docs.refreshRecentFilesList
    private static let dataModelIdentifier = "RecentFiles"
    static let listToken = "RecentFiles"

    enum RecentDataError: Error {
        // 列表无法加载更多
        case unableToLoadMore
    }

    var pageCount: Int {
        switch homeType {
        case .defaultHome:
            let defaultCount = 100
            return Self.configPageCount ?? defaultCount
        case .baseHomeType:
            return 100
        }
    }
}

private extension SpaceHomeType {
    var folderKey: DocFolderKey {
        switch self {
        case .defaultHome(let isFromV2Tab):
            return isFromV2Tab ? .spaceTabRecent : .recent
        case .baseHomeType:
            return .bitableRecent
        }
    }

    var observerDataType: SKObserverDataType {
        .specialList(folderKey: folderKey)
    }

    var listID: String {
        switch self {
        case let .defaultHome(isFromV2Tab):
            return isFromV2Tab ? "SpaceTabRecent" : "Recent"
        case .baseHomeType:
            return "BitableRecent"
        }
    }
}

public final class RecentListDataModel {
    private let disposeBag = DisposeBag()
    private(set) var sortHelper: SpaceSortHelper
    private(set) var filterHelper: SpaceFilterHelper
    // 每次列表触发刷新后通知
    let reloadSignal = PublishRelay<Void>()
    let listContainer: SpaceListContainer
    let interactionHelper: SpaceInteractionHelper
    let userResolver: UserResolver
    private let dataManager: SpaceRecentListDataProvider
    private var hasBeenSetup = false
    private let api: RecentListAPI.Type

    private let workQueue = DispatchQueue(label: "space.recent.dm.queue")

    var itemChanged: Observable<[SpaceEntry]> {
        listContainer.itemsChanged
    }
    
    var currentUserID: String {
        userResolver.userID
    }

    var homeType: SpaceHomeType

    public convenience init(userResolver: UserResolver, usingLeanModeAPI: Bool, homeType: SpaceHomeType = .spaceTab) {
        let dataManager = SKDataManager.shared
        let listAPI: RecentListAPI.Type

        if usingLeanModeAPI {
            listAPI = LeanModeRecentListAPI.self
        } else {
            listAPI = StandardRecentListAPI.self
        }
        let (sortHelper, filterHelper) = { () -> (SpaceSortHelper, SpaceFilterHelper) in
            switch homeType {
            case .baseHomeType:
                return (.bitableRecent, .bitable)
            case let .defaultHome(isFromV2Tab):
                if isFromV2Tab {
                    return (.spaceTabRecent, .spaceTabRecent)
                } else {
                    return (.recent, .recent)
                }
            }
        }()
        self.init(userResolver: userResolver,
                  dataManager: dataManager,
                  interactionHelper: SpaceInteractionHelper(dataManager: dataManager),
                  sortHelper: sortHelper,
                  filterHelper: filterHelper,
                  listContainer: SpaceListContainer(listIdentifier: Self.dataModelIdentifier),
                  listAPI: listAPI,
                  homeType: homeType)
    }

    // 单测注入用
    init(userResolver: UserResolver,
         dataManager: SpaceRecentListDataProvider,
         interactionHelper: SpaceInteractionHelper,
         sortHelper: SpaceSortHelper,
         filterHelper: SpaceFilterHelper,
         listContainer: SpaceListContainer,
         listAPI: RecentListAPI.Type,
         homeType: SpaceHomeType) {
        self.userResolver = userResolver
        self.dataManager = dataManager
        self.interactionHelper = interactionHelper
        self.sortHelper = sortHelper
        self.filterHelper = filterHelper
        self.listContainer = listContainer
        self.api = listAPI
        self.homeType = homeType
    }

    func setup() {
        guard !hasBeenSetup else {
            DocsLogger.error("space.recent.dm --- skipping re-setup data model")
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

        if case .defaultHome = homeType {
            userResolver.docs.spacePerformanceTracker?.begin(stage: .loadFromDB, scene: .recent)
            userResolver.docs.spacePerformanceTracker?.begin(stage: .loadFromNetwork, scene: .recent)
        }
        dataManager.addObserver(self)
        // 先发 Action 再调用 loadData，保证 addObserver 后一定能收到一次本地数据回调
        dataManager.loadFolderFileEntries(folderKey: homeType.folderKey, limit: pageCount)
        dataManager.loadData(currentUserID) { success in
            if !success {
                spaceAssertionFailure("Load DB 竟然失败了 cc @guoqingping")
            }
        }

        NotificationCenter.default.rx.notification(Self.recentListNeedUpdate)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.refresh().subscribe().disposed(by: self.disposeBag)
            })
            .disposed(by: disposeBag)
    }

    func refresh() -> Completable {
        return api.queryList(count: pageCount,
                             sortOption: sortHelper.selectedOption,
                             filterOption: filterHelper.selectedOption,
                             extraParams: ThumbnailUrlConfig.gridThumbnailSizeParams)
            .do(onSuccess: { [weak self] dataDiff in
                if case .defaultHome = self?.homeType {
                    self?.userResolver.docs.spacePerformanceTracker?.end(stage: .loadFromNetwork, succeed: true, dataSize: dataDiff.recentObjs.count, scene: .recent)
                }
                guard let self = self else { return }
                self.apply(refreshData: dataDiff)
            }, onError: { [weak self] error in
                DocsLogger.error("space.recent.dm --- refresh failed", error: error)
                if case .defaultHome = self?.homeType {
                    self?.userResolver.docs.spacePerformanceTracker?.end(stage: .loadFromNetwork, succeed: false, dataSize: 0, scene: .recent)
                    self?.userResolver.docs.spacePerformanceTracker?.reportLoadingFailed(dataSource: .fromNetwork, reason: error.localizedDescription, scene: .recent)
                }
            })
            .asCompletable()
    }

    func apply(refreshData: FileDataDiff) {
        let pagingState: SpaceListContainer.PagingState
        let pagingInfo = refreshData.recentPagingInfo
        let totalCount = pagingInfo.total ?? refreshData.recentObjs.count
        if pagingInfo.hasMore, let lastLabel = pagingInfo.lastLabel {
            pagingState = .hasMore(lastLabel: lastLabel)
        } else {
            pagingState = .noMore
        }
        self.listContainer.update(pagingState: pagingState)
        self.listContainer.update(totalCount: totalCount)
        self.dataManager.resetRecentFileListOld(data: refreshData, folderKey: homeType.folderKey)
        self.reloadSignal.accept(())
    }

    func loadMore() -> Completable {
        guard case let .hasMore(lastLabel) = listContainer.pagingState else {
            DocsLogger.error("space.recent.dm --- cannot load more")
            return .error(RecentDataError.unableToLoadMore)
        }

        return api.queryList(count: pageCount,
                             lastLabel: lastLabel,
                             sortOption: sortHelper.selectedOption,
                             filterOption: filterHelper.selectedOption,
                             extraParams: ThumbnailUrlConfig.gridThumbnailSizeParams)
            .do(onSuccess: { [weak self] dataDiff in
                guard let self = self else { return }
                let pagingState: SpaceListContainer.PagingState
                let pagingInfo = dataDiff.recentPagingInfo
                let totalCount = pagingInfo.total ?? dataDiff.recentObjs.count
                if pagingInfo.hasMore, let lastLabel = pagingInfo.lastLabel {
                    pagingState = .hasMore(lastLabel: lastLabel)
                } else {
                    pagingState = .noMore
                }
                self.listContainer.update(pagingState: pagingState)
                self.listContainer.update(totalCount: totalCount)
                self.dataManager.appendRecentFileListOld(data: dataDiff, folderKey: self.homeType.folderKey)
            }, onError: { error in
                DocsLogger.error("space.recent.dm --- load more failed", error: error)
            })
            .asCompletable()
    }

    func update(filterIndex: Int) {
        filterHelper.update(filterIndex: filterIndex)
    }

    func update(filterOption: SpaceFilterHelper.FilterOption) {
        filterHelper.update(selectedOption: filterOption)
    }

    func update(sortIndex: Int, descending: Bool) {
        sortHelper.update(sortIndex: sortIndex, descending: descending)
    }

    func update(sortOption: SpaceSortHelper.SortOption) {
        sortHelper.update(selectedOption: sortOption)
    }

    func resetFilterOption() {
        filterHelper.update(selectedOption: filterHelper.defaultOption)
    }

    func resetSortOption() {
        sortHelper.update(selectedOption: sortHelper.defaultOption)
    }

    func notifyWillUpdateFilterSortOption() {
        let tokens = listContainer.items.prefix(pageCount).map(\.objToken)
        let listID = "recent"
        dataManager.save(filterCacheTokens: tokens,
                         listID: listID,
                         filterType: filterHelper.selectedOption.legacyType,
                         sortType: sortHelper.selectedOption.type.legacyType,
                         isAscending: !sortHelper.selectedOption.descending)
    }
    func notifyDidUpdateFilterSortOption() {
        // 在新的首页结构设计上，存在同时展示两个最近列表的场景，由于本地过滤、数据拉取依赖 dataModel 的筛选过滤状态，为了保证多个列表展示的数据一致，需要在 dataModel 之间同步 sortHelper 和 filterHelper 的状态
        sortHelper.store()
        filterHelper.store()
        let listID = "recent"
        dataManager.getFilterCacheTokens(listID: listID,
                                         filterType: filterHelper.selectedOption.legacyType,
                                         sortType: sortHelper.selectedOption.type.legacyType,
                                         isAscending: !sortHelper.selectedOption.descending) { [weak self] tokens in
            guard let self = self else { return }
            guard let tokens = tokens, !tokens.isEmpty else { return }
            self.dataManager.resetRecentFilesByTokens(tokens: tokens, folderKey: self.homeType.folderKey)
        }
    }

    func deleteFromRecentList(objToken: FileListDefine.ObjToken,
                              objType: DocsType) -> Completable {
        api.removeFromRecentList(objToken: objToken, docType: objType)
            .do(onCompleted: { [weak self] in
                guard let self = self else { return }
                self.dataManager.deleteRecentFile(tokens: [objToken])
            })
    }
}

private extension SKOperational {

    func isLocalDataForRecentList(homeType: SpaceHomeType) -> Bool {
        switch self {
        case .loadNewDBData,
             .resetRecentFilesByTokens:
            return true
        case let .loadSpecialFolder(folderKey):
            return folderKey == homeType.folderKey
        default:
            return false
        }
    }

    var isServerDataForRecentList: Bool {
        switch self {
        case .resetRecentFileListOld,
             .appendRecentFileListOld:
            return true
        default:
            return false
        }
    }
}

extension RecentListDataModel: SKListServiceProtocol {
    public func dataChange(data: SKListData, operational: SKOperational) {
        let modifier = api.listModifier(sortOption: sortHelper.selectedOption,
                                        filterOption: filterHelper.selectedOption)
        workQueue.async { [weak self] in
            let entries = modifier.handle(entries: data.files)
            DocsLogger.debug("space.recent.dm.debug --- data changed, operation: \(operational.descriptionInLog), dataCount: \(data.files.count), handledCount: \(entries.count)")
            DispatchQueue.main.async {
                guard let self = self else { return }
                if operational.isLocalDataForRecentList(homeType: self.homeType) {
                    self.listContainer.restore(localData: entries)
                } else if operational.isServerDataForRecentList {
                    self.listContainer.sync(serverData: entries)
                } else {
                    self.listContainer.update(data: entries)
                }

                guard case .defaultHome = self.homeType else { return }
                if operational.isServerDataForRecentList {
                    self.userResolver.docs.spacePerformanceTracker?.reportLoadingSucceed(dataSource: .fromNetwork, scene: .recent)
                } else {
                    if entries.isEmpty {
                        self.userResolver.docs.spacePerformanceTracker?.reportLoadingFailed(dataSource: .fromDBCache, reason: "DB is Empty", scene: .recent)
                    } else {
                        self.userResolver.docs.spacePerformanceTracker?.reportLoadingSucceed(dataSource: .fromDBCache, scene: .recent)
                    }
                    self.userResolver.docs.spacePerformanceTracker?.end(stage: .loadFromDB, succeed: !entries.isEmpty, dataSize: entries.count, scene: .recent)
                }
            }
        }
    }

    public var type: SKObserverDataType {
        homeType.observerDataType
    }

    public var token: String {
        homeType.listID
    }
}

// MARK: 列表自动刷新逻辑，待梳理
extension RecentListDataModel {
    func backgroundReload(size: Int, handler: @escaping () -> Void) {
        fetchCurrentList(size: size) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(dataDiff):
                self.dataManager.mergeRecentFiles(data: dataDiff, folderKey: self.homeType.folderKey)
                DispatchQueue.global().async {
                    Self.preload(data: dataDiff)
                }
            case let .failure(error):
                DocsLogger.error("space.recent.dm --- auto refresh failed to reload in background", error: error)
            }
            handler()
        }
    }

    func fetchCurrentList(size: Int, handler: @escaping (Result<FileDataDiff, Error>) -> Void) {
        DispatchQueue.main.async { [self] in
            api.queryList(count: size,
                          sortOption: sortHelper.selectedOption,
                          filterOption: filterHelper.selectedOption,
                          extraParams: ThumbnailUrlConfig.gridThumbnailSizeParams)
                .subscribe { dataDiff in
                    handler(.success(dataDiff))
                } onError: { error in
                    DocsLogger.error("space.recent.dm --- auto refresh failed to reload in background", error: error)
                    handler(.failure(error))
                }
                .disposed(by: disposeBag)
        }
    }
}

// MARK: - Preload
extension RecentListDataModel {

    // 暂时模仿 RecentFiles 的行为，userLogin 后先取消已有的 preload，然后出发一次preload
    private static var preloadBag = DisposeBag()

    // 获取最近列表第一页的数据并开始预加载
    public static func preloadFirstPage() {
        preloadBag = DisposeBag()
        StandardRecentListAPI.queryList(count: OpenAPI.RecentCacheConfig.preloadClientVarNumber,
                                        extraParams: ThumbnailUrlConfig.gridThumbnailSizeParams)
            .subscribe { dataDiff in
                preload(data: dataDiff, from: "user_login")
            } onError: { error in
                DocsLogger.error("space.recent.dm --- preload first page failed", error: error)
            }
            .disposed(by: preloadBag)
    }

    private static func preload(data: FileDataDiff, from source: String = FromSource.recentPreload.rawValue) {
        let preloadKeys = data.objsInfos
            .prefix(OpenAPI.RecentCacheConfig.preloadClientVarNumber)
            .compactMap { (_, objInfo) -> PreloadKey? in
                guard let fileEntry = DataBuilder.parseNoNodeTokenFileEntryFor(objInfo: objInfo, users: [:]) else { return nil }
                guard fileEntry.type.shouldPreloadClientVar else { return nil }
                var preloadKey = fileEntry.preloadKey
                preloadKey.fromSource = PreloadFromSource(rawValue: source)
                return preloadKey
            }
        DocsLogger.info("getRecentList，add \(preloadKeys.count) recent files to preloadClientvar", component: LogComponents.dataModel + LogComponents.preload)
        let userInfo: [String: Any] = [DocPreloaderManager.preloadNotificationKey: preloadKeys]
        NotificationCenter.default.post(name: Notification.Name.Docs.addToPreloadQueue, object: nil, userInfo: userInfo)
    }
}
