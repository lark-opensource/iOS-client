//
//  MeetingMinuteEditorsPushHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/18.
//

import LarkRustClient
import LarkContainer
import RustPB

final class MeetingMinuteEditorsPushHandler: UserPushHandler {

    @ScopedInjectedLazy var rustPushService: RustPushService?

    func process(push message: Rust.MeetingMinuteEditors) throws {
        RustPushService.logger.info("receive MeetingMinuteEditors")
        self.rustPushService?.rxMeetingMinuteEditors.onNext(message)
    }

}
