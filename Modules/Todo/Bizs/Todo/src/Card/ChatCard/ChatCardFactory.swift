//
//  ChatCardFactory.swift
//  Todo
//
//  Created by 张威 on 2020/12/5.
//

import LarkMessageBase
import AsyncComponent
import LarkModel

public protocol ChatCardContentContext: ViewModelContext {
    // 在 chat 中，任务卡片会被自动加上边框；但是在话题群、message 详情页等场景需要自己处理
    // 逻辑在下方拓展中实现
    func needBorder() -> Bool
    func isMe(_ chatterId: String) -> Bool
    var scene: ContextScene { get }
}

extension PageContext: ChatCardContentContext {
    public var scene: ContextScene {
        return dataSourceAPI?.scene ?? .newChat
    }

    public func needBorder() -> Bool {
        guard let scene = dataSourceAPI?.scene else {
            return false
        }

        switch scene {
        case .threadChat, .threadDetail, .messageDetail, .replyInThread, .threadPostForwardDetail:
            return true
        default:
            return false
        }
    }
    public func isMe(_ chatterId: String) -> Bool {
        return userID == chatterId
    }
}

public class ChatCardComponentFactory<C: PageContext>: MessageSubFactory<C> {

    public override class var subType: SubType { .content }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is TodoContent
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(
        with metaModel: M,
        metaModelDependency: D
    ) -> MessageSubViewModel<M, D, C> {
        return ChatCardViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: ChatCardBinder<M, D, C>(context: context)
        )
    }

}

public final class ChatPinCardComponentFactory<C: PageContext>: ChatCardComponentFactory<C> {
    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(
        with metaModel: M,
        metaModelDependency: D
    ) -> MessageSubViewModel<M, D, C> {
        return ChatCardViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: ChatCardBinder<M, D, C>(context: context),
            chatCardContentConfig: ChatCardContentConfig(needBottomPadding: true)
        )
    }
}

