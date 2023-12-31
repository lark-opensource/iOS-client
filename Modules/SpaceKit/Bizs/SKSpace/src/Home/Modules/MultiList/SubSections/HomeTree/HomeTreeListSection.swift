//
//  HomeClipListSection.swift
//  SKSpace
//
//  Created by majie.7 on 2023/5/18.
//
// disable-lint: magic number

import Foundation
import RxCocoa
import RxSwift
import SKWorkspace
import SKCommon
import SKFoundation
import SKUIKit
import SKResource
import UniverseDesignDialog
import LarkContainer

public final class HomeTreeListSection: SpaceSection {
    public var identifier: String {
        "space.home.\(scene.rawValue).section"
    }
    
    private let reloadInput = PublishRelay<ReloadAction>()
    public var reloadSignal: Signal<ReloadAction> {
        reloadInput.asSignal()
    }
    
    private let actionInput = PublishRelay<Action>()
    public var actionSignal: Signal<Action> {
        actionInput.asSignal()
    }
    
    private let disposeBag = DisposeBag()
    private var headerViewDisposeBag = DisposeBag()
    
    private let scene: HomeTreeSectionScene
    private let viewModel: HomeTreeSectionViewModel
    private var listState: HomeListState  = .loading
        
    // 实现 section内的item侧滑互斥
    private let mutexHelper: SKCustomSlideMutexHelper
    private lazy var differ = HomeListStateDiffer(initialState: listState, differ: HomeViewListDiffer())
    private let dataQueue = DispatchQueue(label: "home.tree.section.dataQueue")
    private(set) lazy var dataQueueScheduler = SerialDispatchQueueScheduler(queue: dataQueue,
                                                                            internalSerialQueueName: "home.tree.section.dataQueueScheduler")
    
    public let userResolver: UserResolver
    
    public init(userResolver: UserResolver,
                scene: HomeTreeSectionScene,
                viewModel: HomeTreeSectionViewModel,
                slideMutexHelper: SKCustomSlideMutexHelper) {
        self.userResolver = userResolver
        self.scene = scene
        self.viewModel = viewModel
        self.mutexHelper = slideMutexHelper
    }
    
    public func prepare() {
        bindData()
        viewModel.prepare()
    }
    
    private func bindData() {
        viewModel.actionSignal.emit(to: actionInput).disposed(by: disposeBag)
        viewModel.listStateRelay
            .observeOn(dataQueueScheduler)
            .subscribe(onNext: { [weak self] listState in
                self?.handle(state: listState)
            })
            .disposed(by: disposeBag)

        viewModel.scrollToItemSignal.asObservable()
            .observeOn(dataQueueScheduler)
            .subscribe(onNext: { [weak self] index in
                DispatchQueue.main.async {
                    self?.reloadInput.accept(.scrollToItem(index: index, at: .centeredVertically, animated: true))
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.dataProvider.wikiActionInput
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] action in
                self?.handle(action: action)
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
        viewModel.reloadList { [weak self] in
            self?.actionInput.accept(.stopPullToRefresh(total: nil))
        }
    }
    
    public func notifyPullToLoadMore() {
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
                    self?.reloadInput.accept(.scrollToItem(index: indexPath.item, at: .centeredVertically, animated: true))
                }
            }
        case .reloadSectionHeader(let section, let node):
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
        case .simulateClickState(let nodeUID):
            return
        case .showLoading:
            return
        case .showErrorPage(let view):
            return
        case let .showHUD(subAction):
            handleHUDAction(action: subAction)
        case .hideHUD:
            actionInput.accept(.hideHUD)
        case .customAction(let compeletion):
            // TODO: 移除掉copyFile 这个case
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


extension HomeTreeListSection: SpaceSectionLayout {
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
            case .specialItem, .item:
                return CGSize(width: containerWidth, height: 48)
            case .headerRoot, .loading, .empty, .error:
                spaceAssertionFailure("home tree list section should have not these item type, just for assemble home tree")
                return CGSize(width: containerWidth, height: 0)
            }
        case .empty, .error:
            //数据为空或失败直接隐藏
            return CGSize(width: 0, height: 0)
        }
    }
    
    public func sectionInsets(for containerWidth: CGFloat) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)
    }
    
    public func minimumLineSpacing(for containerWidth: CGFloat) -> CGFloat {
        .zero
    }
    
    public func minimumInteritemSpacing(for containerWidth: CGFloat) -> CGFloat {
        .zero
    }
    
    public func headerHeight(for containerWidth: CGFloat) -> CGFloat {
        switch listState {
        case .loading, .empty, .error:
            return 0
        case .normal:
            return 48
        }
    }
    
    public func footerHeight(for containerWidth: CGFloat) -> CGFloat {
        .zero
    }
    
    
}

extension HomeTreeListSection: SpaceSectionDataSource {
    public var numberOfItems: Int {
        switch listState {
        case .error:
            return 0
        case .normal(homeItem: let homeItem):
            return homeItem.items.count
        case .empty:
            return 0
        case .loading:
            return 1
        }
    }
    
    public func setup(collectionView: UICollectionView) {
        collectionView.register(HomeTreeSpecialClickCell.self, forCellWithReuseIdentifier: HomeTreeSpecialClickCell.reuseIdentifier)
        collectionView.register(HomeTreeHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: HomeTreeHeaderView.reuseIdentifier + scene.rawValue)
        collectionView.register(HomeTreeViewCell.self, forCellWithReuseIdentifier: HomeTreeViewCell.reuseIdentifier)
        collectionView.register(HomeTreeViewEmptyCell.self, forCellWithReuseIdentifier: HomeTreeViewEmptyCell.reuseIdentifier)
        collectionView.register(HomeLoadingViewCell.self, forCellWithReuseIdentifier: HomeLoadingViewCell.reuseIdentifier)
        collectionView.register(HomePersonalFailedView.self, forCellWithReuseIdentifier: HomePersonalFailedView.reuseIdentifier)
        
        collectionView.rx.didScroll.subscribe(onNext: { [weak self] in
            self?.mutexHelper.listViewDidScroll()
        })
        .disposed(by: disposeBag)
    }
    
    public func cell(at indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell {
        switch listState {
        case .loading:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeLoadingViewCell.reuseIdentifier, for: indexPath)
            return cell
        case .empty, .error:
            spaceAssertionFailure("empty or error should not show view")
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeLoadingViewCell.reuseIdentifier, for: indexPath)
            return cell
        case let .normal(homeItem):
            let index = indexPath.item
            guard index < homeItem.items.count else {
                DocsLogger.error("home clip section: cell index bounds the listdata range")
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeTreeViewCell.reuseIdentifier, for: indexPath)
                return cell
            }
            let item = homeItem.items[index]
            switch item {
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
            case .headerRoot, .loading, .empty, .error:
                spaceAssertionFailure("home tree list section should have not these item type, just for assemble home tree")
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomePersonalFailedView.reuseIdentifier, for: indexPath)
                return cell
            }
        }
    }
    
    public func supplymentaryElementView(kind: String, indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            headerViewDisposeBag = DisposeBag()
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HomeTreeHeaderView.reuseIdentifier + "\(scene.rawValue)", for: indexPath)
            guard let headerView = view as? HomeTreeHeaderView else {
                return view
            }
            let isExpand = self.viewModel.expandStateRelay.value
            headerView.update(title: scene.headerTitle)
            headerView.updateState(isExpand: isExpand)
            headerView.backgroundView.rx.controlEvent(.touchUpInside).subscribe(onNext: { [weak self, weak headerView] _ in
                guard let self else { return }
                let isExpand = self.viewModel.expandStateRelay.value
                self.viewModel.expandStateRelay.accept(!isExpand)
                headerView?.updateState(isExpand: !isExpand)
            }).disposed(by: headerViewDisposeBag)
            return headerView
        default:
            assertionFailure()
            return UICollectionReusableView()
        }
    }
    
    public func dragItem(at indexPath: IndexPath, sceneSourceID: String?, collectionView: UICollectionView) -> [UIDragItem] {
        []
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
    
}

extension HomeTreeListSection: SpaceSectionDelegate {
    public func didSelectItem(at indexPath: IndexPath, collectionView: UICollectionView) {
        
    }
    
    @available(iOS 13.0, *)
    public func contextMenuConfig(at indexPath: IndexPath, sceneSourceID: String?, collectionView: UICollectionView) -> UIContextMenuConfiguration? {
        nil
    }
    
    
}
