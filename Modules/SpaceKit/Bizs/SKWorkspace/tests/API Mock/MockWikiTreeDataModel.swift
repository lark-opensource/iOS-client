//
//  MockWikiTreeDataModel.swift
//  SKWikiV2_Tests-Unit-_Tests
//
//  Created by Weston Wu on 2022/8/15.
//

import Foundation
@testable import SKWorkspace
import RxSwift
import RxCocoa
import SKCommon
import SpaceInterface

class MockWikiTreeDataModel: WikiTreeDataModelType {
    
    typealias Util = WikiTreeTestUtil

    enum MockError: Error {
        case mockNotImplement
    }

    // MARK: - Space 基本信息
    var initialWikiToken: String?
    var treeSpaceIds: [String] = [Util.mockSpaceID]
    var spaceID: String = Util.mockSpaceID
    var spaceIDUpdated: Driver<String> { .just(spaceID) }

    var spaceInfoUpdated: Driver<WikiSpace?> { .just(nil) }
    var userSpacePermissionUpdated: Driver<WikiUserSpacePermission> { .just(.default) }

    var initialState = InitialState(cacheState: nil, serverState: nil)
    var initialStateUpdated: Driver<InitialState> { .just(initialState) }

    var treeState: WikiTreeState = .empty

    func restore() -> Maybe<WikiTreeState> {
        .error(MockError.mockNotImplement)
    }

    func restoreFavoriteList() -> Maybe<WikiTreeState> {
        .error(MockError.mockNotImplement)
    }

    func makeFavoriteRoot() -> Single<WikiTreeState> {
        .error(MockError.mockNotImplement)
    }
    // 额外 flag 表明 cacheLoaded
    func reload() -> Single<(WikiTreeState, Bool)> {
        .error(MockError.mockNotImplement)
    }

    func reloadFavoriteList() -> Single<WikiTreeState> {
        .error(MockError.mockNotImplement)
    }

    func reset(context: WikiTreeContext) -> Single<WikiTreeState> {
        .error(MockError.mockNotImplement)
    }

    func select(wikiToken: String) -> Single<WikiTreeState> {
        .error(MockError.mockNotImplement)
    }
    // 额外 flag 表明 isFromCache
    func expand(wikiToken: String, spaceID: String, nodeUID: WikiTreeNodeUID) -> Observable<(WikiTreeState, Bool)> {
        .error(MockError.mockNotImplement)
    }

    func expand(nodeUID: WikiTreeNodeUID) -> Single<WikiTreeState> {
        .error(MockError.mockNotImplement)
    }

    func collapse(nodeUID: WikiTreeNodeUID) -> Single<WikiTreeState> {
        .error(MockError.mockNotImplement)
    }

    func focus(wikiToken: String) -> Single<WikiTreeState> {
        .error(MockError.mockNotImplement)
    }
}

extension MockWikiTreeDataModel: WikiTreeSyncDataModelType {
    func syncAdd(node: WikiServerNode, originNode: WikiServerNode?) -> Maybe<WikiTreeState> {
        .error(MockError.mockNotImplement)
    }

    func syncBatchAdd(parentWikiToken: String, nodes: [WikiServerNode], originNode: WikiServerNode?) -> Maybe<WikiTreeState> {
        .error(MockError.mockNotImplement)
    }

    func syncDelete(wikiToken: String) -> Maybe<DeleteResult> {
        .error(MockError.mockNotImplement)
    }

    func syncBatchDelete(parentToken: String, wikiTokens: [String]) -> Maybe<DeleteResult> {
        .error(MockError.mockNotImplement)
    }

    func syncDeleteAndMoveUp(wikiToken: String, parentToken: String, spaceID: String) -> Maybe<DeleteResult> {
        .error(MockError.mockNotImplement)
    }

    func syncMove(oldParentToken: String,
                  newParentToken: String,
                  movedToken: String,
                  movedNode: WikiServerNode?,
                  allowSpaceRedirect: Bool) -> Maybe<MoveResult> {
        .error(MockError.mockNotImplement)
    }

    func syncBatchMove(oldParentToken: String,
                       targetMeta: WikiMeta,
                       movedTokens: [String],
                       movedNodes: [String: WikiServerNode],
                       allowSpaceRedirect: Bool) -> Maybe<MoveResult> {
        .error(MockError.mockNotImplement)
    }

    func syncNodePermissionUpdate(wikiToken: String, node: WikiServerNode?) -> Maybe<MoveResult> {
        .error(MockError.mockNotImplement)
    }

    func syncTitleUpdate(wikiToken: String, newTitle: String, updateForOrigin: Bool) -> Maybe<WikiTreeState> {
        .error(MockError.mockNotImplement)
    }

    func syncToggleStar(wikiToken: String, isStar: Bool) -> Maybe<WikiTreeState> {
        .error(MockError.mockNotImplement)
    }

    func syncToggleExplorerStar(wikiToken: String, isStar: Bool) -> Maybe<WikiTreeState> {
        .error(MockError.mockNotImplement)
    }

    func syncToggleExplorerStarForExternalShortcut(objToken: String, isStar: Bool) -> Maybe<WikiTreeState> {
        .error(MockError.mockNotImplement)
    }
    
    func syncToggleExplorerPin(wikiToken: String, isPin: Bool) -> RxSwift.Maybe<WikiTreeState> {
        .error(MockError.mockNotImplement)
    }
    
    func syncToggleExplorerPinForExternalShortcut(objToken: String, isPin: Bool) -> RxSwift.Maybe<WikiTreeState> {
        .error(MockError.mockNotImplement)
    }
}
