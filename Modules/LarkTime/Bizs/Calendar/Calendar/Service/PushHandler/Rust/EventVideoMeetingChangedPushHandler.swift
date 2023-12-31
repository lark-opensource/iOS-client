//
//  EventVideoMeetingChangedPushHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/18.
//

import LarkRustClient
import LarkContainer
import RustPB

final class EventVideoMeetingChangedPushHandler: UserPushHandler {

    @ScopedInjectedLazy var rustPushService: RustPushService?

    func process(push message: Rust.VideoMeetingChangeNotiPayload) throws {
        RustPushService.logger.info("receive VideoMeetingChangeNotiPayload")
        self.rustPushService?.rxVideoMeetingInfos.onNext(message.eventVideoMeetingInfo)
    }

}
