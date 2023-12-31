//
//  PostCategoryDetailContainerViewController.swift
//  Moment
//
//  Created by liluobin on 2021/4/27.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignTabs
import LarkNavigation
import LarkContainer
import EENavigator
import RustPB
import UniverseDesignToast
import LarkMessengerInterface
import LarkSDKInterface
import LarkRustClient
import CoreGraphics

final class PostCategoryDetailContainerViewController: MomentsBasePostListContainerViewController,
                                                       UDTabsViewDelegate,
                                                       UDTabsListContainerViewDataSource {
    let viewModel: PostCategoryDetailContainerViewModel
    let isPresented: Bool //true表示VC是present出来的，false表示是push出来的
    var lastSelectedIndexOfTabsView = 0
    private lazy var titleTabsView: UDTabsTitleView = {
        let tabsView = UDTabsTitleView()

        tabsView.titles = [BundleI18n.Moment.Lark_Community_RecentlyCommented, BundleI18n.Moment.Lark_Community_Recents]
        tabsView.backgroundColor = UIColor.ud.bgBody
        let config = tabsView.getConfig()
        config.itemSpacing = 20
        config.contentEdgeInsetLeft = 16
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
    private lazy var headerView: UIView = {
        let header = UIView()
        header.addSubview(categoryInfoView)
        return header
    }()

    private let cornerViewRadius: CGFloat = 12

    override var needToSwitchTabWhenCreatePost: Bool {
        return isModalView
    }

    ///目前只有ipad通过profile页进入该页面时会为true，此时一些UI布局和页面跳转逻辑需要做特殊处理
    lazy private var isModalView: Bool = {
        if !isPresented,
           let nav = self.navigationController,
           nav.view.safeAreaInsets.top > 0 {
            //当VC是被push出来的，且顶部有状态栏（即VC的高等于屏幕的高）的时候才会走到这里
            return false
        }
        return true
    }()
    lazy private var navigationBarHeight: CGFloat = {
        return isModalView ? MomentsPostNavigationBar.navigationBarHeightForModalView : MomentsPostNavigationBar.navigationBarHeight
    }()
    private var headerBgViewHeight: CGFloat {
        let extraHeight = isRegularStyle ? 60 : cornerViewRadius
        return navigationBarHeight + categoryInfoView.suggestHeight + extraHeight
    }
    private func titleTabsHeight() -> CGFloat {
        return !viewModel.needShowFilterTab ? 0 : 40
    }
    private var maxOffSet: CGFloat {
        return categoryInfoView.suggestHeight
    }

    private var scrollViewContentSize: CGSize {
        return CGSize(width: self.hostSize.width, height: self.hostSize.height - navigationBarHeight + maxOffSet)
    }
    private var listContainerHeight: CGFloat {
        return scrollViewContentSize.height - maxOffSet - titleTabsHeight()
    }
    private lazy var bgScrollView: LinkageScrollView = {
        let sc = LinkageScrollView()
        sc.contentInsetAdjustmentBehavior = .never
        sc.showsHorizontalScrollIndicator = false
        sc.showsVerticalScrollIndicator = false
        sc.backgroundColor = .clear
        sc.didScrollCallBack = { [weak self] (offset) in
            guard let self = self else { return }
            if offset.y <= self.categoryInfoView.iconTopDistance {
                self.titleView.alpha = 0
            } else if offset.y > self.categoryInfoView.iconTopDistance, offset.y < self.categoryInfoView.iconMaxY {
                self.titleView.alpha = offset.y / (self.categoryInfoView.iconMaxY - self.categoryInfoView.iconTopDistance)
            } else {
                self.titleView.alpha = 1
            }
        }
        return sc
    }()

    private lazy var categoryInfoView: PostCategoryDetailInfoView = {
        let vm = PostCategoryHeaderViewModel(userResolver: userResolver, categoryInputs: viewModel.categoryInputs)
        let infoView = PostCategoryDetailInfoView(viewModel: vm, hostWidth: hostSize.width) { [weak self] (animation) in
            self?.updateHeaderViewWith(animation: animation)
        } detailInfoCallback: { [weak self] (entityId, key, title) in
            self?.titleView.updateUIWith(title: title, entityId: entityId, imageKey: key)
        }
        infoView.headerImageSetFinishCallback = { [weak self] (image, key, entityId) in
            self?.headerBgView.setHeaderBackGroundImageWithOriginImage(image, key: key, entityId: entityId, finish: nil)
        }
        infoView.iconTapCallBack = { [weak self] (key, entityId) in
            guard let self = self else { return }
            let body = PreviewAvatarBody(avatarKey: key,
                                         entityId: entityId,
                                         scene: .simple)
            self.userResolver.navigator.present(body: body, from: self)
        }
        infoView.adminAvatarTapCallBack = { [weak self] (item) in
            guard let self = self else { return }
            MomentsNavigator.pushAvatarWith(userResolver: self.userResolver,
                                            user: item,
                                            from: self,
                                            source: .categoryDetail,
                                            trackInfo: nil)
        }

        infoView.didTapUrl = { [weak self] (url) in
            guard let self = self else { return }
            if let httpUrl = url.lf.toHttpUrl() {
                self.userResolver.navigator.push(httpUrl, from: self)
            } else {
                self.userResolver.navigator.push(url, from: self)
            }
        }
        return infoView
    }()

    private lazy var navBar: PostListNavigationBar = {
        return PostListNavigationBar(backImage: isPresented ? Resources.momentsNavBarClose : Resources.categoryBack, delegate: self)
    }()

    private lazy var headerBgView: PostCategoryHeaderBackgroundView = {
        return PostCategoryHeaderBackgroundView()
    }()

    lazy var listContainerView: UDTabsListContainerView = {
        return UDTabsListContainerView(dataSource: self)
    }()

    lazy var titleView: BaseInfoNavTitleView = {
        return BaseInfoNavTitleView(cornerRadius: 2)
    }()

    override var scene: MomentContextScene {
        return .categoryDetail(titleTabsView.selectedIndex, viewModel.categoryInputs.id)
    }

    init(userResolver: UserResolver, viewModel: PostCategoryDetailContainerViewModel, isPresented: Bool) {
        self.viewModel = viewModel
        self.isPresented = isPresented
        super.init(userResolver: userResolver)
        viewModel.getCategoryDetailWithRefreshBlock { [weak self] entity in
            guard let self = self,
                  let category = entity?.category else {
                return
            }
            self.createPostButton.isHidden = !category.canCreatePost
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        /// .strongIntervention .recommendV2Mode 不需要展示tab
        viewModel.initCurrentCircleConfig { [weak self] circle in
            self?.viewModel.needShowFilterTab = !circle.manageMode.isRecommendOrder
            self?.updateFeedOrder(config: circle)
        }
        addObserves()
    }

    func setupUI() {
        isNavigationBarHidden = true
        /// 配置标题
        bgScrollView.addSubview(listContainerView)
        bgScrollView.addSubview(headerView)
        self.contentView.addSubview(headerBgView)
        self.contentView.addSubview(bgScrollView)
        self.view.insertSubview(headerBgView, belowSubview: self.contentView)
        self.view.addSubview(navBar)
        titleView.alpha = 0
        updateUI()
    }

    func updateUI() {
        if !viewModel.needShowFilterTab {
            if titleTabsView.superview != nil {
                titleTabsView.removeFromSuperview()
            }
            titleTabsView.listContainer = nil
        } else {
            if titleTabsView.superview == nil {
                headerView.addSubview(titleTabsView)
            }
            titleTabsView.listContainer = listContainerView
        }
        self.navBar.snp.remakeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(navigationBarHeight)
        }
        bgScrollView.snp.remakeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(self.navBar.snp.bottom)
        }
        headerBgView.snp.remakeConstraints { (make) in
            make.top.equalTo(headerView).offset(-navigationBarHeight)
            make.left.right.equalToSuperview()
            make.height.equalTo(headerBgViewHeight)
        }

        headerView.snp.remakeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.width.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalTo(categoryInfoView.suggestHeight + titleTabsHeight())
        }

        listContainerView.snp.remakeConstraints { (make) in
            make.left.width.equalToSuperview()
            make.top.equalTo(self.headerView.snp.bottom)
            make.height.equalTo(listContainerHeight)
        }
        setupHeaderSubViews()
    }

    override func onResize(widthChanged: Bool, heightChanged: Bool) {
        super.onResize(widthChanged: widthChanged, heightChanged: heightChanged)
        let offset = self.bgScrollView.contentOffset
        self.bgScrollView.contentSize = self.scrollViewContentSize
        self.bgScrollView.layoutIfNeeded()
        self.bgScrollView.setContentOffset(offset, animated: false)
        if heightChanged {
            listContainerView.snp.updateConstraints { make in
                make.height.equalTo(listContainerHeight)
            }
        }
        if widthChanged {
            categoryInfoView.hostWidth = hostSize.width
            for vc in listContainerView.validListDict.values {
                if let vc = vc as? BasePostListViewController {
                    vc.resizeWhenHostSizeWidthChange()
                }
            }
        }
    }

    private func setupHeaderSubViews() {
        categoryInfoView.snp.remakeConstraints { (make) in
            make.top.left.right.equalToSuperview()
        }
        if viewModel.needShowFilterTab {
            titleTabsView.snp.remakeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.height.equalTo(titleTabsHeight())
                make.bottom.equalToSuperview()
            }
            self.titleTabsView.lu.addCorner(corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner], cornerSize: CGSize(width: cornerViewRadius, height: cornerViewRadius))
            self.listContainerView.lu.addCorner(corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner], cornerSize: CGSize(width: 0, height: 0))
        } else {
            self.titleTabsView.lu.addCorner(corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner], cornerSize: CGSize(width: 0, height: 0))
            titleTabsView.snp.removeConstraints()
            self.listContainerView.lu.addCorner(corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner], cornerSize: CGSize(width: cornerViewRadius, height: cornerViewRadius))
        }
    }

    private func updateHeaderViewWith(animation: Bool) {
        self.bgScrollView.maxOffSetY = maxOffSet
        self.bgScrollView.contentSize = self.scrollViewContentSize
        self.view.layoutIfNeeded()
        self.headerView.snp.updateConstraints { (make) in
            make.height.equalTo(categoryInfoView.suggestHeight + titleTabsHeight())
        }
        headerBgView.snp.updateConstraints { make in
            make.height.equalTo(headerBgViewHeight)
        }
        if animation {
            /// 文字展开动画
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.bgScrollView.contentSize = self.scrollViewContentSize
    }

    private func addObserves() {
        viewModel.addObserverForPostStatus { [weak self] (success, categorydIds) in
            self?.sendPostSuccess(success)
            /// 如果发布的tab包含当前的tab 刷新一下UI
            if let categorydIds = categorydIds,
               let vc = self?.getCurrentVC(),
               categorydIds.contains(vc.getPageType().getCategoryId) {
                /// 这里发送成功 不代表一定可以刷新出来 所以延时帮用户刷新一下
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    vc.autoRefresh()
                }
            }
        }
    }

    /// 获取config之后 刷新UI
    private func updateFeedOrder(config: RawData.UserCircleConfig) {
        listContainerView.reloadData()
        updateUI()
    }
    override func getCurrentVC() -> MomentsPostListDelegate? {
        let selectedIndex = !viewModel.needShowFilterTab ? 0 : self.titleTabsView.selectedIndex
        if self.listContainerView.validListDict.count <= selectedIndex {
            return nil
        }
        return self.listContainerView.validListDict[selectedIndex] as? MomentsPostListDelegate
    }

    override func getCreatePostService() -> CreatePostApiService? {
        return viewModel.createPostService
    }

    override func getMomentsSendPostBodyParams() -> (categoryId: String?, source: Tracer.FeedCardViewSource?, hashtagContent: String?) {
        return (categoryId: self.viewModel.categoryInputs.id, source: nil, hashtagContent: nil)
    }

    override func trackCreatePostBtnClicked() {
        let pageDetail: MomentsTracer.PageDetail = !viewModel.needShowFilterTab ? .category_recommend
            : (titleTabsView.selectedIndex == 1 ? .category_post : .category_comment)
        MomentsTracer.trackFeedPageViewClick(.post_edit,
                                             circleId: self.viewModel.circleId,
                                             type: .category(viewModel.categoryInputs.id),
                                             detail: pageDetail)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    /// - Parameter listContainerView: UDTabsListContainerView
    func numberOfLists(in listContainerView: UniverseDesignTabs.UDTabsListContainerView) -> Int {
        /// 如果没有 circleConfig 暂时不列表数据 等待UI刷新
        if viewModel.circleConfig == nil {
            return 0
        }
        if !viewModel.needShowFilterTab {
            return 1
        }
        return self.titleTabsView.titles.count
    }
    /// - Parameters:
    ///   - listContainerView: UDTabsListContainerView
    ///   - index: 目标index
    /// - Returns: 遵从UDTabsListContainerViewListDelegate协议的实例
    func listContainerView(_ listContainerView: UniverseDesignTabs.UDTabsListContainerView, initListAt index: Int) -> UniverseDesignTabs.UDTabsListContainerViewDelegate {
        let context = BaseMomentContext()
        let feedOrder: RawData.FeedOrder
        let manageMode: RawData.ManageMode = viewModel.circleConfig?.manageMode ?? .basic
        switch manageMode {
        case .strongIntervention:
            feedOrder = .recommend
        case .recommendV2Mode:
            feedOrder = .recommendV2
        case .basic:
            feedOrder = index == 0 ? .lastReplied : .lastPublish
        @unknown default:
            assertionFailure("unknown case")
            feedOrder = .unspecified
        }
        let vm = PostCategoryDetailViewModel(userResolver: userResolver,
                                             tabID: viewModel.categoryInputs.id,
                                             feedOrder: feedOrder,
                                             manageMode: manageMode,
                                             context: context,
                                             userPushCenter: viewModel.userPushCenter)
        let vc = PostCategoryDetailViewController(userResolver: userResolver, viewModel: vm)
        context.pageAPI = self
        context.dataSourceAPI = vm
        vc.delegate = self
        self.categoryInfoView.tracker = vm.tracker
        return vc
    }

    override func refreshTableView() {
        self.getCurrentVC()?.autoRefresh()
    }
}

extension PostCategoryDetailContainerViewController: PostListVCDelegate {
    func listWillAppear(_ tableView: MomentLinkagePostTableView) {
        self.bgScrollView.bindSubTableView(tableView, maxOffSet: self.maxOffSet)
    }

    func exitCurrentPostList() {
        popSelf()
    }

    /// 刷新tableView 刷新数据
    func willRefreshTableData() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.categoryInfoView.refreshData()
        }
    }

   private func sendPostSuccess(_ success: Bool) {
        guard let window = self.view.window,
              let topVC = self.navigationController?.topViewController,
              topVC === self else {
            return
        }
        if success {
            UDToast.showTips(with: BundleI18n.Moment.Lark_Community_PostedToast, on: window, delay: 1.5)
        } else {
            UDToast.showFailure(with: BundleI18n.Moment.Lark_Community_UnableToPostToast, on: window)
        }
    }
}

extension PostCategoryDetailContainerViewController: PostNavigationBarDelegate {
    /// 点击左边按钮
    func MomentsNavigationViewOnClose(_ view: MomentsPostNavigationBar) {
        if isPresented {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.popSelf()
        }
    }
    func titleViewForNavigation() -> UIView? {
        return self.titleView
    }
    func MomentsNavigationViewOnRightButtonTapped(_ view: MomentsPostNavigationBar) {
        //do nothing
    }
}

extension PostCategoryDetailContainerViewController {
    /// 点击选中或者滚动选中都会调用该方法。适用于只关心选中事件，而不关心具体是点击还是滚动选中的情况。
    func tabsView(_ tabsView: UDTabsView, didSelectedItemAt index: Int) {
        if lastSelectedIndexOfTabsView == index {
            return
        }
        lastSelectedIndexOfTabsView = index
        //埋点处理
        let pageDetail: MomentsTracer.PageDetail
        switch index {
        case 1:
            pageDetail = .category_post
        default:
            pageDetail = .category_comment
        }
        viewModel.trackCategoryFeedShowWithID(viewModel.categoryInputs.id, pageDetail: pageDetail)
        self.categoryInfoView.tracker = self.getCurrentVC()?.getTracker()
    }
}

extension PostCategoryDetailContainerViewController: FeedListDependencyDataDelegate {
    func requestForCircleId() -> String? {
        return viewModel.circleId
    }
}
