//
//  MergeForwardReplyInThreadCardContentActionHandler.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/2/7.
//

import Foundation
import LarkCore
import LarkModel
import EENavigator
import LarkMessageBase
import LarkMessengerInterface

class MergeForwardReplyInThreadCardContentActionHandler<C: MergeForwardContentContext>: ComponentActionHandler<C> {
    private let currentChatterId: String
    init(context: C, currentChatterId: String) {
        self.currentChatterId = currentChatterId
        super.init(context: context)
    }

    func fromTitleTap(chat: Chat, message: Message, content: MergeForwardContent?) {
        onFromInfoTap(chat: chat, message: message, content: content)
    }

    func fromAvatarTap(chat: Chat, message: Message, content: MergeForwardContent?) {
        onFromInfoTap(chat: chat, message: message, content: content)
    }

    func onFromInfoTap(chat: Chat, message: Message, content: MergeForwardContent?) {
        self.tapAction(chat: chat, message: message, content: content)
    }

    /// 点击事件
    func tapAction(chat: Chat, message: Message, content: MergeForwardContent?) {
        /// 如果是从私有话题转发详情页跳转的
        MergeForwardReplyInThreadCardContentViewModelLogger.logger.info("tapAction fromChatID: \(content?.fromThreadChat?.id) subTitleCount: \(content?.thread?.subtitle.count)")
        guard let content = content else {
            return
        }
        /// 点击卡片的埋点
        IMTracker.Chat.Main.Click.Msg.ReplyThread(chat, message, context.trackParams[PageContext.TrackKey.sceneKey] as? String, type: .threadCard)
        if ReplyInThreadMergeForwardDataManager.isChatMember(content: content, currentChatterId: self.currentChatterId) {
            MergeForwardReplyInThreadCardContentViewModelLogger.logger.info("push ReplyInThreadByIDBody threadID--\(String(describing: content.thread?.id))")
            let body = ReplyInThreadByIDBody(threadId: content.thread?.id ?? "",
                                             sourceType: .forward_card,
                                             chatFromWhere: ChatFromWhere(fromValue: context.trackParams[PageContext.TrackKey.sceneKey] as? String) ?? .ignored)
            self.context.navigator(type: .push, body: body, params: nil)
        } else {
            var originMergeForwardId = message.id
            if context.scene == .threadPostForwardDetail,
               let chatPageAPI = context.targetVC as? ChatPageAPI,
               let forwardID = chatPageAPI.originMergeForwardId() {
                originMergeForwardId = forwardID
            }
            MergeForwardReplyInThreadCardContentViewModelLogger.logger.info("reply in Thread content push ThreadPostForwardDetailBody originMergeForwardId--\(originMergeForwardId)")
            var body = ThreadPostForwardDetailBody(originMergeForwardId: originMergeForwardId,
                                                   message: message,
                                                   chat: ReplyInThreadMergeForwardDataManager.getFromChatFor(content: content),
                                                   openWithMergeForwardContentPrior: true)
            self.context.navigator(type: .push, body: body, params: nil)
        }
    }
}
