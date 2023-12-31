//
//  WikiMainTreeViewModel.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2022/7/27.
//
// swiftlint:disable file_length

import Foundation
import RxSwift
import RxRelay
import RxCocoa
import SKFoundation
import SKCommon
import SKUIKit
import UniverseDesignColor
import UniverseDesignIcon
import LarkContainer

public enum ServerDataState {
    case loading
    case synced
    case fetchFailed(error: Error)

    public var isReady: Bool {
        switch self {
        case .loading:
            return false
        case .synced:
            return true
        case .fetchFailed:
            return false
        }
    }
}

public typealias DidSelectFileAction = () -> Void
// ViewModel 的方法、属性要保证在主线程可安全使用
public class WikiMainTreeViewModel {
    // viewModel 持有一份 treeState 用于业务判断，但不会直接修改 treeState
    public let treeStateRelay = BehaviorRelay<WikiTreeState>(value: .empty)
    public let reachabilityRelay = BehaviorRelay<Bool>(value: true)
    private(set) var dataState: ServerDataState = .loading

    // space 信息
    private let spaceInfoRelay = BehaviorRelay<WikiSpace?>(value: nil)
    public var spaceInfo: WikiSpace? { spaceInfoRelay.value }
    // space 用户权限信息
    private let userSpacePermissionRelay = BehaviorRelay<WikiUserSpacePermission>(value: .default)
    public var userSpacePermission: WikiUserSpacePermission { userSpacePermissionRelay.value }

    private let workQueue = DispatchQueue(label: "wiki.main.tree.vm")
    private lazy var workQueueScheduler = SerialDispatchQueueScheduler(queue: workQueue,
                                                                       internalSerialQueueName: "wiki.main.tree.scheduler.vm")
    let disposeBag = DisposeBag()

    public let scene: WikiMainTreeScene
    public let dataModel: WikiMainTreeDataModelType
    private let converterProvider: WikiMainTreeConverterProviderType
    public let moreProvider: WikiTreeMoreProvider
    public let interactionHandler: WikiInteractionHandler
    let syncDispatcher: WikiSyncDispatcher
    // more面板操作目录树协同
    lazy var moreActionSyncDispatcher: TreeMoreActionSyncDispatcher = {
        TreeMoreActionSyncDispatcher(userResolver: userResolver, syncModel: self)
    }()
    lazy var treeSyncDispatchHandler: TreeSyncDispatchHandler = {
        TreeSyncDispatchHandler(userResolver: userResolver, syncModel: self)
    }()

    let synergyUUID: String

    // MARK: - input
    public let scrollByUIDInput = PublishRelay<WikiTreeNodeUID>()
    let onSwipeCellInput = PublishRelay<(IndexPath, TreeNode)>()

    let reloadInput = PublishRelay<Void>()
    // 创建一级节点事件
    public let createRootNodeInput = PublishRelay<UIView>()
    // 实现根据 wikiToken 定位
    public let focusByWikiTokenInput = PublishRelay<String>()
    // 根据 WikiTreeState 和 nodeUID 同步滚动
    public let syncWithContextInput = PublishRelay<WikiTreeContext>()

    // MARK: - output
    // 参数为: 父节点 wikiToken，是否是图片，callback
    public let onUploadInput = PublishRelay<(String, Bool, DidSelectFileAction)>()
    public var onUploadSignal: Signal<(String, Bool, DidSelectFileAction)> { onUploadInput.asSignal() }

    public let onClickNodeInput = PublishRelay<(WikiTreeNodeMeta, WikiTreeContext)>()
    /// 向外传递点击事件，参数为点击的节点 nodeMeta、nodeUID、和当下的目录树快照
    /// 配合 syncWithTreeStateInput 同步给其他目录树
    public var onClickNodeSignal: Signal<(WikiTreeNodeMeta, WikiTreeContext)> { onClickNodeInput.asSignal() }

    // 手动删除节点时需要上报
    public let onManualDeleteNodeInput = PublishRelay<Void>()
    /// 当存在节点被手动删除（目前仅除外协同场景）时，通知上游，参数为被删除的 wikiToken，删除的节点是否当前被选中
    /// 仅用于详情页场景删除自身的场景，此时上游会关闭当前页面
    public var onManualDeleteNodeSignal: Signal<Void> { onManualDeleteNodeInput.asSignal() }

    public let actionInput = PublishRelay<WikiTreeViewAction>()
    public var actionSignal: Signal<WikiTreeViewAction> { actionInput.asSignal() }

    private let sectionsRelay = BehaviorRelay<[NodeSection]>(value: [])
    public var sectionsDriver: Driver<[NodeSection]> { sectionsRelay.asDriver() }

    public var reloadSuccessDriver: Driver<Void> {
        dataModel.initialStateUpdated.compactMap { state -> Void? in
            guard case .success = state.serverState else {
                return nil
            }
            return ()
        }
    }
    public var reloadFailedDriver: Driver<Error> {
        dataModel.initialStateUpdated.compactMap { state in
            guard case let .failure(error) = state.serverState else {
                return nil
            }
            return error
        }
    }

    var selectedWikiToken: String? { treeStateRelay.value.viewState.selectedWikiToken }
    var selectedNodeMeta: WikiTreeNodeMeta? {
        guard let token = selectedWikiToken else { return nil }
        let storage = treeStateRelay.value.metaStorage
        return storage[token]
    }
    public var selectedNodeUID: WikiTreeNodeUID? { treeStateRelay.value.viewState.latestSelectedNodeUID }

    let initialNodeUID: WikiTreeNodeUID?
    private let networkAPI: WikiTreeNetworkAPI
    private var hasBeenSetup = false
    
    let userResolver: UserResolver

    public convenience init(userResolver: UserResolver,
                            spaceID: String,
                            wikiToken: String?,
                            scene: WikiMainTreeScene,
                            treeContext: WikiTreeContext? = nil,
                            synergyUUID: String = UUID().uuidString) {
        let dataModel = WikiTreeDataModel(spaceID: spaceID,
                                          initialWikiToken: wikiToken,
                                          scene: scene,
                                          treeContext: treeContext,
                                          networkAPI: WikiNetworkManager.shared,
                                          cacheAPI: WikiTreeCacheHandle.shared,
                                          processor: WikiTreeDataProcessor())
        self.init(userResolver: userResolver,
                  dataModel: dataModel,
                  scene: scene,
                  initialNodeUID: treeContext?.nodeUID,
                  synergyUUID: synergyUUID)
    }

    public convenience init(userResolver: UserResolver,
                            dataModel: WikiMainTreeDataModelType,
                            scene: WikiMainTreeScene,
                            initialNodeUID: WikiTreeNodeUID? = nil,
                            synergyUUID: String = UUID().uuidString) {
        let networkAPI = WikiNetworkManager.shared
        let interactionHandler = WikiInteractionHandler(networkAPI: networkAPI,
                                                        synergyUUID: synergyUUID)
        let moreProvider = WikiMainTreeMoreProvider(interactionHelper: interactionHandler)
        let converterProvider = WikiMainTreeConverterProvider(offlineChecker: WikiMainTreeOfflineChecker(userReslover: userResolver))
        self.init(userResolver: userResolver,
                  dataModel: dataModel,
                  scene: scene,
                  initialNodeUID: initialNodeUID,
                  interactionHandler: interactionHandler,
                  moreProvider: moreProvider,
                  networkAPI: WikiNetworkManager.shared,
                  converterProvider: converterProvider,
                  synergyUUID: synergyUUID)
    }

    // 单测用
    public init(userResolver: UserResolver,
                dataModel: WikiMainTreeDataModelType,
                scene: WikiMainTreeScene,
                initialNodeUID: WikiTreeNodeUID?,
                interactionHandler: WikiInteractionHandler,
                moreProvider: WikiTreeMoreProvider,
                networkAPI: WikiTreeNetworkAPI,
                converterProvider: WikiMainTreeConverterProviderType,
                synergyUUID: String) {
        self.userResolver = userResolver
        self.scene = scene
        self.initialNodeUID = initialNodeUID
        self.synergyUUID = synergyUUID
        self.dataModel = dataModel
        self.interactionHandler = interactionHandler
        self.moreProvider = moreProvider
        self.networkAPI = networkAPI
        syncDispatcher = WikiSyncDispatcher(spaceID: dataModel.spaceID,
                                            synergyUUID: synergyUUID,
                                            networkAPI: networkAPI)
        self.converterProvider = converterProvider
        self.converterProvider.clickHandler = self
    }

    public func setup() {
        if hasBeenSetup {
            // 从目录树打开文档后，会重复调用一次 setup，这里需要主动触发一次并scroll一下
            treeStateRelay.accept(dataModel.treeState)
            if let initialNodeUID = initialNodeUID {
                scrollByUIDInput.accept(initialNodeUID)
            } else if let selectedWikiToken = selectedWikiToken {
                focusNode(wikiToken: selectedWikiToken, shouldLoading: false)
            }
            return
        }
        hasBeenSetup = true

        setupList()
        setupMoreProvider()
        setupInput()
        setupDataModel()
        // 监听协同事件
        setupSyncProcessor()

        if let initialNodeUID = initialNodeUID {
            // 带初始化状态进入的场景下，需要主动触发一次 treeStateRelay
            treeStateRelay.accept(dataModel.treeState)
            scrollByUIDInput.accept(initialNodeUID)
        } else {
            setupData()
        }
    }
}

// 初始化逻辑
extension WikiMainTreeViewModel {
    // 核心的列表数据转换逻辑
    private func setupList() {
        Observable.combineLatest(treeStateRelay.skip(1),
                                 userSpacePermissionRelay,
                                 reachabilityRelay)
            .observeOn(workQueueScheduler)
            .map { [weak self] (state, userPermission, isReachable) -> [NodeSection] in
                if state.isEmpty { return [] }
                guard let self = self else { return [] }
                let converter = self.converterProvider.converter(treeState: state,
                                                                 isReachable: isReachable)
                var rootList: [(TreeNodeRootSection, String)] = []
                // 是否展示置顶树，取决于用户对知识库的权限
                // mvp新首页下目录树不展示置顶根节点
                if userPermission.canStarWiki,
                   let starRootToken = state.metaStorage[WikiTreeNodeMeta.favoriteRootToken]?.wikiToken,
                   !UserScopeNoChangeFG.WWJ.newSpaceTabEnable {
                    rootList.append((.favoriteRoot, starRootToken))
                }
                let sharedRootToken = state.metaStorage[WikiTreeNodeMeta.sharedRootToken]?.wikiToken
                /// 是否展示空间目录树，取决于后端有没有下发 mainRootMeta
                if let mainRootToken = state.metaStorage.first(where: { $1.nodeType == .mainRoot })?.key {
                    rootList.append((.mainRoot, mainRootToken))
                }
                if let sharedRootToken = sharedRootToken {
                    rootList.append((.sharedRoot, sharedRootToken))
                }
                if rootList.isEmpty { return [] }
                return converter.convert(rootList: rootList)
            }
            .bind(to: sectionsRelay)
            .disposed(by: disposeBag)
    }

    private func setupInput() {
        focusByWikiTokenInput.asSignal()
            .emit(onNext: { [weak self] token in
                // 来自外部的 focus 信号，需要 loading
                self?.focusNode(wikiToken: token, shouldLoading: true)
            })
            .disposed(by: disposeBag)

        RxNetworkMonitor.networkStatus(observerObj: self)
            .map { $1 }
            .bind(to: reachabilityRelay)
            .disposed(by: disposeBag)
        
        reachabilityRelay.distinctUntilChanged()
            .filter{ $0 }
            .subscribe(onNext: {[weak self] _ in
                self?.reload(isRefresh: true)
            })
            .disposed(by: disposeBag)

        createRootNodeInput.asSignal()
            .emit { [weak self] sourceView in
                guard let self = self else { return }
                guard let rootMeta = self.treeStateRelay.value.metaStorage.first(where: { $1.nodeType == .mainRoot })?.value else {
                    DocsLogger.error("failed to get rootToken when create root node")
                    return
                }
                self.moreProvider.createOnRootNode(rootMeta: rootMeta, sourceView: sourceView)
            }
            .disposed(by: disposeBag)

        scrollByUIDInput
            .observeOn(workQueueScheduler)
            .subscribe(onNext: { [weak self] targetUID in
                guard let self = self else { return }
                let sections = self.sectionsRelay.value
                for (sectionIndex, section) in sections.enumerated() {
                    guard let rowIndex = section.items.firstIndex(where: { $0.diffId == targetUID }) else {
                        continue
                    }
                    let indexPath = IndexPath(row: rowIndex, section: sectionIndex)
                    self.actionInput.accept(.scrollTo(indexPath: indexPath))
                    return
                }
            })
            .disposed(by: disposeBag)

        syncWithContextInput.asSignal()
            .filter { [weak self] context in
                guard let self = self else { return false }
                // 如果详情页发生了 spaceID 变化，知识空间不需要跟着跳转
                return self.spaceID == context.spaceID
            }
            .emit(onNext: { [weak self] context in
                self?.reset(context: context)
            })
            .disposed(by: disposeBag)
        
        dataModel.initialStateUpdated.drive(onNext: {[weak self] state in
            guard let self = self, case let .failure(error) = state.serverState else {
                return
            }
            let errorCode = WikiErrorCode(rawValue: (error as NSError).code) ?? .networkError
            if case .success = state.cacheState, errorCode == .networkError {
                // 无网有缓存正常展示，不展示兜底页
                return
            }
            let faileTipsView = WikiFaildView()
            faileTipsView.isHidden = false
            if errorCode == .nodePermFailCode {
                faileTipsView.showFail(error: .permFail)
            } else {
                faileTipsView.showFail(error: errorCode)
            }
            self.actionInput.accept(.showErrorPage(faileTipsView))
            
        }).disposed(by: disposeBag)
    }

    private func setupDataModel() {
        dataModel.userSpacePermissionUpdated
            .drive(userSpacePermissionRelay)
            .disposed(by: disposeBag)

        let spaceInfoUpdated = dataModel.spaceInfoUpdated
        spaceInfoUpdated
            .drive(spaceInfoRelay)
            .disposed(by: disposeBag)

        spaceInfoUpdated
            .drive(onNext: { [weak self] spaceInfo in
                self?.moreProvider.spaceInput.accept(spaceInfo)
            })
            .disposed(by: disposeBag)

        dataModel.spaceIDUpdated.skip(1)
            .drive(onNext: { [weak self] _ in
                self?.reloadWhenSpaceIDUpdated()
            })
            .disposed(by: disposeBag)
    }

    private func setupData() {
        // MARK: Start Load Data
        dataModel.restore()
            .flatMap { [weak self] state -> Maybe<WikiTreeState> in
                guard let self = self else { return .just(state) }
                if let initialWikiToken = self.dataModel.initialWikiToken {
                    let section = WikiTreeDataProcessor.getNodeSection(wikiToken: initialWikiToken, treeState: state)
                    let nodeUID = WikiTreeNodeUID(wikiToken: initialWikiToken,
                                                  section: section ?? .mainRoot,
                                                  shortcutPath: "")
                    return self.dataModel.select(wikiToken: initialWikiToken, nodeUID: nodeUID).asMaybe()
                } else {
                    return .just(state)
                }
            }
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] state in
                guard let self = self else { return }
                DocsLogger.info("main tree restore from cache")
                self.treeStateRelay.accept(state)
                if let selectedToken = state.viewState.selectedWikiToken {
                    self.focusNode(wikiToken: selectedToken, shouldLoading: false)
                }
            } onError: { error in
                DocsLogger.error("main tree load cache failed with error", error: error)
            } onCompleted: {
                DocsLogger.info("main tree found no cache")
            }
            .disposed(by: disposeBag)

        dataModel.restoreFavoriteList()
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] state in
                DocsLogger.info("main tree restore fav list from cache")
                self?.treeStateRelay.accept(state)
            } onError: { [weak self] error in
                DocsLogger.error("main tree load fav cache failed with error", error: error)
                guard let self = self else { return }
                self.dataModel.makeFavoriteRoot()
                    .subscribe(onSuccess: { [weak self] state in
                        self?.treeStateRelay.accept(state)
                    })
                    .disposed(by: self.disposeBag)
            } onCompleted: { [weak self] in
                DocsLogger.info("main tree found no fav cache")
                guard let self = self else { return }
                self.dataModel.makeFavoriteRoot()
                    .subscribe(onSuccess: { [weak self] state in
                        self?.treeStateRelay.accept(state)
                    })
                    .disposed(by: self.disposeBag)
            }
            .disposed(by: disposeBag)

        reload()
    }
}

// MARK: - load data
extension WikiMainTreeViewModel {
    public func reload(isRefresh: Bool = false) {
        // reload 里不会尝试重新加载缓存，因为通常而言需要重试的场合都不存在缓存
        dataModel.reload()
            .observeOn(MainScheduler.instance)
            .flatMap { [weak self] (state, cacheLoaded) -> Single<(WikiTreeState, Bool)> in
                guard let self = self else { return .just((state, cacheLoaded)) }
                // 首次加载默认高亮逻辑
                if let initialWikiToken = self.dataModel.initialWikiToken {
                    let section = WikiTreeDataProcessor.getNodeSection(wikiToken: initialWikiToken, treeState: state)
                    let nodeUID = WikiTreeNodeUID(wikiToken: initialWikiToken,
                                                  section: section ?? .mainRoot,
                                                  shortcutPath: "")
                    return self.dataModel.select(wikiToken: initialWikiToken, nodeUID: nodeUID)
                        .map { ($0, cacheLoaded) }
                } else {
                    return .just((state, cacheLoaded))
                }
            }
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] state, cacheLoaded in
                DocsLogger.info("main tree reload from server")
                guard let self = self else { return }
                self.dataState = .synced
                self.treeStateRelay.accept(state)
                if !cacheLoaded,
                   !isRefresh,
                   let selectedToken = state.viewState.selectedWikiToken {
                    self.focusNode(wikiToken: selectedToken, shouldLoading: false)
                }
            } onError: { [weak self] error in
                DocsLogger.error("main tree reload from server failed with error", error: error)
                guard let self = self else { return }
                self.dataState = .fetchFailed(error: error)
                // 重放一次触发 UI 刷新
                self.treeStateRelay.accept(self.treeStateRelay.value)
            }
            .disposed(by: disposeBag)

        reloadWhenSpaceIDUpdated()
    }

    // spaceID 变化后，需要重新拉取一次收藏列表和权限
    private func reloadWhenSpaceIDUpdated() {
        // 由于 spaceID 变化后不会加载缓存，需要手动插入一个收藏根
        dataModel.makeFavoriteRoot()
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] state in
                DocsLogger.info("manual insert fav list root")
                guard let self = self else { return }
                self.treeStateRelay.accept(state)
            } onError: { error in
                DocsLogger.error("manual insert fav list failed", error: error)
            }
            .disposed(by: disposeBag)

        dataModel.reloadFavoriteList()
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] state in
                DocsLogger.info("main tree reload fav list from server")
                guard let self = self else { return }
                self.treeStateRelay.accept(state)
            } onError: { error in
                // 拉失败了暂不处理，因为可能存在无权限的情况
                DocsLogger.error("main tree reload fav list from server failed", error: error)
            }
            .disposed(by: disposeBag)

        networkAPI.getSpacePermission(spaceId: dataModel.spaceID)
            .subscribe { [weak self] spacePermission in
                guard let self = self else { return }
                DocsLogger.info("did get root space permission", extraInfo: ["perm": spacePermission])
                self.moreProvider.spacePermissionInput.accept(spacePermission)
            } onError: { error in
                DocsLogger.error("main tree get root space permission failed")
            }
            .disposed(by: disposeBag)
        // spaceID 变化需要重新建立新的监听
        treeSyncDispatchHandler.removeAllDispatcher()
        setupSyncProcessor()
    }
}

// MARK: - Click Handler
extension WikiMainTreeViewModel: WikiTreeConverterClickHandler {
    public func configDidClickNode(meta: WikiTreeNodeMeta, node: TreeNode) -> ((IndexPath) -> Void)? {
        return { [weak self] _ in
            guard let self = self else { return }
            if meta.nodeType.isRootType {
                // 根节点的点击操作视为折叠
                self.toggleExpand(meta: meta, nodeUID: node.diffId)
                return
            }
            self.didSelect(meta: meta, nodeUID: node.diffId)
        }
    }

    public func configDidToggleNode(meta: WikiTreeNodeMeta, node: TreeNode) -> ((IndexPath) -> Void)? {
        return { [weak self] _ in
            guard let self = self else { return }
            self.toggleExpand(meta: meta, nodeUID: node.diffId)
        }
    }

    public func configAccessoryItem(meta: WikiTreeNodeMeta, node: TreeNode) -> TreeNodeAccessoryItem? {
        let showAddItem = meta.nodeType == .mainRoot && UserScopeNoChangeFG.WWJ.newSpaceTabEnable
        guard showAddItem else {
            return nil
        }
        
        return TreeNodeAccessoryItem(identifier: "create-on-main-tree",
                                     image: UDIcon.getIconByKeyNoLimitSize(.addOutlined,
                                                                           iconColor: UDColor.iconN1),
                                     handler: { [weak self] view in
            self?.moreProvider.createOnRootNode(rootMeta: meta, sourceView: view)
        })
    }

    public func update(selectedToken: String) {
        // TODO: 现算一个当前树的 nodeUID
        dataModel.select(wikiToken: selectedToken, nodeUID: nil)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] state in
                guard let self else { return }
                self.treeStateRelay.accept(state)
            } onError: { error in
                DocsLogger.error("select node failed?", error: error)
            }
            .disposed(by: disposeBag)
    }

    func didSelect(meta: WikiTreeNodeMeta, nodeUID: WikiTreeNodeUID, expandIfNeed: Bool = SKDisplay.pad) {
        // 带树信息跳转详情页
        let wikiToken = meta.wikiToken
        dataModel.select(wikiToken: wikiToken, nodeUID: nodeUID)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] state in
                guard let self = self else { return }
                self.treeStateRelay.accept(state)
                let context = WikiTreeContext(nodeUID: nodeUID,
                                              spaceID: self.dataModel.spaceID,
                                              treeState: state,
                                              spaceInfo: self.spaceInfo,
                                              userSpacePermission: self.userSpacePermission)
                self.onClickNodeInput.accept((meta, context))
            } onError: { error in
                DocsLogger.error("select node failed?", error: error)
            }
            .disposed(by: disposeBag)

        let viewState = treeStateRelay.value.viewState
        // iPad 上，选中节点的同时，还需要展开被选中的节点
        if expandIfNeed,
           meta.hasChild,
           !viewState.expandedUIDs.contains(nodeUID) {
            toggleExpand(meta: meta, nodeUID: nodeUID)
        }
    }

    func toggleExpand(meta: WikiTreeNodeMeta, nodeUID: WikiTreeNodeUID) {
        let currentState = treeStateRelay.value
        let isExpand = !currentState.viewState.expandedUIDs.contains(nodeUID)
        WikiStatistic.clickWikiTreeExpand(isExpand: isExpand, isFavorites: nodeUID.section == .favoriteRoot, meta: meta)
        guard isExpand else {
            // 折叠比较简单
            dataModel.collapse(nodeUID: nodeUID)
                .observeOn(MainScheduler.instance)
                .subscribe { [weak self] state in
                    guard let self = self else { return }
                    self.treeStateRelay.accept(state)
                } onError: { error in
                    DocsLogger.error("collapse node failed?", error: error)
                }
                .disposed(by: disposeBag)
            return
        }

        let token = meta.originWikiToken ?? meta.wikiToken
        let spaceID = meta.originSpaceID ?? meta.spaceID
        var cacheReady = false
        dataModel.expand(wikiToken: token, spaceID: spaceID, nodeUID: nodeUID)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (state, fromCache) in
                self?.treeStateRelay.accept(state)
                if fromCache {
                    cacheReady = true
                }
            }, onError: { [weak self] error in
                DocsLogger.error("expand node failed", error: error)
                guard let self = self else { return }
                let wikiError = WikiErrorCode(rawValue: (error as NSError).code) ?? .networkError
                if !cacheReady {
                    self.actionInput.accept(.showHUD(.failure(wikiError.expandErrorDescription)))
                    // 重放一次触发 UI 刷新，重置 loading 状态
                    self.treeStateRelay.accept(self.treeStateRelay.value)
                }
            })
            .disposed(by: disposeBag)
    }

    // 展开并高亮到特定路径
    // 从搜索跳到特定位置, 或跨库移动后
    func focusNode(wikiToken: String, shouldLoading: Bool) {
        // 部分场景已经请求到了数据在 focus，此时不需要 loading
        if shouldLoading {
            actionInput.accept(.showLoading)
        }
        dataModel.focus(wikiToken: wikiToken)
            .subscribe { [weak self] state in
                guard let self = self else { return }
                self.treeStateRelay.accept(state)
                // 固定跳到无 shortcut 路径
                let section = WikiTreeDataProcessor.getNodeSection(wikiToken: wikiToken, treeState: state) ?? .mainRoot
                let nodeUID = WikiTreeNodeUID(wikiToken: wikiToken, section: section, shortcutPath: "")
                self.scrollByUIDInput.accept(nodeUID)
            } onError: { [weak self] error in
                DocsLogger.error("focus node failed", error: error)
                guard let self = self else { return }
                let wikiError = WikiErrorCode(rawValue: (error as NSError).code) ?? .networkError
                self.actionInput.accept(.showHUD(.failure(wikiError.expandErrorDescription)))
                // 重放一次触发 UI 刷新，重置 loading 状态
                self.treeStateRelay.accept(self.treeStateRelay.value)
            }
            .disposed(by: disposeBag)
    }

    private func reset(context: WikiTreeContext) {
        dataModel.reset(context: context)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] state in
                guard let self = self else { return }
                self.treeStateRelay.accept(state)
                self.scrollByUIDInput.accept(context.nodeUID)
            } onError: { error in
                DocsLogger.error("reset with context failed", error: error)
            }
            .disposed(by: disposeBag)
    }
}


// MARK: - DataBuilderInterface
extension WikiMainTreeViewModel: TreeViewDataBuilder {
    public var spaceID: String { dataModel.spaceID }
    
    public var sectionRelay: BehaviorRelay<[NodeSection]> {
        sectionsRelay
    }

    public var input: (build: PublishRelay<Void>, swipeCell: PublishRelay<(IndexPath, TreeNode)>) {
        (reloadInput, onSwipeCellInput)
    }

    public func configSlideAction(node: TreeNode) -> [TreeSwipeAction]? {
        let metas = treeStateRelay.value.metaStorage
        guard let meta = metas[node.id] else { return nil }
        return moreProvider.configSlideAction(meta: meta, node: node)
    }
}
