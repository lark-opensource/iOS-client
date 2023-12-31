//
//  PinCardComponentFactory.swift
//  LarkChat
//
//  Created by 白言韬 on 2020/12/14.
//

import Foundation
import LarkModel
import LarkMessageBase

public final class PinCardComponentFactory<C: PinCardViewModelContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .content
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is TodoContent
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(
        with metaModel: M,
        metaModelDependency: D
    ) -> MessageSubViewModel<M, D, C> {
        return PinCardViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: PinCardComponentBinder<M, D, C>(context: context)
        )
    }
}
