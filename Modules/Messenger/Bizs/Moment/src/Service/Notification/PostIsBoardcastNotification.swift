//
//  PostIsBoardcastNotification.swift
//  Moment
//
//  Created by zc09v on 2021/3/9.
//

import Foundation
import RustPB
import RxSwift
import LarkRustClient

protocol PostIsBoardcastNotification: AnyObject {
    var rxPostIsBoardcast: PublishSubject<RawData.PushPostIsBoardcastNof> { get }
}

final class PostIsBoardcastNotificationHandler: PostIsBoardcastNotification {
    let rxPostIsBoardcast: PublishSubject<RawData.PushPostIsBoardcastNof> = .init()

    init(client: RustService) {
        client.register(pushCmd: .momentsPushPostIsBroadcastLocalNotification) { [weak self] nofInfo in
            guard let self = self else { return }
            do {
                let rustBody = try RawData.PushPostIsBoardcastNof(serializedData: nofInfo)
                self.rxPostIsBoardcast.onNext(rustBody)
            } catch {
                assertionFailure("serialize update noti payload failed")
            }
        }
    }
}
