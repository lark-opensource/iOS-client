//
//  MergeForwardContent+Extensions.swift
//  LarkChat
//
//  Created by chengzhipeng-bytedance on 2018/6/20.
//

import Foundation
import UIKit
import LarkModel
import LarkFoundation
import LarkExtensions
import TangramService
import RichLabel
import RustPB
import UniverseDesignColor
import UniverseDesignTheme
import LarkContainer

public extension MergeForwardContent {
    var title: String {
        switch self.chatType {
        case .group, .topicGroup:
            return BundleI18n.LarkCore.Lark_Legacy_GroupChatHistory
        case .p2P:
            if self.p2PPartnerName.isEmpty {
                return String(format: BundleI18n.LarkCore.Lark_Legacy_MergeforwardTitleOneside, self.p2PCreatorName)
            } else {
                return String(format: BundleI18n.LarkCore.Lark_Legacy_MergeforwardTitleTwoside, self.p2PCreatorName, self.p2PPartnerName)
            }
        @unknown default:
            assert(false, "new value")
            return BundleI18n.LarkCore.Lark_Legacy_GroupChatHistory
        }
    }

    /// 会涉及到解析纯文本消息的 richText, 所以最好别每次直接使用此属性, 建议业务方使用存储属性保存.
    /// needHandleTranslation：是否需要判断译文，iPad等场景不显示出译文信息
    func getContentText(
        userResolver: UserResolver,
        font: UIFont = UIFont.ud.body2,
        fontColor: UIColor = UIColor.ud.N600,
        needHandleTranslation: Bool = true
    ) -> NSAttributedString {
        let iconColor = UIColor.ud.N600
        let defautAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: fontColor,
            MessageInlineViewModel.iconColorKey: iconColor,
            MessageInlineViewModel.tagTypeKey: TagType.normal
        ]

        var attributeTexts: [NSMutableAttributedString] = []

        /// 提高性能, 只处理前4条
        self.messages = self.messages.enumerated().map { (index: Int, message: Message) -> Message in

            guard let userName = self.chatters[message.fromId]?.name, index < 4 else {
                return message
            }

            var contentStr = NSMutableAttributedString(string: "")

            switch message.type {
            case .text:
                var content: TextContent?
                if !needHandleTranslation || message.displayRule == .noTranslation || message.displayRule == .unknownRule {
                    content = message.content as? TextContent
                } else {
                    content = message.translateContent as? TextContent
                }
                if var content = content {
                    let textDocsVM = TextDocsViewModel(userResolver: userResolver, richText: content.richText, docEntity: content.docEntity, hangPoint: message.urlPreviewHangPointMap)
                    let parseResult = textDocsVM.parseRichText(
                        isShowReadStatus: false,
                        checkIsMe: { _ in false },
                        maxLines: 1,
                        needNewLine: false,
                        iconColor: iconColor,
                        customAttributes: defautAttributes,
                        urlPreviewProvider: { elementID, customAttributes in
                            let inlinePreviewVM = MessageInlineViewModel()
                            return inlinePreviewVM.getSummerizeAttrAndURL(elementID: elementID, message: message, customAttributes: customAttributes)
                        }
                    )
                    // 覆盖richText，适配copy场景
                    content.richText = textDocsVM.richText
                    contentStr = NSMutableAttributedString(attributedString: parseResult.attriubuteText)
                }
                // 如果有译文，前面需要加上[译]
                if needHandleTranslation && (message.displayRule == .onlyTranslation || message.displayRule == .withOriginal) {
                    contentStr.insert(NSAttributedString(string: BundleI18n.LarkCore.Lark_Legacy_TranslateInChat, attributes: defautAttributes), at: 0)
                }
            case .post:
                var content: PostContent?
                if !needHandleTranslation || message.displayRule == .noTranslation || message.displayRule == .unknownRule {
                    content = message.content as? PostContent
                } else {
                    content = message.translateContent as? PostContent
                }
                if let content = content {
                    // 无标题帖子展示内容
                    if content.isUntitledPost {
                        let fixRichText = content.richText.lc.convertText(tags: [.img, .media])
                        let textDocsVM = TextDocsViewModel(userResolver: userResolver, richText: fixRichText, docEntity: content.docEntity, hangPoint: message.urlPreviewHangPointMap)
                        let parseResult = textDocsVM.parseRichText(
                            isShowReadStatus: false,
                            checkIsMe: { _ in false },
                            maxLines: 1,
                            needNewLine: false,
                            iconColor: iconColor,
                            customAttributes: defautAttributes,
                            urlPreviewProvider: { elementID, customAttributes in
                                let inlinePreviewVM = MessageInlineViewModel()
                                return inlinePreviewVM.getSummerizeAttrAndURL(elementID: elementID, message: message, customAttributes: customAttributes)
                            }
                        )
                        contentStr = NSMutableAttributedString(attributedString: parseResult.attriubuteText)
                    } else {
                        contentStr = NSMutableAttributedString(string: content.title, attributes: defautAttributes)
                    }
                }
                // 如果有译文，前面需要加上[译]
                if needHandleTranslation && (message.displayRule == .onlyTranslation || message.displayRule == .withOriginal) {
                    contentStr.insert(NSAttributedString(string: BundleI18n.LarkCore.Lark_Legacy_TranslateInChat, attributes: defautAttributes), at: 0)
                }
            case .image:
                contentStr = NSMutableAttributedString(string: BundleI18n.LarkCore.Lark_Legacy_ImageSummarize, attributes: defautAttributes)
            case .location:
                if let content = message.content as? LocationContent {
                    contentStr = NSMutableAttributedString(string: BundleI18n.LarkCore.Lark_Chat_MessageReplyStatusLocation(content.location.name), attributes: defautAttributes)
                }
            case .sticker:
                //如果是商店表情,则优先展示商店表情的描述
                let stickerContent = message.content as? StickerContent
                if let sticker = stickerContent?.transformToSticker(), sticker.mode == .meme, !sticker.description_p.isEmpty {
                    contentStr = NSMutableAttributedString(string: "[" + sticker.description_p + "]", attributes: defautAttributes)
                    break
                }
                contentStr = NSMutableAttributedString(string: BundleI18n.LarkCore.Lark_Legacy_StickerHolder, attributes: defautAttributes)
            case .file, .folder:
                contentStr = NSMutableAttributedString(string: BundleI18n.LarkCore.Lark_Legacy_FileHolder, attributes: defautAttributes)
            case .shareUserCard:
                let content = message.content as? ShareUserCardContent
                contentStr = NSMutableAttributedString(string: BundleI18n.LarkCore.Lark_Legacy_PreviewUserCard(content?.chatter?.localizedName ?? ""), attributes: defautAttributes)
            case .shareGroupChat:
                contentStr = NSMutableAttributedString(string: BundleI18n.LarkCore.Lark_Legacy_SharegroupSummarize, attributes: defautAttributes)
            case .mergeForward:
                if let content = message.content as? MergeForwardContent {
                    contentStr = NSMutableAttributedString(string: BundleI18n.LarkCore.Lark_Legacy_MessagePoCard + content.title, attributes: defautAttributes)
                } else {
                    contentStr = NSMutableAttributedString(string: BundleI18n.LarkCore.Lark_Legacy_MessagePoMergeforward, attributes: defautAttributes)
                }
                // 如果有译文，前面需要加上[译]
                if needHandleTranslation && (message.displayRule == .onlyTranslation || message.displayRule == .withOriginal) {
                    contentStr.insert(NSAttributedString(string: BundleI18n.LarkCore.Lark_Legacy_TranslateInChat, attributes: defautAttributes), at: 0)
                }
            case .email, .calendar, .generalCalendar, .unknown, .system, .card, .shareCalendarEvent, .videoChat:
                contentStr = NSMutableAttributedString(string: BundleI18n.LarkCore.Lark_Legacy_UnknownMessageTypeTip(), attributes: defautAttributes)
            case .media:
                contentStr = NSMutableAttributedString(string: BundleI18n.LarkCore.Lark_Legacy_VideoSummarize, attributes: defautAttributes)
            case .audio:
                contentStr = NSMutableAttributedString(string: BundleI18n.LarkCore.Lark_Legacy_AudioHolder, attributes: defautAttributes)
            case .hongbao, .commercializedHongbao:
                contentStr = NSMutableAttributedString(string: BundleI18n.LarkCore.Lark_Legacy_AudioRedPacket, attributes: defautAttributes)
            case .todo:
                // TODO: todo 适配
                assertionFailure("new value")
                contentStr = NSMutableAttributedString(string: "")
            case .diagnose, .vote:
                assertionFailure("new value") // FIXME: use unknown default setting to fix warning
            @unknown default:
                assertionFailure("new value")
                break
            }

            let userNameStr = NSMutableAttributedString(string: userName + ": ", attributes: defautAttributes)
            let newLine = NSMutableAttributedString(string: "\n", attributes: defautAttributes)

            attributeTexts.append(userNameStr)
            attributeTexts.append(contentStr)
            attributeTexts.append(newLine)
            return message
        }

        let attr = attributeTexts.reduce(NSMutableAttributedString(string: ""), +).lf.trimmedAttributedString(
            set: .whitespacesAndNewlines,
            position: .trail
        )
        return NSMutableAttributedString(attributedString: attr)
    }
}
