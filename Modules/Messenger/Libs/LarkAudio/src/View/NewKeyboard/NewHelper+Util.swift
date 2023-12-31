//
//  AudioKeyboardHelper+Util.swift
//  LarkAudio
//
//  Created by 李晨 on 2019/8/23.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import EditTextView
import LKCommonsLogging
// import LarkCore
import LarkKeyboardView
import LarkModel
import LarkSDKInterface
import LarkSensitivityControl
import CoreTelephony
import LarkSendMessage
import LarkLocalizations

// maskView
extension NewAudioKeyboardHelper {
    // 录音时 显示/隐藏 输入框
    func handleAudioMask(show: Bool, maskInputView: Bool, bottomOffset: Int = 46) {
        if self.maskViewLock { return }

        if show {
            guard let keyboardView = self.delegate?.audiokeybordPanelView() else { return }
            keyboardView.addSubview(self.audioMaskView)
            self.audioMaskView.snp.makeConstraints { (maker) in
                maker.left.right.equalToSuperview()
                maker.bottom.equalTo(keyboardView.keyboardPanel.contentWrapper.snp.top).offset(bottomOffset)
                if maskInputView {
                    maker.top.equalToSuperview()
                } else {
                    maker.top.equalTo(keyboardView.inputStackWrapper.snp.bottom)
                }
            }
            self.audioMaskView.layoutIfNeeded()
            UIView.animate(withDuration: 0.2, animations: {
                self.audioMaskView.alpha = 1
            })
        } else {
            audioMaskView.subviews.forEach { view in
                view.removeFromSuperview()
            }
            UIView.animate(withDuration: 0.2, animations: {
                self.audioMaskView.alpha = 0
            }) { (_) in
                self.audioMaskView.removeFromSuperview()
            }
        }
    }

    func handleClearTextView(show: Bool) {
        if show, canShowCaret {
            guard let textView = self.delegate?.audiokeybordPanelView().inputTextView else { return }
            if caretView.superview == nil {
                textView.addSubview(caretView)
            }
            moveCaretView(textView: textView)
        } else {
            caretView.removeFromSuperview()
        }

        func moveCaretView(textView: LarkEditTextView) {
            let inputSelectRange = textView.selectedRange
            textView.selectedRange = caretRange ?? inputSelectRange
            if let position = textView.selectedTextRange?.start {
               let rect = textView.caretRect(for: position)
                if rect.origin.x.isInfinite || rect.origin.y.isInfinite {
                    Self.logger.error("move caret rect is infinite")
                    caretView.removeFromSuperview()
                } else if caretView.superview != nil {
                    // bytest平台收到几例崩溃，都是在remake取不到superview，线上还没有遇到。所以此处再加一次拦截，观察一段时间
                    caretView.snp.remakeConstraints { make in
                        make.width.equalTo(rect.width)
                        make.height.equalTo(rect.height)
                        make.left.equalToSuperview().offset(rect.origin.x)
                        make.top.equalToSuperview().offset(rect.origin.y)
                    }
                } else {
                    Self.logger.error("caret can not find superview")
                }
            }
            textView.selectedRange = inputSelectRange
        }
    }

    func handleAIBackview(show: Bool) {
        if show {
            guard let keyboardView = self.delegate?.audiokeybordPanelView() else { return }
            keyboardView.addSubview(audioAIView)
            audioAIView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalTo(keyboardView.inputStackWrapper.snp.bottom)
                make.bottom.equalTo(keyboardView.snp.bottom)
            }
        } else {
            audioAIView.removeFromSuperview()
        }
    }

    // 录音时 隔绝手势
    func handleAudioGestureMask(show: Bool) {
        if show {
            guard let keyboardView = self.delegate?.audiokeybordPanelView() else { return }
            if let window = keyboardView.window {
                window.addSubview(self.audioGestureMaskView)
                self.audioGestureMaskView.snp.makeConstraints { (maker) in
                    maker.edges.equalToSuperview()
                }
            }
        } else {
            self.audioGestureMaskView.removeFromSuperview()
        }
    }

    /// 同时识别语音和文字的时候的 mask
    func handleAudioWithTextMask(show: Bool) {
        if show {
            guard let keyboardView = self.delegate?.audiokeybordPanelView() else { return }

            if let vc = getViewController(view: keyboardView) {
                vc.view.addSubview(self.audioWithTextMaskView)
                self.audioWithTextMaskView.snp.makeConstraints { (maker) in
                    maker.left.right.top.equalToSuperview()
                    maker.bottom.equalTo(keyboardView.snp.top)
                }
            }
        } else {
            self.audioWithTextMaskView.removeFromSuperview()
        }
    }
}

extension NewAudioKeyboardHelper {
    func insertAudioRecognizeInputView(uploadID: String) {
        if let keyboardView = self.delegate?.audiokeybordPanelView() {
            let viewCache = keyboardView.inputStackView.arrangedSubviews
            for view in viewCache {
                keyboardView.inputStackView.removeArrangedSubview(view)
                view.isHidden = true
            }
            recordTextKeyboardViewCache = viewCache
            let inputView = NewRecordWithTextInputView(
                userResolver: userResolver,
                uploadID: uploadID,
                chat: self.chat,
                recognizeService: self.audioRecognizeService)
            inputView.delegate = self
            inputView.keyboardView = keyboardView
            keyboardView.inputStackView.insertArrangedSubview(inputView, at: 0)
            inputView.snp.makeConstraints { (maker) in
                maker.left.right.equalToSuperview()
            }
            self.recordTextInputView = inputView
            self.recordTextButtonView = RecordWithTextButtonViewWithLID(userResolver: userResolver, delegate: self, textView: inputView.textView, sessionId: uploadID)
            keyboardView.keyboardPanel?.panelBarHidden = true

            /// 如果是 mac 风格输入框的话
            /// 插入 wraper view 用于动画
            if keyboardView.macInputStyle {
                let recordTextButtonWrapper = UIStackView()
                recordTextButtonWrapper.axis = .vertical
                self.recordTextButtonWrapper = recordTextButtonWrapper
                keyboardView.containerStackView.insertArrangedSubview(
                    recordTextButtonWrapper,
                    at: 1
                )
                recordTextButtonWrapper.snp.makeConstraints { (maker) in
                    maker.left.right.equalToSuperview()
                    maker.height.equalTo(0).priority(.low)
                }
            }
        }
        // 键盘弹起/收起时点击语音加文字按钮开始事件
        self.isVoiceBehaviorRelay.accept(true)
    }

    func cleanAudioRecognizeInputView() {
        if let keyboardView = self.delegate?.audiokeybordPanelView() {
            if let recordButtonView = self.recordTextButtonView {
                if let stackView = recordButtonView.stackView,
                    let actionView = recordButtonView.actionButton {
                    stackView.removeArrangedSubview(actionView)
                    actionView.removeFromSuperview()
                }
                self.recordTextButtonView = nil
            }

            if let recordTextButtonWrapper = self.recordTextButtonWrapper {
                keyboardView.containerStackView
                    .removeArrangedSubview(recordTextButtonWrapper)
                recordTextButtonWrapper.removeFromSuperview()
                self.recordTextButtonWrapper = nil
            }

            if let recordTextInputView = self.recordTextInputView {
                keyboardView.inputStackView
                    .removeArrangedSubview(recordTextInputView)
                recordTextInputView.removeFromSuperview()
            }

            for view in recordTextKeyboardViewCache.reversed() {
                keyboardView.inputStackView.insertArrangedSubview(view, at: 0)
                view.isHidden = false
            }
            recordTextKeyboardViewCache = []
            keyboardView.keyboardPanel?.panelBarHidden = false
        }
        self.handleAudioWithTextMask(show: false)
        // 键盘弹起/收起时语音加文字面板点击clean/发送/audio only的事件
        self.isVoiceBehaviorRelay.accept(false)
    }

    func cleanAudioRecognizeInputLoading() {
        if let recordTextInputView = self.recordTextInputView {
            recordTextInputView.cleanAudioRecognizeView()
        }
    }

    /// 移除长按出现的ASR键盘的对ASR识别结果的监听，防止在弱网时，用户结束一次录音之后快速开始第二次录音，
    /// 第一次结果就有可能展示在第二次的面板上，导致错误的结果
    func removeLongpressRecognizeMonitor() {
        Self.logger.info("enter removeLongpressRecognizeMonitor")
        guard let keyboard = self.longPressKeyboard else { return }
        Self.logger.info("remove LongpressRecognizeMonitor")
        keyboard.endTimer()
        keyboard.removeFromSuperview()
        self.longPressKeyboard = nil
    }

    func insertLongGestureButtonView(view: UIView, ishHiddenPanel: Bool = true) {
        if let keyboardView = self.delegate?.audiokeybordPanelView(),
           keyboardView.containerStackView.arrangedSubviews.count >= 1 {
            keyboardView.containerStackView.insertArrangedSubview(
                self.LongGestureButtonView,
                at: 1)
            self.LongGestureButtonView.snp.makeConstraints { (maker) in
                maker.left.right.equalToSuperview()
                maker.height.equalTo(72)
            }
            LongGestureButtonView.addSubview(view)
            view.snp.makeConstraints { make in
                make.bottom.equalToSuperview().offset(-7)
                make.height.equalTo(48)
                make.left.equalToSuperview().offset(8)
                make.right.equalToSuperview().offset(-8)
            }
            if ishHiddenPanel {
                keyboardView.keyboardPanel?.panelBarHidden = true
            }
        }
    }

    func cleanLongGestureButtonView(isHiddenPanel: Bool = true) {
        if let keyboardView = self.delegate?.audiokeybordPanelView() {
            keyboardView.containerStackView
                .removeArrangedSubview(LongGestureButtonView)
            LongGestureButtonView.removeFromSuperview()
            LongGestureButtonView.subviews.forEach { view in
                view.removeFromSuperview()
            }
            if isHiddenPanel {
                keyboardView.keyboardPanel?.panelBarHidden = false
            }
        }
    }

    func insertAudioRecognizeSpaceView(height: CGFloat = 70) {
        if let keyboardView = self.delegate?.audiokeybordPanelView(),
            keyboardView.containerStackView.arrangedSubviews.count >= 1 {
            keyboardView.containerStackView
                .insertArrangedSubview(
                    self.recognizeSpaceView,
                    at: keyboardView.containerStackView.arrangedSubviews.count - 1
            )
            self.recognizeSpaceView.snp.makeConstraints { (maker) in
                maker.left.right.equalToSuperview()
                maker.height.equalTo(height)
            }
        }
    }

    func cleanAudioRecognizeSpaceView() {
        if let keyboardView = self.delegate?.audiokeybordPanelView() {
            keyboardView.containerStackView
                .removeArrangedSubview(recognizeSpaceView)
            recognizeSpaceView.removeFromSuperview()
        }
    }

    func sendAudioWhenRecordWithText() {
        if let recordTextInputView = self.recordTextInputView,
            let audioData = recordTextInputView.audioData {
            let audioInfo = AudioDataInfo(
                data: audioData,
                length: recordTextInputView.duration,
                type: .opus,
                uploadID: recordTextInputView.uploadID
            )
            NewAudioKeyboardHelper.logger.info("send audio duration \(audioInfo.length)")

            AudioTracker.trackSendAudio(duration: TimeInterval(recordTextInputView.duration), sendType: .audioOnly)
            AudioTracker.selectSendAudioOnly()
            self.delegate?.audiokeybordSendMessage(audioInfo)
        }
    }

    func sendAudioWithTextWhenRecordWithText() {
        if let recordTextInputView = self.recordTextInputView,
            let audioData = recordTextInputView.audioData {
            let text = recordTextInputView.textView.text ?? ""
            let audioInfo = AudioDataInfo(
                data: audioData,
                length: recordTextInputView.duration,
                type: .opus,
                text: text.isEmpty ? nil : text,
                uploadID: recordTextInputView.uploadID)
            NewAudioKeyboardHelper.logger.info("send audio with text duration \(audioInfo.length) text length \(audioInfo.text?.count ?? 0)")
            AudioTracker.trackSendAudio(duration: TimeInterval(recordTextInputView.duration), sendType: .audioAndText)
            self.delegate?.audiokeybordSendMessage(audioInfo)
        }
    }

    func sendTextWhenRecordWithText() {
        if let recordTextInputView = self.recordTextInputView, let text = recordTextInputView.textView.text {
            NewAudioKeyboardHelper.logger.info("send text. length \(text.count)")
            self.delegate?.audioSendTextMessage(str: text)
        }
    }
}

extension NewAudioKeyboardHelper {

    func focusKeyboardInputView() {
        if let keyboardView = self.delegate?.audiokeybordPanelView() {
            // 键盘成为第一响应，并将标记位设置为true
            isEditTextViewByRecognize = true
            keyboardView.inputTextView.becomeFirstResponder()
        }
    }

    func saveRecognizeCacheText() {
        if let keyboardView = self.delegate?.audiokeybordPanelView() {
            self.recognizeCacheText = keyboardView.attributedString
        }
    }

    func sendMessageWhenRecognition() {
        self.delegate?.sendMessageWhenRecognition()
    }

    func cleanMessageWhenRecognition() {
        if let keyboardView = self.delegate?.audiokeybordPanelView() {
            keyboardView.attributedString = NSMutableAttributedString(string: "")
        }
    }

    func clearTextViewTintColor() {
        guard let keyboardView = self.delegate?.audiokeybordPanelView() else { return }
        self.currentTextViewTintColor = keyboardView.inputTextView.tintColor
        keyboardView.inputTextView.tintColor = UIColor.clear
    }

    func recoverTextViewTintColor() {
        guard let keyboardView = self.delegate?.audiokeybordPanelView() else { return }
        keyboardView.inputTextView.tintColor = self.currentTextViewTintColor
    }
}
// CTCall 工具方法
extension NewAudioKeyboardHelper {
    static func getCurrentCalls() -> Set<CTCall>? {
        do {
            return try DeviceInfoEntry.currentCalls(
                forToken: Token(withIdentifier: "LARK-PSDA-audio_record_check_call"),
                callCenter: CTCallCenter()
            )
        } catch {
            Self.logger.warn("Could not fetch currentCalls by LarkSensitivityControl API")
            return nil
        }
    }
}

// 普通工具
extension NewAudioKeyboardHelper {
    static func convertString(from language: Lang) -> String {
        switch language {
        case .zh_CN:
            return BundleI18n.LarkAudio.Lark_Chat_AudioToChinese
        case .en_US:
            return BundleI18n.LarkAudio.Lark_Chat_AudioToEnglish
        default:
            assertionFailure()
            return BundleI18n.LarkAudio.Lark_Chat_AudioToEnglish
        }
    }

    static func timeString(time: TimeInterval) -> String {
        // 更新时间
        let timeStr: String
        let time = Int(time)
        let second = time % 60
        let minute = time / 60
        let secondStr = String(format: "%02d", second)
        if minute == 0 {
            timeStr = "0:" + secondStr
        } else {
            timeStr = "\(minute):" + secondStr
        }
        return timeStr
    }

    static func addAudioCountDownView(view: UIView) -> AudioCountDownView {
        let countDownView = AudioCountDownView()
        if let topWindow = view.window {
            topWindow.addSubview(countDownView)
            countDownView.snp.makeConstraints { (maker) in
                maker.width.height.equalTo(110)
                maker.top.equalTo(105)
                maker.centerX.equalTo(view)
            }
        }
        return countDownView
    }
}
