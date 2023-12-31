//
//  ComposePostViewController.swift
//  Lark
//
//  Created by 刘晚林 on 2017/4/2.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import RustPB
import Photos
import RxSwift
import RxCocoa
import LarkUIKit
import LarkModel
import LKCommonsLogging
import LKCommonsTracker
import Homeric
import LarkCore
import LarkRichTextCore
import LarkKeyboardView
import LarkAttachmentUploader
import EditTextView
import UniverseDesignToast
import Kingfisher
import LarkSDKInterface
import LarkMessengerInterface
import LarkAlertController
import LarkContainer
import LarkCanvas
import EENavigator
import ByteWebImage
import LarkFocus
import LarkSetting
import LarkMessageBase
import LarkSplitViewController
import LarkSendMessage
import LarkBaseKeyboard
import LarkOpenKeyboard
import LarkChatOpenKeyboard

public protocol ComposePostRouter: AnyObject {

    var rootVCBlock: (() -> UIViewController?)? { get set }

    func presentAtPicker(
        chat: Chat,
        allowAtAll: Bool,
        allowMyAI: Bool,
        allowSideIndex: Bool,
        cancel: (() -> Void)?,
        complete: (([InputKeyboardAtItem]) -> Void)?
    )

    func pushProfile(chatterId: String)
}

public typealias ComposeSendMsgModel = (Basic_V1_RichText,
                                        String?,
                                        Basic_V1_Message.TypeEnum?)

public protocol ComposePostViewControllerDelegate: AnyObject {

    func updateAttachmentResultInfo()

    func sendPost(scheduleTime: Int64?)

    func didInsertImage(_ viewController: ComposePostViewController)

    /// if a subview is first responder, return true
    func shouldContainFirstResponer() -> Bool

    func willResignFirstResponders()

    func shouldShowKeyboard() -> Bool

    func updateSendButton(isEnabled: Bool)

    func updateTranslationIfNeed()

    func multiEditMessage()

    func onMessengerKeyboardPanelSchuduleSendButtonTap()

    func goBackToLastStatus()

    func scheduleSendMessage()

    func patchScheduleMessage(itemId: String,
                              cid: String,
                              itemType: RustPB.Basic_V1_ScheduleMessageItem.ItemType,
                              isSendImmediately: Bool,
                              needSuspend: Bool)

    func dismissByCancel()
}

public final class ComposePostViewController: BaseUIViewController,
                                              UITextViewDelegate,
                                              UITextPasteDelegate,
                                              UIGestureRecognizerDelegate,
                                              MessengerKeyboardPanelRightContainerViewDelegate,
                                              KeyboardImageContainerProtocol,
                                              KeyboardAtRouteProtocol {

    public var editTextViewWidth: CGFloat = 0

    lazy var atUserAnalysisService: IMAtUserAnalysisService? = {
        return try? self.viewModel.resolver.resolve(assert: IMAtUserAnalysisService.self)
    }()

    lazy var anchorAnalysisService: IMAnchorAnalysisService? = {
        return try? self.viewModel.resolver.resolve(assert: IMAnchorAnalysisService.self)
    }()

    static let logger = Logger.log(ComposePostViewController.self, category: "Module.IM.Message")
    var log = ComposePostViewController.logger
    public weak var delegate: ComposePostViewControllerDelegate?

    fileprivate lazy var contentLongGesture: UILongPressGestureRecognizer = {
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongGesture(gesture:)))
        gesture.delegate = self
        return gesture
    }()

    var textViewInputProtocolSet = TextViewInputProtocolSet()

    // ui 内容输入框
    public private(set) lazy var contentTextView: LarkEditTextView = {
        let textView = LarkEditTextView(config: LarkEditTextView.Config(log:
                                                                            EditTextViewLogger()))
        self.setSupportAtForTextView(textView)
        let pasteboardToken = self.viewModel.pasteBoardToken
        let interactionHandler = CustomTextViewInteractionHandler(pasteboardToken: pasteboardToken)
        interactionHandler.useCustomPasteFragment = true
        textView.interactionHandler = interactionHandler

        /// 这重复代码
        interactionHandler.filterAttrbutedStringBeforePaste = { [weak self] attr, expandInfo in
            guard let self = self else { return attr }
            let chatId = expandInfo["chatId"] ?? ""
            let newAttr = self.atUserAnalysisService?.updateAttrAtUserInfoBeforePasteIfNeed(attr,
                                                                                            textView: self.inputTextView,
                                                                                            isSameChat: chatId == self.viewModel.chatModel?.id) ?? attr
            if !AttributedStringAttachmentAnalyzer.canPasteAttrForTextView(self.contentTextView,
                                                                           attr: newAttr) {
                self.showVideoLimitError()
                return AttributedStringAttachmentAnalyzer.deleVideoAttachmentForAttr(newAttr)
            }
            return newAttr
        }

        interactionHandler.getExpandInfoSaveToPasteBoard = { [weak self] in
            guard let chatId = self?.viewModel.chatModel?.id else { return [:] }
            return ["chatId": chatId]
        }

        interactionHandler.didApplyPasteboardInfo = { [weak self] success, attr, expandInfo in
            guard let self = self, success else { return }
            IMCopyPasteMenuTracker.trackPaste(chat: self.viewModel.chatModel,
                                              text: self.contentTextView.attributedText)
            self.viewModel.attachmentServer.resizeAttachmentView(textView: self.contentTextView,
                                                                 toSize: self.view.bounds.size)
            let chatId = expandInfo["chatId"] ?? ""
            self.analysisUserInfoFor(attr: attr, chatId: chatId)
        }
        return textView
    }()

    /// 底部区域
    private(set) lazy var bottomExtendView = UIView()

    /// 有部分需求会在editTextView和keyboardPanel之间插入其他视图，故把此区域开放出去给外部进行配置
    public let centerContainer: UIView = UIView()

    // 记录 title content textView 是否正在编辑
    // 从 willBegin 开始到 didEndEditing
    var contentIsEditing: Bool = false

    public var keyboardPanel: MessengerKeyboardPanel!
    var pictureKeyboard: AssetPickerSuiteView?

    public var keyboardItems: [InputKeyboardItem] = [] {
        didSet {
            /// 刷新UI
            onkeyboardItemsUpdate()
        }
    }
    public var keyboardViewCache: [Int: UIView] = [:]

    /// 第一次进来显示键盘
    public var shouldShowKeyboard = true

    // 发资源类消息管理类
    lazy var assetManager: AssetPreProcessManager = {
        return AssetPreProcessManager(userResolver: self.viewModel.userResolver, isCrypto: false)
    }()
    let disposeBag = DisposeBag()
    var titleTypingDisposeBag = DisposeBag()
    var contentTypingDisposeBag = DisposeBag()

    let chatFromWhere: ChatFromWhere
    let viewModel: ComposePostViewModel

    lazy var inputManager: PostInputManager = {
        return PostInputManager(inputTextView: self.contentTextView)
    }()

    lazy var fontSubModule: IMComposeKeyboardFontPanelSubModule? = {
        return self.viewModel.module.getPanelSubModuleForItemKey(.font) as? IMComposeKeyboardFontPanelSubModule
    }()

    lazy var atSubModule: IMComposeKeyboardAtUserPanelSubModule? = {
        return self.viewModel.module.getPanelSubModuleForItemKey(.at) as? IMComposeKeyboardAtUserPanelSubModule
    }()

    lazy var pictureModule: IMComposeKeyboardPictruePanelSubModule? = {

        let subModule = self.viewModel.module.getPanelSubModuleForItemKey(.picture) as? IMComposeKeyboardPictruePanelSubModule

        subModule?.hasOtherResponer = { [weak self] in
           return self?.delegate?.shouldContainFirstResponer() ?? false
        }

        subModule?.didFinishInsertAllImagesCallBack = { [weak self] in
            self?.textChanged()
        }

        subModule?.onUpdateAttachmentResultCallBack = { [weak self] in
            self?.delegate?.updateAttachmentResultInfo()
        }

        subModule?.onInserImageAttachment = { [weak self] (_) in
            guard let self = self else { return }
            self.delegate?.didInsertImage(self)
        }

        return subModule
    }()

    var scheduleTime: Int64? {
        if let time = self.scheduleDate?.timeIntervalSince1970 {
            return Int64(time)
        }
        return nil
    }
    private var scheduleDate: Date?
    private var scheduleInitDate: Date?

    public init(viewModel: ComposePostViewModel,
                chatFromWhere: ChatFromWhere) {
        self.viewModel = viewModel
        self.chatFromWhere = chatFromWhere
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        self.isNavigationBarHidden = true
        self.view.backgroundColor = UIColor.ud.bgBody

        self.configContentTextView()
        self.initCenterContainerView()
        self.initInnerBottomView()
        self.initKeyboardPanel()
        self.initInputHandler()

        // 添加长按手势 解决 长按菜单 与 容器滑动 冲突
        self.contentTextView.addGestureRecognizer(self.contentLongGesture)
        self.textChanged()
        self.viewModel.placeHolderUpdateCallBack = { [weak self] (placeHolderText) in
            // 更新占位文字
            self?.updateAttributedPlaceholder(placeHolderText)
        }

        // 更新发送按钮 enable
        self.contentTextView.rx.value.asDriver().drive(onNext: { [weak self] (_) in
            guard let self = self else { return }
            self.textChanged()
        }).disposed(by: self.disposeBag)

        // content view 打点聚焦
        self.contentTextView.rx.didBeginEditing.subscribe(onNext: {[weak self]  (_) in
            guard let `self` = self else { return }

            var trackChatType: PostTracker.ChatType = .group
            if self.viewModel.isMeetingChat {
                trackChatType = .meeting
            } else if self.viewModel.chatType != .group {
                trackChatType = self.viewModel.isBotChat ? .single_bot : .single
            }

            PostTracker.typingInputActive(
                isFirst: true,
                chatType: trackChatType,
                location: .richtext_input)

            var text = self.contentTextView.text
            Observable<Int>.interval(.seconds(5), scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] (_) in
                    guard let `self` = self else { return }
                    if text != self.contentTextView.text {
                        text = self.contentTextView.text
                        PostTracker.typingInputActive(
                            isFirst: false,
                            chatType: trackChatType,
                            location: .richtext_input)

                    }
                }).disposed(by: self.contentTypingDisposeBag)
        }).disposed(by: self.disposeBag)

        self.contentTextView.rx.didEndEditing.subscribe(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            self.contentTypingDisposeBag = DisposeBag()
        }).disposed(by: self.disposeBag)

        self.viewModel.setupModule()
        self.resetPanelItemsFor(keyboardJob: viewModel.keyboardStatusManager.currentKeyboardJob)
        self.anchorAnalysisService?.addObserverFor(textView: self.contentTextView)
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.viewModel.module.viewWillAppear()
        self.contentTextView.updateAttachmentViewData()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.shouldShowKeyboard {
            if Display.pad {
                self.parent?.view.layoutIfNeeded()
            }

            self.shouldShowKeyboard = false
        }
        self.viewModel.module.viewDidAppear()
        self.kbc_viewDidAppear(animated)
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.contentTextView.resignFirstResponder()
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        viewModel.module.viewWillTransition(to: size, with: coordinator)
        self.kbc_viewWillTransition(to: size, with: coordinator)
    }

    public override func splitSplitModeChange(splitMode: SplitViewController.SplitMode) {
        super.splitSplitModeChange(splitMode: splitMode)
        viewModel.module.splitSplitModeChange()
        self.kbc_splitSplitModeChange()
    }

    fileprivate func configContentTextView() {
        contentTextView.maxHeight = 0
        contentTextView.font = Cons.textFont
        contentTextView.textContainerInset = UIEdgeInsets(top: 15, left: 15, bottom: 0, right: 15)
        contentTextView.textColor = UIColor.ud.textTitle
        contentTextView.defaultTypingAttributes = [
            .font: Cons.textFont,
            .foregroundColor: UIColor.ud.textTitle
        ]
        contentTextView.placeholderAlpha = 0.5
        contentTextView.delegate = self
        contentTextView.pasteDelegate = self
        self.view.addSubview(contentTextView)
        contentTextView.snp.makeConstraints({ make in
            make.top.left.right.equalToSuperview()
        })
        contentTextView.setContentHuggingPriority(.defaultLow - 1, for: .vertical)
        contentTextView.backgroundColor = UIColor.ud.bgBody
        updateAttributedPlaceholder(self.viewModel.placeholder)
        contentTextView.setAcceptablePaste(types: [UIImage.self, NSAttributedString.self, FontStyleItemProvider.self])
        inputManager.addParagraphStyle()
    }

    private func updateAttributedPlaceholder(_ text: NSAttributedString) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.lineSpacing = PostInputManager.lineSpace
        let attributes: [NSAttributedString.Key: Any] = [
            .font: Cons.textFont,
            .foregroundColor: UIColor.ud.textTitle,
            .paragraphStyle: paragraphStyle
        ]
        let muAttr = NSMutableAttributedString(attributedString: text)
        muAttr.addAttributes(attributes, range: NSRange(location: 0, length: muAttr.length))
        self.contentTextView.attributedPlaceholder = muAttr
    }

    fileprivate func initCenterContainerView() {
        self.view.addSubview(self.centerContainer)
        self.centerContainer.snp.makeConstraints { (make) in
            make.top.equalTo(contentTextView.snp.bottom)
            make.left.right.equalToSuperview()
            // 这里添加一个低优先级的高度 确保没有撑开的时候 height为0
            make.height.equalTo(0).priority(.low)
        }
    }

    fileprivate func initInnerBottomView() {
        if let syncToChatOptionView = viewModel.syncToChatOptionView {
            bottomExtendView.addSubview(syncToChatOptionView)
            syncToChatOptionView.snp.makeConstraints { make in
                make.edges.equalToSuperview().priority(.required)
            }
        }
        self.view.addSubview(bottomExtendView)
        bottomExtendView.snp.makeConstraints { make in
            make.height.equalTo(0).priority(.low)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalTo(centerContainer.snp.bottom)
        }
    }

    fileprivate func initKeyboardPanel() {
        self.keyboardPanel = MessengerKeyboardPanel()
        self.keyboardPanel.buttonSpace = 32
        self.keyboardPanel.backgroundColor = UIColor.ud.bgBodyOverlay
        self.keyboardPanel.delegate = self
        self.keyboardPanel.rightContainerViewDelegate = self
        self.view.addSubview(keyboardPanel)
        keyboardPanel.snp.makeConstraints { make in
            make.top.equalTo(bottomExtendView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        self.layoutKeyboardIcon()
    }

    fileprivate func initInputHandler() {
        let atUserInputHandler = AtUserInputHandler(supportPasteStyle: !(self.viewModel.chatModel?.isCrypto ?? false))
        let emojiInputHandler = EmojiInputHandler(supportFontStyle: viewModel.supportFontStyle)
        let codeInputHandler = CodeInputHandler(supportFontStyle: viewModel.supportFontStyle)
        let returnInputHandler = ReturnInputHandler { [weak self] (textView) -> Bool in
            guard let `self` = self else { return true }
            if textView == self.contentTextView { return true }
            self.contentTextView.becomeFirstResponder()
            return false
        }

        let atPickerInputHandler = AtPickerInputHandler { [weak self] (textView, range, _) in
            guard let `self` = self, let textView = textView as? LarkEditTextView else { return }
            textView.resignFirstResponder()
            let defaultTypingAttributes = textView.defaultTypingAttributes
            self.chatInputViewInputAt(cancel: {
                textView.becomeFirstResponder()
            }, complete: { (selectItems) in
                // 删除已经插入的at
                textView.selectedRange = NSRange(location: range.location + 1, length: range.length)
                textView.deleteBackward()

                // 插入at标签
                selectItems.forEach { (item) in
                    switch item {
                    case .chatter(let item):
                        self.insert(userName: item.name,
                                    userId: item.id,
                                    actualName: item.actualName,
                                    isOuter: item.isOuter)
                    case .doc(let url, let title, let type), .wiki(let url, let title, let type):
                        if let url = URL(string: url) {
                            self.insertUrl(title: title, url: url, type: type)
                        } else {
                            self.insertUrl(urlString: url)
                        }
                    }
                }
                textView.defaultTypingAttributes = defaultTypingAttributes
            })
        }
        let fontStyleInputHander = FontStyleInputHander(pasteCallBack: { [weak self] in
            self?.fontSubModule?.onChangeSelectionFromPaste()
        }, supportCopyStyle: viewModel.supportFontStyle)

        var inputs: [TextViewInputProtocol] = [fontStyleInputHander,
                                               returnInputHandler,
                                               atPickerInputHandler,
                                               atUserInputHandler,
                                               emojiInputHandler,
                                               codeInputHandler,
                                               EntityNumInputHandler(),
                                               AnchorInputHandler()]
        let resourcesCopyFG = self.viewModel.userResolver.fg.staticFeatureGatingValue(with: "messenger.message.copy")
        let copyVideoInputHandler = CopyVideoInputHandler()
        let copyImageInputHandler = CopyImageInputHandler()
        if resourcesCopyFG {
            inputs.append(copyVideoInputHandler)
            inputs.append(copyImageInputHandler)
        } else {
            inputs.append(ImageAndVideoInputHandler())
        }
        if let urlPreviewAPI = self.viewModel.urlPreviewAPI {
            inputs.append(URLInputHandler(urlPreviewAPI: urlPreviewAPI))
        }
        // 快捷指令输入框全屏编辑，也添加 QuickActionInputHandler，与 Keyboard 保持一致
        if let isAIChat = viewModel.chatModel?.isP2PAi, isAIChat,
            case .quickAction = viewModel.keyboardStatusManager.currentKeyboardJob {
            inputs.append(QuickActionInputHandler())
            // 快捷指令要禁用智能能删除，会误删空格
            contentTextView.smartInsertDeleteType = .no
        }
        if !viewModel.unsupportPasteTypes.isEmpty {
            viewModel.unsupportPasteTypes.forEach { type in
                switch type {
                case .imageAndVideo:
                    inputs.removeAll { $0 === copyImageInputHandler }
                    inputs.removeAll { $0 === copyVideoInputHandler }
                case .emoji:
                    inputs.removeAll { $0 === emojiInputHandler }
                case .fontStyle:
                    inputs.removeAll { $0 === fontStyleInputHander }
                case .code:
                    inputs.removeAll { $0 === codeInputHandler }
                default:
                    break
                }
            }
        }
        let textViewInputProtocolSet = TextViewInputProtocolSet(inputs)
        self.textViewInputProtocolSet = textViewInputProtocolSet
        self.textViewInputProtocolSet.register(textView: self.contentTextView)
    }

    fileprivate func layoutKeyboardIcon() {
        keyboardPanel.layout = .left(24, 12)
    }

    public func sendPostEnable() -> Bool {
        let content = self.contentTextView.text?.lf.trimCharacters(in: .whitespacesAndNewlines, postion: .tail) ?? ""
        return !content.isEmpty
    }

    func chatInputViewInputAt(cancel: (() -> Void)?, complete: (([InputKeyboardAtItem]) -> Void)?) {
        self.atSubModule?.showAtPicker(cancel: cancel, complete: complete)
    }

    private func analysisUserInfoFor(attr: NSAttributedString, chatId: String) {
        guard let chat = self.viewModel.chatModel else { return }
        self.atUserAnalysisService?.updateAttrAtInfoAfterPaste(attr,
                                                               chat: chat,
                                                               textView: self.contentTextView,
                                                               isSameChat: chatId == chat.id,
                                                               finish: nil)
    }

    //提取出图文混排中的所有图片
    public func getAllImageAndVideoIds() -> [String] {
        return getAllImgeIds() + getAllVideoIds()
    }

    func getAllImgeIds() -> [String] {
        guard let attributedText = self.contentTextView.attributedText else {
            return []
        }
        return ImageTransformer.fetchAllImageKey(attributedText: attributedText) + ImageTransformer.fetchAllRemoteImageKey(attributedText: attributedText)
    }

    func getAllVideoIds() -> [String] {
        guard let attributedText = self.contentTextView.attributedText else {
            return []
        }
        return VideoTransformer.fetchAllVideoKey(attributedText: attributedText) + VideoTransformer.fetchAllRemoteVideoKey(attributedText: attributedText)
    }

    func transform(image: UIImage, useOriginal: Bool, callback: @escaping (NSAttributedString) -> Void) {
        self.viewModel.pictureHandlerService?.handlerInsertImageFrom(image,
                                                                     useOriginal: useOriginal,
                                                                     attachmentUploader: self.viewModel.attachmentUploader,
                                                                     sendImageConfig: SendImageConfig(checkConfig: SendImageCheckConfig(isOrigin: useOriginal,
                                                                                                                                        needConvertToWebp: LarkImageService.shared.imageUploadWebP,
                                                                                                                                        scene: .Chat,
                                                                                                                                        biz: .Messenger,
                                                                                                                                        fromType: .post)),
                                                                     encrypt: self.viewModel.chatModel?.isPrivateMode ?? false,
                                                                     fromVC: self,
                                                                     processorId: "messageCore.post") { [weak self] info in
            guard let self = self else { return }
            let content = ImageTransformer.InsertContent("",
                                                         nil,
                                                         info.imageKey,
                                                         nil,
                                                         image.size,
                                                         .normal,
                                                         image,
                                                         self.contentTextView.bounds.width,
                                                         useOriginal,
                                                         fromCopy: false,
                                                         nil,
                                                         nil)
            let attachmentString = ImageTransformer.transformContentToString(content, attributes: [:])
            self.viewModel.attachmentServer.updateImageAttachmentState(attachmentString, gifBackgroundColor: self.contentTextView.backgroundColor) { attachmentString }
            callback(attachmentString)
        }
    }

    func textChanged() {
        reloadSendButton()
        self.delegate?.updateSendButton(isEnabled: self.sendPostEnable())
    }

    func reloadSendButton() {
        self.keyboardPanel.updateSendButtonEnableIfNeed(self.sendPostEnable())
    }

    @objc
    func handleLongGesture(gesture: UIGestureRecognizer) {
        if gesture.state == .began {
            self.swipContainerVC?.panGesture.isEnabled = false
        } else if gesture.state == .ended ||
            gesture.state == .cancelled ||
            gesture.state == .failed {
            self.swipContainerVC?.panGesture.isEnabled = true
        }
    }

    override public func showLoadingHud(_ title: String) -> (() -> Void) {
        let hud = UDToast.showLoading(with: title, on: self.view.window ?? self.view, disableUserInteraction: true)
        return {
            hud.remove()
        }
    }

    public func setupAttachment(needToClearTranslationData: Bool = false) {
        PostDraftManager.setupAttachment(fromVC: self,
                                         contentTextView: self.contentTextView,
                                         attachmentServer: self.viewModel.attachmentServer) { [weak self] in
            if needToClearTranslationData {
                self?.viewModel.translateService?.clearTranslationData()
            }
        }
        self.keyboardPanel.reloadPanel()
    }

    // MARK: - UITextViewDelegate
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return self.kbc_textView(textView, shouldChangeTextIn: range, replacementText: text)
    }

    public func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return self.kbc_textView(textView, shouldInteractWith: textAttachment, in: characterRange, interaction: interaction)
    }

    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return self.textView(textView, shouldInteractWith: URL, in: characterRange, interaction: interaction) { [weak self] chatterId in
            self?.pushProfile(chatterId: chatterId)
        }
    }

    private func pushProfile(chatterId: String) {
        guard let from = self.viewModel.rootVC else {
            assertionFailure()
            return
        }
        let body = PersonCardBody(chatterId: chatterId)
        self.viewModel.navigator.presentOrPush(
            body: body,
            wrap: LkNavigationController.self,
            from: from,
            prepareForPresent: { vc in
                vc.modalPresentationStyle = .formSheet
            })
    }

    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        let value = self.kbc_textViewShouldBeginEditing(textView)
        if textView == self.contentTextView {
            self.contentIsEditing = true
        }
        return value
    }

    public func textViewDidBeginEditing(_ textView: UITextView) {
        keyboardPanel.reloadPanelBtn(key: KeyboardItemKey.at.rawValue)
        keyboardPanel.reloadPanelBtn(key: KeyboardItemKey.emotion.rawValue)
        keyboardPanel.reloadPanelBtn(key: KeyboardItemKey.picture.rawValue)
        keyboardPanel.reloadPanelBtn(key: KeyboardItemKey.canvas.rawValue)
        keyboardPanel.reloadPanelBtn(key: KeyboardItemKey.font.rawValue)
        keyboardPanel.reloadPanelBtn(key: KeyboardItemKey.burnTime.rawValue)
    }

    public func textViewDidChange(_ textView: UITextView) {
        self.kbc_textViewDidChange(textView)
        self.textChanged()
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        if textView == self.contentTextView {
            self.contentIsEditing = false
        }

        let needShowKeyboard = self.delegate?.shouldShowKeyboard() ?? false

        if !needShowKeyboard && !self.contentIsEditing {
            self.kbc_textViewDidEndEditing(textView)
        }
    }

    // MARK: - UITextPasteDelegate
    public func textPasteConfigurationSupporting(_ textPasteConfigurationSupporting: UITextPasteConfigurationSupporting,
                                                 transform item: UITextPasteItem) {
        // 这个部分主要负责处理 UIImage in NSAttachment 与 CustomAttachmentView & upload if needed 的转换
        Self.logger.info("textPasteConfigurationSupporting \(viewModel.chatId)")
        if item.itemProvider.canLoadObject(ofClass: NSAttributedString.self) {
            item.itemProvider.loadObject(
                ofClass: NSAttributedString.self,
                completionHandler: { [weak self] object, error in
                    guard error == nil, let string = object as? NSAttributedString, let `self` = self else {
                        Self.logger.error("Failed to load NSAttributedString from UITextPasteItem: " +
                                            "\(String(describing: error))")
                        return
                    }
                    let mutableString = NSMutableAttributedString(attributedString: string)
                    let range = NSRange(location: 0, length: string.length)
                    mutableString.setAttributes(self.inputManager.baseTypingAttributes(), range: range)
                    // 处理剪贴板中的图片
                    // 因为可能会新建 ImageAsset，初始化 CustomView 时应该在主线程
                    let group = DispatchGroup()
                    DispatchQueue.main.async {
                        string.enumerateAttribute(.attachment, in: range, options: [], using: { raw, range, _ in
                            guard let attachment = raw as? NSTextAttachment else { return }
                            // 如果是已经存在的 CustomTextAttachment 的拖动行为，直接加入
                            if let custom = attachment as? CustomTextAttachment {
                                mutableString.replaceCharacters(in: range, with: NSAttributedString(attachment: custom))
                                return
                            }
                            // 否则将 image 构建到新的 CustomTextAttachment，并执行上传逻辑
                            var optionalImage = attachment.image
                            if optionalImage == nil, let file = attachment.fileWrapper, file.isRegularFile,
                               let data = attachment.fileWrapper?.regularFileContents {
                                optionalImage = UIImage(data: data)
                            }
                            guard let image = optionalImage else {
                                Self.logger.warn("failed to fetch image from attributed string")
                                return
                            }
                            group.enter()
                            self.transform(image: image, useOriginal: true, callback: { attributeString in
                                mutableString.replaceCharacters(in: range, with: attributeString)
                                group.leave()
                            })
                        })
                        group.notify(queue: .main) {
                            item.setResult(attributedString: mutableString)
                        }
                    }
                }
            )
        } else if item.itemProvider.canLoadObject(ofClass: UIImage.self) {
            // 如果只是纯图片
            item.itemProvider.loadObject(ofClass: UIImage.self, completionHandler: { [weak self] object, error in
                guard error == nil, let image = object as? UIImage, let `self` = self else {
                    Self.logger.error("Failed to load UIImage from UITextPasteItem: " +
                                        "\(String(describing: error))")
                    return
                }
                // 因为可能会新建 ImageAsset，初始化 CustomView 时应该在主线程
                DispatchQueue.main.async { [weak self] in
                    self?.transform(image: image, useOriginal: true, callback: { attributeString in
                        item.setResult(attributedString: attributeString)
                    })
                }
            })
        } else if item.itemProvider.canLoadObject(ofClass: FontStyleItemProvider.self), viewModel.supportFontStyle {
            item.itemProvider.loadObject(ofClass: FontStyleItemProvider.self) { [weak self] obj, error in
                guard error == nil,
                      let fontStyleItem = obj as? FontStyleItemProvider,
                      let self = self else {
                    return
                }
                let attributes = self.inputManager.baseTypingAttributes()
                DispatchQueue.main.async {
                    if let attr = fontStyleItem.attributeStringWithAttributes(attributes) {
                        item.setResult(attributedString: attr)
                    }
                }
            }
        } else {
            item.setDefaultResult()
        }
    }

    public func textPasteConfigurationSupporting(
        _ textPasteConfigurationSupporting: UITextPasteConfigurationSupporting,
        combineItemAttributedStrings itemStrings: [NSAttributedString],
        for textRange: UITextRange) -> NSAttributedString {
        if let styleAttr = itemStrings.first { FontStyleItemProvider.isStyleItemProviderCreateAttr($0) } {
            return FontStyleItemProvider.removeStyleTagKeyFor(attr: styleAttr)
        }
        let muAttr = NSMutableAttributedString()
        itemStrings.forEach { attr in
            muAttr.append(attr)
        }
        return muAttr
    }
    public func textPasteConfigurationSupporting(
        _ textPasteConfigurationSupporting: UITextPasteConfigurationSupporting,
        shouldAnimatePasteOf attributedString: NSAttributedString,
        to textRange: UITextRange) -> Bool {
        return false
    }
    // MARK: - UIGestureRecognizerDelegate
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    public func onMessengerKeyboardPanelCommit() {
        switch viewModel.keyboardStatusManager.currentKeyboardJob {
        case .multiEdit(_):
            IMTracker.Chat.Main.Click.Msg.saveEditMsg(self.viewModel.chatModel,
                                                      viewModel.keyboardStatusManager.getMultiEditMessage(),
                                                      triggerMethod: .click_save,
                                                      self.chatFromWhere)
            delegate?.multiEditMessage()

        case .scheduleSend:
            delegate?.onMessengerKeyboardPanelSchuduleSendButtonTap()
        default:
            assertionFailure("error entrance")
            break
        }
    }

    public func onMessengerKeyboardPanelCancel() {
        delegate?.goBackToLastStatus()
    }

    public func onMessengerKeyboardPanelSendTap() {
        LarkMessageCoreTracker.trackComposePostInputItem(KeyboardItemKey.send)
        delegate?.sendPost(scheduleTime: nil)
    }

    private func getHasScheduleMsg() -> Observable<Bool> {
        let chatId = viewModel.chatId
        var threadId: Int64?
        if viewModel.isFromMsgThread {
            switch viewModel.keyboardStatusManager.currentKeyboardJob {
            case .reply(let info):
                threadId = Int64(info.message.threadId) ?? 0
            default:
                break
            }
        }
        return viewModel.messageAPI?.getScheduleMessages(chatId: Int64(chatId) ?? 0,
                                                         threadId: threadId,
                                                         rootId: nil,
                                                         isForceServer: false,
                                                         scene: threadId == nil ? .chatOnly : .replyInThread)
            .map { res in
                let status = ChatScheduleSendTipViewModel.getScheduleTypeFrom(messageItems: res.messageItems, entity: res.entity)
                Self.logger.info("getScheduleMessages chatId: \(chatId), res.messageItemsCount:\(res.messageItems.count), status: \(status)")
                return res.messageItems.isEmpty == false
            } ?? .empty()
    }

    public func onMessengerKeyboardPanelSendLongPress() {
        // 话题群/话题模式不支持创建
        if viewModel.chatModel?.chatMode == .threadV2 || viewModel.chatModel?.displayInThreadMode == true { return }
        // my ai不支持创建
        if viewModel.chatModel?.isP2PAi == true { return }
        if viewModel.isForwardToChat {
            UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_IM_AlsoSendGroup_CantSendScheduleMsg_Toast, on: self.view)
            return
        }
        guard self.viewModel.scheduleSendService?.scheduleSendEnable ?? false else { return }
        // 密盾聊、密聊、临时入会不支持
        if viewModel.chatModel?.isPrivateMode == true || viewModel.chatModel?.isCrypto == true || viewModel.chatModel?.isInMeetingTemporary == true { return }

        if self.viewModel.getScheduleMsgSendTime?() != nil {
            IMTracker.Chat.Main.Click.Msg.msgDelayedSendToastView(self.viewModel.chatModel, self.chatFromWhere)
            UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_CanSendOnly1ScheduledMessage_Tooltip, on: self.view)
            return
        }
        let vm = self.viewModel
        // 需要check下其他场景有无发送
        getHasScheduleMsg()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] hasScheduleMsg in
                guard let `self` = self else { return }
                guard !hasScheduleMsg else {
                    UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_CanSendOnly1ScheduledMessage_Tooltip, on: self.view)
                    IMTracker.Chat.Main.Click.Msg.msgDelayedSendToastView(self.viewModel.chatModel, self.chatFromWhere)
                    return
                }
                // 大于当前时间5分钟
                let currentInitDate = Date().addingTimeInterval(5 * 60)
                let currentSelectDate = ScheduleSendManager.getFutureHour(Date())
                IMTracker.Chat.Main.Click.Msg.delayedSendMobile(self.viewModel.chatModel, self.chatFromWhere)
                self.viewModel.scheduleSendService?.showDatePicker(currentInitDate: currentInitDate,
                                                                   currentSelectDate: currentSelectDate,
                                                      from: self) { [weak self] time in
                    guard let `self` = self else { return }
                    IMTracker.Chat.Main.Click.Msg.msgDelayedSendTimeClick(self.viewModel.chatModel, self.chatFromWhere)
                    self.getHasScheduleMsg()
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { [weak self] hasScheduleMsg in
                            guard let `self` = self else { return }
                            guard !hasScheduleMsg else {
                                UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_CanSendOnly1ScheduledMessage_Tooltip, on: self.view)
                                IMTracker.Chat.Main.Click.Msg.msgDelayedSendToastView(self.viewModel.chatModel, self.chatFromWhere)
                                return
                            }
                            vm.setScheduleTipStatus?(.creating)
                            let formatTime = ScheduleSendManager.formatSendScheduleTime(time)
                            self.delegate?.sendPost(scheduleTime: formatTime)
                            // 删除草稿
                            vm.draftCache?.deleteScheduleDraft(key: vm.getScheduleDraftId(), messageId: vm.keyboardStatusManager.getReplyMessage()?.id, chatId: vm.chatModel?.id ?? "")
                    }).disposed(by: self.disposeBag)
                }
            }).disposed(by: self.disposeBag)
    }

    func resetPanelItemsFor(keyboardJob: KeyboardJob = .normal) {
        pictureModule?.supportVideoContent = self.viewModel.supportVideoContent
        self.viewModel.module.reloadPanelItems()
        self.keyboardItems = self.viewModel.module.getPanelItems()
        if case .quickAction = keyboardJob {
            self.keyboardItems = []
        }
    }

    public func getPostAttachmentServer() -> LarkBaseKeyboard.PostAttachmentServer? {
        self.viewModel.attachmentServer
    }
}

// MARK: - Insert NSAttributedString
extension ComposePostViewController {
    func insert(userName: String,
                userId: String = "",
                actualName: String,
                isOuter: Bool = false) {
        if userId == self.viewModel.myAIService?.defaultResource.mockID {
            let selectMyAICallBack = self.viewModel.selectMyAICallBack
            dismiss(animated: true) { [weak self] in
                self?.delegate?.dismissByCancel()
                self?.viewModel.dataService.myAIInlineService?.openMyAIInlineMode(source: .mention)
                selectMyAICallBack?()
            }
            return
        }
        KeyboardPanelAtUserManager.insert(inputTextView: self.contentTextView,
                                          userName: userName,
                                          actualName: actualName,
                                          userId: userId,
                                          isOuter: isOuter)

        if case .multiEdit = self.viewModel.keyboardStatusManager.currentKeyboardJob {
            self.viewModel.keyboardStatusManager.addTip(.atWhenMultiEdit)
        }
    }

    public func insertUrl(title: String, url: URL, type: RustPB.Basic_V1_Doc.TypeEnum) {
        KeyboardPanelAtUserManager.insertUrl(inputTextView: self.contentTextView, title: title, url: url, type: type)
        self.keyboardPanel.reloadPanelBtn(key: KeyboardItemKey.send.rawValue)
    }

    func insertUrl(urlString: String) {
        guard let urlAPI = self.viewModel.urlPreviewAPI else {
            return
        }
        KeyboardPanelAtUserManager.insertUrl(inputTextView: self.contentTextView,
                                             urlPreviewAPI: urlAPI,
                                             urlString: urlString,
                                             disposeBag: self.disposeBag) { [weak self] in
            self?.reloadSendButton()
        }
    }
}

public extension ComposePostViewController {

    enum Cons {
        public static var textFont: UIFont { UIFont.ud.body0 }
    }

    func showDefaultError(error: Error) {
        guard let window = self.view.window else {
            return
        }
        UDToast.showFailure(
            with: BundleI18n.LarkMessageCore.Lark_Legacy_ErrorMessageTip, on: window, error: error
        )
    }

    func showVideoLimitError() {
        if let window = self.currentWindow() {
            UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_Chat_TopicCreateSelectVideoError, on: window)
        }
    }
}

// MARK: KeyboardSchuduleSendButtonDelegate
extension ComposePostViewController {
    public func scheduleTipDidShow(date: Date) {
        guard let vm = self.viewModel as? ComposePostViewModel else { return }
        // 初始化当前的时间
        let formatDate = ScheduleSendManager.formatSendScheduleDate(date)
        self.scheduleDate = formatDate
    }

    // 按下定时消息按钮
    public func onMessengerKeyboardPanelSchuduleSendButtonTap() {
        self.delegate?.onMessengerKeyboardPanelSchuduleSendButtonTap()
    }

    // 初次发送选择关闭
    public func onMessengerKeyboardPanelSchuduleExitButtonTap() {
        guard let vm = self.viewModel as? ComposePostViewModel else { return }
        let chatFromWhere = self.chatFromWhere
        vm.scheduleSendService?.showAlertWhenSchuduleExitButtonTap(from: self,
                                                                   chatID: Int64(vm.chatModel?.id ?? "") ?? 0,
                                                                   closeTask: {
            // 恢复输入框状态
            if case .scheduleSend = vm.keyboardStatusManager.lastKeyboardJob {
                vm.keyboardStatusManager.switchToDefaultJob()
            } else {
                vm.keyboardStatusManager.goBackToLastStatus()
            }
            IMTracker.Chat.Main.Click.Msg.msgDelayedSendClick(vm.chatModel, click: "delete", chatFromWhere)
            // 删除草稿
            vm.draftCache?.deleteScheduleDraft(key: vm.getScheduleDraftId(), messageId: vm.keyboardStatusManager.getReplyMessage()?.id, chatId: vm.chatModel?.id ?? "")
        },
                                                                  continueTask: {})
    }

    public func updateTip(_ tip: KeyboardTipsType) {
        guard let vm = self.viewModel as? ComposePostViewModel else { return }
        vm.keyboardStatusManager.addTip(tip)
    }

    // 定时消息再次编辑后关闭
    public func onMessengerKeyboardPanelSchuduleCloseButtonTap(itemId: String,
                                                               itemType: RustPB.Basic_V1_ScheduleMessageItem.ItemType) {
        guard let vm = self.viewModel as? ComposePostViewModel else { return }
        vm.scheduleSendService?.showAlertWhenSchuduleCloseButtonTap(from: self,
                                                                    chatID: Int64(vm.chatId) ?? 0,
                                                                    itemId: itemId,
                                                                    itemType: itemType,
                                                                    cancelTask: {
            // 删除草稿
            vm.draftCache?.deleteScheduleDraft(key: vm.getScheduleDraftId(), messageId: vm.keyboardStatusManager.getReplyMessage()?.id, chatId: vm.chatModel?.id ?? "")
            vm.keyboardStatusManager.goBackToLastStatus()
        },
                                                                   closeTask: { [weak self] in
            IMTracker.Chat.Main.Click.Msg.msgDelayedSendClick(vm.chatModel, click: "delete", self?.chatFromWhere)
            // 删除草稿
            vm.draftCache?.deleteScheduleDraft(key: vm.getScheduleDraftId(), messageId: vm.keyboardStatusManager.getReplyMessage()?.id, chatId: vm.chatModel?.id ?? "")
            vm.keyboardStatusManager.goBackToLastStatus()
            vm.setScheduleTipStatus?(.delete)
            // 如果定时消息已经发送/删除，弹toast后恢复普通输入框
            if let ids = vm.getSendScheduleMsgIds?(), ids.0.contains { $0 == itemId } || ids.1.contains { $0 == itemId }, let window = self?.view.window {
                UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_IM_ScheduledMessage_RepeatOperationFailed_Toast, on: window)
                return
            }
        },
                                                                   continueTask: {})
    }

    // 定时消息再次编辑后确认
    public func onMessengerKeyboardPanelSchuduleConfrimButtonTap(itemId: String,
                                                                 cid: String,
                                                                 itemType: RustPB.Basic_V1_ScheduleMessageItem.ItemType) {
        delegate?.patchScheduleMessage(itemId: itemId,
                                       cid: cid,
                                       itemType: itemType,
                                       isSendImmediately: false,
                                       needSuspend: true)
    }

    // 编辑发送时间
    public func onMessengerKeyboardPanelSchuduleSendTimeTap(currentSelectDate: Date,
                                                            sendMessageModel: SendMessageModel,
                                                            _ task: @escaping (Date) -> Void) {
        guard let vm = self.viewModel as? ComposePostViewModel, let chat = self.viewModel.chatModel else { return }
        // 初始化当前的时间
        self.scheduleDate = currentSelectDate
        self.scheduleInitDate = currentSelectDate
        vm.scheduleSendService?
            .showDatePickerInEdit(currentSelectDate: currentSelectDate,
                                  chatName: chat.name,
                                  from: self,
                                  isShowSendNow: !(sendMessageModel.cid.isEmpty && sendMessageModel.messageId.isEmpty),
                                  sendNowCallback: { [weak self] in
                IMTracker.Chat.Main.Click.Msg.msgDelayedSendClick(chat, click: "send_immediate", self?.chatFromWhere)
                self?.delegate?.patchScheduleMessage(itemId: sendMessageModel.messageId,
                                                     cid: sendMessageModel.cid,
                                                     itemType: sendMessageModel.itemType,
                                                     isSendImmediately: true,
                                                     needSuspend: false)
            },
                                  confirmTask: { [weak self] date in
                if let initDate = self?.scheduleInitDate, date != initDate {
                    IMTracker.Chat.Main.Click.Msg.msgDelayedSendClick(chat, click: "modify_time", self?.chatFromWhere)
                }
                task(date)
                self?.scheduleDate = date
                })
    }
}

extension KeyboardJob {
    // 是否是footbar的紧凑布局
    public var isFontBarCompactLayout: Bool {
        switch self {
        case .multiEdit, .scheduleMsgEdit:
            return true
        default:
            return false
        }
    }
}

/// module 相关的
extension ComposePostViewController {

    func updateWithUIWithFontBarStatusItem(_ status: FontToolBarStatusItem) {
        self.fontSubModule?.updateWithUIWithFontBarStatusItem(status)
    }

    func hideFontActionBar() {
        self.fontSubModule?.hideFontActionBar()
    }

    func getCurrentStatusItem() -> FontToolBarStatusItem? {
       return self.fontSubModule?.getFontBarStatusItem()
    }

    public func uploadFailsImageIfNeed(finish: ((Bool) -> Void)?) {
        self.pictureModule?.uploadFailsImageIfNeed(finish: finish)
    }
}

extension ComposePostViewController: ComposeOpenKeyboardService {

    public func getRootVC() -> UIViewController? {
        return self.viewModel.rootVC
    }

    public var inputTextView: EditTextView.LarkEditTextView {
        self.contentTextView
    }

    public var inputKeyboardPanel: LarkKeyboardView.KeyboardPanel {
        return self.keyboardPanel
    }

    public var inputProtocolSet: EditTextView.TextViewInputProtocolSet? {
        return self.textViewInputProtocolSet
    }

    public func displayVC() -> UIViewController {
        return self
    }

    public func reloadPaneItems() {
        let currentKeyboardJob = viewModel.keyboardStatusManager.currentKeyboardJob
        self.resetPanelItemsFor(keyboardJob: currentKeyboardJob)
    }

    public func keyboardAppearForSelectedPanel(item: LarkKeyboardView.KeyboardItemKey) {
    }

    public func getReplyMessage() -> Message? {
        return self.viewModel.keyboardStatusManager.getReplyMessage()
    }

    public var keyboardStatusManager: KeyboardStatusManager {
        return self.viewModel.keyboardStatusManager
    }

    public func dismissByCancel() {
        self.delegate?.dismissByCancel()
    }

    public func reloadPaneItemForKey(_ key: KeyboardItemKey) {
        guard let item = viewModel.module.getPanelItems().first(where: { $0.key == key.rawValue }),
        let idx = self.keyboardItems.firstIndex(where: { $0.key == key.rawValue }) else {
            return
        }
        self.keyboardItems[idx] = item
        self.keyboardPanel.reloadPanelBtn(key: key.rawValue)
    }
}
