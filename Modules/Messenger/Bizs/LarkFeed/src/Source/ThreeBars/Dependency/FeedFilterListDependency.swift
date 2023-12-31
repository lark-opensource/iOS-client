//
//  FeedFilterListDependency.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/3/9.
//

import UIKit
import Foundation
import RustPB
import RxSwift
import RxCocoa
import LarkContainer

protocol FeedFilterListDependency: UserResolverWrapper {
    var filterItems: [FilterItemModel] { get }

    var multiLevelTabs: [Feed_V1_FeedFilter.TypeEnum] { get }

    var subTab: FilterSubSelectedTab? { get }

    var currentTab: Feed_V1_FeedFilter.TypeEnum { get set }

    var currentWindow: UIWindow? { get }

    var filtersUpdateDriver: Driver<Void> { get }

    var styleService: Feed3BarStyleService { get }

    func recordSubSelectedTab(subTab: FilterSubSelectedTab?)

    func getItemsByTab(_ tab: Feed_V1_FeedFilter.TypeEnum) -> [FeedFilterListItemInterface]

    func selectFilterTab(_ type: Feed_V1_FeedFilter.TypeEnum, _ subSelectedId: String?)

    var selectionObservable: Observable<FeedFilterSelection> { get }

    var currentSelection: FeedFilterSelection { get }

    func updateFilterSelection(_ selection: FeedFilterSelection)

    func getExpandState(id: Int) -> Bool

    func updateExpandState(id: Int, isExpand: Bool)

    func getLastOffset() -> CGFloat

    func saveCurrentOffset(_ offset: CGFloat)
}

extension FeedFilterListDependency {
    var filterItems: [FilterItemModel] { return [] }

    var multiLevelTabs: [Feed_V1_FeedFilter.TypeEnum] { return [] }

    var subTab: FilterSubSelectedTab? { return nil }

    var currentWindow: UIWindow? { return nil }

    var filtersUpdateDriver: Driver<Void> { return Driver.empty() }

    func recordSubSelectedTab(subTab: FilterSubSelectedTab?) {}

    func getItemsByTab(_ tab: Feed_V1_FeedFilter.TypeEnum) -> [FeedFilterListItemInterface] { return [] }

    func selectFilterTab(_ type: Feed_V1_FeedFilter.TypeEnum, _ subSelectedId: String?) {}

    var selectionObservable: Observable<FeedFilterSelection> { return Observable.empty() }

    func updateFilterSelection(_ selection: FeedFilterSelection) {}

    func getExpandState(id: Int) -> Bool { return true }

    func updateExpandState(id: Int, isExpand: Bool) {}

    func getLastOffset() -> CGFloat { return 0 }

    func saveCurrentOffset(_ offset: CGFloat) {}
}
