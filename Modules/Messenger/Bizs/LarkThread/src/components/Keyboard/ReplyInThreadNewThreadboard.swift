//
//  ReplyInThreadNewThreadKey.swift
//  LarkThread
//
//  Created by ByteDance on 2022/4/27.
//

import Foundation
import UIKit
import LarkCore
import LarkRichTextCore
import EditTextView
import LarkKeyboardView
import RustPB
import LarkModel
import ByteWebImage
import LarkAlertController
import LarkAttachmentUploader
import LarkMessengerInterface
import UniverseDesignToast
import LarkSDKInterface
import LarkMessageCore
import LarkMessageBase
import RxCocoa
import RxSwift
import LarkFeatureGating
import UniverseDesignDialog
import EENavigator
import UniverseDesignDatePicker
import UniverseDesignActionPanel
import LarkBaseKeyboard
import LarkChatOpenKeyboard

final class ReplyInThreadNewThreadboard: ThreadKeyboard {

    var currentViewModel: NewThreadKeyboardViewModel? {
        return viewModel as? NewThreadKeyboardViewModel
    }
    var draft: String? {
        guard let postDraft = self.postDraft else { return nil }
        if postDraft.title.isEmpty && postDraft.content.isEmpty {
            return ""
        }
        return postDraft.stringify()
    }

    private var scheduleTime: Int64? {
        if let time = self.scheduleDate?.timeIntervalSince1970 {
            return Int64(time)
        }
        return nil
    }
    private var scheduleDate: Date?
    private var scheduleInitDate: Date?

    var postDraft: PostDraftModel? {
        get {
            guard let delegate = keyboardView.keyboardStatusManager.delegate else { return nil }
            var postDraft: PostDraftModel = PostDraftModel()
            let attrText = delegate.getKeyboardAttributedText()
            if !attrText.string.isEmpty,
               let richText = RichTextTransformKit.transformStringToRichText(string: attrText) {
                postDraft.content = (try? richText.jsonString()) ?? ""
            } else {
                return postDraft
            }
            if let attachmentManager = currentViewModel?.attachmentManager,
            let data = attachmentManager.attachmentUploader.draft.atchiverData(),
                let draftStr = String(data: data, encoding: .utf8) {
                postDraft.uploaderDraft = draftStr
            }
            postDraft.lingoElements = LingoConvertService.transformStringToDraftModel(attrText)
            postDraft.userInfoDic = AtTransformer.getAllChatterActualNameMapForAttributedString(attrText)
            return postDraft
        }
        set {
            guard let postDraft = newValue else { return }
            if let draftData = postDraft.uploaderDraft.data(using: .utf8),
                let uploaderDraft = AttachmentUploader.Draft(draftData) {
                currentViewModel?.attachmentManager?.attachmentUploader.draft = uploaderDraft
            }

            if let richText = try? RustPB.Basic_V1_RichText(jsonString: postDraft.content) {
                let attachmentResult: [String: String] = currentViewModel?.attachmentManager?.attachmentUploader.results ?? [:]
                let content = RichTextTransformKit.transformRichTextToStr(
                    richText: richText,
                    attributes: keyboardView.inputTextView.baseDefaultTypingAttributes,
                    attachmentResult: attachmentResult,
                    processProvider: postDraft.processProvider)
                AtTransformer.getAllChatterInfoForAttributedString(content).forEach { chatterInfo in
                    chatterInfo.actualName = postDraft.userInfoDic[chatterInfo.id] ?? ""
                }
                fontPanelSubModule?.onTextViewLengthChange(content.length)
                let contentStr = LingoConvertService.transformModelToString(elements: postDraft.lingoElements, text: content)
                keyboardView.inputTextView.replace(contentStr, useDefaultAttributes: false)
            } else if !postDraft.content.isEmpty {
                // 处理旧版本草稿格式
                let draft = NSAttributedString(string: postDraft.content, attributes: keyboardView.inputTextView.defaultTypingAttributes)
                let content = OldVersionTransformer.transformInputText(draft)
                fontPanelSubModule?.onTextViewLengthChange(content.length)
                keyboardView.inputTextView.replace(content, useDefaultAttributes: false)
            }
            setupAttachment()
            Self.logger.info("ChatInputKeyboard setPostDraft",
                             additionalData: ["chatId": self.viewModel.chatWrapper.chat.value.id,
                                                                  "messageId": self.viewModel.replyMessage?.id ?? "",
                                                                  "DraftLength": "\(self.keyboardView.inputTextView.text.count)"])
        }
    }

    override init(
        viewModel: ThreadKeyboardViewModel,
        delegate: ThreadKeyboardDelegate?,
        draftCache: DraftCache,
        keyBoardView: ThreadKeyboardView,
        sendImageProcessor: SendImageProcessor,
        keyboardConfig: ThreadKeyboardConfig) {
            super.init(viewModel: viewModel,
                       delegate: delegate,
                       draftCache: draftCache,
                       keyBoardView: keyBoardView,
                       sendImageProcessor: sendImageProcessor,
                       keyboardConfig: keyboardConfig)
            keyboardView.messengerKeyboardPanel?.rightContainerViewDelegate = self
        }

    override func addObservers() {
        /// 更新AttachmentManager时候更新callack
        currentViewModel?.updateAttachmentManagerCallBack = { [weak self] in
            self?.updateAttachmentUploaderDefaultCallBack()
        }
        super.addObservers()
        /// TODO: 李洛斌 MVP后续可以找产品对其暂停使用和屏蔽状态
        self.viewModel.chatWrapper.chat
            .distinctUntilChanged({ $0.isAllowPost == $1.isAllowPost })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.updateKeyboardState()
            }).disposed(by: self.disposeBag)
    }

    override func textViewInputHanders() -> [TextViewInputProtocol] {
        var handlers = super.textViewInputHanders()
        let styleHander = FontStyleInputHander { [weak self] in
            self?.fontPanelSubModule?.onChangeSelectionFromPaste()
        }
        handlers.insert(styleHander, at: 0)
        return handlers
    }

    override func updateKeyboardStatusIfNeed(_ item: ComposePostItem?) {
        (self.keyboardView as? NewThreadKeyboardView)?.updateKeyboardStatusIfNeed(item)
        updateAttachmentUploaderDefaultCallBack()
    }

    /// 草稿设置后的恢复
    override func setupAttachment(needToClearTranslationData: Bool = false) {
        guard let attachmentManager = currentViewModel?.attachmentManager  else {
            assertionFailure("attachmentManager is nil")
            return
        }
        attachmentManager.applyAttachmentDraftForTextView(keyboardView.inputTextView,
                                                          async: true,
                                                          imageMaxHeight: keyboardView.textFieldMaxHeight - 5,
                                                          imageMinWidth: 80,
                                                          finishBlock: { [weak self] in
            guard let self = self else { return }
            self.currentViewModel?.attachmentManager?.attachmentUploader.startUpload()
            self.currentViewModel?.attachmentManager?.updateImageAttachmentState(self.keyboardView.inputTextView)
        }, didUpdateAttrText: nil)
        keyboardView.keyboardPanel.reloadPanel()
    }

    func updateAttachmentUploaderDefaultCallBack() {
        guard let attachmentManager = currentViewModel?.attachmentManager else {
            return
        }
        attachmentManager.defaultCallBack = {  [weak self] (_, _, url, data, error) in
            guard let `self` = self else { return }
            self.updateAttachmentStateWith(url: url, data: data)
            if let apiError = error?.underlyingError as? APIError, let vc = self.delegate?.baseViewController() {
                switch apiError.type {
                case .cloudDiskFull:
                    let alertController = LarkAlertController()
                    alertController.showCloudDiskFullAlert(from: vc, nav: self.viewModel.navigator)
                case .securityControlDeny(let message):

                    self.currentViewModel?.chatSecurityControlService?.authorityErrorHandler(event: .sendImage,
                                                                                            authResult: nil,
                                                                                            from: vc,
                                                                                            errorMessage: message)
                default: break
                }
                self.showDefaultError(error: apiError)
                return
            }
            if let error = error {
                self.showDefaultError(error: error)
            }
        }
    }

    func showDefaultError(error: Error) {
        guard let window = self.delegate?.baseViewController().view.window else {
            return
        }
        UDToast.showFailure(
            with: BundleI18n.LarkThread.Lark_Legacy_ErrorMessageTip, on: window, error: error
        )
    }

    func updateAttachmentStateWith(url: String?, data: Data?) {
        guard let attachmentManager = currentViewModel?.attachmentManager, let resourceAPI = self.viewModel.resourceAPI else {
            return
        }
        attachmentManager.updateAttachmentResultInfo(self.keyboardView.attributedString)
        attachmentManager.updateImageAttachmentState(self.keyboardView.inputTextView)
        if let imageData = data,
           let key = url,
           let image = try? ByteImage(imageData) {
            let originKey = resourceAPI.computeResourceKey(key: key, isOrigin: true)
            attachmentManager.storeImageToCacheFromDraft(image: image, imageData: imageData, originKey: originKey)
        }
    }

    /// 回复草稿
    override func updateDraftContent(by draftStr: String) {
        if draftStr.isEmpty {
            keyboardView.attributedString = NSAttributedString(string: "",
                                                               attributes: keyboardView.inputTextView.defaultTypingAttributes)
            return
        }
        self.postDraft = PostDraftModel.parse(draftStr)
        updateAttachmentInfo()
    }

    func updateAttachmentInfo() {
        currentViewModel?.attachmentManager?.updateAttachmentResultInfo(keyboardView.inputTextView.attributedText)
        currentViewModel?.attachmentManager?.updateImageAttachmentState(keyboardView.inputTextView)
    }

    override func saveDraftOnTextDidChange() {
        if let editMessage = keyboardView.keyboardStatusManager.getMultiEditMessage() {
            saveInputViewDraft(id: .multiEditMessage(messageId: editMessage.id, chatId: viewModel.chat.id))
        } else if let replyMessageId = viewModel.replyMessage?.id {
            saveInputViewDraft(id: .replyMessage(messageId: replyMessageId))
        }
    }

    /// 保存草稿
    func saveInputViewDraft(id: DraftId, callback: DraftCallback? = nil) {
        guard let vm = currentViewModel,
              let attrText = keyboardView.keyboardStatusManager.delegate?.getKeyboardAttributedText(),
              let draft = self.draft else {
            return
        }
        vm.savePostDraftWithMessageId(id,
                                      draft: draft,
                                      attachmentKeys: vm.attachmentManager?.attachmentIdsForAttruibuteStr(attrText) ?? [],
                                      async: true,
                                      callback: callback)
    }

    override func onComposePostViewCompleteWith(_ richText: RichTextContent, replyMessage: Message?, scheduleTime: Int64?) {
        var richTextContent = richText
        richTextContent.richText.richTextVersion = 1
        if richText.richText.imageIds.isEmpty,
           richText.richText.mediaIds.isEmpty,
           richText.title.isEmpty,
           !CodeInputHandler.richTextContainsCode(richText: richText.richText) {
            /// RichTextContent的 richText.processProvider这里没有了呢
            let transmitToChat = keyboardView.keyboardShareDataService.forwardToChatSerivce.forwardToChat
            keyboardView.keyboardShareDataService.forwardToChatSerivce.messageWillSend(chat: viewModel.chat)
            self.viewModel.delegate?.defaultInputSendTextMessage(richText.richText,
                                                                 lingoInfo: richText.lingoInfo,
                                                                 parentMessage: replyMessage,
                                                                 scheduleTime: scheduleTime,
                                                                 transmitToChat: transmitToChat,
                                                                 isFullScreen: true)
        } else {
            super.onComposePostViewCompleteWith(richTextContent,
                                                replyMessage: replyMessage,
                                                scheduleTime: scheduleTime)
        }
    }
    /// 发送消息
    override func inputTextViewSend(attributedText: NSAttributedString, scheduleTime: Int64?) {
        guard let attachmentManager = currentViewModel?.attachmentManager,
              !attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        if attachmentManager.checkAttachmentAllUploadSuccessFor(attruibuteStr: attributedText) {
            sendMessageWith(contentAttributedText: attributedText, scheduleTime: scheduleTime)
            return
        }
        if let view = self.delegate?.baseViewController().view {
            let hud = UDToast.showLoading(with: BundleI18n.LarkThread.Lark_Legacy_ComposePostUploadPhoto, on: view, disableUserInteraction: true)
            attachmentManager.retryUploadAttachment(textView: keyboardView.inputTextView,
                                                       start: nil) { [weak self] successs in
                if !successs {
                    if let window = self?.delegate?.baseViewController().view.window {
                        hud.showFailure(with: BundleI18n.LarkThread.Lark_Legacy_LoadFailRetry, on: window)
                    }
                } else {
                    hud.remove()
                    self?.sendMessageWith(contentAttributedText: attributedText, scheduleTime: scheduleTime)
                }
            }
        }
    }

    public func updateTip(_ tip: KeyboardTipsType) {
        viewModel.keyboardStatusManagerBlock?()?.addTip(tip)
    }

    fileprivate func sendMessageWith(contentAttributedText: NSAttributedString,
                                     scheduleTime: Int64? = nil) {
        let title = ""
        var contentAttr = contentAttributedText
        let canSendText = canSendTextMessageForAttr(contentAttr, title: title)
        contentAttr = RichTextTransformKit.preproccessSendAttributedStr(contentAttr)
        onInputFinished()
        let transmitToChat = keyboardView.keyboardShareDataService.forwardToChatSerivce.forwardToChat
        keyboardView.keyboardShareDataService.forwardToChatSerivce.messageWillSend(chat: viewModel.chat)
        if var richText = RichTextTransformKit.transformStringToRichText(string: contentAttr) {
            richText.richTextVersion = 1
            let lingoInfo = LingoConvertService.transformStringToQuasiContent(contentAttr)
            if canSendText {
                viewModel.delegate?.defaultInputSendTextMessage(richText,
                                                                lingoInfo: lingoInfo,
                                                                parentMessage: viewModel.replyMessage,
                                                                scheduleTime: scheduleTime,
                                                                transmitToChat: transmitToChat,
                                                                isFullScreen: false)
            } else {
                viewModel.delegate?.defaultInputSendPost(content: RichTextContent(title: title, richText: richText, lingoInfo: lingoInfo),
                                                         parentMessage: viewModel.replyMessage,
                                                         scheduleTime: scheduleTime,
                                                         transmitToChat: transmitToChat,
                                                         isFullScreen: false)
            }
        }
        if let editMessage = self.keyboardView.keyboardStatusManager.getMultiEditMessage() {
            viewModel.delegate?.cleanPostDraftWith(key: editMessage.editDraftId,
                                                   id: .multiEditMessage(messageId: editMessage.id, chatId: viewModel.chat.id))
        } else if let replyMessage = self.viewModel.replyMessage {
            viewModel.delegate?.cleanPostDraftWith(key: replyMessage.postDraftId,
                                                   id: .replyInThread(messageId: replyMessage.id))
        }
        audioKeyboardHelper?.trackAudioRecognizeIfNeeded()
    }

    private func canSendTextMessageForAttr(_ attr: NSAttributedString, title: String) -> Bool {
        // 如果里面包含代码块，则转为发送富文本消息
        if CodeInputHandler.attributedTextContainsCode(attributedText: attr) {
            return false
        }
        /// 没有标题/视频/图片
        if let attachmentManager = currentViewModel?.attachmentManager, attachmentManager.attachmentIdsForAttruibuteStr(attr).isEmpty,
           title.isEmpty {
            return true
        }
        return false
    }
    override func setupTextMessage(message: Message,
                                   isInsert: Bool = true,
                                   callback: (() -> Void)? = nil) {
        super.setupTextMessage(message: message, isInsert: isInsert, callback: callback)
        fontPanelSubModule?.updateInputTextViewStyle()
    }

    override func setupPostMessage(message: Message,
                                   isInsert: Bool = true,
                                   callback: (() -> Void)? = nil,
                                   beforeApplyCallBack: ((NSAttributedString) -> NSAttributedString)? = nil) {
        guard let content = message.content as? PostContent else {
            return
        }
        let richText = TextDocsViewModel(userResolver: userResolver, richText: content.richText, docEntity: content.docEntity, hangPoint: message.urlPreviewHangPointMap).richText
        let attributes = self.keyboardView.inputTextView.defaultTypingAttributes
        let processProvider = MessageInlineViewModel.urlInlineProcessProvider(message: message, attributes: attributes)
        let contentText = RichTextTransformKit.transformRichTextToStr(
            richText: richText,
            attributes: keyboardView.inputTextView.baseDefaultTypingAttributes,
            attachmentResult: [:],
            processProvider: processProvider)
        updateAttributedStringAtInfo(contentText) { [weak self] in
            let applyAttr = beforeApplyCallBack?(contentText) ?? contentText
            if isInsert {
                self?.keyboardView.inputTextView.insert(applyAttr, useDefaultAttributes: false)
            } else {
                self?.keyboardView.inputTextView.replace(applyAttr, useDefaultAttributes: false)
            }
            self?.fontPanelSubModule?.updateInputTextViewStyle()
            callback?()
        }
    }
    override func updateAttachmentSizeFor(attributedText: NSAttributedString) {
        currentViewModel?.attachmentManager?.updateAttachmentSizeWithMaxHeight(keyboardView.textFieldMaxHeight - 5,
                                                                               imageMinWidth: 80,
                                                                               attributedText: attributedText,
                                                                               textView: keyboardView.inputTextView)
    }

    override func supportFontStyle() -> Bool {
        return !viewModel.chat.isCrypto
    }

    override var normalPlaceHolder: String {
        return BundleI18n.LarkThread.Lark_IM_Thread_ReplyToThread_Placeholder
    }

    override var isAllowReply: Bool {
        let chat = self.viewModel.chatWrapper.chat.value
        if !chat.isAllowPost {
            return false
        }
        if chat.type == .p2P, let chatter = chat.chatter {
            if chatter.isResigned {
                return false
            }
        }
        return super.isAllowReply
    }

    override func updatePlaceholder() {
        let chat = self.viewModel.chatWrapper.chat.value
        if chat.isFrozen {
            keyboardView.inputPlaceHolder = BundleI18n.LarkThread.Lark_IM_CantSendMsgThisDisbandedGrp_Desc
            keyboardView.keyboardShareDataService.forwardToChatSerivce.showSyncToCheckBox = false
            return
        }
        if !chat.isAllowPost {
            let isBannedPost = chat.adminPostSetting == .bannedPost
            let inputPlaceHolder = isBannedPost ? BundleI18n.LarkThread.Lark_IM_Chatbox_UnableToSendMessagesInProhibitedGroup_Placeholder :
            BundleI18n.LarkThread.Lark_Group_GroupSettings_MsgRestriction_YouAreBanned_InputHint
            keyboardView.inputPlaceHolder = inputPlaceHolder
            return
        }
        if chat.type == .p2P, let chatter = chat.chatter {
            if chatter.isResigned {
                keyboardView.inputPlaceHolder = BundleI18n.LarkThread.Lark_Legacy_ChatterResignPermissionMask
                return
            }
        }
        super.updatePlaceholder()
    }

    override func supportAtUser() -> Bool {
        return true
    }

    override func onKeyboardJobChanged(oldJob: KeyboardJob?, currentJob: KeyboardJob) {
        super.onKeyboardJobChanged(oldJob: oldJob, currentJob: currentJob)
        self.currentViewModel?.updateAttachmentUploaderIfNeed()
    }

    public override func sendInputContentAsMessage() {
        switch keyboardView.keyboardStatusManager.currentKeyboardJob {
        case .multiEdit(let message):
            confirmMultiEditMessage(message, triggerMethod: .hotkey_action)
        default:
            super.sendInputContentAsMessage()
        }
    }

    func confirmMultiEditMessage(_ message: Message,
                                 triggerMethod: IMTracker.Chat.Main.Click.Msg.SaveEditMsgTriggerMethod) {
        IMTracker.Chat.Main.Click.Msg.saveEditMsg(self.viewModel.chat,
                                                  message,
                                                  triggerMethod: triggerMethod,
                                                  self.delegate?.chatFromWhere)
        //触发二次编辑或（内容为空时）撤回后（无论请求是否成功），都会走到这里
        func callback() {
            cleanPostDraft()
            onInputFinished()
            keyboardView.keyboardStatusManager.goBackToLastStatus()
        }

        let title = ""
        var contentAttr = keyboardView.getTrimTailSpacesAttributedString()
        if contentAttr.string.isEmpty {
            //内容为空，视为撤回
            let dialog = UDDialog()
            dialog.setTitle(text: BundleI18n.LarkThread.Lark_IM_EditMessage_ClearAllContenAndRecallMessage_Title)
            dialog.setContent(text: BundleI18n.LarkThread.Lark_IM_EditMessage_ClearAllContenAndRecallMessage_Desc)
            dialog.addSecondaryButton(text: BundleI18n.LarkThread.Lark_IM_EditMessage_ClearAllContenAndRecallMessage_Cancel_Button,
                                      dismissCompletion: { [weak self] in
                IMTracker.Msg.WithdrawConfirmCLick(self?.viewModel.chat,
                                                   message,
                                                   clickConfirm: false)
            })
            dialog.addDestructiveButton(text: BundleI18n.LarkThread.Lark_IM_EditMessage_ClearAllContenAndRecallMessage_RecallMessage_Button,
                                        dismissCompletion: { [weak self] in
                guard let self = self, let messageAPI = self.viewModel.messageAPI else { return }
                IMTracker.Msg.WithdrawConfirmCLick(self.viewModel.chat,
                                                   message,
                                                   clickConfirm: true)
                messageAPI
                    .recall(messageId: message.id)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { (_) in
                    }, onError: { [weak self] (error) in
                        guard let window = self?.delegate?.baseViewController().view.window else { return }
                        if let error = error.underlyingError as? APIError {
                            switch error.type {
                            case .messageRecallOverTime(let errorInfo):
                                UDToast.showFailure(with: errorInfo, on: window, error: error)
                                self?.currentViewModel?.multiEditService?.reloadEditEffectiveTimeConfig()
                            default:
                                UDToast.showFailure(
                                    with: BundleI18n.LarkThread.Lark_Legacy_RecallMessageErr,
                                    on: window,
                                    error: error
                                )
                            }
                        }
                    })
                    .disposed(by: self.disposeBag)
                callback()
            })

            if let vc = self.delegate?.baseViewController() {
                navigator.present(dialog, from: vc)
            }
            return
        }
        let canSendText = canSendTextMessageForAttr(contentAttr, title: title)
        contentAttr = RichTextTransformKit.preproccessSendAttributedStr(contentAttr)
        if var richText = RichTextTransformKit.transformStringToRichText(string: contentAttr),
           let messageId = Int64(message.id) {
            richText.richTextVersion = 1
            let chat = self.viewModel.chat
            if !chat.isAllowPost {
                guard let window = self.delegate?.baseViewController().view.window else { return }
                UDToast.showFailure(with: BundleI18n.LarkThread.Lark_IM_EditMessage_FailedToEditDueToSpecificSettings_Toast(chat.name), on: window)
                return
            }
            if message.isRecalled || message.isDeleted {
                let dialog = UDDialog()
                dialog.setTitle(text: BundleI18n.LarkThread.Lark_IM_EditMessage_UnableToSaveChanges_Text)
                let content = message.isRecalled ?
                BundleI18n.LarkThread.Lark_IM_EditMessage_MessageRecalledUnableToSave_Title :
                BundleI18n.LarkThread.Lark_IM_EditMessage_MessageDeletedUnableToSave_Title
                dialog.setContent(text: content)
                dialog.addPrimaryButton(text: BundleI18n.LarkThread.Lark_IM_EditMessage_UnableToSave_GotIt_Button)
                if let vc = self.delegate?.baseViewController() {
                    navigator.present(dialog, from: vc)
                }
                return
            }

            callback()

            DispatchQueue.global(qos: .userInteractive).async {
                let lingoInfo = LingoConvertService.transformStringToQuasiContent(contentAttr)
                //没有改变任何内容点保存，则不执行任何操作
                if let oldMessageContent = self.keyboardView.keyboardStatusManager.multiEditingMessageContent,
                   richText.isContentEqualTo(oldMessageContent.richText),
                   lingoInfo.isContentEqualTo(oldMessageContent.lingoInfo) {
                    return
                }

                let chatId = chat.id
                self.requestMultiEditMessage(messageId: messageId,
                                             chatId: chatId,
                                             type: canSendText ? .text : .post,
                                             richText: richText,
                                             title: title.isEmpty ? nil : title,
                                             lingoInfo: lingoInfo)
            }
        }
    }

    func requestMultiEditMessage(messageId: Int64,
                                 chatId: String,
                                 type: Basic_V1_Message.TypeEnum,
                                 richText: Basic_V1_RichText,
                                 title: String?,
                                 lingoInfo: Basic_V1_LingoOption) {
        self.currentViewModel?.multiEditService?.multiEditMessage(messageId: messageId,
                                                                  chatId: chatId,
                                                                  type: type,
                                                                  richText: richText,
                                                                  title: title,
                                                                  lingoInfo: lingoInfo)
            .observeOn(MainScheduler.instance)
            .subscribe { _ in
            } onError: { [weak self] error in
                Self.logger.info("multiEditMessage fail, error: \(error)",
                                 additionalData: ["chatId": chatId,
                                                  "messageId": "\(messageId)"])
                guard let self = self,
                      let window = self.delegate?.baseViewController().view.window,
                      let error = error.underlyingError as? APIError else {
                    return
                }
                switch error.type {
                case .editMessageNotInValidTime:
                    self.currentViewModel?.multiEditService?.reloadEditEffectiveTimeConfig()
                default:
                    break
                }
                UDToast.showFailureIfNeeded(on: window, error: error)
            }.disposed(by: self.disposeBag)
    }
}

extension ReplyInThreadNewThreadboard: MessengerKeyboardPanelRightContainerViewDelegate {
    public func onMessengerKeyboardPanelCommit() {
        guard let message = keyboardView.keyboardStatusManager.getMultiEditMessage() else {
            return
        }
        confirmMultiEditMessage(message, triggerMethod: .click_save)
    }

    public func onMessengerKeyboardPanelCancel() {
        keyboardView.goBackToLastStatus()
    }

    public func onMessengerKeyboardPanelSendTap() {
        keyboardView.sendNewMessage()
    }

    public func onMessengerKeyboardPanelSchuduleSendTimeTap(currentSelectDate: Date,
                                                            sendMessageModel: SendMessageModel,
                                                            _ task: @escaping (Date) -> Void) {
        guard let from = self.delegate?.baseViewController() else {
            assertionFailure()
            return
        }
        // 初始化当前的时间
        self.scheduleDate = currentSelectDate
        self.scheduleInitDate = currentSelectDate
        currentViewModel?.scheduleSendService?.showDatePickerInEdit(currentSelectDate: currentSelectDate,
                                                                   chatName: viewModel.chat.name,
                                                                   from: from,
                                                                   isShowSendNow: !(sendMessageModel.cid.isEmpty && sendMessageModel.messageId.isEmpty),
                                                                   sendNowCallback: { [weak self] in
                guard let self = self else { return }
                IMTracker.Chat.Main.Click.Msg.msgDelayedSendClick(self.viewModel.chat, click: "send_immediate", self.delegate?.chatFromWhere)
                self.patchScheduleMessage(itemId: sendMessageModel.messageId,
                                          cid: sendMessageModel.cid,
                                          itemType: sendMessageModel.itemType,
                                          isSendImmediately: true,
                                          needSuspend: false)
            },
                                                                   confirmTask: { [weak self] date in
                if let initDate = self?.scheduleInitDate, date != initDate, let chat = self?.viewModel.chat {
                    IMTracker.Chat.Main.Click.Msg.msgDelayedSendClick(chat, click: "modify_time", self?.delegate?.chatFromWhere)
                }
                self?.scheduleDate = date
                task(date)
        })
    }

    func patchScheduleMessage(itemId: String,
                              cid: String,
                              itemType: RustPB.Basic_V1_ScheduleMessageItem.ItemType,
                              isSendImmediately: Bool,
                              needSuspend: Bool) {
        guard let from = self.delegate?.baseViewController() else {
            assertionFailure()
            return
        }
        func callback() {
            self.keyboardView.fold()
            self.cleanPostDraft()
            DispatchQueue.main.async {
                self.onInputFinished()
                self.keyboardView.goBackToLastStatus()
            }
        }
        let vm = viewModel
        // 如果定时消息已经发送/删除，弹toast后恢复普通输入框
        if let ids = self.delegate?.getSendScheduleMsgIds(), ids.0.contains { $0 == itemId } || ids.1.contains { $0 == itemId } {
            vm.keyboardStatusManagerBlock?()?.switchJob(.normal)
            UDToast.showTips(with: BundleI18n.LarkThread.Lark_IM_ScheduleMessage_UnaleToSendAgain_Toast, on: from.view)
            callback()
            return
        }

        // 如果当前选择的消息已经过去了，弹toast阻断
        if isSendImmediately == false, let date = scheduleDate, date < Date() {
            UDToast.showTips(with: BundleI18n.LarkThread.Lark_IM_ScheduleMessage_TimePassedSelectAgain_Toast, on: from.view)
            return
        }

        let chat = self.viewModel.chat
        if !chat.isAllowPost {
            guard let window = self.delegate?.baseViewController().view.window else { return }
            UDToast.showFailure(with: BundleI18n.LarkThread.Lark_IM_EditMessage_FailedToEditDueToSpecificSettings_Toast(chat.name), on: window)
            callback()
            return
        }
        var contentAttr = keyboardView.getTrimTailSpacesAttributedString()
        /// 如果没有图片&视频&标题&代码块 走Text消息
        let canSendText = canSendTextMessageForAttr(contentAttr, title: "")
        contentAttr = RichTextTransformKit.preproccessSendAttributedStr(contentAttr)
        // 判断内容为空
        guard contentAttr.string.isEmpty == false, var richText = RichTextTransformKit.transformStringToRichText(string: contentAttr) else {
            // 消息内容为空，弹窗
            vm.scheduleSendService?.showAlertWhenContentNil(from: from,
                                                           chatID: Int64(vm.chat.id) ?? 0,
                                                           itemId: itemId,
                                                           itemType: itemType,
                                                           deleteConfirmTask: { [weak self] in
                self?.keyboardView.switchToDefaultJob()
            },
                                                           deleteSuccessTask: { [weak self] in
                IMTracker.Chat.Main.Click.Msg.msgDelayedSendClick(vm.chat, click: "delete", self?.delegate?.chatFromWhere)
            })
            return
        }

        // 重置输入框状态和草稿
        callback()
        self.delegate?.setScheduleTipViewStatus(.updating)

        // 调用接口
        var quasiContent = QuasiContent()
        richText.richTextVersion = 1
        quasiContent.richText = richText
        quasiContent.lingoOption = LingoConvertService.transformStringToQuasiContent(contentAttr)
        // 格式化时间
        var sendScheduleTime: Int64?
        if let time = self.scheduleTime {
            sendScheduleTime = ScheduleSendManager.formatSendScheduleTime(time)
        }
        var item = ScheduleMessageItem()
        item.itemID = itemId
        item.itemType = itemType
        vm.postSendService?.patchScheduleMessage(chatID: Int64(self.viewModel.chat.id) ?? 0,
                                                cid: cid,
                                                item: item,
                                                messageType: canSendText ? .text : .post,
                                                content: quasiContent,
                                                scheduleTime: sendScheduleTime,
                                                isSendImmediately: isSendImmediately,
                                                needSuspend: needSuspend) { [weak from] result in
            switch result {
            case .success(_):
                break
            case .failure(let error):
                DispatchQueue.main.async {
                    if let view = from?.view {
                        UDToast.showFailure(with: BundleI18n.LarkThread.Lark_Legacy_ErrorMessageTip, on: view, error: error)
                    }
                }
                Self.logger.error("patchScheduleMessage error", error: error)
            }
        }
    }

    // 点击"定时发送"按钮
    public func onMessengerKeyboardPanelSchuduleSendButtonTap() {
    }

    public func scheduleTipDidShow(date: Date) {
        // 初始化当前的时间
        let formatDate = ScheduleSendManager.formatSendScheduleDate(date)
        self.scheduleDate = formatDate
    }

    // 定时消息再次编辑后关闭
    public func onMessengerKeyboardPanelSchuduleCloseButtonTap(itemId: String,
                                                               itemType: RustPB.Basic_V1_ScheduleMessageItem.ItemType) {
        guard let from = self.delegate?.baseViewController() else {
            assertionFailure()
            return
        }
        self.keyboardView.inputTextView.resignFirstResponder()
        viewModel.scheduleSendService?.showAlertWhenSchuduleCloseButtonTap(from: from,
                                                                          chatID: Int64(viewModel.chat.id) ?? 0,
                                                                          itemId: itemId,
                                                                          itemType: itemType,
                                                                          cancelTask: { [weak self] in
                guard let self = self else { return }
                self.viewModel.keyboardStatusManagerBlock?()?.goBackToLastStatus()
        },
                                                                          closeTask: { [weak self, weak from] in
                guard let self = self else { return }
                IMTracker.Chat.Main.Click.Msg.msgDelayedSendClick(self.viewModel.chat, click: "delete", self.delegate?.chatFromWhere)
                self.viewModel.keyboardStatusManagerBlock?()?.goBackToLastStatus()
                // 如果定时消息已经发送/删除，弹toast后恢复普通输入框
                if let ids = self.delegate?.getSendScheduleMsgIds(), ids.0.contains { $0 == itemId } || ids.1.contains { $0 == itemId }, let from = from {
                    self.viewModel.keyboardStatusManagerBlock?()?.switchJob(.normal)
                    UDToast.showTips(with: BundleI18n.LarkThread.Lark_IM_ScheduleMessage_UnaleToSendAgain_Toast, on: from.view)
                }

        }) { [weak self] in
            self?.keyboardView.inputTextView.becomeFirstResponder()
        }
    }

    // 定时消息二次编辑点击确认
    public func onMessengerKeyboardPanelSchuduleConfrimButtonTap(itemId: String,
                                                                 cid: String,
                                                                 itemType: RustPB.Basic_V1_ScheduleMessageItem.ItemType) {
        patchScheduleMessage(itemId: itemId, cid: cid, itemType: itemType, isSendImmediately: false, needSuspend: true)
    }

    // 长按发送按钮
    public func onMessengerKeyboardPanelSendLongPress() {
        // my ai不支持创建
        if viewModel.chat.isP2PAi { return }
        guard self.currentViewModel?.scheduleSendService?.scheduleSendEnable == true else { return }
        guard ScheduleSendManager.chatCanScheduleSend(viewModel.chat) else { return }
        guard let from = self.delegate?.baseViewController() else {
            assertionFailure()
            return
        }
        if keyboardView.keyboardShareDataService.forwardToChatSerivce.forwardToChat {
            UDToast.showFailure(with: BundleI18n.LarkThread.Lark_IM_AlsoSendGroup_CantSendScheduleMsg_Toast, on: from.view)
            return
        }
        // 检查是否有已经发送过的定时消息
        if self.delegate?.getScheduleMsgSendTime() != nil {
            Self.logger.info("getScheduleMsgSendTime not empty")
            IMTracker.Chat.Main.Click.Msg.msgDelayedSendToastView(self.viewModel.chat, self.delegate?.chatFromWhere)
            UDToast.showTips(with: BundleI18n.LarkThread.Lark_IM_ScheduleMessage_CanSendOnly1ScheduledMessage_Tooltip, on: from.view)
            return
        }
        getHasScheduleMsg()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak from] hasScheduleMsg in
                guard let `self` = self, let from = from else { return }
                guard !hasScheduleMsg else {
                    UDToast.showTips(with: BundleI18n.LarkThread.Lark_IM_ScheduleMessage_CanSendOnly1ScheduledMessage_Tooltip, on: from.view)
                    IMTracker.Chat.Main.Click.Msg.msgDelayedSendToastView(self.viewModel.chat, self.delegate?.chatFromWhere)
                    return
                }
                // 大于当前时间5分钟
                let currentInitDate = Date().addingTimeInterval(5 * 60)
                // 默认选择时间大于当前时间
                let currentSelectDate = ScheduleSendManager.getFutureHour(Date())
                IMTracker.Chat.Main.Click.Msg.delayedSendMobile(self.viewModel.chat, self.delegate?.chatFromWhere)
                self.currentViewModel?.scheduleSendService?.showDatePicker(currentInitDate: currentInitDate,
                                                                          currentSelectDate: currentSelectDate,
                                                                          from: from) { [weak self, weak from] time in
                    guard let `self` = self, let from = from else { return }
                    self.getHasScheduleMsg()
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { [weak self, weak from] hasScheduleMsg in
                            guard let `self` = self, let from = from else { return }
                            guard !hasScheduleMsg else {
                                UDToast.showTips(with: BundleI18n.LarkThread.Lark_IM_ScheduleMessage_CanSendOnly1ScheduledMessage_Tooltip, on: from.view)
                                IMTracker.Chat.Main.Click.Msg.msgDelayedSendToastView(self.viewModel.chat, self.delegate?.chatFromWhere)
                                return
                            }
                            let formatTime = ScheduleSendManager.formatSendScheduleTime(time)
                            self.keyboardView.sendNewMessage(scheduleTime: formatTime)
                        }).disposed(by: self.disposeBag)
                }
            }).disposed(by: self.disposeBag)
    }

    private func getHasScheduleMsg() -> Observable<Bool> {
        let chatId = viewModel.chat.id
        var threadId: Int64?
        switch viewModel.keyboardStatusManagerBlock?()?.currentKeyboardJob {
        case .reply(let info):
            threadId = Int64(info.message.threadId) ?? 0
        default:
            return .just(false)
        }
        return viewModel.messageAPI?.getScheduleMessages(chatId: Int64(chatId) ?? 0,
                                                        threadId: threadId,
                                                        rootId: nil,
                                                        isForceServer: false,
                                                        scene: .replyInThread)
            .map { res in
                let status = ChatScheduleSendTipViewModel.getScheduleTypeFrom(messageItems: res.messageItems, entity: res.entity)
                Self.logger.info("getScheduleMessages chatId: \(chatId), res.messageItemsCount:\(res.messageItems.count), status: \(status)")
                return res.messageItems.isEmpty == false
            } ?? .just(false)
    }
}
