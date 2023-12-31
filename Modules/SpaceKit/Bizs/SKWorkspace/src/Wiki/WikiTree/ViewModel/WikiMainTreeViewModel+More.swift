//
//  WikiMainTreeViewModel+More.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2022/8/8.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa
import SKFoundation
import SKResource
import SKCommon
import SKInfra
import SpaceInterface

extension WikiMainTreeViewModel {
    func setupMoreProvider() {
        // 转发 moreProvider 事件
        moreProvider.actionSignal
            .emit(to: actionInput)
            .disposed(by: disposeBag)

        moreProvider.moreActionSignal
            .emit(onNext: { [weak self] moreAction in
                self?.moreActionSyncDispatcher.handleMoreAction(action: moreAction)
            })
            .disposed(by: disposeBag)

        onSwipeCellInput
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _, node in
                guard let self = self else { return }
                guard let meta = self.treeStateRelay.value.metaStorage[node.id] else {
                    DocsLogger.error("meta not found when swipe cell?")
                    return
                }
                self.moreProvider.preloadPermission(meta: meta)
            })
            .disposed(by: disposeBag)

        // 暂时没有好的方法在 MoreProvider 中拿到一个节点的 parent token，这里传个闭包进去
        moreProvider.parentProvider = { [weak self] childToken in
            guard let self = self else { return nil }
            let state = self.treeStateRelay.value
            return state.relation.nodeParentMap[childToken]
        }

        moreProvider.childCountProvider = { [weak self] targetToken in
            guard let self = self else { return nil }
            let state = self.treeStateRelay.value
            return state.relation.nodeChildrenMap[targetToken]?.count
        }

        // TODO: 这里可能会有性能问题
        moreProvider.clipChecker = { [weak self] targetToken in
            guard let self = self else { return false }
            let relation = self.treeStateRelay.value.relation
            guard let clipChildren = relation.nodeChildrenMap[WikiTreeNodeMeta.favoriteRootToken] else {
                return false
            }
            return clipChildren.contains { $0.wikiToken == targetToken }
        }
    }
}

extension WikiMainTreeViewModel: TreeSyncModelType {
    public var syncDataModel: WikiMainTreeDataModelType {
        self.dataModel
    }
    
    public var wikiActionInput: PublishRelay<WikiTreeViewAction> {
        self.actionInput
    }
}
