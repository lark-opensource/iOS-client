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
import UniverseDesignIcon
import LarkAIInfra

/// 语音转文字
final class NewRecognitionAudioKeyboard: UIView, AudioKeyboardItemViewDelegate, UserResolverWrapper {

    enum DisplayState {
        case idel // 未在录音，初始化状态
        case pressedRecording // 长按录音
        case unpressedRecording // 点按录音
        case end // 录音完成，展示按钮
    }

    var displayState: DisplayState = .idel {
        didSet {
            guard displayState == .idel || displayState != oldValue else { return }
            switch displayState {
            case .idel:
                self.cancelButton.isHidden = true
                self.sendButton.isHidden = true
                self.languageLabel.isHidden = false
                self.tipLabel.isHidden = false
                self.deleteView.isHidden = true
                iconView.image = UDIcon.voice2textOutlined.ud.withTintColor(UIColor.ud.staticWhite)
                gestureView.backgroundColor = UDColor.primaryContentDefault
                voiceLayer.isHidden = true
                self.gestureView.snp.remakeConstraints { (maker) in
                    maker.centerX.equalToSuperview()
                    maker.top.equalToSuperview().offset(59)
                    maker.width.height.equalTo(108)
                }
                voiceLayer.center = gestureView.center
                voiceLayer.bounds = .zero
                self.gestureView.layer.cornerRadius = 54
                self.gestureView.layoutIfNeeded()
                self.keyboardFocusBlock?(false)
            case .pressedRecording:
                self.cancelButton.isHidden = true
                self.sendButton.isHidden = true
                self.languageLabel.isHidden = true
                self.tipLabel.isHidden = true
                self.deleteView.isHidden = true
                iconView.image = UDIcon.voice2textOutlined.ud.withTintColor(UIColor.ud.staticWhite)
                gestureView.backgroundColor = UDColor.primaryContentDefault
                voiceLayer.isHidden = false
                self.gestureView.snp.remakeConstraints { (maker) in
                    maker.centerX.equalToSuperview()
                    maker.top.equalToSuperview().offset(59)
                    maker.width.height.equalTo(108)
                }
                voiceLayer.center = gestureView.center
                voiceLayer.bounds = .zero
                self.gestureView.layer.cornerRadius = 54
                self.layoutIfNeeded()
                self.keyboardFocusBlock?(true)
            case .unpressedRecording:
                self.cancelButton.isHidden = true
                self.sendButton.isHidden = true
                self.languageLabel.isHidden = true
                self.tipLabel.isHidden = true
                self.deleteView.isHidden = true
                iconView.image = UDIcon.pauseFilled.ud.withTintColor(UDColor.staticWhite)
                gestureView.backgroundColor = UDColor.primaryContentDefault
                voiceLayer.isHidden = false
                self.gestureView.snp.remakeConstraints { (maker) in
                    maker.centerX.equalToSuperview()
                    maker.top.equalToSuperview().offset(59)
                    maker.width.height.equalTo(108)
                }
                voiceLayer.center = gestureView.center
                voiceLayer.bounds = .zero
                self.gestureView.layer.cornerRadius = 54
                self.layoutIfNeeded()
                self.keyboardFocusBlock?(true)
            case .end:
                self.cancelButton.isHidden = false
                self.sendButton.isHidden = false
                self.languageLabel.isHidden = false
                self.tipLabel.isHidden = false
                self.deleteView.isHidden = false
                iconView.image = UDIcon.voice2textOutlined.ud.withTintColor(UIColor.ud.staticWhite)
                gestureView.backgroundColor = UDColor.primaryContentDefault
                voiceLayer.isHidden = true
                self.setButtomInCenter()
                self.layoutIfNeeded()
                self.gestureView.snp.remakeConstraints { (maker) in
                    maker.centerX.equalToSuperview()
                    maker.top.equalToSuperview().offset(59)
                    maker.width.height.equalTo(88)
                }
                voiceLayer.center = gestureView.center
                voiceLayer.bounds = .zero
                self.setButtonAverage()
                UIView.animate(withDuration: 0.25) {
                    // 如果动画过程中已经 reset UI，则不再改变 cornerRadius
                    if !self.sendButton.isHidden {
                        self.layoutIfNeeded()
                        self.gestureView.layer.cornerRadius = 44
                    }
                }
            }
        }
    }

    @ScopedInjectedLazy var byteViewService: AudioDependency?
    @ScopedInjectedLazy var audioTracker: NewAudioTracker?

    var keyboardFocusBlock: ((Bool) -> Void)?
    var recognitionType: RecognizeLanguageManager.RecognizeType { return .text }
    var keyboardView: UIView { self }
    var isNetConnected: Bool = true
    let viewModel: NewAudioRecognizeViewModel
    let title: String = BundleI18n.LarkAudio.Lark_Chat_AudioToText

    var macInputStyle: Bool = false
    fileprivate static let logger = Logger.log(NewRecognitionAudioKeyboard.self, category: "LarkAudio")
    private weak var delegate: RecognitionAudioKeyboardDelegate?

    private var longGesture: UILongPressGestureRecognizer = UILongPressGestureRecognizer()
    private var tapGesture: UITapGestureRecognizer = UITapGestureRecognizer()
    private var gesturesTapGesture: UITapGestureRecognizer = UITapGestureRecognizer()

    private var iconView: UIImageView = UIImageView()
    private var gestureView: UIView = UIView()
    private var voiceLayer: UIView = UIView()
    private lazy var cancelButton: AudioKeyboardInteractiveButton = AudioKeyboardInteractiveButton(type: .cancel, userResolver: userResolver)
    private lazy var sendButton: AudioKeyboardInteractiveButton = AudioKeyboardInteractiveButton(type: .sendAll, userResolver: userResolver, customText: BundleI18n.LarkAudio.Lark_Legacy_Send)
    private lazy var languageLabel: AudioLanguageLabel = AudioLanguageLabel(userResolver: userResolver, type: .textOnly)
    private let deleteView = UIView()
    private let tipLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.LarkAudio.Lark_IM_AudioMsg_TapHoldToRecord_Text
        label.textColor = UDColor.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    private let windowMask: UIView = {
        let view = UIView()
        view.backgroundColor = .black.withAlphaComponent(0.1)
        return view
    }()
    private var sessionId: String = ""
    // true: 单击开启录音中。false: 长按开启录音中。nil:未录音中
    private var isTapStart: Bool?
    // 长按手势开始后会调用trylock后才开始录音，这时手指离开会立即调用stop，此时lock完成后录音启动且无法终止
    // 在trylock前将属性设置为 false，真正启动后会回调 didStart方法，如果在此期间调用过 stop，则立即停止录音
    private var isInvokeEnd: Bool = false
    /// 用于动画快速定位用
    private var leftView: UIView = UIView()
    /// 用于动画快速定位用
    private var rightView: UIView = UIView()

    let userResolver: UserResolver

    init(userResolver: UserResolver,
         viewModel: NewAudioRecognizeViewModel,
         delegate: RecognitionAudioKeyboardDelegate?) {
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
        self.addSubview(languageLabel)
        self.addSubview(tipLabel)

        let leftWrapperView = UIView()
        let rightWrapperView = UIView()
        self.addSubview(leftWrapperView)
        self.addSubview(rightWrapperView)
        self.addSubview(self.leftView)
        self.addSubview(self.rightView)
        self.addSubview(self.cancelButton)
        self.addSubview(self.sendButton)
        self.addSubview(self.deleteView)

        cancelButton.setHandler(clickCancelBtn)
        sendButton.setHandler(clickSendBtn)

        self.voiceLayer.backgroundColor = UDColor.colorfulBlue.withAlphaComponent(0.1)
        self.addSubview(self.voiceLayer)

        self.addSubview(self.gestureView)
        self.gestureView.layer.cornerRadius = 54
        self.gestureView.layer.masksToBounds = true
        self.gestureView.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview().offset(59)
            maker.width.height.equalTo(108)
        }
        languageLabel.updateLabelAndIcon(labelFont: 14, labelColor: UIColor.ud.textCaption)
        languageLabel.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().offset(195)
            maker.centerX.equalToSuperview()
        }
        tipLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(gestureView.snp.top).offset(-12)
        }
        let deleteTapGesture: UITapGestureRecognizer = UITapGestureRecognizer()
        deleteView.addGestureRecognizer(deleteTapGesture)
        deleteTapGesture.addTarget(self, action: #selector(deleteBackward))
        deleteView.snp.makeConstraints { make in
            make.centerY.equalTo(languageLabel)
            make.width.height.equalTo(32)
            make.right.equalToSuperview().offset(-20)
        }
        let deleteImageView = UIImageView(image: UDIcon.deleteOutlined.ud.withTintColor(UIColor.ud.iconN2))
        deleteView.addSubview(deleteImageView)
        deleteImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(22)
        }

        self.gestureView.addSubview(self.iconView)
        self.iconView.image = Resources.recognitionIcon
        self.iconView.snp.makeConstraints { (maker) in
            maker.center.equalToSuperview()
            maker.width.height.equalTo(28)
        }

        self.longGesture.minimumPressDuration = 0.3
        self.gestureView.addGestureRecognizer(longGesture)
        self.longGesture.addTarget(self, action: #selector(longHandleGesture(sender:)))
        self.gestureView.addGestureRecognizer(gesturesTapGesture)
        self.gesturesTapGesture.addTarget(self, action: #selector(tapHandleGesture))
        self.windowMask.addGestureRecognizer(tapGesture)
        self.tapGesture.addTarget(self, action: #selector(tapHandleGesture))

        leftWrapperView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalTo(gestureView.snp.left)
            make.centerY.height.equalTo(gestureView)
        }
        rightWrapperView.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.left.equalTo(gestureView.snp.right)
            make.centerY.height.equalTo(gestureView)
        }

        self.leftView.snp.remakeConstraints { (maker) in
            maker.width.equalTo(110)
            maker.height.greaterThanOrEqualTo(54)
            maker.center.equalTo(leftWrapperView)
        }

        self.rightView.snp.remakeConstraints { (maker) in
            maker.width.equalTo(110)
            maker.height.greaterThanOrEqualTo(54)
            maker.center.equalTo(rightWrapperView)
        }

        // app挂起
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)

        self.resetKeyboardView()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        delegate?.handleCaretView(show: self.window != nil)
    }

    @objc
    func applicationWillResignActive() {
        if viewModel.isRecording {
            stopAudioRecognition()
        }
    }

    @objc
    func deleteBackward() {
        delegate?.deleteBackward()
    }

    func resetKeyboardView() {
        NewRecognitionAudioKeyboard.logger.info("reset keyboard view")
        displayState = .idel
    }

    private func stopAudioRecognition() {
        NewRecognitionAudioKeyboard.logger.info("stop audio recognition")
        guard isNetConnected else {
            self.resetKeyboardView()
            return
        }
        displayState = .end
        self.viewModel.endRecord()
    }

    private func startAudioRecognition() {
        NewRecognitionAudioKeyboard.logger.info("start audio recognition")

        if isTapStart == true {
            displayState = .unpressedRecording
        } else {
            displayState = .pressedRecording
        }

        NewRecognitionAudioKeyboard.logger.info("did start audio recognition")
        self.viewModel.startRecognition(language: RecognizeLanguageManager.shared.recognitionLanguage)
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
    private func tapHandleGesture() {
        if viewModel.isRecording {
            self.stopAudioRecognition()
        } else {
            let resetBlock = { [weak self] in
                /// 强制结束手势
                self?.tapGesture.isEnabled = false
                self?.tapGesture.isEnabled = true
                self?.resetKeyboardView()
            }
            if checkNetworkConnection() &&
                checkCallingState() &&
                checkByteViewState() {
                isInvokeEnd = false
                AudioMediaLockManager.shared.tryLock(userResolver: userResolver, from: self.window, callback: { [weak self] result in
                    if result {
                        self?.isTapStart = true
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
        }
    }

    @objc
    private func longHandleGesture(sender: UILongPressGestureRecognizer) {
        NewRecognitionAudioKeyboard.logger.info(
            "gesture state change",
            additionalData: ["state": AudioTracker.stateDescription(sender.state)])
        switch sender.state {
        case .began:
            let resetBlock = { [weak self] in
                /// 强制结束手势
                self?.longGesture.isEnabled = false
                self?.longGesture.isEnabled = true
                self?.resetKeyboardView()
            }

            if checkNetworkConnection() &&
                checkCallingState() &&
                checkByteViewState() {
                isInvokeEnd = false
                AudioMediaLockManager.shared.tryLock(userResolver: userResolver, from: self.window, callback: { [weak self] result in
                    if result {
                        self?.isTapStart = false
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
            NewRecognitionAudioKeyboard.logger.info("network connection is none")
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
            NewRecognitionAudioKeyboard.logger.info("user is calling")
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
        return min(120 + max(0, (CGFloat(power) - 40) / (65 - 40) * 120), 226)
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

extension NewRecognitionAudioKeyboard: AudioRecognizeViewModelDelegate {
    func audioRecordError(uploadID: String, error: Error) {
        self.sessionId = ""
        // 强制结束手势
        self.longGesture.isEnabled = false
        self.longGesture.isEnabled = true
        self.tapGesture.isEnabled = false
        self.tapGesture.isEnabled = true

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

        windowMask.removeFromSuperview()
        isTapStart = nil
    }

    func audioRecordStartFailed(uploadID: String) {
        // 强制结束手势
        self.longGesture.isEnabled = false
        self.longGesture.isEnabled = true
        self.tapGesture.isEnabled = false
        self.tapGesture.isEnabled = true

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

        windowMask.removeFromSuperview()
        isTapStart = nil
    }

    func audioRecordFinish(uploadID: String) {
        self.sessionId = ""
        self.delegate?.recognitionAudioKeyboardRecordFinish()
        audioTracker?.asrRecordingStop(sessionId: uploadID)

        windowMask.removeFromSuperview()
        isTapStart = nil
        displayState = .end
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow == nil {
            stopAudioRecognition()
        }
    }

    func audioRecordWillStart(uploadID: String) {
        self.sessionId = uploadID
        self.delegate?.recognitionAudioKeyboardStartRecognition(uploadID: uploadID)
        self.delegate?.recognitionAudioKeyboardRecordStart()
        audioTracker?.asrUserTouchButton(sessionId: uploadID)
        if let window = self.window, isTapStart == true {
            window.addSubview(windowMask)
            windowMask.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
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
        windowMask.removeFromSuperview()
        isTapStart = nil
        displayState = .end
    }

    func audioRecordDidTooShort(uploadID: String) {
        self.sessionId = ""
        self.delegate?.recognitionAudioKeyboardRecordFinish()
        windowMask.removeFromSuperview()
        isTapStart = nil
        displayState = .end
    }

    func audioRecordUpdateRecordTime(time: TimeInterval) { }

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
