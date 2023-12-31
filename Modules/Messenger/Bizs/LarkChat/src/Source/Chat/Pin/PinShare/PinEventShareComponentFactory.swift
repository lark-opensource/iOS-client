//
//  PinEventShareComponentFactory.swift
//  LarkChat
//
//  Created by zc09v on 2019/9/24.
//

import Foundation
import LarkModel
import LarkMessageBase

final public class PinEventShareComponentFactory<C: PinEventShareViewModelContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .content
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is EventShareContent
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return PinEventShareViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: PinEventShareComponentBinder<M, D, C>(context: context))
    }
}
