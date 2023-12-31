//
//  ChatContainerViewController.swift
//  LarkChat
//
//  Created by 赵家琛 on 2021/6/22.
//

import Foundation
import UIKit
import RxSwift
import LarkModel
import RxCocoa
import ServerPB
import LarkFoundation
import LKCommonsLogging
import SnapKit
import LarkUIKit
import LarkContainer
import LarkCore
import EENavigator
import LarkMessageCore
import LarkBadge
import LarkMessageBase
import EETroubleKiller
import LarkSafety
import LarkLocalizations
import LarkSDKInterface
import LKCommonsTracker
import Homeric
import LarkMessengerInterface
import LarkOpenFeed
import LarkKeyCommandKit
import LarkFeatureGating
import ThreadSafeDataStructure
import AppReciableSDK
import LarkMagic
import LarkOpenChat
import LarkSplitViewController
import LarkTraitCollection
import LarkSceneManager
import LarkSuspendable
import RustPB
import Heimdallr
import RichLabel
import UniverseDesignFont
import UniverseDesignTabs
import UniverseDesignColor
import Swinject
import LarkAIInfra
import FigmaKit
import LarkEmotionKeyboard
import LarkTracing
import UniverseDesignToast
import UniverseDesignActionPanel
import LarkSetting
import UniverseDesignDialog

final class ChatContainerViewController: BaseUIViewController, UserResolverWrapper, InnerChatControllerProtocol, EdgeNaviAnimatorGesDelegate,
                                         MyAIChatModeViewControllerProtocol {
    // 背景图
    lazy var backgroundImage: ChatBackgroundImageView? = {
        let pushChatTheme = self.dependency.pushCenter.observable(for: ChatTheme.self)
        return componentGenerator.backgroundImage(chat: self.chat.value, pushChatTheme: pushChatTheme)
    }()

    // 群置顶 - 吸顶
    lazy var pinSummaryView: ChatPinSummaryContainerView? = {
        return self.componentGenerator.pinSummaryView(
            pinSummaryContext: self.moduleContext.pinSummaryContext,
            pushWrapper: self.chatContainerViewModel.chatWrapper,
            chatVC: self
        )
    }()

    // 顶部区域显影状态
    var topContainerLockedToHide: Bool = false
    lazy var chatTabsView: ChatTabsTitleView = {
        let chatTabsView = ChatTabsTitleView(
            containerWidth: self.view.bounds.width,
            enableAddDriver: self.tabsViewModel.canManageTab.asDriver().map { $0.0 }
        )
        chatTabsView.router = self.tabsViewModel
        return chatTabsView
    }()

    private lazy var tabModule: ChatTabModule = {
        ChatTabModule.onLoad(context: self.moduleContext.tabContext)
        ChatTabModule.registGlobalServices(container: self.moduleContext.container)
        let module = ChatTabModule(context: self.moduleContext.tabContext)
        return module
    }()
    lazy var tabsViewModel: ChatTabsViewModel = {
        let chatWrapper = self.chatContainerViewModel.chatWrapper
        let tabsViewModel = ChatTabsViewModel(
            userResolver: userResolver,
            chat: chatWrapper.chat,
            tabModule: self.tabModule,
            targetVC: self,
            chatFromWhere: self.fromWhere
        )
        return tabsViewModel
    }()

    /// UI 正式视图是否已经构造完成
    private var subViewAleadySetup: Bool = false
    /// 是否开启群 tab 功能
    private var enableTabs: Bool = false
    /// 群 tab UI 展示/隐藏
    private var _displayTabs: Bool = false
    private(set) var displayTabs: Bool {
        get {
            return _displayTabs
        }
        set {
            if !subViewAleadySetup {
                _displayTabs = newValue
                return
            }
            if _displayTabs != newValue {
                _displayTabs = newValue
                self.configTopContainer()
            }
        }
    }

    /// 顶部区域隐藏的时候是否带上移动画
    private lazy var supportTopContainerTranformAnimation: Bool = {
        return userResolver.fg.staticFeatureGatingValue(with: "im.chat.mobile.header.fading")
    }()

    private var _displayWidget: Bool = false
    private(set) var displayWidget: Bool {
        get {
            return _displayWidget
        }
        set {
            if !subViewAleadySetup {
                _displayWidget = newValue
                return
            }
            if _displayWidget != newValue {
                _displayWidget = newValue
                self.configTopContainer()
                self.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }

    private let childViewLeastTopMargin: CGFloat = 12

    private func configTopContainer() {
        var bottomConstraintItem: SnapKit.ConstraintItem = self.naviBar.snp.bottom

        if displayWidget, let widgetView = self.widgetView {
            self.naviBar.observePanGesture { [weak widgetView] panGesture in
                widgetView?.handleNaviBarPan(panGesture)
            }
            if self.enableTabs {
                self.chatTabsView.observePanGesture { [weak widgetView] panGesture in
                    widgetView?.panGes(panGesture)
                }
            }
            widgetView.isHidden = false
            if widgetView.superview == nil {
                self.view.addSubview(widgetView)
                widgetView.snp.makeConstraints { make in
                    make.left.right.equalToSuperview()
                    make.top.equalTo(bottomConstraintItem)
                }
            }
            bottomConstraintItem = widgetView.snp.bottom
        } else {
            self.widgetView?.isHidden = true
        }

        if displayTabs {
            self.chatTabsView.isHidden = self.widgetExpandLimit?.value ?? false
            self.chatTabsView.snp.remakeConstraints { make in
                make.top.equalTo(bottomConstraintItem)
                make.left.right.equalToSuperview()
                make.height.equalTo(ChatTabsTitleView.ViewHeight)
            }
            bottomConstraintItem = self.chatTabsView.snp.bottom
        } else if self.enableTabs {
            self.chatTabsView.isHidden = true
        }

        if let pinSummaryView = self.pinSummaryView {
            if !pinSummaryView.isHidden {
                if pinSummaryView.superview == nil {
                    self.view.addSubview(pinSummaryView)
                    pinSummaryView.snp.makeConstraints { make in
                        make.left.right.equalToSuperview()
                        make.top.equalTo(bottomConstraintItem)
                    }
                }
                bottomConstraintItem = pinSummaryView.snp.bottom
            }
        }

        if displayWidget {
            self.topBlurView.isHidden = true
            if self.enableTabs { self.chatTabsView.backgroundColor = UIColor.ud.bgBody & UIColor.ud.bgBase }
            self.naviBar.setBackgroundColor(ChatWidgetsContainerView.UIConfig.widgetThemeColor)
            self.naviBar.setNavigationBarDisplayStyle(.custom(UIColor.ud.N00.alwaysLight))
            self.statusBarView.backgroundColor = ChatWidgetsContainerView.UIConfig.widgetThemeColor
        } else {
            self.topBlurView.isHidden = false
            self.topBlurView.snp.remakeConstraints { make in
                make.top.left.right.equalToSuperview()
                make.bottom.equalTo(bottomConstraintItem)
            }
            if self.enableTabs { self.chatTabsView.backgroundColor = UIColor.clear }
            self.naviBar.setBackgroundColor(UIColor.clear)
            self.naviBar.setNavigationBarDisplayStyle(self.initialBarStyle ?? .lightContent)
            self.statusBarView.backgroundColor = UIColor.clear
        }
        self.chatMessageTabPageAPI?.contentTopMarginHasChanged()
    }

    private weak var _chatMessageTabPageAPI: ChatMessageTabPageAPI?
    private var chatMessageTabPageAPI: ChatMessageTabPageAPI? {
        if _chatMessageTabPageAPI != nil { return _chatMessageTabPageAPI }
        _chatMessageTabPageAPI = try? self.moduleContext.resolver.resolve(type: ChatMessageTabPageAPI.self)
        return _chatMessageTabPageAPI
    }

    static let pageName = "\(ChatContainerViewController.self)"
    static let logger = Logger.log(ChatContainerViewController.self, category: "Module.IM.Message")
    /// Body中生成VC后，等多久再进行push跳转到该VC
    static let preLoadDataBufferTime: TimeInterval = 0.1

    var sourceID: String = UUID().uuidString

    /// push回调
    var pushChatVC: (() -> Void)?

    private var magicRegister: ChatMagicRegister?

    /// Chat 数据模型
    var chat: BehaviorRelay<Chat> {
        return self.chatContainerViewModel.chatWrapper.chat
    }

    /// 顶部毛玻璃视图
    private lazy var topBlurView: BackgroundBlurView = {
        return self.componentGenerator.topBlurView(chat: self.chat.value)
    }()

    private lazy var statusBarView: UIView = {
        let statusBarView = UIView()
        statusBarView.backgroundColor = UIColor.clear
        return statusBarView
    }()

    private lazy var widgetView: ChatWidgetsContainerView? = {
        return self.componentGenerator.widgetsView(
            moduleContext: self.moduleContext,
            pushWrapper: self.chatContainerViewModel.chatWrapper,
            targetVC: self
        )
    }()
    var widgetExpandDriver: Driver<Bool>? {
        return self.widgetView?.expandDriver
    }
    var widgetExpandLimit: BehaviorRelay<Bool>? {
        return self.widgetView?.expandLimitBehaviorRelay
    }

    /// 导航栏组件
    lazy var naviBar: ChatNavigationBar = {
        let view = self.componentGenerator.navigationBar(moduleContext: self.moduleContext,
                                                         pushWrapper: self.chatContainerViewModel.chatWrapper,
                                                         blurEnabled: false,
                                                         targetVC: self,
                                                         chatPath: self.chatPath)
        view.leastTopMargin = self.childViewLeastTopMargin
        self.initialBarStyle = view.navigationBarDisplayStyle()
        view.setBackgroundColor(UIColor.clear)
        afterFirstMessagesRenderDelegates.append(view)
        self.moduleContext.container.register(ChatOpenNavigationService.self) { [weak view] (_) -> ChatOpenNavigationService in
            return view ?? DefaultChatOpenNavigationService()
        }
        view.loadSubModuleData()
        return view
    }()
    /// 记录初始的 bar style
    private var initialBarStyle: OpenChatNavigationBarStyle?

    /// 水印waterMarkView
    var waterMarkView: UIView?
    /// 密聊录屏保护时占位的界面
    lazy var placeholderChatView: PlaceholderChatView? = {
        let placeholderChatView = self.componentGenerator.placeholderChatView()
        placeholderChatView?.setNavigationBarDelegate(self)
        return placeholderChatView
    }()

    private var _chatContainerViewModel: ChatContainerViewModel?
    var chatContainerViewModel: ChatContainerViewModel {
        get {
            if let _chatContainerViewModel {
                return _chatContainerViewModel
            } else {
                // https://bytedance.feishu.cn/docs/doccnsda3sk5AFsdzSw0NyMpq7e#
                fatalError("会话仍处于初始化阶段，暂无chatContainerViewModel,可使用performSafeWhenSetup方法暂存操作")
            }
        }
        set {
            self._chatContainerViewModel = newValue
        }
    }

    let userResolver: UserResolver
    private let fromWhere: ChatFromWhere
    private let disposeBag = DisposeBag()
    private let dependency: ChatControllerDependency
    private let moduleContext: ChatModuleContext
    private let chatId: String

    /// 引导
    private(set) lazy var guideManager: ChatContainerGuideManager = ChatContainerGuideManager(chatContainerVC: self, chatId: chatId)
    /// 当导航栏隐藏时，显示哪些悬浮按钮
    private var showFloatButtons: [FloatButtonType] {
        return [FloatButtonType.backButton]
    }
    /// 用于构造 VC 的 ChatViewModel 和 ChatMessagesViewModel 等信息
    private let componentGenerator: ChatViewControllerComponentGeneratorProtocol
    private let chatKeyPointTracker: ChatKeyPointTracker
    /// 中间态时占位的导航栏
    private var instantNav: InstantChatNavigationBar?
    /// 中间态时占位的键盘
    private var instantkeyboard: InstantChatKeyboard?

    /// 控制视图初始化流程
    private let initialDataAndViewControl: ChatInitialDataAndViewControl
    private var setupFinish: Bool {
        return initialDataAndViewControl.setupFinish
    }
    /// 首屏消息渲染回调
    private var afterFirstMessagesRenderDelegates: SafeArray<AfterFirstScreenMessagesRenderDelegate> = [] + .semaphore

    /// 从屏幕右边缘向左划出 VC 动画
    private var edgeNaviAnimation: EdgeNaviAnimator?
    private var isGroupOwner: Bool {
        self.chatContainerViewModel.currentAccountChatterId == self.chat.value.ownerId
    }
    private var screenProtectService: ChatScreenProtectService? {
        return self.moduleContext.chatContext.pageContainer.resolve(ChatScreenProtectService.self)
    }

    public var specificSource: SpecificSourceFromWhere? //细化fromWhere的二级来源

    @ScopedInjectedLazy private var chatDurationStatusTrackService: ChatDurationStatusTrackService?
    public required init(
        userResolver: UserResolver,
        chatId: String,
        initialDataAndViewControl: ChatInitialDataAndViewControl,
        fromWhere: ChatFromWhere,
        dependency: ChatControllerDependency,
        moduleContext: ChatModuleContext,
        componentGenerator: ChatViewControllerComponentGeneratorProtocol,
        chatKeyPointTracker: ChatKeyPointTracker,
        specificSource: SpecificSourceFromWhere? = nil
    ) {
        self.userResolver = userResolver
        self.chatId = chatId
        self.initialDataAndViewControl = initialDataAndViewControl
        self.dependency = dependency
        self.componentGenerator = componentGenerator
        self.fromWhere = fromWhere
        self.chatKeyPointTracker = chatKeyPointTracker
        self.moduleContext = moduleContext
        self.specificSource = specificSource
        super.init(nibName: nil, bundle: nil)
        self.registerMagicIfNeeded()
        componentGenerator.pageContainerRegister(chatId: chatId, context: moduleContext.chatContext)
        self.startInitialDataAndViewControl()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        self.isActive.accept(false)
        print("NewChat: ChatContainerViewController deinit")
    }

    // swiftlint:disable all
    override public func loadView() {
        //此处调loadView 1.使用系统默认复制的view.frame 2.setSecureView方法中可能没有命中生成替换view的逻辑，也会使用super中默认生成的
        super.loadView()
        if #available(iOS 13.0, *) {
            self.screenProtectService?.setSecureView(targetVC: self)
        }
    }
    // swiftlint:enable all

    // MARK: - Override VC 生命周期
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.supportSecondaryOnly = true
        self.supportSecondaryPanGesture = true
        self.supportSecondaryOnlyButton = true
        self.autoAddSecondaryOnlyItem = true
        self.keyCommandToFullScreen = true
        self.isNavigationBarHidden = true
        self.view.backgroundColor = UIColor.ud.bgBody & UIColor.ud.bgBase
        self.initialDataAndViewControl.viewDidLoad()
        self.rotateScreenIfNeed()
        performSafeWhenSetup { [weak self] in
            guard let self = self else { return }
            self.chatDurationStatusTrackService?.setGetChatBlock { [weak self] in
                return self?.chat.value
            }

            if let chatViewModel: ChatViewModel = self.moduleContext.tabContext.store.getValue(for: ChatMessageTabModuleStoreKey.chatViewModel.rawValue) {
                chatViewModel.viewIsNotShowingDriver.drive(onNext: { [weak self] notShowing in
                    self?.chatDurationStatusTrackService?.markIfViewIsNotShow(value: notShowing)
                }).disposed(by: self.disposeBag)
            }

            // 监听Chat主题的变化
            if self.backgroundImage != nil {
                let chatId = self.chatId
                self.dependency.pushCenter.observable(for: ChatTheme.self)
                    .filter({ theme in
                        theme.chatId == chatId
                    })
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] theme in
                        guard let self = self else { return }
                        switch theme.style {
                        case .image, .color, .key:
                            self.statusBarStyle = .default
                        case .defalut:
                            self.statusBarStyle = self.naviBar.statusBarStyle
                        case .unknown:
                            break
                        }
                    }).disposed(by: self.disposeBag)
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.performSafeWhenSetup { [weak self] in
            guard let self = self else { return }
            self.naviBar.viewWillAppear()
            if self.enableTabs { self.chatTabsView.resizeIfNeeded(self.view.bounds.width) }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        chatDurationStatusTrackService?.markIfViewControllerIsAppear(value: true)
        self.performSafeWhenSetup { [weak self] in
            guard let self = self else { return }

            self.naviBar.viewDidAppear()
            self.chatMessageTabPageAPI?.reportZoomInitializationIfNeeded()
        }
        HMDFrameDropMonitor.shared().addFrameDropCustomExtra(ChatTrack.CustomExtra)
        self.guideManager.viewDidAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        guard setupFinish else { return }
        self.guideManager.removeHintBubbleView()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        chatDurationStatusTrackService?.markIfViewControllerIsAppear(value: false)
        guard setupFinish else { return }
        HMDFrameDropMonitor.shared().removeFrameDropCustomExtra(ChatTrack.CustomExtra)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        guard setupFinish else {
            return
        }
        self.naviBar.viewWillTransition(to: size, with: coordinator)
        if self.enableTabs { self.chatTabsView.resizeIfNeeded(size.width) }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        func bringToFront(_ view: UIView) {
            if view.superview == self.view {
                self.view.bringSubviewToFront(view)
            }
        }
        if let placeholderChatView = self.placeholderChatView {
            bringToFront(placeholderChatView)
        }
        if let waterMarkView = self.waterMarkView {
            bringToFront(waterMarkView)
        }
        if setupFinish {
            self.pinSummaryView?.resizeIfNeeded(self.view.bounds.size.width)
        }
    }

    private func rotateScreenIfNeed() {
        //my ai分会场强制转到竖屏
        if let myAIPageService = try? self.moduleContext.userResolver.resolve(type: MyAIPageService.self), myAIPageService.chatMode {
            UIDevice.current.setValue(UIDeviceOrientation.portrait.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }

    // MARK: 状态栏
    var statusBarStyle = UIStatusBarStyle.default {
        didSet {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if self.displayWidget {
            return .lightContent
        }
        return statusBarStyle
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }

    // MARK: ChatNavigationBarDelegate
    override func backItemTapped() {
        navigator.pop(from: self)
    }

    // MARK: 全屏按钮
    override func splitSplitModeChange(splitMode: SplitViewController.SplitMode) {
        self.performSafeWhenSetup { [weak self] in
            guard let self = self else { return }
            self.naviBar.splitSplitModeChange(splitMode: splitMode)
        }
        if self.enableTabs { self.chatTabsView.resizeIfNeeded(view.bounds.size.width) }

        guard setupFinish, let transitionCoordinator = self.transitionCoordinator else {
            return
        }
        self.naviBar.viewWillTransition(to: view.bounds.size, with: transitionCoordinator)
    }

    // MARK: ChatMagicRegister
    fileprivate func registerMagicIfNeeded() {
        guard userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "lark.magic.chat.enable")) else {
            return
        }
        magicRegister = try? ChatMagicRegister(userResolver: userResolver) { [weak self] in return self }
    }

    // MARK: 展示/隐藏导航栏和 Tab
    @objc
    private func objcShowTopContainer(isShown: NSNumber) {
        guard !topContainerLockedToHide else { return }
        showTopContainerWithAnimation(isShown: isShown)
    }

    // MARK: 创建/移除中间态视图
    private func setupInstentView() {
        self.chatKeyPointTracker.loadTrackInfo?.showInstentView = true
        let instantNav = self.componentGenerator.instantChatNavigationBar()
        instantNav.delegate = self
        self.instantNav = instantNav
        self.view.addSubview(instantNav)
        instantNav.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
        }

        let instantkeyboard = self.componentGenerator.instantKeyboard()
        self.instantkeyboard = instantkeyboard
        self.view.addSubview(instantkeyboard)
        instantkeyboard.snp.makeConstraints { (make) in
            make.bottom.equalTo(self.viewBottomConstraint)
            make.left.right.equalToSuperview()
            make.height.equalTo(80)
        }
    }

    private func removeInstentView() {
        self.instantNav?.removeFromSuperview()
        self.instantkeyboard?.removeFromSuperview()
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer.name == emotionKeyboardHighPriorityGesture {
            return false
        }
       return true
   }

   func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
       if otherGestureRecognizer.name == emotionKeyboardHighPriorityGesture {
           return true
       }
       return false
   }

    // MARK: MyAIChatModeViewControllerProtocol
    func closeMyAIChatMode(needShowAlert: Bool) {
        if needShowAlert {
            self.showChatModeThreadClosedAlert()
        } else {
            self.closeBtnTapped()
        }
    }

    @available(iOS 13.0, *)
    func getCurrentSceneState() -> UIScene.ActivationState? {
        return self.currentScene()?.activationState
    }

    var isActive: BehaviorRelay<Bool> = BehaviorRelay(value: true)
}

// MARK: - 进群相关流程
extension ChatContainerViewController {
    private func performSafeWhenSetup(_ perform: @escaping () -> Void) {
        self.initialDataAndViewControl.performSafeWhenSetup(perform)
    }

    private var chatLogInfo: [String: String] {
        let chat = self.chat.value
        return [
            "chatMode": "\(chat.chatMode)",
            "chatType": "\(chat.type)",
            "isCrypto": "\(chat.isCrypto)",
            "lastMsgId": "\(chat.lastMessageId)",
            "badge": "\(chat.badge)",
            "lastMsgPosition": "\(chat.lastMessagePosition)",
            "readPositionBadgeCount": "\(chat.readPositionBadgeCount)",
            "lastReadPosition": "\(chat.lastReadPosition)",
            "lastMessagePositionBadgeCount": "\(chat.lastMessagePositionBadgeCount)",
            "readPosition": "\(chat.readPosition)",
            "lastVisibleMsgPosition": "\(chat.lastVisibleMessagePosition)",
            "displayInThreadMode": "\(chat.displayInThreadMode)",
            "aliveTime": "\(chat.restrictedModeSetting.onTimeDelMsgSetting.aliveTime)"
        ]
    }

    private func startInitialDataAndViewControl() {
        ChatContainerViewController.logger.info("chatTrace startFetchData \(self.chatId)")
        moduleContext.chatContext.pageContainer.beforeFetchFirstScreenMessages()
        self.initialDataAndViewControl.start { [weak self] (result) in
            switch result {
            case .success(let status):
                switch status {
                // chat获取后，子线程初始化相关业务组件
                case .blockDataFetched(data: let data):
                    self?.generateComponents(data.0)
                    self?.chatKeyPointTracker.loadTrackInfo?.fetchChatCost = data.fetchChatCost
                    self?.chatKeyPointTracker.loadTrackInfo?.fetchChatterCost = data.fetchChatterCost
                    ChatContainerViewController.logger.info(logId: "enterChat", "chatTrace new initData: \(data.0.id)", params: self?.chatLogInfo ?? [:])
                    ChatTracker.trackEnterChat(chat: data.0, from: self?.fromWhere.rawValue)
                    //在初始化业务组件之后主动执行push操作。
                    if let pushChatVC = self?.pushChatVC {
                        pushChatVC()
                    }
                // chat获取 & viewDidLoad调用后
                case .inNormalStatus:
                    self?.removeInstentView()
                    self?.beforeGenerateNormalViews()
                    self?.generateNormalViews()
                // 展示中间态
                case .inInstantStatus:
                    self?.setupInstentView()
                    self?.chatKeyPointTracker.loadTrackInfo?.initViewEndTime = CACurrentMediaTime()
                }
            case .failure(let error):
                guard let self = self else { return }
                let loadTrackInfo = self.chatKeyPointTracker.loadTrackInfo
                AppReciableSDK.shared.error(params: ErrorParams(biz: .Messenger,
                                                                scene: .Chat,
                                                                event: .enterChat,
                                                                errorType: .SDK,
                                                                errorLevel: .Exception,
                                                                errorCode: 1,
                                                                userAction: nil,
                                                                page: ChatContainerViewController.pageName,
                                                                errorMessage: nil,
                                                                extra: Extra(isNeedNet: false,
                                                                             latencyDetail: [:],
                                                                             metric: loadTrackInfo?.reciableExtraMetric ?? [:],
                                                                             category: loadTrackInfo?.reciableExtraCategory ?? [:])))
                ChatContainerViewController.logger.error("chatTrace fetchChat error \(self.chatId)", error: error)
            }
        }
    }

    /// 生成 vm 等业务组件
    /// 在获取必要信息后执行
    private func generateComponents(_ chat: Chat) {
        guard userResolver.valid else { return }
        LarkTracingUtil.startChildSpanByPName(spanName: LarkTracingUtil.generateComponents, parentName: LarkTracingUtil.firstRender)
        let start = CACurrentMediaTime()
        guard let chatPushWrapper = self.componentGenerator.chatPushWrapper(chat: chat) else { return }
        self.screenProtectService?.set(chat: chatPushWrapper.chat)
        self.componentGenerator.pageContainerRegister(pushWrapper: chatPushWrapper, context: self.moduleContext.chatContext)
        self.chatKeyPointTracker.chatInfo.chat = chat

        self.chatContainerViewModel = self.componentGenerator.chatContainerViewModel(pushWrapper: chatPushWrapper)
        self.componentGenerator.messageActionServiceRegister(pushWrapper: chatPushWrapper, moduleContext: self.moduleContext)
        let chatViewModel = try? self.componentGenerator.chatViewModel(pushWrapper: chatPushWrapper)
        let chatMessageVM = try? self.componentGenerator.chatMessageViewModel(pushWrapper: chatPushWrapper,
                                                                              pushHandlerRegister: self.dependency.pushHandlerRegister,
                                                                              context: self.moduleContext.chatContext,
                                                                              chatKeyPointTracker: chatKeyPointTracker,
                                                                              fromWhere: self.fromWhere)

        self.moduleContext.tabContext.store.setValue(chatViewModel, for: ChatMessageTabModuleStoreKey.chatViewModel.rawValue)
        self.moduleContext.tabContext.store.setValue(chatMessageVM, for: ChatMessageTabModuleStoreKey.chatMessagesViewModel.rawValue)
        enableTabs = self.componentGenerator.needDisplayTabs(chat: chat)
        if let chatViewModel { self.afterFirstMessagesRenderDelegates.append(chatViewModel) }
        if let chatMessageVM {
            self.afterFirstMessagesRenderDelegates.append(chatMessageVM)
            self.moduleContext.chatContext.dataSourceAPI = chatMessageVM
            if let myAIMainChatMessageVM = chatMessageVM as? OldMyAIMainChatMessagesViewModel {
                self.moduleContext.container.register(MyAIChatModeMessagesManager.self) { [weak myAIMainChatMessageVM] _ -> MyAIChatModeMessagesManager in
                    return myAIMainChatMessageVM ?? MyAIChatModeMessagesManagerEmptyImpl()
                }
            }
        }
        // MyAIPageService添加监听首屏
        if let pageService = try? self.moduleContext.userResolver.resolve(type: MyAIPageService.self) { self.afterFirstMessagesRenderDelegates.append(pageService) }
        self.chatKeyPointTracker.loadTrackInfo?.generateComponentsCost = ChatKeyPointTracker.cost(startTime: start)
        LarkTracingUtil.endSpanByName(spanName: LarkTracingUtil.generateComponents)
    }

    private func beforeGenerateNormalViews() {
        LarkTracingUtil.startChildSpanByPName(spanName: LarkTracingUtil.containerVCBeforeGenerateNormalViews, parentName: LarkTracingUtil.firstRender)
        if self.enableTabs {
            self.moduleContext.container.register(ChatOpenTabService.self) { [weak self] (_) -> ChatOpenTabService in
                return self?.tabsViewModel ?? DefaultChatOpenTabService()
            }
            self.afterFirstMessagesRenderDelegates.append(tabsViewModel)
            tabsViewModel.tabRefreshDriver
                .throttle(.milliseconds(300))
                .drive(onNext: { [weak self] (isHidden) in
                    guard let self = self else { return }
                    if isHidden {
                        self.displayTabs = false
                    } else {
                        self.displayTabs = true
                        self.chatTabsView.setModels(self.tabsViewModel.transformToTabTitleModels())
                        self.guideManager.checkShowTabGuide(self.tabsViewModel.findNeedShowGuideTabId())
                    }
                }).disposed(by: self.disposeBag)
            tabsViewModel.initTabs(tabsObservable: initialDataAndViewControl.tabPreLoadDataObservable,
                                   getBufferPushTabs: initialDataAndViewControl.getBufferPushTabs,
                                   pushTabsObservable: initialDataAndViewControl.tabsPushObservable)
        }
        LarkTracingUtil.endSpanByName(spanName: LarkTracingUtil.containerVCBeforeGenerateNormalViews)
    }

    /// 生成正式 UI 视图
    private func generateNormalViews() {
        LarkTracingUtil.startChildSpanByPName(spanName: LarkTracingUtil.containerVCGenerateNormalViews, parentName: LarkTracingUtil.firstRender)
        let start = CACurrentMediaTime()
        self.initView()
        self.chatKeyPointTracker.loadTrackInfo?.generateNormalViewsCost = ChatKeyPointTracker.cost(startTime: start)
        LarkTracingUtil.endSpanByName(spanName: LarkTracingUtil.containerVCGenerateNormalViews)
    }

    /// 正式 UI 生成后相关逻辑
    private func afterGenerateNormalViews() {
        LarkTracingUtil.startChildSpanByPName(spanName: LarkTracingUtil.containerVCAfterGenerateNormalViews, parentName: LarkTracingUtil.firstRender)
        let start = CACurrentMediaTime()
        self.naviBar.viewWillRealRenderSubView()
        self.chatKeyPointTracker.loadTrackInfo?.afterGenerateNormalViewsCost = ChatKeyPointTracker.cost(startTime: start)
        if self.chatKeyPointTracker.loadTrackInfo?.initViewEndTime == nil {
            self.chatKeyPointTracker.loadTrackInfo?.initViewEndTime = CACurrentMediaTime()
        }

        edgeNaviAnimation = EdgeNaviAnimator { [weak self] in
            guard let `self` = self else { return }
            ChatRouterAblility.routeToChatSetting(chat: self.chat.value, context: self.moduleContext.navigaionContext, source: .chatSwipeMobile, action: .chatSwipeMobile)
        }
        edgeNaviAnimation?.addGesture(to: view)
        edgeNaviAnimation?.gestureDelegate = self
        LarkTracingUtil.endSpanByName(spanName: LarkTracingUtil.containerVCAfterGenerateNormalViews)
        LarkTracingUtil.endSpanByName(spanName: LarkTracingUtil.firstRender)
    }
}

// MARK: - UI 相关布局初始化
extension ChatContainerViewController {
    private func initView() {
        // 导航栏
        self.view.addSubview(self.statusBarView)
        self.statusBarView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.top).priority(.high)
            make.bottom.greaterThanOrEqualTo(self.view.snp.top).offset(self.childViewLeastTopMargin).priority(.required)
        }
        self.view.addSubview(self.topBlurView)
        self.statusBarStyle = self.naviBar.statusBarStyle
        self.view.addSubview(naviBar)
        naviBar.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
        }
        observeBadge()
        setupMessageVC()

        if enableTabs {
            self.view.addSubview(chatTabsView)
            chatTabsView.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.height.equalTo(ChatTabsTitleView.ViewHeight)
                make.top.equalTo(self.naviBar.snp.bottom)
            }
        }
        topBlurView.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
            make.bottom.equalTo(self.naviBar.snp.bottom)
        }
        self.configTopContainer()
        if let messageVC = self.chatMessageTabPageAPI as? ChatMessagesViewController {
            self.naviBar.delegate = messageVC
        }

        self.chatContainerViewModel
            .getWaterMarkImage()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (image) in
                guard let `self` = self,
                      let waterMarkImage = image else { return }
                self.waterMarkView?.removeFromSuperview()
                self.waterMarkView = waterMarkImage
                self.view.addSubview(waterMarkImage)
                waterMarkImage.contentMode = .top
                waterMarkImage.snp.makeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
            }).disposed(by: self.disposeBag)

        // 添加聊天背景图
        if let backgroundImage = backgroundImage {
            self.view.addSubview(backgroundImage)
            backgroundImage.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            self.view.sendSubviewToBack(backgroundImage)
            backgroundImage.setImage(theme: self.chat.value.theme) { [weak self] mode in
                guard let self = self else { return }
                self.statusBarStyle = mode == .originMode ? self.naviBar.statusBarStyle : .default
            }
        }
        self.subViewAleadySetup = true
        self.afterGenerateNormalViews()
    }

    private func setupMessageVC() {
        let metaModel = ChatTabMetaModel(chat: self.chat.value, type: .message)
        guard let messageVC = self.tabModule.getContent(metaModel: metaModel, chat: self.chat.value) as? ChatMessagesViewController else { return }

        self.addChild(messageVC)
        self.view.insertSubview(messageVC.view, at: 0)
        messageVC.view.snp.makeConstraints { make in
            make.left.bottom.right.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide).priority(.high)
            make.top.greaterThanOrEqualToSuperview().offset(self.childViewLeastTopMargin).priority(.required)
        }
        messageVC.didMove(toParent: self)
    }
}

extension ChatContainerViewController: ChatMessageBaseDelegate {
    var contentTopMargin: CGFloat {
        var topMargin: CGFloat = self.naviBar.naviBarHeight + (self.displayTabs ? ChatTabsTitleView.ViewHeight : 0) + (self.displayWidget ? ChatWidgetsContainerView.UIConfig.barHeight : 0)
        if let pinSummaryView = self.pinSummaryView, !pinSummaryView.isHidden {
            topMargin += ChatPinSummaryContainerView.ViewHeight
        }
        return topMargin
    }

    func getTopContainerBottomConstraintItem() -> SnapKit.ConstraintItem? {
        if let pinSummaryView = self.pinSummaryView,
           !pinSummaryView.isHidden,
           pinSummaryView.superview != nil {
            return pinSummaryView.snp.bottom
        }
        if displayTabs, self.chatTabsView.superview != nil {
            return self.chatTabsView.snp.bottom
        }
        if displayWidget, self.widgetView?.superview != nil {
            return self.widgetView?.snp.bottom
        }
        if self.naviBar.superview != nil {
            return self.naviBar.snp.bottom
        }
        return nil
    }

    func keyboardContentHeightWillChange(_ isFold: Bool) {
        self.widgetView?.handleKeyboardContentHeightWillChange(isFold)
        self.pinSummaryView?.handleKeyboardContentHeightWillChange(isFold)
    }

    func messagesBeenRendered() {
        for delegate in self.afterFirstMessagesRenderDelegates.getImmutableCopy() {
            delegate.afterMessagesRender()
        }
        var params: [AnyHashable: Any] = [:]
        if enableTabs {
            params += tabsViewModel.viewParams
        }
        // 如果是分会场，则需要上传app_name
        if let myAIPageService = try? self.moduleContext.userResolver.resolve(type: MyAIPageService.self), myAIPageService.chatMode {
            params += ["app_name": myAIPageService.chatModeConfig.extra["app_name"] ?? "other"]
        }
        IMTracker.Chat.Main.View(self.chat.value, params: params, self.fromWhere)

        self.widgetView?.hasWidget
            .asDriver(onErrorJustReturn: false)
            .drive(onNext: { [weak self] hasWidget in
                self?.displayWidget = hasWidget
            }).disposed(by: self.disposeBag)
        self.widgetExpandLimit?
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
            .drive(onNext: { [weak self] limit in
                guard let self = self, self.enableTabs else { return }
                if limit {
                    self.chatTabsView.isHidden = true
                } else if self.displayTabs {
                    self.chatTabsView.isHidden = false
                } else {
                    self.chatTabsView.isHidden = true
                }
            }).disposed(by: self.disposeBag)
        self.widgetView?.setup(self.view.bounds.size)

        self.pinSummaryView?.setup()
        self.pinSummaryView?.displayBehaviorRelay
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false).drive(onNext: { [weak self] display in
                self?.configTopContainer()
                if display {
                    /// 吸顶视图刚出现的时候可能获取不到 target view，导致引导异常，因此延迟弹出引导
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                        self?.guideManager.checkShowGuideIfNeeded(.pinSummary)
                    }
                }
            }).disposed(by: self.disposeBag)
    }

    func showNaviBarMultiSelectCancelItem(_ isShow: Bool) {
        self.naviBar.showMultiSelectCancelItem(isShow)
        self.widgetView?.handleMultiselect(isShow)
        self.pinSummaryView?.handleMultiselect(isShow)
    }

    func showTopContainerWithAnimation(isShown: NSNumber) {
        var getAnimationViews: () -> [UIView] = {
            var animationViews: [UIView?] = []
            if self.enableTabs { animationViews.append(self.chatTabsView) }
            animationViews.append(self.topBlurView)
            animationViews.append(self.chatMessageTabPageAPI?.bannerView)
            animationViews.append(self.pinSummaryView)
            animationViews.append(self.widgetView)
            return animationViews.compactMap { $0 }
        }

        let show = isShown.boolValue
        if !supportTopContainerTranformAnimation {
            let animateDuration: TimeInterval = 0.3
            if show {
                UIView.animate(withDuration: animateDuration, animations: {
                    getAnimationViews().forEach { $0.alpha = 1 }
                })
                self.naviBar.show(style: .normal, animateDuration: animateDuration)
            } else {
                UIView.animate(withDuration: animateDuration, animations: {
                    getAnimationViews().forEach { $0.alpha = 0 }
                }) { _ in
                    self.widgetView?.foldWhenHide()
                }
                self.naviBar.show(style: .floatButtons(showFloatButtons, translationY: 0), animateDuration: animateDuration)
            }
        } else {
            if show {
                let animateDuration: TimeInterval = 0.5
                UIView.animate(withDuration: animateDuration, animations: {
                    getAnimationViews().forEach {
                        $0.alpha = 1
                        $0.transform = .identity
                    }
                })
                self.naviBar.show(style: .normal, animateDuration: animateDuration)
            } else {
                let animateDuration: TimeInterval = 0.3
                let translationY: Double = -20
                let transformChange = CGAffineTransform(translationX: 0, y: translationY)
                UIView.animate(withDuration: animateDuration, animations: {
                    getAnimationViews().forEach {
                        $0.alpha = 0
                        $0.transform = transformChange
                    }
                }) { _ in
                    self.widgetView?.foldWhenHide()
                }
                self.naviBar.show(style: .floatButtons(showFloatButtons, translationY: translationY), animateDuration: animateDuration)
            }
        }
    }

    func showChatModeThreadClosedAlert() {
        guard let aiInfo = try? userResolver.resolve(type: MyAIInfoService.self) else { return }
        let dialog = UDDialog()
        dialog.setContent(text: BundleI18n.AI.MyAI_Chat_ChatExpiredReInvocate_aiName_Toast(aiInfo.defaultResource.name))
        dialog.addButton(text: BundleI18n.LarkChat.Lark_Legacy_IKnow) { [weak self] in
            self?.closeBtnTapped()
        }
        navigator.present(dialog, from: self)
    }

    func showPlaceholderView(_ isShow: Bool) {
        if isShow {
            /// 收起键盘
            self.view.endEditing(true)
            /// 显示占位图
            if let placeholderChatView = self.placeholderChatView {
                self.view.addSubview(placeholderChatView)
                placeholderChatView.snp.makeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
            }
        } else {
            /// 移除占位图
            self.placeholderChatView?.removeFromSuperview()
        }
    }
}

// MARK: - ChatDocSpaceTabDelegate
extension ChatContainerViewController: ChatDocSpaceTabDelegate {
    func jumpToChat(messagePosition: Int32) {
        self.customLocate(by: "\(messagePosition)", with: [:], animated: false)
    }
}

// MARK: - FragmentLocate
extension ChatContainerViewController: FragmentLocate {
    public func customLocate(by fragment: String, with context: [String: Any], animated: Bool) {
        self.chatMessageTabPageAPI?.customLocate(by: fragment, with: context, animated: animated)
    }
}

// MARK: - Badge 相关
extension ChatContainerViewController {
    private func observeBadge() {
        // chat页红点Root
        self.view.badge.observe(for: chatPath)
        // 该红点不显示，仅用于构造路径
        self.view.badge.set(type: .clear)
    }
}

// MARK: - InstantChatNavigationBarDelegate & PlaceholderChatNavigationBarDelegate
extension ChatContainerViewController: InstantChatNavigationBarDelegate, PlaceholderChatNavigationBarDelegate {
    func backButtonClicked() {
        navigator.pop(from: self)
    }
}

// MARK: - ChatOpenService
extension ChatContainerViewController: ChatOpenService {
    /// "chat_id" 拼接\(chid_id)
    var chatPath: Path { return Path().prefix(Path().chat_id, with: chat.value.id) }

    func chatVC() -> UIViewController {
        return self
    }

    func lockTopContainerCompressedStateTo(_ isCompressed: Bool) {
        self.showTopContainerWithAnimation(isShown: NSNumber(value: !isCompressed))
        topContainerLockedToHide = isCompressed
    }

    func setTopContainerShowDelay(_ show: Bool) {
        if supportTopContainerTranformAnimation {
            NSObject.cancelPreviousPerformRequests(withTarget: self)
            if !show {
                self.perform(#selector(objcShowTopContainer(isShown:)), with: NSNumber(value: show))
            } else {
                self.perform(#selector(objcShowTopContainer(isShown:)), with: NSNumber(value: show), afterDelay: 0.5, inModes: [.tracking, .common])
            }
        } else {
            NSObject.cancelPreviousPerformRequests(withTarget: self)
            self.perform(#selector(objcShowTopContainer(isShown:)), with: NSNumber(value: show), afterDelay: 0.2, inModes: [.tracking, .common])
        }
    }

    func chatTopNoticeChange(updateNotice: @escaping ((ChatTopNotice?) -> Void)) {
        self.chatMessageTabPageAPI?.setUpdateTopNotice(updateNotice: updateNotice)
    }

    func currentSelectMode() -> ChatSelectMode {
        return (self.chatMessageTabPageAPI?.isMultiSelecting() ?? false) ? .multiSelecting : .normal
    }

    func endMultiSelect() {
        self.chatMessageTabPageAPI?.cancelItemClicked()
    }
}

extension ChatContainerViewController: ChatCloseDetailLeftItemService {
    var source: SpecificSourceFromWhere? { return self.specificSource }
}

// MARK: - 页面支持收入多任务浮窗

extension ChatContainerViewController: ViewControllerSuspendable {

    var suspendID: String {
        return chatId
    }

    var suspendSourceID: String {
        return sourceID
    }

    var suspendIcon: UIImage? {
        guard setupFinish else {
            return nil
        }
        return self.componentGenerator.suspendIcon(chat: chat.value)
    }

    var suspendIconKey: String? {
        guard setupFinish else {
            return nil
        }
        return chat.value.avatarKey
    }

    var suspendIconEntityID: String? {
        guard setupFinish else {
            return nil
        }
        return chat.value.chatter?.id ?? chatId
    }

    var suspendTitle: String {
        guard setupFinish else {
            return ""
        }
        return chat.value.displayName
    }

    var suspendURL: String {
        return "//client/chat/\(chatId)"
    }

    var suspendParams: [String: AnyCodable] {
        return [:]
    }

    var suspendGroup: SuspendGroup {
        return .chat
    }

    var isWarmStartEnabled: Bool {
        return false
    }

    var analyticsTypeName: String {
        guard setupFinish else {
            return ""
        }
        switch chat.value.type {
        case .p2P:
            if chat.value.chatter?.type == .bot {
                return "bot"
            } else if chat.value.isCrypto {
                return "secret"
            } else {
                return "private"
            }
        case .group, .topicGroup:
            return "group"
        @unknown default:
            return "private"
        }
    }

    // MARK: 处理右侧交互式转场动画与浮窗动画的冲突
    func pushAnimationController(from: UIViewController, to: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let edgeNaviAnimation = edgeNaviAnimation else {
            return pushAnimationController(for: to)
        }
        return edgeNaviAnimation.interactive ? edgeNaviAnimation : pushAnimationController(for: to)
    }

    func interactiveTransitioning(with animatedTransitioning: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        (edgeNaviAnimation?.interactive ?? false) ? edgeNaviAnimation : nil
    }
}

extension ChatContainerViewController: FeedSelectionInfoProvider {
    func getFeedIdForSelected() -> String? {
        return self.chatId
    }
}

// MARK: - ChatMessageTabPageAPI Protocol
protocol ChatMessageTabPageAPI: AnyObject {
    /// 路由定位
    func customLocate(by fragment: String, with context: [String: Any], animated: Bool)
    func reportZoomInitializationIfNeeded()

    var bannerView: UIView { get }
    func setUpdateTopNotice(updateNotice: @escaping ((ChatTopNotice?) -> Void))
    func contentTopMarginHasChanged()
    func isMultiSelecting() -> Bool
    func cancelItemClicked()
}

final class DefaultChatMessageTabPageAPI: ChatMessageTabPageAPI {
    func customLocate(by fragment: String, with context: [String: Any], animated: Bool) {}
    func reportZoomInitializationIfNeeded() {}

    /// banner相关
    var bannerView: UIView { return UIView() }
    func setUpdateTopNotice(updateNotice: @escaping ((ChatTopNotice?) -> Void)) {}
    func contentTopMarginHasChanged() {}
    func isMultiSelecting() -> Bool { return false }
    func cancelItemClicked() {}
}
