//
//  ListBadgeNoti.swift
//  Todo
//
//  Created by wangwanxin on 2021/6/6.
//

import RxSwift
import LKCommonsLogging
import LarkRustClient
import RustPB

/// Home - List - Badge
protocol ListBadgeNoti: AnyObject {
    var rxListBadge: PublishSubject<Int32> { get }
}

final class ListBadgePushHandler: ListBadgeNoti {

    var rxListBadge: PublishSubject<Int32> = .init()
    static let logger = Logger.log(ListBadgePushHandler.self, category: "Todo.ListBadgePushHandler")

    init(client: RustService) {
        client.register(pushCmd: .pushTodoBadgeNotification) { [weak self] data in
            guard let self = self else { return }
            do {
                let payload = try RustPB.Todo_V1_PushTodoBadgeChangedNotification(serializedData: data)
                self.rxListBadge.onNext(payload.count)
            } catch {
                Detail.assertionFailure("serialize comment noti payload failed. err: \(error)")
            }
        }
    }
}
