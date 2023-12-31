//
//  PersonalFolderVerticalGridViewModel.swift
//  SKECM
//
//  Created by Weston Wu on 2021/2/18.
//
// disable-lint: magic number

import Foundation
import RxSwift
import RxRelay
import RxCocoa
import SKCommon
import SKFoundation
import SKResource
import LarkContainer

public extension SpaceVerticalGridSection.Config {
    static var personalFolder: Self {
        Self(headerTitle: BundleI18n.SKResource.Doc_List_My_Folder,
             emptyBehavior: .hide,
             needBottomSeperator: false)
    }
}

public final class PersonalFolderVerticalGridViewModel: SpaceVerticalGridViewModel {

    private let workQueue = DispatchQueue(label: "space.vertical-grid.personal-folder.vm")
    private let dataModel: MyFolderDataModel

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
    init(userResolver: UserResolver, dataModel: MyFolderDataModel) {
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
        dataModel.refresh().subscribe().disposed(by: disposeBag)
    }

    public func handleMoreAction() {
        SpaceSubSectionTracker.reportEnter(module: .personalFolderRoot, srcModule: nil)
        guard let vcFactory = try? userResolver.resolve(assert: SpaceVCFactory.self) else {
            DocsLogger.error("can not get SpaceVCFactory")
            return
        }

        let personalFolderViewController = vcFactory.makeMyFolderListController()
        actionInput.accept(.push(viewController: personalFolderViewController))
        DocsTracker.reportSpacePersonalPageClick(params: .all)
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
        entry.fromModule = "personal_folder"
        FileListStatistics.curFileObjToken = entry.objToken
        FileListStatistics.curFileType = entry.type
        FileListStatistics.prepareStatisticsData(.myFolderList)
        let body = SKEntryBody(entry)
        let context: [String: Any] = [SKEntryBody.fileEntryListKey: entryLists,
                                      SKEntryBody.fromKey: FileListStatistics.Module.personal]
        actionInput.accept(.open(entry: body, context: context))
        SpaceSubSectionTracker.reportEnter(module: .personalFolderRoot, srcModule: nil)
        DocsTracker.reportSpacePersonalPageClick(params: .listItem(isFolder: entry.type == .folder,
                                                                   isShareFolder: entry.isShareFolder,
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
