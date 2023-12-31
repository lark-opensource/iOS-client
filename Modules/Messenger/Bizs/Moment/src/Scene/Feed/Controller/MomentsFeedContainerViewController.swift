//
//  MomentsFeedContainerViewController.swift
//  Moments
//
//  Created by liluobin on 2021/4/19.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import LarkTab
import AnimatedTabBar
import LarkNavigation
import LarkContainer
import UniverseDesignTabs
import UniverseDesignBadge
import EENavigator
import RustPB
import UniverseDesignToast
import LarkSDKInterface
import LarkRustClient
import LarkFeatureGating
import UniverseDesignActionPanel
import LarkMessageCore
import LarkAccountInterface
import LarkMessengerInterface

let momentsAnonymousPostRefreshInterval = 0.5
final class MomentsFeedContainerViewController: MomentsBasePostListContainerViewController, UDTabsListContainerViewDataSource {

    private lazy var titleTabsView: UDTabsTitleView = {
        let tabs = UDTabsTitleView()
        let config = tabs.getConfig()
        config.itemSpacing = 20
        config.contentEdgeInsetLeft = 16
        config.contentEdgeInsetRight = 30
        config.isItemSpacingAverageEnabled = false
        tabs.widthForTitleClosure = { text in
            return MomentsDataConverter.widthForString(text, font: config.titleSelectedFont)
        }
        tabs.setConfig(config: config)
        tabs.backgroundColor = UIColor.ud.bgBody
        return tabs
    }()

    private lazy var titleTabsBgView: UIView = {
        let view = UIView()
        view.backgroundColor = titleTabsView.backgroundColor
        return view
    }()

    private lazy var editButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = .clear
        btn.addTarget(self, action: #selector(editBtnClick), for: .touchUpInside)
        btn.setImage(Resources.rightEidtMenu, for: .normal)
        btn.adjustsImageWhenHighlighted = false
        btn.isHidden = true
        return btn
    }()

    private let disposeBag = DisposeBag()
    private let userPushCenter: PushNotificationCenter
    let viewModel: MomentsFeedContainerViewModel
    var currentAccountIconBadge: UDBadge?
    var accountSwitcherIconBadge: UDBadge?
    var isAppeared: Bool = false
    private let titleTabsViewHeight: CGFloat = 40
    lazy var listContainerView: MomentsTabsListContainerView = {
        let view = MomentsTabsListContainerView(dataSource: self)
        let borderView = UIView(frame: CGRect.zero)
        contentView.addSubview(borderView)
        borderView.backgroundColor = UIColor.ud.lineDividerDefault
        borderView.snp.makeConstraints { (make) in
            make.top.left.right.equalTo(0)
            make.height.equalTo(1 / UIScreen.main.scale)
        }
        return view
    }()

    private weak var popoverVC: UIViewController?

    private lazy var momentTab: MomentTab? = {
        return TabRegistry.resolve(Tab.moment) as? MomentTab
    }()

    @ScopedInjectedLazy private var redDotNotifyService: RedDotNotifyService?

    //是否播放摇铃铛动画。app生命周期内仅会播放至多一次
    static var shouldStartAnimationShakeBell = true

    init(userResolver: UserResolver, userPushCenter: PushNotificationCenter) {
        self.userPushCenter = userPushCenter
        self.viewModel = MomentsFeedContainerViewModel(userResolver: userResolver)
        super.init(userResolver: userResolver)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Self.logger.info("MomentsFeedContainerViewController view info \(Display.pad) -- \(self.view.bounds.size)")
        setupUI()
        self.addObserves()
    }

    func setupUI() {
        MomentsFeedFristScreenItem.shared.startTabRenderCost()
        /// 配置标题
        isNavigationBarHidden = true
        titleTabsView.titles = viewModel.getTabTitles()
        /// 配置指示器
        let indicator = UDTabsIndicatorLineView()
        indicator.indicatorHeight = 2
        indicator.indicatorCornerRadius = 0
        titleTabsView.indicators = [indicator]
        self.contentView.addSubview(titleTabsView)
        self.view.insertSubview(titleTabsBgView, belowSubview: self.contentView)
        self.contentView.addSubview(editButton)
        titleTabsView.delegate = self
        titleTabsView.listContainer = listContainerView
        self.view.insertSubview(listContainerView, belowSubview: self.createPostButton)
        listContainerView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(titleTabsView.snp.bottom)
        }
        titleTabsView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview().offset(-30)
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(self.naviHeight)
            make.height.equalTo(titleTabsViewHeight)
        }
        titleTabsBgView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.bottom.equalTo(titleTabsView)
        }
        editButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(titleTabsView)
            make.right.equalToSuperview()
        }
    }

    func addObserves() {
        self.viewModel.badgeNoti?.badgePush
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (info) in
                guard let self = self else { return }
                if let currentAccountIconBadge = self.currentAccountIconBadge, let badgeCount = self.momentsAccountService?.getCurrentUserTotalBadgeCount(info) {
                    currentAccountIconBadge.config.number = badgeCount
                    currentAccountIconBadge.isHidden = badgeCount <= 0
                }

                if let accountSwitcherIconBadge = self.accountSwitcherIconBadge,
                       let badgeCount = self.momentsAccountService?.getOtherUsersTotalBadgeCount(info) {
                    accountSwitcherIconBadge.config.number = badgeCount
                    accountSwitcherIconBadge.isHidden = badgeCount <= 0
                }
            }).disposed(by: self.disposeBag)

        self.viewModel.getUserGlobalConfigAndSettingsWithFinish { [weak self] in
            self?.reloadDataWithSelectTabID("\(RawData.PostTab.FeedTabId.feedRecommend.rawValue)")
            MomentsFeedFristScreenItem.shared.endTabRenderCost()
        } onError: { [weak self] (error) in
            guard let self = self else { return }
            MomentsErrorTacker.trackFeedError(error,
                                              event: .momentsShowHomePage,
                                              failSence: .configAndSettigsFail)
            UDToast.showFailure(with: BundleI18n.Moment.Lark_Community_OopsSmthWrong, on: self.view.window ?? self.view)
        }
        self.viewModel.addObserverForConfigNotWithRefresh { [weak self] (indexs) in
            guard let self = self, !indexs.isEmpty else { return }
            self.titleTabsView.titles = self.viewModel.getTabTitles()
            self.titleTabsView.reloadData()
        }
        self.viewModel.addObserverForPostStatus { [weak self] (success, categorydIds) in
            self?.sendPostSuccess(success)
            /// 如果发布的tab包含当前的tab 刷新一下UI
            if let categorydIds = categorydIds, let vc = self?.getCurrentVC(), categorydIds.contains(vc.getPageType().getCategoryId) {
                /// 这里发送成功 不代表一定可以刷新出来 所以延时帮用户刷新一下
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    vc.autoRefresh()
                }
            }
        }

        self.momentsAccountService?.rxAnyAccountInfoChanged
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                let officialUser = self?.viewModel.getCurrentOfficialUser()
                self?.changeAccountButton.officialUser = officialUser
                self?.viewModel.badgeNoti?.forceGetBadgeFromServer()
                self?.reloadNaviBar()
            }).disposed(by: disposeBag)

        self.viewModel.userSwitchAccountCallBack = { [weak self] in
            self?.toRecommendTabAndRefresh()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isAppeared = true
        if Self.shouldStartAnimationShakeBell, let badgeNoti = viewModel.badgeNoti,
           (badgeNoti.currentBadge.messageCount > 0 || badgeNoti.currentBadge.reactionCount > 0) {
            Self.shouldStartAnimationShakeBell = false
            showBadgeButton.startAnimation(delay: 0.5)
        }
    }
    lazy var showBadgeButton: MomentsNotifyBellButton = {
        let button = MomentsNotifyBellButton()
        button.addTarget(self, action: #selector(noticeBtnClick(_:)), for: .touchUpInside)
        return button
    }()
    lazy var changeAccountButton: MomentsChangeAccountButton = {
        let button = MomentsChangeAccountButton(currentUser: try? userResolver.resolve(assert: PassportUserService.self).user)
        button.officialUser = viewModel.getCurrentOfficialUser()
        button.addTarget(self, action: #selector(changeAccountBtnClick(_:)), for: .touchUpInside)
        return button
    }()
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isAppeared = false
    }

    override func onResize(widthChanged: Bool, heightChanged: Bool) {
        super.onResize(widthChanged: widthChanged, heightChanged: heightChanged)
        if widthChanged {
            for vc in listContainerView.validListDict.values {
                if let vc = vc as? MomentsFeedListViewController {
                    vc.hostSize = self.hostSize
                    vc.resizeWhenHostSizeWidthChange(isRegularStyle: isRegularStyle)
                }
            }
        }
    }

    func refreshCurrentDisplayVC() {
        if let vc = getCurrentVC() {
            vc.autoRefresh()
        }
        if Display.pad {
           closeChildViewControllers()
        }
    }

    override func getCurrentVC() -> MomentsPostListDelegate? {
        let selectedIndex = self.titleTabsView.selectedIndex
        return self.listContainerView.validListDict[selectedIndex] as? MomentsPostListDelegate
    }

    override func getCreatePostService() -> CreatePostApiService? {
        return viewModel.createPostService
    }

    override func getMomentsSendPostBodyParams() -> (categoryId: String?, source: Tracer.FeedCardViewSource?, hashtagContent: String?) {
        return (categoryId: nil, source: .feed, hashtagContent: nil)
    }

    override func trackCreatePostBtnClicked() {
        Tracer.trackCommunitySendPostClick(source: .sendBtn)
    }
    /// 默认选中的tab
    func reloadDataWithSelectTabID(_ tabId: String?) {
        let titles = self.viewModel.getTabTitles()
        self.titleTabsView.titles = titles
        if let tabId = tabId, let index = self.viewModel.tabs.firstIndex(where: { $0.id == tabId }) {
            self.titleTabsView.defaultSelectedIndex = index
        }
        var needShowTabs = true
        /// 如果没有配置办款 且没有关注按钮
        if !viewModel.hasCategories, !viewModel.tabs.contains(where: { $0.id == "\(RawData.PostTab.FeedTabId.feedFollowing.rawValue)" }) {
            needShowTabs = false
        }
        let height = !needShowTabs ? 0 : titleTabsViewHeight
        self.titleTabsView.isHidden = !needShowTabs
        titleTabsView.snp.updateConstraints { (make) in
            make.height.equalTo(height)
        }
        self.editButton.isHidden = self.titleTabsView.isHidden
        self.titleTabsView.reloadData()
    }

    private func deleTabForId(_ id: String) {
        guard titleTabsView.selectedIndex < viewModel.tabs.count,
              viewModel.tabs[titleTabsView.selectedIndex].id == id else {
            return
        }
        viewModel.tabs.removeAll { $0.id == id }
        reloadDataWithSelectTabID("\(RawData.PostTab.FeedTabId.feedRecommend.rawValue)")
    }

    @objc
    func userProfileClick() {
        let userID = userResolver.userID
        let body = MomentUserProfileByIdBody(userId: userID)
        userResolver.navigator.presentOrPush(body: body,
                                       wrap: LkNavigationController.self,
                                       from: self,
                                       prepareForPresent: { (vc) in
            vc.modalPresentationStyle = .formSheet
        })
        Tracer.trackCommunityProfileView(source: .feed)
        trackFeedPageViewClick(.moments_profile)
    }

    @objc
    func noticeBtnClick(_ sender: UIButton) {
        let vc = MomentsUserNoticeContainerViewController(userResolver: self.userResolver,
                                                          circleId: self.viewModel.circleID)
        if Display.pad {
            let size = CGSize(width: 375, height: max(UIScreen.main.bounds.height, UIScreen.main.bounds.width))
            vc.navFromForPad = self
            vc.popoverPresentationController?.backgroundColor = UIColor.ud.bgBody
            MomentsIpadPopoverAdapter.popoverVC(vc, fromVC: self.navigationController ?? self, sourceView: sender, preferredContentSize: size, permittedArrowDirections: .up)
        } else {
            self.navigationController?.pushViewController(vc, animated: true)
        }
        trackFeedPageViewClick(.notification(self.currentAccountIconBadge?.config.number ?? 0))
    }

    @objc
    func changeAccountBtnClick(_ sender: UIButton) {
        guard let myOfficialUsers = self.viewModel.myOfficialUsers,
              let currentUserId = self.viewModel.currentOperatorUserInfo?.userID,
              let momentsAccountService,
              let currentBadgeInfo = self.viewModel.badgeNoti?.currentBadgeInfo else { return }
        let pickerView = MomentsAnonymousPickerViewFactory.createOfficialUserPicker(momentsAccountService: momentsAccountService,
                                                                                    badgeInfo: currentBadgeInfo,
                                                                                    showBottomLine: false,
                                                                                    userResolver: self.viewModel.userResolver)
        pickerView.showPickerView()
        pickerView.delegate = self
        pickerView.autoDismiss = true
        /// 区分IPad & 手机上的展示
        if !Display.pad {
            pickerView.backgroundColor = .clear
            let actionPanel = MomentsActionPanel(childView: pickerView,
                                                 height: CGFloat(pickerView.containerHeight),
                                                 backgroundColor: pickerView.contentBackgroundColor,
                                                 safeAreaInsets: self.view.safeAreaInsets)
            self.present(actionPanel, animated: true)
            self.popoverVC = actionPanel
        } else {
            let size = CGSize(width: 375, height: pickerView.containerHeight)
            let scrollView = AutoScrollableContainer(contentHeight: CGFloat(pickerView.containerHeight),
                                                     childView: pickerView,
                                                     childViewHeight: CGFloat(pickerView.containerHeight))
            scrollView.backgroundColor = pickerView.contentBackgroundColor
            self.popoverVC = MomentsIpadPopoverAdapter.popoverView(scrollView,
                                                                   fromVC: self,
                                                                   sourceView: sender,
                                                                   preferredContentSize: size,
                                                                   backgroundColor: UIColor.ud.bgBody,
                                                                   permittedArrowDirections: .up)
        }
    }

    /// 编辑按钮点击事件
    @objc
    private func editBtnClick() {
        if viewModel.tabs.isEmpty,
           titleTabsView.selectedIndex < viewModel.tabs.count {
            return
        }
        trackFeedPageViewClick(.category_setting)
        let body = MomentsCategoryEditBody(selectedTab: viewModel.tabs[titleTabsView.selectedIndex],
                                           usedTabs: viewModel.tabs) { [weak self] (tab) in
            guard let self = self else { return }
            if let idx = self.viewModel.tabs.firstIndex(where: { $0.id == tab.id }) {
                self.titleTabsView.selectItemAt(index: idx)
                self.listContainerView.didClickSelectedItem(at: idx)
                self.dismiss(animated: true, completion: nil)
            } else {
                let body = MomentsPostCategoryDetialByIDBody(categoryID: tab.id)
                self.userResolver.navigator.push(body: body, from: self)
                self.dismiss(animated: false, completion: nil)
            }
        } finishBlock: { [weak self](tabs) in
            guard let self = self, self.titleTabsView.selectedIndex < self.viewModel.tabs.count else { return }
            let tabID = self.viewModel.tabs[self.titleTabsView.selectedIndex].id
            self.viewModel.tabs = tabs
            self.reloadDataWithSelectTabID(tabID)
        }
        userResolver.navigator.present(body: body, from: self) { vc in
            vc.modalPresentationStyle = .formSheet
        }
    }

    @objc
    func onSearchButtonTapped() {
        let body = SearchMainBody(topPriorityScene: nil, sourceOfSearch: .moments)
        userResolver.navigator.push(body: body, from: self)
    }

    /// - Parameter listContainerView: UDTabsListContainerView
    func numberOfLists(in listContainerView: UniverseDesignTabs.UDTabsListContainerView) -> Int {
        return self.viewModel.tabs.count
    }

    /// - Parameters:
    ///   - listContainerView: UDTabsListContainerView
    ///   - index: 目标index
    /// - Returns: 遵从UDTabsListContainerViewListDelegate协议的实例
    func listContainerView(_ listContainerView: UniverseDesignTabs.UDTabsListContainerView, initListAt index: Int) -> UniverseDesignTabs.UDTabsListContainerViewDelegate {
        if viewModel.manageMode == nil {
            assertionFailure("manageMode fail to nil")
            Self.logger.error("moments manageMode fail to nil")
        }
        let manageMode = viewModel.manageMode ?? .basic
        let contextForRecommand = BaseMomentContext()
        let vc = MomentsFeedListViewController(userResolver: userResolver,
                                               context: contextForRecommand,
                                               userPushCenter: userPushCenter,
                                               sourceType: .recommand,
                                               manageMode: manageMode,
                                               tabInfo: viewModel.tabs[index],
                                               isRegularStyle: isRegularStyle,
                                               hostSize: self.hostSize)
        contextForRecommand.pageAPI = vc
        vc.delegate = self
        vc.navHeight = self.naviHeight
        return vc
    }

    func toRecommendTabAndRefresh() {
        if let recommendIndex = self.viewModel.tabs.firstIndex(where: { $0.isRecommendTab }) {
            if Display.pad {
                closeChildViewControllers()
            }
            view.layoutIfNeeded()
            self.titleTabsView.selectItemAt(index: recommendIndex)
            self.listContainerView.didClickSelectedItem(at: recommendIndex)
            (self.listContainerView.validListDict[recommendIndex] as? MomentsPostListDelegate)?.autoRefresh()
        }
    }

    func closeChildViewControllers() {
        if let navVC = self.navigationController as? LkNavigationController {
            navVC.popToRootViewController(animated: false)
        }
    }
}

extension MomentsFeedContainerViewController: FeedListEventDelegate {
    func viewDidAppearForVC(_ vc: MomentsFeedListViewController) {
        self.listContainerView.clearCacheObjectIfNeed()
        MomentsTracer.trackFeedPageView(circleId: self.viewModel.circleID, type: .tabInfo(vc.viewModel.tabInfo), detail: nil)
    }

    func didClickEmptyPageActionBtn() {
        createPost(source: .feed)
    }

    func getReactionMenuBarFromVC() -> UIViewController? {
        return self
    }
    /// 当前VC在最上面的时候 才需要处理
   private func sendPostSuccess(_ success: Bool) {
        guard let window = self.view.window, isAppeared else {
            return
        }
        if success {
            UDToast.showTips(with: BundleI18n.Moment.Lark_Community_PostedToast, on: window, delay: 1.5)
        } else {
            UDToast.showFailure(with: BundleI18n.Moment.Lark_Community_UnableToPostToast, on: window)
        }
    }
    func invalidTabID(_ id: String) {
        self.deleTabForId(id)
    }
}

extension MomentsFeedContainerViewController: UDTabsViewDelegate {
    func tabsView(_ tabsView: UniverseDesignTabs.UDTabsView, didSelectedItemAt index: Int) {
        if let feedVC = self.listContainerView.validListDict[index] as? MomentsFeedListViewController {
            trackFeedPageViewClick(.category, pageType: .tabInfo(feedVC.viewModel.tabInfo), pageDetail: .category_comment)
        }
    }
}

extension MomentsFeedContainerViewController: TabRootViewController {
    var tab: Tab { .moment }
    var controller: UIViewController { self }

    /// 首屏数据Ready
    var firstScreenDataReady: BehaviorRelay<Bool>? { nil }
}

extension MomentsFeedContainerViewController: TabbarItemTapProtocol {
    /// 刷新当前的VC
    func onTabbarItemDoubleTap() {
        refreshCurrentDisplayVC()
    }
}

extension MomentsFeedContainerViewController: TabBarEventViewController {
    func didSwitchToTabBarController(_ tabType: TabType, oldType: TabType) {
        self.redDotNotifyService?.dotNotify(enable: false)
        self.redDotNotifyService?.putTabDotUpdate()
        self.viewModel.getOfficialAccountInto()
        Tracer.trackCommunitFeedPageView(source: .larkTab)
        if let momentTab = self.momentTab {
            MomentsTracer.trackNavigationClick(tabType: tabType,
                                               badge: momentTab.badge?.value,
                                               isReminder: self.redDotNotifyService?.settingEnable ?? false,
                                               circleId: self.viewModel.circleID,
                                               pageType: self.getCurrentVC()?.getPageType())
        }
    }

    func didSwitchOutTabBarController(_ tabType: TabType, oldType: TabType) {
        self.redDotNotifyService?.dotNotify(enable: true)
    }
}

extension MomentsFeedContainerViewController {
    //封装MomentsTracer.trackFeedPageViewClick
    func trackFeedPageViewClick(_ clickType: MomentsTracer.FeedPageViewClickType,
                                pageType: MomentsTracer.PageType? = nil,
                                pageDetail: MomentsTracer.PageDetail? = nil) {
        let type = pageType ?? self.getCurrentVC()?.getPageType()
        MomentsTracer.trackFeedPageViewClick(clickType,
                                             circleId: self.viewModel.circleID,
                                             type: type,
                                             detail: pageDetail)
    }
}

extension MomentsFeedContainerViewController: FeedListDependencyDataDelegate {
    func requestForCircleId() -> String? {
        return viewModel.circleID
    }
}

extension MomentsFeedContainerViewController: AnonymousBusinessPickerViewDelegate {
    func pickViewDidSelectItem(pickView: AnonymousBusinessPickerView, selectedIndex: Int?, entityID: String?) {
        guard let entityID = entityID else {
            return
        }
        viewModel.updateCurrentMomentUser(userID: entityID)
    }

    func pickViewWillDismiss(pickView: AnonymousBusinessPickerView) {
        self.popoverVC?.dismiss(animated: true)
    }

    func pickViewWillDidReceiveUserInteraction(selectedIndex: Int?) {
    }
}
