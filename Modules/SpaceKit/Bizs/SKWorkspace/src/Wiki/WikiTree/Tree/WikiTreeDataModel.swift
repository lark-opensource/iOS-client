//
//  WikiTreeDataModel.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2022/7/14.
//
// swiftlint:disable file_length

import Foundation
import SKFoundation
import SKCommon
import RxSwift
import RxRelay
import RxCocoa

open class WikiTreeDataModel: WikiTreeDataModelType {
    let disposeBag = DisposeBag()


    private let spaceIDRelay: BehaviorRelay<String>
    public var spaceIDUpdated: Driver<String> { spaceIDRelay.asDriver() }
    public var spaceID: String { spaceIDRelay.value }
    public var treeSpaceIds: [String] { [spaceID] }

    // 用于初始化时定位到的 wiki token
    private let initialWikiTokenRelay: BehaviorRelay<String?>
    public var initialWikiToken: String? { initialWikiTokenRelay.value }
    // 以下属性的写操作限制在 dataQueue 中执行
    // 为了给 extension 用所以没有加 private，但是禁止外部使用
    var viewState: WikiTreeViewState
    var relation: WikiTreeRelation
    var metaStorage: [String: WikiTreeNodeMeta]
    public var treeState: WikiTreeState {
        get {
            WikiTreeState(viewState: viewState,
                          metaStorage: metaStorage,
                          relation: relation)
        }
        set {
            // 批量更新的快捷方法
            viewState = newValue.viewState
            relation = newValue.relation
            metaStorage = newValue.metaStorage
        }
    }

    // 初始化状态和异常信息
    public let initialStateRelay = BehaviorRelay(value: InitialState())
    public var initialStateUpdated: Driver<InitialState> { initialStateRelay.asDriver() }
    // space 信息
    private let spaceInfoRelay = BehaviorRelay<WikiSpace?>(value: nil)
    public var spaceInfoUpdated: Driver<WikiSpace?> { spaceInfoRelay.asDriver() }
    // space 用户权限信息
    private let userSpacePermissionRelay = BehaviorRelay<WikiUserSpacePermission>(value: .default)
    public var userSpacePermissionUpdated: Driver<WikiUserSpacePermission> { userSpacePermissionRelay.asDriver() }

    private let dataQueue = DispatchQueue(label: "wiki.tree.dataQueue")
    private(set) lazy var dataQueueScheduler = SerialDispatchQueueScheduler(queue: dataQueue,
                                                                            internalSerialQueueName: "com.wiki.dataQueueScheduler")
    // 一些依赖使用业务方的通用配置
    private(set) var config: WikiTreeDataModelConfig

    let networkAPI: WikiTreeNetworkAPI
    let cacheAPI: WikiTreeCacheAPI
    let processor: WikiTreeDataProcessorType
    let scene: WikiMainTreeScene

    public convenience init(spaceID: String,
                            initialWikiToken: String?,
                            scene: WikiMainTreeScene = .spacePage,
                            networkAPI: WikiTreeNetworkAPI,
                            cacheAPI: WikiTreeCacheAPI,
                            processor: WikiTreeDataProcessorType,
                            config: WikiTreeDataModelConfig = .default) {
        self.init(spaceID: spaceID,
                  initialWikiToken: initialWikiToken,
                  scene: scene,
                  treeContext: nil,
                  networkAPI: networkAPI,
                  cacheAPI: cacheAPI,
                  processor: processor,
                  config: config)
    }

    public init(spaceID: String,
                initialWikiToken: String?,
                scene: WikiMainTreeScene = .spacePage,
                treeContext: WikiTreeContext?,
                networkAPI: WikiTreeNetworkAPI,
                cacheAPI: WikiTreeCacheAPI,
                processor: WikiTreeDataProcessorType,
                config: WikiTreeDataModelConfig = .default) {
        let treeState = treeContext?.treeState ?? .empty
        self.spaceIDRelay = BehaviorRelay(value: spaceID)
        self.initialWikiTokenRelay = BehaviorRelay(value: initialWikiToken)
        self.scene = scene
        self.viewState = treeState.viewState
        self.relation = treeState.relation
        self.metaStorage = treeState.metaStorage
        self.networkAPI = networkAPI
        self.cacheAPI = cacheAPI
        self.processor = processor
        self.config = config

        if !treeState.isEmpty {
            // 带数据初始化时，标记 DB 和 server 为加载完成状态
            let state = InitialState(cacheState: .success(()), serverState: .success(()))
            initialStateRelay.accept(state)
        }

        if let treeContext = treeContext {
            spaceInfoRelay.accept(treeContext.spaceInfo)
            userSpacePermissionRelay.accept(treeContext.userSpacePermission ?? .default)
        }
    }

    // 跨库移动后，需要重置 spaceID 和 initialWikiToken，并重新加载一次
    func reset(spaceID: String, initialWikiToken: String?) -> Single<WikiTreeState> {
        Single.create { [weak self] single in
            guard let self = self else {
                single(.error(DataError.modelReferenceError))
                return Disposables.create()
            }
            return self.networkAPI.loadTree(spaceID: spaceID, initialWikiToken: initialWikiToken, needPermission: true)
                .observeOn(self.dataQueueScheduler)
                .map { [weak self] treeData in
                    guard let self = self else {
                        throw DataError.modelReferenceError
                    }
                    // 由于是跨库移动，这里直接 reset，丢弃已有的所有数据
                    self.treeState = try self.processor.process(operation: .reset(relation: treeData.relation,
                                                                                  metaStorage: treeData.metaStorage),
                                                                treeState: .empty) // 这里丢弃原有的 viewState
                    if let token = initialWikiToken {
                        self.treeState = try self.processor.process(operation: .expandTo(wikiToken: token),
                                                                    treeState: self.treeState)
                        self.viewState.select(wikiToken: token)
                        let section = WikiTreeDataProcessor.getNodeSection(wikiToken: token, treeState: self.treeState)
                        let nodeUID = WikiTreeNodeUID(wikiToken: token,
                                                      section: section ?? .mainRoot,
                                                      shortcutPath: "")
                        self.viewState.select(nodeUID: nodeUID)
                    }
                    self.spaceInfoRelay.accept(treeData.spaceInfo)
                    if let permission = treeData.userSpacePermission {
                        self.userSpacePermissionRelay.accept(permission)
                    }
                    self.cacheAPI.batchUpdate(metas: Array(treeData.metaStorage.values),
                                              relation: treeData.relation)
                    .subscribe().disposed(by: self.disposeBag)
                    self.spaceIDRelay.accept(spaceID)
                    self.initialWikiTokenRelay.accept(initialWikiToken)
                    return self.treeState
                }
                .subscribe(single)
        }
        .subscribeOn(dataQueueScheduler)
    }

    public func reset(context: WikiTreeContext) -> Single<WikiTreeState> {
        Single.create { [weak self] single in
            guard let self = self else {
                single(.error(DataError.modelReferenceError))
                return Disposables.create()
            }
            self.spaceIDRelay.accept(context.spaceID)
            self.treeState = context.treeState
            self.spaceInfoRelay.accept(context.spaceInfo)
            self.userSpacePermissionRelay.accept(context.userSpacePermission ?? .default)
            single(.success(self.treeState))
            return Disposables.create()
        }
        .subscribeOn(dataQueueScheduler)
    }

    // resume from DB, 会完全覆盖本地状态
    open func restore() -> Maybe<WikiTreeState> {
        // 包装一层是因为内部存在两个事件，为了不产生副作用，将两个事件都包装在订阅时发生
        Maybe.create { [weak self] maybe in
            guard let self = self else {
                maybe(.error(DataError.modelReferenceError))
                return Disposables.create()
            }

            self.cacheAPI.loadSpaceInfo(spaceID: self.spaceID)
                .subscribe(onSuccess: { [weak self] spaceInfo in
                    self?.spaceInfoRelay.accept(spaceInfo)
                })
                .disposed(by: self.disposeBag)

            return self.cacheAPI.loadTree(spaceID: self.spaceID, initialWikiToken: self.initialWikiToken)
                .observeOn(self.dataQueueScheduler)
                .do(onNext: { [weak self] (relation, storage) in
                    guard let self = self else { return }
                    self.treeState = try self.processor.process(operation: .update(relation: relation,
                                                                               metaStorage: storage,
                                                                               onConflict: .ignore),
                                                            treeState: self.treeState)
                    if let token = self.initialWikiToken {
                        self.treeState = try self.processor.process(operation: .expandTo(wikiToken: token),
                                                                    treeState: self.treeState)
                        // 非目录树打开需要定位完展开自身
                        if let childMap = self.relation.nodeChildrenMap[token],
                           !childMap.isEmpty,
                           let section = WikiTreeDataProcessor.getNodeSection(wikiToken: token, treeState: self.treeState) {
                            let nodeUID = WikiTreeNodeUID(wikiToken: token, section: section, shortcutPath: "")
                            self.viewState.expand(nodeUID: nodeUID)
                        }
                    } else if let mainRootToken = storage.first(where: { $1.nodeType == .mainRoot })?.key {
                        let mainRootUID = WikiTreeNodeUID(wikiToken: mainRootToken,
                                                          section: .mainRoot,
                                                          shortcutPath: "")
                        self.viewState.expand(nodeUID: mainRootUID)
                    } else {
                        DocsLogger.error("restore cache but not root token found")
                    }
                    var modelState = self.initialStateRelay.value
                    modelState.cacheState = .success(())
                    self.initialStateRelay.accept(modelState)
                }, onError: { [weak self] error in
                    // 通常不存在失败
                    DocsLogger.error("load tree from DB failed", error: error)
                    guard let self = self else { return }
                    var modelState = self.initialStateRelay.value
                    modelState.cacheState = .failure(error)
                    self.initialStateRelay.accept(modelState)
                })
                    .map { [weak self] _ in
                        guard let self = self else {
                            throw DataError.modelReferenceError
                        }
                        return self.treeState
                    }
                    .subscribe(maybe)
        }
    }

    public func restoreFavoriteList() -> Maybe<WikiTreeState> {
        cacheAPI.loadFavoriteList(spaceID: spaceID)
            .observeOn(dataQueueScheduler)
            .do(onNext: { [weak self] (children, metaStorage) in
                guard let self = self else { return }
                let relation = WikiTreeRelation(nodeParentMap: [:], nodeChildrenMap: [
                    WikiTreeNodeMeta.favoriteRootToken: children
                ])
                do {
                    let newState = try self.processor.process(operation: .updateFavoriteList(spaceID: self.spaceID,
                                                                                             relation: relation,
                                                                                             metaStorage: metaStorage,
                                                                                             onConflict: .ignore),
                                                              treeState: self.treeState)
                    self.treeState = newState
                } catch {
                    DocsLogger.error("un-handle update error", error: error)
                    spaceAssertionFailure()
                }
            }, onError: { error in
                DocsLogger.error("restore favorite list failed", error: error)
            })
                .map { [weak self] _ -> WikiTreeState in
                    guard let self = self else {
                        throw DataError.modelReferenceError
                    }
                    return self.treeState
                }
    }

    public func makeFavoriteRoot() -> Single<WikiTreeState> {
        Single.create { [weak self] single in
            guard let self = self else {
                single(.error(DataError.modelReferenceError))
                return Disposables.create()
            }
            // 将收藏根节点插入树中
            let metas = [
                WikiTreeNodeMeta.favoriteRootToken: WikiTreeNodeMeta.createFavoriteRoot(spaceID: self.spaceID)
            ]
            do {
                let newState = try self.processor.process(operation: .updateFavoriteList(spaceID: self.spaceID,
                                                                                         relation: WikiTreeRelation(),
                                                                                         metaStorage: metas,
                                                                                         onConflict: .ignore),
                                                          treeState: self.treeState)
                self.treeState = newState
            } catch {
                DocsLogger.error("un-handle update error", error: error)
                spaceAssertionFailure()
            }
            single(.success(self.treeState))
            return Disposables.create()
        }
        .subscribeOn(dataQueueScheduler)
    }

    // 重新加载目录树, 注意只会触发网络请求，不会触发 load cache
    open func reload() -> Single<(WikiTreeState, Bool)> {
        networkAPI.loadTree(spaceID: spaceID, initialWikiToken: initialWikiToken, needPermission: true)
            .observeOn(dataQueueScheduler)
            .do(onSuccess: { [weak self] treeData in
                guard let self = self else { return }
                let cacheLoaded: Bool
                if let cacheState = self.initialStateRelay.value.cacheState,
                   case .success = cacheState {
                    cacheLoaded = true
                } else {
                    cacheLoaded = false
                }
                do {
                    if let token = self.initialWikiToken, cacheLoaded {
                        // 带 token 请求目录树的情况下，覆盖缓存有特别的冲突要处理
                        self.treeState = try self.processor.process(operation: .cleanDivergePath(wikiToken: token,
                                                                                                 newRelation: treeData.relation),
                                                                    treeState: self.treeState)
                    }
                    self.treeState = try self.processor.process(operation: .update(relation: treeData.relation,
                                                                                   metaStorage: treeData.metaStorage,
                                                                                   onConflict: .override),
                                                                treeState: self.treeState)

                    if let token = self.initialWikiToken {
                        self.treeState = try self.processor.process(operation: .expandTo(wikiToken: token),
                                                                    treeState: self.treeState)
                        // 非目录树打开需要定位完展开自身
                        if !cacheLoaded,
                           let childMap = self.relation.nodeChildrenMap[token],
                           !childMap.isEmpty,
                           let section = WikiTreeDataProcessor.getNodeSection(wikiToken: token, treeState: self.treeState) {
                            let nodeUID = WikiTreeNodeUID(wikiToken: token, section: section, shortcutPath: "")
                            self.viewState.expand(nodeUID: nodeUID)
                        }
                    } else if let mainRootToken = treeData.metaStorage.first(where: { $1.nodeType == .mainRoot })?.key {
                        // 有 cache 就不再特意展开子节点了
                        if !cacheLoaded {
                            let rootUID = WikiTreeNodeUID(wikiToken: mainRootToken, section: .mainRoot, shortcutPath: "")
                            self.viewState.expand(nodeUID: rootUID)
                        }
                    } else {
                        DocsLogger.error("restore cache but not root token found")
                    }
                } catch {
                    DocsLogger.error("unexpected error found", error: error)
                    spaceAssertionFailure()
                }
                self.spaceInfoRelay.accept(treeData.spaceInfo)
                if let userSpacePermission = treeData.userSpacePermission {
                    self.userSpacePermissionRelay.accept(userSpacePermission)
                }
                var modelState = self.initialStateRelay.value
                modelState.serverState = .success(())
                self.initialStateRelay.accept(modelState)
                // 存一份到 DB
                self.cacheAPI.batchUpdate(metas: Array(treeData.metaStorage.values),
                                          relation: treeData.relation)
                .subscribe().disposed(by: self.disposeBag)
                self.cacheAPI.updateSpaceInfoIfNeed(spaceInfo: treeData.spaceInfo)
                    .subscribe().disposed(by: self.disposeBag)
            }, onError: { [weak self] error in
                DocsLogger.info("load tree from server failed", error: error)
                guard let self = self else { return }
                var modelState = self.initialStateRelay.value
                modelState.serverState = .failure(error)
                self.initialStateRelay.accept(modelState)
            })
                .map { [weak self] _ in
                    guard let self = self else {
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

    public func reloadFavoriteList() -> Single<WikiTreeState> {
        networkAPI.loadFavoriteList(spaceID: spaceID)
            .observeOn(dataQueueScheduler)
            .do(onSuccess: { [weak self] (relation, metas) in
                guard let self = self else { return }
                var metaMap: MetaStorage = [:]
                metas.forEach { metaMap[$0.wikiToken] = $0 }
                do {
                    self.treeState = try self.processor.process(operation: .updateFavoriteList(spaceID: self.spaceID,
                                                                                               relation: relation,
                                                                                               metaStorage: metaMap,
                                                                                               onConflict: .override),
                                                                treeState: self.treeState)
                } catch {
                    DocsLogger.error("unknown update error", error: error)
                    spaceAssertionFailure()
                }
                // 保存到 DB
                self.cacheAPI.updateFavoriteList(spaceID: self.spaceID,
                                                 metaStorage: metaMap,
                                                 relation: relation)
                .subscribe().disposed(by: self.disposeBag)
            }, onError: { error in
                DocsLogger.error("reload favorite list failed", error: error)
            })
                .map { [weak self] _ in
                    guard let self = self else {
                        throw DataError.modelReferenceError
                    }
                    return self.treeState
                }
    }
}

extension WikiTreeDataModel {
    func loadChildren(wikiToken: String, spaceID: String) -> Single<WikiTreeState> {
        networkAPI.loadChildren(spaceID: spaceID, wikiToken: wikiToken)
            .observeOn(dataQueueScheduler)
            .map { [weak self] (children, metas) -> WikiTreeState in
                guard let self = self else {
                    throw DataError.modelReferenceError
                }
                var metaStorage: MetaStorage = [:]
                metas.forEach { metaStorage[$0.wikiToken] = $0 }
                var parentMap: [String: String] = [:]
                children.forEach { parentMap[$0.wikiToken] = wikiToken }

                let relation = WikiTreeRelation(nodeParentMap: parentMap, nodeChildrenMap: [wikiToken: children])
                self.treeState = try self.processor.process(operation: .update(relation: relation,
                                                                               metaStorage: metaStorage,
                                                                               onConflict: .override),
                                                            treeState: self.treeState)
                var metasToSave = metas
                if let currentNode = self.metaStorage[wikiToken] {
                    metasToSave.append(currentNode)
                }
                self.cacheAPI.batchUpdate(metas: metasToSave, relation: self.relation)
                    .subscribe().disposed(by: self.disposeBag)
                return self.treeState
            }
    }
    // 返回 treeState 和 isFromCache 字段
    public func expand(wikiToken: String, spaceID: String, nodeUID: WikiTreeNodeUID) -> Observable<(WikiTreeState, Bool)> {
        var expanded = false
        let cache = cacheAPI.loadChildren(spaceID: spaceID, wikiToken: wikiToken)
            .observeOn(dataQueueScheduler)
            .map { [weak self] (children, metas) -> (WikiTreeState, Bool) in
                guard let self = self else {
                    throw DataError.modelReferenceError
                }
                var parentMap: [String: String] = [:]
                children.forEach { parentMap[$0.wikiToken] = wikiToken }
                let relation = WikiTreeRelation(nodeParentMap: parentMap, nodeChildrenMap: [wikiToken: children])
                let newState = try self.processor.process(operation: .update(relation: relation,
                                                                             metaStorage: metas,
                                                                             onConflict: .ignore),
                                                          treeState: self.treeState)
                self.treeState = newState
                self.viewState.expand(nodeUID: nodeUID)
                expanded = true
                return (self.treeState, true)
            }
            .asObservable()
            // 如果 cache 失败了，不应该影响 network 继续执行, 这里把 error 包装为 empty
            .catchError { error in
                DocsLogger.error("load children from cache when expand node failed", error: error)
                return .empty()
            }

        let network = loadChildren(wikiToken: wikiToken, spaceID: spaceID)
            .map { [weak self] _ -> (WikiTreeState, Bool) in
                guard let self = self else {
                    throw DataError.modelReferenceError
                }
                if !expanded {
                    self.viewState.expand(nodeUID: nodeUID)
                }
                return (self.treeState, false)
            }

        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(DataError.modelReferenceError)
                return Disposables.create()
            }
            if self.relation.nodeChildrenMap[wikiToken] != nil {
                // 内存有数据，不用拉 cache、server
                self.viewState.expand(nodeUID: nodeUID)
                observer.onNext((self.treeState, true))
                observer.onCompleted()
                return Disposables.create()
            }
            return cache.concat(network)
                .subscribe(observer)
        }
        .subscribeOn(dataQueueScheduler)
    }

    // 强制展开某节点，仅在特定场景下使用，如在某节点下完成新建并拉取到了子节点数据时
    public func expand(nodeUID: WikiTreeNodeUID) -> Single<WikiTreeState> {
        Single.create { [weak self] single in
            guard let self = self else {
                single(.error(DataError.modelReferenceError))
                return Disposables.create()
            }
            self.dataQueue.async {
                self.viewState.expand(nodeUID: nodeUID)
                single(.success(self.treeState))
            }
            return Disposables.create()
        }
    }

    public func collapse(nodeUID: WikiTreeNodeUID) -> Single<WikiTreeState> {
        Single.create { [weak self] single in
            guard let self = self else {
                single(.error(DataError.modelReferenceError))
                return Disposables.create()
            }
            self.dataQueue.async {
                self.viewState.collapse(nodeUID: nodeUID)
                single(.success(self.treeState))
            }
            return Disposables.create()
        }
    }

    public func select(wikiToken: String, nodeUID: WikiTreeNodeUID?) -> Single<WikiTreeState> {
        Single.create { [weak self] single in
            guard let self = self else {
                single(.error(DataError.modelReferenceError))
                return Disposables.create()
            }
            self.dataQueue.async {
                self.viewState.select(wikiToken: wikiToken)
                self.viewState.select(nodeUID: nodeUID)
                single(.success(self.treeState))
            }
            return Disposables.create()
        }
    }

    /// 展开到并选中目标节点，分两种情况
    /// 1. 目标节点已经在内存中，且 paths 包含根节点，paths 经过的节点都在内存中，会直接定位到目标，不会发请求
    /// 2. 目标不在内存中，或找不到一条通往 mainRoot 的 paths，会重新请求并合并数据
    public func focus(wikiToken: String) -> Single<WikiTreeState> {
        Single.create { [weak self] single in
            guard let self = self else {
                single(.error(DataError.modelReferenceError))
                return Disposables.create()
            }
            if let targetMeta = self.metaStorage[wikiToken] {
                if targetMeta.nodeType.isMainRootType {
                    // 目标是 mainRoot， 且 mainRoot 在内存，直接返回
                    return self.select(wikiToken: wikiToken, nodeUID: nil).subscribe(single)
                }

                let paths = self.relation.getPath(wikiToken: wikiToken)
                if let pathRoot = paths.first, // paths 有根节点
                   let pathRootMeta = self.metaStorage[pathRoot], // paths 顶层节点存在
                   pathRootMeta.nodeType.isMainRootType, // paths 顶层节点是 mainRoot
                   paths.allSatisfy({ self.metaStorage[$0] != nil }) { // 所有 paths 经过的节点都存在
                    // 节点在内存中，直接定位
                    do {
                        self.treeState = try self.processor.process(operation: .expandTo(wikiToken: wikiToken),
                                                                    treeState: self.treeState)
                        // 选中目标
                        self.viewState.select(wikiToken: wikiToken)
                        let section = WikiTreeDataProcessor.getNodeSection(wikiToken: wikiToken, treeState: self.treeState)
                        self.viewState.select(nodeUID: WikiTreeNodeUID(wikiToken: wikiToken,
                                                                       section: section ?? .mainRoot,
                                                                       shortcutPath: ""))
                    } catch {
                        DocsLogger.error("unexpected error when expand to node", error: error)
                        spaceAssertionFailure()
                    }
                    single(.success(self.treeState))
                    return Disposables.create()
                }
            }
            // 2. 发请求
            let targetSpaceID = self.metaStorage[wikiToken]?.spaceID ?? self.spaceID
            if targetSpaceID == WikiTreeNodeMeta.mutilTreeSpaceID {
                spaceAssertionFailure("wiki multi tree should not focus node not in metaStorage")
                single(.error(DataError.modelReferenceError))
                return Disposables.create()
            }
            return self.networkAPI.loadTree(spaceID: targetSpaceID, initialWikiToken: wikiToken, needPermission: false)
                .observeOn(self.dataQueueScheduler)
                .do(onSuccess: { [weak self] data in
                    guard let self = self else { return }
                    do {
                        var newState = try self.processor.process(operation: .cleanDivergePath(wikiToken: wikiToken,
                                                                                               newRelation: data.relation),
                                                                  treeState: self.treeState)
                        newState = try self.processor.process(operation: .update(relation: data.relation,
                                                                                 metaStorage: data.metaStorage,
                                                                                 onConflict: .override),
                                                              treeState: newState)
                        newState = try self.processor.process(operation: .expandTo(wikiToken: wikiToken), treeState: newState)
                        self.treeState = newState
                        self.viewState.select(wikiToken: wikiToken)
                        let section = WikiTreeDataProcessor.getNodeSection(wikiToken: wikiToken, treeState: newState)
                        self.viewState.select(nodeUID: WikiTreeNodeUID(wikiToken: wikiToken,
                                                                       section: section ?? .mainRoot,
                                                                       shortcutPath: ""))
                    } catch {
                        DocsLogger.error("unexpected error found when load to expand node", error: error)
                    }
                })
                    .map { [weak self] _ in
                        guard let self = self else {
                            throw DataError.modelReferenceError
                        }
                        return self.treeState
                    }
                    .subscribe(single)
        }
        .subscribeOn(dataQueueScheduler)
    }
}
