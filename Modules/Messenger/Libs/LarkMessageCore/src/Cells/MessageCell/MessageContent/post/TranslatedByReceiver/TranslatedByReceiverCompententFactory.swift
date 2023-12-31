//
//  TranslatedByReceiverCompententFactory.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/2/17.
//

import Foundation
import LarkMessageBase

public final class TranslatedByReceiverCompententFactory<C: PageContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .autoTranslatedByReceiver
    }

    public override var canCreateBinder: Bool {
        return true
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        let message = metaModel.message
        let isFromMe = context.isMe(message.fromId, chat: metaModel.getChat())
        return isFromMe && message.translateState == .origin && message.isAutoTranslatedByReceiver
    }

    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return TranslatedByReceiverCompententBinder(translatedViewModel: TranslatedByReceiverCompententViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context
        ))
    }
}
