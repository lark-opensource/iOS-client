//
//  WikiiPadHomePageViewController.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2023/9/21.
//

import UIKit
import SKFoundation
import SnapKit
import ESPullToRefresh
import RxSwift
import RxRelay
import RxCocoa
import SKResource
import SKUIKit
import SKCommon
import LarkSplitViewController
import LarkContainer
import SKWorkspace
import UniverseDesignColor
import SKInfra
import UniverseDesignIcon

public class WikiIPadHomePageViewController: BaseViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    private lazy var headerView: WikiIPadHeaderView = {
        let view = WikiIPadHeaderView(enableObeservable: viewModel.reachabilityRelay.asObservable())
        view.createView.onClickPanel = { [weak self] sourceView, createType in
            self?.confirmCreate(sourceView: sourceView, createType: createType)
        }
        return view
    }()

    private lazy var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 140, height: 196)
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.headerReferenceSize = CGSize(width: 0, height: 44)
        layout.sectionInset = UIEdgeInsets(top: 8, left: 24, bottom: 24, right: 24)
        layout.sectionHeadersPinToVisibleBounds = true
        return layout
    }()

    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = UDColor.bgBody
        view.register(WikiIPadSpaceCell.self, forCellWithReuseIdentifier: WikiIPadSpaceCell.reuseIdentifier)
        view.register(WikiHomePagePlaceHolderCell.self, forCellWithReuseIdentifier: WikiHomePagePlaceHolderCell.reuseIdentifier)
        view.register(WikiHomePageAllSpaceHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: WikiHomePageAllSpaceHeaderView.reuseIdentifier)
        view.dataSource = self
        view.delegate = self
        return view
    }()

    private lazy var refreshAnimator: WikiHomePageRefreshAnimator = {
        let refreshView = WikiHomePageRefreshAnimator(frame: .zero)
        return refreshView
    }()

    lazy var uploadHelper = WikiSelectFileHelper(hostViewController: self, triggerLocation: .wikiHome)
    let viewModel: WikiHomePageViewModelV2
    private var hasAppeared = false
    let bag = DisposeBag()

    public let userResolver: UserResolver
    
    private var viewWidth: CGFloat = 0.0

    // MARK: 列表状态
    private var isPinSpaceEmpty: Bool { viewModel.starSpaces.isEmpty }
    private var isAllSpaceEmpty: Bool { viewModel.spaces.isEmpty }

    public init(userResolver: UserResolver) {
        viewModel = WikiHomePageViewModelV2(userResolver: userResolver)
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
        viewModel.ui = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.post(name: .Docs.notifySelectedSpaceEntarnce, object: ("ipad_wiki", false))
        DocsLogger.info("wikiIpadHomePageViewController deinit")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPullToRefresh()
        setupLoadMoreFooter()

        viewModel.actionOutput.drive(onNext: { [weak self] action in
            self?.handle(action: action)
        })
        .disposed(by: bag)
    }

    private func setupUI() {
        supportSecondaryOnly = true
        supportSecondaryPanGesture = true
        keyCommandToFullScreen = true
        navigationBar.isHidden = true

        view.backgroundColor = UDColor.bgBody

        view.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
        }
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }

    private func setupPullToRefresh() {
        collectionView.es.addPullToRefreshOfDoc(animator: refreshAnimator) { [weak self] in
            self?.viewModel.refresh()
        }
    }

    private func setupLoadMoreFooter() {
        collectionView.es.addInfiniteScrollingOfDoc(animator: DocsThreeDotRefreshAnimator()) { [weak self] in
            self?.viewModel.loadMoreList()
        }
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.didAppear(isFirstTime: !hasAppeared)
        hasAppeared = true
        
        NotificationCenter.default.post(name: .Docs.notifySelectedSpaceEntarnce, object: ("ipad_wiki", true))
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.post(name: .Docs.notifySelectedSpaceEntarnce, object: ("ipad_wiki", false))
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { [weak self] context in
            UIView.animate(withDuration: context.transitionDuration, delay: 0) {
                self?.layout.invalidateLayout()
                self?.collectionView.layoutIfNeeded()
            }
        }
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        guard viewWidth != view.frame.width else {
            return
        }
        viewWidth = view.frame.width
        layout.invalidateLayout()
    }

    public override func splitSplitModeChange(splitMode: SplitViewController.SplitMode) {
        layout.invalidateLayout()
        collectionView.layoutIfNeeded()
    }

    private func handle(action: WikiHomeAction) {
        switch action {
        case let .updateNetworkState(isReachable):
            reloadData()
        case let .jumpToWikiTree(space):
            open(space: space)
        case let .jumpToCreateWikiPicker(sourceView):
            jumpToCreateWikiPicker(sourceView: sourceView)
        case .updatePlaceHolderView:
            // 兜底用 cell 实现了
            break
        case let .jumpToUploadList(mountToken):
            // 首页没有container_id
            let params: [String: Any] = ["container_id": "none", "container_type": "wiki"]
            DocsContainer.shared.resolve(DriveRouterBase.self)?.type()
                .showUploadListViewController(sourceViewController: self,
                                              folderToken: mountToken,
                                              scene: .workspace,
                                              params: params)
        case .getListError:
            break
        case .updateHeaderList:
            reloadData()
        case .updateList:
            reloadData()
        case .stopPullToRefresh:
            collectionView.es.stopPullToRefresh()
        case let .stopLoadMoreList(hasMore):
            collectionView.es.stopLoadingMore()
            if let hasMore {
                collectionView.footer?.noMoreData = !hasMore
                collectionView.footer?.isHidden = !hasMore
            }
        case let .present(controller):
            userResolver.navigator.present(controller, from: self)
        case .scrollHeaderView:
            // iPad 样式不需要定位
            break
        }
    }

    // MARK: - UICollectionViewDataSource
    private func reloadData() {
        collectionView.reloadData()
    }

    private var pinSectionIndex: Int {
        0
    }

    private var recentSectionIndex: Int {
        1
    }

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        2
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == recentSectionIndex {
            return isAllSpaceEmpty ? 1 : viewModel.spaces.count
        } else if section == pinSectionIndex {
            return viewModel.starSpaces.count
        } else {
            return 0
        }
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == recentSectionIndex {
            if isAllSpaceEmpty {
                // TODO: empty cell
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WikiHomePagePlaceHolderCell.reuseIdentifier, for: indexPath)
                guard let emptyCell = cell as? WikiHomePagePlaceHolderCell else {
                    spaceAssertionFailure()
                    return cell
                }
                emptyCell.update(message: viewModel.emptyListDescription)
                return emptyCell
            } else {
                return recentSpaceCell(collectionView: collectionView, indexPath: indexPath)
            }
        } else if indexPath.section == pinSectionIndex {
            return pinSpaceCell(collectionView: collectionView, indexPath: indexPath)
        } else {
            spaceAssertionFailure()
            return collectionView.dequeueReusableCell(withReuseIdentifier: WikiIPadSpaceCell.reuseIdentifier, for: indexPath)
        }
    }

    private func recentSpaceCell(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WikiIPadSpaceCell.reuseIdentifier, for: indexPath)
        guard let spaceCell = cell as? WikiIPadSpaceCell else {
            spaceAssertionFailure()
            return cell
        }
        guard indexPath.item < viewModel.spaces.count else {
            return cell
        }
        let space = viewModel.spaces[indexPath.item]
        spaceCell.updateUI(item: space)
        space.isTreeContentCached.drive { [weak self, weak spaceCell] hasCache in
            guard let self else { return }
            let enable = self.viewModel.isReachable || hasCache
            spaceCell?.set(enable: enable)
            spaceCell?.isUserInteractionEnabled = enable
        }
        .disposed(by: spaceCell.reuseBag)
        return spaceCell
    }

    private func pinSpaceCell(collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WikiIPadSpaceCell.reuseIdentifier, for: indexPath)
        guard let spaceCell = cell as? WikiIPadSpaceCell else {
            spaceAssertionFailure()
            return cell
        }
        guard indexPath.item < viewModel.starSpaces.count else {
            return cell
        }
        let space = viewModel.starSpaces[indexPath.item]
        spaceCell.updateUI(item: space)
        space.isTreeContentCached.drive { [weak self, weak spaceCell] hasCache in
            guard let self else { return }
            let enable = self.viewModel.isReachable || hasCache
            spaceCell?.set(enable: enable)
            spaceCell?.isUserInteractionEnabled = enable
        }
        .disposed(by: spaceCell.reuseBag)
        return spaceCell
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: WikiHomePageAllSpaceHeaderView.reuseIdentifier, for: indexPath)
        guard let headerView = view as? WikiHomePageAllSpaceHeaderView else {
            spaceAssertionFailure()
            return view
        }
        headerView.update(config: .regular)
        if indexPath.section == recentSectionIndex {
            headerView.titleLabel.text = BundleI18n.SKResource.LarkCCM_NewCM_Sidebar_Mobile_AllWorkspaces_Title
            headerView.setupFilterView(stateRelay: viewModel.filterStateRelay,
                                       clickEnable: viewModel.filterClickEnableRelay.asDriver(),
                                       showEnable: viewModel.filterShowEnableRelay.asDriver())
            headerView.clickHandler = { [weak self, weak headerView] in
                guard let headerView else { return }
                self?.viewModel.didClickFilter(sourceView: headerView.filterView)
            }
        } else if indexPath.section == pinSectionIndex {
            headerView.titleLabel.text = BundleI18n.SKResource.LarkCCM_NewCM_Sidebar_Mobile_PinWorkspaceToTop_Title
        }
        return headerView
    }

    // MARK: - UICollectionViewDelegateFlowLayout
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let space: WikiSpace
        if indexPath.section == recentSectionIndex {
            guard indexPath.item < viewModel.spaces.count else {
                return
            }
            space = viewModel.spaces[indexPath.item]
        } else if indexPath.section == pinSectionIndex {
            guard indexPath.item < viewModel.starSpaces.count else {
                return
            }
            space = viewModel.starSpaces[indexPath.item]
        } else {
            return
        }
        open(space: space)
    }

    private func open(space: WikiSpace) {
        let viewModel = WikiTreeCoverViewModel(userResolver: userResolver, space: space)
        let controller = WikiTreeCoverViewController(userResolver: userResolver, viewModel: viewModel, showWikiHomeWhenClosed: true)
        guard let larkSplitViewController,
              let primaryController = larkSplitViewController.viewController(for: .primary) else {
            spaceAssertionFailure()
            return
        }
        userResolver.navigator.push(controller, from: primaryController)
        userResolver.navigator.showDetail(WikiIPadDefaultDetailController(initialState: .loading), from: self)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == recentSectionIndex, isAllSpaceEmpty {
            return CGSize(width: collectionView.frame.width, height: 400)
        }
        return layout.itemSize
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == pinSectionIndex, isPinSpaceEmpty {
            return .zero
        }
        // FlowLayout 会在宽度有冗余时均分到 item 间距，但是我们希望统一把多余的空间展示在右侧，这里通过加大右侧的 inset 实现
        var insets = layout.sectionInset
        let avaiableWidth = collectionView.frame.width - insets.left - insets.right + layout.minimumInteritemSpacing
        let itemWidth = layout.itemSize.width + layout.minimumInteritemSpacing
        let extraRightInset = avaiableWidth.truncatingRemainder(dividingBy: itemWidth)
        insets.right += extraRightInset
        return insets
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == pinSectionIndex, isPinSpaceEmpty {
            return .zero
        }
        return layout.headerReferenceSize
    }

    @available(iOS 13.0, *)
    public func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let space: WikiSpace
        if indexPath.section == recentSectionIndex {
            if isAllSpaceEmpty {
                return nil
            }
            guard indexPath.item < viewModel.spaces.count else {
                return nil
            }
            space = viewModel.spaces[indexPath.item]
        } else if indexPath.section == pinSectionIndex {
            guard indexPath.item < viewModel.starSpaces.count else {
                return nil
            }
            space = viewModel.starSpaces[indexPath.item]
        } else {
            return nil
        }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            let icon = space.displayIsStar
            ? UDIcon.getContextMenuIconBy(key: .setTopCancelOutlined)
            : UDIcon.getContextMenuIconBy(key: .setTopOutlined)
            let title = space.displayIsStar
            ? BundleI18n.SKResource.LarkCCM_Wiki_UnpinWorkspace_Tooltip
            : BundleI18n.SKResource.LarkCCM_Wiki_PinWorkspace_Tooltip
            let action = UIAction(title: title, image: icon) { _ in
                self?.toggleSetTop(space: space)
            }
            return UIMenu(children: [action])
        }
    }

    private func toggleSetTop(space: WikiSpace) {
        guard viewModel.isReachable else { return }
        viewModel.setStarWikiSpace(space: space, sourceView: collectionView) { [weak self] isStar in
            guard let self else { return }
            if let index = self.viewModel.spaces.firstIndex { $0.spaceID == space.spaceID } {
                self.viewModel.spaces[index].isStar = isStar
                let updatedSpace = self.viewModel.spaces[index]
                if isStar {
                    self.viewModel.starSpaces.insert(updatedSpace, at: 0)
                }
            }
            if !isStar,
               let index = self.viewModel.starSpaces.firstIndex { $0.spaceID == space.spaceID } {
                   self.viewModel.starSpaces.remove(at: index)
               }
            self.collectionView.reloadSections([self.pinSectionIndex])
            if !isStar {
                self.viewModel.refreshHeaderList()
            }
        }
    }
}

extension WikiIPadHomePageViewController: WikiHomePageUIDelegate {
    var isiPadRegularSize: Bool {
        true
    }
}
