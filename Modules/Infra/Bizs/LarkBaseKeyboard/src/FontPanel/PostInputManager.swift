//
//  PostInputManager.swift
//  LarkMessageCore
//
//  Created by liluobin on 2021/9/10.
//

import Foundation
import UIKit
import UniverseDesignFont
import EditTextView
import LarkRichTextCore

/// 提供一些公共方法
public final class PostInputManager {
    public static let lineSpace: CGFloat = 6
    weak var inputTextView: LarkEditTextView?
    public init(inputTextView: LarkEditTextView) {
        self.inputTextView = inputTextView
    }

    public static func getBaseDefaultTypingAttributesFor(_ attributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        var baseDefaultTypingAttributes: [NSAttributedString.Key: Any] = [:]
        baseDefaultTypingAttributes[.font] = (attributes[.font] as? UIFont)?.withoutTraits(.traitBold, .traitItalic)
        baseDefaultTypingAttributes[.foregroundColor] = attributes[.foregroundColor]
        baseDefaultTypingAttributes[.paragraphStyle] = attributes[.paragraphStyle]
        return baseDefaultTypingAttributes
    }

    public static func unsupportSelectedRangesForTextView(_ textView: BaseEditTextView) -> [NSRange] {
        var exceptRanges: [NSRange] = []
        let subAttrStr = textView.attributedText.attributedSubstring(from: textView.selectedRange)
        RichTextTransformKit.transformer.forEach { transformer in
            let ranges: [NSRange] = transformer.filterUnsupportStyleRangeFor(text: subAttrStr)
            exceptRanges.append(contentsOf: ranges.map({ range in
                return NSRange(location: textView.selectedRange.location + range.location, length: range.length)
            }))
        }
        return exceptRanges
    }

    public static func updateSelectedRangeIfNeedWithExceptRanges(_ exceptRanges: [NSRange], textView: BaseEditTextView) -> Bool {
        if exceptRanges.isEmpty {
            return false
        }
        let selectedRange = textView.selectedRange
        if exceptRanges.count == 2 {
            let leftRange = exceptRanges[0]
            let rightRange = exceptRanges[1]
            if leftRange.right == rightRange.location {
                textView.selectedRange = NSRange(location: selectedRange.right, length: 0)
            } else {
                textView.selectedRange = NSRange(location: leftRange.right, length: rightRange.location - leftRange.right)
            }
        } else if exceptRanges.count == 1 {
            if exceptRanges[0] == selectedRange {
                textView.selectedRange = NSRange(location: selectedRange.right, length: 0)
            } else {
                if exceptRanges[0].location == selectedRange.location {
                    let location = exceptRanges[0].right
                    textView.selectedRange = NSRange(location: location, length: selectedRange.right - exceptRanges[0].right)
                } else {
                    textView.selectedRange = NSRange(location: selectedRange.location, length: exceptRanges[0].location - selectedRange.location)
                }
            }
        } else {
            textView.selectedRange = NSRange(location: selectedRange.location + selectedRange.length, length: 0)
            assertionFailure("exceptRanges 检测出现错误")
        }
        return true
    }

    // MARK: - font调整
    public func recoveryToDefaultTypingAttributes() {
        updateDefaultTypingAttributesWithType(.bold, apply: false)
        updateDefaultTypingAttributesWithType(.italic, apply: false)
        updateDefaultTypingAttributesWithType(.underline, apply: false)
        updateDefaultTypingAttributesWithType(.strikethrough, apply: false)
    }

    public func addAtttibuteForRange(_ range: NSRange, type: FontActionType) -> NSAttributedString {
        guard let inputTextView = inputTextView else {
            return NSAttributedString(string: "")
        }
        guard range.length > 0 else {
            return inputTextView.attributedText
        }
        return addAttributeForText(NSMutableAttributedString(attributedString: inputTextView.attributedText), range: range, type: type)
    }

    public func removeAttributeForRange(_ range: NSRange, type: FontActionType) -> NSAttributedString {
        guard let inputTextView = inputTextView else {
            return NSAttributedString(string: "")
        }
        guard range.length > 0 else {
            return inputTextView.attributedText
        }
        return removeAttributeForText(NSMutableAttributedString(attributedString: inputTextView.attributedText),
                                      range: range,
                                      type: type)
    }

    // 根据fontbar的状态来更新当前默认编辑的属性
    public func updateDefaultTypingAttributesWithStatus(_ status: FontToolBarStatusItem) {
        self.updateDefaultTypingAttributesWithType(.bold, apply: status.isBold)
        self.updateDefaultTypingAttributesWithType(.italic, apply: status.isItalic)
        self.updateDefaultTypingAttributesWithType(.strikethrough, apply: status.isStrikethrough)
        self.updateDefaultTypingAttributesWithType(.underline, apply: status.isUnderline)
    }

    // convert defaultTypingAttributes to barStatus
    public func getInputViewFontStatus() -> FontToolBarStatusItem {
        guard let inputTextView = inputTextView else {
            return FontToolBarStatusItem()
        }
        var fontBarStatus = FontToolBarStatusItem()
        let attributes = inputTextView.defaultTypingAttributes
        fontBarStatus.isBold = attributes[FontStyleConfig.boldAttributedKey] != nil
        fontBarStatus.isItalic = attributes[FontStyleConfig.italicAttributedKey] != nil
        fontBarStatus.isStrikethrough = attributes[FontStyleConfig.strikethroughAttributedKey] != nil
        fontBarStatus.isUnderline = attributes[FontStyleConfig.underlineAttributedKey] != nil
        return fontBarStatus
    }

    func addAttributeForText(_ text: NSMutableAttributedString, range: NSRange, type: FontActionType) -> NSMutableAttributedString {
        guard let inputTextView = inputTextView else {
            return NSMutableAttributedString(string: "")
        }
        switch type {
        case .bold:
            let arr = NSAttributedString(attributedString: text)
            let attributes = inputTextView.defaultTypingAttributes
            let defaultFont = (attributes[.font] as? UIFont)?.withoutTraits(.traitBold, .traitItalic)
            arr.enumerateAttribute(.font, in: range, options: []) { value, subRange, _ in
                let fontTrait = getCurrentFontTrait(of: arr, in: subRange)
                let isBold = fontTrait.isBold
                let isItalic = fontTrait.isItalic
                if let _ = value as? UIFont, !isBold, let baseFont = defaultFont {
                    /// 这里使用baseFont处理 而不是使用 font，因为汉字的font的英文的font的不一样，加粗之后会出现字体变小的情况
                    if isItalic {
                        text.addAttributes([.font: baseFont.boldItalic], range: subRange)
                    } else {
                        if UDFontAppearance.isCustomFont {
                            text.addAttributes([.font: baseFont.medium], range: subRange)
                        } else {
                            text.addAttributes([.font: baseFont.withTraits(.traitBold)], range: subRange)
                        }
                    }
                }
            }
            text.addAttributes([FontStyleConfig.boldAttributedKey: FontStyleConfig.boldAttributedValue], range: range)
        case .italic:
            let arr = NSAttributedString(attributedString: text)
            let attributes = inputTextView.defaultTypingAttributes
            let defaultFont = (attributes[.font] as? UIFont)?.withoutTraits(.traitBold, .traitItalic)
            arr.enumerateAttribute(.font, in: range, options: []) { value, subRange, _ in
                let fontTrait = getCurrentFontTrait(of: arr, in: subRange)
                let isBold = fontTrait.isBold
                let isItalic = fontTrait.isItalic
                if let _ = value as? UIFont, !isItalic, let baseFont = defaultFont {
                    /// 这里使用baseFont处理 而不是使用 font，因为汉字的font的英文的font的不一样，斜体之后会出现字体变小的情况
                    if isBold {
                        text.addAttributes([.font: baseFont.boldItalic], range: subRange)
                    } else {
                        text.addAttributes([.font: baseFont.italic], range: subRange)
                    }
                }
            }
            text.addAttributes([FontStyleConfig.italicAttributedKey: FontStyleConfig.italicAttributedValue], range: range)
        case .underline:
            text.addAttributes([FontStyleConfig.underlineAttributedKey: FontStyleConfig.underlineAttributedValue], range: range)
            text.addAttributes([.underlineStyle: FontStyleConfig.underlineStyle], range: range)
            /// 有百科/纠错的场景，防止覆盖其他高优的场景
            text.enumerateAttribute(AIFontStyleConfig.smartCorrectAttribuedKey, in: range) { (value, attributeRange, _) in
                if value != nil {
                    text.addAttributes([.underlineStyle: AIFontStyleConfig.smartCorrectAttribuedValue], range: attributeRange)
                }
            }
            text.enumerateAttribute(AIFontStyleConfig.lingoHighlightAttributedKey, in: range) { (value, attributeRange, _) in
                if value != nil {
                    text.addAttributes([.underlineStyle: AIFontStyleConfig.lingoHighlightAttributedValue], range: attributeRange)
                }
            }
        case .strikethrough:
            text.addAttributes([.strikethroughStyle: FontStyleConfig.strikethroughStyle], range: range)
            text.addAttributes([FontStyleConfig.strikethroughAttributedKey: FontStyleConfig.strikethroughAttributedValue], range: range)
        case .goback:
            break
        }
        return text
    }

    func removeAttributeForText(_ text: NSMutableAttributedString, range: NSRange, type: FontActionType) -> NSMutableAttributedString {
        guard let inputTextView = inputTextView else {
            return NSMutableAttributedString(string: "")
        }
        switch type {
        case .bold:
            let arr = NSAttributedString(attributedString: text)
            let attributes = inputTextView.defaultTypingAttributes
            let defaultFont = (attributes[.font] as? UIFont)?.withoutTraits(.traitBold, .traitItalic)
            arr.enumerateAttribute(.font, in: range, options: []) { value, subRange, _ in
                let fontTrait = getCurrentFontTrait(of: arr, in: subRange)
                let isBold = fontTrait.isBold
                let isItalic = fontTrait.isItalic
                if let _ = value as? UIFont, isBold, let baseFont = defaultFont {
                    /// 这里使用baseFont处理 而不是使用 font，因为汉字的font的英文的font的不一样，加粗之后会出现字体变小的情况
                    if isItalic {
                        text.addAttributes([.font: baseFont.italic], range: subRange)
                    } else {
                        text.addAttributes([.font: baseFont], range: subRange)
                    }
                }
            }
            text.removeAttribute(FontStyleConfig.boldAttributedKey, range: range)
        case .italic:
            let arr = NSAttributedString(attributedString: text)
            let attributes = inputTextView.defaultTypingAttributes
            let defaultFont = (attributes[.font] as? UIFont)?.withoutTraits(.traitBold, .traitItalic)
            arr.enumerateAttribute(.font, in: range, options: []) { value, subRange, _ in
                let fontTrait = getCurrentFontTrait(of: arr, in: subRange)
                let isBold = fontTrait.isBold
                let isItalic = fontTrait.isItalic
                if let _ = value as? UIFont, isItalic, let baseFont = defaultFont {
                    if isBold {
                        if UDFontAppearance.isCustomFont {
                            text.addAttributes([.font: baseFont.medium], range: subRange)
                        } else {
                            text.addAttributes([.font: baseFont.withTraits(.traitBold)], range: subRange)
                        }
                    } else {
                        text.addAttributes([.font: baseFont], range: subRange)
                    }
                }
            }
            text.removeAttribute(FontStyleConfig.italicAttributedKey, range: range)
        case .underline:
            text.removeAttribute(FontStyleConfig.underlineAttributedKey, range: range)
            text.removeAttribute(.underlineStyle, range: range)
            text.enumerateAttribute(AIFontStyleConfig.smartCorrectAttribuedKey, in: range) { (value, attrRange, _) in
                if value != nil {
                    text.addAttributes([.underlineStyle: AIFontStyleConfig.smartCorrectAttribuedValue], range: attrRange)
                }
            }
            text.enumerateAttribute(AIFontStyleConfig.lingoHighlightAttributedKey, in: range) { (value, attrRange, _) in
                if value != nil {
                    text.addAttributes([.underlineStyle: AIFontStyleConfig.lingoHighlightAttributedValue], range: attrRange)
                }
            }
        case .strikethrough:
            text.removeAttribute(.strikethroughStyle, range: range)
            text.removeAttribute(FontStyleConfig.strikethroughAttributedKey, range: range)
        case .goback:
            break
        }
        return text
    }

    public func updateDefaultTypingAttributesWithType(_ type: FontActionType, apply: Bool) {
        guard let inputTextView = inputTextView else {
            return
        }
        var attributes = inputTextView.defaultTypingAttributes
        switch type {
        case .bold:
            if apply {
                attributes[.font] = (attributes[.font] as? UIFont)?.withTraits(.traitBold)
                attributes[FontStyleConfig.boldAttributedKey] = FontStyleConfig.boldAttributedValue
            } else {
                attributes[.font] = (attributes[.font] as? UIFont)?.withoutTraits(.traitBold)
                attributes.removeValue(forKey: FontStyleConfig.boldAttributedKey)
            }
        case .italic:
            if apply {
                attributes[.font] = (attributes[.font] as? UIFont)?.withTraits(.traitItalic)
                attributes[FontStyleConfig.italicAttributedKey] = FontStyleConfig.italicAttributedValue
            } else {
                attributes[.font] = (attributes[.font] as? UIFont)?.withoutTraits(.traitItalic)
                attributes.removeValue(forKey: FontStyleConfig.italicAttributedKey)
            }
        case .underline:
            if apply {
                attributes[.underlineStyle] = FontStyleConfig.underlineStyle
                attributes[FontStyleConfig.underlineAttributedKey] = FontStyleConfig.underlineAttributedValue
            } else {
                attributes.removeValue(forKey: .underlineStyle)
                attributes.removeValue(forKey: FontStyleConfig.underlineAttributedKey)
            }
        case .strikethrough:
            if apply {
                attributes[.strikethroughStyle] = FontStyleConfig.strikethroughStyle
                attributes[FontStyleConfig.strikethroughAttributedKey] = FontStyleConfig.strikethroughAttributedValue
            } else {
                attributes.removeValue(forKey: .strikethroughStyle)
                attributes.removeValue(forKey: FontStyleConfig.strikethroughAttributedKey)
            }
        case .goback:
            break
        }
        inputTextView.defaultTypingAttributes = attributes
    }

    public func updateDefaultTypingAttributesWidth(text: NSAttributedString) -> FontToolBarStatusItem {
        if text.length == 0 {
            recoveryToDefaultTypingAttributes()
            return FontToolBarStatusItem()
        } else {
            let attr = text.attributedSubstring(from: NSRange(location: 0, length: 1))
            var statusItem = FontToolBarStatusItem()
            recoveryToDefaultTypingAttributes()
            attr.enumerateAttributes(in: NSRange(location: 0, length: attr.length), options: []) { attributes, _, _ in
                if attributes[FontStyleConfig.underlineAttributedKey] != nil {
                    updateDefaultTypingAttributesWithType(.underline, apply: true)
                    statusItem.isUnderline = true
                }
                if attributes[FontStyleConfig.italicAttributedKey] != nil {
                    updateDefaultTypingAttributesWithType(.italic, apply: true)
                    statusItem.isItalic = true
                }
                if attributes[FontStyleConfig.boldAttributedKey] != nil {
                    updateDefaultTypingAttributesWithType(.bold, apply: true)
                    statusItem.isBold = true
                }
                if attributes[FontStyleConfig.strikethroughAttributedKey] != nil {
                    updateDefaultTypingAttributesWithType(.strikethrough, apply: true)
                    statusItem.isStrikethrough = true
                }
            }
            return statusItem
        }
    }

    public func addParagraphStyle() {
        guard let inputTextView = inputTextView else {
            return
        }
        var defaultTypingAttributes = inputTextView.defaultTypingAttributes
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = Self.lineSpace
        defaultTypingAttributes[.paragraphStyle] = paragraphStyle
        inputTextView.defaultTypingAttributes = defaultTypingAttributes
    }

    public func baseTypingAttributes() -> [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [:]
        /// 有特殊样式需要去除一下
        if let defaultFont = inputTextView?.defaultTypingAttributes[.font] as? UIFont, (defaultFont.isBold || defaultFont.isItalic) {
            attributes[.font] = defaultFont.withoutTraits(.traitBold, .traitItalic)
        } else {
            attributes[.font] = inputTextView?.defaultTypingAttributes[.font]
        }
        attributes[.foregroundColor] = inputTextView?.defaultTypingAttributes[.foregroundColor]
        attributes[.paragraphStyle] = inputTextView?.defaultTypingAttributes[.paragraphStyle]
        return attributes
    }

    private func getCurrentFontTrait(of arr: NSAttributedString, in range: NSRange) -> FontTrait {
        let attributes = arr.attributes(at: range.location, effectiveRange: nil)
        let isItalic = (attributes[FontStyleConfig.italicAttributedKey] as? String ?? "") == FontStyleConfig.italicAttributedValue
        let isBold = (attributes[FontStyleConfig.boldAttributedKey] as? String ?? "") == FontStyleConfig.boldAttributedValue
        return FontTrait(isBold: isBold, isItalic: isItalic)
    }
}

fileprivate extension NSRange {
    var right: Int {
        return self.location + self.length
    }
}

public extension LarkEditTextView {
    var baseDefaultTypingAttributes: [NSAttributedString.Key: Any] {
        return PostInputManager.getBaseDefaultTypingAttributesFor(defaultTypingAttributes)
    }
}

fileprivate struct FontTrait {
    var isBold: Bool
    var isItalic: Bool
}
