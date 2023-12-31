//
//  OfflineViewModel.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/18.
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
import SKInfra
import LarkContainer

extension OfflineViewModel {
    public typealias Action = SpaceSection.Action
}

public final class OfflineViewModel: SpaceListViewModel {

    private let workQueue = DispatchQueue(label: "space.offline.list.vm")

    // 表示当前列表是否正在被展示，切换至其他子列表时，isActive 需要置 false
    private(set) var isActive = false

    private let actionInput = PublishRelay<Action>()
    public var actionSignal: Signal<Action> {
        actionInput.asSignal()
    }
    
    let dataModel: ManuOffLineDataModel

    let sortStateRelay = BehaviorRelay<SpaceListFilterState>(value: .deactivated)
    let sortSelectOptionRelay = BehaviorRelay<SpaceSortHelper.SortOption?>(value: nil)
    let titleRelay = BehaviorRelay<String>(value: "")
    let filterStateRelay = BehaviorRelay<SpaceListFilterState>(value: .deactivated)
    var filterState: SpaceListFilterState { filterStateRelay.value }
    var hasActiveFilter: Bool { filterState != .deactivated }

    let updateItemInput = PublishRelay<Void>()

    // 列表中的文档数据
    private let itemsRelay = BehaviorRelay<[SpaceListItem]>(value: [])
    private var items: [SpaceListItem] { itemsRelay.value }

    // 为了适配 drive 的上传进度特殊 cell，这里需要包装一层，和列表展示的数据对应
    private let itemTypesRelay = BehaviorRelay<[SpaceListItemType]>(value: [])
    private var itemTypes: [SpaceListItemType] { itemTypesRelay.value }

    var itemsUpdated: Observable<[SpaceListItemType]> {
        itemTypesRelay.skip(1).asObservable()
    }

    private let reachabilityRelay = BehaviorRelay(value: true)
    var reachabilityChanged: Observable<Bool> {
        reachabilityRelay.distinctUntilChanged().asObservable()
    }
    var isReachable: Bool { reachabilityRelay.value }
    
    private lazy var slideActionHelper: SpaceListSlideDelegateProxyV2 = {
        return SpaceListSlideDelegateProxyV2(helper: self)
    }()

    private let disposeBag = DisposeBag()
    private(set) var tracker = SpaceSubSectionTracker(bizParameter: SpaceBizParameter(module: .offline))

    public init(dataModel: ManuOffLineDataModel) {
        self.dataModel = dataModel
    }

    func prepare() {
        RxNetworkMonitor.networkStatus(observerObj: self)
            .map { $1 }
            .bind(to: reachabilityRelay)
            .disposed(by: disposeBag)
        reachabilityChanged.skip(1)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                let entries = self.dataModel.listContainer.items
                self.didUpdate(entries: entries)
            })
            .disposed(by: disposeBag)

        dataModel.setup()
        dataModel.itemChanged.subscribe(onNext: { [weak self] entries in
            guard let self = self else { return }
            self.didUpdate(entries: entries)
        })
        .disposed(by: disposeBag)
        
        let newSortState = generateFilterState(generateType: .sort)
        sortStateRelay.accept(newSortState)
        sortSelectOptionRelay.accept(dataModel.sortHelper.selectedOption)
        titleRelay.accept(dataModel.sortHelper.selectedOption.legacyItem.fullDescription)
        let newFilterState = generateFilterState(generateType: .filter)
        filterStateRelay.accept(newFilterState)

        itemsRelay.skip(1).subscribe(onNext: { [weak self] items in
            guard let self = self else { return }
            self.update(items: items)
        }).disposed(by: disposeBag)

        updateItemInput.subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            self.update(items: self.items)
        }).disposed(by: disposeBag)
        let filterAction = dataModel.filterHelper.selectedOption.reportName
        let sortAction = dataModel.sortHelper.selectedOption.type.reportName
        tracker.filterAction = filterAction
        tracker.sortAction = sortAction
    }

    func didBecomeActive() {
        isActive = true
        actionInput.accept(.stopPullToLoadMore(hasMore: false))
        tracker.reportEnter(module: "offline", subModule: nil, srcModule: "home")
    }

    func willResignActive() {
        isActive = false
    }

    func select(at index: Int, item: SpaceListItemType) {
        switch item {
        case .inlineSectionSeperator, .gridPlaceHolder:
            return
        case .driveUpload:
            actionInput.accept(.showDriveUploadList(folderToken: ""))
        case let .spaceItem(item):
            didSelect(entry: item.entry)
            // 列表中可能存在drive上传进度等不属于文档的内容，在计算实际点击的位置时，需要排除掉
            let actualIndex: Int
            if let firstIndex = itemTypes.firstIndex(where: \.isDocument) {
                actualIndex = index - firstIndex
            } else {
                actualIndex = index
            }
            tracker.reportClick(entry: item.entry, at: actualIndex)
        }
    }

    private func didSelect(entry: SpaceEntry) {

        // 无网时，可能存在还没有离线成功的文件，需要弹toast提示无法打开
        if !isReachable, entry.canOpenWhenOffline == false {
            let tips: String
            if entry.type == .file {
                tips = BundleI18n.SKResource.Doc_List_OfflineClickTips
            } else {
                tips = BundleI18n.SKResource.Doc_List_OfflineOpenDocFail
            }
            actionInput.accept(.showHUD(.tips(tips)))
            return
        }

        let entryLists = items.compactMap { item -> SpaceEntry? in
            let entry = item.entry
            if entry.type.isUnknownType { return nil }
            return entry
        }
        entry.fromModule = "manualOffline"
        FileListStatistics.curFileObjToken = entry.objToken
        FileListStatistics.curFileType = entry.type
        FileListStatistics.prepareStatisticsData(dataModel.name)
        let body = SKEntryBody(entry)
        let context: [String: Any] = [SKEntryBody.fileEntryListKey: entryLists,
                                      SKEntryBody.fromKey: FileListStatistics.Module.manualOffline]
        actionInput.accept(.open(entry: body, context: context))
    }

    func notifyPullToRefresh() {
        actionInput.accept(.stopPullToRefresh(total: dataModel.listContainer.items.count))
    }

    func notifyPullToLoadMore() {
        actionInput.accept(.stopPullToLoadMore(hasMore: false))
    }

    private func update(items: [SpaceListItem]) {
        var itemTypes: [SpaceListItemType] = []
        let listItems = items.map { SpaceListItemType.spaceItem(item: $0) }
        itemTypes.append(contentsOf: listItems)
        itemTypesRelay.accept(itemTypes)
    }

    func contextMenuConfig(for entry: SpaceEntry) -> SpaceListItem.SlideConfig? {
        generateSlideConfig(for: entry)
    }
}

extension OfflineViewModel {
    private func didUpdate(entries: [SpaceEntry]) {
        workQueue.async { [weak self] in
            guard let self = self else { return }
            let items = SpaceModelConverter.convert(entries: entries,
                                                    context: .init(sortType: self.dataModel.sortHelper.selectedOption.type,
                                                                   folderEntry: nil,
                                                                   listSource: .manualOffline),
                                                    handler: self)
            self.itemsRelay.accept(items)
        }
    }
}

extension OfflineViewModel {

    func generateSortFilterConfig() -> SpaceSortFilterConfig? {
        let sortItems = dataModel.sortHelper.legacyItemsForSortPanel
        let defaultSortItems = dataModel.sortHelper.defaultLegacyItemsForSortPanel
        let filterItems = dataModel.filterHelper.legacyItemsForFilterPanel
        let defaultFilterItems = dataModel.filterHelper.defaultLegacyItemsForFilterPanel
        return SpaceSortFilterConfig(sortItems: sortItems,
                                     defaultSortItems: defaultSortItems,
                                     filterItems: filterItems,
                                     defaultFilterItems: defaultFilterItems)
    }

    private func generateFilterState(generateType: SpaceListFilterState.GenerateType) -> SpaceListFilterState {
        var filterName: String?
        if dataModel.filterHelper.changed {
            filterName = dataModel.filterHelper.selectedOption.displayName
        }
        if filterName == nil {
            return .deactivated
        } else {
            return .activated(type: filterName, sortOption: nil, descending: true)
        }
    }
}

extension OfflineViewModel: SpaceSortPanelDelegate {
    private func generateSortState() -> SpaceListFilterState {
        if dataModel.sortHelper.changed {
            let sortOption = dataModel.sortHelper.selectedOption
            return .activated(type: nil, sortOption: sortOption.type.displayName, descending: sortOption.descending)
        } else {
            return .deactivated
        }
    }
    
    private func sortOptionDidChanged() {
        let newSortState = generateSortState()
        sortStateRelay.accept(newSortState)
        sortSelectOptionRelay.accept(dataModel.sortHelper.selectedOption)
        titleRelay.accept(dataModel.sortHelper.selectedOption.legacyItem.fullDescription)
        actionInput.accept(.stopPullToLoadMore(hasMore: true))
        dataModel.refresh()

        let filterAction = dataModel.filterHelper.selectedOption.reportName
        let sortAction = dataModel.sortHelper.selectedOption.type.reportName
        tracker.reportFilterPanelUpdated(action: "",
                                         filterAction: filterAction,
                                         sortAction: sortAction)
        DocsTracker.reportSpaceHeaderFilterClick(by: nil,
                                                 by: dataModel.sortHelper.selectedOption.legacyItem,
                                                 lastActionName: "",
                                                 eventType: DocsTracker.EventType.spaceOfflinePageView,
                                                 bizParms: tracker.bizParameter)
    }

    public func sortPanel(_ panel: SpaceSortPanelController, didSelect selectionIndex: Int, descending: Bool) {
        dataModel.update(sortIndex: selectionIndex, descending: descending)
        sortOptionDidChanged()
    }

    public func sortPanelDidClickReset(_ panel: SpaceSortPanelController) {
        dataModel.update(sortOption: dataModel.sortHelper.defaultOption)
        sortOptionDidChanged()
    }
}

extension OfflineViewModel: SpaceFilterPanelDelegate {
    public func filterPanel(_ panel: SpaceFilterPanelController, didConfirmWith selection: FilterItem) {
        guard let index = panel.options.firstIndex(where: { $0.filterType == selection.filterType }) else {
            assertionFailure()
            return
        }
        updateFilter(selectionIndex: index, action: "done")
    }

    public func didClickResetFor(filterPanel: SpaceFilterPanelController) {
        updateFilter(selectionIndex: 0, action: "reset")
    }

    private func updateFilter(selectionIndex: Int, action: String) {
        dataModel.update(filterIndex: selectionIndex)
        let newFilterState = generateFilterState(generateType: .filter)
        filterStateRelay.accept(newFilterState)
        actionInput.accept(.stopPullToLoadMore(hasMore: true))
        dataModel.refresh()
        let filterAction = dataModel.filterHelper.selectedOption.reportName
        let sortAction = dataModel.sortHelper.selectedOption.type.reportName
        tracker.reportFilterPanelUpdated(action: action,
                                         filterAction: filterAction,
                                         sortAction: sortAction)
        let filterItem = FilterItem(isSelected: true, filterType: dataModel.filterHelper.selectedOption.legacyType)
        DocsTracker.reportSpaceHeaderFilterClick(by: filterItem,
                                                 by: dataModel.sortHelper.selectedOption.legacyItem,
                                                 lastActionName: action,
                                                 eventType: DocsTracker.EventType.spaceOfflinePageView,
                                                 bizParms: tracker.bizParameter)
    }
}

extension OfflineViewModel: SpaceListItemInteractHandler {
    // 网格模式下，more 按钮
    func handleMoreAction(for entry: SpaceEntry) -> ((UIView) -> Void)? {
        let handler: (UIView) -> Void = { [weak self] view in
            guard let self = self else { return }
            if entry.secretKeyDelete == true {
                self.actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.CreationDoc_Docs_KeyInvalidCanNotOperate)))
                return
            }
            self.tracker.source = .gridMore
            self.showMoreVC(for: entry, sourceView: view, forbiddenItems: [])
            self.tracker.reportClickGridMore(entryType: entry.type)
            
        }
        return handler
    }

    func handlePermissionTips(for entry: SpaceEntry) -> ((UIView) -> Void)? {
        return nil
    }

    func generateSlideConfig(for entry: SpaceEntry) -> SpaceListItem.SlideConfig? {
        let actions: [SlideAction] = [.remove, .share, .more]
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
            case .readyToDelete, .delete, .remove:
                self.handleDelete(for: entry)
            case .share:
                self.slideActionHelper.share(entry: entry, sourceView: cell, shareSource: .list)
            case .more:
                self.showMoreVC(for: entry, sourceView: cell, forbiddenItems: [.share, .delete])
            default:
                spaceAssertionFailure("space.offline.list.vm --- unhandle slide action: \(action)")
                return
            }
        }
    }

    private func showMoreVC(for entry: SpaceEntry, sourceView: UIView, forbiddenItems: [MoreItemType]) {
        var moreProvider = SpaceMoreProviderFactory.createMoreProvider(for: entry, sourceView: sourceView, forbiddenItems: forbiddenItems, listType: .offline)
        moreProvider.handler = slideActionHelper
        let moreVM = MoreViewModel(dataProvider: moreProvider, docsInfo: entry.transform(), moreItemClickTracker: entry.listMoreItemClickTracker)
        let moreVC = MoreViewControllerV2(viewModel: moreVM)
        actionInput.accept(.present(viewController: moreVC, popoverConfiguration: { controller in
            controller.modalPresentationStyle = .popover
            controller.popoverPresentationController?.sourceView = sourceView
            controller.popoverPresentationController?.sourceRect = sourceView.bounds
            controller.popoverPresentationController?.permittedArrowDirections = .any
        }))
    }
}

extension OfflineViewModel {
    func didSelectDeleteAction(file: SpaceEntry, completion: @escaping ((Bool) -> Void)) {
        if slideActionHelper.checkIsColorfulEgg(file: file) {
            let navi = UINavigationController(rootViewController: DocsSercetDebugViewController())
            actionInput.accept(.present(viewController: navi, popoverConfiguration: nil))
            return
        }
        actionInput.accept(.confirmRemoveManualOffline(completion: { confirm in
            completion(confirm)
        }))
    }
    
    func deleteFile(_ file: SpaceEntry) {
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        SKDataManager.shared.resetManualOfflineTag(objToken: file.objToken, isSetManuOffline: false) {
            let moFile = ManualOfflineFile(objToken: file.objToken, type: file.type)
            guard let moMgr = DocsContainer.shared.resolve(FileManualOfflineManagerAPI.self) else {
                return
            }
            moMgr.removeFromOffline(by: moFile)
        }
    }
}

extension OfflineViewModel: SpaceListSlideDelegateHelperV2 {
    var slideActionInput: PublishRelay<SpaceSectionAction> { actionInput }
    var slideTracker: SpaceSubSectionTracker { tracker }
    var listType: SKObserverDataType? { dataModel.type }
    var userID: String { dataModel.userResolver.userID }
    
    var interactionHelper: SpaceInteractionHelper {
        dataModel.interactionHelper
    }

    func refreshForMoreAction() {
        notifyPullToRefresh()
    }
    
    func handleDelete(for entry: SpaceEntry) {
        didSelectDeleteAction(file: entry, completion: { comfirm in
            if comfirm {
                self.deleteFile(entry)
            }
        })
    }
}
