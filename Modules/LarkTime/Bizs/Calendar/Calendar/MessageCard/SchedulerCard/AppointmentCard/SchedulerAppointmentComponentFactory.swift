//
//  SchedulerAppointmentComponentFactory.swift
//  Calendar
//
//  Created by tuwenbo on 2023/3/29.
//

import Foundation
import LarkMessageBase
import LarkModel
import AsyncComponent
import UniverseDesignColor

extension PageContext: SchedulerAppointmentViewModelContext {}

final class SchedulerAppointmentComponentFactory<C: SchedulerAppointmentViewModelContext>: MessageSubFactory<C> {
    override class var subType: SubType {
        return .content
    }

    override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is SchedulerAppointmentCardContent
    }

    override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return SchedulerAppointmentViewModel(metaModel: metaModel,
                                             metaModelDependency: metaModelDependency,
                                             context: context,
                                             binder: SchedulerAppointmentComponentBinder<M, D, C>(context: context))
    }
}

final class ThreadSchedulerAppointmentComponentFactory<C: SchedulerAppointmentViewModelContext>: MessageSubFactory<C> {
    override class var subType: SubType {
        return .content
    }

    override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is SchedulerAppointmentCardContent
    }

    override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        let binder = SchedulerAppointmentComponentBinder<M, D, C>(
            context: context,
            borderGetter: { Border(BorderEdge(width: 1, color: EventCardStyle.borderColor, style: .solid)) },
            cornerRadiusGetter: { 10 })
        return SchedulerAppointmentViewModel(metaModel: metaModel,
                                             metaModelDependency: metaModelDependency,
                                             context: context,
                                             binder: binder)
    }
}

final class DetailSchedulerAppointmentComponentFactory<C: SchedulerAppointmentViewModelContext>: MessageSubFactory<C> {
    override class var subType: SubType {
        return .content
    }

    override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is SchedulerAppointmentCardContent
    }

    override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        let binder = SchedulerAppointmentComponentBinder<M, D, C>(
            context: context,
            borderGetter: { Border(BorderEdge(width: 1, color: EventCardStyle.borderColor, style: .solid)) },
            cornerRadiusGetter: { 10 })
        return SchedulerAppointmentViewModel(metaModel: metaModel,
                                             metaModelDependency: metaModelDependency,
                                             context: context,
                                             binder: binder)
    }
}
