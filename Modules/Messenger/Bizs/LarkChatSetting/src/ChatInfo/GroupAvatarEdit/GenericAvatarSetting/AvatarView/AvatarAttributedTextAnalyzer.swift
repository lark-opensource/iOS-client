//
//  AvatarAttributedTextAnalyzer.swift
//  LarkChatSetting
//
//  Created by ByteDance on 2023/11/10.
//

import Foundation
import UIKit
import LarkExtensions
import EditTextView
import LarkEmotion
import LKCommonsLogging
import LarkBaseKeyboard

struct AttributeTextCutInfo {
    /// 实际字符索引信息
    let cutRange: Range<String.Index>?
    let maxRange: Range<String.Index>
    /// count 产品定义,  即可见字符的数量
    let cutCount: Int?
    let count: Int
}

final class AvatarAttributedTextAnalyzer {
    private let logger = Logger.log(AvatarAttributedTextAnalyzer.self, category: "LarkChatSetting.GroupAvatar.textAnalyzer")
    // 产品定义的最大字符数量
    static let maxCountOfCharacter = 14
    let textColorCallBack: (() -> UIColor)?

    var paragraphStyle: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 2
        // swiftlint:disable ban_linebreak_byChar
        style.lineBreakMode = .byCharWrapping
        // swiftlint:enable ban_linebreak_byChar
        style.alignment = .center
        return style
    }

    /// 标准字号对应的图片尺寸为120*120
    /// 图片渲染时，根据图片的大小等比例计算字号大小
    struct FontConfig {
        // 四个汉字字号大小
        var fourChineseFont: CGFloat
        // 第一行最小字号
        var sizeOfFirstLine: CGFloat
        // 第二行最小字号
        var sizeOfLastLine: CGFloat
        // 共1-2个字符
        var sizeOfFirstLineWithLessTwoChar: CGFloat
        // 共3-4个字符
        var sizeOfFirstLineWithLessFourChar: CGFloat
        // 共5-6个字符
        var sizeOfFirstLineWithLessSixChar: CGFloat
        // 共7-12个字符，第一行字号
        var sizeOfFirstLineWithLessTwelveChar: CGFloat
        // 共7-12个字符，第二行字号
        var sizeOfLastLineWithLessTwelveChar: CGFloat
        // 自主换行：第一行默认字号
        var NewLinesizeForFirst: CGFloat
        // 自主换行：第二行默认字号
        var NewLinesizeForLast: CGFloat
        // 自主换行：每行少于2个字符
        var newLineSizeWithLessTwoChar: CGFloat
        // 自主换行：每行少于4个字符
        var newLineSizeWithLessFourChar: CGFloat
        // 自主换行： 每行少于6个字符
        var newLineSizeWithLessSixChar: CGFloat
        init(scale: CGFloat) {
            // disable-lint: magic_number
            // 不同场景下需要展示的字号大小
            self.fourChineseFont = 34.0 * scale
            self.sizeOfFirstLine = 28.0 * scale
            self.sizeOfLastLine = 22.0 * scale
            self.sizeOfFirstLineWithLessTwoChar = 52.0 * scale
            self.sizeOfFirstLineWithLessFourChar = 42.0 * scale
            self.sizeOfFirstLineWithLessSixChar = 30.0 * scale
            self.sizeOfFirstLineWithLessTwelveChar = 28.0 * scale
            self.sizeOfLastLineWithLessTwelveChar = 28.0 * scale
            self.NewLinesizeForFirst = 28.0 * scale
            self.NewLinesizeForLast = 22.0 * scale
            self.newLineSizeWithLessTwoChar = 42.0 * scale
            self.newLineSizeWithLessFourChar = 34.0 * scale
            self.newLineSizeWithLessSixChar = 28.0 * scale
            // enable-lint: magic_number
        }
    }

    var fontConfig: FontConfig
    init(fontScale: CGFloat = 1.0,
         textColorCallBack: (() -> UIColor)?) {
        self.textColorCallBack = textColorCallBack
        self.fontConfig = FontConfig(scale: fontScale)
    }

    func attrbuteStrForText(_ attributedText: NSAttributedString?) -> NSAttributedString {
        guard let attributedText = attributedText, !attributedText.string.lf.trimCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return NSAttributedString(string: "")
        }
        let targetText = attributedText.lf.trimmedAttributedString(set: CharacterSet.whitespacesAndNewlines)
        /// 对四个汉字需要特化处理，展示方块
        if let attr = self.handleFourChineseCharacterTextIfNeed(attributedText: targetText) {
            return attr
        }
        /// 对四个表情需要特化处理，展示为方块
        if let attr = self.handleFourReactionIfNeed(attributedText: targetText) {
            return attr
        }
        return self.transformTextToAttributeStr(attributedText: targetText)
    }

    private func getColorAttributes() -> [NSAttributedString.Key: Any] {
        return [.foregroundColor: self.textColorCallBack?() ?? UIColor.ud.primaryOnPrimaryFill]
    }

    private func handleFourChineseCharacterTextIfNeed(attributedText: NSAttributedString) -> NSAttributedString? {
        var isAllChinese = false
        var chineseCount = 0
        // 记录第二个汉字的位置
        var cutRange: Range<String.Index>?
        let text = attributedText.string
        attributedText.string.enumerateSubstrings(in: text.startIndex..<text.endIndex, options: .byComposedCharacterSequences) { (subString, substringRange, _, stopPoint) in
            isAllChinese = subString?.first?.isChinese() ?? false
            if !isAllChinese {
                // 跳出循环
                stopPoint = true
                return
            }
            chineseCount += 2
            if chineseCount == 4 {
                cutRange = substringRange
            }
        }

        if isAllChinese,
           chineseCount == 8,
           let cutRange = cutRange {
            var attributes: [NSAttributedString.Key: Any] = self.getColorAttributes()
            attributes[.font] = UIFont.boldSystemFont(ofSize: fontConfig.fourChineseFont)
            attributes[.paragraphStyle] = paragraphStyle
            /// 校验索引
            let endIndex = text.index(after: cutRange.upperBound)
            guard text.indices.contains(endIndex) else {
                self.logger.error("[GroupAvatar]the index is wrong")
                return nil
            }
            let muAttr = NSMutableAttributedString()
            let prefixRange = NSRange(..<cutRange.upperBound, in: text)
            let suffixRange = NSRange(cutRange.upperBound..., in: text)
            muAttr.append(attributedText.attributedSubstring(from: prefixRange))
            muAttr.append(NSAttributedString(string: "\n"))
            muAttr.append(attributedText.attributedSubstring(from: suffixRange))
            muAttr.addAttributes(attributes, range: NSRange(location: 0, length: muAttr.length))
            return muAttr
        }
        return nil
    }

    private func handleFourReactionIfNeed(attributedText: NSAttributedString) -> NSAttributedString? {
        var isAllReaction = false
        var reactionCount = 0
        var cutRange: Range<String.Index>?
        let text = attributedText.string
        attributedText.string.enumerateSubstrings(in: text.startIndex..<text.endIndex, options: .byComposedCharacterSequences) { (subString, substringRange, _, stopPoint) in
            isAllReaction = subString?.first?.isReaction() ?? false
            if !isAllReaction {
                // 跳出循环
                stopPoint = true
                return
            }
            reactionCount += 2
            if reactionCount == 4 {
                cutRange = substringRange
            }
        }

        if isAllReaction,
           reactionCount == 8,
           let cutRange = cutRange {
            let fontSize = fontConfig.fourChineseFont
            /// 校验索引
            let endIndex = text.index(after: cutRange.upperBound)
            guard text.indices.contains(endIndex) else {
                self.logger.error("[GroupAvatar]the index is wrong")
                return nil
            }
            let muAttr = NSMutableAttributedString()
            let prefixRange = NSRange(..<cutRange.upperBound, in: text)
            let suffixRange = NSRange(cutRange.upperBound..., in: text)
            let prefixString = attributedText.attributedSubstring(from: prefixRange).adjustAttributedStringFormat(fontSize: fontSize)
            let suffixString = attributedText.attributedSubstring(from: suffixRange).adjustAttributedStringFormat(fontSize: fontSize)
            muAttr.append(prefixString)
            muAttr.append(NSAttributedString(string: "\n"))
            muAttr.append(suffixString)
            return muAttr
        }
        return nil
    }

    private func transformTextToAttributeStr(attributedText: NSAttributedString) -> NSAttributedString {
        // 如果有换行，计算第一行的信息
        let info = attributedText.firstNewLineInfo()
        let newlineCount = info.0
        let newlineIdx = info.1
        var targetStr: NSAttributedString = NSAttributedString(string: "")
        let countInfo = attributedText.avatarCountInfo(cutCount: 6)
        let fontInfo = self.getWithoutNewlineFontForCharCount(count: countInfo.count)
        /// 由于输入框的最多输入两列，所以中间只有一个换行，需要根据实际展示的规则调整换行的位置
        if newlineIdx != nil {
            targetStr = fixTextForNewline(attributedText, newlineCount: newlineCount)
        } else {
            if countInfo.count > 6 {
                if let cutRange = countInfo.cutRange {
                    let muAttr = NSMutableAttributedString()
                    let prefixRange = NSRange(..<cutRange.upperBound, in: attributedText.string)
                    let prefixSubstring = attributedText.attributedSubstring(from: prefixRange)
                    muAttr.append(prefixSubstring.adjustAttributedStringFormat(fontSize: fontInfo.0, attr: self.getColorAttributes()))
                    muAttr.append(NSAttributedString(string: "\n"))

                    let suffixRange = NSRange(cutRange.upperBound..., in: attributedText.string)
                    let suffixSubstring = attributedText.attributedSubstring(from: suffixRange)
                    muAttr.append(suffixSubstring.adjustAttributedStringFormat(fontSize: fontInfo.1, attr: self.getColorAttributes()))
                    targetStr = muAttr
                } else {
                    self.logger.error("[GroupAvatar] cutRange is nil")
                }
            } else {
                targetStr = attributedText.adjustAttributedStringFormat(fontSize: fontInfo.0, attr: self.getColorAttributes())
            }
        }
        let murAttr = NSMutableAttributedString(attributedString: targetStr)
        murAttr.addAttributes([.paragraphStyle: paragraphStyle], range: NSRange(location: 0, length: targetStr.length))
        return murAttr
    }

    private func fixTextForNewline(_ attributedText: NSAttributedString, newlineCount: Int) -> NSAttributedString {
        // 如果是复制粘贴，中间有多个换行符，第一个行和第二个行
        let strArr = attributedText.splitAttributedStringByNewline()
        var firstStr = strArr.first ?? NSAttributedString(string: "")
        var lastStr = strArr.count > 1 ? strArr[1] : NSAttributedString(string: "")
        /// 如果换行的位置正好 那就不需要调整 加上字体即可
        if newlineCount < 7 {
            // 第二行从头部截取前8个字符
            lastStr = lastStr.subStrToCount(8)
        } else {
            firstStr = firstStr.subStrToCount(6)
            // 第二行去除“\n”后 从第7个字符往后取所有字符
            let mutableAttributedText = NSMutableAttributedString(attributedString: attributedText)
            let range = NSRange(location: 0, length: mutableAttributedText.length)
            mutableAttributedText.mutableString.replaceOccurrences(of: "\n", with: "", options: [], range: range)
            lastStr = mutableAttributedText.subStrFromCount(6)
        }
        let fontInfo = self.getFontForNewLine(firstLineCount: firstStr.avatarCountInfo().count,
                                              lastLineCount: lastStr.avatarCountInfo().count)
        let muAttr = NSMutableAttributedString()

        muAttr.append(firstStr.adjustAttributedStringFormat(fontSize: fontInfo.0, attr: self.getColorAttributes()))
        muAttr.append(NSAttributedString(string: "\n"))
        muAttr.append(lastStr.adjustAttributedStringFormat(fontSize: fontInfo.1, attr: self.getColorAttributes()))
        return muAttr
    }

    // 用户自主换行，根据每行字符数，计算对应的字体大小
    private func getFontForNewLine(firstLineCount: Int, lastLineCount: Int) -> (CGFloat, CGFloat) {

        if firstLineCount <= 2, lastLineCount <= 2 {
            return (fontConfig.newLineSizeWithLessTwoChar, fontConfig.newLineSizeWithLessTwoChar)
        }

        if firstLineCount <= 4, lastLineCount <= 4 {
            return (fontConfig.newLineSizeWithLessFourChar, fontConfig.newLineSizeWithLessFourChar)
        }

        if firstLineCount <= 6, lastLineCount <= 6 {
            return (fontConfig.newLineSizeWithLessSixChar, fontConfig.newLineSizeWithLessSixChar)
        }

        if lastLineCount <= 6 {
            assertionFailure("lastLineCount can <= 6")
        }
        return (fontConfig.NewLinesizeForFirst, fontConfig.NewLinesizeForLast)
    }

    /// 获取当前字符数对应的字体大小
    private func getWithoutNewlineFontForCharCount(count: Int) -> (CGFloat, CGFloat) {
        // 第一行最小字号
        var sizeOfFirstLine = fontConfig.sizeOfFirstLine
        // 第二行最小字号
        var sizeOfLastLine = fontConfig.sizeOfLastLine
        // 产品定义规则，不同的字符数对应字号不同
        // disable-lint: magic_number
        switch count {
        case 1, 2:
            sizeOfFirstLine = fontConfig.sizeOfFirstLineWithLessTwoChar
        case 3, 4:
            sizeOfFirstLine = fontConfig.sizeOfFirstLineWithLessFourChar
        case 5, 6:
            sizeOfFirstLine = fontConfig.sizeOfFirstLineWithLessSixChar
        case 7...12:
            sizeOfFirstLine = fontConfig.sizeOfFirstLineWithLessTwelveChar
            sizeOfLastLine = fontConfig.sizeOfLastLineWithLessTwelveChar
        default:
            break
        }
        // enable-lint: magic_number
        // 字号加粗
        return (sizeOfFirstLine, sizeOfLastLine)
    }
}

extension NSAttributedString {
    internal func subStrToCount(_ count: Int) -> NSAttributedString {
        var countOfChar = 0
        var result: NSAttributedString?
        self.string.enumerateSubstrings(in: self.string.startIndex..<self.string.endIndex, options: .byComposedCharacterSequences) {(substring, substringRange, _, stopPoint) in
            if substring?.first?.isWideCharacter() == true {
                countOfChar += 2
            } else {
                countOfChar += 1
            }
            if countOfChar > count {
                let prefixRange = NSRange(..<substringRange.lowerBound, in: self.string)
                result = self.attributedSubstring(from: prefixRange)
                stopPoint = true
                return
            }
        }
        return result ?? self
    }

    fileprivate func subStrFromCount(_ count: Int) -> NSAttributedString {
        var countOfChar = 0
        var result: NSAttributedString = NSAttributedString(string: "")
        self.string.enumerateSubstrings(in: self.string.startIndex..<self.string.endIndex, options: .byComposedCharacterSequences) {(substring, substringRange, _, stopPoint) in

            if substring != "\n" {
                if substring?.first?.isWideCharacter() == true {
                    countOfChar += 2
                } else {
                    countOfChar += 1
                }
                if countOfChar >= count {
                    let suffixRange = NSRange(substringRange.upperBound..., in: self.string)
                    result = self.attributedSubstring(from: suffixRange)
                    stopPoint = true
                    return
                }
            }
        }
        return result
    }
    internal func splitAttributedStringByNewline() -> [NSAttributedString] {
        let text = self.string
        let components = text.components(separatedBy: "\n")

        var result: [NSAttributedString] = []

        var location = 0
        for component in components {
            let componentLength = component.utf16.count

            let range = NSRange(location: location, length: componentLength)
            let attributedSubstring = self.attributedSubstring(from: range)
            result.append(attributedSubstring)

            location += componentLength + 1
        }

        return result
    }

    fileprivate func firstNewLineInfo() -> (Int, Range<String.Index>?) {
        var newlineCount = 0
        var newlineRange: Range<String.Index>?
        self.string.enumerateSubstrings(in: self.string.startIndex..<self.string.endIndex, options: .byComposedCharacterSequences) {(substring, substringRange, _, stopPoint) in
            if substring == "\n" {
                newlineRange = substringRange
                stopPoint = true
                return
            } else if substring?.first?.isWideCharacter() == true {
                newlineCount += 2
            } else {
                newlineCount += 1
            }
        }
        return (newlineCount, newlineRange)
    }

    internal func avatarCountInfo(cutCount: Int? = nil) -> AttributeTextCutInfo {
        var countOfChar: Int = 0
        var cutRange: Range<String.Index>?
        var maxRange = self.string.startIndex..<self.string.startIndex
        self.string.enumerateSubstrings(in: self.string.startIndex..<self.string.endIndex, options: .byComposedCharacterSequences) {(substring, substringRange, _, _) in
            if substring != "\n" {
                // 换行符不算个数
                if substring?.first?.isWideCharacter() == true {
                    countOfChar += 2
                } else {
                    countOfChar += 1
                }
            }
            if let cutCount = cutCount, countOfChar <= cutCount {
                cutRange = substringRange
            }
            maxRange = substringRange

        }
        return AttributeTextCutInfo(cutRange: cutRange, maxRange: maxRange, cutCount: cutCount, count: countOfChar)
    }

    internal func adjustAttributedStringFormat(fontSize: CGFloat,
                                               attr: [NSAttributedString.Key: Any] = [:],
                                               needBold: Bool = true,
                                               emotionScale: CGFloat = 1.0) -> NSAttributedString {
        let adjustedString = NSMutableAttributedString()
        self.enumerateAttributes(in: NSRange(location: 0, length: self.length), options: []) { [weak self] (attributes, range, _) in
            guard let self = self else { return }

            if let emojiString = self.attribute(EmotionTransformer.EmojiAttributedKey, at: range.location, effectiveRange: nil) as? String {
                // 处理emoji部分
                guard let emojiKey = emojiString.components(separatedBy: EmotionTransformer.EmojiRandomKeySeparator).last else { return }
                let imageAttachment = NSTextAttachment()
                imageAttachment.image = EmotionResouce.shared.imageBy(key: emojiKey)

                if let image = imageAttachment.image {
                    let font = UIFont.systemFont(ofSize: fontSize)
                    let newHeight = font.pointSize * emotionScale
                    let newWidth = image.size.width * newHeight / image.size.height
                    let newSize = CGSize(width: newWidth, height: newHeight)
                    let descent = (newHeight - font.ascender - font.descender) / 2
                    imageAttachment.bounds = CGRect(origin: CGPoint(x: 0, y: -descent), size: newSize)
                }
                let attachmentString = NSMutableAttributedString(attributedString: NSAttributedString(attachment: imageAttachment))
                attachmentString.addAttributes([EmotionTransformer.EmojiAttributedKey: emojiString], range: NSRange(location: 0, length: 1))
                adjustedString.append(attachmentString)
            } else {
                // 处理文本部分
                let text = self.attributedSubstring(from: range)
                let textString = NSMutableAttributedString(attributedString: text)
                var attributes = attr
                if needBold {
                    attributes[.font] = UIFont.boldSystemFont(ofSize: fontSize)
                } else {
                    attributes[.font] = UIFont.systemFont(ofSize: fontSize)
                }

                textString.addAttributes(attributes, range: NSRange(location: 0, length: textString.length))
                adjustedString.append(textString)
            }
        }

        return adjustedString
    }

}
