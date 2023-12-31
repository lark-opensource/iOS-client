//
//  ForwardThreadContentActionHandler.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2023/3/29.
//

import Foundation
import LarkModel
import EENavigator
import AsyncComponent
import LarkMessageBase
import LarkMessengerInterface

/// 「转发话题外露回复」需求：话题回复、话题使用一套逻辑 & 使用嵌套UI
final class ForwardThreadContentActionHandler<C: ViewModelContext>: ComponentActionHandler<C> {
    private let currentChatterId: String
    init(context: C, currentChatterId: String) {
        self.currentChatterId = currentChatterId
        super.init(context: context)
    }
    /// 点击嵌套区域，跳转到内一层话题
    func tapAction(chat: Chat, message: Message, content: MergeForwardContent?) {
        guard let content = message.content as? MergeForwardContent, let thread = content.thread else { return }
        if ReplyInThreadMergeForwardDataManager.isChatMember(content: content, currentChatterId: self.currentChatterId) {
            if ReplyInThreadMergeForwardDataManager.isReplyInThreadData(content: content) {
                let body = ReplyInThreadByIDBody(threadId: thread.id, sourceType: .forward_card)
                self.context.navigator(type: .push, body: body, params: nil)
            } else {
                let body = ThreadDetailByIDBody(threadId: thread.id)
                self.context.navigator(type: .push, body: body, params: nil)
            }
        } else {
            let chat = ReplyInThreadMergeForwardDataManager.getFromChatFor(content: content)
            // 对齐线上：无权限（公开群/私有群里）的话题回复都跳转到快照详情页
            if ReplyInThreadMergeForwardDataManager.isReplyInThreadData(content: content) || !chat.isPublic {
                let body = ThreadPostForwardDetailBody(originMergeForwardId: message.id, message: message, chat: chat)
                self.context.navigator(type: .push, body: body, params: nil)
            } else { // 公开话题群对齐之前的表现，如果未在群，需要先加群
                let body = OpenShareThreadTopicBody(threadid: thread.id, chatid: chat.id)
                self.context.navigator(type: .push, body: body, params: nil)
            }
        }
    }
}
