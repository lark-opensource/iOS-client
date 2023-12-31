//
//  ProfilePostListViewController.swift
//  Moment
//
//  Created by liluobin on 2021/8/3.
//

import Foundation
import LarkUIKit
import LarkProfile
import LarkContainer
import RxSwift
import Swinject
import LKCommonsLogging
import LarkMessageCore
import LarkButton
import EENavigator
import RustPB
import UniverseDesignToast
import LarkRustClient
import LarkTab
import LarkFeatureGating
import UniverseDesignEmpty
import UIKit
import LarkSetting
final class ProfilePostListViewController: MomentsViewAdapterViewController,
                                     MenuObserverProtocol,
                                     UITableViewDelegate,
                                     UITableViewDataSource {
    @ScopedInjectedLazy private var translateNoti: MomentsTranslateNotification?

    override var childVCMustBeModalView: Bool {
        return Display.pad
    }

    func followDisableFG() -> Bool {
        return (try? userResolver.resolve(assert: FeatureGatingService.self))?.staticFeatureGatingValue(with: "moments.follow.disable") ?? false
    }

    static let logger = Logger.log(ProfilePostListViewController.self, category: "Module.Moments.ProfilePostListViewController")
    let disposeBag: DisposeBag = DisposeBag()

    public var contentViewDidScroll: ((UIScrollView) -> Void)?
    public weak var profileVC: UIViewController? {
        didSet {
            if profileVC == nil || profileVC === oldValue {
                return
            }
            if let pageAPI = profileVC as? ProfileViewController {
                viewModel.context.pageAPI = pageAPI
                viewModel.context.dataSourceAPI = viewModel
                tableView.reloadData()
                headerViewModel.context.pageVC = profileVC
            }
        }
    }

    private var followable = true
    private var circleDisableFollowing = false
    private lazy var headerView: MomentsProfileHeaderView = {
        let header: MomentsProfileHeaderView
        if !circleDisableFollowing {
            header = OldMomentsProfileHeaderView(viewModel: headerViewModel, followable: followable)
        } else {
            header = NewMomentsProfileHeaderView(viewModel: headerViewModel)
        }
        header.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: header.suggestHeight)
        headerViewModel.showTipCallBack = { [weak self, weak header] (tip, image)in
            guard let self = self,
                  let header = header else { return }
            self.showTipView(topOffset: header.suggestHeight, tip: tip, image: image)
        }
        return header
    }()

    let tableView: MomentUserPostTableView = MomentUserPostTableView()

    private lazy var postCardTracker: PostCardViewTracker = {
        return PostCardViewTracker(source: .profile)
    }()

    private lazy var pageShowClickTracker: MomentsFeedPageShowClickTracker = {
        return MomentsFeedPageShowClickTracker(pageType: .moments_profile, pageDetail: nil)
    }()

    private lazy var cellManager: UserTransitionCellManager = {
        let manager = UserTransitionCellManager()
        manager.delegate = self
        manager.showCornerForCell = true
        return manager
    }()

    let viewModel: ProfilePostListViewModel
    let headerViewModel: MomentsProfileHeaderViewModel

    public var itemId: String = "moments_profile"

    init(userResolver: UserResolver, viewModel: ProfilePostListViewModel) {
        self.viewModel = viewModel
        let context = MomentsProfileHeaderContext()
        self.headerViewModel = MomentsProfileHeaderViewModel(userResolver: userResolver,
                                                             userID: viewModel.userId,
                                                             context: context,
                                                             tracker: viewModel.tracker)
        super.init(userResolver: userResolver)
        self.viewModel.getIsFollowCallBack = {
            [weak self] in
            return self?.headerViewModel.profileEntity?.user?.isCurrentUserFollowing
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        observerMessageViewModel()
        addMenuObserver()
    }

    override func loadFirstScreenData() {
        super.loadFirstScreenData()
        viewModel.fetchFirstScreenPosts()
        viewModel.getCurrentCircle { [weak self] circle in
            guard let self = self else { return }
            self.headerViewModel.context.circleId = circle.circleID
            self.circleDisableFollowing = self.followDisableFG() && circle.disableFollowing
            self.followable = !(self.followDisableFG() && circle.disableFollowing) && self.momentsAccountService?.getCurrentOfficialUser() == nil
            self.setHeader()
        }
    }

    override func onResize(widthChanged: Bool, heightChanged: Bool) {
        super.onResize(widthChanged: widthChanged, heightChanged: heightChanged)
        if widthChanged {
            ProfileViewController.momentsProfileHostSize = self.hostSize
            viewModel.uiDataSource.forEach { cellVM in
                cellVM.onResize()
            }
            self.tableView.reloadData()
        }
    }

    private func setupView() {
        isNavigationBarHidden = true
        self.view.backgroundColor = UIColor.ud.bgBase
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.enableTopPreload = false
        tableView.momentFeedTableViewDelegate = self
        tableView.hasHeader = false
        tableView.backgroundColor = UIColor.clear
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = .zero
        tableView.register(PostSkeletonlTableViewCell.self, forCellReuseIdentifier: PostSkeletonlTableViewCell.identifier)
        tableView.register(UserPostEmptyCell.self, forCellReuseIdentifier: UserPostEmptyCell.identifier)
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview().offset(-14)
            make.left.equalToSuperview().offset(14)
        }
        tableView.reloadData()
    }

    private func observerMessageViewModel() {
        viewModel.tableRefreshDriver
            .drive(onNext: { [weak self] (refreshType) in
                switch refreshType {
                case .remoteFirstScreenDataRefresh(hasFooter: let hasFooter):
                    self?.update(hasFooter: hasFooter)
                    self?.cellManager.firstScreenDataLoading = false
                    self?.reloadData()
                    self?.viewModel.endTrackForShowProfile()
                case .refreshTable(_, hasFooter: let hasFooter):
                    self?.update(hasFooter: hasFooter)
                    self?.reloadData()
                case .refresh:
                    self?.reloadData()
                case .refreshCell(indexs: let indexPaths, animation: let animation):
                    self?.tableView.refresh(indexPaths: indexPaths, animation: animation, guarantLastCellVisible: false)
                // 删帖后 需要更新头部数据
                case .delePost:
                    self?.headerViewModel.modifyPostCount()
                }
            }).disposed(by: disposeBag)

        viewModel.errorDri
            .drive(onNext: { [weak self] (errorType) in
                switch errorType {
                case .fetchFirstScreenPostsFail(let error, _):
                    if self?.momentsAccountService?.handleOfficialAccountErrorIfNeed(error: error, from: self) == true {
                        return
                    }
                    self?.update(hasFooter: false)
                    self?.cellManager.firstScreenDataLoading = false
                    self?.reloadData()
                case .loadMoreFail(let error):
                    self?.tableView.endBottomLoadMore(hasMore: true)
                    self?.momentsAccountService?.handleOfficialAccountErrorIfNeed(error: error, from: self)
                case .refreshListFail(let error):
                    self?.tableView.endTopLoadMore(hasMore: true)
                    self?.momentsAccountService?.handleOfficialAccountErrorIfNeed(error: error, from: self)
                }
            }).disposed(by: disposeBag)
    }

    func showTipView(topOffset: CGFloat, tip: String, image: UIImage) {
        let tipView = PostDetailTipView(topOffset: topOffset, tip: tip, image: image)
        view.addSubview(tipView)
        tipView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func update(hasFooter: Bool) {
        self.tableView.hasFooter = hasFooter
        if !hasFooter {
            // 占位footer
            self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 80))
        } else {
            self.tableView.tableFooterView = UIView(frame: .zero)
        }
    }

    private func setHeader() {
        tableView.tableHeaderView = headerView
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if cellManager.isTransitionStatus() {
            return cellManager.cellForTableView(tableView, indexPath: indexPath)
        }
        let cellVM = viewModel.uiDataSource[indexPath.row]
        let cellId = cellVM.entity.post.id
        let cell = cellVM.dequeueReusableCell(tableView, cellId: cellId)
        cell.backgroundColor = UIColor.ud.bgBody
        addCornerForCell(cell, indexPath: indexPath)
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

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        tableView.scrollViewDidScroll(scrollView)
        contentViewDidScroll?(scrollView)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil, !cellManager.isTransitionStatus() else { return }
        let cellVM = viewModel.uiDataSource[indexPath.row]
        cellVM.didSelect()
        Tracer.trackCommunityFeedCardClick(postID: cellVM.entity.id, source: .profile)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard !cellManager.isTransitionStatus(), indexPath.row < self.viewModel.uiDataSource.count else {
            return
        }
        // 在屏幕内的才触发vm的willDisplay
        if tableView.indexPathsForVisibleRows?.contains(indexPath) ?? false {
            self.viewModel.uiDataSource[indexPath.row].willDisplay()
            let postID = self.viewModel.uiDataSource[indexPath.row].entity.id
            self.postCardTracker.displayPostIds.insert(postID)
            self.pageShowClickTracker.insert(postId: postID, cirleId: "")
        }
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard !cellManager.isTransitionStatus(), indexPath.row < self.viewModel.uiDataSource.count else {
            return
        }
        // 不在屏幕内的才触发didEndDisplaying
        if !(tableView.indexPathsForVisibleRows?.contains(indexPath) ?? false) {
            self.viewModel.uiDataSource[indexPath.row].didEndDisplay()
            let postID = self.viewModel.uiDataSource[indexPath.row].entity.id
            self.postCardTracker.displayPostIds.remove(postID)
            self.pageShowClickTracker.remove(postId: postID)
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if cellManager.isTransitionStatus() {
            return
        }
        postCardTracker.trackCommunityFeedCardView()
        pageShowClickTracker.trackCommunityFeedCardView()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate, !cellManager.isTransitionStatus() {
            postCardTracker.trackCommunityFeedCardView()
            pageShowClickTracker.trackCommunityFeedCardView()
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        MomentsTracer.trackFeedPageViewClick(.slide,
                                             circleId: viewModel.circleId,
                                             type: .moments_profile,
                                             detail: nil,
                                             profileInfo: MomentsTracer.ProfileInfo(profileUserId: viewModel.userId,
                                                                                    isFollow: headerView.viewModel.profileEntity?.user?.isCurrentUserFollowing,
                                                                                    isNickName: false,
                                                                                    isNickNameInfoTab: false))
    }

    func reloadData() {
        let isEmpty = self.viewModel.uiDataSource.isEmpty
        cellManager.isEmptyData = isEmpty
        self.tableView.separatorStyle = isEmpty ? .none : .singleLine
        self.tableView.reloadData()
        DispatchQueue.main.async {
            self.postCardTracker.trackCommunityFeedCardView()
            self.pageShowClickTracker.trackCommunityFeedCardView()
        }
    }

    func pauseQueue() {
        self.viewModel.pauseQueue()
    }

    func resumeQueue() {
        self.viewModel.resumeQueue()
    }

    private func addCornerForCell(_ cell: UITableViewCell, indexPath: IndexPath) {
        if viewModel.uiDataSource.isEmpty {
            return
        }
        cell.clipsToBounds = true
        guard viewModel.uiDataSource.count > 1 else {
            cell.layer.cornerRadius = 8
            cell.layer.maskedCorners = [.layerMinXMinYCorner,
                                        .layerMaxXMinYCorner,
                                        .layerMinXMaxYCorner,
                                        .layerMaxXMaxYCorner]
            return
        }
        if indexPath.row == 0 {
            cell.layer.cornerRadius = 8
            cell.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else if indexPath.row == viewModel.uiDataSource.count - 1 {
            cell.layer.cornerRadius = 8
            cell.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else {
            cell.layer.cornerRadius = 0
            cell.layer.maskedCorners = []
        }
    }
}

extension ProfilePostListViewController: MomentFeedTableViewDelegate {
    func refreshPosts(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        viewModel.refreshPosts(finish: finish)
    }

    func loadMorePosts(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        viewModel.loadMorePosts(finish: finish)
    }

    func cellViewModel(indexPath: IndexPath) -> PolybasicCellViewModelProtocol {
        return viewModel.uiDataSource[indexPath.row]
    }
}

extension ProfilePostListViewController: LarkProfileTab {
    static func createTab(by tab: LarkUserProfilTab,
                          resolver: UserResolver,
                          context: ProfileContext,
                          profile: ProfileInfoProtocol,
                          dataProvider: ProfileDataProvider) -> ProfileTabItem? {
        let fgValue = (try? resolver.resolve(assert: FeatureGatingService.self))?.staticFeatureGatingValue(with: "moments.profile.new") ?? false
        guard tab.tabType == .fCommunity, !fgValue, let userPushCenter = try? resolver.userPushCenter else {
            return nil
        }
        return ProfileTabItem(title: tab.name.getString(),
                              identifier: "moments_profile") {
            let context = BaseMomentContext()
            let vm = ProfilePostListViewModel(userResolver: resolver,
                                              userId: profile.userInfoProtocol.userID,
                                              context: context,
                                              userPushCenter: userPushCenter)
            let vc = ProfilePostListViewController(userResolver: resolver, viewModel: vm)
            return vc
        }
    }

    public static var tabId: String = "moments_profile"

    public func listView() -> UIView {
        return view
    }

    public var segmentTitle: String {
        return ""
    }

    public var scrollableView: UIScrollView {
        return self.tableView
    }
}

extension ProfilePostListViewController: UserTransitionCellManagerDelegate {
    func emptyType() -> UDEmptyType {
        return .noPost
    }

    func emptyBtnStyle() -> (String, TypeButton.Style?)? {
        return headerViewModel.isCurrentUser ? (BundleI18n.Moment.Lark_Community_MomentsEmptyStateButton, nil) : nil
    }

    func emptyTitle() -> String {
        return headerViewModel.isCurrentUser ? BundleI18n.Moment.Lark_Community_MomentsEmptyState : BundleI18n.Moment.Lark_Community_MomentsEmptyStateTheirs
    }

    func emptyBtnClick() {
        let url = Tab.moment.url
        guard let profileVC = self.profileVC else {
            return
        }
        let isCurrentTabMoments = self.animatedTabBarController?.currentTab == Tab.moment
        userResolver.navigator.switchTab(url, from: profileVC, animated: true) { [weak self] _ in
            if let container = self?.animatedTabBarController?.viewController(for: Tab.moment)?.tabRootViewController as? MomentsFeedContainerViewController {
                Self.logger.info("用户点击了自己空profile页的发帖按钮")
                if !isCurrentTabMoments,
                   Display.pad {
                    container.closeChildViewControllers()
                }
                container.createPost(source: .profile)
            }
        }
    }
}

extension ProfileViewController: PageAPI {

    func refreshTableView() {}

    static var momentsProfileHostSize: CGSize = .zero
    var childVCMustBeModalView: Bool {
        return Display.pad
    }

    var hostSize: CGSize { CGSize(width: Self.momentsProfileHostSize.width - 28, height: Self.momentsProfileHostSize.height) }
    /// 回复某一条评论
    func reply(by commentData: RawData.CommentEntity, fromMenu: Bool) {}
    /// 回复动态
    func reply(by postData: RawData.PostEntity) {}

    var scene: MomentContextScene { .profile }
}
