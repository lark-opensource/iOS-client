//
//  PostCategoryDetailViewController.swift
//  Moment
//
//  Created by liluobin on 2021/4/27.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignTabs
import LKCommonsLogging
import LarkMessageCore
import RxSwift
import RxCocoa
import LarkButton
import UniverseDesignEmpty
import LarkContainer

protocol PostListVCDelegate: AnyObject {
    func listWillAppear(_ tableView: MomentLinkagePostTableView)
    func exitCurrentPostList()
    func willRefreshTableData()
}

protocol BasePostListViewModelProtocol: AnyObject {
    var uiDataSource: [MomentPostCellViewModel] { get }
    var tableRefreshDriver: Driver<PostList.TableRefreshType> { get }
    var errorDri: Driver<PostList.ErrorType> { get }
    var tracker: MomentsCommonTracker { get }
    var manageMode: RawData.ManageMode { get }
    func resumeQueue()
    func pauseQueue()
    func fetchFirstScreenPosts()
    func refreshPosts(finish: @escaping (ScrollViewLoadMoreResult) -> Void)
    func loadMorePosts(finish: @escaping (ScrollViewLoadMoreResult) -> Void)
    func getPageType() -> MomentsTracer.PageType
    func getPageDetail() -> MomentsTracer.PageDetail?
    func endTrackFeedItem()
    func endTrackPolymerizationItem()
    func lastReadPostId() -> String?
}

class BasePostListViewController: BaseUIViewController,
                                  UDTabsListContainerViewDelegate,
                                  UITableViewDataSource,
                                  UITableViewDelegate,
                                  MenuObserverProtocol,
                                  UserTransitionCellManagerDelegate,
                                  MomentsPostListDelegate,
                                  UserResolverWrapper {
    let userResolver: UserResolver
    static let logger = Logger.log(BasePostListViewController.self, category: "Module.Moments.BasePostListViewController")
    let viewModel: BasePostListViewModelProtocol
    let disposeBag: DisposeBag = DisposeBag()
    weak var delegate: (PostListVCDelegate & FeedListDependencyDataDelegate)?
    private var isFirstAppear = true
    private lazy var cellManager: UserTransitionCellManager = {
        let manager = UserTransitionCellManager()
        manager.delegate = self
        return manager
    }()

    @ScopedInjectedLazy private var momentsAccountService: MomentsAccountService?

    init(userResolver: UserResolver, viewModel: BasePostListViewModelProtocol) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    deinit {
        Self.logger.info("BasePostListViewController deinit")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var feedPageShowClickTracker: MomentsFeedPageShowClickTracker = {
        return MomentsFeedPageShowClickTracker(pageType: viewModel.getPageType(), pageDetail: viewModel.getPageDetail())
    }()

    lazy var tableView: MomentLinkagePostTableView = {
        let table = MomentLinkagePostTableView()
        table.dataSource = self
        table.delegate = self
        table.tableFooterView = UIView(frame: .zero)
        table.enableTopPreload = false
        table.momentFeedTableViewDelegate = self
        table.backgroundColor = UIColor.ud.bgBody
        table.separatorStyle = .singleLine
        table.separatorInset = .zero
        /// UX 要求这里底部加上120的Inset
        table.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 120, right: 0)
        table.separatorColor = UIColor.ud.lineDividerDefault
        table.register(PostSkeletonlTableViewCell.self, forCellReuseIdentifier: PostSkeletonlTableViewCell.identifier)
        table.register(UserPostEmptyCell.self, forCellReuseIdentifier: UserPostEmptyCell.identifier)
        return table
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        isNavigationBarHidden = true
        setupView()
        observerMessageViewModel()

        self.momentsAccountService?.rxCurrentAccount
            .observeOn(MainScheduler.instance)
            .filter { account in
                account != nil
            }.subscribe { [weak self] _ in
                self?.loadFirstScreenData()
            }.disposed(by: disposeBag)
    }

    func loadFirstScreenData() {
        viewModel.fetchFirstScreenPosts()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        resetTableViewHeaderFrame()
        if isFirstAppear {
            //如果第一次加载 会在reloadData上报埋点，这里不重复上报
            isFirstAppear = false
            return
        }
        if let visibleRows = tableView.indexPathsForVisibleRows {
            for indexPath in visibleRows where indexPath.row < self.viewModel.uiDataSource.count {
                let post = self.viewModel.uiDataSource[indexPath.row].entity.post
                feedPageShowClickTracker.insert(postId: post.id, cirleId: post.circleID)
            }
            feedPageShowClickTracker.trackCommunityFeedCardView()
        }
    }

    private func observerMessageViewModel() {
        viewModel.tableRefreshDriver
            .drive(onNext: { [weak self] (refreshType) in
                switch refreshType {
                case .remoteFirstScreenDataRefresh(hasFooter: let hasFooter, style: let style):
                    self?.update(hasFooter: hasFooter)
                    self?.tableView.showPostTip(style, finishResetHeader: true)
                    self?.cellManager.firstScreenDataLoading = false
                    self?.reloadData()
                    self?.firstScreenLoadFinish(self?.viewModel.uiDataSource.isEmpty ?? false)
                    self?.viewModel.endTrackPolymerizationItem()
                case .refreshTable(needResetHeader: let needResetHeader, hasFooter: let hasFooter, style: let style):
                    if needResetHeader {
                        self?.tableView.showPostTip(style, finishResetHeader: true)
                    }
                    self?.delegate?.willRefreshTableData()
                    self?.update(hasFooter: hasFooter)
                    self?.reloadData()
                    self?.viewModel.endTrackFeedItem()
                case .refresh:
                    self?.reloadData()
                    self?.delegate?.willRefreshTableData()
                case .refreshCell(indexs: let indexPaths, animation: let animation):
                    self?.tableView.refresh(indexPaths: indexPaths, animation: animation, guarantLastCellVisible: false)
                }
            }).disposed(by: disposeBag)

        viewModel.errorDri
            .drive(onNext: { [weak self] (errorType) in
                switch errorType {
                case .fetchFirstScreenPostsFail(let error, _):
                    if self?.momentsAccountService?.handleOfficialAccountErrorIfNeed(error: error, from: self) == true {
                        return
                    }
                    self?.tableView.showPostTip(.fail, finishResetHeader: true)
                    self?.update(hasFooter: false)
                    self?.cellManager.firstScreenDataLoading = false
                    self?.reloadData()
                    self?.onLoadError(error)
                case .loadMoreFail(let error):
                    self?.tableView.endBottomLoadMore(hasMore: true)
                    if self?.momentsAccountService?.handleOfficialAccountErrorIfNeed(error: error, from: self) == true {
                        return
                    }
                    self?.onLoadError(error)
                case .refreshListFail(let error):
                    self?.tableView.showPostTip(.fail, finishResetHeader: true)
                    if self?.momentsAccountService?.handleOfficialAccountErrorIfNeed(error: error, from: self) == true {
                        return
                    }
                    self?.onLoadError(error)
                }
            }).disposed(by: disposeBag)
    }

    func onLoadError(_ error: Error) {
    }

    func autoRefresh() {
        self.tableView.scrollToTop(animated: false)
        /// 列表的滑动受到父Scrollview的影响
        if !tableView.canMove {
            tableView.canMove = true
        }
        self.tableView.topLoadMoreView?.beginRefresh()
    }

    func getPageType() -> MomentsTracer.PageType {
        return viewModel.getPageType()
    }

    func getTracker() -> MomentsCommonTracker {
        return viewModel.tracker
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if cellManager.isTransitionStatus() {
            let cell = cellManager.cellForTableView(tableView, indexPath: indexPath)
            cell.separatorInset = .zero
            return cell
        }
        let cellVM = viewModel.uiDataSource[indexPath.row]
        let cellId = cellVM.entity.post.id
        let cell = cellVM.dequeueReusableCell(tableView, cellId: cellId)
        let left = (cellId == self.viewModel.lastReadPostId() ? self.view.frame.width : 0)
        cell.separatorInset = UIEdgeInsets(top: 0, left: left, bottom: 0, right: 0)
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if cellManager.isTransitionStatus() {
            return cellManager.numberOfCell()
        }
        return viewModel.uiDataSource.count
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if cellManager.isTransitionStatus() {
            return cellManager.cellHeight()
        }
        return viewModel.uiDataSource[indexPath.row].renderer.size().height
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if cellManager.isTransitionStatus() {
            return cellManager.cellHeight()
        }
        return viewModel.uiDataSource[indexPath.row].renderer.size().height
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil, !cellManager.isTransitionStatus() else { return }
        let cellVM = viewModel.uiDataSource[indexPath.row]
        cellVM.didSelect()
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard !cellManager.isTransitionStatus(), indexPath.row < self.viewModel.uiDataSource.count else {
            return
        }
        // 在屏幕内的才触发vm的willDisplay
        if tableView.indexPathsForVisibleRows?.contains(indexPath) ?? false {
            self.viewModel.uiDataSource[indexPath.row].willDisplay()
            let post = self.viewModel.uiDataSource[indexPath.row].entity.post
            self.feedPageShowClickTracker.insert(postId: post.id, cirleId: post.circleID)
        }
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard !cellManager.isTransitionStatus(), indexPath.row < self.viewModel.uiDataSource.count else {
            return
        }
        // 不在屏幕内的才触发didEndDisplaying
        if !(tableView.indexPathsForVisibleRows?.contains(indexPath) ?? false) {
            self.viewModel.uiDataSource[indexPath.row].didEndDisplay()
            let post = self.viewModel.uiDataSource[indexPath.row].entity.post
            self.feedPageShowClickTracker.remove(postId: post.id)
        }
    }

    func update(hasFooter: Bool) {
        self.tableView.hasFooter = hasFooter
        if !hasFooter {
            let footer = NoMoreFeedPostFooter(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: 68))
            footer.delegate = self
            self.tableView.tableFooterView = footer
        } else {
            self.tableView.tableFooterView = UIView(frame: .zero)
        }
    }

    func reloadData() {
        let isEmpty = self.viewModel.uiDataSource.isEmpty
        cellManager.isEmptyData = isEmpty
        self.tableView.separatorStyle = isEmpty ? .none : .singleLine
        if let footer = self.tableView.tableFooterView as? NoMoreFeedPostFooter {
            footer.isHidden = isEmpty
        }
        self.tableView.reloadData()
        DispatchQueue.main.async {
            self.feedPageShowClickTracker.trackCommunityFeedCardView()
        }
    }

    func setupView() {
        self.view.backgroundColor = UIColor.clear
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    func pauseQueue() {
        self.viewModel.pauseQueue()
    }
    func resumeQueue() {
        self.viewModel.resumeQueue()
    }

    func listView() -> UIView {
        return self.view
    }
    func listWillAppear() {
        self.delegate?.listWillAppear(tableView)
    }

    func firstScreenLoadFinish(_ isEmpty: Bool) {
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.tableView.scrollViewDidScroll(scrollView)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if cellManager.isTransitionStatus() {
            return
        }
        self.feedPageShowClickTracker.trackCommunityFeedCardView()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate || cellManager.isTransitionStatus() {
            return
        }
        self.feedPageShowClickTracker.trackCommunityFeedCardView()
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        MomentsTracer.trackFeedPageViewClick(.slide,
                                             circleId: delegate?.requestForCircleId(),
                                             type: viewModel.getPageType(),
                                             detail: viewModel.getPageDetail())
    }

    func emptyBtnStyle() -> (String, TypeButton.Style?)? {
        return nil
    }

    func emptyTitle() -> String {
        return BundleI18n.Moment.Lark_Community_ShareAPost
    }

    func emptyType() -> UDEmptyType {
        return .noPost
    }
    func emptyBtnClick() {
    }

    func resizeWhenHostSizeWidthChange() {
        viewModel.uiDataSource.forEach { cellVM in
            cellVM.onResize()
        }
        reloadData()
    }

    func resetTableViewHeaderFrame() {
        tableView.topLoadMoreView?.resetFrame()
    }
}

extension BasePostListViewController: MomentFeedTableViewDelegate {
    func refreshPosts(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        viewModel.refreshPosts(finish: finish)
    }

    func loadMorePosts(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        viewModel.loadMorePosts(finish: finish)
    }

    func cellViewModel(indexPath: IndexPath) -> PolybasicCellViewModelProtocol {
        return viewModel.uiDataSource[indexPath.row]
    }

    func supportTopTipStyle() -> Bool {
        return self.userResolver.fg.dynamicFeatureGatingValue(with: "moments.new.refresh")
    }
}

extension BasePostListViewController: NoMoreFeedPostFooterDelegate {
    func attributedLabel(didSelectText text: String, didSelectRange range: NSRange) -> Bool {
        self.autoRefresh()
        return false
    }
}
