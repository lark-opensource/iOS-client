//
//  TodoContent.swift
//  LarkModel
//
//  Created by 张威 on 2020/12/2.
//

import Foundation
import RustPB

public struct TodoContent: MessageContent {
    public typealias PBModel = RustPB.Basic_V1_TodoOperationContent

    public let pbModel: PBModel

    public init(pbModel: PBModel) {
        self.pbModel = pbModel
    }

    public static func transform(pb: PBModel) -> MessageContent {
        switch pb.operationType {
        case .update, .assign, .complete, .cancel, .delete, .create, .incomplete, .share,
             .createComment, .replyComment, .follow, .unfollow, .dailyRemind, .reactComment,
             .completeAssignee, .completeSelf, .restoreAssignee, .restoreSelf, .assignOwner:
            return TodoContent(pbModel: pb)
        case .unknown:
            return UnknownContent()
        @unknown default:
            assertionFailure()
            return UnknownContent()
        }
    }

    public var isFromBot = false
    // 提供给 Todo 分享卡片获得推荐执行者数据使用
    public var chatId = ""
    // 关注 / 取消关注按钮，在和 chat 相关的场景需要 messageId
    public var messageId = ""
    // 发送者 ID
    public var senderId = ""
    // 是否来自话题群
    public var isFromThread = false

    public mutating func complement(entity: RustPB.Basic_V1_Entity, message: Message) {
        guard let pb = entity.messages[message.id],
              let chat = entity.chats[pb.chatID],
              let chatters = entity.chatChatters[pb.chatID]?.chatters else { return }
        isFromBot = chat.type == .p2P && chatters.values.contains(where: { $0.type == .bot })
        isFromThread = chat.chatMode == .threadV2
        chatId = pb.chatID
        messageId = message.id
        senderId = pb.fromID
    }
}
