//
//  MomentsAccountNotification.swift
//  Moment
//
//  Created by ByteDance on 2022/12/8.
//

import Foundation
import RustPB
import RxSwift
import LarkRustClient

protocol MomentsAccountNotification: AnyObject {
    var rxOfficialAccountChanged: PublishSubject<RawData.PushOfficialUserChangedNotification> { get }
}

final class MomentsAccountNotificationHandler: MomentsAccountNotification {
    let rxOfficialAccountChanged: PublishSubject<RawData.PushOfficialUserChangedNotification> = .init()

    init(client: RustService) {
        client.register(pushCmd: .momentsPushOfficialUserChangedNotification) { [weak self] nofInfo in
            guard let self = self else { return }
            do {
                let rustBody = try RawData.PushOfficialUserChangedNotification(serializedData: nofInfo)
                self.rxOfficialAccountChanged.onNext(rustBody)
            } catch {
                assertionFailure("serialize update noti payload failed")
            }
        }
    }
}
