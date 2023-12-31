//
//  Model.swift
//  SKWorkspace
//
//  Created by majie.7 on 2023/5/16.
//

import Foundation
import RxSwift
import RxCocoa
import SKCommon
import SKFoundation



public class WikiMutilTreeDataModel: WikiTreeDataModel {
    // 维护的WikiMutilTree从实际数据角度来说是一颗虚拟树，不需要实际的spaceId，维护一个spaceID兼容复用TreeDataModel
    private let mutilTreeSpaceId = WikiTreeNodeMeta.mutilTreeSpaceID
    
    private var treeSpaceIdsRelay = BehaviorRelay<[String]>(value: [])
    override public var treeSpaceIds: [String] {
        treeSpaceIdsRelay.value
    }
    
    public init(networkAPI: WikiTreeNetworkAPI,
                cacheAPI: WikiTreeCacheAPI,
                processor: WikiTreeDataProcessor) {
        super.init(spaceID: mutilTreeSpaceId,
                   initialWikiToken: nil,
                   treeContext: nil,
                   networkAPI: networkAPI,
                   cacheAPI: cacheAPI,
                   processor: processor,
                   config: .init(ignoreCrossMoveSync: true))
    }
    
    public convenience init() {
        let networkAPI = WikiNetworkManager.shared
        let cacheAPI = WikiTreeCacheHandle.shared
        let processor = WikiTreeDataProcessor()
        self.init(networkAPI: networkAPI, cacheAPI: cacheAPI, processor: processor)
    }
    
    public override func restore() -> Maybe<WikiTreeState> {
        cacheAPI.loadWikiSpaceTree()
            .observeOn(dataQueueScheduler)
            .do(onNext: { [weak self] (relation, metaStorage) in
                guard let self else { return }
                do {
                    let newState = try self.processor.process(operation: .updateMutilTreeList(relation: relation,
                                                                                              metaStorage: metaStorage,
                                                                                              onConflict: .ignore),
                                                              treeState: self.treeState)
                    self.treeState = newState
                    if !self.treeState.isEmptyTree {
                        // 有数据时固定展开虚拟-云空间节点
                        let mutilRootToken = WikiTreeNodeMeta.mutilTreeRootToken
                        let nodeUid = WikiTreeNodeUID(wikiToken: mutilRootToken, section: .mutilTreeRoot, shortcutPath: "")
                        self.viewState.expand(nodeUID: nodeUid)
                    }
                    
                    var modelState = self.initialStateRelay.value
                    modelState.cacheState = .success(())
                    self.initialStateRelay.accept(modelState)
                } catch {
                    DocsLogger.error("un-handle update wiki space tree error", error: error)
                    spaceAssertionFailure()
                }
            }, onError: { error in
                DocsLogger.error("restore favorite wiki space tree list failed", error: error)
                var modelState = self.initialStateRelay.value
                modelState.cacheState = .failure(error)
                self.initialStateRelay.accept(modelState)
            })
            .map { [weak self] _ in
                guard let self else {
                    throw DataError.modelReferenceError
                }
                return self.treeState
            }
    }
    
    public override func reload() -> Single<(WikiTreeState, Bool)> {
        networkAPI.getStarWikiSpaceTreeList()
            .observeOn(dataQueueScheduler)
            .do(onSuccess: { [weak self] (relation, metas) in
                guard let self else { return }
                var metaMap: MetaStorage = [:]
                metas.forEach { metaMap[$0.wikiToken] = $0 }
                // 维护当前虚拟置顶树上所有知识库的spaceId
                let treeSpaceIds: [String] = metas.map { $0.spaceID }
                self.treeSpaceIdsRelay.accept(treeSpaceIds)
                do {
                    self.treeState = try self.processor.process(operation: .updateMutilTreeList(relation: relation,
                                                                                                metaStorage: metaMap,
                                                                                                onConflict: .override),
                                                                treeState: self.treeState)
                    let mutilRootToken = WikiTreeNodeMeta.mutilTreeRootToken
                    let nodeUid = WikiTreeNodeUID(wikiToken: mutilRootToken, section: .mutilTreeRoot, shortcutPath: "")
                    if !self.treeState.isEmptyTree {
                        // 有数据时固定展开虚拟-知识库根节点
                        self.viewState.expand(nodeUID: nodeUid)
                    } else {
                        self.viewState.collapse(nodeUID: nodeUid)
                    }
                    
                    var modelState = self.initialStateRelay.value
                    modelState.serverState = .success(())
                    self.initialStateRelay.accept(modelState)
                } catch {
                    DocsLogger.error("unkown update error", error: error)
                    spaceAssertionFailure()
                }
            }, onError: { error in
                DocsLogger.error("reload favorite wiki space tree list failed", error: error)
                var modelState = self.initialStateRelay.value
                modelState.serverState = .failure(error)
                self.initialStateRelay.accept(modelState)
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
}
