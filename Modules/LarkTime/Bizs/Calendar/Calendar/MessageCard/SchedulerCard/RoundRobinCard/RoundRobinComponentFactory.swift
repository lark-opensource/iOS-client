//
//  RoundRobinComponentFactory.swift
//  Calendar
//
//  Created by tuwenbo on 2023/3/28.
//

import Foundation
import LarkMessageBase
import LarkModel
import AsyncComponent
import UniverseDesignColor

extension PageContext: RoundRobinCardViewModelContext { }

final class RoundRobinCardComponentFactory<C: RoundRobinCardViewModelContext>: MessageSubFactory<C> {
    override class var subType: SubType {
        return .content
    }

    override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is RoundRobinCardContent
    }

    override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return RoundRobinCardViewModel(metaModel: metaModel,
                                       metaModelDependency: metaModelDependency,
                                       context: context,
                                       binder: RoundRobinCardComponentBinder<M, D, C>(context: context))
    }
}


final class ThreadRoundRobinCardComponentFactory<C: RoundRobinCardViewModelContext> : MessageSubFactory<C>  {
    override class var subType: SubType {
        return .content
    }

    override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is RoundRobinCardContent
    }

    override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        let binder = RoundRobinCardComponentBinder<M, D, C>(
            context: context,
            borderGetter: { Border(BorderEdge(width: 1, color: EventCardStyle.borderColor, style: .solid)) },
            cornerRadiusGetter: { 10 })
        return RoundRobinCardViewModel(metaModel: metaModel,
                                       metaModelDependency: metaModelDependency,
                                       context: context,
                                       binder: binder)
    }
}


final class DetailRoundRobinCardComponentFactory<C: RoundRobinCardViewModelContext> : MessageSubFactory<C>  {
    override class var subType: SubType {
        return .content
    }

    override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is RoundRobinCardContent
    }

    override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        let binder = RoundRobinCardComponentBinder<M, D, C>(
            context: context,
            borderGetter: { Border(BorderEdge(width: 1, color: EventCardStyle.borderColor, style: .solid)) },
            cornerRadiusGetter: { 10 })
        return RoundRobinCardViewModel(metaModel: metaModel,
                                       metaModelDependency: metaModelDependency,
                                       context: context,
                                       binder: binder)
    }
}
