//
//  CommentSetNotification.swift
//  Moment
//
//  Created by zc09v on 2021/2/4.
//

import Foundation
import RustPB
import RxSwift
import LarkRustClient

protocol CommentSetNotification: AnyObject {
    var rxCommentSet: PublishSubject<RawData.CommentSetNof> { get }
}

final class CommentSetNotificationHandler: CommentSetNotification {
    let rxCommentSet: PublishSubject<RawData.CommentSetNof> = .init()
    init(client: RustService) {
        client.register(pushCmd: .momentsPushCommentSetLocalNotification) { [weak self] data in
            do {
                let rustBody = try RawData.CommentSetNof(serializedData: data)
                self?.rxCommentSet.onNext(rustBody)
            } catch {
                assertionFailure("serialize update noti payload failed")
            }
        }
    }
}
