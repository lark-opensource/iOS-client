//
//  NormalChatInputKeyboard.swift
//  Lark
//
//  Created by lichen on 2017/7/25.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//
import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkUIKit
import EENavigator
import Photos
import LarkModel
import LarkCore
import LarkRichTextCore
import LarkBaseKeyboard
import LKCommonsLogging
import EditTextView
import UniverseDesignToast
import LarkAudio
import LarkAlertController
import LarkFeatureGating
import LarkKAFeatureSwitch
import LarkSDKInterface
import LarkMessengerInterface
import LarkMessageCore
import LarkMessageBase
import LarkContainer
import LarkCanvas
import LarkEmotion
import RustPB
import LarkEmotionKeyboard
import ByteWebImage
import TangramService
import LarkFocus
import LarkOpenChat
import LKCommonsTracker
import UniverseDesignDialog
import LarkAttachmentUploader
import LarkSendMessage
import LarkKeyboardView
import LarkChatOpenKeyboard
import LarkChatKeyboardInterface

public struct RichTextInfoItem {
    let richTextStr: String?
    let userActualNameInfoDic: [String: String]
}

public struct PostServiceItem {
     let attachmentServer: PostAttachmentServer?
     let translateService: RealTimeTranslateService
}

public protocol ChatInputKeyboardDelegate: ChatOpenKeyboardDelegate {
    var chatFromWhere: ChatFromWhere { get }
    func setEditingMessage(message: Message?)
    func setScheduleTipViewStatus(_ status: ScheduleMessageStatus)
    func getScheduleMsgSendTime() -> Int64?
    func getSendScheduleMsgIds() -> ([String], [String])
    func clickChatMenuEntry()
    func replaceViewWillChange(_ view: UIView?)
    func keyboardCanAutoBecomeFirstResponder() -> Bool
    func jobDidChange(old: KeyboardJob?, new: KeyboardJob)
    func onExitReply()
}

public protocol NormalChatKeyboardRouter: AnyObject {

    var rootVCBlock: (() -> UIViewController?)? { get set }

    func showImagePicker(
        showOriginButton: Bool,
        selectedBlock: ((ImagePickerViewController, _ assets: [PHAsset], _ isOriginalImage: Bool) -> Void)?
    )

    func showStickerSetting()

    func showStickerSetSetting()

    // swiftlint:disable function_parameter_count
    func showComposePostView(
        chat: Chat,
        dataService: KeyboardShareDataService,
        richTextInfoItem: RichTextInfoItem?,
        placeholder: NSAttributedString?,
        reeditContent: RichTextContent?,
        postItem: ComposePostItem?,
        postServiceItem: PostServiceItem,
        supportRealTimeTranslate: Bool,
        pasteBoardToken: String,
        callbacks: ShowComposePostViewCallBacks,
        chatFromWhere: ChatFromWhere)
    // swiftlint:enable function_parameter_count
}
/**
 如果你修改键盘的时候
 1.不想影响到密聊，
 2.不清楚当前键盘的类的作用
 不妨简单看下这个文档 https://bytedance.feishu.cn/docx/Pq9adSIIKodUNSxvJqncrG6UnNq
 */

public final class NormalChatInputKeyboard: ChatBaseInputKeyboard {

    @ScopedInjectedLazy var router: NormalChatKeyboardRouter?
    @ScopedInjectedLazy private var modelService: ModelService?
    @ScopedInjectedLazy private var userGeneralSettings: UserGeneralSettings?
    @ScopedInjectedLazy private var messageBurntService: MessageBurnService?

    /// NormalChatInputKeyboard+keyboard 用到
    lazy var quasiMsgCreateByNative: Bool = {
        return self.viewModel.chatModel.anonymousId.isEmpty && !self.viewModel.chatModel.isP2PAi
    }()

    override var audioKeyboardHelper: AudioRecordPanelProtocol? {
        let module: IMChatKeyboardVoicePanelSubModule? = self.getPanelSubModuleForItemKey(key: .voice)
        return module?.audioKeyboardHelper
    }

    /// 输入框保存草稿的时机
    override var debounceDuration: TimeInterval { return 3 }

    /// 这里一定是可以转成功的 放心使用
    var chatInputViewModel: ChatInputViewModel? {
        return viewModel as? ChatInputViewModel
    }

    var chatKeyboardView: NormalChatKeyboardView? {
        return keyboardView as? NormalChatKeyboardView
    }

    /// 输入框是否是展开状态
    var expandInputView: Bool = false
    //发资源类消息管理类
    lazy var assetManager: AssetPreProcessManager = {
        return AssetPreProcessManager(userResolver: userResolver, isCrypto: false)
    }()
    var scheduleTime: Int64? {
        self.viewModel.scheduleTime
    }
    var scheduleDate: Date? {
        self.viewModel.scheduleDate
    }

    /// 翻译数据管理
    lazy var translateDataService: RealTimeTranslateService = {
        return RealTimeTranslateDataManager(targetLanguage: self.viewModel.chatModel.typingTranslateSetting.targetLanguage,
                                            userResolver: self.viewModel.userResolver)
    }()

    //最后一次点击”使用“时，获得的翻译内容
    var lastTranslationData: (title: String?, content: RustPB.Basic_V1_RichText?)?
    var scheduleSendDraftChangeBehavior = BehaviorRelay<ScheduleSendDraftModel>(value: ScheduleSendDraftModel())

    var keyboardCanAutoBecomeFirstResponder: Bool {
        return self.delegate?.keyboardCanAutoBecomeFirstResponder() ?? true
    }

    var fontPanelSubModule: IMChatKeyboardFontPanelSubModule? {
        let module = self.keyboardView.module.getPanelSubModuleInstanceForModuleClass(IMChatKeyboardFontPanelSubModule.self) as? IMChatKeyboardFontPanelSubModule
        return module
    }

    init(viewModel: ChatInputViewModel,
         module: BaseChatKeyboardModule,
         delegate: ChatInputKeyboardDelegate?,
         keyboardView: NormalChatKeyboardView) {
         super.init(viewModel: viewModel,
                   module: module,
                   delegate: delegate,
                   keyboardView: keyboardView)
        // 初始化 router vc
        if let router = self.router {
            router.rootVCBlock = { [weak self] in
                return self?.delegate?.baseViewController()
            }
        }
        updateConfigForTranslate(open: self.viewModel.chatModel.typingTranslateSetting.isOpen)
        self.viewModel.chatTypingTranslateEnableChanged = { [weak self] () in
            guard let `self` = self else { return }
            self.updateConfigForTranslate(open: self.viewModel.chatModel.typingTranslateSetting.isOpen)
            self.updateInputPlaceHolder()
        }
        self.viewModel.chatTypingTranslateLanguageChanged = { [weak self] () in
            guard let `self` = self,
                  !self.viewModel.chatModel.typingTranslateSetting.targetLanguage.isEmpty else { return }
            self.updateTargetLanguage(self.viewModel.chatModel.typingTranslateSetting.targetLanguage)
            self.keyboardView.translationInfoPreviewView.updateLanguage(self.viewModel.chatModel.typingTranslateSetting.targetLanguage)
        }

        self.chatKeyboardView?.titleTextView?.rx.value.asDriver()
            .drive(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.updateTranslateSessionIfNeed()
        }).disposed(by: self.disposeBag)

        self.viewModel.chatWrapper.chat
            .distinctUntilChanged { (chat1, chat2) -> Bool in
                return chat1.enableMessageBurn == chat2.enableMessageBurn
            }
            .asDriver(onErrorJustReturn: self.viewModel.chatWrapper.chat.value)
            .drive(onNext: { [weak self] (chat) in
                Self.logger.info("chat restrictedModeSetting onTimeDelMsgSetting aliveTime \(chat.id) \(chat.enableMessageBurn)")
                self?.updateInputPlaceHolder()
            }).disposed(by: disposeBag)
        self.actionAfterKeyboardInitDraftFinish { [weak self] in
            self?.keyboardView.autoAddAnchorForLinkText()
        }
    }

    private func getMorePanelSubModule() -> IMChatKeyboardMorePanelSubModule? {
        let subModule = self.keyboardView.module.getPanelSubModuleInstanceForModuleClass(IMChatKeyboardMorePanelSubModule.self)
        return subModule as? IMChatKeyboardMorePanelSubModule
    }

    private func getEmojiPanelSubModule() -> IMChatKeyboardEmojiPanelSubModule? {
        let subModule = self.keyboardView.module.getPanelSubModuleInstanceForModuleClass(IMChatKeyboardEmojiPanelSubModule.self)
        return subModule as? IMChatKeyboardEmojiPanelSubModule
    }

    override func keyboardItems(moreItemsDriver: Driver<[ChatKeyboardMoreItem]>) -> [InputKeyboardItem] {
        var isSpecialStatus = false
        var isQuickAction = false
        switch self.keyboardView.keyboardStatusManager.currentKeyboardJob {
        case .multiEdit, .scheduleSend, .scheduleMsgEdit:
            isSpecialStatus = true
        case .quickAction:
            // “快捷指令”编辑状态下，隐藏所有的功能按钮，除了 at，at 按钮需要保留
            isQuickAction = true
        default:
           break
        }
        getEmojiPanelSubModule()?.supportLeftViewInfo = !isSpecialStatus
        getMorePanelSubModule()?.itemDriver = moreItemsDriver
        keyboardView.viewModel.module.reloadPanelItems()
        var items = keyboardView.viewModel.panelItems
        if isSpecialStatus {
            let supportItemKeys = [KeyboardItemKey.font.rawValue,
                                   KeyboardItemKey.at.rawValue,
                                   KeyboardItemKey.emotion.rawValue]
            items = items.flatMap({ item in
                supportItemKeys.contains(item.key) ? item : nil
            })
        } else if isQuickAction {
            let supportItemKeys = [KeyboardItemKey.at.rawValue]
            items = items.flatMap({ item in
                supportItemKeys.contains(item.key) ? item : nil
            })
        }
        return items
    }

    /// 触发原因：相同消息或者chat的草稿发生变更
    /// 出发场景：1.回复某个消息的时候，点击进入消息的详情页 2.ipad的分屏后 同一个chat
    override func updateInputViewWith(draftInfo: DraftInfo) {
        let isFirstReponse = keyboardView.inputTextView.isFirstResponder || (keyboardView.titleTextView?.isFirstResponder ?? false)
        /// 不是第一响应者
        if draftInfo.type == .post,
           !isFirstReponse,
           !expandInputView {
            updateDraftContent(by: draftInfo.content)
        }
    }

    override func scheduleSendDraftChange(draftInfo: DraftInfo) {
        let info = ScheduleSendDraftModel(isVaild: !draftInfo.isDelete,
                                          draftContent: draftInfo.content,
                                          scheduleTime: draftInfo.scheduleTime,
                                          messageId: draftInfo.messageId)
        scheduleSendDraftChangeBehavior.accept(info)
    }

    override func setupStartupKeyboardState() {
        guard let keyboardStartupState = self.delegate?.getKeyboardStartupState() else {
            assertionFailure()
            Self.logger.error("取不到 keyboard state")
            return
        }

        guard self.viewModel.chatModel.isAllowPost else {
            Self.logger.error("can not set setupStartupKeyboardState for chatId: \(self.viewModel.chatModel.id) isAllowPost = false")
            return
        }

        switch keyboardStartupState.type {
        case .none:
            break
        case .inputView:
            // 如果存在文字则聚焦输入框
            if self.keyboardView.attributedString.length > 0, self.keyboardCanAutoBecomeFirstResponder {
                self.keyboardView.inputViewBecomeFirstResponder()
            }
        case .stickerSet:
            self.keyboardView.keyboardPanel.select(key: KeyboardItemKey.emotion.rawValue)
            if let contentView = self.keyboardView.keyboardPanel.content as? EmotionKeyboardView,
                let index = contentView.dataSources.firstIndex(where: { (item) -> Bool in
                    return item.identifier == "stickerSet-\(keyboardStartupState.info)"
                }) {
                contentView.setSelectIndex(index: index, animation: false)
            }
        @unknown default:
            assertionFailure("error KeyboardState")
        }
    }

    public override func reEditMessage(message: Message) {
        let supportType: [Message.TypeEnum] = [.post, .text]
        guard supportType.contains(message.type) else {
            return
        }
        Self.logger.info("reedit message type \(message.type)")

        if let parentMessage = message.parentMessage {
            let info = KeyboardJob.ReplyInfo(message: parentMessage, partialReplyInfo: message.partialReplyInfo)
            keyboardView.keyboardStatusManager.switchJob(.reply(info: info))
        }
        switch message.type {
        case .text:
            self.setupTextMessage(message: message)
        case .post:
            self.setupPostMessage(message: message) { [weak self] attr in
                guard let self = self else { return attr }
                var targetAttr = attr
                if !AttributedStringAttachmentAnalyzer.canPasteAttrForTextView(self.keyboardView.inputTextView, attr: attr) {
                    targetAttr = AttributedStringAttachmentAnalyzer.deleVideoAttachmentForAttr(attr)
                    self.keyboardView.showVideoLimitError()
                }
                CopyToPasteboardManager.addRemoteResourcesCopyTagFor(targetAttr)
                return targetAttr
            } callback: { [weak self] in
                /// 撤回编辑中支持展示图片，所以需要更下图片的尺寸
                self?.updateAttachmentSizeFor(attributedText: self?.keyboardView.attributedString ?? NSAttributedString())
            }

        @unknown default:
            break
        }
    }

    override func insertRichText(richText: RustPB.Basic_V1_RichText) {
        self.setupRichText(richText: richText) { [weak self] attr in
            guard let self = self else { return attr }
            var targetAttr = attr
            if !AttributedStringAttachmentAnalyzer.canPasteAttrForTextView(self.keyboardView.inputTextView, attr: attr) {
                targetAttr = AttributedStringAttachmentAnalyzer.deleVideoAttachmentForAttr(attr)
                self.keyboardView.showVideoLimitError()
            }
            CopyToPasteboardManager.addRemoteResourcesCopyTagFor(targetAttr)
            return targetAttr
        } callback: { [weak self] in
            /// 所以需要更下图片的尺寸
            self?.updateAttachmentSizeFor(attributedText: self?.keyboardView.attributedString ?? NSAttributedString())
        }
    }

    override func updateAttributedString(message: Message,
                                isInsert: Bool,
                                callback: (() -> Void)?) {
        switch message.type {
        case .text:
            self.setupTextMessage(message: message, isInsert: isInsert, callback: callback)
        case .post:
            self.setupPostMessage(message: message, isInsert: isInsert, callback: callback)
        @unknown default:
            break
        }
    }

    func setupPostMessage(message: Message,
                          isInsert: Bool = true,
                          beforeApplyCallBack: ((NSAttributedString) -> NSAttributedString)? = nil,
                          callback: (() -> Void)? = nil) {
        guard let content = message.content as? PostContent else {
            return
        }
        let richText = TextDocsViewModel(userResolver: userResolver, richText: content.richText, docEntity: content.docEntity, hangPoint: message.urlPreviewHangPointMap).richText
        let attributes = self.keyboardView.inputTextView.defaultTypingAttributes
        let processProvider = MessageInlineViewModel.urlInlineProcessProvider(message: message, attributes: attributes)
        keyboardView.titleTextView?.insert(NSAttributedString(string: content.title))
        setupRichText(richText: richText,
                      processProvider: processProvider,
                      isInsert: isInsert,
                      beforeApplyCallBack: beforeApplyCallBack,
                      callback: callback)
    }

    func setupRichText(richText: RustPB.Basic_V1_RichText,
                       processProvider: ElementProcessProvider = [:],
                       isInsert: Bool = true,
                       beforeApplyCallBack: ((NSAttributedString) -> NSAttributedString)? = nil,
                       callback: (() -> Void)? = nil) {
        var contentText = RichTextTransformKit.transformRichTextToStr(
            richText: richText,
            attributes: keyboardView.inputTextView.baseDefaultTypingAttributes,
            attachmentResult: [:],
            processProvider: processProvider)
        if let beforeApplyCallBack = beforeApplyCallBack {
            contentText = beforeApplyCallBack(contentText)
        }
        updateAttributedStringAtInfo(contentText) { [weak self] in
            guard let self = self else { return }
            if isInsert {
                self.chatKeyboardView?.inputTextView.insert(contentText, useDefaultAttributes: false)
            } else {
                self.chatKeyboardView?.inputTextView.replace(contentText, useDefaultAttributes: false)
            }
            self.fontPanelSubModule?.updateInputTextViewStyle()
            callback?()
        }
    }

    fileprivate func showComposeVC(richTextInfoItem: RichTextInfoItem?,
                                   replyMessage: Message?,
                                   reeditContent: RichTextContent?,
                                   postItem: ComposePostItem?) {
        self.keyboardView.fold()
        self.expandInputView = true
        /// 新版 & 旧版输入框单聊需要将状态携带过去
        var inputPlaceHolder: NSAttributedString?
        let textTranslateService: RealTimeTranslateService
        inputPlaceHolder = keyboardView.inputTextView.attributedPlaceholder
        textTranslateService = self.translateDataService
        let postServiceItem = PostServiceItem(attachmentServer: viewModel.getCurrentAttachmentServer(),
                                              translateService: textTranslateService)
        var callbacks = ShowComposePostViewCallBacks()
        callbacks.completeCallback = { [weak self] content, scheduleTime in
            self?.onComposePostViewDismiss()
            self?.onComposePostViewComplete(content, replyMessage: replyMessage, scheduleTime: scheduleTime)
            self?.onInputFinished()
        }
        callbacks.cancelCallback = { [weak self] (item) in
            self?.onComposePostViewDismiss()
            // 从 ComposePost 退出来之后，需要刷新画板 button 的状态（红点可能会变化）
            self?.keyboardView.keyboardPanel.reloadPanelBtn(key: KeyboardItemKey.canvas.rawValue)
            self?.updateKeyboardStatusIfNeed(item)
        }
        callbacks.applyTranslationCallback = { [weak self] (title: String?, content: Basic_V1_RichText?) in
            self?.lastTranslationData = (title, content)
        }
        callbacks.recallTranslationCallback = { [weak self] in
            self?.lastTranslationData = nil
        }
        callbacks.multiEditFinishCallback = { [weak self] in
            self?.onComposePostViewDismiss()
            self?.onInputFinished()
        }
        callbacks.patchScheduleMsgFinishCallback = { [weak self] in
            self?.onComposePostViewDismiss()
            self?.onInputFinished()
        }

        callbacks.setScheduleTipStatus = { [weak self] status in
            self?.delegate?.setScheduleTipViewStatus(status)
        }
        callbacks.getScheduleMsgSendTime = { [weak self] in
            return self?.delegate?.getScheduleMsgSendTime()
        }
        callbacks.getSendScheduleMsgIds = { [weak self] in
            return self?.delegate?.getSendScheduleMsgIds() ?? ([], [])
        }
        self.router?.showComposePostView(
            chat: self.viewModel.chatWrapper.chat.value,
            dataService: keyboardView.keyboardShareDataService,
            richTextInfoItem: richTextInfoItem,
            placeholder: inputPlaceHolder,
            reeditContent: reeditContent,
            postItem: postItem,
            postServiceItem: postServiceItem,
            supportRealTimeTranslate: self.keyboardView.supportRealTimeTranslate,
            pasteBoardToken: self.keyboardView.pasteboardToken,
            callbacks: callbacks,
            chatFromWhere: self.delegate?.chatFromWhere ?? ChatFromWhere.default()
        )
    }

    func onComposePostViewComplete(_ content: RichTextContent,
                                   replyMessage: Message?,
                                   scheduleTime: Int64?) {
        /// post消息 新版添加richTextVersion = 1
        var richTextContent = content
        richTextContent.richText.richTextVersion = 1
        if self.isTextContent(richTextContent) {
            self.keyboardView.fold()
            self.doSendTextMessageWith(richText: content.richText,
                                       lingoInfo: content.lingoInfo,
                                       parentMessage: replyMessage,
                                       scheduleTime: scheduleTime,
                                       isFullScreen: true)
            self.keyboardView.keyboardStatusManager.switchToDefaultJob()
        } else {
            self.sendPostMessageViewOnPostViewComplete(content, replyMessage: replyMessage, scheduleTime: scheduleTime)
        }
        if let replyMessage = replyMessage {
            chatInputViewModel?.draftCache?.saveDraft(messageId: replyMessage.id, type: .post, content: "", callback: nil)
        }
    }

    /// 是否是文本类型消息发送
    private func isTextContent(_ content: RichTextContent) -> Bool {
        if content.richText.imageIds.isEmpty,
           content.richText.mediaIds.isEmpty,
           content.title.isEmpty,
           !CodeInputHandler.richTextContainsCode(richText: content.richText) {
            return true
        }
        return false
    }

    //不管以什么原因关闭大框时都调用（包括用户手动关闭大框、在大框发消息、二次编辑保存、定时发送等）
    func onComposePostViewDismiss() {
        expandInputView = false
        keyboardView.resetKeyboardStatusDelagate()
        translateDataServiceBindTextView()
    }

    public override func sendInputContentAsMessage() {
        switch keyboardView.keyboardStatusManager.currentKeyboardJob {
        case .multiEdit(let message):
            confirmMultiEditMessage(message, triggerMethod: .hotkey_action)
        default:
            super.sendInputContentAsMessage()
        }
    }

    /// 更新输入框的数据 这里不做兼容处理 直接读取Post的数据
    override func updateDraftContent(by draftStr: String) {
        if draftStr.isEmpty {
            keyboardView.attributedString = NSAttributedString(string: "",
                                                               attributes: keyboardView.inputTextView.defaultTypingAttributes)
            return
        }
        let draft = PostDraftModel.parse(draftStr)
        /// 刚开始进入 postDraft应该为空
        self.postDraft = draft
        updateAttachmentInfo()
    }

    func sendPostMessageViewOnPostViewComplete(_ content: RichTextContent, replyMessage: Message?, scheduleTime: Int64?) {
        self.keyboardView.fold()
        self.viewModel.messageSender?.sendPost(title: content.title,
                                              content: content.richText,
                                              lingoInfo: content.lingoInfo,
                                              parentMessage: replyMessage,
                                              chatId: self.viewModel.chatModel.id,
                                              scheduleTime: scheduleTime) { [weak self] state in
            guard let self = self else { return }
            if case .finishSendMessage(let message, _, _, _, _) = state {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.translateDataService.clearOriginAndTranslationData()
                    self.keyboardView.translationInfoPreviewView.recallEnable = self.translateDataService.getRecallEnable()
                }
                self.trackerInputMsgSend(message: message, isFullScreen: true, useSendBtn: true,
                                         title: content.title, richText: content.richText)
            }
        }
        self.keyboardView.keyboardStatusManager.switchToDefaultJob()
    }

    func updateKeyboardStatusIfNeed(_ item: ComposePostItem?) {
        let info = translateDataService.getCurrentTranslateOriginData()
        let recallEnable = translateDataService.getRecallEnable()
        if let item = item {
            self.keyboardView.updateTextViewData(item, translateInfo: info,
                                                 recallEnable: recallEnable,
                                                 keyboardCanBecomeFirstResponder: self.keyboardCanAutoBecomeFirstResponder)
        } else if self.keyboardCanAutoBecomeFirstResponder {
            self.keyboardView.becomeFirstResponder()
        }
        updateAttachmentUploaderDefaultCallBack()
    }

    func trackerInputMsgSend(message: Message, isFullScreen: Bool, useSendBtn: Bool,
                             title: String?, richText: RustPB.Basic_V1_RichText) {
        var translateStatus: IMTracker.Chat.Main.Click.TranslateStatus = .none
        if let lastTranslationData = self.lastTranslationData {
            if (title == nil || lastTranslationData.title == title),
               RichTextTransformKit.transformRichTexToText(lastTranslationData.content) == RichTextTransformKit.transformRichTexToText(richText) {
                translateStatus = .all
            } else {
                translateStatus = .part
            }
        }
        IMTracker.Chat.Main.Click.InputMsgSend(viewModel.chatModel,
                                               message: message,
                                               isFullScreen: isFullScreen,
                                               useSendBtn: useSendBtn,
                                               translateStatus: translateStatus,
                                               nil,
                                               self.delegate?.chatFromWhere)
        self.lastTranslationData = nil
        // 监控 MyAI Query 的发送事件
        self.trackQuerySendingEventIfNeeded(richText)
    }

    // MARK: - ChatKeyboardOpenService Override
    public override func sendFile(path: String,
                                  name: String,
                                  parentMessage: Message?) {
        self.viewModel.messageSender?.sendFile(
            path: path,
            name: name,
            parentMessage: parentMessage,
            removeOriginalFileAfterFinish: false,
            chatId: self.viewModel.chatModel.id,
            lastMessagePosition: self.viewModel.chatModel.lastMessagePosition,
            quasiMsgCreateByNative: self.quasiMsgCreateByNative,
            preprocessResourceKey: self.assetManager.getPreprocessResourceKey(assetName: path)
        )
    }

    public override func sendText(content: RustPB.Basic_V1_RichText, lingoInfo: RustPB.Basic_V1_LingoOption?, parentMessage: Message?) {
        self.viewModel.messageSender?.sendText(
            content: content,
            lingoInfo: lingoInfo,
            parentMessage: parentMessage,
            chatId: self.viewModel.chatModel.id,
            position: self.viewModel.chatModel.lastMessagePosition,
            quasiMsgCreateByNative: self.quasiMsgCreateByNative,
            callback: nil
        )
    }

    // MARK: - ChatKeyboardDelegate Override
    /**
     由于端上将消息都升级为Post之后，一些机器人只能识别Text类型的消息，所以会出现机器人无法使用的情况
     由于无法确认开发者怎么使用这些消息，所以由端上做兼容方案,仍发送Text的消息
     如果没有图片与标题，则发送Text类型的消息
     */
    public override func inputTextViewSend(attributedText: NSAttributedString,
                                           scheduleTime: Int64?) {
        guard let vm = chatInputViewModel, let attachmentManager = vm.attachmentManager,
              !attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        if attachmentManager.checkAttachmentAllUploadSuccessFor(attruibuteStr: attributedText) {
            sendMessageWith(contentAttributedText: attributedText, scheduleTime: scheduleTime)
            return
        }
        if let view = self.delegate?.baseViewController().view {
            let hud = UDToast.showLoading(with: BundleI18n.LarkChat.Lark_Legacy_ComposePostUploadPhoto, on: view, disableUserInteraction: true)
            attachmentManager.retryUploadAttachment(textView: keyboardView.inputTextView,
                                                       start: nil) { [weak self] success in
                hud.remove()
                if success {
                    self?.sendMessageWith(contentAttributedText: attributedText, scheduleTime: scheduleTime)
                }
            }
        }
    }

    public override func clickExpandButton() {
        var postItem: ComposePostItem?
        var defaultContent: String?
        let fontBarStatus: FontToolBarStatusItem
        // try to replace status by bar
        if let status = fontPanelSubModule?.getFontBarStatusItem() {
            fontBarStatus = status
        } else {
            // get defaultTypingAttributes from inputManager
            fontBarStatus = self.chatKeyboardView?.inputManager.getInputViewFontStatus() ?? FontToolBarStatusItem()
        }
        postItem = ComposePostItem(fontBarStatus: fontBarStatus,
                                   firstResponderInfo: getCurrentFirstResponderInfo())
        IMTracker.Chat.Main.Click.FullScreen(viewModel.chatModel, self.delegate?.chatFromWhere, open: true)

        var replyMessage: Message?
        if let message = self.viewModel.replyMessage {
            replyMessage = message
        } else if let rootMessage = self.viewModel.rootMessage {
            replyMessage = rootMessage
        }
        let userActualNameInfoDic = AtTransformer.getAllChatterActualNameMapForAttributedString(keyboardView.inputTextView.attributedText)
        let richTextInfoItem = RichTextInfoItem(richTextStr: defaultContent,
                                                userActualNameInfoDic: userActualNameInfoDic)
        self.showComposeVC(richTextInfoItem: richTextInfoItem,
                           replyMessage: replyMessage,
                           reeditContent: nil,
                           postItem: postItem)
        self.keyboardWillExpand()
    }

    public override func supportFontStyle() -> Bool {
        return true
    }

    /// 开启或者关闭翻译
    func updateConfigForTranslate(open: Bool) {
        if open {
            self.translateDataServiceBindTextView()
            self.keyboardView.translationInfoPreviewView.setDisplayable(true)
            /// 绑定之后 需要刷新一下翻译的内容
            self.translateDataService.refreshTranslateContent()
        } else {
            self.translateDataService.unbindToTranslateData()
            self.keyboardView.translationInfoPreviewView.setDisplayable(false)
        }
    }

    func translateDataServiceBindTextView() {
        guard self.viewModel.chatModel.typingTranslateSetting.isOpen else { return }
        let data = RealTimeTranslateData(chatID: self.viewModel.chatModel.id,
                                         titleTextView: self.keyboardView.titleTextView,
                                         contentTextView: self.keyboardView.inputTextView,
                                         delegate: self.keyboardView)
        self.translateDataService.bindToTranslateData(data)
        self.keyboardView.translationInfoPreviewView.disableLoadingTemporary()
    }

    private func keyboardWillExpand() {
        self.audioKeyboardHelper?.cleanAudioRecognizeState()
        self.delegate?.keyboardWillExpand()
        LarkMessageCoreTracker.trackClickKeyboardInputItem(KeyboardItemKey.compose)
        IMTracker.Chat.Main.Click.Post(self.viewModel.chatModel, self.delegate?.chatFromWhere)
    }
    /// 保存草稿
    override func saveInputViewDraft(isExitChat: Bool = false, callback: DraftCallback? = nil) {
        guard let vm = chatInputViewModel, let attachmentManager = vm.attachmentManager,
              let attrText = keyboardView.keyboardStatusManager.delegate?.getKeyboardAttributedText(),
              let draft = self.draft else {
            return
        }
        vm.saveInputViewDraft(draft: draft,
                              attachmentKeys: attachmentManager.attachmentIdsForAttruibuteStr(attrText),
                              async: true,
                              isExitChat: isExitChat,
                              callback: callback)
    }

    public override func inputTextViewDidChange(input: LKKeyboardView) {
        getEmojiPanelSubModule()?.emotionKeyboard?.updateActionBarEnable()
        fontPanelSubModule?.onTextViewLengthChange(input.inputTextView.attributedText.length)
        self.updateTranslateSessionIfNeed()
    }

    private func updateTranslateSessionIfNeed() {
        guard userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "im.chat.manual_open_translate")) else { return }
        if self.viewModel.chatModel.typingTranslateSetting.isOpen,
           self.chatKeyboardView?.titleTextView?.attributedText.string.isEmpty ?? true,
           self.keyboardView.inputTextView.attributedText.string.isEmpty {
            self.translateDataService.updateSessionID()
        }
    }

    private func getCurrentFirstResponderInfo() -> (NSRange, Bool)? {
        var firstResponderInfo: (NSRange, Bool)?
        if keyboardView.inputTextView.isFirstResponder || keyboardView.titleTextView?.isFirstResponder ?? false {
            let range = keyboardView.inputTextView.selectedRange
            if range.length > 0 {
                keyboardView.inputTextView.selectedRange = NSRange(location: range.location, length: 0)
            }
            firstResponderInfo = (keyboardView.inputTextView.isFirstResponder ?
                                    keyboardView.inputTextView.selectedRange : keyboardView.titleTextView?.selectedRange ?? NSRange(location: 0, length: 0),
                                  keyboardView.inputTextView.isFirstResponder)
            return firstResponderInfo
        }
        // 当小输入框的正文和标题都不是第一响应时
        // 获取优先取正文的位置，是不是在文末。如果不在文末则使用正文位置
        if keyboardView.inputTextView.selectedRange.location != keyboardView.inputTextView.attributedText.length {
            let range = keyboardView.inputTextView.selectedRange
            if range.length > 0 {
                keyboardView.inputTextView.selectedRange = NSRange(location: range.location, length: 0)
            }
            firstResponderInfo = (keyboardView.inputTextView.selectedRange, true)
            return firstResponderInfo
        }
        return firstResponderInfo
    }

    public override func getReplyTo(info: KeyboardJob.ReplyInfo, user: Chatter, result: @escaping (NSMutableAttributedString) -> Void) {
        let displayName = self.getDisplayName(chatter: user)
        let attr = MessageReplyGenerator.attributeReplyForInfo(info,
                                                               font: UIFont.ud.body2,
                                                               displayName: displayName,
                                                               chat: self.viewModel.chatModel,
                                                               userResolver: self.userResolver,
                                                               abTestService: self.abTestService,
                                                               modelService: self.modelService,
                                                               messageBurntService: self.messageBurntService)
        result(attr)
    }

    public override func getTranslationResult() -> (String?, RustPB.Basic_V1_RichText?) {
        return translateDataService.getCurrentTranslateOriginData()
    }

    public override func getOriginContentBeforeTranslate() -> (String?, NSAttributedString?) {
        return translateDataService.getLastOriginData()
    }

    public override func clearTranslationData() {
        translateDataService.clearTranslationData()
    }

    public override func updateTargetLanguage(_ languageKey: String) {
        translateDataService.updateTargetLanguage(languageKey)
    }

    public override func applyTranslationCallBack(title: String?, content: RustPB.Basic_V1_RichText?) {
        self.lastTranslationData = (title: title, content: content)
        setupAttachment(needToClearTranslationData: true)
    }

    public override func recallTranslationCallBack() {
        self.translateDataService.refreshTranslateContent()
        self.lastTranslationData = nil
    }

    public override func presentLanguagePicker(currentLanguage: String) {
        guard let vc = self.delegate?.baseViewController() else { return }
        var body = LanguagePickerBody(chatId: self.viewModel.chatModel.id, currentTargetLanguage: currentLanguage, chatFromWhere: self.delegate?.chatFromWhere ?? ChatFromWhere.default())
        body.targetLanguageChangeCallBack = { [weak self] (chat) in
            self?.keyboardView.translationInfoPreviewView.updateLanguage(chat.typingTranslateSetting.targetLanguage)
            self?.updateTargetLanguage(chat.typingTranslateSetting.targetLanguage)
        }
        body.closeRealTimeTranslateCallBack = { [weak self] _ in
            self?.keyboardView.translationInfoPreviewView.setDisplayable(false)
        }
        navigator.present(body: body, from: vc)
    }

    public override func previewTranslation(applyButtonCallBack: @escaping (() -> Void)) {
        guard let vc = self.delegate?.baseViewController() else { return }
        let detail = getTranslationResult()
        if detail.0?.isEmpty ?? true,
           detail.1 == nil {
            return
        }
        let imageAttachments: [String: (CustomTextAttachment, ImageTransformInfo, NSRange)] =
        ImageTransformer.fetchImageAttachemntMapInfo(attributedText: self.keyboardView.inputTextView.attributedText)
        let videoAttachments: [String: (CustomTextAttachment, VideoTransformInfo, NSRange)] =
        VideoTransformer.fetchVideoAttachemntMapInfo(attributedText: self.keyboardView.inputTextView.attributedText)
        let body = ChatTranslationDetailBody(chat: nil, title: detail.0, content: detail.1,
                                             attributes: self.keyboardView.inputTextView.baseDefaultTypingAttributes,
                                             imageAttachments: imageAttachments,
                                             videoAttachments: videoAttachments) {
            applyButtonCallBack()
        }
        navigator.present(body: body,
                                 wrap: LkNavigationController.self,
                                 from: vc,
                                 prepare: { $0.modalPresentationStyle = .fullScreen },
                                 animated: true)
    }

    override public func pushProfile(chatterId: String) {
        guard let from = self.delegate?.baseViewController() else { return }
        let body = PersonCardBody(chatterId: chatterId)
        navigator.presentOrPush(
            body: body,
            wrap: LkNavigationController.self,
            from: from,
            prepareForPresent: { vc in
                vc.modalPresentationStyle = .formSheet
            })
    }

    override func onKeyboardJobChanged(oldJob: KeyboardJob?, currentJob: KeyboardJob) {
        super.onKeyboardJobChanged(oldJob: oldJob, currentJob: currentJob)
        chatInputViewModel?.updateAttachmentUploaderIfNeed()
        self.updateInputPlaceHolder()
        self.audioKeyboardHelper?.cleanAudioRecognizeState()
        func resetKeyTypeIfNeeded(_ newType: UIReturnKeyType) {
            if self.keyboardView.inputTextView.returnKeyType != newType {
                self.keyboardView.inputTextView.returnKeyType = newType
                self.keyboardView.inputTextView.reloadInputViews()
            }
        }
        switch currentJob {
        case .scheduleSend, .scheduleMsgEdit, .multiEdit, .quickAction:
            // 修改发送为换行
            let newType: UIReturnKeyType = .default
            resetKeyTypeIfNeeded(newType)
            getEmojiPanelSubModule()?.emotionKeyboard?.updateSendBtnIfNeed(hidden: true)
        default:
            let newType: UIReturnKeyType = keyboardNewStyleEnable ? .default : .send
            resetKeyTypeIfNeeded(newType)
            if case .reply = oldJob {
                self.delegate?.onExitReply()
            }
            getEmojiPanelSubModule()?.emotionKeyboard?.updateSendBtnIfNeed(hidden: false)
        }
        var editingMessage: Message?
        if case .multiEdit(let message) = currentJob {
            editingMessage = message
        }
        self.delegate?.setEditingMessage(message: editingMessage)
        self.delegate?.jobDidChange(old: oldJob, new: currentJob)
    }

    // 点击 x 号
    override public func onMessengerKeyboardPanelSchuduleExitButtonTap() {
        guard let from = self.delegate?.baseViewController(), let vm = viewModel as? ChatInputViewModel else {
            assertionFailure()
            return
        }
        self.keyboardView.inputTextView.resignFirstResponder()
        vm.scheduleSendService?.showAlertWhenSchuduleExitButtonTap(from: from,
                                                                  chatID: Int64(vm.chatModel.id) ?? 0,
                                                                  closeTask: { [weak self] in
            // 恢复输入框状态
            if case .scheduleSend = vm.keyboardStatusManagerBlock?()?.lastKeyboardJob {
                self?.keyboardView.switchToDefaultJob()
            } else {
                self?.keyboardView.goBackToLastStatus()
            }
            // 删除草稿
            vm.draftCache?.deleteScheduleDraft(key: self?.getScheduleDraftId() ?? "", messageId: vm.rootMessage?.id, chatId: vm.chatModel.id ?? "")
        },
                                                                  continueTask: { [weak self] in
            self?.keyboardView.inputTextView.becomeFirstResponder()
        })
    }

    override public func scheduleTipDidShow(date: Date) {
        guard let vm = viewModel as? ChatInputViewModel else {
            return
        }
        // 初始化当前的时间
        let formatDate = ScheduleSendManager.formatSendScheduleDate(date)
        // 初始化当前的时间
        self.viewModel.scheduleDate = formatDate
    }

    public func updateTip(_ tip: KeyboardTipsType) {
        self.keyboardView.keyboardStatusManager.addTip(tip)
    }

    // 键盘定时发送按钮 点击
    override public func onMessengerKeyboardPanelSchuduleSendButtonTap() {
        self.keyboardView.imKeyboardDelegate?.inputTextViewWillSend()
        let attributedText = keyboardView.getTrimTailSpacesAttributedString()

        guard let from = self.delegate?.baseViewController(), let vm = viewModel as? ChatInputViewModel else {
            assertionFailure()
            return
        }
        getHasScheduleMsg()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak from] hasScheduleMsg in
                guard let `self` = self, let from = from else { return }
                guard !hasScheduleMsg else {
                    UDToast.showTips(with: BundleI18n.LarkChat.Lark_IM_ScheduleMessage_CanSendOnly1ScheduledMessage_Tooltip, on: from.view)
                    self.keyboardView.keyboardStatusManager.goBackToLastStatus()
                    IMTracker.Chat.Main.Click.Msg.msgDelayedSendToastView(self.viewModel.chatModel, self.delegate?.chatFromWhere)
                    return
                }
                IMTracker.Chat.Main.Click.Msg.msgDelayedSendTimeClick(self.viewModel.chatModel, self.delegate?.chatFromWhere)
                // 内容不为空
                if attributedText.string.isEmpty == false {
                    self.keyboardView.fold()
                    guard let scheduleTime = self.scheduleTime else {
                        assertionFailure("scheduletime is empty")
                        Self.logger.info("scheduletime is empty")
                        self.keyboardView.keyboardStatusManager.switchToDefaultJob()
                        return
                    }
                    self.delegate?.setScheduleTipViewStatus(.creating)
                    let time = ScheduleSendManager.formatSendScheduleTime(scheduleTime)
                    self.keyboardView.sendNewMessage(scheduleTime: time ?? Int64(Date().timeIntervalSince1970))
                    self.keyboardView.keyboardStatusManager.switchToDefaultJob()
                    // 删除草稿
                    self.viewModel.draftCache?.deleteScheduleDraft(key: self.getScheduleDraftId() ?? "", messageId: vm.rootMessage?.id, chatId: vm.chatModel.id ?? "")
                } else {
                    Self.logger.info("attributedText string isEmpty")
                    assertionFailure("bussiness error")
                }
            }).disposed(by: self.disposeBag)
    }

    override  public func onMessengerKeyboardPanelSchuduleCloseButtonTap(itemId: String,
                                                               itemType: RustPB.Basic_V1_ScheduleMessageItem.ItemType) {
        guard let from = self.delegate?.baseViewController(), let vm = viewModel as? ChatInputViewModel else {
            assertionFailure()
            return
        }
        self.keyboardView.inputTextView.resignFirstResponder()
        vm.scheduleSendService?.showAlertWhenSchuduleCloseButtonTap(from: from,
                                                                   chatID: Int64(vm.chatModel.id) ?? 0,
                                                                   itemId: itemId,
                                                                   itemType: itemType,
                                                                   cancelTask: { [weak self] in
                // 恢复输入框状态
                self?.keyboardView.goBackToLastStatus()
                // 删除草稿
                vm.draftCache?.deleteScheduleDraft(key: self?.getScheduleDraftId() ?? "", messageId: vm.rootMessage?.id, chatId: vm.chatModel.id ?? "")
            },
                                                                   closeTask: { [weak self, weak from] in
                IMTracker.Chat.Main.Click.Msg.msgDelayedSendClick(vm.chatModel, click: "delete", self?.delegate?.chatFromWhere)
                // 恢复输入框状态
                self?.keyboardView.goBackToLastStatus()
                // 删除草稿
                vm.draftCache?.deleteScheduleDraft(key: self?.getScheduleDraftId() ?? "", messageId: vm.rootMessage?.id, chatId: vm.chatModel.id ?? "")
                // 如果定时消息已经发送/删除，弹toast后恢复普通输入框
                if let ids = self?.delegate?.getSendScheduleMsgIds(), ids.0.contains { $0 == itemId } || ids.1.contains { $0 == itemId }, let from = from {
                    UDToast.showTips(with: BundleI18n.LarkChat.Lark_IM_ScheduledMessage_RepeatOperationFailed_Toast, on: from.view)
                    return
                }
        }) { [weak self] in
            self?.keyboardView.inputTextView.becomeFirstResponder()
        }
    }

    private func getScheduleDraftId() -> String {
        let draftId = self.viewModel.rootMessage == nil ? self.viewModel.chatModel.scheduleMessageDraftID : self.viewModel.rootMessage?.scheduleMessageDraftId ?? ""
        return draftId
    }

    private func getHasScheduleMsg() -> Observable<Bool> {
        let chatId = viewModel.chatModel.id
        return viewModel.messageAPI?.getScheduleMessages(chatId: Int64(chatId) ?? 0,
                                                 threadId: nil,
                                                 rootId: nil,
                                                 isForceServer: false,
                                                 scene: .chatOnly)
            .map { res in
                let status = ChatScheduleSendTipViewModel.getScheduleTypeFrom(messageItems: res.messageItems, entity: res.entity)
                Self.logger.info("getScheduleMessages chatId: \(chatId), res.messageItemsCount:\(res.messageItems.count), status: \(status)")
                return res.messageItems.isEmpty == false
            } ?? .error(UserScopeError.disposed)
    }

    // 长按定时发送
    override public func onMessengerKeyboardPanelSendLongPress() {
        // my ai不支持创建
        if viewModel.chatModel.isP2PAi { return }
        guard self.viewModel.scheduleSendService?.scheduleSendEnable == true else { return }
        guard let from = self.delegate?.baseViewController(), let vm = viewModel as? ChatInputViewModel else {
            assertionFailure()
            return
        }
        guard ScheduleSendManager.chatCanScheduleSend(vm.chatModel) else { return }

        if self.delegate?.getScheduleMsgSendTime() != nil {
            Self.logger.info("getScheduleMsgSendTime not empty")
            IMTracker.Chat.Main.Click.Msg.msgDelayedSendToastView(self.viewModel.chatModel, self.delegate?.chatFromWhere)
            UDToast.showTips(with: BundleI18n.LarkChat.Lark_IM_ScheduleMessage_CanSendOnly1ScheduledMessage_Tooltip, on: from.view)
            return
        }

        getHasScheduleMsg()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak from] hasScheduleMsg in
                guard let `self` = self, let from = from else { return }
                guard !hasScheduleMsg else {
                    UDToast.showTips(with: BundleI18n.LarkChat.Lark_IM_ScheduleMessage_CanSendOnly1ScheduledMessage_Tooltip, on: from.view)
                    IMTracker.Chat.Main.Click.Msg.msgDelayedSendToastView(self.viewModel.chatModel, self.delegate?.chatFromWhere)
                    return
                }
                // 大于当前时间5分钟
                let currentInitDate = Date().addingTimeInterval(5 * 60)
                let currentSelectDate = ScheduleSendManager.getFutureHour(Date())
                IMTracker.Chat.Main.Click.Msg.delayedSendMobile(self.viewModel.chatModel, self.delegate?.chatFromWhere)
                self.viewModel.scheduleSendService?.showDatePicker(currentInitDate: currentInitDate,
                                                                  currentSelectDate: currentSelectDate,
                                                                  from: from) { [weak self] time in
                    guard let `self` = self else { return }
                    IMTracker.Chat.Main.Click.Msg.msgDelayedSendTimeClick(self.viewModel.chatModel, self.delegate?.chatFromWhere)
                    self.getHasScheduleMsg()
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { [weak self, weak from] hasScheduleMsg in
                            guard let `self` = self, let from = from else { return }
                            guard !hasScheduleMsg else {
                                UDToast.showTips(with: BundleI18n.LarkChat.Lark_IM_ScheduleMessage_CanSendOnly1ScheduledMessage_Tooltip, on: from.view)
                                IMTracker.Chat.Main.Click.Msg.msgDelayedSendToastView(self.viewModel.chatModel, self.delegate?.chatFromWhere)
                                return
                            }
                            self.delegate?.setScheduleTipViewStatus(.creating)
                            let formatTime = ScheduleSendManager.formatSendScheduleTime(time)
                            self.keyboardView.sendNewMessage(scheduleTime: formatTime)
                            // 删除草稿
                            vm.draftCache?.deleteScheduleDraft(key: self.getScheduleDraftId() ?? "", messageId: vm.rootMessage?.id, chatId: vm.chatModel.id ?? "")
                        }).disposed(by: self.disposeBag)
                }
            }).disposed(by: self.disposeBag)
    }

    // +号菜单点击开始发送定时消息
    override public func onMessengerKeyboardPanelScheduleSendTaped(draft: RustPB.Basic_V1_Draft?) {
        guard let from = self.delegate?.baseViewController(), let vm = viewModel as? ChatInputViewModel else {
            assertionFailure()
            return
        }
        if self.delegate?.getScheduleMsgSendTime() != nil {
            Self.logger.info("getScheduleMsgSendTime not empty")
            IMTracker.Chat.Main.Click.Msg.msgDelayedSendToastView(self.viewModel.chatModel, self.delegate?.chatFromWhere)
            UDToast.showTips(with: BundleI18n.LarkChat.Lark_IM_ScheduleMessage_CanSendOnly1ScheduledMessage_Tooltip, on: from.view)
            return
        }
        getHasScheduleMsg()
            .observeOn(MainScheduler.instance)
            .flatMap({ [weak self, weak from] hasScheduleMsg -> Observable<KeyboardJob.ReplyInfo?> in
                guard let `self` = self, let from = from else { return .empty() }
                guard !hasScheduleMsg else {
                    UDToast.showTips(with: BundleI18n.LarkChat.Lark_IM_ScheduleMessage_CanSendOnly1ScheduledMessage_Tooltip, on: from.view)
                    IMTracker.Chat.Main.Click.Msg.msgDelayedSendToastView(self.viewModel.chatModel, self.delegate?.chatFromWhere)
                    return .empty()
                }
                if case .reply(info: let info) = self.keyboardView.keyboardStatusManager.currentKeyboardJob {
                    return .just(info)
                } else {
                    if draft?.messageID.isEmpty == false, self.viewModel.rootMessage == nil {
                        return self.viewModel.messageAPI?.fetchLocalMessage(id: draft?.messageID ?? "").map({
                            return KeyboardJob.ReplyInfo(message: $0, partialReplyInfo: nil)
                        }) ?? .just(nil)
                    }
                    return .just(nil)
                }
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] replyInfo in
                guard let `self` = self else { return }
                self.keyboardView.switchJob(.scheduleSend(info: replyInfo))
                if let time = draft?.scheduleInfo.scheduleTime {
                    let date = Date(timeIntervalSince1970: TimeInterval(time))
                    let is12HourTime = !(self.userGeneralSettings?.is24HourTime.value ?? false)
                    self.keyboardView.keyboardStatusManager.addTip(.scheduleSend(date, true, is12HourTime, ScheduleSendModel()))
                }
                self.keyboardView.inputViewBecomeFirstResponder()
                if let draft = draft, draft.content.isEmpty == false {
                    // 将草稿更新为内容
                    self.updateDraftContent(by: draft.content)
                    // 删除草稿
                    self.viewModel.draftCache?.deleteScheduleDraft(key: draft.id, messageId: nil, chatId: vm.chatModel.id)
                }
            }).disposed(by: self.disposeBag)
    }

    override func configViewModelCallBacks() {
        super.configViewModelCallBacks()
        /// 当AttachmentManager的时候 需要更callBack
        chatInputViewModel?.updateAttachmentManagerCallBack = { [weak self] in
            self?.updateAttachmentUploaderDefaultCallBack()
        }
    }
    /// 进入页面 获取草稿内容|| 详情页更新键盘
    override func setupDraftContent(_ finish: (() -> Void)? = nil) {
        let chat = self.viewModel.chatModel
        if !chat.isAllowPost {
            finish?()
            return
        }
        /// 这里需要判断是否存在 rootMessage， rootMessage 代表当前页面是否存在根消息
        /// lastDraftId 和含义是 chat 上次退出页面时键盘显示的草稿状态，只影响 rootMessage 为空的情况
        chatInputViewModel?.updateAttachmentUploaderIfNeed()
        if self.viewModel.rootMessage != nil ||
            chat.lastDraftId.isEmpty {
            autoRecoveryDraft(finish)
        } else {
            /// 根据 lastDraftId 获取上一次的 reply message
            /// 如果不存在 replyMessage，更新草稿
            self.viewModel.getDraftMessageBy(
                lastDraftId: chat.lastDraftId
            ) { [weak self] (draftId, message, draft) in
                guard let draftId = draftId else {
                    self?.autoRecoveryDraft(finish)
                    return
                }
                switch draftId {
                case .replyMessage(_, let partialReplyInfo):
                    if let message = message {
                        self?.keyboardView.switchJob(.reply(info: KeyboardJob.ReplyInfo(message: message,
                                                                                        partialReplyInfo: partialReplyInfo)))
                    }
                    self?.recoveryTextDraftIfNeedWith(chat: chat, draft: draft)
                    finish?()
                case .multiEditMessage(_, _):
                    if let message = message {
                        self?.keyboardView.switchJob(.multiEdit(message: message))
                        self?.updateDraftContent(onFinished: { [weak self] in
                            //消费后清空草稿
                            finish?()
                            self?.chatInputViewModel?.cleanPostDraft()
                        })
                    }
                case .schuduleSend(_, let time, let partialReplyInfo, let parent, let item):
                    guard let info = draft?.scheduleInfo else {
                        finish?()
                        return
                    }
                    if info.item.itemID.isEmpty == false, let message = message {
                        // 进入定时编辑状态
                        self?.keyboardView.switchJob(.scheduleMsgEdit(info: KeyboardJob.ReplyInfo(message: message,
                                                                                                  partialReplyInfo: partialReplyInfo),
                                                                      time: Date(timeIntervalSince1970: TimeInterval(time)),
                                                                      type: info.item.itemType))

                    } else if info.item.itemType == .quasiScheduleMessage {
                        var info: KeyboardJob.ReplyInfo?
                        if let parent = parent {
                            info = KeyboardJob.ReplyInfo(message: parent, partialReplyInfo: partialReplyInfo)
                        }
                        // 进入定时发送状态
                        if case .reply(info: let info) = self?.keyboardView.keyboardStatusManager.currentKeyboardJob {
                            self?.keyboardView.switchJobWithoutReplaceLastStatus(.scheduleSend(info: info))
                        } else {
                            self?.keyboardView.switchJob(.scheduleSend(info: info))
                        }
                        // 添加tip
                        let date = Date(timeIntervalSince1970: TimeInterval(time))
                        let is12HourTime = self?.userGeneralSettings?.is24HourTime.value == false
                        self?.keyboardView.keyboardStatusManager.addTip(.scheduleSend(date, true, is12HourTime, ScheduleSendModel(itemType: .quasiScheduleMessage)))
                    }
                    // 将草稿转化为输入框内容
                    self?.updateDraftContent(by: draft?.content ?? "")
                    // 设置资源在输入框显示大小
                    if let text = self?.keyboardView.attributedString {
                        self?.updateAttachmentSizeFor(attributedText: text)
                    }
                    //消费后清空草稿
                    self?.chatInputViewModel?.cleanPostDraft()
                    finish?()
                default:
                    self?.autoRecoveryDraft(finish)
                }
            }
        }
    }

    override public func onMessengerKeyboardPanelCommit() {
        // 二次编辑
        if let message = keyboardView.keyboardStatusManager.getMultiEditMessage() {
            confirmMultiEditMessage(message, triggerMethod: .click_save)
        }
        // 快捷指令
        if case .quickAction = keyboardView.keyboardStatusManager.currentKeyboardJob {
            sendQuickActionFromCurrentEditing()
        }
    }

    override public func onMessengerKeyboardPanelCancel() {
        keyboardView.goBackToLastStatus()
        // 快捷指令
        if case .quickAction = keyboardView.keyboardStatusManager.currentKeyboardJob {
            exitQuickActionEditingState()
        }
    }

    private func getSendMessageModel() -> (Basic_V1_RichText, Bool, String?)? {
        guard let vm = viewModel as? ChatInputViewModel else {
            assertionFailure()
            return nil
        }
        let titleAttributedText = keyboardView.titleTextView?.attributedText ?? NSAttributedString(string: "")
        var contentAttr = keyboardView.getTrimTailSpacesAttributedString()
        let title: String = titleAttributedText.string.lf.trimCharacters(in: .whitespacesAndNewlines)

        var isPost = true
        /// 如果没有图片&视频&标题&代码块 走Text消息
        if let attachmentManager = chatInputViewModel?.attachmentManager,
           attachmentManager.attachmentIdsForAttruibuteStr(contentAttr).isEmpty,
           title.isEmpty,
           !CodeInputHandler.attributedTextContainsCode(attributedText: contentAttr) {
            isPost = false
        }
        contentAttr = RichTextTransformKit.preproccessSendAttributedStr(contentAttr)
        if var richText = RichTextTransformKit.transformStringToRichText(string: contentAttr) {
            richText.richTextVersion = 1
            return contentAttr.string.isEmpty == false ? (richText, isPost, title.isEmpty ? nil : title) : nil
        }
        return nil
    }

    // 点击更新消息
    override public func onMessengerKeyboardPanelSchuduleConfrimButtonTap(itemId: String,
                                                                          cid: String,
                                                                          itemType: RustPB.Basic_V1_ScheduleMessageItem.ItemType) {
        patchScheduleMessage(itemId: itemId, cid: cid, itemType: itemType, isSendImmediately: false, needSuspend: true)
    }

    func patchScheduleMessage(itemId: String,
                              cid: String,
                              itemType: RustPB.Basic_V1_ScheduleMessageItem.ItemType,
                              isSendImmediately: Bool,
                              needSuspend: Bool) {
        guard let from = self.delegate?.baseViewController(), let vm = viewModel as? ChatInputViewModel else {
            assertionFailure()
            return
        }
        func callback() {
            // 重置输入框状态和草稿
            self.chatInputViewModel?.cleanPostDraft()
            self.keyboardView.goBackToLastStatus()
            self.keyboardView.fold()
        }
        // 如果定时消息已经发送/删除，弹toast后恢复普通输入框
        if let ids = self.delegate?.getSendScheduleMsgIds(), ids.0.contains { $0 == itemId } || ids.1.contains { $0 == itemId } {
            Self.logger.info("msg was sent or deleted, itemId: \(itemId), successIds: \(ids.0), deleteIds: \(ids.1)")
            UDToast.showTips(with: BundleI18n.LarkChat.Lark_IM_ScheduledMessage_RepeatOperationFailed_Toast, on: from.view)
            callback()
            return
        }
        // 如果当前选择的消息已经过去了，弹toast阻断
        if isSendImmediately == false, let date = scheduleDate, date < Date() {
            UDToast.showTips(with: BundleI18n.LarkChat.Lark_IM_ScheduleMessage_TimePassedSelectAgain_Toast, on: from.view)
            return
        }
        if !vm.chatModel.isAllowPost {
            UDToast.showFailure(with: BundleI18n.LarkChat.Lark_IM_EditMessage_FailedToEditDueToSpecificSettings_Toast(vm.chatModel.name), on: from.view)
            callback()
            return
        }
        let job = self.keyboardView.keyboardStatusManager.currentKeyboardJob
        var contentAttr = keyboardView.getTrimTailSpacesAttributedString()
        // 判断内容为空
        guard contentAttr.string.isEmpty == false, let model = self.getSendMessageModel() else {
            // 消息内容为空，弹窗
            vm.scheduleSendService?.showAlertWhenContentNil(from: from,
                                                           chatID: Int64(vm.chatModel.id) ?? 0,
                                                           itemId: itemId,
                                                           itemType: itemType,
                                                           deleteConfirmTask: { [weak self] in
                self?.keyboardView.goBackToLastStatus()
            },
                                                           deleteSuccessTask: { [weak self] in
                if let chat = self?.viewModel.chatModel {
                    IMTracker.Chat.Main.Click.Msg.msgDelayedSendClick(chat, click: "delete", self?.delegate?.chatFromWhere)
                }
            })
            return
        }

        callback()
        self.delegate?.setScheduleTipViewStatus(.updating)
        // 调用接口
        let richText = model.0
        let isPost = model.1
        let title = model.2
        var quasiContent = QuasiContent()
        quasiContent.richText = richText
        if let title = title {
            quasiContent.title = title
        }

        quasiContent.lingoOption = LingoConvertService.transformStringToQuasiContent(contentAttr)
        // 格式化时间
        var sendScheduleTime: Int64?
        if let time = self.scheduleTime {
            sendScheduleTime = ScheduleSendManager.formatSendScheduleTime(time)
        }
        var item = ScheduleMessageItem()
        item.itemID = itemId
        item.itemType = itemType
        vm.postSendService?.patchScheduleMessage(chatID: Int64(vm.chatModel.id) ?? 0,
                                                cid: cid,
                                                item: item,
                                                messageType: isPost ? .post : .text,
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
                        UDToast.showFailure(with: BundleI18n.LarkChat.Lark_Legacy_ErrorMessageTip, on: view, error: error)
                    }
                }
                Self.logger.error("patchScheduleMessage error", error: error)
            }
        }
    }

    // 点击定时发送时间
    override public func onMessengerKeyboardPanelSchuduleSendTimeTap(
        currentSelectDate: Date,
        sendMessageModel: SendMessageModel,
        _ task: @escaping (Date) -> Void) {
        guard let from = self.delegate?.baseViewController(), let vm = viewModel as? ChatInputViewModel else {
            assertionFailure()
            return
        }
        // 初始化当前的时间
        self.viewModel.scheduleDate = currentSelectDate
        self.viewModel.scheduleInitDate = currentSelectDate
        // 展示时间选择器
        vm.scheduleSendService?.showDatePickerInEdit(currentSelectDate: currentSelectDate,
                                                    chatName: vm.chatModel.name,
                                                    from: from,
                                                    isShowSendNow: !(sendMessageModel.cid.isEmpty && sendMessageModel.messageId.isEmpty),
                                                    sendNowCallback: { [weak self] in
            IMTracker.Chat.Main.Click.Msg.msgDelayedSendClick(vm.chatModel, click: "send_immediate", self?.delegate?.chatFromWhere)
            self?.patchScheduleMessage(itemId: sendMessageModel.messageId,
                                       cid: sendMessageModel.cid,
                                       itemType: sendMessageModel.itemType,
                                       isSendImmediately: true,
                                       needSuspend: false)
        },
                                                    confirmTask: { [weak self] date in
            // 更新为用户选择的时间
            self?.viewModel.scheduleDate = date
            if let initDate = self?.viewModel.scheduleInitDate, date != initDate, let chat = self?.viewModel.chatModel {
                IMTracker.Chat.Main.Click.Msg.msgDelayedSendClick(chat, click: "modify_time", self?.delegate?.chatFromWhere)
            }
            // 更新tip数据
            if case .scheduleSend(let time, let show, let is12HourTime, let model) = self?.viewModel.keyboardStatusManagerBlock?()?.currentDisplayTip {
                self?.updateTip(.scheduleSend(date, show, is12HourTime, model))
            }
            task(date)
        })
    }

    public override func textChange(text: String, textView: LarkEditTextView) {
        debouncer.debounce(indentify: "textChange", duration: debounceDuration) { [weak self] in
            let job = self?.keyboardView.keyboardStatusManager.currentKeyboardJob
            if textView.isFirstResponder,
               //二次编辑场景不实时存草稿
               job?.isMultiEdit != true,
               job?.isScheduleSendState != true {
                self?.saveInputViewDraft()
            }
        }
        delegate?.textChange(text: text, textView: textView)
    }

    public override func multiEditMessage(message: Message) {
        let supportType: [Message.TypeEnum] = [.post, .text]
        guard supportType.contains(message.type) else {
            return
        }
        Self.logger.info("multiEdit message type \(message.type)")
        if case .multiEdit = self.keyboardView.keyboardStatusManager.currentKeyboardJob {
            self.keyboardView.switchJobWithoutReplaceLastStatus(.multiEdit(message: message))
        } else {
            self.keyboardView.switchJob(.multiEdit(message: message))
        }

        let guideKey = "im_chat_edit_message"
        if let chatInputViewModel = chatInputViewModel,
           chatInputViewModel.newGuideManager?.checkShouldShowGuide(key: guideKey) == true {
            keyboardView.updateTipIfNeed(.atWhenMultiEdit)
            chatInputViewModel.newGuideManager?.didShowedGuide(guideKey: guideKey)
        }

        self.keyboardView.inputTextView.attributedText = NSAttributedString(string: "")
        self.keyboardView.titleTextView?.attributedText = NSAttributedString(string: "")

        if !message.editDraftId.isEmpty {
            self.keyboardView.keyboardStatusManager.multiEditingMessageContent = nil
            self.updateDraftContent(onFinished: { [weak self] in
                //消费后清空草稿
                self?.chatInputViewModel?.cleanPostDraft()
            })
            return
        }
        let callBack: (() -> Void) = { [weak self] in
            guard let self = self else { return }
            let titleAttributedText = self.keyboardView.titleTextView?.attributedText ?? NSAttributedString(string: "")
            let title: String = titleAttributedText.string.lf.trimCharacters(in: .whitespacesAndNewlines)
            var contentAttr = self.keyboardView.getTrimTailSpacesAttributedString()
            contentAttr = RichTextTransformKit.preproccessSendAttributedStr(contentAttr)
            if let richText = RichTextTransformKit.transformStringToRichText(string: contentAttr) {
                let lingoInfo = LingoConvertService.transformStringToQuasiContent(contentAttr)
                self.keyboardView.keyboardStatusManager.multiEditingMessageContent = (richText: richText,
                                                                                      title: title.isEmpty ? nil : title,
                                                                                      lingoInfo: lingoInfo)
            }
            self.updateAttachmentSizeFor(attributedText: self.keyboardView.attributedString)
        }
        switch message.type {
        case .text:
            self.setupTextMessage(message: message, callback: callBack)
        case .post:
            self.setupPostMessage(message: message, callback: callBack)
        @unknown default:
            break
        }
    }
    public override func transformRichTextToStr(richText: RustPB.Basic_V1_RichText) -> NSAttributedString {
        let attachmentResult: [String: String] = chatInputViewModel?.attachmentManager?.attachmentUploader.results ?? [:]
        var content = RichTextTransformKit.transformRichTextToStr(
            richText: richText,
            attributes: keyboardView.inputTextView.baseDefaultTypingAttributes,
            attachmentResult: attachmentResult,
            processProvider: [:])
        /// 删除尾部换行
        content = content.lf.trimmedAttributedString(set: CharacterSet.newlines, position: .trail)
        AtTransformer.getAllChatterInfoForAttributedString(content).forEach { chatterInfo in
            let userInfoDic = AtTransformer.getAllChatterActualNameMapForAttributedString(keyboardView.inputTextView.attributedText)
            chatterInfo.actualName = userInfoDic[chatterInfo.id] ?? ""
        }
        return content
    }
    override func onFinishUpdateAttributedStringAtInfo(_ attributedStr: NSAttributedString,
                                                       isInsert: Bool) {
        super.onFinishUpdateAttributedStringAtInfo(attributedStr, isInsert: isInsert)
        fontPanelSubModule?.updateInputTextViewStyle()
    }

    public override func saveInputPostDraftWithReplyMessageInfo(_ info: KeyboardJob.ReplyInfo?) {
        guard let vm = chatInputViewModel, let attachmentManager = vm.attachmentManager,
              let attrText = keyboardView.keyboardStatusManager.delegate?.getKeyboardAttributedText(),
              let draft = self.draft else {
            return
        }
        let draftId: DraftId
        if let info = info {
            draftId = .replyMessage(messageId: info.message.id, partialReplyInfo: info.partialReplyInfo)
        } else {
            draftId = .chat(chatId: vm.chatModel.id)
        }
        vm.savePostDraftWithMessageId(id: draftId,
                                      draft: draft,
                                      attachmentKeys: attachmentManager.attachmentIdsForAttruibuteStr(attrText),
                                      async: true,
                                      callback: nil)
    }

    public override func saveScheduleDraft() {
        guard let vm = chatInputViewModel, let attachmentManager = vm.attachmentManager,
              let attrText = keyboardView.keyboardStatusManager.delegate?.getKeyboardAttributedText(),
              let draft = self.draft else {
            return
        }
        vm.saveInputViewDraft(draft: draft,
                              attachmentKeys: attachmentManager.attachmentIdsForAttruibuteStr(attrText),
                              async: true,
                              isExitChat: false,
                              callback: nil)
    }

    public override func deleteScheduleDraft() {
        guard let vm = chatInputViewModel else {
            return
        }
        // 删除草稿
        vm.draftCache?.deleteScheduleDraft(key: self.getScheduleDraftId() ?? "", messageId: vm.rootMessage?.id, chatId: vm.chatModel.id ?? "")
    }

    public override func applyInputPostDraft(_ replyDraft: String) {
        updateDraftContent(by: replyDraft)
    }
    public override func updateAttachmentSizeFor(attributedText: NSAttributedString) {
        chatInputViewModel?.attachmentManager?.updateAttachmentSizeWithMaxHeight(keyboardView.textFieldMaxHeight - 5,
                                                                                imageMinWidth: 80,
                                                                                attributedText: attributedText,
                                                                                textView: keyboardView.inputTextView)
    }
    //发送、二次编辑点保存等动作后 会调用这里
    override func onInputFinished() {
        keyboardView.attributedString = NSAttributedString(string: "")
        keyboardView.titleTextView?.attributedText = NSAttributedString(string: "")
        self.translateDataService.clearOriginAndTranslationData()
        self.keyboardView.translationInfoPreviewView.recallEnable = self.translateDataService.getRecallEnable()
        translateDataService.updateSessionID()
        keyboardView.clearTranslationPreview()
    }

    /// 该方法只会在Chat中被调用
    public override func setReplyMessage(message: Message, replyInfo: PartialReplyInfo?) {
        // 非回复状态下存储键盘中原有的输入内容，如果replyMessage没草稿则该内容会带过去
        let inputString = (self.viewModel.replyMessage == nil) ? self.keyboardView.attributedString : NSAttributedString()
        var draftData: Data?
        if viewModel.replyMessage == nil {
            draftData = chatInputViewModel?.attachmentManager?.attachmentUploader.draft.atchiverData()
        }
        let isScheduleMsgEdit = self.keyboardView.keyboardStatusManager.currentKeyboardJob.isScheduleMsgEdit
        // 这一步会同步的把输入框内容变为replyMessage的草稿
        self.keyboardView.keyboardStatusManager.switchJob(.reply(info: KeyboardJob.ReplyInfo(message: message, partialReplyInfo: replyInfo)))
        // 如果replyMessage的草稿为空，则需要自动插入内容
        if self.keyboardView.attributedString.length == 0 {
            // 单聊：自动插入{键盘中输入的内容}
            let muAttr = getTitleAttributeString()
            self.keyboardView.titleTextView?.attributedText = NSAttributedString(string: "")
            if self.viewModel.chatModel.type == .p2P {
                muAttr.append(inputString)
                self.keyboardView.attributedString = muAttr
            } else {
                // 群聊回复别人：自动插入{@UserName}+{键盘中输入的内容}
                if let user = message.fromChatter, user.id != self.viewModel.userResolver.userID {
                    let name = self.getDisplayName(chatter: user)
                    self.keyboardView.insert(userName: name,
                                             actualName: user.localizedName,
                                             userId: user.id,
                                             isOuter: false)
                    let newString = NSMutableAttributedString(attributedString: self.keyboardView.attributedString)
                    if !isScheduleMsgEdit {
                        newString.append(inputString)
                    }
                    muAttr.append(newString)
                    self.keyboardView.attributedString = muAttr
                } else {
                    // 群聊回复自己：自动插入{键盘中输入的内容}
                    if !isScheduleMsgEdit {
                        muAttr.append(inputString)
                    }
                    self.keyboardView.attributedString = muAttr
                }
            }
            updateAttachmentDraftWithReplayMessageId(message.id, data: draftData)
        }
    }

    func getTitleAttributeString() -> NSMutableAttributedString {
        let titleString = self.keyboardView.titleTextView?.attributedText ?? NSAttributedString(string: "")
        let muAttr = NSMutableAttributedString(attributedString: titleString)
        if titleString.length > 0 {
            var defaultAttributes = PostInputManager.getBaseDefaultTypingAttributesFor(keyboardView.inputTextView.defaultTypingAttributes)
            if let font = defaultAttributes[.font] as? UIFont {
                defaultAttributes[.font] = font.bold
                defaultAttributes[FontStyleConfig.boldAttributedKey] = FontStyleConfig.boldAttributedValue
            }
            muAttr.append(NSAttributedString(string: "\n", attributes: defaultAttributes))
            muAttr.addAttributes(defaultAttributes, range: NSRange(location: 0, length: titleString.length))
        }
        return muAttr
    }

    private func sendMessageWith(contentAttributedText: NSAttributedString,
                                 scheduleTime: Int64?) {
        let titleAttributedText = keyboardView.titleTextView?.attributedText ?? NSAttributedString(string: "")
        var contentAttr = contentAttributedText
        let title: String = titleAttributedText.string.lf.trimCharacters(in: .whitespacesAndNewlines)

        var sendPost = true
        /// 如果没有图片&视频&标题&代码块 走Text消息
        if let attachmentManager = chatInputViewModel?.attachmentManager,
           attachmentManager.attachmentIdsForAttruibuteStr(contentAttributedText).isEmpty,
           title.isEmpty,
           !CodeInputHandler.attributedTextContainsCode(attributedText: contentAttributedText) {
            sendPost = false
        }
        contentAttr = RichTextTransformKit.preproccessSendAttributedStr(contentAttr)
        if var richText = RichTextTransformKit.transformStringToRichText(string: contentAttr) {
            richText.richTextVersion = 1
            self.onInputFinished()
            let lingoInfo = LingoConvertService.transformStringToQuasiContent(contentAttr)
            if let replyInfo = self.viewModel.replyMessageInfo {
                // 回复消息成功后，需要清空Chat的草稿
                self.viewModel.draftCache?.saveDraft(chatId: self.viewModel.chatModel.id, type: .post, content: "", callback: nil)
                let parentMessage = replyInfo.message
                if sendPost {
                    self.doSendPostMessageWith(title: title,
                                               richText: richText,
                                               lingoInfo: lingoInfo,
                                               scheduleTime: scheduleTime,
                                               parentMessage: parentMessage)
                } else {
                    self.doSendTextMessageWith(richText: richText,
                                               lingoInfo: lingoInfo,
                                               parentMessage: parentMessage,
                                               scheduleTime: scheduleTime,
                                               isFullScreen: false)
                }
                self.viewModel.cleanReplyMessage()
            } else {
                if sendPost {
                    self.doSendPostMessageWith(title: title, richText: richText, lingoInfo: lingoInfo, scheduleTime: scheduleTime, parentMessage: viewModel.rootMessage)
                } else {
                    self.doSendTextMessageWith(richText: richText,
                                               lingoInfo: lingoInfo,
                                               parentMessage: viewModel.rootMessage,
                                               scheduleTime: scheduleTime,
                                               isFullScreen: false)
                }
                chatInputViewModel?.cleanPostDraft()
            }
            /// 添加发消息埋点 记录是在哪一个 scene 发出的消息
            if let baseVC = self.delegate?.baseViewController() {
                ChatTracker.trackSendMessageScene(chat: self.viewModel.chatModel, in: baseVC)
            }
        }
        self.audioKeyboardHelper?.trackAudioRecognizeIfNeeded()
    }

    private func doSendPostMessageWith(title: String,
                                       richText: RustPB.Basic_V1_RichText,
                                       lingoInfo: RustPB.Basic_V1_LingoOption?,
                                       scheduleTime: Int64?,
                                       parentMessage: Message?) {
        let chatId: String = self.viewModel.chatModel.id
        viewModel.messageSender?.sendPost(title: title,
                                         content: richText,
                                         lingoInfo: lingoInfo,
                                         parentMessage: parentMessage,
                                         chatId: chatId,
                                         scheduleTime: scheduleTime) { [weak self] state in
            guard let self = self else { return }
            if case .finishSendMessage(let message, _, _, _, _) = state {
                self.trackerInputMsgSend(message: message,
                                         isFullScreen: false,
                                         useSendBtn: self.keyboardNewStyleEnable ?? false,
                                         title: title,
                                         richText: richText)
            }
        }
    }

    private func doSendTextMessageWith(richText: RustPB.Basic_V1_RichText,
                                       lingoInfo: RustPB.Basic_V1_LingoOption?,
                                       parentMessage: Message?,
                                       scheduleTime: Int64?,
                                       isFullScreen: Bool) {
        let lastMessagePosition: Int32 = self.viewModel.chatModel.lastMessagePosition
        let chatId: String = self.viewModel.chatModel.id
        self.viewModel.messageSender?.sendText(content: richText,
                                               lingoInfo: lingoInfo,
                                               parentMessage: parentMessage,
                                               chatId: chatId,
                                               position: lastMessagePosition,
                                               scheduleTime: scheduleTime,
                                               quasiMsgCreateByNative: self.quasiMsgCreateByNative) { [weak self] state in
            guard let self = self else { return }
            if case .finishSendMessage(let message, _, _, _, _) = state {
                let useSendBtn = isFullScreen ? true : (self.keyboardNewStyleEnable ?? false)
                self.trackerInputMsgSend(message: message,
                                         isFullScreen: isFullScreen,
                                         useSendBtn: useSendBtn,
                                         title: nil,
                                         richText: richText)
            }
        }
    }

    func confirmMultiEditMessage(_ message: Message,
                                 triggerMethod: IMTracker.Chat.Main.Click.Msg.SaveEditMsgTriggerMethod) {
        let titleAttributedText = keyboardView.titleTextView?.attributedText ?? NSAttributedString(string: "")
        var contentAttr = keyboardView.getTrimTailSpacesAttributedString()
        let title: String = titleAttributedText.string.lf.trimCharacters(in: .whitespacesAndNewlines)

        IMTracker.Chat.Main.Click.Msg.saveEditMsg(self.viewModel.chatModel,
                                                  message,
                                                  triggerMethod: triggerMethod,
                                                  self.delegate?.chatFromWhere)
        //触发二次编辑或（内容为空时）撤回后（无论请求是否成功），都会走到这里
        func callback() {
            chatInputViewModel?.cleanPostDraft()
            self.onInputFinished()
            keyboardView.keyboardStatusManager.goBackToLastStatus()
        }

        if title.isEmpty && contentAttr.string.isEmpty {
            //标题和内容都为空，视为撤回
            let dialog = UDDialog()
            dialog.setTitle(text: BundleI18n.LarkChat.Lark_IM_EditMessage_ClearAllContenAndRecallMessage_Title)
            dialog.setContent(text: BundleI18n.LarkChat.Lark_IM_EditMessage_ClearAllContenAndRecallMessage_Desc)
            dialog.addSecondaryButton(text: BundleI18n.LarkChat.Lark_IM_EditMessage_ClearAllContenAndRecallMessage_Cancel_Button,
                                      dismissCompletion: { [weak self] in
                IMTracker.Msg.WithdrawConfirmCLick(self?.viewModel.chatModel,
                                                   message,
                                                   clickConfirm: false)
            })
            dialog.addDestructiveButton(text: BundleI18n.LarkChat.Lark_IM_EditMessage_ClearAllContenAndRecallMessage_RecallMessage_Button,
                                        dismissCompletion: { [weak self] in
                guard let self = self else { return }
                IMTracker.Msg.WithdrawConfirmCLick(self.viewModel.chatModel,
                                                   message,
                                                   clickConfirm: true)
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
                                self?.viewModel.multiEditService?.reloadEditEffectiveTimeConfig()
                            default:
                                UDToast.showFailure(
                                    with: BundleI18n.LarkChat.Lark_Legacy_RecallMessageErr,
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
        var isPost = true
        /// 如果没有图片&视频&标题&代码块 走Text消息
        if let attachmentManager = chatInputViewModel?.attachmentManager,
           attachmentManager.attachmentIdsForAttruibuteStr(contentAttr).isEmpty,
           title.isEmpty,
           !CodeInputHandler.attributedTextContainsCode(attributedText: contentAttr) {
            isPost = false
        }
        contentAttr = RichTextTransformKit.preproccessSendAttributedStr(contentAttr)
        if var richText = RichTextTransformKit.transformStringToRichText(string: contentAttr),
           let messageId = Int64(message.id) {
            richText.richTextVersion = 1
            let chat = self.viewModel.chatWrapper.chat.value
            if !chat.isAllowPost {
                guard let window = self.delegate?.baseViewController().view.window else { return }
                UDToast.showFailure(with: BundleI18n.LarkChat.Lark_IM_EditMessage_FailedToEditDueToSpecificSettings_Toast(chat.name), on: window)
                return
            }
            if message.isRecalled || message.isDeleted {
                let dialog = UDDialog()
                dialog.setTitle(text: BundleI18n.LarkChat.Lark_IM_EditMessage_UnableToSaveChanges_Text)
                let content = message.isRecalled ? BundleI18n.LarkChat.Lark_IM_EditMessage_MessageRecalledUnableToSave_Title : BundleI18n.LarkChat.Lark_IM_EditMessage_MessageDeletedUnableToSave_Title
                dialog.setContent(text: content)
                dialog.addPrimaryButton(text: BundleI18n.LarkChat.Lark_IM_EditMessage_UnableToSave_GotIt_Button)
                if let vc = self.delegate?.baseViewController() {
                    navigator.present(dialog, from: vc)
                }
                return
            }

            callback()

            DispatchQueue.global(qos: .userInteractive).async {
                let lingoInfo = LingoConvertService.transformStringToQuasiContent(contentAttr)
                //没有改变任何内容点保存，则不执行任何操作
                if let oldMessageContent = self.keyboardView.keyboardStatusManager.multiEditingMessageContent {
                    if richText.isContentEqualTo(oldMessageContent.richText),
                       lingoInfo.isContentEqualTo(oldMessageContent.lingoInfo) {
                        if let oldTitle = oldMessageContent.title {
                            if oldTitle == title {
                                return
                            }
                        } else if title.isEmpty {
                            return
                        }
                    }
                }

                var chatId = chat.id
                self.requestMultiEditMessage(messageId: messageId,
                                             chatId: chatId,
                                             type: isPost ? .post : .text,
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
        self.viewModel.multiEditService?.multiEditMessage(messageId: messageId,
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
                    self.viewModel.multiEditService?.reloadEditEffectiveTimeConfig()
                default:
                    break
                }
                UDToast.showFailureIfNeeded(on: window, error: error)
            }.disposed(by: self.disposeBag)
    }

    override func didApplyPasteboardInfo() {
        self.updateAttachmentSizeFor(attributedText: self.keyboardView.attributedString)
        IMCopyPasteMenuTracker.trackPaste(chat: self.viewModel.chatModel,
                                          text: self.keyboardView.attributedString)
    }
}
// MARK: - MessengerChatKeyboardDependency
extension NormalChatInputKeyboard: MessengerNormalChatKeyboardDependency {
    var scheduleSendDraftChange: RxSwift.Observable<ScheduleSendDraftModel> {
        scheduleSendDraftChangeBehavior.asObservable().skip(1)
    }
    var returnType: UIReturnKeyType {
        self.keyboardView.inputTextView.returnKeyType
    }
}
