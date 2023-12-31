//
//  VoIPChatContentFactory.swift
//  Action
//
//  Created by Prontera on 2019/6/20.
//

import Foundation
import LarkModel
import LarkMessageBase
import RxSwift
import AsyncComponent

protocol VoIPChatContentContext: ComponentContext & VoIPChatContentViewModelContext {}

class VoIPChatContentFactory<C: VoIPChatContentContext>: MessageSubFactory<C> {

    override class var subType: SubType {
        return .content
    }

    override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        /// 系统消息
        guard let messageContent = metaModel.message.content as? SystemContent else {
            return false
        }
        /// 获取VoIP
        switch messageContent.systemType {
        case .userCallE2EeVoiceDuration, .userCallE2EeVoiceWhenRefused, .userCallE2EeVoiceOnCancell,
             .userCallE2EeVoiceOnMissing, .userCallE2EeVoiceWhenOccupy:
            return true
        @unknown default:
            return false
        }
    }

    override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return VoIPChatContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context, binder: VoIPChatContentComponentBinder<M, D, C>(context: context))
    }
}

extension PageContext: VoIPChatContentContext {}
