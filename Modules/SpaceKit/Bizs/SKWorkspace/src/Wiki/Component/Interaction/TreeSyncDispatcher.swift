//
//  TreeSyncDispatcher.swift
//  SKWorkspace
//
//  Created by majie.7 on 2023/5/26.
//

import Foundation
import SKCommon
import SKFoundation
import SKInfra
import SpaceInterface
import RxCocoa
import RxRelay
import RxSwift
import LarkContainer

public enum WikiLocalSync {
    /// 刷新个人文件列表
    public static let MovedFromMoreName = Notification.Name(rawValue: "docs.bytedance.notification.name.Docs.Wiki.MovedFromMore")
    public static func movedFromMore(movedMeta: WikiMeta,
                                     newParentMeta: WikiMeta,
                                     newSortID: Double,
                                     oldParentToken: String?,
                                     synergyUUID: String?) -> Notification {
        Notification(name: MovedFromMoreName,
                     object: nil,
                     userInfo: [
                        "movedMeta": movedMeta,
                        "newParentMeta": newParentMeta,
                        "newSortID": newSortID,
                        "oldParentToken": oldParentToken,
                        "synergyUUID": synergyUUID
                     ])
    }
}

public class TreeSyncDispatchHandler {
    private let disposeBag = DisposeBag()
    // 弱引用，避免内存泄漏
    private weak var syncModel: TreeSyncModelType?
    // 每个知识库的SpaceID 对应一个知识库
    private var dispatherManager: [String: WikiSyncDispatcher] = [:]
    
    private let workQueue = DispatchQueue(label: "tree.sync.dispatcher")
    private lazy var workQueueScheduler = SerialDispatchQueueScheduler(queue: workQueue,
                                                                       internalSerialQueueName: "tree.sync.dispatcher.scheduler")
    
    let userResolver: UserResolver
    
    public init(userResolver: UserResolver,
                syncModel: TreeSyncModelType) {
        self.userResolver = userResolver
        self.syncModel = syncModel
        setupLocalNotificationSync()
    }
    
    public func addDispather(spaceId: String, synergyUUID: String) {
        // 每个知识库的协同插入字典时放入特定线程，防止多线程读写
        workQueue.sync(flags: [.barrier]) {
            if dispatherManager[spaceId] != nil {
                // 已经启动的协同事件直接return
                return
            }
            let dispather = WikiSyncDispatcher(spaceID: spaceId, synergyUUID: synergyUUID, networkAPI: WikiNetworkManager.shared)
            dispatherManager[spaceId] = dispather
            setupDispathProcessor(syncDispatcher: dispather, spaceId: spaceId)
        }
    }

    /// 单一目录树场景（详情页、知识空间页），跨库移动后需要移除旧 space 的监听
    public func removeAllDispatcher() {
        workQueue.sync(flags: [.barrier]) { [weak self] in
            self?.dispatherManager = [:]
        }
    }
    
    // MARK: - 本体协同
    private func setupLocalNotificationSync() {
        NotificationCenter.default.rx.notification(Notification.Name.Docs.wikiStarNode)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] notification in
                guard let self = self,
                      let wikiToken = notification.object as? String else {
                    return
                }
                self.handleSyncToggleStar(wikiToken: wikiToken, isStar: true)
            })
            .disposed(by: disposeBag)
        // TODO: wikiStar 通知二合一
        NotificationCenter.default.rx.notification(Notification.Name.Docs.wikiUnStarNode)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] notification in
                guard let self = self,
                      let wikiToken = notification.object as? String else {
                    return
                }
                self.handleSyncToggleStar(wikiToken: wikiToken, isStar: false)
            })
            .disposed(by: disposeBag)
        // 本地协同：explorer收藏
        NotificationCenter.default.rx.notification(Notification.Name.Docs.wikiExplorerStarNode)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] notification in
                guard let self = self else { return }
                guard let objType = notification.userInfo?["objType"] as? DocsType,
                      let objToken = notification.userInfo?["objToken"] as? String,
                      let addStar = notification.userInfo?["addStar"] as? Bool else {
                    DocsLogger.error("can not get target token and type from local explorer star sync event")
                    return
                }
                if objType == .wiki {
                    self.handleSyncToggleExplorerStar(wikiToken: objToken, isStar: addStar)
                } else {
                    self.handleSyncToggleExplorerStarForExternalShortcut(objToken: objToken, isStar: addStar)
                }
            })
            .disposed(by: disposeBag)
        // 本地协同：跨库节点标题变更使用，可能受到其他 space 内的事件
        NotificationCenter.default.rx.notification(Notification.Name.Docs.wikiTitleUpdated)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] notification in
                guard let self = self else { return }
                guard let userInfo = notification.userInfo,
                      let wikiToken = userInfo["wikiToken"] as? String,
                      let newName = userInfo["newName"] as? String else {
                    DocsLogger.error("wiki title update notification has no wikiToken or newName")
                    return
                }
                let updateForOrigin = userInfo["updateForOrigin"] as? Bool ?? false
                self.handleSyncTitleUpdata(updateData: WikiTreeUpdateData(wikiToken: wikiToken, title: newName),
                                           updateForOrigin: updateForOrigin)
            })
            .disposed(by: disposeBag)
        // 本地协同：explorer快速访问
        NotificationCenter.default.rx.notification(Notification.Name.Docs.WikiExplorerPinNode)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] notification in
                guard let self else { return }
                guard let userInfo = notification.userInfo,
                      let objType = userInfo["objType"] as? DocsType,
                      let targetToken = userInfo["targetToken"] as? String,
                      let addPin = userInfo["addPin"] as? Bool else {
                    DocsLogger.error("can not get target token and type, pin status from explorer pin sync event")
                    return
                }
                if objType == .wiki {
                    self.handleSyncToggleExplorerPin(wikiToken: targetToken, isPin: addPin)
                } else {
                    self.handleSyncToggleExplorerPinForExternalShorcut(objToken: targetToken, isPin: addPin)
                }
            })
            .disposed(by: disposeBag)
        // 本地协同：离线创建同步成功后数据更新
        NotificationCenter.default.rx.notification(Notification.Name.Docs.updateFakeWikiInfo)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] notification in
                guard let self else { return }
                guard let userInfo = notification.userInfo,
                      let fakeToken = userInfo["fakeToken"] as? String,
                      let title = userInfo["title"] as? String else {
                    return
                }
                guard let object = notification.object,
                      let wikiInfo = object as? WikiInfo else {
                    return
                }
                guard let libraryRootToken = WikiStorage.shared.getMylibraryMainRootToken() else {
                    return
                }
                // 删除fake节点
                self.handleSyncDelete(wikiToken: fakeToken)
//                // 根据真实信息创建真实节点，插入
//                let realMeta = WikiTreeNodeMeta(wikiToken: wikiInfo.wikiToken,
//                                                spaceId: wikiInfo.spaceId,
//                                                objToken: wikiInfo.objToken,
//                                                docsType: wikiInfo.docsType,
//                                                title: title)
//                let realNode = WikiServerNode(meta: realMeta, sortID: wikiInfo.sortId ?? Double.greatestFiniteMagnitude, parent: libraryRootToken)
                //self.handleSyncAdd(node: realNode)
            })
            .disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(WikiLocalSync.MovedFromMoreName)
            .observeOn(workQueueScheduler)
            .subscribe(onNext: { [weak self] notification in
                guard let self else { return }
                guard let userInfo = notification.userInfo,
                      let movedMeta = userInfo["movedMeta"] as? WikiMeta,
                      let targetMeta = userInfo["newParentMeta"] as? WikiMeta,
                      let newSortID = userInfo["newSortID"] as? Double,
                      let oldParentToken = userInfo["oldParentToken"] as? String,
                      let synergyUUID = userInfo["synergyUUID"] as? String else {
                    return
                }
                guard let dispatcher = self.dispatherManager[movedMeta.spaceID],
                      dispatcher.synergyUUID == synergyUUID else {
                    return
                }
                DispatchQueue.main.async {
                    if let state = self.syncModel?.treeStateRelay.value,
                       var meta = state.metaStorage[movedMeta.wikiToken] {
                        meta.spaceID = targetMeta.spaceID
                        let node = WikiServerNode(meta: meta, sortID: newSortID, parent: targetMeta.wikiToken)
                        self.handleSyncMove(oldParentToken: oldParentToken, newParentToken: targetMeta.wikiToken, movedToken: movedMeta.wikiToken, movedNode: node, allowSpaceRedirect: true)
                    } else {
                        self.handleSyncMove(oldParentToken: oldParentToken, newParentToken: targetMeta.wikiToken, movedToken: movedMeta.wikiToken, movedNode: nil, allowSpaceRedirect: true)
                    }
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func setupDispathProcessor(syncDispatcher: WikiSyncDispatcher, spaceId: String) {
        syncDispatcher.handleAddSyncV2
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] node in
                self?.handleSyncAdd(node: node)
            })
            .disposed(by: disposeBag)

        syncDispatcher.handleBatchAddSyncV2
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] parentToken, nodes in
                self?.handleSyncBatchAdd(parentWikiToken: parentToken, nodes: nodes)
            })
            .disposed(by: disposeBag)

        syncDispatcher.handleDeleteSyncV2
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] deletedToken in
                self?.handleSyncDelete(wikiToken: deletedToken)
            })
            .disposed(by: disposeBag)

        syncDispatcher.handleNodeTitleUpdateSyncV2
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] updateNode in
                self?.handleSyncTitleUpdata(updateData: updateNode)
            })
            .disposed(by: disposeBag)

        syncDispatcher.handleMoveSyncV2
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] event in
                self?.handleSyncMove(oldParentToken: event.oldParentToken,
                                     newParentToken: event.newParentToken,
                                     movedToken: event.movedToken,
                                     movedNode: event.movedNode,
                                     allowSpaceRedirect: false) // 协同场景不触发 wiki space 跳转
            })
            .disposed(by: disposeBag)

        syncDispatcher.handleBatchMoveSyncV2
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] event in
                self?.handleSyncBatchMove(oldParentToken: event.from,
                                          targetMeta: WikiMeta(wikiToken: event.to, spaceID: event.targetSpaceId),
                                          movedTokens: event.movedTokens,
                                          movedNodes: event.movingNodes,
                                          allowSpaceRedirect: false) // 协同场景不触发 wiki space 跳转
            })
            .disposed(by: disposeBag)

        syncDispatcher.handleNodePermSync
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] targetToken, node in
                self?.handleSyncNodePermissionUpdate(wikiToken: targetToken, node: node)
            })
            .disposed(by: disposeBag)

        syncDispatcher.handleDeleteAndMoveUpSync
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] event in
                self?.handleDeleteAndMoveUp(wikiToken: event.wikiToken,
                                            parentWikiToken: event.parentWikiToken,
                                            spaceID: event.spaceId)
            })
            .disposed(by: disposeBag)

        syncDispatcher.handleDeleteSpaceSync
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] spaceID in
                guard let self = self else { return }
                // 知识库空间删除协同, 判断是否是当前知识库
                guard spaceId == spaceID else { return }
                self.handleSpaceDeletedEvent()
            })
            .disposed(by: disposeBag)
        
        syncDispatcher.handlePinDocumentSync
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                DocsLogger.info("clip document tree need sync")
                NotificationCenter.default.post(name: .Docs.quickAccessUpdate, object: nil)
            })
            .disposed(by: disposeBag)
        
        syncDispatcher.handlePinWikiSpaceSync
            .observeOn(MainScheduler.instance)
            .subscribe(onNext:  {
                DocsLogger.info("clip wiki space need sync")
                NotificationCenter.default.post(name: .Docs.clipWikiSpaceListUpdate, object: nil)
            })
            .disposed(by: disposeBag)
    }
    
    
    // MARK: - 各个协同事件的 UI 层处理逻辑
    // 考虑到每个协同事件的处理逻辑差异比较大，这里直接拆分为若干个处理函数分别处理单个协同事件的逻辑
    // 这里关注 UI 层的逻辑，调用 DataModel 对应的方法更新树结构后，按需调整 UI （如滚动到特定位置、展开特定节点等），最终上屏
    // 数据层的逻辑在 DataModel 中，如请求相关信息、插入数据等
    // Discussion:
    // 部分协同事件需要根据当前的状态做不同的逻辑，又因为 UI 和 Data 处理分离，会有以下问题：
    // UI层，某节点还没有展示出来，但数据层正在展开某节点，此时若根据 UI 层的 snapshot 做逻辑，会与 Data 层不匹配
    
    // 协同新建直接转发给 DataModel
    public func focusNode(wikiToken: String, shouldLoading: Bool) {
        guard let syncModel else {
            spaceAssertionFailure("syncmodel must be implemented")
            return
        }
        // 部分场景已经请求到了数据在 focus，此时不需要 loading
        if shouldLoading {
            syncModel.wikiActionInput.accept(.showLoading)
        }
        syncModel.syncDataModel.focus(wikiToken: wikiToken)
            .subscribe { [weak self] state in
                guard let self = self else { return }
                self.syncModel?.treeStateRelay.accept(state)
                // 固定跳到无 shortcut 路径
                let section = WikiTreeDataProcessor.getNodeSection(wikiToken: wikiToken, treeState: state) ?? .mainRoot
                let nodeUID = WikiTreeNodeUID(wikiToken: wikiToken, section: section, shortcutPath: "")
                self.syncModel?.scrollByUIDInput.accept(nodeUID)
            } onError: { [weak self, weak syncModel] error in
                DocsLogger.error("focus node failed", error: error)
                guard let self = self, let syncModel else { return }
                let wikiError = WikiErrorCode(rawValue: (error as NSError).code) ?? .networkError
                self.syncModel?.wikiActionInput.accept(.showHUD(.failure(wikiError.expandErrorDescription)))
                // 重放一次触发 UI 刷新，重置 loading 状态
                syncModel.treeStateRelay.accept(syncModel.treeStateRelay.value)
            }
            .disposed(by: disposeBag)
    }
    
    public func handleSyncAdd(node: WikiServerNode) {
        guard let syncModel else {
            spaceAssertionFailure("syncmodel must be implemented")
            return
        }
        syncModel.syncDataModel.syncAdd(node: node)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] state in
                DocsLogger.info("handle add sync event success")
                self?.syncModel?.treeStateRelay.accept(state)
            } onError: { error in
                DocsLogger.error("handle add sync event failed", error: error)
            } onCompleted: {
                DocsLogger.info("handle add sync event complete without update")
            }
            .disposed(by: disposeBag)
    }
    
    public func handleSyncBatchAdd(parentWikiToken: String, nodes: [WikiServerNode]) {
        guard let syncModel else {
            spaceAssertionFailure("syncmodel must be implemented")
            return
        }
        syncModel.syncDataModel.syncBatchAdd(parentWikiToken: parentWikiToken, nodes: nodes)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] state in
                DocsLogger.info("handle batch add sync event success")
                self?.syncModel?.treeStateRelay.accept(state)
            } onError: { error in
                DocsLogger.error("handle batch add sync event failed", error: error)
            } onCompleted: {
                DocsLogger.info("handle batch add sync event complete without update")
            }
            .disposed(by: disposeBag)
    }
    
    public func handleSyncDelete(wikiToken: String) {
        guard let syncModel else {
            spaceAssertionFailure("syncmodel must be implemented")
            return
        }
        syncModel.syncDataModel.syncDelete(wikiToken: wikiToken)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] result in
                guard let self = self else { return }
                DocsLogger.info("handle delete sync event success")
                self.syncModel?.treeStateRelay.accept(result.treeState)
                // 协同导致节点被删除处理时，需要关闭当前文档
                if result.selectedTokenDeleted && !wikiToken.isFakeToken {
                    self.syncModel?.onManualDeleteNodeInput.accept(())
                }
            } onError: { error in
                DocsLogger.error("handle delete sync event failed", error: error)
            } onCompleted: {
                DocsLogger.info("handle delete sync event complete without update")
            }
            .disposed(by: disposeBag)
    }
    
    public func handleSyncTitleUpdata(updateData: WikiTreeUpdateData, updateForOrigin: Bool = false) {
        guard let syncModel else {
            spaceAssertionFailure("syncmodel must be implemented")
            return
        }
        syncModel.syncDataModel.syncTitleUpdata(updateData: updateData, updateForOrigin: updateForOrigin)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] state in
                DocsLogger.info("handle title update sync event success")
                self?.syncModel?.treeStateRelay.accept(state)
            } onError: { error in
                DocsLogger.error("handle title update sync event failed", error: error)
            } onCompleted: {
                DocsLogger.info("handle title update sync event complete without update")
            }
            .disposed(by: disposeBag)
    }
    
    public func handleSyncMove(oldParentToken: String,
                               newParentToken: String,
                               movedToken: String,
                               movedNode: WikiServerNode?,
                               allowSpaceRedirect: Bool) {
        guard let syncModel else {
            spaceAssertionFailure("syncmodel must be implemented")
            return
        }
        syncModel.syncDataModel.syncMove(oldParentToken: oldParentToken,
                                         newParentToken: newParentToken,
                                         movedToken: movedToken,
                                         movedNode: movedNode,
                                         allowSpaceRedirect: allowSpaceRedirect)
        .observeOn(MainScheduler.instance)
        .subscribe { [weak self] result in
            guard let self = self else { return }
            DocsLogger.info("handle move sync event success")
            self.syncModel?.treeStateRelay.accept(result.treeState)
            if result.selectedTokenMoved, let selectedToken = result.treeState.viewState.selectedWikiToken {
                self.focusNode(wikiToken: selectedToken, shouldLoading: false)
            }
            // 移动导致节点被删除处理时，需要关闭当前文档
            if result.selectedTokenDeleted {
                self.syncModel?.onManualDeleteNodeInput.accept(())
            }
        } onError: { error in
            DocsLogger.error("handle move sync event failed", error: error)
        } onCompleted: {
            DocsLogger.info("handle move sync event complete without update")
        }
        .disposed(by: disposeBag)
    }
    
    public func handleSyncBatchMove(oldParentToken: String,
                                    targetMeta: WikiMeta,
                                    movedTokens: [String],
                                    movedNodes: [String: WikiServerNode],
                                    allowSpaceRedirect: Bool) {
        guard let syncModel else {
            spaceAssertionFailure("syncmodel must be implemented")
            return
        }
        syncModel.syncDataModel.syncBatchMove(oldParentToken: oldParentToken,
                                              targetMeta: targetMeta,
                                              movedTokens: movedTokens,
                                              movedNodes: movedNodes,
                                              allowSpaceRedirect: allowSpaceRedirect)
        .observeOn(MainScheduler.instance)
        .subscribe { [weak self] result in
            guard let self = self else { return }
            DocsLogger.info("handle batch move sync event success")
            self.syncModel?.treeStateRelay.accept(result.treeState)
            if result.selectedTokenMoved, let selectedToken = result.treeState.viewState.selectedWikiToken {
                self.focusNode(wikiToken: selectedToken, shouldLoading: false)
            }
            // 移动导致节点被删除处理时，需要关闭当前文档
            if result.selectedTokenDeleted {
                self.syncModel?.onManualDeleteNodeInput.accept(())
            }
        } onError: { error in
            DocsLogger.error("handle batch move sync event failed", error: error)
        } onCompleted: {
            DocsLogger.info("handle batch move sync event complete without update")
        }
        .disposed(by: disposeBag)
    }
    
    public func handleSyncNodePermissionUpdate(wikiToken: String, node: WikiServerNode?) {
        guard let syncModel else {
            spaceAssertionFailure("syncmodel must be implemented")
            return
        }
        syncModel.syncDataModel.syncNodePermissionUpdate(wikiToken: wikiToken, node: node)
            .map { ($0.treeState, $0.selectedTokenMoved) } // 协同场景不关心选中节点是否被删除
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] state, selectedMoved in
                guard let self = self else { return }
                DocsLogger.info("handle node permission update sync event success")
                self.syncModel?.treeStateRelay.accept(state)
            } onError: { error in
                DocsLogger.error("handle node permission sync event failed", error: error)
            } onCompleted: {
                DocsLogger.info("handle node permission sync event complete without update")
            }
            .disposed(by: disposeBag)
    }
    
    public func handleSyncToggleStar(wikiToken: String, isStar: Bool) {
        guard let syncModel else {
            spaceAssertionFailure("syncmodel must be implemented")
            return
        }
        syncModel.syncDataModel.syncToggleStar(wikiToken: wikiToken, isStar: isStar)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] state in
                DocsLogger.info("handle toggle wiki star sync event success")
                self?.syncModel?.treeStateRelay.accept(state)
            } onError: { error in
                DocsLogger.error("handle toggle wiki star sync event failed", error: error)
            } onCompleted: {
                DocsLogger.info("handle toggle wiki star sync event complete without update")
            }
            .disposed(by: disposeBag)
    }
    
    public func handleSyncToggleExplorerStar(wikiToken: String, isStar: Bool) {
        guard let syncModel else {
            spaceAssertionFailure("syncmodel must be implemented")
            return
        }
        syncModel.syncDataModel.syncToggleExplorerStar(wikiToken: wikiToken, isStar: isStar)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] state in
                DocsLogger.info("handle toggle explorer star sync event success")
                self?.syncModel?.treeStateRelay.accept(state)
            } onError: { error in
                DocsLogger.error("handle toggle explorer star sync event failed", error: error)
            } onCompleted: {
                DocsLogger.info("handle toggle explorer star sync event complete without update")
            }
            .disposed(by: disposeBag)
    }
    
    func handleSyncToggleExplorerStarForExternalShortcut(objToken: String, isStar: Bool) {
        guard let syncModel else {
            spaceAssertionFailure("syncmodel must be implemented")
            return
        }
        syncModel.syncDataModel.syncToggleExplorerStarForExternalShortcut(objToken: objToken, isStar: isStar)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] state in
                DocsLogger.info("handle toggle explorer star for external shortcut sync event success")
                self?.syncModel?.treeStateRelay.accept(state)
            } onError: { error in
                DocsLogger.error("handle toggle explorer star for external shortcut sync event failed", error: error)
            } onCompleted: {
                DocsLogger.info("handle toggle explorer star for external shortcut sync event complete without update")
            }
            .disposed(by: disposeBag)
    }
    
    public func handleSyncToggleExplorerPin(wikiToken: String, isPin: Bool) {
        guard let syncModel else {
            spaceAssertionFailure("syncmodel must be implemented")
            return
        }
        syncModel.syncDataModel.syncToggleExplorerPin(wikiToken: wikiToken, isPin: isPin)
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] state in
                DocsLogger.info("handle toggle explorer pin sync event success")
                self?.syncModel?.treeStateRelay.accept(state)
            }, onError: { error in
                DocsLogger.error("handle toggle explorer pin sync event failed", error: error)
            }, onCompleted: {
                DocsLogger.info("handle toggle explorer pin sync event complete without update")
            })
            .disposed(by: disposeBag)
    }
    
    func handleSyncToggleExplorerPinForExternalShorcut(objToken: String, isPin: Bool) {
        guard let syncModel else {
            spaceAssertionFailure("syncmodel must be implemented")
            return
        }
        syncModel.syncDataModel.syncToggleExplorerPinForExternalShortcut(objToken: objToken, isPin: isPin)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] state in
                DocsLogger.info("handle toggle explorer pin for external shortcut event success")
                self?.syncModel?.treeStateRelay.accept(state)
            } onError: { error in
                DocsLogger.error("handle toggle explorer pin for external shortcut event failed", error: error)
            } onCompleted: {
                DocsLogger.info("handle toggle explorer pin for external shortcut sync event complete without update")
            }
            .disposed(by: disposeBag)
    }
    
    public func handleDeleteAndMoveUp(wikiToken: String,
                                      parentWikiToken: String,
                                      spaceID: String) {
        guard let syncModel else {
            spaceAssertionFailure("syncmodel must be implemented")
            return
        }
        syncModel.syncDataModel.syncDeleteAndMoveUp(wikiToken: wikiToken, parentToken: parentWikiToken, spaceID: spaceID)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] result in
                guard let self = self else { return }
                DocsLogger.info("handle delete and move up sync event success")
                self.syncModel?.treeStateRelay.accept(result.treeState)
                if result.selectedTokenDeleted {
                    // 移除场景，协同时也需要退出当前文档
                    self.syncModel?.onManualDeleteNodeInput.accept(())
                }
            } onError: { error in
                DocsLogger.error("handle delete and move up sync event failed", error: error)
            } onCompleted: {
                DocsLogger.info("handle delete and move up sync event complete without update")
            }
            .disposed(by: disposeBag)
    }
    
    public func handleSpaceDeletedEvent() {
        // TODO: 优化下错误 view 的实现，考虑把 error type 丢出去
        let failTipsView = WikiFaildView()
        failTipsView.showFail(error: .spaceDeleted)
        failTipsView.isHidden = false
        syncModel?.wikiActionInput.accept(.showErrorPage(failTipsView))
    }
}
