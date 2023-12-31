//
//  UrgentAckChatterStatusPushHandler.swift
//  LarkMessageCore
//
//  Created by zc09v on 2019/4/14.
//

import Foundation
import RxSwift
import LarkModel
import LarkContainer
import LarkSDKInterface

final class UrgentAckChatterStatusPushHandlerFactory: NSObject, PushHandlerFactory {
    func createHandler(channelId: String, needCachePush: Bool, userResolver: UserResolver) -> PushHandler {
        return UrgentAckChatterStatusPushHandler(needCachePush: needCachePush, userResolver: userResolver)
    }
}

final class UrgentAckChatterStatusPushHandler: PushHandler {
    let disposeBag: DisposeBag = DisposeBag()

    override func startObserve() throws {
        try self.userResolver.userPushCenter
            .observable(for: PushUrgentStatus.self)
            .subscribe(onNext: { [weak self] (push) in
                self?.perform {
                    self?.dataSourceAPI?.update(messageIds: [push.messageId], doUpdate: { (data) -> PushData in
                        data.message.ackUrgentChatterIds = push.confirmedChatterIds
                        data.message.unackUrgentChatterIds = push.unconfirmedChatterIds
                        return data
                    })
                }
            }).disposed(by: disposeBag)
    }
}
