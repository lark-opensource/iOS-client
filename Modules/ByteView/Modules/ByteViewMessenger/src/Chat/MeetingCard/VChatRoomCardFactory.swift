//
//  VChatRoomCardFactory.swift
//  LarkByteView
//
//  Created by Prontera on 2020/3/15.
//

import Foundation
import LarkModel
import LarkMessageBase
import LarkSDKInterface

protocol VChatRoomCardContext: VChatRoomCardViewModelContext {}

class VChatRoomCardFactory<C: PageContext>: MessageSubFactory<C> {
    override class var subType: SubType {
        return .content
    }

    override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is VChatRoomCardContent
    }

    override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return VChatRoomCardViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: VChatRoomCardComponentBinder<M, D, C>(context: context)
        )
    }
}
