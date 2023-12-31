//
//  CryptoReactionComponentFactory.swift
//  LarkMessageCore
//
//  Created by ByteDance on 2022/11/21.
//

import Foundation
import LarkModel
import LarkMessengerInterface
import LarkMessageBase
import LarkAccountInterface
import LarkSDKInterface

public final class CryptoReactionComponentFactory<C: PageContext>: ReactionComponentFactory<C> {
    public override var canCreateBinder: Bool {
        return true
    }

    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return ReactionComponentBinder(
            reactonViewModel: CryptoReactionViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            reactionActionHandler: ReactionActionHandler(context: context)
        )
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        let message = metaModel.message
        if context.isBurned(message: message) {
            return false
        }
        return super.canCreate(with: metaModel)
    }
}
