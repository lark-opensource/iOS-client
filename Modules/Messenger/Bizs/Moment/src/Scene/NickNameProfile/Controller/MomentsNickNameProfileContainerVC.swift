//
//  MomentsNickNameProfileContainerVC.swift
//  Moment
//
//  Created by ByteDance on 2022/7/21.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignTabs
import LarkNavigation
import LarkContainer
import EENavigator
import CoreGraphics
import LarkProfile
import ByteWebImage
import LKCommonsLogging

final class MomentsNickNameProfileContainerVC: BaseUIViewController,
                                               UserResolverWrapper,
                                               UDTabsViewDelegate,
                                               UDTabsListContainerViewDataSource {
    let userResolver: UserResolver
    static let logger = Logger.log(MomentsNickNameProfileContainerVC.self, category: "Module.Moments.MomentsNickNameProfileContainerVC")
    private lazy var titleTabsView: UDTabsTitleView = {
        let tabsView = UDTabsTitleView()
        tabsView.titles = [BundleI18n.Moment.Moments_NicknameProfilePage_PersonalInfo_Title,
                           BundleI18n.Moment.Lark_MomentsDetails_ListTitle]
        tabsView.defaultSelectedIndex = viewModel.selectPostTab ? 1 : 0
        tabsView.backgroundColor = UIColor.ud.bgBody
        let config = tabsView.getConfig()
        config.itemSpacing = 20
        config.contentEdgeInsetLeft = 16
        config.titleNormalFont = UIFont.systemFont(ofSize: 16)
        config.titleSelectedFont = UIFont.systemFont(ofSize: 16, weight: .medium)
        config.titleNumberOfLines = 1
        config.titleNormalColor = UIColor.ud.textCaption
        config.isItemSpacingAverageEnabled = false
        tabsView.setConfig(config: config)
        tabsView.widthForTitleClosure = { text in
            return MomentsDataConverter.widthForString(text, font: config.titleSelectedFont)
        }
        /// 配置指示器
        let indicator = UDTabsIndicatorLineView()
        indicator.indicatorHeight = 2
        indicator.indicatorCornerRadius = 0
        tabsView.indicators = [indicator]
        tabsView.delegate = self
        return tabsView
    }()

    lazy var listContainerView: UDTabsListContainerView = {
        return UDTabsListContainerView(dataSource: self)
    }()

    private lazy var bgScrollView: LinkageScrollView = {
        let sc = LinkageScrollView()
        sc.contentInsetAdjustmentBehavior = .never
        sc.showsHorizontalScrollIndicator = false
        sc.showsVerticalScrollIndicator = false
        sc.backgroundColor = .clear
        sc.didScrollCallBack = { [weak self] (offset) in
            guard let self = self else { return }
            if self.headerView.avatarBottom <= offset.y {
                self.navigationBar?.setAppearance(byProgress: 1.0)
            } else {
                let process = offset.y / self.headerView.avatarBottom
                self.navigationBar?.setAppearance(byProgress: process)
            }
        }
        return sc
    }()
    /// 导航栏的高度 参考profile页
    var navBarHeight: CGFloat = Display.pad ? 50 : 92
    /// 顶部header高度
    private let headerViewHeight: CGFloat = 138
    /// 顶部tab的高度
    private let tabHeight: CGFloat = 40

    private var scrollViewContentSize: CGSize {
        return CGSize(width: self.view.frame.width, height: self.view.frame.height - navBarHeight + headerViewHeight)
    }

    private var listContainerHeight: CGFloat {
        return self.view.frame.height - navBarHeight - tabHeight
    }

    private lazy var headerView: MomentsNickNameHeaderView = {
        let header = MomentsNickNameHeaderView()
        return header
    }()

    var navigationBar: ProfileNaviBar?
    let viewModel: MomentsNickNameProfileContainerViewModel
    let isPresented: Bool //true表示VC是present出来的，false表示是push出来的

    init(userResolver: UserResolver,
         viewModel: MomentsNickNameProfileContainerViewModel,
         isPresented: Bool) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        self.isPresented = isPresented
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        isNavigationBarHidden = true
        setupUI()
        loadData()
        viewModel.configService?.getUserCircleConfigWithFinsih { [weak self] config in
            let info = MomentsTracer.ProfileInfo(profileUserId: self?.viewModel.userId ?? "",
                                      isFollow: false,
                                      isNickName: true,
                                    isNickNameInfoTab: self?.titleTabsView.selectedIndex == 0)
            MomentsTracer.trackFeedPageView(circleId: config.circleID,
                                            type: .moments_profile,
                                            detail: .none,
                                            porfileInfo: info)
        } onError: { error in
            Self.logger.error("getUserCircleConfig error", error: error)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let nav = self.navigationBar {
            navBarHeight = nav.frame.maxY
        }
        self.listContainerView.snp.updateConstraints { make in
            make.height.equalTo(listContainerHeight)
        }
        self.bgScrollView.contentSize = self.scrollViewContentSize
    }

    private func setupUI() {
        if Display.pad {
            self.preferredContentSize = ProfileViewInfoData.iPadViewSize
            self.modalPresentationControl.dismissEnable = true
        }
        view.backgroundColor = UIColor.ud.bgBody
        /// 配置标题
        bgScrollView.addSubview(listContainerView)
        let navBar = ProfileNaviBar()
        navBar.backButton.setImage(Resources.leftOutlined, for: .normal)
        navBar.setAppearance(byProgress: 0)
        view.addSubview(navBar)
        navBar.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
        }
        navBar.backButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        navigationBar = navBar
        view.addSubview(bgScrollView)
        bgScrollView.addSubview(headerView)
        bgScrollView.addSubview(titleTabsView)
        bgScrollView.addSubview(listContainerView)
        titleTabsView.listContainer = listContainerView
        bgScrollView.snp.makeConstraints { (make) in
            make.left.right.bottom.width.equalToSuperview()
            make.top.equalTo(navBar.snp.bottom)
        }

        headerView.snp.makeConstraints { (make) in
            make.top.left.right.width.equalToSuperview()
            make.height.equalTo(headerViewHeight)
        }

        titleTabsView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(tabHeight)
            make.top.equalTo(headerView.snp.bottom)
        }
        listContainerView.snp.remakeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(titleTabsView.snp.bottom)
            make.bottom.equalToSuperview()
            make.height.equalTo(listContainerHeight)
        }
    }

    func loadData() {
        headerView.updateUIWith(avatarKey: viewModel.userInfo.avatarKey,
                                avatarId: viewModel.userId,
                                name: viewModel.userInfo.name)
        navigationBar?.titleLabel.text = viewModel.userInfo.name
        let avatar = UIImageView()
        avatar.bt.setLarkImage(with: .avatar(key: viewModel.userInfo.avatarKey,
                                             entityID: viewModel.userId))

        avatar.ud.setMaskView()
        navigationBar?.avatarView.customView = avatar
    }

    /// 有几个tab
    func numberOfLists(in listContainerView: UniverseDesignTabs.UDTabsListContainerView) -> Int {
        return self.titleTabsView.titles.count
    }

    func listContainerView(_ listContainerView: UniverseDesignTabs.UDTabsListContainerView, initListAt index: Int) -> UniverseDesignTabs.UDTabsListContainerViewDelegate {
        if index == 0 {
            let vm = MomentsNickNamePersonInfoViewModel(userResolver: userResolver, userId: viewModel.userId)
            let vc = MomentsNickNameViewPersonInfoVC(viewModel: vm)
            vc.privacyPolicyTapCallBack = { [weak self] url in
                guard let self = self else { return }
                self.userResolver.navigator.push(url, from: self)
            }
            vc.delegate = self
            return vc
        } else {
            let context = BaseMomentContext()
            let vm = MomentsPolybasicProfileViewModel(userResolver: userResolver,
                                                      userId: viewModel.userId,
                                                      userType: .nickname,
                                                      showInNickNameContainer: true,
                                                      context: context,
                                                      userPushCenter: viewModel.userPushCenter)
            let vc = MomentsPolybasicProfileViewController(userResolver: userResolver, viewModel: vm)
            vc.delegate = self
            context.pageAPI = self
            context.dataSourceAPI = vm
            return vc
        }
    }

    @objc
    private func close() {
        self.dismissSelf()
    }

    func dismissSelf() {
        if hasBackPage {
            navigationController?.popViewController(animated: true)
        } else if presentingViewController != nil {
            dismiss(animated: true, completion: nil)
        }
    }
}

extension MomentsNickNameProfileContainerVC: PostListVCDelegate {

    func listWillAppear(_ tableView: MomentLinkagePostTableView) {
        self.bgScrollView.bindSubTableView(tableView, maxOffSet: headerViewHeight)
    }

    func exitCurrentPostList() {
        popSelf()
    }

    func willRefreshTableData() {}

}

extension MomentsNickNameProfileContainerVC: PageAPI {
    var hostSize: CGSize { CGSize(width: ProfileViewController.momentsProfileHostSize.width - 32, height: ProfileViewController.momentsProfileHostSize.height) }
    /// 回复某一条评论
    func reply(by commentData: RawData.CommentEntity, fromMenu: Bool) {}
    /// 回复动态
    func reply(by postData: RawData.PostEntity) {}

    var scene: MomentContextScene { .profile }

    var childVCMustBeModalView: Bool { Display.pad }

    var reactionMenuBarInset: UIEdgeInsets? { nil }

    var reactionMenuBarFromVC: UIViewController { self }
}
