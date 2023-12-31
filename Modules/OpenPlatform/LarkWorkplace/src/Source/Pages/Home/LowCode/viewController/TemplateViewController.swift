//
//  TemplateViewController.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2021/4/1.
//
// swiftlint:disable file_length

import Swinject
import RxSwift
import RxRelay
import LarkUIKit
import EENavigator
import LKCommonsLogging
import ECOInfra
import ByteWebImage
import LarkAlertController
import WebBrowser
import AnimatedTabBar
import LarkTab
import LarkLocalizations
import SwiftyJSON
import UIKit
import SnapKit
import LarkInteraction
import LarkContainer
import LarkSetting
import LarkNavigator
import LarkWorkplaceModel
import LarkNavigation
import RustPB
import UniverseDesignToast
import LarkQuickLaunchInterface
import OPBlockInterface

private enum WPMovingMeetsDirection: Int {
    case none = 0
    case top = 1
    case bottom = 2
}

private enum WPLongGestureAction: Int {
    case none = 0
    case dragAndMove = 1
    case showActionMenu = 2
}

private struct WPFirstScreenComponent {
    let id: String
    let type: String

    func toDictionary() -> [String: String] {
        return [
            "id": id,
            "type": type
        ]
    }
}

final class TemplateViewController: WPBaseViewController,
                                    UICollectionViewDelegate,
                                    UICollectionViewDataSource,
                                    OperationDialogHostProtocol,
                                    UIPopoverPresentationControllerDelegate {
    static let logger = Logger.log(TemplateViewController.self)

    let context: WorkplaceContext
    private let templateDataManager: TemplateDataManager

    private var enablePrefetchBlock: Bool {
        return context.configService.fgValue(for: .enablePrefetchBlock)
    }

    /// 我的常用支持最近使用子组件
    private var enableRecentlyUsedApp: Bool {
        return context.configService.fgValue(for: .enableRecentlyUsedApp)
    }

    private let blockDataService: WPBlockDataService
    private var prefetchBlockData: [String: WPBlockPrefetchData]?

    private(set) var groupComponents: [GroupComponent]?

    let disposeBag = DisposeBag()
    weak var rootDelegate: WPHomeRootVCProtocol?
    var launchReporter: TemplateLaunchReport

    /// 首次加载是否使用缓存
    let firstLoadByCache: Bool

    /// 是否展示naviBar
    var isShowNaviBar: Bool = true
    /// 工作台运营配置的Model
    var workPlaceOperationModel: WorkPlaceOperationModel?
    /// 是否完成首次数据请求
    internal var finishFirstDataRequest = false
    /// 操作菜单展示管理器
    var actMenuShowManager: ActionMenuManager = ActionMenuManager()
    ///  操作菜单触发item的itemId与indexPath映射表
    var actionMenuTriggerItemIndex: [String: IndexPath] = [:]
    ///  iconCell位置和数据的映射表
    var iconPathDatas: [IndexPath: ItemModel] = [:]

    private let pageDisplayStateService: WPHomePageDisplayStateService

    /// 页面配置信息
    var pageConfig: ConfigModel

    private(set) var initData: WPHomeVCInitData.LowCode

    /// 首次渲染标志位
    private var firstRenderFlag: Bool = true

    /// 常用组件/应用区域状态：默认态 or 编辑态
    private var commonAreaState: WPCommonAreaState = .normal

    /// 存储被移动的常用组件/应用的信息
    private var movingCommonItemInfo: WPMovingItemInfo?
    /// 常用组件/应用拖拽时，是否到达边缘
    private var movingMeetsDirection: WPMovingMeetsDirection = .none

    // 拖动常用组件/应用拖拽时，创建计时器来同步滚动 collectionView
    private var autoScrollTimer: CADisplayLink?
    private var longPressGestureAction: WPLongGestureAction = .none
    private var longGetureActionTimer: Timer?
    private var commonComponentsBeforeDragging: [NodeComponent]?

    /// 常用区域当前正触发长按手势的cell的indexPath，防止多个cell同时触发长按
    private var commonAndRecommandLongPressIndexPath: IndexPath?

    /// 首次滑动标志位，用来做框架加载出来到首次滚动耗时埋点
    private var firstScroll: Bool = true

    /// push消息更新时间
    private var pushRefreshTime: TimeInterval = 0

    /// Template版工作台表格视图
    lazy var workPlaceCollectionView: WPTemplateCollectionView = {
        createCollectionView()
    }()

    /// 背景视图
    private let backgroundImageView: WPBackgroundView
    private(set) var collectionViewTopConstraint: Constraint?

    private lazy var enableUseCache: Bool = {
        return firstLoadByCache && templateDataManager.checkHasCache(for: initData)
    }()

    let dataManager: AppCenterDataManager
    let openService: WorkplaceOpenService
    let dependency: WPDependency
    let badgeService: WorkplaceBadgeService

    // MARK: - OperationDialogHostProtocol 运营弹窗
    let dialogMgr: OperationDialogMgr
    var onShow: Bool = false

    /// 用于统计 Block 曝光情况，key: item id，value: 上次停留时，是否曝光
    var blockExposeState: [String: Bool] = [:]
    
    let quickLaunchService: QuickLaunchService
    
    // 是否展示无权限block，true为不展示，false表示展示。取自 schema 中的数据
    private(set) var isHideBlockForNoAuth: Bool = false
    private lazy var isShowBlockForNoAuthFg: Bool = {
        context.userResolver.fg.staticFeatureGatingValue(with: "workplace.template.no_permission_hide")
    }()
    private var hideBlockModelArray: [BlockModel] = []      // reset before network request

    // MARK: TemplateWorkPlace-VC初始化
    init(
        context: WorkplaceContext,
        rootDelegate: WPHomeRootVCProtocol?,    /* 需要改造 */
        data: WPHomeVCInitData.LowCode,
        templateDataManager: TemplateDataManager,
        firstLoadCache: Bool,
        blockDataService: WPBlockDataService,
        pageDisplayStateService: WPHomePageDisplayStateService,
        dataManager: AppCenterDataManager,
        openService: WorkplaceOpenService,
        dependency: WPDependency,
        badgeService: WorkplaceBadgeService,
        dialogMgr: OperationDialogMgr,
        quickLaunchService: QuickLaunchService
    ) {
        self.context = context
        self.initData = data
        self.launchReporter = TemplateLaunchReport(trace: context.trace)
        self.launchReporter.recordInitEnvStart()
        self.rootDelegate = rootDelegate
        self.firstLoadByCache = firstLoadCache
        self.blockDataService = blockDataService
        self.pageDisplayStateService = pageDisplayStateService
        self.dataManager = dataManager
        self.openService = openService
        self.dependency = dependency
        self.badgeService = badgeService
        self.dialogMgr = dialogMgr
        self.templateDataManager = templateDataManager
        self.pageConfig = templateDataManager.getPageConfigCache(template: data)
        self.backgroundImageView = WPBackgroundView()
        self.quickLaunchService = quickLaunchService
        Self.logger.info("Template WorkPlace init, welcome to Template WorkPlace")
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        monitor_pageLaunchStart(scene: .cold_boot)
        setupViews()
        if enablePrefetchBlock {
            prefetchBlockData = blockDataService.getPrefetchData()
        }
        launchReporter.recordInitEnvEnd()
        dataProduce(useCache: firstLoadByCache)
        registerPushNotification()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        onShow = true
		notifyBlockViewVCAppear(true)
        rootDelegate?.tracker.trackPageExpose(
            .lowCode(initData),
            templatePortalCount: rootDelegate?.templatePortalCount ?? 0
        )
        pageDisplayStateService.notifyPageAppear()
        // Block 产品埋点曝光（工作台不可见 -> 可见）
        if let groups = groupComponents {
            resetExposeBlockMap(with: groups)
            workPlaceCollectionView.performBatchUpdates(nil) { [weak self] _ in
                guard let `self` = self else { return }
                self.reportBlockExpose(collectionView: self.workPlaceCollectionView)
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onShow = false
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
		notifyBlockViewVCAppear(false)
        reportPageStayDurationIfNeeded()
        pageDisplayStateService.notifyPageDisappear()
    }

    // 适配iPad分/转屏，collectionview需要刷新布局（仅刷新布局的地方不要用reloadData）
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // 找到正在展示的actionMenu气泡，暂存位置信息，以备完成转屏后恢复
        var targetPath: IndexPath?
        var targetItemId: String?
        if actMenuShowManager.showMenuPopOver != nil {
            targetPath = actMenuShowManager.targetPath
            targetItemId = actMenuShowManager.targetItemId
            dismissActionMenu()
        }

        // 执行分/转屏
        coordinator.animate(alongsideTransition: nil, completion: { [weak self](_) in
            guard let `self` = self else { return }
            self.workPlaceCollectionView.collectionViewLayout.invalidateLayout()
            self.workPlaceCollectionView.reloadData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                if let indexPath = targetPath { //  恢复长按菜单
                    self.reappearActionMenu(originIndexPath: indexPath, itemId: targetItemId)
                }
            })
        })
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        Self.logger.info("Template traitCollectionDidChange", additionalData: [
            "previousTraitCollection": "\(previousTraitCollection ?? UITraitCollection())",
            "currentTraitCollection": "\(traitCollection)"
        ])
        super.traitCollectionDidChange(previousTraitCollection)
        self.refreshMenuOnTraitCollectionDidChange()
    }

    override func onPageWillResignActive() {
        super.onPageWillResignActive()

        guard isAppeared else {
            return
        }

        handlingPageVisiblityChangesForBlock(pageVisible: false)

        reportPageStayDurationIfNeeded()
    }

    override func onPageDidBecomeActive() {
        super.onPageDidBecomeActive()
        guard isAppeared else { return }
        handlingPageVisiblityChangesForBlock(pageVisible: true)
        rootDelegate?.tracker.trackPageExpose(
            .lowCode(initData),
            templatePortalCount: rootDelegate?.templatePortalCount ?? 0
        )
        reportFavoriteComponentExpose()
        // Block 产品埋点曝光（工作台不可见 -> 可见）
        resetExposeBlockMap(with: groupComponents ?? [])
        reportBlockExpose(collectionView: workPlaceCollectionView)
    }

    // MARK: popOver回调
    /// popOver消失事件
    @objc
    func popoverPresentationControllerDidDismissPopover(
        _ popoverPresentationController: UIPopoverPresentationController
    ) {
        if actMenuShowManager.showMenuPopOver != nil {
            Self.logger.info("action menu popOver dismiss")
            dismissActionMenu()
        }
    }

    /// 适配分屏模式下的异常popOver
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    // 滚动事件
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if firstScroll {
            firstScroll = false
            monitorFirstStartScroll()
        }
        var offset = workPlaceCollectionView.contentOffset
        if offset.y <= 0 {  // 禁用向上拉伸
            offset.y = 0
        }
        workPlaceCollectionView.contentOffset = offset
    }

    /// 刷新工作台数据
    /// - Parameters:
    ///   - useCache: 是否使用缓存（仅冷启动时使用缓存）
    ///   - forceUseCacheOnly: 是否强制使用缓存数据刷新（使用缓存不会再请求网络数据刷新<弹窗时，用户点击「立即更新」时使用>）
    func dataProduce(useCache: Bool = false, isRetry: Bool = false) {
        let pageShown = !workPlaceCollectionView.isHidden

        // 页面未展示出来的情况
        if !pageShown {
            self.stateView.state = .loading
            // 模板加载中，页面配置为：按缓存值展示title，不展示ICON
            let cacheConfig = self.templateDataManager.getPageConfigCache(template: initData)
            let newConfig = ConfigModel(showTitle: cacheConfig.showPageTitle)
            if !newConfig.isEqual(to: self.pageConfig) {
                self.pageConfig = newConfig
            }
            self.reloadWrapperNaviBar()
        }

        if !isRetry && finishFirstDataRequest {
            monitorRefreshPageStart()
        }

        launchReporter.recordRequestStart()

        let monitor = WPMonitor().timing()
        // cache fg 关闭的情况，认为是没有缓存
        let shouldUseCache: Bool = useCache && enableUseCache
        // 把三个请求（模板列表，模板文件，官方数据）串行化，请求回来就是带有官方数据的组件列表
        // 可以进行展示。异步请求三方组件数据，逐个刷新

        hideBlockModelArray = []

        templateDataManager.getHomeComponents(
            template: initData,
            useCache: shouldUseCache,
            // swiftlint:disable closure_body_length
            completion: { [weak self] result in
                guard let `self` = self else {
                    Self.logger.warn("TemplateViewController deinit before data back!")
                    return
                }
                let isFirstRequest = !self.finishFirstDataRequest
                self.finishFirstDataRequest = true
                switch result {
                case .success(let data):
                    Self.logger.info("TemplateVC data produce success: \(data.components), refresh page")
                    self.stateView.state = .hidden
                    self.workPlaceCollectionView.isHidden = false
                    self.isHideBlockForNoAuth = data.preferProps?.isHideBlockForNoAuth ?? false
                    // 刷新页面 && 保存当前模板
                    self.refreshViews(with: data, isFirstRefresh: (isFirstRequest || isRetry))

                    self.launchReporter.recordRequestEnd()
                    self.rootDelegate?.reportFirstScreenDataReadyIfNeeded()
                    if isFirstRequest || isRetry {
                        self.monitorPageLoadSuccess(
                            useCache: shouldUseCache,
                            isRetry: isRetry,
                            monitor: monitor
                        )
                    } else {
                        self.monitorRefreshPageSuccess()
                    }

                    // 获取弹窗数据
                    self.wp_operationDialogProduce(completion: nil)
                case .failure(let errorData):
                    Self.logger.error("TemplateVC data produce failed with error: \(errorData.error)")
                    if isFirstRequest || isRetry {
                        self.monitorPageLoadFail(
                            isRetry: isRetry,
                            monitor: monitor,
                            failFrom: errorData.failFrom,
                            useCache: shouldUseCache
                        )
                    } else {
                        self.monitorRefreshPageFail(failFrom: errorData.failFrom)
                    }

                    self.launchReporter.isStepFailed = true
                    self.handleDataProduceError(errorData.error)
                }
            }
            // swiftlint:enable closure_body_length
        )
    }

    /// 从网络更新缓存
    func refreshCache() {
        templateDataManager.getHomeComponents(template: initData, useCache: false, completion: { _ in })
    }

    private func handleDataProduceError(_ error: WPTemplateError, isSwitchTemplate: Bool = false) {
        Self.logger.info("template handle data produce error:\(error)")

        switch error {
        case .invalidSchema, .invalidTemplate:
            Self.logger.info("template info invalid, force user to upGrade")
            /// 模板信息、文件不可用，强制提示升级客户端
            stateView.state = .verExpired
            monitorShowErrorView()

            // 模板提示升级，页面配置为：按缓存值展示title,不展示ICON
            let cacheConfig = self.templateDataManager.getPageConfigCache(template: initData)
            let newConfig = ConfigModel(showTitle: cacheConfig.showPageTitle)
            if !newConfig.isEqual(to: self.pageConfig) {
                self.pageConfig = newConfig
            }
            self.reloadWrapperNaviBar()
        default:
            let noContentShown = self.workPlaceCollectionView.isHidden || isSwitchTemplate
            Self.logger.error("template error occurred, with noContentShown(\(noContentShown))")
            if noContentShown {
                switch self.stateView.state {
                case .loadFail:
                    break
                default:
                    self.stateView.state = .loadFail(
                        .create(
                            monitorCode: WPMCode.workplace_page_show_error,
                            showReloadBtn: true,
                            action: { [weak self] in
                                self?.retryLoading()
                            }
                        )
                    )
                }
                
                monitorShowErrorView()
                // 模板加载失败，页面配置为：展示title，不展示ICON
                let newConfig = ConfigModel(showTitle: true)
                if !newConfig.isEqual(to: self.pageConfig) {
                    self.pageConfig = newConfig
                }
                self.reloadWrapperNaviBar()
            } else {
                stateView.state = .hidden
            }
        }
    }

    private func setupViews() {
        Self.logger.info("TemplateVC setup views for U")

        // VC基本配置(把页面扩展到屏幕底部避免拖动删除cell闪烁)
        modalPresentationStyle = .custom
        view.backgroundColor = UIColor.ud.bgBody
        edgesForExtendedLayout = .bottom
        extendedLayoutIncludesOpaqueBars = true
        view.insertSubview(backgroundImageView, belowSubview: workPlaceCollectionView)
        backgroundImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(rootDelegate?.topNavH ?? 0)
            make.leading.trailing.equalToSuperview()
            let botOffset: CGFloat = rootDelegate?.botTabH ?? 0
            make.bottom.equalToSuperview().offset(-botOffset)
        }
        workPlaceCollectionView.isHidden = true
    }

    func inner_updateInitData(_ wrapper: WPHomeVCInitData) {
        guard case .lowCode(let data) = wrapper, data.isSameCoreData(with: initData) else {
            Self.logger.error("update invalid init data")
            assertionFailure()
            return
        }
        // 目前只用于更新标题
        initData = data
        rootDelegate?.rootReloadNaviBar()
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
        // swiftlint:disable line_length
		let name = appear ? WorkplaceViewControllerNotifiction.vcDidAppear.name : WorkplaceViewControllerNotifiction.vcDidDisappear.name
        // swiftlint:enable line_length
        NotificationCenter.default.post(name: name, object: nil)
	}

    private func resetCollectionView() {
        Self.logger.warn("reset template cview")
        workPlaceCollectionView.removeFromSuperview()
        workPlaceCollectionView = createCollectionView()
    }

    private func createCollectionView() -> WPTemplateCollectionView {
        let layout = WPTemplateLayout(
            userId: context.userId,
            configService: context.configService,
            layoutModel: groupComponents ?? []
        )
        layout.decorationDelegate = self

        let cv = WPTemplateCollectionView(frame: .zero, collectionViewLayout: layout)
        cv.delegate = self
        cv.dataSource = self

        view.insertSubview(cv, at: 0)
        let bottomInset: CGFloat = animatedTabBarController?.tabbarHeight ?? 63
        let bottomMargin: CGFloat = (Display.pad || templateDataManager.isPreview) ? 0 : bottomInset
        cv.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(LarkNaviBarConsts.naviHeight)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(bottomMargin)
        }
        return cv
    }

    private func retryLoading() {
        /// 刷新数据（由于没有数据才可能触发error页面，所以重试时只当做first请求）
        Self.logger.info("user retry load home page")
        dataProduce(isRetry: true)
    }

    func reuseTriComponent(with newComponentList: [GroupComponent]) -> [GroupComponent] {
        /// 复用已有第三方数据（避免三方组件数据没请求到，空数据而导致页面闪烁）
        var reuseComponentList: [GroupComponent] = []
        guard let oldComponentList = groupComponents else { return newComponentList }

        for newComponent in newComponentList {
            let oldComponent = oldComponentList.first(where: { $0.componentID == newComponent.componentID })
            // 数据更新时保留常用组件中用户最近一次点击的 Tab
            // 数据更新的情况包括：切 Tab、拿到缓存数据后再拿到远端数据
            // 冷启动不需要保存用户点击状态
            if let newFavoriteComponent = newComponent as? CommonAndRecommendComponent,
               let oldFavoriteComponent = oldComponent as? CommonAndRecommendComponent,
               let userSelectedTab = oldFavoriteComponent.userSelectedSubModule {
                newFavoriteComponent.updateDisplayModule(module: userSelectedTab, isUserSelected: true)
            }

            reuseComponentList.append(newComponent)
        }

        return reuseComponentList
    }

    func refreshViews(with data: WPTemplateHomeData, isFirstRefresh: Bool) {
        Self.logger.info("TemplateVC refresh template(id:\(initData.id)) views for U")

        // 更新背景图
        if let props = data.backgroundProps {
            backgroundImageView.refreshWhenDataChange(with: props)
        }

        var components = reuseTriComponent(with: data.components)
        if !data.isFromCache {
            components = filterHideBlockModel(from: components)
        }
        self.groupComponents = components

        if let layout = self.workPlaceCollectionView.collectionViewLayout as? WPTemplateLayout {
            layout.layoutModel = self.groupComponents ?? []
        }
        /// 添加常用区域的提示cell
        let group = groupComponents?.first(where: {
            $0.groupType == .CommonAndRecommend
        })
        if let commonGroup = group as? CommonAndRecommendComponent {
            commonGroup.updateFavoriteAreaState(state: commonAreaState)
        }

        self.workPlaceCollectionView.reloadData()
        if isFirstRefresh {
            DispatchQueue.main.async {[weak self] in
                self?.handleFirstScreenData()
            }
        }

        // 工作台门户内容首次成功加载，上报 Block 曝光埋点
        if isFirstRefresh, onShow {
            resetExposeBlockMap(with: groupComponents ?? [])
            workPlaceCollectionView.performBatchUpdates(nil) { [weak self] _ in
                guard let `self` = self else { return }
                self.reportBlockExpose(collectionView: self.workPlaceCollectionView)
            }
        }

        // 清空应用的位置索引，等待重新刷新
        actionMenuTriggerItemIndex.removeAll()
        iconPathDatas.removeAll()

        let newConfig = self.templateDataManager.getPageConfigCache(template: initData)
        if !self.pageConfig.isEqual(to: newConfig) {
            self.pageConfig = newConfig
        }
        self.reloadWrapperNaviBar()
    }

    private func filterHideBlockModel(from components: [GroupComponent]) -> [GroupComponent] {
        var outerIndex: [Int] = []
        for i in 0..<(components.count) {
            guard let blockComponent = components[i] as? BlockLayoutComponent else {
                continue
            }
            var innerIndex: [Int] = []

            // search
            for idx in 0..<(blockComponent.nodeComponents.count) {
                guard let model = blockComponent.nodeComponents[idx] as? BlockComponent,
                      let blockModel = model.blockModel else {
                    continue
                }
                let contains = hideBlockModelArray.contains { $0 == blockModel }
                if contains {
                    innerIndex.append(idx)
                }
            }
            
            // delete
            for idx in innerIndex.reversed() {
                blockComponent.removeComponent(at: idx, for: true)
            }

            if blockComponent.nodeComponents.isEmpty {
                outerIndex.append(i)
            }
        }

        // delete
        var result = components
        for idx in outerIndex.reversed() {
            result.remove(at: idx)
        }
        return result
    }

    /// 更新naviBar
    func reloadWrapperNaviBar() {
        Self.logger.info("reload naviBar via rootDelegate")
        rootDelegate?.rootReloadNaviBar()
    }

    /// GroupComponent 占位 Cell 展示加载失败，点击重新加载组件的数据信息
    private func reloadGroupComponent(_ groupComponent: GroupComponent) {
        Self.logger.info("templateVC try to reload Component(id:\(groupComponent.componentID))")
        if groupComponent.moduleReqParam != nil {
            groupComponent.updateGroupState(.loading)
            refreshSectionByComponentIfNeeded(groupComponent)
            self.templateDataManager.updateModuleBizData(portalId: initData.id, groupComponent: groupComponent) { (error) in
                if let err = error {
                    Self.logger.error("update module biz data error: \(err)")
                    groupComponent.updateGroupState(.loadFailed)
                } else {
                    groupComponent.updateGroupState(.running)
                }
                self.refreshSectionByComponentIfNeeded(groupComponent)
            }
        } else {
            assertionFailure("missing module param!")
        }
    }

    /// 刷新某个 GroupComponent 所在的 Section UI
    private func refreshSectionByComponentIfNeeded(_ group: GroupComponent) {
        guard let idx = self.groupComponents?.firstIndex(where: { $0 === group }) else {
            // group 已经不在数据源里面了，不需要刷新页面
            return
        }
        UIView.performWithoutAnimation {
            self.workPlaceCollectionView.reloadSections([idx])
        }
    }

    private func handleCommonItemsLongPressAction(
        cell: UICollectionViewCell,
        gesture: UIGestureRecognizer
    ) {
        guard gesture is UILongPressGestureRecognizer || gesture is RightClickRecognizer else {
            return
        }
        switch gesture.state {
        case .began:
            commonComponentsBeforeDragging = nil
            cancelLongGestureTimer()
            clearMovingItem()
            if commonAreaState == .normal {
                /// 默认态，长按1s并且无位移，弹出菜单
                /// 长按默认触发的时间是0.5s, 所以触发后再过0.5s弹出菜单
                longGetureActionTimer = Timer.scheduledTimer(
                    timeInterval: 0.5,
                    target: self,
                    selector: #selector(showActionMenuTimer(timer:)),
                    userInfo: ["gesture": gesture, "cell": cell],
                    repeats: false
                )
            }
            beginMoveItem(gesture: gesture)
            break
        case .changed:
            movingItem(with: gesture)
            break
        case .ended:
            longPressGestureAction = .none
            cancelLongGestureTimer()
            moveItemFinished()
            break
        default:
            longPressGestureAction = .none
            cancelLongGestureTimer()
            moveItemFinished()
            break
        }
    }

    @objc func showActionMenuTimer(timer: Timer) {
        if longPressGestureAction == .dragAndMove {
            return
        }
        guard let userInfo = timer.userInfo as? [String: AnyObject] else {
            return
        }

        resetDragAction()
        longPressGestureAction = .showActionMenu
        if let geture = userInfo["gesture"] as? UIGestureRecognizer {
            // cancel长按手势
            geture.isEnabled = false
            geture.isEnabled = true
        }
        let cell = userInfo["cell"]
        if let blockCell = cell as? BlockCell,
           let items = blockCell.getActionMenuItems(),
           !items.isEmpty {
            showActionMenu(blockCell, items: items)
            return
        }

        if let iconCell = cell as? WorkPlaceIconCell,
           let indexPath = workPlaceCollectionView.indexPath(for: iconCell),
           let item = getNodeComponent(at: indexPath) as? CommonIconComponent,
           let itemModel = item.itemModel {
            let isCommon = item.appScene == .common
            iconCell.updatePressState(isPressed: false)
            handleIconLongPress(cell: iconCell, itemInfo: itemModel, indexPath: indexPath)
        }
        cancelLongGestureTimer()
    }

    func cancelLongGestureTimer() {
        longGetureActionTimer?.invalidate()
        longGetureActionTimer = nil
    }

    private func handleFirstScreenData() {
        var components: [WPFirstScreenComponent] = []
        var commonAndRecommandIconAdded: Bool = false
        // swiftlint:disable closure_body_length
        workPlaceCollectionView.visibleCells.forEach { cell in
            guard let indexPath = workPlaceCollectionView.indexPath(for: cell),
                  let group = groupComponents?[indexPath.section],
                  let cellModel = getNodeComponent(at: indexPath) else {
                      return
                  }

            switch group.groupType {
            case .Block:
                if let model = cellModel as? BlockComponent,
                   let blockModel = model.blockModel {
                    components.append(
                        WPFirstScreenComponent(
                            id: blockModel.blockId,
                            type: group.groupType.rawValue
                        )
                    )
                }
                break
            case .CommonAndRecommend:
                if cellModel.type == .CommonIconApp && commonAndRecommandIconAdded {
                    break
                }
                if let model = cellModel as? BlockComponent,
                   let blockModel = model.blockModel {
                    components.append(
                        WPFirstScreenComponent(
                            id: blockModel.blockId,
                            type: GroupComponentType.Block.rawValue
                        )
                    )
                } else if !commonAndRecommandIconAdded {
                    components.append(
                        WPFirstScreenComponent(
                            id: group.componentID,
                            type: group.groupType.rawValue
                        )
                    )
                    commonAndRecommandIconAdded = true
                }
                break
            default:
                break
            }
        }
        // swiftlint:enable closure_body_length
        monitorFirstScreen(components: components)
    }

    private func registerPushNotification() {
        Self.logger.info("register template push notification")
        context.userPushCenter
            .observable(for: WorkplacePushMessage.self)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else {
                    Self.logger.error("self is nil")
                    return
                }
                if self.commonAreaState == .editing { return }
                let currentTimestamp = Date().timeIntervalSince1970
                guard (currentTimestamp - self.pushRefreshTime) > 2.5 else {
                    /// 2.5s防抖处理
                    Self.logger.info("handle last push message within 2.5s")
                    return
                }
                guard let groupComponents = self.groupComponents,
                      let index =
                        groupComponents.firstIndex(where: { $0.groupType == .CommonAndRecommend })
                else {
                    Self.logger.info("cannot find common and recommend group")
                    return
                }
                Self.logger.info("handle push messge")
                let component = groupComponents[index]
                self.pushRefreshTime = Date().timeIntervalSince1970
                self.silentRefresh(section: index, component: component)
            })
            .disposed(by: disposeBag)
        // 监听最近使用应用变更，只在工作台可见时，才会请求最新数据
        if enableRecentlyUsedApp { registerRecentlyUsedAppChangeNotify() }
    }

    private func registerRecentlyUsedAppChangeNotify() {
        context.userPushCenter
            .observable(for: GadgetCommonPushMessage.self)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] message in
                guard let `self` = self else { return }
                guard let groupComponents = self.groupComponents,
                      let index = groupComponents.firstIndex(where: { $0.groupType == .CommonAndRecommend }),
                      GadgetCommonPushBiz(rawValue: message.biz) == .workplace_recent else {
                    return
                }
                if self.commonAreaState == .editing { return }
                let animatedTabBar = RootNavigationController.shared.viewControllers.first as? AnimatedTabBarController
                guard let currentTab = animatedTabBar?.currentTab, currentTab == .appCenter else { return }
                self.silentRefresh(section: index, component: groupComponents[index])
            })
            .disposed(by: disposeBag)
    }

    /// 打开第三方链接
    func openTriLink(url: String) {
        if let link = URL(string: url) {
            Self.logger.info("open biz link \(url)")
            context.navigator.showDetailOrPush(
                link,
                context: ["from": "appcenter"],
                wrap: LkNavigationController.self,
                from: self
            )
        } else {
            Self.logger.error("biz link err with \(url)")
        }
    }
    /// 静默刷新常用推荐列表
    func silentRefresh(section: Int, component: GroupComponent) {
        Self.logger.info("templateVC silent to refresh section(\(section))")
        if component.moduleReqParam != nil {
            self.templateDataManager.updateModuleBizData(portalId: initData.id, groupComponent: component) { (error) in
                if let err = error {
                    Self.logger.error("\(err.localizedDescription)")
                } else {
                    self.actMenuShowManager.isUILocalChanging = true
                    UIView.setAnimationsEnabled(false)
                    self.workPlaceCollectionView.performBatchUpdates({ [weak self] in
                        /*
                        UICollectionView内部维护了一个关于item数量的缓存，由于silent fresh不是用户手动触发的，不会引起relayout，因此缓存不会马上刷新。
                        在iOS12以下的系统，performBatchUpdates做全局刷新会导致crash
                        */
                        self?.workPlaceCollectionView.reloadSections([section])
                    },
                        completion: { [weak self](_) in
                            self?.actMenuShowManager.isUILocalChanging = false
                            UIView.setAnimationsEnabled(true)
                        }
                    )
                }
            }
        } else {
            Self.logger.info("component miss request, refresh failed")
        }
    }
    // MARK: - UICollectionViewDataSource
    /// 根据UIModel获取section数量（缺省值：0）
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return groupComponents?.count ?? 0
    }

    ///  numberOfItemsInSection
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let model = groupComponents, section < model.count else {
            return 0    // 没有数据的异常处理
        }

        let groupComponent = model[section]
        if groupComponent.componentState == .running {
            return getNodeCount(at: section)
        } else {
            return 1    // 状态示意cell
        }
    }

    /// 获取cell
    // swiftlint:disable function_body_length
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        /// 加载性能埋点（检测首屏是否有block，没有block加载，则直接上报）
        if firstRenderFlag, !isBlockInFirstFrame() {
            launchReporter.post()
        }
        firstRenderFlag = false

        guard let group = groupComponents?[indexPath.section] else {
            assertionFailure("datasource error")
            return collectionView.dequeueReusableCell(withReuseIdentifier: unknownCellID, for: indexPath)
        }
        guard group.componentState == .running else {
            guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: stateTipCellID,
                    for: indexPath
            ) as? WPComponentStateTipCell else {
                assertionFailure("cell type error")
                return collectionView.dequeueReusableCell(withReuseIdentifier: unknownCellID, for: indexPath)
            }
            Self.logger.debug("cell for item at \(indexPath) show state tip cell") // 临时调试信息
            cell.update(groupComponent: group, trace: context.trace) { [weak self] in
                guard let self = self else {
                    return
                }
                // 注意：使用 weak cell 防止循环引用
                self.reloadGroupComponent(group)
            }
            return cell
        }
        // 🔧 获取对应数据model实例
        guard let cellModel = getNodeComponent(at: indexPath) else {
            assertionFailure("cell model error")
            return collectionView.dequeueReusableCell(withReuseIdentifier: unknownCellID, for: indexPath)
        }

        /// 组件曝光
        group.exposePost()

        switch cellModel.type {
        case .Block:
            guard let model = cellModel as? BlockComponent, let blockModel = model.blockModel else {
                assertionFailure("block data missing")
                return collectionView.dequeueReusableCell(
                    withReuseIdentifier: unknownCellID,
                    for: indexPath
                )
            }
            let cellId = blockModel.uniqueId.fullString
            collectionView.register(BlockCell.self, forCellWithReuseIdentifier: cellId)
            guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: cellId,
                    for: indexPath
            ) as? BlockCell else {
                assertionFailure("block type error")
                return collectionView.dequeueReusableCell(
                    withReuseIdentifier: unknownCellID,
                    for: indexPath
                )
            }
            cell.delegate = self
            let extra = ExtraBlockInfo(containerID: initData.id)
            cell.updateData(
                blockModel,
                hostVCShow: onShow,
                extraInfo: extra,
                isEditing: commonAreaState == .editing,
                trace: context.trace,
                portalId: initData.id,
                prefetchData: prefetchBlockData?[blockModel.blockId],
                userResolver: context.userResolver
            )
            if let itemId = blockModel.editorProps?.itemId {
                actionMenuTriggerItemIndex[itemId] = indexPath
            }
            cell.isHidden = indexPath == movingCommonItemInfo?.currentIndexPath
            /// Block加载性能上报
            launchReporter.recordBlockStart(id: cellId)
            return cell
        case .CommonIconApp:
            guard let itemModel = cellModel as? CommonIconComponent,
                  let item = itemModel.itemModel else {
                return UICollectionViewCell()
            }
            var secondaryTag = ""
            if let group = group as? CommonAndRecommendComponent {
                secondaryTag = group.displaySubModule.rawValue
            }
            if case .addRect = item.itemType {
                return collectionView.dequeueReusableCell(
                    withReuseIdentifier: emptyCommonCellId,
                    for: indexPath
                )
            }

            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: templateCommonAppID,
                for: indexPath
            )
            guard let commonAppCell = cell as? WorkPlaceIconCell else {
                return cell
            }

            commonAppCell.delegate = self
            commonAppCell.refreshCell(
                with: item,
                isNewApp: false,
                fromTemplate: true,
                isEditing: commonAreaState == .editing,
                badgeService: badgeService,
                configService: context.configService,
                userResolver: context.userResolver,
                sectionType: .favorite,
                primaryTag: "my_common",
                secondaryTag: secondaryTag
            ) { [weak self] (itemCell, gesture) in
                // swiftlint:disable empty_enum_arguments
                if !item.isAddApp() {
                    // swiftlint:enable empty_enum_arguments
                    self?.handleCommonItemsLongPressAction(cell: itemCell, gesture: gesture)
                } else {
                    Self.logger.warn("long press on add item, menu not display")
                }
            }
            actionMenuTriggerItemIndex[item.item.itemId] = indexPath
            iconPathDatas[indexPath] = item
            commonAppCell.isHidden = indexPath == movingCommonItemInfo?.currentIndexPath
            return commonAppCell
        case .CommonTips:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: commonAreaInEditTipsCellId,
                for: indexPath
            ) as? WPCommonAreaTipCell else {
                return UICollectionViewCell()
            }

            cell.updateTips(
                isEditable: checkCommonAreaIsEditable(at: indexPath.section),
                enableRecentlyUsedApp: enableRecentlyUsedApp
            )
            return cell
        default:
            return collectionView.dequeueReusableCell(withReuseIdentifier: unknownCellID, for: indexPath)
        }
    }
    // swiftlint:enable function_body_length

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard let group = groupComponents?[indexPath.section] else {
            return UICollectionReusableView()
        }
        switch group.groupType {
        case .CommonAndRecommend:
            group.monitorComponentShow(trace: context.trace)
            break
        default:
            break
        }
        // 我的常用 Header
        if let commonGroup = group as? CommonAndRecommendComponent,
           let reusableView = collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: templateCommonHeaderID,
            for: indexPath
           ) as? WPCommonAppHeader {
            reusableView.delegate = self
            reusableView.indexPath = indexPath
            reusableView.refreshViews(
                with: commonGroup.layoutParams,
                titleComponents: commonGroup.extraComponents[.GroupTitle] as? GroupTitleComponent,
                configService: context.configService
            )
            let isEditable = !commonGroup.checkNodeListIsEmpty()
            reusableView.updateState(
                with: commonAreaState,
                isEditable: isEditable,
                displaySubModule: commonGroup.displaySubModule
            )
            return reusableView
        }
        assertionFailure("unknown reusable view")
        return UICollectionReusableView()
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true) // cell反选，实现点击效果
        guard let group = groupComponents?[indexPath.section],
            indexPath.row < getNodeCount(at: indexPath.section),
              let item = getNodeComponent(at: indexPath) else {
            return
        }
        Self.logger.info("cell tap event:\(group.groupType)")
        switch item.type {
        case .CommonIconApp:
            if let appItem = item as? CommonIconComponent, let itemModel = appItem.itemModel {
                Self.logger.info("tap app in CommonRecommend")
                let itemData = itemModel.dataItem.item
                switch itemModel.itemType {
                case .addIcon, .addRect:
                    Self.logger.info("user tap addIcon to add common App page")
                    openAddApp()
                    context.tracker
                        .start(.openplatform_workspace_main_page_click)
                        .setExposeUIType(.my_common_and_recommend)
                        .setSubType(.native)
                        .setTargetView(.openplatform_workspace_add_app_page_view)
                        .setClickValue(.add_app)
                        .setValue(initData.id, for: .template_id)
                        .post()

                case .icon:
                    Self.logger.info("user tap icon at \(indexPath) to open App")
                    if commonAreaState == .editing { return }
                    let isInRecentlyUsed = isInRecentlyUsedSubModule(section: indexPath.section)
                    openAppAndReportEvent(
                        with: itemModel.item,
                        appScene: appItem.appScene,
                        exposeUIType: isInRecentlyUsed ? .recentlyUsed : .commom_and_recommend
                    )

                default:
                    Self.logger.info("user tap app - \(itemModel.itemType)")
                    return
                }
            }
        default:
            Self.logger.info("tap cell unKnown: \(item.type)")
            return
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        if let blockCell = cell as? BlockCell {
            blockCell.visible = true
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt forItemAtindexPath: IndexPath
    ) {
        if let blockCell = cell as? BlockCell {
            blockCell.visible = false
        }
    }

    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return canMoveItem(at: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        if getCommonAndRecommendGroup(at: indexPath.section) != nil,
           commonAndRecommandLongPressIndexPath != nil && indexPath != commonAndRecommandLongPressIndexPath {
            return false
        }
        return true
    }

    /// 获取node数量
    private func getNodeCount(at section: Int) -> Int {
        guard let group = groupComponents?[section] else {
            Self.logger.error("group \(section) out range of groupComponents")
            return 0
        }
        return group.nodeComponents.count
    }

    /// 判断首屏是否有block
    private func isBlockInFirstFrame() -> Bool {
        guard let layout = workPlaceCollectionView.collectionViewLayout as? WPTemplateLayout else {
            assertionFailure("invalid layout")
            return false
        }
        for indexPath in layout.firstFrameCellIndex {
            if let cellModel = getNodeComponent(at: indexPath), cellModel is BlockComponent {
                return true
            }
        }
        return false
    }

    @objc
    private func startAutoScroll() {
        guard let movingItemInfo = movingCommonItemInfo,
              let snapshotImage = movingItemInfo.snapshotImageView,
              checkIfMoveMeetsEdge() else {
            return
        }
        let speed: CGFloat = 2
        var snapshotFrame = snapshotImage.frame
        let contentOffsetY = workPlaceCollectionView.contentOffset.y
        if movingMeetsDirection == .top && contentOffsetY > 0 {
            /// 向上滚动
            workPlaceCollectionView.setContentOffset(CGPoint(
                x: 0,
                y: contentOffsetY - speed
            ), animated: false)
            snapshotFrame.origin.y -= speed
            snapshotImage.frame = snapshotFrame

            if let indexPath = workPlaceCollectionView.indexPathForItem(
                at: workPlaceCollectionView.contentOffset
               ), getCommonAndRecommendGroup(at: indexPath.section) != nil {
                workPlaceCollectionView.layoutAttributesForSupplementaryElement(
                    ofKind: UICollectionView.elementKindSectionHeader,
                    at: indexPath
                )
            }
            // swiftlint:disable line_length
        } else if movingMeetsDirection == .bottom && contentOffsetY + workPlaceCollectionView.bounds.height < workPlaceCollectionView.contentSize.height {
            // swiftlint:enable line_length
            /// 向下滚动
            workPlaceCollectionView.setContentOffset(CGPoint(x: 0, y: contentOffsetY + speed), animated: false)
            snapshotFrame.origin.y += speed
            snapshotImage.frame = snapshotFrame
        }
    }

    private func startAutoSrollTimer() {
        if autoScrollTimer == nil {
            let timer = CADisplayLink(target: self, selector: #selector(startAutoScroll))
            timer.add(to: RunLoop.main, forMode: .common)
            autoScrollTimer = timer
        }
    }

    private func stopAutoScrollTimer() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }

    /// 获取数据Item
    func getNodeComponent(at indexPath: IndexPath) -> NodeComponent? {
        guard let group = groupComponents?[indexPath.section] else {
            Self.logger.error("group \(indexPath.section) out range of groupComponents")
            return nil
        }
        let row = indexPath.row
        let nodeList = group.nodeComponents
        return row < nodeList.count ? nodeList[row] : nil
    }
}

// MARK: Block代理
extension TemplateViewController: BlockCellDelegate {
    func onTitleClick(_ cell: BlockCell, link: String?) {
        Self.logger.info("handle title click", additionalData: [
            "link": link ?? ""
        ])
        if let indexPath = workPlaceCollectionView.indexPath(for: cell),
           groupComponents?.count ?? 0 > indexPath.section,
           (groupComponents?[indexPath.section] as? CommonAndRecommendComponent) != nil,
           commonAreaState == .editing {
            /// 编辑态不响应点击
            return
        }

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
        if cell.blockModel?.isTemplateCommonAndRecommand == true {
            /// 常用区域的block
            handleCommonItemsLongPressAction(cell: cell, gesture: gesture)
            return
        }
        commonAndRecommandLongPressIndexPath = nil
        guard gesture.state == .began else {
            return
        }
        if let items = cell.getActionMenuItems(), !items.isEmpty {
            showActionMenu(cell, items: items)
        } else {
            Self.logger.error("action menu is empty, not display")
        }
    }

    func blockDidFail(_ cell: BlockCell, error: OPError) {
        launchReporter.recordBlockEnd(id: cell.blockModel?.uniqueId.fullString, success: false)

        let isNoAuth = error.monitorCode == OPBlockitMonitorCodeMountLaunchGuideInfoServer.no_permissions ||
                       error.monitorCode == OPBlockitMonitorCodeMountLaunchGuideInfoServer.disable_install_other_tenant_selfbuilt_app ||
                       error.monitorCode == OPBlockitMonitorCodeMountLaunchGuideInfoServer.disable_apply_visible ||
                       error.monitorCode == OPBlockitMonitorCodeMountLaunchGuideInfoServer.bind_app_not_exist ||
                       error.monitorCode == OPBlockitMonitorCodeMountLaunchGuideInfoServer.install_in_deactivate
        Self.logger.info("[LarkWorkplace] blockDidFail", additionalData: [
            "monitorCode": "\(error.monitorCode)"
        ])

        guard isNoAuth else {
            return
        }

        tryHideBlockCell(cell)
    }

    func blockRenderSuccess(_ cell: BlockCell) {
        launchReporter.recordBlockEnd(id: cell.blockModel?.uniqueId.fullString, success: true)
    }

    func blockDidReceiveLogMessage(_ cell: BlockCell, message: WPBlockLogMessage) {
    }

    func blockContentSizeDidChange(_ cell: BlockCell, newSize: CGSize) {
        guard let layout = workPlaceCollectionView.collectionViewLayout as? WPTemplateLayout else {
            assertionFailure("[BLKH] invalid layout")
            return
        }
        guard let block = cell.blockModel, block.isAutoSizeBlock else {
            return
        }
        Self.logger.info("[BLKH] auto block size update: \(newSize), block: \(block.uniqueId)")
        layout.invalidateLayout()
    }

    func blockLongGestureShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return longGestureShouldBegin(gestureRecognizer)
    }

    func tryHideBlockCell(_ cell: BlockCell) {
        Self.logger.info("[LarkWorkplace] tryHideBlockCell", additionalData: [
            "isHideBlockForNoAuth": "\(isHideBlockForNoAuth)",
            "isShowBlockForNoAuthFg": "\(isShowBlockForNoAuthFg)",
            "isMainThread": "\(Thread.isMainThread)"
        ])
        
        // condition check
        guard isHideBlockForNoAuth, isShowBlockForNoAuthFg else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let model = cell.blockModel,
                  let layout = self.workPlaceCollectionView.collectionViewLayout as? WPTemplateLayout,
                  let groupComponents = self.groupComponents else {
                return
            }

            // update hideBlockModelArray
            let contains = self.hideBlockModelArray.contains { $0 == model }
            if contains {
                return
            }
            self.hideBlockModelArray.append(model)

            // delete from hideBlockModelArray
            self.groupComponents = self.filterHideBlockModel(from: groupComponents)

            // update UI
            layout.layoutModel = self.groupComponents ?? []
            self.workPlaceCollectionView.reloadData()
        }
    }
}

// MARK: 组件背景视图代理
extension TemplateViewController: CollectionViewGroupBackgroundDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: WPTemplateLayout,
        decorationDisplayedForSectionAt section: Int
    ) -> GroupBackgroundComponent? {
        if let groupExtras = groupComponents?[section].extraComponents {
            return groupExtras[.GroupBackground] as? GroupBackgroundComponent
        } else {
            return nil
        }
    }
}

extension TemplateViewController: WorkPlaceIconCellDelegate {
    func iconLongGestureShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return longGestureShouldBegin(gestureRecognizer)
    }

    /// 编辑态，点击右上角移除按钮，移除常用应用
    func deleteItem(_ cell: UICollectionViewCell) {
        guard let indexPath = workPlaceCollectionView.indexPath(for: cell) else { return }
        removeCommonApp(indexPath: indexPath)
    }

    /// 移除常用应用
    func removeCommonApp(indexPath: IndexPath) {
        guard let groups = groupComponents, indexPath.section < groups.count,
              let component = groups[indexPath.section] as? CommonAndRecommendComponent,
              indexPath.item < component.nodeComponents.count  else {
            Self.logger.error("try to remove app other than favorite apps")
            return
        }

        // 目前只支持 Block 和 ICON 的移除
        var deletedItemId: String?
        var deletedItemName: String = ""
        if let deletedIcon = component.nodeComponents[indexPath.item] as? CommonIconComponent,
           let model = deletedIcon.itemModel {
            deletedItemId = model.item.itemId
            deletedItemName = model.item.name
            reportRemoveIconBtnClick(model: model, subType: deletedIcon.appScene)
        } else if let deletedBlock = component.nodeComponents[indexPath.item] as? BlockComponent,
                  let model = deletedBlock.blockModel {
            deletedItemId = model.item.itemId
            deletedItemName = model.item.name
            reportRemoveBlockBtnClick(model: model)
        }
        Self.logger.info("remove common app \(deletedItemName), itemId: \(deletedItemId ?? "")")

        // UI 刷新
        component.removeComponent(at: indexPath.item, for: false)
        if component.checkNodeListIsEmpty() {
            // 常用组件内无应用，切换到空态
            commonAreaState = .normal
            component.switchToFavoriteEmptyState()
            workPlaceCollectionView.reloadSections([indexPath.section])
        } else {
            // 常用组件内还有应用，刷新 UI 状态
            workPlaceCollectionView.deleteItems(at: [indexPath])
        }

        // 后端数据同步，本地缓存同步
        guard let itemId = deletedItemId else { return }
        dataManager.removeCommonApp(itemId: itemId) { [weak self] in
            guard let `self` = self else { return }
            Self.logger.info("sync remove common app \(deletedItemName) success, itemId: \(itemId)")
            UDToast.showSuccess(
                with: BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_RemoveFrqSuccessToast,
                on: self.view
            )
            self.refreshCache()
        } failure: { error in
            Self.logger.error("sync remove common app \(deletedItemName) failed, itemId: \(itemId)", error: error)
        }
    }
}

// MARK: - 埋点相关
extension TemplateViewController {
    private func reportPageStayDurationIfNeeded() {
        rootDelegate?.tracker.trackPageStayDurationIfNeeded(.lowCode(initData), duration: pageStayDuration)
    }

    private func monitor_pageLaunchStart(scene: WorkplaceMonitorPortalRenderType) {
        context.monitor
            .start(.workplace_page_load)
            .setPortalRenderType(scene)
            .setPortalType(.lowCode)
            .setValue(enableUseCache, for: .use_cache)
            .flush()
    }

    private func monitorPageLoadSuccess(useCache: Bool, isRetry: Bool, monitor: WPMonitor) {
        context.monitor
            .start(.workplace_page_show_content)
            .setResultTypeSuccess()
            .setValue(initData.id, for: .portal_id)
            .setPortalType(.lowCode)
            .setPortalRenderType(isRetry ? .error_retry : .cold_boot)
            .setValue(useCache, for: .use_cache)
            .flush()
    }

    private func monitorPageLoadFail(
        isRetry: Bool,
        monitor: WPMonitor,
        failFrom: WPLoadTemplateError.WPLoadTemplateFailFrom,
        useCache: Bool
    ) {
        context.monitor
            .start(.workplace_page_show_error)
            .setResultTypeFail()
            .setValue(initData.id, for: .portal_id)
            .setPortalType(.lowCode)
            .setPortalRenderType(isRetry ? .error_retry : .cold_boot)
            .setTemplateFailFrom(failFrom)
            .setValue(useCache, for: .use_cache)
            .flush()
    }

    private func monitorShowErrorView() {
        context.monitor
            .start(.workplace_show_error_view)
            .setValue(initData.id, for: .portal_id)
            .setTemplateShowErrorFrom(.load_template)
            .flush()
    }

    private func monitorFirstStartScroll() {
        context.monitor
            .start(.workplace_template_first_start_scroll)
            .flush()
    }

    private func monitorFirstScreen(components: [WPFirstScreenComponent]) {
        let componentsArr = components.map({ $0.toDictionary() })
        guard let componentsData = try? JSONSerialization.data(withJSONObject: componentsArr, options: []),
              let jsonString = String(data: componentsData, encoding: .utf8) else {
            Self.logger.error("monitorFirstScreen: covert component data fail")
            return
        }

        context.monitor
            .start(.workplace_template_first_screen)
            .setValue(jsonString, for: .components)
            .flush()
    }

    private func monitorRefreshPageStart() {
        context.monitor
            .start(.workplace_template_start_refresh)
            .flush()
    }

    private func monitorRefreshPageSuccess() {
        context.monitor
            .start(.workplace_template_refresh_success)
            .setValue(initData.id, for: .portal_id)
            .flush()
    }

    private func monitorRefreshPageFail(failFrom: WPLoadTemplateError.WPLoadTemplateFailFrom) {
        context.monitor
            .start(.workplace_template_refresh_fail)
            .setValue(initData.id, for: .portal_id)
            .setTemplateFailFrom(failFrom)
            .flush()
    }
}

// MARK: - 常用应用/组件 header
extension TemplateViewController: WPCommonAppHeaderDelegate {
    func onTitleClick(_ view: WPCommonAppHeader, urlStr: String) {
        openTriLink(url: urlStr)
    }

    func onEditClick(view: WPCommonAppHeader, indexPath: IndexPath) {
        guard commonAreaState == .normal,
              let group = groupComponents?[indexPath.section] as? CommonAndRecommendComponent else {
            return
        }

        clearMovingItem()
        commonAreaState = .editing
        group.updateFavoriteAreaState(state: commonAreaState)
        UIView.animate(withDuration: 0) {
            self.workPlaceCollectionView.reloadSections([indexPath.section])
        }
        context.tracker
            .start(.openplatform_workspace_main_page_click)
            .setClickValue(.management)
            .setExposeUIType(.my_common_and_recommend)
            .setValue(initData.id, for: .template_id)
            .post()
    }

    func onAddClick(view: WPCommonAppHeader) {
        Self.logger.info("user tap addIcon to add common App page")
        openAddApp()
        context.tracker
            .start(.openplatform_workspace_main_page_click)
            .setClickValue(.add_app)
            .setExposeUIType(.my_common_and_recommend)
            .setValue(initData.id, for: .template_id)
            .post()
    }

    func onFinishEditClick(view: WPCommonAppHeader, indexPath: IndexPath) {
        guard commonAreaState == .editing,
              let group = groupComponents?[indexPath.section] as? CommonAndRecommendComponent else {
            return
        }
        clearMovingItem()
        commonAreaState = .normal
        group.updateFavoriteAreaState(state: commonAreaState)
        UIView.animate(withDuration: 0) {
            self.workPlaceCollectionView.reloadSections([indexPath.section])
        }
    }

    func onSubModuleSelected(subModuleIndex: Int, indexPath: IndexPath) {
        guard let components = groupComponents, indexPath.section < components.count,
              let group = components[indexPath.section] as? CommonAndRecommendComponent,
              subModuleIndex < group.subModuleList.count,
              group.subModuleList[subModuleIndex] != group.displaySubModule else { return }
        group.updateDisplayModule(index: subModuleIndex, isUserSelected: true)
        if group.displaySubModule == .recentlyUsed { reportUserSwitchToRecentlyUsedTab() }
        commonAreaState = .normal
        group.updateFavoriteAreaState(state: commonAreaState)
        UIView.animate(withDuration: 0) { // 避免 reload 时淡入淡出
            self.workPlaceCollectionView.reloadSections([indexPath.section])
            self.reportBlockExpose(collectionView: self.workPlaceCollectionView)
        }
    }

    func reportUserSwitchToRecentlyUsedTab() {
        context.tracker
            .start(.openplatform_workspace_main_page_click)
            .setExposeUIType(.recent_use)
            .setClickValue(.recent_use_tab)
            .setTargetView(.none)
            .post()
    }
}

// MARK: 拖拽相关
extension TemplateViewController {

    func longGestureShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer is UILongPressGestureRecognizer || gestureRecognizer is RightClickRecognizer else {
            return true
        }

        let touchPoint = gestureRecognizer.location(in: workPlaceCollectionView)
        guard let indexPath = workPlaceCollectionView.indexPathForItem(at: touchPoint),
              getCommonAndRecommendGroup(at: indexPath.section) != nil else {
                  /// 不是操作常用应用
            return true
        }

        guard commonAndRecommandLongPressIndexPath == nil || indexPath == commonAndRecommandLongPressIndexPath else {
            return false
        }

        commonAndRecommandLongPressIndexPath = indexPath
        return true
    }

    func beginMoveItem(gesture: UIGestureRecognizer) {
        // swiftlint:disable line_length
        guard let indexPath = workPlaceCollectionView.indexPathForItem(at: gesture.location(in: workPlaceCollectionView)),
              let group = getCommonAndRecommendGroup(at: indexPath.section),
              canMoveItem(at: indexPath) else {
            // swiftlint:enable line_length
                  return
        }
        /// 处理可拖拽  cell
        if let cell = workPlaceCollectionView.cellForItem(at: indexPath) as? WorkPlaceIconCell {
            cell.updatePressState(isPressed: true)
        }
        createMovingItemInfo(for: indexPath, gesture: gesture)
        commonComponentsBeforeDragging = group.nodeComponents
        startAutoSrollTimer()
    }

    func movingItem(with gesture: UIGestureRecognizer) {
        guard let movingItemInfo = movingCommonItemInfo else {
            /// 不可拖拽 cell
            return
        }

        let firstMove = !movingItemInfo.didCreateSnapshot
        if firstMove {
            let touchPointInView = gesture.location(in: workPlaceCollectionView)
            let moveTolerence: CGFloat = 8
            let touchTolerenceFrame: CGRect = CGRect(
                x: movingItemInfo.originTouchPoint.x - moveTolerence,
                y: movingItemInfo.originTouchPoint.y - moveTolerence,
                width: moveTolerence * 2,
                height: moveTolerence * 2
            )
            if touchTolerenceFrame.contains(touchPointInView) {
                /// 位移在容错值范围内，不触发拖动事件
                return
            }
        }

        longPressGestureAction = .dragAndMove
        cancelLongGestureTimer()

        if firstMove {
            if let cell = movingItemInfo.sourceCell as? WorkPlaceIconCell {
                cell.updatePressState(isPressed: false)
            }
            createMovingItemSnapshot()
        }

        guard let snapshotImage = movingItemInfo.snapshotImageView else {
            return
        }

        if firstMove {
            /// 开始拖动, 震动反馈
            let buzzFeedback = UIImpactFeedbackGenerator(style: .light)
            buzzFeedback.impactOccurred()
        }

        var imageViewFrame = snapshotImage.frame
        let touchPoint = gesture.location(in: workPlaceCollectionView)
        var point: CGPoint = .zero
        point.x = touchPoint.x - movingItemInfo.offset.x
        point.y = touchPoint.y - movingItemInfo.offset.y
        imageViewFrame.origin = point
        snapshotImage.frame = imageViewFrame

        guard let targetIndexPath = workPlaceCollectionView.indexPathForItem(
                at: gesture.location(in: workPlaceCollectionView)
            ), canExchangeItem(from: movingItemInfo.currentIndexPath, targetIndexPath: targetIndexPath) else {
            return
        }

        workPlaceCollectionView.moveItem(at: movingItemInfo.currentIndexPath, to: targetIndexPath)
        moveItemData(from: movingItemInfo.currentIndexPath, targetIndexPath: targetIndexPath)
        movingItemInfo.currentIndexPath = targetIndexPath
    }

    func moveItemFinished() {
        Self.logger.info("moveItemFinished")

        stopAutoScrollTimer()
        commonAndRecommandLongPressIndexPath = nil
        guard let movingItemInfo = movingCommonItemInfo else {
            return
        }
        if let iconCell = movingItemInfo.sourceCell as? WorkPlaceIconCell {
            iconCell.updatePressState(isPressed: false)
        }
        guard let snapshotImage = movingItemInfo.snapshotImageView else {
            clearMovingItem()
            return
        }

        UIView.animate(withDuration: 0.2) {
            snapshotImage.frame = movingItemInfo.sourceCell.frame
            // swiftlint:disable closure_body_length
        } completion: { [weak self]_ in
            guard let self = self else { return }
            movingItemInfo.sourceCell.isHidden = false
            var dragType: WorkplaceTrackFavoriteDragType = .icon
            if let iconCell = movingItemInfo.sourceCell as? WorkPlaceIconCell {
                iconCell.cellEndDragging()
                dragType = .icon
            } else if let blockCell = movingItemInfo.sourceCell as? BlockCell {
                blockCell.cellEndDragging()
                dragType = .block
            }
            snapshotImage.removeFromSuperview()

            self.movingCommonItemInfo = nil

            UIView.setAnimationsEnabled(false)
            self.workPlaceCollectionView.performBatchUpdates({ [weak self] in
                self?.workPlaceCollectionView.reloadData()
            }, completion: { (_) in
                UIView.setAnimationsEnabled(true)
            })

            if let group = self.getCommonAndRecommendGroup(at: movingItemInfo.currentIndexPath.section),
               let commonComponentsBeforeDragging = self.commonComponentsBeforeDragging,
               let result = self.createrRankResult(
                beforeDragging: commonComponentsBeforeDragging,
                afterDragging: group.nodeComponents
               ) {
                self.dataManager.updateCommonList(
                    updateData: result,
                    cacheModel: nil,
                    success: { [weak self] in
                        Self.logger.info("update dragging result successed")
                        self?.refreshCache()
                        self?.commonComponentsBeforeDragging = nil
                    },
                    failure: { error in
                        Self.logger.error("update dragging result failed", error: error)
                    }
                )
            }
            let status: WorkplaceTrackFavoriteStatus = self.commonAreaState == .normal ? .default : .edit
            self.context.tracker
                .start(.openplatform_workspace_main_page_sort_click)
                .setClickValue(.sort)
                .setTargetView(.none)
                .setFavoriteStatus(status)
                .setFavoriteDragType(dragType)
                .post()
        }
        // swiftlint:enable closure_body_length
    }

    func canMoveItem(at indexPath: IndexPath) -> Bool {
        guard let favoriteComponent = getCommonAndRecommendGroup(at: indexPath.section),
              let item = getNodeComponent(at: indexPath),
              favoriteComponent.displaySubModule != .recentlyUsed else {
            return false
        }

        return checkIsSortable(item: item)
    }

    func checkIsSortable(item: NodeComponent) -> Bool {
        if let iconComponent = item as? CommonIconComponent {
            return iconComponent.isSortable
        }
        return false
    }

    /// 判断常用区域是否可管理
    /// 如果只有管理员推荐应用，则不可管理
    func checkCommonAreaIsEditable(at section: Int) -> Bool {
        guard let group = getCommonAndRecommendGroup(at: section) else {
            return false
        }

        return group.isGroupManageable()
    }

    func getCommonAndRecommendGroup(at section: Int) -> CommonAndRecommendComponent? {
        guard let groupComponents = groupComponents,
              groupComponents.count > section else {
            return nil
        }
        return groupComponents[section] as? CommonAndRecommendComponent
    }

    func createMovingItemInfo(for indexPath: IndexPath, gesture: UIGestureRecognizer) {
        /// 先不创建截图，因为拖拽时需要隐藏标题和删除按钮
        guard let cell = workPlaceCollectionView.cellForItem(at: indexPath) else {
            return
        }

        let cellInViewFrame: CGRect = cell.frame
        let touchPointInView = gesture.location(in: workPlaceCollectionView)
        let offset = CGPoint(
            x: touchPointInView.x - cellInViewFrame.origin.x,
            y: touchPointInView.y - cellInViewFrame.origin.y
        )
        movingCommonItemInfo = WPMovingItemInfo(
            offset: offset,
            sourceCell: cell,
            currentIndexPath: indexPath,
            originTouchPoint: touchPointInView,
            snapshotImageView: nil
        )
    }

    func createMovingItemSnapshot() {
        guard let movingItemInfo = movingCommonItemInfo,
              let cell = workPlaceCollectionView.cellForItem(at: movingItemInfo.currentIndexPath) else {
            return
        }
        if let iconCell = cell as? WorkPlaceIconCell {
            iconCell.cellStartDragging()
            movingItemInfo.visibleAreaHeight = iconCell.iconView.frame.size.height
        } else if let blockCell = cell as? BlockCell {
            blockCell.cellStartDragging()
            movingItemInfo.visibleAreaHeight = blockCell.frame.size.height
        }
        let cellInViewFrame: CGRect = cell.frame
        let snapshotImageView = cell.snapshotView(afterScreenUpdates: true)
        snapshotImageView?.frame = cellInViewFrame
        movingItemInfo.snapshotImageView = snapshotImageView
        movingItemInfo.didCreateSnapshot = true

        if let snapshotImage = snapshotImageView {
            workPlaceCollectionView.addSubview(snapshotImage)
            cell.isHidden = true
        }
    }

    func canExchangeItem(from previousIndexPath: IndexPath, targetIndexPath: IndexPath) -> Bool {
        guard targetIndexPath.section == previousIndexPath.section,
              targetIndexPath.row != previousIndexPath.row,
              getCommonAndRecommendGroup(at: targetIndexPath.section) != nil else {
            return false
        }

        guard let targetNode = getNodeComponent(at: targetIndexPath),
              let previousNode = getNodeComponent(at: previousIndexPath),
              let targetCell = workPlaceCollectionView.cellForItem(at: targetIndexPath) else {
                  return false
              }
        // swiftlint:disable line_length
        if (targetCell.frame.minY < workPlaceCollectionView.contentOffset.y) || (targetCell.frame.maxY > workPlaceCollectionView.bounds.height + workPlaceCollectionView.contentOffset.y) {
            // swiftlint:enable line_length
            return false
        }

        if !checkIsSortable(item: targetNode) {
            return false
        }

        return targetNode.type == previousNode.type
    }

    func moveItemData(from previousIndexPath: IndexPath, targetIndexPath: IndexPath) {
        guard let group = getCommonAndRecommendGroup(at: previousIndexPath.section) else {
            return
        }
        group.moveComponent(to: targetIndexPath.row, previousIndex: previousIndexPath.row)
    }

    func checkIfMoveMeetsEdge() -> Bool {
        movingMeetsDirection = .none

        guard let movingItemInfo = movingCommonItemInfo,
              let snapShotImageView = movingItemInfo.snapshotImageView else {
              return false
        }

        let minY = snapShotImageView.frame.minY
        let maxY = snapShotImageView.frame.maxY
        if minY + movingItemInfo.visibleAreaHeight / 2 < workPlaceCollectionView.contentOffset.y {
            movingMeetsDirection = .top
            return true
        }
        // swiftlint:disable line_length
        if maxY - snapShotImageView.frame.size.height / 2 > workPlaceCollectionView.bounds.height + workPlaceCollectionView.contentOffset.y {
            // swiftlint:enable line_length
            movingMeetsDirection = .bottom
            return true
        }

        return false
    }

    func createrRankResult(beforeDragging: [NodeComponent], afterDragging: [NodeComponent]) -> UpdateRankResult? {
        var oldCommonWidgetItemList: [String] = []
        var oldCommonIconItemList: [String] = []
        var newCommonWidgetItemList: [String] = []
        var newCommonIconItemList: [String] = []

        beforeDragging.forEach { nodeComponent in
            if let iconComponent = nodeComponent as? CommonIconComponent,
               let itemId = iconComponent.itemModel?.itemID,
               !iconComponent.isRecommand {
                oldCommonIconItemList.append(itemId)
            }
            if let blockComponent = nodeComponent as? BlockComponent,
               let itemId = blockComponent.blockModel?.item.itemId,
               !blockComponent.isTemplateRecommand {
                oldCommonWidgetItemList.append(itemId)
            }
        }
        afterDragging.forEach { nodeComponent in
            if let iconComponent = nodeComponent as? CommonIconComponent,
               let itemId = iconComponent.itemModel?.itemID,
               !iconComponent.isRecommand {
                newCommonIconItemList.append(itemId)
            }
            if let blockComponent = nodeComponent as? BlockComponent,
               let itemId = blockComponent.blockModel?.item.itemId,
               !blockComponent.isTemplateRecommand {
                newCommonWidgetItemList.append(itemId)
            }
        }
        let isIconSame = newCommonIconItemList.elementsEqual(oldCommonIconItemList) { $0 == $1 }
        let isWidgetSame = newCommonWidgetItemList.elementsEqual(oldCommonWidgetItemList) { $0 == $1 }

        if isIconSame, isWidgetSame {
            Self.logger.info("item list is no modified, not need to update")
            return nil
        } else {
            Self.logger.info("item list is modified, need to update")
            return UpdateRankResult(
                newCommonWidgetItemList: newCommonWidgetItemList,
                originCommonWidgetItemList: oldCommonWidgetItemList,
                newCommonIconItemList: newCommonIconItemList,
                originCommonIconItemList: oldCommonIconItemList,
                newDistributedRecommendItemList: [],
                originDistributedRecommendItemList: []
            )
        }
    }

    func resetDragAction() {
        commonAndRecommandLongPressIndexPath = nil
        clearMovingItem()
        stopAutoScrollTimer()
        commonComponentsBeforeDragging = nil
    }

    func clearMovingItem() {
        if let movingItemInfo = movingCommonItemInfo {
            movingItemInfo.snapshotImageView?.removeFromSuperview()
            movingItemInfo.sourceCell.isHidden = false
        }
        movingCommonItemInfo = nil
    }
}
// swiftlint:enable file_length
