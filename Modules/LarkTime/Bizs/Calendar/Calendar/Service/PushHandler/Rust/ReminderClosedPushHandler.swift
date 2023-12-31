//
//  ReminderClosedPushHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/22.
//

import LarkRustClient
import LarkContainer
import RustPB

final class ReminderClosedPushHandler: UserPushHandler {

    @ScopedInjectedLazy var rustPushService: RustPushService?

    func process(push message: PushReminderClosedNotification) throws {
        RustPushService.logger.info("receive PushReminderClosedNotification")
        let generator = NotificationIdGenerator(eventId: String(message.eventID),
                                                startTime: String(message.startTime),
                                                minutes: "0")
        self.rustPushService?.rxReminderCardClosed.onNext(generator.getId())
    }

}
