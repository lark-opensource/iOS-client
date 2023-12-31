//
//  ChatKeyboardServiceIMP.swift
//  LarkChat
//
//  Created by liluobin on 2023/5/14.
//

import UIKit
import LarkChatOpenKeyboard
import LarkKeyboardView
import LarkFeatureGating
import LarkBaseKeyboard
import LarkOpenChat
import LarkCore
import LarkAccountInterface
import LarkSDKInterface
import LarkAttachmentUploader
import LarkMessageCore
import LarkOpenKeyboard
import LarkModel
import RxSwift
import RustPB
import LarkMessengerInterface
import LarkFocusInterface
import EditTextView
import LarkChatKeyboardInterface
import LarkSendMessage
import LarkAIInfra

/// ChatKeyboardContext 是否必须
/// 1. 怎样才能保证后续功能的拓展
/// 2. 禁止粘贴的这些行为
/// 3. more的whitelist指定
class ChatKeyboardMessageSendServiceImp: ChatKeyboardMessageSendService {
    let moreSendService: KeyboardMoreItemSendService?
    let keyboardSendService: ChatOpenKeyboardSendService?
    let aiService: AIQuickActionSendService?
    init(moreSendService: KeyboardMoreItemSendService?,
         keyboardSendService: ChatOpenKeyboardSendService?,
         aiService: AIQuickActionSendService?) {
        self.moreSendService = moreSendService
        self.keyboardSendService = keyboardSendService
        self.aiService = aiService
    }

    func sendText(content: RustPB.Basic_V1_RichText,
                  lingoInfo: RustPB.Basic_V1_LingoOption?,
                  parentMessage: LarkModel.Message?,
                  chatId: String,
                  position: Int32,
                  scheduleTime: Int64?,
                  quasiMsgCreateByNative: Bool,
                  callback: ((LarkSendMessage.SendMessageState) -> Void)?) {
        self.keyboardSendService?.sendText(content: content,
                      lingoInfo: lingoInfo,
                      parentMessage: parentMessage,
                      chatId: chatId,
                      position: position,
                      scheduleTime: scheduleTime,
                      quasiMsgCreateByNative: quasiMsgCreateByNative,
                      callback: callback)
    }

    func sendText(content: RustPB.Basic_V1_RichText,
                  lingoInfo: RustPB.Basic_V1_LingoOption?,
                  parentMessage: LarkModel.Message?,
                  chatId: String,
                  position: Int32,
                  quasiMsgCreateByNative: Bool,
                  callback: ((LarkSendMessage.SendMessageState) -> Void)?) {
        self.sendText(content: content,
                      lingoInfo: lingoInfo,
                      parentMessage: parentMessage,
                      chatId: chatId,
                      position: position,
                      scheduleTime: nil,
                      quasiMsgCreateByNative: quasiMsgCreateByNative,
                      callback: callback)
    }

    func sendUserCard(shareChatterId: String, chatId: String) {
        self.moreSendService?.sendUserCard(shareChatterId: shareChatterId, chatId: chatId)
    }

    func sendLocation(parentMessage: Message?, chatId: String, screenShot: UIImage, location: LocationContent) {
        self.moreSendService?.sendLocation(parentMessage: parentMessage,
                                          chatId: chatId,
                                          screenShot: screenShot,
                                          location: location)
    }

    func sendFile(path: String,
                  name: String,
                  parentMessage: Message?,
                  removeOriginalFileAfterFinish: Bool,
                  chatId: String,
                  lastMessagePosition: Int32?,
                  quasiMsgCreateByNative: Bool?,
                  preprocessResourceKey: String?) {
        self.moreSendService?.sendFile(path: path,
                                      name: name,
                                      parentMessage: parentMessage,
                                      removeOriginalFileAfterFinish: removeOriginalFileAfterFinish,
                                      chatId: chatId,
                                      lastMessagePosition: lastMessagePosition,
                                      quasiMsgCreateByNative: quasiMsgCreateByNative, preprocessResourceKey: preprocessResourceKey)
    }

    /// 发送Post的消息
    func sendPost(title: String,
                  content: RustPB.Basic_V1_RichText,
                  lingoInfo: RustPB.Basic_V1_LingoOption?,
                  parentMessage: Message?,
                  chatId: String,
                  scheduleTime: Int64?,
                  stateHandler: ((SendMessageState) -> Void)?) {
        self.keyboardSendService?.sendPost(title: title,
                                          content: content,
                                          lingoInfo: lingoInfo,
                                          parentMessage: parentMessage,
                                          chatId: chatId,
                                          scheduleTime: scheduleTime,
                                          stateHandler: stateHandler)
    }

    func sendAIQuickAction(content: RustPB.Basic_V1_RichText,
                           chatId: String,
                           position: Int32,
                           quickActionID: String,
                           quickActionParams: [String: String]?,
                           quickActionBody: AIQuickAction?,
                           callback: ((SendMessageState) -> Void)?) {
        self.aiService?.sendAIQuickAction(content: content,
                                          chatId: chatId,
                                          position: position,
                                          quickActionID: quickActionID,
                                          quickActionParams: quickActionParams,
                                          quickActionBody: quickActionBody,
                                          callback: callback)
    }

    func sendAIQuery(content: Basic_V1_RichText,
                     chatId: String,
                     position: Int32,
                     quickActionBody: AIQuickAction?,
                     callback: ((SendMessageState) -> Void)?) {
        self.aiService?.sendAIQuery(
            content: content,
            chatId: chatId,
            position: position,
            quickActionBody: quickActionBody,
            callback: callback
        )
    }
}

public class ChatKeyboardServiceIMP: ChatInputKeyboardService,
                                     ChatOpenKeyboardItemConfigService {

    func insertRichText(richText: RustPB.Basic_V1_RichText) {
        self.keyboard?.insertRichText(richText: richText)
    }

    func updateAttributedString(message: Message,
                                isInsert: Bool,
                                callback: (() -> Void)?) {
        self.keyboard?.updateAttributedString(message: message, isInsert: isInsert, callback: callback)
    }

    public func updateAttachmentSizeFor(attributedText: NSAttributedString) {
        self.keyboard?.updateAttachmentSizeFor(attributedText: attributedText)
    }

    public var keyboardStatusManager: LarkChatOpenKeyboard.KeyboardStatusManager? {
        self._keyboardView?.keyboardStatusManager
    }

    lazy var smartCorrectService: SmartCorrectService? = {
        return try? self.config?.dataConfig.userResolver.resolve(type: SmartCorrectService.self)
    }()

    lazy var lingoHighlightService: LingoHighlightService? = {
        return try? self.config?.dataConfig.userResolver.resolve(type: LingoHighlightService.self)
    }()

    lazy var smartComposeService: SmartComposeService? = {
        return try? self.config?.dataConfig.userResolver.resolve(type: SmartComposeService.self)
    }()

    var config: ChatOpenKeyboardConfig?

    public var chatKeyboardView: IMKeyBoardView? {
        return self._keyboardView
    }

    public var view: ChatKeyboardView? {
        return self._keyboardView
    }

    var myAIQuickActionSendService: MyAIQuickActionSendService? {
        return self.keyboard
    }

    private var keyboard: NormalChatInputKeyboard?

    private var _keyboardView: ChatKeyboardView?

    public init() {}

    /// 设置支持Panel Menu items
    /// - Parameter order: 按钮的展示顺序，不在order中的按钮 不会展示
    /// 不设置 默认使用chat的顺序
    public func setSupportItemOrder(_ order: [KeyboardItemKey]) {
        (self._keyboardView?.module as? IMChatKeyboardModule)?.setPanelItemsOrderBlock({
            return order
        })
        self.keyboard?.reloadItems()
    }

    /// 设置支持的Panel Menu items
    /// - Parameter typeSet: 支持按钮，默认按照Chat规则的展示
    public func setSupportItemWhiteList(_ whiteList: [KeyboardItemKey]) {
        (self._keyboardView?.module as? IMChatKeyboardModule)?.setPanelWhiteListBlock({
            return whiteList
        })
        self.keyboard?.reloadItems()
    }

    public func setupStartupKeyboardState() {
        self.keyboard?.setupStartupKeyboardState()
    }

    public func setAttributedPlaceholder(_ attributedPlaceholder: NSAttributedString) {
        self.keyboard?.customAttributedPlaceholder = attributedPlaceholder
    }

    public func clearReplyMessage() {
        self.keyboard?.clearReplyMessage()
    }

    func getReplyMessageInfo() -> LarkChatOpenKeyboard.KeyboardJob.ReplyInfo? {
        self.keyboard?.getReplyMessageInfo()
    }

    public func getReplyMessage() -> LarkModel.Message? {
        self.getReplyMessageInfo()?.message
    }

    func saveInputViewDraft(isExitChat: Bool, callback: LarkSDKInterface.DraftCallback?) {
        self.keyboard?.saveInputViewDraft(isExitChat: isExitChat, callback: callback)
    }

    public func getDraftMessageBy(lastDraftId: String, callback: @escaping (LarkChatOpenKeyboard.DraftId?, LarkModel.Message?, RustPB.Basic_V1_Draft?) -> Void) {
        self.keyboard?.viewModel.getDraftMessageBy(lastDraftId: lastDraftId, callback: callback)
    }

    public func actionAfterKeyboardInitDraftFinish(_ action: @escaping () -> Void) {
        self.keyboard?.actionAfterKeyboardInitDraftFinish {
            action()
        }
    }

    public func loadChatKeyboardViewWithConfig(_ config: ChatOpenKeyboardConfig) -> LarkChatOpenKeyboard.IMKeyBoardView? {
        /// 全局容器
        let userResolver = config.dataConfig.userResolver
        guard
            let pushCenter = try? userResolver.userPushCenter,
            let chatWrapper = try? userResolver.resolve(assert: ChatPushWrapper.self, argument: config.dataConfig.chat) else {
                return nil
            }
        self.config = config
        let inputKeyboard: NormalChatInputKeyboard
        let translateFG = userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "im.chat.manual_open_translate"))
        let keyboardNewStyleEnable = KeyboardDisplayStyleManager.isNewKeyboadStyle()

        let chatKeyboardModule: BaseChatKeyboardModule = NormalChatKeyboardModule(context: config.dataConfig.context)
        NormalChatKeyboardModule.onLoad(context: config.dataConfig.context)
        NormalChatKeyboardModule.registGlobalServices(container: config.dataConfig.context.container)
        let moreItem: ChatMoreKeyboardItemConfig? = self.getChatKeyboardItemFor(.more)
        let viewModel = ChatInputViewModel(
            userResolver: userResolver,
            chatWrapper: { chatWrapper },
            messageSender: ChatKeyboardMessageSendServiceImp(moreSendService: moreItem?.sendConfig?.sendService,
                                                             keyboardSendService: config.dataConfig.sendService,
                                                             aiService: try? config.dataConfig.context.userResolver.resolve(type: AIQuickActionSendService.self)),
            pushChannelMessage: pushCenter.driver(for: PushChannelMessage.self),
            pushChat: pushCenter.driver(for: PushChat.self),
            rootMessage: config.dataConfig.rootMessage,
            supportAfterMessagesRender: config.abilityConfig.supportAfterMessagesRender,
            getAttachmentUploader: { (key) in
                return try? userResolver.resolve(assert: AttachmentUploader.self, argument: key)
            }, supportDraft: !config.abilityConfig.forbidDraft)
        let context = KeyboardContext(parent: config.dataConfig.context.container,
                                      store: Store(),
                                      userStorage: userResolver.storage,
                                      compatibleMode: userResolver.compatibleMode)
        IMChatKeyboardModule.onLoad(context: context)
        IMChatKeyboardModule.registGlobalServices(container: context.container)
        let keyboardModule = IMChatKeyboardModule(context: context)

        let keyboardView = NormalChatKeyboardView(
            chatWrapper: viewModel.chatWrapper,
            viewModel: IMKeyboardViewModel(module: keyboardModule, chat: chatWrapper.chat),
            suppportAtAI: config.abilityConfig.supportAtMyAI,
            currentChatterId: viewModel.userResolver.userID,
            pasteboardToken: config.dataConfig.copyPasteToken,
            keyboardNewStyleEnable: keyboardNewStyleEnable,
            supportRealTimeTranslate: translateFG && config.abilityConfig.supportRealTimeTranslate,
            disableReplyBar: config.abilityConfig.disableReplyBar)
        config.dataConfig.keyboardViewDidInitCallBack?(keyboardView)

        keyboardView.keyboardShareDataService.supportDraft = !config.abilityConfig.forbidDraft
        keyboardView.keyboardShareDataService.unsupportPasteTypes = config.abilityConfig.unsupportPasteType
        keyboardView.keyboardShareDataService.supportPartReply = config.dataConfig.rootMessage == nil
        self._keyboardView = keyboardView

        keyboardView.expandType = config.abilityConfig.supportRichTextEdit ? .show : .hide

        config.dataConfig.context.container.register(OpenKeyboardService.self) { [weak keyboardView] (_) -> OpenKeyboardService in
            return keyboardView ?? OpenKeyboardServiceEmptyIMP()
        }

        config.dataConfig.context.container.register(ChatOpenKeyboardItemConfigService.self) { [weak self] (_) -> ChatOpenKeyboardItemConfigService in
            return self ?? ChatOpenKeyboardItemConfigEmptyServiceIMP()
        }

        let delegate = (config.dataConfig.delegate as? ChatInputKeyboardDelegate) ?? self
        inputKeyboard = NormalChatInputKeyboard(
            viewModel: viewModel,
            module: chatKeyboardModule,
            delegate: delegate,
            keyboardView: keyboardView
        )
        self.keyboard = inputKeyboard

        config.dataConfig.context.container.register(ChatKeyboardOpenService.self) { [weak inputKeyboard] (_) -> ChatKeyboardOpenService in
            return inputKeyboard ?? DefaultChatKeyboardOpenService()
        }

        config.dataConfig.context.container.register(MessengerNormalChatKeyboardDependency.self) { [weak inputKeyboard] (_) -> MessengerNormalChatKeyboardDependency in
            return inputKeyboard ?? DefaultMessengerNormalChatKeyboardDependency(userResolver: userResolver)
        }
        var unsupportPasteTypes: [ChatKeyboardInputOpenType] = []
        config.abilityConfig.unsupportPasteType.forEach { type in
            switch type {
            case .imageAndVideo:
                unsupportPasteTypes.append(.image)
                unsupportPasteTypes.append(.video)
            case .emoji:
                unsupportPasteTypes.append(.emoji)
            case .fontStyle:
                keyboardView.fontStyleInputService?.removerObserveForTextView(keyboardView.inputTextView)
            case .code:
                unsupportPasteTypes.append(.code)
            default:
                break
            }
        }
        inputKeyboard.setupModule(unsupportPasteTypes)
        let chat = config.dataConfig.chat
        lingoHighlightService?.setupLingoHighlight(
            chat: chat,
            fromController: delegate.baseViewController(),
            inputTextView: inputKeyboard.keyboardView.inputTextView,
            getMessageId: { [weak inputKeyboard] in
                inputKeyboard?.keyboardView.keyboardStatusManager.getMultiEditMessage()?.id ?? ""
            })
        smartCorrectService?.setupCorrectService(chat: chat,
                                                 scene: .im,
                                                 fromController: delegate.baseViewController(),
                                                 inputTextView: inputKeyboard.keyboardView.inputTextView)
        smartComposeService?.setupSmartCompose(chat: chat,
                                               scene: .MESSENGER,
                                               with: inputKeyboard.keyboardView.inputTextView,
                                               fromVC: delegate.baseViewController())

        return keyboardView
    }

    public func showExpandButton(_ show: Bool) {
        self.chatKeyboardView?.expandType = show ? .show : .hide
    }

    public func getChatKeyboardItemFor<T: AnyObject>(_ key: KeyboardItemKey) -> T? {
        let config = self.config?.dataConfig.items.first(where: { $0.key == key })
        return config as? T
    }

    /// 弹出键盘
    public func showKeyboard() {
        self.chatKeyboardView?.inputTextView.becomeFirstResponder()
    }

    /// 收起键盘
    public func foldKeyboard() {
        self.chatKeyboardView?.fold()
    }

    func setReplyMessage(message: LarkModel.Message, replyInfo: PartialReplyInfo?) {
        self.keyboard?.setReplyMessage(message: message, replyInfo: replyInfo)
    }

    func reEditMessage(message: LarkModel.Message) {
        self.keyboard?.reEditMessage(message: message)
    }

    func multiEditMessage(message: Message) {
        self.keyboard?.multiEditMessage(message: message)
    }

    func save(draft: String, id: DraftId, type: RustPB.Basic_V1_Draft.TypeEnum, callback: DraftCallback?) {
        self.keyboard?.viewModel.save(draft: draft, id: id, type: type, callback: callback)
    }

    func reloadKeyBoard(rootMessage: LarkModel.Message) {
        self.keyboard?.reloadKeyBoard(rootMessage: rootMessage)
    }

    public func saveInputViewDraft(callback: DraftCallback?) {
        self.keyboard?.saveInputViewDraft(isExitChat: false, callback: callback)
    }
}

extension ChatKeyboardServiceIMP {
    public func afterMessagesRender() {
        self.keyboard?.viewModel.afterMessagesRender()
    }
}

/// 业务方需要实现，因为对外保留的能力只是分布，所以有些代理也不需要实现
extension ChatKeyboardServiceIMP: ChatInputKeyboardDelegate {

    var openKeyboardDelegate: ChatOpenKeyboardDelegate? {
        return self.config?.dataConfig.delegate
    }

    /// ChatOpenKeyboardDelegate
    public func handleKeyboardAppear(triggerType: KeyboardAppearTriggerType) {
        openKeyboardDelegate?.handleKeyboardAppear(triggerType: .inputTextView)
    }

    public func keyboardFrameChanged(frame: CGRect) {
        openKeyboardDelegate?.keyboardFrameChanged(frame: frame)
    }

    public func inputTextViewFrameChanged(frame: CGRect) {
        openKeyboardDelegate?.inputTextViewFrameChanged(frame: frame)
    }

    /// 插入图片，返回值是 是否应该继续向输入框插入图片，默认为 返回 false 的空实现
    public func inputTextViewWillInput(image: UIImage) -> Bool {
        return openKeyboardDelegate?.inputTextViewWillInput(image: image) ?? false
    }

    public func rootViewController() -> UIViewController {
        return openKeyboardDelegate?.rootViewController() ?? UIViewController()
    }

    public func baseViewController() -> UIViewController {
        return openKeyboardDelegate?.baseViewController() ?? UIViewController()
    }

    public func keyboardWillExpand() {
        openKeyboardDelegate?.keyboardWillExpand()
    }

    public func textChange(text: String, textView: LarkEditTextView) {
        openKeyboardDelegate?.textChange(text: text, textView: textView)
    }

    public func keyboardContentHeightWillChange(_ isFold: Bool) {
        openKeyboardDelegate?.keyboardContentHeightWillChange(isFold)
    }

    /// ChatInputKeyboardDelegate
    public func setEditingMessage(message: Message?) {}

    public var chatFromWhere: ChatFromWhere {
        return .ignored
    }

    public func getKeyboardStartupState() -> KeyboardStartupState {
        return (openKeyboardDelegate?.getKeyboardStartupState()) ?? KeyboardStartupState(type: .none)
    }

    public func setScheduleTipViewStatus(_ status: ScheduleMessageStatus) {
    }

    public func getScheduleMsgSendTime() -> Int64? {
        return nil
    }

    public func getSendScheduleMsgIds() -> ([String], [String]) {
        return ([], [])
    }

    public func clickChatMenuEntry() {
    }

    public func replaceViewWillChange(_ view: UIView?) {

    }

    public func onExitReply() {
    }

    public func jobDidChange(old: KeyboardJob?, new: KeyboardJob) {
    }

    public func keyboardCanAutoBecomeFirstResponder() -> Bool {
        return true
    }
}
