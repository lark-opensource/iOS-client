//
//  ChatInput.swift
//  Lark
//
//  Created by 刘晚林 on 2017/6/13.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import RxCocoa
import RxSwift
import LarkModel
import LarkUIKit
import LarkCore
import LarkBaseKeyboard
import LarkKeyboardView
import LarkMessengerInterface
import TangramService
import LarkContainer
import RustPB
import LarkCanvas
import EditTextView
import LarkFeatureGating
import LarkRustClient
import LarkFocus
import LarkFocusInterface
import LarkMessageCore
import LarkMessageBase
import EENavigator
import UniverseDesignToast
import LarkSDKInterface
import LKCommonsLogging
import LarkChatOpenKeyboard
import LarkOpenKeyboard

protocol ChatKeyboardDelegate: IMKeyboardDelegate, KeyboardRealTimeTranslateDelegate {
    func inputTextViewSaveDraft(id: DraftId, type: RustPB.Basic_V1_Draft.TypeEnum, content: String)
    func inputTextViewGetDraft(key: String) -> Observable<(content: String, partialReplyInfo: Basic_V1_Message.PartialReplyInfo?)>
    func closeRelatedMessageTipsView()
    func saveInputPostDraftWithReplyMessageInfo(_ info: KeyboardJob.ReplyInfo?)
    func saveScheduleDraft()
    func deleteScheduleDraft()
    func applyInputPostDraft(_ replyDraft: String)
    func updateAttachmentSizeFor(attributedText: NSAttributedString)
    func userFocusStatus() -> ChatterFocusStatus?
    func shouldReprocessPlaceholder() -> Bool
    func getTenantInputBoxPlaceholder() -> String?
    func replaceTenantInputPlaceholderEnable() -> Bool
    func getReplyTo(info: KeyboardJob.ReplyInfo, user: Chatter, result: @escaping (NSMutableAttributedString) -> Void)

    func onKeyboardJobChanged(oldJob: KeyboardJob?, currentJob: KeyboardJob)
    func keyboardWillExitJob(currentJob: KeyboardJob, newJob: KeyboardJob, triggerByGoBack: Bool)
    func clickChatMenuEntry()
    func didApplyPasteboardInfo()
    var chatFromWhere: ChatFromWhere { get }
    var shouldShowTenantPlaceholder: Bool { get }
    func pushProfile(chatterId: String)
    func getDisplayVC() -> UIViewController
    func keyboardAppearForSelectedPanel(item: KeyboardItemKey)
    func reloadItems()
    func reloadItemForKey(_ key: KeyboardItemKey)
}

public class ChatKeyboardView: MessengerKeyboardView, UserResolverWrapper {

    public var userResolver: UserResolver { viewModel.module.userResolver }
    static let logger = Logger.log(ChatKeyboardView.self, category: "Module.Inputs")
    public typealias MessageInlineProvider = (_ message: Message,
                                              _ elementID: String,
                                              _ font: UIFont,
                                              _ iconColor: UIColor,
                                              _ customAttributes: [NSAttributedString.Key: Any]) -> NSAttributedString?

    let disposeBag = DisposeBag()
    fileprivate var typingDisposeBag = DisposeBag()

    private let disableReplyBar: Bool

    lazy var inputManager: PostInputManager = {
        return PostInputManager(inputTextView: self.inputTextView)
    }()

    @ScopedInjectedLazy var urlPreviewAPI: URLPreviewAPI?

    private var chatType: LarkModel.Chat.TypeEnum {
        return chat.type
    }
    private var isBotChat: Bool {
        if let chatter = chat.chatter,
            chatter.type == .bot {
            return true
        }
        return false
    }
    private var isMeetingChat: Bool {
        return chat.isMeeting
    }

    private let chatWrapper: ChatPushWrapper

    var chat: Chat {
        return chatWrapper.chat.value
    }

    @ScopedInjectedLazy private var modelService: ModelService?
    @ScopedInjectedLazy private var rustClient: RustService?
    @ScopedInjectedLazy private var chatAPI: ChatAPI?
    let currentChatterId: String

    weak var chatKeyboardDelegate: ChatKeyboardDelegate? {
        didSet {
            self.delegate = self.chatKeyboardDelegate
        }
    }

    var titleEditView: TitleEditView?
    /// 输入框
    var titleTextView: LarkEditTextView? {
        return titleEditView?.textView
    }
    let supportRealTimeTranslate: Bool
    fileprivate var relatedMessageTipsView: RelatedMessageTipsView = RelatedMessageTipsView(frame: .zero)

    private var translationPreviewHeight: CGFloat = 39 {
        didSet {
            if translationPreviewHeight != oldValue,
               translationContainerView.superview != nil {
                translationContainerView.snp.updateConstraints { make in
                    make.height.equalTo(translationPreviewHeight)
                }
            }
        }
    }
    lazy var translationContainerView: TranslationInfoPreviewContainerView = {
        let translationContainerView = TranslationInfoPreviewContainerView(targetLanguage: chat.typingTranslateSetting.targetLanguage,
                                                                           displayable: chat.typingTranslateSetting.isOpen == true,
                                                                           maxLines: 3) { [weak self] (height) in
            guard let self = self else { return }
            self.translationPreviewHeight = height
        }
        translationContainerView.translationInfoPreviewView.delegate = self
        return translationContainerView
    }()

    override public var translationInfoPreviewView: TranslationInfoPreviewView {
        return translationContainerView.translationInfoPreviewView
    }

    override public var keyboardRealTimeTranslateDelegate: KeyboardRealTimeTranslateDelegate? {
        return self.chatKeyboardDelegate
    }

    /// 是否支持AtMyAI
    let suppportAtAI: Bool

    public init(chatWrapper: ChatPushWrapper,
                viewModel: IMKeyboardViewModel,
                suppportAtAI: Bool,
                currentChatterId: String,
                pasteboardToken: String,
                keyboardNewStyleEnable: Bool,
                supportRealTimeTranslate: Bool,
                disableReplyBar: Bool = false) {
        self.suppportAtAI = suppportAtAI
        self.currentChatterId = currentChatterId
        self.chatWrapper = chatWrapper
        self.supportRealTimeTranslate = supportRealTimeTranslate
        self.disableReplyBar = disableReplyBar
        super.init(frame: CGRect.zero,
                   viewModel: viewModel,
                   pasteboardToken: pasteboardToken,
                   keyboardNewStyleEnable: keyboardNewStyleEnable)
        self.inputTextView.gestureRecognizeSimultaneously = false
        // 更新 Pad icon 布局
        self.updateKeyboardIconLayoutIfNeeded()

        // 回复框
        if !supportRealTimeTranslate {
            self.inputStackView.insertArrangedSubview(relatedMessageTipsView, at: 0)
            relatedMessageTipsView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
            }
            self.controlContainer.snp.remakeConstraints { make in
                make.top.equalTo(self.relatedMessageTipsView.snp.bottom)
                make.left.equalToSuperview()
                make.right.equalToSuperview()
            }
        } else {
            self.inputStackView.insertArrangedSubview(translationContainerView, at: 0)
            self.inputContainerInnerTopView.addSubview(relatedMessageTipsView)
            relatedMessageTipsView.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(9)
                make.right.equalToSuperview().offset(-9)
            }
            relatedMessageTipsView.backgroundColor = UIColor.ud.bgBase
            relatedMessageTipsView.showContentInset = false
            relatedMessageTipsView.layer.cornerRadius = 4
            relatedMessageTipsView.clipsToBounds = true
            translationContainerView.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(10)
                make.right.equalToSuperview().offset(-10)
                make.height.equalTo(translationPreviewHeight)
                make.top.equalToSuperview()
            }
            self.controlContainer.snp.remakeConstraints { make in
                make.top.equalTo(self.translationContainerView.snp.bottom)
                make.left.equalToSuperview()
                make.right.equalToSuperview()
            }
        }
        relatedMessageTipsView.closeButton.addTarget(self, action: #selector(closeRelatedMessageTipsView), for: .touchUpInside)
        keyboardPanel.observeKeyboard = false
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        self.updateKeyboardIconLayoutIfNeeded()
    }

    public func insert(userName: String,
                       actualName: String,
                       userId: String = "",
                       isOuter: Bool = false) {
        if !userId.isEmpty {
            let info = AtChatterInfo(id: userId, name: userName, isOuter: isOuter, actualName: actualName)
            let atString = AtTransformer.transformContentToString(info,
                                                                  style: [:],
                                                                  attributes: inputManager.baseTypingAttributes())
            let mutableAtString = NSMutableAttributedString(attributedString: atString)
            mutableAtString.append(NSMutableAttributedString(string: " ", attributes: inputManager.baseTypingAttributes()))

            self.inputTextView.insert(mutableAtString, useDefaultAttributes: false)
        } else {
            self.inputTextView.insertText(userName)
        }
        self.inputTextView.becomeFirstResponder()
        self.reloadSendButton()
        if case .multiEdit = keyboardStatusManager.currentKeyboardJob {
            updateTipIfNeed(.atWhenMultiEdit)
        }
    }

    public func insertUrl(title: String, url: URL, type: RustPB.Basic_V1_Doc.TypeEnum) {
        let content: LinkTransformer.DocInsertContent = (title, type, url, "")
        let urlString: String = url.absoluteString
        let defaultTypingAttributes = inputTextView.baseDefaultTypingAttributes
        let urlAttributedString = NSAttributedString(string: urlString, attributes: inputManager.baseTypingAttributes())
        self.inputTextView.insert(urlAttributedString, useDefaultAttributes: false)

        guard let url = URL(string: urlString) else {
            Self.logger.info("insertUrl urlString is not URL")
            return
        }

        let attributedText = NSMutableAttributedString(attributedString: self.inputTextView.attributedText ?? NSAttributedString())
        /// 这里与产品沟通 粘贴的文字不携带样式，使用原有样式
        let replaceStr = LinkTransformer.transformToDocAttr(content, attributes: defaultTypingAttributes)
        let range = (attributedText.string as NSString).range(of: urlString)
        if range.location != NSNotFound {
            attributedText.replaceCharacters(in: range, with: replaceStr)
            self.inputTextView.attributedText = attributedText
        } else {
            Self.logger.info("urlPreviewAPI range.location is not Found")
        }
        // 重置光标
        self.inputTextView.selectedRange = NSRange(location: range.location + replaceStr.length, length: 0)
        self.inputTextView.becomeFirstResponder()
        self.keyboardPanel.reloadPanelBtn(key: KeyboardItemKey.send.rawValue)
    }

    public func insertUrl(urlString: String) {
        let defaultTypingAttributes = inputTextView.baseDefaultTypingAttributes
        let urlAttributedString = NSAttributedString(string: urlString, attributes: inputManager.baseTypingAttributes())
        self.inputTextView.insert(urlAttributedString, useDefaultAttributes: false)

        guard let url = URL(string: urlString) else {
            Self.logger.info("insertUrl urlString is not URL")
            return
        }
        self.urlPreviewAPI?.generateUrlPreviewEntity(url: urlString)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] inlineEntity, _ in
                // 三端对齐，title为空时不进行替换
                guard let self = self, let entity = inlineEntity, !(entity.title ?? "").isEmpty else {
                    Self.logger.info("urlPreviewAPI res title is Emtpy")
                    return
                }
                let attributedText = NSMutableAttributedString(attributedString: self.inputTextView.attributedText ?? NSAttributedString())
                /// 这里与产品沟通 粘贴的文字不携带样式，使用原有样式
                let replaceStr = LinkTransformer.transformToURLAttr(entity: entity, originURL: url, attributes: defaultTypingAttributes)
                let range = (attributedText.string as NSString).range(of: urlString)
                if range.location != NSNotFound {
                    attributedText.replaceCharacters(in: range, with: replaceStr)
                    self.inputTextView.attributedText = attributedText
                } else {
                    Self.logger.info("urlPreviewAPI range.location is not Found")
                }
                // 重置光标
                self.inputTextView.selectedRange = NSRange(location: range.location + replaceStr.length, length: 0)
                self.inputTextView.becomeFirstResponder()
                self.reloadSendButton()
            })
            .disposed(by: self.disposeBag)
    }

    public func insertEmoji(_ emoji: String) {
        let selectedRange: NSRange = self.inputTextView.selectedRange
        if self.textViewInputProtocolSet.textView(self.inputTextView, shouldChangeTextIn: selectedRange, replacementText: emoji) {
            let emojiStr = EmotionTransformer.transformContentToString(emoji, attributes: inputManager.baseTypingAttributes())
            self.inputTextView.insert(emojiStr, useDefaultAttributes: false)
        }
        self.reloadSendButton()
    }

    public func insertString(_ str: String) {
        self.inputTextView.insert(NSAttributedString(string: str), useDefaultAttributes: true)
    }

    @objc
    private func closeRelatedMessageTipsView() {
        self.chatKeyboardDelegate?.closeRelatedMessageTipsView()
    }

    public func textViewDidBeginEditing(_ textView: UITextView) {
        var trackChatType: ChatTracker.ChatType = .group
        if self.isMeetingChat {
            trackChatType = .meeting
        } else if self.chatType != .group {
            trackChatType = self.isBotChat ? .single_bot : .single
        }

        ChatTracker.typingInputActive(
            isFirst: true,
            chatType: trackChatType,
            location: .message_input)

        var text = self.inputTextView.text
        Observable<Int>.interval(.seconds(5), scheduler: MainScheduler.instance).subscribe(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            if text != self.inputTextView.text {
                text = self.inputTextView.text
                ChatTracker.typingInputActive(
                    isFirst: false,
                    chatType: trackChatType,
                    location: .message_input)

            }
        }).disposed(by: self.typingDisposeBag)
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        self.keyboardPanel.observeKeyboard = false
        // iPad 同一时间可能存在多个输入框切换的情况
        // 失去焦点收起键盘
        // 这里需要延时判断，如果 KeyboardView 仍是第一响应，则不收起键盘
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self else { return }
            if self.keyboardPanel.selectIndex == nil &&
                Display.pad &&
                !self.hasFirstResponder() {
                self.keyboardPanel.closeKeyboardPanel(animation: true)
            }
        }
        self.typingDisposeBag = DisposeBag()
    }

    /// text消息😊在relatedMessageTipsView以😊存在，post消息😊在relatedMessageTipsView以[微笑]存在，和pm确认过，先保持现状，后续会统一
    /// text消息支持docsUrl转icon+title，post不支持
    private func updateRelatedMessageBar(info: KeyboardJob.ReplyInfo?, showCloseButton: Bool) {
        guard self.relatedMessageTipsView.superview != nil else {
            return
        }
        if let info = info, let user = info.message.fromChatter {
            let message = info.message
            relatedMessageTipsView.show(true, showCloseButton: showCloseButton)
            self.chatKeyboardDelegate?.getReplyTo(
                info: info,
                user: user,
                result: { [weak self] mutableAttributedString in
                    mutableAttributedString.mutableString.replaceOccurrences(
                        of: "\n",
                        with: " ",
                        options: [],
                        range: NSRange(location: 0, length: mutableAttributedString.length)
                    )
                    if message.isMultiEdited, info.partialReplyInfo == nil {
                        mutableAttributedString.append(.init(string: BundleI18n.LarkChat.Lark_IM_EditMessage_Edited_Label,
                                                             attributes: [.font: UIFont.systemFont(ofSize: 12),
                                                                          .foregroundColor: UIColor.ud.textPlaceholder]))
                    }
                    self?.relatedMessageTipsView.tipsContent = mutableAttributedString
                    if self?.window != nil {
                        self?.layoutIfNeeded()
                    }
                })
        } else {
            relatedMessageTipsView.show(false, showCloseButton: showCloseButton)
            self.relatedMessageTipsView.tipsContent = NSAttributedString(string: "")
            if self.window != nil {
                self.layoutIfNeeded()
            }
        }
        updateinputContainerInnerExpandViewForHeight(self.relatedMessageTipsView.currentHeight)
    }

    private func updateinputContainerInnerExpandViewForHeight(_ height: CGFloat) {
        guard self.supportRealTimeTranslate,
              self.relatedMessageTipsView.superview != nil,
              self.inputContainerInnerTopView.superview != nil,
              self.inputContainerInnerBottomView.superview != nil else {
            return
        }
        let offset: CGFloat = height > 0 ? 9 : 0
        self.relatedMessageTipsView.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(9)
            make.top.equalToSuperview().offset(offset)
            make.right.equalToSuperview().offset(-9)
            make.bottom.equalToSuperview()
        }
        self.inputContainerInnerTopView.snp.updateConstraints { make in
            make.height.equalTo(max(0, (height + offset)))
        }
    }
    /// 更新回复的草稿
    func updateReplyInputText(newReply: LarkModel.Message?,
                              oldReply: LarkModel.Message?,
                              hasDraftCallback: @escaping (Bool, PartialReplyInfo?) -> Void = { _, _ in }) {
        if oldReply?.id == newReply?.id {
            return
        }
        /// 获取当前的输入
        var attributedText = self.richTextStr
        if let message = keyboardStatusManager.getMultiEditMessage() {
            self.chatKeyboardDelegate?.inputTextViewSaveDraft(id: .multiEditMessage(messageId: message.id, chatId: self.chat.id), type: .text, content: attributedText)
        } else if let oldReply = oldReply {
            self.chatKeyboardDelegate?.inputTextViewSaveDraft(id: .replyMessage(messageId: oldReply.id), type: .text, content: attributedText)
        } else {
            self.chatKeyboardDelegate?.inputTextViewSaveDraft(id: .chat(chatId: self.chat.id), type: .text, content: attributedText)
        }

        if let newReply = newReply {
            let getDraftCompletion: (String) -> Void = { [weak self] (replyDraft) in
                guard let self = self else { return }
                if !replyDraft.isEmpty {
                    if !self.updateTextViewForTextDraftStr(replyDraft) {
                        let draft = NSAttributedString(
                            string: replyDraft,
                            attributes: self.inputTextView.defaultTypingAttributes
                        )
                        let content = OldVersionTransformer.transformInputText(draft)
                        self.attributedString = content
                    }
                } else {
                    self.attributedString = NSAttributedString(string: "")
                }
                hasDraftCallback(replyDraft.isEmpty == false, nil)
            }

            if newReply.textDraftId.isEmpty {
                getDraftCompletion("")
                return
            }
            self.chatKeyboardDelegate?
                .inputTextViewGetDraft(key: newReply.textDraftId)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { replyDraft in
                    getDraftCompletion(replyDraft.content)
                }).disposed(by: self.disposeBag)
        } else {
            let getDraftCompletion: (String) -> Void = { [weak self] (chatDraft) in
                guard let self = self else { return }
                if !chatDraft.isEmpty {
                    if !self.updateTextViewForTextDraftStr(chatDraft) {
                        self.attributedString = NSAttributedString(string: "")
                    }
                } else {
                    self.attributedString = NSAttributedString(string: "")
                }
            }
            if chat.textDraftId.isEmpty {
                getDraftCompletion("")
                return
            }
            self.chatKeyboardDelegate?
                .inputTextViewGetDraft(key: chat.textDraftId)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { chatDraft in
                    getDraftCompletion(chatDraft.content)
                }).disposed(by: self.disposeBag)
        }
    }

    /// 在 iPad c 视图下键盘布局根据 cr 变化动态更新
    private func updateKeyboardIconLayoutIfNeeded() {
        guard Display.pad && !self.keyboardNewStyleEnable else {
            return
        }
        /// 判断是否需要更新
        if let lastHorizontalSizeClass = lastHorizontalSizeClass,
            lastHorizontalSizeClass == self.traitCollection.horizontalSizeClass {
            return
        }
        lastHorizontalSizeClass = self.traitCollection.horizontalSizeClass
        updateKeyboardPanelLayout()
    }

    private func updateKeyboardPanelLayout() {
        /// 根据 sizeClass 更新布局
        if keyboardNewStyleEnable {
            self.keyboardPanel.layout = Display.pad ? .left(26) : .left(20)
            return
        }
        if self.traitCollection.horizontalSizeClass == .compact {
            switch keyboardStatusManager.currentKeyboardJob {
            case .multiEdit, .scheduleSend, .scheduleMsgEdit:
                self.keyboardPanel.layout = Display.pad ? .left(26) : .left(20)
            default:
                self.keyboardPanel.layout = .average
            }
        } else {
            self.keyboardPanel.layout = .left(26)
        }
    }

    public override func setSubViewsEnable(enable: Bool) {
        var realEnable = enable
        /// 所有chat 业务下 如果isAllowPost = false，键盘应该不可用
        if !chat.isAllowPost {
            realEnable = false
        }
        if realEnable != enable {
            assertionFailure("you set enable should care for chat.isAllowPost")
        }
        super.setSubViewsEnable(enable: realEnable)
    }

    /// 拼接表情
    public override func updatePlaceholder(placeholder: String) {
        super.updatePlaceholder(placeholder: placeholder)
        /// 如果不允许再次处理占位文字 直接返回
        guard self.chatKeyboardDelegate?.shouldReprocessPlaceholder() ?? true else { return }
        /// 满足条件就拼接 ->个人状态
        if let status = self.chatKeyboardDelegate?.userFocusStatus(),
            let attributedPlaceholder = inputTextView.attributedPlaceholder,
            let image = FocusManager.getFocusIcon(byKey: status.iconKey) {

            let muAttr = NSMutableAttributedString(attributedString: attributedPlaceholder)
            muAttr.append(NSAttributedString(string: "  "))
            let font = (self.placeholderTextAttributes[.font] as? UIFont) ?? UIFont.ud.body0
            let attachment = InputUtil.textAttachmentForImage(image, font: font)
            let attachmentStr = NSMutableAttributedString(attachment: attachment)
            attachmentStr.append(NSAttributedString(string: " "))
            attachmentStr.append(NSAttributedString(string: status.title))
            attachmentStr.addAttributes(self.placeholderTextAttributes, range: NSRange(location: 0, length: attachmentStr.length))
            muAttr.append(attachmentStr)
            self.inputTextView.attributedPlaceholder = muAttr
        }

        if self.chatKeyboardDelegate?.shouldShowTenantPlaceholder == true,
           let tenantPlaceholder = self.chatKeyboardDelegate?.getTenantInputBoxPlaceholder() {
            // 替换规则生效
            if self.chatKeyboardDelegate?.replaceTenantInputPlaceholderEnable() ?? false {
                self.inputTextView.attributedPlaceholder = NSAttributedString(string: tenantPlaceholder,
                                                                              attributes: self.placeholderTextAttributes)
            } else {
                if let attributedPlaceholder = self.inputTextView.attributedPlaceholder {
                    let muAttr = NSMutableAttributedString(attributedString: attributedPlaceholder)
                    ///这里做个安全校验 -> 如果原来的attributedPlaceholder不为空，再拼接分割符" | "
                    if !muAttr.string.isEmpty {
                        let font = (self.placeholderTextAttributes[.font] as? UIFont) ?? UIFont.ud.body0
                        muAttr.append(TextSplitConstructor.splitTextAttributeStringFor(font: font))
                    }
                    muAttr.append(NSAttributedString(string: tenantPlaceholder,
                                                     attributes: self.placeholderTextAttributes))
                    self.inputTextView.attributedPlaceholder = muAttr
                }
            }
        }
    }

    private var lastHorizontalSizeClass: UIUserInterfaceSizeClass?

    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        observeKeyboard()
        return true
    }

    func observeKeyboard() {
        if !self.keyboardPanel.observeKeyboard {
            self.keyboardPanel.resetContentHeight()
        }
        self.keyboardPanel.observeKeyboard = true
    }

    func updateTextViewForTextDraftStr(_ draftStr: String) -> Bool {
        if draftStr.isEmpty {
            return false
        }
        var update = false
        let model = TextDraftModel.parse(draftStr)
        if model.unarchiveSuccess {
            self.richText = try? RustPB.Basic_V1_RichText(jsonString: model.content) ?? RustPB.Basic_V1_RichText()
            AtTransformer.getAllChatterInfoForAttributedString(self.attributedString).forEach { chatterInfo in
                chatterInfo.actualName = model.userInfoDic[chatterInfo.id] ?? ""
            }
            update = true
        } else if let richText = try? RustPB.Basic_V1_RichText(jsonString: draftStr) {
            self.richText = richText
            update = true
        }
        return update
    }

    func clearTranslationPreview() {
        self.translationInfoPreviewView.clearData()
    }

    func updateTextViewData(_ item: ComposePostItem,
                            translateInfo: (title: String?, content: RustPB.Basic_V1_RichText?),
                            recallEnable: Bool,
                            keyboardCanBecomeFirstResponder: Bool) {}

    public override func getKeyboardTitle() -> NSAttributedString? {
        return titleTextView?.attributedText
    }

    public override func updateKeyboardTitle(_ value: NSAttributedString?) {
        if let titleAttr = value {
            titleTextView?.attributedText = titleAttr
        }
    }

    public override func willExitJob(currentJob: KeyboardJob, newJob: KeyboardJob, triggerByGoBack: Bool) {
        super.willExitJob(currentJob: currentJob, newJob: newJob, triggerByGoBack: triggerByGoBack)
        chatKeyboardDelegate?.keyboardWillExitJob(currentJob: currentJob, newJob: newJob, triggerByGoBack: triggerByGoBack)
    }

    public override func updateUIForKeyboardJob(oldJob: KeyboardJob?, currentJob: KeyboardJob) {
        super.updateUIForKeyboardJob(oldJob: oldJob, currentJob: currentJob)
        /// panel 布局完成之后 再重新刷新Item
        updateKeyboardPanelLayout()
        keyboardPanel.panelTopBar.layoutIfNeeded()
        chatKeyboardDelegate?.onKeyboardJobChanged(oldJob: oldJob, currentJob: currentJob)

        var replyMessage: Message?
        let info: KeyboardJob.ReplyInfo? = keyboardStatusManager.getRelatedDispalyReplyInfo(for: currentJob)
        let relatedMessageBarShowCloseButton = getReplyBarShowCloseButton(keyboardJob: currentJob)
        switch currentJob {
        case .reply(let info):
            replyMessage = info.message
        default:
            break
        }
        if !self.disableReplyBar {
            self.updateRelatedMessageBar(info: info, showCloseButton: relatedMessageBarShowCloseButton)
        }
        self.updateExpandType()
        if oldJob == nil {
            //第一次调用时，不走下面逻辑
            return
        }
        var oldReplyMessage: Message?
        switch oldJob {
        case .reply(let info):
            oldReplyMessage = info.message
        default:
            break
        }
        // 如果有reply无草稿并且之前是定时发送，带回复态切换定时发送
        let updateReplyInputTextCallback: (Bool, PartialReplyInfo?) -> Void = { [weak self] (isHasReplyDraft, partialReplyInfo) in
            guard let self = self else { return }
            if !isHasReplyDraft {
                switch oldJob {
                case .scheduleSend(let msg):
                    if msg == nil {
                        self.keyboardStatusManager.switchJobWithoutReplaceLastStatus(.scheduleSend(info: info))
                        self.chatKeyboardDelegate?.deleteScheduleDraft()
                    }
                default:
                    break
                }
            }
            if let partialReplyInfo = partialReplyInfo, let job = currentJob.updateJobPartialReplyInfo(partialReplyInfo) {
                self.keyboardStatusManager.switchJob(job)
            }
        }
        if oldReplyMessage?.id != replyMessage?.id,
           //新job是normal或reply时走这个逻辑
           (currentJob == .normal || replyMessage != nil) {
            self.updateReplyInputText(newReply: replyMessage,
                                      oldReply: oldReplyMessage,
                                      hasDraftCallback: updateReplyInputTextCallback)
        }
    }

    public override func keyboardJobAssociatedValueChanged(currentJob: KeyboardJob) {
        super.keyboardJobAssociatedValueChanged(currentJob: currentJob)
        let info = keyboardStatusManager.getRelatedDispalyReplyInfo(for: currentJob)
        let relatedMessageBarShowCloseButton = getReplyBarShowCloseButton(keyboardJob: currentJob)
        if !self.disableReplyBar {
            self.updateRelatedMessageBar(info: info, showCloseButton: relatedMessageBarShowCloseButton)
        }
    }

    private func getReplyBarShowCloseButton(keyboardJob: KeyboardJob) -> Bool {
        switch keyboardJob {
        case .reply, .scheduleSend:
            return true
        default:
            return false
        }
    }

    // MARK: - 边写边译
    override open func beginTranslateTitle() {
        self.translationInfoPreviewView.isTitleLoading = true
    }

    override open func onUpdateTitleTranslation(_ text: String) {
        self.translationInfoPreviewView.editType = .title(text)
        self.translationInfoPreviewView.isTitleLoading = false
    }

    override open func didClickApplyTranslationItem() {
        guard let data = keyboardRealTimeTranslateDelegate?.getTranslationResult() else { return }
        if data.0?.isEmpty == false {
            self.titleTextView?.text = data.0
        }
        super.didClickApplyTranslationItem()
    }

    override open func didClickCloseTranslationItem() {
        IMTracker.Chat.Main.Click.closeTranslation(self.chat, (self.chatKeyboardDelegate?.chatFromWhere ?? ChatFromWhere.default()).rawValue, location: .chat_view)
        chatAPI?.updateChat(chatId: self.chat.id, isRealTimeTranslate: false, realTimeTranslateLanguage: self.chat.typingTranslateSetting.targetLanguage)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                self?.translationInfoPreviewView.setDisplayable(false)
            }, onError: { [weak self] (error) in
                // 把服务器返回的错误显示出来
                let showMessage = BundleI18n.LarkChat.Lark_Setting_PrivacySetupFailed
                if let view = self {
                    UDToast.showFailure(with: showMessage, on: view, error: error)
                }
            }).disposed(by: self.disposeBag)
    }

    override open func didClickRecallTranslationItem() {
        guard let data = self.keyboardRealTimeTranslateDelegate?.getOriginContentBeforeTranslate() else { return }
        if data.0?.isEmpty == false {
            self.titleTextView?.text = data.0
        }
        super.didClickRecallTranslationItem()
    }
}

extension ChatKeyboardView: OpenKeyboardService {
    public func displayVC() -> UIViewController {
        return self.chatKeyboardDelegate?.getDisplayVC() ?? UIViewController()
    }

    public func keyboardAppearForSelectedPanel(item: KeyboardItemKey) {
        self.chatKeyboardDelegate?.keyboardAppearForSelectedPanel(item: item)
    }

    public func reloadPaneItems() {
        self.chatKeyboardDelegate?.reloadItems()
    }

    public func foldKeyboard() {
        self.fold()
    }
    public func reloadPaneItemForKey(_ key: KeyboardItemKey) {
        self.chatKeyboardDelegate?.reloadItemForKey(key)
    }
}
