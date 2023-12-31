//
//  CalendarSyncPushHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/18.
//

import LarkRustClient
import LarkContainer
import RustPB

final class CalendarSyncPushHandler: UserPushHandler {

    @ScopedInjectedLazy var rustPushService: RustPushService?

    func process(push message: Calendar_V1_PushCalendarSyncNotification) throws {
        RustPushService.logger.info("receive PushCalendarSyncNotification")
        self.rustPushService?.rxCalendarSync.onNext(())
    }

}
