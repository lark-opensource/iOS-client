//
//  PostVisibilityNotification.swift
//  Moment
//
//  Created by zc09v on 2021/2/4.
//

import Foundation
import RustPB
import RxSwift
import LarkRustClient

protocol PostDistributionNotification: AnyObject {
    var rxPostDistribution: PublishSubject<RawData.PostDistributionNof> { get }
}

final class PostDistributionNotificationHandler: PostDistributionNotification {
    let rxPostDistribution: PublishSubject<RawData.PostDistributionNof> = .init()
    init(client: RustService) {
        client.register(pushCmd: .momentsPushPostDistributionLocalNotification) { [weak self] data in
            do {
                let rustBody = try RawData.PostDistributionNof(serializedData: data)
                self?.rxPostDistribution.onNext(rustBody)
            } catch {
                assertionFailure("serialize update noti payload failed")
            }
        }
    }
}
