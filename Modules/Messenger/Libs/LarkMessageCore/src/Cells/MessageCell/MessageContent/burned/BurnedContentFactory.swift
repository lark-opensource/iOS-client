//
//  BurnedContentFactory.swift
//  Action
//
//  Created by 赵冬 on 2019/8/10.
//

import Foundation
import LarkModel
import AsyncComponent
import LarkMessageBase

public protocol BurnedContentContext: ViewModelContext {
    var scene: ContextScene { get }
    func isBurned(message: Message) -> Bool
}

public final class BurnedContentFactory<C: BurnedContentContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .content
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return context.isBurned(message: metaModel.message)
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return BurnedContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context)
    }
}

extension PageContext: BurnedContentContext {}
