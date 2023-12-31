//
//  MomentsPushNotification.swift
//  Moment
//
//  Created by llb on 2021/2/25.
//

import Foundation
import RustPB
import RxSwift
import LarkRustClient
import LarkContainer

final class MomentsBadgePushNotificationHandler {
     let rxBadgeCount: PublishSubject<MomentsBadgeInfo> = .init()
    init(client: RustService) {
        client.register(pushCmd: .momentsPushBadgeNotification) { [weak self] data in
            do {
                let rustBody = try Moments_V1_PushBadgeNotification(serializedData: data)
                let info = MomentsBadgeInfo(personalUserBadge: rustBody.notificationCount,
                                            officialUsersBadge: rustBody.officialUserNotificationCounts)
                self?.rxBadgeCount.onNext(info)
            } catch {
                assertionFailure("serialize update noti payload failed")
            }
        }
    }
}
