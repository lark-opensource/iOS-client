//
//  AnimatedTabBarController.swift
//  AnimatedTabBar
//
//  Created by liuwanlin on 2018/9/21.
//

import Foundation
import UIKit
import SnapKit
import LarkKeyboardKit
import RxSwift
import LKCommonsLogging
import LarkContainer
import LarkUIKit
import LarkBadge
import LarkTraitCollection
import LarkTab
import UniverseDesignToast
import UniverseDesignIcon
import UniverseDesignColor
import Homeric
import LKCommonsTracker
import LarkFeatureGating
import LarkStorage
import LKWindowManager
import LarkQuickLaunchInterface
import EENavigator
import ThreadSafeDataStructure
import LarkSceneManager
import LarkSetting
import LarkDocsIcon
import ByteWebImage
import RustPB
import RunloopTools
// swiftlint:disable file_length

public protocol AnimatedTabBarControllerDelegate: AnyObject {
    func tabbarController(_ tababrController: AnimatedTabBarController, shouldSelect newTab: Tab) -> Bool
    func tabbarController(_ tabbarController: AnimatedTabBarController, didTapped tab: Tab)
    func tabbarController(_ tabbarController: AnimatedTabBarController, didLongPress tab: Tab)
    func tabbarController(_ tabbarController: AnimatedTabBarController, didSelect newTab: Tab, oldTab: Tab)
    // 通知代理修改导航顺序
    func tabbarController(_ tabbarController: AnimatedTabBarController,
                          didEditForMain mainTabItems: [AbstractTabBarItem], quick quickTabItems: [AbstractTabBarItem],
                          success: (() -> Void)?, fail: (() -> Void)?)
    /// Inform delegate to handle tab reordering event.
    func tabbarController(_ tabbarController: AnimatedTabBarController,
                          didReorderForMain mainItems: [RankItem], quick quickItems: [RankItem],
                          success: (() -> Void)?, fail: (() -> Void)?)
    /// 查询是否已经在「常用列表」
    func tabbarController(_ tabbarController: AnimatedTabBarController, findItemIsInQuickLaunchView tab: TabCandidate) -> Observable<Bool>
    func tabbarController(_ tabbarController: AnimatedTabBarController,
                          didChangeEdgeMoreItems moreItems: [AbstractTabBarItem])
    // 当本地没有navigationInfo缓存时，禁用tab编辑功能
    func editTabBarEnabled() -> Bool
    func computeRankItems() -> (main: [RankItem], quick: [RankItem])
    func computeNaviEditItems() -> (main: [AbstractTabBarItem], quick: [AbstractTabBarItem])
    // 把 “快捷导航” 的 item 重命名
    func tabbarController(_ tabbarController: AnimatedTabBarController, fromVC: UIViewController, shouldRename tabItem: AbstractTabBarItem, success: (() -> Void)?, fail: (() -> Void)?)
    // 把 “快捷导航” 的 item 删除
    func tabbarController(_ tabbarController: AnimatedTabBarController, shouldDelete quickTab: Tab, success: (() -> Void)?, fail: (() -> Void)?)
}

extension AnimatedTabBarControllerDelegate {
    func tabbarController(_ tababrController: AnimatedTabBarController, shouldSelect newTab: Tab) -> Bool {
        return true
    }
    func tabbarController(_ tabbarController: AnimatedTabBarController, didTapped tab: Tab) { }
    func tabbarController(_ tabbarController: AnimatedTabBarController, didSelect newTab: Tab, oldTab: Tab) {}
    func tabbarController(_ tabbarController: AnimatedTabBarController, didLongPress tab: Tab) {}
}

public protocol AnimatedTabBarDependancy: AnyObject {
    func getTabRootViewController(from controller: UIViewController) -> TabRootViewController?
}

/// Tab 样式
public enum TabbarStyle {
    case edge   /// 左侧 Tab
    case bottom /// 底部 Tab

    public var description: String {
        switch self {
        case .edge:
            return "edge"
        case .bottom:
            return "bottom"
        }
    }
}

open class AnimatedTabBarController: UITabBarController, UserResolverWrapper {

    public let userResolver: UserResolver

    public var disposeBag = DisposeBag()

    public static var styleChangeNotification = Notification.Name("AnimatedTabBarController.tabbarStyleDidChange")

    @ScopedInjectedLazy var fgService: FeatureGatingService?

    // MARK: Feature Gating
    /// FG
    public var isEditNaivDisable: Bool = {
        let editPageDisableFG = FeatureGatingManager.shared.featureGatingValue(with: "lark.navigation.disable.new.editpage")
        return editPageDisableFG == true
    }()

    /// FG：CRMode数据统一
    public lazy var crmodeUnifiedDataDisable: Bool = {
        return fgService?.staticFeatureGatingValue(with: "lark.navigation.disable.crmode") ?? false
    }()

    /// QuickLauncher 功能是否打开
    /// - NOTE: 由于 AnimatedTabBar 没有依赖 LarkSetting，所以 FG 需要在 LarkNavigation 中设置
    public var isQuickLauncherEnabled: Bool

    public private(set) var tabbarStyle: TabbarStyle = .bottom {
        didSet {
            if oldValue != tabbarStyle {
                // background 状态不修改 edgeTabbar show 状态
                let inBackground: Bool = { () -> Bool in
                    if #available(iOS 13, *),
                       let windowScene = self.view.window?.windowScene {
                        return windowScene.activationState == .background
                    } else {
                        return UIApplication.shared.applicationState == .background
                    }
                }()
                if !inBackground {
                    // tabbar style 变化重置 edge 属性
                    self.showEdgeTabbar = true
                    NotificationCenter.default.post(name: AnimatedTabBarController.styleChangeNotification, object: nil)
                }
                self.tabbarStyleDidChange()
            }
        }
    }

    private var lastBoundsSize: CGSize = .zero

    public let iPadCModeMaxMainCount: Int = 5

    static let logger = Logger.log(AnimatedTabBarController.self, category: "Module.TabBar")

    public var tabbarHeight: CGFloat {
        switch tabbarStyle {
        case .edge:
            return 0
        case .bottom:
            // 若访问时机过早，view.safeAreaInsets.bottom取到可能为0
            return mainTabBar.intrinsicHeight +
            (UIApplication.shared.delegate?.window??.safeAreaInsets.bottom ?? view.safeAreaInsets.bottom)
        }
    }

    public var tabbarIntrinsicHeight: CGFloat {
        return mainTabBar.intrinsicHeight
    }

    /// 获取 Tab 所对应的 ViewController。最终由子类 `LkTabBarController` 自己实现
    public weak var dependancy: AnimatedTabBarDependancy?

    /// 回调 TabBarVC 的点击、编辑事件，获取配置信息。最终由子类 `LkTabBarController` 自己实现
    public weak var animatedTabBarDelegate: AnimatedTabBarControllerDelegate?

    /// iPad 上侧侧边 TabBar，由上层注入。最终由子类 `MainTabbarController`
    public private(set) var edgeTab: EdgeTabBarProtocol?

    /// 拖拽手势开始拖拽的位置，用于处理拖拽偏移误差
    private var panEdgeTabStartLocationX: CGFloat = 0

    /// iPad 全屏是否默认展示 edgeBar
    public static var globalShowEdgeTabbar: Bool = globalStore[globalShowEdgeTabbarKey] {
        didSet {
            if oldValue != globalShowEdgeTabbar {
                globalStore[globalShowEdgeTabbarKey] = globalShowEdgeTabbar
            }
        }
    }
    private static let globalStore = KVStores.udkv(
        space: .global,
        domain: Domain.biz.core.child("AnimatedTabBar")
    )

    public static var globalEdgeTabbarStyle: Bool {
        set {
            if Utility.getCurrentInterfaceOrientation()?.isLandscape ?? false {
                globalStore[globalLandscapeEdgeTabbarStyleKey] = newValue
            } else {
                globalStore[globalPortraitEdgeTabbarStyleKey] = newValue
            }
        }
        get {
            if Utility.getCurrentInterfaceOrientation()?.isLandscape ?? false {
                return globalStore[globalLandscapeEdgeTabbarStyleKey]
            } else {
                return globalStore[globalPortraitEdgeTabbarStyleKey]
            }
        }
    }

    private static var globalShowEdgeTabbarKey = KVKey("showEdgeTabbar", default: true)
    private static var globalPortraitEdgeTabbarStyleKey = KVKey("PortraitEdgeTabbarStyle", default: true)
    private static var globalLandscapeEdgeTabbarStyleKey = KVKey("LandscapeEdgeTabbarStyle", default: max(UIScreen.main.bounds.width, UIScreen.main.bounds.width) < EdgeTabBarLayoutStyle.maxViewWidth)

    /// 当前是否显示 edgeBar
    public private(set) var showEdgeTabbar: Bool = true

    private var viewWillTransitionItem: DispatchWorkItem?
    private var traitCollectionDidChangeItem: DispatchWorkItem?

    private var backgroundFG: Bool {
        return self.userResolver.fg.dynamicFeatureGatingValue(with: "ios.tabbar.optimize_multi_called_uirefresh")
    }

    private var traitCollectionDidChangeFG: Bool {
        return self.userResolver.fg.dynamicFeatureGatingValue(with: "ios.tabbar.optimize_background_ui_refresh")
    }

    private var enableSearchiPadRedesignFG: Bool {
        let enableSearchiPadRedesignFeatureGating = self.userResolver.fg.staticFeatureGatingValue(with: "lark.search.ipad.redesign")
        Self.logger.info("enableSearchiPadRedesignFG, fg is: \(enableSearchiPadRedesignFeatureGating), isPad is \(Display.pad)")
        return enableSearchiPadRedesignFeatureGating && Display.pad
    }

    private var logFG: Bool {
        return self.userResolver.fg.dynamicFeatureGatingValue(with: "ios.tabbar.ui_log")
    }

    /// 支持临时区打开知识库空间页面
    private var temporaryOpenWikiFG: Bool {
        return self.userResolver.fg.dynamicFeatureGatingValue(with: "ipad.navigation.tabs.wiki_space")
    }

    private var inBackground: Bool {
        if #available(iOS 13, *),
           let windowScene = self.view.window?.windowScene {
            return windowScene.activationState == .background
        } else {
            return UIApplication.shared.applicationState == .background
        }
    }

    /// 拖动过程中 edgeTabar 布局偏移
    private var edgeTabbarOffset: CGFloat?

    private var edgePanGesture: UIPanGestureRecognizer = {
        let ges = UIPanGestureRecognizer()
        if #available(iOS 13.4, *) {
            ges.allowedScrollTypesMask = [.continuous]
        }
        return ges
    }()

    private func updateEdgeTabbar(show: Bool, animation: Bool) {
        self.showEdgeTabbar = show

        guard self.tabbarStyle == .edge else {
            return
        }

        if animation {
            UIView.animate(withDuration: 0.2) {
                self.layoutTabbarForIpad()
            } completion: { (_) in }
        } else {
            self.layoutTabbarForIpad()
        }
    }

    /// 设置当前 edgeTabbar 显示状态
    @discardableResult
    public func setEdgeTabbar(show: Bool, from vc: UIViewController, animation: Bool) -> Bool {
        var rootVC: UIViewController? = vc
        while (rootVC != nil) {
            if self.temporaryTabContainer.tabContainable?.tabContainableIdentifier == selectedTab.key {
                break
            } else if rootVC == self.viewController(for: selectedTab) {
                break
            }
            rootVC = rootVC?.parent
        }
        guard rootVC != nil else {
            return false
        }

        updateEdgeTabbar(show: show, animation: animation)
        return true
    }

    /// 添加更新 edgeTab 手势
    /// 被更高层模块 `LarkSplitViewController` 依赖并调用，通知 TabBar 更新
    /// - Parameter pan: 拖动手势，来自其他模块传入
    public func updateEdgeTabGesture(pan: UIPanGestureRecognizer) {
        pan.addTarget(self, action: #selector(handleEdgeTabbarPan(pan:)))
    }

    @objc
    private func handleEdgeTabbarPan(pan: UIPanGestureRecognizer) {
        guard self.tabbarStyle == .edge, let edgeTab = self.edgeTab else {
            return
        }
        let location = pan.location(in: self.view)
        let velocity = pan.velocity(in: self.view)
        switch pan.state {
        case .began:
            break
        case .changed:
            /// 拖动过程中设置拖拽偏移
            /// 修改偏移是为了避免拖动中宽度与最终宽度一致导致系统 viewWillTransation 不回调
            self.edgeTabbarOffset = min(0, max(-edgeTab.tabbarWidth, location.x-edgeTab.tabbarWidth))
            if self.edgeTabbarOffset == 0,
               self.showEdgeTabbar == false {
                self.edgeTabbarOffset = -0.5
            } else if self.edgeTabbarOffset == -edgeTab.tabbarWidth,
                      self.showEdgeTabbar == true {
                self.edgeTabbarOffset = -edgeTab.tabbarWidth + 0.5
            }
            self.layoutTabbarForIpad()
        case .cancelled, .ended, .failed:
            /// 手势结束 重置偏移
            self.edgeTabbarOffset = nil
            /// 判断是否需要显示 edgeBar
            var showEdgeBar = (location.x > edgeTab.tabbarWidth) ||
            (location.x + (velocity.x / 10) > (edgeTab.tabbarWidth / 3 * 2))

            /// 判断是快速划出
            let isSwipeShowEdgeTabbar = velocity.x > 1000
            let isSwipeHideEdgeTabbar = velocity.x < -1500

            /// 根据全局属性更正是否显示
            if !AnimatedTabBarController.globalShowEdgeTabbar,
               (location.x + (velocity.x / 10)) < (edgeTab.tabbarWidth / 3 * 2) ||
                isSwipeHideEdgeTabbar {
                showEdgeBar = false
            }

            /// 更新全局属性
            if (!self.showEdgeTabbar && showEdgeBar && !isSwipeShowEdgeTabbar) ||
                !showEdgeBar {
                AnimatedTabBarController.globalShowEdgeTabbar = showEdgeBar
            }
            /// 更新 edgeTabbar 显示
            self.updateEdgeTabbar(show: showEdgeBar, animation: false)
        default:
            break
        }
    }


    /// EdgeTabBar 是业务层模块 `LarkNavigation` 注入的，不是 `AnimatedTabBar` 内部实现的
    /// - Parameter provider: 创建 `EdgeTabBar` 实例的闭包
    /// - Note: 和 `MainTabBar` 不同，`MainTabBar` 由 `AnimateTabBar` 维护
    public func registerEdgeTab(provider: () -> EdgeTabBarProtocol) {
        if UIDevice.current.userInterfaceIdiom != .pad {
            return
        }
        let edgeTab = provider()
        edgeTab.delegate = self
        if !self.crmodeUnifiedDataDisable {
            edgeTab.mainTabItems = allTabBarItems.iPad.main
            edgeTab.hiddenTabItems = allTabBarItems.iPad.quick
        } else {
            edgeTab.mainTabItems = allTabBarItems.edge.main
            edgeTab.hiddenTabItems = allTabBarItems.edge.quick
        }
        edgeTab.temporaryTabItems = self.temporaryTabs
        self.edgeTab = edgeTab
        edgeTab.moreItem = edgeMoreItem
        self.updateTabbarStyleIfNeeded()
    }

    public var moreTabEnabled: Bool = true
    // main navi
    lazy var mainTabBar = {
        return MainTabBar(moreTabEnabled: moreTabEnabled, translucent: tabBarConfig.translucent, userResolver: userResolver)
    }()

    // swiftlint:disable todo
    // for ipad TODO: Meng
    // swiftlint:enable todo
    public var customTabBar: UITabBar? {
        return mainTabBar
    }

    /// iPad 上 TabBar 的容器 View
    private var _tabbarCanvas: TabbarCanvas = TabbarCanvas()

    private var tabbarCanvas: UIView {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return _tabbarCanvas
        }
        return self.view
    }

    // MARK: 读items接口
    public let allTabBarItems = AllTabBarItems()

    public var mainTabBarItems: [AbstractTabBarItem] {
        if !self.crmodeUnifiedDataDisable {
            if Display.pad {
                return self.allTabBarItems.iPad.main
            } else {
                return self.allTabBarItems.iPhone.main
            }
        } else {
            switch tabbarStyle {
            case .edge:
                return self.allTabBarItems.edge.main
            case .bottom:
                return self.allTabBarItems.bottom.main
            }
        }
    }

    public var quickTabBarItems: [AbstractTabBarItem] {
        if !self.crmodeUnifiedDataDisable {
            if Display.pad {
                return self.allTabBarItems.iPad.quick
            } else {
                return self.allTabBarItems.iPhone.quick
            }
        } else {
            switch tabbarStyle {
            case .edge:
                return self.allTabBarItems.edge.quick
            case .bottom:
                return self.allTabBarItems.bottom.quick
            }
        }
    }

    public var bottomMoreItem: AbstractTabBarItem? {
        didSet {
            guard let item = bottomMoreItem else { return }
            mainTabBar.moreItem = item
        }
    }

    public var edgeMoreItem: AbstractTabBarItem? {
        didSet { edgeTab?.moreItem = edgeMoreItem }
    }

    /// 存储 Tab -> TabBarItem 的映射关系，应该只有一套 TabBarItem
    private var tabBarItems = [Tab: AbstractTabBarItem]()

    /// Get view controller for specified tab from current container, if not exist, return nil.
    /// - Parameter tab: Tab data structure.
    /// ??? 如果 VC 被回收，此处将返回 nil？
    public func viewController(for tab: Tab?) -> UIViewController? {
        return self.viewControllers?.first { [weak self] in
            self?.dependancy?.getTabRootViewController(from: $0)?.tab == tab
        }
    }

    // 已经被加载的Tab
    public var currentLoadedTabs: [Tab] {
        guard let vcs = viewControllers else { return [] }
        return vcs.compactMap { [weak self] in
            self?.dependancy?.getTabRootViewController(from: $0)?.tab
        }
    }

    // quick navi
    public var quickTabInitTask: (() -> Void)?
    public var tabBarConfig: TabBarConfig
    var isQuickTabBarShown: Bool {
        return quickTabBar != nil
    }
    public weak var quickTabBar: QuickTabBarInterface?

    public var quickLaunchWindow: QuickLaunchWindow?

    weak var quickTabBarContentView: QuickTabBarContentViewInterface?
    public var quickTabBarContentViewMinY: CGFloat? {
        return quickTabBarContentView?.frame.minY
    }

    private func allowTemporaryOpen(for tab: Tab) -> Bool {
        //admin后台用户配置的网页应用类型 webapp，PM说需要支持，暂时通过临时区容器打开支持
        guard temporaryOpenWikiFG else {
            return false
        }
        guard let _ = viewController(for: tab) else {
            if tab.appType == .webapp {
                return true
            }
            return false
        }
        return false
    }

    // 判断是否需要在临时区打开
    private func needOpenInTemporary(by tab: Tab) -> Bool {
        if tab.isCustomType() || allowTemporaryOpen(for: tab) {
            return true
        }
        return false
    }

    // setviewController调用时会调用selectedIndex, 因此分开控制
    private var safeSetSelectedIndex: Bool = false
    private var safeSetViewControllers: Bool = false

    /// observe hardware keyboard enable
    /// if true, tabbar will move when hardware keyboard bar appear
    private var hardwareKeyboardObserveEnable: Bool = false
    private var keyboardDisposeBag: DisposeBag = DisposeBag()

    /// 用于标记底部 Tabbar 最后应该出现的 VC 位置
    private weak var lastTabbarShowVC: UIViewController?

    /// selectedIndex managed by `AnimatedTabBarController`, do not call directly.
    /// - Note: Use `selectedTab` instead of `selectedIndex`
    open override var selectedIndex: Int {
        willSet {
            /// iPad 转屏会自动调用该方法，判断这种case 避免错误 assert
            if UIDevice.current.userInterfaceIdiom == .pad {
                return
            }
            assert(safeSetSelectedIndex, "selectedIndex managed by AnimatedTabBarController, do not call directly")
        }
    }

    /// Tab index might be changed after reordered, so the selected index should be reasign after reordering,
    /// use this flag to prevent select and deselect actions which are not necessary.
    public var isReordering: Bool = false

    /// Current selected tabType, set this value will change selectedIndex(selectedViewController) immediately.
    /// setter will not check delegate `tabbarController(_:shouldSelect:)`, and change select directly.
    public var selectedTab: Tab = Tab(url: "", appType: .native, key: "") {
        willSet {
            guard selectedTab != newValue else { return }
            if !isReordering {
                /// 切换 tab 时默认展开 edgeTabbar
                if self.tabbarStyle == .edge && !self.showEdgeTabbar {
                    self.updateEdgeTabbar(show: true, animation: false)
                    AnimatedTabBarController.globalShowEdgeTabbar = true
                }
                willSelectTab(newValue, oldTab: selectedTab)
            }
        }
        didSet {
            if !isReordering {
                setSelect(from: oldValue, to: selectedTab)
                guard oldValue.key != selectedTab.key else { return }
                unsafeTabKeyCache.use(selectedTab.key)
            }
        }
    }

    /// 记录最近打开页面
    public var unsafeTabKeyCache = UnsafeLRUStack<String>(maxSize: 100)

    public var selectedTabItem: AbstractTabBarItem? {
        return getTabBarItem(for: selectedTab)
    }

    /// 当前正在显示的Tab
    public var currentTab: Tab? {
        return self.currentLoadedTabs.first
    }

    @InjectedUnsafeLazy public var temporaryTabService: TemporaryTabService

    public var temporaryTabs: [AbstractTabBarItem] = []
    private var docDefaultIconCache: SafeDictionary<String, UIImage>? = [:] + .readWriteLock
    private var docSelectIconCache: SafeDictionary<String, UIImage>? = [:] + .readWriteLock
    private var docQuickIconCache: SafeDictionary<String, UIImage>? = [:] + .readWriteLock

    public var closeTemporaryTab = UnsafeLRUStack<String>(maxSize: 100)

    lazy public var temporaryTabContainer: TemporaryTabContainer = {
        let temporaryTabContainer = TemporaryTabContainer()
        temporaryTabContainer.isLkShowTabBar = false
        return temporaryTabContainer
    }()

    private var updateEdge = false

    public init(tabBarConfig: TabBarConfig, isQuickLauncherEnabled: Bool = false, userResolver: UserResolver) {
        self.userResolver = userResolver
        self.isQuickLauncherEnabled = isQuickLauncherEnabled
        self.tabBarConfig = tabBarConfig
        if UIDevice.current.userInterfaceIdiom == .pad {
            // iPad 上关闭毛玻璃效果
            self.tabBarConfig.translucent = false
        }
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    open override func setViewControllers(_ viewControllers: [UIViewController]?, animated: Bool) {
        // swiftlint:disable line_length
        assert(safeSetViewControllers, "setViewControllers(_:animated:) managed by AnimatedTabBarController, do not call directly")
        // swiftlint:enable line_length
        defer { safeSetSelectedIndex = false }
        safeSetSelectedIndex = true
        super.setViewControllers(viewControllers, animated: animated)
        if mainTabBar != self.tabBar {
            // iPhone用mainTabBar替换了origin tabBar
            // 直接对self.tabBar调用setItems会引起Crash:
            // 'Directly modifying a tab bar managed by a tab bar controller is not allowed.'
            mainTabBar.items = tabBar.items
        }
    }

    // MARK: life circle
    open override func viewDidLoad() {
        super.viewDidLoad()

        if logFG {
            UIView.initializeOnceForView()
        }

        initTababrCanvas()
        initializeMainTab()
        initializeMoreItems()
        initTemporaryTabs()
        initEdgePanGesture()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc
    private func didBecomeActive() {
        setNeedsStatusBarAppearanceUpdate()
    }

    private var firstAppeared: Bool = false
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        /// 第一次出现时刷新 style 样式
        if !firstAppeared {
            firstAppeared = true
            lastTabbarShowVC = self
            self.updateTabbarStyleIfNeeded()
            self.setupAllSubVCTraitCollection()
        }
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.view.bringSubviewToFront(_tabbarCanvas)
        }
    }

    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // 当VC设置了hidesBottomBarWhenPushed属性，pop时会自动显示tabBar，需要在此处重新隐藏
        if UIDevice.current.userInterfaceIdiom == .pad {
            tabBar.isHidden = true
        }
    }

    @available(iOS 11.0, *)
    open override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        layoutTabbarForIpad()
        view.layoutIfNeeded() // layout for tabbar height first size without safeArea
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        /// iOS 14 Tababr autolayout 约束失效，需要使用 frame 刷新布局
        if updateEdge {
            self.updateEdgePanFrame(width: self.edgeTab?.frame.width ?? 0)
        } else {
            self.layoutTabbarForIpad()
        }

        if !self.lastBoundsSize.equalTo(self.view.bounds.size) {
            /// 正常应该 viewWillTransition、traitCollectionDidChange做处理，但是这俩时机self.view.bounds可能还不是准确的
            /// 导致customTraitCollection不准确，这里先做个trict方式先修复下
            self.updateTabbarStyleIfNeeded()
            self.setupAllSubVCTraitCollection()
        }
        self.lastBoundsSize = self.view.bounds.size
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let newTraitCollection = updateTabbarStyleIfNeeded(size: size)

        Self.logger.info("viewWillTransition, isCompact: \(newTraitCollection.horizontalSizeClass == .compact)")
        /// 修正子视图 traitCollection
        self.children.forEach { (controller) in
            Self.logger.info("Child VC: \(controller), setOverrideTraitCollection")
            self.setOverrideTraitCollection(newTraitCollection, forChild: controller)
        }

        super.viewWillTransition(to: size, with: coordinator)

        self.traverseExceededVC { (vc) in
            self.setOverrideTraitCollection(newTraitCollection, forChild: vc)
            let subSize = self.size(forChildContentContainer: vc, withParentContainerSize: size)
            vc.viewWillTransition(to: subSize, with: coordinator)
        }
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.setupAllSubVCTraitCollection()

        Self.logger.info("TraitCollection Did Change")

        if inBackground, backgroundFG, Display.pad {
            return
        }

        self.updateTabbarStyleIfNeeded()
        var tabbarLayoutStyle: EdgeTabBarLayoutStyle = AnimatedTabBarController.globalEdgeTabbarStyle ? .vertical : .horizontal
        if self.view.frame.width < EdgeTabBarLayoutStyle.maxViewWidth {
            tabbarLayoutStyle = .vertical
        }
        self.edgeTab?.tabbarLayoutStyle = tabbarLayoutStyle
        self.layoutTabbarForIpad()
        // UI特性发生变化的时候（这时会根据屏幕情况决定使用底部栏还是侧边栏）需要调用
        self.reassignCustomViews()
    }

    open override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return [.left]
    }

    open func tabbarStyleDidChange() {
        reassignCustomViews()
        reassignSelectedItems()
    }

    open func removeTabKey(_ key: String) {
    }

    /// 如果 Tab 使用了 customView（如日历 Tab），需要将 customView 在 MainTabBar 和 EdgeTabBar 之间移动
    private func reassignCustomViews() {
        /// 根据 TabBarStyle 更新 Tab custom icon
        switch tabbarStyle {
        case .edge:
            self.edgeTab?.refreshTabbarCustomView()
        case .bottom:
            self.mainTabBar.refreshTabbarCustomView()
        }
    }

    /// rc变换时数据变更，可能会导致返回之前视图出现多个选中
    private func reassignSelectedItems() {
        self.mainTabBarItems.forEach {
            if $0.tab == selectedTab {
                $0.selectedState()
            } else if $0.isSelected {
                $0.deselectedState()
            }
        }
    }

    // 这个值为了保证willTransition（to newTraitCollection)从开始到结束的过程中，traitCollection都用新的
    private var targetTrainCollection: UITraitCollection?

    open override func willTransition(
        to newCollection: UITraitCollection,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        targetTrainCollection = newCollection
        super.willTransition(to: newCollection, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] (_) in
            self?.targetTrainCollection = nil
        }
        // R 视图自动 Dismiss QuickLaunchWindow，并且要恢复底部 TabBar 的选中状态
        if newCollection.horizontalSizeClass == .regular {
            dismissQuickLaunchWindow(animated: false) {
                self.updateMainTabBarSelectionState(isQuickTabOpened: true)
            }
        }
    }

    open override func size(
        forChildContentContainer container: UIContentContainer,
        withParentContainerSize parentSize: CGSize
    ) -> CGSize {
        if self.tabbarStyle == .bottom {
            var tabbarHeight = self.tabbarIntrinsicHeight
            tabbarHeight += view.safeAreaInsets.bottom
            return CGSize(width: parentSize.width, height: parentSize.height - tabbarHeight)
        } else {
            if self.showEdgeTabbar {
                return CGSize(width: parentSize.width - (edgeTab?.tabbarWidth ?? 0), height: parentSize.height)
            } else {
                return CGSize(width: parentSize.width, height: parentSize.height)
            }
        }
        return super.size(forChildContentContainer: container, withParentContainerSize: parentSize)
    }

    open func setTabViewController(_ viewController: UIViewController) {
        var children = self.viewControllers ?? []
        if !children.contains(viewController) {
            children.append(viewController)
        }
        // UITabBarController index大于4会中系统assert，始终选中index 0，并交换VC位置
        children.swapAt(0, children.firstIndex(of: viewController)!)
        safeSetViewControllers(children, animated: false)
        // 初始化 subVC traitCollection
        setupAllSubVCTraitCollection()
    }

    open func didSet(bottomMain tabOrder: [Tab]) {}

    open func didSet(edgeMain tabOrder: [Tab]) {}

    open func didSet(bottomQuick tabOrder: [Tab]) {}

    open func didSet(edgeQuick tabOrder: [Tab]) {}

    open func didSet(iPhoneMain tabOrder: [Tab]) {}

    open func didSet(iPadMain tabOrder: [Tab]) {}

    open func didSet(iPhoneQuick tabOrder: [Tab]) {}

    open func didSet(iPadQuick tabOrder: [Tab]) {}

    /// QuickTabBar is fully displayed.
    /// - Parameter isSlide: isSlide to show or not.
    open func quickNavigationDidAppear(isSlide: Bool) {}

    /// Call when before set `selectedType` immediately (for `selectedType` really changed).
    /// you can override this to handle event yourself.
    /// you must call super when you override this func.
    open func willSelectTab(_ tab: Tab, oldTab: Tab) {
        assert(tab != oldTab)
        eventViewController(for: oldTab)?.tabBarController(self, willSwitchOut: oldTab, to: tab)
        eventViewController(for: tab)?.tabBarController(self, willSwitch: oldTab, to: tab)
    }

    /// Call when set `selectedType` and switch tabVC successfully (for `selectedType` really changed).
    /// you can override this to handle event yourself.
    /// you must call super when you override this func.
    open func didSelectTab(_ tab: Tab, oldTab: Tab) {
        assert(tab != oldTab)
        eventViewController(for: oldTab)?.tabBarController(self, didSwitchOut: oldTab, to: tab)
        eventViewController(for: tab)?.tabBarController(self, didSwitch: oldTab, to: tab)
    }

    open func eventViewController(for tab: Tab) -> TabBarEventViewController? {
        assertionFailure("must be override!")
        return nil
    }

    /// index: start from 0
    public func switchMainTab(to index: Int) {
        switch tabbarStyle {
        case .edge:
            edgeTab?.switchMainTab(to: index)
        case .bottom:
            mainTabBar.switchMainTab(to: index)
        }
    }

    /// When set `selectedType` and switch tabVC successed, will call & notify, for `selectedType` really changed
    /// you can override this to handle event yourself.
    open func didSelectTabViewController(_ tabViewController: UIViewController) {}

    open func didSelectTemporaryViewController() {
    }

    /// set hardward keyboard observe enable, only efficient in iPad
    public func setHardwareKeyboardObserve(enable: Bool) {
        if UIDevice.current.userInterfaceIdiom != .pad ||
            enable == self.hardwareKeyboardObserveEnable {
            return
        }
        self.keyboardDisposeBag = DisposeBag()
        self.hardwareKeyboardObserveEnable = enable
        if enable {
            KeyboardKit.shared
                .keyboardEventChange
                .observeOn(MainScheduler.instance)
                .filter({ (event) -> Bool in
                    let handleEventType: [KeyboardEvent.TypeEnum] = [
                        .willShow, .willHide
                    ]
                    return handleEventType.contains(event.type)
                })
                .subscribe(onNext: { [weak self] (event) in
                    guard let self = self,
                        let window = self.mainTabBar.window else { return }
                    if window.lkTraitCollection.horizontalSizeClass == .regular,
                        event.options.belongsToCurrentApp,
                        event.type == .willShow,
                        event.keyboard.type == .hardware,
                        event.keyboard.inputAccessoryHeight == 0,
                        event.keyboard.displayType == .default {
                        self.layoutTabbarForIpad(
                            keyboardHeight: event.keyboard.frame.height
                        )
                    } else {
                        self.layoutTabbarForIpad()
                    }
                    UIView.animate(
                        withDuration: event.options.animationDuration,
                        delay: 0,
                        options: event.options.animationOptions,
                        animations: {
                            self.view.layoutIfNeeded()
                        }, completion: nil)

                }).disposed(by: self.keyboardDisposeBag)
        } else {
            self.layoutTabbarForIpad()
        }
    }

    /// 提供 TabBar 上的按钮位置，方便展示引导
    public func mainTabWindowRect(for mainTab: Tab) -> CGRect? {
        guard let index = mainTabBarItems.firstIndex(where: { $0.tab == mainTab }) else {
            return nil
        }
        switch tabbarStyle {
        case .edge:
            return edgeTab?.tabWindowRect(for: index)
        case .bottom:
            return mainTabBar.tabWindowRect(for: index)
        }
    }

    /// 提供 “更多” 按钮在主 Window 上的位置，方便展示引导
    public func moreTabWindowRect() -> CGRect? {
        return mainTabBar.moreTabWindowRect()
    }

    /// 遍历溢出的 view controller
    private func traverseExceededVC(_ block: (UIViewController) -> Void) {
        /// Tabbar 最大展示 vc 数目为 5，如果超过 5 个 vc 则只会展示 4 个，其余的作为溢出的 viewController
        /// 溢出的 vc 会被一个 MoreNavigation 替代，不会实时收到一些系统回调，需要手动调用
        ///
        Self.logger.info("Traverse Exceeded VC")
        guard let viewControllers = self.customizableViewControllers else {
            return
        }
        let children = self.children

        let fg = self.userResolver.fg.dynamicFeatureGatingValue(with: "ios.tabbar.traverseexceededvc")

        Self.logger.info("TraverseExceededVC FeatureGatingValue is \(fg)")

        let exceededVCs = viewControllers.filter { (controller) -> Bool in
            Self.logger.info("controller: \(controller), isViewLoaded: \(controller.isViewLoaded), isChild: \(children.contains(controller))")

            /// 不依赖!children.contains(controller)，在后台会出现children和viewControllers不匹配的情况
            /// 删除!children.contains(controller)
            if fg {
                return controller.isViewLoaded
            } else {
                return !children.contains(controller) && controller.isViewLoaded
            }
        }
        exceededVCs.forEach { (controller) in
            block(controller)
        }
    }
    // MARK: 更新items接口
    open func resetTabBarItems(allTabBarItems: [AbstractTabBarItem]) {
        tabBarItems = [:]
        allTabBarItems.forEach { tabBarItems[$0.tab] = $0 }
        self.resetEdgeTemporaryItems()
    }

    open func shouldUpdateTemporary(_ candidate: TabCandidate, oldID: String) -> Bool {
        return !self.mainTabBarItems.contains(where: { item in
            item.tab.key == oldID || item.tab.key == candidate.uniqueId
        }) && !self.quickTabBarItems.contains(where: { item in
            item.tab.key == oldID || item.tab.key == candidate.uniqueId
        })
    }

    open func reopenTab() {

    }

    open func searchItemTapped() {} //子类实现
    open func addTabContainableTask() { }
}

extension AnimatedTabBarController {
    public func updateMainItemsOrder(bottomMainTabs: [Tab], edgeMainTabs: [Tab]) {
        // fg关闭则不展示自定义类型
        var bottomMainTabs = bottomMainTabs
        if !self.isQuickLauncherEnabled {
            bottomMainTabs = bottomMainTabs.filter({ $0.isCustomType() == false })
        }
        resetBottomMainItemViews(items: getItemsFromDict(with: bottomMainTabs))
        resetEdgeMainItemViews(items: getItemsFromDict(with: edgeMainTabs))
        reassignCustomViews()
    }

    public func updateQuickItemsOrder(bottomQuickTabs: [Tab], edgeQuickTabs: [Tab]) {
        // fg关闭则不展示自定义类型
        var bottomQuickTabs = bottomQuickTabs
        if !self.isQuickLauncherEnabled {
            bottomQuickTabs = bottomQuickTabs.filter({ $0.isCustomType() == false })
        }
        resetBottomQuickItemViews(items: getItemsFromDict(with: bottomQuickTabs))
        resetEdgeQuickItemViews(items: getItemsFromDict(with: edgeQuickTabs))
        reassignCustomViews()
    }

    /// 单独更新主导航顺序
    public func updateMainItemsOrder(iPhoneMainTabs: [Tab], iPadMainTabs: [Tab]) {
        var iPhoneMainTabs = iPhoneMainTabs
        if !self.isQuickLauncherEnabled {
            // fg关闭则不展示自定义类型
            iPhoneMainTabs = iPhoneMainTabs.filter({ $0.isCustomType() == false })
        }
        // iPad设备和iPhone设备数据源完全隔离
        if Display.pad {
            resetIPadMainItemViews(items: getItemsFromDict(with: iPadMainTabs))
        } else {
            resetIPhoneMainItemViews(items: getItemsFromDict(with: iPhoneMainTabs))
        }
        reassignCustomViews()
    }

    /// 单独更新快捷导航顺序
    public func updateQuickItemsOrder(iPhoneQuickTabs: [Tab], iPadQuickTabs: [Tab]) {
        // fg关闭则不展示自定义类型
        var iPhoneQuickTabs = iPhoneQuickTabs
        if !self.isQuickLauncherEnabled {
            iPhoneQuickTabs = iPhoneQuickTabs.filter({ $0.isCustomType() == false })
        }
        // iPad设备和iPhone设备数据源完全隔离
        if Display.pad {
            resetIPadQuickItemViews(items: getItemsFromDict(with: iPadQuickTabs))
        } else {
            resetIPhoneQuickItemViews(items: getItemsFromDict(with: iPhoneQuickTabs))
        }
        reassignCustomViews()
    }

    /// Pin、UnPin、Edit之后的回调，更新导航顺序（根据当前设备）
    public func updateItemsOrder(mainTabs: [Tab], quickTabs: [Tab]) {
        if Display.pad {
            resetIPadMainItemViews(items: getItemsFromDict(with: mainTabs))
            resetIPadQuickItemViews(items: getItemsFromDict(with: quickTabs))
        } else {
            resetIPhoneMainItemViews(items: getItemsFromDict(with: mainTabs))
            resetIPhoneQuickItemViews(items: getItemsFromDict(with: quickTabs))
            
        }
        // 如果打开了 QuickLauncher，刷新数据源
        quickLaunchWindow?.launchController.reloadData()
        // 重新添加Tab应用上的自定义控件，目前就是日历
        reassignCustomViews()
    }

    /// 按 TabBarStyle 来更新顺序，默认按当前 Style 更新
    public func updateItemsOrderOfStyle(mainTabs: [Tab], quickTabs: [Tab], style: TabbarStyle? = nil) {
        let tabbarStyle = style ?? self.tabbarStyle
        switch tabbarStyle {
        case .bottom:
            resetBottomMainItemViews(items: getItemsFromDict(with: mainTabs))
            resetBottomQuickItemViews(items: getItemsFromDict(with: quickTabs))
            // 如果打开了 QuickLauncher，刷新数据源
            quickLaunchWindow?.launchController.reloadData()
        case .edge:
            resetEdgeMainItemViews(items: getItemsFromDict(with: mainTabs))
            resetEdgeQuickItemViews(items: getItemsFromDict(with: quickTabs))
        }
        reassignCustomViews()
    }

    /// 从 tabBarItems 中获取 item
    private func getItemsFromDict(with tabs: [Tab]) -> [AbstractTabBarItem] {
        assert(Thread.isMainThread, "ui data accessible only on main thread")
        let tabs = tabs.filter { !$0.key.isEmpty }
        guard !tabs.isEmpty else {
            Self.logger.error("[Animated Tabbar] all tab key is empty")
            return []
        }
        var items = _getItemsFromDict(with: tabs)
        if items.isEmpty && self.quickTabInitTask != nil {
            Self.logger.error("[Animated Tabbar] trigger quick tab init task")
            // ？？？ 不知道是干啥的
            self.quickTabInitTask?()
            items = _getItemsFromDict(with: tabs)
        }
        return items
    }

    private func _getItemsFromDict(with tabs: [Tab]) -> [AbstractTabBarItem] {
        tabs.compactMap { newTab in
            // 自定义类型没法注册
            if let item = tabBarItems[newTab] {
                return item
            }
            if let item = self.mainTabBarItems.first(where: {
                $0.tab == newTab
            }) {
                return item
            }
            if let item = self.quickTabBarItems.first(where: {
                $0.tab == newTab
            }) {
                return item
            }
            if newTab.isCustomType() {
                if let item = self.temporaryTabs.first(where: { temporary in
                    return temporary.tab.key == newTab.key
                }) {
                    return item
                }
                let config = ItemStateConfig(defaultIcon: nil, selectedIcon: nil, quickBarIcon: nil)
                return TabBarItem(tab: newTab, title: newTab.name ?? "", stateConfig: config)
            }
            Self.logger.error("尝试更新了未注册的 item tab: \(newTab.urlString)")
            return nil
       }
    }

    private func resetIPhoneMainItemViews(items: [AbstractTabBarItem]) {
        let newItems = items.map {
            $0.tab.extra[NavigationKeys.launcherFrom] = NavigationKeys.LauncherFrom.main
            return $0
        }
        allTabBarItems.iPhone.main = newItems
        mainTabBar.tabItems = newItems
        didSet(iPhoneMain: newItems.map { $0.tab })
    }

    private func resetIPhoneQuickItemViews(items: [AbstractTabBarItem]) {
        let newItems = items.map {
            $0.tab.extra[NavigationKeys.launcherFrom] = NavigationKeys.LauncherFrom.quick
            return $0
        }
        allTabBarItems.iPhone.quick = newItems
        quickTabInitTask = nil
        if let moreView = mainTabBar.moreView, let item = moreView.item, let gridView = item.customView as? TabMoreGridView {
            gridView.tabBarItems = newItems
        }
        refreshQuickTabBar(newItems)
        didSet(iPhoneQuick: newItems.map { $0.tab })
    }

    private func resetIPadMainItemViews(items: [AbstractTabBarItem]) {
        let newItems = items.map {
            $0.tab.extra[NavigationKeys.launcherFrom] = NavigationKeys.LauncherFrom.main
            return $0
        }
        // 给数据源赋值
        allTabBarItems.iPad.main = newItems
        // R模式
        edgeTab?.mainTabItems = newItems
        // C模式（主导航最多显示5个哦）
        let mainItems = allTabBarItems.iPad.main.prefix(iPadCModeMaxMainCount)
        mainTabBar.tabItems = Array(mainItems)

        didSet(iPadMain: newItems.map { $0.tab })
    }

    private func resetIPadQuickItemViews(items: [AbstractTabBarItem]) {
        let newItems = items.map {
            $0.tab.extra[NavigationKeys.launcherFrom] = NavigationKeys.LauncherFrom.quick
            return $0
        }
        // 给数据源赋值
        allTabBarItems.iPad.quick = newItems
        // R模式
        edgeTab?.hiddenTabItems = newItems
        if let item = edgeMoreItem, let gridView = item.customView as? TabMoreGridView {
            gridView.tabBarItems = newItems
        }
        // C模式（主导航最多显示5个，显示不下的要加到快捷导航的最前面）
        let mainItems = allTabBarItems.iPad.main
        let mainCount = mainItems.count
        var quickItems = newItems
        if mainCount > iPadCModeMaxMainCount {
            // 因为C模式下底部主导航最多只能显示5个，所以把截断的“拼到”快捷导航前面
            let mainSuffix = Array(mainItems[iPadCModeMaxMainCount..<mainCount])
            quickItems = mainSuffix + newItems
        }
        quickTabInitTask = nil
        if let moreView = mainTabBar.moreView, let item = moreView.item, let gridView = item.customView as? TabMoreGridView {
            gridView.tabBarItems = quickItems
        }
        refreshQuickTabBar(quickItems)

        didSet(iPadQuick: newItems.map { $0.tab })
    }

    private func resetBottomMainItemViews(items: [AbstractTabBarItem]) {
        let newItems = items.map {
            $0.tab.extra[NavigationKeys.launcherFrom] = NavigationKeys.LauncherFrom.main
            return $0
        }
        allTabBarItems.bottom.main = newItems
        mainTabBar.tabItems = newItems
        didSet(bottomMain: newItems.map { $0.tab })
    }

    private func resetBottomQuickItemViews(items: [AbstractTabBarItem]) {
        let newItems = items.map {
            $0.tab.extra[NavigationKeys.launcherFrom] = NavigationKeys.LauncherFrom.quick
            return $0
        }
        allTabBarItems.bottom.quick = newItems
        quickTabInitTask = nil
        if let moreView = mainTabBar.moreView, let item = moreView.item, let gridView = item.customView as? TabMoreGridView {
            gridView.tabBarItems = newItems
        }
        refreshQuickTabBar(newItems)
        didSet(bottomQuick: newItems.map { $0.tab })
    }

    private func resetEdgeMainItemViews(items: [AbstractTabBarItem]) {
        let newItems = items.map {
            $0.tab.extra[NavigationKeys.launcherFrom] = NavigationKeys.LauncherFrom.main
            return $0
        }
        allTabBarItems.edge.main = newItems
        edgeTab?.mainTabItems = newItems
        didSet(edgeMain: newItems.map { $0.tab })
    }

    private func resetEdgeQuickItemViews(items: [AbstractTabBarItem]) {
        let newItems = items.map ({ item -> AbstractTabBarItem in
            guard item.stateConfig.defaultIcon == nil ||
            item.stateConfig.selectedIcon == nil ||
            item.stateConfig.quickBarIcon == nil else {
                item.tab.extra[NavigationKeys.launcherFrom] = NavigationKeys.LauncherFrom.quick
                return item
            }
            let uniqueId = item.tab.tabIcon?.content ?? (item.tab.uniqueId ?? item.tab.key)
            let decorateItem: AbstractTabBarItem
            if let defaultIcon = self.docDefaultIconCache?[uniqueId],
                let selectIcon = self.docSelectIconCache?[uniqueId],
                let quickIcon = self.docQuickIconCache?[uniqueId] {
                decorateItem = item
                decorateItem.stateConfig.defaultIcon = defaultIcon
                decorateItem.stateConfig.selectedIcon = selectIcon
                decorateItem.stateConfig.quickBarIcon = quickIcon
            } else {
                if let tabItem = item as? TabBarItem{
                    decorateItem = self.decorateEdgeTemporaryItem(userResolver: self.userResolver, item: tabItem)
                } else {
                    decorateItem = item
                }
            }
            decorateItem.tab.extra[NavigationKeys.launcherFrom] = NavigationKeys.LauncherFrom.quick
            return decorateItem
        })
        allTabBarItems.edge.quick = newItems
        edgeTab?.hiddenTabItems = newItems
        if let item = edgeMoreItem, let gridView = item.customView as? TabMoreGridView {
            gridView.tabBarItems = newItems
        }
        didSet(edgeQuick: newItems.map { $0.tab })
    }

    private func resetEdgeTemporaryItems() {
        addTabContainableTask()
        self.temporaryTabs = self.temporaryTabService.tabs.map({ item -> TabBarItem in
            if let newTab = self.tabBarItems.values.first(where: { tabItem in
                return tabItem.tab.key == item.uniqueId
            }) as? TabBarItem {
                newTab.tab.extra[NavigationKeys.launcherFrom] = NavigationKeys.LauncherFrom.temporary
                return newTab
            }
            let tabItem = TabBarItem.tranformBy(item)
            let decorateItem: TabBarItem
            let uniqueId = tabItem.tab.tabIcon?.content ?? (tabItem.tab.uniqueId ?? tabItem.tab.key)
            if let defaultIcon = self.docDefaultIconCache?[uniqueId],
                let selectIcon = self.docSelectIconCache?[uniqueId],
                let quickIcon = self.docQuickIconCache?[uniqueId] {
                decorateItem = tabItem
                decorateItem.stateConfig.defaultIcon = defaultIcon
                decorateItem.stateConfig.selectedIcon = selectIcon
                decorateItem.stateConfig.quickBarIcon = quickIcon
            } else {
                decorateItem = self.decorateEdgeTemporaryItem(userResolver: self.userResolver, item: tabItem)
            }
            if decorateItem.tab.key == self.selectedTab.key {
                decorateItem.selectedState()
                decorateItem.selectedUserEvent()
            }
            decorateItem.tab.extra[NavigationKeys.launcherFrom] = NavigationKeys.LauncherFrom.temporary
            return decorateItem
        })
        edgeTab?.temporaryTabItems = self.temporaryTabs
    }

    /// 修饰临时区应用：租户配置或者用户配置的，不同类型应用图标的处理都不一样，最特殊的当属CCM的文档图标，文档那边设计不符合规范，太业务化了！
    private func decorateEdgeTemporaryItem(userResolver: UserResolver, item: TabBarItem) -> TabBarItem {
        // 新导航用户配置的自定义应用
        if let tabIcon = item.tab.tabIcon {
            let key = item.tab.key
            let uniqueId = item.tab.tabIcon?.content ?? (item.tab.uniqueId ?? key)
            self.loadImage(userResolver: userResolver, tabIcon: tabIcon, tabItem: item) { [weak self] img in
                // 产品要求没有选中状态图片需要统一置灰处理
                if let resultImage = UIImage.transformToGrayImage(img) {
                    item.stateConfig.defaultIcon = resultImage
                    self?.docDefaultIconCache?[uniqueId] = resultImage
                } else {
                    item.stateConfig.defaultIcon = img
                    self?.docDefaultIconCache?[uniqueId] = img
                }
                item.stateConfig.selectedIcon = img
                self?.docSelectIconCache?[uniqueId] = img
                item.stateConfig.quickBarIcon = img
                self?.docQuickIconCache?[uniqueId] = img
                // 数据模型变化的时候需要通知给上层业务刷新控件或者页面
                NotificationCenter.default.post(name: .LKTabDownloadIconSucceedNotification, object: ["key": key, "uniqueId": uniqueId], userInfo: nil)
            }
        }
        return item
    }
}

extension AnimatedTabBarController {
    // 根据图标类型加载图片，注意基本都是异步获取，所以要考虑数据模型变化的时候如何通知业务刷新UI
    func loadImage(userResolver: UserResolver, tabIcon: TabCandidate.TabIcon, tabItem: TabBarItem, success: @escaping (UIImage) -> Void) {
        let placeHolder = UDIcon.getIconByKey(.globalLinkOutlined, iconColor: UIColor.ud.iconN3)
        switch tabIcon.type {
        case .iconInfo:
            // 如果是ccm iconInfo图标
            if let docsService = try? userResolver.resolve(assert: DocsIconManager.self) {
                docsService.getDocsIconImageAsync(iconInfo: tabIcon.content, url: tabItem.tab.urlString, shape: .SQUARE)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { (image) in
                        success(image)
                    }, onError: { error in
                        Self.logger.error("<NAVIGATION_BAR> get docs icon image error", error: error)
                    }).disposed(by: self.disposeBag)
            } else {
                Self.logger.error("<NAVIGATION_BAR> can't resolver DocsIconManager")
            }
        case .udToken:
            // 如果是UD图片
            let image = UDIcon.getIconByString(tabIcon.content) ?? placeHolder
            success(image)
        case .byteKey, .webURL:
            // 如果是ByteImage或者网络图片
            var resource: LarkImageResource
            if tabIcon.type == .byteKey {
                let (key, entityId) = tabIcon.parseKeyAndEntityID()
                resource = .avatar(key: key ?? "", entityID: entityId ?? "")
            } else {
                resource = .default(key: tabIcon.content)
            }
            // 获取图片资源
            LarkImageService.shared.setImage(with: resource, completion:  { (imageResult) in
                var image = placeHolder
                switch imageResult {
                case .success(let r):
                    if let img = r.image {
                        image = img
                    } else {
                        Self.logger.error("<NAVIGATION_BAR> LarkImageService get image result is nil!!! tabIcon content = \(tabIcon.content)")
                    }
                case .failure(let error):
                    Self.logger.error("<NAVIGATION_BAR> LarkImageService get image failed!!! tabIcon content = \(tabIcon.content), error = \(error)")
                    break
                }
                success(image)
            })
        @unknown default:
            break
        }
    }
}

// MARK: - initialize
extension AnimatedTabBarController {

    private func initTababrCanvas() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.view.addSubview(_tabbarCanvas)
            _tabbarCanvas.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            _tabbarCanvas.tapCallback = { [weak self] in
                self?.edgeTab?.tabbarLayoutStyle = .vertical
                AnimatedTabBarController.globalEdgeTabbarStyle = true
                self?.layoutTabbarForIpad()
            }

            temporaryTabContainer.traitCollectionDidChangeCallback = { [weak self] (tab) in
                guard let `self` = self, tab.tabContainableIdentifier == self.selectedTab.key else { return }
                let isCollapsed = self.traitCollection.horizontalSizeClass == .compact
                if isCollapsed {
                    self.hiddenTabBarIfNeeded()
                } else {
                    self.showTabBarIfNeeded(to: self)
                }
            }
        }
    }

    private func initializeMainTab() {
        mainTabBar.delegate = tabBar.delegate
        mainTabBar.mainTabBarDelegate = self
        if UIDevice.current.userInterfaceIdiom == .pad {
            tabBar.isTranslucent = tabBarConfig.translucent
            tabBar.isHidden = true
            self.tabbarCanvas.addSubview(mainTabBar)
            self.tabbarCanvas.bringSubviewToFront(mainTabBar)
            layoutTabbarForIpad()
        } else {
            // 使用自定义的 MainTabBar 替换 UITabBar
            self.setValue(mainTabBar, forKey: "tabBar")
        }
    }

    private func initializeMoreItems() {
        bottomMoreItem = createMoreItem()
        edgeMoreItem = createMoreItem()
    }

    private func createMoreItem() -> TabBarItem {
        // 由 FG 控制按钮样式
        if isQuickLauncherEnabled {
            // “启动” 按钮
            // NOTE: 按钮只在 QuickLaunchView 有选中态，此处不设置 selectedIcon
            let item = TabBarItem(
                tab: Tab.more,
                title: BundleI18n.AnimatedTabBar.Lark_Core_More_Navigation,
                stateConfig: ItemStateConfig(
                    defaultIcon: nil,
                    selectedIcon: nil,
                    quickBarIcon: nil
                )
            )
            item.customView = TabMoreGridView(tabBarItems: self.quickTabBarItems)
            item.itemState = DefaultTabState()
            return item
        } else {
            // “更多” 按钮
            let isTemporaryEnabled = self.temporaryTabService.isTemporaryEnabled
            let defaultIcon = !isTemporaryEnabled ? Resources.AnimatedTabBar.tab_more_button_normal : UDIcon.getIconByKey(.moreLauncherOutlined, iconColor: UIColor.ud.iconN3)
            let selectedIcon = !isTemporaryEnabled ? Resources.AnimatedTabBar.tab_more_button_selected : UDIcon.getIconByKey(.moreLauncherOutlined, iconColor: UIColor.ud.primaryPri500)
            let item = TabBarItem(
                tab: Tab.more,
                title: BundleI18n.AnimatedTabBar.Lark_Legacy_NavigationMore,
                stateConfig: ItemStateConfig(
                    defaultIcon: defaultIcon,
                    selectedIcon: selectedIcon,
                    quickBarIcon: nil
                )
            )
            item.itemState = DefaultTabState()
            return item
        }
    }

    private func initTemporaryTabs() {
        temporaryTabService.set(delegate: self)
        resetEdgeTemporaryItems()
    }

    private func initEdgePanGesture() {
        self.edgePanGesture.addTarget(self, action: #selector(handleEdge(pan:)))
        self.edgePanGesture.delegate = self
        self.view.addGestureRecognizer(edgePanGesture)
    }

    @objc
    private func handleEdge(pan: UIPanGestureRecognizer) {
        guard self.tabbarStyle == .edge,
              let edgeTab = self.edgeTab,
              self.temporaryTabService.isTemporaryEnabled else {
            return
        }

        let location = pan.location(in: self.view)
        let velocity = pan.velocity(in: self.view)

        switch pan.state {
        case .began:
            panEdgeTabStartLocationX = location.x
            self.updateEdge = true
        case .changed:
            /// 拖动过程中设置拖拽偏移
            /// 修改偏移是为了避免拖动中宽度与最终宽度一致导致系统 viewWillTransation 不回调
            let distance = location.x - panEdgeTabStartLocationX
            var width = (self.edgeTab?.tabbarLayoutStyle.width ?? 0) + distance
            if width > EdgeTabBarLayoutStyle.horizontal.width {
                width = EdgeTabBarLayoutStyle.horizontal.width
            } else if width < EdgeTabBarLayoutStyle.vertical.width {
                width = EdgeTabBarLayoutStyle.vertical.width
            }

            updateEdgePanFrame(width: width)
        case .cancelled, .ended, .failed:
            self.panEdgeTabStartLocationX = 0
            /// 手势结束 重置偏移
            self.edgeTabbarOffset = nil
            /// 判断是否需要显示 edgeBar
            var style: EdgeTabBarLayoutStyle = .vertical
            if (edgeTab.frame.width > edgeTab.tabbarWidth) ||
                (edgeTab.frame.width + (velocity.x / 10) > (edgeTab.tabbarWidth / 3 * 2)) {
                style = .horizontal
            }

            /// 判断是快速划出
            let isSwipeShowEdgeTabbar = velocity.x > 1000

            let maxHide: CGFloat = 1500
            let isSwipeHideEdgeTabbar = velocity.x < -maxHide

            /// 根据全局属性更正是否显示
            if !AnimatedTabBarController.globalShowEdgeTabbar,
               (edgeTab.frame.width + (velocity.x / 10)) < (edgeTab.tabbarWidth / 3 * 2) ||
                isSwipeHideEdgeTabbar {
                style = .vertical
            }

            edgeTab.tabbarLayoutStyle = style
            AnimatedTabBarController.globalEdgeTabbarStyle = style == .vertical
            layoutTabbarForIpad()

            /// 更新 edgeTabbar 显示
            self.updateEdge = false
            self.updateEdgeTabbar(show: true, animation: false)
        default:
            break
        }
    }

    private func updateEdgePanFrame(width: CGFloat) {
        guard self.tabbarStyle == .edge, let edgeTab = self.edgeTab else {
            return
        }
        edgeTab.frame = CGRect(x: 0, y: 0, width: width, height: self.view.bounds.height)
        let minWidth: CGFloat = EdgeTabBarLayoutStyle.vertical.width
        let maxWidth: CGFloat = EdgeTabBarLayoutStyle.horizontal.width
        let alpha = (width - minWidth) / (maxWidth - minWidth)
        self._tabbarCanvas.updateMask(alpha: alpha)

        if let containerView = view.subviews.first {
            containerView.frame = CGRect(
                x: width,
                y: 0,
                width: self.view.frame.width - width,
                height: self.view.frame.height
            )
        }
    }
}

// MARK: - MainTabBar UIGestureRecognizerDelegate
extension AnimatedTabBarController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard self.tabbarStyle == .edge, let edgeTab = self.edgeTab else {
            return false
        }

        let location = gestureRecognizer.location(in: self.view)
        let point = (gestureRecognizer as? UIPanGestureRecognizer)?.translation(in: self.view) ?? .zero
        if abs(point.y) / abs(point.x) > 0.15 {
            return false
        }
        return location.x < edgeTab.tabbarWidth || _tabbarCanvas.maskAlpha > 0
    }
}

// MARK: - MainTabBar Delegate

extension AnimatedTabBarController: MainTabBarDelegate {
    func mainTabBar(_ mainTabBar: MainTabBar, didSelectItem tab: Tab) {
        tabItemSelectHandler(for: tab)
    }

    func mainTabBar(_ mainTabBar: MainTabBar, didLongPressItem tab: Tab) {
        tabItemLongPressHandler(for: tab)
    }

    func mainTabBarDidTapMoreButton(_ mainTabBar: MainTabBar) {
        tabBarMoreItemTapHandler()
    }
}

// MARK: - QuickTabBar Delegate

/// EdgeTabbar protocol，触发 tab 点击
extension AnimatedTabBarController: EdgeTabBarDelegate {

    public func edgeTabBar(_ edgeTabBar: EdgeTabBarProtocol, removeTemporaryItems items: [AbstractTabBarItem]) {
        let keys = items.map {
            return $0.tab.key
        }
        /// TODO，需要SDK补充接口
        Self.logger.info("Remove Temporary Item: \(keys)")
        self.temporaryTabService.removeTab(ids: keys)
    }

    public func edgeTabBar(_ edgeTabBar: EdgeTabBarProtocol, didSelectItem item: AbstractTabBarItem) {
        if item.tab.key == Tab.asKey, let topView = Navigator.shared.mainSceneWindow {
            Navigator.shared.push(item.tab.url, context: item.tab.extra, from: topView)
            return
        }
        Self.logger.info("Did Select Item: \(item.tab.key)")
        /// 自定义暂不支持多次点击
        if item.tab.isCustomType(), item.tab.key == self.selectedTab.key {
            return
        }
        tabItemSelectHandler(for: item.tab)
    }

    public func edgeTabBarDidReorderItem(main: [RankItem], hidden: [RankItem], temporary: [AbstractTabBarItem]) {
        Self.logger.info("Reorder Items")

        self.animatedTabBarDelegate?.tabbarController(
            self, didReorderForMain: main, quick: hidden, success: { [weak self] in
                guard let self = self else { return }
                self.temporaryTabs = temporary
                self.temporaryTabService.modifyTabs(temporary.compactMap({
                    guard let item = $0 as? TabBarItem else { return nil }
                    return item.tranformTo()
                }))
            }, fail: nil
        )
    }

    public func edgeTabBarMoreItemsDidChange(_ edgeTabBar: EdgeTabBarProtocol, moreItems: [AbstractTabBarItem]) {
        self.animatedTabBarDelegate?.tabbarController(self, didChangeEdgeMoreItems: moreItems)
    }

    public func hasCloseTab() -> Bool {
        return !self.closeTemporaryTab.isEmpty
    }

    // 更新tab->tabBarItem的映射数据源，当临时区向固定区提升的时候需要更新这个映射关系
    public func edgeTabBarUpdateTabBarItem(tab: Tab, tabBarItem: AbstractTabBarItem) {
        tabBarItems[tab] = tabBarItem
    }
}

/// TemporaryTabDelegate，刷新临时区域
extension AnimatedTabBarController: TemporaryTabDelegate {
    public func updateTabs() {
        resetEdgeTemporaryItems()
        Self.logger.info("TemporaryTabDelegate Update Tabs")
        if containsTabKey(selectedTab.key) != nil {
            return
        }
        if enableSearchiPadRedesignFG, selectedTab.key == Tab.search.key {
            //关闭了temporary之后，退回到消息tab，然后快速手动切换到搜索tab时，如果temporary触发了update，需要手动过滤，否则会因为search tab与线上已有tab类型不同，containsTabKey里不能过滤到，被直接跳转回消息tab
            Self.logger.info("current tab is search tab, need filter temporary update")
            return
        }
        if self.tabbarStyle == .edge,
           let top = unsafeTabKeyCache.pop(),
           let tab = containsTabKey(top) {
            tabItemSelectHandler(for: tab)
        } else if let first = self.mainTabBarItems.first?.tab {
            tabItemSelectHandler(for: first)
        }
    }

    public func showTab(_ vc: TabContainable) {
        resetEdgeTemporaryItems()
        Self.logger.info("TemporaryTabDelegate Show Tab vc:\(vc.tabContainableIdentifier)")
        tabItemSelectHandler(for: vc)
    }

    public func removeTab(_ ids: [String]) {
        for id in ids {
            self.unsafeTabKeyCache.remove(id)
            if let tab = containsTabKey(id) {
                closeTemporaryTab.use(tab.urlString)
            }
        }

        resetEdgeTemporaryItems()
        /// 主导航不支持删除，只能用户主动移除
        /// removeTabKey(id)
        ///
        Self.logger.info("TemporaryTabDelegate Remove Tab vc:\(ids)")

        let tabId = self.temporaryTabContainer.tabContainable?.tabContainableIdentifier
        if ids.contains(where: {
            tabId == $0
        }) {
            temporaryTabContainer.tabContainable?.willCloseTemporary()
            temporaryTabContainer.removeTabContainable()
        }

        if ids.contains(where: {
            selectedTab.key == $0
        }) {
            selectedTabItem?.deselectedState()

            if self.tabbarStyle == .edge,
               let top = unsafeTabKeyCache.pop(),
               let tab = containsTabKey(top) {
                tabItemSelectHandler(for: tab)
            } else if let first = self.mainTabBarItems.first?.tab {
                tabItemSelectHandler(for: first)
            }
        }
    }

    private func containsTabKey(_ key: String) -> Tab? {
        if let tab = self.mainTabBarItems.first(where: { item in
            item.tab.key == key
        }) {
            return tab.tab
        }

        if let tab = self.quickTabBarItems.first(where: { item in
            item.tab.key == key
        }) {
            return tab.tab
        }

        if let tab = self.temporaryTabs.first(where: {
            $0.tab.key == key
        })?.tab {
            return tab
        }
        return nil
    }
}

// MARK: - event handler
extension AnimatedTabBarController {

    func tabItemSelectHandler(for tabContainableToSelect: TabContainable) {
        Self.logger.info("TabItem Select Handler for vc: \(tabContainableToSelect.tabContainableIdentifier)")
        var newtab = TabBarItem.tranformBy(tabContainableToSelect.transferToTabCandidate()).tab
        if self.mainTabBarItems.contains(where: { item in
            item.tab == newtab
        }) {
            newtab.extra[NavigationKeys.launcherFrom] = NavigationKeys.LauncherFrom.main
            self.updatePageScene(tabContainableToSelect, scene: .main)
        } else if self.quickTabBarItems.contains(where: { item in
            item.tab == newtab
        }) {
            newtab.extra[NavigationKeys.launcherFrom] = NavigationKeys.LauncherFrom.quick
            self.updatePageScene(tabContainableToSelect, scene: .quick)
        } else if self.temporaryTabs.contains(where: { item in
            item.tab == newtab
        }) {
            newtab.extra[NavigationKeys.launcherFrom] = NavigationKeys.LauncherFrom.temporary
            self.updatePageScene(tabContainableToSelect, scene: .temporary)
        }
        selectedTab = newtab
        self.dismissPresentedVC()
        setTabViewController(temporaryTabContainer)
        self.didSelectTemporaryViewController()
        temporaryTabContainer.update(tabContainable: tabContainableToSelect)
        self.safeSetSelectedIndex(0)
    }

    public func tabItemSelectHandler(for tabToSelect: Tab) {
        Self.logger.info("TabItem Select Handler for Tab: \(tabToSelect.key)")
        guard animatedTabBarDelegate?.tabbarController(self, shouldSelect: tabToSelect) == true else { return }
        var newtab = tabToSelect
        if self.mainTabBarItems.contains(where: { item in
            item.tab == newtab
        }) {
            newtab.extra[NavigationKeys.launcherFrom] = NavigationKeys.LauncherFrom.main
        } else if self.quickTabBarItems.contains(where: { item in
            item.tab == newtab
        }) {
            newtab.extra[NavigationKeys.launcherFrom] = NavigationKeys.LauncherFrom.quick
        } else if self.temporaryTabs.contains(where: { item in
            item.tab == newtab
        }) {
            newtab.extra[NavigationKeys.launcherFrom] = NavigationKeys.LauncherFrom.temporary
        }
        // 鉴于移动端和iPad的行为差异很大，干脆区分开来
        if self.tabbarStyle == .bottom {
            // Mobile设备和iPad设备C模式
            var openMode = newtab.openMode
            // 下面是给开平的特化逻辑，如果是用户配置的开平应用（包含小程序和网页应用）都使用push方式打开（否则和租户配置重复的话打开会出现黑屏）
            if newtab.source == .userSource && newtab.appType == .appTypeOpenApp {
                openMode = .pushMode
            } else if newtab.appType == .appTypeURL {
                // 如果是url类型的，那么肯定是push新开页面的方式打开，不用管是否是用户还是租户配置的
                openMode = .pushMode
            }
            if openMode == .pushMode, let topView = Navigator.shared.mainSceneWindow {
                Navigator.shared.push(newtab.url, context: newtab.extra, from: topView)
            } else {
                selectedTab = newtab
            }
            animatedTabBarDelegate?.tabbarController(self, didTapped: newtab)
        } else {
            selectedTab = newtab
            // iPad设备R模式
            if needOpenInTemporary(by: newtab) {
                showTemporary(selectedTab)
            } else {
                animatedTabBarDelegate?.tabbarController(self, didTapped: newtab)
            }
        }
    }

    func tabItemLongPressHandler(for tabToSelect: Tab) {
        guard currentTab == tabToSelect else { return }
        animatedTabBarDelegate?.tabbarController(self, didLongPress: tabToSelect)
    }

    public func tabBarMoreItemTapHandler() {
        if isQuickLauncherEnabled {
            // 调整 TabItem 高亮状态
            updateMainTabBarSelectionState(isQuickTabOpened: false)
            // 新逻辑，展示 QuickLauncher
            self.quickTabInitTask?()
            showOrDismissQuickLauncher()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } else {
            // 调整 TabItem 高亮状态
            updateMainTabBarSelectionState(isQuickTabOpened: isQuickTabBarShown)
            // 旧逻辑，展示 QuickTabBar
            self.quickTabInitTask?()
            showOrDismssQuickTabBar()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            Tracker.post(TeaEvent(Homeric.NAVIGATION_MORE))
        }
    }

    // 调整 TabItem 高亮状态
    func updateMainTabBarSelectionState(isQuickTabOpened: Bool) {
        if !isQuickTabOpened {
            // 展开 QuickTab
            bottomMoreItem?.selectedState()
            if isInBottomMainBar(selectedTab) {
                selectedTabItem?.deselectedState()
            }
        } else {
            // 收起 QuickTab
            if isInBottomMainBar(selectedTab) {
                selectedTabItem?.selectedState()
                bottomMoreItem?.deselectedState()
            } else {
                bottomMoreItem?.selectedState()
            }
        }
    }

    private func showTemporary(_ tab: Tab) {
        guard (selectedTab.isCustomType() && self.tabbarStyle == .edge) || allowTemporaryOpen(for: tab) else { return }

        Self.logger.info("Show Temporary for Tab: \(tab.key)")

        popToRootFromCurrentSelect()
        setTabViewController(temporaryTabContainer)
        self.didSelectTemporaryViewController()
        self.safeSetSelectedIndex(0)
        self.dismissPresentedVC()

        if let first = self.mainTabBarItems.first(where: { item in
            item.tab == selectedTab
        }) as? TabBarItem {
            Self.logger.info("Show Main Item")
            let context = [NavigationKeys.launcherFrom: NavigationKeys.LauncherFrom.main]
            self.temporaryTabService.getTab(first.tranformTo(), context: context) { [weak self] vc in
                guard let vc = vc else { return }
                self?.temporaryTabContainer.update(tabContainable: vc)
                self?.updatePageScene(vc, scene: .main)
            }
        } else if let first = self.quickTabBarItems.first(where: { item in
            item.tab == selectedTab
        }) as? TabBarItem {
            Self.logger.info("Show Quick Item")
            let context = [NavigationKeys.launcherFrom: NavigationKeys.LauncherFrom.quick]
            self.temporaryTabService.getTab(first.tranformTo(), context: context) { [weak self] vc in
                guard let vc = vc else { return }
                self?.temporaryTabContainer.update(tabContainable: vc)
                self?.updatePageScene(vc, scene: .quick)
            }
        } else if let vc = self.temporaryTabService.getTab(id: selectedTab.key,
                                                           context: [NavigationKeys.launcherFrom: NavigationKeys.LauncherFrom.temporary]) {
            Self.logger.info("Show Temporary Item")

            temporaryTabContainer.update(tabContainable: vc)
            self.updatePageScene(vc, scene: .temporary)
        }
    }

    private func updatePageScene(_ vc: UIViewController, scene: PageKeeperScene) {
        if let page = vc as? PagePreservable {
            page.pageScene = scene
        }
    }

    private func dismissPresentedVC() {
        self.presentedViewController?.dismiss(animated: true)
    }

    // swiftlint:disable identifier_name
    /// 在 `selectedTab` 的 `didSet` 中触发
    private func setSelect(from: Tab, to: Tab) {
        dismissQuickTabBar()
        let toTabIsInBottomMainBar = isInBottomMainBar(to)
        if from == to {
            popToRootFromCurrentSelect()
            if toTabIsInBottomMainBar {
                bottomMoreItem?.deselectedState()
            }
            getTabBarItem(for: to)?.selectedState()
            return
        }

        Self.logger.info("Set Select Tab from:\(from.key), to: \(to.key)")

        getTabBarItem(for: from)?.deselectedState()
        getTabBarItem(for: to)?.selectedState()
        getTabBarItem(for: to)?.selectedUserEvent()
        if from != to {
            self.edgeTab?.selectedTab(to)
        }

        if toTabIsInBottomMainBar {
            bottomMoreItem?.deselectedState()
        } else {
            bottomMoreItem?.selectedState()
        }

        // 子类 LkTabbarController 在 override 的 willSelectTab 方法中，通过 Navigator 创建了 VC 实例，
        // 所以此处已经可以取到 SelectVC 了。
        if let selectVC = viewController(for: to), !self.viewControllers!.isEmpty {
            // Tab Lazy：只会有一个VC在TabBarController
            self.safeSetSelectedIndex(0)
            self.didSelectTabViewController(selectVC)
        }

        // 切换Tab，回收符合「deallocAfterSwitchTab」的VC
        if let fromVC = viewController(for: from),
            let tabRoot = self.dependancy?.getTabRootViewController(from: fromVC),
            tabRoot.deallocAfterSwitchTab {
            self.deallocChildViewController(fromVC, tabRoot: tabRoot)
        }

        self.didSelectTab(to, oldTab: from)
        animatedTabBarDelegate?.tabbarController(self, didSelect: to, oldTab: from)
    }
    // swiftlint:enable identifier_name

    private func popToRootFromCurrentSelect() {
        let controller = self.viewController(for: selectedTab)
        let navigation = [controller, controller?.parent].compactMap { $0 as? UINavigationController }
        navigation.first?.popToRootViewController(animated: true)
    }

    /// Tab -> AbstractTabBarItem
    public func getTabBarItem(for tab: Tab) -> AbstractTabBarItem? {
        guard let tabBarItem = self.getItemsFromDict(with: [tab]).first else {
            Self.logger.error("can not find tab.", additionalData: ["tab": "\(tab.key)"])
            return nil
        }
        return tabBarItem
    }

    public func isInBottomMainBar(_ tab: Tab) -> Bool {
        if !self.crmodeUnifiedDataDisable {
            if Display.pad && tabbarStyle == .bottom {
                // iPad设备C模式使用的是iPad的数据源，但是展现上是底部栏，蛋疼的设计
                return allTabBarItems.iPad.main.contains(where: { $0.tab == tab })
            }
            return allTabBarItems.iPhone.main.contains(where: { $0.tab == tab })
        } else {
            return allTabBarItems.bottom.main.contains(where: { $0.tab == tab })
        }
    }
}

// MARK: - update
extension AnimatedTabBarController {
    public func setBadge(at selectTabItem: AbstractTabBarItem, badge: LarkTab.BadgeType, style: BadgeRemindStyle) {
        selectTabItem.updateBadge(type: getType(badge, style), style: getStyle(badge, style))
    }

    /// Merge a series badges into one. Quick items that folded into one item share one badge.
    /// NOTE: types and styles should be corresponded.
    public func mergeBadges(_ types: [LarkTab.BadgeType], _ styles: [BadgeRemindStyle])
                -> (type: LarkBadge.BadgeType, style: BadgeStyle)? {

        Self.logger.info("[NavigationTabBadge] Merge Bdages")

        guard types.count == styles.count else {
            Self.logger.info("[NavigationTabBadge] Merge Bdages unequal")
            return nil
        }
        var mergedType: LarkBadge.BadgeType = .none
        var mergedStyle: LarkBadge.BadgeStyle = .weak
        for index in 0..<types.count {
            // NEED TO BE REFACTORED.
            let type = types[index]
            let style = styles[index]
            // Disgard hidden badge.
            if type == .none { continue }
            // .number(0)的badge不可见，需要去掉，否则会冲掉.dot的badge
            if case let .number(badge) = type, badge <= 0 { continue }
            // Convert AnimatedTabBar.Badge into LarkBadge
            let currentType = getType(type, style)
            let currentStyle = getStyle(type, style)
            // Merge rule: strong > weak
            switch (currentStyle, mergedStyle) {
            case (.strong, .weak):
                // Strong badge will wash out weak badge.
                mergedType = currentType
                mergedStyle = .strong
                Self.logger.info("[NavigationTabBadge] Merge Bdages strong, weak")
            case (.weak, .strong):
                // Disgard weak badge directly.、
                Self.logger.info("[NavigationTabBadge] Merge Bdages weak, strong")
                break
            case (.strong, .strong), (.weak, .weak):
                // Both strong or weak, then merge by style only
                // Merge rule: number > dot > image > none
                switch (currentType, mergedType) {
                case (.label(.number(let count1)), .label(.number(let count2))):
                    Self.logger.info("[NavigationTabBadge] Merge Bdages label count1: \(count1), count2: \(count2)")
                    // If all number, add them
                    mergedType = .label(.number(count1 + count2))
                case (.label(.number(let count)), _), (_, .label(.number(let count))):
                    // If one number, use number
                    Self.logger.info("[NavigationTabBadge] Merge Bdages label 2 count: \(count)")
                    mergedType = .label(.number(count))
                case (.dot, _), (_, .dot):
                    // If one or both dot, use dot
                    Self.logger.info("[NavigationTabBadge] Merge Bdages dot")
                    mergedType = .dot(.lark)
                case (.image(let img), _), (_, .image(let img)):
                    // If one or both image, use image
                    Self.logger.info("[NavigationTabBadge] Merge Bdages dot")
                    mergedType = .image(img)
                default:
                    Self.logger.info("[NavigationTabBadge] Merge Bdages none")
                    mergedType = .none
                }
            default:
                // The type of middle badge is not used here.
                break
            }
        }

                    Self.logger.info("[NavigationTabBadge] Return mergedType \(mergedType.description) style \(mergedStyle.description)")
        return (type: mergedType, style: mergedStyle)
    }

    // TODO: KT
    public func getStyle(_ type: LarkTab.BadgeType, _ style: BadgeRemindStyle) -> LarkBadge.BadgeStyle {
        // 目前只有.dot & .weak 显示灰色，要调整需要改Feed，这期来不及
        // ??? 消息的灰色数字是 .dot，红色数字是 .number，都属于 .weak
        switch (type, style) {
        case (.dot, .weak):     return .weak
        default:                return .strong
        }
    }
    // TODO: KT
    public func getType(_ type: LarkTab.BadgeType, _ style: BadgeRemindStyle) -> LarkBadge.BadgeType {
        // 只有 dot，但是是强提醒，未读才显示红点
        // ??? none 也转成了 label，但是数字是 0
        switch (type, style) {
        case (.image(let image), _):    return .image(.image(image))
        case (.dot, .strong):           return .dot(.lark)
        default:                        return .label(.number(type.count))
        }
    }

    public func changeMainTabbarIcon(for item: AbstractTabBarItem, image: UIImage, selectedImage: UIImage) {
        item.stateConfig.defaultIcon = image
        item.stateConfig.selectedIcon = selectedImage

        if isInBottomMainBar(item.tab), selectedTab == item.tab {
            item.selectedState()
        } else {
            item.deselectedState()
        }
    }

    public func changeQuickTabbarIcon(for item: AbstractTabBarItem, image: UIImage) {
        if !isInBottomMainBar(item.tab) {
            item.stateConfig.quickBarIcon = image
        }
    }
}

// MARK: - iPad
extension AnimatedTabBarController {
    /// See https://bytedance.feishu.cn/space/doc/doccn0xgaG0pxnYn338RPD16rNh
    @objc
    private func layoutTabbarForIpad(keyboardHeight: CGFloat = 0) {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        Self.logger.info("layout Tabbar For Ipad")
        if self.tabbarStyle == .edge, let edgeTab = self.edgeTab {
            Self.logger.info("layout Tabbar For Ipad tabbarStyle == .edge")

            let edgeBarXoffset: CGFloat = edgeTabbarOffset ??
                (self.showEdgeTabbar ? 0 : -edgeTab.tabbarWidth)
            edgeTab.frame = CGRect(x: edgeBarXoffset, y: 0, width: edgeTab.tabbarWidth, height: self.view.bounds.height)
            var alpha: CGFloat = 0
            if self.edgeTab?.tabbarLayoutStyle == .horizontal {
                alpha = 1
            }
            self._tabbarCanvas.updateMask(alpha: alpha)

            let containerView = view.subviews.first
            /// 如果存在 transitionCoordinator 在动画中调整 UI 布局
            ///
            let isMax = self.view.frame.width >= EdgeTabBarLayoutStyle.maxViewWidth
            let edgeWidth = isMax ? max(EdgeTabBarLayoutStyle.vertical.width,
                                        min(edgeTab.frame.width, EdgeTabBarLayoutStyle.horizontal.width)) : EdgeTabBarLayoutStyle.vertical.width

            let containerViewWidth = self.view.frame.width - edgeWidth - edgeBarXoffset

            containerView?.frame = CGRect(
                x: edgeBarXoffset + edgeTab.tabbarWidth,
                y: 0,
                width: min(self.view.frame.width, containerViewWidth),
                height: self.view.frame.height
            )
            if let coordinator = self.transitionCoordinator {
                Self.logger.info("layout Tabbar For Ipad coordinator animate")

                coordinator.animate(alongsideTransition: { (_) in
                    containerView?.frame = CGRect(
                        x: edgeBarXoffset + edgeTab.tabbarWidth,
                        y: 0,
                        width: min(self.view.frame.width, containerViewWidth),
                        height: self.view.frame.height
                    )
                }, completion: nil)
            }
        } else {
            Self.logger.info("layout Tabbar For Ipad tabbarStyle == .bottom")

            var tabbarHeight = self.tabbarIntrinsicHeight
            if keyboardHeight == 0 {
                tabbarHeight += view.safeAreaInsets.bottom
            }

            self._tabbarCanvas.updateMask(alpha: 0)

            if mainTabBar.superview != nil {
                mainTabBar.snp.remakeConstraints { (make) in
                    make.leading.trailing.equalToSuperview()
                    make.height.equalTo(tabbarHeight)
                    make.bottom.equalTo(-keyboardHeight)
                }
            }
            var height: CGFloat = 0.0
            if tabbarCanvas.subviews.contains(mainTabBar) {
                height += tabbarHeight
                height += keyboardHeight
            }
            let extraLength = self.mainTabBar.isTranslucent ? 0 : height
            let containerView = view.subviews.first
            let newFrame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height - extraLength)
            /// 如果存在 transitionCoordinator 在动画中调整 UI 布局
            if let coordinator = self.transitionCoordinator {
                Self.logger.info("layout Tabbar For Ipad coordinator animate")

                if #available(iOS 14, *) {
                    containerView?.frame = newFrame
                }
                coordinator.animate(alongsideTransition: { (_) in
                    if #available(iOS 14, *) {
                        containerView?.frame = newFrame
                    } else {
                        containerView?.snp.remakeConstraints { (make) in
                            make.leading.trailing.top.equalToSuperview()
                            make.bottom.equalToSuperview().inset(extraLength)
                        }
                    }
                }, completion: nil)
            } else {
                if #available(iOS 14, *) {
                    containerView?.frame = newFrame
                } else {
                    containerView?.snp.remakeConstraints { (make) in
                        make.leading.trailing.top.equalToSuperview()
                        make.bottom.equalToSuperview().inset(extraLength)
                    }
                }
            }
        }
        /// Tabar 层级变化，更新 quick tab
        Self.logger.info("dismissQuickTabBarIfNeed")
        dismissQuickTabBarIfNeed()
    }

    /// 响应 navigationVC 切换 vc 时， tabbar 切换 superView
    public func handleNaviPushOrPop(
        navi: UINavigationController,
        fromVC: UIViewController?,
        toVC: UIViewController
    ) {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            return
        }

        guard self.customTabBar != nil else {
            return
        }

        let realFromVC = navi.getTopViewControllerOrSelf(viewController: fromVC)
        guard let realToVC = navi.getTopViewControllerOrSelf(viewController: toVC) else {
            return
        }

        guard navi.selectedByTabbar else {
            return
        }

        var fromNeedShowTabbar = needShowTabbar(realFromVC)
        var toNeedShowTabbar = needShowTabbar(realToVC)

        if let coordinator = navi.transitionCoordinator {
            if let realFrom = realFromVC {
                if !fromNeedShowTabbar && toNeedShowTabbar {
                    // from不需要，to需要
                    showTabBarIfNeeded(to: realToVC)
                } else if fromNeedShowTabbar && !toNeedShowTabbar {
                    // from需要，to不需要
                    showTabBarIfNeeded(to: realFrom)
                } else if fromNeedShowTabbar && toNeedShowTabbar {
                     // 都需要
                    showTabBarIfNeeded(to: self)
                } else {
                    // 都不需要
                    hiddenTabBarIfNeeded()
                }
            } else {
                if toNeedShowTabbar {
                    showTabBarIfNeeded(to: self)
                } else {
                    hiddenTabBarIfNeeded()
                }
            }
            coordinator.animate(alongsideTransition: nil) { (context) in
                fromNeedShowTabbar = self.needShowTabbar(realFromVC)
                toNeedShowTabbar = self.needShowTabbar(realToVC)
                if context.isCancelled {
                    if fromNeedShowTabbar {
                        self.showTabBarIfNeeded(to: self)
                    } else {
                        self.hiddenTabBarIfNeeded()
                    }
                } else {
                    if toNeedShowTabbar {
                        self.showTabBarIfNeeded(to: self)
                    } else {
                        self.hiddenTabBarIfNeeded()
                    }
                }
            }
        } else {
            if toNeedShowTabbar {
                /// 这里特殊判断 targetViewControllers first 是否是 realToVC 是为了处理 setViewControllers 布局错误问题
                /// setViewControllers 会调用两次 第一次可能触发下面逻辑，修正布局
                /// 第二次才是由转场动画的 会最终修正 tabbar 显示的位置
                if let navi = realToVC.navigationController,
                   navi.targetViewControllers?.first == realToVC {
                    showTabBarIfNeeded(to: realToVC)
                } else {
                    showTabBarIfNeeded(to: self)
                }
            } else {
                hiddenTabBarIfNeeded()
            }
        }
        // 在动画过程中会涉及到tabbar从tabbarvc上摘除然后下一个runloop刷新布局，会导致navigationVC在显示vc的时候，vc的布局刷不回来,所以直接刷新tabBar
        self.view.layoutIfNeeded()
    }

    private func hiddenTabBarIfNeeded() {
        self.mainTabBar.removeFromSuperview()
        lastTabbarShowVC = nil

        /// 当 tabbar 为 bottom style 时，刷新 UI
        if self.tabbarStyle == .bottom {
            self.layoutTabbarForIpad()
        }
    }

    private func needShowTabbar(_ controller: UIViewController?) -> Bool {
        guard let controller = controller, let navigation = controller.navigationController,
              navigation.actualViewControllers.first == controller else {
            return false
        }
        guard controller.tabBarController != nil,
              controller.tabBarController is AnimatedTabBarController,
              UIDevice.current.userInterfaceIdiom == .pad else {
            return false
        }
        if let result = AnimatedTabbarConfig.customNeedShowTabbar?(controller) {
            return result
        }
        let needSet = needSetShowTabbar(navi: navigation)
        return needSet
    }

    func getParentNavi(navi: UINavigationController) -> UINavigationController? {
        var parent: UIViewController? = navi.parent
        var parentNavi: UINavigationController?
        while let parentVC = parent {
            if let navi = parentVC as? UINavigationController {
                parentNavi = navi
                break
            } else if parentVC is AnimatedTabBarController {
                break
            }
            parent = parent?.parent
        }
        return parentNavi
    }

    /// 判断 navi 是否需要设置 firstVC 的
    func needSetShowTabbar(navi: UINavigationController) -> Bool {
        /// 这里设置为 true 代表如果不存在 parentNavi 的话
        /// 应该设置当前 navi 可以展示 tabbar
        var needSet = true
        var current: UINavigationController = navi
        while let parentNavi = getParentNavi(navi: current) {
            /// 一直向上找，直到找不到 parentNavi
            /// 必须一直是 parent navi 的第一个 vc，最后返回的 needSet 才是 true
            needSet = checkIsInFirstVC(navi: current, parentNavi: parentNavi)
            current = parentNavi
        }
        return needSet
    }

    /// 判断嵌套 navi 是否是它 parent Navi 的 first VC
    func checkIsInFirstVC(
        navi: UINavigationController,
        parentNavi: UINavigationController
    ) -> Bool {
        let firstVC = parentNavi.viewControllers.first
        var parentVC = navi.parent
        var isInFirstVC = false
        while parentVC != nil {
            if parentVC == parentNavi {
                break
            } else if parentVC == firstVC {
                isInFirstVC = true
                break
            }
            parentVC = parentVC?.parent
        }
        return isInFirstVC
    }

    private func showTabBarIfNeeded(to viewController: UIViewController) {
        if self.mainTabBar.superview == viewController.view {
            return
        }
        lastTabbarShowVC = viewController

        /// 当 tabbar 为 bottom style 时，刷新 UI
        if self.tabbarStyle == .bottom {
            var tabbarSuperView: UIView
            if viewController == self {
                tabbarSuperView = self.tabbarCanvas
            } else {
                tabbarSuperView = viewController.view
            }
            tabbarSuperView.addSubview(self.mainTabBar)
            tabbarSuperView.bringSubviewToFront(self.mainTabBar)
            self.layoutTabbarForIpad()
        }
    }

    // 初始化 child vc traitCollection
    private func setupAllSubVCTraitCollection() {
        let customTraitCollection = self.customTraitCollection()
        viewControllers?.forEach { (controller) in
            self.setOverrideTraitCollection(customTraitCollection, forChild: controller)
        }
    }

    private func customTraitCollection(size: CGSize? = nil) -> UITraitCollection {
        return TraitCollectionKit.customTraitCollection(
            targetTrainCollection ?? traitCollection,
            size ?? self.view.bounds.size
        )
    }

    @discardableResult
    private func updateTabbarStyleIfNeeded(size: CGSize? = nil) -> UITraitCollection {
        let newTraitCollection = customTraitCollection(size: size)
        updateTabbarStyleIfNeeded(traitCollection: newTraitCollection)
        layoutQuickTabBar()
        layoutQuickLaunchBar()
        return newTraitCollection
    }

    private func updateTabbarStyleIfNeeded(traitCollection: UITraitCollection) {
        guard UIDevice.current.userInterfaceIdiom == .pad,
            let edgeTab = self.edgeTab else { return }

        Self.logger.info("update Tabbar Style If Needed")
        if traitCollection.horizontalSizeClass == .regular {
            Self.logger.info("traitCollection horizontalSizeClass is regular")
            self.tabbarStyle = .edge

            Self.logger.info("update Tabbar Style If Needed addSubview")
            self.tabbarCanvas.addSubview(edgeTab)
            Self.logger.info("update Tabbar Style If Needed bringSubviewToFront")
            self.tabbarCanvas.bringSubviewToFront(edgeTab)

            Self.logger.info("update Tabbar Style If Needed set tabbarLayoutStyle")
            edgeTab.tabbarLayoutStyle = Self.globalEdgeTabbarStyle ? .vertical : .horizontal

            Self.logger.info("update Tabbar Style If Needed mainTabBar removeFromSuperview")
            self.mainTabBar.removeFromSuperview()

            Self.logger.info("update Tabbar Style If Needed layout")
            self.layoutTabbarForIpad()
        } else {
            Self.logger.info("traitCollection horizontalSizeClass is compact")

            self.tabbarStyle = .bottom
            Self.logger.info("update Tabbar Style If Needed removeFromSuperview")
            edgeTab.removeFromSuperview()
            /// lastTabbarShowVC  为空代表 mainTabbar 不显示
            if let last = self.lastTabbarShowVC {
                self.showTabBarIfNeeded(to: last)
            } else {
                self.layoutTabbarForIpad()
            }
        }
    }
}

// MARK: - safe call
extension AnimatedTabBarController {
    public func safeSetSelectedIndex(_ selectedIndex: Int) {
        defer { safeSetSelectedIndex = false }
        safeSetSelectedIndex = true
        self.selectedIndex = selectedIndex
    }

    public func safeSetViewControllers(_ viewControllers: [UIViewController]?, animated: Bool) {
        defer { safeSetViewControllers = false }
        safeSetViewControllers = true
        self.setViewControllers(viewControllers, animated: animated)
    }
}

// MARK: - Memory
extension AnimatedTabBarController {
    open override func didReceiveMemoryWarning() {
        AnimatedTabBarController.logger.info("TabBar begin memoryWarning: \(self.currentVC)")
        if let children = self.viewControllers, let current = children.first {
            let controllers = children
                .filter { $0 != current }
                .filter { self.dependancy?.getTabRootViewController(from: $0)?.deamon ?? false }
            self.safeSetViewControllers([current] + controllers, animated: false)
        }
        AnimatedTabBarController.logger.info("TabBar after memoryWarning: \(self.currentVC)")
        super.didReceiveMemoryWarning()
    }

    /// 切换Tab，释放被切走的VC
    /// - Parameter controller: 被切走的VC
    private func deallocChildViewController(_ controller: UIViewController, tabRoot: TabRootViewController) {
        guard let children = self.viewControllers, children.contains(controller) else { return }
        let vcs = children.filter { $0 != controller }
        self.safeSetViewControllers(vcs, animated: false)
        AnimatedTabBarController.logger.info("Dealloc Child ViewController: \(tabRoot.tab.urlString)")
    }

    private var currentVC: String {
        return self.viewControllers?
            .compactMap { self.dependancy?.getTabRootViewController(from: $0)?.tab.urlString }
            .joined(separator: "|") ?? ""
    }
}

// MARK: - Help Function
extension AnimatedTabBarController {
    // 查询某个应用是否在主导航里面（main + quick），参数：tabBizType & appId
    public func findInNavigation(bizType: CustomBizType, appId: String) -> Bool {
        let uniqueId = Tab.generateAppUniqueId(bizType: bizType, appId: appId)
        return findInNavigation(uniqueId: uniqueId)
    }
    
    // 查询某个应用是否在主导航里面（main + quick），参数：uniqueId
    public func findInNavigation(uniqueId: String) -> Bool {
        let allTabs: [AbstractTabBarItem]
        if !self.crmodeUnifiedDataDisable {
            if Display.pad {
                allTabs = self.allTabBarItems.iPad.main + self.allTabBarItems.iPad.quick
            } else {
                allTabs = self.allTabBarItems.iPhone.main + self.allTabBarItems.iPhone.quick
            }
        } else {
            if self.tabbarStyle == .bottom {
                allTabs = self.allTabBarItems.bottom.main + self.allTabBarItems.bottom.quick
            } else {
                allTabs = self.allTabBarItems.edge.main + self.allTabBarItems.edge.quick
            }
        }
        let finds = allTabs.filter { (item) -> Bool in
            let id = item.tab.uniqueId ?? item.tab.key
            return id == uniqueId
        }
        return !finds.isEmpty
    }
}


/// Tabbar 画布，透传不再 tabbar 上的手势
final class TabbarCanvas: UIView {
    static let maskBGColor = UIColor.ud.staticBlack15 & UIColor.ud.staticBlack50

    var isMaxScreen: Bool {
        self.window?.frame.width ?? 0 >= EdgeTabBarLayoutStyle.maxViewWidth
    }

    private var maskBGView: UIView = {
        let maskView = UIView()
        maskView.backgroundColor = TabbarCanvas.maskBGColor
        return maskView
    }()

    var maskAlpha: CGFloat {
        return maskBGView.alpha
    }

    var tapCallback: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(maskBGView)
        maskBGView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        maskBGView.alpha = 0
        maskBGView.lu.addTapGestureRecognizer(action: #selector(tap), target: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        if hitView == self { return nil }
        return hitView
    }

    func updateMask(alpha: CGFloat) {
        maskBGView.alpha = self.isMaxScreen ? 0 : alpha
    }

    @objc func tap() {
        self.tapCallback?()
    }
}

// swiftlint:enable file_length
