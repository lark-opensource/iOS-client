//
//  AudioKeyboardHelper+Recognize.swift
//  LarkAudio
//
//  Created by 李晨 on 2019/8/23.
//

import Foundation
import RxSwift
import RxCocoa
import EditTextView
import LKCommonsLogging
import LarkCore
import LarkModel
import LarkMessengerInterface
import LarkAIInfra
import UniverseDesignIcon
import UniverseDesignColor
import LarkLocalizations

extension NewAudioKeyboardHelper: RecognitionAudioKeyboardDelegate {

    func handleCaretView(show: Bool) {
        canShowCaret = show
        self.handleClearTextView(show: show)
    }

    func deleteBackward() {
        cleanAudioRecognizeState()
        guard let keyboard = self.delegate?.audiokeybordPanelView() else { return }
        if let caretRange {
            keyboard.inputTextView.selectedRange = caretRange
        }
        keyboard.deleteBackward()
        self.lastSelectRange = keyboard.inputTextView.selectedRange
        self.caretRange = lastSelectRange
        self.handleCaretView(show: true)
    }

    func recognitionAudioKeyboardStartRecognition(uploadID: String) {
        self.audioPlayMediator?.syncStopPlayingAudio()
        self.cleanAudioRecognizeState()
        self.recognizeAudioID = uploadID
        self.showAudioRecognizeLoading = true
        self.saveRecognizeCacheText()
        self.observeRecognizeAudio(uploadID: uploadID)
        // 键盘收起时语音转文字开始事件
        self.isVoiceBehaviorRelay.accept(true)
    }

    func recognitionAudioKeyboardboardState(isPrepare: Bool) {
        if let recognizeAudioID = self.recognizeAudioID, self.lastAudioRecognize == nil {
            self.updateAudioRecognize(text: "", uploadID: recognizeAudioID, isPrepare: isPrepare, finish: false)
        }
    }

    func recognitionAudioKeyboardSendText(uploadID: String) {
        self.handleAudioMask(show: false, maskInputView: false)
        self.cleanAudioRecognizeState()
        self.sendMessageWhenRecognition()
        self.lastSelectRange = nil
        self.caretRange = nil
        // 键盘弹起时语音转文字面板点击发送事件
        self.isVoiceBehaviorRelay.accept(false)
        if self.hasEditRecognizeResult {
            audioTracker?.asrFinishThenEdit(sessionId: uploadID)
        }
        self.handleClearTextView(show: true)
    }

    func recognitionAudioKeyboardCleanAllText() {
        self.handleAudioMask(show: false, maskInputView: false)
        self.cleanAudioRecognizeState()
        self.cleanMessageWhenRecognition()
        self.lastSelectRange = nil
        self.caretRange = nil
        // 键盘弹起时语音转文字面板点击clean事件
        self.isVoiceBehaviorRelay.accept(false)
        self.handleClearTextView(show: true)
    }

    func recognitionAudioKeyboardRecordStart() {
        self.audioPlayMediator?.syncStopPlayingAudio()
        aiCollectionView.removeFromSuperview()
        self.handleAudioMask(show: true, maskInputView: false)
        self.handleAudioGestureMask(show: true)
        self.maskViewLock = true
        // 键盘弹起时语音转文字开始事件
        self.isVoiceBehaviorRelay.accept(true)
        self.lineAI()
        self.handleClearTextView(show: false)
    }

    func recognitionAudioKeyboardRecordFinish() {
        self.handleAudioGestureMask(show: false)
        self.maskViewLock = false
        self.cleanAudioRecognizeView()
        self.handleClearTextView(show: true)
        self.showAIButton()
    }

    func showAIButton() {
        // aiBtn的文字是否拉到；本次语音识别是否识别到文字了；输入框是否有文字；
        let btnEmpty = !aiCollectionView.dataSource.isEmpty
        let textEmpty = !(self.delegate?.audiokeybordPanelView().inputTextView.attributedText?.string ?? "").isEmpty
        NewAudioKeyboardHelper.logger.info("helper+recognize show button: \(btnEmpty) \(hasAudioRecognize) \(textEmpty)")
        if !aiCollectionView.dataSource.isEmpty, hasAudioRecognize, textEmpty {
            audioMaskView.addSubview(aiCollectionView)
            aiCollectionView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview().offset(12)
                make.height.equalTo(32)
            }
            AudioTracker.inlineAIEntranceView()
        }
    }

    func recognitionAudioKeyboardRecordCancel() {
        self.handleAudioGestureMask(show: false)
        self.maskViewLock = false
        self.cleanAudioRecognizeView()
        self.handleAudioMask(show: false, maskInputView: false)
        self.handleClearTextView(show: false)
        self.isVoiceBehaviorRelay.accept(false)
    }

    // 开始转文字时被调用
    func lineAI() {
        guard userResolver.fg.dynamicFeatureGatingValue(with: "messenger.input.audio.ai") else { return }
        aiCollectionView.dataSource = []
        aiAsrSDK.getPrompts(result: { [weak self] result in
            switch result {
            case .success(let group):
                if let prompts = group.last?.prompts.filter({ ($0.extraMap["is_visible"] != nil) == true }) {
                    self?.aiCollectionView.dataSource = prompts
                }
            case .failure(let error):
                NewAudioKeyboardHelper.logger.error("helper+recognize: ai_error: \(error)")
            }
        })
    }

    func addObserver() {
        aiAsrSDK.isShowing.asObservable().subscribe(onNext: { [weak self] isShowing in
            if !isShowing {
                self?.handleAIBackview(show: false)
            }
        }).disposed(by: audioDisposeBag)
    }

    func aiButtonClick(prompt: AIPrompt) {
        addObserver()
        handleAIBackview(show: true)
        guard let keyboardView = self.delegate?.audiokeybordPanelView() else { return }
        let helper = InlineAIAsrCallbackImpl(chat: chat,
                                             inputText: self.delegate?.audiokeybordPanelView().inputTextView.attributedText?.string ?? "",
                                             callback: { [weak self, weak keyboardView] aiResultStr in
            guard let keyboardView else { return }
            let attributedText = NSMutableAttributedString(string: aiResultStr)
            attributedText.addAttributes(keyboardView.inputTextView.defaultTypingAttributes, range: NSRange(location: 0, length: attributedText.length))
            keyboardView.inputTextView.attributedText = attributedText
            let contentOffset = CGPoint(x: 0, y: keyboardView.inputTextView.contentSize.height - keyboardView.inputTextView.frame.height)
            keyboardView.inputTextView.setContentOffset(contentOffset, animated: false)
            self?.lastSelectRange = keyboardView.inputTextView.selectedRange
            self?.caretRange = self?.lastSelectRange
            // 当ai返回的文字比原文多很多时（比原文行数多），这时光标计算的位置就可能会错误。这里需要layoutIfNeeded一次，让文字进入输入框，保证计算尽量正确
            keyboardView.layoutIfNeeded()
            self?.handleCaretView(show: true)

            // 文字上屏后，收起面板。这里面板收起需要有回调
            self?.aiAsrSDK.hidePanel()
        })
        self.aiAsrSDK.showPanel(prompt: prompt, provider: helper, inlineAIAsrCallback: helper)
        AudioTracker.inlineAIEntranceClick(type: prompt.type)
    }
}

extension NewAudioKeyboardHelper: RecognizeAudioGestureKeyboardDelegate {

    func recognitionAudioGestureKeyboardStartRecognition(uploadID: String) {
        self.isRecognizeFirstResult = true
        self.hasEditRecognizeResult = false
        self.recognitionAudioKeyboardStartRecognition(uploadID: uploadID)
    }

    func recognitionAudioGestureKeyboardRecordStart() {
        self.audioPlayMediator?.syncStopPlayingAudio()
        self.handleAudioGestureMask(show: true)
        self.maskViewLock = true
        self.clearTextViewTintColor()
    }

    func recognitionAudioAddLongGestureButtonView(view: UIView) {
        self.insertLongGestureButtonView(view: view)
    }

    func recognitionAudioGestureKeyboardRecordFinish() {
        self.handleAudioGestureMask(show: false)
        self.maskViewLock = false
        self.handleAudioMask(show: false, maskInputView: false)
        self.cleanLongGestureButtonView()
        self.cleanAudioRecognizeView()
        self.cleanAudioRecognizeSpaceView()
        self.focusKeyboardInputView()
        self.recoverTextViewTintColor()
    }

    func recognitionAudioGestureKeyboardRecordCancel() {
        self.handleAudioGestureMask(show: false)
        self.maskViewLock = false
        self.handleAudioMask(show: false, maskInputView: false)
        self.cleanLongGestureButtonView()
        self.cleanAudioRecognizeView()
        self.cleanAudioRecognizeSpaceView()
        self.recoverTextViewTintColor()
    }

    func recognitionAudioGestureAudioKeyboardState(isPrepare: Bool) {
        self.recognitionAudioKeyboardboardState(isPrepare: isPrepare)
    }
}

class InlineAISDKDelete: LarkInlineAISDKDelegate {
    var supportedInterfaceOrientationsSetByOutsite: UIInterfaceOrientationMask? { nil }
    func onHistoryChange(text: String) {}
    func onHeightChange(height: CGFloat) {}
    func getUserPrompt() -> AIPrompt { AIPrompt(id: nil, icon: "", text: "", callback: .empty) }
    func getShowAIPanelViewController() -> UIViewController { UIViewController()}
    func getBizReportCommonParams() -> [AnyHashable: Any] { ["from_entrance": "voice_input_toolbar"] }
}
class InlineAIAsrCallbackImpl: InlineAIAsrProvider, InlineAIAsrCallback {
    let chat: Chat
    let inputText: String
    let callback: (String) -> Void
    static let logger = Logger.log(InlineAIAsrCallbackImpl.self, category: "Module.AI.Button")

    init(chat: Chat, inputText: String, callback: @escaping (String) -> Void) {
        self.chat = chat
        self.inputText = inputText
        self.callback = callback
    }
    // input_text 这个key是在Prompt管理平台上配置的
    func getParam() -> [String: String] {
        let chatIDStr = chat.id
        let chatNameStr = chat.name
        var param = ["voice_input_text": inputText,
                     "input_text": inputText,
                     "im_chat_chat_id": chatIDStr,
                     "im_chat_chat_name": chatNameStr,
                     "im_chat_history_message_client": "{\"chat_id\":\"\(chatIDStr)\",\"direction\":\"up\",\"start_position\":\(chat.lastMessagePosition)}"
        ]
        if let lange = LanguageManager.currentLanguage.languageCode {
            param["display_lang"] = lange
        }
        InlineAIAsrCallbackImpl.logger.info("get param: \(param)")
        return param
    }
    func onSuccess(text: String) {
        callback(text)
    }
    func onError(_ error: Error) {
        InlineAIAsrCallbackImpl.logger.error("onError: \(error)")
    }
}
