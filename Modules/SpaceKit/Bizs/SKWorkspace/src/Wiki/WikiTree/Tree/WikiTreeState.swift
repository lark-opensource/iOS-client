//
//  WikiTreeState.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2022/8/4.
//

import Foundation
import SKFoundation

// 驱动一颗 wiki 目录树的数据结构
public struct WikiTreeState: Equatable {
    
    public let viewState: WikiTreeViewState
    public let metaStorage: WikiTreeNodeMeta.MetaStorage
    public let relation: WikiTreeRelation

    public var isEmpty: Bool {
        guard viewState.isEmpty else { return false }
        guard metaStorage.isEmpty else { return false }
        guard relation.isEmpty else { return false }
        return true
    }
    
    public var isEmptyTree: Bool {
        let metaStorageEmptyState = metaStorage.isEmpty
        let relationEmptyState = relation.isEmpty
        let childrenEmptyState = relation.nodeChildrenMap.allSatisfy { $1.isEmpty }
        DocsLogger.info("check wiki tree state is empty tree: metaStorage \(metaStorageEmptyState), relation \(relationEmptyState), children \(childrenEmptyState)")
        DocsLogger.info("check wiki tree state is empty tree count: metaStorage \(metaStorage.count), relation \(relation.nodeChildrenMap.count) \(relation.nodeParentMap.count)")
        
        return metaStorageEmptyState || relationEmptyState || childrenEmptyState
    }

    public static var empty: WikiTreeState {
        WikiTreeState(viewState: WikiTreeViewState(), metaStorage: [:], relation: WikiTreeRelation())
    }
    
    public init(viewState: WikiTreeViewState, metaStorage: WikiTreeNodeMeta.MetaStorage, relation: WikiTreeRelation) {
        self.viewState = viewState
        self.metaStorage = metaStorage
        self.relation = relation
    }
}
