//
//  ListActivityRecordsViewController.swift
//  Todo
//
//  Created by wangwanxin on 2023/3/22.
//

import CTFoundation
import LarkContainer
import RxSwift
import RxCocoa
import LarkUIKit
import TodoInterface
import LarkSplitViewController
import UniverseDesignActionPanel

final class ListActivityRecordsViewController:
    BaseViewController, UserResolverWrapper,
    UICollectionViewDelegateFlowLayout,
    UICollectionViewDataSource,
    UICollectionViewDelegate {

    let viewModel: ListActivityRecordsViewModel
    let userResolver: LarkContainer.UserResolver

    @ScopedInjectedLazy private var routeDependency: RouteDependency?
    @ScopedInjectedLazy private var driveDependency: DriveDependency?

    private lazy var stateView: ListStateView = {
        return ListStateView(
            with: view,
            targetView: view,
            bottomInset: navigationController?.navigationBar.frame.height ?? 0,
            backgroundColor: UIColor.ud.bgBase
        )
    }()
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionHeadersPinToVisibleBounds = true
        layout.minimumLineSpacing = 0
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.showsVerticalScrollIndicator = false
        view.alwaysBounceVertical = true
        view.dataSource = self
        view.delegate = self
        view.backgroundColor = UIColor.ud.bgBase
        view.clipsToBounds = true
        view.ctf.register(cellType: ActivityRecordContentCell.self)
        view.ctf.register(cellType: ActivityRecordCombineCell.self)
        view.ctf.register(headerViewType: ActivityRecordSectionHeader.self)
        return view
    }()

    private let disposeBag = DisposeBag()

    init(resolver: LarkContainer.UserResolver, viewModel: ListActivityRecordsViewModel) {
        self.userResolver = resolver
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubview()
        bindViewState()
        setupViewModel()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateViewWidth()
    }

    override func closeBtnTapped() {
        closeViewController(userResolver)
    }

    private func setupSubview() {
        if let controllers = navigationController?.viewControllers,
           controllers.contains(self) && (controllers.count > 1) {
            addBackItem()
        } else {
            // add close item
            let barItem = LKBarButtonItem(image: nil, title: I18N.Todo_Common_Cancel, fontStyle: .regular)
            barItem.button.titleLabel?.textColor = UIColor.ud.textTitle
            barItem.button.addTarget(self, action: #selector(closeBtnTapped), for: .touchUpInside)
            navigationItem.leftBarButtonItem = barItem
        }
        title = viewModel.title
        view.backgroundColor = UIColor.ud.bgBase
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(
                UIEdgeInsets(
                    top: 0,
                    left: ListActivityRecordsViewModel.Config.leftPadding,
                    bottom: 0,
                    right: ListActivityRecordsViewModel.Config.rightPadding
                )
            )
        }
        stateView.retryHandler = { [weak self] in self?.viewModel.retryFetch() }
    }

    private func bindViewState() {
        viewModel.onTapImage = { [weak self] (index, images, sourceImage) in
            guard let self = self else { return }
            self.routeDependency?.previewImages(
                .property(images),
                sourceIndex: index,
                sourceView: sourceImage,
                from: self
            )
        }
        viewModel.rxListUpdate
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onNext: { [weak self] type in
                    guard let self = self else { return }
                    switch type {
                    case .reload:
                        self.reloadData()
                    case .reloadIndex(let indexPath):
                        guard self.collectionView.cellForItem(at: indexPath) != nil else {
                            self.reloadData()
                            return
                        }
                        self.collectionView.performBatchUpdates {
                            self.collectionView.reloadItems(at: [indexPath])
                        }
                    }
                })
            .disposed(by: disposeBag)
        viewModel.rxLoadMoreState.distinctUntilChanged()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onNext: { [weak self] state in
                    guard let self = self else { return }
                    self.updateLoadMore(state: state)
                })
            .disposed(by: disposeBag)
        viewModel.rxViewState.distinctUntilChanged()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] state in
                self?.stateView.updateViewState(
                    state: state,
                    emptyType: .noContent,
                    emptyTitle: I18N.Todo_Activities_NoActivities_Empty_Title,
                    emptyDescription: I18N.Todo_Activities_NoActivities_Empty_Desc
                )
            })
            .disposed(by: disposeBag)
    }

    private func setupViewModel() {
        updateViewWidth()
        viewModel.setup()
    }

    private func updateViewWidth() {
        let width = navigationController?.view.bounds.size.width ?? view.bounds.size.width
        viewModel.collectionViewWidth = width - ListActivityRecordsViewModel.Config.leftPadding - ListActivityRecordsViewModel.Config.rightPadding
    }

    private func reloadData() {
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.layoutIfNeeded()
        collectionView.reloadData()
    }

    // MARK: - CollectionView

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return viewModel.itemSize(at: indexPath, and: collectionView.frame.width)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return viewModel.itemSpace()
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection
                            section: Int
    ) -> CGSize {
        return viewModel.sectionHeaderSize(in: section, and: collectionView.frame.width)
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.numberOfSections()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfItems(in: section)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let itemInfo = viewModel.itemInfo(at: indexPath) else { return UICollectionViewCell() }
        switch itemInfo {
        case .content(let data):
            guard let cell = collectionView.ctf.dequeueReusableCell(ActivityRecordContentCell.self, for: indexPath) else {
                return UICollectionViewCell()
            }
            let tuple = viewModel.itemCorner(at: indexPath)
            cell.viewData = data
            cell.delegate = self
            cell.showSeparateLine = !tuple.corners.contains([.layerMinXMaxYCorner, .layerMaxXMaxYCorner])
            cell.lu.addCorner(
                corners: tuple.corners,
                cornerSize: tuple.cornerSize
            )
            cell.clipsToBounds = true
            return cell
        case .combine(let data):
            guard let cell = collectionView.ctf.dequeueReusableCell(ActivityRecordCombineCell.self, for: indexPath) else {
                return UICollectionViewCell()
            }
            cell.viewData = data
            return cell
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            guard let header = collectionView.ctf.dequeueReusableHeaderView(ActivityRecordSectionHeader.self, for: indexPath),
                  let data = viewModel.sectionHeader(in: indexPath.section) else {
                return UICollectionReusableView()
            }
            header.viewData = data
            return header
        default:
            return UICollectionReusableView()
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) else { return }
        guard let item = viewModel.itemInfo(at: indexPath) else {
            ActivityRecord.logger.error("can't find item")
            return
        }
        guard viewModel.scene != .task else { return }
        switch item {
        case .content(let data):
            showDetailVC(data)
        case .combine(let data):
            showActionSheet(data, from: cell)
        }
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard viewModel.needPreload(at: indexPath) else { return }
        viewModel.loadMore(silent: true)
    }

    private func showDetailVC(_ data: ActivityRecordContentData) {
        guard let data = data.metaData else { return }
        switch data.targetType {
        case .task:
            showTask(with: data.relatedTaskGuid)
        case .taskList:
            if viewModel.scene == .user, let taskListGuid = data.relatedTaskListGuids.first {
                showTaskList(with: taskListGuid)
            }
        @unknown default: break
        }

    }

    private func showActionSheet(_ data: ActivityRecordCombineData, from source: UIView) {
        guard let actions = viewModel.taskListActions(data.metaData) else {
            return
        }
        // 只有一个的时候，不需要跳转
        if actions.count == 1, let action = actions.first {
            showTaskList(with: action.guid)
            return
        }

        let source = UDActionSheetSource(
            sourceView: source,
            sourceRect: source.bounds,
            arrowDirection: .unknown
        )
        let config = UDActionSheetUIConfig(popSource: source)
        let actionSheet = UDActionSheet(config: config)
        actions.forEach { action in
            actionSheet.addItem(
                UDActionSheetItem(
                    title: action.name,
                    titleColor: UIColor.ud.textTitle,
                    action: { [weak self] in
                        self?.showTaskList(with: action.guid)
                    }
                )
            )
        }
        actionSheet.setCancelItem(text: I18N.Todo_Common_Cancel)
        present(actionSheet, animated: true, completion: nil)
    }

    private func showTaskList(with taskListGuid: String) {
        ActivityRecord.logger.info("did tap taskList item, guid: \(taskListGuid)")
        let vc = V3HomeViewController(resolver: userResolver, scene: .onePage(guid: taskListGuid))
        userResolver.navigator.push(vc, from: self)
    }
    
    private func showTask(with taskGuid: String) {
        let detailVC = DetailViewController(
            resolver: userResolver,
            input: .edit(guid: taskGuid, source: .activity, callbacks: .init())
        )
        if viewModel.scene == .taskList {
            userResolver.navigator.push(detailVC, from: self)
        } else {
            userResolver.navigator.showDetailOrPush(detailVC, wrap: LkNavigationController.self, from: self)
        }
    }

}

// MARK: - Load More State

extension ListActivityRecordsViewController {

    func updateLoadMore(state: ListLoadMoreState) {
        ActivityRecord.logger.info("updateLoadMoreState: \(state)")
        switch state {
        case .none:
            collectionView.es.removeRefreshFooter()
        case .noMore:
            collectionView.es.stopLoadingMore()
            collectionView.es.noticeNoMoreData()
        case .loading:
            setupFooterIfNeeded()
            collectionView.footer?.startRefreshing()
        case .hasMore:
            setupFooterIfNeeded()
            collectionView.es.resetNoMoreData()
            collectionView.es.stopLoadingMore()
        }
    }

    private func setupFooterIfNeeded() {
        if collectionView.footer != nil { return }
        collectionView.es.addInfiniteScrolling(animator: LoadMoreAnimationView()) { [weak self] in
            self?.viewModel.loadMore()
        }
    }
}

extension ListActivityRecordsViewController: ActivityRecordContentCellDelegate {

    func didTapUser(with userId: String, from cell: ActivityRecordContentCell) {
        guard collectionView.indexPath(for: cell) != nil else { return }
        ActivityRecord.logger.info("show profile with \(userId)")
        var routeParams = RouteParams(from: self)
        routeParams.openType = .push
        routeDependency?.showProfile(with: userId, params: routeParams)
    }

    func didTapUrl(with urlStr: String, from cell: ActivityRecordContentCell) {
        guard collectionView.indexPath(for: cell) != nil else { return }
        ActivityRecord.logger.info("did tap url: \(urlStr)")
        let taskList = ListActivityRecordsViewModel.AnchorPrefix.taskList
        let task = ListActivityRecordsViewModel.AnchorPrefix.task
        if urlStr.hasPrefix(taskList), let taskListGuid = urlStr.components(separatedBy: taskList).last {
            showTaskList(with: taskListGuid)
        } else if urlStr.hasPrefix(task), let taskGuid = urlStr.components(separatedBy: task).last {
            showTask(with: taskGuid)
        } else {
            do {
                let url = try URL.forceCreateURL(string: urlStr)
                guard let httpUrl = url.lf.toHttpUrl() else {
                    ActivityRecord.logger.error("url is not valid.")
                    return
                }
                userResolver.navigator.push(httpUrl, from: self)
            } catch {
                ActivityRecord.logger.error("forceCreateURL failed. err: \(error)")
            }
        }
    }

    func didTapGridImage(index: Int, images: [Rust.ImageSet], sourceView: UIImageView, from cell: ActivityRecordContentCell) {
        guard collectionView.indexPath(for: cell) != nil else { return }
        routeDependency?.previewImages(.imageSet(images), sourceIndex: index, sourceView: sourceView, from: self)
    }

    func didTapAttachment(with fileToken: String, from cell: ActivityRecordContentCell) {
        guard collectionView.indexPath(for: cell) != nil else { return }
        if presentingViewController == nil {
            driveDependency?.previewFile(from: self, fileToken: fileToken)
        } else {
            driveDependency?.previewFileInPresent(from: self, fileToken: fileToken)
        }
    }

    func didExpandAttachment(from cell: ActivityRecordContentCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        viewModel.expandAttach(at: indexPath)
    }

    func didExpandContent(from cell: ActivityRecordContentCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        viewModel.expandContent(at: indexPath)
    }
}
