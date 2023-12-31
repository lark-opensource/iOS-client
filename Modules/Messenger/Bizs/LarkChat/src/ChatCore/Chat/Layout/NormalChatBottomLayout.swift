//
//  NormalChatBottomLayout.swift
//  LarkChat
//
//  Created by ByteDance on 2023/11/13.
//

import Foundation
import LarkContainer
import LarkCore
import LarkMessengerInterface
import UniverseDesignToast
import LKCommonsLogging
import LarkMessageCore
import LarkOpenChat
import RxSwift
import RxCocoa
import LarkModel
import LarkSDKInterface
import LarkRustClient
import LarkBaseKeyboard
import LarkOpenKeyboard
import LarkChatOpenKeyboard
import RustPB
import SnapKit
import EditTextView
import LarkChatKeyboardInterface
import LarkNavigator
import TangramService
import ByteWebImage
import LarkSendMessage
import LarkStorage
import LarkKeyCommandKit
import UIKit
import LarkUIKit
import UniverseDesignDialog
import LarkMessageBase

protocol NormalChatBottomLayoutDelegate: AnyObject {
    var tableHeightLock: Bool { get }
    func keyboardContentHeightWillChange(_ isFold: Bool)
    func handleKeyboardAppear(triggerType: KeyboardAppearTriggerType)
    func removeHightlight(needRefresh: Bool)
    func addDownUnReadMessagesTipView()
    func updateCellViewModel(ids: [String], doUpdate: @escaping (String, ChatCellViewModel) -> Bool)
}

class NormalChatBottomLayout: NSObject, UserResolverWrapper {
    static let logger = Logger.log(NormalChatBottomLayout.self, category: "Module.IM.Message")
    private var componentGenerator: ChatViewControllerComponentGeneratorProtocol
    var chatBottomStatus: ChatBottomStatus = .none(display: true)
    private let chatWrapper: ChatPushWrapper
    private let messagesObservable: Observable<[Message]>
    let userResolver: UserResolver
    let chatFromWhere: ChatFromWhere
    let chatId: String
    private let chatKeyPointTracker: ChatKeyPointTracker
    private let footerContext: LarkOpenChat.ChatFooterContext
    private let pushCenter: PushNotificationCenter
    private let keyBoardTopExtendContext: ChatKeyboardTopExtendContext
    private let tableView: ChatTableView
    private var guideManager: ChatBaseGuideManager?
    /// 定制键盘初始化状态
    private let keyboardStartState: KeyboardStartupState

    @ScopedInjectedLazy private  var scheduleSendService: ScheduleSendService?
    @ScopedInjectedLazy var chatAPI: ChatAPI?
    private let threadModelAddButtonOptimize: Bool

    private var chat: BehaviorRelay<Chat> {
        return self.chatWrapper.chat
    }

    weak var delegate: NormalChatBottomLayoutDelegate?

    private let disposeBag: DisposeBag = DisposeBag()

    private weak var _containerViewController: UIViewController?
    var containerViewController: UIViewController {
        return self._containerViewController ?? UIViewController()
    }

    lazy var chatModeChange: Driver<Bool> = {
        return self.chatWrapper.chat.distinctUntilChanged { chat1, chat2 in
            return chat1.displayInThreadMode == chat2.displayInThreadMode
        }.map { chat in
            return chat.displayInThreadMode
        }.asDriver(onErrorJustReturn: false)
    }()

    lazy var chatIsFrozen: Driver<Void> = {
        return self.chatWrapper.chat.distinctUntilChanged { chat1, chat2 in
            return chat1.isFrozen == chat2.isFrozen
        }
        .filter { $0.isFrozen }
        .map { _ in return }
        .asDriver(onErrorJustReturn: ())
    }()

    private var getMessageSender: () -> MessageSender?
    private let context: ChatModuleContext

    private lazy var myAIInlineService: IMMyAIInlineService? = {
        return try? self.context.chatContext.userResolver.resolve(type: IMMyAIInlineService.self)
    }()

    private var viewDidAppeared = false

    init(userResolver: UserResolver,
         context: ChatModuleContext,
         chatWrapper: ChatPushWrapper,
         messagesObservable: Observable<[LarkModel.Message]>,
         componentGenerator: ChatViewControllerComponentGeneratorProtocol,
         containerViewController: UIViewController,
         chatFromWhere: ChatFromWhere,
         chatKeyPointTracker: ChatKeyPointTracker,
         pushCenter: PushNotificationCenter,
         tableView: ChatTableView,
         delegate: NormalChatBottomLayoutDelegate?,
         guideManager: ChatBaseGuideManager?,
         keyboardStartState: KeyboardStartupState,
         getMessageSender: @escaping () -> MessageSender?) {
        self.componentGenerator = componentGenerator
        self._containerViewController = containerViewController
        self.userResolver = userResolver
        self.chatWrapper = chatWrapper
        self.messagesObservable = messagesObservable
        self.chatFromWhere = chatFromWhere
        self.chatId = chatWrapper.chat.value.id
        self.chatKeyPointTracker = chatKeyPointTracker
        self.context = context
        self.footerContext = context.footerContext
        self.pushCenter = pushCenter
        self.keyBoardTopExtendContext = context.keyBoardTopExtendContext
        self.tableView = tableView
        self.delegate = delegate
        self.threadModelAddButtonOptimize = userResolver.fg.staticFeatureGatingValue(with: "im.message.thread_model_addbutton_optimize")
        self.guideManager = guideManager
        self.keyboardStartState = keyboardStartState
        self.getMessageSender = getMessageSender
    }

    private var _frozenMask: UIView?
    private lazy var frozenMask: UIView? = {
        switch self.chatBottomStatus {
        case .frozenMask:
            if let mask = self._frozenMask {
                return mask
            }
            let mask = self.componentGenerator.createChatFrozenMask()
            if let mask = mask {
                self.containerViewController.view.addSubview(mask)
                mask.snp.makeConstraints { make in
                    make.left.right.bottom.equalToSuperview()
                }
            }
            self._frozenMask = mask
            return mask
        default:
            return nil
        }
    }()

    private var _createThreadPanel: ChatCreateThreadPanel?
    private var createThreadPanel: ChatCreateThreadPanel? {
        switch self.chatBottomStatus {
        case .createThread:
            if let createThreadPanel = self._createThreadPanel {
                return createThreadPanel
            }
            let panel = self.componentGenerator.createThreadPanel(hasChatMenuItem: true,
                                                                  pushWrapper: self.chatWrapper)
            panel?.delegate = self
            panel?.hasChatMenuItem = self.hasMenuItem ?? false
            if let panel = panel {
                self.containerViewController.view.addSubview(panel)
                panel.snp.makeConstraints { make in
                    make.left.right.bottom.equalToSuperview()
                }
            }
            self._createThreadPanel = panel
            return panel
        default:
            return nil
        }
    }

    private var _chatMenuView: ChatMenuBottomView?

    private var hasMenuItemDriver: Driver<Bool>? {
        if let chatMenuView = self._chatMenuView {
            return chatMenuView.hasMenuItemDriver
        }
        let chatMenuView = self.componentGenerator.chatMenu(pushWrapper: self.chatWrapper,
                                                            delegate: self,
                                                            chatVC: self.containerViewController)
        chatMenuView?.chatFromWhere = self.chatFromWhere
        self._chatMenuView = chatMenuView
        return chatMenuView?.hasMenuItemDriver
    }

    var hasMenuItem: Bool? {
        if let chatMenuView = self._chatMenuView {
            return chatMenuView.hasMenuItem
        }
        let chatMenuView = self.componentGenerator.chatMenu(pushWrapper: self.chatWrapper,
                                                            delegate: self, chatVC: self.containerViewController)
        chatMenuView?.chatFromWhere = self.chatFromWhere
        self._chatMenuView = chatMenuView
        return chatMenuView?.hasMenuItem
    }

    private var chatMenuView: ChatMenuBottomView? {
        switch self.chatBottomStatus {
        case .chatMenu:
            let spaceView: ChatMenuBottomView?
            if let chatMenuView = self._chatMenuView {
                spaceView = chatMenuView
            } else {
                spaceView = self.componentGenerator.chatMenu(pushWrapper: self.chatWrapper,
                                                             delegate: self, chatVC: self.containerViewController)
                spaceView?.chatFromWhere = self.chatFromWhere
                self._chatMenuView = spaceView
            }
            if let spaceView = spaceView {
                self.containerViewController.view.addSubview(spaceView)
                spaceView.snp.makeConstraints { make in
                    make.left.right.bottom.equalToSuperview()
                }
            }
            return spaceView
        default:
            return nil
        }
    }

    lazy var footerView: ChatFooterView? = {
        let footer = self.componentGenerator.chatFooter(pushWrapper: self.chatWrapper,
                                                        context: self.footerContext)
        self.footerContext.container.register(ChatOpenFooterService.self) { [weak footer] (_) -> ChatOpenFooterService in
            return footer ?? DefaultChatOpenFooterService()
        }
        return footer
    }()

    private lazy var _messageSender: MessageSender? = {
        return self.getMessageSender()
    }()

    private var messageSender: MessageSender? {
        switch self.chatBottomStatus {
        case .footerView, .none:
            return nil
        default:
            return _messageSender
        }
    }

    private lazy var quasiMsgCreateByNative: Bool = {
        let chat = self.chatWrapper.chat.value
        return chat.anonymousId.isEmpty && !chat.isCrypto
    }()

    /// 键盘区域
    private var _defaultKeyboard: ChatInternalKeyboardService?
    var defaultKeyboard: ChatInternalKeyboardService? {
        switch self.chatBottomStatus {
        case .keyboard:
            if let keyboard = _defaultKeyboard {
                return keyboard
            }
            guard let messageSender = self._messageSender else {
                return nil
            }
            _defaultKeyboard = self.componentGenerator.keyboard(moduleContext: self.context,
                                                                delegate: self,
                                                                chat: self.chat.value,
                                                                messageSender: { return messageSender },
                                                                chatKeyPointTracker: self.chatKeyPointTracker)
            //目前存在键盘上来不存在的情况，手动调用
            _defaultKeyboard?.afterMessagesRender()
            if let keyboardView = _defaultKeyboard?.view {
                keyboardView.keyboardShareDataService.myAIInlineService = self.myAIInlineService
                self.containerViewController.view.addSubview(keyboardView)
                keyboardView.snp.makeConstraints({ make in
                    make.left.right.bottom.equalToSuperview()
                })
                keyboardView.inputTextView.accessibilityIdentifier = "ChatInput"
                keyboardView.inputTextView.setAcceptablePaste(types: [UIImage.self, NSAttributedString.self])
                (keyboardView as? NormalChatKeyboardView)?.showChatMenuEntry(self.hasMenuItem ?? false,
                                                                               animation: false)
            }
            return _defaultKeyboard
        default:
            return nil
        }
    }

    var keyboardView: ChatKeyboardView? {
        return self.defaultKeyboard?.view
    }

    private lazy var canCreateKeyboard: Bool = {
        return self.componentGenerator.canCreateKeyboard(chat: self.chatWrapper.chat.value)
    }()

    /// 定时发送提示
    private lazy var scheduleSendTipView: ChatScheduleSendTipView? = {
        guard let scheduleSendService, scheduleSendService.scheduleSendEnable else { return nil }
        let disableObservable = self.chatWrapper.chat.asObservable().map({ !$0.isAllowPost }).distinctUntilChanged()
        let push = self.pushCenter.observable(for: PushScheduleMessage.self)
        let chatId = self.chatId
        return self.componentGenerator.scheduleSendTipView(chatId: Int64(self.chat.value.id) ?? 0,
                                                           threadId: nil,
                                                           rootId: nil,
                                                           scene: .chatOnly,
                                                           messageObservable: self.messagesObservable,
                                                           sendEnable: self.chatWrapper.chat.value.isAllowPost,
                                                           disableObservable: disableObservable,
                                                           pushObservable: push)
    }()

    /// 对方的状态说明提示视图
    private lazy var statusDisplayView: StatusDisplayView? = {
        let urlPush = self.pushCenter.observable(for: URLPreviewScenePush.self)
        return self.componentGenerator.statusDisplayView(chat: self.chatWrapper.chat,
                                                         chatNameObservable: self.chat.asObservable().compactMap({ $0.displayWithAnotherName }), urlPushObservable: urlPush)
    }()

    /// 键盘上方区域，包含扩展区+timezone等
    private lazy var keyboardTopStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 0.0
        stackView.lu.setBackgroundColor(UIColor.ud.bgBodyOverlay)
        return stackView
    }()

    /// 如果为nil，则不会显示keyboardTopStackView
    private var keyboardTopStackDependView: UIView? {
        switch self.chatBottomStatus {
        case .keyboard:
            return self.keyboardView
        case .createThread:
            return self.createThreadPanel
        case .chatMenu:
            return self.chatMenuView
        case .none, .footerView, .frozenMask:
            return nil
        }
    }

    /// 键盘上方可扩展区域
    private lazy var keyboardTopExtendView: ChatKeyboardTopExtendView? = {
        let view = self.componentGenerator.chatKeyboardTopExtendView(pushWrapper: self.chatWrapper,
                                                                     context: self.keyBoardTopExtendContext,
                                                                     delegate: self)
        self.keyBoardTopExtendContext.container.register(ChatOpenKeyboardTopExtendService.self) { [weak view] (_) -> ChatOpenKeyboardTopExtendService in
            return view ?? DefaultChatOpenKeyboardTopExtendService()
        }
        return view
    }()

    /// 对方的时区提示视图
    private lazy var timezoneView: TimeZoneView? = {
        guard self.chat.value.type == .p2P else { return nil }
        return self.componentGenerator.timezoneView(chatNameObservable: self.chat.asObservable().compactMap({ $0.displayWithAnotherName }))
    }()
    private var displayTimezoneViewTask: (() -> Void)?

    private func saveInputDraft() {
        self.defaultKeyboard?.saveInputViewDraft(isExitChat: true, callback: { [weak self] (draft, _) in
            self?.saveChatDraft(draft: draft)
        })
    }

    /// 获取当前正在回复哪条消息
    var replymessage: Message? {
        return self.defaultKeyboard?.getReplyMessageInfo()?.message
    }

    var editingMessage: Message? {
        didSet {
            if oldValue?.id == editingMessage?.id {
                return
            }
            if let oldValue = oldValue {
                self.delegate?.updateCellViewModel(ids: [oldValue.id], doUpdate: { _, cellVM in
                    (cellVM as? ChatMessageCellViewModel)?.isEditing = false
                    return true
                })
            }
            if let newValue = self.editingMessage {
                self.delegate?.updateCellViewModel(ids: [newValue.id], doUpdate: { _, cellVM in
                    (cellVM as? ChatMessageCellViewModel)?.isEditing = true
                    return true
                })
            }
        }
    }

    func insertRichText(richText: RustPB.Basic_V1_RichText) {
        self.defaultKeyboard?.insertRichText(richText: richText)
        self.keyboardView?.inputTextView.becomeFirstResponder()
    }
}

extension NormalChatBottomLayout: BottomLayout {
    func afterInitView() {
        // 定时发送提示
        self.scheduleSendTipView?.fetchAndObserveData()

        self.chatModeChange.skip(1).drive { [weak self] displayInThreadMode in
            guard let self = self else { return }
            if displayInThreadMode {
                if self.threadModelAddButtonOptimize {
                    // 如果输入框有草稿，则不进行切换
                    if (self.keyboardView?.text ?? "").isEmpty { self.toggleBottomStatusToCreateThreadIfNeeded() }
                } else {
                    self.toggleBottomStatusToCreateThreadIfNeeded()
                }
            } else {
                switch self.chatBottomStatus {
                case .createThread(display: let display):
                    self.toggleBottomStatus(to: .keyboard(display: display), animation: false)
                default:
                    break
                }
            }
        }.disposed(by: self.disposeBag)

        /// 群被冻结
        self.chatIsFrozen
            .drive { [weak self] _ in
                guard let self = self else { return }
                switch self.chatBottomStatus {
                case .keyboard(display: let display), .chatMenu(display: let display), .createThread(display: let display):
                    self.toggleBottomStatus(to: .frozenMask(display: display), animation: false)
                case .none, .footerView, .frozenMask:
                    break
                }
            }.disposed(by: self.disposeBag)
    }

    func setupBottomView() {
        // 是否能创建footer
        if let footer = self.footerView, footer.isDisplay {
            self.containerViewController.view.addSubview(footer)
            // 这里不能设置make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            // 原因是footer的颜色可能和tableView的颜色不一致，这样会造成底部显示不友好，我们应该让footer自己内部去处理这个适配
            footer.snp.makeConstraints { make in
                make.left.right.bottom.equalToSuperview()
            }
            self.chatBottomStatus = .footerView(display: true)
            return
        }
        let chat = self.chat.value
        /// 群是否被冻结
        if chat.isFrozen {
            self.chatBottomStatus = .frozenMask(display: true)
        } else if self.componentGenerator.needDisplayChatMenu(chat: chat) {
            self.chatBottomStatus = .chatMenu(display: true)
        } else if chat.displayInThreadMode, (!self.threadModelAddButtonOptimize || chat.lastDraftId.isEmpty) {
            // 如果有草稿，则不展示"+创建话题"按钮；普通草稿、回复消息、二次编辑、定时发送的草稿都会有lastDraftId
            self.chatBottomStatus = .createThread(display: true)
        } else if self.canCreateKeyboard {
            self.chatBottomStatus = .keyboard(display: true)
        } else {
            self.chatBottomStatus = .none(display: true)
        }
        self.setupKeyboardTopStackView()
    }

    private func setupKeyboardTopStackView() {
        if var timezoneView = self.timezoneView {
            timezoneView.isHidden = true
            timezoneView.targetVC = self.containerViewController
            self.keyboardTopStackView.addArrangedSubview(timezoneView)
            timezoneView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.height.equalTo(NewChatTimezoneView.Config.viewHeight)
            }
        }

        if let scheduleSendTipView = self.scheduleSendTipView {
            self.keyboardTopStackView.addArrangedSubview(scheduleSendTipView)
            scheduleSendTipView.delegate = self
            scheduleSendTipView.isHidden = true
            scheduleSendTipView.preferMaxWidth = self.containerViewController.view.bounds.width
            scheduleSendTipView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
            }
        }

        if let statusDisplayView = self.statusDisplayView {
            statusDisplayView.targetVC = self.containerViewController
            statusDisplayView.delegate = self
            self.keyboardTopStackView.addArrangedSubview(statusDisplayView)
            statusDisplayView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
            }
        }

        if let keyboardTopExtendView = self.keyboardTopExtendView {
            self.keyboardTopStackView.addArrangedSubview(keyboardTopExtendView)
            keyboardTopExtendView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
            }
            keyboardTopExtendView.shouldShow = self.shouldShowKeyboardTopExtend()
        }
        guard let dependView = self.keyboardTopStackDependView else {
            // 目前keyboardTopStackView中部分内容有阴影，需要下方视图先添加上去（上面keyboardTopStackDependView会触发）再添加keyboardTopStackView
            self.containerViewController.view.addSubview(self.keyboardTopStackView)
            self.keyboardTopStackView.isHidden = true
            return
        }
        // 目前keyboardTopStackView中部分内容有阴影，需要下方视图先添加上去（上面keyboardTopStackDependView会触发）再添加keyboardTopStackView
        self.containerViewController.view.addSubview(self.keyboardTopStackView)
        self.keyboardTopStackView.snp.remakeConstraints { make in
            make.bottom.equalTo(dependView.snp.top)
            make.left.right.equalToSuperview()
        }
    }

    func viewWillDisappear(_ animated: Bool) {
        self.saveInputDraft()
        self.keyboardView?.showNewLine = false
        if self.keyboardView?.keyboardPanel.selectIndex == nil,
            self.keyboardView?.keyboardPanel.contentHeight ?? 0 > 0,
           (self.containerViewController.navigationController?.interactivePopGestureRecognizer?.state ?? .possible != .began) {
            self.keyboardView?.fold()
        }
        self.keyboardView?.viewControllerWillDisappear()
    }

    func afterFirstScreenMessagesRender() {
        let chatId = self.chatId
        keyboardTopExtendView?.setupModule()
        if Display.externalKeyboard, self.userResolver.fg.dynamicFeatureGatingValue(with: "ios.display.externalkeyboard") {
            self.keyboardView?.inputViewBecomeFirstResponder()
        }

        if self.timezoneView != nil {
            pushCenter.driver(for: PushChatTimeTipNotify.self)
                .filter({ (push) -> Bool in
                    return push.chatId == chatId
                }).drive(onNext: { [weak self] (notify) in
                    guard let self = self else { return }
                    Self.logger.info("""
                        "timezoneView chatTimeTipNotifyDriver,
                        show:\(notify.status != .end),
                        chatTimezone: \(notify.chatTimezone),
                        myTimezone: \(notify.myTimezone),
                        myTimezoneType= \(notify.myTimezoneType)
                    """)
                    let isShow = notify.status != .end
                    if isShow {
                        if self.scheduleSendTipView?.isHidden == false {
                            self.displayTimezoneViewTask = { [weak self] in
                                self?.displayTimezone(notify: notify, isShow: isShow)
                            }
                        } else {
                            self.displayTimezone(notify: notify, isShow: isShow)
                        }
                    } else {
                        self.displayTimezone(notify: notify, isShow: isShow)
                        self.displayTimezoneViewTask = nil
                    }
                }).disposed(by: disposeBag)
        }

        self.hasMenuItemDriver?
            .distinctUntilChanged()
            .drive(onNext: { [weak self] hasMenuItem in
                guard let self = self else { return }
                if hasMenuItem {
                    switch self.chatBottomStatus {
                    case .none:
                        self.toggleBottomStatus(to: .chatMenu(display: true), animation: false)
                    case .chatMenu, .footerView, .keyboard, .createThread, .frozenMask:
                        break
                    }
                } else {
                    switch self.chatBottomStatus {
                    case .chatMenu:
                        self.toggleBottomStatus(to: .keyboard(display: true), animation: false)
                    case .keyboard, .footerView, .none, .createThread, .frozenMask:
                        break
                    }
                }
                self.createThreadPanel?.hasChatMenuItem = hasMenuItem
                if let keyboardView = self.keyboardView as? NormalChatKeyboardView {
                    if hasMenuItem, keyboardView.keyboardContentIsFold {
                        keyboardView.showChatMenuEntry(true, animation: false)
                        return
                    }
                    keyboardView.showChatMenuEntry(false, animation: false)
                }
            }).disposed(by: self.disposeBag)
    }

    func onTable(refresh: ChatTableRefreshType) {
        switch refresh {
        case .messageSending(_):
            //话题模式下，发送一条话题后切换到"+创建话题"模式
            if self.threadModelAddButtonOptimize {
                self.toggleBottomStatusToCreateThreadIfNeeded()
            }
        default:
            break
        }
    }

    func getBottomHeight() -> CGFloat {
        var bottomHeight: CGFloat = 0
        switch self.chatBottomStatus {
        case .keyboard:
            bottomHeight = (self.keyboardView?.frame.height ?? 0) + self.keyboardTopStackView.bounds.height
        case .chatMenu:
            bottomHeight = (self.chatMenuView?.frame.height ?? 0) + self.keyboardTopStackView.bounds.height
        case .footerView:
            return self.footerView?.frame.height ?? 0
        case .createThread:
            bottomHeight = (self.createThreadPanel?.frame.height ?? 0) + self.keyboardTopStackView.bounds.height
        case .frozenMask:
            bottomHeight = self.frozenMask?.frame.height ?? 0
        case .none:
            break
        }
        return bottomHeight
    }

    func toggleBottomStatus(to: ChatBottomStatus, animation: Bool) {
        Self.logger.info("toggleBottomStatus \(self.chatId) \(self.chatBottomStatus) \(to) \(animation)")
        var to = to
        if case .keyboard(display: let display) = to, !self.canCreateKeyboard {
            Self.logger.info("toggleBottomStatus can not createKeyboard \(self.chatId)")
            to = .none(display: display)
        }

        switch (self.chatBottomStatus, to) {
        case (.chatMenu(display: let display), .keyboard):
            guard let chatMenuView = self.chatMenuView else {
                assertionFailure("can not init chatMenuView")
                return
            }
            self.chatBottomStatus = .keyboard(display: display)
            self.setScheduleSendTipView(display: true)
            guard let keyboardView = self.keyboardView else {
                assertionFailure("can not init keyboardView")
                return
            }
            IMTracker.Chat.ChatMenu.View(self.chat.value, isAppMenu: false)
            self.toggleBottomView(from: chatMenuView, to: keyboardView, animation: animation)
        case (.keyboard(display: let display), .chatMenu):
            self.saveInputDraft()
            guard let keyboardView = self.keyboardView else {
                assertionFailure("can not init keyboardView")
                return
            }
            keyboardView.inputTextView.resignFirstResponder()
            self.chatBottomStatus = .chatMenu(display: display)
            self.setScheduleSendTipView(display: false)
            guard let chatMenuView = self.chatMenuView else {
                assertionFailure("can not init chatMenuView")
                return
            }
            chatMenuView.trackView()
            self.toggleBottomView(from: keyboardView, to: chatMenuView, animation: animation)
        case (.createThread(display: let display), .keyboard):
            guard let createThreadPanel = self.createThreadPanel else {
                assertionFailure("can not init createThreadPanel")
                return
            }
            self.chatBottomStatus = .keyboard(display: display)
            self.setScheduleSendTipView(display: true)
            guard let keyboardView = self.keyboardView else {
                assertionFailure("can not init keyboardView")
                return
            }
            self.toggleBottomView(from: createThreadPanel, to: keyboardView, animation: animation)
        case (.createThread(display: let display), .chatMenu):
            guard let createThreadPanel = self.createThreadPanel else {
                assertionFailure("can not init createThreadPanel")
                return
            }
            self.chatBottomStatus = .chatMenu(display: display)
            self.setScheduleSendTipView(display: false)
            guard let chatMenuView = self.chatMenuView else {
                assertionFailure("can not init chatMenuView")
                return
            }
            self.toggleBottomView(from: createThreadPanel, to: chatMenuView, animation: animation)
        case (.chatMenu(display: let display), .createThread):
            guard let chatMenuView = self.chatMenuView else {
                assertionFailure("can not init chatMenuView")
                return
            }
            self.chatBottomStatus = .createThread(display: display)
            self.setScheduleSendTipView(display: true)
            guard let createThreadPanel = self.createThreadPanel else {
                assertionFailure("can not init createThreadPanel")
                return
            }
            self.toggleBottomView(from: chatMenuView, to: createThreadPanel, animation: animation)
        case (.keyboard(display: let display), .createThread):
            self.saveInputDraft()
            guard let keyboardView = self.keyboardView else {
                assertionFailure("can not init keyboardView")
                return
            }
            keyboardView.inputTextView.resignFirstResponder()
            self.defaultKeyboard?.clearReplyMessage()
            self.chatBottomStatus = .createThread(display: display)
            self.setScheduleSendTipView(display: true)
            guard let createThreadPanel = self.createThreadPanel else {
                assertionFailure("can not init createThreadPanel")
                return
            }
            self.toggleBottomView(from: keyboardView, to: createThreadPanel, animation: animation)
        case (.none(display: let display), .chatMenu):
            self.chatBottomStatus = .chatMenu(display: display)
            guard let chatMenuView = self.chatMenuView else {
                assertionFailure("can not init chatMenuView")
                return
            }
            self.toggleBottomView(from: nil, to: chatMenuView, animation: animation)
        case (.chatMenu(display: let display), .none):
            guard let chatMenuView = self.chatMenuView else {
                assertionFailure("can not init chatMenuView")
                return
            }
            self.chatBottomStatus = .none(display: display)
            self.toggleBottomView(from: chatMenuView, to: nil, animation: animation)
        case (.keyboard(display: let display), .frozenMask):
            guard let keyboardView = self.keyboardView else {
                assertionFailure("can not init keyboardView")
                return
            }
            keyboardView.inputTextView.resignFirstResponder()
            self.chatBottomStatus = .frozenMask(display: display)
            guard let frozenMask = self.frozenMask else {
                assertionFailure("can not init frozenMask")
                return
            }
            self.toggleBottomView(from: keyboardView, to: frozenMask, animation: animation)
        case (.chatMenu(display: let display), .frozenMask):
            guard let chatMenuView = self.chatMenuView else {
                assertionFailure("can not init chatMenuView")
                return
            }
            self.chatBottomStatus = .frozenMask(display: display)
            guard let frozenMask = self.frozenMask else {
                assertionFailure("can not init frozenMask")
                return
            }
            self.toggleBottomView(from: chatMenuView, to: frozenMask, animation: animation)
        case (.createThread(display: let display), .frozenMask):
            guard let createThreadPanel = self.createThreadPanel else {
                assertionFailure("can not init createThreadPanel")
                return
            }
            self.chatBottomStatus = .frozenMask(display: display)
            guard let frozenMask = self.frozenMask else {
                assertionFailure("can not init frozenMask")
                return
            }
            self.toggleBottomView(from: createThreadPanel, to: frozenMask, animation: animation)
        default:
            break
        }
    }

    /// 底部视图切换 UI 处理逻辑
    /// - Parameters:
    ///   - from: 初始视图
    ///   - to: 目标视图
    ///   - animation: 切换是否带动画
    ///   - display: 切换的视图是否正在屏幕上展示
    ///   - shouldShowKeyboardTopExtend: 是否展示键盘上方快捷组件
    func toggleBottomView(from: UIView?, to: UIView?, animation: Bool) {
        let shouldShowKeyboardTopExtend = self.shouldShowKeyboardTopExtend()
        let display = self.chatBottomStatus.display
        let hideKeyboardTopStack: Bool = !display || (self.keyboardTopStackDependView == nil)
        /// 「初始视图」为空
        if from == nil, let to = to {
            self.keyboardTopStackView.snp.remakeConstraints { make in
                make.bottom.equalTo(to.snp.top)
                make.left.right.equalToSuperview()
            }
            to.isHidden = !display
            self.keyboardTopStackView.isHidden = hideKeyboardTopStack
            self.keyboardTopExtendView?.shouldShow = shouldShowKeyboardTopExtend
            if display {
                self.containerViewController.view.layoutIfNeeded()
                let tableHeight = self.containerViewController.view.bounds.height - getBottomHeight()
                self.tableView.remakeConstraints(height: tableHeight, bottom: self.getTableBottomConstraintItem())
                self.delegate?.addDownUnReadMessagesTipView()
            }
            return
        }
        /// 「目标视图」为空
        if let from = from, to == nil {
            from.isHidden = true
            self.keyboardTopStackView.isHidden = hideKeyboardTopStack
            self.keyboardTopExtendView?.shouldShow = shouldShowKeyboardTopExtend
            if display {
                self.containerViewController.view.layoutIfNeeded()
                let tableHeight = self.containerViewController.view.bounds.height - getBottomHeight()
                self.tableView.remakeConstraints(height: tableHeight, bottom: self.getTableBottomConstraintItem())
                self.delegate?.addDownUnReadMessagesTipView()
            }
            return
        }
        /// 从「初始视图」切换到「目标视图」
        guard let from = from, let to = to else { return }
        let originTableHeight = self.tableView.frame.size.height
        let originContentOffsetY = self.tableView.contentOffset.y
        let offsetToBottom = max(self.tableView.contentSize.height - self.tableView.frame.size.height + self.tableView.contentInset.bottom, -self.tableView.contentInset.top) - originContentOffsetY

        self.keyboardTopExtendView?.shouldShow = shouldShowKeyboardTopExtend
        if !display {
            self.keyboardTopStackView.snp.remakeConstraints { make in
                make.bottom.equalTo(to.snp.top)
                make.left.right.equalToSuperview()
            }
            to.isHidden = true
            from.isHidden = true
            self.keyboardTopStackView.isHidden = hideKeyboardTopStack
            return
        }
        self.keyboardTopStackView.isHidden = hideKeyboardTopStack
        if animation {
            to.isHidden = false
            self.containerViewController.view.insertSubview(to, aboveSubview: from)
            self.containerViewController.view.layoutIfNeeded()
            to.transform = CGAffineTransform(translationX: 0, y: to.bounds.height)
            self.tableView.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
            self.containerViewController.view.layoutIfNeeded()
            self.tableView.setContentOffset(CGPoint(x: 0, y: originContentOffsetY), animated: false)
            UIView.animate(withDuration: 0.2) {
                to.transform = .identity
                from.transform = CGAffineTransform(translationX: 0, y: from.bounds.height)
                self.keyboardTopStackView.snp.remakeConstraints { make in
                    make.bottom.equalTo(to.snp.top)
                    make.left.right.equalToSuperview()
                }
                let tableHeight = self.containerViewController.view.bounds.height - self.getBottomHeight()
                self.tableView.remakeConstraints(height: tableHeight, bottom: self.getTableBottomConstraintItem())
                if offsetToBottom <= abs(self.tableView.frame.height - originTableHeight) {
                    self.tableView.scrollToBottom(animated: false)
                }
                self.containerViewController.view.layoutIfNeeded()
            } completion: { _ in
                from.isHidden = true
                from.transform = .identity
            }
            return
        }
        to.isHidden = false
        from.isHidden = true
        self.keyboardTopStackView.snp.remakeConstraints { make in
            make.bottom.equalTo(to.snp.top)
            make.left.right.equalToSuperview()
        }
        self.containerViewController.view.layoutIfNeeded()
        let tableHeight = self.containerViewController.view.bounds.height - getBottomHeight()
        self.tableView.remakeConstraints(height: tableHeight, bottom: self.getTableBottomConstraintItem())
    }

    func getTableBottomConstraintItem() -> SnapKit.ConstraintItem {
        return getBottomControlTopConstraintInView() ?? containerViewController.view.snp.bottom
    }

    // 获取view最底部控件的top约束(如果有)
    func getBottomControlTopConstraintInView() -> SnapKit.ConstraintItem? {
        var result: SnapKit.ConstraintItem?
        switch self.chatBottomStatus {
        case .keyboard, .chatMenu, .createThread:
            result = self.keyboardTopStackView.snp.top
        case .footerView:
            if let footer = self.footerView, footer.isDisplay {
                result = footer.snp.top
            }
        case .frozenMask:
            if let frozenMask = self.frozenMask {
                result = frozenMask.snp.top
            }
        case .none:
            break
        }
        return result
    }

    func toggleShowAndHideBottom(display: Bool) {
        Self.logger.info("toggleShowAndHideBottom \(self.chatId) \(self.chatBottomStatus) \(display)")
        if self.chatBottomStatus.display == display { return }
        switch self.chatBottomStatus {
        case .keyboard(display: let display):
            self.chatBottomStatus = .keyboard(display: !display)
            if display {
                keyboardView?.isHidden = true
                keyboardView?.fold()
                keyboardView?.inputTextView.resignFirstResponder()
                break
            }
            keyboardView?.isHidden = false
        case .chatMenu(display: let display):
            self.chatBottomStatus = .chatMenu(display: !display)
            chatMenuView?.isHidden = display
        case .footerView(display: let display):
            self.chatBottomStatus = .footerView(display: !display)
            self.footerView?.isHidden = display
        case .createThread(display: let display):
            self.chatBottomStatus = .createThread(display: !display)
            self.createThreadPanel?.isHidden = display
        case .frozenMask(display: let display):
            self.chatBottomStatus = .frozenMask(display: !display)
            self.frozenMask?.isHidden = display
        case .none:
            self.chatBottomStatus = .none(display: !display)
        }
        self.keyboardTopStackView.isHidden = !self.chatBottomStatus.display || self.keyboardTopStackDependView == nil
    }

    func pageSupportReply() -> Bool {
        switch self.chatBottomStatus {
        case .footerView, .none:
            return false
        default:
            return true
        }
    }

    func showGuide(key: String) {
        if key == PageContext.GuideKey.typingTranslateOnboarding {
            guideManager?.checkShowGuideIfNeeded(.typingTranslateOnboarding(self.keyboardView))
        }
    }

    func menuWillShow(isSheetMenu: Bool) {
        let beginKeyboardHeight = self.keyboardView?.frame.height ?? 0
        let beginTableViewOffset = self.tableView.contentOffset

        // 出现菜单之前如果键盘弹起
        let needBecomFirstResponder = self.keyboardView?.inputTextView.isFirstResponder ?? false
        var showKeyboard = false
        if needBecomFirstResponder {
            self.keyboardView?.inputTextView.resignFirstResponder()
            showKeyboard = true
        } else if self.keyboardView?.keyboardPanel.contentHeight ?? 0 > 0 {
            self.keyboardView?.foldKeyboard()
            showKeyboard = true
        }
        if showKeyboard, isSheetMenu {
            /// 键盘收起之后 计算高度的差值，调整tableView的高度
            let changeHeight = beginKeyboardHeight - (self.keyboardView?.frame.height ?? 0)
            if changeHeight <= 0 {
                Self.logger.info("MessageSelectControl beginKeyboardHeight:\(beginKeyboardHeight) " +
                                 "keyboardView?.frame.height: \(self.keyboardView?.frame.height) " +
                                 "changeHeight: \(changeHeight)")
            } else {
                let tableHeight = self.tableView.frame.height + changeHeight
                ///lockChatTable 会保证一定可以 updateConstraints height
                self.tableView.snp.updateConstraints { make in
                    make.height.equalTo(tableHeight)
                }
                self.tableView.layoutIfNeeded()
                /// 这个要保证偏移不变，需要设置为原来的offset
                self.tableView.setContentOffset(beginTableViewOffset, animated: false)
            }
        }

        // 如果是因为长按消息弹出菜单导致的键盘收起，不进行切换「话题模式」，如果要切换试了下面两种方式都有问题：
        // 1.切换时toggleBottomStatus传false：会导致bug，菜单弹出时消息内容被顶到很上面去了，屏幕内看不到消息了
        // 2.切换时toggleBottomStatus传true：会导致bug，菜单弹出后，会执行切换「话题模式」，导致表格视图又掉下来了
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(toggleBottomStatusToCreateThreadIfNeeded), object: nil)
    }

    func tapTableHandler() {
        self.keyboardView?.fold()
    }

    func viewWillAppear(_ animated: Bool) {
        self.keyboardView?.showNewLine = true
    }

    func viewDidAppear(_ animated: Bool) {
        if let defaultKeyboard = self.defaultKeyboard, !self.viewDidAppeared {
            if Display.pad {
                self.containerViewController.view.layoutIfNeeded()
            }
            // 设置键盘初始状态
            defaultKeyboard.setupStartupKeyboardState()
        }
        self.keyboardView?.viewControllerDidAppear()

        // 优先检查Onboarding引导
        if self.guideManager?.shouldShowNewOnboardingGuide() ?? false {
            // New onboarding引导
            self.guideManager?.checkShowGuideIfNeeded(.newOnboarding(self.keyboardView))
        }

        // 键盘下方区域进Chat刷新时会频繁移除view，导致引导异常，因此延迟弹出引导
        let showGuideDelay = 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + showGuideDelay) { [weak self] in
            guard let self = self else { return }
            // 定时发送引导
            self.guideManager?.checkShowGuideIfNeeded(.scheduleSendExpandButton(self.chat.value, self.keyboardView))
            self.guideManager?.checkShowGuideIfNeeded(.sendButtonScheduleSend(self.chat.value, self.keyboardView))
        }

        if Display.externalKeyboard, self.userResolver.fg.dynamicFeatureGatingValue(with: "ios.display.externalkeyboard") {
            self.keyboardView?.inputViewBecomeFirstResponder()
        }
        self.viewDidAppeared = true
    }

    func subProviders() -> [KeyCommandProvider] {
        if let keyboardView = self.keyboardView {
            return [keyboardView]
        }
        return []
    }

    func lockForShowEnterpriseEntityWordCard() {
        self.keyboardView?.inputTextView.resignFirstResponder()
    }

    func keepTableOffset() -> Bool {
        if keyboardExpending(),
           (self.replymessage != nil || self.editingMessage != nil) {
            return true
        }
        return false
    }

    func showToBottomTipIfNeeded() -> Bool {
        return !self.keyboardExpending()
    }

    func hasInputViewInFirstResponder() -> Bool {
        return self.keyboardView?.inputTextView.isFirstResponder ?? false
    }

    func keyboardExpending() -> Bool {
        return self.keyboardView?.keyboardPanel.contentHeight ?? 0 > 0
    }

    func screenCaptured(captured: Bool) {
        if captured {
            self.keyboardView?.inputTextView.resignFirstResponder()
        }
    }

    func widgetExpand(expand: Bool) {
        if expand {
            self.keyboardView?.fold()
        }
    }

    private func displayTimezone(notify: PushChatTimeTipNotify, isShow: Bool) {
        // 延迟500ms出现，避免出现太快，动画不自然
        let showDisplayTimezoneViewDelay = 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + showDisplayTimezoneViewDelay) { [weak self] in
            self?.displayTimezoneView(show: isShow,
                                      copyWriting: notify.copyWriting,
                                      chatTimezone: notify.chatTimezone,
                                      myTimezone: notify.myTimezone,
                                      myTimezoneType: notify.myTimezoneType)
        }
    }

    // MARK: timezone tip 出现/消失
    private func displayTimezoneView(show: Bool,
                                     copyWriting: String,
                                     chatTimezone: String,
                                     myTimezone: String,
                                     myTimezoneType: ExternalDisplayTimezoneSettingType) {
        if show {
            self.timezoneView?.updateTipContent(chatTimezoneDesc: copyWriting,
                                                chatTimezone: chatTimezone,
                                                myTimezone: myTimezone,
                                                myTimezoneType: myTimezoneType,
                                                preferredMaxLayoutWidth: self.containerViewController.view.frame.width)
                }
        if self.timezoneView?.isHidden == !show {
            return
        }
        self.timezoneView?.isHidden = !show
        self.statusDisplayView?.updateUIPadding(show)
        self.keyboardTopStackView.layoutIfNeeded()
        self.keyboardTopExtendViewOnRefresh()
    }

    private func shouldShowKeyboardTopExtend() -> Bool {
        switch self.chatBottomStatus {
        case .keyboard, .createThread:
            return true
        case .chatMenu, .footerView, .none, .frozenMask:
            return false
        }
    }

    func canHandleDropInteraction() -> Bool {
        switch self.chatBottomStatus {
        case .none, .footerView:
            return false
        default:
            return self.chat.value.isAllowPost
       }
    }

    func handleTextTypeDropItem(text: String) {
        self.toggleBottomStatus(to: .keyboard(display: true), animation: false)
        guard let keyboard = self.keyboardView else { return }
        keyboard.inputTextView.insertText(text)
        keyboard.inputTextView.becomeFirstResponder()
    }
}

extension NormalChatBottomLayout: ChaMenutKeyboardDelegate {
    func didClickKeyboardButton() {
        self.toggleBottomStatus(to: .keyboard(display: true), animation: true)
    }
}

extension NormalChatBottomLayout: ChatCreateThreadPanelDelegate {
    func createNewThread() {
        if chatWrapper.chat.value.isAllowPost {
            self.toggleBottomStatus(to: .keyboard(display: true), animation: true)
            self.keyboardView?.inputViewBecomeFirstResponder()
            IMTracker.Chat.Main.Click.CreateTopicClick(self.chatWrapper.chat.value, self.chatFromWhere)
        } else {
            UDToast.showFailure(
                with: BundleI18n.LarkChat.Lark_Group_GroupOwnerAdminBannedNewTopics,
                on: self.containerViewController.view
            )
        }
    }

    func showChatMenu() {
        self.toggleBottomStatus(to: .chatMenu(display: true), animation: true)
    }

    /// 切换到"+创建话题"模式
    @objc
    func toggleBottomStatusToCreateThreadIfNeeded() {
        // 话题模式
        guard self.chat.value.displayInThreadMode else { return }
        // 只能从键盘切换，保持和chatModeChange一致的逻辑
        guard case .keyboard(let display) = self.chatBottomStatus else { return }

        self.toggleBottomStatus(to: .createThread(display: display), animation: true)
    }
}

// MARK: - 键盘代理
extension NormalChatBottomLayout: ChatInputKeyboardDelegate {
    func getScheduleMsgSendTime() -> Int64? {
        self.scheduleSendTipView?.scheduleMsgSendTime
    }

    func getSendScheduleMsgIds() -> ([String], [String]) {
        guard let view = self.scheduleSendTipView else { return ([], []) }
        return (view.sendSucceedIds, view.deleteIds)
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

    func clickChatMenuEntry() {
        self.toggleBottomStatus(to: .chatMenu(display: true), animation: true)
    }

    func replaceViewWillChange(_ view: UIView?) {
        if view == nil {
            keyboardTopExtendView?.shouldShow = self.shouldShowKeyboardTopExtend()
        } else {
            keyboardTopExtendView?.shouldShow = false
        }
    }

    func keyboardContentHeightWillChange(_ isFold: Bool) {
        self.delegate?.keyboardContentHeightWillChange(isFold)
        // 键盘收起时，如果没有草稿，并且replaceView是nil，则切换到"+创建话题"模式
        if isFold, (self.keyboardView?.text ?? "").isEmpty, self.threadModelAddButtonOptimize, self.keyboardView?.replaceView == nil {
            // 如果是因为跳转大框导致的键盘收起，会立刻在后续keyboardWillExpand中cancelPreviousPerformRequests，不切换到"+创建话题"模式
            let toggleBottomStatusDelay = 0.05
            self.perform(#selector(toggleBottomStatusToCreateThreadIfNeeded), with: nil, afterDelay: toggleBottomStatusDelay)
        }
        if !isFold {
            (self.keyboardView as? NormalChatKeyboardView)?.showChatMenuEntry(false, animation: true)
            return
        }
        if self.hasMenuItem ?? false {
            (self.keyboardView as? NormalChatKeyboardView)?.showChatMenuEntry(true, animation: true)
            return
        }
        (self.keyboardView as? NormalChatKeyboardView)?.showChatMenuEntry(false, animation: true)
    }

    func onExitReply() {
    }

    func textChange(text: String, textView: LarkEditTextView) {
    }

    func setEditingMessage(message: Message?) {
        self.editingMessage = message
    }

    func handleKeyboardAppear(triggerType: KeyboardAppearTriggerType) {
        self.delegate?.handleKeyboardAppear(triggerType: triggerType)
    }

    func keyboardFrameChanged(frame: CGRect) {
        if self.delegate?.tableHeightLock ?? false { return }
        guard let keyboardView = self.keyboardView,
              case .keyboard(display: true) = self.chatBottomStatus else { return }

        if keyboardView.keyboardPanel.contentHeight == 0 {
            let originHeight = self.tableView.frame.height
            let maxVisibleY = originHeight + self.tableView.contentOffset.y
            let height = self.containerViewController.view.bounds.height - keyboardView.frame.height - self.keyboardTopStackView.bounds.height
            self.tableView.remakeConstraints(height: height, bottom: keyboardView.snp.top, bottomOffset: -self.keyboardTopStackView.bounds.height)
            if maxVisibleY > height {
                // 可见区域没有在底部 或者 TableView 没有被触碰或者滚动时
                // 更新 ContentOffset 修正位置
                // 此次修改是为了适配键盘因为适配 safeArea 高度发生变化
                if maxVisibleY <= self.tableView.contentSize.height ||
                    !(self.tableView.isTracking ||
                    self.tableView.isDragging ||
                    self.tableView.isDecelerating) {
                    self.tableView.setContentOffset(CGPoint(x: 0, y: maxVisibleY - height), animated: false)
                }
            }
        } else {
            let height = self.containerViewController.view.bounds.height - keyboardView.frame.height - self.keyboardTopStackView.bounds.height
            if CGFloat(self.tableView.contentSize.height) <= self.tableView.frame.height {
                self.tableView.remakeConstraints(height: height, bottom: getTableBottomConstraintItem())
                if self.tableView.contentSize.height >= height {
                    self.tableView.setContentOffset(CGPoint(x: 0, y: self.tableView.contentSize.height - height), animated: false)
                }
            } else {
                self.delegate?.removeHightlight(needRefresh: true)
                let originHeight = self.tableView.frame.height
                let heightChange = height - originHeight
                self.tableView.remakeConstraints(height: height, bottom: getTableBottomConstraintItem())
                if !self.tableView.stickToBottom() {
                    self.tableView.setContentOffset(CGPoint(x: 0, y: self.tableView.contentOffset.y - heightChange), animated: false)
                }
            }
        }
    }

    func inputTextViewFrameChanged(frame: CGRect) {
        if frame.height > 60 {
            self.guideManager?.checkShowGuideIfNeeded(.postHint(self.keyboardView))
        }
    }

    func inputTextViewWillInput(image: UIImage) -> Bool {
        let alert = ImageInputHandler.createSendAlert(userResolver: userResolver, with: image, for: chat.value, confirmCompletion: { [weak self] in
            guard let self = self else { return }
            let imageMessageInfo = generateSendImageMessageInfoInChat(image)
            self.messageSender?.sendImages(
                parentMessage: nil,
                useOriginal: false,
                imageMessageInfos: [imageMessageInfo],
                chatId: self.chat.value.id,
                lastMessagePosition: self.chat.value.lastMessagePosition,
                quasiMsgCreateByNative: self.quasiMsgCreateByNative,
                extraTrackerContext: [ChatKeyPointTracker.selectAssetsCount: 1,
                                      ChatKeyPointTracker.chooseAssetSource: ChatKeyPointTracker.ChooseAssetSource.other.rawValue]
            )
        })
        self.userResolver.navigator.present(alert, from: self.containerViewController)
        return false
    }

    func rootViewController() -> UIViewController {
        return self.containerViewController.navigationController ?? self.containerViewController
    }

    func baseViewController() -> UIViewController {
        return self.containerViewController
    }

    func keyboardWillExpand() {
        self.guideManager?.removeHintBubbleView()
        // 如果是因为跳转大框导致的键盘收起，则不切换到"+创建话题"模式
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(toggleBottomStatusToCreateThreadIfNeeded), object: nil)
    }

    func getKeyboardStartupState() -> KeyboardStartupState {
        return self.keyboardStartState
    }

    func keyboardCanAutoBecomeFirstResponder() -> Bool {
        switch self.chatBottomStatus {
        case .keyboard:
            return true
        default:
            return false
        }
    }
}

// MARK: - ChatScheduleSendTipViewDelegate
extension NormalChatBottomLayout: ChatScheduleSendTipViewDelegate {
    func setScheduleSendTipView(display: Bool) {
        guard self.scheduleSendTipView?.superview != nil else { return }
        if display, self.scheduleSendTipView?.needDisplay == true {
            // 如果隐藏需要展示
            if self.scheduleSendTipView?.isHidden == true {
                self.scheduleSendTipView?.isHidden = false
                self.scheduleSendTipView?.snp.remakeConstraints { make in
                    make.left.right.equalToSuperview()
                }
                // 定时消息显示，隐藏时区
                if self.timezoneView?.isHidden == false {
                    self.timezoneView?.isHidden = true
                    // 恢复时区显示的任务
                    self.displayTimezoneViewTask = { [weak self] in
                        self?.timezoneView?.isHidden = false
                        self?.keyboardTopStackView.layoutIfNeeded()
                        self?.keyboardTopExtendViewOnRefresh()
                    }
                }
                DispatchQueue.main.async {
                    self.keyboardTopExtendViewOnRefresh()
                }
            }
        } else {
            if self.scheduleSendTipView?.isHidden == false {
                self.scheduleSendTipView?.isHidden = true
                self.scheduleSendTipView?.snp.remakeConstraints { make in
                    make.left.right.equalToSuperview()
                    make.height.equalTo(0)
                }
                // 恢复时区显示
                self.displayTimezoneViewTask?()
                DispatchQueue.main.async {
                    self.keyboardTopExtendViewOnRefresh()
                }
            }
        }
    }

    func getKeyboardIsDisplay() -> Bool {
        switch self.chatBottomStatus {
        case .keyboard(display: let display), .createThread(display: let display):
            return display
        default:
            return false
        }
    }

    func getKeyboardEnable() -> Bool {
        self.keyboardView?.isHidden == false && self.keyboardView?.inputTextView.isUserInteractionEnabled == true && self.chat.value.isAllowPost
    }

    func canHandleScheduleTip(messageItems: [RustPB.Basic_V1_ScheduleMessageItem],
                              entity: RustPB.Basic_V1_Entity) -> Bool {
        guard let itemId = messageItems.first?.itemID else {
            return false
        }
        // replyInThread的push不响应
        if let message = entity.messages[itemId] {
            if message.threadMessageType != .unknownThreadMessage {
                return false
            }
            return message.channel.id == self.chatId
        } else if let quasi = entity.quasiMessages[itemId] {
            if quasi.threadID.isEmpty == false {
                return false
            }
            return quasi.channel.id == self.chatId
        }
        return true
    }

    func scheduleTipTapped(model: LarkMessageCore.ChatScheduleSendTipTapModel) {
        if model.keyboardEnable {
            IMTracker.Chat.Main.Click.Msg.delayedMsgEdit(self.chat.value)
            let date = Date(timeIntervalSince1970: TimeInterval(model.scheduleTime ?? 0))
            self.keyboardView?.inputViewBecomeFirstResponder()
            let info = KeyboardJob.ReplyInfo(message: model.message, partialReplyInfo: model.message.partialReplyInfo)
            self.keyboardView?.keyboardStatusManager.switchJob(.scheduleMsgEdit(info: info, time: date, type: model.type))
            self.defaultKeyboard?.updateAttributedString(message: model.message, isInsert: false) { [weak self] in
                if let inputTextView = self?.keyboardView?.inputTextView {
                    self?.defaultKeyboard?.updateAttachmentSizeFor(attributedText: inputTextView.attributedText)
                }
            }
        } else {
            let title = model.status.isFailed ? BundleI18n.LarkChat.Lark_IM_ScheduleMessage_FailedToSendMessage_Text : BundleI18n.LarkChat.Lark_IM_ScheduleMessage_UnableToSendNow_Title
            self.scheduleSendService?.showFailAlert(from: self.containerViewController,
                                                   message: model.message,
                                                   itemType: model.type,
                                                   title: title,
                                                    chat: self.chat.value,
                                                   pasteboardToken: "LARK-PSDA-messenger-chat-scheduleSend-copy-permission")
        }
    }
}

extension NormalChatBottomLayout: ChatKeyboardTopExtendViewDelegate {
    func keyboardTopExtendViewOnRefresh() {
        let currentTableHeight = self.tableView.frame.height
        self.containerViewController.view.layoutIfNeeded()
        let height = self.containerViewController.view.bounds.height - getBottomHeight()
        var offset = currentTableHeight - height
        if offset <= 0 {
            offset = 0
        }
        self.remakeTableConstrainWithHeight(height: height,
                                            offsetHeight: offset,
                                            animated: true)
    }

    private func remakeTableConstrainWithHeight(height: ConstraintRelatableTarget,
                                                offsetHeight: CGFloat,
                                                animated: Bool = false) {
        self.tableView.remakeConstraints(height: height, bottom: self.getTableBottomConstraintItem())

        let totalHeight = self.tableView.adjustedContentInset.top + self.tableView.adjustedContentInset.bottom + self.tableView.contentSize.height
        let completeShow = (totalHeight <= self.tableView.frame.size.height)
        if completeShow {
            self.tableView.scrollToBottom(animated: animated)
        } else {
            self.tableView.setContentOffset(CGPoint(x: 0, y: self.tableView.contentOffset.y + offsetHeight), animated: animated)
        }
    }
}

extension NormalChatBottomLayout: StatusDisplayViewDelegate {
    func statusDisplayViewOnShowAndHide() {
        self.keyboardTopExtendViewOnRefresh()
    }
}

extension NormalChatBottomLayout: SaveChatDraft {
}

extension NormalChatBottomLayout {
    func insertAt(by chatter: Chatter?) {
        self.toggleBottomStatus(to: .keyboard(display: true), animation: false)
        guard let chatter = chatter else { return }

        let chat = self.chat.value
        var displayName = chatter.name
        if chat.oncallId.isEmpty {
            displayName = chatter.displayName(chatId: chat.id, chatType: chat.type, scene: .atInChatInput)
        }
        self.keyboardView?.insert(userName: displayName, actualName: chatter.localizedName, userId: chatter.id)
    }

    func reply(message: Message, partialReplyInfo: PartialReplyInfo?) {
        self.toggleBottomStatus(to: .keyboard(display: true), animation: false)
        self.defaultKeyboard?.setReplyMessage(message: message, replyInfo: partialReplyInfo)
        self.keyboardView?.inputViewBecomeFirstResponder()
    }

    func reedit(_ message: Message) {
        self.toggleBottomStatus(to: .keyboard(display: true), animation: false)
        self.keyboardView?.inputViewBecomeFirstResponder()
        self.defaultKeyboard?.reEditMessage(message: message)
    }

    func multiEdit(message: Message) {
        self.toggleBottomStatus(to: .keyboard(display: true), animation: false)
        self.defaultKeyboard?.actionAfterKeyboardInitDraftFinish { [weak self] in
            self?.didMultiEditWith(editingMessage: self?.editingMessage, message: message)
        }
    }

    private func didMultiEditWith(editingMessage: Message?, message: Message) {
        let comfirmToMultiEdit = { [weak self] (message: Message) in
            self?.defaultKeyboard?.multiEditMessage(message: message)
            self?.keyboardView?.inputViewBecomeFirstResponder()
        }
        let chat = self.chat.value
        if editingMessage?.id == message.id {
            //重复选择 二次编辑当前消息，不执行任何动作
            return
        }
        if  editingMessage == nil,
            (chat.editMessageDraftId.isEmpty ||
            chat.editMessageDraftId == message.editDraftId) {
            comfirmToMultiEdit(message)
        } else {
            //有正在二次编辑的草稿
            let dialog = UDDialog()
            dialog.setTitle(text: BundleI18n.LarkChat.Lark_IM_EditMessage_EditAnotherMessage_Title)
            dialog.setContent(text: BundleI18n.LarkChat.Lark_IM_EditMessage_EditAnotherMessage_Desc)
            dialog.addSecondaryButton(text: BundleI18n.LarkChat.Lark_IM_EditMessage_EditAnotherMessage_GoBack_Button,
                                      dismissCompletion: { [weak self] in
                if editingMessage != nil {
                    //有正在编辑的内容，点击“返回”则不做任何动作
                    return
                }
                //有二次编辑草稿，但不是正在编辑的内容，点击“返回”则跳转到编辑 草稿所对应的message
                self?.defaultKeyboard?.getDraftMessageBy(lastDraftId: chat.editMessageDraftId, callback: { draftId, draftMessage, _ in
                    guard case .multiEditMessage = draftId,
                          let draftMessage = draftMessage else { return }
                    comfirmToMultiEdit(draftMessage)
                })
            })
            dialog.addDestructiveButton(text: BundleI18n.LarkChat.Lark_IM_EditMessage_EditAnotherMessage_Confirm_Button,
                                        dismissCompletion: { [weak self] in
                if !chat.editMessageDraftId.isEmpty {
                    //有二次编辑草稿，用户确认转而编辑新的内容，则把旧草稿清空
                    self?.defaultKeyboard?.getDraftMessageBy(lastDraftId: chat.editMessageDraftId, callback: { [weak self] draftId, draftMessage, _ in
                        guard case .multiEditMessage = draftId,
                              let draftMessage = draftMessage else { return }
                        self?.defaultKeyboard?.save(draft: "",
                                                             id: .multiEditMessage(messageId: draftMessage.id, chatId: chat.id),
                                                             type: .editMessage,
                                                             callback: nil)
                    })
                }
                comfirmToMultiEdit(message)
            })
            navigator.present(dialog, from: self.containerViewController)
        }
    }
}
