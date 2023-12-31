//
//  MessageDetailViewController.swift
//  Action
//
//  Created by 赵冬 on 2019/7/24.
//

import UIKit
import Foundation
import WebKit
import RxSwift
import RxCocoa
import Photos
import LarkUIKit
import Kingfisher
import LarkModel
import LarkContainer
import LarkFoundation
import LarkCore
import LarkKeyboardView
import LKCommonsLogging
import LKCommonsTracker
import Swinject
import SnapKit
import EENavigator
import LarkMessageCore
import UniverseDesignToast
import LarkMessageBase
import LarkMessengerInterface
import LarkKeyCommandKit
import LarkInteraction
import LarkSDKInterface
import LarkFeatureGating
import EditTextView
import LarkAppConfig
import LarkAI
import LarkSafety
import LarkSplitViewController
import RustPB
import RichLabel
import UniverseDesignColor
import ByteWebImage
import UniverseDesignDialog
import LarkOpenChat
import LarkChatOpenKeyboard
import LarkSendMessage
import LarkChatKeyboardInterface

final class MessageDetailViewController: BaseUIViewController, UserResolverWrapper {
    var userResolver: UserResolver { chatViewModel.userResolver }
    var chat: BehaviorRelay<Chat> {
        return self.chatViewModel.chatWrapper.chat
    }

    private(set) var tableView: MessageDetailTableView!

    static let logger = Logger.log(MessageDetailViewController.self, category: "Module.IM.MessageDetail")

    var tableHeightLock: Bool = false // 用于在menu 出现的时候 锁住 table 约束

    private let moduleContext: MessageDetailModuleContext
    private let fromSource: MessageDetailFromSource
    let chatFromWhere: ChatFromWhere

    //处理消息相关逻辑
    let chatMessagesViewModel: MessageDetailMessagesViewModel
    //处理会话相关逻辑
    let chatViewModel: MessageDetailViewModel

    private var waterMarkImageView: UIView?

    private let disposeBag = DisposeBag()

    private var defaultKeyboard: ChatInternalKeyboardService?
    var keyboardView: ChatKeyboardView? {
        return self.defaultKeyboard?.view
    }

    var getWaterMark: (LarkModel.Chat) -> Observable<UIView?>

    // 离职视图
    private var chatterResignChatMask: ChatterResignChatMask?

    private var messageSelectControl: MessageSelectControl?

    // 联系人相关的生命周期
    private var contactOptDisposeBag = DisposeBag()

    @ScopedInjectedLazy private var scheduleSendService: ScheduleSendService?
    @ScopedInjectedLazy private var chatDurationStatusTrackService: ChatDurationStatusTrackService?

    /// 定时发送提示
    private lazy var scheduleSendTipView: ChatScheduleSendTipView? = {
        guard scheduleSendService?.scheduleSendEnable == true else { return nil }
        let chat = self.chatViewModel.chat
        if chat.isPrivateMode || chat.isCrypto { return nil }
        let disableObservable = self.chatViewModel.chatWrapper.chat.asObservable().map({ !$0.isAllowPost }).distinctUntilChanged()
        let push = self.chatViewModel.pushScheduleMessage
        let vm = ChatScheduleSendTipViewModel(chatId: Int64(self.chat.value.id) ?? 0,
                                              threadId: nil,
                                              rootId: Int64(self.chatMessagesViewModel.rootMessageId) ?? 0,
                                              scene: .chatThread,
                                              messageObservable: .empty(),
                                              sendEnable: chat.isAllowPost,
                                              disableObservable: disableObservable,
                                              pushObservable: push,
                                              userResolver: self.userResolver)
        return ChatScheduleSendTipView(viewModel: vm)
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

    /// 此方法依赖keyboardTopStackView进行过layout，如果出现问题可以以此排查
    var keyboardTopStackHeight: CGFloat {
        // 某些机型下，当键盘上方区域没有任何子视图展示时，在进群时机系统返回bounds.height会遇到不正确的问题
        if self.scheduleSendTipView?.isHidden ?? true {
            return 0
        }
        return self.keyboardTopStackView.bounds.height
    }

    private var afterMessagesRenderCalled: Bool = false {
        didSet {
            guard oldValue == false else { return }
            self.afterMessagesRender()
            Self.logger.info("messageDetail finishAfterMessagesRender")
        }
    }

    private func afterMessagesRender() {
        //监听截屏事件，打log
        NotificationCenter.default.rx.notification(UIApplication.userDidTakeScreenshotNotification)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self, self.viewIfLoaded?.window != nil else { return }
                let renderCellViewModels = self.chatMessagesViewModel.messageDatasource.renderCellViewModels
                let visibleViewModels = (self.tableView.indexPathsForVisibleRows ?? [])
                    .map { renderCellViewModels[$0.section][$0.row] }
                let messages: [[String: String]] = visibleViewModels
                    .compactMap { (vm: MessageDetailCellViewModel) -> Message? in (vm as? HasMessage)?.message }
                    .map { (message: Message) -> [String: String]  in
                        ["id": "\(message.id)",
                         "cid": "\(message.cid)",
                         "type": "\(message.type)",
                         "position": "\(message.position)",
                         "read_count": "\(message.readCount)",
                         "un_read_count": "\(message.unreadCount)",
                         "message_length": "\(self.chatViewModel.modelService?.messageSummerize(message).count ?? 0)"]
                    }
                let jsonEncoder = JSONEncoder()
                jsonEncoder.outputFormatting = .sortedKeys
                let data = (try? jsonEncoder.encode(messages)) ?? Data()
                let jsonStr = String(data: data, encoding: .utf8) ?? ""
                Self.logger.info("user screenshot accompanying infos:" + "channel_id: \(self.chat.value.id), messages: \(jsonStr)")
            })
            .disposed(by: disposeBag)

        if Display.externalKeyboard, self.userResolver.fg.dynamicFeatureGatingValue(with: "ios.display.externalkeyboard") {
            self.keyboardView?.inputViewBecomeFirstResponder()
        }
    }

    private func setupKeyboardTopStackView() {
        guard let keyboardView = self.keyboardView else {
            return
        }
        self.view.addSubview(self.keyboardTopStackView)
        self.keyboardTopStackView.snp.makeConstraints { make in
            make.bottom.equalTo(keyboardView.snp.top)
            make.left.right.equalToSuperview()
        }

        // 时区
        if var scheduleSendTipView = self.scheduleSendTipView {
            self.keyboardTopStackView.addArrangedSubview(scheduleSendTipView)
            scheduleSendTipView.delegate = self
            scheduleSendTipView.preferMaxWidth = self.view.bounds.width
            scheduleSendTipView.isHidden = true
            scheduleSendTipView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
            }
        }
    }

    private func remakeTableLayoutWhenKeyboardHidden(barHeight: CGFloat) {
        let height = self.view.bounds.height - CGFloat(barHeight)
        self.tableView.remakeConstraints(height: height, bottom: view.snp.bottom, bottomOffset: -barHeight)
    }

    private func remakeTableLayoutWhenKeyboardShow() {
        self.tableView.remakeConstraints(height: self.getTableViewHeight(), bottom: self.getTableBottomConstraintItem())
    }

    var tableViewTopMargin: CGFloat {
        return 0
    }

    /// 密聊录屏保护时占位的界面
    private lazy var placeholderChatView: PlaceholderChatView? = {
        let placeholderChatView = componentGenerator.placeholderChatView()
        placeholderChatView?.setNavigationBarDelegate(self)
        return placeholderChatView
    }()

    /// chat 拖拽交互工具
    private lazy var interactionKit: ChatInteractionKit = {
        let kit = ChatInteractionKit(userResolver: userResolver)
        kit.delegate = self
        return kit
    }()

    private let componentGenerator: MessageDetailViewControllerComponentGeneratorProtocol

    init(
        moduleContext: MessageDetailModuleContext,
        chatViewModel: MessageDetailViewModel,
        chatMessagesViewModel: MessageDetailMessagesViewModel,
        componentGenerator: MessageDetailViewControllerComponentGeneratorProtocol,
        fromSource: MessageDetailFromSource,
        getWaterMark: @escaping (LarkModel.Chat) -> Observable<UIView?>,
        chatFromWhere: ChatFromWhere
    ) {
        self.moduleContext = moduleContext
        self.chatViewModel = chatViewModel
        self.chatMessagesViewModel = chatMessagesViewModel
        self.componentGenerator = componentGenerator
        self.getWaterMark = getWaterMark
        self.fromSource = fromSource
        self.chatFromWhere = chatFromWhere
        super.init(nibName: nil, bundle: nil)
        componentGenerator.pageContainerRegister(pushWrapper: chatViewModel.chatWrapper, context: moduleContext.messageDetailContext)
        self.moduleContext.messageDetailContext.pageContainer.pageInit()
        self.initTableView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.componentGenerator.fileDecodeService?.clean(force: true)
        NotificationCenter.default.removeObserver(self)
        print("MessageDetailVC deinit")
        self.moduleContext.messageDetailContext.pageContainer.pageDeinit()
    }

    override var navigationBarStyle: LarkUIKit.NavigationBarStyle {
        return .custom(UIColor.ud.bgBody)
    }

    override func subProviders() -> [KeyCommandProvider] {
        var providers: [KeyCommandProvider] = [self.tableView]
        if let keyboardView = self.keyboardView {
            providers.append(keyboardView)
        }
        return providers
    }

    private func initTableView() {
        self.tableView = MessageDetailTableView(viewModel: self.chatMessagesViewModel, chatFromWhere: self.chatFromWhere)
        self.tableView.detailTableDelegate = self

        if Display.pad {
            /// 添加 drop 手势
            self.addInterface(in: tableView)
            /// 添加 drag 手势
            let dragManager = moduleContext.messageDetailContext.dragManager
            let drag = UIDragInteraction(delegate: dragManager)
            self.tableView.addInteraction(drag)
            dragManager.addLifeCycle { [weak self] (info) in
                guard let self = self else { return }
                if info.type == .willLift {
                    let location = info.session.location(in: self.tableView)
                    self.tableView.longPressGesture.isEnabled = false
                    self.tableView.longPressGesture.isEnabled = true
                    DispatchQueue.main.async {
                        self.tableView.showMenuIfNeeded(location: location, triggerByDrag: true)
                    }
                } else if info.type == .willBegin {
                    self.messageSelectControl?.dismissMenuIfNeeded()
                }
            }
        }
    }

    /// 添加全局拖拽手势
    private func addInterface(in table: UITableView) {
        guard Display.pad else { return }
        let drop = self.interactionKit
            .createDropInteraction(
                itemTypes: ChatInteractionKit.messageDetailSupportTypes
        )
        table.addLKInteraction(drop)
    }

    private lazy var screenProtectService: ChatScreenProtectService? = {
        return self.moduleContext.messageDetailContext.pageContainer.resolve(ChatScreenProtectService.self)
    }()

    private lazy var imageSendService: KeyboardPictureItemSendService? = {
        return try? self.moduleContext.userResolver.resolve(type: KeyboardPictureItemSendService.self)
    }()

    // swiftlint:disable all
    override func loadView() {
        super.loadView()
        if #available(iOS 13.0, *) {
            self.screenProtectService?.setSecureView(targetVC: self)
        }
    }
    // swiftlint:enable all

    override func viewDidLoad() {
        super.viewDidLoad()

        self.supportSecondaryOnly = true
        self.supportSecondaryPanGesture = true
        self.keyCommandToFullScreen = true
        self.autoAddSecondaryOnlyItem = true
        self.supportSecondaryOnlyButton = true
        self.fullScreenSceneBlock = { "chat_history" }
        self.view.backgroundColor = UIColor.ud.bgBody & UIColor.ud.bgBase
        self.title = BundleI18n.LarkChat.Lark_Legacy_Thread
        self.getWaterMark(self.chatViewModel.chat)
            .compactMap { $0 }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (waterMarkImageView) in
                guard let `self` = self else { return }
                self.waterMarkImageView?.removeFromSuperview()
                self.waterMarkImageView = waterMarkImageView
                self.waterMarkImageView?.contentMode = .top
                self.view.insertSubview(waterMarkImageView, at: 0)
                waterMarkImageView.snp.makeConstraints { (make) in
                    make.left.top.right.equalToSuperview()
                    make.bottom.equalTo(self.viewBottomConstraint)
                }
            }).disposed(by: self.disposeBag)
        self.setupView()
        // 注册消息菜单
        self.componentGenerator.messageActionServiceRegister(pushWrapper: self.chatViewModel.chatWrapper, moduleContext: moduleContext)
        self.moduleContext.container.register(ChatMessagesOpenService.self) { [weak self] _ -> ChatMessagesOpenService in
            return self ?? DefaultChatMessagesOpenService()
        }
        // 视图初始化后立即赋值，如果在监听之后用到，会因为立即来了数据push，导致crash
        self.chatMessagesViewModel.hostUIConfig = HostUIConfig(
            size: navigationController?.view.bounds.size ?? view.bounds.size,
            safeAreaInsets: navigationController?.view.safeAreaInsets ?? view.safeAreaInsets
        )
        self.obeserverChatViewModel()
        self.messageSelectControl = self.componentGenerator.messageSelectControl(chat: self)
        self.messageSelectControl?.addMessageSelectObserver()
        self.messageSelectControl?.menuService = self.moduleContext.messageDetailContext.pageContainer.resolve(MessageMenuOpenService.self)
        self.observerchatMessagesViewModel()
        self.moduleContext.messageDetailContext.pageContainer.beforeFetchFirstScreenMessages()
        self.chatMessagesViewModel.initMessages()
        self.moduleContext.messageDetailContext.pageContainer.pageViewDidLoad()

        MessageDetailApprecibleTrack.firstRenderCostTrack()

        chatDurationStatusTrackService?.setGetChatBlock { [weak self] in
            return self?.chat.value
        }
        ChatTracker.trackMsgDetailView(message: chatMessagesViewModel.rootMessage,
                                     chat: chatViewModel.chat,
                                     from_source: fromSource)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] (_) in
            self?.updateTableConstraints()
            }, completion: nil)
        self.messageSelectControl?.dismissMenuIfNeeded()
    }

    private func resizeVMIfNeeded() {
        let size = view.bounds.size
        if size != chatMessagesViewModel.hostUIConfig.size {
            let needOnResize = size.width != chatMessagesViewModel.hostUIConfig.size.width
            chatMessagesViewModel.hostUIConfig.size = size
            let fg = self.userResolver.fg.dynamicFeatureGatingValue(with: "im.message.resize_if_need_by_width")
            if fg {
                // 仅宽度更新才刷新cell，因为部分机型系统下(iphone8 iOS15、不排除其他系统也存在相同问题)存在非预期回调，比如当唤起大图查看器时，系统回调了该函数，且给的高度不对
                /*1. cell渲染只依赖宽度 2. 目前正常情况下不存在只变高，不变宽的情况（转屏、ipad拖拽）
                 */
                if needOnResize {
                    chatMessagesViewModel.onResize()
                }
            } else {
                chatMessagesViewModel.onResize()
            }
        }
    }

    private func updateTableConstraints() {
        self.tableView.snp.remakeConstraints({ make in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.tableViewTopMargin)
            make.bottom.equalTo(getTableBottomConstraintItem())
        })
    }

    /// 添加占位的界面
    private func setupPlaceholderView() {
        /// 收起键盘
        self.view.endEditing(true)
        self.keyboardView?.inputTextView.isEditable = false
        /// 隐藏系统导航栏
        self.isNavigationBarHidden = true
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        /// 显示占位图
        if let placeholderChatView = self.placeholderChatView {
            self.view.addSubview(placeholderChatView)
            placeholderChatView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
    }

    /// 移除占位的界面
    private func removePlaceholderView() {
        /// 键盘恢复
        self.keyboardView?.inputTextView.isEditable = true
        /// 显示系统导航栏
        self.isNavigationBarHidden = false
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        /// 移除占位图
        self.placeholderChatView?.removeFromSuperview()
        self.resetTableViewConstraint(isImmediatelyLayout: false)
    }

    private func obeserverChatViewModel() {
        /// 翻译设置变了，需要刷新界面
        chatViewModel.userGeneralSettings.translateLanguageSettingDriver.skip(1)
            .drive(onNext: { [weak self] (_) in
                /// 清空一次标记
                self?.chatViewModel.translateService.resetMessageCheckStatus(key: self?.chatViewModel.chat.id ?? "")
                self?.tableView.displayVisibleCells()
            }).disposed(by: self.disposeBag)

        /// 自动翻译开关变了，需要刷新界面
        chatViewModel.chatAutoTranslateSettingDriver.drive(onNext: { [weak self] () in
            /// 清空一次标记
            self?.chatViewModel.translateService.resetMessageCheckStatus(key: self?.chatViewModel.chat.id ?? "")
            self?.tableView.displayVisibleCells()
        }).disposed(by: self.disposeBag)

        // 监听定时消息变化
        self.scheduleSendTipView?.fetchAndObserveData()
    }

    private func observerchatMessagesViewModel() {
        let messageDetailPageTrackKey = MessageDetailApprecibleTrack.getMessageDetailPageKey()
        chatMessagesViewModel.tableRefreshDriver
            .drive(onNext: { [weak self] (refreshType) in
                switch refreshType {
                case .refreshTable:
                    // 如果在底部则滚动，主要处理docs preview预览的上屏
                    self?.tableView.reloadAndGuarantLastCellVisible(isForceScrollToBottom: false)
                case .initMessages(let isDisplayLoad, let succeed, let index):
                    guard let self = self else { return }
                    if isDisplayLoad {
                        self.perform(#selector(self.updateHeaderViewForLoadingReply), with: nil, afterDelay: 0.3)
                    } else {
                        MessageDetailApprecibleTrack.clientDataCostEndTrack(key: messageDetailPageTrackKey)
                        MessageDetailApprecibleTrack.clientRenderCostStartTrack(key: messageDetailPageTrackKey)
                        NSObject.cancelPreviousPerformRequests(
                            withTarget: self,
                            selector: #selector(self.updateHeaderViewForLoadingReply),
                            object: nil
                        )
                        self.tableView.initCells(isDisplayLoad: false, isSucceed: succeed)
                        MessageDetailApprecibleTrack.clientRenderCostEndTrack(key: messageDetailPageTrackKey)
                        MessageDetailApprecibleTrack.loadingTimeEnd(key: messageDetailPageTrackKey,
                                                                    isNeedNet: true)
                        self.afterMessagesRenderCalled = true
                        if let index = index {
                            self.tableView.scrollToRow(at: index, at: .bottom, animated: false)
                        }
                    }
                case .refreshMessages:
                    // 如果在底部则滚动，主要处理docs preview预览的上屏
                    self?.tableView.reloadAndGuarantLastCellVisible(isForceScrollToBottom: false)
                case .hasNewMessage(let isForceScrollToBottom, let message):
                    self?.refreshForNewMessage(isForceScrollToBottom: isForceScrollToBottom)
                case .scrollToIndexPath(let indexPath):
                    self?.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
                case .updateKeyBoardEnable(let enable, let message):
                    self?.defaultKeyboard?.view?.setSubViewsEnable(enable: enable)
                    if let message = message {
                        self?.defaultKeyboard?.reloadKeyBoard(rootMessage: message)
                    }
                }
            }).disposed(by: self.disposeBag)

        chatMessagesViewModel.enableUIOutputDriver.filter({ return $0 })
            .drive(onNext: { [weak self] _ in
                self?.tableView.reloadAndGuarantLastCellVisible(animated: true)
            }).disposed(by: self.disposeBag)
    }

    @objc
    func updateHeaderViewForLoadingReply() {
        self.tableView.initCells(isDisplayLoad: true, isSucceed: nil)
    }

    //刷新，如果屏幕在最底端，还要滚动一下，保证新消息上屏
    private func refreshForNewMessage(isForceScrollToBottom: Bool) {
        if UIApplication.shared.applicationState == .background {
            self.tableView.reloadData()
        } else {
            self.tableView.reloadAndGuarantLastCellVisible(
                isForceScrollToBottom: isForceScrollToBottom,
                animated: true
            )
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.keyboardView?.showNewLine = true
        self.moduleContext.messageDetailContext.pageContainer.pageWillAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.keyboardView?.showNewLine = false
        super.viewWillDisappear(animated)
        self.keyboardView?.viewControllerWillDisappear()
        self.defaultKeyboard?.saveInputViewDraft(isExitChat: true, callback: nil)
        self.moduleContext.messageDetailContext.pageContainer.pageWillDisappear()
    }

    fileprivate var viewDidAppeared = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        chatDurationStatusTrackService?.markIfViewControllerIsAppear(value: true)
        if !self.viewDidAppeared {
            self.screenProtectService?.observeEnterBackground(targetVC: self)
            self.screenProtectService?.observe(screenCaptured: { [weak self] capture in
                if capture {
                    self?.setupPlaceholderView()
                    self?.chatMessagesViewModel.setReadService(enable: false)
                } else {
                    self?.removePlaceholderView()
                    self?.chatMessagesViewModel.setReadService(enable: true)
                    self?.tableView.displayVisibleCells()
                }
            })
            if let keyboardView = self.defaultKeyboard?.view,
               keyboardView.attributedString.length > 0 {
                self.keyboardView?.inputViewBecomeFirstResponder()
            }
        }
        self.viewDidAppeared = true
        self.keyboardView?.viewControllerDidAppear()
        self.keyboardView?.inputTextView.setAcceptablePaste(types: [UIImage.self, NSAttributedString.self])
        self.moduleContext.messageDetailContext.pageContainer.pageDidAppear()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        chatDurationStatusTrackService?.markIfViewControllerIsAppear(value: false)
        self.moduleContext.messageDetailContext.pageContainer.pageDidDisappear()
    }

    func getTableBottomConstraintItem() -> SnapKit.ConstraintItem {
        var result = view.snp.bottom
        // 外部联系人解除屏蔽
        if let chatInputView = self.keyboardView {
            // 键盘
            result = self.keyboardTopStackView.snp.top
        } else if let chatMask = self.chatterResignChatMask {
            // 离职
            result = chatMask.snp.top
        }
        return result
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resizeVMIfNeeded()
        if let placeholderChatView = self.placeholderChatView, placeholderChatView.superview != nil {
            self.view.bringSubviewToFront(placeholderChatView)
        }
        self.checkTableConstraintIniPadIfNeeded()
    }

    func setupView() {
        if self.chatViewModel.chat.chatterHasResign {
            let chatMask = ChatterResignChatMask(frame: .zero)
            self.chatterResignChatMask = chatMask
            self.view.addSubview(chatMask)
            chatMask.snp.makeConstraints { (make) in
                make.left.right.bottom.equalToSuperview()
            }
        } else if !self.isKeyboardHidden {
            let rootMessage = self.chatMessagesViewModel.rootMessage
            if let defaultKeyboard = try? componentGenerator.keyboard(
                moduleContext: moduleContext,
                delegate: self,
                pushWrapper: self.chatViewModel.chatWrapper,
                getRootMessage: { return rootMessage },
                chatFromWhere: self.chatFromWhere
            ) {
                self.defaultKeyboard = defaultKeyboard
                if let keyboardView = defaultKeyboard.view {
                    self.view.addSubview(keyboardView)
                    keyboardView.snp.makeConstraints({ make in
                        make.left.right.bottom.equalToSuperview()
                    })
                    DispatchQueue.main.async {
                        self.keyboardView?.keyboardPanel.reloadPanel()
                    }
                }
            }
        }
        self.setupKeyboardTopStackView()
        self.view.addSubview(tableView)
        self.tableView.snp.makeConstraints({ make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(getTableBottomConstraintItem())
        })

        self.navigationItem.rightBarButtonItems = self.componentGenerator.navigationBarItems(chat: self.chat.value,
                                                                                             rootMessage: self.chatMessagesViewModel.rootMessage,
                                                                                             uiDataSource: { [weak self] in self?.chatMessagesViewModel.uiDataSource ?? [] },
                                                                                             targetVC: self)
    }

    private var isKeyboardHidden: Bool {
        let openApp = chat.value.chatter?.openApp
        Self.logger.info("""
                         isKeyboardHidden: chatID = \(chat.value.id)
                         ,chatterHasResign = \(chat.value.chatterHasResign)
                         ,chatable = \(chat.value.chatable), openApp = \(openApp?.chatable.rawValue)
                         """)
        return chat.value.chatterHasResign || !chat.value.chatable || (openApp != nil && openApp?.chatable == .unchatable) || chat.value.displayInThreadMode
    }

    /// 在 iPad 中，tab 会根据外接键盘动态变化
    /// 当没有动画在执行的时候，检查 table 高度是否符合预期，如果不符合，重置约束
    private func checkTableConstraintIniPadIfNeeded() {
        guard Display.pad else {
            return
        }
        let tableHeight = getTableViewHeight()
        if tableHeight > 0,
            self.tableView.frame.height != tableHeight,
            (self.tableView.layer.animationKeys() ?? []).isEmpty {
            self.resetTableViewConstraint()
        }
    }

    private func resetTableViewConstraint(isImmediatelyLayout: Bool = true) {
        let tableHeight = getTableViewHeight()
        if tableHeight > 0 {
            self.tableView.remakeConstraints(
                height: tableHeight,
                bottom: getTableBottomConstraintItem(),
                isImmediatelyLayout: isImmediatelyLayout
            )
        }
    }

    private func resetTableViewConstraintWhenKeyboardArangViewShow() {
        let currentTableHeight = self.tableView.frame.height
        self.view.layoutIfNeeded()
        let height = getTableViewHeight()
        var offset = currentTableHeight - height
        if offset <= 0 {
            offset = 0
        }
        self.tableView.remakeConstraints(height: height, bottom: self.getTableBottomConstraintItem())

        let totalHeight = self.tableView.adjustedContentInset.top + self.tableView.adjustedContentInset.bottom + self.tableView.contentSize.height
        let completeShow = (totalHeight <= self.tableView.frame.size.height)
        if completeShow {
            self.tableView.scrollToBottom(animated: true)
        } else {
            self.tableView.setContentOffset(CGPoint(x: 0, y: self.tableView.contentOffset.y + offset), animated: true)
        }
    }

    func getTableViewHeight() -> CGFloat {
        let bottomHeight = self.keyboardView?.frame.height ?? 0 + /*self.timezoneHeight（固定为0，不需要加）*/keyboardTopStackHeight
        let height = self.view.frame.height - self.tableViewTopMargin - bottomHeight
        return height
    }
}

extension MessageDetailViewController: ChatMessagesOpenService {
    var pageAPI: PageAPI? { self }
    var dataSource: DataSourceAPI? { self.moduleContext.messageDetailContext.dataSourceAPI }
    func getUIMessages() -> [Message] {
        return self.chatMessagesViewModel.uiDataSource.flatMap {
            return $0.compactMap { item in
                return (item as? HasMessage)?.message
            }
        }
    }
}

extension MessageDetailViewController {
    func send(image: UIImage, useOriginal: Bool = false) {
        guard let imageSendService = self.imageSendService else { return }
        let jpegImageInfo = image.jpegImageInfo()
        let imgFunc: ImageSourceFunc = {
            jpegImageInfo
        }
        let imageMessageInfo = ImageMessageInfo(
            originalImageSize: image.size,
            sendImageSource: SendImageSource(
                cover: imgFunc, origin: imgFunc
            ),
            imageSize: Int64(jpegImageInfo.data?.bytes.count ?? 0)
        )
        imageSendService.sendImages(
            parentMessage: self.chatMessagesViewModel.rootMessage,
            useOriginal: useOriginal,
            imageMessageInfos: [imageMessageInfo],
            chatId: self.chat.value.id,
            lastMessagePosition: self.chatViewModel.chat.lastMessagePosition,
            quasiMsgCreateByNative: self.chatViewModel.quasiMsgCreateByNative,
            extraTrackerContext: [ChatKeyPointTracker.selectAssetsCount: 1,
                                  ChatKeyPointTracker.chooseAssetSource: ChatKeyPointTracker.ChooseAssetSource.other.rawValue],
            stateHandler: nil
        )
    }
}

// MARK: - ChatScheduleSendTipViewDelegate
extension MessageDetailViewController: ChatScheduleSendTipViewDelegate {
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

    // 输入框是否显示
    func getKeyboardIsDisplay() -> Bool {
        self.keyboardView?.isHidden == false
    }

    // 输入框是否可用
    func getKeyboardEnable() -> Bool {
        self.keyboardView?.isHidden == false && self.keyboardView?.inputTextView.isUserInteractionEnabled == true && self.chat.value.isAllowPost
    }

    func canHandleScheduleTip(messageItems: [RustPB.Basic_V1_ScheduleMessageItem],
                              entity: RustPB.Basic_V1_Entity) -> Bool {
        self.chatViewModel.canHandleScheduleTip(messageItems: messageItems, entity: entity)
    }

    func scheduleTipTapped(model: LarkMessageCore.ChatScheduleSendTipTapModel) {
        if model.keyboardEnable {
            IMTracker.Chat.Main.Click.Msg.delayedMsgEdit(self.chat.value)
            let date = Date(timeIntervalSince1970: TimeInterval(model.scheduleTime ?? 0))
            self.keyboardView?.inputViewBecomeFirstResponder()
            let info = KeyboardJob.ReplyInfo(message: model.message, partialReplyInfo: nil)
            self.keyboardView?.keyboardStatusManager.switchJob(.scheduleMsgEdit(info: info, time: date, type: model.type))
            self.defaultKeyboard?.updateAttributedString(message: model.message, isInsert: false) { [weak self] in
                if let text = self?.keyboardView?.attributedString {
                    self?.defaultKeyboard?.updateAttachmentSizeFor(attributedText: text)
                }
            }
        } else {
            let title = model.status.isFailed ? BundleI18n.LarkChat.Lark_IM_ScheduleMessage_FailedToSendMessage_Text : BundleI18n.LarkChat.Lark_IM_ScheduleMessage_UnableToSendNow_Title
            self.scheduleSendService?.showFailAlert(from: self,
                                                   message: model.message,
                                                   itemType: model.type,
                                                   title: title,
                                                   chat: self.chatViewModel.chat,
                                                   pasteboardToken: "LARK-PSDA-messenger-messageDetail-scheduleSend-copy-permission")
        }
    }
}

// MARK: - Keyboard delegate
extension MessageDetailViewController: ChatInputKeyboardDelegate {
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
        self.resetTableViewConstraintWhenKeyboardArangViewShow()
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
        self.chatMessagesViewModel.editingMessage = message
    }

    func onExitReply() {
    }

    func textChange(text: String, textView: LarkEditTextView) {
    }

    func keyboardFrameChanged(frame: CGRect) {
        if self.tableHeightLock {
            return
        }
        guard let keyboardView = self.keyboardView else { return }
        let tableContentHeight = self.tableView.contentSize.height
        let tableHeight = self.view.bounds.height - keyboardView.frame.height
        let tableOriginHeight = self.tableView.frame.height
        let tableHeightChange = tableHeight - tableOriginHeight
        if keyboardView.keyboardPanel.contentHeight == 0 {
            DispatchQueue.main.async {
                self.tableView.scrollToBottom(animated: false)
            }
            if Display.iPhoneXSeries, tableContentHeight < tableHeight {
                self.resetTableViewConstraint(isImmediatelyLayout: false)
            } else {
                self.resetTableViewConstraint()
            }
        } else {
            if tableContentHeight <= tableOriginHeight {
                self.resetTableViewConstraint(isImmediatelyLayout: !Display.iPhoneXSeries)
                if self.tableView.contentSize.height >= tableHeight {
                    self.tableView.setContentOffset(CGPoint(x: 0, y: self.tableView.contentSize.height - tableHeight), animated: true)
                }
            } else {
                self.resetTableViewConstraint()
                if !self.tableView.stickToBottom() {
                    self.tableView.setContentOffset(CGPoint(x: 0, y: self.tableView.contentOffset.y - tableHeightChange), animated: false)
                }
            }
        }
    }

    func handleKeyboardAppear(triggerType: KeyboardAppearTriggerType) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let editingMessage = self.chatMessagesViewModel.editingMessage,
               let index = self.chatMessagesViewModel.findMessageIndexBy(id: editingMessage.id) {
                self.tableView.scrollToRow(at: index, at: .bottom, animated: false)
            } else {
                self.tableView.scrollToBottom(animated: false)
            }
        }
    }

    func inputTextViewFrameChanged(frame: CGRect) {
    }

    func inputTextViewWillInput(image: UIImage) -> Bool {
        let alert = ImageInputHandler.createSendAlert(userResolver: userResolver, with: image, for: chat.value, confirmCompletion: { [weak self] in
            self?.send(image: image)
        })
        navigator.present(alert, from: self)
        return false
    }

    func rootViewController() -> UIViewController {
        return self.navigationController ?? self
    }

    func baseViewController() -> UIViewController {
        return self
    }

    func keyboardWillExpand() {
    }

    func getKeyboardStartupState() -> KeyboardStartupState {
        return .default()
    }

    func keyboardContentHeightWillChange(_ isFold: Bool) {}

    func replaceViewWillChange(_ view: UIView?) { }

    func clickChatMenuEntry() {}

    func keyboardCanAutoBecomeFirstResponder() -> Bool {
        return true
    }
}

extension MessageDetailViewController: MessageDetailTableDelegate {
    func tapTableHandler() {
        self.keyboardView?.fold()
    }
}

extension MessageDetailViewController: PageAPI {
    func viewWillEndDisplay() {
        chatMessagesViewModel.uiOutput(enable: false, indentify: "maskByCell")
        self.tableView.endDisplayVisibleCells()
    }

    func viewDidDisplay() {
        chatMessagesViewModel.uiOutput(enable: true, indentify: "maskByCell")
        self.tableView.displayVisibleCells()
    }

    var pageSupportReply: Bool {
        return self.defaultKeyboard != nil
    }

    func insertAt(by chatter: Chatter?) {
        let chat = self.chatViewModel.chat
        guard let chatter = chatter else {
            return
        }

        var displayName = chatter.name
        if chat.oncallId.isEmpty {
            displayName = chatter.displayName(chatId: chat.id, chatType: chat.type, scene: .atInChatInput)
        }
        self.keyboardView?.insert(userName: displayName, actualName: chatter.localizedName, userId: chatter.id, isOuter: false)
    }

    func reply(message: Message, partialReplyInfo: PartialReplyInfo?) {
        self.insertAt(by: message.fromChatter)
        self.keyboardView?.inputViewBecomeFirstResponder()
    }

    func reedit(_ message: Message) {
        self.keyboardView?.inputViewBecomeFirstResponder()
        self.defaultKeyboard?.reEditMessage(message: message)
    }

    func multiEdit(_ message: Message) {
        let comfirmToMultiEdit = { [weak self] (message: Message) in
            self?.defaultKeyboard?.multiEditMessage(message: message)
            self?.keyboardView?.inputViewBecomeFirstResponder()
        }
        let chat = self.chat.value
        let editingMessage = self.chatMessagesViewModel.editingMessage
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

            navigator.present(dialog, from: self)
        }
    }

    func getSelectionLabelDelegate() -> LKSelectionLabelDelegate? {
        return self.messageSelectControl
    }
}

// MARK: - EnterpriseEntityWordProtocol
extension MessageDetailViewController: EnterpriseEntityWordDelegate {

    func lockForShowEnterpriseEntityWordCard() {
        MessageDetailViewController.logger.info("MessageDetailViewController: pauseQueue for enterprise entity word card show")
        messageSelectControl?.lockChatTable()
        keyboardView?.inputTextView.resignFirstResponder()
    }

    func unlockForHideEnterpriseEntityWordCard() {
        MessageDetailViewController.logger.info("MessageDetailViewController: resumeQueue for after enterprise entity word card hide")
        messageSelectControl?.unlockChatTable()
    }
}

// MARK: - PlaceholderChatNavigationBarDelegate
extension MessageDetailViewController: PlaceholderChatNavigationBarDelegate {
    func backButtonClicked() {
        navigator.pop(from: self)
    }
}

extension MessageDetailViewController: ChatInteractionKitDelegate {
    func canHandleDropInteraction() -> Bool {
        return self.keyboardView != nil &&
            self.chat.value.isAllowPost
    }

    func handleDropChatModel() -> Chat {
        return self.chat.value
    }

    func handleImageTypeDropItem(image: UIImage) {
        send(image: image)
    }

    func handleTextTypeDropItem(text: String) {
        guard let keyboard = self.keyboardView else { return }
        keyboard.inputTextView.insertText(text)
        keyboard.inputTextView.becomeFirstResponder()
    }

    func handleFileTypeDropItem(name: String?, url: URL) {
        assertionFailure()
    }

    func interactionTargetController() -> UIViewController {
        return self
    }
}
