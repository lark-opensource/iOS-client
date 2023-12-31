//
//  MergeForwardContentFactory.swift
//  LarkMessageCore
//
//  Created by zc09v on 2019/6/18.
//

import Foundation
import LarkModel
import LarkSetting
import LarkMessageBase
import EENavigator

public protocol MergeForwardContentContext: MergeForwardContentViewModelContext & MergeForwardContentComponentContext & ForwardThreadBinderContext {
}

public class BaseMergeForwardContentFactory<C: MergeForwardContentContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .content
    }

    public override var canCreateBinder: Bool {
        return true
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is MergeForwardContent
    }
}

public class ChatMergeForwardContentFactory<C: MergeForwardContentContext>: BaseMergeForwardContentFactory<C> {
    let enableThreadForwardCard: Bool
    let messageEngineFactory: MessageEngineCellViewModelFactory<PageContext>?

    public required init(context: C) {
        let enableThreadForwardCard = context.getStaticFeatureGating("messenger.message.new_thread_forward_card")
        self.enableThreadForwardCard = enableThreadForwardCard
        if enableThreadForwardCard {
            self.messageEngineFactory = MessageEngineCellViewModelFactory(
                context: context,
                registery: MessageEngineSubFactoryRegistery(
                    context: context, defaultFactory: MessageEngineUnknownContentFactory(context: context)
                ),
                initBinder: { [unowned context] contentComponent in
                    return ForwardMessageEngineCellBinder<PageContext>(
                        context: context,
                        contentComponent: contentComponent
                    )
                }
            )
        } else {
            self.messageEngineFactory = nil
        }
        super.init(context: context)
    }

    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        if let binder = getChatMergeForwardBinder(with: metaModel, metaModelDependency: metaModelDependency) {
            return binder
        }
        return MergeForwardContentComponentBinder(
            mergeForwardViewModel: MergeForwardContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            mergeForwardActionHandler: MergeForwardContentActionHandler(context: context)
        )
    }

    func getChatMergeForwardBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C>? {
        if let content = metaModel.message.content as? MergeForwardContent, content.isFromPrivateTopic {
            // 「转发话题外露回复」需求：话题回复、话题使用一套逻辑 & 使用嵌套UI
            if enableThreadForwardCard, let messageEngineFactory = messageEngineFactory {
                return ForwardThreadContentComponentBinder(
                    context: context,
                    viewModel: ForwardThreadContentViewModel(metaModel: metaModel,
                                                             metaModelDependency: metaModelDependency,
                                                             context: context,
                                                             messageEngineFactory: messageEngineFactory),
                    actionHandler: ForwardThreadContentActionHandler(context: context, currentChatterId: self.context.currentUserID)
                )
            } else if let thread = content.thread, thread.isReplyInThread {
                return MergeForwardReplyInThreadCardContentComponentBinder(
                    mergeForwardViewModel: MergeForwardReplyInThreadCardContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
                    mergeForwardActionHandler: MergeForwardReplyInThreadCardContentActionHandler(context: context, currentChatterId: self.context.currentUserID)
                )
            } else {
                return MergeForwardPostCardContentComponentBinder(
                    mergeForwardViewModel: MergeForwardPostCardContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
                    mergeForwardActionHandler: MergeForwardPostCardContentActionHandler(context: context)
                )
            }
        }
        return nil
    }
}

// 话题转发卡片场景
public class ForwardThreadMergeForwardContentFactory<C: MergeForwardContentContext>: BaseMergeForwardContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        // 话题转发卡片场景不能再持有MessageEngineCellViewModelFactory了，否则会导致MessageEngineSubFactoryRegistery递归注册
        if let content = metaModel.message.content as? MergeForwardContent, content.isFromPrivateTopic {
            if let thread = content.thread, thread.isReplyInThread {
                return MergeForwardReplyInThreadCardContentComponentBinder(
                    mergeForwardViewModel: MergeForwardReplyInThreadCardContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
                    mergeForwardActionHandler: MergeForwardReplyInThreadCardContentActionHandler(context: context, currentChatterId: self.context.currentUserID)
                )
            } else {
                return MergeForwardPostCardContentComponentBinder(
                    mergeForwardViewModel: MergeForwardPostCardContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
                    mergeForwardActionHandler: MergeForwardPostCardContentActionHandler(context: context)
                )
            }
        }
        // 消息链接化 & 话题卡片转发上层统一加border
        return MergeForwardContentComponentBinder(
            mergeForwardViewModel: MessageLinkMergeForwardContentViewModel(
                metaModel: metaModel,
                metaModelDependency: metaModelDependency,
                context: context,
                config: getMergeForwardConfig()
            ),
            mergeForwardActionHandler: MergeForwardContentActionHandler(context: context)
        )
    }

    func getMergeForwardConfig() -> MergeForwardConfig {
        return MergeForwardConfig(needContentPadding: true)
    }
}

// 群置顶场景
public class ChatPinMergeForwardContentFactory<C: MergeForwardContentContext>: ChatMergeForwardContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        if let binder = getChatMergeForwardBinder(with: metaModel, metaModelDependency: metaModelDependency) {
            return binder
        }
        return MergeForwardContentComponentBinder(
            mergeForwardViewModel: MessageLinkMergeForwardContentViewModel(
                metaModel: metaModel,
                metaModelDependency: metaModelDependency,
                context: context,
                config: MergeForwardConfig(needContentPadding: true)
            ),
            mergeForwardActionHandler: MergeForwardContentActionHandler(context: context)
        )
    }
}

// 消息链接化场景
public final class MessageLinkMergeForwardContentFactory<C: MergeForwardContentContext>: ForwardThreadMergeForwardContentFactory<C> {
    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        // 消息链接化场景话题转发卡片需要降级为文本
        if let content = metaModel.message.content as? MergeForwardContent, content.isFromPrivateTopic {
            return false
        }
        return super.canCreate(with: metaModel)
    }

    // 消息链接化场景上层加padding
    override func getMergeForwardConfig() -> MergeForwardConfig {
        return MergeForwardConfig(needContentPadding: false)
    }
}

// pin
public final class PinMergeForwardContentFactory<C: MergeForwardContentContext>: ChatMergeForwardContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        if let content = metaModel.message.content as? MergeForwardContent, content.isFromPrivateTopic {
            // 「转发话题外露回复」需求：pin场景（Pin和标记页面）保持旧样式，二期适配；因为Pin和标记页面的根消息要求处理成和会话不同
            if let thread = content.thread, thread.isReplyInThread {
                return MergeForwardReplyInThreadCardContentBorderComponentBinder(
                    mergeForwardViewModel: MergeForwardReplyInThreadCardContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
                    mergeForwardActionHandler: MergeForwardReplyInThreadCardContentActionHandler(context: context, currentChatterId: self.context.currentUserID)
                )
            } else {
                return MergeForwardPostCardContentBorderComponentBinder(
                    mergeForwardViewModel: MergeForwardPostCardContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
                    mergeForwardActionHandler: MergeForwardPostCardContentActionHandler(context: context)
                )
            }
        }
        return MergeForwardContentComponentBinder(
            mergeForwardViewModel: MergeForwardContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            mergeForwardActionHandler: MergeForwardContentActionHandler(context: context)
        )
    }
}

// threadChat，threadDetail, replyInThread, threadPostForwardDetail
public final class ThreadChatMergeForwardContentFactory<C: MergeForwardContentContext>: ChatMergeForwardContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        if let content = metaModel.message.content as? MergeForwardContent, content.isFromPrivateTopic {
            if enableThreadForwardCard, let messageEngineFactory = messageEngineFactory {
                return ForwardThreadContentComponentBinder(
                    context: context,
                    viewModel: ForwardThreadContentViewModel(metaModel: metaModel,
                                                             metaModelDependency: metaModelDependency,
                                                             context: context,
                                                             messageEngineFactory: messageEngineFactory),
                    actionHandler: ForwardThreadContentActionHandler(context: context, currentChatterId: self.context.currentUserID)
                )
            } else if let thread = content.thread, thread.isReplyInThread {
                return MergeForwardReplyInThreadCardContentBorderComponentBinder(
                    mergeForwardViewModel: MergeForwardReplyInThreadCardContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
                    mergeForwardActionHandler: MergeForwardReplyInThreadCardContentActionHandler(context: context, currentChatterId: self.context.currentUserID)
                )
            } else {
                return MergeForwardPostCardContentBorderComponentBinder(
                    mergeForwardViewModel: MergeForwardPostCardContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
                    mergeForwardActionHandler: MergeForwardPostCardContentActionHandler(context: context)
                )
            }
        }

        return ThreadChatMergeForwardContentComponentBinder(
            mergeForwardViewModel: MergeForwardContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            mergeForwardActionHandler: MergeForwardContentActionHandler(context: context)
        )
    }
}

// messageDetail
public final class MessageDetailMergeForwardContentFactory<C: MergeForwardContentContext>: ChatMergeForwardContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        if let content = metaModel.message.content as? MergeForwardContent, content.isFromPrivateTopic {
            if enableThreadForwardCard, let messageEngineFactory = messageEngineFactory {
                return ForwardThreadContentComponentBinder(
                    context: context,
                    viewModel: ForwardThreadContentViewModel(metaModel: metaModel,
                                                             metaModelDependency: metaModelDependency,
                                                             context: context,
                                                             messageEngineFactory: messageEngineFactory),
                    actionHandler: ForwardThreadContentActionHandler(context: context, currentChatterId: self.context.currentUserID)
                )
            } else if let thread = content.thread, thread.isReplyInThread {
                return MergeForwardReplyInThreadCardContentBorderComponentBinder(
                    mergeForwardViewModel: MergeForwardReplyInThreadCardContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
                    mergeForwardActionHandler: MergeForwardReplyInThreadCardContentActionHandler(context: context, currentChatterId: self.context.currentUserID)
                )
            } else {
                return MergeForwardPostCardContentBorderComponentBinder(
                    mergeForwardViewModel: MergeForwardPostCardContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
                    mergeForwardActionHandler: MergeForwardPostCardContentActionHandler(context: context)
                )
            }
        }

        return MessageDetailContentComponentBinder(
            mergeForwardViewModel: MergeForwardContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            mergeForwardActionHandler: MergeForwardContentActionHandler(context: context)
        )
    }
}

extension PageContext: MergeForwardContentContext {
}
