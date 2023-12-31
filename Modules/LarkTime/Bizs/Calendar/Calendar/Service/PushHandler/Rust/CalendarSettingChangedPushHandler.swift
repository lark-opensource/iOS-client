//
//  CalendarSettingChangedPushHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/19.
//

import LarkRustClient
import LarkContainer
import RustPB

final class CalendarSettingChangedPushHandler: UserPushHandler {

    @ScopedInjectedLazy var rustPushService: RustPushService?

    func process(push message: Calendar_V1_PushCalendarSettingsChangeNotification) throws {
        RustPushService.logger.info("receive PushCalendarSettingsChangeNotification")
        self.rustPushService?.rxSettingRefresh.onNext(())
    }

}
