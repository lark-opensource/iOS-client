//
//  LingoHighlightViewModel.swift
//  LarkAI
//
//  Created by ByteDance on 2023/5/18.
//

import Foundation
import UIKit
import RxSwift
import ServerPB
import EditTextView
import RichLabel
import LarkMenuController
import LKCommonsLogging
import LarkContainer
import UniverseDesignToast
import LarkBaseKeyboard
import LarkMessengerInterface
import LarkSetting
import LarkSearchCore
import EENavigator

final class LingoHighlightViewModel: NSObject, UITextViewDelegate, EditTextViewTextDelegate, UserResolverWrapper {
    private static let logger = Logger.log(LingoHighlightViewModel.self, category: "EnterpriseEntityWord.lingoHighlightVM")
    let eewServiceApi: EnterpriseEntityWordAPI
    let enterpriseEntityWordService: EnterpriseEntityWordService?
    weak var viewController: UIViewController?
    weak var inputTextView: LarkEditTextView?
    var chatId: String = ""
    var getMessageId: (() -> String)?
    private var lastRequstText: String = ""

    private var menuVC: MenuViewController?
    private let disposeBag = DisposeBag()
    let userResolver: UserResolver
    init(resolver: UserResolver) {
        self.userResolver = resolver
        self.enterpriseEntityWordService = try? userResolver.resolve(assert: EnterpriseEntityWordService.self)
        self.eewServiceApi = RustEnterpriseEntityWordAPI(resolver: resolver)
    }

    /// 请求企业百科高亮
    func getLingoHighlightSuggestion(chatId: String?, messageId: String?) -> Observable<([(NSRange, String)], ServerPB_Enterprise_entitiy_BatchRecallResponse)?> {
        guard let textView = inputTextView else {
            return Observable.just(nil)
        }

        let texts = splitAttributedString(text: textView.attributedText)
        return eewServiceApi.getLingoHighlight(texts: texts.map { $1 }, chatId: chatId, messageId: messageId)
            .observeOn(MainScheduler.instance)
            .map { [weak self] (response) -> ([(NSRange, String)], ServerPB_Enterprise_entitiy_BatchRecallResponse)? in
                /// 如果拿到响应的时候端上文本已经变化，本次的结果需要被丢弃
                if self?.isEquatable(lhs: texts, rhs: self?.splitAttributedString(text: textView.attributedText) ?? []) == true {
                    return (texts, response)
                } else {
                    return nil
                }
            }
    }

    func splitAttributedString(text: NSAttributedString) -> [(NSRange, String)] {
        var textArray: [(NSRange, String)] = []
        var inputAtrributeString = NSMutableAttributedString(attributedString: text)
        /// 首先挖掉企业百科的信息
        inputAtrributeString.enumerateAttributes(in: NSRange(location: 0, length: inputAtrributeString.length)) { (attr, attrRange, _) in
            if attr.keys.contains(LingoConvertService.LingoInfoKey) {
                inputAtrributeString.removeAttribute(.underlineStyle, range: attrRange)
                inputAtrributeString.removeAttribute(.underlineColor, range: attrRange)
                inputAtrributeString.removeAttribute(.link, range: attrRange)
                inputAtrributeString.removeAttribute(.backgroundColor, range: attrRange)
                inputAtrributeString.removeAttribute(LingoConvertService.LingoInfoKey, range: attrRange)
                inputAtrributeString.removeAttribute(AIFontStyleConfig.lingoHighlightAttributedKey, range: attrRange)
            }
            if attr.keys.contains(AIFontStyleConfig.smartCorrectAttribuedKey) {
                inputAtrributeString.removeAttribute(.underlineStyle, range: attrRange)
                inputAtrributeString.removeAttribute(.underlineColor, range: attrRange)
                inputAtrributeString.removeAttribute(.link, range: attrRange)
                inputAtrributeString.removeAttribute(.backgroundColor, range: attrRange)
                inputAtrributeString.removeAttribute(AIFontStyleConfig.smartCorrectAttribuedKey, range: attrRange)
            }
        }
        /// 再次进行分段
        inputAtrributeString.enumerateAttributes(in: NSRange(location: 0, length: text.length)) { _, attrRange, _ in
            let subText = text.attributedSubstring(from: attrRange).string
            textArray.append((attrRange, subText))
        }
        return textArray
    }

    func isEquatable(lhs: [(NSRange, String)], rhs: [(NSRange, String)]) -> Bool {
        if lhs.count != rhs.count {
            return false
        }

        for (index, tuple) in lhs.enumerated() {
            if tuple != rhs[index] {
                return false
            }
        }

        return true
    }

    func validateShouldRequestLingo(validateString: String) -> Bool {
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

    /// 展示高亮
    func showLingoHighlight(prefix: [(NSRange, String)], with response: ServerPB_Enterprise_entitiy_BatchRecallResponse) {
        guard let textView = inputTextView,
              isEquatable(lhs: prefix, rhs: splitAttributedString(text: textView.attributedText)) else {
            Self.logger.info("[lingoHighlight]: there have conflict between request and textView")
            return
        }
        let inputAtrributeString = NSMutableAttributedString(attributedString: textView.attributedText)
        /// 保留百科旧操作,移除上次添加的百科信息
        var lastLingoInfo: [String: SingleLingoElement] = [:]
        inputAtrributeString.enumerateAttributes(in: NSRange(location: 0, length: inputAtrributeString.length)) { (attr, attrRange, _) in
            if attr.keys.contains(LingoConvertService.LingoInfoKey),
                let info = attr[LingoConvertService.LingoInfoKey] as? SingleLingoElement {
                lastLingoInfo[info.name] = info
                inputAtrributeString.removeAttribute(.underlineStyle, range: attrRange)
                inputAtrributeString.removeAttribute(.underlineColor, range: attrRange)
                inputAtrributeString.removeAttribute(.link, range: attrRange)
                inputAtrributeString.removeAttribute(.backgroundColor, range: attrRange)
                inputAtrributeString.removeAttribute(LingoConvertService.LingoInfoKey, range: attrRange)
                inputAtrributeString.removeAttribute(AIFontStyleConfig.lingoHighlightAttributedKey, range: attrRange)
            }
            if attr.keys.contains(FontStyleConfig.underlineAttributedKey) {
                inputAtrributeString.addAttributes([.underlineStyle: FontStyleConfig.underlineStyle], range: attrRange)
            }
        }
        /// 处理本次服务端返回信息
        for (index, results) in response.phrases.enumerated() {
            for match in results.phrase {
                let inputString = inputAtrributeString.string
                let wordLength = Int(match.span.end - match.span.start)
                let location = Int(prefix[index].0.location) + Int(match.span.start)
                if inputString.utf16.count >= location + wordLength, wordLength > 0 {
                    guard let abbrId = match.ids.first else {
                        Self.logger.info("[lingoHighlight]: arrrId is Empty")
                        return
                    }
                    let range = NSRange(location: location, length: wordLength)
                    var pinId: String = ""
                    if let lingoInfo = lastLingoInfo[match.name] {
                        pinId = lingoInfo.pinId
                        /// 需要保存pin和忽略的操作，range/name/abbrId需要更新
                        var newLingoInfo = lingoInfo
                        newLingoInfo.location = location
                        newLingoInfo.length = wordLength
                        inputAtrributeString.addAttributes([LingoConvertService.LingoInfoKey: newLingoInfo], range: range)
                    } else {
                        let lingoModel = SingleLingoElement(abbrId: abbrId,
                                                            name: match.name,
                                                            location: location,
                                                            length: wordLength)
                        inputAtrributeString.addAttributes([LingoConvertService.LingoInfoKey: lingoModel], range: range)
                    }

                    if enableLingoHightlight(text: inputAtrributeString, range: range) {
                        continue
                    }
                    Self.logger.info("[lingoHighlight] abbrId: \(abbrId), match.id.count: \(match.ids.count), pinId: \(pinId)")
                    /// 应该展示哪一个URL，
                    /// 有多个释义-》有没有操作过pin/unpin，如果选过，应该展示黑色 （选中一个词语或者多释义卡片中关闭卡片）
                    /// 有多个释义-》有没有操作过pin/unpin，如果没有，应该展示红色
                    /// 有单个释义-》展示黑色
                    if match.ids.count > 1 && pinId.isEmpty && match.hasGuideType && match.guideType == .pin {
                        inputAtrributeString.addAttributes([AIFontStyleConfig.lingoHighlightAttributedKey: AIFontStyleConfig.lingoHighlightAttributedValue], range: range)
                        let attribute: [NSAttributedString.Key: Any] = [
                            .underlineStyle: NSUnderlineStyle.single.rawValue | NSUnderlineStyle.patternDot.rawValue,
                            .underlineColor: UIColor.ud.functionWarningFillDefault
                        ]
                        inputAtrributeString.addAttributes(attribute, range: range)
                        let link: URL? = LinkAttributeValue.lingoHighlight(id: abbrId, name: match.name, isSingleName: false).rawValue
                        if let link = link {
                            inputAtrributeString.addAttributes([.link: link], range: range)
                        }
                    } else {
                        inputAtrributeString.addAttributes([AIFontStyleConfig.lingoHighlightAttributedKey: AIFontStyleConfig.lingoHighlightAttributedValue], range: range)
                        let attribute: [NSAttributedString.Key: Any] = [
                            .underlineStyle: NSUnderlineStyle.single.rawValue | NSUnderlineStyle.patternDot.rawValue,
                            .underlineColor: UIColor.ud.N900.withAlphaComponent(0.60)
                        ]
                        inputAtrributeString.addAttributes(attribute, range: range)
                        var link: URL?
                        if !pinId.isEmpty {
                            link = LinkAttributeValue.lingoHighlight(id: abbrId, name: match.name, isSingleName: true, pinId: pinId).rawValue
                        } else {
                            link = LinkAttributeValue.lingoHighlight(id: abbrId, name: match.name, isSingleName: true).rawValue
                        }
                        if let link = link {
                            inputAtrributeString.addAttributes([.link: link], range: range)
                        }
                    }
                }
            }
        }

        textView.linkTextAttributes = [NSAttributedString.Key: Any]()
        replaceText(forTextView: textView, withAttributedText: inputAtrributeString)
        // 编辑文字、滚动textview、切换键盘类型、收起键盘，均收起提示卡片
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

    func enableLingoHightlight(text: NSAttributedString, range: NSRange) -> Bool {
        var containConflict = false
        /// 忽略过的词语不要展示，包含移动端菜单上的忽略，点击多释义卡片（以上都不是我想要的, 忽略提示）
        text.enumerateAttributes(in: range) { (info, _, _) in
            if info.keys.contains(LingoConvertService.LingoInfoKey) {
                if let lingoInfo = info[LingoConvertService.LingoInfoKey] as? SingleLingoElement, lingoInfo.isIgnore {
                    containConflict = true
                    Self.logger.info("[lingoHighlight]: user ignore this word")
                }
            }
            /// 纠错、人名、doc预览、url链接、代码、mention、emotion等
            var conflictKeys: Set<NSAttributedString.Key> = RichTextTransformKit.digOutRichTextNode
            conflictKeys.insert(AIFontStyleConfig.smartCorrectAttribuedKey)
            if !conflictKeys.isDisjoint(with: Set(info.keys)) {
                containConflict = true
                Self.logger.info("[lingoHighlight]: there has other richText Node!")
            }
        }
        return containConflict
    }
    func dismissMenuController() {
        guard let menuVC = self.menuVC else { return }
        menuVC.dismiss(animated: true, params: nil)
        self.menuVC = nil
    }

    @objc
    private func keyboardTypeChanged() {
        // 切换键盘类型、收起键盘，均收起纠错提示卡片
        self.dismissMenuController()
    }

    func textChange(text: String, textView: LarkEditTextView) {
        // 换行和发送关闭提示卡片
        if text.isEmpty {
            dismissMenuController()
        }
    }

    private func replaceText(forTextView textView: UITextView, withAttributedText attributedText: NSAttributedString) {
        // 记录光标位置 location 对应光标的位置
        let selectedRange = textView.selectedRange
        let offset = textView.contentOffset
        textView.attributedText = attributedText
        // 重新设置光标位置
        textView.selectedRange = selectedRange
        textView.setContentOffset(offset, animated: false)
    }

    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        Self.logger.info("[lingoHighlight]: lingo highLight Card Show with url:\(url.absoluteString) ")
        guard let link = LinkAttributeValue(rawValue: url), case .lingoHighlight(let id, let name, let isSingleName, let pinId) = link else {
            return false
        }
        let inputAtrributeString = NSMutableAttributedString(attributedString: textView.attributedText)
        if !isSingleName {
            inputAtrributeString.addAttributes([.backgroundColor: UIColor.ud.functionWarningFillDefault.withAlphaComponent(0.2)], range: characterRange)
        }
        textView.selectedRange = NSRange(location: characterRange.location + characterRange.length, length: 0)
        replaceText(forTextView: textView, withAttributedText: inputAtrributeString)
        let text = textView.attributedText.attributedSubstring(from: characterRange)
        let textRects: [CGRect] = rects(forString: text.string, in: textView, range: characterRange)
        let textfirstRect: CGRect = textRects.first ?? CGRect.zero
        guard let fromVC = viewController else {
            Self.logger.info("[lingoHighlight]: from vc is nil")
            return false
        }
        LingoHighlightTracker.showAbbrMobileTip(abbrId: id)
        let menuString = isSingleName ? BundleI18n.LarkAI.Lark_Lingo_IM_EntryDetected_ViewEntryButton : BundleI18n.LarkAI.Lark_Lingo_IMInputField_WordMeaningUnclearHover_DefineButton

        let layout = AIMenuLayout(leadingInset: 10, horizontalCenter: false)
        let cardViewModel = LingoHighlightMenuViewModel(originSize: fromVC.view.bounds.size,
                                                        menuText: menuString,
                                                        tapPoint: CGPoint(x: textfirstRect.centerX, y: textfirstRect.centerY),
                                                        textView: textView,
                                                        cardLayout: layout,
                                                        selectedActionCallback: { [weak self] in
            guard let self = self else { return }
            /// 打开百科卡片有三种场景：
            /// - 多释义卡片
            /// - 百科卡片
            /// - pin过的百科卡片
            let pageType: LingoPageEnum = isSingleName ? .LingoCard : .MutipleSelection
            self.openEnterpriseCard(id: id,
                                    name: name,
                                    fromVC: fromVC,
                                    pageType: pageType,
                                    range: characterRange,
                                    pinId: pinId)
            LingoHighlightTracker.clickAbbrMobileTip(abbrId: id, clickType: isSingleName ? .Entity : .ChooseEntity)
        }, abandonActionCallback: { [weak self] in
            guard let self = self else { return }
            self.dismissMenuController()
            self.removeLingoHighlightTip(in: characterRange)
            if let window = self.navigator.mainSceneWindow {
                UDToast().showTips(with: BundleI18n.LarkAI.Lark_Lingo_LingoCard_IgnoreEntry_EntryIgnoredToast, on: window)
            }
            LingoHighlightTracker.clickAbbrMobileTip(abbrId: id, clickType: .Ignore)
            Self.logger.info("[LingoHighlight] click abandon with text:\(name) ")
        })
        let menuVC = MenuViewController(viewModel: cardViewModel,
                                        layout: layout,
                                        trigerView: textView,
                                        trigerLocation: CGPoint(x: textfirstRect.centerX, y: textfirstRect.centerY))
        menuVC.dismissBlock = { [weak self] in
            guard let self = self else { return }
            self.menuVC = nil
            let inputAtrributeString = NSMutableAttributedString(attributedString: textView.attributedText)
            guard inputAtrributeString.length >= (characterRange.location + characterRange.length) else { return }
            inputAtrributeString.removeAttribute(.backgroundColor, range: characterRange)
            self.replaceText(forTextView: textView, withAttributedText: inputAtrributeString)
            Self.logger.info("[lingoHighlight]: dismiss lingo menu")
        }
        menuVC.show(in: fromVC)
        menuVC.menuDidShow = {
            cardViewModel.cardView.drawCardBorder()
        }
        self.menuVC = menuVC
        return false
    }

    /// 打开企业百科实体词卡片
    private func openEnterpriseCard(id: String,
                                    name: String,
                                    fromVC: UIViewController,
                                    pageType: LingoPageEnum,
                                    range: NSRange,
                                    pinId: String? = nil) {
        var clientArgs: String?
        let analysisParams: [String: Any] = [
            "card_source": "im_input_card",
            "message_id": self.getMessageId?() ?? "",
            "chat_id": self.chatId
        ]
        let pinInfo: [String: Any] = [
            "abbrId": pinId ?? "",
            "isGlobal": false,
            "requestService": false
        ]
        let ignoreInfo: [String: Any] = [
            "isGlobal": false,
            "requestService": false
        ]
        let extra: [String: Any] = [
            "space": SpaceType.IM.rawValue,
            "spaceId": self.chatId,
            "spaceSubId": self.getMessageId?() ?? "",
            "pinInfo": pinInfo,
            "ignoreInfo": ignoreInfo,
            "showPin": AIFeatureGating.lingoHighlightOnKeyboard.isUserEnabled(userResolver: userResolver)
        ]

        let params: [String: Any] = [
            "page": pageType.rawValue,
            "showIgnore": AIFeatureGating.lingoHighlightOnKeyboard.isUserEnabled(userResolver: userResolver),
            "analysisParams": analysisParams,
            "extra": extra
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: params) {
            clientArgs = String(data: jsonData, encoding: String.Encoding.utf8)
        }
        self.enterpriseEntityWordService?.showEnterpriseTopic(abbrId: id,
                                                             query: name,
                                                             chatId: self.chatId,
                                                             sense: .messenger,
                                                             targetVC: fromVC,
                                                             completion: nil,
                                                             clientArgs: clientArgs,
                                                             passThroughAction: { [weak self] (params) in
            /// lynx的线程，但是将会操作ui,所以需要在主线程上跑
            DispatchQueue.main.async {
                self?.cardClickPassThrough(params: params, abbrId: id, query: name, range: range)
            }
        })
    }

    /// 处理lynx卡片的回传事件，根据type的取值，需要处理下面几类事件：
    /// ignore：             忽略词条
    /// close：              关闭卡片
    /// pin：                选中释义/取消pin
    private func cardClickPassThrough(params: String, abbrId: String, query: String, range: NSRange) {
        guard let data = params.data(using: .utf8),
           let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] else {
            Self.logger.info("[lingoHightlight]: parse passThrough data failed!")
            return
        }
        if let type = json["type"] as? String,
            let passThroughType = PassThroughType(rawValue: type) {
            switch passThroughType {
            case .ignore:
                removeLingoHighlightTip(in: range)
            case .pin:
                if let pinId = json["pinId"] as? String,
                   let entityId = json["entityId"] as? String,
                   !pinId.isEmpty, !entityId.isEmpty {
                    pinEnterpriseWord(abbrId: abbrId, query: query, range: range, pinId: pinId)
                }
            case .unPin:
                unpinEnterpriseWord(abbrId: abbrId, query: query, range: range)
            default: break
            }
        }
        dismissMenuController()

    }

    /// 卡片中pin选词语
    /// - Parameters:
    ///   - abbrId:   词条id
    ///   - range:    词条位置信息
    ///   - pinId:    pin选的词条id
    ///   - pinName:  pin选的词条name
    func pinEnterpriseWord(abbrId: String, query: String, range: NSRange, pinId: String) {
        guard let textView = inputTextView else { return }
        let inputAtrributeString = NSMutableAttributedString(attributedString: textView.attributedText)
        guard inputAtrributeString.length >= (range.location + range.length) else { return }
        inputAtrributeString.removeAttribute(.underlineColor, range: range)
        inputAtrributeString.removeAttribute(.backgroundColor, range: range)
        inputAtrributeString.enumerateAttributes(in: range, options: []) { (attribute, attributeRange, _) in
            /// 更新URL
            if attribute.keys.contains(.link),
               let newLink = LinkAttributeValue.lingoHighlight(id: abbrId, name: query, isSingleName: true, pinId: pinId).rawValue {
                inputAtrributeString.addAttributes([.link: newLink], range: attributeRange)
            }
            /// 更新模型数据
            if attribute.keys.contains(LingoConvertService.LingoInfoKey) {
                if let lingoInfo = attribute[LingoConvertService.LingoInfoKey] as? SingleLingoElement,
                    lingoInfo.abbrId == abbrId {
                    var newlingoInfo = lingoInfo
                    newlingoInfo.pinId = pinId
                    inputAtrributeString.addAttributes([LingoConvertService.LingoInfoKey: newlingoInfo], range: attributeRange)
                } else {
                    Self.logger.info("""
                                    [ligoHighlight]: pin Failed!
                                    abbrID \(abbrId),
                                    SingleLingoElement id \(String(describing: (attribute[LingoConvertService.LingoInfoKey] as? SingleLingoElement)?.abbrId))
                                    """)
                }
            }
        }
        replaceText(forTextView: textView, withAttributedText: inputAtrributeString)
    }

    /// 百科卡片unpin词条
    /// - Parameters:
    ///   - abbrId: 词条id
    ///   - range: 词条位置信息
    func unpinEnterpriseWord(abbrId: String, query: String, range: NSRange) {
        guard let textView = inputTextView else { return }
        let inputAtrributeString = NSMutableAttributedString(attributedString: textView.attributedText)
        guard inputAtrributeString.length >= (range.location + range.length) else { return }
        inputAtrributeString.removeAttribute(.backgroundColor, range: range)
        inputAtrributeString.enumerateAttributes(in: range, options: []) { (attribute, attributeRange, _) in
            /// 更新URL, 更新UI
            if attribute.keys.contains(.link),
               let newLink = LinkAttributeValue.lingoHighlight(id: abbrId, name: query, isSingleName: false).rawValue {
                inputAtrributeString.addAttributes([.link: newLink, .underlineColor: UIColor.ud.functionWarningFillDefault], range: attributeRange)
            }
            /// 更新模型数据
            if attribute.keys.contains(LingoConvertService.LingoInfoKey) {
                if let lingoInfo = attribute[LingoConvertService.LingoInfoKey] as? SingleLingoElement,
                    lingoInfo.abbrId == abbrId {
                    var newlingoInfo = lingoInfo
                    newlingoInfo.pinId = ""
                    inputAtrributeString.addAttributes([LingoConvertService.LingoInfoKey: newlingoInfo], range: attributeRange)
                } else {
                    Self.logger.info("""
                                    [ligoHighlight]: unpin Failed!
                                    abbrID \(abbrId),
                                    SingleLingoElement id \(String(describing: (attribute[LingoConvertService.LingoInfoKey] as? SingleLingoElement)?.abbrId))
                                    """)
                }
            }
        }
        replaceText(forTextView: textView, withAttributedText: inputAtrributeString)
    }

    /// 忽略百科词条
    /// - Parameter range: 词条在textView中的位置
    func removeLingoHighlightTip(in range: NSRange) {
        guard let textView = inputTextView else { return }
        let inputAtrributeString = NSMutableAttributedString(attributedString: textView.attributedText)
        guard inputAtrributeString.length >= (range.location + range.length) else { return }
        inputAtrributeString.removeAttribute(AIFontStyleConfig.lingoHighlightAttributedKey, range: range)
        inputAtrributeString.removeAttribute(.underlineStyle, range: range)
        inputAtrributeString.removeAttribute(.underlineColor, range: range)
        inputAtrributeString.removeAttribute(.link, range: range)
        inputAtrributeString.removeAttribute(.backgroundColor, range: range)
        inputAtrributeString.enumerateAttributes(in: range, options: []) { (attribute, attributeRange, _) in
            /// 防止手工添加下划线被删除
            if attribute.keys.contains(FontStyleConfig.underlineAttributedKey) {
                inputAtrributeString.addAttributes([.underlineStyle: FontStyleConfig.underlineStyle], range: attributeRange)
            }
            /// 更新模型数据
            if attribute.keys.contains(LingoConvertService.LingoInfoKey) {
                if let lingoInfo = attribute[LingoConvertService.LingoInfoKey] as? SingleLingoElement {
                    var newlingoInfo = lingoInfo
                    newlingoInfo.isIgnore = true
                    inputAtrributeString.addAttributes([LingoConvertService.LingoInfoKey: newlingoInfo], range: attributeRange)
                }
            }
        }
        replaceText(forTextView: textView, withAttributedText: inputAtrributeString)
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

}
