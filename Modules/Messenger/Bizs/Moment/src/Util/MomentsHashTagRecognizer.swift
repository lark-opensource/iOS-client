//
//  MomentsHashTagRecognizer.swift
//  Moment
//
//  Created by liluobin on 2021/6/29.
//

import Foundation
import UIKit
import EditTextView
import LarkCore
import LarkRichTextCore
import LarkBaseKeyboard
/**
 弹出hashtag的时机
 1 输入#号
 2 在hashTag中编辑

 隐藏 hashTag的时机
 1 超出长度
 2 点击消息后
 3 光标移开之后弹出
 */
final class MomentsHashTagRecognizer {
    private let hashTagMaxCount: Int = 51 //#加上50字一共51
    private let httpPrefix = "http://"
    private let httpsPrefix = "https://"
    private let hashTagPrefix = "#"
    private let showHashTagList: ((String?) -> Void)?
    private var hashTagRanges: [NSRange] = []
    private var urlRanges: [NSRange] = []
    private var textLength: Int = 0
    private let ignoreAttributedKeys: [NSAttributedString.Key]

    init(ignoreAttributedKeys: [NSAttributedString.Key], showHashTagList: ((String?) -> Void)?) {
        self.showHashTagList = showHashTagList
        self.ignoreAttributedKeys = ignoreAttributedKeys
    }

    func onTextDidChangeFor(textView: LarkEditTextView?) {
        guard let textView = textView,
              textView.markedTextRange == nil,
              let attributeText = removeHashTagAttributeFor(textView: textView) else {
            return
        }
        self.urlRanges = []
        let selectedRange = textView.selectedRange
        let ranges = hashTagListForAttributedText(attributeText)
        addHashTagAttributesFor(attributeText: attributeText, ranges: ranges)
        textView.attributedText = attributeText
        textView.selectedRange = selectedRange
        self.hashTagRanges = ranges
        var currentEidtRange: NSRange?
        ranges.forEach { [weak self] (range) in
            guard let self = self else { return }
            if self.isContain(hashTagRange: range, selectedRange: textView.selectedRange) {
                currentEidtRange = range
            }
        }
        if let range = currentEidtRange {
            /// show
            let input = (attributeText.string as NSString).substring(with: range)
            showHashTagList?(input)
        } else {
            /// 当前光标在最前面 移除hashTag
            if textView.selectedRange.location == 0 {
                showHashTagList?(nil)
                return
            }
            /// 不是#号的话 移除hashTag列表
            if (textView.attributedText.string as NSString).substring(with: NSRange(location: textView.selectedRange.location - 1, length: 1)) != "#" {
                showHashTagList?(nil)
            /// 是#号 需要更新最近列表
            } else {
                /// 如果输入的是#号 在URL的范围内 不需要弹出
                if urlRanges.first(where: { $0.contains(textView.selectedRange.location - 1) }) == nil {
                    showHashTagList?("")
                } else {
                    showHashTagList?(nil)
                }
            }
        }
    }

    func hashTagListForAttributedText(_ attributedText: NSMutableAttributedString) -> [NSRange] {
        let text = attributedText.string as NSString
        assert(attributedText.length == text.length, "这里出现异常了")
        self.textLength = text.length
        var hashTags: [NSRange] = []
        var idx: Int = 0
        let invalidRange = filterInvalidRanges(attributedText)
        while skipUrlFrom(str: text, startIdx: &idx) < text.length {
            if text.substring(with: NSRange(location: idx, length: 1)) != hashTagPrefix {
                idx += 1
                continue
            }
            /// 如果其他类型的包含#号
            if let range = invalidRange.first(where: { $0.contains(idx) }) {
                idx = range.location + range.length
                continue
            }
            let start = idx
            idx += 1
            while idx < text.length,
                  text.substring(with: NSRange(location: idx, length: 1)).isLetterOrNumber(),
                  idx < start + hashTagMaxCount,
                  !hasHttpPrefixFor(text: text, fromIdx: idx) {
                idx += 1
            }
            if idx - start > 1 {
                hashTags.append(NSRange(location: start, length: idx - start))
            }
        }
        return Array(hashTags.prefix(100))
    }

    func removeHashTagAttributeFor(textView: LarkEditTextView) -> NSMutableAttributedString? {
        guard let attributedText = textView.attributedText else {
            return nil
        }
        let targetStr = NSMutableAttributedString(attributedString: attributedText)
        attributedText.enumerateAttribute(HashTagTransformer.HashTagAttributedKey, in: NSRange(location: 0, length: attributedText.length), options: []) { (value, range, _) in
            if value != nil {
                targetStr.removeAttribute(HashTagTransformer.HashTagAttributedKey, range: range)
                targetStr.addAttributes(textView.defaultTypingAttributes, range: range)
            }
        }
        return targetStr
    }

    func addHashTagAttributesFor(attributeText: NSMutableAttributedString, ranges: [NSRange]) {
        ranges.forEach { (range) in
            attributeText.addAttributes([HashTagTransformer.HashTagAttributedKey: "",
                                .foregroundColor: UIColor.ud.textLinkNormal],
                               range: range)
        }
    }

    func skipUrlFrom(str: NSString, startIdx: inout Int) -> Int {
        guard startIdx < str.length  else {
            return startIdx
        }
        /// 如果开头的是https 或者 http 需要开始便利
        let urlRangeStart = startIdx
        let subStr = str.substring(from: startIdx)
        if subStr.hasPrefix(httpPrefix) {
            startIdx += httpPrefix.count
        } else if subStr.hasPrefix(httpsPrefix) {
            startIdx += httpsPrefix.count
        } else {
            return startIdx
        }
        while startIdx < str.length && str.substring(with: NSRange(location: startIdx, length: 1)).isUrlChar() {
            startIdx += 1
        }
        let urlRangeEnd = startIdx
        if urlRangeEnd > urlRangeStart {
            urlRanges.append(NSRange(location: urlRangeStart, length: urlRangeEnd - urlRangeStart))
        }
        return startIdx
    }

    func hasHttpPrefixFor(text: NSString, fromIdx: Int) -> Bool {
        let subStr = text.substring(from: fromIdx)
        return subStr.hasPrefix(httpsPrefix) || subStr.hasPrefix(httpPrefix)
    }

    func editingHashTagForTextView(_ textView: LarkEditTextView) -> NSRange? {
        let selectedRange = textView.selectedRange
        var targetRange: NSRange?
        hashTagRanges.forEach { range in
            if isContain(hashTagRange: range, selectedRange: selectedRange) {
                targetRange = range
            }
        }
        if targetRange == nil, (textView.attributedText.string as NSString).substring(with: NSRange(location: textView.selectedRange.location - 1, length: 1)) == "#" {
            targetRange = NSRange(location: textView.selectedRange.location - 1, length: 1)
        }
        return targetRange
    }

    func onChangeSelectionForTextView(_ textView: LarkEditTextView) {
        guard (textView.attributedText.string as NSString).length == textLength else {
            return
        }
        let filterResult = hashTagRanges.filter { (range) -> Bool in
           return self.isContain(hashTagRange: range, selectedRange: textView.selectedRange)
        }
        if filterResult.isEmpty {
            self.showHashTagList?(nil)
        }
    }

    func isContain(hashTagRange: NSRange, selectedRange: NSRange) -> Bool {
        if selectedRange.length != 0 {
            return false
        }
        /// 判断是否光标在hashtag的范围内，需要后移以1位 eg: |#11111111 (在hashTag范围) 或者 #22222|（在hashTag范围）
        let actualRange = NSRange(location: hashTagRange.location + 1, length: hashTagRange.length)
        /// 这里加1是需要保证在#号后面
        return actualRange.contains(selectedRange.location)
    }
    func hasHashTag(_ content: String, textView: LarkEditTextView?) -> Bool {
        guard let textView = textView, !content.isEmpty else {
            return false
        }
        let text = textView.attributedText.string as NSString
        let item = hashTagRanges.first { range in
           return text.substring(with: range) == content
        }
        return item != nil
    }

    func isBeginEditingHashTagFor(textView: LarkEditTextView) -> Bool {
        let text = textView.attributedText.string as NSString
        let location = textView.selectedRange.location
        if location - 1 < text.length, text.substring(with: NSRange(location: location - 1, length: 1)) == hashTagPrefix {
            return true
        }
        return false
    }

    func filterInvalidRanges(_ attr: NSAttributedString) -> [NSRange] {
        if ignoreAttributedKeys.isEmpty {
            return []
        }
        var ranges: [NSRange] = []
        let text = attr.string as NSString
        attr.enumerateAttributes(in: NSRange(location: 0, length: attr.length), options: []) { (attributes, range, _) in
            for key in ignoreAttributedKeys where attributes[key] != nil {
                let subStr = text.substring(with: range) as NSString
                if subStr.contains(hashTagPrefix) {
                    ranges.append(range)
                }
                break
            }
        }
        return ranges
    }

    func getSelectedRangeRect(_ textView: UITextView) -> CGRect? {
        guard textView.selectedRange.location != (textView.attributedText.string as NSString).length else {
            return nil
        }
        let beginning = textView.beginningOfDocument
        guard let start = textView.position(from: beginning, offset: textView.selectedRange.location) else {
            return nil
        }
        guard let end = textView.position(from: start, offset: 1) else {
            return nil
        }
        guard let textRange = textView.textRange(from: start, to: end) else {
            return nil
        }
        return textView.firstRect(for: textRange)
    }
}

extension String {
    func isUrlChar() -> Bool {
        let array = Array(self)
        if array.count != 1 {
            return false
        }
        let char = array[0]
        if char >= "A" && char <= "Z" {
            return true
        }

        if char >= "a" && char <= "z" {
            return true
        }

        if "0123456789".contains(char) {
            return true
        }
        if ";:@&=+$,/?-_.~!*'()[]{}|\\^`#%".contains(char) {
            return true
        }
        return false
    }

    func isLetterOrNumber() -> Bool {
        let notExpectedArr = self.filter { (character) -> Bool in
            return !character.isNumber && !character.isLetter
        }
        return notExpectedArr.isEmpty
    }
}
