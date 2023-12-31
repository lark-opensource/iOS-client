//
//  NewRecordWithTextAudioKeyboard.swift
//  LarkAudio
//
//  Created by 白镜吾 on 2023/2/16.
//

import UIKit
import Foundation
import LarkLocalizations
import LarkActionSheet
import EENavigator
import Reachability
import UniverseDesignToast
import UniverseDesignColor
import RxSwift
import LarkAlertController
import LKCommonsLogging
import LarkAudioKit
import AVFoundation
import CoreTelephony
import LarkMessengerInterface
import LarkContainer
import LarkMedia

/// 语音加文字
final class NewRecordWithTextAudioKeyboard: UIView, AudioKeyboardItemViewDelegate, UserResolverWrapper {

    fileprivate static let logger = Logger.log(NewRecordWithTextAudioKeyboard.self, category: "LarkAudio")

    private var recordLengthLimit: TimeInterval = 5 * 60
    private var audioCountDownView: AudioCountDownView?

    @ScopedInjectedLazy var byteViewService: AudioDependency?
    @ScopedInjectedLazy var audioTracker: NewAudioTracker?

    var keyboardFocusBlock: ((Bool) -> Void)?

    let tipText: String = BundleI18n.LarkAudio.Lark_Chat_AudioToTextTips
    let tipLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.LarkAudio.Lark_Chat_AudioToTextTips
        label.textColor = UDColor.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    let title: String = BundleI18n.LarkAudio.Lark_Chat_SendAudioWithText
    var recognitionType: RecognizeLanguageManager.RecognizeType { return .audioWithText }
    var keyboardView: UIView { self }
    let viewModel: NewAudioWithTextRecordViewModel
    /// 录制完成后，viewModel.uploadID = ""，我们需要在开始录制时记录uploadID，后续用户点"清空"按钮时需要使用
    private var currentUploadID: String = ""

    private weak var delegate: RecordWithTextAudioKeyboardDelegate?

    private var gesture: UILongPressGestureRecognizer = UILongPressGestureRecognizer()

    private lazy var languageLabel = AudioLanguageLabel(userResolver: userResolver, type: .audioAndText)

    private var iconView: UIImageView = UIImageView()
    private var gestureView: UIView = UIView()

    private var actionButton: RecordWithTextActionViewWithLID
    // 注释在语音转文字面板的里，相同的属性名称下
    private var isInvokeEnd: Bool = false
    private lazy var tipView: RecordWithTextTipView = {
        var tipView = RecordWithTextTipView()
        tipView.isHidden = true
        return tipView
    }()
    // var macInputStyle: Bool = false

    /// if recognize failed, this value will change to true
    /// if this value is true, show alert when user finish record audio
    private var recognizeFailed: Bool = false
    /// 语音识别是否返回尾包
    private var hasFinshed: Bool = false
    private var loadingTimer: Timer?
    private let loadingView: LoadingView = {
        let loadingView = LoadingView(frame: .zero)
        loadingView.backgroundColor = UIColor.ud.bgBodyOverlay
        loadingView.fillColor = UIColor.clear
        loadingView.strokeColor = UIColor.ud.colorfulBlue
        loadingView.radius = 10
        return loadingView
    }()

    private let textLoadingView: LoadingView = {
        let loadingView = LoadingView(frame: .zero)
        loadingView.backgroundColor = UIColor.ud.bgBodyOverlay
        loadingView.fillColor = UIColor.clear
        loadingView.strokeColor = UIColor.ud.iconN1
        loadingView.radius = 10
        return loadingView
    }()

    private var disposeBag = DisposeBag()

    let userResolver: UserResolver
    init(userResolver: UserResolver,
         viewModel: NewAudioWithTextRecordViewModel,
         delegate: RecordWithTextAudioKeyboardDelegate?) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        self.delegate = delegate
        actionButton = RecordWithTextActionViewWithLID(userResolver: userResolver)
        super.init(frame: .zero)
        viewModel.delegate = self
        self.setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        endTimer()
    }

    private func setupViews() {
        self.backgroundColor = UIColor.ud.bgBodyOverlay
        self.addSubview(languageLabel)
        self.addSubview(tipLabel)

        gestureView.backgroundColor = UDColor.primaryContentDefault
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
            maker.top.equalTo(gestureView.snp.bottom).offset(28)
            maker.centerX.equalToSuperview()
        }
        tipLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(gestureView.snp.top).offset(-12)
        }

        self.gestureView.addSubview(self.iconView)
        self.iconView.image = Resources.record_with_Text_icon
        self.iconView.snp.makeConstraints { (maker) in
            maker.center.equalToSuperview()
            maker.width.height.equalTo(32)
        }

        self.gesture.minimumPressDuration = 0.1
        self.gestureView.addGestureRecognizer(gesture)
        self.gesture.addTarget(self, action: #selector(handleGesture(sender:)))

        self.addSubview(self.actionButton)
        (self.actionButton.cancelButton as? AudioKeyboardInteractiveButton)?.setHandler(clickCancelBtn)
        (self.actionButton.sendAudioButton as? AudioKeyboardInteractiveButton)?.setHandler(clickOnlySendAudioBtn)
        (self.actionButton.sendAllButton as? AudioKeyboardInteractiveButton)?.setHandler(clickSendBtn)
        (self.actionButton.sendTextButton as? AudioKeyboardInteractiveButton)?.setHandler(clickOnlySendTextBtn)
        self.actionButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(self.actionButton.getActionViewActualHeight())
            make.bottom.equalToSuperview().offset(-80)
        }

        if viewModel.netErrorOptimizeEnabled {
            addSubview(tipView)
            tipView.snp.makeConstraints { (make) in
                make.top.equalToSuperview().inset(16)
                make.height.equalTo(18)
                make.centerX.equalToSuperview()
                make.width.lessThanOrEqualToSuperview()
            }
        }

        self.resetKeyboardView()
    }

    func resetKeyboardView() {
        NewRecordWithTextAudioKeyboard.logger.info("reset keyboard view")
        self.gestureView.isHidden = false
        self.tipLabel.isHidden = false
        self.actionButton.isHidden = true
        self.languageLabel.isHidden = false
        gestureView.backgroundColor = UDColor.primaryContentDefault
        if viewModel.netErrorOptimizeEnabled {
            self.tipView.isHidden = true
        }
        self.keyboardFocusBlock?(false)
        endTimer()
    }

    private func stopAudioRecognition() {
        NewRecordWithTextAudioKeyboard.logger.info("stop audio recognition")
        if !self.viewModel.isRecording { return }
        self.viewModel.endRecord()

        if self.recognizeFailed {
            self.recognizeFailed = false
            NewRecordWithTextAudioKeyboard.logger.info("show recognize failed")
            AudioTracker.audioConvertServerError(type: .audioAndText)

            if let window = self.window {
                if  !viewModel.netErrorOptimizeEnabled {
                    DispatchQueue.main.async {
                        let alertController = LarkAlertController()
                        alertController.setTitle(text: BundleI18n.LarkAudio.Lark_Chat_AudioConvertedFailedSendAudioAndText)
                        alertController.addPrimaryButton(text: BundleI18n.LarkAudio.Lark_Legacy_Sure)
                        self.userResolver.navigator.present(alertController, from: window)
                    }
                }
            } else {
                assertionFailure("Lost From Window")
            }
        }
    }

    private func showActionButtons() {
        NewRecordWithTextAudioKeyboard.logger.info("show action buttons")
        self.gestureView.isHidden = true
        self.tipLabel.isHidden = true
        self.actionButton.isHidden = false

        self.actionButton.setButtomInCenter()
        self.layoutIfNeeded()
        self.actionButton.setButtonAverage()

        UIView.animate(withDuration: 0.25) {
            self.layoutIfNeeded()
        }
    }

    private func startAudioRecognition() {
        NewRecordWithTextAudioKeyboard.logger.info("start audio recognition")
        AudioTracker.touchAudioWithText(from: .audioMenu)

        if viewModel.netErrorOptimizeEnabled {
            self.actionButton.sendAllButton.isEnabled = false
            self.actionButton.sendTextButton.isEnabled = false
            registerNetErrorMonitor()
            endTimer()
        }
        self.hasFinshed = false
        self.gestureView.isHidden = false
        self.tipLabel.isHidden = true
        gestureView.backgroundColor = UDColor.functionInfoContentPressed
        self.actionButton.isHidden = true
        self.languageLabel.isHidden = true
        self.keyboardFocusBlock?(true)
        self.recognizeFailed = false
        NewRecordWithTextAudioKeyboard.logger.info("did start audio recognition")
        self.viewModel.startRecognition(language: RecognizeLanguageManager.shared.recognitionLanguage)
    }

    @objc
    private func handleGesture(sender: UILongPressGestureRecognizer) {
        NewRecordWithTextAudioKeyboard.logger.info(
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
            var canStartAudioRecognition = false
            if viewModel.netErrorOptimizeEnabled {
                canStartAudioRecognition = checkCallingState() &&
                checkByteViewState()
            } else {
                canStartAudioRecognition = checkNetworkConnection() &&
                checkCallingState() &&
                checkByteViewState()
            }
            if canStartAudioRecognition {
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

            AudioTracker.imChatVoiceMsgClick(click: .holdToTalk, viewType: .audioWithText)
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
            NewRecordWithTextAudioKeyboard.logger.info("network connection is none")

            let alertController = LarkAlertController()
            alertController.setTitle(text: BundleI18n.LarkAudio.Lark_Chat_AudioToTextNetworkError)
            alertController.addPrimaryButton(text: BundleI18n.LarkAudio.Lark_Legacy_Sure)
            userResolver.navigator.present(alertController, from: window)
            return false
        }
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
            NewRecordWithTextAudioKeyboard.logger.info("user is calling")
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
        self.resetKeyboardView()
        self.delegate?.recordWithTextAudioKeyboardCleanAllText(uploadID: self.currentUploadID)
        self.delegate?.recordWithTextAudioKeyboardCleanInputView()
        AudioTracker.imChatVoiceMsgClick(click: .empty, viewType: .audioWithText)
    }

    @objc
    private func clickSendBtn() {
        self.resetKeyboardView()
        self.delegate?.recordWithTextAudioKeyboardSendAudioAndText(uploadID: viewModel.uploadID)
        self.delegate?.recordWithTextAudioKeyboardCleanInputView()
        AudioTracker.imChatVoiceMsgClick(click: .send, viewType: .audioWithText)
    }

    @objc
    private func clickOnlySendAudioBtn() {
        self.resetKeyboardView()
        self.delegate?.recordWithTextAudioKeyboardSendAudio(uploadID: viewModel.uploadID)
        self.delegate?.recordWithTextAudioKeyboardCleanInputView()
        AudioTracker.imChatVoiceMsgClick(click: .onlyVoice, viewType: .audioWithText)
    }

    @objc
    private func clickOnlySendTextBtn() {
        self.resetKeyboardView()
        self.delegate?.recordWithTextAudioKeyboardSendText()
        self.delegate?.recordWithTextAudioKeyboardCleanInputView()
        AudioTracker.imChatVoiceMsgClick(click: .onlyText, viewType: .audioWithText)
    }

    fileprivate func resetCountDownView() {
        self.audioCountDownView?.removeFromSuperview()
        self.audioCountDownView = nil
    }

    /// 根据语音识别的结果展示提示，如果5秒之后：
    /// - 还没有返回尾包，则展示只发语音的提示
    /// - 收到尾包，则不作任何操作，收到尾包的时候做了相应操作
    private func resolveStartNetErrorStatus() {
        self.actionButton.sendAllButton.isEnabled = false
        self.actionButton.sendAllButton.addSubview(loadingView)
        self.actionButton.sendTextButton.isEnabled = false
        self.actionButton.sendTextButton.addSubview(textLoadingView)
        loadingView.snp.makeConstraints { make in
            make.size.equalTo(24)
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        textLoadingView.snp.makeConstraints { make in
            make.size.equalTo(24)
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        startTime()
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
                self.actionButton.sendAllButton.isEnabled = true
                self.actionButton.sendTextButton.isEnabled = true
            }).disposed(by: self.disposeBag)

        // 监听尾包，尾包回来，消失loading
        viewModel.hasFinshed
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                self.loadingView.removeFromSuperview()
                self.textLoadingView.removeFromSuperview()
                self.tipView.isHidden = true
                self.hasFinshed = true
                self.delegate?.recordWithTextAudioKeyboardRecordRecognizeFinish(hasFinshed: true)
            }).disposed(by: self.disposeBag)
    }

    private func startTime() {
        endTimer()
        loadingTimer = Timer.scheduledTimer(withTimeInterval: 5,
                                            repeats: false,
                                            block: { [weak self] _ in
            guard let self = self, !self.hasFinshed else { return }
            DispatchQueue.main.async {
                self.loadingView.removeFromSuperview()
                self.textLoadingView.removeFromSuperview()
                self.tipView.isHidden = false
                self.delegate?.recordWithTextAudioKeyboardRecordRecognizeFinish(hasFinshed: false)
            }
        })
    }

    private func endTimer() {
        loadingTimer?.invalidate()
        loadingTimer = nil
    }

}

extension NewRecordWithTextAudioKeyboard: AudioWithTextRecordViewModelDelegate {

    func audioRecordError(uploadID: String, error: Error) {
        recognizeFailed = true
        self.resetCountDownView()
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
        self.delegate?.recordWithTextAudioKeyboardRecordFinish()
        self.resetKeyboardView()
        self.delegate?.recordWithTextAudioKeyboardCleanInputView()
    }

    func audioRecordFinish(uploadID: String, audioData: Data, duration: TimeInterval) {
        audioTracker?.asrRecordingStop(sessionId: uploadID)
        self.delegate?.recordWithTextAudioKeyboardRecordFinish()
        self.showActionButtons()
        self.resetCountDownView()
        if viewModel.netErrorOptimizeEnabled {
            self.resolveStartNetErrorStatus()
        }
        self.delegate?.recordWithTextAudioKeyboardSetupInfo(
            uploadID: uploadID,
            audioData: audioData,
            duration: duration
        )
    }

    func audioRecordWillStart(uploadID: String) {
        self.delegate?.recordWithTextAudioKeyboardStartRecognition(uploadID: uploadID)
        self.delegate?.recordWithTextAudioKeyboardRecordStart()
        self.currentUploadID = uploadID
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
        self.delegate?.recordWithTextAudioKeyboardRecordFinish()
        self.resetKeyboardView()
        self.resetCountDownView()
        self.delegate?.recordWithTextAudioKeyboardCleanInputView()
        audioTracker?.asrRecordingStop(sessionId: uploadID)
    }

    func audioRecordDidTooShort(uploadID: String) {
        self.delegate?.recordWithTextAudioKeyboardRecordFinish()
        self.resetKeyboardView()
        self.delegate?.recordWithTextAudioKeyboardCleanInputView()
        if let window = self.window {
            UDToast.showTipsOnScreenCenter(with: BundleI18n.LarkAudio.Lark_Legacy_VoiceIndicatorTooShort, on: window)
        }
    }

    func audioRecordUpdateRecordTime(time: TimeInterval) {
        self.delegate?.recordWithTextAudioKeyboardTime(duration: time)

        if time >= self.recordLengthLimit {
            self.stopAudioRecognition()
        } else if self.recordLengthLimit - time <= 10 {
            if self.audioCountDownView == nil {
                self.audioCountDownView = NewAudioKeyboardHelper.addAudioCountDownView(view: self)
            }
            self.audioCountDownView?.updateCountDownTime(
                time: self.recordLengthLimit - time
            )
        }
    }

    func audioRecordUpdateRecordVoice(power: Float) {
        delegate?.audioDecible(decible: power)
    }

    func audioRecordUpdateState(state: AudioState) {
        let isPrepare: Bool
        switch state {
        case .prepare:
            isPrepare = true
        case .normal, .recording:
            isPrepare = false
        }
        self.delegate?.recordWithTextAudioKeyboardState(isPrepare: isPrepare)
    }
}
