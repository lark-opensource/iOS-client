//
//  MainTabbarController.swift
//  LarkApp
//
//  Created by KT on 2019/10/17.
//

import Foundation
import EENavigator
import LarkAccountInterface
import RxSwift
import LarkUIKit
import Swinject
import RxCocoa
import RunloopTools
import LarkContainer
import LarkGuide
import LarkSetting
import LarkLeanMode
import SnapKit
import AnimatedTabBar
import LarkKeyCommandKit
import BootManager
import UniverseDesignDrawer
import LarkResource
import SuiteAppConfig
import LarkGuide
import LarkGuideUI
import LKCommonsTracker
import Homeric
import UniverseDesignColor
import UIKit
import LarkTab
import UniverseDesignNotice
import UniverseDesignToast
import UniverseDesignActionPanel
import UniverseDesignPopover
import LarkStorage

public protocol MainTabbarControllerDependency {
    var showTabbarFocusStatus: Driver<Bool> { get }
    func userFocusStatusView() -> UIView?
}

final class MainTabbarController: LkTabbarController, MainTabbarProtocol, SideTabbarViewController {

    lazy var sideBarMenu: SideBarMenu = SideBarMenu(mainTabbar: self)

    var naviBar: NaviBarProtocol?

    private lazy var switchAccountService: SwitchAccountService? = {
        return try? self.userResolver.resolve(assert: SwitchAccountService.self)
    }()

    private lazy var leanModeService: LeanModeService? = {
        return try? self.userResolver.resolve(assert: LeanModeService.self)
    }()

    private lazy var tabbarLifecycle: TabbarLifecycle? = {
        return try? self.userResolver.resolve(assert: TabbarLifecycle.self)
    }()

    private lazy var navigationService: NavigationService? = {
        return try? self.userResolver.resolve(assert: NavigationService.self)
    }()

    private lazy var navigationConfigService: NavigationConfigService? = {
        return try? self.userResolver.resolve(assert: NavigationConfigService.self)
    }()

    private lazy var newGuideManager: NewGuideService? = {
        return try? self.userResolver.resolve(assert: NewGuideService.self)
    }()

    private lazy var navigationDependency: NavigationDependency? = {
        return try? self.userResolver.resolve(assert: NavigationDependency.self)
    }()

    private lazy var passportService: PassportService? = {
        return try? self.userResolver.resolve(assert: PassportService.self)
    }()

    private lazy var passportUserService: PassportUserService? = {
        return try? self.userResolver.resolve(assert: PassportUserService.self)
    }()

    private var showPad3BarNaviStyleDisposeBag = DisposeBag()

    private let badgeEnable: Bool
    private let feedDisorderFixEnable: Bool

    private var tabNoticeView: UDNotice?
    private var noticeTxt: String = ""
    private var noticeActionSheet: UDActionSheet?

    private var tabbarDependency: MainTabbarControllerDependency? {
        try? self.userResolver.resolve(type: MainTabbarControllerDependency.self)
    }

    override init(translucent: Bool, isQuickLauncherEnabled: Bool, userResolver: UserResolver) {
        let fgService = try? userResolver.resolve(assert: FeatureGatingService.self)
        self.badgeEnable = fgService?.staticFeatureGatingValue(with: "lark.tenant.penetration.enable") ?? false
        self.feedDisorderFixEnable = fgService?.staticFeatureGatingValue(with: "lark.core.feed_disorder_fix") ?? false
        super.init(translucent: translucent, isQuickLauncherEnabled: isQuickLauncherEnabled, userResolver: userResolver)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var curTab: Tab? {
        return self.currentTab
    }

    var naviFeatureEnable: Bool {
        return AppConfigManager.shared.naviFeatureIsOn
    }

    override func viewDidLoad() {
        
        moreTabEnabled = !naviFeatureEnable
        super.viewDidLoad()
        // 添加统一导航栏
        self.setupLarkNaviBar(in: self)

        /// 开启自定义导航，注入侧边栏实现
        if UIDevice.current.userInterfaceIdiom == .pad {
            let isTemporaryEnabled = self.temporaryTabService.isTemporaryEnabled
            self.registerEdgeTab { () -> EdgeTabBarProtocol in
                let tabbar: EdgeTabBarProtocol = NewEdgeTabBar(userResolver: self.userResolver)
                return tabbar
            }
            self.edgeTab?.refreshEdgeBarDelegate = self
        }

        // 监听 keyWindow 改变，用来进行多窗口转屏导致的Feed错乱问题的报警检测
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(observeKeyWindowDidChanged),
            name: UIWindow.didBecomeKeyNotification,
            object: nil)

        let moreItemConfig = bottomMoreItem?.stateConfig
        let stateConfig = TabConfig(key: "",
                                    name: "",
                                    icon: moreItemConfig?.defaultIcon,
                                    selectedIcon: moreItemConfig?.selectedIcon,
                                    quickTabIcon: moreItemConfig?.quickBarIcon)
        bottomMoreItem?.stateConfig = Tab.decorateNativeTab(defaultConfig: stateConfig).itemConfig

        RunloopDispatcher.shared.addTask {
            // 请求多租户Badge
            self.getAccountBadge()
            // 导航栏更新
            self.observeTabUpdate()
        }

        DispatchQueue.main.async {
            self.showGuide()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sideBarMenu.hideSideBar(animate: true, completion: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tabbarLifecycle?.fireTabDidAppear()
    }

    // Navi切换数据
    override func didSelectTabViewController(_ tabViewController: UIViewController) {
        self.larkNaviBar(didSwitchTabTo: tabViewController)
    }

    override func didSelectTemporaryViewController() {
        guard self.temporaryTabService.isTemporaryEnabled else { return }

        // iPad切换Tab，添加NaviBar
        if Display.pad {
            self._addLarkNaviBar(in: temporaryTabContainer)
        }
        self.naviBar?.dataSource = temporaryTabContainer
        self.naviBar?.delegate = temporaryTabContainer
    }

    // popover显示的时候展示黑色statusBar
    // Drawer出来的时候，统一白色StatusBar
    override public var preferredStatusBarStyle: UIStatusBarStyle {
        if sideBarMenu.showType == .popover {
            return .default
        }
        return .default
    }

    // Drawer出来的时候，Tab接管StatusBar状态，否则子VC接管
    override var childForStatusBarStyle: UIViewController? {
        return self.selectedViewController
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sideBarMenu.updateWidth()
    }

    private func getAccountBadge() {
        self.switchAccountService?.fetcAccountsBadge()
    }

    override func tabbarStyleDidChange() {
        super.tabbarStyleDidChange()
        guard let navbar = self.naviBar as? LarkNaviBar else { return }
        let container = navbar.getAvatarContainer()
        container.snp.removeConstraints()
        container.removeFromSuperview()
        /// 调整头像容器的层级
        if self.tabbarStyle == .edge {
            // C模式切换到R模式，如果QuickLaunchWindow显示的话需要dismiss掉
            if isQuickLaunchWindowShown {
                dismissQuickLaunchWindow()
            }
            navbar.avatarView.setAvatarSize(size: CGSize(width: 40, height: 40))
            navbar.showAvatarView = false
            edgeTab?.addAvatar(container)
            if let navigationDependency = navigationDependency, navigationDependency.enableUseNewSearchEntranceOnPad() {
                edgeTab?.addSearchEntrenceOnPad()
            }
        } else {
            navbar.avatarView.resetAvatarSize()
            navbar.showAvatarView = true
            if let navigationDependency = navigationDependency, navigationDependency.enableUseNewSearchEntranceOnPad() {
                edgeTab?.removeSearchEntrenceOnPad()
            }
        }
    }

    override func keyBindings() -> [KeyBindingWraper] {
        return super.keyBindings() + switchTabKeyCommand()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // MainTabbarController 自身的 traitCollection 已经被上层改为了 LarkTraitCollection
        // 所以应该去 window 取系统的 traitCollection
        if let window = view.window, window.traitCollection.horizontalSizeClass == .regular {
            sideBarMenu.showType = .popover
        } else {
            sideBarMenu.showType = .slide
        }
    }

    @objc
    func observeKeyWindowDidChanged() {
        guard UIDevice.current.userInterfaceIdiom == .phone else { return }

        guard let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else { return }

        guard let rootVC = keyWindow.rootViewController else { return }

        guard let topVC = UIViewController.topMost(of: rootVC, checkSupport: true) else { return }

        guard getWindowOrientation(keyWindow) == .portrait else { return }

        // key window 改变时检测 safeArea 是否正常，用来统计修复率。
        self.judgeWhetherPostTrackerToSlardar(keyWindow, rootVC, topVC,
                                              isAllCases: true, didFixed: false, isFgEnabled: self.feedDisorderFixEnable)

        guard feedDisorderFixEnable else {
            self.judgeWhetherPostTrackerToSlardar(keyWindow, rootVC, topVC,
                                                  isAllCases: false, didFixed: false, isFgEnabled: false)
            return
        }
        // 多窗口转屏后 Feed 布局错乱修复
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "UIApplicationResumedNotification"),
                                            object: UIApplication.shared,
                                            userInfo: nil)
        }
        // 修复后，在新的 runloop 中检测是否还存在 safeArea 不正确的情况
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.judgeWhetherPostTrackerToSlardar(keyWindow, rootVC, topVC,
                                                  isAllCases: false, didFixed: true, isFgEnabled: true)
        }
    }

    private func observeTabUpdate() {
        if !self.crmodeUnifiedDataDisable {
            // iPhone设备导航变更触发提示信号
            self.navigationConfigService?.iPhoneTabBarUpdateShowTipObservable
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] notice in
                    guard let `self` = self else { return }
                    self.noticeTxt = notice
                    self.showBottomTabBarNoticeIfNeed(notice: notice)
                }).disposed(by: disposeBag)
            // iPad设备导航变更触发提示信号（需要再区分C、R模式）
            self.navigationConfigService?.iPadTabBarUpdateShowTipObservable
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] notice in
                    guard let `self` = self else { return }
                    self.noticeTxt = notice
                    // iPad设备的R模式侧边栏的提醒
                    self.showSideTabBarNoticeIfNeed(notice: notice)
                    // iPad设备的C模式底部栏的提醒
                    self.showBottomTabBarNoticeIfNeed(notice: notice)
                }).disposed(by: disposeBag)
        } else {
            // 底部导航栏（包含iPad设备C模式下的底部栏）变更触发提示信号
            self.navigationConfigService?.bottomTabBarUpdateShowTipObservable
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] notice in
                    guard let `self` = self else { return }
                    self.noticeTxt = notice
                    self.showBottomTabBarNoticeIfNeed(notice: notice)
                }).disposed(by: disposeBag)
            // 侧边导航栏（iPad设备）变更触发提示信号
            self.navigationConfigService?.sideTabBarUpdateShowTipObservable
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] notice in
                    guard let `self` = self else { return }
                    self.noticeTxt = notice
                    self.showSideTabBarNoticeIfNeed(notice: notice)
                }).disposed(by: disposeBag)
        }
    }

    // 展示导航栏更新提示框：包含Mobile设备的底部栏和iPad设备C模式下的底部栏
    func showBottomTabBarNoticeIfNeed(notice: String) {
        let navigationServiceImpl = navigationService as? NavigationServiceImpl
        if self.tabNoticeView?.superview != nil {
            self.removeNoticeView()
            navigationServiceImpl?.didNoticeIsShow(height: 0)
        }
        if let actionSheet = self.noticeActionSheet {
            actionSheet.dismiss(animated: true)
        }
        guard self.tabbarStyle == .bottom, !notice.isEmpty, let tabBar = self.customTabBar else { return }
        Tracker.post(TeaEvent(Homeric.NAVIGATION_APP_UPDATE_NOTICE_VIEW))
        let attribute = NSMutableAttributedString(string: notice)
        /// just for tap event, not really use the scheme
        var config = UDNoticeUIConfig(type: .info, attributedText: attribute)
        config.leadingButtonText = BundleI18n.LarkNavigation.Lark_Core_NavigationBarUpdate_UpdateNow_Button
        config.leadingIcon = BundleResources.LarkNavigation.refreshTabIcon
        config.trailingButtonIcon = BundleResources.LarkNavigation.closeTipIcon
        config.linkTextColor = UIColor.ud.textTitle
        config.lineBreakMode = .byTruncatingTail
        let udNoticeView = UDNotice(config: config)
        udNoticeView.textView.textContainer.lineBreakMode = .byTruncatingTail
        udNoticeView.textView.textContainer.maximumNumberOfLines = 1
        udNoticeView.update()
        tabBar.addSubview(udNoticeView)
        udNoticeView.delegate =  self

        let noticeHeight: CGFloat = 44
        udNoticeView.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(noticeHeight)
            make.bottom.equalTo(tabBar.snp.top)
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(didClickTabUpdate(_:)))
        udNoticeView.addGestureRecognizer(tap)
        self.tabNoticeView = udNoticeView
        navigationServiceImpl?.didNoticeIsShow(height: noticeHeight)
    }

    // 展示导航栏更新提示框：包含Mobile设备的底部栏和iPad设备C模式下的底部栏
    func showSideTabBarNoticeIfNeed(notice: String) {
        self.edgeTab?.showRefreshTabIcon = !notice.isEmpty
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.showBottomTabBarNoticeIfNeed(notice: self.noticeTxt)
    }

    @objc
    func didClickTabUpdate(_ gesture: UITapGestureRecognizer) {
        self.handleTabUpdateEvent()
    }

    func removeNoticeView() {
        self.tabNoticeView?.snp.removeConstraints()
        self.tabNoticeView?.removeFromSuperview()
    }

    override func reopenTab() {
        self.reopenClosedTemporaryTab()
    }

    override func searchItemTapped() {
        guard let navigationDependency = navigationDependency, navigationDependency.enableUseNewSearchEntranceOnPad() else { return }
        self.enterSearch(sourceOfSearchStr: "im", entryAction: "navigation_icon")
        navigationDependency.changeSelectedState(isSelect: true)
    }
}

// MARK: - Navi
extension MainTabbarController {
    // https://bits.bytedance.net/meego/larksuite/issue/detail/211413?parentUrl=%2Flarksuite%2FissueView%2FPdskfslkb%3Ffop%3Dand%26issue_operator-In%3D%255B%257B%2522id%2522%253A270%252C%2522type%2522%253A%2522team%2522%257D%255D%26work_item_status-Nin%3Dwontfix%252CCLOSED%252CRESOLVED#detail
    // 切租户成功时，需要取消监听，因为有个翻转动画，旧tabbar来不及销毁，会在旧租户上看到新切租户的头像，租户名等信息(因为此时信号监听还有效)
    func reset() {
        disposeBag = DisposeBag()
    }

    func isCustomer(user: User) -> Bool {
        return user.type == .c
    }

    /// Setup NaviBar
    /// - Parameter vc: Target VC
    func setupLarkNaviBar(in vc: UIViewController) {
        guard let navigationService = self.navigationService else {
            Self.logger.error("navigationService injected error!")
            return
        }

        guard let passportUserService = self.passportUserService,
                let passportService = self.passportService else {
            Self.logger.error("passportUserService injected error!")
            return
        }

        self.naviBar = LarkNaviBar(navigationService: navigationService, userResolver: self.userResolver, sideBarMenu: sideBarMenu)

        // iPhone 导航栏加载顶层容器，iPad加在SplitVC.main.navi.first
        if Display.phone {
            self._addLarkNaviBar(in: vc)
        }

        RunloopDispatcher.shared.addTask(priority: .emergency) {
            /// todo: 没有找到passport替代的接口
            let currentAccountObservable = AccountServiceAdapter.shared.currentAccountObservable
            Observable.combineLatest(passportService.menuUserListObservable, currentAccountObservable)
                .subscribe(onNext: { [weak self] (accounts, _) in
                    guard let self = self else { return }
                    let user = passportUserService.user
                    let showPad3Bar = self.naviBar?.dataSource?.showPad3BarNaviStyle.value ?? false
                    let needShow = accounts.count > 1 && !self.isCustomer(user: user)
                    /// user 里的avatar同步不及时，这里先取 currentAccount，在修改头像时候能及时变更
                    let currentChatter = AccountServiceAdapter.shared.currentAccountInfo
                    self.naviBar?.avatarKey.onNext((user.userID, currentChatter.avatarKey))
                    self.naviBar?.groupNameText.onNext(user.tenant.localizedTenantName)
                    self.handleShowGroup(showPad3Bar, needShow)
                }).disposed(by: self.disposeBag)

            self.leanModeService?.leanModeStatus
                .distinctUntilChanged()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: {[weak self] (status) in
                    self?.naviBar?.avatarInLeanMode.onNext(status)
                })
                .disposed(by: self.disposeBag)

            self.switchAccountService?.accountsBadgesDriver.drive(onNext: { [weak self] (accountsBadges) in
                guard let self = self else { return }
                // 判断是否屏蔽切租户fg，如果屏蔽了其他租户的消息不应影响Badges。
                let fgService = try? self.userResolver.resolve(assert: FeatureGatingService.self)
                let transferEnable = fgService?.staticFeatureGatingValue(with: "suite_transfer_function") ?? false
                guard transferEnable else { return }
                let totalCount = Int(accountsBadges.values.reduce(0, +))
                self.naviBar?.avatarNewBadgeCount.onNext(totalCount)
            }).disposed(by: self.disposeBag)

            // 接收个人状态的变化
            self.tabbarDependency?.showTabbarFocusStatus
                .drive(onNext: { [weak self] showFocus in
                    guard let self = self else { return }
                    if let containerView = self.tabbarDependency?.userFocusStatusView(), showFocus {
                        self.edgeTab?.addFocus(containerView)
                    } else {
                        self.edgeTab?.removeFocus()
                    }
                }).disposed(by: self.disposeBag)

            self.addShowPad3BarNaviStyleObserve()
        }

        self.naviBar?.isNeedShowBadge = self.badgeEnable
        NewBootManager.shared.addSerialTask { [weak self] in
            guard let self = self else { return }
            self.navigationDependency?.shouldNoticeNewVerison
                .subscribe(onNext: { [weak self] (upgrade) in
                    self?.naviBar?.avatarShouldNoticeNewVersion.onNext(upgrade)
                }).disposed(by: self.disposeBag)
        }
    }

    private func addShowPad3BarNaviStyleObserve() {
        guard let passportUserService = self.passportUserService,
                let passportService = self.passportService else {
            Self.logger.error("passportUserService injected error!")
            return
        }
        // 接收R/C视图切换
        self.naviBar?.dataSource?.showPad3BarNaviStyle
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] showPad3Bar in
                guard let self = self else { return }
                let user = passportUserService.user
                let userList = passportService.userList
                let needShow = userList.count > 1 && !self.isCustomer(user: user)
                self.handleShowGroup(showPad3Bar, needShow)
                if let navbar = self.naviBar as? LarkNaviBar {
                    navbar.titleView.setFocusView(!showPad3Bar ? navbar.dataSource?.userFocusStatusView() : nil)
                }
            }).disposed(by: self.showPad3BarNaviStyleDisposeBag)
    }

    private func handleShowGroup(_ showPad3Bar: Bool, _ needShow: Bool) {
        let shouldShowGroup = !showPad3Bar && needShow
        self.naviBar?.shouldShowGroup.onNext(shouldShowGroup)
    }

    func larkNaviBar(didSwitchTabTo vc: UIViewController?) {
        let dataSource = vc?.tabRootViewController as? (LarkNaviBarDataSource & LarkNaviBarDelegate)

        // iPad切换Tab，添加NaviBar
        if Display.pad {
            self._addLarkNaviBar(in: dataSource)
        }
        self.naviBar?.dataSource = dataSource
        self.naviBar?.delegate = dataSource
        self.showPad3BarNaviStyleDisposeBag = DisposeBag()
        addShowPad3BarNaviStyleObserve()
    }

    private func _addLarkNaviBar(in vc: UIViewController?) {
        guard let naviBar = self.naviBar, let vc = vc else { return }
        // remove last if existed
        naviBar.removeFromSuperview()

        if let firstView = vc.view.subviews.first, Display.phone {
            vc.view.insertSubview(naviBar, aboveSubview: firstView)
        } else {
            vc.view.addSubview(naviBar)
        }

        naviBar.snp.makeConstraints { (make) in
            make.top.equalTo(vc.view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
        }
    }
}

extension MainTabbarController: NewSearchBarTransitionBottomVC {
    var naviBarView: UIView {
        return naviBar ?? UIView()
    }

    func pushAnimationController(
        from: UIViewController,
        to: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        guard to.transitionViewController is SearchBarTransitionTopVCDataSource else {
            return nil
        }
        return SearchBarNewPresentTransition()
    }

    func popAnimationController(
        from: UIViewController,
        to: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        guard from.transitionViewController is SearchBarTransitionTopVCDataSource else {
            return nil
        }
        return SearchBarNewDismissTransition()
    }
}

extension MainTabbarController: GuideSingleBubbleDelegate {
    private func showGuide() {
        let guideKey = "mobile_entry_new_Homepage"

        guard let newGuideManager = self.newGuideManager else {
            Self.logger.error("resolve guide manager error!")
            return
        }

        guard newGuideManager.checkShouldShowGuide(key: guideKey) else {
            Self.logger.info("展示过\(guideKey)引导")
            return
        }

        guard let passportService = self.passportService else {
            Self.logger.error("resolve passportService error!")
            return
        }

        guard passportService.userList.count > 1 else {
            Self.logger.info("租户数目少于2个,不展示引导")
            return
        }

        guard let user = self.passportUserService?.user else {
            Self.logger.error("resolve passportUserService error!")
            return
        }

        let calendar = Calendar.current
        let dateComponents = DateComponents(calendar: calendar, year: 2021, month: 8, day: 16)
        let date = calendar.date(from: dateComponents)
        guard let tenantCreateDate = passportService.foregroundUser.flatMap({ Date(timeIntervalSince1970: $0.createTime) }),
              let standardDate = date,
              tenantCreateDate > standardDate else {
            let tenantCreateDate = passportService.foregroundUser.flatMap({ Date(timeIntervalSince1970: $0.createTime) })
            Self.logger.info("tenant list count: \(passportService.tenantList.count) or create tenant date: \(tenantCreateDate)")
            return
        }

        guard let avatarView = (RootNavigationController.shared.viewControllers.first as? MainTabbarProtocol)?
                .naviBar?
                .getAvatarContainer() else {
            Self.logger.info("获取头像位置失败")
            return
        }

        if avatarView.frame.equalTo(.zero) {
            return
        }

        // 需要租户列表 > 1,并且在8.16日后注册的用户才会显示引导
        Self.logger.info("开始展示引导")

        // get file path
        guard let zipFilePath = BundleConfig.LarkNavigationBundle.path(forResource: "guide_team_join",
                                                                       ofType: "zip",
                                                                       inDirectory: "Lottie")
        else {
            Self.logger.info("[UGGuide]: showTeamJoinBubbleGuide: unzipPath not found")
            return
        }
        // unzipPath
        let cachePath = userResolver.isoPath(in: Domain.biz.core.child("Navigation"), type: .temporary)
        try? cachePath.createDirectoryIfNeeded()
        let unzipPath = cachePath + "LarkNavigation"
        let filePath = unzipPath + "guide_team_join.json"
        // try unzip file
        do {
            try unzipPath.unzipFile(fromPath: AbsPath(zipFilePath), overwrite: true, password: nil)
        } catch let error {
            Self.logger.error("[UGGuide]: showTeamJoinBubbleGuide: lottie文件解压失败!", error: error)
            return
        }

        let tenantName = user.tenant.i18nTenantNames?.currentLocalName ?? user.tenant.tenantName
        let lottieInfo = BubbleLOTImageInfo(filePath: filePath.absoluteString, size: CGSize(width: 240, height: 146))
        let itemConfig = BubbleItemConfig(guideAnchor: TargetAnchor(targetSourceType: .targetView(avatarView),
                                                                     offset: 4,
                                                                     arrowDirection: .left,
                                                                     targetRectType: .circle),
                                          textConfig: .init(detail: BundleI18n.LarkNavigation.Lark_Accounts_OnboardWelcomeToTenant(tenantName)),
                                          bannerConfig: BannerInfoConfig(imageType: .lottie(lottieInfo)),
                                          bottomConfig: .init(rightBtnInfo: ButtonInfo(title: BundleI18n.LarkNavigation.Lark_Accounts_OnboardWelcomeToTenantButton)))

        let singleBubbleConfig = SingleBubbleConfig(delegate: self,
                                                    bubbleConfig: itemConfig,
                                                    maskConfig: MaskConfig())
        DispatchQueue.main.async {
            newGuideManager.showBubbleGuideIfNeeded(guideKey: guideKey,
                                                    bubbleType: .single(singleBubbleConfig),
                                                    dismissHandler: nil,
                                                    didAppearHandler: nil,
                                                    willAppearHandler: { _ in
                Tracker.post(TeaEvent(Homeric.NAVIGATION_BUBBLE_POPUP_LOGIN_VIEW))
            })
        }
    }

    func didClickRightButton(bubbleView: GuideBubbleView) {
        Tracker.post(TeaEvent(Homeric.NAVIGATION_BUBBLE_POPUP_LOGIN_CLICK, params: ["click": "know", "target": "none"]))
        newGuideManager?.closeCurrentGuideUIIfNeeded()
    }
}

// MARK: pad 跳转搜索tab
extension MainTabbarController {
    public func enterSearch(vc: UIViewController) {
        guard self.selectedTab != Tab.search else { return }
        self.selectedTab = Tab.search
        self.setTabViewController(vc)
        self.safeSetSelectedIndex(0)
    }

    public func enterSearch(sourceOfSearchStr: String? = nil, entryAction: String) {
        guard let navigationDependency = navigationDependency, navigationDependency.enableUseNewSearchEntranceOnPad() else { return }
        guard let vc = navigationDependency.getSearchVC(fromTabURL: self.currentTab?.url,
                                                        sourceOfSearchStr: sourceOfSearchStr,
                                                        entryAction: entryAction) else { return }
        self.enterSearch(vc: vc)
     }
}

/// Feed 布局错乱警告
private extension UIWindow {

    var topViewController: UIViewController? {
        var top = rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}

// MARK: Feed 布局错乱修复拓展
private extension MainTabbarController {
    /// 获取 window 方向
    func getWindowOrientation(_ window: UIWindow?) -> UIInterfaceOrientationMask? {
        guard let window = window else {
            return nil
        }
        if let customTopVC = window.customTopViewController, let vc = customTopVC() {
            return vc.supportedInterfaceOrientations
        } else if let topViewController = window.topViewController {
            return topViewController.supportedInterfaceOrientations
        }
        return nil
    }

    /// 根据 SafeArea 是否正确，判断是否给 Slardar 上报埋点，只有 safeArea 错误时，才会上报
    /// - Parameters:
    ///     - window: 当前的 keyWindow
    ///     - rootVC: keyWindow 的根控制器
    ///     - topVC: keyWindow 的顶控制器
    ///     - isAllCases: 筛选出现问题的次数 , true 表示未经过修复，false 表示经过了 FG 判断后的第二次上报
    ///     - didFixed: 上报的埋点，是否是已经修复过，如是则表明修复的方案有问题
    ///     - isFgEnabled: 判断当前埋点是否是走了FG开关
    func judgeWhetherPostTrackerToSlardar(_ window: UIWindow, _ rootVC: UIViewController, _ topVC: UIViewController,
                                          isAllCases: Bool, didFixed: Bool, isFgEnabled: Bool) {
        let topVCName = String(describing: type(of: topVC.self))
        // Tab 内 CCM 页面会误报，先屏蔽 CCM 日志上报
        guard topVCName != "SpaceHomeViewController" else { return }

        // 监听多 window 时 Window safeArea 变化，所以先仅针对竖屏状态做报警
        // 放在修复后的目的是检测修复后，是否还存在 safeArea 不正确的问题
        let windowSafeAreaLayoutFrameX = window.safeAreaLayoutGuide.layoutFrame.minX
        let rootVCSafeAreaLayoutFrameX = rootVC.view.safeAreaLayoutGuide.layoutFrame.minX
        let topVCSafeAreaLayoutFrameX = topVC.view.safeAreaLayoutGuide.layoutFrame.minX

        if windowSafeAreaLayoutFrameX != 0 || rootVCSafeAreaLayoutFrameX != 0 || topVCSafeAreaLayoutFrameX != 0 {
            // 切换至竖屏，且 safearea 不符合竖屏大小进行报警
            let windowName = String(describing: type(of: window.self))
            Self.logger.error("\(windowName) - \(topVCName) safeArea is Error, afterFix: \(!isAllCases)")
            Tracker.post(SlardarEvent(name: "window_rotate_make_feed_disorder_issue",
                                      metric: ["window_safe_area_correct": windowSafeAreaLayoutFrameX == 0,
                                               "root_vc_safe_area_correct": rootVCSafeAreaLayoutFrameX == 0,
                                               "top_vc_safe_area_correct": topVCSafeAreaLayoutFrameX == 0,
                                               "root_vc_name": String(describing: type(of: rootVC.self)),
                                               "top_vc_name": topVCName
                                              ],
                                      category: ["window_name": windowName,
                                                 "did_fixed": didFixed,
                                                 "is_all_cases": isAllCases,
                                                 "is_fg_enabled": isFgEnabled
                                                ],
                                      extra: [:]))
        }
    }
}

extension MainTabbarController: EdgeTabBarRefreshDelegate {
    func edgeTabBarRefreshItemDidClick(_ edgeTabBar: EdgeTabBarProtocol) {
        Self.logger.info("[navigation] did click refresh button on edge bar")
        if let refreshItem = self.edgeTab?.refreshTabItem {
            let rect = CGRect(x: 0, y: 10, width: refreshItem.frame.size.width, height: refreshItem.frame.size.height)
            let popSource = UDActionSheetSource(sourceView: refreshItem, sourceRect: rect, preferredContentWidth: 303, arrowDirection: .down)
            let config = UDActionSheetUIConfig(style: .autoPopover(popSource: popSource), isShowTitle: true, cornerRadius: 8)
            let actionSheet = UDActionSheet(config: config)
            actionSheet.setTitle(self.noticeTxt)
            let item = UDActionSheetItem(title: BundleI18n.LarkNavigation.Lark_Core_NavigationBarUpdate_UpdateNow_Button, titleColor: UDColor.primaryContentDefault) { [weak self] in
                guard let `self` = self else { return }
                self.handleUpdateTabNow(showTips: true)
            }
            actionSheet.addItem(item)
            let cancelItem = UDActionSheetItem(title: BundleI18n.LarkNavigation.Lark_Core_NavigationBarUpdate_NotNow_Button) { [weak self] in
                guard let `self` = self else { return }
                self.handleUpdateTabLater()
            }
            actionSheet.addItem(cancelItem)
            self.present(actionSheet, animated: true)
            self.noticeActionSheet = actionSheet
        }
    }
}

extension MainTabbarController: UDNoticeDelegate {
    func handleLeadingButtonEvent(_ button: UIButton) {
        self.handleUpdateTabNow(showTips: true)
    }

    func handleTrailingButtonEvent(_ button: UIButton) {
        self.handleUpdateTabLater()
    }

    func handleTabUpdateEvent() {
        guard let noticeView = self.tabNoticeView,
              !self.noticeTxt.isEmpty else { return }
        let source = UDActionSheetSource(sourceView: noticeView,
                                         sourceRect: noticeView.bounds,
                                         arrowDirection: .up)
        let config = UDActionSheetUIConfig(isShowTitle: true, popSource: source)

        let actionsheet = UDActionSheet(config: config)
        actionsheet.setTitle(self.noticeTxt)
        actionsheet.addDefaultItem(text: BundleI18n.LarkNavigation.Lark_Core_NavigationBarUpdate_UpdateNow_Button) { [weak self] in
            guard let `self` = self else { return }
            Tracker.post(TeaEvent(Homeric.NAVIGATION_APP_UPDATE_NOTICE_CLICK, params: ["click": "update_now"]))
            self.handleUpdateTabNow(showTips: true)
        }
        actionsheet.setCancelItem(text: BundleI18n.LarkNavigation.Lark_Core_NavigationBarUpdate_NotNow_Button) { [weak self] in
            guard let `self` = self else { return }
            Tracker.post(TeaEvent(Homeric.NAVIGATION_APP_UPDATE_NOTICE_CLICK, params: ["click": "update_later"]))
            self.handleUpdateTabLater()
        }
        self.present(actionsheet, animated: true)
        self.noticeActionSheet = actionsheet
    }

    func handleTextButtonEvent(URL: URL, characterRange: NSRange) {
        /// not need implement
    }

    // TODO: @wanghaidong 当 tab 更新时，调用此方法
    public func handleUpdateTabNow(showTips: Bool) {
        Self.logger.info("[navigation] did click update now")
        guard let navigationConfigService = self.navigationConfigService else { return }
        guard let navigationService = self.navigationService else { return }
        if let info = navigationConfigService.reloadLocalData() {
            (navigationService as? NavigationServiceImpl)?.reloadTabs()

            // iPad 和 Mobile 的数据源要加起来才是所有的 Tab
            let allItems = navigationService.allTabs.all
                .compactMap {
                    // 这边有点恶心，之前都是业务方注入的，有很多定制逻辑（红点），但是，但是，但是
                    // 现在AppInfo里面多了N多的字段，用来各种定制和交互控制，所以必须以服务端下发的AppInfo为准
                    // 为了不影响原来的逻辑，只能在这边更新tabBarItem里面的tab对象，不能使用业务方自己Provider提供的
                    if let tabBarItem = TabRegistry.resolve($0)?.makeTabItem(userResolver: self.userResolver) {
                        tabBarItem.tab = $0
                        return tabBarItem
                    } else {
                        return nil
                    }
                }
            if !self.crmodeUnifiedDataDisable {
                let iPhoneMainTabs = navigationService.allTabs.iPhone.main
                let iPhoneQuickTabs = navigationService.allTabs.iPhone.quick

                let iPadMainTabs = navigationService.allTabs.iPad.main
                let iPadQuickTabs = navigationService.allTabs.iPad.quick

                self.resetTabBarItems(allTabBarItems: allItems)
                self.updateMainItemsOrder(iPhoneMainTabs: iPhoneMainTabs, iPadMainTabs: iPadMainTabs)
                self.updateQuickItemsOrder(iPhoneQuickTabs: iPhoneQuickTabs, iPadQuickTabs: iPadQuickTabs)
            } else {
                let bottomMainTabs = navigationService.allTabs.bottom.main
                let bottomQuickTabs = navigationService.allTabs.bottom.quick

                let edgeMainTabs = navigationService.allTabs.edge.main
                let edgeQuickTabs = navigationService.allTabs.edge.quick

                self.resetTabBarItems(allTabBarItems: allItems)
                self.updateMainItemsOrder(bottomMainTabs: bottomMainTabs, edgeMainTabs: edgeMainTabs)
                self.updateQuickItemsOrder(bottomQuickTabs: bottomQuickTabs, edgeQuickTabs: edgeQuickTabs)
            }
            let switchToFirstTab = { [weak self] (tab: Tab) in
                guard let `self` = self else { return }
                if tab != self.selectedTab {
                    self.switchTab(to: tab)
                } else {
                    self.getTabBarItem(for: tab)?.selectedState()
                }
            }

            // 更新后，如果之前选中的tab仍存在则保持之前tab选中状态
            // 否则使用第一个支持switch打开的tab作为选中tab
            let switchToCurTab = { [weak self] (tab: Tab) in
                guard let self = self else { return }
                self.switchTab(to: tab)
                if self.isInBottomMainBar(tab) {
                    self.getTabBarItem(for: tab)?.selectedState()
                } else {
                    self.bottomMoreItem?.selectedState()
                }
            }
            if !self.crmodeUnifiedDataDisable {
                let iPhoneMainTabs = navigationService.allTabs.iPhone.main
                let iPhoneQuickTabs = navigationService.allTabs.iPhone.quick

                let iPadMainTabs = navigationService.allTabs.iPad.main
                let iPadQuickTabs = navigationService.allTabs.iPad.quick

                // 这逻辑TM要吐了
                let bottomTabs: [Tab]
                if Display.pad {
                    bottomTabs = iPadMainTabs + iPadQuickTabs
                } else {
                    bottomTabs = iPhoneMainTabs + iPhoneQuickTabs
                }
                if self.tabbarStyle == .bottom {
                    // iPad设备C模式和iPhone设备都有底部栏
                    if bottomTabs.contains(self.selectedTab) {
                        switchToCurTab(self.selectedTab)
                    } else if let firstTab = bottomTabs.first(where: { $0.openMode == .switchMode }) {
                        switchToCurTab(firstTab)
                    }
                } else {
                    // 只有iPad设备有侧边栏
                    if let firstTab = iPadMainTabs.first {
                        switchToFirstTab(firstTab)
                    }
                }
            } else {
                let bottomMainTabs = navigationService.allTabs.bottom.main
                let bottomQuickTabs = navigationService.allTabs.bottom.quick

                let edgeMainTabs = navigationService.allTabs.edge.main
                let edgeQuickTabs = navigationService.allTabs.edge.quick

                if self.tabbarStyle == .bottom {
                    let bottomTabs = bottomMainTabs + bottomQuickTabs
                    if bottomTabs.contains(self.selectedTab) {
                        switchToCurTab(self.selectedTab)
                    } else if let firstTab = bottomTabs.first(where: { $0.openMode == .switchMode }) {
                        switchToCurTab(firstTab)
                    }
                } else {
                    if let firstTab = edgeMainTabs.first {
                        switchToFirstTab(firstTab)
                    }
                }
            }
            self.edgeTab?.showRefreshTabIcon = false
            self.removeNoticeView()
            let navigationServiceImpl = navigationService as? NavigationServiceImpl
            navigationServiceImpl?.didNoticeIsShow(height: 0)
            self.noticeTxt = ""
            navigationConfigService.resetLocalData()
            if showTips {
                let toast = BundleI18n.LarkNavigation.Lark_Core_NavigationBarUpdate_Updated_Toast
                UDToast.showSuccess(with: toast, on: self.view)
            }
        }
    }

    func handleUpdateTabLater() {
        Self.logger.info("[navigation] did click update later")
        self.removeNoticeView()
        let navigationServiceImpl = navigationService as? NavigationServiceImpl
        navigationServiceImpl?.didNoticeIsShow(height: 0)
        self.noticeTxt = ""
        if self.tabbarStyle == .edge {
            self.edgeTab?.showRefreshTabIcon = false
        }
        let toast = BundleI18n.LarkNavigation.Lark_Core_NavigationBarUpdate_UpdateAfterRestart_Toast()
        UDToast.showSuccess(with: toast, on: self.view)
    }
}
