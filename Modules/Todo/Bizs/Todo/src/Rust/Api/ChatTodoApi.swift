//
//  ChatTodoApi.swift
//  Todo
//
//  Created by 白言韬 on 2021/4/8.
//

import RxSwift
import RustPB
import ServerPB

protocol ChatTodoApi {
    /// 根据 chatId 批量获取不需要分页的 ChatTodos：「由我处理」「其他任务」
    /// - Parameter chatId: 指定 chatId
    func getChatTodos(byChatId chatId: String)
        -> Observable<(assignToMe: [Rust.ChatTodo], assignToOther: [Rust.ChatTodo])>

    /// 根据 chatId 批量获取需要分页的 ChatTodos：「已完成」
    /// - Parameters:
    ///   - chatId: 指定 chatId
    ///   - pageCount: 分页数量
    ///   - pageOffset: 分页偏移量。该变量端上仅需要把上一次调用该接口返回的 pageOffset 拿来填充就可以；第一次调用不需要填值
    func getCompletedChatTodos(byChatId chatId: String, pageCount: Int, lastOffset: Int64?)
        -> Observable<(chatTodos: [Rust.ChatTodo], lastOffset: Int64, hasMore: Bool)>
}

extension RustApiImpl: ChatTodoApi {

    func getChatTodos(byChatId chatId: String)
        -> Observable<(assignToMe: [Rust.ChatTodo], assignToOther: [Rust.ChatTodo])> {
        var ctx = Self.generateContext()
        ctx.cmd = .getChatTodos
        ctx.logReq("\(chatId)")

        var request = Todo_V1_GetChatTodosRequest()
        request.chatID = chatId
        return client.sendAsyncRequest(request)
            .map { (response: Todo_V1_GetChatTodosResponse)
                -> (assignToMe: [Rust.ChatTodo], assignToOther: [Rust.ChatTodo]) in
                return (assignToMe: response.assignToMeTodos, assignToOther: response.assignToOtherTodos)
            }
            .log(with: ctx) {
                return "assignToMe: \($0.assignToMe.count), assignToOther: \($0.assignToOther.count)"
            }
    }

    func getCompletedChatTodos(byChatId chatId: String, pageCount: Int, lastOffset: Int64?)
        -> Observable<(chatTodos: [Rust.ChatTodo], lastOffset: Int64, hasMore: Bool)> {
        var ctx = Self.generateContext()
        ctx.cmd = .getChatCompletedTodos
        ctx.logReq("\(chatId),\(pageCount),\(lastOffset ?? 0)")

        var request = Todo_V1_GetChatCompletedTodosRequest()
        request.chatID = chatId
        request.pageCount = Int32(pageCount)
        if let offset = lastOffset {
            request.lastOffset = offset
        }
        return client.sendAsyncRequest(request)
            .map { (response: Todo_V1_GetChatCompletedTodosResponse)
                -> (chatTodos: [Rust.ChatTodo], lastOffset: Int64, hasMore: Bool) in
                return (chatTodos: response.todos, lastOffset: response.lastOffset, hasMore: response.hasMore_p)
            }
            .log(with: ctx) {
                return "chatTodos:\($0.chatTodos.count),lastOffset:\($0.lastOffset),hasMore:\($0.hasMore)"
            }
    }

}
