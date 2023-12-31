//
//  PinRoundRobinComponentFactory.swift
//  LarkChat
//
//  Created by tuwenbo on 2023/4/5.
//

import Foundation
import LarkModel
import LarkMessageBase

final public class PinRoundRobinComponentFactory<C: PinRoundRobinViewModelContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .content
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is RoundRobinCardContent
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return PinRoundRobinViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: PinRoundRobinComponentBinder<M, D, C>(context: context))
    }
}
