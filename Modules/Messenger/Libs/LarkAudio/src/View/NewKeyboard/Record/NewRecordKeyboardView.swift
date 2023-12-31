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
import UniverseDesignIcon

final class NewRecordAudioKeyboard: UIView, AudioKeyboardItemViewDelegate, UserResolverWrapper {

    fileprivate static let logger = Logger.log(NewRecordAudioKeyboard.self, category: "LarkAudio")

    var keyboardFocusBlock: ((Bool) -> Void)?

    let title: String = BundleI18n.LarkAudio.Lark_Chat_RecordAudio
    var recognitionType: RecognizeLanguageManager.RecognizeType { return .audio }

    var keyboardView: UIView { self }

    let viewModel: NewRecordViewModel
    private weak var delegate: RecordAudioKeyboardDelegate?

    fileprivate var recordLengthLimit: TimeInterval = 5 * 60
    // 注释在语音转文字面板的里，相同的属性名称下
    private var isInvokeEnd: Bool = false
    private var gesture: UILongPressGestureRecognizer = UILongPressGestureRecognizer()
    private var tipLabel = UILabel()
    private var iconView: UIImageView = UIImageView()
    private var gestureView: UIView = UIView()

    fileprivate var readyToCancel: Bool = false

    var displayState: RecordAnimationView.DisplayState = .unpressed {
        didSet {
            switch displayState {
            case .unpressed:
                readyToCancel = false
                self.gestureView.backgroundColor = UDColor.primaryContentDefault
                self.iconView.image = UDIcon.micOutlined.ud.withTintColor(UIColor.ud.staticWhite)
            case .pressing:
                readyToCancel = false
                self.gestureView.backgroundColor = UDColor.functionInfoContentPressed
                self.iconView.image = UDIcon.micOutlined.ud.withTintColor(UIColor.ud.staticWhite)
            case .cancel:
                readyToCancel = true
                self.gestureView.backgroundColor = UDColor.bgBody
                self.iconView.image = UDIcon.micOutlined.ud.withTintColor(UIColor.ud.functionInfoContentDefault)
            }
        }
    }

    @ScopedInjectedLazy var byteViewService: AudioDependency?
    let userResolver: UserResolver
    init(userResolver: UserResolver, viewModel: NewRecordViewModel, delegate: RecordAudioKeyboardDelegate?) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        self.delegate = delegate
        super.init(frame: .zero)
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
        self.tipLabel.text = BundleI18n.LarkAudio.Lark_Chat_AudioToTextTips
        self.addSubview(self.tipLabel)
        self.addSubview(self.gestureView)
        tipLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(gestureView.snp.top).offset(-12)
        }
        self.gestureView.layer.cornerRadius = 54
        self.gestureView.layer.masksToBounds = true
        self.gestureView.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview().offset(59)
            maker.width.height.equalTo(108)
        }
        self.gestureView.backgroundColor = UDColor.primaryContentDefault
        self.iconView.image = UDIcon.micOutlined.ud.withTintColor(UIColor.ud.staticWhite)
        self.gestureView.addSubview(self.iconView)
        self.iconView.snp.makeConstraints { (maker) in
            maker.center.equalToSuperview()
            maker.width.height.equalTo(32)
        }

        self.gesture.minimumPressDuration = 0.1
        self.gestureView.addGestureRecognizer(gesture)
        self.gesture.addTarget(self, action: #selector(handleGesture(sender:)))

        self.resetKeyboardView()
    }

    func resetKeyboardView() {
        NewRecordAudioKeyboard.logger.info("reset keyboard view")
        displayState = .unpressed
    }

    private func stopAudioRecord() {
        NewRecordAudioKeyboard.logger.info("stop audio record")
        if self.readyToCancel {
            self.viewModel.cancelRecord()
        } else {
            self.viewModel.endRecord()
        }
        self.keyboardFocusBlock?(false)
        self.resetKeyboardView()
    }

    private func startAudioRecord() {
        NewRecordAudioKeyboard.logger.info("start audio record")
        displayState = .pressing
        self.keyboardFocusBlock?(true)
        self.viewModel.startRecordAudio()
    }

    @objc
    private func handleGesture(sender: UILongPressGestureRecognizer) {
        NewRecordAudioKeyboard.logger.info(
            "gesture state change",
            additionalData: ["state": AudioTracker.stateDescription(sender.state)]
        )
        switch sender.state {
        case .began:
            let resetBlock = { [weak self] in
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
        let point = gesture.location(in: gestureView)
        delegate?.updatePoint(point: point)
        self.displayState = delegate?.animationDisplayState ?? .unpressed
    }
}

extension NewRecordAudioKeyboard: AudioRecordViewModelDelegate {
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

        if time >= self.recordLengthLimit {
            self.stopAudioRecord()
        } else if recordLengthLimit - time <= 10 {
            delegate?.updateRecordTime(str: BundleI18n.LarkAudio.Lark_IM_AudioMsg_RecordingEndsInNums_Text(Int(recordLengthLimit - time)))
        } else {
            delegate?.updateRecordTime(str: NewAudioKeyboardHelper.timeString(time: time))
        }
    }

    func audioRecordUpdateRecordVoice(power: Float) {
        delegate?.updateDecible(decible: power)
    }

    func audioRecordUpdateState(state: AudioState) { }

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
            NewRecordAudioKeyboard.logger.info("user is calling")
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
