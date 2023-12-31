//
//  NewAudioAndTextView.swift
//  LarkAudio
//
//  Created by kangkang on 2023/9/21.
//

import AVFAudio
import LarkUIKit
import Foundation
import EditTextView
import LarkContainer
import LarkKeyboardView
import LKCommonsLogging
import UniverseDesignFont
import UniverseDesignToast
import UniverseDesignColor

// view实现，viewModel调用
protocol InAudioAndTextAbstractViewByViewModel: AnyObject {
    // 透传audioManager的状态
    func updateState(state: AudioRecordState)
    // 音量
    func updateDecibel(decibel: Float)
    // 时间
    func updateTime(time: TimeInterval)
    // 收到的系统通知
    func audioSessionInterruption()
    // 识别的文字
    func updateTextResult(text: String, finish: Bool, diffIndexSlice: [Int32])
}

// 监听输入框文字，改变按钮 isEnable
final class NewAudioAndTextView: AudioCommonView {

    enum DisplayState {
        case idle // 未在录音，初始化状态
        case voiceAndRecording // 按压+说话中
        case recognizing // 松手+识别剩余中
        case recognized // 松手+识别完成
    }

    var keyboardFocusBlock: ((Bool) -> Void)?

    private static let logger = Logger.log(NewAudioAndTextView.self, category: "NewAudioAndTextView")
    private let tipLabel = UILabel()
    private let actionButton: AudioAndTextActionButton
    private let textAndWaveView: TextAndWaveView
    private lazy var languageLabel: AudioLanguageLabel = AudioLanguageLabel(userResolver: userResolver, type: .audioAndText)

    private var vm: InAudioAndTextAbstractViewModelByView
    private var keyboardPanelView: LKKeyboardView? {
        vm.keyboard?.audiokeybordPanelView()
    }
    // 存储属性，记得清空
    private var recordTextKeyboardViewCache: [UIView] = []
    private var timer: Timer?
    private var recognizeFinish: Bool = false

    private var displayState: DisplayState {
        get {
            return _displayState
        }
        set {
            let canChange: Bool
            switch (_displayState, newValue) {
            case (.idle, .voiceAndRecording), (.voiceAndRecording, .recognizing), (.recognizing, .recognized), (_, .idle): canChange = true
            default: canChange = false
            }
            Self.logger.info("\(canChange) set display: \(_displayState) \(newValue)")
            if canChange {
                _displayState = newValue
                switch newValue {
                case .idle: idle()
                case .voiceAndRecording: voiceAndRecording()
                case .recognizing: recognizing()
                case .recognized: recognized()
                }
            } else {
                Self.logger.error("displayState change failed, old: \(_displayState), new: \(newValue)")
                assertionFailure()
            }
        }
    }

    private var _displayState: DisplayState = .idle

    init(userResolver: UserResolver, vm: InAudioAndTextAbstractViewModelByView, chatName: String, openType: OpenType) {
        self.vm = vm
        self.textAndWaveView = TextAndWaveView(userResolver: userResolver, chatName: chatName, recordLengthLimit: CommonCons.recordLengthLimit)
        self.actionButton = AudioAndTextActionButton()
        super.init(userResolver: userResolver, openType: openType)
        switch openType {
        case .pressPanel: radiusView = GestureView(isRadius: false)
        case .tapPanel: radiusView = GestureView(isRadius: true)
        }
        self.vm.viewDelegate = self
        setViews()
        Self.logger.info("init audio and text view \(self)")
    }

    deinit {
        stopTimer()
        Self.logger.info("deinit audio and text view \(self)")
    }

    private func setViews() {
        switch openType {
        case .tapPanel:
            self.addSubview(radiusView)
            radiusView.longGesture.addTarget(self, action: #selector(longGestureHander(sender: )))
            radiusView.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalToSuperview().offset(CommonCons.radiusTopOffset)
                make.width.height.equalTo(GestureView.Cons.RadiusSide)
            }
            self.addSubview(tipLabel)
            tipLabel.text = BundleI18n.LarkAudio.Lark_Chat_AudioToTextTips
            tipLabel.font = UDFont.body2
            tipLabel.textColor = UIColor.ud.textPlaceholder
            tipLabel.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.bottom.equalTo(radiusView.snp.top).offset(CommonCons.tipLabelBottomOffset)
            }

            self.addSubview(languageLabel)
            languageLabel.updateLabelAndIcon(labelFont: 14, labelColor: UIColor.ud.textCaption)
            languageLabel.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalToSuperview().offset(CommonCons.languageLabelTopOffset)
            }
            displayState = .idle
        case .pressPanel(let longPress):
            self.addSubview(radiusView)
            radiusView.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(GestureView.Cons.squareSpacing)
                make.right.equalToSuperview().offset(-GestureView.Cons.squareSpacing)
                make.height.equalTo(GestureView.Cons.squareHeight)
                make.centerY.equalToSuperview()
            }
            longPress.addTarget(self, action: #selector(longGestureHander))
            addActionButtonInKeyboard()
            insertSelfInKeyboard(keyboardView: keyboardPanelView, view: self)
        }

        actionButton.isHidden = true
        actionButton.cancelButton.tapHandler = { [weak self] in self?.clickCancelBtn() }
        actionButton.sendAudioButton.tapHandler = { [weak self] in self?.clickSendAudioBtn() }
        actionButton.sendAllButton.tapHandler = { [weak self] in self?.clickSendAllBtn() }
        actionButton.sendTextButton.tapHandler = { [weak self] in self?.clickSendTextBtn() }

        textAndWaveView.textView.textView.delegate = self

        if case .pressPanel = openType {
            startAudioRecord()
        }
    }

    private func setActionHidden(tipLabel: Bool, actionButton: Bool, languageLabel: Bool, radiusView: Bool, textAndWaveView: Bool) {
        self.tipLabel.isHidden = tipLabel
        self.actionButton.isHidden = actionButton
        self.languageLabel.isHidden = languageLabel
        self.radiusView.isHidden = radiusView
        self.textAndWaveView.isHidden = textAndWaveView
    }

    private func idle() {
        stopTimer()
        setActionHidden(tipLabel: false, actionButton: true, languageLabel: false, radiusView: false, textAndWaveView: true)
        addActionButtonInKeyboard()
        radiusView.gestureState = .audioWithTextUnpressed
        removeTextView()
        handleMaskWindowView(show: false, keyboardView: nil)
        handleMaskVCView(show: false, keyboardView: nil)
        keyboardFocusBlock?(false)
        recognizeFinish = false
        vm.reset()
        if case .pressPanel = openType {
            removeSelfFromKeyboard(keyboardView: keyboardPanelView)
        }
    }

    private func voiceAndRecording() {
        setActionHidden(tipLabel: true, actionButton: true, languageLabel: true, radiusView: false, textAndWaveView: false)
        radiusView.gestureState = .audioWithTextPressing
        // 输入框和Wave
        insertTextView()
        textAndWaveView.displayState = .voiceAndRecognizing
        handleMaskWindowView(show: true, keyboardView: keyboardPanelView)
        handleMaskVCView(show: true, keyboardView: keyboardPanelView)
        keyboardFocusBlock?(true)
    }

    private func recognizing() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { [weak self] _ in
            guard let self else { return }
            if displayState == .recognizing {
                displayState = .recognized
            }
        })
        setActionHidden(tipLabel: true, actionButton: false, languageLabel: true, radiusView: true, textAndWaveView: false)
        actionButton.loadingHandler(show: true)
        textAndWaveView.displayState = .recognizing
        handleMaskWindowView(show: false, keyboardView: nil)
        handleMaskVCView(show: true, keyboardView: keyboardPanelView)
        keyboardFocusBlock?(true)
    }

    private func recognized() {
        stopTimer()
        setActionHidden(tipLabel: true, actionButton: false, languageLabel: true, radiusView: true, textAndWaveView: false)
        if !recognizeFinish, let vc = AudioUtils.getViewController(view: self) {
            UDToast.showFailure(with: BundleI18n.LarkAudio.Lark_Chat_SendAudioAndTextPoorNetworkTip, on: vc.view)
        }
        actionButton.loadingHandler(show: false)
        textAndWaveView.displayState = .over
        handleMaskWindowView(show: false, keyboardView: nil)
        handleMaskVCView(show: true, keyboardView: keyboardPanelView)
        keyboardFocusBlock?(true)
    }

    override func startAudioRecord() {
        // 再次检查手势状态，是否开启录音
        if checkGestureCanRecord() {
            displayState = .voiceAndRecording
            self.vm.startRecord(language: RecognizeLanguageManager.shared.recognitionLanguage, from: self.window)
        } else {
            displayState = .idle
        }
    }

    override func stopAudioRecord() {
        if vm.isRecording {
            displayState = .recognizing
            self.vm.end()
        } else {
            Self.logger.error("stop audio record. !vm.isRecord, displayState!=.voiceAndRecording")
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func addActionButtonInKeyboard() {
        guard actionButton.superview != self else { return }
        // 把按钮放在键盘面板里面
        actionButton.removeFromSuperview()
        self.addSubview(actionButton)
        actionButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.centerY.equalTo(radiusView)
        }
    }

    private func addActionButtonInStackView() {
        guard actionButton.superview != textAndWaveView.stackView else { return }
        // 把按钮放在textAndWaveView里面
        actionButton.removeFromSuperview()
        textAndWaveView.stackView.addArrangedSubview(actionButton)
        actionButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
        }
    }

    private func insertTextView() {
        guard let keyboardView = keyboardPanelView else { return }
        let viewCache = keyboardView.inputStackView.arrangedSubviews
        for view in viewCache {
            keyboardView.inputStackView.removeArrangedSubview(view)
            view.isHidden = true
        }
        recordTextKeyboardViewCache = viewCache

        textAndWaveView.keyboardView = keyboardView
        keyboardView.inputStackView.insertArrangedSubview(textAndWaveView, at: 0)
        textAndWaveView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
        }

        keyboardView.keyboardPanel?.panelBarHidden = true
    }

    private func removeTextView() {
        guard textAndWaveView.superview != nil,
              let keyboardView = keyboardPanelView else { return }

        keyboardView.inputStackView.removeArrangedSubview(textAndWaveView)
        textAndWaveView.removeFromSuperview()

        for view in recordTextKeyboardViewCache.reversed() {
            keyboardView.inputStackView.insertArrangedSubview(view, at: 0)
            view.isHidden = false
        }
        recordTextKeyboardViewCache = []
        keyboardView.keyboardPanel.panelBarHidden = false
    }

    private func clickCancelBtn() {
        vm.cancel()
        displayState = .idle
    }

    private func clickSendAudioBtn() {
        vm.sendAudio()
        displayState = .idle
    }

    private func clickSendTextBtn() {
        vm.sendText(str: textAndWaveView.textView.textView.text)
        displayState = .idle
    }

    private func clickSendAllBtn() {
        vm.sendAll(str: textAndWaveView.textView.textView.text)
        displayState = .idle
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension NewAudioAndTextView: InAudioAndTextAbstractViewByViewModel {
    func updateState(state: AudioRecordState) {
        switch state {
        case .tooShort:
            if let window = keyboardPanelView?.window {
                UDToast.showTips(with: BundleI18n.LarkAudio.Lark_Legacy_VoiceIndicatorTooShort, on: window)
            }
            displayState = .idle
        case .prepare:
            break
        case .start:
            textAndWaveView.hasReady()
        case .cancel:
            displayState = .idle
        case .failed(let error):
            stopLongGesture()
            switch error {
            case .dataEmpty, .startFailed: presentFailAlert(from: keyboardPanelView?.window)
            case .tryLockFailed: break
            }
            displayState = .idle
        case .success:
            break
        }
    }

    func updateDecibel(decibel: Float) {
        textAndWaveView.updateDecibel(decibel: decibel)
    }

    func updateTime(time: TimeInterval) {
        if time > CommonCons.recordLengthLimit {
            self.stopAudioRecord()
            stopLongGesture()
        } else {
            textAndWaveView.updateTime(time)
        }
    }
    func audioSessionInterruption() {
        if vm.isRecording, let window = keyboardPanelView?.window {
            // 录音被打断，请重试
            Self.logger.info("audio interruption")
            UDToast.showTipsOnScreenCenter(with: BundleI18n.LarkAudio.Lark_IM_RecordingInterrupted_Toast, on: window)
            stopAudioRecord()
        }
    }

    func updateTextResult(text: String, finish: Bool, diffIndexSlice: [Int32]) {
        textAndWaveView.updateText(text: text, finish: finish, diffIndexSlice: diffIndexSlice)
        if finish {
            recognizeFinish = true
            if displayState == .recognizing {
                displayState = .recognized
            }
        }
        actionButton.isEnabled = !text.isEmpty
    }
}
extension NewAudioAndTextView: AudioKeyboardItemViewDelegate {
    var title: String {
        BundleI18n.LarkAudio.Lark_Chat_SendAudioWithText
    }
    var recognitionType: RecognizeLanguageManager.RecognizeType {
        return .audioWithText
    }
    var keyboardView: UIView {
        self
    }
    func resetKeyboardView() {
        if displayState == .recognizing || displayState == .recognized {

        } else {
            displayState = .idle
        }
    }
}

extension NewAudioAndTextView: UITextViewDelegate {
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        keyboardPanelView?.observeKeyboard = true
        if displayState == .recognizing {
            displayState = .recognized
        }
        // 如果是面板进入
        if case .tapPanel = openType {
            addActionButtonInStackView()
        }
        // 如果是长按进入，按钮组已经在键盘的 StackView 内，不需要再调整
        AudioTracker.imChatVoiceMsgClick(click: .clickInput, viewType: .audioWithText)
        return true
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        keyboardPanelView?.observeKeyboard = true
    }

    func textViewDidChange(_ textView: UITextView) {
        actionButton.isEnabled = !textAndWaveView.textView.textView.text.isEmpty
    }

    func textViewDidEndEditing() {
        keyboardPanelView?.observeKeyboard = false
        if Display.pad {
            keyboardPanelView?.fold()
        }
    }
}
