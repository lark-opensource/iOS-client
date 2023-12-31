//
//  ThreadContainerController.swift
//  LarkThread
//
//  Created by lizhiqiang on 2019/8/16.
//

import UIKit
import Foundation
import RxCocoa
import RxSwift
import SnapKit
import LarkCore
import LarkUIKit
import LarkBadge
import LarkModel
import EENavigator
import LarkMessageCore
import LarkMessageBase
import LKCommonsLogging
import LarkMessengerInterface
import LarkOpenFeed
import LarkFeatureGating
import AppReciableSDK
import LarkSplitViewController
import LarkTraitCollection
import LarkSDKInterface
import LarkSceneManager
import UniverseDesignToast
import LarkSuspendable
import UniverseDesignTabs
import LarkOpenChat
import LarkContainer

// MARK: - ThreadContainerController
typealias GetThreadChatController = (ThreadContentConfig, @escaping () -> Void) throws -> ThreadChatController
typealias GetNavigationBar = (Chat, Bool) throws -> ChatNavigationBar
typealias GetFilterController = (ThreadContentConfig) throws -> ThreadFilterController

final class ThreadContainerController: BaseUIViewController, UserResolverWrapper {
    var userResolver: UserResolver { viewModel.userResolver }

    init(viewModel: ThreadContainerViewModel,
         intermediateStateControl: InitialDataAndViewControl<(Chat, TopicGroup), Void>,
         getNaviBar: @escaping GetNavigationBar,
         getThreadsController: @escaping GetThreadChatController,
         getFilterThreadsController: @escaping GetFilterController) {
        ThreadPerformanceTracker.startUIRender()
        self.intermediateStateControl = intermediateStateControl
        self.viewModel = viewModel
        self.getNavigationBar = getNaviBar
        self.getThreadsController = getThreadsController
        self.getFilterThreadsController = getFilterThreadsController
        super.init(nibName: nil, bundle: nil)
        if viewModel.useIntermediateEnable {
            self.startInitialDataAndViewControl()
        }
        self.updateSceneTargetContentIdentifier()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var sourceID: String = UUID().uuidString

    private var edgeNaviAnimation: EdgeNaviAnimator?

    @ScopedInjectedLazy private var chatDurationStatusTrackService: ChatDurationStatusTrackService?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.naviBar?.viewWillAppear()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.naviBar?.viewDidAppear()
        chatDurationStatusTrackService?.markIfViewControllerIsAppear(value: true)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        chatDurationStatusTrackService?.markIfViewControllerIsAppear(value: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.supportSecondaryOnly = true
        self.supportSecondaryPanGesture = true
        self.keyCommandToFullScreen = true
        self.fullScreenSceneBlock = { "channel" }
        self.view.backgroundColor = UIColor.ud.bgBase
        self.isNavigationBarHidden = true
        // 如果已经有了chat和topicGroup数据，直接开始构造界面
        if !viewModel.useIntermediateEnable,
            let chatPushWrapper = self.viewModel.chatWrapper,
            let topicGroupPushWrapper = self.viewModel.topicGroupPushWrapper {
            self.setupView(with: chatPushWrapper, topicGroupPushWrapper: topicGroupPushWrapper)
        } else {
            self.intermediateStateControl.viewDidLoad()
        }
        self.observeToUpdateSceneTitle()
        chatDurationStatusTrackService?.setGetChatBlock { [weak self] in
                return self?.viewModel.chat
        }
    }

    // MARK: private
    private static let logger = Logger.log(ThreadContainerController.self, category: "Thread.Container")
    private let disposeBag = DisposeBag()
    private var naviBar: ChatNavigationBar?
    private let getNavigationBar: GetNavigationBar
    private let viewModel: ThreadContainerViewModel
    private let getThreadsController: GetThreadChatController
    private let getFilterThreadsController: GetFilterController

    private var loadingView: GroupIntermediateSkeletionView?
    private let intermediateStateControl: InitialDataAndViewControl<(Chat, TopicGroup), Void>

    private var joinGroupFooter: ApplyToJoinGroupView?

    /// 水印waterMarkView
    var waterMarkView: UIView?

    private lazy var navBarHeight: CGFloat = {
        var statusBarHeight: CGFloat = UIApplication.shared.statusBarFrame.height
        // statusbar隐藏的情况
        if statusBarHeight <= 0 {
            statusBarHeight = (Display.iPhoneXSeries ? 44 : 20)
        }
        return statusBarHeight + (self.naviBar?.naviBarHeight ?? 44)
    }()

    /// key: type；value: 全部、已订阅、我参与的控制器
    private var tabControllers = [TabItemType: UDTabsListContainerViewDelegate]()
    private var tabModels: [TabItemBaseModel] = []
    private var tabsView: ThreadTabsView?
    private lazy var listContainerView: UDTabsListContainerView = {
        return UDTabsListContainerView(dataSource: self)
    }()

    private var threadAnounmentView: ThreadChatHeader?

    private func startInitialDataAndViewControl() {
        self.intermediateStateControl.start { [weak self] (result) in
            switch result {
            case .success(let status):
                ThreadContainerController.logger.info("ProcessStatus is \(status)")
                switch status {
                // 获取到了Chat和TopicGroup
                case .blockDataFetched(data: let data):
                    self?.viewModel.ready(chat: data.0, topicGroup: data.1)
                // 开始构造界面
                case .inNormalStatus:
                    guard let chatPushWrapper = self?.viewModel.chatWrapper,
                          let topicGroupPushWrapper = self?.viewModel.topicGroupPushWrapper else {
                        ThreadContainerController.logger.error("block data is empty error \(self?.viewModel.chatID ?? "")")
                        return
                    }
                    self?.setupView(with: chatPushWrapper, topicGroupPushWrapper: topicGroupPushWrapper)
                    self?.hideLoadingView()
                    ThreadPerformanceTracker.endUIRender()
                // 显示中间态界面
                case .inInstantStatus:
                    self?.showLoadingView()
                    ThreadPerformanceTracker.endUIRender()
                }
            case .failure(let error):
                AppReciableSDK.shared.error(params: ErrorParams(biz: .Messenger,
                                                                scene: .Thread,
                                                                event: .enterChat,
                                                                errorType: .SDK,
                                                                errorLevel: .Exception,
                                                                errorCode: 1,
                                                                userAction: nil,
                                                                page: ThreadChatController.pageName,
                                                                errorMessage: nil,
                                                                extra: Extra(isNeedNet: false,
                                                                             latencyDetail: [:],
                                                                             metric: ThreadPerformanceTracker.reciableExtraMetric(nil),
                                                                             category: ThreadPerformanceTracker.reciableExtraCategory(nil, type: .Thread))))
                ThreadContainerController.logger.error("fetchTopicGroup error \(self?.viewModel.chatID ?? "")", error: error)
            }
        }
    }

    private func addObservers() {
        // 设置红点
        observeBadge()
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

    private func fetchChatData() {
        /// 进入话题群的时候 拉取更新一下群公告的内容,确保下次进入展示最新的群公告
        self.viewModel.chatAPI?.fetchChat(by: self.viewModel.chatID, forceRemote: true).subscribe(onNext: { (_) in
        }).disposed(by: disposeBag)
    }

    private func showLoadingView() {
        let loadingView = GroupIntermediateSkeletionView(backButtonClickedBlock: { [weak self] in
            guard let `self` = self else {
                assertionFailure("缺少 From VC")
                return
            }
            self.navigator.pop(from: self)
        })
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        loadingView.startLoading()
        self.loadingView = loadingView
    }

    private func hideLoadingView() {
        loadingView?.stopLoading()
        loadingView?.removeFromSuperview()
    }

    private func configData() {
        // 默认选中第一个标签
        self.tabsView?.selectItemAt(index: 0, selectedType: .code)
    }

    fileprivate func showShareController() {
        let body = ShareChatViaLinkBody(chatId: viewModel.chatID)
        navigator.open(body: body, from: self)
    }

    // MARK: 状态栏
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }

    // MARK: 全屏按钮
    override func splitSplitModeChange(splitMode: SplitViewController.SplitMode) {
        self.naviBar?.splitSplitModeChange(splitMode: splitMode)
    }
}

// MARK: - setupView
extension ThreadContainerController {
    private func setupView(with chatPushWrapper: ChatPushWrapper, topicGroupPushWrapper: TopicGroupPushWrapper) {
        let chat = chatPushWrapper.chat.value
        let topicGroup = topicGroupPushWrapper.topicGroupObservable.value
        // 小组有自己的背景图片，ChatNavigationBar会有透出效果，需要禁掉，否则tabsView做弹性动画会有白边
        guard let navigationBar = try? self.getNavigationBar(chat, false) else {
            return
        }
        if #available(iOS 13.0, *), Display.phone {
            navigationBar.overrideUserInterfaceStyle = .light
        }
        navigationBar.loadSubModuleData()
        self.naviBar = navigationBar
        self.naviBar?.viewWillRealRenderSubView()
        // 加入小组
        view.addSubview(navigationBar)
        self.setupNaviBar()
        setupThreadTabs(with: chatPushWrapper, navigationBar: navigationBar)
        self.setupHeaderView()
        self.setupFooterView(navigationBar: navigationBar)

        // 添加全部控制器
        self.setupAllTabController(with: chat, topicGroup: topicGroup)

        view.bringSubviewToFront(navigationBar)
        self.configData()
        addObservers()
        fetchChatData()

        edgeNaviAnimation = EdgeNaviAnimator { [weak self] in
            self?.moreInfoItemClicked()
        }
        edgeNaviAnimation?.addGesture(to: view)
        IMTracker.Chat.Main.View(chatPushWrapper.chat.value, params: [:], nil)
    }

    private func setupNaviBar() {
        naviBar?.backgroundColor = UIColor.clear
        naviBar?.delegate = self
        naviBar?.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
        }
    }

    private func setupThreadTabs(with chatPushWrapper: ChatPushWrapper, navigationBar: ChatNavigationBar) {
        guard let chatAPI = self.viewModel.chatAPI else { return }
        // 构建全部，我订阅的tab
        self.tabModels = []
        let allTabItem = AllTabItemModel(itemType: .all,
                                         cellType: AllTabItemCell.self,
                                         title: BundleI18n.LarkThread.Lark_Chat_TopicFilterAll,
                                         chatObserverable: chatPushWrapper.chat)
        self.tabModels.append(allTabItem)
        if !(viewModel.chat?.isTeamVisitorMode ?? false) {
            let followTabItem = FollowTabItemModel(itemType: .follow,
                                                   cellType: FollowTabItemCell.self,
                                                   title: BundleI18n.LarkThread.Lark_Groups_TopicFilterFollowed)
            self.tabModels.append(followTabItem)
        }

        let tabsView = ThreadTabsView(tabModels: self.tabModels)
        tabsView.listContainer = self.listContainerView
        tabsView.delegate = self
        self.tabsView = tabsView
        let chat = chatPushWrapper.chat.value
        let viewModel = ThreadChatHeaderViewModel(
            userResolver: viewModel.userResolver,
            chatPushWrapper: chatPushWrapper,
            chatAPI: chatAPI,
            isDefaultTopicGroup: self.viewModel.isDefaultTopicGroup
        )
        // 涉及到动画的视图
        var relateAnimtaionViews = [UIView]()
        if let centerView = navigationBar.centerView {
            relateAnimtaionViews.append(centerView)
        }
        if let shareButton = navigationBar.getRightItem(type: .shareItem)?.view {
            relateAnimtaionViews.append(shareButton)
        }
        let threadAnounmentView = ThreadChatHeader(
            viewModel: viewModel,
            tabsView: tabsView,
            relateAnimtaionViews: relateAnimtaionViews,
            navBarHeight: self.navBarHeight
        )

        threadAnounmentView.addToView(self.view)
        self.threadAnounmentView = threadAnounmentView

        // 构建listContainerView，getThreadsController和getFilterThreadsController的构建依赖于threadAnounmentView
        // 所以listContainerView需要在threadAnounmentView之后初始化
        view.insertSubview(listContainerView, belowSubview: threadAnounmentView)
        listContainerView.snp.makeConstraints { (make) in
            make.top.equalTo(navigationBar.snp.bottom).offset(SegmentLayout.tabsHeight)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    private func setupHeaderView() {
        threadAnounmentView?.clickedAnnounceLabel = { [weak self] () in
            guard let `self` = self else { return }
            self.viewModel.pushChatAnnouncement(self, chatId: self.viewModel.chatID)
        }
        threadAnounmentView?.clickedShareButton = { [weak self] in
            self?.showShareController()
        }
    }

    private func setupFooterView(navigationBar: ChatNavigationBar) {
        guard let chat = viewModel.chat, chat.isTeamVisitorMode else { return }
        var footerTeamID: Int64?
        if case .team(let teamID) = viewModel.fromWhere {
            footerTeamID = teamID
        }
        let joinGroupFooter = ApplyToJoinGroupView(chat: chat, targetVC: self, teamID: footerTeamID, nav: self.navigator)
        self.joinGroupFooter = joinGroupFooter
        view.addSubview(joinGroupFooter)
        joinGroupFooter.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        listContainerView.snp.remakeConstraints { (make) in
            make.top.equalTo(navigationBar.snp.bottom).offset(SegmentLayout.tabsHeight)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(joinGroupFooter.snp.top)
        }
        self.view.layoutIfNeeded()
    }

    private func setupAllTabController(with chat: Chat, topicGroup: TopicGroup) {
        guard tabControllers[.all] == nil, let threadAnounmentView = self.threadAnounmentView else {
            Self.logger.error("can not create AllTabController: \(threadAnounmentView == nil) -> \(tabControllers.keys)")
            return
        }
        // 点击未读群公告
        let clickedUnreadView: () -> Void = { [weak self] in
            guard let `self` = self else {
                return
            }
            self.threadAnounmentView?.showHeaderView(false)
        }

        let config = ThreadContentConfig(topicGroup: topicGroup,
                                         chat: chat,
                                         navBarHeight: self.navBarHeight)
        guard let allThreadController = try? getThreadsController(config, clickedUnreadView) else { return }
        allThreadController.delegate = self
        allThreadController.containerVC = self
        tabControllers[.all] = allThreadController
    }

    private func setupFollowTabController(with chat: Chat, topicGroup: TopicGroup) {
        guard tabControllers[.follow] == nil, let threadAnounmentView = self.threadAnounmentView else {
            Self.logger.error("can not create FollowTabController: \(threadAnounmentView == nil) -> \(tabControllers.keys)")
            return
        }
        let config = ThreadContentConfig(topicGroup: topicGroup,
                                         chat: chat,
                                         navBarHeight: self.navBarHeight)
        guard let filterThreadsController = try? self.getFilterThreadsController(config) else { return }
        filterThreadsController.delegate = self
        tabControllers[.follow] = filterThreadsController
    }
}

// MARK: - ThreadContainerDelegate
extension ThreadContainerController: ThreadContainerDelegate {
    func updateShowTableView(tableView: UITableView) {
        self.threadAnounmentView?.updateTableViewObservers(tableView: tableView)
    }

    // listContainerView可能会被延迟加入view中，hostSize需要container提供
    var hostSize: CGSize {
        return self.navigationController?.view.bounds.size ?? self.view.bounds.size
    }

    func getBannerTopConstraintItem() -> ConstraintItem? {
        return self.threadAnounmentView?.snp.bottom
    }

    func topNoticeManager() -> ChatTopNoticeDataManager {
        return viewModel.topNoticeDataManger
    }
}

// MARK: - ChatNavigationBarDelegate
extension ThreadContainerController: ChatNavigationBarDelegate {
    func getSceneId() -> String {
        return self.viewModel.chatID
    }

    func getSceneKey() -> String {
        return "Chat"
    }

    func backItemClicked(sender: UIButton) {
        navigator.pop(from: self)
    }

    func openChatSetting(action: EnterChatSettingAction) {
        if let chat = self.viewModel.chat {
            IMTracker.Chat.Main.Click.Sidebar(chat, nil)
            if !chat.announcement.docURL.isEmpty {
                self.viewModel.preloadDocFeed(chat.announcement.docURL, from: chat.trackType + "_announcement")
            }
        }
        self.viewModel.pushChatInfo(from: self, action: action)
    }

    func moreInfoItemClicked() {
        openChatSetting(action: .chatMoreMobile)
    }
}

extension ThreadContainerController: ThreadNavgationBarContentDependency {
    public func forceShowAllStaffTag() -> Bool {
        guard let topicGroupPushWrapper = self.viewModel.topicGroupPushWrapper else { return false }
        return topicGroupPushWrapper.topicGroupObservable.value.isDefaultTopicGroup
    }

    public func titleClicked() {
        self.threadAnounmentView?.showHeaderView(true)
    }
}

extension ThreadContainerController: UDTabsViewDelegate {
    /// 点击选中或者滚动选中都会调用该方法。适用于只关心选中事件，而不关心具体是点击还是滚动选中的情况。
    func tabsView(_ tabsView: UDTabsView, didSelectedItemAt index: Int) {
        let unReadAnnounce = viewModel.chatWrapper?.chat.value.chatOptionInfo?.announce ?? false
        if !unReadAnnounce {
            self.threadAnounmentView?.showHeaderView(false)
        }
        ThreadContainerController.logger.info("DidAppear \(index)")
    }

    /// 手动点击会触发，代码跳转不会触发
    func tabsView(_ tabsView: UDTabsView, didClickSelectedItemAt index: Int) {
        guard index < self.tabModels.count else { return }
        let model = self.tabModels[index]
        // 如果点击的我订阅的，进行埋点
        if model.itemType == .follow, let chat = self.viewModel.chat {
            IMTracker.Chat.Main.Click.MySubscribe(chat)
        }
    }
}

// MARK: - Badge 相关
extension ThreadContainerController {
    private func observeBadge() {
        // chat页红点Root
        self.view.badge.observe(for: chatPath)
        // 该红点不显示，仅用于构造路径
        self.view.badge.set(type: .clear)
    }
}

extension ThreadContainerController {

    /// 刷新 scene title
    private func observeToUpdateSceneTitle() {
        guard SceneManager.shared.supportsMultipleScenes else {
            return
        }
        self.viewModel.chatWrapper?.chat
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

    private func updateSceneTargetContentIdentifier() {
        let scene = LarkSceneManager.Scene(
            key: "Chat",
            id: self.viewModel.chatID
        )
        self.sceneTargetContentIdentifier = scene.targetContentIdentifier
    }
}

// MARK: - 页面支持收入多任务浮窗

extension ThreadContainerController: ViewControllerSuspendable {

    var suspendID: String {
        return viewModel.chatID
    }

    var suspendSourceID: String {
        return sourceID
    }

    var suspendTitle: String {
        return viewModel.chat?.name ?? viewModel.chatID
    }

    var suspendIcon: UIImage? {
        return Resources.suspend_icon_group
    }

    var suspendIconKey: String? {
        return viewModel.chat?.avatarKey
    }

    var suspendIconEntityID: String? {
        return viewModel.chat?.id
    }

    var suspendURL: String {
        return "//client/chat/thread/by/id/\(viewModel.chatID)"
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
        return "circle"
    }
}

/// 处理右侧交互式转场动画与浮窗动画的冲突
extension ThreadContainerController {

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

extension ThreadContainerController: UDTabsListContainerViewDataSource {
    func numberOfLists(in listContainerView: UDTabsListContainerView) -> Int {
        return self.tabModels.count
    }

    func listContainerView(_ listContainerView: UDTabsListContainerView,
                           initListAt index: Int) -> UDTabsListContainerViewDelegate {
        guard index < self.tabModels.count else {
            Self.logger.error("index error -> \(self.tabModels.count) -> \(index) -> \(self.tabControllers.count)")
            return UnknownThreadTabContentView()
        }
        let itemType = self.tabModels[index].itemType
        if let targetVC = self.tabControllers[itemType] {
            return targetVC
        }
        guard let chat = self.viewModel.chatWrapper?.chat.value,
              let topicGroup = self.viewModel.topicGroupPushWrapper?.topicGroupObservable.value else {
            Self.logger.error("cannot create thread tabVC with nil chat or topicGroup")
            return UnknownThreadTabContentView()
        }
        switch itemType {
        case .all:
            setupAllTabController(with: chat, topicGroup: topicGroup)
            return tabControllers[.all] ?? UnknownThreadTabContentView()
        case .follow:
            setupFollowTabController(with: chat, topicGroup: topicGroup)
            return tabControllers[.follow] ?? UnknownThreadTabContentView()
        default:
            return UnknownThreadTabContentView()
        }
    }
}

extension ThreadContainerController: ChatOpenService {
    // "chat_id" 拼接\(chid_id)
    var chatPath: Path { return Path().prefix(Path().chat_id, with: viewModel.chatID) }

    func chatVC() -> UIViewController {
        return self
    }

    func chatTopNoticeChange(updateNotice: @escaping ((ChatTopNotice?) -> Void)) {
        (tabControllers[.all] as? ThreadChatTapPageAPI)?.setUpdateTopNotice(updateNotice: updateNotice)
    }

    /// 锁定顶部区域的的显隐
    func lockTopContainerCompressedStateTo(_ isCompressed: Bool) {
        if isCompressed {
            self.threadAnounmentView?.showHeaderView(false)
        }
    }
}

extension ThreadContainerController: FeedSelectionInfoProvider {
    func getFeedIdForSelected() -> String? {
        return self.viewModel.chatID
    }
}
