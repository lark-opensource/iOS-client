//
//  CalendarEventChangedPushHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/22.
//

import LarkRustClient
import LarkContainer
import RustPB

final class CalendarEventChangedPushHandler: UserPushHandler {

    @ScopedInjectedLazy var rustPushService: RustPushService?

    func process(push message: Rust.CalendarEventChanged) throws {
        RustPushService.logger.info("receive CalendarEventChanged")
        self.rustPushService?.rxCalendarEventChanged.onNext(message)
    }

}
