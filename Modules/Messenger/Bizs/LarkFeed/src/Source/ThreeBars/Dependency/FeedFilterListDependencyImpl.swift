//
//  FeedFilterListDependencyImpl.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/3/9.
//

import UIKit
import Foundation
import RustPB
import LarkOpenFeed
import RxSwift
import RxCocoa
import LarkContainer

final class FeedFilterListDependencyImpl: FeedFilterListDependency {
    let userResolver: UserResolver
    let styleService: Feed3BarStyleService
    let fixedViewModel: FilterFixedViewModel
    let filterDataStore: FilterDataStore
    let context: FeedContextService
    let selectionHandler: FeedFilterSelectionAbility
    var lastOffset: CGFloat = 0
    var filtersUpdateRelay = BehaviorRelay<Void>(value: ())
    var userId: String { userResolver.userID }
    var currentTab: Feed_V1_FeedFilter.TypeEnum
    private var expandMap: [Int: Bool] = [:]  // 展开收起状态
    private let disposeBag = DisposeBag()

    init(resolver: UserResolver,
         filterDataStore: FilterDataStore,
         fixedViewModel: FilterFixedViewModel,
         context: FeedContextService,
         selectionHandler: FeedFilterSelectionAbility,
         styleService: Feed3BarStyleService) {
        self.userResolver = resolver
        self.fixedViewModel = fixedViewModel
        self.filterDataStore = filterDataStore
        self.context = context
        self.selectionHandler = selectionHandler
        self.styleService = styleService
        self.currentTab = context.dataSourceAPI?.currentFilterType ?? .unknown
        if let expandMap = getLastFiltersExpandedState() {
            self.expandMap = expandMap
        }
        bind()
    }

    var filterItems: [FilterItemModel] {
        return filterDataStore.usedFiltersDS
    }

    var multiLevelTabs: [Feed_V1_FeedFilter.TypeEnum] {
        return fixedViewModel.multiLevelTabList
    }

    var subTab: FilterSubSelectedTab? {
        return fixedViewModel.subSelectedTab
    }

    var currentWindow: UIWindow? {
        guard let mainVC = context.page as? FeedMainViewController,
              let window = mainVC.view.window else { return nil }
        return window
    }

    var filtersUpdateDriver: Driver<Void> {
        return filtersUpdateRelay.asDriver()
    }

    func recordSubSelectedTab(subTab: FilterSubSelectedTab?) {
        fixedViewModel.subSelectedTab = subTab
    }

    func getItemsByTab(_ tab: Feed_V1_FeedFilter.TypeEnum) -> [FeedFilterListItemInterface] {
        if multiLevelTabs.contains(tab) {
            guard let source = FeedFilterListSourceFactory.source(for: tab) else { return [] }
            do {
                let items = try source.itemsProvider(userResolver, getSubTabId(tab))
                return items
            } catch {
                let errorMsg = "no itemsProvider \(tab)"
                let info = FeedBaseErrorInfo(type: .error(), errorMsg: errorMsg)
                FeedExceptionTracker.Filter.threeColumns(node: .getItemsByTab, info: info)
            }
        } else if let item = filterDataStore.usedFiltersDS.first(where: { $0.type == tab }) {
            return [FeedFilterListItemModel.transformFilterModel(item, currentTab)]
        }
        return []
    }

    func selectFilterTab(_ type: Feed_V1_FeedFilter.TypeEnum, _ subSelectedId: String?) {
        if let mainVC = context.page as? FeedMainViewController {
            mainVC.didClickFilterItem(type, subSelectedId: subSelectedId)
        }
    }

    var selectionObservable: Observable<FeedFilterSelection> {
        return selectionHandler.selectionObservable
    }

    var currentSelection: FeedFilterSelection {
        return selectionHandler.currentSelection
    }

    func updateFilterSelection(_ selection: FeedFilterSelection) {
        selectionHandler.updateFilterSelection(selection)
    }

    func getExpandState(id: Int) -> Bool {
        return expandMap[id] ?? true
    }

    func updateExpandState(id: Int, isExpand: Bool) {
        expandMap[id] = isExpand
        saveFiltersExpandedState()
    }

    func getLastOffset() -> CGFloat {
        return lastOffset
    }

    func saveCurrentOffset(_ offset: CGFloat) {
        lastOffset = offset
    }

    // MARK: - Private
    private func getSubTabId(_ type: Feed_V1_FeedFilter.TypeEnum) -> String? {
        guard let subTab = self.subTab, subTab.type == type else {
            return nil
        }
        return subTab.tabId
    }

    private func bind() {
        filterDataStore.usedFiltersDSDriver.asObservable()
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] (_) in
            guard let self = self else { return }
            self.filtersUpdateRelay.accept(())
        }).disposed(by: disposeBag)

        for tab in multiLevelTabs {
            if let source = FeedFilterListSourceFactory.source(for: tab) {
                do {
                    try source.observableProvider(userResolver)
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { [weak self] (_) in
                            guard let self = self else { return }
                            self.filtersUpdateRelay.accept(())
                        }).disposed(by: disposeBag)
                } catch {
                    let errorMsg = "no observableProvider \(tab)"
                    let info = FeedBaseErrorInfo(type: .error(), errorMsg: errorMsg)
                    FeedExceptionTracker.Filter.threeColumns(node: .bind, info: info)
                }
            }
        }
    }

    private func saveFiltersExpandedState() {
        FeedKVStorage(userId: userId).saveFiltersExpandedState(expandMap)
    }

    private func getLastFiltersExpandedState() -> [Int: Bool]? {
        return FeedKVStorage(userId: userId).getLastFiltersExpandedState()
    }
}
