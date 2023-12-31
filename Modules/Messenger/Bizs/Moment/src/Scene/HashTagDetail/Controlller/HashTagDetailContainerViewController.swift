//
//  HashTagDetailContainerViewController.swift
//  Moment
//
//  Created by liluobin on 2021/6/27.
//

import Foundation
import LarkUIKit
import UniverseDesignTabs
import UniverseDesignToast
import EENavigator
import RustPB
import LarkRustClient
import LarkEnv
import LarkAppLinkSDK
import UIKit
import UniverseDesignColor
import LarkAccountInterface
import LarkSetting
import LarkEMM
import LarkSensitivityControl
import LarkContainer

final class HashTagDetailContainerViewController: MomentsBasePostListContainerViewController,
                                            UDTabsViewDelegate,
                                            UDTabsListContainerViewDataSource {
    let viewModel: HashTagDetailContainerViewModel
    let isPresented: Bool //true表示VC是present出来的，false表示是push出来的
    var maxOffSet: CGFloat {
        return self.headerView.suggestHeight
    }
    var showCorner = true {
        didSet {
            if showCorner != oldValue {
                updateTitleWrapperViewCorner()
            }
        }
    }
    let cornerRadius: CGFloat = 12
    let titleWrapperView = UIView()
    var lastSelectedIndexOfTabsView = 0
    var hasTrackedPageViewShowWhenFirstLoadScreen = false

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
    private var scrollViewContentSize: CGSize {
        return CGSize(width: self.hostSize.width, height: self.hostSize.height - navigationBarHeight + maxOffSet)
    }
    private lazy var titleTabsView: UDTabsTitleView = {
        let tabsView = UDTabsTitleView()
        tabsView.titles = [BundleI18n.Moment.Lark_Community_TopicsPopularTab,
                           BundleI18n.Moment.Lark_Community_TopicsNewTab]
        tabsView.backgroundColor = UIColor.ud.bgBody
        let config = tabsView.getConfig()
        config.itemSpacing = 20
        config.contentEdgeInsetLeft = 10
        config.isItemSpacingAverageEnabled = false
        tabsView.widthForTitleClosure = { text in
            return MomentsDataConverter.widthForString(text, font: config.titleSelectedFont)
        }
        tabsView.setConfig(config: config)
        /// 配置指示器
        let indicator = UDTabsIndicatorLineView()
        indicator.indicatorHeight = 2
        indicator.indicatorCornerRadius = 0
        tabsView.indicators = [indicator]
        tabsView.delegate = self
        return tabsView
    }()

    private lazy var bgScrollView: LinkageScrollView = {
        let sc = LinkageScrollView()
        sc.contentInsetAdjustmentBehavior = .never
        sc.showsHorizontalScrollIndicator = false
        sc.showsVerticalScrollIndicator = false
        sc.backgroundColor = .clear
        sc.didScrollCallBack = { [weak self] (offset) in
            guard let self = self else { return }
            let maxOffset = self.headerView.titleLabelMaxY
            var alpha = offset.y / maxOffset
            self.titleLabel.alpha = max(alpha, 0)
            if Display.pad {
                self.navigationBar?.backgroundColor = self.headerBgColor.withAlphaComponent(alpha)
            } else {
                self.navigationBar?.backgroundColor = UIColor.ud.bgBody.withAlphaComponent(alpha)
            }
            self.showCorner = self.isRegularStyle || !(offset.y >= self.maxOffSet)
        }
        return sc
    }()

    private lazy var headerView: HashTagDetailHeaderView = {
        let viewModel = HashTagDetailHeaderViewModel(userResolver: self.userResolver, hashtagId: self.viewModel.hashTagId)
        let header = HashTagDetailHeaderView(viewModel: viewModel) { [weak self] (height) in
            self?.updateHeaderViewWith(height: height)
        }
        header.onRefreshHeaderInfo = { [weak self] (tag) in
            self?.titleLabel.text = tag.content
        }
        return header
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        label.textColor = UIColor.ud.N900
        label.text = viewModel.content ?? ""
        label.alpha = 0
        return label
    }()

    private lazy var headerBgImageView: UIView = {
        let view = UIView()
        if Display.pad {
            let imageViewLeft = UIImageView()
            imageViewLeft.image = Resources.hashTagheaderBgPadLeft
            let imageViewRight = UIImageView()
            imageViewRight.image = Resources.hashTagheaderBgPadRight
            view.addSubview(imageViewLeft)
            view.addSubview(imageViewRight)
            imageViewLeft.snp.makeConstraints { make in
                make.left.top.equalToSuperview()
            }
            imageViewRight.snp.makeConstraints { make in
                make.right.top.equalToSuperview()
            }
        } else {
            let imageView = UIImageView()
            imageView.image = UIImage.dynamic(light: Resources.hashTagheaderBgLightMode,
                                              dark: Resources.hashTagheaderBgDarkMode)
            view.addSubview(imageView)
            imageView.snp.makeConstraints { make in
                make.right.top.equalToSuperview()
            }
        }
        return view
    }()

    private let headerBgColor = UIColor.ud.N00.ud.withOver(UIColor.ud.primaryFillSolid03.withAlphaComponent(0.6))
    private lazy var headerBgView: UIView = {
        let view = UIView()
        view.backgroundColor = Display.pad ? headerBgColor : .clear
        return view
    }()

    lazy var listContainerView: UDTabsListContainerView = {
        return UDTabsListContainerView(dataSource: self)
    }()

    private var listContainerHeight: CGFloat {
        return scrollViewContentSize.height - maxOffSet - (!viewModel.needShowFilterTab ? 0 : 40)
    }

    var navigationBar: MomentsPostNavigationBar?

    init(userResolver: UserResolver, viewModel: HashTagDetailContainerViewModel, isPresented: Bool) {
        self.viewModel = viewModel
        self.isPresented = isPresented
        super.init(userResolver: userResolver)
        self.autoRefreshForAnonymousPostCreateSuccessCallBack = { [weak self] in
            self?.switchToNewPostTabIfNeed()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        /// .strongIntervention .recommendV2Mode 不需要展示tab
        viewModel.initCurrentCircle { [weak self] config in
            self?.viewModel.needShowFilterTab = !config.manageMode.isRecommendOrder
            self?.updateFeedOrder()
        }
        addObserves()
    }

    /// 布局当前界面的UI元素
    func setupView() {
        view.backgroundColor = UIColor.ud.bgBase
        isNavigationBarHidden = true
        let navBar = MomentsPostNavigationBar(backImage: isPresented ? Resources.momentsNavBarClose : Resources.blackBack, rightBtnImage: Resources.momentsMoreNav, delegate: self)
        navBar.backgroundColor = UIColor.clear
        navigationBar = navBar
        view.insertSubview(headerBgView, belowSubview: self.contentView)
        contentView.addSubview(headerBgImageView)
        view.addSubview(navBar)

        contentView.addSubview(bgScrollView)
        bgScrollView.addSubview(headerView)
        titleWrapperView.backgroundColor = titleTabsView.backgroundColor
        titleWrapperView.lu.addCorner(corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner], cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        titleWrapperView.addSubview(titleTabsView)
        bgScrollView.addSubview(titleWrapperView)
        bgScrollView.addSubview(listContainerView)
        navBar.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(navigationBarHeight)
        }

        headerBgImageView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            //图片的容器view的高度。由于背景是透明的，所以尽量写大一些也没有问题
            //现在手机端切图的高度是280，ipad切图高度是240，所以取280
            make.height.equalTo(280)
            make.top.equalTo(headerView).offset(-navigationBarHeight)
        }
        headerBgView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(headerBgImageView)
            make.bottom.equalTo(titleTabsView.snp.top).offset(60)
        }
        bgScrollView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.width.equalToSuperview()
            make.top.equalTo(navBar.snp.bottom)
        }
        let suggestHeight = headerView.suggestHeight
        headerView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(suggestHeight)
        }
        updateUI()
    }

    func updateUI() {
        if !viewModel.needShowFilterTab {
            listContainerView.lu.addCorner(corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner], cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
            titleWrapperView.lu.addCorner(corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner], cornerSize: CGSize(width: 0, height: 0))
            listContainerView.clipsToBounds = true
            titleTabsView.listContainer = nil
            titleTabsView.snp.removeConstraints()
            if titleTabsView.superview != nil {
                titleTabsView.removeFromSuperview()
            }
        } else {
            titleWrapperView.backgroundColor = titleTabsView.backgroundColor
            titleWrapperView.lu.addCorner(corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner], cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
            listContainerView.lu.addCorner(corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner], cornerSize: CGSize(width: 0, height: 0))
            if titleTabsView.superview == nil {
                titleWrapperView.addSubview(titleTabsView)
            }
            titleTabsView.listContainer = listContainerView
            titleTabsView.snp.remakeConstraints { (make) in
                make.left.equalToSuperview().offset(6)
                make.right.equalToSuperview().offset(-6)
                make.top.bottom.equalToSuperview()
            }
        }
        let titleWrapperViewHeight: CGFloat = !viewModel.needShowFilterTab ? 0 : 40
        titleWrapperView.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            make.width.equalToSuperview()
            make.top.equalTo(headerView.snp.bottom)
            make.height.equalTo(titleWrapperViewHeight)
        }
        listContainerView.snp.remakeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(titleWrapperView.snp.bottom)
            make.bottom.equalToSuperview()
            make.height.equalTo(listContainerHeight)
        }
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
            self.showCorner = self.isRegularStyle || !(bgScrollView.contentOffset.y >= self.maxOffSet)
            for vc in listContainerView.validListDict.values {
                if let vc = vc as? BasePostListViewController {
                    vc.resizeWhenHostSizeWidthChange()
                }
            }
        }
    }

    private func updateHeaderViewWith(height: CGFloat) {
        bgScrollView.maxOffSetY = maxOffSet
        bgScrollView.contentSize = self.scrollViewContentSize
        headerView.snp.updateConstraints { (make) in
            make.height.equalTo(height)
        }
    }

    private func addObserves() {
        viewModel.addObserverForPostStatus { [weak self] (success) in
            self?.switchToNewPostTabIfNeed()
            self?.sendPostSuccess(success)
            /// 如果发布的tab包含当前的tab 刷新一下UI
            if let vc = self?.getCurrentVC() {
                /// 这里发送成功 不代表一定可以刷新出来 所以延时帮用户刷新一下
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    vc.autoRefresh()
                }
            }
        }
    }

    private func updateFeedOrder() {
        listContainerView.reloadData()
        updateUI()
    }

    func switchToNewPostTabIfNeed() {
        if !viewModel.needShowFilterTab {
            return
        }
        let createTimeListIdx = self.titleTabsView.titles.count - 1
        if self.titleTabsView.selectedIndex != createTimeListIdx {
            self.titleTabsView.selectItemAt(index: createTimeListIdx)
            self.listContainerView.didClickSelectedItem(at: createTimeListIdx)
        }
    }

    func updateTitleWrapperViewCorner() {
        let width = self.showCorner ? cornerRadius : 0
        if !viewModel.needShowFilterTab {
            self.listContainerView.lu.addCorner(corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner], cornerSize: CGSize(width: width, height: width))
            self.titleWrapperView.lu.addCorner(corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner], cornerSize: CGSize(width: 0, height: 0))
        } else {
            self.titleWrapperView.lu.addCorner(corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner], cornerSize: CGSize(width: width, height: width))
            self.listContainerView.lu.addCorner(corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner], cornerSize: CGSize(width: 0, height: 0))
        }
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
        return (categoryId: nil, source: nil, hashtagContent: viewModel.content)
    }

    override func trackCreatePostBtnClicked() {
        let detail: MomentsTracer.PageDetail = !viewModel.needShowFilterTab ? .hashtag_recommend
            : (titleTabsView.selectedIndex == 1 ? .hashtag_new : .hashtag_hot)
        MomentsTracer.trackFeedPageViewClick(.post_edit,
                                             circleId: self.viewModel.circleId,
                                             type: .hashtag(self.viewModel.hashTagId),
                                             detail: detail)
    }

    func numberOfLists(in listContainerView: UniverseDesignTabs.UDTabsListContainerView) -> Int {
        if viewModel.circleConfig == nil {
            return 0
        }
        if !viewModel.needShowFilterTab {
            return 1
        }
        return self.titleTabsView.titles.count
    }

    func listContainerView(_ listContainerView: UniverseDesignTabs.UDTabsListContainerView, initListAt index: Int) -> UniverseDesignTabs.UDTabsListContainerViewDelegate {
        let context = BaseMomentContext()
        let manageMode = viewModel.circleConfig?.manageMode ?? .basic
        let hashTagOrder: RawData.hashTagOrder
        switch manageMode {
        case .basic:
             hashTagOrder = index == 0 ? .participateCount : .createTimeDesc
        case .strongIntervention:
            hashTagOrder = .recommend
        case .recommendV2Mode:
            hashTagOrder = .recommendV2
        @unknown default:
            assertionFailure("unknown case")
            hashTagOrder = .unknown
        }
        let vm = HashTagDetailViewModel(userResolver: userResolver,
                                        hashTagOrder: hashTagOrder,
                                        manageMode: manageMode,
                                        hashTagId: viewModel.hashTagId,
                                        context: context,
                                        userPushCenter: viewModel.userPushCenter)
        let vc = HashTagDetailViewController(userResolver: userResolver, viewModel: vm)
        vc.onFirstScreenLoadFinish = { [weak self] (isEmpty) in
            guard let self = self else { return }
            if !self.viewModel.needShowFilterTab {
                if !self.hasTrackedPageViewShowWhenFirstLoadScreen {
                    self.viewModel.trackCategoryFeedShowWith(
                        pageDetail: .hashtag_recommend)
                }
                return
            }
            if isEmpty, self.titleTabsView.selectedIndex == 0 {
                self.switchToNewPostTabIfNeed()
                //如果调用了switchToNewPostTabIfNeed()，会在didSelected的逻辑中处理埋点，这里不重复处理
            } else {
                //只在加载第一个页面的时候发送埋点，其他时候在点tab的时候处理，避免重复埋
                if !self.hasTrackedPageViewShowWhenFirstLoadScreen {
                    self.viewModel.trackCategoryFeedShowWith(
                        pageDetail: self.titleTabsView.selectedIndex == 0 ? .hashtag_hot : .hashtag_new)
                }
            }
            self.hasTrackedPageViewShowWhenFirstLoadScreen = true
        }
        context.pageAPI = self
        context.dataSourceAPI = vm
        vc.delegate = self
        self.headerView.tracker = vm.tracker
        return vc
    }

    override var scene: MomentContextScene {
        return .hashTagDetail(titleTabsView.selectedIndex, viewModel.hashTagId)
    }

    override func refreshTableView() {
        getCurrentVC()?.autoRefresh()
    }
}
extension HashTagDetailContainerViewController: PostListVCDelegate {
    func listWillAppear(_ tableView: MomentLinkagePostTableView) {
        tableView.backgroundColor = UIColor.ud.bgBody
        self.bgScrollView.bindSubTableView(tableView, maxOffSet: maxOffSet)
    }

    func exitCurrentPostList() {
        popSelf()
    }
    /// 刷新tableView 刷新数据
    func willRefreshTableData() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.headerView.refreshData()
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

extension HashTagDetailContainerViewController: PostNavigationBarDelegate {
    //点击右上角 ... 按钮
    func MomentsNavigationViewOnRightButtonTapped(_ view: MomentsPostNavigationBar) {
        let popoverMenuItemTypes: [MomentsPopOverMenuActionType] = [.copyLink]
        MomentsPopOverMenuManager.showMenuVCWith(presentVC: self,
                                                 pointView: view.rightBtn,
                                                 itemTypes: popoverMenuItemTypes) { [weak self] (type) in
            guard let self = self else { return }
            switch type {
            case .copyLink:
                self.copyPostLink()
            default:
                break
            }
        }
    }

    /// 点击左边按钮
    func MomentsNavigationViewOnClose(_ view: MomentsPostNavigationBar) {
        if isPresented {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.popSelf()
        }
    }
    func titleViewForNavigation() -> UIView? {
        return titleLabel
    }
    private func copyPostLink() {
        guard let domain = DomainSettingManager.shared.currentSetting["applink"]?.first else { return }
        let url = "https://\(domain)\(MomentsHashTagDetialByIDBody.appLinkPatter)?hashtagId=\(self.viewModel.hashTagId)&source=copy"
        do {
            let config = PasteboardConfig(token: Token("LARK-PSDA-moment_hashTag_share_link"))
            try SCPasteboard.generalUnsafe(config).string = url
            UDToast.showTips(with: BundleI18n.Moment.Lark_Community_LinkCopiedToast, on: self.view, delay: 1.5)
        } catch {
            // 业务兜底逻辑
            UDToast.showFailure(with: BundleI18n.Moment.Lark_IM_CopyContent_CopyingIsForbidden_Toast, on: self.view)
        }
    }
}

extension HashTagDetailContainerViewController {
    func tabsView(_ tabsView: UDTabsView, didSelectedItemAt index: Int) {
        if lastSelectedIndexOfTabsView == index {
            return
        }
        lastSelectedIndexOfTabsView = index
        //埋点处理
        let pageDetail: MomentsTracer.PageDetail
        switch index {
        case 1:
            pageDetail = .hashtag_new
        default:
            pageDetail = .hashtag_hot
        }
        viewModel.trackCategoryFeedShowWith(pageDetail: pageDetail)
        self.headerView.tracker = self.getCurrentVC()?.getTracker()
    }
}

extension HashTagDetailContainerViewController: FeedListDependencyDataDelegate {
    func requestForCircleId() -> String? {
        return viewModel.circleId
    }
}
