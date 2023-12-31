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

protocol RecognizeAudioGestureKeyboardDelegate: AnyObject {
    func recognitionAudioGestureKeyboardStartRecognition(uploadID: String)
    func recognitionAudioGestureKeyboardRecordStart()
    func recognitionAudioGestureKeyboardRecordFinish()
    func recognitionAudioGestureKeyboardRecordCancel()
    func recognitionAudioGestureAudioKeyboardState(isPrepare: Bool)
    func recognitionAudioAddLongGestureButtonView(view: UIView)
}

extension RecognizeAudioGestureKeyboardDelegate {
    func recognitionAudioAddLongGestureButtonView(view: UIView) {}
}

final class RecognizeAudioGestureKeyboard: UIView, UserResolverWrapper {
    @ScopedInjectedLazy var audioTracker: NewAudioTracker?

    fileprivate static let logger = Logger.log(RecognizeAudioGestureKeyboard.self, category: "LarkAudio")

    var keyboardFocusBlock: ((Bool) -> Void)?

    let viewModel: AudioRecognizeViewModel

    private weak var delegate: RecognizeAudioGestureKeyboardDelegate?
    private var gesture: UILongPressGestureRecognizer
    private var isInvokeEnd: Bool = false
    private var iconView: UIImageView = UIImageView()
    private var gestureView: UIView = UIView()
    private var voiceLayer: UIView = UIView()

    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.locations = [0, 1]
        layer.startPoint = CGPoint(x: 0.25, y: 0.5)
        layer.endPoint = CGPoint(x: 0.75, y: 0.5)
        return layer
    }()

    private let tapMask: UIView = {
        let mask = UIView()
        mask.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.2)
        return mask
    }()

    let userResolver: UserResolver
    init(userResolver: UserResolver, viewModel: AudioRecognizeViewModel, gesture: UILongPressGestureRecognizer, delegate: RecognizeAudioGestureKeyboardDelegate?) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        self.gesture = gesture
        self.delegate = delegate
        super.init(frame: .zero)
        self.gradientLayer.type = .radial
        self.gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        self.gradientLayer.endPoint = CGPoint(x: 1, y: 1)
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
            self.voiceLayer.center = self.gestureView.center
            self.startAudioRecord()
        }
    }

    private func setupViews() {
        self.backgroundColor = UIColor.clear
        guard let view = self.gesture.view else {
            return
        }
        let iconRect = view.convert(view.bounds, to: self)

        self.voiceLayer.backgroundColor = UDColor.colorfulBlue

        self.addSubview(self.voiceLayer)

        self.addSubview(self.gestureView)
        self.gestureView.layer.cornerRadius = 45
        self.gestureView.layer.masksToBounds = true
        self.gestureView.snp.makeConstraints { (maker) in
            maker.center.equalTo(iconRect.center)
            maker.width.height.equalTo(90)
        }

        self.gestureView.layer.addSublayer(self.gradientLayer)

        self.gestureView.addSubview(self.iconView)
        self.iconView.image = Resources.recognitionIcon
        self.iconView.snp.makeConstraints { (maker) in
            maker.center.equalToSuperview()
            maker.width.height.equalTo(24)
        }

        self.gestureView.addSubview(self.tapMask)
        self.tapMask.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        self.tapMask.isHidden = true

        self.gesture.addTarget(self, action: #selector(handleGesture(sender:)))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.gradientLayer.frame = self.gestureView.bounds
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.gradientLayer.colors = [UDColor.primaryPri400.cgColor, UDColor.primaryContentDefault.cgColor]
    }

    private func resetKeyboardView() {
        self.removeFromSuperview()
    }

    private func stopAudioRecord() {
        RecognizeAudioGestureKeyboard.logger.info("stop audio record")

        self.tapMask.isHidden = true
        self.viewModel.endRecord()
        self.keyboardFocusBlock?(false)
        self.resetKeyboardView()
    }

    private func startAudioRecord() {
        if !(gesture.state == .began || gesture.state == .changed) {
            Self.logger.info("gesture error!!! \(gesture.state)")
            isInvokeEnd = true
        }
        RecognizeAudioGestureKeyboard.logger.info("start audio record")

        self.tapMask.isHidden = false
        self.keyboardFocusBlock?(true)
        RecognizeAudioGestureKeyboard.logger.info("did start audio record")
        self.viewModel.startRecognition(language: RecognizeLanguageManager.shared.recognitionLanguage)
    }

    @objc
    private func handleGesture(sender: UILongPressGestureRecognizer) {
        RecognizeAudioGestureKeyboard.logger.info(
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

    fileprivate func voiceLayerHeight(power: Float) -> CGFloat {
        return min(120 + max(0, (CGFloat(power) - 40) / (65 - 40) * 120), 236)
    }

    fileprivate func updateRecordPowerLayer(power: Float, duration: TimeInterval) {
        UIView.animate(withDuration: duration) {
            let width = self.voiceLayerHeight(power: power)
            self.voiceLayer.center = self.gestureView.center
            self.voiceLayer.bounds = CGRect(x: 0, y: 0, width: width, height: width)
            self.voiceLayer.layer.masksToBounds = true
            self.voiceLayer.layer.cornerRadius = width / 2
        }
    }
}

extension RecognizeAudioGestureKeyboard: AudioRecognizeViewModelDelegate {

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

    func audioRecordUpdateRecordTime(time: TimeInterval) {
    }

    func audioRecordUpdateRecordVoice(power: Float) {
        self.updateRecordPowerLayer(power: power, duration: 0.1)
    }

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
