//
//  CryptoChatInputKeyboard.swift
//  LarkChat
//
//  Created by zhaojiachen on 2022/2/21.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import Photos
import LarkModel
import LarkCore
import LarkRichTextCore
import LarkKeyboardView
import LKCommonsLogging
import EditTextView
import LarkAudio
import LarkAlertController
import LarkFeatureGating
import LarkKAFeatureSwitch
import LarkSDKInterface
import LarkMessengerInterface
import LarkMessageCore
import LarkContainer
import LarkEmotion
import RustPB
import LarkEmotionKeyboard
import ByteWebImage
import TangramService
import LarkStorage
import LarkOpenChat
import LarkRustClient
import LKCommonsTracker
import LarkMessageBase
import LarkAccountInterface
import LarkSendMessage
import LarkFocusInterface
import LarkBaseKeyboard
import LarkChatOpenKeyboard

public final class CryptoChatInputKeyboard: ChatBaseInputKeyboard {
    @ScopedInjectedLazy private var modelService: ModelService?
    @ScopedInjectedLazy private var messageBurntService: MessageBurnService?
    @ScopedInjectedLazy private var rustClient: RustService?
    @ScopedInjectedLazy private var secretChatService: SecretChatService?

    private var emotionKeyboard: EmotionKeyboardProtocol? {
        let module: IMCryptoChatKeyboardEmojiPanelSubModule? = self.getPanelSubModuleForItemKey(key: .emotion)
        return module?.emotionKeyboard
    }

    override var audioKeyboardHelper: AudioRecordPanelProtocol? {
        let module: IMCryptoChatKeyboardVoicePanelSubModule? = self.getPanelSubModuleForItemKey(key: .voice)
        return module?.audioKeyboardHelper
    }

    //发资源类消息管理类
    lazy var assetManager: AssetPreProcessManager = {
        return AssetPreProcessManager(userResolver: userResolver, isCrypto: true)
    }()

    public override init(viewModel: DefaultInputViewModel,
                module: BaseChatKeyboardModule,
                delegate: ChatInputKeyboardDelegate?,
                keyboardView: ChatKeyboardView) {
        super.init(viewModel: viewModel,
                   module: module,
                   delegate: delegate,
                   keyboardView: keyboardView
        )
    }

    override func keyboardItems(moreItemsDriver: Driver<[ChatKeyboardMoreItem]>) -> [InputKeyboardItem] {
        let module: IMCryptoChatKeyboardMorePanelSubModule? = self.getPanelSubModuleForItemKey(key: .more)
        module?.itemDriver = moreItemsDriver
        keyboardView.viewModel.module.reloadPanelItems()
        return keyboardView.viewModel.panelItems
    }

    /// 根据草稿信息更新UI
    override func updateInputViewWith(draftInfo: DraftInfo) {
        // 当键盘不是第一响应者并且草稿更新的时候，需要刷新
        let isFirstResponder = self.keyboardView.inputTextView.isFirstResponder
        if !isFirstResponder {
            // 由于 message 与 chat 的 draftID 没有更新
            // 直接使用 draft 刷新UI
            self.updateDraftContent(by: draftInfo.content)
        }
    }

    override func setupStartupKeyboardState() {
        guard let keyboardStartupState = self.delegate?.getKeyboardStartupState() else {
            assertionFailure()
            Self.logger.error("取不到 keyboard state")
            return
        }
        guard case .inputView = keyboardStartupState.type else {
            return
        }
        // 如果存在文字则聚焦输入框
        if self.keyboardView.attributedString.length > 0 {
            self.keyboardView.inputViewBecomeFirstResponder()
        }
    }

    public override func reEditMessage(message: Message) {
        let supportType: [Message.TypeEnum] = [.text]
        guard supportType.contains(message.type) else {
            return
        }
        Self.logger.info("reedit message type \(message.type)")

        if let parentMessage = message.parentMessage {
            let info = KeyboardJob.ReplyInfo(message: parentMessage, partialReplyInfo: nil)
            keyboardView.keyboardStatusManager.switchJob(.reply(info: info))
        }
        switch message.type {
        case .text:
            self.setupTextMessage(message: message)
        @unknown default:
            break
        }
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
            quasiMsgCreateByNative: false,
            preprocessResourceKey: nil
        )
    }

    public override func sendText(content: RustPB.Basic_V1_RichText, lingoInfo: RustPB.Basic_V1_LingoOption?, parentMessage: Message?) {
        self.viewModel.messageSender?.sendText(
            content: content,
            lingoInfo: nil,
            parentMessage: parentMessage,
            chatId: self.viewModel.chatModel.id,
            position: self.viewModel.chatModel.lastMessagePosition,
            quasiMsgCreateByNative: false,
            callback: nil
        )
    }

    // MARK: - ChatKeyboardDelegate Override
    public override func inputTextViewSend(attributedText: NSAttributedString, scheduleTime: Int64?) {
        if !attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            var attributedText = attributedText
            attributedText = RichTextTransformKit.preproccessSendAttributedStr(attributedText)
            self.onInputFinished()
            if let richText = RichTextTransformKit.transformStringToRichText(string: attributedText) {
                let lastMessagePosition: Int32 = self.viewModel.chatModel.lastMessagePosition
                let chatId: String = self.viewModel.chatModel.id
                if let messageModel = self.viewModel.replyMessage {
                    // 回复消息成功后，需要清空Chat的草稿
                    self.viewModel.draftCache?.saveDraft(chatId: self.viewModel.chatModel.id, type: .text, content: "", callback: nil)
                    let parentMessage = messageModel
                    self.viewModel.messageSender?.sendText(content: richText,
                                                           lingoInfo: nil,
                                                           parentMessage: parentMessage,
                                                           chatId: chatId,
                                                           position: lastMessagePosition,
                                                           quasiMsgCreateByNative: false,
                                                           callback: nil)
                    self.viewModel.cleanReplyMessage()
                } else {
                    self.viewModel.messageSender?.sendText(content: richText,
                                                           lingoInfo: nil,
                                                           parentMessage: self.viewModel.rootMessage,
                                                           chatId: chatId,
                                                           position: lastMessagePosition,
                                                           quasiMsgCreateByNative: false,
                                                           callback: nil)
                }
                self.saveInputViewDraft()
                /// 添加发消息埋点 记录是在哪一个 scene 发出的消息
                if let baseVC = self.delegate?.baseViewController() {
                    ChatTracker.trackSendMessageScene(chat: self.viewModel.chatModel, in: baseVC)
                }
            }
        }
        self.audioKeyboardHelper?.trackAudioRecognizeIfNeeded()
    }

    /// 密聊不支持复制字体样式
    public override func supportFontStyle() -> Bool {
        return false
    }

    public override func inputTextViewDidChange(input: LKKeyboardView) {
        self.emotionKeyboard?.updateActionBarEnable()
    }

    public override func getReplyTo(info: KeyboardJob.ReplyInfo, user: Chatter, result: @escaping (NSMutableAttributedString) -> Void) {
        let message = info.message
        let iconColor = UIColor.ud.iconN3
        let paragraphStyle = NSMutableParagraphStyle()
        /// 这里只展示一行，尽可能多的展示内容
        // swiftlint:disable ban_linebreak_byChar
        paragraphStyle.lineBreakMode = .byCharWrapping
        // swiftlint:enable ban_linebreak_byChar
        let textAttribute: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.ud.textPlaceholder,
            .font: UIFont.ud.body2,
            .paragraphStyle: paragraphStyle,
            MessageInlineViewModel.iconColorKey: iconColor,
            MessageInlineViewModel.tagTypeKey: TagType.normal
        ]
        let displayName: String
        if self.viewModel.chatModel.type == .p2P, user.id != userResolver.userID {
            displayName = BundleI18n.LarkChat.Lark_IM_SecureChatUser_Title
        } else {
            displayName = self.getDisplayName(chatter: user) ?? user.displayName
        }
        /// 添加“回复 ”文案
        let replyDisplayName = BundleI18n.LarkChat.Lark_Legacy_ReplySomebody(displayName)
        let mutableAttributedString = NSMutableAttributedString(string: "\(replyDisplayName): ", attributes: textAttribute)
        var messageSummerize: NSMutableAttributedString = NSMutableAttributedString(string: "")
        func parseInvalidMessage(_ text: String) {
            messageSummerize = NSMutableAttributedString(string: text)
            messageSummerize.addAttributes(textAttribute, range: NSRange(location: 0, length: messageSummerize.length))
            mutableAttributedString.append(messageSummerize)
            result(mutableAttributedString)
        }
        if message.isDeleted {
            parseInvalidMessage(BundleI18n.LarkChat.Lark_Legacy_MessageRemove)
            return
        }
        if message.isRecalled {
            parseInvalidMessage(BundleI18n.LarkChat.Lark_Legacy_MessageWithdrawMessage)
            return
        }
        if message.isSecretChatDecryptedFailed {
            parseInvalidMessage(BundleI18n.LarkChat.Lark_IM_SecureChat_UnableLoadMessage_Text)
            return
        }
        if messageBurntService?.isBurned(message: message) ?? false {
            parseInvalidMessage(BundleI18n.LarkChat.Lark_Legacy_MessageBurned)
            return
        }
        if message.type == .text {
            let parseText: (TextContent?) -> Void = { [userResolver]textContent in
                if let textContent = textContent {
                    // 密聊未接入URL中台
                    let textDocsVM = TextDocsViewModel(userResolver: userResolver, richText: textContent.richText, docEntity: textContent.docEntity)
                    let parseRichText = textDocsVM.parseRichText(
                        checkIsMe: nil,
                        needNewLine: false,
                        iconColor: iconColor,
                        customAttributes: textAttribute
                    )
                    messageSummerize = parseRichText.attriubuteText
                    messageSummerize.addAttributes(textAttribute, range: NSRange(location: 0, length: messageSummerize.length))
                }
            }
            var textContent: TextContent?
            if !message.cryptoToken.isEmpty {
                DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                    textContent = try? self?.getRealContent(token: message.cryptoToken)
                    DispatchQueue.main.async {
                        parseText(textContent)
                        mutableAttributedString.append(messageSummerize)
                        result(mutableAttributedString)
                    }
                }
                return
            } else {
                textContent = message.content as? TextContent
                parseText(textContent)
            }
        } else {
            /// 其他情况按照原来的逻辑来处理，用modelService去描述
            if let modelService {
                messageSummerize = NSMutableAttributedString(string: modelService.messageSummerize(message))
                messageSummerize.addAttributes(textAttribute, range: NSRange(location: 0, length: messageSummerize.length))
            }
        }
        mutableAttributedString.append(messageSummerize)
        result(mutableAttributedString)
    }

    private func getRealContent(token: String) throws -> TextContent? {
        guard let rustClient else { throw RCError.cancel }
        var request = RustPB.Im_V1_GetDecryptedContentRequest()
        request.decryptedTokens = [token]
        let res: RustPB.Im_V1_GetDecryptedContentResponse = try rustClient.sendSyncRequest(request)
        if let content = res.contents[token] {
            let textContent = TextContent(
                text: content.text,
                previewUrls: content.previewUrls,
                richText: content.richText,
                docEntity: nil,
                abbreviation: nil,
                typedElementRefs: nil
            )
            return textContent
        }
        return nil
    }

    override func onKeyboardJobChanged(oldJob: KeyboardJob?, currentJob: KeyboardJob) {
        super.onKeyboardJobChanged(oldJob: oldJob, currentJob: currentJob)
        self.updateInputPlaceHolder()
        self.audioKeyboardHelper?.cleanAudioRecognizeState()
        switch currentJob {
        case .reply:
            break
        default:
            if case .reply = oldJob {
                self.delegate?.onExitReply()
            }
        }
    }

    override func userFocusStatus() -> ChatterFocusStatus? {
        return nil
    }

    override func updateInputPlaceHolder() {
        shouldShowTenantPlaceholder = false
        if self.viewModel.chatModel.isAllowPost {
            if self.viewModel.chatModel.type == .p2P {
                self.keyboardView.inputPlaceHolder = ""
            } else {
                self.keyboardView.inputPlaceHolder = BundleI18n.LarkChat.Lark_Legacy_SendTip(self.viewModel.chatModel.displayWithAnotherName)
            }
        } else {
            if self.viewModel.chatModel.isFrozen {
                self.keyboardView.inputPlaceHolder = BundleI18n.LarkChat.Lark_IM_CantSendMsgThisDisbandedGrp_Desc
            } else {
                let isBannedPost = self.viewModel.chatModel.adminPostSetting == .bannedPost
                let placeHolder = isBannedPost ? BundleI18n.LarkChat.Lark_IM_Chatbox_UnableToSendMessagesInProhibitedGroup_Placeholder :
                BundleI18n.LarkChat.Lark_Group_GroupSettings_MsgRestriction_YouAreBanned_InputHint
                self.keyboardView.inputPlaceHolder = placeHolder
            }
        }
    }
}
