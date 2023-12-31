//
//  HomeSharedDataModel.swift
//  SKWorkspace
//
//  Created by majie.7 on 2023/6/27.
//

import Foundation
import SKCommon
import RxSwift
import RxCocoa
import SKFoundation


public class HomeSharedDataModel: WikiTreeDataModel {
    private let sharedTreeSpaceId = WikiTreeNodeMeta.homeSharedSpaceID

    public init(networkAPI: WikiTreeNetworkAPI,
                cacheAPI: WikiTreeCacheAPI,
                processor: WikiTreeDataProcessor) {
        super.init(spaceID: sharedTreeSpaceId,
                   initialWikiToken: nil,
                   treeContext: nil,
                   networkAPI: networkAPI,
                   cacheAPI: cacheAPI,
                   processor: processor,
                   config: .homeSharedConfig)
    }
    
    public convenience init() {
        let networkAPI = WikiNetworkManager.shared
        let cacheAPI = WikiTreeCacheHandle.shared
        let processor = WikiTreeDataProcessor()
        self.init(networkAPI: networkAPI, cacheAPI: cacheAPI, processor: processor)
    }
    
    public override func reload() -> Single<(WikiTreeState, Bool)> {
        networkAPI.loadShareList()
            .observeOn(dataQueueScheduler)
            .do(onSuccess: { [weak self] (relation, metas) in
                guard let self else { return }
                var metaMap: MetaStorage = [:]
                metas.forEach { metaMap[$0.wikiToken] = $0 }
                do {
                    self.treeState = try self.processor.process(operation: .updateHomeTreeList(root: WikiTreeNodeMeta.createHomeSharedRoot(),
                                                                                               relation: relation,
                                                                                               metaStorage: metaMap,
                                                                                               onConflict: .override),
                                                                treeState: self.treeState)
                    if !self.treeState.isEmptyTree {
                        // 有数据时固定展开虚拟-分享树根节点
                        let rooToken = WikiTreeNodeMeta.homeSharedRootToken
                        let nodeUid = WikiTreeNodeUID(wikiToken: rooToken, section: .homeSharedRoot, shortcutPath: "")
                        self.viewState.expand(nodeUID: nodeUid)
                    }
                    self.cacheAPI.updateHomeSharedList(metaStorage: metaMap, relation: relation).subscribe().disposed(by: self.disposeBag)
                } catch {
                    DocsLogger.error("unkown update error", error: error)
                    spaceAssertionFailure()
                }
            }, onError: { error in
                DocsLogger.error("reload home shared tree list failed", error: error)
            })
            .map { [weak self] _ in
                guard let self else {
                    throw DataError.modelReferenceError
                }
                let cacheLoaded: Bool
                if let cacheState = self.initialStateRelay.value.cacheState,
                   case .success = cacheState {
                    cacheLoaded = true
                } else {
                    cacheLoaded = false
                }
                return (self.treeState, cacheLoaded)
            }
    }
    
    public override func restore() -> Maybe<WikiTreeState> {
        cacheAPI.loadHomeSharedList()
            .observeOn(dataQueueScheduler)
            .do(onNext: { [weak self] (children, metaStorage) in
                guard let self else { return }
                let relation = WikiTreeRelation(nodeParentMap: [:], nodeChildrenMap: [
                    WikiTreeNodeMeta.homeSharedRootToken: children
                ])
                do {
                    let newState = try self.processor.process(operation: .updateHomeTreeList(root: WikiTreeNodeMeta.createHomeSharedRoot(),
                                                                                             relation: relation,
                                                                                             metaStorage: metaStorage,
                                                                                             onConflict: .ignore),
                                                              treeState: self.treeState)
                    self.treeState = newState
                    let nodeUid = WikiTreeNodeUID(wikiToken: WikiTreeNodeMeta.homeSharedRootToken, section: .homeSharedRoot, shortcutPath: "")
                    if !self.treeState.isEmptyTree {
                        // 有数据时固定展开虚拟-云文档节点
                        self.viewState.expand(nodeUID: nodeUid)
                    } else {
                        self.viewState.collapse(nodeUID: nodeUid)
                    }
                } catch {
                    DocsLogger.error("un-handle update error", error: error)
                    spaceAssertionFailure()
                }
            }, onError: { error in
                DocsLogger.error("restore home shared tree list failed", error: error)
            })
                .map { [weak self] _ -> WikiTreeState in
                    guard let self else {
                        throw DataError.modelReferenceError
                    }
                    return self.treeState
                }
    }
}
