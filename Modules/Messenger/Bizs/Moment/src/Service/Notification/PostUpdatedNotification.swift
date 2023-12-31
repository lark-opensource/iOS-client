//
//  PostUpdatedNotification.swift
//  Moment
//
//  Created by 袁平 on 2021/7/4.
//

import Foundation
import RustPB
import RxSwift
import LarkRustClient

protocol PostUpdatedNotification: AnyObject {
    var rxPostUpdated: PublishSubject<RawData.PostEntity> { get }
}

final class PostUpdatedNotificationHandler: PostUpdatedNotification {
    let rxPostUpdated: PublishSubject<RawData.PostEntity> = .init()

    init(client: RustService) {
        client.register(pushCmd: .momentsPushNewPostUpdatedNotification) { [weak self] data in
            do {
                let rustBody = try RawData.PushNewPostUpdatedNotification(serializedData: data)
                if let entity = RustApiService.getPostEntity(postID: rustBody.postID, entities: rustBody.entities) {
                    self?.rxPostUpdated.onNext(entity)
                }
            } catch {
                assertionFailure("serialize update noti payload failed")
            }
        }
    }
}
