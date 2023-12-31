//
//  DKMainViewController.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/6/12.
//

import Foundation
import SKUIKit
import EENavigator
import UniverseDesignToast
import RxSwift
import RxCocoa
import SKCommon
import SKFoundation
import SKResource
import SpaceInterface
import UniverseDesignDialog
import UniverseDesignColor
import LarkUIKit
import SnapKit
import UIKit
import LarkFoundation
import SKInfra
import LarkTab
import LarkSplitViewController
import LarkContainer
import LarkQuickLaunchInterface
import LarkDocsIcon

extension DKMainViewController: SceneProvider {
    var objType: DocsType {
        .file
    }

    var objToken: String {
        self.viewModel.objToken
    }

    var docsTitle: String? {
        self.viewModel.title
    }

    var isSupportedShowNewScene: Bool {
        // mail、calendar第三方附件，vcfollow不支持url打开，暂不支持多窗口
        let previewFrom = viewModel.previewFrom
        switch previewFrom {
        case .thirdParty, .mail, .calendar, .vcFollow,
             .docsAttachInFollow, .docx, .docsAttach, .im,
             .secretIM, .localFile, .bitableAttach, .sheetAttach,
             .sheetAttachInFollow, .miniApp, .driveSDK, .webBroswer:
            return false
        default:
            return true
        }
    }
    var userInfo: [String: String] {
        let previewFrom = viewModel.previewFrom
        return ["from": previewFrom.rawValue]
    }

    var currentURL: URL? {
        return nil
    }

    var version: String? {
        return nil
    }
}

// swiftlint:disable type_body_length file_length
final class DKMainViewController: BaseViewController, DrivePreviewScreenModeDelegate,
                                  UICollectionViewDataSource, UICollectionViewDelegateFlowLayout,
                                  UIScrollViewDelegate, CommonGestureDelegateRepeaterProtocol, DriveFileBlockVCProtocol,
                                  WikiContextProxy {
    weak var wikiContextProvider: WikiContextProvider?
    weak var fileBlockComponent: DriveFileBlockComponentProtocol?
    var fileBlockMountToken: String? // 同层渲染所挂载在文档的位置
    var isSameLayerFollow = false // 是否在同层渲染下 VCFollow
    /*
     stackView预期是自适应高度，初始化一个stackView放在Navigation下面后，ContainerView内容界面
     刷新后，stackView会有一个高度把内容顶下去导致看不到或只能看到部分内容。因此在stackView中没有内容
     时候预设一个高度限制bannerHeightConstraint，有内容时取消限制
     */
    var bannerHeightConstraint: Constraint?
    var statusBarIsHidden: Bool = false
    var bottomBarHideByPermission: Bool = false
    private var bottomBarIsHidden: Bool = true
    var isInFullScreen: Bool = false
    private(set) var hasAppearred = false
    // 点击卡片模式进入全屏模式
    var clickEnterFull: (() -> Void)?
    weak var attachmentDelegate: DriveSDKAttachmentDelegate?
    
    // 处理上级权限逻辑
    private let leaderPermHandler = LeaderPermHandler()

    private lazy var cardModeHoverView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tapGuesture)
        return view
    }()
    // 视频文件在卡片模式下不响应点击进入全屏flag
    private lazy var disableCardModeHoverView: Bool = false
    private lazy var didUpadateCardModeNavibar: Bool = false
    
    private lazy var disableCardModeHoverViewAndCardModeNavibar: Bool = true
    
    @InjectedSafeLazy private var temporaryTabService: TemporaryTabService

    // 权限埋点
    private var permissionStatistics: PermissionStatistics?
    private var docsInfo: DocsInfo?



    private lazy var tapGuesture: DriveCardModeTap =  {
        let guesture = DriveCardModeTap(target: self, action: #selector(enterFullAction(gesture:)))
        return guesture
    }()
    private(set) var collectionView: UICollectionView?
    private(set) var fileView: DKFileView?
    /// 内容违规提示页面
    private(set) lazy var violationHintTipView: SKComplaintNoticeView = {
        let hintView = SKComplaintNoticeView()
        hintView.overrideContent = ComplaintState.driveDetail
        hintView.isHidden = true
        return hintView
    }()

    private(set) lazy var appealView: SKAppealBanner = {
        let view = SKAppealBanner()
        view.isHidden = true
        return view
    }()

    /// 密级banner提示
    private(set) lazy var secretBannerView: SecretBannerView = {
        let view = SecretBannerView()
        view.actionDelegate = self
        return view
    }()

    /// DLP banner提示
    private(set) lazy var dlpBannerView: DLPBannerView = {
        let view = DLPBannerView()
        view.bannerDelegate = self
        return view
    }()

    ///公告
    private(set) lazy var noticeBulletinView: BulletinView = {
        let bt = BulletinView()
        bt.isHidden = true
        return bt
    }()
    private(set) lazy var bannerStackView: DKBannerContainer = {
        let sv = DKBannerContainer()
        sv.axis = .vertical
        return sv
    }()

    private weak var lastChildVC: UIViewController?
    private weak var bottomBar: DKBottomBar?

    /// 底部菜单栏
    var commentBarIsShow: Bool = false
    lazy var commentBar: DriveCommentBottomView = {
        guard let host = viewModel.hostModule else {
            DocsLogger.driveInfo("IMFile has no host module")
            return DriveCommentBottomView(likeEnabled: false)
        }
        // 游客模式下，禁用游客的点赞功能
        let likeEnabled = !host.commonContext.isGuest
        return DriveCommentBottomView(likeEnabled: likeEnabled)
    }()
    lazy var cardModeNaviBar: DKCardModeNaviBar = {
        let bar = DKCardModeNaviBar(type: .unknown, title: self.viewModel.title)
        didUpadateCardModeNavibar = !self.viewModel.title.isEmpty
        bar.isHidden = true
        return bar
    }()
    /// 底部模拟安全区域的view，用于解决VC场景下，评论栏底部空白区域问题
    private(set) lazy var bottomPlaceHolderView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgBody
        return view
    }()

    private var magicRegister: FeelGoodRegister?

    /// hook navigationController interactivePopGestureRecognizer
    public weak var naviPopGestureDelegate: UIGestureRecognizerDelegate?
        private lazy var gestureDelegateRepeater = CommonGestureDelegateRepeater(self)
        var bag = DisposeBag()
        override var childForScreenEdgesDeferringSystemGestures: UIViewController? {
            return children.last
    }

    // 性能埋点
    private var performanceRecorder: DrivePerformanceRecorder {
        return viewModel.performanceRecorder
    }

    // 更新 CollectionView 的 contentOffset，避免横竖屏切换内容显示不正确
    private var shouldUpdateCollectionViewContentOffset: Bool = false

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DocsLogger.driveInfo("DKMainViewController -- willAppear")
        setupNaviPopGestureDelegate()
        viewModel.notifyControllerWillAppear()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        hasAppearred = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !childrenIdentifier.contains(.isTransfering) && displayMode != .card {
            // 分屏过程中不dismiss
            dismissCommentVCIfNeeded()
            dismissMessagePanelIfNeeded()
        }
        DocsLogger.driveInfo("DKMainViewController -- willDisappear")
        guard displayMode == .normal else {
            return
        }
        DocsLogger.driveInfo("DKMainViewController -- willDisappear remove naviPopGestureDelegate")
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self.naviPopGestureDelegate
        self.naviPopGestureDelegate = nil
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.notifyControllerDidDisappear()
    }

    @objc
    func willDealloc() -> Bool {
        return false
    }

    private func setupNaviPopGestureDelegate() {
        guard !isFromCardMode else {
            return
        }
        DocsLogger.driveInfo("DKMainViewController -- setupNaviPopGestureDelegate ")
        guard (self.navigationController?.interactivePopGestureRecognizer?.delegate as? CommonGestureDelegateRepeater) != gestureDelegateRepeater else {
            DocsLogger.error("interactivePopGestureRecognizer?.delegate must not be self")
            return
        }
        self.naviPopGestureDelegate = self.navigationController?.interactivePopGestureRecognizer?.delegate
        self.navigationController?.interactivePopGestureRecognizer?.delegate = gestureDelegateRepeater
    }

    override func refreshLeftBarButtons() {
        super.refreshLeftBarButtons()
        let itemComponents: [SKBarButtonItem] = navigationBar.leadingBarButtonItems
        // iPad 下并且是标签页打开需要左上角展示「X」按钮
        if (self.presentingViewController != nil || (self.isTemporaryChild && SKDisplay.pad))
            && !hasBackPage
            && !itemComponents.contains(closeButtonItem) {
            self.navigationBar.leadingBarButtonItems.insert(closeButtonItem, at: 0)
            self.navigationBar.leadingBarButtonItems.removeAll(where: { $0 == backBarButtonItem })
        }
        if let index = itemComponents.firstIndex(of: showInNewSceneItem), viewModel.fileDeleted {
            // 文档被删除场景，需要移除 newScene 按钮
            // 不能通过禁用 isSupportedShowNewScene 的方式隐藏此按钮，原因是关闭多窗口按钮也依赖了这个属性，会导致无法关闭多窗口
            self.navigationBar.leadingBarButtonItems.remove(at: index)
        }
    }
    override var shouldAutorotate: Bool {
        if viewModel.supportLandscape {
            return true
        } else {
            return self.children.last?.shouldAutorotate ?? false
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if viewModel.supportLandscape {
            return .allButUpsideDown
        } else {
            if let childOrientations = self.children.last?.supportedInterfaceOrientations {
                return childOrientations
            }
            return .portrait
        }
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateCommentBarForSafeAreaUpdated()
        // 在全屏态下避免展示navigationbar
        self.updateNavigationBar(isHidden: self.displayMode == .card || isInFullScreen)
    }

    private let naviBarConfig: DriveSDKNaviBarConfig
    let viewModel: DKMainViewModelType
    private let router: DKRouter

    // viewDidLoad 之后才能读取此属性
    private(set) var naviBarCoordinator: DKNaviBarCoordinator!

    override var prefersStatusBarHidden: Bool { statusBarIsHidden }
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { .slide }

    // private properties
    // 记录是否是第一次打开应用
    private var hasAppeared: Bool = false
    /// 判断是否是第一次打开DriveMainViewController,第一次进入mainVC马上加载文件，
    /// 如果是左右切换不马上加载文件，要等到滚动停止时开始加载
    var loadFileWhenDisplay = true

    var displayMode: DrivePreviewMode = .normal {
        didSet {
            if displayMode == .card { // 出现一次diplayMode为card mode
                isFromCardMode = true
            }
        }
    }

    private var isFromCardMode: Bool = false // 判断是否来自卡片模式场景
    init(viewModel: DKMainViewModelType, router: DKRouter, naviBarConfig: DriveSDKNaviBarConfig) {
        self.viewModel = viewModel
        self.router = router
        self.naviBarConfig = naviBarConfig
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        DocsLogger.driveInfo("drive.sdk.mainVC --- deinit")
        // drive视图栈计数-1
        DrivePreviewRecorder.close()
        // 用户取消埋点 如果打开成功已经上报过 则不会上报取消
        performanceRecorder.sourceType = .other
        performanceRecorder.openFinish(result: .cancel, code: .cancel, openType: .unknown)
        performanceRecorder.close(contextVC: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupFeelGood()
        performanceRecorder.stageBegin(stage: .vcCreate)
        // drive视图栈计数+1
        DrivePreviewRecorder.open()
        setupUI()
        setupViewModel()
        performanceRecorder.stageEnd(stage: .vcCreate)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !hasAppeared {
            hasAppeared = true
            DocsLogger.driveInfo("uiState: viewDidLayoutSubviews scrollToIndex \(viewModel.curIndex)")
            scrollToItem(by: viewModel.curIndex)
            viewModel.prepareShowBulletin()
        }
        if displayMode == .card {
            view.bringSubviewToFront(cardModeHoverView)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        DocsLogger.driveInfo("uiState: viewWillTransition to size \(size)")
        super.viewWillTransition(to: size, with: coordinator)
        dismissCommentVCIfNeeded()
        shouldUpdateCollectionViewContentOffset = true
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let self = self else { return }
            self.collectionView?.collectionViewLayout.invalidateLayout()
            self.scrollToItem(by: self.viewModel.curIndex)
            self.shouldUpdateCollectionViewContentOffset = false

        }
        if !secretBannerView.isHidden {
            secretBannerView.layoutHorizontalIfNeeded(preferedWidth: size.width)
        }
    }

    // SplitVC 显示模式发生变化时，更新 CollectionView 的布局，避免因布局问题导致当前显示的Cell不对
    override func splitSplitModeChange(splitMode: SplitViewController.SplitMode) {
        super.splitSplitModeChange(splitMode: splitMode)
        DocsLogger.driveInfo("uiState: splitMode change \(splitMode), curIndex: \(viewModel.curIndex)")
        self.collectionView?.collectionViewLayout.invalidateLayout()
        scrollToItem(by: viewModel.curIndex)
    }


    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        if parent == nil, !isInVCFollow {
            //通知前端附件退出
            DocsLogger.driveInfo("notice web to exit previewing")
            attachmentDelegate?.onAttachmentClose()
        }
    }

    public override var canShowFullscreenItem: Bool {
        self.bizType = .file
        return naviBarConfig.fullScreenItemEnable
    }

    // 是否显示返回按钮，VC 场景需要隐藏
    override var canShowBackItem: Bool {
        if shouldHideBackButtonInFollow { return false }
        guard let host = viewModel.hostModule else { return super.canShowBackItem }
        return (host.commonContext.previewFrom == .groupTab) ? self.hasBackPageIgnorParent() : super.canShowBackItem
    }

    public override var commonTrackParams: [String: String] {
        return viewModel.statisticsService.commonTrackParams
    }

    public var statisticsService: DKStatisticsService {
        return viewModel.statisticsService
    }

    private func setupCollectionView() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.footerReferenceSize = .zero
        layout.headerReferenceSize = .zero
        layout.sectionInset = .zero
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.dataSource = self
        view.delegate = self
        view.backgroundColor = .clear
        view.isPagingEnabled = true
        view.isPrefetchingEnabled = false
        view.showsHorizontalScrollIndicator = false
        view.contentInsetAdjustmentBehavior = .never
        view.register(DKFileCell.self, forCellWithReuseIdentifier: "\(DKFileCell.self)")
        return view
    }

    private func scrollToItem(by index: Int) {
        collectionView?.scrollToItem(at: IndexPath(item: index, section: 0),
                                    at: .centeredHorizontally,
                                    animated: false)
    }
    private func setupUI() {
        view.backgroundColor = UDColor.bgBase
        if viewModel.numberOfFiles() > 1 {
            let collectionView = setupCollectionView()
            self.collectionView = collectionView
            view.addSubview(collectionView)
            collectionView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        } else {
            let fileView = DKFileView()
            self.fileView = fileView
            view.addSubview(fileView)
            fileView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        if !isInVCFollow {
            setupBannerStackView()
        }
        view.addSubview(cardModeNaviBar)
        cardModeNaviBar.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(0)
            make.left.right.equalToSuperview()
            make.height.equalTo(44)
        }
        self.didChangeMode(self.displayMode)
        if displayMode == .card {
            view.addSubview(cardModeHoverView)
            cardModeHoverView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            view.bringSubviewToFront(cardModeHoverView)
        }
        if let fileView = fileView {
            loadFileData(fileView, index: 0)
        }
    }

    private func setupViewModel() {
        viewModel.reloadData.debug("reloadData").drive(onNext: {[weak self] (index) in
            guard let self = self else { return }
            DocsLogger.driveInfo("uiState: viewModel reloadData at \(index)")
            self.loadFileWhenDisplay = true
            self.collectionView?.reloadData()
            self.scrollToItem(by: index)
        }).disposed(by: bag)
        viewModel.naviBarViewModel
            .drive(onNext: {[weak self] (vm) in
                    guard let self = self else { return }
                self.naviBarCoordinator = DKNaviBarCoordinator(naviBar: self.navigationBar,
                                                               viewModel: vm,
                                                               subTitle: self.viewModel.subTitle,
                                                               naviBarConfig: self.naviBarConfig) { [weak self] (action, sourceView, sourceRect) in
                        self?.handle(naviBarAction: action, sourceView: sourceView, sourceRect: sourceRect)
                }
                self.hideNaviTrailingButtonIfNeeded()
            }).disposed(by: bag)
        viewModel.previewAction
            .subscribe(onNext: { [weak self] action in
                self?.handle(previewAction: action)
            }).disposed(by: bag)

        viewModel.previewUIStateManager.setup(hostVC: self) { [weak self] isLandscape in
            guard let self = self else { return }
            self.viewModel.statisticsService.enterFileLandscape(isLandscape)
        }

        viewModel.previewUIStateManager.previewUIState
            .skip(1)
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: DriveUIState())
            .drive(onNext: { [weak self] state in
                guard let self = self else { return }
                self.handle(uiState: state)
            }).disposed(by: bag)
    }

    override func back(canEmpty: Bool = false) {
        // 避免横屏状态下直接 popVC 的奇怪动画，这里先切换为竖屏再退出
        setToPortraitIfNeeded()
        super.back(canEmpty: canEmpty)
        let docsInfo = viewModel.hostModule?.docsInfoRelay.value
        if docsInfo?.isFromWiki ?? false, let vc = self.parent as? TabContainable {
            temporaryTabService.removeTab(id: vc.tabContainableIdentifier)
        } else {
            temporaryTabService.removeTab(id: tabContainableIdentifier)
        }
        if clickEnterFull != nil {
            let params: [String: Any] = ["display": "card"]
            statisticsService.reportClickEvent(DocsTracker.EventType.driveFileOpenClick,
                                               clickEventType: DriveStatistic.DriveFileOpenClickEventType.clickReturn,
                                               params: params)
        }
    }

    override func setToPortraitIfNeeded() {
        DocsLogger.driveInfo("setToPortraitIfNeeded, previewFrom: \(viewModel.previewFrom)")
        super.setToPortraitIfNeeded()
    }

    func updateNavigationBar(isHidden: Bool) {
        let topSafeAreaHeight = view.safeAreaInsets.top
        let naviBarOffset = isHidden ? navigationBar.intrinsicHeight + topSafeAreaHeight : 0
        statusBar.snp.updateConstraints { make in
            make.top.equalToSuperview().offset(-naviBarOffset)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.top).offset(-naviBarOffset)
        }
        navigationBar.snp.updateConstraints { (make) in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(-naviBarOffset)
        }
    }

    // MARK: - CardMode
    var shouldHandleDismissGesture: Bool {
        if fileView?.lastChildVC == nil {
            return true
        } else {
            return (fileView?.lastChildVC as? DriveBizeControllerProtocol)?.shouldHandleDismissGesture ?? false
        }
    }
    func willChangeMode(_ mode: DrivePreviewMode) {
        if mode == .normal {
            refreshLeftBarButtons()
            self.navigationBar.alpha = 1.0
        }
        viewModel.willChangeMode(mode)
    }
    func changingMode(_ mode: DrivePreviewMode) {
        switch mode {
        case .card:
            self.updateNavigationBar(isHidden: true)
        case .normal:
            self.updateNavigationBar(isHidden: false)
        @unknown default:
            spaceAssertionFailure("unkonw preview mode")
        }
        viewModel.changingMode(mode)
    }
    func didChangeMode(_ mode: DrivePreviewMode) {
        displayMode = mode
        switch mode {
        case .card:
            self.updateNavigationBar(isHidden: true)
            self.hideCommentBar(animated: false)
            showCardModeNavibar(didUpadateCardModeNavibar, animate: false)
            self.cardModeHoverView.isHidden = disableCardModeHoverView
            self.statusBar.isHidden = true
            // isHidden会白边SKNavigationBar的高度导致布局错误
            self.navigationBar.alpha = 0.0
        case .normal:
            self.updateNavigationBar(isHidden: false)
            self.showCommentBar(animated: false)
            showCardModeNavibar(false, animate: false)
            self.cardModeHoverView.isHidden = true
            self.statusBar.isHidden = false
            self.navigationBar.alpha = 1.0
            fileView?.mainViewController = self
        @unknown default:
            spaceAssertionFailure("unkonw preview mode")
        }
        self.collectionView?.collectionViewLayout.invalidateLayout()
        self.collectionView?.layoutIfNeeded()
        viewModel.didChangeMode(mode)
    }

    var panGesture: UIPanGestureRecognizer? {
        if let collectionView = self.collectionView {
            guard let cell = collectionView.cellForItem(at: IndexPath(item: self.viewModel.curIndex, section: 0)) as? DKFileCell else { return nil }
            guard let bizVC = cell.fileView.lastChildVC as? DriveBizeControllerProtocol else { return nil }
            return bizVC.panGesture
        } else if let fileView = fileView {
            guard let bizVC = fileView.lastChildVC as? DriveBizeControllerProtocol else { return nil }
            return bizVC.panGesture
        } else {
            spaceAssertionFailure("cannot get panGesture")
            return nil
        }
    }

    var customGestureView: UIView? {
        // 同层渲染使用，不会使用多文件预览
        if let fileView = fileView {
            guard let bizVC = fileView.lastChildVC as? DriveBizeControllerProtocol else { return nil }
            return bizVC.customGestureView
        } else {
            spaceAssertionFailure("cannot get customGestureView")
            return nil
        }
    }

    var mainBackgroundColor: UIColor {
        if let collectionView = self.collectionView {
            guard let cell = collectionView.cellForItem(at: IndexPath(item: self.viewModel.curIndex, section: 0)) as? DKFileCell else { return UDColor.bgBase }
            guard let bizVC = cell.fileView.lastChildVC as? DriveBizeControllerProtocol else { return UDColor.bgBase }
            return bizVC.mainBackgroundColor
        } else if let fileView = fileView {
            guard let bizVC = fileView.lastChildVC as? DriveBizeControllerProtocol else { return UDColor.bgBase }
            return bizVC.mainBackgroundColor
        } else {
            return UDColor.bgBase
        }
    }

    @objc
    func enterFullAction(gesture: DriveCardModeTap?) {
        DocsLogger.driveInfo("DriveTapEnterFull -- state: \(String(describing: gesture?.state.rawValue))")
        if displayMode == .card {
            clickEnterFull?()
        }
    }

    // MARK: - Router
    fileprivate func handle(naviBarAction: DKNaviBarItemAction, sourceView: UIView?, sourceRect: CGRect?) {
        switch naviBarAction {
        case .none:
            return
        case let .push(body):
            Navigator.shared.push(body: body, from: self)
        case let .present(body):
            body.sourceView = sourceView
            body.sourceRect = sourceRect
            Navigator.shared.present(body: body, from: self, animated: true, completion: nil)
        case let .toast(content):
            UDToast.showTips(with: content, on: view)
        case .presentSpaceMoreVC:
            guard let host = viewModel.hostModule else { return }
            host.subModuleActionsCenter.accept(.showMoreVC)
        case .presentFeedVC:
            guard let host = viewModel.hostModule else { return }
            host.subModuleActionsCenter.accept(.showFeed)
        case .presentShareVC:
            guard let host = viewModel.hostModule else { return }
            host.subModuleActionsCenter.accept(.showShareVC)
        case .presentSercetSetting:
            guard let host = viewModel.hostModule else { return }
            host.subModuleActionsCenter.accept(.clickNavSecretEvent)
        case .presentMyAIVC:
            guard let host = viewModel.hostModule else { return }
            host.subModuleActionsCenter.accept(.showMyAIVC)
        }
    }

    // MARK: - Preview Action Handler
    // swiftlint:disable cyclomatic_complexity
    private func handle(previewAction: DKPreviewAction) {
        switch previewAction {
        case let .toast(content, type):
            UDToast.docs.showMessage(content, on: view, msgType: type)
        case let .dialog(entityOperate, fileBizDomain, docType, token):
            CCMSecurityPolicyService.showInterceptDialog(entityOperate: entityOperate, fileBizDomain: fileBizDomain, docType: docType, token: token)
        case let .forward(handler, info):
            handler(self, info)
        case let .openDrive(token, appID):
            router.openDrive(token: token, appID: appID, from: self)
        case let .openWithOtherApp(url, sourceView, sourceRect, callback):
            router.openWith3rdApp(filePath: url, from: self, sourceView: sourceView, sourceRect: sourceRect, callback: callback)
        case let .downloadOriginFile(viewModel, isOpenWithOtherApp):
            self.showDownloadView(viewModel: viewModel, isOpenWithOtherApp: isOpenWithOtherApp)
        case .exitPreview, .cancelDownload:
            if let navigationController = self.navigationController {
                navigationController.popViewController(animated: true)
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        case let .alert(content):
            showAlert(content: content)
        case .storageQuotaAlert:
            showQuotaAlert()
        case let .userStorageQuotaAlert(token):
            showUserQuotaAlert(token: token)
        case let .customAction(action):
            action(self)
        case let .downloadAndOpenWithOtherApp(meta, previewFrom, sourceView, sourceRect, callback):
            // router 内部统一做了鉴权，这里不再重复判断 CAC 了
            router.downloadAndOpenWithOtherApp(meta: meta, from: self, sourceView: sourceView, sourceRect: sourceRect, callback: callback)
        case let .saveToAlbum(handler, info, previewFrom):
            router.downloadIfNeed(fileInfo: info, from: self, appealAlertFrom: .unknown, previewFrom: previewFrom, completed: handler)
        case let .saveToFile(handler, info, previewFrom):
            router.downloadIfNeed(fileInfo: info, from: self, appealAlertFrom: .unknown, previewFrom: previewFrom, completed: handler)
        case let .saveToLocal(handle, info):
            DriveRouter.saveToLocal(fileInfo: info, from: self, appealAlertFrom: .driveAttachmentMoreDownload, complete: handle)
        case let .appealResult(state):
            if UserScopeNoChangeFG.PLF.appealV2Enable {
                showAppealView(state)
            } else {
                showAppealViolationTipsView(state)
            }
        case .hideAppealBanner:
            if UserScopeNoChangeFG.PLF.appealV2Enable {
                hideAppealView()
            } else {
                hideViolationTipsView()
            }
        case let .importAs(convertType, actionSource, previewFrom):
            router.pushConvertFileVC(type: convertType, actionSource: actionSource, previewFrom: previewFrom, from: self)
        case let .completeDownloadToSave(fileType, url, handler):
            handler?(self)
            self.completeDownloadToSave(fileType: fileType, url: url, from: self)
        case let .saveToSpaceQuotaAlert(fileSize):
            QuotaAlertPresentor.shared.showUserUploadAlert(mountNodeToken: nil, mountPoint: nil, from: self, fileSize: fileSize, quotaType: .bigFileSaveToSpace)
        case let .didFetchFileInfo(info):
            updateCardModeNaviBar(fileInfo: info)
        case let .setupChildPreviewVC(openType):
            handleOpenType(openType)
        case let .openSuccess(openType):
            handleOpenType(openType)
        case  .openFailed:
            handleOpenFailed()
        case let .open(entry, context):
            Navigator.shared.docs.showDetailOrPush(body: entry, context: context, wrap: LkNavigationController.self, from: self, animated: true)
        case let .openURL(url):
            Navigator.shared.docs.showDetailOrPush(url, from: self)
        case let .openShadowFile(id, url):
            openShadowFile(id: id, url: url)
        case let .closeBulletin(info):
            removeNotice(info)
        case let .showNotice(info):
            updateNotice(info)
        case let .customUserDefine(handler, info):
            handler(self, info)
        case .showDLPBanner:
            self.showDLPBannerView()
        case .hideDLPBanner:
            self.hideDLPBannerView()
        case let .showSecretBanner(type):
            self.showSecretBannerView(type: type)
        case .hideSecretBanner:
            self.hideSecretBannerView()
        case .showSecretSetting:
            self.showSecretSetting()
        case let .push(viewController):
            Navigator.shared.push(viewController, from: self)
        case let .legacyShowLeaderPermAlert(token, userPermission):
            self.leaderPermHandler.showLeaderManagerAlertIfNeeded(token, userPermission: userPermission, topVC: self)
        case let .showLeaderPermAlert(token, permissionContainer):
            self.leaderPermHandler.showLeaderManagerAlertIfNeeded(token: token, permissionContainer: permissionContainer, topVC: self)
        case .cacBlock:
            self.showCardModeNavibarAndTapHander()
        case let .showCustomBanner(banner, bannerID):
            showCustomBanner(banner, bannerID: bannerID)
        case let .hideCustomBanner(bannerID):
            hideCustomBanner(bannerID)
        case .hideLoadingToast:
            UDToast.removeToast(on: view)
        case .showFlowOnboarding(let id):
            DocsLogger.driveInfo("showFlowOnboarding: \(id.rawValue)")
            OnboardingManager.shared.showFlowOnboarding(id: id, delegate: self, dataSource: self)
        }
    }

    private func handle(uiState: DriveUIState) {
        guard displayMode == .normal else { return }
        DocsLogger.driveInfo("uiState: handle: \(uiState)")

        isInFullScreen = uiState.isInFullScreen
        navigationBar.trailingButtonBar.isHidden = uiState.isNaviTrailingButtonHidden

        if uiState.isBannerStackViewHidden {
            bannerStackView.isHidden = true
            bannerHeightConstraint?.activate()
        } else {
            if !bannerStackView.arrangedSubviews.isEmpty {
                bannerStackView.isHidden = false
                bannerHeightConstraint?.deactivate()
            }
        }

        let statusBarAnimation: AnimationBlock? = animationForSetStatusBar(isHidden: uiState.isStatusBarHidden)
        let naviBarAnimation: AnimationBlock? = animationForSetNaviBar(isHidden: uiState.isNavigationbarHidden)
        let bottomBarAnimation: AnimationBlock? = animationForSetBottomBar(isHidden: uiState.isBottomBarHidden)
        UIView.animate(withDuration: screenModeAnimationDuration) {
            statusBarAnimation?()
            naviBarAnimation?()
            bottomBarAnimation?()
            self.view.backgroundColor = uiState.backgroundColor?.udColor ?? self.mainBackgroundColor
            self.view.layoutIfNeeded()
        }
        showCommentBar(!uiState.isBottomBarHidden, animate: true)
    }

    private func updateCardModeNaviBar(fileInfo: DKFileProtocol) {
        self.cardModeNaviBar.titleLabel.text = fileInfo.name
        self.cardModeNaviBar.imageIcon.image = fileInfo.fileType.squareImage
        if fileInfo.fileType.isMedia || fileInfo.fileType.isImage {
            self.cardModeNaviBar.gradientLayer.colors = [UIColor.ud.staticBlack.withAlphaComponent(0.7).cgColor,
                UIColor.ud.staticBlack.withAlphaComponent(0).cgColor]
            self.cardModeNaviBar.snp.updateConstraints { make in
                make.height.equalTo(44)
            }
            self.cardModeNaviBar.gradientLayer.locations = [0, 1]
            self.cardModeNaviBar.titleLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        }
        didUpadateCardModeNavibar = true
    }

    private func handleOpenType(_ openType: DriveOpenType) {
        if openType.isVideo {
            if disableCardModeHoverViewAndCardModeNavibar {
                enableCardModeTapAction(false)
                if displayMode == .card {
                    showCardModeNavibar(false, animate: false)
                }
            }
        } else {
            enableCardModeTapAction(true)
            showCardModeNavibar(displayMode == .card, animate: false)
        }
        
        // 根据ChildVC配置默认背景色
        view.backgroundColor = mainBackgroundColor
    }

    func enableCardModeTapAction(_ enable: Bool) {
        disableCardModeHoverView = !enable
        cardModeHoverView.isHidden = (!enable || displayMode == .normal)
    }
    private func handleOpenFailed() {
        if displayMode == .card {
            showCardModeNavibar(true, animate: false)
        }
    }

    func showCardModeNavibar(_ show: Bool, animate: Bool) {
        let offset = show ? 0 : -70
        self.cardModeNaviBar.snp.updateConstraints { make in
            make.top.equalToSuperview().offset(offset)
        }
        if animate {
            UIView.animate(withDuration: 0.1) {
                self.view.layoutIfNeeded()
            } completion: { _ in
                self.cardModeNaviBar.isHidden = !show
            }
        } else {
            self.cardModeNaviBar.isHidden = !show
        }
    }

    // Show download view and start download
    private func showDownloadView(viewModel: DKDownloadViewModel, isOpenWithOtherApp: Bool) {
        let view = DKBottomBar()
        let downloadView = DKDownloadProgressView(viewModel: viewModel)
        view.pushItemVew(downloadView)
        view.show(on: self.view, animate: true)
        bottomBarIsHidden = false
        self.bottomBar = view
    }

    private func completeDownloadToSave(fileType: DriveFileType,
                                        url: URL,
                                        from: UIViewController) {
        DriveRouter.checkPhotosAlbumPermissionIfNeed(fileType) { granted in
            if granted {
                let filePath = SKFilePath(absUrl: url)
                DriveRouter.saveRouter(fileType: fileType, filePath: filePath, from: from)
            } else {
                DriveRouter.showNoPhotoPermissionDialog()
            }
        }
    }

    private func showAlert(content: DKAlertContent) {
        guard !content.isEmpty else {
            spaceAssertionFailure("alert content is empty!")
            DocsLogger.error("DriveSDK.MainVC: alert content is empty!")
            return
        }
        let dialog = UDDialog()
        if let title = content.title {
            dialog.setTitle(text: title)
        }
        if let message = content.message {
            dialog.setContent(text: message)
        }
        content.actions.forEach { action in
            switch action.style {
            case .default:
                dialog.addPrimaryButton(text: action.title, dismissCompletion: action.handler)
            case .cancel:
                dialog.addSecondaryButton(text: action.title, dismissCompletion: action.handler)
            case .destructive:
                dialog.addDestructiveButton(text: action.title, dismissCompletion: action.handler)
            @unknown default:
                dialog.addPrimaryButton(text: action.title, dismissCompletion: action.handler)
            }
        }
        Navigator.shared.present(dialog, from: self)
    }

    private func showQuotaAlert() {
        QuotaAlertPresentor.shared.showQuotaAlert(type: .saveToSpace, from: self)
    }

    private func showUserQuotaAlert(token: String) {
        let bizParams = SpaceBizParameter(module: .drive, fileID: token, fileType: .file)
        QuotaAlertPresentor.shared.showUserQuotaAlert(mountNodeToken: nil, mountPoint: nil, from: self, bizParams: bizParams)
    }

    private func hideNaviTrailingButtonIfNeeded() {
        guard LKDeviceOrientation.isLandscape() && SKDisplay.phone else { return }
        // 云空间文件横屏下不展示更多按钮
        var isHidden = viewModel.isSpaceFile
        if #available(iOS 16.0, *) {
            // iOS16 隐藏更多按钮，避免横屏下弹出页面让状态栏错乱
            isHidden = true
        }
        navigationBar.trailingButtonBar.isHidden = isHidden
    }

    private func openShadowFile(id: String, url: URL) {
        DocsLogger.driveDebug("openShadowFile \(url)")
        guard let navigationController = navigationController else { return }
        // 找到当前 VC 的上一个 VC，作为新页面的 fromVC，并移除当前 DriveVC
        let lastVCIndex = navigationController.viewControllers.endIndex - 2
        guard lastVCIndex >= 0 else {
            if SKDisplay.pad, navigationController.viewControllers.first == self {
                if let vc = Navigator.shared.response(for: url).resource as? UIViewController {
                    navigationController.setViewControllers([vc], animated: false)
                }
            } else {
                spaceAssertionFailure("Navigation Controller only have one viewControllers")
            }
            return
        }
        let lastVC = navigationController.viewControllers[lastVCIndex]
        navigationController.popViewController(animated: false)

        // 通过文档打开Drive文件（目前仅支持 Excel 通过 Sheet 打开）
        // showTemporary为false，不需要打开到主导航
        Navigator.shared.docs.showDetailOrPush(url,
                                               context: ["showTemporary": false],
                                               from: lastVC,
                                               animated: false) { [weak self] _, resp in
            guard let self = self else { return }
            guard let vc = resp.resource as? BaseViewController,
                  let vm = self.viewModel as? DriveShadowFileViewModelProtocol else {
                DocsLogger.driveInfo("openShadowFile, but not has right type")
                return
            }
            let shadowFile = DriveShadowFileImpl(vc: vc, vm: vm)
            DriveShadowFileManger.shared.addShadowFile(id: id, shadowFile: shadowFile)
        }
        // 打开埋点
        viewModel.performanceRecorder.openFinish(result: .success, code: .success, openType: .sheet)
        viewModel.statisticsService.reportExcelContentPageView(editMethod: .sheet(url: url))
    }

    // MARK: - ScreenMode
    private var screenModeAnimationDuration: TimeInterval { 0.25 }

    private typealias AnimationBlock = () -> Void

    // MARK: Status Bar

    private func animationForSetStatusBar(isHidden: Bool) -> AnimationBlock? {
        return { [weak self] in
            guard let self = self else { return }
            self.statusBarIsHidden = isHidden
            self.setNeedsStatusBarAppearanceUpdate()
            var naviBarOffset: CGFloat
            if isHidden {
                let topSafeAreaOffset = self.view.safeAreaInsets.top
                naviBarOffset = self.navigationBar.frame.height + topSafeAreaOffset
            } else {
                naviBarOffset = self.calculateTopOffsetForShowingNavibar()
                DocsLogger.driveDebug("uiState: show statusbar safeAreaInsets.top \(self.view.safeAreaInsets.top), final: \(naviBarOffset)")
            }
            self.statusBar.snp.updateConstraints { (make) in
                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(-naviBarOffset)
            }
        }
    }

    func setStatusBar(isHidden: Bool, animated: Bool = true) {
        guard let animation = animationForSetStatusBar(isHidden: isHidden) else { return }
        if animated {
            UIView.animate(withDuration: screenModeAnimationDuration, animations: animation)
        } else {
            animation()
        }
    }

    // MARK: Navi Bar
    private func animationForSetNaviBar(isHidden: Bool) -> AnimationBlock? {
        return { [weak self] in
            guard let self = self else { return }
            var naviBarOffset: CGFloat
            if isHidden {
                let topSafeAreaOffset = self.view.safeAreaInsets.top
                naviBarOffset = self.navigationBar.frame.height + topSafeAreaOffset
            } else {
                DocsLogger.driveInfo("uiState: show navibar safeAreaInsets.top \(self.view.safeAreaInsets.top)")
                self.setNavigationBarHidden(false, animated: false)
                naviBarOffset = self.calculateTopOffsetForShowingNavibar()
            }
            self.navigationBar.snp.updateConstraints { (make) in
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(-naviBarOffset)
            }
        }
    }

    func setNavibarHidden(isHidden: Bool, animated: Bool = true) {
        guard let animation = animationForSetNaviBar(isHidden: isHidden) else { return }
        if animated {
            UIView.animate(withDuration: screenModeAnimationDuration, animations: animation)
        } else {
            animation()
        }
    }

    /// 非全面屏手机，在全屏切换竖屏时，safeAreaInsets.top 出现不正确的 0 值，此处手工配置 offset，避免显示异常
    private func calculateTopOffsetForShowingNavibar() -> CGFloat {
        if self.view.safeAreaInsets.top == 0 && !LKDeviceOrientation.isLandscape() && !isInVCFollow
            && SKDisplay.phone && !Display.iPhoneXSeries {
            return -20
        }
        return 0
    }

    // MARK: Bottom Bar
    private func animationForSetBottomBar(isHidden: Bool) -> AnimationBlock? {
        guard let bottomBar = bottomBar, bottomBarIsHidden != isHidden else { return nil }
        return {
            guard bottomBar.superview != nil else { return }
            self.bottomBarIsHidden = isHidden
            let bottomBarOffset: CGFloat
            if isHidden {
                bottomBarOffset = bottomBar.frame.height
            } else {
                bottomBarOffset = 0
            }
            bottomBar.snp.updateConstraints { (make) in
                make.bottom.equalToSuperview().offset(bottomBarOffset)
            }
        }
    }

    // DrivePreviewScreenModeDelegate
    @discardableResult
    func changeScreenMode() -> Bool {
        if isInFullScreen {
            exitFullScreen()
            return false
        } else {
            enterFullScreen()
            return true
        }
    }

    func enterFullScreen() {
        viewModel.previewUIStateManager.previewSituation.accept(.fullScreen)
    }

    func exitFullScreen() {
        viewModel.previewUIStateManager.previewSituation.accept(.exitFullScreen)
    }

    func changePreview(situation: DrivePreviewSituation) {
        viewModel.previewUIStateManager.previewSituation.accept(situation)
    }

    @discardableResult
    func isInFullScreenMode() -> Bool {
        return isInFullScreen
    }
    func hideCommentBar(animated: Bool) {
        showCommentBar(false, animate: animated)
    }

    func showCommentBar(animated: Bool) {
        showCommentBar(viewModel.shouldShowCommentBar, animate: animated)
    }

    func setCommentBar(enable: Bool) {
        viewModel.previewUIStateManager.commentBarEnable.accept(enable)
    }

    private func hideSecretBannerView() {
        secretBannerView.isHidden = true
        bannerStackView.removeArrangedSubview(secretBannerView)
        secretBannerView.removeFromSuperview()
        judgeIfActiveConstraint()

    }

    private func showSecretBannerView(type: SecretBannerView.BannerType) {
        bannerHeightConstraint?.deactivate()
        secretBannerView.isHidden = false
        bannerStackView.addArrangedSubview(secretBannerView)
        secretBannerView.setBannerType(type)
        secretBannerView.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
        }
        secretBannerView.layoutHorizontalIfNeeded(preferedWidth: view.bounds.width)
    }

    private func showDLPBannerView() {
        PermissionStatistics.shared.reportDlpSecurityBannerHintView()
        bannerHeightConstraint?.deactivate()
        dlpBannerView.isHidden = false
        bannerStackView.addArrangedSubview(dlpBannerView)
    }

    private func hideDLPBannerView() {
        dlpBannerView.isHidden = true
        bannerStackView.removeArrangedSubview(dlpBannerView)
        dlpBannerView.removeFromSuperview()
        judgeIfActiveConstraint()
    }
    
    private func showCustomBanner(_ banner: UIView, bannerID: String) {
        bannerHeightConstraint?.deactivate()
        bannerStackView.addBanner(banner: banner, bannerID: bannerID)
    }
    
    private func hideCustomBanner(_ bannerID: String) {
        bannerStackView.removeBanner(with: bannerID)
        judgeIfActiveConstraint()
    }

    // MARK: - 审核横幅提示tips
    func setupViolationHintTipViewIfNeed() {
        guard violationHintTipView.superview == nil else {
            DocsLogger.driveInfo("BannerStackView: violationHint has superview")
            return
        }
        violationHintTipView.isHidden = true
        violationHintTipView.clickLabelHandler = { [weak self] state in
            guard let self = self else { return }
            self.viewModel.shouldOpenVerifyURL(type: state)
        }
        bannerStackView.addArrangedSubview(violationHintTipView)
        violationHintTipView.snp.makeConstraints({ (make) in
            make.left.right.equalToSuperview()
        })
    }

    func showAppealViolationTipsView(_ state: ComplaintState) {
        DocsLogger.driveInfo("audit state: \(state)")
        setupViolationHintTipViewIfNeed()
        bannerHeightConstraint?.deactivate()
        violationHintTipView.isHidden = false
        violationHintTipView.update(complaintState: state)
    }

    private func hideViolationTipsView() {
        violationHintTipView.isHidden = true
        bannerStackView.removeArrangedSubview(violationHintTipView)
        violationHintTipView.removeFromSuperview()
        judgeIfActiveConstraint()
    }

    func showAppealView(_ state: ComplaintState) {
        DocsLogger.driveInfo("audit state: \(state)")
        setupAppealViewIfNeed()
        bannerHeightConstraint?.deactivate()
        appealView.isHidden = false
        let entityId = "\(objToken):\(objType.rawValue)"
        appealView.update(complaintState: state, entityId: entityId)
    }

    private func hideAppealView() {
        appealView.isHidden = true
        bannerStackView.removeArrangedSubview(appealView)
        appealView.removeFromSuperview()
        judgeIfActiveConstraint()
    }

    func setupAppealViewIfNeed() {
        guard appealView.superview == nil else {
            DocsLogger.driveInfo("BannerStackView: violationHint has superview")
            return
        }
        appealView.isHidden = true
        appealView.clickCallback = { [weak self] (url) in
            guard let self else { return }
            Navigator.shared.push(url, from: self)
        }
        bannerStackView.addArrangedSubview(appealView)
        appealView.snp.makeConstraints({ (make) in
            make.left.right.equalToSuperview()
        })
    }

    // MARK: - 公告
    func removeNotice(_ info: BulletinInfo?) {
        noticeBulletinView.info = nil
        noticeBulletinView.delegate = nil
        noticeBulletinView.isHidden = true
        bannerStackView.removeArrangedSubview(noticeBulletinView)
        noticeBulletinView.removeFromSuperview()
        DocsLogger.driveInfo("BannerStackView: NoticeBulletin has remove")
        judgeIfActiveConstraint()
    }

    func updateNotice(_ info: BulletinInfo) {
        DocsLogger.driveInfo("BannerStackView: NoticeBulletin update")
        guard noticeBulletinView.superview == nil else {
            DocsLogger.driveInfo("BannerStackView: NoticeBulletin has superview")
            return
        }
        bannerHeightConstraint?.deactivate()
        noticeBulletinView.delegate = viewModel
        noticeBulletinView.uiDelegate = self
        noticeBulletinView.info = info
        noticeBulletinView.isHidden = false
        DocsLogger.driveInfo("BannerStackView: NoticeBulletin  add in BannerStackView")
        bannerStackView.addArrangedSubview(noticeBulletinView)
    }

    func setupBannerStackView() {
        guard bannerStackView.superview == nil else {
            DocsLogger.driveInfo("BannerStackView : has superview")
            return
        }
        view.addSubview(bannerStackView)
        DocsLogger.driveInfo("BannerStackView: NoticeBulletin  add in view")
        bannerStackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(navigationBar.snp.bottom)
            bannerHeightConstraint = make.height.equalTo(0).constraint
        }
    }

    func judgeIfActiveConstraint() {
        if bannerStackView.arrangedSubviews.isEmpty {
            bannerHeightConstraint?.activate()
        }
    }

    // MARK: - UICollectionViewDatasource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell1 = collectionView.dequeueReusableCell(withReuseIdentifier: "\(DKFileCell.self)", for: indexPath)
        guard let cell = cell1 as? DKFileCell else {
            spaceAssertionFailure("cell is not registed")
            return cell1
        }
        return cell
    }
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfFiles()
    }
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let preivewCell = cell as? DKFileCell else { return }
        guard viewModel.numberOfFiles() > 1 else {
            // 不是多图预览的情况下，直接加载 fileData
            // 避免进入 didEndDisplaying 后 cell 被 reset()，再此进入 willDisplay 时无法加载数据
            loadFileData(preivewCell.fileView, index: indexPath.item)
            return
        }
        DocsLogger.driveInfo("uiState: willDisplay, currentIndex: \(indexPath.item)")
        preivewCell.fileView.shouldReset = true
        if loadFileWhenDisplay {
            loadFileWhenDisplay = false
            DocsLogger.driveInfo("uiState: willDisplay, loadFileWhenDisplay, currentIndex: \(indexPath.item)")
            loadFileData(preivewCell.fileView, index: indexPath.item)
        }
        // 布局变化可能会触发 didEndDisplaying，从而 reset 当前 cell，这里重新 loadData
        if indexPath.item == viewModel.curIndex, preivewCell.fileView.viewModel == nil {
            DocsLogger.driveInfo("uiState: willDisplay, loadFileWhenNoViewModel, currentIndex: \(indexPath.item)")
            loadFileData(preivewCell.fileView, index: indexPath.item)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // 在cell离开显示区域时reset cell，remove 当前的childVC,同时将cellViewModel置nil
        // 1. 避免mainVC存在多个childViewController； 2. 避免同时存在多个长链
        if let cell = cell as? DKFileCell {
            DocsLogger.driveInfo("uiState: didEndDisplaying, reset currentIndex: \(indexPath.item)")
            cell.fileView.notifyDidEndDisplay()
            cell.fileView.reset()
        }
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }

    // 这个决定了 collectionView 停止滚动时最终的偏移量，配置保持当前 Cell 的偏移位置，可以避免横竖屏切换，内容没有居中问题
    func collectionView(_ collectionView: UICollectionView, targetContentOffsetForProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        guard shouldUpdateCollectionViewContentOffset else {
            return proposedContentOffset
        }
        // 注意 index 从 viewModel 中取
        let currentVisibleIndexPath = IndexPath(item: viewModel.curIndex, section: 0)
        let attributes = collectionView.layoutAttributesForItem(at: currentVisibleIndexPath)
        let contentOffset = attributes?.frame.origin ?? proposedContentOffset
        DocsLogger.driveInfo("uiState: targetContentOffset: \(contentOffset), viewModelIndex: \(viewModel.curIndex)")
        return contentOffset
    }

    private func loadFile(at index: Int) {
        guard let cell = collectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as? DKFileCell else {
            DocsLogger.warning("can not find cell", extraInfo: ["at index": index])
            return
        }
        loadFileData(cell.fileView, index: index)
    }

    private func resetFile(at index: Int) {
        guard let cell = collectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as? DKFileCell else {
            DocsLogger.warning("can not find cell", extraInfo: ["at index": index])
            return
        }
        DocsLogger.driveInfo("uiState: resetFile at index: \(index)")
        cell.fileView.reset()
    }

    private func loadFileData(_ fileView: DKFileView, index: Int) {
        fileView.mainViewController = self
        let cellVM = viewModel.cellViewModel(at: index)
        fileView.viewModel = cellVM
        if displayMode == .normal {
            fileView.mainViewController = self
        }
        fileView.screenModeDelegate = self
        fileView.startLoadFile()
        fileView.notifyWillDisplay()
        attachmentDelegate?.onAttachmentSwitch(to: index, with: cellVM.fileID)
    }
    private func setupFeelGood() {
        magicRegister = FeelGoodRegister(type: .driveContent) { [weak self] in return self }
    }

    // MARK: - UIScrollViewDelegate
    // 切换文件后更新MainViewController的状态（navbar 和 commentView)
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let index = curIndex(of: scrollView)
        guard index >= 0, index < viewModel.numberOfFiles() else {
            DocsLogger.driveError("currentIndex(\(index)) is illegal")
            return
        }

        DocsLogger.driveInfo("uiState: scrollViewDidEndDecelerating, currentIndex: \(index)")
        if loadFileWhenEndDecelerating(at: index) {
            let preIndex = viewModel.curIndex
            DocsLogger.driveInfo("uiState: loadFileWhenEndDecelerating, index: \(index), preIndex: \(preIndex)")
            // CollectionView 的 didEndDisplay 在某些场景下不会触发，为避免 cell 没有 reset，这里尝试找到 cell 然后将其 reset
            resetFile(at: preIndex)
            loadFile(at: index)
        }
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let cell = collectionView?.cellForItem(at: IndexPath(item: self.viewModel.curIndex, section: 0)) as? DKFileCell else { return }
        cell.fileView.shouldReset = true
        updateTitle()
    }
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        DocsLogger.driveInfo("uiState: scrollViewWillBeginDragging, loadFileWhenDisplay false")
        loadFileWhenDisplay = false // 手动滚动后设置为false,需要等加载fileinfo和permission后才加载文件
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        dismissCommentVCIfNeeded()
        updateTitle()
        DocsLogger.driveInfo("uiState: scrollViewDidEndDragging")
    }

    var currentIndex: Int {
        if let collectionView {
            return curIndex(of: collectionView)
        } else {
            return 0
        }
    }

    private func curIndex(of scrollView: UIScrollView) -> Int {
        let pageWidth = scrollView.bounds.size.width
        let offsetX = scrollView.contentOffset.x
        guard pageWidth > CGFloat.leastNormalMagnitude else {
            DocsLogger.driveInfo("pageWidth is 0, ofssetX is \(offsetX)")
            return 0
        }
        DocsLogger.driveInfo("Drive pageWidth", extraInfo: ["pageWidth": pageWidth])
        let index = Int(round(offsetX / pageWidth))
        return index
    }
    private func loadFileWhenEndDecelerating(at index: Int) -> Bool {
        guard let cell = collectionView?.cellForItem(at: IndexPath(item: index, section: 0)) as? DKFileCell else {
            DocsLogger.warning("can not find cell", extraInfo: ["at index": index])
            return false
        }
        return cell.fileView.viewModel == nil
    }

    private func updateTitle() {
        let index = viewModel.curIndex
        if viewModel.numberOfFiles() > 1, index >= 0, index < viewModel.numberOfFiles() {
            // update title bar
            let subtile = "\(index + 1)/\(viewModel.numberOfFiles())"
            self.naviBarCoordinator.updateTitle(title: viewModel.title(of: index), subTitle: subtile, showText: viewModel.previewFrom != .groupTab)
        }
    }
    
    private func showCardModeNavibarAndTapHander() {
        disableCardModeHoverViewAndCardModeNavibar = false
        enableCardModeTapAction(true)
        showCardModeNavibar(true, animate: false)
    }
}

// MARK: - WaterMark
extension DKMainViewController: WatermarkUpdateListener {
    public func didUpdateWatermarkEnable() {
        let shouldShowWatermark = viewModel.shouldShowWatermark
        if watermarkConfig.needAddWatermark != shouldShowWatermark {
            watermarkConfig.needAddWatermark = shouldShowWatermark
        }
    }
}
extension DKMainViewController: BannerUIDelegate {
    func preferedWidth(_ item: BannerItem) -> CGFloat {
        return view.bounds.width
    }

    func shouldUpdateHeight(_ item: BannerItem, newHeight: CGFloat) {
        noticeBulletinView.snp.remakeConstraints { make in
            make.height.equalTo(newHeight)
        }
    }

    //暂时项目没有用到此方法
    func shouldRemove(_ item: BannerItem) {}
}
/// make copy 需要 hostVC实现 DocsCreateViewControllerRouter
extension DKMainViewController: DocsCreateViewControllerRouter {}
extension DKMainViewController: DKSubModleHostVC {}
extension DKMainViewController: WindowSizeProtocol {}
extension DKMainViewController: SecretBannerViewDelegate {
    func secretBannerViewDidClickSetButton(_ view: SecretBannerView) {
        guard let host = viewModel.hostModule else { return }
        if let docsInfo = docsInfo, let level = docsInfo.secLabel {
            permissionStatistics?.reportPermissionSecurityDocsBannerClick(hasDefaultSecretLevel: level.bannerType == .defaultSecret, action: .securitySetting)
        }
        host.subModuleActionsCenter.accept(.clickSecretBanner)
    }
    func secretBannerViewDidClickLink(_ view: SecretBannerView, url: URL) {
        if let docsInfo = docsInfo, let level = docsInfo.secLabel {
            permissionStatistics?.reportPermissionSecurityDocsBannerClick(hasDefaultSecretLevel: level.bannerType == .defaultSecret, action: .knowDetail)
        }
        if let type = DocsType(url: url),
            let objToken = DocsUrlUtil.getFileToken(from: url, with: type) {
            let file = SpaceEntryFactory.createEntry(type: type, nodeToken: "", objToken: objToken)
            file.updateShareURL(url.absoluteString)
            let body = SKEntryBody(file)
            Navigator.shared.docs.showDetailOrPush(body: body, wrap: LkNavigationController.self, from: self)
        } else {
            Navigator.shared.push(url, from: self)
        }
    }
    
    // 改动点文档：https://bytedance.feishu.cn/wiki/GySPwq0LqiIbn8kTNYpcS1IdnIb?theme=DARK&contentTheme=LIGHT
    func secretBannerClose(_ secretBannerView: SecretBannerView) {
        hideSecretBannerView()
        PermissionStatistics.shared.reportPermissionRecommendBannerViewAction(isCompulsoryLabeling: false, action: "click")
        let docsInfo = viewModel.hostModule?.docsInfoRelay.value
        if let docsInfo = docsInfo {
            let bannerId: String
            if docsInfo.secLabel?.secLableTypeBannerType == .recommendMark {
                bannerId = docsInfo.secLabel?.recommendLabelId ?? "0"
            } else {
                bannerId = docsInfo.secLabel?.label.id ?? "0"
            }
            SecretLevel.updateSecLabelBanner(token: docsInfo.objId ?? "0",
                                             type: docsInfo.inherentType.rawValue,
                                             secLabelId: bannerId,
                                             bannerType: docsInfo.secLabel?.secLableTypeBannerType?.rawValue ?? 0,
                                             bannerStatus: docsInfo.secLabel?.secLableTypeBannerStatus?.rawValue ?? 0)
                .subscribe {
                    DocsLogger.info("update secret level success")
                } onError: { error in
                    DocsLogger.error("update secret level fail", error: error)
                }
                .disposed(by: self.bag)
        }
    }

    public func showSecretLearnMore() {
        do {
            let url = try HelpCenterURLGenerator.generateURL(article: .secretBannerHelpCenter)
            Navigator.shared.push(url, from: self)
        } catch {
            DocsLogger.error("failed to generate helper center URL when showSecretLearnMore from secret banner", error: error)
        }
    }
    public func showSecretSetting() {
        secretBannerViewDidClickSetButton(secretBannerView)
    }
    
    func secretBannerViewDidClickSetConfirmButton(_ view: SecretBannerView) {
        guard let host = viewModel.hostModule else { return }
        PermissionStatistics.shared.reportPermissionRecommendBannerViewAction(isCompulsoryLabeling: false, action: "confirm")
        hideSecretBannerView()
        host.subModuleActionsCenter.accept(.updateSecretLabel(name: view.secLabelTitleName))
    }
}

extension DKMainViewController: DLPBannerViewDelegate {

    func shouldClose(_ dlpBannerView: DLPBannerView) {
        let docsInfo = viewModel.hostModule?.docsInfoRelay.value
        if let docsInfo = docsInfo {
            let uid = User.current.info?.userID ?? ""
            let closedKey = "ccm.permission.dlp.closed" + docsInfo.encryptedObjToken + uid
            if !CacheService.normalCache.containsObject(forKey: closedKey) {
                if let saveData = try? JSONEncoder().encode(true) {
                    CacheService.normalCache.set(object: saveData, forKey: closedKey)
                } else {
                    DocsLogger.error("SaveData encode fail", extraInfo: ["encryptedObjToken": docsInfo.encryptedObjToken])
                }
            }
        }
        DocsLogger.driveInfo("DLP banner should close", extraInfo: ["encryptedObjToken": docsInfo?.encryptedObjToken])

        PermissionStatistics.shared.reportDlpSecurityBannerHintClick(isClose: true)
        hideDLPBannerView()
    }

    func shouldOpenLink(_ dlpBannerView: DLPBannerView, _ url: URL) {
        let docsInfo = viewModel.hostModule?.docsInfoRelay.value
        DocsLogger.driveInfo("Should open link", extraInfo: [
            "encryptedObjToken": docsInfo?.encryptedObjToken,
            "url": url.absoluteString
        ])
        PermissionStatistics.shared.reportDlpSecurityBannerHintClick(isClose: false)
        if let type = DocsType(url: url),
            let objToken = DocsUrlUtil.getFileToken(from: url, with: type) {
            let file = SpaceEntryFactory.createEntry(type: type, nodeToken: "", objToken: objToken)
            file.updateShareURL(url.absoluteString)
            let body = SKEntryBody(file)
            Navigator.shared.docs.showDetailOrPush(body: body, wrap: LkNavigationController.self, from: self)
        } else {
            Navigator.shared.push(url, from: self)
        }
    }
}
