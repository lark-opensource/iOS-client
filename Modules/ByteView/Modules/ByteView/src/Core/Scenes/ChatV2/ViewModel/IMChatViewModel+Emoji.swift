//
//  IMChatViewModel+Emoji.swift
//  ByteView
//
//  Created by 陈乐辉 on 2022/11/7.
//

import Foundation

extension IMChatViewModel {
    private var emotion: EmotionDependency { service.emotion }

    func parseEmoji(richText: NSAttributedString, font: UIFont) -> NSAttributedString {
        let text = richText.string
        let matchs = getMatchs(text: text)
        guard !matchs.isEmpty else { return richText }
        let richText = NSMutableAttributedString(string: text)
        let richTextLength = richText.length
        let textCount = text.utf16.count
        matchs.forEach { item in
            let itemRange = item.range
            guard let emojiKey = getEmojiKey(text: text, itemRange: itemRange, textCount: textCount, richTextLength: richTextLength), !emojiKey.isEmpty  else { return }
            guard let imageAttri = getEmojiAttri(emojiKey: emojiKey, font: font) else { return }
            richText.replaceCharacters(in: itemRange, with: imageAttri)
        }
        return richText
    }

    func getMatchs(text: String) -> [NSTextCheckingResult] {
        guard !text.isEmpty, let regExp = Self.emojiRegExp else { return [] }
        let textCount = text.utf16.count
        let textRange = NSRange(location: 0, length: textCount)
        var matchs = regExp.matches(in: text, options: [], range: textRange)
        guard !matchs.isEmpty else { return [] }
        matchs.reverse()
        return matchs
    }

    func getEmojiKey(text: String, itemRange: NSRange, textCount: Int, richTextLength: Int) -> String? {
        guard itemRange.location + itemRange.length <= richTextLength else { return nil }
        let keyRange = NSRange(location: itemRange.location + 1, length: itemRange.length - 2)
        guard keyRange.location + keyRange.length <= textCount else { return nil }
        let emojiName = (text as NSString).substring(with: keyRange)
        guard let emojiKey = emotion.emotionKeyBy(i18n: emojiName) else { return nil }
        return emojiKey
    }

    func getEmoji(emojiKey: String) -> UIImage? {
        guard !emojiKey.isEmpty  else { return nil }
        guard let emoji = emotion.imageByKey(emojiKey) else {
                  return nil
              }
        return emoji
    }

    func getEmojiAttri(emojiKey: String, font: UIFont) -> NSAttributedString? {
        guard let image = getEmoji(emojiKey: emojiKey) else {
            // 企业自定义表情上线后需要再判断下这个表情是否被服务端标记为“违规”
            if emotion.isDeletedBy(key: emojiKey) {
                // 如果表情违规的话不能显示：[文案]，需要显示违规提示：[表情已违规]
                let illegaText = emotion.getIllegaDisplayText()
                return NSAttributedString(string: "[\(illegaText)]")
            }
            // 如果仅仅是因为图片暂时没有取到（并非违规），保持原有逻辑（显示[文案]）
            return nil
        }
        let imageSizeWidth = image.size.width
        let imageSizeHeight = image.size.height
        guard imageSizeWidth != 0, imageSizeHeight != 0 else { return nil }
        let attachment: NSTextAttachment = NSTextAttachment()
        attachment.image = image
        let imageX: CGFloat = 0
        let imageHeight = Cons.emojiHeight
        let imageY: CGFloat = (font.capHeight - imageHeight) / 2
        let radio = imageSizeWidth / imageSizeHeight
        let imageWidth = imageHeight * radio
        attachment.bounds = CGRect(x: imageX, y: imageY, width: imageWidth, height: imageHeight)
        let imageAttri = NSAttributedString(attachment: attachment)
        return imageAttri
    }

    static var emojiRegExp: NSRegularExpression? = {
        let regex = "\\[[^\\[\\]]+\\]"
        guard let regExp = try? NSRegularExpression(pattern: regex, options: [.caseInsensitive]) else {
            return nil
        }
        return regExp
    }()
}
