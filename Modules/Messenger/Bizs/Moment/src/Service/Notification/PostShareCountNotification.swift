//
//  PostShareCountNotification.swift
//  Moment
//
//  Created by zc09v on 2021/2/4.
//

import Foundation
import RustPB
import RxSwift
import LarkRustClient

protocol PostShareCountNotification: AnyObject {
    var rxShareCount: PublishSubject<RawData.ShareCountNof> { get }
}

final class PostShareCountNotificationHandler: PostShareCountNotification {
    let rxShareCount: PublishSubject<RawData.ShareCountNof> = .init()
    init(client: RustService) {
        client.register(pushCmd: .momentsPushShareCountLocalNotification) { [weak self] data in
            do {
                let rustBody = try RawData.ShareCountNof(serializedData: data)
                self?.rxShareCount.onNext(rustBody)
            } catch {
                assertionFailure("serialize update noti payload failed")
            }
        }
    }
}
