//
//  FeedbackRegenerateComponentFactory.swift
//  LarkAI
//
//  Created by 李勇 on 2023/6/16.
//

import Foundation
import LarkMessageBase
import LarkSDKInterface
import LarkMessengerInterface

public protocol FeedbackRegenerateFactoryContext: FeedbackRegenerateBinderContext {}

public final class FeedbackRegenerateComponentFactory<C: FeedbackRegenerateFactoryContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .feedbackRegenerate
    }

    public override var canCreateBinder: Bool {
        return true
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        // 必须是和MyAI的主分会场才展示
        guard metaModel.getChat().isP2PAi else { return false }
        // MyAI回复的才展示
        guard metaModel.message.fromChatter?.type == .ai else { return false }
        // MyAI新话题或选择插件后，自动生成的会话消息不展示
        guard metaModel.message.aiMessageType != .guideMessage else { return false }
        // 撤回的消息不展示
        guard !metaModel.message.isRecalled else { return false }
        return true
    }

    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return FeedbackRegenerateComponentBinder(
            viewModel: FeedbackRegenerateComponentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            actionHandler: FeedbackRegenerateComponentActionHandler(context: context)
        )
    }
}

extension PageContext: FeedbackRegenerateFactoryContext {
    public var sdkRustService: SDKRustService? {
        return try? self.userResolver.resolve(type: SDKRustService.self)
    }
}
