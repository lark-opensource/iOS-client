//
//  WorkPlaceViewController.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2020/5/8.
//
// swiftlint:disable file_length

import Foundation
import LarkUIKit
import SnapKit
import LKCommonsLogging
import Swinject
import RxSwift
import RxRelay
import LarkOPInterface
import LarkKeyCommandKit
import EENavigator
import OPFoundation
import LarkContainer
import LarkSetting
import LarkNavigator
import LarkBoxSetting
import LarkQuickLaunchInterface
import LarkGuide

/// 工作台打开场景分类
enum WorkPlaceDisplayScene {
    /// 其他场景显示工作台
    case unknown
    /// 切换tab显示工作台
    case switchTab
}

/// Date: 2020.10
/// 工作台（动态配置）设计说明：
///     （0）主View说明：使用CollectionView作为主视图
///     （1）Item分类说明：Icon类型-图标类应用；Widget类型-自定义配置内容的卡片状应用，可展示业务数据；其他类型：方形/Icon的「添加应用」
///     （2）section划分说明：widget独占一个section，同一个header（或没有header）相邻聚合为一个section
///     （3）业务流程说明：#参考viewDidLoad流程#
///     （4）数据管理说明：workPlaceUIModel：管理UI数据，workPlaceSettingModel：管理配置信息，widgetData：管理widget的业务数据
///

/// TODO: 原逻辑看场景已经不太适合只用在模版工作台了，后续需要迁移到 HomeVC
/// 主端接入的渲染监控
struct WorkPlaceMetrics {
    let initTime = Date()
    var initMemory: UInt64?

    var finishRenderTime: Date? {
        didSet {
            if let finishTs = finishRenderTime {
                let cost = finishTs.timeIntervalSince(initTime)
                WPEventReport(name: WPEvent.appcenter_rendering_time.rawValue)
                    .set(key: "time", value: "\(Int(cost * 1000))")
                    .post()
            }
        }
    }
    var finishRenderMemory: UInt64? {
        didSet {
            if let finishMem = finishRenderMemory, let startMem = initMemory {
                /// 采用溢出的减法，避免溢出的时候潜在crash
                let memoryDiff = (finishMem >= startMem) ? "\(finishMem &- startMem)" : "-\(startMem &- finishMem)"
                WPEventReport(name: WPEvent.appcenter_memory.rawValue)
                    .set(key: "memory", value: "\(String(describing: memoryDiff))")
                    .post()
            }
        }
    }
}

/// widget版工作台主页-视图控制器
final class WorkPlaceViewController: WPBaseViewController,
                                     UICollectionViewDelegate,
                                     UICollectionViewDataSource,
                                     UICollectionViewDelegateFlowLayout,
                                     UICollectionViewDropDelegate,
                                     UICollectionViewDragDelegate,
                                     OperationDialogHostProtocol,
                                     UIPopoverPresentationControllerDelegate {
    static let logger = Logger.log(WorkPlaceViewController.self)

    let context: WorkplaceContext
    lazy var disposeBag: DisposeBag = { DisposeBag() }()
    lazy var notificationDisposeBag: DisposeBag = { DisposeBag() }()

    private let blockDataService: WPBlockDataService

    let dataManager: AppCenterDataManager
    /// 工作台的UIModel（功能更像是一个Model）
    var workPlaceUIModel: WorkPlaceViewModel?
    /// 工作台配置的Model
    var workPlaceSettingModel: WorkPlaceSetting?
    /// 工作台运营配置的Model
    var workPlaceOperationModel: WorkPlaceOperationModel?
    /// Widget业务数据管理对象
    private let widgetData: WidgetDataManage
    /// 上报性能数据
    lazy var metrics: WorkPlaceMetrics = { return WorkPlaceMetrics() }()
    /// 需要显示长按菜单的widget的index
    var needShowMenuIndex: IndexPath?
    /// 工作台点击查看的新应用itemId
    var localCleanNewItemIds = [String]()
    /// widget版工作台表格视图
    lazy var workPlaceCollectionView: WorkPlaceCollectionView = {
        /// collectionView的layout配置
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = WorkPlaceViewModel.itemMinSpace
        layout.sectionHeadersPinToVisibleBounds = true
        /// 实例化collectionView
        let widgetCollectionView = WorkPlaceCollectionView(frame: .zero, collectionViewLayout: layout)
        widgetCollectionView.delegate = self
        widgetCollectionView.dataSource = self
        /// 处理touch事件
        widgetCollectionView.handleTouchEvent = { [weak self] in self?.handleTouchToRemoveBubble() }
        return widgetCollectionView
    }()
    private(set) var collectionViewTopConstraint: Constraint?

    /// 蒙层（能盖住Tab）
    private lazy var maskView: UIView = {
        let view = UIView(frame: UIScreen.main.bounds)  // 去掉frame
        view.backgroundColor = UIColor.ud.bgMask
        view.isUserInteractionEnabled = true
        let ges = UITapGestureRecognizer()
        ges.rx.event.subscribe { [weak self] _ in self?.removeMask() }.disposed(by: disposeBag)
        view.addGestureRecognizer(ges)
        return view
    }()
    /// 运营位文案
    private var operationText: String?
    // MARK: 属性成员
    /// 是否加载过success页面（防止第一次拉数据缓存成功网络失败）
    private var pageDidRenderSuccess = false
    /// 标记是否正在进行主页数据的网络请求，需要做频率控制预防请求太多
    private var isMainPageDataRequesting = false
    /// 是否完成首次数据请求
    internal var finishFirstDataRequest = false
    /// 是否在显示安装引导
    var isDisplayingInstallGuide = false
    /// 是否在请求中
    var isFetchingOnboardingApps = false

    /// 操作菜单展示管理器
    lazy var actMenuShowManager: ActionMenuManager = {
        ActionMenuManager()
    }()
    /// 是否展示naviBar
    var isShowNaviBar: Bool = true
    /// 运营活动入口button
    var operationButton: UIButton?
    /// 是否能隐藏运营气泡
    var isCanHiddenBubble: Bool = false
    /// 运营活动气泡
    var operationBubbleView: WorkPlaceBubbleView?
    /// 分类筛选页面VC
    private weak var categoryPageViewController: AppCenterHomeCategroyViewController?
    /// 触发分类筛选的按钮
    private weak var triggerCategoryButton: UIButton?
    /// 获取不到tabBar时的默认height
    private let defaultTabBarHeight: CGFloat = 63
    /// widget view Cache
    private let widgetViewCache: NSCache<NSString, UIView> = NSCache<NSString, UIView>()
    /// 工作台首页加载渲染监控
    private let WPHomeRenderMonitor = WPMonitor().timing()
    /// 工作台首页已完成的加载渲染流程计数
    private var renderCount = 0
    /// show Scene , 初始化假设是tab切换
    var dispalyScene: WorkPlaceDisplayScene = .unknown
    /// 中转页面代理
    private(set) weak var rootDelegate: WPHomeRootVCProtocol?

    /// 这个数据结构里面暂时没有数据，为了架构统一也存储在这里
    private let initData: WPHomeVCInitData.Normal

    private var enablePrefetchBlock: Bool {
        return context.configService.fgValue(for: .enablePrefetchBlock)
    }

    /// 是否支持原生工作台预加载
    private var enableNativePrefetch: Bool {
        return context.configService.fgValue(for: .enableNativePrefetch)
    }

    private var prefetchBlockData: [String: WPBlockPrefetchData]?

    private let pageDisplayStateService: WPHomePageDisplayStateService
    let openService: WorkplaceOpenService
    let dependency: WPDependency
    let badgeService: WorkplaceBadgeService

    // MARK: - OperationDialogHostProtocol 运营弹窗
    var onShow = false
    let dialogMgr: OperationDialogMgr

    /// 用于统计 Block 曝光情况，key: item id，value: 上次停留时，是否曝光
    var blockExposeState: [String: Bool] = [:]
    
    let quickLaunchService: QuickLaunchService
    
    let newGuideService: NewGuideService
    
    /// 首屏数据是否请求完成
    /// 用于功能前置需求角标引导，需要等首屏数据请求完成才开始引导流程
    var firstDataRequestFinishRelay: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    
    /// 首屏数据是否请求完成
    /// 用于功能前置需求角标引导，需要等运营弹窗结果，如果没有运营弹窗才开始引导流程
    var needShowOperationRelay: BehaviorRelay<Bool?> = BehaviorRelay<Bool?>(value: nil)

    deinit {
        removeDataUpdateNoti()
        Self.logger.debug("[wp] deinit: \(type(of: self))")
    }
    // MARK: WorkPlace-VC初始化
    init(
        context: WorkplaceContext,
        blockDataService: WPBlockDataService,
        dataManager: AppCenterDataManager,
        rootDelegate: WPHomeRootVCProtocol,
        initData: WPHomeVCInitData.Normal,
        pageDisplayStateService: WPHomePageDisplayStateService,
        openService: WorkplaceOpenService,
        widgetData: WidgetDataManage,
        dependency: WPDependency,
        badgeService: WorkplaceBadgeService,
        dialogMgr: OperationDialogMgr,
        quickLaunchService: QuickLaunchService,
        newGuideService: NewGuideService
    ) {
        self.context = context
        self.blockDataService = blockDataService
        self.dataManager = dataManager
        self.rootDelegate = rootDelegate
        self.initData = initData
        self.pageDisplayStateService = pageDisplayStateService
        self.openService = openService
        self.widgetData = widgetData
        self.dependency = dependency
        self.badgeService = badgeService
        self.dialogMgr = dialogMgr
        self.quickLaunchService = quickLaunchService
        self.newGuideService = newGuideService
        super.init(nibName: nil, bundle: nil)
        metrics.initMemory = WPUtils.appMemory
        registerDataUpdateNoti()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        // 模版工作台是否支持预加载Block也是用enablePrefetchBlock这个fg
        // 且BlockDataService保存的Block数据不会随门户销毁而销毁
        // 因此为了防止原生工作台预加载fg关闭的情况下，有其他门户的相同block的数据，要再加enableNativePrefetch判断
        if enablePrefetchBlock, enableNativePrefetch {
            prefetchBlockData = blockDataService.getPrefetchData()
        }
        firstDataProduce()
        settingProduce()
        /// 原来调用的是 operationProduce(isFirst: true)
        /// 「工作台管理功能前置需求」需要把installApps一键安装弹窗去掉，只保留活动运营弹窗
        wp_operationDialogProduce { [weak self] needShow in
            Self.logger.info("get operation dialog produce result", additionalData: [
                "needShow" : "\(needShow)"
            ])
            self?.needShowOperationRelay.accept(needShow)
        }
        addWPNotification()
        observeAuxiliarySceneActive()
        if #available(iOS 13.4, *) {
            setupDragInteraction()
            setupDropInteraction()
        }
        subscribeForSortGuide()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        onShow = true
        handlingPageVisiblityChangesForBlock(pageVisible: true)
		notifyBlockViewVCAppear(true)
        metrics.finishRenderMemory = WPUtils.appMemory
        widgetRefreshBizData()
        checkTopViewController()

        rootDelegate?.tracker.trackPageExpose(
            .normal(initData),
            templatePortalCount: rootDelegate?.templatePortalCount ?? 0
        )
        pageDisplayStateService.notifyPageAppear()

        // Block 产品埋点曝光（工作台不可见 -> 可见）
        if let viewModel = workPlaceUIModel {
            resetExposeBlockMap(with: viewModel)
            reportBlockExpose(collectionView: workPlaceCollectionView)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onShow = false
    }

    override func viewDidDisappear(_ animated: Bool) {
        removeBubble()    // 移除运营气泡
        operationButton = nil // 置空持有运营气泡的锚点view引用
        super.viewDidDisappear(animated)
        handlingPageVisiblityChangesForBlock(pageVisible: false)
		notifyBlockViewVCAppear(false)

        reportPageStayDurationIfNeeded()
        pageDisplayStateService.notifyPageDisappear()
    }

    // 适配iPad分/转屏，collectionview需要刷新布局（仅刷新布局的地方不要用reloadData）
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        actMenuShowManager.isNeedRefreshMenuView = false   // 如果只是分转屏，C R视图模式没有改变，则触发 traitCollectionDidChange 无需

        ///  找到正在展示的actionMenu气泡，暂存位置信息，以备完成转屏后恢复
        var targetPath: IndexPath?
        var targetItemId: String?
        if actMenuShowManager.showMenuPopOver != nil {
            targetPath = actMenuShowManager.targetPath
            targetItemId = actMenuShowManager.targetItemId
            dismissActionMenu()
        }
        
        /// 如果在展示「应用排序和角标展示」引导，分屏/转屏后把引导关掉
        closeBadgeSortGuideIfNeeded()

        // 看一下是否有分类筛选页面要关闭
        let isCategoryClosed = tryCloseCategoryPage(animated: false)
        // 执行分/转屏
        coordinator.animate(alongsideTransition: nil, completion: { [weak self](_) in
            guard let `self` = self else { return }
            self.workPlaceCollectionView.collectionViewLayout.invalidateLayout()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                if let indexPath = targetPath { //  恢复长按菜单
                    self.reappearActionMenu(originIndexPath: indexPath, itemId: targetItemId)
                }
                // 恢复关闭的筛选页面
                if isCategoryClosed, let targetButton = self.triggerCategoryButton {
                    self.didSelectCategoryButton(sender: targetButton)
                }
            })
        })
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        refreshMenuOnTraitCollectionDidChange()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // workPlaceCollectionView 宽度变化时，计算列表视图布局，重新加载
        // 原实现在 viewWillTransition 中
        // 修复 ios16 & iphone mini 屏幕旋转时，viewWillTransition to size 存在负值的情况
        // 将 workPlaceUIModel 数据刷新移到该处
        let collectionViewWidth = self.workPlaceCollectionView.bounds.width
        if let needRefresh = self.workPlaceUIModel?.refreshDisplayIfNeeded(with: collectionViewWidth), needRefresh {
            Self.logger.info("WorkPlace's width changed, display views need refresh")
            self.workPlaceCollectionView.reloadData()
        }
    }

    override func onPageWillResignActive() {
        super.onPageWillResignActive()

        guard isAppeared else {
            return
        }

        removeBubble()

        handlingPageVisiblityChangesForBlock(pageVisible: false)

        reportPageStayDurationIfNeeded()
    }

    override func onPageDidBecomeActive() {
        super.onPageDidBecomeActive()

        guard isAppeared else {
            return
        }

        self.handlingPageVisiblityChangesForBlock(pageVisible: true)
        rootDelegate?.tracker.trackPageExpose(
            .normal(initData),
            templatePortalCount: rootDelegate?.templatePortalCount ?? 0
        )
        // Block 产品埋点曝光（工作台不可见 -> 可见）
        // 原生工作台我的常用组件曝光不上报
        resetExposeBlockMap(with: workPlaceUIModel)
        reportBlockExpose(collectionView: workPlaceCollectionView)
    }

    /// 保证了长按菜单变成C视图时不会变成Modal
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    @objc
    func popoverPresentationControllerDidDismissPopover(
        _ popoverPresentationController: UIPopoverPresentationController
    ) {
        if actMenuShowManager.showMenuPopOver != nil {
            Self.logger.info("action menu popOver dismiss")
            dismissActionMenu()
        }
    }

    /// 判断当前VC是否展示在最顶层
    private func checkTopViewController() {
        if OPNavigatorHelper.topMostVC(window: view.window) != self {
            Self.logger.warn("the current topVC isn't workplace VC!")
            OPMonitor(EPMClientOpenPlatformAppCenterWorkplaceCode.workplace_home_page_not_display)
                .setResultTypeFail().flush()
        }
    }
// }
//
// MARK: Widget Refresh
// extension WorkPlaceViewController {
    /// 从其他入口返回的时候，需要刷新数据
    private func needRefreshWidget() -> Bool {
        if dispalyScene == .switchTab {
            return false
        }
        return true
    }
    /// 当前显示的所有widgetView
    private func displayingWidgetViews() -> [WidgetView] {
        var result: [WidgetView] = []
        for cell in workPlaceCollectionView.visibleCells {
            if let widget = (cell as? WorkPlaceWidgetCell)?.widgetView {
                result.append(widget)
            }
        }
        return result
    }
    /// 刷新widget数据
    private func widgetRefreshBizData() {
        defer {
            dispalyScene = .unknown
        }
        if needRefreshWidget() {
            for widget in displayingWidgetViews() {
                Self.logger.info("\(widget.widgetModel.name) refresh biz data from unknown scene")
                widget.updateWidgetBizData()
            }
        }
    }

// }
//
// MARK: 工作台附加操作
// extension WorkPlaceViewController {
    /// 处理用户的touch事件，移除bubble展示
    func handleTouchToRemoveBubble() {
        if isCanHiddenBubble {
            removeBubble()
        }
    }

    override func keyBindings() -> [KeyBindingWraper] { // ⚠️ 注意验证，加了中转页面是否影响
        super.keyBindings() + searchKeyCommand()
    }

    /// 支持iPad快捷键搜索
    func searchKeyCommand() -> [KeyBindingWraper] {
        return [
            KeyCommandBaseInfo(
                input: "k",
                modifierFlags: .command,
                discoverabilityTitle: BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_IpadShortCutSearch
            ).binding(
                target: self,
                selector: #selector(ocEnterSearch)
            ).wraper
        ]
    }

    @objc
    private func ocEnterSearch() {
        self.enterSearch()
    }

// }
//
// MARK: setup view 视图相关
// extension WorkPlaceViewController {
    /// 初始化widget版应用中心主页，添加View布局
    private func setupView() {
        Self.logger.info("WorkPlaceVC setup views, hurry up!")
        // VC基本配置(把页面扩展到屏幕底部避免拖动删除cell闪烁)
        modalPresentationStyle = .custom
        view.backgroundColor = UIColor.ud.bgBody
        edgesForExtendedLayout = .bottom
        extendedLayoutIncludesOpaqueBars = true
        // 列表视图添加
        view.addSubview(workPlaceCollectionView)
        setConstraint()
    }
    /// 初始化布局约束
    private func setConstraint() {
        /// 主端搞了个强行遮住的导航栏，应用中心需要隐藏系统导航，然后collectionView下移状态栏+假导航的高度
        var bottomInset: CGFloat = animatedTabBarController?.tabbarHeight ?? defaultTabBarHeight
        bottomInset = (Display.pad ? 0 : bottomInset) + 16
        workPlaceCollectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
        workPlaceCollectionView.snp.makeConstraints { (make) in
            collectionViewTopConstraint = make.top.equalToSuperview().constraint
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    /// 展示空态页
    private func showEmptyView() {
        workPlaceCollectionView.isHidden = true
        stateView.state = .noApp(WPPageStateView.State.Param.NoApp(action: { [weak self] in
            self?.openAddApp()
        }))
    }
// }
//
// MARK: dataProduce 数据生成
// extension WorkPlaceViewController {
    /// 首次进入页面加载数据调用 retry也需要调用此方法 会显示Loading页面 会显示retry
    private func firstDataProduce(isRetry: Bool = false) {
        Self.logger.info("WorkPlaceVC first fetch data, come on!")
        stateView.state = .loading
        /// hasCache 表示是否有缓存，用于在埋点区分有缓存但是失败的情况
        let hasCache = dataManager.checkHasCache()
        let start = Date().timeIntervalSince1970
        let successMonitor = context.monitor
            .start(.workplace_home_render_success)
            .timing()
        let failedMonitor = context.monitor
            .start(.workplace_home_render_fail)
            .timing()
        /// 拉取数据，若成功则隐藏loading并且展示数据，失败则显示重试页面
        dataManager.fetchItemInfoWith(success: { [weak self] (model, isFromCache) in
            Self.logger.info("fetch home page data finished", additionalData: [
                "isFromCache": "\(isFromCache)",
                "hasSelf": "\(self != nil)"
            ])
            guard let `self` = self else { return }
            self.stateView.state = .hidden
            self.dataProduceSuccessAction(isFirst: true, dataModel: model, fromCache: isFromCache)
            self.finishFirstDataRequest = true
            self.firstDataRequestFinishRelay.accept(true)

            let end = Date().timeIntervalSince1970
            self.metrics.finishRenderTime = Date()
            self.context.tracker
                .start(.appcenter_rendering)
                .setValue("yes", for: .is_success)
                .post()
            successMonitor
                .setPortalRenderType(isRetry ? .error_retry : .cold_boot)
                .setValue(isFromCache ? 1 : 0, for: .use_cache)
                .setValue(hasCache, for: .has_cache)
                .setResultTypeSuccess()
                .timing()
                .setValue((end - start) * 1000, for: .renderEnd) // 本质上是 duration，目前数据链路上有依赖，暂时保留
                .flush()
        }, failure: { [weak self] (error) in
            guard let `self` = self else { return }
            self.firstDataRequestFinishRelay.accept(true)
            /// 首次进入应用中心数据失败是需要显示重试页面的，但是缓存成功就不用进入重试页面了
            if self.pageDidRenderSuccess {
                self.stateView.state = .hidden
                return
            }
            
            Self.logger.error("fetch home page data failed", additionalData: [
                "pageDidRenderSuccess": "\(self.pageDidRenderSuccess)"
            ],error: error)
            let end = Date().timeIntervalSince1970
            self.finishFirstDataRequest = true
            
            self.metrics.finishRenderTime = Date()
            self.context.tracker
                .start(.appcenter_rendering)
                .setValue("no", for: .is_success)
                .post()
            failedMonitor
                .setPortalRenderType(isRetry ? .error_retry : .cold_boot)
                .setError(error)
                .setValue(hasCache, for: .has_cache)
                .setResultTypeFail()
                .timing()
                .setValue((end - start) * 1000, for: .renderEnd) // 本质上是 duration，目前数据链路上有依赖，暂时保留
                .flush()

            self.workPlaceCollectionView.isHidden = true
            self.stateView.state = .loadFail(.create { [weak self] in
                /// 刷新数据（由于没有数据才可能触发error页面，所以重试时只当做first请求）
                self?.firstDataProduce(isRetry: true)
            })
        })
    }
    /// 数据拉取成功，生成UIModel，刷新View
    /// - Parameters:
    ///   - isFirst: 是否是首次应用中心或者retry的拉取
    ///   - model: 数据模型
    private func dataProduceSuccessAction(
        isFirst: Bool,
        dataModel: WorkPlaceDataModel,
        fromCache: Bool
    ) {
        Self.logger.info("data produce success action", additionalData: [
            "isFirst": "\(isFirst)",
            "fromCache": "\(fromCache)",
            "dataModel.allItemInfos.count": "\(dataModel.allItemInfos.count)"
        ])
        if dataModel.allItemInfos.isEmpty {
            showEmptyView()
            return
        }
        /// data加载成功，显示collecitonView，隐藏重试页面，空态页
        workPlaceCollectionView.isHidden = false
        stateView.state = .hidden
        /// 将DataModel转化为UIModel，注入VC，刷新View
        let oldUIModel = workPlaceUIModel
        workPlaceUIModel = WorkPlaceViewModel(
            dataModel: dataModel,
            containerWidth: view.bdp_width,
            dataManager: dataManager
        )
        /// 从旧的数据model同步数据
        workPlaceUIModel?.syncDataFrom(oldModel: oldUIModel)

        workPlaceUIModel?.dataUpdateCallback = { [weak self, weak workPlaceCollectionView] sections in
            UIView.performWithoutAnimation {
                self?.workPlaceCollectionView.performBatchUpdates({
                    self?.workPlaceCollectionView.reloadSections(IndexSet(sections))
                }, completion: { completed in
                    Self.logger.error("workPlaceCollectionView reload data failed: \(completed)")
                    self?.actMenuShowManager.isUILocalChanging = false
                    if let workPlaceCollectionView = workPlaceCollectionView {
                        self?.reportBlockExpose(collectionView: workPlaceCollectionView)
                    }
                })
            }
        }
        workPlaceCollectionView.reloadData() // 触发View重新加载数据
        rootDelegate?.reportFirstScreenDataReadyIfNeeded()

        // 工作台门户内容首次成功加载，上报 Block 曝光埋点
        if !pageDidRenderSuccess, onShow {
            resetExposeBlockMap(with: workPlaceUIModel)
            workPlaceCollectionView.performBatchUpdates(nil) { [weak self]_ in
                guard let `self` = self else { return }
                self.reportBlockExpose(collectionView: self.workPlaceCollectionView)
            }
        }

        // 记录页面被加载成功过
        if isFirst {
            Self.logger.info("first fetch data success")
            pageDidRenderSuccess = true
        }
    }

    /// 添加通知监听
    func addWPNotification() {
        pushRefresh()
    }

    private func handlingPageVisiblityChangesForBlock(pageVisible: Bool) {
        if pageVisible {
            for cell in workPlaceCollectionView.visibleCells {
                if let blockCell = cell as? BlockCell {
                    blockCell.visible = true
                }
            }
        } else {
            for cell in workPlaceCollectionView.visibleCells {
                if let blockCell = cell as? BlockCell {
                    blockCell.visible = false
                }
            }
        }
    }

	private func notifyBlockViewVCAppear(_ appear: Bool) {
        let appearName = WorkplaceViewControllerNotifiction.vcDidAppear.name
        let disappear = WorkplaceViewControllerNotifiction.vcDidDisappear.name
		let name = appear ? appearName : disappear
		NotificationCenter.default.post(name: name, object: nil)
	}

    /// 后台支持刷新应用中心
    private func pushRefresh() {
        context.userPushCenter
            .observable(for: WorkplacePushMessage.self)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self]message in
                /// 数据处理
                guard let ts = Double(message.timestamp),
                      let refreshTs = self?.workPlaceUIModel?.timestamp
                else {
                    return
                }
                let pushDate = Date(timeIntervalSince1970: ts)
                let requestDate = Date(timeIntervalSince1970: Double(refreshTs))
                guard pushDate > requestDate else {
                    return
                }
                Self.logger.info("Workplace: recieve push and call dataProduce")
                /// 刷新UI
                self?.dataProduce()
            }).disposed(by: disposeBag)
    }

    /// 非首次拉取数据且非重试 使用此方法拉取数据（点击tab会触发，二级页面有数据更新时触发）,不会触发error页面
    @objc
    func dataProduce() {
        Self.logger.info("process data produce", additionalData: [
            "isMainPageDataRequesting": "\(isMainPageDataRequesting)"
        ])
        /// 不支持多个请求同时进行
        if isMainPageDataRequesting {
            return
        }
        /// 异步拉取数据，成功进行刷新
        isMainPageDataRequesting = true
        /// 异步请求的回调
        dataManager.fetchItemInfoWith(needCache: false, success: { [weak self](model, isFromCache) in
            self?.isMainPageDataRequesting = false
            self?.dataProduceSuccessAction(isFirst: false, dataModel: model, fromCache: isFromCache)
        }, failure: { [weak self](error) in
            Self.logger.error("aysnc fetch data failed", error: error)
            self?.isMainPageDataRequesting = false
        })
    }

    /// 生成工作台运营信息
    /// - Parameter isFirst: 是否是第一次进入
    /// 「工作台管理功能前置需求」需要把installApps一键安装弹窗去掉，只保留活动运营弹窗
    /// 技术评审时确定先保留方法实现，把调用的地方去掉
    func operationProduce(isFirst: Bool) {
        // onBoarding流程（首次进入工作台，拉取onBoardingKey，并强制上报消除该Key；
        // 非首次进入，则该Key必定为false）
        Self.logger.info("operation produce", additionalData: ["isFrist": "\(isFirst)"])
        var isNewUser: Bool = false
        if isFirst {
            let key = WorkPlaceViewController.remoteGuideKey
            isNewUser = dependency.guide.shouldShow(key: key)
            dependency.guide.finishShow(key: key)
        }
        // 请求运营配置
        // swiftlint:disable closure_body_length
        dataManager.fetchOperationConfig(isOnboarding: isNewUser, success: { [weak self](model) in
            Self.logger.info("fetch operation config success", additionalData: [
                "isConfigEmpty": "\(model.isConfigEmpty())"
            ])
            self?.workPlaceOperationModel = model
            if model.isConfigEmpty() {
                self?.closeOperation()
                self?.wp_operationDialogProduce { [weak self] needShow in
                    Self.logger.info("get operation dialog produce result", additionalData: [
                        "needShow" : "\(needShow)"
                    ])
                    self?.needShowOperationRelay.accept(needShow)
                }
                return
            }
            // 新用户首次onBoarding，推荐应用有数据,且后端允许，就展示一键安装列表
            // Ref doc: https://bytedance.feishu.cn/docx/N6iXdePmpo2X5dxmgVGcxIMbnQe?chatTab=1&useIframe=1&multiPage=1
            if isNewUser,
               let apps = model.operationalApps,
               !apps.isEmpty, model.onboardingPopUp ?? false,
               !BoxSetting.isBoxOff() {
                let displayApps = apps.map({ $0.appId })
                self?.context.tracker
                    .start(.appcenter_onboardinginstall_exposure)
                    .setValue(displayApps, for: .appids)
                    .post()

                self?.displayInstallGuide(
                    apps: apps,
                    isAdmin: model.isAdmin ?? false,
                    isFromOperation: false,
                    completion: {
                        self?.wp_operationDialogProduce { [weak self] needShow in
                            Self.logger.info("get operation dialog produce result", additionalData: [
                                "needShow" : "\(needShow)"
                            ])
                            self?.needShowOperationRelay.accept(needShow)
                        }
                    })
            } else {
                /// 原来调用的是self?.reloadNaviBarWithOperation()
                /// 「工作台管理功能前置需求」需要主导航小灯泡按钮去掉
                /// 因此直接调用rootReloadNaviBar()方法，不展示指向小灯泡的气泡
                self?.rootDelegate?.rootReloadNaviBar()
                self?.wp_operationDialogProduce { [weak self] needShow in
                    Self.logger.info("get operation dialog produce result", additionalData: [
                        "needShow" : "\(needShow)"
                    ])
                    self?.needShowOperationRelay.accept(needShow)
                }
            }
        }, failure: { (error) in
            Self.logger.error("fetch operation config failde", error: error)
            self.wp_operationDialogProduce { [weak self] needShow in
                Self.logger.info("get operation dialog produce result", additionalData: [
                    "needShow" : "\(needShow)"
                ])
                self?.needShowOperationRelay.accept(needShow)
            }
        })
        // swiftlint:enable closure_body_length
    }

    /// 生成工作台配置信息
    func settingProduce() {
        dataManager.fetchWorkPlaceSettingWith(success: { [weak self](model) in
            Self.logger.info("setting produce success")
            self?.workPlaceSettingModel = model
            /// 配置拉取成功，刷新NaviBar
            /// 原来调用的是self?.reloadNaviBarWithOperation()
            /// 「工作台管理功能前置需求」需要主导航小灯泡按钮去掉
            /// 因此直接调用rootReloadNaviBar()方法，不展示指向小灯泡的气泡
            self?.rootDelegate?.rootReloadNaviBar()
        }, failure: { error in
            Self.logger.error("setting produce failed", error: error)
        })
    }

    /// 刷新NaviBar和运营配置
    func reloadNaviBarWithOperation() {
        DispatchQueue.main.async {
            Self.logger.info("reload naviBar via rootDelegate")
            self.rootDelegate?.rootReloadNaviBar()
        }
        
        if let model = workPlaceOperationModel, let bubblePop = model.bubblePopup, bubblePop {
            Self.logger.info("reload NaviBar With Operation")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                self.displayBubble()    // 需要延迟执行，不然reloadNaviBar还没有完成，导致button位置没有更新
            })
        }
    }

    /// 展示气泡（注意：需要先判断是否需要展示气泡）
    func displayBubble() {
        Self.logger.info("display operation bubble view")
        /// 清空之前的气泡
        removeBubble()
        /// 获取气泡文案
        guard let text = getBubbleText() else {
            Self.logger.error("bubbule's text missed, not display")
            return
        }
        /// 做新的气泡
        guard let targetView = self.operationButton,
              let window = animatedTabBarController?.view else {
            Self.logger.error("bubbule's depencyView missed, not display")
            return
        }
        let targetRect = targetView.convert(targetView.bounds, to: window)
        let safeInsetY: CGFloat = 8 // 气泡指向目标的安全距离
        let anchorPoint: CGPoint = CGPoint(x: targetRect.centerX, y: targetRect.bottom + safeInsetY)
        let bubbleView = WorkPlaceBubbleView(anchorPoint: anchorPoint, text: text, windowMaxWidth: window.bdp_width)
        window.addSubview(bubbleView)
        window.bringSubviewToFront(bubbleView)
        operationBubbleView = bubbleView
        /// 展示5s延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
            Self.logger.info("isCanHiddenBubble is true")
            self.isCanHiddenBubble = true
        })
    }

    /// 获取气泡要展示的文案
    func getBubbleText() -> String? {
        guard let model = workPlaceOperationModel, let type = model.getoOperationalType() else {
            Self.logger.error("operation model missed, no bubble text")
            return nil
        }
        switch type {
        case .operationalActivity:
            if let activity = model.operationalActivity, let text = activity.name {
                return text
            }
        case .operationalApps:
            if let apps = model.operationalApps, !apps.isEmpty {
                let isAdmin = model.isAdmin ?? false
                return isAdmin ? BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_OnboardingAdminTtle :
                    BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_OnboardingUserTtl
            }
        case .none:
            break
        }
        Self.logger.error("operation config \(type) required params missed, no bubble text")
        return nil
    }

    /// 隐藏气泡
    @objc
    func removeBubble() {
        if let bubbleView = operationBubbleView {
            Self.logger.debug("clear before bubble view")
            if bubbleView.superview != nil {
                bubbleView.removeFromSuperview()
            }
            operationBubbleView = nil
        }
    }

    // MARK: UICollectionView-Delegate

    /// 主页item选中处理
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true) // cell反选，实现点击效果
        guard let sectionModel = workPlaceUIModel?.sectionsList[indexPath.section],
            let itemModel = sectionModel.getItemAtIndex(index: indexPath.item) else {
                Self.logger.error("ItemModel exception at \(indexPath)")
                return
        }
        switch itemModel.itemType {
        case .addIcon, .addRect:    // 点击「添加应用」
            Self.logger.info("user tap addIcon to add common App page")
            openAddApp()
        case .icon:                 // 点击应用
            Self.logger.info("user tap icon at \(indexPath) to open App")
            openAppAndReportEvent(with: itemModel, sectionType: sectionModel.type)
            /// 新应用清除标记（判断是真的新应用，获取subTag[后端需要]，获取cell[消除蓝点]）
            if let appItem = itemModel as? ItemModel,
               isRealNewApp(itemId: appItem.itemID, indexPath: indexPath, isRemoteNew: appItem.isNewApp()),
               let cell = collectionView.cellForItem(at: indexPath) as? WorkPlaceIconCell {
                onNewAppTap(cell: cell, itemId: appItem.itemID)
            }
        case .widget:               // 点击widget
            Self.logger.info("user tap widget at \(indexPath)")
            return
        case .block:
            Self.logger.info("user tap block at \(indexPath)")
            return
        case .verticalSpace, .fillItem, .stateItem:
            return
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard let blockCell = cell as? BlockCell else { return }
        blockCell.visible = true
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt forItemAtindexPath: IndexPath
    ) {
        guard let blockCell = cell as? BlockCell else { return }
        blockCell.visible = false
    }

    /// 新应用点击处理
    private func onNewAppTap(cell: WorkPlaceIconCell, itemId: String) {
        cell.cleanNewAppFlag()
        localCleanNewItemIds.append(itemId)
        /// 返送清除标记的请求
        dataManager.postCleanNewApp(itemId: itemId, success: {
            Self.logger.info("clean new app flag \(itemId)")
        }, failure: { (error) in
            Self.logger.error("clean new app flag \(itemId) failed", error: error)
        })
    }

    // MARK: UICollectionView-DataSource
    /// 根据UIModel获取section数量（缺省值：0）
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        let sectionNum = workPlaceUIModel?.getSectionsCount() ?? 0
        Self.logger.info("collectionView's section num is \(sectionNum)")
        return sectionNum
    }

    /// 每个section的item数量（缺省值：0）
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let sectionModel = workPlaceUIModel?.getSectionModel(index: section) else {
            Self.logger.error("get sectionModel at section-\(section) failed on getNumofSection")
            return 0
        }
        return sectionModel.getDisplayItemCount()
    }

    // swiftlint:disable function_body_length
    /// 获取指定位置的cell视图
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        /// model检查，获取相应位置的itemModel
        guard let model = workPlaceUIModel, let sectionModel = model.getSectionModel(index: indexPath.section),
            let itemModel = sectionModel.getItemAtIndex(index: indexPath.row) else {
               Self.logger.error("getUIModel for cell at section-\(indexPath.section) failed")
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: workPlaceCollectionView.stateCellReuseID,
                for: indexPath
            )
        }
        let primaryTag = sectionModel.tag.id  // app 所属一级分类名
        let secondaryTag = sectionModel.allAppsData?.currentTag.tagName ?? "" // app 所属二级分类名
        switch itemModel.itemType {
        case ItemType.widget:                    // widget类型
            // 获取widget实例
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: workPlaceCollectionView.widgetCellID,
                for: indexPath
            )
            guard let widgetCell = cell as? WorkPlaceWidgetCell else {
                return cell
            }
            // 刷新widget
            if let widgetModel = itemModel.getWidgetModel(), let itemId = itemModel.getItemId() {
                widgetCell.badgeKey = itemModel.badgeKey()
                /// 恢复上一次遗存的容器状态信息
                if let lastContainerState = model.queryAdditionItem(itemId: itemId)?.widgetContainerState {
                    widgetModel.widgetContainerState = lastContainerState
                } else {
                    /// 保存唯一份 widgetContainerState
                    let itemAdditionInfo = ItemModelAdditionInfo(itemId: itemId)
                    itemAdditionInfo.widgetContainerState = widgetModel.widgetContainerState
                    model.updateAdditionItem(itemId: itemId, item: itemAdditionInfo)
                }
                /// ❓要么在refresh的时候带上展开状态update，要么就把update之后的widgetView传过来复用❓
                widgetModel.cardSizeDidChange = { [weak self] (_, state, size) in
                    guard let self = self else { return }
                    /// 记录尺寸变化，更新状态
                    state.expandSize = size
                    /// 刷新列表，重新计算widget的高度
                    // collectionView?.reloadItems(at: [indexPath])
                    self.workPlaceCollectionView.performBatchUpdates({
                            self.workPlaceCollectionView.reloadItems(at: [indexPath])
                        },
                        completion: { [weak self] _ in
                            // cell-widget刷新后，展示长按菜单
                            if let indexPath = self?.needShowMenuIndex,
                               let widgetCell = self?.workPlaceCollectionView
                                .cellForItem(at: indexPath) as? WorkPlaceWidgetCell,
                               let itemModel = self?.workPlaceUIModel?.getSectionModel(index: indexPath.section)?
                                .getItemAtIndex(index: indexPath.row) as? ItemModel {
                                let isCommon = self?.workPlaceUIModel?.isCommonItem(itemId: itemId) ?? false
                                self?.handleWidgetLongPress(
                                    cell: widgetCell,
                                    path: indexPath,
                                    itemInfo: itemModel,
                                    isCommon: isCommon
                                )
                                self?.needShowMenuIndex = nil
                            }
                        }
                    )
                }
                widgetCell.refresh(
                    userId: context.userId,
                    widgetModel: widgetModel,
                    widgetDataManage: widgetData,
                    widgetViewCache: widgetViewCache
                )
                /// 设置widget的长按事件
                widgetCell.longPressAction = { [weak self] (wc) in
                    /// 收起展开的widget之后才展示长按菜单
                    if self?.workPlaceUIModel?.queryAdditionItem(itemId: itemId)?
                        .widgetContainerState?.isExpand ?? false {
                        self?.needShowMenuIndex = indexPath
                        wc.expandButtonClick()
                    } else {
                        let isCommon = self?.workPlaceUIModel?.isCommonItem(itemId: itemId) ?? false
                        if let item = itemModel as? ItemModel {
                            self?.handleWidgetLongPress(
                                cell: wc,
                                path: indexPath,
                                itemInfo: item,
                                isCommon: isCommon
                            )
                        }
                    }
                }
                /// widget header 点击响应
                widgetCell.setHeaderClick { [weak self] (link) in
                    guard let self = self else { return }
                    if let url = link {
                        Self.logger.info("open link \(url)")
                        self.openService.openAppLink(url, from: self)
                    } else if let app = itemModel.getSingleAppInfo() {
                        Self.logger.info("open item \(app.name)")
                        self.openAppAndReportEvent(with: itemModel, sectionType: sectionModel.type)
                    } else {
                        Self.logger.info(
                            "open widget header nothing \(itemModel.getWidgetModel()?.name ?? "")"
                        )
                    }
                }
                /// widget展示的埋点上报
                widgetCell.widgetDisplayReport = { [weak self] in
                    self?.context.tracker
                        .start(.appcenter_widgetopen)
                        .setValue(itemId, for: .item_id)
                        .post()
                }
            }
            return widgetCell
        case ItemType.block:
            guard let blockModel = itemModel.getBlockModel() else {
                assertionFailure("block data missing")
                return collectionView.dequeueReusableCell(
                    withReuseIdentifier: workPlaceCollectionView.unknownCellID,
                    for: indexPath
                )
            }
            let cellId = blockModel.uniqueId.fullString
            collectionView.register(BlockCell.self, forCellWithReuseIdentifier: cellId)
            guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: cellId,
                    for: indexPath
            ) as? BlockCell else {
                assertionFailure("cell type error")
                return collectionView.dequeueReusableCell(
                    withReuseIdentifier: workPlaceCollectionView.unknownCellID,
                    for: indexPath
                )
            }
            cell.delegate = self
            cell.updateData(
                blockModel,
                hostVCShow: onShow,
                trace: context.trace,
                prefetchData: prefetchBlockData?[blockModel.blockId],
                userResolver: context.userResolver
            )
            return cell
        case ItemType.icon, ItemType.addIcon:    // icon应用
            // 获取icon实例
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: workPlaceCollectionView.gadgetCellID,
                for: indexPath
            )
            /// 防止数组越界，判断是否展示推荐，获取iconUrl
            guard let gadget = cell as? WorkPlaceIconCell,
                let section = workPlaceUIModel?.getSectionModel(index: indexPath.section),
                indexPath.item < section.getDisplayItemCount(),
                let item = section.getItemAtIndex(index: indexPath.row) as? ItemModel else {
                    return cell
            }
            /// 刷新icon（当应用不在本地清除新应用标记list中时，即该应用还没有在本地被点击，isLocalNew: true）
            gadget.refreshCell(
                with: item,
                isNewApp: isRealNewApp(itemId: item.itemID, indexPath: indexPath, isRemoteNew: item.isNewApp()),
                fromTemplate: false,
                isEditing: false,
                badgeService: badgeService,
                configService: context.configService,
                userResolver: context.userResolver,
                sectionType: sectionModel.type,
                primaryTag: primaryTag,
                secondaryTag: secondaryTag,
                block: { [weak self](itemCell, _) in
                    // swiftlint:disable empty_enum_arguments
                    if !item.isAddApp() {
                        // swiftlint:enable empty_enum_arguments
                        self?.handleIconLongPress(cell: itemCell, itemInfo: item, indexPath: indexPath)
                    } else {
                        Self.logger.warn("long press on add item, menu not display")
                    }
                }
            )
            return gadget
        case ItemType.addRect:
            // 方形「添加应用」
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: workPlaceCollectionView.addGadgetCellID,
                for: indexPath
            )
        case .verticalSpace:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: workPlaceCollectionView.spaceCellReuseID,
                for: indexPath
            )
            return cell
        case .fillItem:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: workPlaceCollectionView.fillCellReuseID,
                for: indexPath
            )
            return cell
        case .stateItem:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: workPlaceCollectionView.stateCellReuseID,
                for: indexPath
            )
            /// 刷新状态
            if let statecell = cell as? ItemStateCell,
                let stateModel = itemModel as? StateItemModel {
                statecell.refreshItemModel(model: stateModel)
                statecell.retryCallback = { [weak self] in
                    /// 重试的时候，重新调用
                    if let subtag = sectionModel.allAppsData?.currentTag {
                        self?.workPlaceUIModel?.didSelect(sectionTag: sectionModel.tag, subTag: subtag)
                    }
                }
            }
            return cell
        }
    }
    // swiftlint:enable function_body_length

    /// 设置section的附加视图（分组title）
    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            return self.headerForCollectionView(collectionView, at: indexPath)
        case UICollectionView.elementKindSectionFooter:
            return self.footerForCollectionView(collectionView, at: indexPath)
        default:
            return UICollectionReusableView(frame: .zero)
        }
    }
    /// 获取对应的header
    private func headerForCollectionView(
        _ collectionView: UICollectionView,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard let uimodel = workPlaceUIModel else {
           Self.logger.error("workPlaceUIModel is nil")
            return UICollectionReusableView(frame: .zero)
        }
        guard let sectionModel = uimodel.getSectionModel(index: indexPath.section) else {
           Self.logger.error("sectionModel is nil, index is \(indexPath)")
            return UICollectionReusableView(frame: .zero)
        }
        switch sectionModel.type {
        case .favorite, .normalSection:
            let headerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: UICollectionView.elementKindSectionHeader,
                withReuseIdentifier: workPlaceCollectionView.gadgetGroupHeaderID,
                for: indexPath
            )
            if let gadgetHeader = headerView as? GadgetGroupHeaderView {
                gadgetHeader.badgeKey = sectionModel.badgeKey()
                gadgetHeader.updateData(
                    groupTitle: sectionModel.sectionName,
                    state: sectionModel.foldState,
                    foldClick: { [weak self] in
                        self?.workPlaceUIModel?.foldStateToggle(sectionIndex: indexPath.section)
                    }
                )
                return gadgetHeader
            }
        case .allAllsSection:
            let headerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: UICollectionView.elementKindSectionHeader,
                withReuseIdentifier: workPlaceCollectionView.allAppCategoryHeaderID,
                for: indexPath
            )
            if let allHeader = headerView as? AppCenterAllAppHeaderView {
                /// 设置全部应用的点击回调
                allHeader.delegate = self
                uimodel.allAppSectionModel = sectionModel as? SectionModel
                if let selectIndexpath = sectionModel.allAppsData?.selectedIndex() {
                    allHeader.selectIndexPath = selectIndexpath
                }
                allHeader.updateHeaderView(with: sectionModel.allAppsData?.nameList() ?? [])
                return allHeader
            }
        }
        return UICollectionReusableView(frame: .zero)
    }
    /// 获取对应的footer
    private func footerForCollectionView(
        _ collectionView: UICollectionView,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        let footer = collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: workPlaceCollectionView.workplaceEmptyFooterID,
            for: indexPath
        )
        guard let uimodel = workPlaceUIModel else {
           Self.logger.error("workPlaceUIModel is nil")
            return footer
        }
        guard let sectionModel = uimodel.getSectionModel(index: indexPath.section) else {
           Self.logger.error("sectionModel is nil, index is \(indexPath)")
            return footer
        }
        var showFooter = BoxSetting.isBoxOff() ? false : sectionModel.hasMoreData()
        (footer as? EmptyFooterView)?.hasMore = showFooter
        return footer
    }
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        let topMargin: CGFloat
        if section == 0 {
            topMargin = 0
        } else {
            topMargin = 11
        }
        let defaultInsets = UIEdgeInsets(
            top: topMargin,
            left: ItemModel.horizontalCellMargin,
            bottom: 0,
            right: ItemModel.horizontalCellMargin
        )
        guard let sectionModel = workPlaceUIModel?.getSectionModel(index: section) else {
            return defaultInsets
        }
        switch sectionModel.type {
        case .allAllsSection:
            return UIEdgeInsets(
                top: 19,
                left: ItemModel.horizontalCellMargin,
                bottom: 0,
                right: ItemModel.horizontalCellMargin
            )
        case .favorite, .normalSection:
            return defaultInsets
        }
    }
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        guard let sectionModel = workPlaceUIModel?.getSectionModel(index: indexPath.section),
            let itemModel = sectionModel.getItemAtIndex(index: indexPath.row) else {
               Self.logger.error("getUIModel for cell at section-\(indexPath.section) failed")
            return true
        }
        /// 状态的cell不能够选中，否则样式会出现问题
        if itemModel.itemType == .stateItem {
            return false
        }
        return true
    }
    /// 运营位关闭事件（业务逻辑：分为「关闭运营气泡」和「关闭运营入口」）
    func closeOperation() {
        Self.logger.info("close operation view")
        removeBubble()
        Self.logger.info("reload naviBar via rootDelegate")
        self.rootDelegate?.rootReloadNaviBar()
    }

// MARK: UICollectionView-DelegateFlowLayout

    /// 设置section的header高度
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        /// 获取相应sectionModel
        guard let sectionModel = workPlaceUIModel?.getSectionModel(index: section) else {
            Self.logger.error("get sectionModel at \(section) faild for header height")
            return .zero
        }
        /// 获取当前section的header大小，返回.zero则不展示
        return sectionModel.getHeaderSize(superViewWidth: collectionView.bdp_width)
    }
    /// 设置section的footer高度
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForFooterInSection section: Int
    ) -> CGSize {
        /// 获取相应sectionModel
        guard let sectionModel = workPlaceUIModel?.getSectionModel(index: section) else {
           Self.logger.error("get sectionModel at \(section) faild for footer height")
            return .zero
        }
        /// 获取当前section的header大小，返回.zero则不展示
        let itemsPerRow = WorkPlaceViewModel.appsCountPerRow
        return sectionModel.getFooterSize(
            collectionview: collectionView,
            section: section,
            itemsPerRow: itemsPerRow
        )
    }

    /// 设置每个item大小
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard let sectionModel = workPlaceUIModel?.getSectionModel(index: indexPath.section),
        let itemModel = sectionModel.getItemAtIndex(index: indexPath.item) else {
            Self.logger.error(
                "get itemSize at section-\(indexPath.section) item-\(indexPath.item) failed"
            )
            return .zero
        }
        return itemModel.getItemLayoutSize(superViewWidth: collectionView.bdp_width)
    }
    /// 设置item之间的行间距
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return ItemModel.miniLineSpace
    }

    // MARK: - UICollectionViewDropDelegate
    func collectionView(
        _ collectionView: UICollectionView,
        performDropWith coordinator: UICollectionViewDropCoordinator
    ) {}

    func collectionView(
        _ collectionView: UICollectionView,
        dropSessionDidUpdate session: UIDropSession,
        withDestinationIndexPath destinationIndexPath: IndexPath?
    ) -> UICollectionViewDropProposal {
        rawCollectionView(collectionView, dropSessionDidUpdate: session, withDestinationIndexPath: destinationIndexPath)
    }

    // MARK: - UICollectionViewDragDelegate
    func collectionView(
        _ collectionView: UICollectionView,
        itemsForBeginning session: UIDragSession,
        at indexPath: IndexPath
    ) -> [UIDragItem] {
        rawCollectionView(collectionView, itemsForBeginning: session, at: indexPath)
    }
}

// MARK: 工作台全部应用分组的headerView
extension WorkPlaceViewController: AppCenterAllAppHeaderViewProtocol, AppCenterHomeCategroyProtocol {

    /// 刷新筛选页面
    private func tryCloseCategoryPage(animated: Bool) -> Bool {
        guard let pageView = self.categoryPageViewController else {
            Self.logger.debug("miss category page，not need to refresh")
            return false
        }
        pageView.closeCategory(animated: animated)
        return true
    }
    /// 添加蒙层
    private func addSelectCategoryMask() {
        guard let navView = self.navigationController?.view else {
            return
        }
        navView.addSubview(maskView)
        maskView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        maskView.setNeedsUpdateConstraints()
    }
    /// 移除蒙层
    private func removeMask() {
        maskView.removeFromSuperview()
    }
    /// 点击分类筛选按钮
    func didSelectCategoryButton(sender: UIButton) {
        if let sectionModel = workPlaceUIModel?.allAppSectionModel,
            let nameArray = sectionModel.allAppsData?.nameList(),
            let index = sectionModel.allAppsData?.selectedIndex().row {
            let isPopMode: Bool = Display.pad && isWPWindowRegularSize()
            let categoryPageViewController = AppCenterHomeCategroyViewController(
                with: nameArray, selectIndex: index, isPopMode: isPopMode
            )
            categoryPageViewController.delegate = self
            if isPopMode {
                categoryPageViewController.preferredContentSize = AppCenterHomeCategroyViewController.getPopSize(
                    itemCount: nameArray.count
                )
                let sourceRect = sender.convert(sender.bounds, to: view)
                categoryPageViewController.modalPresentationStyle = .popover
                categoryPageViewController.popoverPresentationController?.backgroundColor = UIColor.ud.bgBody
                categoryPageViewController.popoverPresentationController?.sourceView = view
                categoryPageViewController.popoverPresentationController?.sourceRect = sourceRect.insetBy(dx: -8, dy: 0)
                categoryPageViewController.popoverPresentationController?.permittedArrowDirections = .left
            } else {
                addSelectCategoryMask()
            }
            self.categoryPageViewController = categoryPageViewController
            self.triggerCategoryButton = sender
            present(categoryPageViewController, animated: true)
        }
    }
    /// 点击分类选项
    private func didSelectCategory(
        categoryIndex: Int,
        sectionModel: SectionModel
    ) {
        guard categoryIndex >= 0 && categoryIndex < (sectionModel.tag.subTags ?? []).count,
            let subtag = sectionModel.tag.subTags?[categoryIndex] else {
            Self.logger.error("didSelectCategory index \(categoryIndex) out of bounds")
            return
        }
        Self.logger.info("select tag \(subtag.tagName)")
        workPlaceUIModel?.didSelect(sectionTag: sectionModel.tag, subTag: subtag)
    }
    /// 点击横向滑动列表的cell
    /// - Parameter indexPath: 位置
    func didSelectHorizontalLabelCell(
        headerView: AppCenterAllAppHeaderView,
        at indexPath: IndexPath
    ) {
        if let sectionModel = workPlaceUIModel?.allAppSectionModel {
            didSelectCategory(
                categoryIndex: indexPath.row,
                sectionModel: sectionModel
            )
        }
    }
    /// 点击了侧滑栏分类cell
    /// - Parameter indexPath: 位置
    func didSelectAppCenterHomeCategroyCollectionViewCell(
        categoryVC: AppCenterHomeCategroyViewController,
        at indexPath: IndexPath,
        for group: Int
    ) {
        if let sectionModel = workPlaceUIModel?.allAppSectionModel {
            didSelectCategory(
                categoryIndex: indexPath.row,
                sectionModel: sectionModel
            )
        }
        removeMask()
    }
    /// 点击了空白区域 关闭分类页
    func justCloseAppCenterHomeCategroyViewController(
        categoryVC: AppCenterHomeCategroyViewController,
        for group: Int
    ) {
        removeMask()
    }
    /// 判断一个App是否是新应用（判断规则：远端数据为isNew && 本地未被消除标记 && 不是常用应用）
    func isRealNewApp(itemId: String, indexPath: IndexPath, isRemoteNew: Bool) -> Bool {
        guard let sections = workPlaceUIModel?.sectionsList, indexPath.section < sections.count else {
            Self.logger.warn("section is invalid, app not exsit")
            return false
        }
        // swiftlint:disable contains_over_first_not_nil
        return isRemoteNew                                              // 远端数据为isNew
            && (localCleanNewItemIds.firstIndex(of: itemId) == nil)     // 本地未被消除标记
            && !(sections[indexPath.section].type == .favorite)    // 非主tag下的应用
            && indexPath.row < 5                                        // 每个tag下的前5个应用才展示蓝点
        // swiftlint:enable contains_over_first_not_nil
    }
    /// 判断一个应用是否是常用应用
    func isCommonApp(itemId: String) -> Bool {
        return workPlaceUIModel?.isCommonItem(itemId: itemId) ?? false
    }
}

extension WorkPlaceViewController: BlockCellDelegate {

    func onTitleClick(_ cell: BlockCell, link: String?) {
        Self.logger.info("[block] title click open link: \(link ?? "")")
        guard let str = link, let url = URL(string: str) else { return }

        context.navigator.showDetailOrPush(
            url,
            context: ["from": "appcenter"],
            wrap: LkNavigationController.self,
            from: self
        )
    }

    func onActionClick(_ cell: BlockCell) {
        if let items = cell.getActionMenuItems(), !items.isEmpty {
            showActionMenu(cell, items: items)
        } else {
            Self.logger.error("action menu is empty, not display")
        }
    }
    func onLongPress(_ cell: BlockCell, gesture: UIGestureRecognizer) {
        if let items = cell.getActionMenuItems(), !items.isEmpty {
            showActionMenu(cell, items: items)
        } else {
            Self.logger.error("action menu is empty, not display")
        }
    }
    func blockDidFail(_ cell: BlockCell, error: OPError) {
    }
    func blockRenderSuccess(_ cell: BlockCell) {
    }
    func blockDidReceiveLogMessage(_ cell: BlockCell, message: WPBlockLogMessage) {
    }
    func blockContentSizeDidChange(_ cell: BlockCell, newSize: CGSize) {
    }
}

// MARK: - tracker

extension WorkPlaceViewController {
    func reportPageStayDurationIfNeeded() {
        rootDelegate?.tracker.trackPageStayDurationIfNeeded(.normal(initData), duration: pageStayDuration)
    }
}
// swiftlint:enable file_length
