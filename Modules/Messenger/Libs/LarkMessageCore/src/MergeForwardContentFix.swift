//
//  MergeForwardContentFix.swift
//  LarkChat
//
//  Created by ByteDance on 2022/8/18.
//

import Foundation
import RustPB
import LarkModel

/// subMessages有时数据携带不全，需要自己填充chatter和parentMsg等信息
public func fixMergeForwardContent(_ message: Message) -> [Message] {
    guard let content = message.content as? MergeForwardContent else {
        return []
    }

    if message.fatherMFMessage == nil {
        message.mergeMessageIdPath = [message.id]
    }

    let rootMessage = message
    let messages = content.messages
    let messageIds = messages.map({ $0.id })
    var channel = RustPB.Basic_V1_Channel()
    channel.id = message.chatID
    channel.type = .chat
    //拼chatter/parentMsg/syncToChatThreadRootMessage
    for message in messages {
        if let fromChatChatters = content.fromChatChatters,
           let pb = fromChatChatters[message.fromId] {
            message.fromChatter = Chatter.transform(pb: pb)
            if let reactionInfo = content.messageReactionInfo[message.id] {
                let reactions = reactionInfo.reactions.map { (reactionData) -> Reaction in
                    let reaction = Reaction(type: reactionData.type, chatterIds: reactionData.chatterIds, chatterCount: reactionData.count)
                    reaction.chatters = reactionData.chatterIds.compactMap({ userID in
                        if let value = content.fromChatChatters?[userID] {
                            return Chatter.transform(pb: value)
                        }
                         return nil
                    })
                    return reaction
                }
                message.reactions = reactions
            }
        }
        if let parentIndex = messageIds.firstIndex(where: { return $0 == message.parentId }) {
            message.parentMessage = messages[parentIndex]
        }
        if let rootIndex = messageIds.firstIndex(where: { return $0 == message.syncToChatThreadRootID }) {
            message.syncToChatThreadRootMessage = messages[rootIndex]
        }
        message.channel = channel
        message.fatherMFMessage = rootMessage
        var tempIDPath = rootMessage.mergeMessageIdPath
        tempIDPath.append(message.id)
        message.mergeMessageIdPath = tempIDPath
    }
    // 拼接replyInThreadLastReplies
    for message in messages {
        // 避免重复调用fixMergeForwardContent
        guard message.replyInThreadLastReplies.isEmpty else { continue }
        guard let messageThreads = content.messageThreads[Int64(message.id) ?? 0] else { continue }
        // 取最后的5条消息，和群内逻辑保持一致
        messageThreads.messages.suffix(5).forEach { messagePB in
            guard let currMessage = try? Message.transform(pb: messagePB) else { return }
            guard let fromChatChatters = content.fromChatChatters, let chatterPB = fromChatChatters[currMessage.fromId] else { return }
            currMessage.fromChatter = Chatter.transform(pb: chatterPB)
            message.replyInThreadLastReplies.append(currMessage)
        }
    }
    return messages
}
