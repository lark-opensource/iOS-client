//
//  WikiTreeDataModel+Sync.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2022/7/29.
//

import Foundation
import RxSwift
import SKCommon
import SKFoundation
import RxRelay
import SpaceInterface

/// 这里处理协同的树结构更新逻辑
/// 注意除了协同外，一些本地操作也会复用部分逻辑
/// 如插入新建节点可以来自后端协同，也可以来自端上本地操作，对数据层而言没有区别，仅在 UI 层有区别
extension WikiTreeDataModel: WikiTreeSyncDataModelType {
    
    // 参考 batchAdd
    public func syncAdd(node: WikiServerNode, originNode: WikiServerNode? = nil) -> Maybe<WikiTreeState> {
        syncBatchAdd(parentWikiToken: node.parent, nodes: [node], originNode: originNode)
    }
    
    /// 向目录树中插入节点，有以下特化逻辑
    /// 1. parent 不存在，则什么也不会发生
    /// 2. parent 存在，parent 是非叶子节点，但 parent 的 children 未知，会拉取一次 parent 的 children
    /// 3. parent 存在，parent 是非叶子节点，children 已知，会直接插入 children
    /// 4. parent 存在，parent 是叶子节点，会更新 parent，直接插入 children
    /// 如果在 shortcut 下创建子节点，需要额外提供本体 node 的信息，否则会出现找不到 parent 的场景
    public func syncBatchAdd(parentWikiToken: String, nodes: [WikiServerNode], originNode: WikiServerNode? = nil) -> Maybe<WikiTreeState> {
        Maybe.create { [weak self] maybe in
            guard let self = self else {
                maybe(.error(DataError.modelReferenceError))
                return Disposables.create()
            }
            if nodes.isEmpty {
                DocsLogger.warning("nodes is empty when add")
                maybe(.completed)
                return Disposables.create()
            }
            do {
                if let originNode = originNode {
                    // 如果有 originNode 信息，也要插入进来
                    self.metaStorage[originNode.meta.wikiToken] = originNode.meta
                    self.relation.insert(wikiToken: originNode.meta.wikiToken,
                                         sortID: originNode.sortID,
                                         parentToken: originNode.parent)
                }
                self.treeState = try self.processor.process(operation: .insert(parentWikiToken: parentWikiToken,
                                                                               nodes: nodes),
                                                            treeState: self.treeState)
                // 3、4 两种场景在内部处理
                var metasToSave = nodes.map(\.meta)
                if originNode == nil, let newParentMeta = self.metaStorage[parentWikiToken] {
                    // parentMeta 可能会被更新，需要重新读一次后写入
                    metasToSave.append(newParentMeta)
                }
                // 更新下 cache
                self.cacheAPI.batchUpdate(metas: metasToSave,
                                          relation: self.relation)
                .subscribe().disposed(by: self.disposeBag)
                if let originNode = originNode {
                    // shortcut 的本体节点单独处理一下
                    self.cacheAPI.batchUpdate(nodes: [originNode], relation: self.relation)
                        .subscribe().disposed(by: self.disposeBag)
                }
                maybe(.success(self.treeState))
                return Disposables.create()
            } catch let error as WikiTreeOperation.InsertError {
                switch error {
                case .parentNotFound:
                    /// 1. parent 不存在，无事发生
                    maybe(.completed)
                    return Disposables.create()
                case .parentChildrenUnknown:
                    // 2. parent 的 children 未知，直接拉一次 children 接口，然后更新数据
                    guard let parentMeta = self.metaStorage[parentWikiToken] else {
                        // 这里如果取不到 parent，当 parent 不存在处理
                        spaceAssertionFailure("parent meta should exist")
                        maybe(.completed)
                        return Disposables.create()
                    }
                    return self.loadChildren(wikiToken: parentMeta.wikiToken, spaceID: parentMeta.spaceID)
                        .asMaybe()
                        .subscribe(maybe)
                }
            } catch {
                DocsLogger.error("unknown error found when add node")
                maybe(.error(error))
                return Disposables.create()
            }
        }
        .subscribeOn(dataQueueScheduler)
    }
    
    // 删除节点, 返回是否包含被选中的节点, 注意这里只代表从树中删除，不等价于文档被删除
    public func syncDelete(wikiToken: String) -> Maybe<DeleteResult> {
        Maybe.create { [weak self] maybe in
            guard let self = self else {
                maybe(.error(DataError.modelReferenceError))
                return Disposables.create()
            }
            // 提前读出来 parentToken
            let parentToken = self.relation.nodeParentMap[wikiToken]
            var selectedTokenDeleted = false
            let deleteCompletion: WikiTreeOperation.DeleteResponse = { deletedTokens in
                // 注意在这个闭包内，self.treeState 还是未更新的状态
                self.cacheAPI.delete(wikiTokens: deletedTokens)
                    .subscribe().disposed(by: self.disposeBag)
                // WARNING: 遍历子树时，实际上不会检查 shortcut 的子节点，所以如果选中的节点路径经过了 shortcut，下面的检查会失效
                if let selectedToken = self.viewState.selectedWikiToken {
                    if wikiToken == selectedToken {
                        selectedTokenDeleted = true
                    } else if deletedTokens.contains(selectedToken) {
                        selectedTokenDeleted = true
                    }
                }
            }
            do {
                self.treeState = try self.processor.process(operation: .delete(wikiToken: wikiToken,
                                                                               response: deleteCompletion),
                                                            treeState: self.treeState)
                var metasToSave: [WikiTreeNodeMeta] = []
                if let parentToken = parentToken,
                   let parentMeta = self.metaStorage[parentToken] {
                    metasToSave.append(parentMeta)
                }
                if let favRootMeta = self.metaStorage[WikiTreeNodeMeta.favoriteRootToken] {
                    metasToSave.append(favRootMeta)
                }
                self.cacheAPI.batchUpdate(metas: metasToSave, relation: self.relation)
                    .subscribe().disposed(by: self.disposeBag)
                let result = DeleteResult(treeState: self.treeState, selectedTokenDeleted: selectedTokenDeleted)
                maybe(.success(result))
                return Disposables.create()
            } catch {
                DocsLogger.error("sync delete failed", error: error)
                maybe(.completed)
                return Disposables.create()
            }
        }
        .subscribeOn(dataQueueScheduler)
    }
    
    // 批量删除节点，要求节点都在同一个 parent 下，返回是否包含被选中的节点
    public func syncBatchDelete(parentToken: String, wikiTokens: [String]) -> Maybe<DeleteResult> {
        Maybe.create { [weak self] maybe in
            guard let self = self else {
                maybe(.error(DataError.modelReferenceError))
                return Disposables.create()
            }
            var selectedTokenDeleted = false
            let deleteCompletion: WikiTreeOperation.DeleteResponse = { deletedTokens in
                // 注意在这个闭包内，self.treeState 还是未更新的状态
                self.cacheAPI.delete(wikiTokens: deletedTokens)
                    .subscribe().disposed(by: self.disposeBag)
                // WARNING: 遍历子树时，实际上不会检查 shortcut 的子节点，所以如果选中的节点路径经过了 shortcut，下面的检查会失效
                if let selectedToken = self.viewState.selectedWikiToken {
                    if wikiTokens.contains(selectedToken) {
                        selectedTokenDeleted = true
                    } else if deletedTokens.contains(selectedToken) {
                        selectedTokenDeleted = true
                    }
                }
            }
            do {
                self.treeState = try self.processor.process(operation: .batchDelete(parentToken: parentToken,
                                                                                    wikiTokens: wikiTokens,
                                                                                    response: deleteCompletion),
                                                            treeState: self.treeState)
                var metasToSave: [WikiTreeNodeMeta] = []
                if let parentMeta = self.metaStorage[parentToken] {
                    metasToSave.append(parentMeta)
                }
                if let favRootMeta = self.metaStorage[WikiTreeNodeMeta.favoriteRootToken] {
                    metasToSave.append(favRootMeta)
                }
                self.cacheAPI.batchUpdate(metas: metasToSave, relation: self.relation)
                    .subscribe().disposed(by: self.disposeBag)
                let result = DeleteResult(treeState: self.treeState, selectedTokenDeleted: selectedTokenDeleted)
                maybe(.success(result))
                return Disposables.create()
            } catch {
                DocsLogger.error("sync delete failed", error: error)
                maybe(.completed)
                return Disposables.create()
            }
        }
        .subscribeOn(dataQueueScheduler)
    }
    
    /// 更新标题
    /// - Parameters:
    ///   - updateForOrigin: 若为 true，且 wikiToken 为 wiki shortcut，则会更新对应的 originWikiToken
    public func syncTitleUpdata(updateData: WikiTreeUpdateData, updateForOrigin: Bool = false) -> Maybe<WikiTreeState> {
        return Maybe.create { [weak self] maybe in
            guard let self = self else {
                maybe(.error(DataError.modelReferenceError))
                return Disposables.create()
            }
            guard var targetMeta = self.metaStorage[updateData.wikiToken] else {
                // 找不到，啥也不干
                maybe(.completed)
                return Disposables.create()
            }
            // 打开 shortcut 后编辑标题时，实际需要更新本体的 title
            if updateForOrigin, case let .shortcut(location) = targetMeta.nodeType {
                switch location {
                case .external:
                    // 本体不在 wiki，啥也不干
                    maybe(.completed)
                    return Disposables.create()
                case let .inWiki(originWikiToken, _):
                    guard let originMeta = self.metaStorage[originWikiToken] else {
                        // 本体在 wiki，但本体节点找不到，啥也不干
                        maybe(.completed)
                        return Disposables.create()
                    }
                    // 转为更新本体 title
                    targetMeta = originMeta
                }
            }
            if let newTitle = updateData.title {
                targetMeta.title = newTitle
            }
            
            if let iconInfo = updateData.iconInfo {
                targetMeta.iconInfo = iconInfo
            }
            self.metaStorage[targetMeta.wikiToken] = targetMeta
            self.cacheAPI.batchUpdate(metas: [targetMeta], relation: self.relation)
                .subscribe().disposed(by: self.disposeBag)
            maybe(.success(self.treeState))
            return Disposables.create()
        }
        .subscribeOn(dataQueueScheduler)
    }
    
    public func syncMove(oldParentToken: String,
                         newParentToken: String,
                         movedToken: String,
                         movedNode: WikiServerNode?,
                         allowSpaceRedirect: Bool) -> Maybe<MoveResult> {
        guard let movedNode = movedNode else {
            // 拿不到新的节点信息说明移动后失去了权限，改为从树上删除节点
            return syncDelete(wikiToken: movedToken)
                .map {
                    MoveResult(treeState: $0.treeState,
                               selectedTokenDeleted: $0.selectedTokenDeleted,
                               selectedTokenMoved: false)
                }
        }
        let newSpaceID = movedNode.meta.spaceID
        
        // 置顶目录树上的一级节点忽略掉移动操作
        if ignoreSyncMove(wikiToken: movedToken) {
            DocsLogger.info("ignore move operation of first level node in clip document tree")
            return .empty()
        }
        
        // 禁止 space 重定向时，若节点发生了跨库移动，按删除处理
        // 外部配置控制跨库移动后是否立刻从目录树上删除
        if !allowSpaceRedirect,
           !treeSpaceIds.contains(newSpaceID),
           !config.ignoreCrossMoveSync {
            return syncDelete(wikiToken: movedToken)
                .map {
                    MoveResult(treeState: $0.treeState,
                               selectedTokenDeleted: $0.selectedTokenDeleted,
                               selectedTokenMoved: false)
                }
        }
        return syncBatchMove(oldParentToken: oldParentToken,
                             targetMeta: WikiMeta(wikiToken: newParentToken, spaceID: movedNode.meta.spaceID),
                             movedTokens: [movedToken],
                             movedNodes: [movedToken: movedNode],
                             allowSpaceRedirect: allowSpaceRedirect)
    }
    
    /// 移动节点，有以下几种场景
    /// 1. 同库内，移动非选中节点，正常移动
    /// 2. 同库内，移动选中节点，移动后，若节点不可见，需要拉取目标位置并定位
    /// 3. 跨库移动非选中节点，直接删除
    /// 4. 跨库移动选中节点，先从父节点删除，再拉取目标位置并定位，同时刷新 space 信息
    /// 若 allowSpaceRedirect 为 false，则跨库移动按照删除处理
    /// 返回最新的 treeState，以及选中的节点是否被 moved
    public func syncBatchMove(oldParentToken: String,
                              targetMeta: WikiMeta,
                              movedTokens: [String],
                              movedNodes: [String: WikiServerNode],
                              allowSpaceRedirect: Bool) -> Maybe<MoveResult> {
        // 禁止 space 重定向时，若节点发生了跨库移动，按删除处理
        // 外部配置控制跨库移动后是否立即从树上删除节点
        let treatAsDelete = !allowSpaceRedirect && !treeSpaceIds.contains(targetMeta.spaceID) && !config.ignoreCrossMoveSync
        if movedNodes.isEmpty || treatAsDelete {
            // 拿不到新的节点信息说明移动后失去了权限，改为从树上删除节点
            return syncBatchDelete(parentToken: oldParentToken, wikiTokens: movedTokens)
                .map {
                    MoveResult(treeState: $0.treeState,
                               selectedTokenDeleted: $0.selectedTokenDeleted,
                               selectedTokenMoved: false)
                }
        }
        return Maybe.create { [weak self] maybe in
            guard let self = self else {
                maybe(.error(DataError.modelReferenceError))
                return Disposables.create()
            }
            let selectedTokenMoved: Bool
            if let selectedToken = self.viewState.selectedWikiToken {
                let movedTreeToken = movedTokens.first { movedToken in
                    self.relation.checkSubTree(rootToken: movedToken, contains: selectedToken)
                }
                if let movedTreeToken = movedTreeToken,
                   movedNodes[movedTreeToken] != nil {
                    selectedTokenMoved = true
                } else {
                    selectedTokenMoved = false
                }
            } else {
                selectedTokenMoved = false
            }
            let nodes = movedNodes.map { _, node -> WikiServerNode in
                var newMeta = node.meta
                // 这里将所有被移动端的节点的 spaceID 更新一下，原因是本地移动的时候，本地的 node 信息还是旧的 spaceID
                newMeta.spaceID = targetMeta.spaceID
                return WikiServerNode(meta: newMeta, sortID: node.sortID, parent: node.parent)
            }
            do {
                // 这里不区分跨库，如果跨库，新 parent 不存在，会从本库的旧 parent 的关系中删除，可以兼容
                let operation = WikiTreeOperation.move(oldParentToken: oldParentToken,
                                                       newParentToken: targetMeta.wikiToken,
                                                       nodes: nodes)
                self.treeState = try self.processor.process(operation: operation,
                                                            treeState: self.treeState)
                var metasToSave = nodes.map(\.meta)
                if let oldParentMeta = self.metaStorage[oldParentToken] {
                    metasToSave.append(oldParentMeta)
                }
                if let newParentMeta = self.metaStorage[targetMeta.wikiToken] {
                    metasToSave.append(newParentMeta)
                }
                self.cacheAPI.batchUpdate(metas: metasToSave, relation: self.relation)
                    .subscribe().disposed(by: self.disposeBag)

                guard selectedTokenMoved,
                      let selectedWikiToken = self.viewState.selectedWikiToken else {
                    // 选中节点不受影响情况下，没有后续流程
                    let result = MoveResult(treeState: self.treeState,
                                            selectedTokenDeleted: false,
                                            selectedTokenMoved: false)
                    maybe(.success(result))
                    return Disposables.create()
                }
                // 选中节点受影响，展开并选中目标节点
                if self.treeSpaceIds.contains(targetMeta.spaceID) {
                    // 同库移动场景，按需重载树结构并合并
                    return self.focus(wikiToken: selectedWikiToken)
                        .asMaybe()
                        .map { result -> MoveResult in
                            MoveResult(treeState: result,
                                       selectedTokenDeleted: false,
                                       selectedTokenMoved: true)
                        }
                        .subscribe(maybe)
                } else {
                    // 与「我的文档库」相关的空间内高亮节点跨库移动不做处理，没有后续流程
                    // 详情页目录树的跨库移动必须刷新
                    let scene = self.scene
                    let disableMove = (scene == .myLibrary || MyLibrarySpaceIdCache.isMyLibrary(targetMeta.spaceID)) && scene != .documentDraggablePage
                    // 依赖外部配置是否忽略跨库移动后的知识库刷新
                    if self.config.ignoreCrossMoveSync || disableMove {
                        let result = MoveResult(treeState: self.treeState,
                                                selectedTokenDeleted: false,
                                                selectedTokenMoved: false)
                        maybe(.success(result))
                        return Disposables.create()
                    }
                    // 跨库移动，需要 reset 一下 spaceID
                    return self.reset(spaceID: targetMeta.spaceID, initialWikiToken: selectedWikiToken)
                        .asMaybe()
                        .map { result -> MoveResult in
                            MoveResult(treeState: result,
                                       selectedTokenDeleted: false,
                                       selectedTokenMoved: true)
                        }
                        .subscribe(maybe)
                }
            } catch {
                spaceAssertionFailure("processor move operation should not throw error")
                maybe(.error(error))
                return Disposables.create()
            }
        }
        .subscribeOn(dataQueueScheduler)
    }
    
    // 可能导致节点被移动，多返回一个 bool 表示状态
    public func syncNodePermissionUpdate(wikiToken: String, node: WikiServerNode?) -> Maybe<MoveResult> {
        guard let node = node else {
            // node 为 nil 表示失去节点权限，当删除处理
            return syncDelete(wikiToken: wikiToken)
                .map {
                    MoveResult(treeState: $0.treeState,
                               selectedTokenDeleted: $0.selectedTokenDeleted,
                               selectedTokenMoved: false)
                }
        }
        return Maybe.create { [weak self] maybe in
            guard let self = self else {
                maybe(.error(DataError.modelReferenceError))
                return Disposables.create()
            }
            if self.metaStorage[wikiToken] != nil,
               let oldParentToken = self.relation.nodeParentMap[wikiToken] {
                // 有权限变化前的信息，权限变化后视为一次移动操作
                return self.syncMove(oldParentToken: oldParentToken,
                                     newParentToken: node.parent,
                                     movedToken: wikiToken,
                                     movedNode: node,
                                     allowSpaceRedirect: false)
                .subscribe(maybe)
            } else {
                // 没有权限变化前的信息，权限变化后视为一次插入操作
                return self.syncAdd(node: node)
                    .map { result -> MoveResult in
                        MoveResult(treeState: result,
                                   selectedTokenDeleted: false,
                                   selectedTokenMoved: false)
                    }
                    .subscribe(maybe)
            }
        }
        .subscribeOn(dataQueueScheduler)
    }
    
    // 更新 wiki 的置顶状态
    public func syncToggleStar(wikiToken: String, isStar: Bool) -> Maybe<WikiTreeState> {
        return Maybe.create { [weak self] maybe in
            guard let self = self else {
                maybe(.error(DataError.modelReferenceError))
                return Disposables.create()
            }
            do {
                self.treeState = try self.processor.process(operation: .toggleWikiStar(wikiToken: wikiToken, isStar: isStar),
                                                            treeState: self.treeState)
                if let favoriteMeta = self.metaStorage[WikiTreeNodeMeta.favoriteRootToken] {
                    // 更新一下缓存里的收藏列表
                    self.cacheAPI.batchUpdate(metas: [favoriteMeta], relation: self.relation)
                        .subscribe().disposed(by: self.disposeBag)
                }
                maybe(.success(self.treeState))
                return Disposables.create()
            } catch {
                // 出现 error 说明树结构不需要更新，通常意味着收藏列表未知或没有实际发生改变
                DocsLogger.info("toggle wiki star found error", error: error)
                maybe(.completed)
                return Disposables.create()
            }
        }
        .subscribeOn(dataQueueScheduler)
    }
    
    public func syncToggleExplorerStar(wikiToken: String, isStar: Bool) -> Maybe<WikiTreeState> {
        return Maybe.create { [weak self] maybe in
            guard let self = self else {
                maybe(.error(DataError.modelReferenceError))
                return Disposables.create()
            }
            do {
                self.treeState = try self.processor.process(operation: .toggleExplorerStar(wikiToken: wikiToken, isStar: isStar),
                                                            treeState: self.treeState)
                if let targetMeta = self.metaStorage[wikiToken] {
                    // 更新一下被改的节点
                    self.cacheAPI.batchUpdate(metas: [targetMeta], relation: self.relation)
                        .subscribe().disposed(by: self.disposeBag)
                }
                maybe(.success(self.treeState))
                return Disposables.create()
            } catch {
                // 出现 error 说明树结构不需要更新，通常意味着收藏列表未知或没有实际发生改变
                DocsLogger.info("toggle wiki star found error", error: error)
                maybe(.completed)
                return Disposables.create()
            }
        }
        .subscribeOn(dataQueueScheduler)
    }
    
    public func syncToggleExplorerStarForExternalShortcut(objToken: String, isStar: Bool) -> Maybe<WikiTreeState> {
        return Maybe.create { [weak self] maybe in
            guard let self = self else {
                maybe(.error(DataError.modelReferenceError))
                return Disposables.create()
            }
            do {
                let operation = WikiTreeOperation.toggleExplorerStarForExternalShortcut(objToken: objToken, isStar: isStar)
                self.treeState = try self.processor.process(operation: operation,
                                                            treeState: self.treeState)
                maybe(.success(self.treeState))
                return Disposables.create()
            } catch {
                DocsLogger.error("toggle external shortcut star should not throw error", error: error)
                spaceAssertionFailure("toggle external shortcut star should not throw error")
                maybe(.error(error))
                return Disposables.create()
            }
        }
        .subscribeOn(dataQueueScheduler)
    }
    
    public func syncToggleExplorerPin(wikiToken: String, isPin: Bool) -> Maybe<WikiTreeState> {
        return Maybe.create { [weak self] maybe in
            guard let self else {
                maybe(.error(DataError.modelReferenceError))
                return Disposables.create()
            }
            do {
                self.treeState = try self.processor.process(operation: .toggleExplorerPin(wikiToken: wikiToken, isPin: isPin),
                                                            treeState: self.treeState)
                if let targetMeta = self.metaStorage[wikiToken] {
                    //更新一下改动节点
                    self.cacheAPI.batchUpdate(metas: [targetMeta], relation: self.relation)
                        .subscribe().disposed(by: self.disposeBag)
                }
                maybe(.success(self.treeState))
                return Disposables.create()
            } catch {
                // 出现error说明树结构不需要更新，一般是指快速访问状态没有发生实际变化
                DocsLogger.info("toggle wiki pin found error", error: error)
                maybe(.completed)
                return Disposables.create()
            }
        }
        .subscribeOn(dataQueueScheduler)
    }
    
    public func syncToggleExplorerPinForExternalShortcut(objToken: String, isPin: Bool) -> Maybe<WikiTreeState> {
        return Maybe.create { [weak self] maybe in
            guard let self else {
                maybe(.error(DataError.modelReferenceError))
                return Disposables.create()
            }
            do {
                self.treeState = try self.processor.process(operation: .toggleExplorerPinForExternalShortcut(objToken: objToken, isPin: isPin),
                                                            treeState: self.treeState)
                maybe(.success(self.treeState))
                return Disposables.create()
            } catch {
                DocsLogger.error("toggle external shortcut pin should not throw error", error: error)
                spaceAssertionFailure("toggle external shortcut pin should not throw error")
                maybe(.error(error))
                return Disposables.create()
            }
        }
        .subscribeOn(dataQueueScheduler)
    }
    
    public func syncDeleteAndMoveUp(wikiToken: String, parentToken: String, spaceID: String) -> Maybe<DeleteResult> {
        return Maybe.create { [weak self] maybe in
            guard let self = self else {
                maybe(.error(DataError.modelReferenceError))
                return Disposables.create()
            }
            guard let targetMeta = self.metaStorage[wikiToken] else {
                // 找不到被删除的节点，不处理
                maybe(.completed)
                return Disposables.create()
            }
            
            // 有以下两个步骤
            // 1. 刷新一次父节点, 此时子节点都会被更新到父节点上
            return self.loadChildren(wikiToken: parentToken, spaceID: spaceID).asMaybe()
                .flatMap { [weak self] _ -> Maybe<DeleteResult> in
                    guard let self = self else {
                        return .error(DataError.modelReferenceError)
                    }
                    // 2. 删除目标节点
                    return self.syncDelete(wikiToken: wikiToken)
                }
                .subscribe(maybe)
        }
        .subscribeOn(dataQueueScheduler)
    }
    
    // 置顶树的一级节点忽略掉因权限协同事件触发的Move操作
    private func ignoreSyncMove(wikiToken: String) -> Bool {
        let clipDocumentRootToken = WikiTreeNodeMeta.clipDocumentRootToken
        let clipDocumentSpaceId = WikiTreeNodeMeta.clipDocumentSpaceID
        let relation = treeState.relation
        // 置顶目录树下的所有一级节点
        let childrens: [String] = relation.nodeChildrenMap[clipDocumentRootToken]?.compactMap { $0.wikiToken } ?? []
        // 保证是在置顶目录树下 && 当前节点是置顶目录树下的一级节点
        return treeSpaceIds.contains(WikiTreeNodeMeta.clipDocumentSpaceID) && childrens.contains(wikiToken)
    }
}
