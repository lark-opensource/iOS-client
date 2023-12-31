//
//  PinAppointmentComponentFactory.swift
//  LarkChat
//
//  Created by tuwenbo on 2023/4/10.
//

import Foundation
import LarkModel
import LarkMessageBase

final public class PinAppointmentComponentFactory<C: PinAppointmentViewModelContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .content
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is SchedulerAppointmentCardContent
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return PinAppointmentViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: PinAppointmentComponentBinder<M, D, C>(context: context))
    }
}
