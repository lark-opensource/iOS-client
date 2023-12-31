//
//  CreateTodo.swift
//  TodoInterface
//
//  Created by 张威 on 2021/1/25.
//

import EENavigator
import RxSwift
import RustPB

/// 新建 Todo
public struct TodoCreateBody: PlainBody {

    public static let pattern = "//client/todo/create"

    public var sourceContext: SourceContext

    public init(sourceContext: SourceContext) {
        self.sourceContext = sourceContext
    }

}

extension TodoCreateBody {

    public enum SourceContext {
        case chat(ChatSourceContext)
    }

    /// 基于会话创建 Todo 的上下文
    public struct ChatSourceContext {

        public var chatId: String
        public var chatName: String
        public var messageId: String? // 某些情况下可能为 threadId，为了兼容旧场景，不再调整
        public var threadId: String? // 始终为 threadId 原意，非 thread 则为空
        public var fromContent: FromContent
        public var isThread: Bool // 当前 chat 是否为话题群

        /// 消息转 Todo 时，@ 的人会自动解析为执行者 (该功能已废弃，后续删除 TODO: byt)
        public var atUsers: Set<String>?
        /// 该字段目前为话题转 Todo 埋点所用
        public var extra: [String: Any]?
        /// 会话引导: bottom margin在连续创建的时候会用到
        public var chatGuideHandler: ((_ bottomMargin: CGFloat?) -> Void)?
        /// 会话公参
        public var chatCommonParams: [AnyHashable: Any]?

        // nolint: long parameters
        public init(
            chatId: String,
            chatName: String,
            messageId: String?,
            threadId: String?,
            fromContent: FromContent,
            isThread: Bool
        ) {
            self.chatId = chatId
            self.chatName = chatName
            self.messageId = messageId
            self.threadId = threadId
            self.fromContent = fromContent
            self.isThread = isThread
        }
        // enable-lint: long parameters

        public typealias RichContent = Basic_V1_RichContent

        public enum FromContent {
            // 来自会话 keyboard
            case chatKeyboard(richContent: RichContent?)
            // 来自会话 setting
            case chatSetting
            // 来自 text 消息
            case textMessage(richContent: RichContent)
            // 来自 post 消息
            case postMessage(title: String, richContent: RichContent)
            // 来自 Thread 消息
            case threadMessage(title: String, richContent: RichContent?, threadId: String)
            // 需要被当做合并消息
            case needsMergeMessage(messageId: String, title: String)
            // 来自 mergeForward 消息（合并转发消息）
            case mergeForwardMessage(messageId: String, chatName: String)
            // 来自多选消息
            case multiSelectMessages(messageIds: [String], chatName: String)
            // 未知消息
            case unknownMessage
        }
    }
}

extension TodoCreateBody.ChatSourceContext.FromContent {
    public func dubugInfo() -> String {
        switch self {
        case .chatKeyboard:
            return "type: chatKeyboard"
        case .chatSetting:
            return "type: chatSetting"
        case .textMessage:
            return "type: textMessage"
        case .postMessage:
            return "type: postMessage"
        case .threadMessage(_, _, let threadId):
            return "type: threadMessage, threadId: \(threadId)"
        case .needsMergeMessage(let messageId, _):
            return "type: needsMergeMessage, messageId: \(messageId)"
        case .mergeForwardMessage(let messageId, _):
            return "type: mergeForwardMessage, messageId: \(messageId)"
        case .multiSelectMessages(let messageIds, _):
            return "type: multiSelectMessages, messageIds: \(messageIds)"
        case .unknownMessage:
            return "type: unknownMessage"
        }
    }
}
