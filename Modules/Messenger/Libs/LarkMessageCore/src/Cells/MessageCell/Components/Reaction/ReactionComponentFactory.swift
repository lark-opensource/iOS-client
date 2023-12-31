//
//  ReactionComponentFactory.swift
//  Pods
//
//  Created by liuwanlin on 2019/3/20.
//

import Foundation
import LarkModel
import LarkMessengerInterface
import LarkMessageBase
import LarkAccountInterface
import LarkSDKInterface
import LarkEmotion

public class ReactionComponentFactory<C: PageContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .reaction
    }

    public override var canCreateBinder: Bool {
        return true
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        let message = metaModel.message
        // 需要过滤掉chatterCount为0 和 违规的那些reaction
        let reactions = message.reactions.filter { reaction in
            let reactionKey = reaction.type
            let isDeleted = EmotionResouce.shared.isDeletedBy(key: reactionKey)
            return (reaction.chatterCount > 0) && (isDeleted == false)
        }
        if reactions.isEmpty {
            return false
        }
        if message.isRecalled || message.isDecryptoFail {
            return false
        }
        if !(canReaction(message)) {
            return false
        }
        return true
    }

    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        switch context.scene {
        case .threadPostForwardDetail:
            return ReactionComponentBinder(
                reactonViewModel: ThreadPostForwardReactionViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
                reactionActionHandler: ThreadPostForwardReactionActionHandler(context: context)
            )
        case .mergeForwardDetail:
            return ReactionComponentBinder(
                reactonViewModel: MergeForwardReactionViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
                reactionActionHandler: MergeForwardReactionActionHandler(context: context)
            )
        default:
            return ReactionComponentBinder(
                reactonViewModel: ReactionViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
                reactionActionHandler: ReactionActionHandler(context: context)
            )
        }
    }

    private func canReaction(_ message: Message) -> Bool {
        return message.type != .system
    }
}

// 会话/ReplyInThread等支持独立卡片的场景使用
public final class ChatReactionComponentFactory<C: PageContext>: ReactionComponentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        var config = ReactionConfig()
        config.supportSinglePreview = true
        return ReactionComponentBinder(
            reactonViewModel: ReactionViewModel(
                metaModel: metaModel,
                metaModelDependency: metaModelDependency,
                context: context,
                reactionConfig: config
            ),
            reactionActionHandler: ReactionActionHandler(context: context)
        )
    }
}

public final class MessageLinkReactionComponentFactory<C: PageContext>: ReactionComponentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        var config = ReactionConfig()
        config.customReactionType = .gray
        return ReactionComponentBinder(
            reactonViewModel: MergeForwardReactionViewModel(
                metaModel: metaModel,
                metaModelDependency: metaModelDependency,
                context: context,
                reactionConfig: config
            ),
            reactionActionHandler: MergeForwardReactionActionHandler(context: context)
        )
    }
}

extension PageContext: ReactionViewModelContext {
    public var scene: ContextScene {
        return dataSourceAPI?.scene ?? .newChat
    }

    public var currentChatterId: String { return currentUserID }

    public var reactionAPI: ReactionAPI? {
        return try? resolver.resolve(assert: ReactionAPI.self, cache: true)
    }
}
