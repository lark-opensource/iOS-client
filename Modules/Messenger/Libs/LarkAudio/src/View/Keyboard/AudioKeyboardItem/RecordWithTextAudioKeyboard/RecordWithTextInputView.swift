//
//  RecordWithTextInputView.swift
//  LarkAudio
//
//  Created by 李晨 on 2019/8/15.
//

import UIKit
import Foundation
import SnapKit
import LarkCore
import LarkKeyboardView
import EditTextView
import RxCocoa
import RxSwift
import LKCommonsLogging
import LarkSDKInterface
import LarkModel
import LarkContainer

protocol RecordWithTextInputViewDelegate: AnyObject {
    func recordWithTextInputViewShowAction(inputView: RecordWithTextInputView, sendEnabled: Bool)
    func recordWithTextInputViewTextChanged(inputView: RecordWithTextInputView)
    func recordWithTextInputViewEndEditing(inputView: RecordWithTextInputView)
}

final class RecordWithTextInputView: UIView, UITextViewDelegate, UserResolverWrapper {

    fileprivate static let logger = Logger.log(RecordWithTextInputView.self, category: "LarkAudio")

    weak var delegate: RecordWithTextInputViewDelegate?
    @ScopedInjectedLazy var audioTracker: NewAudioTracker?
    let textView: LarkEditTextView = LarkEditTextView()
    let textViewWraper: UIView = UIView()
    let timeLabel: UILabel = UILabel()
    let timeIcon: UIImageView = UIImageView()
    let lanageLabel: UILabel = UILabel()
    let spaceView: UILabel = UILabel()

    var uploadID: String
    var audioData: Data?
    var recognizeService: AudioRecognizeService?
    var audioDisposeBag = DisposeBag()
    var stackView = UIStackView()
    var loadingView: AudioRecognizingView?
    var receviceResult: Bool = true

    var isPrepare: Bool = true {
        didSet {
            if let loadingView = self.loadingView, self.isPrepare != oldValue {
                loadingView.text = self.loadingText()
            }
        }
    }

    var duration: TimeInterval = 0 {
        didSet {
            let time = Int(self.duration)
            let second = time % 60
            let minute = time / 60
            if minute == 0 {
                self.timeLabel.text = "\(second)\""
            } else {
                self.timeLabel.text = "\(minute)\'\(second)\""
            }
        }
    }
    weak var keyboardView: LKKeyboardView?
    private(set) var lastAudioRecognize: AudioRecognizeResult?
    private var showLoadingState: Bool = true
    private var showSpaceWhenStart: Bool
    /// 是否还是第一次非空结果，用来第一次非空结果时埋点使用
    private var isFirstRecognizeResult: Bool = true
    private let chat: Chat
    let userResolver: UserResolver
    init(userResolver: UserResolver,
         uploadID: String,
         chat: Chat,
         recognizeService: AudioRecognizeService?,
         showSpaceWhenStart: Bool) {
        self.userResolver = userResolver
        self.uploadID = uploadID
        self.chat = chat
        self.showSpaceWhenStart = showSpaceWhenStart
        self.recognizeService = recognizeService
        super.init(frame: .zero)
        self.setupSubViews()
        self.observeRecognizeAudio()
        self.updateAudioRecognize(
            text: "",
            finish: false,
            diffIndexSlice: [])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupSubViews() {
        stackView.spacing = 0
        stackView.axis = .vertical
        addSubview(stackView)
        stackView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }

        let headerView = UIView()
        stackView.addArrangedSubview(headerView)
        headerView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        headerView.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.height.equalTo(27).priority(.required)
        }

        headerView.addSubview(timeLabel)
        timeLabel.textColor = UIColor.ud.textPlaceholder
        timeLabel.text = "0'"
        timeLabel.font = UIFont.systemFont(ofSize: 14)
        timeLabel.snp.makeConstraints { (maker) in
            maker.bottom.equalToSuperview()
            maker.left.equalTo(37)
        }

        headerView.addSubview(timeIcon)
        timeIcon.image = Resources.recordTime
        timeIcon.snp.makeConstraints { (maker) in
            maker.centerY.equalTo(timeLabel)
            maker.left.equalTo(16)
        }

        headerView.addSubview(lanageLabel)
        lanageLabel.textColor = UIColor.ud.textPlaceholder
        lanageLabel.font = UIFont.systemFont(ofSize: 11)
        lanageLabel.snp.makeConstraints { (maker) in
            maker.centerY.equalTo(timeLabel)
            maker.right.equalTo(-12)
        }

        if RecognizeLanguageManager.shared.recognitionLanguage == .un_AUTO {
            lanageLabel.text = BundleI18n.LarkAudio.Lark_IM_AudioToTextDetectLanguage_DetectingNotice
        } else {
            let languageName: String = RecognizeLanguageManager.shared.recognitionLanguageI18n
            lanageLabel.text = BundleI18n.LarkAudio.Lark_Chat_AudioRecognitionLanguageTip(languageName)
        }

        stackView.addArrangedSubview(textViewWraper)
        textViewWraper.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        textViewWraper.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
        }

        textViewWraper.addSubview(textView)
        textView.defaultTypingAttributes = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.ud.textTitle
        ]
        textView.isScrollEnabled = false
        textView.backgroundColor = UIColor.clear
        textView.placeholder = BundleI18n.LarkAudio.Lark_Legacy_SendTip(chat.displayName)
        textView.delegate = self
        textView.placeholderTextColor = UIColor.ud.textPlaceholder
        textView.contentInset = .zero
        textView.textColor = UIColor.ud.textTitle
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.snp.makeConstraints { (maker) in
            maker.top.bottom.equalToSuperview()
            maker.right.equalTo(-8)
            maker.left.equalTo(8)
            maker.height.greaterThanOrEqualTo(showSpaceWhenStart ? 37 : 94)
            maker.height.lessThanOrEqualTo(125)
        }
    }

    @inline(__always)
    private func loadingText() -> String {
        return isPrepare ? BundleI18n.LarkAudio.Lark_Chat_PrepareRecordAudio : BundleI18n.LarkAudio.Lark_Chat_AudioToTextSpeakTip
    }

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        self.keyboardView?.keyboardPanel.observeKeyboard = true
        self.delegate?.recordWithTextInputViewShowAction(inputView: self, sendEnabled: !textView.text.isEmpty)
        self.cleanAudioRecognizeView()
        self.receviceResult = false
        AudioTracker.imChatVoiceMsgClick(click: .clickInput, viewType: .audioWithText)
        /// ASR识别完成后编辑时间的上报
        audioTracker?.asrFinishThenEdit(sessionId: self.uploadID)
        return true
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        self.keyboardView?.keyboardPanel.observeKeyboard = true
    }

    func textViewDidChange(_ textView: UITextView) {
        self.delegate?.recordWithTextInputViewTextChanged(inputView: self)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        self.keyboardView?.keyboardPanel.observeKeyboard = false
        self.delegate?.recordWithTextInputViewEndEditing(inputView: self)
    }

    fileprivate func observeRecognizeAudio() {
        self.recognizeService?
            .result
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (result) in
                guard let `self` = self else { return }
                if result.uploadID != self.uploadID || !self.receviceResult {
                    return
                }
                if let lastAudioRecognize = self.lastAudioRecognize,
                    !result.finish,
                    lastAudioRecognize.text == result.text,
                    lastAudioRecognize.diffIndexSlice == result.diffIndexSlice {
                    return
                }
                self.lastAudioRecognize = result
                if !result.text.isEmpty {
                    // 上报第一次非空结果上屏的时间
                    if self.isFirstRecognizeResult {
                        self.audioTracker?.asrFirstPartialOnScreen(sessionId: self.uploadID)
                        AudioReciableTracker.shared.audioRecognitionFirstResultAppear(sessionID: self.uploadID)
                        self.isFirstRecognizeResult = false
                    }
                    // 上报一次ASR最后的识别结果上屏的时间
                    if result.finish {
                        self.audioTracker?.asrFinalResultOnScreen(sessionId: self.uploadID)
                    }
                    self.updateAudioRecognize(
                        text: result.text,
                        finish: result.finish,
                        diffIndexSlice: result.diffIndexSlice)
                } else {
                    // 一次ASR结束时 没有识别结果
                    if result.finish {
                        self.audioTracker?.asrFinalResultEmpty(sessionId: self.uploadID)
                    }
                }
            }, onError: { (error) in
                RecordWithTextInputView.logger.error("audio recognize failed", error: error)
            }).disposed(by: self.audioDisposeBag)
    }

    fileprivate func updateAudioRecognize(text: String, finish: Bool, diffIndexSlice: [Int32] = []) {
        let attributedText = NSMutableAttributedString(string: text)
        attributedText.addAttributes(textView.defaultTypingAttributes, range: NSRange(location: 0, length: attributedText.length))

        if showLoadingState {
            // 显示加载中
            if !finish, let attachmentText = self.loadingViewWith(text: text) {
                attributedText.append(attachmentText)
            }

            // 显示未确定标记
            var diffStartIndex = attributedText.length
            let sorted = diffIndexSlice.sorted(by: { $0 > $1 })
            sorted.forEach { (index) in
                if index == diffStartIndex - 1 {
                    diffStartIndex = Int(index)
                }
            }
            // 最短添加3个字符的未确定
            if diffStartIndex > attributedText.length - 3 && attributedText.length >= 3 {
                diffStartIndex = attributedText.length - 3
            }

            let diffOffset = attributedText.length - diffStartIndex
            if diffOffset > 0 && !finish {
                attributedText.addAttribute(
                    .foregroundColor,
                    value: UIColor.ud.textTitle,
                    range: NSRange(location: diffStartIndex, length: diffOffset)
                )
            }
        }
        textView.attributedText = attributedText
        let contentOffset = CGPoint(x: 0, y: textView.contentSize.height - textView.frame.height)
        if contentOffset.y > 0 {
            textView.setContentOffset(contentOffset, animated: false)
        }
    }

    private func loadingViewWith(text: String) -> NSAttributedString? {
        if self.loadingView == nil {
            let loadingView = AudioRecognizingView(text: self.loadingText())
            self.loadingView = loadingView
        }
        guard let loadingView = self.loadingView else { return nil }
        loadingView.startAnimationIfNeeded()
        if text.isEmpty {
            loadingView.text = self.loadingText()
        } else {
            loadingView.text = ""
        }
        var attachmentBounds = loadingView.attachmentBounds
        if let font = self.textView.font {
            attachmentBounds.origin.y = font.descender
        }
        let attachment = CustomTextAttachment(customView: loadingView, bounds: attachmentBounds)
        let attachmentText = NSMutableAttributedString(attachment: attachment)
        attachmentText.addAttributes(textView.defaultTypingAttributes, range: NSRange(location: 0, length: attachmentText.length))
        return attachmentText
    }

    func cleanAudioRecognizeView() {
        if let lastResut = self.lastAudioRecognize {
            let attributedText = NSMutableAttributedString(string: lastResut.text)
            attributedText.addAttributes(textView.defaultTypingAttributes, range: NSRange(location: 0, length: attributedText.length))
            textView.attributedText = attributedText
            self.lastAudioRecognize = nil
        } else {
            textView.attributedText = NSMutableAttributedString(string: "")
        }
        self.showLoadingState = false
    }
}
