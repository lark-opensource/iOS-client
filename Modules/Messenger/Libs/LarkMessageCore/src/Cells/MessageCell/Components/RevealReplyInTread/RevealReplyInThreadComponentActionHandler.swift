//
//  RevealReplyInThreadComponentActionHandler.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/2/9.
//

import Foundation
import LarkCore
import LarkModel
import LarkMessageBase
import LarkMessengerInterface

final class RevealReplyInThreadComponentActionHandler<C: RevealReplyInTreadViewModelContext>: ComponentActionHandler<C> {
    func replyClick(
        message: Message,
        chat: Chat,
        position: Int32?,
        keyboardStartupState: KeyboardStartupState = KeyboardStartupState(type: .none)
    ) {
        // 同ReplyThreadInfoComponentViewModel.replyDidTapped逻辑
        let isMergeForwardScene: Bool = message.mergeForwardInfo != nil
        let originChat = isMergeForwardScene ? message.mergeForwardInfo?.originChat : chat
        if originChat?.role == .member {
            let body = ReplyInThreadByModelBody(message: message,
                                                chat: originChat ?? chat,
                                                loadType: position == nil ? .unread : .position,
                                                position: position,
                                                keyboardStartupState: keyboardStartupState,
                                                sourceType: .chat,
                                                chatFromWhere: ChatFromWhere(fromValue: context.trackParams[PageContext.TrackKey.sceneKey] as? String) ?? .ignored)
            context.navigator(type: .push, body: body, params: nil)
        } else {
            //如果拿不到chat，也说明自己不在会话里。此时mock一个
            let chat = originChat ?? ReplyInThreadMergeForwardDataManager.getMockP2pChat(id: String(message.mergeForwardInfo?.originChatID ?? 0))
            let body = ThreadPostForwardDetailBody(originMergeForwardId: message.id, message: message, chat: chat)
            context.navigator(type: .push, body: body, params: nil)
        }
    }

    func replyTipClick(
        message: Message,
        chat: Chat
    ) {
        IMTracker.Chat.Main.Click.Msg.replyTopicClick(chat, message: message, context.trackParams[PageContext.TrackKey.sceneKey] as? String)
        self.replyClick(message: message, chat: chat, position: nil, keyboardStartupState: KeyboardStartupState(type: .inputView))
    }
}
