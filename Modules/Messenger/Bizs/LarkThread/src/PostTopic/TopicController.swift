//
//  TopicController.swift
//  LarkThread
//
//  Created by zoujiayi on 2019/9/25.
//

import Foundation
import UIKit
import LarkUIKit
import LarkModel
import EditTextView
import LarkCore
import LarkRichTextCore
import LarkKeyboardView
import RxSwift
import UniverseDesignToast
import EENavigator
import LarkMessageCore
import LarkSDKInterface
import LarkFeatureGating
import LarkAttachmentUploader
import LarkMessengerInterface
import LarkSendMessage
import LarkAlertController
import RustPB
import LarkContainer
import UniverseDesignDialog
import LKCommonsLogging
import LarkMessageBase
import LarkBaseKeyboard
import LarkChatOpenKeyboard

/// 话题编辑&发送界面
final class TopicController: BaseUIViewController, UserResolverWrapper {
    let userResolver: UserResolver
    static let logger = Logger.log(TopicController.self, category: "Module.LarkThread")

    private var isDefaultTopicGroup: Bool
    private let topicView: TopicView
    let composePostController: ComposePostViewController
    private let postSendService: PostSendService
    private let disposeBag = DisposeBag()
    private let startCreateTopicTime: TimeInterval

    var dismissCallBack: (() -> Void)?

    private let viewModel: ComposePostViewModel

    @ScopedInjectedLazy private var chatDurationStatusTrackService: ChatDurationStatusTrackService?
    @ScopedInjectedLazy var lingoHighlightService: LingoHighlightService?
    init(userResolver: UserResolver,
         chatApi: ChatAPI,
         router: ComposePostRouter,
         viewModel: ComposePostViewModel,
         postSendService: PostSendService,
         isDefaultTopicGroup: Bool = false,
         isPadPageStyle: Bool = false
    ) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        self.isDefaultTopicGroup = isDefaultTopicGroup
        self.composePostController = ComposePostViewController(
            viewModel: self.viewModel,
            chatFromWhere: .ignored
        )

        self.postSendService = postSendService
        self.startCreateTopicTime = CACurrentMediaTime()
        var showSaveAndCancelButton = false
        if case .multiEdit = viewModel.keyboardStatusManager.currentKeyboardJob {
            showSaveAndCancelButton = true
        }
        self.topicView = TopicView(showSaveAndCancelButton: showSaveAndCancelButton,
                                   isPadPageStyle: isPadPageStyle)
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .fullScreen
        self.isNavigationBarHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.layoutTopicView()
        self.layoutInputView()

        if Display.phone {
            chatDurationStatusTrackService?.setGetChatBlock { [weak self] in
                return self?.viewModel.chatModel
            }
        }

        // 取草稿
        self.viewModel.fetchDraftModel()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (postDraft) in
                guard let self = self else { return }
                if self.postDraft == PostDraftModel.default {
                    /// 草稿图片布局需要 view width
                    /// 这里强行 layout
                    self.view.layoutIfNeeded()
                    self.postDraft = postDraft
                    self.updateAttachmentResultInfo(
                        self.composePostController.contentTextView.attributedText ?? NSAttributedString()
                    )
                    self.updateImageAttachmentState()
                }
            }).disposed(by: disposeBag)

        // 间隔 2s 存储一次
        self.composePostController
            .contentTextView.rx.value.asDriver()
            .skip(1).throttle(.seconds(2)).drive(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                if self.composePostController.contentTextView.isFirstResponder {
                    self.saveDraft(self.composePostController.getAllImageAndVideoIds())
                }
            }).disposed(by: self.disposeBag)

        if case .multiEdit(let message) = viewModel.keyboardStatusManager.currentKeyboardJob {
           setupMultiMessage(message)
        }
        self.viewModel.keyboardStatusManager.delegate = self
        self.setupLingo()
    }

    // swiftlint:disable all
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    // swiftlint:enable all

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if Display.phone {
            chatDurationStatusTrackService?.markIfViewControllerIsAppear(value: true)
        }

        if self.composePostController.shouldShowKeyboard {
            self.composePostController.shouldShowKeyboard = false
            if Display.pad {
                self.parent?.view.layoutIfNeeded()
            }
            self.composePostController.contentTextView.becomeFirstResponder()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if Display.phone {
            chatDurationStatusTrackService?.markIfViewControllerIsAppear(value: false)
        }
    }

    private func layoutInputView() {
        self.addChild(composePostController)
        self.topicView.addEditer(composePostController.view)
        composePostController.delegate = self
    }

    private func layoutTopicView() {
        topicView.delegate = self
        self.view.addSubview(topicView)
        topicView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    /// 注册输入框内百科高亮服务
    private func setupLingo() {
        lingoHighlightService?.setupLingoHighlight(chat: self.viewModel.chatModel,
                                                  fromController: self,
                                                  inputTextView: self.composePostController.contentTextView,
                                                  getMessageId: { [weak self] in
            self?.viewModel.keyboardStatusManager.getMultiEditMessage()?.id ?? ""
        })
    }

    /// 更新图片附件上传状态
    fileprivate func updateImageAttachmentState() {
        self.viewModel.attachmentServer.updateImageAttachmentState(self.composePostController.contentTextView)
    }

    /// 根据 upload result 更新附件 result
    fileprivate func updateAttachmentResultInfo(_ attributedText: NSAttributedString) {
        self.viewModel.attachmentServer.updateAttachmentResultInfo(attributedText)
    }

    fileprivate func doSendPost() {

        let titleAttributedText = NSAttributedString(string: "") // 发帖没有标题
        var contentAttributedText = self.composePostController.contentTextView.attributedText ?? NSAttributedString(string: "")
        let title: String = titleAttributedText.string.lf.trimCharacters(in: .whitespacesAndNewlines, postion: .tail)
        /// 裁剪尾部的空格
        contentAttributedText = KeyboardStringTrimTool.trimTailAttributedString(attr: contentAttributedText, set: .whitespaces)
        contentAttributedText = RichTextTransformKit.preproccessSendAttributedStr(contentAttributedText)
        if var richText = RichTextTransformKit.transformStringToRichText(string: contentAttributedText) {
            richText.richTextVersion = 1
            // 广场发帖，不支持设置匿名
            var isAnonymous = false
            // 小组发帖，支持设置匿名
            let lingoInfo = LingoConvertService.transformStringToQuasiContent(contentAttributedText)
            self.postSendService.sendThread(
                title: title,
                content: richText,
                lingoInfo: lingoInfo,
                chatId: self.viewModel.chatModel?.id ?? "",
                isGroupAnnouncement: false
            )
            // 是否是公开群
            let isPublic = self.viewModel.chatModel?.isPublic ?? false
            ThreadTracker.trackNewPost(isDefaultTopicGroup: self.isDefaultTopicGroup, isPulicGroup: isPublic, isAnonymous: isAnonymous)
            DispatchQueue.main.async {
                self.isEditing = false
                self.dismiss()
                self.cleanDraft()
            }
        }
    }

    private func dismiss() {
        ThreadTracker.trackUserDurationCreateContent(startTime: startCreateTopicTime)
        if self.dismissCallBack != nil {
            self.dismissCallBack?()
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
}

extension TopicController: TopicViewDelegate,
                           PadLargeModalDelegate {
    func TopicViewOnCancel(_ view: TopicView) {
        saveDraftBeforeClosed()
        self.dismiss()
    }

    func TopicViewOnSave(_ view: TopicView) {
        multiEditMessage()
    }

    func TopicViewOnChangeTopic(_ view: TopicView) {
        self.composePostController.contentTextView.resignFirstResponder()
    }

    func TopicViewOnClose(_ view: TopicView) {
        saveDraftBeforeClosed()
        self.dismiss()
    }

    //点击了背景，将要dismiss
    func padLargeModalViewControllerBackgroundClicked() {
        saveDraftBeforeClosed()
    }

    private func saveDraftBeforeClosed() {
        self.isEditing = false
        self.saveDraft(self.composePostController.getAllImageAndVideoIds())
        ThreadTracker.trackNewPostEdit(action: .cancel)
    }
}

extension TopicController: ComposePostViewControllerDelegate {
    func dismissByCancel() {
    }

    func updateAttachmentResultInfo() {
    }

    func onMessengerKeyboardPanelSchuduleSendButtonTap() {
    }

    func updateSendButton(isEnabled: Bool) {
    }

    func scheduleSendMessage() {
    }

    func patchScheduleMessage(itemId: String,
                              cid: String,
                              itemType: RustPB.Basic_V1_ScheduleMessageItem.ItemType,
                              isSendImmediately: Bool,
                              needSuspend: Bool) {
    }

    func sendPost(scheduleTime: Int64? = nil) {
        if !self.composePostController.sendPostEnable() {
            let alertController = LarkAlertController()
            alertController.setTitle(text: BundleI18n.LarkThread.Lark_Legacy_Hint)
            alertController.setContent(text: BundleI18n.LarkThread.Lark_Legacy_ComposePostTitleContentEmpty)
            alertController.addPrimaryButton(text: BundleI18n.LarkThread.Lark_Legacy_Sure)
            navigator.present(alertController, from: self)
            return
        }

        self.composePostController.uploadFailsImageIfNeed { [weak self] success in
            guard let self = self else { return }
            if success {
                self.doSendPost()
            } else {
                UDToast.showFailure(with: BundleI18n.LarkThread.Lark_Legacy_LoadFailRetry, on: self.view)
            }
        }
    }

    func didInsertImage(_ viewController: ComposePostViewController) {
        self.saveDraft(viewController.getAllImageAndVideoIds())
    }

    func shouldContainFirstResponer() -> Bool {
        return false
    }

    func willResignFirstResponders() {
        //
    }

    func shouldShowKeyboard() -> Bool {
        return false
    }

    func updateTranslationIfNeed() {}

    func goBackToLastStatus() {}

    func multiEditMessage() {
        guard let message = self.viewModel.keyboardStatusManager.getMultiEditMessage() else {
            return
        }

        //触发二次编辑或（内容为空时）撤回后（无论请求是否成功），都会走到这里
        func callback() {
            viewModel.cleanPostDraft()
            self.dismiss()
        }

        if !self.composePostController.sendPostEnable() {
            //内容为空，视为撤回
            let dialog = UDDialog()
            dialog.setTitle(text: BundleI18n.LarkThread.Lark_IM_EditMessage_ClearAllContenAndRecallMessage_Title)
            dialog.setContent(text: BundleI18n.LarkThread.Lark_IM_EditMessage_ClearAllContenAndRecallMessage_Desc)
            dialog.addSecondaryButton(text: BundleI18n.LarkThread.Lark_IM_EditMessage_ClearAllContenAndRecallMessage_Cancel_Button,
                                      dismissCompletion: { [weak self] in
                IMTracker.Msg.WithdrawConfirmCLick(self?.viewModel.chatModel,
                                                   message,
                                                   clickConfirm: false)
            })
            dialog.addDestructiveButton(text: BundleI18n.LarkThread.Lark_IM_EditMessage_ClearAllContenAndRecallMessage_RecallMessage_Button,
                                        dismissCompletion: { [weak self] in
                guard let self = self else { return }
                IMTracker.Msg.WithdrawConfirmCLick(self.viewModel.chatModel,
                                                   message,
                                                   clickConfirm: true)
                let hud = UDToast.showLoading(
                    with: BundleI18n.LarkThread.Lark_Legacy_BaseUiLoading,
                    on: self.view,
                    disableUserInteraction: true)
                self.viewModel.messageAPI?
                    .deleteByNoTrace(with: message.id)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { _ in
                        hud.remove()
                        // also will pushThread() when delete success
                        // 删除成功后还会pushThread
//                        self.deleteMemeryTopic?(message.id)
                    }, onError: { [weak self] error in
                        guard let self = self else { return }
                        hud.remove()
                        if let error = error.underlyingError as? APIError {
                            switch error.type {
                            case .notDeleteThreadWhenOverTime(let message):
                                hud.showFailure(with: message, on: self.view, error: error)
                                self.viewModel.multiEditService?.reloadEditEffectiveTimeConfig()
                            default:
                                hud.showFailure(
                                    with: BundleI18n.LarkThread.Lark_Legacy_ChatViewFailHideMessage,
                                    on: self.view,
                                    error: error
                                )
                            }
                        } else {
                            hud.showFailure(
                                with: BundleI18n.LarkThread.Lark_Legacy_ChatViewFailHideMessage,
                                on: self.view,
                                error: error
                            )
                        }
                    }).disposed(by: self.disposeBag)
                callback()
            })

            navigator.present(dialog, from: self)
            return
        }

        var contentAttributedText = self.composePostController.contentTextView.attributedText ?? NSAttributedString(string: "")
        /// 裁剪尾部的空格
        contentAttributedText = KeyboardStringTrimTool.trimTailAttributedString(attr: contentAttributedText, set: .whitespaces)
        contentAttributedText = RichTextTransformKit.preproccessSendAttributedStr(contentAttributedText)
        if var richText = RichTextTransformKit.transformStringToRichText(string: contentAttributedText),
           let messageId = Int64(message.id) {
            richText.richTextVersion = 1
            let chat = self.viewModel.chatModel
            if !(chat?.isAllowPost ?? false) {
                guard let window = self.view.window else { return }
                UDToast.showFailure(with: BundleI18n.LarkThread.Lark_IM_EditMessage_FailedToEditDueToSpecificSettings_Toast(chat?.name ?? ""), on: window)
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
                navigator.present(dialog, from: self)
                return
            }

            callback()

            DispatchQueue.global(qos: .userInteractive).async {
                let lingoInfo = LingoConvertService.transformStringToQuasiContent(contentAttributedText)
                //没有改变任何内容点保存，则不执行任何操作
                if let oldMessageContent = self.viewModel.keyboardStatusManager.multiEditingMessageContent,
                   richText.isContentEqualTo(oldMessageContent.richText),
                   lingoInfo.isContentEqualTo(oldMessageContent.lingoInfo) {
                    return
                }

                let chatId = self.viewModel.chatModel?.id ?? ""
                self.requestMultiEditMessage(messageId: messageId,
                                             chatId: chatId,
                                             richText: richText,
                                             lingoInfo: lingoInfo)
            }
        }
    }

    func requestMultiEditMessage(messageId: Int64,
                                 chatId: String,
                                 richText: Basic_V1_RichText,
                                 lingoInfo: Basic_V1_LingoOption) {
        self.viewModel.multiEditService?.multiEditMessage(messageId: messageId,
                                                         chatId: chatId,
                                                         type: .post,
                                                         richText: richText,
                                                         title: nil,
                                                         lingoInfo: lingoInfo)
            .observeOn(MainScheduler.instance)
            .subscribe { _ in
            } onError: { [weak self] error in
                Self.logger.info("multiEditMessage fail, error: \(error)",
                                 additionalData: ["chatId": chatId,
                                                  "messageId": "\(messageId)"])
                guard let self = self,
                      let window = self.view.window,
                      let error = error.underlyingError as? APIError else {
                    return
                }
                switch error.type {
                case .editMessageNotInValidTime:
                    self.viewModel.multiEditService?.reloadEditEffectiveTimeConfig()
                default:
                    break
                }
                UDToast.showFailureIfNeeded(on: window, error: error)
            }.disposed(by: self.disposeBag)
    }
}

// MARK: Draft 相关
extension TopicController {

    var draft: String {
        let postDraft = self.postDraft
        if postDraft.title.isEmpty && postDraft.content.isEmpty {
            return ""
        }
        return postDraft.stringify()
    }

    var postDraft: PostDraftModel {
        get {
            if self.composePostController.contentTextView.text.isEmpty {
                return PostDraftModel()
            }
            var postDraft = PostDraftManager.getDraftModelFor(attributeStr: self.composePostController.contentTextView.attributedText,
                                                              attachmentUploader: self.viewModel.attachmentUploader)
            postDraft.chatId = self.viewModel.chatModel?.id ?? ""
            return postDraft
        }
        set {
            let postDraft = newValue
            PostDraftManager.applyPostDraftFor(postDraft,
                                               attachmentUploader: self.viewModel.attachmentUploader,
                                               contentTextView: self.composePostController.contentTextView)
            self.composePostController.setupAttachment()
        }
    }

    private func saveDraft(_ attachmentKeys: [String]) {
            self.viewModel.saveChatPostDraft(self.draft,
                                             attachmentKeys: attachmentKeys,
                                             async: true)
    }

    private func cleanDraft() {
        self.viewModel.cleanPostDraft()
    }

    private func saveDraftWhenAppTerminate() {
        let attachmentKeys = self.composePostController.getAllImageAndVideoIds()
        self.viewModel.saveChatPostDraft(self.draft,
                                         attachmentKeys: attachmentKeys,
                                         async: false)
    }
}

extension TopicController {
    func setupMultiMessage(_ message: Message) {
        if !message.editDraftId.isEmpty {
            self.viewModel.keyboardStatusManager.multiEditingMessageContent = nil
            //有草稿的话 走通用的取草稿逻辑即可
            return
        }
        let callBack: (() -> Void) = { [weak self] in
            guard let self = self else { return }
            var contentAttributedText = self.composePostController.contentTextView.attributedText ?? NSAttributedString(string: "")
            contentAttributedText = KeyboardStringTrimTool.trimTailAttributedString(attr: contentAttributedText, set: .whitespaces)
            contentAttributedText = RichTextTransformKit.preproccessSendAttributedStr(contentAttributedText)
            if let richText = RichTextTransformKit.transformStringToRichText(string: contentAttributedText) {
                let lingoInfo = LingoConvertService.transformStringToQuasiContent(contentAttributedText)
                self.viewModel.keyboardStatusManager.multiEditingMessageContent = (richText: richText, title: nil, lingoInfo: lingoInfo)
            }
        }
        switch message.type {
        case .text:
            setupTextMessage(message: message, callback: callBack)
        case .post:
            setupPostMessage(message: message, callback: callBack)
        @unknown default:
            break
        }
    }

    func setupTextMessage(message: Message, callback: (() -> Void)? = nil) {
        guard let textContent = message.content as? TextContent else {
            return
        }

        let attributes = composePostController.contentTextView.baseDefaultTypingAttributes
        let processProvider = MessageInlineViewModel.urlInlineProcessProvider(message: message, attributes: attributes)
        let attributedStr = RichTextTransformKit.transformRichTextToStr(
            richText: textContent.richText,
            attributes: attributes,
            attachmentResult: [:],
            processProvider: processProvider
        )
        updateAttributedStringAtInfo(attributedStr) { [weak self] in
            self?.composePostController.contentTextView.insert(attributedStr, useDefaultAttributes: false)
            callback?()
        }
    }

    func updateAttributedStringAtInfo(_ attributedStr: NSAttributedString, finish: (() -> Void)?) {
        let chatterInfo: [AtChatterInfo] = AtTransformer.getAllChatterInfoForAttributedString(attributedStr)
        /// 撤回重新编辑的时候，本地一定有数据很快就能返回，但是防止数据巨大或者异常时候，做个超时处理
        let chatID = self.viewModel.chatModel?.id ?? ""
        self.viewModel.chatterAPI?.fetchChatChattersFromLocal(ids: chatterInfo.map { $0.id },
                                          chatId: chatID)
            .timeout(.milliseconds(500), scheduler: MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (chatterMapInfo) in
                chatterInfo.forEach { $0.actualName = (chatterMapInfo[$0.id]?.localizedName ?? "") }
                finish?()
            }, onError: { error in
                finish?()
                Self.logger.error("fetchChatChatters error chatID \(chatID)", error: error)
            }).disposed(by: self.disposeBag)
    }

    func setupPostMessage(message: Message, callback: (() -> Void)? = nil) {
        guard let content = message.content as? PostContent else {
            return
        }
        let richText = TextDocsViewModel(userResolver: userResolver, richText: content.richText, docEntity: content.docEntity, hangPoint: message.urlPreviewHangPointMap).richText
        let attributes = self.composePostController.contentTextView.defaultTypingAttributes
        let processProvider = MessageInlineViewModel.urlInlineProcessProvider(message: message, attributes: attributes)
        let contentText = RichTextTransformKit.transformRichTextToStr(
            richText: richText,
            attributes: composePostController.contentTextView.baseDefaultTypingAttributes,
            attachmentResult: [:],
            processProvider: processProvider)
        updateAttributedStringAtInfo(contentText) { [weak self] in
            self?.composePostController.contentTextView.insert(contentText, useDefaultAttributes: false)
            callback?()
        }
    }
}

extension TopicController: KeyboardStatusDelegate {
    func willExitJob(currentJob: KeyboardJob, newJob: KeyboardJob, triggerByGoBack: Bool) {}

    func updateUIForKeyboardJob(oldJob: KeyboardJob?, currentJob: KeyboardJob) {
        switch currentJob {
        case .multiEdit(let message):
            let multiEditEffectiveTime = TimeInterval(viewModel.tenantUniversalSettingService?.getEditEffectiveTime() ?? 0)
            let timeRemaining = Date(timeIntervalSince1970: .init(message.createTime + multiEditEffectiveTime)).timeIntervalSince(Date())
            let enable = timeRemaining > 0
            if enable {
                viewModel.multiEditCountdownService.startMultiEditTimer(messageCreateTime: message.createTime,
                                                              effectiveTime: multiEditEffectiveTime,
                                                              onNeedToShowTip: { [weak self] in
                    self?.viewModel.keyboardStatusManager.addTip(.multiEditCountdown(.init(message.createTime + multiEditEffectiveTime)))
                },
                                                              onNeedToBeDisable: { [weak self] in
                    self?.topicView.setRightButtonEnable(false)
                })
            } else {
                viewModel.keyboardStatusManager.addTip(.multiEditCountdown(.init(message.createTime + Double(multiEditEffectiveTime))))
            }
        default:
            composePostController.keyboardPanel.reLayoutRightContainer(.sendButton(enable: self.composePostController.sendPostEnable()))
        }
    }

    func updateUIForKeyboardTip(_ value: KeyboardTipsType) {
        let containerView = composePostController.centerContainer
        for child in containerView.subviews {
            child.removeFromSuperview()
        }
        if let view = value.createView(delegate: nil, scene: .normal) {
            containerView.addSubview(view)
            view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
                make.height.equalTo(view.suggestHeight(maxWidth: containerView.bounds.width))
            }
        }
    }

    func getKeyboardAttributedText() -> NSAttributedString {
        return composePostController.contentTextView.attributedText
    }

    func getKeyboardTitle() -> NSAttributedString? {
        return nil
    }

    func updateKeyboardTitle(_ value: NSAttributedString?) {}

    func updateKeyboardAttributedText(_ value: NSAttributedString) {
        composePostController.contentTextView.attributedText = value
    }
}
