//
//  ShareUserCardContentFactory.swift
//  LarkMessageCore
//
//  Created by 赵家琛 on 2020/4/21.
//

import UIKit
import Foundation
import Swinject
import LarkModel
import AsyncComponent
import LarkMessageBase
import LarkSDKInterface
import LarkSetting

public protocol ShareUserCardContentContext: ViewModelContext {
    var scene: ContextScene { get }
}

public class BaseShareUserCardContentFactory<C: ShareUserCardContentContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .content
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is ShareUserCardContent
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return ShareUserCardContentViewModel(metaModel: metaModel,
                                             metaModelDependency: metaModelDependency,
                                             context: context,
                                             binder: ShareUserCardContentComponentBinder<M, D, C>(context: context))
    }
}

public class ChatPinShareUserCardContentFactory<C: ShareUserCardContentContext>: BaseShareUserCardContentFactory<C> {
    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return ShareUserCardContentViewModel(metaModel: metaModel,
                                             metaModelDependency: metaModelDependency,
                                             context: context,
                                             binder: ShareUserCardContentComponentBinder<M, D, C>(context: context),
                                             shareUserCardContentConfig: ShareUserCardContentConfig(hasPaddingBottom: true))
    }
}

public class ThreadShareUserCardContentFactory<C: ShareUserCardContentContext>: BaseShareUserCardContentFactory<C> {
    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return ShareUserCardContentViewModel(metaModel: metaModel,
                                             metaModelDependency: metaModelDependency,
                                             context: context,
                                             binder: ShareUserCardWithBorderContentComponentBinder<M, D, C>(context: context))
    }
}

extension PageContext: ShareUserCardContentContext {}
