//
//  RedPacketContentFactory.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/6/10.
//

import UIKit
import Foundation
import LarkModel
import AsyncComponent
import LarkMessageBase

public protocol RedPacketContentContext: ViewModelContext {
    var contextScene: ContextScene { get }
    @available(*, deprecated, message: "this function could't judge anonymous scene, the best is to use new isMe with metaModel parameter")
    func isMe(_ chatterId: String) -> Bool
    func isMe(_ chatterID: String, chat: Chat) -> Bool
    // some cases redpacket can select but the other can't select
    // so this property is to limit it
    func getMessageSelectedEnable(_ message: Message) -> Bool
    func getChatThemeScene() -> ChatThemeScene
}

public class RedPacketContentFactory<C: RedPacketContentContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .content
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is HongbaoContent
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return RedPacketContentViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: RedPacketContentComponentBinder<M, D, C>(context: context)
        )
    }
}

public final class MessageDetailRedPacketContentFactory<C: RedPacketContentContext>: RedPacketContentFactory<C> {
    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return MessageDetailRedPacketContentViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: RedPacketContentComponentBinder<M, D, C>(context: context)
        )
    }
}

extension PageContext: RedPacketContentContext {
    public func getMessageSelectedEnable(_ message: Message) -> Bool {
        return self.dataSourceAPI?.processMessageSelectedEnable(message: message) ?? false
    }
}
