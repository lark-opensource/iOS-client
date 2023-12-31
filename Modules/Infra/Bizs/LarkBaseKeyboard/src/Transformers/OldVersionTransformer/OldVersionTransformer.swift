//
//  OldVersionTransformer.swift
//  LarkRichTextCore
//
//  Created by 李晨 on 2019/4/2.
//

import UIKit
import Foundation
import LarkUIKit
import EditTextView
import LarkEmotion

// 老版本草稿转化
public final class OldVersionTransformer {
    public static func transformInputText(_ text: NSAttributedString) -> NSAttributedString {
        let transformers: [OldVersionDraftTransform] = [
            OldImageDraftTransformer(),
            OldAtDraftTransformer(),
            OldEmotionDraftTransformer()
        ]

        var text = text
        transformers.forEach { (item) in
            text = item.transformInputText(text)
        }
        return text
    }
}

protocol OldVersionDraftTransform {
    func transformInputText(_ text: NSAttributedString) -> NSAttributedString
}

final class OldEmotionDraftTransformer: OldVersionDraftTransform {
    static let EmojiAttributedKey = NSAttributedString.Key(rawValue: "emoji")
    static let EmojiRandomKeySeparator = "||"
    static let emojiPattern = "\\[[^\\[\\]]+\\]"

    private static func emojiAttachment(content: String, image: UIImage, attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = image
        attachment.bounds = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        if let font = attributes[.font] as? UIFont {
            let fontSize = font.pointSize
            let height = fontSize * 1.3
            let width = image.size.width * height / image.size.height
            let descent = (height - font.ascender - font.descender) / 2
            attachment.bounds = CGRect(x: 0, y: -descent, width: width, height: height)
        }
        let attachmentString = NSMutableAttributedString(attributedString: NSAttributedString(attachment: attachment))
        let randomKeyEmoji = "\(Date().timeIntervalSince1970)\(arc4random() % 100)\(OldEmotionDraftTransformer.EmojiRandomKeySeparator)\(content)"
        attachmentString.addAttribute(OldEmotionDraftTransformer.EmojiAttributedKey, value: randomKeyEmoji, range: NSRange(location: 0, length: 1))
        attachmentString.addAttributes(attributes, range: NSRange(location: 0, length: 1))
        return attachmentString
    }

    func transformInputText(_ text: NSAttributedString) -> NSAttributedString {
        if text.length == 0 { return text }
        let attributes = text.attributes(at: 0, effectiveRange: nil).filter { (key: NSAttributedString.Key, _: Any) -> Bool in
            return key == .font || key == .foregroundColor
        }
        return InputParseUtils.baseAttributedParse(in: text, pattern: OldEmotionDraftTransformer.emojiPattern, formReplaceResult: { parts in
            let string = parts[0]
            var emojiKey = string.lf.trimCharacters(in: ["["], postion: .lead)
            emojiKey = emojiKey.lf.trimCharacters(in: ["]"], postion: .tail)

            if let icon = EmotionResouce.shared.imageBy(key: emojiKey) {
                return OldEmotionDraftTransformer.emojiAttachment(content: string, image: icon, attributes: attributes)
            }
            return NSAttributedString(string: string, attributes: attributes)
        })
    }
}

final class OldAtDraftTransformer: OldVersionDraftTransform {
    static let UserIdAttributedKey = NSAttributedString.Key(rawValue: "userId")
    static let UserIdRandomKeySeparator = "||"
    static let atPattern = "\(InputParseUtils.prefix)@([^\u{00}-\u{15}]+) ([\u{00}-\u{12}]+)\(InputParseUtils.suffix)"
    static let atTextPattern = "<at user_id=\"(\\w*)\">@(.*?)</at>"

    private static func invisibleStringToUserId(_ invisibleString: String) -> String {
        if invisibleString == "\u{11}" {
            return "all"
        }
        return InputParseUtils.invisibleStringToNumberString(invisibleString)
    }

    func transformInputText(_ text: NSAttributedString) -> NSAttributedString {
        if text.length == 0 { return text }
        let attributes = text.attributes(at: 0, effectiveRange: nil).filter { (key: NSAttributedString.Key, _: Any) -> Bool in
            return key == .font || key == .foregroundColor
        }
        return InputParseUtils.baseAttributedParse(in: text, pattern: OldAtDraftTransformer.atPattern, formReplaceResult: { parts in
            let userId = OldAtDraftTransformer.invisibleStringToUserId(parts[2])
            let userName = parts[1]
            let attributedStr = NSMutableAttributedString(string: "@" + userName, attributes: attributes)

            let info = AtChatterInfo(id: userId,
                                     name: userName,
                                     isOuter: false,
                                     actualName: "")
            attributedStr.addAttributes(
                [AtTransformer.UserIdAttributedKey: info,
                 .foregroundColor: UIColor.ud.colorfulBlue],
                range: NSRange(location: 0, length: attributedStr.length))

            return attributedStr
        })
    }
}

final class OldImageDraftTransformer: OldVersionDraftTransform {
    static let ImageAttachmentAttributedKey = NSAttributedString.Key(rawValue: "imageAttachment")
    static let imagePattern = "\(InputParseUtils.prefix)\\[图片([\u{00}-\u{12}]+)\\]\(InputParseUtils.suffix)"
    func transformInputText(_ text: NSAttributedString) -> NSAttributedString {
        if text.length == 0 { return text }
        let attributes = text.attributes(at: 0, effectiveRange: nil).filter { (key: NSAttributedString.Key, _: Any) -> Bool in
            return key == .font || key == .foregroundColor
        }
        return InputParseUtils.baseAttributedParse(in: text, pattern: OldImageDraftTransformer.imagePattern, formReplaceResult: { parts in
            let key = InputParseUtils.invisibleStringToNumberString(parts[1])
            let imageView = AttachmentImageView(key: key, state: .success)
            let bounds = CGRect(x: 0, y: 0, width: 0, height: 0)
            let attachment = CustomTextAttachment(customView: imageView, bounds: bounds)
            let attachmentStr = NSAttributedString(attachment: attachment)
            let attributeString = NSMutableAttributedString(attributedString: attachmentStr)
            let imageInfo = ImageTransformInfo(
                key: "",
                localKey: key,
                imageSize: bounds.size,
                type: .normal,
                useOrigin: false
            )
            attributeString.addAttribute(OldImageDraftTransformer.ImageAttachmentAttributedKey, value: imageInfo, range: NSRange(location: 0, length: 1))
            attributeString.addAttributes(attributes, range: NSRange(location: 0, length: 1))
            return attributeString
        })
    }
}
