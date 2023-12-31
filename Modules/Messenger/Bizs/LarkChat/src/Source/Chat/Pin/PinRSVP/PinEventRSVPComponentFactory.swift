//
//  PinEventRSVPComponentFactory.swift
//  LarkChat
//
//  Created by pluto on 2023/2/16.
//

import Foundation
import LarkModel
import LarkMessageBase

final public class PinEventRSVPComponentFactory<C: PinEventRSVPViewModelContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .content
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is GeneralCalendarEventRSVPContent
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return PinEventRSVPViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: PinEventRSVPComponentBinder<M, D, C>(context: context))
    }
}
