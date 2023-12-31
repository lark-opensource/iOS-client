//
//  WikiTreeDataModelType.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2022/8/15.
//

import Foundation
import RxSwift
import RxCocoa
import SKCommon
import SpaceInterface

// 初始化状态
public struct WikiTreeInitialState {
    // 缓存状态，nil 表示尚未加载到
    public var cacheState: Result<Void, Error>?
    // 服务端状态，nil 表示尚未加载到
    public var serverState: Result<Void, Error>?
    
    public init(cacheState: Result<Void, Error>? = nil, serverState: Result<Void, Error>? = nil) {
        self.cacheState = cacheState
        self.serverState = serverState
    }
}

public enum WikiTreeDataError: Error {
    case modelReferenceError
}

public protocol WikiTreeDataModelType: AnyObject {
    typealias InitialState = WikiTreeInitialState
    typealias DataError = WikiTreeDataError
    typealias MetaStorage = WikiTreeNodeMeta.MetaStorage

    // MARK: - Space 基本信息
    var initialWikiToken: String? { get }
    var spaceID: String { get }
    var spaceIDUpdated: Driver<String> { get }
    var spaceInfoUpdated: Driver<WikiSpace?> { get }
    var userSpacePermissionUpdated: Driver<WikiUserSpacePermission> { get }
    var initialStateUpdated: Driver<InitialState> { get }
    /// MVP首页虚拟置顶知识库树维护多个知识库的spaceId
    var treeSpaceIds: [String] { get }

    var treeState: WikiTreeState { get }

    func restore() -> Maybe<WikiTreeState>
    func restoreFavoriteList() -> Maybe<WikiTreeState>
    func makeFavoriteRoot() -> Single<WikiTreeState>
    // 额外 flag 表明 cacheLoaded
    func reload() -> Single<(WikiTreeState, Bool)>
    func reloadFavoriteList() -> Single<WikiTreeState>
    func reset(context: WikiTreeContext) -> Single<WikiTreeState>

    func select(wikiToken: String, nodeUID: WikiTreeNodeUID?) -> Single<WikiTreeState>
    // 额外 flag 表明 isFromCache
    func expand(wikiToken: String, spaceID: String, nodeUID: WikiTreeNodeUID) -> Observable<(WikiTreeState, Bool)>
    func expand(nodeUID: WikiTreeNodeUID) -> Single<WikiTreeState>
    func collapse(nodeUID: WikiTreeNodeUID) -> Single<WikiTreeState>

    func focus(wikiToken: String) -> Single<WikiTreeState>
}

public struct WikiTreeSyncDeleteResult {
    public let treeState: WikiTreeState
    public let selectedTokenDeleted: Bool
    public init(treeState: WikiTreeState, selectedTokenDeleted: Bool) {
        self.treeState = treeState
        self.selectedTokenDeleted = selectedTokenDeleted
    }
}

public struct WikiTreeSyncMoveResult {
    public let treeState: WikiTreeState
    public let selectedTokenDeleted: Bool
    public let selectedTokenMoved: Bool
    public init(treeState: WikiTreeState, selectedTokenDeleted: Bool, selectedTokenMoved: Bool) {
        self.treeState = treeState
        self.selectedTokenDeleted = selectedTokenDeleted
        self.selectedTokenMoved = selectedTokenMoved
    }
}

// 由于 picker tree 有一些轻量的本地协同逻辑，抽一个小的 protocol
public protocol WikiTreeBasicSyncDataModelType: AnyObject {
    func syncAdd(node: WikiServerNode, originNode: WikiServerNode?) -> Maybe<WikiTreeState>
    func syncTitleUpdata(updateData: WikiTreeUpdateData, updateForOrigin: Bool) -> Maybe<WikiTreeState>
}

extension WikiTreeBasicSyncDataModelType {
    public func syncAdd(node: WikiServerNode) -> Maybe<WikiTreeState> {
        syncAdd(node: node, originNode: nil)
    }
    
    public func syncTitleUpdata(wikiToken: String, newTitle: String) -> Maybe<WikiTreeState> {
        syncTitleUpdata(updateData: WikiTreeUpdateData(wikiToken: wikiToken, title: newTitle), updateForOrigin: false)
    }
}

// 拓展协同的功能
public protocol WikiTreeSyncDataModelType: WikiTreeBasicSyncDataModelType {

    func syncBatchAdd(parentWikiToken: String, nodes: [WikiServerNode], originNode: WikiServerNode?) -> Maybe<WikiTreeState>

    typealias DeleteResult = WikiTreeSyncDeleteResult
    func syncDelete(wikiToken: String) -> Maybe<DeleteResult>
    func syncBatchDelete(parentToken: String, wikiTokens: [String]) -> Maybe<DeleteResult>
    func syncDeleteAndMoveUp(wikiToken: String, parentToken: String, spaceID: String) -> Maybe<DeleteResult>

    typealias MoveResult = WikiTreeSyncMoveResult
    func syncMove(oldParentToken: String,
                  newParentToken: String,
                  movedToken: String,
                  movedNode: WikiServerNode?,
                  allowSpaceRedirect: Bool) -> Maybe<MoveResult>
    func syncBatchMove(oldParentToken: String,
                       targetMeta: WikiMeta,
                       movedTokens: [String],
                       movedNodes: [String: WikiServerNode],
                       allowSpaceRedirect: Bool) -> Maybe<MoveResult>
    func syncNodePermissionUpdate(wikiToken: String, node: WikiServerNode?) -> Maybe<MoveResult>

    func syncToggleStar(wikiToken: String, isStar: Bool) -> Maybe<WikiTreeState>
    func syncToggleExplorerStar(wikiToken: String, isStar: Bool) -> Maybe<WikiTreeState>
    func syncToggleExplorerStarForExternalShortcut(objToken: String, isStar: Bool) -> Maybe<WikiTreeState>
    func syncToggleExplorerPin(wikiToken: String, isPin: Bool) -> Maybe<WikiTreeState>
    func syncToggleExplorerPinForExternalShortcut(objToken: String, isPin: Bool) -> Maybe<WikiTreeState>
}

extension WikiTreeSyncDataModelType {
    public func syncBatchAdd(parentWikiToken: String, nodes: [WikiServerNode]) -> Maybe<WikiTreeState> {
        syncBatchAdd(parentWikiToken: parentWikiToken,
                     nodes: nodes,
                     originNode: nil)
    }
}

public typealias WikiPickerTreeDataModelType = WikiTreeDataModelType & WikiTreeBasicSyncDataModelType
public typealias WikiMainTreeDataModelType = WikiTreeDataModelType & WikiTreeSyncDataModelType
