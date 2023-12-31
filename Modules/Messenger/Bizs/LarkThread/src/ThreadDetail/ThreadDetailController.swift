//
//  ThreadDetailController.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/1/30.
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
import LarkSDKInterface
import LarkMessengerInterface
import LarkKeyCommandKit
import LarkAlertController
import LarkSplitViewController
import LarkAI
import LarkSceneManager
import LarkSendMessage
import LarkRichTextCore
import RustPB
import LarkGuideUI
import LarkSuspendable
import LarkContainer
import RichLabel
import UniverseDesignToast
import UniverseDesignDialog
import LarkBaseKeyboard
import LarkInteraction
import LarkOpenChat
import LarkChatOpenKeyboard
import LarkExtensions
import class AppContainer.BootLoader

public protocol ThreadDetailControllerDependency {
    func isSupportURLType(url: URL) -> (Bool, type: String, token: String)
}

final class ThreadDetailController: ThreadDetailBaseViewController {
    private static let logger = Logger.log(ThreadDetailController.self, category: "LarkThread.ThreadDetail")
    static let pageName = "\(ThreadDetailController.self)"

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
    var sourceID: String = UUID().uuidString
    private var noReplyOnboarding: ThreadDetailOnboarding?
    private let disposeBag = DisposeBag()

    lazy fileprivate(set) var threadKeyboard: ThreadKeyboard? = {
        guard let keyboard = try? self.keyboardBlock(self) else { return nil }
        //只保存根消息草稿,detail页面所有消息都默认回复根消息
        keyboard.viewModel.rootMessage = self.viewModel.rootMessage
        let info = KeyboardJob.ReplyInfo(message: self.viewModel.rootMessage, partialReplyInfo: nil)
        keyboard.keyboardView.keyboardStatusManager.defaultKeyboardJob = .reply(info: info)
        keyboard.keyboardView.keyboardStatusManager.switchJob(.reply(info: info))
        keyboard.viewModel.isShowAtAll = false
        return keyboard
    }()

    var threadKeyboardView: ThreadKeyboardView? {
        return self.threadKeyboard?.keyboardView
    }

    lazy var tableView: ThreadDetailTableView = {
        let tableView = ThreadDetailTableView(viewModel: self.viewModel, tableDelegate: self)
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: CGFloat.leastNonzeroMagnitude, height: CGFloat.leastNonzeroMagnitude))
        return tableView
    }()

    /// 水印waterMarkView
    var waterMarkView: UIView?

    private lazy var animationFollowing: LOTAnimationTapView? = {
        if let path = BundleConfig.LarkThreadBundle.path(forResource: "data",
                                                         ofType: "json",
                                                         inDirectory: "lottie/threadDetailFollowing/lightMode") {
            let pathDark = BundleConfig.LarkThreadBundle.path(forResource: "data",
                                                              ofType: "json",
                                                              inDirectory: "lottie/threadDetailFollowing/darkMode")
            let animation = LOTAnimationTapView(frame: .zero, filePathLight: path, filePathDark: pathDark)
            animation.backgroundColor = UIColor.ud.bgBody
            return animation
        } else {
            return nil
        }
    }()

    private var messageSelectControl: ThreadMessageSelectControl?

    private var viewDidAppeaded: Bool = false

    private func showThreadVC() {
        ThreadTracker.trackClickTitleView()
        let chat = self.viewModel._chat
        // 公开群 && 不是成员
        if chat.role != .member && chat.isPublic {
            let body = JoinGroupApplyBody(
                chatId: chat.id,
                way: .viaSearch
            )
            navigator.open(body: body, from: self)
        } else if chat.role == .member {
            // 已经是成员
            let body = ChatControllerByIdBody(chatId: self.viewModel._chat.id)
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

    lazy var sceneButtonItem: SceneButtonItem = {
        let item = SceneButtonItem(
            clickCallBack: { [weak self] (sender) in
                self?.clickSceneButton(sender: sender)
            },
            sceneKey: "Thread", sceneId: self.viewModel.threadObserver.value.id ?? ""
        )
        item.addDefaultPointer()
        return item
    }()

    lazy var focusBarButton: FocusBarButton = {
        let but = FocusBarButton()
        but.addPointerStyle()
        return but
    }()

    lazy var moreBarButton: UIButton = {
        let moreButton = UIButton()
        moreButton.setImage(Resources.thread_detail_nav_more.withRenderingMode(.alwaysTemplate), for: .normal)
        moreButton.tintColor = UIColor.ud.iconN1
        moreButton.addTarget(self, action: #selector(moreButtonTapped(sender:)), for: .touchUpInside)
        moreButton.addPointerStyle()
        return moreButton
    }()

    lazy var lynxcardRenderFG: Bool = {
        return self.viewModel.userResolver.fg.staticFeatureGatingValue(with: "lynxcard.client.render.enable")
    }()

    let viewModel: ThreadDetailViewModel
    let currentChatterId: String
    let chatAPI: ChatAPI
    typealias KeyboardBlock = (ThreadKeyboardDelegate & ThreadKeyboardViewModelDelegate) throws -> ThreadKeyboard
    let keyboardBlock: KeyboardBlock
    private let loadType: LoadType
    private var menuService: ThreadMenuService
    private let sourceType: ThreadDetailFromSourceType
    private lazy var isEnterFromRecommendList: Bool = {
        return self.sourceType == .recommendList
    }()
    private let isFromFeed: Bool
    private var keyboardStartupState: KeyboardStartupState
    private var menuOpenService: MessageMenuOpenService?

    /// 注册 Thread Deatil 界面的 MessageActionMenu,
    func registerThreadMessageActionMenu() {
        let actionContext = MessageActionContext(parent: Container(parent: BootLoader.container),
                                                 store: Store(),
                                                 interceptor: IMMessageActionInterceptor(),
                                                 userStorage: userResolver.storage, compatibleMode: userResolver.compatibleMode)
        actionContext.container.register(ChatMessagesOpenService.self) { [weak self] _ -> ChatMessagesOpenService in
            return self ?? DefaultChatMessagesOpenService()
        }
        ThreadDetailMessageActionModule.onLoad(context: actionContext)
        let actionModule = ThreadDetailMessageActionModule(context: actionContext)
        let messageMenuService = MessageMenuServiceImp(pushWrapper: viewModel.chatWrapper,
                                                    actionModule: actionModule)
        context.pageContainer.register(MessageMenuOpenService.self) {
            return messageMenuService
        }
    }

    private let context: ThreadDetailContext
    private let dependency: ThreadDetailControllerDependency
    private let getContainerController: () -> UIViewController?
    private var specificSource: SpecificSourceFromWhere? //细化的二级来源

    @ScopedInjectedLazy private var chatDurationStatusTrackService: ChatDurationStatusTrackService?
    @ScopedInjectedLazy var lingoHighlightService: LingoHighlightService?
    init(
        loadType: LoadType,
        viewModel: ThreadDetailViewModel,
        context: ThreadDetailContext,
        currentChatterId: String,
        keyboardStartupState: KeyboardStartupState,
        chatAPI: ChatAPI,
        menuService: ThreadMenuService,
        sourceType: ThreadDetailFromSourceType,
        isFromFeed: Bool,
        keyboardBlock: @escaping KeyboardBlock,
        dependency: ThreadDetailControllerDependency,
        getContainerController: @escaping () -> UIViewController?,
        specificSource: SpecificSourceFromWhere? = nil
    ) {
        ThreadPerformanceTracker.startUIRender()
        self.getContainerController = getContainerController
        self.viewModel = viewModel
        self.sourceType = sourceType
        self.isFromFeed = isFromFeed
        self.context = context
        self.currentChatterId = currentChatterId
        self.keyboardBlock = keyboardBlock
        self.loadType = loadType
        self.keyboardStartupState = keyboardStartupState
        self.chatAPI = chatAPI
        self.menuService = menuService
        self.dependency = dependency
        self.specificSource = specificSource
        super.init(userResolver: viewModel.userResolver)
        self.context.pageContainer.pageInit()
        self.registerThreadMessageActionMenu()
        self.updateSceneTargetContentIdentifier()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.context.pageContainer.pageDeinit()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if copyOptimizeFG {
            self.messageSelectControl?.dismissMenuIfNeeded()
        }
    }

    override func splitVCSplitModeChange(split: SplitViewController) {
        super.splitVCSplitModeChange(split: split)
        if copyOptimizeFG {
            self.messageSelectControl?.dismissMenuIfNeeded()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resizeVMIfNeeded()
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
            self.observeToUpdateSceneTitle()
        }
        threadKeyboardView?.viewControllerDidAppear()
        context.pageContainer.pageDidAppear()
        updateLeftNavigationItems()
        showGuidUIIfNeed()
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
        self.fullScreenSceneBlock = { "channel_detail" }
        self.setupView()
        // 视图初始化后立即赋值，如果在监听之后用到，会因为立即来了数据push，导致crash
        self.viewModel.hostUIConfig = HostUIConfig(
            size: navigationController?.view.bounds.size ?? view.bounds.size,
            safeAreaInsets: navigationController?.view.safeAreaInsets ?? view.safeAreaInsets
        )
        self.observerViewModel()
        self.setupDraft()
        self.setupLingo()
        self.messageSelectControl = ThreadMessageSelectControl(chat: self, pasteboardToken: "LARK-PSDA-messenger-threadDetail-select-copyCommand-permission")
        messageSelectControl?.menuService = self.context.pageContainer.resolve(MessageMenuOpenService.self)
        self.messageSelectControl?.addMessageSelectObserver()
        self.obserScroll()
        ThreadPerformanceTracker.endUIRender()
        self.viewModel.initMessages(loadType: self.loadType)
        self.context.pageContainer.pageViewDidLoad()
        observeScreenShot()
        ChannelTracker.TopicDetail.View(self.viewModel._chat, self.viewModel.rootMessage.id)
        chatDurationStatusTrackService?.setGetChatBlock { [weak self] in
            return self?.viewModel._chat
        }
    }

    override func subProviders() -> [KeyCommandProvider] {
        var providers: [KeyCommandProvider] = [self.tableView]
        if let threadKeyboardView = self.threadKeyboardView {
            providers.append(threadKeyboardView)
        }
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
        self.loadingPlaceholderView.snp.remakeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(navBar.snp.bottom)
        }
        self.configFocusBarButton()
        self.addTableAndInput()
    }

    /// 配置导航栏
    private func setupNavBar() {
        isNavigationBarHidden = true
        addBackItemForNavBar()
        navBar.titleView = threadTitleView
        // 设置chatName,subjectText
        threadTitleView.setObserveData(chatObservable: self.viewModel.chatObserver)
        view.addSubview(navBar)
        navBar.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
        }
        navBar.titleViewTappedBlock = { [weak self] (_) in
            guard let self = self else {
                return
            }
            self.showThreadVC()
            ChannelTracker.TopicDetail.Click.FromTopic(self.viewModel._chat, self.viewModel.rootMessage)
        }
    }

    override func multiSelectingValueUpdate() {
        guard let threadKeyboard else { return }
        if multiSelecting {
            self.tableView.longPressGesture.isEnabled = false
            threadKeyboard.keyboardView.alpha = 0
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
            threadKeyboard.keyboardView.alpha = 1
            self.reloadNavigationBar()
            self.remakeTableViewConstraints()
            self.view.layoutIfNeeded()
            self.tableView.setContentOffset(CGPoint(x: 0, y: self.tableView.contentOffset.y), animated: false)
        }
    }

    func remakeTableViewConstraints() {
        guard let threadKeyboard = self.threadKeyboard else { return }
        self.tableView.snp.remakeConstraints { (make) in
            make.leading.trailing.equalTo(self.view)
            make.top.equalTo(navBar.snp.bottom)
            make.bottom.equalTo(threadKeyboard.keyboardView.snp.top)
        }
    }

    private func configFocusBarButton() {
        // 更新focusBarButtonItem
        focusBarButton.updateFocusBarButton(isFocus: false)
        focusBarButton.clickBlock = { [weak self] focus in
            let setFocus = !focus
            if setFocus {
                if let rect = self?.focusBarButton.buttonImageView?.frame,
                    let animationFollowing = self?.animationFollowing {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    // 隐藏 focusView，避免状态变更影响动画
                    self?.focusBarButton.isHidden = true
                    // 设置一个假状态 保证动画结束时状态一致，请求回来会更新这个状态
                    self?.focusBarButton.updateFocusBarButton(isFocus: true)
                    self?.viewModel.toggleFollow()
                    animationFollowing.frame = self?.focusBarButton.convert(rect, to: self?.focusBarButton.superview) ?? .zero
                    self?.focusBarButton.superview?.addSubview(animationFollowing)
                    animationFollowing.animationView.play(completion: { [weak animationFollowing] ( _ ) in
                        self?.focusBarButton.isHidden = false
                        animationFollowing?.removeFromSuperview()
                    })
                }
                if let chat = self?.viewModel._chat, let id = self?.viewModel.threadObserver.value.id {
                    ChannelTracker.TopicDetail.Click.Subscribe(chat, id)
                }
            } else {
                self?.viewModel.toggleFollow()
            }
        }

        reloadNavigationBar()
    }

    private func reloadNavigationBar() {
        if multiSelecting {
            navBar.rightViews = [cancelMutilButton]
        } else {
            let hasMenu = menuService.hasMenu(
                threadMessage: viewModel.messageDatasource.threadMessage,
                chat: viewModel.chatObserver.value,
                topNotice: nil,
                topicGroup: viewModel.topicGroup,
                scene: .threadDetail,
                isEnterFromRecommendList: isEnterFromRecommendList
            )
            var items: [UIView] = []
            if hasMenu {
                rightView.addSubview(moreBarButton)
                items.append(moreBarButton)
            }
            rightView.addSubview(focusBarButton)
            items.append(focusBarButton)

            if viewModel.rootMessage.localStatus == .success,
               !viewModel.rootMessage.isDecryptoFail {
                rightView.addSubview(forwardBarButton)
                items.append(forwardBarButton)
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

    private func addTableAndInput() {
        guard let threadKeyboardView else { return }
        self.view.addSubview(tableView)
        self.view.addSubview(threadKeyboardView)

        threadKeyboardView.expandType = .show
        threadKeyboardView.snp.makeConstraints({ make in
            make.left.right.bottom.equalToSuperview()
        })

        tableView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(navBar.snp.bottom)
            make.bottom.equalTo(threadKeyboardView.snp.top)
        }
    }

    private func obserScroll() {
        let refresh = self.viewModel.tableRefreshDriver.map { _ in return }
        let offset = self.tableView.rx.contentOffset.asDriver().map { _ in return }

        Driver<()>.merge([refresh, offset])
            .throttle(.milliseconds(300))
            .skip(1)
            .drive(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                if let view = (self.tableView.visibleCells.first as? MessageCommonCell)?
                    .getView(by: PostViewComponentConstant.titleKey),
                    view.convert(view.bounds, to: self.view).maxY > 0 {
                    self.threadTitleView.isShowSubTitle = false
                } else {
                    self.threadTitleView.isShowSubTitle = true
                }
            })
            .disposed(by: disposeBag)

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
            make.centerX.equalToSuperview()
            make.bottom.equalTo(self.tableView).offset(-15)
        }
        (self.downUnReadMessagesTipView.viewModel as? DownUnReadThreadDetailsTipViewModel)?
            .update(thread: self.viewModel.threadObserver.value)
    }

    private func setupDraft() {
        self.viewModel.rootMessageTextDraft()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (content) in
                guard let self = self else { return }
                if let keyboard = self.threadKeyboard as? NewThreadKeyboard {
                    /// 如果keyboard为NewThreadKeyboard，新版都使用Post的草稿
                    if !self.viewModel.isTextDraft {
                        keyboard.updateDraftContent(by: content)
                    }
                } else {
                    self.updateKeyboardViewWithTextDraftContent(content)
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

    /// 还原Text类型的草稿
    func updateKeyboardViewWithTextDraftContent(_ content: String) {
        guard !content.isEmpty, let threadKeyboardView else { return }
        let model = TextDraftModel.parse(content)
        if model.unarchiveSuccess {
            threadKeyboardView.richText = try? RustPB.Basic_V1_RichText(jsonString: model.content) ?? RustPB.Basic_V1_RichText()
            AtTransformer.getAllChatterInfoForAttributedString(threadKeyboardView.attributedString).forEach { chatterInfo in
                chatterInfo.actualName = model.userInfoDic[chatterInfo.id] ?? ""
            }
        } else if let richText = try? RustPB.Basic_V1_RichText(jsonString: content) {
            threadKeyboardView.richText = richText
        }
    }

    private func saveDraft() {
        guard let threadKeyboard else { return }
        if let multiEditMessage = threadKeyboard.keyboardView.keyboardStatusManager.getMultiEditMessage() {
            if let keyboard = threadKeyboard as? NewThreadKeyboard {
                keyboard.saveInputViewDraft(id: .multiEditMessage(messageId: multiEditMessage.id,
                                                                  chatId: viewModel._chat.id))
            }
        } else {
            let replyMessage = threadKeyboard.viewModel.replyMessage ?? viewModel.rootMessage
            if let keyboard = threadKeyboard as? NewThreadKeyboard {
                keyboard.saveInputViewDraft(id: .replyMessage(messageId: replyMessage.id))
            } else {
                let chatterActualNameMap = AtTransformer.getAllChatterActualNameMapForAttributedString(threadKeyboard.keyboardView.attributedString)
                let model = TextDraftModel(content: threadKeyboard.keyboardView.richTextStr,
                                           userInfoDic: chatterActualNameMap)
                self.viewModel.save(
                    draft: threadKeyboard.keyboardView.richTextStr,
                    id: .replyMessage(messageId: replyMessage.id))
            }
        }
    }

    /// 刷新 scene title
    private func observeToUpdateSceneTitle() {
        guard SceneManager.shared.supportsMultipleScenes else {
            return
        }
        self.viewModel.chatObserver
            .observeOn(MainScheduler.asyncInstance)
            .distinctUntilChanged({ $0.displayName == $1.displayName })
            .subscribe(onNext: { [weak self] (chat) in
                guard let vc = self else { return }
                SceneManager.shared.updateSceneIfNeeded(
                    title: chat.displayName,
                    from: vc
                )
            }).disposed(by: self.disposeBag)
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
    override func forwardButtonTapped(sender: UIButton) {
        guard let threadKeyboard = self.threadKeyboard else { return }
        threadKeyboard.keyboardView.inputTextView.resignFirstResponder()
        ChannelTracker.TopicDetail.Click.Forward(self.viewModel._chat, self.viewModel.threadObserver.value.id)
        let targetVC = self.navigationController ?? self
        let message = viewModel.rootMessage
        if viewModel._chat.isPublic {
            self.menuService.shareTopic(message: message, targetVC: targetVC)
        } else {
            self.menuService.forwardTopic(originMergeForwardId: originMergeForwardId(), message: message, chat: viewModel._chat, targetVC: targetVC)
        }
    }

    @objc
    private func moreButtonTapped(sender: UIButton) {
        guard let threadKeyboard = self.threadKeyboard else { return }
        threadKeyboard.keyboardView.inputTextView.resignFirstResponder()
        threadKeyboard.keyboardView.fold()

        ChannelTracker.TopicDetail.Click.More(self.viewModel._chat, self.viewModel.threadObserver.value.id)
        let targetVC = self.navigationController ?? self
        self.menuService.showMenu(
            threadMessage: self.viewModel.messageDatasource.threadMessage,
            chat: self.viewModel._chat,
            topNotice: nil,
            topicGroup: viewModel.topicGroup,
            isEnterFromRecommendList: isEnterFromRecommendList,
            scene: .threadDetail,
            uiConfig: ThreadMenuUIConfig(pointView: sender,
                                         targetVC: targetVC,
                                         menuAnimationBegin: nil,
                                         menuAnimationEnd: nil))
    }

    // MARK: 全屏按钮
    override func splitSplitModeChange(splitMode: SplitViewController.SplitMode) {
        self.updateLeftNavigationItems()
    }

    private func addBackItemForNavBar() {
        navBar.addBackButton { [weak self] in
            if let chat = self?.viewModel._chat, let id = self?.viewModel.threadObserver.value.id {
                ChannelTracker.TopicDetail.Click.Close(chat, id)
            }
            self?.backItemTapped()
        }
    }

    private func addCloseItemForNavBar() {
        navBar.addCloseButton { [weak self] in
            if let chat = self?.viewModel._chat, let id = self?.viewModel.threadObserver.value.id {
                ChannelTracker.TopicDetail.Click.Close(chat, id)
            }
            self?.closeBtnTapped()
        }
    }

    // MARK: - 引导页UI
    private func showGuidUIIfNeed() {
        // 来自feed的点击 & 需要展示引导 & 存在view
        guard self.isFromFeed, let newGuideManager = self.viewModel.newGuideManager,
              newGuideManager.checkShouldShowGuide(key: self.viewModel.guideUIKey),
              focusBarButton.frame != .zero else {
            return
        }
        let guideAnchor = TargetAnchor(targetSourceType: .targetView(focusBarButton), offset: -8, targetRectType: .circle)
        let textInfoConfig = TextInfoConfig(detail: BundleI18n.LarkThread.Lark_Groups_UnsubscribeGuide)
        let item = BubbleItemConfig(guideAnchor: guideAnchor, textConfig: textInfoConfig)
        let singleBubbleConfig = SingleBubbleConfig(delegate: nil, bubbleConfig: item)
        let window = UIWindow(frame: self.view.window?.bounds ?? self.view.bounds)
        if #available(iOS 13.0, *) {
            window.windowScene = self.view.window?.windowScene
        }
        window.windowIdentifier = "LarkThread.guideWindow"
        newGuideManager.showBubbleGuideIfNeeded(guideKey: self.viewModel.guideUIKey,
                                                               bubbleType: .single(singleBubbleConfig),
                                                               customWindow: window,
                                                               dismissHandler: nil)
    }

}

extension ThreadDetailController {
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
                //如果是从ThreadChat页面进来的，会在ThreadChatController监听，这里不重复处理
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
                    self?.updateNoReplyOnboardingView()
                    self?.refreshForInitMessages(hasHeader: info.hasHeader,
                                                 hasFooter: info.hasFooter,
                                                 scrollType: info.scrollType)
                    ThreadPerformanceTracker.trackThreadDetailLoadTime(chat: self?.viewModel._chat, pageName: ThreadDetailController.pageName)
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
                    self?.updateNoReplyOnboardingView()
                    self?.tableView.reloadAndGuarantLastCellVisible()
                case .refreshMissedMessage:
                    self?.tableView.keepOffsetRefresh(nil)
                case .hasNewMessage(let hasFooter):
                    self?.refreshForNewMessage()
                    self?.updateNoReplyOnboardingView()
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
                }
            }).disposed(by: self.disposeBag)

        self.viewModel.threadObserver
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (thread) in
                self?.focusBarButton.updateFocusBarButton(isFocus: thread.isFollow)
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
                    alertController.showCloudDiskFullAlert(from: self, nav: self.navigator)
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
                self?.updateNoReplyOnboardingView()
                self?.tableView.reloadAndGuarantLastCellVisible(animated: true)
            }).disposed(by: self.disposeBag)

        self.viewModel
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
                func bringToFront(_ view: UIView) {
                    if view.superview == self.view {
                        self.view.bringSubviewToFront(view)
                    }
                }
                bringToFront(waterMarkImage)
            }).disposed(by: self.disposeBag)
    }

    //被踢出群或群被解散 时的弹窗提示
    private func alertBeDeletedFromChannel(content: String) {
        let alertController = LarkAlertController()
        alertController.setContent(text: content)
        alertController.addPrimaryButton(text: BundleI18n.LarkThread.Lark_Legacy_IKnow, dismissCompletion: { [weak self] in
            DispatchQueue.main.async {
                self?.popSelf()
            }
        })
        navigator.present(alertController, from: self)
    }

    private func updateNoReplyOnboardingView() {
        if self.viewModel.showReplyOnboarding() {
            if noReplyOnboarding == nil {
                let noReplyOnboarding = ThreadDetailOnboarding(threadObserver: viewModel.threadObserver)
                noReplyOnboarding.didTapped = { [weak self] in
                    guard let `self` = self else { return }
                    self.threadKeyboardView?.inputViewBecomeFirstResponder()
                }

                let size = noReplyOnboarding.systemLayoutSizeFitting(
                    CGSize(
                        width: self.view.bounds.width,
                        height: CGFloat.greatestFiniteMagnitude
                    )
                )
                noReplyOnboarding.frame = CGRect(origin: .zero, size: size)
                self.tableView.tableFooterView = noReplyOnboarding

                self.noReplyOnboarding = noReplyOnboarding
            }
        } else {
            tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: CGFloat.leastNonzeroMagnitude, height: CGFloat.leastNonzeroMagnitude))
            noReplyOnboarding = nil
        }
    }

    func refreshForInitMessages(hasHeader: Bool, hasFooter: Bool, scrollType: ThreadDetailViewModel.ScrollType) {
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
    func refreshForMessages(hasHeader: Bool, hasFooter: Bool, scrollType: ThreadDetailViewModel.ScrollType) {
        self.tableView.hasHeader = hasHeader
        self.tableView.hasFooter = hasFooter
        self.tableView.reloadData()
        self.scrollTo(scrollType: scrollType)
    }

    func scrollTo(scrollType: ThreadDetailViewModel.ScrollType) {
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

// MARK: - ChatPageAPI 多选
extension ThreadDetailController: ChatPageAPI {
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

// MARK: - 键盘代理
extension ThreadDetailController: ThreadKeyboardDelegate, ThreadKeyboardViewModelDelegate {
    func getScheduleMsgSendTime() -> Int64? {
        nil
    }

    var chatFromWhere: ChatFromWhere {
        return ChatFromWhere.default()
    }

    func getSendScheduleMsgIds() -> ([String], [String]) {
        ([], [])
    }

    func setScheduleTipViewStatus(_ status: ScheduleMessageStatus) {
    }

    func jobDidChange(old: KeyboardJob?, new: KeyboardJob) {
    }

    func getKeyboardStartupState() -> KeyboardStartupState {
        return self.keyboardStartupState
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
        self.viewModel.save(draft: draft, id: id)
    }

    func cleanPostDraftWith(key: String, id: DraftId) {
        self.viewModel.cleanPostDraftWith(key: key, id: id)
    }

    /// 发文本消息，支持设置匿名
    func defaultInputSendTextMessage(_ content: RustPB.Basic_V1_RichText,
                                     lingoInfo: RustPB.Basic_V1_LingoOption?,
                                     parentMessage: LarkModel.Message?,
                                     scheduleTime: Int64? = nil,
                                     transmitToChat: Bool = false,
                                     isFullScreen: Bool) {
        let replyMessage = self.getReplyMessage(by: parentMessage)
        ThreadTracker.trackSendMessage(
            messageLength: content.innerText.count,
            parentMessage: replyMessage, type: .text,
            chatId: viewModel._chat.id,
            isSupportURLType: dependency.isSupportURLType(url:),
            chat: viewModel._chat)
        self.viewModel.sendText(
            content: content,
            lingoInfo: lingoInfo,
            parentMessage: replyMessage,
            chatId: self.viewModel.chatObserver.value.id) { [weak self] state in
            self?.trackInputMsgSend(state: state, isFullScreen: isFullScreen)
        }
        self.trackNewReplyEvent()
    }

    /// 发送富文本，支持设置匿名
    func defaultInputSendPost(content: RichTextContent,
                              parentMessage: LarkModel.Message?,
                              scheduleTime: Int64? = nil,
                              transmitToChat: Bool = false,
                              isFullScreen: Bool) {
        let replyMessage = self.getReplyMessage(by: parentMessage)
        ThreadTracker.trackSendMessage(
            messageLength: content.richText.innerText.count,
            parentMessage: replyMessage,
            type: .post,
            chatId: viewModel._chat.id,
            isSupportURLType: dependency.isSupportURLType(url:),
            chat: viewModel._chat)
        self.viewModel.sendPost(
            title: content.title,
            content: content.richText,
            lingoInfo: content.lingoInfo,
            transmitToChat: transmitToChat,
            parentMessage: replyMessage,
            chatId: self.viewModel.chatObserver.value.id) { [weak self] state in
            self?.trackInputMsgSend(state: state, isFullScreen: isFullScreen)
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

    /// 跟踪回帖事件
    private func trackNewReplyEvent() {
        ThreadTracker.trackNewReply(isPulicGroup: self.viewModel.chatObserver.value.isPublic,
                                    isAnonymous: false)
    }

    /// 新版输入框发送消息埋点
    private func trackInputMsgSend(state: SendMessageState, isFullScreen: Bool) {
        if case .finishSendMessage(let message, _, _, _, _) = state {
            var useSendBtn = self.keyboardView?.keyboardNewStyleEnable ?? false
            if isFullScreen {
                useSendBtn = true
            }
            IMTracker.Chat.Main.Click.InputMsgSend(self.viewModel._chat,
                                                   message: message,
                                                   isFullScreen: isFullScreen,
                                                   useSendBtn: useSendBtn,
                                                   translateStatus: .none,
                                                   nil, nil)
        }
    }
}

extension ThreadDetailController: UnReadMessagesTipViewDelegate {
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

extension ThreadDetailController: DetailTableDelegate {

    func tapHandler() {
        self.threadKeyboardView?.fold()
    }

    func showTopLoadMore(status: ScrollViewLoadMoreStatus) {
        switch status {
        case .start:
            self.viewModel.topLoadMoreReciableKeyInfo = LoadMoreReciableKeyInfo.generate(page: ThreadDetailController.pageName)
        case .finish:
            break
        }
    }

    func showBottomLoadMore(status: ScrollViewLoadMoreStatus) {
        switch status {
        case .start:
            self.viewModel.bottomLoadMoreReciableKeyInfo = LoadMoreReciableKeyInfo.generate(page: ThreadDetailController.pageName)
        case .finish:
            break
        }
    }

    func showMenuForCellVM(cellVM: ThreadDetailCellVMGeneralAbility) {
        ChannelTracker.TopicDetail.Click.MsgPress(self.viewModel._chat, cellVM.message)
    }
    func willDisplay(cell: UITableViewCell, cellVM: ThreadDetailCellViewModel) {
        if let messageCellVM = cellVM as? HasMessage {
            self.viewModel.readService.putRead(element: messageCellVM.message, urgentConfirmed: nil)
            if messageCellVM.message.threadPosition == self.viewModel.highlightPosition {
                (cell as? MessageCommonCell)?.highlightView()
                self.viewModel.highlightPosition = nil
            }
        }
    }
}

extension ThreadDetailController: PageAPI {
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
        if viewModel.threadObserver.value.stateInfo.state == .closed {
            UDToast.showFailure(
                with: BundleI18n.LarkThread.Lark_Chat_TopicClosedInputWindowPlaceholder,
                on: self.view
            )
            return
        }
        guard let threadKeyboard, let threadKeyboardView else { return }
        let comfirmToMultiEdit = { (message: Message) in
            threadKeyboard.multiEditMessage(message: message)
            threadKeyboardView.inputViewBecomeFirstResponder()
        }
        if !threadKeyboardView.keyboardStatusManager.currentKeyboardJob.isMultiEdit {
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

extension ThreadDetailController: EnterpriseEntityWordDelegate {

    func lockForShowEnterpriseEntityWordCard() {
        ThreadDetailController.logger.info("ThreadDetailController: pauseQueue for enterprise entity word card show")
        viewModel.pauseQueue()
    }

    func unlockForHideEnterpriseEntityWordCard() {
        ThreadDetailController.logger.info("ThreadDetailController: resumeQueue for after enterprise entity word card hide")
        viewModel.resumeQueue()
    }

}

extension ThreadDetailController {
    private func updateSceneTargetContentIdentifier() {
        let sceneInfo = LarkSceneManager.Scene(
            key: "Thread",
            id: self.viewModel.threadObserver.value.id
        )
        self.sceneTargetContentIdentifier = sceneInfo.targetContentIdentifier
    }

    private func updateLeftNavigationItems() {
        guard Display.pad else {
            return
        }
        let controller = self.getContainerController() ?? self
        self.navBar.leftItems = []
        let sceneInfo = LarkSceneManager.Scene(
            key: "Thread",
            id: self.viewModel.threadObserver.value.id
        )
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
        if SceneManager.shared.supportsMultipleScenes {
            if #available(iOS 13.0, *) {
                if self.currentScene()?.sceneInfo != sceneInfo {
                    self.navBar.leftViews.append(self.sceneButtonItem)
                }
            }
        }
    }
}

// MARK: - ThreadFilterController 对 OpenIM 架构暴露的关于Messages的能力
extension ThreadDetailController: ChatMessagesOpenService {
    func getUIMessages() -> [Message] {
        return self.viewModel.uiDataSource.flatMap {
            return $0.compactMap { item in
                return (item as? HasMessage)?.message
            }
        }
    }
    var pageAPI: PageAPI? {
        return self
    }
    var dataSource: DataSourceAPI? {
        return self.context.dataSourceAPI
    }
}

// MARK: - 页面支持收入多任务浮窗

extension ThreadDetailController: ViewControllerSuspendable {

    var suspendID: String {
        return viewModel.threadObserver.value.id
    }

    var suspendSourceID: String {
        return sourceID
    }

    var suspendTitle: String {
        let message = viewModel.rootMessage
        let content = MessageSummarizeUtil.getSummarize(message: message, lynxcardRenderFG: self.lynxcardRenderFG)
        if let name = message.fromChatter?.displayName {
           return content + " - " + name
        } else {
            return content
        }
    }

    var suspendIcon: UIImage? {
        return Resources.suspend_icon_topic
    }

    var suspendIconKey: String? {
        return viewModel.threadObserver.value.avatarKey
    }

    var suspendIconEntityID: String? {
        return currentChatterId
    }

    var suspendURL: String {
        return "//client/chat/thread/detail/\(viewModel.threadObserver.value.id)"
    }

    var suspendParams: [String: AnyCodable] {
        return [:]
    }

    var suspendGroup: SuspendGroup {
        return .thread
    }

    var isWarmStartEnabled: Bool {
        return false
    }

    var analyticsTypeName: String {
        return "topic"
    }
}
