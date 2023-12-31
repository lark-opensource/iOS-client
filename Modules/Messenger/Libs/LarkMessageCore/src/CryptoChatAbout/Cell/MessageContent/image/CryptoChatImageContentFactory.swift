//
//  CryptoChatImageContentFactory.swift
//  LarkMessageCore
//
//  Created by zc09v on 2022/1/17.
//

import CoreServices
import Foundation
import LarkModel
import LarkMessageBase
import RxSwift
import LarkSDKInterface
import LarkInteraction
import ByteWebImage

public class CryptoChatImageContentFactory<C: ImageContentContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .content
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is ImageContent
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return CryptoChatImageContentViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: CryptoChatImageContentComponentBinder<M, D, C>(context: context)
        )
    }

    public override func registerDragHandler<M: CellMetaModel, D: CellMetaModelDependency>(with dargManager: DragInteractionManager, metaModel: M, metaModelDependency: D) {
        return
    }
}

public final class CryptoMessageDetailImageContentFactory<C: ImageContentContext>: CryptoChatImageContentFactory<C> {
    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return CryptoChatMessageDetailImageContentViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: CryptoChatMessageDetailImageContentComponentBinder<M, D, C>()
        )
    }
}
