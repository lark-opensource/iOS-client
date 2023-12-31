//
//  MailSendContainerView.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2019/12/29.
//

import Foundation
import RxSwift
import RxCocoa
import UIKit
import SnapKit
import WebKit
import RustPB
import LarkInteraction
import UniverseDesignIcon
import EENavigator

class MailSendContainerView: UIScrollView, MailSendWebViewDelegate {
    var editionInputView: LKTokenInputView?
    private(set) var webView: MailSendWebView
    let normalInputViewHeight = 26
    var currentAddressEntity: MailClientAddress? {
        MailLogger.log(level: .info, message: "alladdresses count: \(allAddresses.count)")
        return allAddresses.first(where: { fromInputView.aliasAddress.address == $0.address })
    }
    var allAddresses = [MailClientAddress]()

    weak var safeSendController: MailSendController?
    weak var sendController: MailSendController! {
        didSet {
            safeSendController = sendController
            subjectCoverEditorView.delegate = sendController
            webView.responderDelegate = sendController
            calendarView.delegate = sendController
        }
    }
    var showCollaTips = false
    var isOOO = false
    var needRefreshSignature = false
    private let disposeBag = DisposeBag()
    let bottomView = UIView()
    lazy var attachmentTopMarginView = UIView()
    lazy var attachmentBottomMarginView = UIView()
    lazy var attachmentBottomSeparator = UIView()
    let webTopMarginView = UIView()

    var isSubjectFieldEditing: Bool {
        return subjectCoverInputView.textView.isFirstResponder
    }

    var coverEntryButton: UIButton {
        return subjectCoverInputView.actionButton
    }

    var featureManager: UserFeatureManager {
        sendController.accountContext.featureManager
    }

    lazy var mailPickerEnable: Bool = featureManager.open(.mailPicker)
    lazy var contentView: UIStackView = {
        let stackView = UIStackView(frame: bounds)
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = 0.0
        return stackView
    }()

    lazy var fromInputView: AliasInputView = {
        let fromInputView = AliasInputView()
        fromInputView.accessibilityIdentifier = MailAccessibilityIdentifierKey.FieldSendFromKey
        return fromInputView
    }()

    lazy var toInputView: LKTokenInputView = {
        let inputView = createInputView()
        inputView.fieldName = BundleI18n.MailSDK.Mail_Normal_ToColon
        inputView.accessoryView = showCcInputButton()
        if mailPickerEnable {
            inputView.firstRespAccessoryView = createContactPickerButton(tokenView: inputView)
        }
        inputView.textField.accessibilityIdentifier = MailAccessibilityIdentifierKey.FieldSendToKey
        return inputView
    }()

    lazy var ccInputView: LKTokenInputView = {
        let inputView = createInputView()
        inputView.fieldName = BundleI18n.MailSDK.Mail_Normal_CcColon
        if mailPickerEnable {
            inputView.firstRespAccessoryView = createContactPickerButton(tokenView: inputView)
        }
        inputView.textField.accessibilityIdentifier = MailAccessibilityIdentifierKey.FieldSendCcKey
        return inputView
    }()

    lazy var bccInputView: LKTokenInputView = {
        let inputView = createInputView()
        inputView.fieldName = BundleI18n.MailSDK.Mail_Normal_BccColon
        if mailPickerEnable {
            inputView.firstRespAccessoryView = createContactPickerButton(tokenView: inputView)
        }
        inputView.textField.accessibilityIdentifier = MailAccessibilityIdentifierKey.FieldSendBccKey
        return inputView
    }()

    private var selectedCover: MailSubjectCover?
    private var currentKeyboardHeight: CGFloat = 0

    lazy var coverVM = MailCoverDisplayViewModel(
        scene: .MailDraft,
        photoProvider: OfficialCoverPhotoDataProvider(
            configurationProvider: sendController.accountContext.provider.configurationProvider,
            imageService: sendController.accountContext.imageService
        )
    )

    var coverStateSubject: BehaviorSubject<MailCoverDisplayState> {
        return coverVM.coverStateSubject
    }

    func setupInputViewWindow() {
        if self.window != nil {
            self.toInputView.tokenViews.forEach { view in
                if view.dragDropConfig.dragFloatView == nil {
                    view.dragDropConfig.dragFloatView = self.window
                    view.dragDropConfig.targetInputViews = self.toInputView.dragDropTargetInputViews
                }
            }
            self.bccInputView.tokenViews.forEach { view in
                if view.dragDropConfig.dragFloatView == nil {
                    view.dragDropConfig.dragFloatView = self.window
                    view.dragDropConfig.targetInputViews = self.bccInputView.dragDropTargetInputViews
                }
            }
            self.ccInputView.tokenViews.forEach { view in
                if view.dragDropConfig.dragFloatView == nil {
                    view.dragDropConfig.dragFloatView = self.window
                    view.dragDropConfig.targetInputViews = self.ccInputView.dragDropTargetInputViews
                }
            }
        }
    }

    func showCcInputButton() -> UIButton {
        let button: UIButton = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: 14, height: 14)
        button.setImage(UDIcon.avSetDownOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.ud.iconN3
        button.rx.tap.subscribe(onNext: { [weak self] in
            guard let `self` = self else { return }
            self.isCCandBCCNeedShow = true
        }).disposed(by: disposeBag)
        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: PointerStyle(
                    effect: .highlight
                )
            )
            button.addLKInteraction(pointer)
        }
        return button
    }

    func createContactPickerButton(tokenView: LKTokenInputView) -> UIButton {
        let button: UIButton = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: 18, height: 18)
        button.setImage(UDIcon.moreAddOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.ud.iconN3
        button.isHidden = true
        button.rx.tap.subscribe(onNext: { [weak tokenView, weak self] in
            guard let self = self else { return }
            guard let token = tokenView else { return }
            self.safeSendController?.showContactPicker(tokenView: token)
        }).disposed(by: disposeBag)
        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: PointerStyle(
                    effect: .highlight
                )
            )
            button.addLKInteraction(pointer)
        }
        return button
    }

    // 用于 Cc/Bcc 的折叠展开
    var isCCandBCCNeedShow: Bool = false {
        didSet {
            toInputView.accessoryView = isCCandBCCNeedShow ? nil : showCcInputButton()
            ccInputView.isHidden = !isCCandBCCNeedShow
            bccInputView.isHidden = !isCCandBCCNeedShow
        }
    }

    lazy var attachmentsContainer: MailSendAttachmentContainer = {
        let fg = featureManager.open(.attachmentLocation, openInMailClient: true)
        let attachmentAtTop = Store.settingData.getCachedPrimaryAccount()?.mailSetting.attachmentLocation == .top
        let container = MailSendAttachmentContainer(frame: .zero,
                                                    attachmentLocationFG: fg,
                                                    attachmentAtTop: fg && attachmentAtTop) // 多一层保护，fg 关闭时即使设置项有异常也必定是附件置底
        container.backgroundColor = UIColor.ud.bgBody
        container.isHidden = true
        return container
    }()

    /// 添加或者删减attachment后修改attachment的高度
    func updateAttachmentContainerLayout(toBottom: Bool = false) {
        attachmentsContainer.setNeedsLayout()
        if attachmentsContainer.superview != nil {
            attachmentsContainer.snp.remakeConstraints { (make) in
                make.width.equalToSuperview()
                make.height.equalTo(attachmentsContainer.preferredHeight)
            }
        }
        let noAttachment = attachmentsContainer.isEmpty
        attachmentsContainer.isHidden = noAttachment
        attachmentTopMarginView.isHidden = noAttachment
        attachmentBottomMarginView.isHidden = noAttachment
        attachmentBottomSeparator.isHidden = noAttachment
        attachmentsContainer.updateAttachmentsLayout()
        if toBottom {
            if attachmentsContainer.attachmentAtTop {
                topAttachmentViewScrollToBottom()
            } else {
                scrollToBottom()
            }
        }
    }

    func scrollToBottom() {
        DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.short, execute: { [weak self]  in
            guard let `self` = self else { return }
            self.webView.scrollView.contentOffset = .zero
            self.scrollRectToVisible(self.bottomView.frame, animated: true)
        })
    }

    func topAttachmentViewScrollToBottom() {
        DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.short, execute: { [weak self]  in
            guard let `self` = self else { return }
            self.scrollRectToVisible(self.attachmentTopMarginView.frame, animated: true)
            self.attachmentsContainer.topAttachmentScrollToBottom()
        })
    }

    lazy var subjectCoverInputView: MailSubjectFieldView = {
        let inputView = MailSubjectFieldView(frame: .zero,
                                             coverEnable: featureManager.open(.editMailCover, openInMailClient: false),
                                             priorityEnable: featureManager.open(.mailPriority, openInMailClient: false)) { [weak self] in
            guard let self = self else { return }
            self.safeSendController?.triggerAddCover()
        }
        inputView.delegate = self
        inputView.accessibilityIdentifier = MailAccessibilityIdentifierKey.FieldSendSubjectKey
        return inputView
    }()

    lazy var subjectCoverEditorView: MailCoverDisplayView = {
        let view = MailCoverDisplayView(frame: .zero,
                                        priorityEnable: featureManager.open(.mailPriority, openInMailClient: false))
        view.heightChangedDriver
            .distinctUntilChanged()
            .drive(onNext: { [weak self] _ in
                self?.adjustOffsetIfNeeded()
            }).disposed(by: disposeBag)
        return view
    }()

    // MARK: 各种高度变量
    var headerViewHeight: CGFloat {
        let attachmentsHeight: CGFloat = CGFloat(attachmentsContainer.preferredHeight)
        let spacingHeight: CGFloat = 1
        var headerViewHeight: CGFloat = 0
        if isCCandBCCNeedShow {
            headerViewHeight = toInputView.bounds.height +
                ccInputView.bounds.height +
                bccInputView.bounds.height +
                subjectCoverInputView.bounds.height +
                attachmentsHeight + spacingHeight
        } else {
            headerViewHeight = toInputView.bounds.height +
                subjectCoverInputView.bounds.height +
                attachmentsHeight + spacingHeight
        }
        headerViewHeight += fromInputView.bounds.height
        return headerViewHeight
    }
    
    lazy var calendarView: MailSendCalendarView = {
        let view = MailSendCalendarView(frame: CGRect(x: 0, y: 0, width: bounds.width, height: 64))
        view.isHidden = true
        return view
    }()

    /// 计算webview内容区域高度
    /// 并根据其高度调整滚动区域
    var webContentSize: CGSize = .zero {
        didSet {
            webView.snp.remakeConstraints { (make) in
                make.height.equalTo(webContentSize.height)
            }
        }
    }

    func updateContentHeight(_ height: CGFloat) {
        self.webContentSize = CGSize(width: self.bounds.width, height: height)
    }
    func gotoOtherPage(url: URL) {
        sendController.navigator?.push(url, from: self.sendController)
    }
    func presentPage(vc: UIViewController) {
        sendController.navigator?.present(vc, from: self.sendController)
    }
    func cacheSetToolBar(params: [String: Any]) {
        self.safeSendController?.pluginRender?.cacheSetToolBar(params: params)
    }
    func renderDone(_ status: Bool, _ param: [String: Any]) {
        if status {
            self.safeSendController?.didRenderMail(param: param)
        }
    }
    func webViewReady() {
        self.safeSendController?.slardarInit()
    }

    init(frame: CGRect, sendAction: MailSendAction, sendController: MailSendController) {
        self.sendController = sendController
        sendController.accountContext.editorLoader.sendSence = sendController.strLoadSence()
        if sendController.accountContext.editorLoader.enterpriseFG != FeatureManager.realTimeOpen(.enterpriseSignature) {
            sendController.accountContext.editorLoader.enterpriseFG = FeatureManager.realTimeOpen(.enterpriseSignature)
            sendController.accountContext.editorLoader.clearEditor(type: .enterpriseFGChange)
            if sendController.accountContext.editorLoader.enterpriseFG {
                //重新拉取一下签名
                _ = Store.settingData.getCurrentSigListData().subscribe()
            }
        }
        if sendAction == .outOfOffice {
            self.webView = sendController.accountContext.editorLoader.oooEditor
        } else {
            if FeatureManager.open(.preRender) {
                if sendAction == .new {
                    self.webView = sendController.accountContext.editorLoader.newMailEditor
                } else {
                    self.webView = sendController.accountContext.editorLoader.commonEditor
                }
            } else {
                self.webView = sendController.accountContext.editorLoader.commonEditor
            }
        }
        
        super.init(frame: frame)
        addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapContainer(_:)))
        addGestureRecognizer(tap)
        setupCoverDriver()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(mailSettingChange(_:)),
                                               name: Notification.Name.Mail.MAIL_CACHED_CURRENT_SETTING_CHANGED,
                                               object: nil)
        webView.sendWebViewDelegate = self
    }
    deinit {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: docsJSMessageName)
    }

    @objc
    func didTapContainer(_ gesture: UITapGestureRecognizer) {
        if self.sendController.aiService.myAIContext.inAIMode {
            self.sendController.aiService.onClickMaskArea(keyboardShow: false)
            return
        }
        let point = gesture.location(in: self)
        // 确保点击位置在 webview 区域
        if point.y >= webTopMarginView.frame.minY {
            webView.becomeFirstResponder()
            webView.focus()
            sendController.deactiveContactlist()
        }
    }
    
    @objc
    private func mailSettingChange(_ notification: Notification) {
        DispatchQueue.main.async {
            self.updateAliasInMainThread()
        }
    }
    func updateAliasInMainThread() {
        guard let setting = Store.settingData.getCachedCurrentSetting() else { return }
        guard let sendController = safeSendController, sendController.action != .outOfOffice else { return }
        allAddresses = setting.emailAlias.allAddresses
        if let currentAddress = currentAddressEntity {
            sendController.selectedAlias(address: currentAddress)
        } else {
            sendController.selectedAlias(address: setting.emailAlias.defaultAddress)
        }
        setupAliasView(setting.emailAlias)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setEditorView(editor: MailSendWebView) {
        let idx = contentView.arrangedSubviews.firstIndex(of: webView)
        contentView.removeArrangedSubview(webView)
        contentView.insertArrangedSubview(editor, at: idx!)
        editor.frame = webView.frame
        webView = editor
        webView.responderDelegate = sendController
    }
    
    func isCoverSelected() -> Bool {
        return selectedCover == nil ? false : true
    }
    
    func getSubjectText() -> String? {
        if selectedCover != nil {
            return subjectCoverEditorView.textView.text
        } else {
            return subjectCoverInputView.text
        }
    }

    func setSubjectText(_ text: String) {
        if selectedCover != nil {
            subjectCoverEditorView.textView.text = text.replacingOccurrences(of: "\n", with: " ")
        } else {
            subjectCoverInputView.text = text.replacingOccurrences(of: "\n", with: " ")
        }
    }

    func getMailPriority() -> MailPriorityType {
        if featureManager.open(.editMailCover), selectedCover != nil {
            return subjectCoverEditorView.mailPriority
        } else {
            return subjectCoverInputView.mailPriority
        }
    }

    func setMailPriority(_ priority: MailPriorityType) {
        if featureManager.open(.editMailCover), selectedCover != nil {
            subjectCoverEditorView.mailPriority = priority
        } else {
            subjectCoverInputView.mailPriority = priority
        }
    }

    private func createInputView() -> LKTokenInputView {
        let inputView = LKTokenInputView()
        inputView.fieldFont = UIFont.systemFont(ofSize: 14, weight: .regular)
        inputView.textFont = UIFont.systemFont(ofSize: 14, weight: .regular)
        inputView.fieldColor = UIColor.ud.textCaption
        inputView.tintColor = UIColor.ud.primaryContentDefault
        inputView.drawBottomBorder = true
        inputView.delegate = sendController

        inputView.didChangeTextObservable
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (view, text) in
            if let `self` = self {
                self.safeSendController?.handleTextDidChange(aView: view, didChangeText: text)
            }
            }).disposed(by: self.disposeBag)

        return inputView
    }

    func viewDidTransition(to size: CGSize, statInfo: MailSendStatInfo) {
        frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        toInputView.repositionViews()
        ccInputView.repositionViews()
        bccInputView.repositionViews()
        updateAttachmentContainerLayout(toBottom: false)
    }
    
    func updateCalendarView(calendarEvent: DraftCalendarEvent?) {
        if let calendar = calendarEvent {
            //"12月20日 🎦(周日 15:30-17:30(GMT+8:00:00)"
            calendarView.setupUI(isHidden: false,
                                 isEditable: calendar.editable,
                                 title: genCalendarTimeStr(basic: calendar.basicEvent),
                                 summary: genCalendarSummary(calendarEvent: calendar))
        } else {
            calendarView.setupUI(isHidden: true, isEditable: false)
        }
    }
    private func genCalendarSummary(calendarEvent: DraftCalendarEvent) -> String {
        let localtionStr = calendarEvent.location.location
        var meetingStr = ""
        for room in calendarEvent.meetingRooms {
            if room.displayName.isEmpty {
                continue
            }
            if meetingStr.isEmpty {
                meetingStr = room.displayName
            } else {
                meetingStr = meetingStr + ", " + room.displayName
            }
        }
        var summary = ""
        if !localtionStr.isEmpty {
            summary = summary + localtionStr
        }
        if !meetingStr.isEmpty {
            if summary.isEmpty {
                summary = meetingStr
            } else {
                summary = summary + ", " + meetingStr
            }
        }
        return summary
    }
    private func genCalendarTimeStr(basic: CalendarBasicEvent) -> String {
        var is12HourStyle = false
        if let provider = sendController.serviceProvider?.provider.configurationProvider {
            is12HourStyle = provider.is24HourTime
        }
        return sendController.accountContext.provider.calendarProvider?.formattCalenderTime(startTime: basic.start,
                                                                                            endTime: basic.end,
                                                                                            isAllDay: basic.isAllDay,
                                                                                            is12HourStyle: is12HourStyle) ?? ""
    }

    func setupViews(statInfo: MailSendStatInfo) {
        contentView.addArrangedSubview(fromInputView)
        contentView.addArrangedSubview(toInputView)
        contentView.addArrangedSubview(ccInputView)
        contentView.addArrangedSubview(bccInputView)
        self.isOOO = (statInfo.from == .outOfOffice)
        /// set target inputviews
        toInputView.dragDropTargetInputViews = [WeakBox(value: ccInputView), WeakBox(value: bccInputView)]
        ccInputView.dragDropTargetInputViews = [WeakBox(value: toInputView), WeakBox(value: bccInputView)]
        bccInputView.dragDropTargetInputViews = [WeakBox(value: toInputView), WeakBox(value: ccInputView)]

        if statInfo.from == .outOfOffice {
            toInputView.isHidden = true
        } else {
            contentView.addArrangedSubview(subjectCoverInputView)
            subjectCoverInputView.snp.makeConstraints { (make) in
                make.height.greaterThanOrEqualTo(48)
            }
            if featureManager.open(.editMailCover) {
                subjectCoverEditorView.snp.makeConstraints { (make) in
                    make.height.greaterThanOrEqualTo(MailCoverDisplayView.defaultCoverHeight)
                }
            }

            sendController.getCurrentAccount { (account) in
                /// if has shared account, show form
                let hasSharedAccount = Store.settingData.getAccountInfos().count > 1
                if let currentAccount = account, hasSharedAccount {
                    self.setupSharedAccountIfNeeded(currentAccount)
                }
            }
            contentView.addArrangedSubview(calendarView)
            calendarView.snp.makeConstraints { make in
                make.height.equalTo(64)
            }
        }

        if attachmentsContainer.attachmentAtTop {
            attachmentTopMarginView.isHidden = true
            attachmentBottomMarginView.isHidden = true
            attachmentBottomSeparator.isHidden = true
            contentView.addArrangedSubview(attachmentTopMarginView)
            attachmentTopMarginView.snp.makeConstraints { make in
                make.height.equalTo(12)
                make.left.right.equalToSuperview()
            }
            contentView.addArrangedSubview(attachmentsContainer)
            contentView.addArrangedSubview(attachmentBottomMarginView)
            attachmentBottomMarginView.snp.makeConstraints { make in
                make.height.equalTo(12)
                make.left.right.equalToSuperview()
            }
            attachmentBottomSeparator.backgroundColor = UIColor.ud.lineDividerDefault
            contentView.addArrangedSubview(attachmentBottomSeparator)
            attachmentBottomSeparator.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(16)
                make.right.equalToSuperview()
                make.height.equalTo(0.5)
            }
            contentView.addArrangedSubview(webTopMarginView)
            webTopMarginView.snp.makeConstraints { make in
                make.height.equalTo(10)
                make.left.right.equalToSuperview()
            }
            contentView.addArrangedSubview(webView)
            contentView.addArrangedSubview(bottomView)
            bottomView.snp.makeConstraints { (make) in
                make.top.equalTo(webView.snp.bottom)
                make.left.right.equalToSuperview()
                make.height.equalTo(24)
            }
        } else {
            contentView.addArrangedSubview(webTopMarginView)
            webTopMarginView.snp.makeConstraints { make in
                make.height.equalTo(10)
                make.left.right.equalToSuperview()
            }
            contentView.addArrangedSubview(webView)
            contentView.addArrangedSubview(attachmentsContainer)
            contentView.addArrangedSubview(bottomView)
            bottomView.snp.makeConstraints { (make) in
                make.top.equalTo(attachmentsContainer.snp.bottom)
                make.left.right.equalToSuperview()
                make.height.equalTo(24)
            }
        }
        attachmentsContainer.frame = CGRect(x: 0, y: 0, width: contentView.bounds.width, height: 0)
        bccInputView.isHidden = true
        ccInputView.isHidden = true
        fromInputView.isHidden = true
    }

    func setupSharedAccountIfNeeded(_ account: MailAccount) {
        setupSharedAccountView(account)
    }

    func setupSharedAccountView(_ account: MailAccount) {
        guard !self.isOOO else { return }
        fromInputView.actionHandler = nil
        fromInputView.snp.remakeConstraints { (make) in
            make.height.equalTo(39)
        }
        fromInputView.isHidden = false
        fromInputView.showArrow = false
    }

    func setupAliasInputViewIfNeeded() {
        if let setting = Store.settingData.getCachedCurrentSetting() {
            self.processAliasData(setting: setting)
        } else {
            Store.settingData.getCurrentAccount().subscribe { [weak self] (account) in
                guard let `self` = self else { return }
                let setting = account.mailSetting
                self.processAliasData(setting: setting)
            } onError: { (err) in
                mailAssertionFailure("setting error: \(err)")
            }.disposed(by: self.disposeBag)
        }
    }

    func processAliasData(setting: MailSetting) {
        MailLogger.log(level: .info, message: "setupAliasInputViewIfNeeded: \(setting.emailAlias.allAddresses.count)")

        self.allAddresses = setting.emailAlias.allAddresses
        if let idx = setting.emailAlias.allAddresses.firstIndex(where: { [weak self] in
            $0.address == self?.sendController.draft?.content.from.address
        }) {
            let name = Store.settingData.mailClient ? setting.emailAlias.defaultAddress.name : setting.emailAlias.allAddresses[idx].name
            self.fromInputView.resetAddress(nickName: name, addressName: setting.emailAlias.allAddresses[idx].address)
        } else if self.sendController.draft != nil {
            let address = {
                let defauleAddress = setting.emailAlias.defaultAddress.address
                if defauleAddress.isEmpty, let configAddress = setting.emailClientConfigs.first?.emailAddress {
                    return configAddress
                } else {
                    return defauleAddress
                }
            }()
            self.fromInputView.resetAddress(nickName: setting.emailAlias.defaultAddress.name, addressName: address)
            self.needRefreshSignature = true // 更换地址的时候需要刷新签名
        }
        self.setupAliasView(setting.emailAlias)
    }

    func setupAliasView(_ emailAlias: EmailAlias) {
        guard !self.isOOO else { return }
        var showArrow = emailAlias.allAddresses.filter({ !$0.address.isEmpty }).count > 1
        if featureManager.open(FeatureKey(fgKey: .sendMailNameSetting, openInMailClient: true)), sendController.accountContext.mailAccount?.protocol != .exchange {
            showArrow = true
        }
        var isHidden = !showArrow
        fromInputView.actionHandler = { [weak self] () in
            guard showArrow else {
                return
            }
            self?.sendController.onClickAlias(emailAlias)
        }
        fromInputView.showArrow = showArrow
        if Store.settingData.getAccountInfos().count > 0 {
            if Store.settingData.getAccountInfos().filter({ $0.userType != .noPrimaryAddressUser }).count > 1 {
                isHidden = false // 多账号必显示地址
            }
            self.updateFromInputViewStatus(isHidden: isHidden)
        } else {
            Store.settingData.getAccountList()
                .subscribe(onNext: { [weak self] (resp) in
                    guard let `self` = self else { return }
                    if resp.accountList.filter({ $0.mailSetting.userType != .noPrimaryAddressUser }).count > 1 {
                        isHidden = false // 多账号必显示地址
                    }
                    self.updateFromInputViewStatus(isHidden: isHidden)
                }, onError: { [weak self] (err) in
                    MailLogger.info("setupAliasView getAccountList err \(err)")
                    self?.updateFromInputViewStatus(isHidden: isHidden)
                }).disposed(by: self.disposeBag)
        }
        
    }
    func updateFromInputViewStatus(isHidden: Bool) {
        fromInputView.snp.remakeConstraints { (make) in
            make.height.equalTo(isHidden ? 0 : 39)
        }
        fromInputView.isHidden = isHidden
    }

    func setIsSp(isSp: Bool) {
        toInputView.fieldName = isSp ? BundleI18n.MailSDK.Mail_Normal_SpColon : BundleI18n.MailSDK.Mail_Normal_ToColon
        if isSp {
            let allTokens = ccInputView.tokens + bccInputView.tokens
            let filteredAll = allTokens.filterDuplicates({ $0.address })
            filteredAll.forEach { (token) in
                toInputView.addToken(token: token, reposition: false)
            }
            toInputView.repositionViews()
            ccInputView.removeAllToken()
            bccInputView.removeAllToken()
        }
        if isSp {
            isCCandBCCNeedShow = false
        }
        toInputView.accessoryView = isSp ? nil : showCcInputButton()
    }
    
    func moveBccTocc() {
        for token in bccInputView.tokens where !ccInputView.tokens.contains(where: { element in
            element.address == token.address
        }) {
            ccInputView.addToken(token: token, reposition: false)
        }
        ccInputView.repositionViews()
        bccInputView.removeAllToken()
    }

    func updateCurrentKeyboardHeight(_ height: CGFloat) {
        currentKeyboardHeight = height
        adjustOffsetIfNeeded()
    }
}

// MARK: - Cover
private extension MailSendContainerView {
    func setupCoverDriver() {
        guard featureManager.open(.editMailCover) else { return }
        subjectCoverEditorView.bind(viewModel: coverVM)
        coverVM.coverStateDriver.drive(onNext: { [weak self] state in
            guard let self = self else { return }

            switch state {
            case .none:
                self.didRemoveCover()
                self.selectedCover = nil
            case .loading(let cover):
                self.didSelectCover()
                self.selectedCover = cover
            case .loadFailed:
                ActionToast.showFailureToast(with: BundleI18n.MailSDK.Mail_Cover_MobileUnableEditTryAgain, on: self)
            default:
                break
            }
        }).disposed(by: disposeBag)
    }

    func didSelectCover() {
        if let index = contentView.arrangedSubviews.firstIndex(of: subjectCoverInputView) {
            subjectCoverInputView.removeFromSuperview()
            contentView.insertArrangedSubview(subjectCoverEditorView, at: index)
            subjectCoverEditorView.updateContent(subjectCoverInputView.textView.text)
            subjectCoverEditorView.mailPriority = subjectCoverInputView.mailPriority
            if subjectCoverInputView.textView.text.isEmpty {
                subjectCoverEditorView.becomeFirstResponder()
            }
        }
    }

    func didRemoveCover() {
        if let index = contentView.arrangedSubviews.firstIndex(of: subjectCoverEditorView) {
            subjectCoverEditorView.removeFromSuperview()
            contentView.insertArrangedSubview(subjectCoverInputView, at: index)
            subjectCoverInputView.text = subjectCoverEditorView.textView.text
            subjectCoverInputView.mailPriority = subjectCoverEditorView.mailPriority
        }
    }

    // 封面需要和键盘之间至少需要 64 的间隔
    func adjustOffsetIfNeeded() {
        guard subjectCoverEditorView.textView.isFirstResponder,
              selectedCover != nil,
              let view = safeSendController?.view
        else { return }
        let offsetY = 64 - (view.frame.height - subjectCoverEditorView.frame.bottom - currentKeyboardHeight)
        guard offsetY > 0 && offsetY > contentOffset.y else { return }
        setContentOffset(CGPoint(x: contentOffset.x, y: offsetY), animated: true)
    }
}

// MARK: - UITextFieldDelegate & UITextViewDelegate
extension MailSendContainerView: UITextFieldDelegate, UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if let char = text.first, char.isNewline {
            sendController.focusNextInputView(currentView: subjectCoverInputView)
            return false
        } else {
            sendController.subjectViewChangeText()
            return true
        }
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        subjectFieldDidBeginEditing(textView)
        if textView == subjectCoverInputView.textView {//为带封面的主题textView注册tabKey事件
            sendController.registerTabKey(currentView: subjectCoverInputView)
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView == subjectCoverInputView.textView, let text = textView.text {
            let js = "window.draftTitle = '\(text)'"
            sendController.requestEvaluateJavaScript(js) { (_, _) in }
        }
        if textView == subjectCoverInputView.textView {//为带封面的主题textView注销tabKey事件
            sendController.unregisterTabKey(currentView: subjectCoverInputView)
        }
    }

    private func subjectFieldDidBeginEditing(_ view: UIView) {
        sendController.foldAllTokenInputViews()
        sendController.firstResponder = view
        let attrItem = EditorToolBarItemInfo(identifier: EditorToolBarButtonIdentifier.attr.rawValue)
        attrItem.isEnable = false
        sendController.mainToolBar?.updateItemStatus(newItem: attrItem)
    }
}

extension MailSendContainerView {
    func updateInputViews(_ mailContent: MailContent) {
        if let index = mailContent.to.firstIndex(where: { !$0.address.isLegalForEmail() }) {
            self.toInputView.selectTokenView(at: index, animated: true)
        } else if let index = mailContent.cc.firstIndex(where: { !$0.address.isLegalForEmail() }) {
            self.ccInputView.selectTokenView(at: index, animated: true)
        } else if let index = mailContent.bcc.firstIndex(where: { !$0.address.isLegalForEmail() }) {
            self.bccInputView.selectTokenView(at: index, animated: true)
        }
    }

    func saveTextToToken() {
        /// 如果to/cc/bcc中已有文字，但是还没有形成 token
        /// 先将文字变成 token，再进行下面的逻辑
        _ = toInputView.tokenizeTextfieldText()
        _ = ccInputView.tokenizeTextfieldText()
        _ = bccInputView.tokenizeTextfieldText()
    }
    
    func updateToInputView(toAddress: [MailAddress]) {
        toInputView.removeAllToken()
        toAddress.forEach { (addressModel) in
            toInputView.addToken(token: self.addressModelToToken(addressModel), reposition: false)
        }
        toInputView.repositionViews()
    }
    func updateCCInputView(ccAddress: [MailAddress]) {
        ccInputView.removeAllToken()
        ccAddress.forEach { (addressModel) in
            ccInputView.addToken(token: self.addressModelToToken(addressModel), reposition: false)
        }
        ccInputView.repositionViews()
        if ccAddress.count > 0 {
            self.isCCandBCCNeedShow = true
        }
    }
    func updateBCCInputView(bccAddress: [MailAddress]) {
        bccInputView.removeAllToken()
        bccAddress.forEach { (addressModel) in
            bccInputView.addToken(token: self.addressModelToToken(addressModel), reposition: false)
        }
        bccInputView.repositionViews()
        if bccAddress.count > 0 {
            self.isCCandBCCNeedShow = true
        }
    }

    func updateInputView(content: MailContent, mailtoSubject: String?) {
        if let mailtoSubject = mailtoSubject {
            setSubjectText(mailtoSubject)
        } else {
            setSubjectText(content.subject)
        }
        if featureManager.open(.mailPriority, openInMailClient: false) {
            setMailPriority(content.priorityType)
        }
        if featureManager.open(.editMailCover), let cover = content.subjectCover {
            coverStateSubject.onNext(.loading(cover))
        } else {
            coverStateSubject.onNext(.none)
        }
        /// 全量数据，先删除老数据
        toInputView.removeAllToken()
        ccInputView.removeAllToken()
        bccInputView.removeAllToken()

        content.to.forEach { (addressModel) in
            toInputView.addToken(token: self.addressModelToToken(addressModel), reposition: false)
        }
        toInputView.repositionViews()
        content.cc.forEach { (addressModel) in
            ccInputView.addToken(token: self.addressModelToToken(addressModel), reposition: false)
        }
        ccInputView.repositionViews()
        content.bcc.forEach { (addressModel) in
            bccInputView.addToken(token: self.addressModelToToken(addressModel), reposition: false)
        }
        bccInputView.repositionViews()
    }

    private func addressModelToToken(_ addressModel: MailAddress) -> LKToken {
        var viewModel = MailAddressCellViewModel()
        viewModel.address = addressModel.address
        viewModel.name = addressModel.name
        viewModel.larkID = addressModel.larkID
        viewModel.type = addressModel.type
        viewModel.tenantId = addressModel.tenantId
        viewModel.displayName = addressModel.displayName
        viewModel.currentTenantID = sendController.accountContext.user.tenantID
        let token = LKToken()
        token.displayName = addressModel.displayName
        token.name = addressModel.name
        token.address = addressModel.address
        if statusIsError(address: addressModel) {
            token.status = .error
        }
        token.context = viewModel as AnyObject
        return token
    }

    func hideAllTokens() {
        ccInputView.showAllTokens = false
        toInputView.showAllTokens = false
        bccInputView.showAllTokens = false
    }
    // 判断token的status是否是正常状态，群组地址允许为空
    func statusIsError(address: MailAddress) -> Bool {
        return !( (address.type == .group && address.address.isEmpty) || address.address.isLegalForEmail() )
    }
    func statusIsError(address: MailAddressCellViewModel) -> Bool {
        return !( (address.type == .group && address.address.isEmpty) || address.address.isLegalForEmail() )
    }
}
