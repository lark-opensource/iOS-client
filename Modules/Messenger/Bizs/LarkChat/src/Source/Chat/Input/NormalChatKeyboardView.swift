//
//  NormalChatKeyboardView.swift
//  LarkChat
//
//  Created by liluobin on 2021/8/31.
//
import Foundation
import UIKit
import RxCocoa
import RxSwift
import LarkModel
import LarkUIKit
import LarkCore
import LarkKeyboardView
import LarkMessengerInterface
import TangramService
import LarkContainer
import Swinject
import RustPB
import LarkGuide
import LarkGuideUI
import LarkCanvas
import EditTextView
import LarkFeatureGating
import LarkRichTextCore
import LarkMessageBase
import UniverseDesignIcon
import LarkBaseKeyboard
import LarkSetting
import LarkOpenKeyboard
import LarkChatOpenKeyboard

final class NormalChatKeyboardView: ChatKeyboardView {
    /// 文字长度
    var needShowTextDraft: Bool = false

    var fontStyleInputService: FontStyleInputService?
    @ScopedInjectedLazy var newGuideManager: NewGuideService?
    override var inputHeaderMaxHeight: CGFloat { 48 }

    private var fontPanelSubModule: IMChatKeyboardFontPanelSubModule? {
        let module = self.viewModel.module.getPanelSubModuleInstanceForModuleClass(IMChatKeyboardFontPanelSubModule.self) as? IMChatKeyboardFontPanelSubModule
        return module
    }

    /// 群空间菜单按钮
    private lazy var entryButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.getIconByKey(.menuHideOutlined, size: CGSize(width: 24, height: 24)).ud.withTintColor(UIColor.ud.iconN2), for: .normal)
        button.imageView?.contentMode = .center
        button.backgroundColor = UIColor.ud.bgBody
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(clickChatMenuButton), for: .touchUpInside)
        return button
    }()

    /// 该属性主要用于排查异常问题，打印日志使用
    private var isFirstBeginEditing = false

    private var entryButtonShowTrack: Bool = false
    private static let entryButtonSize: CGFloat = 46
    private static let entryButtonRightMargin: CGFloat = 8

    override init(chatWrapper: ChatPushWrapper,
                  viewModel: IMKeyboardViewModel,
                  suppportAtAI: Bool,
                  currentChatterId: String,
                  pasteboardToken: String,
                  keyboardNewStyleEnable: Bool,
                  supportRealTimeTranslate: Bool,
                  disableReplyBar: Bool = false) {
        super.init(chatWrapper: chatWrapper,
                   viewModel: viewModel,
                   suppportAtAI: suppportAtAI,
                   currentChatterId: currentChatterId,
                   pasteboardToken: pasteboardToken,
                   keyboardNewStyleEnable: keyboardNewStyleEnable,
                   supportRealTimeTranslate: supportRealTimeTranslate,
                   disableReplyBar: disableReplyBar)
        setupTitleView()
        inputManager.addParagraphStyle()
        fontStyleInputService = try? resolver.resolve(assert: FontStyleInputService.self, argument: true)
        fontStyleInputService?.observeTextView(inputTextView) { [weak self] in
            self?.fontPanelSubModule?.onChangeSelectionFromPaste()
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return self.textView(textView, shouldInteractWith: URL, in: characterRange, interaction: interaction) { [weak self] chatterId in
            self?.chatKeyboardDelegate?.pushProfile(chatterId: chatterId)
        }
    }

    func setupTitleView() {
        let titleView = TitleEditView(placeholder: BundleI18n.LarkChat.Lark_Legacy_PostNoTitleHint) { [weak self] in
            self?.observeKeyboard()
        } endEditing: { [weak self] in
            self?.keyboardPanel.observeKeyboard = false
        }
        let textContainerInset = UIEdgeInsets(top: 0, left: titleView.textView.textContainerInset.left, bottom: 0, right: titleView.textView.textContainerInset.right)
        titleView.textView.textContainerInset = textContainerInset
        titleView.textViewDidBeginEditingCallBack = { [weak self] in
            self?.fontPanelSubModule?.hideFontActionBar()
            self?.items.forEach { self?.keyboardPanel.reloadPanelBtn(key: $0.key) }
        }
        self.titleEditView = titleView
        self.inputHeaderView.addSubview(titleView)
        titleView.returnInputHandler = { [weak self] in
            self?.inputTextView.becomeFirstResponder()
        }
        titleView.textView.rx.value.asDriver().drive(onNext: { [weak self] value in
            guard let self = self else { return }
            if value?.count ?? 0 > 0 {
                if self.titleEditView?.isHidden ?? false {
                    self.titleEditView?.isHidden = false
                    self.titleEditView?.snp.remakeConstraints({ make in
                        make.left.right.top.equalToSuperview()
                        make.height.greaterThanOrEqualTo(22)
                        make.height.lessThanOrEqualTo(40)
                        make.bottom.equalToSuperview().offset(-8)
                    })
                }
            } else {
                if self.titleEditView?.textView.isFirstResponder ?? false {
                    self.inputTextView.becomeFirstResponder()
                }
                self.titleEditView?.snp.remakeConstraints({ make in
                    make.edges.equalToSuperview()
                    make.height.equalTo(0)
                })
                /// 这里要设置isHidden，否则iPad上点击键盘的tab键 光标可以聚焦到这个TextView(设置isUserInteractionEnabled = false 无效)
                self.titleEditView?.isHidden = true
            }
        }).disposed(by: self.disposeBag)
    }

    override func updateReplyInputText(newReply: Message?,
                                       oldReply: Message?,
                                       hasDraftCallback: @escaping (Bool, PartialReplyInfo?) -> Void = { _, _ in }) {
        /// 如果需要展示的草稿是Text类型，需要使用基类的解析方法，NormalChatKeyboardView 不支持Text类型的草稿
        if self.needShowTextDraft {
            self.needShowTextDraft = false
            super.updateReplyInputText(newReply: newReply, oldReply: oldReply)
            return
        }
        if oldReply?.id == newReply?.id {
            return
        }

        let getDraftCompletion: (String, PartialReplyInfo?) -> Void = { [weak self] (replyDraft, partialReplyInfo) in
            guard let self = self else { return }
            /// 应用草稿
            if !replyDraft.isEmpty {
                self.chatKeyboardDelegate?.applyInputPostDraft(replyDraft)
            } else {
                self.attributedString = NSAttributedString(string: "")
            }
            hasDraftCallback(replyDraft.isEmpty == false, partialReplyInfo)
        }
        if let newReply = newReply {
            if newReply.postDraftId.isEmpty {
                getDraftCompletion("", nil)
                return
            }
            self.chatKeyboardDelegate?
                .inputTextViewGetDraft(key: newReply.postDraftId)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { replyDraft in
                    getDraftCompletion(replyDraft.content, replyDraft.partialReplyInfo)
                }).disposed(by: self.disposeBag)
        } else {
            if self.chat.postDraftId.isEmpty {
                getDraftCompletion("", nil)
                return
            }
            self.chatKeyboardDelegate?
                .inputTextViewGetDraft(key: self.chat.postDraftId)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { chatDraft in
                    getDraftCompletion(chatDraft.content, chatDraft.partialReplyInfo)
                }).disposed(by: self.disposeBag)
        }
    }

    override func updateTextViewData(_ item: ComposePostItem,
                                     translateInfo: (title: String?, content: RustPB.Basic_V1_RichText?),
                                     recallEnable: Bool,
                                     keyboardCanBecomeFirstResponder: Bool) {
        self.translationInfoPreviewView.editType = .title(translateInfo.title ?? "")
        let contentStr = RichTextTransformKit.transformRichTexToText(translateInfo.content)
        self.translationInfoPreviewView.editType = .content(contentStr ?? "")
        self.translationInfoPreviewView.recallEnable = recallEnable
        if let responderInfo = item.firstResponderInfo {
            if !responderInfo.1, titleEditView?.textView.attributedText.length ?? 0 > 0 {
                if keyboardCanBecomeFirstResponder {
                    titleEditView?.textView.becomeFirstResponder()
                }
                titleEditView?.textView.selectedRange = NSRange(location: responderInfo.0.location, length: 0)
            } else {
                if keyboardCanBecomeFirstResponder {
                    inputTextView.becomeFirstResponder()
                }
                inputTextView.selectedRange = NSRange(location: responderInfo.0.location, length: 0)
            }
        } else {
            if keyboardCanBecomeFirstResponder {
                inputTextView.becomeFirstResponder()
            }
        }
        fontPanelSubModule?.updateWithUIWithFontBarStatusItem(item.fontBarStatus)
    }

    func getCurrentDisplaySendBtn() -> KeyboardIconButton? {
        return messengerKeyboardPanel?.getSendButton() as? KeyboardIconButton
    }

    /// 当标题输入框 为第一个响应着 不支持发送表情 @等
    override func keyboardSelectEnable(index: Int, key: String) -> Bool {
        /// 处理了发送按钮 其他都不可用
        if titleEditView?.textView.isFirstResponder ?? false {
            return false
        }
        return super.keyboardSelectEnable(index: index, key: key)
    }

    override func textViewDidBeginEditing(_ textView: UITextView) {
        if !isFirstBeginEditing {
            isFirstBeginEditing = true
            Self.logger.info("textView first Begin Editing -\(self.inputTextView.proxyCount)")
        }
        items.forEach { keyboardPanel.reloadPanelBtn(key: $0.key) }
        super.textViewDidBeginEditing(textView)
    }

    override func trimCharacterSetForAttributedString() -> CharacterSet {
        return .whitespacesAndNewlines
    }

    override func updateKeyboardAttributedText(_ value: NSAttributedString) {
        self.attributedString = NSAttributedString(string: "")
        self.chatKeyboardDelegate?.updateAttachmentSizeFor(attributedText: value)
        self.attributedString = value
    }

    override func updateUIForKeyboardJob(oldJob: KeyboardJob?, currentJob: KeyboardJob) {
        super.updateUIForKeyboardJob(oldJob: oldJob, currentJob: currentJob)
        fontPanelSubModule?.updateFontBarSpaceStyle(keyboardStatusManager.currentKeyboardJob.isFontBarCompactLayout ? .compact : .normal)
    }

    @objc
    private func clickChatMenuButton() {
        IMTracker.Chat.Main.Click.ChatMenuSwitch(self.chat, switchToInput: false, self.chatKeyboardDelegate?.chatFromWhere)
        self.chatKeyboardDelegate?.clickChatMenuEntry()
    }

    func showChatMenuEntry(_ isShow: Bool, animation: Bool) {
        func show() {
            self.entryButton.alpha = 1
            self.controlContainerLeftContainerView.snp.updateConstraints { make in
                make.width.equalTo(Self.entryButtonSize + Self.entryButtonRightMargin)
            }
            self.controlContainer.layoutIfNeeded()
        }
        func hide() {
            self.entryButton.alpha = 0
            self.controlContainerLeftContainerView.snp.updateConstraints { make in
                make.width.equalTo(0)
            }
            self.controlContainer.layoutIfNeeded()
        }

        if isShow {
            if self.entryButton.superview == nil {
                self.controlContainerLeftContainerView.addSubview(entryButton)
                entryButton.snp.makeConstraints { make in
                    make.bottom.equalToSuperview()
                    make.left.equalToSuperview()
                    make.size.equalTo(Self.entryButtonSize)
                }
                self.entryButton.alpha = 0
                self.controlContainer.layoutIfNeeded()
            }

            if animation {
                UIView.animate(withDuration: 0.25) {
                    show()
                }
            } else {
                show()
            }

            /// 进入会话第一次展示群空间菜单入口时,上报埋点并展示引导(IfNeeded)
            if !entryButtonShowTrack {
                entryButtonShowTrack = true
                IMTracker.Chat.ChatMenu.View(self.chat, isAppMenu: false)
                DispatchQueue.main.async {
                    self.showChatMenuGuideIfNeeded()
                }
            }
            return
        }
        if animation {
            UIView.animate(withDuration: 0.25) {
                hide()
            }
        } else {
            hide()
        }
    }

    override func didApplyPasteboardInfo() {
        self.chatKeyboardDelegate?.didApplyPasteboardInfo()
    }
}

extension NormalChatKeyboardView {
    /// 群空间引导
    private func showChatMenuGuideIfNeeded() {
        let chatMenuGuideKey = "im_chat_input_menu_onboard"
        /// 判断是否需要引导的时机必须在addsubview(entryButton)后!
        guard entryButton.superview != nil else {
            assertionFailure("entryButton.superview is nil!")
            return
        }
        let rect = entryButton.convert(entryButton.bounds, to: nil)
        let guideAnchor = TargetAnchor(targetSourceType: .targetRect(rect),
                                       arrowDirection: .down,
                                       targetRectType: .rectangle)
        let item = BubbleItemConfig(guideAnchor: guideAnchor,
                                    textConfig: TextInfoConfig(detail: BundleI18n.LarkChat.Lark_IM_FunctionMenuInChat_Onboard))
        let maskConfig = MaskConfig(shadowAlpha: 0, windowBackgroundColor: UIColor.clear)
        let singleBubbleConfig = SingleBubbleConfig(bubbleConfig: item, maskConfig: maskConfig)
        newGuideManager?.showBubbleGuideIfNeeded(guideKey: chatMenuGuideKey,
                                                bubbleType: .single(singleBubbleConfig),
                                                dismissHandler: nil)
    }
}
