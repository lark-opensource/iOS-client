//
//  ActionButtonComponentFactory.swift
//  LarkAI
//
//  Created by 李勇 on 2023/5/16.
//

import Foundation
import LarkMessageBase
import LarkSDKInterface
import LarkMessengerInterface

public protocol ActionButtonFactoryContext: ActionButtonBinderContext {}

public final class ActionButtonComponentFactory<C: ActionButtonFactoryContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .actionButton
    }

    public override var canCreateBinder: Bool {
        return true
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        // 必须是和MyAI的分会场才展示
        guard let myAIPageService = self.context.myAIPageService, myAIPageService.chatMode else { return false }
        // MyAI回复的才展示
        guard metaModel.message.fromChatter?.type == .ai else { return false }
        guard !myAIPageService.chatModeConfig.actionButtons.isEmpty else { return false }
        // 撤回的消息不展示
        guard !metaModel.message.isRecalled else { return false }
        // 流式中不展示
        guard metaModel.message.streamStatus != .streamTransport, metaModel.message.streamStatus != .streamPrepare else { return false }
        // 存在有效数据才展示
        guard !metaModel.message.aiAnswerRawData.isEmpty else { return false }
        // 文本消息才展示
        return metaModel.message.type == .text || metaModel.message.type == .post
    }

    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return ActionButtonComponentBinder(
            viewModel: ActionButtonComponentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            actionHandler: ActionButtonComponentActionHandler(context: context)
        )
    }
}

extension PageContext: ActionButtonFactoryContext {
    public var myAIPageService: MyAIPageService? {
        // 这里需要从resolver页面层取，pageContainer是Cell渲染层用的容器
        return try? self.userResolver.resolve(type: MyAIPageService.self)
    }
}
