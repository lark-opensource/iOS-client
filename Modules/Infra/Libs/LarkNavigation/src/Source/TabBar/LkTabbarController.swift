//
//  LkTabbarController.swift
//  Lark
//
//  Created by zhuchao on 2017/2/20.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import AnimatedTabBar
import LarkUIKit
import EENavigator
import LarkAlertController
import Swinject
import LKCommonsLogging
import AppContainer
import LarkGuide
import SuiteAppConfig
import LarkPerf
import ThreadSafeDataStructure
import LarkContainer
import RunloopTools
import LarkTab
import LarkZoomable
import LarkSplitViewController
import LarkFeatureGating
import RustPB
import UniverseDesignNotice
import UniverseDesignActionPanel
import UniverseDesignIcon
import UniverseDesignToast
import LarkStorage
import LarkFontAssembly
import LarkLocalizations
import LarkQuickLaunchInterface
import BootManager

public protocol LkTabbarControllerDelegate: AnyObject {
    func getSupplementVC() -> UIViewController?
}

extension LkTabbarControllerDelegate {
    func getSupplementVC() -> UIViewController? { return nil }
}

class LkTabbarController: AnimatedTabBarController {

    static let maxBadgeCont = 999

    static let logger = Logger.log(LkTabbarController.self, category: "LarkNavigation.LkTabBarController")

    private var lastTaptime: TimeInterval = 0
    private var lastDoubleTapTime: TimeInterval = 0
    private var lastTapTab: Tab = Tab(url: "", appType: .native, key: "")
    private var switchTabPerf: SafeDictionary<String, SwitchTabMonitor.Params> = [:] + .readWriteLock

    @KVConfig(key: KVKeys.Navigation.editGuideShowed, store: .dynamic(KVStores.Navigation.buildGlobal))
    private var editGuideShowed: Bool

    @ScopedInjectedLazy private var guideService: GuideService?
    @ScopedInjectedLazy private var navigationService: NavigationService?
    @ScopedInjectedLazy private var navigationConfigService: NavigationConfigService?
    @ScopedInjectedLazy private var navigationDependency: NavigationDependency?
    @ScopedInjectedLazy private var quickLaunchService: QuickLaunchService?

    /// 用户自己添加到主导航的应用支持展示角标FG
    private lazy var openplatformAppBadgeFGEnabled: Bool = userResolver.fg.staticFeatureGatingValue(with: "openplatform.main_tab.op_app_badge")

    /// TabKey: AppInfo
    lazy var edgeTabInfo: [String: Basic_V1_NavigationAppInfo] = {
        // CRMode数据统一GA后把重复的代码删除
        if !self.crmodeUnifiedDataDisable {
            if let iPad = navigationConfigService?.originalAllTabsinfo?.iPad {
                let infos = iPad.main + iPad.quick
                return infos.reduce([:], { (result, info) -> [String: Basic_V1_NavigationAppInfo] in
                    var result = result
                    result[info.key] = info
                    return result
                })
            } else {
                return [:]
            }
        } else {
            if let edge = navigationConfigService?.originalAllTabsinfo?.edge {
                let infos = edge.main + edge.quick
                return infos.reduce([:], { (result, info) -> [String: Basic_V1_NavigationAppInfo] in
                    var result = result
                    result[info.key] = info
                    return result
                })
            } else {
                return [:]
            }
        }
    }()

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return self.viewControllers?.first?.supportedInterfaceOrientations ?? .allButUpsideDown
    }

    override var shouldAutorotate: Bool {
        return self.viewControllers?.first?.shouldAutorotate ?? true
    }

    convenience init(isQuickLauncherEnabled: Bool, userResolver: UserResolver) {
        self.init(translucent: false, isQuickLauncherEnabled: isQuickLauncherEnabled, userResolver: userResolver)
    }

    init(translucent: Bool, isQuickLauncherEnabled: Bool, userResolver: UserResolver) {
        let config = TabBarConfig(
            minBottomTab: NavigationConfig.mainTabRange.lowerBound,
            maxBottomTab: NavigationConfig.mainTabRange.upperBound,
            translucent: translucent
        )
        super.init(tabBarConfig: config, isQuickLauncherEnabled: isQuickLauncherEnabled, userResolver: userResolver)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadViewControllers),
            name: Zoom.didChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadViewControllers),
            name: LarkFont.boldTextStatusDidChange,
            object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        Self.logger.info("<NAVIGATION_BAR> [----> tab] deinit LKTabbarController")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        NSObject.cancelPreviousPerformRequests(
            withTarget: self,
            selector: #selector(notiDidFinishLayoutSubviews),
            object: nil
        )
        perform(#selector(notiDidFinishLayoutSubviews), with: nil, afterDelay: 0.0)
    }

    @objc
    private func notiDidFinishLayoutSubviews() {
        NotificationCenter.default.post(name: .lkTabbarDidLayoutSubviews, object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.dependancy = self
        self.observeSwitchTabPerf()

        RunloopDispatcher.shared.addTask {
            self.observeSpringBoardBadge()
            self.observeTabResourceChange()
        }

        self.animatedTabBarDelegate = self
        self.temporaryTabContainer.closeCallback = { [weak self] (tab) in
            guard let `self` = self else { return }
            if let tab = self.temporaryTabContainer.tabContainable {
                self.closeTemporaryTab.use(tab.tabURL)
            }
            self.temporaryTabService.removeTab(ids: [tab.tabContainableIdentifier])
        }
    }

    func switchTab(to tab: Tab) {
        // SwitchTab 数据校验
        guard Tab.tabKeyDics.values.contains(tab) else {
            let msg = "<NAVIGATION_BAR> no locoal tab existed: \(tab.urlString)"
            assertionFailure(msg)
            LkTabbarController.logger.error(msg)
            return
        }
        guard let tabItem = getTabBarItem(for: tab) else { return }
        selectedTab = tabItem.tab
    }

    override func tabbarStyleDidChange() {
        super.tabbarStyleDidChange()
        guard let navigationService = self.navigationService else { return }
        navigationService.tabbarStyle = self.tabbarStyle
    }

    override func quickNavigationDidAppear(isSlide: Bool) {
        super.quickNavigationDidAppear(isSlide: isSlide)
        self.showEditAlert()
        NavigationTracker.didShowQuickNavigation(slide: isSlide)
    }

    private var willSelectedTabTime: CFTimeInterval?
    override func willSelectTab(_ tab: Tab, oldTab: Tab) {
        guard tab != oldTab else { return }
        self.willSelectedTabTime = CACurrentMediaTime()

        let isInitialize = self.viewController(for: tab) == nil
        let tabKey = tab.key
        let tabURL = tab.urlString
        //每次点击tab的时候重新设置当前tab的埋点信息。
        self.switchTabPerf[tab.key] = SwitchTabMonitor.Params()
        CoreEventMonitor.SwithTabCost.start(tabKey: tabKey, isInitialize: isInitialize)
        //开始可感知埋点
        let disposedKey = SwitchTabTracker.shared.start(tabURL: tabURL, isInitialize: isInitialize)
        self.switchTabPerf[tab.key]?.disposeKey = disposedKey
        // 不是第一次切Tab，通知Rust（启动的Tab Rust拿得到）
        if !oldTab.urlString.isEmpty {
            navigationConfigService?.noticeRustSwitchTab(tabKey: tabKey)
        }
        handleSelectingTab(tab)
        super.willSelectTab(tab, oldTab: oldTab)
    }

    override func didSelectTab(_ tab: Tab, oldTab: Tab) {
        super.didSelectTab(tab, oldTab: oldTab)
        if let navigationServiceImpl = navigationService as? NavigationServiceImpl {
            navigationServiceImpl.updateTab(oldTab: oldTab, newTab: tab)
        }
    }

    public override func eventViewController(for tab: Tab) -> TabBarEventViewController? {
        return self.viewController(for: tab)?.tabEventVC
    }

    /// 切换到选中的 TabVC（如果 TabVC 未创建，则在此处创建）
    private func handleSelectingTab(_ tab: Tab) {
        // TODO: 在此处根据 Tab 类别，决定以何种方式打开页面（Switch、Push、Present）
        guard !(tab.isCustomType() && self.tabbarStyle == .edge) else { return }
        if let vc = self.viewController(for: tab) {
            self.setTabViewController(vc)
        } else if let vc = self.generateViewController(for: tab) {
            self.setTabViewController(vc)
        } else {
            assertionFailure("can not find viewController")
        }
    }

    @objc
    private func reloadViewControllers() {
        if Display.pad {
            dismiss(animated: true) {
                self.reconstructAllTabViewControllers()
            }
        } else {
            reconstructAllTabViewControllers()
        }
    }
    
    private func reconstructAllTabViewControllers() {
        guard let currentVCs = viewControllers else { return }
        var reservedTabs: [Tab] = []
        for (index, vc) in currentVCs.enumerated() {
            guard let tabRootVC = vc.tabRootViewController else { continue }
            if index == 0 || tabRootVC.deamon {
                reservedTabs.append(tabRootVC.tab)
            }
        }
        let newViewControllers = reservedTabs.compactMap {
            self.generateViewController(for: $0)
        }
        guard !newViewControllers.isEmpty else { return }
        safeSetViewControllers(newViewControllers, animated: false)
        didSelectTabViewController(newViewControllers.first!)
    }

    private var lastVCInitTime: CFTimeInterval?
    private func generateViewController(for tab: Tab) -> UIViewController? {
        let url = tab.url
        let id = TimeLogger.shared.logBegin(eventName: "\(url)")
        let last = CACurrentMediaTime()
        self.lastVCInitTime = last
        if var controller = Navigator.shared
            .response(for: url, context: tab.extra)
            .resource as? UIViewController {
            // 路由注册的VC对应的Tab要和 TabRegistry的匹配
            guard let tabRoot = controller.tabRootViewController, tabRoot.tab == tab else {
                let msg = "<NAVIGATION_BAR> generateViewController error, tab donot match \(url)"
                assertionFailure(msg)
                LkTabbarController.logger.error(msg)
                //没有获取到vc，需要移除埋点信息
                self.switchTabPerf.removeValue(forKey: tab.key)
                return nil
            }
            self.switchTabPerf[tab.key]?.initVCCost = (CACurrentMediaTime() - last) * 1_000
            self.observeFirstScreenDataReady(tabRoot)
            controller.hookTabVCLifeCycle()
            if Display.pad {
                controller.isLkShowTabBar = true
                // 当tabVC时NavigationController时，其初始viewControllers也需要设置isLkShowTabBar，否则iPad上bottom tabBar无法显示
                if let navTabVC = controller as? UINavigationController {
                    navTabVC.viewControllers.first?.isLkShowTabBar = true
                    // UITabbarController调用setViewControllers时，当多于6个VC时，系统会默认把多余的VC加入到moreNavigation里，
                    // moreNavigation自身就是一个UINavigationController，不能再push一个节点是UINavigationController的导航栈
                    // 此时需要wrapper一层
                    let wrapper = TabbarWrapperController()
                    wrapper.isLkShowTabBar = true
                    navTabVC.willMove(toParent: wrapper)
                    wrapper.addChild(navTabVC)
                    navTabVC.view.frame = wrapper.view.frame
                    wrapper.view.addSubview(navTabVC.view)
                    navTabVC.didMove(toParent: wrapper)
                    controller = wrapper
                }
                switch url {
                case Tab.feed.url:
                    let feedNavi = LkNavigationController(rootViewController: controller)
                    let splitVC = SplitViewController(supportSingleColumnSetting: true)
                    splitVC.setViewController(feedNavi, for: .supplementary)
                    splitVC.setViewController(feedNavi, for: .compact)
                    if let currentController = controller as? LkTabbarControllerDelegate,
                       let filterVC = currentController.getSupplementVC() {
                        splitVC.setViewController(filterVC, for: .primary)
                    }
                    splitVC.preferredPrimaryColumnWidth = 184
                    if let feedVC = controller as? SplitViewControllerDelegate {
                        splitVC.delegate = feedVC
                    }
                    controller = splitVC
                    splitVC.defaultVCProvider = { () -> DefaultVCResult in
                        return DefaultVCResult(defaultVC: DefaultDetailController(), wrap: LkNavigationController.self)
                    }
                case Tab.contact.url, Tab.mail.url, Tab.appCenter.url, Tab.todo.url, Tab.minutes.url:
                    let navi = LkNavigationController(rootViewController: controller)
                    let splitVC = SplitViewController(supportSingleColumnSetting: false)
                    splitVC.setViewController(navi, for: .primary)
                    splitVC.setViewController(navi, for: .compact)
                    splitVC.isShowSidePanGestureView = false
                    splitVC.isShowPanGestureView = false
                    controller = splitVC
                    splitVC.defaultVCProvider = { () -> DefaultVCResult in
                        return DefaultVCResult(defaultVC: DefaultDetailController(), wrap: LkNavigationController.self)
                    }
                case Tab.byteview.url:
                    controller = LkNavigationController(rootViewController: controller)
                    // UITabbarController调用setViewControllers时，当多于6个VC时，系统会默认把多余的VC加入到moreNavigation里，
                    // moreNavigation自身就是一个UINavigationController，不能再push一个节点是UINavigationController的导航栈
                    // 此时需要wrapper一层
                    let wrapper = TabbarWrapperController()
                    wrapper.isLkShowTabBar = true
                    controller.willMove(toParent: wrapper)
                    wrapper.addChild(controller)
                    controller.view.frame = wrapper.view.frame
                    wrapper.view.addSubview(controller.view)
                    controller.didMove(toParent: wrapper)
                    controller = wrapper
                default:
                    break
                }
            }
            TimeLogger.shared.logEnd(identityObject: id, eventName: "\(url)")
            // 第一次Tab初始化耗时
            if let last = self.willSelectedTabTime {
                let cost = (CACurrentMediaTime() - last) * 1000
                NavigationTracker.trackTabInitialize(tab: tab, cost: cost)
            }
            return controller
        }
        return nil
    }
    /// mainTab
    private var observeDisposeBag = DisposeBag()
    /// 临时区
    private var observeDisposeContainableBag = DisposeBag()
    private var observeBottomMoreDisposeBag = DisposeBag()
    private var observeEdgeMoreDisposeBag = DisposeBag()

    override func resetTabBarItems(allTabBarItems: [AbstractTabBarItem]) {
        super.resetTabBarItems(allTabBarItems: allTabBarItems)
        // 只有一个tabbar隐藏
        if allTabBarItems.count == 1 && self.moreTabEnabled == false {
            self.tabBar.isHidden = true
        } else {
            self.tabBar.isHidden = false
        }
        RunloopDispatcher.shared.addTask(priority: .high) { [weak self] in
            let representables = allTabBarItems.compactMap { TabRegistry.resolve($0.tab) }
            self?.observeItem(representables)
        }
    }

    override func didSet(iPhoneMain tabOrder: [Tab]) {
        super.didSet(iPhoneMain: tabOrder)
    }
    override func didSet(iPhoneQuick tabOrder: [Tab]) {
        super.didSet(iPhoneQuick: tabOrder)
        self.observeMoreBadge(for: .bottom, moreTabs: tabOrder.compactMap { TabRegistry.resolve($0) })
    }
    override func didSet(iPadMain tabOrder: [Tab]) {
        super.didSet(iPadMain: tabOrder)
    }
    override func didSet(iPadQuick tabOrder: [Tab]) {
        super.didSet(iPadQuick: tabOrder)
        // iPad设备C模式下虽然数据是用的iPad，但是展现上确是底部栏，需要特化重新计算更多的Badge
        if Display.pad {
            // C模式（主导航最多显示5个，显示不下的要加到快捷导航的最前面）
            let mainTabs = allTabBarItems.iPad.main.map { $0.tab }
            let mainCount = mainTabs.count
            var quickTabs = tabOrder
            if mainCount > iPadCModeMaxMainCount {
                // 因为C模式下底部主导航最多只能显示5个，所以把截断的“拼到”快捷导航前面
                let mainSuffix = Array(mainTabs[iPadCModeMaxMainCount..<mainCount])
                quickTabs = mainSuffix + tabOrder
            }
            self.observeMoreBadge(for: .bottom, moreTabs: quickTabs.compactMap { TabRegistry.resolve($0) })
        }
    }
    // CRMode数据统一GA后删除下面重复代码
    override func didSet(bottomMain tabOrder: [Tab]) {
        super.didSet(bottomMain: tabOrder)
    }
    override func didSet(bottomQuick tabOrder: [Tab]) {
        super.didSet(bottomQuick: tabOrder)
        self.observeMoreBadge(for: .bottom, moreTabs: tabOrder.compactMap { TabRegistry.resolve($0) })
    }
    override func didSet(edgeMain tabOrder: [Tab]) {
        super.didSet(edgeMain: tabOrder)
    }
    override func didSet(edgeQuick tabOrder: [Tab]) {
        super.didSet(edgeQuick: tabOrder)
    }

    private let totalBadge = BehaviorRelay<Int>(value: 0)

    override func removeTabKey(_ key: String) {
        if key == selectedTab.key, selectedTab.isCustomType(), let tab = self.temporaryTabContainer.tabContainable {
            closeTemporaryTab.use(tab.tabURL)
        }
        unsafeTabKeyCache.remove(key)

        var mainRankItem = self.mainTabBarItems.compactMap { transferToRankItem(for: $0) }
        var quickRankItem = self.quickTabBarItems.compactMap { transferToRankItem(for: $0) }

        mainRankItem.removeAll {
            $0.tab.key == key
        }

        quickRankItem.removeAll {
            $0.tab.key == key
        }

        self.temporaryTabs.removeAll(where: { item in
            item.tab.key == key
        })

        edgeTabBarDidReorderItem(main: mainRankItem, hidden: quickRankItem, temporary: temporaryTabs)
    }

    override func addTabContainableTask() {
        super.addTabContainableTask()
        guard openplatformAppBadgeFGEnabled else {
            Self.logger.info("addTabContainableTask openplatformAppBadgeFGEnabled close")
            return
        }
        RunloopDispatcher.shared.addTask(priority: .high) { [weak self] in
            guard let self = self else { return }
            let containables = self.temporaryTabService.tabContainables
            self.observeItem(containables)
        }
    }

    private func observeItem(_ tabContainables: [TabContainable]) {
        observeDisposeContainableBag = DisposeBag()
        observeBadge(tabContainables)
    }

    // 监听每个Tab的Badge，以及计算SpringBoard总的Badge
    private func observeBadge(_ tabContainables: [TabContainable]) {
        for tabContainable in tabContainables {
            guard let badge = tabContainable.badge, let style = tabContainable.badgeStyle else {
                let candidate = tabContainable.transferToTabCandidate()
                let tabItem = TabBarItem.tranformBy(candidate)
                setBadge(at: tabItem, badge: .none, style: .weak)
                continue
            }
            // 订阅每一个Tab的Badge更新通知
            Observable.combineLatest(badge, style)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (badge, style) in
                    guard let self = self else { return }
                    // 记录下每个Tab的Badge更新，上报日志（排查红点问题的重要手段）
                    Self.logger.info("[NavigationTabBadge] Tab: \(tabContainable.tabTitle) TabID: \(tabContainable.tabID) Update Badges: count = \(badge.description), style = \(style.description), tabbarStyle = \(self.tabbarStyle.description)")
                    // 收到业务方Badge通知后刷新UI，Badge数量正确与否完全取决于业务方的通知，UI只是无脑刷新
                    let tabItem = TabBarItem.tranformBy(tabContainable.transferToTabCandidate())
                    setBadge(at: tabItem, badge: badge, style: style)
                }).disposed(by: observeDisposeContainableBag)
        }
    }
}

extension LkTabbarController: AnimatedTabBarDependancy {
    func getTabRootViewController(from vc: UIViewController) -> TabRootViewController? {
        return vc.tabRootViewController
    }
}

extension LkTabbarController {
    private func transferToRankItem(for item: AbstractTabBarItem) -> RankItem? {
        if let info = edgeTabInfo[item.tab.key] {
            return RankItem(tab: item.tab,
                            stateConfig: item.stateConfig,
                            name: item.title,
                            primaryOnly: info.primaryOnly,
                            unmovable: info.unmovable,
                            uniqueID: info.uniqueID)
        } else {
            return RankItem(tab: item.tab,
                            stateConfig: item.stateConfig,
                            name: item.title,
                            primaryOnly: false,
                            unmovable: false,
                            uniqueID: item.tab.key)
        }
    }
}

// MARK: - update
extension LkTabbarController {
    private func setBadge(for tab: Tab, badge: LarkTab.BadgeType, style: BadgeRemindStyle) {
        guard let tabItem = getTabBarItem(for: tab) else { return }
        setBadge(at: tabItem, badge: badge, style: style)
    }

    private func setMainTabbarIcon(for tab: Tab, icon: UIImage, selectedIcon: UIImage) {
        guard let tabItem = getTabBarItem(for: tab) else { return }
        changeMainTabbarIcon(for: tabItem, image: icon, selectedImage: selectedIcon)
    }

    private func setQuickTabbarIcon(for tab: Tab, icon: UIImage) {
        guard let tabItem = getTabBarItem(for: tab) else { return }
        changeQuickTabbarIcon(for: tabItem, image: icon)
    }
}

// MARK: - observe
extension LkTabbarController {

    private func observeTabResourceChange() {
        guard let navigationConfigService = self.navigationConfigService else { return }
        guard navigationConfigService.updateTabResourceEnable else { return }
        navigationConfigService.dataChangeObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                LkTabbarController.logger.info("<NAVIGATION_BAR> new tab resource: observe having fetched new tab resource")
                /// 针对非native的应用，监听到新的数据，如果tab物料有更新，需要更新到UI上
                if let info = navigationConfigService.getNavigationInfoByLocal() {
                    if !self.crmodeUnifiedDataDisable {
                        // main tab
                        let mainTabs: [Basic_V1_NavigationAppInfo]
                        if Display.pad {
                            mainTabs = info.iPad.main
                        } else {
                            mainTabs = info.iPhone.main
                        }
                        self.handleMainTabResourceChange(mainTabs)
                        // quick tab
                        let quickTabs: [Basic_V1_NavigationAppInfo]
                        if Display.pad {
                            quickTabs = info.iPad.quick
                        } else {
                            quickTabs = info.iPhone.quick
                        }
                        self.handleQuickTabResourceChange(quickTabs)
                    } else {
                        // main tab
                        let mainTabs = info.bottom.main
                        self.handleMainTabResourceChange(mainTabs)
                        // quick tab
                        let quickTabs = info.bottom.quick
                        self.handleQuickTabResourceChange(quickTabs)
                    }
                }
            }).disposed(by: disposeBag)
    }

    private func handleMainTabResourceChange(_ mainTabs: [Basic_V1_NavigationAppInfo]) {
        mainTabs.forEach { tabInfo in
            if let tab = NavigationServiceImpl.parseNonNativeTab(by: tabInfo, userResolver: self.userResolver),
               let oldTab = self.getTabBarItem(for: tab) {
                Self.logger.info("<NAVIGATION_BAR> new tab resource: mainTab \(String(describing: tab.appid)), \(tab.appType)")
                Self.logger.info("<NAVIGATION_BAR> new tab resource: default icon change:\(oldTab.tab.mobileRemoteDefaultIcon != tab.mobileRemoteDefaultIcon)")
                Self.logger.info("<NAVIGATION_BAR> new tab resource: select icon change:\(oldTab.tab.mobileRemoteSelectedIcon != tab.mobileRemoteSelectedIcon)")
                if tab.mobileRemoteDefaultIcon != oldTab.tab.mobileRemoteDefaultIcon ||
                    tab.mobileRemoteSelectedIcon != oldTab.tab.mobileRemoteSelectedIcon {
                    let tabBarItem = tab.makeTabItem(userResolver: self.userResolver)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        // download icon need time
                        if let icon = tabBarItem.stateConfig.defaultIcon,
                           let selectIcon = tabBarItem.stateConfig.selectedIcon {
                            // update item icon & select icon
                            Self.logger.info("<NAVIGATION_BAR> new tab resource: update icon & selectIcon")
                            self.changeMainTabbarIcon(for: oldTab, image: icon, selectedImage: selectIcon)
                        }
                    }
                }
                Self.logger.info("<NAVIGATION_BAR> new tab resource: title change:\(oldTab.title != tab.tabName)")
                if oldTab.title != tab.tabName {
                    // update item title
                    oldTab.title = tab.tabName
                    NotificationCenter.default.post(name: Tab.tabNameChangeNotification, object: tab)
                }
                oldTab.tab = tab
            }
        }
    }

    private func handleQuickTabResourceChange(_ quickTabs: [Basic_V1_NavigationAppInfo]) {
        quickTabs.forEach { tabInfo in
            if let quickTab = NavigationServiceImpl.parseNonNativeTab(by: tabInfo, userResolver: self.userResolver),
               let oldTab = self.getTabBarItem(for: quickTab) {
                LkTabbarController.logger.info("<NAVIGATION_BAR> new tab resource: quickTab \(String(describing: quickTab.appid)), \(quickTab.appType)")

                Self.logger.info("<NAVIGATION_BAR> new tab resource: quick icon change:\(oldTab.tab.mobileRemoteSelectedIcon != quickTab.mobileRemoteSelectedIcon)")
                Self.logger.info("<NAVIGATION_BAR> new tab resource: quick tab mobile update icon:\(String(describing: quickTab.mobileRemoteSelectedIcon))")
                Self.logger.info("<NAVIGATION_BAR> new tab resource: quick tab mobile old icon: \(String(describing: oldTab.tab.mobileRemoteSelectedIcon))")
                if quickTab.mobileRemoteSelectedIcon != oldTab.tab.mobileRemoteSelectedIcon {
                    // from v5.15, show quick icon use `remoteSelectedIcon`
                    let tabBarItem = quickTab.makeTabItem(userResolver: self.userResolver)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        // download icon need time
                        if let quickIcon = tabBarItem.stateConfig.quickBarIcon {
                            // update item icon & select icon
                            Self.logger.info("<NAVIGATION_BAR> new tab resource: update quick icon")
                            self.changeQuickTabbarIcon(for: oldTab, image: quickIcon)
                        }
                    }
                }
                LkTabbarController.logger.info("<NAVIGATION_BAR> new tab resource: quick tab title change:\(oldTab.title != quickTab.tabName)")
                if oldTab.title != quickTab.tabName {
                    // update item title
                    oldTab.title = quickTab.tabName
                    NotificationCenter.default.post(name: Tab.tabNameChangeNotification, object: quickTab)
                }
                oldTab.tab = quickTab
            }
        }
    }

    private func observeItem(_ tabRepresentables: [TabRepresentable]) {
        observeDisposeBag = DisposeBag()
        observeBadge(tabRepresentables)
        observeMainIcon(tabRepresentables)
        observeQuickIcon(tabRepresentables)
    }

    // 监听每个Tab的Badge，以及计算SpringBoard总的Badge
    private func observeBadge(_ tabRepresentables: [TabRepresentable]) {
        for tabRepresentable in tabRepresentables {
            guard let badge = tabRepresentable.badge, let style = tabRepresentable.badgeStyle else {
                setBadge(for: tabRepresentable.tab, badge: .none, style: .weak)
                continue
            }
            let version = tabRepresentable.badgeVersion?.value ?? "none"
            // 订阅每一个Tab的Badge更新通知
            Observable.combineLatest(badge, style)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (badge, style) in
                    guard let self = self else { return }
                    // 记录下每个Tab的Badge更新，上报日志（排查红点问题的重要手段）
                    LkTabbarController.logger.info("[NavigationTabBadge] Tab: \(tabRepresentable.tab.name ?? tabRepresentable.tab.key) Update Badges: count = \(badge.description), style = \(style.description), version = \(version), tabbarStyle = \(self.tabbarStyle.description)")
                    // 收到业务方Badge通知后刷新UI，Badge数量正确与否完全取决于业务方的通知，UI只是无脑刷新
                    self.setBadge(for: tabRepresentable.tab, badge: badge, style: style)
                }).disposed(by: observeDisposeBag)
        }

        // 桌面SpringBoard的总Badge
        let tabsNeedObserve = tabRepresentables.filter {
            // 收集所有”有Badge“并且”需要累加到SpringBoard“的Tab
            $0.badge != nil && $0.springBoardBadgeEnable != nil
        }
        Observable.combineLatest(
            tabsNeedObserve.compactMap {
                Observable.combineLatest(
                    $0.badge!.distinctUntilChanged(),
                    $0.springBoardBadgeEnable!.distinctUntilChanged())
        }).subscribe(onNext: { [weak self] (badges) in
            // 记录下所有有Badge并且设置过SpringBoard开关的应用
            let logTabs = tabsNeedObserve.map { ($0.tab.name ?? $0.tab.key, $0.badge?.value.description) }
            LkTabbarController.logger.info("[NavigationTabBadge] SpringBoard Badges: tabsNeedObserve = \(logTabs)")
            let lists = badges.filter { $0.1 }.map { $0.0.count }
            // print badge
            LkTabbarController.logger.info("[NavigationTabBadge] SpringBoard Badges: lists = \(lists)")
            // update badge signal（累加所有的Badge）
            self?.totalBadge.accept(lists.reduce(0, +))
        }).disposed(by: observeDisposeBag)

    }

    ///  在 More Tabs 发生改变的时候，更新订阅
    /// - Parameter tabs: More Tabs
    /// - Note: Bottom More 在排序发生变化时，需要重新订阅
    ///         和 Bottom More  更新时机不一样的是，Edge More 在数据未发生变化的时候，例如旋屏，也可能导致 Edge More Items 的变化
    private func observeMoreBadge(for style: TabbarStyle, moreTabs: [TabRepresentable]) {
        let bag: DisposeBag
        let moreItem: AbstractTabBarItem?
        LkTabbarController.logger.info("<NAVIGATION_BAR> [NavigationTabBadge] Observe More Badge, Style is bottom \(style == .bottom)")
        switch style {
        case .bottom:
            observeBottomMoreDisposeBag = DisposeBag()
            bag = observeBottomMoreDisposeBag
            moreItem = bottomMoreItem
        case .edge:
            observeEdgeMoreDisposeBag = DisposeBag()
            bag = observeEdgeMoreDisposeBag
            moreItem = edgeMoreItem
        }
        let tabsWithBadge = moreTabs.filter({ $0.badge != nil && $0.badgeStyle != nil })
        let types = tabsWithBadge.compactMap { $0.badge }
        let styles = tabsWithBadge.compactMap { $0.badgeStyle }

        let o1 = Observable.combineLatest(types)
        let o2 = Observable.combineLatest(styles)
        Observable.combineLatest(o1, o2).observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (types, styles) in
                guard let self = self else { return }
                // Calculate badge for more button.
                let numbers = types.map {
                    return $0.count
                }
                LkTabbarController.logger.info("<NAVIGATION_BAR> [NavigationTabBadge] Observe More Badge, Type Nunmbers: \(numbers)")
                if let moreBadge = self.mergeBadges(types, styles) {
                    LkTabbarController.logger.info("<NAVIGATION_BAR> [NavigationTabBadge] Observe More Badge, Update More badge")
                    moreItem?.updateBadge(type: moreBadge.0, style: moreBadge.1)
                }
            }).disposed(by: bag)
    }

    // 主Tab图标更新
    private func observeMainIcon(_ tabs: [TabRepresentable]) {
        tabs.filter { $0.mutableIcon != nil && $0.mutableSelectedIcon != nil }
            .forEach { tab in
                Observable.combineLatest(tab.mutableIcon!, tab.mutableSelectedIcon!)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] (icon, selectedIcon) in
                        self?.setMainTabbarIcon(for: tab.tab, icon: icon, selectedIcon: selectedIcon)
                    }).disposed(by: observeDisposeBag)
        }
    }

    // Quick图标更新
    private func observeQuickIcon(_ tab: [TabRepresentable]) {
        tab.filter { $0.mutableQuickIcon != nil }
            .forEach { tab in
                tab.mutableQuickIcon!
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] img in
                        self?.setQuickTabbarIcon(for: tab.tab, icon: img)
                    }).disposed(by: observeDisposeBag)
        }
    }

    private func getPageSceneBy(tab: Tab) -> PageKeeperScene {
        if self.mainTabBarItems.contains(where: { item in
            item.tab == tab
        }) {
            return .main
        } else if self.quickTabBarItems.contains(where: { item in
            item.tab == tab
        }) {
            return .quick
        } else if self.temporaryTabs.contains(where: { item in
            item.tab == tab
        }) {
            return .temporary
        }
        return .normal
    }
}

// MARK: - AnimatedTabBarControllerDelegate
extension LkTabbarController: AnimatedTabBarControllerDelegate {

    func tabbarController(_ tababrController: AnimatedTabBarController, shouldSelect newTab: Tab) -> Bool {
        return true
    }

    func tabbarController(_ tabbarController: AnimatedTabBarController, didTapped tab: Tab) {
        // 单、双击检测
        let time = Date().timeIntervalSince1970
        var vc = viewController(for: tab)
        vc = (vc?.tabRootViewController as? UIViewController) ?? vc

        if let page = vc as? PagePreservable {
            page.pageScene = self.getPageSceneBy(tab: tab)
        }

        if let naviFirst = (vc as? UINavigationController)?.viewControllers.first {
            vc = naviFirst
        } else if let splitFirst = (vc as? UISplitViewController)?.viewControllers.first {
            vc = (splitFirst as? UINavigationController)?.viewControllers.first ?? splitFirst
        } else if let lkSplit = vc?.larkSplitViewController?.sideNavigationController {
            vc = lkSplit.viewControllers.first ?? lkSplit
        }

        guard let tabVC = vc as? (UIViewController & TabRootViewController) else {
            // 到这边说明点击了自定义应用，用非切Tab（switch）方式打开，也需要埋点
            NavigationTracker.trackNavClickTab(tab, tabType: tabType(of: tab), style: tabbarStyle)
            return
        }

        let tapProtocol = tabVC as? TabbarItemTapProtocol
        if tab == lastTapTab, time - lastTaptime < 0.5 {
            if time - lastDoubleTapTime > 0.6 {
                NavigationTracker.didDoubleClickTab(tabVC.tab, tabType: tabType(of: tab))
                tapProtocol?.onTabbarItemDoubleTap()
                lastDoubleTapTime = time
            }
        } else {
            NavigationTracker.didClickTab(tabVC.tab, tabType: tabType(of: tab))
            tapProtocol?.onTabbarItemTap(lastTapTab == tab)
        }
        self.lastTaptime = time
        self.lastTapTab = tab
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func tabbarController(_ tabbarController: AnimatedTabBarController, didLongPress tab: Tab) {
        var vc = viewController(for: tab)
        vc = (vc?.tabRootViewController as? UIViewController) ?? vc
        if let naviFirst = (vc as? UINavigationController)?.viewControllers.first {
            vc = naviFirst
        } else if let splitFirst = (vc as? UISplitViewController)?.viewControllers.first {
            vc = (splitFirst as? UINavigationController)?.viewControllers.first ?? splitFirst
        } else if let lkSplit = vc?.larkSplitViewController?.sideNavigationController {
            vc = lkSplit.viewControllers.first ?? lkSplit
        }
        guard let tabVC = vc as? (UIViewController & TabRootViewController) else { return }
        let tapProtocol = tabVC as? TabbarItemTapProtocol
        tapProtocol?.onTabbarItemLongPress()
    }
    
    func tabbarController(_ tabbarController: AnimatedTabBarController, didSelect newTab: Tab, oldTab: Tab) {
        guard newTab != oldTab else { return } // 只有发生了tab切换才回post
        NavigationTracker.trackNavClickTab(newTab, tabType: tabType(of: newTab), style: tabbarStyle)
        LkTabbarController.logger.info("<NAVIGATION_BAR> didSwitchTab from: \(oldTab.description) to: \(newTab.description)")
    }

    func tabbarController(_ tabbarController: AnimatedTabBarController,
                          didEditForMain mainTabItems: [AbstractTabBarItem], quick quickTabItems: [AbstractTabBarItem],
                          success: (() -> Void)?, fail: (() -> Void)?) {
        // Call navigation service to report current tab order.
        modifyNavigationOrder(mainTabItems: mainTabItems,
                              quickTabItems: quickTabItems,
                              success: success,
                              fail: fail)
    }

    func tabbarController(_ tabbarController: AnimatedTabBarController,
                          didReorderForMain mainItems: [RankItem], quick quickItems: [RankItem],
                          success: (() -> Void)?, fail: (() -> Void)?) {
        // Call navigation service to report current tab order.
        modifyNavigationOrder(mainItems: mainItems,
                              quickItems: quickItems,
                              success: success,
                              fail: fail)
    }

    func tabbarController(_ tabbarController: AnimatedTabBarController, findItemIsInQuickLaunchView tab: TabCandidate) -> Observable<Bool> {
        return quickLaunchService?.findInQuickLaunchWindow(appId: tab.id, tabBizType: tab.bizType) ?? .just(false)
    }

    func tabbarController(_ tabbarController: AnimatedTabBarController,
                          didChangeEdgeMoreItems moreItems: [AbstractTabBarItem]) {
        let representables = moreItems.compactMap {
            TabRegistry.resolve($0.tab)
        }
        observeMoreBadge(for: .edge, moreTabs: representables)
    }

    func editTabBarEnabled() -> Bool {
        guard let navigationConfigService = self.navigationConfigService else { return false }
        return navigationConfigService.originalAllTabsinfo != nil
    }

    func computeRankItems() -> (main: [RankItem], quick: [RankItem]) {
        guard let navigationConfigService = self.navigationConfigService else { return ([], []) }
        guard let navigationInfo = navigationConfigService.originalAllTabsinfo else { return ([], []) }
        let appInfos: [Basic_V1_NavigationAppInfo]
        if !self.crmodeUnifiedDataDisable {
            if Display.pad {
                appInfos = navigationInfo.iPad.main + navigationInfo.iPad.quick
            } else {
                appInfos = navigationInfo.iPhone.main + navigationInfo.iPhone.quick
            }
        } else {
            appInfos = navigationInfo.bottom.main + navigationInfo.bottom.quick
        }
        /// get cache item， if tab has new tab's name & icon, then get the new data update to UI
        let naviResponse = navigationConfigService.getNavigationInfoByLocal()
        let crmodeDisable = self.crmodeUnifiedDataDisable
        let mainItems = mainTabBarItems.map { main -> RankItem in
            let info = appInfos.first(where: { $0.key == main.tab.key })
            let isCustomType = main.tab.isCustomType()
            let canDelete = info?.erasable ?? isCustomType
            /// have new navigation data
            let tempMain: [Basic_V1_NavigationAppInfo]?
            if !crmodeDisable {
                tempMain = Display.pad ? naviResponse?.iPad.main : naviResponse?.iPhone.main
            } else {
                tempMain = naviResponse?.bottom.main
            }
            if navigationConfigService.updateTabResourceEnable,
               let localMain = tempMain,
               let localTabInfo = localMain.first(where: { $0.key == main.tab.key }),
               let localTab = NavigationServiceImpl.parseNonNativeTab(by: localTabInfo, userResolver: self.userResolver) {
                let localTabItem = localTab.makeTabItem(userResolver: self.userResolver)
                LkTabbarController.logger.info("<NAVIGATION_BAR> new tab resource: rank item @ main: \(main.tab.key), \(String(describing: main.tab.appid))")
                return RankItem(tab: main.tab,
                                stateConfig: localTabItem.stateConfig,
                                name: isCustomType ? main.title : localTabItem.tab.tabName,
                                primaryOnly: info?.primaryOnly ?? false,
                                unmovable: info?.unmovable ?? false,
                                uniqueID: info?.uniqueID ?? main.tab.key,
                                canDelete: canDelete)
            }

            return RankItem(tab: main.tab,
                            stateConfig: main.stateConfig,
                            name: main.title,
                            primaryOnly: info?.primaryOnly ?? false,
                            unmovable: info?.unmovable ?? false,
                            uniqueID: info?.uniqueID ?? "",
                            canDelete: canDelete)
        }
        let quickItems = quickTabBarItems.map { quick -> RankItem in
            let info = appInfos.first(where: { $0.key == quick.tab.key })
            let isCustomType = quick.tab.isCustomType()
            let canDelete = info?.erasable ?? isCustomType
            /// have new navigation data
            let tempQuick: [Basic_V1_NavigationAppInfo]?
            if !crmodeDisable {
                tempQuick = Display.pad ? naviResponse?.iPad.quick : naviResponse?.iPhone.quick
            } else {
                tempQuick = naviResponse?.bottom.quick
            }
            if navigationConfigService.updateTabResourceEnable,
               let localQuick = tempQuick,
               let localTabInfo = localQuick.first(where: { $0.key == quick.tab.key }),
               let localTab = NavigationServiceImpl.parseNonNativeTab(by: localTabInfo, userResolver: self.userResolver) {
                let localTabItem = localTab.makeTabItem(userResolver: self.userResolver)
                LkTabbarController.logger.info("<NAVIGATION_BAR> new tab resource: rank item @ quick: \(quick.tab.key), \(quick.tab.appid)")
                return RankItem(tab: quick.tab,
                                stateConfig: localTabItem.stateConfig,
                                name: isCustomType ? quick.title : localTabItem.tab.tabName,
                                primaryOnly: info?.primaryOnly ?? false,
                                unmovable: info?.unmovable ?? false,
                                uniqueID: info?.uniqueID ?? "",
                                canDelete: canDelete)
            }
            return RankItem(tab: quick.tab,
                            stateConfig: quick.stateConfig,
                            name: quick.title,
                            primaryOnly: info?.primaryOnly ?? false,
                            unmovable: info?.unmovable ?? false,
                            uniqueID: info?.uniqueID ?? "",
                            canDelete: canDelete)
        }
        return (mainItems, quickItems)
    }
    
    func computeNaviEditItems() -> (main: [AbstractTabBarItem], quick: [AbstractTabBarItem]) {
        var mainItems = Array(mainTabBarItems)
        var quickItems = Array(quickTabBarItems)
        if !self.crmodeUnifiedDataDisable {
            let mainCount = mainTabBarItems.count
            if mainCount > self.iPadCModeMaxMainCount {
                // 底部主导航最多只能显示5个（不管是在iPhone还是iPad的C模式）
                mainItems = Array(mainTabBarItems.prefix(self.iPadCModeMaxMainCount))
                // 因为C模式下底部主导航最多只能显示5个，所以把截断的“拼到”快捷导航前面
                let mainSuffix = Array(mainTabBarItems[iPadCModeMaxMainCount..<mainCount])
                quickItems = mainSuffix + quickTabBarItems
            }
        }
        return (mainItems, quickItems)
    }

    // 把 “快捷导航” 的 item 重命名
    func tabbarController(_ tabbarController: AnimatedTabBarController, fromVC: UIViewController, shouldRename tabItem: AbstractTabBarItem, success: (() -> Void)?, fail: (() -> Void)?) {
        // 1. 统一跳转到重命名页面，修改名字
        let viewController = TabModifyViewController(userResolver: self.userResolver, tabItem: tabItem, from: .quick, style: self.tabbarStyle) { [weak self] (renamedItem) in
            guard let self = self else { return }
            let mainItems = Array(self.mainTabBarItems)
            // 修改符合条件的元素
            let quickItems = self.quickTabBarItems.enumerated().map { (_, item) -> AbstractTabBarItem in
                if item.tab == tabItem.tab {
                    let newItem = item
                    let displayName = renamedItem.tab.name ?? renamedItem.title
                    newItem.title = displayName
                    newItem.tab.name = displayName
                    newItem.tab.extra[RecentRecordExtraKey.displayName] = displayName
                    return newItem
                } else {
                    return item
                }
            }
            var appInfos: [Basic_V1_NavigationAppInfo] = []
            if let item = tabItem as? TabBarItem {
                appInfos.append(item.tranformToNavigationAppInfo())
            }
            // 2. 调SDK接口更新数据库中AppInfo的信息
            self.quickLaunchService?.updateNavigationInfos(appInfos: appInfos)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self, let hudOn = fromVC.view else { return }
                    let hud = UDToast.showLoading(with: BundleI18n.LarkNavigation.Lark_Legacy_BaseUiLoading, on: hudOn, disableUserInteraction: true)
                    // 3. 调SDK接口全量更新导航顺序
                    self.modifyNavigationOrder(mainTabItems: mainItems, quickTabItems: quickItems) {
                        hud.remove()
                        if let success = success {
                            success()
                        }
                    } fail: {
                        hud.remove()
                        if let fail = fail {
                            fail()
                        }
                    }

                })
                .disposed(by: self.disposeBag)
        }
        viewController.modalPresentationStyle = .formSheet
        fromVC.present(viewController, animated: true)
    }

    // 把 “快捷导航” 的 item 删除
    func tabbarController(_ tabbarController: AnimatedTabBarController, shouldDelete quickTab: Tab, success: (() -> Void)?, fail: (() -> Void)?) {
        let mainItems = Array(mainTabBarItems)
        let quickItems = quickTabBarItems.filter { item in
            return item.tab != quickTab
        }
        // Call navigation service to report current tab order.
        modifyNavigationOrder(mainTabItems: mainItems,
                              quickTabItems: quickItems,
                              success: success,
                              fail: fail)
    }
}

// MARK: - Guide
extension LkTabbarController {
    // show edit guide when new quick bar first show
    private func showEditAlert() {
        guard !editGuideShowed else { return }
        guard let y = quickTabBarContentViewMinY else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            guard let guideService = self.guideService else { return }
            guard !guideService.getGuideIsShowing() else { return }
            let offset = self.view.frame.height - y
            let vc = TabAlertViewController(title: BundleI18n.LarkNavigation.Lark_Legacy_BottomNavigationOnboardTitle,
                                            text: BundleI18n.LarkNavigation.Lark_Legacy_BottomNavigationOnboardContent,
                                            offset: offset,
                                            guideService: guideService,
                                            maskColor: .clear) { [weak self] in
                self?.editGuideShowed = true
            }
            Navigator.shared.present(vc, from: self)
        }
    }
}

// MARK: - Badge
extension LkTabbarController {
    private func observeSpringBoardBadge() {
        self.totalBadge
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (count) in
                self?.navigationDependency?.updateBadge(to: count)
            }).disposed(by: disposeBag)

        NotificationCenter.default.rx
            .notification(UIApplication.willResignActiveNotification)
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.navigationDependency?.updateBadge(to: self.totalBadge.value)
            }).disposed(by: disposeBag)
    }
}

// Mark - Tab Perf
extension LkTabbarController {
    private func observeSwitchTabPerf() {
        NotificationCenter.default
            .rx
            .notification(Notification.Name.ViewDidAppear)
            .subscribe(onNext: { [weak self] (notification) in
                guard let viewController = notification.object as? TabRootViewController else {
                    self?.willSelectedTabTime = nil
                    return
                }
                NewBootManager.shared.afterFirstRender()
                ColdStartup.shared?.category = viewController.tab.key
                ColdStartup.shared?.do(.firstRender)
                guard let self = self, let last = self.willSelectedTabTime else { return }
                self.switchTabPerf[viewController.tab.key]?.viewDidAppearCost = notification.cost
                self.reportSwitchTabPerfIfNeeded(viewController)

                // 之前逻辑，这个点只有初始化后上报
                if self.switchTabPerf[viewController.tab.key]?.initVCCost == 0 {
                    let cost = (CACurrentMediaTime() - last) * 1000
                    NavigationTracker.trackTabViewDidAppear(tab: viewController.tab, cost: cost)
                }

                self.willSelectedTabTime = nil
            }).disposed(by: disposeBag)

        NotificationCenter.default
            .rx
            .notification(Notification.Name.ViewDidLoad)
            .take(1)
            .subscribe(onNext: { [weak self] (notification) in
                guard let viewController = notification.object as? TabRootViewController else {
                    return
                }
                self?.switchTabPerf[viewController.tab.key]?.viewDidLoadCost = notification.cost
            }).disposed(by: disposeBag)
    }

    private func observeFirstScreenDataReady(_ current: TabRootViewController) {
        guard let firstScreenOb = current.firstScreenDataReady else { return }
        firstScreenOb
            .filter { $0 }
            .take(1)
            .subscribe(onNext: { [weak self] _ in
            guard let self = self, let last = self.lastVCInitTime else { return }
            let cost = (CACurrentMediaTime() - last) * 1000
            self.lastVCInitTime = nil
            self.switchTabPerf[current.tab.key]?.firstScreenDataReadyCost = cost
            self.reportSwitchTabPerfIfNeeded(current)
        }).disposed(by: disposeBag)
    }

    private func reportSwitchTabPerfIfNeeded(_ current: TabRootViewController) {
        guard
            let params = self.switchTabPerf[current.tab.key],
            let tab = self.currentTab,
            current.tab == tab
            else { return }

        // 初始化
        if params.initVCCost > 0 {
            // 业务提供了First Screen Ready
            if current.firstScreenDataReady != nil {
                // 等业务方返回
                if params.firstScreenDataReadyCost > 0
                    && params.viewDidAppearCost > 0 { self.report(current.tab.key) }
            } else {
                // 没提供First Screen Ready
                self.report(current.tab.key)
            }
        } else {
            // 不是初始化，直接切Tab，上报DidAppear耗时
            self.report(current.tab.key)
        }
    }

    private func report(_ key: String) {
        guard let params = self.switchTabPerf[key] else { return }
        CoreEventMonitor.SwithTabCost.end(params: params)
        //上报可感知埋点
        SwitchTabTracker.shared.end(disposeKey: params.disposeKey)
        self.switchTabPerf[key] = SwitchTabMonitor.Params()
    }
}

// MARK: - Reordering

/// 修改排序
extension LkTabbarController {

    func modifyNavigationOrder(mainTabItems: [AbstractTabBarItem],
                               quickTabItems: [AbstractTabBarItem],
                               success: (() -> Void)?,
                               fail: (() -> Void)?) {
        if !self.crmodeUnifiedDataDisable {
            // 需要记录下修改顺序之前iPad设备R模式下主导航的个数
            let iPadRModeMainCount = self.navigationService?.allTabs.iPad.main.count ?? 0
            // iPhone设备的数据直接用传参
            var modifiedMainTabItems = mainTabItems
            var modifiedQuickTabItems = quickTabItems
            if Display.pad {
                // iPad设备C模式的话还要转化一下，哎，这产品逻辑也是醉
                if self.tabbarStyle == .bottom {
                    // 根据传参计算出C模式所有的数据以及个数
                    let iPadCModeAllTabItems = mainTabItems + quickTabItems
                    let iPadCModeAllCount = iPadCModeAllTabItems.count
                    // C模式主导航的个数要和R模式一样，所以取传入总数据的前n个（n是R模式下主导航的个数，这个逻辑绕成狗子了>_<）
                    modifiedMainTabItems = Array(iPadCModeAllTabItems.prefix(iPadRModeMainCount))
                    if iPadRModeMainCount < iPadCModeAllCount {
                        // 截取剩下的部分
                        modifiedQuickTabItems = Array(iPadCModeAllTabItems[iPadRModeMainCount..<iPadCModeAllCount])
                    }
                }
            }
            Self.logger.info("<NAVIGATION_BAR> User pressed modify button: isIPad = \(Display.pad), tabBarStyle = \(self.tabbarStyle), iPadRModeMainCount = \(iPadRModeMainCount), modifiedMainTabItems: \(modifiedMainTabItems), modifiedQuickTabItems: \(modifiedQuickTabItems)")
            // Call navigation service to modify current tab order.
            (navigationService as? NavigationServiceImpl)?
                .modifyNavigationOrder(mainTabItems: modifiedMainTabItems, quickTabItems: modifiedQuickTabItems)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { _ in
                    success?()
                }, onError: { _ in
                    fail?()
                })
                .disposed(by: disposeBag)
            updateItemsWhenModifyOrder(mainTabItems: modifiedMainTabItems, quickTabItems: modifiedQuickTabItems)
        } else {
            // Call navigation service to modify current tab order.
            (navigationService as? NavigationServiceImpl)?
                .modifyNavigationOrder(mainTabItems: mainTabItems, quickTabItems: quickTabItems)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { _ in
                    success?()
                }, onError: { _ in
                    fail?()
                })
                .disposed(by: disposeBag)
            updateItemsWhenModifyOrder(mainTabItems: mainTabItems, quickTabItems: quickTabItems)
        }
    }

    func modifyNavigationOrder(mainItems: [AbstractRankItem],
                               quickItems: [AbstractRankItem],
                               success: (() -> Void)?,
                               fail: (() -> Void)?) {
        // Call navigation service to report current tab order.
        (navigationService as? NavigationServiceImpl)?
            .modifyNavigationOrder(main: mainItems, quick: quickItems)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                success?()
            })
            .disposed(by: disposeBag)
        updateItemsWhenModifyOrder(mainItems: mainItems, quickItems: quickItems)
    }

    private func updateItemsWhenModifyOrder(mainTabItems: [AbstractTabBarItem],
                                            quickTabItems: [AbstractTabBarItem]) {
        let mainTabs = mainTabItems.map { $0.tab }
        let quickTabs = quickTabItems.map { $0.tab }

        if !self.crmodeUnifiedDataDisable {
            self.updateItemsOrder(mainTabs: mainTabs, quickTabs: quickTabs)
        } else {
            self.updateItemsOrderOfStyle(mainTabs: mainTabs, quickTabs: quickTabs)
        }
        // 重新设置高亮状态
        self.isReordering = true
        if isInBottomMainBar(selectedTab) {
            self.bottomMoreItem?.deselectedState()
        } else {
            self.bottomMoreItem?.selectedState()
        }
        self.isReordering = false
    }

    private func updateItemsWhenModifyOrder(mainItems: [AbstractRankItem],
                                    quickItems: [AbstractRankItem]) {
        let mainTabs = mainItems.map { $0.tab }
        let quickTabs = quickItems.map { $0.tab }

        if !self.crmodeUnifiedDataDisable {
            self.updateItemsOrder(mainTabs: mainTabs, quickTabs: quickTabs)
        } else {
            self.updateItemsOrderOfStyle(mainTabs: mainTabs, quickTabs: quickTabs)
        }
        // 重新设置高亮状态
        self.isReordering = true
        if isInBottomMainBar(selectedTab) {
            self.bottomMoreItem?.deselectedState()
        } else {
            self.bottomMoreItem?.selectedState()
        }
        self.isReordering = false
    }
}
