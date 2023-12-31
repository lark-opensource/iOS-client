//
//  PostStatusChangedNotification.swift
//  Moment
//
//  Created by zhuheng on 2021/1/8.
//
import Foundation
import RustPB
import LarkRustClient
import RxSwift

protocol PostStatusChangedNotification: AnyObject {
    var rxPostStatus: PublishSubject<PostStatusInfo> { get }
}

struct PostStatusInfo {
    let localPostID: String
    let createStatus: RawData.PostCreateStatus
    let successPost: RawData.PostEntity
    let error: RawData.Error
}

final class PostStatusChangedPushHandler: PostStatusChangedNotification {
    let rxPostStatus: PublishSubject<PostStatusInfo> = .init()

    init(client: RustService) {
        client.register(pushCmd: .momentsPushPostCreateStatusChangeLocalNotification) { [weak self] data in
            guard let self = self else { return }
            do {
                let rustBody = try RawData.PostStatusNof(serializedData: data)
                let info = PostStatusInfo(localPostID: rustBody.localPostID,
                                          createStatus: rustBody.createStatus,
                                          successPost: RustApiService.getPostEntity(post: rustBody.successServerPost,
                                                                                    entities: rustBody.entities),
                                          error: rustBody.error)
                self.rxPostStatus.onNext(info)
            } catch {
                assertionFailure("serialize update noti payload failed")
            }
        }
    }
}
