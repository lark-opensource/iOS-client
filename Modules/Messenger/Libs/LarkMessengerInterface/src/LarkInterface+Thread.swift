//
//  LarkInterface+Thread.swift
//  LarkInterface
//
//  Created by liuwanlin on 2019/2/13.
//

import Foundation
import LarkModel
import EENavigator
import SuiteCodable
import LarkSDKInterface
import RustPB
// 小组
public struct ThreadChatComposePostBody: PlainBody {
    public static let pattern: String = "//client/chat/thread/chatComposePost"

    public let chat: Chat
    public let isDefaultTopicGroup: Bool
    public let multiEditingMessage: Message?
    public let pasteBoardToken: String

    public init(chat: Chat,
                isDefaultTopicGroup: Bool,
                pasteBoardToken: String,
                multiEditingMessage: Message?) {
        self.isDefaultTopicGroup = isDefaultTopicGroup
        self.chat = chat
        self.pasteBoardToken = pasteBoardToken
        self.multiEditingMessage = multiEditingMessage
    }
}

public struct ThreadChatByIDBody: CodableBody {
    private static let prefix = "//client/chat/thread/by/id"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:chatID(\\d+)", type: .path)
    }

    public var _url: URL {
        if let position = position {
            return URL(string: "\(ThreadChatByIDBody.prefix)/\(chatID)#\(position)") ?? .init(fileURLWithPath: "")
        }
        return URL(string: "\(ThreadChatByIDBody.prefix)/\(chatID)") ?? .init(fileURLWithPath: "")
    }

    public let chatID: String
    public let position: Int32?
    public let fromWhere: ChatFromWhere

    public init(
        chatID: String,
        position: Int32? = nil,
        fromWhere: ChatFromWhere = .ignored
    ) {
        self.chatID = chatID
        self.position = position
        self.fromWhere = fromWhere
    }
}

public struct ThreadPreviewByIDBody: PlainBody {
    public static let pattern = "//client/chat/threadPreviewByID"
    public let chatID: String
    public let position: Int32?
    public let fromWhere: ChatFromWhere

    public init(
        chatID: String,
        position: Int32? = nil,
        fromWhere: ChatFromWhere = .ignored
    ) {
        self.chatID = chatID
        self.position = position
        self.fromWhere = fromWhere
    }
}

/// Using this method requires manual synchronization of the latest chat data. recommend use ChatControllerByIdBody
public struct ThreadChatByChatBody: Body {
    private static let prefix = "//client/chat/thread/by/chat"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:chatId(\\d+)", type: .path)
    }

    public var _url: URL {
        if let position = position {
            return URL(string: "\(ThreadChatByChatBody.prefix)/\(chat.id)#\(position)") ?? .init(fileURLWithPath: "")
        }
        return URL(string: "\(ThreadChatByChatBody.prefix)/\(chat.id)") ?? .init(fileURLWithPath: "")
    }

    public let chat: Chat
    public let position: Int32?
    /// for track enter cost
    public let startEnter: Double
    public let fromWhere: ChatFromWhere

    public init(chat: Chat, position: Int32? = nil, startEnter: Double = 0, fromWhere: ChatFromWhere = .ignored) {
        self.chat = chat
        self.position = position
        self.startEnter = startEnter
        self.fromWhere = fromWhere
    }
}

public enum ThreadDetailLoadType: String, Codable, HasDefault {
    case unread
    case position
    case justReply
    case root

    public static func `default`() -> ThreadDetailLoadType {
        return .unread
    }
}

/// 进入话题详情的来源
public enum ThreadDetailFromSourceType: String, Codable, HasDefault {
    case feed
    case chat
    case recommendList
    case notification
    case other

    public static func `default`() -> ThreadDetailFromSourceType {
        return .other
    }
}

/// 进入reply in Thread详情的来源
public enum ReplyInThreadFromSourceType: String, Codable, HasDefault {
    case feed
    case chat
    case applink
    case notification
    case search
    case forward_card
    case other
    public static func `default`() -> ReplyInThreadFromSourceType {
        return .other
    }
}

/// 跳转私有话题圈转发
public struct ThreadPostForwardDetailBody: Body {

    private static let prefix = "//client/chat/thread/postForwardDetail"
    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:messageId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(ThreadPostForwardDetailBody.prefix)/\(message.id)-\(openWithMergeForwardContentPrior)") ?? .init(fileURLWithPath: "")
    }
    public let message: Message
    public let chat: Chat
    public let originMergeForwardId: String

    //在一些边缘case，可能两个话题对应对应同一个根消息。其中一个话题需要用MergeForwardContent来渲染，另一个话题需要用MessageThread来渲染。
    //当openWithMergeForwardContentPrior为ture，会优先用MergeForwardContent来渲染；否则优先用MessageThread来渲染。
    public let openWithMergeForwardContentPrior: Bool

    public init(originMergeForwardId: String,
                message: Message,
                chat: Chat,
                openWithMergeForwardContentPrior: Bool = false) {
        self.originMergeForwardId = originMergeForwardId
        self.chat = chat
        self.message = message
        self.openWithMergeForwardContentPrior = openWithMergeForwardContentPrior
    }
}
/// 当场景下无法确认或者较难区分Thread是MsgThread还是topic thread的时候，可以使用该body
public struct ThreadDetailUniversalIDBody: CodableBody {
    private static let prefix = "//client/chat/thread/universal/detail"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:threadId(\\d+)", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(ThreadDetailUniversalIDBody.prefix)/\(threadId)") ?? .init(fileURLWithPath: "")
    }

    public let threadId: String
    public let chatID: String
    public let loadType: ThreadDetailLoadType
    public var position: Int32?
    public var keyboardStartupState: KeyboardStartupState

    /// 跳入推荐列表的来源
    public let sourceType: ThreadDetailFromSourceType

    public init(
        chatID: String,
        threadId: String,
        loadType: ThreadDetailLoadType = .unread,
        position: Int32? = -1,
        keyboardStartupState: KeyboardStartupState = KeyboardStartupState(type: .none),
        sourceType: ThreadDetailFromSourceType = .other) {
        self.chatID = chatID
        self.threadId = threadId
        self.loadType = loadType
        self.position = position
        self.keyboardStartupState = keyboardStartupState
        self.sourceType = sourceType
    }
}

/// for get latest chat thread and rootMessage must fetch from SDK.获取Chat thread rootMessage会使用forceRemote == false，直接从SDK拿数据，如果SDK没有才走网络。
public struct ThreadDetailByIDBody: CodableBody {
    private static let prefix = "//client/chat/thread/detail"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:threadId(\\d+)", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(ThreadDetailByIDBody.prefix)/\(threadId)") ?? .init(fileURLWithPath: "")
    }

    public let threadId: String
    public let loadType: ThreadDetailLoadType
    public var position: Int32?
    public var keyboardStartupState: KeyboardStartupState

    /// 跳入推荐列表的来源
    public let sourceType: ThreadDetailFromSourceType

    public var specificSource: SpecificSourceFromWhere? //二级来源
    public init(
        threadId: String,
        loadType: ThreadDetailLoadType = .unread,
        position: Int32? = -1,
        keyboardStartupState: KeyboardStartupState = KeyboardStartupState(type: .none),
        sourceType: ThreadDetailFromSourceType = .other,
        specificSource: SpecificSourceFromWhere? = nil) {
        self.threadId = threadId
        self.loadType = loadType
        self.position = position
        self.keyboardStartupState = keyboardStartupState
        self.sourceType = sourceType
        self.specificSource = specificSource
    }
}

/// 普通话题详情内容预览Body，暂时放在Thread仓，后期考虑拆分出独立仓库
public struct ThreadDetailPreviewByIDBody: CodableBody {
    private static let prefix = "//client/chat/thread/detailPreview"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:threadId(\\d+)", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(ThreadDetailPreviewByIDBody.prefix)/\(threadId)") ?? .init(fileURLWithPath: "")
    }

    public let threadId: String
    public let loadType: ThreadDetailLoadType
    public var position: Int32?

    public init(
        threadId: String,
        loadType: ThreadDetailLoadType = .root,
        position: Int32? = -1) {
        self.threadId = threadId
        self.loadType = loadType
        self.position = position
    }
}

/// 消息话题详情内容预览Body，暂时放在Thread仓，后期考虑拆分出独立仓库
public struct MsgThreadDetailPreviewByIDBody: CodableBody {
    private static let prefix = "//client/chat/msgThread/detailPreview"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:threadId(\\d+)", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(MsgThreadDetailPreviewByIDBody.prefix)/\(threadId)") ?? .init(fileURLWithPath: "")
    }

    public let threadId: String
    public let loadType: ThreadDetailLoadType
    public var position: Int32?

    public init(
        threadId: String,
        loadType: ThreadDetailLoadType = .root,
        position: Int32? = -1) {
        self.threadId = threadId
        self.loadType = loadType
        self.position = position
    }
}

/// if Chat TopicGroup ThreadMessage not the latest data. need set needUpdateBlockData is true
public struct ThreadDetailByModelBody: Body {
    private static let prefix = "//client/chat/thread/detail/by/model"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:threadId", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(ThreadDetailByModelBody.prefix)/\(threadMessage.thread.id)") ?? .init(fileURLWithPath: "")
    }

    public let chat: Chat
    public let topicGroup: TopicGroup
    public var threadMessage: ThreadMessage
    /// fetch latest data for chat topicGroup and threadMessage
    public let needUpdateBlockData: Bool
    public let loadType: ThreadDetailLoadType
    public var position: Int32?
    public var keyboardStartupState: KeyboardStartupState
    public let sourceType: ThreadDetailFromSourceType

    public init(
        chat: Chat,
        topicGroup: TopicGroup,
        sourceType: ThreadDetailFromSourceType = .other,
        threadMessage: ThreadMessage,
        needUpdateBlockData: Bool = false,
        loadType: ThreadDetailLoadType,
        position: Int32? = -1,
        keyboardStartupState: KeyboardStartupState = KeyboardStartupState(type: .none)) {
        self.chat = chat
        self.topicGroup = topicGroup
        self.sourceType = sourceType
        self.threadMessage = threadMessage
        self.needUpdateBlockData = needUpdateBlockData
        self.loadType = loadType
        self.position = position
        self.keyboardStartupState = keyboardStartupState
    }
}

public struct ReplyInThreadByIDBody: CodableBody {

    private static let prefix = "//client/chat/reply/in/thread"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:threadId(\\d+)", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(ReplyInThreadByIDBody.prefix)/\(threadId)") ?? .init(fileURLWithPath: "")
    }

    public let threadId: String
    public let loadType: ThreadDetailLoadType
    public var position: Int32?
    public var keyboardStartupState: KeyboardStartupState
    public let chatFromWhere: ChatFromWhere

    /// 跳入列表的来源
    public let sourceType: ReplyInThreadFromSourceType
    public var specificSource: SpecificSourceFromWhere? //二级来源

    public init(
        threadId: String,
        loadType: ThreadDetailLoadType = .root,
        position: Int32? = -1,
        keyboardStartupState: KeyboardStartupState = KeyboardStartupState(type: .none),
        sourceType: ReplyInThreadFromSourceType = .other,
        chatFromWhere: ChatFromWhere = .ignored,
        specificSource: SpecificSourceFromWhere? = nil) {
        self.threadId = threadId
        self.loadType = loadType
        self.position = position
        self.keyboardStartupState = keyboardStartupState
        self.sourceType = sourceType
        self.chatFromWhere = chatFromWhere
        self.specificSource = specificSource
    }
}
public struct ReplyInThreadByModelBody: Body {

    private static let prefix = "//client/chat/reply/in/thread/by/model"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:threadId(\\d+)", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(ReplyInThreadByModelBody.prefix)/\(threadId)") ?? .init(fileURLWithPath: "")
    }

    public let message: Message
    /// 这里传入chat可以优化加载速度
    public let chat: Chat?
    public let loadType: ThreadDetailLoadType
    public var position: Int32?
    public var keyboardStartupState: KeyboardStartupState
    /// 跳入列表的来源
    public let sourceType: ReplyInThreadFromSourceType
    public let chatFromWhere: ChatFromWhere

    public var threadId: String {
        return !message.threadId.isEmpty ? message.threadId : message.id
    }

    public init(
        message: Message,
        chat: Chat?,
        loadType: ThreadDetailLoadType = .root,
        position: Int32? = -1,
        keyboardStartupState: KeyboardStartupState = KeyboardStartupState(type: .none),
        sourceType: ReplyInThreadFromSourceType = .other,
        chatFromWhere: ChatFromWhere = .ignored) {
        self.message = message
        self.chat = chat
        self.loadType = loadType
        self.position = position
        self.keyboardStartupState = keyboardStartupState
        self.sourceType = sourceType
        self.chatFromWhere = chatFromWhere
    }
}

/// 服务端下发url，端上openUrl打开。（不要删除此body）
/// 场景：分享公开群里的话题走动态卡片会下发url，私有群分享话题走合并转发形态。
public struct OpenShareThreadTopicBody: CodableBody {
    private static let prefix = "//client/openthread"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)")
    }

    public var _url: URL {
        return URL(string: "\(OpenShareThreadTopicBody.prefix)") ?? .init(fileURLWithPath: "")
    }

    public let threadid: String
    public let chatid: String

    public init(threadid: String, chatid: String) {
        self.threadid = threadid
        self.chatid = chatid
    }
}
