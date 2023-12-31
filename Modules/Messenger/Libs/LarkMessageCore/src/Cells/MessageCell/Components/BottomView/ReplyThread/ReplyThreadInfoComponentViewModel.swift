//
//  ReplyThreadInfoComponentViewModel.swift
//  LarkMessageCore
//
//  Created by JackZhao on 2022/4/25.
//

import UIKit
import EEAtomic
import LarkModel
import Foundation
import EENavigator
import LarkMessageBase
import LKCommonsLogging
import LarkReleaseConfig
import LarkMessengerInterface
import LarkCore
import LarkContainer
import LarkSDKInterface
import LarkAccountInterface

final class ReplyThreadInfoLogger {
    static let logger = Logger.log(ReplyThreadInfoLogger.self, category: "MessagCore")
}

final class ReplyThreadInfoComponentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: PageContext>: MessageSubViewModel<M, D, C> {
    private var replyCount: Int32 {
        return message.replyInThreadCount
    }

    private var text: String {
        return replyCount > 999
            ? BundleI18n.LarkMessageCore.Lark_IM_Thread_999PlusReplies_Text()
            : BundleI18n.LarkMessageCore.Lark_IM_Thread_NumRepliesToThread_Tooltip(replyCount)
    }

    var chatComponentTheme: ChatComponentTheme {
        let scene = self.context.getChatThemeScene()
        return ChatComponentThemeManager.getComponentTheme(scene: scene)
    }

    /// 回复描述
    public var attributedText: NSAttributedString {
        let textColor = chatComponentTheme.threadReplyTipColor
        let attributedText = NSMutableAttributedString(string: text)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        attributedText.addAttributes([.font: UIFont.systemFont(ofSize: 14),
                                      .foregroundColor: textColor,
                                      .paragraphStyle: paragraphStyle],
                                     range: NSRange(location: 0, length: attributedText.length)
        )
        return attributedText
    }

    public var chatterModels: [ReplyThreadChatterModel] {
        return message.replyInThreadTopRepliers.map { ReplyThreadChatterModel(userId: $0.id, key: $0.avatarKey) }
    }

    public override  init(
        metaModel: M,
        metaModelDependency: D,
        context: C,
        binder: ComponentBinder<C>) {
        super.init(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context, binder: binder)
    }

    public func replyDidTapped() {
        let isMergeForwardScene: Bool = message.mergeForwardInfo != nil
        let chat = isMergeForwardScene ? message.mergeForwardInfo?.originChat : self.metaModel.getChat()
        if chat?.role == .member {
            guard let chat = chat else { return } //这条路径一定是有chat的
            let loadType: ThreadDetailLoadType
            switch message.threadMessageType {
            case .unknownThreadMessage, .threadReplyMessage:
                ReplyThreadInfoLogger.logger.error("ReplyThreadInfoComponentViewModel replyDidTapped: threadMessageType error ")
                assertionFailure("threadMessageType error")
                return
            case .threadRootMessage:
                loadType = isMergeForwardScene ? .root : .unread
            @unknown default:
                assertionFailure("threadMessageType error")
                return
            }
            let body = ReplyInThreadByModelBody(message: message,
                                                chat: chat,
                                                loadType: loadType,
                                                sourceType: .chat,
                                                chatFromWhere: ChatFromWhere(fromValue: context.trackParams[PageContext.TrackKey.sceneKey] as? String) ?? .ignored)
            context.navigator(type: .push, body: body, params: nil)
            IMTracker.Chat.Main.Click.Msg.ReplyThread(chat,
                                                      message,
                                                      context.trackParams[PageContext.TrackKey.sceneKey] as? String,
                                                      type: .threadReply)
        } else {
            var originMergeForwardId = message.id
            if context.scene == .threadPostForwardDetail,
               let chatPageAPI = context.targetVC as? ChatPageAPI,
               let forwardID = chatPageAPI.originMergeForwardId() {
                originMergeForwardId = forwardID
            }
            //如果拿不到chat，也说明自己不在会话里。此时mock一个
            let chat = chat ?? ReplyInThreadMergeForwardDataManager.getMockP2pChat(id: String(message.mergeForwardInfo?.originChatID ?? 0))
            let body = ThreadPostForwardDetailBody(originMergeForwardId: originMergeForwardId,
                                                   message: message,
                                                   chat: chat)
            context.navigator(type: .push, body: body, params: nil)
        }
    }
}
