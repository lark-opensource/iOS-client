//
//  PersonaListSection.swift
//  SKSpace
//
//  Created by majie.7 on 2023/5/23.
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

public final class HomePersonalSection: SpaceSection {
    public var identifier: String = "space.home.clip.section"
    private let dataQueue = DispatchQueue(label: "home.personal.section.dataQueue")
    private(set) lazy var dataQueueScheduler = SerialDispatchQueueScheduler(queue: dataQueue,
                                                                            internalSerialQueueName: "home.personal.section.dataQueueScheduler")

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
    
    private let viewModel: HomePersonalViewModel
    private var listState: HomeListState = .loading
    // 实现 section内的item侧滑互斥
    private let mutexHelper: SKCustomSlideMutexHelper
    private lazy var differ = HomeListStateDiffer(initialState: listState, differ: HomeViewListDiffer())
    private var coordinator: RefreshCoordinator
    
    public let userResolver: UserResolver
    // refreshCoordinator: 帮助处理异步流程串行化处理
    // slideMuetexHelper: 保证多个cell侧滑面板互斥收起
    public init(userResolver: UserResolver,
                refreshCoordinator: RefreshCoordinator,
                slideMutexHelper: SKCustomSlideMutexHelper) {
        self.userResolver = userResolver
        self.coordinator = refreshCoordinator
        self.mutexHelper = slideMutexHelper
        self.viewModel = HomePersonalViewModel(userResolver: userResolver, coordinator: refreshCoordinator)
    }

    public func prepare() {
        bindData()
        viewModel.prepare()
        actionInput.accept(.stopPullToLoadMore(hasMore: false))
    }
    
    private func bindData() {
        viewModel.actionSignal.emit(to: actionInput).disposed(by: disposeBag)
        viewModel.reloadSignal.emit(to: reloadInput).disposed(by: disposeBag)
        
        viewModel.listStateRelay
            .observeOn(dataQueueScheduler)
            .subscribe(onNext: { [weak self] state in
                self?.handle(state: state)
            })
            .disposed(by: disposeBag)
        
        viewModel.wikiTreeActionInput
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] action in
                self?.handle(action: action)
            })
            .disposed(by: disposeBag)
    }

    public func notifyPullToRefresh() {
        viewModel.treeViewModel?.reload(isRefresh: true)
    }

    public func notifyPullToLoadMore() {
    }
    
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
            viewModel.expandStateRelay.accept(true)
            dataQueue.async { [weak self] in
                DispatchQueue.main.async {
                    self?.reloadInput.accept(.scrollToItem(index: indexPath.item, at: .centeredVertically, animated: true))
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

extension HomePersonalSection: SpaceSectionLayout {
    public func itemSize(at index: Int, containerWidth: CGFloat) -> CGSize {
        switch listState {
        case .loading, .error:
            return CGSize(width: containerWidth, height: 160)
        case .empty:
            return CGSize(width: containerWidth, height: 340)
        case .normal:
            return CGSize(width: containerWidth, height: 48)
        }
    }

    public func sectionInsets(for containerWidth: CGFloat) -> UIEdgeInsets {
        UIEdgeInsets(top: 0, left: 0, bottom: 68, right: 0)
    }

    public func minimumLineSpacing(for containerWidth: CGFloat) -> CGFloat {
        .zero
    }

    public func minimumInteritemSpacing(for containerWidth: CGFloat) -> CGFloat {
        .zero
    }

    public func headerHeight(for containerWidth: CGFloat) -> CGFloat {
        if case .loading = listState {
            return 0
        }
        return 48
    }

    public func footerHeight(for containerWidth: CGFloat) -> CGFloat {
        .zero
    }

}

extension HomePersonalSection: SpaceSectionDataSource {
    public var numberOfItems: Int {
        switch listState {
        case .error, .loading, .empty:
            return 1
        case let .normal(homeItem):
            return homeItem.items.count
        }
    }

    public func setup(collectionView: UICollectionView) {
        collectionView.register(HomeTreeHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: HomeTreeHeaderView.reuseIdentifier + "personal")
        collectionView.register(HomeTreeViewCell.self, forCellWithReuseIdentifier: HomeTreeViewCell.reuseIdentifier)
        collectionView.register(HomeTreeViewEmptyCell.self, forCellWithReuseIdentifier: HomeTreeViewEmptyCell.reuseIdentifier)
        collectionView.register(HomePersonalFailedView.self, forCellWithReuseIdentifier: HomePersonalFailedView.reuseIdentifier)
        collectionView.register(HomeLoadingViewCell.self, forCellWithReuseIdentifier: HomeLoadingViewCell.reuseIdentifier)
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
                DocsLogger.error("home clip section: cell index bounds the listdata range")
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeTreeViewCell.reuseIdentifier, for: indexPath)
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
                        return self?.viewModel.configHoverItem(node: node)
                    }
                    return nodeCell
                case .wikiSpace:
                    spaceAssertionFailure("personal tree should not show wikispace node, only show mutil tree section")
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeTreeViewCell.reuseIdentifier, for: indexPath)
                    return cell
                }
            case .specialItem:
                spaceAssertionFailure("persoanl section tree node have not headr type node")
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeTreeViewEmptyCell.reuseIdentifier, for: indexPath)
                return cell
            case .headerRoot, .loading, .empty, .error:
                spaceAssertionFailure("persoanl section should have not these item type, just for assemble home tree")
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomePersonalFailedView.reuseIdentifier, for: indexPath)
                return cell
            }
        case .loading:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeLoadingViewCell.reuseIdentifier, for: indexPath)
            return cell
        case .empty:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomePersonalEmptyView.reuseIdentifier, for: indexPath)
            guard let emptyCell = cell as? HomePersonalEmptyView else {
                return cell
            }
            emptyCell.createButton.rx.tap.asSignal()
                .emit(onNext: { [weak self, weak emptyCell] in
                    guard let self, let emptyCell else { return }
                    self.viewModel.createOnRoot(sourceView: emptyCell.createButton)
                }).disposed(by: emptyCell.reuseBag)
            return emptyCell
        case .error:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomePersonalFailedView.reuseIdentifier, for: indexPath)
            return cell
        }
    }

    public func supplymentaryElementView(kind: String, indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            headerViewDisposeBag = DisposeBag()
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: HomeTreeHeaderView.reuseIdentifier + "personal", for: indexPath)
            guard let headerView = view as? HomeTreeHeaderView else {
                return view
            }
            let isExpand = self.viewModel.expandStateRelay.value
            headerView.update(title: BundleI18n.SKResource.LarkCCM_NewCM_Personal_Title)
            headerView.updateState(isExpand: isExpand)
            viewModel.createButtonStatusRelay.map { !$0 }.bind(to: headerView.createButton.rx.isHidden).disposed(by: headerViewDisposeBag)
            headerView.backgroundView.rx.controlEvent(.touchUpInside).subscribe(onNext: { [weak self, weak headerView] _ in
                guard let self else { return }
                let isExpand = self.viewModel.expandStateRelay.value
                self.viewModel.expandStateRelay.accept(!isExpand)
                headerView?.updateState(isExpand: !isExpand)
            }).disposed(by: headerViewDisposeBag)

            headerView.createButton.rx.tap.subscribe(onNext: { [weak self, weak headerView] _ in
                guard let headerView else { return }
                self?.viewModel.createOnRoot(sourceView: headerView.createButton)
            }).disposed(by: headerView.reuseBag)
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


extension HomePersonalSection: SpaceSectionDelegate {
    public func didSelectItem(at indexPath: IndexPath, collectionView: UICollectionView) {
        
    }

    @available(iOS 13.0, *)
    public func contextMenuConfig(at indexPath: IndexPath, sceneSourceID: String?, collectionView: UICollectionView) -> UIContextMenuConfiguration? {
        nil
    }


}
