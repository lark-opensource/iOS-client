//
//  LarkInterface+MessageLink.swift
//  LarkMessengerInterface
//
//  Created by Ping on 2023/6/25.
//

import RxSwift
import LarkModel
import EENavigator

/// 数据拉取能力支持外部注入
public protocol MergeForwardMessageDetailDataSourceService {
    func loadFirstScreenMessages() -> Observable<(messages: [Message], hasMoreNew: Bool, hasMoreOld: Bool, sdkCost: Int64)>
    func loadMoreNewMessages() -> Observable<(messages: [Message], hasMoreNew: Bool, sdkCost: Int64)>
    func loadMoreOldMessages() -> Observable<(messages: [Message], hasMoreOld: Bool, sdkCost: Int64)>
}

public extension MergeForwardMessageDetailDataSourceService {
    func loadFirstScreenMessages() -> Observable<(messages: [Message], hasMoreNew: Bool, hasMoreOld: Bool, sdkCost: Int64)> {
        return .just(([], false, false, 0))
    }
    func loadMoreNewMessages() -> Observable<(messages: [Message], hasMoreNew: Bool, sdkCost: Int64)> {
        return .just(([], false, 0))
    }
    func loadMoreOldMessages() -> Observable<(messages: [Message], hasMoreOld: Bool, sdkCost: Int64)> {
        return .just(([], false, 0))
    }
}

public struct MergeForwardChatInfo {
    public var isAuth: Bool
    public var chatName: String
    public var chatID: String
    public var position: Int32?

    public init(isAuth: Bool,
                chatName: String,
                chatID: String,
                position: Int32? = nil) {
        self.isAuth = isAuth
        self.chatName = chatName
        self.chatID = chatID
        self.position = position
    }
}

public struct MessageLinkDetailBody: Body {
    private static let prefix = "//client/chat/messageLink"
    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)", type: .path)
    }
    public var _url: URL {
        return URL(string: "\(MessageLinkDetailBody.prefix)") ?? .init(fileURLWithPath: "")
    }

    public enum ChatInfo {
        case chat(Chat)
        case chatID(String)
    }

    public let chatInfo: ChatInfo
    public var chatID: String {
        switch chatInfo {
        case .chat(let chat): return chat.id
        case .chatID(let chatID): return chatID
        }
    }
    public let messages: [Message]
    public let dataSourceService: MergeForwardMessageDetailDataSourceService?
    public let title: String
    public let mergeForwardChatInfo: MergeForwardChatInfo?

    public init(
        chatInfo: ChatInfo,
        messages: [Message],
        dataSourceService: MergeForwardMessageDetailDataSourceService?,
        title: String,
        mergeForwardChatInfo: MergeForwardChatInfo?
    ) {
        self.chatInfo = chatInfo
        self.messages = messages
        self.dataSourceService = dataSourceService
        self.title = title
        self.mergeForwardChatInfo = mergeForwardChatInfo
    }
}
