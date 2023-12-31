//
//  AudioLongPressRecognizeView.swift
//  LarkAudio
//
//  Created by 李晨 on 2019/8/19.
//

import UIKit
import Foundation
import UniverseDesignToast
import UniverseDesignColor
import EENavigator
import LarkAlertController
import LKCommonsLogging
import AVFoundation
import LarkContainer
import UniverseDesignIcon

final class NewRecognizeAudioGestureKeyboard: UIView, UserResolverWrapper {
    @ScopedInjectedLazy var audioTracker: NewAudioTracker?

    fileprivate static let logger = Logger.log(NewRecognizeAudioGestureKeyboard.self, category: "LarkAudio")

    var keyboardFocusBlock: ((Bool) -> Void)?

    let viewModel: NewAudioRecognizeViewModel

    private weak var delegate: RecognizeAudioGestureKeyboardDelegate?
    private var gesture: UILongPressGestureRecognizer
    private var isInvokeEnd: Bool = false
    private var iconView: UIImageView = UIImageView()
    private var gestureView: UIView = UIView()

    let userResolver: UserResolver
    init(userResolver: UserResolver, viewModel: NewAudioRecognizeViewModel, gesture: UILongPressGestureRecognizer, delegate: RecognizeAudioGestureKeyboardDelegate?) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        self.gesture = gesture
        self.delegate = delegate
        super.init(frame: .zero)
        viewModel.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if self.window != nil {
            self.setupViews()
            self.layoutIfNeeded()
            self.startAudioRecord()
        }
    }

    private func setupViews() {
        self.backgroundColor = UIColor.clear
        guard let view = self.gesture.view else {
            return
        }
        gestureView.backgroundColor = UDColor.primaryContentDefault
        delegate?.recognitionAudioAddLongGestureButtonView(view: gestureView)
        self.gestureView.layer.cornerRadius = 8
        self.gestureView.layer.masksToBounds = true

        self.gestureView.addSubview(self.iconView)
        self.iconView.image = UDIcon.voice2textOutlined.ud.withTintColor(UIColor.ud.staticWhite)
        self.iconView.snp.makeConstraints { (maker) in
            maker.center.equalToSuperview()
            maker.width.height.equalTo(24)
        }
        self.gesture.addTarget(self, action: #selector(handleGesture(sender:)))
    }

    private func resetKeyboardView() {
        self.removeFromSuperview()
    }

    private func stopAudioRecord() {
        NewRecognizeAudioGestureKeyboard.logger.info("stop audio record")
        gestureView.backgroundColor = UDColor.primaryContentDefault
        self.viewModel.endRecord()
        self.keyboardFocusBlock?(false)
        self.resetKeyboardView()
    }

    private func startAudioRecord() {
        if !(gesture.state == .began || gesture.state == .changed) {
            Self.logger.info("gesture error!!! \(gesture.state)")
            isInvokeEnd = true
        }
        NewRecognizeAudioGestureKeyboard.logger.info("start audio record")
        gestureView.backgroundColor = UDColor.primaryContentPressed
        self.keyboardFocusBlock?(true)
        NewRecognizeAudioGestureKeyboard.logger.info("did start audio record")
        self.viewModel.startRecognition(language: RecognizeLanguageManager.shared.recognitionLanguage)
    }

    @objc
    private func handleGesture(sender: UILongPressGestureRecognizer) {
        NewRecognizeAudioGestureKeyboard.logger.info(
            "gesture state change",
            additionalData: ["state": AudioTracker.stateDescription(sender.state)]
        )
        switch sender.state {
        case .began:
            break
        case .failed, .cancelled, .ended, .possible:
            self.stopAudioRecord()
        case .changed:
            self.handleGestureMove()
        @unknown default:
            break
        }
    }

    private func handleGestureMove() {
    }
}

extension NewRecognizeAudioGestureKeyboard: AudioRecognizeViewModelDelegate {

    func audioRecordError(uploadID: String, error: Error) {
        guard let window = self.window else {
            assertionFailure("Lost From Window")
            return
        }
        // 强制结束手势
        self.gesture.isEnabled = false
        self.gesture.isEnabled = true
        DispatchQueue.main.async {
            let alertController = LarkAlertController()
            alertController.setTitle(text: BundleI18n.LarkAudio.Lark_Chat_AudioConvertedFailedOnlySendText)
            alertController.addPrimaryButton(text: BundleI18n.LarkAudio.Lark_Legacy_Sure)
            self.userResolver.navigator.present(alertController, from: window)
        }
        self.resetKeyboardView()
        self.delegate?.recognitionAudioGestureKeyboardRecordCancel()
        AudioTracker.audioConvertServerError(type: .textOnly)
    }

    func audioRecordStartFailed(uploadID: String) {
        guard let window = self.window else {
            assertionFailure("Lost From Window")
            return
        }
        // 强制结束手势
        self.gesture.isEnabled = false
        self.gesture.isEnabled = true
        DispatchQueue.main.async {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            let alertController = LarkAlertController()
            alertController.setTitle(text: BundleI18n.LarkAudio.Lark_Chat_VoiceMessageFailedToast)
            alertController.addPrimaryButton(text: BundleI18n.LarkAudio.Lark_Legacy_Sure)
            self.userResolver.navigator.present(alertController, from: window)
        }
        self.resetKeyboardView()
        self.delegate?.recognitionAudioGestureKeyboardRecordCancel()
    }

    func audioRecordFinish(uploadID: String) {
        self.delegate?.recognitionAudioGestureKeyboardRecordFinish()
        audioTracker?.asrRecordingStop(sessionId: uploadID)
    }

    func audioRecordWillStart(uploadID: String) {
        self.delegate?.recognitionAudioGestureKeyboardStartRecognition(uploadID: uploadID)
        self.delegate?.recognitionAudioGestureKeyboardRecordStart()
        audioTracker?.asrUserTouchButton(sessionId: uploadID)
    }

    func audioRecordDidStart(uploadID: String) {
        audioTracker?.asrRecordingStart(sessionId: uploadID)
        AudioReciableTracker.shared.audioRecognitionStart(sessionID: uploadID)
        if isInvokeEnd, userResolver.fg.staticFeatureGatingValue(with: "messenger.old.audio.stop.record") {
            Self.logger.error("gesture error!!!")
            stopAudioRecord()
        }
    }

    func audioRecordDidCancel(uploadID: String) {
        self.delegate?.recognitionAudioGestureKeyboardRecordFinish()
        audioTracker?.asrRecordingStop(sessionId: uploadID)
    }

    func audioRecordDidTooShort(uploadID: String) {
        self.delegate?.recognitionAudioGestureKeyboardRecordFinish()
    }

    func audioRecordUpdateRecordTime(time: TimeInterval) { }

    func audioRecordUpdateRecordVoice(power: Float) { }

    func audioRecordUpdateState(state: AudioState) {
        let isPrepare: Bool
        switch state {
        case .prepare:
            isPrepare = true
        case .normal, .recording:
            isPrepare = false
        }
        self.delegate?.recognitionAudioGestureAudioKeyboardState(isPrepare: isPrepare)
    }
}
