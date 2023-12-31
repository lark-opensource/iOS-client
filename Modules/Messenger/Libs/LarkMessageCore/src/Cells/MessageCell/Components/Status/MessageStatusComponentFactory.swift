//
//  MessageStatusComponentFactory.swift
//  LarkMessageCore
//
//  Created by qihongye on 2019/4/22.
//

import Foundation
import LarkModel
import LarkMessageBase
import RxSwift
import LarkSendMessage
import LarkMessengerInterface

public protocol StatusContext: StatusComponentContext, StatusViewModelContext {

}

open class MessageStatusComponentFactory<C: StatusContext>: MessageSubFactory<C> {
    open override class var subType: SubType {
        return .messageStatus
    }

    open override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        if metaModel.getChat().isTeamVisitorMode {
            return false
        }
        return metaModel.message.fromChatter?.type == .user
    }

    open override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return MessageStatusViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: MessageStatusComponentBinder<M, D, C>(context: context)
        )
    }
}

extension PageContext: StatusContext {
    public var supportAvatarLeftRightLayout: Bool {
        return self.dataSourceAPI?.supportAvatarLeftRightLayout ?? false
    }

    public func resend(message: Message) {

        switch message.type {
        case .media:
            guard let vc = self.targetVC else {
                assertionFailure("缺少路由跳转VC")
                return
            }
            try? resolver.resolve(assert: VideoMessageSendService.self, cache: true).resendVideoMessage(message, from: vc)
        case .post:
            try? resolver.resolve(assert: PostSendService.self).resend(message: message)
        @unknown default:
            try? resolver.resolve(assert: SendMessageAPI.self, cache: true).resendMessage(message: message)
        }
    }
}
