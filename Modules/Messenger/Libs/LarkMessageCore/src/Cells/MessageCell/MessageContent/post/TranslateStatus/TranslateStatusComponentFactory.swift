//
//  TranslateStatusComponentFactory.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/2/17.
//

import Foundation
import LarkStorage
import LarkSearchCore
import LarkMessageBase

public final class TranslateStatusComponentFactory<C: PageContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .translateStatus
    }

    public override var canCreateBinder: Bool {
        return true
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        let message = metaModel.message
        let isFromMe = context.isMe(message.fromId, chat: metaModel.getChat())
        let canShowTranslateIcon = LarkMessageCore.canShowTranslateIcon(message: message, chat: metaModel.getChat(), isFromMe: isFromMe)
        return (message.translateState == .origin && canShowTranslateIcon) || (message.translateState == .translating)
    }

    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return TranslateStatusComponentBinder(translateStatusViewModel: TranslateStatusComponentViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context
        ))
    }
}
