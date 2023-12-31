//
//  TodoCommentApi.swift
//  Todo
//
//  Created by 张威 on 2021/3/4.
//

import RxSwift
import RustPB
import ServerPB

/// Todo 评论 Api

protocol TodoCommentApi {

    /// 新建评论
    func createComment(withTodoId todoId: String, info: Rust.CreateCommentInfo) -> Observable<Rust.Comment>

    /// 更新评论
    ///
    /// - Parameters:
    ///   - commentId: 评论 id
    ///   - content: 富文本内容
    ///   - attachments: 图片
    ///   - fileAttachments: 文件附件
    ///   - todoId: todo 的 guid
    func updateComment(
        byId commentId: String,
        content: Rust.RichContent,
        attachments: [Rust.Attachment],
        fileAttachments: [Rust.Attachment],
        todoId: String
    ) -> Observable<Rust.Comment>

    /// 删除评论
    ///
    /// - Parameters:
    ///   - commentId: 评论 id
    ///   - todoId: todo 的 guid
    func deleteComment(byId commentId: String, todoId: String) -> Observable<Void>

    /// 根据位置向上获取 comments
    ///
    /// - Parameters:
    ///   - position: position
    ///   - count: 数量
    ///   - todoId: todo 的 guid
    func getUpComments(from position: Int32, count: Int32, todoId: String)
        -> Observable<(comments: [Rust.Comment], hasMore: Bool)>

    /// 根据位置向下获取 comments
    ///
    /// - Parameters:
    ///   - position: position
    ///   - count: 数量
    ///   - todoId: todo 的 guid
    func getDownComments(from position: Int32, count: Int32, todoId: String)
        -> Observable<(comments: [Rust.Comment], hasMore: Bool)>

    /// 增加 reaction
    ///
    /// - Parameters:
    ///   - type: reaction type
    ///   - commentId: comment id
    ///   - todoId: todo id
    func insertReaction(withType type: String, commentId: String, todoId: String) -> Observable<Void>

    /// 删除 reaction
    ///
    /// - Parameters:
    ///   - type: reaction type
    ///   - commentId: comment id
    ///   - todoId: todo id
    func deleteReaction(withType type: String, commentId: String, todoId: String) -> Observable<Void>

    /// 发送心跳（维系 server 同端上的 push 推送）
    ///
    /// - Parameter todoId: todo id
    /// - Parameter containerId: container guid
    func sendCommentHeartbeat(either todoId: String?, or containerId: String?) -> Observable<Void>

    /// 获取评论草稿
    func getCommentDraft(withTodoId todoId: String) -> Observable<Rust.CreateCommentInfo?>

    /// 更新评论草稿
    func setCommentDraft(withTodoId todoId: String, info: Rust.CreateCommentInfo) -> Observable<Void>

    /// 移除评论草稿
    func clearCommentDraft(byTodoId todoId: String) -> Observable<Void>

}

extension RustApiImpl: TodoCommentApi {

    func createComment(withTodoId todoId: String, info: Rust.CreateCommentInfo) -> Observable<Rust.Comment> {
        var ctx = Self.generateContext()
        ctx.cmd = .createTodoComment
        ctx.logReq("cid:\(info.cid),todoId:\(todoId)")

        var request = Todo_V1_CreateCommentRequest()
        request.todoGuid = todoId
        request.cid = info.cid
        request.content = info.content
        request.attachments = info.attachments
        request.fileAttachments = info.fileAttachments
        request.type = info.type
        if !info.replyRootID.isEmpty {
            request.replyRootID = info.replyRootID
        }
        if !info.replyParentID.isEmpty {
            request.replyParentID = info.replyParentID
        }
        return client.sendAsyncRequest(request)
            .map(Transform<Todo_V1_CreateCommentResponse>.toKeyPath(\.comment))
            .log(with: ctx) { $0.logInfo }
    }

    func updateComment(
        byId commentId: String,
        content: Rust.RichContent,
        attachments: [Rust.Attachment],
        fileAttachments: [Rust.Attachment],
        todoId: String
    ) -> Observable<Rust.Comment> {
        var ctx = Self.generateContext()
        ctx.cmd = .updateTodoComment
        ctx.logReq("commentId:\(commentId),todoId:\(todoId)")

        var request = Todo_V1_UpdateCommentRequest()
        request.todoGuid = todoId
        request.commentID = commentId
        request.content = content
        request.attachments = attachments
        request.fileAttachments = fileAttachments
        return client.sendAsyncRequest(request)
            .map(Transform<Todo_V1_UpdateCommentResponse>.toKeyPath(\.comment))
            .log(with: ctx) { $0.logInfo }
    }

    func deleteComment(byId commentId: String, todoId: String) -> Observable<Void> {
        var ctx = Self.generateContext()
        ctx.cmd = .deleteComment
        ctx.logReq("commentId:\(commentId),todoId:\(todoId)")

        var request = Todo_V1_DeleteCommentRequest()
        request.commentID = commentId
        request.todoGuid = todoId
        return client.sendAsyncRequest(request)
            .map(Transform<Todo_V1_DeleteCommentResponse>.toVoid())
            .log(with: ctx) { "delete succeed" }
    }

    func getUpComments(
        from position: Int32,
        count: Int32,
        todoId: String
    ) -> Observable<(comments: [Rust.Comment], hasMore: Bool)> {
        return getComments(from: position, count: count, todoId: todoId, upFlag: true)
    }

    func getDownComments(
        from position: Int32,
        count: Int32,
        todoId: String
    ) -> Observable<(comments: [Rust.Comment], hasMore: Bool)> {
        return getComments(from: position, count: count, todoId: todoId, upFlag: false)
    }

    private func getComments(
        from position: Int32,
        count: Int32,
        todoId: String,
        upFlag: Bool
    ) -> Observable<(comments: [Rust.Comment], hasMore: Bool)> {
        var ctx = Self.generateContext()
        ctx.cmd = .listTodoComments
        ctx.logReq("position:\(position),count:\(count),todoId:\(todoId),direction:\(upFlag)")
        var request = Todo_V1_ListCommentsRequest()
        request.position = position
        request.count = count
        request.todoGuid = todoId
        request.direction = upFlag ? .up : .down
        return client.sendAsyncRequest(request)
            .map { (response: Todo_V1_ListCommentsResponse) -> (comments: [Rust.Comment], hasMore: Bool) in
                return (response.comments, response.hasMore_p)
            }
            .log(with: ctx) { tuple in
                let (comments, hasMore) = tuple
                return "comments: \(comments.map(\.logInfo).joined(separator: ",")), hasMore: \(hasMore)"
            }
    }

    func insertReaction(withType type: String, commentId: String, todoId: String) -> Observable<Void> {
        var ctx = Self.generateContext()
        ctx.serverCmd = .createTodoCommentReaction
        ctx.logReq("type:\(type),commentId:\(commentId),todoId:\(todoId)")
        var request = ServerPB_Todo_comments_CreateTodoCommentReactionRequest()
        request.todoGuid = todoId
        request.commentID = commentId
        request.reactionType = type
        return client.sendPassThroughAsyncRequest(request, serCommand: ctx.serverCmd!)
            .map(Transform<ServerPB_Todo_comments_CreateTodoCommentReactionResponse>.toVoid())
            .log(with: ctx) { _ in "insertReaction succeed.type:\(type),commentId:\(commentId),todoId:\(todoId)" }
    }

    func deleteReaction(withType type: String, commentId: String, todoId: String) -> Observable<Void> {
        var ctx = Self.generateContext()
        ctx.serverCmd = .deleteTodoCommentReaction
        ctx.logReq("type:\(type),commentId:\(commentId),todoId:\(todoId)")
        var request = ServerPB_Todo_comments_DeleteTodoCommentReactionRequest()
        request.todoGuid = todoId
        request.commentID = commentId
        request.reactionType = type
        return client.sendPassThroughAsyncRequest(request, serCommand: ctx.serverCmd!)
            .map(Transform<ServerPB_Todo_comments_DeleteTodoCommentReactionResponse>.toVoid())
            .log(with: ctx) { _ in "deleteReaction succeed.type:\(type),commentId:\(commentId),todoId:\(todoId)" }
    }

    func sendCommentHeartbeat(either todoId: String?, or containerId: String?) -> Observable<Void> {
        var ctx = Self.generateContext()
        ctx.serverCmd = .sendTodoHeartbeat
        ctx.logReq("todoId:\(todoId), containerId: \(containerId)")
        var request = ServerPB_Todos_SendTodoHeartbeatRequest()
        if let todoId = todoId {
            request.todoGuid = todoId
        }
        if let containerId = containerId {
            request.containerGuid = containerId
        }
        return client.sendPassThroughAsyncRequest(request, serCommand: ctx.serverCmd!)
            .map(Transform<ServerPB_Todos_SendTodoHeartbeatResponse>.toVoid())
            .log(with: ctx) { _ in "sendCommentHeartbeat succeed" }
    }

    func getCommentDraft(withTodoId todoId: String) -> Observable<Rust.CreateCommentInfo?> {
        var ctx = Self.generateContext()
        ctx.cmd = .getTodoCommentDraft
        ctx.logReq("todoId:\(todoId)")

        var request = Todo_V1_GetCommentDraftRequest()
        request.todoGuid = todoId
        return client.sendAsyncRequest(request)
            .map { (response: Todo_V1_GetCommentDraftResponse) -> Rust.CreateCommentInfo? in
                guard response.found else { return nil }
                return response.info
            }
            .log(with: ctx) { "getCommentDraft \($0 == nil ? "failed" : "succeed"). todoId: \(todoId)" }
    }

    func setCommentDraft(withTodoId todoId: String, info: Rust.CreateCommentInfo) -> Observable<Void> {
        var ctx = Self.generateContext()
        ctx.cmd = .saveTodoCommentDraft
        ctx.logReq("todoId:\(todoId)")

        var request = Todo_V1_SaveCommentDraftRequest()
        request.todoGuid = todoId
        request.info = info
        return client.sendAsyncRequest(request)
            .map(Transform<Todo_V1_SaveCommentDraftResponse>.toVoid())
            .log(with: ctx) { _ in "cache comment draft succeed. todoId:\(todoId)" }
    }

    func clearCommentDraft(byTodoId todoId: String) -> Observable<Void> {
        var ctx = Self.generateContext()
        ctx.cmd = .deleteTodoCommentDraft
        ctx.logReq("todoId:\(todoId)")

        var request = Todo_V1_DeleteCommentDraftRequest()
        request.todoGuid = todoId
        return client.sendAsyncRequest(request)
            .map(Transform<Todo_V1_DeleteCommentDraftResponse>.toVoid())
            .log(with: ctx) { _ in "clear comment draft succeed. todoId:\(todoId)" }
    }

}
