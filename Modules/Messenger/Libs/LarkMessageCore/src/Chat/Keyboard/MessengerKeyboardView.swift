//
//  MessengerKeyboardView.swift
//  LarkMessageCore
//
//  Created by bytedance on 7/1/22.
//

import Foundation
import UIKit
import RustPB
import LarkModel
import LarkKeyboardView
import LarkEmotionKeyboard
import LarkMessageBase
import LarkSetting
import LarkSDKInterface
import LarkContainer
import LarkMessengerInterface
import LarkRichTextCore
import UniverseDesignToast
import LarkBaseKeyboard
import LarkOpenKeyboard
import LarkChatOpenKeyboard

open class MessengerKeyboardView: IMKeyBoardView,
                                    KeyboardStatusDelegate,
                                    KeyboardAtRouteProtocol {
    lazy var tenantUniversalSettingService: TenantUniversalSettingService? = {
        return try? self.viewModel.resolver.resolve(assert: TenantUniversalSettingService.self)
    }()

    lazy var atUserAnalysisService: IMAtUserAnalysisService? = {
        if self.viewModel.chatModel.isCrypto { return nil }
        return try? self.viewModel.resolver.resolve(assert: IMAtUserAnalysisService.self)
    }()

    lazy var anchorAnalysisService: IMAnchorAnalysisService? = {
        if self.viewModel.chatModel.isCrypto { return nil }
        return try? self.viewModel.resolver.resolve(assert: IMAnchorAnalysisService.self)
    }()

    lazy var scheduleSendService: ScheduleSendService? = {
        return try? self.viewModel.resolver.resolve(assert: ScheduleSendService.self)
    }()
    lazy var userGeneralSettings: UserGeneralSettings? = {
        return try? self.viewModel.resolver.resolve(assert: UserGeneralSettings.self)
    }()
    private lazy var scheduleSendEnable = scheduleSendService?.scheduleSendEnable ?? false

    public override var placeholderTextAttributes: [NSAttributedString.Key: Any] {
        var attributes = super.placeholderTextAttributes
        attributes[.foregroundColor] = UIColor.ud.textTitle
        return attributes
    }

    public lazy var keyboardShareDataService: KeyboardShareDataService = {
        return KeyboardShareDataManager()
    }()

    public var messengerKeyboardPanel: MessengerKeyboardPanel? {
        return self.keyboardPanel as? MessengerKeyboardPanel
    }

    public var keyboardStatusManager: KeyboardStatusManager {
        return keyboardShareDataService.keyboardStatusManager
    }

    public var multiEditCountdownService: MultiEditCountdownService {
        return keyboardShareDataService.countdownService
    }

    public var richText: RustPB.Basic_V1_RichText? {
        get {
            if let richText = RichTextTransformKit.transformStringToRichText(string: self.attributedString),
               !richText.elements.isEmpty {
                return richText
            }
            return nil
        }
        set {
            if let richText = newValue {
                let attributedString = RichTextTransformKit.transformRichTextToStr(
                    richText: richText,
                    attributes: self.inputTextView.defaultTypingAttributes,
                    attachmentResult: [:])
                self.attributedString = attributedString
            } else {
                self.attributedString = NSAttributedString()
            }
        }
    }

    public var richTextStr: String {
        if let richText = self.richText {
            return (try? richText.jsonString()) ?? ""
        }
        return ""
    }

    public let pasteboardToken: String

    public init(frame: CGRect,
                viewModel: IMKeyboardViewModel,
                         pasteboardToken: String,
                         keyboardNewStyleEnable: Bool = false) {
        self.pasteboardToken = pasteboardToken
        super.init(frame: frame,
                   viewModel: viewModel,
                   keyboardNewStyleEnable: keyboardNewStyleEnable)
        inputTextView.placeholderAlpha = 0.5
        let interactionHandler = CustomTextViewInteractionHandler(pasteboardToken: pasteboardToken)
        interactionHandler.useCustomPasteFragment = true
        inputTextView.interactionHandler = interactionHandler
        keyboardStatusManager.delegate = self
        setSupportAtForTextView(self.inputTextView)
        interactionHandler.filterAttrbutedStringBeforePaste = { [weak self] attr, expandInfo in
            let chatId = expandInfo["chatId"] ?? ""
            guard let self = self else { return attr }
            let newAttr = self.atUserAnalysisService?.updateAttrAtUserInfoBeforePasteIfNeed(attr, textView: self.inputTextView, isSameChat: chatId == self.viewModel.chatModel.id) ?? attr
            if !AttributedStringAttachmentAnalyzer.canPasteAttrForTextView(self.inputTextView,
                                                                           attr: newAttr) {
                self.showVideoLimitError()
                return AttributedStringAttachmentAnalyzer.deleVideoAttachmentForAttr(newAttr)
            }
            return newAttr
        }

        interactionHandler.getExpandInfoSaveToPasteBoard = { [weak self] in
            guard let chatId = self?.viewModel.chatModel.id else { return [:] }
            return ["chatId": chatId]
        }

        interactionHandler.didApplyPasteboardInfo = { [weak self] success, attr, expandInfo in
            guard success, let self = self else { return }
            let chatId = expandInfo["chatId"] ?? ""
            self.didApplyPasteboardInfo()
            self.atUserAnalysisService?.updateAttrAtInfoAfterPaste(attr,
                                                                   chat: self.viewModel.chatModel,
                                                                   textView: self.inputTextView,
                                                                   isSameChat: chatId == self.viewModel.chatModel.id,
                                                                   finish: nil)
        }
    }

    public func autoAddAnchorForLinkText() {
        self.anchorAnalysisService?.addObserverFor(textView: inputTextView)
    }

    open func didApplyPasteboardInfo() {
    }

    public func showVideoLimitError() {
        if let window = self.window {
            UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_Chat_TopicCreateSelectVideoError, on: window)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        multiEditCountdownService.stopMultiEditTimer()
    }

    public func resetKeyboardStatusDelagate() {
        keyboardStatusManager.delegate = self
    }

    public func switchJob(_ value: KeyboardJob) {
        keyboardStatusManager.switchJob(value)
    }

    open override func textViewDidChange(_ textView: UITextView) {
        self.textViewInputProtocolSet.textViewDidChange(textView)
        if keyboardNewStyleEnable || scheduleSendEnable {
            reloadSendButton()
        }
    }

    public func switchJobWithoutReplaceLastStatus(_ value: KeyboardJob) {
        keyboardStatusManager.switchJobWithoutReplaceLastStatus(value)
    }

    open func willExitJob(currentJob: KeyboardJob, newJob: KeyboardJob, triggerByGoBack: Bool) {
        if case .multiEdit = currentJob {
            multiEditCountdownService.stopMultiEditTimer()
        }
    }

    open func keyboardJobAssociatedValueChanged(currentJob: KeyboardJob) {}

    open func updateUIForKeyboardJob(oldJob: KeyboardJob?, currentJob: KeyboardJob) {
        switch currentJob {
        case .multiEdit(let message):
            let multiEditEffectiveTime = TimeInterval(tenantUniversalSettingService?.getEditEffectiveTime() ?? 0)
            let timeRemaining = Date(timeIntervalSince1970: .init(message.createTime + multiEditEffectiveTime)).timeIntervalSince(Date())
            let enable = timeRemaining > 0
            layoutRightContiner(type: .submitView(enable: enable))
            if enable {
                multiEditCountdownService.startMultiEditTimer(messageCreateTime: message.createTime,
                                                              effectiveTime: multiEditEffectiveTime,
                                                              onNeedToShowTip: { [weak self] in
                    self?.keyboardStatusManager.addTip(.multiEditCountdown(.init(message.createTime + multiEditEffectiveTime)))
                },
                                                              onNeedToBeDisable: { [weak self] in
                    self?.messengerKeyboardPanel?.reLayoutRightContainer(.submitView(enable: false))
                })
            } else {
                keyboardStatusManager.addTip(.multiEditCountdown(.init(message.createTime + Double(multiEditEffectiveTime))))
            }
        case .quickAction:
            layoutRightContiner(type: .sendQuickAction(enable: true))
        case .scheduleSend:
            self.messengerKeyboardPanel?.reLayoutRightContainer(.scheduleSend(enable:
                                                                                self.sendPostEnable()))
            // 没有提示的时候去创建
            if !self.keyboardStatusManager.containsTipType(.scheduleSend(Date(), false, false, ScheduleSendModel())) {
                // 重新选择时间
                let initDate = ScheduleSendManager.getFutureHour(Date())
                let is12HourTime = !(self.userGeneralSettings?.is24HourTime.value ?? false)
                keyboardStatusManager.addTip(.scheduleSend(initDate, true, is12HourTime, ScheduleSendModel()))
            }
        case .scheduleMsgEdit(let info, let time, let type):
            self.messengerKeyboardPanel?.reLayoutRightContainer(
                .scheduleMsgEdit(enable: true,
                                 itemId: info?.message.id ?? "",
                                 cid: info?.message.cid ?? "",
                                 itemType: type))
            if let message = info?.message, !self.keyboardStatusManager.containsTipType(.scheduleSend(Date(), false, false, ScheduleSendModel())) {
                let model = ScheduleSendModel(parentMessage: message.parentMessage,
                                              messageId: message.id,
                                              cid: message.cid,
                                              itemType: type,
                                              threadId: info?.message.threadId)
                let is12HourTime = !(self.userGeneralSettings?.is24HourTime.value ?? false)
                keyboardStatusManager.addTip(.scheduleSend(time, false, is12HourTime, model))
            }
        default:
            layoutRightContiner(type: keyboardNewStyleEnable ? .sendButton(enable: self.getSendButtonEnable()) : .none)
        }
    }

    open func updateUIForKeyboardTip(_ value: KeyboardTipsType) {
        for child in inputFooterView.subviews {
            child.removeFromSuperview()
        }
        if let view = value.createView(delegate: messengerKeyboardPanel?.rightContainerViewDelegate, scene: .normal) {
            inputFooterView.addSubview(view)
            view.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.left.equalToSuperview()
                make.right.equalToSuperview()
            }
            inputFooterView.snp.updateConstraints { make in
                make.height.equalTo(view.suggestHeight(maxWidth: bounds.width))
            }
            inputFooterView.layoutIfNeeded()
        } else {
            inputFooterView.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
        }
    }

    open func getKeyboardAttributedText() -> NSAttributedString {
        return self.attributedString
    }

    open func updateKeyboardAttributedText(_ value: NSAttributedString) {
        self.attributedString = value
    }

    open func getKeyboardTitle() -> NSAttributedString? {
        return nil
    }

    open func updateKeyboardTitle(_ value: NSAttributedString?) {
    }

    open func layoutRightContiner(type: MessengerKeyboardPanel.Scene) {
        messengerKeyboardPanel?.reLayoutRightContainer(type)
    }

    open func goBackToLastStatus() {
        keyboardStatusManager.goBackToLastStatus()
    }

    open func switchToDefaultJob() {
        keyboardStatusManager.switchToDefaultJob()
    }

    open func updateTipIfNeed(_ value: KeyboardTipsType) {
        self.keyboardStatusManager.addTip(value)
    }

    open override func initKeyboardPanel() {
        keyboardPanel = MessengerKeyboardPanel()
    }

    open override func reloadSendButton() {
        messengerKeyboardPanel?.updateSendButtonEnableIfNeed(self.getSendButtonEnable())
    }

    private func getSendButtonEnable() -> Bool {
        return sendPostEnable() && subViewsEnable && !self.disableItems.contains(KeyboardItemKey.send.rawValue)
    }

    // MARK: - 边写边译
    open var translationInfoPreviewView: TranslationInfoPreviewView? {
        //支持边写边译的keyboard需要在子类重写
        return nil
    }

    open var keyboardRealTimeTranslateDelegate: KeyboardRealTimeTranslateDelegate? {
        //支持边写边译的keyboard需要在子类重写
        return nil
    }

    open func beginTranslateTitle() {
    }

    open func beginTranslateConent() {
        self.translationInfoPreviewView?.isContentLoading = true
    }

    open func onUpdateTitleTranslation(_ text: String) {
    }

    open func onUpdateContentTranslationPreview(_ previewtext: String, completeData: RustPB.Basic_V1_RichText?) {
        self.translationInfoPreviewView?.editType = .content(previewtext)
        self.translationInfoPreviewView?.isContentLoading = false
    }

    open func onRecallEnableChanged(_ enable: Bool) {
        self.translationInfoPreviewView?.recallEnable = enable
    }

    open func didClickLanguageItem(currentLanguage: String) {
        self.keyboardRealTimeTranslateDelegate?.presentLanguagePicker(currentLanguage: currentLanguage)
    }

    open func didClickApplyTranslationItem() {
        guard let data = keyboardRealTimeTranslateDelegate?.getTranslationResult() else { return }
        if let content = data.1 {
            if let attrString = keyboardRealTimeTranslateDelegate?.transformRichTextToStr(richText: content) {
                inputTextView.replace(attrString, useDefaultAttributes: false)
            }
        }
        keyboardRealTimeTranslateDelegate?.applyTranslationCallBack(title: data.0, content: data.1)
        keyboardRealTimeTranslateDelegate?.clearTranslationData()
    }

    open func didClickCloseTranslationItem() {
        assertionFailure("need to be overrided")
    }

    open func didClickRecallTranslationItem() {
        guard let data = self.keyboardRealTimeTranslateDelegate?.getOriginContentBeforeTranslate() else { return }
        if let content = data.1 {
            inputTextView.replace(content, useDefaultAttributes: false)
        }
        self.keyboardRealTimeTranslateDelegate?.recallTranslationCallBack()
    }

    open func didClickPreview() {
        self.keyboardRealTimeTranslateDelegate?.previewTranslation(applyButtonCallBack: { [weak self] in
            self?.didClickApplyTranslationItem()
        })
    }
}

public protocol KeyboardRealTimeTranslateDelegate: AnyObject {
    func getTranslationResult() -> (String?, RustPB.Basic_V1_RichText?)
    func getOriginContentBeforeTranslate() -> (String?, NSAttributedString?)
    func clearTranslationData()
    func updateTargetLanguage(_ languageKey: String)
    func applyTranslationCallBack(title: String?, content: RustPB.Basic_V1_RichText?)
    func recallTranslationCallBack()
    func transformRichTextToStr(richText: RustPB.Basic_V1_RichText) -> NSAttributedString
    func presentLanguagePicker(currentLanguage: String)
    func previewTranslation(applyButtonCallBack: @escaping (() -> Void))
}
extension MessengerKeyboardView: RealTimeTranslateDataDelegate, TranslationInfoPreviewViewDelegate {
}

public extension KeyboardJob {
    var needPanelSendBtn: Bool {
        switch self {
        case .multiEdit, .scheduleMsgEdit, .scheduleSend:
            return false
        default:
            return true
        }
    }
}
