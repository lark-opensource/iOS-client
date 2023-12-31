//
//  SpaceOfflineSection.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/18.
//

import UIKit
import RxSwift
import RxRelay
import RxCocoa
import SKCommon
import SKFoundation
import SKResource
import SKUIKit
import UniverseDesignColor
import UniverseDesignEmpty
import LarkSceneManager
import LarkContainer

public final class SpaceOfflineSection: SpaceListSubSection, SpaceListSectionAutoLayout, SpaceListSectionAutoDataSource, SpaceListSectionCommonDelegate {

    public let identifier: String = "manual-offline"
    public var subSectionTitle: String {
        return isShowInDetail ? BundleI18n.SKResource.LarkCCM_NewCM_Mobile_DocList_Title : BundleI18n.SKResource.Doc_List_OfflineAvailable
    }
    public let subSectionIdentifier: String = "offline"
    
    private let ipadListDefaultSortOption = SpaceSortHelper.SortOption(type: .updateTime, descending: true, allowAscending: false)
    private let ipadListStableSortOption = SpaceSortHelper.SortOption(type: .latestCreated, descending: true, allowAscending: false)

    public var listTools: [SpaceListTool] {
        return [
            .sort(stateRelay: viewModel.sortStateRelay,
                  titleRelay: viewModel.titleRelay,
                  isEnabled: .just(true),
                  clickHandler: { [weak self] view in
                self?.changeSortState(sortView: view)
            }),
            .filter(stateRelay: viewModel.filterStateRelay,
                    isEnabled: .just(true),
                    clickHandler: { [weak self] view in
                        self?.changeFilterState(filterView: view)
                    }),
            .modeSwitch(modeRelay: displayModeRelay, clickHandler: { [weak self] _ in
                self?.switchDisplayMode()
            })
        ]
    }

    public var createIntent: SpaceCreateIntent {
        SpaceCreateIntent(context: .manualOfflines, source: .other, createButtonLocation: .bottomRight)
    }
    
    private let displayModeRelay = BehaviorRelay<SpaceListDisplayMode>(value: .list)
    private var displayMode: SpaceListDisplayMode { displayModeRelay.value }

    private let reloadInput = PublishRelay<ReloadAction>()
    public var reloadSignal: Signal<ReloadAction> {
        reloadInput.asSignal()
    }

    private let actionInput = PublishRelay<Action>()
    public var actionSignal: Signal<Action> {
        actionInput.asSignal()
    }

    private var listState = ListState.loading

    private let viewModel: OfflineViewModel
    private var tracker: SpaceSubSectionTracker { viewModel.tracker }
    private lazy var stateHelper: SpaceSubSectionStateHelper = {
        let differ = SpaceListDifferFactory.createListStateDiffer()
        return SpaceSubSectionStateHelper(differ: differ,
                                          listID: identifier,
                                          stateProvider: self)
    }()

    public private(set) lazy var sectionLayoutHelper: SpaceListSectionLayoutHelper = {
        if isShowInDetail {
            return IpadSpaceSubSectionLayoutHelper(delegate: self)
        } else {
            return SpaceSubSectionLayoutHelper(delegate: self)
        }
    }()

    public var sectionDataSourceHelper: SpaceListSectionDataSourceHelper {
        dataSourceHelper
    }

    private(set) lazy var dataSourceHelper: SpaceListSectionDataSourceHelper = {
        if isShowInDetail {
            let firstSortRelay = BehaviorRelay<SpaceSortHelper.SortType>(value: .updateTime)
            viewModel.sortSelectOptionRelay.compactMap { option in
                guard let option else { return nil }
                if option.type == .title { return nil }
                return option.type
            }.bind(to: firstSortRelay).disposed(by: disposeBag)
            
            let secondSortRelay = BehaviorRelay<SpaceSortHelper.SortType>(value: .latestCreated)
            
            
            return IpadSpaceSubSectionDataSourceHelper(delegate: self,
                                                       firstSortTypeRelay: firstSortRelay,
                                                       secondSortTypeRelay: secondSortRelay)
        } else {
            return SpaceSubSectionDataSourceHelper(delegate: self)
        }
    }()

    public private(set) lazy var sectionDelegateProxy: SpaceListSectionDelegateProxy = {
        if isShowInDetail {
            return IpadSpaceSubSectionDelegateHelper(provider: self)
        } else {
            return SpaceSubSectionDelegateHelper(provider: self)
        }
    }()

    private let disposeBag = DisposeBag()
    
    private let isShowInDetail: Bool

    public init(viewModel: OfflineViewModel, isShowInDetail: Bool = false) {
        self.viewModel = viewModel
        self.isShowInDetail = isShowInDetail
    }

    public func prepare() {
        setupDisplayMode()
        stateHelper.actionSignal.emit(to: actionInput).disposed(by: disposeBag)
        stateHelper.reloadSignal.emit(to: reloadInput).disposed(by: disposeBag)
        viewModel.itemsUpdated.observeOn(SerialDispatchQueueScheduler(internalSerialQueueName: "space.recent.section"))
            .subscribe(onNext: { [weak self] newItems in
                self?.handle(newItems: newItems)
            }).disposed(by: disposeBag)
        viewModel.actionSignal.emit(to: actionInput).disposed(by: disposeBag)
        viewModel.prepare()
    }

    private func setupDisplayMode() {
        let mode: SpaceListDisplayMode = LayoutManager.shared.isGrid ? .grid : .list
        displayModeRelay.accept(mode)

        NotificationCenter.default.rx
            .notification(LayoutManager.layoutChangeNotification)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                let mode: SpaceListDisplayMode = LayoutManager.shared.isGrid ? .grid : .list
                self.displayModeRelay.accept(mode)
                self.reloadInput.accept(.reloadSection(animated: false))
            })
            .disposed(by: disposeBag)
    }

    private func switchDisplayMode() {
        LayoutManager.shared.isGrid = !LayoutManager.shared.isGrid
        let newMode: SpaceListDisplayMode
        if LayoutManager.shared.isGrid {
            newMode = .grid
        } else {
            newMode = .list
        }
        tracker.reportChangeDisplayMode(newMode: newMode)
    }

    private func changeSortState(sortView: UIView) {
        guard let config = viewModel.generateSortFilterConfig() else {
            DocsLogger.error("space.recent.section --- unable to get sort filter config")
            return
        }
        let selectedIndex = config.sortItems.firstIndex(where: \.isSelected) ?? 0
        let panelController = SpaceSortPanelController(options: config.sortItems, initialSelection: selectedIndex, canReset: config.sortChanged)
        panelController.delegate = viewModel
        panelController.setupPopover(sourceView: sortView, direction: .any)
        panelController.popoverPresentationController?.sourceRect = sortView.bounds.inset(by: UIEdgeInsets(top: -4, left: -4, bottom: -4, right: -4)) // 向外偏移一点
        panelController.dismissalStrategy = .larkSizeClassChanged
        actionInput.accept(.present(viewController: panelController, popoverConfiguration: nil))
        tracker.reportClickFilterPanel()
        DocsTracker.reportSpaceHeaderFilterView(bizParms: tracker.bizParameter)
        DocsTracker.reportSpaceOfflinePageClick(params: .filter)
    }

    private func changeFilterState(filterView: UIView) {
        guard let config = viewModel.generateSortFilterConfig() else {
            DocsLogger.error("space.recent.section --- unable to get sort filter config")
            return
        }
        let selectedIndex = config.filterItems.firstIndex(where: \.isSelected) ?? 0
        let panelController = SpaceFilterPanelController(options: config.filterItems, initialSelection: selectedIndex)
        panelController.delegate = viewModel
        panelController.setupPopover(sourceView: filterView, direction: .any)
        panelController.popoverPresentationController?.sourceRect = filterView.bounds.inset(by: UIEdgeInsets(top: -4, left: -4, bottom: -4, right: -4)) // 向外偏移一点
        panelController.dismissalStrategy = .larkSizeClassChanged
        actionInput.accept(.present(viewController: panelController, popoverConfiguration: nil))
        tracker.reportClickFilterPanel()
        DocsTracker.reportSpaceHeaderFilterView(bizParms: tracker.bizParameter)
        DocsTracker.reportSpaceOfflinePageClick(params: .filter)
    }

    public func notifyPullToRefresh() {
        viewModel.notifyPullToRefresh()
    }

    public func notifyPullToLoadMore() {
        viewModel.notifyPullToLoadMore()
    }

    public func notifySectionDidAppear() {
        NotificationCenter.default.post(name: .Docs.notifySelectedSpaceEntarnce, object: (SpaceEntranceSection.EntranceIdentifier.ipadOffline, true))
    }
    
    public func notifySectionWillDisappear() {
        NotificationCenter.default.post(name: .Docs.notifySelectedSpaceEntarnce, object: (SpaceEntranceSection.EntranceIdentifier.ipadOffline, false))
    }
    public func notifyViewDidLayoutSubviews(hostVCWidth: CGFloat) {}

    public func didShowSubSection() {
        viewModel.didBecomeActive()
        switch listState {
        case .empty, .loading:
            actionInput.accept(.stopPullToLoadMore(hasMore: false))
        default:
            break
        }
    }
    public func willHideSubSection() {
        viewModel.willResignActive()
    }
    
    deinit {
        NotificationCenter.default.post(name: .Docs.notifySelectedSpaceEntarnce, object: (SpaceEntranceSection.EntranceIdentifier.ipadOffline, false))
    }
}

extension SpaceOfflineSection: SpaceSubSectionLayoutDelegate {
    var layoutListState: SpaceListSubSection.ListState { listState }
    var layoutDisplayMode: SpaceListDisplayMode { displayMode }
}

extension SpaceOfflineSection: SpaceSectionLayout {}

extension SpaceOfflineSection: SpaceSubSectionDataSourceDelegate {
    var dataSourceListState: SpaceListSubSection.ListState { listState }
    var dataSourceDisplayMode: SpaceListDisplayMode { displayMode }
    var dataSourceCellTrackerModule: PageModule { tracker.module }
}

extension SpaceOfflineSection: SpaceSectionDataSource {

    // 手动离线列表需要额外注册一个 SpaceOfflineEmptyCell，重写下
    public func setup(collectionView: UICollectionView) {
        dataSourceHelper.setup(collectionView: collectionView)
        collectionView.register(SpaceOfflineEmptyCell.self, forCellWithReuseIdentifier: SpaceOfflineEmptyCell.reuseIdentifier)
    }

    // 手动离线列表对于兜底页的处理与其他页面不同，单独重写下
    public func cell(at indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell {
        switch listState {
        case .loading, .failure, .none:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SpacePlaceHolderCell.reuseIdentifier, for: indexPath)
            guard let placeHolderCell = cell as? SpacePlaceHolderCell else {
                assertionFailure()
                return cell
            }
            guard let placeHolderType = listState.asPlaceHolderType else {
                assertionFailure()
                return cell
            }
            placeHolderCell.update(type: placeHolderType)
            return placeHolderCell
        case .empty, .networkUnavailable:
            return collectionView.dequeueReusableCell(withReuseIdentifier: SpaceOfflineEmptyCell.reuseIdentifier, for: indexPath)
        case let .normal(items):
            guard indexPath.item < items.count else {
                assertionFailure()
                return collectionView.dequeueReusableCell(withReuseIdentifier: SpaceListCell.reuseIdentifier, for: indexPath)
            }
            let item = items[indexPath.item]
            if isShowInDetail, let sourceHelper = dataSourceHelper as? IpadSpaceSubSectionDataSourceHelper {
                return sourceHelper.itemCell(at: indexPath, collectionView: collectionView, item: item)
            } else {
                if let sourceHelper = dataSourceHelper as? SpaceSubSectionDataSourceHelper {
                    return sourceHelper.itemCell(at: indexPath, collectionView: collectionView, item: item)
                } else {
                    assertionFailure()
                    return collectionView.dequeueReusableCell(withReuseIdentifier: SpaceListCell.reuseIdentifier, for: indexPath)
                }
            }
        }
    }
}

extension SpaceOfflineSection: SpaceSubSectionDelegateProvider {
    var providerListState: SpaceListSubSection.ListState { listState }
    var listViewModel: SpaceListViewModel { viewModel }
    func open(newScene: Scene) {
        actionInput.accept(.newScene(newScene))
    }
}

extension SpaceOfflineSection: SpaceSectionDelegate {}

extension SpaceOfflineSection: SpaceSubSectionStateProvider {
    var canReloadState: Bool { viewModel.isActive }
    func handle(newState: SpaceListSubSection.ListState, helper: SpaceSubSectionStateHelper) {
        listState = newState
    }
    func didShowListAfterLoading() {}

    private func handle(newItems: [SpaceListItemType]) {
        let newState = newListState(from: newItems)
        stateHelper.handle(newState: newState)
    }

    private func newListState(from newItems: [SpaceListItemType]) -> ListState {
        guard newItems.isEmpty else { return .normal(itemTypes: newItems) }
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        if SKDataManager.shared.dbDataHadReady == false {
            return .loading
        }
        // 手动离线页的空白页比较特殊，不需要这些配置项
        return .empty(description: "",
                      emptyType: .noContent,
                      createEnable: .never(),
                      createButtonTitle: "",
                      createHandler: { _ in })
    }
}

// iPad相关
extension SpaceOfflineSection {
    public var iPadListHeaderSortConfig: IpadListHeaderSortConfig? {
        let selectOptionDriver: Driver<(IpadSpaceSubListHeaderView.Index, SpaceSortHelper.SortOption)>
        selectOptionDriver = viewModel.sortSelectOptionRelay.asDriver(onErrorJustReturn: nil).compactMap { option in
            guard let option else {
                return nil
            }
            var index: IpadSpaceSubListHeaderView.Index
            if option.type == .updateTime {
                index = .second
            } else if option.type == .latestCreated {
                index = .thrid
            } else {
                index = .second
            }
            return (index, option)
        }
        return IpadListHeaderSortConfig(sortOption: [
                                            SpaceSortHelper.SortOption(type: .title, descending: true, allowAscending: false),
                                            SpaceSortHelper.SortOption(type: .updateTime, descending: true, allowAscending: false),
                                            SpaceSortHelper.SortOption(type: .latestCreated, descending: true, allowAscending: false)
                                        ],
                                        displayModeRelay: displayModeRelay,
                                        selectSortOptionDriver: selectOptionDriver)
    }
    
}
