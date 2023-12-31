//
//  HomePersonalSectionViewModel.swift
//  SKSpace
//
//  Created by majie.7 on 2023/5/23.
//

import Foundation
import SKWorkspace
import SKCommon
import RxSwift
import RxCocoa
import SKFoundation
import SKUIKit
import SKInfra
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignDialog
import LarkContainer

extension Notification.Name.Docs {
    static let spaceHomeTabSelectedTokenChanged = Notification.Name(rawValue: "docs.bytedance.notification.name.Docs.spaceHomeTabSelectedTokenChanged")
}

class HomePersonalViewModel {
    let disposeBag = DisposeBag()
    
    let networkAPI: WikiTreeNetworkAPI
    let myLibraryInteractionHandler: MyLibraryInteractionType
    
    var treeViewModel: WikiMainTreeViewModel?
    
    let listStateRelay = BehaviorRelay<HomeListState>(value: .loading)
    public var listStateDriver: Driver<HomeListState> {
        listStateRelay.asDriver()
    }
    
    private let actionInput = PublishRelay<SpaceSectionAction>()
    public var actionSignal: Signal<SpaceSectionAction> {
        actionInput.asSignal()
    }

    private let reloadInput = PublishRelay<SpaceSectionReloadAction>()
    public var reloadSignal: Signal<SpaceSectionReloadAction> {
        reloadInput.asSignal()
    }
    
    public let wikiTreeActionInput = PublishRelay<WikiTreeViewAction>()
    public var wikiTreeActionSignal: Signal<WikiTreeViewAction> {
        return wikiTreeActionInput.asSignal()
    }
    // 当前section的展开状态
    public var expandStateRelay = BehaviorRelay(value: true)
    private var isExpand: Bool {
        return expandStateRelay.value
    }
    
    public let createButtonStatusRelay = BehaviorRelay(value: false)
    
    // 串行化数据加载
    private let coordinator: RefreshCoordinator
    let userResolver: UserResolver
    
    convenience init(userResolver: UserResolver, coordinator: RefreshCoordinator) {
        
        self.init(userResolver: userResolver,
                  networkAPI: WikiNetworkManager.shared,
                  myLibraryInteractionHandler: MyLibraryInteractionHandler(),
                  coordinator: coordinator)
    }
    
    init(userResolver: UserResolver,
         networkAPI: WikiTreeNetworkAPI,
         myLibraryInteractionHandler: MyLibraryInteractionType,
         coordinator: RefreshCoordinator) {
        self.userResolver = userResolver
        self.networkAPI = networkAPI
        self.myLibraryInteractionHandler = myLibraryInteractionHandler
        self.coordinator = coordinator
    }
    
    
    func prepare() {
        userResolver.docs.wikiStorage?.loadStorageIfNeed(completion: { [weak self] in
            guard let self else { return }
            self.myLibraryInteractionHandler.getMyLibrarySpaceId()
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] spaceId in
                    self?.getLibraryIdCompeltion(spaceId: spaceId)
                }, onError: { [weak self] error in
                    DocsLogger.error("home.personal.section: get library id error", error: error)
                    self?.listStateRelay.accept(.error)
                })
                .disposed(by: self.disposeBag)
        })
    }
    
    private func getLibraryIdCompeltion(spaceId: String) {
        MyLibrarySpaceIdCache.set(spaceId: spaceId)
        self.treeViewModel = WikiMainTreeViewModel(userResolver: userResolver,
                                                   spaceID: spaceId,
                                                   wikiToken: nil,
                                                   scene: .myLibrary)
        self.bindTreeViewModelAction(spaceId: spaceId)
        treeViewModel?.setup()

        NotificationCenter.default.rx.notification(.Docs.spaceHomeTabSelectedTokenChanged)
            .subscribe(onNext: { [weak self] notification in
                guard let wikiToken = notification.object as? String else {
                    return
                }
                guard let self,
                let treeViewModel = self.treeViewModel else {
                    return
                }
                treeViewModel.update(selectedToken: wikiToken)
            })
            .disposed(by: disposeBag)
        
        reportPerformance()
    }
    
    private func bindTreeViewModelAction(spaceId: String) {
        guard let treeViewModel else { return }
        // 目录树数据合并信号
        let latestSections = Driver.combineLatest(treeViewModel.sectionsDriver,
                                                  treeViewModel.treeStateRelay.skip(1).asDriver(onErrorJustReturn: .empty),
                                                  expandStateRelay.asDriver())
        latestSections
            .drive(onNext: { [weak self] (sections, state, isExpand) in
                guard isExpand else {
                    let itemContainer = HomeItemContainer(identifier: spaceId, items: [])
                    self?.listStateRelay.accept(.normal(homeItem: itemContainer))
                    return
                }
                var items: [HomeItemType] = []
                sections.forEach { section in
                    // 只取目录下的数据
                    guard section.headerNode?.section == .mainRoot else { return }
                    items = section.items.map { .item(node: $0) }
                }
                let itemContainer = HomeItemContainer(identifier: spaceId, items: items)
                if items.isEmpty || state.isEmptyTree {
                    self?.listStateRelay.accept(.empty)
                    DocsLogger.info("home.personal.vm: personal tree is Empty")
                } else {
                    self?.listStateRelay.accept(.normal(homeItem: itemContainer))
                }
            })
            .disposed(by: disposeBag)
        
        treeViewModel.actionSignal
            .emit(onNext: { [weak self] action in
                self?.wikiTreeActionInput.accept(action)
            })
            .disposed(by: disposeBag)
        
        treeViewModel.onClickNodeSignal
            .emit(onNext: { [weak self] (meta, context) in
                guard let self = self else { return }
                let nodeMeta = WikiTreeNodeUtils.getWikiNodeMeta(treeMeta: meta)
                guard let wikiRouterAPI = try? self.userResolver.resolve(assert: WikiRouterBaseAPIProtocol.self) else {
                    DocsLogger.error("can not get wikiRouterAPI")
                    return
                }
                
                self.actionInput.accept(.customWithController(completion: { fromVC in
                    wikiRouterAPI.gotoWikiDetail(nodeMeta, extraInfo: context.params ?? [:], fromVC: fromVC, treeContext: context, completion: nil)
                }))
                
                NotificationCenter.default.post(name: .Docs.spaceHomeTabSelectedTokenChanged, object: meta.wikiToken)

                // 新首页 我的文档库 的 Section 是特化逻辑, 因此这里 scene 可以直接写 .personal
                SpaceNewHomeTracker.reportSpaceHomeTreeItemClick(docsType: meta.objType, scene: .personal)
            })
            .disposed(by: disposeBag)

        treeViewModel.onUploadSignal.emit(onNext: { [weak self] (token, isImage, action) in
            guard let self else { return }
            self.actionInput.accept(.customWithController(completion: { hostController in
                let helper = WikiSelectFileHelper(hostViewController: hostController, triggerLocation: .wikiHome)
                if isImage {
                    helper.selectImages(wikiToken: token, completion: action)
                } else {
                    helper.selectFile(wikiToken: token, completion: action)
                }
            }))
        }).disposed(by: disposeBag)
        
        treeViewModel.dataModel
            .initialStateUpdated
            .drive(onNext: { [weak self] state in
                if case .success = state.cacheState {
                    // wiki支持离线新建时，缓存数据加载成功就可以展示新建按钮
                    self?.createButtonStatusRelay.accept(true)
                }
                if case .success = state.serverState {
                    // 网络数据上屏后展示创建按钮
                    self?.createButtonStatusRelay.accept(true)
                }
            })
            .disposed(by: disposeBag)
        
        treeViewModel.reloadFailedDriver
            .drive(onNext: { [weak self] error in
                self?.listStateRelay.accept(.error)
                DocsLogger.error("reload home personal failed", error: error)
            })
            .disposed(by: disposeBag)
    }
    
    private func reportPerformance() {
        guard let treeViewModel else { return }
        
        treeViewModel.dataModel.initialStateUpdated
            .drive(onNext: { [weak self] state in
                if case .success = state.cacheState {
                    self?.userResolver.docs.spacePerformanceTracker?.reportLoadingSucceed(dataSource: .fromDBCache, scene: .homeContents)
                } else if case let .failure(error) = state.cacheState {
                    self?.userResolver.docs.spacePerformanceTracker?.reportLoadingFailed(dataSource: .fromDBCache, reason: error.localizedDescription, scene: .homeContents)
                } else if case .success = state.serverState {
                    self?.userResolver.docs.spacePerformanceTracker?.reportLoadingSucceed(dataSource: .fromNetwork, scene: .homeContents)
                } else if case let .failure(error) = state.serverState {
                    self?.userResolver.docs.spacePerformanceTracker?.reportLoadingFailed(dataSource: .fromNetwork, reason: error.localizedDescription, scene: .homeContents)
                }
            })
            .disposed(by: disposeBag)

        treeViewModel.sectionsDriver.asObservable()
            .skipUntil(treeViewModel.dataModel.initialStateUpdated.filter({ state in
                if case .failure = state.cacheState, case .failure = state.serverState {
                    return true
                }
                if case .success = state.cacheState {
                    return true
                }
                if case .success = state.serverState {
                    return true
                }
                return false
            }).asObservable())
            .observeOn(scheduler: MainScheduler.instance)
            .take(1)
            .subscribe(onNext: { [weak self] _ in
                // 加载结束，数据上屏上报
                self?.userResolver.docs.spacePerformanceTracker?.reportOpenFinish(filterOption: .all, sortType: .allTime, displayMode: .list, scene: .homeContents)
            })
            .disposed(by: disposeBag)
    }
}

// MARK: More面板配置
extension HomePersonalViewModel {
    public func configSlidItem(node: TreeNode) -> [SKCustomSlideItem]? {
        let isReachable = treeViewModel?.reachabilityRelay.value ?? false
        return getSlideAction(node: node).map({ actions in
            actions.map { action in
                action.getSlideItem(isEnable: isReachable, node: node)
            }
        })
    }
    
    public func configHoverItem(node: TreeNode) -> [HomeHoverItem]? {
        return getSlideAction(node: node).map { actions in
            actions.map { action in
                action.getHoverItem(node: node)
            }
        }
    }
    
    private func getSlideAction(node: TreeNode) -> [TreeSwipeAction]? {
        let treeState = treeViewModel?.treeStateRelay.value
        guard let meta = treeState?.metaStorage[node.id] else {
            return nil
        }

        let actions = treeViewModel?.moreProvider.configSlideAction(meta: meta, node: node)
        return actions
    }
    
    public func createOnRoot(sourceView: UIView) {
        treeViewModel?.createRootNodeInput.accept(sourceView)
    }
}
