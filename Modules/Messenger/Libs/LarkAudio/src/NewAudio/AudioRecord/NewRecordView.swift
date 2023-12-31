//
//  NewRecordView.swift
//  LarkAudio
//
//  Created by kangkang on 2023/9/21.
//

import AVFAudio
import Foundation
import LarkContainer
import LarkKeyboardView
import LKCommonsLogging
import UniverseDesignFont
import UniverseDesignToast

// view 实现，viewModel 调用
protocol InRecordAbstractViewByViewModel: AnyObject {
    // 透传audioManager的状态
    func updateState(state: AudioRecordState)
    // 音量
    func updateDecibel(decibel: Float)
    // 时间
    func updateTime(time: TimeInterval)
    // 收到的系统通知
    func audioSessionInterruption()
}

final class NewRecordView: AudioCommonView {

    enum DisplayState {
        case cancel // 手指按压在园外
        case pressing // 手指按压在园内
        case unpressed // 手指未在按压
    }

    var keyboardFocusBlock: ((Bool) -> Void)?

    private static let logger = Logger.log(NewRecordView.self, category: "NewRecordView")
    private let animationView = RecordAnimationView()
    private let tipLabel = UILabel()

    private var vm: InRecordAbstractViewModelByView
    private var keyboardPanelView: LKKeyboardView? {
        vm.keyboard?.audiokeybordPanelView()
    }
    // 存储属性，记得清空
    private var recordTextKeyboardViewCache: [UIView] = []
    private var readyToCancel: Bool = false

    private var displayState: DisplayState {
        get {
            return _displayState
        }
        set {
            let canChange: Bool
            switch (_displayState, newValue) {
            case (_, .unpressed), (.unpressed, .pressing), (.cancel, .pressing), (.pressing, .cancel): canChange = true
            default: canChange = false
            }
            Self.logger.info("\(canChange) set display: \(_displayState) \(newValue)")
            if canChange {
                _displayState = newValue
                switch newValue {
                case .unpressed: unpressed()// 未在按压
                case .pressing: pressing()  // 按压在园内
                case .cancel: cancel()      // 按压在园外
                }
            } else {
                assertionFailure()
                Self.logger.error("displayState change failed, old: \(_displayState), new: \(newValue)")
            }
        }
    }

    private var _displayState: DisplayState = .unpressed

    init(userResolver: UserResolver, vm: InRecordAbstractViewModelByView, openType: OpenType) {
        self.vm = vm
        super.init(userResolver: userResolver, openType: openType)
        switch openType {
        case .pressPanel: radiusView = GestureView(isRadius: false)
        case .tapPanel: radiusView = GestureView(isRadius: true)
        }
        self.vm.viewDelegate = self
        setViews()
        Self.logger.info("init record view \(self)")
    }

    deinit {
        Self.logger.info("deinit record view \(self)")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setViews() {
        switch openType {
        case .pressPanel(let longPress):
            self.addSubview(radiusView)
            radiusView.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(GestureView.Cons.squareSpacing)
                make.right.equalToSuperview().offset(-GestureView.Cons.squareSpacing)
                make.height.equalTo(GestureView.Cons.squareHeight)
                make.centerY.equalToSuperview()
            }
            longPress.addTarget(self, action: #selector(longGestureHander))
            insertSelfInKeyboard(keyboardView: keyboardPanelView, view: self)
            startAudioRecord()
        case .tapPanel:
            displayState = .unpressed
            self.addSubview(radiusView)
            radiusView.snp.makeConstraints { make in
                make.width.height.equalTo(GestureView.Cons.RadiusSide)
                make.centerX.equalToSuperview()
                make.top.equalToSuperview().offset(CommonCons.radiusTopOffset)
            }
            radiusView.longGesture.addTarget(self, action: #selector(longGestureHander(sender: )))

            tipLabel.font = UDFont.body2
            tipLabel.text = BundleI18n.LarkAudio.Lark_Chat_HoldToRecordAudio
            tipLabel.textColor = UIColor.ud.textPlaceholder
            self.addSubview(tipLabel)
            tipLabel.snp.makeConstraints { make in
                make.bottom.equalTo(radiusView.snp.top).offset(CommonCons.tipLabelBottomOffset)
                make.centerX.equalToSuperview()
            }
        }
    }

    private func unpressed() {
        tipLabel.isHidden = false
        handlePanelView(show: false, keyboardView: nil)
        handleMaskWindowView(show: false, keyboardView: nil)
        radiusView.gestureState = .audioUnpressed
        readyToCancel = false
        keyboardFocusBlock?(false)
        switch openType {
        case .pressPanel:
            removeAnimation()
            removeSelfFromKeyboard(keyboardView: keyboardPanelView)
        case .tapPanel:
            animationView.removeFromSuperview()
        }
    }

    private func pressing() {
        tipLabel.isHidden = false
        handleMaskWindowView(show: true, keyboardView: keyboardPanelView)
        if animationView.superview == nil {
            switch openType {
            case .pressPanel:
                insertAnimation()
            case .tapPanel:
                handlePanelView(show: true, keyboardView: keyboardPanelView, bottomOffset: CommonCons.radiusTopOffset + CommonCons.tipLabelBottomOffset + ContainerPageView.Cons.pageSumHeight)
                maskPanelView.addSubview(animationView)
                animationView.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
            }
        }
        radiusView.gestureState = .audioPressing
        keyboardFocusBlock?(true)
    }

    private func cancel() {
        tipLabel.isHidden = true
        if case .tapPanel = openType {
            handlePanelView(show: true, keyboardView: keyboardPanelView, bottomOffset: CommonCons.radiusTopOffset + CommonCons.tipLabelBottomOffset + ContainerPageView.Cons.pageSumHeight)
        }
        handleMaskWindowView(show: true, keyboardView: keyboardPanelView)
        radiusView.gestureState = .audioCancel
        keyboardFocusBlock?(false)
    }

    func keyboardDidSet(keyboard: LKKeyboardView?) {
        if case .pressPanel = openType {
            // 直接长按开始录音
            // 真正开始调用录音接口
            Self.logger.info("keyboard delegate did set")
            insertSelfInKeyboard(keyboardView: keyboard, view: self)
            startAudioRecord()
        }
    }

    // 长按手势 start
    override func startAudioRecord() {
        if checkGestureCanRecord() {
            displayState = .pressing
            self.vm.startRecord(from: self.window)
        } else {
            displayState = .unpressed
        }
    }

    // 长按手势 move
    override func handleGestureMove() {
        guard vm.isRecording else { return }
        let point: CGPoint
        switch openType {
        case .pressPanel(let longPress):
            point = longPress.location(in: radiusView)
        case .tapPanel:
            point = radiusView.longGesture.location(in: radiusView)
        }
        animationView.updatePoint(point: point)
        let cancel = animationView.readyToCancel
        if cancel != readyToCancel {
            if cancel {
                displayState = .cancel
            } else {
                displayState = .pressing
            }
            readyToCancel = cancel
        }
    }

    // 长按手势 end
    override func stopAudioRecord() {
        if vm.isRecording {
            animationView.stopPress(comple: { [weak self] in
                self?.displayState = .unpressed
            })
            if readyToCancel {
                vm.cancel()
            } else {
                vm.end()
            }
        } else {
            Self.logger.error("stop audio record, !vm.isRecord, displayState==unpressed")
        }
    }

    private func insertAnimation() {
        guard let keyboardView = keyboardPanelView else { return }
        let viewCache = keyboardView.inputStackView.arrangedSubviews
        for view in viewCache {
            keyboardView.inputStackView.removeArrangedSubview(view)
            view.isHidden = true
        }
        recordTextKeyboardViewCache = viewCache
        keyboardView.inputStackView.insertArrangedSubview(animationView, at: 0)
        animationView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(190)
        }
    }

    private func removeAnimation() {
        guard animationView.superview != nil,
              let keyboardView = keyboardPanelView else { return }
        keyboardView.inputStackView.removeArrangedSubview(animationView)
        animationView.removeFromSuperview()
        for view in recordTextKeyboardViewCache.reversed() {
            keyboardView.inputStackView.insertArrangedSubview(view, at: 0)
            view.isHidden = false
        }
        recordTextKeyboardViewCache = []
        keyboardView.keyboardPanel.panelBarHidden = false
    }
}

extension NewRecordView: InRecordAbstractViewByViewModel {

    func updateState(state: AudioRecordState) {
        switch state {
        case .tooShort:
            if let window = keyboardPanelView?.window {
                UDToast.showTips(with: BundleI18n.LarkAudio.Lark_Legacy_VoiceIndicatorTooShort, on: window)
            }
        case .prepare: break
        case .start: break
        case .cancel: break
        case .failed(let error):
            // 强制结束手势
            stopLongGesture()
            displayState = .unpressed
            switch error {
            case .dataEmpty, .startFailed: presentFailAlert(from: keyboardPanelView?.window)
            case .tryLockFailed: break
            }
        case .success: break
        }
    }

    func updateDecibel(decibel: Float) {
        animationView.updateDecible(decible: decibel)
    }

    func updateTime(time: TimeInterval) {
        if time > CommonCons.recordLengthLimit {
            self.stopAudioRecord()
        } else if CommonCons.recordLengthLimit - time <= CommonCons.strongReminderTime {
            // 最后 10s 强提醒
            animationView.updateTime(str: BundleI18n.LarkAudio.Lark_IM_AudioMsg_RecordingEndsInNums_Text(Int(CommonCons.recordLengthLimit - time)))
        } else {
            animationView.updateTime(str: AudioUtils.timeString(time: time))
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
}

extension NewRecordView: AudioKeyboardItemViewDelegate {
    var title: String {
        BundleI18n.LarkAudio.Lark_Chat_RecordAudio
    }
    var recognitionType: RecognizeLanguageManager.RecognizeType {
        return .audio
    }
    var keyboardView: UIView {
        self
    }
    func resetKeyboardView() {
        displayState = .unpressed
    }
}
