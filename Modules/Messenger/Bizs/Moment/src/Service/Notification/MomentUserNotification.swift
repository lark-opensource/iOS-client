//
//  MomentUserNotification.swift
//  Moment
//
//  Created by zc09v on 2021/1/14.
//

import Foundation
import RustPB
import LarkRustClient
import RxSwift

protocol MomentUserNotification: AnyObject {
    var rxUserInfo: PublishSubject<RawData.PushMomentsUserInfoNof> { get }
}

final class MomentUserPushHandler: MomentUserNotification {
    let rxUserInfo: PublishSubject<RawData.PushMomentsUserInfoNof> = .init()

    init(client: RustService) {
        client.register(pushCmd: .momentsPushMomentUsersLocalNotification) { [weak self] data in
            guard let self = self else { return }
            do {
                let rustBody = try RawData.PushMomentsUserInfoNof(serializedData: data)
                self.rxUserInfo.onNext(rustBody)
            } catch {
                assertionFailure("serialize update noti payload failed")
            }
        }
    }
}
