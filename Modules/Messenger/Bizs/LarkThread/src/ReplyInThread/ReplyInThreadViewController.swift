//
//  ReplyInThreadViewController.swift
//  LarkThread
//
//  Created by liluobin on 2022/4/8.
//

import UIKit
import Foundation
import Lottie
import SnapKit
import RxSwift
import RxCocoa
import LarkCore
import LarkKeyboardView
import LarkModel
import LarkUIKit
import AppReciableSDK
import EENavigator
import LarkMessageCore
import LKCommonsTracker
import LKCommonsLogging
import LarkMessageBase
import LarkMenuController
import LarkFeatureGating
import LarkSendMessage
import LarkSDKInterface
import LarkMessengerInterface
import LarkKeyCommandKit
import LarkAlertController
import LarkSplitViewController
import LarkAI
import LarkSceneManager
import LarkRichTextCore
import RustPB
import LarkSuspendable
import LarkContainer
import RichLabel
import UniverseDesignToast
import UniverseDesignDialog
import LarkOpenChat
import LarkChatOpenKeyboard
import LarkBaseKeyboard

final class ReplyInThreadViewController: ThreadDetailBaseViewController {
    private static let logger = Logger.log(ReplyInThreadViewController.self, category: "LarkThread.ReplyInThread")
    static let pageName = "\(ReplyInThreadViewController.self)"
    enum LoadType {
        case unread
        case position(Int32)
        case root
        case justReply

        public var rawValue: Int {
            switch self {
            case .unread: return 0
            case .position: return 1
            case .root: return 2
            case .justReply: return 3
            }
        }
    }
    let chatFromWhere: ChatFromWhere

    private let disposeBag = DisposeBag()

    lazy fileprivate(set) var threadKeyboard: ThreadKeyboard? = {
        guard let keyboard = try? self.keyboardBlock(self) else { return nil }
        //只保存根消息草稿,detail页面所有消息都默认回复根消息
        keyboard.viewModel.rootMessage = self.viewModel.rootMessage
        keyboard.keyboardView.keyboardShareDataService.forwardToChatSerivce.updateText(chat: self.viewModel._chat, showFromChat: showFromChat)
        let info = KeyboardJob.ReplyInfo(message: self.viewModel.rootMessage, partialReplyInfo: nil)
        keyboard.keyboardView.keyboardStatusManager.defaultKeyboardJob = .reply(info: info)
        keyboard.keyboardView.keyboardStatusManager.switchJob(.reply(info: info))
        keyboard.viewModel.isShowAtAll = false
        return keyboard
    }()

    lazy var forwardThreadButton: UIButton = {
        let forwardButton = UIButton()
        forwardButton.setImage(Resources.replyInThreadFoward.withRenderingMode(.alwaysTemplate), for: .normal)
        forwardButton.addTarget(self, action: #selector(forwardThreadButtonTappped), for: .touchUpInside)
        forwardButton.tintColor = UIColor.ud.iconN1
        forwardButton.addPointerStyle()
        return forwardButton
    }()

    var threadKeyboardView: ThreadKeyboardView? {
        return self.threadKeyboard?.keyboardView
    }

    lazy var tableView: ThreadDetailTableView = {
        let tableView = ThreadDetailTableView(viewModel: self.viewModel, tableDelegate: self, chatFromWhere: self.chatFromWhere)
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: CGFloat.leastNonzeroMagnitude, height: CGFloat.leastNonzeroMagnitude))
        return tableView
    }()

    private var messageSelectControl: ThreadMessageSelectControl?

    private var viewDidAppeaded: Bool = false

    private func showThreadVC() {
        let chat = self.viewModel._chat
        /// TODO: 李洛斌 MVP的后续版本需要考虑
        /// 当前不是该群的成员，无法进入该页面
        if chat.role != .member && chat.isPublic {
            let body = JoinGroupApplyBody(
                chatId: chat.id,
                way: .viaSearch
            )
            navigator.open(body: body, from: self)
        } else if chat.role == .member {
            // 已经是成员
            let message = self.viewModel.rootMessage
            let body = ChatControllerByChatBody(
                chat: chat,
                position: message.position
            )
            navigator.push(body: body, from: self)
        }
    }

    lazy var downUnReadMessagesTipView: DownUnReadMessagesTipView = {
        let thread = self.viewModel.threadObserver.value
        let viewModel = DownUnReadThreadDetailsTipViewModel(
            userResolver: self.userResolver,
            threadId: thread.id,
            threadObserver: self.viewModel.threadObserver,
            lastMessagePosition: thread.lastMessagePosition,
            requestCount: self.viewModel.requestCount,
            redundancyCount: self.viewModel.redundancyCount,
            threadAPI: self.viewModel.threadAPI
        )

        let tipView = DownUnReadMessagesTipView(
            chat: self.viewModel._chat,
            viewModel: viewModel
        )
        tipView.delegate = self
        return tipView
    }()

    lazy var fullScreenIcon: SecondaryOnlyButton = {
        let icon = SecondaryOnlyButton(vc: self)
        icon.addDefaultPointer()
        return icon
    }()

    lazy var moreBarButton: UIButton = {
        let moreButton = UIButton()
        moreButton.setImage(Resources.thread_detail_nav_more.withRenderingMode(.alwaysTemplate), for: .normal)
        moreButton.tintColor = UIColor.ud.iconN1
        moreButton.addTarget(self, action: #selector(moreButtonTapped(sender:)), for: .touchUpInside)
        moreButton.addPointerStyle()
        return moreButton
    }()

    let viewModel: ReplyInThreadViewModel
    let chatAPI: ChatAPI
    typealias KeyboardBlock = (ThreadKeyboardDelegate & ThreadKeyboardViewModelDelegate) throws -> ThreadKeyboard
    let keyboardBlock: KeyboardBlock
    private let loadType: LoadType
    private var menuService: ThreadMenuService
    private let sourceType: ReplyInThreadFromSourceType
    private var keyboardStartupState: KeyboardStartupState

    private let context: ThreadDetailContext
    private let dependency: ThreadDetailControllerDependency
    private let getContainerController: () -> UIViewController?
    public var specificSource: SpecificSourceFromWhere? //细化的二级来源
    // 定时发送服务
    @ScopedInjectedLazy public var scheduleSendService: ScheduleSendService?
    /// 统计页面时长
    @ScopedInjectedLazy private var chatDurationStatusTrackService: ChatDurationStatusTrackService?
    @ScopedInjectedLazy var lingoHighlightService: LingoHighlightService?
    var showFromChat: Bool = false

    private lazy var screenProtectService: ChatScreenProtectService? = {
        return self.context.pageContainer.resolve(ChatScreenProtectService.self)
    }()

    private lazy var placeholderChatView: PlaceholderChatView = {
        let placeholderChatView = PlaceholderChatView(isDark: false,
                                                      title: BundleI18n.LarkThread.Lark_IM_RestrictedMode_ScreenRecordingEmptyState_Text,
                                                      subTitle: BundleI18n.LarkThread.Lark_IM_RestrictedMode_ScreenRecordingEmptyState_Desc)
        placeholderChatView.setNavigationBarDelegate(self)
        return placeholderChatView
    }()

    /// 定时发送提示
    private lazy var scheduleSendTipView: ChatScheduleSendTipView? = {
        guard scheduleSendService?.scheduleSendEnable ?? false else { return nil }
        let chat = self.viewModel._chat
        if chat.isPrivateMode || chat.isCrypto { return nil }

        let disableObservable = self.viewModel.chatObserver.asObservable().map({ !$0.isAllowPost }).distinctUntilChanged()
        let push = self.viewModel.pushScheduleMessage
        let rootMessage = self.viewModel.rootMessage
        let vm = ChatScheduleSendTipViewModel(chatId: Int64(chat.id) ?? 0,
                                              threadId: !rootMessage.threadId.isEmpty ? Int64(rootMessage.threadId) ?? 0 : Int64(rootMessage.id) ?? 0,
                                              rootId: nil,
                                              scene: .replyInThread,
                                              messageObservable: .empty(),
                                              sendEnable: chat.isAllowPost,
                                              disableObservable: disableObservable,
                                              pushObservable: push,
                                              userResolver: self.userResolver)
        return ChatScheduleSendTipView(backgroundColor: UIColor.ud.bgBody,
                                       viewModel: vm)
    }()

    //键盘上方区域
    private lazy var keyboardTopStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 0.0
        stackView.backgroundColor = UIColor.ud.bgBodyOverlay
        return stackView
    }()

    var keyboardTopStackHeight: CGFloat {
        // 某些机型下，当键盘上方区域没有任何子视图展示时，在进群时机系统返回bounds.height会遇到不正确的问题
        if self.scheduleSendTipView?.isHidden ?? true {
            return 0
        }
        return self.keyboardTopStackView.bounds.height
    }

    /// 注册 Reply In Thread 全部话题界面的 MessageActionMenu
    func registerThreadMessageActionMenu(actionContext: MessageActionContext) {
        actionContext.container.register(ChatMessagesOpenService.self) { [weak self] _ -> ChatMessagesOpenService in
            return self ?? DefaultChatMessagesOpenService()
        }
        ReplyThreadMessageActionModule.onLoad(context: actionContext)
        let actionModule = ReplyThreadMessageActionModule(context: actionContext)
        // 处理内存泄漏临时解法: OpenIM和PageContainer两个容器没有打通, ChatPinService需要也被OpenIM持有
        if let chatPinservice = context.pageContainer.resolve(ChatPinPageService.self) {
            actionContext.container.register(ChatPinPageService.self) { _ in
                return chatPinservice
            }
        }
        let messageMenuService = MessageMenuServiceImp(pushWrapper: viewModel.chatWrapper,
                                                    actionModule: actionModule)
        context.pageContainer.register(MessageMenuOpenService.self) {
            return messageMenuService
        }
    }

    /// 注册页面服务
    func registerPageServices(chatID: String, pageContext: PageContext) {
        context.pageContainer.register(ChatPinPageService.self) { [weak pageContext] in
            return ChatPinPageService(chatID: chatID, pageContext: pageContext)
        }
    }

    init(
        loadType: LoadType,
        viewModel: ReplyInThreadViewModel,
        context: ThreadDetailContext,
        messageActionContext: MessageActionContext,
        keyboardStartupState: KeyboardStartupState,
        chatAPI: ChatAPI,
        menuService: ThreadMenuService,
        sourceType: ReplyInThreadFromSourceType,
        keyboardBlock: @escaping KeyboardBlock,
        dependency: ThreadDetailControllerDependency,
        getContainerController: @escaping () -> UIViewController?,
        chatFromWhere: ChatFromWhere,
        specificSource: SpecificSourceFromWhere? = nil
    ) {
        self.getContainerController = getContainerController
        self.viewModel = viewModel
        self.sourceType = sourceType
        self.context = context
        self.keyboardBlock = keyboardBlock
        self.loadType = loadType
        self.keyboardStartupState = keyboardStartupState
        self.chatAPI = chatAPI
        self.menuService = menuService
        self.dependency = dependency
        self.chatFromWhere = chatFromWhere
        self.specificSource = specificSource
        super.init(userResolver: viewModel.userResolver)
        self.context.pageContainer.pageInit()
        // MessageAction依赖页面服务, 页面服务注册因在MessageAction注册之前
        self.registerPageServices(chatID: viewModel._chat.id, pageContext: context)
        self.registerThreadMessageActionMenu(actionContext: messageActionContext)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.context.pageContainer.pageDeinit()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.messageSelectControl?.dismissMenuIfNeeded()
    }

    override func splitVCSplitModeChange(split: SplitViewController) {
        super.splitVCSplitModeChange(split: split)
        self.messageSelectControl?.dismissMenuIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.threadKeyboardView?.showNewLine = true
        context.pageContainer.pageWillAppear()
        updateLeftNavigationItems()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        chatDurationStatusTrackService?.markIfViewControllerIsAppear(value: true)
        if !viewDidAppeaded {
            viewDidAppeaded = true
            self.threadKeyboard?.setupStartupKeyboardState()
        }
        threadKeyboardView?.viewControllerDidAppear()
        context.pageContainer.pageDidAppear()
        updateLeftNavigationItems()

        if Display.externalKeyboard, self.userResolver.fg.dynamicFeatureGatingValue(with: "ios.display.externalkeyboard") {
            self.keyboardView?.inputViewBecomeFirstResponder()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.threadKeyboardView?.showNewLine = false
        self.saveDraft()
        threadKeyboardView?.viewControllerWillDisappear()
        context.pageContainer.pageWillDisappear()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        chatDurationStatusTrackService?.markIfViewControllerIsAppear(value: false)
        context.pageContainer.pageDidDisappear()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.supportSecondaryOnly = true
        self.supportSecondaryPanGesture = true
        self.keyCommandToFullScreen = true
        self.setupView()
        // 视图初始化后立即赋值，如果在监听之后用到，会因为立即来了数据push，导致crash
        self.viewModel.hostUIConfig = HostUIConfig(
            size: navigationController?.view.bounds.size ?? view.bounds.size,
            safeAreaInsets: navigationController?.view.safeAreaInsets ?? view.safeAreaInsets
        )
        self.observerViewModel()
        self.setupDraft()
        self.setupLingo()
        self.messageSelectControl = ThreadMessageSelectControl(chat: self, pasteboardToken: "LARK-PSDA-messenger-replyInThread-select-copyCommand-permission")
        messageSelectControl?.menuService = self.context.pageContainer.resolve(MessageMenuOpenService.self)
        self.messageSelectControl?.addMessageSelectObserver()
        self.obserScroll()
        self.context.pageContainer.beforeFetchFirstScreenMessages()
        self.viewModel.initMessages(loadType: self.loadType)
        self.context.pageContainer.pageViewDidLoad()
        observeScreenShot()
        chatDurationStatusTrackService?.setGetChatBlock { [weak self] in
            return self?.viewModel._chat
        }
        trackReplyThreadView()
    }

    override func subProviders() -> [KeyCommandProvider] {
        var providers: [KeyCommandProvider] = [self.tableView]
        if let threadKeyboardView { providers.append(threadKeyboardView) }
        return providers
    }

    private func resizeVMIfNeeded() {
        let size = view.bounds.size
        if size != viewModel.hostUIConfig.size {
            let needOnResize = size.width != viewModel.hostUIConfig.size.width
            viewModel.hostUIConfig.size = size
            let fg = self.userResolver.fg.dynamicFeatureGatingValue(with: "im.message.resize_if_need_by_width")
            if fg {
                // 仅宽度更新才刷新cell，因为部分机型系统下(iphone8 iOS15、不排除其他系统也存在相同问题)存在非预期回调，比如当唤起大图查看器时，系统回调了该函数，且给的高度不对
                /*1. cell渲染只依赖宽度 2. 目前正常情况下不存在只变高，不变宽的情况（转屏、ipad拖拽）
                 */
                if needOnResize {
                    viewModel.onResize()
                }
            } else {
                viewModel.onResize()
            }
        }
    }

    private func setupView() {
        self.view.backgroundColor = UIColor.ud.bgBase
        self.setupNavBar()
        self.reloadNavigationBar()
        self.addTableAndInput()
    }

    private func setupKeyboardTopStackView() {
        guard let threadKeyboard else { return }
        self.view.addSubview(self.keyboardTopStackView)
        var heightConstraint: SnapKit.Constraint?
        self.keyboardTopStackView.snp.makeConstraints { make in
            make.bottom.equalTo(threadKeyboard.keyboardView.snp.top)
            heightConstraint = make.height.equalTo(0).constraint
            make.left.right.equalToSuperview()
        }
        heightConstraint?.activate()

        if var scheduleSendTipView = self.scheduleSendTipView {
            heightConstraint?.deactivate()
            self.keyboardTopStackView.addArrangedSubview(scheduleSendTipView)
            scheduleSendTipView.delegate = self
            scheduleSendTipView.preferMaxWidth = self.view.bounds.width
            scheduleSendTipView.isHidden = true
            scheduleSendTipView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
            }
        }
    }

    /// 配置导航栏
    private func setupNavBar() {
        isNavigationBarHidden = true
        addBackItemForNavBar()
        let factory = ReplyTitleViewFactory(userResolver: self.userResolver)
        let style: ReplyTitleViewFactory.Style = showFromChat ? .source : .normal
        navBar.titleView = factory.createTitleViewWith(style: style,
                                                       rootMessageFromId: viewModel.rootMessage.fromId,
                                                    chatObservable: viewModel.chatObserver,
                                                    tap: { [weak self] in
            self?.showThreadVC()
        })
        self.view.addSubview(navBar)
        navBar.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resizeVMIfNeeded()
        if self.placeholderChatView.superview != nil {
            self.view.bringSubviewToFront(placeholderChatView)
        }
    }

    override func multiSelectingValueUpdate() {
        if multiSelecting {
            self.tableView.longPressGesture.isEnabled = false
            self.threadKeyboard?.keyboardView.alpha = 0
            self.reloadNavigationBar()
            let bottomMenBarHeight = BottomMenuBar.barHeight(in: self.view)
            self.tableView.snp.remakeConstraints { (make) in
                make.leading.trailing.equalTo(self.view)
                make.top.equalTo(navBar.snp.bottom)
                make.bottom.equalTo(self.view).offset(-bottomMenBarHeight)
            }
            self.view.layoutIfNeeded()
        } else {
            self.tableView.longPressGesture.isEnabled = true
            self.threadKeyboard?.keyboardView.alpha = 1
            self.reloadNavigationBar()
            self.remakeTableViewConstraint()
            self.view.layoutIfNeeded()
            self.tableView.setContentOffset(CGPoint(x: 0, y: self.tableView.contentOffset.y), animated: false)
        }
    }

    private func reloadNavigationBar() {
        if multiSelecting {
            navBar.rightViews = [cancelMutilButton]
        } else {
            var items: [UIView] = []
            if viewModel.threadHadCreate {
                rightView.addSubview(moreBarButton)
                items.append(moreBarButton)
            }

            if viewModel.rootMessage.localStatus == .success,
               !viewModel.rootMessage.isDecryptoFail {
                if !self.viewModel.threadHadCreate {
                    forwardThreadButton.removeFromSuperview()
                    rightView.addSubview(forwardBarButton)
                    items.append(forwardBarButton)
                } else {
                    forwardBarButton.removeFromSuperview()
                    rightView.addSubview(forwardThreadButton)
                    items.append(forwardThreadButton)
                }
            }
            layoutViewItems(items)
            navBar.rightViews = [rightView]
        }
    }

    private func layoutViewItems(_ items: [UIView]) {
        if items.isEmpty {
            return
        }
        if items.count == 1, let item = items.first {
            item.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview()
                make.height.equalTo(20)
            }
            return
        }
        var rightItem: UIView?
        for (index, item) in items.enumerated() {
            if index == items.count - 1, let rightItem = rightItem {
                item.snp.remakeConstraints { (make) in
                    make.right.equalTo(rightItem.snp.left).offset(-20)
                    make.top.bottom.equalToSuperview()
                    make.height.equalTo(20)
                    make.left.equalToSuperview().offset(10)
                }
            } else {
                item.snp.remakeConstraints { (make) in
                    if let rightItem = rightItem {
                        make.right.equalTo(rightItem.snp.left).offset(-20)
                    } else {
                        make.right.equalToSuperview()
                    }
                    make.centerY.equalToSuperview()
                }
                rightItem = item
            }
        }
    }

    private func resetTableViewConstraintWhenKeyboardArangViewShow() {
        let currentTableHeight = self.tableView.frame.height
        self.view.layoutIfNeeded()
        var offset = currentTableHeight - self.tableView.frame.height
        if offset <= 0 {
            offset = 0
        }

        let totalHeight = self.tableView.adjustedContentInset.top + self.tableView.adjustedContentInset.bottom + self.tableView.contentSize.height
        let completeShow = (totalHeight <= self.tableView.frame.size.height)
        if completeShow {
            self.tableView.scrollToBottom(animated: true)
        } else {
            self.tableView.setContentOffset(CGPoint(x: 0, y: self.tableView.contentOffset.y + offset), animated: true)
        }
    }

    func remakeTableViewConstraint() {
        self.tableView.snp.remakeConstraints { (make) in
            make.leading.trailing.equalTo(self.view)
            make.top.equalTo(navBar.snp.bottom)
            make.bottom.equalTo(getTableBottomConstraintItem())
        }
    }

    private func getTableBottomConstraintItem() -> SnapKit.ConstraintItem {
        return self.keyboardTopStackView.snp.top
    }

    private func addTableAndInput() {
        guard let threadKeyboardView else { return }
        self.view.addSubview(tableView)
        self.view.addSubview(threadKeyboardView)
        setupKeyboardTopStackView()

        threadKeyboardView.expandType = .show
        threadKeyboardView.snp.makeConstraints({ make in
            make.left.right.bottom.equalToSuperview()
        })

        tableView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(navBar.snp.bottom)
            make.bottom.equalTo(getTableBottomConstraintItem())
        }
    }

    private func obserScroll() {
        let offset = self.tableView.rx.contentOffset.asDriver().map { _ in return }
        offset
            .filter { [weak self] (_) -> Bool in
                guard let `self` = self else { return false }
                return (self.viewModel.uiDataSource.first?.isEmpty ?? true) && self.tableView.contentOffset.y < -8
            }
            .drive(onNext: { [weak self] (_) in
                self?.viewModel.showRootMessage()
            })
            .disposed(by: disposeBag)
    }

    private func setupUnreadTipView() {
        self.view.insertSubview(downUnReadMessagesTipView, aboveSubview: self.tableView)
        downUnReadMessagesTipView.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-5)
            make.bottom.equalTo(self.tableView).offset(-15)
        }
        (self.downUnReadMessagesTipView.viewModel as? DownUnReadThreadDetailsTipViewModel)?
            .update(thread: self.viewModel.threadObserver.value)
    }

    private func setupDraft() {
        /// 根据跟消息的id 获取当前的草稿
        self.viewModel.rootMessageMsgThreadDraft()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (content) in
                guard let self = self else { return }
                /// 跟产品沟通后 草稿不兼 无需考虑之前reply in thread的草稿
                if let keyboard = self.threadKeyboard as? ReplyInThreadNewThreadboard {
                    keyboard.updateDraftContent(by: content)
                }
            }).disposed(by: self.disposeBag)
    }

    /// 注册输入框内百科高亮服务
    private func setupLingo() {
        lingoHighlightService?.setupLingoHighlight(chat: viewModel._chat,
                                                  fromController: self,
                                                  inputTextView: threadKeyboard?.keyboardView.inputTextView,
                                                  getMessageId: { [weak self] in
            self?.threadKeyboard?.keyboardView.keyboardStatusManager.getMultiEditMessage()?.id ?? ""
        })
    }

    private func saveDraft() {
        if let multiEditMessage = self.threadKeyboard?.keyboardView.keyboardStatusManager.getMultiEditMessage() {
            if let keyboard = self.threadKeyboard as? ReplyInThreadNewThreadboard {
                keyboard.saveInputViewDraft(id: .multiEditMessage(messageId: multiEditMessage.id,
                                                                  chatId: viewModel._chat.id))
            }
        } else if let replyMessage = self.threadKeyboard?.viewModel.replyMessage,
            let keyboard = self.threadKeyboard as? ReplyInThreadNewThreadboard,
                  !(self.threadKeyboard?.keyboardView.keyboardStatusManager.currentKeyboardJob.isScheduleSendState == true) {
                keyboard.saveInputViewDraft(id: .replyInThread(messageId: replyMessage.id))
        }
    }

    override func clickSceneButton(sender: UIButton) {
        if #available(iOS 13.0, *) {
            var userInfo: [String: String] = [:]
            userInfo["chatID"] = "\(self.viewModel._chat.id)"
            let scene = LarkSceneManager.Scene(
                key: "Thread",
                id: self.viewModel.threadObserver.value.id,
                title: self.viewModel.chatObserver.value.displayName,
                userInfo: userInfo,
                sceneSourceID: self.currentSceneID(),
                windowType: "channel",
                createWay: "window_click"
            )
            SceneManager.shared.active(scene: scene, from: self) { [weak self] (_, error) in
                if let self = self, error != nil {
                    UDToast.showTips(
                        with: BundleI18n.LarkThread.Lark_Core_SplitScreenNotSupported,
                        on: self.view
                    )
                }
            }
        } else {
            assertionFailure()
        }
    }
    override func cancelMutilButtonTapped(sender: UIButton) {
        self.viewModel.finishMultiSelect()
    }

    private func checkForwardPermission() -> Bool {
        let chat = viewModel._chat
        if chat.enableRestricted(.forward) {
            UDToast.showTips(with: BundleI18n.LarkThread.Lark_IM_RestrictedMode_CopyForwardNotAllow_Toast, on: self.view)
            return false
        }
        // 服务端禁用 transmit 行为时,禁止转发
        if let disableBehavior = viewModel.rootMessage.disabledAction.actions[Int32(MessageDisabledAction.Action.transmit.rawValue)] {
            let errorMessage: String
            switch disableBehavior.code {
            case 311_150:
                errorMessage = BundleI18n.LarkThread.Lark_IM_MessageRestrictedCantForward_Hover
            default:
                errorMessage = BundleI18n.LarkThread.Lark_IM_UnableOperationDueToPermissionRestrictions_Toast
            }
            UDToast.showFailure(with: errorMessage, on: self.view)
            return false
        }
        return true
    }

    @objc
    private func forwardThreadButtonTappped() {
        guard checkForwardPermission(), viewModel.rootMessage.threadMessageType != .unknownThreadMessage else {
            Self.logger.error("forwardButtonTapped chatID: \(viewModel._chat.id) \(viewModel.rootMessage.threadMessageType)")
            return
        }
        let containBurnMessage = viewModel.replies.contains(where: { $0.isOnTimeDel == true }) || viewModel.rootMessage.isOnTimeDel
        let body = MergeForwardMessageBody(
            originMergeForwardId: nil,
            fromChannelId: viewModel._chat.id,
            messageIds: [viewModel.rootMessage.id],
            threadRootMessage: viewModel.rootMessage,
            title: BundleI18n.LarkThread.Lark_Legacy_ForwardGroupChatHistory,
            forwardThread: true,
            traceChatType: .thread,
            finishCallback: nil,
            supportToMsgThread: true,
            isMsgThread: true,
            containBurnMessage: containBurnMessage
        )
        self.navigator.present(
            body: body,
            from: self,
            prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() })
    }

    override func forwardButtonTapped(sender: UIButton) {
        guard checkForwardPermission(), viewModel.rootMessage.threadMessageType == .unknownThreadMessage else {
            Self.logger.error("forwardButtonTapped chatID: \(viewModel._chat.id) \(viewModel.rootMessage.threadMessageType)")
            return
        }
        let body = ForwardMessageBody(originMergeForwardId: nil,
                                      message: viewModel.rootMessage,
                                      type: .message(viewModel.rootMessage.id),
                                      from: .thread,
                                      supportToMsgThread: true,
                                      traceChatType: .threadDetail)
        self.navigator.present(
            body: body,
            from: self,
            prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() }
        )
        self.trackReplyThreadClick(.forward)
    }

    @objc
    private func moreButtonTapped(sender: UIButton) {
        guard let threadKeyboard else { return }
        threadKeyboard.keyboardView.inputTextView.resignFirstResponder()
        threadKeyboard.keyboardView.fold()
        var itemTypes: [ThreadMenuType] = []
        itemTypes.append((viewModel.threadObserver.value.isFollow ? .unsubscribe : .subscribe))
        if viewModel.threadObserver.value.isFollow {
            itemTypes.append((viewModel.threadObserver.value.isRemind ? .muteMsgNotice : .msgNotice))
        }
        let menuVC = ThreadFloatMenuController(pointView: sender,
                                  itemTypes: itemTypes,
                                  actionFunc: { [weak self] (type) in
            switch type {
            case .subscribe, .unsubscribe:
                self?.viewModel.toggleFollow()
            case .msgNotice, .muteMsgNotice:
                self?.viewModel.toggleThreadRemindStatus()
            default:
                break
            }
            self?.trackReplyThreadClickFromThreadMenuType(type)
        })
        menuVC.modalPresentationStyle = .overFullScreen
        self.present(menuVC, animated: false)
        let targetVC = self.navigationController ?? self
    }

    // MARK: 全屏按钮
    override func splitSplitModeChange(splitMode: SplitViewController.SplitMode) {
        self.updateLeftNavigationItems()
    }

    private func addBackItemForNavBar() {
        navBar.addBackButton { [weak self] in
            self?.backItemTapped()
        }
    }

    private func addCloseItemForNavBar() {
        navBar.addCloseButton { [weak self] in
            self?.closeBtnTapped()
        }
    }
}

// MARK: - ReplyInThreadViewController 对 OpenIM 架构暴露的关于Messages的能力
extension ReplyInThreadViewController: ChatMessagesOpenService {
    func getUIMessages() -> [LarkModel.Message] {
        return self.viewModel.uiDataSource.flatMap {
            return $0.compactMap { item in
                return (item as? HasMessage)?.message
            }
        }
    }
    var pageAPI: LarkMessageBase.PageAPI? {
        return self
    }
    var pageContainer: LarkMessageBase.PageContainer? {
        return self.context.pageContainer
    }
    var dataSource: LarkMessageBase.DataSourceAPI? {
        return self.context.dataSourceAPI
    }
}

extension ReplyInThreadViewController {
    private func observeScreenShot() {
        //监听截屏事件，打log
        NotificationCenter.default.rx.notification(UIApplication.userDidTakeScreenshotNotification)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self, self.viewIfLoaded?.window != nil else { return }
                let viewModels = self.viewModel.uiDataSource
                let visibleViewModels = (self.tableView.indexPathsForVisibleRows ?? [])
                    .map { viewModels[$0.section][$0.row] }
                let messages: [[String: String]] = visibleViewModels
                    .compactMap { (vm: ThreadDetailCellViewModel) -> Message? in (vm as? HasMessage)?.message }
                    .map { (message: Message) -> [String: String]  in
                        let message_length = self.viewModel.modelService?.messageSummerize(message).count ?? -1
                        return ["id": "\(message.id)",
                         "time": "\(message.updateTime)",
                         "type": "\(message.type)",
                         "position": "\(message.position)",
                         "read_count": "\(message.readCount)",
                         "message_length": "\(message_length)"]
                    }
                let jsonEncoder = JSONEncoder()
                jsonEncoder.outputFormatting = .sortedKeys
                let data = (try? jsonEncoder.encode(messages)) ?? Data()
                let jsonStr = String(data: data, encoding: .utf8) ?? ""
                Self.logger.info("user screenshot accompanying infos:" + "channel_id: \(self._chat?.id ?? ""), messages: \(jsonStr)")
            })
            .disposed(by: disposeBag)
    }

    func observerViewModel() {
        self.viewModel.deleteMeFromChannelDriver
            .filter({ [weak self] _ in
                guard let self = self else {
                    return false
                }
                //如果是从Chat页面进来的，会在ChatController监听，这里不重复处理
                return !(self.sourceType == .chat)
            })
            .asObservable()
            .take(1)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (content) in
                self?.alertBeDeletedFromChannel(content: content)
            }).disposed(by: self.disposeBag)
        self.viewModel.tableRefreshDriver
            .drive(onNext: { [weak self] (refreshType) in
                switch refreshType {
                case .showRootMessage:
                    self?.tableView.reloadData()
                case .initMessages(let info):
                    self?.setupUnreadTipView()
                    self?.refreshForInitMessages(hasHeader: info.hasHeader,
                                                 hasFooter: info.hasFooter,
                                                 scrollType: info.scrollType)
                case .refreshMessages(let hasHeader, let hasFooter, let scrollType):
                    self?.refreshForMessages(hasHeader: hasHeader, hasFooter: hasFooter, scrollType: scrollType)
                case .loadMoreOldMessages(let hasHeader):
                    self?.tableView.headInsertCells(hasHeader: hasHeader)
                case .loadMoreNewMessages(let hasFooter):
                    self?.tableView.appendCells(hasFooter: hasFooter)
                case .scrollTo(let type):
                    self?.scrollTo(scrollType: type)
                case .updateHeaderView(let hasHeader):
                    self?.tableView.hasHeader = hasHeader
                case .updateFooterView(let hasFooter):
                    self?.tableView.hasFooter = hasFooter
                case .refreshTable:
                    self?.tableView.reloadAndGuarantLastCellVisible()
                case .refreshMissedMessage:
                    self?.tableView.keepOffsetRefresh(nil)
                case .hasNewMessage(let hasFooter):
                    self?.refreshForNewMessage()
                    self?.tableView.hasFooter = hasFooter
                case .showRoot(let rootHeight):
                    self?.tableView.showRoot(rootHeight: rootHeight)
                case .messagesUpdate(indexs: let indexs, guarantLastCellVisible: let guarantLastCellVisible):
                    self?.tableView.refresh(indexPaths: indexs, guarantLastCellVisible: guarantLastCellVisible)
                case .startMultiSelect(let startIndexPath):
                    self?.multiSelecting = true
                    self?.tableView.reloadData()
                    self?.tableView.scrollRectToVisibleBottom(indexPath: startIndexPath, animated: true)
                case .finishMultiSelect:
                    self?.multiSelecting = false
                    self?.tableView.reloadAndGuarantLastCellVisible()
                case .refreshNavBar:
                    self?.reloadNavigationBar()
                }
            }).disposed(by: self.disposeBag)

        viewModel.sendMessageStatusDriver.drive(onNext: { [weak self] (message, error) in
            guard let `self` = self else { return }
            if let apiError = error?.underlyingError as? APIError {
                switch apiError.type {
                case .messageTooLarge:
                    UDToast.showFailure(
                        with: BundleI18n.LarkThread.Lark_Legacy_MessageTooLargeAlert,
                        on: self.view,
                        error: apiError)
                case .noMessagePermission:
                    UDToast.showFailure(
                        with: BundleI18n.LarkThread.Lark_Legacy_NoMessagePermissionAlert,
                        on: self.view,
                        error: apiError
                    )
                case .unknownBusinessError(let message), .topicHasClosed(let message):
                    UDToast.showFailure(
                        with: message,
                        on: self.view,
                        error: apiError
                    )
                case .createAnonymousMessageSettingClose(let message), .createAnonymousMessageNoMore(let message):
                    UDToast.showFailure(
                        with: message,
                        on: self.view)
                case .targetExternalCoordinateCtl, .externalCoordinateCtl:
                    UDToast.showFailure(
                        with: BundleI18n.LarkThread.Lark_Contacts_CantCompleteOperationNoExternalCommunicationPermission,
                        on: self.view,
                        error: apiError
                    )
                case .cloudDiskFull:
                    let alertController = LarkAlertController()
                    alertController.showCloudDiskFullAlert(from: self, nav: self.viewModel.navigator)
                case .securityControlDeny(let message):
                    self.viewModel.chatSecurityControlService?.authorityErrorHandler(event: .sendFile,
                                                                                    authResult: nil,
                                                                                    from: self,
                                                                                    errorMessage: message)
                case .invalidMedia(_):
                    self.alertService?.showResendAlertFor(error: error,
                                                         message: message,
                                                         fromVC: self)
                    return
                case .strategyControlDeny:
                    return
                default: break
                }
            }
            if let error = error {
                UDToast.showFailure(
                    with: BundleI18n.LarkThread.Lark_Legacy_ErrorMessageTip,
                    on: self.view,
                    error: error
                )
            }
        }).disposed(by: self.disposeBag)

        // 翻译设置变了，需要刷新界面
        viewModel.userGeneralSettings.translateLanguageSettingDriver.skip(1)
            .drive(onNext: { [weak self] (_) in
                // 清空一次标记
                self?.viewModel.translateService.resetMessageCheckStatus(key: self?.viewModel._chat.id ?? "")
                self?.tableView.displayVisibleCells()
            }).disposed(by: self.disposeBag)

        // 自动翻译开关变了，需要刷新界面
        viewModel.chatAutoTranslateSettingDriver.drive(onNext: { [weak self] () in
            // 清空一次标记
            self?.viewModel.translateService.resetMessageCheckStatus(key: self?.viewModel._chat.id ?? "")
            self?.tableView.displayVisibleCells()
        }).disposed(by: self.disposeBag)
        viewModel.offlineThreadUpdateDriver
            .drive(onNext: { [weak self] (thread) in
                //如果显示的最后一条消息小于当前chat的lastVisibleThreadPosition，说明离线期间有离线消息
                if let lastPosition = self?.viewModel.replies.last?.threadPosition,
                    lastPosition < thread.lastVisibleMessagePosition {
                    //尝试加载更多一页消息
                    self?.tableView.loadMoreBottomContent(finish: { [weak self] result in
                        DispatchQueue.main.async {
                            self?.tableView.enableBottomPreload = result.isValid()
                        }
                    })
                }
            }).disposed(by: disposeBag)

        self.viewModel.enableUIOutputDriver.filter({ return $0 })
            .drive(onNext: { [weak self] _ in
                self?.tableView.reloadAndGuarantLastCellVisible(animated: true)
            }).disposed(by: self.disposeBag)

        self.screenProtectService?.observe(screenCaptured: { [weak self] captured in
            if captured {
                self?.setupPlaceholderView()
            } else {
                self?.removePlaceholderView()
            }
        })
        self.screenProtectService?.observeEnterBackground(targetVC: self)

        // 拉取和监听数据
        self.scheduleSendTipView?.fetchAndObserveData()
    }

    /// 添加占位的界面
    private func setupPlaceholderView() {
        /// 收起键盘
        self.view.endEditing(true)
        self.keyboardView?.inputTextView.isEditable = false
        self.navBar.isHidden = true
        /// 显示占位图
        self.view.addSubview((placeholderChatView))
        placeholderChatView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    /// 移除占位的界面
    private func removePlaceholderView() {
        /// 键盘恢复
        self.keyboardView?.inputTextView.isEditable = true
        self.navBar.isHidden = false
        /// 移除占位图
        self.placeholderChatView.removeFromSuperview()
    }

    // 被踢出群或群被解散 时的弹窗提示
    private func alertBeDeletedFromChannel(content: String) {
        let alertController = LarkAlertController()
        alertController.setContent(text: content)
        alertController.addPrimaryButton(text: BundleI18n.LarkThread.Lark_Legacy_LarkConfirm, dismissCompletion: { [weak self] in
            DispatchQueue.main.async {
                self?.popSelf()
            }
        })
        navigator.present(alertController, from: self)
    }

    func refreshForInitMessages(hasHeader: Bool, hasFooter: Bool, scrollType: ReplyInThreadViewModel.ScrollType) {
        self.tableView.hasHeader = hasHeader
        self.tableView.hasFooter = hasFooter
        self.tableView.reloadData()
        switch scrollType {
        case .toLastCell(let position):
            self.tableView.scrollToBottom(animated: false, scrollPosition: position)
        case .toReply(index: let index, section: let section, tableScrollPosition: let position, _):
            self.tableView.scrollToRow(at: IndexPath(row: index, section: section), at: position, animated: false)
        case .toTableBottom:
            self.tableView.scrollsToMaxOffsetY()
        case .toReplySection, .toRoot:
            break
        }
    }

    //刷新，滚动到指定消息
    func refreshForMessages(hasHeader: Bool, hasFooter: Bool, scrollType: ReplyInThreadViewModel.ScrollType) {
        self.tableView.hasHeader = hasHeader
        self.tableView.hasFooter = hasFooter
        self.tableView.reloadData()
        self.scrollTo(scrollType: scrollType)
    }

    func scrollTo(scrollType: ReplyInThreadViewModel.ScrollType) {
        switch scrollType {
        case .toLastCell(let position):
            self.tableView.scrollToBottom(animated: false, scrollPosition: position)
        case .toReply(index: let index, section: let section, tableScrollPosition: let position, _):
            self.tableView.scrollToRow(at: IndexPath(row: index, section: section), at: position, animated: false)
        case .toTableBottom:
            self.tableView.scrollsToMaxOffsetY()
        case .toRoot, .toReplySection:
            break
        }
    }

    //刷新，如果屏幕在最底端，还要滚动一下，保证新消息上屏
    func refreshForNewMessage() {
        if UIApplication.shared.applicationState == .background {
            self.tableView.reloadData()
        } else {
            self.tableView.reloadAndGuarantLastCellVisible(animated: true)
        }
    }
}

extension ReplyInThreadViewController: ChatPageAPI {
    func reloadRows(current: String, others: [String]) {
    }

    var inSelectMode: Observable<Bool> {
        return self.viewModel.inSelectMode.asObservable()
    }

    var selectedMessages: BehaviorRelay<[ChatSelectedMessageContext]> {
        return self.viewModel.pickedMessages
    }

    func startMultiSelect(by messageId: String) {
        self.viewModel.startMultiSelect(by: messageId)
    }

    func endMultiSelect() {
        self.viewModel.finishMultiSelect()
    }

    func toggleSelectedMessage(by messageId: String) {
        self.viewModel.toggleSelectedMessage(by: messageId)
    }
    func originMergeForwardId() -> String? {
        return nil
    }
}

// MARK: - ChatScheduleSendTipViewDelegate
extension ReplyInThreadViewController: ChatScheduleSendTipViewDelegate {
    func setScheduleSendTipView(display: Bool) {
        if display {
            // 如果隐藏需要展示
            if self.scheduleSendTipView?.isHidden == true {
                self.scheduleSendTipView?.isHidden = false
                self.scheduleSendTipView?.snp.remakeConstraints { make in
                    make.left.right.equalToSuperview()
                }
                DispatchQueue.main.async {
                    self.resetTableViewConstraintWhenKeyboardArangViewShow()
                }
            }
        } else {
            if self.scheduleSendTipView?.isHidden == false {
                self.scheduleSendTipView?.isHidden = true
                self.scheduleSendTipView?.snp.remakeConstraints { make in
                    make.left.right.equalToSuperview()
                    make.height.equalTo(0)
                }
                DispatchQueue.main.async {
                    self.resetTableViewConstraintWhenKeyboardArangViewShow()
                }
            }
        }
    }

    func getKeyboardIsDisplay() -> Bool {
        self.keyboardView?.isHidden == false
    }

    func getKeyboardEnable() -> Bool {
        self.keyboardView?.isHidden == false && self.keyboardView?.inputTextView.isUserInteractionEnabled == true && self.viewModel._chat.isAllowPost
    }

    func canHandleScheduleTip(messageItems: [RustPB.Basic_V1_ScheduleMessageItem],
                              entity: RustPB.Basic_V1_Entity) -> Bool {
        self.viewModel.canHandleScheduleTip(messageItems: messageItems, entity: entity)
    }

    func scheduleTipTapped(model: LarkMessageCore.ChatScheduleSendTipTapModel) {
        if model.keyboardEnable {
            IMTracker.Chat.Main.Click.Msg.delayedMsgEdit(self.viewModel._chat)
            let date = Date(timeIntervalSince1970: TimeInterval(model.scheduleTime ?? 0))
            self.keyboardView?.inputViewBecomeFirstResponder()
            let job = KeyboardJob.scheduleMsgEdit(info: KeyboardJob.ReplyInfo(message: model.message,
                                                                               partialReplyInfo: nil),
                                                   time: date,
                                                   type: model.type)
            self.keyboardView?.keyboardStatusManager.switchJob(job)
            self.threadKeyboard?.updateAttributedWith(message: model.message, isInsert: false) { [weak self] in
                if let text = self?.keyboardView?.attributedString {
                    self?.threadKeyboard?.updateAttachmentSizeFor(attributedText: text)
                }
            }
        } else {
            let title = model.status.isFailed ? BundleI18n.LarkThread.Lark_IM_ScheduleMessage_FailedToSendMessage_Text : BundleI18n.LarkThread.Lark_IM_ScheduleMessage_UnableToSendNow_Title
            self.scheduleSendService?.showFailAlert(from: self,
                                                   message: model.message,
                                                   itemType: model.type,
                                                   title: title,
                                                   chat: self.viewModel._chat,
                                                   pasteboardToken: "LARK-PSDA-messenger-replyInThread-scheduleSend-copy-permission")
        }
    }
}

// MARK: - 键盘代理
extension ReplyInThreadViewController: ThreadKeyboardDelegate, ThreadKeyboardViewModelDelegate {
    func getScheduleMsgSendTime() -> Int64? {
        self.scheduleSendTipView?.scheduleMsgSendTime
    }

    func getSendScheduleMsgIds() -> ([String], [String]) {
        guard let view = self.scheduleSendTipView else { return ([], []) }
        return (view.sendSucceedIds, view.deleteIds)
    }

    func getKeyboardStartupState() -> KeyboardStartupState {
        return self.keyboardStartupState
    }

    func jobDidChange(old: KeyboardJob?, new: KeyboardJob) {
        guard self.scheduleSendTipView?.isHidden == false else { return }
        self.scheduleSendTipView?.updateLinkText(isShow: !new.isScheduleMsgEdit)
    }

    func setScheduleTipViewStatus(_ status: ScheduleMessageStatus) {
        switch status {
        case .sendSuccess:
            setScheduleSendTipView(display: true)
        case .delete:
            setScheduleSendTipView(display: false)
        case .updating:
            self.scheduleSendTipView?.configUpdatingStatusModel()
            self.scheduleSendTipView?.updateStatus(.updating)
            setScheduleSendTipView(display: true)
        case .creating:
            self.scheduleSendTipView?.configCreatingStatusModel()
            self.scheduleSendTipView?.updateStatus(.creating)
            setScheduleSendTipView(display: true)
        default:
            assertionFailure()
        }
    }

    func setEditingMessage(message: Message?) {
        self.viewModel.editingMessage = message
    }

    func handleKeyboardAppear() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.viewModel.firstScreenLoaded {
                if let editingMessage = self.viewModel.editingMessage,
                   let index = self.viewModel.findMessageIndexBy(id: editingMessage.id) {
                    self.viewModel.jumpTo(index: index.row, section: index.section, tableScrollPosition: .bottom, needHightlight: false)
                }
            }
        }
    }

    func keyboardFrameChange(frame: CGRect) {
        guard let threadKeyboardView, !lockTableOffset else { return }
        let tableHeight = self.view.frame.height - (self.navBar.frame.minY + self.navBar.frame.height) - threadKeyboardView.frame.height
        let oldHeight = self.tableView.frame.height
        let oldOffsetY = self.tableView.contentOffset.y
        let maxOffset = self.tableView.contentSize.height - tableHeight
        if maxOffset > 0 {
            var newOffsetY = oldOffsetY + (oldHeight - tableHeight)
            if newOffsetY > maxOffset {
                newOffsetY = maxOffset
            }
            self.tableView.contentOffset.y = newOffsetY
        }
    }

    func inputTextViewFrameChange(frame: CGRect) {
    }

    func rootViewController() -> UIViewController {
        return self.navigationController ?? self
    }

    func baseViewController() -> BaseUIViewController {
        return self
    }

    func saveDraft(draft: String, id: DraftId) {
        if case .chat = id {
            assertionFailure("reply in thread errot to save chat draft")
            return
        }
        self.viewModel.save(draft: draft, id: id)
    }

    func cleanPostDraftWith(key: String, id: DraftId) {
        if case .chat = id {
            assertionFailure("reply in thread errot to save chat draft")
            return
        }
        self.viewModel.cleanPostDraftWith(key: key, id: id)
    }

    /// 发文本消息，支持设置匿名
    func defaultInputSendTextMessage(_ content: RustPB.Basic_V1_RichText,
                                     lingoInfo: RustPB.Basic_V1_LingoOption?,
                                     parentMessage: LarkModel.Message?,
                                     scheduleTime: Int64? = nil,
                                     transmitToChat: Bool,
                                     isFullScreen: Bool) {
        let replyMessage = self.getReplyMessage(by: parentMessage)
        self.viewModel.sendText(
            content: content,
            lingoInfo: lingoInfo,
            parentMessage: replyMessage,
            chatId: self.viewModel.chatObserver.value.id,
            isAnonymous: false,
            scheduleTime: scheduleTime,
            transmitToChat: transmitToChat) { [weak self] state in
                self?.trackInputMsgSend(state: state, isFullScreen: isFullScreen, transmitToChat: transmitToChat)
        }
    }

    func defaultInputSendSticker(sticker: RustPB.Im_V1_Sticker, parentMessage: Message?, chat: Chat, stickersCount: Int) {
        let replyMessage = self.getReplyMessage(by: parentMessage)
        self.viewModel.sendSticker(sticker: sticker,
                                   parentMessage: replyMessage,
                                   chat: chat,
                                   isAnonymous: false,
                                   stateHandler: nil)
    }

    /// 发送富文本，支持设置匿名
    func defaultInputSendPost(content: RichTextContent,
                              parentMessage: LarkModel.Message?,
                              scheduleTime: Int64? = nil,
                              transmitToChat: Bool,
                              isFullScreen: Bool) {
        let replyMessage = self.getReplyMessage(by: parentMessage)
        self.viewModel.sendPost(
            title: content.title,
            content: content.richText,
            lingoInfo: content.lingoInfo,
            parentMessage: replyMessage,
            chatId: self.viewModel.chatObserver.value.id,
            isAnonymous: false,
            scheduleTime: scheduleTime,
            transmitToChat: transmitToChat) { [weak self] state in
                self?.trackInputMsgSend(state: state, isFullScreen: isFullScreen, transmitToChat: transmitToChat)
        }
    }

    private func getReplyMessage(by parentMessage: LarkModel.Message?) -> Message {
        //如果有指定回复消息，返回指定回复；如果没有，默认回复根消息
        let message: Message
        if let parentMessage = parentMessage {
            message = parentMessage
        } else {
            message = self.viewModel.rootMessage
        }
        return message
    }

    /// 新版输入框发送消息埋点
    private func trackInputMsgSend(state: SendMessageState, isFullScreen: Bool, transmitToChat: Bool) {
        if case .finishSendMessage(let message, _, _, _, _) = state {
            self.trackReplyThreadClick(.reply, transmitToChat: transmitToChat)
            var useSendBtn = self.keyboardView?.keyboardNewStyleEnable ?? false
            if isFullScreen {
                useSendBtn = true
            }
            IMTracker.Chat.Main.Click.InputMsgSend(self.viewModel._chat,
                                                   message: message,
                                                   isFullScreen: isFullScreen,
                                                   useSendBtn: useSendBtn,
                                                   translateStatus: .none,
                                                   nil,
                                                   self.chatFromWhere)

        }
    }
}

extension ReplyInThreadViewController: UnReadMessagesTipViewDelegate {
    func tipCanShow(tipView: BaseUnReadMessagesTipView) -> Bool {
        guard self.viewModel.firstScreenLoaded else {
            return false
        }
        if self.tableView.hasFooter {
            return true
        } else if self.tableView.stickToBottom() {
            //table自动滚动到底时，不用显示气泡，新消息来了会自动显示
            return false
        }
        return true
    }

    func scrollToBottommostMessage(tipView: BaseUnReadMessagesTipView, finish: @escaping () -> Void) {
        self.viewModel.jumpToLastReply(tableScrollPosition: .top, finish: finish)
    }
}

extension ReplyInThreadViewController: DetailTableDelegate {

    func tapHandler() {
        self.threadKeyboardView?.fold()
    }

    func showTopLoadMore(status: ScrollViewLoadMoreStatus) {
    }

    func showBottomLoadMore(status: ScrollViewLoadMoreStatus) {
    }

    func showMenuForCellVM(cellVM: ThreadDetailCellVMGeneralAbility) {
        if cellVM.message.threadMessageType == .threadReplyMessage {
            cellVM.message.rootMessage = viewModel.rootMessage
        }
    }

    func willDisplay(cell: UITableViewCell, cellVM: ThreadDetailCellViewModel) {
        if let messageCellVM = cellVM as? HasMessage {
            self.viewModel.readService?.putRead(element: messageCellVM.message) { _ in }
            if messageCellVM.message.threadPosition == self.viewModel.highlightPosition {
                (cell as? MessageCommonCell)?.highlightView()
                self.viewModel.highlightPosition = nil
            }
        }
    }
}

extension ReplyInThreadViewController: PageAPI {
    func viewWillEndDisplay() {
        viewModel.uiOutput(enable: false, indentify: "maskByCell")
        self.tableView.endDisplayVisibleCells()
    }

    func viewDidDisplay() {
        viewModel.uiOutput(enable: true, indentify: "maskByCell")
        self.tableView.displayVisibleCells()
    }

    var pageSupportReply: Bool {
        return true
    }

    func insertAt(by chatter: Chatter?) {
        let chat = self.viewModel._chat
        guard let chatter = chatter else {
            return
        }
        var displayName = chatter.name
        if chat.oncallId.isEmpty {
            displayName = chatter.displayName(chatId: chat.id, chatType: chat.type, scene: .atInChatInput)
        }
        self.threadKeyboardView?.insert(userName: displayName,
                                       actualName: chatter.name,
                                       userId: chatter.id,
                                       isOuter: false,
                                       isAnonymous: chatter.isAnonymous)
    }

    func reply(message: Message, partialReplyInfo: PartialReplyInfo?) {
        //目前thread详情页中具体回复的产品逻辑还没想明白，暂时只支持自动插入@xxxx, 仍然是回复根消息
        self.insertAt(by: message.fromChatter)
        self.threadKeyboardView?.inputViewBecomeFirstResponder()
    }

    func reedit(_ message: Message) {
        if viewModel.threadObserver.value.stateInfo.state == .closed {
            UDToast.showFailure(
                with: BundleI18n.LarkThread.Lark_Chat_TopicClosedInputWindowPlaceholder,
                on: self.view
            )
            return
        }
        self.threadKeyboardView?.inputViewBecomeFirstResponder()
        self.threadKeyboard?.reEditMessage(message: message)
    }

    func multiEdit(_ message: Message) {
        guard let threadKeyboard else { return }
        if viewModel.threadObserver.value.stateInfo.state == .closed {
            UDToast.showFailure(
                with: BundleI18n.LarkThread.Lark_Chat_TopicClosedInputWindowPlaceholder,
                on: self.view
            )
            return
        }
        let comfirmToMultiEdit = { (message: Message) in
            threadKeyboard.multiEditMessage(message: message)
            threadKeyboard.keyboardView.inputViewBecomeFirstResponder()
        }
        if !threadKeyboard.keyboardView.keyboardStatusManager.currentKeyboardJob.isMultiEdit {
            comfirmToMultiEdit(message)
        } else {
            let dialog = UDDialog()
            dialog.setTitle(text: BundleI18n.LarkThread.Lark_IM_EditMessage_EditAnotherMessage_Title)
            dialog.setContent(text: BundleI18n.LarkThread.Lark_IM_EditMessage_EditAnotherMessage_Desc)
            dialog.addSecondaryButton(text: BundleI18n.LarkThread.Lark_IM_EditMessage_EditAnotherMessage_GoBack_Button)
            dialog.addDestructiveButton(text: BundleI18n.LarkThread.Lark_IM_EditMessage_EditAnotherMessage_Confirm_Button,
                                        dismissCompletion: {
                comfirmToMultiEdit(message)
            })

            navigator.present(dialog, from: self)
        }
    }

    func getSelectionLabelDelegate() -> LKSelectionLabelDelegate? {
        return self.messageSelectControl
    }
}

extension ReplyInThreadViewController: EnterpriseEntityWordDelegate {

    func lockForShowEnterpriseEntityWordCard() {
        Self.logger.info("ReplyInThreadViewController: pauseQueue for enterprise entity word card show")
        viewModel.pauseQueue()
    }

    func unlockForHideEnterpriseEntityWordCard() {
        Self.logger.info("ReplyInThreadViewController: resumeQueue for after enterprise entity word card hide")
        viewModel.resumeQueue()
    }

}
extension ReplyInThreadViewController {

    private func updateLeftNavigationItems() {
        guard Display.pad else {
            return
        }
        let controller = self.getContainerController() ?? self
        self.navBar.leftItems = []
        /// 在 iPad 分屏场景中
        if let split = self.larkSplitViewController {
            if let navigation = controller.navigationController,
               navigation.realViewControllers.first != controller {
                self.addBackItemForNavBar()
            }
            if !split.isCollapsed {
                let service = try? self.userResolver.resolve(assert: SearchOuterService.self)
                if let searchOutService = service, searchOutService.enableSearchiPadSpliteMode(), self.specificSource == .searchResultMessage {
                    self.navBar.leftViews.append(searchOutService.closeDetailButton(chatID: self.viewModel._chat.id))
                }
                self.navBar.leftViews.append(fullScreenIcon)
                fullScreenIcon.updateIcon()
            }
        } else {
        /// 在 iPad 非左右分屏场景
            if let navigation = self.navigationController {
                if navigation.realViewControllers.first == controller {
                    self.addCloseItemForNavBar()
                } else {
                    self.addBackItemForNavBar()
                }
            }
        }
    }
}

extension ReplyInThreadViewController {
    private func trackReplyThreadClickFromThreadMenuType(_ type: ThreadMenuType) {
        switch type {
        case .subscribe:
            trackReplyThreadClick(.subscribe)
        case .unsubscribe:
            trackReplyThreadClick(.unsubscribe)
        case .muteMsgNotice:
            trackReplyThreadClick(.mute)
        case .msgNotice:
            trackReplyThreadClick(.unmute)
        default:
            break
        }
    }
    private func trackReplyThreadView() {
        let rootMessage = viewModel.rootMessage
        ThreadTracker.trackReplyThreadView(chat: viewModel.chatObserver.value,
                                           message: rootMessage,
                                           msgCount: Int(viewModel.threadObserver.value.replyCount),
                                           threadId: !rootMessage.threadId.isEmpty ? rootMessage.threadId : rootMessage.id,
                                           inGroup: true)
    }

    private func trackReplyThreadClick(_ type: ThreadTracker.ReplyThreadClickType, transmitToChat: Bool = false) {
        let rootMessage = viewModel.rootMessage
        ThreadTracker.trackReplyThreadClick(chat: viewModel.chatObserver.value,
                                            message: rootMessage,
                                            clickType: type,
                                            threadId: !rootMessage.threadId.isEmpty ? rootMessage.threadId : rootMessage.id,
                                            inGroup: true,
                                            transmitToChat: transmitToChat)
    }

    private func trackReplyMsgSend(state: SendMessageState) {
        if case .finishSendMessage(_, _, _, _, _) = state {
            self.trackReplyThreadClick(.reply)
        }
    }
}

extension ReplyInThreadViewController: PlaceholderChatNavigationBarDelegate {
    func backButtonClicked() {
        navigator.pop(from: self)
    }
}
