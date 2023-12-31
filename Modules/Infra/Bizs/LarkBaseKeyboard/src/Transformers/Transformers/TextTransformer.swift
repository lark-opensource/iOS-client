//
//  TextTransformer.swift
//  LarkRichTextCore
//
//  Created by 李晨 on 2019/3/31.
//

import UIKit
import Foundation
import LarkModel
import RustPB
import LarkRichTextCore

public final class TextTransformer: RichTextTransformProtocol {
    public init() {}

    public func transformFromRichText(attributes: [NSAttributedString.Key : Any], attachmentResult: [String : String]) -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        return self.transformFromRichText(attributes: attributes, attachmentResult: attachmentResult, downgrade: false)
    }

    public func downgradeTransformFromRichText(attributes: [NSAttributedString.Key : Any], attachmentResult: [String : String]) -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        return self.transformFromRichText(attributes: attributes, attachmentResult: attachmentResult, downgrade: true)
    }

    public func transformFromRichText(attributes: [NSAttributedString.Key: Any],
                                      attachmentResult: [String: String],
                                      downgrade: Bool) -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        let process: RichTextElementProcess = { option -> [NSAttributedString] in
            let muattr = NSMutableAttributedString(
                string: "\(option.element.property.text.content)",
                attributes: attributes
            )
            if downgrade {
                return [muattr]
            }
            if let fontAttributes = RichTextParseHelper.transformStyleToAttributes(option.element.style, font: attributes[.font] as? UIFont) {
                muattr.addAttributes(fontAttributes,
                                            range: NSRange(location: 0, length: muattr.length))
            }
            return [muattr]
        }
        return [(.text, process)]
    }

    public func transformToTextFromRichText() -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        let process: RichTextElementProcess = { option -> [NSAttributedString] in
            return [NSAttributedString(string: "\(option.element.property.text.content)")]
        }

        return [(.text, process)]
    }

    public func transformToRichText(_ text: NSAttributedString) -> [RichTextFragmentAttr] {
        let string = text.string as NSString

        var index = 0  // 当前遍历的索引
        var lastTagIndex = 0   // 上一次添加 P tag 的索引
        var lastChar: Character? // 上一个字符
        var autoNewLine = false // 是否需要自动换行
        var result: [RichTextFragmentAttr] = []

        // 判断是否是图片/视频附件/代码块， 这里要排除掉 emtion 的影响
        let attachmentCharacter = Character(UnicodeScalar(NSTextAttachment.character)!)
        let checkIsAttachment = { (char: Character, text: NSAttributedString, range: NSRange) -> Bool in
            if char != attachmentCharacter { return false }
            let subtext = text.attributedSubstring(from: range)
            var isAttachment = false
            subtext.enumerateAttributes(
                in: NSRange(location: 0, length: subtext.length),
                options: []
            ) { (attributes, _, _) in
                if attributes[ImageTransformer.ImageAttachmentAttributedKey] != nil ||
                    attributes[VideoTransformer.VideoAttachmentAttributedKey] != nil ||
                    attributes[ImageTransformer.RemoteImageAttachmentAttributedKey] != nil ||
                    attributes[VideoTransformer.RemoteVideoAttachmentAttributedKey] != nil ||
                    attributes[CodeTransformer.editCodeKey] != nil{
                    isAttachment = true
                }
            }
            return isAttachment
        }

        // 判断是否是换行符
        let checkIsNewline = { (char: Character) -> Bool in
            return NSCharacterSet.newlines.contains(String(char).unicodeScalars.first!)
        }

        let addPTag: (Bool) -> Void = { [self] addPTag in
            if index == lastTagIndex { return }
            defer {
                autoNewLine = false
                lastTagIndex = index
            }

            let range = NSRange(location: lastTagIndex, length: index - lastTagIndex)

            // 如果是自动换行 证明之前有图片附件 不需要添加 P 标签
            if autoNewLine { return }
            var paragraphAttr: RichTextAttr?
            // 添加 p element
            if addPTag {
                let pPriority: RichTextAttrPriority = .high
                let pId = InputUtil.randomId()
                let paragraphProperty = RustPB.Basic_V1_RichTextElement.ParagraphProperty()
                let paragraphTuple: RichTextParseHelper.RichTextAttrTuple = (RustPB.Basic_V1_RichTextElement.Tag.p, pId, .p(paragraphProperty), nil)
                paragraphAttr = RichTextAttr(priority: pPriority, tuple: paragraphTuple)
            }
            var startLocation = range.location
            var length = range.length
            var content = text.attributedSubstring(from: range).string
            if content.hasPrefix("\r\n") {
                content = (content as NSString).substring(from: 2)
                startLocation += 2
                length -= 2
            } else if content.hasPrefix("\n") || content.hasPrefix("\r") {
                content = (content as NSString).substring(from: 1)
                startLocation += 1
                length -= 1
            }

            if !content.isEmpty {
                let textRange = NSRange(location: startLocation, length: length)
                let textTags = Self.addTextTagFor(attributedString: text.attributedSubstring(from: textRange), startLocation: startLocation, paragraphAttr: paragraphAttr)
                result.append(contentsOf: textTags)
            } else {
                let arr = [paragraphAttr].compactMap { $0 }
                result.append(RichTextFragmentAttr(range, arr))
            }
        }

        // 遍历每一个字符
        for i in 0..<string.length {
            // Emoji 在 string 中 char 长度为 1， 在 NSString 中长度为 2
            // Emoji 在这里是无法转化为 UnicodeScalar
            if let unicode = UnicodeScalar(string.character(at: i)) {
                let char = Character(unicode)
                if checkIsAttachment(char, text, NSRange(location: index, length: 1)) {
                    // 图片附件目前单独在一行，需要自动折行， 这里需要判断前一个字符是否是换行符
                    // 后面的文字需要自动折行
                    addPTag(!(lastChar != nil && checkIsNewline(lastChar!)))
                    autoNewLine = true
                } else if checkIsNewline(char) {
                    // 如果出现换行符, 折行
                    // 需要特殊判断 \r\n 算是一个换行
                    // \u2028 is LineSeperator, so do not add P tag in this case.
                    if char != "\u{2028}" &&
                        !(char == "\n" && lastChar == "\r") {
                        addPTag(true)
                    }
                } else if autoNewLine {
                    // 如果之前出现过图片 换行
                    addPTag(true)
                }
                lastChar = char
            } else {
                // 如果是 原生 emoji 判断是否需要折行
                if autoNewLine { addPTag(true) }
                lastChar = nil
            }
            index += 1
        }
        addPTag(true)

        return result
    }

    /*
     贴子需求：若正文的前N行/后N行只有空格和换行符，发出后直接删除掉这些行（只删空白整行，不删非空白行前面的空格）。
     */
    public static func removeWhitespacesAndNewlines(_ text: String) -> String {
        var mutiText = text
        recognitionWhitespacesAndNewlines(mutiText) { (textRange, _) -> String in
            mutiText.replaceSubrange(textRange, with: "")
            return mutiText
        }

        return mutiText
    }

    public static func removeWhitespacesAndNewlines(_ text: NSAttributedString) -> NSAttributedString {
        if let mutiText = text.mutableCopy() as? NSMutableAttributedString {
            var string = text.string
            do {
                try recognitionWhitespacesAndNewlines(string) { (textRange, range) -> String in
                    string.replaceSubrange(textRange, with: "")
                    mutiText.replaceCharacters(in: range, with: "")
                    return string
                }
            } catch {}

            return mutiText
        }
        return text
    }
    /**
     这里需要把原来的text的标签 拆分一下 eg:
     原: wwwxxxaaa .text标签可以表示.text(wwwxxxaaa)
     新: wwwXXXaAA  xxx被加粗 aa 被加粗.text(www) .text(XXX) .text(a) .text(AA)
     这里的拆分方式&系统的一致 直接使用系统的方式
     */
    private static func addTextTagFor(attributedString: NSAttributedString, startLocation: Int, paragraphAttr: RichTextAttr?) -> [RichTextFragmentAttr] {
        var attrs: [RichTextFragmentAttr] = []
        let muAttributedString = NSMutableAttributedString(attributedString: attributedString)
        attributedString.enumerateAttributes(in: NSRange(location: 0, length: attributedString.length), options: []) { (attributes, range, _) in
            let keys: [NSAttributedString.Key] = [FontStyleConfig.underlineAttributedKey,
                                                  FontStyleConfig.strikethroughAttributedKey,
                                                  FontStyleConfig.italicAttributedKey,
                                                  FontStyleConfig.boldAttributedKey]
            let invalidAttributes = attributes.filter { !keys.contains($0.key) }
            invalidAttributes.forEach { muAttributedString.removeAttribute($0.key, range: range) }
        }
        muAttributedString.enumerateAttributes(in: NSRange(location: 0, length: attributedString.length), options: []) { (attributes, range, _) in
            var style: [RichTextStyleKey: [RichTextStyleValue]] = [:]
            if attributes[FontStyleConfig.boldAttributedKey] != nil {
                style[.fontWeight] = [.bold]
            }
            if attributes[FontStyleConfig.italicAttributedKey] != nil {
                style[.fontStyle] = [.italic]
            }
            if attributes[FontStyleConfig.underlineAttributedKey] != nil, attributes[FontStyleConfig.strikethroughAttributedKey] != nil {
                style[.textDecoration] = [.lineThrough, .underline]
            } else {
                if attributes[FontStyleConfig.strikethroughAttributedKey] != nil {
                    style[.textDecoration] = [.lineThrough]
                } else if attributes[FontStyleConfig.underlineAttributedKey] != nil {
                    style[.textDecoration] = [.underline]
                }
            }
            let textPriority: RichTextAttrPriority = .lowest
            let textId = InputUtil.randomId()
            var textProperty = RustPB.Basic_V1_RichTextElement.TextProperty()
            textProperty.content = (muAttributedString.string as NSString).substring(with: range)
            let textTuple: RichTextParseHelper.RichTextAttrTuple = (RustPB.Basic_V1_RichTextElement.Tag.text, textId, .text(textProperty), style)
            let textAttr = RichTextAttr(priority: textPriority, tuple: textTuple)
            let textAttrattrs: [RichTextAttr] = [paragraphAttr, textAttr].compactMap { $0 }
            attrs.append(RichTextFragmentAttr(NSRange(location: range.location + startLocation, length: range.length), textAttrattrs))
        }
        return attrs
    }
    
    private static let regex = try! NSRegularExpression(pattern: "^\\s*\\n|\\n\\s*$", options: [])

    private static func recognitionWhitespacesAndNewlines(_ text: String, matchBlock: (Range<String.Index>, NSRange) -> String) {
        var text = text
        while let result = regex.firstMatch(in: text, range: NSRange(location: 0, length: text.utf16.count)) {
            let range = result.range
            let textRange = text.index(text.startIndex, offsetBy: range.location)..<text.index(text.startIndex, offsetBy: range.location + range.length)
            text = matchBlock(textRange, range)
        }
    }
}
