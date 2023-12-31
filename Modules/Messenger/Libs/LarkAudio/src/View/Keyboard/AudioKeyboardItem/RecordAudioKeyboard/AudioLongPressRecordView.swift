//
//  AudioLongPressRecordView.swift
//  LarkAudio
//
//  Created by 李晨 on 2019/5/29.
//

import UIKit
import Foundation
import UniverseDesignToast
import UniverseDesignColor
import LarkSDKInterface
import LKCommonsLogging
import EENavigator
import LarkAlertController
import LarkSendMessage
import LarkContainer

protocol RecordAudioGestureKeyboardDelegate: AnyObject {
    var animationDisplayState: RecordAnimationView.DisplayState { get }
    func recordAudioGestureKeyboardSendAudio(audioData: AudioDataInfo)
    func recordAudioGestureKeyboardSendAudio(uploadID: String, duration: TimeInterval)
    func recordAudioGestureKeyboardRecordStart()
    func recordAudioGestureKeyboardRecordCancel()
    func updateRecordTime(str: String)
    func updatePoint(point: CGPoint)
    func updateDecible(decible: Float)

    func addLongGestureView(view: UIView)
}

extension RecordAudioGestureKeyboardDelegate {
    func addLongGestureView(view: UIView) {}
}

final class RecordAudioGestureKeyboard: UIView, UserResolverWrapper {
    fileprivate static let logger = Logger.log(RecordAudioGestureKeyboard.self, category: "LarkAudio")

    var keyboardFocusBlock: ((Bool) -> Void)?

    let viewModel: AudioRecordViewModel

    private weak var delegate: RecordAudioGestureKeyboardDelegate?
    private var gesture: UILongPressGestureRecognizer

    private var recordLengthLimit: TimeInterval = 5 * 60
    private var isInvokeEnd: Bool = false
    private var iconView: UIImageView = UIImageView()
    private var gestureView: UIView = UIView()

    private var animationHelper = RecordAnimationHelper()

    var layerColors: [CGColor] {
        [UDColor.primaryPri400.cgColor, UDColor.primaryContentDefault.cgColor]
    }
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

    let userResolver: UserResolver
    init(userResolver: UserResolver, viewModel: AudioRecordViewModel, gesture: UILongPressGestureRecognizer, delegate: RecordAudioGestureKeyboardDelegate?) {
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
            self.startAudioRecord()
        }
    }

    private func setupViews() {
        self.backgroundColor = UIColor.clear
        guard let view = self.gesture.view else {
            return
        }
        let iconRect = view.convert(view.bounds, to: self)

        self.addSubview(self.gestureView)
        self.gestureView.layer.cornerRadius = 45
        self.gestureView.layer.masksToBounds = true
        self.gestureView.snp.makeConstraints { (maker) in
            maker.center.equalTo(iconRect.center)
            maker.width.height.equalTo(90)
        }

        self.gestureView.layer.addSublayer(self.gradientLayer)

        self.gestureView.addSubview(self.iconView)
        self.iconView.image = Resources.recordIcon
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
        self.gradientLayer.colors = layerColors
    }

    private func resetKeyboardView() {
        self.removeFromSuperview()
    }

    private func stopAudioRecord() {
        RecordAudioGestureKeyboard.logger.info("stop audio record")

        self.tapMask.isHidden = true
        if self.readyToCancel {
            self.viewModel.cancelRecord()
        } else {
            self.viewModel.endRecord()
        }
        self.keyboardFocusBlock?(false)
    }

    private func startAudioRecord() {
        if !(gesture.state == .began || gesture.state == .changed) {
            RecordAudioGestureKeyboard.logger.info("gesture error!!! \(gesture.state)")
            isInvokeEnd = true
        }
        RecordAudioGestureKeyboard.logger.info("start audio record")

        self.readyToCancel = false
        self.tapMask.isHidden = false
        self.keyboardFocusBlock?(true)
        self.animationHelper.showFloatBarView(
            in: self,
            gestureView: gestureView,
            gesture: gesture,
            userResolver: userResolver
        )
        RecordAudioGestureKeyboard.logger.info("did start audio record")
        self.viewModel.startRecordAudio()
    }

    @objc
    private func handleGesture(sender: UILongPressGestureRecognizer) {
        RecordAudioGestureKeyboard.logger.info(
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

extension RecordAudioGestureKeyboard: AudioRecordViewModelDelegate {

    func audioRecordFinish(_ audioData: AudioDataInfo) {
        self.delegate?.recordAudioGestureKeyboardSendAudio(audioData: audioData)
        self.resetKeyboardView()
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
        self.delegate?.recordAudioGestureKeyboardRecordCancel()
        self.resetKeyboardView()
    }

    func audioRecordFinish(uploadID: String, duration: TimeInterval) {
        self.delegate?.recordAudioGestureKeyboardSendAudio(uploadID: uploadID, duration: duration)
        self.resetKeyboardView()
    }

    func audioRecordWillStart(uploadID: String) {
        self.delegate?.recordAudioGestureKeyboardRecordStart()
    }

    func audioRecordDidStart(uploadID: String) {
    }

    func audioRecordDidCancel(uploadID: String) {
        self.delegate?.recordAudioGestureKeyboardRecordCancel()
        self.resetKeyboardView()
        if isInvokeEnd, userResolver.fg.staticFeatureGatingValue(with: "messenger.old.audio.stop.record") {
            Self.logger.error("gesture error!!!")
            stopAudioRecord()
        }
    }

    func audioRecordDidTooShort(uploadID: String) {
        self.delegate?.recordAudioGestureKeyboardRecordCancel()
        self.resetKeyboardView()
        if let window = self.window {
            UDToast.showTips(with: BundleI18n.LarkAudio.Lark_Legacy_VoiceIndicatorTooShort, on: window)
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
}
