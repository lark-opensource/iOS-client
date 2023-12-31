//
//  HomeSectionDataProvider.swift
//  SKSpace
//
//  Created by majie.7 on 2023/6/26.
//

import Foundation
import SKWorkspace
import SKCommon
import RxCocoa
import RxSwift
import SKFoundation
import SKResource
import UniverseDesignDialog
import UniverseDesignIcon
import UniverseDesignColor
import SKUIKit
import LarkContainer

protocol HomeTreeSectionDataProviderProtocol {
    var sectionScene: HomeTreeSectionScene { get }
    var dataModel: WikiTreeDataModel { get }
    var treeStateRelay: BehaviorRelay<WikiTreeState> { get }
    var actionSignal: Signal<SpaceSectionAction> { get }
    var onClickNodeSignal: Signal<(WikiTreeNodeMeta, WikiTreeContext)> { get }
    var sectionsDriver: Driver<[NodeSection]> { get }
    var scrollToItemSignal: Signal<Int> { get }
    
    func reloadList(completion: (() -> Void)?)
    func restoreList()
    func configSlidItem(node: TreeNode) -> [SKCustomSlideItem]?
}

public enum HomeTreeSectionScene: String {
    case clipDocument
    case clipWikiSpace
    case shared
    case personal
    
    public var headerTitle: String {
        switch self {
        case .clipDocument:
            return BundleI18n.SKResource.LarkCCM_NewCM_Pins_Title
        case .clipWikiSpace:
            return BundleI18n.SKResource.Doc_Facade_Wiki
        case .shared:
            return BundleI18n.SKResource.LarkCCM_NewCM_Shared_Menu
        case .personal:
            return BundleI18n.SKResource.LarkCCM_CM_MyLib_Menu
        }
    }
}

class HomeTreeSectionDataProvider: HomeTreeSectionDataProviderProtocol {
    
    //protocal
    public let sectionScene: HomeTreeSectionScene
    public let dataModel: WikiTreeDataModel
    public let treeStateRelay = BehaviorRelay<WikiTreeState>(value: .empty)
    
    private let sectionsRelay = BehaviorRelay<[NodeSection]>(value: [])
    public var sectionsDriver: Driver<[NodeSection]> { sectionsRelay.asDriver() }
    
    public let actionInput = PublishRelay<SpaceSectionAction>()
    public var actionSignal: Signal<SpaceSectionAction> {
        actionInput.asSignal()
    }

    private let scrollToItemInput = PublishRelay<Int>()
    public var scrollToItemSignal: Signal<Int> { scrollToItemInput.asSignal() }
    
    // 内部持有
    private let disposeBag = DisposeBag()
    let reachabilityRelay = BehaviorRelay<Bool>(value: true)
    private let converterProvider: WikiMutilTreeConverterProvider
    private let workQueue = DispatchQueue(label: "home.tree.data.prvoider.dataQueue")
    private lazy var workQueueScheduler = SerialDispatchQueueScheduler(queue: workQueue,
                                                                       internalSerialQueueName: "home.tree.data.provider.scheduler")
    
    // space More面板相关
    private(set) var tracker = SpaceSubSectionTracker(bizParameter: SpaceBizParameter(module: .wikiSpace))
    let interactionHelper: SpaceInteractionHelper
    private lazy var slideActionHelper: SpaceListSlideDelegateProxyV2 = {
        return SpaceListSlideDelegateProxyV2(helper: self)
    }()
    
    // Wiki More面板相关
    public let moreProvider: WikiMainTreeMoreProvider
    public let interactionHandler: WikiInteractionHandler
    // more面板操作协同处理
    private lazy var moreActionSyncDispatcher: TreeMoreActionSyncDispatcher = {
        return TreeMoreActionSyncDispatcher(userResolver: userResolver, syncModel: self)
    }()
    // 知识库协同管理
    private lazy var treeSyncDispatcherHandler: TreeSyncDispatchHandler = {
        return TreeSyncDispatchHandler(userResolver: userResolver, syncModel: self)
    }()
    
    // MARK: - output
    // 参数为: 父节点 wikiToken，是否是图片，callback
    public let scrollByUIDInput = PublishRelay<WikiTreeNodeUID>()
    // 手动删除节点时需要上报
    public let onManualDeleteNodeInput = PublishRelay<Void>()
    /// 当存在节点被手动删除（目前仅除外协同场景）时，通知上游，参数为被删除的 wikiToken，删除的节点是否当前被选中
    /// 仅用于详情页场景删除自身的场景，此时上游会关闭当前页面
    public var onManualDeleteNodeSignal: Signal<Void> { onManualDeleteNodeInput.asSignal() }
    public let onUploadInput = PublishRelay<(String, Bool, DidSelectFileAction)>()
    public var onUploadSignal: Signal<(String, Bool, DidSelectFileAction)> { onUploadInput.asSignal() }
    public var wikiActionInput = PublishRelay<WikiTreeViewAction>()
    public var wikiActionSignal: Signal<WikiTreeViewAction> { wikiActionInput.asSignal() }
    public let onClickNodeInput = PublishRelay<(WikiTreeNodeMeta, WikiTreeContext)>()
    var onClickNodeSignal: Signal<(WikiTreeNodeMeta, WikiTreeContext)> { onClickNodeInput.asSignal() }
    
    // 保证数据加载串行化
    private var coordinator: RefreshCoordinator
    private let synergyUUID: String
    
    let userResolver: UserResolver
    public init(userResolver: UserResolver,
                dataModel: WikiTreeDataModel,
                convertProvider: WikiMutilTreeConverterProvider,
                coordinator: RefreshCoordinator,
                scene: HomeTreeSectionScene) {
        self.userResolver = userResolver
        self.synergyUUID = UUID().uuidString
        self.sectionScene = scene
        self.dataModel = dataModel
        self.converterProvider = convertProvider
        self.coordinator = coordinator
        self.interactionHelper = SpaceInteractionHelper(dataManager: SKDataManager.shared)
        self.interactionHandler = WikiInteractionHandler()
        self.moreProvider = WikiMainTreeMoreProvider(interactionHelper: interactionHandler)
        self.moreProvider.moreActionProxy = self
        convertProvider.clickHandler = self
    }
    
    public convenience init(userResolver: UserResolver,
                            dataModel: WikiTreeDataModel,
                            coordinator: RefreshCoordinator,
                            scene: HomeTreeSectionScene) {
        let convertProvider = WikiMutilTreeConverterProvider(offlineChecker: WikiMainTreeOfflineChecker(userReslover: userResolver))
        self.init(userResolver: userResolver,
                  dataModel: dataModel,
                  convertProvider: convertProvider,
                  coordinator: coordinator,
                  scene: scene)
    }
    
    public func prepare() {
        userResolver.docs.spacePerformanceTracker?.begin(stage: .loadFromDB, scene: .homeContents)
        userResolver.docs.spacePerformanceTracker?.begin(stage: .loadFromNetwork, scene: .homeContents)
        
        setupList()
        setupData()
        setupInput()
        setupMoreProvider()
    }
    
    func reloadList(completion: (() -> Void)? = nil) {
        dataModel.reload()
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] state, _ in
                guard let self else { return }
                DocsLogger.info("home \(self.sectionScene.rawValue) tree reload from server")
                self.treeStateRelay.accept(state)
                self.userResolver.docs.spacePerformanceTracker?.end(stage: .loadFromNetwork, succeed: true, dataSize: state.metaStorage.count, scene: .homeContents)
                completion?()
            } onError: { [weak self] error in
                guard let self else { return }
                DocsLogger.error("home \(self.sectionScene.rawValue) tree reload faile from server", error: error)
                self.userResolver.docs.spacePerformanceTracker?.end(stage: .loadFromNetwork, succeed: false, dataSize: 0, scene: .homeContents)
                completion?()
            }
            .disposed(by: disposeBag)
    }
    
    func restoreList() {
        let currentScene = self.sectionScene
        dataModel.restore()
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] state in
                DocsLogger.info("home \(currentScene.rawValue) tree restore from cache")
                self?.treeStateRelay.accept(state)
                self?.userResolver.docs.spacePerformanceTracker?.end(stage: .loadFromDB, succeed: true, dataSize: state.metaStorage.count, scene: .homeContents)
            } onError: { [weak self] error in
                self?.userResolver.docs.spacePerformanceTracker?.end(stage: .loadFromDB, succeed: false, dataSize: 0, scene: .homeContents)
                DocsLogger.error("home \(currentScene.rawValue) tree restore failed from cache", error: error)
            } onCompleted: { [weak self] in
                self?.userResolver.docs.spacePerformanceTracker?.end(stage: .loadFromDB, succeed: false, dataSize: 0, scene: .homeContents)
                DocsLogger.info("home \(currentScene.rawValue) tree found no cache")
            }
            .disposed(by: disposeBag)

    }
    
    private func setupList() {
        Observable.combineLatest(treeStateRelay.skip(1), reachabilityRelay)
            .observeOn(workQueueScheduler)
            .map { [weak self] state, isReachable in
                guard let self else { return [] }
                if state.isEmptyTree { return [] }
                let converter = self.converterProvider.converter(treeState: state, isReachable: isReachable)
                var rootList = [(TreeNodeRootSection, String)]()
                switch self.sectionScene {
                case .clipDocument:
                    rootList.append((.documentRoot, WikiTreeNodeMeta.clipDocumentRootToken))
                case .clipWikiSpace:
                    rootList.append((.mutilTreeRoot, WikiTreeNodeMeta.mutilTreeRootToken))
                case .shared:
                    rootList.append((.homeSharedRoot, WikiTreeNodeMeta.homeSharedRootToken))
                case .personal:
                    spaceAssertionFailure("home personal should not use the data provider, it use personalViewModel")
                }
                return converter.convert(rootList: rootList)
            }
            .bind(to: sectionsRelay)
            .disposed(by: disposeBag)
    }
    
    private func setupData() {
        //读DB不需要加入串行队列，影响其他section首屏加载DB数据
        userResolver.docs.wikiStorage?.loadStorageIfNeed { [weak self] in
            self?.restoreList()
        }
        coordinator.enqueue()
            .subscribe { [weak self] completion in
                self?.reloadList(completion: completion)
            } onError: { [weak self] _ in
                self?.reloadList()
            }
            .disposed(by: disposeBag)
    }
    
    private func setupInput() {
        RxNetworkMonitor.networkStatus(observerObj: self)
            .map { $1 }
            .bind(to: reachabilityRelay)
            .disposed(by: disposeBag)

        scrollByUIDInput.observeOn(workQueueScheduler)
            .subscribe(onNext: { [weak self] targetUID in
                guard let self = self else { return }
                let sections = self.sectionsRelay.value
                for (sectionIndex, section) in sections.enumerated() {
                    guard let rowIndex = section.items.firstIndex(where: { $0.diffId == targetUID }) else {
                        continue
                    }
                    let indexPath = IndexPath(row: rowIndex, section: sectionIndex)
                    self.wikiActionInput.accept(.scrollTo(indexPath: indexPath))
                    return
                }
            })
            .disposed(by: disposeBag)
        // 置顶云文档本地刷新推送
        NotificationCenter.default.rx.notification(QuickAccessDataModel.quickAccessNeedUpdate)
            .subscribe(onNext: { [weak self] _ in
                guard self?.sectionScene == .clipDocument else { return }
                self?.reloadList()
            })
            .disposed(by: disposeBag)
        // 置顶知识库刷新推送
        NotificationCenter.default.rx.notification(.Docs.clipWikiSpaceListUpdate)
            .subscribe(onNext: { [weak self] _ in
                guard self?.sectionScene == .clipWikiSpace else { return }
                self?.reloadList()
            })
            .disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(.Docs.spaceHomeTabSelectedTokenChanged)
            .subscribe(onNext: { [weak self] notificaiton in
                guard let self,
                      let wikiToken = notificaiton.object as? String else {
                    return
                }
                self.update(selectedToken: wikiToken)
            })
            .disposed(by: disposeBag)
        
        // 同步列表文档删除状态，从列表移除
        NotificationCenter.default.rx.notification(.Docs.deleteDocInNewHome)
            .subscribe(onNext: { [weak self] notification in
                guard let self, let wikiToken = notification.object as? String else {
                    return
                }
                self.treeSyncDispatcherHandler.handleSyncDelete(wikiToken: wikiToken)
            })
            .disposed(by: disposeBag)
    }
    
    private func setupMoreProvider() {
        moreProvider.actionSignal.emit(to: wikiActionInput).disposed(by: disposeBag)
        
        moreProvider.moreActionSignal
            .emit { [weak self] action in
                self?.moreActionSyncDispatcher.handleMoreAction(action: action)
            }.disposed(by: disposeBag)
        
        moreProvider.parentProvider = { [weak self] childToken in
            guard let self else { return nil }
            let state = self.treeStateRelay.value
            return state.relation.nodeParentMap[childToken]
        }
        
        moreProvider.childCountProvider = { [weak self] targetToken in
            guard let self else { return nil }
            let state = self.treeStateRelay.value
            return state.relation.nodeChildrenMap[targetToken]?.count
        }

        onUploadSignal.emit(onNext: { [weak self] (token, isImage, action) in
            guard let self else { return }
            self.actionInput.accept(.customWithController(completion: { hostController in
                // TODO: 埋点 location 更新
                let helper = WikiSelectFileHelper(hostViewController: hostController, triggerLocation: .wikiHome)
                if isImage {
                    helper.selectImages(wikiToken: token, completion: action)
                } else {
                    helper.selectFile(wikiToken: token, completion: action)
                }
            }))
        }).disposed(by: disposeBag)
    }
}


extension HomeTreeSectionDataProvider: WikiTreeConverterClickHandler {
    public func configDidClickNode(meta: WikiTreeNodeMeta, node: TreeNode) -> ((IndexPath) -> Void)? {
        return { [weak self] _ in
            guard let self else { return }
            if meta.nodeType == .mainRoot {
                // 知识库节点点击操作视为折叠
                self.toggleExpand(meta: meta, nodeUID: node.diffId)
                return
            }
            self.didSelect(meta: meta, nodeUID: node.diffId)
        }
    }
    
    public func configDidToggleNode(meta: WikiTreeNodeMeta, node: TreeNode) -> ((IndexPath) -> Void)? {
        return { [weak self] _ in
            guard let self else { return }
            self.toggleExpand(meta: meta, nodeUID: node.diffId)
        }
    }
    
    public func configAccessoryItem(meta: WikiTreeNodeMeta, node: TreeNode) -> TreeNodeAccessoryItem? {
        nil
    }

    public func update(selectedToken: String) {
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
                // context兼容wiki目录树，在首页目录树只传不用
                let context = WikiTreeContext(nodeUID: nodeUID, spaceID: meta.spaceID, treeState: state)
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
                guard let self else { return }
                self.treeStateRelay.accept(state)
                if fromCache {
                    cacheReady = true
                }
                self.treeSyncDispatcherHandler.addDispather(spaceId: spaceID, synergyUUID: self.synergyUUID)
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
}

// MARK: More面板相关
extension HomeTreeSectionDataProvider {
    public func configSlidItem(node: TreeNode) -> [SKCustomSlideItem]? {
        let metaStorage = dataModel.treeState.metaStorage
        guard let meta = metaStorage[node.id] else {
            spaceAssertionFailure("can not get tree node meta in document tree")
            return nil
        }
        
        switch meta.nodeLocation {
        case .wiki:
            let isReachable = reachabilityRelay.value
            return moreProvider.configSlideAction(meta: meta, node: node).map { actions in
                actions.map { action in
                    action.getSlideItem(isEnable: isReachable, node: node)
                }
            }
        case let .space(file):
            return [
                        SKCustomSlideItem(icon: UDIcon.moreOutlined.ud.withTintColor(UDColor.staticWhite),
                                          backgroundColor: UDColor.N500,
                                          handler: { [weak self] _, view in
                                              self?.showSpaceMoreVC(entry: file, sourceView: view)
                                          })
                    ]
        }
    }
    
    public func configHoverItem(node: TreeNode) -> [HomeHoverItem]? {
        let metaStorage = dataModel.treeState.metaStorage
        guard let meta = metaStorage[node.id] else {
            spaceAssertionFailure("can not get tree node meta in document tree")
            return nil
        }
        
        switch meta.nodeLocation {
        case .wiki:
            let isReachable = reachabilityRelay.value
            return moreProvider.configSlideAction(meta: meta, node: node).map { actions in
                actions.map { action in
                    action.getHoverItem(node: node)
                }
            }
        case let .space(file):
            return [
                        HomeHoverItem(icon: UDIcon.moreOutlined.ud.withTintColor(UDColor.staticWhite),
                                      hoverBackgroundColor: UDColor.fillHover,
                                      handler:  { [weak self] _, view in
                                          self?.showSpaceMoreVC(entry: file, sourceView: view)
                                      })
                    ]
        }
    }
    
    private func showSpaceMoreVC(entry: SpaceEntry, sourceView: UIView) {
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        let realEntry = SKDataManager.shared.spaceEntry(objToken: entry.objToken) ?? entry
        var forbiddenItems = [MoreItemType]()
        switch sectionScene {
        case .clipDocument, .shared:
            if UserScopeNoChangeFG.ZYP.spaceMoveToEnable {
                forbiddenItems = [.delete]
            } else {
                forbiddenItems = [.moveTo, .delete]
            }
        default:
            return
        }
        
        var moreProvider = SpaceMoreProviderFactory.createMoreProvider(for: realEntry, sourceView: sourceView, forbiddenItems: forbiddenItems, listType: .clipDocument)
        moreProvider.handler = slideActionHelper
        let moreVM = MoreViewModel(dataProvider: moreProvider, docsInfo: entry.transform())
        let moreVC = MoreViewControllerV2(viewModel: moreVM)
        
        actionInput.accept(.present(viewController: moreVC, popoverConfiguration: { [weak sourceView] controller in
            guard let sourceView else { return }
            controller.modalPresentationStyle = .popover
            controller.popoverPresentationController?.sourceView = sourceView
            controller.popoverPresentationController?.sourceRect = sourceView.bounds
            controller.popoverPresentationController?.permittedArrowDirections = .any
        }))
    }
}

// MARK: Space More面板Handler相关
extension HomeTreeSectionDataProvider: SpaceListSlideDelegateHelperV2, WikiTreeMoreActionProxy {
    var slideActionInput: RxRelay.PublishRelay<SpaceSectionAction> {
        self.actionInput
    }
    
    var slideTracker: SpaceSubSectionTracker {
        tracker
    }
    
    var listType: SKObserverDataType? {
        nil
    }
    
    var userID: String {
        User.current.info?.userID ?? ""
    }
    
    func refreshForMoreAction() {
        reloadList()
    }
    
    func handleDelete(for entry: SKCommon.SpaceEntry) {}
}

// MARK: 目录树协同相关
extension HomeTreeSectionDataProvider: TreeSyncModelType {
    public var syncDataModel: WikiMainTreeDataModelType {
        dataModel
    }
    
    public var scene: WikiMainTreeScene {
        .spacePage
    }
    
    public var spaceInfo: WikiSpace? {
        nil
    }
    
    public var userSpacePermission: WikiUserSpacePermission {
        .default
    }
}
