//
//  NewThreadKeyboard.swift
//  LarkThread
//
//  Created by liluobin on 2021/9/8.
//

import Foundation
import UIKit
import LarkCore
import LarkRichTextCore
import LarkKeyboardView
import RustPB
import LarkModel
import ByteWebImage
import LarkAlertController
import LarkAttachmentUploader
import LarkMessengerInterface
import LarkMessageBase
import LarkMessageCore
import UniverseDesignToast
import LarkSDKInterface
import RxCocoa
import RxSwift
import EditTextView
import UniverseDesignDialog
import LarkBaseKeyboard
import EENavigator
import UniverseDesignDatePicker
import LarkChatOpenKeyboard

import UniverseDesignActionPanel

final class NewThreadKeyboard: ThreadKeyboard {

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
            assertionFailure("attachmentManager 为空")
            return
        }
        attachmentManager.applyAttachmentDraftForTextView(keyboardView.inputTextView,
                                                          async: true,
                                                          imageMaxHeight: keyboardView.textFieldMaxHeight - 5,
                                                          imageMinWidth: 80,
                                                          finishBlock: {[weak self] in
            guard let self = self else { return }
            self.currentViewModel?.attachmentManager?.attachmentUploader.startUpload()
            self.currentViewModel?.attachmentManager?.updateImageAttachmentState(self.keyboardView.inputTextView)
        }, didUpdateAttrText: { [weak self] in
            guard let self = self else { return }
            if needToClearTranslationData {
                self.translateDataService.clearTranslationData()
            }
        })
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

    /// 恢复草稿
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
        let transmitToChat = keyboardView.keyboardShareDataService.forwardToChatSerivce.forwardToChat
        keyboardView.keyboardShareDataService.forwardToChatSerivce.messageWillSend(chat: viewModel.chat)
        if richText.richText.imageIds.isEmpty,
           richText.richText.mediaIds.isEmpty,
           richText.title.isEmpty,
           !CodeInputHandler.richTextContainsCode(richText: richText.richText) {
            /// RichTextContent的 richText.processProvider这里没有了呢
            self.viewModel.delegate?.defaultInputSendTextMessage(richText.richText,
                                                                 lingoInfo: richText.lingoInfo,
                                                                 parentMessage: replyMessage,
                                                                 scheduleTime: scheduleTime,
                                                                 transmitToChat: transmitToChat,
                                                                 isFullScreen: true)
        } else {
            super.onComposePostViewCompleteWith(richTextContent, replyMessage: replyMessage, scheduleTime: scheduleTime)
        }
    }
    /// 发送消息
    override func inputTextViewSend(attributedText: NSAttributedString, scheduleTime: Int64?) {
        guard let attachmentManager = currentViewModel?.attachmentManager,
              !attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        if attachmentManager.checkAttachmentAllUploadSuccessFor(attruibuteStr: attributedText) {
            sendMessageWith(contentAttributedText: attributedText)
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
                    self?.sendMessageWith(contentAttributedText: attributedText)
                }
            }
        }
    }

    fileprivate func sendMessageWith(contentAttributedText: NSAttributedString) {
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
                                                                scheduleTime: nil,
                                                                transmitToChat: transmitToChat,
                                                                isFullScreen: false)
            } else {
                viewModel.delegate?.defaultInputSendPost(content: RichTextContent(title: title, richText: richText, lingoInfo: lingoInfo),
                                                         parentMessage: viewModel.replyMessage,
                                                         scheduleTime: nil,
                                                         transmitToChat: transmitToChat,
                                                         isFullScreen: false)
            }
        }
        cleanPostDraft()
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
                                   beforeApplyCallBack: ((NSAttributedString) -> NSAttributedString)?) {
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
        guard let message = keyboardView.keyboardStatusManager.getMultiEditMessage() else {
            return
        }
        IMTracker.Chat.Main.Click.Msg.saveEditMsg(self.viewModel.chat,
                                                  message,
                                                  triggerMethod: triggerMethod,
                                                  nil)
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
                guard let self = self,
                      let window = self.delegate?.baseViewController().view.window else { return }
                IMTracker.Msg.WithdrawConfirmCLick(self.viewModel.chat,
                                                   message,
                                                   clickConfirm: true)
                if self.viewModel.rootMessage?.id == self.keyboardView.keyboardStatusManager.getMultiEditMessage()?.id {
                    //撤回根消息
                    let hud = UDToast.showLoading(
                        with: BundleI18n.LarkThread.Lark_Legacy_BaseUiLoading,
                        on: window,
                        disableUserInteraction: true)
                    self.viewModel.messageAPI?
                        .deleteByNoTrace(with: message.id)
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { _ in
                            hud.remove()
                        }, onError: { [weak window, weak self] error in
                            guard let window = window else { return }
                            hud.remove()
                            if let error = error.underlyingError as? APIError {
                                switch error.type {
                                case .notDeleteThreadWhenOverTime(let message):
                                    hud.showFailure(with: message, on: window, error: error)
                                    self?.currentViewModel?.multiEditService?.reloadEditEffectiveTimeConfig()
                                default:
                                    hud.showFailure(
                                        with: BundleI18n.LarkThread.Lark_Legacy_ChatViewFailHideMessage,
                                        on: window,
                                        error: error
                                    )
                                }
                            } else {
                                hud.showFailure(
                                    with: BundleI18n.LarkThread.Lark_Legacy_ChatViewFailHideMessage,
                                    on: window,
                                    error: error
                                )
                            }
                        }).disposed(by: self.disposeBag)
                } else {
                    //撤回非根消息
                    self.viewModel.messageAPI?
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
                }
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
            let chat = self.viewModel.chat
            if !chat.isAllowPost && message.rootId.isEmpty { //rootId为空表示是根帖。如果chat被禁言，不能编辑根帖，但可以编辑回帖。
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

                richText.richTextVersion = 1
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

extension NewThreadKeyboard: MessengerKeyboardPanelRightContainerViewDelegate {
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
}
