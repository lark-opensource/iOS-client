//
//  MomentsFeedListViewController.swift
//  Moment
//
//  Created by zc09v on 2021/1/5.
//

import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import LarkMessageCore
import EENavigator
import LarkMenuController
import UniverseDesignToast
import LarkContainer
import UniverseDesignTabs
import LarkRustClient
import UIKit
import LKCommonsLogging

protocol FeedListDependencyDataDelegate: AnyObject {
    func requestForCircleId() -> String?
}

protocol FeedListEventDelegate: AnyObject {
    func viewDidAppearForVC(_ vc: MomentsFeedListViewController)
    func didClickEmptyPageActionBtn()
    func invalidTabID(_ id: String)
    func getReactionMenuBarFromVC() -> UIViewController?
}

final class MomentsFeedListViewController: BaseUIViewController,
                                           UITableViewDataSource,
                                           MomentFeedTableViewDelegate,
                                           UITableViewDelegate,
                                           PageAPI,
                                           MenuObserverProtocol,
                                           MomentsTabsListContainerViewDelegate,
                                           MomentsPostListDelegate,
                                           UserResolverWrapper {
    static let logger = Logger.log(MomentsFeedListViewController.self, category: "Module.Moments.MomentsFeedListViewController")
    let userResolver: UserResolver
    private var isRegularStyle: Bool
    let viewModel: MomentFeedListViewModel
    private lazy var postCardTracker: PostCardViewTracker = {
        return PostCardViewTracker(source: .feed)
    }()
    private lazy var feedPageShowClickTracker: MomentsFeedPageShowClickTracker = {
        return MomentsFeedPageShowClickTracker(pageType: .tabInfo(self.viewModel.tabInfo), pageDetail: nil)
    }()
    var appearDate: Date = Date()
    weak var delegate: (FeedListEventDelegate & FeedListDependencyDataDelegate)?
    private lazy var tableBgView: UIView = {
        let tableBgView = UIView()
        tableBgView.backgroundColor = .ud.bgBody
        return tableBgView
    }()
    private lazy var tableView: MomentFeedTableView = {
        let table = MomentFeedTableView()
        table.dataSource = self
        table.delegate = self
        table.tableFooterView = UIView(frame: .zero)
        table.enableTopPreload = false
        table.momentFeedTableViewDelegate = self
        table.backgroundColor = UIColor.clear
        table.separatorStyle = .singleLine
        table.separatorInset = .zero
        table.separatorColor = UIColor.ud.lineDividerDefault
        table.register(PostSkeletonlTableViewCell.self, forCellReuseIdentifier: PostSkeletonlTableViewCell.identifier)
        table.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: self.animatedTabBarController?.tabbarHeight ?? 52, right: 0)
        return table
    }()

    private lazy var tableBlankHeaderView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: CGFloat.leastNormalMagnitude, height: self.isRegularStyle ? 12 : CGFloat.leastNormalMagnitude))
        view.backgroundColor = .clear
        return view
    }()
    private lazy var boardcastHeaderView: BoardcastHeaderView = {
        let headerView = BoardcastHeaderView()
        headerView.delegate = self
        return headerView
    }()

    private lazy var emptyView: MomentsEmptyView = {
        let emptyView: MomentsEmptyView
        if viewModel.tabInfo.isFollowTab {
            emptyView = MomentsEmptyView(frame: .zero,
                                         description: BundleI18n.Moment.Lark_Community_NoFollowingContentEmptyState,
                                         type: .noContent)
        } else {
            emptyView = MomentsEmptyView(frame: .zero,
                                         description: BundleI18n.Moment.Lark_Community_ShareAPost,
                                         type: .noPost)
        }
        emptyView.isHidden = true
        emptyView.lu.addCorner(corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner], cornerSize: CGSize(width: 8, height: 8))
        return emptyView
    }()

    let disposeBag: DisposeBag = DisposeBag()
    private var isFirstAppear: Bool = true
    let context: BaseMomentContext
    let sourceType: FeedList.SourceType

    var hostSize: CGSize = .zero {
        didSet {
            Self.logger.info("MomentsFeedListViewController hostSize set -\(self.hostSize)")
        }
    }

    var navHeight: CGFloat?

    private var firstScreenDataLoading: Bool = true

    //记录是否初始化了BroadcastHeaderView，避免无效刷新BroadcastHeaderView的UI消耗性能
    private var hasBroadcastHeaderView = false

    private func setBroadcastHeaderView(broadcasts: [RawData.Broadcast]) {
        self.boardcastHeaderView.mainMargin = isRegularStyle ? 0 : 16
        self.boardcastHeaderView.updateUI(boardcasts: broadcasts,
                                          totalWitdh: self.hostSize.width)
        let headerBgView = BoardcastHeaderContainerView(frame: CGRect(x: 0, y: 0, width: 0, height: boardcastHeaderView.totalHeight + 12))
        headerBgView.addSubview(self.boardcastHeaderView)
        self.boardcastHeaderView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview().offset(12)
        }
        self.tableView.tableHeaderView = broadcasts.isEmpty ? tableBlankHeaderView : headerBgView
        self.hasBroadcastHeaderView = true
    }

    var reactionMenuBarInset: UIEdgeInsets? {
        if let navHeight = navHeight {
            return UIEdgeInsets(top: navHeight, left: 0, bottom: 0, right: 0)
        }
        return nil
    }

    var reactionMenuBarFromVC: UIViewController {
        return self.delegate?.getReactionMenuBarFromVC() ?? self
    }

    var scene: MomentContextScene {
        return .feed(self.viewModel.tabInfo)
    }

    init(userResolver: UserResolver,
         context: BaseMomentContext,
         userPushCenter: PushNotificationCenter,
         sourceType: FeedList.SourceType,
         manageMode: RawData.ManageMode,
         tabInfo: RawData.PostTab,
         isRegularStyle: Bool,
         hostSize: CGSize) {
        self.userResolver = userResolver
        self.context = context
        self.sourceType = sourceType
        self.hostSize = hostSize
        self.viewModel = MomentFeedListViewModel(userResolver: userResolver, sourceType: sourceType, manageMode: manageMode, userPushCenter: userPushCenter, context: context, tabInfo: tabInfo)
        MomentsFeedFristScreenItem.shared.initViewStartRender(isRecommend: tabInfo.isRecommendTab)
        context.dataSourceAPI = self.viewModel
        self.isRegularStyle = isRegularStyle
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.clear
        isNavigationBarHidden = true
        initSubViews()
        observerMessageViewModel()
        self.addMenuObserver()
        MomentsFeedFristScreenItem.shared.endInitView(isRecommend: viewModel.tabInfo.isRecommendTab)

        self.viewModel.momentsAccountService?.rxCurrentAccount
            .observeOn(MainScheduler.instance)
            .filter { account in
                account != nil
            }.subscribe { [weak self] _ in
                self?.loadFirstScreenData()
            }.disposed(by: disposeBag)
    }

    func loadFirstScreenData() {
        viewModel.fetchFirstScreenPosts()
        viewModel.fetchBoardcastPosts()
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

    private func initSubViews() {
        view.addSubview(tableBgView)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        tableView.backgroundColor = isRegularStyle ? .clear : tableBgView.backgroundColor
        if sourceType == .recommand {
            tableView.addSubview(self.emptyView)
            emptyView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
                make.width.height.equalToSuperview()
            }
        }
        tableView.tableHeaderView = tableBlankHeaderView
        if let footer = tableView.tableFooterView {
            tableBgView.snp.remakeConstraints { make in
                make.centerX.bottom.equalToSuperview()
                make.top.equalTo(footer)
                make.width.equalTo(hostSize.width)
            }
        }
    }

    private func observerMessageViewModel() {
        viewModel.tableRefreshDriver
            .drive(onNext: { [weak self] (refreshType) in
                switch refreshType {
                case .localFirstScreenDataRefresh:
                    //如果本地数据是空，继续处于加载中状态
                    if !(self?.viewModel.uiDataSource.isEmpty ?? true) {
                        self?.firstScreenDataLoading = false
                        self?.tableView.hasHeader = true
                    }
                    self?.reloadData(needShowEmptyView: false)
                    let isRecommendTab = self?.viewModel.tabInfo.isRecommendTab ?? false
                    self?.viewModel.tracker.getMomentsFeedLoadItem(isRecommendTab: isRecommendTab)?.endLocalDataRender()
                case .remoteFirstScreenDataRefresh(hasFooter: let hasFooter, style: let style):
                    //之前本地数据为空，还处于首屏数据加载中
                    var finishResetHeader = false
                    if self?.firstScreenDataLoading ?? false {
                        self?.firstScreenDataLoading = false
                        finishResetHeader = true
                    }
                    self?.update(hasFooter: hasFooter)
                    self?.reloadData()
                    self?.viewModel.endTrackForFirstScreen()
                    self?.tableView.showPostTip(style, finishResetHeader: finishResetHeader)
                case .refreshTable(needResetHeader: let needResetHeader, hasFooter: let hasFooter, style: let style, trackSence: let trackSence):
                    if needResetHeader {
                        self?.tableView.showPostTip(style, finishResetHeader: true)
                    }
                    //刷新列表，添加/屏蔽加载更多
                    self?.update(hasFooter: hasFooter)
                    self?.reloadData()
                    self?.viewModel.endTrackForSence(trackSence)
                case .publishPost:
                    self?.reloadData()
                    self?.tableView.setContentOffset(.zero, animated: false)
                case .refresh:
                    self?.reloadData()
                case .refreshCell(indexs: let indexPaths, animation: let animation):
                    self?.tableView.refresh(indexPaths: indexPaths, animation: animation, guarantLastCellVisible: false)
                case .refreshBoardcast(let broadcasts):
                    self?.setBroadcastHeaderView(broadcasts: broadcasts)
                }
            }).disposed(by: disposeBag)

        viewModel.errorDri
            .drive(onNext: { [weak self] (errorType) in
                switch errorType {
                case .fetchFirstScreenPostsFail(let error, let fetchLocalDataSuccess):
                    if self?.viewModel.momentsAccountService?.handleOfficialAccountErrorIfNeed(error: error, from: self) == true {
                        return
                    }
                    //取消骨架图状态，可刷新，无更多内容
                    self?.firstScreenDataLoading = false
                    self?.tableView.showPostTip(.fail, finishResetHeader: true)
                    self?.update(hasFooter: false)
                    //如果本地接口成功了，需要展示无数据页面；否则没有依据，不展示无数据页面
                    self?.reloadData(needShowEmptyView: fetchLocalDataSuccess)
                    _ = self?.canHandleError(error)
                case .loadMoreFail(let error):
                    self?.tableView.endBottomLoadMore(hasMore: true)
                    if self?.viewModel.momentsAccountService?.handleOfficialAccountErrorIfNeed(error: error, from: self) == true {
                        return
                    }
                    if let canHandle = self?.canHandleError(error), !canHandle {
                        UDToast.showFailure(with: BundleI18n.Moment.Lark_Community_FailedToLoad, on: self?.view ?? UIView())
                    }
                case .refreshListFail(let error):
                    self?.tableView.showPostTip(.fail, finishResetHeader: true)
                    if self?.viewModel.momentsAccountService?.handleOfficialAccountErrorIfNeed(error: error, from: self) == true {
                        return
                    }
                    if let canHandle = self?.canHandleError(error), !canHandle {
                        UDToast.showFailure(with: BundleI18n.Moment.Lark_Community_FailedToRefresh, on: self?.view ?? UIView())
                    }
                }
            }).disposed(by: disposeBag)
    }

    private func canHandleError(_ error: Error) -> Bool {
        var canhander = false
        if let error = error as? RCError {
            switch error {
            case .businessFailure(errorInfo: let info) where !info.displayMessage.isEmpty:
                // 读取失败 || 板块被删除
                if info.code == 330_503 {
                    UDToast.showFailure(with: info.displayMessage, on: self.view.window ?? self.view)
                    self.delegate?.invalidTabID(viewModel.tabInfo.id)
                }
                // 没有权限
                if info.code == 330_300 {
                    UDToast.showFailure(with: info.displayMessage, on: self.view.window ?? self.view)
                }
                canhander = true
            default:
                break
            }
        }
        return canhander
    }

    // MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.firstScreenDataLoading {
            return FeedList.skeletonCellCount
        }
        return viewModel.uiDataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if self.firstScreenDataLoading {
            cell = tableView.dequeueReusableCell(withIdentifier: PostSkeletonlTableViewCell.identifier, for: indexPath)
            cell.separatorInset = .zero
        } else {
            let cellVM = viewModel.uiDataSource[indexPath.row]
            let cellId = cellVM.entity.post.id
            cell = cellVM.dequeueReusableCell(tableView, cellId: cellId)
            let left = (cellId == self.viewModel.lastReadPostId() ? self.view.frame.width : 0)
            cell.separatorInset = UIEdgeInsets(top: 0, left: left, bottom: 0, right: 0)
        }
        if isRegularStyle && indexPath.row == 0 {
            cell.contentView.lu.addCorner(corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner], cornerSize: CGSize(width: 8, height: 8))
        } else {
            cell.contentView.lu.addCorner(corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner], cornerSize: CGSize(width: 0, height: 0))
        }
        return cell
    }

    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard !self.firstScreenDataLoading, indexPath.row < self.viewModel.uiDataSource.count else {
            return
        }
        // 在屏幕内的才触发vm的willDisplay
        if tableView.indexPathsForVisibleRows?.contains(indexPath) ?? false {
            self.viewModel.uiDataSource[indexPath.row].willDisplay()
            let post = self.viewModel.uiDataSource[indexPath.row].entity.post
            self.postCardTracker.displayPostIds.insert(post.id)
            self.feedPageShowClickTracker.insert(postId: post.id, cirleId: post.circleID)
        }
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard !self.firstScreenDataLoading, indexPath.row < self.viewModel.uiDataSource.count else {
            return
        }
        // 不在屏幕内的才触发didEndDisplaying
        if !(tableView.indexPathsForVisibleRows?.contains(indexPath) ?? false) {
            self.viewModel.uiDataSource[indexPath.row].didEndDisplay()
            let post = self.viewModel.uiDataSource[indexPath.row].entity.post
            self.postCardTracker.displayPostIds.remove(post.id)
            self.feedPageShowClickTracker.remove(postId: post.id)
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.firstScreenDataLoading {
            return 200
        }
        return viewModel.uiDataSource[indexPath.row].renderer.size().height
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.firstScreenDataLoading {
            return 200
        }
        return viewModel.uiDataSource[indexPath.row].renderer.size().height
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil, !self.firstScreenDataLoading else { return }
        let cellVM = viewModel.uiDataSource[indexPath.row]
        Tracer.trackCommunityFeedCardClick(postID: cellVM.entity.id, source: .feed)
        cellVM.didSelect()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.tableView.scrollViewDidScroll(scrollView)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if firstScreenDataLoading {
            return
        }
        self.postCardTracker.trackCommunityFeedCardView()
        self.feedPageShowClickTracker.trackCommunityFeedCardView()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate, !firstScreenDataLoading {
            self.postCardTracker.trackCommunityFeedCardView()
            self.feedPageShowClickTracker.trackCommunityFeedCardView()
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        MomentsTracer.trackFeedPageViewClick(.slide,
                                             circleId: delegate?.requestForCircleId(),
                                             type: .tabInfo(self.viewModel.tabInfo),
                                             detail: nil)
    }

    // MARK: MomentFeedTableViewDelegate
    func loadMorePosts(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        viewModel.loadMorePosts(finish: finish)
    }

    func refreshPosts(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        viewModel.refreshPosts(finish: finish)
        viewModel.fetchBoardcastPosts()
    }

    func cellViewModel(indexPath: IndexPath) -> PolybasicCellViewModelProtocol {
        return self.viewModel.uiDataSource[indexPath.row]
    }

    func supportTopTipStyle() -> Bool {
        return self.userResolver.fg.dynamicFeatureGatingValue(with: "moments.new.refresh")
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
        if let footer = tableView.tableFooterView {
            tableBgView.snp.remakeConstraints { make in
                make.centerX.bottom.equalToSuperview()
                make.top.equalTo(footer)
                make.width.equalTo(hostSize.width)
            }
        }
    }

    func reloadData(needShowEmptyView: Bool = true) {
        if needShowEmptyView {
            self.emptyView.isHidden = !self.viewModel.uiDataSource.isEmpty
        } else {
            self.emptyView.isHidden = true
        }
        if !self.emptyView.isHidden {
            let view = UIView(frame: .zero)
            self.tableView.tableFooterView = view
            tableBgView.snp.remakeConstraints { make in
                make.centerX.bottom.equalToSuperview()
                make.top.equalTo(view)
                make.width.equalTo(hostSize.width)
            }
            self.tableView.bringSubviewToFront(self.emptyView)
        }
        self.tableView.reloadData()
        DispatchQueue.main.async {
            self.postCardTracker.trackCommunityFeedCardView()
            self.feedPageShowClickTracker.trackCommunityFeedCardView()
        }
    }

    func pauseQueue() {
        self.viewModel.pauseQueue()
    }

    func resumeQueue() {
        self.viewModel.resumeQueue()
    }

    /// 先滚动到顶部 然后再刷新 否则数据较多的时候 出现无法滚动到头部的问题
    func autoRefresh() {
        self.tableView.setContentOffset(.zero, animated: false)
        self.tableView.topLoadMoreView?.beginRefresh()
    }

    func getPageType() -> MomentsTracer.PageType {
        return .tabInfo(viewModel.tabInfo)
    }

    func getTracker() -> MomentsCommonTracker {
        return viewModel.tracker
    }

    func listView() -> UIView {
        return self.view
    }

    func listDidAppear() {
        appearDate = Date()
        self.delegate?.viewDidAppearForVC(self)
    }

    func resizeWhenHostSizeWidthChange(isRegularStyle: Bool) {
        self.isRegularStyle = isRegularStyle
        self.tableBlankHeaderView.frame = CGRect(x: 0, y: 0, width: CGFloat.leastNormalMagnitude, height: self.isRegularStyle ? 12 : CGFloat.leastNormalMagnitude)
        viewModel.uiDataSource.forEach { cellVM in
            cellVM.onResize()
        }
        reloadData()
        if hasBroadcastHeaderView {
            boardcastHeaderView.mainMargin = isRegularStyle ? 0 : 16
            boardcastHeaderView.updateBackGroudImage(totalWitdh: hostSize.width)
        }
        tableBgView.snp.updateConstraints { make in
            make.width.equalTo(hostSize.width)
        }
        tableView.backgroundColor = isRegularStyle ? .clear : tableBgView.backgroundColor
    }

    func resetTableViewHeaderFrame() {
        tableView.topLoadMoreView?.resetFrame()
    }

    func refreshTableView() {
        self.autoRefresh()
    }
}

extension MomentsFeedListViewController: FeedListEmptyViewDelegate {
    func createPostClick() {
        self.delegate?.didClickEmptyPageActionBtn()
    }
}

extension MomentsFeedListViewController: SingleBoardcastViewDelegate, FeedListDependencyDataDelegate {
    func tapPlaced(postId: String) {
        let body = MomentPostDetailByIdBody(postId: postId, toCommentId: nil, source: .feed)
        userResolver.navigator.push(body: body, from: self)
    }

    func requestForCircleId() -> String? {
        return delegate?.requestForCircleId()
    }
}

extension MomentsFeedListViewController: NoMoreFeedPostFooterDelegate {
    func attributedLabel(didSelectText text: String, didSelectRange range: NSRange) -> Bool {
        self.autoRefresh()
        return false
    }
}
