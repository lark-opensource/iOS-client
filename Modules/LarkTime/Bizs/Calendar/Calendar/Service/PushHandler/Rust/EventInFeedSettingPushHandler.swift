//
//  EventInFeedSettingPushHandler.swift
//  Calendar
//
//  Created by chaishenghua on 2023/8/15.
//

import LarkRustClient
import LarkContainer
import RustPB

final class EventInFeedSettingPushHandler: UserPushHandler {

    @ScopedInjectedLazy var rustPushService: RustPushService?

    func process(push message: Feed_V1_PushEventSetting) throws {
        RustPushService.logger.info("Push_eventTempTop: \(message.eventTempTop)")
        self.rustPushService?.rxFeedTempTop.onNext(message.eventTempTop)
    }

}
