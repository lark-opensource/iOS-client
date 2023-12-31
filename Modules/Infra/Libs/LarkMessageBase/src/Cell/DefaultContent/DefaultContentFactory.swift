//
//  DefaultContentFactory.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/1/29.
//

import Foundation

open class DefaultContentFactory<C: PageContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .content
    }

    open override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return true
    }

    open override func create<M: CellMetaModel, D: CellMetaModelDependency>(
        with metaModel: M,
        metaModelDependency: D
    ) -> MessageSubViewModel<M, D, C> {
        return DefaultContentViewModel(metaModel: metaModel,
                                       metaModelDependency: metaModelDependency,
                                       context: context,
                                       binder: DefaultContentCompoenntBinder<C>(context: context))
    }
}
