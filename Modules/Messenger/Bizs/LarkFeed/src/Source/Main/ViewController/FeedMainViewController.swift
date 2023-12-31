//
//  FeedMainViewController.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/8.
//

import UIKit
import Foundation
import SnapKit
import RxDataSources
import RxSwift
import RxCocoa
import LarkNavigation
import AnimatedTabBar
import LKCommonsLogging
import RunloopTools
import LarkSDKInterface
import RustPB
import AppContainer
import LarkPerf
import LarkMessengerInterface
import EENavigator
import LarkKeyCommandKit
import LarkUIKit
import UniverseDesignTabs
import UniverseDesignDrawer
import LarkContainer
import LarkFoundation
import Heimdallr
import AppReciableSDK
import LarkAccountInterface
import LarkOpenFeed
import LarkFocus
import Swinject

final class FeedMainViewController: BaseUIViewController, LarkNaviBarAbility, UIScrollViewDelegate, UserResolverWrapper {
    var userResolver: UserResolver { mainViewModel.userResolver }

    let chatterManager: ChatterManagerProtocol
    let feedDependency: FeedDependency
    let feedGuideDependency: FeedGuideDependency
    let passportUserService: PassportUserService

    weak var filterPopoveController: PopoveContentControllerProvider?

    // 放在导航栏展示的个人状态 UI 组件
    lazy var naviFocusView: FocusNaviDisplayView = {
        let view = FocusNaviDisplayView()
        view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapNaviFocusStatus)))
        return view
    }()

    // Vibration
    var isAllowVibrate: Bool = false
    lazy var feedbackGenerator: UIImpactFeedbackGenerator = {
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.prepare()
        return feedback
    }()

    var onViewAppeared = BehaviorRelay<Bool>(value: false)

    // Statistics
    var CustomExtra = ["biz": Biz.Messenger.rawValue, "scene": Scene.Feed.rawValue]

    // SubViews
    lazy var mainScrollView = FeedScrollView()

    lazy var headerView: FeedHeaderViewInterface = {
        let view = FeedHeaderView(frame: .zero, context: context.userResolver)
        return view
    }()

    lazy var bottomBarView: FeedBottomBarViewInterface = {
        let view = FeedBottomBarView(frame: .zero, context: context.userResolver)
        return view
    }()

    lazy var filterTabView: FilterContainerView = {
        let view = FilterContainerView(mainViewModel: filterTabViewModel, context: context)
        return view
    }()

    lazy var moduleVCContainerView: FeedModuleVCContainerView = {
        let layoutConfig = try? context.userResolver.resolver.resolve(assert: FeedLayoutConfig.self)
        let view = FeedModuleVCContainerView(layoutConfig)
        return view
    }()

    // 基本功能模式的弹窗
    weak var minimumModeTipView: MinimumModeTipView?

    let mainViewModel: FeedMainViewModel
    let filterTabViewModel: FilterContainerViewModel
    let navigationBarViewModel: FeedNavigationBarViewModel

    // 导航栏
    let presentProcessor = FeedPresentProcessor()

    var scrollDirection: ScrollDirection = .unknown
    let context: FeedContextService
    let styleService: Feed3BarStyleService
    let disposeBag = DisposeBag()
    var feedMainVCAddress = ""
    var _needLazyLoad: Bool = true

    init(navigationBarViewModel: FeedNavigationBarViewModel,
         mainViewModel: FeedMainViewModel,
         filterTabViewModel: FilterContainerViewModel,
         context: FeedContextService,
         styleService: Feed3BarStyleService
    ) throws {
        FeedContext.log.info("feedlog/life/main/init. userId: \(mainViewModel.userId)")
        self.chatterManager = try mainViewModel.resolver.resolve(assert: ChatterManagerProtocol.self)
        self.feedDependency = try mainViewModel.resolver.resolve(assert: FeedDependency.self)
        self.feedGuideDependency = try mainViewModel.resolver.resolve(assert: FeedGuideDependency.self)
        self.passportUserService = try mainViewModel.resolver.resolve(assert: PassportUserService.self)
        self.navigationBarViewModel = navigationBarViewModel
        self.mainViewModel = mainViewModel
        self.filterTabViewModel = filterTabViewModel
        self.context = context
        self.styleService = styleService
        super.init(nibName: nil, bundle: nil)
        self.isLkShowTabBar = true
        FeedPerfTrack.trackFirstRender(status: .start)
        mainViewModel.sendLifeState(.viewInit)
        self.feedMainVCAddress = "\(ObjectIdentifier(self))"
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }

    deinit {
        FeedContext.log.info("feedlog/life/main/deinit. userId: \(mainViewModel.userId), address: \(feedMainVCAddress)")
        mainViewModel.sendLifeState(.viewDeinit)
    }

    override func viewDidLoad() {
        FeedContext.log.info("feedlog/life/main/viewDidLoad. userId: \(mainViewModel.userId), address: \(feedMainVCAddress)")
        let id = TimeLogger.shared.logBegin(eventName: "viewDidLoad")
        defer { TimeLogger.shared.logEnd(identityObject: id, eventName: "viewDidLoad") }
        super.viewDidLoad()
        setupViews()
        layout()
        observeOffsetChange()
        bindHeaderViewModels()
        binds()
        FeedContext.log.info("feedlog/asyncBind/mainVC. start")
        RunloopDispatcher.shared.addTask(priority: .emergency) {
            FeedContext.log.info("feedlog/asyncBind/mainVC. end")
            self.asyncBinds()
        }
        mainViewModel.sendLifeState(.viewDidLoad)
    }

    override func viewWillAppear(_ animated: Bool) {
        FeedContext.log.info("feedlog/life/main/viewWillAppear")
        let id = TimeLogger.shared.logBegin(eventName: "viewWillAppear")
        defer { TimeLogger.shared.logEnd(identityObject: id, eventName: "viewWillAppear") }
        super.viewWillAppear(animated)
        mainViewModel.trackPageView(dataStore: filterTabViewModel.dataStore)
        mainViewModel.sendLifeState(.viewWillAppear)
        // 由于自动结束的状态没有推送，所以每次进入界面时刷新个人状态
        refreshFocusView()
    }

    override func viewDidAppear(_ animated: Bool) {
        FeedContext.log.info("feedlog/life/main/viewDidAppear")
        let id = TimeLogger.shared.logBegin(eventName: "viewDidAppear")
        defer { TimeLogger.shared.logEnd(identityObject: id, eventName: "viewDidAppear") }
        super.viewDidAppear(animated)
        FeedPerfTrack.trackFirstRender(status: .end)
        FeedPerfTrack.trackUpdateFeedShow()
        HMDFrameDropMonitor.shared().addFrameDropCustomExtra(CustomExtra)
        onViewAppeared.accept(true)
        mainViewModel.sendLifeState(.viewDidAppear)
        if let split = self.larkSplitViewController {
            styleService.updateStyle(split.isCollapsed)
        } else {
            styleService.updateStyle(self.view.horizontalSizeClass == .compact)
        }
        self.lazyLoad()
        setNeedsStatusBarAppearanceUpdate()
    }

    override func viewWillDisappear(_ animated: Bool) {
        FeedContext.log.info("feedlog/life/main/viewWillDisappear")
        super.viewWillDisappear(animated)
        onViewAppeared.accept(false)
        mainViewModel.sendLifeState(.viewWillDisappear)
    }

    override func viewDidDisappear(_ animated: Bool) {
        FeedContext.log.info("feedlog/life/main/viewDidDisappear")
        super.viewDidDisappear(animated)
        HMDFrameDropMonitor.shared().removeFrameDropCustomExtra(CustomExtra)
        mainViewModel.sendLifeState(.viewDidDisappear)
    }

    // MARK: Scroll代理方法
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView === self.mainScrollView {
            self.headerView.scrollViewWillBeginDragging()
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView === self.mainScrollView {
            self.headerView.scrollViewDidScroll(offsetY: scrollView.contentOffset.y)
            self.triggerVibration(scrollView)
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView === self.mainScrollView {
            self.headerView.scrollViewDidEndDragging(offsetY: scrollView.contentOffset.y)
        }
    }

    // MARK: iPad相关
    override func keyBindings() -> [KeyBindingWraper] {
        super.keyBindings() + searchKeyCommand()
    }

    /// 跳转搜索VC: iPad上快捷键也会用且iOS13以下extension无法@objc, 所以放到Tab里
    @objc
    func pushSearchController() {
        FeedTracker.Navigation.Click.Search()
        FeedTeaTrack.trackSearchTap()
        let body = SearchMainBody(topPriorityScene: nil, searchTabName: "message")
        userResolver.navigator.push(body: body, from: self)
    }

    @objc
    func nextFilterItem() {
        FeedTeaTrack.trackNextFilterTab()
    }

    @objc
    func previousFilterItem() {
        FeedTeaTrack.trackerLastFilterTab()
    }

    @objc
    func didTapNaviFocusStatus() {
        _didTapNaviFocusStatus()
    }

    func showDrawer() {
        currentSideBarMenu?.showDrawer(UDDrawerTriggerType.click(FeedSideBarClick.tag), completion: {})
    }
}
