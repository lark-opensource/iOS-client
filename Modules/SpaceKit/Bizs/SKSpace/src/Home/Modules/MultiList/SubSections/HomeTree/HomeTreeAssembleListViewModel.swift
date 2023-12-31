//
//  HomeTreeListViewModel.swift
//  SKSpace
//
//  Created by majie.7 on 2023/9/7.
//

import Foundation
import SKWorkspace
import RxCocoa
import RxRelay
import RxSwift
import SKFoundation
import SKResource
import SKUIKit
import LarkContainer


public final class HomeTreeAssembleListViewModel {
    // 首页所有目录树的数据源
    let treeViewModels: [HomeTreeSectionViewModel]
    // 个人目录树因时序问题流程与其他首页目录树不一致，因此单独处理
    let personalViewModel: HomePersonalViewModel
    
    // 合并云文档与知识库数据后抛给UI处理
    let listStateRelay = BehaviorRelay<HomeListState>(value: .loading)
    var listStateDriver: Driver<HomeListState> { listStateRelay.asDriver() }
    // space首页action
    private let actionInput = PublishRelay<SpaceSectionAction>()
    public var actionSignal: Signal<SpaceSectionAction> {
        actionInput.asSignal()
    }
    private let reloadInput = PublishRelay<SpaceSectionReloadAction>()
    public var reloadSignal: Signal<SpaceSectionReloadAction> {
        reloadInput.asSignal()
    }
    // wiki目录树action
    public let wikiActionInput = PublishRelay<WikiTreeViewAction>()
    public var wikiActionSignal: Signal<WikiTreeViewAction> {
        wikiActionInput.asSignal()
    }
    // 滚动定位action
    private let scrollToItemInput = PublishRelay<Int>()
    public var scrollToItemSignal: Signal<Int> { scrollToItemInput.asSignal() }
    private let personalScrollItemInput = PublishRelay<Int>()
    // 需要处理节点自动展开定位时的时序问题，使用relay对象在section内处理时序问题，保证数据先展开后定位
    public let personalScrollRelay = PublishRelay<Int>()
    
    
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
    
    var isActive = false
    
    // 分享树最大展示节点数量
    private let maxShareListCount = 7
    private var userResolver: UserResolver
    
    public init(userResolver: UserResolver, treeViewModels: [HomeTreeSectionViewModel], coordinator: RefreshCoordinator) {
        self.userResolver = userResolver
        self.treeViewModels = treeViewModels
        self.personalViewModel = HomePersonalViewModel(userResolver: userResolver, coordinator: coordinator)
    }
    
    public func prepare() {
        setupNetworkStatus()
        setupViewModelsPrepare()
        bindAction()
        bindScrollAction()
        bindPersonalScrollAction()
        bindListState()
    }
    
    public func reloadList() {
        treeViewModels.forEach { $0.reloadList { [weak self] in
            self?.actionInput.accept(.stopPullToRefresh(total: nil))
        } }
        personalViewModel.treeViewModel?.reload(isRefresh: true)
    }
    
    private func setupNetworkStatus() {
        RxNetworkMonitor.networkStatus(observerObj: self)
            .map { $1 }
            .bind(to: reachabilityRelay)
            .disposed(by: disposeBag)
        
        reachabilityChanged.skip(1)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] reachable in
                guard let self else { return }
                if reachable {
                    self.reloadList()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func setupViewModelsPrepare() {
        personalViewModel.prepare()
        treeViewModels.forEach { $0.prepare() }
    }
    
    private func bindAction() {
        treeViewModels.forEach { viewModel in
            viewModel.actionSignal.emit(to: actionInput).disposed(by: disposeBag)
            viewModel.dataProvider.wikiActionSignal.emit(to: wikiActionInput).disposed(by: disposeBag)
        }
        // 个人目录树Action绑定
        personalViewModel.actionSignal.emit(to: actionInput).disposed(by: disposeBag)
        personalViewModel.reloadSignal.emit(to: reloadInput).disposed(by: disposeBag)
        personalViewModel.wikiTreeActionSignal
            .emit(onNext: { [weak self] action in
                switch action {
                case let .scrollTo(indexPath):
                    self?.personalViewModel.expandStateRelay.accept(true)
                    self?.personalScrollItemInput.accept(indexPath.item)
                default:
                    self?.wikiActionInput.accept(action)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func bindScrollAction() {
        for (index, viewModel) in treeViewModels.enumerated() {
            guard index != 0 else {
                viewModel.scrollToItemSignal.emit(to: scrollToItemInput).disposed(by: disposeBag)
                continue
            }
            
            let currentCount = index + 1
            guard currentCount <= treeViewModels.count else {
                return
            }
            let latestSections = treeViewModels.prefix(currentCount).map {
                return Driver.combineLatest($0.listStateDriver, $0.expandStateRelay.asDriver())
            }
            let latestDrivers = Driver.combineLatest(latestSections)

            viewModel.scrollToItemSignal.asDriver(onErrorJustReturn: 0)
                .withLatestFrom(latestDrivers) { currentIndex, sections in
                    return (currentIndex, sections)
                }
                .drive(onNext: { [weak self] currentIndex, sections in
                    var itemCount: Int = 0
                    sections.forEach { listState, isExpand in
                        guard isExpand else {
                            itemCount += 1
                            return
                        }
                        if case let .normal(homeItem) = listState {
                            itemCount += homeItem.items.count
                        }
                    }
                    // 真实索引: 当前目录树header + 当前目录树index + 之前所有目录树的item
                    let actualIndex = 1 + currentIndex + itemCount
                    self?.scrollToItemInput.accept(actualIndex)
                }).disposed(by: disposeBag)
        }
    }
    
    private func bindPersonalScrollAction() {
        let latestSections = treeViewModels.map {
            return Driver.combineLatest($0.listStateDriver, $0.expandStateRelay.asDriver())
        }
        let latestDriver = Driver.combineLatest(latestSections)
        
        personalScrollItemInput.asDriver(onErrorJustReturn: 0)
            .withLatestFrom(latestDriver) { currentIndex, sections in
                return (currentIndex, sections)
            }
            .drive(onNext: { [weak self] currentIndex, sections in
                var itemCount: Int = 0
                sections.forEach { listState, isExpand in
                    guard isExpand else {
                        itemCount += 1
                        return
                    }
                    if case let .normal(homeItem) = listState {
                        itemCount += homeItem.items.count
                    }
                }
                // 真实索引: 当前目录树header + 当前目录树index + 之前所有目录树的item
                let actualIndex = 1 + currentIndex + itemCount
                self?.personalScrollRelay.accept(actualIndex)
            })
            .disposed(by: disposeBag)
    }
    
    private func bindListState() {
        // 将所有目录树的数据状态绑定起来
        var allListStateDriver = treeViewModels.map { viewModel in
            return Driver.combineLatest(viewModel.listStateDriver,
                                        viewModel.expandStateRelay.asDriver(),
                                        Driver.just(false),
                                        Driver.just(viewModel.dataProvider.sectionScene))
        }
        let personalDriver = Driver.combineLatest(personalViewModel.listStateDriver,
                                                  personalViewModel.expandStateRelay.asDriver(),
                                                  personalViewModel.createButtonStatusRelay.asDriver(),
                                                  Driver.just(HomeTreeSectionScene.personal))
        allListStateDriver.append(personalDriver)
        
        
        Driver.combineLatest(allListStateDriver)
            .drive(onNext: { [weak self] allListState in
                guard let self else { return }
                var result = [HomeItemType]()
                allListState.forEach { listState, isExpand, showCreateButton, scene in
                    let listItems = self.transformPersonalItems(state: listState, isExpand: isExpand, scene: scene, showCreateButton: showCreateButton)
                    result.append(contentsOf: listItems)
                }
                
                let itemContainer = HomeItemContainer(identifier: "home.tree.assemble.section", items: result)
                self.listStateRelay.accept(.normal(homeItem: itemContainer))
            })
            .disposed(by: disposeBag)
        
    }
    
    // 将个人目录树VM的数据处理转换一下
    private func transformPersonalItems(state: HomeListState, isExpand: Bool, scene: HomeTreeSectionScene, showCreateButton: Bool) -> [HomeItemType] {
        var result = [HomeItemType]()
        switch state {
        case .error:
            guard scene == .personal else {
                // 非个人目录树，失败状态不展示当前目录树
                return []
            }
            result.append(.headerRoot(scene: .personal, isExpand: isExpand, showCreateButton: showCreateButton))
            result.append(.error)
        case .empty:
            guard scene == .personal else {
                // 非个人目录树，空状态不展示当前目录树
                return []
            }
            result.append(.headerRoot(scene: .personal, isExpand: isExpand, showCreateButton: showCreateButton))
            result.append(.empty)
        case .loading:
            result.append(.loading)
        case .normal(let homeItem):
            result.append(.headerRoot(scene: scene, isExpand: isExpand, showCreateButton: showCreateButton))
            guard isExpand else {
                return result
            }
            result.append(contentsOf: homeItem.items)
        }
        return result
    }
    
    public func clickSpecialExtraItem() {
        // 共享目录树查看更多按钮回调
        guard let vcFactory = try? userResolver.resolve(assert: SpaceVCFactory.self) else {
            DocsLogger.error("can not get SpaceVCFactory")
            return
        }
        let vc = vcFactory.makeAllFilesController(initialSection: .sharedFiles)
        actionInput.accept(.push(viewController: vc))
        
        SpaceNewHomeTracker.reportSpaceHomeViewAllSharedClick()
    }
    
    public func clickHeaderView(scene: HomeTreeSectionScene, expand: Bool) {
        if scene == .personal {
            personalViewModel.expandStateRelay.accept(expand)
        } else {
            treeViewModels.first { $0.dataProvider.sectionScene == scene }?.expandStateRelay.accept(expand)
        }
    }
    
    // multiSection 列表切换到当前 section
    func didBecomeActive() {
        isActive = true
        
    }

    // multiSection 列表即将切换到其他 section
    func willResignActive() {
        isActive = false
    }
}

extension HomeTreeAssembleListViewModel {
    public func configSlidItem(node: TreeNode) -> [SKCustomSlideItem]? {
        switch node.section {
        case .documentRoot:
            return treeViewModels.first { $0.dataProvider.sectionScene == .clipDocument }?.configSlidItem(node: node)
        case .mutilTreeRoot:
            return treeViewModels.first { $0.dataProvider.sectionScene == .clipWikiSpace }?.configSlidItem(node: node)
        case .homeSharedRoot:
            return treeViewModels.first { $0.dataProvider.sectionScene == .shared }?.configSlidItem(node: node)
        case .mainRoot:
            return personalViewModel.configSlidItem(node: node)
        default:
            spaceAssertionFailure("home tree should have not the section tree!")
            return nil
        }
    }
        
    public func configHoverItem(node: TreeNode) -> [HomeHoverItem]? {
        switch node.section {
        case .documentRoot:
            return treeViewModels.first { $0.dataProvider.sectionScene == .clipDocument }?.configHoverItem(node: node)
        case .mutilTreeRoot:
            return treeViewModels.first { $0.dataProvider.sectionScene == .clipWikiSpace }?.configHoverItem(node: node)
        case .homeSharedRoot:
            return treeViewModels.first { $0.dataProvider.sectionScene == .shared }?.configHoverItem(node: node)
        case .mainRoot:
            return personalViewModel.configHoverItem(node: node)
        default:
            spaceAssertionFailure("home tree should have not the section tree!")
            return nil
        }
    }
}
