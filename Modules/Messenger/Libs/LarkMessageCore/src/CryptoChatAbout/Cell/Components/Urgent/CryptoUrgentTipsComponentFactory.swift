//
//  CryptoUrgentTipsComponentFactory.swift
//  LarkMessageCore
//
//  Created by ByteDance on 2022/11/21.
//

import Foundation
import LarkModel
import LarkMessageBase
import LarkSDKInterface

public final class CryptoUrgentTipsComponentFactory<C: PageContext>: UrgentTipsComponentFactory<C> {
    public override class var subType: SubType {
        return .urgentTip
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        if context.isBurned(message: metaModel.message) {
            return false
        }
        return super.canCreate(with: metaModel)
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return UrgentTipsComponentViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: UrgentTipsComponentBinder<M, D, C>(context: context),
            transform: { chatters, chat in
                return chatters.map { chatter in
                    if chat.type == .p2P {
                        return ChatterForUrgentTip(id: chatter.id, displayName: BundleI18n.LarkMessageCore.Lark_IM_SecureChatUser_Title)
                    }
                    return ChatterForUrgentTip(id: chatter.id, displayName: chatter.displayName(chatId: chat.id,
                                                                                                chatType: chat.type,
                                                                                                scene: .urgentTip))
                }
            }
        )
    }
}
