//
//  ChatTodoCellData.swift
//  Todo
//
//  Created by 白言韬 on 2021/4/13.
//

import Foundation

struct ChatTodoCellData {

    var contentData: V3ListContentData?

    var senderTitle: String?

    var type: ChatTodoSectionType?

    var chatTodo: Rust.ChatTodo
    var completeState: CompleteState

    init(with todo: Rust.ChatTodo, completeState: CompleteState) {
        self.chatTodo = todo
        self.completeState = completeState
    }

}
