//
//  ChatParseEmojiUtility.swift
//  ByteView
//
//  Created by yangfukai on 2021/3/26.
//

import Foundation
import RichLabel

extension EmotionDependency {
    func parseEmotion(_ attributedString: NSMutableAttributedString) -> NSMutableAttributedString {
        // 匹配[]之间为英文的整个内容
        let pattern = "(\\[)[+0-9a-zA-Z_!]*?(\\])"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return NSMutableAttributedString(string: "")
        }
        let string = attributedString.string
        let matchs = regex.matches(in: string, options: .withoutAnchoringBounds, range: NSRange(location: 0, length: string.count))
        let result = NSMutableAttributedString(string: "")
        var stringIndex: Int = 0
        _ = matchs.map { (match) in
            let range = match.range(at: 0)
            if let stringRange = Range(match.range(at: 0), in: string) {
                // 把匹配的[xxx]之前的内容加入results
                if range.lowerBound > stringIndex {
                    let startIndex = string.index(string.startIndex, offsetBy: stringIndex)
                    let endIndex = string.index(string.startIndex, offsetBy: range.lowerBound)
                    result.append(NSAttributedString(string: String(string[startIndex..<endIndex])))
                }
                let startIndex = string.index(string.startIndex, offsetBy: range.lowerBound + 1)
                let endIndex = string.index(string.startIndex, offsetBy: range.upperBound - 1)
                let emojiKey = String(string[startIndex..<endIndex])

                // 判断是否是一个合法的emoji key，如果不是则显示原内容
                if let icon = emojiIcon(with: emojiKey) {
                    // emoji之间距离要调整成2
                    // Spacing between emojis needs to be 2pt.
                    let emoji = LKEmoji(icon: icon, font: UIFont.systemFont(ofSize: 16), spacing: 1)
                    let attrStr = NSMutableAttributedString(
                        string: LKLabelAttachmentPlaceHolderStr,
                        attributes: [
                            LKEmojiAttributeName: emoji,
                            .kern: 20
                        ]
                    )
                    result.append(attrStr)
                } else {
                    result.append(NSAttributedString(string: String(string[stringRange])))
                }
                stringIndex = range.upperBound
            }
        }
        // 把最后一个[xxx]后面的部分加入results
        if stringIndex < string.count {
            let startIndex = string.index(string.startIndex, offsetBy: stringIndex)
            let endIndex = string.index(string.startIndex, offsetBy: string.count)
            result.append(NSAttributedString(string: String(string[startIndex..<endIndex])))
        }
        // 去除空格
        let trimmedResult = trim(result, set: CharacterSet.whitespacesAndNewlines)
        return NSMutableAttributedString(attributedString: trimmedResult)
    }

    private func emojiIcon(with key: String) -> UIImage? {
        if let icon = self.imageByKey(key) {
            // 直播发过来的新版表情，格式与主站最新表情一致，直接根据 key 取
            return icon
        } else if let icon = self.imageByKey(key.uppercased()) {
            // 兼容旧版直播发过来的表情，主站全大写的表情在旧版直播中是驼峰式，所以需要把 key 转换成大写
            return icon
        }
        return nil
    }

    private func trim(_ attributedString: NSAttributedString, set: CharacterSet) -> NSAttributedString {
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
