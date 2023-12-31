//
//  ChatMessageViewModelDelegate.swift
//  ByteView
//
//  Created by chenyizhuo on 2021/12/30.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork

protocol ChatMessageViewModelDelegate: AnyObject {
    /// 消息变更时的总回调，一定在主线程执行
    func messagesDidChange(messages: [ChatMessageCellModel])
    /// 未读消息数量变更时的回调，一定在主线程执行
    func numberOfUnreadMessagesDidChange(count: Int)
    /// 从服务端收到新的未读消息，不包括自己从服务端查的未读消息，用于展示消息气泡，一定在主线程执行
    func didReceiveNewUnreadMessage(_ unreadMessage: ChatMessageCellModel)
    /// 翻译内容变更，收到翻译结果时调用，一定在主线程执行。sources 指定这些翻译的方式：自动或手动翻译
    func translationResultDidChange(sources: [String: TranslateSource])
    /// 翻译设置变更，整个列表需要重新刷新（触发重新自动翻译），一定在主线程执行
    func translationInfoDidChange()
    /// 用户本人发送了一条消息时的回调，一定在主线程执行
    func didSendMessage(_ message: ChatMessageCellModel)
    /// 当前聊天消息展示情况，一定在主线程执行
    func chatMessageViewShowingDidChange(isShowing: Bool)
}

extension ChatMessageViewModelDelegate {
    func messagesDidChange(messages: [ChatMessageCellModel]) {}
    func didReceiveNewUnreadMessage(_ unreadMessage: ChatMessageCellModel) {}
    func translationResultDidChange(sources: [String: TranslateSource]) {}
    func translationInfoDidChange() {}
    func numberOfUnreadMessagesDidChange(count: Int) {}
    func didSendMessage(_ message: ChatMessageCellModel) {}
    func chatMessageViewShowingDidChange(isShowing: Bool) {}
}
