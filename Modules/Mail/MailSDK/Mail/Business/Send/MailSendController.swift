//
//  ViewController.swift
//  LKTokenInputView
//
//  Created by majx on 05/26/19 from CLTokenInputView-Swift by Robert La Ferla.
//
//

import Foundation
import UIKit
import WebKit
import LarkUIKit
import SnapKit
import RxSwift
import RxCocoa
import EENavigator
import LKCommonsLogging
import LarkActionSheet
import LarkAlertController
import Homeric
import Reachability
import RustPB
import ServerPB
import LarkTraitCollection
import LarkLocalizations
import UniverseDesignIcon
import FigmaKit
import UniverseDesignActionPanel
import UniverseDesignShadow
import UniverseDesignColor
import UniverseDesignCheckBox
import LarkKeyCommandKit
import UniverseDesignDialog
import ThreadSafeDataStructure
import LarkSceneManager
import LarkSplitViewController

typealias DiscardCallback = (String) -> Void
typealias DraftSaveCommonParam = MailAPMEvent.SaveDraft.CommonParam

protocol MailSendOOODelegate: AnyObject {
    func saveAutoReplyLetter(content: MailContent?)
}

enum addressType {
    case toAddress
    case ccAddress
    case bccAddress
}
let mentionHeaderHeight: CGFloat = 50
let mentionHeaderWidth: CGFloat = 300

class MailSendController: MailBaseViewController, MailSendAttachmentDelegate,
                          EditorPluginRenderDelegate, MailSendContentCheckerDelegate,
                          MailSendPriorityDelegate,
                          UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate,
                          WKNavigationDelegate, UIScrollViewDelegate, UIDocumentPickerDelegate, UIViewControllerTransitioningDelegate {

    enum SendScene: String {
        case send   // 直接发送
        case scheduleSend // 定时发送
        case scheduleSendCheck // 定时发送前检查
        case draft  // 保存草稿
        case getDraft // 仅获取草稿，不进行保存
    }
    private var msgStatInfo: MessageListStatInfo?
    // 需手动填写rootPath
    static let debugPath = String(cString: "") + "../../LarkEditorJS/Bizs/LarkEditorJS/resources/EditorVendorJS"
    var viewModel: MailSendViewModel = MailSendViewModel()
    let dataManager = MailSendDataMananger.shared
    let threadActionDataManager = ThreadActionDataManager()
    lazy var attachmentViewModel: MailSendAttachmentViewModel = MailSendAttachmentViewModel(accountContext: accountContext)
    lazy var toolbarConfig = EditorToolBarConfig(self.view.bounds.size.height)
    var dataProvider: MailSendDataProvider = MailSendDataSource()
    let keyBoard: Keyboard = Keyboard()
    var lastResponderView: UIView?
    var languageId: String?
    var feedCardId: String?
    var tempDate: Date?
    var scheduleSendTime: Int64 = 0
    var isWebViewMention = false
    var initDate: Date?
    var spWording: String {
        return draft?.isSendSeparately == true ? BundleI18n.MailSDK.Mail_Compose_CancelSp : BundleI18n.MailSDK.Mail_Normal_Sp
    }
    var isShowSeparateSendEnable: Bool {
        let status = Store.settingData.getCachedCurrentAccount()?.mailSetting.mailOnboardStatus
        let userType = Store.settingData.getCachedCurrentAccount()?.mailSetting.userType
        if userType != .larkServer {
            return false
        }
        return status == .active || status == .softInput
    }
    weak var sendNavVC: MailNavigationController?
    internal var mainToolBar: MailMainToolBar?
    internal var toolBarSubPanel: EditorSubToolBarPanel?
    let action: MailSendAction
    lazy var contentChecker = MailSendContentChecker(accountContext: accountContext)
    var totalDistance: CGFloat = 0
    var startOffsetY: CGFloat?
    var originContentOffset: CGPoint?
    var moreBtn: UIView?
    let constCalendarTemplate = """
<blockquote style="padding-left: 0px; color: #646a73; border-left: 2px solid #bbbfc4; margin: 0px;" class="lark-mail-doc-quote"><div id="lark-calendar-3434-{{calendarId}}" style="white-space:pre; white-space:pre-wrap; margin-left: 12px;"><span>{{calendarDesc}}<wbr></span> <a href="{{calendarLink}}" target="_blank" rel="noopener noreferrer" style="transition: color 0.3s ease 0s; margin-right: 2px; cursor: pointer; text-decoration: none; color: rgb(51, 112, 255);">{{calendarLink}}</a></div></blockquote>
"""
    var calendarTemplateFetched = ""
    // 白屏检测相关参数
    var renderSuccess = false
    var hasContent: Bool?

    /// 当前光标位置
    internal var selectionPosition: EditorSelectionPosition? {
        didSet {
            /// 滚动光标到可视范围
            guard let top = selectionPosition?.top, let height = selectionPosition?.height else { return }
            guard mainToolBar != nil else { return }
            let originOffset = scrollContainer.contentOffset
            let webviewY = scrollContainer.webView.frame.minY
            let selectionY = top + webviewY
            let toolbarY = mainToolBar?.frame.minY ?? 0
            let screenY = selectionY - scrollContainer.contentOffset.y
            let bottomY = webviewY + top + height - toolbarY
            let padding: CGFloat = 10
            if screenY > (toolbarY - height) {
                // In this case, selection point is below the keyboard
                scrollContainer.contentOffset = CGPoint(x: originOffset.x, y: bottomY + padding)
            } else if selectionY < originOffset.y {
                // In this case, selection point is above the visible screen
                scrollContainer.contentOffset = CGPoint(x: originOffset.x, y: selectionY - padding)
            }
        }
    }
    var isNewDraft: Bool = false
    var needBlockWebImages: Bool = false

    // 封面相关
    lazy var officialCoverProvider = OfficialCoverPhotoDataProvider(configurationProvider: accountContext.provider.configurationProvider, imageService: accountContext.imageService)
    lazy var officialCoverListProvider = OfficialCoverPhotosProvider(configurationProvider: accountContext.provider.configurationProvider)
    lazy var coverPickerVM = CoverSelectPanelViewModel(networkAPI: officialCoverListProvider, delegate: self, provider: accountContext)

    // 外部设置的内容
    var baseInfo: MailSendBaseInfo
    let ondiscard: DiscardCallback?
    private var sendTo: [MailAddress]?
    var trackerSourceType: MailTracker.SourcesType

    weak var oooDelegate: MailSendOOODelegate?

    var closeHandler: (() -> Void)?

    private(set) var disposeBag = DisposeBag()
    var mentionBag: DisposeBag?
    var searchBag: DisposeBag = DisposeBag()
    static let logger = Logger.log(MailSendController.self, category: "Module.MailSendController")
    internal var isViewDidAppear = false
    var isViewWillDisAppear = false
    internal var sendButton: UIButton?
    private var largefilePermissionToAnyone = false
    var needShowConvertToLargeTips = false
    private var sendMailItem: MailItem? = nil
    var canSendExternal = true
    var removeScheduleLoading = false
    var reachability: Reachability? = Reachability()
    private(set) var connection: Reachability.Connection?
    internal lazy var feedbackGenerator = UISelectionFeedbackGenerator()

    private var hasDraftChangePush = false // 标记是否有未处理的草稿变更推送
    private var hasThreadChangePush = false // 标记是否有未处理的会话变更推送

    lazy var aiService: MailAIService = {
        let service = MailAIService(accountContext: self.accountContext)
        service.delegate = self
        return service
    }()
    var hidePlaceHolder = false
    let mentionLabel: UILabel = {
        let xCGPoint: CGFloat = 16
        let yCGPoint: CGFloat = 0
        let label = UILabel(frame: CGRect(x: xCGPoint, y: yCGPoint, width: mentionHeaderWidth, height: mentionHeaderHeight))
        return label
    }()
    lazy var mentionAddAddressBtn: UIButton = {
        let btnWidth: CGFloat = 20
        let btnHeight: CGFloat = 20
        let xCGPoint: CGFloat = 16
        let yOffset:CGFloat = 18
        let yCGPoint: CGFloat = (mentionHeaderHeight - yOffset) / 2

        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: btnWidth, height: btnHeight))
        btn.setImage(Resources.mail_cell_option_selected, for: .selected)
        btn.setImage(Resources.mail_cell_option, for: .normal)
        btn.frame = CGRect(x: xCGPoint, y: yCGPoint, width: btnWidth, height: btnHeight)
        btn.isUserInteractionEnabled = false
        btn.isSelected = getMentionStatus()
        return btn
    }()
    let mentionDicKey = "Mail_Send_Mention_Add_Address_Key"
    // MARK: Views
    var scrollContainer: MailSendContainerView!
    lazy var aiMaskView: MailAIMaskView = {
        let view = MailAIMaskView()
        view.backgroundColor = .clear
        view.isHidden = true
        view.delegate = self
        return view
    }()

    // 文档相关信息
    var docInfoArray = SafeDictionary<String, DocShareModel>(synchronization: .readWriteLock)

    lazy var tableHeaderView: UIView = {
        let pathWidth: CGFloat = 12.0
        let pathHeight: CGFloat = 12.0
        let borderWidth: CGFloat = 0.000001
        let mentionLabelFontSize: CGFloat = 16

        let bound = CGRect(x: 0, y: 0, width: view.bounds.width, height: mentionHeaderHeight)
        let view = UIView(frame: bound)
        view.backgroundColor = UIColor.ud.bgFloat
        if mentionFg() {
            mentionLabel.text = BundleI18n.MailSDK.Mail_Edit_AddToRecipient
            mentionLabel.textColor = UIColor.ud.textTitle
        } else {
            mentionLabel.text = BundleI18n.MailSDK.Mail_Compose_Mentions_Title
            mentionLabel.textColor = UIColor.ud.textPlaceholder
        }
        mentionLabel.font = UIFont.systemFont(ofSize: mentionLabelFontSize)
        view.addSubview(mentionLabel)
        if mentionFg() {
            let mentionFrameX: CGFloat = 48
            let mentionFrameY: CGFloat = 0
            view.addSubview(mentionAddAddressBtn)
            updateMentionBtnView()
            mentionLabel.frame = CGRect(x: mentionFrameX, y: mentionFrameY, width: mentionHeaderWidth, height: mentionHeaderHeight)
            let tap = UITapGestureRecognizer(target: self, action: #selector(mentionBtnClick))
            view.addGestureRecognizer(tap)
            view.isUserInteractionEnabled = true
        }
        return view
    }()

    func updateMentionBtnView() {
        if mentionAddAddressBtn.isSelected {
            let cornerRadius: CGFloat = 10
            mentionAddAddressBtn.backgroundColor = UIColor.ud.primaryContentDefault
            mentionAddAddressBtn.layer.cornerRadius = cornerRadius
            mentionAddAddressBtn.clipsToBounds = true
        } else {
            let cornerRadius: CGFloat = 0
            mentionAddAddressBtn.backgroundColor = UIColor.clear
            mentionAddAddressBtn.layer.cornerRadius = cornerRadius
            mentionAddAddressBtn.clipsToBounds = false
        }

    }
    var suggestTableSelectionRow = -1 {
        didSet {
            if !self.suggestTableView.isHidden && Display.pad {
                if suggestTableSelectionRow >= 0 &&
                    suggestTableSelectionRow < self.viewModel.filteredArray.count {
                    self.suggestTableView.selectRow(at: IndexPath(row: suggestTableSelectionRow,
                                                                  section: 0),
                                                    animated: true,
                                                    scrollPosition: .middle)
                }
            }
        }
    }

    lazy var suggestTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(MailAddressCell.self, forCellReuseIdentifier: MailAddressCellConfig.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.tableFooterView = nil
        tableView.rowHeight = MailAddressCellConfig.height
        tableView.backgroundColor = UIColor.ud.bgBody
        // fix 改变搜索词table contentOffset跳变的问题
        tableView.estimatedRowHeight = 0.0
        tableView.estimatedSectionFooterHeight = 0.0
        tableView.estimatedSectionHeaderHeight = 0.0
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 60, bottom: 0, right: 0)
        return tableView
    }()

    lazy var shawdowHeaderView: UIView = {
        let shadowView = UIView()
        shadowView.isHidden = true
        shadowView.backgroundColor = UIColor.ud.bgBody
        shadowView.layer.cornerRadius = 12
        shadowView.layer.maskedCorners = CACornerMask(rawValue: CACornerMask.layerMinXMinYCorner.rawValue | CACornerMask.layerMaxXMinYCorner.rawValue)
        shadowView.layer.ud.setShadow(type: .s3Up)
        return shadowView
    }()

    // 是否需要忽略本次text（paste的内容另外处理）
    var shouldIgnoreThisInput: Bool = false

    // 草稿相关
    let draftSaveChecker: MailDraftSaveEnableChecker = MailDraftSaveEnableChecker()
    var htmlContentChangeRelay = PublishRelay<Void>()
    var createDraftRelay = BehaviorRelay<(Email_Client_V1_MailCreateDraftResponse?, Bool)>(value: (nil, false))
    var needsSaveDraftToast = false
    var needOOOSaveToast = false
    var draft: MailDraft? {
        didSet {
            guard draft != nil else {
                MailLogger.info("set draft nil")
                return
            }
            fetchSendExternal()
        }
    }
    var serverDraft: MailDraft?
    var draftChangeAlert: LarkAlertController?

    private var addressFromUserInfo: MailAddress?
    private var draftDeleted = false
    var draftSent = false
    var draftFromOutbox = false
    var refocusKey = ""
    let needFocus = 101


    var firstResponder: UIView?
    var popoverOriginY: CGFloat?

    // 邮件内容（用于回复及转发）
    private var messageItem: MailMessageItem?

    var editionInputView: LKTokenInputView?
    // editionInputView 是用户输入后请求时传入，请求返回后会重置为 nil
    // 三方联系人支持搜索后会多个 push，需要另外存储一个输入 view
    var pushEditionInputView: LKTokenInputView?
    var replyAttachments: [Email_Client_V1_Attachment]?
    var showedExipredAlert: Bool = false
    var sendEditorParam: [String: Any]?
    var saveDraftParam: [String: Any]?
    var emlFilledSubject: Bool = false

    // 收件人数量相关
    // 当收件人数量超过限制阈值时，出现弹窗确认提醒
    /// Admin是否开启限制收件人规模
    var recipientLimitEnable = false
    /// 收件人规模限制阈值，由Admin配置
    var recipientLimit: Int64 = 0
    /// 标记当前收件人规模是否超限，添加收件地址时无需计算，删除收件地址时需要重新置为false
    var recipientOverLimit: Bool = false
    /// 群组、邮件组人数存储，单个直接超限的 value 为 -1，key：群组使用LarkID，邮件组使用address
    var groupMemberCount: [String: Int64] = [:]

    override var serviceProvider: MailSharedServicesProvider? {
        accountContext
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setEditorDarkModeIfNeeded()
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .default
    }

    override var navigationBarTintColor: UIColor {
        return UIColor.ud.bgBody
    }

    var pluginRender: EditorPluginRender? {
        return self.scrollContainer.webView.pluginRender
    }

    override func updateNavigationBar() {
        super.updateNavigationBar()
        updateSendButtonEnable()
    }



    func makePluginRender() {
        pluginRender?.initDelegate(jsEngine: self, sendVC: self, docsInfoDelegate: self, mentionDelegate: self, uploaderDelegate: self, threadID: baseInfo.threadID ?? "", code: baseInfo.mailItem?.code ?? .none, statInfo: baseInfo.statInfo)
        pluginRender?.renderDelegate = self
        self.scrollContainer.webView.sendVCJSHandlerInited = true
    }

    let accountContext: MailAccountContext

    var holdVC: MailSendController?
    let holdVCMaxTime: Double = 15.0
    var slardarInitFlag = false


    init(accountContext: MailAccountContext,
         threadID: String?,
         messageID: String?,
         action: MailSendAction,
         labelID: String?,
         chatID: String?,
         statInfo: MailSendStatInfo,
         trackerSourceType: MailTracker.SourcesType,
         mailItem: MailItem?,
         sendToAddress: String?,
         ondiscard: DiscardCallback?,
         msgStatInfo: MessageListStatInfo?,
         languageId: String?,
         isNewDraft: Bool?,
         subject: String?,
         body: String?,
         cc: String?,
         bcc: String?,
         fileBannedInfos: [String: FileBannedInfo]?,
         feedCardId: String?) {
        MailTracker.startRecordTimeConsuming(event: Homeric.MAIL_DEV_CONTENT_COST_TIME, params: ["from": msgStatInfo?.from == .chat ? "chat" : "mail"])
        self.feedCardId = feedCardId
        self.action = action
        self.baseInfo = MailSendBaseInfo(threadID: threadID,
                                         messageID: messageID,
                                         chatID: chatID,
                                         currentLabelId: labelID ?? Mail_LabelId_Inbox,
                                         statInfo: statInfo,
                                         mailItem: mailItem,
                                         sendToAddress: sendToAddress,
                                         fileBannedInfos: fileBannedInfos)
        if let has_subject = subject {
            self.baseInfo.subject = has_subject
        }
        if let has_body = body {
            self.baseInfo.body = has_body
        }
        if bcc != nil {
            self.baseInfo.bccAddress = bcc
        }
        if cc != nil {
            self.baseInfo.ccAddress = cc
        }
        var langStr: String?
        if let data = languageId?.data(using: .utf8),
           let lans = try? JSONSerialization.jsonObject(with: data, options: []) as? [String],
           let first = lans.first {
            langStr = first
        } else {
            langStr = BundleI18n.currentLanguage.languageIdentifier // 传入主端的语言
        }
        self.languageId = langStr
        self.msgStatInfo = msgStatInfo
        self.ondiscard = ondiscard
        self.trackerSourceType = trackerSourceType
        self.accountContext = accountContext
        super.init(nibName: nil, bundle: nil)
        self.scrollContainer = MailSendContainerView(frame: .zero, sendAction: action, sendController: self)
        if let isNewDraft = isNewDraft {
            self.isNewDraft = isNewDraft // create forwardDraft的场景以response的为准
        }
        makePluginRender()
        self.initDate = Date()
        self.apmSendLoadStart()
        if let _ = self.scrollContainer.webView.draft,
           self.scrollContainer.webView.renderJSCallBackSuccess {
            // already has draft, do nothing
        } else if self.createDraftAction() {
            let draftAction = action.getDraftAction()
            dataManager.createDraft(with: baseInfo.messageID,
                                                threadID: baseInfo.threadID,
                                                msgTimestamp: getDraftMessageTimestamp(),
                                                action: draftAction,
                                                languageId: languageId).observeOn(MainScheduler.instance)

            .subscribe(onNext: { [weak self] (resp) in
                self?.createDraftRelay.accept((resp, true))
            }, onError: { [weak self] (_) in
                MailLogger.log(level: .info,
                               message: "create draft fail")
                self?.createDraftRelay.accept((nil, true))
            }).disposed(by: disposeBag)
        }
        self.attachmentViewModel.delegate = self
        self.attachmentViewModel.viewController = self
        contentChecker.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(didReceivedKeyboardWillHideNotification), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceivedKeyboardDidShowNotification), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.rx.notification(UIApplication.didEnterBackgroundNotification)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.apmSuspendLoad()
                self?.doSaveDraft(param: DraftSaveCommonParam.background_save)
            }).disposed(by: disposeBag)
        NotificationCenter.default.rx.notification(UIApplication.willResignActiveNotification)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                if self?.firstResponder == self?.scrollContainer.webView {
                    self?.scrollContainer.webView.focusAtSelectionEnd()
                    self?.doSaveDraft(param: DraftSaveCommonParam.background_save)
                }
            }).disposed(by: disposeBag)
        NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                if self.aiService.myAIContext.inAIMode {
                    self.requestHideKeyBoard()
                }
            }).disposed(by: disposeBag)

        htmlContentChangeRelay
            .debounce(.milliseconds(timeIntvl.normalMili), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.doSaveDraft(param: DraftSaveCommonParam.auto_save)
                self.draftSaveChecker.htmlContentChangeCount = 0
            })

        scrollContainer.delegate = self
        scrollContainer.sendController = self
        scrollContainer.contentInset = UIEdgeInsets.zero
        scrollContainer.sendController = self
        draftSaveChecker.sendVC = self
    }

    func mentionFg() -> Bool {
        let flag = accountContext.featureManager.open(.mentionAddAddress)
        return flag
    }

    @objc
    func mentionBtnClick() {
        guard mentionAddAddressBtn.isHidden == false else { return }
        mentionAddAddressBtn.isSelected = !mentionAddAddressBtn.isSelected
        updateMentionBtnView()
    }

    func setMentionDic() {
        let accountID = Store.settingData.getCachedCurrentAccount()?.mailAccountID ?? ""
        let kvStore = accountContext.accountKVStore
        var temDic: [String: Bool] = [:]
        if let dic: [String: Bool] = kvStore.value(forKey: mentionDicKey) {
            let id = accountContext.user.userID
            temDic = dic
            temDic[id] = self.mentionAddAddressBtn.isSelected
        }
        if !temDic.isEmpty {
            // nothing
        } else {
            let id = accountContext.user.userID
            temDic[id] = self.mentionAddAddressBtn.isSelected
        }
        kvStore.set(temDic, forKey: mentionDicKey)
    }

    func getMentionStatus() -> Bool {
        let kvStore = accountContext.accountKVStore
        if let dic: [String: Bool] = kvStore.value(forKey: mentionDicKey) {
            let id = accountContext.user.userID
            if let flag = dic[id] {
                return flag
            }
        }
        return false
    }

    @objc
    func didReceivedKeyboardWillHideNotification() {
        lastResponderView = view.firstResponder
        deactiveContactlist()
    }

    @objc
    func didReceivedKeyboardDidShowNotification() {
        guard scrollContainer.webView.scrollView.contentOffset.y > 0 else {
            return
        }
        let deltaY = scrollContainer.webView.scrollView.contentOffset.y + (mainToolBar?.frame.height ?? 0)
        scrollContainer.setContentOffset(CGPoint(x: scrollContainer.contentOffset.x, y: scrollContainer.contentOffset.y + deltaY), animated: true)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 根据 Store.settingData.hasEmailService == true 判断mailTab不存在时会返回空，调用方需要处理
    /// 修复 5.7 bug，控制影响面先单独新开方法，后续创建MailSend应该全部走这个方法
    class func checkMailTab_makeSendNavController(accountContext: MailAccountContext,
                                                  threadID: String? = nil,
                                                  messageID: String? = nil,
                                                  action: MailSendAction,
                                                  labelId: String? = nil,
                                                  draft: MailDraft? = nil,
                                                  statInfo: MailSendStatInfo,
                                                  trackerSourceType: MailTracker.SourcesType = .composeButton,
                                                  ondiscard: DiscardCallback? = nil,
                                                  chatID: String? = nil,
                                                  sendTo: [MailAddress]? = nil,
                                                  mailItem: MailItem? = nil,
                                                  sendToAddress: String? = nil,
                                                  oooDelegate: MailSendOOODelegate? = nil,
                                                  msgStatInfo: MessageListStatInfo? = nil,
                                                  languageId: String? = nil,
                                                  isNewDraft: Bool = false,
                                                  needBlockWebImages: Bool = false,
                                                  fileBannedInfos: [String: FileBannedInfo]? = nil,
                                                  feedCardId: String? = nil) -> LkNavigationController? {
        MailLogger.info("checkMailTab_makeSendNavController called")
        guard Store.settingData.hasEmailService else {
            // MailTab不存在，不能跳转写信，使用方需要另外处理
            MailLogger.info("MailTab not enabled, failed to create sendVC")
            return nil
        }
        return makeSendNavController(accountContext: accountContext,
                                     threadID: threadID,
                                     messageID: messageID,
                                     action: action,
                                     labelId: labelId,
                                     draft: draft,
                                     statInfo: statInfo,
                                     trackerSourceType: trackerSourceType,
                                     ondiscard: ondiscard,
                                     chatID: chatID,
                                     sendTo: sendTo,
                                     mailItem: mailItem,
                                     sendToAddress: sendToAddress,
                                     oooDelegate: oooDelegate,
                                     msgStatInfo: msgStatInfo,
                                     languageId: languageId,
                                     isNewDraft: isNewDraft,
                                     needBlockWebImages: needBlockWebImages,
                                     fileBannedInfos: fileBannedInfos,
                                     feedCardId: feedCardId)
    }

    @available(*, deprecated, message: "请使用 checkMailTab_makeSendNavController，需要处理mailTab不存在时无法显示发信页的情况")
    class func makeSendNavController(accountContext: MailAccountContext,
                                     threadID: String? = nil,
                                     messageID: String? = nil,
                                     action: MailSendAction,
                                     labelId: String? = nil,
                                     draft: MailDraft? = nil,
                                     statInfo: MailSendStatInfo,
                                     trackerSourceType: MailTracker.SourcesType = .composeButton,
                                     ondiscard: DiscardCallback? = nil,
                                     chatID: String? = nil,
                                     sendTo: [MailAddress]? = nil,
                                     mailItem: MailItem? = nil,
                                     sendToAddress: String? = nil,
                                     oooDelegate: MailSendOOODelegate? = nil,
                                     msgStatInfo: MessageListStatInfo? = nil,
                                     languageId: String? = nil,
                                     isNewDraft: Bool? = nil,
                                     subject: String? = nil,
                                     body: String? = nil,
                                     cc: String? = nil,
                                     bcc: String? = nil,
                                     shouldMonitorPermissionChanges: Bool = true,
                                     needBlockWebImages: Bool = false,
                                     fileBannedInfos: [String: FileBannedInfo]? = nil,
                                     closeHandler: (() -> Void)? = nil,
                                     feedCardId: String? = nil) -> LkNavigationController {
        MailTracker.editViewLog(clickType: .editView, editType: trackerSourceType)
        let sendVc = MailSendController(accountContext: accountContext,
                                        threadID: threadID,
                                        messageID: messageID,
                                        action: action,
                                        labelID: labelId,
                                        chatID: chatID,
                                        statInfo: statInfo,
                                        trackerSourceType: trackerSourceType,
                                        mailItem: mailItem,
                                        sendToAddress: sendToAddress,
                                        ondiscard: ondiscard,
                                        msgStatInfo: msgStatInfo,
                                        languageId: languageId,
                                        isNewDraft: isNewDraft,
                                        subject: subject,
                                        body: body,
                                        cc: cc,
                                        bcc: bcc,
                                        fileBannedInfos: fileBannedInfos,
                                        feedCardId: feedCardId)
        sendVc.draft = draft
        sendVc.draft?.threadID = threadID ?? ""
        sendVc.sendTo = sendTo
        sendVc.oooDelegate = oooDelegate
        sendVc.shouldMonitorPermissionChanges = shouldMonitorPermissionChanges
        sendVc.closeHandler = closeHandler
        let sendNav = MailNavigationController(rootViewController: sendVc)
        sendNav.navigationBar.isTranslucent = false
        sendNav.navigationBar.shadowImage = UIImage()
        sendNav.modalPresentationStyle = .fullScreen
        sendVc.sendNavVC = sendNav
        sendVc.isNewDraft = isNewDraft ?? false
        sendVc.needBlockWebImages = needBlockWebImages
        return sendNav
    }

    deinit {
        self.scrollContainer.webView.cleanEditorReloadTimer()
        /// 释放前再次停止键盘监听，预防crash
        stopListenKeyBoard()
        if let reach = reachability {
            reach.stopNotifier()
            reach.notificationCenter.removeObserver(self)
        }
        MailLogger.info("mail send deinit")
        MailTracker.log(event: "mail_draft_scroll_distance_dev", params: ["distance": totalDistance])
    }

    // MARK: life circle
    override func viewDidLoad() {
        super.viewDidLoad()
        if let draft = self.scrollContainer.webView.draft,
           self.scrollContainer.webView.renderJSCallBackSuccess {
            self.draft = draft
            self.isNewDraft = self.scrollContainer.webView.isNewDraft
        }
        let cost = Date().timeIntervalSince(initDate ?? Date()) * 1000
        let beforeViewDidLoad = MailAPMEvent.DraftLoaded.EndParam.activity_created_cost_time(cost)
        self.apmHolder[MailAPMEvent.DraftLoaded.self]?.endParams.append(beforeViewDidLoad)
        MailTracker.startRecordTimeConsuming(event: "mail_editor_vc_load_time", params: nil)
        MailTracker.log(event: "mail_editor_bad_network_draft", params: ["is_weak_network": reachability?.connection == Reachability.Connection.none ? 1 : 0])
        MailLogger.info("mail send view did load")

        scrollContainer.frame = view.bounds
        scrollContainer.contentSize = CGSize(width: view.bounds.size.width, height: view.bounds.size.height)

        MailTracker.startRecordTimeConsuming(event: Homeric.MAIL_DEV_SEND_VIEWDIDLOAD_COST_TIME, params: nil)
        isNavigationBarHidden = false
        addCloseItem()
        closeCallback = { [weak self] in
            self?.attachmentViewModel.cancelAll()
        }
        setupViews()
        constructAttachmentViewModel()
        loadData()
        loadAddress()
        // 键盘监听
        listenKeyBoard()
        // 事件监听
        addObserver()
        networkChanged()
        MailTracker.endRecordTimeConsuming(event: Homeric.MAIL_DEV_SEND_VIEWDIDLOAD_COST_TIME, params: nil)
        self.scrollContainer.webView.checkIfEditorIsReady()
        MailTracker.startRecordTimeConsuming(event: "mail_editor_vc_load_time", params: nil)
        RootTraitCollection.observer
        .observeRootTraitCollectionWillChange(for: self)
        .subscribe(onNext: { [weak self] _ in
            guard let `self` = self else { return }
            self.dismissVCWhenTransition()
        }).disposed(by: disposeBag)
        setEditorDarkModeIfNeeded()
        slardarInit()
    }
    func slardarInit() {
        guard !Store.settingData.mailClient else { return }
        guard self.scrollContainer.webView.isReady else { return }
        guard !self.slardarInitFlag else { return }
        self.slardarInitFlag = true
        // 三方不进行slardar监控；默认开关关闭，走slardar监控
        if !accountContext.featureManager.open(FeatureKey(fgKey:.mailSlardarWebClose, openInMailClient: true)) {
            let openPerformance = self.accountContext.featureManager.open(FeatureKey(fgKey: .editorPerformance, openInMailClient: false)) ?? false
            let isOverSea = self.accountContext.user.isOverSea ?? false
            evaluateJavaScript("window.command.slardarInit(\(isOverSea), \(openPerformance))")
        }
    }

    func fetchSendExternal() {
        if Store.settingData.mailClient {
            return
        }
        guard let address = draft?.content.from else { mailAssertionFailure("must have address"); return }
        _ = MailDataServiceFactory.commonDataService?.fetchCanSendExternal(address: address.toPBModel()).subscribe { [weak self] (res) in
            self?.canSendExternal = res
        } onError: { (err) in
            mailAssertionFailure("err: \(err)")
        }
    }

    private func dismissVCWhenTransition() {
        if let moreVC = self.presentedViewController as? PopupMenuPoverViewController {
            moreVC.dismiss(animated: false, completion: nil)
        }
        if let alertVC = self.presentedViewController as? ActionSheet {
            alertVC.dismiss(animated: false, completion: nil)
        }
    }

    private func dismissVCWhenAlert(completion: (() -> Void)?) {
        if let presentedVC = self.presentedViewController,
           !presentedVC.isKind(of: LarkAlertController.self) {
            presentedVC.dismiss(animated: true, completion: completion)
        } else {
            completion?()
        }
    }

    private func addObserver() {
        PushDispatcher
            .shared
            .mailChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                switch push {
                case .threadChange(let change):
                    self?.didReceivedThreadChanged((change.threadId, change.labelIds))
                case .multiThreadsChange(let change):
                    self?.didReceivedMultiThreadChanged(change.label2Threads)
                case .draftChange(let change):
                    self?.didReceivedDraftChanged((change.draftId, change.action))
                default:
                    break
                }
            }).disposed(by: disposeBag)

        EventBus.threadListEvent.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] event in
            if case let .didReloadListData(labelId: labelId, _) = event {
                self?.didReceivedThreadRefreshed(labelId)
            }
        }).disposed(by: disposeBag)

        bindCoverPickerViewModelIfNeeded()
        listenSearchContactPush()
        listenGroupMemberCountPush()

        if let reach = reachability {
            connection = reach.connection
            reach.notificationCenter.addObserver(self, selector: #selector(networkChanged), name: Notification.Name.reachabilityChanged, object: nil)
            do {
                try reachability?.startNotifier()
            } catch {
                MailLogger.error("could not start reachability notifier")
            }
        }
        self.accountContext.provider.myAIServiceProvider?.aiNickNameRelay
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] nick in
                if !nick.isEmpty {
                    self?.updateAIName(name: nick)
                }
            }).disposed(by: disposeBag)
    }

    func didReceivedMultiThreadChanged(_ label2Threads: Dictionary<String, (threadIds: [String], needReload: Bool)>) {
        guard label2Threads.keys.contains(Mail_LabelId_Trash) else {
            return
        }
        if let info = label2Threads[Mail_LabelId_Trash],
            (info.needReload || info.threadIds.contains(baseInfo.threadID ?? "")) {
            MailLogger.info("handleDraftDisappearIfNeeded in didReceivedMultiThreadChanged")
            handleDraftDisappearIfNeeded()
        }
    }

    func setEditorDarkModeIfNeeded() {
        guard accountContext.featureManager.open(FeatureKey(fgKey: .darkMode, openInMailClient: true)) else { return }
        if #available(iOS 13.0, *) {
            let isDarkMode = self.traitCollection.userInterfaceStyle == .dark
            // editor不受内容层DM切换开关控制 跟应用保持一致
            evaluateJavaScript("window.command.setDarkMode(\(isDarkMode))")
        }
    }

    func didReceivedThreadChanged(_ change: (threadId: String, labelIds: [String])) {
        guard change.threadId == self.baseInfo.threadID, change.labelIds.contains(Mail_LabelId_Draft) else {
            return
        }
        MailLogger.info("handleDraftDisappearIfNeeded in didReceivedThreadChanged")
        handleDraftDisappearIfNeeded()
    }

    func didReceivedThreadRefreshed(_ labelId: String) {
        if labelId == Mail_LabelId_Draft {
            MailLogger.info("handleDraftDisappearIfNeeded in didReceivedThreadRefreshed")
            handleDraftDisappearIfNeeded()
        }
    }

    func didReceivedDraftChanged(_ change: (draftId: String, action: Email_V1_DraftAction)) {
        guard change.draftId == draftID else { return }
        MailLogger.info("processDraftChange in didReceivedDraftChanged")
        processDraftChange()
    }

    func processDraftChange() {
        guard accountContext.featureManager.open(.draftSync, openInMailClient: true) else { return }
        guard !draftSent else {
            MailLogger.info("processDraftChange return sent=\(draftSent)")
            return
        }
        guard isViewDidAppear else {
            MailLogger.info("processDraftChange return isViewDidAppear=\(isViewDidAppear)")
            self.hasDraftChangePush = true // 标记有推送未处理
            return
        }
        if let draft_id = draft?.id, !draft_id.isEmpty {
            MailDataSource.shared.getDraftItem(draftID: draft_id).observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (serverDraft) in
                MailSendController.logger.info("get draft item in send vc when draft changelog push")
                guard let `self` = self else { return }
                self.serverDraft = serverDraft
                self.showDraftChangeAlertIfNeeded()
            }).disposed(by: self.disposeBag)
        }
    }

    func showDraftChangeAlertIfNeeded() {
        if self.draftChangeAlert == nil {
            self.draftChangeAlert = LarkAlertController()
            draftChangeAlert?.setContent(text: BundleI18n.MailSDK.Mail_SyncMessageAcrossDevice_ConfirmUpdateVersion_Notice)
            draftChangeAlert?.addSecondaryButton(text: BundleI18n.MailSDK.Mail_SyncMessageAcrossDevice_ConfirmUpdateVersion_Keep_Bttn, dismissCompletion: { [weak self] in
                guard let `self` = self else { return }
                MailTracker.log(event: "email_draft_sync_window_click",
                                params: ["click": "use_current",
                                         "window_type": "draft_expired",
                                         "mail_account_type": Store.settingData.getMailAccountType()])
                self.draftSaveChecker.saveDraftBtnClick = true
                self.doSaveDraft(param: DraftSaveCommonParam.user_save)
                self.serverDraft = nil
                self.draftChangeAlert = nil
            })
            draftChangeAlert?.addPrimaryButton(text: BundleI18n.MailSDK.Mail_SyncMessageAcrossDevice_ConfirmUpdateVersion_Update_Bttn, dismissCompletion: { [weak self] in
                guard let `self` = self else { return }
                guard let newDraft = self.serverDraft else { return }
                MailTracker.log(event: "email_draft_sync_window_click",
                                params: ["click": "update_draft",
                                         "window_type": "draft_expired",
                                         "mail_account_type": Store.settingData.getMailAccountType()])
                self.attachmentViewModel.cancelAll()
                self.processDraft(draft: newDraft)
                self.renderAttachment(attachments: newDraft.content.attachments, reload: true)
                // 相当于做了一次草稿保存，把草稿是否需要保存的相关变量置为初始状态
                self.draftSaveChecker.initDraft = newDraft
                self.draftSaveChecker.htmlContentDidChange = false
                self.draftSaveChecker.htmlContentChangeCount = 0
                self.serverDraft = nil
                self.draftChangeAlert = nil
            })
            dismissVCWhenAlert(completion: { [weak self] in
                guard let `self` = self else { return }
                self.navigator?.present(self.draftChangeAlert ?? LarkAlertController(), from: self)
                MailTracker.log(event: "email_draft_sync_window_view",
                                params: ["window_type": "draft_expired",
                                         "mail_account_type": Store.settingData.getMailAccountType()])
            })
        }
    }

    func handleDraftDisappearIfNeeded() {
        guard !draftSent, !isNewDraft else {
            MailLogger.info("handleDraftDisappear return sent=\(draftSent) isNewDraft=\(isNewDraft)")
            return
        }
        guard isViewDidAppear else {
            MailLogger.info("handleDraftDisappear return isViewDidAppear=\(isViewDidAppear)")
            self.hasThreadChangePush = true // 标记有推送未处理
            return
        }
        if let draft_id = draft?.id, !draft_id.isEmpty {
            MailDataSource.shared.getDraftItem(draftID: draft_id).observeOn(MainScheduler.instance).subscribe(onError: { [weak self] (error) in
                MailSendController.logger.info("get draft item fail in send vc when thread changelog push")
                self?.draftDeleted = true
                if self?.accountContext.featureManager.open(.draftSync, openInMailClient: true) == true {
                    self?.showDraftDisappearAlertIfNeeded(error: error)
                } else {
                    self?.showDismissTipsAlert(tips: BundleI18n.MailSDK.Mail_Compose_DraftDeleteed)
                    InteractiveErrorRecorder.recordError(event: .send_compose_has_been_deleted,
                                                         tipsType: .alert)
                }
            }).disposed(by: self.disposeBag)
        }
    }

    func showDraftDisappearAlertIfNeeded(error: Error) {
        guard error.mailErrorCode == MailErrorCode.draftBeenDeleted || error.mailErrorCode == MailErrorCode.draftBeenSent else {
            // 不是这两个错误码的走下旧逻辑兜底
            self.showDismissTipsAlert(tips: BundleI18n.MailSDK.Mail_Compose_DraftDeleteed)
            InteractiveErrorRecorder.recordError(event: .send_compose_has_been_deleted,
                                                 tipsType: .alert)
            return
        }
        if self.draftChangeAlert != nil {
            // 草稿变更的弹窗还没关掉，草稿又被删除/发送，则要先关掉变更的弹窗
            self.draftChangeAlert?.closeWith(animated: false)
            self.draftChangeAlert = nil
        }
        let alert = LarkAlertController()
        var windowTypeString = "" // 用于埋点上报
        if error.mailErrorCode == MailErrorCode.draftBeenDeleted { // 被删除
            alert.setContent(text: BundleI18n.MailSDK.Mail_SyncMessageAcrossDevice_CopyDeletedKeepCopy_Notice)
            windowTypeString = "draft_aborted"
        } else if error.mailErrorCode == MailErrorCode.draftBeenSent { // 被发送
            alert.setContent(text: BundleI18n.MailSDK.Mail_SyncMessageAcrossDevice_CopySentKeepCopy_Notice)
            windowTypeString = "draft_sent"
        }
        alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_SyncMessageAcrossDevice_CopyDeletedKeepCopy_Discard_Bttn, dismissCompletion: { [weak self] in
            guard let `self` = self else { return }
            MailTracker.log(event: "email_draft_sync_window_click",
                            params: ["click": "draft_abort",
                                     "window_type": windowTypeString,
                                     "mail_account_type": Store.settingData.getMailAccountType()])
            self.dismiss(animated: true, completion: nil)
        })
        alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_SyncMessageAcrossDevice_CopyDeletedKeepCopy_Keep_Bttn, dismissCompletion: { [weak self] in
            guard let `self` = self, var draft = self.draft else { return }
            self.getDraftHtmlContent(.getDraft, onNext: { [weak self] editorContent in
                guard let `self` = self else { return }
                if let editorContentJSON = editorContent as? [String: Any],
                   let editorData = self.convertSendContent(sendContent: editorContentJSON) {
                    self.handleEditorData(draft: &draft, editorData: editorData)
                }
                self.accountContext.dataService.rebuildDraft(draft: draft).observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (newDraft) in
                    guard let `self` = self else { return }
                    MailTracker.log(event: "email_draft_sync_window_click",
                                    params: ["click": "save_draft",
                                             "window_type": windowTypeString,
                                             "mail_account_type": Store.settingData.getMailAccountType()])
                    self.attachmentViewModel.cancelAll()
                    self.processDraft(draft: newDraft)
                    self.renderAttachment(attachments: newDraft.content.attachments, reload: true)
                    self.draftDeleted = false
                }).disposed(by: self.disposeBag)
            }, onError: nil, onCompleted: nil)
        })
        dismissVCWhenAlert(completion: { [weak self] in
            guard let `self` = self else { return }
            self.navigator?.present(alert, from: self)
            MailTracker.log(event: "email_draft_sync_window_view",
                            params: ["window_type": windowTypeString,
                                     "mail_account_type": Store.settingData.getMailAccountType()])
        })
    }

    override func pageTrackName() -> String {
        if self.baseInfo.statInfo.from == .outOfOffice {
            return "auto_reply_editor"
        } else {
            return "mail_editor"
        }
    }

    @objc
    private func networkChanged() {
        guard let reach = reachability else {
            return
        }
        guard connection != reach.connection else {
            MailLogger.info("mail network changed repeat at send")
            return
        }
        MailLogger.info("mail network changed at send")
        connection = reach.connection
    }

    private func constructAttachmentViewModel () {
        // 组装container和viewmodel
        scrollContainer.attachmentsContainer.delegate = attachmentViewModel
        attachmentViewModel.attachmentsContainer = scrollContainer.attachmentsContainer
        attachmentViewModel.updateAttachmentContainerLayout = { [weak self] toBottom in
            self?.scrollContainer.updateAttachmentContainerLayout(toBottom: toBottom)
        }
        attachmentViewModel.navigationPush = { [weak self] (vc) in
            self?.navigationController?.pushViewController(vc, animated: true)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        MailTracker.endRecordMemory(event: Homeric.MAIL_DEV_SEND_PAGE_MEMORY_DIFF, params: nil)
        isViewDidAppear = true
        showMailCoverGuideIfNeeded()
        showPriorityGuideIfNeeded()
        showReadReceiptGuideIfNeeded()
        self.scrollContainer.setupInputViewWindow()
        if !self.refocusKey.isEmpty {
            cancelModify(key: self.refocusKey)
            self.refocusKey = ""
        }
        // 处理一下未处理的推送
        if hasThreadChangePush {
            hasThreadChangePush = false
            handleDraftDisappearIfNeeded()
        }
        if hasDraftChangePush {
            hasDraftChangePush = false
            processDraftChange()
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isViewWillDisAppear = false
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isViewDidAppear = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        checkBlank()
        self.isViewWillDisAppear = true
        requestHideKeyBoard()
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] (_) in
            self?.viewDidTransition(to: size)
        }
    }

    func animationController(forDismissed dismissed: UIViewController ) -> UIViewControllerAnimatedTransitioning? {
        if lastResponderView == scrollContainer.webView {
            if dismissed.view.tag == needFocus {
                self.reFocus()
            }
        } else {
            lastResponderView?.becomeFirstResponder()
        }
        return nil
    }

    override func viewDidTransition(to size: CGSize) {
        scrollContainer.viewDidTransition(to: size, statInfo: baseInfo.statInfo)
        suggestTableView.frame.size.width = size.width
        self.dismissVCWhenTransition()
        self.updateKeyboardRelatedViews()
        self.scrollContainer.attachmentsContainer.updateAttachmentsLayout()
    }

    private func setupViews() {
        title = baseInfo.statInfo.from == .outOfOffice ? BundleI18n.MailSDK.Mail_OOO_Content_Title : ""
        setupRightBarItems()

        view.backgroundColor = UIColor.ud.bgBody
        // 容器层
        view.addSubview(scrollContainer)
        scrollContainer.frame = view.bounds
        view?.addSubview(aiMaskView)
        aiMaskView.frame = view.bounds

        scrollContainer.updateAttachmentContainerLayout()
        scrollContainer.setupViews(statInfo: baseInfo.statInfo)
        if baseInfo.statInfo.from != .outOfOffice { setupInputViews() }
    }

    func setupInputViews() {
        // 搜索推荐
        view.addSubview(shawdowHeaderView)
        view.addSubview(suggestTableView)
        shawdowHeaderView.snp.makeConstraints { (make) in
            make.edges.equalTo(suggestTableView.snp.edges)
        }
        suggestTableView.frame = view.bounds
        suggestTableView.isHidden = true
        self.scrollContainer.setupAliasInputViewIfNeeded()
    }

    @objc
    func saveOOOLetter() {
        self.needOOOSaveToast = true
        doSaveOOODraft()
        MailTracker.log(event: Homeric.EMAIL_OOO_SETTINGS_CLOSE, params: ["source": "Save"])
    }

    func setupRightBarItems() {
        if baseInfo.statInfo.from == .outOfOffice {
            let saveBtn = LKBarButtonItem(title: BundleI18n.MailSDK.Mail_CustomLabels_Save)
            saveBtn.button.tintColor = UIColor.ud.primaryContentPressed
            saveBtn.addTarget(self, action: #selector(saveOOOLetter), for: .touchUpInside)
            navigationItem.rightBarButtonItems = [saveBtn]
            return
        }

        var items: [UIBarButtonItem] = []
        /// 删除草稿
        let spaceItemWidth: CGFloat = 24
        let sendMoreSpaceWidth: CGFloat = 24

        let spaceItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        spaceItem.width = spaceItemWidth

        let sendMoreSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        sendMoreSpace.width = sendMoreSpaceWidth

        let moreBtn = UIButton(type: .custom)
        moreBtn.setImage(UDIcon.moreOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        moreBtn.tintColor = UIColor.ud.iconN1
        moreBtn.addTarget(self, action: #selector(onClickMore), for: .touchUpInside)
        moreBtn.accessibilityIdentifier = MailAccessibilityIdentifierKey.BtnSendMoreKey
        let moreItem = MailBarButtonItem(customView: moreBtn)
        moreItem.tintColor = UIColor.ud.iconN1
        self.moreBtn = moreBtn

        /// 发送
        let sendBtn = UIButton(type: .custom)
        sendBtn.setImage(UDIcon.sendFilled.withRenderingMode(.alwaysTemplate), for: .normal)
        sendBtn.tintColor = UIColor.ud.iconN1
        sendBtn.rx.throttleTap.subscribe(onNext: { [weak self] in
            self?.onClickSendMail()
        }).disposed(by: disposeBag)
        let sendItem = MailBarButtonItem(customView: sendBtn)
        sendItem.tintColor = UIColor.ud.iconN1
        sendBtn.accessibilityIdentifier = MailAccessibilityIdentifierKey.BtnSendSendKey
        self.sendButton = sendBtn
        items.append(spaceItem)
        items.append(sendItem)
        items.append(sendMoreSpace)
        items.append(moreItem)
        navigationItem.rightBarButtonItems = items.reversed()
    }

    func updateSuggestTableView(_ searchResultCount: Int = 0) {
        suggestTableView.setContentOffset(CGPoint.zero, animated: false) // 如果有新的输入移动到顶部
        if let inputView = editionInputView {
            shawdowHeaderView.isHidden = true
            if suggestTableView.isHidden {
                suggestTableView.isHidden = false
            }
            var newFrame = suggestTableView.frame
            let point = scrollContainer.convert(inputView.frame, to: view)
            newFrame.origin.y = point.minY + inputView.frame.height
            let y = mainToolBar?.frame.minY ?? 200
            let height = y - newFrame.origin.y
            newFrame.size.height = height
            suggestTableView.frame = newFrame
            suggestTableView.layer.cornerRadius = 0
        } else {
            if !suggestTableView.isHidden {
                suggestTableView.isHidden = true
                searchContactAbortFinish(resultCount: searchResultCount)
            }
        }
        self.updateKeyboardBinding()
    }

    func searchContactAbortFinish(resultCount: Int) {
        dataProvider.trackContactSearchFinish(type: .abort, resultCount: resultCount, selectRank: 0, contactVM: nil, fromAddress: draft?.content.from)
    }

    func showDismissTipsAlert(tips: String) {
        let alert = LarkAlertController()
        alert.setContent(text: tips, alignment: .center)
        alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_Alert_OK, dismissCompletion: { [weak self] in
            guard let `self` = self else { return }
            self.dismiss(animated: true, completion: nil)
        })
        navigator?.present(alert, from: self)
    }

    func isUploadFileComplete() -> Bool {
        guard let imageHandler = pluginRender?.imageHandler else { return false }
        let imgUploadComplete = !(imageHandler.isContainsUploadingImg || imageHandler.isContainsErrorImg)
        return attachmentViewModel.isFinished && imgUploadComplete
    }

    func onClickAlias(_ emailAlias: EmailAlias) {
        /// hide keyboard
        requestHideKeyBoard()
        scrollContainer.webView.endEditing(true)
        let shouldShowEdit = accountContext.sharedServices.featureManager.open(FeatureKey(fgKey: .sendMailNameSetting, openInMailClient: true))
        let aliasList = AliasListController(emailAlias.allAddresses,
                                            scrollContainer.fromInputView.aliasAddress,
                                            type: .alias,
                                            showEditButton: shouldShowEdit)
        aliasList.delegate = self
        navigator?.present(aliasList, from: self, animated: false, completion: nil)
    }
#if ALPHA || DEBUG
    func showDraftDebugData() {
        if let model = self.draft?.toPBModel() {
            let vc = MailDetailDataVC()
            vc.detailData = model.debugDescription
            navigator?.push(vc, from: self, animated: true)
        }
    }
#endif

    @objc
    func onClickMore() {
        /// hide keyboard
        requestHideKeyBoard()
        scrollContainer.webView.endEditing(true)
        showMoreActionView()
    }

    private func getMoreActionItems() -> [MailActionItemProtocol] {
        var actionItems: [MailActionItemProtocol] = []

        // -- 邮件优先级 --
        if accountContext.featureManager.open(.mailPriority, openInMailClient: false) {
            let priority: MailPriorityType = self.draft?.content.priorityType ?? .normal
            let priorityAction = MailActionStatusItem(title: BundleI18n.MailSDK.Mail_EmailPriority_AdvancedSettings_EmailPriority,
                                                      actionType: .priority,
                                                      udGroupNumber: ActionType.priority.mailSendGroupNumber,
                                                      status: priority.toStatusText(),
                                                      actionCallBack: { [weak self] _ in
                guard let `self` = self else { return }
                let vc = MailSendPriorityController(delegate: self, priority: priority)
                let nav = LkNavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                self.navigator?.present(nav, from: self)
            })
            actionItems.append(priorityAction)
        }

        // -- 已读回执 --
        if accountContext.featureManager.open(.readReceipt, openInMailClient: false) {
            let needReadReceipt: Bool = self.draft?.content.needReadReceipt ?? false
            let readReceiptAction = MailActionSwitchItem(title: BundleI18n.MailSDK.Mail_ReadReceiptFeature_Toggle,
                                                         actionType: .readReceipt,
                                                         udGroupNumber: ActionType.readReceipt.mailSendGroupNumber,
                                                         status: needReadReceipt,
                                                         actionCallBack: { [weak self] status in
                guard let `self` = self else { return }
                self.draft?.content.needReadReceipt = status
                let event = NewCoreEvent(event: .email_email_edit_click)
                event.params = ["target": "none",
                                "click": status ? "read_receipt_on" : "read_receipt_off",
                                "edit_type": MailTracker.editType(type: self.trackerSourceType) ?? ""]
                event.post()
            })
            actionItems.append(readReceiptAction)
        }

        // -- 定时发送 --
        if !Store.settingData.mailClient {
            var scheduleSendAction = MailActionItem(title: BundleI18n.MailSDK.Mail_SendLater_ScheduleSend,
                                                    icon: UDIcon.sentScheduledOutlined.withRenderingMode(.alwaysTemplate),
                                                    actionType: .scheduleSend,
                                                    udGroupNumber: ActionType.scheduleSend.mailSendGroupNumber,
                                                    actionCallBack: { [weak self] _ in
                self?.onClickScheduleSend()
            })
            let enableScheduleBtn = checkSendButtonEnable() && self.draft?.calendarEvent == nil
            scheduleSendAction.disable = !enableScheduleBtn
            actionItems.append(scheduleSendAction)
        }

        // -- 分别发送 --
        if accountContext.featureManager.open(.sendSeparaly), isShowSeparateSendEnable {
            let separalyAction = MailActionItem(title: spWording,
                                                icon: UDIcon.forwardComOutlined.withRenderingMode(.alwaysTemplate),
                                                actionType: .sendSeparaly,
                                                udGroupNumber: ActionType.sendSeparaly.mailSendGroupNumber,
                                                actionCallBack: { [weak self] _ in
                self?.changeSendSeparately()
            })
            actionItems.append(separalyAction)
        }

        // -- 保存草稿 --
        let saveDraftAction = MailActionItem(title: BundleI18n.MailSDK.Mail_Alert_SaveDraft,
                                             icon: UDIcon.filelinkSaveOutlined.withRenderingMode(.alwaysTemplate),
                                             actionType: .saveDraft,
                                             udGroupNumber: ActionType.saveDraft.mailSendGroupNumber,
                                             actionCallBack: { [weak self] _ in
            self?.onClickSaveDraftInMoreMenu()
        })
        actionItems.append(saveDraftAction)

        // -- 丢弃草稿 --
        let discardDraftAction = MailActionItem(title: BundleI18n.MailSDK.Mail_Alert_DiscardDraft,
                                                icon: UDIcon.deleteTrashOutlined.withRenderingMode(.alwaysTemplate),
                                                actionType: .discardDraft,
                                                udGroupNumber: ActionType.discardDraft.mailSendGroupNumber,
                                                actionCallBack: { [weak self] _ in
            self?.onClickDiscardDraftInMoreMenu()
        })
        actionItems.append(discardDraftAction)

        return actionItems
    }

    private func showMoreActionView() {
        var sections = [MoreActionSection]()
        var sectionItems = getMoreActionItems()
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
            let debugItem = MailActionItem(title: "draft data",
                                           icon: Resources.mail_action_reedit.withRenderingMode(.alwaysTemplate),
                                           udGroupNumber: 1000,
                                           actionCallBack: { [weak self] _ in
                guard let `self` = self else { return }
                self.showDraftDebugData()
            })
            sections.append(MoreActionSection(layout: .vertical, items: [debugItem]))
        }
#endif
        var headerTitle = ""
        if let text = self.scrollContainer.getSubjectText(), !text.isEmpty {
            headerTitle = text
        } else {
            headerTitle = BundleI18n.MailSDK.Mail_ThreadList_TitleEmpty
        }
        var subtitle = ""
        if let from = self.draft?.fromName {
            subtitle = BundleI18n.MailSDK.Mail_Normal_FromColon + "\(from)"
        }
        let headerConfig = MoreActionHeaderConfig(iconType: .image(Resources.mail_action_mail_icon),
                                                  title: headerTitle,
                                                  subtitle: subtitle)
        let popoverSourceView = rootSizeClassIsSystemRegular ? moreBtn : nil
        // Thread
        presentMoreActionVC(headerConfig: headerConfig,
                            sectionData: sections,
                            popoverSourceView: popoverSourceView,
                            popoverRect: popoverSourceView?.bounds)
    }

    // delegate: MailSendPriorityDelegate
    func updatePriority(_ priority: MailPriorityType) {
        self.draft?.content.priorityType = priority
        self.scrollContainer.setMailPriority(priority)
        let event = NewCoreEvent(event: .email_email_edit_click)
        event.params = ["target": "none",
                        "click": "mail_priority",
                        "edit_type": MailTracker.editType(type: self.trackerSourceType) ?? "",
                        "priority": priority.toTracker()]
        event.post()
    }

    private func discardDraftInMoreAction() {
        draftSaveChecker.discardDraft = true
        MailLogger.info("Discard Draft")
        MailTracker.log(event: Homeric.EMAIL_DRAFT_DISCARD, params: [MailTracker.sourceParamKey(): MailTracker.source(type: .editorDeleteButton), MailTracker.isMultiselectParamKey(): false])
        self.discardDraft()
        self.closeMe()
        MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_Toast_DraftDiscarded, on: self.view)
    }

    func changeSendSeparately() {
        let isSp = draft?.isSendSeparately == true
        draft?.isSendSeparately = !isSp
        scrollContainer.setIsSp(isSp: draft?.isSendSeparately ?? false)
        scrollContainer.toInputView.textField.becomeFirstResponder()
        if draft?.isSendSeparately == true {
            let source: String
            switch action {
            case .reply:
                source = "reply"
            case .replyAll:
                source = "reply all"
            case .forward:
                source = "forward"
            default:
                source = "Draft"
            }
            MailTracker.log(event: "email_add_send_separately", params: ["source": source])
        } else {
            MailTracker.log(event: "email_cancle_send_separately", params: nil)
        }
    }

    func onClickScheduleSend() {
        Store.settingData.storageLimitCheck(from: self, navigator: accountContext.navigator) { [weak self] in
            // 这里先进行检查，暂不发送
            self?.prepareMailContent(.scheduleSendCheck)
        }
    }

    func onClickSaveDraftInMoreMenu() {
        if self.hasFailedOrUploadingImages() {
            let alert = LarkAlertController()
            alert.setContent(text: BundleI18n.MailSDK.Mail_Draft_Uploadingimages, alignment: .center)
            alert.addCancelButton()
            alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_Alert_OK, dismissCompletion: {
                self.needsSaveDraftToast = true
                self.draftSaveChecker.saveDraftBtnClick = true
                self.pluginRender?.imageHandler?.removeFailedImgs()
                self.doSaveDraft(param: DraftSaveCommonParam.user_save)
            })
            navigator?.present(alert, from: self)
            InteractiveErrorRecorder.recordError(event: .send_more_save_draft_uploading_image, tipsType: .alert)
        } else {
            needsSaveDraftToast = true
            draftSaveChecker.saveDraftBtnClick = true
            self.doSaveDraft(param: DraftSaveCommonParam.user_save)
        }
    }

    func onClickDiscardDraftInMoreMenu() {
        if self.needShowDiscardAlert() {
            let alert = LarkAlertController()
            alert.setContent(text: BundleI18n.MailSDK.Mail_Alert_DiscardThisMessage, alignment: .center)
            alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_Alert_Cancel)
            alert.addDestructiveButton(text: BundleI18n.MailSDK.Mail_Alert_Discard, dismissCompletion: {
                self.discardDraftInMoreAction()
                MailTracker.draftLog(event: .draftAbort)
            })
            navigator?.present(alert, from: self)
        } else {
            self.discardDraftInMoreAction()
        }
    }

    private func needShowDiscardAlert() -> Bool {
        if isCreateNewDraftScene() {
            if let draft = self.draft, checkSaveDraftEnable(draft: draft) {
                return true
            }
            return false
        } else {
            return true
        }
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
        callback(headerConfig, sectionData, popoverSourceView)
    }

    /// 由本地文件 -> 发送邮件类型
    func createMailSendAttachments(localFiles: [MailSendFileInfoProtocol]) -> [MailSendAttachment] {
        var type: MailClientAttachement.AttachmentType = .small
        if accountContext.featureManager.open(.largeAttachment) {
            if (localFiles.first?.size ?? 0) > attachmentViewModel.availableSize {
                type = .large
            }
        }
        let attachments = localFiles.map { (file) -> MailSendAttachment in
            let hashKey = "\(file.name)_\(Date().timeIntervalSince1970)"
            var res = MailSendAttachment.init(displayName: file.name,
                                              fileExtension: MainAttachmentType.init(fileExtension: file.fileURL.pathExtension.lowercased()),
                                              fileSize: Int(file.size ?? 0), type: type)
            res.attachObject = file
            res.fileInfo = file
            res.hashKey = hashKey
            if type == .large && !accountContext.featureManager.open(.largeAttachmentManage, openInMailClient: false) {
                res.expireTime = MailSendAttachment.genExpireTime()
            }
            return res
        }
        return attachments
    }

    // MARK: action handler
    @objc
    func didClickAddAttachment() {
        if Store.settingData.mailClient {
            MailLogger.info("[mail_client_attach] doSaveDraft")
            doSaveDraft(param: .mail_client_save)
        }
        /// 计算可用大小
        let availableSize = attachmentViewModel.availableSize
        let attachmentFG = accountContext.featureManager.open(.largeAttachment)
        let singleMaxSize = attachmentFG ? MailSendAttachmentViewModel.singleAttachemntMaxSize : availableSize
        let sizeGB = singleMaxSize / (1024 * 1024 * 1024)
        let limitSize = String("\((contentChecker.mailLimitSize)) MB")
        let wording = attachmentFG ? BundleI18n.MailSDK.Mail_Attachment_MaximumFileSize(sizeGB) :
            BundleI18n.MailSDK.Mail_Attachment_OverLimit(limitSize)

        /// 拉起文件选择器。
        var body = LocalFileParams()
        let chooseFileBlock: ([MailSendFileInfoProtocol]) -> Void = { [weak self] (files) in
            // 添加附件并且
            if let `self` = self {
                self.doSaveDraft(param: .mail_client_save)
                let attachments = self.createMailSendAttachments(localFiles: files)
                let types = attachments.map { (attachment) -> DriveFileType in
                    DriveFileType(fileExtension: attachment.fileExtension.rawValue)
                }
                for att in attachments where att.fileSize > singleMaxSize {
                    MailLogger.info("[mail_client_attach] att.fileSize: \(att.fileSize) availSize \(singleMaxSize)")
                    if Store.settingData.mailClient {
                        DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.normal) {
                            let alert = LarkAlertController()
                            alert.setTitle(text: BundleI18n.MailSDK.Mail_ThirdClient_FailedToUpload)
                            alert.setContent(text: BundleI18n.MailSDK.Mail_ThirdClient_FailedToUploadDesc)
                            alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_ThirdClient_FailedToUploadConfirm)
                            self.navigator?.present(alert, from: self)
                        }
                    } else {
                        MailRoundedHUD.showFailure(with: wording, on: self.view,
                                                   event: ToastErrorEvent(event: .send_insert_attachment_overlimit))
                    }
                    return
                }
                var pureAttachments = attachments.filter { (item) -> Bool in
                    let type = DriveFileType(fileExtension: item.fileExtension.rawValue)
                    return !type.isHarmful
                }
                var sumSize = 0
                pureAttachments.forEach { item in
                    sumSize += item.fileSize
                }
                // 校验邮箱总容量

                MailLogger.info("[mail_client_attach] sumSize: \(sumSize) availSize \(self.attachmentViewModel.availableSize)")
                let insertBlock: ([MailSendAttachment], [MailSendAttachment], [DriveFileType]) -> Void = { [weak self] (pureAttachments, attachments, types) in
                    guard let `self` = self else { return }
                    self.scrollContainer.attachmentsContainer.addAttachments(pureAttachments, permCode: self.baseInfo.mailItem?.code)
                    self.attachmentViewModel.appendAttachments(pureAttachments, toBottom: true)
                    MailTracker.log(event: Homeric.EMAIL_DRAFT_ADD_ATTACHMENT, params: [MailTracker.sourceParamKey(): MailTracker.source(type: .toolbar)])
                    for attachment in attachments {
                        // event
                        let event = NewCoreEvent(event: .email_email_edit_click)
                        event.params = ["target": "none",
                                        "click": "attachment",
                                        "attachment_type": "recent_files",
                                        "is_large": attachment.type == .large ? "true" : "false"]
                        event.post()
                    }
                    let harmfulCount = types.filter({ $0.isHarmful }).count
                    if harmfulCount > 0 {
                        let alert = LarkAlertController()
                        alert.setTitle(text: BundleI18n.MailSDK.Mail_AttachmentsBlockedNum_Title(harmfulCount))
                        alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_UnableToDownloadHighRiskSingularGotIt_Button)
                        let text = BundleI18n.MailSDK.Mail_AttachmentsBlockedCompose_Desc(harmfulCount) + BundleI18n.MailSDK.Mail_AttachmentsBlockedLearnMore_Button
                        let actionableText = BundleI18n.MailSDK.Mail_AttachmentsBlockedLearnMore_Button
                        let textView = ActionableTextView.alertWithLinkTextView(text: text,
                                                                                actionableText: actionableText,
                                                                                action: {
                            guard let configString = ProviderManager.default.commonSettingProvider?.stringValue(key: "attachment-harmful"),
                                  let url = URL(string: configString) else { return }
                            UIApplication.shared.open(url)
                        })
                        alert.setContent(view: textView, padding: UIEdgeInsets(top: 12, left: 20, bottom: 24, right: 20))
                        // must delay to wait for the file vc disappear
                        DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.normal) {
                            self.navigator?.present(alert, from: self)
                            InteractiveErrorRecorder.recordError(event: .send_select_attachment_blocked,
                                                                 tipsType: .alert)
                        }
                    }
                }
                if sumSize > self.attachmentViewModel.availableSize {
                    if Store.settingData.mailClient {
                        DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.normal) {
                            let alert = LarkAlertController()
                            alert.setTitle(text: BundleI18n.MailSDK.Mail_ThirdClient_FailedToUpload)
                            alert.setContent(text: BundleI18n.MailSDK.Mail_ThirdClient_FailedToUploadDesc)
                            alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_ThirdClient_FailedToUploadConfirm)
                            self.navigator?.present(alert, from: self)
                        }
                        return
                    } else {
                        if self.accountContext.featureManager.open(.largeAttachmentManage, openInMailClient: false) {
                            if self.accountContext.featureManager.open(.largeAttachmentManagePhase2, openInMailClient: false) {
                                // must delay to wait for the file vc disappear
                                DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.normal + 0.2) {
                                    LarkAlertController.showAttachmentAlert(accountContext: self.accountContext, from: self, navigator: self.accountContext.navigator, limitSize: limitSize, userStore: self.accountContext.userKVStore) {
                                        var leftSize = self.attachmentViewModel.availableSize
                                        pureAttachments = pureAttachments.map { item -> MailSendAttachment in
                                            var item = item
                                            if item.fileSize > leftSize {
                                                item.type = .large
                                                item.expireTime = 0
                                            } else {
                                                leftSize = leftSize - item.fileSize
                                                item.type = .small
                                                item.expireTime = 0
                                            }
                                            return item
                                        }
                                        insertBlock(pureAttachments, attachments, types)
                                    }
                                }
                            } else {
                                var leftSize = self.attachmentViewModel.availableSize
                                pureAttachments = pureAttachments.map { item -> MailSendAttachment in
                                    var item = item
                                    if item.fileSize > leftSize {
                                        item.type = .large
                                        item.expireTime = 0
                                    } else {
                                        leftSize = leftSize - item.fileSize
                                        item.type = .small
                                        item.expireTime = 0
                                    }
                                    return item
                                }
                                insertBlock(pureAttachments, attachments, types)
                            }
                        } else if self.accountContext.featureManager.open(.largefileUploadOpt) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.normal) {
                                let alert = self.largeFileAlert(num: pureAttachments.count)
                                alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_Common_Confirm, dismissCompletion: { [weak self] in
                                    guard let `self` = self else { return }
                                    var leftSize = self.attachmentViewModel.availableSize
                                    pureAttachments = pureAttachments.map { item -> MailSendAttachment in
                                        var item = item
                                        if item.fileSize > leftSize {
                                            item.type = .large
                                            item.expireTime = MailSendAttachment.genExpireTime()
                                        } else {
                                            leftSize = leftSize - item.fileSize
                                            item.type = .small
                                            item.expireTime = 0
                                        }
                                        return item
                                    }
                                    insertBlock(pureAttachments, attachments, types)
                                })
                                self.navigator?.present(alert, from: self)
                            }
                        } else {
                            pureAttachments = pureAttachments.map { item -> MailSendAttachment in
                                var item = item
                                item.type = .large
                                item.expireTime = MailSendAttachment.genExpireTime()
                                return item
                            }
                            insertBlock(pureAttachments, attachments, types)
                        }

                    }
                } else {
                    insertBlock(pureAttachments, attachments, types)
                }
            }
        }
        body.maxTotalFileSize = attachmentFG ? nil : availableSize
        body.maxSingleFileSize = singleMaxSize
        if Store.settingData.mailClient {
            body.maxTotalFileSize = nil
            body.maxSingleFileSize = nil
        }
        body.chooseLocalFiles = chooseFileBlock
        body.title = BundleI18n.MailSDK.Mail_Attachment_ReceivedFiles
        body.extraPaths = [getLocalFileDir()]
        _ = scrollContainer.webView.resignFirstResponder()
        accountContext.provider.fileProvider?.presentLocalFilePicker(params: body, wrap: MailNavigationController.self, fromVC: self) { [weak self] in
            guard let `self` = self else { return }
            if self.lastResponderView == self.scrollContainer.webView {
                self.reFocus()
            } else {
                self.lastResponderView?.becomeFirstResponder()
            }
        }
    }

    func reFocus() {
        _ = self.scrollContainer.webView.becomeFirstResponder()
        self.scrollContainer.webView.focusAtEditor()
    }

    /// 关闭当前页面
    func closeMe() {
        stopListenKeyBoard()
        super.closeBtnTapped()
        // 关闭草稿后重新预加载一个新的
        accountContext.editorLoader.preloadEditor(reNewOne: true)
        //请求新签名
        _ = Store.settingData.getCurrentSigListData().subscribe()
    }

    override func closeBtnTapped() {
        self.scrollContainer.webView.cleanEditorReloadTimer()
        requestHideKeyBoard()
        scrollContainer.webView.endEditing(true)

        needsSaveDraftToast = true

        let superAction = super.closeBtnTapped

        let closeAction = { [weak self] in
            guard let `self` = self else { return }
            /// 停止键盘监听，防止crash
            self.stopListenKeyBoard()
            if self.mentionFg() {
                self.setMentionDic()
            }
            if self.baseInfo.statInfo.from == .outOfOffice {
                self.doSaveOOODraft()
            } else {
                superAction()
                if !self.draftSent {
                    if self.doSaveDraft(param: DraftSaveCommonParam.user_save) {
                        self.holdVC = self
                        // 大邮件保存，耗时久，可能vc已经销毁导致保存失败。这里hold住，保存后释放
                        //超过15s自动释放
                        DispatchQueue.main.asyncAfter(deadline: .now() + self.holdVCMaxTime) { [weak self] in
                            self?.holdVC = nil
                        }
                    }
                }
            }

            if !self.scrollContainer.webView.isReady {
                MailLogger.info("draftId=\(self.draft?.threadID ?? "")")
                let reloadCount = self.scrollContainer.webView.reloadCount
                let stayTime = Int(Date().timeIntervalSince(self.initDate ?? Date()) * 1000)
                MailTracker.log(event: "mail_editor_timeout_reload",
                                params: ["retryCount": reloadCount,
                                         "scene": "close",
                                         "stayTime": stayTime])
            }
            if self.removeScheduleLoading {
                MailRoundedHUD.remove(on: self.view)
            }
            // 关闭草稿后重新预加载一个新的
            self.accountContext.editorLoader.preloadEditor(reNewOne: true)
            //请求新签名
            _ = Store.settingData.getCurrentSigListData().subscribe()

            self.closeSceneIfNeeded()
        }

        if baseInfo.statInfo.from == .outOfOffice {
            if self.draftSaveChecker.htmlContentDidChange {
                let alert = LarkAlertController()
                alert.setTitle(text: BundleI18n.MailSDK.Mail_OOO_Content_Exit)
                alert.setContent(text: BundleI18n.MailSDK.Mail_OOO_Exit_Confirm, alignment: .center)
                alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_Alert_Discard, dismissCompletion: { [weak self] in
                    MailTracker.log(event: Homeric.EMAIL_OOO_SETTINGS_CLOSE, params: ["source": "Discard"])
                    /// 停止键盘监听，防止crash
                    self?.stopListenKeyBoard()
                    self?.dismiss(animated: true, completion: nil)
                })
                alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_CustomLabels_Save, dismissCompletion: { [weak self] in
                    MailRoundedHUD.showLoading(with: BundleI18n.MailSDK.Mail_OOO_Saving, on: self?.view ?? UIView(), disableUserInteraction: false)
                    MailTracker.log(event: Homeric.EMAIL_OOO_SETTINGS_CLOSE, params: ["source": "Save"])
                    if self != nil {
                        closeAction()
                    }
                })
                navigator?.present(alert, from: self)
            } else {
                MailTracker.log(event: Homeric.EMAIL_OOO_SETTINGS_CLOSE, params: ["source": "CloseBtn"])
                closeAction()
                dismiss(animated: true, completion: nil)
            }
        } else {
            if isUploadFileComplete() {
                closeAction()
            } else { // 如果有文件未上传完跪舔一下用户
                showUnfinishedChangeAlertIfNeeded(cancelHandler: nil) { [weak self] in
                    if self != nil {
                        self?.pluginRender?.imageHandler?.removeFailedImgs()
                        closeAction()
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

    // MARK: - 页面滚动处理 UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        _scrollViewDidScroll(scrollView)
    }
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        _scrollViewWillBeginDragging(scrollView)
    }

    // MARK: - RenderDelegate - EditorPluginRenderDelegate
    func didRenderFail() {
        apmSendLoadEnd(status: .status_exception)
    }

    func didRenderMail(param: [String: Any]) {
        EditorPluginRender.renderFinishTrack(nil)

        if baseInfo.statInfo.from != .outOfOffice {
            if draftSaveChecker.initDraft == nil && draft != nil {
                draftSaveChecker.initDraft = draft
            }
        }
        if accountContext.editorLoader.forceUnziped {
            // 成功了
            MailTracker.log(event: "mail_editor_js_err_dev",
                            params: ["error_type": "UnexpectedEnd",
                                     "sence": "recovered"])
        }
        apmSendLoadEnd(status: .status_success, renderParam: param)
        self.renderSuccess = true
        if let initDraft = self.draft {
            let text = initDraft.content.bodySummary.trimmingCharacters(in: .whitespacesAndNewlines)
            self.hasContent = !text.isEmpty
        }

        if let toolbarParam = self.scrollContainer.webView.toolBarParam {
            pluginRender?.cacheSetToolBar(params: toolbarParam)
        }
        if !self.baseInfo.statInfo.emlAsAttachmentInfos.isEmpty {
            //走emlAsAttachment逻辑
            setViewLoadingStatus(isLoading: false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.insertEmlAttachment(infos: self.baseInfo.statInfo.emlAsAttachmentInfos)
            }
        } else {
            focusEditor()
        }

        // update calendar icon status
        updateCalendarIcon()
        getCalendarTemplate()
        /// 更新签名
        if accountContext.featureManager.realTimeOpen(.enterpriseSignature),
           self.action != .outOfOffice,
           scrollContainer.needRefreshSignature,
           let sigData = Store.settingData.getCachedCurrentSigData(),
           let currentAddress = scrollContainer.currentAddressEntity {
            self.scrollContainer.webView.sigId = nil
            if let dic = self.genSignatureDicByAddres(sigData: sigData, address: currentAddress) {
                pluginRender?.resetSignature(address: currentAddress.address, dic: dic)
            }

        }
        if accountContext.featureManager.realTimeOpen(.enterpriseSignature) {
            // get signatureID
            self.pluginRender?.getSignatureID()
        }
        if accountContext.featureManager.open(.massiveSendRemind, openInMailClient: false) {
            // 获取Admin发信规模限制配置
            // 这是一个静默流程，用户无感知，为降低对草稿加载速度的影响，放在 renderDone 之后
            MailDataServiceFactory.commonDataService?.mailGetRecipientCountLimit().subscribe(onNext: { [weak self] res in
                guard let self = self else { return }
                if res.config.enableRecipientLimitRemind {
                    self.recipientLimitEnable = true
                    self.recipientLimit = res.config.recipientLimitCount
                    self.checkRecipientCount()
                } else {
                    self.recipientLimitEnable = false
                    self.recipientLimit = 0
                }
            }).disposed(by: self.disposeBag)
        }
        if FeatureManager.open(.docAuthOpt, openInMailClient: false) {
            let jsStr = "window.command.fetchDocBlockUrls()"
            self.evaluateJavaScript(jsStr)
        }
        if openAIFG() && self.baseInfo.statInfo.from != .outOfOffice &&
            (self.action == .new ||
                          self.action == .reply ||
                          self.action == .replyAll) {
            let event = NewCoreEvent(event: .email_email_edit_myai_view)
            event.params = ["target": "none",
                            "label_item": baseInfo.statInfo.newCoreEventLabelItem,
                            "show_type": "blank_mail",
                            "mail_account_type": Store.settingData.getMailAccountType()]
            event.post()
        }
        let show = (openAIFG() && self.baseInfo.statInfo.from != .outOfOffice) ? "true" : "false"
        let event = NewCoreEvent(event: .email_editor_right_menu_view)
        event.params = ["target": "none",
                        "is_myai_show": show,
                        "select_content": "false",
                        "label_item": baseInfo.statInfo.newCoreEventLabelItem,
                        "show_type": "blank_mail",
                        "mail_account_type": Store.settingData.getMailAccountType()]
        event.post()
    }

    func cacheSetToolBar(param: [String: Any]) {
        pluginRender?.cacheSetToolBar(params: param)
    }

    func focusEditor() {
        setViewLoadingStatus(isLoading: false)
        self.focusWhenFirstEnter()
    }

    func focusWhenFirstEnter() {
        for view in scrollContainer.contentView.arrangedSubviews {
            if !view.isHidden {
                if view is LKTokenInputView && view == self.scrollContainer.toInputView {
                    if let isEmpty = (view as? LKTokenInputView)?.tokens.isEmpty, isEmpty {
                        (view as? LKTokenInputView)?.beginEditing()
                        return
                    }
                } else if view == self.scrollContainer.subjectCoverInputView {
                    if let inputView = (view as? MailSubjectFieldView), inputView.textView.text.isEmpty {
                        inputView.textView.isEditable = true
                        inputView.becomeFirstResponder()
                        self.registerTabKey(currentView: view)
                        return
                    }
                }  else if view is MailCoverDisplayView {
                    if let coverView = (view as? MailCoverDisplayView), coverView.textView.text.isEmpty {
                        coverView.becomeFirstResponder()
                        self.registerTabKey(currentView: coverView)
                        return
                    }
                } else if view is MailSendWebView {
                    _ = (view as? MailSendWebView)?.becomeFirstResponder()
                    (view as? MailSendWebView)?.focusAtEditorBegin()
                    self.selectionPosition = EditorSelectionPosition(top: 0, left: 0, height: 0)
                    self.unregisterTabKey(currentView: view)
                    self.unregisterLeftKey(currentView: view)
                    self.unregisterRightKey(currentView: view)
                    return
                }
            }
        }
    }
    func resetEditorView(editor: MailSendWebView) {
        scrollContainer.setEditorView(editor: editor)
    }

    /// 丢弃草稿
    func discardDraft() {
        var tempThreadID : String?
        if let tempfeedCardId = self.feedCardId, !tempfeedCardId.isEmpty {
            tempThreadID = draft?.threadID
        } else {
            tempThreadID = baseInfo.threadID
        }
        if let draftId = draft?.id, let threadID = tempThreadID {
            threadActionDataManager.deleteDraft(draftID: draftId, threadID: threadID, feedCardId: self.feedCardId, onSuccess: { [weak self] in
                guard let self = self else { return }
                self.ondiscard?(draftId)
                MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_Toast_DraftDiscarded, on: self.view)
                self.closeSceneIfNeeded()
            }, onError: { [weak self] in
                guard let self = self else { return }
                MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Toast_OperationFailed, on: self.view,
                                           event: ToastErrorEvent(event: .send_discard_draft_fail))
                self.closeSceneIfNeeded()
            })
        }
    }

    func doSaveDraft(param: DraftSaveCommonParam) -> Bool {
        guard !draftSaveChecker.discardDraft else { return false }
        guard !draftDeleted else { return false }
        guard !draftSent else { return false }
        if self.action == .outOfOffice &&
            (param == .auto_save ||
             param == .background_save) {
            // ooo不需要自动保存功能
            return false
        }
        let size = self.draft?.content.bodyHtml.count ?? 0
        apmSaveDraftStart(param: param)
        getDraftHtmlContent(onNext: { [weak self] _ in
            MailTracker.draftLog(event: .draftSave)
            MailLogger.info("success in dave draft")
            self?.isNewDraft = false
        }, onError: { [weak self] (error) in
            MailLogger.error("error in dave draft \(error)")
            guard let `self` = self else { return }
            let size = MailAPMEvent.SaveDraft.EndParam.mail_body_length(size)
            self.apmHolder[MailAPMEvent.SaveDraft.self]?.endParams.append(size)
            self.apmSaveDraftEnd(status: .status_rust_fail, error: error)
            MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Toast_DraftSavingError, on: self.view,
                                       event: ToastErrorEvent(event: .send_save_draft_fail))
        })
        return true
    }

    func doSaveOOODraft() {
        func getDraftHtmlAndSave(size: Int) {
            self.pluginRender?.imageHandler?.removeFailedImgs()

            getDraftHtmlContent(onNext: { _ in
            }, onError: { [weak self] (error) in
                MailLogger.error("error in dave draft \(error)")
                guard let `self` = self else { return }
                let size = MailAPMEvent.SaveDraft.EndParam.mail_body_length(size)
                self.apmHolder[MailAPMEvent.SaveDraft.self]?.endParams.append(size)
                self.apmSaveDraftEnd(status: .status_rust_fail, error: error)
                MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Toast_DraftSavingError, on: self.view)
            })
        }
        let bodyLimit = 20000
        guard (draft?.content.bodyHtml.count ?? 0) < bodyLimit else {
            MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_OOO_Body_Limit, on: self.view,
                                       event: ToastErrorEvent(event: .ooo_save_draft_body_limit_fail, userCause: true))
            return
        }
        self.apmSaveDraftStart(param: DraftSaveCommonParam.ooo_save)
        let size = self.draft?.content.bodyHtml.count ?? 0
        if !isUploadFileComplete() {
            showUnfinishedChangeAlertIfNeeded(cancelHandler: { [weak self] in
                MailRoundedHUD.remove(on: self?.view ?? UIView())
            }, completion: {
                getDraftHtmlAndSave(size: size)
            })
        } else {
            getDraftHtmlAndSave(size: size)
        }
    }

    func showUnfinishedChangeAlertIfNeeded(cancelHandler:(() -> Void)? = nil, completion: (() -> Void)? = nil) {
        let alert = LarkAlertController()
        var alertContent = ""
        var alertButtonTxt = ""
        var alertSubTxt = ""
        guard let imageHandler = pluginRender?.imageHandler else { return }

        let imgUploadComplete = !(imageHandler.isContainsUploadingImg || imageHandler.isContainsErrorImg)
        if !attachmentViewModel.isFinished && !imgUploadComplete {
            alertSubTxt = BundleI18n.MailSDK.Mail_Alert_QuitAttachmentUnfinished_ImageAndAttachment
        } else if !attachmentViewModel.isFinished {
            alertSubTxt = BundleI18n.MailSDK.Mail_Alert_QuitAttachmentUnfinished_Attachment
        } else {
            alertSubTxt = BundleI18n.MailSDK.Mail_Alert_QuitAttachmentUnfinished_Image
        }


        if baseInfo.statInfo.from == .outOfOffice { //保存草稿
            if imageHandler.isContainsUploadingImg || !attachmentViewModel.isFinished { //文件上传中的场景
                alertContent = BundleI18n.MailSDK.Mail_Alert_ContentUploadingNowSaveToDelete_Title(alertSubTxt)
            } else if imageHandler.isContainsErrorImg || attachmentViewModel.isExistError { //文件上传失败
                alertContent = BundleI18n.MailSDK.Mail_Normal_Uploadimagefailed_Varibles(alertSubTxt)
            }
            alertButtonTxt = BundleI18n.MailSDK.Mail_OutOfOffice_SaveAnyway
        } else { //关闭退出草稿的场景
            if imageHandler.isContainsUploadingImg || !attachmentViewModel.isFinished { //文件上传中的场景
                alertContent = BundleI18n.MailSDK.Mail_Alert_ContentUploadingNowLeaveToLost_Title(alertSubTxt)
            } else if imageHandler.isContainsErrorImg || attachmentViewModel.isExistError { //文件上传失败
                alertContent = BundleI18n.MailSDK.Mail_Alert_FailedToUploadContentLeaveNow_Title(alertSubTxt)
            }



            alertButtonTxt = BundleI18n.MailSDK.Mail_Alert_CloseAnyway
        }


        alert.setContent(text: alertContent,
                         alignment: .center)
        alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_Alert_Cancel, dismissCompletion: { [weak self] in
            MailRoundedHUD.remove(on: self?.view ?? UIView())
            cancelHandler?()
        })
        alert.addDestructiveButton(text: alertButtonTxt, dismissCompletion: {
            completion?()
        })
        navigator?.present(alert, from: self)
        InteractiveErrorRecorder.recordError(event: .send_save_draft_image_uploading,
                                             tipsType: .alert,
                                             scene: baseInfo.statInfo.from == .outOfOffice ? .outofoffice : .compose)
    }

    // 联系人/主题/内容/附件/图片/封面 有任何一个，都可以保存草稿
    func checkSaveDraftEnable(draft: MailDraft) -> Bool {
        // 如果草稿被删除，则无需保存
        if self.draftDeleted {
            return false
        }
        /// if draft did't change the init content
        /// no need to save
        if draftSaveChecker.shouldSaveDraft() {
            return true
        }
        return false
    }

    private func checkBoxTap(_ checkBox: UDCheckBox) {
        guard let accountID = baseInfo.currentAccount?.mailAccountID else { return }
        checkBox.isSelected = !checkBox.isSelected
        accountContext.userKVStore.set(checkBox.isSelected, forKey: "mail_readstat_warning_\(accountID)")
    }

    private func makeDontShowAgainCheckBox(content content: String) -> UIView {
        let container = UIView()

        let contentLabel = UILabel()
        let checkLabel = UILabel()
        var config = UDCheckBoxUIConfig()
        config.style = .circle


        let checkBox = UDCheckBox(boxType: .multiple, config: config, tapCallBack: self.checkBoxTap)
        checkBox.isEnabled = true

        container.addSubview(checkBox)
        container.addSubview(contentLabel)
        container.addSubview(checkLabel)
        contentLabel.textColor = UIColor.ud.textPlaceholder
        contentLabel.font = UIFont.ud.body0.withSize(16)
        contentLabel.numberOfLines = 0
        contentLabel.textAlignment = .justified
        contentLabel.textColor = UIColor.ud.N900
        contentLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        contentLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }

        contentLabel.text = content

        checkBox.isUserInteractionEnabled = true
        checkBox.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.top.equalTo(contentLabel.snp.bottom).offset(20)
            make.bottom.equalToSuperview()
            make.width.height.equalTo(18)
        }

        checkLabel.text = BundleI18n.MailSDK.Mail_ReadReceipts_DontShowAgain
        checkLabel.font = UIFont.ud.body0.withSize(14)
        checkLabel.textColor = UIColor.ud.textPlaceholder
        checkLabel.snp.makeConstraints { (make) in
            make.left.equalTo(checkBox.snp.right).offset(8)
            make.top.equalTo(contentLabel.snp.bottom).offset(20)
            make.bottom.equalToSuperview()
            make.height.equalTo(18)
        }


        return container
    }

    // MARK: Mail Send Check - MailSendContentCheckerDelegate
    // Mail 发送前的内容检查
    func updateSendButtonEnable() {
        self.sendButton?.isEnabled = checkSendButtonEnable()
        if let btn = self.sendButton {
            if btn.isEnabled {
                btn.alpha = 1
                btn.tintColor = UIColor.ud.colorfulBlue
                btn.setImage(UDIcon.sendColorful.withRenderingMode(.alwaysTemplate), for: .normal)
                btn.accessibilityIdentifier = MailAccessibilityIdentifierKey.BtnSendSendKey
            } else {
                btn.setImage(UDIcon.sendFilled.withRenderingMode(.alwaysTemplate), for: .normal)
                btn.tintColor = UIColor.ud.iconDisabled
                btn.accessibilityIdentifier = MailAccessibilityIdentifierKey.BtnSendSendDisableKey
            }
        }
    }

    func moveBccTocc() {
        self.scrollContainer.moveBccTocc()
    }
    func disableSendSep() {
        self.draft?.isSendSeparately = false
    }

    func checkSendButtonEnable() -> Bool {
        let allEmailAddress = viewModel.sendToArray + viewModel.ccToArray + viewModel.bccToArray
        if allEmailAddress.isEmpty {
            return false
        }
        // 新的逻辑，只要有一个address就enable
        return true
    }

    func refreshInputView(mailContent: MailContent) {
        scrollContainer.updateInputViews(mailContent)
    }
    private func scrollToFirstFailedAttach() {
        let attachVM = self.attachmentViewModel
        let firstFailedIndex = attachVM.getFirstFailedAttachment()//第一个失败的附件Index
        let originOffset = self.scrollContainer.contentOffset
        let webviewY = self.scrollContainer.webView.frame.maxY

        let attachmentHeight = self.scrollContainer.attachmentsContainer.getAttachHeight()
        let targetAttachY = CGFloat(self.scrollContainer.attachmentsContainer.getTargetAttachY(at:firstFailedIndex))

        let screenY = webviewY + targetAttachY

        if screenY >= self.scrollContainer.contentSize.height - self.scrollContainer.frame.height {
            self.scrollContainer.scrollToBottom()
        } else {
            let padding: CGFloat = self.scrollContainer.attachmentsContainer.getCardSpacing()/2
            let cgPoint = CGPoint(x: originOffset.x, y: screenY - padding)
            self.scrollContainer.setContentOffset(cgPoint, animated: true)
        }
    }

    private func scrollToFirstFailedImg(at position:[String:Any],_ err:Any) {
        guard let top = position["top"] as? CGFloat else { return }
        guard let height = position["height"] as? CGFloat else { return }
        guard let uuid = position["uuid"] else { return }

        let webviewY = self.scrollContainer.webView.frame.minY
        let contentHeight = self.scrollContainer.frame.height
        let originOffset = self.scrollContainer.contentOffset
        var screenY: CGFloat = 0.0
        if contentHeight > height {
            let HeightOffset = (contentHeight - height)/2
            screenY = top + webviewY - HeightOffset
        } else {
            let HeightOffset = (height - contentHeight)/2
            screenY = top + webviewY + HeightOffset
        }
        if screenY >= self.scrollContainer.contentSize.height - self.scrollContainer.frame.height {
            self.scrollContainer.scrollToBottom()
            return
        }
        var cgPoint = CGPoint(x: originOffset.x, y: 0.0)
        if screenY > 0 {
            cgPoint = CGPoint(x: originOffset.x, y: screenY)
        }
        self.scrollContainer.setContentOffset(cgPoint, animated: true)
    }

    func showVerticalAlert(title: String,
                           content: String,
                           action1: String,
                           action2: String,
                           action1Handler: (() -> Void)?,
                           action2Handler: (() -> Void)?) {
        let alert = LarkAlertController()
        alert.setTitle(text: title)
        alert.setContent(text: content, alignment: .center)
        alert.addPrimaryButton(text: action1, dismissCompletion:  {
            action1Handler?()
        })
        alert.addSecondaryButton(text: action2, dismissCompletion:  {
            action2Handler?()
        })
        alert.addCancelButton()
        accountContext.navigator.present(alert, from: self)
    }

    /// 显示发送检查项的提示
    func saveContentAndShowAlert(result: MailSendContentChecker.SendEnableCheckResult,
                                 mailContent: MailContent,
                                 title: String?,
                                 leftTitle: String?,
                                 rightTitle: String,
                                 content: String,
                                 sendHandler: (() -> Void)?) {
        if sendHandler == nil {
            apmEndSendCustom(status: .status_blocking)
        } else {
            apmSuspendSendTimer()
        }
        requestHideKeyBoard()
        let alert = LarkAlertController()
        if let title = title {
            alert.setTitle(text: title)
        }
        alert.setContent(text: content, alignment: .center)
        if let leftTitle = leftTitle {
            alert.addSecondaryButton(text: leftTitle, dismissCompletion: {
                if result == .restrictOutbound {
                    MailTracker.log(event: "email_restriction_popup_click", params: ["button_type": "cancle"])
                } else if ( result == .attachmentsUploadError || result == .imagesUploadError ) {//有图片、附件未上传成功,需要跳转
                    if let errorImg = self.pluginRender?.imageHandler, errorImg.isContainsErrorImg {
                        let completionHandler = {[weak self] (position:Any, err:Any) in
                            if let position = position as? [String: Any]{
                                self?.scrollToFirstFailedImg(at: position, err)
                            } else { return }
                        }
                        self.requestEvaluateJavaScript("window.command.highLightFirstErrorImg()",completionHandler: completionHandler)
                    } else if self.attachmentViewModel.isExistError {
                        self.scrollToFirstFailedAttach()
                    }
                }
            })
        }
        let dismissCompletion = {
            sendHandler?()
            /// 邮件地址错误，则需要显示出是哪个邮件地址错误
            if result == .invailEmailAddress {
                self.contentChecker.selectInvailEmailAddress(mailContent)
            } else if result == .restrictOutbound {
                NotificationCenter.default.post(name: lkTokenViewRemoveNotificationName, object: nil)
                MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_RestrictOutbound_DeletedSuccessfully, on: self.view)
                MailTracker.log(event: "email_restriction_popup_click", params: ["button_type": "clear"])
            } else if ( result == .attachmentsUploadError || result == .imagesUploadError ) {//有图片、附件未上传成功，批量重传
                if self.attachmentViewModel.isExistError {
                    let attachVM = self.attachmentViewModel
                    attachVM.mailSendRetryAllAttachments()
                }
                if let errorImg = self.pluginRender?.imageHandler?.isContainsErrorImg {
                    let imgHandler = self.pluginRender?.imageHandler
                    imgHandler?.UploadRetryAll()
                }
            }
        }
        if result == .restrictOutbound {
            alert.addDestructiveButton(text: rightTitle, dismissCompletion: {
                dismissCompletion()
            })
        } else {
            alert.addPrimaryButton(text: rightTitle, dismissCompletion: dismissCompletion)
        }
        navigator?.present(alert, from: self)
    }

    func showAlert(alert: LarkAlertController) {
        navigator?.present(alert, from: self)
    }

    func showCustomAlert(alert: LarkAlertController, content: String) {
        alert.setContent(view: self.makeDontShowAgainCheckBox(content: content))
        navigator?.present(alert, from: self)
    }

    func onClickSendMail() {
        Store.settingData.storageLimitCheck(from: self, navigator: accountContext.navigator) { [weak self] in
            guard let `self` = self else { return }
//            MailTracker.startRecordTimeConsuming(event: "email_apm_send_draft", params: nil)
            if Store.settingData.mailClient {
                Store.settingData.mailClientExpiredCheck(accountContext: self.accountContext, from: self) {
                    [weak self] in
                    self?.apmMarkSendStart()
                    self?.prepareMailContent(.send)
                }
            } else {
                self.checkBeforePrepareContent {
                    self.apmMarkSendStart()
                    self.prepareMailContent(.send)
                }
            }
        }

        // core event
        let event = NewCoreEvent(event: .email_email_edit_click)
        let hasCalendar = self.draft?.calendarEvent != nil
        let (attNum, largeAttNum) = self.getSuccessUploadedAttachmentsCount()
        var params: [String: Any] = ["target": "none",
                     "click": "send",
                     "label_item": baseInfo.statInfo.newCoreEventLabelItem,
                                     "large_attachment": largeAttNum,
                                     "has_calendar": hasCalendar,
                     "attachment": attNum]
        if accountContext.featureManager.realTimeOpen(.enterpriseSignature) {
            params["scene"] = genSignatureScene()
            if let sigId = self.scrollContainer.webView.sigId, let type = genSignatureType(sigId: sigId) {
                params["signature_type"] = type
            }
        }
        if let draft = draft {
            params["sender_id"] = ["user_id": draft.content.from.larkID.encriptUtils(),
                                   "mail_id": draft.content.from.address.lowercased().encriptUtils(),
                                   "mail_type": (draft.content.from.type ?? .unknown).rawValue]
            var receIds : [[String: Any]] = []
            for address in viewModel.sendToArray {
                if address.larkID.isEmpty || address.larkID == "0" {
                    let receId = ["user_id": address.address.lowercased().encriptUtils(),
                                  "mail_id": address.address.lowercased().encriptUtils(),
                                  "mail_type": (address.type ?? .unknown).rawValue] as [String: Any]
                    receIds.append(receId)
                } else {
                    let receId = ["user_id": address.larkID.encriptUtils(),
                                  "mail_id": address.address.lowercased().encriptUtils(),
                                  "mail_type": (address.type ?? .unknown).rawValue] as [String: Any]
                    receIds.append(receId)
                }
            }
            for address in viewModel.ccToArray {
                if address.larkID.isEmpty || address.larkID == "0" {
                    let receId = ["user_id": address.address.lowercased().encriptUtils(),
                                  "mail_id": address.address.lowercased().encriptUtils(),
                                  "mail_type": (address.type ?? .unknown).rawValue] as [String: Any]
                    receIds.append(receId)
                } else {
                    let receId = ["user_id": address.larkID.encriptUtils(),
                                  "mail_id": address.address.lowercased().encriptUtils(),
                                  "mail_type": (address.type ?? .unknown).rawValue] as [String: Any]
                    receIds.append(receId)
                }
            }
            for address in viewModel.bccToArray {
                if address.larkID.isEmpty || address.larkID == "0" {
                    let receId = ["user_id": address.address.lowercased().encriptUtils(),
                                  "mail_id": address.address.lowercased().encriptUtils(),
                                  "mail_type": (address.type ?? .unknown).rawValue] as [String: Any]
                    receIds.append(receId)
                } else {
                    let receId = ["user_id": address.larkID.encriptUtils(),
                                  "mail_id": address.address.lowercased().encriptUtils(),
                                  "mail_type": (address.type ?? .unknown).rawValue] as [String: Any]
                    receIds.append(receId)
                }
            }
            if let stringData = try? JSONSerialization.data(withJSONObject: receIds, options: []),
               let JSONString = NSString(data: stringData, encoding: String.Encoding.utf8.rawValue)?.replacingOccurrences(of: "'", with: "\\'") {
                params["rece_id"] = JSONString as String
            }
            params["send_timestamp"] = Int(Date().timeIntervalSince1970 * 1000)
        }
        event.params = params
        event.post()
    }

    private func checkBeforePrepareContent(_ completion: @escaping () -> Void) {
        guard var draft = draft else {
            mailAssertionFailure("must have draft")
            completion()
            return
        }
        let tempContent = viewModel.createMailContentWithEmailAddress()
        draft.content.to = tempContent.to
        draft.content.cc = tempContent.cc
        draft.content.bcc = tempContent.bcc
        let checkResult = checkSendEnableResult(draft: draft)
        MailLogger.info("check before prepareContent result: \(checkResult)")
        if !contentChecker.showSendCheckResultAlert(checkResult, draft.content, nil) {
            completion()
        }
    }

    func prepareMailContent(_ scene: SendScene) {
        largefilePermissionToAnyone = false
        /// 点击发送时，先将所有输入中的文字保存为token
        scrollContainer.saveTextToToken()
        /// 保存一下附件
        guard draft != nil else { mailAssertionFailure("must have draft"); return }
        draft?.content.attachments = getSuccessUploadedAttachments()

        /// 获取 MailContent
        MailTracker.startRecordTimeConsuming(event: Homeric.MAIL_DEV_SEND_MAIL_COST_TIME, params: nil)
        getDraftHtmlContent(scene, onNext: { (_) in
        }, onError: { (error) in
            mailAssertionFailure("send error \(error)")
        })
    }

    func closeSceneIfNeeded() {
        if self.closeHandler?() != nil {
            self.closeScene(completionHandler: { [weak self] in
                self?.closeHandler?()
            })
        }
        if let splitVC = larkSplitViewController, splitVC.splitMode == .secondaryOnly {
            splitVC.updateSplitMode(.twoBesideSecondary, animated: true)
        }
    }

    func convertDocsConfig(docsConfigs: [[String: Any]]) -> [MailClientDocsPermissionConfig] {
        let configModels = docsConfigs.map({ (docsDic) -> MailClientDocsPermissionConfig in
            guard let docsUrl = docsDic["docUrl"] as? String,
                let perm = docsDic["action"] as? Int,
                let action = DocsInMailPermAction(rawValue: perm) else {
                    mailAssertionFailure("unexpacted data type, perm = \(String(describing: docsDic["permission"]))")
                    return MailClientDocsPermissionConfig()
            }

            var configModel = MailClientDocsPermissionConfig()
            configModel.docURL = docsUrl
            configModel.action = action
            return configModel
        })
        return configModels
    }

    func getSuccessUploadedAttachments() -> [MailAttachment] {
        let attachments = attachmentViewModel.successUploadedItems.map { MailAttachment(fileName: $0.displayName,
        fileKey: $0.fileToken ?? "",
        type: $0.type,
        fileSize: Int64($0.fileSize),
        largeFilePermission: $0.largeFilePermission,
        expireTime: $0.expireTime,
        needConvertToLarge: $0.needConvertToLarge)
        }
        return attachments
    }

    func getSuccessUploadedAttachmentsCount() -> (Int, Int) {
        var largeAttachmentNum = 0
        var attachmentNum = 0
        for att in attachmentViewModel.successUploadedItems {
            if att.type == .large ||
                att.needConvertToLarge == true {
                largeAttachmentNum += 1
            } else {
                attachmentNum += 1
            }
        }
        return (attachmentNum, largeAttachmentNum)
    }

    typealias sendContent = (bodyHtml: String, imageList: [MailImageInfo], plainText: String, docLinkConfigs: [MailClientDocsPermissionConfig], scene: String)
    func convertSendContent(sendContent: [String: Any]) -> sendContent? {
        guard let bodyHtml = sendContent["html"] as? String,
              let text = sendContent["text"] as? String,
              let image = sendContent["images"] as? [[String: Any]],
              let docLinks = sendContent["docLinks"] as? [[String: Any]] else { mailAssertionFailure("params error"); return nil }
        let imageList = image.map { MailImageInfo.convertFromJSON(param: $0) }
        let docLinkConfigs = convertDocsConfig(docsConfigs: docLinks)
        let scene = sendContent["scene"] as? String ?? "draft"

        return (bodyHtml, imageList, text, docLinkConfigs, scene)
    }

    func getDraftHtmlContent(_ scene: SendScene = .draft,
                             onNext: ((_ sendContent: Any?) -> Void)? = nil,
                             onError: ((_ error: Error) -> Void)? = nil,
                             onCompleted: (() -> Void)? = nil) {
        let getContent: Observable<Any?>
        if scene == .draft || scene == .getDraft {
            getContent = getDraftContent(scene.rawValue)
        } else {
            tempDate = Date()
            getContent = getSendContent(scene.rawValue)
        }
        getContent.observeOn(MainScheduler.instance).subscribe(onNext: {(htmlContent) in
            onNext?(htmlContent)
        }, onError: { (err) in
            onError?(err)
        }, onCompleted: {
            onCompleted?()
        }).disposed(by: self.disposeBag)
    }

    /// 发送邮件
    func sendMail(content: MailContent, scheduleSendTime: Int64) {
        guard let sendNav = sendNavVC else { mailAssertionFailure("must have navi vc"); return }
        var content = content
        if largefilePermissionToAnyone {
            content.attachments = content.attachments.map { (attach) -> MailAttachment in
                var copy_attach = attach
                copy_attach.largeFilePermission = .anyoneReadable
                return copy_attach
            }
        }
        if needShowConvertToLargeTips {
            MailRoundedHUD.showTips(with: BundleI18n.MailSDK.Mail_Edit_AttachmentTransferAutomatically, on: self.view)
        }
        self.apmResumeSendTimer()
        let dismiss = super.closeBtnTapped
        /// if is schedule send waiting for send callback, then dismiss
        let delayDismiss = scheduleSendTime > 0

        if var draft = self.draft {
            // 草稿里不能发的附件实际在这里去除
            content.attachments = content.attachments.filter({ (attachment) -> Bool in
                // 已过期
                let expiredFlag = attachment.type == .large &&
                attachment.expireTime != 0 &&
                attachment.expireTime / 1000 < Int64(Date().timeIntervalSince1970)
                // 已封禁
                let bannedFlag = attachmentViewModel.attachmentsContainer?.attachmentViews.contains(where: { $0.fileToken == attachment.fileKey && $0.bannedInfo?.isBanned == true })
                // 有害附件
                let typeStr = String(attachment.fileName.split(separator: ".").last ?? "")
                let type = DriveFileType(fileExtension: typeStr)
                let harmfulFlag = type.isHarmful
                // 已删除
                if FeatureManager.open(.largeAttachmentManagePhase2, openInMailClient: false) {
                    let deletedFlag = attachmentViewModel.attachmentsContainer?.attachmentViews.contains(where: { $0.fileToken == attachment.fileKey && $0.bannedInfo?.status == .deleted }) ?? false
                    return !expiredFlag && bannedFlag != true && !harmfulFlag && !deletedFlag
                }
                return !expiredFlag && bannedFlag != true && !harmfulFlag
            })
            draft.content = content
            draft.replyToMailID = baseInfo.messageID ?? ""
            MailLogger.info("mail send threadId: \(draft.threadID) reply mailId: \(draft.replyToMailID)")
            let imageNum = content.images.count
            let attachmentNum = content.attachments.count
            let toNum = content.to.count
            let ccNum = content.cc.count
            let bccNum = content.bcc.count
            let has_subject = !content.subject.isEmpty
            MailTracker.log(event: Homeric.EMAIL_DRAFT_SEND,
                            params: [
                                MailTracker.draftIdParamKey(): threadID ?? "",
                                MailTracker.imageCountParamKey(): imageNum,
                                MailTracker.attachmentCountParamKey(): attachmentNum,
                                MailTracker.toCountParamKey(): toNum,
                                MailTracker.ccCountParamKey(): ccNum,
                                MailTracker.bccCountParamKey(): bccNum,
                                MailTracker.hasSubjectParamKey(): has_subject,
                                MailTracker.sourceParamKey(): trackerSourceType])

//            MailTracker.endRecordTimeConsuming(event: "email_apm_send_draft", params: ["mail_body_length": draft.content.bodyHtml.count], useNewKey: true)
            let event = apmHolder[MailAPMEvent.SendDraft.self]
            event?.endParams.append(MailAPMEvent.SendDraft.EndParam.draft_id(draft.id))
            let isSchedule = scheduleSendTime > 0
            let isSp = draft.isSendSeparately
            let largeAttachmentCount = content.attachments.filter({ $0.type == .large }).count
            let normalAttachmentCount = content.attachments.count - largeAttachmentCount
            guard let fromVC = self.presentingViewController else { return }
            self.draftSent = true
            _ = dataManager.sendMail(draft, replyMailId: baseInfo.messageID ?? "", scheduleSendTime: scheduleSendTime, sendVC: sendNav, fromVC: fromVC, navigator: accountContext.navigator, feedCardId: self.feedCardId)
            .subscribe(onNext: { [weak self] (mailItem, _) in
                guard let `self` = self else { return }
                self.sendMailItem = mailItem
                MailLogger.info("mail send success")
                event?.endParams.append(MailAPMEventConstant.CommonParam.status_success)
                if let content = self.sendEditorParam {
                    if var detailDic = content["latencyDetails"] as? [String : Any] {
                        let callTime = self.scrollContainer.webView.sendCallTime
                        let respTime = self.scrollContainer.webView.sendReceiveTime
                        if let callEndTime = content["commandReceiveTime"] as? Int, callTime > 0, callEndTime - callTime >= 0 {
                            detailDic["bridge_command_cost_time"] = callEndTime - callTime
                        }
                        if let respStartTime = content["commandReturnTime"] as? Int, respTime > 0, respTime - respStartTime >= 0 {
                            detailDic["bridge_return_cost_time"] = respTime - respStartTime
                        }
                        for (key, value) in detailDic {
                            event?.appendCustomLantency(param: MailAPMEventConstant
                                .CommonParam.customKeyValue(key: key, value: value))
                        }
                    }
                }
                event?.postEnd()
                if delayDismiss {
                    if self.removeScheduleLoading {
                        self.removeScheduleLoading = false
                        MailRoundedHUD.remove(on: self.view)
                    }
                    dismiss()
                    self.closeSceneIfNeeded()
                }
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                MailLogger.error("mail send error \(error)")
                if self.removeScheduleLoading {
                    self.removeScheduleLoading = false
                    MailRoundedHUD.remove(on: self.view)
                }
                // code = 439, 即 msg 下不能有 2 封 schedule msg
                // code = 440, 即 schedule msg 超过 100 封限制
                let errCodeSchedule = 439
                let errCodeLimit = 440
                if self.scheduleSendTime > 0, let code = error.errorCode() {
                    if code == errCodeSchedule {
                        MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_SendLater_AlreadyScheduled, on: self.view,
                                                   event: ToastErrorEvent(event: .schedule_send_already_exist_fail))
                    }
                    if code == errCodeLimit {
                        MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_SendLater_ServerLimit,
                                                   on: self.view, event: ToastErrorEvent(event: .schedule_send_server_limit))
                    }
                    MailTracker.log(event: "email_draft_scheduledSend_failure", params: ["code": code])
                }
                event?.endParams.appendError(error: error)
                event?.endParams.append(MailAPMEventConstant.CommonParam.status_rust_fail)
                event?.postEnd()
                MailTracker.sendLog(send_status: false, toCount: toNum, ccCount: ccNum, bccCount: bccNum,
                                    largeAttachment: largeAttachmentCount, attachment: normalAttachmentCount,
                                    isSchedule: isSchedule, isSeparately: isSp)
                InteractiveErrorRecorder.recordError(event: .mail_failed_tosend)
            }, onCompleted: {
                MailTracker.sendLog(send_status: true, toCount: toNum, ccCount: ccNum, bccCount: bccNum,
                                    largeAttachment: largeAttachmentCount, attachment: normalAttachmentCount,
                                    isSchedule: isSchedule, isSeparately: isSp)
            })

            /// when user clicked send button, dismiss this page
            dismiss()
            self.closeSceneIfNeeded()
        } else {
            self.apmEndSend(status: .status_exception)
        }
    }

    func loadData() {
        setViewLoadingStatus(isLoading: true)
        // must call layout here
        view.layoutIfNeeded()
        if let draft = self.scrollContainer.webView.draft,
           self.scrollContainer.webView.renderJSCallBackSuccess {
            self.draft = draft
            self.isNewDraft = self.scrollContainer.webView.isNewDraft
            // check updateHeight
            if self.scrollContainer.webView.contentHeight > 0 {
                self.didUpdateEditorHeight(self.scrollContainer.webView.contentHeight)
            }
            updateUI(with: draft)
            if self.scrollContainer.webView.renderDone {
                self.didRenderMail(param: self.scrollContainer.webView.renderParam)
            }
        } else {
            self.scrollContainer.webView.draft = draft
            // check updateHeight
            if accountContext.featureManager.open(.preRender) &&
                self.scrollContainer.webView.contentHeight > 0 {
                self.didUpdateEditorHeight(self.scrollContainer.webView.contentHeight)
            }
            self.loadLocalDraftData()
        }
        contentChecker.userType = accountContext.user.getUserSetting()?.userType ?? .larkServer
        getCurrentAccount(complete: nil)
    }

    func isCreateNewDraftScene() -> Bool {
        return action == .new || action == .reply || action == .forward || action == .replyAll || action == .fromAddress || action == .fromAIChat
    }
    func clearScheduleSendTime() {
        scheduleSendTime = 0
    }
    func undoReloadDraft() {
        guard let message = self.sendMailItem?.messageItems.first?.message else {
            MailLogger.info("sendMailItem message info is nil")
            return
        }
        let atts = message.attachments.map {
            MailAttachment(fileName: $0.fileName,
                           fileKey: $0.fileToken,
                           type: $0.type,
                           fileSize: $0.fileSize,
                           largeFilePermission: $0.largeFilePermission,
                           expireTime: $0.expireTime,
                           needConvertToLarge: $0.needConvertToLarge)
        }
        self.renderAttachment(attachments: atts, reload: true)
    }
    private func createDraftAction() -> Bool {
        if self.action == .new || self.action == .reply ||
            self.action == .forward || self.action == .replyAll ||
            self.action == .fromAddress || self.action == .fromAIChat {
            return true
        }
        return false
    }
    private func editDraftAction() -> Bool {
        if self.action == .sendToChat_Forward || action == .sendToChat_Reply || self.action == .share || self.action == .outOfOffice || self.action == .reEdit || self.action == .messagedraft {
            return true
        }
        return false
    }

    func loadLocalDraftData() {
        if self.createDraftAction() {
            self.createDraftRelay
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] resp in
                    guard let `self` = self else { return }
                    guard resp.1 == true else { return }
                    if let resp = resp.0 {
                        let draft = MailDraft(with: resp.draft)
                        MailLogger.log(level: .info, message: "create draft success")
                        self.scrollContainer.webView.draft = draft
                        self.createNewDraft(draft)
                        self.isNewDraft = resp.isNew
                    } else {
                        MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Toast_OperationFailed, on: self.view)
                    }
                }).disposed(by: disposeBag)
        } else if self.editDraftAction() {
            guard let draft = draft else {
                mailAssertionFailure("must have draft")
                return
            }
            renderDraft(draft)
        } else if self.action == .draft {
            self.getMessageListForDraft()
        }
    }

    func getMessageListForDraft() {
        let realId = baseInfo.threadID ?? ""
        if realId.isEmpty {
            mailAssertionFailure("must have id")
        }
        if self.baseInfo.currentLabelId == Mail_LabelId_Outbox {
            MailDataSource.shared.getMessageListFromLocal(threadId: realId,
                                                          labelId: Mail_LabelId_Draft,
                                                          newMessageIds: nil).observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (res) in
                guard let `self` = self else { return }
                var resDraft: MailClientDraft? = nil
                if let clientDraft = res.mailItem.composeDrafts.first {
                    resDraft = clientDraft
                } else {
                    let item = res.mailItem.messageItems.first { item in
                        item.message.id == self.baseInfo.messageID
                    }
                    if let item = item, let draft = item.drafts.first {
                        resDraft = draft
                    }
                }
                if let clientDraft = resDraft {
                    self.draftFromOutbox = true
                    let draft = MailDraft(with: clientDraft)
                    self.processDraft(draft: draft)
                } else {
                    MailLogger.info("outbox from db draft is empty")
                }
            }, onError: { [weak self] (error) in
                mailAssertionFailure("获取草稿失败", error: error)
                guard let `self` = self else { return }
                self.processDraftError()
            }).disposed(by: self.disposeBag)
        } else {
            getDraftFromLocal(threadID: realId)
        }
    }

    func getDraftFromLocal(threadID: String) {
        MailDataSource.shared.getMessageListFromLocal(threadId: threadID,
                                                      labelId: baseInfo.currentLabelId,
                                                      newMessageIds: nil,
                                                      forwardInfo: nil)
        .observeOn(MainScheduler.instance)
        .subscribe { [weak self] res in
            guard let self = self else { return }
            let item = res.mailItem
            if res.notInDB {
                // 本地没有数据，从远端获取
                self.getDraftFromRemote(threadID: threadID)
            } else if let clientDraft = item.composeDrafts.first {
                let draft = MailDraft(with: clientDraft)
                self.processDraft(draft: draft)
            } else {
                mailAssertionFailure("no drafts from local \(threadID)")
            }
        } onError: { [weak self] error in
            mailAssertionFailure("获取本地草稿失败", error: error)
            guard let self = self else { return }
            self.getDraftFromRemote(threadID: threadID)
        }.disposed(by: disposeBag)
    }

    func getDraftFromRemote(threadID: String) {
        MailDataSource.shared.getMessageListFromRemote(threadId: baseInfo.threadID ?? "",
                                                       labelId: baseInfo.currentLabelId,
                                                       forwardInfo: nil,
                                                       newMessageIds: nil)
        .observeOn(MainScheduler.instance)
        .subscribe { [weak self] item in
            guard let self = self, let clientDraft = item.composeDrafts.first else { return }
            let draft = MailDraft(with: clientDraft)
            self.processDraft(draft: draft)
        } onError: { [weak self] error in
            mailAssertionFailure("获取远端草稿失败", error: error)
            guard let `self` = self else { return }
            self.processDraftError()
        }.disposed(by: disposeBag)
    }

    func processDraft(draft: MailDraft) {
        var draft = draft
        if Store.settingData.mailClient {
            for (index, image) in draft.content.images.enumerated() {
                if image.src.isEmpty {
                    draft.content.images[index].src = "cid:\(image.uuid)_msgId:\(draft.id)"
                }
                accountContext.cacheService.set(object: ["draft_id": draft.id] as NSCoding, for: "draft_cid:\(image.uuid)")
            }
        }
        self.draft = draft
        if let threadId = self.baseInfo.threadID, !threadId.isEmpty {
            self.draft?.threadID = threadId
        }
        if let messageId = self.baseInfo.messageID, !messageId.isEmpty {
            self.draft?.replyToMailID =  messageId
        }
        self.scrollContainer.webView.draft = draft
        self.renderDraft(draft)
        self.statReplayActionIfNeed(threadId: self.baseInfo.threadID ?? "", messageId: self.baseInfo.messageID ?? "")
        MailLogger.info("mail send draft threadId: \(self.draft?.threadID ?? "") reply mailId: \(self.draft?.replyToMailID ?? "")")
    }
    func processDraftError() {
        self.discardDraft()
        self.closeMe()
        MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_Toast_DraftDiscarded, on: self.view)
    }

    func setBarButtonEnableStatus(isEnabled: Bool) {
        // warning: do not call this method directly, call 'setViewLoadingStatus' instead
        if let items = navigationItem.rightBarButtonItems {
            for item in items {
                item.isEnabled = isEnabled
                if let view = item.customView {
                    view.alpha = isEnabled ? 1.0 : 0.5
                }
            }
        }
    }

    func getDraftMessageTimestamp() -> Int64? {
        let messageId = (self.baseInfo.messageID ?? self.baseInfo.threadID) ?? ""
        if let msgTimestamp = self.baseInfo.mailItem?.getMessageItem(by: messageId)?.message.createdTimestamp {
            return msgTimestamp / 1000
        }
        return nil
    }

    func setViewLoadingStatus(isLoading: Bool) {
        setBarButtonEnableStatus(isEnabled: !isLoading)
        if !isLoading {
            updateSendButtonEnable()
        }
    }

    func loadAddress() {
        addressFromUserInfo = MailModelManager.shared.getUserEmailAddress()
    }

    // 创建了一个新草稿
    func createNewDraft(_ newDraft: MailDraft) {
        draft = newDraft
        draft?.id = newDraft.id
        draft?.replyToMailID = baseInfo.messageID ?? ""

        let defaultAddress = MailAddress(name: "", address: baseInfo.toAddress ?? "", larkID: "", tenantId: "", displayName: "", type: nil)
        if action == .fromAddress {
            self.preRenderDraft(newDraft.id)
            // update address if need
            mailToUpdateAddress(address: baseInfo.toAddress ?? "", type: .toAddress)
            if !baseInfo.ccAddress.isEmpty {
                mailToUpdateAddress(address: baseInfo.ccAddress ?? "", type: .ccAddress)
            }
            if !baseInfo.bccAddress.isEmpty {
                mailToUpdateAddress(address: baseInfo.bccAddress ?? "", type: .bccAddress)
            }

        }  else {
            preRenderDraft(newDraft.id)
        }
    }

    // type: 0: toAddress; 1: ccAddress; 2: bccAddress
    func mailToUpdateAddress(address: String, type: addressType) {
        var addressByType = baseInfo.toAddress
        if type == .ccAddress {
            addressByType = baseInfo.ccAddress
        } else if type == .bccAddress {
            addressByType = baseInfo.bccAddress
        }
        var addressList = [MailAddress]()
        let addressStrList: [String] = addressByType?.components(separatedBy: ",") ?? [""] // 此处对齐pc端
        addressStrList.forEach { address in
            let addressTrim = address.trimmingCharacters(in: .whitespaces)
            let addressItem = MailAddress(name: "", address: addressTrim, larkID: "", tenantId: "", displayName: "", type: nil)
            addressList.append(addressItem)
        }
        let addressTem = MailAddress(name: "", address: addressByType ?? "", larkID: "", tenantId: "", displayName: "", type: nil)
        if type == .toAddress {
            self.draft?.content.to += addressList
            if let to = self.draft?.content.to {
                self.scrollContainer.updateToInputView(toAddress: to)
            }
        } else if type == .ccAddress {
            self.draft?.content.cc += addressList
            if let cc = self.draft?.content.cc {
                self.scrollContainer.updateCCInputView(ccAddress: cc)
            }
        } else if type == .bccAddress {
            self.draft?.content.bcc += addressList
            if let bcc = self.draft?.content.bcc {
                self.scrollContainer.updateBCCInputView(bccAddress: bcc)
            }
        }
        dataProvider
            .addressInfoSearch(address: addressByType ?? "")
            .timeout(.seconds(1), scheduler: MainScheduler.instance).subscribe(onNext: { [weak self] (model) in
                if let info = model {
                    let address = MailAddress(name: info.name,
                                             address: info.address,
                                             larkID: info.larkID ?? "",
                                             tenantId: info.tenantID ?? "",
                                             displayName: info.displayName ?? "",
                                             type: info.type)
                    if type == .toAddress {
                        if let index = self?.draft?.content.to.firstIndex(of: addressTem) {
                            self?.draft?.content.to.remove(at: index)
                        }
                        self?.draft?.content.to.append(address)
                        if let to = self?.draft?.content.to {
                            self?.scrollContainer.updateToInputView(toAddress: to)
                        }
                        self?.dataProvider.trackAddMailContact(contactType: address.type,
                                                               contactTag: nil,
                                                               addType: .mail_to,
                                                               addPosition: .to)
                    } else if type == .ccAddress {
                        if let index = self?.draft?.content.cc.firstIndex(of: addressTem) {
                            self?.draft?.content.cc.remove(at: index)
                        }
                        self?.draft?.content.cc.append(address)
                        if let cc = self?.draft?.content.cc {
                            self?.scrollContainer.updateCCInputView(ccAddress: cc)
                        }
                    } else if type == .bccAddress {
                        if let index = self?.draft?.content.bcc.firstIndex(of: addressTem) {
                            self?.draft?.content.bcc.remove(at: index)
                        }
                        self?.draft?.content.bcc.append(address)
                        if let bcc = self?.draft?.content.bcc {
                            self?.scrollContainer.updateBCCInputView(bccAddress: bcc)
                        }
                    }
                } else if type == .toAddress {
                    if let to = self?.draft?.content.to {
                        self?.scrollContainer.updateToInputView(toAddress: to)
                    }
                    self?.dataProvider.trackAddMailContact(contactType: addressTem.type,
                                                           contactTag: nil,
                                                           addType: .mail_to,
                                                           addPosition: .to)
                } else if type == .ccAddress {
                    if let cc = self?.draft?.content.cc {
                        self?.scrollContainer.updateCCInputView(ccAddress: cc)
                    }
                } else if type == .bccAddress {
                    if let bcc = self?.draft?.content.bcc {
                        self?.scrollContainer.updateBCCInputView(bccAddress: bcc)
                    }
                }
            }, onError: { _ in
               // nothing
            }).disposed(by: disposeBag)
    }


    func preRenderDraft(_ draftId: String) {
        // 渲染草稿
        if let draft = self.draft {
            if let sendTo = self.sendTo, !sendTo.isEmpty {
                self.draft?.content.to.append(contentsOf: sendTo)
            }
            self.renderDraft(draft)
        }
        // 统计
        self.actionInDetailTrack(self.action)
        self.statReplayActionIfNeed(threadId: self.baseInfo.threadID ?? "", messageId: self.baseInfo.messageID ?? "")
        self.statComposeActionIfNeed(draftId: draftId)
    }

    func updateUI(with draft: MailDraft) {
        self.scrollContainer.setupAliasInputViewIfNeeded()
        renderInputViews(draft)
        updateSendButtonEnable()
        updateAddressItemIfNeed(draft: draft)
        
    }
    
    func updateAddressItemIfNeed(draft: MailDraft) {
       guard !Store.settingData.mailClient else { return }
       guard accountContext.featureManager.open(.replyCheckAddress) else { return }
       let array = draft.content.cc + draft.content.bcc + draft.content.to
        var addressList: [AddressRequestItem] = []
        var addressUidMap: [String: MailAddress] = [:]
        for address in array {
            var item = AddressRequestItem()
            item.address = address.address
            addressList.append(item)
            if !address.address.isEmpty {
                addressUidMap[address.address] = address
            }
        }
       guard !addressList.isEmpty else { return }
        MailDataServiceFactory.commonDataService?.getMailAddressNames(addressList: addressList).subscribe( onNext: { [weak self]  MailAddressNameResponse in
        guard let `self` = self else { return }
            if !MailAddressNameResponse.addressNameList.isEmpty {
                var obserables: [Observable<MailSendAddressModel?>] = []
                for addressRes in MailAddressNameResponse.addressNameList {
                    // 如果id发生了变化，需要进一步请求大搜接口
                    if let originAddress = addressUidMap[addressRes.address],
                       !originAddress.larkID.isEmpty,
                       originAddress.larkID != addressRes.larkEntityID {
                        let observable = self.dataProvider.addressInfoSearchAppend(address: originAddress.address)
                        obserables.append(observable)
                    }
                }
                guard !obserables.isEmpty else { return }
                Observable.concat(obserables)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (info) in
                    guard let `self` = self else { return }
                    if let info = info,
                       !info.address.isEmpty,
                        !info.name.isEmpty {
                        var cellModel = MailAddressCellViewModel()
                        cellModel.address = info.address
                        cellModel.name = info.name
                        cellModel.type = info.type
                        cellModel.groupType = info.groupType
                        cellModel.displayName = info.displayName ?? ""
                        cellModel.larkID =  info.larkID ?? ""
                        cellModel.tenantId = info.tenantID ?? ""
                        self.viewModel.updateAddresModels(model: cellModel)
                    }
                }).disposed(by: self.disposeBag)
            }
        }, onError: { (error) in
            MailLogger.error("updateAddressItemIfNeed addressName error \(error)")
        }).disposed(by: disposeBag)
    }

    /// 渲染草稿
    func renderDraft(_ draft: MailDraft) {
        /// if is main account , show alias
        MailLogger.info("render draft")

        let content = draft.content
        var bodyHtml = content.bodyHtml
        if accountContext.featureManager.open(FeatureKey(fgKey: .draftContentHTMLDecode, openInMailClient: true)) {
            bodyHtml = content.bodyHtml.components(separatedBy: .controlCharacters).joined()
        }
        draft.toPBModel().images.forEach { (image) in
            let value = ["imageName": image.imageName, "fileToken": image.fileToken, "draft_id": draft.id]
            // 不知道是否需要把src也改了 增加draft_前缀
            if Store.settingData.mailClient {
                accountContext.cacheService.set(object: value as NSCoding, for: "draft_cid:\(image.cid)")
            } else {
                accountContext.cacheService.set(object: value as NSCoding, for: image.cid)
            }
        }
        /// 回填图片
        var images = content.images
        if let sigData = Store.settingData.getCachedCurrentSigData() {
            for sig in sigData.signatures {
                for image in sig.images where !image.cid.isEmpty {
                    let user = accountContext.user
                    var info = MailImageInfo(uuid: image.cid, src: "", width: "", height: "")
                    info.token = image.fileToken
                    info.name = image.imageName
                    info.dataSize = image.imageSize
                    images.append(info)
                }
            }
        }
        if !images.isEmpty {
            pluginRender?.imageHandler?.resetImageInfo(images)
        }
        updateUI(with: draft)
        MailTracker.startRecordMemory(event: Homeric.MAIL_DEV_CONTENT_MEMORY_DIFF, params: nil)
        pluginRender?.originRenderInfo = bodyHtml
        scrollContainer.updateCalendarView(calendarEvent: self.draft?.calendarEvent)
        if scrollContainer.webView.isReady {
            pluginRender?.render(mailContent: draft.content, needBlockWebImages: needBlockWebImages)
        } else {
            MailLogger.info("webView is not Ready")
        }
    }

    func renderInputViews(_ draft: MailDraft) {
        let content = draft.content
        scrollContainer.updateInputView(content: content, mailtoSubject: baseInfo.subject)
        // 注意setIsSp和isCCandBCCNeedShow的顺序
        scrollContainer.setIsSp(isSp: draft.isSendSeparately)
        if !draft.isSendSeparately && (content.bcc.count > 0 || content.cc.count > 0) {
            scrollContainer.isCCandBCCNeedShow = true
        }
        renderAttachment(attachments: content.attachments)
    }

    private func actionInDetailTrack(_ action: MailSendAction) {
        switch action {
        case .reply:
            MailTracker.startRecordTimeConsuming(event: Homeric.MAIL_DEV_REPLAY_IN_DETAIL_COST_TIME, params: nil)
            MailTracker.startRecordMemory(event: Homeric.MAIL_DEV_REPLAY_IN_DETAIL_MEMORY_DIFF, params: nil)
        case .replyAll:
            MailTracker.startRecordTimeConsuming(event: Homeric.MAIL_DEV_REPLAY_ALL_IN_DETAIL_COST_TIME, params: nil)
            MailTracker.startRecordMemory(event: Homeric.MAIL_DEV_REPLAY_ALL_IN_DETAIL_MEMORY_DIFF, params: nil)
        case .forward:
            MailTracker.startRecordTimeConsuming(event: Homeric.MAIL_DEV_FORWARD_IN_DETAIL_COST_TIME, params: nil)
            MailTracker.startRecordMemory(event: Homeric.MAIL_DEV_FORWARD_IN_DETAIL_MEMORY_DIFF, params: nil)
        default:
            return
        }
    }

    func renderAttachment(attachments: [MailAttachment],
                                 reload: Bool = false,
                                 replaceTokens: [String] = [],
                                 toBottom: Bool = false) {
        guard !attachments.isEmpty || reload else {
            if toBottom {
                self.scrollContainer.scrollToBottom()
            }
            return
        }
        var mailSendAttachments = [MailSendAttachment]()
        for attchment in attachments {
            let fileExtension = MainAttachmentType.init(fileExtension: NSString(string: attchment.fileName).pathExtension)
            var sendAttachment = MailSendAttachment(displayName: attchment.fileName,
                                                    fileExtension: fileExtension,
                                                    fileSize: Int(attchment.fileSize), largeFilePermission: attchment.largeFilePermission, type: attchment.type)
            sendAttachment.expireTime = attchment.expireTime
            sendAttachment.fileToken = attchment.fileKey
            sendAttachment.needConvertToLarge = attchment.needConvertToLarge
            sendAttachment.hashKey = "\(attchment.fileName)_\(Date().timeIntervalSince1970)"
            sendAttachment.needReplaceToken = attchment.needReplaceToken
            mailSendAttachments.append(sendAttachment)
        }
        if reload {
            scrollContainer.attachmentsContainer.removeAllAttachment()
            scrollContainer.attachmentsContainer.addAttachments(mailSendAttachments, allSuccess: true, permCode: baseInfo.mailItem?.code) // 转数据结构[MailSendAttachment]
            attachmentViewModel.removeAllAttachments()
            attachmentViewModel.appendAttachments(mailSendAttachments, needUpload: false)

        } else {
            mailSendAttachments = attachmentViewModel.removedulplicate(mailSendAttachments)
            scrollContainer.attachmentsContainer.addAttachments(mailSendAttachments, allSuccess: true, permCode: baseInfo.mailItem?.code) // 转数据结构[MailSendAttachment]
            attachmentViewModel.appendAttachments(mailSendAttachments,
                                                  needUpload: false,
                                                  toBottom: toBottom)
            if replaceTokens.count > 0 {
                MailDataServiceFactory
                    .commonDataService?.translateLargeTokenRequest(tokenList: replaceTokens, messageBizId: self.baseInfo.messageID ?? "").observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (dic) in
                    guard let `self` = self else { return }
                        // replaceToken
                        self.scrollContainer.attachmentsContainer.replaceToken(tokenMap: dic, messageBizId: self.baseInfo.messageID ?? "")
                }, onError: {  [weak self] (err) in
                    guard let `self` = self else { return }
                    MailLogger.info("[replace_token] err \(err)")
                    self.scrollContainer.attachmentsContainer.replaceTokenFail(tokenList: replaceTokens)
                }).disposed(by: disposeBag)
            }
        }
        if FeatureManager.open(.largeAttachmentManagePhase2, openInMailClient: false) {
            // 合并接口处理
            processNewBannedInfoIfNeeded(attachments: mailSendAttachments)
            processRiskFileIfNeeded(attachments: mailSendAttachments) // 处理风险附件 没下掉之前先用这个逻辑 后续可以用上面的接口取得风险态
        } else {
            processBannedInfoIfNeeded(attachments: mailSendAttachments) // 处理封禁附件
            processRiskFileIfNeeded(attachments: mailSendAttachments) // 处理风险附件
        }
    }
    /// context : 二期 将risk接口与banned接口基于banned接口合并，并新增被删除态
    /// bannedInfo:
    /// required bool is_owner = 1;
    /// required bool is_banned = 2;
    /// optional bool is_high_risk = 3;
    /// optional bool is_deleted = 4;
    private func processNewBannedInfoIfNeeded(attachments: [MailSendAttachment]) {
        let bannedEvent = MailAPMEvent.LoadFileBannedInfos()
        bannedEvent.customScene = .MailDraft
        bannedEvent.endParams.append(MailAPMEvent.LoadFileBannedInfos.EndParam.requestSourceTerminal)
        bannedEvent.markPostStart()
        let allFileTokens = attachments.compactMap { $0.fileToken }.filter({ !$0.isEmpty }).filterDuplicates({$0})
        bannedEvent.endParams.append(MailAPMEvent.LoadFileBannedInfos.EndParam.requestFileTokensLength(allFileTokens.count))
        // 接口一次最多接收100个Token，因此需要拆分
        let allFileTokensSplit = allFileTokens.splitArray(withSubsize: 100)
        let observables: [Observable<ServerPB_Mails_GetLargeAttachmentBannedInfoResponse>] = allFileTokensSplit.map { fileTokensGroup in
            guard let dataService = MailDataServiceFactory.commonDataService else {
                return Observable.error(MailUserLifeTimeError.serviceDisposed)
            }
            return dataService.getLargeAttachmentBannedInfo(fileTokensGroup)
        }
        Observable.zip(observables).subscribe(onNext: { [weak self] allResult in
            MailLogger.info("getLargeAttachmentBannedInfo Success.")
            var bannedFileOwnerCount = 0 // 用于业务埋点上报
            var bannedFileCustomerCount = 0 // 用于业务埋点上报
            var allResultCount = 0 // 用于品质埋点上报
            for result in allResult {
                for info in result.tokenBannedInfoMap {
                    attachments.filter({ $0.fileToken == info.key }).forEach { attachment in
                        self?.scrollContainer.attachmentsContainer.updateNewBannedInfo(attachment: attachment, bannedInfo: info.value)
                    }
                    if info.value.status.rawValue == 2 { // isBanned
                        info.value.isOwner ? (bannedFileOwnerCount += 1) : (bannedFileCustomerCount += 1)
                    }
                }
                allResultCount += result.tokenBannedInfoMap.count
            }
            if bannedFileOwnerCount > 0 || bannedFileCustomerCount > 0 {
                MailTracker.log(event: "email_attachment_list_view",
                                params: ["risk_file_cnt": bannedFileOwnerCount,
                                         "expired_file_cnt": bannedFileCustomerCount,
                                         "mail_account_type": Store.settingData.getMailAccountType()])
            }
            bannedEvent.endParams.append(MailAPMEvent.LoadFileBannedInfos.EndParam.responseBannedInfosLength(allResultCount))
            bannedEvent.endParams.append(MailAPMEventConstant.CommonParam.status_success)
            bannedEvent.postEnd()
        }, onError: { (error) in
            // 拿不到结果，包括超时，都视为未封禁
            MailLogger.info("getLargeAttachmentBannedInfo Error: \(error)")
            bannedEvent.endParams.appendError(error: error)
            if error.isRequestTimeout {
                bannedEvent.endParams.append(MailAPMEventConstant.CommonParam.status_timeout)
            } else {
                bannedEvent.endParams.append(MailAPMEventConstant.CommonParam.status_rust_fail)
            }
            bannedEvent.postEnd()
        }).disposed(by: disposeBag)
    }

    private func processRiskFileIfNeeded(attachments: [MailSendAttachment]) {
        guard accountContext.featureManager.open(.securityFile, openInMailClient: true) else { return }
        let event = MailAPMEvent.LoadFileRiskInfos()
        event.customScene = .MailDraft
        event.endParams.append(MailAPMEvent.LoadFileRiskInfos.EndParam.requestSourceTerminal)
        event.markPostStart()
        let allFileTokens = attachments.compactMap { $0.fileToken }.filter({ !$0.isEmpty }).filterDuplicates({$0})
        event.endParams.append(MailAPMEvent.LoadFileRiskInfos.EndParam.requestFileTokensLength(allFileTokens.count))

        // 接口一次最多接收100个Token，因此需要拆分
        let allFileTokensSplit = allFileTokens.splitArray(withSubsize: 100)
        let observables: [Observable<ServerPB_Compliance_MGetRiskTagByTokenResponse>] = allFileTokensSplit.map { fileTokensGroup in
            guard let dataService = MailDataServiceFactory.commonDataService else {
                return Observable.error(MailUserLifeTimeError.serviceDisposed)
            }
            return dataService.getAttachmentsRiskTag(fileTokensGroup)
        }
        Observable.zip(observables).subscribe(onNext: { [weak self] allResult in
            MailLogger.info("getAllAttachmentsRiskTag Success.")
            var riskFileCount = 0 // 用于业务埋点上报
            var allResultCount = 0 // 用于品质埋点上报
            for result in allResult {
                for tag in result.result where !tag.fileToken.isEmpty && tag.isRiskFile {
                    attachments.filter({ $0.fileToken == tag.fileToken }).forEach { attachment in
                        self?.scrollContainer.attachmentsContainer.updateRiskFileTag(attachment: attachment, isRiskFile: true)
                        riskFileCount += 1
                    }
                }
                allResultCount += result.result.count
            }
            if riskFileCount > 0 {
                MailTracker.log(event: "email_attachment_file_alert_view",
                                params: ["attachment_num": riskFileCount,
                                         "mail_account_type": Store.settingData.getMailAccountType()])
            }
            event.endParams.append(MailAPMEvent.LoadFileRiskInfos.EndParam.responseRiskInfosLength(allResultCount))
            event.endParams.append(MailAPMEventConstant.CommonParam.status_success)
            event.postEnd()
        }, onError: { (error) in
            // 拿不到结果，包括超时，都视为无风险
            MailLogger.info("getAllAttachmentsRiskTag Error: \(error)")
            event.endParams.appendError(error: error)
            if error.isRequestTimeout {
                event.endParams.append(MailAPMEventConstant.CommonParam.status_timeout)
            } else {
                event.endParams.append(MailAPMEventConstant.CommonParam.status_rust_fail)
            }
            event.postEnd()
        }).disposed(by: disposeBag)
    }

    private func processBannedInfoIfNeeded(attachments: [MailSendAttachment]) {
        guard accountContext.featureManager.open(.largeAttachmentManage, openInMailClient: false) else { return }
        let event = MailAPMEvent.LoadFileBannedInfos()
        event.customScene = .MailDraft
        event.endParams.append(MailAPMEvent.LoadFileBannedInfos.EndParam.requestSourceTerminal)
        event.markPostStart()
        // 只筛选出超大附件
        let allFileTokens = attachments.filter({ $0.type == .large }).compactMap { $0.fileToken }.filter({ !$0.isEmpty }).filterDuplicates({$0})
        event.endParams.append(MailAPMEvent.LoadFileBannedInfos.EndParam.requestFileTokensLength(allFileTokens.count))

        // 接口一次最多接收100个Token，因此需要拆分
        let allFileTokensSplit = allFileTokens.splitArray(withSubsize: 100)
        let observables: [Observable<ServerPB_Mails_GetLargeAttachmentBannedInfoResponse>] = allFileTokensSplit.map { fileTokensGroup in
            guard let dataService = MailDataServiceFactory.commonDataService else {
                return Observable.error(MailUserLifeTimeError.serviceDisposed)
            }
            return dataService.getLargeAttachmentBannedInfo(fileTokensGroup)
        }
        Observable.zip(observables).subscribe(onNext: { [weak self] allResult in
            MailLogger.info("getLargeAttachmentBannedInfo Success.")
            var bannedFileOwnerCount = 0 // 用于业务埋点上报
            var bannedFileCustomerCount = 0 // 用于业务埋点上报
            var allResultCount = 0 // 用于品质埋点上报
            for result in allResult {
                for info in result.tokenBannedInfoMap {
                    attachments.filter({ $0.fileToken == info.key }).forEach { attachment in
                        self?.scrollContainer.attachmentsContainer.updateBannedInfo(attachment: attachment, bannedInfo: info.value)
                    }
                    if info.value.isBanned {
                        info.value.isOwner ? (bannedFileOwnerCount += 1) : (bannedFileCustomerCount += 1)
                    }
                }
                allResultCount += result.tokenBannedInfoMap.count
            }
            if bannedFileOwnerCount > 0 || bannedFileCustomerCount > 0 {
                MailTracker.log(event: "email_attachment_list_view",
                                params: ["risk_file_cnt": bannedFileOwnerCount,
                                         "expired_file_cnt": bannedFileCustomerCount,
                                         "mail_account_type": Store.settingData.getMailAccountType()])
            }
            event.endParams.append(MailAPMEvent.LoadFileBannedInfos.EndParam.responseBannedInfosLength(allResultCount))
            event.endParams.append(MailAPMEventConstant.CommonParam.status_success)
            event.postEnd()
        }, onError: { (error) in
            // 拿不到结果，包括超时，都视为未封禁
            MailLogger.info("getLargeAttachmentBannedInfo Error: \(error)")
            event.endParams.appendError(error: error)
            if error.isRequestTimeout {
                event.endParams.append(MailAPMEventConstant.CommonParam.status_timeout)
            } else {
                event.endParams.append(MailAPMEventConstant.CommonParam.status_rust_fail)
            }
            event.postEnd()
        }).disposed(by: disposeBag)
    }

    private func statReplayActionIfNeed(threadId: String, messageId: String) {
        var type = "unknow"
        switch baseInfo.statInfo.from {
        case .messageReply, .messageDraftClick: type = "reply"
        case .messageReplyAll: type = "replyall"
        case .messageForward: type = "forward"
        default:
            return // 其他入口不打这个点
        }

        let replyId = messageId
        let draftId = draft?.id
        let params = ["type": type,
                      "threadid": threadId,
                      "originMessageId": replyId,
                      "draftid": draftId]
        MailTracker.log(event: Homeric.EMAIL_EDIT, params: params as [String: Any])
    }

    private func statComposeActionIfNeed(draftId: String) {
        guard baseInfo.statInfo.from == .threadListCreate else {
            return
        }
        // 业务统计
        MailTracker.log(event: Homeric.EMAIL_EDIT, params: ["type": "compose", "draftid": draftId])
    }

    func checkDocsUrlBeforeSend(docsLinks: [MailClientDocsPermissionConfig],
                                mailContent: MailContent,
                                nextStepHandler: @escaping (_ content: MailContent) -> Bool) {
        guard !docsLinks.isEmpty else {
            _ = nextStepHandler(mailContent)
            return
        }
        let isContainExternalTenant = checkExternalTenant()
        let isContainBcc = containBcc()
        if draft?.isSendSeparately == true {
            let alert = LarkAlertController()
            let content = BundleI18n.MailSDK.Mail_Compose_NoPermissionDesc
            alert.setContent(text: content, alignment: .center)
            alert.addCancelButton()
            alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_Alert_Confirm, dismissCompletion: {
                _ = nextStepHandler(mailContent)
            })
            navigator?.present(alert, from: self)
        } else if isContainBcc || isContainExternalTenant {
            let alert = LarkAlertController()
            var content = ""
            if isContainBcc, isContainExternalTenant {
                content = BundleI18n.MailSDK.Mail_DocPreview_HasBccAndExtContacts
            } else if isContainBcc {
                content = BundleI18n.MailSDK.Mail_DocPreview_HasBcc
            } else if isContainExternalTenant {
                content = BundleI18n.MailSDK.Mail_DocPreview_HasExternalContacts
            }
            alert.setContent(text: content, alignment: .center)
            alert.addCancelButton()
            alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_Alert_Confirm, dismissCompletion: {
                _ = nextStepHandler(mailContent)
            })
            navigator?.present(alert, from: self)
        } else {
            _ = nextStepHandler(mailContent)
        }
    }
    func checkDriveAttachmentExternalBeforeSend(mailContent: MailContent,
                                                nextStepHandler: @escaping (_ content: MailContent) -> Bool) {
        if accountContext.featureManager.open(.largeAttachmentManage, openInMailClient: false) {
            _ = nextStepHandler(mailContent)
            return
        }
        if let attachments = draft?.content.attachments {
            if attachments.contains(where: { (attachment) -> Bool in
                return attachment.type == .large && attachment.expireTime == 0
            }), checkExternalTenant() {                _ = MailDataServiceFactory.commonDataService?.checkIfLargeFileCanShare().subscribe(onNext: { [weak self] (res) in
                    guard let `self` = self else { return }
                    if !res.canShare {
                        let alert = LarkAlertController()
                        alert.setTitle(text: BundleI18n.MailSDK.Mail_Compose_LFAdminTurnOffExternalTitle)
                        alert.setContent(text: BundleI18n.MailSDK.Mail_Compose_LFAdminTurnOffExternalBody, alignment: .center)
                        alert.addCancelButton()
                        alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_Compose_LFActionSendAnyway, dismissCompletion: {
                            _ = nextStepHandler(mailContent)
                        })
                        self.navigator?.present(alert, from: self)
                        InteractiveErrorRecorder.recordError(event: .send_largefile_external_cannot_access,
                                                             tipsType: .alert)
                    } else {
                        _ = nextStepHandler(mailContent)
                    }
                    }, onError: { (err) in
                        MailSendController.logger.error(
                            "checkIfLargeFileCanShare failed",
                            error: err
                        )
                        _ = nextStepHandler(mailContent)
                })
                return
            }
        }
        _ = nextStepHandler(mailContent)
    }

    func checkDriveAttachmentPermissionBeforeSend(mailContent: MailContent,
                                                  nextStepHandler: @escaping (_ content: MailContent) -> Bool) {
        if accountContext.featureManager.open(.largeAttachmentManage, openInMailClient: false) {
            _ = nextStepHandler(mailContent)
            return
        }
        if let attachments = draft?.content.attachments {
            if attachments.contains(where: { (attachment) -> Bool in
                attachment.type == .large && attachment.largeFilePermission == .tenantReadable && attachment.expireTime == 0
            }) {
                let alert = LarkAlertController()
                alert.setTitle(text: BundleI18n.MailSDK.Mail_Compose_LFChangePermissionTitle)
                alert.setContent(text: BundleI18n.MailSDK.Mail_Compose_LFChangePermissionBody, alignment: .center)
                alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_Compose_LFActionSendAnyway, dismissCompletion: {
                    _ = nextStepHandler(mailContent)
                })
                alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_Compose_LFActionChangeAndSend, dismissCompletion: { [weak self] in
                    guard let `self` = self else { return }
                    self.largefilePermissionToAnyone = true
                    _ = nextStepHandler(mailContent)
                })
                navigator?.present(alert, from: self)
                InteractiveErrorRecorder.recordError(event: .send_largefile_external_permission_change,
                                                     tipsType: .alert)
                return
            }
        }
        _ = nextStepHandler(mailContent)
    }

    func containBcc() -> Bool {
        return draft?.content.bcc.count ?? 0 > 0
    }

    func checkExternalTenant() -> Bool {
        if let localAddress = accountContext.user.emailDomains, localAddress.count > 0 {

            let external = getDraftSendAddresses().first { str in
                if let domain = str {
                    return !localAddress.contains(domain)
                }
                return false
            }
            return external != nil
        }
        return containExternalTenant()
    }

    func getDraftSendAddresses() -> [String?] {
        let map = { (address: MailAddressCellViewModel) -> String? in
            if let str = address.address.split(separator: "@").last {
                return String(str)
            } else {
                return nil
            }
        }
        var array: [MailAddressCellViewModel] = []
        array.append(contentsOf: viewModel.sendToArray)
        array.append(contentsOf: viewModel.ccToArray)
        array.append(contentsOf: viewModel.bccToArray)
        return array.map(map)
    }

    func containExternalTenant() -> Bool {
        let fromAddresses = draft?.content.from.address.split(separator: "@").last
        guard fromAddresses?.count ?? 0 > 0 else {
            return false
        }
        let map = { (address: MailAddressCellViewModel) -> String.SubSequence? in
            return address.address.split(separator: "@").last
        }
        let externalTo = viewModel.sendToArray.map(map).first { $0 != fromAddresses }
        let externalCc = viewModel.ccToArray.map(map).first { $0 != fromAddresses }
        let externalBcc = viewModel.bccToArray.map(map).first { $0 != fromAddresses }
        return externalTo != nil || externalCc != nil || externalBcc != nil
    }

    // 计算当前收件人人数
    func checkRecipientCount() {
        MailLogger.info("[MassiveSendRemind] checkRecipientCount recipientLimitEnable:\(self.recipientLimitEnable)")
        if accountContext.featureManager.open(.massiveSendRemind, openInMailClient: false), self.recipientLimitEnable, !self.recipientOverLimit {
            let allAddress = self.viewModel.sendToArray + self.viewModel.ccToArray + self.viewModel.bccToArray
            var memberCount: Int64 = 0
            var groupInfosNeedFetch: [MailGroupMemberCountInfo] = []
            for address in allAddress {
                if address.type == .group {
                    if let count = self.groupMemberCount[address.larkID] { // Map里存放了人数
                        if count == -1 { // 直接超限
                            MailLogger.info("[MassiveSendRemind] checkRecipientCount group overLimit.")
                            self.recipientOverLimit = true
                            return
                        }
                        memberCount += count
                    } else {
                        memberCount += 1 // 查不到的先当成一个地址
                        if let chatGroupID = Int64(address.larkID) {
                            var groupInfo = MailGroupMemberCountInfo()
                            groupInfo.chatGroupID = chatGroupID // 群聊使用ID
                            groupInfosNeedFetch.append(groupInfo)
                        }
                    }
                } else if address.type == .enterpriseMailGroup {
                    if let count = self.groupMemberCount[address.address] { // Map 里存放了人数
                        if count == -1 { // 直接超限
                            MailLogger.info("[MassiveSendRemind] checkRecipientCount enterpriseMailGroup overLimit.")
                            self.recipientOverLimit = true
                            return
                        }
                        memberCount += count
                    } else {
                        memberCount += 1 // 查不到的先当成一个地址
                        var groupInfo = MailGroupMemberCountInfo()
                        groupInfo.mailGroupAddress = address.address // 邮件组使用地址
                        groupInfosNeedFetch.append(groupInfo)
                    }
                } else {
                    memberCount += 1
                }

                if memberCount >= self.recipientLimit {
                    self.recipientOverLimit = true
                    return
                }
            }
            MailLogger.info("[MassiveSendRemind] checkRecipientCount memberCount:\(memberCount), needFetch:\(!groupInfosNeedFetch.isEmpty)")
            if !groupInfosNeedFetch.isEmpty, let draftID = draftID {
                MailDataServiceFactory.commonDataService?.mailCheckGroupMemberCount(sessionID: draftID, groupInfos: groupInfosNeedFetch).subscribe(onNext: { [weak self] groupInfos in
                    guard let self = self else { return }
                    guard !groupInfos.isEmpty else { return }
                    for groupInfo in groupInfos {
                        self.handleGroupMemberCountInfo(groupInfo)
                    }
                    self.checkRecipientCount()
                }).disposed(by: disposeBag)
            }
        }
    }

    private func handleGroupMemberCountInfo(_ groupInfo: MailGroupMemberCountInfo) {
        switch groupInfo.groupID {
        case .chatGroupID(let id):
            self.groupMemberCount[String(id)] = groupInfo.groupMemberOverLimit ? -1 : groupInfo.groupMemberCount
        case .mailGroupAddress(let id):
            self.groupMemberCount[id] = groupInfo.groupMemberOverLimit ? -1 : groupInfo.groupMemberCount
        case .none, .some(_):
            mailAssertionFailure("[MassiveSendRemind] unknown GroupMemberCountInfo type")
            break
        default:
            mailAssertionFailure("[MassiveSendRemind] unknown GroupMemberCountInfo type")
            break
        }
    }

    private func listenGroupMemberCountPush() {
        guard accountContext.featureManager.open(.massiveSendRemind, openInMailClient: false) else { return }
        PushDispatcher.shared.$mailGroupMemberCountPush
            .wrappedValue
            .observeOn(MainScheduler.instance)
            .subscribe({ [weak self] push in
                MailLogger.info("[MassiveSendRemind] mailGroupMemberCountPush")
                guard let self = self,
                      let value = push.element,
                      self.draft?.id == value.sessionID else { return }
                self.recipientLimitEnable = value.config.enableRecipientLimitRemind
                // 设置值发生变化，所有存储需重置
                if self.recipientLimitEnable,
                   self.recipientLimit != value.config.recipientLimitCount {
                    MailLogger.info("[MassiveSendRemind] recipientLimitEnable change")
                    self.recipientLimit = value.config.recipientLimitCount
                    self.recipientOverLimit = false
                    self.groupMemberCount.removeAll()
                }
                self.handleGroupMemberCountInfo(value.groupInfo)
                self.checkRecipientCount()
            }).disposed(by: disposeBag)
    }

    // MARK: - UITableViewDataSource & Delegate
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        _tableView(tableView, viewForHeaderInSection: section)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        _tableView(tableView, heightForHeaderInSection: section)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        _tableView(tableView, numberOfRowsInSection: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        _tableView(tableView, cellForRowAt: indexPath)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        _tableView(tableView, didSelectRowAt: indexPath)
    }

    // filter load more
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        _tableView(tableView, willDisplay: cell, forRowAt: indexPath)
    }

    // MARK: - UITextFieldDelegate & UITextViewDelegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        _textFieldDidBeginEditing(textField)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        _textFieldShouldReturn(textField)
    }
    func tabKeyBinding(currentView: UIView) -> KeyBinding {
        let tabKeyBing = KeyCommandBaseInfo(input: "\t",
                           modifierFlags: [],
                           discoverabilityTitle:"")
            .binding(
                tryHandle: { _ in true },
                handler: { [weak self] in
                    guard let `self` = self else { return }
                    self.focusNextInputView(currentView: currentView)
                }
            )
        return tabKeyBing
    }

    func leftArrowKeyBinding(currentView: UIView) -> KeyBinding {
        let leftKeyBing = KeyCommandBaseInfo(input: UIKeyCommand.inputLeftArrow,
                                             modifierFlags: [],
                                             discoverabilityTitle:"")
            .binding(
                tryHandle: { _ in true },
                handler: { [weak self] in
                    guard let `self` = self else { return }
                    self.selectPreToken(currentView: currentView)
                }
            )
        return leftKeyBing
    }

    func rightArrowKeyBinding(currentView: UIView) -> KeyBinding {
        let rightKeyBing = KeyCommandBaseInfo(input: UIKeyCommand.inputRightArrow,
                           modifierFlags: [],
                           discoverabilityTitle:"")
            .binding(
                tryHandle: { _ in true },
                handler: { [weak self] in
                    guard let `self` = self else { return }
                    self.selectNextToken(currentView: currentView)
                }
            )
        return rightKeyBing
    }

    func registerLeftKey(currentView: UIView) {
        KeyCommandKit.shared.register(keyBinding: leftArrowKeyBinding(currentView: currentView))
    }
    func unregisterLeftKey(currentView: UIView) {
        KeyCommandKit.shared.unregister(keyBinding: leftArrowKeyBinding(currentView: currentView))
    }

    func registerRightKey(currentView: UIView) {
        KeyCommandKit.shared.register(keyBinding: rightArrowKeyBinding(currentView: currentView))
    }
    func unregisterRightKey(currentView: UIView) {
        KeyCommandKit.shared.unregister(keyBinding: rightArrowKeyBinding(currentView: currentView))
    }

    func registerTabKey(currentView: UIView) {
        KeyCommandKit.shared.register(keyBinding: tabKeyBinding(currentView: currentView))
    }
    func unregisterTabKey(currentView: UIView) {
        KeyCommandKit.shared.unregister(keyBinding: tabKeyBinding(currentView: currentView))
    }

    func dynamicKeyBindings() -> [KeyBinding] {
        let dynamicKeyBindings:[KeyBinding] = [
            KeyCommandBaseInfo(input: UIKeyCommand.inputUpArrow,
                               modifierFlags: [],
                               discoverabilityTitle:"")
                .binding(
                    tryHandle: { _ in true },
                    handler: { [weak self] in
                        self?.selectPreCell()
                    }
                ),
            KeyCommandBaseInfo(input: UIKeyCommand.inputDownArrow,
                               modifierFlags: [],
                               discoverabilityTitle:"")
                .binding(
                    tryHandle: { _ in true },
                    handler: { [weak self] in
                        self?.selectNextCell()
                    }
                ),
            KeyCommandBaseInfo(input: "\r",
                                      modifierFlags: [],
                                      discoverabilityTitle:"")
                                     .binding(
                                         tryHandle: { _ in true },
                                         handler: { [weak self] in
                                             self?.selectAddressCell()
                                         }
                                     )
        ]
        return dynamicKeyBindings
    }

    func updateKeyboardBinding() {
        if suggestTableView.isHidden {
            for keyBinding in dynamicKeyBindings() {
                KeyCommandKit.shared.unregister(keyBinding: keyBinding)
            }

        } else {
            for keyBinding in dynamicKeyBindings() {
                KeyCommandKit.shared.register(keyBinding: keyBinding)
            }
        }
    }

    @objc
    func selectPreCell() {
        let totalCnt = viewModel.filteredArray.count
        if self.suggestTableSelectionRow - 1 >= 0 &&
            self.suggestTableSelectionRow - 1 < totalCnt {
            self.suggestTableSelectionRow = self.suggestTableSelectionRow - 1
        }

    }
    @objc
    func selectNextCell() {
        let totalCnt = viewModel.filteredArray.count
        if self.suggestTableSelectionRow + 1 >= 0 &&
            self.suggestTableSelectionRow + 1 < totalCnt {
            self.suggestTableSelectionRow = self.suggestTableSelectionRow + 1
        }
    }
    @objc
    func selectAddressCell() {
        _tableView(self.suggestTableView,
                   didSelectRowAt: IndexPath(row: self.suggestTableSelectionRow,
                                             section: 0))
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        _documentPicker(controller, didPickDocumentsAt: urls)
    }
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        _documentPicker(controller, didPickDocumentAt: url)
    }

    private func getLocalFileDir() -> URL {
        // 本地 Document 路径 + "缓存目录"
        FileOperator.getAttachmentCacheDirURL("preview_file_cache", userID: accountContext.user.userID)
    }
}
extension MailSendController: MailAIMaskViewDelegate {
    func getHitTestView() -> UIView? {
        return scrollContainer
    }
}

protocol MailAIMaskViewDelegate: AnyObject {
    func getHitTestView() -> UIView?
}

class MailAIMaskView: UIView {
    weak var delegate:MailAIMaskViewDelegate?
    var moveFlag = false
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.isHidden {
            return nil
        } else {
            return self.delegate?.getHitTestView()
        }
    }
}
