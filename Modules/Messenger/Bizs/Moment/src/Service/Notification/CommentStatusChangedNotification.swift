//
//  CommentStatusChangedNotification.swift
//  Moment
//
//  Created by zc09v on 2021/2/1.
//

import Foundation
import RustPB
import LarkRustClient
import RxSwift

protocol CommentStatusChangedNotification: AnyObject {
    var rxCommentStatus: PublishSubject<CommentStatusInfo> { get }
}

struct CommentStatusInfo {
    let localCommentID: String
    let createStatus: RawData.CommentCreateStatus
    let successComment: RawData.CommentEntity
    let error: RawData.Error
}

final class CommentStatusChangedPushHandler: CommentStatusChangedNotification {
    let rxCommentStatus: PublishSubject<CommentStatusInfo> = .init()

    init(client: RustService) {
        client.register(pushCmd: .momentsPushCommentCreateStatusChangeLocalNotification) { [weak self] data in
            guard let self = self else { return }
            do {
                let rustBody = try RawData.CommentStatusNof(serializedData: data)
                let info = CommentStatusInfo(localCommentID: rustBody.localCommentID,
                                             createStatus: rustBody.createStatus,
                                             successComment: MomentsDataConverter.convertCommentToCommentEntitiy(entities: rustBody.entities,
                                                                                                                 comment: rustBody.successServerComment),
                                             error: rustBody.error)
                self.rxCommentStatus.onNext(info)
            } catch {
                assertionFailure("serialize update noti payload failed")
            }
        }
    }
}
