//
//  ReplyComponentFactory.swift
//  Action
//
//  Created by KT on 2019/5/29.
//

import UIKit
import Foundation
import LarkModel
import LarkMessageBase
import LarkSDKInterface
import LarkMessengerInterface
import LarkCore
import EEFlexiable
import LKCommonsLogging

public protocol ReplyContext: ReplyComponentContext & ReplyViewModelContext { }

public class ReplyComponentFactory<C: ReplyContext>: MessageSubFactory<C> {
    private var logger = Logger.log(ReplyComponentFactory.self, category: "LarkMessage.ReplyComponentFactory")
    public override class var subType: SubType {
        return .reply
    }

    public override var canCreateBinder: Bool {
        return true
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        if let parentMessage = metaModel.message.parentMessage, parentMessage.cryptoToken.isEmpty {
            let result = parentMessage.isDeleted || (parentMessage.isVisible && parentMessage.position > metaModel.getChat().firstMessagePostion)
            if result {
                self.logger.info("crypto trace use ReplyComponentFactory \(metaModel.message.id) \(parentMessage.id) \(parentMessage.cryptoToken.isEmpty)")
            }
            return result
        }
        return false
    }

    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        if context.scene == .mergeForwardDetail {
            return ReplyCompontentBinder(
                replyViewModel: ReplyComponentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
                replyActionHandler: MergeForwardDetailReplyComponentActionHandler(context: context)
            )
        }
        return ReplyCompontentBinder(
            replyViewModel: ReplyComponentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            replyActionHandler: ReplyComponentActionHandler(context: context)
        )
    }
}

public final class MessageLinkReplyComponentFactory<C: ReplyContext>: ReplyComponentFactory<C> {
    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        if let parentMessage = metaModel.message.parentMessage, parentMessage.cryptoToken.isEmpty {
            return parentMessage.isDeleted || parentMessage.isVisible
        }
        return false
    }

    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        // 消息链接场景的message不更新，可以在create时判断
        // 1: Reply左边竖线会被截断，暂时没查到原因，此处给个1的间距（本身padding应该是0）
        let padding = metaModel.message.showInThreadModeStyle ? ChatCellUIStaticVariable.bubblePadding : 1
        return ReplyCompontentBinder(
            replyViewModel: ReplyComponentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            replyActionHandler: nil,
            padding: CSSValue(cgfloat: padding)
        )
    }
}

extension PageContext: ReplyContext {
    // 获取回复Summerize，用LarkChat - MessageViewModel已有方法
    public func getReplyMessageSummerize(message: Message, chat: Chat, textColor: UIColor, partialReplyInfo: PartialReplyInfo?) -> NSAttributedString {
        return MessageViewModelHandler.getReplyMessageSummerize(
            message,
            chat: chat,
            textColor: textColor,
            nameProvider: getDisplayName,
            isBurned: isBurned(message: message),
            partialReplyInfo: partialReplyInfo,
            userResolver: self.userResolver,
            urlPreviewProvider: { elementID, customAttributes in
                let inlinePreviewVM = MessageInlineViewModel()
                return inlinePreviewVM.getSummerizeAttrAndURL(elementID: elementID, message: message, customAttributes: customAttributes)
            }
        )
    }

    public var userGeneralSettings: UserGeneralSettings? {
        return try? self.resolver.resolve(assert: UserGeneralSettings.self)
    }
}
