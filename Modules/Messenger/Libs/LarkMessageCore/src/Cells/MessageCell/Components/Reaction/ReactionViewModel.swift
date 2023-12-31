//
//  ReactionViewModel.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/3/6.
//

import UIKit
import Foundation
import Homeric
import AsyncComponent
import EEFlexiable
import LarkModel
import EENavigator
import LarkUIKit
import LarkSetting
import RxSwift
import UniverseDesignToast
import LarkMessageBase
import LKCommonsTracker
import LarkSDKInterface
import LKCommonsLogging
import LarkMessengerInterface
import LarkCore

public protocol ReactionViewModelContext: ViewModelContext, ColorConfigContext {
    var scene: ContextScene { get }
    var reactionAPI: ReactionAPI? { get }
    var currentChatterId: String { get }
    func isBurned(message: Message) -> Bool
    func isMe(_ chatterID: String, chat: Chat) -> Bool
    func getStaticFeatureGating(_ key: FeatureGatingManager.Key) -> Bool
}

public enum ReactionType {
    case blue, gray
}

final class ReactionViewModelLogger {
    static let logger = Logger.log(ReactionViewModelLogger.self, category: "Module.LarkMessageCore.ReactionViewModel")
}

public struct ReactionConfig {
    // 指定ReactionType，nil时使用默认规则
    public var customReactionType: ReactionType?
    // 是否支持独立卡片
    public var supportSinglePreview: Bool

    public init(supportSinglePreview: Bool = false) {
        self.supportSinglePreview = supportSinglePreview
    }
}

public class ReactionViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: ReactionViewModelContext & PageContext>: NewMessageSubViewModel<M, D, C> {
    public var vmIdentifier: String {
        return message.id
    }

    public var reactions: [Reaction] {
        return message.reactions
    }

    let reactionConfig: ReactionConfig

    public init(
        metaModel: M,
        metaModelDependency: D,
        context: C,
        reactionConfig: ReactionConfig = ReactionConfig()
    ) {
        self.reactionConfig = reactionConfig
        super.init(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context)
        self.logWhileReactionChattersAreMissing()
    }

    public override func update(metaModel: M, metaModelDependency: D?) {
        super.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
        self.logWhileReactionChattersAreMissing()
    }

    @inline(__always)
    private func logWhileReactionChattersAreMissing() {
        // 处理message上chatter缺失的情况，进行打点
        message.reactions.forEach { (reaction) in
            if reaction.chatterIds.count != reaction.chatters?.count {
                ReactionViewModelLogger.logger.error(
                    "reaction: message.chatters is missing, reactionType = \(reaction.type), messageId = \(message.id)"
                )
            }
        }
    }

    private lazy var threadReplyBubbleOptimize: Bool = {
        return self.context.getStaticFeatureGating("im.message.thread_reply_bubble_optimize")
    }()

    private var isSinglePreview: Bool {
        return reactionConfig.supportSinglePreview &&
        TCPreviewContainerComponentFactory.canCreateSinglePreview(message: message, chat: metaModel.getChat(), context: context)
    }

    // 会话内有独立卡片时，reaction间距不同，所以会话场景间距由组件自己设置
    // 其他场景维持不变，由CellComponent统一设置间距
    public var marginTop: CSSValue? {
        if context.scene == .newChat {
            // 独立卡片且非气泡场景
            if isSinglePreview,
               !TCPreviewContainerComponentFactory.isSinglePreviewWithBubble(message: message, scene: context.scene) {
                return 4
            }
            return CSSValue(cgfloat: metaModelDependency.contentPadding)
        }
        return nil
    }

    // 会话内有独立卡片时，reaction间距不同，所以会话场景间距由组件自己设置
    // 其他场景维持不变，由CellComponent统一设置间距
    public var marginHoriz: CSSValue? {
        return context.scene == .newChat ? CSSValue(cgfloat: metaModelDependency.contentPadding) : nil
    }

    public var reactionType: ReactionType {
        if let customReactionType = reactionConfig.customReactionType {
            return customReactionType
        }
        let scene = self.context.scene
        if isSinglePreview {
            return (TCPreviewContainerComponentFactory.isSinglePreviewWithBubble(message: message, scene: context.scene) && message.isMeSend(userId: context.currentChatterId)) ? .blue : .gray
        }
        // 会话、合并转发页面，话题样式下创建的使用灰色
        if (scene == .newChat || scene == .mergeForwardDetail), message.displayInThreadMode {
            return .gray
        }
        // 话题回复
        if (scene == .newChat || scene == .mergeForwardDetail), (message.showInThreadModeStyle && !message.displayInThreadMode) {
            // 如果开了FG，则统一使用蓝灰
            if self.threadReplyBubbleOptimize {
                return message.isMeSend(userId: context.currentChatterId) ? .blue : .gray
            }
            // 如果没开FG，使用灰色
            return .gray
        }

        // chat & 合并转发详情页中&&自己发的消息才会使用蓝色样式
        guard (scene == .newChat || scene == .mergeForwardDetail), message.isMeSend(userId: context.currentChatterId) else { return .gray }
        // 只在部分类型使用蓝色样式
        switch message.type {
        case .post:
            if let content = message.content as? PostContent,
               content.isGroupAnnouncement {
                return .gray
            }
            return .blue
        case .text, .audio, .image, .sticker, .media: return .blue
        case .mergeForward:
            if (message.content as? MergeForwardContent)?.isFromPrivateTopic ?? false {
                return .gray
            }
            return .blue
        @unknown default: return .gray
        }
    }

    func rectionTagBg() -> UIColor {
        switch reactionType {
        case .blue:
            return context.getColor(for: .Reaction_Background, type: .mine)
        case .gray:
            let scene = self.context.scene
            if (scene == .newChat || scene == .mergeForwardDetail), message.displayInThreadMode {
                return UIColor.ud.udtokenReactionBgGrey
            }
            // 话题回复，如果没开FG，使用和话题模式一样的颜色
            if (scene == .newChat || scene == .mergeForwardDetail), !self.threadReplyBubbleOptimize, (message.showInThreadModeStyle && !message.displayInThreadMode) {
                return UIColor.ud.udtokenReactionBgGrey
            }
            return context.getColor(for: .Reaction_Background, type: .other)
        }
    }

    public func reactionAbsenceCount(_ reaction: Reaction) -> Int? {
        return Int(reaction.chatterCount) - reaction.chatterIds.count
    }

    public func reactionTagIconActionAreaEdgeInsets() -> UIEdgeInsets? {
        return UIEdgeInsets(top: 7, left: 12, bottom: 7, right: 5)
    }

    public func getReactionChatterDisplayName(_ chatter: Chatter) -> String {
        let chat = self.metaModel.getChat()
        let displayName = chatter.displayName(chatId: chat.id, chatType: chat.type, scene: .reaction)
        if displayName.isEmpty {
            ReactionViewModelLogger.logger.error(
                """
                reaction: displayName is empty:
                \(chatter.chatExtraChatID ?? "chatExtraChatID is empty")
                \(chat.id)
                \(chat.type)
                \(chatter.id)
                \(chatter.alias.count)
                \(chatter.localizedName.count)
                \(chatter.nickName?.count ?? 0)
                """
            )
        }
        return displayName
    }
}

public class ThreadPostForwardReactionViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: ReactionViewModelContext & PageContext>: ReactionViewModel<M, D, C> {
    /// 补偿的reaction的数量
    public override func reactionAbsenceCount(_ reaction: Reaction) -> Int? {
        let chatterCount = Int(reaction.chatterCount)
        guard chatterCount > reaction.chatterIds.count else {
            return nil
        }
        return chatterCount - reaction.chatterIds.count
    }
}

public final class MergeForwardReactionViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: ReactionViewModelContext & PageContext>: ThreadPostForwardReactionViewModel<M, D, C> {}
