//
//  File.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/8/15.
//

import UIKit
import Foundation
import LarkUIKit
import LarkModel
import RichLabel
import RxSwift
import LarkSetting
import EENavigator
import LarkMessageBase
import LarkContainer
import LarkSDKInterface
import LarkCore
import ByteWebImage
import LarkMessengerInterface
import UniverseDesignColor
import UniverseDesignCardHeader
import LarkAlertController
import LKCommonsLogging

public class SyncToChatComponentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: ReplyViewModelContext>: ReplyComponentViewModel<M, D, C> {

    private var textFont = UIFont.ud.body2
    override var parentMessage: Message? {
        return message.syncToChatThreadRootMessage
    }

    override func setupAttributedText() {
        guard let rootMessage = message.syncToChatThreadRootMessage,
              let fromChatter = rootMessage.fromChatter else { return }
        let chat = metaModel.getChat()
        let chatterDisplayName = context.getDisplayName(chatter: fromChatter, chat: chat, scene: .reply)
        attributedText = NSMutableAttributedString(string: BundleI18n.LarkMessageCore.Lark_IM_Thread_UsernameThreadCard_Title(chatterDisplayName),
                                                       attributes: [.foregroundColor: UIColor.ud.textCaption, .font: UIFont.ud.body2])

        /// 回复的提示
        let (leftText, rightText) = Self.splitI18NText { BundleI18n.LarkMessageCore.Lark_Legacy_ReplySomebody($0) }
        // 左侧提示
        if !leftText.isEmpty { attributedText.insert(.init(string: leftText, attributes: [.font: UIFont.ud.body2, .foregroundColor: UIColor.ud.textCaption]), at: 0) }
        // 右侧提示
        if !rightText.isEmpty { attributedText.append(.init(string: rightText, attributes: [.font: UIFont.ud.body2, .foregroundColor: UIColor.ud.textCaption])) }

        attributedText.append(.init(string: ": ", attributes: [.font: UIFont.ud.body2, .foregroundColor: UIColor.ud.textCaption]))

        let messageSummerizeText = NSMutableAttributedString(attributedString: context.getSyncToChatMessageSummerize(message: rootMessage,
                                                                                                                     chat: metaModel.getChat(),
                                                                                                                     textColor: .ud.textCaption))
        messageSummerizeText.mutableString.replaceOccurrences(
            of: "\n",
            with: " ",
            options: [],
            range: NSRange(location: 0, length: messageSummerizeText.length)
        )
        messageSummerizeText.addAttributes(
            [.font: font],
            range: NSRange(location: 0, length: messageSummerizeText.length)
        )
        attributedText.append(messageSummerizeText)
        if rootMessage.isMultiEdited {
            attributedText.append(.init(string: BundleI18n.LarkMessageCore.Lark_IM_EditMessage_Edited_Label,
                                        attributes: [.font: UIFont.systemFont(ofSize: 12),
                                                     .foregroundColor: UIColor.ud.textCaption]))
        }

        /// 分割线
        let width: CGFloat = 2
        let lineAttachment = LKAsyncAttachment(
            viewProvider: { [weak self] in
                guard let self = self else { return UIView() }
                let lineView = UIView()
                lineView.layer.cornerRadius = width / 2.0
                lineView.backgroundColor = self.lineColor
                return lineView
            },
            size: CGSize(width: width, height: UIFont.ud.body2.pointSize)
        )
        lineAttachment.fontDescent = font.descender
        lineAttachment.fontAscent = font.ascender
        lineAttachment.margin.right = 4
        attributedText.insert(
            NSAttributedString(
                string: LKLabelAttachmentPlaceHolderStr,
                attributes: [LKAttachmentAttributeName: lineAttachment]
            ),
            at: 0)

        /// 末尾截断的省略号「...」
        outOfRangeText = NSAttributedString(
            string: "\u{2026}",
            attributes: [.font: font, .foregroundColor: textColor]
        )
    }

    // Splite I18N 插值有可能在文案的中间
    // eg. 日语可能存在效果： グループ「xxxxx」に返信
    // 需要拆分文案
    private static func splitI18NText(_ i18nFunc: (String) -> String) -> (String, String) {
        let splitString = "@#$%&"
        let components = i18nFunc(splitString).components(separatedBy: splitString)
        if components.count >= 2 {
            return (components[0], components[1])
        } else if components.count >= 1 {
            return (components[0], "")
        } else {
            return ("", "")
        }
    }
}

extension PageContext: SyncToChatContext {
    // 获取Summerize，用LarkChat - MessageViewModel已有方法
    public func getSyncToChatMessageSummerize(message: Message, chat: Chat, textColor: UIColor) -> NSAttributedString {
        return MessageViewModelHandler.getReplyMessageSummerize(
            message,
            chat: chat,
            textColor: textColor,
            nameProvider: getDisplayName,
            needFromName: false,
            isBurned: isBurned(message: message),
            userResolver: self.userResolver,
            urlPreviewProvider: { elementID, customAttributes in
                let inlinePreviewVM = MessageInlineViewModel()
                return inlinePreviewVM.getSummerizeAttrAndURL(elementID: elementID, message: message, customAttributes: customAttributes)
            }
        )
    }
}
