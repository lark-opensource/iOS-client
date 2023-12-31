//
//  KeyboardViewInputTool.swift
//  LarkBaseKeyboard
//
//  Created by liluobin on 2023/4/6.
//

import UIKit
import EditTextView

public class KeyboardViewInputTool {

    /// 除去LarkEditTextView的字体样式
    public static func baseTypingAttributesFor(inputTextView: LarkEditTextView) -> [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [:]
        /// 有特殊样式需要去除一下
        if let defaultFont = inputTextView.defaultTypingAttributes[.font] as? UIFont, (defaultFont.isBold || defaultFont.isItalic) {
            attributes[.font] = defaultFont.withoutTraits(.traitBold, .traitItalic)
        } else {
            attributes[.font] = inputTextView.defaultTypingAttributes[.font]
        }
        attributes[.foregroundColor] = inputTextView.defaultTypingAttributes[.foregroundColor]
        attributes[.paragraphStyle] = inputTextView.defaultTypingAttributes[.paragraphStyle]
        return attributes
    }

    public static func insertEmojiForTextView(_ inputTextView: LarkEditTextView,
                                             inputProtocolSet: TextViewInputProtocolSet?,
                                             emojiKey: String) {
        let emoji = "[\(emojiKey)]"
        let selectedRange = inputTextView.selectedRange
        if inputProtocolSet?.textView(inputTextView, shouldChangeTextIn: selectedRange, replacementText: emoji) != false {
            let emojiStr = EmotionTransformer.transformContentToString(emoji,
                                                                       attributes: KeyboardViewInputTool.baseTypingAttributesFor(inputTextView: inputTextView))
            inputTextView.insert(emojiStr, useDefaultAttributes: false)
        }
    }

    public static func insertAtForTextView(_ inputTextView: LarkEditTextView,
                                           userName: String,
                                           actualName: String,
                                           userId: String,
                                           isOuter: Bool) {
        if !userId.isEmpty {
            let info = AtChatterInfo(id: userId, name: userName, isOuter: isOuter, actualName: actualName)
            let attributes = KeyboardViewInputTool.baseTypingAttributesFor(inputTextView: inputTextView)
            let atString = AtTransformer.transformContentToString(info,
                                                                  style: [:],
                                                                  attributes: attributes)
            let mutableAtString = NSMutableAttributedString(attributedString: atString)
            mutableAtString.append(NSMutableAttributedString(string: " ", attributes: attributes))
            inputTextView.insert(mutableAtString, useDefaultAttributes: false)
        } else {
            inputTextView.insertText(userName)
        }
        inputTextView.becomeFirstResponder()
    }
}
