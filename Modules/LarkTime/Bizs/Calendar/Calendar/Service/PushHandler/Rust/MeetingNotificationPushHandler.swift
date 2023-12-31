//
//  MeetingNotificationPushHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/19.
//

import LarkRustClient
import LarkContainer
import RustPB

final class MeetingNotificationPushHandler: UserPushHandler {

    @ScopedInjectedLazy var rustPushService: RustPushService?

    func process(push message: Rust.PushMeeting) throws {
        RustPushService.logger.info("receive PushMeeting")
        self.rustPushService?.rxMeetingChange.onNext(message.meetingEventRefs)
    }

}
