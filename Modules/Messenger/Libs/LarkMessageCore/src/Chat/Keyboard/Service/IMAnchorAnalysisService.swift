//
//  IMAnchorAnalysisService.swift
//  LarkMessageCore
//
//  Created by liluobin on 2023/7/28.
//

import UIKit
import LarkBaseKeyboard
import EditTextView
import RxSwift
import LarkContainer
import LKCommonsLogging
import LarkCore

public protocol IMAnchorAnalysisService {
    func addObserverFor(textView: LarkEditTextView)
    func removerObserver()
}

class IMAnchorAnalysisServiceIMP: IMAnchorAnalysisService, TextViewListenersProtocol {

    var disposeBag = DisposeBag()
    /// 处理频繁的操作
    private var debouncer: Debouncer = Debouncer()

    /// 内部key使用 用来标记识别的anchor
    let PreviewAnchorAttributedKey = NSAttributedString.Key(rawValue: "lark.anchor.preview.key")

    static let logger = Logger.log(IMAnchorAnalysisServiceIMP.self, category: "IMAnchorAnalysisServiceIMP")
    /// 这里输入检测高亮 需要anchor高亮的FG开了 才可以识别
    lazy var anchorAnalysisFg: Bool = {
       return self.userResolver.fg.staticFeatureGatingValue(with: "messenger.input.copy_dynamic") && TextViewCustomPasteConfig.useNewPasteFG
    }()

    private weak var textView: LarkEditTextView?
    private var defaultFontColor: UIColor = UIColor.ud.N600

    let userResolver: UserResolver

    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    public func addObserverFor(textView: LarkEditTextView) {
        guard self.anchorAnalysisFg else { return }
        Self.logger.info("start ObserverFor for textView")
        self.textView = textView
        textView.addListener(self)
        defaultFontColor = (textView.defaultTypingAttributes[.foregroundColor] as? UIColor) ?? UIColor.ud.N600
        /// rx这里无法监听到文字的复制
        textView.rx.didChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                self.highlightUrlIfNeed()
            }).disposed(by: disposeBag)
        /// addObserver先进行一次检测
        self.highlightUrlIfNeed(immediate: true)
    }

    func onSetTextViewAttributedText() {
        self.highlightUrlIfNeed()
    }

    /// 高亮URL链接
    private func highlightUrlIfNeed(immediate: Bool = false) {
        guard !immediate else {
            self.matchAndHanderUrlRange()
            return
        }
        let duration: TimeInterval = 0.3
        debouncer.debounce(indentify: "onSetTextViewAttributedText", duration: duration) { [weak self] in
            self?.matchAndHanderUrlRange()
        }
    }

    private func matchAndHanderUrlRange() {
        guard let textView = self.textView else { return }
        let start = CFAbsoluteTimeGetCurrent()
        let attrText = textView.textStorage
        var range = NSRange(location: 0, length: attrText.string.utf16.count)
        if textView.selectedRange.location != NSNotFound,
           textView.selectedRange.location + textView.selectedRange.length <= attrText.string.utf16.count {
            /// 1. 只匹配当前段落的文字
            range = (attrText.string as NSString).paragraphRange(for: textView.selectedRange)
        } else {
            Self.logger.warn("matchAndHanderUrlRange error range \(textView.selectedRange) --\(textView.attributedText.length)")
        }
        /// 2. 匹配出来所有的URL
        var urlRanges = CustomTextViewPasteManager.generalURLRegexp.matches(in: attrText.string,
                                                                            range: range).map { res in
            return res.range
        }
        /// 3. 如果没有匹配到的 都进行移除
        attrText.enumerateAttribute(PreviewAnchorAttributedKey, in: range) { value, subRange, _ in
            if value != nil {
                if let idx = urlRanges.firstIndex(where: { $0 == subRange }) {
                    urlRanges.remove(at: idx)
                } else {
                    textView.textStorage.removeAttribute(self.PreviewAnchorAttributedKey, range: subRange)
                    textView.textStorage.addAttributes([.foregroundColor: defaultFontColor], range: subRange)
                }
            }
        }

        urlRanges.forEach { range in
            /// 3. 处理对应的URL
            let attr = attrText.attributedSubstring(from: range)
            if self.canAddAnchorInfoFor(attr: attr) {
                textView.textStorage.addAttributes([self.PreviewAnchorAttributedKey:
                                                        AnchorTransformInfo(isCustom: false,
                                                                            scene: .unknown,
                                                                            contentLength: range.length,
                                                                            href: attrText.attributedSubstring(from: range).string),
                                                    .foregroundColor: UIColor.ud.textLinkNormal], range: range)
            }
        }
        let end = CFAbsoluteTimeGetCurrent()
        /// 超过某个时长再打印一下
        if end - start > 0.1 {
            assertionFailure("...regexp matches cost too much time...")
            Self.logger.warn("urlRanges handler cost time > 0.1s range\(range), cost:\(end - start) --urlRanges: \(urlRanges) -- \(attrText.length)")
        }
    }

    public func removerObserver() {
        guard self.anchorAnalysisFg else { return }
        disposeBag = DisposeBag()
    }

    private func canAddAnchorInfoFor(attr: NSAttributedString) -> Bool {
        /// 如果命中的文字 之前已经有key了 不需要再处理
        let unsupportKey: [NSAttributedString.Key] = [LinkTransformer.LinkAttributedKey,
                                                      AtTransformer.UserIdAttributedKey,
                                                      AnchorTransformer.AnchorAttributedKey,
                                                      .attachment]
        var needAdd = true
        unsupportKey.forEach { key in
            if !needAdd {
                return
            }
            attr.enumerateAttribute(key, in: NSRange(location: 0, length: attr.length)) { value, _, stop in
                if value != nil {
                    needAdd = false
                    stop.pointee = true
                }
            }
        }
        return needAdd
    }
}
