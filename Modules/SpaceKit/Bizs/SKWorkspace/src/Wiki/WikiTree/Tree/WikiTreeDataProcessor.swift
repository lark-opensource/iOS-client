//
//  WikiTreeDataProcessor.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2022/7/14.
//

import Foundation
import SKFoundation
import SKCommon
import SpaceInterface

typealias WikiLocation = WikiPickerLocation

public enum WikiTreeOperation {

    public enum ConflictStrategy: Equatable {
        // 用传入的数据覆盖旧数据，如 server 数据覆盖 cache
        case override
        // 保留旧数据，忽略传入的数据，如 cache 不能覆盖 server 的新数据
        case ignore
    }

    // 从 DB 恢复时，reset 当前状态
    case reset(relation: WikiTreeRelation, metaStorage: WikiTreeNodeMeta.MetaStorage)
    /// 带 token 请求目录树后，覆盖 cache 时，需要做一次清理逻辑
    /// cache: A -> B -> C -> D -> TARGET
    /// server: A -> B -> E -> TARGET
    /// 需要清空 C、D 子节点信息，避免本地和 server 数据不一致
    case cleanDivergePath(wikiToken: String, newRelation: WikiTreeRelation)
    // 更新收藏列表数据，包括从 DB、网络拿到数据
    case updateFavoriteList(spaceID: String,
                            relation: WikiTreeRelation,
                            metaStorage: WikiTreeNodeMeta.MetaStorage,
                            onConflict: ConflictStrategy)
    // 更新置顶知识库节点列表数据
    case updateMutilTreeList(relation: WikiTreeRelation,
                             metaStorage: WikiTreeNodeMeta.MetaStorage,
                             onConflict: ConflictStrategy)
    case updatePinDocumentList(relation: WikiTreeRelation,
                               metaStorage: WikiTreeNodeMeta.MetaStorage,
                               onConflict: ConflictStrategy)
    case updateHomeTreeList(root: WikiTreeNodeMeta,
                            relation: WikiTreeRelation,
                            metaStorage: WikiTreeNodeMeta.MetaStorage,
                            onConflict: ConflictStrategy)
    // 合并数据，如合并网络请求的数据和 cache 的数据
    case update(relation: WikiTreeRelation,
                metaStorage: WikiTreeNodeMeta.MetaStorage,
                onConflict: ConflictStrategy)
    // 递归展开到特定 wikiToken，适用链接打开场景，需要定位到某个节点
    // 注意只会定位本体位置
    case expandTo(wikiToken: String)

    public enum InsertError: Error, Equatable {
        case parentNotFound
        case parentChildrenUnknown
    }
    /// 向特定节点下插入子节点
    /// 如果父节点不存在、父节点无法被索引到、或父节点是非叶子节点且 children 未知，不会处理
    case insert(parentWikiToken: String, nodes: [WikiServerNode])

    public enum DeleteError: Error, Equatable {
        case targetNotFound
        case parentNotFound
    }
    public typealias DeleteResponse = ([String]) -> Void
    case delete(wikiToken: String, response: DeleteResponse)
    case batchDelete(parentToken: String, wikiTokens: [String], response: DeleteResponse)

    case move(oldParentToken: String, newParentToken: String, nodes: [WikiServerNode])

    public enum UpdateError: Error, Equatable {
        case wikiStarRootNotFound
        case starStateUnchanged
        case targetNotFound
        case pinStateUnchanged
    }
    // wiki与space的互通操作
    enum ExplorerOperation {
        case explorerStar(addStar: Bool)
        case explorerPin(addPin: Bool)
    }
    // 操作对象本体所在的位置
    enum ExplorerOperationStage {
        case wiki
        case external
    }
    case toggleWikiStar(wikiToken: String, isStar: Bool)
    case toggleExplorerStar(wikiToken: String, isStar: Bool)
    case toggleExplorerStarForExternalShortcut(objToken: String, isStar: Bool)
    // 快速访问
    case toggleExplorerPin(wikiToken: String, isPin: Bool)
    case toggleExplorerPinForExternalShortcut(objToken: String, isPin: Bool)
}

public protocol WikiTreeDataProcessorType {
    typealias MetaStorage = WikiTreeNodeMeta.MetaStorage
    typealias NodeChildren = WikiTreeRelation.NodeChildren
    typealias ConflictStrategy = WikiTreeOperation.ConflictStrategy
    func process(operation: WikiTreeOperation, treeState: WikiTreeState) throws -> WikiTreeState
}

// 同步完成所有知识库的数据结构更新
public class WikiTreeDataProcessor: WikiTreeDataProcessorType {
    public init() {}
    
    public func process(operation: WikiTreeOperation, treeState: WikiTreeState) throws -> WikiTreeState {
        switch operation {
        case let .reset(relation, metaStorage):
            return reset(relation: relation, storage: metaStorage, treeState: treeState)
        case let .cleanDivergePath(wikiToken, newRelation):
            return cleanDivergePath(wikiToken: wikiToken, newRelation: newRelation, treeState: treeState)
        case let .update(relation, metaStorage, onConflict):
            return update(relation: relation, storage: metaStorage, onConflict: onConflict, treeState: treeState)
        case let .expandTo(wikiToken):
            return expandTo(wikiToken: wikiToken, treeState: treeState)
        case let .updateFavoriteList(spaceID, relation, metaStorage, onConflict):
            return updateFavoriteList(spaceID: spaceID,
                                      relation: relation,
                                      metaStorage: metaStorage,
                                      onConflict: onConflict,
                                      treeState: treeState)
        case let .updatePinDocumentList(relation, metaStorage, onConflict):
            return updatePinDocumentList(relation: relation, metaStorage: metaStorage, onConflict: onConflict, treeState: treeState)
        case let .updateMutilTreeList(relation, metaStorage, onConflict):
            return updateMutilTreeList(relation: relation,
                                       metaStorage: metaStorage,
                                       onConflict: onConflict,
                                       treeState: treeState)
        case let .insert(parentWikiToken, nodes):
            return try insert(parentWikiToken: parentWikiToken,
                              nodes: nodes,
                              treeState: treeState)
        case let .delete(wikiToken, response):
            return try delete(wikiToken: wikiToken, response: response, treeState: treeState)
        case let .batchDelete(parentToken, wikiTokens, response):
            return try batchDelete(parentToken: parentToken, wikiTokens: wikiTokens, response: response, treeState: treeState)
        case let .move(oldParentToken, newParentToken, nodes):
            return move(oldParentToken: oldParentToken,
                        newParentToken: newParentToken,
                        nodes: nodes,
                        treeState: treeState)
        case let .toggleWikiStar(wikiToken, isStar):
            return try toggleStar(wikiToken: wikiToken, isStar: isStar, treeState: treeState)
        case let .toggleExplorerStar(wikiToken, isStar):
            return try toggleExplorerStar(wikiToken: wikiToken, isStar: isStar, treeState: treeState)
        case let .toggleExplorerStarForExternalShortcut(objToken, isStar):
            return toggleExplorerStarForExternalShortcut(objToken: objToken, isStar: isStar, treeState: treeState)
        case let .toggleExplorerPin(wikiToken, isPin):
            return try toggleExplorerPin(wikiToken: wikiToken, isPin: isPin, treeState: treeState)
        case let .toggleExplorerPinForExternalShortcut(objToken, isPin):
            return toggleExplorerPinForExternalShortcut(objToken: objToken, isPin: isPin, treeState: treeState)
        case let .updateHomeTreeList(root, relation, metaStorage, onConflict):
            return updateHomeTreeList(root: root, relation: relation, metaStorage: metaStorage, onConflict: onConflict, treeState: treeState)
        }
    }

    func reset(relation: WikiTreeRelation, storage: MetaStorage, treeState: WikiTreeState) -> WikiTreeState {
        return WikiTreeState(viewState: treeState.viewState,
                             metaStorage: storage,
                             relation: relation)
    }

    func update(relation: WikiTreeRelation,
                storage: MetaStorage,
                onConflict: ConflictStrategy,
                treeState: WikiTreeState) -> WikiTreeState {
        var newStorage = treeState.metaStorage
        newStorage.merge(storage) {
            switch onConflict {
            case .override:
                return $1
            case .ignore:
                return $0
            }
        }
        var newRelation = treeState.relation
        // relation 合并详细策略见内部实现
        newRelation.update(newRelation: relation, onConflict: onConflict)
        return WikiTreeState(viewState: treeState.viewState,
                             metaStorage: newStorage,
                             relation: newRelation)
    }

    func expandTo(wikiToken: String, treeState: WikiTreeState) -> WikiTreeState {
        let paths = treeState.relation.getPath(wikiToken: wikiToken)
        guard let section = Self.getNodeSection(wikiToken: wikiToken, treeState: treeState) else {
            spaceAssertionFailure("rootNode not found when expanding")
            return treeState
        }
        var newViewState = treeState.viewState
        paths.forEach { token in
            // 这里假设路径上一定没有经过 shortcut
            let UID = WikiTreeNodeUID(wikiToken: token, section: section, shortcutPath: "")
            newViewState.expand(nodeUID: UID)
        }
        return WikiTreeState(viewState: newViewState,
                             metaStorage: treeState.metaStorage,
                             relation: treeState.relation)
    }

    func updateFavoriteList(spaceID: String,
                            relation: WikiTreeRelation,
                            metaStorage: MetaStorage,
                            onConflict: ConflictStrategy,
                            treeState: WikiTreeState) -> WikiTreeState {
        let favoriteRoot = WikiTreeNodeMeta.createFavoriteRoot(spaceID: spaceID)
        // 合并 meta
        var newMetaStorage = treeState.metaStorage
        newMetaStorage.merge(metaStorage) {
            switch onConflict {
            case .override:
                return $1
            case .ignore:
                return $0
            }
        }
        newMetaStorage[favoriteRoot.wikiToken] = favoriteRoot
        // 更新收藏 root 的 children
        var newRelation = treeState.relation
        newRelation.update(newRelation: relation, onConflict: onConflict)
        return WikiTreeState(viewState: treeState.viewState,
                             metaStorage: newMetaStorage,
                             relation: newRelation)
    }
    
    func updateMutilTreeList(relation: WikiTreeRelation,
                             metaStorage: MetaStorage,
                             onConflict: ConflictStrategy,
                             treeState: WikiTreeState) -> WikiTreeState {
        // 空数据时隐藏这一part
        if relation.isEmpty, metaStorage.isEmpty {
            return .empty
        }
        let mutilTreeRoot = WikiTreeNodeMeta.createMutilTreeRoot()
        var newMetaStorage = treeState.metaStorage
        newMetaStorage.merge(metaStorage) {
            switch onConflict {
            case .override:
                return $1
            case .ignore:
                return $0
            }
        }
        
        newMetaStorage[mutilTreeRoot.wikiToken] = mutilTreeRoot
        var newRelation = treeState.relation
        newRelation.update(newRelation: relation, onConflict: onConflict)
        return WikiTreeState(viewState: treeState.viewState,
                             metaStorage: newMetaStorage,
                             relation: newRelation)
    }
    
    func updatePinDocumentList(relation: WikiTreeRelation,
                               metaStorage: MetaStorage,
                               onConflict: ConflictStrategy,
                               treeState: WikiTreeState) -> WikiTreeState {
        // 空数据时隐藏这一part
        if relation.isEmpty, metaStorage.isEmpty {
            return .empty
        }
        let documentRoot = WikiTreeNodeMeta.createDocumentRoot()
        var newMetaStorage = treeState.metaStorage
        newMetaStorage.merge(metaStorage) {
            switch onConflict {
            case .override:
                return $1
            case .ignore:
                return $0
            }
        }
        
        newMetaStorage[documentRoot.wikiToken] = documentRoot
        var newRelation = treeState.relation
        newRelation.update(newRelation: relation, onConflict: onConflict)
        return WikiTreeState(viewState: treeState.viewState,
                             metaStorage: newMetaStorage,
                             relation: newRelation)
    }
    
    func updateHomeTreeList(root: WikiTreeNodeMeta,
                            relation: WikiTreeRelation,
                            metaStorage: MetaStorage,
                            onConflict: ConflictStrategy,
                            treeState: WikiTreeState) -> WikiTreeState {
        // 空数据时隐藏这一part
        if relation.isEmpty, metaStorage.isEmpty {
            return .empty
        }
        var newMetaStorage = treeState.metaStorage
        newMetaStorage.merge(metaStorage) {
            switch onConflict {
            case .override:
                return $1
            case .ignore:
                return $0
            }
        }
        
        newMetaStorage[root.wikiToken] = root
        var newRelation = treeState.relation
        newRelation.update(newRelation: relation, onConflict: onConflict)
        return WikiTreeState(viewState: treeState.viewState,
                             metaStorage: newMetaStorage,
                             relation: newRelation)
        
    }

    func cleanDivergePath(wikiToken: String, newRelation: WikiTreeRelation, treeState: WikiTreeState) -> WikiTreeState {
        let newPaths = newRelation.getPath(wikiToken: wikiToken)
        let oldPaths = treeState.relation.getPath(wikiToken: wikiToken)
        let maxIndex = min(newPaths.count, oldPaths.count)
        var index = 0
        while index < maxIndex {
            guard newPaths[index] == oldPaths[index] else {
                break
            }
            index += 1
        }
        if index >= oldPaths.count {
            // oldPaths 包含在 newPaths，没有 diverge
            return treeState
        }
        var childrenMap = treeState.relation.nodeChildrenMap
        var parentMap = treeState.relation.nodeParentMap
        var viewState = treeState.viewState
        for subIndex in index..<oldPaths.count {
            // 清理 diverge 节点的 children，以便后续可以正常触发网络请求
            let parentToken = oldPaths[subIndex]
            if let children = childrenMap[parentToken] {
                // 对 parent 的引用也要清掉
                children.forEach { parentMap[$0.wikiToken] = nil }
            }
            childrenMap[parentToken] = nil
            // 将 diverge 节点标记为隐藏
            let nodeUID = WikiTreeNodeUID(wikiToken: parentToken, section: .mainRoot, shortcutPath: "")
            viewState.collapse(nodeUID: nodeUID)
        }
        return WikiTreeState(viewState: viewState,
                             metaStorage: treeState.metaStorage,
                             relation: WikiTreeRelation(nodeParentMap: parentMap,
                                                        nodeChildrenMap: childrenMap))
    }

    func insert(parentWikiToken: String, nodes: [WikiServerNode], treeState: WikiTreeState) throws -> WikiTreeState {
        typealias InsertError = WikiTreeOperation.InsertError
        guard var parentMeta = treeState.metaStorage[parentWikiToken] else {
            // parent meta 不存在，不处理
            DocsLogger.info("parent meta not found when insert sub nodes")
            throw InsertError.parentNotFound
        }

        var newMetaStorage = treeState.metaStorage
        var newRelation = treeState.relation

        if !parentMeta.hasChild {
            // 如果往叶子节点插入数据，需要更新下 parentMeta 的信息
            parentMeta.hasChild = true
            newMetaStorage[parentWikiToken] = parentMeta
            newRelation.setup(rootToken: parentWikiToken)
        } else if treeState.relation.nodeChildrenMap[parentWikiToken] == nil {
            // parent 的 children 未知，应该优先拉数据，而不是直接插入
            DocsLogger.info("parent meta children is unknown, insert abort")
            throw InsertError.parentChildrenUnknown
        }

        nodes.forEach { node in
            guard node.parent == parentWikiToken else {
                spaceAssertionFailure("batch insert found node in different parent")
                return
            }
            newRelation.insert(wikiToken: node.meta.wikiToken,
                               sortID: node.sortID,
                               parentToken: parentWikiToken)
            newMetaStorage[node.meta.wikiToken] = node.meta
        }
        return WikiTreeState(viewState: treeState.viewState,
                             metaStorage: newMetaStorage,
                             relation: newRelation)
    }

    func delete(wikiToken: String,
                response: WikiTreeOperation.DeleteResponse,
                treeState: WikiTreeState) throws -> WikiTreeState {
        typealias DeleteError = WikiTreeOperation.DeleteError
        guard let parentToken = treeState.relation.nodeParentMap[wikiToken] else {
            throw DeleteError.parentNotFound
        }
        return try batchDelete(parentToken: parentToken,
                               wikiTokens: [wikiToken],
                               response: response, treeState: treeState)
    }

    func batchDelete(parentToken: String,
                     wikiTokens: [String],
                     response: WikiTreeOperation.DeleteResponse,
                     treeState: WikiTreeState) throws -> WikiTreeState {
        typealias DeleteError = WikiTreeOperation.DeleteError
        let targetMetas = wikiTokens.compactMap { treeState.metaStorage[$0] }
        if targetMetas.isEmpty {
            // 被删除的节点全不存在，不处理
            throw DeleteError.targetNotFound
        }
        var newRelation = treeState.relation
        var newMetaStorage = treeState.metaStorage
        var allDeletedTokens: [String] = []
        targetMetas.forEach { meta in
            let deletedTokens = newRelation.deleteSubTree(rootToken: meta.wikiToken)
            allDeletedTokens.append(contentsOf: deletedTokens)
            // 还需要从收藏列表 / 置顶 - 云文档 里删除（PS：Wiki节点在这两种虚拟树的列表下parent非虚拟节点parent, 是真实parent）
            deletedTokens.forEach { token in
                newRelation.delete(wikiToken: token, parentToken: WikiTreeNodeMeta.favoriteRootToken)
                newRelation.delete(wikiToken: token, parentToken: WikiTreeNodeMeta.clipDocumentRootToken)
            }
        }
        // 从 meta 中删除
        allDeletedTokens.forEach { token in
            newMetaStorage[token] = nil
        }
        if let parentChildren = newRelation.nodeChildrenMap[parentToken],
           parentChildren.isEmpty,
           var parentMeta = newMetaStorage[parentToken] {
            // 如果 parent 在删除后没有子节点，需要更新状态
            parentMeta.hasChild = false
            newMetaStorage[parentToken] = parentMeta
        }
        response(allDeletedTokens)
        return WikiTreeState(viewState: treeState.viewState,
                             metaStorage: newMetaStorage,
                             relation: newRelation)
    }

    // 这里假定所有 nodes 的 parent 都相同
    func move(oldParentToken: String,
              newParentToken: String,
              nodes: [WikiServerNode],
              treeState: WikiTreeState) -> WikiTreeState {
        var newRelation = treeState.relation
        var newMetaStorage = treeState.metaStorage
        // 更新一下 newParent 的状态
        if var newParentMeta = newMetaStorage[newParentToken],
           !newParentMeta.hasChild {
            newParentMeta.hasChild = true
            newMetaStorage[newParentToken] = newParentMeta
            newRelation.setup(rootToken: newParentToken)
        }
        nodes.forEach { node in
            newRelation.insert(wikiToken: node.meta.wikiToken,
                               sortID: node.sortID,
                               parentToken: newParentToken)
            // 这里覆盖一下，原因是 spaceID 可能会变
            newMetaStorage[node.meta.wikiToken] = node.meta
        }
        // 更新一下 oldParent 的状态
        if let oldParentChildren = newRelation.nodeChildrenMap[oldParentToken],
           oldParentChildren.isEmpty,
           var oldParentMeta = newMetaStorage[oldParentToken] {
            oldParentMeta.hasChild = false
            newMetaStorage[oldParentToken] = oldParentMeta
        }
        return WikiTreeState(viewState: treeState.viewState,
                             metaStorage: newMetaStorage,
                             relation: newRelation)
    }

    func toggleStar(wikiToken: String, isStar: Bool, treeState: WikiTreeState) throws -> WikiTreeState {
        typealias UpdateError = WikiTreeOperation.UpdateError
        var newRelation = treeState.relation
        var newViewState = treeState.viewState
        guard treeState.metaStorage[WikiTreeNodeMeta.favoriteRootToken] != nil,
              let starChildren = newRelation.nodeChildrenMap[WikiTreeNodeMeta.favoriteRootToken] else {
            DocsLogger.error("toggle star failed, star root info not found")
            throw UpdateError.wikiStarRootNotFound
        }
        
        let currentIsStar = starChildren.contains { $0.wikiToken == wikiToken }
        if currentIsStar == isStar {
            DocsLogger.error("toggle star failed, star state un-changed")
            throw UpdateError.starStateUnchanged
        }
        if isStar {
            if starChildren.count == 0 {
                // 我的置顶 从无到有时固定展开
                let favNodeUID = WikiTreeNodeUID(wikiToken: WikiTreeNodeMeta.favoriteRootToken,
                                                 section: .favoriteRoot,
                                                 shortcutPath: "")
                newViewState.expand(nodeUID: favNodeUID)
            }
            let minSortID = starChildren.first?.sortID ?? 0
            newRelation.forceInsert(wikiToken: wikiToken, sortID: minSortID - 10, parentToken: WikiTreeNodeMeta.favoriteRootToken)
        } else {
            newRelation.delete(wikiToken: wikiToken, parentToken: WikiTreeNodeMeta.favoriteRootToken)
        }
        return WikiTreeState(viewState: newViewState,
                             metaStorage: treeState.metaStorage,
                             relation: newRelation)
    }

    func toggleExplorerStar(wikiToken: String, isStar: Bool, treeState: WikiTreeState) throws -> WikiTreeState {
        typealias UpdateError = WikiTreeOperation.UpdateError
        var newMetas = treeState.metaStorage
        guard var targetMeta = newMetas[wikiToken] else {
            DocsLogger.error("toggle explorer star failed, star root info not found")
            throw UpdateError.targetNotFound
        }
        if targetMeta.isExplorerStar == isStar {
            DocsLogger.error("toggle explorer star failed, star state un-changed")
            throw UpdateError.starStateUnchanged
        }
        targetMeta.isExplorerStar = isStar
        newMetas[wikiToken] = targetMeta
        // 收藏后同步同库的shortcut收藏状态
        newMetas = updateRelatedMetaState(targetToken: wikiToken, operation: .explorerStar(addStar: isStar), operationStage: .wiki, metas: newMetas)
        
        return WikiTreeState(viewState: treeState.viewState,
                             metaStorage: newMetas,
                             relation: treeState.relation)
    }
    
    // 本体在外部的 wiki shortcut 有特别的流程同步收藏状态
    func toggleExplorerStarForExternalShortcut(objToken: String, isStar: Bool, treeState: WikiTreeState) -> WikiTreeState {
        let newMetas = updateRelatedMetaState(targetToken: objToken, operation: .explorerStar(addStar: isStar), operationStage: .external, metas: treeState.metaStorage)
        return WikiTreeState(viewState: treeState.viewState,
                             metaStorage: newMetas,
                             relation: treeState.relation)
    }
    
    func toggleExplorerPin(wikiToken: String, isPin: Bool, treeState: WikiTreeState) throws -> WikiTreeState {
        typealias UpdateError = WikiTreeOperation.UpdateError
        var newMetas = treeState.metaStorage
        guard var targetMeta = newMetas[wikiToken] else {
            DocsLogger.error("toggle explorer pin failed, pin node info not found")
            throw UpdateError.targetNotFound
        }
        if targetMeta.isExplorerPin == isPin {
            DocsLogger.error("toggle explorer pin failed, target node pin state un-change")
            throw UpdateError.pinStateUnchanged
        }
        targetMeta.isExplorerPin = isPin
        newMetas[wikiToken] = targetMeta
        //添加快速访问后同步所有相关节点的状态
        newMetas = updateRelatedMetaState(targetToken: wikiToken, operation: .explorerPin(addPin: isPin), operationStage: .wiki, metas: newMetas)
        
        return WikiTreeState(viewState: treeState.viewState, metaStorage: newMetas, relation: treeState.relation)
    }
    
    // 本体在外部的 wiki shortcut 特有的流程同步快速访问状态
    func toggleExplorerPinForExternalShortcut(objToken: String, isPin: Bool, treeState: WikiTreeState) -> WikiTreeState {
        let newMetas = updateRelatedMetaState(targetToken: objToken, operation: .explorerPin(addPin: isPin), operationStage: .external, metas: treeState.metaStorage)
        return WikiTreeState(viewState: treeState.viewState,
                             metaStorage: newMetas,
                             relation: treeState.relation)
    }
    
    private func updateRelatedMetaState(targetToken: String,
                                        operation: WikiTreeOperation.ExplorerOperation,
                                        operationStage: WikiTreeOperation.ExplorerOperationStage,
                                        metas: WikiTreeNodeMeta.MetaStorage) -> WikiTreeNodeMeta.MetaStorage {
        var newMetas = metas
        var updateMetas = [WikiTreeNodeMeta]()
        // 根据操作对象的本体在wiki或space，找到对应所有在wiki的shortcut
        switch operationStage {
        case .wiki:
            newMetas.forEach { (_, meta) in
                if meta.isShortcut, meta.originWikiToken == targetToken {
                    updateMetas.append(meta)
                }
            }
        case .external:
            newMetas.forEach { (_, meta) in
                if meta.originIsExternal, meta.objToken == targetToken {
                    updateMetas.append(meta)
                }
            }
        }
        // 更改所有shortcut的对应状态，写入metaStorage
        for var meta in updateMetas {
            switch operation {
            case let .explorerStar(addStar):
                meta.isExplorerStar = addStar
            case let .explorerPin(addPin):
                meta.isExplorerPin = addPin
            }
            newMetas[meta.wikiToken] = meta
        }
        return newMetas
    }
}

// 拓展几个通用的静态方法
extension WikiTreeDataProcessor {

    public static func getNodeSection(wikiToken: String, treeState: WikiTreeState) -> TreeNodeRootSection? {
        let paths = treeState.relation.getPath(wikiToken: wikiToken)
        guard let rootToken = paths.first,
           let rootNode = treeState.metaStorage[rootToken] else {
            //取不到root node，无法判断当前section
            return nil
        }
        switch rootNode.nodeType {
        case .normal, .shortcut, .sharedRoot:
            return .sharedRoot
        case .mainRoot:
            return .mainRoot
        case.multiTreeRoot:
            return .mutilTreeRoot
        case .clipDocumentListRoot:
            return .documentRoot
        case .homeSharedRoot:
            return .homeSharedRoot
        case .starRoot:
            // favorite path 是虚拟路径，实际上应该走不到这里
            spaceAssertionFailure("root section should not be fav root")
            return .favoriteRoot
        }
    }
}
