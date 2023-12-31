//
//  SpaceListViewModel.swift
//  SKECM
//
//  Created by Weston Wu on 2021/4/20.
//

import UIKit
import SKCommon
import RxSwift
import RxRelay
import RxCocoa

enum ServerDataState {
    // 还未拉取过服务端的数据
    case loading
    // 成功拉取过服务端数据
    case synced
    // 拉取过服务端数据，但是失败了，需要重试
    case fetchFailed
}

protocol SpaceListViewModel {
    typealias Action = SpaceSection.Action

    var tracker: SpaceSubSectionTracker { get }
    var itemsUpdated: Observable<[SpaceListItemType]> { get }
    var actionSignal: Signal<Action> { get }
    var hasActiveFilter: Bool { get }

    func prepare()
    func notifyPullToRefresh()
    func notifyPullToLoadMore()

    // 注意，下述两个生命周期事件并非所有 listSection 都会正常触发，目前为按需通知的方式
    // 目前仅 recentSection 和 recentListViewModel 实现，用户后台停止刷新
    func notifySectionDidAppear()
    func notifySectionWillDisappear()

    var isActive: Bool { get }
    func didBecomeActive()
    func willResignActive()

    // 适配 contextMenu
    func contextMenuConfig(for entry: SpaceEntry) -> SpaceListItem.SlideConfig?
    //func select(at index: Int)
    func select(at index: Int, item: SpaceListItemType)
}

extension SpaceListViewModel {
    func notifySectionDidAppear() {}
    func notifySectionWillDisappear() {}
}

protocol SpaceListFilterDelegate: AnyObject {
    var filterStateRelay: BehaviorRelay<SpaceListFilterState> { get }
    var filterEnabled: Observable<Bool> { get }

    func generateSortFilterConfig() -> SpaceSortFilterConfig?
}
