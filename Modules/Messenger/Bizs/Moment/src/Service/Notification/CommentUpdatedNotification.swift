//
//  CommentUpdatedNotification.swift
//  Moment
//
//  Created by 袁平 on 2021/7/4.
//

import Foundation
import RustPB
import RxSwift
import LarkRustClient

protocol CommentUpdatedNotification: AnyObject {
    var rxCommentUpdated: PublishSubject<RawData.CommentEntity> { get }
}

final class CommentUpdatedNotificationHandler: CommentUpdatedNotification {
    let rxCommentUpdated: PublishSubject<RawData.CommentEntity> = .init()

    init(client: RustService) {
        client.register(pushCmd: .momentsPushNewCommentUpdatedNotification) { [weak self] data in
            do {
                let rustBody = try RawData.PushNewCommentUpdatedNotification(serializedData: data)
                if let comment = rustBody.entities.comments[rustBody.commentID] {
                    let entity = MomentsDataConverter.convertCommentToCommentEntitiy(entities: rustBody.entities, comment: comment)
                    self?.rxCommentUpdated.onNext(entity)
                }
            } catch {
                assertionFailure("serialize update noti payload failed")
            }
        }
    }
}
