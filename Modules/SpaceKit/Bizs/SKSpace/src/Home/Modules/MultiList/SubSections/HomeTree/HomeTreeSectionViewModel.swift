//
//  SpaceTabHomeTreeViewModel.swift
//  SKSpace
//
//  Created by majie.7 on 2023/6/26.
//

import Foundation
import SKWorkspace
import RxSwift
import RxRelay
import RxCocoa
import RxDataSources
import SKFoundation
import SKCommon
import SKUIKit
import SKResource
import UniverseDesignColor
import UniverseDesignIcon
import LarkContainer

// Space新首页目录树通用的ViewModel
public final class HomeTreeSectionViewModel {
    
    //数据diff Identifier
    private var homeItemIdentifier: String {
        return "home.section.tree" + dataProvider.sectionScene.rawValue
    }
    
    let dataProvider: HomeTreeSectionDataProvider
    // 合并云文档与知识库数据后抛给UI处理
    let listStateRelay = BehaviorRelay<HomeListState>(value: .loading)
    var listStateDriver: Driver<HomeListState> { listStateRelay.asDriver() }
    // space首页action
    private let actionInput = PublishRelay<SpaceSectionAction>()
    public var actionSignal: Signal<SpaceSectionAction> {
        actionInput.asSignal()
    }

    private let scrollToItemInput = PublishRelay<Int>()
    public var scrollToItemSignal: Signal<Int> { scrollToItemInput.asSignal() }
    
    
    // 当前section的展开状态
    public var expandStateRelay = BehaviorRelay(value: true)
    private var isExpand: Bool {
        return expandStateRelay.value
    }
    
    // 网络状态的监听
    private let reachabilityRelay = BehaviorRelay(value: true)
    private var reachabilityChanged: Observable<Bool> {
        reachabilityRelay.distinctUntilChanged().asObservable()
    }
    
    private let disposeBag = DisposeBag()
    
    // 共享section最大展示的数量
    let maxShareListCount = 7
    
    let userResolver: UserResolver
    
    public init(userResolver: UserResolver,
                scene: HomeTreeSectionScene,
                dataModel: WikiTreeDataModel,
                coordinator: RefreshCoordinator) {
        self.userResolver = userResolver
        self.dataProvider = HomeTreeSectionDataProvider(userResolver: userResolver,
                                                        dataModel: dataModel,
                                                        coordinator: coordinator,
                                                        scene: scene)
    }
    
    public func prepare() {
        setupNetworkStatus()
        bindAction()
        dataProvider.prepare()
        
        reportPerformanceTracker()
    }
    
    private func setupNetworkStatus() {
        RxNetworkMonitor.networkStatus(observerObj: self)
            .map { $1 }
            .bind(to: reachabilityRelay)
            .disposed(by: disposeBag)
        
        reachabilityChanged.skip(1)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] reachable in
                guard let self = self else { return }
                if reachable {
                    self.reloadList()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func bindAction() {
        // space action事件上抛
        dataProvider.actionSignal.emit(to: actionInput).disposed(by: disposeBag)
        // 目录树节点点击
        dataProvider.onClickNodeSignal
            .emit(onNext: { [weak self] (meta, _) in
                guard let self else { return }
                switch meta.nodeLocation {
                case .wiki:
                    let nodeMeta = WikiTreeNodeUtils.getWikiNodeMeta(treeMeta: meta)
                    self.actionInput.accept(.openURL(url: nodeMeta.wikiUrl, context: nil))
                    NotificationCenter.default.post(name: .Docs.spaceHomeTabSelectedTokenChanged, object: meta.wikiToken)
                case let .space(file):
                    self.actionInput.accept(.openURL(url: file.url, context: nil))
                    NotificationCenter.default.post(name: .Docs.spaceHomeTabSelectedTokenChanged, object: file.objToken)
                }
                SpaceNewHomeTracker.reportSpaceHomeTreeItemClick(docsType: meta.objType, scene: self.dataProvider.sectionScene)
            })
            .disposed(by: disposeBag)

        // 目录树数据合并信号
        let latestSections = Driver.combineLatest(dataProvider.sectionsDriver,
                                                  expandStateRelay.asDriver())
        // 上屏信号
        latestSections
            .drive(onNext: { [weak self] sections, isExpand in
                guard let self else { return }
                guard isExpand else {
                    let itemContainer = HomeItemContainer(identifier: homeItemIdentifier, items: [])
                    self.listStateRelay.accept(.normal(homeItem: itemContainer))
                    return
                }
                var treeItems = [HomeItemType]()
                sections.forEach { section in
                    treeItems = self.transformTreeItems(items: section.items)
                }
                
                if treeItems.isEmpty {
                    self.listStateRelay.accept(.empty)
                } else {
                    let itemContainer = HomeItemContainer(identifier: homeItemIdentifier, items: treeItems)
                    self.listStateRelay.accept(.normal(homeItem: itemContainer))
                }
            })
            .disposed(by: disposeBag)
        
        dataProvider.scrollToItemSignal.emit { [weak self] index in
            guard let self else { return }
            guard self.isExpand else { return }
            self.scrollToItemInput.accept(index)
        }
        .disposed(by: disposeBag)
    }
    
    public func reloadList(completion: (() -> Void)? = nil) {
        dataProvider.reloadList(completion: completion)
    }
    
    public func clickSpecialExtraItem() {
        switch dataProvider.sectionScene {
        case .clipDocument, .clipWikiSpace, .personal:
            return
        case .shared:
            guard let vcFactory = try? userResolver.resolve(assert: SpaceVCFactory.self) else {
                DocsLogger.error("can not get SpaceVCFactory")
                return
            }

            let vc = vcFactory.makeAllFilesController(initialSection: .sharedFiles)
            actionInput.accept(.push(viewController: vc))
        }
    }
    
    private func transformTreeItems(items: [TreeNode]) -> [HomeItemType] {
        switch dataProvider.sectionScene {
        case .clipDocument, .clipWikiSpace, .personal:
            return items.map { .item(node: $0) }
        case .shared:
            // 共享树只需要取前7个一级节点数据，且一级节点个数超过7个后展示查看全部按钮
            var rootChildrenCount = 0
            var result = [HomeItemType]()
            items.forEach { node in
                // 达到7个一级节点后，后续的一级节点数据直接过滤掉
                if rootChildrenCount >= maxShareListCount, node.level == 1 {
                    rootChildrenCount += 1
                    return
                }
                result.append(.item(node: node))
                if node.level == 1 {
                    rootChildrenCount += 1
                }
            }
            if rootChildrenCount > maxShareListCount {
                result.append(.specialItem(title: BundleI18n.SKResource.LarkCCM_NewCM_ViewAllSharedDocs_Menu))
            }
            return result
        }
    }
    
    private func reportPerformanceTracker() {
        
        dataProvider.dataModel.initialStateUpdated
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

        dataProvider.sectionsDriver.asObservable()
            .skipUntil(dataProvider.dataModel.initialStateUpdated.filter({ state in
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
extension HomeTreeSectionViewModel {
    public func configSlidItem(node: TreeNode) -> [SKCustomSlideItem]? {
        return dataProvider.configSlidItem(node: node)
    }
    
    public func configHoverItem(node: TreeNode) -> [HomeHoverItem]? {
        return dataProvider.configHoverItem(node: node)
    }
}

