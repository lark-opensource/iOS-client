//
//  CalendarTodayInstanceChangedPushHandler.swift
//  Calendar
//
//  Created by chaishenghua on 2023/8/7.
//

import LarkRustClient
import LarkContainer
import RustPB

final class CalendarTodayInstanceChangedPushHandler: UserPushHandler {

    @ScopedInjectedLazy var rustPushService: RustPushService?

    func process(push message: Calendar_V1_PushCalendarTodayInstanceChangedNotification) throws {
        RustPushService.logger.info("CalendarTodayInstanceChangedPush")
        self.rustPushService?.rxTodayInstanceChanged.onNext(())
    }

}
