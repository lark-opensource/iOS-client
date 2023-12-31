//
//  AudioKeyboardHelper+RecordWithText.swift
//  LarkAudio
//
//  Created by 李晨 on 2019/8/23.
//

import Foundation
import RxSwift
import RxCocoa
import EditTextView
import LKCommonsLogging
import LarkModel
import LarkAudioKit
import LarkMessengerInterface
import LarkUIKit
import SnapKit
import LarkFeatureGating
import LarkSetting

extension NewAudioKeyboardHelper: NewRecordWithTextInputViewDelegate {
    func recordWithTextInputViewShowAction(inputView: NewRecordWithTextInputView, sendEnabled: Bool) {
        var audioRecognizeFinish = false
        if let finish = self.audioRecognizeFinshed, finish {
            audioRecognizeFinish = true
        }
        self.recordTextButtonView?.showActionsIfNeeded(
            stackInfo: self.recordButtonViewContainerStack(),
            animation: false,
            alpha: true,
            sendEnabled: sendEnabled,
            showTipView: !audioRecognizeFinish)
    }

    func recordWithTextInputViewTextChanged(inputView: NewRecordWithTextInputView) {
        self.recordTextButtonView?.actionButton?.sendAllButton.isEnabled = !inputView.textView.text.isEmpty
        self.recordTextButtonView?.actionButton?.sendTextButton.isEnabled = !inputView.textView.text.isEmpty
    }

    func recordWithTextInputViewEndEditing(inputView: NewRecordWithTextInputView) {
        guard let keyboardView = self.delegate?.audiokeybordPanelView() else {
            return
        }
        if Display.pad {
            keyboardView.fold()
        }
    }

    func recordButtonViewContainerStack() -> StackViewInfo {
        guard let keyboardView = self.delegate?.audiokeybordPanelView(),
            let inputView = self.recordTextInputView else {
            return StackViewInfo(stackView: nil, location: 0)
        }
        if keyboardView.macInputStyle {
            return StackViewInfo(
                stackView: self.recordTextButtonWrapper,
                location: 0
            )
        }
        return StackViewInfo(
            stackView: inputView.stackView,
            location: inputView.stackView.arrangedSubviews.count
        )
    }
}

extension NewAudioKeyboardHelper: RecordWithTextButtonViewDelegate {
    func recordWithTextButtonViewClickCancel(buttonView: BaseRecordWithTextButtonView) {
        self.checkAudioRecognitionError()
        self.audioContainer?.resetKeyboardView()
        self.cleanAudioRecognizeInputView()
        self.removeLongpressRecognizeMonitor()
        if userResolver.fg.staticFeatureGatingValue(with: "messenger.audiowithtext.recognition.and.upload"), !buttonView.sessionId.isEmpty {
            self.audioAPI?.abortUploadAudio(uploadID: buttonView.sessionId).subscribe().disposed(by: self.disposeBag)
        }
    }

    func recordWithTextButtonViewClickSendAll(buttonView: BaseRecordWithTextButtonView) {
        self.checkAudioRecognitionError()
        self.audioContainer?.resetKeyboardView()
        self.sendAudioWithTextWhenRecordWithText()
        self.cleanAudioRecognizeInputView()
        self.removeLongpressRecognizeMonitor()
    }

    func recordWithTextButtonViewClickSendAudio(buttonView: BaseRecordWithTextButtonView) {
        self.checkAudioRecognitionError()
        self.audioContainer?.resetKeyboardView()
        self.sendAudioWhenRecordWithText()
        self.cleanAudioRecognizeInputView()
        self.removeLongpressRecognizeMonitor()
    }

    func recordWithTextButtonViewClickSendText(buttonView: BaseRecordWithTextButtonView) {
        self.checkAudioRecognitionError()
        self.audioContainer?.resetKeyboardView()
        self.sendTextWhenRecordWithText()
        self.cleanAudioRecognizeInputView()
        self.removeLongpressRecognizeMonitor()
    }
}

extension NewAudioKeyboardHelper: RecordWithTextAudioKeyboardDelegate {
    func recordWithTextAudioKeyboardStartRecognition(uploadID: String) {
        self.audioPlayMediator?.syncStopPlayingAudio()
        self.cleanAudioRecognizeState()
        self.insertAudioRecognizeInputView(uploadID: uploadID)
        self.handleAudioWithTextMask(show: true)
        self.audioRecognizeFinshed = false
    }

    func recordWithTextAudioKeyboardSendAudio(uploadID: String) {
        self.checkAudioRecognitionError()
        self.sendAudioWhenRecordWithText()
    }

    func recordWithTextAudioKeyboardSendText() {
        self.checkAudioRecognitionError()
        self.sendTextWhenRecordWithText()
    }

    func recordWithTextAudioKeyboardSendAudioAndText(uploadID: String) {
        self.checkAudioRecognitionError()
        self.sendAudioWithTextWhenRecordWithText()
    }

    func recordWithTextAudioKeyboardCleanAllText(uploadID: String) {
        self.checkAudioRecognitionError()
        audioTracker?.asrFinishThenCancel(sessionId: uploadID)
        self.cleanAudioRecognizeInputView()
        // 语音+文字场景边识别边上传优化，用户点击取消时调用，取消语音上传
        if userResolver.fg.staticFeatureGatingValue(with: "messenger.audiowithtext.recognition.and.upload"), !uploadID.isEmpty {
            self.audioAPI?.abortUploadAudio(uploadID: uploadID).subscribe().disposed(by: self.disposeBag)
        }
    }

    func recordWithTextAudioKeyboardRecordStart() {
        self.audioPlayMediator?.syncStopPlayingAudio()
        self.handleAudioGestureMask(show: true)
    }

    func recordWithTextAudioKeyboardRecordFinish() {
        self.handleAudioGestureMask(show: false)
        self.cleanAudioRecognizeInputLoading()
    }

    func recordWithTextAudioKeyboardRecordRecognizeFinish(hasFinshed: Bool) {
        // 记录是否有尾包
        self.audioRecognizeFinshed = hasFinshed
    }

    func recordWithTextAudioKeyboardCleanInputView() {
        self.cleanAudioRecognizeInputView()
    }

    func recordWithTextAudioKeyboardSetupInfo(uploadID: String, audioData: Data, duration: TimeInterval) {
        self.recordTextInputView?.duration = duration
        self.recordTextInputView?.audioData = OpusUtil.encode_wav_data(audioData)
    }

    func recordWithTextAudioKeyboardTime(duration: TimeInterval) {
        self.recordTextInputView?.duration = duration
    }

    func recordWithTextAudioKeyboardState(isPrepare: Bool) {
        self.recordTextInputView?.isPrepare = isPrepare
    }

    func audioDecible(decible: Float) {
        recordTextInputView?.updateDecible(decible: decible)
    }

    func checkAudioRecognitionError() {
        if let recordTextInputView = self.recordTextInputView,
           recordTextInputView.textView.text.isEmpty {
            let audioLength = recordTextInputView.duration
            var errorType = AudioReciableTracker.RecognitionError.noFinalCallback
            if let result = recordTextInputView.lastAudioRecognize {
                if result.error != nil {
                    errorType = .sdkError
                } else if result.finish {
                    errorType = .alwaysEmptyResult
                }
            }
            AudioReciableTracker.shared.audioRecognitionError(sessionID: recordTextInputView.uploadID, errorType: errorType, audioLength: audioLength)
        }
    }
}

// 长按 Audio 同时转文字键盘代理
extension NewAudioKeyboardHelper: RecordAudioTextGestureKeyboardDelegate {
    func addLongGestureView(view: UIView) {
        self.insertLongGestureButtonView(view: view, ishHiddenPanel: false)
    }

    func recordAudioTextGestureKeyboardStartRecognition(uploadID: String) {
        self.audioPlayMediator?.syncStopPlayingAudio()
        self.cleanAudioRecognizeState()
        self.insertAudioRecognizeInputView(uploadID: uploadID)
        self.handleAudioWithTextMask(show: true)
        self.audioRecognizeFinshed = false
    }

    func recordAudioTextGestureKeyboardRecordStart() {
        self.audioPlayMediator?.syncStopPlayingAudio()
        self.handleAudioGestureMask(show: true)
    }

    func recordAudioTextGestureKeyboardRecordRecognizeHasResult() {
        recordTextButtonView?.actionButton?.sendAllButton.isEnabled = true
        recordTextButtonView?.actionButton?.sendTextButton.isEnabled = true
    }

    func recordAudioTextGestureKeyboardRecordFinish() {
        self.cleanLongGestureButtonView(isHiddenPanel: false)
        self.handleAudioGestureMask(show: false)
        self.cleanAudioRecognizeInputLoading()
        if userResolver.fg.staticFeatureGatingValue(with: "ai.asr.opt.no_network") {
            // 录音结束，展示loading
            recordTextButtonView?.showSendAllButtonLoading()
        }
    }

    func recordAudioTextGestureKeyboardRecordRecognizeFinish(hasFinshed: Bool) {
        // 结束信号返回，只更改是否展示loading，不更改按钮isEnable样式
        recordTextButtonView?.hideSendAllButtonLoading()
        self.audioRecognizeFinshed = hasFinshed
        if !hasFinshed {
            self.recordTextButtonView?.showActionsIfNeeded(
                stackInfo: self.recordButtonViewContainerStack(),
                animation: false,
                alpha: true,
                sendEnabled: recordTextButtonView?.actionButton?.sendAllButton.isEnabled ?? false,
                showTipView: true)
        }
    }

    func recordAudioTextGestureKeyboardTime(duration: TimeInterval) {
        self.recordTextInputView?.duration = duration
    }

    func recordAudioTextGestureKeyboardCleanInputView() {
        self.cleanAudioRecognizeInputView()
    }

    func recordAudioTextGestureKeyboardSetupInfo(uploadID: String, audioData: Data, duration: TimeInterval) {
        self.recordTextInputView?.duration = duration
        self.recordTextInputView?.audioData = OpusUtil.encode_wav_data(audioData)

        // 全文只有在“语音+文字”长按松手后audioRecordFinish时调用，此时创建发送按钮。
        // 先默认按钮不可点击。如果有结果返回会更改按钮isEnable属性。如果没有结果返回会保持isEnable的结果不更改
        self.recordTextButtonView?.showActionsIfNeeded(stackInfo: self.recordButtonViewContainerStack(),
                                                       animation: true,
                                                       alpha: false,
                                                       sendEnabled: false,
                                                       showTipView: false)
    }

    func recordAudioTextGestureKeyboardState(isPrepare: Bool) {
        self.recordTextInputView?.isPrepare = isPrepare
    }

    func audioGestureDecible(decible: Float) {
        recordTextInputView?.updateDecible(decible: decible)
    }
}
