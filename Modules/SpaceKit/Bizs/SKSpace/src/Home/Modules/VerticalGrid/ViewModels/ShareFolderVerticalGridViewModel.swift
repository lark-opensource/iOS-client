//
//  ShareFolderVerticalGridViewModel.swift
//  SKECM
//
//  Created by Weston Wu on 2021/2/18.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa
import SKCommon
import SKFoundation
import SKResource
import LarkContainer

public extension SpaceVerticalGridSection.Config {
    static var shareFolder: Self {
        Self(headerTitle: BundleI18n.SKResource.Doc_List_Shared_Folder,
             emptyBehavior: .emptyTips(placeHolder: BundleI18n.SKResource.Doc_List_ShareFolderEmptyTips),
             needBottomSeperator: false)
    }
}

public final class ShareFolderVerticalGridViewModel: SpaceVerticalGridViewModel {
    
    private let workQueue = DispatchQueue(label: "space.vertical-grid.share-folder.vm")
    private let dataModel: ShareFolderDataModel

    private let itemsRelay = BehaviorRelay<[SpaceVerticalGridItem]>(value: [])
    private var items: [SpaceVerticalGridItem] { itemsRelay.value }
    public var itemsUpdated: Observable<[SpaceVerticalGridItem]> {
        itemsRelay.asObservable()
    }

    private let actionInput = PublishRelay<Action>()
    public var actionSignal: Signal<Action> {
        actionInput.asSignal()
    }

    private let reachabilityRelay = BehaviorRelay(value: true)
    private var reachabilityChanged: Observable<Bool> {
        reachabilityRelay.distinctUntilChanged().asObservable()
    }
    private var isReachable: Bool { reachabilityRelay.value }

    private let disposeBag = DisposeBag()

    let userResolver: UserResolver
    init(userResolver: UserResolver, dataModel: ShareFolderDataModel) {
        self.userResolver = userResolver
        self.dataModel = dataModel
    }

    public func prepare() {
        RxNetworkMonitor.networkStatus(observerObj: self)
            .map { $1 }
            .bind(to: reachabilityRelay)
            .disposed(by: disposeBag)

        reachabilityChanged.skip(1)
            .subscribe(onNext: { [weak self] reachable in
                guard let self = self else { return }
                let entries = self.dataModel.listContainer.items
                self.updateList(entries: entries)
                if reachable, !self.dataModel.listContainer.synced {
                    self.dataModel.refresh().subscribe().disposed(by: self.disposeBag)
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

        dataModel.refresh().subscribe().disposed(by: disposeBag)
    }

    public func handleMoreAction() {
        SpaceSubSectionTracker.reportEnter(module: .sharedFolderRoot, srcModule: nil)
        guard let vcFactory = try? userResolver.resolve(assert: SpaceVCFactory.self) else {
            DocsLogger.error("can not get SpaceVCFactory")
            return
        }

        let shareFoldersViewController = vcFactory.makeShareFolderListController(apiType: dataModel.apiType)
        actionInput.accept(.push(viewController: shareFoldersViewController))
        DocsTracker.reportSpaceSharedPageClick(params: .all)
    }

    public func didSelect(item: SpaceVerticalGridItem) {
        let entry = item.entry

        if !isReachable, entry.canOpenWhenOffline == false {
            offlineSelect(entry: entry)
            return
        }

        let entryLists = items.compactMap { item -> SpaceEntry? in
            let entry = item.entry
            if entry.type.isUnknownType { return nil }
            return entry
        }
        entry.fromModule = "shared_folder"
        FileListStatistics.curFileObjToken = entry.objToken
        FileListStatistics.curFileType = entry.type
        FileListStatistics.prepareStatisticsData(.shareFolder)
        let body = SKEntryBody(entry)
        let context: [String: Any] = [SKEntryBody.fileEntryListKey: entryLists,
                                      SKEntryBody.fromKey: FileListStatistics.Module.sharedFolder]
        actionInput.accept(.open(entry: body, context: context))
        SpaceSubSectionTracker.reportEnter(module: .sharedFolderRoot, srcModule: .shared(.sharetome))
        DocsTracker.reportSpaceShareFolderPageClick(params: .listItem(isFolder: true,
                                                                 isShareFolder: true,
                                                                 isSubFolder: false,
                                                                 folderLevel: 0,
                                                                 pageModule: nil,
                                                                      pageSubModule: nil))
    }

    // 离线时点击某文档
    private func offlineSelect(entry: SpaceEntry) {
        let tips: String
        if entry.type == .file {
            tips = BundleI18n.SKResource.Doc_List_OfflineClickTips
        } else {
            tips = BundleI18n.SKResource.Doc_List_OfflineOpenDocFail
        }
        actionInput.accept(.showHUD(.tips(tips)))
    }

    public func notifyPullToRefresh() {
        dataModel.refresh().subscribe().disposed(by: disposeBag)
    }

    private func updateList(entries: [SpaceEntry]) {
        workQueue.async { [weak self] in
            guard let self = self else { return }
            let items = SpaceVerticalGridModelConverter.convert(entries: Array(entries.prefix(12)))
            self.itemsRelay.accept(items)
        }
    }
}
