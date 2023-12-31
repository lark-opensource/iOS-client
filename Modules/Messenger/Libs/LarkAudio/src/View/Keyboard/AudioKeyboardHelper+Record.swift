//
//  AudioKeyboardHelper+Record.swift
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
import LarkSDKInterface
import LarkMessengerInterface
import LarkSendMessage

// MARK: - AudioRecordViewModelDelegate
extension AudioKeyboardHelper: RecordAudioKeyboardDelegate, RecordAudioGestureKeyboardDelegate {
    var animationDisplayState: RecordAnimationView.DisplayState { .unpressed }
    func updateRecordTime(str: String) { }
    func updatePoint(point: CGPoint) { }
    func updateDecible(decible: Float) { }
    func recordAudioGestureKeyboardSendAudio(audioData: AudioDataInfo) {
        self.recordAudioKeyboardSendAudio(audioData: audioData)
    }

    func recordAudioGestureKeyboardSendAudio(uploadID: String, duration: TimeInterval) {
        self.recordAudioKeyboardSendAudio(uploadID: uploadID, duration: duration)
    }

    func recordAudioGestureKeyboardRecordStart() {
        self.recordAudioKeyboardRecordStart()
    }

    func recordAudioGestureKeyboardRecordCancel() {
        self.recordAudioKeyboardRecordCancel()
    }

    func recordAudioKeyboardSendAudio(audioData: AudioDataInfo) {
        self.delegate?.audiokeybordSendMessage(audioData)
        self.handleAudioMask(show: false, maskInputView: true)
        self.handleAudioGestureMask(show: false)
        // 录音完成发送事件
        self.isVoiceBehaviorRelay.accept(false)
    }

    func recordAudioKeyboardSendAudio(uploadID: String, duration: TimeInterval) {
        AudioTracker.trackSendAudio(duration: TimeInterval(duration), sendType: .audioOnly)
        let audioInfo = StreamAudioInfo(uploadID: uploadID, length: duration)
        self.delegate?.audiokeybordSendMessage(audioInfo: audioInfo)
        self.handleAudioMask(show: false, maskInputView: true)
        self.handleAudioGestureMask(show: false)
        // 录音完成发送事件
        self.isVoiceBehaviorRelay.accept(false)
    }

    func recordAudioKeyboardRecordStart() {
        self.audioPlayMediator?.syncStopPlayingAudio()
        self.handleAudioMask(show: true, maskInputView: true)
        self.handleAudioGestureMask(show: true)
        // 键盘弹起时录音开始事件
        self.isVoiceBehaviorRelay.accept(true)
    }

    func recordAudioKeyboardRecordCancel() {
        AudioTracker.trackCancelAudio()
        self.handleAudioMask(show: false, maskInputView: true)
        self.handleAudioGestureMask(show: false)
        // 录音被取消事件
        self.isVoiceBehaviorRelay.accept(false)
    }
}
