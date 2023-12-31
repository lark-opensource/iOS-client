//
//  CalendarTenantSettingsChangedPushHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/18.
//

import LarkRustClient
import LarkContainer
import RustPB

final class CalendarTenantSettingsChangedPushHandler: UserPushHandler {

    @ScopedInjectedLazy var rustPushService: RustPushService?

    func process(push message: Calendar_V1_PushCalendarTenantSettingsChangeNotification) throws {
        RustPushService.logger.info("receive PushCalendarTenantSettingsChangeNotification")
        self.rustPushService?.rxTenantSettingChanged.onNext(message.row)
    }

}
