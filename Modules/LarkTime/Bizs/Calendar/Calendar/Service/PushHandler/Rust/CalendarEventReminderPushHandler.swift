//
//  CalendarEventReminderPushHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/22.
//

import LarkRustClient
import LarkContainer
import RustPB

final class CalendarEventReminderPushHandler: UserPushHandler {

    @ScopedInjectedLazy var rustPushService: RustPushService?

    func process(push message: Rust.CalendarReminder) throws {
        RustPushService.logger.info("receive CalendarReminder")
        self.rustPushService?.rxEventReminder.onNext(message)
    }

}
