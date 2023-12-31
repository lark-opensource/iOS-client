//
//  BTController.swift
//  SKBitable
//
//  Created by maxiao on 2019/11/20.
//
// swiftlint:disable file_length

import UIKit
import SnapKit
import EENavigator
import SKCommon
import SKBrowser
import SKUIKit
import SKFoundation
import SKResource
import RxSwift
import UniverseDesignFont
import UniverseDesignColor
import UniverseDesignToast
import UniverseDesignActionPanel
import SpaceInterface
import LarkUIKit
import LarkSplitViewController
import UniverseDesignIcon
import Lottie

// 从controller传递下去的上下文，后续有需要就在这里加东西
struct BTContext {
    var id: String
    var shouldShowItemViewTabs: Bool
    var shouldShowAttachmentCover: Bool
    var shouldShowItemViewCatalogue: Bool
    var openRecordTraceId: String?
    var openBaseTraceId: String?
}

class BTController: UIViewController, UICollectionViewDelegate {

    lazy var loadingView: BTCardLoadingView = {
        let loading = BTCardLoadingView(frame: .zero)
        loading.isHidden = true
        loading.delegate = self
        return loading
    }()
    
    // MARK: Delegation

    weak var delegate: BTControllerDelegate?

    weak var spaceFollowAPIDelegate: SpaceFollowAPIDelegate?

    weak var uploader: BTUploadObservingDelegate?
    
    weak var geoFetcher: BTGeoLocationFetcher?

    let dismissAnimation = BTDismissAnimationController()

    let dismissTransition = BTDismissInteractionController()
    
    let presentAnimation = BTPresentAnimationController()
    
    //dismiss被取消或者失败时为true，不通知前端，其它情况均为false
    var hasDismissalFailed: Bool = false

    var dismissTransitionWasCancelled: Bool = false

    // MARK: Data Model

    var viewModel: BTViewModel

    var diffableDataSource: BitableTableDiffableDataSource? // 初始化时保证 meta、value 已拉到

    // MARK: Flags

    var hasDoneInitialScroll = false

    var shouldLocateToField = true
    
    var didLoadInitData = false

    private(set) var temporarilyHighlightField: (recordId: String, fieldId: String)?

    var didAppear = false

    var willAppear = false

    var willDisAppear = false
    var didDisAppear = false

    var needReloadCardsView = false

    // 是否已经通知前端卡片关闭
    private var hasNotifyFECardClose = false

    //当前卡片列表是否在滚动
    //在滚动过程中不处理update事件
    var recordIsScrolling = false
    
    //滚动过程中触发更新的model，需要保存下来，待滚动停止后再执行更新
    var appendingUpdateModel: BTTableModel?

    var isTransitioningSize = false

    // MARK: Subviews

    lazy var backgroundView = UIView()

    lazy var titleView = BTTableTitleView()
    
    var lastSwitchCardAction: (from: String, to: String) = (from: "", to: "")

    var currentOrientation: UIInterfaceOrientation = UIApplication.shared.statusBarOrientation

    lazy var cardsLayout = BTCardLayout(mode: viewModel.mode) // 初始化时保证 meta 已拉到
    
    /// 允许截图
    var allowCapture = true
    // context
    var context: BTContext {
        didSet {
            viewModel.context = context
            diffableDataSource?.context = context
        }
    }
    
    // 初始化时保证 meta、value 已拉到
    lazy var cardsView = BTRecordCollectionView(frame: .zero, collectionViewLayout: cardsLayout).construct { it in
        it.register(BTRecord.self, forCellWithReuseIdentifier: BTRecord.reuseIdentifier)
        it.delegate = self
        it.dataSource = diffableDataSource
        it.backgroundColor = .clear
        it.showsHorizontalScrollIndicator = false
        it.contentInsetAdjustmentBehavior = .never
        it.insetsLayoutMarginsFromSafeArea = false
        it.bounces = true
        it.alwaysBounceHorizontal = true
        it.context = context
        it.isScrollEnabled = false
    }
    
    // 卡片右下角翻页悬浮窗
    lazy var switchCardBottomPanelView = PaginationView(frame: .zero)
    
    lazy var submitView: BTSubmitView = {
        let view = BTSubmitView()
        view.update(iconType: .initial, animated: false)
        view.clickCallback = { [weak self] (view) in
            self?.didClickSubmitView()
        }
        return view
    }()
    
    var recordSubmitTimer: Timer?
    
    // 毛玻璃效果
    private lazy var switchCardBottomBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
    
    private var canSetSwitchCardBottomPanelViewState: Bool {
        let isNormalCard = viewModel.mode.isCard
        let isLinkCard = viewModel.mode.isLinkedRecord
        let isFiltered = currentCard?.recordModel.isFiltered ?? false
        let isEditingStatus = self.currentEditAgent != nil
        return (isNormalCard || isLinkCard) && !isFiltered && !isEditingStatus
    }
    
    private var shouldShowSubmitView: Bool {
        if viewModel.mode == .addRecord {
            guard UserScopeNoChangeFG.YY.baseAddRecordPage else {
                return false
            }
        } else if viewModel.mode == .submit {
            guard UserScopeNoChangeFG.YY.baseAddRecordPageShareEnable else {
                return false
            }
        }
        let isEditingStatus = self.currentEditAgent != nil
        return (viewModel.mode == .submit || viewModel.mode == .addRecord) && !isEditingStatus
    }
    
    lazy var animationView: LOTAnimationView = {
        let animation = AnimationViews.bitableStageCompleteAnimation
        animation.backgroundColor = UIColor.clear
        animation.loopAnimation = false
        animation.autoReverseAnimation = false
        animation.contentMode = .scaleAspectFill
        return animation
    }()
    
    lazy var stageNavigationView: SKDraggableTitleView = {
        let titleView = SKDraggableTitleView()
        titleView.bottomLine.isHidden = true
        titleView.topLine.isHidden = true
        titleView.titleLabel.isHidden = true
        titleView.rightButton.isHidden = true
        titleView.leftButton.setImage(UDIcon.leftOutlined, for: .normal)
        titleView.leftButton.addTarget(self, action: #selector(stageClickDismiss), for: .touchUpInside)
        return titleView
    }()
    
    // MARK: Others

    var defaultBackgroundColor: UIColor {
        viewModel.mode.isForm || UserScopeNoChangeFG.ZJ.btCardReform ? UDColor.bgBody : UDColor.bgBase
    }

    var orientationMask: UIInterfaceOrientationMask?

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        if viewModel.mode.isAddRecord, UserScopeNoChangeFG.YY.baseAddRecordPage {
            return [.portrait]
        }
        if viewModel.mode.isSubmitRecord, UserScopeNoChangeFG.YY.baseAddRecordPageShareEnable {
            return [.portrait]
        }
        if let linkingController = linkingController {
            return linkingController.supportedInterfaceOrientations
        }
        if let mask = orientationMask {
            return mask
        }
        return [.portrait, .landscape]
    }

    var pageOffset: CGFloat { cardsLayout.pageOffset }

    var currentCard: BTRecord? {
        var cell = cardsView.cellForItem(at: IndexPath(item: self.viewModel.currentRecordIndex, section: 0))
        if cell == nil, !UserScopeNoChangeFG.XM.cellForItemFixDisable {
            cardsView.layoutIfNeeded()
            cell = cardsView.cellForItem(at: IndexPath(item: self.viewModel.currentRecordIndex, section: 0))
        }
        return cell as? BTRecord
    }

    var currentCardHasAttachmentField: Bool {
        currentCard?.recordModel.wrappedFields.first(where: { $0.compositeType.uiType == .attachment }) != nil
    }

    var currentCardHasUserField: Bool {
        currentCard?.recordModel.wrappedFields.first(where: { $0.compositeType.uiType == .user }) != nil
    }
    var currentCardHasLinkField: Bool {
        currentCard?.recordModel.wrappedFields.first(where: { $0.compositeType.classifyType == .link }) != nil
    }
    // 用于异步进入字段编辑，异步类型：text number link
    var currentEditingField: BTFieldCellProtocol?

    var currentEditAgent: BTBaseEditAgent?
    
    // 当前附件预览的FiledID
    var currentPreviewAttachmentBTFieldID: String?
    var currentPreviewAttachmentToken: String?

    let keyboard = Keyboard()

    var keyboardHeight: CGFloat = 0

    var inputSuperviewDistanceToWindowBottom: CGFloat {
        SKDisplay.windowBounds(view).height - view.convert(view.bounds, to: nil).maxY
    }

    let watermarkConfig = WatermarkViewConfig()

    var hapticFeedbackGenerator: UISelectionFeedbackGenerator = UISelectionFeedbackGenerator()

    var startPanningY: CGFloat = -1

    weak var deleteActionSheet: UDActionSheet? //删除卡片弹框

    // 上一层卡片
    var linkingController: BTController?

    // 下一层关联卡片
    var linkedController: BTController?

    // 埋点用，双向关联 or 单向关联
    var linkFromType: BTFieldCompositeType?

    // 显示卡片的task，用来串行处理前端事件，保证事件能正常执行
    var showCardActionTask: BTCardActionTask?
    
    //当前卡片的index，用来做分页预加载请求，避免重复请求
    var currentPageIndex: Int?
    
    // 是否是最底层的卡片
    var isRootController: Bool = false
    
    // Ipad 适配时，下个状态在base文档区域的展示方式
    var nextCardPresentMode: CardPresentMode {
        guard let browserVC = self.delegate?.cardGetBrowserController() else {
            return .fullScreen
        }
        
        if showCardActionTask?.actionParams.data.openSource == .templatePreview {
            // 模版预览case下卡片全屏显示
            return .fullScreen
        }
        
        if viewModel.mode.isIndRecord {
            return .fullScreen
        }
        
        if browserVC.view.bounds.width >= 500 && SKDisplay.pad && BTNavigator.isReularSize(browserVC) {
            return .card
        } else {
            return .fullScreen
        }
    }
    
    // Ipad 适配时，当前状态在base文档区域的展示方式
    var currentCardPresentMode: CardPresentMode = .fullScreen
    
    // CardPresentMode为 .card 时，card的最小宽度
    let cardMinWidthOnCardMode: CGFloat = 420
    
    // CardPresentMode为 .card 时，card的宽度占表格宽度的比例
    let cardWidthPercentOnCardMode: CGFloat = 0.44
    
    private let basePermissionHelper: BasePermissionHelper
    
    let baseContext: BaseContext

    weak var currentOperateAttachmentCoverVC: UIViewController? = nil
    
    // 监控页面的View的上滑和下滑事件，隐藏翻页pagination
    var cardViewUIEventMonitor: BTUIEventMonitor?
    
    var isPushed: Bool {
        return UserScopeNoChangeFG.ZJ.btCardReform && SKDisplay.phone && !self.viewModel.mode.isIndRecord
    }
    var contentView = UIView().construct { it in
        it.backgroundColor = .clear
    }
    
    var emptyView = BTCardEmptyView()
    
    // 监控Frame的变化, 用于reload卡片
    var frameObserver: NSKeyValueObservation?
    
    // 是否需要在下次重新显示的时候关掉所有 card（例如发生了 terminate 但由于上层正在显示其他 Doc 因此不能直接立即关闭）
    var needCloseAllCardsWhenAppear: Bool = false
    
    /// 当前场景是否关闭：编辑触发自动订阅功能，默认为false
    var isCloseRecordAutoSubscribe: Bool = false
    
    // 是否编辑过 cellvalue
    var hasUnSubmitCellValue: Bool = false {
        didSet {
            updateToggleSwipeGestureIfNeeded()
        }
    }
    var edgePanGesture: UIScreenEdgePanGestureRecognizer?
    
    // MARK: - Life Cycle Events

    init(actionTask: BTCardActionTask,
         viewMode: BTViewMode? = nil,
         recordIDs: [String] = [],
         stageFieldId: String = "",
         delegate: BTControllerDelegate?,
         uploader: BTUploadObservingDelegate?,
         geoFetcher: BTGeoLocationFetcher?,
         baseContext: BaseContext,
         dataService: BTDataService?) {
        DocsLogger.btInfo("[LifeCycle] BTController initWithActionTask: \(actionTask.actionParams.action), viewMode: \(viewMode), recordIDs: \(recordIDs)")
        var mode: BTViewMode
        if let viewMode = viewMode {
            mode = viewMode
        } else {
            mode = .card
        }
        // 普通表会管ready状态，其他的都当做ready
        let bitableReady = mode == .card ? actionTask.actionParams.data.bitableIsReady : true
        self.context = BTContext(
            id: UUID().uuidString,
            shouldShowItemViewTabs: false,
            shouldShowAttachmentCover: false,
            shouldShowItemViewCatalogue: false,
            openRecordTraceId: nil,
            openBaseTraceId: nil
        )
        viewModel = BTViewModel(mode: mode,
                                recordIDs: recordIDs,
                                stageFieldId: stageFieldId,
                                dataService: dataService,
                                cardActionParams: actionTask.actionParams,
                                baseContext: baseContext,
                                bitableIsReady: bitableReady,
                                context: context)
        self.baseContext = baseContext
        self.delegate = delegate
        self.uploader = uploader
        self.geoFetcher = geoFetcher
        self.showCardActionTask = actionTask
        self.basePermissionHelper = BasePermissionHelper(baseContext: baseContext)
        super.init(nibName: nil, bundle: nil)
        viewModel.listener = self
        dismissAnimation.dismissingController = self
        dismissTransition.dismissingController = self
        presentAnimation.presentController = self
        hapticFeedbackGenerator.prepare()

        BTStatisticManager.shared?.allowedNormalStateDropDetect(isAllowed: true)
        viewModel.fpsTrace.startOpenRecordTraceAndAutoStop()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        BTFV2Const.debugEnable = !BTFV2Const.debugEnable
        DocsLogger.btInfo("[LifeCycle] BTController viewDidLoad: \(view)")
        view.backgroundColor = defaultBackgroundColor
        view.addSubview(contentView)
        view.addSubview(emptyView)
        emptyView.delegate = self
        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        watermarkConfig.add(to: view)
        diffableDataSource?.setCollectionView(cardsView)
        contentView.addSubview(cardsView)
        cardsView.bounces = !viewModel.bitableIsReady
        
        func setupSwitchCardBottomPanelView() {
            contentView.addSubview(switchCardBottomBlurView)
            contentView.addSubview(switchCardBottomPanelView)
            switchCardBottomPanelView.delegate = self
            switchCardBottomPanelView.snp.makeConstraints { make in
                make.bottom.equalToSuperview().offset(-40)
                make.right.equalToSuperview().offset(-16)
                make.height.equalTo(PaginationView.Const.containerH)
            }
            switchCardBottomBlurView.snp.makeConstraints { make in
                make.edges.equalTo(switchCardBottomPanelView)
            }
            switchCardBottomBlurView.clipsToBounds = true
            switchCardBottomBlurView.layer.cornerRadius = PaginationView.Const.cornerRadius
        }
        
        func setupSubmitView() {
            guard shouldShowSubmitView else {
                return
            }
            contentView.addSubview(submitView)
            submitView.snp.makeConstraints { make in
                make.bottom.equalToSuperview().offset(-40)
                make.right.equalToSuperview().offset(-16)
            }
        }
        
        switch viewModel.mode {
        case .link:
            if !UserScopeNoChangeFG.ZJ.btCardReform {
                contentView.addSubview(titleView)
                titleView.snp.makeConstraints { make in
                    make.left.top.right.equalToSuperview()
                }
                cardsView.snp.makeConstraints { make in
                    make.top.equalTo(titleView.snp.bottom)
                    make.left.equalTo(contentView.safeAreaLayoutGuide.snp.left)
                    make.bottom.equalTo(contentView.safeAreaLayoutGuide.snp.bottom)
                    make.right.equalTo(contentView.safeAreaLayoutGuide.snp.right)
                }
                contentView.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
            } else {
                cardsView.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
                if nextCardPresentMode == .card,
                   UserScopeNoChangeFG.ZJ.btItemViewPresentModeFixDisable {
                    contentView.snp.makeConstraints { make in
                        make.right.top.bottom.equalToSuperview()
                        make.left.equalToSuperview().offset(15)
                    }
                } else {
                    contentView.snp.makeConstraints { make in
                        make.top.bottom.equalToSuperview()
                        make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
                        make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
                    }
                }
                setupSwitchCardBottomPanelView()
                self.updateSwitchCardBottomPanelViewVisibility(visible: true)
                setBackgroundShadow()
            }
        case .card, .submit, .indRecord, .addRecord:
            cardsView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            if !UserScopeNoChangeFG.ZJ.btCardReform {
                contentView.snp.makeConstraints { make in
                    make.left.right.bottom.equalToSuperview()
                    make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
                }
            } else {
                if nextCardPresentMode == .card,
                   UserScopeNoChangeFG.ZJ.btItemViewPresentModeFixDisable {
                    contentView.snp.remakeConstraints { make in
                        make.right.top.bottom.equalToSuperview()
                        make.left.equalToSuperview().offset(15)
                    }
                } else {
                    contentView.snp.remakeConstraints { make in
                        make.top.bottom.equalToSuperview()
                        make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
                        make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
                    }
                }
                setupSwitchCardBottomPanelView()
                self.updateSwitchCardBottomPanelViewVisibility(visible: true)
                setBackgroundShadow()
                
                setupSubmitView()
            }
        case .stage:
            contentView.snp.makeConstraints {make in
                make.edges.equalToSuperview()
            }
            contentView.addSubview(stageNavigationView)
            contentView.backgroundColor = UDColor.bgBody
            stageNavigationView.snp.makeConstraints { make in
                make.left.equalTo(contentView.safeAreaLayoutGuide.snp.left)
                make.top.equalTo(contentView.safeAreaLayoutGuide.snp.top)
                make.right.equalTo(contentView.safeAreaLayoutGuide.snp.right)
            }
            cardsView.snp.makeConstraints { make in
                make.left.equalTo(contentView.safeAreaLayoutGuide.snp.left)
                make.right.equalTo(contentView.safeAreaLayoutGuide.snp.right)
                make.bottom.equalTo(contentView.safeAreaLayoutGuide.snp.bottom)
                make.top.equalTo(stageNavigationView.snp.bottom)
            }
        case .form:
            cardsView.snp.makeConstraints {make in
                make.edges.equalToSuperview()
            }
            contentView.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
                make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
            }
        }
        cardsView.clipsToBounds = false
        cardsView.isScrollEnabled = false
        reloadCardsView()
        
        keyboard.on(events: [.didShow, .willShow, .didHide]) { [weak self] (options) in
            self?.handleKeyboard(didTrigger: options.event, options: options)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(recoverVCOrientationAfterLandscpae), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)

        self.basePermissionHelper.startObserve(observer: self)
        
        addScreenPanGestureIfNeeded()
        if UserScopeNoChangeFG.XM.cardOpenLoadingEnable {
            view.addSubview(loadingView)
            loadingView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            // 表单和记录分享页不显示loading
            if viewModel.mode != .form &&
                viewModel.mode != .indRecord,
                viewModel.mode != .addRecord {
                showLoading(from: viewModel.mode)
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !hasDoneInitialScroll, !viewModel.mode.isForm, !viewModel.mode.isStage {
            DocsLogger.btInfo("[LifeCycle] BTController viewDidLayoutSubviews once")
            CATransaction.begin()
            CATransaction.setCompletionBlock { [weak self] in
                guard let self = self else { return }
                DocsLogger.btInfo("scrollToCurrentCard complete, \(self.shouldLocateToField)")
                if self.shouldLocateToField {
                    self.scrollToDesignatedFieldAndHighlight()
                }
                self.hasDoneInitialScroll = true
                self.updateVisibleCellsCaptureAllowedState()
            }
            scrollToCurrentCard()
            CATransaction.commit()
        }
        
        if !UserScopeNoChangeFG.QYK.btSideCardCloseFixDisable {
            if SKDisplay.pad, needReloadCardsView {
                self.cardsView.reloadData()
            }
        }
        
        switchCardBottomPanelView.updateTextLabel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DocsLogger.btInfo("[LifeCycle] BTController viewWillAppear")
        navigationController?.setNavigationBarHidden(true, animated: false) // 从外部网页退回到 bitable 时要把导航栏隐藏
        currentOrientation = UIApplication.shared.statusBarOrientation
        keyboard.start()
        willAppear = true
        willDisAppear = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DocsLogger.btInfo("[LifeCycle] viewWillDisappear")
        keyboard.stop()
        willDisAppear = true
    }
    
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
    }
    
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        
        if viewModel.mode == .submit, UserScopeNoChangeFG.YY.baseAddRecordPageShareEnable {
            setToggleSwipeGesture(navigationController: self.navigationController)
        } else if viewModel.mode == .addRecord {
            setToggleSwipeGesture(navigationController: self.delegate?.cardGetBrowserController()?.navigationController)
        }
        
        // cardVC 从 parent 移除时，清理卡片的状态
        guard UserScopeNoChangeFG.ZJ.btCardReform, parent == nil, willDisAppear else { return }
        self.afterRealDismissal()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.didDisAppear = false
        DocsLogger.btInfo("[LifeCycle] BTController viewDidAppear")
        self.startCardViewUIEventMonitor()
        if didAppear {
            viewModel.constructCardRequest(.update)
        } else {
            viewModel.openCardTracker?.trackTimestamp(type: .nativeShowCardTime)
            viewModel.endAndReportOpenCardEvent()
            viewModel.trackCardViewEvent()
            cardsView.isScrollEnabled = !UserScopeNoChangeFG.ZJ.btCardReform
            didAppear = true
            notifyFrontCardDidOpen()
            showCardActionTask?.completedBlock()
            showCardActionTask = nil
            
            if UserScopeNoChangeFG.QYK.btSideCardCloseFixDisable {
                // 这段代码下个版本会删除，请不要再修改内容
                // 临时区拖动时，卡片frame发生变化，需要重新调整offset
                if !UserScopeNoChangeFG.QYK.btCardOffsetErrorFixDisable {
                    self.frameObserver = view.observe(\.frame, options: [.new]) { [weak self] _, _  in
                        guard let self = self else { return }
                        DispatchQueue.main.async {
                            self.reloadCardsView()
                        }
                    }
                }
            }
            
            if !UserScopeNoChangeFG.ZJ.btItemViewPresentModeFixDisable {
                self.presentAnimation.maskView.addTarget(self, action: #selector(didClickMaskView), for: .touchUpInside)
            }
        }

        if needReloadCardsView {
            needReloadCardsView = false
            reloadCardsView()
        }
        if let token = viewModel.hostDocsInfo?.token {  // 电量统计场景，直接取宿主信息
            let scene: PowerConsumptionStatisticScene?
            let viewId = "\(ObjectIdentifier(self))"
            switch viewModel.mode {
            case .card, .link:
                scene = .bitableCardView(contextViewId: viewId)
            case .form:
                scene = .bitableFormView(contextViewId: viewId)
            case .submit, .stage, .indRecord, .addRecord:
                scene = nil
            }
            
            if let scene = scene {
                PowerConsumptionStatistic.markStart(token: token, scene: scene)
                let isInVc = viewModel.dataService?.isInVideoConference ?? false
                let inVCKey = PowerConsumptionStatisticParamKey.isInVC
                PowerConsumptionStatistic.updateParams(isInVc, forKey: inVCKey, token: token, scene: scene)
            }
        }
        
        if UserScopeNoChangeFG.QYK.btSideCardCloseFixDisable {
            self.closeCardWhenTabChanged()
        }
        
        if needCloseAllCardsWhenAppear {
            self.closeAllCards()
        }
        BTStatisticManager.shared?.allowedNormalStateDropDetect(isAllowed: true)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.didDisAppear = true
        self.stopCardViewUIEventMonitor()
        BTStatisticManager.shared?.allowedNormalStateDropDetect(isAllowed: false)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        DocsLogger.btInfo("[LifeCycle] BTController viewWillTransitionToSize: \(size)")
        isTransitioningSize = true
        let currentCardIndex = viewModel.currentRecordIndex
//        if let previousCardSize = cardsLayout.previousItemSize {
//            let estimatedXAfterTransition = CGFloat(currentCardIndex) * (previousCardSize.height + cardsLayout.minimumLineSpacing)
//            cardsView.setContentOffset(CGPoint(x: estimatedXAfterTransition, y: 0), animated: false)
//        }
        if SKDisplay.phone {
            currentEditAgent?.stopEditing(immediately: true, sync: true)
        }
        deleteActionSheet?.dismiss(animated: false)
        super.viewWillTransition(to: size, with: coordinator)
        cardReloadForTransition(size: size)
        coordinator.animate(alongsideTransition: { [self] _ in
            scrollToCurrentCard()
        }) { [self] _ in
            isTransitioningSize = false
            if self.willDisAppear {
                //页面不可见时调用reloadData无效，需要在可见时再刷新
                self.needReloadCardsView = true
            } else {
                self.reloadCardsView()
            }

            if UIApplication.shared.statusBarOrientation != currentOrientation {
                currentOrientation = UIApplication.shared.statusBarOrientation
                DocsLogger.btInfo("[ACTION] iPhone orientation changed, refetch data")
                self.orientationDidChange()
            }
            reloadCardsView()
        }
    }
     
    override func splitVCSplitModeChange(split: LKSplitViewController2) {
        // split 改版了，原先size发生变化会走 viewWillTransition
        super.splitVCSplitModeChange(split: split)
        reloadCardsView()
    }
    
    @objc func stageClickDismiss() {
        self.dismiss(animated: true) { [weak self] in
            self?.linkingController = nil
        }
    }

    // 如果你想关闭全部卡片，请不要直接调用该方法，请使用 closeAllCards 来处理，否则在多层卡片的场景下会 dismiss 不干净
    // 如果你只想关闭一层，推荐使用 closeThisCard，也可以使用该方法，但注意多测测
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        DocsLogger.btInfo("[LifeCycle] BTController dismiss animated: \(flag)")
        self.currentEditAgent?.stopEditing(immediately: true, sync: true)
        super.dismiss(animated: flag, completion: completion)
    }

    func afterRealDismissal() {
        let currentBaseID = viewModel.actionParams.data.baseId
        let currentTableID = viewModel.actionParams.data.tableId
        let originBaseID = viewModel.actionParams.originBaseID
        let originTableID = viewModel.actionParams.originTableID
        let callback = viewModel.actionParams.callback
        if let prevController = linkingController { // 关联卡片正在下滑
            let destinationBaseID = prevController.viewModel.actionParams.data.baseId
            let destinationTableID = prevController.viewModel.actionParams.data.tableId
            delegate?.cardLink(action: .backwardLinkTable,
                               originBaseID: originBaseID,
                               originTableID: originTableID,
                               sourceBaseID: currentBaseID,
                               sourceTableID: currentTableID,
                               destinationBaseID: destinationBaseID,
                               destinationTableID: destinationTableID,
                               callback: callback)
            prevController.linkedController = nil
            linkingController = nil
        } else { // 第 0 层卡片正在下滑
            notifyToFrontAndClearWhenDidClose()
        }
        DocsLogger.btInfo("[LifeCycle] BTController did close card with mode \(self.viewModel.mode)")
    }
    
    // 通知前端卡片已打开
    func notifyFrontCardDidOpen() {
        delegate?.cardDidOpen(self,
                              currentBaseID: viewModel.actionParams.data.baseId,
                              currentTableID: viewModel.actionParams.data.tableId,
                              originBaseID: viewModel.actionParams.originBaseID,
                              originTableID: viewModel.actionParams.originTableID,
                              isFormCard: viewModel.mode.isForm,
                              callback: viewModel.actionParams.callback)
    }
    
    // 通知前端第一层卡片已关闭。
    func notifyFrontCardDidClose() {
        delegate?.cardDidClickHeaderButton(self,
                                           action: .exit,
                                           currentBaseID: viewModel.actionParams.data.baseId,
                                           currentTableID: viewModel.actionParams.data.tableId,
                                           originBaseID: viewModel.actionParams.originBaseID,
                                           originTableID: viewModel.actionParams.originTableID,
                                           callback: viewModel.actionParams.callback)
    }
    
    // 通知前端第一层卡片关闭，并且清空 BTJSService 上的控制器
    func notifyToFrontAndClearWhenDidClose(shouldSetCardVcNil: Bool = true) {
        // 防止多次调用 afterRealDismissal()
        if !UserScopeNoChangeFG.QYK.btSwitchFormInSheetFixDisable, hasNotifyFECardClose {
            return
        }
        hasNotifyFECardClose = true
        notifyFrontCardDidClose()
        delegate?.cardDidClose(shouldSetCardVcNil: shouldSetCardVcNil)
    }
    
    // 根据 index 来获取对应的卡片
    func getCard(at index: Int) -> BTRecord? {
        let cell = cardsView.cellForItem(at: IndexPath(item: index, section: 0))
        return cell as? BTRecord
    }

    // interactive dismissal 会超过 MLeaksFinder 的判断时间，导致 MLeakFinder 误报内存泄漏
    @objc
    func willDealloc() -> Bool {
        return false
    }

    deinit {
        viewModel.fpsTrace.forceStopAndReportAll()
        if let openBaseTraceId = context.openBaseTraceId {
            BTStatisticManager.shared?.stopTrace(traceId: openBaseTraceId)
        }
        if let openRecordTraceId = context.openRecordTraceId {
            BTStatisticManager.shared?.stopTrace(traceId: openRecordTraceId)
        }

        DocsLogger.btInfo("[LifeCycle] BTController deinit")
        BTFieldLayoutCacheManager.shared.removeCache(with: context.id)
        keyboard.stop()
        if !UserScopeNoChangeFG.ZJ.btCardUpdateFieldActionFixDisable, 
           !hasNotifyFECardClose,
           isRootController {
            // 当卡片是最底层的，且关闭未通知到前端时需要补发事件
            DocsLogger.btInfo("[LifeCycle] BTController deinit notifyToFrontAndClearWhenDidClose")
            notifyToFrontAndClearWhenDidClose(shouldSetCardVcNil: false)
        }
        if let token = viewModel.hostDocsInfo?.token {  // 电量统计场景，直接取宿主信息
            let viewId = "\(ObjectIdentifier(self))"
            switch viewModel.mode {
            case .card, .link:
                PowerConsumptionStatistic.markEnd(token: token, scene: .bitableCardView(contextViewId: viewId))
            case .form:
                PowerConsumptionStatistic.markEnd(token: token, scene: .bitableFormView(contextViewId: viewId))
            case .submit, .stage, .indRecord, .addRecord:
                break
            }
        }
    }
    
    func addScreenPanGestureIfNeeded() {
        if !UserScopeNoChangeFG.ZYS.recordShareSwipeCloseDisable, viewModel.mode.isIndRecord {
            let gesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(swipeToCloseIndRecord(_:)))
            gesture.edges = .left
            view.addGestureRecognizer(gesture)
        }
    }
    
    
    @objc
    func swipeToCloseIndRecord(_ gesture: UIScreenEdgePanGestureRecognizer) {
        guard gesture.state == .ended else {
            return
        }
        let translation = gesture.translation(in: view)
        let progress = translation.x / (view.bounds.width)
        if progress >= 0.2 {
            // 滑动到屏幕宽度 1/5，关闭卡片
            closeThisCard()
        }
    }
    
    // MARK: - For Override
    func updateVisibleCellsCaptureAllowedState() {}
}

extension BTController {

    func updateForm() {
        viewModel.updateForm()
    }

    func respond(to newActionTask: BTCardActionTask) {
        let currentTableID = viewModel.actionParams.data.tableId
        DocsLogger.btInfo("[SYNC] \(currentTableID) controller responds to \(newActionTask.actionParams.action.rawValue)")
        
        // 1. 对于一些特殊事件，无需校验 baseID 和 tableID，直接在本层响应

        // 如果是 closeCard 事件，前端不会传 id 过来，我们就放心关卡片就好了
        if newActionTask.actionParams.action == .closeCard {
            DocsLogger.btInfo("[SYNC] action is closeCard，turning to viewModel")
            viewModel.respond(to: newActionTask)
            return
        }
        
        if viewModel.mode.isForm && newActionTask.actionParams.action == .showCard {
            DocsLogger.btInfo("[SYNC] action is showForm，turning to viewModel")
            viewModel.respond(to: newActionTask)
            return
        }

        if newActionTask.actionParams.action == .scrollCard {
            DocsLogger.btInfo("[SYNC] action is scrollCard，turning to viewModel")
            viewModel.respond(to: newActionTask)
            return
        }
        
        if newActionTask.actionParams.action == .formFieldsValidate {
            DocsLogger.btInfo("[SYNC] action is formFieldsValidate，turning to viewModel")
            viewModel.respond(to: newActionTask)
            return
        }
        
        if newActionTask.actionParams.action == .fieldsValidate,
            newActionTask.actionParams.data.stackViewId == viewModel.tableMeta.stackViewId {
            DocsLogger.btInfo("[SYNC] action is formFieldsValidate，turning to viewModel")
            viewModel.respond(to: newActionTask)
            return
        }
        
        if newActionTask.actionParams.action == .bitableIsReady {
            DocsLogger.btInfo("[SYNC] action is bitableIsReady，turning to viewModel")
            viewModel.respond(to: newActionTask)
            return
        }
        
        if viewModel.mode.isForm && newActionTask.actionParams.action == .setCardHidden {
            DocsLogger.btInfo("[SYNC] action is setCardHidden，turning to viewModel")
            viewModel.respond(to: newActionTask)
            return
        }
        
        if viewModel.mode.isForm && newActionTask.actionParams.action == .setCardVisible {
            DocsLogger.btInfo("[SYNC] action is setCardHidden，turning to viewModel")
            viewModel.respond(to: newActionTask)
            return
        }

        // 移动到 TableViewModel 中
        // tableRecordsDataLoaded 代表关联表数据已完成前端加载，可以开始请求前端数据了
        // 它比较特殊，传过来的 payload 里面的 baseID 和 tableID 是关联表的，而不是当前表格的，所以过不了 id 校验，所以需要特殊处理
        if newActionTask.actionParams.action == .tableRecordsDataLoaded {
            DocsLogger.btInfo("[SYNC] action is tableRecordsDataLoaded，checking hierarchy")
             //当前有正在等待打开的关联编辑面板
            if let linkEditAgent = currentEditAgent as? BTLinkEditAgent,
               let linkField = currentEditingField as? BTFieldLinkCellProtocol,
               !linkEditAgent.isEditing,
               linkField.fieldModel.property.tableId == newActionTask.actionParams.data.tableId {
                DocsLogger.btInfo("[SYNC] found pending link edit agent, start editing")
                linkEditAgent.startEditing(linkField)
                newActionTask.completedBlock()
                return
            }

             //当前有正在等待打开的关联记录卡片
            if let linkedController = linkedController {
                if linkedController.presentingViewController == nil,
                   (!UserScopeNoChangeFG.ZJ.btCardReform || linkedController.navigationController == nil),
                   newActionTask.actionParams.data.tableId == linkedController.viewModel.actionParams.data.tableId { // 只要发现这一层有未 present 的 controller，就去 present
                    presentPendingLinkController(linkedController, newActionTask)
                } else { // 否则说明是其他层的卡片有待 present 的卡片，将信息继续往上传递
                    DocsLogger.btInfo("[SYNC] linked controller for \(currentTableID) not in this layer, going up")
                    linkedController.respond(to: newActionTask)
                }
                return
            }
            newActionTask.completedBlock()
            return
        }
        
        if UserScopeNoChangeFG.ZJ.btLinkPanelCreatRecordOpt,
           newActionTask.actionParams.action == .showLinkCard,
           let fieldModel = viewModel.tableModel.getRecordModel(id: viewModel.currentRecordID)?.getFieldModel(id: newActionTask.actionParams.data.fieldId) {

            var linkRecordIds = fieldModel.linkedRecords.compactMap({ $0.recordID })
            if fieldModel.property.multiple {
                if !linkRecordIds.contains(where: { $0 == newActionTask.actionParams.data.recordId}) {
                    linkRecordIds.append(newActionTask.actionParams.data.recordId)
                }
            } else {
                linkRecordIds = [newActionTask.actionParams.data.recordId]
            }
            
            openLinkedRecord(withID: newActionTask.actionParams.data.recordId,
                             allLinkedRecordIDs: linkRecordIds,
                             linkFieldModel: fieldModel)
            
            linkedController?.viewModel.updateCurrentRecordID(newActionTask.actionParams.data.recordId)
            newActionTask.completedBlock()
            return
        }
        
        // 2. 特殊情况处理完后，开始进行校验

        // 如果当前层不是受影响的 table，则向上传递
        guard newActionTask.actionParams.data.tableId == currentTableID else {
            DocsLogger.btInfo("[SYNC] this layer is \(currentTableID), not \(newActionTask.actionParams.data.tableId), going up")
            // 当前有正在打开的关联编辑面板
            if let linkEditAgent = currentEditAgent as? BTLinkEditAgent {
                DocsLogger.btInfo("[SYNC] found active link edit agent, turning to it")
                linkEditAgent.respond(to: newActionTask.actionParams)
            }

            // 当前有正在打开的关联记录卡片
            if let linkedController = linkedController {
                DocsLogger.btInfo("[SYNC] found existed linked controller, turning to it")
                linkedController.respond(to: newActionTask)
                return
            }
            newActionTask.completedBlock()
            return
        }
        
        // 当切换卡片时，结束编辑，防止编辑信息转移到下一张卡片上
        if UserScopeNoChangeFG.ZJ.btCardReform, newActionTask.actionParams.action == .showCard,
            newActionTask.actionParams.data.recordId != self.viewModel.currentRecordID, self.isEditingStatus {
            self.didStopEditing()
        }
        
        let preSubmit = self.viewModel.mode == .submit
        if UserScopeNoChangeFG.YY.baseAddRecordPageShareEnable {
            if newActionTask.actionParams.action == .showCard, preSubmit {
                // 记录提交 -> 记录详情（提交后跳转）
                unlockViewEditingAfterRecordSubmit()
                self.hasUnSubmitCellValue = false
                updateSubmitViewVisibility(visible: false, animation: true)
            } else if newActionTask.actionParams.action == .showManualSubmitCard {
                // 记录详情 -> 记录提交（继续添加）
                self.hasUnSubmitCellValue = false
                // 按设计师要求，这里做一个淡入的过渡动画
                updateSubmitViewVisibility(visible: true, forceVisible: true, animation: true)
                submitView.update(iconType: .initial, animated: false)
            }
        }
        
        // 通过校验，本层 view model 响应
        viewModel.respond(to: newActionTask)
        
        if UserScopeNoChangeFG.YY.baseAddRecordPageShareEnable,
            preSubmit,
            newActionTask.actionParams.action == .showCard,
            newActionTask.actionParams.data.preMockRecordId.isEmpty == false
        {
            handleSubmitSuccess(newActionTask: newActionTask)
        }

        // 本层处理完后，关联面板关联的tableId跟本层一样则需要继续处理
        // TODO 5.24版本仅上线全量版本，关联表格的数据更新仍走linkTableChanged事件，
        // 等后续上线按需版本后关联表格的数据更新会走updateField、updateRecord事件，会去掉linkTableChanged事件
//        if let linkEditAgent = currentEditAgent as? BTLinkEditAgent {
//            DocsLogger.btInfo("[SYNC] found active link edit agent, turning to it")
//            linkEditAgent.respond(to: newActionTask.actionParams)
//            newActionTask.completedBlock()
//            return
//        }
        
        // 本层处理完后，上层可能还有这个 table 的关联卡片（ A -> B -> A ），所以要继续向上抛
        if let linkedController = linkedController {
            DocsLogger.btInfo("[SYNC] \(currentTableID) controller finish responding, going up for potential layer for \(newActionTask.actionParams.data.tableId)")
            linkedController.respond(to: newActionTask)
            return
        }
    }
    
    private func handleSubmitSuccess(newActionTask: BTCardActionTask) {
        let recordId = newActionTask.actionParams.data.recordId
        // Base 内提交跳转详情
        if UserScopeNoChangeFG.YY.baseAddRecordPageAutoSubscribeEnable {
            // 触发自动订阅
            self.viewModel.dataService?.triggerRecordSubscribeForSubmitIfNeeded(recordId: recordId)
        }
        
        // 埋点 ccm_bitable_record_create_click
        var trackParams = viewModel.getCommonTrackParams()
        trackParams["click"] = "submit_success"
        trackParams["target"] = "none"
        DocsTracker.newLog(enumEvent: .bitableRecordCreateClick, parameters: trackParams)
    }
    
    func presentPendingLinkController(_ linkedController: BTController, _ showAction: BTCardActionTask) {
        DocsLogger.btInfo("[SYNC] found pending linked controller, kick off")
        linkedController.linkingController = self
        linkedController.showCardActionTask = showAction
        if !UserScopeNoChangeFG.XM.cardOpenLoadingEnable {
            linkedController.viewModel.kickoff()
        }
        linkedController.spaceFollowAPIDelegate = self.spaceFollowAPIDelegate
        
        var trackParams = viewModel.getCommonTrackParams()
        trackParams["click"] = "expand"
        trackParams["target"] = "ccm_bitable_card_view"
        trackParams["field_type"] = linkedController.linkFromType?.fieldTrackName ?? "" // 移到 table view model 中
        DocsTracker.newLog(enumEvent: .bitableCardLinkFieldClick, parameters: trackParams)
        linkedController.respond(to: showAction)
        if UserScopeNoChangeFG.XM.cardOpenLoadingEnable {
            presentLinkedController(linkedController)
        }
    }

    func presentLinkedController(_ linkedController: BTController) {
        let wrapperController = BTNavigationController(rootViewController: linkedController)
        // 第 0 层卡片使用 BTJSService+Card.swift 里面设定的 .overFullScreen， vc场景下需要用.overCurrentContext
        // 但是关联卡片的打开一定使用 .fullScreen，不能用 .overFullScreen，vc场景下需要用.currentContext
        // 否则打开十层关联卡片时时内存占用暴涨（每打开一层+20MB）、转屏分屏事件传递也很慢
        let isInVCFollow = self.spaceFollowAPIDelegate != nil
        if UserScopeNoChangeFG.ZJ.btCardReform {
            wrapperController.modalPresentationStyle = (isInVCFollow || SKDisplay.pad) ? .currentContext : .fullScreen
        } else {
            wrapperController.modalPresentationStyle = isInVCFollow ? .currentContext : .fullScreen
        }
        wrapperController.transitioningDelegate = linkedController
        if !UserScopeNoChangeFG.ZJ.btCardReform {
            Navigator.shared.present(wrapperController, from: self) { _ in
                linkedController.showCardActionTask?.completedBlock()
            }
        } else {
            let complete: EENavigator.Completion = { linkedController.showCardActionTask?.completedBlock() }
            self.navigationController?.pushViewController(linkedController, animated: true, completion: complete)
        }
        if UserScopeNoChangeFG.XM.cardOpenLoadingEnable {
            linkedController.viewModel.kickoff()
        }
    }

    func loadInitialModel(_ tableModel: BTTableModel) {
        self.context.shouldShowItemViewTabs = viewModel.shouldShowItemViewTabs
        self.context.shouldShowAttachmentCover = viewModel.shouldShowAttachmentCover
        self.context.shouldShowItemViewCatalogue = viewModel.shouldShowItemViewCatalogue
        self.didLoadInitData = true
        if viewModel.mode.isStage, tableModel.cardCloseReason == .stageFieldInvalid {
            // 边缘case，阶段字段已被删除，打开后需要立刻就关闭
            DocsLogger.btInfo("[SYNC] stageField has been deleted, should not show detail")
            if let window = self.linkingController?.view.window {
                UDToast.showFailure(with: "BundleI18n.SKResource.Bitable_Flow_FieldSetup_LinkedFieldNotExist_Desc", on: window)
                self.linkingController = nil
            }
            return
        }
        diffableDataSource = BitableTableDiffableDataSource(initialModel: tableModel, delegate: self, viewMode: viewModel.mode, context: context)
        diffableDataSource?.bitableIsReady = viewModel.bitableIsReady
        if diffableDataSource?.recordsCollectionView == nil { // 表单会走到这里
            diffableDataSource?.setCollectionView(cardsView)
        }
        if viewModel.mode.isLinkedRecord || viewModel.mode.isStage,
            let linkingController = linkingController {
            if !UserScopeNoChangeFG.XM.cardOpenLoadingEnable {
                // linkController也是先push再kickoff
                linkingController.presentLinkedController(self)
            }
            if UserScopeNoChangeFG.XM.cardOpenLoadingEnable {
                reloadCardsView()
                DispatchQueue.main.async {
                    if self.shouldLocateToField {
                        self.scrollToDesignatedFieldAndHighlight()
                    }
                    self.checkHideLoading()
                }
            }
            
        } else {
            delegate?.cardDidLoadInitialData(isFormCard: viewModel.mode.isForm)
            if UserScopeNoChangeFG.XM.cardOpenLoadingEnable {
                reloadCardsView()
                DispatchQueue.main.async {
                    if self.shouldLocateToField {
                        self.scrollToDesignatedFieldAndHighlight()
                    }
                }
            }
        }
    }
    
    func showBitableNotReadyToast() {
        if !viewModel.bitableIsReady, let window = view.window {
            let config = UDToastConfig(toastType: .info, text: BundleI18n.SKResource.Bitable_Record_LoadingCannotView_Mobile, operation: nil)
            UDToast.showToast(with: config, on: window)
        }
    }
    
    func notifyBitableIsReady() {
        DispatchQueue.main.async {
            self.cardsView.bounces = false
            self.diffableDataSource?.bitableReady()
            self.reloadCardsView()
//            self.scrollToDesignatedFieldAndHighlight()

            if !self.viewModel.hasTTU {
                self.viewModel.hasTTU = true
                if let traceId = self.context.openRecordTraceId {
                    BTOpenRecordReportHelper.reportBitableReady(traceId: traceId)
                    BTOpenRecordReportHelper.reportTTU(traceId: traceId)
                }
                if let traceId = self.context.openBaseTraceId {
                    if self.viewModel.mode == .form {
                        BTOpenFileReportMonitor.reportOpenFormTTU(traceId: traceId)
                    } else if self.viewModel.mode == .indRecord {
                        BTOpenFileReportMonitor.reportOpenShareRecordTTU(traceId: traceId)
                    }
                }
            }
        }
    }
    
    func reloadCardsView() {
        self.cardsView.reloadData()
        if !viewModel.mode.isForm {
            scrollToCurrentCard()
        }
        if UserScopeNoChangeFG.XM.cardOpenLoadingEnable {
            checkHideLoading()
        }
    }
    
    func checkHideLoading() {
        let mode = viewModel.mode
        guard diffableDataSource?.latestSnapshot.items.count ?? 0 > 0 else {
            DocsLogger.btInfo("[BTController] force loading form \(viewModel.mode.description)  items is tempty")
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
                guard let self = self else { return }
                // 避免出现意外loading盖着不隐藏
                self.hideLoading(from: mode, force: true)
            }
            return
        }
        hideLoading(from: mode)
    }

    func updateModel(_ tableModel: BTTableModel, completion: ((Bool) -> Void)? = nil) {
        self.context.shouldShowItemViewTabs = viewModel.shouldShowItemViewTabs
        self.context.shouldShowAttachmentCover = viewModel.shouldShowAttachmentCover
        self.context.shouldShowItemViewCatalogue = viewModel.shouldShowItemViewCatalogue
        if linkedController == nil { // 如果当前是顶层卡片
            let newRecordIDs = tableModel.records.map { $0.recordID }
            if viewModel.mode.isStage, tableModel.cardCloseReason == .stageFieldInvalid {
                // 当前阶段详情的record没有field，表示被删了或者因为高级权限不可见了
                DocsLogger.btInfo("[SYNC] deleted current stageField")
                if let window = view.window {
                    UDToast.showFailure(with: "BundleI18n.SKResource.Bitable_Flow_FieldSetup_LinkedFieldNotExist_Desc", on: window)
                    closeThisCard()
                }
                return
            }
            if viewModel.mode.isLinkedRecord, !newRecordIDs.contains(viewModel.currentRecordID) { // 现在正在查看的关联记录已经被删掉了
                DocsLogger.btInfo("[SYNC] deleted linked record")
                if let window = view.window {
                    UDToast.showFailure(with: BundleI18n.SKResource.Bitable_Record_DeletedByOtherUser, on: window)
                    closeThisCard()
                }
                return
            }
            DocsLogger.btInfo("[SYNC] begin updating data for \(tableModel.tableID), " +
                              "recordIds: \(newRecordIDs.joined(separator: ", ")), " +
                              "recordsCount: \(tableModel.records.count)")

            guard !recordIsScrolling else {
                appendingUpdateModel = tableModel
                cardsLayout.isUpdatingData = false
                DocsLogger.btInfo("[SYNC] begin updating data recordList is scrolling not update")
                return
            }
            let attachmentCoverChanged = diffableDataSource?.attachmentCoverChanged(tableModel) ?? false
            if attachmentCoverChanged {
                currentOperateAttachmentCoverVC?.dismiss(animated: true)
            }
            let hasChanged = diffableDataSource?.acceptSnapshot(tableModel, completion: completion) ?? false
            if hasChanged,
               hasDoneInitialScroll,
               viewModel.mode.needScrollToCurrentCardAfterUpdate {
                scrollToCurrentCard()
            }
            if UserScopeNoChangeFG.XM.cardOpenLoadingEnable {
                DispatchQueue.main.async {
                    if self.shouldLocateToField {
                        self.scrollToDesignatedFieldAndHighlight()
                    }
                    self.checkHideLoading()
                }
            }
        } else { // 在 didAppear 里处理
            DocsLogger.btInfo("[SYNC] begin updating data for \(tableModel.tableID), not in view hierarchy, ignore")
        }
    }

    private func orientationDidChange() {
        delegate?.card(self,
                       tableID: self.viewModel.actionParams.data.tableId,
                       viewID: self.viewModel.actionParams.data.viewId,
                       didChangeOrientationTo: UIDevice.current.orientation)
    }
    
    //iOS16横屏下present分享表单VC之后，会自动转到竖屏，但是cardview的collectionCell还是横屏布局，原因是没有调用viewWillTransation，进而没有触发reloadData和更新FieldModel中cell的布局信息，这里在分享VCpresent成功后，执行viewWillTransation里的动作
    //bitable@docx，横屏下下拉卡片，由于docx不支持横屏，所以系统会被强制转到竖屏，但是没有调用viewWillTransation，需要监听系统转屏事件重新刷新下布局
    @objc
    public func recoverVCOrientationAfterLandscpae() {
        if UIApplication.shared.statusBarOrientation != currentOrientation,
           UIApplication.shared.statusBarOrientation != .unknown {
            if SKDisplay.phone {
                currentEditAgent?.stopEditing(immediately: true, sync: true)
            }
            deleteActionSheet?.dismiss(animated: false)
            currentOrientation = UIApplication.shared.statusBarOrientation
            DocsLogger.btInfo("[ACTION] recoverVCOrientationAfterLandscpae, refetch data")
            self.orientationDidChange()
            self.reloadCardsView()
        }
    }

    func scrollToCurrentCard(animated: Bool = false, completion: (() -> Void)? = nil) {
        scrollToDesignatedCard(at: viewModel.currentRecordIndex, animated: animated, completion: completion)
        /// 更新悬浮窗下标
        switchCardBottomPanelView.updateTextLabel()
    }

    public func scrollToDesignatedCard(at index: Int, animated: Bool = false, completion: (() -> Void)? = nil) {
        // 如果当前就是这张卡片，就不需要滚动了，不然 setContentOffset 会导致多余的
        guard let pageCount = diffableDataSource?.getRecordCount(),
              0 <= index, index < pageCount, pageOffset >= 0,
              index < cardsView.numberOfItems(inSection: 0) else { return }

        CATransaction.begin()
        cardsView.setContentOffset(
            CGPoint(x: CGFloat(index) * pageOffset, y: 0),
            animated: animated
        )
        cardsView.scrollToItem(
            at: IndexPath(item: index, section: 0),
            at: .centeredHorizontally,
            animated: animated
        )
        CATransaction.setCompletionBlock(completion)
        CATransaction.commit()
    }

    public func scrollToCardField(fieldID: String) {
        currentCard?.scrollToField(with: fieldID, scrollPosition: [.top, .centeredHorizontally], animated: false)
        didScrollToField(id: fieldID, recordID: currentCard?.recordID ?? "")
        DocsLogger.btInfo("[ACTION] scrollToCardField fieldID: \(fieldID)")
    }

    private func scrollToDesignatedFieldAndHighlight() {
        guard let currentCard = currentCard else { 
            DocsLogger.btError("scrollToDesignatedFieldAndHighlight failed, current card not found")
            return 
        }
        let fieldId = viewModel.actionParams.data.fieldId
        let recordId = viewModel.actionParams.data.recordId
        let groupValue = viewModel.actionParams.data.groupValue
        guard let focusFieldIndex = currentCard.getFieldIndex(forFieldID: fieldId) else {
            DocsLogger.btError("[ACTION] cannot find opening fieldID \(viewModel.actionParams.data.fieldId)")
            return
        }

        DocsLogger.btInfo("[ACTION] scrollToDesignatedFieldAndHighlight start")
        
        // 首次打开定位到指定字段
        if fieldId != currentCard.recordModel.primaryFieldID {
            // 定位的是主键则不需要滚动，否则滚动到对应字段
            DocsLogger.btInfo("[ACTION] scroll to location field: \(fieldId)")
            currentCard.scrollToField(with: viewModel.actionParams.data.fieldId,
                                      scrollPosition: [.top, .centeredHorizontally],
                                      needAddHeaderOffset: true,
                                      animated: false)
            didScrollToField(id: viewModel.actionParams.data.fieldId, recordID: currentCard.recordID)
        }
        shouldLocateToField = false
        
        if UserScopeNoChangeFG.ZYS.recordCardV2 {
            // 旧版的 Cell 高亮有问题，新版使用新的逻辑
            // 1. 如果 cell 此时是不可见的，记录下需要高亮的 cell，在 cell willDisplay 时设置高亮
            // 2. 记录在 VC 里而不是 BTRecord 里，是因为 Cell 会重用，记录的状态可能会被清掉或者不准
            switch viewModel.actionParams.data.highLightType {
            case .none:
                break
            case .temporary:
                UIView.animate(withDuration: 1) {
                    self.temporarilyHighlightField = (recordId, fieldId)
                    if let recordIdxPath = self.diffableDataSource?.getIndexPathForRecord(recordId: recordId, groupValue: groupValue),
                       let recordCell = self.cardsView.cellForItem(at: recordIdxPath) as? BTRecord,
                       let index = recordCell.getFieldIndex(forFieldID: fieldId),
                       let fieldCell = recordCell.fieldsView.cellForItem(at: IndexPath(row: index, section: 0)) as? BTFieldCellProtocol {
                        fieldCell.updateContainerHighlight(true)
                    }
                } completion: { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        UIView.animate(withDuration: 1) { [weak self] in
                            self?.temporarilyHighlightField = nil
                            if let recordIdxPath = self?.diffableDataSource?.getIndexPathForRecord(recordId: recordId, groupValue: groupValue),
                               let recordCell = self?.cardsView.cellForItem(at: recordIdxPath) as? BTRecord,
                               let index = recordCell.getFieldIndex(forFieldID: fieldId),
                               let fieldCell = recordCell.fieldsView.cellForItem(at: IndexPath(row: index, section: 0)) as? BTFieldCellProtocol {
                                fieldCell.updateContainerHighlight(false)
                            }
                        }
                    }
                }
            }
            return
        }
        currentCard.highlightFieldIfNeeded(at: IndexPath(row: focusFieldIndex, section: 0), mode: viewModel.actionParams.data.highLightType)
    }

    private func handleKeyboard(didTrigger event: Keyboard.KeyboardEvent, options: Keyboard.KeyboardOptions) {
        switch event {
        case .didHide:
            keyboardHeight = 0
        case .didShow, .willShow:
            keyboardHeight = max(options.endFrame.height - inputSuperviewDistanceToWindowBottom, 0)
        default:
            ()
        }
    }
    
    // 适配Ipad右侧弹出卡片的阴影
    func setBackgroundShadow() {
        
        if !UserScopeNoChangeFG.QYK.btSideCardCloseFixDisable, SKDisplay.pad {
            self.navigationController?.view.layer.ud.setShadow(type: .s4Down)
            self.navigationController?.view.layer.masksToBounds = false
            return
        }
        
        /// 下面这段代码将要在下个版本删除
        if currentCardPresentMode == .card || (SKDisplay.pad && viewModel.mode.isLinkedRecord) {
            self.view.backgroundColor = .clear
            self.cardsView.backgroundColor = defaultBackgroundColor
            if !UserScopeNoChangeFG.ZJ.btItemViewPresentModeFixDisable {
                self.navigationController?.view.layer.masksToBounds = false
                self.navigationController?.view.layer.ud.setShadow(type: .s4Down)
            } else {
                self.contentView.layer.ud.setShadow(type: .s4Down)
            }
        }
    }
    
    @objc
    private func didClickMaskView() {
        guard currentCardPresentMode == .card else {
            return
        }
        if viewModel.mode == .submit,
            UserScopeNoChangeFG.YY.baseAddRecordPageShareEnable
        {
            self.closeAddRecord(closeConfirm: { [weak self] in
                self?.closeAllCards()
            })
            return
        }
        closeAllCards()
    }
}

extension BTController {

    func isCurrentCardHasField(for type: BTFieldUIType) -> Bool {
        currentCard?.recordModel.wrappedFields.first(where: { $0.compositeType.uiType == type }) != nil
    }
    
    func getFormShareEnableTip() -> String? {
        let hasFormula = isCurrentCardHasField(for: .formula)
        let hasLookup = isCurrentCardHasField(for: .lookup)
        if hasFormula && hasLookup {
            return BundleI18n.SKResource.Bitable_Form_FormulaResultsAndLookupResultsWillBeVisible
        } else if hasLookup {
            return BundleI18n.SKResource.Bitable_Form_LookupResultsWillBeVisible
        } else if hasFormula {
            return BundleI18n.SKResource.Bitable_Form_FormulaResultsWillBeVisible
        } else {
            return nil
        }
    }
}

extension BTController {
    
    func haveCommonAncestor(firstView: UIView, secondView: UIView) -> Bool {
        var ancestorView: UIView? = firstView.superview

        while ancestorView != nil {
            if secondView.isDescendant(of: ancestorView ?? UIView()) {
                return true
            }
            ancestorView = ancestorView?.superview
        }
        return false
    }
    
    func cardReloadForTransition(size: CGSize) {
        
        var browserViewController: UIViewController
        if !UserScopeNoChangeFG.QYK.btSideCardWidthOnSheetFixDisable {
            guard let browserVC = self.delegate?.cardGetBrowserController() else {
                return
            }
            browserViewController = browserVC
        } else {
            guard let browserVC = self.delegate?.cardGetBitableBrowserController(),
                  let bitableBrowserVC = browserVC as? BitableBrowserViewController else {
                return
            }
            browserViewController = bitableBrowserVC
        }
        guard !UserScopeNoChangeFG.QYK.btSideCardCloseFixDisable,
            !viewModel.mode.isForm,
            !viewModel.mode.isIndRecord,
            !viewModel.mode.isAddRecord,
            let parentVC = self.parent else {
            DocsLogger.btError("[ACTION] cannot relayout for view transition change")
            return
        }

        if !haveCommonAncestor(firstView: browserViewController.view, secondView: parentVC.view) {
            return
        }
        
        let browserVCWidth = browserViewController.view.frame.width
        var cardWidth: CGFloat = min(max(browserVCWidth * cardWidthPercentOnCardMode, cardMinWidthOnCardMode), browserVCWidth)
        
        cardWidth = min(cardWidth, size.width)
        if self.cardPresentMode == .card {
            if abs(browserVCWidth - cardWidth) <= 100 || cardWidth > browserVCWidth {
                cardWidth = browserVCWidth
                parentVC.view.snp.remakeConstraints { make in
                    make.edges.equalTo(browserViewController.view.snp.edges)
                }
            } else {
                if parentVC.view.superview != nil {
                    parentVC.view.snp.remakeConstraints { make in
                        make.bottom.top.equalToSuperview()
                        make.width.equalTo(cardWidth)
                        make.right.equalToSuperview()
                    }
                }
            }
        } else {
            parentVC.view.snp.remakeConstraints { make in
                make.edges.equalTo(browserViewController.view.snp.edges)
            }
        }
        parentVC.view.superview?.layoutIfNeeded()
        view.layoutIfNeeded()
    }
    
    /// 当card模式下，browser发生变化，但是APP大小未发生变化时，调用这个函数
    func cardRelayoutForSplitModeChange() {
        guard let browserVC = self.delegate?.cardGetBrowserController() else {
            DocsLogger.btError("[ACTION] cannot relayout for splitMode change")
            return
        }
        
        // 支持打开卡片，动态控制卡片的宽度为browserView的 44%
        let browserVCWidth = browserVC.view.frame.width
        let cardWidth = min(max(browserVCWidth * cardWidthPercentOnCardMode, cardMinWidthOnCardMode), browserVCWidth)
        let screenHeight = UIScreen.main.bounds.height
        self.presentAnimation.containerView?.frame = CGRect(x: browserVCWidth - cardWidth, y: 0, width: cardWidth, height: screenHeight)
        view.layoutIfNeeded()
        self.scrollToCurrentCard()
    }

    /// 当tab切换时，.card 模式的卡片会跟随底部的transitionView异常变大，扩展到整个browserView，根据frame的大小确定卡片是否需要关闭
    func closeCardWhenTabChanged() {
        guard UserScopeNoChangeFG.ZJ.btCardReform, let browserVC = self.delegate?.cardGetBitableBrowserController(), currentCardPresentMode == .card, !viewModel.mode.isIndRecord else { return }
        if view.frame.width >= browserVC.view.frame.width * (cardWidthPercentOnCardMode + 0.05), view.frame.width >= cardMinWidthOnCardMode + 20 {
            self.closeAllCards(animated: false)
        }
    }
}

/// 卡片上下滑动事件监听（卡片上滑时需要隐藏翻页悬浮窗）
extension BTController {
    
    func updateSwitchCardBottomPanelViewVisibility(visible: Bool) {
        if canSetSwitchCardBottomPanelViewState {
            if visible {
                self.switchCardBottomPanelView.isHidden = false
                self.switchCardBottomBlurView.isHidden = false
            } else {
                self.switchCardBottomPanelView.isHidden = true
                self.switchCardBottomBlurView.isHidden = true
            }
        } else {
            self.switchCardBottomPanelView.isHidden = true
            self.switchCardBottomBlurView.isHidden = true
        }
    }
    
    func updateSubmitViewVisibility(visible: Bool, forceVisible: Bool = false, animation: Bool = false) {
        let visible = forceVisible || (shouldShowSubmitView && visible)
        if visible {
            self.submitView.isHidden = false
            if self.submitView.alpha != 1, animation {
                UIView.animate(withDuration: 0.2) {
                    self.submitView.alpha = 1
                } completion: { _ in
                    self.submitView.alpha = 1
                }
            } else {
                self.submitView.alpha = 1
            }
        } else {
            if !self.submitView.isHidden, animation {
                UIView.animate(withDuration: 0.2) {
                    self.submitView.alpha = 0
                } completion: { _ in
                    self.submitView.isHidden = true
                    self.submitView.alpha = 0
                }
            } else {
                self.submitView.isHidden = true
                self.submitView.alpha = 0
            }
        }
    }
    
    private func startCardViewUIEventMonitor() {
        guard cardViewUIEventMonitor == nil else {
            return
        }
        let ancestorView = self.cardsView
        if !self.viewModel.mode.isCard,
            !self.viewModel.mode.isLinkedRecord,
            self.viewModel.mode != .addRecord,
            self.viewModel.mode != .submit {
            DocsLogger.btError("current record can not add the UIMonitor")
            return
        }
        cardViewUIEventMonitor = BTUIEventMonitor(ancestorView: ancestorView)
        cardViewUIEventMonitor?.didReceiveMove = {[weak self] moveTranslaction in
            self?.handleCardViewTranslaction(moveTranslaction)
        }
    }
    
    private func stopCardViewUIEventMonitor() {
        cardViewUIEventMonitor = nil
    }
    
    private func handleCardViewTranslaction(_ translation: CGPoint) {
        let direction = TranslationDirectionDetector.detect(translation)
        handleCardViewDirection(direction)
    }
    
    private func handleCardViewDirection(_ direction: TranslationDirectionDetector.ScrollDirection) {
        switch direction {
        case .up:
            updateSwitchCardBottomPanelViewVisibility(visible: false)
            updateSubmitViewVisibility(visible: false)
        case .down:
            updateSwitchCardBottomPanelViewVisibility(visible: true)
            updateSubmitViewVisibility(visible: true)
        default: break
        }
    }
}

extension BTController {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        diffableDataSource?.forceUpdateItemsIfNeeded(at: indexPath, cell: cell)
        if let cell = cell as? BTRecord {
            viewModel.fpsTrace.bindSingleRecord(scrollView: cell.fieldsView)
        }
    }
}

extension BTController: ClipboardProtectProtocol {
    public func getDocumentToken() -> String? {
        return self.viewModel.baseContext.permissionObj.objToken
    }
}

extension BTController: BasePermissionObserver {
    func initOrUpdateCapturePermission(hasCapturePermission: Bool) {
        DocsLogger.info("[BasePermission] BTController initOrUpdateCapturePermission \(hasCapturePermission)")
        self.allowCapture = hasCapturePermission
        updateVisibleCellsCaptureAllowedState()
    }
    
    func initOrUpdateWatermark(shouldShowWatermark: Bool) {
        DocsLogger.info("[BasePermission] BTController initOrUpdateWatermark \(shouldShowWatermark)")
        self.watermarkConfig.needAddWatermark = shouldShowWatermark
    }
}
