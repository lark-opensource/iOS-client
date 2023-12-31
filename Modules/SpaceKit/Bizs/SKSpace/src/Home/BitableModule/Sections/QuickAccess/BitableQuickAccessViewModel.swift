//
//  BitableQuickAccessViewModel.swift
//  SKSpace
//
//  Created by ByteDance on 2023/10/27.
//

import Foundation
import SKCommon
import RxSwift
import RxRelay
import RxCocoa
import SKFoundation
import SwiftyJSON
import EENavigator
import SKResource

extension BitableQuickAccessViewModel {
    public typealias Action = SpaceSection.Action
}

public final class BitableQuickAccessViewModel: SpaceListViewModel {

    private let workQueue = DispatchQueue(label: "bitable.pin.list.vm")

    // 表示当前列表是否正在被展示，切换至其他子列表时，isActive 需要置 false
    private(set) var isActive = false
    // 表明是否请求过服务端数据，用于解决本地为空的情况下，继续展示loading
    private(set) var serverDataState = ServerDataState.loading
    var hasActiveFilter: Bool { false }

    private let actionInput = PublishRelay<Action>()
    public var actionSignal: Signal<Action> {
        actionInput.asSignal()
    }

    let dataModel: QuickAccessDataModel
    let homeType: SpaceHomeType

    private let itemsRelay = BehaviorRelay<[SpaceListItem]>(value: [])
    private var items: [SpaceListItem] { itemsRelay.value }

    var itemsUpdated: Observable<[SpaceListItemType]> {
        itemsRelay.skip(1).map {
            $0.map(SpaceListItemType.spaceItem(item:))
        }.asObservable()
    }

    private let reachabilityRelay = BehaviorRelay(value: true)
    private var reachabilityChanged: Observable<Bool> {
        reachabilityRelay.distinctUntilChanged().asObservable()
    }

    var isReachable: Bool { reachabilityRelay.value }

    private lazy var slideActionHelper: SpaceListSlideDelegateProxyV2 = {
        return SpaceListSlideDelegateProxyV2(helper: self)
    }()

    private let disposeBag = DisposeBag()
    private(set) var tracker = SpaceSubSectionTracker(bizParameter: SpaceBizParameter(module: .home(.quickaccess)))

    public init(dataModel: QuickAccessDataModel, homeType: SpaceHomeType = .spaceTab) {
        self.dataModel = dataModel
        self.homeType = homeType
        
        if case .baseHomeType = homeType, let module = homeType.pageModule() {
            tracker = SpaceSubSectionTracker(bizParameter: SpaceBizParameter(module: module))
        }
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
                    self.dataModel.refresh().subscribe().disposed(by: self.disposeBag)
                }
            })
            .disposed(by: disposeBag)

        dataModel.setup()
        dataModel.itemChanged.subscribe(onNext: { [weak self] entries in
            guard let self = self else { return }
            self.updateList(entries: entries)
        })
        .disposed(by: disposeBag)

        dataModel.refresh().subscribe { [weak self] in
            guard let self = self else { return }
            self.actionInput.accept(.stopPullToLoadMore(hasMore: false))
            self.serverDataState = .synced
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
        }
        .disposed(by: disposeBag)
    }

    func didBecomeActive() {
        isActive = true
        actionInput.accept(.stopPullToLoadMore(hasMore: false))
        tracker.reportEnter(module: "home", subModule: "quickaccess", srcModule: nil)
    }

    func willResignActive() {
        isActive = false
    }
    
    func select(at index: Int, item: SpaceListItemType) {
        guard case let .spaceItem(spaceItem) = item else { return }
        let entry = spaceItem.entry
        tracker.reportClick(entry: entry, at: index, pageModule: homeType.pageModule(), pageSubModule: .quickaccess)
        if !isReachable, entry.canOpenWhenOffline == false {
            offlineSelect(entry: entry)
            return
        }

        let entryLists = items.compactMap { item -> SpaceEntry? in
            let entry = item.entry
            if entry.type.isUnknownType { return nil }
            return entry
        }
        entry.fromModule = dataModel.token
        FileListStatistics.curFileObjToken = entry.objToken
        FileListStatistics.curFileType = entry.type
        FileListStatistics.prepareStatisticsData(.pin)
        let body = SKEntryBody(entry)
        var context: [String: Any] = [SKEntryBody.fileEntryListKey: entryLists,
                                      SKEntryBody.fromKey: FileListStatistics.Module.quickaccess]
        if case let .baseHomeType(ctx) = homeType {
            context[SKEntryBody.fromKey] = ctx.containerEnv == .larkTab ? FileListStatistics.Module.baseHomeLarkTabQuickAccessV4 : FileListStatistics.Module.baseHomeWorkbenchQuickAccessV4
        }
        actionInput.accept(.open(entry: body, context: context))
        if let folder = entry as? FolderEntry {
            tracker.reportEnter(folderToken: folder.objToken,
                                isShareFolder: folder.isShareFolder,
                                currentModule: "quickaccess",
                                currentFolderToken: nil,
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
            DocsLogger.info("bitable.recent.list.vm --- drive disable by FG, forbidden offline open drive action")
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
        var entries = entries
        if case .baseHomeType = homeType {
            entries = entries.filter({ entry in
                entry.docsType == .bitable
            })
        }
        
        // 适配Base的方图标
        var config: SpaceModelConverter.Config
        switch self.homeType{
        case .baseHomeType:
            if UserScopeNoChangeFG.QYK.btSquareIcon { config = .baseHome } else { config = .default }
        default:
            config = .default
        }
        
        workQueue.async { [weak self] in
            guard let self = self else { return }
            let items = SpaceModelConverter.convert(entries: entries,
                                                    context: .init(sortType: .updateTime,
                                                                   folderEntry: nil,
                                                                   listSource: .pin),
                                                    config: config,
                                                    handler: self)
            self.itemsRelay.accept(items)
        }
    }

    func notifyPullToRefresh() {
        serverDataState = .loading
        dataModel.refresh().subscribe { [weak self] in
            guard let self = self else { return }
            self.serverDataState = .synced
            var total = self.dataModel.listContainer.totalCount
            if case .baseHomeType = self.homeType {
                total = self.dataModel.listContainer.items.filter({ entry in
                    entry.docsType == .bitable
                }).count
            }
            self.actionInput.accept(.stopPullToRefresh(total: total))
            self.actionInput.accept(.stopPullToLoadMore(hasMore: false))
        } onError: { [weak self] error in
            guard let self = self else { return }
            self.actionInput.accept(.stopPullToRefresh(total: nil))
            DocsLogger.error("bitable.quickaccess.list.vm --- pull to refresh failed with error", error: error)
            // show error
            self.serverDataState = .fetchFailed
            self.itemsRelay.accept(self.items)
            return
        }
        .disposed(by: disposeBag)
    }

    func notifyPullToLoadMore() {
        actionInput.accept(.stopPullToLoadMore(hasMore: false))
    }

    func contextMenuConfig(for entry: SpaceEntry) -> SpaceListItem.SlideConfig? {
        generateSlideConfig(for: entry)
    }
}

extension BitableQuickAccessViewModel: SpaceListItemInteractHandler {
    // 网格模式下，more 按钮
    func handleMoreAction(for entry: SpaceEntry) -> ((UIView) -> Void)? {
        let handler: (UIView) -> Void = { [weak self] view in
            guard let self = self else { return }
            if entry.secretKeyDelete == true {
                self.actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.CreationDoc_Docs_KeyInvalidCanNotOperate)))
                return
            }
            self.tracker.source = .gridMore
            var forbiddenItesm: [MoreItemType] = [.delete]
            /// 出现在快速访问列表里已经不在知识库的wiki文档，隐藏收藏
            if entry.type == .wiki, let wikiEntry = entry as? WikiEntry, !wikiEntry.contentExistInWiki {
                forbiddenItesm = [.delete, .star, .unStar]
            }
            self.showMoreVC(for: entry, sourceView: view, forbiddenItems: forbiddenItesm)
            self.tracker.reportClickGridMore(entryType: entry.type)
        }
        return handler
    }

    func handlePermissionTips(for entry: SpaceEntry) -> ((UIView) -> Void)? {
        return nil
    }

    func generateSlideConfig(for entry: SpaceEntry) -> SpaceListItem.SlideConfig? {
        let actions: [SlideAction] = [.removeFromPin, .share, .more]
        return SpaceListItem.SlideConfig(actions: actions) { [weak self] (cell, action) in
            guard let self = self else { return }
            if entry.secretKeyDelete == true {
                self.actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.CreationDoc_Docs_KeyInvalidCanNotOperate)))
                return
            }
            self.tracker.source = .slide
            self.tracker.bizParameter.update(fileID: entry.objToken, fileType: entry.docsType, driveType: entry.fileType)
            self.tracker.reportClick(slideAction: action)
            switch action {
            case .removeFromPin:
                self.slideActionHelper.toggleQuickAccess(for: entry)
            case .share:
                self.slideActionHelper.share(entry: entry, sourceView: cell, shareSource: .list)
            case .more:
                var forbiddenItems: [MoreItemType] = [.share, .delete]
                /// 出现在快速访问列表里已经不在知识库的wiki文档，隐藏收藏
                if entry.type == .wiki, let wikiEntry = entry as? WikiEntry, !wikiEntry.contentExistInWiki {
                    forbiddenItems = [.share, .delete, .star, .unStar]
                }
                self.showMoreVC(for: entry, sourceView: cell, forbiddenItems: forbiddenItems)
            default:
                spaceAssertionFailure("bitable.pins.list.vm --- unhandle slide action: \(action)")
                return
            }
        }
    }

    private func showMoreVC(for entry: SpaceEntry, sourceView: UIView, forbiddenItems: [MoreItemType]) {
        var moreProvider = SpaceMoreProviderFactory.createMoreProvider(for: entry, sourceView: sourceView, forbiddenItems: forbiddenItems, listType: .quickAccess)
        var listMoreItemClickTracker = entry.listMoreItemClickTracker
        if case .baseHomeType = homeType {
            moreProvider = SpaceMoreProviderFactory.createMoreProvider(for: entry,
                                                                       sourceView: sourceView,
                                                                       forbiddenItems: forbiddenItems,
                                                                       needShowItems: [.copyLink, .copyFile, .sensitivtyLabel, .pin, .unPin, .star, .unStar], listType: .quickAccess)
            listMoreItemClickTracker.setIsBitableHome(true)
            listMoreItemClickTracker.setSubModule(.quickaccess)
        }
        moreProvider.handler = slideActionHelper
        let moreVM = MoreViewModel(dataProvider: moreProvider, docsInfo: entry.transform(), moreItemClickTracker: listMoreItemClickTracker)
        let moreVC = MoreViewControllerV2(viewModel: moreVM)
        // iPad 分屏时，存在导航栏盖在 more
        moreVC.modalPresentationStyle = .overFullScreen
        actionInput.accept(.present(viewController: moreVC, popoverConfiguration: { controller in
            controller.modalPresentationStyle = .popover
            controller.popoverPresentationController?.sourceView = sourceView
            controller.popoverPresentationController?.sourceRect = sourceView.bounds
            controller.popoverPresentationController?.permittedArrowDirections = .any
        }))
    }
}

// SlideAction
extension BitableQuickAccessViewModel: SpaceListSlideDelegateHelperV2 {

    var slideActionInput: PublishRelay<SpaceSection.Action> { actionInput }
    var slideTracker: SpaceSubSectionTracker { tracker }
    var interactionHelper: SpaceInteractionHelper { dataModel.interactionHelper }
    var listType: SKObserverDataType? { dataModel.type }
    var userID: String { dataModel.currentUserID }

    func refreshForMoreAction() {
        notifyPullToRefresh()
    }

    func handleDelete(for entry: SpaceEntry) {}
}
