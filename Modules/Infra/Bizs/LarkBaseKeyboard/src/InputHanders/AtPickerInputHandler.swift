//
//  AtPickerInputHandler.swift
//  Lark
//
//  Created by lichen on 2017/11/8.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkUIKit
import EditTextView
import RustPB

public enum InputKeyboardAtItem {
    case chatter(_ item: InputKeyboardAtChatter)
    case doc(_ url: String, _ title: String, _ docType: RustPB.Basic_V1_Doc.TypeEnum)
    case wiki(_ url: String, _ title: String, _ docType: RustPB.Basic_V1_Doc.TypeEnum)
}

public struct InputKeyboardAtChatter {
    public var id: String
    public var name: String
    public var actualName: String
    public var isOuter: Bool

    public init(id: String, name: String, actualName: String, isOuter: Bool) {
        self.id = id
        self.name = name
        self.actualName = actualName
        self.isOuter = isOuter
    }
}

/// 响应 TextView 中 @ 人
/// NOTE: 响应 @ 之后，会调用 block, 同时 @ 仍然会被输入到 TextView 中
public final class AtPickerInputHandler: TextViewInputProtocol {

    public let showAtPickBlock: (_ textView: UITextView, _ range: NSRange, _ text: String) -> Void

    public init(showAtPickBlock: @escaping (_ textView: UITextView, _ range: NSRange, _ text: String) -> Void) {
        self.showAtPickBlock = showAtPickBlock
    }

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "@" {

            let isDelete = !NSEqualRanges(range, textView.selectedRange) && range.length > 0
            let isAtUser = AtPickerInputHandler.isAt(text: textView.text ?? "", selectedRange: textView.selectedRange, isDelete: isDelete)

            if isAtUser {
                DispatchQueue.main.async {
                    self.showAtPickBlock(textView, range, text)
                }
            }
        }
        return true
    }

    private static func isAt(text: String, selectedRange: NSRange, isDelete: Bool) -> Bool {

        // 当 text 为空的时候，响应 @
        if text.isEmpty { return true }
        let nsCurrentText = text as NSString

        // 当为删除操作时候不响应 @
        if isDelete { return false }

        // 当 selectedRange length 长度不为 0 的时候不响应 @
        if selectedRange.length > 0 { return false }

        let location = selectedRange.location
        let frontContent = nsCurrentText.substring(to: location)

        // 当光标为第一位的时候，响应 @
        if frontContent.isEmpty { return true }

        // 当光标前一位为空格的时候，响应 @
        let lastChar = frontContent.substring(from: frontContent.count - 1)
        if lastChar == " " { return true }

        // 当光标前不为数字或者字母的时候，响应 @
        do {
            let regexp = try NSRegularExpression(pattern: "[\\da-zA-Z]", options: [])
            let matches = regexp.matches(in: lastChar, options: [], range: NSRange(location: 0, length: 1))
            if matches.isEmpty { return true }
        } catch {}

        return false
    }
}

extension String {
    public func substring(from index: Int) -> String {
        if self.count > index {
            let startIndex = self.index(self.startIndex, offsetBy: index)
            let subString = self[startIndex..<self.endIndex]

            return String(subString)
        } else {
            return self
        }
    }

    public func substring(to index: Int) -> String {
        if self.count > index {
            let endIndex = self.index(self.startIndex, offsetBy: index)
            let subString = self[..<endIndex]
            return String(subString)
        } else {
            return self
        }
    }
}
