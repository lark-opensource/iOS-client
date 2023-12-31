//
//  MeegoNativeDependency.swift
//  LarkMeego
//
//  Created by shizhengyu on 2021/9/14.
//

import Foundation
import LarkModel

public struct ChatMessageInfo {
    public let chat: Chat?
    public let messages: [Message]

    public init(chat: Chat?, messages: [Message]) {
        self.chat = chat
        self.messages = messages
    }
}

public protocol MeegoNativeDependency {
    /// 通过快捷应用的 triggerId 获取本地 chat 和 message 信息（同步）
    /// 如果本地查询不到，则返回空
    func getChatAndMessages(by triggerId: String) -> ChatMessageInfo?
}
