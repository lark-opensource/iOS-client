//
//  CryptoTextReplyComponentFactory.swift
//  LarkMessageCore
//
//  Created by zc09v on 2021/9/26.
//

import Foundation
import LarkModel
import LarkMessageBase
import LarkSDKInterface
import LarkMessengerInterface
import LarkCore
import LKCommonsLogging

public protocol CryptoReplyContext: ReplyComponentContext & CryptoReplyViewModelContext { }

public final class CryptoTextReplyComponentFactory<C: CryptoReplyContext>: MessageSubFactory<C> {
    private var logger = Logger.log(CryptoTextReplyComponentFactory.self, category: "LarkMessage.CryptoTextReplyComponentFactory")
    public override class var subType: SubType {
        return .cryptoReply
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        //目前只做了文本消息
        if let parentMessage = metaModel.message.parentMessage, parentMessage.type == .text, !parentMessage.cryptoToken.isEmpty {
            let result = parentMessage.isVisible && parentMessage.position > metaModel.getChat().firstMessagePostion
            if result {
                self.logger.info("crypto trace use CryptoTextReplyComponentFactory \(metaModel.message.id) \(parentMessage.id) \(parentMessage.cryptoToken.isEmpty) \(parentMessage.type == .text)")
            }
            return result
        }
        return false
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return CryptoTextReplyComponentViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: CryptoTextReplyCompontentBinder<M, D, C>(context: context)
        )
    }
}

extension PageContext: CryptoReplyContext {
}
