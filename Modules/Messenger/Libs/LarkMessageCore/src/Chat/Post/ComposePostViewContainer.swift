//
//  ComposePostViewParentController.swift
//  LarkChat
//
//  Created by zoujiayi on 2019/10/9.
//

import Foundation
import UIKit
import Photos
import RxSwift
import RxCocoa
import LarkUIKit
import LarkModel
import LKCommonsLogging
import LarkCore
import LarkRichTextCore
import LarkKeyboardView
import LarkAttachmentUploader
import EditTextView
import LarkContainer
import UniverseDesignToast
import LarkSetting
import Kingfisher
import LarkMessengerInterface
import LarkAlertController
import EENavigator
import LarkInteraction
import LarkKeyCommandKit
import RustPB
import LarkSDKInterface
import UniverseDesignDialog
import LarkMessageBase
import LarkBaseKeyboard
import LarkOpenKeyboard
import LarkChatOpenKeyboard
import RichLabel

/// 富文本编辑&发送界面
final class ComposePostViewContainer: BaseUIViewController, UITextViewDelegate, UIGestureRecognizerDelegate, KeyboardStatusDelegate, UserResolverWrapper {
    let userResolver: LarkContainer.UserResolver
    /// 用户取消编辑，退出全屏编辑
    private var dismissByUserAction = false
    private var firstResponderInfo: (NSRange, Bool)?
    let childController: ComposePostViewController
    private var debouncer: Debouncer = Debouncer()
    let viewModel: ComposePostViewModel
    private var titleInputProtocolSet = TextViewInputProtocolSet()
    static let logger = Logger.log(ComposePostViewContainer.self, category: "ComposePostViewContainer")

    /// Smart Correct Service
    @ScopedInjectedLazy var smartCorrectService: SmartCorrectService?
    @ScopedInjectedLazy var lingoHighlightService: LingoHighlightService?
    @ScopedInjectedLazy var smartComposeService: SmartComposeService?

    /// 右上角关闭按钮
    private(set) var closeButton: UIButton!
    /// 回复某条消息时，显示该消息摘要
    private(set) var relatedMessageLabel: LKLabel = .init()
    /// 标题输入框
    private(set) var titleTextView: LarkEditTextView?

    let disposeBag = DisposeBag()
    private var titleTypingDisposeBag = DisposeBag()
    private let chatFromWhere: ChatFromWhere

    fileprivate lazy var translationPreviewContainer: UIView = {
        let container = UIView()
        let backgroundView = UIView()
        container.addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.bottom.equalToSuperview().offset(12)
        }
        backgroundView.backgroundColor = UIColor.ud.bgBodyOverlay
        let cornerRadiusView = UIView()
        cornerRadiusView.layer.cornerRadius = 9
        cornerRadiusView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        cornerRadiusView.clipsToBounds = true
        cornerRadiusView.backgroundColor = UIColor.ud.bgBody
        container.addSubview(cornerRadiusView)
        cornerRadiusView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(container.snp.bottom)
            make.height.equalTo(12)
        }
        container.clipsToBounds = false
        return container
    }()

    private lazy var translateFG: Bool = {
        return viewModel.fgService?.staticFeatureGatingValue(with: "im.chat.manual_open_translate") ?? false
    }()

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
        let previewView = TranslationInfoPreviewContainerView(targetLanguage: viewModel.chatModel?.typingTranslateSetting.targetLanguage ?? "",
                                                              displayable: translateFG && viewModel.chatModel?.typingTranslateSetting.isOpen == true,
                                                              maxLines: 6) { [weak self] (height) in
            guard let self = self else { return }
            self.translationPreviewHeight = height
        }
        previewView.translationInfoPreviewView.delegate = self
        return previewView
    }()

    var translationInfoPreviewView: TranslationInfoPreviewView {
        return translationContainerView.translationInfoPreviewView
    }

    private var translateSettingIsOpen: Bool {
        let chatModel = viewModel.chatModel
        return translateFG && chatModel?.typingTranslateSetting.isOpen == true && viewModel.supportRealTimeTranslate
    }

    fileprivate lazy var titleLongGesture: UILongPressGestureRecognizer = {
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongGesture(gesture:)))
        gesture.delegate = self
        return gesture
    }()

    var titleIsEditing = false

    var isTitleLastFocued = true // 之前focused是否是title

    init(resolver: UserResolver, viewModel: ComposePostViewModel, chatFromWhere: ChatFromWhere) {
        self.userResolver = resolver
        self.childController = ComposePostViewController(viewModel: viewModel,
                                                         chatFromWhere: chatFromWhere)
        self.viewModel = viewModel
        self.chatFromWhere = chatFromWhere
        super.init(nibName: nil, bundle: nil)
    }

    deinit {
        /// 这里主要用于处理ipad上，在全屏展开输入框的时候，通过feed或者feed上的tab切换将该页面直接销毁
        if !dismissByUserAction {
            self.saveChatPostDraftWhenAbnormalExit()
        }
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.isNavigationBarHidden = true
        self.view.backgroundColor = UIColor.ud.bgBody
        self.setupTranslationPreviewView()
        self.initRelatedMessageTipsView()
        self.initCloseButton()
        // 初始化ui
        if !self.viewModel.hiddeTitleTextView {
            self.initTitleTextView()
        }
        self.initChildVC()

        self.initInputHandler()

        // 初始化当前一些 UI 状态
        self.updateRelatedMessageBar(replyInfo: self.viewModel.keyboardStatusManager.getRelatedDispalyReplyInfo())
        // 添加长按手势 解决 长按菜单 与 容器滑动 冲突
        self.titleTextView?.addGestureRecognizer(self.titleLongGesture)
        self.saveChatPostDraftOnTextChange()
        // title view 打点聚焦
        self.titleTextView?.rx.didBeginEditing.subscribe(onNext: {[weak self]  (_) in
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

            var text = self.titleTextView?.text
            Observable<Int>.interval(.seconds(5), scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] (_) in
                    guard let `self` = self else { return }
                    if let titleTextView = self.titleTextView, text != titleTextView.text {
                        text = titleTextView.text

                        PostTracker.typingInputActive(
                            isFirst: false,
                            chatType: trackChatType,
                            location: .richtext_input)

                    }
                }).disposed(by: self.titleTypingDisposeBag)
        }).disposed(by: self.disposeBag)

        self.titleTextView?.rx.didEndEditing.subscribe(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            self.titleTypingDisposeBag = DisposeBag()
        }).disposed(by: self.disposeBag)

        // 在 app 被结束的时候存储数据
        NotificationCenter.default.rx.notification(UIApplication.willTerminateNotification)
            .subscribe(onNext: { [weak self] _ in
                self?.saveChatPostDraftWhenAbnormalExit()
            }).disposed(by: disposeBag)

        self.titleTextView?.rx.value.asDriver().skip(1)
            .drive(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.contentDidChanged()
        }).disposed(by: self.disposeBag)

        self.childController.contentTextView.rx.value.asDriver().skip(1)
            .drive(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.contentDidChanged()
            }).disposed(by: self.disposeBag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configFirstResponder()
        self.updateConfigForTranslate(open: translateSettingIsOpen)
    }

    private func contentDidChanged() {
        //当用户清空所有内容时，边写边译需要updateSessionID
        guard viewModel.supportRealTimeTranslate else { return }
        if self.titleTextView?.attributedText.string.isEmpty ?? true,
           self.childController.contentTextView.attributedText.string.isEmpty,
           self.viewModel.chatModel?.typingTranslateSetting.isOpen == true {
            self.viewModel.translateService?.updateSessionID()
        }
    }

    func saveChatPostDraftOnTextChange() {
        // 间隔 2s 存储一次
        self.titleTextView?.rx.value.asDriver().skip(1).throttle(.seconds(2)).drive(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            /// 如果有图片插入的话 不频繁保存，在退出时候保存
            if self.titleTextView?.isFirstResponder ?? false,
               self.childController.getAllImageAndVideoIds().isEmpty,
                //二次编辑场景不实时存草稿
               !self.viewModel.keyboardStatusManager.currentKeyboardJob.isMultiEdit,
               !self.viewModel.keyboardStatusManager.currentKeyboardJob.isScheduleSendState {
                self.saveChatPostDraft([])
            }
        }).disposed(by: self.disposeBag)

        self.childController.contentTextView
            .rx.value.asDriver().skip(1).throttle(.seconds(2))
            .drive(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                if self.childController.contentTextView.isFirstResponder, self.childController.getAllImageAndVideoIds().isEmpty,
                   //二次编辑场景不实时存草稿
                   !self.viewModel.keyboardStatusManager.currentKeyboardJob.isMultiEdit,
                   !self.viewModel.keyboardStatusManager.currentKeyboardJob.isScheduleSendState {
                    self.saveChatPostDraft([])
                }
            }).disposed(by: self.disposeBag)
    }

    func configFirstResponder() {
        guard let item = viewModel.postItem else {
            return
        }
        if self.childController.shouldShowKeyboard {
            if Display.pad {
                self.parent?.view.layoutIfNeeded()
            }
            if let info = item.firstResponderInfo {
                if !info.1, titleTextView != nil,
                    viewModel.keyboardStatusManager.getRelatedDispalyMessage() == nil {
                    titleTextView?.becomeFirstResponder()
                    titleTextView?.selectedRange = NSRange(location: info.0.location, length: 0)
                } else {
                    self.childController.contentTextView.becomeFirstResponder()
                    self.childController.contentTextView.selectedRange = NSRange(location: info.0.location, length: 0)
                }
            } else {
                self.childController.contentTextView.becomeFirstResponder()
            }
            // 更新 defaultTypingAttributes
            self.childController.inputManager.updateDefaultTypingAttributesWithStatus(item.fontBarStatus)
            // 初始化上一个fontbar传递过来的items状态
            if item.fontBarStatus.style == .static {
                self.childController.updateWithUIWithFontBarStatusItem(item.fontBarStatus)
            }
            self.childController.shouldShowKeyboard = false
            let chat = self.viewModel.chatModel

            smartCorrectService?.setupCorrectService(chat: chat,
                                                     scene: .richText,
                                                     fromController: self,
                                                     inputTextView: childController.contentTextView)

            smartComposeService?.setupSmartCompose(chat: chat,
                                                   scene: .MESSENGER,
                                                   with: childController.contentTextView,
                                                   fromVC: self)

            lingoHighlightService?.setupLingoHighlight(chat: chat,
                                                       fromController: self,
                                                       inputTextView: childController.contentTextView,
                                                       getMessageId: { [weak self] in
                return (self?.viewModel.keyboardStatusManager.getMultiEditMessage()?.id) ?? ""
            })
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.titleTextView?.resignFirstResponder()
    }

    func initChildVC() {
        self.addChild(childController)
        self.view.addSubview(childController.view)
        childController.view.snp.makeConstraints { (make) in
            if let titleTextView = self.titleTextView {
                make.top.equalTo(titleTextView.snp.bottom)
            } else {
                make.top.equalTo(self.relatedMessageLabel.snp.bottom)
            }
            make.left.right.bottom.equalToSuperview()
        }
        childController.delegate = self
        let translateOriginData = self.viewModel.translateService?.getCurrentTranslateOriginData()
        let contentStr = RichTextTransformKit.transformRichTexToText(translateOriginData?.1)
        self.translationInfoPreviewView.updatePreviewData(title: translateOriginData?.0 ?? "", content: contentStr ?? "")
        let recallEnable = self.viewModel.translateService?.getRecallEnable() ?? false
        self.translationInfoPreviewView.recallEnable = recallEnable
        //keyboardStatusManager.delegate赋值时会同步大小框数据，
        //因此赋值时机应该在操作输入框内容的方法（resizeAttachmentView等）调用之前
        viewModel.keyboardStatusManager.delegate = self
        self.viewModel.attachmentServer.resizeAttachmentView(textView: self.childController.contentTextView, toSize: self.view.frame.size)
    }

    private func initCloseButton() {
        closeButton = UIButton()
        closeButton.setImage(Resources.closePost, for: .normal)
        closeButton.setImage(Resources.closePost, for: .highlighted)
        self.view.addSubview(closeButton)
        if #available(iOS 13.4, *) {
            closeButton.lkPointerStyle = PointerStyle(
                effect: .highlight,
                shape: .roundedSize({ (_, _) -> (CGSize, CGFloat) in
                    return (Cons.buttonHotspotSize, 8)
                }),
                targetProvider: .init { (interaction, _) -> UITargetedPreview? in
                    guard let view = interaction.view, let superview = view.superview?.superview else {
                        return nil
                    }
                    let targetCenter = view.convert(view.bounds.center, to: superview)
                    let target = UIPreviewTarget(container: superview, center: targetCenter)
                    let parameters = UIPreviewParameters()
                    return UITargetedPreview(
                        view: view,
                        parameters: parameters,
                        target: target
                    )
                }
            )
        }
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
    }

    let relatedMessageLabelLeftMargin: CGFloat = 20
    let relatedMessageLabelRightMargin: CGFloat = Cons.buttonRightSpace + Cons.buttonSize.width + 8
    var relatedMessageLabelAttributes: [NSAttributedString.Key: Any] {
        let p = NSMutableParagraphStyle()
        // swiftlint:disable ban_linebreak_byChar
        p.lineBreakMode = .byCharWrapping
        // swiftlint:enable ban_linebreak_byChar
        return [.font: Cons.replyFont,
                .foregroundColor: UIColor.ud.textPlaceholder,
                .paragraphStyle: p]
    }

    fileprivate func initRelatedMessageTipsView() {
        let outOfRangeText = NSMutableAttributedString(string: "\u{2026}", attributes: relatedMessageLabelAttributes)
        relatedMessageLabel = LKLabel(frame: .zero).lu.setProps(
            fontSize: Cons.replyFont.pointSize,
            numberOfLine: 1,
            textColor: UIColor.ud.textPlaceholder
        )
        relatedMessageLabel.autoDetectLinks = false
        relatedMessageLabel.outOfRangeText = outOfRangeText
        relatedMessageLabel.backgroundColor = UIColor.clear

        let preferredMaxLayoutWidth = self.view.frame.width - relatedMessageLabelLeftMargin - relatedMessageLabelRightMargin
        self.relatedMessageLabel.preferredMaxLayoutWidth = preferredMaxLayoutWidth
        view.addSubview(relatedMessageLabel)
        relatedMessageLabel.snp.makeConstraints { make in
            make.top.equalTo(self.translationPreviewContainer.snp.bottom).offset(20.auto())
            make.left.equalToSuperview().offset(relatedMessageLabelLeftMargin)
            make.right.equalToSuperview().offset(-relatedMessageLabelRightMargin)
            make.height.equalTo(0)
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let preferredMaxLayoutWidth = self.view.frame.width - relatedMessageLabelLeftMargin - relatedMessageLabelRightMargin
        self.relatedMessageLabel.preferredMaxLayoutWidth = preferredMaxLayoutWidth
    }

    func setupTranslationPreviewView() {
        self.view.addSubview(self.translationPreviewContainer)
        self.translationPreviewContainer.addSubview(self.translationContainerView)
        self.translationPreviewContainer.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalToSuperview()
        }
        self.translationContainerView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-12)
            make.top.equalToSuperview()
            make.height.equalTo(translationPreviewHeight)
            make.bottom.equalToSuperview().offset(-9)
        }
    }

    func initTitleTextView() {
        let titleTextView = LarkEditTextView()
        titleTextView.textColor = UIColor.ud.textTitle
        titleTextView.backgroundColor = UIColor.ud.bgBody
        titleTextView.attributedPlaceholder = NSAttributedString(
            string: BundleI18n.LarkMessageCore.Lark_Legacy_PostNoTitleHint,
            attributes: [
                .font: Cons.titleTypingFont,
                .foregroundColor: UIColor.ud.textPlaceholder
            ]
        )
        titleTextView.font = Cons.titlePlaceholderFont
        titleTextView.textContainerInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        titleTextView.maxHeight = 120
        titleTextView.setContentHuggingPriority(.required, for: .vertical)
        titleTextView.defaultTypingAttributes = [
            .font: Cons.titleTypingFont,
            .foregroundColor: UIColor.ud.textTitle
        ]
        self.view.addSubview(titleTextView)
        titleTextView.snp.makeConstraints({ make in
            make.top.equalTo(self.relatedMessageLabel.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalTo(relatedMessageLabel.snp.right)
            make.height.lessThanOrEqualTo(titleTextView.maxHeight)
        })
        titleTextView.delegate = self
        self.titleTextView = titleTextView
    }

    private func initInputHandler() {
        let returnInputHandler = ReturnInputHandler { [weak self] _ -> Bool in
            guard let `self` = self else { return true }
            self.childController.contentTextView.becomeFirstResponder()
            return false
        }

        let titleInputProtocolSet = TextViewInputProtocolSet([returnInputHandler])

        self.titleInputProtocolSet = titleInputProtocolSet

        if let titleTextView = self.titleTextView {
            self.titleInputProtocolSet.register(textView: titleTextView)
        }
    }

    func updateRelatedMessageBar(replyInfo: KeyboardJob.ReplyInfo?) {

        if let replyInfo = replyInfo, let user = replyInfo.message.fromChatter {
            self.relatedMessageLabel.snp.updateConstraints { make in
                make.height.equalTo(Cons.replyViewHeight)
            }
            titleTextView?.snp.updateConstraints({ make in
                make.height.lessThanOrEqualTo(0)
            })
            let displayName = user.displayName(chatId: self.viewModel.chatId, chatType: self.viewModel.chatType, scene: .atInChatInput)
            self.relatedMessageLabel.attributedText = self.getReplyAttributeText(displayName: displayName, replyInfo: replyInfo)
            closeButton.snp.remakeConstraints { (make) in
                make.size.equalTo(Cons.buttonSize)
                make.centerY.equalTo(self.relatedMessageLabel)
                make.right.equalTo(-Cons.buttonRightSpace)
            }
        } else {
            relatedMessageLabel.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
            if let titleTextView = self.titleTextView {
                titleTextView.snp.updateConstraints({ make in
                    make.height.lessThanOrEqualTo(titleTextView.maxHeight)
                })
            }
            closeButton.snp.remakeConstraints { (make) in
                make.size.equalTo(Cons.buttonSize)
                make.top.equalTo(relatedMessageLabel.snp.bottom).offset(-6)
                make.right.equalTo(-Cons.buttonRightSpace)
            }
            self.relatedMessageLabel.attributedText = NSMutableAttributedString(string: "")
        }
        self.view?.bringSubviewToFront(self.closeButton)
        self.view.layoutIfNeeded()
    }

    private func getReplyAttributeText(displayName: String, replyInfo: KeyboardJob.ReplyInfo) -> NSAttributedString {
        let attrText: NSMutableAttributedString
        let fg = viewModel.fgService?.dynamicFeatureGatingValue(with: "im.messenger.part_reply") ?? false

        let supportPartReply = viewModel.dataService.supportPartReply && fg
        if let chat = self.viewModel.chatModel,
           (replyInfo.partialReplyInfo != nil || supportPartReply) {
            attrText = MessageReplyGenerator.attributeReplyForInfo(replyInfo,
                                                               font: Cons.replyFont,
                                                               displayName: displayName,
                                                               chat: chat,
                                                               userResolver: self.userResolver,
                                                               abTestService: self.viewModel.abTestService,
                                                               modelService: self.viewModel.modelService,
                                                               messageBurntService: self.viewModel.messageBurntService)
        } else {
            let message = replyInfo.message
            let attributes = relatedMessageLabelAttributes
            if viewModel.abTestService?.hitABTest(chat: viewModel.chatModel) ?? false {
                let header = "\(displayName): "
                attrText = NSMutableAttributedString(string: "\(header)\(self.viewModel.modelService.messageSummerize(message, partialReplyInfo: nil))",
                                                     attributes: attributes)
            } else {
                let header = "\(BundleI18n.LarkMessageCore.Lark_Legacy_ReplySomebody(displayName)): "
                attrText = NSMutableAttributedString(string:
                                                        "\(header)\(self.viewModel.modelService.messageSummerize(message, partialReplyInfo: nil))",
                                                     attributes: attributes)
            }
        }
        if replyInfo.message.isMultiEdited, replyInfo.partialReplyInfo == nil {
            attrText.append(.init(string: BundleI18n.LarkMessageCore.Lark_IM_EditMessage_Edited_Label,
                                  attributes: [.font: UIFont.systemFont(ofSize: 12),
                                               .foregroundColor: UIColor.ud.textPlaceholder]))
        }
        return attrText
    }

    /// 使用中 开启或者关闭翻译
    func updateConfigForTranslate(open: Bool) {
        if open {
            self.bindToTranslateData()
            self.translationInfoPreviewView.setDisplayable(true)
            self.translationPreviewContainer.snp.remakeConstraints { make in
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.top.equalToSuperview()
            }
            self.translationPreviewContainer.clipsToBounds = false
            /// 绑定之后 需要刷新一下翻译的内容
            updateTranslationIfNeed()
        } else {
            self.viewModel.translateService?.unbindToTranslateData()
            self.translationInfoPreviewView.setDisplayable(false)
            self.translationPreviewContainer.snp.remakeConstraints { make in
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.top.equalToSuperview()
                make.height.equalTo(0).priority(.required)
            }
            self.translationPreviewContainer.clipsToBounds = true
        }
    }

    func bindToTranslateData() {
        let data = RealTimeTranslateData(chatID: self.viewModel.chatId,
                                         titleTextView: self.titleTextView,
                                         contentTextView: self.childController.contentTextView,
                                         delegate: self)
        self.viewModel.translateService?.bindToTranslateData(data)
        self.translationInfoPreviewView.disableLoadingTemporary()
    }

    @objc
    private func handleLongGesture(gesture: UIGestureRecognizer) {
        if gesture.state == .began {
            self.swipContainerVC?.panGesture.isEnabled = false
        } else if gesture.state == .ended ||
            gesture.state == .cancelled ||
            gesture.state == .failed {
            self.swipContainerVC?.panGesture.isEnabled = true
        }
    }

    @objc
    func closeButtonTapped() {
        savefirstResponderInfo()
        self.view.endEditing(true)
        self.swipContainerVC?.dismiss(completion: { [weak self] in
            guard let `self` = self else { return }
            self.dismissByCancel()
        })
        IMTracker.Chat.Main.Click.FullScreen(viewModel.chatModel, self.chatFromWhere, open: false,
                                             viewModel.keyboardStatusManager.getRelatedDispalyMessage()?.id)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func doSendPost(scheduleTime: Int64? = nil) {
        let titleAttributedText = self.titleTextView?.attributedText ?? NSAttributedString(string: "")
        var contentAttributedText = self.childController.contentTextView.attributedText ?? NSAttributedString(string: "")
        // sendPost no longer set i18n title any more
        let title: String = preproccessTitleAttributedText(titleAttributedText)
        contentAttributedText = preproccessContentAttributedText(contentAttributedText)
        if let richText = RichTextTransformKit.transformStringToRichText(string: contentAttributedText) {
            let lingoInfo = LingoConvertService.transformStringToQuasiContent(contentAttributedText)
            self.swipContainerVC?.dismiss(completion: { [weak self] in
                self?.onInputFinished()
                self?.viewModel.completeCallback?(RichTextContent(title: title, richText: richText, lingoInfo: lingoInfo), scheduleTime)
            })
        }
    }

    //发送、二次编辑点保存等动作后 会调用这里
    func onInputFinished() {
        self.dismissByUserSendPost()
        self.cleanPostDraft()
        self.viewModel.translateService?.clearOriginAndTranslationData()
    }

    /// 标题发送前预处理
    func preproccessTitleAttributedText(_ titleAttributedText: NSAttributedString) -> String {
        return titleAttributedText.string.lf.trimCharacters(in: .whitespacesAndNewlines)
    }

    /// 内容发送预处理
    func preproccessContentAttributedText(_ contentAttributedText: NSAttributedString) -> NSAttributedString {
        let attr = KeyboardStringTrimTool.trimTailAttributedString(attr: contentAttributedText, set: .whitespacesAndNewlines)
        return RichTextTransformKit.preproccessSendAttributedStr(attr)
    }

    /// 子类override
    func dismissByUserSendPost() {
        dismissByUserAction = true
    }

    // MARK: - UITextViewDelegate
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return self.titleInputProtocolSet.textView(textView, shouldChangeTextIn: range, replacementText: text)
    }

    func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if #available(iOS 13.0, *) { return false }
        return true
    }

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if !self.childController.keyboardPanel.observeKeyboard {
            self.childController.keyboardPanel.resetContentHeight()
        }
        self.childController.keyboardPanel.observeKeyboard = true
        self.titleIsEditing = true
        return true
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        self.childController.keyboardPanel.reloadPanelBtn(key: KeyboardItemKey.at.rawValue)
        self.childController.keyboardPanel.reloadPanelBtn(key: KeyboardItemKey.emotion.rawValue)
        self.childController.keyboardPanel.reloadPanelBtn(key: KeyboardItemKey.picture.rawValue)
        self.childController.keyboardPanel.reloadPanelBtn(key: KeyboardItemKey.canvas.rawValue)
        self.childController.keyboardPanel.reloadPanelBtn(key: KeyboardItemKey.font.rawValue)
        self.childController.keyboardPanel.reloadPanelBtn(key: KeyboardItemKey.burnTime.rawValue)
        self.childController.hideFontActionBar()
    }

    func textViewDidChange(_ textView: UITextView) {
        self.titleInputProtocolSet.textViewDidChange(textView)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        self.isTitleLastFocued = true
        self.titleIsEditing = false

        if !self.titleIsEditing && !self.childController.contentIsEditing {
            self.childController.keyboardPanel.observeKeyboard = false
            if self.childController.keyboardPanel.selectIndex == nil {
                self.childController.keyboardPanel.closeKeyboardPanel(animation: true)
            }
        }
    }
    // MARK: - UIGestureRecognizerDelegate
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    // MARK: - KeyCommands
    override func keyBindings() -> [KeyBindingWraper] {
        super.keyBindings() + jumpKeyBindings
    }
    lazy var jumpKeyBindings: [KeyBindingWraper] = {[
        KeyCommandBaseInfo(input: UIKeyCommand.inputTab, modifierFlags: [])
            .binding(tryHandle: { [weak self] _ in
                self?.titleTextView?.isFirstResponder ?? false
            }, handler: { [weak self] in
                self?.childController.contentTextView.becomeFirstResponder()
            }).wraper
    ]}()

    func dismissByCancel() {
        dismissByUserAction = true
        let fontBarStatus: FontToolBarStatusItem
        // try to replace status by bar
        if let status = childController.getCurrentStatusItem() {
            fontBarStatus = status
        } else {
            // get defaultTypingAttributes from inputManager
            fontBarStatus = childController.inputManager.getInputViewFontStatus()
        }
        let postItem = ComposePostItem(fontBarStatus: fontBarStatus,
                                       firstResponderInfo: firstResponderInfo)
        self.childController.viewModel.cancelCallback?(postItem)
        self.saveChatPostDraft(self.childController.getAllImageAndVideoIds())
    }

    func resignInputViewFirstResponder() {
        savefirstResponderInfo()
        DispatchQueue.main.async {
            self.titleTextView?.resignFirstResponder()
            self.childController.contentTextView.resignFirstResponder()
        }
    }

    // MARK: - KeyboardStatusDelegate
    public func willExitJob(currentJob: KeyboardJob, newJob: KeyboardJob, triggerByGoBack: Bool) {
        if case .multiEdit = currentJob {
            viewModel.multiEditCountdownService.stopMultiEditTimer()
        }
    }

    public func updateUIForKeyboardJob(oldJob: KeyboardJob?, currentJob: KeyboardJob) {
        // TODO: 目前只有 QuickAction 才会隐藏 PostTitle
        var shouldHidePostTitle: Bool = false
        switch currentJob {
        case .multiEdit(let message):
            let multiEditEffectiveTime = TimeInterval(viewModel.tenantUniversalSettingService?.getEditEffectiveTime() ?? 0)
            let timeRemaining = Date(timeIntervalSince1970: .init(message.createTime + multiEditEffectiveTime)).timeIntervalSince(Date())
            let enable = timeRemaining > 0
            childController.keyboardPanel.reLayoutRightContainer(.submitView(enable: enable))
            if enable {
                viewModel.multiEditCountdownService.startMultiEditTimer(messageCreateTime: message.createTime,
                                                              effectiveTime: multiEditEffectiveTime,
                                                              onNeedToShowTip: { [weak self] in
                    self?.viewModel.keyboardStatusManager.addTip(.multiEditCountdown(.init(message.createTime + multiEditEffectiveTime)))
                },
                                                              onNeedToBeDisable: { [weak self] in
                    self?.childController.keyboardPanel.reLayoutRightContainer(.submitView(enable: false))
                })
            } else {
                viewModel.keyboardStatusManager.addTip(.multiEditCountdown(.init(message.createTime + Double(multiEditEffectiveTime))))
            }
        // 定时发送
        case .scheduleSend:
            self.childController.keyboardPanel.reLayoutRightContainer(.scheduleSend(enable: self.childController.sendPostEnable()))
            // 使用上一个页面的选择的时间
            if case .scheduleSend = viewModel.keyboardStatusManager.currentDisplayTip {
                viewModel.keyboardStatusManager.addTip(viewModel.keyboardStatusManager.currentDisplayTip)
            }
        // 定时消息编辑
        case .scheduleMsgEdit(info: let info, time: _, type: let type):
            let message = info?.message
            self.childController.keyboardPanel.reLayoutRightContainer(.scheduleMsgEdit(enable: true, itemId: message?.id ?? "", cid: message?.cid ?? "", itemType: type))
            // 使用上一个页面的选择的时间
            if case .scheduleSend = viewModel.keyboardStatusManager.currentDisplayTip {
                viewModel.keyboardStatusManager.addTip(viewModel.keyboardStatusManager.currentDisplayTip)
            }
        case .quickAction:
            // QuickAction Job，隐藏所有的功能按钮
            shouldHidePostTitle = true
        default:
            childController.keyboardPanel.reLayoutRightContainer(.sendButton(enable: self.childController.sendPostEnable()))
        }
        titleTextView?.isHidden = shouldHidePostTitle
        self.updateRelatedMessageBar(replyInfo: self.viewModel.keyboardStatusManager.getRelatedDispalyReplyInfo(for: currentJob))
        childController.resetPanelItemsFor(keyboardJob: currentJob)
    }

    public func updateUIForKeyboardTip(_ value: KeyboardTipsType) {
        let containerView = childController.centerContainer
        for child in containerView.subviews {
            child.removeFromSuperview()
        }
        if let view = value.createView(delegate: self.childController.keyboardPanel?.rightContainerViewDelegate,
                                       scene: .compose) {
            containerView.addSubview(view)
            view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
                make.height.equalTo(view.suggestHeight(maxWidth: containerView.bounds.width))
            }
        }
    }

    func keyboardJobAssociatedValueChanged(currentJob: KeyboardJob) {
        self.updateRelatedMessageBar(replyInfo: self.viewModel.keyboardStatusManager.getRelatedDispalyReplyInfo(for: currentJob))
    }

    public func getKeyboardAttributedText() -> NSAttributedString {
        return childController.contentTextView.attributedText
    }

    public func getKeyboardTitle() -> NSAttributedString? {
        return titleTextView?.attributedText
    }

    public func updateKeyboardTitle(_ value: NSAttributedString?) {
        if let titleTextView = self.titleTextView,
           let attributedString = value {
            titleTextView.attributedText = attributedString
        }
    }

    public func updateKeyboardAttributedText(_ value: NSAttributedString) {
        childController.contentTextView.attributedText = value
    }
}

// MARK: delegate
extension ComposePostViewContainer: ComposePostViewControllerDelegate {

    func updateAttachmentResultInfo() {
        if !translateSettingIsOpen { return }
        debouncer.debounce(indentify: "update", duration: 0.15) { [weak self] in
            self?.updateTranslationIfNeed()
        }
    }

    func updateSendButton(isEnabled: Bool) { }

    func didInsertImage(_ viewController: ComposePostViewController) {
    }

    func willResignFirstResponders() {
        self.titleTextView?.resignFirstResponder()
    }

    func shouldContainFirstResponer() -> Bool {
        return self.titleTextView?.isFirstResponder ?? false
    }

    func shouldShowKeyboard() -> Bool {
        return self.titleIsEditing
    }

    func sendPost(scheduleTime: Int64? = nil) {
        if !self.childController.sendPostEnable() {
            let alertController = LarkAlertController()
            alertController.setTitle(text: BundleI18n.LarkMessageCore.Lark_Legacy_Hint)
            alertController.setContent(text: BundleI18n.LarkMessageCore.Lark_Legacy_ComposePostTitleContentEmpty)
            alertController.addPrimaryButton(text: BundleI18n.LarkMessageCore.Lark_Legacy_Sure)
            self.viewModel.navigator.present(alertController, from: self)
            return
        }

        self.childController.uploadFailsImageIfNeed { [weak self] success in
            if success {
                self?.doSendPost(scheduleTime: scheduleTime)
            }
        }
    }

    func updateTranslationIfNeed() {
        viewModel.translateService?.refreshTranslateContent()
    }

    func goBackToLastStatus() {
        viewModel.keyboardStatusManager.goBackToLastStatus()
    }

    func getSendMsgModelFrom(attr: NSAttributedString) -> ComposeSendMsgModel? {
        let titleAttributedText = self.titleTextView?.attributedText ?? NSAttributedString(string: "")
        var contentAttributedText = self.childController.contentTextView.attributedText ?? NSAttributedString(string: "")

        let title: String = preproccessTitleAttributedText(titleAttributedText)
        contentAttributedText = preproccessContentAttributedText(contentAttributedText)
        if var richText = RichTextTransformKit.transformStringToRichText(string: contentAttributedText) {
            richText.richTextVersion = 1
            return (richText, title, .post)
        }
        return nil
    }

    func multiEditMessage() {
        let titleAttributedText = self.titleTextView?.attributedText ?? NSAttributedString(string: "")
        var contentAttributedText = self.childController.contentTextView.attributedText ?? NSAttributedString(string: "")
        guard let message = viewModel.keyboardStatusManager.getMultiEditMessage() else { return }

        //触发二次编辑或（内容为空时）撤回后（无论请求是否成功），都会走到这里
        func callback() {
            self.swipContainerVC?.dismiss(completion: { [weak self] in
                self?.onInputFinished()
                self?.viewModel.keyboardStatusManager.goBackToLastStatus()
                self?.childController.viewModel.multiEditFinishCallback?()
            })
        }
        if titleAttributedText.string.isEmpty && contentAttributedText.string.isEmpty {
            //内容为空，视为撤回
            let dialog = UDDialog()
            dialog.setTitle(text: BundleI18n.LarkMessageCore.Lark_IM_EditMessage_ClearAllContenAndRecallMessage_Title)
            dialog.setContent(text: BundleI18n.LarkMessageCore.Lark_IM_EditMessage_ClearAllContenAndRecallMessage_Desc)
            dialog.addSecondaryButton(text: BundleI18n.LarkMessageCore.Lark_IM_EditMessage_ClearAllContenAndRecallMessage_Cancel_Button,
                                      dismissCompletion: { [weak self] in
                IMTracker.Msg.WithdrawConfirmCLick(self?.viewModel.chatModel,
                                                   message,
                                                   clickConfirm: false)
            })
            dialog.addDestructiveButton(text: BundleI18n.LarkMessageCore.Lark_IM_EditMessage_ClearAllContenAndRecallMessage_RecallMessage_Button,
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
                        guard let window = self?.view.window else { return }
                        if let error = error.underlyingError as? APIError {
                            switch error.type {
                            case .messageRecallOverTime(let errorInfo):
                                UDToast.showFailure(with: errorInfo, on: window, error: error)
                                self?.viewModel.multiEditService?.reloadEditEffectiveTimeConfig()
                            default:
                                UDToast.showFailure(
                                    with: BundleI18n.LarkMessageCore.Lark_Legacy_RecallMessageErr,
                                    on: window,
                                    error: error
                                )
                            }
                        }
                    })
                    .disposed(by: self.disposeBag)
                callback()
            })

            self.viewModel.navigator.present(dialog, from: self)
            return
        }

        let title: String = preproccessTitleAttributedText(titleAttributedText)
        contentAttributedText = preproccessContentAttributedText(contentAttributedText)
        if var richText = RichTextTransformKit.transformStringToRichText(string: contentAttributedText),
           let messageId = Int64(message.id) {
            richText.richTextVersion = 1
            let chat = self.viewModel.chatModel
            if !(chat?.isAllowPost ?? false) {
                guard let window = self.view.window else { return }
                UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_IM_EditMessage_FailedToEditDueToSpecificSettings_Toast(chat?.name ?? ""), on: window)
                return
            }
            if message.isRecalled || message.isDeleted {
                let dialog = UDDialog()
                dialog.setTitle(text: BundleI18n.LarkMessageCore.Lark_IM_EditMessage_UnableToSaveChanges_Text)
                let content = message.isRecalled ?
                BundleI18n.LarkMessageCore.Lark_IM_EditMessage_MessageRecalledUnableToSave_Title :
                BundleI18n.LarkMessageCore.Lark_IM_EditMessage_MessageDeletedUnableToSave_Title
                dialog.setContent(text: content)
                dialog.addPrimaryButton(text: BundleI18n.LarkMessageCore.Lark_IM_EditMessage_UnableToSave_GotIt_Button)
                self.viewModel.navigator.present(dialog, from: self)
                return
            }

            let chatId = self.viewModel.chatId
            callback()

            DispatchQueue.global(qos: .userInteractive).async {
                let lingoInfo = LingoConvertService.transformStringToQuasiContent(contentAttributedText)
                //没有改变任何内容点保存，则不执行任何操作
                if let oldMessageContent = self.viewModel.keyboardStatusManager.multiEditingMessageContent {
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

                self.requestMultiEditMessage(messageId: messageId,
                                             chatId: chatId,
                                             richText: richText,
                                             title: title.isEmpty ? nil : title,
                                             lingoInfo: lingoInfo)
            }
        }
    }

    func scheduleSendMessage() {
        self.childController.onMessengerKeyboardPanelSchuduleSendButtonTap()
    }

    // 按下定时消息按钮
    public func onMessengerKeyboardPanelSchuduleSendButtonTap() {
        guard let vm = self.viewModel as? ComposePostViewModel else { return }
        let attributedText = self.childController.contentTextView.attributedText
        IMTracker.Chat.Main.Click.Msg.msgDelayedSendTimeClick(vm.chatModel, self.chatFromWhere)
        if self.viewModel.getScheduleMsgSendTime?() != nil {
            IMTracker.Chat.Main.Click.Msg.msgDelayedSendToastView(vm.chatModel, self.chatFromWhere)
            UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_CanSendOnly1ScheduledMessage_Tooltip, on: self.view)
            // 重置输入框状态和草稿
            self.onInputFinished()
            self.viewModel.keyboardStatusManager.goBackToLastStatus()
            return
        }
        if attributedText?.string.isEmpty == false {
            guard let scheduleTime = self.childController.scheduleTime else {
                assertionFailure("scheduletime is empty")
                Self.logger.info("scheduletime is empty")
                self.viewModel.keyboardStatusManager.goBackToLastStatus()
                return
            }
            self.viewModel.setScheduleTipStatus?(.creating)
            let formatTime = ScheduleSendManager.formatSendScheduleTime(scheduleTime)
            self.sendPost(scheduleTime: formatTime ?? Int64(Date().timeIntervalSince1970))
        } else {
            Self.logger.info("attributedText string isEmpty")
            assertionFailure("bussiness error")
        }
    }

    func patchScheduleMessage(itemId: String,
                              cid: String,
                              itemType: RustPB.Basic_V1_ScheduleMessageItem.ItemType,
                              isSendImmediately: Bool,
                              needSuspend: Bool) {
        guard let vm = self.viewModel as? ComposePostViewModel else { return }
        func callback() {
            // 重置输入框状态和草稿
            self.swipContainerVC?.dismiss(completion: { [weak self] in
                self?.onInputFinished()
                self?.viewModel.keyboardStatusManager.goBackToLastStatus()
                self?.viewModel.patchScheduleMsgFinishCallback?()
            })
        }
        // 如果定时消息已经发送/删除，弹toast后恢复普通输入框
        if let ids = vm.getSendScheduleMsgIds?(), ids.0.contains { $0 == itemId } || ids.1.contains { $0 == itemId } {
            if let window = self.view.window {
                UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_IM_ScheduledMessage_RepeatOperationFailed_Toast, on: window)
            }
            callback()
            return
        }
        // 如果当前选择的消息已经过去了，弹toast阻断
        let scheduleTime = TimeInterval(self.childController.scheduleTime ?? 0) ?? 0
        if isSendImmediately == false, scheduleTime < Date().timeIntervalSince1970 {
            if let window = self.view.window {
                UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_TimePassedSelectAgain_Toast, on: window)
            }
            return
        }
        if vm.chatModel?.isAllowPost == false {
            if let window = self.view.window {
                UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_IM_EditMessage_FailedToEditDueToSpecificSettings_Toast(vm.chatModel?.name), on: window)
            }
            callback()
            return
        }
        let titleAttributedText = self.titleTextView?.attributedText ?? NSAttributedString(string: "")
        var contentAttributedText = self.childController.contentTextView.attributedText ?? NSAttributedString(string: "")
        // 内容不为空
        guard contentAttributedText.string.isEmpty == false, let model = getSendMsgModelFrom(attr: contentAttributedText) else {
            vm.scheduleSendService?.showAlertWhenContentNil(from: self,
                                                            chatID: Int64(vm.chatModel?.id ?? "") ?? 0,
                                                            itemId: itemId,
                                                            itemType: itemType,
                                                            deleteConfirmTask: { [weak self] in
                self?.swipContainerVC?.dismiss(completion: { [weak self] in
                    self?.dismissByUserSendPost()
                    self?.cleanPostDraft()
                    self?.viewModel.keyboardStatusManager.goBackToLastStatus()
                    self?.viewModel.patchScheduleMsgFinishCallback?()
                })
            },
                                                           deleteSuccessTask: { [weak self] in
                if let chat = self?.viewModel.chatModel {
                    IMTracker.Chat.Main.Click.Msg.msgDelayedSendClick(chat, click: "delete", self?.chatFromWhere)
                }
            })
            return
        }

        // 重置输入框状态和草稿
        callback()
        vm.setScheduleTipStatus?(.updating)

        // 调用接口
        let richText = model.0
        let title = model.1
        let messageType = model.2
        var quasiContent = QuasiContent()
        quasiContent.richText = richText
        if let title = title {
            quasiContent.title = title
        }
        quasiContent.lingoOption = LingoConvertService.transformStringToQuasiContent(contentAttributedText)
        var item = ScheduleMessageItem()
        item.itemID = itemId
        item.itemType = itemType
        // 格式化时间
        var sendScheduleTime: Int64?
        if let time = self.childController.scheduleTime {
            sendScheduleTime = ScheduleSendManager.formatSendScheduleTime(time)
        }
        vm.postSendService?.patchScheduleMessage(chatID: Int64(vm.chatId) ?? 0,
                                                 cid: cid,
                                                 item: item,
                                                 messageType: messageType,
                                                 content: quasiContent,
                                                 scheduleTime: sendScheduleTime,
                                                 isSendImmediately: isSendImmediately,
                                                 needSuspend: needSuspend) { [weak self] result in
            switch result {
            case .success(_):
                break
            case .failure(let error):
                DispatchQueue.main.async {
                    if let view = self?.childController.view {
                        UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_Legacy_ErrorMessageTip, on: view, error: error)
                    }
                }
                Self.logger.error("patchScheduleMessage error", error: error)
            }
        }
    }

    func requestMultiEditMessage(messageId: Int64,
                                 chatId: String,
                                 richText: Basic_V1_RichText,
                                 title: String?,
                                 lingoInfo: Basic_V1_LingoOption) {
        self.viewModel.multiEditService?.multiEditMessage(messageId: messageId,
                                                          chatId: chatId,
                                                          type: .post,
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

    func savefirstResponderInfo() {
        if childController.contentTextView.isFirstResponder || titleTextView?.isFirstResponder ?? false {
            let range = childController.contentTextView.selectedRange
            if childController.contentTextView.isFirstResponder, range.length > 0 {
                childController.contentTextView.selectedRange = NSRange(location: range.location, length: 0)
            }
            firstResponderInfo = (childController.contentTextView.isFirstResponder ?
                                    childController.contentTextView.selectedRange : titleTextView?.selectedRange ?? NSRange(location: 0, length: 0),
                                  childController.contentTextView.isFirstResponder)
        } else {
            firstResponderInfo = nil
        }
    }
}

// MARK: Draft 相关
extension ComposePostViewContainer {

    var draft: String {
        let postDraft = self.postDraft
        if postDraft.title.isEmpty && postDraft.content.isEmpty {
            return ""
        }
        return postDraft.stringify()
    }

    var postDraft: PostDraftModel {
        get {
            if self.viewModel.isMyAIChatMode {
                return PostDraftModel()
            }
            if self.childController.contentTextView.text.isEmpty && (self.titleTextView?.text.isEmpty ?? true) {
                return PostDraftModel()
            }
            var postDraft = PostDraftManager.getDraftModelFor(attributeStr: self.childController.contentTextView.attributedText,
                                                                              attachmentUploader: self.viewModel.attachmentUploader)
            if self.viewModel.keyboardStatusManager.getRelatedDispalyMessage() == nil {
                postDraft.title = self.titleTextView?.attributedText.string ?? ""
            }
            return postDraft
        }
        set {
            if self.viewModel.isMyAIChatMode {
                return
            }
            let postDraft = newValue
            if !PostDraftManager.applyPostDraftFor(postDraft,
                                                  attachmentUploader: self.viewModel.attachmentUploader,
                                                  contentTextView: self.childController.contentTextView),
                !postDraft.content.isEmpty {
                // 处理旧版本草稿格式
                let draft = NSAttributedString(string: postDraft.content, attributes: self.childController.contentTextView.defaultTypingAttributes)
                let content = OldVersionTransformer.transformInputText(draft)
                self.childController.contentTextView.replace(content, useDefaultAttributes: false)
            }
            ComposePostViewContainer.logger.info("ComposePostViewContainer setPostDraft",
                                                 additionalData: ["chatId": self.viewModel.chatId,
                                                                  "messageId": self.viewModel.keyboardStatusManager.getRelatedDispalyMessage()?.id ?? "",
                                                                  "DraftLength": "\(self.childController.contentTextView.text.count)"])
            self.childController.setupAttachment()
        }
    }

    func cleanPostDraft() {
        self.viewModel.cleanPostDraft()
    }

    func saveChatPostDraft(_ attachmentKeys: [String]) {
        self.viewModel.saveChatPostDraft(self.draft, attachmentKeys: attachmentKeys, async: true)
    }

    func saveChatPostDraftWhenAbnormalExit() {
        let attachmentKeys = self.childController.getAllImageAndVideoIds()
        self.viewModel.saveChatPostDraft(self.draft, attachmentKeys: attachmentKeys, async: false)
    }
}

extension ComposePostViewContainer: RealTimeTranslateDataDelegate, TranslationInfoPreviewViewDelegate {

    func didClickPreview() {
        guard let chat = self.viewModel.chatModel,
        let data = viewModel.translateService?.getCurrentTranslateOriginData() else { return }
        if data.0?.isEmpty ?? true &&
            data.1 == nil {
            return
        }

        let imageAttachments: [String: (CustomTextAttachment, ImageTransformInfo, NSRange)] =
        ImageTransformer.fetchImageAttachemntMapInfo(attributedText: self.childController.contentTextView.attributedText)
        let videoAttachments: [String: (CustomTextAttachment, VideoTransformInfo, NSRange)] =
        VideoTransformer.fetchVideoAttachemntMapInfo(attributedText: self.childController.contentTextView.attributedText)
        let body = ChatTranslationDetailBody(chat: chat, title: data.0, content: data.1,
                                             attributes: self.childController.contentTextView.baseDefaultTypingAttributes,
                                             imageAttachments: imageAttachments,
                                             videoAttachments: videoAttachments) { [weak self] in
            self?.didClickApplyTranslationItem()
        }
        self.viewModel.navigator.present(body: body,
                                 wrap: LkNavigationController.self,
                                 from: self,
                                 prepare: { $0.modalPresentationStyle = .fullScreen },
                                 animated: true)
    }

    func didClickLanguageItem(currentLanguage: String) {
        var body = LanguagePickerBody(chatId: self.viewModel.chatId, currentTargetLanguage: currentLanguage, chatFromWhere: self.chatFromWhere)
        body.closeRealTimeTranslateCallBack = { [weak self] _ in
            self?.updateConfigForTranslate(open: false)
        }
        body.targetLanguageChangeCallBack = { [weak self] chat in
            self?.translationInfoPreviewView.updateLanguage(chat.typingTranslateSetting.targetLanguage)
            self?.viewModel.translateService?.updateTargetLanguage(chat.typingTranslateSetting.targetLanguage)
        }
        self.viewModel.navigator.present(body: body, from: self)
    }

    func didClickApplyTranslationItem() {
        guard let data = self.viewModel.translateService?.getCurrentTranslateOriginData() else { return }
        if data.0?.isEmpty == false {
            self.titleTextView?.text = data.0
        }
        if let richtext = data.1 {
            let content = RichTextTransformKit.transformRichTextToStr(
                richText: richtext,
                attributes: self.childController.contentTextView.baseDefaultTypingAttributes,
                attachmentResult: self.viewModel.attachmentUploader.results,
                processProvider: [:])
            AtTransformer.getAllChatterInfoForAttributedString(content).forEach { chatterInfo in
                let userInfoDic = AtTransformer.getAllChatterActualNameMapForAttributedString(childController.contentTextView.attributedText)
                chatterInfo.actualName = userInfoDic[chatterInfo.id] ?? ""
            }
            self.childController.contentTextView.replace(content, useDefaultAttributes: false)
        }
        self.viewModel.applyTranslationCallback?(data.0, data.1)
        self.childController.setupAttachment(needToClearTranslationData: true)
        self.viewModel.translateService?.clearTranslationData()
    }

    func didClickCloseTranslationItem() {
        viewModel.closeTranslation(succeed: { [weak self] in
            self?.updateConfigForTranslate(open: false)
        }, fail: { [weak self] error in
            let showMessage = BundleI18n.LarkMessageCore.Lark_Setting_PrivacySetupFailed
            if let view = self?.viewIfLoaded {
                UDToast.showFailure(with: showMessage, on: view, error: error)
            }
        })
    }

    public func didClickRecallTranslationItem() {
        guard let data = self.viewModel.translateService?.getLastOriginData() else { return }
        if data.0?.isEmpty == false {
            self.titleTextView?.text = data.0
        }
        if let content = data.1 {
            self.childController.contentTextView.replace(content, useDefaultAttributes: false)
        }
        updateTranslationIfNeed()
        self.viewModel.recallTranslationCallback?()
    }

    func beginTranslateTitle() {
        self.translationInfoPreviewView.isTitleLoading = true
    }

    func beginTranslateConent() {
        self.translationInfoPreviewView.isContentLoading = true
    }

    func onUpdateTitleTranslation(_ text: String) {
        self.translationInfoPreviewView.editType = .title(text)
        self.translationInfoPreviewView.isTitleLoading = false
    }

    func onUpdateContentTranslationPreview(_ previewtext: String, completeData: RustPB.Basic_V1_RichText?) {
        self.translationInfoPreviewView.editType = .content(previewtext)
        self.translationInfoPreviewView.isContentLoading = false
    }

    func onRecallEnableChanged(_ enable: Bool) {
        self.translationInfoPreviewView.recallEnable = enable
    }
}

fileprivate extension ComposePostViewContainer {
    enum Cons {
        static var titlePlaceholderFont: UIFont { UIFont.ud.title3 }
        static var titleTypingFont: UIFont { UIFont.ud.title3 }
        static var replyFont: UIFont { UIFont.ud.title4 }
        static var replyViewHeight: CGFloat { replyFont.rowHeight + 4 }
        static var buttonSize: CGSize { .square(36) }
        static var buttonHotspotSize: CGSize { .square(44) }
        static var buttonRightSpace: CGFloat { 8 }
    }
}
