//
//  FollowingChangedNotification.swift
//  Moment
//
//  Created by zhuheng on 2021/1/8.
//

import Foundation
import RustPB
import LarkRustClient
import RxSwift

protocol FollowingChangedNotification: AnyObject {
    var rxFollowingInfo: PublishSubject<RawData.FollowingInfoNof> { get }
}

final class FollowingChangedPushHandler: FollowingChangedNotification {
    let rxFollowingInfo: PublishSubject<RawData.FollowingInfoNof> = .init()

    init(client: RustService) {
        client.register(pushCmd: .momentsPushUserFollowingChangeLocalNotification) { [weak self] data in
            guard let self = self else { return }
            do {
                let rustBody = try RawData.FollowingInfoNof(serializedData: data)
                self.rxFollowingInfo.onNext(rustBody)
            } catch {
                assertionFailure("serialize update noti payload failed")
            }
        }
    }
}
