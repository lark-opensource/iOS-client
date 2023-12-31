//
//  MergeForwardPostCardContentActionHandler.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/2/6.
//

import Foundation
import LarkCore
import LarkModel
import EENavigator
import LarkMessageBase
import LarkMessengerInterface

final class MergeForwardPostCardContentActionHandler<C: MergeForwardContentContext>: ComponentActionHandler<C> {
    func fromTitleTap(chat: Chat, message: Message, content: MergeForwardContent?) {
        onFromInfoTap(chat: chat, message: message, content: content)
    }

    func fromAvatarTap(chat: Chat, message: Message, content: MergeForwardContent?) {
        onFromInfoTap(chat: chat, message: message, content: content)
    }

    func onFromInfoTap(chat: Chat, message: Message, content: MergeForwardContent?) {
        guard let fromThreadChat = content?.fromThreadChat,
              fromThreadChat.role == .member else {
            tapAction(chat: chat, message: message, content: content)
            return
        }
        /// 点击卡片上的群名
        IMTracker.Chat.Main.Click.threadCardClick(chat, tapCardGroup: true, context.trackParams[PageContext.TrackKey.sceneKey] as? String)
        let body = ChatControllerByIdBody(chatId: fromThreadChat.id)
        self.context.navigator(type: .push, body: body, params: nil)
    }

    /// 点击事件
    func tapAction(chat: Chat, message: Message, content: MergeForwardContent?) {
        /// 如果是从私有话题转发详情页跳转的
        MergeForwardPostCardContentViewModelLogger.logger.info("tapAction fromChatID: \(String(describing: content?.fromThreadChat?.id)) subTitleCount: \(content?.thread?.subtitle.count)")
        guard let content = content,
              let fromChat = content.fromThreadChat else {
            return
        }
        /// 点击卡片的埋点
        IMTracker.Chat.Main.Click.threadCardClick(chat, tapCardGroup: false, context.trackParams[PageContext.TrackKey.sceneKey] as? String)
        if fromChat.role == .member {
            MergeForwardPostCardContentViewModelLogger.logger.info("push ThreadDetailByIDBody threadID--\(String(describing: content.thread?.id))")
            let body = ThreadDetailByIDBody(threadId: content.thread?.id ?? "")
            self.context.navigator(type: .push, body: body, params: nil)
        } else {
            var originMergeForwardId = message.id
            if context.scene == .threadPostForwardDetail,
               let chatPageAPI = context.targetVC as? ChatPageAPI,
               let forwardID = chatPageAPI.originMergeForwardId() {
                originMergeForwardId = forwardID
            }
            MergeForwardPostCardContentViewModelLogger.logger.info("push ThreadPostForwardDetailBody originMergeForwardId--\(originMergeForwardId)")
            let body = ThreadPostForwardDetailBody(originMergeForwardId: originMergeForwardId,
                                                   message: message,
                                                   chat: fromChat)
            self.context.navigator(type: .push, body: body, params: nil)
        }
    }
}
