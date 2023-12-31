//
//  ThreadChatController.swift
//  LarkChat
//
//  Created by liuwanlin on 2019/1/30.
//

import Foundation
import RxSwift
import RxCocoa
import SnapKit
import LarkCore
import Swinject
import LarkModel
import LarkBadge
import LarkUIKit
import UniverseDesignToast
import EENavigator
import LarkContainer
import LarkMessageCore
import LarkMessageBase
import LKCommonsLogging
import LarkMenuController
import LarkAlertController
import LarkTraitCollection
import LarkSDKInterface
import LarkFeatureGating
import AppReciableSDK
import LarkAI
import LarkSceneManager
import RustPB
import RichLabel
import UniverseDesignTabs
import UniverseDesignShadow
import LarkMessengerInterface
import UIKit
import LarkOpenChat
import UniverseDesignDialog
import LarkSplitViewController
import LarkSendMessage
import LarkSetting

protocol ThreadChatTapPageAPI {
    func setUpdateTopNotice(updateNotice: @escaping ((ChatTopNotice?) -> Void))
}

final class ThreadChatController: BaseUIViewController, UserResolverWrapper {
    let userResolver: UserResolver
    static let pageName = "\(ThreadChatController.self)"
    static let logger = Logger.log(ThreadChatController.self, category: "Module.IM.Message")
    weak var delegate: ThreadContainerDelegate?
    // UDTab里会临时构建一个VC，iPad下找层级关系可能会找错，这里需要外面传入containerVC
    weak var containerVC: UIViewController?
    private let disposeBag = DisposeBag()
    private let heightOfNavigationBar: CGFloat = 44
    private var onboardingView: ThreadNewOnboardingView?
    fileprivate var topLoadMoreReciableKey: DisposedKey?
    fileprivate var bottomLoadMoreReciableKey: DisposedKey?
    @ScopedInjectedLazy private var alertService: PostMessageErrorAlertService?

    lazy var tableView: ThreadChatTableView = {
        let isOnlyReceiveScroll = chatViewModel.chat.isTeamVisitorMode
        let tableView = ThreadChatTableView(viewModel: self.messageViewModel,
                                            isOnlyReceiveScroll: isOnlyReceiveScroll)
        tableView.chatTableDelegate = self
        tableView.contentInset = UIEdgeInsets(
            top: 0,
            left: 0,
            bottom: Display.iPhoneXSeries ? 109.5 : 65.5,
            right: 0
        )
        return tableView
    }()

    private var showFrozenMask = false {
        didSet {
            if showFrozenMask {
                self.view.addSubview(self.frozenMask)
                self.frozenMask.snp.makeConstraints { make in
                    make.left.right.bottom.equalToSuperview()
                }
            }
        }
    }
    private lazy var frozenMask: UIView = ChatFrozenMask()

    private var messageSelectControl: ThreadMessageSelectControl?

    lazy var copyOptimizeFG: Bool = {
        return (try? userResolver.resolve(assert: FeatureGatingService.self))?.staticFeatureGatingValue(with: .init(key: .groupMobileCopyOptimize)) ?? false
    }()

    lazy var downUnReadMessagesTipView: DownUnReadMessagesTipView? = {
        // hide unreadTipView if is participant role
        if self.messageViewModel.topicGroup.isParticipant {
            return nil
        }
        if chatViewModel.chat.isTeamVisitorMode { return nil }
        let viewModel = UnReadNewThreadsTipViewModel(
            userResolver: self.userResolver,
            channelId: self.chatViewModel.chat.id,
            pushCenter: self.chatViewModel.pushCenter,
            lastMessagePosition: self.chatViewModel.chat.lastThreadPosition,
            requestCount: messageViewModel.requestCount,
            redundancyCount: messageViewModel.redundancyCount,
            threadAPI: self.messageViewModel.dependency.threadAPI
        )
        let tipView = DownUnReadMessagesTipView(
            chat: self.chatViewModel.chat,
            viewModel: viewModel
        )
        tipView.delegate = self
        return tipView
    }()

    private lazy var topUnReadMessagesTipView: TopUnreadMessagesTipView? = {
        // hide unreadTipView if is participant role
        if self.messageViewModel.topicGroup.isParticipant {
            return nil
        }
        if chatViewModel.chat.isTeamVisitorMode { return nil }
            // old threads in bottom
        if showOldUnReadMessagesTipView,
           let readPositionBadgeCount = self.messageViewModel.firstUnreadMessageInfo?.readPositionBadgeCount {
            let viewModel = UnReadOldThreadsTipViewModel(
                userResolver: self.userResolver,
                chatID: self.chatViewModel.chat.id,
                firstUnreadMessagePosition: self.messageViewModel.firstUnreadMessageInfo?.firstUnreadMessagePosition,
                readPositionBadgeCount: readPositionBadgeCount + 1,
                requestCount: messageViewModel.requestCount,
                redundancyCount: messageViewModel.redundancyCount,
                threadAPI: self.messageViewModel.dependency.threadAPI
            )

            let tipView = TopUnreadMessagesTipView(
                chat: self.chatViewModel.chat,
                viewModel: viewModel
            )
            tipView.delegate = self
            return tipView
        }
        return nil
    }()

    private lazy var plusButton: PlusButtonControl? = {
        if chatViewModel.chat.isTeamVisitorMode { return nil }
        let viewModel = PlusButtonViewModel(
            chatPushWrapper: self.chatViewModel.chatWrapper,
            postSendService: self.chatViewModel.postSendService
        )
        let plusButton = PlusButtonControl(
            viewModel: viewModel,
            clickBlock: { [weak self] () in
                guard let `self` = self else { return }
                self.showPostView(multiEditingMessage: nil)
            }
        )
        return plusButton
    }()
    /// 骨架图
    private lazy var skeletonTableView: TopicsSkeletonTableView = {
        let view = TopicsSkeletonTableView()
        return view
    }()

    @ScopedInjectedLazy(\SendMessageAPI.statusDriver) var sendMessageStatusDriver: Driver<(LarkModel.Message, Error?)>?
    let chatViewModel: ThreadChatViewModel
    let messageViewModel: ThreadChatMessagesViewModel
    private let specifiedPosition: Int32?
    private let tableViewTopMargin: CGFloat = UIApplication.shared.statusBarFrame.height
    private let router: ThreadChatRouter
    private let unreadTipViewClickedFunc: () -> Void
    private var viewDidDisappear = false
    /// 当banner添加后，调整一下TopUnReadView的布局
    /// default 不需要，因为banner总是优先添加，但是特殊情况下，可能会banner晚于TopUnReadView
    private var needLayoutTopUnReadView = false

    private let context: ThreadContext

    /// bannerContext
    let bannerContext: ChatBannerContext

    /// 所有待展示banner的集合：入群申请、视频会议卡片、日程卡片
    lazy var bannerView: UIView = {
        ChatBannerModule.onLoad(context: bannerContext)
        ChatBannerModule.registGlobalServices(container: bannerContext.container)
        let banner = ChatBannerView(bannerModule: ChatBannerModule(context: self.bannerContext), chatWrapper: self.chatViewModel.chatWrapper)
        self.bannerContext.container.register(ChatOpenBannerService.self) { [weak banner] (_) -> ChatOpenBannerService in
            return banner ?? DefaultChatOpenBannerService()
        }
        banner.changeDisplayStatus = { [weak self] display in
             if let topView = self?.topUnReadMessagesTipView {
                 self?.updateTopUnReadMessagesTipViewConstraints(topView, hasBanner: display)
             }
         }
        return banner
    }()

    /// 注册 Thread 全部话题界面的 MessageActionMenu
    func registerThreadMessageActionMenu(actionContext: MessageActionContext) {
        actionContext.container.register(ChatMessagesOpenService.self) { [weak self] _ -> ChatMessagesOpenService in
            return self ?? DefaultChatMessagesOpenService()
        }
        ThreadMessageActionModule.onLoad(context: actionContext)
        let actionModule = ThreadMessageActionModule(context: actionContext)
        let messageMenuService = MessageMenuServiceImp(pushWrapper: chatViewModel.chatWrapper,
                                                    actionModule: actionModule)
        context.pageContainer.register(MessageMenuOpenService.self) {
            return messageMenuService
        }
    }

    // MARK: Life Cycle
    init(userResolver: UserResolver,
        specifiedPosition: Int32? = nil,
        chatViewModel: ThreadChatViewModel,
        messageViewModel: ThreadChatMessagesViewModel,
        context: ThreadContext,
        bannerContext: ChatBannerContext,
        messageActionContext: MessageActionContext,
        router: ThreadChatRouter,
        unreadTipViewClickedFunc: @escaping () -> Void
    ) {
        self.userResolver = userResolver
        self.unreadTipViewClickedFunc = unreadTipViewClickedFunc
        self.specifiedPosition = specifiedPosition
        self.chatViewModel = chatViewModel
        self.messageViewModel = messageViewModel
        self.context = context
        self.bannerContext = bannerContext
        self.router = router
        super.init(nibName: nil, bundle: nil)
        self.context.pageContainer.pageInit()
        self.messageViewModel.gcunit?.delegate = self
        self.registerThreadMessageActionMenu(actionContext: messageActionContext)
    }

    private var showOldUnReadMessagesTipView: Bool {
        guard specifiedPosition == nil && chatViewModel.chat.badge > 0 else {
            return false
        }
        let userSettingStatus = self.messageViewModel.dependency
            .userUniversalSettingService
            .getIntUniversalUserSetting(key: "GLOBALLY_ENTER_CHAT_POSITION") ?? Int64(UserUniversalSettingKey.ChatLastPostionSetting.recentLeft.rawValue)
        if userSettingStatus == UserUniversalSettingKey.ChatLastPostionSetting.recentLeft.rawValue {
            //1、上次离开的位置
            return false
        } else if userSettingStatus == UserUniversalSettingKey.ChatLastPostionSetting.lastUnRead.rawValue {
            //2、最后一条未读消息
            return true
        } else {
            ThreadChatController.logger.info("userUniversalPageConfigFG error\(userSettingStatus)")
            return chatViewModel.chat.messagePosition == .newestUnread
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.context.pageContainer.pageDeinit()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if self.copyOptimizeFG {
            self.messageSelectControl?.dismissMenuIfNeeded()
        }
    }

    override func splitVCSplitModeChange(split: SplitViewController) {
        super.splitVCSplitModeChange(split: split)
        if self.copyOptimizeFG {
            self.messageSelectControl?.dismissMenuIfNeeded()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewDidDisappear = false
        tableView.showViewEnable = true
        context.pageContainer.pageWillAppear()
        ThreadChatController.logger.info("ThreadChat life: viewWillAppear \(viewDidDisappear) \(tableView.showViewEnable)")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.hideHighlight()
        context.pageContainer.pageDidAppear()
        ThreadTracker.trackTopicFollowToAll()
        self.delegate?.updateShowTableView(tableView: self.tableView)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        context.pageContainer.pageWillDisappear()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewDidDisappear = true
        tableView.showViewEnable = false
        context.pageContainer.pageDidDisappear()
        ThreadChatController.logger.info("ThreadChat life: viewDidDisappear \(viewDidDisappear) \(tableView.showViewEnable)")

        if let cellInfo = self.tableView.firstVisibleMessageCellInfo() {
            // 最后一个cell完全移出屏幕，才记录位置
            let rect = self.view.convert(cellInfo.frame, from: self.tableView)
            self.messageViewModel.setLastRead(messagePosition: cellInfo.messagePosition, offsetInScreen: rect.minY)
        } else {
            self.messageViewModel.setLastRead(messagePosition: -1, offsetInScreen: 0)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // 视图初始化后立即赋值，如果在监听之后用到，会因为立即来了数据push，导致crash
        self.messageViewModel.hostUIConfig = HostUIConfig(
            size: delegate?.hostSize ?? navigationController?.view.bounds.size ?? view.bounds.size,
            safeAreaInsets: navigationController?.view.safeAreaInsets ?? view.safeAreaInsets
        )
        // 需要在 willReceiveProps 之前将 CR 信息给到 VM，willReceiveProps 会从 VM 中取 CR 信息，对按钮进行布局
        self.messageViewModel.traitCollection = navigationController?.currentWindow()?.lkTraitCollection
        self.setupView()
        self.setNeedsStatusBarAppearanceUpdate()
        self.observerChatViewModel()
        self.observerMessageViewModel()
        self.messageSelectControl = ThreadMessageSelectControl(chat: self, pasteboardToken: "LARK-PSDA-messenger-threadChat-select-copyCommand-permission")
        messageSelectControl?.menuService = self.context.pageContainer.resolve(MessageMenuOpenService.self)
        self.messageSelectControl?.addMessageSelectObserver()
        self.observerSendThreadStatus()
        self.messageViewModel.initMessages(specifiedPosition: specifiedPosition)
        self.observeTraitCollection()
        self.context.pageContainer.pageViewDidLoad()
        observceScreenShot()
    }

    // MARK: private methods
    private func observceScreenShot() {
        //监听截屏事件，打log
        NotificationCenter.default.rx.notification(UIApplication.userDidTakeScreenshotNotification)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self, self.viewIfLoaded?.window != nil else { return }
                let viewModels = self.messageViewModel.uiDataSource
                let visibleViewModels = (self.tableView.indexPathsForVisibleRows ?? [])
                    .map { viewModels[$0.row] }
                let messages: [[String: String]] = visibleViewModels
                    .compactMap { (vm: ThreadCellViewModel) -> Message? in (vm as? ThreadMessageCellViewModel)?.getThreadMessage().message }
                    .map { (message: Message) -> [String: String]  in
                        let message_length = self.chatViewModel.dependency.modelService?.messageSummerize(message).count ?? -1
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
                Self.logger.info("user screenshot accompanying infos:" + "channel_id: \(self.chatViewModel.chat.id), messages: \(jsonStr)")
            })
            .disposed(by: disposeBag)
    }

    private func resizeVMIfNeeded() {
        let size = view.bounds.size
        if size != messageViewModel.hostUIConfig.size {
            let needOnResize = size.width != messageViewModel.hostUIConfig.size.width
            messageViewModel.hostUIConfig.size = size
            let fg = self.userResolver.fg.dynamicFeatureGatingValue(with: "im.message.resize_if_need_by_width")
            if fg {
                // 仅宽度更新才刷新cell，因为部分机型系统下(iphone8 iOS15、不排除其他系统也存在相同问题)存在非预期回调，比如当唤起大图查看器时，系统回调了该函数，且给的高度不对
                /*1. cell渲染只依赖宽度 2. 目前正常情况下不存在只变高，不变宽的情况（转屏、ipad拖拽）
                 */
                if needOnResize {
                    messageViewModel.onResize()
                }
            } else {
                messageViewModel.onResize()
            }
            updateOnboardingViewWithAnimation()
        }
    }

    private func setupView() {
        self.view.backgroundColor = UIColor.ud.bgBase
        self.isNavigationBarHidden = true
        self.loadingPlaceholderView.snp.remakeConstraints { (make) in
            make.top.left.right.bottom.equalToSuperview()
        }
        self.showFrozenMask = self.chatViewModel.chat.isFrozen
        self.addTableView()
        self.addPlusButtonControl()
    }

    /// 添加bannerView
    func addBannerViewWithTopConstraintItem(_ constraintItem: ConstraintItem) {
        self.view.addSubview(self.bannerView)
        self.bannerView.snp.makeConstraints { make in
            make.top.equalTo(constraintItem)
            make.left.right.equalToSuperview()
        }
    }

    private func getTableBottomConstraintItem() -> SnapKit.ConstraintItem {
        if showFrozenMask {
            return self.frozenMask.snp.top
        }
        return self.view.snp.bottom
    }

    private func addTableView() {
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(self.getTableBottomConstraintItem())
        }
        self.showSkeletonTableView()
    }

    private func updateTableConstraints() {
        self.tableView.snp.remakeConstraints({ make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(self.getTableBottomConstraintItem())
        })
    }

    /// 显示骨架图
    private func showSkeletonTableView() {
        self.skeletonTableView.isHidden = false
        self.skeletonTableView.startLoading()
        // 骨架图加到tableView上，用户可在骨架图展示期间进行上下滚动，会有上下滚动的交互动画
        self.tableView.addSubview(self.skeletonTableView)
        // 添加到tableView上的视图，会受到contentInset影响，比如top约束为0，实际top距离上边界最开始为contentInset.top
        self.skeletonTableView.snp.makeConstraints { (make) in
            // 和updateTableViewContentSize逻辑一致
            make.height.equalTo(self.tableView).offset(-tableView.contentInset.bottom)
            make.width.equalTo(self.tableView)
        }
    }

    /// 隐藏骨架图
    private func hiddenSkeletonTableView() {
        self.skeletonTableView.isHidden = true
        self.skeletonTableView.removeFromSuperview()
    }

    private func addPlusButtonControl() {
        guard let plusButton = self.plusButton else { return }
        view.addSubview(plusButton)
        plusButton.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview()
            make.width.height.equalTo(PlusButtonControl.buttonSize + PlusButtonControl.buttonInset * 2)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    private func showPostView(multiEditingMessage: Message?) {
        guard self.chatViewModel.chat.isAllowPost else {
            let text = BundleI18n.LarkThread.Lark_Group_GroupOwnerAdminBannedNewTopics
            UDToast.showFailure(
                with: text,
                on: self.view
            )
            return
        }

        self.router.presentPostView(
            chat: self.chatViewModel.chat,
            isDefaultTopicGroup: self.messageViewModel.topicGroup.isDefaultTopicGroup,
            multiEditingMessage: multiEditingMessage,
            from: self
        )
    }

    private func setupUnreadTipView() {
        let newUnreadTipView: BaseUnReadMessagesTipView? = self.downUnReadMessagesTipView
        let oldUnreadTipView: BaseUnReadMessagesTipView? = self.topUnReadMessagesTipView

        (newUnreadTipView?.viewModel as? UnReadNewThreadsTipViewModel)?.update(chat: self.chatViewModel.chat)
        // if old unread message exsit. new unread message tip view hide
        if oldUnreadTipView != nil {
            newUnreadTipView?.isHidden = true
        }

        let topTipView: UIView? = oldUnreadTipView
        let downTipView: UIView? = newUnreadTipView
        if let topView = topTipView {
            self.view.insertSubview(topView, aboveSubview: self.tableView)
            let hasBanner = (self.bannerView as? ChatBannerView)?.isDisplay ?? false
            self.updateTopUnReadMessagesTipViewConstraints(topView, hasBanner: hasBanner)
        }

        if let downView = downTipView, let plusButton = self.plusButton {
            self.view.insertSubview(downView, aboveSubview: self.tableView)
            downView.snp.makeConstraints { (make) in
                make.right.equalTo(-8)
                make.bottom.equalTo(plusButton.snp.top).offset(4)
            }
        }

        // 上下气泡布局完成后，立即显示。
        view.layoutIfNeeded()
    }

    private func updateTopUnReadMessagesTipViewConstraints(_ tipView: UIView, hasBanner: Bool) {
        guard tipView.superview != nil else {
            return
        }
        if bannerView.superview == nil {
            self.needLayoutTopUnReadView = true
            return
        }
        let offset = hasBanner ? 20 : 40
        tipView.snp.remakeConstraints { (make) in
            make.right.equalTo(-8)
            make.top.equalTo(self.bannerView.snp.bottom).offset(offset)
        }
    }

    /// 监听置顶变更
    private func addTopNoticeObserver() {
        self.delegate?.topNoticeManager()
            .topNoticeDriver
            .drive(onNext: { [weak self] notice in
                self?.messageViewModel.topNoticeSubject.onNext(notice)
            }).disposed(by: self.disposeBag)
    }

    // support reverse FG
    private func jumpToBottommostMessage(_ toBottommost: Bool, finish: @escaping () -> Void) {
        Self.logger.info("chatTrace jumpToBottommostMessage toBottommost: \(toBottommost)")
        if toBottommost {
            self.messageViewModel.jumpToChatLastMessage(finish: finish)
        } else {
            self.messageViewModel.jumpToOldestUnreadMessage(finish: finish)
        }
    }

    private func appendOldMessages(hasLoading: Bool) {
        self.tableView.headInsertCells(hasHeader: hasLoading)
    }

    private func appendNewMessages(hasLoading: Bool) {
        self.tableView.appendCells(hasFooter: hasLoading)
    }

    private func updateLoadingViewForHasNewMessage(hasLoading: Bool) {
        self.tableView.hasFooter = hasLoading
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resizeVMIfNeeded()
        guard view.superview != nil else {
            return
        }
        if self.bannerView.superview == nil {
            if let constraintItem = self.delegate?.getBannerTopConstraintItem() {
                self.addBannerViewWithTopConstraintItem(constraintItem)
            } else {
                assertionFailure("这里getBannerTopConstraintItem不应该为空")
                self.addBannerViewWithTopConstraintItem(self.tableView.snp.top)
            }
            if needLayoutTopUnReadView, let topView = self.topUnReadMessagesTipView {
                let hasBanner = (self.bannerView as? ChatBannerView)?.isDisplay ?? false
                self.updateTopUnReadMessagesTipViewConstraints(topView, hasBanner: hasBanner)
                needLayoutTopUnReadView = false
            }
        }
    }
}

// MARK: - observers
private extension ThreadChatController {
    private func preloadMoreMessages() {
        let maxDisplayZoneInFirstScreen = tableView.frame.height - tableView.contentInset.top
        if !messageViewModel.getCellsHeightOver(maxHeigh: maxDisplayZoneInFirstScreen) {
            ThreadChatController.logger.info("autoLoadNexPageData for firstSceent \(maxDisplayZoneInFirstScreen)")
            messageViewModel.loadMoreOldMessages()
            messageViewModel.loadMoreNewMessages()
        }
    }

    func observerMessageViewModel() {
        self.messageViewModel.tableRefreshDriver
            .drive(onNext: { [weak self] (refreshType) in
                ThreadChatController.logger.info("tableRefreshDriver refreshType \(refreshType)")
                switch refreshType {
                case .refreshTable:
                    self?.tableView.reloadData()
                case .initMessages(let info, _):
                    // 用户在拉取首屏期间没有发送消息，一定会走到此分支
                    self?.hiddenSkeletonTableView()
                    self?.setupUnreadTipView()
                    self?.refreshForInitMessages(initInfo: info)
                    ThreadPerformanceTracker.trackThreadLoadTime(chat: self?.chatViewModel.chat, pageName: Self.pageName)
                    self?.preloadMoreMessages()
                case .refreshMessages(hasHeader: let hasHeader, hasFooter: let hasFooter, scrollInfo: let scrollInfo):
                    self?.refreshForMessages(hasHeader: hasHeader, hasFooter: hasFooter, scrollTo: scrollInfo)
                case .messagesUpdate(indexs: let indexs, guarantLastCellVisible: let guarantLastCellVisible):
                    let indexPaths = indexs.map({ IndexPath(row: $0, section: 0) })
                    self?.tableView.refresh(indexPaths: indexPaths, guarantLastCellVisible: guarantLastCellVisible)
                case .loadMoreOldMessages(hasLoading: let hasLoading):
                    self?.appendOldMessages(hasLoading: hasLoading)
                case .loadMoreNewMessages(hasLoading: let hasLoading):
                    self?.appendNewMessages(hasLoading: hasLoading)
                case .hasNewMessage(hasLoading: let hasLoading):
                    // 用户在拉取首屏期间有成功发送消息，则会走到此分支
                    self?.hiddenSkeletonTableView()
                    self?.refreshForNewMessage()
                    self?.updateLoadingViewForHasNewMessage(hasLoading: hasLoading)
                case .updateHeaderView(hasHeader: let hasHeader):
                    self?.tableView.hasHeader = hasHeader
                case .updateFooterView(hasFooter: let hasFooter):
                    self?.tableView.hasFooter = hasFooter
                case .scrollTo(let scrollInfo):
                    let indexPath = IndexPath(row: scrollInfo.index, section: 0)
                    self?.tableView.scrollToRow(at: indexPath, at: scrollInfo.tableScrollPosition, animated: false)
                case .refreshMissedMessage:
                    self?.tableView.keepOffsetRefresh(nil)
                case .remain(hasLoading: let hasLoading):
                    self?.tableView.keepOffsetRefresh(nil)
                    self?.appendNewMessages(hasLoading: hasLoading)
                    self?.view.isUserInteractionEnabled = true
                }
                self?.updateOnboardingViewWithAnimation()
            }).disposed(by: self.disposeBag)

        self.messageViewModel.errorDriver.drive(onNext: { [weak self] (errorType) in
            guard let `self` = self else {
                return
            }
            switch errorType {
            case .jumpFail(let error):
                ThreadChatController.logger.error("LarkThread error: 消息跳转失败", error: error)
            case .loadMoreOldMsgFail(let error):
                ThreadChatController.logger.error("LarkThread error: 拉取历史消息失败", error: error)
                self.tableView.endTopLoadMore(hasMore: true)
            case .loadMoreNewMsgFail(let error):
                ThreadChatController.logger.error("LarkThread error: 拉取新消息失败", error: error)
                self.tableView.endBottomLoadMore(hasMore: true)
            }
        }).disposed(by: self.disposeBag)

        self.messageViewModel.enableUIOutputDriver.filter({ return $0 })
            .drive(onNext: { [weak self] _ in
                self?.tableView.reloadAndGuarantLastCellVisible(animated: true)
                self?.updateOnboardingViewWithAnimation()
            }).disposed(by: self.disposeBag)
    }

    /// 添加 VM 的 traitCollection 和 window.traitCollection 的订阅关系
    private func observeTraitCollection() {
        RootTraitCollection.observer
            .observeRootTraitCollectionWillChange(for: self)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] change in
                self?.messageViewModel.traitCollection = change.new
            }).disposed(by: disposeBag)
    }

    private func observerSendThreadStatus() {
        self.chatViewModel.postSendService
            .sendThreadStatusDriver.drive(onNext: { [weak self] (threadMessage, error) in
                guard let `self` = self else { return }
                self.chatViewModel.dependency.pushCenter.post(PushThreadMessages(messages: [threadMessage]))
                if let apiError = error?.underlyingError as? APIError {
                    switch apiError.type {
                    case .banned(let message):
                        UDToast.showFailure(with: message, on: self.view, error: apiError)
                    case .cloudDiskFull:
                        let alertController = LarkAlertController()
                        // 发送视频时alert疑似有冲突，必须使用from:
                        alertController.showCloudDiskFullAlert(from: self, nav: self.navigator)
                        //匿名失败发送失败后的提示
                    case .createAnonymousMessageNoMore(let message), .createAnonymousMessageSettingClose(let message):
                        UDToast.showFailure(with: message, on: self.view)
                    case .securityControlDeny(let message):
                        self.chatViewModel.dependency.chatSecurityControlService?.authorityErrorHandler(
                            event: .sendFile,
                            authResult: nil,
                            from: self,
                            errorMessage: message)
                    case .invalidMedia(_):
                        self.alertService?.showResendAlertForThread(error: error,
                                                                    message: threadMessage,
                                                                    fromVC: self)
                    case .strategyControlDeny: // 鉴权的策略引擎返回的报错，安全侧弹出弹框，端上做静默处理
                        break
                    default:
                        UDToast.showFailure(
                            with: BundleI18n.LarkThread.Lark_Legacy_ErrorMessageTip,
                            on: self.view,
                            error: apiError
                        )
                    }
                    return
                }
                if let error = error {
                    UDToast.showFailure(
                        with: BundleI18n.LarkThread.Lark_Legacy_ErrorMessageTip,
                        on: self.view,
                        error: error
                    )
                }
        }).disposed(by: self.disposeBag)

        let chatId = chatViewModel.chat.id
        self.sendMessageStatusDriver?
            .filter({ (messgae, _) in
                return messgae.channel.id == chatId
            })
            .drive(onNext: { [weak self] (_, error) in
                guard let self = self else { return }
                if let error = error {
                    UDToast.showFailure(
                        with: BundleI18n.LarkThread.Lark_Legacy_ErrorMessageTip,
                        on: self.view,
                        error: error
                    )
                }
            }).disposed(by: self.disposeBag)
    }

    private func observerChatViewModel() {
        self.chatViewModel.deleteMeFromChannelDriver
            .asObservable()
            .take(1)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (content) in
                guard let `self` = self else { return }

                let alertController = LarkAlertController()
                alertController.setContent(text: content)
                alertController.addPrimaryButton(text: BundleI18n.LarkThread.Lark_Legacy_IKnow, dismissCompletion: { [weak self] in
                    self?.chatViewModel.removeFeedCard()
                    DispatchQueue.main.async {
                        self?.leaveThreadController()
                    }
                })
                self.navigator.present(alertController, from: self)
            }).disposed(by: self.disposeBag)

        /// 翻译设置变了，需要刷新界面
        chatViewModel.dependency.userGeneralSettings.translateLanguageSettingDriver.skip(1)
            .drive(onNext: { [weak self] (_) in
                /// 清空一次标记
                self?.chatViewModel.dependency.translateService.resetMessageCheckStatus(key: self?.chatViewModel.chat.id ?? "")
                self?.tableView.displayVisibleCells()
            }).disposed(by: self.disposeBag)

        /// 自动翻译开关变了，需要刷新界面
        chatViewModel.chatAutoTranslateSettingDriver.drive(onNext: { [weak self] () in
            /// 清空一次标记
            self?.chatViewModel.dependency.translateService.resetMessageCheckStatus(key: self?.chatViewModel.chat.id ?? "")
            self?.tableView.displayVisibleCells()
        }).disposed(by: self.disposeBag)

        self.chatViewModel.localLeaveGroupChannel
            .filter { $0.status == .success }
            .drive(onNext: { [weak self] (_) in
                self?.leaveThreadController()
            }).disposed(by: disposeBag)

        chatViewModel.chatLastPositionDriver
            .drive(onNext: { [weak self] () in
                guard let `self` = self else { return }
                self.messageViewModel.updateNewMessageLoadingView()
            }).disposed(by: self.disposeBag)

        chatViewModel.chatIsAllowPost
            .drive(onNext: { [weak self] (isAllowPost) in
                guard let `self` = self else { return }
                if isAllowPost {
                    self.updateOnboardingViewWithAnimation()
                } else {
                    self.onboardingView?.removeFromSuperview()
                    self.onboardingView = nil
                }
            }).disposed(by: disposeBag)

        chatViewModel.offlineChatUpdateDriver
            .drive(onNext: { [weak self] (chat) in
                //如果显示的最后一条消息小于当前chat的lastVisibleThreadPosition，说明离线期间有离线消息
                if let lastPosition = self?.messageViewModel.threads.last?.position,
                    lastPosition < chat.lastVisibleThreadPosition {
                    ThreadChatController.logger.info("offlineChatUpdateDriver \(lastPosition) \(lastPosition)")
                    //尝试加载更多一页消息
                    self?.messageViewModel.loadMoreNewMessages()
                }
            }).disposed(by: disposeBag)

        chatViewModel.chatIsFrozen
            .drive { [weak self] _ in
                self?.showFrozenMask = true
                self?.updateTableConstraints()
            }.disposed(by: disposeBag)

        self.addTopNoticeObserver()
        observeSwitchTeamChatMode()
        chatViewModel.chatFirstMessagePositionDriver
            .drive(onNext: { [weak self] in
                self?.messageViewModel.adjustMinMessagePosition()
            }).disposed(by: disposeBag)
    }

    private func leaveThreadController() {
        /// 这里判断 iPad 情况下，thread VC 是否是 Nav rootVC, 如果是，直接 showDetail
        /// UDTab里也会创建一个Controller，通过self找层级会找错，需要由外部传入的container去找
        let targetVC = containerVC ?? self
        if Display.pad,
           targetVC.navigationController?.viewControllers.first == targetVC {
            let currentSplitVC = self.larkSplitViewController
            let showDefaultVC = { [weak self, weak currentSplitVC] in
                guard let `self` = self else { return }
                if let fromVC = currentSplitVC {
                    self.navigator.showDetail(
                        DefaultDetailController(),
                        wrap: LkNavigationController.self,
                        from: fromVC,
                        completion: nil
                    )
                } else {
                    if #available(iOS 13.0, *) {
                        /// 删除独立 scene
                        if let sceneInfo = self.currentScene()?.sceneInfo,
                           !sceneInfo.isMainScene() {
                            SceneManager.shared.deactive(from: self)
                        }
                    }
                }
            }

            if let navigationController = self.navigationController,
                navigationController.presentedViewController != nil {
                navigationController.dismiss(animated: true, completion: {
                    showDefaultVC()
                })
            } else {
                showDefaultVC()
            }
        } else {
            self.popSelf()
        }
    }

    private func refreshForInitMessages(initInfo: InitMessagesInfo) {
        self.refreshForMessages(hasHeader: initInfo.hasHeader, hasFooter: initInfo.hasFooter, scrollTo: initInfo.scrollInfo)
        switch initInfo.initType {
        case .recentLeftMessage:
            let cell = self.tableView.getVisibleCell(by: self.messageViewModel.chatWrapper.chat.value.lastReadPosition)
            if let cell = cell {
                let frame = self.view.convert(cell.frame, from: self.tableView)
                let contentOffsetY = min(self.tableView.tableViewOffsetMaxY(), self.tableView.contentOffset.y + (frame.minY - CGFloat(self.messageViewModel.chatWrapper.chat.value.lastReadOffset)))
                if contentOffsetY > 0 {
                    self.tableView.contentOffset.y = contentOffsetY
                }
            }
            break
        default:
            ThreadChatController.logger.info("self.messageViewModel.publicInitType = \(initInfo.initType)")
            break
        }
    }

    //刷新，滚动到指定消息
    func refreshForMessages(hasHeader: Bool, hasFooter: Bool, scrollTo: ScrollInfo?) {
        self.tableView.hasHeader = hasHeader
        self.tableView.hasFooter = hasFooter
        self.tableView.reloadData()
        if let scrollTo = scrollTo {
            ThreadChatController.logger.info("will scrollToRow index \(scrollTo.index) contentSize \(self.tableView.contentSize)")
            self.tableView.willDisplayEnable = false
            self.tableView.layoutIfNeeded()
            self.tableView.willDisplayEnable = true
            self.tableView.scrollToRow(at: IndexPath(row: scrollTo.index, section: 0), at: scrollTo.tableScrollPosition, animated: false)
            self.tableView.displayVisibleCells()
            ThreadChatController.logger.info("did scrollToRow index \(scrollTo.index) contentSize \(self.tableView.contentSize)")
        }
    }

    //刷新，如果屏幕在最底端，还要滚动一下，保证新消息上屏
    func refreshForNewMessage() {
        // 应用后台 或者 应用处于DidDisappear状态，不需要保证新消息上屏
        if UIApplication.shared.applicationState == .background || viewDidDisappear {
            self.tableView.reloadData()
        } else {
            self.tableView.reloadAndGuarantLastCellVisible(animated: true)
        }
    }
}

// MARK: - UnReadMessagesTipViewDelegate
extension ThreadChatController: UnReadMessagesTipViewDelegate {
    func tipWillShow(tipView: BaseUnReadMessagesTipView) {
        let newUnreadTipView: BaseUnReadMessagesTipView? = self.downUnReadMessagesTipView
        var oldUnreadTipView: BaseUnReadMessagesTipView? = self.topUnReadMessagesTipView
        // feature: new unread message is exsit. old unread message hide. 新消息气泡显示后，旧气泡在本次会话期间就不会再显示了，销毁
        if tipView == newUnreadTipView, oldUnreadTipView != nil {
            oldUnreadTipView?.removeFromSuperview()
            oldUnreadTipView = nil
        }
    }

    func tipCanShow(tipView: BaseUnReadMessagesTipView) -> Bool {
        //首屏加载中气泡不要显示
        guard self.messageViewModel.firstScreenLoaded else {
            return false
        }
        if tipView == self.downUnReadMessagesTipView {
            if self.tableView.hasFooter {
                return true
            }
            if self.tableView.stickToBottom() {
                return false
            }
        }
        return true
    }

    func scrollToBottommostMessage(tipView: BaseUnReadMessagesTipView, finish: @escaping () -> Void) {
        self.unreadTipViewClickedFunc()
        self.jumpToBottommostMessage(true, finish: finish)
        ThreadTracker.trackTipClick(tipState: tipView.unReadTipState,
                                    tipViewType: .down)
    }

    func scrollToToppestUnReadMessage(tipView: BaseUnReadMessagesTipView, finish: @escaping () -> Void) {
        self.unreadTipViewClickedFunc()
        self.jumpToBottommostMessage(false, finish: finish)
        ThreadTracker.trackTipClick(tipState: tipView.unReadTipState,
                                    tipViewType: .up)
    }

    /// 跳转到"@我/@所有人"消息
    public func scrollTo(message: MessageInfoForUnReadTip, tipView: BaseUnReadMessagesTipView, finish: @escaping () -> Void) {
        Self.logger.info("chatTrace scroll to message position: \(message.position)")
        self.tableView.setContentOffset(self.tableView.contentOffset, animated: false)
        self.messageViewModel.jumpTo(threadPosition: message.position, scrollPosition: .top, finish: finish)
    }
}

// MARK: - ThreadChatTableViewDelegate
extension ThreadChatController: ThreadChatTableViewDelegate {

    var hasDisplaySheetMenu: Bool {
        guard let menuService = self.context.pageContainer.resolve(MessageMenuOpenService.self) else {
            return false
        }
        return menuService.hasDisplayMenu && menuService.isSheetMenu
    }

    /// cell选中后应该隐藏Menu
    func tableviewDidSelectRowAt(indexPath: IndexPath) {
        self.messageSelectControl?.dismissMenuIfNeeded()
    }

    func threadWillDisplay(thread: RustPB.Basic_V1_Thread) {
        let oldTipView: BaseUnReadMessagesTipView? = self.topUnReadMessagesTipView
        (oldTipView?.viewModel as? UnReadOldThreadsTipViewModel)?.updateThreadRead(badgeCount: thread.badgeCount, position: thread.position)
    }

    func menuCustomInserts() -> UIEdgeInsets {
        if self.tableView.contentOffset.y < 0 {
            return UIEdgeInsets(top: -self.tableView.contentOffset.y, left: 0, bottom: 0, right: 0)
        }
        return .zero
    }

    func showTopLoadMore(status: ScrollViewLoadMoreStatus) {
        switch status {
        case .start:
            self.messageViewModel.topLoadMoreReciableKeyInfo = LoadMoreReciableKeyInfo.generate(page: ThreadChatController.pageName)
        case .finish:
            break
        }
    }

    func showBottomLoadMore(status: ScrollViewLoadMoreStatus) {
        switch status {
        case .start:
            self.messageViewModel.bottomLoadMoreReciableKeyInfo = LoadMoreReciableKeyInfo.generate(page: ThreadChatController.pageName)
        case .finish:
            break
        }
    }

    func chatModel() -> Chat {
        return self.chatViewModel.chat
    }
}

// MARK: - PageAPI
extension ThreadChatController: PageAPI {
    func viewWillEndDisplay() {
        messageViewModel.uiOutput(enable: false, indentify: "maskByCell")
        self.tableView.endDisplayVisibleCells()
    }

    func viewDidDisplay() {
        messageViewModel.uiOutput(enable: true, indentify: "maskByCell")
        self.tableView.displayVisibleCells()
    }

    var pageSupportReply: Bool {
        return false
    }

    func insertAt(by chatter: Chatter?) {

    }

    func reply(message: Message, partialReplyInfo: PartialReplyInfo?) {

    }

    func reedit(_ message: Message) {
        assert(false, "Thread 目前不需要撤回重新编辑，如果做新的Feature，实现当前方法即可")
    }

    func multiEdit(_ message: Message) {
        showPostView(multiEditingMessage: message)
    }

    func getSelectionLabelDelegate() -> LKSelectionLabelDelegate? {
        return self.messageSelectControl
    }
}

// MARK: - Onboarding
extension ThreadChatController {
    /// 触发消息添加时需要更新 onboardingView
    private func updateOnboardingViewWithAnimation() {
        guard let plusButton = self.plusButton else { return }
        let hasMore = self.messageViewModel.hasMoreOldMessages() ||
        self.messageViewModel.hasMoreNewMessages()
        if hasMore || // 可以加载更多
            self.messageViewModel.needFetchMissedData || // 正在请求miss数据
            self.messageViewModel.totalSystemCellHeight == nil || // 所有系统消息cell高度为nil时表示存在话题卡片cell
            !chatViewModel.chat.isAllowPost || // 禁言
            self.chatViewModel.onBoardingClosed { // 主动关闭过
            onboardingView?.removeFromSuperview()
            tableView.backgroundColor = UIColor.ud.bgBase
            return
        }
        ThreadChatController.logger.info("ThreadOnboradingView add onboardingView")
        let onboardingH = ThreadNewOnboardingView.font.rowHeight + ThreadNewOnboardingView.labelVerticalOffset * 2
        if onboardingView?.superview == nil {
            onboardingView?.removeFromSuperview()
            let onboardingView = ThreadNewOnboardingView()
            view.addSubview(onboardingView)
            onboardingView.layer.cornerRadius = onboardingH / 2
            onboardingView.layer.ud.setShadow(type: .s2Down)
            onboardingView.backgroundColor = UIColor.ud.bgBody
            onboardingView.closeHandler = { [weak self] in
                guard let self = self else { return }
                self.chatViewModel.onBoardingClosed = true
                self.onboardingView?.removeFromSuperview()
                self.onboardingView = nil
                ThreadChatController.logger.info("close onboarding for \(self.chatViewModel.chat.id)")
            }
            self.onboardingView = onboardingView
            onboardingView.snp.makeConstraints { (make) in
                make.height.equalTo(onboardingH)
                make.leading.greaterThanOrEqualToSuperview().offset(16)
                make.trailing.equalTo(plusButton.snp.leading).offset(PlusButtonControl.buttonInset - 8)
                make.bottom.equalTo(plusButton.snp.top)
            }
        } else {
            onboardingView?.snp.remakeConstraints { (make) in
                make.height.equalTo(onboardingH)
                make.leading.greaterThanOrEqualToSuperview().offset(16)
                make.trailing.equalTo(plusButton.snp.leading).offset(PlusButtonControl.buttonInset - 8)
                make.bottom.equalTo(plusButton.snp.top)
            }
        }
    }
}

// MARK: - EnterpriseEntityWordProtocol
extension ThreadChatController: EnterpriseEntityWordDelegate {

    func lockForShowEnterpriseEntityWordCard() {
        ThreadChatController.logger.info("ThreadChatController: pauseQueue for enterprise entity word card show")
        messageViewModel.pauseQueue()
    }

    func unlockForHideEnterpriseEntityWordCard() {
        ThreadChatController.logger.info("ThreadChatController: resumeQueue for after enterprise entity word card hide")
        messageViewModel.resumeQueue()
    }
}

extension ThreadChatController: GCUnitDelegate {
    func gc(limitWeight: Int64, callback: GCUnitDelegateCallback) {
        guard let range = tableView.visiblePositionRange() else { return }
        self.view.isUserInteractionEnabled = false
        let postion: Int32 = range.bottom
        messageViewModel.removeMessages(afterPosition: postion, redundantCount: 5) {  //留5个消息的冗余
            callback.end(currentWeight: Int64($0))
        }
        ThreadChatController.logger.info("chatTrace in GC \(self.chatViewModel.chat.id) \(postion)")
    }
}

extension ThreadChatController: UDTabsListContainerViewDelegate {
    func listView() -> UIView {
        return self.view
    }

    func listVC() -> UIViewController? {
        return self
    }
}

// MARK: - banner相关
extension ThreadChatController: ThreadChatTapPageAPI {
    func setUpdateTopNotice(updateNotice: @escaping ((ChatTopNotice?) -> Void)) {
        self.delegate?.topNoticeManager().addTopNotice(listener: updateNotice)
    }
}

// MARK: - ThreadChatVC 对 OpenIM 架构暴露的关于Messages的能力
extension ThreadChatController: ChatMessagesOpenService {
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

// MARK: - 处理团队公开群 用户身份转换逻辑
extension ThreadChatController {
    private func observeSwitchTeamChatMode() {
        chatViewModel.teamChatModeSwitchDriver.drive(onNext: { [weak self] (change) in
            guard let self = self else { return }
            switch change {
            case .none: break
            case .visitorToMember: self.refreshGroup()
            case .memberToVisitor: self.showSwitchTeamChatModeAlert()
            }
        }).disposed(by: disposeBag)
    }

    private func showSwitchTeamChatModeAlert() {
        let dialog = UDDialog()
        dialog.setContent(text: BundleI18n.LarkThread.Lark_IM_YouAreNotInThisChat_Text)
        dialog.addPrimaryButton(text: BundleI18n.LarkThread.Lark_Legacy_IKnow, dismissCompletion: { [weak self] in
            self?.refreshGroup()
        })
        navigator.present(dialog, from: self)
     }

    // 关闭掉chat，然后重新进入chat
    private func refreshGroup() {
        let chat = chatViewModel.chat
        var completion: (() -> Void)?
        if let vc = self.navigationController {
            completion = { [weak self, weak vc] in
                guard let self, let vc = vc else { return }
                Self.logger.info("threadTrace/teamlog/refreshGroup/enter id:  \(chat.id)")
                let body = ChatControllerByBasicInfoBody(chatId: chat.id,
                                                         fromWhere: .teamOpenChat,
                                                         isCrypto: chat.isCrypto,
                                                         isMyAI: chat.isP2PAi,
                                                         chatMode: chat.chatMode)
                self.navigator.showDetailOrPush(body: body,
                                                  wrap: LkNavigationController.self,
                                                  from: vc,
                                                  animated: false)
            }
        }
        Self.logger.info("threadTrace/teamlog/refreshGroup/exist id: \(chat.id)")
        popSelf(animated: false, dismissPresented: true, completion: completion)
    }
}
