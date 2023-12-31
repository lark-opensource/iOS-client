//
//  IMChatViewModel+Digest.swift
//  ByteView
//
//  Created by 陈乐辉 on 2022/11/8.
//

import Foundation
import ByteViewNetwork

extension IMChatViewModel {

    func getOriginalDigest(_ digest: Digest) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        var elements = digest.elements
        if elements.count > 1 {
            elements.remove(at: 0)
            if elements.count > 1, elements[0].text.content == ": " {
                elements.remove(at: 0)
            }
        }
        elements.forEach { (element: DigestElement) in
            switch element.tag {
            case .text:
                let text = getTextAttri(textProperty: element.text)
                attributedString.append(text)
            case .emoji:
                let emoji = getEmojiAttri(emojiProperty: element.emoji, font: Cons.contentFont)
                attributedString.append(emoji)
            case .textWithEmojis:
                let textWithEmoji = getTextWithEmojistAttri(text: element.text.content, font: Cons.contentFont)
                attributedString.append(textWithEmoji)
            @unknown default:
                break
            }
        }
        attributedString.addAttributes(Cons.attributes, range: NSRange(location: 0, length: attributedString.length))
        return attributedString
    }

    func getTextAttri(textProperty: TextProperty) -> NSAttributedString {
        return NSAttributedString(string: textProperty.content)
    }

    func getEmojiAttri(emojiProperty: EmojiProperty, font: UIFont) -> NSAttributedString {
        if let imageAttri = getEmojiAttri(emojiKey: emojiProperty.emojiKey, font: font) {
            return imageAttri
        }
        return NSAttributedString(string: emojiProperty.defaultContent)
    }

    func getTextWithEmojistAttri(text: String, font: UIFont) -> NSAttributedString {
        let matchs = getMatchs(text: text)
        guard !matchs.isEmpty else { return NSAttributedString(string: text) }
        let richText = NSMutableAttributedString(string: text)
        let richTextLength = richText.length
        let textCount = text.utf16.count
        matchs.forEach { item in
            let itemRange = item.range
            guard let emojiKey = getEmojiKey(text: text, itemRange: itemRange, textCount: textCount, richTextLength: richTextLength), !emojiKey.isEmpty  else { return }
            guard let emojiAttri = getEmojiAttri(emojiKey: emojiKey, font: font) else { return }
            richText.replaceCharacters(in: itemRange, with: emojiAttri)
        }
        return richText
    }
}
