//
//  CommentNoti.swift
//  Todo
//
//  Created by 张威 on 2021/4/4.
//

import RxSwift
import RustPB
import LarkRustClient
import LKCommonsLogging

/// Rust - Todo Update Noti

struct CommentNotiBody {
    var todoId: String
    var comment: Rust.Comment
}

struct CommentReactionNotiBody {
    var todoId: String
    var commentId: String
    var reactions: [Rust.Reaction]
    var updateTime: Int64   // 更新时间，单位 - 毫秒
}

protocol CommentNoti: AnyObject {
    /// 评论
    var rxCommentSubject: PublishSubject<CommentNotiBody> { get }

    /// 评论 reaction
    var rxCommentReactionSubject: PublishSubject<CommentReactionNotiBody> { get }
}

final class CommentPushHandler: CommentNoti {

    var rxCommentSubject: PublishSubject<CommentNotiBody> = .init()
    var rxCommentReactionSubject: PublishSubject<CommentReactionNotiBody> = .init()
    static let logger = Logger.log(CommentPushHandler.self, category: "Todo.CommentPushHandler")

    init(client: RustService) {
        client.register(pushCmd: .pushTodoCommentNotification) { [weak self] data in
            guard let self = self else { return }
            do {
                let payload = try RustPB.Todo_V1_PushTodoComment(serializedData: data)
                self.rxCommentSubject.onNext(.init(todoId: payload.todoGuid, comment: payload.comment))
            } catch {
                Detail.assertionFailure("serialize comment noti payload failed. err: \(error)")
            }
        }
        client.register(pushCmd: .pushTodoCommentReactionNotification) { [weak self] data in
            do {
                let payload = try RustPB.Todo_V1_PushTodoCommentReaction(serializedData: data)
                let body = CommentReactionNotiBody(
                    todoId: payload.todoGuid,
                    commentId: payload.commentID,
                    reactions: payload.reactions,
                    updateTime: payload.updateMilliTime
                )
                self?.rxCommentReactionSubject.onNext(body)
            } catch {
                Detail.assertionFailure("serialize comment reaction noti payload failed. err: \(error)")
            }
        }
    }
}
