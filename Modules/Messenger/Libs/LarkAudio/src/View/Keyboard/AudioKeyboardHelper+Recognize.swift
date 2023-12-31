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

extension AudioKeyboardHelper: RecognitionAudioKeyboardDelegate {

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
        // 键盘弹起时语音转文字面板点击发送事件
        self.isVoiceBehaviorRelay.accept(false)
        if self.hasEditRecognizeResult {
            audioTracker?.asrFinishThenEdit(sessionId: uploadID)
        }
    }

    func recognitionAudioKeyboardCleanAllText() {
        self.handleAudioMask(show: false, maskInputView: false)
        self.cleanAudioRecognizeState()
        self.cleanMessageWhenRecognition()
        self.lastSelectRange = nil
        // 键盘弹起时语音转文字面板点击clean事件
        self.isVoiceBehaviorRelay.accept(false)
    }

    func recognitionAudioKeyboardRecordStart() {
        self.audioPlayMediator?.syncStopPlayingAudio()
        self.handleAudioMask(show: true, maskInputView: false)
        self.handleAudioGestureMask(show: true)
        self.maskViewLock = true
        // 键盘弹起时语音转文字开始事件
        self.isVoiceBehaviorRelay.accept(true)
    }

    func recognitionAudioKeyboardRecordFinish() {
        self.handleAudioGestureMask(show: false)
        self.maskViewLock = false
        self.cleanAudioRecognizeView()
        self.cleanRecognizeLanguageLabel()
    }

    func recognitionAudioKeyboardRecordCancel() {
        self.handleAudioGestureMask(show: false)
        self.maskViewLock = false
        self.cleanAudioRecognizeView()
        self.cleanRecognizeLanguageLabel()
    }
}

extension AudioKeyboardHelper: RecognizeAudioGestureKeyboardDelegate {

    func recognitionAudioGestureKeyboardStartRecognition(uploadID: String) {
        self.isRecognizeFirstResult = true
        self.hasEditRecognizeResult = false
        self.recognitionAudioKeyboardStartRecognition(uploadID: uploadID)
    }

    func recognitionAudioGestureKeyboardRecordStart() {
        self.audioPlayMediator?.syncStopPlayingAudio()
        self.handleAudioGestureMask(show: true)
        self.handleAudioMask(show: true, maskInputView: false)
        self.maskViewLock = true
        self.insertRecognizeLanguageLabel()
        self.insertAudioRecognizeSpaceView(height: 100)
        self.clearTextViewTintColor()
    }

    func recognitionAudioGestureKeyboardRecordFinish() {
        self.handleAudioGestureMask(show: false)
        self.maskViewLock = false
        self.handleAudioMask(show: false, maskInputView: false)
        self.cleanAudioRecognizeView()
        self.cleanRecognizeLanguageLabel()
        self.cleanAudioRecognizeSpaceView()
        self.focusKeyboardInputView()
        self.recoverTextViewTintColor()
    }

    func recognitionAudioGestureKeyboardRecordCancel() {
        self.handleAudioGestureMask(show: false)
        self.maskViewLock = false
        self.handleAudioMask(show: false, maskInputView: false)
        self.cleanAudioRecognizeView()
        self.cleanRecognizeLanguageLabel()
        self.cleanAudioRecognizeSpaceView()
        self.recoverTextViewTintColor()
    }

    func recognitionAudioGestureAudioKeyboardState(isPrepare: Bool) {
        self.recognitionAudioKeyboardboardState(isPrepare: isPrepare)
    }
}
