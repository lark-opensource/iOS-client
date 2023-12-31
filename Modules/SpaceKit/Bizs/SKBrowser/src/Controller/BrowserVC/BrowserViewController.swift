//
// Created by Huang JinZhu on 2018/5/29.
// SKBrowser
//
// Description: BrowserViewController 负责加载 BrowserView
// swiftlint:disable file_length type_body_length

import UIKit
import RxSwift
import RxRelay
import SnapKit
import SKUIKit
import SKCommon
import LarkUIKit
import LarkTab
import UniverseDesignToast
import SKResource
import EENavigator
import SKFoundation
import SpaceInterface
import LarkSplitViewController
import UniverseDesignColor
import LarkTraitCollection
import UniverseDesignEmpty
import Heimdallr
import UniverseDesignTheme
import SKInfra
import LarkContainer
import LarkQuickLaunchInterface

// MARK: - BrowserViewController for Docs/Mindnotes
open class BrowserViewController: BaseViewController, BrowserTopContainerDelegate, CommonGestureDelegateRepeaterProtocol, SKTracableProtocol, WikiContextProxy {
    
    public enum SearchMode {
        case normal // 普通模式
        case search(finishCallback: (()->Void)) // 搜索模式
    }

    // MARK: - UI
    open var topContainer: BrowserTopContainer { _topContainer } // 这么写是为了让 Sheet 能够 override
    private lazy var _topContainer = BrowserTopContainer(navBar: self.navigationBar)
    open var topContainerState: TopContainerState {
        didSet {
            DocsLogger.info("before changing, topContainer state: \(oldValue)")
            switch topContainerState {
            case .fixedShowing:
                setFullScreenProgress(0.0, forceUpdate: true, topContainerAnimated: false)
                updateTopPlaceholderHeight(webviewContentOffsetY: 0, forceUpdate: true)
            case .fixedHiding:
                if isFromTemplatePreview {
                    return
                }
                if isEmbedMode {
                    // EmbedMode 下，只隐藏 topContainer，但要显示 editButton
                    setFullScreenProgress(0.0, forceUpdate: true, topContainerAnimated: false)
                } else {
                    setFullScreenProgress(1.0, forceUpdate: true, topContainerAnimated: false)
                }
                updateTopPlaceholderHeight(webviewContentOffsetY: -1, forceUpdate: true)
            case .normal:
                let needFixed = (UIDevice.current.userInterfaceIdiom == .pad && !isInVideoConference) || isFromTemplatePreview
                if needFixed {
                    topContainerState = .fixedShowing
                }
            }
            DocsLogger.info("after changing, topContainer state: \(topContainerState)")
        }
    }
    /// 定制化 TopContainerManager，用于在 doc block 全屏下覆盖在 topContainer 上方
    open lazy var customTCMangager: CustomTopContainerManager = CustomTopContainerManager(proxy: self)

    /// 在 topContainer 底下的透明 view，通过控制自身高度来带动 webview 尺寸变化，从而做到沉浸式浏览
    public lazy var topPlaceholder = UIView().construct { $0.backgroundColor = .clear }
    /// 在 editor 下方的透明 view，通过控制自身高度来带动 webview 尺寸变化，用于文档搜索导航条占位顶起文档等场景
    public lazy var bottomPlaceholder = UIView().construct { $0.backgroundColor = .clear }
    /// 在可以切换横竖屏的时候，若设备开启了竖排锁定，则会在屏幕角落显示的一个黑色的手动转屏 tip
    var forceOrientationTip: ForceOrientationTip?
    /// Browser View 本 View
    public var editor: BrowserView! {
        didSet {
            spaceAssert(Thread.isMainThread)
            spaceAssert(!hasSetEditor)
            orientationDirector?.editor = editor
            hasSetEditor = true
        }
    }
    //主导航PagePreservable缓存协议使用
    public var pageScene: LarkQuickLaunchInterface.PageKeeperScene = .normal
    // Magic Share 等场景下，会存在 browserView 上下有其他 view 的情况，不能理所当然认为 browserView 是顶到屏幕上下边界的
    var browserViewDistanceToWindowTop: CGFloat { view.convert(view.bounds, to: nil).minY }
    public var browserViewDistanceToWindowBottom: CGFloat { (SKDisplay.windowBounds(view).height) - view.convert(view.bounds, to: nil).maxY }
    
    /// ipad悬浮键盘下是否打开了图片选择器
    var floatKeyboardHasSubPanel: Bool {
        if Display.pad, let view = editor.uiResponder.inputAccessory.realInputAccessoryView, view is SKSubToolBarPanel {
            return true
        }
        return false
    }
    // 横屏时禁用滑动返回手势，记录之前的状态
    var preInteractivePopGestureRecognizerEnable: Bool = true
    var hasForbiddenPopGestureRecognizer: Bool = false
    var isViewDidShow: Bool = false
    
    // MARK: - Infos

    open var docsInfo: DocsInfo? { editor.docsInfo }
    var iconInfo: IconSelectionInfo?
    public var openSessionID: String?
    public private(set) var feedID: String?
    public var fileConfig: FileConfig?
    var isExternal: Bool?
    /// 当前页面是否是历史记录
    public var isHistoryRecord: Bool { docsInfo?.inherentType == .docX ? editor.isHistoryPanelShow : editor.currentUrl?.fragment == "history" }
    /// 当前页面是否为订阅详情页
    public var isSubscription: Bool {
        if let url = self.editor.currentURL, let subscription = url.docs.queryParams?["subscription"] {
            return subscription == "1"
        }
        return false
    }
    /// 当前是否跟群公告相关的，例如群公告历史
    private var isAnnouncement: Bool {
        if let url = self.editor.currentURL,
           let open_type = url.docs.queryParams?["open_type"],
           open_type == "announce" {
            return true
        }
        return false
    }
    
    private var isFromTaskList: Bool {
        if let url = self.editor.currentURL,
           let from = url.docs.queryParams?["from"],
           from == "tasklist" {
            return true
        }
        return false
    }
    
    /// 当前页面是否是群tab
    public var isInGroupTab: Bool {
        return editor.currentURL?.docs.isGroupTabUrl ?? false
    }
    
    /// 当前页面嵌入式模式加载
    /// 特性：
    /// 1. 阅读模式下不显示 TopContainer
    /// 2. 编辑模式下显示 TopContainer
    /// 3. 支持显示 SKEditButton
    public var isEmbedMode: Bool {
        docsInfo?.openDocsFrom == .baseInstructionDocx
    }
    /// 当前页面是否能够显示公告栏
    open var canBulletinShow: Bool { 
        return isAnnouncement ? false : true
    }
    
    @InjectedSafeLazy public var temporaryTabService: TemporaryTabService
    
    public internal(set) var docsURL: Strong<URL>!
    private(set) var shareFolderInfo: FolderEntry.ShareFolderInfo?
    private var padContainerType: UIViewController.Type?
    // 所有从前端触发的 Onboarding 的 Data Model，在 CommonInit 的 fillOnboardingMaterials() 中赋值 (子类重写)，也可在其他地方赋值
    open var onboardingTypes: [OnboardingID: OnboardingType] = [:]
    open var onboardingTitles: [OnboardingID: String] = [:]
    open var onboardingHints: [OnboardingID: String] = [:]
    open var onboardingIndexes: [OnboardingID: String] = [:]
    open var onboardingTargetRects: [OnboardingID: CGRect] = [:]
    open var onboardingArrowDirections: [OnboardingID: OnboardingStyle.ArrowDirection] = [:]
    open var onboardingIsLast: [OnboardingID: Bool] = [:]
    open var onboardingNextIDs: [OnboardingID: OnboardingID] = [:]
    open var onboardingDependenciesMap: [OnboardingID: [OnboardingID]] = [:]
    open var onboardingShouldCheckDependenciesMap: [OnboardingID: Bool] = [:]

    // MARK: - Flags

    var isFinishSetUp: Bool = false
    private var hasSetEditor = false
    open var isSupportedShowNewScene: Bool {
        if let url = self.editor.currentURL, let from = url.docs.queryParams?["from"] {
            if  from == "group_tab_notice" || from == DocsVCFollowFactory.fromKey || isSubscription {
                return false
            }
        }
        return true
    }
    /// 导航栏标题是否采取文档默认水平对齐方式（C 视图居左，R 视图居中）
    open var titleUseDefaultHorizontalAlignment: Bool { isHistoryRecord } // 历史记录、群公告统一居中
    var togglingEditModeState: Int = 0 // 是否处于编辑态切换间隔阈值中, 0显示,1动画中,2全隐藏
    open var enableFullscreenScrolling: Bool = SKDisplay.phone // 滚动进入沉浸式浏览
    var isDoneButtonVisible = false //完成按钮是否显示
    public var isInVideoConference: Bool { editor.isInVideoConference }
    public var isWindowFloating = false // 是否在MS悬浮窗状态

    // MARK: - Delegates

    public weak var orientationDirector: BrowserOrientationDirector?
    weak var delegate: BrowserViewControllerDelegate?
    weak var lifeCycleDelegate: BrowserViewControllerLifeCycle?
    public weak var spaceFollowAPIDelegate: SpaceFollowAPIDelegate?
    weak public var naviPopGestureDelegate: UIGestureRecognizerDelegate?
    private lazy var gestureDelegateRepeater = CommonGestureDelegateRepeater(self)

    // MARK: - Managers & Proxies
    public weak var wikiContextProvider: WikiContextProvider?
    private(set) lazy var bulletin: BulletinView = BulletinView()
    public private(set) var toolbarManager: DocsToolbarManager
    private(set) lazy var animator: BrowserViewAnimator = BrowserViewAnimator(topContainerHeightProvider: { [weak self] () -> CGFloat in
        return self?.topContainer.preferredHeight ?? 0.0
    }, bottomSafeAreaHeightProvider: { [weak self] () -> CGFloat in
        return self?.view.safeAreaInsets.bottom ?? 0.0
    })
    public var keyboard: Keyboard = Keyboard()
    /// FeelGood
    public var magicRegister: FeelGoodRegister?
    public let disposeBag = DisposeBag()

    ///bitable
    public var currentTableId: String = ""
    
    open var docName: String?
    
    public var tracingContext: TracingContext?
    public var tracingComponent: String {
        return LogComponents.fileOpen
    }
    public var tracingCommonParams: [String: Any] {
        return ["editorId": self.browerEditor?.jsEngine.editorIdentity ?? "noid"]
    }

    // 密钥删除页面
    public var keyDeleteHintView: UDEmptyView?
    public let isShowingDeleteHintView = BehaviorRelay(value: false)
    
    // 文档和版本删除页展示标记
    public var isShowingDocsDeleteHintView = false
    // 被删除文档恢复成功信号，仅用于wiki
    public var restoreSuccessRelay = BehaviorRelay(value: false)
    
    // MARK: - Overrides
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if forceFull, SKDisplay.phone {
            return .portrait
        }
        if let mask = orientationDirector?.supportedInterfaceOrientations {
            return mask
        } else {
            if docsInfo?.inherentType.alwaysOrientationsEnable ?? false {
                return .allButUpsideDown
            }
            return super.supportedInterfaceOrientations
        }
    }

    open override var canShowFullscreenItem: Bool {
        let enableType: [DocsType] = [.doc, .sheet, .docX, .file, .mindnote, .slides, .bitable, .wiki]
        self.bizType = docsInfo?.type ?? .unknownDefaultType
        return enableType.contains(docsInfo?.type ?? .unknownDefaultType)
    }

    open override var canShowCatalogItem: Bool {
        if let url = self.editor.currentURL, let from = url.docs.queryParams?["from"] {
            if  from == "group_tab_notice" || from == DocsVCFollowFactory.fromKey {
                return false
            }
        }
        let enableType: [DocsType] = [.doc, .docX]
        let currentRealType: DocsType
        if let wikiInfo = docsInfo?.wikiInfo {
            currentRealType = wikiInfo.docsType
        } else {
            currentRealType = docsInfo?.type ?? .unknownDefaultType
        }
        return enableType.contains(currentRealType) && SKDisplay.pad
    }

    open override var canShowBackItem: Bool {
        if isInVideoConference {
            return false
        } else if isInGroupTab {
            return self.hasBackPageIgnorParent()
        } else if isEmbedMode {
            return false
        } else {
            return true
        }
    }

    open override var canShowDoneItem: Bool { // 只有当显示场景为iPhone时，完成按钮显示在左侧，才需要与返回按钮的显示进行兼容
        return isDoneButtonVisible && SKDisplay.phone
    }

    public override var canBecomeFirstResponder: Bool { true }

    public override var keyCommands: [UIKeyCommand] { docsKeyCommands.keys.process() }
    
    lazy var docsKeyCommands = DocsKeyCommands(defaultKeyCommandInfos())
    
    public override var baseViewFrame: CGRect {
        // 文档loadview时使用mainSceneWindow size创建BaseView，因为文档会在viewDidLoad前会调用前端render，如果使用.zero会导致前端布局错乱。
        // 注意：window size在iPad多窗口下不一定是正确的，目前暂时没发现BadCase，理想情况是让前端迟点render或能更好的自适应(不闪烁)，但render流程会影响秒开率，从长计议...
        var viewFrame = userResolver.navigator.mainSceneWindow?.bounds ?? SKDisplay.activeWindowBounds
        if SKDisplay.pad {
            if let splitVC = lkSplitViewController {
                viewFrame = CGRectMake(0, 0, splitVC.contentSize.width, splitVC.contentSize.height) 
            }
        }
        return viewFrame
    }

    open override var isLoggingNavigationBarViewDelegated: Bool { true }
    public override var commonTrackParams: [String: String] {
        if let docsInfo = docsInfo {
            return DocsParametersUtil.createCommonParams(by: docsInfo)
        }
        return [:]
    }

    private var permissionHelper: DocPermissionHelper?
    
    public var forceFull = false {
        didSet {
            PermissionStatistics.isFormV2 = forceFull
        }
    }
    
    public let userResolver: UserResolver
    
    // MARK: - Life Cycle Events
    public required init(userResolver: UserResolver) {
        self.userResolver = userResolver
        self.toolbarManager = DocsToolbarManager(userResolver: userResolver)
        topContainerState = .normal
        DocsTracker.startRecordTimeConsuming(eventType: .browserVCInit, parameters: nil)
        super.init(nibName: nil, bundle: nil)
        forceFull = false
        //slardar memory warning from Lark iOS 内存压力监听方案: https://bytedance.feishu.cn/wiki/wikcnBptylmllRsEZDSQ0WkzcFg
        if UserScopeNoChangeFG.HZK.mainTabbarDisableForceRefresh {
            NotificationCenter.default.addObserver(self, selector: #selector(didReceiveMemoryLevelNotification(_:)), name: NSNotification.Name(rawValue: SKMemoryMonitor.memoryWarningNotification), object: nil)
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        SKMemoryMonitor.logMemory(when: "browser deinit", extraInfo: tracingCommonParams, component: LogComponents.fileOpen)
        rootTracing.info("vc deinit")
        rootTracing.startChildAndEndAutomatically(spanName: SKBrowserTrace.closeBrowser)
        rootTracing.finish()
        if isShowingDocsDeleteHintView, let docsInfo = self.docsInfo {
            deleteVersionCacheData(docsInfo)
        }
        editor.dismissApplyPermissionView()
        topContainer.banners.removeAll()
        editor.scrollViewProxy.removeObserver(self)
        editor.uiResponder.inputAccessory.realInputView = nil
        editor.uiResponder.inputAccessory.realInputAccessoryView = nil
        delegate?.browserViewControllerDeinit(self)
        DocsContainer.shared.resolve(DocsBulletinManager.self)?.removeObserver(self)
        permissionHelper?.unRegister()
        removeShadowFileIfNeeded()
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.async {
            self.editor.browserViewControllerDidLoad()
            DocsLogger.info("browserViewControllerDidLoad in main thread")
        }
        
        //适配三栏
        lkSplitViewController?.subscribe(self)
        
        rootTracing.startChild(spanName: SKBrowserTrace.browserViewDidLoad)
        self.commonInit()
        self.setupView()
        self.configure()
        
        // 判断下发的配置是否需要延时加载URL
        isFinishSetUp = true
        let time = OpenAPI.delayLoadUrl
        if time <= 0 {
            if self.editor.superview == nil {
                self.setupBrowser(self.editor)
            }
        }
        editor.modifyEditButtonProgress(0.0, animated: false, force: true)
        if let titleView = navigationBar.titleView as? SKNavigationBarTitle {
            titleView.uiDelegate = self
        }
        addRootTraitObserver()
        if isInGroupTab {
            navigationBar.titleView.shouldShowTexts = false
            navigationBar.navigationMode = .blocking(list: [.feed])
        } else if isEmbedMode {
            navigationBar.titleView.shouldShowTexts = false
            navigationBar.navigationMode = .allowing(list: [.done, .undo, .redo, .aiChatMode])
            topContainerState = .fixedHiding
        } else {
            navigationBar.navigationMode = DocsSDK.navigationMode
        }
        navigationBar.layoutAttributes.titleHorizontalAlignment = (SKDisplay.pad || isHistoryRecord) ? .center : .leading
        self.editor.docsLoader?.setNavibarHeight(naviHeight: self.navigationBar.frame.size.height)
        rootTracing.endSpan(spanName: SKBrowserTrace.browserViewDidLoad, params: ["delayLoadUrlTime": time])
        trackEnterDoc()
        //版本文档相关操作通知
        NotificationCenter.default.rx.notification(Notification.Name.Docs.versionDeleteNotifictaion)
            .subscribe { [weak self] notification in self?.didReceiveVersionDeleteNotification(notification) }
            .disposed(by: disposeBag)
        NotificationCenter.default.rx.notification(Notification.Name.Docs.versionPermissionChangeNotifictaion)
            .subscribe { [weak self] notification in self?.didReceiveVersionPermissionNotification(notification) }
            .disposed(by: disposeBag)
        NotificationCenter.default.rx.notification(Notification.Name.Docs.updateVersionInfoNotifictaion)
            .subscribe { [weak self] notification in self?.didReceiveVersionUpdateNotification(notification) }
            .disposed(by: disposeBag)
        NotificationCenter.default.rx.notification(Notification.Name.Docs.docsTokenCheckFailNotifictaion)
            .subscribe { [weak self] notification in self?.didReceiveTokenCheckFailNotification(notification) }
            .disposed(by: disposeBag)
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        editor.browserWillTransition(from: view.bounds.size, to: size)
        browerEditor?.callFunction(DocsJSCallBack.notifyWebViewSizeChange,
                                             params: [:],
                                             completion: nil)
    }

    open override func viewDidTransition(from oldSize: CGSize, to size: CGSize) {
        super.viewDidTransition(from: oldSize, to: size)
        updateNavBarTitleAlignment()
        topContainer.updateSubviewsContraints()
        editor.browserDidTransition(from: oldSize, to: size)
    }
    
    open override func viewDidSplitModeChange() {
        super.viewDidSplitModeChange()
        updateNavBarTitleAlignment()
        topContainer.updateSubviewsContraints()
        editor.browserDidSplitModeChange()
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard #available(iOS 13.0, *) else { return }
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        guard UIApplication.shared.applicationState != .background else { return }
        DocsLogger.info("darkmode.service --- \(String(describing: type(of: self))) user interface style did change")
        editor.jsEngine.simulateJSMessage(DocsJSService.simulateUserInterfaceChanged.rawValue, params: [:])
        
        //  Dark Mode 和 Light Mode 切换时，通知生命周期事件
        editor.browserTraitCollectionDidChange(previousTraitCollection)
    }

    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        toolbarManager.m_container.frame.size = view.frame.size
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DocsTracker.endRecordTimeConsuming(eventType: .browserVCInit, parameters: nil)
        toolbarManager.restoreH5EditStateIfNeeded()
        updateNavBarTitleAlignment()
        editor.browserWillAppear()
        if SKDisplay.pad, #available(iOS 15.1, *) {
        } else {
            bindInputAccessoryView(editor, with: toolbarManager.m_keyboardObservingView)
        }
        lifeCycleDelegate?.browserViewController(self, viewWillAppearAnimated: animated)
        enablePopGesture(true)
        setupNaviPopGestureDelegate()
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isViewDidShow = true
        rootTracing.startChild(spanName: SKBrowserTrace.browserViewDidAppear)
        
        if OpenAPI.delayLoadUrl > 0 {
            if self.editor.superview == nil {
                guard let tmpUrl = self.editor.docsLoader?.currentUrl else { return }
                self.editor.load(url: tmpUrl)
                self.setupBrowser(self.editor)
            }
        }
        if isFromTaskList {
            view.window?.makeKeyAndVisible()
        }
        updateNavBarTitleAlignment()
        if !ignoreLoadingInViewAppear() {
            self.editor.docsLoader?.delayShowLoading()
        }
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        keyboard.start()
        DocsLogger.info("BrowserViewController keyboad startListener", component: LogComponents.toolbar)
        editor.browserDidAppear()
        watermarkConfig.needAddWatermark = editor.browserInfo.docsInfo?.shouldShowWatermark ?? true
        lifeCycleDelegate?.browserViewController(self, viewDidAppearAnimated: animated)
        if let docInfo = editor.browserInfo.docsInfo, Display.pad {
            let docsOrMind = docInfo.type == .doc || docInfo.type == .mindnote || docInfo.type == .docX
            let wikiDoc = docInfo.wikiInfo?.docsType == .doc
            navigationBar.layoutAttributes.showsBottomSeparator = docsOrMind || wikiDoc
        }
        rootTracing.endSpan(spanName: SKBrowserTrace.browserViewDidAppear, params: ["delayLoadUrlTime": OpenAPI.delayLoadUrl])
        
        //关闭webview drag and drop属性
        if let webView = editor.editorView as? DocsWebViewV2,
           let dragInteraction = (webView.contentView?.interactions.compactMap { $0 as? UIDragInteraction }.first) {
            webView.contentView?.removeInteraction(dragInteraction)
        }
        
        if let editor = editor as? WebBrowserView {
            //需要注意的是，侧滑松手只会触发viewwillappear，不会触发did的 这里的表达的是一种广义的「后台切前台」，用「不可见到可见」可能更容易理解，webview不可见的时候回收的概率大大提高，及时强行reload也不见得就是稳定的，而是加一个flag，等「可见」再进行恢复
            rootTracing.info("backgroundToForeground from viewDidAppear")
            guard let loader = editor.webLoader else {
                rootTracing.info("backgroundToForeground from viewDidAppear and editor.webLoader is nil")
                return
            }
            loader.tryRecoveryTerminatedPageIfNeededWhenBecomeActive()
        }
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        editor.browserWillDisappear()
         //下掉键盘，先通知前端
        hideKeyboardAndNoticeWebIfNeed()
        lifeCycleDelegate?.browserViewController(self, viewWillDisappearAnimated: animated)
        enablePopGesture(true)
        self.dismissFollowView(isRefresh: false)
        if !isEmbedMode {
            self.navigationController?.interactivePopGestureRecognizer?.delegate = self.naviPopGestureDelegate
        }
        self.naviPopGestureDelegate = nil
        isViewDidShow = false
    }
    
    open override func keyboardWillHide() {
        hideKeyboardAndNoticeWebIfNeed()
    }
    
    /// 有时下掉键盘时没有通知到前端，导致下次触发编辑时，会不显示工具栏的问题。
    func hideKeyboardAndNoticeWebIfNeed() {
        if keyboard.isShow {
            let info = SimulateKeyboardInfo()
            info.trigger = "editor"
            info.isShow = false
            let params: [String: Any] = [SimulateKeyboardInfo.key: info]
            editor.jsEngine.simulateJSMessage(DocsJSService.simulateKeyboardChange.rawValue, params: params)
            editor.uiResponder.inputAccessory.realInputView = nil
            if floatKeyboardHasSubPanel {
                editor.uiResponder.inputAccessory.realInputAccessoryView = nil
            }
            keyboard.isShow = false
        }
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        rootTracing.startChild(spanName: SKBrowserTrace.browserViewDidDisappear)
        editor.browserDidDisappear()
        keyboard.stop()
        DocsLogger.info("BrowserViewController keyboad stopListener", component: LogComponents.toolbar)
        rootTracing.endSpan(spanName: SKBrowserTrace.browserViewDidDisappear)
        //hide loading
        guard let view = self.browerEditor else {
            return
        }
        UDToast.removeToast(on: view.window ?? view)
        lifeCycleDelegate?.browserViewController(self, viewDidDisappearAnimated: animated)
        //ipad上不会走didmove，所以在disappear之后延期0.05s判断是否还有parent，没有的话就clear
        if Display.pad {
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_100, execute: {
                if self.parent == nil {
                    self.rootTracing.info("ipad BrowserViewController.parent is nil,should celar")
                    self.didMove(toParent: nil)
                }
            })
        }
    }

    open override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        rootTracing.info("BrowserViewController didMove to parent: \(parent)")
        guard parent == nil else {
            // VC场景&分屏场景存在移除重新显示逻辑，需要对该场景进行适配
            // 判断当前VC是否弱引用在栈中，不存在需要重新加进去
            delegate?.browserViewControllerRedisplay(self)
            return
        }
        guard shouldDismissAfterMove() else { return }
        
        editor.dismissChildController()
        spaceFollowAPIDelegate?.follow(self, onOperate: .onDocumentVCDidMove)
        delegate?.browserViewControllerDismiss(self)
        OnboardingManager.shared.setTemporarilyRejectsUpcomingOnboardings(false)
    }
    
    open override func becomeFirstResponder() -> Bool {
        let res = super.becomeFirstResponder()
        DocsLogger.info("BrowserVC becomeFirstResponder:\(res)")
        return res
    }
    
    open override func resignFirstResponder() -> Bool {
        let res = super.resignFirstResponder()
        DocsLogger.info("BrowserVC resignFirstResponder:\(res)")
        return res
    }
    
    ///弹起其他VC之前（例如图片选择器拍照、查看图库，打开大图等）先抢一下webView上的焦点，不然可能在视图中出现键盘或者工具栏未下掉的情况
    func becomeFirstResponderFromEditorView() {
        if let firstResponder = UIResponder.docsFirstResponder() as? UIView,
           firstResponder.isDescendant(of: editor.editorView) {
            self.becomeFirstResponder()
        }
    }

    // MARK: 下面的方法会被子类重写，所以必须放在声明体内

    open func setupView() {
        // ⚠️：此函数被子类重写且未调用super，此处新加的代码务必检查子类函数中是否也要添加
        view.insertSubview(toolbarManager.m_container, belowSubview: statusBar)
        view.insertSubview(topContainer, belowSubview: toolbarManager.m_container)
        topContainer.snp.makeConstraints { it in
            it.top.equalTo(statusBar.snp.bottom)
            it.leading.trailing.equalToSuperview()
        }
        view.insertSubview(topPlaceholder, belowSubview: topContainer)
        topPlaceholder.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(topContainer)
            make.height.equalTo(topContainer.preferredHeight)
        }
        topContainer.delegate = self
        topContainer.setup()
        view.insertSubview(bottomPlaceholder, belowSubview: topContainer)
        bottomPlaceholder.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(0)
        }
        // ⚠️：此函数被子类重写且未调用super，此处新加的代码务必检查子类函数中是否也要添加
    }

    open func trackEnterDoc() {
        //原来在LarkSpaceKit的DocsViewController的打开文档时的上报
        //Tracker.post(TeaEvent("chat_view", category: "chat", params: ["chat_type": "doc"]))
        DocsTracker.log(event: "chat_view", parameters: ["chat_type": "doc"], category: "chat", shouldAddPrefix: false)
    }

    open func updateConfig(_ config: FileConfig) {
        isExternal = config.isExternal
        feedID = config.feedID
        fileConfig = config
    }

    open func setupFeelGood() {
        if let type = docsInfo?.type,
           let scenarioType = FeelGoodRegister.conver(type) {
            magicRegister = FeelGoodRegister(type: scenarioType) { [weak self] in return self }
        }
    }
    
    open func setShowTemplateTag(_ showTemplateTag: Bool) {
        
    }
    
    open func setShowExternalTag(needDisPlay: Bool, tagValue: String) {
        
    }

    open func fillOnboardingMaterials() {
        DocsLogger.error("onboarding 物料请在各个子类内填充")
    }

    open func showOnboarding(id: OnboardingID) {
        DocsLogger.error("SKBrowser 中的引导播放请求先集中到这里，请各子类分别实现该方法进行分发")
    }

    public func keyboardDidChangeState(_ options: Keyboard.KeyboardOptions) {}

    open func topContainerDidUpdateSubviews() {
        let newHeight = topContainer.preferredHeight
        let oldHeight = topPlaceholder.bounds.height
        // when full screen is not in progress, we can update top placeholder's height
        // when full screen is in progress, the top placeholder's height will automatically
        // be updated to the latest `topContainer.preferredHeight` in `-setFullScreenProgress`
        if animator.isFullScreenInProgress == false && topPlaceholder.superview != nil && topPlaceholder.bounds.height != newHeight && topContainerState != .fixedHiding {
//            debugPrint("&*() will change placeholder height")
            DocsLogger.info("topPlaceholder height changed from \(oldHeight) to \(newHeight)")
            topPlaceholder.snp.updateConstraints { (make) in
                make.height.equalTo(newHeight)
            }
            view.layoutIfNeeded()
            return
        }
        view.setNeedsLayout()
//        debugPrint("&*() topPlaceholder.frame.height: \(topPlaceholder.frame.height), topContainer.frame.height: \(topContainer.frame.height)")
    }

    /// Update the full screen progress and animates subviews if needed.
    ///
    /// The sign indicates whether the webview is dragging up or down, meanwhile the absolute value of `progress`
    /// should be the `contentOffset.y` of the webview divided by the height of the top container. That is,
    /// when `webview.contentOffset.y` becomes greater than or equal to `topContainer.frame.height`,
    /// the top container should reduce its `alpha` to `0`, and `webview` would occupy the rect owned by `topContainer`.
    ///
    /// - Parameters:
    ///   - progress: A `CGFloat` value from `-1.0` to `1.0`.
    ///    `0.0` means top container is totally visible and `webview.topAnchor == topContainer.bottomAnchor`,
    ///   whereas `±1.0` means top container is completely transparent and `webview.topAnchor == topContainer.topAnchor`.
    ///   - forceUpdate: Whether to update the subviews regardless of top container's fixing state.
    ///   - editButtonAnimated: whether should edit button's state be changed animatedly.
    ///   - topContainerAnimated: whether should top container's transparency be changed animatedly.
    open func setFullScreenProgress(_ progress: CGFloat, forceUpdate: Bool = false, editButtonAnimated: Bool = true, topContainerAnimated: Bool = true) {
        if topContainerState == .fixedHiding && isEmbedMode {
            topContainer.setAlpha(to: 0)
        } else {
            if topContainerState != .normal && !forceUpdate {
    //            DocsLogger.error("topContainerState is \(topContainerState) and no forceful update is requested. Will not set top container's state")
                return
            }
            let normalizedProgress = min(1.0, max(-1.0, progress))
            let absoluteProgress = abs(normalizedProgress)
            animateIfNeeded(topContainerAnimated) { [self] in
                if normalizedProgress < 0 {
                    // show top container immediately when the webview is dragging down
                    topContainer.setAlpha(to: 1.0)
                } else {
                    // only make the top container transparent when normalized progress is exactly ±1.0
                    topContainer.setAlpha(to: 1.0 - floor(absoluteProgress))
                }
                DocsLogger.info("topContainer alpha: \(topContainer.navBar.alpha)")
            }
        }
        editor.modifyEditButtonProgress(progress, animated: editButtonAnimated) { [self] in
            var targetState: Int
            if progress == 0.0 {
                targetState = 0
            } else if progress >= 1.0 {
                targetState = 2
            } else {
                targetState = 1
            }
            togglingEditModeState = targetState
        }
        view.layoutIfNeeded()
    }

    open func updateTopPlaceholderHeight(webviewContentOffsetY: CGFloat, scrollView: EditorScrollViewProxy? = nil, forceUpdate: Bool = false) {
        if topContainerState != .normal && !forceUpdate {
            // DocsLogger.error("topContainerState is \(topContainerState) and no forceful update is requested. Will not set top placeholder's height")
            return
        }
        let topContainerHeight = topContainer.preferredHeight
        // 要考虑当前文档内容较少，contentOffset最大值小于 topContainerHeight 的情况
        var canUpdate = true
        if let scroll = scrollView, scroll.contentSize.height - scroll.frame.height <= webviewContentOffsetY {
            canUpdate = false
        }
        guard canUpdate else {
            DocsLogger.info("topPlaceholder.frame.height not needUpdate")
            return
        }
        if webviewContentOffsetY >= 0 && webviewContentOffsetY <= topContainerHeight {
            topPlaceholder.snp.updateConstraints { (make) in
                make.height.equalTo(topContainerHeight - webviewContentOffsetY)
            }
        } else {
            topPlaceholder.snp.updateConstraints { (make) in
                make.height.equalTo(0)
            }
        }
        view.layoutIfNeeded()
        DocsLogger.info("topPlaceholder.frame.height: \(topPlaceholder.frame.height), topContainer.frame.height: \(topContainer.frame.height)")
    }
    
    open func updateBottomPlaceholderHeight(height: CGFloat) {
        bottomPlaceholder.snp.updateConstraints { (make) in
            make.height.equalTo(height)
        }
    }

    open func updatePhoneUI(for orientation: UIInterfaceOrientation) {
        guard SKDisplay.phone, let docType = docsInfo?.inherentType else { return }
        if orientation.isLandscape {
            // 横屏下只有 sheet 需要隐藏导航栏
            let shouldHideNavBar = docType == .sheet
            setNavigationBarHidden(shouldHideNavBar, animated: false)
        } else {
            setNavigationBarHidden(false, animated: false)
        }
        updateEditorConstraints(forOrientation: orientation)
    }

    // MARK: - navigation bar related events

    open override func updateNavBarHeightIfNeeded() {
        super.updateNavBarHeightIfNeeded()
        topContainerDidUpdateSubviews()
        customTCMangager.updateCurNavBarSizeType(self.navigationBar.sizeType)
    }

    open override func setNavigationBarHidden(_ hidden: Bool, animated: Bool) {
        if spaceFollowAPIDelegate?.followRole == .follower && !hidden {
            // 如果当前是 follower，在任何模式下都不应该显示导航栏
            return
        }
        if topContainerState == .fixedHiding && isEmbedMode && !hidden {
            // 如果当前是 EmbedMode fixedHiding 模式，不应该显示导航栏
            return
        }
        // 模版模式下，不支持隐藏导航栏
        if isFromTemplatePreview, hidden, !forceFull {
            return
        }
        UIView.animate(withDuration: animated ? TimeInterval(UINavigationController.hideShowBarDuration) : 0) { [self] in
            topContainer.navBar.isHidden = hidden
            topContainer.setNavBarAlpha(to: hidden ? 0.0 : 1.0)
            if docsInfo?.inherentType == .sheet {
                // sheet 场景下，不需要隐藏目录栏
                topContainer.setBannersAlpha(to: hidden ? 0.0 : 1.0)
            } else {
                topContainer.setAlpha(to: hidden ? 0.0 : 1.0)
            }
            topContainer.updateSubviewsContraints()
        }
    }

    open override func refreshLeftBarButtons() {
        super.refreshLeftBarButtons()
        let itemComponents: [SKBarButtonItem] = navigationBar.leadingBarButtonItems
        // iPad 下并且是标签页打开需要左上角展示「X」按钮
        if (self.presentingViewController != nil || (self.isTemporaryChild && Display.pad))
            && !hasBackPage
            && !canShowDoneItem
            && !itemComponents.contains(closeButtonItem) {
            self.navigationBar.leadingBarButtonItems.insert(closeButtonItem, at: 0)
        }
    }

    open override func onDoneBarButtonClick() {
        super.onDoneBarButtonClick()
        self.editor.callFunction(.clickCompleteButton, params: nil, completion: nil)
    }

    open override func fullscreenButtonItemAction() {
        super.fullscreenButtonItemAction()
        guard SKDisplay.pad, let lkSplitVC = lkSplitViewController, self.canShowCatalogItem else { return }
        let isFullscreenMode = lkSplitVC.splitMode == .secondaryOnly
        self.editor.callFunction(.clickFullScreenButton, params: ["isFullsceenMode": isFullscreenMode], completion: nil)
    }

    // canEmpty: iPad 模式下是否可以pop到兜底页
    open override func back(canEmpty: Bool = false) {
        DocsLogger.info("\(editor.jsEngine.editorIdentity) back", component: LogComponents.fileOpen)
        editor.vcFollowDelegate?.followWillBack()
        if #available(iOS 16.0, *) {
            setToPortraitIfNeeded()
        }
        super.back(canEmpty: canEmpty)
        if let vc = self.parent as? TabContainable {
            temporaryTabService.removeTab(id: vc.tabContainableIdentifier)
        } else {
            temporaryTabService.removeTab(id: tabContainableIdentifier)
        }
        refreshLeftBarButtons()
    }
    
    open override func setToPortraitIfNeeded() {
        if LKFeatureGating.ccmios16Orientation { return }
        if forceFull {
            DocsLogger.error("forceFull, not setToPortraitIfNeeded")
            return
        }
        super.setToPortraitIfNeeded()
    }

    open func configEditorScrollView() {
        editor.scrollViewProxy.contentInset = .zero
        editor.scrollViewProxy.clipsToBounds = false
        editor.scrollViewProxy.bounces = false
    }

    open func updateFullScreenProgress(_ editorViewScrollViewProxy: EditorScrollViewProxy) {
        updateTopPlaceholderHeight(webviewContentOffsetY: editorViewScrollViewProxy.contentOffset.y, scrollView: editorViewScrollViewProxy)
        let newProgress = animator.updateFullscreenProgress(with: editorViewScrollViewProxy.contentOffset)
        setFullScreenProgress(newProgress, editButtonAnimated: false)
    }

    /// BrowserViewNavigationItemObserver 的实现方法，由于需要在子 BrowserViewController 进行重写。iOS 13 直接无法标识为 @objc，所以迁移到这里来。
    open func trailingButtonBarItemsDidChange(from oldValue: [SKBarButtonItem], to newValue: [SKBarButtonItem]) {
        navigationBar.trailingBarButtonItems = newValue
        if newValue.count > 0 {
            checkCanShowVersionName()
        }
    }
    
    open func setSearchMode(searchMode: BrowserViewController.SearchMode) {
        
    }
    
    /// 容器是否有绑定的预加载容器
    open class func preloadEmbedVC(url: URL) {
    }
    
    // MARK: - Internal Methods
    func setInitEditor(_ browserView: BrowserView) {
        browserView.navigationItemObserver = self
        self.editor = browserView
        if UserScopeNoChangeFG.HZK.mainTabbarDisableForceRefresh {
            self.editor.browserViewLifeCycleEvent.addObserver(self)
        }
    }

    @objc
    func browserNavReceivedPopGesture(_ recognizer: UIGestureRecognizer) {
        editor.browserNavReceivedPopGesture()
        if recognizer.state == .began {
            let docType = self.docsInfo?.inherentType ?? .unknownDefaultType
            if docType == .bitable, let webview = self.browerEditor?.editorView as? DocsWebViewV2 {
                //解决侧滑与WebView中的手势冲突问题
                if webview.cancelWebTouchEventGestureRecognizer() {
                    DocsLogger.info("cancel WebView TouchEvent")
                }
            }
        }
    }

    func enablePopGesture(_ enable: Bool) {
        if navigationController?.responds(to: #selector(getter: UINavigationController.interactivePopGestureRecognizer)) ?? false {
            naviPopGestureRecognizerEnabled = enable
            navigationController?.interactivePopGestureRecognizer?.addTarget(self, action: #selector(browserNavReceivedPopGesture(_:)))
        }
    }

    func updateTitleAccordingUrl(_ urlStr: String?) {
        guard let urlStr = urlStr, let url = URL(string: urlStr) else { return }
        if url.docs.isDocHistoryUrl {
            navigationBar.title = BundleI18n.SKResource.Doc_More_History
        }
    }

    // 目前文档视图结构复杂，不正交，此处不要随便修改
    open func forceFullScreen() {
        forceFull = true
        setNavigationBarHidden(true, animated: false)
        updateEditorConstraints(forOrientation: Display.phone ? UIApplication.shared.statusBarOrientation : .portrait)
        statusBar.alpha = 0
        topContainer.alpha = 0
        topPlaceholder.alpha = 0
        navigationBar.alpha = 0
        if isFromTemplatePreview {
            if let templateVC = parent as? TemplatesPreviewViewController {
                templateVC.forceFullScreen()
            }
        }
    }
    
    open func cancelForceFullScreen() {
        forceFull = false
        setNavigationBarHidden(false, animated: false)
        updateEditorConstraints(forOrientation: Display.phone ? UIApplication.shared.statusBarOrientation : .portrait)
        statusBar.alpha = 1
        topContainer.alpha = 1
        topPlaceholder.alpha = 1
        navigationBar.alpha = 1
        if isFromTemplatePreview {
            if let templateVC = parent as? TemplatesPreviewViewController {
                templateVC.cancelForceFullScreen()
            }
        }
    }
    
    @objc
    open func updateEditorConstraints(forOrientation orientation: UIInterfaceOrientation) {
        guard editor.superview != nil, let type = docsInfo?.inherentType else { return }
        
        if forceFull { // 强制全屏模式，包括状态栏，安全区域都需要顶上去
            editor.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
            return
        }
        
        //docX横屏时webview占满屏幕，safeArea由前端布局（设计要求文档封面占满屏幕）
        let webViewFullScreen: Bool = type == .docX || type == .slides
        switch orientation {
        case .landscapeLeft: // notch right
            let trailingConstraint = webViewFullScreen ? view.snp.trailing : view.safeAreaLayoutGuide.snp.trailing
            editor.snp.remakeConstraints { (make) in
                make.top.equalTo(self.topPlaceholder.snp.bottom)
                make.leading.equalToSuperview()
                make.trailing.equalTo(trailingConstraint)
                make.bottom.equalTo(bottomPlaceholder.snp.top)
            }
        case .landscapeRight: // notch left
            let leadingConstraint = webViewFullScreen ? view.snp.leading : view.safeAreaLayoutGuide.snp.leading
            editor.snp.remakeConstraints { (make) in
                make.top.equalTo(self.topPlaceholder.snp.bottom)
                make.trailing.equalToSuperview()
                make.leading.equalTo(leadingConstraint)
                make.bottom.equalTo(bottomPlaceholder.snp.top)
            }
        default:
            editor.snp.remakeConstraints { (make) in
                make.top.equalTo(self.topPlaceholder.snp.bottom)
                make.top.greaterThanOrEqualTo(statusBar.snp.bottom).priority(.low)
                make.leading.trailing.equalToSuperview()
                make.bottom.equalTo(bottomPlaceholder.snp.top)
            }
        }
        view.layoutIfNeeded()
    }
    
    /// 忽略webview的loading，显示自定义的， 需要在ViewDidAppear前调用
    open func showCustomLoading() -> Bool {
        return false
    }
    /// 是否忽略掉viewDidAppear里的loading
    open func ignoreLoadingInViewAppear() -> Bool {
        return false
    }
    
    /// 权限页显示通知
    open func willShowNoPermissionView() {
    }
    
    /// 文档不可见
    open func handleBrowserViewNotFoundEvent() {
        
    }
    
    open func handleShowBitableAdvancedPermissionsSettingVC(data: BitableBridgeData, listener: BitableAdPermissionSettingListener?) {
        
    }

   ///注意，如果子类需要重写这个方法，务必保证可以调用到rerenderWebview，重新走一遍文档的打开流程 
    open func refresh() {
        editor.rerenderWebview()
    }
    
    // MARK: - Private Methods
    
    private func commonInit() {
        var dismissMode: UIScrollView.KeyboardDismissMode = .interactive
        if SKDisplay.pad, #available(iOS 15.1, *) {
            dismissMode = .none
        }
        editor.uiResponder.setKeyboardDismissMode(dismissMode)
        editor.bizPlugin?.editButtnAgent?.modifyEditButtonBottomOffset(height: 0)
        fillOnboardingMaterials()
        setupFeelGood()
    }

    private func configure() {
        keyboard.on(events: [.willShow, .didShow, .willHide, .didHide, .willChangeFrame, .didChangeFrame]) { [weak self] opt in
            self?.keyboardDidChangeState(opt)
            var floatKeyboardHasSubPanel: Bool = false
            if opt.displayType == .floating,
                let hasSubPanel = self?.floatKeyboardHasSubPanel {
                floatKeyboardHasSubPanel = hasSubPanel
            }
            //ipad悬浮键盘可以被拖动，无法通过键盘的位置计算工具栏高度，计算高度有两种情况：
            //1. floatKeyboardHasSubPanel == false 工具栏固定在底部，高度为0
            //2. floatKeyboardHasSubPanel == true  工具栏应附在subPanel上方
            self?.animator.keyboardDidChangeState(opt, floatKeyboardHasSubPanel)
            self?.toolbarManager.keyboardDidChangeState(opt)
            self?.browerEditor?.catalog?.keyboardDidChangeState(opt)
        }
        bulletin.delegate = self
        animator.toolContainer = toolbarManager.m_container
        animator.keyboardObservingView = toolbarManager.m_keyboardObservingView
        if docsInfo?.inherentType == .sheet, UserScopeNoChangeFG.LJW.sheetInputViewFix {
            animator.toolContainer?.snp.makeConstraints { (make) in
                make.bottom.equalTo(view.skKeyboardLayoutGuide.snp.top)
                make.height.width.equalToSuperview()
            }
        }
        NotificationCenter.default.rx.notification(.BrowserFullscreenMode)
            .subscribe { [weak self] notification in self?.setBrowserFullScreenMode(notification) }
            .disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(UIApplication.willResignActiveNotification)
            .subscribe { [weak self] _ in self?.willResignActive() }
            .disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification)
            .subscribe { [weak self] _ in self?.appDidBecomeActive() }
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(Notification.Name.Docs.publicPermissonUpdate)
            .subscribe { [weak self] _ in self?.notifyFrontReceiveShareLinkEditUpdate() }
            .disposed(by: disposeBag)

        WatermarkManager.shared.addListener(self)
    }
    
    func notifyFrontReceiveShareLinkEditUpdate() {
        let str = """
        document.dispatchEvent(new CustomEvent('formSharePermissionChange'))
        """
        editor.evaluateJavaScript(str, completion: nil)
    }

    @objc
    private func willResignActive() {
        editor.isInForground = false
        browerEditor?.callFunction(DocsJSCallBack.webviewVisibilityChange, params: ["visible": 0], completion: {(_, error) in
            if let err = error {
                DocsLogger.error("called webviewVisibilityChange failed", extraInfo: nil, error: err, component: nil)
            } else {
                DocsLogger.error("called webviewVisibilityChange success", extraInfo: nil, error: nil, component: nil)
            }
        })
    }

    @objc
    private func appDidBecomeActive() {
        editor.isInForground = true
        if #available(iOS 13.0, *) {
            let isDarkMode = UDThemeManager.getRealUserInterfaceStyle() == .dark
            if isDarkMode != editor.isRenderDarkMode {
                editor.jsEngine.simulateJSMessage(DocsJSService.simulateUserInterfaceChanged.rawValue, params: [:])
            }
        }
        browerEditor?.callFunction(DocsJSCallBack.webviewVisibilityChange, params: ["visible": 1], completion: {(_, error) in
            if let err = error {
                DocsLogger.error("called webviewVisibilityChange failed", extraInfo: nil, error: err, component: nil)
            } else {
                DocsLogger.error("called webviewVisibilityChange success", extraInfo: nil, error: nil, component: nil)
            }
        })
    }
    
    // 子类重写此函数，可以在在不同的位置添加 browser
    open func insertBrowser(_ browser: BrowserView) {
        view.insertSubview(browser, belowSubview: topContainer)
    }
    /// loading 等异常状态承载的view
    open func stateHostConfig() -> CustomStatusConfig? {
        return nil
    }
    
    open func permissionHostView() -> UIView? {
        return nil
    }
    
    @objc
    private func didReceiveMemoryLevelNotification(_ notification: Notification) {
        
        let userInfo = notification.userInfo
        // 如果在内存高水位(4)以上的level,需要释放多出来的webview
        if let flag = userInfo?["type"] as? Int32, flag >= OpenAPI.docs.memoryWarningLevel {
            DocsLogger.warning("receive MemoryLevel change: \(flag)", component: LogComponents.editorPool)
            DocsLogger.warning("didReceiveMemoryLevelNotification，begin removeMainTabBarCache")
            self.removeMainTabBarCache()
        }
    }

    private func setupBrowser(_ browser: BrowserView) {
        insertBrowser(browser)
        // iPad 上永远用 portrait 模式的布局
        updateEditorConstraints(forOrientation: Display.phone ? UIApplication.shared.statusBarOrientation : .portrait)

        animator.updateToolContainer(with: -(view.window?.safeAreaInsets.bottom ?? 0))
        animator.scrollProxy = editor.scrollViewProxy

        // Setup Module Config
        editor.scrollViewProxy.addObserver(self)
        toolbarManager.m_toolBar.delegate = self
        browser.editorView.setSKResponderDelegate(self)
        toolbarManager.keyboardObservingView.delegate = self
        editor.toolbarManagerProxy.setToolbarManager(toolbarManager)

        // Setup UI Config
        configEditorScrollView()

        NotificationCenter.default.post(name: DocsBulletinManager.bulletinRequestShowIfNeeded, object: self)
    }

    private func bindInputAccessoryView(_ browser: BrowserView, with view: UIView?) {
        if browser.uiResponder.inputAccessory.realInputAccessoryView != view {
            browser.uiResponder.inputAccessory.realInputAccessoryView = view
        }
        if toolbarManager.m_toolBar.sheetInputTextView.inputAccessoryView != view {
            toolbarManager.m_toolBar.sheetInputTextView.inputAccessoryView = view
        }
    }

    private func shouldDismissAfterMove() -> Bool {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone, .unspecified:
            return true
        case .pad:
            return !isTransfering(self)
        default:
            return false
        }
    }

    private func isTransfering(_ vc: UIViewController?) -> Bool {
        guard let vc = vc else {
            return false // default value
        }
        let isTransferingValue: Bool = vc.childrenIdentifier.contains(.isTransfering)
        return isTransfering(vc.parent) || isTransferingValue
    }

    private func setupNaviPopGestureDelegate() {
        guard (self.navigationController?.interactivePopGestureRecognizer?.delegate as? CommonGestureDelegateRepeater) != gestureDelegateRepeater else {
            DocsLogger.error("interactivePopGestureRecognizer?.delegate must not be self")
            return
        }
        if isEmbedMode {
            return // EmbedMode 不应该修改这里
        }
        self.naviPopGestureDelegate = self.navigationController?.interactivePopGestureRecognizer?.delegate
        self.navigationController?.interactivePopGestureRecognizer?.delegate = gestureDelegateRepeater
    }

    private func addRootTraitObserver() {
        RootTraitCollection.observer
            .observeRootTraitCollectionDidChange(for: view)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] _ in
                guard let self = self else {
                    return
                }
                self.refreshLeftBarButtons()
                self.updateNavBarTitleAlignment()
            }
            .disposed(by: disposeBag)
    }

    open func updateNavBarTitleAlignment() {
        if !titleUseDefaultHorizontalAlignment {
            var isRegular = view.window?.lkTraitCollection.horizontalSizeClass == .regular && view.window?.lkTraitCollection.verticalSizeClass == .regular
            if navigationBar.frame.width < 450, editor.docsInfo?.isVersion ?? false {
                isRegular = false
            }
            navigationBar.layoutAttributes.titleHorizontalAlignment = isRegular ? .center : .leading
        }
    }

    @objc
    func handleShortcutCommand(_ command: UIKeyCommand) {
        _handleShortcutCommand(command)
    }

    // MARK: Part of WebViewScrollViewObserver: extension 不支持 override
    open func editorViewScrollViewDidScroll(_ editorViewScrollViewProxy: EditorScrollViewProxy) {
        _editorViewScrollViewDidScroll(editorViewScrollViewProxy)
    }

    /// 获取键盘+工具栏的高度
    /// - Parameter ingnoreKeyboardHeight: 是否需要加上键盘高度
    /// - Returns: 键盘+工具栏的高度或工具栏的高度
    public func getToolBarHeightWithKeyboard(_ needKeyboardHeight: Bool = true) -> CGFloat {
        let toolBaHeight = toolbarManager.toolBar.frame.height
        let keyboardHeight = abs(toolbarManager.m_container.frame.minY)
        let sheetInputViewHeight: CGFloat = toolbarManager.toolBar.getSheetInputViewHeight()
        return needKeyboardHeight ? keyboardHeight + max(toolBaHeight, sheetInputViewHeight) : max(toolBaHeight, sheetInputViewHeight)
    }

    /// 移除当前文档的影子Drive文件
    private func removeShadowFileIfNeeded() {
        guard let shadowFileId = docsInfo?.shadowFileId else { return }
        DocsContainer.shared.resolve(DriveShadowFileManagerProtocol.self)?.removeShadowFile(id: shadowFileId)
    }
}

extension BrowserViewController: DocsCreateViewControllerRouter { }
/// EOF: REFRAIN FROM ADDING NEW METHODS DOWN HERE
/// PROTOCOL CONFORMANCES SHOULD BE WRITTEN IN `BrowserViewController+Delegates.swift`

// TODO: 前端会推送权限变化，所以这里似乎没有必要再监听一次，考虑移除掉
///监听权限变化
extension BrowserViewController {

    private func permissionChanged(response: DocPermissionInfo) {
        guard let permissionData = response.userPermissions?.rawData else {
            DocsLogger.info("BrowserView permissionChanged userPermissions rawData is nil")
            return
        }
        DocsLogger.info("BrowserVC update user permission")
        if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
            do {
                let data = try JSONSerialization.data(withJSONObject: permissionData)
                editor.permissionConfig.update(permissionData: data, for: .hostDocument, objType: docsInfo?.inherentType ?? .docX)
            } catch {
                DocsLogger.error("BrowserVC update user permission failed", error: error)
                spaceAssertionFailure("BrowserVC update user permission failed")
            }
        } else {
            editor.permissionConfig.update(userPermission: response.userPermissions, for: .hostDocument, objType: docsInfo?.inherentType ?? .docX) // 更新 host 可以随便传 objType
        }
        updateTemporaryTab()
    }
    public func setupMonitorPermissions(docsInfo: DocsInfo) {
        guard permissionHelper == nil else {
            DocsLogger.info("permissionHelper exist, file: \(DocsTracker.encrypt(id: docsInfo.token))")
            return
        }
        DocsLogger.info("BrowserView setupMonitorPermissions, file: \(DocsTracker.encrypt(id: docsInfo.token))")
        permissionHelper = DocPermissionHelper(fileToken: docsInfo.token, type: docsInfo.inherentType)
        permissionHelper?.startMonitorPermission(startFetch: { },
                                                permissionChanged: {[weak self] (info) in
                                                    self?.permissionChanged(response: info)
            },
                                                failed: { error in
                                                    DocsLogger.error("BrowserView.permissionChanged: \(error)")
        })
    }
}
