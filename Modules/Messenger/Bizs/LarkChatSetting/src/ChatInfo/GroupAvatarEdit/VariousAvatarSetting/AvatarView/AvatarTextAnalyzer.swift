//
//  AvatarTextAnalyzer.swift
//  LarkChatSetting
//
//  Created by liluobin on 2023/2/10.
//

import UIKit
import LarkExtensions

struct TextCutInfo {
    /// 实际字符idx
    let cutIdx: Int?
    let maxIdx: Int
    /// count 产品定义
    let cutCount: Int?
    let count: Int

    var prefixLength: Int {
        return (cutIdx ?? -1) + 1
    }

    var suffixLength: Int {
        guard let cutIdx = cutIdx else {
            return 0
        }
        return maxIdx - cutIdx
    }
}

final class AvatarTextAnalyzer {
    static let maxCountOfCharacter = 14
    private let firstLineMinFontSize: CGFloat = 28
    private let lastLineMinFontSize: CGFloat = 22
    let resultCallBack: ((NSAttributedString) -> Void)?
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

    init(resultCallBack: ((NSAttributedString) -> Void)?,
         textColorCallBack: (() -> UIColor)?) {
        self.resultCallBack = resultCallBack
        self.textColorCallBack = textColorCallBack
    }

    func analysisText(_ text: String?) {
        self.resultCallBack?(self.attrbuteStrForText(text))
    }

    func attrbuteStrForText(_ text: String?) -> NSAttributedString {
        guard let text = text, !text.lf.trimCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return NSAttributedString(string: "")
        }
        /// 对四个汉字需要特化处理，展示方块
        let targetText = text.lf.trimString(target: ["\n"], postion: .both)
        if let attr = self.handerFourChineseCharacterTextIfNeed(text: targetText) {
            return attr
        }
        return self.transformTextToAttributeStr(text: targetText)
    }

    func getColorAttributes() -> [NSAttributedString.Key: Any] {
        return [.foregroundColor: self.textColorCallBack?() ?? UIColor.ud.primaryOnPrimaryFill]
    }

    func filterText(_ text: String) -> String? {
        var newText = ""
        /// 防止粘贴的文字含有多个换行
        let components = text.components(separatedBy: "\n")
        if components.count > 2 {
            newText.append(components[0])
            newText.append("\n")
            newText.append(components[1])
        } else {
            newText = text
        }

        let result = newText.avatarCountInfo(cutCount: Self.maxCountOfCharacter)
        guard result.count > Self.maxCountOfCharacter else { return nil }
        /// cutIndex 为Id 0...x, 所以需要加1
        return String(newText.prefix(result.prefixLength))
    }

    private func handerFourChineseCharacterTextIfNeed(text: String) -> NSAttributedString? {
        var isAllChinese = false
        var chineseCount = 0
        var cutIndex: Int?
        for (index, item) in text.enumerated() {
            isAllChinese = item.isChinese()
            if !isAllChinese {
                break
            }
            chineseCount += 2
            if chineseCount == 4 {
                cutIndex = index
            }
        }
        if isAllChinese,
           chineseCount == 8,
           let cutIndex = cutIndex {
            var attributes: [NSAttributedString.Key: Any] = self.getColorAttributes()
            attributes[.font] = UIFont.boldSystemFont(ofSize: 34)
            attributes[.paragraphStyle] = paragraphStyle
            let muAttr = NSMutableAttributedString(string: String(text.prefix(cutIndex + 1)), attributes: attributes)
            muAttr.append(NSAttributedString(string: "\n"))
            muAttr.append(NSAttributedString(string: String(text.suffix(cutIndex + 1)),
                                             attributes: attributes))
            return muAttr
        }
        return nil
    }

    func transformTextToAttributeStr(text: String) -> NSAttributedString {
        /// 如果没有换行 根据情况插入换行
        let info = text.firstNewLineInfo()
        let newlineCount = info.0
        let newlineIdx = info.1
        let targetStr: NSAttributedString
        let countInfo = text.avatarCountInfo(cutCount: 6)
        let fontInfo = self.getWithoutNewlineFontForCharCount(count: countInfo.count)
        /// 由于输入框的最多输入两列，所以中间只有一个换行，需要根据实际展示的规则调整换行的位置
        if newlineIdx != nil {
            targetStr = fixTextForNewline(text, newlineCount: newlineCount)
        } else {
            /// 没有换行的时候 处理起来简单
            if countInfo.count > 6 {
                let muAttr = NSMutableAttributedString(string: String(text.prefix(countInfo.prefixLength)),
                                                       attributes: getAttributesWidthFont(fontInfo.0))
                muAttr.append(NSAttributedString(string: "\n"))
                muAttr.append(NSAttributedString(string: String(text.suffix(countInfo.suffixLength)),
                                                 attributes: getAttributesWidthFont(fontInfo.1)))
                targetStr = muAttr
            } else {
                targetStr = NSAttributedString(string: text, attributes: getAttributesWidthFont(fontInfo.0))
            }
        }
        let murAttr = NSMutableAttributedString(attributedString: targetStr)
        murAttr.addAttributes([.paragraphStyle: paragraphStyle], range: NSRange(location: 0, length: targetStr.length))
        return murAttr
    }

    func fixTextForNewline(_ text: String, newlineCount: Int) -> NSAttributedString {
        let strArr = (text as NSString).components(separatedBy: "\n")
        var firstStr = strArr.first ?? ""
        var lastStr = strArr.last ?? ""
        /// 如果换行的位置正好 那就不需要调整 加上字体即可
        if newlineCount < 7 {
            lastStr = lastStr.subStrToCount(8)
        } else if newlineCount > 7 {
            firstStr = firstStr.subStrToCount(6)
            lastStr = text.subStrFromCount(7)
        }
        let fontInfo = self.getFontForNewLine(firstLineCount: firstStr.avatarCountInfo().count,
                                              lastLineCount: lastStr.avatarCountInfo().count)
        let muAttr = NSMutableAttributedString(string: firstStr,
                                               attributes: getAttributesWidthFont(fontInfo.0))
        muAttr.append(NSAttributedString(string: "\n"))
        muAttr.append(NSAttributedString(string: lastStr,
                                         attributes: getAttributesWidthFont(fontInfo.1)))
        return muAttr
    }

    private func getFontForNewLine(firstLineCount: Int, lastLineCount: Int) -> (UIFont, UIFont) {

        if firstLineCount <= 2, lastLineCount <= 2 {
            return (UIFont.boldSystemFont(ofSize: 42), UIFont.boldSystemFont(ofSize: 42))
        }

        if firstLineCount <= 4, lastLineCount <= 4 {
            return (UIFont.boldSystemFont(ofSize: 34), UIFont.boldSystemFont(ofSize: 34))
        }

        if firstLineCount <= 6, lastLineCount <= 6 {
            return (UIFont.boldSystemFont(ofSize: 28), UIFont.boldSystemFont(ofSize: 28))
        }

        if lastLineCount <= 6 {
            assertionFailure("lastLineCount can <= 6")
        }
        return (UIFont.boldSystemFont(ofSize: 28), UIFont.boldSystemFont(ofSize: 22))
    }

    /// 获取当前字符数对应的字体大小
    private func getWithoutNewlineFontForCharCount(count: Int) -> (UIFont, UIFont) {
        var sizeOfFirstLine = firstLineMinFontSize            // 第一行最小字号
        var sizeOfLastLine = lastLineMinFontSize
        // disable-lint: magic_number
        switch count {
        case 1, 2:
            sizeOfFirstLine = 52
        case 3, 4:
            sizeOfFirstLine = 42
        case 5, 6:
            sizeOfFirstLine = 30
        case 7...12:
            sizeOfFirstLine = 28
            sizeOfLastLine = 28
        default:
            break
        }
        // enable-lint: magic_number
        // 字号加粗
        return (UIFont.boldSystemFont(ofSize: CGFloat(sizeOfFirstLine)),
                UIFont.boldSystemFont(ofSize: CGFloat(sizeOfLastLine)))
    }

    private func getAttributesWidthFont(_ font: UIFont) -> [NSAttributedString.Key: Any] {
        var attributes = self.getColorAttributes()
        attributes[.font] = font
        return attributes
    }
}

extension String {
    fileprivate func subStrToCount(_ count: Int) -> String {
        var countOfChar = 0
        for (index, item) in self.enumerated() {
            if item.isWideCharacter() {
                countOfChar += 2
            } else {
                countOfChar += 1
            }
            if countOfChar > count {
                return String(self.prefix(index))
            }
        }
        return self
    }

    fileprivate func subStrFromCount(_ count: Int) -> String {
        let text = self.replacingOccurrences(of: "\n", with: "")
        var countOfChar = 0
        var str: String = ""
        for (idx, item) in text.enumerated() {
            if item.isWideCharacter() {
                countOfChar += 2
            } else {
                countOfChar += 1
            }
            if countOfChar >= count {
                str.append(item)
            }
        }
        return str
    }

    fileprivate func firstNewLineInfo() -> (Int, Int?) {
        var newlineCount = 0
        var newlineIdx: Int?
        for (index, item) in self.enumerated() {
            /// 当要换行的时候，需要判断下换行的字符
            if item == "\n" {
                newlineCount += 1
                newlineIdx = index
                break
            } else if item.isWideCharacter() {
                newlineCount += 2
            } else {
                newlineCount += 1
            }
        }
        return (newlineCount, newlineIdx)
    }

    func avatarCountInfo(cutCount: Int? = nil) -> TextCutInfo {
        var countOfChar: Int = 0
        var cutIdx: Int?
        var idxCount = 0
        for (index, item) in self.enumerated() {
            /// 当要换行的时候，需要判断下换行的字符
            if item == "\n" {
                continue
            } else if item.isWideCharacter() {
                countOfChar += 2
            } else {
                countOfChar += 1
            }
            if let cutCount = cutCount, countOfChar <= cutCount {
                cutIdx = index
            }
            idxCount = index
        }
        return TextCutInfo(cutIdx: cutIdx, maxIdx: idxCount, cutCount: cutCount, count: countOfChar)
    }
}
