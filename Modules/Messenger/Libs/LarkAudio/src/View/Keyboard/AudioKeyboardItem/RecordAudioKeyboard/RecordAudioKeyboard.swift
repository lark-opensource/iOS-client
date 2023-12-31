//
//  RecordAudioKeyboard.swift
//  LarkAudio
//
//  Created by 李晨 on 2019/5/31.
//

import UIKit
import Foundation
import UniverseDesignToast
import UniverseDesignColor
import LarkSDKInterface
import LKCommonsLogging
import EENavigator
import LarkAlertController
import CoreTelephony
import LarkMessengerInterface
import LarkContainer
import LarkMedia
import LarkSendMessage

protocol RecordAudioKeyboardDelegate: AnyObject {
    var animationDisplayState: RecordAnimationView.DisplayState { get }
    func recordAudioKeyboardSendAudio(audioData: AudioDataInfo)
    func recordAudioKeyboardSendAudio(uploadID: String, duration: TimeInterval)
    func recordAudioKeyboardRecordStart()
    func recordAudioKeyboardRecordCancel()
    func updateRecordTime(str: String)
    func updatePoint(point: CGPoint)
    func updateDecible(decible: Float)
}

final class RecordAudioKeyboard: UIView, AudioKeyboardItemViewDelegate, UserResolverWrapper {

    fileprivate static let logger = Logger.log(RecordAudioKeyboard.self, category: "LarkAudio")

    var keyboardFocusBlock: ((Bool) -> Void)?

    let tipText: String = BundleI18n.LarkAudio.Lark_Chat_HoldToRecordAudio

    let title: String = BundleI18n.LarkAudio.Lark_Chat_RecordAudio

    var recognitionType: RecognizeLanguageManager.RecognizeType { return .audio }
    var layerColors: [CGColor] {
        [UDColor.primaryPri400.cgColor, UDColor.primaryContentDefault.cgColor]
    }

    var keyboardView: UIView {
        return self
    }

    let viewModel: AudioRecordViewModel
    private weak var delegate: RecordAudioKeyboardDelegate?

    fileprivate var recordLengthLimit: TimeInterval = 5 * 60

    private var gesture: UILongPressGestureRecognizer = UILongPressGestureRecognizer()

    private var tipLabel = UILabel()
    // 注释在语音转文字面板的里，相同的属性名称下
    private var isInvokeEnd: Bool = false
    private var iconView: UIImageView = UIImageView()
    private var gestureView: UIView = UIView()
    private var animationHelper = RecordAnimationHelper()

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

    fileprivate var readyToCancel: Bool = false {
        didSet {
            if oldValue == readyToCancel { return }
            if readyToCancel {
                self.gradientLayer.colors = UIColor.ud.gradientRed.cgColors
            } else {
                self.gradientLayer.colors = layerColors
            }
            animationHelper.setReadyToCancel(
                readyToCancel: readyToCancel,
                gestureView: gestureView,
                gesture: gesture
            )
        }
    }

    @ScopedInjectedLazy var byteViewService: AudioDependency?
    let userResolver: UserResolver
    init(userResolver: UserResolver, viewModel: AudioRecordViewModel, delegate: RecordAudioKeyboardDelegate?) {
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
        self.tipLabel.font = UIFont.systemFont(ofSize: 14)
        self.tipLabel.textAlignment = .center
        self.tipLabel.textColor = UIColor.ud.textPlaceholder
        self.tipLabel.text = self.tipText
        self.addSubview(self.tipLabel)
        self.tipLabel.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.top.equalTo(21)
        }

        self.addSubview(self.gestureView)
        self.gestureView.layer.cornerRadius = 60
        self.gestureView.layer.masksToBounds = true
        self.gestureView.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview().offset(59)
            maker.width.height.equalTo(120)
        }

        self.gestureView.layer.addSublayer(self.gradientLayer)

        self.gestureView.addSubview(self.iconView)
        self.iconView.image = Resources.recordIcon
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

        self.resetKeyboardView()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.gradientLayer.frame = self.gestureView.bounds
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.gradientLayer.colors = layerColors
    }

    func resetKeyboardView() {
        RecordAudioKeyboard.logger.info("reset keyboard view")
        self.animationHelper.removeFloatView()
        self.readyToCancel = false
        self.tipLabel.isHidden = false
    }

    private func stopAudioRecord() {
        RecordAudioKeyboard.logger.info("stop audio record")
        self.tapMask.isHidden = true
        if self.readyToCancel {
            self.viewModel.cancelRecord()
        } else {
            self.viewModel.endRecord()
        }
        self.keyboardFocusBlock?(false)
        self.resetKeyboardView()
    }

    private func startAudioRecord() {
        RecordAudioKeyboard.logger.info("start audio record")
        self.tipLabel.isHidden = true
        self.readyToCancel = false
        self.tapMask.isHidden = false
        self.keyboardFocusBlock?(true)
        if let topWindow = self.window {
            self.animationHelper.showFloatBarView(
                in: topWindow,
                gestureView: gestureView,
                gesture: gesture,
                userResolver: userResolver
            )
        }
        self.viewModel.startRecordAudio()
    }

    @objc
    private func handleGesture(sender: UILongPressGestureRecognizer) {
        RecordAudioKeyboard.logger.info(
            "gesture state change",
            additionalData: ["state": AudioTracker.stateDescription(sender.state)]
        )
        switch sender.state {
        case .began:
            var resetBlock = { [weak self] in
                /// 强制结束手势
                self?.gesture.isEnabled = false
                self?.gesture.isEnabled = true
            }
            if checkCallingState() &&
                checkByteViewState() {
                isInvokeEnd = false
                AudioMediaLockManager.shared.tryLock(userResolver: userResolver, from: self.window, callback: { [weak self] result in
                    if result {
                        self?.startAudioRecord()
                    } else {
                        resetBlock()
                    }
                }, interruptedCallback: { _ in
                    resetBlock()
                })
            } else {
                resetBlock()
            }

            AudioTracker.imChatVoiceMsgClick(click: .holdToTalk, viewType: .audio)
        case .failed, .cancelled, .ended, .possible:
            isInvokeEnd = true
            self.stopAudioRecord()
        case .changed:
            self.handleGestureMove()
        @unknown default:
            break
        }
    }

    private func handleGestureMove() {
        if !self.viewModel.isRecording { return }
        self.animationHelper.handleGestureMove(
            gestureView: gestureView,
            gesture: gesture
        )
        self.readyToCancel = self.animationHelper.checkReadyToCancel(
            gestureView: gestureView,
            gesture: gesture
        )
    }
}

extension RecordAudioKeyboard: AudioRecordViewModelDelegate {
    func audioRecordFinish(_ audioData: AudioDataInfo) {
        self.delegate?.recordAudioKeyboardSendAudio(audioData: audioData)
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
        self.delegate?.recordAudioKeyboardRecordCancel()
    }

    func audioRecordFinish(uploadID: String, duration: TimeInterval) {
        self.delegate?.recordAudioKeyboardSendAudio(uploadID: uploadID, duration: duration)
    }

    func audioRecordWillStart(uploadID: String) {
        self.delegate?.recordAudioKeyboardRecordStart()
    }

    func audioRecordDidStart(uploadID: String) {
        if isInvokeEnd, userResolver.fg.staticFeatureGatingValue(with: "messenger.old.audio.stop.record") {
            Self.logger.error("gesture error!!!")
            stopAudioRecord()
        }
    }

    func audioRecordDidCancel(uploadID: String) {
        self.delegate?.recordAudioKeyboardRecordCancel()
    }

    func audioRecordDidTooShort(uploadID: String) {
        self.delegate?.recordAudioKeyboardRecordCancel()
        if let window = self.window {
            UDToast.showTipsOnScreenCenter(with: BundleI18n.LarkAudio.Lark_Legacy_VoiceIndicatorTooShort, on: window)
        }
    }

    func audioRecordUpdateRecordTime(time: TimeInterval) {
        self.animationHelper.floatView?.time = time

        if time >= self.recordLengthLimit {
            self.stopAudioRecord()
        } else if self.recordLengthLimit - time <= 10 {
            self.animationHelper.floatView?.setCountDown(time: self.recordLengthLimit - time)
        }
    }

    func audioRecordUpdateRecordVoice(power: Float) {
        self.animationHelper.floatView?.append(decible: CGFloat(power))
    }

    func audioRecordUpdateState(state: AudioState) {
        switch state {
        case .prepare:
            // 延时 0.1s 避免每次都出现 loading 状态
            NSObject.cancelPreviousPerformRequests(withTarget: self)
            self.perform(#selector(showProgressState), with: nil, afterDelay: 0.1)
        default:
            NSObject.cancelPreviousPerformRequests(withTarget: self)
            self.animationHelper.floatView?.processing = false
        }
    }

    @objc
    private func showProgressState() {
        self.animationHelper.floatView?.processing = true
    }

    private func checkCallingState() -> Bool {
        guard let byteViewService else { return false }
        // 飞书内部 vc 正在运行时，不判断 CTCall
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
            RecordAudioKeyboard.logger.info("user is calling")
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
}
