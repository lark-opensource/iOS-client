//
//  ActiveEventChangedPushHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/18.
//

import LarkRustClient
import LarkContainer
import RustPB

final class ActiveEventChangedPushHandler: UserPushHandler {

    @ScopedInjectedLazy var rustPushService: RustPushService?

    func process(push message: Calendar_V1_PushActiveEventChangedNotification) throws {
        RustPushService.logger.info("receive PushActiveEventChangedNotification, changedEvents count: \(message.changedEvents.count)")
        self.rustPushService?.rxActiveEventChanged.onNext(message.changedEvents)
    }

}
