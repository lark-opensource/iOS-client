//
//  ChatMessagesViewController.swift
//  LarkChat
//
//  Created by 赵家琛 on 2021/7/16.
//

import Foundation
import UIKit
import RxSwift
import LarkModel
import RxCocoa
import LarkFoundation
import LKCommonsLogging
import SnapKit
import LarkUIKit
import LarkContainer
import LarkCore
import LarkKeyboardView
import EENavigator
import LarkMessageCore
import UniverseDesignToast
import LarkMessageBase
import EETroubleKiller
import LarkAlertController
import LarkSafety
import LarkLocalizations
import LarkSDKInterface
import LarkSendMessage
import LarkPerf
import LKCommonsTracker
import Homeric
import LarkMessengerInterface
import LarkKeyCommandKit
import LarkInteraction
import LarkFeatureGating
import ThreadSafeDataStructure
import EditTextView
import LarkAppConfig
import AppReciableSDK
import LarkAI
import LarkOpenChat
import LarkTraitCollection
import RustPB
import ServerPB
import Heimdallr
import RichLabel
import LarkAccountInterface
import LarkSplitViewController
import LarkSceneManager
import UniverseDesignFont
import UniverseDesignColor
import LarkTracing
import LarkStorage
import UniverseDesignDialog
import LarkGuideUI
import LarkGuide
import LarkIMMention
import ByteWebImage
import LarkRustClient
import TangramService
import LarkFocus
import LarkChatOpenKeyboard
import LarkSetting
import LarkAIInfra
import LarkChatKeyboardInterface

class ChatMessagesViewController: BaseUIViewController, SplitViewControllerProxy, UserResolverWrapper {
    var userResolver: UserResolver { chatViewModel.userResolver }

    static let pageName = "\(ChatMessagesViewController.self)"
    static let logger = Logger.log(ChatMessagesViewController.self, category: "Module.IM.Message")

    var controllerService: ChatViewControllerService?
    var fixedBottomBaseInset: CGFloat { 24 + self.tableView.safeAreaInsets.bottom }

    /// 我被移出群聊、主动退出群聊、解散群聊时的执行操作
    lazy var doActionWhenKickOff: (() -> Void) = {
        return { [weak self] in
            guard let targetVC = self?.targetVC else { return }
            if Display.pad,
               targetVC.navigationController?.realViewControllers.first == targetVC {
                let showDefaultVC = { [weak self] in
                    guard let self, let targetVC = self.targetVC else { return }
                    if let customSplitViewController = targetVC.larkSplitViewController {
                        self.navigator.showDetail(
                            DefaultDetailController(),
                            wrap: LkNavigationController.self,
                            from: customSplitViewController,
                            completion: nil
                        )
                    } else {
                        if #available(iOS 13.0, *) {
                            /// 删除独立 scene
                            if let sceneInfo = targetVC.currentScene()?.sceneInfo,
                               !sceneInfo.isMainScene() {
                                SceneManager.shared.deactive(from: targetVC)
                            }
                        }
                    }
                }
                if let navigationController = targetVC.navigationController,
                    navigationController.presentedViewController != nil {
                    navigationController.dismiss(animated: true, completion: showDefaultVC)
                } else {
                    showDefaultVC()
                }
            } else if !targetVC.hasBackPage, targetVC.presentingViewController != nil {
                targetVC.dismiss(animated: true)
            } else {
                targetVC.popSelf()
            }
        }
    }()

    @ScopedInjectedLazy var messageAPI: MessageAPI?
    @ScopedInjectedLazy(\SendMessageAPI.statusDriver) var sendMessageStatusDriver: Driver<(LarkModel.Message, Error?)>?
    @ScopedInjectedLazy var modelService: ModelService?
    @ScopedInjectedLazy private var alertService: PostMessageErrorAlertService?
    @ScopedInjectedLazy var chatSecurityControlService: ChatSecurityControlService?
    @ScopedInjectedLazy var topNoticeService: ChatTopNoticeService?
    @ScopedInjectedLazy var foldApproveDataService: FoldApproveDataService?
    @ScopedInjectedLazy private var chatAPI: ChatAPI?

    var myAIService: MyAIService? {
        try? self.userResolver.resolve(type: MyAIService.self)
    }

    weak var chatOpenService: ChatOpenService?
    weak var chatMessageBaseDelegate: ChatMessageBaseDelegate?
    // chat组件的场景
    private lazy var chatComponentScene: ChatThemeScene = chat.value.theme?.componentScene ?? .defaultScene
    // chat的主题模式
    private var chatThemeMode: SafeAtomic<ServerPB_Entities_ChatBackgroundEntity.BackgroundMode>

    @ScopedInjectedLazy var videoMessageSendService: VideoMessageSendService?
    /// bannerContext
    let bannerContext: ChatBannerContext

    /// 所有待展示banner的集合：入群申请、视频会议卡片、日程卡片
    lazy var bannerView: UIView = {
        let banner = self.componentGenerator.chatBanner(pushWrapper: self.chatMessageViewModel.chatWrapper,
                                                        context: self.bannerContext) ?? UIView()
        self.bannerContext.container.register(ChatOpenBannerService.self) { [weak banner] (_) -> ChatOpenBannerService in
            return (banner as? ChatBannerView) ?? DefaultChatOpenBannerService()
        }
        (banner as? ChatBannerView)?.changeDisplayStatus = { [weak self] display in
            if let topView = self?.topUnReadMessagesTipView, topView.superview != nil {
                self?.updateTopUnReadMessagesTipViewConstraints(topView, hasBanner: display)
            }
        }
        return banner
    }()

    lazy var batchMultiSelectView: ChatBatchMultiSelectView = {
        let batchMultiSelectView = ChatBatchMultiSelectView(chatPageAPI: self, chatMessageViewModel: self.chatMessageViewModel, chatTableView: self.tableView)
        batchMultiSelectView.delegate = self
        return batchMultiSelectView
    }()
    private var hud: UDToast?

    private var contentTopMarginGuide: UILayoutGuide?

    /// Chat 数据模型
    var chat: BehaviorRelay<Chat> {
        return self.chatMessageViewModel.chatWrapper.chat
    }

    /// 多选/单选状态切换
    var multiSelecting = false {
        didSet {
            self.multiSelectingDidSet()
        }
    }

    func multiSelectingDidSet() {
        self.tableView.multiSelecting = multiSelecting
        // 多选时，下方的合并转发、合并收藏和删除按钮视图的高度
        let bottomMenBarHeight = BottomMenuBar.barHeight(in: self.view)
        if multiSelecting {
            self.tableView.longPressGesture.isEnabled = false
            self.bottomLayout.toggleShowAndHideBottom(display: false)
            self.chatMessageBaseDelegate?.showNaviBarMultiSelectCancelItem(true)
            self.remakeTableLayoutWhenBottomHidden(barHeight: bottomMenBarHeight)
            self.chatMessageBaseDelegate?.showTopContainerWithAnimation(isShown: NSNumber(value: true))
            // 进入多选移除电梯
            self.removeReadTipView()
        } else {
            self.tableView.longPressGesture.isEnabled = true
            self.bottomLayout.toggleShowAndHideBottom(display: true)
            self.chatMessageBaseDelegate?.showNaviBarMultiSelectCancelItem(false)
            self.remakeTableLayoutWhenBottomShow(barHeight: bottomMenBarHeight)
            // 退出多选重新添加电梯视图
            self.addDownUnReadMessagesTipView()
            self.addTopUnReadMessagesTipViewIfNeeded()
        }
        self.view.layoutIfNeeded()
        /// 多选 || widgets 完全展开的时候 将banner隐藏
        self.bannerView.isHidden = multiSelecting || ( self.chatMessageBaseDelegate?.widgetExpandLimit?.value ?? false)
    }

    /// 快捷键组件
    override func subProviders() -> [KeyCommandProvider] {
        var providers: [KeyCommandProvider] = [self.tableView]
        for provider in self.bottomLayout.subProviders() {
            providers.append(provider)
        }
        return providers
    }

    /// 消息 table
    lazy var tableView: ChatTableView = {
        let tableView = self.componentGenerator.chatTableView(
            userResolver: userResolver,
            pushWrapper: chatMessageViewModel.chatWrapper,
            keepOffset: { [weak self] in
                return self?.keepTableOffset() ?? false
            },
            fromWhere: self.chatFromWhere
        )
        tableView.chatTableDelegate = self
        tableView.contentInsetAdjustmentBehavior = .never
        return tableView
    }()

    /// 下气泡：xx条未读消息、@我/@all消息、回到最后
    private lazy var downUnReadMessagesTipView: DownUnReadMessagesTipView? = {
        guard chatViewModel.showDownUnReadMessagesTipView,
              let viewModel = self.componentGenerator.unreadMessagesTipViewModel(chatContext: self.chatContext,
                                                                                 chat: self.chat.value,
                                                                                 pushCenter: pushCenter,
                                                                                 readPosition: self.chatMessageViewModel.chatDataContext.readPosition,
                                                                                 lastMessagePosition: self.chatMessageViewModel.chatDataContext.lastMessagePosition)
        else { return nil }
        let tipView = DownUnReadMessagesTipView(
            chat: self.chat.value,
            viewModel: viewModel
        )
        tipView.delegate = self
        return tipView
    }()

    /// 上气泡：xx条未读消息、@我/@all消息
    private var showTopUnReadMessagesTipView: Bool!
    private lazy var topUnReadMessagesTipView: TopUnreadMessagesTipView? = {
        if showTopUnReadMessagesTipView, let firstUnreadMessageInfo = self.chatMessageViewModel.firstUnreadMessageInfo, let messageAPI {
            let tipView = TopUnreadMessagesTipView(
                chat: self.chat.value,
                viewModel: TopUnReadMessagesTipViewModel(
                    userResolver: self.userResolver,
                    chatId: self.chat.value.id,
                    firstUnreadMessagePosition: firstUnreadMessageInfo.firstUnreadMessagePosition,
                    messageAPI: messageAPI,
                    pushCenter: self.pushCenter,
                    readPositionBadgeCount: firstUnreadMessageInfo.readPositionBadgeCount + 1
                )
            )
            tipView.delegate = self
            return tipView
        }
        return nil
    }()

    /// 进群是否定位到指定位置
    let positionStrategy: ChatMessagePositionStrategy?
    /// 定制键盘初始化状态
    let keyboardStartState: KeyboardStartupState
    let disposeBag = DisposeBag()

    private var messageSelectControl: MessageSelectControl?

    lazy var messageSender: MessageSender = {
        return self.componentGenerator.messageSender(chat: self.chat,
                                                     context: self.chatContext,
                                                     chatKeyPointTracker: self.chatKeyPointTracker,
                                                     fromWhere: self.chatFromWhere)
    }()

    /// 置顶消息管理
    lazy var topNoticeDataManger: ChatTopNoticeDataManager = {
        return ChatTopNoticeDataManager(chatId: self.chatId,
                                        pushCenter: self.pushCenter,
                                        userResolver: self.userResolver)
    }()

    /// drag 手势
    private let dragManager: DragInteractionManager

    lazy var guideManager: ChatBaseGuideManager? = {
        return self.componentGenerator.guideManager(chatBaseVC: self)
    }()

    /// 用于在menu 出现的时候 锁住 table 约束
    var tableHeightLock: Bool = false

    let chatKeyPointTracker: ChatKeyPointTracker

    let chatId: String

    /// chat 拖拽交互工具
    private lazy var interactionKit: ChatInteractionKit = {
        let kit = ChatInteractionKit(userResolver: userResolver)
        kit.delegate = self
        return kit
    }()

    /// 首屏消息渲染
    private var afterMessagesRenderCalled: Bool = false {
        didSet {
            LarkTracingUtil.endSpanByName(spanName: LarkTracingUtil.firstScreenMessagesRender)
            ChatMessagesViewController.logger.info("enter_chat_afterMessagesRenderCalled")
            guard oldValue == false else { return }
            DispatchQueue.main.async { [weak self] in
                ChatMessagesViewController.logger.info("chatTrace inAfterMessagesRender \(self?.chatId ?? "")")
                self?.afterMessagesRender()
                ChatMessagesViewController.logger.info("chatTrace finishAfterMessagesRender \(self?.chatId ?? "")")
            }
        }
    }

    /// 联系人相关的生命周期
    private var contactOptDisposeBag = DisposeBag()

    /// 处理消息相关逻辑
    let chatMessageViewModel: ChatMessagesViewModel
    /// 处理会话相关逻辑
    let chatViewModel: ChatViewModel

    weak var targetVC: UIViewController?
    let dependency: ChatControllerDependency
    private let router: ChatControllerRouter
    let chatContext: ChatContext
    let chatFromWhere: ChatFromWhere

    /// 用于构造 VC 的 ChatVieowModel 和 ChatMessagesViewModel 等信息
    let componentGenerator: ChatViewControllerComponentGeneratorProtocol

    private let getChatMessagesResultObservable: Observable<GetChatMessagesResult>
    private let getBufferPushMessages: GetBufferPushMessagesHandler

    let pushCenter: PushNotificationCenter

    var isGroupOwner: Bool {
        return chatMessageViewModel.dependency.currentChatterID == self.chat.value.ownerId
    }

    private lazy var screenProtectService: ChatScreenProtectService? = {
        return self.chatContext.pageContainer.resolve(ChatScreenProtectService.self)
    }()

    lazy var bottomLayout: BottomLayout = {
        self.generateBottomLayout()
    }()

    let moduleContext: ChatModuleContext

    func generateBottomLayout() -> BottomLayout {
        return EmptyBottomLayout()
    }

    required init(
        chatId: String,
        moduleContext: ChatModuleContext,
        componentGenerator: ChatViewControllerComponentGeneratorProtocol,
        router: ChatControllerRouter,
        dependency: ChatControllerDependency,
        chatViewModel: ChatViewModel,
        chatMessageViewModel: ChatMessagesViewModel,
        chatMessageBaseDelegate: ChatMessageBaseDelegate,
        chatOpenService: ChatOpenService,
        positionStrategy: ChatMessagePositionStrategy?,
        keyboardStartState: KeyboardStartupState,
        chatKeyPointTracker: ChatKeyPointTracker,
        dragManager: DragInteractionManager,
        getChatMessagesResultObservable: Observable<GetChatMessagesResult>,
        getBufferPushMessages: @escaping GetBufferPushMessagesHandler,
        pushCenter: PushNotificationCenter,
        chatFromWhere: ChatFromWhere) {
        self.chatViewModel = chatViewModel
        self.chatMessageViewModel = chatMessageViewModel
        self.chatId = chatId
        self.dependency = dependency
        self.router = router
        self.moduleContext = moduleContext
        self.chatContext = moduleContext.chatContext
        self.bannerContext = moduleContext.bannerContext
        self.componentGenerator = componentGenerator
        self.positionStrategy = positionStrategy
        self.keyboardStartState = keyboardStartState
        self.chatKeyPointTracker = chatKeyPointTracker
        self.dragManager = dragManager
        self.chatMessageBaseDelegate = chatMessageBaseDelegate
        self.getChatMessagesResultObservable = getChatMessagesResultObservable
        self.getBufferPushMessages = getBufferPushMessages
        self.chatOpenService = chatOpenService
        self.pushCenter = pushCenter
        self.chatFromWhere = chatFromWhere
        let chat = chatMessageViewModel.chatWrapper.chat.value
        self.chatThemeMode = (chat.theme?.backgroundEntity.mode ?? .originMode) + .readWriteLock
        super.init(nibName: nil, bundle: nil)
        self.chatContext.pageContainer.pageInit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.chatViewModel.chatWrapper.exitChat()
        self.chatContext.pageContainer.pageDeinit()
        self.componentGenerator.fileDecodeService?.clean(force: true)
        ImagePreloader.shared.cancelPreload(scene: .chat, sceneID: chatId)
        NotificationCenter.default.removeObserver(self)
        print("NewChat: ChatMessagesViewController deinit")
    }

    // MARK: - Override VC 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        self.isNavigationBarHidden = true
        self.view.backgroundColor = self.chat.value.isCustomTheme ? .clear : (UIColor.ud.bgBody & UIColor.ud.bgBase)
        self.messageSelectControl = self.componentGenerator.messageSelectControl(chat: self)
        /// 连接消息菜单服务与文本选择控制
        messageSelectControl?.menuService = self.chatContext.pageContainer.resolve(MessageMenuOpenService.self)
        self.targetVC?.fullScreenSceneBlock = { [weak self] () -> String? in
            guard let self = self else {
                return nil
            }
            let chat = self.chat.value
            switch chat.type {
            case .p2P:
                if chat.chatter?.type == .bot {
                    return "bot"
                } else {
                    return chat.isCrypto ? "secret_chat" : "single_chat"
                }
            case .group, .topicGroup:
                if chat.isCustomerService || chat.isOncall {
                    return "help_desk"
                } else if chat.isMeeting {
                    return "event_group"
                } else {
                    return "group"
                }
            @unknown default:
                return nil
            }
        }
        self.targetVC?.larkSplitViewController?.subscribe(self)
        self.chatContext.pageContainer.pageViewDidLoad()
        self.foldApproveDataService?.configData(exclude: self.chat.value.isCrypto)
        self.beforeInitView()
        self.initView()
        self.afterInitView()

        self.guideManager?.checkShowGuideIfNeeded(.specialFocus(self.chat.value))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.bottomLayout.viewWillAppear(animated)
        self.chatContext.pageContainer.pageWillAppear()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.bottomLayout.viewDidAppear(animated)
        self.chatContext.pageContainer.pageDidAppear()
        reportZoomInitializationIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.bottomLayout.viewWillDisappear(animated)
        self.guideManager?.removeHintBubbleView()
        self.removeHightlight(needRefresh: true)
        self.chatContext.pageContainer.pageWillDisappear()
        NotificationCenter.default.post(name: NSNotification.Name("ChatMessagesViewControllerDisAppear"), object: ["chatId": self.chatId])
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let lastCellVisible = self.tableView.lastCellVisible() {
            if !lastCellVisible, let cellInfo = self.tableView.firstVisibleMessageCellInfo() {
                // 最后一个cell完全移出屏幕，才记录位置
                let rect = self.view.convert(cellInfo.frame, from: self.tableView)
                self.chatViewModel.setLastRead(messagePosition: cellInfo.messagePosition, offsetInScreen: rect.minY)
            } else {
                self.chatViewModel.setLastRead(messagePosition: -1, offsetInScreen: 0)
            }
        }
        self.chatContext.pageContainer.pageDidDisappear()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // 为了处理 ipad 退到后台时连续回调不同 size 导致 table 偏移
        // 特化处理没有动画场景保持 table 高度不变
        // 不在 window 上不需要 lock offset
        let lockOffset = !coordinator.isAnimated &&
            Display.pad &&
            self.view.window != nil
        if lockOffset {
            // 当需要锁住 offset 时 重置 table 约束 锁住 table 尺寸
            self.lockTableConstraints()
            self.tableHeightLock = true
            // 添加主线程异步回调重置约束，异步回调会在多次系统回调后才会被调用
            // 确保是按照最终正确尺寸布局更新，不会被中间状态影响
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.updateTableConstraints()
                self.tableHeightLock = false
            }
        }

        coordinator.animate(alongsideTransition: { [weak self] (_) in
            // 不需要锁住 offset 时，更新约束
            if !lockOffset {
                self?.updateTableConstraints()
            }
        }, completion: nil)

        self.guideManager?.viewWillTransition()
        self.messageSelectControl?.menuService?.dissmissMenu(completion: nil)
        self.messageSelectControl?.dismissMenuIfNeeded()
    }

    func splitViewController(_ svc: SplitViewController, willChangeTo splitMode: SplitViewController.SplitMode) {
        // 为了处理 ipad 退到后台时连续回调不同 size 导致 table 偏移
        // 特化处理没有动画场景保持 table 高度不变
        // 不在 window 上不需要 lock offset
        let lockOffset = Display.pad &&
            self.view.window != nil
        if lockOffset {
            // 当需要锁住 offset 时 重置 table 约束 锁住 table 尺寸
            self.lockTableConstraints()
            self.tableHeightLock = true
            // 添加主线程异步回调重置约束，异步回调会在多次系统回调后才会被调用
            // 确保是按照最终正确尺寸布局更新，不会被中间状态影响
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.updateTableConstraints()
                self.tableHeightLock = false
            }
        }

        if !lockOffset {
            self.updateTableConstraints()
        }

        self.messageSelectControl?.menuService?.dissmissMenu(completion: nil)
        self.messageSelectControl?.dismissMenuIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 为了处理 ipad 退到后台时连续回调不同 size 导致 table 偏移
        // 添加主线程异步回调，异步回调会在多次系统回调后才会被调用
        // 确保是按照最终正确尺寸布局更新，不会被中间状态影响
        DispatchQueue.main.async {
            self.resizeVMIfNeeded()
        }
    }

    // MARK: Set HostSize
    private func resizeVMIfNeeded() {
        let size = self.view.bounds.size
        if size != chatMessageViewModel.hostUIConfig.size {
            let needOnResize = size.width != chatMessageViewModel.hostUIConfig.size.width
            chatMessageViewModel.hostUIConfig.size = size
            let fg = self.userResolver.fg.dynamicFeatureGatingValue(with: "im.message.resize_if_need_by_width")
            if fg {
                // 仅宽度更新才刷新cell，因为部分机型系统下(iphone8 iOS15、不排除其他系统也存在相同问题)存在非预期回调，比如当唤起大图查看器时，系统回调了该函数，且给的高度不对
                /*1. cell渲染只依赖宽度 2. 目前正常情况下不存在只变高，不变宽的情况（转屏、ipad拖拽）
                 */
                if needOnResize {
                    chatMessageViewModel.onResize()
                }
            } else {
                chatMessageViewModel.onResize()
            }
        }
    }

    // MARK: UI 布局约束
    private func remakeTableLayoutWhenBottomHidden(barHeight: CGFloat) {
        let height = self.view.bounds.height - CGFloat(barHeight)
        self.tableView.remakeConstraints(height: height, bottom: view.snp.bottom, bottomOffset: -barHeight)
    }

    private func remakeTableLayoutWhenBottomShow(barHeight: CGFloat) {
        let height = self.view.bounds.height - self.bottomLayout.getBottomHeight()
        self.tableView.remakeConstraints(height: height, bottom: self.getTableBottomConstraintItem())
    }

    /// 当容器发生变化的时候重新布局 table
    /// 考虑存在 chatFooterView 和 keyboard 两种情况
    /// 使用 getTableBottomConstraintItem 进行 autolayout 布局
    /// 不使用计算高度布局
    private func updateTableConstraints() {
        self.tableView.snp.remakeConstraints({ make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalTo(getTableBottomConstraintItem())
        })
    }

    private func lockTableConstraints() {
        let size = self.tableView.bounds.size
        self.tableView.snp.remakeConstraints({ make in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.width.equalTo(size.width)
            make.height.equalTo(size.height)
        })
    }

    // MARK: 拖拽
    /// 添加全局拖拽手势
    private func addInterface(in table: UITableView) {
        guard Display.pad else { return }
        let drop = self.interactionKit.createDropInteraction()
        table.addLKInteraction(drop)
    }
    /// 检测是否有需要立刻响应Drop items
    private func checkChatDropItems() {
        guard Display.pad else { return }
        let items = ChatInteractionKit.getDropItems(chatID: self.chat.value.id)
        if !items.isEmpty {
            self.interactionKit.handleDropValues(items)
        }
        ChatInteractionKit.chatDropItemsDriver.drive(onNext: { [weak self] (chatID, items) in
            guard let `self` = self else { return }
            if chatID == self.chat.value.id,
                !items.isEmpty,
                !self.chatViewModel.viewIsNotShowing {
                self.interactionKit.handleDropValues(items)
                ChatInteractionKit.cleanDropItems()
            }
        }).disposed(by: self.disposeBag)
    }

    // MARK: - ChatNavigationBarDelegate
    override func backItemTapped() {
        guard let targetVC = self.targetVC else { return }
        self.controllerService?.backDismissAndCloseSceneItemTapped()
        navigator.pop(from: targetVC)
    }

    // MARK: observe ChatMessageViewModel
    func observeChatMessageViewModel() {
        chatMessageViewModel.tableRefreshDriver
            .drive(onNext: { [weak self] (refreshType) in
                Self.logger.info("Chat trace tableRefreshDriver onNext \(self?.chatId ?? "") \(refreshType.describ)")
                switch refreshType {
                case .refreshTable:
                    self?.tableView.reloadAndGuarantLastCellVisible()
                case .initMessages(let info, _):
                    self?.refreshForInitMessages(initInfo: info)
                    self?.afterMessagesRenderCalled = true
                case .refreshMessages(hasHeader: let hasHeader, hasFooter: let hasFooter, scrollInfo: let scrollInfo):
                    self?.refreshForMessages(hasHeader: hasHeader, hasFooter: hasFooter, scrollTo: scrollInfo)
                case .messagesUpdate(indexs: let indexs, guarantLastCellVisible: let guarantLastCellVisible, let animation):
                    let indexPaths = indexs.map({ IndexPath(row: $0, section: 0) })
                    self?.tableView.refresh(indexPaths: indexPaths, animation: animation, guarantLastCellVisible: (guarantLastCellVisible && !(self?.keepTableOffset() ?? false)))
                case .loadMoreOldMessages(hasHeader: let hasHeader):
                    self?.chatOpenService?.setTopContainerShowDelay(true)
                    self?.tableView.headInsertCells(hasHeader: hasHeader)
                case .loadMoreNewMessages(hasFooter: let hasFooter):
                    self?.tableView.appendCells(hasFooter: hasFooter)
                case .hasNewMessage(message: let message, hasFooter: let hasFooter, let withAnimation):
                    self?.refreshForNewMessage(message: message, withAnimation: withAnimation)
                    self?.tableView.hasFooter = hasFooter
                case .updateHeaderView(hasHeader: let hasHeader):
                    self?.tableView.hasHeader = hasHeader
                case .updateFooterView(hasFooter: let hasFooter):
                    self?.tableView.hasFooter = hasFooter
                case .scrollTo(let scrollInfo):
                    self?.tableView.highlightPosition = scrollInfo.highlightPosition
                    let indexPath = IndexPath(row: scrollInfo.index, section: 0)
                    if scrollInfo.highlightPosition != nil {
                        self?.tableView.reloadData()
                    }
                    let defaultScrollPosition = self?.getDefaultScrollPositionFor(index: scrollInfo.index) ?? .top
                    self?.tableView.scrollToRow(at: indexPath,
                                                at: scrollInfo.tableScrollPosition ?? defaultScrollPosition)
                case .startMultiSelect(startIndex: let startIndex):
                    self?.multiSelecting = true
                    self?.tableView.reloadData()
                    self?.tableView.scrollRectToVisibleBottom(indexPath: IndexPath(row: startIndex, section: 0), animated: true)
                case .finishMultiSelect:
                    self?.multiSelecting = false
                    self?.tableView.reloadAndGuarantLastCellVisible()
                case .messageSendSuccess(message: let message, hasFooter: let hasFooter):
                    let start = CACurrentMediaTime()
                    self?.chatMessageViewModel.dependency.chatKeyPointTracker.afterPublishFinishSignal(cid: message.cid, messageId: message.id)
                    self?.tableView.reloadAndGuarantLastCellVisible()
                    self?.tableView.hasFooter = hasFooter
                    self?.guideManager?.checkShowGuideIfNeeded(.readStatus(message))
                    self?.chatMessageViewModel.dependency.chatKeyPointTracker.sendMessageFinish(cid: message.cid,
                                                                                                messageId: message.id,
                                                                                                success: true,
                                                                                                page: ChatMessagesViewController.pageName,
                                                                                                isCheckExitChat: false,
                                                                                                renderCost: CACurrentMediaTime() - start)
                case .messageSending(let message):
                    let start = CACurrentMediaTime()
                    self?.chatMessageViewModel.dependency.chatKeyPointTracker.afterPublishOnScreenSignal(cid: message.cid, messageId: message.id)
                    self?.refreshForNewMessage(message: message, withAnimation: false)
                    self?.afterMessagesRenderCalled = true
                    DispatchQueue.main.async {
                        self?.guideManager?.checkShowGuideIfNeeded(.atUser(message))
                        self?.guideManager?.checkShowGuideIfNeeded(.pin(message))
                    }
                    self?.chatMessageViewModel.dependency.chatKeyPointTracker.messageOnScreen(cid: message.cid,
                                                                        messageid: message.id,
                                                                        page: ChatMessagesViewController.pageName, renderCost: CACurrentMediaTime() - start)
                case .refreshMissedMessage(let anchorMessageId):
                    self?.tableView.keepOffsetRefresh(anchorMessageId)
                    self?.logVisiblePosition()
                    // 进入会话时最后一条消息可完整显示，不会出现回到最后，但缺失消息回来后可能把最后一条挤出屏幕，但table因为会保持位置，不调didscroll
                    self?.showToBottomTipIfNeeded()
                case .highlight(position: let position):
                    self?.tableView.highlightPosition = position
                    self?.tableView.reloadData()
                case .remain(let hasFooter):
                    self?.tableView.reloadData()
                    self?.tableView.hasFooter = hasFooter
                    self?.view.isUserInteractionEnabled = true
                case .batchFetchSelectMessage(let status):
                    guard let self = self else { return }
                    switch status {
                    case .initHud:
                        self.hud = UDToast()
                    case .loadingHud:
                        self.hud?.showLoading(with: BundleI18n.LarkChat.Lark_Legacy_BaseUiLoading, on: self.view, disableUserInteraction: true)
                    case .removeHud(let showLimit):
                        self.hud?.remove()
                        self.hud = nil

                        guard showLimit else { return }
                        let alertController = LarkAlertController()
                        alertController.setContent(text: BundleI18n.LarkChat.Lark_Chat_SelectMaximumMessagesToast)
                        alertController.addPrimaryButton(text: BundleI18n.LarkChat.Lark_Group_RevokeIKnow)
                        self.present(alertController, animated: true)
                    }
                }
                self?.bottomLayout.onTable(refresh: refreshType)
            }).disposed(by: self.disposeBag)

        chatMessageViewModel.errorDriver.drive(onNext: { [weak self] (errorType) in
            guard let `self` = self else {
                return
            }
            switch errorType {
            case .jumpFail(let error):
                Self.logger.error("消息跳转失败", error: error)
            case .loadMoreOldMsgFail(let error):
                Self.logger.error("拉取历史消息失败", error: error)
                self.chatOpenService?.setTopContainerShowDelay(true)
                self.tableView.endTopLoadMore(hasMore: true)
            case .loadMoreNewMsgFail(let error):
                Self.logger.error("拉取新消息失败", error: error)
                self.tableView.endBottomLoadMore(hasMore: true)
            }
        }).disposed(by: self.disposeBag)
    }

    // MARK: UI 组件初始化完成后逻辑
    private func afterInitView() {
        // 我被移出群聊
        self.chatViewModel.deleteMeFromChannelDriver
            .asObservable()
            .take(1)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (content) in
                guard let `self` = self else { return }
                let alertController = LarkAlertController()
                alertController.setContent(text: content)
                alertController.addPrimaryButton(text: BundleI18n.LarkChat.Lark_Legacy_IKnow, dismissCompletion: { [weak self] in
                    guard let `self` = self else { return }
                    self.chatViewModel.removeFeedCard()
                    DispatchQueue.main.async {
                        self.doActionWhenKickOff()
                    }
                })
                self.navigator.present(alertController, from: self)
            }).disposed(by: self.disposeBag)

        // 我主动退出群聊、解散群聊
        self.chatViewModel.localLeaveGroupChannel
            .filter { $0.status == .success }
            .drive(onNext: { [weak self] (_) in
                self?.doActionWhenKickOff()
            }).disposed(by: disposeBag)

        self.chatViewModel.chatLastPositionDriver
            .drive(onNext: { [weak self] () in
                guard let `self` = self else { return }
                self.chatMessageViewModel.updateFooter()
            }).disposed(by: self.disposeBag)

        self.componentGenerator.chatFirstMessagePositionDriver(pushWrapper: self.chatMessageViewModel.chatWrapper)?
            .drive(onNext: { [weak self] in
                self?.chatMessageViewModel.adjustMinMessagePosition()
            }).disposed(by: self.disposeBag)

        self.chatViewModel.offlineChatUpdateDriver
            .debounce(.milliseconds(300)) //1. rust可能会多次push,端上debounce 2. 延后一些在处理首屏case时，可以尽量保证首屏消息已加载
            .drive(onNext: { [weak self] (chat) in
                //如果显示的最后一条消息小于当前chat的lastVisibleMessagePosition，说明离线期间有离线消息
                guard let self = self else { return }
                let maxPosition = self.chatMessageViewModel.messageDatasource.maxMessagePosition
                let firstScreenLoaded = self.chatMessageViewModel.firstScreenLoaded
                if firstScreenLoaded,
                    maxPosition < chat.lastVisibleMessagePosition {
                    //尝试加载更多一页消息
                    self.tableView.loadMoreBottomContent(finish: { [weak self] result in
                        DispatchQueue.main.async {
                            if result.isValid(), chat.badge == 0 {
                                //有离线，但都是已读的或自己发的，显示回到最后电梯，有未读会显示未读电梯
                                (self?.downUnReadMessagesTipView?.viewModel as? DownUnReadMessagesTipViewModel)?.toLastMessageState()
                            }
                        }
                    })
                }
                Self.logger.info("chatTrace offlineChatUpdate \(chat.id) \(firstScreenLoaded) \(chat.badge) \(maxPosition) \(chat.lastVisibleMessagePosition)")
        }).disposed(by: disposeBag)

        self.observeSendMessageStatusDriver()
        AudioPlayStatusView.setAudioPlayStatusTopMargin(self.chatMessageBaseDelegate?.contentTopMargin, view: self.view)
        /// 获取chat置顶信息
        let chatValue = self.chat.value
        if topNoticeService?.isSupportTopNoticeChat(chatValue) == true {
            topNoticeDataManger.startGetAndObserverTopNoticeData()
            topNoticeDataManger.topNoticeDriver
                .drive(onNext: { [weak self] notice in
                    self?.chatMessageViewModel.topNoticeSubject.onNext(notice)
                }).disposed(by: disposeBag)
        }

        self.screenProtectService?.observe(screenCaptured: { [weak self] captured in
            if captured {
                self?.chatMessageBaseDelegate?.showPlaceholderView(true)
            } else {
                self?.chatMessageBaseDelegate?.showPlaceholderView(false)
            }
            self?.bottomLayout.screenCaptured(captured: captured)
            self?.chatViewModel.view(isShowing: !captured, indentify: "secret_chat_recording")
        })

        // 监听Chat主题的变化
        self.pushCenter.observable(for: ChatTheme.self)
            // 子线程处理数据更新，避免主线程抢占锁资源
            .map({ [weak self] theme -> (ChatTheme, Bool) in
                switch theme.style {
                case .image, .key:
                    self?.chatThemeMode.value = .imageMode
                case .color(_):
                    self?.chatThemeMode.value = .colorMode
                case .defalut:
                    self?.chatThemeMode.value = .originMode
                case .unknown:
                    break
                @unknown default:
                    fatalError("unknown default for theme.style")
                }
                let isOrigin = self?.chatThemeMode.value == .originMode
                return (theme, isOrigin)
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (theme, isOrigin) in
                self?.chatComponentScene = theme.scene
                self?.view.backgroundColor = isOrigin ? (UIColor.ud.bgBody & UIColor.ud.bgBase) : .clear
                // 触发table所有cell的重新计算和布局
                self?.chatMessageViewModel.onResize()
            }).disposed(by: self.disposeBag)

        self.bottomLayout.afterInitView()
    }

    // MARK: - UI 相关布局初始化
    func initView() {
        /// table
        tableView.chatTableDelegate = self
        tableView.contentInsetAdjustmentBehavior = .never
        self.tableView.chatTableDataSourceDelegate = self.chatMessageViewModel
        tableView.contentInset = UIEdgeInsets(
            top: self.chatMessageBaseDelegate?.contentTopMargin ?? 0,
            left: 0,
            bottom: 24,
            right: 0
        )
        self.view.addSubview(tableView)
        self.bottomLayout.setupBottomView()

        let topMarginGuide = UILayoutGuide()
        self.contentTopMarginGuide = topMarginGuide
        self.view.addLayoutGuide(topMarginGuide)
        topMarginGuide.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(self.chatMessageBaseDelegate?.contentTopMargin ?? 0)
        }

        // 「选择以下消息」按钮
        self.view.addSubview(batchMultiSelectView)
        batchMultiSelectView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(topMarginGuide.snp.bottom).offset(48)
            make.height.equalTo(28)
        }

        /// 添加bannerView
        self.view.addSubview(self.bannerView)
        self.bannerView.snp.makeConstraints { make in
            make.top.equalTo(topMarginGuide.snp.bottom)
            make.left.right.equalToSuperview()
        }

        self.tableView.snp.makeConstraints({ make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalTo(getTableBottomConstraintItem())
        })
    }
    /// 首屏消息渲染后相关逻辑
    func afterMessagesRender() {
        if self.chatKeyPointTracker.loadTrackInfo?.tableRenderEnd == nil {
            self.chatKeyPointTracker.loadTrackInfo?.tableRenderEnd = CACurrentMediaTime()
        }
        self.controllerService?.messagesBeenRendered()
        self.observeAfterMessagesRender()
        self.bottomLayout.afterFirstScreenMessagesRender()
        self.chatMessageBaseDelegate?.messagesBeenRendered()
        self.uiBusinessAfterMessageRender()
        self.setupUnreadTipViewIfNeeded()
        self.messageSelectControl?.addMessageSelectObserver()
        self.logVisiblePosition()
        self.chatContext.pageContainer.afterFirstScreenMessagesRender()
        LarkTracingUtil.endSpanByName(spanName: LarkTracingUtil.enterChat, tags: self.chatKeyPointTracker.loadTrackInfo?.metric)
        // 进访客群忽略【进群埋点】：因为进访客群是从远端拉取chat，可能会影响进群埋点数据的准确性
        let ignoreTracker = chat.value.isTeamVisitorMode
        if !ignoreTracker {
            self.chatKeyPointTracker.trackChatLoadTimeEnd()
        }
        Self.logger.info(logId: "enterChatCost",
                         "chatTrace enterChatCost",
                         params: self.chatKeyPointTracker.loadTrackInfo?.metric)
        // mention预加载数据
        IMMentionData.preLoading(chatId: self.chatId)
    }

    func uiBusinessAfterMessageRender() {
        if Display.pad {
            // 添加 drop 手势
            self.addInterface(in: tableView)
            // 添加 drag 手势
            let drag = UIDragInteraction(delegate: self.dragManager)
            self.tableView.addInteraction(drag)
            dragManager.addLifeCycle { [weak self] (info) in
                guard let self = self else { return }
                if info.type == .willLift {
                    let location = info.session.location(in: self.tableView)
                    self.tableView.longPressGesture.isEnabled = false
                    self.tableView.longPressGesture.isEnabled = true
                    DispatchQueue.main.async {
                        self.tableView.showMenu(location: location,
                                                triggerByDrag: false,
                                                triggerGesture: nil)
                    }
                } else if info.type == .willBegin {
                    self.messageSelectControl?.menuService?.dissmissMenu(completion: nil)
                    self.messageSelectControl?.dismissMenuIfNeeded()
                }
            }
        }
        // 检查 iPad 拖拽
        self.checkChatDropItems()
        self.chatMessageBaseDelegate?.widgetExpandDriver?
            .distinctUntilChanged()
            .drive(onNext: { [weak self] expand in
                self?.bottomLayout.widgetExpand(expand: expand)
            }).disposed(by: self.disposeBag)

        self.chatMessageBaseDelegate?.widgetExpandLimit?
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false).drive(onNext: { [weak self] limit in
                guard let self = self else { return }
                self.bannerView.isHidden = (limit || self.multiSelecting)
            }).disposed(by: self.disposeBag)
    }

    func onUnReadMessagesTipViewMyAIItemTapped(tipView: BaseUnReadMessagesTipView) {
    }

    func shouldShowUnReadMessagesMyAIView(tipView: BaseUnReadMessagesTipView) -> Bool {
        return false
    }

    func insertAt(by chatter: Chatter?) {
    }

    func reply(message: LarkModel.Message, partialReplyInfo: LarkModel.PartialReplyInfo?) {
    }

    func reedit(_ message: Message) {
    }

    func multiEdit(_ message: Message) {
    }

    func quasiMsgCreateByNative() -> Bool {
        return false
    }
}

// MARK: - 进群相关流程
extension ChatMessagesViewController {
    /// UI 组件初始化前
    private func beforeInitView() {
        LarkTracingUtil.startChildSpanByPName(spanName: LarkTracingUtil.beforeGenerateNormalViews, parentName: LarkTracingUtil.firstRender)
        let start = CACurrentMediaTime()
        // 只有定位策略是「最新一条未读消息」时，才展示上气泡
        self.showTopUnReadMessagesTipView = self.positionStrategy == nil && self.chatViewModel.showTopUnReadMessagesTipView
        self.chatMessageViewModel.hostUIConfig = HostUIConfig(
            size: self.navigationController?.view.bounds.size ?? self.view.bounds.size,
            safeAreaInsets: self.navigationController?.view.safeAreaInsets ?? self.view.safeAreaInsets
        )
        /// 对首屏数据的处理至少要等到hostSize被设置
        self.observeChatMessageViewModel()
        self.chatMessageViewModel.initMessages(positionStrategy: self.positionStrategy,
                                               firstScreenMessagesObservable: self.getChatMessagesResultObservable,
                                               bufferPushMessages: self.getBufferPushMessages)
        self.chatKeyPointTracker.loadTrackInfo?.beforeGenerateNormalViewsCost = ChatKeyPointTracker.cost(startTime: start)
        LarkTracingUtil.endSpanByName(spanName: LarkTracingUtil.beforeGenerateNormalViews)
    }

    private func observeAfterMessagesRender() {
        // 翻译设置变了，需要刷新界面
        chatViewModel.dependency.userGeneralSettings?.translateLanguageSettingDriver.skip(1)
            .drive(onNext: { [weak self] (_) in
                // 清空一次标记
                self?.chatViewModel.dependency.translateService?.resetMessageCheckStatus(key: self?.chat.value.id ?? "")
                self?.tableView.displayVisibleCells()
            }).disposed(by: self.disposeBag)

        // 自动翻译开关变了，需要刷新界面
        chatViewModel.chatAutoTranslateSettingDriver.drive(onNext: { [weak self] () in
            // 清空一次标记
            self?.chatViewModel.dependency.translateService?.resetMessageCheckStatus(key: self?.chat.value.id ?? "")
            self?.tableView.displayVisibleCells()
        }).disposed(by: self.disposeBag)

        self.chatViewModel.is24HourTime
            .drive(onNext: { [weak self] _ in
                self?.chatMessageViewModel.refreshRenders()
            }).disposed(by: disposeBag)

        self.chatViewModel.dependency.byteViewService?.meetingWindowInfoOb
            .observeOn(MainScheduler.instance)
            .map { [weak self] (info) -> Bool in
                /// 不存在会议window
                if !info.hasWindow { return false }
                /// 是小窗
                if info.isFloating { return false }
                if #available(iOS 13.0, *) {
                    /// 会议窗口和会话页面不是一个 Scene
                    if let chatScene = self?.currentScene(),
                        chatScene != info.windowScene {
                        return false
                    }
                }
                return true
            }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] covering in
                self?.chatViewModel.view(isShowing: !covering, indentify: "meetingCovering")
            }).disposed(by: disposeBag)

        self.chatViewModel.chatWrapper.enterChat()

        // 当view没有显示出来时，比如被视频会议view覆盖，则不发已读
        chatViewModel.viewIsNotShowingDriver.drive(onNext: { [weak self] notShowing in
            self?.screenProtectService?.protectedTargetIsShow = !notShowing
            if notShowing {
                self?.chatMessageViewModel.readService.set(enable: false)
            } else {
                self?.chatMessageViewModel.readService.set(enable: true)
                self?.tableView.displayVisibleCells()
            }
        }).disposed(by: disposeBag)

        // 当点击图片进行大图预览时，只处理数据更新不产生UI刷新，当退出大图预览时统一产生一次刷新
        chatMessageViewModel.enableUIOutputDriver.filter({ return $0 }).drive(onNext: { [weak self] _ in
            self?.tableView.reloadAndGuarantLastCellVisible(animated: true)
        }).disposed(by: self.disposeBag)

        self.screenProtectService?.observeEnterBackground(targetVC: self)

        /// 监听截屏事件，打 log
        NotificationCenter.default.rx.notification(UIApplication.userDidTakeScreenshotNotification)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self, self.viewIfLoaded?.window != nil else { return }
                let visiableRowIndex = Set((self.tableView.indexPathsForVisibleRows ?? []).map { $0.row })
                let messages: [[String: String]] = self.chatMessageViewModel.uiDataSource.enumerated()
                    .filter { visiableRowIndex.contains($0.offset) }
                    .compactMap { (_: Int, vm: ChatCellViewModel) -> Message? in (vm as? HasMessage)?.message }
                    .map { (message: Message) -> [String: String]  in
                        ["id": "\(message.id)",
                         "cid": "\(message.cid)",
                         "type": "\(message.type)",
                         "position": "\(message.position)",
                         "read_count": "\(message.readCount)",
                         "un_read_count": "\(message.unreadCount)",
                         "message_length": "\(self.dependency.modelService?.messageSummerize(message).count ?? 0)",
                         "displaymode": "\(message.displayInThreadMode)"]
                    }
                let jsonEncoder = JSONEncoder()
                jsonEncoder.outputFormatting = .sortedKeys
                let data = (try? jsonEncoder.encode(messages)) ?? Data()
                let jsonStr = String(data: data, encoding: .utf8) ?? ""
                Self.logger.info("user screenshot accompanying infos:" + "channel_id: \(self.chat.value.id), messages: \(jsonStr)")
            })
            .disposed(by: disposeBag)

        /// 监听 Scene 激活状态
        /// Scene 在未激活时，禁止已读
        if #available(iOS 13.0, *),
           let targetVC = self.targetVC,
           SceneManager.shared.supportsMultipleScenes,
           let scene = targetVC.currentScene() {
            let indentify = "chat_scene_deactive"
            /// 初始化当前是否正在显示
            if scene.activationState != .foregroundActive {
                self.chatViewModel.view(isShowing: false, indentify: indentify)
            }
            /// 监听 scene 信号，改变 show 状态
            NotificationCenter.default.rx.notification(UIScene.didActivateNotification).subscribe(onNext: { [weak self] (noti) in
                if let changeScene = noti.object as? UIWindowScene,
                   let currentScene = self?.targetVC?.currentScene(),
                   changeScene == currentScene {
                    self?.chatViewModel.view(isShowing: true, indentify: indentify)
                }
            }).disposed(by: disposeBag)

            NotificationCenter.default.rx.notification(UIScene.willDeactivateNotification).subscribe(onNext: { [weak self] (noti) in
                if let changeScene = noti.object as? UIWindowScene,
                   let currentScene = self?.targetVC?.currentScene(),
                   changeScene == currentScene {
                    self?.chatViewModel.view(isShowing: false, indentify: indentify)
                }
            }).disposed(by: disposeBag)
        }

        /// 监听 scene title 更新
        self.observeToUpdateSceneTitle()
    }

    private func observeSendMessageStatusDriver() {
        self.sendMessageStatusDriver?.drive(onNext: { [weak self] (message, error) in
            guard let self = self else { return }
            if let apiError = error?.underlyingError as? APIError {
                switch apiError.type {
                case .cloudDiskFull:
                    let alertController = LarkAlertController()
                    // 发送文件时alert疑似有冲突，必须使用from：
                    alertController.showCloudDiskFullAlert(from: self, nav: self.navigator)
                case .noMessagePermission:
                    UDToast.showFailure(
                        with: BundleI18n.LarkChat.Lark_Legacy_NoMessagePermissionAlert,
                        on: self.view,
                        error: apiError
                    )
                /// 无法使用密聊
                case .noSecretChatPermission(let message):
                    UDToast.showFailure(with: message, on: self.view)
                case .securityControlDeny(let message):
                    self.chatSecurityControlService?.authorityErrorHandler(event: .sendFile,
                                                                          authResult: nil,
                                                                          from: self,
                                                                          errorMessage: message)
                /// 权限管控
                case .externalCoordinateCtl, .targetExternalCoordinateCtl, .collaborationAuthFailedBeBlocked, .messageDlpFailedToSendMessage, .strategyControlDeny:
                    // 不需要弹窗
                    break
                case .invalidCipherFailedToSendMessage(let message), .invalidCipherFailedToUploadFile(let message):
                    let alert = LarkAlertController()
                    alert.setContent(text: message)
                    alert.addPrimaryButton(text: BundleI18n.LarkChat.Lark_IMSecureKey_KeyDeletedCantSentMessageContactAdmin_GotItButton)
                    self.navigator.present(alert, from: self)
                case .noFileSharePermission(let message):
                    let alert = LarkAlertController()
                    alert.setTitle(text: BundleI18n.LarkChat.Lark_FilePermission_NoPermissionSendFileExternally_PopupTitle)
                    alert.setContent(text: message)
                    alert.addPrimaryButton(text: BundleI18n.LarkChat.Lark_FilePermission_NoPermissionSendFileExternally_OKButton)
                    self.navigator.present(alert, from: self)
                case .invalidMedia(_):
                    self.alertService?.showResendAlertFor(error: error,
                                                         message: message,
                                                         fromVC: self)
                default:
                    // 发消息目前三端都给了默认提示(糟糕发生一些错误), 并优先展示服务端的错误文案(可转换成APIError的前提下)
                    UDToast.showFailure(
                        with: BundleI18n.LarkChat.Lark_Legacy_ErrorMessageTip,
                        on: self.view,
                        error: apiError
                    )
                }
                return
            }
            if let error = error {
                UDToast.showFailure(
                    with: BundleI18n.LarkChat.Lark_Legacy_ErrorMessageTip,
                    on: self.view,
                    error: error
                )
            }
        }).disposed(by: self.disposeBag)
    }
}

// MARK: - OpenIM Framwork Messages Service
extension ChatMessagesViewController: ChatMessagesOpenService {
    var pageAPI: PageAPI? { self }
    var dataSource: DataSourceAPI? { self.chatContext.dataSourceAPI }
    func getUIMessages() -> [Message] {
        return self.chatMessageViewModel.uiDataSource.compactMap {
            return ($0 as? HasMessage)?.message
        }
    }
    func delete(messageIds: [String], callback: ((Bool) -> Void)?) {
        self.chatContext.pageContainer.resolve(DeleteMessageService.self)?.delete(messageIds: messageIds, callback: callback)
    }
}

// MARK: - FragmentLocate
extension ChatMessagesViewController: FragmentLocate {
    public func customLocate(by fragment: String, with context: [String: Any], animated: Bool) {
        guard let messagePosition = Int32(fragment) else {
            return
        }
        var jumpStatus: ((ChatMessagesViewModel.JumpStatus) -> Void)?
        jumpStatus = { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .start:
                    // 占位视图需要重新布局
                    self?.loadingPlaceholderView.snp.remakeConstraints { (make) in
                        make.left.right.bottom.equalToSuperview()
                        make.top.equalToSuperview().inset(self?.chatMessageBaseDelegate?.contentTopMargin ?? 0)
                    }
                    self?.loadingPlaceholderView.isHidden = false
                    self?.chatMessageBaseDelegate?.showTopContainerWithAnimation(isShown: NSNumber(value: true))
                case .finishByRequest:
                    Self.logger.info("chatTrace queueInfo customLocate pauseQueue")
                    self?.chatMessageViewModel.pauseQueue()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                        self?.loadingPlaceholderView.isHidden = true
                        Self.logger.info("chatTrace queueInfo customLocate resumeQueue")
                        self?.chatMessageViewModel.resumeQueue()
                    })
                case .error:
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                        self?.loadingPlaceholderView.isHidden = true
                    })
                    if let self = self {
                        UDToast.showFailure(with: BundleI18n.LarkChat.Lark_Legacy_MessageLoadFail, on: self.view)
                    }
                case .finshDirect:
                    break
                }
            }
        }
        let body = context[ContextKeys.body] as? HasLocateMessageInfo
        let tracker = self.chatKeyPointTracker
        let indentify = tracker.generateIndentify()
        tracker.inChatStartJump(indentify: indentify)

        /// 这个跳转传入nil 使用默认策略
        self.chatMessageViewModel.jumpTo(position: messagePosition,
                                         messageId: body?.messageId,
                                         tableScrollPosition: nil,
                                         needHighlight: true,
                                         jumpStatus: jumpStatus) { trackInfo in
                                            tracker.inChatFinishJump(indentify: indentify,
                                                                     scene: .routerLocate,
                                                                     trackInfo: trackInfo)
        }
    }
}

// MARK: - ChatNavigationBarDelegate
extension ChatMessagesViewController: ChatNavigationBarDelegate {

    func changeStatusBarStyle(_ statusBarStyle: UIStatusBarStyle) {
        if let containerVC = self.targetVC as? ChatContainerViewController {
            containerVC.statusBarStyle = statusBarStyle
        }
    }

    func backItemClicked(sender: UIButton) {
        guard let targetVC = self.targetVC else { return }
        self.controllerService?.backDismissAndCloseSceneItemTapped()
        navigator.pop(from: targetVC)
    }

    func cancelItemClicked() {
        self.chatContext.chatPageAPI?.endMultiSelect()
        ChatTracker.trackMultiSelectExit()
    }
}

// MARK: - Scene
extension ChatMessagesViewController {
    func updateSceneTargetContentIdentifier() {
        guard let targetVC = self.targetVC else { return }
        let chat = self.chat.value
        let scene: LarkSceneManager.Scene
        switch chat.type {
        case .p2P:
            scene = LarkSceneManager.Scene(
                key: chat.isCrypto ? "P2pCryptoChat" : "P2pChat",
                id: chat.chatterId
            )
        @unknown default:
            scene = LarkSceneManager.Scene(
                key: "Chat",
                id: self.chatId
            )
        }
        targetVC.sceneTargetContentIdentifier = scene.targetContentIdentifier
    }

    /// 刷新 scene title
    func observeToUpdateSceneTitle() {
        guard SceneManager.shared.supportsMultipleScenes else {
            return
        }
        self.chat
            .observeOn(MainScheduler.asyncInstance)
            .distinctUntilChanged({ $0.displayName == $1.displayName })
            .subscribe(onNext: { [weak self] (chat) in
                guard let vc = self?.targetVC else { return }
                SceneManager.shared.updateSceneIfNeeded(
                    title: chat.displayName,
                    from: vc
                )
            }).disposed(by: self.disposeBag)
    }
}

// MARK: - 电梯视图 UI 操作
extension ChatMessagesViewController {
    private func setupUnreadTipViewIfNeeded() {
        guard let downUnReadMessagesTipView = self.downUnReadMessagesTipView else { return }
        guard downUnReadMessagesTipView.superview == nil else {
            return
        }
        self.addDownUnReadMessagesTipView()
        (downUnReadMessagesTipView.viewModel as? DownUnReadMessagesTipViewModel)?.update(chat: self.chat.value)
        self.addTopUnReadMessagesTipViewIfNeeded()
    }

    // 添加底部电梯视图
    func addDownUnReadMessagesTipView() {
        guard let downUnReadMessagesTipView = self.downUnReadMessagesTipView else { return }
        self.view.insertSubview(downUnReadMessagesTipView, aboveSubview: self.tableView)
        // 默认为安全区域底部的边界
        var bottomConstraint = view.safeAreaLayoutGuide.snp.bottom
        // 获取view底部控件的top约束
        if let constraint = self.bottomLayout.getBottomControlTopConstraintInView() {
            bottomConstraint = constraint
        }
        downUnReadMessagesTipView.snp.remakeConstraints { (make) in
            make.right.equalTo(-4)
            make.bottom.equalTo(bottomConstraint).offset(-12)
        }
    }

    // 必要时添加顶部电梯视图
    private func addTopUnReadMessagesTipViewIfNeeded() {
        if let topUnReadMessagesTipView = self.topUnReadMessagesTipView {
            self.downUnReadMessagesTipView?.isHidden = true
            self.view.insertSubview(topUnReadMessagesTipView, aboveSubview: self.tableView)
            let hasBanner = (self.bannerView as? ChatBannerView)?.isDisplay ?? false
            updateTopUnReadMessagesTipViewConstraints(topUnReadMessagesTipView, hasBanner: hasBanner)
        }
    }

    private func updateTopUnReadMessagesTipViewConstraints(_ tipView: UIView, hasBanner: Bool) {
        let offset = hasBanner ? 20 : 40
        tipView.snp.remakeConstraints { (make) in
            make.right.equalTo(-4)
            make.top.equalTo(self.bannerView.snp.bottom).offset(offset)
        }
    }

    // 移除所有电梯视图
    private func removeReadTipView() {
        self.topUnReadMessagesTipView?.removeFromSuperview()
        self.downUnReadMessagesTipView?.removeFromSuperview()
    }
}

// MARK: - table刷新、滚动
extension ChatMessagesViewController {
    private func refreshForInitMessages(initInfo: InitMessagesInfo) {
        LarkTracingUtil.endSpanByName(spanName: LarkTracingUtil.publishInitMessagesSignal)
        LarkTracingUtil.startChildSpanByPName(spanName: LarkTracingUtil.refreshForInitMessages, parentName: LarkTracingUtil.firstScreenMessagesRender)
        let trackInfo = self.chatKeyPointTracker.loadTrackInfo
        trackInfo?.swithToMainThreadEnd = CACurrentMediaTime()
        self.refreshForMessages(hasHeader: initInfo.hasHeader, hasFooter: initInfo.hasFooter, scrollTo: initInfo.scrollInfo)
        trackInfo?.tableRenderStart = CACurrentMediaTime()
        if initInfo.initType == .recentLeftMessage, let cell = self.tableView.getVisibleCell(by: self.chat.value.lastReadPosition) {
            let frame = self.view.convert(cell.frame, from: self.tableView)
            let contentOffsetY = min(self.tableView.tableViewOffsetMaxY(), self.tableView.contentOffset.y + (frame.minY - CGFloat(self.chat.value.lastReadOffset)))
            if contentOffsetY > 0 {
                self.tableView.contentOffset.y = contentOffsetY
            }
            //getVisibleCell会导致cellForRow立刻执行
            trackInfo?.tableRenderEnd = CACurrentMediaTime()
        }
        trackInfo?.renderEnd = CACurrentMediaTime()
        LarkTracingUtil.endSpanByName(spanName: LarkTracingUtil.refreshForInitMessages)
    }

    /// 刷新，滚动到指定消息
    private func refreshForMessages(hasHeader: Bool, hasFooter: Bool, scrollTo: ScrollInfo?) {
        self.tableView.hasHeader = hasHeader
        self.tableView.hasFooter = hasFooter
        self.tableView.reloadData()
        // 是否需要滚动到指定消息
        if let scrollTo = scrollTo {
            self.tableView.highlightPosition = scrollTo.highlightPosition
            if scrollTo.needDuration, let customDurationTime = scrollTo.customDurationTime {
                UIView.animate(withDuration: customDurationTime) {
                    self.tableView.scrollToRow(at: IndexPath(row: scrollTo.index, section: 0),
                                               at: scrollTo.tableScrollPosition ?? self.getDefaultScrollPositionFor(index: scrollTo.index))
                }
            }
            self.tableView.scrollToRow(at: IndexPath(row: scrollTo.index, section: 0),
                                       at: scrollTo.tableScrollPosition ?? getDefaultScrollPositionFor(index: scrollTo.index))
        }
    }

    /// 刷新，如果屏幕在最底端，还要滚动一下，保证新消息上屏
    private func refreshForNewMessage(message: Message, withAnimation: Bool = true) {
        if UIApplication.shared.applicationState == .background || self.chatViewModel.viewIsNotShowing {
            self.tableView.reloadData()
        } else {
            self.tableView.reloadAndGuarantLastCellVisible(animated: withAnimation)
        }
    }

    /// 有回复，且正在输入时，保证table不产生位置偏移
    private func keepTableOffset() -> Bool {
        return self.bottomLayout.keepTableOffset()
    }

    private func logVisiblePosition() {
        if let range = self.tableView.visiblePositionRange() {
            ChatMessagesViewController.logger.info("chatTrace visiblePositionRange \(self.chat.value.id) \(range.top) \(range.bottom)")
        }
    }

    private func getDefaultScrollPositionFor(index: Int) -> UITableView.ScrollPosition {
        if index < self.chatMessageViewModel.uiDataSource.count,
           let cellVM = self.chatMessageViewModel.uiDataSource[index] as? ChatMessageCellViewModel {
            return cellVM.renderer.size().height > tableView.frame.height ? .top : .middle
        }
        return .top
    }
}

// MARK: - ChatTableViewDelegate
extension ChatMessagesViewController: ChatTableViewDelegate {
    var isOriginTheme: Bool {
        self.chatThemeMode.value == .originMode
    }

    func messageWillDisplay(message: Message) {
        switch message.type {
        case .file, .audio:
            (self.topUnReadMessagesTipView?.viewModel as? TopUnReadMessagesTipViewModel)?.updateMessageRead(message: message)
        @unknown default:
            break
        }
    }

    func messageDidEndDisplay(message: Message) {
    }

    func tapTableHandler() {
        self.bottomLayout.tapTableHandler()
        self.removeHightlight(needRefresh: true)
    }

    func removeHightlight(needRefresh: Bool) {
        self.chatMessageViewModel.removeHightlight(needRefresh: needRefresh)
        self.tableView.highlightPosition = nil
        self.tableView.hightlightCell = nil
    }

    func tableDidScroll(table: ChatTableView) {
        self.showToBottomTipIfNeeded()
    }

    func tableWillBeginDragging() {
        // 内部实现用viewWithTag
        // 当前View找不到tag会递归子视图
        // 频繁调用有性能问题
        AudioPlayStatusView.hideAudioPlayStatusOn(view: self.view)
        self.removeHightlight(needRefresh: true)
    }

    func showToBottomTipIfNeeded() {
        guard let downUnReadMessagesTipView = self.downUnReadMessagesTipView else { return }
        guard let lastCellVisible = self.tableView.lastCellVisible() else { return }
        if self.chatMessageViewModel.firstScreenLoaded,
           !lastCellVisible,
           self.bottomLayout.showToBottomTipIfNeeded() {
            // 屏幕底部外已经加载但没有上屏的cells的总高度是否超过给定高度
            if let bottomUnVisibleCellsHeightIsMoreThanHeight = self.tableView.bottomUnVisibleCellsHeightIsMoreThanHeight(self.chatMessageViewModel.hostUIConfig.size.height),
               bottomUnVisibleCellsHeightIsMoreThanHeight {
                    (downUnReadMessagesTipView.viewModel as? DownUnReadMessagesTipViewModel)?.toLastMessageState()
            }
        } else {
            (downUnReadMessagesTipView.viewModel as? DownUnReadMessagesTipViewModel)?.disableLastMessageState()
        }
    }

    func safeAreaInsetsDidChange() {
        self.adjustTableViewContentInset()
    }

    func adjustTableViewContentInset() {
        var tableTopContentInset: CGFloat = self.chatMessageBaseDelegate?.contentTopMargin ?? 0
        self.tableView.contentInset = UIEdgeInsets(
            top: tableTopContentInset,
            left: 0,
            bottom: fixedBottomBaseInset,
            right: 0
        )
    }

    func showTopLoadMore(status: ScrollViewLoadMoreStatus) {
        switch status {
        case .start:
            self.chatMessageViewModel.topLoadMoreReciableKeyInfo = LoadMoreReciableKeyInfo.generate()
            self.chatKeyPointTracker.startLoadMoreMessageTime(loadType: .older)
        case .finish:
            self.chatKeyPointTracker.endLoadMoreMessageTime(loadType: .older)
        }
    }

    func showBottomLoadMore(status: ScrollViewLoadMoreStatus) {
        switch status {
        case .start:
            self.chatMessageViewModel.bottomLoadMoreReciableKeyInfo = LoadMoreReciableKeyInfo.generate()
            self.chatKeyPointTracker.startLoadMoreMessageTime(loadType: .newer)
        case .finish:
            self.chatKeyPointTracker.endLoadMoreMessageTime(loadType: .newer)
        }
    }
}

// MARK: - 气泡相关
extension ChatMessagesViewController: UnReadMessagesTipViewDelegate {
    func tipWillShow(tipView: BaseUnReadMessagesTipView) {
        if let downUnReadMessagesTipView = self.downUnReadMessagesTipView, tipView == downUnReadMessagesTipView, tipView.unReadTipState != .showToLastMessage {
            // 下气泡显示后，上气泡在本次会话期间就不会再显示了，销毁
            if let topUnReadMessagesTipView = self.topUnReadMessagesTipView {
                topUnReadMessagesTipView.removeFromSuperview()
                self.topUnReadMessagesTipView = nil
            }
        }
    }

    func tipCanShow(tipView: BaseUnReadMessagesTipView) -> Bool {
        // 首屏加载中气泡不要显示
        guard self.chatMessageViewModel.firstScreenLoaded else {
            return false
        }
        if let downUnReadMessagesTipView = self.downUnReadMessagesTipView, tipView == self.downUnReadMessagesTipView {
            if tipView.unReadTipState == .showToLastMessage || self.tableView.hasFooter {
                return true
            }
            if self.tableView.stickToBottom() {
                // table自动滚动到底时，不用显示气泡，新消息来了会自动显示
                return false
            }
            return true
        } else {
            // 上部气泡是否显示不受vc逻辑制约
            return true
        }
    }

    /// 跳转到"@我/@所有人"消息
    public func scrollTo(message: MessageInfoForUnReadTip, tipView: BaseUnReadMessagesTipView, finish: @escaping () -> Void) {
        self.tableView.setContentOffset(self.tableView.contentOffset, animated: false)
        let tracker = chatMessageViewModel.dependency.chatKeyPointTracker
        let indentify = tracker.generateIndentify()
        tracker.unReadTipStartJump(indentify: indentify)
        self.chatMessageViewModel.jumpTo(position: message.position, tableScrollPosition: .top, finish: { trackInfo in
            tracker.unReadTipFinishJump(indentify: indentify, scene: .unReadTipToPosition, trackInfo: trackInfo)
            finish()
        })

        // 气泡打点
        let tipViewType: TipViewType = (tipView == topUnReadMessagesTipView) ? .up : .down
        let mentionType: MentionType = message.isAtAll ? .all : .me
        ChatTracker.trackTipClick(tipState: tipView.unReadTipState,
                                  mentionType: mentionType,
                                  tipViewType: tipViewType)
    }

    /// 跳转到最新的未读消息
    func scrollToBottommostMessage(tipView: BaseUnReadMessagesTipView, finish: @escaping () -> Void) {
        self.tableView.setContentOffset(self.tableView.contentOffset, animated: false)
        let position: UITableView.ScrollPosition = (tipView.unReadTipState == .showToLastMessage) ? .bottom : .top
        let tracker = chatMessageViewModel.dependency.chatKeyPointTracker
        let indentify = tracker.generateIndentify()
        tracker.unReadTipStartJump(indentify: indentify)
        let trackJumpType: ChatKeyPointTracker.JumpScene = (tipView.unReadTipState == .showToLastMessage) ? .unReadTipToBottom : .unReadTipToBottomUnreadMessage
        self.chatMessageViewModel.jumpToChatLastMessage(tableScrollPosition: position) { trackInfo in
            tracker.unReadTipFinishJump(indentify: indentify, scene: trackJumpType, trackInfo: trackInfo)
            finish()
        }

        // 气泡点击打点
        ChatTracker.trackTipClick(tipState: tipView.unReadTipState,
                                  tipViewType: .down)
    }

    /// 跳转到最旧的未读消息
    func scrollToToppestUnReadMessage(tipView: BaseUnReadMessagesTipView, finish: @escaping () -> Void) {
        self.tableView.setContentOffset(self.tableView.contentOffset, animated: false)
        let tracker = chatMessageViewModel.dependency.chatKeyPointTracker
        let indentify = tracker.generateIndentify()
        tracker.unReadTipStartJump(indentify: indentify)
        self.chatMessageViewModel.jumpToOldestUnreadMessage { trackInfo in
            tracker.unReadTipFinishJump(indentify: indentify, scene: .unReadTipToTopUnreadMessage, trackInfo: trackInfo)
            finish()
        }

        // 气泡点击打点
        ChatTracker.trackTipClick(tipState: tipView.unReadTipState,
                                  tipViewType: .up)
    }
}

// MARK: - ChatPageAPI
extension ChatMessagesViewController: ChatPageAPI {
    var inSelectMode: Observable<Bool> {
        return self.chatMessageViewModel.inSelectMode.asObservable()
    }

    var selectedMessages: BehaviorRelay<[ChatSelectedMessageContext]> {
        return self.chatMessageViewModel.pickedMessages
    }

    func startMultiSelect(by messageId: String) {
        self.chatMessageViewModel.startMultiSelect(by: messageId)
    }

    func endMultiSelect() {
        self.chatMessageViewModel.finishMultiSelect()
    }

    func toggleSelectedMessage(by messageId: String) {
        self.chatMessageViewModel.toggleSelectedMessage(by: messageId)
    }

    func reloadRows(current: String, others: [String]) {
        guard let currentIndexPath = self.chatMessageViewModel.findMessageIndexBy(id: current) else {
            return
        }
        let otherIndexPaths = others.compactMap { (messageId) -> IndexPath? in
            return self.chatMessageViewModel.findMessageIndexBy(id: messageId)
        }
        if self.chatMessageViewModel.uiDataSource.count != self.tableView.numberOfRows(inSection: 0) {
            self.tableView.reloadData()
            Self.logger.warn("chatTrace uiDataSource count is not equal numberOfRows")
        }
        self.tableView.antiShakeReload(current: currentIndexPath, others: otherIndexPaths)
        self.tableView.scrollRectToVisibleBottom(indexPath: currentIndexPath, animated: true)
    }

    func originMergeForwardId() -> String? {
        return nil
    }
}

// MARK: - PageAPI
extension ChatMessagesViewController: PageAPI {
    func viewWillEndDisplay() {
        chatMessageViewModel.uiOutput(enable: false, indentify: "maskByCell")
        self.tableView.endDisplayVisibleCells()
    }

    func getChatThemeScene() -> ChatThemeScene {
        self.chatComponentScene
    }

    func viewDidDisplay() {
        chatMessageViewModel.uiOutput(enable: true, indentify: "maskByCell")
        self.tableView.displayVisibleCells()
    }

    var pageSupportReply: Bool {
        return self.bottomLayout.pageSupportReply()
    }

    var topNoticeSubject: BehaviorSubject<ChatTopNotice?>? {
        return self.chatMessageViewModel.topNoticeSubject
    }

    func getSelectionLabelDelegate() -> LKSelectionLabelDelegate? {
        return self.messageSelectControl
    }

    func jumpToChatLastMessage(tableScrollPosition: UITableView.ScrollPosition, needDuration: Bool) {
        self.chatMessageViewModel.jumpToChatLastMessage(tableScrollPosition: tableScrollPosition, needDuration: needDuration, finish: nil)
    }

    func showGuide(key: String) {
        self.bottomLayout.showGuide(key: key)
    }
}

// MARK: - EETroubleKiller
extension ChatMessagesViewController: CaptureProtocol & DomainProtocol {
    var chatLogInfo: [String: String] {
        let chat = self.chat.value
        return [
            "chatId": self.chatId,
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
            "lastVisibleMsgPosition": "\(chat.lastVisibleMessagePosition)"
        ]
    }

    var domainKey: [String: String] {
        return chatLogInfo
    }
}

// MARK: - EnterpriseEntityWordProtocol
extension ChatMessagesViewController: EnterpriseEntityWordDelegate {
    func lockForShowEnterpriseEntityWordCard() {
        ChatMessagesViewController.logger.info("ChatMessagesViewController: pauseQueue for show enterprise entuty word card")
        messageSelectControl?.lockChatTable()
        self.bottomLayout.lockForShowEnterpriseEntityWordCard()
    }

    func unlockForHideEnterpriseEntityWordCard() {
        ChatMessagesViewController.logger.info("ChatMessagesViewController: resumeQueue for after enterprise entuty word card hide")
        messageSelectControl?.unlockChatTable()
        self.bottomLayout.unlockForHideEnterpriseEntityWordCard()
    }
}

// MARK: - GCUnitDelegate
extension ChatMessagesViewController: GCUnitDelegate {
    func gc(limitWeight: Int64, callback: GCUnitDelegateCallback) {
        guard !multiSelecting, let range = tableView.visiblePositionRange() else { return }
        self.view.isUserInteractionEnabled = false
        let chatID = self.chat.value.id
        chatMessageViewModel.removeMessages(afterPosition: range.bottom, redundantCount: 5) {  //留5个消息的冗余
            callback.end(currentWeight: Int64($0))
            let trace = callback.traceInfo()
            ChatMessagesViewController.logger.info("chatTrace in GC \(chatID) limitWeight: \(trace.limitWeight)")
        }
    }
}

// MARK: - ChatBatchMultiSelectViewDelegate
extension ChatMessagesViewController: ChatBatchMultiSelectViewDelegate {
    func clickBatchSelect(centerPoint: CGPoint) {
        let referenceLocation = self.tableView.convert(centerPoint, from: self.view)
        self.tableView.clickBatchSelect(referenceLocation: referenceLocation)
        IMTracker.Msg.MultiSelect.Click.SelectFollowMsg(self.chat.value)
    }
}

// MARK: - UDZoom
extension ChatMessagesViewController {
    func reportZoomInitializationIfNeeded() {
        if UDZoom.isZoomInitialized, !UDZoom.isZoomInitReported {
            Tracker.post(TeaEvent(Homeric.INIT_TEXTSIZE, params: [
                "size": UDZoom.currentZoom.name
            ]))
            UDZoom.isZoomInitReported = true
        }
    }
}

// MARK: - ChatMessageTabPageAPI
extension ChatMessagesViewController: ChatMessageTabPageAPI {
    func setUpdateTopNotice(updateNotice: @escaping ((ChatTopNotice?) -> Void)) {
        self.topNoticeDataManger.addTopNotice(listener: updateNotice)
    }

    func contentTopMarginHasChanged() {
        self.adjustTableViewContentInset()
        AudioPlayStatusView.setAudioPlayStatusTopMargin(self.chatMessageBaseDelegate?.contentTopMargin, view: self.view)
        contentTopMarginGuide?.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.chatMessageBaseDelegate?.getTopContainerBottomConstraintItem() ?? self.view.snp.top)
            make.height.equalTo(0)
        }
    }
    func isMultiSelecting() -> Bool {
        return self.multiSelecting
    }
}

extension ChatMessagesViewController: ChatInteractionKitDelegate {
    func canHandleDropInteraction() -> Bool {
        return self.bottomLayout.canHandleDropInteraction()
    }

    func handleDropChatModel() -> Chat {
        return self.chat.value
    }

    func handleImageTypeDropItem(image: UIImage) {
        let imageMessageInfo = generateSendImageMessageInfoInChat(image)
        self.messageSender.sendImages(
            parentMessage: nil,
            useOriginal: false,
            imageMessageInfos: [imageMessageInfo],
            chatId: self.chat.value.id,
            lastMessagePosition: self.chat.value.lastMessagePosition,
            quasiMsgCreateByNative: self.quasiMsgCreateByNative(),
            extraTrackerContext: [ChatKeyPointTracker.selectAssetsCount: 1,
                                  ChatKeyPointTracker.chooseAssetSource: ChatKeyPointTracker.ChooseAssetSource.other.rawValue]
        )
    }

    func handleTextTypeDropItem(text: String) {
        self.bottomLayout.handleTextTypeDropItem(text: text)
    }

    func handleFileTypeDropItem(name: String?, url: URL) {
        messageSender.sendFile(
            path: url.path,
            name: name ?? "",
            parentMessage: nil,
            removeOriginalFileAfterFinish: false,
            chatId: self.chat.value.id,
            lastMessagePosition: self.chat.value.lastMessagePosition,
            quasiMsgCreateByNative: self.quasiMsgCreateByNative())
    }

    func interactionTargetController() -> UIViewController {
        return self
    }
}

func generateSendImageMessageInfoInChat(_ image: UIImage) -> ImageMessageInfo {
    let (imgImageInfo, type) = (image.jpegImageInfo(), ImageFileFormat.jpeg)
    // 添加imagePath，图片在转文件时，会判断imagePathProvider是否为nil
    func imagePath(_ block: @escaping (URL?) -> Void) {
        guard let data = imgImageInfo.data else {
            block(nil)
            return
        }
        let dir = IsoPath.glboalTemporary(in: Domain.biz.messenger) + "tempUIImage"
        try? dir.createDirectoryIfNeeded()
        let imageName = "image_" + UUID().uuidString + ".JPG"
        let path = dir + imageName
        try? path.removeItem()
        do {
            try data.write(to: path)
            block(path.url)
        } catch {
            block(nil)
        }
    }
    let imageMessageInfo = ImageMessageInfo(
        originalImageSize: image.size,
        sendImageSource: SendImageSource(cover: { imgImageInfo }, origin: { imgImageInfo }),
        // imageSize是图片转文件时，对比的一项
        imageSize: Int64(imgImageInfo.data?.count ?? 0),
        imageType: type,
        imagePathProvider: imagePath
    )
    return imageMessageInfo
}
