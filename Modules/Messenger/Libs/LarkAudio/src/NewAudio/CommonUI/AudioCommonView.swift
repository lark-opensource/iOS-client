//
//  AudioCommonView.swift
//  LarkAudio
//
//  Created by kangkang on 2023/9/21.
//

import AVFAudio
import Foundation
import EENavigator
import LarkContainer
import LarkKeyboardView
import LKCommonsLogging
import UniverseDesignDialog

class AudioCommonView: UIView, UserResolverWrapper {
    enum CommonCons {
        static let recordLengthLimit: TimeInterval = 5 * 60
        static let strongReminderTime: CGFloat = 10
        static let tipLabelBottomOffset: CGFloat = -12
        static let radiusTopOffset: CGFloat = 59
        static let languageLabelTopOffset: CGFloat = 195
    }

    // 打开面板的方式
    enum OpenType {
        case pressPanel(UILongPressGestureRecognizer)   // 在键盘Panel上长按icon，打开语音面板，会直接开始录音
        case tapPanel                                   // 在键盘panel上点击icon，可以选择开始录音
    }

    private static let logger = Logger.log(AudioCommonView.self, category: "AudioCommonView")
    let userResolver: UserResolver
    let openType: OpenType
    var radiusView: GestureView
    var canGesture: (() -> Bool)?

    // 录音开始时，覆盖在keyboard的panel上。
    lazy var maskPanelView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBodyOverlay
        return view
    }()

    // 录音开始时在 window 上放一个透明的遮罩
    // 录音松手时取下来
    lazy var audioMaskWindowView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }()

    // 录音开始时在 VC 上放一个透明的遮罩
    // 录音流程结束时取下来
    // 例如在语音加文字场景
    // 长按时：两个遮罩都加上。
    // 结束长按后：取下window的遮罩，此时chat内消息还是不能点击，但是能点击返回
    // 点击取消/发送后，取下vc遮罩，可以点击消息
    lazy var audioMaskVCView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    let feedbackGenerator: UIImpactFeedbackGenerator = {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.prepare()
        return feedbackGenerator
    }()

    init(userResolver: UserResolver, openType: OpenType) {
        self.userResolver = userResolver
        self.openType = openType
        radiusView = GestureView(isRadius: true)
        super.init(frame: .zero)
        Self.logger.info("init common view ")
    }

    deinit {
        Self.logger.info("deinit common view ")
    }

    func stopTapGesture() {
        radiusView.tapGesture.isEnabled = false
        radiusView.tapGesture.isEnabled = true
    }

    func stopLongGesture() {
        radiusView.longGesture.isEnabled = false
        radiusView.longGesture.isEnabled = true
    }

    func stopKeyboardLongGesture() {
        if case .pressPanel(let longPress) = openType {
            longPress.isEnabled = false
            longPress.isEnabled = true
        }
    }

    func presentFailAlert(from: EENavigator.NavigatorFrom?) {
        self.feedbackGenerator.impactOccurred()
        AudioUtils.presentFailAlert(userResolver: userResolver, from: from)
    }

    func checkGestureCanRecord() -> Bool {
        // 检查手势状态
        switch openType {
        case .pressPanel(let longPress):
            // 如果是icon长按，长按在 began 状态
            let result = longPress.state == .began
            Self.logger.info("checkGesture: \(result)")
            return result
        case .tapPanel:
            // 如果是 按钮长按，长按在 began 状态
            return radiusView.longGesture.state == .began
        }
    }

    @objc
    func longGestureHander(sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
            if AudioUtils.checkCallingState(userResolver: userResolver, from: self.window),
               AudioUtils.checkByteViewState(userResolver: userResolver, from: self.window),
               (canGesture?() ?? true) {
                self.startAudioRecord()
            } else {
                self.stopLongGesture() // 强制结束手势
            }
        case .failed, .cancelled, .ended, .possible:
            Self.logger.info("sender.state \(sender.state)")
            self.stopAudioRecord()
        case .changed:
            self.handleGestureMove()
        @unknown default:
            break
        }
    }

    func startAudioRecord() {
        assertionFailure("need override")
    }

    func stopAudioRecord() {
        assertionFailure("need override")
    }

    func handleGestureMove() {
        assertionFailure("need override")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // 白色遮罩，放在 keyboardPanel 上
    func handlePanelView(show: Bool, keyboardView: LKKeyboardView?, isMaskInput: Bool = true, bottomOffset: CGFloat = 0) {
        if !show {
            maskPanelView.subviews.forEach { view in
                view.removeFromSuperview()
            }
            maskPanelView.removeFromSuperview()
            return
        }
        guard maskPanelView.superview == nil,
              let keyboardView = keyboardView else { return }
        keyboardView.addSubview(maskPanelView)
        maskPanelView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(keyboardView.keyboardPanel.contentWrapper.snp.top).offset(bottomOffset)
            if isMaskInput {
                make.top.equalToSuperview()
            } else {
                make.top.equalTo(keyboardView.inputStackWrapper.snp.bottom)
            }
        }
    }

    // 透明遮罩，放在 window 上
    func handleMaskWindowView(show: Bool, keyboardView: UIView?) {
        if !show {
            audioMaskWindowView.removeFromSuperview()
            return
        }
        guard audioMaskWindowView.superview == nil,
              let keyboardView = keyboardView,
              let window = keyboardView.window
        else { return }
        window.addSubview(audioMaskWindowView)
        audioMaskWindowView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // 透明遮罩，放在 vc 上
    func handleMaskVCView(show: Bool, keyboardView: UIView?) {
        if !show {
            audioMaskVCView.removeFromSuperview()
            return
        }
        guard audioMaskVCView.superview == nil,
              let keyboardView = keyboardView,
              let vc = AudioUtils.getViewController(view: keyboardView) else { return }
        vc.view.addSubview(audioMaskVCView)
        audioMaskVCView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.bottom.equalTo(keyboardView.snp.top)
        }
    }

    func removeSelfFromKeyboard(keyboardView: LKKeyboardView?) {
        guard let keyboardView = keyboardView else { return }
        keyboardView.containerStackView.removeArrangedSubview(self)
        self.removeFromSuperview()
        keyboardView.keyboardPanel?.panelBarHidden = false
    }

    func insertSelfInKeyboard(keyboardView: LKKeyboardView?, view: UIView) {
        guard let keyboardView = keyboardView, keyboardView.containerStackView.arrangedSubviews.count >= 1 else { return }
        keyboardView.containerStackView.insertArrangedSubview(view, at: 1)
        view.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(72)
        }
        keyboardView.keyboardPanel.panelBarHidden = true
    }
}
