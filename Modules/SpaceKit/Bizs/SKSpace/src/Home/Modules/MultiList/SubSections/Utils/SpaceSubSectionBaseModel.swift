//
//  SpaceSubSectionBaseModel.swift
//  SKSpace
//
//  Created by Weston Wu on 2023/2/21.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa

protocol SpaceSubSectionStateProvider: AnyObject {
    /// 是否允许列表变化触发 UI 更新
    /// 仅在增量 diff 场景有效，原因是 diff 逻辑需要在 diff 闭包内更新列表数据，
    /// 但当前 section 可能在 multiSection 内且处于不可见状态，导致 diff 闭包不被执行，可能导致数据不一致问题
    /// 此 flag 的状态不正确可能导致数据不一致问题，目前只应该和 multiSection 的逻辑有关联
    var canReloadState: Bool { get }
    func handle(newState: SpaceListSubSection.ListState, helper: SpaceSubSectionStateHelper)
    // 从 loading 切换到列表内容后的事件，部分列表用于预加载的时机
    func didShowListAfterLoading()
}
// 收敛各 SpaceSection 的 ListState 通用逻辑
class SpaceSubSectionStateHelper {
    // 区分列表打 log 用
    let listID: String
    let differ: SpaceListStateDiffer

    private let actionInput = PublishRelay<SpaceSectionAction>()
    var actionSignal: Signal<SpaceSectionAction> {
        actionInput.asSignal()
    }

    private let reloadInput = PublishRelay<SpaceSectionReloadAction>()
    var reloadSignal: Signal<SpaceSectionReloadAction> {
        reloadInput.asSignal()
    }

    weak var stateProvider: SpaceSubSectionStateProvider?

    init(differ: SpaceListStateDiffer, listID: String, stateProvider: SpaceSubSectionStateProvider) {
        self.differ = differ
        self.listID = listID
        self.stateProvider = stateProvider
    }

    func handle(newState: SpaceListSubSection.ListState) {
        let transaction = differ.handle(newState: newState)
        switch transaction {
        case .updateList(diffResults: let diffResults):
            diffResults.forEach { result in
                let completion: () -> Void
                switch result {
                case let .none(newList):
                    completion = { [weak self, weak stateProvider] in
                        guard let self else { return }
                        stateProvider?.handle(newState: .normal(itemTypes: newList),
                                              helper: self)
                    }
                case let .reload(newList):
                    completion = { [weak self, weak stateProvider] in
                        guard let self else { return }
                        stateProvider?.handle(newState: .normal(itemTypes: newList),
                                              helper: self)
                        self.reloadInput.accept(.reloadSection(animated: false))
                    }
                case let .update(newList, inserts, deletes, updates, moves):
                    completion = { [weak self, weak stateProvider] in
                        guard let self,
                              let stateProvider else { return }
                        guard stateProvider.canReloadState else {
                            // canReloadState 为 false 表明 multiSection 场景且当前 section 不可见，
                            // 抛出的 updateAction 不会被调用，但需要在 updateAction 内更新数据源，所以需要判断 canReloadState 分别处理数据更新时机
                            stateProvider.handle(newState: .normal(itemTypes: newList),
                                                  helper: self)
                            return
                        }
                        let reloadAction = SpaceSectionReloadAction.update(inserts: inserts,
                                                                           deletes: deletes,
                                                                           updates: updates,
                                                                           moves: moves) {
                            stateProvider.handle(newState: .normal(itemTypes: newList),
                                                  helper: self)
                        }
                        self.reloadInput.accept(reloadAction)
                    }
                }
                DispatchQueue.main.async(execute: completion)
            }
        case .displayListAfterLoading,
             .displayListFromSpecialState:
            DispatchQueue.main.async { [weak self, weak stateProvider] in
                guard let self else { return }
                stateProvider?.handle(newState: newState,
                                      helper: self)
                self.reloadInput.accept(.reloadSection(animated: false))
                self.actionInput.accept(.stopPullToLoadMore(hasMore: true))

                if case .displayListAfterLoading = transaction {
                    stateProvider?.didShowListAfterLoading()
                }
            }
        case .changeSpecialState:
            DispatchQueue.main.async { [weak self, weak stateProvider] in
                guard let self else { return }
                stateProvider?.handle(newState: newState,
                                      helper: self)
                self.reloadInput.accept(.reloadSection(animated: false))
                self.actionInput.accept(.stopPullToLoadMore(hasMore: false))
            }
        }
    }
}
