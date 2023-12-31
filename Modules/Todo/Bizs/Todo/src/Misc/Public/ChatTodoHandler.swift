//
//  ChatTodoHandler.swift
//  LarkTodo
//
//  Created by 白言韬 on 2021/4/8.
//

import Foundation
import TodoInterface
import Swinject
import EENavigator
import LarkNavigator

final class ChatTodoHandler: UserTypedRouterHandler {

    func handle(_ body: ChatTodoBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        V3Home.trackEvent(.viewList, with: ["source": "chat_todo_list"])
        let vm = ChatTodoViewModel(resolver: userResolver, chatId: body.chatId, isFromThread: body.isFromThread)
        let vc = ChatTodoViewController(resolver: userResolver, viewModel: vm)
        res.end(resource: vc)
    }
}
