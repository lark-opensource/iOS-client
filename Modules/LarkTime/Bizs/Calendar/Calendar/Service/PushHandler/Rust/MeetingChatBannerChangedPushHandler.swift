//
//  MeetingChatBannerChangedPushHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/18.
//

import LarkRustClient
import LarkContainer
import RustPB

final class MeetingChatBannerChangedPushHandler: UserPushHandler {

    @ScopedInjectedLazy var rustPushService: RustPushService?

    func process(push message: Calendar_V1_PushMeetingChatBannerChangedNotification) throws {
        RustPushService.logger.info("receive PushMeetingChatBannerChangedNotification")
        self.rustPushService?.rxMeetingChatBannerChanged.onNext(message)
    }

}
