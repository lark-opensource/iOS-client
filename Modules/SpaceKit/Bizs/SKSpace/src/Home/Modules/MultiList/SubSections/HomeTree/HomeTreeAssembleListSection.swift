//
//  HomeTreeAssembleListSection.swift
//  SKSpace
//
//  Created by majie.7 on 2023/9/11.
//

import Foundation
import RxCocoa
import RxRelay
import RxSwift
import SKWorkspace
import SKUIKit
import SKFoundation
import SKCommon
import UniverseDesignDialog
import SKResource


public final class HomeTreeAssembleListSection: SpaceSection {
    public var identifier: String = "space.home.tree.assemble.list.section"
    
    private let reloadInput = PublishRelay<ReloadAction>()
    public var reloadSignal: RxCocoa.Signal<ReloadAction> {
        reloadInput.asSignal()
    }
    
    private let actionInput = PublishRelay<Action>()
    public var actionSignal: RxCocoa.Signal<Action> {
        actionInput.asSignal()
    }
    
    private let disposeBag = DisposeBag()
    private let viewModel: HomeTreeAssembleListViewModel
    private var listState: HomeListState = .loading
    
    // 实现 section内的item侧滑互斥
    private let mutexHelper: SKCustomSlideMutexHelper
    private lazy var differ = HomeListStateDiffer(initialState: listState, differ: HomeViewListDiffer())
    private let dataQueue = DispatchQueue(label: "home.tree.assemble.section.dataQueue")
    private(set) lazy var dataQueueScheduler = SerialDispatchQueueScheduler(queue: dataQueue,
                                                                            internalSerialQueueName: "home.tree.assemble.section.dataQueueScheduler")
    
    public init(viewModel: HomeTreeAssembleListViewModel, slideMutexHelper: SKCustomSlideMutexHelper) {
        self.viewModel = viewModel
        self.mutexHelper = slideMutexHelper
    }
    
    public func prepare() {
        bindData()
        viewModel.prepare()
    }
    
    private func bindData() {
        viewModel.actionSignal.emit(to: actionInput).disposed(by: disposeBag)
        viewModel.reloadSignal.emit(to: reloadInput).disposed(by: disposeBag)
        
        viewModel.listStateRelay
            .observeOn(dataQueueScheduler)
            .subscribe(onNext: { [weak self] listState in
                self?.handle(state: listState)
            })
            .disposed(by: disposeBag)
        
        viewModel.wikiActionSignal
            .emit(onNext: { [weak self] action in
                self?.handle(action: action)
            })
            .disposed(by: disposeBag)
        
        viewModel.scrollToItemSignal
            .emit(onNext: { [weak self] index in
                guard let self else { return }
                self.dataQueue.async {
                    DispatchQueue.main.async {
                        guard index < self.numberOfItems else {
                            return
                        }
                        self.reloadInput.accept(.scrollToItem(index: index, at: .centeredVertically, animated: true))
                    }
                }
            })
            .disposed(by: disposeBag)
        
        // 个人目录树的滚动定位需要单独处理，定位时额外要固定展开个人目录树
        viewModel.personalScrollRelay
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] index in
                guard let self else { return }
                self.viewModel.personalViewModel.expandStateRelay.accept(true)
                self.dataQueue.async {
                    DispatchQueue.main.async {
                        guard index < self.numberOfItems else {
                            return
                        }
                        self.reloadInput.accept(.scrollToItem(index: index, at: .centeredVertically, animated: true))
                    }
                }
            })
            .disposed(by: disposeBag)
        
        if UserScopeNoChangeFG.MJ.newRecentListRefreshStrategy {
            NotificationCenter.default.rx
                .notification(.SpaceTabItemTapped)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] notification in
                    guard let userInfo = notification.userInfo,
                          let isSameTab = userInfo[SpaceTabItemTappedNotificationKey.isSameTab] as? Bool,
                          !isSameTab else {
                        return
                    }
                    self?.notifyPullToRefresh()
                })
                .disposed(by: disposeBag)
        }
    }
    
    public func notifyPullToRefresh() {
        viewModel.reloadList()
    }
    
    public func notifyPullToLoadMore() {
        actionInput.accept(.stopPullToLoadMore(hasMore: false))
    }
    
    public func notifySectionDidAppear() {
        actionInput.accept(.stopPullToLoadMore(hasMore: false))
    }
    
    // nolint: duplicated_code
    private func handle(state: HomeListState) {
        let transaction = differ.handle(newState: state)
        transaction.forEach { result in
            switch result {
            case .reload:
                DispatchQueue.main.async { [weak self] in
                    self?.listState = state
                    self?.reloadInput.accept(.reloadSection(animated: false))
                }
            case let .update(listState, inserts, deletes, updates, moves):
                guard viewModel.isActive else {
                    //在multiSection中View不展示的时候不会走到下面update逻辑的willUpdate给listState赋值，此处区分处理下
                    DispatchQueue.main.async { [weak self] in
                        self?.listState = state
                    }
                    return
                }

                reloadInput.accept(.update(inserts: inserts,
                                           deletes: deletes,
                                           updates: updates,
                                           moves: moves,
                                           willUpdate: { [weak self] in
                    self?.listState = listState
                }))
            }
        }
    }
    
    private func handle(action: WikiTreeViewAction) {
        switch action {
        case .scrollTo(let indexPath):
            dataQueue.async { [weak self] in
                DispatchQueue.main.async {
                    self?.reloadInput.accept(.scrollToItem(index: indexPath.item, at: .top, animated: true))
                }
            }
        case .reloadSectionHeader, .simulateClickState, .showLoading, .showErrorPage:
            return
        case .present(let provider, let popoverConfig):
            actionInput.accept(.copyFile(completion: { [weak self] hostController in
                let controller = provider(hostController.view)
                self?.actionInput.accept(.present(viewController: controller,
                                            popoverConfiguration: popoverConfig,
                                            completion: {
                    if let dialog = controller as? UDDialog, dialog.customMode == .input {
                        dialog.textField.becomeFirstResponder()
                    }
                }))
            }))
        case .dismiss(let controller):
            controller?.dismiss(animated: true)
        case .push(let controller):
            actionInput.accept(.push(viewController: controller))
        case let .pushURL(url):
            actionInput.accept(.dismissPresentedVC)
            actionInput.accept(.openURL(url: url, context: nil))
        case let .showHUD(subAction):
            handleHUDAction(action: subAction)
        case .hideHUD:
            actionInput.accept(.hideHUD)
        case .customAction(let compeletion):
            actionInput.accept(.copyFile(completion: compeletion))
        }
    }
    
    private func handleHUDAction(action: WikiTreeViewAction.HUDAction) {
        switch action {
        case let .customLoading(text):
            actionInput.accept(.showHUD(.customLoading(text)))
        case let .failure(text):
            actionInput.accept(.showHUD(.failure(text)))
        case let .success(text):
            actionInput.accept(.showHUD(.success(text)))
        case let .tips(text):
            actionInput.accept(.showHUD(.tips(text)))
        case let .custom(config, operationCallback):
            actionInput.accept(.showHUD(.custom(config: config, operationCallback: operationCallback)))
        }
    }
}

extension HomeTreeAssembleListSection: SpaceSectionLayout {
    public func itemSize(at index: Int, containerWidth: CGFloat) -> CGSize {
        switch listState {
        case .loading:
            return CGSize(width: containerWidth, height: 160)
        case let .normal(homeItem):
            guard index < homeItem.items.count else {
                return CGSize(width: containerWidth, height: 48)
            }
            let item = homeItem.items[index]
            switch item {
            case .loading, .empty, .error:
                // 仅个人目录树部分会有该case
                return CGSize(width: containerWidth, height: 360)
            case .item, .specialItem, .headerRoot:
                return CGSize(width: containerWidth, height: 48)
            }
        case .empty, .error:
            spaceAssertionFailure("should have not the list state in homeTreeAssembleSection")
            return CGSize(width: 0, height: 0)
        }
    }
    
    public func sectionInsets(for containerWidth: CGFloat) -> UIEdgeInsets {
        .zero
    }
    
    public func minimumLineSpacing(for containerWidth: CGFloat) -> CGFloat {
        .zero
    }
    
    public func minimumInteritemSpacing(for containerWidth: CGFloat) -> CGFloat {
        .zero
    }
    
    public func headerHeight(for containerWidth: CGFloat) -> CGFloat {
        .zero
    }
    
    public func footerHeight(for containerWidth: CGFloat) -> CGFloat {
        .zero
    }
    
}

extension HomeTreeAssembleListSection: SpaceSectionDataSource {
    public var numberOfItems: Int {
        switch listState {
        case .error, .empty:
            return 0
        case .loading:
            return 1
        case let .normal(homeItem):
            return homeItem.items.count
        }
    }
    
    public func setup(collectionView: UICollectionView) {
        collectionView.register(HomeTreeViewCell.self, forCellWithReuseIdentifier: HomeTreeViewCell.reuseIdentifier)
        collectionView.register(HomeTreeViewEmptyCell.self, forCellWithReuseIdentifier: HomeTreeViewEmptyCell.reuseIdentifier)
        collectionView.register(HomeLoadingViewCell.self, forCellWithReuseIdentifier: HomeLoadingViewCell.reuseIdentifier)
        
        collectionView.register(HomeTreeSpecialClickCell.self, forCellWithReuseIdentifier: HomeTreeSpecialClickCell.reuseIdentifier)
        collectionView.register(HomeTreeHeaderViewCell.self, forCellWithReuseIdentifier: HomeTreeHeaderViewCell.reuseIdentifier)
        
        collectionView.register(HomePersonalFailedView.self, forCellWithReuseIdentifier: HomePersonalFailedView.reuseIdentifier)
        collectionView.register(HomePersonalEmptyView.self, forCellWithReuseIdentifier: HomePersonalEmptyView.reuseIdentifier)
        
        collectionView.rx.didScroll.subscribe(onNext: { [weak self] in
            self?.mutexHelper.listViewDidScroll()
        })
        .disposed(by: disposeBag)
    }
    
    public func cell(at indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell {
        switch listState {
        case let .normal(homeItem):
            let index = indexPath.item
            guard index < homeItem.items.count else {
                DocsLogger.error("home tree assemble section: cell index bounds the listdata range")
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomePersonalFailedView.reuseIdentifier, for: indexPath)
                return cell
            }
            let item = homeItem.items[index]
            switch item {
            case let .item(node):
                switch node.type {
                case .empty:
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeTreeViewEmptyCell.reuseIdentifier, for: indexPath)
                    guard let emptyCell = cell as? HomeTreeViewEmptyCell else {
                        return cell
                    }
                    emptyCell.update(title: node.title, level: node.level)
                    return emptyCell
                case .normal:
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeTreeViewCell.reuseIdentifier, for: indexPath)
                    guard let nodeCell = cell as? HomeTreeViewCell else {
                        return cell
                    }
                    nodeCell.updateModel(node)
                    nodeCell.content.clickStateSignal.emit(onNext: { [weak self, weak nodeCell] in
                        if !node.isOpened {
                            nodeCell?.content.nodeLoadingView.isHidden = false
                            nodeCell?.content.nodeLoadingView.play()
                            nodeCell?.content.stateButton.isHidden = true
                            self?.markNodeAsLoading(indexPath: indexPath)
                        }
                        node.clickStateAction(indexPath)
                    }).disposed(by: nodeCell.reuseBag)
                    
                    nodeCell.content.titleButton.rx.tap.subscribe(onNext: {
                        node.clickContentAction(indexPath)
                    }).disposed(by: nodeCell.reuseBag)
                    
                    nodeCell.configSlideItem { [weak self] in
                        guard let self else {
                            return (nil, nil)
                        }
                        let slideItems = self.viewModel.configSlidItem(node: node)
                        return (slideItems, self.mutexHelper)
                    }
                    
                    nodeCell.configHomeHoverItem { [weak self] in
                        let items = self?.viewModel.configHoverItem(node: node)
                        return items
                    }
                    
                    return nodeCell
                case .wikiSpace:
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeTreeViewCell.reuseIdentifier, for: indexPath)
                    guard let nodeCell = cell as? HomeTreeViewCell else {
                        return cell
                    }
                    nodeCell.updateModel(node)
                    nodeCell.content.clickStateSignal.emit(onNext: { [weak self, weak nodeCell] in
                        if !node.isOpened {
                            nodeCell?.content.nodeLoadingView.isHidden = false
                            nodeCell?.content.nodeLoadingView.play()
                            nodeCell?.content.stateButton.isHidden = true
                            self?.markNodeAsLoading(indexPath: indexPath)
                        }
                        node.clickStateAction(indexPath)
                    }).disposed(by: nodeCell.reuseBag)
                    nodeCell.content.titleButton.rx.tap.subscribe(onNext: { [weak self, weak nodeCell] in
                        if !node.isOpened {
                            /// 知识库节点点击展开时，也需要展示loding动画
                            nodeCell?.content.nodeLoadingView.isHidden = false
                            nodeCell?.content.nodeLoadingView.play()
                            nodeCell?.content.stateButton.isHidden = true
                            self?.markNodeAsLoading(indexPath: indexPath)
                        }
                        node.clickContentAction(indexPath)
                    }).disposed(by: nodeCell.reuseBag)
                    nodeCell.configHomeHoverItem { nil }
                    return nodeCell
                }
            case let .specialItem(title):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeTreeSpecialClickCell.reuseIdentifier, for: indexPath)
                guard let clickCell = cell as? HomeTreeSpecialClickCell else {
                    return cell
                }
                clickCell.update(title: title)
                clickCell.button.rx.controlEvent(.touchUpInside)
                    .subscribe(onNext: { [weak self] _ in
                        self?.viewModel.clickSpecialExtraItem()
                    })
                    .disposed(by: clickCell.reuseBag)
                return clickCell
            case .empty:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomePersonalEmptyView.reuseIdentifier, for: indexPath)
                guard let emptyCell = cell as? HomePersonalEmptyView else {
                    return cell
                }
                emptyCell.createButton.rx.tap.asSignal()
                    .emit(onNext: { [weak self, weak emptyCell] in
                        guard let self, let emptyCell else { return }
                        self.viewModel.personalViewModel.createOnRoot(sourceView: emptyCell.createButton)
                    }).disposed(by: emptyCell.reuseBag)
                return cell
            case .loading:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeLoadingViewCell.reuseIdentifier, for: indexPath)
                return cell
            case .error:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomePersonalFailedView.reuseIdentifier, for: indexPath)
                return cell
            case let .headerRoot(scene, isExpand, showCreateButton):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeTreeHeaderViewCell.reuseIdentifier, for: indexPath)
                guard let headerView = cell as? HomeTreeHeaderViewCell else {
                    return cell
                }
                headerView.update(title: scene.headerTitle)
                headerView.updateState(isExpand: isExpand, scene: scene)
                headerView.createButton.isHidden = !showCreateButton
                
                headerView.containerView.rx.controlEvent(.touchUpInside).subscribe(onNext: { [weak self, weak headerView] _ in
                    DocsLogger.info("home.assemble.tree: click header node, type: \(scene), expandStatus: \(isExpand)")
                    self?.viewModel.clickHeaderView(scene: scene, expand: !isExpand)
                    headerView?.updateState(isExpand: !isExpand, scene: scene)
                    
                    SpaceNewHomeTracker.reportSpaceHomeTreeClick(scene: scene, isExpand: !isExpand)
                })
                .disposed(by: headerView.reuseBag)
                
                headerView.createButton.rx.tap.subscribe(onNext: { [weak self, weak headerView] _ in
                    guard let headerView, scene == .personal else { return }
                    self?.viewModel.personalViewModel.createOnRoot(sourceView: headerView)
                })
                .disposed(by: headerView.reuseBag)
                
                return headerView
            }
        case .error, .empty:
            spaceAssertionFailure("should have not the list state in home assemble tree list section")
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomePersonalFailedView.reuseIdentifier, for: indexPath)
            return cell
        case .loading:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeLoadingViewCell.reuseIdentifier, for: indexPath)
            return cell
        }
    }
    
    private func markNodeAsLoading(indexPath: IndexPath) {
        dataQueue.async { [weak self] in
            guard let self else { return }
            let listState = self.differ.currentState
            guard case var .normal(listData) = listState else {
                return
            }
            var items = listData.items
            guard indexPath.item < items.count else {
                return
            }
            let item = items[indexPath.item]
            guard case var .item(node) = item else {
                return
            }
            node.isLoading = true
            items[indexPath.item] = .item(node: node)
            listData.items = items
            self.differ.reset(newState: .normal(homeItem: listData))
        }
    }
    
    public func supplymentaryElementView(kind: String, indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionReusableView {
        assertionFailure()
        return UICollectionReusableView()
    }
    
    public func dragItem(at indexPath: IndexPath, sceneSourceID: String?, collectionView: UICollectionView) -> [UIDragItem] {
        []
    }
    
}

extension HomeTreeAssembleListSection: SpaceSectionDelegate {
    public func didSelectItem(at indexPath: IndexPath, collectionView: UICollectionView) {

    }
    
    @available(iOS 13.0, *)
    public func contextMenuConfig(at indexPath: IndexPath, sceneSourceID: String?, collectionView: UICollectionView) -> UIContextMenuConfiguration? {
        nil
    }
}

extension HomeTreeAssembleListSection: SpaceListSubSection {
    public var createIntent: SpaceCreateIntent {
        SpaceCreateIntent(context: .recent, source: .recent, createButtonLocation: .bottomRight)
    }
    
    public var listTools: [SpaceListTool] {
        []
    }
    
    public var subSectionIdentifier: String {
        "homeAssembleTree"
    }
    
    public var subSectionTitle: String {
        BundleI18n.SKResource.LarkCCM_NewCM_Sidebar_Mobile_Contents_Tab
    }
    
    public func didShowSubSection() {
        viewModel.didBecomeActive()
        self.actionInput.accept(.stopPullToLoadMore(hasMore: false))
    }
    
    public func willHideSubSection() {
        viewModel.willResignActive()
    }

    public func reportClick(fromSubSectionId previousSubSectionId: String) {
        guard let previousModule = PageModule.typeFor(tabID: previousSubSectionId) else {
            DocsLogger.debug("Can not retrieve PageModule for " +
                             "previous sub section id(\(previousSubSectionId)")
            return
        }

        guard let params = SpacePageClickParameter.typeFor(subTab: subSectionIdentifier) else {
            DocsLogger.debug("Can not retrieve SpacePageClickParameter for " +
                             "current sub section id(\(subSectionIdentifier)")
            return
        }

        let bizParms = SpaceBizParameter(module: previousModule)
        DocsTracker.reportSpaceHomePageClick(params: params, bizParms: bizParms)
    }
}
