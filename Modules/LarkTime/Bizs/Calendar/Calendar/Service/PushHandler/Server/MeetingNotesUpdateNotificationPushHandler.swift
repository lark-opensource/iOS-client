//
//  MeetingNotesUpdateNotificationPushHandler.swift
//  Calendar
//
//  Created by huoyunjie on 2023/9/1.
//

import LarkRustClient
import LarkContainer
import ServerPB

final class MeetingNotesUpdateNotificationPushHandler: UserPushHandler {

    @ScopedInjectedLazy var serverPushService: ServerPushService?

    func process(push message: Server.MeetingNotesUpdateInfo) throws {
        self.serverPushService?.rxMeetingNotesUpdate.onNext(message)
    }

}
