//
//  EntityDeletedNotification.swift
//  Moment
//
//  Created by zhuheng on 2021/1/8.
//
import Foundation
import RustPB
import LarkRustClient
import RxSwift

protocol EntityDeletedNotification: AnyObject {
    var rxDeleteInfo: PublishSubject<RawData.DeletedInfoNof> { get }
}

final class EntityDeletedPushHandler: EntityDeletedNotification {
    let rxDeleteInfo: PublishSubject<RawData.DeletedInfoNof> = .init()

    init(client: RustService) {
        client.register(pushCmd: .momentsPushEntityDeletedLocalNotification) { [weak self] data in
            guard let self = self else { return }
            do {
                let rustBody = try RawData.DeletedInfoNof(serializedData: data)
                self.rxDeleteInfo.onNext(rustBody)
            } catch {
                assertionFailure("serialize update noti payload failed")
            }
        }
    }
}
