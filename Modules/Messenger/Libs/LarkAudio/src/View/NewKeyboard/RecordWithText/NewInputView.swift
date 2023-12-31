//
//  NewRecordWithTextInputView.swift
//  LarkAudio
//
//  Created by 李晨 on 2019/8/15.
//

import UIKit
import Foundation
import SnapKit
import LarkKeyboardView
import EditTextView
import RxCocoa
import RxSwift
import LKCommonsLogging
import LarkSDKInterface
import LarkModel
import LarkContainer
import UniverseDesignColor

protocol NewRecordWithTextInputViewDelegate: AnyObject {
    func recordWithTextInputViewShowAction(inputView: NewRecordWithTextInputView, sendEnabled: Bool)
    func recordWithTextInputViewTextChanged(inputView: NewRecordWithTextInputView)
    func recordWithTextInputViewEndEditing(inputView: NewRecordWithTextInputView)
}

final class NewRecordWithTextInputView: UIView, UITextViewDelegate, UserResolverWrapper {

    fileprivate static let logger = Logger.log(NewRecordWithTextInputView.self, category: "LarkAudio")

    weak var delegate: NewRecordWithTextInputViewDelegate?
    @ScopedInjectedLazy var audioTracker: NewAudioTracker?
    let textView: LarkEditTextView = LarkEditTextView()
    let textViewWraper: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgBody
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()
    let waveBackView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()
    let timeLabel: UILabel = UILabel()
    let waveView = WaveView()
    let tempMaskView = UIView()
    var uploadID: String
    var audioData: Data?
    var recognizeService: AudioRecognizeService?
    var audioDisposeBag = DisposeBag()
    var stackView = UIStackView()
    var loadingView: AudioRecognizingView?
    var receviceResult: Bool = true
    let backActiveColor = UDColor.getValueByKey(UDColor.Name("imtoken-message-bg-bubbles-blue")) ?? UDColor.rgb(0xD1E3FF) & UDColor.rgb(0x133063)
    let backDeactiveColor = UDColor.udtokenReactionBgGreyFloat

    var isPrepare: Bool = true {
        didSet {
            if let loadingView = self.loadingView, self.isPrepare != oldValue {
                loadingView.text = self.loadingText()
            }
        }
    }

    var duration: TimeInterval = 0 {
        didSet {
            let timeStr: String
            let time = Int(duration)
            let second = time % 60
            let minute = time / 60
            let secondStr = String(format: "%02d", second)
            if minute == 0 {
                timeStr = "0:" + secondStr
            } else {
                timeStr = "\(minute):" + secondStr
            }
            timeLabel.text = timeStr
        }
    }
    weak var keyboardView: LKKeyboardView?
    private(set) var lastAudioRecognize: AudioRecognizeResult?
    private var showLoadingState: Bool = true
    /// 是否还是第一次非空结果，用来第一次非空结果时埋点使用
    private var isFirstRecognizeResult: Bool = true
    private let chat: Chat
    let userResolver: UserResolver
    init(userResolver: UserResolver,
         uploadID: String,
         chat: Chat,
         recognizeService: AudioRecognizeService?) {
        self.userResolver = userResolver
        self.uploadID = uploadID
        self.chat = chat
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
        self.backgroundColor = UIColor.ud.bgBodyOverlay
        stackView.spacing = 8
        stackView.axis = .vertical
        addSubview(stackView)
        stackView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }

        let headerView = UIView()
        stackView.addArrangedSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(0.1)
        }

        stackView.addArrangedSubview(textViewWraper)
        textViewWraper.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        textViewWraper.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().offset(8)
            maker.right.equalToSuperview().offset(-8)
        }

        textViewWraper.addSubview(textView)
        textView.defaultTypingAttributes = [
            .font: UIFont.systemFont(ofSize: 17),
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
            maker.top.equalToSuperview().offset(4)
            maker.bottom.equalToSuperview().offset(-4)
            maker.right.equalTo(-8)
            maker.left.equalTo(8)
            maker.height.greaterThanOrEqualTo(36)
            maker.height.lessThanOrEqualTo(125)
        }

        stackView.addArrangedSubview(waveBackView)
        waveBackView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
        }
        // 用来定位 WaveView 的 center 位置
        let tempCenterView = UIView()
        let tempMaskBackView = UIView()
        timeLabel.font = UIFont.systemFont(ofSize: 14)
        timeLabel.textColor = UDColor.functionInfoContentDefault
        waveBackView.backgroundColor = backActiveColor
        tempMaskBackView.backgroundColor = UDColor.bgBodyOverlay
        tempMaskView.backgroundColor = waveBackView.backgroundColor
        waveBackView.addSubview(tempCenterView)
        waveBackView.addSubview(waveView)
        waveBackView.addSubview(tempMaskBackView)
        waveBackView.addSubview(tempMaskView)
        waveBackView.addSubview(timeLabel)
        tempCenterView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(7)
            make.left.equalToSuperview().offset(1)
            make.bottom.equalToSuperview().offset(-7)
            make.right.equalToSuperview().offset(-55)
            make.height.equalTo(28)
        }

        tempMaskView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.width.equalTo(9)
            make.height.equalTo(28)
            make.centerY.equalToSuperview()
        }
        tempMaskBackView.snp.makeConstraints { make in
            make.edges.equalTo(tempMaskView)
        }
        timeLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-12)
        }
        waveView.snp.makeConstraints { make in
            make.center.equalTo(tempCenterView)
            make.width.equalTo(28)
            make.height.equalTo(tempCenterView.snp.width)
        }
        // wave是tableView。所以旋转90度
        waveView.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
        waveView.start()
    }

    func updateDecible(decible: Float) {
        waveView.addDecible(decible)
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
                NewRecordWithTextInputView.logger.error("audio recognize failed", error: error)
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

        waveBackView.backgroundColor = backDeactiveColor
        tempMaskView.backgroundColor = waveBackView.backgroundColor
        waveView.stop()
        waveView.changeColor(color: UDColor.textCaption)
        timeLabel.textColor = UDColor.textCaption
    }
}
