//
//  VChatContentContext.swift
//  Action
//
//  Created by Prontera on 2019/6/17.
//

import Foundation
import LarkModel
import LarkMessageBase
import RxSwift
import LarkFeatureGating
import AsyncComponent

protocol VChatContentContext: ComponentContext & VChatContentViewModelContext {}

class VChatContentFactory<C: VChatContentContext>: MessageSubFactory<C> {
    override class var subType: SubType {
        return .content
    }

    override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        // 系统消息
        guard let messageContent = metaModel.message.content as? SystemContent else {
            return false
        }
        // 获取VoIP
        switch messageContent.systemType {
        case .vcCallHostCancel, .vcCallPartiNoAnswer, .vcCallPartiCancel, .vcCallHostBusy,
             .vcCallPartiBusy, .vcCallFinishNotice, .vcCallDuration, .vcCallConnectFail,
             .vcCallDisconnect:
            return true
        @unknown default:
            return false
        }
    }

    override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return VChatContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context, binder: VChatContentComponentBinder<M, D, C>(context: context))
    }
}

extension PageContext: VChatContentContext {
    var callbackEnabled: Bool {
        return true
    }
}
