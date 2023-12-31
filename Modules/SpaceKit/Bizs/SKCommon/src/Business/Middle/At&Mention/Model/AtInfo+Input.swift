//
//  AtInfo+Input.swift
//  SpaceKit
//
//  Created by chenjiahao.gill on 2019/2/21.
//

import SKFoundation
import UniverseDesignColor
import SpaceInterface

extension AtInfo {
    public final class TextFormat {
        public static func defaultAttributes(fontSize: CGFloat = 16.0, textColor: UIColor? = UDColor.textTitle) -> [NSAttributedString.Key: Any] {
            self.defaultAttributes(font: UIFont.systemFont(ofSize: fontSize), textColor: textColor)
        }
        
        public static func defaultAttributes(font: UIFont, textColor: UIColor? = UDColor.textTitle) -> [NSAttributedString.Key: Any] {
            if let color = textColor {
                return [NSAttributedString.Key.font: font,
                        NSAttributedString.Key.foregroundColor: color]
            } else {
                return [NSAttributedString.Key.font: font]
            }
        }
    }

   public class func deleteAtInfoIfNeeded(_ textView: UITextView, _ range: NSRange) -> Bool {
        guard let attributedText = textView.attributedText else {
            return false
        }

        // 当前长度
        let totalRange = NSRange(location: 0, length: attributedText.length)

        // 获取当前光标位置
        let currentCursorLocation = range.location

        // 枚举 function 里面不可以直接返回 ... 所以加一个标记位
        var hasDelete = false

        var needDeleteRanges: [NSRange] = []

        // 枚举 At 判断是否需要删除 @ 内容
        attributedText.enumerateAttribute(AtInfo.attributedStringAtInfoKey, in: totalRange, options: .reverse) { (attrs, attrsRange, _) in
            if attrs != nil {
                let isInAtLocation = NSLocationInRange(currentCursorLocation, attrsRange)
                if isInAtLocation {
                    needDeleteRanges.append(attrsRange)
                    hasDelete = true
                }
            }
        }
        var deleteRange = range
        var begin = range.location
        var end = range.location + range.length
        if hasDelete,
           !needDeleteRanges.isEmpty,
           let first = needDeleteRanges.first,
           let last = needDeleteRanges.last {
            if first.location < begin {
                begin = first.location
            }
            if last.location + last.length > end {
                end = last.location + last.length
            }
            deleteRange = NSRange(location: begin, length: end - begin)
        }
        if deleteRange != range {
            let tempAttributedText = NSMutableAttributedString(attributedString: textView.attributedText)
            tempAttributedText.deleteCharacters(in: deleteRange)
            textView.attributedText = tempAttributedText
            // 控制光标
            textView.selectedRange = NSRange(location: deleteRange.location, length: 0)
            return true
        } else {
            return false
        }
    }

    /// remove @people attributedString from textView
    public class func removeAtString(from textView: UITextView) -> Bool {
        var deleteSpecial = false
        var isLastPhrase = false
        if let attributedString = textView.attributedText {
            attributedString.enumerateAttribute(AtInfo.attributedStringAtInfoKey, in: NSRange(location: 0, length: attributedString.length), options: .reverse) { (attrs, range, _) in
                let deleteRange = NSRange(location: textView.selectedRange.location - 1, length: 0)
                if !isLastPhrase && attrs != nil,
                    deleteRange.location >= range.location,
                    deleteRange.location < (range.location + range.length) {
                    let textAttStr = NSMutableAttributedString(attributedString: attributedString)
                    textAttStr.deleteCharacters(in: range)
                    textView.attributedText = textAttStr
                    isLastPhrase = true
                    textView.selectedRange = NSRange(location: range.location, length: 0)
                    deleteSpecial = true
                }
            }
        }
        return deleteSpecial
    }

    /// 插入 “@”，返回光标位置
    public class func insertAt(for textView: UITextView, attri: [NSAttributedString.Key: Any]) -> Int {
        let atString = NSAttributedString(string: "@", attributes: attri)
        let range = textView.selectedRange
        let textString = NSMutableAttributedString(attributedString: textView.attributedText)
        textString.replaceCharacters(in: range, with: atString)
        textView.attributedText = textString
        let newRange = NSRange(location: range.location + 1, length: 0)
        textView.selectedRange = newRange
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_100) {
            /// 滚动到指定区域
            textView.scrollRangeToVisible(newRange)
        }
        return textView.selectedRange.location
    }

    public class func removeEmojiLocation(with textView: UITextView, location: Int) -> Int {
        var loc = location
        if (textView.text as NSString).length >= location {
            loc = (textView.text as NSString).substring(to: location).count
        }
        return loc
    }
}
