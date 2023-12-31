//
//  TreeMoreActionSyncDispatcher.swift
//  SKWorkspace
//
//  Created by majie.7 on 2023/5/25.
//

import Foundation
import RxSwift
import RxCocoa
import RxRelay
import SKFoundation
import SKCommon
import SKInfra
import SpaceInterface
import LarkContainer

public protocol TreeSyncModelType: AnyObject {
    var syncDataModel: WikiMainTreeDataModelType { get }
    var scene: WikiMainTreeScene { get }
    var spaceInfo: WikiSpace? { get }
    var userSpacePermission: WikiUserSpacePermission { get }
    var wikiActionInput: PublishRelay<WikiTreeViewAction> { get }
    var treeStateRelay: BehaviorRelay<WikiTreeState> { get }
    var scrollByUIDInput: PublishRelay<WikiTreeNodeUID> { get }
    /// 向外传递点击事件，参数为点击的节点 nodeMeta、nodeUID、和当下的目录树快照
    var onClickNodeInput: PublishRelay<(WikiTreeNodeMeta, WikiTreeContext)> { get }
    /// 手动删除节点时需要上报
    var onManualDeleteNodeInput: PublishRelay<Void> { get }
    /// 参数为: 父节点 wikiToken，是否是图片，callback
    var onUploadInput: PublishRelay<(String, Bool, DidSelectFileAction)> { get }
}


public class TreeMoreActionSyncDispatcher {
    private let disposeBag = DisposeBag()
    // 弱引用，避免内存泄漏
    private weak var syncModel: TreeSyncModelType?
    private var handler: TreeSyncDispatchHandler
    
    let userResolver: UserResolver
    public init(userResolver: UserResolver, syncModel: TreeSyncModelType) {
        self.userResolver = userResolver
        self.syncModel = syncModel
        self.handler = TreeSyncDispatchHandler(userResolver: userResolver, syncModel: syncModel)
    }
    
    
    public func handleMoreAction(action: WikiTreeMoreAction) {
        switch action {
        case let .upload(parentToken, isImage, completion):
            syncModel?.onUploadInput.accept((parentToken, isImage, completion))
        case let .create(response):
            didCreateNode(response: response)
        case let .remove(meta):
            didRemoveNode(meta: meta)
        case let .move(oldParentToken, movedNode):
            didMovedNode(oldParentToken: oldParentToken, movedNode: movedNode)
        case let .copy(newNode):
            didCopyNode(newNode: newNode)
        case let .shortcut(newNode):
            handler.handleSyncAdd(node: newNode)
        case let .delete(meta, isSingleDelete):
            didDeleteNode(meta: meta, isSingleDelete: isSingleDelete)
        case let .toggleClip(meta, setClip):
            handler.handleSyncToggleStar(wikiToken: meta.wikiToken, isStar: setClip)
        case let .toggleExplorerStar(meta, setStar):
            handler.handleSyncToggleExplorerStar(wikiToken: meta.wikiToken, isStar: setStar)
        case let .toggleExplorerPin(meta, setPin):
            handler.handleSyncToggleExplorerPin(wikiToken: meta.wikiToken, isPin: setPin)
        case let .updateTitle(wikiToken, newTitle):
            didUpdateTitle(wikiToken: wikiToken, newTitle: newTitle)
        }
    }
    
    // 处理创建完成事件并更新 UI、跳转文档
    private func didCreateNode(response: WikiTreeCreateResponse) {
        guard let syncModel else {
            spaceAssertionFailure("syncmodel must be implemented")
            return
        }
        // 注意这里和协同的实现有差异，主要在于定位 + 滚动 + 跳转文档
        syncModel.syncDataModel.syncAdd(node: response.newNode, originNode: response.originNode)
            .flatMap { [weak syncModel] state -> Maybe<WikiTreeState> in
                guard let syncModel else { return .just(state) }
                // 展开父节点
                return syncModel.syncDataModel.expand(nodeUID: response.nodeUID).asMaybe()
            }
            .flatMap { [weak syncModel] state -> Maybe<WikiTreeState> in
                guard let syncModel else { return .just(state) }
                // 选中新创建的节点
                let nodeUID = response.nodeUID.extend(childToken: response.newNode.meta.wikiToken,
                                                      currentIsShortcut: response.newNode.meta.isShortcut)
                return syncModel.syncDataModel.select(wikiToken: response.newNode.meta.wikiToken,
                                                      nodeUID: nodeUID)
                .asMaybe()
            }
            .observeOn(MainScheduler.instance)
            .subscribe { [weak syncModel] state in
                guard let syncModel else { return }
                syncModel.wikiActionInput.accept(.hideHUD)
                syncModel.treeStateRelay.accept(state)
                let newUID = response.nodeUID.extend(childToken: response.newNode.meta.wikiToken,
                                                     currentIsShortcut: response.nodeMeta.isShortcut)
                syncModel.scrollByUIDInput.accept(newUID)
                let context = WikiTreeContext(nodeUID: newUID,
                                              spaceID: syncModel.syncDataModel.spaceID,
                                              treeState: state,
                                              spaceInfo: syncModel.spaceInfo,
                                              userSpacePermission: syncModel.userSpacePermission,
                                              params: ["from": "tab_create"])
                syncModel.onClickNodeInput.accept((response.newNode.meta, context))
            } onError: { [weak self] error in
                guard let self = self else { return }
                DocsLogger.error("error found when handle create completed event", error: error)
                spaceAssertionFailure()
                self.syncModel?.wikiActionInput.accept(.hideHUD)
            } onCompleted: { [weak self] in
                DocsLogger.error("not state receive when handle create completed event")
                spaceAssertionFailure()
                self?.syncModel?.wikiActionInput.accept(.hideHUD)
            }
            .disposed(by: disposeBag)
    }
    
    // 处理移除操作的协同逻辑
    private func didRemoveNode(meta: WikiTreeNodeMeta) {
        guard let syncModel else {
            spaceAssertionFailure("syncmodel must be implemented")
            return
        }
        let state = syncModel.treeStateRelay.value
        let parent = state.relation.nodeParentMap[meta.wikiToken]
        // 同协同逻辑
        handler.handleDeleteAndMoveUp(wikiToken: meta.wikiToken, parentWikiToken: parent ?? "", spaceID: meta.spaceID)
        // 更新路由表
        let record = WorkspaceCrossRouteRecord(wikiToken: meta.wikiToken,
                                               objToken: meta.objToken,
                                               objType: meta.objType,
                                               inWiki: false,
                                               logID: nil)
        DocsContainer.shared.resolve(WorkspaceCrossRouteStorage.self)?.set(record: record)
    }
    
    private func didMovedNode(oldParentToken: String, movedNode: WikiServerNode) {
        // 同协同逻辑
        handler.handleSyncMove(oldParentToken: oldParentToken,
                               newParentToken: movedNode.parent,
                               movedToken: movedNode.meta.wikiToken,
                               movedNode: movedNode,
                               allowSpaceRedirect: true) // 主动跨库移动场景，允许 wiki space 重定向
    }
    
    private func didCopyNode(newNode: WikiServerNode) {
        guard let syncModel else {
            spaceAssertionFailure("syncmodel must be implemented")
            return
        }
        // 只有知识库首页才可定位+跳转
        let shouldFocus = syncModel.scene == .spacePage
        guard shouldFocus else {
            // 文档详情页内，复用协同逻辑，不需要额外定位+滚动
            handler.handleSyncAdd(node: newNode)
            return
        }
        // 这里和新建比较类似，插入 + 定位 + 滚动，但是没有跳转，而且新建的节点也不一定在同一个知识库内
        let isSameSpace = newNode.meta.spaceID == syncModel.syncDataModel.spaceID
        syncModel.syncDataModel.syncAdd(node: newNode)
            .flatMap { [weak syncModel] state -> Maybe<WikiTreeState> in
                guard let syncModel else { return .just(state) }
                // 插入成功，选中新创建的节点, 这里不更新 nodeUID，在下面的 focus 里按需更新
                return syncModel.syncDataModel.select(wikiToken: newNode.meta.wikiToken,
                                                      nodeUID: nil).asMaybe()
            }
            .flatMap { [weak syncModel] state -> Maybe<WikiTreeState> in
                guard let syncModel else { return .just(state) }
                if isSameSpace {
                    // 同库才可定位
                    return syncModel.syncDataModel.focus(wikiToken: newNode.meta.wikiToken).asMaybe()
                } else {
                    return .just(state)
                }
            }
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] state in
                guard let self = self else { return }
                self.syncModel?.treeStateRelay.accept(state)
                if isSameSpace {
                    self.handler.focusNode(wikiToken: newNode.meta.wikiToken, shouldLoading: false)
                }
            } onError: { error in
                DocsLogger.error("found error when handle copy node event", error: error)
            } onCompleted: {
                DocsLogger.info("no update for tree after copy node event")
            }
            .disposed(by: disposeBag)
    }
    
    private func didDeleteAllNode(wikiToken: String) {
        guard let syncModel else {
            spaceAssertionFailure("syncmodel must be implemented")
            return
        }
        syncModel.syncDataModel.syncDelete(wikiToken: wikiToken)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] result in
                guard let self = self else { return }
                self.syncModel?.treeStateRelay.accept(result.treeState)
                if result.selectedTokenDeleted {
                    self.syncModel?.onManualDeleteNodeInput.accept(())
                }
            } onError: { error in
                DocsLogger.error("found error when handle delete node event", error: error)
            } onCompleted: {
                DocsLogger.info("no update for tree after delete node event")
            }
            .disposed(by: disposeBag)
    }
    
    private func didUpdateTitle(wikiToken: String, newTitle: String) {
        handler.handleSyncTitleUpdata(updateData: WikiTreeUpdateData(wikiToken: wikiToken, title: newTitle))
    }
    
    private func didDeleteNode(meta: WikiTreeNodeMeta, isSingleDelete: Bool) {
        guard let syncModel else {
            spaceAssertionFailure("syncmodel must be implemented")
            return
        }
        if isSingleDelete {
            let state = syncModel.treeStateRelay.value
            let parent = state.relation.nodeParentMap[meta.wikiToken]
            // 同协同逻辑
            handler.handleDeleteAndMoveUp(wikiToken: meta.wikiToken, parentWikiToken: parent ?? "", spaceID: meta.spaceID)
        } else {
            didDeleteAllNode(wikiToken: meta.wikiToken)
        }
        let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
        dataCenterAPI?.deleteSpaceEntry(token: TokenStruct(token: meta.wikiToken))
    }
}
