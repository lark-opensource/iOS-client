//
//  EmojiInputHandler.swift
//  Lark
//
//  Created by lichen on 2017/11/6.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkUIKit
import LarkModel
import LarkFoundation
import EditTextView
import LarkEMM

public final class EmojiInputHandler: TextViewInputProtocol {
    let supportFontStyle: Bool
    private var pasteboardRedesignFg: Bool {
        return LarkPasteboardConfig.useRedesign
    }

    public init(supportFontStyle: Bool) {
        self.supportFontStyle = supportFontStyle
    }

    /// 处理 TextView 复制粘贴表情
    /// NOTE: 此方法修改 BaseSZTextView 字段， 有可能与其他设置相互影响
    public func register(textView: UITextView) {
        guard let textView = textView as? LarkEditTextView else { return }
        let handler = CustomSubInteractionHandler()
        handler.supportPasteType = .emoji
        /// emoji的检测规则
        let customHanderEntity = CustomHanderEntity { str in
            return EmotionTransformer.regularResult(str).map { $0.range }
        } handerBlock: { subStr, defaultTypingAttributes in
            return EmotionTransformer.replaceStrToEmojiAtt(subStr, attributes: defaultTypingAttributes, emojiKey: nil)
        }
        let defaultTypingAttributes = textView.defaultTypingAttributes
        handler.handerPasteTextType = .emoji(customHanderEntity)
        // 输入框处理拷贝回调
        handler.copyHandler = { [weak self] (textView) in
            guard let self = self else {
                return false
            }
            let selectedRange = textView.selectedRange
            if selectedRange.length > 0, let attributedText = textView.attributedText {
                let subAttributedText = attributedText.attributedSubstring(from: selectedRange)
                // 如果包含代码块，则交由CodeInputHandler处理
                if !self.pasteboardRedesignFg,
                    CodeInputHandler.editTextViewRegisterCode(textView: textView),
                   CodeInputHandler.attributedTextContainsCode(attributedText: subAttributedText) {
                    return false
                }
                let range = NSRange(location: 0, length: subAttributedText.length)
                var hasEmojiKey = false
                subAttributedText.enumerateAttribute(EmotionTransformer.EmojiAttributedKey, in: range, options: [], using: { (value, _, stop) in
                    if value != nil {
                        hasEmojiKey = true
                        stop.pointee = true
                    }
                })
                if self.pasteboardRedesignFg { return hasEmojiKey }
                if hasEmojiKey {
                    DispatchQueue.main.async {
                        let pasteString = EmotionTransformer.retransformContentToString(subAttributedText)
                        SCPasteboard.generalPasteboard().string = pasteString.string
                        // 向剪切板里面添加字体相关信息
                        self.addFontStyleInfoWith(attributedText: pasteString)
                        // 向剪切板里面添加emojKey相关信息
                        self.addEmojiKeyInfoWith(attributedText: pasteString)
                    }
                }
            }
            return false
        }
        // 输入框处理黏贴回调
        handler.pasteHandler = { [weak self] (textView) in
            guard let self = self else {
                return false
            }
            // 如果包含代码块，则交由CodeInputHandler处理
            if CodeInputHandler.editTextViewRegisterCode(textView: textView), CodeInputHandler.pasteboardContainsCode() {
                return false
            }
            let selectedRange = textView.selectedRange
            var needTransform = false
            if let string = SCPasteboard.generalPasteboard().string {
                let res = EmotionTransformer.regularResult(string)
                for rst in res {
                    let subStr = (string as NSString).substring(with: rst.range)
                    if EmotionTransformer.hasNeedTransformEmoji(subStr) {
                        // 如果有表情文字需要转换，break，执行转换方法
                        needTransform = true
                        break
                    }
                }
                if needTransform {
                    // 这个Block更新富文本里面的emoji信息：[笑脸] -> 😁
                    let updateAttributedTextBlock: ((NSAttributedString?, [NSRange: String]?) -> Void) = { [weak self] (text, emojiKeyMap) in
                        guard self != nil else {
                            return
                        }
                        // 这里与产品沟通 粘贴的文字不携带样式，使用原有样式
                        let result: NSAttributedString
                        if let text = text, text.string == string {
                            result = EmotionTransformer.transformPasteAttributedStringToRichText(text, attributes: defaultTypingAttributes, matchResult: res, emojiKeyMap: emojiKeyMap)
                        } else {
                            result = EmotionTransformer.transformPastestringToRichText(string, attributes: defaultTypingAttributes, matchResult: res, emojiKeyMap: emojiKeyMap)
                        }
                        let attributedText = NSMutableAttributedString(attributedString: textView.attributedText ?? NSAttributedString())
                        if selectedRange.length > 0 {
                            attributedText.replaceCharacters(in: selectedRange, with: result)
                        } else {
                            attributedText.insert(result, at: selectedRange.location)
                        }
                        textView.attributedText = attributedText
                    }
                    // 这个Block是从剪切板取出emojiKeyMap相关信息，注意从剪切板load数据是异步操作
                    let getEmojiKeyMapFromPasteboardBlock: ((NSAttributedString?) -> Void) = { [weak self] (text) in
                        guard self != nil else {
                            return
                        }
                        let itemProviders = SCPasteboard.generalPasteboard().itemProviders?.filter { itemProvider in
                            itemProvider.canLoadObject(ofClass: EmojiItemProvider.self)
                        }
                        if let provider = itemProviders?.last {
                            provider.loadObject(ofClass: EmojiItemProvider.self) { obj, error in
                                DispatchQueue.main.async {
                                    guard error == nil, let emojiItem = obj as? EmojiItemProvider else {
                                        updateAttributedTextBlock(text, nil)
                                        return
                                    }
                                    let emojiKeyMap = emojiItem.emojiKeyMapping()
                                    updateAttributedTextBlock(text, emojiKeyMap)
                                }
                            }
                        } else {
                            updateAttributedTextBlock(text, nil)
                        }
                    }
                    // 从剪切板取出字体相关信息，注意从剪切板load数据是异步操作
                    let itemProviders = SCPasteboard.generalPasteboard().itemProviders?.filter { itemProvider in
                        itemProvider.canLoadObject(ofClass: FontStyleItemProvider.self)
                    }
                    if self.supportFontStyle, let provider = itemProviders?.last {
                        provider.loadObject(ofClass: FontStyleItemProvider.self) { obj, error in
                            DispatchQueue.main.async {
                                guard error == nil, let fontStyleItem = obj as? FontStyleItemProvider else {
                                    getEmojiKeyMapFromPasteboardBlock(nil)
                                    return
                                }
                                let text = fontStyleItem.attributeStringWithAttributes(defaultTypingAttributes)
                                getEmojiKeyMapFromPasteboardBlock(text)
                            }
                        }
                    } else {
                        getEmojiKeyMapFromPasteboardBlock(nil)
                    }
                    return true
                }
            }
            return false
        }
        // 输入框处理剪切回调
        handler.cutHandler = { [weak self] (textView) in
            guard let self = self else {
                return false
            }
            let selectedRange = textView.selectedRange
            if selectedRange.length > 0, let attributedText = textView.attributedText.mutableCopy() as? NSMutableAttributedString {
                let subAttributedText = attributedText.attributedSubstring(from: selectedRange)
                // 如果包含代码块，则交由CodeInputHandler处理
                if !self.pasteboardRedesignFg, CodeInputHandler.editTextViewRegisterCode(textView: textView), CodeInputHandler.attributedTextContainsCode(attributedText: subAttributedText) {
                    return false
                }
                let range = NSRange(location: 0, length: subAttributedText.length)
                var hasEmojiKey = false
                subAttributedText.enumerateAttribute(EmotionTransformer.EmojiAttributedKey, in: range, options: [], using: { (value, _, stop) in
                    if value != nil {
                        hasEmojiKey = true
                        stop.pointee = true
                    }
                })
                if self.pasteboardRedesignFg { return hasEmojiKey }
                if hasEmojiKey {
                    DispatchQueue.main.async {
                        let pasteString = EmotionTransformer.retransformContentToString(subAttributedText)
                        SCPasteboard.generalPasteboard().string = pasteString.string
                        // 向剪切板里面添加字体相关信息
                        self.addFontStyleInfoWith(attributedText: pasteString)
                        // 向剪切板里面添加emojKey相关信息
                        self.addEmojiKeyInfoWith(attributedText: pasteString)
                    }
                }
            }
            return false
        }

        handler.pasteboardStringHandler = { attr in
            return EmotionTransformer.retransformContentToString(attr)
        }
        textView.interactionHandler.registerSubInteractionHandler(handler: handler)
    }

    func addFontStyleInfoWith(attributedText: NSAttributedString) {
        if !self.supportFontStyle {
            return
        }
        let style = FontStyleItemProvider.styleForAttributedString(attributedText)
        if !style.isEmpty, let json = FontStyleItemProvider.JSONStringWithStyle(style, content: attributedText.string) {
            SCPasteboard.generalPasteboard().addItems([[FontStyleItemProvider.typeIdentifier: json]])
        }
    }

    func addEmojiKeyInfoWith(attributedText: NSAttributedString) {
        let emoji = EmojiItemProvider.emojiKeyForAttributedString(attributedText)
        if !emoji.isEmpty, let json = EmojiItemProvider.JSONStringWithEmoji(emoji, content: attributedText.string) {
            SCPasteboard.generalPasteboard().addItems([[EmojiItemProvider.emojiIdentifier: json]])
        }
    }
}
