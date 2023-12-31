//
//  ThreadKeyboard.swift
//  LarkThread
//
//  Created by 李晨 on 2019/2/26.
//

import UIKit
import EENavigator
import Foundation
import Homeric
import LarkAlertController
import LarkAudio
import LarkCanvas
import LarkCore
import LarkRichTextCore
import LarkKeyboardView
import LarkEmotion
import LarkIMMention
import LarkEmotionKeyboard
import LarkSendMessage
import LarkFoundation
import LarkMessageBase
import LarkMessageCore
import LarkMessengerInterface
import LarkModel
import LarkSDKInterface
import LarkUIKit
import LKCommonsLogging
import LKCommonsTracker
import Photos
import Reachability
import UniverseDesignToast
import RustPB
import RxCocoa
import RxSwift
import ByteWebImage
import LarkFeatureGating
import EditTextView
import LarkContainer
import LarkAccountInterface
import LarkBaseKeyboard
import LarkChatOpenKeyboard

protocol ThreadKeyboardDelegate: AnyObject {
    func handleKeyboardAppear()
    func keyboardFrameChange(frame: CGRect)
    func inputTextViewFrameChange(frame: CGRect)
    func rootViewController() -> UIViewController
    func baseViewController() -> BaseUIViewController
    func getKeyboardStartupState() -> KeyboardStartupState
    func setEditingMessage(message: Message?)
    func setScheduleTipViewStatus(_ status: ScheduleMessageStatus)
    func getScheduleMsgSendTime() -> Int64?
    func getSendScheduleMsgIds() -> ([String], [String])
    func jobDidChange(old: KeyboardJob?, new: KeyboardJob)
    var chatFromWhere: ChatFromWhere { get }
}

protocol ThreadKeyboardRouter {
    func showImagePicker(
        showOriginButton: Bool,
        from vc: UIViewController,
        selectedBlock: ((ImagePickerViewController, _ assets: [PHAsset], _ isOriginalImage: Bool) -> Void)?
    )

    func showStickerSetting(from vc: UIViewController)
}
/// thread的默认配置
struct ThreadKeyboardConfig {
    let keyboardNewStyleEnable: Bool
}

class ThreadKeyboard: ThreadKeyboardViewDelegate, UserResolverWrapper {
    var userResolver: UserResolver { viewModel.userResolver }
    static let logger = Logger.log(ThreadKeyboard.self, category: "Module.Keyboard.Message")

    let viewModel: ThreadKeyboardViewModel

    lazy var theadInputAtManager: TheadInputAtManager = {
        return TheadInputAtManager(userResolver: userResolver)
    }()

    lazy var anchorAnalysisService: IMAnchorAnalysisService? = {
        return try? self.viewModel.resolver.resolve(assert: IMAnchorAnalysisService.self)
    }()

    weak var delegate: ThreadKeyboardDelegate?
    let draftCache: DraftCache

    private(set) var keyboardView: ThreadKeyboardView

    private var emotionKeyboard: EmotionKeyboardProtocol? {
        let module: BaseThreadKeyboardEmojiSubModule? = self.getPanelSubModuleForItemKey(key: .emotion)
        return module?.emotionKeyboard
    }

    let disposeBag = DisposeBag()
    private let reachability = Reachability()

    /// 这里有些情况下就不会创建audio的panel
    var audioKeyboardHelper: AudioRecordPanelProtocol? {
        let module: BaseThreadKeyboardVoiceSubModule? = self.getPanelSubModuleForItemKey(key: .voice)
        return module?.audioKeyboardHelper
    }

    var fontPanelSubModule: ThreadKeyboardFontSubModule? {
        let module: ThreadKeyboardFontSubModule? = self.getPanelSubModuleForItemKey(key: .font)
        return module
    }

    /// 翻译数据管理
    lazy var translateDataService: RealTimeTranslateService = {
        return RealTimeTranslateDataManager(targetLanguage: self.viewModel.chat.typingTranslateSetting.targetLanguage,
                                            userResolver: self.viewModel.userResolver)
    }()

    //最后一次点击”使用“时，获得的翻译内容
    var lastTranslationData: (title: String?, content: RustPB.Basic_V1_RichText?)?

    let keyboardNewStyleEnable: Bool
    /// 正常情况下(非匿名)的占位文字
    var normalPlaceHolder: String {
        return viewModel.threadWrapper.thread.value.isFollow ? BundleI18n.LarkThread.Lark_Chat_TopicFollowedReplyPlaceholder
        : BundleI18n.LarkThread.Lark_Chat_Topic_DetailPage_ReplyBox_Hint
    }

    var isAllowReply: Bool {
        if self.viewModel.chat.isFrozen {
            return false
        }
        switch self.viewModel.threadWrapper.thread.value.stateInfo.state {
        case .closed:
            return false
        case .open:
            return true
        case .unknownState:
            return true
        @unknown default:
            assert(false, "new value")
            return false
        }
    }

    @ScopedInjectedLazy private var tenantUniversalSettingService: TenantUniversalSettingService?

    let sendImageProcessor: SendImageProcessor
    init(
        viewModel: ThreadKeyboardViewModel,
        delegate: ThreadKeyboardDelegate?,
        draftCache: DraftCache,
        keyBoardView: ThreadKeyboardView,
        sendImageProcessor: SendImageProcessor,
        keyboardConfig: ThreadKeyboardConfig) {
        self.delegate = delegate
        self.viewModel = viewModel
        self.draftCache = draftCache
        self.keyboardNewStyleEnable = keyboardConfig.keyboardNewStyleEnable
        self.sendImageProcessor = sendImageProcessor
        keyboardView = keyBoardView
        keyBoardView.threadKeyboardDelegate = self
        keyBoardView.expandType = .show
        setupthreadInputView()

        try? reachability?.startNotifier()
        configSubModels()
        keyboardView.setupItems(self.keyboardItems())
        updateKeyboardState()

        self.viewModel.keyboardStatusManagerBlock = { [weak self] in
            return self?.keyboardView.keyboardStatusManager
        }

            updateConfigForTranslate(open: self.viewModel.chat.typingTranslateSetting.isOpen)
            self.viewModel.chatTypingTranslateEnableChanged = { [weak self] () in
                guard let `self` = self else { return }
                self.updateConfigForTranslate(open: self.viewModel.chat.typingTranslateSetting.isOpen)
                self.updatePlaceholder()
            }
            self.viewModel.chatTypingTranslateLanguageChanged = { [weak self] () in
                guard let `self` = self,
                      !self.viewModel.chat.typingTranslateSetting.targetLanguage.isEmpty else { return }
                self.updateTargetLanguage(self.viewModel.chat.typingTranslateSetting.targetLanguage)
                self.keyboardView.translationInfoPreviewView.updateLanguage(self.viewModel.chat.typingTranslateSetting.targetLanguage)
            }

        updatePlaceholder()
        addObservers()
    }

    deinit {
        reachability?.stopNotifier()
    }

    private func configSubModels() {
        let module = self.keyboardView.viewModel.module
        let item = ThreadKeyboardPageItem(threadWrapper: viewModel.threadWrapper,
                                          keyboardView: self.keyboardView,
                                          keyboardStatusManager: self.keyboardView.keyboardStatusManager) { [weak self] in
            return self?.viewModel.replyMessage
        }
        module.context.store.setValue(item, for: ThreadKeyboardPageItem.key)

        let atSubModule: ThreadKeyboardAtUserSubModule? = getPanelSubModuleForItemKey(key: .at)
        atSubModule?.afterInsertCallBack = { [weak self] (type) in
            guard let self = self else { return }
            self.keyboardView.reloadSendButton()
            if type == .at, case .multiEdit = self.keyboardView.keyboardStatusManager.currentKeyboardJob {
                self.keyboardView.updateTipIfNeed(.atWhenMultiEdit)
            }
        }
        self.keyboardView.setupKeyboardModule()
    }

    private func getPanelSubModuleForItemKey<Value>(key: KeyboardItemKey) -> Value? {
        let module = self.keyboardView.module.getPanelSubModuleForItemKey(key)
        return module as? Value
    }

    /// 这个逻辑是企业自定义输入框宣传语
    /// 不管是不是密聊，全场景都要感知，因此只用于暴露placeholder，具体聊天场景根据实际诉求获取然后赋值。
    func getTenantInputBoxPlaceholder() -> String? {
        return tenantUniversalSettingService?.getInputBoxPlaceholder()
    }

    func updatePlaceholder() {
        if self.viewModel.chat.isFrozen {
            self.keyboardView.inputPlaceHolder = BundleI18n.LarkThread.Lark_IM_CantSendMsgThisDisbandedGrp_Desc
        } else if self.viewModel.threadWrapper.thread.value.stateInfo.state == .closed {
            keyboardView.inputPlaceHolder = BundleI18n.LarkThread.Lark_Chat_TopicClosedInputWindowPlaceholder
        } else if case .multiEdit = keyboardView.keyboardStatusManager.currentKeyboardJob {
            keyboardView.inputPlaceHolder = BundleI18n.LarkThread.Lark_IM_EditMessage_DeleteAllAndRecall_EnterNewMessage_Placeholder
        } else if self.viewModel.chat.typingTranslateSetting.isOpen {
            self.keyboardView.inputPlaceHolder = BundleI18n.LarkThread.Lark_IM_TranslationAsYouType_EnterYourPreferredLanguage_Placeholder
        } else {
            let inputPlaceHolder = normalPlaceHolder
            if let tenantInputPlaceholder = getTenantInputBoxPlaceholder() {
                if self.tenantUniversalSettingService?.replaceTenantPlaceholderEnable() ?? false {
                    keyboardView.inputPlaceHolder = tenantInputPlaceholder
                } else {
                    let muattr = NSMutableAttributedString(string: inputPlaceHolder)
                    let font = (self.keyboardView.placeholderTextAttributes[.font] as? UIFont) ?? UIFont.ud.body0
                    muattr.append(TextSplitConstructor.splitTextAttributeStringFor(font: font))
                    muattr.append(NSAttributedString(string: tenantInputPlaceholder))
                    muattr.addAttributes(self.keyboardView.placeholderTextAttributes, range: NSRange(location: 0, length: muattr.length))
                    self.keyboardView.inputTextView.attributedPlaceholder = muattr
                }
            } else {
                keyboardView.inputPlaceHolder = inputPlaceHolder
            }
        }
    }

    func cleanPostDraft() {
        if let editMessage = self.keyboardView.keyboardStatusManager.getMultiEditMessage() {
            viewModel.delegate?.cleanPostDraftWith(key: editMessage.editDraftId,
                                                   id: .multiEditMessage(messageId: editMessage.id, chatId: viewModel.chat.id))
        } else if let replyMessage = self.keyboardView.keyboardStatusManager.getReplyMessage() {
            viewModel.delegate?.cleanPostDraftWith(key: replyMessage.postDraftId,
                                                   id: .replyMessage(messageId: replyMessage.id))
        } else if let scheduleMessage = self.keyboardView.keyboardStatusManager.getScheduleMessage() {
            viewModel.delegate?.cleanPostDraftWith(key: viewModel.chat.scheduleMessageDraftID,
                                                   id: .schuduleSend(chatId: viewModel.chat.id, time: 0, item: Basic_V1_ScheduleMessageItem()))
        } else {
            viewModel.delegate?.cleanPostDraftWith(key: viewModel.chat.postDraftId,
                                                   id: .chat(chatId: viewModel.chat.id))
        }
    }

    //不管以什么原因关闭大框时都调用（包括用户手动关闭大框、在大框发消息、二次编辑保存、定时发送等）
    func onComposePostViewDismiss() {
        keyboardView.resetKeyboardStatusDelagate()
        translateDataServiceBindTextView()
    }

    //发送、二次编辑点保存等动作后 会调用这里
    func onInputFinished() {
        keyboardView.attributedString = NSAttributedString(string: "")
        self.translateDataService.clearOriginAndTranslationData()
        self.keyboardView.translationInfoPreviewView.recallEnable = self.translateDataService.getRecallEnable()
        translateDataService.updateSessionID()
        keyboardView.clearTranslationPreview()
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
        guard self.viewModel.chat.typingTranslateSetting.isOpen else { return }
        let data = RealTimeTranslateData(chatID: self.viewModel.chat.id,
                                         titleTextView: nil,
                                         contentTextView: self.keyboardView.inputTextView,
                                         delegate: self.keyboardView)
        self.translateDataService.bindToTranslateData(data)
        self.keyboardView.translationInfoPreviewView.disableLoadingTemporary()
    }

    func setupAttachment(needToClearTranslationData: Bool = false) {
        assertionFailure("need to be overrided")
    }

    private func keyboardItems() -> [InputKeyboardItem] {
        var isSpecialStatus = false
        let module: BaseThreadKeyboardEmojiSubModule? = self.getPanelSubModuleForItemKey(key: .emotion)
        switch keyboardView.keyboardStatusManager.currentKeyboardJob {
        case .multiEdit, .scheduleSend, .scheduleMsgEdit:
            isSpecialStatus = true
            module?.supportLeftViewInfo = false
        default:
            module?.supportLeftViewInfo = true
            break
        }

        keyboardView.viewModel.module.reloadPanelItems()
        var items = keyboardView.viewModel.module.getPanelItems()
        if isSpecialStatus {
            var supportItemKeys = [KeyboardItemKey.font.rawValue,
                                   KeyboardItemKey.at.rawValue,
                                   KeyboardItemKey.emotion.rawValue]
            items = items.flatMap({ item in
                supportItemKeys.contains(item.key) ? item : nil
            })
        }
        return items
    }

    open func setupStartupKeyboardState() {
        guard let keyboardStartupState = delegate?.getKeyboardStartupState() else {
            assertionFailure()
            ThreadKeyboard.logger.error("LarkThread error: 取不到 keyboard state")
            return
        }
        guard self.isAllowReply else {
            ThreadKeyboard.logger.info("can not action for chatId:\(viewModel.chat.id) threadId:\(viewModel.threadWrapper.thread.value.id) keyboardStartupState: \(keyboardStartupState.type.rawValue)")
            return
        }
        switch keyboardStartupState.type {
        case .none:
            break
        case .inputView:
            keyboardView.inputViewBecomeFirstResponder()
        case .stickerSet:
            keyboardView.keyboardPanel.select(key: KeyboardItemKey.emotion.rawValue)
            if let contentView = keyboardView.keyboardPanel.content as? EmotionKeyboardView,
               let index = contentView.dataSources.firstIndex(where: { (item) -> Bool in
                   item.identifier == "stickerSet-\(keyboardStartupState.info)"
               }) {
                contentView.setSelectIndex(index: index, animation: false)
            }
        }
    }

    func addObservers() {
        keyboardView.inputTextView.rx.value.asDriver()
            .debounce(.seconds(2)).skip(1)
            .drive(onNext: { [weak self] _ in
                guard let strongSelf = self else {
                    return
                }
                if !strongSelf.keyboardView.inputTextView.isFirstResponder {
                    return
                }
                //二次编辑场景不实时存草稿
                if case .multiEdit = strongSelf.keyboardView.keyboardStatusManager.currentKeyboardJob {
                    return
                }
                strongSelf.saveDraftOnTextDidChange()
            }).disposed(by: disposeBag)

        viewModel.threadWrapper.thread
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.updateKeyboardState()
            }).disposed(by: disposeBag)
        self.keyboardView.autoAddAnchorForLinkText()
    }

    /// 根据话题的状态 更新相关的占位符文字 --> 每次新发消息也会调用
    func updateKeyboardState() {
        keyboardView.setSubViewsEnable(enable: isAllowReply)
        if !isAllowReply,
           self.keyboardView.attributedString.length == 0 {
            self.keyboardView.fold()
        }
        updatePlaceholder()
    }

    private func setupthreadInputView() {
        let textViewInputProtocolSet = TextViewInputProtocolSet(textViewInputHanders())
        keyboardView.textViewInputProtocolSet = textViewInputProtocolSet
    }

    public func sendInputContentAsMessage() {
        self.keyboardView.sendNewMessage()
    }

    func textViewInputHanders() -> [TextViewInputProtocol] {
        let atUserInputHandler = AtUserInputHandler(supportPasteStyle: true)
        let emojiInputHandler = EmojiInputHandler(supportFontStyle: self.supportFontStyle())
        let codeInputHandler = CodeInputHandler(supportFontStyle: self.supportFontStyle())
        let returnInputHandler = ReturnInputHandler { [weak self] (_) -> Bool in
            if self?.keyboardView.inputTextView.returnKeyType == .default {
                return true
            }
            self?.sendInputContentAsMessage()
            return false
        }
        returnInputHandler.newlineFunc = { (textView) -> Bool in
            // 搜狗换行会 先输入 \r\r 然后删除一个字符 所以这里需要输入两个 \n
            textView.insertText("\n\n")
            return false
        }

        let atPickerInputHandler = AtPickerInputHandler { [weak self] textView, range, _ in
            guard let textView = textView as? LarkEditTextView else { return }
            textView.resignFirstResponder()
            /// 插入@不应用样式 插入之后需要将B I S U这些字体样式还原
            let defaultTypingAttributes = textView.defaultTypingAttributes
            self?.inputTextViewInputAt(cancel: {
                textView.becomeFirstResponder()
            }, complete: { selectItems in
                // 删除已经插入的at
                textView.selectedRange = NSRange(location: range.location + 1, length: range.length)
                textView.deleteBackward()

                // 插入at标签
                selectItems.forEach { item in
                    switch item {
                    case .chatter(let item):
                        self?.keyboardView.insert(userName: item.name,
                                            actualName: item.actualName,
                                            userId: item.id,
                                            isOuter: item.isOuter)
                    case .doc(let url, let title, let type), .wiki(let url, let title, let type):
                        if let url = URL(string: url) {
                            self?.keyboardView.insertUrl(title: title, url: url, type: type)
                        } else {
                            self?.keyboardView.insertUrl(urlString: url)
                        }
                    }
                }
                textView.defaultTypingAttributes = defaultTypingAttributes
            })
        }

        var handers: [TextViewInputProtocol] = [returnInputHandler,
                                                atPickerInputHandler,
                                                atUserInputHandler,
                                                emojiInputHandler]
        if let urlPreviewAPI = viewModel.urlPreviewAPI {
            handers.append(URLInputHandler(urlPreviewAPI: urlPreviewAPI))
        }
        handers.append(codeInputHandler)
        handers.append(EntityNumInputHandler())
        handers.append(AnchorInputHandler())
        let resourcesCopyFG = self.userResolver.fg.staticFeatureGatingValue(with: "messenger.message.copy")
        if resourcesCopyFG {
            handers.append(CopyVideoInputHandler())
            handers.append(CopyImageInputHandler())
        } else {
            handers.append(ImageAndVideoInputHandler())
        }
        return handers
    }

    fileprivate func showComposeVC(defaultContent: String?,
                                   userActualNameInfoDic: [String: String]?,
                                   replyMessage: Message?,
                                   reeditContent: RichTextContent?,
                                   postItem: ComposePostItem?) {
        keyboardView.fold()

        guard let fromVC = delegate?.baseViewController() else {
            assertionFailure("缺少 From VC")
            return
        }

        var callbacks = ShowComposePostViewCallBacks()
        callbacks.completeCallback = { [weak self] content, time in
            self?.onComposePostViewDismiss()
            self?.onComposePostViewCompleteWith(content, replyMessage: replyMessage, scheduleTime: time)
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
        var body = ComposePostBody(chat: viewModel.chat,
                                   pasteBoardToken: self.keyboardView.pasteboardToken,
                                   dataService: keyboardView.keyboardShareDataService)
        body.postItem = postItem
        body.sendVideoEnable = true
        body.defaultContent = defaultContent
        body.reeditContent = reeditContent
        body.placeholder = keyboardView.inputTextView.attributedPlaceholder
        body.userActualNameInfoDic = userActualNameInfoDic
        body.attachmentServer = viewModel.getCurrentAttachmentServer()
        body.translateService = translateDataService
        body.callbacks = callbacks
        body.isFromMsgThread = viewModel.isReplyInThread
        body.supportRealTimeTranslate = true
        navigator.present(body: body, from: fromVC, animated: false)
    }

    func onComposePostViewCompleteWith(_ richText: RichTextContent, replyMessage: Message?, scheduleTime: Int64?) {
        let transmitToChat = keyboardView.keyboardShareDataService.forwardToChatSerivce.forwardToChat
        keyboardView.keyboardShareDataService.forwardToChatSerivce.messageWillSend(chat: viewModel.chat)
        self.viewModel.delegate?.defaultInputSendPost(content: richText,
                                                      parentMessage: replyMessage,
                                                      scheduleTime: scheduleTime,
                                                      transmitToChat: transmitToChat,
                                                      isFullScreen: true)
    }

    /// 需要刷新一下输入框的数据和状态
    func updateKeyboardStatusIfNeed(_ item: ComposePostItem?) {
    }

    func saveDraftOnTextDidChange() {
        let draftContent = self.keyboardView.richTextStr
        let chatterActualNameMap = AtTransformer.getAllChatterActualNameMapForAttributedString(self.keyboardView.attributedString)
        let model = TextDraftModel(content: draftContent,
                                   userInfoDic: chatterActualNameMap)
        self.viewModel.saveDraft(draftContent: model.stringify())
    }

    public func reEditMessage(message: Message) {
        let supportType: [Message.TypeEnum] = [.post, .text]
        guard supportType.contains(message.type) else {
            return
        }
        ThreadKeyboard.logger.info("reedit message type \(message.type)")
        switch message.type {
        case .text:
            setupTextMessage(message: message)
        case .post:
            setupPostMessage(message: message) { [weak self] in
                self?.updateAttachmentSizeFor(attributedText: self?.keyboardView.attributedString ?? NSAttributedString())
            } beforeApplyCallBack: {  [weak self] attr in
                guard let self = self else {
                    return attr
                }
                var target = attr
                if !AttributedStringAttachmentAnalyzer.canPasteAttrForTextView(self.keyboardView.inputTextView, attr: attr) {
                    target = AttributedStringAttachmentAnalyzer.deleVideoAttachmentForAttr(attr)
                    self.keyboardView.showVideoLimitError()
                }
                CopyToPasteboardManager.addRemoteResourcesCopyTagFor(target)
                return target
            }
        @unknown default:
            break
        }
    }

    public func updateAttributedWith(message: Message, isInsert: Bool = true, callback: (() -> Void)? = nil) {
        switch message.type {
        case .text:
            setupTextMessage(message: message, isInsert: isInsert, callback: callback)
        case .post:
            setupPostMessage(message: message, isInsert: isInsert, callback: callback)
        @unknown default:
            break
        }
    }

    public func multiEditMessage(message: Message) {
        let supportType: [Message.TypeEnum] = [.post, .text]
        guard supportType.contains(message.type) else {
            return
        }
        ThreadKeyboard.logger.info("multiEdit message type \(message.type)")
        if case .multiEdit = self.keyboardView.keyboardStatusManager.currentKeyboardJob {
            self.keyboardView.switchJobWithoutReplaceLastStatus(.multiEdit(message: message))
        } else {
            self.keyboardView.switchJob(.multiEdit(message: message))
        }

        let guideKey = "im_chat_edit_message"
        if let newGuideManager = viewModel.newGuideManager, newGuideManager.checkShouldShowGuide(key: guideKey) {
            keyboardView.updateTipIfNeed(.atWhenMultiEdit)
            newGuideManager.didShowedGuide(guideKey: guideKey)
        }

        self.keyboardView.inputTextView.attributedText = NSAttributedString(string: "")

        if !message.editDraftId.isEmpty {
            self.keyboardView.keyboardStatusManager.multiEditingMessageContent = nil
            self.viewModel.draftCache.getDraft(key: message.editDraftId)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (draft) in
                    guard let self = self else { return }
                    self.updateDraftContent(by: draft.content)
                    self.cleanPostDraft()
                }).disposed(by: self.disposeBag)
            return
        }
        let callBack: (() -> Void) = { [weak self] in
            guard let self = self else { return }
            var contentAttr = self.keyboardView.getTrimTailSpacesAttributedString()
            contentAttr = RichTextTransformKit.preproccessSendAttributedStr(contentAttr)
            if let richText = RichTextTransformKit.transformStringToRichText(string: contentAttr) {
                let lingoInfo = LingoConvertService.transformStringToQuasiContent(contentAttr)
                self.keyboardView.keyboardStatusManager.multiEditingMessageContent = (richText: richText, title: nil, lingoInfo: lingoInfo)
            }
            self.updateAttachmentSizeFor(attributedText: self.keyboardView.attributedString)
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

    func updateDraftContent(by draftStr: String) {}

    public func showShopList() {
        StickerTracker.trackEmotionShopListShow()

        guard let fromVC = delegate?.baseViewController() else {
            assertionFailure("缺少 From VC")
            return
        }

        let body = EmotionShopListBody()
        navigator.present(body: body,
                                 wrap: LkNavigationController.self,
                                 from: fromVC,
                                 prepare: { $0.modalPresentationStyle = .fullScreen })
    }

    // ThreadDetail 不存在父消息的情况。
    func setupTextMessage(message: Message,
                          isInsert: Bool = true,
                          callback: (() -> Void)? = nil) {
        guard let textContent = message.content as? TextContent else {
            return
        }

        let attributes = keyboardView.inputTextView.baseDefaultTypingAttributes
        let processProvider = MessageInlineViewModel.urlInlineProcessProvider(message: message, attributes: attributes)
        let attributedStr = RichTextTransformKit.transformRichTextToStr(
            richText: textContent.richText,
            attributes: attributes,
            attachmentResult: [:],
            processProvider: processProvider
        )
        updateAttributedStringAtInfo(attributedStr) { [weak self] in
            if isInsert {
                self?.keyboardView.inputTextView.insert(attributedStr, useDefaultAttributes: false)
            } else {
                self?.keyboardView.inputTextView.replace(attributedStr, useDefaultAttributes: false)
            }
            callback?()
        }
    }

    func updateAttributedStringAtInfo(_ attributedStr: NSAttributedString, finish: (() -> Void)?) {
        let chatterInfo: [AtChatterInfo] = AtTransformer.getAllChatterInfoForAttributedString(attributedStr)
        /// 撤回重新编辑的时候，本地一定有数据很快就能返回，但是防止数据巨大或者异常时候，做个超时处理
        let chatID = self.viewModel.chat.id
        self.viewModel.chatterAPI.fetchChatChattersFromLocal(ids: chatterInfo.map { $0.id },
                                          chatId: chatID)
            .timeout(.milliseconds(500), scheduler: MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (chatterMapInfo) in
                chatterInfo.forEach { $0.actualName = (chatterMapInfo[$0.id]?.localizedName ?? "") }
                finish?()
            }, onError: { error in
                finish?()
                ThreadKeyboard.logger.error("fetchChatChatters error chatID \(chatID)", error: error)
            }).disposed(by: self.disposeBag)
    }

    // ThreadDetail 不存在父消息的情况。
    func setupPostMessage(message: Message,
                          isInsert: Bool = true,
                          callback: (() -> Void)? = nil,
                          beforeApplyCallBack: ((NSAttributedString) -> NSAttributedString)? = nil) {
        assertionFailure("must be override")
    }

    func supportAtUser() -> Bool {
        return viewModel.chat.type != .p2P
    }
    func updateAttachmentSizeFor(attributedText: NSAttributedString) {}

    func keyboardWillExitJob(currentJob: KeyboardJob, newJob: KeyboardJob, triggerByGoBack: Bool) {
        if triggerByGoBack {
            return
        }
        switch currentJob {
        case .multiEdit(let message):
            if case .multiEdit = newJob {
                break
            }
            saveDraftOnTextDidChange()
            DispatchQueue.main.async { [weak self] in
                self?.onInputFinished()
            }
        case .reply(let message):
            if case .reply = newJob {
                break
            }
            keyboardView.keyboardShareDataService.forwardToChatSerivce.showSyncToCheckBox = false
        default:
            break
        }
    }

    func onKeyboardJobChanged(oldJob: KeyboardJob?, currentJob: KeyboardJob) {
        keyboardView.setupItems(self.keyboardItems())
        var editingMessage: Message?
        func resetKeyTypeIfNeeded(_ newType: UIReturnKeyType) {
            if self.keyboardView.inputTextView.returnKeyType != newType {
                self.keyboardView.inputTextView.returnKeyType = newType
                self.keyboardView.inputTextView.reloadInputViews()
            }
        }
        switch currentJob {
        case .scheduleSend, .scheduleMsgEdit, .multiEdit:
            let newType: UIReturnKeyType = .default
            resetKeyTypeIfNeeded(newType)
            emotionKeyboard?.updateSendBtnIfNeed(hidden: true)
        default:
            let newType: UIReturnKeyType = keyboardNewStyleEnable ? .default : .send
            resetKeyTypeIfNeeded(newType)
            emotionKeyboard?.updateSendBtnIfNeed(hidden: false)

        }
        updatePlaceholder()
        if case .multiEdit(let message) = currentJob {
            editingMessage = message
        }
        self.delegate?.setEditingMessage(message: editingMessage)
        self.delegate?.jobDidChange(old: oldJob, new: currentJob)
    }

    func getTranslationResult() -> (String?, RustPB.Basic_V1_RichText?) {
        return translateDataService.getCurrentTranslateOriginData()
    }

    func getOriginContentBeforeTranslate() -> (String?, NSAttributedString?) {
        return translateDataService.getLastOriginData()
    }

    func clearTranslationData() {
        translateDataService.clearTranslationData()
    }

    func updateTargetLanguage(_ languageKey: String) {
        translateDataService.updateTargetLanguage(languageKey)
    }

    func applyTranslationCallBack(title: String?, content: RustPB.Basic_V1_RichText?) {
        self.lastTranslationData = (title: title, content: content)
        setupAttachment(needToClearTranslationData: true)
    }

    func recallTranslationCallBack() {
        self.translateDataService.refreshTranslateContent()
        self.lastTranslationData = nil
    }

    func transformRichTextToStr(richText: RustPB.Basic_V1_RichText) -> NSAttributedString {
        let attachmentResult: [String: String] = (viewModel as? NewThreadKeyboardViewModel)?.attachmentManager?.attachmentUploader.results ?? [:]
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

    func presentLanguagePicker(currentLanguage: String) {
        guard let vc = self.delegate?.baseViewController() else { return }
        var body = LanguagePickerBody(chatId: self.viewModel.chat.id, currentTargetLanguage: currentLanguage)
        body.targetLanguageChangeCallBack = { [weak self] (chat) in
            self?.keyboardView.translationInfoPreviewView.updateLanguage(chat.typingTranslateSetting.targetLanguage)
            self?.updateTargetLanguage(chat.typingTranslateSetting.targetLanguage)
        }
        body.closeRealTimeTranslateCallBack = { [weak self] _ in
            self?.keyboardView.translationInfoPreviewView.setDisplayable(false)
        }
        navigator.present(body: body, from: vc)
    }

    func previewTranslation(applyButtonCallBack: @escaping (() -> Void)) {
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

    func pushProfile(chatterId: String) {
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

    // MARK: - ThreadInputDelegate
    func inputTextViewDidChange(input: LKKeyboardView) {
        emotionKeyboard?.updateActionBarEnable()
        self.updateTranslateSessionIfNeed()
    }

    private func updateTranslateSessionIfNeed() {
        guard userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "im.chat.manual_open_translate")) else { return }
        if self.viewModel.chat.typingTranslateSetting.isOpen,
           self.keyboardView.inputTextView.attributedText.string.isEmpty {
            self.translateDataService.updateSessionID()
        }
    }

    func inputTextViewWillSend() {
        audioKeyboardHelper?.cleanAudioRecognizeState()
    }

    func inputTextViewSend(attributedText: NSAttributedString, scheduleTime: Int64?) {
        if !attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            var attributedText = attributedText
            attributedText = RichTextTransformKit.preproccessSendAttributedStr(attributedText)
            onInputFinished()
            if let richText = RichTextTransformKit.transformStringToRichText(string: attributedText) {
                let lingoInfo = LingoConvertService.transformStringToQuasiContent(attributedText)
                let transmitToChat = keyboardView.keyboardShareDataService.forwardToChatSerivce.forwardToChat
                keyboardView.keyboardShareDataService.forwardToChatSerivce.messageWillSend(chat: viewModel.chat)
                viewModel.delegate?.defaultInputSendTextMessage(richText,
                                                                lingoInfo: lingoInfo,
                                                                parentMessage: viewModel.replyMessage,
                                                                scheduleTime: scheduleTime,
                                                                transmitToChat: transmitToChat,
                                                                isFullScreen: false)
                let chatterActualNameMap = AtTransformer.getAllChatterActualNameMapForAttributedString(keyboardView.attributedString)
                let model = TextDraftModel(content: keyboardView.richTextStr,
                                           userInfoDic: chatterActualNameMap)
                viewModel.saveDraft(draftContent: model.stringify())
            }
        }
        audioKeyboardHelper?.trackAudioRecognizeIfNeeded()
    }

    func keyboardframeChange(frame: CGRect) {
        delegate?.keyboardFrameChange(frame: frame)
        // 当键盘收起的时候 显示 icon 面板
        if keyboardView.keyboardPanel.contentHeight == 0 {
            audioKeyboardHelper?.cleanMaskView()
        }
    }

    func inputTextViewFrameChange(frame: CGRect) {
        delegate?.inputTextViewFrameChange(frame: frame)
    }

    func inputTextViewBeginEditing() {
        delegate?.handleKeyboardAppear()
    }

    func inputTextViewInputAt(cancel: (() -> Void)?, complete: (([InputKeyboardAtItem]) -> Void)?) {
        if !supportAtUser() {
            return
        }
        theadInputAtManager.inputTextViewInputAt(fromVC: delegate?.baseViewController(),
                                                 chat: viewModel.chat,
                                                 cancel: cancel,
                                                 complete: complete)
        IMTracker.Chat.Main.Click.AtMention(viewModel.chat,
                                            isFullScreen: false,
                                            nil,
                                            threadId: viewModel.threadWrapper.thread.value.id)
    }

    func clickExpandButton() {
        var defaultContent: String?
        var postItem: ComposePostItem?
        var fontBarStatus = FontToolBarStatusItem()
        // try to replace status by bar
        if let status = fontPanelSubModule?.getFontBarStatusItem() {
            fontBarStatus = status
        } else {
            // get defaultTypingAttributes from inputManager
            fontBarStatus = (keyboardView as? NewThreadKeyboardView)?.inputManager.getInputViewFontStatus() ?? FontToolBarStatusItem()
        }

        let range = keyboardView.inputTextView.selectedRange
        if range.length > 0 {
            keyboardView.inputTextView.selectedRange = NSRange(location: range.location, length: 0)
        }
        let firstResponderInfo = (keyboardView.inputTextView.selectedRange, true)
        postItem = ComposePostItem(fontBarStatus: fontBarStatus,
                                   firstResponderInfo: firstResponderInfo)
        let threadID = viewModel.threadWrapper.thread.value.id
        IMTracker.Chat.Main.Click.FullScreen(viewModel.chat, nil, open: true, threadID)
        ChannelTracker.TopicDetail.Click.Post(self.viewModel.chat, self.viewModel.threadWrapper.thread.value.id)
        let userActualNameInfoDic = AtTransformer.getAllChatterActualNameMapForAttributedString(keyboardView.inputTextView.attributedText)
        showComposeVC(defaultContent: defaultContent,
                      userActualNameInfoDic: userActualNameInfoDic,
                      replyMessage: viewModel.replyMessage,
                      reeditContent: nil,
                      postItem: postItem)
        audioKeyboardHelper?.cleanAudioRecognizeState()
        LarkMessageCoreTracker.trackClickKeyboardInputItem(KeyboardItemKey.compose)
    }

    @objc
    func supportFontStyle() -> Bool {
        return false
    }

    func getTrackInfo() -> (chat: Chat, threadId: String) {
        return (viewModel.chat, viewModel.threadWrapper.thread.value.id)
    }

    func keyboardContentHeightWillChange(_ isFold: Bool) {
        keyboardView.keyboardShareDataService.forwardToChatSerivce.isKeyboardFold = isFold
    }

    func replaceViewWillChange(_ view: UIView?) { }

    public func didApplyPasteboardInfo() {
        self.updateAttachmentSizeFor(attributedText: self.keyboardView.attributedString)
        IMCopyPasteMenuTracker.trackPaste(chat: self.viewModel.chat, text: self.keyboardView.attributedString)
    }

    func textPasteConfigurationSupporting(_ textPasteConfigurationSupporting: UITextPasteConfigurationSupporting,
        combineItemAttributedStrings itemStrings: [NSAttributedString],
                                          for textRange: UITextRange) -> NSAttributedString? {
        if let styleAttr = itemStrings.first(where: { FontStyleItemProvider.isStyleItemProviderCreateAttr($0) }) {
            return FontStyleItemProvider.removeStyleTagKeyFor(attr: styleAttr)
        }
        return nil
    }

    func textPasteConfigurationSupporting(_ textPasteConfigurationSupporting: UITextPasteConfigurationSupporting,
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

    func displayVC() -> UIViewController {
       return self.delegate?.baseViewController() ?? UIViewController()
    }

    func reloadPaneItems() {
        keyboardView.setupItems(self.keyboardItems())
    }

    func keyboardAppearForSelectedPanel(item: KeyboardItemKey) {
        if item == .emotion || item == .picture {
            self.delegate?.handleKeyboardAppear()
        }
    }

    func reloadPaneItemForKey(_ key: KeyboardItemKey) {
        guard let item = keyboardView.viewModel.module.getPanelItems().first(where: { $0.key == key.rawValue }),
                  let idx = self.keyboardView.items.firstIndex(where: { $0.key == key.rawValue }) else {
            return
        }
        self.keyboardView.items[idx] = item
        self.keyboardView.keyboardPanel.reloadPanelBtn(key: key.rawValue)
    }
}
