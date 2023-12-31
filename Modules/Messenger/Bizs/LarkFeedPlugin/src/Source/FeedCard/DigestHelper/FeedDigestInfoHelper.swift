//
//  FeedDigestInfoHelper.swift
//  LarkFeedPlugin
//
//  Created by liuxianyu on 2023/5/23.
//

import Foundation
import LarkModel
import RustPB
import LarkFeed
import LarkEmotion
import LarkFeedBase
import UniverseDesignColor
import LarkContainer

// TODO: open feed 该类需要重新 review 下
public final class FeedDigestInfoHelper {
    public enum DigestMode {
        case normal
        case draft
        case focus
    }

    lazy var attributes: [NSAttributedString.Key: Any] = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail
        return [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: FeedCardDigestComponentView.Cons.textColor]
    }()

    let userResolver: UserResolver
    let feedDependency: FeedDependency?
    let feedPreview: FeedPreview
    let font: UIFont
    public init(feedPreview: FeedPreview, userResovler: UserResolver) {
        self.userResolver = userResovler
        self.feedPreview = feedPreview
        self.font = FeedCardDigestComponentView.Cons.digestFont
        self.feedDependency = try? userResovler.resolve(assert: FeedDependency.self)
    }

    // 摘要模式
    public func generateDigestMode(selectedStatus: Bool) -> DigestMode {
        if !feedPreview.uiMeta.draft.content.isEmpty && !selectedStatus {
            return .draft
        }
        // [星标联系人]文案展示逻辑要排除单聊情况
        let isFocus = feedPreview.preview.chatData.focusInfo.messageID > 0
        let isFocusMode = isFocus && feedPreview.preview.chatData.chatType != .p2P
        if isFocusMode {
            return .focus
        }
        return .normal
    }

    public func generateDigestContent(selectedStatus: Bool) -> NSAttributedString {
        let mode = generateDigestMode(selectedStatus: selectedStatus)
        switch mode {
        case .normal:
            return getGeneralDigest()
        case .draft:
            return getDraftDigest()
        case .focus:
            return getFocusDigest()
        }
    }
}

// MARK: 普通摘要
extension FeedDigestInfoHelper {
    public func getGeneralDigest() -> NSAttributedString {
        let originalDigest = getOriginalDigest(self.feedPreview.uiMeta.digest)
        let unreadCount = feedPreview.basicMeta.unreadCount
        guard FeedBadgeBaseConfig.badgeStyle == .strongRemind,
              unreadCount > 0,
              !feedPreview.basicMeta.isRemind else { return originalDigest }
        let countDesc = unreadCount == 1 ? BundleI18n.LarkFeedPlugin.Lark_Legacy_UnReadCount("\(unreadCount)") :
            BundleI18n.LarkFeedPlugin.Lark_Legacy_UnReadCounts("\(unreadCount)")
        let digest = NSMutableAttributedString(string: countDesc, attributes: attributes)
        digest.append(originalDigest)
        return digest
    }

    // 原始摘要：即只从feedPreview.digest里解析出来的摘要
    public func getOriginalDigest(_ digest: Feed_V1_Digest) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        digest.elements.forEach { (element: Feed_V1_Digest.Element) in
            switch element.tag {
            case .text:
                let text = getTextAttri(textProperty: element.text)
                attributedString.append(text)
            case .emoji:
                let emoji = getEmojiAttri(emojiProperty: element.emoji, font: font)
                attributedString.append(emoji)
            case .textWithEmojis:
                let textWithEmoji = getTextWithEmojistAttri(text: element.text.content, font: font)
                attributedString.append(textWithEmoji)
            case .unspecified:
                break
            @unknown default:
                break
            }
        }
        attributedString.addAttributes(attributes, range: NSRange(location: 0, length: attributedString.length))
        return attributedString
    }
}

// MARK: - 特化的场景：【草稿】
extension FeedDigestInfoHelper {
    public func getDraftDigest() -> NSAttributedString {
        let draft: String
        // 草稿分为 Text, POST, 存储格式不一样。
        // 优先使用原有方式解析，无法解析使用 POST 方式
        if feedPreview.preview.chatData.isCrypto {
            draft = feedPreview.uiMeta.draft.content
        } else {
            draft = feedDependency?.getDraftFromLarkCoreModel(content: feedPreview.uiMeta.draft.content) ?? ""
        }
        return NSAttributedString(string: draft, attributes: attributes)
    }
}

// MARK: - 特化的场景：【特别关注】
extension FeedDigestInfoHelper {
    public func getFocusDigest() -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail
        let specialFocusAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: UIColor.ud.textLinkNormal
        ]
        let focusDigest = NSMutableAttributedString(string: "[" + BundleI18n.LarkFeedPlugin.Lark_IM_StarredContacts_FeatureName + "] ", attributes: specialFocusAttributes)
        let digest = getGeneralDigest()
        focusDigest.append(digest)
        return focusDigest
    }
}

// MARK: 会话盒子feed摘要
extension FeedDigestInfoHelper {
    public func getHasReadDigestForBox() -> NSAttributedString {
        if feedPreview.preview.boxData.hasFocus_p {
            return getFocusMessage(content: feedPreview.uiMeta.digestText, foregroundColor: UIColor.ud.N500)
        } else {
            return NSAttributedString(string: feedPreview.uiMeta.digestText, attributes: attributes)
        }
    }

    public func getUnreadDigestForBoxFeed() -> NSAttributedString {

        let boxAtInfos = FeedPreviewAt.transform(atInfos: feedPreview.preview.boxData.atInfos)

        // Note: Rust 保证不会同时返回 @ 和 focus 消息
        let digestMessage = "[\(feedPreview.uiMeta.digestText)]"
        if !boxAtInfos.isEmpty {
            let atInfo = boxAtInfos.count == 1 ?
                BundleI18n.LarkFeedPlugin.Lark_Legacy_FeedBoxOneGroupHasAt(boxAtInfos[0].channelName) :
                BundleI18n.LarkFeedPlugin.Lark_Legacy_AtInGroups("\(boxAtInfos.count)")
            let contentStr = atInfo + digestMessage
            let attributedStr = NSAttributedString(string: contentStr, attributes: attributes)
            return attributedStr
        } else if feedPreview.preview.boxData.hasFocus_p {
            return getFocusMessage(content: digestMessage, foregroundColor: UIColor.ud.N500)
        } else {
            return NSAttributedString(string: digestMessage, attributes: attributes)
        }
    }

    private func getFocusMessage(content: String, foregroundColor: UIColor) -> NSAttributedString {
        let focusTag = "[" + BundleI18n.LarkFeedPlugin.Lark_IM_StarredContacts_FeatureName + "] "
        let digestContent = focusTag + content
        let attriStr = NSMutableAttributedString(string: digestContent)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingTail
        let specialFocusAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: foregroundColor
        ]
        attriStr.addAttributes(specialFocusAttributes, range: NSRange(location: 0, length: focusTag.utf16.count))
        if !content.isEmpty {
            attriStr.addAttributes(attributes, range: NSRange(location: focusTag.utf16.count, length: content.utf16.count))
        }
        return attriStr
    }
}

// MARK: - 解析 Feed_V1_Digest
extension FeedDigestInfoHelper {
    private func getTextAttri(textProperty: Feed_V1_Digest.Element.TextProperty) -> NSAttributedString {
        return NSAttributedString(string: textProperty.content)
    }

    private func getEmojiAttri(emojiProperty: Feed_V1_Digest.Element.EmojiProperty, font: UIFont) -> NSAttributedString {
        if let imageAttri = getEmojiAttri(emojiKey: emojiProperty.emojiKey, font: font) {
            return imageAttri
        }
        FeedPluginTracker.log.error("feedlog/feedcard/render/emoji. \(feedPreview.id), \(emojiProperty.emojiKey)")
        return NSAttributedString(string: emojiProperty.defaultContent)
    }

    private func getTextWithEmojistAttri(text: String, font: UIFont) -> NSAttributedString {
        let matchs = getMatchs(text: text)
        guard !matchs.isEmpty else { return NSAttributedString(string: text) }
        let attributedString = NSMutableAttributedString(string: text)
        let attributedStringLength = attributedString.length
        let textCount = text.utf16.count
        matchs.forEach { item in
            let itemRange = item.range
            guard let emojiKey = getEmojiKey(text: text, itemRange: itemRange, textCount: textCount, attributedStringLength: attributedStringLength), !emojiKey.isEmpty  else { return }
            guard let emojiAttri = getEmojiAttri(emojiKey: emojiKey, font: font) else { return }
            attributedString.replaceCharacters(in: itemRange, with: emojiAttri)
        }
        return attributedString
    }
}

// MARK: - 解析Emoji的基础能力接口
extension FeedDigestInfoHelper {
    private func getMatchs(text: String) -> [NSTextCheckingResult] {
        guard !text.isEmpty, let regExp = Self.emojiRegExp else { return [] }
        let textCount = text.utf16.count
        let textRange = NSRange(location: 0, length: textCount)
        var matchs = regExp.matches(in: text, options: [], range: textRange)
        guard !matchs.isEmpty else { return [] }
        matchs.reverse()
        return matchs
    }

    private func getEmojiKey(text: String, itemRange: NSRange, textCount: Int, attributedStringLength: Int) -> String? {
        guard itemRange.location + itemRange.length <= attributedStringLength else { return nil }
        let keyRange = NSRange(location: itemRange.location + 1, length: itemRange.length - 2)
        guard keyRange.location + keyRange.length <= textCount else { return nil }
        let emojiName = (text as NSString).substring(with: keyRange)
        guard let emojiKey = EmotionResouce.shared.emotionKeyBy(i18n: emojiName) else { return nil }
        return emojiKey
    }

    private func getEmoji(emojiKey: String) -> UIImage? {
        guard !emojiKey.isEmpty  else { return nil }
        guard let emoji = EmotionResouce.shared.imageBy(key: emojiKey) else {
                  return nil
              }
        return emoji
    }

    private func getEmojiAttri(emojiKey: String, font: UIFont) -> NSAttributedString? {
        guard let image = getEmoji(emojiKey: emojiKey) else {
            // 企业自定义表情上线后需要再判断下这个表情是否被服务端标记为“违规”
            if EmotionResouce.shared.isDeletedBy(key: emojiKey) {
                // 如果表情违规的话不能显示：[文案]，需要显示违规提示：[表情已违规]
                let illegaText = EmotionResouce.shared.getIllegaDisplayText()
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
        let imageHeight = font.rowHeight - 2.auto()
        let imageY: CGFloat = (font.capHeight - imageHeight) / 2
        let radio = imageSizeWidth / imageSizeHeight
        let imageWidth = imageHeight * radio
        attachment.bounds = CGRect(x: imageX, y: imageY, width: imageWidth, height: imageHeight)
        let imageAttri = NSAttributedString(attachment: attachment)
        return imageAttri
    }

    private static var emojiRegExp: NSRegularExpression? = {
        let regex = "\\[[^\\[\\]]+\\]"
        guard let regExp = try? NSRegularExpression(pattern: regex, options: [.caseInsensitive]) else {
            return nil
        }
        return regExp
    }()
}
