//
//  CalendarEventRefreshPushHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/19.
//

import LarkRustClient
import LarkContainer
import RustPB

final class CalendarEventRefreshPushHandler: UserPushHandler {

    @ScopedInjectedLazy var rustPushService: RustPushService?

    func process(push message: PushCalendarEventRefreshNotification) throws {
        RustPushService.logger.info("receive PushCalendarEventRefreshNotification, id count: \(message.calendarSyncInfos.map { "calendarID \($0.calendarID) isSyncing \($0.isSyncing), \($0.minInstanceCacheTime)-\($0.maxInstanceCacheTime) service \(self.rustPushService)" })")
        self.rustPushService?.rxCalendarRefresh.onNext(message.calendarSyncInfos)
    }

}
