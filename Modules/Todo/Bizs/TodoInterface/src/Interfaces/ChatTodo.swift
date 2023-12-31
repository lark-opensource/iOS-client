//
//  ChatTodo.swift
//  TodoInterface
//
//  Created by 张威 on 2021/3/31.
//

import EENavigator

/// Chat Todo

public struct ChatTodoBody: CodablePlainBody {
    public static let pattern = "//client/chat/todo"

    public let chatId: String
    public let isFromThread: Bool

    public init(chatId: String, isFromThread: Bool) {
        self.chatId = chatId
        self.isFromThread = isFromThread
    }
}
