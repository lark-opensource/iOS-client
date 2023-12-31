//
//  NormalChatInputKeyboard+Draft.swift
//  LarkChat
//
//  Created by liluobin on 2022/9/1.
//

import UIKit
import Foundation
import LarkSDKInterface
import LarkMessengerInterface
import LarkMessageCore
import LarkMessageBase
import LarkContainer
import LarkModel
import LarkCore
import LarkBaseKeyboard
import LarkKeyboardView
import LKCommonsLogging
import EditTextView
import LarkAttachmentUploader
import RustPB
import UniverseDesignDialog
import UniverseDesignToast
import RxSwift
import LarkAlertController
import ByteWebImage
import EENavigator

/// 草稿相关的逻辑
extension NormalChatInputKeyboard {
    var draft: String? {
        guard let postDraft = self.postDraft else { return nil }
        if postDraft.title.isEmpty && postDraft.content.isEmpty {
            return ""
        }
        return postDraft.stringify()
    }

    var postDraft: PostDraftModel? {
        get {
            if self.keyboardView.keyboardShareDataService.isMyAIChatMode {
                return nil
            }
            guard let delegate = keyboardView.keyboardStatusManager.delegate else { return nil }
            var postDraft: PostDraftModel = PostDraftModel()
            if self.keyboardView.keyboardStatusManager.getRelatedDispalyMessage() == nil,
                self.viewModel.rootMessage == nil {
                postDraft.title = delegate.getKeyboardTitle()?.string ?? ""
            }
            let attrText = delegate.getKeyboardAttributedText()
            if !attrText.string.isEmpty,
               let richText = RichTextTransformKit.transformStringToRichText(string: attrText) {
                postDraft.content = (try? richText.jsonString()) ?? ""
            }
            if postDraft.content.isEmpty && postDraft.title.isEmpty {
                return postDraft
            }
            if let attachmentManager = chatInputViewModel?.attachmentManager,
            let data = attachmentManager.attachmentUploader.draft.atchiverData(),
                let draftStr = String(data: data, encoding: .utf8) {
                postDraft.uploaderDraft = draftStr
            }
            postDraft.lingoElements = LingoConvertService.transformStringToDraftModel(attrText)
            postDraft.userInfoDic = AtTransformer.getAllChatterActualNameMapForAttributedString(attrText)
            return postDraft
        }
        set {
            if self.keyboardView.keyboardShareDataService.isMyAIChatMode {
                return
            }
            guard let postDraft = newValue else { return }
            keyboardView.titleEditView?.textView.replace(NSAttributedString(string: postDraft.title))
            if let draftData = postDraft.uploaderDraft.data(using: .utf8),
                let uploaderDraft = AttachmentUploader.Draft(draftData) {
                chatInputViewModel?.attachmentManager?.attachmentUploader.draft = uploaderDraft
            }

            if let richText = try? RustPB.Basic_V1_RichText(jsonString: postDraft.content) {
                let attachmentResult: [String: String] = chatInputViewModel?.attachmentManager?.attachmentUploader.results ?? [:]
                var content = RichTextTransformKit.transformRichTextToStr(
                    richText: richText,
                    attributes: keyboardView.inputTextView.baseDefaultTypingAttributes,
                    attachmentResult: attachmentResult,
                    processProvider: postDraft.processProvider)
                /// 删除尾部换行
                content = content.lf.trimmedAttributedString(set: CharacterSet.newlines, position: .trail)
                AtTransformer.getAllChatterInfoForAttributedString(content).forEach { chatterInfo in
                    chatterInfo.actualName = postDraft.userInfoDic[chatterInfo.id] ?? ""
                }
                fontPanelSubModule?.onTextViewLengthChange(content.length)
                let contentStr = LingoConvertService.transformModelToString(elements: postDraft.lingoElements, text: content)
                chatKeyboardView?.inputTextView.replace(contentStr, useDefaultAttributes: false)
            } else if !postDraft.content.isEmpty {
                // 处理旧版本草稿格式
                let draft = NSAttributedString(string: postDraft.content, attributes: keyboardView.inputTextView.defaultTypingAttributes)
                let content = OldVersionTransformer.transformInputText(draft)
                fontPanelSubModule?.onTextViewLengthChange(content.length)
                chatKeyboardView?.inputTextView.replace(content, useDefaultAttributes: false)
            }
            setupAttachment()
            Self.logger.info("ChatInputKeyboard setPostDraft",
                             additionalData: ["chatId": self.viewModel.chatWrapper.chat.value.id,
                                                                  "messageId": self.viewModel.replyMessage?.id ?? "",
                                                                  "DraftLength": "\(self.keyboardView.inputTextView.text.count)"])
        }
    }

    func autoRecoveryDraft(_ finish: (() -> Void)? = nil) {
        if !viewModel.chatModel.textDraftId.isEmpty || !(viewModel.rootMessage?.textDraftId.isEmpty ?? true) {
            chatInputViewModel?.getTextDraftContent()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (draft) in
                    guard let self = self else { return }
                    self.updateTextDraft(draft.0)
                    self.chatInputViewModel?.cleanTextDraft()
                    finish?()
                }).disposed(by: self.disposeBag)
        } else {
            self.updateDraftContent(onFinished: finish)
        }
    }

    /// 如果之前有text的草稿 首次进入需要恢复一下，然后清空
    func recoveryTextDraftIfNeedWith(chat: Chat, draft: RustPB.Basic_V1_Draft?) {
        /// 如果对某条消息有回复的草稿，清空一下，同时清空chat的Text草稿
        if let draft = draft, draft.type == .text, self.viewModel.replyMessage == nil {
            /// 需要展示Text草稿
            self.chatKeyboardView?.needShowTextDraft = true
            /// 如果有Text的消息，需要清空一下
            if !chat.textDraftId.isEmpty {
                self.viewModel.save(draft: "", id: .chat(chatId: chat.id), type: .text, callback: nil)
            }
        }
    }
    /// 获取到的草稿如果是Text类型的，使用父类进行解析&还原
    private func updateTextDraft(_ draft: String) {
        super.updateDraftContent(by: draft)
    }

    func updateAttachmentInfo() {
        chatInputViewModel?.attachmentManager?.updateAttachmentResultInfo(keyboardView.inputTextView.attributedText)
        chatInputViewModel?.attachmentManager?.updateImageAttachmentState(keyboardView.inputTextView)
    }

    func updateAttachmentUploaderDefaultCallBack() {
        guard let attachmentManager = chatInputViewModel?.attachmentManager else {
            return
        }
        attachmentManager.defaultCallBack = {  [weak self] (_, _, url, data, error) in
            guard let `self` = self else { return }
            self.updateAttachmentStateWith(url: url, data: data)
            if let apiError = error?.underlyingError as? APIError, let vc = self.delegate?.baseViewController() {
                switch apiError.type {
                case .cloudDiskFull:
                    let alertController = LarkAlertController()
                    alertController.showCloudDiskFullAlert(from: vc, nav: self.navigator)
                case .securityControlDeny(let message):

                    self.chatInputViewModel?.chatSecurityControlService?.authorityErrorHandler(event: .sendImage,
                                                                                              authResult: nil,
                                                                          from: vc,
                                                                          errorMessage: message)
                case .strategyControlDeny: // 鉴权的策略引擎返回的报错，安全侧弹出弹框，端上做静默处理
                    break
                default:
                    self.showDefaultError(error: apiError)
                }
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
            with: BundleI18n.LarkChat.Lark_Legacy_ErrorMessageTip, on: window, error: error
        )
    }

    func updateAttachmentDraftWithReplayMessageId(_ messageId: String, data: Data?) {
        guard let vm = chatInputViewModel, let attachmentManager = vm.attachmentManager else {
            return
        }
        let root = attachmentManager.attachmentUploader.cache.root
        let fromDomain = ComposePostViewModel.postDraftFileKey(id: .chat(chatId: vm.chatModel.id), isNewTopic: false)
        let toDomain = ComposePostViewModel.postDraftFileKey(id: .replyMessage(messageId: messageId), isNewTopic: false)
        AttachmentDataStorage.moveDraftPath(root: root, fromDomain: fromDomain, toDomain: toDomain)
        if let data = data, let uploaderDraft = AttachmentUploader.Draft(data) {
            attachmentManager.attachmentUploader.draft = uploaderDraft
        }
        vm.save(draft: "", id: .chat(chatId: viewModel.chatModel.id), type: .post, callback: nil)
    }

    func updateAttachmentStateWith(url: String?, data: Data?) {
        guard let attachmentManager = chatInputViewModel?.attachmentManager else {
            return
        }
        attachmentManager.updateAttachmentResultInfo(self.keyboardView.attributedString)
        attachmentManager.updateImageAttachmentState(self.keyboardView.inputTextView)
        if let imageData = data,
           let key = url,
           let image = try? ByteImage(imageData),
           let resourceAPI = self.viewModel.resourceAPI {
            let originKey = resourceAPI.computeResourceKey(key: key, isOrigin: true)
            attachmentManager.storeImageToCacheFromDraft(image: image, imageData: imageData, originKey: originKey)
        }
    }

    /// 草稿设置后的恢复
    func setupAttachment(needToClearTranslationData: Bool = false) {
        guard let attachmentManager = chatInputViewModel?.attachmentManager else {
            assertionFailure("attachmentManager 为空")
            return
        }
        attachmentManager.applyAttachmentDraftForTextView(keyboardView.inputTextView,
                                                          async: true,
                                                          imageMaxHeight: keyboardView.textFieldMaxHeight - 5,
                                                          imageMinWidth: 80) { [weak self] in
            guard let self = self, let attachmentManager = self.chatInputViewModel?.attachmentManager else { return }
            attachmentManager.attachmentUploader.startUpload()
            attachmentManager.updateImageAttachmentState(self.keyboardView.inputTextView)
        } didUpdateAttrText: { [weak self] in
            guard let self = self else { return }
            if needToClearTranslationData {
                self.translateDataService.clearTranslationData()
            }
        }
        // 这里涉及UI布局操作，需要保证与View初始化不在一次runloop内才能生效
        DispatchQueue.main.async {
            self.keyboardView.keyboardPanel.reloadPanel()
        }
    }

}
