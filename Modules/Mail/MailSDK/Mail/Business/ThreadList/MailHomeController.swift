//
//  MailHomeController.swift
//  LarkMail
//
//  Created by 谭志远 on 2019/5/15.
//

import Foundation
import LarkUIKit
import EENavigator
import Reachability
import LKCommonsLogging
import RxSwift
import Homeric
import LarkAlertController
import RustPB
import LarkKeyCommandKit
import LarkFoundation
import ESPullToRefresh
import RxRelay
import LarkGuideUI
import LarkInteraction
import LarkTraitCollection
import LarkSplitViewController
import LarkAppLinkSDK
import LarkSwipeCellKit
import UniverseDesignIcon
import UniverseDesignShadow
import AnimatedTabBar
import UniverseDesignTheme
import UniverseDesignDialog

private typealias mailHomeConst = MailHomeControllerConst
struct MailHomeControllerConst {
    static let CellHeight: CGFloat = 94
    static let CellWithReaction: CGFloat = CellHeight + 28
    static let CellAttachmentHeight: CGFloat = 40
    static let CellStrangerCardDefaultHeight: CGFloat = 200
    static let CellStrangerCardHeight: CGFloat = 220
}

class MailHomeController: MailCustomNavbarViewController,
                          UITableViewDelegate, UITableViewDataSource,
                          MailThreadListCellDelegate,
                          TabBarDelegate, MailLongPressDelegate, MailCreateDraftButtonDelegate,
                          MailClientSettingDelegate, MailMessageListExternalDelegate {
    // MailBaseViewController { //
    static let logger = Logger.log(MailHomeController.self, category: "Module.MailHomeController")
    var disposeBag = DisposeBag()
    var redDotDisposeBag = DisposeBag()
    var titleDisposeBag = DisposeBag()

    var loadingDisposeBag: DisposeBag = DisposeBag()
    var delayLoadingBag: DisposeBag? = DisposeBag()

    var mainBindDisposeBag = DisposeBag()
    var listDisposeBag = DisposeBag()
    var strangerDisposeBag = DisposeBag()
    var doubleTabDisposeBag = DisposeBag()
    var loadMoreDone = false
    // swiftlint:disable weak_delegate

    weak var displayDelegate: TarBarDisplayDelegate?
    // swiftlint:enable weak_delegate
    var currentLabelIsFirstShow = true
    var senderBlocker: BlockSenderManager?
    static let switchableListDidScrollToTop = Notification.Name(rawValue: "switchableListDidScrollToTop")

    var showLarkNavbar: Bool = true {
        didSet {
            reloadNavbar()
        }
    }
    let showLarkNavbarFlag = BehaviorRelay(value: true)

    var navBarLoading = BehaviorRelay(value: false)

    lazy var navBarTitleBehavior = BehaviorRelay(value: BundleI18n.MailSDK.Mail_Normal_Email)

    // 确认同步的最早文件是否是你的邮箱最早的一封邮件
    var clientMigrationTipsVC: MailMigrationTipsViewController?
    var dualVC: MailDualViewController?
    weak var navbarBridge: MailNavBarBridge?
//    /// 用于接收mail为首tab时首屏渲染。
    var hasFirstScreenRender = false
    let _firstScreenDataReady = BehaviorRelay<Bool>(value: false)
    //  读信预加载场景列表数据完备通知
    let refreshListDataReady = BehaviorRelay<(MailThreadListRefreshListScene, Bool)>(value: (.unknown, false))

    // MARK: - view models
    var viewModel: MailHomeViewModel

    lazy var headerViewManager: ThreadListHeaderManager = {
        let manager = ThreadListHeaderManager(userContext: userContext)
        manager.delegate = self
        return manager
    }()

    // MARK: UI Widget
    lazy var arrowView: MailArrowView = MailArrowView.makeDefaultView()

    var accountListMenu: MailAccountListController?

    lazy var tableView: MailHomeTableView = self.makeTabelView()

    private(set) lazy var sendMailButton: UIButton = self.makeSendMailButton()

    lazy var threadActionBar: ThreadActionsBar = self.makeThreadActionBar()
    func makeThreadActionBar() -> ThreadActionsBar {
        let actionBar = ThreadActionsBar(frame: .zero, accountContext: self.userContext.getCurrentAccountContext())
        actionBar.fromLabelID = viewModel.currentLabelId
        actionBar.actionDelegate = self
        actionBar.backBlock = { [weak self] in
            self?.viewModel.syncDataSource()
            self?.tableView.reloadData()
        }
        return actionBar
    }

    private lazy var _mailBaseLoadingView: MailBaseLoadingView = {
        let loading = MailBaseLoadingView()
        loading.isHidden = true
        self.mailLayoutPlaceHolderView(placeholderView: loading)
        return loading
    }()

    var mailLoadingPlaceholderView: MailBaseLoadingView {
        guard let larkNavibar = navbarBridge?.getLarkNaviBar() else {
            return _mailBaseLoadingView
        }
        self.view.insertSubview(_mailBaseLoadingView, belowSubview: larkNavibar)
        return _mailBaseLoadingView
    }

    func mailLayoutPlaceHolderView(placeholderView: UIView) {
        self.view.addSubview(placeholderView)
        placeholderView.snp.makeConstraints { (make) in
            make.center.width.height.equalToSuperview()
        }
    }
    
    lazy var navSearchButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.searchOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.ud.iconN1
        button.rx.tap
            .subscribe(onNext: { [weak self] _ in self?.onSelectSearch() })
            .disposed(by: disposeBag)
        button.accessibilityIdentifier = MailAccessibilityIdentifierKey.BtnHomeSearch
        return button
    }()

    lazy var navMoreButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.moreOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.ud.iconN1
        button.rx.tap
            .subscribe(onNext: { [weak self] _ in self?.showMoreAction() })
            .disposed(by: disposeBag)
        button.accessibilityIdentifier = MailAccessibilityIdentifierKey.BtnHomeMore
        return button
    }()

    lazy var navFilterButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.filterOutlined.ud.withTintColor(UIColor.ud.primaryContentDefault), for: .normal)
        button.setImage(UDIcon.filterOutlined.ud.withTintColor(UIColor.ud.iconN2), for: .selected)
        button.tintColor = UIColor.ud.iconN1
        button.rx.tap
            .subscribe(onNext: { [weak self] _ in self?.didClickFilterButton() })
            .disposed(by: disposeBag)
        button.accessibilityIdentifier = MailAccessibilityIdentifierKey.BtnHomeFilter
        button.layer.cornerRadius = 4
        button.clipsToBounds = true
        return button
    }()
    lazy var multiAccountView: MailMultiAccountView = {
        let view = MailMultiAccountView()
        view.clipsToBounds = true
        view.delegate = self
        return view
    }()

    /// use to cache template
    private var templateRender: MailMessageListTemplateRender?

    // Refresh
    let header = MailRefreshHeaderAnimator.init(frame: CGRect.zero)
    var esHeaderView: ESRefreshHeaderView?
    let footer = MailLoadMoreRefreshAnimator.init(frame: CGRect.zero)
    var timer: Timer? = Timer()
    var loadingInterval = 0.0
    var didCongfigRefresh: Bool = false

    // scroll
    var lastDragOffset: CGFloat?
    var lastContentOffsetY: CGFloat = 0
    var didChangeOffsetInMultiSelectMode = (false, false)
    var shouldCheckNavigationBarVisibility = true
    var scrollingToTop = false
    var shouldShowOauthPage = false {
        didSet {
            MailLogger.info("[mailTab] shouldShowOauthPage: \(shouldShowOauthPage)")
            if oldValue != shouldShowOauthPage {
                MailLogger.info("[mailTab] shouldShowOauthPage changed: \(shouldShowOauthPage)")
                exitMultiSelect()
                reloadNavbar()
            }
        }
    }

    // switch
    lazy var isSmartInboxEnable = false
    var displaysAsynchronously = false
    var clearContentsBeforeAsynchronouslyDisplay = false
    lazy var asyncRender = userContext.featureManager.open(.asyncRender)

    var conversationGuideMode: Bool = false

    // MARK: Data
    var currentAccountID = ""
    let threadActionDataManager = ThreadActionDataManager()
    private var reachability: Reachability? = Reachability()
    private var connection: Reachability.Connection?

    var selectedRows: [IndexPath] {
        viewModel.listViewModel.mailThreads.all
            .enumerated().compactMap { selectedThreadIds.contains($1.threadID) ? IndexPath(item: $0, section: 0) : nil }
    }
    var selectedThreadIds = [String]() {
        didSet {
            if selectedThreadIds.isEmpty {
                exitMultiSelect()
            }
            updateThreadActionBar()
        }
    }
    var markSelectedThreadId: String?

    var statusAndNaviHeight: CGFloat {
        return statusHeight + naviHeight
    }
    var statusHeight: CGFloat {
        if Display.isDynamicIsland() {
            return UIApplication.shared.statusBarFrame.height + 5
        } else {
            return UIApplication.shared.statusBarFrame.height
        }
    }

    // MARK: States
    private var hasGone: Bool = false
    var delayReload: Bool = false
    var edgePanGesture = UIScreenEdgePanGestureRecognizer()
    var status: MailHomeEmptyCell.EmptyCellStatus = .none
    var didAppear: Bool = false
    var shouldChecklmsStatus: Bool = true

    var markRecalledThreadId: String?
    internal var isShowing: Bool = false

    internal var navbarShowTipsRedDot: Bool = false
    internal var labelsMenuShowing: Bool = false
    var labelListFgDataError: Bool = false
    internal var hasShowOnboardingTips: Bool = false
    var appendGuide = [SmartInboxTipsView.TipType]()
    lazy var smartInboxOnboardState = SmartInboxOnboardState()
    var fingerMoving = false
    var enterTabTimeStamp: TimeInterval = -1
    // MARK: auth
    var oauthPageViewType = OAuthViewType.typeNewUserOnboard
    var oauthPlaceholderPage: MailClientImportViewController?
    var getAccountListDisposed = DisposeBag()
    
    // MARK: IMAP Migration
    var migrationSettingPage: MailIMAPMigrationSettingController?
    var migrationAuthPage: MailIMAPMigrationAuthController?
    var migrationDetailAlert: UDDialog?
    var isShowingMigrationOnboard: Bool = false


    var displaying = false
    var initData = true
    var isMultiSelecting: Bool = false {
        didSet {
            MailLogger.info("[mail_home] isMultiSelecting: \(isMultiSelecting)")
            if self.shouldAdjustPullRefresh {
                self.viewModel.syncDataSource()
                self.tableView.reloadData()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.ultraShort, execute: {
                    self.viewModel.syncDataSource()
                    self.tableView.reloadData() // 因为reloadData会触发layout和scroll，而系统触发的layout会导致进入多选后偶现偏移错误
                })
            }
        }
    }
    

    // DO NOT use in subclasses cause the scopes of viewWillAppear(_:) are different
    final var inViewWillAppear = false

    // MARK: Life Circle
    let userContext: MailUserContext

    init(userContext: MailUserContext) {
        self.userContext = userContext
        self.viewModel = MailViewModelFactory.creatMailHomeInitViewModel(userContext: userContext)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var serviceProvider: MailSharedServicesProvider? {
        userContext
    }

    var viewIsLoaded: Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        MailLogger.info("[mail_loading] MailHome VC viewDidLoad, canInitData: \(initData)")
        viewModel.canInitData = initData
        viewModel.apmFirstScreenStart()
        viewModel.apmMarkThreadListStart(sence: .sence_cold_start)

        setupView()
        // 绑定VM
        bindCommonObserver()
        bindMainViewModel()
        bindListViewModel(listVM: viewModel.listViewModel)
        /// 标记尚未渲染首屏
        hasFirstScreenRender = false
        initData(firstInit: true)
        RootTraitCollection.observer
        .observeRootTraitCollectionWillChange(for: self)
        .subscribe(onNext: { [weak self] _ in
            self?.dismissVCWhenTransition()
        }).disposed(by: disposeBag)
        addObserver()

        self._firstScreenDataReady.asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] ready in
                guard let self = self else { return }
            if ready {
                self.userContext.editorLoader.preloadEditor()
                self.configTabelViewRefresh()
                MailMessageListViewsPool.preload(provider: self.userContext)
                self.preloadReadMailRenderIfNeed(nil)
                self.viewModel.updateUnreadDotAfterFirstScreenLoaded()
                self.viewModel.triggerMailClientRefreshIfNeeded()
                self.labelsMenuController?.updateLabels(self.viewModel.labels)
                self.showPreloadTaskStatusIfNeeded()
                self.detectUnreadCountIfNeeded()
                self.showStrangerCardListViewIfNeeded()
                self.viewModel.showSmartInboxOnboardingIfNeeded()
                self.showNewFilterOnboardingIfNeeded()
                self.showAIOnboardingIfNeeded()
                self.viewModel.setupConversationModeValue()
            }
        }).disposed(by: self.disposeBag)

        if userContext.featureManager.open(.unreadPreloadMailOpt, openInMailClient: true) {
            refreshListDataReady.asObservable()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] sceneInfo in
                    guard let self = self else { return }
                    guard sceneInfo.0 != .unknown && sceneInfo.1 else { return }
                    MailLogger.info("MailUnreadPreload refreshListDataReady sceneInfo: \(sceneInfo)")
                    self.preloadCurrentDatasource()
            }).disposed(by: self.disposeBag)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        MailLogger.error("MailHome receive memory warning")
        userContext.messageListPreloader.clear()
    }

    private func preloadCurrentDatasource(threadChangeDetail: [String : MailThreadChanegDetail]? = nil) {
        preloadReadMailRenderIfNeed { [weak self] render in
            guard let self = self else { return }
            self.userContext.messageListPreloader.startPreloadFor(datasource: self.viewModel.datasource,
                                                                  currentLabelID: self.viewModel.currentLabelId,
                                                                  pageWidth: self.view.bounds.width,
                                                                  paddingTop: MailMessageNavBar.navBarHeight,
                                                                  templateRender: render,
                                                                  threadChangeDetail: threadChangeDetail)
        }
    }

    /// 异步预加载读信页渲染render
    private func preloadReadMailRenderIfNeed(_ completion: ((MailMessageListTemplateRender) -> Void)?) {
        if let render = templateRender {
            // 已经加载了，不需要重新加载
            completion?(render)
        } else {
            MailMessageListTemplateRender.asyncPreloadRender(accountContext: userContext.getCurrentAccountContext()) { [weak self] render in
                self?.templateRender = render
                completion?(render)
            }
        }
    }

    private func dismissVCWhenTransition() {
        if let dropMenuVC = self.presentedViewController as? MailTagViewController {
            dropMenuVC.dismiss(animated: false, completion: nil)
        }
        if let menuPoverVC = self.presentedViewController as? PopupMenuPoverViewController {
            menuPoverVC.dismiss(animated: false, completion: nil)
        }
        if let menuVC = self.presentedViewController as? PopupMenuViewController {
            menuVC.dismiss(animated: false, completion: nil)
        }
        if let accountVC = self.presentedViewController as? MailAccountListController {
            accountVC.dismiss(animated: false, completion: nil)
        }
        if let MoreActionVC = self.presentedViewController as? MoreActionViewController{
            MoreActionVC.dismiss(animated: false, completion: nil)
        }
    }

    override func viewDidTransition(to size: CGSize) {
        labelsMenuController?.preferredContentSize = CGSize(width: MailTagViewController.Layout.popWidth, height: size.height / 2)
        self.viewModel.syncDataSource()
        self.tableView.reloadData()
        if !self.showLarkNavbar {
            // multi mode
            self.threadActionBar.superview?.bringSubviewToFront(self.threadActionBar)
            self.updateThreadActionBar()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.closeNotifyBotOnboarding()
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.tableView.viewWidth = size.width
            self?.tableView.setNeedsLayout()
            self?.viewModel.strangerCardList?.pageSize = size
        }, completion: { [weak self] _ in
            self?.updateNotifyBotOnboardingFrame()
        })
        self.dismissVCWhenTransition()
    }

    override func viewWillAppear(_ animated: Bool) {
        inViewWillAppear = true
        defer { inViewWillAppear = false }

        super.viewWillAppear(animated)
        if hasGone {
            hasGone = false
        }
        dualVC?.view.isHidden = false
        /// restore the state
        if self.displaying {
            MailLogger.info("[mail_client_nav] HomeVC viewWillAppear 刷新导航栏标题")
            navbarTitleBadge(show: navbarShowTipsRedDot)
            updateTitle(viewModel.currentLabelName)
            if rootSizeClassIsSystemRegular {
                navigationController?.navigationBar.isHidden = false
            }
        }
        threadActionBar.isHidden = !isMultiSelecting
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dualVC?.view.isHidden = true
        if navbarShowTipsRedDot && displaying {
            MailLogger.info("[mail_client_nav] HomeVC viewWillDisappear 刷新导航栏标题")
            navbarTitleBadge(show: false)
        }
        if !viewModel.sessionIDs.isEmpty {
            MailRoundedHUD.remove(on: self.tabBarController?.view ?? self.view)
        }
        threadActionBar.isHidden = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isShowing = false

        self.viewModel.apmFirstScreenUserLeave(hasFirstScreenRender)
        self.viewModel.apmMarkUserleaveIfNeeded(hasFirstScreenRender)

        let event = NewCoreEvent(event: .email_thread_list_view)
        let value = NewCoreEvent.labelTransfor(labelId: labelsMenuController?.viewModel.selectedID ?? "",
                                               allLabels: labelsMenuController?.viewModel.labels ?? [])
        event.params = ["thread_list_type": viewModel.currentFilterType == .allMail ? "all_mail" : "unread_mail",
                        "label_item": value,
                        "mail_display_type": Store.settingData.threadDisplayType(),
                        "mail_service_type": Store.settingData.getMailAccountListType()]
        event.post()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configNetworkTips()
        if !self.appendGuide.isEmpty {
            for guide in self.appendGuide {
                self.showSmartInboxTips(guide)
            }
        }
        isShowing = true
        if let sharedAccountChange = viewModel.lastSharedAccountChange {
            dealSharedAccountChange(change: sharedAccountChange)
        }
        if !didAppear {
            didAppear = true
        }
        setFilterButtonType(seleted: viewModel.currentFilterType != .allMail)
        if isMultiSelecting {
            self.threadActionBar.superview?.bringSubviewToFront(self.threadActionBar)
        }
        if Store.settingData.mailClient {
            showClientMigrationTips()
            if displaying && rootSizeClassIsSystemRegular {
                self.changeNaviBarPresentation(show: true, animated: false)
            }
            showMailClientPassLoginExpriedAlertIfNeeded()
        }
        switchToLMSAccountInNextLoginIfNeeded()
        showConversationModeSortGuideIfNeeded()
        viewModel.showBatchChangeLoadingIfNeeded()
        showStrangerReplyToastIfNeeded()
        if viewModel.shouldShowStrangerOnboard {
            showStrangerOnboardingIfNeeded()
        }
        viewModel.showMigrationOnboardIfNeed()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        /// dark/light mode 切换，需要重新预加载，否则内容颜色会错误
        if #available(iOS 13.0, *),
           userContext.featureManager.open(FeatureKey(fgKey: .darkMode, openInMailClient: true)),
           self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            preloadCurrentDatasource()
        }
    }

    // iPad 设置页pop出来后需要刷新导航栏
    func needRefreshHomeNav() {
        if displaying && rootSizeClassIsSystemRegular {
            self.changeNaviBarPresentation(show: true, animated: false)
            MailLogger.info("[mail_client_nav] nav: \(getLarkNavbar())")
            if let nav = getLarkNavbar() {
                MailLogger.info("[mail_client_nav] animatedTabBarController: \(animatedTabBarController)")
                DispatchQueue.main.async {
                    self.tabBarController?.view.bringSubviewToFront(nav)
                }
            }
        }
    }
    func scrollToTopOfThreadList(accountId: String) {
        if let currentAccID = Store.settingData.getCachedCurrentAccount()?.mailAccountID, !accountId.isEmpty, currentAccID != accountId {
            MailLogger.info("[mail_cache_preload] scrollToTopOfThreadList currentAccID: \(currentAccID)")
            Store.settingData.switchMailAccount(to: accountId).subscribe(onNext: { (_) in
                NotificationCenter.default.post(Notification(name: Notification.Name.Mail.MAIL_SWITCH_ACCOUNT))
             }, onError: { (err) in
                 mailAssertionFailure("[mail_cache_preload] err in switch account \(err)")
             }).disposed(by: Store.settingData.disposeBag)
        } else {
            if headerViewManager.tableHeaderView.intrinsicContentSize.height > 10 {
                MailLogger.info("[mail_cache_preload] scrollToTopOfThreadList y: \(-headerViewManager.tableHeaderView.intrinsicContentSize.height)")
                DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.large) { [weak self] in
                    guard let self = self else { return }
                    self.tableView.btd_scrollToTop(animated: true)
                }
            } else {
                let diffOffsetY = (Store.settingData.getCachedAccountList()?.count ?? 1) > 1 ? MailThreadListConst.mulitAccountViewHeight : 0
                MailLogger.info("[mail_cache_preload] scrollToTopOfThreadList y: \(diffOffsetY)")
                tableView.setContentOffset(CGPoint(x: 0, y: -diffOffsetY), animated: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.normal) { [weak self] in
                    guard let self = self else { return }
                    self.tableView.setContentOffset(CGPoint(x: 0, y: -diffOffsetY), animated: true)
                }
            }
        }
    }
    // 重建ViewModel
    func rebuildViewModel() {
        viewModel = MailHomeViewModel(userContext: userContext)
        bindMainViewModel()
        bindListViewModel(listVM: viewModel.listViewModel)
    }

    // 一些通用通知的监听
    func bindCommonObserver() {
        NotificationCenter.default.rx
            .notification(Notification.Name.Mail.MAIL_SWITCH_ACCOUNT)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] _ in
                self?.reloadAcountChangeUI()
                self?.viewModel.auditSwitchToSharedAccount()
            }
            .disposed(by: disposeBag)

        PushDispatcher
            .shared
            .migrationChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (change) in
                switch change {
                case .migrationChange(let change):
                    self?.mailMigrationChange(change)
                }
            }).disposed(by: disposeBag)

        NotificationCenter.default.rx
            .notification(Notification.Name.Mail.MAIL_CACHED_CURRENT_SETTING_CHANGED)
            .subscribe(onNext: { [weak self] notification in
                self?.mailSettingChange(notification)
            }).disposed(by: disposeBag)

        NotificationCenter.default.rx
            .notification(Notification.Name.Mail.MAIL_RESET_THREADLISTLABEL)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] notification in self?.mailResetThreadListLabel(notification) }
            .disposed(by: disposeBag)

        NotificationCenter.default.rx
            .notification(Notification.Name.Mail.MAIL_SERVICE_RECOVER_ACTION)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] notification in self?.handleRecoverActions(notification) }
            .disposed(by: disposeBag)

        EventBus.accountChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                if case .shareAccountChange(let change) = push {
                    self?.mailSharedAccountChange(change)
                }
                if case .accountChange(let change) = push {
                    self?.mailAccountChange(change)
                }
                if case .currentAccountChange = push {
                    self?.mailCurrentAccountChange()
                }
                self?.viewModel.getImapMigrationState()
            }).disposed(by: baseDispose)

        EventBus.threadListEvent
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (event) in
                switch event {
                case .markRecalledThread(threadId: let id):
                    self?.markRecalledThreadId = id
                default: break
                }
            }).disposed(by: baseDispose)

        Store.settingData
            .accountInfoChanges
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] () in
                guard let `self` = self else { return }
                self.mailAccountInfosChange()
        }).disposed(by: disposeBag)
        
        Store.settingData
            .swipeActionChanges
            .distinctUntilChanged({ a, b in
                return a.0 == b.0 && a.1 == b.1
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (leftActions, rightActions) in
                guard let `self` = self else { return }
                MailLogger.info("[mail_swipe_actions] recieve swipeActions push change ---- leftActions: \(leftActions) rightActions: \(rightActions)")
                self.viewModel.listViewModel.leftOrientation = nil
                self.viewModel.listViewModel.rightOrientation = nil
                self.viewModel.syncDataSource()
                self.tableView.reloadData()
        }).disposed(by: disposeBag)
        

        Store.settingData
            .accountListChanges
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] () in
                guard let `self` = self else { return }
                self.mailAccountListChange()
        }).disposed(by: disposeBag)

        let netSettingPush = Store.settingData.netSettingPush
        let firstScreenRender = self._firstScreenDataReady.asObservable().skipWhile({ !$0 })
        Observable.combineLatest(netSettingPush, firstScreenRender)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                MailLogger.info("[mail_home_init] netSettingPush, refresh if need")
                self.refreshSettingAndListData()
        }).disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(Notification.Name.Mail.MAIL_DID_SHOW_SHARED_ACCOUNT_ALERT)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] notification in self?.mailDidShowSharedAccountAlert(notification) }
            .disposed(by: disposeBag)

        MailCommonDataMananger
            .shared
            .syncEventChange
            .observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] change in
                self?.mailSyncEventChange(change)
            }).disposed(by: disposeBag)

        if let reach = reachability {
            connection = reach.connection
            reach.notificationCenter.addObserver(self, selector: #selector(networkChanged), name: Notification.Name.reachabilityChanged, object: nil)
            do {
                try reachability?.startNotifier()
            } catch {
                MailLogger.debug("could not start reachability notifier")
            }
        }

        // 监听 split 切换 detail 页面信号
        NotificationCenter.default.rx
            .notification(SplitViewController.SecondaryControllerChange).observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (noti) in
                guard let `self` = self else { return }
            if let splitVC = noti.object as? SplitViewController,
               let currentSplitVC = self.larkSplitViewController,
               splitVC == currentSplitVC,
               let detail = splitVC.viewController(for: .secondary) {
                var topVC = detail
                if let nav = detail as? UINavigationController,
                   let firstVC = nav.viewControllers.first {
                    topVC = firstVC
                }
                /// 首页为默认 default 页面, 取消选中态
                if topVC is DefaultDetailVC {
                    self.markSelectedThreadId = nil
                    self.viewModel.syncDataSource()
                    self.tableView.reloadData()
                } else if let mvc = topVC as? MailMessageListController {
                    if let id = mvc.getThreadId() {
                        // 确保message的threadid在thread列表中存在
                        if self.viewModel.datasource.map({ $0.threadID }).contains(id) {
                            MailLogger.info("mvc.getThreadId=\(id), origin=\(self.markSelectedThreadId ?? ""))")
                            if let selectedId = self.markSelectedThreadId {
                                if id != selectedId {
                                    self.markSelectedThreadId = id
                                    self.viewModel.syncDataSource()
                                    self.tableView.reloadData()
                                }
                            } else {
                                self.markSelectedThreadId = id
                                self.viewModel.syncDataSource()
                                self.tableView.reloadData()
                            }
                        } else {
                            // iPad 预览 eml 文件, 取消选中.
                            if topVC as? EmlPreviewViewController != nil {
                                self.markSelectedThreadId = nil
                                self.viewModel.syncDataSource()
                                self.tableView.reloadData()
                            }
                        }
                    }
                }
            }
        }).disposed(by: disposeBag)

        _ = NotificationCenter.default.rx
            .notification(Notification.Name.Mail.MAIL_SETTING_CHANGED_BYPUSH)
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] noti in
            guard let `self` = self else { return }
            if let setting: Email_Client_V1_Setting = noti.object as? Email_Client_V1_Setting {
                MailLogger.debug("[mailTab] MAIL_SETTING_CHANGED_BYPUSH 刷新Auth Page")
                self.refreshAuthPageIfNeeded(setting)
            }
        }).disposed(by: disposeBag)

        NotificationCenter.default.rx
            .notification(Notification.Name.Mail.MAIL_HIDE_API_ONBOARDING_PAGE)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] notificationin in
                self?.mailHideApiOnboardingPage(notificationin)
            }).disposed(by: disposeBag)

        NotificationCenter.default.rx
            .notification(Notification.Name.Mail.MAIL_SETTING_AUTH_STATUS_CHANGED)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] notificationin in
                self?.handleAuthStatusChange(noti: notificationin)
            }).disposed(by: disposeBag)
        NotificationCenter.default.rx.notification(Notification.Name.Mail.MAIL_ADDRESS_NAME_CHANGE)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] noti in
               guard let `self` = self else { return }
               self.handleAddressChange()
            }).disposed(by: disposeBag)
        self.userContext.getCurrentAccountContext().provider.myAIServiceProvider?.aiNickNameRelay
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] nick in
                if !nick.isEmpty {
                    self?.userContext.getCurrentAccountContext().editorLoader.changeNewEditor(type: .aiNickNameChange)
                }
            }).disposed(by: disposeBag)
    }

    func bindMainViewModel() {
        mainBindDisposeBag = DisposeBag()
        viewModel.authStatusHelper.delegate = self

        viewModel.bindListVM
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (vm) in
                self?.bindListViewModel(listVM: vm)
            }).disposed(by: mainBindDisposeBag)

        viewModel.bindStrangerVM
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (vm) in
                self?.bindStrangerCardListViewModel(listVM: vm)
            }).disposed(by: mainBindDisposeBag)

        viewModel.outboxCountRefreshed
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (count) in
                MailLogger.info("[MailHome_handle] outboxCountRefreshed receive count \(count)")
                self?.mailOutboxCountRefresh(count)
            }).disposed(by: mainBindDisposeBag)

        viewModel.outboxSendStateChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (change) in
                self?.mailOutboxSendStateChange(change)
            }).disposed(by: mainBindDisposeBag)

        viewModel.currentLabelDeleted
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (labelId) in
                self?.mailCurrentLabelDeleted(labelId)
            }).disposed(by: mainBindDisposeBag)

        viewModel.mailRefreshAll
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                self?.mailRefreshAll()
                // migration也要刷
                self?.headerViewManager.refreshMailMigrationDetails()
                self?.refreshListDataReady.accept((.forceRefresh, false))
            }).disposed(by: mainBindDisposeBag)

        viewModel.errorRouter
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] errorType in
                switch errorType {
                case .labelListFgDataError(isError: let isError):
                    self?.updateLabelListFgDataError(isError)
                }
            }).disposed(by: mainBindDisposeBag)

        viewModel.uiElementChange
            .do(onNext: { element in
                // 为了不打敏感信息
                switch element {
                case .refreshAuthPage(setting: _):
                    MailLogger.info("[MailHome_handle] uiElementChange receive refreshAuthPage")
                case .showMultiAccount(_, showBadge: let badge):
                    MailLogger.info("[MailHome_handle] uiElementChange receive showMultiAccount showBadge: \(badge)")
                case .dismissMultiAccount:
                    MailLogger.info("[MailHome_handle] uiElementChange receive dismissMultiAccount")
                case .updateMultiAccountViewIfNeeded(_, accountList: _):
                    MailLogger.info("[MailHome_handle] uiElementChange receive updateMultiAccountViewIfNeeded")
                default:
                    MailLogger.info("[MailHome_handle] uiElementChange receive \(element)")
                }
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] uiElement in
                switch uiElement {
                case .title(let title):
                    self?.updateTitle(title)
                case .smartInboxPreviewCardResponse(labelID: let labelId, let resp):
                    self?.handleSmartInboxPreviewCardResp(labelId: labelId, resp: resp)
                case .mailLoading(let loading):
                    loading ? self?.showMailLoading() : self?.hiddenLoading()
                case .labelListSmartInboxFlag(let flag):
                    self?.updateLabelListSmartInboxFlag(flag)
                case .showNewFilterOnboardingIfNeeded:
                    self?.showNewFilterOnboardingIfNeeded()
                case .showSmartInboxTips(let type):
                    self?.showSmartInboxTips(type)
                case .showAIOnboardingIfNeeded:
                    self?.showAIOnboardingIfNeeded()
                case .expiredTips(let show):
                    show ? self?.headerViewManager.showExpiredTips() : self?.headerViewManager.dismissExpiredTips()
                case .passLoginExpiredTips(let show):
                    show ? self?.headerViewManager.showPassLoginExpiredTips() : self?.headerViewManager.dismissPassLoginExpiredTips()
                case .refreshPreloadProgressStage(let stage, let fromLabel):
                    self?.headerViewManager.refreshPreloadProgressStage(stage, fromLabel: fromLabel)
                case .refreshHeaderBizInfo:
                    self?.headerViewManager.refreshBussiessInfo()
                case .showMultiAccount(let account, showBadge: let showBadge):
                    self?.updateMultiAccountView(account, showBadge: showBadge)
                case .dismissMultiAccount:
                    self?.dismissMultiAccount()
                    self?.oauthPlaceholderPage?.hideMultiAccount()
                case .refreshAuthPage(setting: let setting):
                    self?.refreshAuthPageIfNeeded(setting, isUIChange: true)
                case .updateMultiAccountViewIfNeeded(let account, accountList: let accountList):
                    guard let self = self else { return }
                    if self._firstScreenDataReady.value {
                        self.updateMultiAccountViewIfNeeded(account, accountList: accountList)
                    } else {
                        self._firstScreenDataReady.asObservable()
                            .observeOn(MainScheduler.instance)
                            .subscribe(onNext: { ready in
                            if ready {
                                self.updateMultiAccountViewIfNeeded(account, accountList: accountList)
                            }
                        }).disposed(by: self.disposeBag)
                    }
                case .autoChangeLabel(labelId: let labelId, labelName: let name, isSystem: let system, updateTimeStamp: let update):
                    self?.autoChangeLabel(labelId, title: name, isSystemLabel: system, updateTimeStamp: update)
                case .updateArrowView(isHidden: let isHidden, isRed: let isRed):
                    let noticeFG = self?.userContext.featureManager.open(FeatureKey.init(fgKey: .labelListNotice, openInMailClient: true)) == true
                    if noticeFG {
                        self?.updateUnreadDot(isHidden: isHidden, isRed: isRed)
                    }
                case .showFeedBackToast(let toast, isSuccess: let isSuccess, selecteAll: let selecteAll, sessionID: let sessionID):
                    self?.showFeedBackToast(toast: toast, isSuccess: isSuccess, selecteAll: selecteAll, sessionID: sessionID)
                case .handleLongTaskLoading(let session, show: let show):
                    self?.handleLongTaskLoading(session: session, show: show)
                case .dismissStrangerCardList:
                    self?.handleStrangerCardEmpty()
                case .showSharedAccountMigrationOboarding(let migrationsIDs):
                    self?.showMigrationGuideIfNeed(migrationsIDs: migrationsIDs)
                }
            }).disposed(by: mainBindDisposeBag)

        // -- 这部分是filterType的ViewModel
        viewModel.filterViewModel
            .selectedFilter
            .asDriver()
            .distinctUntilChanged { $0 == $1 }
            .drive { [weak self] (arg0) in
                guard let self = `self` else { return }
                guard self._firstScreenDataReady.value else { return }
                let (filterType, isReset) = arg0
                self.didSelectFilter(filterType: filterType, loadData: !isReset, showLoading: false)
            }.disposed(by: disposeBag)

        viewModel.filterViewModel
            .showFilterMenu
            .asDriver(onErrorJustReturn: [.allMail])
            .drive { [weak self] (filterItems) in
                self?.showFilterPopupMenu(filterTypes: filterItems)
            }.disposed(by: disposeBag)

        // -- 这部分是直接监听changelog就足矣
        PushDispatcher
            .shared
            .mailChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                switch push {
                case .updateLabelsChange(let change):
                    self?.mailLabelChange(change.labels)
                default:
                    break
                }
        }).disposed(by: mainBindDisposeBag)

        // -- Property监听
        viewModel.currentLabelIdObservable
            .subscribeForUI(onNext: { [weak self] labelId in
                self?.updateUIElementCurrentLabelID(labelId)
        }).disposed(by: mainBindDisposeBag)

        viewModel.currentAccountObservable
            .asDriver()
            .distinctUntilChanged { $0.0?.mailAccountID == $1.0?.mailAccountID }
            .drive { [weak self] (account, needRefetch) in
                MailLogger.info("[mail_home] currentAccountObservable needRefetch: \(needRefetch) account: \(account?.mailAccountID)")
                if let account = account {
                    self?.currentAccountID = account.mailAccountID
                    self?.viewModel.getImapMigrationState()
                }
                if needRefetch {
                    self?.viewModel.firstFetchListData()
                }
            }.disposed(by: mainBindDisposeBag)

        if userContext.featureManager.open(.unreadPreloadMailOpt, openInMailClient: true) {
            Observable.combineLatest(_firstScreenDataReady, viewModel.initSyncFinish)
                .subscribe(onNext: { [weak self] value1, value2 in
                    guard let self = `self` else { return }
                    MailLogger.info("MailUnreadPreload Signal: \(value1) - \(value2)")
                    // 由于initSync的push推送到端上后，threadlistvm处理需要重新getThreadItem，所以首次预加载时机需要推后
                    Observable.just(())
                        .delay(.milliseconds(timeIntvl.normalMili), scheduler: MainScheduler.instance)
                        .subscribe(onNext: { [weak self] _ in
                            self?.preloadCurrentDatasource()
                        }).disposed(by: self.mainBindDisposeBag)
                })
                .disposed(by: mainBindDisposeBag)
        }
        
        viewModel.imapMigrationState.observeOn(MainScheduler.instance).subscribe(onNext: {[weak self] state in
            self?.handleMigrationStateChange(state: state)
        }).disposed(by: mainBindDisposeBag)
    }
    
 

    func bindStrangerCardListViewModel(listVM: MailThreadListViewModel) {
        strangerDisposeBag = DisposeBag()

        let labelID = listVM.labelID
        listVM.dataState
            .observeOn(MainScheduler.instance)
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (state) in
                guard let self = self else { return }
                guard StrangerCardConst.strangerInLabels.contains(self.viewModel.currentLabelId) &&
                        labelID == Mail_LabelId_Stranger else { return }

                switch state {
                case .refreshed(data: let datas, resetLoadMore: _):
                    MailLogger.info("[mail_stranger] cardlist listView dataState refreshed datas: \(datas.count) labelID: \(labelID) vm datacount:\(self.viewModel.strangerViewModel.mailThreads.all.count)")
                    if (self.headerViewManager.tableHeaderView.strangerCardListView?.isHidden ?? false) && !datas.isEmpty {
                        /// cardlist show up
                        MailTracker.log(event: "email_stranger_card_list_view", params: ["label_item": self.viewModel.currentLabelId])
                    }
                    if datas.isEmpty && self.viewModel.strangerViewModel.mailThreads.isEmpty {
                        self.handleStrangerCardEmpty()
                    } else {
                        let oldSelectedThreadID = self.headerViewManager.tableHeaderView.strangerCardListView?.selectedThreadID
                        self.headerViewManager.showStrangerCardListView(self.viewModel.strangerViewModel)
                        let refreshThreadInfo = self.headerViewManager.tableHeaderView.upsetViewModel(self.viewModel.strangerViewModel)
                        MailLogger.info("[mail_stranger] cardlist collect refreshThreadInfo: \(refreshThreadInfo) oldSelectedThreadID: \(oldSelectedThreadID)")
                        if let selectedThreadID = refreshThreadInfo.0, self.rootSizeClassIsRegular, refreshThreadInfo.1 {
                            if let index = self.viewModel.strangerViewModel.mailThreads.all.firstIndex(where: { $0.threadID == selectedThreadID }) {
                                self.headerViewManager.tableHeaderView.strangerCardListView?
                                    .updateSelectedStatus(index: IndexPath.init(row: index, section: 0), threadID: selectedThreadID)
                            }
                            if selectedThreadID != oldSelectedThreadID {
                                self.enterThread(with: selectedThreadID, forceRefresh: refreshThreadInfo.1)
                            }
                        }
                        self.viewModel.syncDataSource()
                        self.tableView.reloadData() // 麻烦 快速操作卡片，又会调用到这里，更新了错误旧的数据源进去
                        self.viewModel.strangerCardList?.updateSelectedStatus(selectedThreadId: refreshThreadInfo.0)
                        if datas.count < StrangerCardConst.cacheCardCount && !self.viewModel.strangerViewModel.isLoading {
                            MailLogger.info("[mail_stranger] cardlist loadmore auto, datas.count: \(datas.count)")
                            self.viewModel.strangerViewModel.getMailListFromLocal()
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.short) { [weak self] in
                            self?.showStrangerOnboardingIfNeeded()
                        }
                    }
                case .loadMore(data: let datas):
                    MailLogger.info("[mail_stranger] cardlist listView dataState loadMore datas: \(datas.count) labelID: \(labelID)")
                    if !datas.isEmpty && !self.viewModel.strangerViewModel.mailThreads.isEmpty {
                        let refreshThreadInfo = self.headerViewManager.tableHeaderView.upsetViewModel(self.viewModel.strangerViewModel)
                        if self.rootSizeClassIsRegular {
                            self.enterThread(with: refreshThreadInfo.0, forceRefresh: refreshThreadInfo.1)
                        }
                    }
                case .pageEmpty:
                    MailLogger.info("[mail_stranger] cardlist listView dataState pageEmpty labelID: \(labelID)")
                    self.handleStrangerCardEmpty()
                case .failed(labelID: let labelId, err: let error):
                    MailLogger.error("[mail_stranger] cardlist listView dataState fail labelID: \(labelID) error: \(error)")
                    self.handleDatasError(labelId: labelId, err: error)
                }
            }).disposed(by: strangerDisposeBag)
    }

    func bindListViewModel(listVM: MailThreadListViewModel) {
        // 绑定前，换个新的
        listDisposeBag = DisposeBag()

        listVM.dataState
            .observeOn(MainScheduler.instance)
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (state) in
                guard let self = self else { return }
                guard self.viewModel.currentLabelId == listVM.labelID else { return }
                MailLogger.info("[MailHome_handle] listView dataState receive \(state) labelID: \(listVM.labelID)")
                switch state {
                case .refreshed(data: let datas, resetLoadMore: let resetLoadMore):
                    if datas.isEmpty {
                        self.handleDatasEmpty()
                    } else {
                        self.handleRefreshedDatas(datas)
                        self.loadMoreDone = true
                    }
                    if resetLoadMore {
                        self.loadMoreIfNeeded()
                    }
                    if self.showCleanTrashTip() &&
                        (self.viewModel.currentLabelId == Mail_LabelId_Trash ||
                         self.viewModel.currentLabelId == Mail_LabelId_Spam) {
                        self.headerViewManager.tableHeaderView.showClearTrashTipsView(label: self.viewModel.currentLabelId, showBtn: !datas.isEmpty)
                        self.showClearTrashAlert()
                    }
                case .loadMore(data: let datas):
                    self.handleLoadMoreDatas(datas)
                case .pageEmpty:
                    self.viewModel.resetWhiteScreenDetect()
                    self.status = .none
                    self.refreshThreadList()
                case .failed(labelID: let labelId, err: let error):
                    self.handleDatasError(labelId: labelId, err: error)
                }
            }).disposed(by: listDisposeBag)

        listVM.mailThreadChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (change) in
                self?.mailThreadsChange(change)
            }).disposed(by: listDisposeBag)

        listVM.multiThreadChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (label2threads, hasFilterThreads) in
                self?.mailMultiThreadsChange(label2threads, hasFilterThreads)
            }).disposed(by: listDisposeBag)

        listVM.refreshStranger
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.resetStrangerCardListView()
                self?.showStrangerCardListViewIfNeeded()
            }).disposed(by: listDisposeBag)

        if userContext.featureManager.open(.unreadPreloadMailOpt, openInMailClient: true) {
            listVM.unreadPreloadChange
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (_, threadChangeDetail) in
                    MailLogger.info("MailUnreadPreload -- unreadPreloadChange threadChangeDetail: \(threadChangeDetail)")
                    let changeDetail = threadChangeDetail.values.contains(.refresh) ? nil : threadChangeDetail
                    self?.preloadCurrentDatasource(threadChangeDetail: changeDetail)
                }).disposed(by: listDisposeBag)
        }
    }

    func refreshSettingAndListData() {
        MailLogger.info("[mail_home_init] [mail_init] refreshSettingAndListData")
        guard let setting = Store.settingData.getCachedCurrentSetting(),
              viewModel.firstFetchSmartInboxMode != setting.smartInboxMode else {
                  return
        }
        // 首页数据上屏后再执行
        self.viewModel.refreshAllListData()
        self.labelsMenuController = self.makeTagMenu()
        self.labelsMenuController?.viewModel.selectedID = self.viewModel.currentLabelId
    }

    func loadAddress() {
        userContext.user.info?.mailAddress = MailModelManager.shared.getUserEmailAddress().address
    }

    private func mailMigrationChange(_ change: MailMigrationChange) {
        if let setting = Store.settingData.getCachedCurrentSetting(), setting.statusIsMigrationDonePromptRendered {
            MailHomeController.logger.debug("migration done should not update banner")
            return
        }
        MailHomeController.logger.debug( "migration change log stage:\(change.stage) progressPct:\(change.progressPct)")
        headerViewManager.updateMigrationState(stage: change.stage, progressPct: change.progressPct, showAlert: true)
        if viewModel.datasource.count < 20 {
            self.refreshCurrentThreadList()
        }
    }

    // 账号切换等原因需要刷新mail全部数据
    private func mailRefreshAll() {
        MailLogger.info("[mail_home_init] mailRefreshAll")
        viewModel.labels.removeAll()
        viewModel.cancelSettingFetch()
        viewModel.apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.abandon()
        viewModel.apmHolder[MailAPMEvent.ThreadListLoaded.self]?.abandon()
        resetStrangerCardListView()
        if viewModel.hasFirstLoaded {
            reloadThreadData()
            showStrangerCardListViewIfNeeded()
        } else {
            if !viewModel.lastGetThreadListInfo.0 {
                initData() // 若突然来了invalid 这个时候还没上屏则一直load不出来
                showStrangerCardListViewIfNeeded()
            } else { // 已经发出GetThreadList 等待回来后再刷新即可
                if self._firstScreenDataReady.value {
                    initData()
                    showStrangerCardListViewIfNeeded()
                } else {
                    self._firstScreenDataReady.asObservable().subscribe(onNext: { [weak self] ready in
                        if ready {
                            MailLogger.debug("[mail_init] netSettingPush _firstScreenDataReady finish and refresh")
                            self?.initData()
                            self?.showStrangerCardListViewIfNeeded()
                        }
                    }).disposed(by: self.disposeBag)
                }
            }
        }
        updateThreadActionBar()
    }

    @objc
    private func mailSettingChange(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let setting = Store.settingData.getCachedCurrentSetting() {
                MailHomeController.logger.debug( "mail setting change -> smartInbox \(setting.smartInboxMode)")
                // 可能还要再取一次当前previewcard的内容去展示
                let smartInboxEnable = setting.smartInboxMode && !self.userContext.featureManager.open(.aiBlock)
                self.isSmartInboxEnable = smartInboxEnable && !self.labelListFgDataError
                if smartInboxEnable {
                    self.showSmartInboxTips(.labelPop)
                } else {
                    self.userContext.provider.guideServiceProvider?.guideService?.removeGuideTasksIfNeeded(keys: ["all_email_smartinbox_intro"])
                }
                if !smartInboxEnable || self.labelListFgDataError {
                    self.updateTableViewHeader(with: self.headerViewManager.tableHeaderView.dismissSmartInboxPreviewCard())
                } else if smartInboxLabels.contains(self.viewModel.currentLabelId) {
                    self.viewModel.showPreviewCardIfNeeded(self.viewModel.currentLabelId == Mail_LabelId_Important ? Mail_LabelId_Other : Mail_LabelId_Important)
                }

                if setting.statusSmartInboxOnboarding.smartInboxPromptRendered {
                    self.navbarShowTipsRedDot = false
                    self.navbarTitleBadge(show: false)
                }

                // 开关发生变化，label list需要刷新
                if let labelsMenuController = self.labelsMenuController {
                    if labelsMenuController.didAppear,
                       (labelsMenuController.smartInboxModeEnable != smartInboxEnable ||
                        labelsMenuController.strangerModeEnable != setting.enableStranger) {
                        self.labelsMenuController?.smartInboxModeEnable = smartInboxEnable
                        self.labelsMenuController?.strangerModeEnable = setting.enableStranger
                        let event = MailTagViewModel.createStartedApmRefresh()
                        self.labelsMenuController?.fetchDataAndRefreshMark(apmEvent: event)
                    }
                }
                // updateAccountView
                if var account = Store.settingData.getCachedCurrentAccount(),
                   !account.sharedAccounts.isEmpty {
                    self.updateMultiAccountViewIfNeeded(account, accountList: [account] + account.sharedAccounts)
                }
                if Store.settingData.mailClient && !setting.isThirdServiceEnable {
                    self.updateOauthStatus(viewType: .typeOauthDeleted)
                    self.dismissMultiAccount()
                }

                // headerMananger
                self.headerViewManager.setupOutOfOfficeTipsAndSmartInboxIfNeeded(setting)
                self.headerViewManager.refreshStorageLimit(setting)

                MailHomeController.logger.debug( "mail setting change -> smartInbox \(setting.smartInboxMode)")

                if setting.statusIsMigrationDonePromptRendered {
                    MailHomeController.logger.debug( "mail status is migration done prompt rendered, dismiss migration tips")
                    self.headerViewManager.dismissMailMigrationStateTips(type: .api)
                    self.headerViewManager.tableHeaderView.migrationAlert?.dismiss(animated: true, completion: nil)
                    self.headerViewManager.migrationDoneAlertVC?.dismiss(animated: true, completion: nil)
                    self.headerViewManager.migrationDoneAlertVC = nil
                }
                if self.viewModel.clearTrashAlert != nil && !self.showCleanTrashTip() {
                    self.headerViewManager.tableHeaderView.dismissClearTrashTipsView()
                    self.viewModel.clearTrashAlert?.dismiss(animated: true)
                    self.viewModel.clearTrashAlert = nil
                }

                if self._firstScreenDataReady.value {
                    if self.viewModel.conversationMode != setting.enableConversationMode {
                        self.refreshListDataReady.accept((.forceRefresh, false))
                    }
                }
                if let cacheEnableStranger = self.viewModel.enableStranger,
                   self._firstScreenDataReady.value && setting.enableStranger != cacheEnableStranger {
                    self.viewModel.enableStranger = setting.enableStranger
                    if setting.enableStranger {
                        self.showStrangerCardListViewIfNeeded()
                    } else {
                        self.resetStrangerCardListView()
                    }
                }
            }
        }
    }

    func updateMultiAccountViewIfNeeded(_ account: MailAccount, accountList: [MailAccount]) {
        if accountList.filter({ $0.isShared }).count > (Store.settingData.clientStatus == .mailClient ? 1 : 0) {
            let badge = Store.settingData.getOtherAccountUnreadBadge()
            self.updateMultiAccountView(account, showBadge: badge)
        } else {
            self.dismissMultiAccount()
        }
    }
    // label 全量刷新当前页面
    private func refreshCurrentThreadList(cleanCache: Bool = false) {
        /// 全量刷新整个列表
        let listLength = max(20, viewModel.datasource.count)
        viewModel.listViewModel.updateMailListFromLocal(filterType: viewModel.currentFilterType, length: Int64(listLength), cleanCache: cleanCache)
    }

    // 当前label被其他端删除
    private func mailCurrentLabelDeleted(_ currentLabelID: String) {
        if currentLabelID == self.viewModel.currentLabelId {
            asyncRunInMainThread {
                if let setting = Store.settingData.getCachedCurrentSetting() {
                    if setting.smartInboxMode && !Store.settingData.mailClient {
                        self.autoChangeLabel(Mail_LabelId_Important, title: BundleI18n.MailSDK.Mail_SmartInbox_Important, isSystemLabel: true)
                    } else {
                        self.autoChangeLabel(Mail_LabelId_Inbox, title: BundleI18n.MailSDK.Mail_Folder_Inbox, isSystemLabel: true)
                    }
                } else if let firstLabel = self.viewModel.labels.first {
                    self.autoChangeLabel(firstLabel.labelId, title: firstLabel.text, isSystemLabel: firstLabel.isSystem)
                } else {
                    mailAssertionFailure("current Label Deleted before setting and labels fetch")
                }
            }
        }
    }

    @objc
    func networkChanged() {
        guard let reachablility = reachability else {
            return
        }
        guard connection != reachablility.connection else {
            MailHomeController.logger.info("mail network changed repeat at home")
            return
        }
        MailHomeController.logger.info("mail network changed at home")
        connection = reachablility.connection
        if reachablility.connection != .none, viewModel.datasource.isEmpty, status == .noNet {
            showMailLoading()
            loadThreadListData(labelId: viewModel.currentLabelId, filterType: viewModel.currentFilterType,
                               title: viewModel.currentLabelName, showLoading: true)
        }
        // updateTitle(reachablility.connection != .none ? currentLabelName : BundleI18n.MailSDK.Mail_Normal_Disconnected)
        // 断网且有数据才显示这个tips
        if !viewModel.datasource.isEmpty {
            configNetworkTips()
        }
        if FeatureManager.open(.offlineCache, openInMailClient: false),
           !viewModel.datasource.isEmpty,
           reachablility.connection != .none, footer.canCacheMore {
            footer.canCacheMore = false
            tableView.es.resetNoMoreData()
            tableView.es.autoLoadMore()
        }
    }

    private func configNetworkTips() {
        guard let reachablility = reachability else {
            return
        }
        if !viewModel.datasource.isEmpty {
            updateTableViewHeader(with: reachablility.connection == .none ?
                                  headerViewManager.tableHeaderView.showNoNetTips() :
                                    headerViewManager.tableHeaderView.dismissNoNetTips())
            if reachablility.connection == .none {
                InteractiveErrorRecorder.recordError(event: .threadlist_no_net_flag, tipsType: .flag)
            }
        } else {
            updateTableViewHeader(with: headerViewManager.tableHeaderView.dismissNoNetTips())
        }
    }
    
    func updateLoading(_ loading: MailBaseLoadingView) {
        _mailBaseLoadingView = loading
        self.mailLayoutPlaceHolderView(placeholderView: loading)
    }

    func showMailLoading() {
        loadingDisposeBag = DisposeBag() // 每次新起一个
        MailLogger.info("[mail_home] [mail_loading] showMailLoading called")
        Observable.just(())
        .delay(.milliseconds(150), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?._showMailLoadingImp()
                self?.viewModel.resetWhiteScreenDetect()
                MailLogger.info("[mail_home] [mail_loading] did showing mailloading")
            }).disposed(by: loadingDisposeBag)
    }

    private func _showMailLoadingImp() {
        // if already show migration page, don't show loading again, avoid interface flicker
        guard self.migrationSettingPage?.parent == nil && self.migrationAuthPage?.parent == nil else {
            MailLogger.info("[mail_init] [mailTab] [mail_loading] already show migration page")
            return
        }
        MailLogger.info("[mail_init] [mailTab] [mail_loading] mail show loading")
        mailLoadingPlaceholderView.play()
        mailLoadingPlaceholderView.isHidden = false
        view.bringSubviewToFront(self.sendMailButton)
        if let oauthView = oauthPlaceholderPage?.view {
            view.bringSubviewToFront(oauthView)
        }
        view.bringSubviewToFront(self.multiAccountView)
        configNetworkTips()
    }

    func hiddenLoading() {
        // 关闭等待计时
        asyncRunInMainThread {
            self.delayLoadingBag = nil
            self.loadingDisposeBag = DisposeBag() // 丢掉旧的
            MailLogger.info("[mail_init] [mailTab] [mail_home] [mail_loading] mail hide loading")
            self.mailLoadingPlaceholderView.stop()
            self.configNetworkTips()
        }
    }

    private func customConfigureTableView(_ tableView: UITableView) {
        tableView.lu.register(cellSelf: MailThreadListCell.self)
        tableView.lu.register(cellSelf: MailHomeEmptyCell.self)
    }

    deinit {
        MailMessageListViewsPool.reset()
        if let reach = reachability {
            reach.stopNotifier()
            reach.notificationCenter.removeObserver(self)
        }
    }

    private var navBarInherentHeight: CGFloat {
        return statusAndNaviHeight
    }

    private func setupView() {
        viewModel.createViewCostTimeStart()
        view.backgroundColor = UIColor.ud.bgBody
        /// status bar appearance manage,
        /// modalPresentationStyle can't equal = fullscreen
        self.modalPresentationStyle = .none
        self.modalPresentationCapturesStatusBarAppearance = true

        /// 导航条
        setupBarItem()
        view.addSubview(tableView)
        if Display.pad {
            tableView.snp.makeConstraints { (make) in
                make.leading.trailing.bottom.equalToSuperview()
                make.top.equalTo(naviHeight + statusHeight)
            }
        } else {
            tableView.frame = CGRect(x: 0, y: naviHeight + statusHeight,
                                     width: Display.width, height: Display.height - naviHeight -  statusHeight)
        }
        view.addSubview(sendMailButton)
        sendMailButton.snp.makeConstraints { (make) in
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right).inset(16)
            var bottomOffset: CGFloat = 16
            if (view.frame.size.height ?? Display.height) < Display.height {
                bottomOffset += (animatedTabBarController?.tabbarHeight ?? 52)
            }
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(bottomOffset)
            make.width.height.equalTo(48)
        }
        MailLogger.info("[mail_client_tabbar] home vc setupViews tabbarHeight: \(animatedTabBarController?.tabbarHeight)")
        _ = navBarLoading.debounce(.milliseconds(500), scheduler: MainScheduler.instance)
        _ = showLarkNavbarFlag.throttle(.milliseconds(300), scheduler: MainScheduler())
        viewModel.createViewCostTimeEnd()
//        displayContentController(self)
        updateOauthStatus(viewType: oauthPageViewType)
        Observable.just(())
            .delay(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                guard self.userContext.featureManager.open(FeatureKey(fgKey: .homeSpeedupLoading, openInMailClient: true)) else { return }
                if self.viewModel.datasource.isEmpty || self.status == .none {
                    MailLogger.info("[mail_loading] mail home white screen detect! showLoading default")
                    self._showMailLoadingImp()
                    self.viewModel.resetWhiteScreenDetect()
                }
            }).disposed(by: viewModel.whiteScreenDetectDisposeBag)
        // 倒计时300毫秒内需要出现loading，否则上报白屏异常
        Observable.just(())
        .delay(.milliseconds(310), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                if LarkFoundation.Utils.isSimulator {
                    MailLogger.error("[mail_loading] mail home white screen")
                } else {
                    mailAssertionFailure("[mail_loading] mail home white screen")
                }
            }).disposed(by: viewModel.whiteScreenDetectDisposeBag)
        if userContext.featureManager.open(FeatureKey(fgKey: .homeSpeedupLoading, openInMailClient: true)) {
            if enterTabTimeStamp != -1 {
                Observable.just(())
                    .delay(.milliseconds(min(300 - Int(Date().timeIntervalSince1970 - enterTabTimeStamp), 300)), scheduler: MainScheduler.instance)
                    .subscribe(onNext: { [weak self] _ in
                        guard let `self` = self else { return }
                        if self.viewModel.datasource.isEmpty || self.status == .none {
                            MailLogger.info("[mail_loading] mail home white screen detect! showLoading default")
                            self._showMailLoadingImp()
                            self.viewModel.resetWhiteScreenDetect()
                        }
                    }).disposed(by: viewModel.whiteScreenDetectDisposeBag)
            } else {
                MailLogger.info("[mail_loading] mail home white screen detect cancel, tabbar had showLoading")
                self._showMailLoadingImp()
                viewModel.resetWhiteScreenDetect()
            }
        }
    }

    func setInset() {
//        let tableViewTopMargin = naviHeight + (multiAccountView.isDescendant(of: view) ? 48 : 0)
//        guard tableView.contentInset.top != tableViewTopMargin else {
//            return
//        }
//        var inset = tableView.contentInset
//        inset.top = tableViewTopMargin
//        tableView.contentInset = inset
//        tableView.setContentOffset(CGPoint(x: 0, y: tableViewTopMargin), animated: false)
    }

    private func setupBarItem() {
        navigationController?.navigationBar.tintColor = UIColor.ud.iconN2
        self.customConfigureTableView(self.tableView)
        navigationItem.hidesBackButton = true
        customNavigationBar.isHidden = true
    }

    func refreshLabel() {
        Store.settingData.getCurrentSetting().observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] (setting) in
            guard let `self` = self else { return }
            self.labelsMenuController?.strangerModeEnable = setting.enableStranger
            self.resetPriorityLabel(by: setting, hasPush: true)
        }, onError: { (error) in
            MailHomeController.logger.error("getEmailSetting failed", error: error)
        }).disposed(by: disposeBag)
    }

    func makeSendMailButton() -> UIButton {
        let sendMailButton = MailCreateDraftButton(frame: CGRect(origin: .zero, size: CGSize(width: 48, height: 48)))
        sendMailButton.delegate = self
        return sendMailButton
    }

    var tableHeaderView: MailThreadListHeaderView {
        return headerViewManager.tableHeaderView
    }

    var labelsMenuController: MailTagViewController?

    func makeTagMenu() -> MailTagViewController {
        var mode: DisplayMode = .normalMode
        if rootSizeClassIsSystemRegular {
            mode = .popoverMode
        }
        let labelsMenuController = MailTagViewController.init(0, accountContext: userContext.getCurrentAccountContext(), delegate: nil, mode)
        labelsMenuController.delegate = self
        if let setting = Store.settingData.getCachedCurrentSetting() {
            labelsMenuController.smartInboxModeEnable = setting.smartInboxMode
            labelsMenuController.strangerModeEnable = setting.enableStranger
        }
        return labelsMenuController
    }

    /// If threadId exists in datasource, show detail page, else show DefaultDetailVC
    func enterThread(with threadId: String?, forceRefresh: Bool = false) {
        if !Display.pad && !rootSizeClassIsRegular {
            headerViewManager.tableHeaderView.strangerCardListView?.clearSelectedStatus()
        }
        if let idx = viewModel.datasource.firstIndex(where: { $0.threadID == threadId }), idx < viewModel.datasource.count {
            enterThread(at: idx, presentDraftEditorOnPad: false)
        } else if userContext.featureManager.open(.stranger, openInMailClient: false),
                  let strangerCardIndex = viewModel.strangerViewModel.mailThreads
            .all.prefix(StrangerCardConst.maxCardCount).firstIndex(where: { $0.threadID == threadId }),
                  let threadID = threadId,
                  strangerCardIndex < viewModel.strangerViewModel.mailThreads.all.count {
            if threadID == headerViewManager.tableHeaderView.strangerCardListView?.selectedThreadID && !forceRefresh {
                return
            } else {
                enterMsgList(at: strangerCardIndex, threadID: threadID, labelID: Mail_LabelId_Stranger, threadList: viewModel.strangerViewModel.mailThreads.all)
            }
        } else {
            if rootSizeClassIsRegular {
                navigator?.showDetail(SplitViewController.makeDefaultDetailVC(), wrap: LkNavigationController.self, from: self)
            }
        }
    }

    private func enterThread(at index: Int, presentDraftEditorOnPad: Bool) {
        viewModel.datasource[index].isUnread = false
        headerViewManager.tableHeaderView.strangerCardListView?.clearSelectedStatus()
        let cellVM = viewModel.datasource[index]
        if cellVM.convCount == 0
            || (cellVM.convCount == 1 && cellVM.isComposeDraft) { // 这个判断@zhengkui
            if rootSizeClassIsRegular && !presentDraftEditorOnPad {
                markSelectedThreadId = nil
                navigator?.showDetail(SplitViewController.makeDefaultDetailVC(), wrap: LkNavigationController.self, from: self)
            } else {
                // 自己的草稿，弹起编辑器
                MailTracker.startRecordTimeConsuming(event: Homeric.MAIL_DEV_DRAFT_COST_TIME, params: nil)
                MailTracker.startRecordMemory(event: Homeric.MAIL_DEV_DRAFT_MEMORY_DIFF, params: nil)
                let labelItem = NewCoreEvent.labelTransfor(labelId: viewModel.currentLabelId,
                                                           allLabels: labelsMenuController?.viewModel.labels ?? [])
                let vc = MailSendController.makeSendNavController(accountContext: userContext.getCurrentAccountContext(),
                                                                  threadID: cellVM.threadID,
                                                                  action: .draft,
                                                                  labelId: viewModel.currentLabelId,
                                                                  statInfo:
                                                                    MailSendStatInfo(from: .threadListDraft, newCoreEventLabelItem: labelItem),
                                                                  trackerSourceType: .inboxDraft)
                navigator?.present(vc, from: self)
            }
        } else if !rootSizeClassIsRegular || markSelectedThreadId != cellVM.threadID {
            // 属于messagelist的草稿
            enterMsgList(at: index, threadID: cellVM.threadID, labelID: viewModel.currentLabelId, threadList: viewModel.datasource)
        }
        hasGone = true
    }

    func enterMsgList(at index: Int, threadID: String, labelID: String, threadList: [MailThreadListCellViewModel]) {
        #if DEBUG
        // debug 时读取开发本地template代码
        let kvStore = MailKVStore(space: .global, mSpace: .global)
        if LarkFoundation.Utils.isSimulator && kvStore.bool(forKey: MailDebugViewController.kMailLoadLocalTemplate) {
            templateRender = MailMessageListTemplateRender(accountContext: userContext.getCurrentAccountContext())
        }
        MailMessageListController.startClickTime = MailTracker.getCurrentTime()
        #endif
        let labelItem = NewCoreEvent.labelTransfor(labelId: viewModel.currentLabelId,
                                                   allLabels: labelsMenuController?.viewModel.labels ?? [])
        // 提前触发图片加载请求
        viewModel.preloadImagesWhenClick(index: index)
        let vc = MailMessageListController.makeForMailHome(accountContext: userContext.getCurrentAccountContext(),
                                                           threadList: threadList,
                                                           threadId: threadID,
                                                           labelId: labelID,
                                                           statInfo: MessageListStatInfo(from: .threadList, newCoreEventLabelItem: labelItem),
                                                           pageWidth: view.bounds.width,
                                                           templateRender: templateRender,
                                                           externalDelegate: self)
        vc.currentAccount = self.viewModel.currentAccount
        if labelID != Mail_LabelId_Stranger {
            Store.sharedContext.value.markEnterThreadId = threadID
            markSelectedThreadId = threadID
        }
        vc.backCallback = { [weak self] in
            guard let strongSelf = self, Display.pad else { return } // 兼容iPad全屏case
            strongSelf.markSelectedThreadId = nil
            strongSelf.headerViewManager.tableHeaderView.strangerCardListView?.clearSelectedStatus()
            MailMessageListViewsPool.reset()
            strongSelf.viewModel.strangerCardList?.clearSelectedStatus()
        }
        if Display.pad {
            navigator?.showDetail(vc, wrap: MailMessageListNavigationController.self, from: self)
            let newIndex = IndexPath(item: index, section: 0)
            var indexPathsToReload = [newIndex]
            if let preIndex = tableView.indexPathForSelectedRow, preIndex != newIndex {
                indexPathsToReload.append(preIndex)
            }
            tableView.reloadItemsAtIndexPaths(indexPathsToReload, animationStyle: .none)
        } else {
            navigator?.push(vc, from: self)
        }
        // 业务统计
        MailTracker.log(event: Homeric.EMAIL_VIEW, params: ["threadid": threadID])
        // 如果是welcomeletter， 另外打点
        if threadID == MailTracker.WelcomeLetterThreadID {
            MailTracker.log(event: Homeric.EMAIL_WELCOMELETTER_READ, params: nil)
        }
    }

    @objc
    func createNewMail() {
        if Store.settingData.mailClient {
            Store.settingData.mailClientExpiredCheck(
                accountContext: userContext.getCurrentAccountContext(),
                from: self
            ) { [weak self] in
                self?.createDraft()
            }
        } else {
            createDraft()
        }
    }

    func createDraft() {
        MailTracker.startRecordMemory(event: Homeric.MAIL_DEV_SEND_PAGE_MEMORY_DIFF, params: nil)
        let vc = MailSendController.makeSendNavController(accountContext: userContext.getCurrentAccountContext(),
                                                          action: .new,
                                                          labelId: self.viewModel.currentLabelId,
                                                          statInfo: MailSendStatInfo(from: .threadListCreate, newCoreEventLabelItem: "none"),
                                                          trackerSourceType: .new)
        navigator?.present(vc, from: self)
        // 业务统计
        MailTracker.log(event: Homeric.EMAIL_EDIT, params: ["type": "compose"])

        // core event
        let event = NewCoreEvent(event: .email_new_mail_click)
        event.params = ["click": "create_new_email",
                        "target": "email_email_edit_view",
                        "mail_service_type": Store.settingData.getMailAccountListType()]
        event.post()
    }

    // MARK: - Data
    private func initData(firstInit: Bool = false) {
        MailLogger.info("[mail_home_init] mail homeviewcontroller init data firstInit: \(firstInit)")
        MailTracker.startRecordTimeConsuming(event: Homeric.MAIL_DEV_THREAD_LIST_COST_TIME, params: nil)
        /// reset to default value
        if firstInit {
            viewModel.initData()
        } else {
            /// 如果不是第一次初始化，直接认为是重刷数据
            viewModel.refreshAllListData()
        }

        /// load email address
        loadAddress()
        /// fetch mail domain
        userContext.user.fetchEmailDomain()
    }

    func mailLabelChange(_ labels: [MailClientLabel]) {
         guard !labels.isEmpty else {
            let errorMsg = "MailChangePush mailLabelChange labels is empty"
            MailLogger.error(errorMsg)
            mailAssertionFailure(errorMsg)
            return
        }
        self.viewModel.labels = labels.map({ MailFilterLabelCellModel(pbModel: $0) })
        for label in viewModel.labels where self.viewModel.currentLabelId == label.labelId {
            self.updateTitle(label.text)
            if viewModel.currentLabelName != label.text, !label.isSystem {
                viewModel.syncDataSource()
                self.tableView.reloadData()
            }
            break
        }
        let hasOutbox = labels.contains(where: {$0.id == Mail_LabelId_Outbox})
        if !hasOutbox && viewModel.currentLabelId == Mail_LabelId_Outbox {
            refreshCurrentThreadList(cleanCache: true)
        } else if hasOutbox {
            viewModel.fetchAndUpdateOutboxState()
        }
    }

    private func findDetailVCThreadId() -> String? {
        if let currentSplitVC = self.larkSplitViewController,
           let detail = currentSplitVC.secondaryViewController {
            var topVC = detail
            if let nav = detail as? UINavigationController,
               let firstVC = nav.viewControllers.first {
                topVC = firstVC
            }
            if let mvc = topVC as? MailMessageListController {
                return mvc.getThreadId()
            }
        }
        return nil
    }

    func firstScreenAPMReport(_ preload: Bool = false) {
        self.viewModel.apmMarkThreadListEnd(status: .status_success)
        viewModel.loadThreadListCostTimeEnd()
        if self.hasFirstScreenRender {
            let type = MailAPMEvent.FirstScreenLoaded.EndParam.mode_hot_start
            viewModel.apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.endParams.appendOrUpdate(type)
        } else {
            let type = MailAPMEvent.FirstScreenLoaded.EndParam.mode_cold_start
            viewModel.apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.endParams.appendOrUpdate(type)
        }
        viewModel.apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.endParams.append(MailAPMEvent.FirstScreenLoaded.EndParam.mail_display_type)
        let from_db = viewModel.listViewModel.lastSource
        viewModel.apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.endParams
            .append(MailAPMEvent.FirstScreenLoaded.EndParam.from_db(from_db ? 1 : 0))
        viewModel.apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.endParams
            .append(MailAPMEvent.FirstScreenLoaded.EndParam.preload_with_unread_mail(preload ? 1 : 0))
        viewModel.apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.endParams
            .append(MailAPMEvent.FirstScreenLoaded.EndParam.has_first_label_cache(0))
        viewModel.apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.endParams.append(MailAPMEventConstant.CommonParam.status_success)
        if viewModel.getParamIndex(.loadLabel) == nil {
            viewModel.apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.endParams.append(MailAPMEvent.FirstScreenLoaded.EndParam.load_label_list_cost_time(0))
        }
        if viewModel.getParamIndex(.createView) == nil {
            viewModel.apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.endParams.append(MailAPMEvent.FirstScreenLoaded.EndParam.load_label_list_cost_time(0))
        }
        if viewModel.getParamIndex(.loadThread) == nil {
            viewModel.apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.endParams.append(MailAPMEvent.FirstScreenLoaded.EndParam.load_thread_list_cost_time(0))
        }
        viewModel.apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.customPostEnd()
        /// 标记首屏渲染完成
        firstScreenDataHadLoad()
    }

    func mailThreadsChange(_ change: (threadId: String, labelIds: [String])) {
        for labelId in change.labelIds {
            filterLabel(labelId)
        }
    }

    func mailMultiThreadsChange(_ label2Threads: Dictionary<String, (threadIds: [String], needReload: Bool)>, _ hasFilterThreads: Bool) {
        for (labelId, _) in label2Threads {
            filterLabel(labelId)
        }
    }

    func filterLabel(_ labelId: String) {
        if (labelId == Mail_LabelId_Other && viewModel.currentLabelId == Mail_LabelId_Important) ||
            (labelId == Mail_LabelId_Important && viewModel.currentLabelId == Mail_LabelId_Other) {
            asyncRunInMainThread {
                self.viewModel.showPreviewCardIfNeeded(self.viewModel.currentLabelId == Mail_LabelId_Important ? Mail_LabelId_Other : Mail_LabelId_Important)
            }
        }
        if labelId == Mail_LabelId_Outbox {
            viewModel.fetchAndUpdateOutboxState()
        }
    }

    func mailThreadsLoadFailed(_ labelId: String, _ error: Error) {
        guard labelId == self.viewModel.currentLabelId else {
            return
        }
        MailLogger.error("mailThreadsLoadFailed: \(error), label: \(labelId)")
        // 这里主要是配置空页面的Cell要展示那个icon
        if let reachability = reachability {
            if reachability.connection != .none {
                status = .canRetry
                MailTracker.log(event: "email_page_fail", params: ["scene": currentLabelIsFirstShow ? "homepage" : "labellist"])
            } else {
                status = .noNet
                updateTableViewHeader(with: tableHeaderView.dismissNoNetTips())
            }
        }
        refreshThreadList()
        if self.hasFirstScreenRender {
            let type = MailAPMEvent.FirstScreenLoaded.EndParam.mode_hot_start
            apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.endParams.append(type)
        } else {
            let type = MailAPMEvent.FirstScreenLoaded.EndParam.mode_cold_start
            apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.endParams.append(type)
        }
        if error.mailErrorCode != 10023 { // 对齐安卓屏蔽启动过程中切账号的接口错误上报
            viewModel.apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.endParams.appendError(errorCode: error.mailErrorCode,
                                                                                  errorMessage: error.getMessage())
            viewModel.apmMarkThreadListEnd(status: MailAPMEventConstant.CommonParam.status_rust_fail, error: error)
            viewModel.apmHolder[MailAPMEvent.FirstScreenLoaded.self]?.customPostEnd()
        }
    }

    func updateUserEngagementSetting(smartInboxAlertRendered: Bool, smartInboxPromptRendered: Bool, hasChange: (Bool, Bool)) {
        var newSmartInboxAlertRendered: Bool = false
        var newSmartInboxPromptRendered: Bool = false
        if hasChange.0 {
            newSmartInboxAlertRendered = smartInboxAlertRendered
            newSmartInboxPromptRendered = !navbarShowTipsRedDot
        }
        if hasChange.1 {
            newSmartInboxAlertRendered = true
            newSmartInboxPromptRendered = smartInboxPromptRendered
        }
        Store.settingData.updateCurrentSettings(.statusSmartInboxOnboarding(.smartInboxAlertRendered(newSmartInboxAlertRendered)),
                                                        .statusSmartInboxOnboarding(.smartInboxPromptRendered(newSmartInboxPromptRendered)))
    }

    func _updateTitle(_ title: String) {
        if title != self.navBarTitleBehavior.value {
            titleDisposeBag = DisposeBag()
            if navbarShowLoading.value {
                navbarShowLoading.asObservable().subscribe(onNext: { [weak self] showLoading in
                    guard let `self` = self else { return }
                    if !showLoading {
                        self.navBarTitleBehavior.accept(title)
                    }
                }).disposed(by: self.titleDisposeBag)
            } else {
                navBarTitleBehavior.accept(title)
                reloadNavbar()
            }
        }
    }

    private func refreshThreadList() {
        viewModel.listViewModel.setThreadsListOfLabel(viewModel.currentLabelId, mailList: [])
        viewModel.listViewModel.isLastPage = true
        viewModel.syncDataSource()
        tableView.reloadData()
        exitMultiSelect()
        MailLogger.info("[MailHome_handle] refreshThreadList hide Loading")
        hiddenLoading()
    }

    func threadListDevTrack() {
        if !viewModel.hasFirstLoaded {
            MailTracker.endRecordTimeConsuming(event: Homeric.MAIL_DEV_THREAD_LIST_COST_TIME, params: nil)
            MailTracker.endRecordMemory(event: Homeric.MAIL_DEV_THREAD_LIST_MEMORY_DIFF, params: nil)
            viewModel.hasFirstLoaded = true
        }
        MailTracker.endRecordTimeConsuming(event: Homeric.MAIL_DEV_LABELS_CHANGE_COST_TIME, params: nil)
        MailTracker.endRecordMemory(event: Homeric.MAIL_DEV_LABELS_CHANGE_MEMORY_DIFF, params: nil)
    }

    @objc
    func mailResetThreadListLabel(_ notification: Notification) {
        markSelectedThreadId = notification.object as? String
        refreshLabel()
    }
    
    func didMoveToNewFolder(toast: String, undoInfo: (String, String)) {
        showMoveToNewFolderToast(toast, undoInfo: undoInfo)
    }
    
    func showMoveToNewFolderToast(_ toast: String, undoInfo: (String, String)) {
        let uuid = undoInfo.0
        guard !toast.isEmpty else {
            if !undoInfo.1.isEmpty {
                MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_Folder_MovedTo(undoInfo.1), on: self.view)
            }
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.normal) { [weak self] in // 因为连续dismiss，callback回调了但window还没回到主页，所以出toast时机需要延迟
            guard let `self` = self else { return }
            MailRoundedHUD.showSuccess(with: toast, on: self.view)
        }
    }

    // MARK: - UIView ThreadListHeaderManagerDelegate
    func makeTabelView() -> MailHomeTableView {
        let tableView = MailHomeTableView(frame: CGRect.zero, style: .plain)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.estimatedRowHeight = 0
        tableView.separatorStyle = .none
        tableView.allowsMultipleSelection = true
        tableView.tableHeaderView = tableHeaderView
        tableView.lu.register(cellSelf: MailHomeEmptyCell.self)
        tableView.lu.register(cellSelf: MailThreadListCell.self)
        tableView.accessibilityIdentifier = MailAccessibilityIdentifierKey.TableViewHomeKey
//        if !shouldAdjustPullRefresh {
            tableView.contentInsetAdjustmentBehavior = .never
//        }
        
        return tableView
    }

    // MARK: - UITableViewDelegate & UITableViewDataSource
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if viewModel.datasource.isEmpty {
            tableView.isScrollEnabled = false
            let showMultiView = Store.settingData.getAccountInfos().count > 1
            let diffHeight = showMultiView ? MailThreadListConst.mulitAccountViewHeight : 0
            return CGFloat.maximum(tableView.bounds.size.height - tableHeaderView.bounds.size.height - diffHeight, 0.01)
        } else {
            tableView.isScrollEnabled = true
            var height = mailHomeConst.CellHeight
            let cellVM = viewModel.datasource[indexPath.row]
            if viewModel.currentLabelId == Mail_LabelId_Stranger && userContext.featureManager.open(FeatureKey(fgKey: .stranger, openInMailClient: false)) {
                let titleWidth = cellVM.desc.getDesc().getTextWidth(font: UIFont.systemFont(ofSize: 14), height: CGFloat.greatestFiniteMagnitude)
                if titleWidth > view.bounds.width - 56 {
                    return mailHomeConst.CellStrangerCardHeight
                } else {
                    return mailHomeConst.CellStrangerCardDefaultHeight
                }
            }
            return height
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if viewModel.datasource.isEmpty {
            return  1
        } else {
            return viewModel.datasource.count
        }
    }

    func calculteYOffset() -> CGFloat {
        return (statusAndNaviHeight + (multiAccountView.isHidden ? 0 : MailThreadListConst.mulitAccountViewHeight) + headerViewManager.tableHeaderView.intrinsicContentSize.height) / 2.0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if viewModel.datasource.isEmpty {
            if status == .none {
                let defaultCell = UITableViewCell()
                defaultCell.selectedBackgroundView = UIView()
                return defaultCell
            }
            if let cell = tableView.dequeueReusableCell(withIdentifier: MailHomeEmptyCell.lu.reuseIdentifier) as? MailHomeEmptyCell {
                cell.centerYOffset = calculteYOffset()
                cell.isUnreadEmpty = viewModel.currentFilterType == .unread
                cell.type = viewModel.currentLabelName
                cell.status = status
                cell.isStrangerEmpty = viewModel.needShowStrangerModeEmpty()
                cell.selectionStyle = .none
                cell.frame = tableView.bounds
                if status == .canRetry { // 只有可以重试才需要埋这个埋点
                    InteractiveErrorRecorder.recordError(event: .threadlist_error_page,
                                                     errorCode: .rust_error,
                                                     tipsType: .error_page)
                }
                MailLogger.info("[MailHome] didShow empty cell currentLabel:\(viewModel.currentLabelId)")
                return cell
            }
        } else {
            if viewModel.datasource.count > indexPath.row {
                let cellVM = viewModel.datasource[indexPath.row]
                cellVM.currentLabelID = self.viewModel.currentLabelId
                if (isMultiSelecting && selectedRows.contains(indexPath)) || (rootSizeClassIsRegular && !isMultiSelecting && markSelectedThreadId == cellVM.threadID) {
                    tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                }
            }
            if let cell = tableView.dequeueReusableCell(withIdentifier: MailThreadListCell.lu.reuseIdentifier) as? MailThreadListCell {
                // 这个可能为nil
                cell.isMultiSelecting = isMultiSelecting
                cell.clearContentsBeforeAsynchronouslyDisplay = clearContentsBeforeAsynchronouslyDisplay
                cell.displaysAsynchronously = displaysAsynchronously
                var cellVM: MailThreadListCellViewModel?
                if viewModel.datasource.count > indexPath.row {
                    cellVM = viewModel.datasource[indexPath.row]
                    guard let cellVM = cellVM else { return UITableViewCell() }
                    cell.cellViewModel = cellVM
                    cell.setSelected(cellVM.threadID == markSelectedThreadId, animated: false)
                }
                cell.delegate = self
                cell.mailDelegate = self
                cell.cellType = .inbox
                cell.enableLongPress = true
                cell.longPressDelegate = self
                cell.selectedIndexPath = indexPath
                cell.rootSizeClassIsRegular = rootSizeClassIsRegular
                cell.accessibilityIdentifier = MailAccessibilityIdentifierKey.HomeCellKey + "\(indexPath.row)"
                return cell
            }
        }

        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        if rootSizeClassIsSystemRegular, !isMultiSelecting, let selectedRows = tableView.indexPathsForSelectedRows {
            guard !selectedRows.isEmpty, selectedRows.count == 1 else {
                mailAssertionFailure("[mail_home] tableView indexPathsForSelectedRows is empty, but call willDeselectRowAt function")
                return indexPath
            }
            guard indexPath.row < viewModel.datasource.count else {
                mailAssertionFailure("[mail_home] tableView indexPath.row >= viewModel.datasource.count willDeselectRowAt")
                return indexPath
            }
            let isUnread = viewModel.datasource[indexPath.row].isUnread
            if isUnread {
                let cell = tableView.cellForRow(at: indexPath)
                cell?.setSelected(true, animated: true)
                enterThread(at: indexPath.row, presentDraftEditorOnPad: true)
            }
            return nil // iPad 已读选中后不允许反选
        } else {
            return indexPath
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if isMultiSelecting && viewModel.datasource.count > indexPath.row {
            let selectedThreadId = viewModel.datasource[indexPath.row].threadID
            selectedThreadIds.lf_remove(object: selectedThreadId)
            return
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !isMultiSelecting, let selectedRows = tableView.indexPathsForSelectedRows {
            for selectedRow in selectedRows where selectedRow != indexPath {
                tableView.deselectRow(at: selectedRow, animated: false)
            }
        }
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        if viewModel.datasource.count < 1 {
            if status == .canRetry {
                loadThreadListData(labelId: viewModel.currentLabelId, filterType: viewModel.currentFilterType,
                                   title: viewModel.currentLabelName, showLoading: true)
            } else if viewModel.currentFilterType == .unread && !viewModel.needShowStrangerModeEmpty() {
                self.viewModel.filterViewModel.didSelectFilter(type: .allMail)
            }
            return
        }
        let cell = tableView.cellForRow(at: indexPath)
        if isMultiSelecting {
            let limitCount = 100
            if selectedRows.count >= limitCount {
                let text = BundleI18n.MailSDK.Mail_Toast_Select_more_label(limitCount)
                MailRoundedHUD.showTips(with: text, on: self.view)
                cell?.setSelected(false, animated: true)
            } else {
                cell?.setSelected(true, animated: true)
                let selectedThreadId = viewModel.datasource[indexPath.row].threadID
                selectedThreadIds.append(selectedThreadId)
            }
            return
        } else {
            if !(cell?.isSelected ?? true) {
                cell?.setSelected(true, animated: true)
            }
        }
        enterThread(at: indexPath.row, presentDraftEditorOnPad: true)

        let value = NewCoreEvent.labelTransfor(labelId: labelsMenuController?.viewModel.selectedID ?? "",
                                               allLabels: labelsMenuController?.viewModel.labels ?? [])
        NewCoreEvent.threadListClickThread(filterType: viewModel.currentFilterType, labelItem: value,
                                           displayType: Store.settingData.threadDisplayType())
    }

    // 加载更多
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if (indexPath.row == viewModel.datasource.count - 10) && !viewModel.isLastPage() {
            viewModel.loadMore()
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return CGFloat.leastNormalMagnitude
        return self.tableHeaderView.intrinsicContentSize.height
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    // MARK: - MailThreadListCellDelegate
    func didClickFlag(_ cell: MailThreadListCell, cellModel: MailThreadListCellViewModel) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        var datasource = viewModel.datasource
        let isFlag = datasource.changeFlagState(at: indexPath.row)
        viewModel.listViewModel.setThreadsListOfLabel(viewModel.currentLabelId, mailList: datasource)
        viewModel.syncDataSource()
        tableView.reloadData()
        NewCoreEvent.threadListFlagAction(isFlag, isMultiSelected: isMultiSelecting).post()
        if isFlag {
            threadActionDataManager.flag(threadID: cellModel.threadID,
                                         fromLabel: viewModel.currentLabelId,
                                         msgIds: [],
                                         sourceType: .threadItemAction)
        } else {
            threadActionDataManager.unFlag(threadID: cellModel.threadID,
                                           fromLabel: viewModel.currentLabelId,
                                           msgIds: [],
                                           sourceType: .threadItemAction)
        }
    }

    // MARK: - Multi-Select MailLongPressDelegate
    func cellLongPress(reconizer: MailLongPressGestureRecognizer, view: UIView) {
        enterMultiSelect(reconizer)
        MailTracker.log(event: Homeric.EMAIL_MULTISELECT_THREADLIST, params: ["source": "longclick"])
#if ALPHA || Debug
        let kvStore = MailKVStore(space: .global, mSpace: .global)
        if kvStore.bool(forKey: MailDebugViewController.kMailDataDebug) {
            var description = ""
            var title = ""
            if let cell = view as? MailThreadListCell {
                description = cell.cellViewModel?.originData.debugDescription ?? ""
                title = cell.cellViewModel?.title ?? ""
            }
            
            let alert = UIAlertController(title: "DataDebug", message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "[\(title)] detail data", style: .destructive, handler: { [weak self] (_) in
                guard let `self` = self else { return }
                let vc = MailDetailDataVC()
                vc.detailData = description
                self.navigator?.push(vc, from: self, animated: true)
            }))
           
            alert.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: nil))
            if let popoverController = alert.popoverPresentationController {
              popoverController.sourceView = view
              popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            present(alert, animated: true, completion: nil)
        }
#endif
    }

    @objc
    func enterMultiSelect(_ reconizer: MailLongPressGestureRecognizer? = nil) {
        if isMultiSelecting ||
            viewModel.currentLabelId == Mail_LabelId_Outbox ||
            viewModel.currentLabelId == Mail_LabelId_SHARED {
            return
        }
        tableView.es.stopPullToRefresh(ignoreDate: true)

        clearContentsBeforeAsynchronouslyDisplay = false
        tableView.isScrollEnabled = true
        closeTableViewHeader()
        multiAccountView.isHidden = true
        reloadListInMultiSelect(true)
        isMultiSelecting = true
        sendMailButton.isHidden = true
        if let reconizer = reconizer {
            let indexPath = reconizer.selectedIndexPath
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            if viewModel.datasource.count > indexPath.row {
                let selectedThreadId = viewModel.datasource[indexPath.row].threadID
                selectedThreadIds.append(selectedThreadId)
            }
        }
        if let larkNavibar = navbarBridge?.getLarkNaviBar() {
            threadActionBar.isHidden = false
            larkNavibar.addSubview(threadActionBar)
            threadActionBar.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
    }

    func updateThreadActionBar() {
        /// user can open editing mode from "muliti select" button
        /// so remove the logic that auto close editing mode when selectedRows.count <= 0
//        if selectedRows.count <= 0 {
//            tableView.setEditing(false, animated: false)
//            threadActionBar.threadActionSet.removeAll()
//            threadActionBar.removeFromSuperview()
//            animator.forceChangeSearchBarHeight(to: searchBarInherentHeight, animated: true)
//            tableView.contentInset.top = tableViewTopContentInset// + noNetViewHeight()
//            return
//        }
        guard isMultiSelecting else {
            threadActionBar.eraseThreadActions()
            threadActionBar.removeFromSuperview()
            return
        }
//        if tableView.contentOffset.y < noNetViewHeight() {
//            tableView.setContentOffset(CGPoint(x: 0, y: -noNetViewHeight()), animated: true)
//        }
        // dispatch sub thread for caculating not blocking main thread.
        var cellViewModels = [MailThreadListCellViewModel]()
        let selectedRows = self.selectedRows
        if selectedRows.count > 0 {
            for selectedRow in selectedRows where
            self.viewModel.datasource.count > selectedRow.row {
                cellViewModels.append(self.viewModel.datasource[selectedRow.row])
            }
        } else {
            /// if user did't selected any thread, insert first thread's actions
            if let cellViewModel = self.viewModel.datasource.first {
                cellViewModels.append(cellViewModel)
            }
        }
        // calculate thread actions here.
        var indexedActions = [MailIndexedThreadAction]()
        var allHasDraftOrSchedule = true
        cellViewModels.forEach { (viewModel) in
            // must update every time because label always change when use operation.
            let actions = MailThreadActionCalculator.calculateThreadListThreadActions(fromLabel: self.viewModel.currentTagID,
                                                                                      cellViewModel: viewModel)
            if viewModel.draft == nil && viewModel.scheduleSendTimestamp <= 0 {
                allHasDraftOrSchedule = false
            } else if let draft = viewModel.draft, draft.isEmpty
                        && viewModel.scheduleSendTimestamp <= 0 {
                allHasDraftOrSchedule = false
            }
            indexedActions.append(contentsOf: actions)
        }
        // 如果viewModel里面全部都含有草稿，则不展示emlAsAttachment
        if allHasDraftOrSchedule {
            indexedActions.removeAll { action in
                action.action == .emlAsAttachment
            }
        }
        threadActionBar.setThreadActions(indexedActions, scheduleSendCount: selectedRows.count, needUpdateUI: true)

        threadActionBar.updateTitle(selectedRows.count)
        updateActionsLabel()
        if viewModel.datasource.count < selectedRows.count {
            return
        }
        threadActionBar.threadIDs = selectedRows.map({
            if viewModel.datasource.count > $0.row {
                return viewModel.datasource[$0.row].threadID
            } else {
                return ""
            }
        })
        threadActionBar.labelIds = [viewModel.currentLabelId]

        let mailAddresses = selectedRows.map({
            if viewModel.datasource.count > $0.row {
                return viewModel.datasource[$0.row].address
            } else {
                return ""
            }
        })
        let isAllFromAuthorized = selectedRows.allSatisfy({
            if viewModel.datasource.count > $0.row {
                return viewModel.datasource[$0.row].isFromAuthorized
            } else {
                return false
            }
        })
        threadActionBar.spamAlertContent = SpamAlertContent(
            threadIDs: threadActionBar.threadIDs,
            fromLabelID: viewModel.currentLabelId,
            mailAddresses: mailAddresses,
            unauthorizedAddresses: [],
            isAllAuthorized: isAllFromAuthorized,
            shouldFetchUnauthorized: true
        )
    }

//    func currentTagID() -> String {
//        var tagID = self.currentLabelId
//        if labels.first(where: { $0.labelId == self.currentLabelId && $0.tagType == .folder }) != nil {
//            tagID = MailLabelId.Folder.rawValue
//        }
//        return tagID
//    }

    func updateActionsLabel() {
        // 从数据源中取交集
        threadActionBar.homeResultItems = viewModel.datasource
        threadActionBar.updateActionsLabel(selectedRows: selectedRows)
    }

    // MARK: - NavigationDrawer

    /// 更改 filter
    func didSelectedLabel(_ labelId: String, title: String, isSystemLabel: Bool) {
        MailLogger.info("[mail_home] didSelectedLabel labelId: \(labelId)")
        viewModel.listViewModel.cancelGetThreadList()
        viewModel.triggerMailClientRefreshIfNeeded(labelId)
        // 业务数据统计
        var tagType = "System label"
        if let newTag = viewModel.labels.first(where: { $0.labelId == labelId }) {
            if newTag.tagType == .folder {
                tagType = "folder"
            } else if !newTag.isSystem {
                tagType = "Custom label"
            }
        }
        MailTracker.log(event: Homeric.EMAIL_FILTER,
                        params: ["from": self.viewModel.currentLabelId,
                                 "to": labelId,
                                 "type": tagType])

        viewModel.updateVisitSmartInboxTimestampIfNeeded(labelId)
        viewModel.updateVisitStrangerTimestampIfNeeded(labelId)
        if !smartInboxLabels.contains(labelId) || (smartInboxLabels.contains(viewModel.currentLabelId) && smartInboxLabels.contains(labelId)) {
            updateTableViewHeader(with: tableHeaderView.dismissSmartInboxPreviewCard())
        } else {
            self.viewModel.showPreviewCardIfNeeded(labelId == Mail_LabelId_Important ? Mail_LabelId_Other : Mail_LabelId_Important)
        }
//        noNetView.isHidden = true

        markSelectedThreadId = nil
        if Display.pad && viewModel.currentLabelId != labelId {
            navigator?.showDetail(UIViewController.DefaultDetailController(), wrap: LkNavigationController.self, from: self)
        }
        switchLabelAndFilterType(labelId, labelName: title, filterType: .allMail)
        loadThreadListData(labelId: labelId, filterType: .allMail, title: title, showLoading: true)
        tableHeaderView.updatePreviewCard(labelID: viewModel.currentLabelId)
        MailTracker.startRecordTimeConsuming(event: Homeric.MAIL_DEV_LABELS_CHANGE_COST_TIME, params: nil)
        MailTracker.startRecordMemory(event: Homeric.MAIL_DEV_LABELS_CHANGE_MEMORY_DIFF, params: nil)
        MailTracker.log(event: Homeric.EMAIL_LABEL_SELECTED,
                        params: [MailTracker.labelIDParamKey(): labelId,
                                 MailTracker.labelTypeParamKey(): MailTracker.getLabelType(isSystemLabel: isSystemLabel)])
        trackPageViewEvent()
    }
    
    func switchLabelAndFilterType(_ labelId: String, labelName: String, filterType: MailThreadFilterType) {
        if viewModel.currentLabelId != labelId {
            currentLabelIsFirstShow = false
        }
        viewModel.switchLabelAndFilterType(labelId, labelName: labelName, filterType: filterType)
        if userContext.featureManager.open(.stranger, openInMailClient: false) && _firstScreenDataReady.value {
            MailLogger.info("[mail_stranger] cardlist switchLabelAndFilterType showCardList IfNeeded, labelId: \(labelId)")
            if StrangerCardConst.strangerInLabels.contains(labelId) {
                showStrangerCardListViewIfNeeded()
            } else {
                resetStrangerCardListView()
            }
        } else {
            headerViewManager.dismissStrangerCardListView()
        }
    }
    
    func loadThreadListData(labelId: String, filterType: MailThreadFilterType, title: String, showLoading: Bool) {
        exitMultiSelect()
        updateTitle(title)
        if showLoading {
            self.showMailLoading()
        }

        if self.viewModel.currentLabelId == Mail_LabelId_Outbox {
            dismissOutboxTips()
        } else {
            showOutboxTips(viewModel.outboxCount)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.ultraShort) {
            if self.viewModel.datasource.count > 0 {
                self.srcollToTop()
            }
        }
        viewModel.listViewModel.getMailListFromLocal(filterType: filterType)
        self.tableView.es.stopLoadingMore()
        self.tableView.es.resetNoMoreData()
        labelsMenuController?.viewModel.selectedID = labelId // updateSelectedIDAndRefresh(labelId)
    }

    func didRetryReloadData(labelId: String) {
        MailLogger.info("[mail_home] didRetryReloadData labelId: \(labelId)")
        let title = labelId == Mail_LabelId_Important ? BundleI18n.MailSDK.Mail_SmartInbox_Important : BundleI18n.MailSDK.Mail_Folder_Inbox
        switchLabelAndFilterType(labelId, labelName: title, filterType: viewModel.currentFilterType)
        loadThreadListData(labelId: labelId,
                           filterType: viewModel.currentFilterType,
                           title: title,
                           showLoading: true)
    }
    // MARK: - TabBarDelegate
    func doubleTapEvent() {
        let event = NewCoreEvent(event: .email_tab_click)
        let value = NewCoreEvent.labelTransfor(labelId: labelsMenuController?.viewModel.selectedID ?? "",
                                               allLabels: labelsMenuController?.viewModel.labels ?? [])
        event.params = ["click": "double_click",
                        "label_item": value,
                        "mail_account_type": Store.settingData.getMailAccountType()]
        event.post()
        
        if userContext.featureManager.open(FeatureKey(fgKey: .doubleTab, openInMailClient: true)) {
            processDoubleTab()
        } else {
            processDoubleTabOld()
        }
    }
    
    func processDoubleTab() {
        doubleTabDisposeBag = DisposeBag()
        shouldCheckNavigationBarVisibility = false
        let visibleCells = tableView.visibleCells.filter({
            var frame = $0.frame
            frame.origin = $0.convert(.zero, to: self.view)
            return frame.maxY > getTopViewHeight()
        })
        guard let firstVisibleCell = visibleCells.first as? MailThreadListCell,
              let firstVisibleIndexPath = tableView.indexPath(for: firstVisibleCell)
        else { return }
        
        let diffOffsetY = (Store.settingData.getCachedAccountList()?.count ?? 1) > 1 ? MailThreadListConst.mulitAccountViewHeight : 0
        let tableHeight = self.tableView.frame.size.height
        let contentHeight = self.tableView.contentSize.height
        let executeIncremental = self.footer.executeIncremental
        var bottomOffset = contentHeight - tableHeight + executeIncremental //刚好到底部时的contentOffset
        var targetIdx = 0
        // 当前处于列表中最后一封未读邮件时，double tab要回到第一封未读
        for i in 0..<viewModel.datasource.count where viewModel.datasource[i].isUnread == true {
            targetIdx = i
            break
        }
        
        // 在底部时，不需要往下寻找未读
        if self.tableView.contentOffset.y < bottomOffset {
            //firstVisble往下的第一封未读
            for i in min(max(0, (firstVisibleIndexPath.row + 1)), viewModel.datasource.count)..<viewModel.datasource.count where viewModel.datasource[i].isUnread == true {
                targetIdx = i
                break
            }
        }
        let needToScrollUp = firstVisibleIndexPath.row >= targetIdx
        let rect = tableView.rectForRow(at: IndexPath(row: targetIdx, section: 0))
        
        // 往上滚 or 不会滚动到列表底部 时才允许滚动。
        if (rect.origin.y - diffOffsetY <  bottomOffset) || needToScrollUp {
            tableView.setContentOffset(CGPoint(x: rect.origin.x,
                                               y: rect.origin.y - diffOffsetY),
                                       animated: true)
        } else if bottomOffset > diffOffsetY { // 防止出现被下拉的情况
            tableView.setContentOffset(CGPoint(x: rect.origin.x,
                                               y: bottomOffset),
                                       animated: true)
            
            // 判断是否需要loadmore
            if targetIdx >= viewModel.datasource.count - 10 && !viewModel.isLastPage() {
                // 监听一下contentSize，在loadMore成功后跳转到目标thread
                tableView.rx.observe(CGSize.self, "contentSize")
                            .subscribe(onNext: { [weak self] newSize in
                                guard let contentSize = newSize else { return }
                                guard contentHeight != contentSize.height else { return }
                                guard let `self` = self else { return }
                                guard self.loadMoreDone else { return }
                                self.loadMoreDone = false
                                let contentHeight = contentSize.height
                                bottomOffset = contentHeight - tableHeight + executeIncremental
                                let rectY = min(rect.origin.y - diffOffsetY, bottomOffset)
                                self.doubleTabDisposeBag = DisposeBag()
                                // 直接执行setContentOffset并没有生效，延期则正常，原因未知
                                let delayTime: Double = 0.2
                                DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) {
                                    self.tableView.setContentOffset(CGPoint(x: rect.origin.x,
                                                                            y: rectY),
                                                                    animated: true)
                                }
                            })
                            .disposed(by: doubleTabDisposeBag)
                viewModel.loadMore()
                tableView.layoutIfNeeded()
            }
        }
    }
    
    func processDoubleTabOld() {
        shouldCheckNavigationBarVisibility = false
        let visibleCells = tableView.visibleCells.filter({
            var frame = $0.frame
            frame.origin = $0.convert(.zero, to: self.view)
            return frame.minY > getTopViewHeightOld()
        })
        guard let firstVisibleCell = visibleCells.first, let firstVisibleIndexPath = tableView.indexPath(for: firstVisibleCell) else { return }

        var targetIdx = 0
        for i in min(max(0, (firstVisibleIndexPath.row + 1)), viewModel.datasource.count)..<viewModel.datasource.count where viewModel.datasource[i].isUnread == true {
            targetIdx = i
            break
        }
        let rect = tableView.rectForRow(at: IndexPath(row: targetIdx, section: 0))
        let diffOffsetY = (Store.settingData.getCachedAccountList()?.count ?? 1) > 1 ? MailThreadListConst.mulitAccountViewHeight : 0
        tableView.setContentOffset(CGPoint(x: rect.origin.x,
                                           y: rect.origin.y - diffOffsetY),
                                   animated: true)
    }

    // MARK: - Stat
    func statMoveAction(type: String, threadID: String) {
        let params = ["type": type,
                      "threadid": threadID,
                      "location": "threadlist",
                      "currentfilter": self.viewModel.currentLabelId]
        MailTracker.log(event: Homeric.EMAIL_MOVE, params: params)
    }

    // MARK: - MailOutboxTips
    // notification of outbox state change
    func mailOutboxSendStateChange(_ change: (messageId: String, deliveryState: MailClientMessageDeliveryState)) {
        MailHomeController.logger.debug( "MailHome outbox state change \(change.deliveryState)")
        /// 如果当前处于outbox，则需要更新列表
        if self.viewModel.currentLabelId == Mail_LabelId_Outbox {
            /// 状态是 delivered，则直接刷新列表 (datasource已做删除操作)
            if change.deliveryState == .delivered {
                self.viewModel.syncDataSource()
                self.tableView.reloadData()
            } else {
                /// 状态是 toSend, 则获取最新的列表数据
                self.refreshCurrentThreadList()
            }
        }
        let count = self.viewModel.outboxCount
        self.showOutboxTips(count)
        self.labelsMenuController?.viewModel.updateOutboxCount(count)
    }

    func mailOutboxCountRefresh(_ count: Int) {
        labelsMenuController?.viewModel.updateOutboxCount(count)
        showOutboxTips(count)
    }

    func showOutboxTips(_ count: Int) {
        let kvStore = userContext.getCurrentAccountContext().accountKVStore
        let dismiss: Bool = kvStore.bool(forKey: UserDefaultKeys.dismissMillOutboxTip)
        if count == 0 || dismiss || self.viewModel.currentLabelId == Mail_LabelId_Outbox {
            /// 隐藏 outbox tips
            updateTableViewHeader(with: tableHeaderView.dismissOutboxTips())
        } else {
            /// 显示outbox tips
            updateTableViewHeader(with: tableHeaderView.showOutboxTips(count))
        }
        MailHomeController.logger.debug( "outbox showOutboxTips count:\(count) dismiss:\(dismiss)")
    }

    func dismissOutboxTips() {
        updateTableViewHeader(with: tableHeaderView.dismissOutboxTips())
        MailHomeController.logger.debug( "dismiss outbox tips view")
    }

    override func keyBindings() -> [KeyBindingWraper] {
        var mailKeyBindings = [
            KeyCommandBaseInfo(
                input: "k",
                modifierFlags: .command,
                discoverabilityTitle: BundleI18n.MailSDK.Mail_ThreadList_IPadShortCutSearch
            ).binding { [weak self] in
                self?.onSelectSearch()
            }.wraper
        ]

        if rootSizeClassIsRegular {
            mailKeyBindings.append(contentsOf: [
                KeyCommandBaseInfo(
                    input: UIKeyCommand.inputUpArrow,
                    modifierFlags: .command,
                    discoverabilityTitle: BundleI18n.MailSDK.Mail_ThreadList_IPadShortCutScrollUp
                ).binding { [weak self] in
                    self?.preThread()
                }.wraper,

                KeyCommandBaseInfo(
                    input: UIKeyCommand.inputDownArrow,
                    modifierFlags: .command,
                    discoverabilityTitle: BundleI18n.MailSDK.Mail_ThreadList_IPadShortCutScrollDown
                ).binding { [weak self] in
                    self?.nextThread()
                }.wraper
            ])
        }

        mailKeyBindings.append(contentsOf: [
            KeyCommandBaseInfo(
                input: "n",
                modifierFlags: .command,
                discoverabilityTitle: BundleI18n.MailSDK.Mail_ThreadList_IPadShortCutNewMail
            ).binding(
                target: self,
                selector: #selector(createNewMail)
            ).wraper,
            KeyCommandBaseInfo(
                input: "n",
                modifierFlags: .control,
                discoverabilityTitle: BundleI18n.MailSDK.Mail_ThreadList_IPadShortCutNewMail
            ).binding(
                target: self,
                selector: #selector(createNewMail)
            ).wraper
        ])

        return super.keyBindings() + mailKeyBindings
    }
    @objc
    func preThread() {
        guard !isMultiSelecting else { return }
        guard self.viewModel.currentLabelId != Mail_LabelId_Draft else { return }
        guard !labelsMenuShowing else { return }
        if let selectedId = self.markSelectedThreadId, let selectedIndex = self.viewModel.datasource.firstIndex(where: { $0.threadID == selectedId }), selectedIndex - 1 >= 0 {
            self.enterThread(with: self.viewModel.datasource[selectedIndex - 1].threadID)
            self.tableView.scrollToRow(at: IndexPath(item: selectedIndex - 1, section: 0), at: UITableView.ScrollPosition.middle, animated: true)
        }
    }
    @objc
    func nextThread() {
        guard !isMultiSelecting else { return }
        guard self.viewModel.currentLabelId != Mail_LabelId_Draft else { return }
        guard !labelsMenuShowing else { return }
        if let selectedId = self.markSelectedThreadId,
           let selectedIndex = self.viewModel.datasource.firstIndex(where: { $0.threadID == selectedId }),
           selectedIndex + 1 < self.viewModel.datasource.count {
            self.enterThread(with: self.viewModel.datasource[selectedIndex + 1].threadID)
            self.tableView.scrollToRow(at: IndexPath(item: selectedIndex + 1, section: 0), at: UITableView.ScrollPosition.middle, animated: true)
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        _scrollViewDidScroll(scrollView)
    }
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        _scrollViewWillBeginDragging(scrollView)
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        _scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        _scrollViewDidEndDecelerating(scrollView)
    }
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        _scrollViewDidEndScrollingAnimation(scrollView)
    }
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        _scrollViewWillEndDragging(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        _scrollViewShouldScrollToTop(scrollView)
    }
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        _scrollViewDidScrollToTop(scrollView)
    }
}

// MARK: state数据handle
extension MailHomeController {
    func handleRefreshedDatas(_ datas: [MailThreadListCellViewModel]) {
        viewModel.resetWhiteScreenDetect()
        let preDatasource = viewModel.datasource
        if delayReload {
            DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.normal, execute: { [weak self] in
                self?.refreshThreadListTableView(datas, preDatasource: preDatasource)
            })
        } else {
            refreshThreadListTableView(datas, preDatasource: preDatasource)
        }
    }

    func refreshThreadListTableView(_ datas: [MailThreadListCellViewModel], preDatasource: [MailThreadListCellViewModel]) {
        if self.viewModel.apmHolder[MailAPMEvent.ThreadListLoaded.self] == nil {
            /// 推送过来引起的refresh
            self.viewModel.apmMarkThreadListStart(sence: .sence_reload)
        }
        if !self.viewModel.listViewModel.isFilteringChange() {
            self.viewModel.syncDataSource(datas: datas)
            self.tableView.reloadData()
        } else {
            MailLogger.info("[mail_swipe_actions] handleRefreshedDatas reloadData when -- isFilteringChange is true")
        }
        if !self.userContext.featureManager.open(.unreadPreloadMailOpt, openInMailClient: true) {
            self.preloadCurrentDatasource() // 旧预加载时机
        }
        self.status = .none
        MailHomeController.logger.info("[mail_home_init] getMailListFromLocal refresh labelId: \(self.viewModel.currentLabelId) datasource count:\(self.viewModel.datasource.count)")
        self.updateThreadActionBar()
        self.threadListDevTrack()
        self.delayReload = false
        self.viewModel.ignoreSettingPush = true
        self.viewModel.startedFetchThreadList = false
        self.hiddenLoading()
        self.firstScreenAPMReport()
        self.handleListFooter()
        self.handleSelectedStatusInSplitMode(preDatasource: preDatasource)
        self.handleRefreshListDataReadyStatus()
    }

    func handleRefreshListDataReadyStatus() {
        var refreshListDataStatus = refreshListDataReady.value
        guard refreshListDataStatus.0 != .unknown else {
            return
        }
        if refreshListDataStatus.1 == false {
            MailLogger.info("MailUnreadPreload -- handleRefreshListDataReadyStatus: \(refreshListDataStatus)")
            refreshListDataStatus.1 = true
            refreshListDataReady.accept(refreshListDataStatus)
        }
    }

    func handleSelectedStatusInSplitMode(preDatasource: [MailThreadListCellViewModel]) {
        // On split mode, handle switching to next thread
        if self.rootSizeClassIsRegular, let markSelectedThreadId = self.markSelectedThreadId,
           !self.viewModel.datasource.isEmpty, !self.viewModel.datasource.map({ $0.threadID }).contains(markSelectedThreadId) {
            guard markSelectedThreadId != self.markRecalledThreadId else {
                self.navigator?.showDetail(SplitViewController.makeDefaultDetailVC(), wrap: LkNavigationController.self, from: self)
                return
            }

            // unread filter需要屏蔽此逻辑
            guard !self.viewModel.filterViewModel.didSwitchToUnread else {
                self.viewModel.filterViewModel.didSwitchToUnread = false
                self.enterThread(with: nil)
                return
            }
            // selectedThread is gone, try switching to next thread
            var hasVisitedEnterThread = false
            let fisrtThreadAfterEnterThread = preDatasource.first { (vm) -> Bool in
                if !hasVisitedEnterThread {
                    if vm.threadID == markSelectedThreadId {
                        hasVisitedEnterThread = true
                    }
                    // filter out threads before selectedThread
                    return false
                } else {
                    // find the first thread after selectedThread & exists in new datasource
                    return self.viewModel.datasource.contains(where: { $0.threadID == vm.threadID })
                }
            }
            self.enterThread(with: fisrtThreadAfterEnterThread?.threadID ?? self.headerViewManager.tableHeaderView.strangerCardListView?.selectedThreadID)
        } else if self.rootSizeClassIsRegular, self.viewModel.datasource.isEmpty {
            self.navigator?.showDetail(SplitViewController.makeDefaultDetailVC(), wrap: LkNavigationController.self, from: self)
        }

        // 选中的cell和detailVC中实际的thread对齐
        if self.rootSizeClassIsRegular,
           let detailId = self.findDetailVCThreadId(),
           self.viewModel.datasource.map({ $0.threadID }).contains(detailId) {
            if let curId = self.markSelectedThreadId {
                if curId != detailId {
                    self.markSelectedThreadId = detailId
                    self.viewModel.syncDataSource()
                    self.tableView.reloadData()
                }
            } else {
                self.markSelectedThreadId = detailId
                self.viewModel.syncDataSource()
                self.tableView.reloadData()
            }
        }
    }

    func handleLoadMoreDatas(_ datas: [MailThreadListCellViewModel]) {
        hiddenLoading()
        if FeatureManager.open(.offlineCache, openInMailClient: false) {
            let offline = isOffline()
            self.footer.canCacheMore = offline
            if offline && !self.viewModel.isLastPage() {
                self.tableView.es.noticeNoMoreData()
            } else if self.viewModel.isLastPage() {
                tableView.es.stopLoadingMore()
                tableView.es.noticeNoMoreData()
            } else if self.viewModel.needAutoLoadMore() {
                self.tableView.es.stopLoadingMore()
                self.tableView.es.autoLoadMore()
            } else {
                self.tableView.es.stopLoadingMore()
            }
        } else {
            tableView.es.stopLoadingMore()
            if viewModel.isLastPage() {
                self.tableView.es.noticeNoMoreData()
            }
        }
    }

    func handleDatasEmpty() {
        viewModel.resetWhiteScreenDetect()
        status = .empty
        refreshThreadList()
        threadListDevTrack()
        firstScreenAPMReport()
    }

    func handleDatasError(labelId: String, err: Error) {
        viewModel.resetWhiteScreenDetect()
        mailThreadsLoadFailed(labelId, err)
    }

    func handleListFooter() {
        if userContext.featureManager.open(.offlineCache, openInMailClient: false) &&
            viewModel.currentLabelId != Mail_LabelId_Outbox {
            let offline = isOffline()
            self.footer.canCacheMore = offline
            if offline && !self.viewModel.isLastPage() {
                self.tableView.es.noticeNoMoreData()
                return
            } else if self.viewModel.isLastPage() {
                tableView.es.stopLoadingMore()
                tableView.es.noticeNoMoreData()
            } else if self.viewModel.needAutoLoadMore() {
                self.tableView.es.stopLoadingMore()
                self.tableView.es.autoLoadMore()
            } else {
                self.tableView.es.stopLoadingMore()
            }
        } else if self.viewModel.needAutoLoadMore() {
            self.footer.canCacheMore = false
            self.tableView.es.stopLoadingMore()
            self.tableView.es.autoLoadMore()
        } else {
            self.footer.canCacheMore = false
            self.tableView.es.stopLoadingMore()
        }
        self.tableView.es.resetNoMoreData()
        if self.viewModel.isLastPage() {
            self.tableView.es.noticeNoMoreData()
        }
    }

    func handleStrangerCardEmpty() {
        if markSelectedThreadId == nil && rootSizeClassIsRegular {
            navigator?.showDetail(SplitViewController.makeDefaultDetailVC(), wrap: LkNavigationController.self, from: self)
        }
        headerViewManager.dismissStrangerCardListView()
        viewModel.strangerCardList?.batchConfirmAlert?.dismiss(animated: true)
        viewModel.strangerCardList?.batchConfirmAlert = nil
        viewModel.batchConfirmAlert?.dismiss(animated: true)
        viewModel.batchConfirmAlert = nil
    }

    func isOffline() -> Bool {
        if let reach = Reachability() {
            return reach.connection == .none
        } else {
            return false
        }
    }
}

// MARK: UI Element handle
extension MailHomeController {
    private func handleSmartInboxPreviewCardResp(labelId: String,
                                                 resp response: Email_Client_V1_MailGetNewMessagePreviewCardResponse) {
        let senderNames = response.previewCard.senderNames
        MailLogger.info("Send getPreviewCard request: hasSmartInboxPreviewCard: \(response.hasPreviewCard) count: \(senderNames.count)")
        if response.hasPreviewCard,
           senderNames.count > 0,
           self.headerViewManager.tableHeaderView.shouldUpdateSmartInboxPreviewCard(labelID: labelId, fromNames: response.previewCard.senderNames),
           smartInboxLabels.contains(self.viewModel.currentLabelId) {
            let headerView = self.headerViewManager.tableHeaderView.showSmartInboxPreviewCard(labelID: labelId, fromNames: response.previewCard.senderNames)
            self.updateTableViewHeader(with: headerView)
            self.showSmartInboxTips(.previewCardPop)
        } else {
            self.updateTableViewHeader(with: self.headerViewManager.tableHeaderView.dismissSmartInboxPreviewCard())
        }
    }
}

// MARK: REFACTOR 暂时先放这里 为了编的过
extension MailHomeController {
    func autoChangeLabel(_ labelId: String, title: String, isSystemLabel: Bool, updateTimeStamp: Bool = true) {
        MailLogger.info("[mail_home] autoChangeLabel labelId: \(labelId)")
        if updateTimeStamp {
            viewModel.updateVisitSmartInboxTimestampIfNeeded(labelId)
            viewModel.updateVisitStrangerTimestampIfNeeded(labelId)
        }
        if !smartInboxLabels.contains(labelId) || (smartInboxLabels.contains(viewModel.currentLabelId) && smartInboxLabels.contains(labelId)) {
            updateTableViewHeader(with: self.headerViewManager.tableHeaderView.dismissSmartInboxPreviewCard())
        } else {
            viewModel.showPreviewCardIfNeeded(labelId == Mail_LabelId_Important ? Mail_LabelId_Other : Mail_LabelId_Important)
        }
        switchLabelAndFilterType(labelId, labelName: title, filterType: viewModel.currentFilterType)
        loadThreadListData(labelId: labelId, filterType: viewModel.currentFilterType, title: title, showLoading: false)
        self.headerViewManager.tableHeaderView.updatePreviewCard(labelID: viewModel.currentLabelId)
        VMtrackPageViewEvent()
    }

    func resetPriorityLabel(by setting: MailSetting, hasPush: Bool = false) {
        let smartInboxEnable = setting.smartInboxMode
        updateLabelListSmartInboxFlag(smartInboxEnable)
        let shouldChangeToImportant = !self.labelListFgDataError && smartInboxEnable
        let needChange = viewModel.currentLabelId != Mail_LabelId_Important || hasPush
        if shouldChangeToImportant && needChange {
            self.viewModel.createNewThreadList(labelId: Mail_LabelId_Important, labelName: BundleI18n.MailSDK.Mail_SmartInbox_Important)
            self.autoChangeLabel(Mail_LabelId_Important,
                                 title: BundleI18n.MailSDK.Mail_SmartInbox_Important,
                                 isSystemLabel: true, updateTimeStamp: false)
        } else if !shouldChangeToImportant && hasPush {
            // 从push跳转进messagelist 返回需要刷到inbox/important的label下
            self.viewModel.createNewThreadList(labelId: Mail_LabelId_Inbox, labelName: BundleI18n.MailSDK.Mail_Folder_Inbox)
            self.autoChangeLabel(Mail_LabelId_Inbox,
                                 title: BundleI18n.MailSDK.Mail_Folder_Inbox,
                                 isSystemLabel: true, updateTimeStamp: false)
        }
    }
}

extension MailHomeController {
    func handleAddressChange() {
        if viewModel.listViewModel.mailFilter.enableBlock {
            return
        }
        self.viewModel.syncDataSource()
        self.tableView.reloadData()
    }
}
