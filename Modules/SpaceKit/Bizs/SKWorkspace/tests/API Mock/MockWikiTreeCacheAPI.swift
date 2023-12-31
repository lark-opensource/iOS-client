//
//  MockWikiTreeCacheAPI.swift
//  SKWikiV2_Tests-Unit-_Tests
//
//  Created by Weston Wu on 2022/8/10.
//

import Foundation
@testable import SKWorkspace
import RxSwift

// 以下的几个方法子类可以按需重写
enum MockTreeCacheError: Error {
    case mockNotImplement
}

class MockWikiTreeCacheAPI: WikiTreeCacheAPI {
    
    func loadSpaceInfo(spaceID: String) -> Maybe<WikiSpace> {
        .error(MockTreeCacheError.mockNotImplement)
    }

    func loadTree(spaceID: String, initialWikiToken: String?) -> Maybe<(WikiTreeRelation, MetaStorage)> {
        .error(MockTreeCacheError.mockNotImplement)
    }

    func loadFavoriteList(spaceID: String) -> Maybe<([NodeChildren], MetaStorage)> {
        .error(MockTreeCacheError.mockNotImplement)
    }

    func loadChildren(spaceID: String, wikiToken: String) -> Maybe<([NodeChildren], MetaStorage)> {
       .error(MockTreeCacheError.mockNotImplement)
    }

    func updateFavoriteList(spaceID: String, metaStorage: [String: WikiTreeNodeMeta], relation: WikiTreeRelation) -> Completable {
        .error(MockTreeCacheError.mockNotImplement)
    }

    func batchUpdate(metas: [WikiTreeNodeMeta], relation: WikiTreeRelation) -> Completable {
        .error(MockTreeCacheError.mockNotImplement)
    }

    func batchUpdate(nodes: [WikiServerNode], relation: WikiTreeRelation) -> Completable {
        .error(MockTreeCacheError.mockNotImplement)
    }

    func update(node: WikiServerNode, children: [String]?) -> Completable {
        .error(MockTreeCacheError.mockNotImplement)
    }

    func delete(wikiTokens: [String]) -> Completable {
        .error(MockTreeCacheError.mockNotImplement)
    }
    func updateSpaceInfoIfNeed(spaceInfo: WikiSpace?) -> RxSwift.Completable {
        .error(MockTreeCacheError.mockNotImplement)
    }
    
    func loadWikiSpaceTree() -> RxSwift.Maybe<(SKWorkspace.WikiTreeRelation, MetaStorage)> {
        .error(MockTreeCacheError.mockNotImplement)
    }
    
    func loadDocumentList() -> RxSwift.Maybe<([NodeChildren], MetaStorage)> {
        .error(MockTreeCacheError.mockNotImplement)
    }
    
    func updateClipDocumentList(metaStorage: [String : SKWorkspace.WikiTreeNodeMeta], relation: SKWorkspace.WikiTreeRelation) -> RxSwift.Completable {
        .error(MockTreeCacheError.mockNotImplement)
    }
    
    func nodeHadChildren(meta: SKWorkspace.WikiTreeNodeMeta) -> Bool {
        false
    }
}
