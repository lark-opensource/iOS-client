//
//  FavoritesListDataModel.swift
//  SKSpace
//
//  Created by Weston Wu on 2021/8/20.
//

import Foundation
import RxSwift
import RxRelay
import SKCommon
import SKFoundation

private extension SpaceHomeType {
    var favoriteFolderKey: DocFolderKey {
        switch self {
        case .baseHomeType:
            return .baseFavorites
        case .defaultHome:
            return .fav
        }
    }
}

extension FavoritesDataModel {
//    typealias FilterOption = SpaceFilterHelper.FilterOption
    typealias ListError = RecentListDataModel.RecentDataError

    private static let favoritesListPageCount = 100
    static let favoritesNeedUpdate = Notification.Name("space.favorites.need-update")
    private static let dataModelIdentifier = "Favorites"
    static let listToken = "FavritesModule"
}

public final class FavoritesDataModel {
    private let disposeBag = DisposeBag()

    private(set) var filterHelper: SpaceFilterHelper
    let listContainer: SpaceListContainer
    let interactionHelper: SpaceInteractionHelper
    let currentUserID: String
    private let dataManager: SKDataManager
    private var hasBeenSetup = false
    private let api: FavoritesListAPI.Type
    let folderKey: DocFolderKey

    private let workQueue = DispatchQueue(label: "space.favorites.dm.queue")

    var itemChanged: Observable<[SpaceEntry]> {
        listContainer.itemsChanged
    }

    public init(userID: String, usingV2API: Bool, homeType: SpaceHomeType) {
        currentUserID = userID
        dataManager = SKDataManager.shared
        filterHelper = homeType.isBaseHomeType() ? SpaceFilterHelper.bitable : SpaceFilterHelper.favorites
        folderKey = homeType.favoriteFolderKey
        interactionHelper = SpaceInteractionHelper(dataManager: dataManager)
        listContainer = SpaceListContainer(listIdentifier: Self.dataModelIdentifier)
        if usingV2API {
            api = V2FavoritesListAPI.self
        } else {
            api = V1FavoritesListAPI.self
        }
    }

    func setup() {
        guard !hasBeenSetup else {
            DocsLogger.error("space.favorites.dm --- skipping re-setup data model")
            spaceAssertionFailure("re-setup list DM")
            return
        }
        hasBeenSetup = true
        filterHelper.restore()
        dataManager.addObserver(self)
        // 先发 Action 再调用 loadData，保证 addObserver 后一定能收到一次本地数据回调
        dataManager.loadFolderFileEntries(folderKey: folderKey, limit: .max)
        dataManager.loadData(currentUserID) { success in
            if !success {
                spaceAssertionFailure("Load DB 竟然失败了 cc @guoqingping")
            }
        }

        NotificationCenter.default.rx.notification(Self.favoritesNeedUpdate)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.refresh().subscribe().disposed(by: self.disposeBag)
            })
            .disposed(by: disposeBag)
    }

    func refresh() -> Completable {
        return api.queryList(count: Self.favoritesListPageCount,
                             filterOption: filterHelper.selectedOption,
                             extraParams: ThumbnailUrlConfig.gridThumbnailSizeParams)
            .do(onSuccess: { [weak self] dataDiff in
                guard let self = self else { return }
                let pagingState: SpaceListContainer.PagingState
                let pagingInfo = dataDiff.starPagingInfo
                let totalCount = pagingInfo.total ?? dataDiff.starObjs.count
                if pagingInfo.hasMore, let lastLabel = pagingInfo.lastLabel {
                    pagingState = .hasMore(lastLabel: lastLabel)
                } else {
                    pagingState = .noMore
                }
                self.listContainer.update(pagingState: pagingState)
                self.listContainer.update(totalCount: totalCount)
                self.dataManager.resetFavorites(data: dataDiff, folderKey: self.folderKey)
            }, onError: { error in
                DocsLogger.error("space.favorites.dm --- refresh failed", error: error)
            })
            .asCompletable()
    }

    func loadMore() -> Completable {
        guard case let .hasMore(lastLabel) = listContainer.pagingState else {
            DocsLogger.error("space.favorites.dm --- cannot load more")
            return .error(ListError.unableToLoadMore)
        }
        return api.queryList(count: Self.favoritesListPageCount,
                             lastLabel: lastLabel,
                             filterOption: filterHelper.selectedOption,
                             extraParams: ThumbnailUrlConfig.gridThumbnailSizeParams)
            .do(onSuccess: { [weak self] dataDiff in
                guard let self = self else { return }
                let pagingState: SpaceListContainer.PagingState
                let pagingInfo = dataDiff.starPagingInfo
                let totalCount = pagingInfo.total ?? dataDiff.starObjs.count
                if pagingInfo.hasMore, let lastLabel = pagingInfo.lastLabel {
                    pagingState = .hasMore(lastLabel: lastLabel)
                } else {
                    pagingState = .noMore
                }
                self.listContainer.update(pagingState: pagingState)
                self.listContainer.update(totalCount: totalCount)
                self.dataManager.updateFavorites(data: dataDiff, folderKey: self.folderKey)
            }, onError: { error in
                DocsLogger.error("space.favorites.dm --- load more failed", error: error)
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
}

private extension SKOperational {
    func isLocalDataForFavoritesList(listKey: DocFolderKey) -> Bool {
        switch self {
        case .loadNewDBData:
            return true
        case let .loadSpecialFolder(folderKey):
            return folderKey == listKey
        default:
            return false
        }
    }

    var isServerDataForFavoritesList: Bool {
        switch self {
        case .resetFavorites,
             .updateFavorites:
            return true
        default:
            return false
        }
    }
}

extension FavoritesDataModel: SKListServiceProtocol {
    public func dataChange(data: SKListData, operational: SKOperational) {
        // 由于收藏列表存在本地插入的数据，需要本地做过滤
        let modifier = SpaceListFilterModifier(filterOption: filterHelper.selectedOption)
        workQueue.async { [weak self] in
            let entries = modifier.handle(entries: data.files)
            DocsLogger.debug("space.favorites.dm.debug --- data changed, operation: \(operational.descriptionInLog), originDataCount: \(data.files.count), after modifier: \(entries.count)")
            DispatchQueue.main.async {
                guard let self else { return }
                self.update(entries: entries, operation: operational)
            }
        }
    }

    private func update(entries: [SpaceEntry], operation: SKOperational) {
        if operation.isLocalDataForFavoritesList(listKey: folderKey) {
            listContainer.restore(localData: entries)
        } else if operation.isServerDataForFavoritesList {
            listContainer.sync(serverData: entries)
        } else {
            listContainer.update(data: entries)
        }
    }

    public var type: SKObserverDataType {
        .specialList(folderKey: folderKey)
    }

    public var token: String {
        Self.listToken
    }
}
