//
//  RevealReplyInTreadComponentFactory.swift
//  LarkMessageCore
//
//  Created by ByteDance on 2022/9/30.
//

import UIKit
import Foundation
import LarkModel
import LarkMessageBase
import LarkSDKInterface
import LarkMessengerInterface
import LarkCore
import LKCommonsLogging

public protocol RevealReplyInTreadContext: RevealReplyInTreadComponentContext & RevealReplyInTreadViewModelContext { }

public final class RevealReplyInTreadComponentFactory<C: RevealReplyInTreadContext>: MessageSubFactory<C> {
    private var logger = Logger.log(RevealReplyInTreadComponentFactory.self, category: "LarkMessage.ReplyComponentFactory")
    public override class var subType: SubType {
        return .revealReplyInTread
    }

    public override var canCreateBinder: Bool {
        return true
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.showInThreadModeStyle
    }

    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return RevealReplyInTreadComponentBinder(
            replyInThreadViewModel: RevealReplyInTreadComponentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            replyInThreadActionHandler: RevealReplyInThreadComponentActionHandler(context: context)
        )
    }
}

extension PageContext: RevealReplyInTreadContext {
    public func getRevealReplyInTreadSummerize(message: Message, chat: Chat, textColor: UIColor) -> NSAttributedString {
        switch message.type {
        case .image:
            return NSAttributedString(string: BundleI18n.LarkMessageCore.Lark_Legacy_ImageSummarize)
        case .sticker:
            //如果是表情包表情,则直接返回表情包描述
            var result: String = ""
            let stickerContent = message.content as? StickerContent
            let sticker = stickerContent?.transformToSticker()
            if sticker?.mode == .meme, let desc = sticker?.description_p, !desc.isEmpty {
                result = "[" + desc + "]"
            }
            result = BundleI18n.LarkMessageCore.Lark_Legacy_StickerHolder
            return NSAttributedString(string: result)
        @unknown default:
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
}
