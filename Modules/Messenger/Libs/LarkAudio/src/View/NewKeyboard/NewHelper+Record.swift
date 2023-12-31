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
extension NewAudioKeyboardHelper: RecordAudioKeyboardDelegate {
    var animationDisplayState: RecordAnimationView.DisplayState {
        animationView?.displayState ?? RecordAnimationView.DisplayState.unpressed
    }

    func recordAudioKeyboardSendAudio(audioData: AudioDataInfo) {
        self.delegate?.audiokeybordSendMessage(audioData)
        self.handleAudioMask(show: false, maskInputView: true)
        self.removeAnimationView()
        self.handleAudioGestureMask(show: false)
        // 录音完成发送事件
        self.isVoiceBehaviorRelay.accept(false)
    }

    func recordAudioKeyboardSendAudio(uploadID: String, duration: TimeInterval) {
        AudioTracker.trackSendAudio(duration: TimeInterval(duration), sendType: .audioOnly)
        let audioInfo = StreamAudioInfo(uploadID: uploadID, length: duration)
        self.delegate?.audiokeybordSendMessage(audioInfo: audioInfo)
        self.removeAnimationView()
        self.handleAudioMask(show: false, maskInputView: true)
        self.handleAudioGestureMask(show: false)
        // 录音完成发送事件
        self.isVoiceBehaviorRelay.accept(false)
    }

    func recordAudioKeyboardRecordStart() {
        self.audioPlayMediator?.syncStopPlayingAudio()
        self.handleAudioMask(show: true, maskInputView: true, bottomOffset: 59 - 12 + 46)
        self.addAnimationView()
        self.handleAudioGestureMask(show: true)
        // 键盘弹起时录音开始事件
        self.isVoiceBehaviorRelay.accept(true)
    }

    func recordAudioKeyboardRecordCancel() {
        AudioTracker.trackCancelAudio()
        NewAudioKeyboardHelper.logger.info("record keyboard cancel")
        animationView?.stopPress(comple: { [weak self] in
            self?.removeAnimationView()
            self?.handleAudioMask(show: false, maskInputView: true)
            self?.handleAudioGestureMask(show: false)
        })
        // 录音被取消事件
        self.isVoiceBehaviorRelay.accept(false)
    }

    func updateRecordTime(str: String) {
        animationView?.updateTime(str: str)
    }

    func updatePoint(point: CGPoint) {
        animationView?.updatePoint(point: point)
    }

    func updateDecible(decible: Float) {
        animationView?.updateDecible(decible: decible)
    }

    private func addAnimationView() {
        if audioMaskView.superview != nil {
            let view = RecordAnimationView()
            animationView = view
            audioMaskView.addSubview(view)
            view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }

    private func removeAnimationView() {
        self.animationView?.removeFromSuperview()
        self.animationView = nil
    }
}

extension NewAudioKeyboardHelper: RecordAudioGestureKeyboardDelegate {
    func recordAudioGestureKeyboardSendAudio(audioData: AudioDataInfo) {
        self.delegate?.audiokeybordSendMessage(audioData)
        self.cleanLongGestureButtonView()
        self.cleanAnimationView()
        self.handleAudioGestureMask(show: false)
        // 录音完成发送事件
        self.isVoiceBehaviorRelay.accept(false)
    }

    func recordAudioGestureKeyboardSendAudio(uploadID: String, duration: TimeInterval) {
        AudioTracker.trackSendAudio(duration: TimeInterval(duration), sendType: .audioOnly)
        let audioInfo = StreamAudioInfo(uploadID: uploadID, length: duration)
        self.delegate?.audiokeybordSendMessage(audioInfo: audioInfo)
        self.cleanLongGestureButtonView()
        self.cleanAnimationView()
        self.handleAudioGestureMask(show: false)
        // 录音完成发送事件
        self.isVoiceBehaviorRelay.accept(false)
    }

    func recordAudioGestureKeyboardRecordStart() {
        self.audioPlayMediator?.syncStopPlayingAudio()
        self.insertAnimationView()
        self.handleAudioGestureMask(show: true)
        // 键盘弹起时录音开始事件
        self.isVoiceBehaviorRelay.accept(true)
    }

    func recordAudioGestureKeyboardRecordCancel() {
        AudioTracker.trackCancelAudio()
        NewAudioKeyboardHelper.logger.info("record gesture cancel")
        self.animationView?.stopPress(comple: { [weak self] in
            self?.cleanLongGestureButtonView()
            self?.cleanAnimationView()
            self?.handleAudioGestureMask(show: false)
        })
        // 录音被取消事件
        self.isVoiceBehaviorRelay.accept(false)
    }

    func audioGestureAddLongGestureView(view: UIView) {
        insertLongGestureButtonView(view: view)
    }

    private func insertAnimationView() {
        guard let keyboardView = self.delegate?.audiokeybordPanelView() else { return }
        let viewCache = keyboardView.inputStackView.arrangedSubviews
        for view in viewCache {
            keyboardView.inputStackView.removeArrangedSubview(view)
            view.isHidden = true
        }
        recordTextKeyboardViewCache = viewCache

        let view = RecordAnimationView()
        animationView = view

        keyboardView.inputStackView.insertArrangedSubview(view, at: 0)
        view.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(190)
        }
        keyboardView.keyboardPanel?.panelBarHidden = true
    }

    private func cleanAnimationView() {
        guard let keyboardView = self.delegate?.audiokeybordPanelView() else { return }
        if let animationView {
            keyboardView.inputStackView.removeArrangedSubview(animationView)
            animationView.removeFromSuperview()
            self.animationView = nil
        }
        for view in recordTextKeyboardViewCache.reversed() {
            keyboardView.inputStackView.insertArrangedSubview(view, at: 0)
            view.isHidden = false
        }
        recordTextKeyboardViewCache = []
        keyboardView.keyboardPanel?.panelBarHidden = false
        self.cleanAudioRecognizeSpaceView()
    }
}
