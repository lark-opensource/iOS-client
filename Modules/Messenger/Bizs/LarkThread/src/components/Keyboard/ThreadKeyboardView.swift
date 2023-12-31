//
//  ThreadInputView.swift
//  LarkThread
//
//  Created by 李晨 on 2019/2/26.
//

import Foundation
import UIKit
import RustPB
import RxCocoa
import RxSwift
import LarkModel
import LarkUIKit
import LarkCore
import LarkContainer
import TangramService
import LarkBaseKeyboard
import LarkKeyboardView
import LKCommonsLogging
import LarkMessengerInterface
import LarkFeatureGating
import LarkMessageCore
import LarkMessageBase
import LarkSDKInterface
import UniverseDesignToast
import LarkSetting
import LarkOpenKeyboard
import LarkChatOpenKeyboard

protocol ThreadKeyboardViewDelegate: IMKeyboardDelegate, KeyboardRealTimeTranslateDelegate {
    func updateAttachmentSizeFor(attributedText: NSAttributedString)
    func getTrackInfo() -> (chat: Chat, threadId: String)
    func keyboardWillExitJob(currentJob: KeyboardJob, newJob: KeyboardJob, triggerByGoBack: Bool)
    func onKeyboardJobChanged(oldJob: KeyboardJob?, currentJob: KeyboardJob)
    func didApplyPasteboardInfo()
    func pushProfile(chatterId: String)
    func displayVC() -> UIViewController
    func reloadPaneItems()
    func keyboardAppearForSelectedPanel(item: KeyboardItemKey)
    func reloadPaneItemForKey(_ key: KeyboardItemKey)
}
class ThreadKeyboardView: MessengerKeyboardView {

    @ScopedInjectedLazy var urlPreviewAPI: URLPreviewAPI?
    @ScopedInjectedLazy private var chatAPI: ChatAPI?
    fileprivate let disposeBag = DisposeBag()
    static let logger = Logger.log(ThreadKeyboardView.self, category: "Module.LarkThread")

    lazy var inputManager: PostInputManager = {
        return PostInputManager(inputTextView: self.inputTextView)
    }()
    private var keyboardViewWidth: CGFloat = UIScreen.main.bounds.width

    private let chatWrapper: ChatPushWrapper

    var chat: Chat {
        return chatWrapper.chat.value
    }

    weak var threadKeyboardDelegate: ThreadKeyboardViewDelegate? {
        didSet {
            self.delegate = self.threadKeyboardDelegate
        }
    }

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
        let translationContainerView = TranslationInfoPreviewContainerView(targetLanguage: chat.typingTranslateSetting.targetLanguage ?? "",
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
        return self.threadKeyboardDelegate
    }

    fileprivate lazy var syncToChatOptionView: UIView? = {
        return keyboardShareDataService.forwardToChatSerivce.getView(isInComposeView: false, chat: chat)
    }()

    init(chatWrapper: ChatPushWrapper,
         viewModel: IMKeyboardViewModel,
         pasteboardToken: String,
         keyboardNewStyleEnable: Bool,
         supportRealTimeTranslate: Bool) {
        self.chatWrapper = chatWrapper
        super.init(frame: CGRect.zero,
                   viewModel: viewModel,
                   pasteboardToken: pasteboardToken,
                   keyboardNewStyleEnable: keyboardNewStyleEnable)

        self.inputPlaceHolder = BundleI18n.LarkThread.Lark_Chat_TopicFollowedReplyPlaceholder
        if !keyboardNewStyleEnable {
            self.keyboardPanel.layout = self.createLayout()
        }

        if supportRealTimeTranslate {
            self.inputStackView.insertArrangedSubview(translationContainerView, at: 0)
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
        } else {
            self.controlContainer.snp.remakeConstraints { make in
                make.top.equalToSuperview()
                make.left.equalToSuperview()
                make.right.equalToSuperview()
            }
        }

        if let syncToChatOptionView = syncToChatOptionView {
            self.inputContainerInnerBottomView.addSubview(syncToChatOptionView)
            syncToChatOptionView.snp.makeConstraints { make in
                make.edges.equalToSuperview().priority(.required)
            }
        }
        self.setupObservers()
    }

    private func updateInputContainerInnerBottomView() {
        if case .reply(info: let info) = keyboardStatusManager.currentKeyboardJob {
            keyboardShareDataService.forwardToChatSerivce.showSyncToCheckBox = true
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !keyboardNewStyleEnable {
            if self.keyboardViewWidth != self.bounds.width {
                self.keyboardViewWidth = self.bounds.width
                self.keyboardPanel.layout = self.createLayout()
            }
        }
    }

    override open func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return self.textView(textView, shouldInteractWith: URL, in: characterRange, interaction: interaction) { [weak self] chatterId in
            self?.threadKeyboardDelegate?.pushProfile(chatterId: chatterId)
        }
    }

    func clearTranslationPreview() {
        self.translationInfoPreviewView.clearData()
    }

    func insert(userName: String, actualName: String, userId: String = "", isOuter: Bool, isAnonymous: Bool = false) {
        if !userId.isEmpty {
            let info = AtChatterInfo(id: userId,
                                     name: userName,
                                     isOuter: isOuter,
                                     actualName: actualName,
                                     isAnonymous: isAnonymous)
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

    func insertUrl(urlString: String) {
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

    func insertEmoji(_ emoji: String) {
        let selectedRange: NSRange = self.inputTextView.selectedRange
        if self.textViewInputProtocolSet.textView(self.inputTextView, shouldChangeTextIn: selectedRange, replacementText: emoji) {
            let emojiStr = EmotionTransformer.transformContentToString(emoji, attributes: inputManager.baseTypingAttributes())
            self.inputTextView.insert(emojiStr, useDefaultAttributes: false)
        }
        reloadSendButton()
    }

    private func setupObservers() {
        self.keyboardPanel.observeKeyboard = false
        self.inputTextView.rx.didEndEditing.subscribe(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
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
        }).disposed(by: self.disposeBag)
    }

    private func createLayout() -> KeyboardPanel.Layout {
        if Display.pad {
            return .left(26)
        } else {
            if keyboardNewStyleEnable {
                return .left(20)
            }
            switch keyboardStatusManager.currentKeyboardJob {
            case .multiEdit, .scheduleSend, .scheduleMsgEdit:
                return .left(20)
            default:
                break
            }
            let screenWidth = keyboardViewWidth
            return .custom({ (_ panel: KeyboardPanel, _ keyboardIcon: UIView, _ key: String, _ index: Int) in
                keyboardIcon.snp.remakeConstraints({ (make) in
                    make.size.equalTo(KeyboardPanel.ButtonSize)
                    make.centerY.equalToSuperview()
                    // 确保按照5个按钮，从左向右排列，第三个保持居中
                    let inset: CGFloat = 10
                    let interval = (screenWidth - KeyboardPanel.ButtonSize.width - inset * 2) / 4
                    let offset = inset + KeyboardPanel.ButtonSize.width / 2 + interval * CGFloat(index)
                    make.centerX.equalTo(panel.snp.left).offset(offset)
                })
            })
        }
    }

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if !self.keyboardPanel.observeKeyboard {
            self.keyboardPanel.resetContentHeight()
        }
        self.keyboardPanel.observeKeyboard = true
        return true
    }

    override open func willExitJob(currentJob: KeyboardJob, newJob: KeyboardJob, triggerByGoBack: Bool) {
        super.willExitJob(currentJob: currentJob, newJob: newJob, triggerByGoBack: triggerByGoBack)
        threadKeyboardDelegate?.keyboardWillExitJob(currentJob: currentJob, newJob: newJob, triggerByGoBack: triggerByGoBack)
    }

    override open func updateUIForKeyboardJob(oldJob: KeyboardJob?, currentJob: KeyboardJob) {
        super.updateUIForKeyboardJob(oldJob: oldJob, currentJob: currentJob)
        keyboardPanel.layout = createLayout()
        keyboardPanel.panelTopBar.layoutIfNeeded()
        /// panel 布局完成之后 再重新刷新Item
        threadKeyboardDelegate?.onKeyboardJobChanged(oldJob: oldJob, currentJob: currentJob)
        updateInputContainerInnerBottomView()
    }

    override open func didClickCloseTranslationItem() {
        guard let chatAPI else { return }
        IMTracker.Chat.Main.Click.closeTranslation(self.chat, ChatFromWhere.thread.rawValue, location: .chat_view)
        chatAPI.updateChat(chatId: self.chat.id, isRealTimeTranslate: false, realTimeTranslateLanguage: self.chat.typingTranslateSetting.targetLanguage)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                self?.translationInfoPreviewView.setDisplayable(false)
            }, onError: { [weak self] (error) in
                // 把服务器返回的错误显示出来
                let showMessage = BundleI18n.LarkThread.Lark_Setting_PrivacySetupFailed
                if let view = self {
                    UDToast.showFailure(with: showMessage, on: view, error: error)
                }
            }).disposed(by: self.disposeBag)
    }
}

extension ThreadKeyboardView: OpenKeyboardService {

    func displayVC() -> UIViewController {
       return self.threadKeyboardDelegate?.displayVC() ?? UIViewController()
    }

    func reloadPaneItems() {
        self.threadKeyboardDelegate?.reloadPaneItems()
    }

    func keyboardAppearForSelectedPanel(item: KeyboardItemKey) {
        self.threadKeyboardDelegate?.keyboardAppearForSelectedPanel(item: item)
    }

    func foldKeyboard() {
        self.fold()
    }

    func reloadPaneItemForKey(_ key: KeyboardItemKey) {
        self.threadKeyboardDelegate?.reloadPaneItemForKey(key)
    }
}
