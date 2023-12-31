//
//  FlagComponentFactory.swift
//  LarkMessageCore
//
//  Created by bytedance on 2022/6/2.
//

import Foundation
import LarkModel
import LarkMessageBase
import RxSwift
import LarkSDKInterface
import LarkMessengerInterface

open class FlagComponentFactory<C: PageContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .flag
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.isFlag
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return FlagComponentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context, binder: FlagComponentBinder<M, D, C>(context: context)
        )
    }
}
