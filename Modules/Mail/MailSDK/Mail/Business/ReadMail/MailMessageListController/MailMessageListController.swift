//
//  MailMessageListController.swift
//  LarkMail
//
//  Created by 谭志远 on 2019/6/10.
//

import UIKit
import WebKit
import LarkUIKit
import SnapKit
import RxSwift
import RxCocoa
import EENavigator
import LKCommonsLogging
import LarkLocalizations
import LarkAlertController
import Homeric
import LarkAppLinkSDK
import LarkFoundation
import Reachability
import RustPB
import LarkGuideUI
import LarkActionSheet
import LarkTraitCollection
import LarkSceneManager
import LarkSplitViewController
import UniverseDesignColor
import UniverseDesignActionPanel
import UniverseDesignIcon
import ThreadSafeDataStructure
import UniverseDesignTheme
import UniverseDesignToast
import Heimdallr
import UniverseDesignButton
import UniverseDesignFont
import LarkEMM
import LarkSensitivityControl
import LarkAIInfra

/// Override removeFromParent() to dismiss MoreActionController when switching thread on iPad
class MailMessageListNavigationController: LkNavigationController {
    override func removeFromParent() {
        super.removeFromParent()
        if let vc = presentedViewController as? MailMessagePadRemoveHandling {
            vc.dismissOnMailMessageRemove()
        }
    }
}

protocol MailMessagePadRemoveHandling {
    func dismissOnMailMessageRemove()
}

enum TipsType: String {
    case shareMember = "98"
    case shareOwner = "99"
}

protocol MailMessageListExternalDelegate: AnyObject {
    func didMoveToNewFolder(toast: String, undoInfo: (String, String))
    func msgListManageStrangerThread(threadIDs: [String]?, status: Bool, isSelectAll: Bool, maxTimestamp: Int64?, fromList: [String]?)
}

struct MessageListFeedInfo {
    var feedCardId: String
    var name: String = ""
    var address: String = ""
    var avatar: String = ""
}

// 初始化参数，用于记录一些信息
struct MessageListStatInfo {
    enum FromType: String {
        case unknown
        case search
        case chatSideBar
        case chat
        case notification
        case threadList
        case imColla
        case emlPreview
        case emailReview
        case imFile
        case bot
        case deleteMail
        case feed
        /// 有新case，要不新加FromType enum，要不加到fromString
        case other
        
        var shouldShowTrustSender: Bool {
            switch self {
            case .imFile, .chat, .emlPreview, .emailReview:
                return false
            default:
                return true
            }
        }
    }
    var fromString: String?
    let from: FromType
    // 三言两语说不清 @liutefeng
    let newCoreEventLabelItem: String
    var searchHintFrom: String = ""
    var isTrashOrSpamList: String = ""
    /// 默认为初始化时间，路由场景为用户点击时间
    var startTime: TimeInterval = Date().timeIntervalSince1970
}

enum MessageListGuide {
    case topAttachmentGuide
    case darkModeGuide
}

class MailMessageListController: MailBaseViewController, MailMessageListControllerViewModelDelegate,
                                 WKNavigationDelegate, WKUIDelegate,
                                 MailEditLabelsDelegate, UICollectionViewDataSource,
                                 UICollectionViewDelegate, UICollectionViewDelegateFlowLayout,
                                 UIScrollViewDelegate, TranslateTargetListDelegate, MailMessageListPageVMDelegate, MailCreateDraftButtonDelegate {
    
    static var startClickTime: Int?
    /// 用于统计 App 生命周期第一次读信
    static var isFirstRead = true
    static let PageCellIdentifier = "MailMessageListPageCellIdentifier"
    private var isTopAttachmentGuideShowing = false // 标记附件置顶Onboard是否正在展示，用于ipad旋转时适配
    let disposeBag = DisposeBag()
    var keyboardDisposeBag = DisposeBag()
    var downloadDisposeBag = DisposeBag()
    var previousAccountID: String?
    //true表示内容区始终LightMode，false跟随系统
    var isContentLight: Bool
    let threadActionDataManager = ThreadActionDataManager.shared
    var actionsFactory: MailMessageListActionFactory = MailMessageListActionFactory()
    var unReadMessageCount: Int = 0 {
        didSet {
            if unReadMessageCount < 0 {
                unReadMessageCount = 0
            }
        }
    } // 统计电梯未读数
    var readMessageList: [String] = [] // 临时维护一个已读列表，防止推送未及时计数错误
    let containerView = UIView(frame: .zero)
    
    private(set) lazy var sendMailButton: UIButton = self.makeSendMailButton()
    lazy var tipsBtn: UDButton = self.makeTipsBtn()
    lazy var draftListBtn: UDButton = self.makeDraftListBtn()
    
    lazy var headerViewManager: MailMessageListHeaderManager = {
        let manager = MailMessageListHeaderManager(accountContext: accountContext, feedCardId: self.feedCardId, from:self)        
        manager.delegate = self
        return manager
    }()
    
    var messagelistHeader: MailMessageListHeaderView {
        return headerViewManager.mailmessagelistHeaderView
    }
    
    var isLoading = false
    var isDeinit = false
    static var isShortcutEnabled: Bool {
        return !Display.pad
    }
    var eventComponents: [MailMessageEventHandleComponent] = []
    lazy var imageViewerService = MailImageViewerService(accountContext: accountContext)
    lazy var attachmentPreviewRouter = AttachmentPreviewRouter(accountContext: accountContext, source: .readMail)
    var viewHasAppeared = false
    var itemsCountForDelete = UInt.max
    var myUserId: String?
    var feedCardId: String = ""
    var isFeedCard: Bool = false
    var fromNotice: Bool = false
    var messageListFeedInfo: MessageListFeedInfo? = nil
    var cancellingScheduleSend: Bool = false
    var subject: String {
        return getOldestMessage(messageItems: mailItem.messageItems)?.subject ?? ""
    }

    var oldestFrom: String {
        return getOldestMessage(messageItems: mailItem.messageItems)?.from.mailDisplayNameNoMe ?? ""
    }

    private weak var recalledChangeAlert: LarkAlertController?
    private var reloadDataOnRecallConfirm = false
    private var alertingRecallMsgIds: [String]?

    let domReadyMonitor = MailMessageListRenderMonitor()

    weak var foldButton: UIButton?
    private var isAllowAllLabels: Bool = false
    override var navigationBarTintColor: UIColor {
        return UIColor.ud.bgBase
    }

    // MARK: - 外部传入
    var fromLabel: String = ""
    var messageId: String?
    var keyword: String = ""
    var subjects: [String] = []
    var needRelocateCurrentLabel = false
    var isSwipingBack = false
    weak var externalDelegate: MailMessageListExternalDelegate?
    var searchFolderTag: String?

    // Handle orientation change
    var containerViewEdgesConstraint: Constraint?
    var updateContentOffsetOnOrientationChanged = false
    private var rightNaviItems: [TitleNaviBarItem] = []
    private var leftNaviItems: [TitleNaviBarItem] = []
    private var isLandscapeInterface: Bool = false

    // javascript functions called before domReady is not reliable
    // will add to queue and execute after domReady
    var pendingJavaScriptQueue = [String: [String]]()

    // Translate
    /// Mark translate start time, make sure animation is more than 0.5s to keep animation smooth
    lazy var translatingIdAndInterval = [String: TimeInterval]()
    lazy var translateManager = MailTranslateManager(translateLanguageProvider: accountContext.provider.translateLanguageProvider, accountContext: accountContext)
    /// Only handle first visible when corresponding webivew domready
    lazy var pendingFirstVisibleIDs = Set<String>()
    var threadBodyHtmlLengthMap = ThreadSafeDataStructure.SafeDictionary<String, Int>(synchronization: .readWriteLock)
    var isInSearchMode: Bool {
        return messageNavBar.isInSearchMode
    }
    private var senderBlocker: BlockSenderManager?

    private let topThreadActionTypesPlanB: [ActionType] = [.flag, .unFlag]
    var logThreadActionSource: MailTracker.SourcesType {
        return .threadAction
    }
    var isFullScreenMode: Bool {
        if let vc = self.larkSplitViewController, vc.splitMode == .secondaryOnly {
            return true
        } else {
            return false
        }
    }
    var unreadPreloadedMailMessageListView: MailMessageListView?

    private var didLayoutRightNavBarCount = 0
    private var hasBackItemTapped = false

    lazy var httpDownloader: MailHttpSchemeDownloader = MailHttpSchemeDownloader(cacheService: accountContext.cacheService)

    // 前置检查 Onboard 是否需要显示
    // 绝大部分 Onboard 只出现一次，而检查接口 checkShouldShow 会有几毫秒的耗时，可能影响读信的流畅性体验。因此将某些仅与 user 相关的检查条件前置，并保存起来。
    // Onboard 展示之后记得更新一下这个字典，避免重复展示
    private var canShowGuide: ThreadSafeDataStructure.SafeDictionary<MessageListGuide, Bool> = [:] + .readWriteLock

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if accountContext.featureManager.open(.messageListRotate) {
            return .allButUpsideDown
        } else {
            return .portrait
        }
    }

    internal var threadActions: [MailIndexedThreadAction] = []
    internal var threadLabels: [MailFilterLabelCellModel] = []
    internal var dataSource: [MailMessageListPageViewModel] {
        self.realViewModel.allMailViewModels
    }
    internal var pageWidth: CGFloat = 0
    internal let initIndex: Int
    internal var currentPageIndex: Int = 0 {
        willSet {
            if currentPageIndex != newValue {
                domReadyMonitor.onSwipe(viewModel.threadId)
                onCurrentWebViewDisappear()
                currentWebViewWillChange()
            }
        }
        didSet {
            if let pageCell = currentPageCell {
                if pageCell.isDomReady {
                    currentWebViewDidDomReady()
                }
                if pageCell.webViewDidLoadFinish() {
                    currentWebViewDidLoadFinish()
                }
            }
            if currentPageIndex != oldValue {
                trackSpamBannerAppear()
            }
            updateSceneTargetContentIdentifier()
        }
    }

    var realViewModel: MailMessageListControllerViewModel
    var initDate: Date?

    /// 是否是EML读信
    open var isEML: Bool {
        return false
    }

    internal var viewModel: MailMessageListPageViewModel {
        if let viewModel = realViewModel[currentPageIndex] {
            if viewModel.labelId.isEmpty {
                viewModel.labelId = fromLabel
            }
            return viewModel
        } else {
            return MailMessageListPageViewModel(accountContext: accountContext, threadId: "", labelId: "", isFlag: false)
        }
    }
    internal var mailItem: MailItem {
        get {
            let defaultItem = MailItem(feedCardId: self.feedCardId,
                                       threadId: "",
                                       messageItems: [],
                                       composeDrafts: [],
                                       labels: [],
                                       code: .none,
                                       isExternal: false,
                                       isFlagged: false,
                                       isRead: false,
                                       isLastPage: true)
            if let viewModel = realViewModel[currentPageIndex] {
                if viewModel.labelId.isEmpty {
                    viewModel.labelId = fromLabel
                }
                if let mailItem = viewModel.mailItem {
                    return mailItem
                } else {
                    return defaultItem
                }
            } else {
                return defaultItem
            }
        }
        set {
            if newValue.threadId == self.viewModel.threadId {
                self.viewModel.mailItem = newValue
                self.viewModel.mailItem?.feedCardId = self.feedCardId
            } else {
                let viewModel = realViewModel[threadId: newValue.threadId]
                viewModel?.mailItem = newValue
                viewModel?.mailItem?.feedCardId = self.feedCardId
                /// viewModel?.bodyHtml = nil
            }
        }
    }
    internal var webView: (WKWebView & MailBaseWebViewAble)? {
        var web: (WKWebView & MailBaseWebViewAble)?
        if let viewModel = realViewModel[currentPageIndex] {
            web = getWebViewOf(threadId: viewModel.threadId)
        } else {
            web = MailNewBaseWebView()
        }
        return web
    }

    let statInfo: MessageListStatInfo
    var didLoad = false
    var didLoadFirstScreen = false
    var isFullReadMessage: Bool {
        if let viewModel = realViewModel[currentPageIndex] {
            return viewModel.isFullReadMessage
        } else {
            return false
        }
    }

    internal var startTrackPageView = false
    var isPreloadRendering = false

    internal var pageIsScrolling = false
    let preRenderRelay = BehaviorRelay<Void>(value: ())

    internal static let logger = Logger.log(MailMessageListController.self, category: "Module.MailMessageListController")
    internal var didRenderDic = [String: Bool]()
    var currentAccount: MailAccount?
    var searchProvider: MailSendDataProvider = MailSendDataSource()
    var barButtonAlignmentRectInset: UIEdgeInsets {
        // 414 以上宽度，navigationBarButton左右间距为 12pt
        // 以下，间距为 8pt
        return view.bounds.width >= 414 ? UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4) : .zero
    }
    let messageNavBar : MailMessageNavBar

    var webViewContentInsetTop: CGFloat {
        return messageNavBar.navBarHeight
    }
    var didMarkAsRead: Bool = false
    var isPreloadMail = false
    var markRecalledThreadId: String?
    var terminatedRetryThreads = Set<String>()
    var atAddressNameMap = ThreadSafeDataStructure.SafeDictionary<String, String>(synchronization: .readWriteLock)
    var atUidAddressMap = ThreadSafeDataStructure.SafeDictionary<String, String>(synchronization: .readWriteLock)
    var atUidAddressCheck = ThreadSafeDataStructure.SafeDictionary<String, String>(synchronization: .readWriteLock)
    var atUpdateAddressNameMap = ThreadSafeDataStructure.SafeDictionary<String, String>(synchronization: .readWriteLock)
    let addressChangeQueue: DispatchQueue = DispatchQueue(label: "MailMessage.AddresChange.Queue", qos: .userInitiated)
    let addressNameFg = MailAddressChangeManager.shared.addressNameOpen()
    lazy var chatAIFg = {
        return self.openChatAI()
    }()
    var aiPageService: MyAIChatModeConfig.PageService?
    var aiIconClick: Bool = false
    var fpsFlag = false
    let fpsRelay = BehaviorRelay<Bool>(value: false)
    lazy var chatAIService: MailAIChatService = {
        let service = MailAIChatService(accountContext: self.accountContext)
        return service
    }()
    // MARK: life Circle
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }



    /// 查看全文
    static func makeForReadMore(accountContext: MailAccountContext,
                                threadId: String,
                                labelId: String,
                                mailItem: MailItem,
                                fullReadMessageId: String,
                                statInfo: MessageListStatInfo,
                                keyword: String,
                                forwardInfo: DataServiceForwardInfo?,
                                externalDelegate: MailMessageListExternalDelegate?) -> MailMessageListController {
        let vm = MailMessageListPageViewModel(accountContext: accountContext, threadId: threadId, labelId: labelId, isFlag: mailItem.isFlagged)
        vm.isFullReadMessage = true
        vm.fullReadMessageId = fullReadMessageId
        vm.mailItem = mailItem
        return MailMessageListController(accountContext: accountContext,
                                         dataSource: [vm],
                                         threadId: threadId,
                                         labelId: labelId,
                                         statInfo: statInfo,
                                         keyword: keyword,
                                         forwardInfo: forwardInfo,
                                         externalDelegate: externalDelegate)
    }
    
    static func makeForFeed(accountContext: MailAccountContext,
                            messageListFeedInfo: MessageListFeedInfo,
                            statInfo: MessageListStatInfo,
                            forwardInfo: DataServiceForwardInfo?,
                            fromNotice: Int = 0) -> MailMessageListController {
        let vm = MailMessageListPageViewModel(accountContext: accountContext, feedCardId: messageListFeedInfo.feedCardId)
        let vc = MailMessageListController(accountContext: accountContext,
                                           dataSource: [vm],
                                           threadId: "",
                                           labelId: "",
                                           statInfo: statInfo,
                                           externalDelegate: nil,
                                           messageListFeedInfo: messageListFeedInfo,
                                           fromNotice: fromNotice)
        return vc
    }

    /// 从其他路径路由进入，如：notification跳转
    static func makeForRouter(accountContext: MailAccountContext,
                              threadId: String,
                              labelId: String,
                              messageId: String = "",
                              keyword: String = "",
                              statInfo: MessageListStatInfo,
                              forwardInfo: DataServiceForwardInfo?) -> MailMessageListController {
        let vm = MailMessageListPageViewModel(accountContext: accountContext, threadId: threadId, labelId: labelId, isFlag: false, messageId: messageId)
        let vc = MailMessageListController(accountContext: accountContext,
                                           dataSource: [vm],
                                           threadId: threadId,
                                           labelId: labelId,
                                           statInfo: statInfo,
                                           keyword: keyword,
                                           forwardInfo: forwardInfo,
                                           externalDelegate: nil)
        return vc
    }

    /// 从 ThreadList 进入
    static func makeForMailHome(accountContext: MailAccountContext,
                                threadList: [MailThreadListCellViewModel],
                                threadId: String,
                                labelId: String,
                                statInfo: MessageListStatInfo,
                                pageWidth: CGFloat,
                                templateRender: MailMessageListTemplateRender?,
                                externalDelegate: MailMessageListExternalDelegate?) -> MailMessageListController {
        let templateRender = templateRender ?? MailMessageListTemplateRender(accountContext: accountContext)
        return MailMessageListController(accountContext: accountContext,
                                         dataSource: MailMessageListPageViewModel.getListFromThreadList(threadList, accountContext: accountContext, labelId: labelId),
                                         threadId: threadId,
                                         labelId: labelId,
                                         templateRender: templateRender,
                                         statInfo: statInfo,
                                         pageWidth: pageWidth,
                                         externalDelegate: externalDelegate)
    }

    /// 从搜索进入
    static func makeForSearch(accountContext: MailAccountContext,
                              searchList: [MailSearchCellViewModel],
                              threadId: String,
                              labelId: String,
                              keyword: String,
                              subjects: [String],
                              statInfo: MessageListStatInfo,
                              externalDelegate: MailMessageListExternalDelegate?) -> MailMessageListController {
        return MailMessageListController(accountContext: accountContext,
                                         dataSource: MailMessageListPageViewModel.getListFromSearchList(searchList, accountContext: accountContext, labelId: labelId),
                                         threadId: threadId,
                                         labelId: labelId,
                                         statInfo: statInfo,
                                         keyword: keyword,
                                         subjects: subjects,
                                         externalDelegate: externalDelegate)
    }

    typealias ViewModelConfig = (MailMessageListTemplateRender, DataServiceForwardInfo?) -> MailMessageListControllerViewModel

    let accountContext: MailAccountContext

    init(accountContext: MailAccountContext,
         dataSource: [MailMessageListPageViewModel],
         threadId: String,
         labelId: String,
         templateRender: MailMessageListTemplateRender? = nil,
         statInfo: MessageListStatInfo,
         keyword: String = "",
         subjects: [String] = [],
         previousAccountID: String? = nil,
         forwardInfo: DataServiceForwardInfo? = nil,
         viewModelConfig: ViewModelConfig? = nil,
         pageWidth: CGFloat = 0,
         externalDelegate: MailMessageListExternalDelegate?,
         messageListFeedInfo: MessageListFeedInfo? = nil,
         fromNotice: Int = 0) {
        self.accountContext = accountContext
        self.initDate = Date()
        self.myUserId = accountContext.user.userID
        let render: MailMessageListTemplateRender
        if let templateRender = templateRender {
            render = templateRender
            render.accountContext = accountContext
        } else {
            render = MailMessageListTemplateRender(accountContext: accountContext)
        }
        self.feedCardId = messageListFeedInfo?.feedCardId ?? ""
        self.isFeedCard = !self.feedCardId.isEmpty && threadId.isEmpty && self.accountContext.featureManager.open(FeatureKey(fgKey: .mailToFeed, openInMailClient: false))
        self.fromNotice = self.isFeedCard ? (fromNotice != 0) : false
        self.messageListFeedInfo = messageListFeedInfo
        realViewModel = MailMessageListControllerViewModel(templateRender: render, imageService: accountContext.imageService, forwardInfo: forwardInfo, isBot: statInfo.from == .bot, isFeed: self.isFeedCard, fromNotice: self.fromNotice)
        if let viewModelConfig = viewModelConfig {
            realViewModel = viewModelConfig(render, forwardInfo)
        }

        if statInfo.from == .deleteMail {
            realViewModel.isForDeletePreview = true
            isAllowAllLabels = true
        }

        if !MailMessageListController.isShortcutEnabled {
            let viewModel = dataSource.first(where: { $0.threadId == threadId && $0.labelId == labelId }) ?? MailMessageListPageViewModel(accountContext: accountContext, threadId: threadId, labelId: labelId, isFlag: false)
            viewModel.keyword = keyword
            realViewModel.updateDataSource([viewModel])
        } else {
            dataSource.forEach { vm in
                vm.keyword = keyword
            }
            realViewModel.updateDataSource(dataSource)
        }
        self.initIndex = self.realViewModel.indexOf(threadId: threadId) ?? 0
        self.currentPageIndex = self.initIndex
        self.statInfo = statInfo
        self.keyword = keyword
        self.subjects = subjects
        self.fromLabel = labelId
        self.pageWidth = pageWidth
        self.isContentLight = realViewModel.templateRender.isContentAlwaysLightMode()
        self.externalDelegate = externalDelegate
        if feedCardId.isEmpty {
            self.messageNavBar = MailMessageNavBar()
        } else {
            self.messageNavBar = MailMessageNavBar(type: .FeedNavBarType, address: self.messageListFeedInfo?.address ?? "", name: self.messageListFeedInfo?.name ?? "")
        }
        super.init(nibName: nil, bundle: nil)
        if !Store.settingData.mailClient {
            self.eventComponents.append(MailMessageCalendarEventComponent(delegate: self, calendarProvider: accountContext.provider.calendarProvider))
        }
        self.onInit(threadId)
        MailMessageListController.logStartTime(name: "on_init")
        if isFeedCard {
            self.markActiveMailPage()
        }
    }

    deinit {
        MailMessageListController.startClickTime = nil
        if !self.isFeedCard {
            MailMessageListViewsPool.reset()
            MailMessageListViewsPool.preload(provider: accountContext)
        }
        MailMessageListController.logger.info("message list deinit \(viewModel.threadId)")
        MailTracker.endRecordTimeConsuming(event: Homeric.EMAIL_THREAD_DISPLAY, params: ["threadid": mailItem.threadId], useNewKey: true)
        MailTracker.log(event: "email_message_list_closed_view", params: ["thread_id": mailItem.threadId, "label_item": statInfo.newCoreEventLabelItem,
                                                                          "mail_display_mode": "list_mode",
                                                                          "result_hint_from": statInfo.searchHintFrom])
        isDeinit = true
        Store.sharedContext.value.markEnterThreadId = nil
        if MailMessageListViewsPool.fpsOpt && self.fpsFlag {
            HMDFPSMonitor.shared().leaveFluencyCustomScene(withUniq: "Lark.MailSDK.Message.Scroll")
            self.fpsFlag = false
        }
        if self.isFeedCard {
            markInActiveMailPage()
        }
        self.closeChatModeScene()
    }

    override var serviceProvider: MailSharedServicesProvider? {
        accountContext
    }

    override func viewDidLoad() {
        MailMessageListController.logStartTime(name: "on_view_did_load")
        super.viewDidLoad()
        setupNativeView()
        isNavigationBarHidden = true
        onLoad(viewModel.threadId)
        businessLog()
        addObserver()
        updateSceneTargetContentIdentifier()
        checkGuideShouldShow()
        _ = openChatAI(checkAlert: true)
        if self.accountContext.featureManager.open(FeatureKey(fgKey: .mailToFeed, openInMailClient: false))
            && self.isFeedCard {
            checkShowDraftBtn()
        }
        MailMessageListController.logger.info("message list view did load")
    }
    
    func setupNativeView() {
        if accountContext.featureManager.open(FeatureKey(fgKey: .darkMode, openInMailClient: true)) {
            containerView.backgroundColor = UIColor.ud.bgBase
        } else {
            containerView.backgroundColor = UIColor.ud.bgBase.alwaysLight
        }
        pageWidth = view.bounds.width
        
        view.addSubview(containerView)
        view.addSubview(messageNavBar)
        if isFeedCard {
            (self.messageNavBar.titleNavBar as? MailFeedTitleNaviBar)?.delegate = self
            self.messageNavBar.feedDelegate = self
            view.addSubview(sendMailButton)
            sendMailButton.snp.makeConstraints { (make) in
                make.right.equalTo(view.safeAreaLayoutGuide.snp.right).inset(16)
                let bottomOffset: CGFloat = 16
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(bottomOffset)
                make.width.height.equalTo(48)
            }
            view.addSubview(draftListBtn)
            draftListBtn.snp.makeConstraints { make in
                make.right.equalTo(sendMailButton.snp.left).offset(-12)
                make.centerY.equalTo(sendMailButton)
            }

            view.addSubview(tipsBtn)
            tipsBtn.snp.makeConstraints { make in
                make.bottom.equalTo(draftListBtn.snp.top).offset(-16)
                make.right.equalTo(view.safeAreaLayoutGuide.snp.right).inset(16)
            }
        
            if let address = self.messageListFeedInfo?.address {
                headerViewManager.enterFeed(feedCardID: self.feedCardId, address: address) { [weak self] in
                    guard let self = self else { return }
                    self.view.addSubview(self.messagelistHeader)
                    self.messagelistHeader.snp.makeConstraints { make in
                        make.top.equalTo(self.messageNavBar.snp.bottom)
                        make.width.equalToSuperview()
                    }
                    self.containerView.snp.remakeConstraints { make in
                        make.top.equalToSuperview().offset(self.messagelistHeader.previewCardCurrentTopMargin() + self.view.safeAreaInsets.top)
                        make.left.right.bottom.equalToSuperview()
                    }
                }
            }
            
        }
        if fromLabel == Mail_LabelId_Stranger && accountContext.featureManager.open(.stranger, openInMailClient: false) {
            messageNavBar.titleNavBar.backgroundColor = .ud.bgBody
        }
        messageNavBar.snp.makeConstraints { (make) in
            make.top.centerX.equalToSuperview()
            make.width.equalTo(containerView)
        }
        containerView.snp.makeConstraints { (make) in
            self.containerViewEdgesConstraint = make.edges.equalToSuperview().constraint
        }
        
        setupMessageContentView()

        #if DEBUG
        addStartLoadBtn()
        #endif
        loadCurrentAccount()
        accountContext.editorLoader.preloadEditor()

        supportSecondaryOnly = true
        supportSecondaryPanGesture = true
        keyCommandToFullScreen = true

        RootTraitCollection.observer
            .observeRootTraitCollectionWillChange(for: self)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                if let moreVC = self.presentedViewController as? MoreActionViewController {
                    moreVC.dismiss(animated: true, completion: nil)
                }
                self.setupMessageActions(mailItem: self.mailItem, triggerByTraitChange: true)
            }).disposed(by: disposeBag)

        if isFullReadMessage {
            showLoading()
        }
    }

    func setupMessageContentView() {
        if let unreadPreloadedMailMessageListView = unreadPreloadedMailMessageListView, unreadPreloadedMailMessageListView.superview != containerView, collectionView == nil {
            containerView.addSubview(unreadPreloadedMailMessageListView)
            unreadPreloadedMailMessageListView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        } else if collectionView == nil {
            // create collectionView
            let flowLayout = UICollectionViewFlowLayout()
            flowLayout.scrollDirection = .horizontal
            flowLayout.minimumLineSpacing = 0
            flowLayout.minimumInteritemSpacing = 0
            flowLayout.sectionInset = .zero
            let collection = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
            collection.showsHorizontalScrollIndicator = false
            collection.showsVerticalScrollIndicator = false
            collection.isPagingEnabled = true
            collection.register(MailMessageListPageCell.self, forCellWithReuseIdentifier: MailMessageListController.PageCellIdentifier)
            collection.backgroundColor = UIColor.ud.bgBase
            collection.delegate = self
            collection.dataSource = self
            collection.isPrefetchingEnabled = false
            collection.contentInsetAdjustmentBehavior = .never
            collection.delaysContentTouches = false
            collectionView = collection

            automaticallyAdjustsScrollViewInsets = false
            view.backgroundColor = UIColor.ud.bgBase

            if let collectionView = collectionView {
                containerView.addSubview(collectionView)
                collectionView.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
            }
        }
    }

    #if DEBUG
    private func addStartLoadBtn() {
        let kvStore = MailKVStore(space: .global, mSpace: .global)
        guard (kvStore.value(forKey: MailDebugViewController.kMailDelayLoadTemplate) ?? false) == true else {
            return
        }
        let startLoadBtn = UIButton()
        startLoadBtn.setTitle("Press to start load html", for: .normal)
        startLoadBtn.setTitleColor(.black, for: .normal)
        containerView.addSubview(startLoadBtn)
        startLoadBtn.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        startLoadBtn.addTarget(self, action: #selector(self.startLoad(_:)), for: .touchUpInside)
    }

    @objc
    private func startLoad(_ sender: UIButton) {
        sender.removeFromSuperview()
        let currentPageIndex = self.currentPageIndex
        if let pageCell = collectionView?.cellForItem(at: IndexPath(item: currentPageIndex, section: 0)) as? MailMessageListPageCell {
            pageCell.delayingHtmlLoad = false
            pageCell.render(
                by: pageCell.viewModel,
                baseURL: realViewModel.templateRender.template.baseURL,
                provider: accountContext,
                mailActionItemsBlock: { [weak self] in
                    self?.bottomActionItemsFor(currentPageIndex) ?? []
            })
        }
    }
    #endif

    func loadCurrentAccount() {
        guard currentAccount == nil else {
            return
        }
        Store.settingData.getAccountList()
            .subscribe(onNext: { [weak self] (resp) in
                guard let `self` = self else { return }
                if let account = resp.accountList.first(where: { $0.mailAccountID == resp.currentAccountId }) {
                    self.currentAccount = account
                    if self.realViewModel.isBot, self.accountContext.featureManager.open(.openBotDirectly, openInMailClient: false), self.currentPageCell?.isDomReady != true {
                        // skip
                    } else if self.realViewModel.isForDeleteSingleMessage() {
                      // skip
                    } else {
                        self.setupThreadActions(mailItem: self.mailItem)
                    }
                }
            }).disposed(by: self.disposeBag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let currentCell = collectionView?.cellForItem(at: IndexPath(row: currentPageIndex, section: 0)),
           currentCell.bounds != .zero,
           currentCell.bounds != collectionView?.bounds {
            // push其他页面后进行横竖屏切换后，返回后需要cell尺寸需要更新
            MailMessageListController.logger.info("didAppear invalidateLayout")
            collectionView?.collectionViewLayout.invalidateLayout()
        }
        trackSpamBannerAppear()
        MailMessageListController.logger.info("message list threadId:\(viewModel.threadId) viewDidAppear")
        isSwipingBack = false
        viewHasAppeared = true
        MailMessageListController.logger.info("didAppear navCount \(didLayoutRightNavBarCount), domReady \(currentPageCell?.isDomReady == true)")
        if didLayoutRightNavBarCount > 0, currentPageCell?.isDomReady == true {
            // 避免didAppear发生在layout后导致不出onboard
            showDarkModeGuideIfNeeded()
        }
        // 预加载需要判断是否是超长图，超长图加载原图，依赖读信页面的渲染宽度
        accountContext
            .sharedServices
            .preloadServices
            .updateDisplayWidth(view.frame.width)
        self.aiIconClick = false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        MailMessageListController.logger.info("viewDidLayoutSubviews navBarHeight \(messageNavBar.bounds.height), safeTop \(view.safeAreaInsets.top), Bottom \(view.safeAreaInsets.bottom)")
        if let currentCellSize = collectionView?.cellForItem(at: IndexPath(item: currentPageIndex, section: 0))?.bounds.size,
           currentCellSize != containerView.bounds.size {
            collectionView?.collectionViewLayout.invalidateLayout()
        }
        // 判断下 messengerBar 的高度
        // 排除iPhone 横屏的场景
        let checkNavBarHeight = {
            return !(Display.phone && UIDevice.current.orientation.isLandscape)
        }
        if checkNavBarHeight() && messageNavBar.bounds.height <= messageNavBar.navBarHeight {
            // 上方状态栏高度小于或等于实际bar高度，说明上方安全区域高度异常
            // async 后再次检查，确保页面布局结束
            let delayTime: Double = 1.0
            DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) { [weak self] in
                guard let self = self else {
                    return
                }
                if checkNavBarHeight() && self.messageNavBar.bounds.height <= self.messageNavBar.navBarHeight {
                    mailAssertionFailure(.messageListSafeArea)
                }
            }
        }
        didLayoutRightNavBarCount = messageNavBar.rightItemsMap.count
        MailMessageListController.logger.info("didLayout backTap \(hasBackItemTapped),appear \(viewHasAppeared),navcount \(messageNavBar.rightItemsMap.count),domReady \(currentPageCell?.isDomReady == true)")
        if !hasBackItemTapped, viewHasAppeared, messageNavBar.rightItemsMap.count > 0, currentPageCell?.isDomReady == true {
            // layout&&domready后出onboard，确保位置正常
            showDarkModeGuideIfNeeded()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupLeftNavActionItems(triggerByTraitChange: false)
        MailMessageListController.logger.info("message list threadId:\(viewModel.threadId) viewWillAppear")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        checkBlank()
        if presentedViewController == nil {
            resetToPortrait()
        }
        if isMovingFromParent, let state = navigationController?.interactivePopGestureRecognizer?.state,
           (state == .began || state == .changed) {
            isSwipingBack = true
        }
        MailRoundedHUD.remove(on: self.view)
        MailMessageListController.logger.info("message list threadId:\(viewModel.threadId) viewWillDisappear")
        onCurrentWebViewDisappear()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let collectionView = collectionView {
            let indexToReload = collectionView.indexPathsForVisibleItems.filter { collectionView.cellForItem(at: $0)?.isHidden == true }
            collectionView.reloadItems(at: indexToReload)
        }
        MailMessageListController.logger.info("message list threadId:\(viewModel.threadId) viewDidDisappear")
        if isSwipingBack {
            backCallback?()
        }
        if isInSearchMode {
            // 进入其他页面时，退出正文搜索
            exitContentSearch()
        }

        currentMailMessageListView?.postMessageLoadEvent(isUserLeave: true)

        if let lastLoadingTime = currentMailMessageListView?.lastStartLoadingTime {
            let netStatus = LarkPushDataManager.shared.dynamicNetStatus.value.netWorkStatusValue()
            MailTracker.log(
                event: "email_read_user_leave_blank",
                params: [
                    "mail_loading_time": (Date().timeIntervalSince1970 - lastLoadingTime) * 1000,
                    "net_status": netStatus
                ]
            )
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        //将操作栏dismiss
        if let MoreActionVC = self.presentedViewController as? MoreActionViewController{
            MoreActionVC.dismiss(animated: false, completion: nil)
        }
        if !Display.pad && isInSearchMode {
            exitContentSearch()
        }
        updateContentOffsetOnOrientationChanged = true

        // Update right nav items & moreActionVC
        if Display.phone {
            if UIDevice.current.orientation.isLandscape {
                isLandscapeInterface = true
                if let moreActionVC = presentedViewController as? MailMoreActionController {
                    moreActionVC.animatedView(isShow: false)
                }
            } else {
                isLandscapeInterface = false
            }
        }
        pageWidth = size.width
        self.closeTopAttachmentGuideIfNeeded()

        // update collectionView
        coordinator.animate(alongsideTransition: { [weak self] (_) in
            guard let `self` = self else { return }
            self.collectionView?.collectionViewLayout.invalidateLayout()
            self.collectionView?.scrollToItem(at: IndexPath(row: self.currentPageIndex, section: 0), at: .left, animated: false)
            self.currentPageCell?.mailMessageListView?.viewWillTransition(to: size)
        }) { [weak self] (_) in
            guard let `self` = self else { return }
            self.updateContentOffsetOnOrientationChanged = false

            if Display.phone {
                if self.isLandscapeInterface {
                    self.messageNavBar.setRightItems([])
                } else {
                    self.messageNavBar.setRightItems(self.rightNaviItems)
                }
            } else {
                if self.feedCardId.isEmpty {
                    self.setupMessageActions(mailItem: self.mailItem)
                } else {
                    self.feedSetupMessageLeftActions()
                }
            }
            self.updateTopAttachmentGuideFrame()
        }
        super.viewWillTransition(to: size, with: coordinator)
    }

    open override func viewDidTransition(to size: CGSize) {
        self.setupMessageActions(mailItem: self.mailItem)
    }

    // 处理 iPad 下通过拖拽改变分屏模式
    open override func splitVCSplitModeChange(split: SplitViewController) {
        super.splitVCSplitModeChange(split: split)
        self.setupMessageActions(mailItem: self.mailItem)
    }

    override func willEnterForeground() {
        MailMessageListController.logger.info("MailMessageList willEnterForeground")
        super.willEnterForeground()
        /// if webview is crash blank, reload page
        if let aWebView = webView {
            if aWebView.isCrashBlank() {
                collectionView?.reloadData()
                MailMessageListController.logger.error("mail message list webview is crash blank")
            }
        } else {
            collectionView?.reloadData()
            MailMessageListController.logger.error("mail message list webview is discard")
        }
    }

    override func didEnterBackground() {
        MailMessageListController.logger.info("MailMessageList didEnterBackground")
        super.didEnterBackground()
        domReadyMonitor.onExit()
        viewModel.messageEvent?.endParams.append(MailAPMEventConstant.CommonParam.status_user_leave)
        viewModel.messageEvent?.postEnd()
        onCurrentWebViewDisappear()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        MailLogger.error("mail message list did receive memory warning")
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        MailMessageListController.logger.info("viewSafeAreaInsetsDidChange barHeight \(messageNavBar.bounds.height), safeTop \(view.safeAreaInsets.top), Bottom \(view.safeAreaInsets.bottom)")
        var containerViewInsets = view.safeAreaInsets
        containerViewInsets.bottom = 0
        containerViewEdgesConstraint?.update(inset: containerViewInsets)
        DispatchQueue.main.async {
            self.collectionView?.scrollToItem(at: IndexPath(row: self.currentPageIndex, section: 0), at: .left, animated: false)
        }
    }

    override func backItemTapped() {
        backItemTapped(completion: nil)
    }

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        resetToPortrait()
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // 在读信页切换了全局DM/LM时 需要重新计算threadAtions（移除或添加内容区切换入口）
        if self.realViewModel.isBot, accountContext.featureManager.open(.openBotDirectly, openInMailClient: false), self.currentPageCell?.isDomReady != true {
            // skip
        } else {
            setupThreadActions(mailItem: self.mailItem)
        }
        accountContext.messageListPreloader.clear()
    }

    /// 兼容分屏场景下的退出读信
    func backItemTappedOrCloseScene() {
        if SceneManager.shared.supportsMultipleScenes,
           #available(iOS 13.0, *),
           let sceneInfo = self.currentScene()?.sceneInfo,
           !sceneInfo.isMainScene() 
        {
            SceneManager.shared.deactive(from: self)
        } else {
            backItemTapped()
        }
    }

    func backItemTapped(completion: (() -> Void)?) {
        domReadyMonitor.onExit()
        backCallback?()
        if !didMarkAsRead {
            MailAPMErrorDetector.shared.abandonDetect(viewModel.threadId)
        }
        if Display.phone &&
            (isLandscapeInterface || (UIDevice.current.orientation == .portraitUpsideDown && view.frame.width > view.frame.height)) {
            resetToPortrait()
        } else {
            if Display.pad {
                self.accountContext.navigator.showDetail(SplitViewController.makeDefaultDetailVC(),
                                                         wrap: LkNavigationController.self, from: self)
            }
            if let nav = navigationController, nav.viewControllers.count > 1 {
                navigator?.pop(from: self, completion: completion)
            } else {
                MailLogger.info("MailMessageList dismiss")
                self.dismiss(animated: true, completion: completion)
            }
        }
        accountContext.imageService.cancelClientDownload()
        hasBackItemTapped = true
    }

    func resetToPortrait() {
        // 读信目前没有转屏，不处理
    }

    private func businessLog() {
        var source = ""
        switch statInfo.from {
        case .threadList, .search:
            source = MailTracker.source(type: .threadList)
        case .chatSideBar:
            source = MailTracker.source(type: .chatSideBar)
        case .notification:
            source = MailTracker.source(type: .notification)
        case .chat, .imColla:
            source = MailTracker.source(type: .imCard)
        default:
            return
        }
        MailTracker.log(event: Homeric.EMAIL_THREAD_SELECTED, params: [MailTracker.sourceParamKey(): source])
    }

    func showFailPage(threadId: String) {
        let pageCell = getPageCellOf(threadId: threadId)
        pageCell?.showLoadFail(true)
        MailTracker.log(event: "email_page_fail", params: ["scene": "messagelist"])
    }

    private func addObserver() {
        realViewModel.addAttachmentObserver()

        NotificationCenter.default.rx
            .notification(Notification.Name.Mail.MAIL_MESSAGE_DRAFT_REFRESHED)
            .subscribe(onNext: { [weak self] notification in
                self?.mailMessageDraftRefreshed(notification)
            }).disposed(by: disposeBag)
        
        PushDispatcher
            .shared
            .$mailfeedChange
            .wrappedValue
            .observeOn(MainScheduler.instance)
            .subscribe({ [weak self] change in
                if let fromChange = change.element {
                    self?.handleFrom(fromChange.fromResponse)
                }
            }).disposed(by: disposeBag)

        
        PushDispatcher
            .shared
            .$mailfollowStatusChange
            .wrappedValue
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] change in
                self?.handleFollowStatusChange(change.followeeList)
        }).disposed(by: disposeBag)
        
        PushDispatcher
            .shared
            .mailChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                switch push {
                case .threadChange(let change):
                    self?.handleThreadChange((change.threadId, change.labelIds))
                case .labelPropertyChange(_):
                    self?.mailLabelsRefreshed()
                case .multiThreadsChange(let change):
                    self?.handleThreadMultiThreadChange(change.label2Threads, change: change)
                case .recallDoneChange(let change):
                    self?.handleRecallStateUpdate(threadID: nil, messageID: change.messageId, newRecallStatus: change.status)
                case .cacheInvalidChange(let change):
                    self?.cacheInvalidChange(change)
                default:
                    break
                }
        }).disposed(by: disposeBag)

        // TODO: REFACTOR 首页加载更多的列表数据，
        EventBus.threadListEvent.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] event in
                if case let .didReloadListDataOnlyFromMessageList(labelId: labelId, datas: datas) = event {
                    self?.mailThreadListRefreshed(labelId: labelId, datas: datas)
                }
        }).disposed(by: disposeBag)

        EventBusManager
            .shared
            .recallStateUpdate
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (change) in
                self?.handleRecallStateUpdate(threadID: change.threadId, messageID: change.messageId, newRecallStatus: change.status)
            }).disposed(by: disposeBag)
        
        EventBus
            .mailChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                switch push {
                case .recalledChange(let change):
                    self?.handleRecalledChange(change.messageId)
                default:
                    break
                }
            }).disposed(by: disposeBag)
        
        EventBus
            .accountChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (change) in
                guard let self = self else { return }
                // 切账号得销毁分屏产生的各种页面 (feed除外）
                if case .currentAccountChange = change {
                    if !self.isFeedCard {
                        self.closeScene(sender: UIButton())
                    }
                }
            }).disposed(by: disposeBag)

        EventBus.threadListEvent
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (event) in
                switch event {
                case .markRecalledThread(threadId: let id):
                    self?.markRecalledThreadId = id
                default:
                    break
                }
            }).disposed(by: baseDispose)
        NotificationCenter.default.rx.notification(Notification.Name.Mail.MAIL_ADDRESS_NAME_CHANGE)
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] noti in
               guard let `self` = self else { return }
               self.handleAddressChange()
            }).disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(Notification.Name.Mail.MAIL_CACHED_CURRENT_SETTING_CHANGED)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                if let account = Store.settingData.getCachedCurrentAccount() {
                    self.handleSettingChanged(setting: account.mailSetting)
                }
            }).disposed(by: disposeBag)
        if MailMessageListViewsPool.fpsOpt {
            let delayTime = 5
            self.fpsRelay
                .debounce(.seconds(delayTime), scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    guard let `self` = self else { return }
                    HMDFPSMonitor.shared().leaveFluencyCustomScene(withUniq: "Lark.MailSDK.Message.Scroll")
                    self.fpsFlag = false
                }).disposed(by: disposeBag)
            let preRenderDelayTime = 2
            self.preRenderRelay
                .debounce(.seconds(preRenderDelayTime), scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    guard let `self` = self else { return }
                    self.preloadMailMessageView()
                }).disposed(by: disposeBag)
        }
    }

    var collectionView: UICollectionView?

    var fullScreenItem: UIButton?

    lazy var sceneButtonItem: UIBarButtonItem = {
        let button = UIButton()
        button.setImage(Resources.mail_scene_icon, for: .normal)
        button.rx.tap.subscribe(onNext: { [weak self, weak button] in
            guard let button = button else { return }
            self?.clickSceneButton(sender: button)
        }).disposed(by: disposeBag)
        return UIBarButtonItem(customView: button)
    }()
    lazy var closeSceneButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem(image: Resources.mail_scene_close,
                                   style: .plain, target: self,
                                   action: #selector(closeScene(sender:)))
        item.tintColor = UIColor.ud.iconN1
        return item
    }()

    func observeForKeyboard() {
        stopObserveForKeyboard()

        NotificationCenter.default.rx
            .notification(UIResponder.keyboardWillShowNotification)
            .subscribe(onNext: { [weak self] notification in
                self?.keyboardWillShow(notification)
            }).disposed(by: keyboardDisposeBag)

        NotificationCenter.default.rx
            .notification(UIResponder.keyboardWillHideNotification)
            .subscribe(onNext: { [weak self] notification in
                self?.keyboardWillHide(notification)
            }).disposed(by: keyboardDisposeBag)
    }

    func stopObserveForKeyboard() {
        keyboardDisposeBag = .init()
    }

    // MARK: config
    var shouldLoadRemoteData: Bool {
        return statInfo.from == .chatSideBar  ||
            statInfo.from == .notification
    }

    // MARK: - UIView
    /// 设置left & right NaviItems
    private func setupMessageActions(mailItem: MailItem, triggerByTraitChange: Bool = false) {
        MailMessageListController.logStartTime(name: "setupMessageActions")
        let newRightNaviItems = getRightNavActionItems(mailItem: mailItem)
        if MailMessageListViewsPool.fpsOpt {
            setRightButtonItemsIfNeed(newItems: newRightNaviItems)
        } else {
            messageNavBar.setRightItems(newRightNaviItems)
            rightNaviItems = newRightNaviItems
        }
        setupLeftNavActionItems(triggerByTraitChange: triggerByTraitChange)
        updateNavBarItemTintColor()
    }
    
    private func feedSetupMessageLeftActions() {
        setupLeftNavActionItems(triggerByTraitChange: false)
    }

    /// 计算rightNaviItems 并返回
    func getRightNavActionItems(mailItem: MailItem) -> [TitleNaviBarItem] {
        let copyThreadActions = miniTopThreadActions()
        navigationController?.navigationBar.tintColor = UIColor.ud.N650
        if isLandscapeInterface && Display.phone {
            // iPhone横屏，没有threadActions
            return []
        }

        guard !self.realViewModel.isForDeleteSingleMessage() else {
            guard let deleteAction = actionsFactory.getSingleDeletePermanentlyAction() else {
                return []
            }
            var deleteButton = TitleNaviBarItem(image: deleteAction.icon) {
                [weak self] _ in
                guard let naviAction = self?.actionWithConfig(deleteAction) else {
                    return
                }
                naviAction()
            }
            deleteButton.mailActionType = deleteAction.type
            return [deleteButton]
        }


        
        if isFeedCard {
            if accountContext.mailAccount?.isUnuse() == true {
                return []
            } else {
                let moreBtn = TitleNaviBarItem(
                    image: UDIcon.moreOutlined.withRenderingMode(.alwaysTemplate),
                    text: nil,
                    badge: .none,
                    action: {
                        [weak self] (btn) in
                        btn.tintColor = UIColor.ud.iconN1
                        self?.feedMoreAction(address: self?.messageListFeedInfo?.address ?? "", name: self?.messageListFeedInfo?.name ?? "", sender: btn)
                    },
                    longPressAction: nil)
                moreBtn.mailActionType = .more
                return [moreBtn]
            }
        }

        // 邮件分享后，owner外层只显示'群组'和'讨论'icon，其余的收到更多中
        // 被分享人，只显示'群组'和'讨论'icon，无其他更多操作
        // spam和trash中不能有share的action
        let isShareMail = mailItem.code != .none || fromLabel == Mail_LabelId_SHARED
        let isShareOwner = mailItem.code == .owner
        let actions: [MailMessageListActionFactory.ActionsStyleConfig] = actionsFactory.messageListTopActions(
            threadActions: copyThreadActions,
            labelId: viewModel.labelId,
            autoRead: true,
            isShareEmail: isShareMail,
            isShareOwner: isShareOwner,
            isInSharedAccount: currentAccount?.isShared == true,
            isFullReadMessage: isFullReadMessage,
            isFromChat: isForwardCard())
        var newRightNaviItems = [TitleNaviBarItem]()

        for styleConfig in actions {
            var titleNaviItem = TitleNaviBarItem(image: styleConfig.icon) { [weak self] (btn) in
                guard let naviAction = self?.actionWithConfig(styleConfig) else {
                    return
                }
                naviAction()
            }
            titleNaviItem.mailActionType = styleConfig.type
            newRightNaviItems.append(titleNaviItem)
        }
        if fromLabel == Mail_LabelId_Stranger && accountContext.featureManager.open(.stranger, openInMailClient: false) {
            let foldItem = TitleNaviBarItem(image: Resources.mail_action_thread_packup.withRenderingMode(.alwaysTemplate)) { [weak self] (btn) in
                self?.didClickFoldOrUnfoldAciton(sender: btn)
            }
            newRightNaviItems.append(foldItem)
        }
        
        if isForwardCard() && !isFullReadMessage && fromLabel != Mail_LabelId_Stranger {
            // if enter from chat, add fold&unfold action
            // and dont have more actions
            let foldItem = TitleNaviBarItem(image: Resources.mail_action_thread_packup.withRenderingMode(.alwaysTemplate)) { [weak self] (btn) in
                self?.didClickFoldOrUnfoldAciton(sender: btn)
            }
            newRightNaviItems.append(foldItem)
            if accountContext.featureManager.open(FeatureKey(fgKey: .darkMode, openInMailClient: true)), #available(iOS 13.0, *), UDThemeManager.getRealUserInterfaceStyle() == .dark {
                var switchItem = TitleNaviBarItem(image: self.isContentLight
                                                  ? UDIcon.nightOutlined.withRenderingMode(.alwaysTemplate)
                                                  : UDIcon.dayOutlined.withRenderingMode(.alwaysTemplate)) { [weak self] (btn) in
                    self?.switchContentDarkMode()
                    if let isContentLight = self?.isContentLight {
                        let newImage = isContentLight
                        ? UDIcon.nightOutlined.withRenderingMode(.alwaysTemplate)
                        : UDIcon.dayOutlined.withRenderingMode(.alwaysTemplate)
                        btn.setImage(newImage, for: .normal)
                    }
                }
                newRightNaviItems.append(switchItem)
            }
            
        } else if !actionsFactory.messageListMoreActions(
                    threadActions: copyThreadActions,
                    labelId: viewModel.labelId,
                    isFullReadMessage: isFullReadMessage,
                    isFromChat: isForwardCard(),
                    isSwitchToLM: !self.isContentLight).isEmpty,
                  viewModel.labelId != Mail_LabelId_Outbox {
            var moreNaviItem = TitleNaviBarItem(image: Resources.mail_action_more.withRenderingMode(.alwaysTemplate)) { [weak self] (btn) in
                self?.moreActionDidClick(sender: btn) // TODO @kkk
            }
            moreNaviItem.mailActionType = .more
            if !isShareOwner && isShareMail {

            } else {
                newRightNaviItems.append(moreNaviItem)
            }
        }
        
        if self.chatAIFg && !isForwardCard() {
            var needHideAIIcon = false
            if #available(iOS 13.0, *) {
                if self.currentScene()?.sceneInfo.key == "MyAIChatMode" {
                    needHideAIIcon = true
                }
            }
            // 添加ai item按钮
            if let img = accountContext.provider.myAIServiceProvider?.chatModeAIImage,
               !needHideAIIcon {
                let aiItem = TitleNaviBarItem(image: img) { [weak self] (_) in
                    self?.aiBtnClick()
                }
                if newRightNaviItems.last?.mailActionType == .more {
                    newRightNaviItems.insert(aiItem, at: newRightNaviItems.count - 1)
                } else {
                    newRightNaviItems.append(aiItem)
                }
            }
        }
        return newRightNaviItems
    }
    
    func isShowTipsBtn(hidden: Bool) {
        self.tipsBtn.isHidden = hidden
    }
    
    func setTipsBtnNum(count: Int) {
        self.tipsBtn.setTitle(BundleI18n.MailSDK.Mail_KeyContact_ChatPage_NumNewEmail_Text(count), for: .normal)
    }

    // if width < 320, top item should <= 2
    private func miniTopThreadActions() -> [MailIndexedThreadAction] {
        guard self.view.bounds.width < 320 else {
            return threadActions
        }
        var copyThreadActions = threadActions
        var maxTop = 2
        for (index, action) in copyThreadActions.enumerated() {
            if action.isOnTop && maxTop > 0 {
                maxTop = maxTop - 1
            } else if action.isOnTop {
                copyThreadActions[index].isOnTop = false
            }
        }
        return copyThreadActions
    }

    private func setupLeftNavActionItems(triggerByTraitChange: Bool) {
        guard !Display.pad || self.view.window != nil || triggerByTraitChange else {
            return
        }
        // check show full screen button
        var showFullScreenItem = Display.pad && !(larkSplitViewController?.isCollapsed ?? true)
        var addFullScreenItem = false
        var setBackItem = false
        var leftBarButtonItems: [TitleNaviBarItem] = []
        // check show multi scene button
        if SceneManager.shared.supportsMultipleScenes {
            if #available(iOS 13.0, *) {
                if let sceneInfo = self.currentScene()?.sceneInfo,
                   !sceneInfo.isMainScene() {
                    showFullScreenItem = false
                    let closeSceneItem = TitleNaviBarItem(image: UDIcon.closeOutlined.withRenderingMode(.alwaysTemplate)) { [weak self] (btn) in
                        btn.tintColor = UIColor.ud.iconN1
                        self?.closeScene(sender: btn)
                    }
                    leftBarButtonItems.append(closeSceneItem)
                } else {
                    if hasBackPage {
                        setBackItem = true
                        let backBtn = TitleNaviBarItem(image: UDIcon.leftOutlined.withRenderingMode(.alwaysTemplate),
                                                       text: nil,
                                                       badge: .none,
                                                       action: { [weak self] (btn) in
                            btn.tintColor = UIColor.ud.iconN1
                            self?.backItemTapped()
                        },
                                                       longPressAction: nil)
                        
                        leftBarButtonItems.append(backBtn)
                    }
                    if showFullScreenItem {
                        addFullScreenItem = true
                        let img = isFullScreenMode ? LarkSplitViewController.Resources.leaveFullScreen :
                        LarkSplitViewController.Resources.enterFullScreen
                        let fullScreenBarItem = TitleNaviBarItem(image: img) { [weak self] (btn) in
                            btn.tintColor = UIColor.ud.iconN1
                            self?.fullScreenItem = btn
                            self?.fullScreenButtonClicked(sender: btn)
                        }
                        leftBarButtonItems.append(fullScreenBarItem)
                    }
                }
            }
        }
        if showFullScreenItem && !addFullScreenItem {
            leftBarButtonItems = []
            if hasBackPage {
                setBackItem = true
                let backBtn = TitleNaviBarItem(
                    image: UDIcon.leftOutlined.withRenderingMode(.alwaysTemplate),
                    text: nil,
                    badge: .none,
                    action: { [weak self] (btn) in
                        btn.tintColor = UIColor.ud.iconN1
                        self?.backItemTapped()
                    },
                    longPressAction: nil)
                leftBarButtonItems.append(backBtn)
            }
            let img = isFullScreenMode ? LarkSplitViewController.Resources.leaveFullScreen :
            LarkSplitViewController.Resources.enterFullScreen
            let fullScreenBarItem = TitleNaviBarItem(image: img) { [weak self] (btn) in
                btn.tintColor = UIColor.ud.iconN1
                self?.fullScreenItem = btn
                self?.fullScreenButtonClicked(sender: btn)
            }
            leftBarButtonItems.append(fullScreenBarItem)
        }
        if !setBackItem && hasBackPage {
            let backBtn = TitleNaviBarItem(image: UDIcon.leftOutlined.withRenderingMode(.alwaysTemplate),
                                           text: nil,
                                           badge: .none,
                                           action: { [weak self] (btn) in
                self?.backItemTapped()
            },
                                           longPressAction: nil)
            if MailMessageListViewsPool.fpsOpt {
                setLeftButtonItemsIfNeed(newItems: [backBtn])
            } else {
                messageNavBar.setLeftItems([backBtn])
            }
            
        } else if (navigationController == nil || navigationController!.viewControllers.count <= 1) && leftBarButtonItems.isEmpty {
            // 需要展示 dismiss按钮
            //只有在leftBarButtonItems里没有按钮的情况下可能需要dismiss按钮
            let backBtn = TitleNaviBarItem(
                image: UDIcon.closeOutlined.withRenderingMode(.alwaysTemplate),
                text: nil,
                badge: .none,
                action: { [weak self] (btn) in
                    btn.tintColor = UIColor.ud.iconN1
                    self?.backItemTapped()
                },
                longPressAction: nil)
            leftBarButtonItems.append(backBtn)
            if MailMessageListViewsPool.fpsOpt {
                setLeftButtonItemsIfNeed(newItems: leftBarButtonItems)
            } else {
                messageNavBar.setLeftItems(leftBarButtonItems)
            }
        } else {
            var useNewItems = true
            if MailMessageListViewsPool.fpsOpt {
                useNewItems = setLeftButtonItemsIfNeed(newItems: leftBarButtonItems)
            } else {
                messageNavBar.setLeftItems(leftBarButtonItems)
            }
            if #available(iOS 13.0, *), let sceneInfo = self.currentScene()?.sceneInfo,
               !sceneInfo.isMainScene() {
                return
            } else if shouldDisplaySceneButton() {
                let sceneButtonBarItem = SceneButtonItem(
                    clickCallBack: {
                        [weak self] (btn) in
                        btn.tintColor = UIColor.ud.iconN1
                        self?.clickSceneButton(sender: btn)
                    },
                    sceneKey: "Mail",
                    sceneId: viewModel.threadId + statInfo.from.rawValue + viewModel.labelId)
                if useNewItems {
                    messageNavBar.titleNavBar.leftViews.append(sceneButtonBarItem)
                }
            }
        }
    }
    private func setLeftButtonItemsIfNeed(newItems: [TitleNaviBarItem]) -> Bool {
        if !sameItems(newItems: newItems, oldItems: self.leftNaviItems) {
            self.messageNavBar.setLeftItems(newItems)
            self.leftNaviItems = newItems
            return true
        }
        return false
    }
    private func setRightButtonItemsIfNeed(newItems: [TitleNaviBarItem]) {
        if !sameItems(newItems: newItems, oldItems: self.rightNaviItems) {
            self.messageNavBar.setRightItems(newItems)
            self.rightNaviItems = newItems
        }
    }
    func sameItems(newItems: [TitleNaviBarItem], oldItems: [TitleNaviBarItem]) -> Bool {
        guard oldItems.count == newItems.count else { return false}
        for (index, newItem) in newItems.enumerated() {
            if newItem.mailActionType != oldItems[index].mailActionType {
                return false
            }
        }
        return true
    }

    private func actionWithConfig(_ actionConfig: MailMessageListActionFactory.ActionsStyleConfig) -> (() -> Void) {
        return { [weak self] in
            switch actionConfig.type {
            case .archive:
                self?.archiveMail()
            case .trash:
                self?.trashMail()
            case .unRead:
                self?.unreadMail()
            case .read:
                self?.readMail()
            case .spam:
                self?.spamMail()
            case .notSpam:
                self?.notSpamMail()
            case .delete:
                self?.deleteOutboxMail()
            case .edit:
                self?.editOutboxMail()
            case .deletePermanently:
                self?.deletePermanently()
            case .moveToInbox:
                self?.moveToInbox()
            case .changeLabels:
                self?.changeLablsThreadAction()
            case .moveToImportant:
                self?.moveToImportant()
            case .moveToOther:
                self?.moveToOther()
            case .moveTo:
                self?.moveToLabel()
            case .flag, .unFlag:
                self?.handleFlag()
            case .cancelScheduleSend:
                self?.cancelScheduleSend()
            case .cancelAllScheduleSend:
                self?.cancelAllScheduleSend()
            case .contentDarkMode:
                self?.switchContentDarkMode()
            case .contentSearch:
                self?.startContentSearch()
            case .emlAsAttachment:
                self?.emlAsAttachment()
            case .blockSender:
                self?.handleBlockSenderClick()
            case .unknown, .deleteDraft, .discardDraft, .scheduleSend, .priority, .readReceipt,
                    .sendSeparaly, .saveDraft, .more, .allowStranger, .rejectStranger:
                mailAssertionFailure("ThreadAction doesnt have selector")
            }
        }
    }

    /// 给子类重载用的.
    func shouldDisplaySceneButton() -> Bool {
        true
    }

    // MARK: - data
    internal func setupViewsWithItem(mailItem: MailItem) {
        MailLogger.debug("message list setupViewsWithItem count:\(mailItem.messageItems.count) threadId: \(self.viewModel.threadId)")
        _ = checkNeedDismissSelf(newMailItem: mailItem)
        setupThreadActions(mailItem: mailItem)
        MailLogger.debug("message list setupViewsWithItem end threadId: \(self.viewModel.threadId)")
    }

    internal func setupThreadActions(mailItem: MailItem) {
        calculateThenStoreThreadActions(mailItem: mailItem)
        setupMessageActions(mailItem: mailItem)
    }

    private func calculateThenStoreThreadActions(mailItem: MailItem) {
        var labelIDs = mailItem.labels.map { (label) -> String in
            label.id
        }
        let senders = mailItem.messageItems.map { (item) -> String in
            item.message.from.address
        }
        if statInfo.from == .imColla {
            labelIDs = [Mail_LabelId_SHARED]
        }
        threadActions = MailThreadActionCalculator.calculateMessageListThreadActions(
            fromLabel: getCurrentLabelIfNeeded(labelIDs: labelIDs),
            labelIDs: labelIDs,
            senders: senders,
            isRead: mailItem.isRead,
            myAddress: accountContext.user.myMailAddress)
        // 定时发送中，当选中的邮件只有一封时，取消定时发送按钮的文案不同
        var scheduleSendCount = 0
        mailItem.messageItems.forEach { (messageItem) in
            if messageItem.message.scheduleSendTimestamp > 0 {
                scheduleSendCount = scheduleSendCount + 1
            }
        }
        if scheduleSendCount <= 1 {
            threadActions.removeAll(where: { $0.action == .cancelAllScheduleSend })
        } else {
            threadActions.removeAll(where: { $0.action == .cancelScheduleSend })
        }
    }

    private func getCurrentLabelIfNeeded(labelIDs: [String]) -> String {
        if !needRelocateCurrentLabel {
            return viewModel.labelId
        }
        // 聊天会走到这里, 需要重新定位当前 message-list 在哪个 label 下.
        if let searchFolderTag = searchFolderTag, viewModel.labelId == Mail_LabelId_SEARCH_TRASH_AND_SPAM {
            return MailThreadActionCalculator.calculateRecommendedLabel(labelIDs: [searchFolderTag], fromLabel: viewModel.labelId)
        }
        return MailThreadActionCalculator.calculateRecommendedLabel(labelIDs: labelIDs, fromLabel: viewModel.labelId)
    }

    /// if is unread mail, mark as read
    internal func markAsRead(vm: MailMessageListPageViewModel, abandonThreadIDs: [String] = []) {
        guard vm.mailItem?.isRead == false && statInfo.from != .chat else {
            // 保证有mailItem才进行，避免页面渲染时再拉取的mailItem已被标为已读
            return
        }
        guard self.navigationController?.viewControllers.last == self else { return }
        if vm.threadId == self.viewModel.threadId {
            self.viewModel.mailItem?.isRead = true
        }
        MailLogger.info("mail message list mark as read \(vm.threadId)")
        for abandonThreadID in abandonThreadIDs {
            MailAPMErrorDetector.shared.abandonDetect(abandonThreadID)
        }
        MailAPMErrorDetector.shared.startDetect(vm.threadId)
        didMarkAsRead = true
        // 已读未读状态更改
        threadActionDataManager.unreadMail(threadID: vm.threadId,
                                           fromLabel: vm.labelId,
                                           isRead: true,
                                           msgIds: self.allMessageIds,
                                           sourceType: logThreadActionSource)
    }

    private func getOldestMessage(messageItems: [MailMessageItem]) -> MailClientMessage? {
        return messageItems.sorted(by: { $0.message.createdTimestamp < $1.message.createdTimestamp }).first?.message
    }

    func loadFeedMailItem(feedCardId: String, 
                          timestampOperator: Bool,
                          timestamp: Int64,
                          forceGetFromNet: Bool,
                          isDraft: Bool,
                          success:((MailItem, Bool) -> Void)?, errorCallBack:(() -> Void)?){
        realViewModel.loadFeedMailItem(feedCardId: feedCardId,
                                       timestampOperator: timestampOperator,
                                       timestamp: timestamp,
                                       forceGetFromNet: forceGetFromNet,
                                       isDraft: isDraft) { (mailItem, hasMore) in
            asyncRunInMainThread {
                success?(mailItem, hasMore)
            }
        } errorCallback: { [weak self] _ in
            asyncRunInMainThread {
                // 停止动画
                errorCallBack?()
            }
        }

    }
    
    func loadMailItem(threadId: String, labelId: String, messageId: String?, success: ((MailItem) -> Void)?) {
        realViewModel.loadMailItem(threadId: threadId,
                                   labelId: labelId,
                                   messageId: messageId,
                                   loadRemote: false,
                                   forwardInfo: realViewModel.forwardInfo) { mailItem, _ in
            asyncRunInMainThread {
                success?(mailItem)
            }
        } errorCallback: { error in
            MailLogger.error("message list loadMailItem error tid: \(threadId), msgid \(messageId ?? ""), labelid: \(labelId)")
            asyncRunInMainThread { [weak self] in
                guard let self = self else { return }
                if Reachability()?.isReachable ?? false {
                    if self.markRecalledThreadId != self.viewModel.threadId {
                        self.dismissSelf()
                    }
                } else {
                    self.showFailPage(threadId: threadId)
                }
            }
        }
    }

    func threadRefresh(threadId: String, change: MailMultiThreadsChange? = nil, success: ((MailItem) -> Void)? = nil) {
        loadMailItem(threadId: threadId, labelId: viewModel.labelId, messageId: nil) { [weak self] (mailItem) in
            guard let `self` = self,
                  !self.checkNeedDismissSelf(newMailItem: mailItem) else {
                return
            }
            self.refreshMessageList(with: mailItem, change: change)
            success?(mailItem)
        }
    }

    func refreshDelegationIfNeeded(with newMailItem: MailItem, change: MailMultiThreadsChange?) {
        MailLogger.info("[Mail_Migration_Delegation] start refreshing delegation with mailItem threadId\(newMailItem.threadId)")
        guard let change = change else { 
            MailLogger.info("[Mail_Migration_Delegation] return refreshing delegation with no change info mailItem threadId\(newMailItem.threadId)")
            return
        }
        let updateDelegation = change.updateDelegation
        guard updateDelegation else {
            MailLogger.info("[Mail_Migration_Delegation] return refreshing delegation with no updateDelegation threadId\(newMailItem.threadId)")
            return
        }
        let renderModel = self.getRenderModel(by: self.viewModel, mailItem: newMailItem, lazyLoadMessage: false)
        for item in newMailItem.messageItems {
            guard renderModel.shouldShowDelegationInfo(for: item, accountContext: self.accountContext) else { continue }
            let addressListHTML = self.realViewModel.templateRender.replaceForDelegation(address: item.message.senderDelegation)
            let insertAddressHTML = addressListHTML.cleanEscapeCharacter()
            var delegationInfo = item.message.senderDelegation.displayName
            if delegationInfo.isEmpty {
                delegationInfo = item.message.senderDelegation.name
            }
            let insertType = BundleI18n.MailSDK.Mail_Normal_From.htmlEncoded
            MailLogger.info("[Mail_Migration_Delegation] finish refreshing delegation with messageId\(item.message.id)")
            callJavaScript("window.updateSenderDelegation('\(item.message.id)','\(delegationInfo)','\(insertType)','\(insertAddressHTML)')")
        }
    }

    func mailThreadFlagRefresh(with newMailItem: MailItem, fromLabel: String, hideFlag: Bool) {
        let jsstring = "window.updateFlagged('\(newMailItem.isFlagged)','\(hideFlagButton())')"
        callJavaScript(jsstring)
        currentPageCell?.mailMessageListView?
            .updateTitleLabels(newMailItem.labels ?? [],
                               fromLabel: fromLabel,
                               flagged: newMailItem.isFlagged,
                               isExternal: newMailItem.isExternal,
                               hideFlag: hideFlag)
    }

    func mailThreadCoverIfNeeded(with newMailItem: MailItem) {
        if let titleView = currentPageCell?.mailMessageListView?.titleView {
            var cover: MailReadTitleViewConfig.CoverImageInfo? = nil
            if let info = newMailItem.mailSubjectCover() {
                cover = MailReadTitleViewConfig.CoverImageInfo(subjectCover: info)
            }
            let fromLabelID = MsgListLabelHelper.resetFromLabelIfNeeded(viewModel.labelId, msgLabels: realViewModel.messageLabels)
            let config = MailReadTitleViewConfig(title: newMailItem.displaySubject,
                                                 fromLabel: fromLabelID,
                                                 labels: newMailItem.labels,
                                                 isExternal: newMailItem.isExternal,
                                                 translatedInfo: titleView.translatedInfo,
                                                 coverImageInfo: cover,
                                                 spamMailTip: newMailItem.spamMailTip,
                                                 needBanner: viewModel.needBanner,
                                                 keyword: keyword, subjects: subjects)

            titleView.updateUI(config: config)
        }
    }

    func mailSendStatusRefresh(with newMailItem: MailItem) {
        for item in newMailItem.messageItems where item.message.sendState != .unknownSendState {
            let mailRecallState = MailRecallManager.shared.recallState(for: item)
            let displayRecallBanner = realViewModel.templateRender.shouldReplaceRecallBanner(for: item, myUserId: myUserId ?? "0") && mailRecallState != .none
            if let setting = Store.settingData.getCachedCurrentSetting(),
               setting.userType == .larkServer &&
                accountContext.featureManager.open(.sendStatus) {
                let html = self.realViewModel.templateRender.replaceForSendStatusBanner(item, needShow: !displayRecallBanner).cleanEscapeCharacter()
                callJavaScript("window.updateSendState('\(item.message.id)','\(html)')")
            }
        }
    }

    func mailHideScheduleSendStatusIfNeeded(with newMailItem: MailItem) {
        for item in newMailItem.messageItems where item.message.scheduleSendTimestamp < Int64(Date().timeIntervalSince1970) {
            callJavaScript("window.hideScheduleSendBanner('\(item.message.id)')")
        }
    }

    func mailReplyTagTypeRefresh(with newMailItem: MailItem) {
        guard FeatureManager.open(.repliedMark, openInMailClient: true) else { return }
        for item in newMailItem.messageItems {
            switch item.message.displayReplyType {
            case .reply:
                callJavaScript("window.updateReplyTagType('\(item.message.id)','reply')")
            case .forward:
                callJavaScript("window.updateReplyTagType('\(item.message.id)','forward')")
            @unknown default:
                callJavaScript("window.updateReplyTagType('\(item.message.id)','')")
            }
        }
    }

    func mailReadReceiptBannerRefresh(with newMailItem: MailItem) {
        guard accountContext.featureManager.open(.readReceipt, openInMailClient: true) else { return }
        for item in newMailItem.messageItems where !item.message.systemLabels.contains(Mail_LabelId_ReadReceiptRequest) {
            hideReadReceiptBanner(threadID: newMailItem.threadId, messageID: item.message.id)
        }
    }

    func mailHideSendStatus(mail: MailMessageItem) {
        if mail.message.sendState != .unknownSendState {
            callJavaScript("window.hideSendStatus('\(mail.message.id)')")
        }
    }
    
    func reloadFeedLabel(with newMailItem: MailItem, messageId: String, hideFlag: Bool) {
        asyncRunInMainThread { [weak self] in
            guard let self = self else { return }
                let feedLabels = newMailItem.feedMessageItems.first(where: {$0.item.message.id == messageId})?.labelIds ?? []
                let feedLabelIds = MailTagDataManager.shared.getTagModels(feedLabels)
                let feedatLabelId = newMailItem.feedMessageItems.first(where: {$0.item.message.id == messageId})?.labelIds.first ?? ""
                let labels = MailMessageListLabelsFilter.filterLabels(feedLabelIds,
                                                                      atLabelId: feedatLabelId,
                                                                      permission: newMailItem.code,
                                                                      useCssColor: MailMessageListTemplateRender.enableNativeRender)
                if labels.count > 0 {
                    /// 刷新界面
                    var allLabels = ""
                    for label in labels {
                        /// 邮件协作fg关闭时，不显示 share label
                        if label.id == Mail_LabelId_SHARED {
                            continue
                        }
                        if label.id == Mail_LabelId_UNREAD || label.id == Mail_LabelId_Unknow {
                            continue
                        }
                        allLabels += self.realViewModel.templateRender.createMessageLabelItem(label.displayLongName,
                                                                                              dirLTR: label.parentID.isEmpty ? true: false,
                                                                                              fontColor: label.displayFontColor,
                                                                                              bgColor: label.displayBgColor,
                                                                                              isGoogle: label.labelModelMailClientType == .googleMail)
                    }
                    allLabels = allLabels.replacingOccurrences(of: "\n", with: "")
                    let jsstring = "window.updateFeedLabels('\(allLabels)','\(messageId)')"
                    self.callJavaScript(jsstring) { (_, error) in
                        if let error = error {
                            MailMessageListController.logger.error("message list updateFeedLabels error:\(error)")
                        }
                        MailMessageListController.logger.info("message list updateFeedLabels succs Labels:\(allLabels), messageId:\(messageId)")
                    }
                } else {
                    let jsstring = "window.updateFeedLabels('','\(messageId)')"
                    self.callJavaScript(jsstring) { (_, error) in
                        if let error = error {
                            MailMessageListController.logger.error("message list updateLabels error:\(error)")
                        }
                        MailMessageListController.logger.info("message list updateFeedLabels succs")
                    }
                }
                // native render
                self.currentPageCell?.mailMessageListView?.updateTitleLabels(feedLabelIds,
                                                                             fromLabel: feedatLabelId,
                                                                             flagged: newMailItem.isFlagged,
                                                                             isExternal: newMailItem.isExternal,
                                                                             hideFlag: hideFlag)
                
            }
    }
    

    func reloadLabel(with newMailItem: MailItem, fromLabel: String, hideFlag: Bool) {
        asyncRunInMainThread { [weak self] in
            guard let self = self else { return }
            let labels = MailMessageListLabelsFilter.filterLabels(newMailItem.labels,
                                                                  atLabelId: fromLabel,
                                                                  permission: newMailItem.code,
                                                                  useCssColor: !MailMessageListTemplateRender.enableNativeRender)
            if labels.count > 0 {
                /// 刷新界面
                var allLabels = ""
                for label in labels {
                    /// 邮件协作fg关闭时，不显示 share label
                    if label.id == Mail_LabelId_SHARED {
                        continue
                    }
                    if label.id == Mail_LabelId_UNREAD || label.id == Mail_LabelId_Unknow {
                        continue
                    }
                    allLabels += self.realViewModel.templateRender.createMessageLabelItem(label.displayLongName,
                                                                                          dirLTR: label.parentID.isEmpty ? true: false,
                                                                                          fontColor: label.displayFontColor,
                                                                                          bgColor: label.displayBgColor,
                                                                                          isGoogle: label.labelModelMailClientType == .googleMail)
                }
                allLabels = allLabels.replacingOccurrences(of: "\n", with: "")
                let jsstring = "window.updateLabels('\(allLabels)')"
                self.callJavaScript(jsstring) { (respon, error) in
                    if let error = error {
                        MailMessageListController.logger.error("message list updateLabels error:\(error)")
                    }
                }
            } else {
                let jsstring = "window.updateLabels('')"
                self.callJavaScript(jsstring) { (respon, error) in
                    if let error = error {
                        MailMessageListController.logger.error("message list updateLabels error:\(error)")
                    }
                }
            }
            // native render
            self.currentPageCell?.mailMessageListView?.updateTitleLabels(newMailItem.labels,
                                                                         fromLabel: fromLabel,
                                                                         flagged: newMailItem.isFlagged,
                                                                         isExternal: newMailItem.isExternal,
                                                                         hideFlag: hideFlag)
        }
    }

    /// 刷新界面
    func refreshMessageList(with newMailItem: MailItem, change: MailMultiThreadsChange? = nil) {
        asyncRunInMainThread { [weak self] in
            guard let self = self else { return }
            /// need refresh current thread
            guard newMailItem.threadId == self.viewModel.threadId else {
                self.resetMailItemForReload(threadIDs: [newMailItem.threadId])
                return
            }

            MailMessageListController.logger.info("message list refresh message list")
            /// refresh label
            self.threadLabels = newMailItem.labels.map({ MailFilterLabelCellModel(pbModel: $0) })
            if self.feedCardId.isEmpty {
                self.reloadLabel(with: newMailItem, fromLabel: self.fromLabel, hideFlag: self.hideFlagButton())
            }

            /// refresh actions
            self.calculateThenStoreThreadActions(mailItem: newMailItem)
            self.setupMessageActions(mailItem: newMailItem)

            /// refresh flag
            self.mailThreadFlagRefresh(with: newMailItem,
                                       fromLabel: self.fromLabel, hideFlag: self.hideFlagButton())

            /// refresh sendStatus
            self.mailSendStatusRefresh(with: newMailItem)

            /// refresh scheduleSendStatus
            self.mailHideScheduleSendStatusIfNeeded(with: newMailItem)

            /// refresh replyTagType
            self.mailReplyTagTypeRefresh(with: newMailItem)

            /// refresh readReceiptBanner
            self.mailReadReceiptBannerRefresh(with: newMailItem)

            /// refresh messages
            self.updateMessageItems(with: newMailItem)

            /// refresh coverIfNeeded
            self.mailThreadCoverIfNeeded(with: newMailItem)

            /// refresh draft
            self.updateDrafts(with: newMailItem, oldMailItem: self.mailItem)
            self.realViewModel.onMailItemUpdate(newMailItem: newMailItem, oldMailItem: self.mailItem)

            /// refresh delegation
            self.refreshDelegationIfNeeded(with: newMailItem, change: change)
            /// update self mailItem in the end
            self.mailItem = newMailItem
            if let index = self.getIndexOf(threadId: newMailItem.threadId),
               let pageCell = self.collectionView?.cellForItem(at: IndexPath(row: index, section: 0)) as? MailMessageListPageCell {
                if !self.isFeedCard {
                    pageCell.updateBottomActionItems(self.bottomActionItemsFor(index))
                }
            }
        }
    }

    func checkNeedDismissSelf(newMailItem: MailItem) -> Bool {
           /// the messageItems is empty
           /// or don't contains self labelId
           /// need to dismiss this page
           let labelId = viewModel.labelId
           if newMailItem.messageItems.isEmpty ||
               (!systemLabels.contains(labelId) && !newMailItem.labels.contains(where: { $0.id == labelId })) {

               if realViewModel.isForDeleteSingleMessage() {
                   MailLogger.info("[mail_applink_delete] label issue is causing dismiss msgID: \(viewModel.messageId) label: \(labelId)")
                   if newMailItem.messageItems.isEmpty {
                       MailLogger.info("[mail_applink_delete] label issue MailItem MessageItem empty!")
                   }
                   if !newMailItem.labels.contains(where: { $0.id == labelId }) {
                       MailLogger.info("[mail_applink_delete] label issue Invalid LabelId\(labelId)!")
                   }
               }

               if let recallingThreadId = markRecalledThreadId, recallingThreadId == viewModel.threadId {
                   // handling recall, will pop after recall is handled
                   return false
               } else {
                   self.dismissSelf()
                   return true
               }
           }
           return false
       }

    func dismissSelf(animated: Bool = true, completion: (() -> Void)? = nil, dismissMsgListSecretly: Bool = false) {
        asyncRunInMainThread { [weak self] in
            guard let self = self else { return }
            /// 将读信页pop走，兼容eml, readmore场景
            guard let navgationVCs = self.navigationController?.viewControllers else {
                /// present case, ipad scene
                return
            }
            // 同时关闭 VC 上 present 出来的弹窗
            if let presentedVC = self.presentedViewController as? MoreActionViewController {
                presentedVC.dismiss(animated: false, completion: nil)
            }
            if dismissMsgListSecretly {
                self.navigationController?.setViewControllers(navgationVCs.filter({ ($0 as? MailMessageListController) == nil }), animated: false)
                MailLogger.info("[mail_stranger] msgList navigationVC count after dismiss: \(self.navigationController?.viewControllers.count ?? 0)")
                completion?()
            } else {
                for navgationVC in navgationVCs.reversed() where (navgationVC as? MailMessageListController) != nil {
                    if let completion = completion {
                        self.navigationController?.popViewController(animated: animated, completion: completion)
                    } else {
                        self.navigationController?.popViewController(animated: animated)
                    }
                }
                self.closeScene(sender: UIButton())
            }
        }
    }

    func mailLabelsRefreshed() {
        MailLogger.info("mail message list labels refreshed")
        let threadId = viewModel.threadId
        let labelId = viewModel.labelId
        let delayTime: Double = 0.25
        DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) {
            /// 获取真正的数据，并更新页面数据
            if self.feedCardId.isEmpty {
                self.loadMailItem(threadId: threadId, labelId: labelId, messageId: nil) { [weak self] (mailItem) in
                    guard let self = self else { return }
                    if self.mailItem.threadId == mailItem.threadId {
                        self.mailItem = mailItem
                        // refreshLabels
                        _ = self.checkNeedDismissSelf(newMailItem: mailItem)
                        self.threadLabels = mailItem.labels.map({ MailFilterLabelCellModel(pbModel: $0) })
                        self.reloadLabel(with: mailItem, fromLabel: self.fromLabel, hideFlag: self.hideFlagButton())
                    }
                }
            }
        }
    }

    func mailMessageDraftRefreshed(_ notification: Notification) {
        asyncRunInMainThread { [weak self] in
            if let draft = notification.object as? MailDraft {
                self?.mailMessageDraftUpdate(draft)
            }
        }
    }

    func cacheInvalidChange(_ change: MailCacheInvalidChange) {
        guard fromLabel == Mail_LabelId_Stranger && accountContext.featureManager.open(.stranger, openInMailClient: false) else { return }
        dismissSelf()
    }

    func handleThreadChange(_ change: (threadId: String, labelIds: [String])) {
        MailLogger.info("mail message thread info refreshed [handleThreadChange] for threadId \(change.threadId)")
        if self.isFeedCard {
            // 需要refresh的threadId
            let needChangeMessageIds = self.mailItem.feedMessageItems.map { $0.item.message.id }
            MailLogger.info("mail message thread message sendState feedMessageItems.count(threadChange): \(self.mailItem.feedMessageItems.count)")
            MailLogger.info("mail message thread message sendState messageIds: \(needChangeMessageIds)")
            self.handleFeedMessageItemStatus(messageIDs: needChangeMessageIds)
            if change.labelIds.contains(Mail_LabelId_Outbox) {
                self.handleOutboxStateChange()
            }
            self.updateMessagesDraftSummary(messageIds: needChangeMessageIds)
        } else if change.threadId == viewModel.threadId {
            MailLogger.info("mail message thread info refreshed [handleThreadChange] for current \(viewModel.threadId)")
            threadRefresh(threadId: change.threadId)
        } else {
            resetMailItemForReload(threadIDs: [change.threadId])
        }
    }

    func handleThreadMultiThreadChange(_ label2Threads: Dictionary<String, (threadIds: [String], needReload: Bool)>,
                                       change: MailMultiThreadsChange?) {
        MailLogger.info("mail message handleThreadMultiThreadChange \(viewModel.threadId) fromLabel \(viewModel.labelId)")
        let currentLabelChange = label2Threads[viewModel.labelId]
        
        /// when received current label multi threads change, refresh message list
        let isCurrentLabelChange = currentLabelChange?.threadIds.contains(viewModel.threadId) == true || currentLabelChange?.needReload == true
        
        /// In search, when threadIds contain current threadId, refresh message list
        let isSearchCurrentThreadChange = statInfo.from == .search && label2Threads.values.contains(where: { $0.threadIds.contains(viewModel.threadId) })
        
        MailLogger.info("mail message handleThreadMultiThreadChange parent \(parent != nil),curLabel \(isCurrentLabelChange),searchCurThread \(isSearchCurrentThreadChange)")
        if self.isFeedCard {
            // 当前threadIds
            let threadIDs = self.mailItem.feedMessageItems.map({$0.threadID})
            // 所有推送变更的threadIds
            let mergedThreadIds = Array(Set(label2Threads.values.flatMap { $0.threadIds }))
            // 需要refresh内容
            MailLogger.info("message sendState feedMessageItems.count(threadChange): \(self.mailItem.feedMessageItems.count)")

            let intersection = Array(Set(threadIDs).intersection(Set(mergedThreadIds)))
//            let needChangeMessageIds = self.mailItem.feedMessageItems
//                .filter { intersection.contains($0.threadID) }
//                .map { $0.item.message.id }
            let needChangeMessageIds = self.mailItem.feedMessageItems.map { $0.item.message.id }
            MailLogger.info("message sendState messageIds: \(needChangeMessageIds)")
            self.handleFeedMessageItemStatus(messageIDs: needChangeMessageIds)
        } else if parent != nil && (isCurrentLabelChange || isSearchCurrentThreadChange) {
            threadRefresh(threadId: viewModel.threadId, change: change)
        } else {
            if let reloadThreadIds = currentLabelChange?.threadIds.filter({ $0 != viewModel.threadId }) {
                resetMailItemForReload(threadIDs: reloadThreadIds)
            }
        }
    }

    func resetMailItemForReload(threadIDs: [String]) {
        /// if other page mail item changed, set the mail item in view model to nil,
        /// waiting for the reload when other page show again
        for threadID in threadIDs {
            let viewModel = self.realViewModel[threadId: threadID]
            viewModel?.mailItem = nil
            viewModel?.bodyHtml = nil
            if let reloadRow = self.dataSource.firstIndex(where: { $0.threadId == threadID }) {
                self.collectionView?.reloadItems(at: [IndexPath(row: reloadRow, section: 0)])
            }
            MailMessageListController.logger.info("message list refresh other page mail item threadId \(threadID)")
        }
    }

    /// 由 checkNeedShowMore 触发，滑动时获取新的邮件数据
    func mailThreadListRefreshed(labelId: String, datas: [MailThreadListCellViewModel]) {
        MailMessageListController.logger.info("mail message list threads refreshed")
        if statInfo.from == .threadList && !rootSizeClassIsRegular {
            if labelId == viewModel.labelId {
                let threadsList = datas
                let newDataSource = MailMessageListPageViewModel.getListFromThreadList(threadsList, accountContext: accountContext, labelId: labelId)
                if newDataSource.map({ $0.threadId }) != dataSource.map({ $0.threadId }) {
                    // dataSource 改变，需要更新
                    // 已生成 bodyHtml 的，需要赋给新VM，避免需要重新组装 bodyHtml
                    newDataSource.forEach { (newVM) in
                        guard let oldVM = realViewModel[threadId: newVM.threadId] else { return }
                        newVM.bodyHtml = oldVM.bodyHtml
                        newVM.mailItem = oldVM.mailItem
                        newVM.keyword = self.keyword
                        newVM.delegate = self
                    }
                    self.realViewModel.updateDataSource(newDataSource)
                    if recalledChangeAlert == nil {
                        self.collectionView?.reloadData()
                    } else {
                        // when showing alert, reloadData after user confirm
                        // to avoid the UI change when alert showing
                        reloadDataOnRecallConfirm = true
                    }
                } else {
                    MailMessageListController.logger.info("mailThreadListRefreshed no diff")
                }
            }
        }
    }

    func handleRecallStateUpdate(threadID: String?, messageID: String?, newRecallStatus: RecallStatus?) {
        let messageID = messageID ?? ""
        MailMessageListController.logger.info("MailRecall: handleRecallStateUpdate '\(messageID)', to: '\(newRecallStatus)')")
        let vm = realViewModel.getViewModelContainsMessage(id: messageID)
        guard let finalThreadID = threadID ?? vm?.threadId else {
            MailMessageListController.logger.error("MailRecall: handleRecallStateUpdate threadID not found")
            return
        }

        var needRefreshThread = true
        if let newRecallStatus = newRecallStatus {
            // has newRecallStatus, update directly
            if let vm = vm {
                let isThreadIdAllowEmpty = self.isFeedCard ? true : (!vm.threadId.isEmpty)
                if isThreadIdAllowEmpty, var mailItem = vm.mailItem, let idx = mailItem.messageItems.firstIndex(where: { $0.message.id == messageID }) {
                    var messageItem = mailItem.messageItems[idx]
                    messageItem.message.recallStatus = newRecallStatus
                    mailItem.messageItems[idx] = messageItem
                    vm.mailItem = mailItem
                    needRefreshThread = false
                }
            }
        }

        asyncRunInMainThread { [weak self] in
            guard let self = self else { return }
            if needRefreshThread {
                MailMessageListController.logger.info("MailRecall: handleRecallStateUpdate: \(messageID), refresh thread")
                if self.feedCardId.isEmpty {
                    self.threadRefresh(threadId: finalThreadID) { [weak self] _  in
                        self?.updateRecallStateFor(messageId: messageID, in: finalThreadID)
                    }
                } else {
                    self.updateRecallStateFor(messageId: messageID, in: finalThreadID)
                }
            } else {
                MailMessageListController.logger.info("MailRecall: handleRecallStateUpdate: \(messageID), direct update state")
                self.updateRecallStateFor(messageId: messageID, in: finalThreadID)
            }

        }
    }

    func updateCurrentMailTitleView(translatedInfo: MailReadTitleViewConfig.TranslatedTitleInfo?) {
        updateMailTitleView(threadID: viewModel.threadId, translatedInfo: translatedInfo)
    }

    func updateMailTitleView(threadID: String, translatedInfo: MailReadTitleViewConfig.TranslatedTitleInfo?) {
        guard let messageListView = getPageCellOf(threadId: threadID)?.mailMessageListView,
              let viewModel = dataSource.first(where: { $0.threadId == threadID })
        else {
            return
        }
        let fromLabelID = MsgListLabelHelper.resetFromLabelIfNeeded(viewModel.labelId, msgLabels: realViewModel.messageLabels)
        messageListView.updateTitle(viewModel.displaySubject,
                                    translatedInfo: translatedInfo,
                                    labels: viewModel.labels ?? [],
                                    fromLabel: fromLabelID,
                                    flagged: viewModel.mailItem?.isFlagged == true,
                                    isExternal: viewModel.mailItem?.isExternal == true,
                                    subjectCover: viewModel.mailSubjectCover(),
                                    spamMailTip: viewModel.spamMailTip,
                                    needBanner: viewModel.needBanner,
                                    keyword: keyword)
    }

    func handleRecalledChange(_ messageId: String) {
        let isRecallingCurrentThread = viewModel.mailItem?.messageItems.contains(where: { $0.message.id == messageId }) == true
        if isRecallingCurrentThread {
            EventBus.$threadListEvent.accept(.markRecalledThread(threadId: viewModel.threadId))
        }
        MailMessageListController.logger.debug("Recall: receive recall notification")
        let messageItemsCount = viewModel.mailItem?.messageItems.count
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            if isRecallingCurrentThread {
                // if current thread has this messageId, toast then remove after confirm
                if self.alertingRecallMsgIds != nil {
                    self.alertingRecallMsgIds?.append(messageId)
                } else {
                    self.alertingRecallMsgIds = [messageId]
                }

                if let alert = self.recalledChangeAlert {
                    let count = self.alertingRecallMsgIds?.count ?? 0
                    if count > 0 {
                        alert.setTitle(text: BundleI18n.MailSDK.Mail_Recall_DilaogMultiRecalled(count))
                    }
                } else {
                    let alert = LarkAlertController()
                    alert.setTitle(text: BundleI18n.MailSDK.Mail_Recall_DilaogHasBeenRecalled)
                    alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_Alert_OK, dismissCompletion: { [weak self] in
                        guard let `self` = self else { return }
                        if let alertingRecallMsgIds = self.alertingRecallMsgIds {
                            if messageItemsCount == alertingRecallMsgIds.count {
                                self.dismissSelf()
                            } else {
                                for msgId in alertingRecallMsgIds {
                                    self.deleteMessageItem(id: msgId)
                                }
                            }
                        }
                        if self.reloadDataOnRecallConfirm == true {
                            self.collectionView?.reloadData()
                        }
                        self.reloadDataOnRecallConfirm = false
                        self.alertingRecallMsgIds = nil
                        EventBus.$threadListEvent.accept(.markRecalledThread(threadId: nil))
                    })
                    self.recalledChangeAlert = alert
                    self.navigator?.present(alert, from: self)
                    InteractiveErrorRecorder.recordError(event: .has_been_recall,
                                                         tipsType: .alert,
                                                         userCause: false,
                                                         scene: .messagelist)
                }
            } else {
                // if not, try delete directly
                self.deleteMessageItem(id: messageId)
            }
        }
    }

    /// need show flag button
    func hideFlagButton() -> Bool {
        let labelId = viewModel.labelId
        if labelId == Mail_LabelId_Trash
            || labelId == Mail_LabelId_Spam
            || labelId == Mail_LabelId_SHARED
            || labelId == Mail_LabelId_Outbox
            || mailItem.code == .view
            || mailItem.code == .edit {
            return true
        }
        return false
    }

    func isForwardCard() -> Bool {
        return realViewModel.forwardInfo != nil
    }

    // MARK: - WKNavigationDelegate
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        _webViewWebContentProcessDidTerminate(webView)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        _webView(webView, didStartProvisionalNavigation: navigation)
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        _webView(webView, didFinish: navigation)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        _webView(webView, decidePolicyFor: navigationAction, decisionHandler: decisionHandler)
    }

    // MARK: - WKUIDelegate
    func webView(_ webView: WKWebView, shouldPreviewElement elementInfo: WKPreviewElementInfo) -> Bool {
        _webView(webView, shouldPreviewElement: elementInfo)
    }

    func webView(_ webView: WKWebView, previewingViewControllerForElement elementInfo: WKPreviewElementInfo, defaultActions previewActions: [WKPreviewActionItem]) -> UIViewController? {
        _webView(webView, previewingViewControllerForElement: elementInfo, defaultActions: previewActions)
    }
    @available(iOS 13.0, *)
    func webView(_ webView: WKWebView, contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo, completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {
        _webView(webView, contextMenuConfigurationForElement: elementInfo, completionHandler: completionHandler)
    }

    func shareMail() {
        Store.settingData.storageLimitCheck(from: self, navigator: accountContext.navigator) { [weak self] in
            self?.presentShareInviteVC()
        }
    }

    func presentShareInviteVC() {
        MailTracker.log(event: "email_thread_share", params: [MailTracker.sourceParamKey(): MailTracker.source(type: logThreadActionSource)])

        let msgIds = mailItem.messageItems.map { (item) -> String in
            return item.message.id
        }
        accountContext.provider.routerProvider?.forwardMailMessageShareBody(threadId: viewModel.threadId, messageIds: msgIds, summary: viewModel.subject  ?? "", fromVC: self)
    }

    func deletePermanently() {
        if realViewModel.isForDeleteSingleMessage(), let msgID = viewModel.messageId {
            deleteMessagePermanentlyFromAppLink(trashMessageIds: [msgID], trackHandler: nil, isAllowAllLabels: self.isAllowAllLabels)
            return
        }
        let alert = LarkAlertController()
        alert.setContent(text: BundleI18n.MailSDK.Mail_ThreadAction_DeleteForeverConfirm, alignment: .center)
        alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_Alert_Cancel)
        alert.addDestructiveButton(text: BundleI18n.MailSDK.Mail_Alert_Delete, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            MailRoundedHUD.showLoading(on: self.view, disableUserInteraction: false)
            self.threadActionDataManager.deletePermanently(threadIDs: [self.viewModel.threadId],
                                                           fromLabel: self.viewModel.labelId,
                                                           sourceType: self.logThreadActionSource).subscribe(onError: { [weak self] (_) in
                guard let `self` = self else { return }
                MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Toast_OperationFailed, on: self.view,
                                           event: ToastErrorEvent(event: .thread_delete_forever_fail,
                                                                  scene: .messagelist))
            }, onCompleted: { [weak self] in
                guard let `self` = self else { return }
                let viewController = WindowTopMostFrom(vc: self)
                self.backItemTapped() {
                    if let view = viewController.fromViewController?.view {
                        MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_Toast_DeleteThreadsSuccess, on: view)
                    }
                }
                self.barActionEvent(action: "delete_clean")
                self.closeScene(sender: UIButton())
            }).disposed(by: self.disposeBag)
        })
        navigator?.present(alert, from: self)
    }

    // MARK: - MailAction MailEditLabelsDelegate
    private func barActionEvent(action: String) {
        var mailShowType = ""
        if self.isFeedCard {
            mailShowType = "im_feed"
        } else if statInfo.from == .bot {
            mailShowType = "mail_bot_window"
        }
        let event = NewCoreEvent(event: .email_message_list_click)
        event.params = ["click": "thread_action",
                        "target": "none",
                        "action_position": "thread_bar",
                        "label_item": statInfo.newCoreEventLabelItem,
                        "is_trash_or_spam_list": statInfo.isTrashOrSpamList,
                        "action_type": action,
                        "mail_service_type": Store.settingData.getMailAccountListType(),
                        "mail_display_type": Store.settingData.threadDisplayType(),
                        "mail_show_type": mailShowType]
        event.post()
    }
    
    func archiveMail() {
        guard pageIsScrolling == false else { return }
        threadActionDataManager.archiveMail(threadID: viewModel.threadId,
                                            fromLabel: viewModel.labelId,
                                            msgIds: allMessageIds,
                                            sourceType: logThreadActionSource,
                                            on: nil)
        let viewController = WindowTopMostFrom(vc: self)
        backItemTapped() {
            if let view = viewController.fromViewController?.view {
                MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_ThreadAction_ArchiveToast, on: view)
            }
        }
        statMoveAction(type: "archive", messageId: nil)

        barActionEvent(action: "archive")
    }

    func trashMail() {
        guard pageIsScrolling == false else { return }
        let feedCardId = self.feedCardId.isEmpty ? nil : self.feedCardId
        threadActionDataManager.trashMail(threadID: viewModel.threadId,
                                          fromLabel: viewModel.labelId,
                                          msgIds: allMessageIds,
                                          sourceType: logThreadActionSource,
                                          feedCardId: feedCardId,
                                          on: view)
        backItemTapped()
        statMoveAction(type: "delete", messageId: nil)
        barActionEvent(action: "trash")
        closeScene(sender: UIButton())
    }

    func unreadMail() {
        guard pageIsScrolling == false else { return }
        threadActionDataManager.unreadMail(threadID: viewModel.threadId,
                                           fromLabel: viewModel.labelId,
                                           isRead: false,
                                           msgIds: allMessageIds,
                                           fromSearch: shouldLoadRemoteData,
                                           sourceType: logThreadActionSource)
        let viewController = WindowTopMostFrom(vc: self)
        backItemTapped() {
            if let view = viewController.fromViewController?.view {
                MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_ThreadAction_UnreadToast, on: view)
            }
        }
        statMoveAction(type: "markunread", messageId: nil)

        barActionEvent(action: "marksunread")
    }

    func readMail() {
        guard pageIsScrolling == false else { return }
        threadActionDataManager.unreadMail(threadID: viewModel.threadId,
                                           fromLabel: viewModel.labelId,
                                           isRead: true,
                                           msgIds: allMessageIds,
                                           fromSearch: shouldLoadRemoteData,
                                           sourceType: .threadAction)
        let viewController = WindowTopMostFrom(vc: self)
        backItemTapped() {
            if let view = viewController.fromViewController?.view {
                MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_ThreadAction_ReadToast, on: view)
            }
        }
    }

    func spamMail() {
        guard pageIsScrolling == false else { return }
        LarkAlertController.showSpamAlert(
            type: .markSpam,
            content: getCurrentSpamAlertContent(),
            from: self,
            navigator: accountContext.navigator,
            userStore: accountContext.userKVStore
        ) { [weak self] ignore in
            guard let self = self else { return }
            self.threadActionDataManager.spamMail(threadID: self.viewModel.threadId,
                                                  fromLabel: self.viewModel.labelId,
                                                  msgIds: self.allMessageIds,
                                                  sourceType: self.logThreadActionSource,
                                                  ignoreUnauthorized: ignore)
            let viewController = WindowTopMostFrom(vc: self)
            self.backItemTapped() {
                if let view = viewController.fromViewController?.view {
                    MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_MarkedAsSpam_Toast, on: view)
                }
            }
            self.statMoveAction(type: "spam", messageId: nil)
            self.barActionEvent(action: "report_spam")
        }
    }

    func notSpamMail() {
        guard pageIsScrolling == false else { return }
        LarkAlertController.showSpamAlert(
            type: .markNormal,
            content: getCurrentSpamAlertContent(),
            from: self,
            navigator: accountContext.navigator,
            userStore: accountContext.userKVStore
        ) { [weak self] ignore in
            guard let self = self else { return }
            self.threadActionDataManager.notSpamMail(threadID: self.viewModel.threadId,
                                                     fromLabel: self.viewModel.labelId,
                                                     msgIds: self.allMessageIds,
                                                     sourceType: .messageAction,
                                                     ignoreUnauthorized: ignore)
//            if Display.pad {
//                self.accountContext.navigator.showDetail(SplitViewController.makeDefaultDetailVC(),
//                                                         wrap: LkNavigationController.self, from: self)
//            }
            let viewController = WindowTopMostFrom(vc: self)
            self.backItemTapped() {
                if let view = viewController.fromViewController?.view {
                    MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_UnmarkedSpamMovetoInbox_Toast, on: view)
                }
            }
            self.statMoveAction(type: "unspam", messageId: nil)

            self.barActionEvent(action: "not_spam")
        }
    }

    func moveToInbox() {
        guard pageIsScrolling == false else { return }
        threadActionDataManager.moveToInbox(threadID: viewModel.threadId,
                                            fromLabel: viewModel.labelId,
                                            msgIds: allMessageIds,
                                            sourceType: .messageAction)
        let viewController = WindowTopMostFrom(vc: self)
        self.backItemTapped() {
            if let view = viewController.fromViewController?.view {
                MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_ThreadAction_InboxToast, on: view)
            }
        }
        var type = "moveToInbox"
        if viewModel.labelId == Mail_LabelId_Trash { // 感觉这里有待商榷，但是pm同学@dailiang这么设计埋点了。
            type = "undelete"
        } else if viewModel.labelId == Mail_LabelId_Archived {
            type = "unarchive"
        }
        statMoveAction(type: type, messageId: nil)

        barActionEvent(action: "move_to_inbox")
    }

    func moveToImportant() {
        guard pageIsScrolling == false else { return }
        MailDataSource.shared.moveMultiLabelRequest(threadIds: [viewModel.threadId],
                                                    fromLabel: viewModel.labelId,
                                                    toLabel: Mail_LabelId_Important)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                let viewController = WindowTopMostFrom(vc: self)
                self.backItemTapped() {
                    if let view = viewController.fromViewController?.view {
                        MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_SmartInbox_MoveToImportant_Success, on: view)
                    }
                }
                MailTracker.log(event: Homeric.EMAIL_SMARTINBOX_LABEL_CHANGE, params: [MailTracker.toParamKey(): "important",
                                                                                       MailTracker.sourceParamKey(): MailTracker.source(type: self.logThreadActionSource),
                                                                                       MailTracker.threadIDsParamKey(): self.viewModel.threadId,
                                                                                       MailTracker.isMultiselectParamKey(): "false"])
            }, onError: { (error) in
                // error
                MailLogger.error("mail moveToImportant error: \(error).")
            }).disposed(by: disposeBag)

        barActionEvent(action: "move_to_important")
    }

    func moveToOther() {
        guard pageIsScrolling == false else { return }
        MailDataSource.shared.moveMultiLabelRequest(threadIds: [viewModel.threadId],
                                                    fromLabel: viewModel.labelId,
                                                    toLabel: Mail_LabelId_Other)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                let viewController = WindowTopMostFrom(vc: self)
                self.backItemTapped() {
                    if let view = viewController.fromViewController?.view {
                        MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_SmartInbox_MoveToOthers_Success, on: view)
                    }
                }
                MailTracker.log(event: Homeric.EMAIL_SMARTINBOX_LABEL_CHANGE, params: [MailTracker.toParamKey(): "other",
                                                                                       MailTracker.sourceParamKey(): MailTracker.source(type: self.logThreadActionSource),
                                                                                       MailTracker.threadIDsParamKey(): self.viewModel.threadId,
                                                                                       MailTracker.isMultiselectParamKey(): "false"])
            }, onError: { (error) in
                // error
                MailLogger.error("mail moveToOther error: \(error).")
            }).disposed(by: disposeBag)

        barActionEvent(action: "move_to_other")
    }

    func deleteOutboxMail() {
        guard pageIsScrolling == false else { return }
        if let message = mailItem.messageItems.last?.message {
            let messageId = message.id
            let threadId = viewModel.threadId
            showDeleteOutboxMailAlert { [weak self] in
                guard let self = self else { return }
                let viewController = WindowTopMostFrom(vc: self)
                Store.updateOutboxMail(threadId: threadId, messageId: messageId, action: .delete)
                    .subscribe(onNext: { [weak self] (_) in
                        MailMessageListController.logger.info("updateOutboxDeleteAction succ threadId: \(threadId) messageId: \(messageId)")
                        guard let self = self else { return }
                        self.backItemTapped()
                        let viewController = WindowTopMostFrom(vc: self)
                        if let view = viewController.fromViewController?.view {
                            ActionToast.showSuccessToast(with: BundleI18n.MailSDK.Mail_Outbox_DeletedPermanentlyMobile, on: view)
                        }
                    }, onError: { (error) in
                        MailMessageListController.logger.error("updateOutboxDeleteAction failed threadId: \(threadId) messageId: \(messageId)", error: error)
                    }).disposed(by: self.disposeBag)
            }
        }
        barActionEvent(action: "outbox_delete")
    }

    func editOutboxMail() {
        guard pageIsScrolling == false else { return }
        let from = WindowTopMostFrom(vc: self)
        if let message = mailItem.messageItems.last?.message {
            let messageId = message.id
            let viewController = WindowTopMostFrom(vc: self)
            Store.updateOutboxMail(threadId: viewModel.threadId, messageId: messageId, action: .edit)
                .subscribe(onNext: { [weak self](arg0) in
                    guard let `self` = self else { return }
                    MailMessageListController.logger.info("updateOutboxEditAction succ threadId: \(self.viewModel.threadId) messageId: \(messageId)")
                    let (threadId, messageId) = arg0
                    let sendVC = MailSendController.makeSendNavController(accountContext: self.accountContext,
                                                                          threadID: threadId,
                                                                          messageID: messageId,
                                                                          action: .draft,
                                                                          labelId: Mail_LabelId_Outbox,
                                                                          statInfo: MailSendStatInfo(from: .messageOutboxEdit,
                                                                                                     newCoreEventLabelItem: self.statInfo.newCoreEventLabelItem),
                                                                          trackerSourceType: .outbox,
                                                                          ondiscard: self.makeDiscardDraftCallback(),
                                                                          mailItem: self.mailItem,
                                                                          fileBannedInfos: self.viewModel.fileBannedInfos)
                    self.backItemTapped()
                    self.navigator?.present(sendVC, from: viewController)
                }, onError: {[weak self] (error) in
                    guard let `self` = self else { return }
                    MailMessageListController.logger.error("updateOutboxEditAction failed threadId: \(self.viewModel.threadId) messageId: \(messageId)", error: error)
                }).disposed(by: self.disposeBag)
        }

        barActionEvent(action: "outbox_edit")
    }

    func didClickFoldOrUnfoldAciton(sender: UIControl) {
        guard pageIsScrolling == false else { return }
        guard let button = sender as? UIButton else {
            assertionFailure("review your logic")
            return
        }
        let shouFoldTag = 200
        let shouldFold = button.tag != shouFoldTag
        button.isEnabled = false
        if shouldFold {
            let jsstring = "window.foldallmessage()"
            callJavaScript(jsstring) { [weak button] (_, _) in
                button?.isEnabled = true
                button?.tag = shouFoldTag
                button?.setImage(Resources.mail_action_thread_unfold.withRenderingMode(.alwaysTemplate), for: .normal)
                button?.setImage(Resources.mail_action_thread_unfold.mail.alpha(0.7)?.withRenderingMode(.alwaysTemplate), for: .highlighted)
            }
        } else {
            let jsstring = "window.unfoldallmessage()"
            callJavaScript(jsstring) { [weak button] (_, _) in
                button?.isEnabled = true
                button?.tag = 0
                button?.setImage(Resources.mail_action_thread_packup.withRenderingMode(.alwaysTemplate), for: .normal)
                button?.setImage(Resources.mail_action_thread_packup.mail.alpha(0.7)?.withRenderingMode(.alwaysTemplate), for: .highlighted)
            }
        }
    }

    private func filterEmlActionIfNeed(actions: [MailMessageListActionFactory.ActionsStyleConfig]) -> [MailMessageListActionFactory.ActionsStyleConfig] {
        var hasDraft = false
        var hasScheduleMessage = false
        for item in mailItem.messageItems {
            if item.drafts.count > 0 {
                hasDraft = true
                break
            }
            if item.message.scheduleSendTimestamp > 0 {
                hasScheduleMessage = true
                break
            }
        }
        if hasDraft || hasScheduleMessage {
            return actions.filter { config in
                return config.type != .emlAsAttachment
            }
        }
        return actions
    }

    func moreActionDidClick(sender: UIControl) {
        guard pageIsScrolling == false else { return }
        MailTracker.log(event: "email_thread_more", params: [MailTracker.sourceParamKey(): MailTracker.source(type: logThreadActionSource)])
        let copyThreadActions = miniTopThreadActions()
        var actions = actionsFactory.messageListMoreActions(threadActions: copyThreadActions,
                                                            labelId: viewModel.labelId,
                                                            isFullReadMessage: isFullReadMessage,
                                                            isFromChat: isForwardCard(),
                                                            isSwitchToLM: !self.isContentLight)
        // 如果含有草稿，则不显示emlAsAttachment入口
        actions = filterEmlActionIfNeed(actions: actions)
        let lowerItems = actions.map { (config) -> MailActionItem in
            let temp = MailActionItem(title: config.title,
                                      icon: config.icon,
                                      udGroupNumber: config.type.messageListThreadGroupNumber) { [weak self] _ in
                guard let action = self?.actionWithConfig(config) else {
                    return
                }
                action()
            }
            return temp
        }
        var sections = [MoreActionSection]()
        var sectionItems = lowerItems
            .sorted(by: { item1, item2 in
                return item1.udGroupNumber < item2.udGroupNumber
            })
            .reduce(into: [[MailActionItemProtocol]]()) { tempo, item in
                if let lastArray = tempo.last {
                    if lastArray.first?.udGroupNumber == item.udGroupNumber {
                        let head: [[MailActionItemProtocol]] = Array(tempo.dropLast())
                        let tail: [[MailActionItemProtocol]] = [lastArray + [item]]
                        tempo = head + tail
                    } else {
                        tempo.append([item])
                    }
                } else {
                    tempo = [[item]]
                }
            }
        for sectionItem in sectionItems {
            sections.append(MoreActionSection(layout: .vertical, items: sectionItem))
        }
        let headerTitle = subject.isEmpty ? BundleI18n.MailSDK.Mail_ThreadList_TitleEmpty : subject
        let from = oldestFrom
        let subtitle = from.isEmpty ? nil : BundleI18n.MailSDK.Mail_Normal_FromColon + "\(from)"
        let headerConfig = MoreActionHeaderConfig(iconType: .image(Resources.mail_action_mail_icon/*UDIcon.mailFilled*/),
                                                  title: headerTitle, subtitle: subtitle)
        let popoverSourceView = rootSizeClassIsSystemRegular ? sender : nil
        // Thread
        presentMoreActionVC(headerConfig: headerConfig,
                            sectionData: sections,
                            popoverSourceView: popoverSourceView,
                            popoverRect: popoverSourceView?.bounds)
    }

    func presentMoreActionVC(headerConfig: MoreActionHeaderConfig?, sectionData: [MoreActionSection], popoverSourceView: UIView?, popoverRect: CGRect?) {
        let callback = { [weak self] (headerConfig: MoreActionHeaderConfig?, sectionData: [MoreActionSection], popoverSourceView: UIView?) -> Void in
            guard let `self` = self else { return }
            let moreVC = MoreActionViewController(headerConfig: headerConfig, sectionData: sectionData)
            if let popoverSourceView = popoverSourceView {
                moreVC.needAnimated = false
                moreVC.modalPresentationStyle = .popover
                moreVC.popoverPresentationController?.sourceView = popoverSourceView
                moreVC.popoverPresentationController?.sourceRect = popoverRect ?? CGRect.zero
                if let rect = popoverRect {
                    if rect.origin.y > UIScreen.main.bounds.height / 3 * 2 {
                        moreVC.popoverPresentationController?.permittedArrowDirections = .down
                        moreVC.arrowUp = false
                    } else {
                        moreVC.popoverPresentationController?.permittedArrowDirections = .up
                        moreVC.arrowUp = true
                    }
                }
            }
            self.navigator?.present(moreVC, from: self, animated: false, completion: nil)
        }

        _ = Store.settingData.getCurrentAccount().subscribe { (account) in
            var sectionData = sectionData
            if account.mailSetting.mailOnboardStatus == .forceInput || account.mailSetting.mailOnboardStatus == .smtpActive ||
                account.mailSetting.userType == .gmailApiClient ||
                account.mailSetting.userType == .exchangeApiClient {
                sectionData = sectionData.map { (section) -> MoreActionSection in
                    var section = section
                    section.items = section.items.filter({ $0.title != BundleI18n.MailSDK.Mail_Recall_Action })
                    return section
                }
            }
            callback(headerConfig, sectionData, popoverSourceView)
        } onError: { (err) in
            mailAssertionFailure("error: \(err)")
            callback(headerConfig, sectionData, popoverSourceView)
        }
    }

    func moveToLabel() {
        MailTracker.log(event: "email_thread_moveto", params: [MailTracker.sourceParamKey(): MailTracker.source(type: logThreadActionSource)])
        guard pageIsScrolling == false else { return }
        // threadLabels 传入folder信息，默认勾选
        let moveToVC = MailMoveToLabelViewController(threadIds: [viewModel.threadId], fromLabelId: viewModel.labelId, accountContext: accountContext)
        moveToVC.spamAlertContent = getCurrentSpamAlertContent()
        if Store.settingData.folderOpen() || Store.settingData.mailClient {
            moveToVC.scene = .moveToFolder
            MailTracker.log(event: "email_thread_move_to_folder", params: [MailTracker.sourceParamKey(): MailTracker.source(type: .threadAction), "thread_count": 1])
        }
        let nav = LkNavigationController(rootViewController: moveToVC)
        nav.modalPresentationStyle = .fullScreen
        if #available(iOS 13.0, *) {
            nav.modalPresentationStyle = .automatic
        }
        if Display.pad {
            nav.modalPresentationStyle = .formSheet
        }
        moveToVC.newFolderDelegate = externalDelegate
        moveToVC.didMoveLabelCallback = { [weak self] toLabel, _, _ in
            self?.dismissSelf()
            if toLabel.labelId == Mail_LabelId_Spam {
                self?.barActionEvent(action: "move_to_spam")
            }
        }
        navigator?.present(nav, from: self)

        barActionEvent(action: "move_to")
    }
    func handleBlockSenderClick(msgId: String) {
        if let messageItem = viewModel.mailItem?.getMessageItem(by: msgId) {
            let feedThreadId = self.mailItem.feedMessageItems.first(where: {$0.item.message.id == messageItem.message.id})?.threadID ?? ""
            let feedLabelId = self.mailItem.feedMessageItems.first(where: {$0.item.message.id == messageItem.message.id})?.labelIds.first ?? ""
            let threadId = self.isFeedCard ? feedThreadId : viewModel.threadId
            let labelId = self.isFeedCard ? feedLabelId : self.viewModel.labelId
            
            let blockItem = BlockItem(threadId: threadId,
                                      messageId: messageItem.message.id,
                                      addressList: [messageItem.message.from])
            self.senderBlocker = BlockSenderManager(accountContext: accountContext,
                                                    labelID: labelId,
                                                    scene: .message,
                                                    originBlockItems: [blockItem],
                                                    feedCardId: self.feedCardId)
            self.senderBlocker?.delegate = self
            senderBlocker?.showPopupMenu(fromVC: self)
        }
    }
    func handleBlockSenderClick() {
        guard let mailItem = self.viewModel.mailItem else { return }
        let addressList: [Email_Client_V1_Address] = mailItem.messageItems.map({ item in
            item.message.from
        })
        let blockItem = BlockItem(threadId: viewModel.threadId,
                                  messageId: nil,
                                  addressList: addressList)
        let feedCardId = self.feedCardId.isEmpty ? nil : self.feedCardId
        self.senderBlocker = BlockSenderManager(accountContext: accountContext,
                                                labelID: self.viewModel.labelId,
                                                scene: .messageThread,
                                                originBlockItems: [blockItem],
                                                feedCardId:feedCardId)
        self.senderBlocker?.delegate = self
        senderBlocker?.showPopupMenu(fromVC: self)
    }
    
    func switchContentDarkMode() {
        self.isContentLight = !self.isContentLight
        let modelsCount = realViewModel.allMailViewModels.count
        for i in 0...modelsCount-1 {
            guard let viewModel = self.realViewModel[i] else { continue }
            if let webView = getWebViewOf(threadId: viewModel.threadId) {
                // 当前及前后页面
                if i >= currentPageIndex - 1 && i <= currentPageIndex + 1 {
                    callJavaScript("window.updateContentStyle(\(self.isContentLight))", in: webView)
                }
            }
            // html文本会被缓存在bodyHtml里，更改了内容区DM后需要清空使下一次浏览时重新走组装template的流程
            viewModel.bodyHtml = nil
        }
        accountContext.messageListPreloader.clear()
        let kvStore = MailKVStore(space: .global, mSpace: .global)
        if self.isContentLight != kvStore.value(forKey: "mail_contentSwitch_isLight") {
            kvStore.set(self.isContentLight, forKey: "mail_contentSwitch_isLight")
        }
        actionsFactory.resetActionConfigMap(isContentLM: self.isContentLight)
    }

    func cancelAllScheduleSend() {
        cancelScheduleSendConfirm()
    }

    func cancelScheduleSendConfirm() {
        let alert = LarkAlertController()
        alert.setContent(text: BundleI18n.MailSDK.Mail_SendLater_CancelScheduledAlert, alignment: .center)
        alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_SendLater_AlertBack)
        alert.addDestructiveButton(text: BundleI18n.MailSDK.Mail_SendLater_AlertCancelAll, dismissCompletion: { [weak self] in
            self?.cancelScheduleSend()
        })
        navigator?.present(alert, from: self)
    }

    func cancelScheduleSend() {
        MailTracker.log(event: "email_thread_scheduledSend_cancel", params: [MailTracker.sourceParamKey(): MailTracker.source(type: logThreadActionSource)])
        let feedCardId = self.feedCardId.isEmpty ? nil : self.feedCardId
        MailDataSource.shared.cancelScheduledSend(messageId: "", threadIds: [viewModel.threadId], feedCardID: feedCardId)
            .subscribe(onNext: {[weak self] _ in
                guard let `self` = self else { return }
                MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_SendLater_Cancelsucceed, on: self.view)
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                MailLogger.error("mail cancelScheduledSend error: \(error)")
                MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_SendLater_CancelFailure,
                                           on: self.view, event: ToastErrorEvent(event: .schedule_send_cancel_fail))
            }).disposed(by: disposeBag)

        barActionEvent(action: "outbox_delete")
    }

    func changeLablsThreadAction() {
        changeLabels(isThreadAction: true)

        barActionEvent(action: "changelabel")
    }

    func changeLabels(isThreadAction: Bool) {
        if isThreadAction {
            MailTracker.log(event: "email_thread_changelabel", params: [MailTracker.sourceParamKey(): MailTracker.source(type: logThreadActionSource)])
        }
        guard self.threadActions.first(where: { $0.action == .changeLabels }) != nil else {
            return
        }
        self.threadLabels = mailItem.labels.map({ MailFilterLabelCellModel(pbModel: $0) })
        let labelsVC = MailEditLabelsViewController(mailItem: mailItem, threadLabels: threadLabels, threadId: viewModel.threadId, fromLabel: fromLabel, accountContext: accountContext)
        labelsVC.editLabelDelegate = self
        labelsVC.currentLabelRemoveHandler = { [weak self] in
            guard let self = self else { return }
            self.dismissSelf(dismissMsgListSecretly: true)
        }
        let viewController = WindowTopMostFrom(vc: self)
        labelsVC.dismissCompletionHandler = { (toast) in
            if let view = viewController.fromViewController?.view {
                MailRoundedHUD.showSuccess(with: toast, on: view)
            }
        }
        let nav = LkNavigationController(rootViewController: labelsVC)
        nav.modalPresentationStyle = .fullScreen
        if #available(iOS 13.0, *) {
            nav.modalPresentationStyle = .automatic
        }
        if Display.pad {
            nav.modalPresentationStyle = .formSheet
        }
        navigator?.present(nav, from: self, animated: true, completion: nil)
    }

    func showEditLabelToast(_ toast: String, uuid: String) {
        MailRoundedHUD.showSuccess(with: toast, on: self.view)
    }

    func manageStrangerThread(threadIDs: [String]?, status: Bool, isSelectAll: Bool, dismissMsgListSecretly: Bool = false) {
        barActionEvent(action: status ? "allow_sender" : "reject_sender")
        if self.isFullScreenMode {
            self.leaveFullScreenItemClicked(sender: UIButton())
        }
        if #available(iOS 13.0, *) {
            if let sceneInfo = self.currentScene()?.sceneInfo,
               !sceneInfo.isMainScene() {
                self.manageThreadAfterDismiss(threadIDs: threadIDs, status: status, isSelectAll: isSelectAll, completionHandler: { [weak self] in
                    self?.dismissSelf(dismissMsgListSecretly: true)
                })
            } else {
                dismissSelf(completion: { [weak self] in
                    self?.manageThreadAfterDismiss(threadIDs: threadIDs, status: status, isSelectAll: isSelectAll)
                }, dismissMsgListSecretly: dismissMsgListSecretly)
            }
        } else {
            dismissSelf(completion: { [weak self] in
                self?.manageThreadAfterDismiss(threadIDs: threadIDs, status: status, isSelectAll: isSelectAll)
            }, dismissMsgListSecretly: dismissMsgListSecretly)
        }
    }

    func manageThreadAfterDismiss(threadIDs: [String]?, status: Bool, isSelectAll: Bool, completionHandler: (() -> Void)? = nil) {
        let fromAddress = self.viewModel.mailItem?.messageItems.first?.message.from.address ?? ""
        if let externalDelegate = self.externalDelegate {
            externalDelegate.msgListManageStrangerThread(threadIDs: threadIDs, status: status, isSelectAll: isSelectAll, maxTimestamp: (self.viewModel.mailItem?.messageItems.first?.message.createdTimestamp ?? 0) + 1, fromList: [fromAddress])
            self.externalDelegate = nil // 兼容多读信页delegate重复调用的场景
        } else { // 特殊case iPad分屏通过路由跳转
            var request = Email_Client_V1_MailManageStrangerRequest()
            request.manageType = status ? .allow : .reject
            if let threadIds = threadIDs { request.threadIds = threadIds }
            request.isSelectAll = isSelectAll
            request.maxTimestamp = (self.viewModel.mailItem?.messageItems.first?.message.createdTimestamp ?? 0) + 1
            request.fromList = [fromAddress]

            Store.settingData.updateBatchChangeSession(batchChangeInfo: MailBatchChangeInfo(sessionID: self.viewModel.threadId + "\(status)" + "msgList", request: request, status: .success, totalCount: 1, progress: 100))
            MailDataServiceFactory
                .commonDataService?.manageStrangerThread(type: status ? .allow : .reject, threadIds: threadIDs, isSelectAll: isSelectAll, maxTimestamp: (self.viewModel.mailItem?.messageItems.first?.message.createdTimestamp ?? 0) + 1, fromList: [fromAddress])
                .subscribe(onNext: { [weak self] (_) in
                    guard let `self` = self else { return }
                    let text = {
                        if status {
                            return BundleI18n.MailSDK.Mail_StrangerMail_SenderAllowed_Toast
                        } else {
                            return BundleI18n.MailSDK.Mail_StrangerMail_SenderRejected_Toast
                        }
                    }()
                    UDToast.showSuccess(with: text, on: self.fromViewController?.view ?? UIView())
                    completionHandler?()
                }, onError: { [weak self] (error) in
                    guard let `self` = self else { return }
                    MailLogger.error("[mail_stranger] send manageStrangerThread request failed error: \(error)")
                    UDToast.showFailure(with: BundleI18n.MailSDK.Mail_StrangerInbox_UnableSendToInboxRetry_Text, on: self.fromViewController?.view ?? UIView())
                    completionHandler?()
                }).disposed(by: self.disposeBag)
        }
    }

    func bottomActionItemsFor(_ idx: Int) -> [MailActionItem] {
        guard let targetViewModel = realViewModel[idx], let targetMailItem = targetViewModel.mailItem else {
            return []
        }
        var items: [MailActionItem] = []

        if viewModel.labelId == Mail_LabelId_Stranger && accountContext.featureManager.open(.stranger, openInMailClient: false) {
            items.append(MailActionItem(title: BundleI18n.MailSDK.Mail_StrangerInbox_Allow_Button,
                                        icon: UDIcon.replyOutlined.withRenderingMode(.alwaysTemplate),
                                        actionType: .allowStranger) { [weak self] _ in
                guard let self = self else { return }
                self.manageStrangerThread(threadIDs: [self.viewModel.threadId], status: true, isSelectAll: false)
                self.closeScene(sender: UIButton())
            })
            items.append(MailActionItem(title: BundleI18n.MailSDK.Mail_StrangerInbox_Reject_Button,
                                        icon: UDIcon.replyOutlined.withRenderingMode(.alwaysTemplate),
                                        actionType: .rejectStranger) { [weak self] _ in
                guard let self = self else { return }
                self.manageStrangerThread(threadIDs: [self.viewModel.threadId], status: false, isSelectAll: false)
                self.closeScene(sender: UIButton())
            })
            return items
        }

        enum QuickActionType: String {
            case reply
            case replyAll
            case forward
            case shareMail

            private var trackerEventName: String {
                switch self {
                case .reply:
                    return "email_thread_reply"
                case .replyAll:
                    return "email_thread_replyall"
                case .forward:
                    return "email_thread_forward"
                case .shareMail:
                    return "email_thread_share"
                }
            }
            /// 上报埋点, https://bytedance.feishu.cn/sheets/WC2LszXv2hxrp2tPT4hcvaXynMb?scene=multi_page&sub_scene=message
            private var coreEventName: String {
                switch self {
                case .reply:
                    return "reply"
                case .replyAll:
                    return "reply_all"
                case .forward:
                    return "forward"
                case .shareMail:
                    return "email_share"
                }
            }
            
            func handlerTrack(isBot: Bool, eventLabelItem: String, logThreadActionSource: MailTracker.SourcesType, isTrashOrSpamList: String, isFeed: Bool) {
                MailTracker.log(event: self.trackerEventName, params: [MailTracker.sourceParamKey(): MailTracker.source(type: logThreadActionSource)])
                var mailShowType = ""
                if isFeed {
                    mailShowType = "im_feed"
                } else if isBot {
                    mailShowType = "mail_bot_window"
                }
                let event = NewCoreEvent(event: .email_message_list_click)
                event.params = ["click": "message_quick_action",
                                "target": "none",
                                "label_item": eventLabelItem,
                                "is_trash_or_spam_list": isTrashOrSpamList,
                                "action_type": self.coreEventName,
                                "mail_display_type": Store.settingData.threadDisplayType(),
                                "mail_show_type": mailShowType]
                event.post()
            }
        }

        let actionHandler: ((QuickActionType) -> Void) = { [weak self] actionType in
            guard let self = self, self.pageIsScrolling == false, let lastMessage = self.realViewModel[idx]?.mailItem?.messageItems.last else { return }
            switch actionType {
            case .reply:
                self.reply(replyMsgID: lastMessage.message.id, isFromFootBtn: true)
            case .replyAll:
                self.replyAll(replyMsgID: lastMessage.message.id, isFromFootBtn: true)
            case .forward:
                self.forward(replyMsgID: lastMessage.message.id, isFromFootBtn: true)
            case .shareMail:
                self.shareMail()
            }
            actionType.handlerTrack(isBot: self.statInfo.from == .bot, eventLabelItem: self.statInfo.newCoreEventLabelItem, logThreadActionSource: self.logThreadActionSource, isTrashOrSpamList: self.statInfo.isTrashOrSpamList, isFeed: self.isFeedCard)
        }

        /// 根据action返回对应item
        let actionItemForActionType: ((QuickActionType) -> MailActionItem) = { actionType in
            switch actionType {
            case .reply:
                return MailActionItem(title: BundleI18n.MailSDK.Mail_Normal_Reply,
                                      icon: UDIcon.replyOutlined.withRenderingMode(.alwaysTemplate)) { _ in
                    actionHandler(actionType)
                }
            case .replyAll:
                return MailActionItem(title: BundleI18n.MailSDK.Mail_Compose_Template_ReplyAll,
                                      icon: UDIcon.replyAllOutlined.withRenderingMode(.alwaysTemplate)) { _ in
                    actionHandler(actionType)
                }
            case .forward:
                return MailActionItem(title: BundleI18n.MailSDK.Mail_Normal_Forward,
                                      icon: UDIcon.forwardOutlined.withRenderingMode(.alwaysTemplate)) { _ in
                    actionHandler(actionType)
                }
            case .shareMail:
                return MailActionItem(title: BundleI18n.MailSDK.Mail_SharetoChat_MenuItem,
                                      icon: UDIcon.shareOutlined.withRenderingMode(.alwaysTemplate)) { _ in
                    actionHandler(actionType)
                }
            }
        }

        let isScheduledSend: Bool
        if let last = targetMailItem.messageItems.last, last.message.scheduleSendTimestamp > 0 {
            isScheduledSend = true
        } else {
            isScheduledSend = false
        }
        /// outbox 和 scheduleSend 不能回复、转发
        if viewModel.labelId != Mail_LabelId_Outbox && !isScheduledSend {
            // reply
            items.append(actionItemForActionType(.reply))

            // replyAll
            if targetMailItem.messageItems.last?.message.canReplyAll == true {
                items.append(actionItemForActionType(.replyAll))
            }

            // forward
            items.append(actionItemForActionType(.forward))

            if !isForwardCard(),
               !Store.settingData.mailClient,
               !targetMailItem.labels.map({ $0.id }).contains(where: { $0 == Mail_LabelId_Spam || $0 == Mail_LabelId_Trash || $0 == Mail_LabelId_Scheduled }),
               !Store.settingData.mailClient {
                items.append(actionItemForActionType(.shareMail))
            }
        }
        return items
    }

    func showContextMenuPanel(threadID: String, messageID: String, isTranslated: Bool, avatarInfo: (initial: String, color: UIColor)?, menuFrame: CGRect?, labelID: String? = nil, needBlockTrash: Bool = false) {
        guard let viewModel = realViewModel[threadId: threadID],
              let mailItem = viewModel.mailItem,
              let messageItem = mailItem.messageItems.first(where: { $0.message.id == messageID }) else {
            return
        }
        let headerTitle = messageItem.message.from.mailDisplayNameNoMe
        let subtitle = messageItem.message.bodySummary

        let headerIconType: MoreActionHeaderIconType
        if let avatarInfo = avatarInfo {
            headerIconType = .text(avatarInfo.initial, backgroundColor: avatarInfo.color)
        } else {
            headerIconType = .avatar(messageItem.message.from.larkEntityIDString, name: messageItem.message.from.mailDisplayNameNoMe)
        }

        let headerConfig = MoreActionHeaderConfig(iconType: headerIconType, title: headerTitle, subtitle: subtitle)
        let items = createMenuItem(viewModel: viewModel, mailItem: mailItem, messageItem: messageItem,
                                   isTranslated: isTranslated, labelID: labelID, needBlockTrash: needBlockTrash)
        var sourceView: UIView? = nil
        var sourceRect: CGRect? = nil
        if rootSizeClassIsSystemRegular && menuFrame != nil {
            sourceView = self.webView
            sourceRect = menuFrame
        }
        var sections = [MoreActionSection]()
        let sectionItems = items
            .sorted(by: { item1, item2 in
                return item1.udGroupNumber < item2.udGroupNumber
            })
            .reduce(into: [[MailActionItemProtocol]]()) { tempo, item in
                if let lastArray = tempo.last {
                    if lastArray.first?.udGroupNumber == item.udGroupNumber {
                        let head: [[MailActionItemProtocol]] = Array(tempo.dropLast())
                        let tail: [[MailActionItemProtocol]] = [lastArray + [item]]
                        tempo = head + tail
                    } else {
                        tempo.append([item])
                    }
                } else {
                    tempo = [[item]]
                }
            }
        for sectionItem in sectionItems {
            sections.append(MoreActionSection(layout: .vertical, items: sectionItem))
        }
#if ALPHA || DEBUG
        let kvStore = MailKVStore(space: .global, mSpace: .global)
        if kvStore.bool(forKey: MailDebugViewController.kMailDataDebug) {
            let debugItem = MailActionItem(title: "message detail data",
                                           icon: Resources.mail_action_reedit.withRenderingMode(.alwaysTemplate),
                                           udGroupNumber: 999,
                                           actionCallBack: { [weak self] _ in
                guard let `self` = self else { return }
                guard let viewModel = self.realViewModel[threadId: threadID],
                              let mailItem = viewModel.mailItem,
                              let messageItem = mailItem.messageItems.first(where: { $0.message.id == messageID }) else {
                            return
                }
                let vc = MailDetailDataVC()
                var threadInfo = "ThreadId: " + mailItem.threadId + "\n"
                vc.detailData = threadInfo + messageItem.debugDescription
                self.navigator?.push(vc, from: self, animated: true)
            }
            )
            sections.append(MoreActionSection(layout: .vertical, items: [debugItem]))
        }
#endif
        // message Item
        presentMoreActionVC(headerConfig: headerConfig, sectionData: sections, popoverSourceView: sourceView, popoverRect: sourceRect)
    }

    private func createMenuItem(viewModel: MailMessageListPageViewModel, mailItem: MailItem, messageItem: MailMessageItem, isTranslated: Bool, labelID: String? = nil, needBlockTrash: Bool = false) -> [MailActionItem] {
        let itemsType = MailMessageListRenderModel.contextMenuItemsFor(atLabelID: labelID ?? viewModel.labelId,
                                                                       mailItem: mailItem,
                                                                       messageItem: messageItem,
                                                                       isTranslated: isTranslated,
                                                                       isFromChat: isForwardCard(),
                                                                       userID: accountContext.user.userID ?? "",
                                                                       featureManager: accountContext.featureManager,
                                                                       needBlockTrash: needBlockTrash)
        if itemsType.contains(.translate) {
            // 翻译展示，打点
            MailTracker.log(event: Homeric.MAIL_TRANSLATION_SINGLE_MESSAGE_BTN_VIEWED,
                            params: ["thread_biz_id": mailItem.threadId, "message_id": messageItem.message.id])
        }
        return itemsType.map { type in
            let msgID = messageItem.message.id
            let subject = messageItem.message.subject
            let feedThreadId = mailItem.feedMessageItems.first(where: {$0.item.message.id == msgID})?.threadID
            let threadID = (self.isFeedCard ? feedThreadId : mailItem.threadId) ?? ""
            let feedLabelId = mailItem.feedMessageItems.first(where: {$0.item.message.id == msgID})?.labelIds.first
            let label = (self.isFeedCard ? feedLabelId : labelID) ?? ""
            let actionItem = MailActionItem(title: type.title,
                                            icon: type.icon,
                                            udGroupNumber: type.messageItemGroupNumber,
                                            actionCallBack: { [weak self] _ in
                guard let self = self else { return }
                self.handleContextMenuAction(type: type,
                                             threadID: threadID,
                                             msgID: msgID,
                                             subject: subject,
                                             labelId: label)
            })
            return actionItem
        }
    }

    func reEdit(threadID: String, msgID: String) {
        let mailItem = self.mailItem
        let labelItem = statInfo.newCoreEventLabelItem
        _ = MailDataServiceFactory.commonDataService?.reEditMsg(threadID: threadID, msgID: msgID).subscribe { [weak self] (draft) in
            guard let self = self else { return }
            let vc = MailSendController.makeSendNavController(
                accountContext: self.accountContext,
                threadID: threadID,
                messageID: msgID,
                action: .reEdit,
                draft: draft,
                statInfo: MailSendStatInfo(from: .msgReEdit, newCoreEventLabelItem: labelItem),
                trackerSourceType: MailTracker.SourcesType.editAgain,
                mailItem: mailItem,
                fileBannedInfos: self.viewModel.fileBannedInfos,
                feedCardId: self.feedCardId)
            self.navigator?.present(vc, from: self)
        } onError: { [weak self] (err) in
            guard let self = self else { return }
            mailAssertionFailure("fail get draft: \(err)")
            MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Normal_Failed, on: self.view)
        }
        var mailShowType = ""
        if self.isFeedCard {
            mailShowType = "im_feed"
        } else if statInfo.from == .bot {
            mailShowType = "mail_bot_window"
        }
        // event
        let event = NewCoreEvent(event: .email_message_list_click)
        event.params = ["click": "message_action",
                        "target": "none",
                        "label_item": statInfo.newCoreEventLabelItem,
                        "is_trash_or_spam_list": statInfo.isTrashOrSpamList,
                        "action_type": NewCoreEvent.ActionType.edit_again.rawValue,
                        "mail_display_type": Store.settingData.threadDisplayType(),
                        "mail_show_type": mailShowType]
        event.post()
    }

    func getThreadId() -> String? {
        return viewModel.threadId
    }

    private func getCurrentSpamAlertContent() -> SpamAlertContent {
        var hasExtern = true
        if let item = viewModel.mailItem {
            hasExtern = item.messageItems.filter({ item in
                item.message.security.isFromExternal
            }).count > 0
        }
        return SpamAlertContent(
            threadIDs: [viewModel.threadId],
            fromLabelID: viewModel.labelId,
            mailAddresses: viewModel.mailItem?.messageItems.map({ $0.message.from.address }) ?? [],
            unauthorizedAddresses: [],
            isFromMessageList: true,
            isAllAuthorized: viewModel.mailItem?.isAllFromAuthorized == true,
            shouldFetchUnauthorized: true,
            scene: .message,
            allInnerDomain: !hasExtern
        )
    }

    // MARK: - message action

    func replyAll(replyMsgID: String, isFromFootBtn: Bool) {
        Store.settingData.mailClientExpiredCheck(accountContext: accountContext, from: self) { [weak self] in
            self?._replyAll(replyMsgID: replyMsgID, isFromFootBtn: false)
        }
    }

    private func _replyAll(replyMsgID: String, isFromFootBtn: Bool) {
        let source = isFromFootBtn ? MailTracker.SourcesType.messageActionReplyAll : MailTracker.SourcesType.messageQuickActionReplyAll
        _mailReplyAction(replyMsgID: replyMsgID, sendAction: .replyAll, from: .messageReplyAll, source: source)
    }

    func forward(replyMsgID: String, isFromFootBtn: Bool) {
        Store.settingData.mailClientExpiredCheck(accountContext: accountContext, from: self) { [weak self] in
            self?._forward(replyMsgID: replyMsgID, isFromFootBtn: false)
        }
    }

    private func _forward(replyMsgID: String, isFromFootBtn: Bool) {
        let source = isFromFootBtn ? MailTracker.SourcesType.messageActionForward : MailTracker.SourcesType.messageQuickActionForward
        _mailReplyAction(replyMsgID: replyMsgID, sendAction: .forward, from: .messageForward, source: source)
    }

    func reply(replyMsgID: String, isFromFootBtn: Bool) {
        Store.settingData.mailClientExpiredCheck(accountContext: accountContext, from: self) { [weak self] in
            self?._reply(replyMsgID: replyMsgID, isFromFootBtn: false)
        }
    }

    private func _reply(replyMsgID: String, isFromFootBtn: Bool) {
        let source = isFromFootBtn ? MailTracker.SourcesType.messageQuickActionReply : MailTracker.SourcesType.messageActionReply
        _mailReplyAction(replyMsgID: replyMsgID, sendAction: .reply, from: .messageReply, source: source)
    }

    private func _mailReplyAction(
        replyMsgID: String,
        sendAction: MailSendAction,
        from: MailSendStatInfo.From,
        source: MailTracker.SourcesType
    ) {
        let isFullscreenMode = self.isFullScreenMode
        if isForwardCard() {
            handleSendToChatDraft(msgID: replyMsgID, action: sendAction.getDraftAction())
        } else {
            showStrangerReplyAlertIfNeeded(messageID: replyMsgID, action: sendAction) { [weak self] (needHandleStrangerCard, needReply) in
                guard needReply else { return }
                self?.showInterceptSendAlertIfNeeded(messageID: replyMsgID, action: sendAction) { [weak self] (needBlockImage, isCancel) in
                    guard let self = self else { return }
                    if isCancel {
                        if needHandleStrangerCard {
                            self.manageStrangerThread(threadIDs: [self.viewModel.threadId], status: true,
                                                      isSelectAll: false, dismissMsgListSecretly: true)
                            self.closeScene(sender: UIButton())
                        }
                    } else {
                        let draft = self.findDraft(replyMsgId: replyMsgID)
                        if isFullscreenMode {
                            self.leaveFullScreenItemClicked(sender: UIButton())
                            self.backCallback?()
                        }
                        self.presentSendVC(msgID: replyMsgID,
                                           draft: draft,
                                           source: source,
                                           action: sendAction,
                                           sendStatInfo: MailSendStatInfo(from: from, newCoreEventLabelItem: self.statInfo.newCoreEventLabelItem),
                                           needBlockImage: needBlockImage,
                                           closeHandler: { self.closeScene(sender: UIButton()) },
                                           completion: {
                            /// 弹出写信页后, 操作允许
                            if needHandleStrangerCard {
                                self.manageStrangerThread(threadIDs: [self.viewModel.threadId], status: true,
                                                          isSelectAll: false, dismissMsgListSecretly: true)
                            }
                        })
                    }
                }
            }
        }
    }

    func closeScene(completionHandler: (() -> Void)?) {
        if #available(iOS 13.0, *) {
            if let sceneInfo = self.currentScene()?.sceneInfo,
               !sceneInfo.isMainScene() {
                SceneManager.shared.deactive(from: self)
                DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.large) {
                    completionHandler?()
                }
            } else {
                completionHandler?()
            }
        } else {
            completionHandler?()
        }
    }

    private func handleUnsubscribe(messageId: String, trackHandler: (() -> Void)?) {
        guard !Store.settingData.mailClient else { return }
        guard let mailItem = viewModel.mailItem?.messageItems.first(where: { $0.message.id == messageId }) else {
            return
        }

        let fromEmailAddress = mailItem.message.from.address

        let alert = LarkAlertController()
        alert.setTitle(text: BundleI18n.MailSDK.Mail_Unsubscribe_Name)

        let state = MailUnsubscribeManager.unsubscribeState(for: mailItem)
        switch state {
        case .hide:
            MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Unsubscribe_Failed, on: self.view, event: ToastErrorEvent(event: .read_unsubscribte_fail))
            return
        case .subscribedMailTo, .subscribedOneClick:
            alert.setContent(text: BundleI18n.MailSDK.Mail_Unsubscribe_DescOne(fromEmailAddress))
        case .subscribedRedirect:
            alert.setContent(text: BundleI18n.MailSDK.Mail_Unsubscribe_DescTwo(fromEmailAddress))
        }

        alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_Alert_Cancel)
        alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_Unsubscribe_Name, dismissCompletion: { [weak self] in
            guard let strongSelf = self else { return }
            trackHandler?()
            strongSelf.startUnsubscribeFor(messageId: messageId, state: state)
        })

        let params: [String: Any] = ["thread_id": viewModel.threadId,
                                     "message_id": messageId]
        MailTracker.log(event: "mail_unsubscribe_btn_clicked", params: params)

        navigator?.present(alert, from: self)
    }

    private func startUnsubscribeFor(messageId: String, state: MailUnsubscribeState) {
        guard !Store.settingData.mailClient else { return }
        let threadId = viewModel.threadId
        switch state {
        case .hide: return
        case .subscribedMailTo, .subscribedOneClick:
            MailRoundedHUD.showLoading(on: self.view)
            MailUnsubscribeManager.unsubscribe(for: messageId, in: threadId).subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                let params: [String: Any] = ["thread_id": threadId,
                                             "message_id": messageId,
                                             "move_to_spam": 0,
                                             "is_success": "true"]
                MailTracker.log(event: "mail_unsubscribe_confirmed", params: params)

                MailMessageListController.logger.debug("MailUnsubscribe: Succeed \(messageId)")
                MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_Unsubscribe_Done, on: self.view)
            }, onError: { [weak self] error in
                guard let `self` = self else { return }
                let params: [String: Any] = ["thread_id": threadId,
                                             "message_id": messageId,
                                             "move_to_spam": 0,
                                             "is_success": "false"]
                MailTracker.log(event: "mail_unsubscribe_confirmed", params: params)

                MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Unsubscribe_Failed, on: self.view,
                                           event: ToastErrorEvent(event: .read_unsubscribte_fail))
                MailMessageListController.logger.debug("MailUnsubscribe: Error: \(messageId) " + (error.localizedDescription))
            }).disposed(by: disposeBag)
        case .subscribedRedirect(let urlString):
            guard let encodedURLString = urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.whitespacesAndNewlines.inverted),
                  let url = URL(string: encodedURLString) else {
                let params: [String: Any] = ["thread_id": threadId,
                                             "message_id": messageId,
                                             "move_to_spam": 0,
                                             "is_success": "false"]
                MailTracker.log(event: "mail_unsubscribe_confirmed", params: params)
                MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Unsubscribe_Failed, on: self.view,
                                           event: ToastErrorEvent(event: .read_unsubscribte_fail))
                return
            }
            let params: [String: Any] = ["thread_id": threadId,
                                         "message_id": messageId,
                                         "move_to_spam": 0,
                                         "is_success": "true"]
            MailTracker.log(event: "mail_unsubscribe_confirmed", params: params)
            navigator?.push(url, context: ["from": "mail"], from: self)
        }
    }

    private func handleRecall(messageId: String) {
        // Sent before 24 hours, dont handle recall
        if let messageCreatedTimestamp = viewModel.mailItem?.messageItems.first(where: { $0.message.id == messageId })?.message.createdTimestamp {
            let interval = Date().timeIntervalSince1970 - TimeInterval(messageCreatedTimestamp / 1000)
            if interval > MailRecallManager.shared.recallTimeLimit {
                MailRoundedHUD.showTips(with: MailRecallError.sentLongTimeAgo.errorText, on: self.view,
                                        event: ToastErrorEvent(event: .recall_mail_fail_timeout))
                return
            }
        }

        let alert = LarkAlertController()
        alert.setTitle(text: BundleI18n.MailSDK.Mail_Recall_ConfirmTitle)
        alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_Alert_Cancel)
        alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_Recall_Action, dismissCompletion: { [weak self] in
            self?.startRecallFor(messageId: messageId)
        })
        navigator?.present(alert, from: self)
    }

    private func startRecallFor(messageId: String) {
        let recalledThreadId = viewModel.threadId
        var shouldShowPopover = false
        MailRecallManager.shared.recall(for: messageId, in: recalledThreadId) { [weak self] (error) in
            if let error = error {
                let errorText: String
                if let errorCode = error.errorCode(), let recallError = MailRecallError(rawValue: errorCode) {
                    errorText = recallError.errorText
                    if recallError == .notInSentState {
                        InteractiveErrorRecorder.recordError(event: .recall_mail_fail_not_sent)
                    }
                    if recallError == .migrationDomain {
                        shouldShowPopover = true
                    }

                } else {
                    errorText = BundleI18n.MailSDK.Mail_Recall_FailDefault
                }
                guard let `self` = self else { return }
                
                if shouldShowPopover {
                    let alert = LarkAlertController()
                    var fromAddress = ""
                    if let messageItem = viewModel.mailItem?.getMessageItem(by: messageId) {
                        fromAddress = messageItem.message.from.address
                    } else {
                        MailLogger.info("[Mail_Recall_Optimiz] getMessageItem NOT FOUND")
                    }
                    alert.setTitle(text: BundleI18n.MailSDK.Mail_Recall_UnableRecall_Popover_Title)
                    alert.setContent(text: BundleI18n.MailSDK.Mail_Recall_UnableRecall_Popover_Desc(fromAddress))
                    alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_Recall_UnableRecall_Popover_Button)
                    navigator?.present(alert, from: self)
                } else {
                    MailRoundedHUD.showFailure(with: errorText, on: self.view)
                    MailMessageListController.logger.debug("MailRecall: Error: \(messageId) " + (error.localizedDescription))
                }
            } else {
                MailMessageListController.logger.debug("MailRecall: Succeed \(messageId)")
            }
        }
        updateRecallStateFor(messageId: messageId, in: viewModel.threadId)
    }

    private func updateNavBarItemTintColor() {
        guard fromLabel == Mail_LabelId_Outbox, accountContext.featureManager.open(.newOutbox) else { return }
        let isEnabled = viewModel.deliveryState == .sendError
        let tintColor: UIColor = isEnabled ? .ud.iconN1 : .ud.iconDisabled
        if let deleteButton = messageNavBar.rightItemsMap[.delete] {
            deleteButton.tintColor = tintColor
            deleteButton.isUserInteractionEnabled = isEnabled
        }
        if let editButton = messageNavBar.rightItemsMap[.edit] {
            editButton.tintColor = tintColor
            editButton.isUserInteractionEnabled = isEnabled
        }
    }

    private func showDeleteOutboxMailAlert(confirmCompletion: @escaping () -> Void) {
        guard accountContext.featureManager.open(.newOutbox) else {
            confirmCompletion()
            return
        }
        let alert = LarkAlertController()
        alert.setContent(text: BundleI18n.MailSDK.Mail_Outbox_DeleteEmailPermanentlyMobile, alignment: .center)
        alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_Outbox_GoBackMobile)
        alert.addDestructiveButton(text: BundleI18n.MailSDK.Mail_Outbox_DeleteMobile, dismissCompletion: confirmCompletion)
        navigator?.present(alert, from: self)
    }

    // MARK: - statices
    internal func statMoveAction(type: String, messageId: String?) {
        var params = ["type": type,
                      "threadid": viewModel.threadId,
                      "location": (messageId != nil) ? "message" : "threadtop",
                      "currentfilter": viewModel.labelId]
        if let messageId = messageId {
            params["messageid"] = messageId
        }
        MailTracker.log(event: Homeric.EMAIL_MOVE, params: params)
    }

    internal func statReadMessageAction(args: [String: Any], in webView: WKWebView?) {
        let params = ["threadid": viewModel.threadId,
                      "message": args["messageid"] ?? "",
                      "fromlabel": viewModel.labelId]
        MailTracker.log(event: Homeric.MAIL_MESSAGE_CLICK, params: params)
        if let is_expand = args["expand"] as? Bool {
            let event = is_expand ? Homeric.EMAIL_MESSAGE_EXPAND : Homeric.EMAIL_MESSAGE_COLLAPSE
            MailTracker.log(event: event, params: [:])

        }

        if let needContent = args["needContent"] as? Bool, needContent,
           let messageId = args["messageid"] as? String {
            callJs_addItemContent(msgIDs: [messageId])
        }
    }

    // MARK: helper
    var allMessageIds: [String] {
        return mailItem.messageItems.map({ (item) -> String in
            return item.message.id
        })
    }

    //// multi scene
    private func clickSceneButton(sender: UIButton) {
        if #available(iOS 13.0, *) {
            let scene = createCurrentSceneConfig()
            scene.userInfo["feedCardId"] = self.feedCardId
            scene.userInfo["feedCardAvatar"] = self.messageListFeedInfo?.avatar ?? ""
            scene.userInfo["threadId"] = self.viewModel.threadId
            scene.userInfo["messageId"] = self.viewModel.mailItem?.messageItems.first?.message.id
            scene.userInfo["labelId"] = self.viewModel.labelId
            scene.userInfo["statInfo"] = self.statInfo.from.rawValue
            scene.userInfo["cardId"] = self.realViewModel.forwardInfo?.cardId
            scene.userInfo["ownerId"] = self.realViewModel.forwardInfo?.ownerUserId
            // 持有callback, 避免scene回调前，self已经被释放，导致无法调用
            let tempBackCallback = backCallback
            SceneManager.shared.active(scene: scene, from: self) { [weak view] (_, error) in
                tempBackCallback?()
                if error != nil, let view = view {
                    MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_iPad_SplitScreenNotSupported,
                                               on: view)
                }
            }
        } else {
            assertionFailure()
        }
    }
    
    @objc 
    func tipsTaped() {
        // 调用函数开始递归循环请求至结束
        self.tipsBtn.showLoading()
        self.tipsLoadMoreHandler()
    }
    @objc
    func jumpToDraftList() {
        let vc = MailFeedDraftListViewController.init(feedCardId: self.feedCardId, accountContext: accountContext)
        self.accountContext.navigator.push(vc, from:self)
    }

    @objc
    private func closeScene(sender: UIButton) {
        if #available(iOS 13.0, *) {
            if let sceneInfo = self.currentScene()?.sceneInfo,
               !sceneInfo.isMainScene() {
                SceneManager.shared.deactive(from: self)
            }
        }
    }
    func closeChatModeScene() {
        guard Display.pad else { return }
        guard self.aiPageService != nil else { return }
        if #available(iOS 13.0, *) {
            for uiScene in UIApplication.shared.windowApplicationScenes {
                let scene = uiScene.sceneInfo
                if !scene.isMainScene() && scene.key == "MyAIChatMode" {
                    SceneManager.shared.deactive(scene: scene)
                    MailLogger.info("[MailChatMode] close chat mode scene")
                }
            }
        }
    }

    private func updateSceneTargetContentIdentifier() {
        sceneTargetContentIdentifier = createCurrentSceneConfig().targetContentIdentifier
    }
    
    private func markActiveMailPage() {
        MailSDKManager.markActiveMailPage().subscribe().disposed(by: disposeBag)
    }
    
    private func markInActiveMailPage() {
        MailSDKManager.markInActiveMailPage().subscribe().disposed(by: disposeBag)
    }

    private func createCurrentSceneConfig() -> LarkSceneManager.Scene {
        LarkSceneManager.Scene(
            key: "Mail",
            id: viewModel.threadId + statInfo.from.rawValue + viewModel.labelId,
            title: subject,
            sceneSourceID: currentSceneID(),
            windowType: "single",
            createWay: "window_click"
        )
    }

    private func fullScreenButtonClicked(sender: UIButton) {
        if let vc = self.larkSplitViewController {
            let isFullscreenMode = vc.splitMode == .secondaryOnly
            if isFullscreenMode {
                self.leaveFullScreenItemClicked(sender: sender)
            } else {
                self.enterFullScreenItemClicked(sender: sender)
            }
        }
    }

    func enterFullScreenItemClicked(sender: UIButton) {
        if let splitVC = larkSplitViewController {
            splitVC.updateSplitMode(.secondaryOnly, animated: true)
        }
        LarkSplitViewController.Tracker.trackFullScreenItemClick(
            scene: "mail", isFold: true
        )
    }

    func leaveFullScreenItemClicked(sender: UIButton) {
        if let splitVC = larkSplitViewController {
            splitVC.updateSplitMode(splitVC.beforeSecondaryOnlySplitMode, animated: true)
        }
        LarkSplitViewController.Tracker.trackFullScreenItemClick(
            scene: "mail", isFold: false
        )
    }

    func setNavBarHidden(_ isHidden: Bool, animated: Bool) {
        guard fromLabel != Mail_LabelId_Stranger && accountContext.featureManager.open(.stranger, openInMailClient: false) else { return }
        messageNavBar.setNavBarHidden(isHidden, animated: animated)
    }

    func showSuccessToast(_ toast: String) {
        MailRoundedHUD.showSuccess(with: toast, on: view)
    }

    func showFailToast(_ toast: String) {
        MailRoundedHUD.showFailure(with: toast, on: view)
    }

    func updateFromLabel(_ newLabel: String) {
        fromLabel = newLabel
    }

    func handleContextMenuAction(type: MailContextActionItemType, threadID: String, msgID: String, subject: String, labelId: String) {
        let handleTrack: (() -> Void) = { [weak self] in
            guard let self = self else { return }
            var mailShowType = ""
            if self.isFeedCard {
                mailShowType = "im_feed"
            } else if self.statInfo.from == .bot {
                mailShowType = "mail_bot_window"
            }
            let event = NewCoreEvent(event: .email_message_list_click)
            event.params = ["click": "message_action",
                            "target": "none",
                            "label_item": self.statInfo.newCoreEventLabelItem,
                            "is_trash_or_spam_list": self.statInfo.isTrashOrSpamList,
                            "action_type": type.coreEventName,
                            "mail_display_type": Store.settingData.threadDisplayType(),
                            "mail_show_type": mailShowType]
            event.post()
        }
        switch type {
        case .cancelScheduleSend:
            handleCancelScheduleSendClick(args: ["messageID": msgID], in: nil, source: "message_action")
        case .turnOffTranslation:
            dismissTranslation(messageId: msgID)
        case .translate:
            translateClick(args: ["messageID": msgID], in: nil)
        case .reply:
            reply(replyMsgID: msgID, isFromFootBtn: false)
        case .replyAll:
            replyAll(replyMsgID: msgID, isFromFootBtn: false)
        case .forward:
            forward(replyMsgID: msgID, isFromFootBtn: false)
        case .reEdit:
            reEdit(threadID: threadID, msgID: msgID)
        case .recall:
            Store.settingData.storageLimitCheck(from: self, navigator: accountContext.navigator) { [weak self] in
                self?.handleRecall(messageId: msgID)
            }
        case .forwardToChat:
            Store.settingData.storageLimitCheck(from: self, navigator: accountContext.navigator) { [weak self] in
                self?.handleMenuClickShareToIm(messageId: msgID)
            }
        case .unsubscribe:
            handleUnsubscribe(messageId: msgID, trackHandler: handleTrack)
        case .trashMessage:
            deleteMessage(msgID: msgID, isPermanently: false, trackHandler: nil)
        case .deleteMessagePermanently:
            deleteMessage(msgID: msgID, isPermanently: true, trackHandler: handleTrack)
        case .emlAsAttachment:
            emlAsAttachmentForSingleMessage(msgID: msgID, subject: subject)
        case .blockSender:
            handleBlockSenderClick(msgId: msgID)
        case .revertScale:
            callJSFunction("userRevertScale", params: [msgID])
        case .jumpToThread:
            jumpToThread(threadID: threadID, msgID: msgID, labelID: labelId)
        }

        if !type.handleTrackOnAlert {
            // 不需要二次确认，直接上报埋点
            handleTrack()
        }
    }
    
    private func jumpToThread(threadID: String, msgID: String, labelID: String) {
        // 区分会话模式与非会话模式，会话模式需要threadID & messageID， 非会话模式只需要messageID，threadID用messageID替换
        let threadID = Store.settingData.getCachedCurrentSetting()?.enableConversationMode == true ? threadID : msgID
        let vc = MailMessageListController.makeForRouter(accountContext: self.accountContext,
                                                         threadId: threadID,
                                                         labelId: labelID,
                                                         messageId: msgID,
                                                         statInfo: MessageListStatInfo(from: .other, newCoreEventLabelItem: labelID),
                                                         forwardInfo: nil)
        self.accountContext.navigator.push(vc, from:self)
    }

    private func deleteMessage(msgID: String, isPermanently: Bool, trackHandler: (() -> Void)?) {
        var trashMessageIds = [msgID]
        MailLogger.info("deleteMsg \(msgID), isPer \(isPermanently)")
        if let messageItem = viewModel.mailItem?.getMessageItem(by: msgID) {
            for draft in messageItem.drafts {
                trashMessageIds.append(draft.id)
                MailLogger.info("deleteDraft \(msgID), isPer \(isPermanently)")
            }
        }
        if let scheduleMessageIds = viewModel.mailItem?.messageItems
            .filter({ $0.message.scheduleSendTimestamp > 0 && $0.message.replyMessageID == msgID })
            .map({ $0.message.id }) {
            trashMessageIds.append(contentsOf: scheduleMessageIds)
            MailLogger.info("DeleteSchedule \(msgID), isPer \(isPermanently)")
        }
        MailLogger.info("deleteMessage: \(trashMessageIds) t_id: \(self.viewModel.threadId),isPer \(isPermanently)")
        if isPermanently {
            deleteMessagePermanently(trashMessageIds: trashMessageIds, trackHandler: trackHandler)
        } else {
            // 最后一封邮件被删掉时需要弹 toast
            var needShowToast = false
            if (accountContext.featureManager.open(FeatureKey(fgKey: .openBotDirectly, openInMailClient: false)) || Store.settingData.mailClient),
               let messageItems = self.viewModel.mailItem?.messageItems, messageItems.count == 1 {
                needShowToast = true
            }
            // 区分feed情况 回传threadId
            let feedMessageItemThreadID = self.mailItem.feedMessageItems.first(where: { $0.item.message.id == msgID})?.threadID ?? ""
            let feedLabels = self.mailItem.feedMessageItems.first(where: { $0.item.message.id == msgID})?.labelIds ?? []
            let threadId = self.isFeedCard ? feedMessageItemThreadID : viewModel.threadId
            let label = self.isFeedCard && !feedLabels.isEmpty ? feedLabels[0] : fromLabel
            let feedCardId = self.isFeedCard ? self.feedCardId : nil
            Store.trashMessage(messageIds: trashMessageIds, threadID: threadId, fromLabelID: label, feedCardId: feedCardId) { [weak self ] in
                guard let self = self else { return }
                if needShowToast {
                    ActionToast.showSuccessToast(with: BundleI18n.MailSDK.Mail_ThreadAction_TrashToast, on: self.view)
                }
            }
        }
    }

    private func deleteMessagePermanentlyFromAppLink(trashMessageIds: [String], trackHandler: (() -> Void)?, isAllowAllLabels: Bool = false) {
        let alert = LarkAlertController()
        alert.setContent(text: BundleI18n.MailSDK.Mail_ThreadAction_DeleteForeverConfirm, alignment: .center)
        alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_Alert_Cancel)
        alert.addDestructiveButton(text: BundleI18n.MailSDK.Mail_Alert_Delete, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            Store.fetcher?.deletePermanently(labelID: self.viewModel.labelId,
                                            threadIDs: [self.viewModel.threadId],
                                            messageIds: trashMessageIds,
                                            isAllowAllLabels: isAllowAllLabels)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                trackHandler?()
                MailLogger.info("deleteMessage suc: \(trashMessageIds) t_id: \(self.viewModel.threadId)")
                let viewController = WindowTopMostFrom(vc: self)
                self.backItemTapped() {
                    if let view = viewController.fromViewController?.view {
                        MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_Toast_DeleteThreadsSuccess, on: view)
                    }
                }
            }, onError: { [weak self] error in
                guard let self = self else { return }
                MailLogger.error("deleteMessage error: \(trashMessageIds) t_id: \(self.viewModel.threadId), \(error)")
                MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Toast_OperationFailed, on: self.view,
                                           event: ToastErrorEvent(event: .message_delete_forever_fail,
                                                                  scene: .messagelist))
            }).disposed(by: self.disposeBag)
        })
        navigator?.present(alert, from: self)
    }

    private func deleteMessagePermanently(trashMessageIds: [String], trackHandler: (() -> Void)?) {
        let alert = LarkAlertController()
        alert.setContent(text: BundleI18n.MailSDK.Mail_ThreadAction_DeleteForeverConfirm, alignment: .center)
        alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_Alert_Cancel)
        alert.addDestructiveButton(text: BundleI18n.MailSDK.Mail_Alert_Delete, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            Store.fetcher?.deletePermanently(labelID: self.fromLabel,
                                            threadIDs: [self.viewModel.threadId],
                                            messageIds: trashMessageIds).subscribe(onNext: { [weak self] res in
                guard let self = self else { return }
                trackHandler?()
                MailLogger.info("deleteMessage suc: \(trashMessageIds) t_id: \(self.viewModel.threadId)")
                let viewController = WindowTopMostFrom(vc: self)
                self.backItemTapped() {
                    if let view = viewController.fromViewController?.view {
                        MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_Toast_DeleteThreadsSuccess, on: view)
                    }
                }
            }, onError: { [weak self] e in
                guard let self = self else { return }
                MailLogger.error("deleteMessage error: \(trashMessageIds) t_id: \(self.viewModel.threadId), \(e)")
                MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Toast_OperationFailed, on: self.view,
                                           event: ToastErrorEvent(event: .message_delete_forever_fail,
                                                                  scene: .messagelist))
            }).disposed(by: self.disposeBag)
        })
        navigator?.present(alert, from: self)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        _collectionView(collectionView, numberOfItemsInSection: section)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        _collectionView(collectionView, cellForItemAt: indexPath)
    }
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        _collectionView(collectionView, willDisplay: cell, forItemAt: indexPath)
    }
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        _collectionView(collectionView, didEndDisplaying: cell, forItemAt: indexPath)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        _collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: indexPath)
    }
    func collectionView(_ collectionView: UICollectionView, targetContentOffsetForProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        _collectionView(collectionView, targetContentOffsetForProposedContentOffset: proposedContentOffset)
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        _scrollViewDidScroll(scrollView)
    }
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        _scrollViewWillBeginDragging(scrollView)
    }
    func scrollViewEndScroll(_ scrollView: UIScrollView) {
        _scrollViewEndScroll(scrollView)
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        _scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        _scrollViewDidEndDecelerating(scrollView)
    }

    /// js 中点击头条回调.
    /// 放在 class 中方便子类复写.
    func onAvatarClicked(args: [String: Any], in webView: WKWebView?) {
        handlePersonalInfoClick(args: args, in: webView)
    }

    /// js 中点击用户地址回调.
    /// 放在 class 中方便子类复写.
    func onAddressClicked(args: [String: Any], in webView: WKWebView?) {
        handlePersonalInfoClick(args: args, in: webView)
    }
}

extension MailContextActionItemType {
    var title: String {
        switch self {
        case .cancelScheduleSend:
            return BundleI18n.MailSDK.Mail_SendLater_CancelSend
        case .turnOffTranslation:
            return BundleI18n.MailSDK.Mail_Translations_Turnofftranslation
        case .translate:
            return BundleI18n.MailSDK.Mail_Translations_Translate
        case .reply:
            return BundleI18n.MailSDK.Mail_Normal_Reply
        case .replyAll:
            return BundleI18n.MailSDK.Mail_Compose_Template_ReplyAll
        case .forward:
            return BundleI18n.MailSDK.Mail_Normal_Forward
        case .reEdit:
            return BundleI18n.MailSDK.Mail_Edit_ReEdit
        case .recall:
            return BundleI18n.MailSDK.Mail_Recall_Action
        case .forwardToChat:
            return BundleI18n.MailSDK.Mail_SharetoChat_MenuItem
        case .unsubscribe:
            return BundleI18n.MailSDK.Mail_Unsubscribe_Name
        case .trashMessage:
            return BundleI18n.MailSDK.Mail_ThreadAction_Delete
        case .deleteMessagePermanently:
            return BundleI18n.MailSDK.Mail_DeletePermanently_MenuItem
        case .emlAsAttachment:
            return BundleI18n.MailSDK.Mail_MailAttachment_SendAsAttachment
        case .blockSender:
            return BundleI18n.MailSDK.Mail_BlockTrust_MenuItem
        case .revertScale:
            return BundleI18n.MailSDK.Mail_Read_RevertAutoSizing_Mobile_Button
        case .jumpToThread:
            return BundleI18n.MailSDK.Mail_KeyContact_ViewConversationThread_MenuItem
        }
    }

    var icon: UIImage {
        switch self {
        case .cancelScheduleSend:
            return Resources.mail_action_sent_cancel.withRenderingMode(.alwaysTemplate)
        case .turnOffTranslation, .translate:
            return Resources.mail_action_translate.withRenderingMode(.alwaysTemplate)
        case .reply:
            return Resources.mail_action_reply.withRenderingMode(.alwaysTemplate)
        case .replyAll:
            return Resources.mail_action_replyall.withRenderingMode(.alwaysTemplate)
        case .forward:
            return Resources.mail_action_forward.withRenderingMode(.alwaysTemplate)
        case .reEdit:
            return Resources.mail_action_reedit.withRenderingMode(.alwaysTemplate)
        case .recall:
            return Resources.mail_action_recall.withRenderingMode(.alwaysTemplate)
        case .forwardToChat:
            return UDIcon.shareOutlined.withRenderingMode(.alwaysTemplate)
        case .unsubscribe:
            return Resources.mail_action_unsubscribe.withRenderingMode(.alwaysTemplate)
        case .trashMessage:
            return UDIcon.deleteTrashOutlined.withRenderingMode(.alwaysTemplate)
        case .deleteMessagePermanently:
            return UDIcon.deleteTrashOutlined.withRenderingMode(.alwaysTemplate)
        case .emlAsAttachment:
            return UDIcon.attachmentOutlined.withRenderingMode(.alwaysTemplate)
        case .blockSender:
            return UDIcon.blockSenderOutlined.withRenderingMode(.alwaysTemplate)
        case .revertScale:
            return Resources.mail_action_revert_zoom.withRenderingMode(.alwaysTemplate)
        case .jumpToThread:
            return UDIcon.viewinchatOutlined.withRenderingMode(.alwaysTemplate)
        }
    }
}

extension MailMessageListController {
    func onCurrentWebViewDisappear() {
        guard let currentPage = currentPageCell,
              let messageView = currentPage.mailMessageListView
        else {
            MailLogger.error("Failed to get current message list view")
            return
        }
        callJSFunction("onWebViewDisappear", params: [], in: messageView.webview)
    }
    func currentWebViewWillChange() {
        self.atAddressNameMap.removeAll()
        self.atUpdateAddressNameMap.removeAll()
    }
}

extension MailMessageListController {
    func enterSendStatusVC(messageId: String, threadId: String, labelId: String) {
        let sendStatusVC = MailSendStatusController(accountContext: accountContext,
                                                    messageId: messageId,
                                                    threadId: threadId,
                                                    labelId: labelId)
        navigator?.push(sendStatusVC, from: self)
    }
}

extension MailMessageListController {
    func handleAtInfos(infos: [Any]) {
        guard !infos.isEmpty else { return }
        guard self.addressNameFg else { return }
        var observables: [Observable<(list: [MailSendAddressModel], isRemote: Bool)>] = []
        var itemList: [AddressRequestItem] = []
        for info in infos {
            if let dic = info as? [String: String] {
                if let address = dic["address"],
                   let name = dic["name"],
                   !name.isEmpty {
                    if atAddressNameMap[address] != nil {
                        continue
                    }
                    atAddressNameMap[address] = name
                    var item = AddressRequestItem()
                    item.address = address
                    itemList.append(item)
                    if MailMessageListViewsPool.fpsOpt {
                        if self.atUidAddressCheck[address] == nil {
                            let observable = searchProvider.recommandListWith(key: address, groupEmailAccount: nil)
                            observables.append(observable)
                        }
                    } else {
                        let observable = searchProvider.recommandListWith(key: address, groupEmailAccount: nil)
                        observables.append(observable)
                    }
                }
            }
        }
        atFetchAddressName(itemList: itemList)
        if observables.count > 0 {
            Observable.concat(observables)
            .subscribe(onNext: { [weak self] (model) in
                guard let `self` = self else { return }
                if let item = model.0.first,
                    let id = item.larkID,
                    !id.isEmpty,
                    id != "0",
                    !item.address.isEmpty {
                    self.atUidAddressMap[id] = item.address
                    self.atUidAddressCheck[item.address] = id
                }
            }).disposed(by: disposeBag)
        }
    }

    private func atFetchAddressName(itemList: [AddressRequestItem]) {
        if itemList.count <= 0 { return }
        let messages = self.mailItem.messageItems
        MailDataServiceFactory.commonDataService?.getMailAddressNamesAsync(addressList: itemList).subscribe( onNext: { [weak self]  MailAddressNameResponse in
            guard let `self` = self else { return }
            var dic:[String: String] = [:]
            for respItem in MailAddressNameResponse.addressNameList {
                if !respItem.address.isEmpty &&
                    !respItem.name.isEmpty &&
                    !MailAddressChangeManager.shared.noUpdate(type: respItem.addressType) {
                    dic[respItem.address] = respItem.name
                    self.atUpdateAddressNameMap[respItem.address] = respItem.name
                }
            }
            if !dic.isEmpty {
                for message in self.mailItem.messageItems {
                    if !message.isFromMe {
                        self.replaceAtName(messageId: message.message.id,
                                           dic: dic)
                    }
                }
            }
            }, onError: { (error) in
                MailLogger.error("at getAddressNames resp error \(error)")
            }).disposed(by: disposeBag)
    }

    func expandMessage(ids: [String]) {
        guard self.addressNameFg else { return }
        for message in self.mailItem.messageItems {
            if ids.contains(message.message.id) {
                if !message.isFromMe {
                    // 展开后更新at人区域
                    self.replaceAtName(messageId: message.message.id,
                                       dic: self.atUpdateAddressNameMap.getImmutableCopy())
                }
            }
        }
    }

    func handleAddressChange() {
        guard self.addressNameFg else { return }
        MailLogger.info("MailMessageList handleAddressChange")
        let copyItems = mailItem.messageItems
        let forceDisplayBcc = mailItem.shouldForceDisplayBcc
        self.addressChangeQueue.async { [weak self] in
            guard let `self` = self else { return }
            for message in copyItems {
                // 更新头部title区域
                // 非自己的地址才需要更新
                if !message.isFromMe {
                    let fromAddress = message.message.from.address
                    let entityId = message.message.from.larkEntityID
                    if let newName = MailAddressChangeManager.shared.uidNameMap[String(entityId)] {
                        self.replaceHeaderFrom(messageId: message.message.id, fromName: newName)
                    } else if let newName = MailAddressChangeManager.shared.addressNameMap[fromAddress] {
                        self.replaceHeaderFrom(messageId: message.message.id, fromName: newName)
                    }
                }
                // 更新头部to区域
                let addressList = message.message.to + message.message.cc
                var needUpdateTo = false
                for address in addressList {
                    if let newName = MailAddressChangeManager.shared.uidNameMap[String(address.larkEntityID)] {
                        needUpdateTo = true
                        break
                    } else if let newName = MailAddressChangeManager.shared.addressNameMap[address.address] {
                        needUpdateTo = true
                        break
                    }
                }
                if needUpdateTo {
                    let toListStr = self.realViewModel.templateRender.replaceForToNames(mail: message,
                                                             shouldForceDisplayBcc: forceDisplayBcc, needReplaceName: true)
                    self.replaceHeaderTo(messageId: message.message.id, toList: toListStr)
                }

                if !message.isFromMe {
                    let id = message.message.from.larkEntityID
                    let address = message.message.from.address
                    var fromDic: [String: String] = [:]
                    if let newName = MailAddressChangeManager.shared.uidNameMap[String(id)] {
                        fromDic[address] = newName
                    } else if let newName = MailAddressChangeManager.shared.addressNameMap[address] {
                        fromDic[address] = newName
                    }
                    if !fromDic.isEmpty {
                        // 更新地址区域From区域
                        self.replaceAddressName(messageId: message.message.id,
                                           dic: fromDic,
                                           type: BundleI18n.MailSDK.Mail_Normal_From.htmlEncoded)
                    }

                }
                if !message.isFromMe {
                    // 更新at人区域
                    var atDic: [String: String] = [:]
                    for (uid, address) in self.atUidAddressMap.getImmutableCopy() {
                        if let newName = MailAddressChangeManager.shared.uidNameMap[uid],
                            !newName.isEmpty {
                            atDic[address] = newName
                            self.atUpdateAddressNameMap[address] = newName
                        } else if let newName = MailAddressChangeManager.shared.addressNameMap[address],
                                  !newName.isEmpty {
                            atDic[address] = newName
                            self.atUpdateAddressNameMap[address] = newName
                        }
                    }
                    for (address, name) in self.atAddressNameMap.getImmutableCopy() {
                        if let newName = MailAddressChangeManager.shared.addressNameMap[address], !newName.isEmpty {
                            atDic[address] = newName
                            self.atUpdateAddressNameMap[address] = newName
                        }
                    }
                    if !atDic.isEmpty {
                        self.replaceAtName(messageId: message.message.id,
                                      dic: atDic)
                    }
                }

                let addressDic = MailAddressChangeManager.shared.addressNameMap.getImmutableCopy()
                let uidDic = MailAddressChangeManager.shared.uidNameMap.getImmutableCopy()
                var uidAddressArray: [MailUidAddressItem] = []
                let addresses = message.message.to + message.message.bcc + message.message.cc
                for address in addresses {
                    uidAddressArray.append(MailUidAddressItem(uid: address.larkEntityIDString, address: address.address))
                }
                var updateDic: [String: String] = [:]
                for item in uidAddressArray where !item.address.isEmpty {
                    if let newName = uidDic[item.uid] {
                        updateDic[item.address] = newName
                    } else if let newName = addressDic[item.address] {
                        updateDic[item.address] = newName
                    }
                }

                if !self.accountContext.featureManager.open(.ignoreMe) {
                    // 拼接Me逻辑
                    let selfAddresses = Store.settingData.getCachedCurrentAccount()?.mailSetting.emailAlias.allAddresses ?? []
                    for address in selfAddresses where updateDic[address.address] != nil {
                        updateDic[address.address] = BundleI18n.MailSDK.Mail_ThreadList_Me
                    }
                }
                if !updateDic.isEmpty {
                    // 更新地址区域To区域
                    self.replaceAddressName(messageId: message.message.id,
                                       dic: updateDic,
                                       type: BundleI18n.MailSDK.Mail_Normal_To_Title.htmlEncoded)
                    // 更新地址区域CC区域
                    self.replaceAddressName(messageId: message.message.id,
                                       dic: updateDic,
                                       type: BundleI18n.MailSDK.Mail_Normal_Cc.htmlEncoded)
                    // 更新地址区域BCC区域
                    self.replaceAddressName(messageId: message.message.id,
                                       dic: updateDic,
                                       type: BundleI18n.MailSDK.Mail_Normal_Bcc.htmlEncoded)
                }
            }
        }
    }

    func handleSettingChanged(setting: MailSetting) {
        if setting.webImageDisplay && fromLabel != Mail_LabelId_Spam {
            self.callJSFunction("showInterceptedImages", params: [""], withThreadId: nil)
        }
    }
}

extension MailMessageListController {
    func checkGuideShouldShow() {
        DispatchQueue.global().async { [weak self] in
            self?.canShowGuide[.topAttachmentGuide] = {
                guard self?.accountContext.featureManager.open(.attachmentLocation, openInMailClient: true) == true else { return false }
                let guideKey = "all_email_attachments_above_text"
                guard self?.accountContext.provider.guideServiceProvider?.guideService?.checkShouldShowGuide(key: guideKey) == true else { return false }
                return true
            }()
            self?.canShowGuide[.darkModeGuide] = {
                guard self?.accountContext.featureManager.open(FeatureKey(fgKey: .darkMode, openInMailClient: true)) == true else { return false }
                guard #available(iOS 13.0, *), UDThemeManager.getRealUserInterfaceStyle() == .dark else { return false }
                let guideKey = "mobile_darmode_switch"
                guard self?.accountContext.provider.guideServiceProvider?.guideService?.checkShouldShowGuide(key: guideKey) == true else { return false }
                return true
            }()
        }
    }
}

extension MailMessageListController {
    func showDarkModeGuideIfNeeded() {
        guard canShowGuide[.darkModeGuide] == true else { return }
        let guideKey = "mobile_darmode_switch"

        let kvStore = MailKVStore(space: .global, mSpace: .global)
        var isContentAlwaysLight = kvStore.value(forKey: "mail_contentSwitch_isLight") ?? false

        guard let targetView = messageNavBar.rightItemsMap[.more] else { return }

        let targetAnchor = TargetAnchor(targetSourceType: .targetView(targetView))
        let rightButtonInfo = ButtonInfo(title: "", skipTitle: BundleI18n.MailSDK.Mail_Onboarding_SwitchBetweenDarkAndLightModeGotIt_Button, buttonType: .close)
        let textConfig = TextInfoConfig(title: BundleI18n.MailSDK.Mail_Onboarding_SwitchBetweenDarkAndLightMode_Title,
                                        detail: !isContentAlwaysLight
                                        ? BundleI18n.MailSDK.Mail_Onboarding_FromDarkToLight_Mobile_Desc
                                        : BundleI18n.MailSDK.Mail_Onboarding_FromLightToDark_Mobile_Desc)
        let bottomConfig = BottomConfig(leftBtnInfo: nil, rightBtnInfo: rightButtonInfo, leftText: nil)
        let itemConfig = BubbleItemConfig(guideAnchor: targetAnchor, textConfig: textConfig, bottomConfig: bottomConfig)
        let maskConfig = MaskConfig(shadowAlpha: 0, windowBackgroundColor: .clear)
        let bubbleConfig = SingleBubbleConfig(bubbleConfig: itemConfig, maskConfig: maskConfig)
        accountContext.provider.guideServiceProvider?.guideService?.showBubbleGuideIfNeeded(guideKey: guideKey,
                                                                                            bubbleType: .single(bubbleConfig),
                                                                                            dismissHandler: nil)
        self.canShowGuide[.darkModeGuide] = false

    }
}

extension MailMessageListController: GuideCustomViewDelegate, MailTopAttachmentGuideViewDelegate {
    func didCloseView(customView: LarkGuideUI.GuideCustomView) {}

    func didTopAttachmentClickSkip() {
        let location = Store.settingData.getCachedPrimaryAccount()?.mailSetting.attachmentLocation
        MailTracker.log(event: "email_attachment_position_onboard_click",
                        params: ["click": "cancel",
                                 "target": "none",
                                 "attachment_position": location == .top ? "message_top" : "message_bottom",
                                 "label_item": statInfo.newCoreEventLabelItem])
    }

    func didTopAttachmentClickConfirm(location: MailAttachmentLocation) {
        MailTracker.log(event: "email_attachment_position_onboard_click",
                        params: ["click": "confirm",
                                 "target": "none",
                                 "attachment_position": location == .top ? "message_top" : "message_bottom",
                                 "label_item": statInfo.newCoreEventLabelItem])
        if var primaryAccount = Store.settingData.getCachedPrimaryAccount(),
           location != primaryAccount.mailSetting.attachmentLocation {
            Store.settingData.updateSettings(.attachmentLocation(location), of: &primaryAccount, onSuccess: { [weak self] in
                guard let `self` = self else { return }
                // 需要马上得到更新后的setting，强制拉取一下账号setting数据
                _ = Store.settingData.getPrimaryAccount().subscribe { [weak self] _ in
                    guard let `self` = self else { return }
                    MailMessageListViewsPool.reset() // 预加载的读信页都要重新加载
                    self.currentPageCell?.isDomReady = false
                    var threadIds: [String] = [self.viewModel.threadId]
                    if let viewModel = self.realViewModel[self.currentPageIndex - 1] {
                        threadIds.append(viewModel.threadId)
                    }
                    if let viewModel = self.realViewModel[self.currentPageIndex + 1] {
                        threadIds.append(viewModel.threadId)
                    }
                    self.resetMailItemForReload(threadIDs: threadIds)
                } onError: { err in
                    MailLogger.error("Mail getPrimaryAccount error: \(err)")
                }.disposed(by: self.disposeBag)
            })
        }
    }

    func showTopAttachmentGuideIfNeeded(messageIDs: [String]) {
        // 附件置顶 Onboard 出现条件
        // 1.FG开 2.Onboard 没展示过 3.当前读信页展开的邮件有附件 4.用户从来没用过「附件置顶」
        guard canShowGuide[.topAttachmentGuide] == true else { return }
        guard viewModel.mailItem?.messageItems.contains(where: { messageIDs.contains($0.message.id) && $0.message.attachments.count > 0 }) == true else { return }
        guard let setting = Store.settingData.getCachedPrimaryAccount()?.mailSetting, setting.attachmentLocation == .bottom else {
            // 已经通过设置用过附件置顶的用户，后面改回来也不用再出 onboard，这里直接把 onboard 设置成已展示
            let guideKey = "all_email_attachments_above_text"
            accountContext.provider.guideServiceProvider?.guideService?.didShowedGuide(guideKey: guideKey)
            return
        }
        showTopAttachmentGuide()
    }

    private func showTopAttachmentGuide() {
        let guideKey = "all_email_attachments_above_text"
        let customView = MailTopAttachmentGuideView(delegate: self, topAttachmentGuideDelegate: self)
        if let window = currentWindow() {
            let x = (window.frame.width - customView.intrinsicContentSize.width) / 2.0
            let y = (window.frame.height - customView.intrinsicContentSize.height) / 2.0
            let frame = CGRect(x: x,
                               y: y,
                               width: customView.intrinsicContentSize.width,
                               height: customView.intrinsicContentSize.height)
            let customConfig = GuideCustomConfig(customView: customView,
                                                 viewFrame: frame,
                                                 delegate: self,
                                                 enableBackgroundTap: false)
            accountContext.provider.guideServiceProvider?.guideService?.showCustomGuideIfNeeded(guideKey: guideKey,
                                                                                                customConfig: customConfig,
                                                                                                dismissHandler: { [weak self] in
                self?.accountContext.provider.guideServiceProvider?.guideService?.didShowedGuide(guideKey: guideKey)
                self?.isTopAttachmentGuideShowing = false
            })
            self.canShowGuide[.topAttachmentGuide] = false
            self.isTopAttachmentGuideShowing = true
        }
    }

    private func closeTopAttachmentGuideIfNeeded() {
        if isTopAttachmentGuideShowing {
            let guideKey = "all_email_attachments_above_text"
            // 关掉之后会消费掉 onboardkey，需要重新置为可显示，此时远端 onboardkey 已被消费
            accountContext.provider.guideServiceProvider?.guideService?.closeCurrentGuideUIIfNeeded()
            accountContext.provider.guideServiceProvider?.guideService?.setGuideInfoOfLocalCache(guideKey: guideKey, canShow: true)
            self.isTopAttachmentGuideShowing = true
        }
    }

    // 由于 CustomGuideView 目前无法处理iPad旋转的适配，采用先关闭后重新显示的方案
    private func updateTopAttachmentGuideFrame() {
        if isTopAttachmentGuideShowing {
            showTopAttachmentGuide()
        }
    }
    
    func makeSendMailButton() -> UIButton {
        let sendMailButton = MailCreateDraftButton(frame: CGRect(origin: .zero, size: CGSize(width: 48, height: 48)))
        sendMailButton.delegate = self
        if self.accountContext.mailAccount?.isUnuse() == true {
            sendMailButton.isHidden = true
        }
        return sendMailButton
    }
    
    func makeDraftListBtn() -> UDButton {
        let normalColor = UniverseDesignButton.UDButtonUIConifg.ThemeColor(borderColor: UDColor.lineBorderCard, backgroundColor: UDColor.bgFloat, textColor: UDColor.textTitle)
        let pressedColor = UniverseDesignButton.UDButtonUIConifg.ThemeColor(borderColor: UDColor.lineBorderCard, backgroundColor: UDColor.N200, textColor: UDColor.textTitle)
        var btnConfig: UDButtonUIConifg = UDButtonUIConifg(normalColor: normalColor,
                                                           pressedColor: pressedColor,
                                                           radiusStyle: .circle)
        let button = UDButton()
        let textWidth = BundleI18n.MailSDK.Mail_Normal_Draft.getTextWidth(font: UDFont.headline, height: 20)
        btnConfig.type = .custom(from: .big, size: CGSize(width: textWidth + 20 + 16*2 + 6, height: 48), inset:16, font: UDFont.headline, iconSize: CGSize(width: 20, height: 20))
        button.config = btnConfig
        button.setImage(UDIcon.getIconByKey(UDIconType.editContinueOutlined).ud.withTintColor(UDColor.functionDangerContentDefault), for: .normal)
        button.setImage(UDIcon.getIconByKey(UDIconType.editContinueOutlined).ud.withTintColor(UDColor.functionDangerContentDefault), for: .highlighted)
        button.addTarget(self, action: #selector(jumpToDraftList), for: .touchUpInside)
        button.setTitle(BundleI18n.MailSDK.Mail_Normal_Draft, for: .normal)
        let spacing: CGFloat = 6
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: spacing/2, bottom: 0, right: -spacing/2)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -spacing/2, bottom: 0, right: spacing/2)
        button.isHidden = true
        button.layer.borderWidth = 0.5
        button.layer.masksToBounds = true
        button.clipsToBounds = false
        button.layer.ud.setShadow(type: .s4Down)
        return button
    }
    
    func makeTipsBtn() -> UDButton {
        let normalColor = UniverseDesignButton.UDButtonUIConifg.ThemeColor(borderColor: UDColor.lineBorderCard, backgroundColor: UDColor.bgFloat, textColor: UDColor.primaryContentDefault)
        let pressedColor = UniverseDesignButton.UDButtonUIConifg.ThemeColor(borderColor: UDColor.lineBorderCard, backgroundColor: UDColor.N200, textColor: UDColor.primaryContentDefault)
        let loadingColor = UniverseDesignButton.UDButtonUIConifg.ThemeColor(borderColor: UDColor.lineBorderCard, backgroundColor: UDColor.bgFloat, textColor: UDColor.primaryContentLoading)
        var btnConfig: UDButtonUIConifg = UDButtonUIConifg(normalColor: normalColor,
                                                           pressedColor: pressedColor,
                                                           loadingColor: loadingColor,
                                                          loadingIconColor: UDColor.primaryContentDefault,
                                                           radiusStyle: .circle)
        let button = UDButton()
        btnConfig.type = .custom(from: .big, size: CGSize(width: 111, height: 40), inset:12, font: UDFont.body1, iconSize: CGSize(width: 16, height: 16))
        button.config = btnConfig
        button.setImage(UDIcon.getIconByKey(UDIconType.downBottomOutlined).ud.withTintColor(UDColor.primaryContentDefault), for: .normal)
        button.addTarget(self, action: #selector(tipsTaped), for: .touchUpInside)
        button.isHidden = true
        button.layer.borderWidth = 0.5
        button.layer.masksToBounds = true
        button.clipsToBounds = false
        button.layer.ud.setShadow(type: .s4Down)
        return button
    }
    
    func createNewMail() {
        if Store.settingData.mailClient {
            Store.settingData.mailClientExpiredCheck(
                accountContext: accountContext,
                from: self
            ) { [weak self] in
                self?.createDraft()
            }
        } else {
            createDraft()
        }
    }

    func createDraft() {
        let address = self.messageListFeedInfo?.address ?? ""
        if let vc = MailSendController.checkMailTab_makeSendNavController(accountContext: self.accountContext,
              action: .fromAddress,
              labelId: Mail_LabelId_Inbox,
              statInfo: MailSendStatInfo(from: .messageHandleAt, newCoreEventLabelItem: "none"),
              trackerSourceType: .mailTo,
              sendToAddress: address,
              feedCardId: self.feedCardId) {
            self.navigator?.present(vc, from: self)
        }
        
        // 业务统计
        MailTracker.log(event: Homeric.EMAIL_EDIT, params: ["type": "compose"])

        // core event
        let event = NewCoreEvent(event: .email_new_mail_click)
        event.params = ["click": "create_new_email",
                        "target": "email_email_edit_view",
                        "mail_service_type": Store.settingData.getMailAccountListType()]
        event.post()
    }
}
extension MailMessageListController: BlockSenderDelegate {
    func addBlockSuccess(isAllow: Bool, num: Int) {
        let text = isAllow ? BundleI18n.MailSDK.Mail_TrustSender_SenderTrusted_Toast(num) : BundleI18n.MailSDK.Mail_BlockSender_SenderBlocked_Toast(num)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeIntvl.normal) {
            MailRoundedHUD.showSuccess(with: text, on: self.view)
        }
    }
}

// ai相关逻辑
extension MailMessageListController: MyAIChatModeConfigDelegate {
    func shouldInteractWithURL(_ url: URL) -> Bool {
        return true
    }
    func openChatAI(checkAlert: Bool = false) -> Bool {
        let enable = accountContext.provider.myAIServiceProvider?.isAIEnable ?? false
        let mainFg = accountContext.featureManager.open(FeatureKey(fgKey: .larkAI, openInMailClient: false))
        let chatFg = accountContext.featureManager.open(FeatureKey(fgKey: .ChatAI, openInMailClient: false))
        let open = mainFg && chatFg && enable
        if checkAlert {
            var beforeOpen = accountContext.accountKVStore.bool(forKey: UserDefaultKeys.mailAIChatOpen)
            if open != beforeOpen {
                accountContext.accountKVStore.set(open, forKey: UserDefaultKeys.mailAIChatOpen)
            }
            if beforeOpen && !open && (!chatFg || !mainFg) {
                // 以前是开着的，现在两个fg有一个关了
                showCloseAIAlert()
            }
        }
        return open
    }
    
    func showCloseAIAlert() {
        let alert = LarkAlertController()
        let name = self.accountContext.provider.myAIServiceProvider?.aiDefaultName ?? ""
        alert.setContent(text: BundleI18n.MailSDK.Mail_MyAI_ContactAdministratorForPermission_aiName_Desc(name)
,
                         alignment: .center)
        alert.setTitle(text: BundleI18n.MailSDK.Mail_MyAI_NoMyAIPermission_aiName_Title(name)
)
        alert.addButton(text: BundleI18n.MailSDK.Mail_MyAI_GotIt_Button, color: UIColor.ud.textLinkNormal)
        navigator?.present(alert, from: self)
    }
    func aiBtnClick() {
        // 避免重复点击
        guard !aiIconClick else {
            MailLogger.info("[MailAIChat] re click click!")
            return
        }
        self.aiIconClick = true
        self.chatAIService.chatModeClickReport()
        let needOnboarding = self.accountContext.provider.myAIServiceProvider?.needOnboarding ?? false
        // 判断是否已经onboarding
        if needOnboarding {
            self.openAIOnboarding()
            return
        }
        self.openChatPage()
    }
    private func openChatPage() {
        self.chatAIService.getChatIDs() { [weak self] (chat, chatmode) in
            guard let `self` = self else { return }
            let idEmpty = self.viewModel.labelId.isEmpty || self.viewModel.threadId.isEmpty
            let unableUse = BundleI18n.MailSDK.Mail_MyAI_UnableToUse_Toast(self.accountContext.provider.myAIServiceProvider?.aiNickName ?? self.accountContext.provider.myAIServiceProvider?.aiDefaultName ?? "")
            if let chatId = Int64(chat),
                let chatModeId = Int64(chatmode),
                !idEmpty {
                    self.launchAIChat(mailContent: nil,
                                      isTrim: nil,
                                      chatId: chatId,
                                      chatModeId: chatModeId)
            } else {
                self.aiIconClick = false
                // show toast
                MailRoundedHUD.showFailure(with: unableUse,
                                           on: self.view)
                MailLogger.info("[MailAIChat] aiClick show error toast, \(idEmpty)")
                // 无法使用场景清除chatId
                if !idEmpty {
                    self.accountContext.accountKVStore.removeValue(forKey: UserDefaultKeys.mailAIChatId)
                    self.accountContext.accountKVStore.removeValue(forKey: UserDefaultKeys.mailAIChatModeId)
                }
            }
        }
    }
    private func openAIOnboarding() {
        self.accountContext.provider.myAIServiceProvider?.openAIOnboarding(vc: self,
                                                                           onSuccess: { [weak self] _ in
            guard let `self` = self else { return }
            // onboarding成功后，打开chatPage
            self.openChatPage()
            self.aiIconClick = false
        }, onError: { [weak self] error in
            guard let `self` = self else { return }
            self.aiIconClick = false
            let unableUse = BundleI18n.MailSDK.Mail_MyAI_UnableToUse_Toast(self.accountContext.provider.myAIServiceProvider?.aiNickName ?? self.accountContext.provider.myAIServiceProvider?.aiDefaultName ?? "")
            MailRoundedHUD.showFailure(with: unableUse,
                                       on: self.view)
            MailLogger.info("[MailAIChat] openAIOnboarding error \(error)")
        }, onCancel: { [weak self] in
            self?.aiIconClick = false
            MailLogger.info("[MailAIChat] openAIOnboarding canceled")
        })
    }
    private func launchAIChat(mailContent: String?,
                              isTrim: Bool?,
                              chatId: Int64,
                              chatModeId: Int64) {
        self.chatAIService.chatModeViewReport(label: self.fromLabel)
        let accountID = Store.settingData.getCachedCurrentAccount()?.mailAccountID ?? ""
        let threadId = self.allMessageIds.joined(separator: ";") + ";"
        let labelId = self.viewModel.labelId
        MailLogger.info("[MailAIChat] launchAIChat")
        let callback: (MyAIChatModeConfig.PageService) -> Void = { [weak self] service in
            guard let `self` = self else { return }
            self.aiPageService = service
            self.aiPageService?.isActive
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] value in
                    guard let `self` = self else { return }
                    if !value {
                        // 释放pageService,恢复按钮可点击
                        MailLogger.info("[MailAIChat] chat page is not active")
                        self.aiPageService = nil
                        self.aiIconClick = false
                    } else {
                        self.aiIconClick = true
                        MailLogger.info("[MailAIChat] chat page is active")
                    }
                }).disposed(by: self.disposeBag)
        }
        let openRag = self.accountContext.featureManager.open(.openRag, openInMailClient: false)
        self.accountContext.provider.myAIServiceProvider?.launchChatMode(chatID: chatId,
                                                                         chatModeID: chatModeId,
                                                                         mailContent: mailContent,
                                                                         isTrim: isTrim,
                                                                         accountId: accountID,
                                                                         bizIds: threadId,
                                                                         labelId: labelId,
                                                                         openRag: openRag,
                                                                         callback: callback)
    }
    
}

