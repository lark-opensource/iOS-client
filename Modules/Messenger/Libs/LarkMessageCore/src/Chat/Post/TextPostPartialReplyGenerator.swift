//
//  TextPostpartialReplyGenerator.swift
//  LarkMessageCore
//
//  Created by liluobin on 2023/10/6.
//

import UIKit
import LarkModel
import RustPB
import LarkRichTextCore
import RichLabel
import UniverseDesignIcon
import LarkCore
import LarkChatOpenKeyboard
import LarkMessageBase
import TangramService
import LarkContainer
import LarkMessengerInterface

public class TextPostPartialReplyGenerator {

    public static func partialReplyForPosition(_ position: Basic_V1_Message.PartialReplyInfo.PartialContentRelativePosition,
                                               headInsertIdx: Int?,
                                               muAttr: NSMutableAttributedString,
                                               textAttribute: [NSAttributedString.Key: Any]?) -> NSMutableAttributedString {
        /// 为空
        guard muAttr.length > 0 else {
            return muAttr
        }
        /// 越界
        if let headIdx = headInsertIdx, headIdx >= muAttr.length {
            return muAttr
        }

        switch position {
        case .tail:
            muAttr.insert(NSAttributedString(string: "\u{2026}",
                                             attributes: textAttribute), at: headInsertIdx ?? 0)
        case .middle:
            muAttr.insert(NSAttributedString(string: "\u{2026}",
                                             attributes: textAttribute), at: headInsertIdx ?? 0)
            muAttr.append(NSAttributedString(string: "\u{2026}",
                                             attributes: textAttribute))
        case .head:
            muAttr.append(NSAttributedString(string: "\u{2026}",
                                             attributes: textAttribute))
        case .unknown:
            break
        @unknown default:
            break
        }
        return muAttr
    }

    public static func insertLinkDefalutIconIfNeedFor(attr: NSAttributedString,
                                                      font: UIFont,
                                                      color: UIColor = UIColor.ud.iconN3) -> NSMutableAttributedString {
        let muAttr = NSMutableAttributedString(attributedString: attr)
        /// 倒序遍历
        muAttr.enumerateAttribute(LarkRichTextCoreUtils.anchorKey,
                                  in: NSRange(location: 0, length: attr.length),
                                  options: [.reverse, .longestEffectiveRangeNotRequired]) { value, range, _ in
            if let value = value as? RustPB.Basic_V1_RichTextElement.AnchorProperty,
               !value.isCustom {
                let content = value.href
                var shouldInsertIcon = false
                if !value.textContent.isEmpty {
                    shouldInsertIcon = value.textContent != content
                }
                if !shouldInsertIcon, !value.content.isEmpty {
                    shouldInsertIcon = value.content != content
                }
                if shouldInsertIcon {
                    let iconAttachment = LKAsyncAttachment(
                        viewProvider: {
                            let imageView = UIImageView()
                            imageView.image = UDIcon.globalLinkOutlined.ud.withTintColor(color)
                            return imageView
                        },
                        size: CGSize(width: font.lineHeight * 0.8, height: font.lineHeight * 0.8)
                    )
                    iconAttachment.fontDescent = font.descender
                    iconAttachment.fontAscent = font.ascender
                    iconAttachment.margin.right = 1
                    iconAttachment.margin.left = 1
                    muAttr.insert(
                        NSAttributedString(
                            string: LKLabelAttachmentPlaceHolderStr,
                            attributes: [LKAttachmentAttributeName: iconAttachment]
                        ),
                        at: range.location)
                }
            }
        }
        return muAttr
    }

}

public class MessageReplyGenerator {

    public static func attributeReplyForInfo(_ info: KeyboardJob.ReplyInfo,
                                                font: UIFont,
                                                displayName: String,
                                                chat: Chat,
                                                userResolver: UserResolver,
                                                abTestService: MenuInteractionABTestService?,
                                                modelService: ModelService?,
                                                messageBurntService: MessageBurnService?) -> NSMutableAttributedString {
        let message = info.message
        let iconColor = UIColor.ud.iconN3
        let paragraphStyle = NSMutableParagraphStyle()
        /// 这里只展示一行，尽可能多的展示内容
        // swiftlint:disable ban_linebreak_byChar
        paragraphStyle.lineBreakMode = .byCharWrapping
        // swiftlint:enable ban_linebreak_byChar
        let fontColor = UIColor.ud.textPlaceholder
        let textAttribute: [NSAttributedString.Key: Any] = [
            .foregroundColor: fontColor,
            .font: font,
            .paragraphStyle: paragraphStyle,
            MessageInlineViewModel.iconColorKey: iconColor,
            MessageInlineViewModel.tagTypeKey: TagType.normal
        ]

        /// 消息只显示译文时，展示译文，其他情况展示原文
        var mutableAttributedString: NSMutableAttributedString
        /// 添加“回复 ”文案
        let replyDisplayName: String
        if let abTestService, abTestService.hitABTest(chat: chat) {
            replyDisplayName = displayName
        } else {
            /// 没有命中实验 走原有的逻辑
            replyDisplayName = BundleI18n.LarkMessageCore.Lark_Legacy_ReplySomebody(displayName)
        }

        if message.displayRule == .onlyTranslation, message.translateContent != nil {
            mutableAttributedString = NSMutableAttributedString(string: "\(replyDisplayName): [\(BundleI18n.LarkMessageCore.Lark_Legacy_ChatInputviewTranslate)]", attributes: textAttribute)
        } else {
            mutableAttributedString = NSMutableAttributedString(string: "\(replyDisplayName): ", attributes: textAttribute)
        }
        let headInsertIdx = mutableAttributedString.length
        /// 特殊场景处理 保持一致
        var messageSummerize: NSMutableAttributedString = NSMutableAttributedString(string: "")
        func parseInvalidMessage(_ text: String) -> NSMutableAttributedString {
            messageSummerize = NSMutableAttributedString(string: text)
            messageSummerize.addAttributes(textAttribute, range: NSRange(location: 0, length: messageSummerize.length))
            mutableAttributedString.append(messageSummerize)
            return mutableAttributedString
        }
        if message.isDeleted {
            return parseInvalidMessage(BundleI18n.LarkMessageCore.Lark_Legacy_MessageRemove)

        }
        if message.isRecalled {
            return parseInvalidMessage(BundleI18n.LarkMessageCore.Lark_Legacy_MessageWithdrawMessage)
        }

        if messageBurntService?.isBurned(message: message) == true {
            return parseInvalidMessage(message.isOnTimeDel ? BundleI18n.LarkMessageCore.Lark_IM_MsgDeleted_Desc : BundleI18n.LarkMessageCore.Lark_Legacy_MessageBurned)
        }

        /// 获取docs预览内容 消息只显示译文时，展示译文，其他情况展示原文
        var fixContent = message.content
        if message.displayRule == .onlyTranslation, let translateContent = message.translateContent {
            fixContent = translateContent
        }
        /// docs text消息需要单独判断
        if message.type == .text {
            let parseText: (TextContent?) -> Void = { textContent in
                if let textContent = textContent {
                    let textDocsVM = TextDocsViewModel(userResolver: userResolver,
                                                       richText: info.partialReplyInfo?.content ?? textContent.richText,
                                                       docEntity: textContent.docEntity,
                                                       hangPoint: message.urlPreviewHangPointMap)
                    let parseRichText = textDocsVM.parseRichText(
                        checkIsMe: nil,
                        needNewLine: false,
                        iconColor: iconColor,
                        customAttributes: textAttribute,
                        urlPreviewProvider: { elementID, _ in
                            let inlinePreviewVM = MessageInlineViewModel()
                            return inlinePreviewVM.getSummerizeAttrAndURL(elementID: elementID, message: message, customAttributes: textAttribute)
                        }
                    )
                    messageSummerize = parseRichText.attriubuteText
                    messageSummerize.addAttributes(textAttribute, range: NSRange(location: 0, length: messageSummerize.length))
                }
            }
            let textContent = fixContent as? TextContent
            parseText(textContent)
        } else if let postContent = fixContent as? PostContent {
            /// docs post消息需要单独判断
            if postContent.isUntitledPost || info.partialReplyInfo != nil {
                let fixRichText = (info.partialReplyInfo?.content ?? postContent.richText).lc.convertText(tags: [.img, .media])
                let textDocsVM = TextDocsViewModel(userResolver: userResolver, richText: fixRichText, docEntity: postContent.docEntity, hangPoint: message.urlPreviewHangPointMap)
                let parseRichText = textDocsVM.parseRichText(
                    checkIsMe: nil,
                    needNewLine: false,
                    iconColor: iconColor,
                    customAttributes: textAttribute,
                    urlPreviewProvider: { elementID, _ in
                        let inlinePreviewVM = MessageInlineViewModel()
                        return inlinePreviewVM.getSummerizeAttrAndURL(elementID: elementID, message: message, customAttributes: textAttribute)
                    }
                )
                messageSummerize = parseRichText.attriubuteText
                messageSummerize.addAttributes(textAttribute, range: NSRange(location: 0, length: messageSummerize.length))
            } else {
                messageSummerize = NSMutableAttributedString(string: postContent.title)
                messageSummerize.addAttributes(textAttribute, range: NSRange(location: 0, length: messageSummerize.length))
            }
        } else {
            /// 其他情况按照原来的逻辑来处理，用modelService去描述
            let newMessage = message.copy()
            newMessage.content = fixContent
            if let modelService {
                messageSummerize = NSMutableAttributedString(string: modelService.messageSummerize(newMessage))
                messageSummerize.addAttributes(textAttribute, range: NSRange(location: 0, length: messageSummerize.length))
            }
        }
        mutableAttributedString.append(messageSummerize)
        if let partialReplyInfo = info.partialReplyInfo, mutableAttributedString.length > 0 {
            mutableAttributedString = TextPostPartialReplyGenerator.insertLinkDefalutIconIfNeedFor(attr: mutableAttributedString,
                                                                                                   font: font,
                                                                                                   color: fontColor)
            mutableAttributedString = TextPostPartialReplyGenerator.partialReplyForPosition(partialReplyInfo.position,
                                                                                            headInsertIdx: headInsertIdx,
                                                                                            muAttr: mutableAttributedString,
                                                                                            textAttribute: textAttribute)
        }
        return mutableAttributedString
    }
}
