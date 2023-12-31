//
//  AudioKeyboardHelper.swift
//  LarkAudio
//
//  Created by 李晨 on 2019/7/24.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import RxRelay
import EditTextView
import LarkLocalizations
import LKCommonsLogging
import LarkCore
import LarkBaseKeyboard
import LarkKeyboardView
import LarkModel
import LarkSDKInterface
import LarkSendMessage
import LarkMessengerInterface
import LarkContainer
import LarkChatOpenKeyboard

public protocol AudioKeyboardHelperDelegate: AnyObject {
    func audiokeybordPanelView() -> LKKeyboardView
    func sendMessageWhenRecognition()
    func audiokeyboardRecordIndicatorShowIn() -> UIViewController?
    func audiokeybordSendMessage(_ audioData: AudioDataInfo)
    func audiokeybordSendMessage(audioInfo: StreamAudioInfo)
    func audioSendTextMessage(str: String)
    func handleAudioKeyboardAppear()
}

/*
audio 拥有与输入框的复杂的交互，在使用的时候需要根据需求主动调用一下几个方法
 1. cleanAudioRecognizeState 清除输入框中正在识别的状态
 2. cleanMaskView 清除 mask view
 3. 发送消息调用 trackAudioRecognizeIfNeeded 打点
 */
// swiftlint:disable all
public final class AudioKeyboardHelper: NSObject, UITextViewDelegate, EditTextViewTextDelegate, UserResolverWrapper, AudioRecordPanelProtocol {

    static let logger = Logger.log(AudioKeyboardHelper.self, category: "Module.Inputs")

    public weak var delegate: AudioKeyboardHelperDelegate? {
        didSet {
            self.setupObserver()
        }
    }
    // 是否在语音中
    let isVoiceBehaviorRelay: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)

    public var isVoice: Bool {
        return self.isVoiceBehaviorRelay.value
    }
    public var isVoiceObservable: Observable<Bool> {
        return isVoiceBehaviorRelay.asObservable()
    }

    @ScopedInjectedLazy var audioPlayMediator: AudioPlayMediator?
    @ScopedInjectedLazy var audioRecognizeService: AudioRecognizeService?
    @ScopedInjectedLazy var resourceAPI: ResourceAPI?
    @ScopedInjectedLazy var audioAPI: AudioAPI?
    @ScopedInjectedLazy var audioTracker: NewAudioTracker?

    public let chat: Chat
    public let audioToTextEnable: Bool
    public let audioWithTextEnable: Bool
    public var iconTintColor: UIColor?

    // 本次是否存在语音识别结果
    var hasAudioRecognize: Bool = false
    // 是否编辑过语音识别的结果
    var hasEditRecognizeResult: Bool = false
    // 正在识别的语音资源id
    var recognizeAudioID: String?
    // 最后一次识别的结果
    var lastAudioRecognize: AudioRecognizeResult?
    // 是否显示正在识别状态
    var showAudioRecognizeLoading: Bool = false
    // 输入框内原本的文字
    var recognizeCacheText: NSAttributedString?
    // 输入框最后一次选择区域
    var lastSelectRange: NSRange?
    // 不确定的 diff 区域
    var lastDiffRange: NSRange?
    // 用于锁住 maskView
    var maskViewLock: Bool = false
    // 记录当前 textView tintColor
    var currentTextViewTintColor: UIColor = UIColor.systemBlue
    // 记录当前编辑输入框是语音识别到的，还是手动输入的;true:语音识别到;false:手动输入的
    var isEditTextViewByRecognize: Bool = false

    var loadingView: AudioRecognizingView?
    var audioDisposeBag = DisposeBag()

    var recordTextKeyboardViewCache: [UIView] = []
    var recordTextInputView: RecordWithTextInputView?
    var recordTextButtonWrapper: UIStackView?
    var recordTextButtonView: BaseRecordWithTextButtonView?
    var recognizeLanguageView: UIView?
    var recognizeSpaceView: UIView = UIView()

    weak var audioContainer: AudioCollectionContainerView?

    /// 是否还是语音转文字的第一次非空结果，第一次非空结果时埋点使用
    var isRecognizeFirstResult: Bool = true
    /// 一次语音识别是否收到尾包
    var audioRecognizeFinshed: Bool?

    weak var longPressKeyboard: RecognizeAudioTextGestureKeyboard?

    var longPressKeyboardAudioToTextHandler: (UILongPressGestureRecognizer) -> RecognizeAudioTextGestureKeyboard { { gesture in
        let recordWithTextVM = AudioWithTextRecordViewModel(
            userResolver: self.userResolver,
            audioRecognizeService: self.audioRecognizeService,
            from: .audioButton
        )
        let recordView = RecognizeAudioTextGestureKeyboard(userResolver: self.userResolver,
                                                           viewModel: recordWithTextVM,
                                                           gesture: gesture,
                                                           delegate: self)
        self.longPressKeyboard = recordView
        return recordView
    }
    }

    var disposeBag = DisposeBag()

    public var updateIconCallBack: (((UIImage?, UIImage?, UIImage?)) -> Void)?

    lazy var audioMaskView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBodyOverlay
        return view
    }()
    lazy var audioGestureMaskView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }()
    lazy var audioWithTextMaskView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }()
    var inputTextViewText: String?
    public let userResolver: UserResolver
    public init(userResolver: UserResolver,
                chat: Chat,
                audioToTextEnable: Bool,
                audioWithTextEnable: Bool) {
        self.userResolver = userResolver
        self.chat = chat
        self.audioToTextEnable = audioToTextEnable
        self.audioWithTextEnable = audioWithTextEnable
        super.init()
        self.audioRecognizeService?.bindChatId(chatId: chat.id)
    }

    func setupObserver() {
        self.disposeBag = DisposeBag()
        guard let keyboardView = self.delegate?.audiokeybordPanelView() else { return }
        keyboardView.inputTextView.delegate = self
        keyboardView.inputTextView.textDelegate = self
        //code_block_start tag CryptChat
        if !self.chat.isCrypto {
            let supportRecognition = self.audioToTextEnable
            let audioWithTextEnable = self.audioWithTextEnable
            RecognizeLanguageManager.shared.typeSubject
                .observeOn(MainScheduler.instance)
                .distinctUntilChanged()
                .subscribe(onNext: { [weak self] (_) in
                    let icons = AudioKeyboard.keyboard(
                        iconColor: self?.iconTintColor,
                        supportRecognition: supportRecognition,
                        audioWithTextEnable: audioWithTextEnable
                    ).icons
                    self?.updateIconCallBack?(icons)
                }).disposed(by: self.disposeBag)
        }
        //code_block_end
    }

    public func textChange(text: String, textView: LarkEditTextView) {
        guard self.inputTextViewText != text else { return }
        self.inputTextViewText = text
        guard textView.isFirstResponder,
            self.hasAudioRecognize else {
                return
        }
        self.hasEditRecognizeResult = true
    }

    public func textViewDidBeginEditing(_ textView: UITextView) {
        guard let keyboardView = self.delegate?.audiokeybordPanelView() else { return }
        // 隐藏 audio mask view
        self.handleAudioMask(show: false, maskInputView: false)
        // 如果是手动输入的，那么清除语音识别的状态。
        // 否则就是语音识别到的文字来改变文本框，如果清除语音识别状态，会重置disposeBag，使得文字不能马上进入文本框
        if !isEditTextViewByRecognize {
            self.cleanAudioRecognizeState()
            isEditTextViewByRecognize = false
        }
        // 更新插入索引
        self.lastSelectRange = keyboardView.inputTextView.selectedRange
    }

    public func textViewDidChangeSelection(_ textView: UITextView) {
        guard let keyboardView = self.delegate?.audiokeybordPanelView() else {
                return
        }
        // 更新最后一次选中范围，用于语音识别插入文字
        if keyboardView.inputTextView.isFirstResponder {
            self.lastSelectRange = keyboardView.inputTextView.selectedRange
        }
    }

    public func cleanMaskView() {
        self.handleAudioMask(show: false, maskInputView: false)
    }

    public func trackAudioRecognizeIfNeeded() {
        if self.hasAudioRecognize {
            AudioTracker.sendAudioRecognizeTextMessage(isEdit: self.hasEditRecognizeResult)
        }
        self.hasAudioRecognize = false
        self.hasEditRecognizeResult = false
    }

    // 清除语音识别中状态
    // 1. 发送文本消息会清除
    // 2. 跳转到帖子页面会清除
    // 3. 切换消息会清除
    // 4. 开启新的录音
    public func cleanAudioRecognizeState() {
        self.audioDisposeBag = DisposeBag()
        if self.recognizeAudioID == nil {
            return
        }
        self.recognizeAudioID = nil
        self.recognizeCacheText = nil
        self.lastAudioRecognize = nil
        self.cleanAudioRecognizeView()
    }

    func cleanAudioRecognizeView() {
        guard let keyboardView = self.delegate?.audiokeybordPanelView() else { return }

        let attributedText = NSMutableAttributedString(attributedString:
            self.delegate?.audiokeybordPanelView().inputTextView.attributedText ?? NSAttributedString()
        )

        // 清除 diff 样式
        if let lastDiffRange = self.lastDiffRange,
            attributedText.length >= lastDiffRange.location + lastDiffRange.length {
            attributedText.setAttributes(keyboardView.inputTextView.defaultTypingAttributes, range: lastDiffRange)
            self.lastDiffRange = nil
        }

        // 清除 loading view
        var loadingRange: NSRange?
        attributedText.enumerateAttribute(
            .attachment,
            in: NSRange(location: 0, length: attributedText.length),
            options: [],
            using: { (value, range, _) in
                if let attachemnt = value as? CustomTextAttachment,
                    attachemnt.customView == self.loadingView {
                    loadingRange = range
                }
            })
        if let range = loadingRange {
            attributedText.replaceCharacters(in: range, with: "")
        }
        keyboardView.inputTextView.attributedText = attributedText
        let offset = CGPoint(x: 0, y: keyboardView.inputTextView.contentSize.height - keyboardView.inputTextView.frame.height)
        keyboardView.inputTextView.setContentOffset(offset, animated: true)
        self.loadingView = nil
        self.showAudioRecognizeLoading = false
        // 键盘收起时语音转文字完成事件
        self.isVoiceBehaviorRelay.accept(false)
    }

    func observeRecognizeAudio(uploadID: String) {
        self.audioDisposeBag = DisposeBag()
        self.audioRecognizeService?
            .result
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (result) in
                guard let `self` = self else { return }
                if result.uploadID != self.recognizeAudioID {
                    return
                }
                if let lastAudioRecognize = self.lastAudioRecognize,
                    !result.finish,
                    lastAudioRecognize.text == result.text,
                    lastAudioRecognize.diffIndexSlice == result.diffIndexSlice {
                    return
                }

                self.lastAudioRecognize = result
                self.updateAudioRecognize(
                    text: result.text,
                    uploadID: result.uploadID,
                    isPrepare: false,
                    finish: result.finish,
                    diffIndexSlice: result.diffIndexSlice
                )
                if result.finish {
                    self.cleanAudioRecognizeState()
                    if result.text.isEmpty {
                        self.audioTracker?.asrFinalResultEmpty(sessionId: uploadID)
                    }
                }
            }, onError: { (error) in
                AudioKeyboardHelper.logger.error("audio recognize failed", error: error)
            }).disposed(by: self.audioDisposeBag)
    }

    func updateAudioRecognize(text: String, uploadID: String, isPrepare: Bool, finish: Bool, diffIndexSlice: [Int32] = []) {
        guard let keyboardView = self.delegate?.audiokeybordPanelView() else { return }
        // 第一次非空结果上屏的埋点
        if !text.isEmpty && self.isRecognizeFirstResult {
            audioTracker?.asrFirstPartialOnScreen(sessionId: uploadID)
            AudioReciableTracker.shared.audioRecognitionFirstResultAppear(sessionID: uploadID)
            self.isRecognizeFirstResult = false
        }
        let recognizeCacheText = self.recognizeCacheText ?? NSAttributedString(string: "")
        let result = NSMutableAttributedString(attributedString: recognizeCacheText)

        let attributedText = NSMutableAttributedString(string: text)
        attributedText.addAttributes(keyboardView.inputTextView.defaultTypingAttributes, range: NSRange(location: 0, length: attributedText.length))

        var lastDiffRange: NSRange?

        if showAudioRecognizeLoading {
            // 显示 loading
            if !finish,
                let attachmentText = self.loadingViewWith(
                    hasText: !(text.isEmpty && recognizeCacheText.string.isEmpty),
                    isPrepare: isPrepare,
                    font: keyboardView.inputTextView.font,
                    defaultTypingAttributes: keyboardView.inputTextView.defaultTypingAttributes
                ) {
                attributedText.append(attachmentText)
            }

            // 显示 diff
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
            let diffRange = NSRange(location: diffStartIndex, length: diffOffset)
            lastDiffRange = diffRange
            if diffOffset > 0 && !finish {
                attributedText.addAttribute(
                    .foregroundColor,
                    value: UIColor.ud.textPlaceholder,
                    range: diffRange
                )
            }
        }

        var lastSelectOffset = 0
        if let lastSelectRange = self.lastSelectRange,
            lastSelectRange.location + lastSelectRange.length <= result.length {
            if let lastDiffRange = lastDiffRange {
                self.lastDiffRange = NSRange(location: lastSelectRange.location + lastDiffRange.location, length: lastDiffRange.length)
            }

            if lastSelectRange.length == 0 {
                result.insert(attributedText, at: lastSelectRange.location)
            } else {
                result.replaceCharacters(in: lastSelectRange, with: attributedText)
            }
            lastSelectOffset = lastSelectRange.location + attributedText.length
        } else {
            if let lastDiffRange = lastDiffRange {
                self.lastDiffRange = NSRange(location: result.length + lastDiffRange.location, length: lastDiffRange.length)
            }

            result.append(attributedText)
            lastSelectOffset = result.length
        }

        keyboardView.inputTextView.attributedText = result
        let contentOffset = CGPoint(x: 0, y: keyboardView.inputTextView.contentSize.height - keyboardView.inputTextView.frame.height)
        keyboardView.inputTextView.setContentOffset(contentOffset, animated: false)

        if !text.isEmpty {
            self.hasAudioRecognize = true
        }

        if finish {
            // 如果结束输入 更新 lastSelectRange
            self.lastSelectRange = NSRange(location: lastSelectOffset, length: 0)
            audioTracker?.asrFinalResultOnScreen(sessionId: uploadID)
        }
    }

    private func loadingViewWith(
        hasText: Bool,
        isPrepare: Bool,
        font: UIFont?,
        defaultTypingAttributes: [NSAttributedString.Key: Any]) -> NSAttributedString? {
        if self.loadingView == nil {
            let loadingView = AudioRecognizingView(text: BundleI18n.LarkAudio.Lark_Chat_AudioToTextSpeakTip)
            self.loadingView = loadingView
        }
        guard let loadingView = self.loadingView else { return nil }
        loadingView.startAnimationIfNeeded()

        if isPrepare {
            loadingView.text = BundleI18n.LarkAudio.Lark_Chat_PrepareRecordAudio
        } else if !hasText {
            loadingView.text = BundleI18n.LarkAudio.Lark_Chat_AudioToTextSpeakTip
        } else {
            loadingView.text = ""
        }
        var attachmentBounds = loadingView.attachmentBounds
        if let font = font {
            attachmentBounds.origin.y = font.descender
        }
        let attachment = CustomTextAttachment(customView: loadingView, bounds: attachmentBounds)
        let attachmentText = NSMutableAttributedString(attachment: attachment)
        attachmentText.addAttributes(defaultTypingAttributes, range: NSRange(location: 0, length: attachmentText.length))

        return attachmentText
    }

    func getViewController(view: UIView) -> UIViewController? {
        if let next = view.next as? UIViewController {
            return next
        } else if let next = view.next as? UIView {
            return getViewController(view: next)
        }
        return nil
    }
}
// swiftlint:enable all
