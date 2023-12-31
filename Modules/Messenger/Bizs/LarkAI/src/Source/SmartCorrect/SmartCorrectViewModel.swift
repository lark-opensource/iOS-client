//
//  SmartCorrectViewModel.swift
//  LarkAI
//
//  Created by ZhangHongyun on 2021/5/27.
//

import Foundation
import UIKit
import RxSwift
import ServerPB
import EditTextView
import RichLabel
import LarkMenuController
import LKCommonsLogging
import LarkGuideUI
import LarkGuide
import LarkContainer
import LarkStorage
import LarkBaseKeyboard
import LarkMessengerInterface
import LarkSetting

final class SmartCorrectViewModel: NSObject, UITextViewDelegate, EditTextViewTextDelegate, UserResolverWrapper {
    private static let logger = Logger.log(SmartCorrectViewModel.self, category: "SmartCorrect.SmartCorrectViewModel")
    let userResolver: UserResolver
    let aiServiceApi: AIServiceAPI
    @ScopedInjectedLazy private var newGuideManager: NewGuideService?
    weak var viewController: UIViewController?

    private var matches: [ServerPB_Correction_AITextCorrectionMatch] = []
    private var sourceTextUrls: [String] = []
    private var lastRequstText: String = ""
    private var menuVC: MenuViewController?
    weak var inputTextView: LarkEditTextView?
    private let guideUIKey = "mobile_suite_ai_smart_correction"
    private let disposeBag = DisposeBag()
    private static let globalStore = KVStores.AI.global()

    init(resolver: UserResolver) {
        self.userResolver = resolver
        self.aiServiceApi = RustAIServiceAPI(resolver: resolver)
    }
    func getSmartCorrectSuggestion(chatId: String, prefix: String, scene: SmartCorrectScene) -> Observable<(String, ServerPB_Correction_AIGetTextCorrectionResponse)> {
        let sceneString = scene == .im ? "im" : "richtext"
        return aiServiceApi.getSmartCorrect(chatID: chatId,
                                            texts: [prefix],
                                            scene: sceneString)
            .map { (response) -> (String, ServerPB_Correction_AIGetTextCorrectionResponse) in
                return (prefix, response)
            }
    }

    func validateShouldRequestSmartCorrect(validateString: String) -> Bool {
        let selectedRange = self.inputTextView?.markedTextRange ?? UITextRange()
        if self.inputTextView?.position(from: selectedRange.start, offset: 0) == nil {
            if self.lastRequstText != validateString {
                self.lastRequstText = validateString
                return true
            }
        } else {
            // 正在输入拼音时，不对文字进行统计和限制
            return false
        }
        return false
    }

    func showSmartCorrectHighlight(with response: ServerPB_Correction_AIGetTextCorrectionResponse) {
        guard let result = response.data.first,
              let textView = inputTextView else { return }
        Self.logger.info("In showSmartCorrectHighlight")
        sourceTextUrls = []
        removeLinkAttributes()
        matches = result.matches.filter({ match in
            !checkMatchInIgnoreList([match.sourceText: match.targetText])
        })
        guard !matches.isEmpty || !enableTextViewReplacedWhenNotEqual() else {
            Self.logger.info("SmartCorrect matches is empty")
            return
        }
        let attribute: [NSAttributedString.Key: Any] = [.underlineStyle: NSUnderlineStyle.thick.rawValue,
                                                        .underlineColor: UIColor.ud.red]
        let inputAtrributeString = NSMutableAttributedString(attributedString: textView.attributedText)

        for (index, match) in matches.enumerated() {
            let inputString = inputAtrributeString.string
            if inputString.count >= match.offset + match.length {
                SmartCorrectTracker.smartCorrectAction(.show)
                Self.logger.info("Smart Correct Highlight Show!")
                let range = NSRange(location: Int(match.offset), length: Int(match.length))
                if checkConflict(text: inputAtrributeString, range: range) { continue }
                inputAtrributeString.addAttributes([AIFontStyleConfig.smartCorrectAttribuedKey: AIFontStyleConfig.smartCorrectAttribuedValue], range: range)
                inputAtrributeString.addAttributes(attribute, range: range)
                let link: URL? = LinkAttributeValue.sultString(sourceText: match.sourceText, index: index).rawValue
                if let link = link {
                    let linkAttribute: [NSAttributedString.Key: Any] = [.link: link]
                    inputAtrributeString.addAttributes(linkAttribute, range: range)
                    sourceTextUrls.append(link.absoluteString)
                }
                if index == 0 {
                    let textRects: [CGRect] = rects(forString: match.sourceText, in: textView, range: range)
                    guard let rect = textRects.first else { return }
                    let resultRect = textView.convert(rect, to: viewController?.view)
                    // 创建气泡的配置
                    let item = BubbleItemConfig(guideAnchor: TargetAnchor(targetSourceType: .targetRect(resultRect),
                                                                          offset: 4,
                                                                          targetRectType: .rectangle),
                                                textConfig: TextInfoConfig(title: BundleI18n.LarkAI.Lark_ASL_SmartCorrectionOnboardingTitle,
                                                                           detail: BundleI18n.LarkAI.Lark_ASL_SmartCorrectionOnboardingDescMobile))
                    let singleBubbleConfig = SingleBubbleConfig(bubbleConfig: item)
                    let bubbleType = BubbleType.single(singleBubbleConfig)
                    newGuideManager?.showBubbleGuideIfNeeded(guideKey: self.guideUIKey,
                                                            bubbleType: bubbleType,
                                                            dismissHandler: nil,
                                                            didAppearHandler: nil,
                                                            willAppearHandler: nil)
                }
            }
        }
        textView.linkTextAttributes = [NSAttributedString.Key: Any]()
        replaceText(forTextView: textView, withAttributedText: inputAtrributeString)
        // 编辑文字、滚动textview、切换键盘类型、收起键盘，均收起纠错提示卡片
        textView.rx.didChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                self.dismissMenuController()
            }).disposed(by: disposeBag)
        textView.rx.didScroll
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                self.dismissMenuController()
            }).disposed(by: disposeBag)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardTypeChanged), name: UITextInputMode.currentInputModeDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardTypeChanged), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    func textViewDidChange(_ textView: UITextView) {
        guard enableRemoveAttributesWhenTextChange() else { return }
        removeLinkAttributes()
    }

    func checkConflict(text: NSAttributedString, range: NSRange) -> Bool {
        var containConflict = false
        text.enumerateAttributes(in: range) { (info, _, _) in
            /// 百科、人名、doc预览、url链接、代码、mention、emotion、
            var conflictKeys: Set<NSAttributedString.Key> = RichTextTransformKit.digOutRichTextNode
            conflictKeys.insert(AIFontStyleConfig.lingoHighlightAttributedKey)
            if !conflictKeys.isDisjoint(with: Set(info.keys)) {
                containConflict = true
                Self.logger.info("smart correct conflict: there has other richText Node!")
            }
        }
        return containConflict
    }

    func dismissMenuController() {
        guard let menuVC = self.menuVC else { return }
        menuVC.dismiss(animated: true, params: nil)
        self.menuVC = nil
    }

    func textChange(text: String, textView: LarkEditTextView) {
        // 换行和发送关闭纠错胶囊
        if text.isEmpty {
            dismissMenuController()
        }
    }

    private func replaceText(forTextView textView: UITextView, withAttributedText attributedText: NSAttributedString) {
        guard !textView.attributedText.isEqual(to: attributedText) || !enableTextViewReplacedWhenNotEqual() else {
            Self.logger.info("replaceText is equal to textview")
            return
        }
        // 记录光标位置 location 对应光标的位置
        let selectedRange = textView.selectedRange
        let offset = textView.contentOffset
        textView.attributedText = attributedText
        // 重新设置光标位置
        textView.selectedRange = selectedRange
        textView.setContentOffset(offset, animated: false)
    }

    public func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        guard let link = LinkAttributeValue(rawValue: url), case .sultString(_, let index) = link else {
            return false
        }
        Self.logger.info("Smart Correct Card Show with url:\(url.absoluteString) ")
        LarkAITracker.trackForStableWatcher(domain: "asl_correction",
                                            message: "asl_correction_click",
                                            metricParams: [:],
                                            categoryParams: [:])
        let inputAtrributeString = NSMutableAttributedString(attributedString: textView.attributedText)
        inputAtrributeString.addAttributes([.backgroundColor: UIColor.ud.colorfulRed.withAlphaComponent(0.2)], range: characterRange)
        replaceText(forTextView: textView, withAttributedText: inputAtrributeString)
        let text = textView.attributedText.attributedSubstring(from: characterRange)
        let textRects: [CGRect] = rects(forString: text.string, in: textView, range: characterRange)
        let textfirstRect: CGRect = textRects.first ?? CGRect.zero
        if index < matches.count,
           let viewController = viewController {
            let match = matches[index]
            let layout = AIMenuLayout(leadingInset: 20, horizontalCenter: false)
            var changedRange = characterRange
            let cardViewModel = SmartCorrectCardViewModel(originSize: viewController.view.bounds.size,
                                                          targetText: match.targetText,
                                                          tapPoint: CGPoint(x: textfirstRect.centerX, y: textfirstRect.centerY),
                                                          cardLayout: layout,
                                                          selectedActionCallback: { [weak self, weak textView] in
                guard let self = self,
                      let textView = textView else { return }
                SmartCorrectTracker.smartCorrectAction(.apply)
                Self.logger.info("Smart Correct suggestion apply with text:\(match.sourceText) ")
                LarkAITracker.trackForStableWatcher(domain: "asl_correction",
                                                    message: "asl_correction_correct",
                                                    metricParams: [:],
                                                    categoryParams: [:])
                self.dismissMenuController()

                inputAtrributeString.removeAttribute(AIFontStyleConfig.smartCorrectAttribuedKey, range: characterRange)
                inputAtrributeString.removeAttribute(.underlineStyle, range: characterRange)
                inputAtrributeString.removeAttribute(.underlineColor, range: characterRange)
                inputAtrributeString.removeAttribute(.link, range: characterRange)
                inputAtrributeString.removeAttribute(.backgroundColor, range: characterRange)
                inputAtrributeString.replaceCharacters(in: characterRange, with: match.targetText)
                if self.enableRemoveAttributesWhenTextChange(), characterRange.length != match.targetText.count {
                    changedRange = NSRange(location: characterRange.location, length: match.targetText.count)
                }

                inputAtrributeString.enumerateAttributes(in: changedRange, options: []) { (attribute, attributeRange, _) in
                    if attribute.keys.contains(FontStyleConfig.underlineAttributedKey) {
                        inputAtrributeString.addAttributes([.underlineStyle: FontStyleConfig.underlineStyle], range: attributeRange)
                    }
                }
                let offset = textView.contentOffset
                textView.attributedText = inputAtrributeString
                // 重新设置光标位置
                textView.selectedRange = NSRange(location: characterRange.location + match.targetText.utf16.count, length: 0)
                textView.setContentOffset(offset, animated: false)
            },
                                                          abandonActionCallback: { [weak self] in
                guard let self = self else { return }
                self.dismissMenuController()
                self.inputTextViewRemoveLinkAttributes(with: match.sourceText, in: characterRange)
                SmartCorrectTracker.smartCorrectAction(.abandon)
                self.addIgnoreSmartCorrectMatch([match.sourceText: match.targetText])
                Self.logger.info("Smart Correct suggestion abandon with text:\(match.sourceText) ")
                LarkAITracker.trackForStableWatcher(domain: "asl_correction",
                                                    message: "asl_correction_ignore",
                                                    metricParams: [:],
                                                    categoryParams: [:])
            })
            let menuVC = MenuViewController(viewModel: cardViewModel,
                                            layout: layout,
                                            trigerView: textView,
                                            trigerLocation: CGPoint(x: textfirstRect.centerX, y: textfirstRect.centerY))
            menuVC.dismissBlock = { [weak self] in
                guard let self = self else { return }
                self.menuVC = nil
                let inputAtrributeString = NSMutableAttributedString(attributedString: textView.attributedText)
                guard inputAtrributeString.length >= (changedRange.location + changedRange.length) else { return }
                inputAtrributeString.removeAttribute(.backgroundColor, range: changedRange)
                self.replaceText(forTextView: textView, withAttributedText: inputAtrributeString)
                Self.logger.info("Smart Correct card click other area with text:\(match.sourceText) ")
            }
            menuVC.show(in: viewController)
            SmartCorrectTracker.smartCorrectAction(.click)
            self.menuVC = menuVC
            return false
        }
        return false
    }

    private func drawUnderline(with rects: [CGRect]) {
        guard !rects.isEmpty else { return }
        rects.forEach { (rect) in
            let path = UIBezierPath()
            path.move(to: CGPoint(x: rect.minX, y: rect.minY + 1))
            path.addLine(to: CGPoint(x: rect.minX + rect.width, y: rect.minY + 2))
            let layer = CAShapeLayer()
            layer.path = path.cgPath
            layer.strokeColor = UIColor.ud.red.cgColor
            layer.fillColor = UIColor.ud.red.cgColor
            self.inputTextView?.layer.addSublayer(layer)
        }
    }

    private
    func inputTextViewAddLinkAttributes(with text: String, in range: NSRange) {
        guard let textView = inputTextView else { return }
        let inputAtrributeString = NSMutableAttributedString(attributedString: textView.attributedText)
        inputAtrributeString.removeAttribute(.underlineStyle, range: range)
        inputAtrributeString.removeAttribute(.underlineColor, range: range)
        replaceText(forTextView: textView, withAttributedText: inputAtrributeString)
    }

    private
    func inputTextViewRemoveLinkAttributes(with text: String, in range: NSRange) {
        guard let textView = inputTextView else { return }
        let inputAtrributeString = NSMutableAttributedString(attributedString: textView.attributedText)
        guard inputAtrributeString.length >= (range.location + range.length) else { return }
        inputAtrributeString.removeAttribute(AIFontStyleConfig.smartCorrectAttribuedKey, range: range)
        inputAtrributeString.removeAttribute(.underlineStyle, range: range)
        inputAtrributeString.removeAttribute(.underlineColor, range: range)
        inputAtrributeString.removeAttribute(.link, range: range)
        inputAtrributeString.removeAttribute(.backgroundColor, range: range)
        inputAtrributeString.enumerateAttributes(in: range, options: []) { (attribute, attributeRange, _) in
            if attribute.keys.contains(FontStyleConfig.underlineAttributedKey) {
                inputAtrributeString.addAttributes([.underlineStyle: FontStyleConfig.underlineStyle], range: attributeRange)
            }
        }
        replaceText(forTextView: textView, withAttributedText: inputAtrributeString)
    }

    private
    func removeLinkAttributes() {
        guard let inputTextView = inputTextView else { return }
        var linkStr: String?
        var nextIndex: Int?
        let inputAtrributeString = NSMutableAttributedString(attributedString: inputTextView.attributedText)
        inputTextView.attributedText.enumerateAttributes(in: NSRange(location: 0, length: inputTextView.attributedText.length), options: []) { (attribute, attributeRange, _) in
            if attribute.keys.contains(AIFontStyleConfig.smartCorrectAttribuedKey) {
                linkStr = (attribute[.link] as? NSURL)?.absoluteString
                nextIndex = attributeRange.location + attributeRange.length
                inputAtrributeString.removeAttribute(AIFontStyleConfig.smartCorrectAttribuedKey, range: attributeRange)
                inputAtrributeString.removeAttribute(.underlineColor, range: attributeRange)
                inputAtrributeString.removeAttribute(.underlineStyle, range: attributeRange)
                inputAtrributeString.removeAttribute(.link, range: attributeRange)
                if enableRemoveAttributesWhenTextChange() {
                    inputAtrributeString.removeAttribute(.backgroundColor, range: attributeRange)
                }
            } else if (attribute[.link] as? NSURL)?.absoluteString == linkStr, !linkStr.isEmpty, nextIndex == attributeRange.location, attributeRange.length == 1 {
                if enableRemoveAttributesWhenTextChange() {
                    inputAtrributeString.removeAttribute(.underlineColor, range: attributeRange)
                    inputAtrributeString.removeAttribute(.underlineStyle, range: attributeRange)
                    inputAtrributeString.removeAttribute(.link, range: attributeRange)
                    inputAtrributeString.removeAttribute(.backgroundColor, range: attributeRange)
                    nextIndex = attributeRange.location + attributeRange.length
                }
            }
            if attribute.keys.contains(FontStyleConfig.underlineAttributedKey) {
                inputAtrributeString.addAttributes([.underlineStyle: FontStyleConfig.underlineStyle], range: attributeRange)
            }
        }
        replaceText(forTextView: inputTextView, withAttributedText: inputAtrributeString)

    }
    private
    func check(_ range: NSRange, contain subRange: NSRange) -> Bool {
        return range.location <= subRange.location
            && subRange.location < range.location + range.length
            && range.location + range.length >= subRange.location + subRange.length
    }

    @objc private
    func keyboardTypeChanged() {
        self.dismissMenuController()
    }

    /// 补全建议文本所在区域集合
    ///
    /// - Parameter string:   文本
    /// - Parameter textview: 输入框
    /// - Returns: 补全建议的点击区域集合
    private func rects(forString string: String, in textview: UITextView, range: NSRange) -> [CGRect] {
        guard textview.text != nil else { return [] }
        guard let start = textview.position(from: textview.beginningOfDocument,
                                            offset: range.location) else { return [] }
        guard let end = textview.position(from: start,
                                          offset: range.length) else { return [] }
        // 获取文本在inputView里的range
        guard let textRange = textview.textRange(from: start, to: end) else { return [] }
        // 获取文本在inputView里的rects
        let rectArr = textview.selectionRects(for: textRange)
        let rects = rectArr.map { $0.rect }.filter { (rect) -> Bool in
            rect.width != 0 && rect.height != 0
        }
        return rects
    }

    private
    func addIgnoreSmartCorrectMatch(_ match: [String: String]) {
        if var arr = SmartCorrectViewModel.globalStore[KVKeys.AI.smartCorrect] {
            arr.append(match)
            SmartCorrectViewModel.globalStore[KVKeys.AI.smartCorrect] = arr
        } else {
            let arr = [match]
            SmartCorrectViewModel.globalStore[KVKeys.AI.smartCorrect] = arr
        }
    }

    private
    func checkMatchInIgnoreList(_ match: [String: String]) -> Bool {
        guard let arr = SmartCorrectViewModel.globalStore[KVKeys.AI.smartCorrect] else { return false }
        var isContain: Bool = false
        arr.forEach { (storeMatch) in
            if match == storeMatch {
                isContain = true
            }
        }
        return isContain
    }

    private func enableRemoveAttributesWhenTextChange() -> Bool {
        let aslConfig = try? SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "lark_asl_config"))
        if let enable = aslConfig?["enable_remove_attributes_when_text_change"] as? Bool {
            return enable
        }
        return true
    }

    private func enableTextViewReplacedWhenNotEqual() -> Bool {
        let aslConfig = try? SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "lark_asl_config"))
        if let enable = aslConfig?["enable_textview_replaced_when_not_equal"] as? Bool {
            return enable
        }
        return true
    }
}
