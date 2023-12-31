//
//  LocationContentFactory.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/6/23.
//

import UIKit
import Foundation
import LarkModel
import LarkMessageBase
import RxSwift
import LarkSDKInterface

public protocol LocationContentContext: ViewModelContext {
    var scene: ContextScene { get }
    var userGeneralSettings: UserGeneralSettings? { get }
}

public class LocationContentFactory<C: LocationContentContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .content
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is LocationContent
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return LocationContentViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: LocationContentComponentBinder<M, D, C>(context: context)
        )
    }
}

public final class MessageDetailLocationContentFactory<C: LocationContentContext>: LocationContentFactory<C> {
    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return LocationContentViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: MessageDetailLocationContentComponentBinder<M, D, C>(context: context)
        )
    }
}

public final class PinLocationContentFactory<C: LocationContentContext>: LocationContentFactory<C> {
    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return LocationContentViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: PinLocationContentComponentBinder<M, D, C>(context: context)
        )
    }
}

extension PageContext: LocationContentContext {}
