//
//  MomentsPolybasicProfileViewController.swift
//  Moment
//
//  Created by ByteDance on 2022/7/21.
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

final class MomentsPolybasicProfileViewController: MomentsViewAdapterViewController,
                                                   UITableViewDelegate,
                                                   UITableViewDataSource,
                                                   MenuObserverProtocol {

    static let logger = Logger.log(ProfilePostListViewController.self, category: "Module.Moments.MomentsPolybasicProfileViewController")

    let disposeBag: DisposeBag = DisposeBag()

    override var childVCMustBeModalView: Bool {
        return Display.pad
    }
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
            }
        }
    }
    public var itemId: String = "moments_profile_new"

    weak var delegate: PostListVCDelegate?

    private lazy var cellManager: UserTransitionCellManager = {
        let manager = UserTransitionCellManager()
        manager.delegate = self
        manager.showCornerForCell = true
        return manager
    }()

    lazy var tableView: MomentLinkagePostTableView = {
        let table = MomentLinkagePostTableView()
        table.dataSource = self
        table.delegate = self
        table.tableFooterView = UIView(frame: .zero)
        table.enableTopPreload = false
        table.momentFeedTableViewDelegate = self
        table.backgroundColor = UIColor.ud.bgBase
        table.separatorStyle = .singleLine
        table.separatorInset = .zero
        table.separatorColor = UIColor.ud.lineDividerDefault
        table.showsVerticalScrollIndicator = false
        table.showsHorizontalScrollIndicator = false
        table.autoStartLinkage = viewModel.showInNickNameContainer
        table.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0.01, height: 12))
        table.register(PostSkeletonlTableViewCell.self, forCellReuseIdentifier: PostSkeletonlTableViewCell.identifier)
        table.register(UserPostEmptyCell.self, forCellReuseIdentifier: UserPostEmptyCell.identifier)
        return table
    }()
    let viewModel: MomentsPolybasicProfileViewModel
    init(userResolver: UserResolver, viewModel: MomentsPolybasicProfileViewModel) {
        self.viewModel = viewModel
        super.init(userResolver: userResolver)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        observerMessageViewModel()
    }

    override func loadFirstScreenData() {
        super.loadFirstScreenData()
        viewModel.fetchFirstScreenPosts()
    }

    private func setupView() {
        isNavigationBarHidden = true
        self.view.backgroundColor = UIColor.ud.bgBase
        self.contentView.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
            make.left.equalToSuperview().offset(16)
        }
        tableView.reloadData()
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

    private func observerMessageViewModel() {
        viewModel.tableRefreshDriver
            .drive(onNext: { [weak self] (refreshType) in
                switch refreshType {
                case .remoteFirstScreenDataRefresh(hasFooter: let hasFooter):
                    self?.update(hasFooter: hasFooter)
                    self?.cellManager.firstScreenDataLoading = false
                    self?.reloadData()
                case .refreshTable(_, hasFooter: let hasFooter):
                    self?.update(hasFooter: hasFooter)
                    self?.reloadData()
                case .refresh:
                    self?.reloadData()
                case .refreshCell(indexs: let indexPaths, animation: let animation):
                    self?.tableView.refresh(indexPaths: indexPaths, animation: animation, guarantLastCellVisible: false)
                // 删帖后 需要更新头部数据
                case .delePost:
                    break
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

    func reloadData() {
        let isEmpty = self.viewModel.uiDataSource.isEmpty
        cellManager.isEmptyData = isEmpty
        self.tableView.separatorStyle = isEmpty ? .none : .singleLine
        self.tableView.reloadData()
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

    func listView() -> UIView {
        return self.view
    }

    func listWillAppear() {
        self.delegate?.listWillAppear(tableView)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if cellManager.isTransitionStatus() {
            return cellManager.cellForTableView(tableView, indexPath: indexPath)
        }
        let cellVM = viewModel.uiDataSource[indexPath.row]
        let cellId = cellVM.entityId
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
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard !cellManager.isTransitionStatus(), indexPath.row < self.viewModel.uiDataSource.count else {
            return
        }
        // 在屏幕内的才触发vm的willDisplay
        if tableView.indexPathsForVisibleRows?.contains(indexPath) ?? false {
            self.viewModel.uiDataSource[indexPath.row].willDisplay()
        }
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard !cellManager.isTransitionStatus(), indexPath.row < self.viewModel.uiDataSource.count else {
            return
        }
        // 不在屏幕内的才触发didEndDisplaying
        if !(tableView.indexPathsForVisibleRows?.contains(indexPath) ?? false) {
            self.viewModel.uiDataSource[indexPath.row].didEndDisplay()
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

extension MomentsPolybasicProfileViewController: UserTransitionCellManagerDelegate {
    func emptyType() -> UDEmptyType {
        return .noPost
    }

    func emptyBtnStyle() -> (String, TypeButton.Style?)? {
        guard self.viewModel.userType == .user else {
            return nil
        }
        let isCurrentUser = self.viewModel.isCurrentUser
        return isCurrentUser ? (BundleI18n.Moment.Lark_Community_MomentsEmptyStateButton, nil) : nil
    }

    func emptyTitle() -> String {
        guard self.viewModel.userType == .user else {
            return BundleI18n.Moment.Lark_Community_MomentsEmptyStateTheirs
        }
        return self.viewModel.isCurrentUser ? BundleI18n.Moment.Lark_Community_MomentsEmptyState : BundleI18n.Moment.Lark_Community_MomentsEmptyStateTheirs
    }

    func emptyBtnClick() {
        guard self.viewModel.userType == .user else {
            return
        }
        let url = Tab.moment.url
        guard let profileVC = self.profileVC else {
            return
        }
        let isCurrentTabMoments = self.animatedTabBarController?.currentTab == Tab.moment
        userResolver.navigator.switchTab(url, from: profileVC, animated: true) { [weak self] _ in
            if let container = self?.animatedTabBarController?.viewController(for: Tab.moment)?.tabRootViewController as? MomentsFeedContainerViewController {
                Self.logger.info("user click send post btn")
                if !isCurrentTabMoments,
                   Display.pad {
                    container.closeChildViewControllers()
                }
                container.createPost(source: .profile)
            }
        }
    }
}

extension MomentsPolybasicProfileViewController: MomentFeedTableViewDelegate {

    func cellViewModel(indexPath: IndexPath) -> PolybasicCellViewModelProtocol {
        return self.viewModel.uiDataSource[indexPath.row]
    }

    func refreshPosts(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        viewModel.refreshPosts(finish: finish)
    }

    func loadMorePosts(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        viewModel.loadMorePosts(finish: finish)
    }
}

/// 该页面作为一个子容器，会被放置在不同容器中
/// 因为不同的容器要求不至于，所以实现了不同的协议
/// LarkProfileTab 现在只有实名的情况，即user的type
extension MomentsPolybasicProfileViewController: LarkProfileTab {

    static func createTab(by tab: LarkUserProfilTab,
                          resolver: UserResolver,
                          context: ProfileContext,
                          profile: ProfileInfoProtocol,
                          dataProvider: ProfileDataProvider) -> ProfileTabItem? {
        let fgValue = (try? resolver.resolve(assert: FeatureGatingService.self))?.staticFeatureGatingValue(with: "moments.profile.new") ?? false

        guard tab.tabType == .fCommunity, fgValue, let userPushCenter = try? resolver.userPushCenter else {
            return nil
        }
        return ProfileTabItem(title: tab.name.getString(),
                              identifier: "moments_profile_new") {
            let context = BaseMomentContext()
            let vm = MomentsPolybasicProfileViewModel(userResolver: resolver,
                                                      userId: profile.userInfoProtocol.userID,
                                                      userType: .user,
                                                      showInNickNameContainer: false,
                                                      context: context,
                                                      userPushCenter: userPushCenter)
            let vc = MomentsPolybasicProfileViewController(userResolver: resolver, viewModel: vm)
            return vc
        }
    }

    public static var tabId: String = "moments_profile_new"

    public var segmentTitle: String { return "" }

    public var scrollableView: UIScrollView {
        return self.tableView
    }
}
