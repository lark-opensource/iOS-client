//
//  MergeForwardContentActionHandler.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/2/6.
//

import Foundation
import LarkCore
import LarkModel
import LarkMessageBase
import LarkMessengerInterface

final class MergeForwardContentActionHandler<C: MergeForwardContentViewModelContext>: ComponentActionHandler<C> {
    func tapAction(chat: Chat, message: Message) {
        let body: MergeForwardDetailBody
        if chat.id == message.channel.id {
            body = MergeForwardDetailBody(message: message, chat: chat, downloadFileScene: context.downloadFileScene)
        } else {
            body = MergeForwardDetailBody(message: message, chatId: message.channel.id, downloadFileScene: context.downloadFileScene)
        }
        if self.context.scene == .threadChat || self.context.scene == .newChat {
            IMTracker.Chat.Main.Click.Msg.MergeForward(chat, message, context.trackParams[PageContext.TrackKey.sceneKey] as? String)
        } else if self.context.scene == .threadDetail || self.context.scene == .replyInThread {
            ChannelTracker.TopicDetail.Click.Msg.MergeForward(chat, message)
        }
        context.navigator(type: .push, body: body, params: nil)
    }
}
