//
//  TodoShareApi.swift
//  Todo
//
//  Created by 张威 on 2021/1/22.
//

import RxSwift
import RustPB

/// Todo 分享相关的 Api

extension Rust {
    typealias TodoShareResult = Todo_V1_ShareTodoMessageResponse
    typealias TodoShareType = Todo_V1_ShareTodoMessageRequest.ShareType
}

protocol TodoShareApi {

    /// 分享 Todo
    /// - Parameters:
    ///   - guid: todo 的 guid
    ///   - chatIds: 要分享的 chatIds
    /// - Returns: 分享结果
    func shareTodo(
        withId guid: String,
        chatIds: [String],
        threadInfos: [Rust.ThreadInfo],
        type: Rust.TodoShareType
    ) -> Observable<Rust.TodoShareResult>

}

extension RustApiImpl: TodoShareApi {

    func shareTodo(
        withId guid: String,
        chatIds: [String],
        threadInfos: [Rust.ThreadInfo],
        type: Rust.TodoShareType
    ) -> Observable<Rust.TodoShareResult> {
        var ctx = Self.generateContext()
        ctx.cmd = .shareTodoMessage
        ctx.logReq("guid: \(guid), chatIds: \(chatIds), threadInfos: \(threadInfos.map { $0.logInfo }), t: \(type.rawValue)")

        var request = Todo_V1_ShareTodoMessageRequest()
        request.todoGuid = guid
        request.chatIds = chatIds
        request.threadInfos = threadInfos
        request.shareType = type
        return client.sendAsyncRequest(request)
            .map { (response: Todo_V1_ShareTodoMessageResponse) -> Rust.TodoShareResult in
                return response
            }
            .log(with: ctx) { result in
                let failedMsg = result.failedChats.map { c in
                    return "{chatId: \(c.chatID), errCode: \(c.errorCode)}"
                }.joined(separator: ",")
                return "\(result.chatID2MessageIds), \(result.message2Threads), failed: \(failedMsg)"
            }
    }

}
