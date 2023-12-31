//
//  MinutesCommentsContentViewModel.swift
//  Minutes
//
//  Created by yangyao on 2021/1/31.
//

import Foundation
import ByteWebImage
import LarkEmotion
import UIKit
import YYText

extension MinutesCommentsContentViewModel {
    static func parseEmotion(_ text: String, foregroundColor: UIColor, font: UIFont) -> NSMutableAttributedString {
        // 匹配[]之间为英文的整个内容
        let pattern = "(\\[)[+0-9a-zA-Z]*?(\\])"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return NSMutableAttributedString(string: "", attributes: [.foregroundColor: foregroundColor])
        }
        let string = text
        let matchs = regex.matches(in: string, options: .withoutAnchoringBounds, range: NSRange(location: 0, length: string.count))
        let result = NSMutableAttributedString(string: "", attributes: [.foregroundColor: foregroundColor])
        var stringIndex: Int = 0
        _ = matchs.map { (match) in
            let range = match.range(at: 0)
            if let stringRange = Range(match.range(at: 0), in: string) {
                // 把匹配的[xxx]之前的内容加入results
                if range.lowerBound > stringIndex {
                    let startIndex = string.index(string.startIndex, offsetBy: stringIndex)
                    let endIndex = string.index(string.startIndex, offsetBy: range.lowerBound)
                    result.append(NSAttributedString(string: String(string[startIndex..<endIndex]), attributes: [.foregroundColor: foregroundColor]))
                }
                let startIndex = string.index(string.startIndex, offsetBy: range.lowerBound + 1)
                let endIndex = string.index(string.startIndex, offsetBy: range.upperBound - 1)
                let emojiKey = String(string[startIndex..<endIndex])

                // 判断是否是一个合法的emoji key，如果不是则显示原内容
                if let icon = EmotionResouce.shared.imageBy(key: emojiKey) {
                    // emoji之间距离要调整成2
                    // Spacing between emojis needs to be 2pt.
                    let fontSize = font.pointSize
                    if let attrStr = NSMutableAttributedString.yy_attachmentString(withEmojiImage: icon, fontSize: fontSize) {
                        result.append(attrStr)
                    } else {
                        result.append(NSAttributedString(string: String(string[stringRange]), attributes: [.foregroundColor: foregroundColor]))
                    }
                } else {
                    result.append(NSAttributedString(string: String(string[stringRange]), attributes: [.foregroundColor: foregroundColor]))
                }
                stringIndex = range.upperBound
            }
        }
        // 把最后一个[xxx]后面的部分加入results
        if stringIndex < string.count {
            let startIndex = string.index(string.startIndex, offsetBy: stringIndex)
            let endIndex = string.index(string.startIndex, offsetBy: string.count)
            result.append(NSAttributedString(string: String(string[startIndex..<endIndex]), attributes: [.foregroundColor: foregroundColor]))
        }

        // 去除空格
        let trimmedResult = trim(result, set: CharacterSet.whitespacesAndNewlines)

        return NSMutableAttributedString(attributedString: trimmedResult)
    }

    private static func trim(_ attributedString: NSAttributedString, set: CharacterSet) -> NSAttributedString {
        let invertedSet = set.inverted
        let modifyAttributeText = NSMutableAttributedString(attributedString: attributedString)
        var range: NSRange = NSRange(location: 0, length: 0)
        let location = range.length > 0 ? range.location : 0
        range.length = 0
        range = (attributedString.string as NSString).rangeOfCharacter(from: invertedSet, options: .backwards)
        let length = (range.length > 0 ? NSMaxRange(range) : modifyAttributeText.string.count) - location
        let newText = modifyAttributeText.attributedSubstring(from: NSRange(location: location, length: length))
        return newText
    }
}
