//
//  PinComponentFactory.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/3.
//

import Foundation
import LarkModel
import LarkCore
import LarkMessageBase
import LarkMessengerInterface
import RxSwift
import LarkSDKInterface
import LarkSetting

public protocol PinComponentContext: PinComponentViewModelContext { }

public final class PinComponentFactory<C: PageContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .pin
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        guard !ChatNewPinConfig.supportPinMessage(chat: metaModel.getChat(), self.context.userResolver.fg) else {
            return false
        }

        let message = metaModel.message
        if message.isRecalled || message.isDecryptoFail {
            return false
        }
        if !metaModel.getChat().isSupportPinMessage {
            return false
        }
        return message.pinChatter != nil
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        switch context.scene {
        case .newChat, .mergeForwardDetail, .messageDetail, .pin:
            return PinComponentViewModel(
                metaModel: metaModel,
                metaModelDependency: metaModelDependency,
                context: context,
                binder: PinComponentBinder<M, D, C>(context: context)
            )
        case .threadChat, .threadDetail:
            return ThreadPinComponentViewModel(
                metaModel: metaModel,
                metaModelDependency: metaModelDependency,
                context: context,
                binder: ThreadPinComponentBinder<M, D, C>(context: context)
            )
        case .threadPostForwardDetail:
            return ThreadPinComponentViewModel(
                metaModel: metaModel,
                metaModelDependency: metaModelDependency,
                context: context,
                binder: ThreadPinComponentBinder<M, D, C>(context: context)
            )
        case .replyInThread:
            return ReplyInThreadPinComponentViewModel(
                metaModel: metaModel,
                metaModelDependency: metaModelDependency,
                context: context,
                binder: ThreadPinComponentBinder<M, D, C>(context: context)
            )
        @unknown default:
            fatalError("new value")
        }
    }
}

extension PageContext: PinComponentContext {
    public func getPinChatterName(chatter: Chatter, chat: Chat) -> String {
        return getDisplayName(chatter: chatter, chat: chat, scene: .pin)
    }
}

public struct ChatPinPermissionManager {
    public static func hasPinPermissionInChat(_ chat: Chat, userID: String, featureGatingService: FeatureGatingService) -> Bool {
        if chat.isFrozen {
            return false
        }
        guard featureGatingService.staticFeatureGatingValue(with: "im.chat.only.admin.can.pin.vc.buzz") else { return true }
        // single chat not limit
        if chat.type == .p2P { return true }
        if chat.type == .group || chat.chatMode == .threadV2 {
            return ChatPinPermissionUtils.checkPinMessagePermission(chat: chat, userID: userID, featureGatingService: featureGatingService)
        }
        assertionFailure("unknown chat type")
        return true
    }
}
