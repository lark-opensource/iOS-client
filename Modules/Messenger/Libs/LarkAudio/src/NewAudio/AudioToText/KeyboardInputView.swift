//
//  RecognizeKeyboardView.swift
//  LarkAudio
//
//  Created by kangkang on 2023/11/3.
//

import Foundation
import EditTextView
import LarkKeyboardView
import LKCommonsLogging

enum InputDisplayState {
    case voiceAndRecognizing// 说话并且识别中
    case recognizing        // 没说话，在识别剩余中
    case over               // 识别结束
}

// 控制显隐「...」、光标、提示文字
final class KeyboardInputView {
    private static let logger = Logger.log(KeyboardInputView.self, category: "KeyboardInputView")
    private let attachmentText = RecognizeAttachmentTextFactory()
    private let caretView = CaretView() // 光标View
    // 输入框内原本的文字
    private var recognizeCacheText: NSAttributedString?
    // 输入框最后一次选择区域
    private var lastSelectRange: NSRange?
    // 不确定的 diff 区域
    private var lastDiffRange: NSRange?
    // 硬件是否准备好
    private var isReady: Bool = false
    // 是否可以展示光标
    private var canShowCaret: Bool = false
    // 文字是否可以上屏
    private var canUpdateText: Bool = true

    weak var keyboardView: LKKeyboardView?

    var inputState: InputDisplayState {
        get {
            return _inputState
        }
        set {
            let canChange: Bool
            switch (_inputState, newValue) {
            case (.over, .voiceAndRecognizing), (.recognizing, .voiceAndRecognizing), (.voiceAndRecognizing, .recognizing), (_, .over): canChange = true
            default: canChange = false
            }
            if canChange {
                _inputState = newValue
            } else {
                Self.logger.error("inputState change failed, old: \(_inputState), new: \(newValue)")
                assertionFailure()
            }
        }
    }
    var _inputState: InputDisplayState = .over {
        didSet {
            switch inputState {
            case .voiceAndRecognizing:  // 按压中，说话并且在识别
                start()
            case .recognizing:          // 未在按压，但仍在识别剩余文字
                end()
            case .over:                 // 未在按压，不再接收识别的文字（识别完成或被打断）
                over()
            }
        }
    }

    init() { }

    /// 开始按压时调用
    /// 展示「...」、展示提示文字、隐藏光标
    private func start() {
        cleanAudioRecognizeView()
        recognizeCacheText = keyboardView?.attributedString
        lastSelectRange = keyboardView?.inputTextView.selectedRange
        isReady = false
        canUpdateText = true
        updateText(text: "", finish: false, diffIndexSlice: [])
        handleCaretView(show: false)
    }

    /// 结束按压时调用
    /// 隐藏「...」、隐藏提示文字、展示光标、依然可以更新文字
    private func end() {
        canUpdateText = true
        cleanAudioRecognizeView()
        keyboardView?.layoutIfNeeded()
        handleCaretView(show: true)
    }

    /// 隐藏「...」、隐藏提示文字、展示光标、不可以更新文字
    private func over() {
        canUpdateText = false
        cleanAudioRecognizeView()
        // 确认光标位置
        // 确认下点击“取消后”lastSelectRange会不会被设置为 nil
        lastSelectRange = keyboardView?.inputTextView.selectedRange
        keyboardView?.layoutIfNeeded()
        handleCaretView(show: true)
    }

    /// 更新文字进入输入框
    /// 修改lastSelectRange、caretRange、lastDiffRange
    func updateText(text: String, finish: Bool, diffIndexSlice: [Int32]) {
        guard let keyboardView, canUpdateText else { return }
        // 输入框原本的文字
        let keyboardText = NSMutableAttributedString(attributedString: self.recognizeCacheText ?? NSAttributedString(string: ""))
        var loadingAttr: NSAttributedString?
        if inputState == .voiceAndRecognizing {
            loadingAttr = attachmentText.loadingViewString(showReady: !isReady, showSpeakTip: (text.isEmpty && recognizeCacheText?.string.isEmpty ?? true),
                                                           font: keyboardView.inputTextView.font, defaultTypingAttributes: keyboardView.inputTextView.defaultTypingAttributes)
        }
        // 识别到的文字
        let (recognizeText, lastDiffRange, notLoadingLength) = attachmentText.getText(text: text, finish: finish, diffIndexSlice: diffIndexSlice,
                                                                                      typingAttributes: keyboardView.inputTextView.defaultTypingAttributes, loading: loadingAttr)
        // 两种文字组合，添加进输入框
        let lastSelectLocation: Int
        if let lastSelectRange, lastSelectRange.location + lastSelectRange.length <= keyboardText.length {
            if let lastDiffRange {
                self.lastDiffRange = NSRange(location: lastSelectRange.location + lastDiffRange.location, length: lastDiffRange.length)
            }
            if lastSelectRange.length == 0 {
                keyboardText.insert(recognizeText, at: lastSelectRange.location)
            } else {
                keyboardText.replaceCharacters(in: lastSelectRange, with: recognizeText)
            }
            let length = (text.isEmpty) ? 0 : (finish ? recognizeText.length : notLoadingLength)
            lastSelectLocation = lastSelectRange.location + length
        } else {
            if let lastDiffRange {
                self.lastDiffRange = NSRange(location: keyboardText.length + lastDiffRange.location, length: lastDiffRange.length)
            }
            keyboardText.append(recognizeText)
            lastSelectLocation = keyboardText.length
        }
        keyboardView.inputTextView.attributedText = keyboardText
        // 设置输入框偏移值
        let contentOffset = CGPoint(x: 0, y: keyboardView.inputTextView.contentSize.height - keyboardView.inputTextView.frame.height)
        keyboardView.inputTextView.setContentOffset(contentOffset, animated: false)
        keyboardView.inputTextView.selectedRange = NSRange(location: lastSelectLocation, length: 0)

        if finish {
            lastSelectRange = NSRange(location: lastSelectLocation, length: 0)
        }
        if inputState == .recognizing || inputState == .over {
            keyboardView.layoutIfNeeded()
            self.handleCaretView(show: true)
        } else {
            self.handleCaretView(show: false)
        }
    }

    func replaceAllText(text: String) {
        guard let keyboardView else { return }
        let attributedText = NSMutableAttributedString(string: text)
        attributedText.addAttributes(keyboardView.inputTextView.defaultTypingAttributes, range: NSRange(location: 0, length: attributedText.length))
        keyboardView.inputTextView.attributedText = attributedText
        let contentOffset = CGPoint(x: 0, y: keyboardView.inputTextView.contentSize.height - keyboardView.inputTextView.frame.height)
        keyboardView.inputTextView.setContentOffset(contentOffset, animated: false)

        lastSelectRange = keyboardView.inputTextView.selectedRange
        if inputState == .recognizing || inputState == .over {
            keyboardView.layoutIfNeeded()
            self.handleCaretView(show: true)
        } else {
            self.handleCaretView(show: false)
        }
    }

    /// 硬件是否准备就绪
    /// 修改isReady
    func hasReady() {
        isReady = true
        updateText(text: "", finish: false, diffIndexSlice: [])
    }

    /// 面板在展示就可见，面板不在展示就不可见
    /// 修改canShowCaret
    func canShowCaret(_ can: Bool) {
        canShowCaret = can
        handleCaretView(show: can)
    }

    /// 点击输入框
    /// 修改lastSelectRange、caretRange
    func textViewDidBeginEditing() {
        lastSelectRange = keyboardView?.inputTextView.selectedRange
        self.handleCaretView(show: false)
    }

    private func handleCaretView(show: Bool) {
        if show, canShowCaret {
            guard let textView = keyboardView?.inputTextView else { return }
            if caretView.superview == nil {
                textView.addSubview(caretView)
            }
            if let position = textView.selectedTextRange?.start {
               let rect = textView.caretRect(for: position)
                if rect.origin.x.isInfinite || rect.origin.y.isInfinite {
                    Self.logger.error("rect is infinite")
                    caretView.removeFromSuperview()
                }
                caretView.snp.remakeConstraints { make in
                    make.width.equalTo(rect.width)
                    make.height.equalTo(rect.height)
                    make.left.equalToSuperview().offset(rect.origin.x)
                    make.top.equalToSuperview().offset(rect.origin.y)
                }
            }
        } else {
            if caretView.superview != nil {
                caretView.removeFromSuperview()
            }
        }
    }

    // 清空输入框的「...」和 diff 灰色文字
    private func cleanAudioRecognizeView() {
        guard let keyboardView = keyboardView else { return }
        let tempSelectRange = keyboardView.inputTextView.selectedRange
        let attributedText = NSMutableAttributedString(attributedString: keyboardView.inputTextView.attributedText)

        let result = attachmentText.cleanDiffAndLoading(attributedText: attributedText, diffRange: lastDiffRange, attrs: keyboardView.inputTextView.defaultTypingAttributes)
        self.lastDiffRange = nil

        // 设置 keyboard 文字
        keyboardView.inputTextView.attributedText = result

        // 设置输入框偏移量
        let offset = CGPoint(x: 0, y: keyboardView.inputTextView.contentSize.height - keyboardView.inputTextView.frame.height)
        keyboardView.inputTextView.setContentOffset(offset, animated: true)
        keyboardView.inputTextView.selectedRange = tempSelectRange
    }
}
