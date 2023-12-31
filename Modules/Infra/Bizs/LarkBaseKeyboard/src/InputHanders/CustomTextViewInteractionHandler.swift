//
//  CustomTextViewInteractionHandler.swift
//  LarkKeyboardView
//
//  Created by liluobin on 2023/1/9.
//

import UIKit
import Foundation
import EditTextView
import RustPB
import LarkEMM
import LarkSensitivityControl
import LKCommonsLogging
import LarkFeatureGating

public class LarkPasteboardConfig {
    public static var useRedesignAbility: (()-> Bool)?

    public static var useRedesign: Bool {
        if !Thread.current.isMainThread {
            assertionFailure("need to config isMainThread")
        }
        if let useRedesignAbility = useRedesignAbility {
            return useRedesignAbility()
        }
        assertionFailure("need to config useRedesignAbility")
        return false
    }

    public static func pasteboardItemRandomKey() -> String {
        return "\(Date().timeIntervalSince1970)" + "_" + "\(Int((arc4random() % 100)))"
    }
}

public class TextViewCustomPasteConfig {
    public static var useNewPasteFG: Bool {
        return LarkFeatureGating.shared.getStaticBoolValue(for: "messenger.input.copy_url_anchor")
    }
}

public class CustomTextViewInteractionHandler: TextViewInteractionHandler {

    var pasteboardRedesignFg: Bool  {
        return LarkPasteboardConfig.useRedesign
    }
    public static let isSingleUrlInLineKey = "isSingleUrlInLine"
    /// 业务放根据需求自行选择解析粘贴普通文本的处理方式
    /// useCustomPasteFragment = true, 必须使用CustomSubInteractionHandler，inputHander中使用SubInteractionHandler会无法触发
    /// useCustomPasteFragment = false, 可以使用SubInteractionHandler
    public var useCustomPasteFragment = false

    lazy var pasteManager: CustomTextViewPasteManagerProtocol = {
        return CustomTextViewPasteManager(token: self.pasteboardToken)
    }()

    public var filterAttrbutedStringBeforePaste: ((NSAttributedString, [String: String]) -> NSAttributedString)?
    public var canApplyPasteboardInfo: ((NSAttributedString) -> Bool)?
    public var didApplyPasteboardInfo: ((Bool, NSAttributedString, [String: String]) -> Void)?
    public var getExpandInfoSaveToPasteBoard: (() -> [String: String])?

    // TODO: 闭包回调方式需要改造
    /// 目前只有 QuickActionInputHandler 在用，其他业务暂时不要使用
    public var shouldChange: ((NSRange, NSAttributedString) -> Bool)?
    /// 目前只有 QuickActionInputHandler 在用，其他业务暂时不要使用
    public var didChange: (() -> Void)?

    static let logger = Logger.log(CustomTextViewInteractionHandler.self, category: "CustomTextViewInteractionHandler")

    let pasteboardToken: String

    public init(pasteboardToken: String) {
        self.pasteboardToken = pasteboardToken
        if pasteboardToken.isEmpty {
            assertionFailure("pasteboardToken can be empty")
        }
        super.init()
    }

    @available(*, deprecated, message: "Please use init(pasteboardToken: String), this func will be remove in future")
    public convenience override init() {
        self.init(pasteboardToken: "")
    }

    public override func copyHandler(_ textView: BaseEditTextView) -> Bool {
        let value = super.copyHandler(textView)
        guard pasteboardRedesignFg else {
            return value
        }
        saveCopyInfo(textView, save: value)
        return false
    }

    public override func pasteHandler(_ textView: BaseEditTextView) -> Bool {
        /// 先用原有的解析方式解析一下，不支持的话 进项降级处理
        let tokenStr = self.pasteboardToken
        let config = PasteboardConfig(token: Token(tokenStr))
        var itemProvider: [NSItemProvider]?
        do {
            try itemProvider = SCPasteboard.generalUnsafe(config).itemProviders
        } catch {
            // 复制失败兜底逻辑
            itemProvider = []
            Self.logger.error("pasteHandler pasteboardConfig init fail token:\(self.pasteboardToken)")
        }
        if let provider = itemProvider?.first(where: { provider in
            provider.canLoadObject(ofClass: CopyRichStyleItemProvider.self)}) {
            super.pasteCallBack(textView)
            provider.loadObject(ofClass: CopyRichStyleItemProvider.self) { [weak textView] item, error in
                if let error = error {
                    DispatchQueue.main.async {
                        Self.downgradeForLoadError(textView: textView, pasteboardToken: tokenStr)
                    }
                    Self.logger.error("CopyRichStyleItemProvider  loadObject error ", error: error)
                    return
                }
                DispatchQueue.main.async {
                    guard let textView = textView else { return }
                    if let key = (item as? CopyRichStyleItemProvider)?.json,
                       let json = CustomPasteboardCache.share.getInfo(key: key),
                       let model = CustomPasteboardModel.parseJsonStr(json),
                       let pb = try? RustPB.Basic_V1_RichText(jsonString: model.content) {
                        var attributes = (textView as? LarkEditTextView)?.defaultTypingAttributes ?? [:]
                        attributes = Self.baseTypingAttributes(attributes)
                        let supportTypes: [String] = self.subHandlers.flatMap { subHander in
                            guard let subHander = subHander as? CustomSubInteractionHandler else {
                                return [String]()
                            }
                            switch subHander.supportPasteType {
                            case .none:
                                return [String]()
                            case .emoji:
                                return [NSStringFromClass(EmotionTransformer.self)]
                            case .at:
                                return [NSStringFromClass(AtTransformer.self)]
                            case .anchor:
                                return [NSStringFromClass(AnchorTransformer.self)]
                            case .link:
                                return [NSStringFromClass(LinkTransformer.self)]
                            case .codeBlock:
                                return [NSStringFromClass(CodeTransformer.self)]
                            case .font:
                                return [NSStringFromClass(TextTransformer.self),
                                        NSStringFromClass(FontTransformer.self)]
                            case .image:
                                return [NSStringFromClass(ImageTransformer.self)]
                            case .video:
                                return [NSStringFromClass(VideoTransformer.self)]
                            }
                        }

                        if !supportTypes.contains(NSStringFromClass(LinkTransformer.self)),
                           (model.expandInfo[Self.isSingleUrlInLineKey]) != nil,
                            self.customHandlerPasteText(textView) {
                            return
                        }

                        var attr = RichTextTransformKit.transformRichTextToStrWithoutDowngrade(richText: pb,
                                                                                               attributes: attributes,
                                                                                               attachmentResult: [:],
                                                                                               supportTypes: supportTypes)
                        let selectedRange = textView.selectedRange
                        let attributedText = NSMutableAttributedString(attributedString: textView.attributedText ?? NSAttributedString())
                        if let filter = self.filterAttrbutedStringBeforePaste {
                            attr = filter(attr, model.expandInfo)
                        }
                        attr = AttributedStringAttachmentAnalyzer.separateAttachmentIfNeed(attr,
                                                                                           originText: attributedText,
                                                                                           range: selectedRange)
                        var changeRange = selectedRange
                        if selectedRange.length > 0 {
                            attributedText.replaceCharacters(in: selectedRange, with: attr)
                        } else {
                            changeRange = NSRange(location: selectedRange.location, length: 0)
                            attributedText.insert(attr, at: selectedRange.location)
                        }
                        let canApply = self.canApplyPasteboardInfo?(attributedText) ?? true
                        if canApply, self.shouldChange?(changeRange, attr) ?? true {
                            textView.attributedText = attributedText
                            /// 粘贴后光标位置需要调整，模拟系统提升体验
                            let range = NSRange(location: selectedRange.location + attr.length,
                                                length: 0)
                            textView.selectedRange = range
                            textView.scrollRangeToVisible(range)
                            self.didChange?()
                            self.didApplyPasteboardInfo?(true, attr, model.expandInfo)
                        }
                    } else {
                        /// 兜底逻辑 触发情况
                        /// 1. 缓存意外失效了
                        /// 2. 飞书的其他版本App粘贴
                        Self.downgradeForLoadError(textView: textView, pasteboardToken: tokenStr)
                        Self.logger.error("CopyRichStyleItemProvider  loadObject json nil ")
                    }
                }
            }
            return true
        } else {
           return self.customHandlerPasteText(textView)
        }
    }

    private func customHandlerPasteText(_ textView: BaseEditTextView) -> Bool {
        if TextViewCustomPasteConfig.useNewPasteFG, useCustomPasteFragment {
            self.pasteCallBack(textView)
            var attributes = (textView as? LarkEditTextView)?.defaultTypingAttributes ?? [:]
            attributes = Self.baseTypingAttributes(attributes)
            return self.pasteManager.handlerPasteStrForTextView(textView, attributes: attributes)
        } else {
            return super.pasteHandler(textView)
        }
    }

    public override func cutHandler(_ textView: BaseEditTextView) -> Bool {
        let value = super.cutHandler(textView)
        guard pasteboardRedesignFg else {
            return value
        }
        saveCopyInfo(textView, save: value)
        return false
    }

    private func saveCopyInfo(_ textView: BaseEditTextView, save: Bool) {
        let attr = self.pasteboardStringHandler(textView)
        guard save else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let config = PasteboardConfig(token: Token(self.pasteboardToken))
                do {
                    try SCPasteboard.generalUnsafe(config).string = attr.string
                } catch {
                    // 复制失败兜底逻辑
                    Self.logger.error("saveCopyInfo pasteboardConfig init fail token:\(self.pasteboardToken)")
                }
            }
            return
        }
        let selectedRange = textView.selectedRange
        guard selectedRange.length > 0, let attributedText = textView.attributedText else {
            return
        }
        var subAttributedText = attributedText.attributedSubstring(from: textView.selectedRange)
        self.subHandlers.forEach { hander in
            if let hander = hander as? CustomSubInteractionHandler,
               let newAtt = hander.willAddInfoToPasteboard?(subAttributedText) {
                 subAttributedText = newAtt
            }
        }

        /// 在复制之前 需要处理一下这种情况光标局部选中-> 【@张|三】额外额外企鹅我去 【文|档A】
        ///                                            ---------------------
        let pb = RichTextTransformKit.transformStringToRichText(string: subAttributedText)
        let json = (try? pb?.jsonString()) ?? ""
        if !json.isEmpty {
            /// 这里需要async，否则会被系统的剪切板覆盖
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let config = PasteboardConfig(token: Token(self.pasteboardToken))
                do {
                    try SCPasteboard.generalUnsafe(config).string = attr.string
                } catch {
                    // 复制失败兜底逻辑
                    Self.logger.error("saveCopyInfo pasteboardConfig init fail token:\(self.pasteboardToken)")
                }
                let key = LarkPasteboardConfig.pasteboardItemRandomKey()
                let expandInfo = self.getExpandInfoSaveToPasteBoard?() ?? [:]
                let value = CustomPasteboardModel(content: json, expandInfo: expandInfo).stringify()
                CustomPasteboardCache.share.saveInfo([key: value])
                SCPasteboard.general(config).addItems([[CopyRichStyleItemProvider.typeIdentifier: key]])
            }
        }
    }

    open func pasteboardStringHandler(_ textView: BaseEditTextView) -> NSAttributedString {
        let selectedRange = textView.selectedRange
        if selectedRange.length > 0, let attributedText = textView.attributedText {
            var subAttributedText = attributedText.attributedSubstring(from: selectedRange)
            self.subHandlers.forEach { (sub) in
                if let sub = sub as? CustomSubInteractionHandler,
                   let strHander = sub.pasteboardStringHandler {
                    subAttributedText = strHander(subAttributedText)
                }
            }
            return subAttributedText
        }
        return NSAttributedString()
    }

    private static func baseTypingAttributes(_ defaultTypingAttributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [:]
        /// 有特殊样式需要去除一下
        if let defaultFont = defaultTypingAttributes[.font] as? UIFont, (defaultFont.isBold || defaultFont.isItalic) {
            attributes[.font] = defaultFont.withoutTraits(.traitBold, .traitItalic)
        } else {
            attributes[.font] = defaultTypingAttributes[.font]
        }
        attributes[.foregroundColor] = defaultTypingAttributes[.foregroundColor]
        attributes[.paragraphStyle] = defaultTypingAttributes[.paragraphStyle]
        return attributes
    }

    private static func downgradeForLoadError(textView: BaseEditTextView?,
                                              pasteboardToken: String) {
        guard let textView = textView else { return }
        let selectedRange = textView.selectedRange
        let attributedText = NSMutableAttributedString(attributedString: textView.attributedText ?? NSAttributedString())
        let config = PasteboardConfig(token: Token(pasteboardToken))
        if let str = SCPasteboard.general(config).string {
            var attributes = (textView as? LarkEditTextView)?.defaultTypingAttributes ?? [:]
            attributes = Self.baseTypingAttributes(attributes)
            let replace = NSAttributedString(string: str, attributes: attributes)
            attributedText.replaceCharacters(in: selectedRange,
                                             with: replace)
            textView.attributedText = attributedText
            let range = NSRange(location: selectedRange.location + replace.length,
                                length: 0)
            textView.selectedRange = range
            textView.scrollRangeToVisible(range)
        }
    }
}

public enum TextViewSupportPasteType {
   case none
   case emoji
   case font
   case at
   case codeBlock
   case image
   case video
   case anchor
   case link
}

public class CustomSubInteractionHandler: SubInteractionHandler {
    open var pasteboardStringHandler: ((NSAttributedString) -> NSAttributedString)?
    open var willAddInfoToPasteboard: ((NSAttributedString) -> NSAttributedString)?
    /// 粘贴富文本 从当前App的消息或者输入框中复制粘贴
    open var supportPasteType: TextViewSupportPasteType = .none
    /// 粘贴普通文本，从其他App复制粘贴 需要正则匹配解析数据的 比如粘了一段包含链接的文字
    open var handerPasteTextType: CustomPasteHanderType = .none
}
