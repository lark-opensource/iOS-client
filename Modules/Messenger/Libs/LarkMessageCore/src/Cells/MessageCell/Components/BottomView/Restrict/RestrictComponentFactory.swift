//
//  RestrictComponentFactory.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/1/3.
//

import Foundation
import LarkModel
import LarkMessageBase
import LarkAccountInterface

public protocol RestrictComponentContext: RestrictComponentViewModelContext { }

extension PageContext: RestrictComponentContext { }

public final class RestrictComponentFactory<C: PageContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .restrict
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        let message = metaModel.message
        if message.isRecalled {
            return false
        }
        return metaModel.message.isRestricted
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return RestrictComponentViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: RestrictComponentBinder<M, D, C>(context: context)
        )
    }
}
