//
//  TodoMenuHandler.swift
//  LarkMessageCore
//
//  Created by 夏汝震 on 2020/11/27.
//

import UIKit
import Foundation
import LarkMessageBase
import LarkModel
import LarkMessengerInterface
import LarkCore
import LarkContainer
import RustPB
import LarkSDKInterface
import LarkUIKit

public struct MessageCoreTodoBody {
    public enum FromContent {
        case chatKeyboard(richContent: Basic_V1_RichContent?)
        case chatSetting
        case textMessage(richContent: Basic_V1_RichContent)
        case postMessage(title: String, richContent: Basic_V1_RichContent)
        case threadMessage(title: String, richContent: Basic_V1_RichContent?, threadId: String)
        case mergeForwardMessage(messageId: String, chatName: String)
        case multiSelectMessages(messageIds: [String], chatName: String)
        case needsMergeMessage(messageId: String, title: String)
        case unknownMessage
    }
    public let chatID: String
    public let chatName: String
    public let messageId: String?
    public let threadId: String?
    public let fromContent: FromContent
    public let isThread: Bool
    public let atUsers: Set<String>?
    public let extra: [String: Any]?
    public let chatCommonParams: [AnyHashable: Any]?
    public init(
        chatID: String,
        chatName: String,
        messageId: String?,
        threadId: String?,
        fromContent: FromContent,
        isThread: Bool,
        atUsers: Set<String>? = nil,
        extra: [String: Any]? = nil,
        chatCommonParams: [AnyHashable: Any]? = nil
    ) {
        self.chatID = chatID
        self.chatName = chatName
        self.messageId = messageId
        self.threadId = threadId
        self.fromContent = fromContent
        self.isThread = isThread
        self.atUsers = atUsers
        self.extra = extra
        self.chatCommonParams = chatCommonParams
    }
}

public protocol MessageCoreTodoDependency {
    func createTodo(body: MessageCoreTodoBody, from: UIViewController, prepare: @escaping (UIViewController) -> Void, animated: Bool)
}

public extension MessageCoreTodoDependency {
    func createTodo(body: MessageCoreTodoBody, from: UIViewController) {
        var fixedBody = MessageCoreTodoBody(
            chatID: body.chatID,
            chatName: body.chatName,
            messageId: body.messageId,
            threadId: body.threadId,
            fromContent: body.fromContent,
            isThread: body.isThread,
            atUsers: body.atUsers,
            extra: body.extra,
            chatCommonParams: body.chatCommonParams
        )
        createTodo(body: fixedBody, from: from, prepare: { $0.modalPresentationStyle = .formSheet }, animated: true)
    }

    // 会话 + 号
    func createTodo(from: UIViewController, chat: Chat, richContent: Basic_V1_RichContent?) {
        let body = MessageCoreTodoBody(
            chatID: chat.id,
            chatName: chat.name,
            messageId: nil,
            threadId: nil,
            fromContent: .chatKeyboard(richContent: richContent),
            isThread: chat.chatMode == .threadV2,
            chatCommonParams: IMTracker.Param.chat(chat)
        )
        createTodo(body: body, from: from)
    }

    // 单条消息，包含话题的评论
    func createTodo(from: UIViewController, chat: Chat, message: Message, extra: [String: Any]?, lynxcardRenderFG: Bool) {
        var fromContent: MessageCoreTodoBody.FromContent = .unknownMessage
        var atUsers = Set<String>()
        switch message.type {
        case .text:
            if let textContent = message.content as? TextContent {
                let richContent = makeRichContent(
                    with: textContent.richText,
                    docEntity: textContent.docEntity ?? .init(),
                    hangPoints: message.urlPreviewHangPointMap,
                    hangEntities: textContent.inlinePreviewEntities
                )
                fromContent = .textMessage(richContent: richContent)
                atUsers = textContent.atUserIdsSet
            }
        case .post:
            if let postContent = message.content as? PostContent {
                let richContent = makeRichContent(
                    with: postContent.richText,
                    docEntity: postContent.docEntity ?? .init(),
                    hangPoints: message.urlPreviewHangPointMap,
                    hangEntities: postContent.inlinePreviewEntities
                )
                fromContent = .postMessage(title: postContent.title, richContent: richContent)
                if postContent.title.isEmpty {
                    atUsers = postContent.atUserIdsSet
                }
            }
        case .mergeForward:
            fromContent = .mergeForwardMessage(messageId: message.id, chatName: chat.name)
        @unknown default:
            let needsMergeMessageTypes: [LarkModel.Message.TypeEnum] = [
                .file, .folder, .audio, .image, .media, .location, .sticker,
                .todo, .videoChat, .shareGroupChat, .shareUserCard,
                .shareCalendarEvent, .generalCalendar, .calendar,
                .hongbao, .card, .vote
            ]
            if needsMergeMessageTypes.contains(message.type) {
                fromContent = .needsMergeMessage(messageId: message.id, title: todoTitle(from: message, with: chat, lynxcardRenderFG: lynxcardRenderFG))
            } else {
                fromContent = .unknownMessage
            }
        }
        let isThread = chat.chatMode == .threadV2
        if let fromUserId = message.parentMessage?.fromId, !isThread {
            atUsers.remove(fromUserId)
        }
        let body = MessageCoreTodoBody(
            chatID: chat.id,
            chatName: chat.name,
            messageId: message.id,
            threadId: message.threadId,
            fromContent: fromContent,
            isThread: chat.chatMode == .threadV2,
            atUsers: atUsers,
            extra: extra,
            chatCommonParams: IMTracker.Param.chat(chat)
        )
        createTodo(body: body, from: from)
    }

    // 多选消息，threaid 在多选话题评论时有效
    func createTodo(from: UIViewController, chat: Chat, threadId: String, messageIDs: [String], extra: [String: Any]?) {
        let body = MessageCoreTodoBody(
            chatID: chat.id,
            chatName: chat.name,
            messageId: threadId.isEmpty ? nil : threadId,
            threadId: threadId,
            fromContent: .multiSelectMessages(messageIds: messageIDs, chatName: chat.name),
            isThread: chat.chatMode == .threadV2,
            extra: extra,
            chatCommonParams: IMTracker.Param.chat(chat)
        )
        createTodo(body: body, from: from)
    }

    // 话题整体转任务
    func createTodo(
        from: UIViewController,
        chat: Chat,
        threadID: String,
        threadMessage: ThreadMessage,
        title: String,
        extra: [String: Any]?
    ) {
        createTodo(
            from: from,
            chat: chat,
            threadID: threadID,
            message: threadMessage.rootMessage,
            title: title,
            extra: extra
        )
    }

    // 上一个方法的兼容 Menu 改造版本，等 menu 改造全量后，需要删除上面那个方法
    func createTodo(
        from: UIViewController,
        chat: Chat,
        threadID: String,
        message: Message,
        title: String,
        extra: [String: Any]?
    ) {
        var title = title
        var richContent: Basic_V1_RichContent?
        var atUsers = Set<String>()
        if message.type == .text, let textContent = message.content as? TextContent {
            richContent = makeRichContent(
                with: textContent.richText,
                docEntity: textContent.docEntity ?? .init(),
                hangPoints: [:],
                hangEntities: [:]
            )
            atUsers = textContent.atUserIdsSet
        } else if message.type == .post, let textContent = message.content as? PostContent {
            richContent = makeRichContent(
                with: textContent.richText,
                docEntity: textContent.docEntity ?? .init(),
                hangPoints: [:],
                hangEntities: [:]
            )
            atUsers = textContent.atUserIdsSet
        } else if message.type == .mergeForward {
            title = "" // 对齐单条消息创建方法，需要对 mergeForward 类型单独处理
        }
        let body = MessageCoreTodoBody(
            chatID: chat.id,
            chatName: chat.name,
            messageId: threadID,
            threadId: threadID,
            fromContent: .threadMessage(title: title, richContent: richContent, threadId: threadID),
            isThread: chat.chatMode == .threadV2,
            atUsers: atUsers,
            extra: extra,
            chatCommonParams: IMTracker.Param.chat(chat)
        )
        createTodo(body: body, from: from)
    }

    private func todoTitle(from message: Message, with chat: Chat, lynxcardRenderFG: Bool) -> String {
        var title = MessageSummarizeUtil.getSummarize(message: message, lynxcardRenderFG: lynxcardRenderFG)
        switch message.type {
        case .image, .media:
            if chat.chatMode == .threadV2 {
                title = BundleI18n.LarkMessageCore.Todo_Task_FromTopic(chat.name)
            } else {
                title = BundleI18n.LarkMessageCore.Todo_Task_FromChat(chat.name)
            }
        case .vote:
            title = BundleI18n.LarkMessageCore.Lark_IM_Poll_PollMessage_Text
        case .calendar, .generalCalendar:
            title = BundleI18n.LarkMessageCore.Calendar_CreateTaskFromEvent_TaskTitle(title)
        case .card:
            if let headerTitle = (message.content as? CardContent)?.header.title, !headerTitle.isEmpty {
                title = headerTitle
            }
        case .todo:
            if let todoContent = message.content as? TodoContent,
               todoContent.pbModel.operationType == .dailyRemind {
                title = BundleI18n.LarkMessageCore.Todo_Task_RecentTodoTask
            }
        @unknown default:
            break
        }
        return title
    }
}

public func makeRichContent(
    with richText: RustPB.Basic_V1_RichText,
    docEntity: RustPB.Basic_V1_DocEntity,
    hangPoints: [String: RustPB.Basic_V1_UrlPreviewHangPoint],
    hangEntities: [String: InlinePreviewEntity]
) -> RustPB.Basic_V1_RichContent {
    var richContent = RustPB.Basic_V1_RichContent()
    richContent.richText = richText
    richContent.docEntity = docEntity
    richContent.urlPreviewHangPoints = .init()
    richContent.urlPreviewEntities = .init()
    richContent.fakePreviewIds = .init()
    for (eleId, ele) in richText.elements where ele.tag == .a {
        guard
            let point = hangPoints[eleId],
            let msgEntity = hangEntities[point.previewID]
        else {
            continue
        }
        var entity = Basic_V1_UrlPreviewEntity()
        entity.version = msgEntity.version
        entity.sourceID = msgEntity.sourceID
        entity.previewID = msgEntity.previewID
        if let udIcon = msgEntity.udIcon {
            entity.udIcon = udIcon
        }
        entity.useColorIcon = msgEntity.useColorIcon
        if let header = msgEntity.unifiedHeader {
            entity.unifiedHeader = header
        }
        if let url = msgEntity.url {
            entity.url = url
        }
        if let title = msgEntity.title {
            entity.serverTitle = title
            entity.sdkTitle = title
        }
        if let iconKey = msgEntity.iconKey {
            entity.serverIconKey = iconKey
        }
        if let iconUrl = msgEntity.iconUrl {
            entity.sdkIconURL = iconUrl
        }
        if let tag = msgEntity.tag {
            entity.serverTag = tag
        }
        richContent.urlPreviewHangPoints[eleId] = point
        richContent.urlPreviewEntities.previewEntity[entity.previewID] = entity
        richContent.fakePreviewIds.append(entity.previewID)
    }
    return richContent
}
