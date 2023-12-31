//
//  ExternalCalendarChangedPushHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/19.
//

import LarkRustClient
import LarkContainer
import RustPB

final class ExternalCalendarChangedPushHandler: UserPushHandler {

    @ScopedInjectedLazy var rustPushService: RustPushService?

    func process(push message: Rust.ExternalCalendar) throws {
        RustPushService.logger.info("receive ExternalCalendar")
        self.rustPushService?.rxExternalCalendar.onNext(message)
    }

}
