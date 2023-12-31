//
//  CodeInputHandler.swift
//  LarkKeyboardView
//
//  Created by Bytedance on 2022/11/15.
//

import UIKit
import RustPB
import LarkEMM
import Foundation
import EditTextView

/// pasteHandler时，记录一下上下文信息
class ProviderContext {
    var fontProvider: FontStyleItemProvider?
    var emojiProvider: EmojiItemProvider?
    var codeProvider: CodeItemProvider?
}

public final class CodeInputHandler: TextViewInputProtocol {
    let supportFontStyle: Bool
    private var pasteboardRedesignFg: Bool {
        return LarkPasteboardConfig.useRedesign
    }
    // MARK: - init
    public init(supportFontStyle: Bool) {
        self.supportFontStyle = supportFontStyle
    }

    // MARK: - TextViewInputProtocol
    /// 处理 TextView 复制粘贴代码
    public func register(textView: UITextView) {
        guard let textView = textView as? LarkEditTextView else { return }
        let handler = CustomSubInteractionHandler()
        handler.supportPasteType = .codeBlock
        // 设置独特的标示
        handler.btd_attach("CodeInputHandler", forKey: "ClassName")
        let defaultTypingAttributes = textView.defaultTypingAttributes
        // 输入框中拷贝了内容
        handler.copyHandler = { [weak self] (textView) in
            guard let self = self else {
                return false
            }
            let selectedRange = textView.selectedRange
            if selectedRange.length > 0, let attributedText = textView.attributedText {
                let subAttributedText = attributedText.attributedSubstring(from: selectedRange)
                // 如果不包含代码块，则交由EmojiInputHandler处理
                let containsCode = CodeInputHandler.attributedTextContainsCode(attributedText: subAttributedText)
                if self.pasteboardRedesignFg {
                    return containsCode
                }
                if !containsCode { return false }

                DispatchQueue.main.async {
                    // 把Emoji从CustomTextAttachment替换为[微笑]
                    var pasteString = EmotionTransformer.retransformContentToString(subAttributedText)
                    // 把Code从CustomTextAttachment替换为代码内容
                    pasteString = CodeTransformer.retransformTextAttachmentToString(pasteString)
                    // 字体不需要进行替换等操作，因为字体已经在subAttributedText中体现了

                    SCPasteboard.generalPasteboard().string = pasteString.string
                    // 向剪切板里面添加代码块相关信息
                    self.addCodeKeyInfoWith(attributedText: pasteString)
                    // 向剪切板里面添加字体相关信息
                    self.addFontStyleInfoWith(attributedText: pasteString)
                    // 向剪切板里面添加emojKey相关信息
                    self.addEmojiKeyInfoWith(attributedText: pasteString)
                }
            }
            return false
        }
        // 输入框中粘贴了内容
        handler.pasteHandler = { [weak self] (textView) in
            // 如果不包含代码块，则交由EmojiInputHandler处理
            guard let `self` = self, CodeInputHandler.pasteboardContainsCode() else { return false }
            // 如果string没内容，说明是赋值了图片等其他富媒体内容，我们不进行处理
            guard let pasteboardString = SCPasteboard.generalPasteboard().string else { return false }

            let pasteContext = ProviderContext()
            // 从剪贴板里加载出所有的ItemProvider
            self.loadItemProvider(pasteContext: pasteContext) {
                // 开始附加剪贴板的内容，剪贴板的内容为初始值；处理优先级：Font > Code > Emoji，尽量保持之前的逻辑
                var resultAttributeString = NSAttributedString(string: pasteboardString, attributes: defaultTypingAttributes)
                // Font
                resultAttributeString = pasteContext.fontProvider?.attributeStringWithAttributes(defaultTypingAttributes) ?? resultAttributeString
                // Code
                resultAttributeString = pasteContext.codeProvider?.transformPasteAttributedString(attributedString: resultAttributeString) ?? resultAttributeString
                // Emoji，根据Code替换信息，修正剪贴板中记录的Emoji的Range
                var emojiKeyMap = pasteContext.emojiProvider?.emojiKeyMapping() ?? [:]
                emojiKeyMap = pasteContext.codeProvider?.fixEmojiKeyMapping(map: emojiKeyMap) ?? emojiKeyMap
                resultAttributeString = EmotionTransformer.transformPasteAttributedStringToRichText(
                    resultAttributeString,
                    attributes: defaultTypingAttributes,
                    matchResult: EmotionTransformer.regularResult(resultAttributeString.string),
                    emojiKeyMap: emojiKeyMap
                )

                // 这里还有一步，代码块需要换行显示，所以需要在代码块后面加一个"\n"
                // 不需要了，CodeTransformer.transformToRichText会让代码块发送出去后，作为单独的一行展示
                // resultAttributeString = self.addReturnCodeIfNeeded(attributedText: resultAttributeString)

                // 赋值到输入框
                let selectedRange = textView.selectedRange
                let attributedText = NSMutableAttributedString(attributedString: textView.attributedText ?? NSAttributedString())
                if selectedRange.length > 0 {
                    attributedText.replaceCharacters(in: selectedRange, with: resultAttributeString)
                } else {
                    attributedText.insert(resultAttributeString, at: selectedRange.location)
                }
                textView.attributedText = attributedText
            }
            // 这里需要return true，让UITextPasteDelegate-textPasteConfigurationSupporting失效，因为我们已经设置过textView.attributedText了
            return true
        }
        // 输入框中剪切了内容，直接复用copyHandler逻辑
        handler.cutHandler = handler.copyHandler
        handler.pasteboardStringHandler = { attr in
            return CodeTransformer.retransformTextAttachmentToString(attr)
        }
        textView.interactionHandler.registerSubInteractionHandler(handler: handler)
    }

    // MARK: - private
    private func addFontStyleInfoWith(attributedText: NSAttributedString) {
        if !self.supportFontStyle { return }
        let style = FontStyleItemProvider.styleForAttributedString(attributedText)
        if !style.isEmpty, let json = FontStyleItemProvider.JSONStringWithStyle(style, content: attributedText.string) {
            SCPasteboard.generalPasteboard().addItems([[FontStyleItemProvider.typeIdentifier: json]])
        }
    }
    private func addEmojiKeyInfoWith(attributedText: NSAttributedString) {
        let emoji = EmojiItemProvider.emojiKeyForAttributedString(attributedText)
        if !emoji.isEmpty, let json = EmojiItemProvider.JSONStringWithEmoji(emoji, content: attributedText.string) {
            SCPasteboard.generalPasteboard().addItems([[EmojiItemProvider.emojiIdentifier: json]])
        }
    }
    private func addCodeKeyInfoWith(attributedText: NSAttributedString) {
        let code = CodeItemProvider.codeKeyForAttributedString(attributedText)
        if !code.isEmpty, let json = CodeItemProvider.JSONStringWithCode(code, content: attributedText.string) {
            SCPasteboard.generalPasteboard().addItems([[CodeItemProvider.codeIdentifier: json]])
        }
    }
    /// 从剪贴板里加载出所有的ItemProvider，finish在主线程回调
    private func loadItemProvider(pasteContext: ProviderContext, finish: @escaping () -> Void) {
        // 同时加载三个ItemProvider，提升速度，避免粘贴时久久才看到内容
        let group = DispatchGroup()
        // 加载代码块
        let loadCodeStyleItemProvider: () -> Void = {
            group.enter()
            let itemProviders = SCPasteboard.generalPasteboard().itemProviders?.filter { $0.canLoadObject(ofClass: CodeItemProvider.self) }
            if let provider = itemProviders?.last {
                provider.loadObject(ofClass: CodeItemProvider.self) { obj, error in
                    pasteContext.codeProvider = obj as? CodeItemProvider
                    group.leave()
                }
            } else { group.leave() }
        }
        // 加载Emoji
        let loadEmojiStyleItemProvider: () -> Void = {
            group.enter()
            let itemProviders = SCPasteboard.generalPasteboard().itemProviders?.filter { $0.canLoadObject(ofClass: EmojiItemProvider.self) }
            if let provider = itemProviders?.last {
                provider.loadObject(ofClass: EmojiItemProvider.self) { obj, error in
                    pasteContext.emojiProvider = obj as? EmojiItemProvider
                    group.leave()
                }
            } else { group.leave() }
        }
        // 加载字体
        let loadFontStyleItemProvider: () -> Void = {
            group.enter()
            let itemProviders = SCPasteboard.generalPasteboard().itemProviders?.filter { $0.canLoadObject(ofClass: FontStyleItemProvider.self) }
            if self.supportFontStyle, let provider = itemProviders?.last {
                provider.loadObject(ofClass: FontStyleItemProvider.self) { obj, error in
                    pasteContext.fontProvider = obj as? FontStyleItemProvider
                    group.leave()
                }
            } else { group.leave() }
        }

        // 开始加载ItemProvider
        loadFontStyleItemProvider()
        loadCodeStyleItemProvider()
        loadEmojiStyleItemProvider()

        // 监听加载完成结果，主线程回调
        group.notify(queue: .main) { finish() }
    }

    // MARK: - static
    /// 剪贴板中是否包含代码块信息
    public static func pasteboardContainsCode() -> Bool {
        let itemProviders = SCPasteboard.generalPasteboard().itemProviders?.filter { itemProvider in
            itemProvider.canLoadObject(ofClass: CodeItemProvider.self)
        }
        return itemProviders?.last != nil
    }
    /// 属性字符串中是否包含代码块信息
    public static func attributedTextContainsCode(attributedText: NSAttributedString) -> Bool {
        var hasCodeKey = false
        attributedText.enumerateAttribute(CodeTransformer.editCodeKey, in: NSRange(location: 0, length: attributedText.length), options: [.longestEffectiveRangeNotRequired], using: { (value, _, stop) in
            if value != nil {
                hasCodeKey = true
                stop.pointee = true
            }
        })
        return hasCodeKey
    }
    /// RichText中是否包含代码块信息
    public static func richTextContainsCode(richText: Basic_V1_RichText) -> Bool {
        var hasCode = false
        richText.elements.forEach { (_, value) in
            if hasCode { return }

            if value.property.hasCodeBlockV2 {
                hasCode = true
            }
        }
        return hasCode
    }
    /// EditTextView.BaseEditTextView是否注册了CodeInputHandler
    public static func editTextViewRegisterCode(textView: BaseEditTextView) -> Bool {
        var hasRegisterCode = false
        textView.interactionHandler.subHandlers.forEach { handler in
            if hasRegisterCode { return }

            if let object = handler.btd_getAttachedObject(forKey: "ClassName") as? String, object == "CodeInputHandler" {
                hasRegisterCode = true
            }
        }
        return hasRegisterCode
    }
}

