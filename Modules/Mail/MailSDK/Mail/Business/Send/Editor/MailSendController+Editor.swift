//
//  MailSendController+Editor.swift
//  DocsSDKDemo
//
//  Created by majx on 2019/6/7.
//

import Foundation
import WebKit
import RxSwift
import Homeric
import LarkLocalizations
import EENavigator
import UniverseDesignTheme
import LarkAlertController
import RustPB
import LarkWebViewContainer
import UniverseDesignActionPanel
import UniverseDesignToast

struct EditorToolBarConfig {
    var toolBarHeight: CGFloat
    var toolBarOffsetY: CGFloat
    var subPanelHeight: CGFloat
    var subPanelOffsetY: CGFloat = 0
    var keyboardHeight: CGFloat = 0
    var keyboardOffsetY: CGFloat = 0
    var keyboardLockHeight: CGFloat = 80
    var subPanelDefaultHeight: CGFloat = 313
    init(_ maxHeight: CGFloat) {
        let trueToolBarHeight: CGFloat = 44
        let trueSubPanelHeight: CGFloat = 260
        subPanelHeight = trueSubPanelHeight + Display.bottomSafeAreaHeight
        toolBarHeight = trueToolBarHeight + Display.bottomSafeAreaHeight
        toolBarOffsetY = maxHeight - toolBarHeight
        subPanelOffsetY = maxHeight
        keyboardOffsetY = maxHeight
    }
}

// MARK: - EditorWebViewResponderDelegate
extension MailSendController: EditorWebViewResponderDelegate {
    func editorWebViewDidBecomeFirstResponder(_ webView: WKWebView) {
        /// 当 webview 获取焦点后，更新 toolbar 状态，将 A 设为可用
        updateToolBarItem(type: .attr, isEnabled: true)
        updateToolBarItem(type: .insertImage, isEnabled: true)
        foldAllTokenInputViews()
        firstResponder = scrollContainer.webView
        self.unregisterTabKey(currentView: webView)
        self.unregisterLeftKey(currentView: webView)
        self.unregisterRightKey(currentView: webView)
        fixPadMagicKeyboard(isHidden: false)
    }
    func fixPadMagicKeyboard(isHidden: Bool) {
        guard Display.pad else {
            return
        }
        self.mainToolBar?.isHidden = isHidden
    }

    func editorWebViewDidResignFirstResponder(_ webView: WKWebView) {
        /// 当 webview 失去焦点后，更新 toolbar 状态，将 A 设为不可用
        updateToolBarItem(type: .attr, isEnabled: false)
        updateToolBarItem(type: .insertImage, isEnabled: false)
        firstResponder = nil
        fixPadMagicKeyboard(isHidden: true)
    }

    func updateToolBarItem(type: EditorToolBarButtonIdentifier, isEnabled: Bool) {
        let attrItem = EditorToolBarItemInfo(identifier: type.rawValue)
        attrItem.isEnable = isEnabled
        if type == .attr || type == .insertImage {
            mainToolBar?.isAttributionEnabled = isEnabled
        }
        mainToolBar?.updateItemStatus(newItem: attrItem)
    }
}

// MARK: - EditorToolBarUIDelegate
extension MailSendController {
    func insertAttachment(fileModel: MailSendFileModel) {
        let size = accountContext.featureManager.open(.largeAttachment) ? MailSendAttachmentViewModel.singleAttachemntMaxSize :
            attachmentViewModel.availableSize
        let sizeGB = size / (1024 * 1024 * 1024)
        let limitSize = String("\((contentChecker.mailLimitSize)) MB")
        var wording = accountContext.featureManager.open(.largeAttachment) ? BundleI18n.MailSDK.Mail_Attachment_MaximumFileSize(sizeGB) :
            BundleI18n.MailSDK.Mail_Attachment_OverLimit(limitSize)
        let fileModelSize = fileModel.size ?? 0
        MailLogger.info("[mail_client_attach] insertAttachment fileModel.size: \(fileModelSize / 1024 / 1024) size: \(size / 1024 / 1024)")
        if Store.settingData.mailClient {
            let fileSizeMB = Int(fileModelSize / 1024 / 1024)
            let sizeMB = Int(size / 1024 / 1024)
            guard fileModelSize <= size else {
                let alert = LarkAlertController()
                alert.setTitle(text: BundleI18n.MailSDK.Mail_ThirdClient_FailedToUpload)
                alert.setContent(text: BundleI18n.MailSDK.Mail_ThirdClient_FailedToUploadDesc)
                alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_ThirdClient_FailedToUploadConfirm)
                navigator?.present(alert, from: self)
                return
            }
        }
        guard fileModelSize <= size else {
            MailRoundedHUD.showFailure(with: wording, on: self.view,
                                       event: ToastErrorEvent(event: .send_insert_attachment_overlimit))
            return
        }
        let insertBlock: ([MailSendFileModel]) -> Void = { [weak self] (fileModels) in
            guard let `self` = self else { return }
            let attachments = self.createMailSendAttachments(localFiles: fileModels)
            self.scrollContainer.attachmentsContainer.addAttachments(attachments, permCode: self.baseInfo.mailItem?.code)
            self.attachmentViewModel.appendAttachments(attachments, toBottom: true)
            MailTracker.log(event: Homeric.EMAIL_DRAFT_ADD_ATTACHMENT, params: [MailTracker.sourceParamKey(): MailTracker.source(type: .toolbar)])
            for attachment in attachments {
                // event
                let event = NewCoreEvent(event: .email_email_edit_click)
                event.params = ["target": "none",
                                "click": "attachment",
                                "attachment_type": "local_upload",
                                "is_large": attachment.type == .large ? "true" : "false"]
                event.post()
            }
        }
        // 如果上传文件需要转为超大附件，需要提示
        if !accountContext.featureManager.open(.largeAttachmentManage, openInMailClient: false) &&
            accountContext.featureManager.open(.largefileUploadOpt) &&
            accountContext.featureManager.open(.largeAttachment) &&
            fileModelSize > attachmentViewModel.availableSize {
            let alert = largeFileAlert(num: 1)
            alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_Common_Confirm, dismissCompletion: { [weak self] in
                insertBlock([fileModel])
            })
            navigator?.present(alert, from: self)
        } else {
            if FeatureManager.open(.largeAttachmentManagePhase2, openInMailClient: false) &&
                fileModelSize > attachmentViewModel.availableSize {
                LarkAlertController.showAttachmentAlert(accountContext: self.accountContext, from: self, navigator: self.accountContext.navigator, limitSize:limitSize, userStore: self.accountContext.userKVStore) {
                    insertBlock([fileModel])
                }
            } else {
                insertBlock([fileModel])
            }
        }
    }
    func largeFileAlert(num: Int) -> LarkAlertController {
        let alert = LarkAlertController()
        let size = String("\((contentChecker.mailLimitSize)) MB")
        let text = BundleI18n.MailSDK.Mail_LargeAttachmentExceedLimit_Description(size: size, num: num)
        alert.setTitle(text: BundleI18n.MailSDK.Mail_LargeAttachmentExceedLimit_Title(num))
        alert.setContent(text: text)
        alert.addCancelButton()
        return alert
    }

    func getThreadId() -> String? {
        nil
    }

    func getDraftId() -> String? {
        return draft?.id
    }

    // 点击附件
    func didClickAttachment() {
        requestHideKeyBoard()
        didClickAddAttachment()
    }

    // 更新工具条
    func updateMainToolBar(bar: EditorMainToolBarPanel) {
        DispatchQueue.main.async {
            if bar === self.mainToolBar { return }
            self.mainToolBar?.removeFromSuperview()
            self.view.addSubview(bar)
            bar.frame = CGRect(x: 0, y: self.toolbarConfig.toolBarOffsetY,
                               width: self.view.bounds.width,
                               height: self.toolbarConfig.toolBarHeight)
            self.mainToolBar = (bar as? MailMainToolBar)
            self.mainToolBar?.isHidden = true
            // ipad上，存在妙控键盘导致不展示toolbar的问题，当firstResponder为webview设置展示
            if Display.pad && self.firstResponder == self.scrollContainer.webView {
                self.mainToolBar?.isHidden = false
            }
            self.mainToolBar?.isAttributionEnabled = self.firstResponder == self.scrollContainer.webView
        }
    }

    // 更新子面板
    func updateSubToolBarPanel(bar panel: EditorSubToolBarPanel, info: EditorToolBarItemInfo) {
        DispatchQueue.main.async {
            self.toolBarSubPanel = panel
            if EditorToolBarButtonIdentifier(rawValue: info.identifier) != nil {
//                if info.identifier == "attribution" {
//                    // TODO Attach
//                    self.updateSubToolBarPanel(panel, popAnimate: true)
//                } else {
                    self.updateSubToolBarPanel(panel)
//                }
            }
        }
    }

    func resetPanel() {
        updateSubToolBarPanel(nil)
        mainToolBar?.reset()
    }

    func updateSubToolBarPanel(_ newPanel: EditorSubToolBarPanel?) {
        if #available(iOS 13.0, *) {
            let correctTrait = UITraitCollection(userInterfaceStyle: UDThemeManager.userInterfaceStyle)
            UITraitCollection.current = correctTrait
        }
        if let panel = newPanel {
            /// 这里通过 Tricky 的方式去让 panel 覆盖键盘，达到切换面板的目的
            /// warning: 需要注意处理第三方键盘，注意不要覆盖掉键盘外的其他 view
            /// 原因：主要原因是此页面是 Native + WebView 页面结构，且只有单个工具条
            /// webview 无法通过 becomeFirstResponder() 方法重新获取焦点
            /// 导致二级面板打开再隐藏后，无法恢复焦点，同时也会丢失光标
            /// 而通过更改 webview.inputView 的方式，会其他textfield.inputView不一致的问题
            /// 找到 keyboardView，将面板添加到 window 上，frame和keyboardView保持一致
            /// 不添加到 keyboardView 是为了挡住 keyboardView 点击响应
            var keyboardNotShow = true
            func showPanel(_ panel: EditorSubToolBarPanel, _ animation: Bool = false) {
                self.scrollContainer.webView.inputAccessory.realInputView = panel
                self.scrollContainer.webView.inputAssistantItem.trailingBarButtonGroups = []
                self.scrollContainer.webView.inputAssistantItem.leadingBarButtonGroups = []
                var animationDuration = 0.3
                var animationCurve = UIView.AnimationOptions.curveEaseInOut
                // update keyboard frame
                if let option = self.keyBoard.options {
                    let op = Keyboard.KeyboardOptions.init(event: .willChangeFrame,
                                                           beginFrame: option.beginFrame,
                                                           endFrame: option.endFrame,
                                                           animationCurve: option.animationCurve,
                                                           animationDuration: option.animationDuration,
                                                           isShow: true,
                                                           trigger: "")
                    handleKeyBoardOptions(op)
                    let shift: UInt = 16
                    animationDuration = option.animationDuration
                    animationCurve = UIView.AnimationOptions.init(rawValue: UInt( option.animationCurve.rawValue << shift))
                }
                panel.isHidden = false
                /// 添加子面板
                if animation {
                    panel.alpha = 0.0
                    UIView.animate(withDuration: animationDuration) {
                        panel.alpha = 1.0
                    }
                } else {
                    UIView.animate(withDuration: animationDuration,
                                   delay: 0,
                                   options: animationCurve,
                                   animations: {
                        panel.alpha = 1.0
                    }, completion: nil)
                }
                keyboardNotShow = false
            }
            showPanel(panel)
            /// 如果当前未显示键盘，则直接抬升键盘，再次调用显示面板
            if keyboardNotShow {
                /// scrollContainer.webView 获取焦点
                self.scrollContainer.webView.focus()
                /// 再次显示面板
                let delayTime: Double = 0.2
                DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) {
                    showPanel(panel, true)
                }
            }
        } else {
            /// 如果无子面板，则去掉 EditorSubToolBarPanel，显示键盘
            self.scrollContainer.webView.inputAccessory.realInputView = nil
            self.scrollContainer.webView.inputAssistantItem.trailingBarButtonGroups = []
            self.scrollContainer.webView.inputAssistantItem.leadingBarButtonGroups = []
            if let option = self.keyBoard.options {
                let op = Keyboard.KeyboardOptions.init(event: .willChangeFrame,
                                                       beginFrame: option.beginFrame,
                                                       endFrame: option.endFrame,
                                                       animationCurve: option.animationCurve,
                                                       animationDuration: option.animationDuration,
                                                       isShow: true,
                                                       trigger: "")
                handleKeyBoardOptions(op)
            }

        }
    }

    // 显示键盘
    func requestDisplayKeyBoard() {
        DispatchQueue.main.async {
            self.updateSubToolBarPanel(nil)
        }
    }

    func recoverFocusStatus() {
        guard let lastResponderView = lastResponderView else {
            scrollContainer.subjectCoverInputView.becomeFirstResponder()
            return
        }

        if lastResponderView == scrollContainer.webView {
            scrollContainer.webView.focusAtEditor()
        } else {
            lastResponderView.becomeFirstResponder()
        }
    }

    // 收起键盘
    func requestHideKeyBoard() {
        view.endEditing(true)
        self.scrollContainer.webView.endEditing(true)
        /// 清理子面板
        self.scrollContainer.webView.inputAccessory.realInputView = nil
        self.view.subviews.filter({ $0 is EditorSubToolBarPanel }).forEach({ $0.removeFromSuperview() })
    }

    func signatureEditClicked() {
        requestHideKeyBoardIfNeed()
        let vc = MailSendSignatureListVC(accountContext: accountContext)
        vc.modalPresentationStyle = .overCurrentContext
        vc.delegate = self
        navigator?.present(vc, from: self, animated: false)
    }
    func requestHideKeyBoardIfNeed() {
        self.scrollContainer.webView.inputAccessory.realInputView = nil
        view.endEditing(true)
        self.scrollContainer.webView.endEditing(true)
        hideMainToolBar()
        self.view.subviews.filter({ $0 is EditorSubToolBarPanel }).forEach({ $0.removeFromSuperview() })
    }

    private func hideMainToolBar() {
        let option = Keyboard.KeyboardOptions(
            event: .willHide,
            beginFrame: .zero,
            endFrame: CGRect(x: 0,
                             y: UIScreen.main.bounds.size.height,
                             width: UIScreen.main.bounds.size.width,
                             height: 0),
            animationCurve: self.keyBoard.options?.animationCurve ??
                UIView.AnimationCurve.linear,
            animationDuration: self.keyBoard.options?.animationDuration ?? 0,
            isShow: false,
            trigger: "byCode")
        self.handleKeyBoardOptions(option)
    }

    // 调用js的方法
    func requestEvaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)?) {
        scrollContainer.webView.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }

    func getScreenSize() -> CGSize {
        return self.view.bounds.size
    }
}

// JS 通信
extension MailSendController: EditorExecJSService {

    // 获取html内容
    func getSendContent(_ scene: String) -> Observable<Any?> {
        if scene == "send" {
            self.scrollContainer.webView.sendCallTime = MailTracker.getCurrentTime()
        }
        return requestEvaluateJavaScript("window.command.getSendContent(`\(scene)`)")
    }

    func getDraftContent(_ scene: String) -> Observable<Any?> {
        guard self.draft != nil else { return Observable.empty() }
        self.scrollContainer.webView.saveCallTime = MailTracker.getCurrentTime()
        return requestEvaluateJavaScript("window.command.getDraftContent(`\(scene)`)")
    }

    func evaluateJS(js: String) {
        scrollContainer.webView.evaluateJavaScript(js, completionHandler: nil)
    }

    // 调用js方法
    func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)? = nil) {
        scrollContainer.webView.evaluateJavaScript(javaScriptString) { (res, err) in
            if let err = err {
                // 只打印function name，不打印具体参数
                var jsString = javaScriptString
                if let index = javaScriptString.firstIndex(of: "(") {
                    jsString = String(javaScriptString[javaScriptString.startIndex..<index])
                }
                if let index = jsString.firstIndex(of: "=") {
                    jsString = String(jsString[jsString.startIndex..<index])
                }
                mailAssertionFailure("editor evaluate js \(jsString) error: \(err)")
            }
            completionHandler?(res, err)
        }
    }

    // js方法调用，observable版
    @discardableResult
    func requestEvaluateJavaScript(_ javaScriptString: String) -> Observable<Any?> {
        let webView = scrollContainer.webView
        return Observable.create { [weak webView] observer in
            guard let webView = webView else { return Disposables.create() }

            webView.evaluateJavaScript(javaScriptString) { (value, error) in
                if let error = error {
                    mailAssertionFailure("error: \(error), js: \(javaScriptString)")
                    observer.onError(error)
                } else {
                    observer.onNext(value)
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
}



// MARK: - 页面滚动处理 UIScrollViewDelegate
extension MailSendController {
    // 用来处理 Webview 和 Native 的滚动
    // TODO: 这里需要优化成 webView contentOffset 的联合滚动
    func _scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollContainer == scrollView else { return }
        let webScrollView = scrollContainer.webView.scrollView
        let offsetY = scrollView.contentOffset.y
        if offsetY <= 0 {
            /// 滑动距离为负
            /// 可以在背景加上 “下拉收起键盘的提示”
            scrollContainer.contentView.transform = CGAffineTransform(translationX: 0, y: offsetY)
            webScrollView.contentOffset = .zero
        }

        if let startOffsetY = startOffsetY {
            totalDistance += abs(scrollView.contentOffset.y - startOffsetY)
        }
        startOffsetY = scrollView.contentOffset.y
        if scrollView.isTracking || scrollView.isDecelerating {
            self.aiService.weakModeScrollByUser = true
        }
    }

    func _scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView == scrollContainer {
            deactiveContactlist()
        }
    }
}

extension MailSendController: MailDocsInfoDelegate {
    func removeAddress(index: Int) {
        editionInputView?.removeTokenAtIndex(index: index)
    }

    func getWebview() -> WKWebView {
        return scrollContainer.webView
    }

    func resignEditorFocus() {
        scrollContainer.webView.resignFirstResponder()
    }

    func updateAddress(addressModels: [MailAddressCellViewModel], type: CollaOpType) {
        var targetInputView: LKTokenInputView?
        if type == .to {
            targetInputView = scrollContainer.toInputView
        } else if type == .cc {
            targetInputView = scrollContainer.ccInputView
        } else if type == .bcc {
            targetInputView = scrollContainer.bccInputView
        }
        targetInputView?.removeAllToken()
        _ = addressModels.map { (model) -> LKToken in
            let token = LKToken()
            token.name = model.name
            token.displayName = model.displayName
            token.address = model.address
            token.context = model as AnyObject
            _ = targetInputView?.addToken(token: token, shouldClearText: false)
            return token
        }
    }
    
    func setSubject(_ subject: String) {
        guard !scrollContainer.isSubjectFieldEditing else {
            return
        }
        scrollContainer.setSubjectText(subject)
    }

    func currentViewController() -> UIViewController {
        return self
    }

    func getDocsInfo(url: String) -> MailClientDocsPermissionConfig? {
        guard let docsCofig = draft?.content.docsConfigs.first(where: { $0.docURL == url }) else { return nil }
        return docsCofig
    }

    func currentAttachments() -> [MailSendAttachment] {
        return scrollContainer.attachmentsContainer.attachmentViews.map { $0.attachment }
    }

    func didReceiveMailContent(content: [String: Any], isSend: Bool) {
        if let scene = content["scene"] as? String, scene == SendScene.getDraft.rawValue {
            return
        }
        if var text = content["text"] as? String {
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)
            self.hasContent =  !text.isEmpty
        }
        if let param = content["eventStatistic"] as? [String: Any] {
            if isSend {
                self.sendEditorParam = param
                self.scrollContainer.webView.sendReceiveTime = MailTracker.getCurrentTime()
            } else {
                self.saveDraftParam = param
                self.scrollContainer.webView.saveReceiveTime = MailTracker.getCurrentTime()
            }
        }
        MailTracker.endRecordTimeConsuming(event: Homeric.MAIL_DEV_SEND_MAIL_COST_TIME, params: nil)
        guard var draft = draft else { mailAssertionFailure("must have draft"); return }
        let getHtmlms = MailAPMEvent.SendDraft.EndParam.time_get_html(Date().timeIntervalSince(tempDate ?? Date()) * 1000)
        self.apmHolder[MailAPMEvent.SendDraft.self]?.endParams.append(getHtmlms)

        guard let editorData = convertSendContent(sendContent: content) else { mailAssertionFailure("empty data"); return }
        let tempContent = viewModel.createMailContentWithEmailAddress()
        draft.lastUpdatedTimestamp = Int64(Date().timeIntervalSince1970 * 1000)
        draft.content.to = tempContent.to
        draft.content.cc = tempContent.cc
        draft.content.bcc = tempContent.bcc
        draft.content.attachments = getSuccessUploadedAttachments()
        draft.content.subject = scrollContainer.getSubjectText() ?? ""
        draft.content.priorityType = scrollContainer.getMailPriority()
        if let address = scrollContainer.currentAddressEntity {
            draft.fromAddress = address.address
            draft.fromName = address.name
            draft.fromEntityId = address.larkEntityIDString
            draft.content.from.name = address.name
            draft.content.from.address = address.address
            draft.content.from.larkID = address.larkEntityIDString
            draft.content.from.displayName = address.displayName
            let currentTenantId = accountContext.user.tenantID ?? "0"
            draft.content.from.tenantId = address.tenantID == "0" ? currentTenantId : address.tenantID // rust大哥们不想兜底，自己兜底吧。
        }
        handleEditorData(draft: &draft, editorData: editorData)
        if draft.isSendSeparately {
            draft.content.bcc = draft.content.to
            draft.content.to = []
        }
        self.draft = draft
        let bodyLengthParam = MailAPMEvent.SendDraft.EndParam.mail_body_length(draft.content.bodyHtml.count)
        apmHolder[MailAPMEvent.SendDraft.self]?.endParams.append(bodyLengthParam)

        if isSend {
            didProcessSendMail(scene: SendScene(rawValue: editorData.scene) ?? .draft)
        } else {
            didProcessDraft()
        }
    }

    func handleEditorData(draft: inout MailDraft, editorData: sendContent) {
        // 对齐android逻辑, 需要将前端生成的签名图片添加到内容中
        let imagesToAppend = editorData.imageList.filter { info in
            return !draft.content.images.map { info in
                return info.uuid
            }.contains(info.uuid)
        }
        draft.content.images.append(contentsOf: imagesToAppend)
        // TODO: editorData
        draft.content.docsConfigs = editorData.docLinkConfigs
        draft.content.bodyHtml = editorData.bodyHtml
        draft.content.bodySummary = editorData.plainText
    }

    // 包含直接发送和定时发送前的检查
    func didProcessSendMail(scene: SendScene) {
        guard var draft = draft else { mailAssertionFailure("must have draft"); return }

        if scene == .scheduleSend {
            self.sendMail(content: draft.content, scheduleSendTime: self.scheduleSendTime)
            return
        }

        if draft.isSendSeparately {
            MailTracker.log(event: "email_send_separately_result", params: nil)
        }
        let checkResult = checkSendEnableResult(draft: draft)
        self.needShowConvertToLargeTips = false
        // 检查转发的小附件是否超过大小
        if accountContext.featureManager.open(.autoTranslateAttachment) &&
            draft.content.calculateMailSize() > Float(contentChecker.mailLimitSize) &&
            draft.content.calculateMailSize(ignoreAttachment: true) < Float(contentChecker.mailLimitSize) {
            var flag = false
            let atts = draft.content.attachments.map { (attItem) -> MailAttachment in
                var tem = attItem
                if tem.type != .large {
                    flag = true
                    if !accountContext.featureManager.open(.largeAttachmentManage, openInMailClient: false) {
                        tem.expireTime = MailSendAttachment.genExpireTime()
                    }
                    tem.needConvertToLarge = true
                }
                return tem
            }
            if flag {
                self.needShowConvertToLargeTips = true
            }
            draft.content.attachments = atts
        }

        // 定时前检查
        if scene == .scheduleSendCheck {
            if contentChecker.showSendCheckResultAlert(checkResult, draft.content, nil) {
                return
            }
            // type must be init with 0, so the checker will go through all the check case.
            contentChecker.sendCheckTips(type: TipsTypeSendCheck.invalidFile,
                                         attachmentViewModel: self.attachmentViewModel,
                                         mailContent: draft.content,
                                         calendarEvent: draft.calendarEvent,
                                         sendSep: draft.isSendSeparately,
                                         isRecipientOverLimit: self.recipientOverLimit,
                                         recipientLimit: self.recipientLimit) { [weak self] _ in
                guard let `self` = self else { return }
                // 弹出定时选择框
                let vc = MailScheduleSendController(accountContext: self.accountContext)
                vc.delegate = self
                vc.modalPresentationStyle = .fullScreen
                self.navigator?.present(vc, from: self)
            } cancelCompletion: { [weak self] in
                self?.apmEndSendCustom(status: .status_user_cancel)
            }
        // 直接发送
        } else if scene == .send {
            if contentChecker.showSendCheckResultAlert(checkResult, draft.content, {
                self.sendMail(content: draft.content, scheduleSendTime: self.scheduleSendTime)
            }) {
                return
            }
            // type must be init with 0, so the checker will go through all the check case.
            contentChecker.sendCheckTips(type: TipsTypeSendCheck.invalidFile,
                                         attachmentViewModel: self.attachmentViewModel,
                                         mailContent: draft.content,
                                         calendarEvent: draft.calendarEvent,
                                         sendSep: draft.isSendSeparately,
                                         isRecipientOverLimit: self.recipientOverLimit,
                                         recipientLimit: self.recipientLimit) { [weak self] (content) in
                guard let `self` = self else { return }
                self.sendMail(content: content, scheduleSendTime: self.scheduleSendTime)
            } cancelCompletion: { [weak self] in
                self?.apmEndSendCustom(status: .status_user_cancel)
            }
        }
    }

    // 校验图片附件上传状态
    func checkSendEnableResult(draft: MailDraft) -> MailSendContentChecker.SendEnableCheckResult {
        let isContainsErrorImg = pluginRender?.imageHandler?.isContainsErrorImg ?? false
        let isContainsUploadingImg = pluginRender?.imageHandler?.isContainsUploadingImg ?? false
        let mailCoverState = (try? scrollContainer.coverStateSubject.value()) ?? .none
        contentChecker.updateErrorUploadCount(imgHandler: pluginRender?.imageHandler, attachmentViewModel) // 更新上传失败的附件和图片数量
        return self.contentChecker.sendEnbleResult(draft.content,
                                                   attachmentViewModel,
                                                   mailCoverState: mailCoverState,
                                                   calendarEvent: draft.calendarEvent,
                                                   isContainsErrorImg: isContainsErrorImg,
                                                   isContainsUploadingImg: isContainsUploadingImg,
                                                   canSendExternal: canSendExternal)
    }

    // 包含保存自动回复模板和普通草稿
    func didProcessDraft() {
        guard let draft = draft else {
            mailAssertionFailure("must have draft");
            self.holdVC = nil
            return
        }
        if baseInfo.statInfo.from == .outOfOffice {
            oooDelegate?.saveAutoReplyLetter(content: draft.content)
            dismiss(animated: true, completion: nil)
            guard let reachability = reachability else {
                self.holdVC = nil
                return
            }
            if reachability.connection != .none, (self.needOOOSaveToast || self.draftSaveChecker.htmlContentDidChange) {
                let bodyLengthParam = MailAPMEvent.SendDraft.EndParam.mail_body_length(draft.content.bodyHtml.count)
                apmHolder[MailAPMEvent.SaveDraft.self]?.endParams.append(bodyLengthParam)
                apmSaveDraftEnd(status: .status_success)
                MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_OOO_Saved, on: self.view)
            }
        } else {
            if checkSaveDraftEnable(draft: draft) {
                dataManager.updateDraftAndGetThreadID(draft: draft, isdelay: false, feedCardId: self.feedCardId).subscribe(onNext: { [weak self] (resultThreadID) in
                    guard let `self` = self else { return }
                    MailSendController.logger.info("updateDraft complete \(self.feedCardId)")
                    let bodyLengthParam = MailAPMEvent.SaveDraft.EndParam.mail_body_length(draft.content.bodyHtml.count)
                    self.apmHolder[MailAPMEvent.SaveDraft.self]?.endParams.append(bodyLengthParam)
                    self.apmSaveDraftEnd(status: .status_success)
                    if self.baseInfo.threadID == nil {
                        self.baseInfo.threadID = resultThreadID
                    }
                    self.draftSaveChecker.htmlContentDidChange = false
                    self.draftSaveChecker.htmlContentChangeCount = 0
                    self.draftSaveChecker.initDraft = self.draft
                    asyncRunInMainThread {
                        if !draft.replyToMailID.isEmpty {
                            NotificationCenter.default.post(name: Notification.Name.Mail.MAIL_MESSAGE_DRAFT_REFRESHED, object: draft)
                        }
                        if self.needsSaveDraftToast {
                            let toastFromView: UIView = self.presentingViewController?.view ?? self.view
                            // 如果有倒计时蒙层，先去除
                            if let toastContainer = (toastFromView.subviews.last(where: { $0 is mailToastLayerView }) as? mailToastLayerView) {
                                toastContainer.removeFromSuperview()
                                MailUndoTaskManager.default.reset()
                            }
                            UDToast.showSuccess(with: BundleI18n.MailSDK.Mail_Toast_DraftSaved, on: toastFromView.window ?? self.view)
                            self.needsSaveDraftToast = false
                        }
                        self.holdVC = nil
                    }
                }, onError: { [weak self] (err) in
                    guard let `self` = self else { return }
                    mailAssertionFailure("fail to update draft \(err)")
                    let bodyLengthParam = MailAPMEvent.SaveDraft.EndParam.mail_body_length(draft.content.bodyHtml.count)
                    self.apmHolder[MailAPMEvent.SaveDraft.self]?.endParams.append(bodyLengthParam)
                    self.apmSaveDraftEnd(status: .status_rust_fail, error: err)
                    if self.needsSaveDraftToast {
                        MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Toast_DraftSavingError, on: self.view)
                        self.needsSaveDraftToast = false
                    }
                    self.holdVC = nil
                }).disposed(by: self.disposeBag)
            } else {
                apmHolder[MailAPMEvent.SaveDraft.self]?.abandon()
                self.holdVC = nil
            }
        }
    }

    func didUpdateSelection(_ newPosition: EditorSelectionPosition) {
        selectionPosition = newPosition
    }

    func didUpdateEditorHeight(_ newHeight: CGFloat) {
        scrollContainer.webContentSize = CGSize(width: view.bounds.width, height: newHeight)
    }

    func didUpdateEditorContent() {
        draftSaveChecker.htmlContentDidChange = true
        draftSaveChecker.htmlContentChangeCount += 1
        if accountContext.featureManager.open(.autoSaveDraft),
           baseInfo.statInfo.from != .outOfOffice,
           draftSaveChecker.htmlContentChangeCount >= draftSaveChecker.autoSaveDraftThreshold {
            htmlContentChangeRelay.accept(())
        }
    }
}

// MARK: - 编辑器相关
extension MailSendController: MailSendEditorMentionDelegate,
                                MentionModifyNameVCDelegate {
    func adjustMentionPostsition(top: CGFloat) {
        originContentOffset = scrollContainer.contentOffset
        let y = scrollContainer.webView.frame.minY
        scrollContainer.setContentOffset(CGPoint(x: 0, y: y + top), animated: true)
    }

    func didMention(keyword: String) {
        searchMentionResult(text: keyword, isWebViewMention: true)
    }

    func removeContact(address: String) {
        if let currentNumber = self.viewModel.tempAtContacts[address] {
            self.viewModel.tempAtContacts.merge(other: [address: max(0, currentNumber - 1)])
            if currentNumber - 1 == 0 {
                var targetIndex = -1
                for (idx, cc) in self.viewModel.sendToArray.enumerated() where cc.address == address {
                    targetIndex = idx
                }
                //let notAdd = self.mentionFg() && !self.mentionAddAddressBtn.isSelected
                if targetIndex != -1 {
                    self.viewModel.sendToArray.remove(at: targetIndex)
                    self.scrollContainer.toInputView.removeTokenAtIndex(index: targetIndex)
                }
            }
        }
    }

    func deactiveContactlist() {
        shawdowHeaderView.isHidden = true
        if !suggestTableView.isHidden {
            suggestTableView.isHidden = true
            searchContactAbortFinish(resultCount: viewModel.filteredArray.count)
        }
        mentionBag = nil
        if let offset = originContentOffset {
            UIView.animate(withDuration: timeIntvl.short) {
                self.scrollContainer.contentOffset = offset
            }
            originContentOffset = nil
        }
        self.updateKeyboardBinding()
    }

    func didClickContact(name: String,
                         emailAddress: String,
                         userId: String,
                         key: String,
                         rect: CGRect) {
        if MailAddressChangeManager.shared.addressNameOpen() &&
            !Store.settingData.mailClient {
            // 显示菜单
            let event = NewCoreEvent(event: .email_at_edit_menu_view)
            event.params = ["mail_account_type": NewCoreEvent.accountType()]
            event.post()
            if rootSizeClassIsSystemRegular {
                // ipad
                let scrollHeight: CGFloat = self.scrollContainer.contentOffset.y
                let webviewOffsetY: CGFloat = self.scrollContainer.webView.frame.origin.y
                let offsetY = rect.minY + webviewOffsetY - scrollHeight
                let sourceRect = CGRect(x: rect.minX, y: offsetY,
                                        width: rect.width, height: rect.height)
                self.popoverOriginY = rect.minY
                self.showMentionPopover(name: name,
                                        address: emailAddress,
                                        userId: userId,
                                        key: key,
                                        sourceRect: sourceRect)
            } else {
                self.refocusKey = key
                requestHideKeyBoard()
                self.showMentionActionSheet(name: name,
                                            address: emailAddress,
                                            userId: userId,
                                            key: key)
            }
        } else {
            self.mentionToProfile(name: name,
                                  address: emailAddress,
                                  userId: key)
        }
        
    }
    
    private func showMentionPopover(name: String,
                                    address: String,
                                    userId: String,
                                    key: String,
                                    sourceRect: CGRect) {
        var popArray: [PopupMenuActionItem] = []
        let titleItem = PopupMenuActionItem(title:"@" + "\(name)", icon: UIImage()) { [weak self] (_, _) in
            // nothing
        }
        titleItem.placeHolderTitle = true
        popArray.append(titleItem)
        let profileItem = PopupMenuActionItem(title:BundleI18n.MailSDK.Mail_ComposeMessageMentionsViewContactCard_Button, icon: UIImage()) { [weak self] (_, _) in
            // 查看个人名片
            let event = NewCoreEvent(event: .email_at_edit_menu_view)
            event.params = ["target": "none",
                            "click": "open_profile",
                            "mail_account_type": NewCoreEvent.accountType()]
            event.post()
            self?.mentionToProfile(name: name, address: address, userId: userId)
        }
        popArray.append(profileItem)
        let modifyItem = PopupMenuActionItem(title:BundleI18n.MailSDK.Mail_ComposeMessageMentionsEditTextToDisplay_Text, icon: UIImage()) { [weak self] (_, _) in
            guard let `self` = self else { return }
            let vc = MailEditMentionNameController(accountContext: self.accountContext,
                                                   mentionDelegate: self,
                                                   key: key,
                                                   name: name)
            self.navigator?.present(vc, from: self)
        }
        popArray.append(modifyItem)
        let vc = PopupMenuPoverViewController(items: popArray)
        vc.hideIconImage = true
        vc.modalPresentationStyle = .popover
        vc.popoverPresentationController?.backgroundColor = UIColor.ud.bgBody
        vc.popoverPresentationController?.sourceView = self.view
        vc.popoverPresentationController?.sourceRect = sourceRect
        
        let spaceLimit: CGFloat = 160
        if sourceRect.maxY + spaceLimit > self.view.bounds.size.height {
            vc.popoverPresentationController?.permittedArrowDirections = .down
        } else {
            vc.popoverPresentationController?.permittedArrowDirections = .up
        }
        
        navigator?.present(vc, from: self)
    }
    
    private func showMentionActionSheet(name: String,
                                        address: String,
                                        userId: String,
                                        key: String) {
        guard let sourceView = self.view else { return }
        let source = UDActionSheetSource(sourceView: sourceView,
                                         sourceRect: sourceView.bounds,
                                         arrowDirection: .up)
        let pop = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: true, popSource: source))
        pop.setTitle("@" + "\(name)")
        pop.addDefaultItem(text: BundleI18n.MailSDK.Mail_ComposeMessageMentionsViewContactCard_Button) { [weak self] in
            // 查看个人名片
            let event = NewCoreEvent(event: .email_at_edit_menu_view)
            event.params = ["target": "none",
                            "click": "open_profile",
                            "mail_account_type": NewCoreEvent.accountType()]
            event.post()
            self?.mentionToProfile(name: name, address: address, userId: userId)
        }
        pop.addDefaultItem(text: BundleI18n.MailSDK.Mail_ComposeMessageMentionsEdit_Button) { [weak self] in
            guard let `self` = self else { return }
            let vc = MailEditMentionNameController(accountContext: self.accountContext,
                                                   mentionDelegate: self,
                                                   key: key,
                                                   name: name)
            self.navigator?.present(vc, from: self)
        }
        pop.setCancelItem(text: BundleI18n.MailSDK.Mail_Alert_Cancel)
        navigator?.present(pop, from: self)
    }
    private func mentionToProfile(name: String, address: String, userId: String) {
        guard let emailAddress = address.components(separatedBy: "?").first else { return }
        if address.isEmpty && !userId.isEmpty {
            self.accountContext.profileRouter.openUserProfile(userId: userId, fromVC: self)
            return
        }
        MailRoundedHUD.showLoading(with: BundleI18n.MailSDK.Mail_Normal_Loading, on: self.view, disableUserInteraction: false)
        dataProvider
            .addressInfoSearch(address: emailAddress).subscribe(onNext: { [weak self] (item) in
            guard let `self` = self else { return }
            let accountId = Store.settingData.currentAccount.value?.mailAccountID ?? ""
            if let item = item {
                MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_Normal_Success, on: self.view)
                let tenantId = item.tenantID
                if !item.larkID.isEmpty && tenantId == "0" {
                    MailContactLogic.default.checkTenantId(userId: item.larkID ?? "") { [weak self] tenantId in
                        guard let self = self else { return }
                        if let id = tenantId {
                            if id.isEmpty || id != self.accountContext.user.tenantID {
                                self.accountContext.profileRouter.openNameCard(accountId: accountId, address: item.address, name: name, fromVC: self)
                            } else {
                                self.accountContext.profileRouter.openUserProfile(userId: item.larkID ?? "", fromVC: self)
                            }
                        }
                    }
                } else {
                    if tenantId.isEmpty || tenantId != self.accountContext.user.tenantID {
                        self.accountContext.profileRouter.openNameCard(accountId: accountId, address: item.address, name: name, fromVC: self)
                    } else {
                        self.accountContext.profileRouter.openUserProfile(userId: item.larkID ?? "", fromVC: self)
                    }
                }
            } else {
                self.accountContext.profileRouter.openNameCard(accountId: accountId,
                                                               address: emailAddress,
                                                               name: name,
                                                               fromVC: self)
            }
        },
        onError: { [weak self] (_) in
            guard let `self` = self else { return }
            MailRoundedHUD.remove(on: self.view)
        },
        onCompleted: { [weak self] in
            guard let `self` = self else { return }
            MailRoundedHUD.remove(on: self.view)
        }).disposed(by: disposeBag)
    }
    
    func cancelModify(key: String) {
        _ = self.scrollContainer.webView.becomeFirstResponder()
        let jsStr = "window.command.focusAfterAtUserBlock(`\(key)`)"
        self.evaluateJavaScript(jsStr)
    }
    
    func modifyName(key: String, name: String) {
        self.requestEvaluateJavaScript("window.command.editAtUser(`\(key)`,`\(name)`)") { [weak self] (_, err) in
            guard let `self` = self else { return }
            if let err = err {
                MailLogger.error("mentionModifyName err \(err)")
            } else {
                DispatchQueue.main.async {
                    _ = self.scrollContainer.webView.becomeFirstResponder()
                    let jsStr = "window.command.focusAfterAtUserBlock(`\(key)`)"
                    self.evaluateJavaScript(jsStr)
                }
            }
        }
    }

    func searchMentionResult(text: String, isWebViewMention: Bool = false) {
        self.isWebViewMention = isWebViewMention
        if text.isEmpty {
            self.editionInputView = nil
            viewModel.filteredArray = []
            return
        }
        var remoteDone = false
        self.dataProvider.searchBegin = 0
        self.dataProvider.searchKey = text
        let bag = DisposeBag()
        mentionBag = bag
        _ = self.dataProvider.atRecommandListWith(key: text).observeOn(MainScheduler.instance).subscribe(
            onNext: { [weak self] (list, isRemote) in
                guard let `self` = self else { return }
                guard !remoteDone || isRemote else { return }
                remoteDone = isRemote
                self.viewModel.filteredArray = list.compactMap({ (model) -> MailAddressCellViewModel? in
                    guard !model.address.isEmpty || (model.larkID != nil && !model.larkID!.isEmpty && model.larkID! != "0") else {
                        return nil
                    }
                    let viewModel = MailAddressCellViewModel.make(from: model, currentTenantID: self.accountContext.user.tenantID)
                    return viewModel
                })
                if self.viewModel.filteredArray.isEmpty || !remoteDone {
                    self.editionInputView = nil
                }
            },
            onCompleted: { [weak self] in
                guard let `self` = self else { return }
                if self.viewModel.filteredArray.isEmpty || !remoteDone {
                    self.editionInputView = nil
                }
                self.suggestTableView.separatorStyle = .none
                if self.mentionFg() {
                    if self.viewModel.filteredArray.isEmpty {
                        self.mentionLabel.text = BundleI18n.MailSDK.Mail_Compose_NoResults
                        self.mentionLabel.textColor = UIColor.ud.textPlaceholder
                        self.mentionAddAddressBtn.isHidden = true
                        self.mentionLabel.frame = CGRect(x: 16, y: 0, width: 300, height: mentionHeaderHeight)
                    } else {
                        self.mentionAddAddressBtn.isHidden = false
                        self.mentionLabel.text = BundleI18n.MailSDK.Mail_Edit_AddToRecipient
                        self.mentionLabel.frame = CGRect(x: 48, y: 0, width: 300, height: mentionHeaderHeight)
                    }
                } else {
                    if self.viewModel.filteredArray.isEmpty {
                        self.mentionLabel.text = BundleI18n.MailSDK.Mail_Compose_NoResults
                        self.mentionLabel.textColor = UIColor.ud.textPlaceholder
                    } else {
                        self.mentionLabel.text = BundleI18n.MailSDK.Mail_Compose_Mentions_Title
                    }
                }
                if let mainToolBar = self.mainToolBar {
                    let wasHidden = self.suggestTableView.isHidden
                    self.suggestTableView.isHidden = false
                    var newFrame = self.suggestTableView.frame
                    var tableViewHeight = mentionHeaderHeight
                    if !self.viewModel.filteredArray.isEmpty {
                        tableViewHeight += MailAddressCellConfig.height * CGFloat(self.viewModel.filteredArray.count)
                    }
                    let topPadding: CGFloat = 54
                    let height: CGFloat = max(min(mainToolBar.frame.minY - topPadding, tableViewHeight), 0)
                    let targetY = max(mainToolBar.frame.minY - height, 0)
                    newFrame.origin.y = wasHidden ? mainToolBar.frame.minY : targetY
                    newFrame.size.height = height
                    self.suggestTableView.frame = newFrame
                    // at 人出现的 tableView 有圆角和阴影
                    let cornerRadius: CGFloat = 12
                    self.suggestTableView.layer.cornerRadius = cornerRadius
                    self.suggestTableView.layer.maskedCorners = CACornerMask(rawValue: CACornerMask.layerMinXMinYCorner.rawValue | CACornerMask.layerMaxXMinYCorner.rawValue)
                    self.shawdowHeaderView.isHidden = false
                    self.shawdowHeaderView.frame = newFrame
                    // 下面这段没搞懂在干嘛
                    if wasHidden {
                        UIView.animate(withDuration: timeIntvl.short) {
                            var tempFrame = self.suggestTableView.frame
                            tempFrame.origin.y = targetY
                            self.suggestTableView.frame = tempFrame
                            var tempFrame2 = self.shawdowHeaderView.frame
                            tempFrame2.origin.y = targetY - 1
                            self.shawdowHeaderView.frame = tempFrame2
                        }
                    }
                } else {
                    self.deactiveContactlist()
                }
                self.suggestTableView.reloadData()
                self.suggestTableSelectionRow = 0
                self.updateKeyboardBinding()
            }).disposed(by: bag)

    }
}

extension MailSendController: MailSendSignatureListVCDelegate {
    func genSignatureScene() -> String {
        var scene = "new_mail"
        if action == .forward {
            scene = "forward"
        } else if action == .reply || action == .replyAll {
            scene = "reply"
        }
        return scene
    }
    func genSignatureType(sigId: String) -> String? {
        if sigId.isEmpty {
            return "none"
        }
        if let sigData = Store.settingData.getCachedCurrentSigData() {
            if let force = sigData.optionalSignatureMap["current_account"]?.isForceApply, force == true {
                return "assign"
            }
            if let sig = sigData.signatures.first { $0.id == sigId } {
                if sig.signatureType == .user {
                    return "custom"
                }
                return "template"
            }
        }
        return nil
    }
    func didSelectSig(sigId: String) {
        self.scrollContainer.webView.sigId = sigId
        self.pluginRender?.setSignature(sigId: sigId)
        let event = NewCoreEvent(event: .email_email_edit_click)
        var param = ["target": "none",
                    "click": "change_signature",
                    "scene": genSignatureScene()]
        if let type = genSignatureType(sigId: sigId) {
            param["signature_type"] = type
        }
        event.params = param
        event.post()
    }
    func updateSigId(sigId: String) {
        self.scrollContainer.webView.sigId = sigId
    }

    func getSignatureListByAddress(sigData: SigListData) -> ([MailSignature], String, Bool) {
        return self.scrollContainer.webView.getSignatureListByAddress(sigData: sigData,
                                                               draft: draft,
                                                                      action: action,
                                                                      address: scrollContainer.currentAddressEntity)
    }
    
    func genSignatureDicByAddres(sigData: SigListData,
                                 address: Email_Client_V1_Address?) -> [String: Any]? {
        return self.scrollContainer.webView.genSignatureDicByAddres(sigData: sigData,
                                                                    draft: draft,
                                                                    action: action,
                                                                    address: address)
    }
    func selectSignature(forceApply: Bool) {
        var bottomMargin: CGFloat? = nil
        if let toolbar = self.mainToolBar, !toolbar.isHidden, toolbar.frame.minY > 0 {
            let dy = UIScreen.main.bounds.height - view.bounds.size.height
            let marginOffset: CGFloat = 23 // 可能是一个调试值
            let caculateMargin = (UIScreen.main.bounds.size.height - toolbar.frame.minY) - dy - marginOffset
            if caculateMargin > 0 && caculateMargin < UIScreen.main.bounds.size.height {
                bottomMargin = caculateMargin
            }
        }
        let text = forceApply ? BundleI18n.MailSDK.Email_MandatoryOrganizationSignatureCannotEditDelete_hover:
        BundleI18n.MailSDK.Email_OrganizationSignatureCannotEdit_hover
        ActionToast.showWarningToast(with: text, on: self.view, bottomMargin: bottomMargin)
    }
    
    
}
