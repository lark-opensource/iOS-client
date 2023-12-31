//
//  RealTimeTranslateDataManager.swift
//  LarkMessageCore
//
//  Created by liluobin on 2022/3/23.
//

import Foundation
import UIKit
import RustPB
import ServerPB
import RxSwift
import RxCocoa
import EditTextView
import LarkRustClient
import LarkContainer
import LarkRichTextCore
import LarkSetting
import LarkMessengerInterface
import LKCommonsLogging
import LarkSDKInterface
import LarkBaseKeyboard

///.debounce(.milliseconds(300), scheduler: MainScheduler.instance)
/// 实时翻译牵涉到频繁的网络请求和数据转化
/// 单独起一个队列来处理数据的转换
/// 这里是翻译的处理
/// 标题翻译只更新标题
/// 内容翻译只更新内容
public final class RealTimeTranslateDataManager: RealTimeTranslateService, UserResolverWrapper {
    private static var logger = Logger.log(RealTimeTranslateDataManager.self, category: "LarkMessageCore")
    @ScopedInjectedLazy private var chatAPI: ChatAPI?
    @ScopedInjectedLazy private var rustService: RustService?
    @ScopedInjectedLazy private var fgService: FeatureGatingService?

    private lazy var translateFG: Bool = {
        return fgService?.staticFeatureGatingValue(with: "im.chat.manual_open_translate") ?? false
    }()
    /// 标记每次请求，低版本丢弃，防止数据回来的晚
    var requestVersion: Int32 = 0
    /// 翻译的最新标题
    var localTitleResponse: RustPB.Im_V1_StreamingTranslateMessageResponse?
    /// 翻译的最新内容
    var localContentResponse: RustPB.Im_V1_StreamingTranslateMessageResponse?
    /// 翻译的最新内容RUSTPB
    var localContentRustRichText: RustPB.Basic_V1_RichText?

    private lazy var realTimeTranslateHelper: RealTimeTranslateHelper = {
        let realTimeTranslateHelper = RealTimeTranslateHelper()
        realTimeTranslateHelper.recallEnableChangedCallback = { [weak self] recallEnable in
            self?.data?.delegate?.onRecallEnableChanged(recallEnable)
        }
        return realTimeTranslateHelper
    }()

    //翻译前的内容
    private var originTitle: String?
    private var originContent: NSAttributedString?

    private var _isSmartTranslate = true
    private var isSmartTranslate: Bool { //_isSmartTranslate + FG
        get {
            return _isSmartTranslate && (fgService?.staticFeatureGatingValue(with: "im.chat.auto_switch_language") ?? false)
        }
        set {
            _isSmartTranslate = newValue
        }
    }
    private var sessionID = ""

    //不想调用refreshTranslateContent的场景直接修改_targetLanguage
    private var _targetLanguage: String {
        didSet {
            if _targetLanguage.isEmpty {
                assertionFailure("targetLanguage is empty, chatID: \(self.data?.chatID)")
            }
        }
    }
    private var targetLanguage: String {
        get {
            return _targetLanguage
        }
        set {
            guard newValue != _targetLanguage else { return }
            if !_targetLanguage.isEmpty {
                //手动修改过语言 那么本次输入不再自动切换语言
                //如过_targetLanguage oldValue是空的，说明是开关边写边译而不是切换语言，不需要把isSmartTranslate置为false
                self.isSmartTranslate = false
            }
            _targetLanguage = newValue
            refreshTranslateContent()
        }
    }
    private let titlePublishSubject = PublishSubject<Void>()
    private let contentPublishSubject = PublishSubject<Void>()

    //是否已经有了有效的请求数据
    private var hadEffectiveTitleRequest = false
    private var hadEffectiveContentRequest = false

    private var disposeBag = DisposeBag()

    public private (set) var data: RealTimeTranslateData?

    /// 绑定数据源 可以多个UITextView，但是互相之间同一时间只能有一个输入
    public func bindToTranslateData(_ data: RealTimeTranslateData) {
        guard self.translateFG else {
            return
        }
        self.data = data
        self.disposeBag = DisposeBag()
        bindListener()
    }

    private func bindListener() {
        self.data?.contentTextView?.rx.value.asDriver().skip(1).drive(onNext: { [weak self] (_) in
            guard let self = self else { return }
            self.onTextViewDidChangeIsForContent(true)
        }).disposed(by: self.disposeBag)
        self.data?.titleTextView?.rx.value.asDriver().skip(1).drive(onNext: { [weak self] (_) in
            guard let self = self else { return }
            self.onTextViewDidChangeIsForContent(false)
        }).disposed(by: self.disposeBag)

        contentPublishSubject
        .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
        .subscribe(onNext: { [weak self] in
            self?.requestForTranslateContent()
        }).disposed(by: disposeBag)
        titlePublishSubject
        .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
        .subscribe(onNext: { [weak self] in
            self?.requestForTranslateTitle()
        }).disposed(by: disposeBag)
    }

    /// 清空数据 比如用户关闭当前的输入框翻译
    public func unbindToTranslateData() {
        self.data = nil
        self.disposeBag = DisposeBag()
        self.updateSessionID()
    }

    public func updateTargetLanguage(_ languageKey: String) {
        if self.targetLanguage == languageKey {
            return
        }
        self.targetLanguage = languageKey
    }

    /// 更新根据当前的内容 更新一下翻译
    public func refreshTranslateContent() {
        self.contentPublishSubject.onNext(())
        self.titlePublishSubject.onNext(())
    }

    /// 标记一次翻译 1.进出chat 2.发送消息
    public func updateSessionID() {
        self.sessionID = UUID().uuidString
        //发送消息或进出chat后，重新开启自动切换语言
        self.isSmartTranslate = true
    }

    public let userResolver: UserResolver

    public init(targetLanguage: String, userResolver: UserResolver) {
        self._targetLanguage = targetLanguage
        self.userResolver = userResolver
        updateSessionID()
    }

    deinit {
        self.realTimeTranslateHelper.stopTimerForAutoResetRecallEnable()
    }

    /// 获取当前翻译的数据
    public func getCurrentTranslateOriginData() -> (String?, RustPB.Basic_V1_RichText?) {
        return (self.localTitleResponse?.translatedTitle, self.localContentRustRichText)
    }

    public func getLastOriginData() -> (String?, NSAttributedString?) {
        return (self.originTitle, self.originContent)
    }

    public func clearTranslationData() {
        clearTranslationData(recallEnable: true)
    }

    public func clearOriginAndTranslationData() {
        self.originTitle = nil
        self.originContent = nil
        self.clearTranslationData(recallEnable: false)
    }

    private func clearTranslationData(recallEnable: Bool) {
        DispatchQueue.main.async { [weak self] in
            //先干掉监听，避免又有PublishSubject.onNext()过来重新调接口刷新数据
            self?.disposeBag = DisposeBag()
            self?.localTitleResponse = nil
            self?.localContentResponse = nil
            self?.localContentRustRichText = nil
            self?.hadEffectiveContentRequest = false
            self?.hadEffectiveTitleRequest = false
            self?.data?.delegate?.onUpdateContentTranslationPreview("", completeData: nil)
            self?.data?.delegate?.onUpdateTitleTranslation("")
            //重新绑定监听
            self?.bindListener()
            self?.realTimeTranslateHelper.recallEnable = recallEnable
        }
    }

    private func onTextViewDidChangeIsForContent(_ isForContent: Bool) {
        if isForContent {
            if self.data?.contentTextView != nil {
                self.contentPublishSubject.onNext(())
                if localTitleResponse == nil &&
                    self.data?.titleTextView?.text.count ?? 0 > 0 {
                    self.titlePublishSubject.onNext(())
                }
            }
        } else {
            if self.data?.titleTextView != nil {
                self.titlePublishSubject.onNext(())
                if localContentResponse == nil &&
                    self.data?.contentTextView?.attributedText.length ?? 0 > 0 {
                    self.contentPublishSubject.onNext(())
                }
            }
        }
    }

    private func autoChangeTranslateLanguage(language: String) {
        guard let chatID = self.data?.chatID else { return }
        self.chatAPI?.updateChat(chatId: chatID, isRealTimeTranslate: true,
                                realTimeTranslateLanguage: language)
        .subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            //再校验一下 data没有解绑、isSmartTranslate没有更改
            if self.data != nil,
               self.isSmartTranslate {
                self._targetLanguage = language
            }
        }, onError: { (error) in
            Self.logger.error("autoChangeTranslateLanguage failed, chatID: \(chatID), language: \(language)", error: error)
        }).disposed(by: self.disposeBag)
    }

    private func requestForTranslateContent() {
        guard let contentTextView = self.data?.contentTextView else {
            return
        }
        if !hadEffectiveContentRequest, contentTextView.attributedText.string.isEmpty {
            return
        }

        guard !targetLanguage.isEmpty else {
            assertionFailure("targetLanguage is empty, chatID: \(self.data?.chatID)")
            return
        }
        /// 数据转换&网络请求
        self.data?.delegate?.beginTranslateConent()
        self.realTimeTranslateHelper.recallEnable = false
        self.originContent = contentTextView.attributedText
        let richText = RichTextTransformKit.transformStringToRichText(string: contentTextView.attributedText)
        self.hadEffectiveContentRequest = true
        var request = RustPB.Im_V1_StreamingTranslateMessageRequest()
        request.version = self.requestVersion
        request.sessionID = self.sessionID
        request.targetLanguage = self.targetLanguage
        request.isSmartTranslate = self.isSmartTranslate
        if let richText = richText {
            realTimeTranslateHelper.checkOriginRichText(richText)
            request.richText = richText
        }
        self.requestVersion += 1
        self.rustService?.sendAsyncRequest(request)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response: RustPB.Im_V1_StreamingTranslateMessageResponse) in
                guard let self = self else { return }
                var needUpdate = true
                if let localContentResponse = self.localContentResponse,
                   localContentResponse.version >= response.version {
                    needUpdate = false
                }
                if needUpdate {
                    self.localContentResponse = response
                    let handledRichText = self.realTimeTranslateHelper.handleTranslatedRichText(response.translatedRichText)
                    self.localContentRustRichText = handledRichText
                    let text = RichTextTransformKit.transformRichTexToText(handledRichText) ?? ""
                    self.data?.delegate?.onUpdateContentTranslationPreview(text, completeData: handledRichText)
                    if self.isSmartTranslate,
                       !response.translatedLanguage.isEmpty,
                       response.translatedLanguage.lowercased() != self.targetLanguage.lowercased() {
                        self.autoChangeTranslateLanguage(language: response.translatedLanguage)
                    }
                }
            }, onError: { [weak self] error in
                Self.logger.error("requestForTranslateContent failed, chatID: \(self?.data?.chatID)", error: error)
            }).disposed(by: self.disposeBag)
    }

    private func requestForTranslateTitle() {
        guard let titleTextView = self.data?.titleTextView else {
            return
        }
        if !hadEffectiveTitleRequest, titleTextView.attributedText.string.isEmpty {
            return
        }

        guard !targetLanguage.isEmpty else {
            assertionFailure("targetLanguage is empty, chatID: \(self.data?.chatID)")
            return
        }
        let title = titleTextView.attributedText.string
        self.data?.delegate?.beginTranslateTitle()
        self.realTimeTranslateHelper.recallEnable = false
        self.originTitle = title
        self.hadEffectiveTitleRequest = true
        var request = RustPB.Im_V1_StreamingTranslateMessageRequest()
        request.title = title
        request.version = self.requestVersion
        request.sessionID = self.sessionID
        request.targetLanguage = targetLanguage
        request.isSmartTranslate = self.isSmartTranslate
        self.requestVersion += 1
        self.rustService?.sendAsyncRequest(request)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response: RustPB.Im_V1_StreamingTranslateMessageResponse) in
                guard let self = self else {
                    return
                }
                var needUpdate = true
                if let localTitleResponse = self.localTitleResponse,
                   localTitleResponse.version >= response.version {
                    needUpdate = false
                }
                if needUpdate {
                    self.localTitleResponse = response
                    self.data?.delegate?.onUpdateTitleTranslation(response.translatedTitle)

                    if self.isSmartTranslate,
                       !response.translatedLanguage.isEmpty,
                       response.translatedLanguage.lowercased() != self.targetLanguage.lowercased() {
                        self.autoChangeTranslateLanguage(language: response.translatedLanguage)
                    }
                }
            }, onError: { [weak self] error in
                Self.logger.error("requestForTranslateTitle failed, chatID: \(self?.data?.chatID)", error: error)
            }).disposed(by: self.disposeBag)
    }

    public func getRecallEnable() -> Bool {
        return realTimeTranslateHelper.recallEnable
    }
}

private final class RealTimeTranslateHelper {
    private var linkElementsCache = [String: RustPB.Basic_V1_RichTextElement.TextProperty]()
    private var mediaElementCache = [String: RustPB.Basic_V1_RichTextElement]()
    fileprivate func checkOriginRichText(_ richText: RustPB.Basic_V1_RichText) {
        for (id, element) in richText.elements {
            switch element.tag {
            case .link:
                for childId in element.childIds {
                    if let childElement = richText.elements[childId],
                       childElement.tag == .text {
                        linkElementsCache[id] = childElement.property.text
                        break
                    }
                }
            case .media:
                mediaElementCache[id] = element
            @unknown default:
                break
            }
        }
    }
    fileprivate func handleTranslatedRichText(_ richText: RustPB.Basic_V1_RichText) -> RustPB.Basic_V1_RichText {
        var richText = richText
        for (id, text) in linkElementsCache {
            if let linkElement = richText.elements[id],
               linkElement.tag == .link {
                for childId in linkElement.childIds {
                    if let childElement = richText.elements[childId],
                       childElement.tag == .text {
                        richText.elements[childId]?.property.text = text
                        break
                    }
                }
            }
        }
        for (id, element) in mediaElementCache {
            richText.elements[id] = element
        }
        return richText
    }

    // MARK: - 撤回“使用翻译”
    fileprivate var recallEnable = false {
        didSet {
            if recallEnable != oldValue {
                recallEnableChangedCallback?(recallEnable)
                if recallEnable {
                    self.startTimerForAutoResetRecallEnable()
                } else {
                    self.stopTimerForAutoResetRecallEnable()
                }
            }
        }
    }

    var recallEnableChangedCallback: ((Bool) -> Void)?

    private var autoResetRecallTimer: Timer?
    //30秒不输入，自动把recallEnable置为false
    fileprivate func startTimerForAutoResetRecallEnable() {
        autoResetRecallTimer?.invalidate()
        autoResetRecallTimer = Timer.scheduledTimer(timeInterval: 30,
                                                             target: self,
                                                             selector: #selector(resetRecallEnable),
                                                             userInfo: nil,
                                                             repeats: false)
    }

    fileprivate func stopTimerForAutoResetRecallEnable() {
        autoResetRecallTimer?.invalidate()
        autoResetRecallTimer = nil
    }

    @objc
    private func resetRecallEnable() {
        recallEnable = false
        stopTimerForAutoResetRecallEnable()
    }
}
