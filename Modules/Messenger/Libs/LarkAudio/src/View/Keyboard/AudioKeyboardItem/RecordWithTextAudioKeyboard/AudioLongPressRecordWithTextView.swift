//
//  AudioLongPressRecordWithTextView.swift
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
import RxSwift
import Reachability
import LarkContainer

protocol RecordAudioTextGestureKeyboardDelegate: AnyObject {
    func recordAudioTextGestureKeyboardStartRecognition(uploadID: String)
    func recordAudioTextGestureKeyboardState(isPrepare: Bool)
    func recordAudioTextGestureKeyboardRecordStart()
    /// 语音识别有结果返回
    func recordAudioTextGestureKeyboardRecordRecognizeHasResult()
    /// 语音录制结束
    func recordAudioTextGestureKeyboardRecordFinish()
    /// 语音识别流程结束，录音结束5秒后触发
    /// - Parameters:
    ///   - hasFinshed: 是否有尾包结果
    func recordAudioTextGestureKeyboardRecordRecognizeFinish(hasFinshed: Bool)
    func recordAudioTextGestureKeyboardTime(duration: TimeInterval)
    func recordAudioTextGestureKeyboardCleanInputView()
    func recordAudioTextGestureKeyboardSetupInfo(uploadID: String, audioData: Data, duration: TimeInterval)
    func audioGestureDecible(decible: Float)

    func audioGestureAddLongGestureView(view: UIView)
}

extension RecordAudioTextGestureKeyboardDelegate {
    func audioGestureAddLongGestureView(view: UIView) {}
}

final class RecognizeAudioTextGestureKeyboard: UIView, UserResolverWrapper {

    fileprivate static let logger = Logger.log(RecognizeAudioTextGestureKeyboard.self, category: "LarkAudio")

    var keyboardFocusBlock: ((Bool) -> Void)?

    let viewModel: AudioWithTextRecordViewModel

    @ScopedInjectedLazy var audioTracker: NewAudioTracker?
    private weak var delegate: RecordAudioTextGestureKeyboardDelegate?
    private var gesture: UILongPressGestureRecognizer

    private var recordLengthLimit: TimeInterval = 5 * 60
    private var audioCountDownView: AudioCountDownView?

    private var iconView: UIImageView = UIImageView()
    private var gestureView: UIView = UIView()
    private var voiceLayer: UIView = UIView()
    /// 语音识别是否返回尾包
    private var hasFinshed: Bool = false
    private var loadingTimer: Timer?
    private var isInvokeEnd: Bool = false
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

    /// if recognize failed, this value will change to true
    /// if this value is true, show alert when user finish record audio
    private var recognizeFailed: Bool = false
    private var currentUploadID: String
    private var disposeBag = DisposeBag()
    let userResolver: UserResolver
    init(userResolver: UserResolver, viewModel: AudioWithTextRecordViewModel, gesture: UILongPressGestureRecognizer, delegate: RecordAudioTextGestureKeyboardDelegate?) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        self.gesture = gesture
        self.delegate = delegate
        self.currentUploadID = viewModel.uploadID
        super.init(frame: .zero)
        self.gradientLayer.type = .radial
        self.gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        self.gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        viewModel.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        endTimer()
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

        self.voiceLayer.backgroundColor = UIColor.ud.colorfulBlue.withAlphaComponent(0.1)

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
        self.iconView.image = Resources.new_record_andText_icon
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
        self.gradientLayer.colors = [UDColor.primaryPri400.cgColor, UDColor.primaryContentDefault.cgColor]
    }

    private func resetKeyboardView() {
        self.isHidden = true
    }

    private func stopAudioRecord() {
        RecognizeAudioTextGestureKeyboard.logger.info("stop audio record")
        self.tapMask.isHidden = true
        self.viewModel.endRecord()
        self.keyboardFocusBlock?(false)
        self.resetKeyboardView()

        if self.recognizeFailed {
            self.recognizeFailed = false
            RecognizeAudioTextGestureKeyboard.logger.info("show recognize failed")
            AudioTracker.audioConvertServerError(type: .audioAndText)

            if !viewModel.netErrorOptimizeEnabled {
                if let window = self.window {
                    DispatchQueue.main.async {
                        let alertController = LarkAlertController()
                        alertController.setTitle(text: BundleI18n.LarkAudio.Lark_Chat_AudioConvertedFailedSendAudioAndText)
                        alertController.addPrimaryButton(text: BundleI18n.LarkAudio.Lark_Legacy_Sure)
                        self.userResolver.navigator.present(alertController, from: window)
                    }
                }
            }
        }
    }

    private func startAudioRecord() {
        if !(gesture.state == .began || gesture.state == .changed) {
            Self.logger.info("gesture error!!! \(gesture.state)")
            isInvokeEnd = true
        }
        RecognizeAudioTextGestureKeyboard.logger.info("start audio record")
        if viewModel.netErrorOptimizeEnabled {
            registerNetErrorMonitor()
            endTimer()
        }

        self.hasFinshed = false
        self.tapMask.isHidden = false
        self.keyboardFocusBlock?(true)
        self.recognizeFailed = false
        RecognizeAudioTextGestureKeyboard.logger.info("did start audio record")
        self.viewModel.startRecognition(language: RecognizeLanguageManager.shared.recognitionLanguage)
    }

    @objc
    private func handleGesture(sender: UILongPressGestureRecognizer) {
        RecognizeAudioTextGestureKeyboard.logger.info(
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

    fileprivate func resetCountDownView() {
        self.audioCountDownView?.removeFromSuperview()
        self.audioCountDownView = nil
    }

    /// 语音开始检测时，建立监听
    /// - 有内容，发送按钮可点击
    /// - 有尾包，消失loading
    private func registerNetErrorMonitor() {
        self.disposeBag = DisposeBag()
        // 监听是否有内容，有内容，发送按钮可点击
        viewModel.hasResult
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                self.delegate?.recordAudioTextGestureKeyboardRecordRecognizeHasResult()
            }).disposed(by: self.disposeBag)

        // 监听尾包，尾包回来，消失loading
        viewModel.hasFinshed
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                self.hasFinshed = true
                self.removeFromSuperview()
                self.delegate?.recordAudioTextGestureKeyboardRecordRecognizeFinish(hasFinshed: true)
            }).disposed(by: self.disposeBag)
    }

    private func startTime() {
        endTimer()
        loadingTimer = Timer.scheduledTimer(withTimeInterval: 5,
                                            repeats: false,
                                            block: { [weak self] _ in
                                                guard let self = self, !self.hasFinshed else { return }
                                                DispatchQueue.main.async {
                                                    self.delegate?.recordAudioTextGestureKeyboardRecordRecognizeFinish(hasFinshed: false)
                                                    self.removeFromSuperview()
                                                }
                                            })
    }

    func endTimer() {
        loadingTimer?.invalidate()
        loadingTimer = nil
    }

    private func checkNetworkConnection() -> Bool {
        guard let reach = Reachability() else { return false }
        if reach.connection == .none {
            Self.logger.info("network connection is none")
            return false
        }
        return true
    }

    private func resolveStartNetErrorStatus() {
        startTime()
    }
}

extension RecognizeAudioTextGestureKeyboard: AudioWithTextRecordViewModelDelegate {

    func audioRecordError(uploadID: String, error: Error) {
        recognizeFailed = true
        resetCountDownView()
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
        self.delegate?.recordAudioTextGestureKeyboardRecordFinish()
        self.resetKeyboardView()
        self.delegate?.recordAudioTextGestureKeyboardCleanInputView()
    }

    func audioRecordFinish(uploadID: String, audioData: Data, duration: TimeInterval) {
        self.delegate?.recordAudioTextGestureKeyboardSetupInfo(
            uploadID: uploadID,
            audioData: audioData,
            duration: duration
        )
        self.delegate?.recordAudioTextGestureKeyboardRecordFinish()
        resetCountDownView()
        if viewModel.netErrorOptimizeEnabled {
            resolveStartNetErrorStatus()
        }
        audioTracker?.asrRecordingStop(sessionId: uploadID)
    }

    func audioRecordWillStart(uploadID: String) {
        self.delegate?.recordAudioTextGestureKeyboardStartRecognition(uploadID: uploadID)
        self.delegate?.recordAudioTextGestureKeyboardRecordStart()
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
        self.delegate?.recordAudioTextGestureKeyboardRecordFinish()
        self.resetKeyboardView()
        self.delegate?.recordAudioTextGestureKeyboardCleanInputView()
        resetCountDownView()
        audioTracker?.asrRecordingStop(sessionId: uploadID)
    }

    func audioRecordDidTooShort(uploadID: String) {
        self.delegate?.recordAudioTextGestureKeyboardRecordFinish()
        self.resetKeyboardView()
        self.delegate?.recordAudioTextGestureKeyboardCleanInputView()
        if let window = self.window {
            UDToast.showTips(with: BundleI18n.LarkAudio.Lark_Legacy_VoiceIndicatorTooShort, on: window)
        }
    }

    func audioRecordUpdateRecordTime(time: TimeInterval) {
        self.delegate?.recordAudioTextGestureKeyboardTime(duration: time)

        if time >= self.recordLengthLimit {
            self.stopAudioRecord()
        } else if self.recordLengthLimit - time <= 10 {
            if self.audioCountDownView == nil {
                let countDownView = AudioCountDownView()
                self.audioCountDownView = countDownView
                if let topWindow = self.window {
                    topWindow.addSubview(countDownView)
                    countDownView.snp.makeConstraints { (maker) in
                        maker.width.height.equalTo(110)
                        maker.top.equalTo(105)
                        maker.centerX.equalTo(self)
                    }
                }
            }
            self.audioCountDownView?.updateCountDownTime(
                time: self.recordLengthLimit - time
            )
        }
    }

    func audioRecordUpdateRecordVoice(power: Float) {
        self.updateRecordPowerLayer(power: power, duration: 0.1)
    }

    func audioRecordUpdateState(state: AudioState) {
        var isPrepare: Bool
        switch state {
        case .prepare:
            isPrepare = true
        case .normal, .recording:
            isPrepare = false
        }
        self.delegate?.recordAudioTextGestureKeyboardState(isPrepare: isPrepare)
    }
}
