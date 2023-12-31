//
//  AudioToTextView.swift
//  LarkAudio
//
//  Created by kangkang on 2023/9/21.
//

import AVFAudio
import Foundation
import LarkAIInfra
import EditTextView
import LarkContainer
import LKCommonsLogging
import LarkKeyboardView
import LarkLocalizations
import UniverseDesignFont
import UniverseDesignIcon
import UniverseDesignColor
import LarkAlertController
import UniverseDesignToast

public protocol AudioToTextViewStopDelegate: AnyObject {
    func stopRecognize()
}

// 语音转文字，view实现，ViewModel调用
protocol InAudioToTextAbstractViewByViewModel: AnyObject, UITextViewDelegate, EditTextViewTextDelegate {
    // 音量
    func updateDecibel(decibel: Float)
    // 透传audioManager的状态
    func updateState(state: AudioRecordState)
    // 收到的系统通知
    func audioSessionInterruption()
    // 识别的文字
    func updateTextResult(text: String, finish: Bool, diffIndexSlice: [Int32])
}

// 按钮的颜色需要调整
final class NewAudioToTextView: AudioCommonView {

    enum Cons {
        static let deleteViewSide: CGFloat = 32
        static let deleteIconSize: CGFloat = 22
        static let deleteViewRightOffset: CGFloat = 20
        static let minDecibel: CGFloat = 40
        static let maxDecibel: CGFloat = 65
        static let shortcutTopOffset: CGFloat = 12
    }
    enum DisplayState {
        case idle // 未在录音，初始化状态
        case pressedRecording // 长按录音
        case tapRecording // 点按录音
        case recognizing // 松手+识别剩余中
        case end // 录音完成，展示按钮
    }
    var keyboardFocusBlock: ((Bool) -> Void)?

    private static let logger = Logger.log(NewAudioToTextView.self, category: "NewAudioToTextView")
    private let tipLabel = UILabel()
    private let deleteButton = UIView()
    private let voiceRippleView = UIView()
    private let leftView = UIView()
    private let rightView = UIView()
    private let textView = KeyboardInputView()
    private lazy var languageLabel = AudioLanguageLabel(userResolver: userResolver, type: .textOnly)
    private lazy var cancelButton = AudioActionButton(config: .init(
        name: BundleI18n.LarkAudio.Lark_IM_AudioToTextSelectLangugage_Cancel_Button, icon: UDIcon.undoOutlined,
        iconColor: UIColor.ud.iconN1, textColor: UIColor.ud.textCaption, loadingColor: UIColor.ud.iconN1))
    private lazy var sendButton = AudioActionButton(config: .init(
        name: BundleI18n.LarkAudio.Lark_Legacy_Send, icon: UDIcon.sendFilled,
        iconColor: UIColor.ud.textLinkHover, textColor: UIColor.ud.textLinkHover, loadingColor: UIColor.ud.colorfulBlue))
    private lazy var aiShortcut = AudioRecognizeAIShortcut(userResolver: userResolver, chat: vm.chat)

    private var vm: InAudioToTextAbstractViewModelByView
    private var keyboardPanelView: LKKeyboardView? {
        vm.keyboard?.audiokeybordPanelView()
    }

    // 存储属性，记得清空
    private var textViewTintColor: UIColor?
    private var timer: Timer?
    private var hasRecognizeResult: Bool = false {
        didSet { handleAIButton() }
    }

    private var displayState: DisplayState {
        get {
            return _displayState
        }
        set {
            let canChange: Bool
            switch (_displayState, newValue) {
            case (_, .idle), (.idle, .pressedRecording), (.idle, .tapRecording),
                (.end, .pressedRecording), (.end, .tapRecording), (.recognizing, .pressedRecording), (.recognizing, .tapRecording),
                (.pressedRecording, .recognizing), (.tapRecording, .recognizing),
                (.recognizing, .end), (.end, .end): canChange = true
            default: canChange = false
            }
            Self.logger.info("\(canChange) set display: \(_displayState) \(newValue)")
            if canChange {
                _displayState = newValue
                handleAIButton()
                switch newValue {
                case .idle: idle()
                case .pressedRecording: pressedRecording()
                case .tapRecording: tapRecording()
                case .recognizing: recognizing()
                case .end: end()
                }
            } else {
                Self.logger.error("displayState change failed, old: \(_displayState), new: \(newValue)")
                assertionFailure()
            }
        }
    }

    private var _displayState: DisplayState = .idle

    init(userResolver: UserResolver, vm: InAudioToTextAbstractViewModelByView, openType: OpenType) {
        self.vm = vm
        super.init(userResolver: userResolver, openType: openType)
        self.vm.viewDelegate = self
        self.canGesture = { [weak self] in return AudioUtils.checkNetworkConnection(view: self) }
        switch openType {
        case .pressPanel(let longPress):
            radiusView = GestureView(isRadius: false)
            setLongPressView(longPress: longPress)
        case .tapPanel:
            radiusView = GestureView(isRadius: true)
            setViews()
            setupAI()
        }
        delegateDidSet(keyboard: keyboardPanelView)
        Self.logger.info("init audio to text view, openType: \(openType) \(self)")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        Self.logger.info("deinit audio to text view \(self)")
    }

    private func setLongPressView(longPress: UILongPressGestureRecognizer) {
        self.addSubview(radiusView)
        radiusView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(GestureView.Cons.squareSpacing)
            make.right.equalToSuperview().offset(-GestureView.Cons.squareSpacing)
            make.height.equalTo(GestureView.Cons.squareHeight)
            make.centerY.equalToSuperview()
        }
        longPress.addTarget(self, action: #selector(longGestureHander))
    }

    private func setViews() {
        self.addSubview(voiceRippleView)
        self.addSubview(leftView)
        self.addSubview(rightView)
        self.addSubview(cancelButton)
        self.addSubview(sendButton)
        self.addSubview(radiusView)
        self.addSubview(tipLabel)
        self.addSubview(languageLabel)
        self.addSubview(deleteButton)

        // 两个按钮
        cancelButton.tapHandler = { [weak self] in self?.clickCancelBtn() }
        sendButton.tapHandler = { [weak self] in self?.clickSendBtn() }

        // 波纹
        self.voiceRippleView.backgroundColor = UDColor.colorfulBlue.withAlphaComponent(0.1)

        // 大按钮
        radiusView.longGesture.minimumPressDuration = 0.3
        radiusView.longGesture.addTarget(self, action: #selector(longGestureHander(sender: )))
        radiusView.tapGesture.addTarget(self, action: #selector(tapGestureHander(sender: )))
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapGestureHander(sender: )))
        self.audioMaskWindowView.addGestureRecognizer(tapGesture)

        // 提示文本
        tipLabel.font = UDFont.body2
        tipLabel.textColor = UDColor.textPlaceholder
        tipLabel.text = BundleI18n.LarkAudio.Lark_IM_AudioMsg_TapHoldToRecord_Text
        tipLabel.snp.makeConstraints { make in
            make.bottom.equalTo(radiusView.snp.top).offset(CommonCons.tipLabelBottomOffset)
            make.centerX.equalToSuperview()
        }

        // 识别语言
        languageLabel.updateLabelAndIcon(labelFont: 14, labelColor: UIColor.ud.textCaption)
        languageLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(CommonCons.languageLabelTopOffset)
        }

        // 删除按钮
        let deleteTapGesture: UITapGestureRecognizer = UITapGestureRecognizer()
        deleteButton.addGestureRecognizer(deleteTapGesture)
        deleteTapGesture.addTarget(self, action: #selector(clickDeleteButton))
        deleteButton.snp.makeConstraints { make in
            make.centerY.equalTo(languageLabel)
            make.width.height.equalTo(Cons.deleteViewSide)
            make.right.equalToSuperview().offset(-Cons.deleteViewRightOffset)
        }
        let deleteImageView = UIImageView(image: UDIcon.deleteOutlined.ud.withTintColor(UIColor.ud.iconN2))
        deleteButton.addSubview(deleteImageView)
        deleteImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(Cons.deleteIconSize)
        }

        // 左右区域
        leftView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalTo(radiusView.snp.left)
            make.centerY.equalTo(radiusView)
            make.height.greaterThanOrEqualTo(54)
        }
        rightView.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.left.equalTo(radiusView.snp.right)
            make.centerY.equalTo(radiusView)
            make.height.greaterThanOrEqualTo(54)
        }

        displayState = .idle

        // app挂起
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    }

    private func setActionHidden(tipLabel: Bool, languageLabel: Bool, deleteButton: Bool, cancelButton: Bool, sendButton: Bool, voiceRippleView: Bool) {
        self.tipLabel.isHidden = tipLabel
        self.languageLabel.isHidden = languageLabel
        self.deleteButton.isHidden = deleteButton
        self.cancelButton.isHidden = cancelButton
        self.sendButton.isHidden = sendButton
        self.voiceRippleView.isHidden = voiceRippleView
        self.voiceRippleView.bounds = .zero
        self.voiceRippleView.center = radiusView.center
    }

    private func idle() {
        switch openType {
        case .tapPanel:
            keyboardFocusBlock?(false)
            setActionHidden(tipLabel: false, languageLabel: false, deleteButton: true, cancelButton: true, sendButton: true, voiceRippleView: true)
            self.setButtomInCenter()
            radiusView.gestureState = .textIdle
            radiusView.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalToSuperview().offset(CommonCons.radiusTopOffset)
                make.width.height.equalTo(GestureView.Cons.RadiusSide)
            }
            textView.inputState = .over
            vm.reset()
        case .pressPanel:
            radiusView.gestureState = .textIdle
            textView.inputState = .over
            removeSelfFromKeyboard(keyboardView: keyboardPanelView)
        }
        stopTimer()
        handlePanelView(show: false, keyboardView: nil)
        handleMaskWindowView(show: false, keyboardView: nil)
        hasRecognizeResult = false
        aiShortcut.reset()
    }

    private func pressedRecording() {
        switch openType {
        case .tapPanel:
            setActionHidden(tipLabel: true, languageLabel: true, deleteButton: true, cancelButton: true, sendButton: true, voiceRippleView: false)
            radiusView.gestureState = .textPressedRecording
            radiusView.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalToSuperview().offset(CommonCons.radiusTopOffset)
                make.width.height.equalTo(GestureView.Cons.RadiusSide)
            }
            textView.inputState = .voiceAndRecognizing
            handlePanelView(show: true, keyboardView: keyboardPanelView, isMaskInput: false, bottomOffset: ContainerPageView.Cons.pageSumHeight)
            handleMaskWindowView(show: true, keyboardView: keyboardPanelView)
            keyboardFocusBlock?(true)
            vm.reset()
        case .pressPanel:
            textViewTintColor = keyboardPanelView?.inputTextView.tintColor
            keyboardPanelView?.inputTextView.tintColor = .clear
            textView.inputState = .voiceAndRecognizing
            radiusView.gestureState = .textPressedRecording
            handleMaskWindowView(show: true, keyboardView: keyboardPanelView)
        }
    }

    private func tapRecording() {
        switch openType {
        case .tapPanel:
            setActionHidden(tipLabel: true, languageLabel: true, deleteButton: true, cancelButton: true, sendButton: true, voiceRippleView: false)
            radiusView.gestureState = .textTapRecording
            radiusView.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalToSuperview().offset(CommonCons.radiusTopOffset)
                make.width.height.equalTo(GestureView.Cons.RadiusSide)
            }
            textView.inputState = .voiceAndRecognizing
            handlePanelView(show: true, keyboardView: keyboardPanelView, isMaskInput: false, bottomOffset: ContainerPageView.Cons.pageSumHeight)
            handleMaskWindowView(show: true, keyboardView: keyboardPanelView)
            keyboardFocusBlock?(true)
            vm.reset()
        case .pressPanel:
            assertionFailure("long press can not .tapRecording")
        }
    }

    private func recognizing() {
        stopTimer()
        timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(timerStop), userInfo: nil, repeats: false)
        switch openType {
        case .tapPanel:
            setActionHidden(tipLabel: false, languageLabel: false, deleteButton: false, cancelButton: false, sendButton: false, voiceRippleView: true)
            self.radiusView.gestureState = .textEnd
            radiusView.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalToSuperview().offset(CommonCons.radiusTopOffset)
                make.width.height.equalTo(GestureView.Cons.smallRadiusSize)
            }
            self.setButtomInCenter()
            self.layoutIfNeeded()
            self.setButtonAverage()
            UIView.animate(withDuration: 0.25) {
                // 如果动画过程中已经 reset UI，则不再改变 cornerRadius
                if !self.sendButton.isHidden {
                    self.layoutIfNeeded()
                }
            }
            textView.inputState = .recognizing
            handlePanelView(show: true, keyboardView: keyboardPanelView, isMaskInput: false, bottomOffset: ContainerPageView.Cons.pageSumHeight)
            handleMaskWindowView(show: false, keyboardView: nil)
            keyboardFocusBlock?(true)
        case .pressPanel:
            textView.inputState = .recognizing
            keyboardPanelView?.inputTextView.becomeFirstResponder()
            if let textViewTintColor { keyboardPanelView?.inputTextView.tintColor = textViewTintColor }
            handleMaskWindowView(show: false, keyboardView: nil)
            removeSelfFromKeyboard(keyboardView: keyboardPanelView)
        }
    }

    private func end() {
        stopTimer()
        switch openType {
        case .tapPanel:
            setActionHidden(tipLabel: false, languageLabel: false, deleteButton: false, cancelButton: false, sendButton: false, voiceRippleView: true)
            textView.inputState = .over
            handlePanelView(show: true, keyboardView: keyboardPanelView, isMaskInput: false, bottomOffset: ContainerPageView.Cons.pageSumHeight)
            handleMaskWindowView(show: false, keyboardView: nil)
            keyboardFocusBlock?(true)
            vm.reset()
        case .pressPanel: break
        }
    }

    private func delegateDidSet(keyboard: LKKeyboardView?) {
        guard let keyboard else { return }
        keyboard.inputTextView.delegate = self
        keyboard.inputTextView.textDelegate = self
        textView.keyboardView = keyboard
        if case .pressPanel = openType {
            Self.logger.info("keyboard delegate did set")
            insertSelfInKeyboard(keyboardView: keyboard, view: self)
            startAudioRecord()
        }
    }

    private func setupAI() {
        aiShortcut.isShowingButton = { [weak self] (isShow, view) in
            if isShow {
                if view.superview == nil {
                    self?.maskPanelView.addSubview(view)
                    view.snp.makeConstraints { make in
                        make.left.right.equalToSuperview()
                        make.top.equalToSuperview().offset(Cons.shortcutTopOffset)
                        make.height.equalTo(AudioShortcutCollectionView.Cons.shortcutCollectionHeight)
                    }
                }
            } else {
                if view.superview != nil {
                    view.removeFromSuperview()
                }
            }
        }
        aiShortcut.isShowingPreview = { [weak self] (isShow, view) in
            guard let self, let keyboardView = self.keyboardPanelView else { return }
            if isShow {
                if view.superview == nil {
                    keyboardView.addSubview(view)
                    view.snp.makeConstraints { make in
                        make.left.right.equalToSuperview()
                        make.top.equalTo(keyboardView.inputStackWrapper.snp.bottom)
                        make.bottom.equalTo(keyboardView.snp.bottom)
                    }
                }
            } else {
                if view.superview != nil {
                    view.removeFromSuperview()
                }
            }
        }
        aiShortcut.aiResultCallback = { [weak self] result in
            self?.textView.replaceAllText(text: result)
        }
        aiShortcut.inputText = { [weak self] in
            return self?.keyboardPanelView?.inputTextView.attributedText.string ?? ""
        }
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow == nil, displayState == .tapRecording {
            Self.logger.info("willMove. newWindow == nil")
            stopAudioRecord()
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if self.window != nil, case .tapPanel = openType {
            textView.canShowCaret(true)
        } else {
            textView.canShowCaret(false)
        }
    }

    override func startAudioRecord() {
        if checkGestureCanRecord() {
            // 设置 UI
            if displayState == .recognizing {
                displayState = .end
            }
            displayState = .pressedRecording
            self.vm.startRecord(language: RecognizeLanguageManager.shared.recognitionLanguage, from: self.window)
        } else {
            displayState = .idle
        }
    }

    override func stopAudioRecord() {
        if vm.isRecording {
            Self.logger.info("stop audio record")
            displayState = .recognizing
            self.vm.end()
        } else {
            Self.logger.error("stop audio record. !vm.isRecord, \(self)")
        }
        if case .pressPanel(let longPress) = openType {
            longPress.removeTarget(self, action: #selector(longGestureHander))
        }
    }

    @objc
    private func timerStop() {
        if displayState == .recognizing {
            displayState = .end
        }
        stopTimer()
    }

    @objc
    private func clickCancelBtn() {
        vm.cancel()
        displayState = .idle
    }

    @objc
    private func clickSendBtn() {
        vm.sendText()
        displayState = .idle
    }

    @objc
    private func applicationWillResignActive() {
        if vm.isRecording {
            Self.logger.info("applicationWillResignActive stopRecord")
            stopAudioRecord()
        }
    }

    @objc
    private func tapGestureHander(sender: UITapGestureRecognizer) {
        // 记录是否录音中
        if vm.isRecording {
            if displayState == .tapRecording {
                Self.logger.info("tapGestureHander stopRecord")
                stopAudioRecord()
            }
        } else {
            if AudioUtils.checkCallingState(userResolver: userResolver, from: self.window),
               AudioUtils.checkByteViewState(userResolver: userResolver, from: self.window),
               AudioUtils.checkNetworkConnection(view: self) {
                if displayState == .recognizing {
                    displayState = .end
                }
                displayState = .tapRecording
                self.vm.startRecord(language: RecognizeLanguageManager.shared.recognitionLanguage, from: self.window)
            } else {
                self.stopTapGesture() // 强制结束手势
            }
        }
    }

    @objc
    private func clickDeleteButton() {
        keyboardPanelView?.deleteBackward()
        displayState = .end
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func setButtonAverage() {
        cancelButton.snp.remakeConstraints { (maker) in
            maker.left.top.width.height.equalTo(leftView)
        }
        sendButton.snp.remakeConstraints { (maker) in
            maker.left.top.width.height.equalTo(rightView)
        }
    }

    private func setButtomInCenter() {
        cancelButton.snp.remakeConstraints { (maker) in
            maker.center.equalTo(radiusView)
        }
        sendButton.snp.remakeConstraints { (maker) in
            maker.center.equalTo(radiusView)
        }
    }

    private func handleAIButton() {
        let isEnd = displayState == .end || displayState == .recognizing
        let isTextEmpty = !(keyboardPanelView?.inputTextView.text.isEmpty ?? true)
        if isEnd, isTextEmpty, hasRecognizeResult {
            aiShortcut.canShowButton(show: true)
        } else {
            aiShortcut.canShowButton(show: false)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// 语音转文字场景，viewModel 调用 view 的方法
extension NewAudioToTextView: InAudioToTextAbstractViewByViewModel {

    func updateDecibel(decibel: Float) {
        let maxRadiusSide: CGFloat = GestureView.Cons.RadiusSide + CommonCons.radiusTopOffset * 2
        let calWidth: CGFloat = (CGFloat(decibel) - Cons.minDecibel) / (Cons.maxDecibel - Cons.minDecibel) * 120
        let width = min(GestureView.Cons.RadiusSide + max(calWidth, 0), maxRadiusSide)
        self.voiceRippleView.layer.masksToBounds = true
        self.voiceRippleView.center = self.radiusView.center
        UIView.animate(withDuration: 0.1) { [weak self] in
            guard let self else { return }
            self.voiceRippleView.bounds = CGRect(x: 0.0, y: 0.0, width: Double(width), height: Double(width))
            self.voiceRippleView.layer.cornerRadius = CGFloat(width / 2)
        }
    }

    func updateState(state: AudioRecordState) {
        switch state {
        case .tooShort:
            break
        case .prepare:
            break
        case .start:
            textView.hasReady()
        case .cancel:
            displayState = .idle
        case .failed(let error):
            // 强制结束手势
            stopTapGesture()
            stopLongGesture()
            switch error {
            case .dataEmpty, .startFailed:
                presentFailAlert(from: keyboardPanelView?.window)
            case .tryLockFailed: break
            }
            displayState = .idle
        case .success:
            break
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
        textView.updateText(text: text, finish: finish, diffIndexSlice: diffIndexSlice)
        hasRecognizeResult = !text.isEmpty
        if finish, displayState == .recognizing {
            displayState = .end
        }
    }
}

// containerPageView 调用 view 的能力
extension NewAudioToTextView: AudioKeyboardItemViewDelegate {
    var title: String {
        BundleI18n.LarkAudio.Lark_Chat_AudioToText
    }
    var recognitionType: RecognizeLanguageManager.RecognizeType {
        .text
    }
    var keyboardView: UIView {
        self
    }
    func resetKeyboardView() {
        displayState = .idle
    }
}

extension NewAudioToTextView: UITextViewDelegate, EditTextViewTextDelegate {

    public func textViewDidBeginEditing(_ textView: UITextView) {
        Self.logger.info("textViewDidBeginEditing")
        if case .tapPanel = openType {
            self.textView.textViewDidBeginEditing()
            displayState = .idle
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        if case .pressPanel = openType, displayState == .recognizing {
            displayState = .end
        }
    }

    public func textViewDidChangeSelection(_ textView: UITextView) {
        handleAIButton()
    }
}

extension NewAudioToTextView: AudioToTextViewStopDelegate {
    func stopRecognize() {
        if displayState == .recognizing {
            displayState = .end
        }
    }
}
