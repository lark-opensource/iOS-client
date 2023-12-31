//
//  RecognitionAudioKeyboard.swift
//  LarkAudio
//
//  Created by 李晨 on 2019/5/31.
//

import UIKit
import Foundation
import LarkLocalizations
import LarkActionSheet
import EENavigator
import Reachability
import UniverseDesignToast
import UniverseDesignColor
import LarkAlertController
import LKCommonsLogging
import AVFoundation
import CoreTelephony
import LarkContainer
import LarkMedia

protocol RecognitionAudioKeyboardDelegate: AnyObject {
    func recognitionAudioKeyboardStartRecognition(uploadID: String)
    func recognitionAudioKeyboardSendText(uploadID: String)
    func recognitionAudioKeyboardCleanAllText()
    func recognitionAudioKeyboardRecordStart()
    func recognitionAudioKeyboardRecordFinish()
    func recognitionAudioKeyboardRecordCancel()
    func recognitionAudioKeyboardboardState(isPrepare: Bool)
    func handleCaretView(show: Bool)
    func deleteBackward()
}

extension RecognitionAudioKeyboardDelegate {
    func handleCaretView(show: Bool) {}
    func deleteBackward() {}
}

/// 语音转文字
final class RecognitionAudioKeyboardWithLID: UIView, AudioKeyboardItemViewDelegate, UserResolverWrapper {
    fileprivate static let logger = Logger.log(RecognitionAudioKeyboardWithLID.self, category: "LarkAudio")

    var keyboardFocusBlock: ((Bool) -> Void)?

    let tipText: String = BundleI18n.LarkAudio.Lark_Chat_AudioToTextTips

    var recognitionType: RecognizeLanguageManager.RecognizeType { return .text }

    let title: String = BundleI18n.LarkAudio.Lark_Chat_AudioToText

    @ScopedInjectedLazy var byteViewService: AudioDependency?
    @ScopedInjectedLazy var audioTracker: NewAudioTracker?

    var layerColors: [CGColor] {
        [UDColor.primaryPri400.cgColor, UDColor.primaryContentDefault.cgColor]
    }
    var keyboardView: UIView {
        return self
    }

    var isNetConnected: Bool = true

    let viewModel: AudioRecognizeViewModel

    var macInputStyle: Bool = false

    private weak var delegate: RecognitionAudioKeyboardDelegate?

    private var gesture: UILongPressGestureRecognizer = UILongPressGestureRecognizer()

    private var iconView: UIImageView = UIImageView()
    private var gestureView: UIView = UIView()
    private var voiceLayer: UIView = UIView()
    private lazy var cancelButton: AudioKeyboardInteractiveButton = AudioKeyboardInteractiveButton(type: .cancel, userResolver: userResolver)
    private lazy var sendButton: AudioKeyboardInteractiveButton = AudioKeyboardInteractiveButton(type: .sendAll, userResolver: userResolver)
    private var separatorLine: UIView = UIView()
    private lazy var languageLabel: AudioLanguageLabel = AudioLanguageLabel(userResolver: userResolver, type: .textOnly)
    private var sessionId: String = ""
    // 长按手势开始后会调用trylock后才开始录音，这时手指离开会立即调用stop，此时lock完成后录音启动且无法终止
    // 在trylock前将属性设置为 false，真正启动后会回调 didStart方法，如果在此期间调用过 stop，则立即停止录音
    private var isInvokeEnd: Bool = false
    /// 用于动画快速定位用
    private var leftView: UIView = UIView()
    /// 用于动画快速定位用
    private var rightView: UIView = UIView()

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

    init(userResolver: UserResolver,
         viewModel: AudioRecognizeViewModel,
         delegate: RecognitionAudioKeyboardDelegate?) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        self.delegate = delegate
        super.init(frame: .zero)
        self.gradientLayer.type = .radial
        self.gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        self.gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        viewModel.delegate = self
        self.setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        self.backgroundColor = UIColor.ud.bgBodyOverlay
        self.addSubview(languageLabel)
        languageLabel.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview()
            maker.centerX.equalToSuperview()
        }
        self.languageLabel.setTipString(self.tipText)

        self.addSubview(self.leftView)
        self.addSubview(self.rightView)
        self.addSubview(self.cancelButton)
        self.addSubview(self.sendButton)

        cancelButton.setHandler(clickCancelBtn)
        sendButton.setHandler(clickSendBtn)

        self.voiceLayer.backgroundColor = UDColor.colorfulBlue

        self.addSubview(self.voiceLayer)

        self.addSubview(self.gestureView)
        self.gestureView.layer.cornerRadius = 60
        self.gestureView.layer.masksToBounds = true
        self.gestureView.backgroundColor = UIColor.ud.colorfulTurquoise
        self.gestureView.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview().offset(59)
            maker.width.height.equalTo(120)
        }

        self.gradientLayer.frame = CGRect(x: 0, y: 0, width: 120, height: 120)
        self.gestureView.layer.addSublayer(self.gradientLayer)

        self.gestureView.addSubview(self.iconView)
        self.iconView.image = Resources.recognitionIcon
        self.iconView.snp.makeConstraints { (maker) in
            maker.center.equalToSuperview()
            maker.width.height.equalTo(28)
        }

        self.gestureView.addSubview(self.tapMask)
        self.tapMask.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        self.tapMask.isHidden = true

        self.gesture.minimumPressDuration = 0.1
        self.gestureView.addGestureRecognizer(gesture)
        self.gesture.addTarget(self, action: #selector(handleGesture(sender:)))

        self.addSubview(self.separatorLine)
        self.separatorLine.backgroundColor = UIColor.ud.bgBodyOverlay
        self.separatorLine.snp.makeConstraints { (maker) in
            maker.left.right.top.equalToSuperview()
            maker.height.equalTo(0.5)
        }
        self.leftView.snp.remakeConstraints { (maker) in
            maker.left.equalToSuperview().offset(38)
            maker.width.equalTo(110)
            maker.height.greaterThanOrEqualTo(54)
            maker.top.equalTo(gestureView.snp.bottom).offset(32)
        }

        self.rightView.snp.remakeConstraints { (maker) in
            maker.right.equalToSuperview().offset(-38)
            maker.width.equalTo(110)
            maker.height.greaterThanOrEqualTo(54)
            maker.top.equalTo(gestureView.snp.bottom).offset(32)
        }
        self.resetKeyboardView()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.gradientLayer.colors = layerColors
    }

    func resetKeyboardView() {
        RecognitionAudioKeyboardWithLID.logger.info("reset keyboard view")

        self.voiceLayer.isHidden = true
        self.cancelButton.isHidden = true
        self.sendButton.isHidden = true
        self.languageLabel.isHidden = false
        self.tapMask.isHidden = true
        self.separatorLine.isHidden = true

        self.gestureView.snp.remakeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview().offset(59)
            maker.width.height.equalTo(120)
        }
        self.gestureView.layer.cornerRadius = 60
        self.gestureView.layoutIfNeeded()
        self.voiceLayer.center = CGPoint(x: self.frame.width / 2, y: 119)
        self.voiceLayer.bounds = .zero

        self.keyboardFocusBlock?(false)
    }

    private func stopAudioRecognition() {
        RecognitionAudioKeyboardWithLID.logger.info("stop audio recognition")
        guard isNetConnected else {
            self.resetKeyboardView()
            return
        }
        self.tapMask.isHidden = true
        self.voiceLayer.isHidden = true
        self.cancelButton.isHidden = false
        self.sendButton.isHidden = false
        self.setButtomInCenter()
        self.layoutIfNeeded()

        let gestureViewRadius: CGFloat
        self.gestureView.snp.remakeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview().offset(69)
            maker.width.height.equalTo(100)
        }
        gestureViewRadius = 50
        self.setButtonAverage()
        self.viewModel.endRecord()

        UIView.animate(withDuration: 0.25) {
            // 如果动画过程中已经 reset UI，则不再改变 cornerRadius
            if !self.sendButton.isHidden {
                self.layoutIfNeeded()
                self.gestureView.layer.cornerRadius = gestureViewRadius
            }
        }
    }

    private func startAudioRecognition() {
        RecognitionAudioKeyboardWithLID.logger.info("start audio recognition")

        self.setupStartAudioLayout()
        self.keyboardFocusBlock?(true)

        RecognitionAudioKeyboardWithLID.logger.info("did start audio recognition")
        self.viewModel.startRecognition(language: RecognizeLanguageManager.shared.recognitionLanguage)
    }

    private func setupStartAudioLayout() {
        self.tapMask.isHidden = false
        self.voiceLayer.isHidden = false
        self.cancelButton.isHidden = true
        self.sendButton.isHidden = true
        self.languageLabel.isHidden = true
        self.separatorLine.isHidden = false || self.macInputStyle
        self.gestureView.snp.remakeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview().offset(59)
            maker.width.height.equalTo(120)
        }
        self.gestureView.layer.cornerRadius = 60

        self.layoutIfNeeded()
        self.voiceLayer.center = CGPoint(x: self.frame.width / 2, y: 119)
        self.voiceLayer.bounds = .zero
    }

    func setButtonAverage() {
        cancelButton.snp.remakeConstraints { (maker) in
            maker.left.top.width.height.equalTo(leftView)
        }
        sendButton.snp.remakeConstraints { (maker) in
            maker.left.top.width.height.equalTo(rightView)
        }
    }

    func setButtomInCenter() {
        cancelButton.snp.remakeConstraints { (maker) in
            maker.center.equalTo(gestureView)
        }
        sendButton.snp.remakeConstraints { (maker) in
            maker.center.equalTo(gestureView)
        }
    }

    @objc
    private func handleGesture(sender: UILongPressGestureRecognizer) {
        RecognitionAudioKeyboardWithLID.logger.info(
            "gesture state change",
            additionalData: ["state": AudioTracker.stateDescription(sender.state)])
        switch sender.state {
        case .began:
            var resetBlock = { [weak self] in
                /// 强制结束手势
                self?.gesture.isEnabled = false
                self?.gesture.isEnabled = true
                self?.resetKeyboardView()
            }

            if checkNetworkConnection() &&
                checkCallingState() &&
                checkByteViewState() {
                isInvokeEnd = false
                AudioMediaLockManager.shared.tryLock(userResolver: userResolver, from: self.window, callback: { [weak self] result in
                    if result {
                        self?.startAudioRecognition()
                    } else {
                        resetBlock()
                    }
                }, interruptedCallback: { _ in
                    resetBlock()
                })
            } else {
                resetBlock()
            }

            AudioTracker.imChatVoiceMsgClick(click: .holdToTalk, viewType: .text)
        case .failed, .cancelled, .ended, .possible:
            isInvokeEnd = true
            self.stopAudioRecognition()
        case .changed:
            break
        @unknown default:
            break
        }
    }

    private func checkNetworkConnection() -> Bool {
        guard let reach = Reachability() else { return false }
        guard let window = self.window else {
            assertionFailure("Lost From Window")
            return true
        }
        if reach.connection == .none {
            self.isNetConnected = false
            RecognitionAudioKeyboardWithLID.logger.info("network connection is none")
            let alertController = LarkAlertController()
            alertController.setTitle(text: BundleI18n.LarkAudio.Lark_Chat_AudioToTextNetworkError)
            alertController.addPrimaryButton(text: BundleI18n.LarkAudio.Lark_Legacy_Sure)
            userResolver.navigator.present(alertController, from: window)
            return false
        }
        self.isNetConnected = true
        return true
    }

    private func checkCallingState() -> Bool {
        // 飞书内部 vc 正在运行时，不判断 CTCall
        guard let byteViewService else { return false }
        if byteViewService.byteViewHasCurrentModule() ||
            byteViewService.byteViewIsRinging() {
            return true
        }
        guard let window = self.window else {
            assertionFailure("Lost From Window")
            return true
        }
        if let calls = AudioKeyboardHelper.getCurrentCalls(),
           !calls.isEmpty {
            RecognitionAudioKeyboardWithLID.logger.info("user is calling")
            let alertController = LarkAlertController()
            alertController.setTitle(text: BundleI18n.LarkAudio.Lark_Chat_VoiceMessageFailedToast)
            alertController.addPrimaryButton(text: BundleI18n.LarkAudio.Lark_Legacy_Sure)
            userResolver.navigator.present(alertController, from: window)
            return false
        }
        return true
    }

    private func checkByteViewState() -> Bool {
        guard let byteViewService else { return false }
        guard let window = self.window else {
            assertionFailure("Lost From Window")
            return false
        }

        if byteViewService.byteViewHasCurrentModule() {
            let text = (byteViewService.byteViewIsRinging() == true) ? byteViewService.byteViewInRingingCannotCallVoIPText() : byteViewService.byteViewIsInCallText()
            let alertController = LarkAlertController()
            alertController.setTitle(text: text)
            alertController.addPrimaryButton(text: BundleI18n.LarkAudio.Lark_Legacy_Sure)
            userResolver.navigator.present(alertController, from: window)
            return false
        }
        return true
    }

    @objc
    private func clickCancelBtn() {
        audioTracker?.asrFinishThenCancel(sessionId: sessionId)
        self.resetKeyboardView()
        self.delegate?.recognitionAudioKeyboardCleanAllText()

        AudioTracker.imChatVoiceMsgClick(click: .empty, viewType: .text)
    }

    @objc
    private func clickSendBtn() {
        self.resetKeyboardView()
        self.delegate?.recognitionAudioKeyboardSendText(uploadID: self.sessionId)
        AudioTracker.imChatVoiceMsgClick(click: .send, viewType: .text)
    }

    fileprivate func voiceLayerHeight(power: Float) -> CGFloat {
        return min(120 + max(0, (CGFloat(power) - 40) / (65 - 40) * 120), 236)
    }

    fileprivate func updateRecordPowerLayer(power: Float, duration: TimeInterval) {
        UIView.animate(withDuration: duration) {
            let width = self.voiceLayerHeight(power: power)
            self.voiceLayer.center = self.gestureView.center //CGPoint(x: self.frame.width / 2, y: 119)
            self.voiceLayer.bounds = CGRect(x: 0, y: 0, width: width, height: width)
            self.voiceLayer.layer.masksToBounds = true
            self.voiceLayer.layer.cornerRadius = width / 2
        }
    }
}

extension RecognitionAudioKeyboardWithLID: AudioRecognizeViewModelDelegate {
    func audioRecordError(uploadID: String, error: Error) {
        self.sessionId = ""
        // 强制结束手势
        self.gesture.isEnabled = false
        self.gesture.isEnabled = true

        if let window = self.window {
            DispatchQueue.main.async {
                let alertController = LarkAlertController()
                alertController.setTitle(text: BundleI18n.LarkAudio.Lark_Chat_AudioConvertedFailedOnlySendText)
                alertController.addPrimaryButton(text: BundleI18n.LarkAudio.Lark_Legacy_Sure)
                self.userResolver.navigator.present(alertController, from: window)
            }
        } else {
            assertionFailure("Lost From Window")
        }
        AudioTracker.audioConvertServerError(type: .textOnly)
        self.resetKeyboardView()
        self.delegate?.recognitionAudioKeyboardRecordCancel()
    }

    func audioRecordStartFailed(uploadID: String) {
        // 强制结束手势
        self.gesture.isEnabled = false
        self.gesture.isEnabled = true

        if let window = self.window {
            DispatchQueue.main.async {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                let alertController = LarkAlertController()
                alertController.setTitle(text: BundleI18n.LarkAudio.Lark_Chat_VoiceMessageFailedToast)
                alertController.addPrimaryButton(text: BundleI18n.LarkAudio.Lark_Legacy_Sure)
                self.userResolver.navigator.present(alertController, from: window)
            }
        }
        self.sessionId = ""
        self.resetKeyboardView()
        self.delegate?.recognitionAudioKeyboardRecordCancel()
    }

    func audioRecordFinish(uploadID: String) {
        self.sessionId = ""
        self.delegate?.recognitionAudioKeyboardRecordFinish()
        audioTracker?.asrRecordingStop(sessionId: uploadID)
    }

    func audioRecordWillStart(uploadID: String) {
        self.sessionId = uploadID
        self.delegate?.recognitionAudioKeyboardStartRecognition(uploadID: uploadID)
        self.delegate?.recognitionAudioKeyboardRecordStart()
        audioTracker?.asrUserTouchButton(sessionId: uploadID)
    }

    func audioRecordDidStart(uploadID: String) {
        audioTracker?.asrRecordingStart(sessionId: uploadID)
        AudioReciableTracker.shared.audioRecognitionStart(sessionID: uploadID)
        if isInvokeEnd, userResolver.fg.staticFeatureGatingValue(with: "messenger.old.audio.stop.record") {
            Self.logger.error("gesture error!!!")
            stopAudioRecognition()
        }
    }

    func audioRecordDidCancel(uploadID: String) {
        self.sessionId = ""
        self.delegate?.recognitionAudioKeyboardRecordFinish()
        audioTracker?.asrRecordingStop(sessionId: uploadID)
    }

    func audioRecordDidTooShort(uploadID: String) {
        self.sessionId = ""
        self.delegate?.recognitionAudioKeyboardRecordFinish()
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
        self.delegate?.recognitionAudioKeyboardboardState(isPrepare: isPrepare)
    }
}
