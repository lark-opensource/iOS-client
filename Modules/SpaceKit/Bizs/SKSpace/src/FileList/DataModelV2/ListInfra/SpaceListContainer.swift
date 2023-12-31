//
//  SpaceListContainer.swift
//  SKSpace
//
//  Created by Weston Wu on 2021/6/23.
//

import Foundation
import SKCommon
import SKFoundation
import RxSwift
import RxRelay

extension SpaceListContainer {

    enum State: Equatable {
        /// 尚未完成从本地 DB 恢复数据，也未拉去过服务端数据
        case restoring
        /// 本地数据ready，尚未完成拉取服务端数据
        case syncing
        /// 数据准备已完成
        case ready
    }

    enum PagingState: Equatable {
        case hasMore(lastLabel: String)
        case noMore
    }
}

class SpaceListContainer {

    private let itemsRelay = BehaviorRelay<[SpaceEntry]>(value: [])
    var itemsChanged: Observable<[SpaceEntry]> { itemsRelay.asObservable().skip(1) }
    var items: [SpaceEntry] {
        itemsRelay.value
    }
    var isEmpty: Bool { items.isEmpty }

    private let stateRelay = BehaviorRelay<State>(value: .restoring)
    var stateChanged: Observable<State> { stateRelay.asObservable().skip(1) }
    var state: State {
        stateRelay.value
    }

    // 是否曾经同步过本地的数据
    private(set) var restored: Bool = false
    // 是否曾经同步过服务端的数据，用于网络变化后判断是否需要重新拉取
    private(set) var synced: Bool = false

    private(set) var pagingState = PagingState.noMore
    var hasMore: Bool {
        switch pagingState {
        case .hasMore:
            return true
        case .noMore:
            return false
        }
    }

    private(set) var totalCount = 0

    private let requestBag = DisposeBag()

    let listIdentifier: String

    init(listIdentifier: String) {
        self.listIdentifier = listIdentifier
    }

    func update(pagingState: PagingState) {
        self.pagingState = pagingState
    }

    func update(totalCount: Int) {
        self.totalCount = totalCount
    }

    // 通常的流程是按顺序 restore - sync - update - update - update ...
    // 调整筛选过滤时  ... update - (reset) restore - sync - update ...
    func restore(localData: [SpaceEntry]) {
        if state != .restoring {
            DocsLogger.info("space.list.container --- container has already been restored", extraInfo: ["list-id": listIdentifier, "state": state])
        }
        restored = true
        stateRelay.accept(.syncing)
        itemsRelay.accept(localData)
    }

    func sync(serverData: [SpaceEntry]) {
        if state == .restoring {
            DocsLogger.info("space.list.container --- skipping restoring state", extraInfo: ["list-id": listIdentifier])
        }
        synced = true
        stateRelay.accept(.ready)
        itemsRelay.accept(serverData)
    }

    func update(data: [SpaceEntry]) {
        if state != .ready {
            DocsLogger.info("space.list.container --- updating no-ready container", extraInfo: ["list-id": listIdentifier, "state": state])
        }
        itemsRelay.accept(data)
    }
}
