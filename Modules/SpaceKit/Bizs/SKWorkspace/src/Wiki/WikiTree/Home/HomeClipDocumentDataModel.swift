//
//  HomePinDocumentDataModel.swift
//  SKWorkspace
//
//  Created by majie.7 on 2023/5/22.
//

import Foundation
import SKFoundation
import SKCommon
import RxSwift
import RxCocoa


public class HomeClipDocumentDataModel: WikiTreeDataModel {
    // 维护的ClipDocumentTree从实际数据角度来说是一颗虚拟树，不需要实际的spaceId，维护一个spaceID兼容复用TreeDataModel
    private let mutilTreeSpaceId = WikiTreeNodeMeta.clipDocumentSpaceID
    
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
    
    public override func reload() -> Single<(WikiTreeState, Bool)> {
        networkAPI.loadPinDocumentList()
            .observeOn(dataQueueScheduler)
            .do(onSuccess: { [weak self] (relation, metas) in
                guard let self else { return }
                var metaMap: MetaStorage = [:]
                metas.forEach { metaMap[$0.wikiToken] = $0 }
                do {
                    self.treeState = try self.processor.process(operation: .updatePinDocumentList(relation: relation,
                                                                                                  metaStorage: metaMap,
                                                                                                  onConflict: .override),
                                                                treeState: self.treeState)
                    if !self.treeState.isEmptyTree {
                        // 有数据时固定展开虚拟-云文档节点
                        let documentRootToken = WikiTreeNodeMeta.clipDocumentRootToken
                        let nodeUid = WikiTreeNodeUID(wikiToken: documentRootToken, section: .documentRoot, shortcutPath: "")
                        self.viewState.expand(nodeUID: nodeUid)
                    }
                    self.cacheAPI.updateClipDocumentList(metaStorage: metaMap, relation: relation).subscribe().disposed(by: self.disposeBag)
                    
                    var modelState = self.initialStateRelay.value
                    modelState.serverState = .success(())
                    self.initialStateRelay.accept(modelState)
                } catch {
                    DocsLogger.error("unkown update error", error: error)
                    spaceAssertionFailure()
                }
            }, onError: { error in
                DocsLogger.error("reload pin document tree list failed", error: error)
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
    
    public override func restore() -> Maybe<WikiTreeState> {
        cacheAPI.loadDocumentList()
            .observeOn(dataQueueScheduler)
            .do(onNext: { [weak self] (children, metaStorage) in
                guard let self else { return }
                let relation = WikiTreeRelation(nodeParentMap: [:], nodeChildrenMap: [
                    WikiTreeNodeMeta.clipDocumentRootToken: children
                ])
                do {
                    let newState = try self.processor.process(operation: .updatePinDocumentList(relation: relation,
                                                                                                metaStorage: metaStorage,
                                                                                                onConflict: .ignore),
                                                              treeState: self.treeState)
                    self.treeState = newState
                    let nodeUid = WikiTreeNodeUID(wikiToken: WikiTreeNodeMeta.clipDocumentRootToken, section: .documentRoot, shortcutPath: "")
                    if !self.treeState.isEmptyTree {
                        // 有数据时固定展开虚拟-云文档节点
                        self.viewState.expand(nodeUID: nodeUid)
                    } else {
                        self.viewState.collapse(nodeUID: nodeUid)
                    }
                    
                    var modelState = self.initialStateRelay.value
                    modelState.cacheState = .success(())
                    self.initialStateRelay.accept(modelState)
                } catch {
                    DocsLogger.error("un-handle update error", error: error)
                    spaceAssertionFailure()
                }
            }, onError: { error in
                DocsLogger.error("restore document list failed", error: error)
                var modelState = self.initialStateRelay.value
                modelState.cacheState = .failure(error)
                self.initialStateRelay.accept(modelState)
            })
                .map { [weak self] _ -> WikiTreeState in
                    guard let self else {
                        throw DataError.modelReferenceError
                    }
                    return self.treeState
                }
    }
}
