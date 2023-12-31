//
//  RecognizeTextView.swift
//  LarkAudio
//
//  Created by kangkang on 2023/10/8.
//

import Foundation
import EditTextView
import LarkContainer
import LarkKeyboardView

// 语音加文字的输入框
final class RecognizeTextView: UIView {

    weak var keyboardView: LKKeyboardView?
    let textView: LarkEditTextView = LarkEditTextView()
    private let attachmentText = RecognizeAttachmentTextFactory()
    private let userResolver: UserResolver
    private let chatName: String
    private var isReady: Bool = false
    private var lastResult: String = ""
    private var canUpdateText: Bool = true

    var inputState: InputDisplayState = .over {
        didSet {
            switch inputState {
            case .voiceAndRecognizing: // 按压中，说话并且在识别
                start()
            case .recognizing:         // 未在按压，但仍在识别剩余文字
                end()
            case .over:                // 未在按压，不再接收识别的文字（识别完成或被打断）
                 over()
            }
        }
    }

    init(userResolver: UserResolver, chatName: String) {
        self.userResolver = userResolver
        self.chatName = chatName
        super.init(frame: .zero)
        setupSubViews()
    }

    private func setupSubViews() {
        self.addSubview(textView)
        textView.defaultTypingAttributes = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.ud.textTitle
        ]
        textView.isScrollEnabled = false
        textView.backgroundColor = UIColor.clear
        textView.placeholder = BundleI18n.LarkAudio.Lark_Legacy_SendTip(chatName)
        textView.placeholderTextColor = UIColor.ud.textPlaceholder
        textView.contentInset = .zero
        textView.textColor = UIColor.ud.textTitle
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
            make.top.equalToSuperview().offset(4)
            make.bottom.equalToSuperview().offset(-4)
            make.height.greaterThanOrEqualTo(36)
            make.height.lessThanOrEqualTo(125)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func hasReady() {
        isReady = true
        updateText(text: "", finish: false)
    }

    func updateText(text: String, finish: Bool, diffIndexSlice: [Int32] = []) {
        guard let keyboardView, canUpdateText else { return }
        lastResult = text
        var loadingView: NSAttributedString?
        if inputState == .voiceAndRecognizing {
            loadingView = attachmentText.loadingViewString(showReady: !isReady, showSpeakTip: text.isEmpty, font: keyboardView.inputTextView.font,
                                                           defaultTypingAttributes: keyboardView.inputTextView.defaultTypingAttributes)
        }
        let (recognizeText, _, _) = attachmentText.getText(text: text, finish: finish, diffIndexSlice: diffIndexSlice,
                                                           typingAttributes: keyboardView.inputTextView.defaultTypingAttributes, loading: loadingView)
        textView.attributedText = recognizeText
        let contentOffset = CGPoint(x: 0, y: textView.contentSize.height - textView.frame.height)
        if contentOffset.y > 0 {
            textView.setContentOffset(contentOffset, animated: false)
        }
    }

    private func start() {
        lastResult = ""
        cleanAudioRecognizeView()
        isReady = false
        canUpdateText = true
        updateText(text: "", finish: false)
    }

    private func end() {
        canUpdateText = true
        cleanAudioRecognizeView()
    }

    private func over() {
        canUpdateText = false
        cleanAudioRecognizeView()
    }

    private func cleanAudioRecognizeView() {
        let attributedText = NSMutableAttributedString(string: lastResult)
        attributedText.addAttributes(textView.defaultTypingAttributes, range: NSRange(location: 0, length: attributedText.length))
        textView.attributedText = attributedText
    }
}
