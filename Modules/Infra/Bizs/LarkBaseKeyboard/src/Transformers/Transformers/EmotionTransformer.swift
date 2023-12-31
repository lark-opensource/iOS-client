//
//  EmotionTransformer.swift
//  LarkRichTextCore
//
//  Created by 李晨 on 2019/3/31.
//

import UIKit
import Foundation
import LarkModel
import LarkUIKit
import LarkEmotion
import EditTextView
import RustPB
import ThreadSafeDataStructure

final class EmojiView: UIView, AttachmentPreviewableView {
    var emoji: UIImage? {
        didSet {
            emojiLayer.contents = emoji?.cgImage
        }
    }

    var emojiSize: CGSize = .zero {
        didSet {
            emojiLayer.frame.size = emojiSize
        }
    }

    var emojiLayer = CALayer()

    override var frame: CGRect {
        didSet {
            emojiLayer.bounds.center = self.bounds.center
        }
    }

    init(emoji: UIImage) {
        super.init(frame: .zero)
        self.emoji = emoji
        layer.addSublayer(emojiLayer)
        emojiLayer.contents = emoji.cgImage
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    /// conform to `AttachmentPreviewableView`
    lazy var previewImage: () -> UIImage? = { [weak self] in self?.emoji }
}

public final class EmotionTransformer: RichTextTransformProtocol {
    public init() {}

    public static let EmojiAttributedKey = NSAttributedString.Key(rawValue: "emoji")
    public static let EmojiRandomKeySeparator = "||"
    /// 含义：              \[                                         [^\[\]\s]                                                +                                      \]
    ///          找到[符号               匹配[、]、空白外的其他字符           前面的表达式至少满足一次            找到]符号
    ///
    public static let pattern = "\\[[^\\[\\]\\f\\n\\r\\t\\v]+?\\]"
    public static let regex = try? NSRegularExpression(pattern: pattern)

    public typealias InsertContent = String

    private static var emojisWithPadding = SafeLRUDictionary<String, UIImage>(capacity: 30)
    static func getEmojiWithPadding(with key: String) -> UIImage? {
        if let emoji = emojisWithPadding.getValue(for: key) {
            return emoji
        }
        if let rawEmoji = EmotionResouce.shared.imageBy(key: key) {
            // emoji之间距离调整成 4pt
            // Spacing between emojis adjust to 4pt.
            let emoji = UIGraphicsImageRenderer(
                size: CGSize(width: rawEmoji.size.width + 4, height: rawEmoji.size.height)
            ).image { _ in
                rawEmoji.draw(in: CGRect(x: 2, y: 0, width: rawEmoji.size.width, height: rawEmoji.size.height))
            }
            emojisWithPadding.setValue(emoji, for: key)
            return emoji
        }
        return nil
    }

    public static func transformContentToString(_ content: InsertContent, attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        var emojiKey = content.lf.trimCharacters(in: ["["], postion: .lead)
        emojiKey = emojiKey.lf.trimCharacters(in: ["]"], postion: .tail)
        // 自定义表情上线后需要考虑表情违规的问题
        let isDeleted = EmotionResouce.shared.isDeletedBy(key: emojiKey)
        if isDeleted {
            // 如果该表情违规：不能显示图片，不能显示正常文案，直接透出违规提示
            let illegaText = EmotionResouce.shared.getIllegaDisplayText()
            return NSAttributedString(string: "[\(illegaText)]")
        }
        if let icon = getEmojiWithPadding(with: emojiKey) {
            let emojiView = EmojiView(emoji: icon)
            var size = icon.size
            emojiView.emojiSize = size
            emojiView.frame = CGRect(origin: .zero, size: size)
            let attachment = CustomTextAttachment(customView: emojiView, bounds: CGRect(origin: .zero, size: size))
            var attributes = attributes
            if let font = attributes[.font] as? UIFont {
                let fontSize = font.pointSize
                let height = fontSize * 1.3
                let width = icon.size.width * height / icon.size.height
                let descent = (height - font.ascender - font.descender) / 2
                size = CGSize(width: width, height: height)
                attachment.bounds = CGRect(origin: CGPoint(x: 0, y: -descent), size: size)
                emojiView.emojiSize = CGSize(width: width, height: height)
            }
            let attachmentString = NSMutableAttributedString(attributedString: NSAttributedString(attachment: attachment))
            let randomKeyEmoji = Self.attributeStrValueForKey(content)
            attributes[EmotionTransformer.EmojiAttributedKey] = randomKeyEmoji
            attachmentString.addAttributes(attributes, range: NSRange(location: 0, length: 1))
            return attachmentString
        }
        return NSAttributedString(string: content)
    }

    public static func attributeStrValueForKey(_ key: String) -> String {
        return "\(Date().timeIntervalSince1970)\(arc4random() % 100)\(EmotionTransformer.EmojiRandomKeySeparator)\(key)"
    }

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
            let emotionKey = option.element.property.emotion.key
            if downgrade {
                return Self.downgradeEmotionContentFor(key: emotionKey, attributes: attributes)
            } else {
                return [EmotionTransformer.transformContentToString(emotionKey, attributes: attributes)]
            }
        }

        return [(.emotion, process)]
    }

    public func transformToTextFromRichText() -> [(RustPB.Basic_V1_RichTextElement.Tag, RichTextElementProcess)]? {
        let process: RichTextElementProcess = { option -> [NSAttributedString] in
            let emotionKey = option.element.property.emotion.key
            return Self.downgradeEmotionContentFor(key: emotionKey, attributes: [:])
        }

        return [(.emotion, process)]
    }


    public func transformToRichText(_ text: NSAttributedString) -> [RichTextFragmentAttr] {
        var result: [RichTextFragmentAttr] = []
        let priority: RichTextAttrPriority = .content

        text.enumerateAttribute(EmotionTransformer.EmojiAttributedKey, in: NSRange(location: 0, length: text.length), options: []) { (emoji, range, _) in
            if let emoji = emoji as? String {
                var emojiString = ""
                let randomKeyEmoji = emoji
                if let realEmojiStr = randomKeyEmoji.components(separatedBy: EmotionTransformer.EmojiRandomKeySeparator).last {
                    emojiString = realEmojiStr
                    emojiString = emojiString.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
                }
                if emojiString.isEmpty {
                    return
                }
                let emotionId = InputUtil.randomId()
                var emotionProperty = RustPB.Basic_V1_RichTextElement.EmotionProperty()
                emotionProperty.key = emojiString
                let tuple: RichTextParseHelper.RichTextAttrTuple = (RustPB.Basic_V1_RichTextElement.Tag.emotion, emotionId, .emotion(emotionProperty), nil)
                let attr = RichTextAttr(priority: priority, tuple: tuple)
                result.append(RichTextFragmentAttr(range, [attr]))
            }
        }
        return result
    }

    public static func retransformContentToString(_ text: NSAttributedString) -> NSAttributedString {
        if let attributedText = text.mutableCopy() as? NSMutableAttributedString {
            var hadTransform = false
            var range: NSRange = NSRange(location: 0, length: 0)
            var emojiKey = ""
            let copyEmojiKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "message.copy.emoji.key")

            attributedText.enumerateAttribute(EmotionTransformer.EmojiAttributedKey, in: NSRange(location: 0, length: attributedText.length), options: []) { (emoji, r, stop) in
                if let emoji = emoji as? String {
                    hadTransform = true
                    range = r
                    let randomKeyEmoji = emoji
                    if let realEmojiStr = randomKeyEmoji.components(separatedBy: EmotionTransformer.EmojiRandomKeySeparator).last {
                        emojiKey = realEmojiStr
                        emojiKey = emojiKey.lf.trimCharacters(in: ["["], postion: .lead)
                        emojiKey = emojiKey.lf.trimCharacters(in: ["]"], postion: .tail)
                    }
                    stop.pointee = true
                }
            }

            if hadTransform {
                attributedText.removeAttribute(EmotionTransformer.EmojiAttributedKey, range: range)
                attributedText.removeAttribute(.attachment, range: range)
                attributedText.addAttribute(copyEmojiKeyAttributedKey, value: emojiKey, range: range)
                if let emojiContent = EmotionResouce.shared.i18nBy(key: emojiKey) {
                    attributedText.replaceCharacters(in: range, with: "[\(emojiContent)]")
                } else {
                    attributedText.replaceCharacters(in: range, with: "[\(emojiKey)]")
                }

                return self.retransformContentToString(attributedText)
            } else {
                return attributedText
            }
        }

        return text
    }

    // 粘贴带有表情的文本时将表情替换为icon富文本返回
    public static func transformPastestringToRichText(_ string: String, attributes: [NSAttributedString.Key: Any],
                                                      matchResult: [NSTextCheckingResult], emojiKeyMap: [NSRange: String]?) -> NSAttributedString {
        return transformPasteAttributedStringToRichText(NSAttributedString(string: string, attributes: attributes), attributes: attributes, matchResult: matchResult, emojiKeyMap: emojiKeyMap)
    }

    // 粘贴带有表情的文本时将表情替换为icon富文本返回
    public static func transformPasteAttributedStringToRichText(_ text: NSAttributedString,
                                                                attributes: [NSAttributedString.Key: Any],
                                                                matchResult: [NSTextCheckingResult],
                                                                emojiKeyMap: [NSRange: String]?) -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: text)
        for checkingRes in matchResult.reversed() {
            // 取出表情文案
            let subStr = (result.string as NSString).substring(with: checkingRes.range)
            var emojiKey: String?
            if let emojiKeyMap = emojiKeyMap {
                emojiKey = emojiKeyMap[checkingRes.range]
            }
            let attributeStr = self.replaceStrToEmojiAtt(subStr, attributes: attributes, emojiKey: emojiKey)
            result.replaceCharacters(in: checkingRes.range, with: attributeStr)
        }
        return NSAttributedString(attributedString: result)
    }

    public static func replaceStrToEmojiAtt(_ subStr: String,
                                            attributes: [NSAttributedString.Key: Any],
                                            emojiKey: String?) -> NSAttributedString {
        var attributeStr = NSAttributedString(string: "")
        var emojiContent = ""
        var newEmojiKey: String = ""

        emojiContent = subStr.lf.trimCharacters(in: ["["], postion: .lead)
        emojiContent = emojiContent.lf.trimCharacters(in: ["]"], postion: .tail)
        // 如果剪贴板里面有对应range的emojiKey，那么从剪切板里面取出对应的emojiKey
        if let emojiKey = emojiKey {
            // 拼接成[emojiKey]格式
            newEmojiKey = "[" + emojiKey + "]"
            // 如果是表情字符串，转为带表情的富文本
            attributeStr = self.transformContentToString(newEmojiKey, attributes: attributes)
        } else if let emojiKey = EmotionResouce.shared.emotionKeyBy(i18n: emojiContent) {
            // 剪切板里面没有emojiKey的相关信息，那么降级成“文案”，通过文案找到对应的emojiKey
            // 拼接成[emojiKey]格式
            newEmojiKey = "[" + emojiKey + "]"
            // 如果是表情字符串，转为带表情的富文本
            attributeStr = self.transformContentToString(newEmojiKey, attributes: attributes)
        } else {
            // 如果是普通文本，转为普通文本的富文本
            attributeStr = NSAttributedString(string: subStr, attributes: attributes)
        }
        return attributeStr
    }

    public static func hasNeedTransformEmoji(_ content: String) -> Bool {
        var emojiContent = content.lf.trimCharacters(in: ["["], postion: .lead)
        emojiContent = emojiContent.lf.trimCharacters(in: ["]"], postion: .tail)
        return EmotionResouce.shared.emotionKeyBy(i18n: emojiContent) != nil
    }

    public static func regularResult(_ string: String) -> [NSTextCheckingResult] {
        guard let res = regex?.matches(in: string, options: .reportCompletion, range: NSRange(location: 0, length: string.utf16.count)) else {
            return []
        }
        return res
    }

    private static func downgradeEmotionContentFor(key: String, attributes: [NSAttributedString.Key: Any]) -> [NSAttributedString] {
        if let content = EmotionResouce.shared.i18nBy(key: key) {
            return [NSAttributedString(string: "[\(content)]", attributes: attributes)]
        }
        return [NSAttributedString(string: "[\(key)]", attributes: attributes)]
    }
}
