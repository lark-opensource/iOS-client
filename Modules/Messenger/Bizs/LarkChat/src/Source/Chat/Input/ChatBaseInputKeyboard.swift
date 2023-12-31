//
//  ChatBaseInputKeyboard.swift
//  LarkChat
//
//  Created by zhaojiachen on 2022/2/16.
//
/// 李洛斌：
/// 1. 偶现的全部回复 done
/// 2. 局部复制的问题 done
/// 3. FG的添加，代码的review
/// 4. 日志的补齐 done
import UIKit
import Foundation
import RxSwift
import RxRelay
import RxCocoa
import LarkUIKit
import EENavigator
import LarkFoundation
import LarkModel
import LarkCore
import LarkRichTextCore
import LarkKeyboardView
import LKCommonsLogging
import EditTextView
import LarkAudio
import LarkFeatureGating
import LarkKAFeatureSwitch
import LarkSDKInterface
import LarkMessengerInterface
import LarkContainer
import RustPB
import LarkFocus
import LarkFocusInterface
import LarkOpenChat
import LarkIMMention
import LarkMessageCore
import LarkMessageBase
import UniverseDesignDatePicker
import UniverseDesignActionPanel
import LarkAccountInterface
import LarkBaseKeyboard
import LarkEMM
import LarkSensitivityControl
import LarkChatOpenKeyboard
import LarkChatKeyboardInterface

public class ChatBaseInputKeyboard: NSObject,
                                    UserResolverWrapper,
                                    EditTextViewTextDelegate,
                                    ChatKeyboardOpenService,
                                    ChatKeyboardDelegate,
                                    MessengerKeyboardPanelRightContainerViewDelegate,
                                    ChatInternalKeyboardService {

    public var userResolver: UserResolver { module.userResolver }

    static let logger = Logger.log(ChatBaseInputKeyboard.self, category: "Module.Inputs")

    @ScopedInjectedLazy var myAIService: MyAIService?

    var chatFromWhere: ChatFromWhere {
        return self.delegate?.chatFromWhere ?? ChatFromWhere.default()
    }

    var myAIQuickActionSendService: MyAIQuickActionSendService? { nil }

    let viewModel: DefaultInputViewModel
    weak var delegate: ChatInputKeyboardDelegate?
    private let module: BaseChatKeyboardModule
    private(set) var keyboardView: ChatKeyboardView
    let keyboardNewStyleEnable: Bool

    var audioKeyboardHelper: AudioRecordPanelProtocol? {
        assertionFailure("need be override")
        return nil
    }

    var view: ChatKeyboardView? {
       return self.keyboardView
    }

    /// 一些UI操作 需要草稿设置之后完成，可以关注下面的属性
    var hasSetupDraft = false {
        didSet {
            if hasSetupDraft {
                self.setupDraftCallBack?()
                /// 确保只会调用一次
                self.setupDraftCallBack = nil
            }
        }
    }

    var supportAtMyAI: Bool {
        guard self.userResolver.fg.dynamicFeatureGatingValue(with: "im.chat.my_ai_inline") else { return false }
        let chat = self.viewModel.chatModel
        guard chat.supportMyAIInlineMode,
              self.myAIService?.enable.value == true,
              self.myAIService?.needOnboarding.value == false else { return false }
        return self.keyboardView.suppportAtAI
    }

    private var setupDraftCallBack: (() -> Void)?

    var debounceDuration: TimeInterval { return 2 }
    var debouncer: Debouncer = Debouncer()
    /// 自定义Placeholder, 设置后长期保持，不受数据变更的影响
    var customAttributedPlaceholder: NSAttributedString?

    var shouldShowTenantPlaceholder: Bool = true
    /// 「+」号更多菜单数据
    private var moreItemsDriver: Driver<[ChatKeyboardMoreItem]> {
        return moreItemsVariable.asDriver()
    }
    private let moreItemsVariable = BehaviorRelay<[ChatKeyboardMoreItem]>(value: [])
    let disposeBag = DisposeBag()

    @ScopedInjectedLazy var abTestService: MenuInteractionABTestService?
    @ScopedInjectedLazy private var tenantUniversalSettingService: TenantUniversalSettingService?

    private var performAfterDraftSetupActions: [() -> Void] = []

    public init(viewModel: DefaultInputViewModel,
                module: BaseChatKeyboardModule,
                delegate: ChatInputKeyboardDelegate?,
                keyboardView: ChatKeyboardView) {
        self.viewModel = viewModel
        self.module = module
        self.delegate = delegate
        self.keyboardView = keyboardView
        self.keyboardNewStyleEnable = keyboardView.keyboardNewStyleEnable
        super.init()
        keyboardView.chatKeyboardDelegate = self
        self.configViewModelCallBacks()
        self.viewModel.keyboardNewStyleEnable = keyboardNewStyleEnable
        self.viewModel.keyboardStatusManagerBlock = { [weak self] in
            return self?.keyboardView.keyboardStatusManager
        }
        self.keyboardView.inputTextView.textDelegate = self
        self.viewModel
            .draftCache?
            .cacheChangeSignal
            .drive(onNext: { [weak self] (draftCacheType) in
                guard let `self` = self else {
                    return
                }
                var updateDraftInfo: DraftInfo?
                switch draftCacheType {
                case .editMessage(let editMessageId, let draftInfo):
                    if editMessageId == self.keyboardView.keyboardStatusManager.getMultiEditMessage()?.id {
                        updateDraftInfo = draftInfo
                    }
                case .chat(let chatId, let draftInfo):
                    if chatId == self.viewModel.chatModel.id,
                       case .normal = self.keyboardView.keyboardStatusManager.currentKeyboardJob,
                       self.viewModel.rootMessage?.id == nil {
                        updateDraftInfo = draftInfo
                    }
                case .message(let messageId, let draftInfo):
                    if messageId == self.keyboardView.keyboardStatusManager.getReplyMessage()?.id ||
                        messageId == self.viewModel.rootMessage?.id {
                        updateDraftInfo = draftInfo
                    }
                case .scheduleMessage(let chatId, let draftInfo):
                    if chatId == self.viewModel.chatModel.id {
                        self.scheduleSendDraftChange(draftInfo: draftInfo)
                    }
                }
                if let draftInfo = updateDraftInfo {
                    self.updateInputViewWith(draftInfo: draftInfo)
                }
            })
            .disposed(by: self.disposeBag)

        self.configPanelSubModule()
        self.keyboardView.setupItems(self.keyboardItems(moreItemsDriver: self.moreItemsDriver))

        self.setupDraftCallBack = { [weak self] in
            self?.performAfterDraftSetupActions.forEach { $0() }
            self?.performAfterDraftSetupActions = []
        }
        /// 这里隔1.5s 自动回调  确保草稿出现拉取异常或者一些分支无法正常给与回调 做个兼容兜底
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: { [weak self] in
            self?.setUpDraftFinish()
        })

        self.setupDraftContent { [weak self] in
            self?.setUpDraftFinish()
        }
        self.updateInputPlaceHolder()
        self.updateInputViewEnable()
        self.keyboardView.messengerKeyboardPanel?.rightContainerViewDelegate = self
    }

    /// 如果一些操作需要在键盘初始化草稿之后完成，调用该方法
    func actionAfterKeyboardInitDraftFinish(_ action: @escaping () -> Void) {
        if self.hasSetupDraft {
            action()
        } else {
            self.performAfterDraftSetupActions.append(action)
        }
    }

    func scheduleSendDraftChange(draftInfo: DraftInfo) {
    }

    @objc
    private func setUpDraftFinish() {
        if !Thread.isMainThread { assertionFailure("error thread") }
        if !self.hasSetupDraft {
            self.hasSetupDraft = true
        }
    }

    // 输入框底部功能区
    func keyboardItems(moreItemsDriver: Driver<[ChatKeyboardMoreItem]>) -> [InputKeyboardItem] {
        assertionFailure("need be override")
        return []
    }

    func getPanelSubModuleForItemKey<Value>(key: KeyboardItemKey) -> Value? {
        let module = self.keyboardView.module.getPanelSubModuleForItemKey(key)
        return module as? Value
    }

    private func configPanelSubModule() {
        let item = ChatKeyboardViewPageItem(keyboardView: self.keyboardView,
                                            keyboardStatusManager: self.keyboardView.keyboardStatusManager,
                                            chatFromWhere: self.chatFromWhere,
                                            supportAtMyAI: self.supportAtMyAI) { [weak self] in
            guard let self = self else { return nil }
            var replyInfo: KeyboardJob.ReplyInfo?
            /// rootMessage 存在 说明是详情页，不支持局部回复
            if let rootMessage = self.viewModel.rootMessage {
                replyInfo = KeyboardJob.ReplyInfo(message: rootMessage, partialReplyInfo: nil)
            }

            if let replyMessageInfo = self.viewModel.replyMessageInfo {
                replyInfo = replyMessageInfo
            }
            return replyInfo
        } afterSendMessage: { [weak self] in
            self?.viewModel.cleanReplyMessage()
        }

        self.keyboardView.module.context.store.setValue(item, for: ChatKeyboardViewPageItem.key)

        let module: IMChatBaseKeyboardAtUserPanelSubModule? = getPanelSubModuleForItemKey(key: .at)

        module?.afterInsertCallBack = { [weak self] (type) in
            guard let self = self else { return }
            self.keyboardView.reloadSendButton()
            if type == .at {
                if case .multiEdit = self.keyboardView.keyboardStatusManager.currentKeyboardJob {
                    self.keyboardView.updateTipIfNeed(.atWhenMultiEdit)
                }
            }
        }
        self.keyboardView.setupKeyboardModule()
    }

    func configViewModelCallBacks() {
        self.viewModel.chatIsAllowPostChangeCallback = { [weak self] () in
            guard let `self` = self else { return }
            // 只有输入框没有文字的时候才会关闭键盘输入能力
            if self.viewModel.chatModel.isAllowPost ||
                self.keyboardView.attributedString.length == 0 {
                self.updateInputViewEnable()
                self.updateInputPlaceHolder()
                if !self.viewModel.chatModel.isAllowPost {
                    self.keyboardView.fold()
                }
            }
        }

        self.viewModel.chatDisplayNameChangeCallback = { [weak self] () in
            guard let `self` = self else { return }
            // 只有输入框没有文字的时候才会关闭键盘输入能力
            if self.viewModel.chatModel.isAllowPost ||
                self.keyboardView.attributedString.length == 0 {
                self.updateInputPlaceHolder()
            }
        }

        self.viewModel.chatModeChanged = { [weak self] () in
            self?.updateInputPlaceHolder()
        }
    }

    public func textChange(text: String, textView: LarkEditTextView) {
        debouncer.debounce(indentify: "textChange", duration: debounceDuration) { [weak self] in
            if textView.isFirstResponder,
               //二次编辑场景不实时存草稿
               self?.keyboardView.keyboardStatusManager.currentKeyboardJob.isMultiEdit != true {
                self?.saveInputViewDraft()
            }
        }
        delegate?.textChange(text: text, textView: textView)
    }

    // 仅详情页使用，解决详情页rootmsg可能上来取不到的问题，此处逻辑需要重构
    func reloadKeyBoard(rootMessage: Message) {
        self.viewModel.rootMessage = rootMessage
        self.keyboardView.setupItems(self.keyboardItems(moreItemsDriver: self.moreItemsDriver))
        self.setupDraftContent()
    }

    func reloadItems() {
        self.keyboardView.setupItems(self.keyboardItems(moreItemsDriver: self.moreItemsDriver))
    }

    func reloadItemForKey(_ key: KeyboardItemKey) {
        guard let item = keyboardView.viewModel.module.getPanelItems().first(where: { $0.key == key.rawValue }),
                  let idx = self.keyboardView.items.firstIndex(where: { $0.key == key.rawValue }) else {
            return
        }
        self.keyboardView.items[idx] = item
        self.keyboardView.keyboardPanel.reloadPanelBtn(key: key.rawValue)
    }

    func setupDraftContent(_ finish: (() -> Void)? = nil) {
        let chat = self.viewModel.chatModel
        if !chat.isAllowPost {
            finish?()
            return
        }
        /// 这里需要判断是否存在 rootMessage， rootMessage 代表当前页面是否存在根消息
        /// lastDraftId 和含义是 chat 上次退出页面时键盘显示的草稿状态，只影响 rootMessage 为空的情况
        if self.viewModel.rootMessage != nil ||
            chat.lastDraftId.isEmpty {
            self.updateDraftContent(onFinished: finish)
        } else {
            /// 根据 lastDraftId 获取上一次的 reply message
            /// 如果不存在 replyMessage，更新草稿
            self.viewModel.getDraftMessageBy(
                lastDraftId: chat.lastDraftId
            ) { [weak self] (draftId, message, _) in
                if case .replyMessage(_, let partialReplyInfo) = draftId {
                    if let message = message {
                        self?.keyboardView.switchJob(.reply(info: KeyboardJob.ReplyInfo(message: message,
                                                                                        partialReplyInfo: partialReplyInfo)))
                    }
                    finish?()
                } else {
                    self?.updateDraftContent(onFinished: finish)
                }
            }
        }
    }

    /// 根据草稿信息更新UI
    func updateInputViewWith(draftInfo: DraftInfo) {
        assertionFailure("need be override")
    }

    func updateDraftContent(onFinished: (() -> Void)? = nil) {
        viewModel.getCurrentDraftContent()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (draft) in
                self?.updateDraftContent(by: draft.0)
                onFinished?()
            }).disposed(by: self.disposeBag)
    }

    func setupStartupKeyboardState() {
        assertionFailure("need be override")
    }

    func updateDraftContent(by draftStr: String) {
        if draftStr.isEmpty {
            self.keyboardView.attributedString = NSAttributedString(string: "",
                                                                    attributes: keyboardView.inputTextView.defaultTypingAttributes)

            return
        }
        if !self.keyboardView.updateTextViewForTextDraftStr(draftStr) {
            let draft = NSAttributedString(
                string: draftStr,
                attributes: self.keyboardView.inputTextView.defaultTypingAttributes
            )
            let content = OldVersionTransformer.transformInputText(draft)
            self.keyboardView.attributedString = content
        }
    }

    func updateInputPlaceHolder() {
        if let customAttributedPlaceholder = self.customAttributedPlaceholder {
            self.keyboardView.inputTextView.attributedPlaceholder = customAttributedPlaceholder
            return
        }
        /// 判定顺序：群管理开启发言 -> 二次编辑 -> 边写边译 -> 阅后即焚 -> 给自己发送信息 -> 话题模式 -> MyAI -> 普通聊天
        shouldShowTenantPlaceholder = true
        if self.viewModel.chatModel.isAllowPost {
            if case .multiEdit = self.keyboardView.keyboardStatusManager.currentKeyboardJob {
                shouldShowTenantPlaceholder = false
                self.keyboardView.inputPlaceHolder = BundleI18n.LarkChat.Lark_IM_EditMessage_DeleteAllAndRecall_EnterNewMessage_Placeholder
            } else if self.viewModel.chatModel.typingTranslateSetting.isOpen {
                shouldShowTenantPlaceholder = false
                self.keyboardView.inputPlaceHolder = BundleI18n.LarkChat.Lark_IM_TranslationAsYouType_EnterYourPreferredLanguage_Placeholder
            } else if viewModel.chatModel.enableMessageBurn {
                shouldShowTenantPlaceholder = false
                self.keyboardView.inputPlaceHolder = BundleI18n.LarkChat.Lark_IM_RestrictedModeOnMessageSelfDestruct_Placeholder
            } else if viewModel.chatModel.type == .p2P,
                       let userId = viewModel.chatModel.chatter?.id,
                       userId == viewModel.userResolver.userID {
               self.keyboardView.inputPlaceHolder = BundleI18n.LarkChat.Lark_Legacy_MessageToYourself
            } else if viewModel.chatModel.displayInThreadMode {
               self.keyboardView.inputPlaceHolder = BundleI18n.LarkChat.Lark_IM_SwitchedTopicGroup_NewTopic_Button
            } else if self.viewModel.chatModel.isP2PAi {
                shouldShowTenantPlaceholder = false
                self.keyboardView.inputPlaceHolder = BundleI18n.LarkChat.MyAI_IM_AskAnythingAboutWork_InputField_Placeholder
            } else {
               self.keyboardView.inputPlaceHolder = BundleI18n.LarkChat.Lark_Legacy_SendTip(self.viewModel.chatModel.displayWithAnotherName)
            }
        } else {
            shouldShowTenantPlaceholder = false
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

    private func updateInputViewEnable() {
        if self.viewModel.chatModel.isAllowPost {
            self.keyboardView.setSubViewsEnable(enable: true)
        } else {
            self.keyboardView.setSubViewsEnable(enable: false)
        }
    }

    func saveInputViewDraft(isExitChat: Bool = false, callback: DraftCallback? = nil) {
        var draftText = self.keyboardView.richTextStr
        let userInfoDic = AtTransformer.getAllChatterActualNameMapForAttributedString(keyboardView.attributedString)
        let textDraft = TextDraftModel(content: draftText,
                                       userInfoDic: userInfoDic)
        self.viewModel.saveInputViewDraft(content: textDraft.stringify(),
                                          callback: callback)
    }

    func getDraftMessageBy(lastDraftId: String, callback: @escaping (LarkChatOpenKeyboard.DraftId?, LarkModel.Message?, RustPB.Basic_V1_Draft?) -> Void) {
        self.viewModel.getDraftMessageBy(lastDraftId: lastDraftId, callback: callback)
    }

    func save(draft: String, id: DraftId, type: RustPB.Basic_V1_Draft.TypeEnum, callback: DraftCallback?) {
        self.viewModel.save(draft: draft, id: id, type: type, callback: callback)
    }

    /// 该方法只会在Chat中被调用
    public func setReplyMessage(message: Message, replyInfo: PartialReplyInfo?) {
        // 非回复状态下存储键盘中原有的输入内容，如果replyMessage没草稿则该内容会带过去
        let inputString = (self.keyboardView.keyboardStatusManager.getReplyMessage() == nil) ? self.keyboardView.attributedString : NSAttributedString()

        // 这一步会同步的把输入框内容变为replyMessage的草稿
        self.keyboardView.switchJob(.reply(info: KeyboardJob.ReplyInfo(message: message, partialReplyInfo: replyInfo)))

        // 如果replyMessage的草稿为空，则需要自动插入内容
        if self.keyboardView.attributedString.length == 0 {
            // 单聊：自动插入{键盘中输入的内容}
            if self.viewModel.chatModel.type == .p2P {
                self.keyboardView.attributedString = inputString
            } else {
                // 群聊回复别人：自动插入{@UserName}+{键盘中输入的内容}
                if let user = message.fromChatter, user.id != self.viewModel.userResolver.userID {
                    let name = self.getDisplayName(chatter: user)
                    self.keyboardView.insert(userName: name,
                                             actualName: user.localizedName,
                                             userId: user.id,
                                             isOuter: false)
                    let newString = NSMutableAttributedString(attributedString: self.keyboardView.attributedString)
                    newString.append(inputString)
                    self.keyboardView.attributedString = newString
                } else {
                    // 群聊回复自己：自动插入{键盘中输入的内容}
                    self.keyboardView.attributedString = inputString
                }
            }
        }
    }

    // https://docs.bytedance.net/doc/0O4zpTN0zxG98gl5irBSNb
    public func reEditMessage(message: Message) {
        assertionFailure("need be override")
    }

    public func multiEditMessage(message: Message) {
        assertionFailure("need be override")
    }

    func setupTextMessage(message: Message,
                          isInsert: Bool = true,
                          callback: (() -> Void)? = nil) {
        guard let textContent = message.content as? TextContent else {
            return
        }
        let attributes = self.keyboardView.inputTextView.baseDefaultTypingAttributes
        let richText = TextDocsViewModel(
            userResolver: userResolver,
            richText: textContent.richText,
            docEntity: textContent.docEntity,
            hangPoint: message.urlPreviewHangPointMap
        ).richText
        let processProvider = MessageInlineViewModel.urlInlineProcessProvider(message: message, attributes: attributes)
        let attributedStr = RichTextTransformKit.transformRichTextToStr(richText: richText,
                                                                        attributes: attributes,
                                                                        attachmentResult: [:],
                                                                        processProvider: processProvider)
        updateAttributedStringAtInfo(attributedStr) { [weak self] in
            self?.onFinishUpdateAttributedStringAtInfo(attributedStr, isInsert: isInsert)
            callback?()
        }
    }

    /// 完成更新attributedStr
    func onFinishUpdateAttributedStringAtInfo(_ attributedStr: NSAttributedString,
                                              isInsert: Bool) {
        if isInsert {
            self.keyboardView.inputTextView.insert(attributedStr, useDefaultAttributes: false)
        } else {
            self.keyboardView.inputTextView.replace(attributedStr, useDefaultAttributes: false)
        }
    }

    /// 撤回重新编辑替换原名 密聊&普通聊天都需要
    func updateAttributedStringAtInfo(_ attributedStr: NSAttributedString, finish: (() -> Void)?) {
        let chatterInfo: [AtChatterInfo] = AtTransformer.getAllChatterInfoForAttributedString(attributedStr)
        /// 撤回重新编辑的时候，本地一定有数据很快就能返回，但是防止数据巨大或者异常时候，做个超时处理
        let chatID = self.viewModel.chatModel.id
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

    func setupModule(_ unsupportPasteType: [ChatKeyboardInputOpenType] = []) {
        let metaModel = ChatKeyboardMetaModel(chat: self.viewModel.chatModel)
        self.module.handler(model: metaModel)
        self.module.createMoreItems(metaModel: metaModel)
        let moreItems = self.module.moreItems()
        self.moreItemsVariable.accept(moreItems)
        self.module.createInputHandlers(metaModel: metaModel)
        let inputOpenHandlers = self.module.inputHandlers().filter { !unsupportPasteType.contains($0.type) }
        let inputHandlers = inputOpenHandlers.map { ChatKeyboardInputOpenHandlerWrapper($0) }
        keyboardView.textViewInputProtocolSet = TextViewInputProtocolSet(inputHandlers)
        self.viewModel.chatWrapper.chat
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] chat in
                guard let `self` = self else { return }
                self.module.modelDidChange(model: ChatKeyboardMetaModel(chat: chat))
            }).disposed(by: self.disposeBag)
    }

    // MARK: - ChatKeyboardOpenService
    public var hasRootMessage: Bool {
        return self.viewModel.rootMessage != nil
    }

    public var hasReplyMessage: Bool {
        return self.viewModel.replyMessage != nil
    }

    public var getScheduleDraft: Observable<RustPB.Basic_V1_Draft?> {
        // 优先取回复的定时消息草稿，然后取chat的定时消息草稿
        let draftId = self.viewModel.rootMessage == nil ? self.viewModel.chatModel.scheduleMessageDraftID : self.viewModel.rootMessage?.scheduleMessageDraftId ?? ""
        return self.viewModel.draftCache?.getDraftModel(draftID: draftId) ?? .error(UserScopeError.disposed)
    }

    public func foldKeyboard() {
        self.keyboardView.fold()
    }

    public func refreshMoreItems() {
        let moreItems = self.module.moreItems()
        self.moreItemsVariable.accept(moreItems)
    }

    public func baseViewController() -> UIViewController {
        return self.delegate?.baseViewController() ?? UIViewController()
    }

    public func getRootMessage() -> Message? {
        return self.viewModel.rootMessage
    }

    public func getReplyMessageInfo() -> KeyboardJob.ReplyInfo? {
        return self.keyboardView.keyboardStatusManager.getReplyInfo()
    }

    public func getReplyMessage() -> LarkModel.Message? {
        self.getReplyMessageInfo()?.message
    }

    public func clearReplyMessage() {
        self.keyboardView.keyboardStatusManager.switchToDefaultJob()
    }

    public func getInputRichText() -> RustPB.Basic_V1_RichText? {
        return self.keyboardView.richText
    }

    public func sendLocation(parentMessage: Message?,
                             screenShot: UIImage,
                             location: LocationContent) {
        self.viewModel.messageSender?.sendLocation(parentMessage: parentMessage,
                                                  chatId: self.viewModel.chatModel.id,
                                                  screenShot: screenShot,
                                                  location: location)
    }

    public func sendUserCard(shareChatterId: String) {
        self.viewModel.messageSender?.sendUserCard(shareChatterId: shareChatterId, chatId: self.viewModel.chatModel.id)
    }

    public func sendFile(path: String,
                         name: String,
                         parentMessage: Message?) {
        assertionFailure("need be override")
    }

    public func sendText(content: RustPB.Basic_V1_RichText, lingoInfo: RustPB.Basic_V1_LingoOption?, parentMessage: Message?) {
        assertionFailure("need be override")
    }

    public func sendInputContentAsMessage() {
        self.keyboardView.sendNewMessage()
    }

    public func insertAtChatter(name: String, actualName: String, id: String, isOuter: Bool) {
        self.keyboardView.insert(userName: name, actualName: actualName, userId: id, isOuter: isOuter)
    }

    public func insertUrl(urlString: String) {
        self.keyboardView.insertUrl(urlString: urlString)
    }

    public func insertUrl(title: String, url: URL, type: RustPB.Basic_V1_Doc.TypeEnum) {
        self.keyboardView.insertUrl(title: title, url: url, type: type)
    }

    // MARK: - ChatKeyboardDelegate
    public func inputTextViewWillSend() {
        self.audioKeyboardHelper?.cleanAudioRecognizeState()
    }

    public func inputTextViewSend(attributedText: NSAttributedString) {
        assertionFailure("need be override")
    }

    public func inputTextViewSend(attributedText: NSAttributedString, scheduleTime: Int64?) {
        assertionFailure("need be override")
    }

    public func keyboardframeChange(frame: CGRect) {
        self.delegate?.keyboardFrameChanged(frame: frame)

        // 当键盘收起的时候 显示 icon 面板
        if self.keyboardView.keyboardPanel.contentHeight == 0 {
            self.audioKeyboardHelper?.cleanMaskView()
        }
    }

    public func inputTextViewFrameChange(frame: CGRect) {
        self.delegate?.inputTextViewFrameChanged(frame: frame)
    }

    public func inputTextViewBeginEditing() {
        self.delegate?.handleKeyboardAppear(triggerType: .inputTextView)
    }

    public func inputTextViewWillInput(image: UIImage) -> Bool {
        let config = PasteboardConfig(token: Token(self.keyboardView.pasteboardToken))
        let itemCount = SCPasteboard.general(config).items?.count ?? 0
        if itemCount == 1 {
           return delegate?.inputTextViewWillInput(image: image) ?? false
        }
        return true
    }

    public func clickExpandButton() {}

    public func supportFontStyle() -> Bool {
        assertionFailure("need be override")
        return false
    }

    public func inputTextViewDidChange(input: LKKeyboardView) {
        assertionFailure("need be override")
    }

    public func getDisplayVC() -> UIViewController {
        return self.delegate?.baseViewController() ?? UIViewController()
    }

    public func keyboardAppearForSelectedPanel(item: LarkKeyboardView.KeyboardItemKey) {
        if item == .emotion || item == .picture || item == .more {
            self.delegate?.handleKeyboardAppear(triggerType: .keyboardItem(item))
        }
    }

    func inputTextViewSaveDraft(id: DraftId, type: RustPB.Basic_V1_Draft.TypeEnum, content: String) {
        self.viewModel.save(
            draft: content,
            id: id,
            type: type,
            callback: nil
        )
    }

    func inputTextViewGetDraft(key: String) -> Observable<(content: String, partialReplyInfo: Basic_V1_Message.PartialReplyInfo?)> {
        return self.viewModel.getDraft(key: key)
    }

    func closeRelatedMessageTipsView() {
        if case .scheduleSend(let msg) = self.keyboardView.keyboardStatusManager.currentKeyboardJob, msg != nil {
            let tip = self.keyboardView.keyboardStatusManager.currentDisplayTip
            self.keyboardView.switchJob(.scheduleSend(info: nil))
            self.keyboardView.keyboardStatusManager.addTip(tip)
        } else {
            self.keyboardView.goBackToLastStatus()
        }
    }

    func getDisplayName(chatter: Chatter) -> String {
        let chat = self.viewModel.chatWrapper.chat.value
        return chatter.displayName(chatId: chat.id, chatType: chat.type, scene: .reply)
    }

    func userFocusStatus() -> ChatterFocusStatus? {
        /// 单聊新的样式(包括自己)
        guard viewModel.chatModel.type == .p2P else {
            return nil
        }
        /// 自己不需要展示状态
        if let userID = viewModel.chatModel.chatter?.id,
           viewModel.userResolver.userID == userID {
            return nil
        }
        return viewModel.chatModel.chatter?.focusStatusList.topActive
    }

    func shouldReprocessPlaceholder() -> Bool {
        return self.customAttributedPlaceholder == nil
    }

    /// 这个逻辑是企业自定义输入框宣传语
    /// 不管是不是密聊，全场景都要感知，因此只用于暴露placeholder，具体聊天场景根据实际诉求获取然后赋值。
    func getTenantInputBoxPlaceholder() -> String? {
        return tenantUniversalSettingService?.getInputBoxPlaceholder()
    }

    func replaceTenantInputPlaceholderEnable() -> Bool {
        return tenantUniversalSettingService?.replaceTenantPlaceholderEnable() ?? false
    }

    func didApplyPasteboardInfo() { }

    public func saveInputPostDraftWithReplyMessageInfo(_ info: KeyboardJob.ReplyInfo?) {}

    public func saveScheduleDraft() {}

    public func deleteScheduleDraft() {}

    public func applyInputPostDraft(_ replyDraft: String) {}

    public func updateAttachmentSizeFor(attributedText: NSAttributedString) {}

    public func getReplyTo(info: KeyboardJob.ReplyInfo, user: Chatter, result: @escaping (NSMutableAttributedString) -> Void) {
        assertionFailure("need be override")
    }

    public func getTranslationResult() -> (String?, RustPB.Basic_V1_RichText?) {
        return (nil, nil)
    }

    public func getOriginContentBeforeTranslate() -> (String?, NSAttributedString?) {
        return (nil, nil)
    }

    public func clearTranslationData() {}

    public func updateTargetLanguage(_ languageKey: String) {}

    public func applyTranslationCallBack(title: String?, content: RustPB.Basic_V1_RichText?) {}

    public func recallTranslationCallBack() {}

    public func transformRichTextToStr(richText: RustPB.Basic_V1_RichText) -> NSAttributedString {
        return RichTextTransformKit.transformRichTextToStr(richText: richText,
                                                           attributes: keyboardView.inputTextView.baseDefaultTypingAttributes,
                                                           attachmentResult: [:])
    }

    public func presentLanguagePicker(currentLanguage: String) {}

    public func previewTranslation(applyButtonCallBack: @escaping (() -> Void)) {}

    func keyboardWillExitJob(currentJob: KeyboardJob, newJob: KeyboardJob, triggerByGoBack: Bool) {
        switch currentJob {
        case .multiEdit(_):
            if triggerByGoBack {
                break
            }
            if case .multiEdit = newJob {
                break
            }
            saveInputViewDraft()
            DispatchQueue.main.async { [weak self] in
                self?.onInputFinished()
            }
        case .reply(let info):
            /// 切job的时候 草稿不存储局部信息
            saveInputPostDraftWithReplyMessageInfo(KeyboardJob.ReplyInfo(message: info.message, partialReplyInfo: nil))
        case .scheduleSend(_):
            if (viewModel.rootMessage == nil && newJob != .normal) ||
                (viewModel.rootMessage != nil && !newJob.isReply) {
                saveScheduleDraft()
            }
        case .scheduleMsgEdit(info: _, time: _, type: _):
            self.onInputFinished()
        case .normal:
            saveInputPostDraftWithReplyMessageInfo(nil)
        default:
            break
        }
    }

    func onInputFinished() {
        self.keyboardView.attributedString = NSAttributedString(string: "")
    }

    func onKeyboardJobChanged(oldJob: KeyboardJob?, currentJob: KeyboardJob) {
        self.keyboardView.setupItems(self.keyboardItems(moreItemsDriver: self.moreItemsDriver))
    }

    public func afterMessagesRender() {
        self.viewModel.afterMessagesRender()
    }

    public func onMessengerKeyboardPanelCommit() {}

    public func onMessengerKeyboardPanelCancel() {
    }

    public func onMessengerKeyboardPanelSendTap() {
        keyboardView.sendNewMessage()
    }

    // 键盘定时发送按钮 点击
    public func onMessengerKeyboardPanelSchuduleSendButtonTap() {
    }

    public func scheduleTipDidShow(date: Date) {
    }

    // 点击定时发送时间
    public func onMessengerKeyboardPanelSchuduleSendTimeTap(currentSelectDate: Date,
                                                            sendMessageModel: SendMessageModel,
                                                            _ task: @escaping (Date) -> Void) {
    }

    // 点击 x 号
    public func onMessengerKeyboardPanelSchuduleExitButtonTap() {
    }

    public func onMessengerKeyboardPanelSchuduleCloseButtonTap(itemId: String,
                                                               itemType: RustPB.Basic_V1_ScheduleMessageItem.ItemType) {
    }

    // 点击更新消息
    public func onMessengerKeyboardPanelSchuduleConfrimButtonTap(itemId: String,
                                                                 cid: String,
                                                                 itemType: RustPB.Basic_V1_ScheduleMessageItem.ItemType) {
    }

    // +号菜单点击开始发送定时消息
    public func onMessengerKeyboardPanelScheduleSendTaped(draft: RustPB.Basic_V1_Draft?) {
    }

    func updateAttributedString(message: Message,
                                isInsert: Bool,
                                callback: (() -> Void)?) {
    }

    func insertRichText(richText: RustPB.Basic_V1_RichText) {
    }

    // 长按定时发送
    public func onMessengerKeyboardPanelSendLongPress() {
    }
    public func keyboardContentHeightWillChange(_ isFold: Bool) {
        self.delegate?.keyboardContentHeightWillChange(isFold)
    }
    public func replaceViewWillChange(_ view: UIView?) {
        self.delegate?.replaceViewWillChange(view)
    }

    public func clickChatMenuEntry() {
        self.delegate?.clickChatMenuEntry()
    }

    public func textPasteConfigurationSupporting(_ textPasteConfigurationSupporting: UITextPasteConfigurationSupporting,
        combineItemAttributedStrings itemStrings: [NSAttributedString],
                                          for textRange: UITextRange) -> NSAttributedString? {
        if let styleAttr = itemStrings.first(where: { FontStyleItemProvider.isStyleItemProviderCreateAttr($0) }) {
            return FontStyleItemProvider.removeStyleTagKeyFor(attr: styleAttr)
        }
        return nil
    }

    public func textPasteConfigurationSupporting(_ textPasteConfigurationSupporting: UITextPasteConfigurationSupporting,
                                          transform item: UITextPasteItem) -> Bool {
        if item.itemProvider.canLoadObject(ofClass: FontStyleItemProvider.self), self.supportFontStyle() {
            item.itemProvider.loadObject(ofClass: FontStyleItemProvider.self) { [weak self] obj, error in
                guard error == nil,
                      let fontStyleItem = obj as? FontStyleItemProvider,
                      let self = self else {
                    return
                }
                DispatchQueue.main.async {
                    var attributes: [NSAttributedString.Key: Any] = [.font: LKKeyboardView.Cons.textFont]
                    attributes[.paragraphStyle] = self.keyboardView.inputTextView.defaultTypingAttributes[.paragraphStyle]
                    attributes[.foregroundColor] = self.keyboardView.inputTextView.defaultTypingAttributes[.foregroundColor]
                    if let attr = fontStyleItem.attributeStringWithAttributes(attributes) {
                        item.setResult(attributedString: attr)
                    }
                }
            }
            return true
        }
        return false
    }

    public func pushProfile(chatterId: String) {}
}

final class ChatKeyboardInputOpenHandlerWrapper: TextViewInputProtocol {
    private let handler: ChatKeyboardInputOpenProtocol

    init(_ handler: ChatKeyboardInputOpenProtocol) {
        self.handler = handler
    }

    func register(textView: UITextView) {
        handler.register(textView: textView)
    }

    func textViewDidChange(_ textView: UITextView) {
        handler.textViewDidChange(textView)
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return handler.textView(textView, shouldChangeTextIn: range, replacementText: text)
    }
}
