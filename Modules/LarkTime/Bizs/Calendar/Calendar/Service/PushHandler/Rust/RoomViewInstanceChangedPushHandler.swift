//
//  RoomViewInstanceChangedPushHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/19.
//

import LarkRustClient
import LarkContainer
import RustPB

final class RoomViewInstanceChangedPushHandler: UserPushHandler {

    @ScopedInjectedLazy var rustPushService: RustPushService?

    func process(push message: Calendar_V1_PushRoomViewInstanceChangeNotification) throws {
        RustPushService.logger.info("receive PushRoomViewInstanceChangeNotification, inst count: \(message.resourceCalendarIds.count)")
        if !message.resourceCalendarIds.isEmpty {
            self.rustPushService?.rxMeetingRoomInstanceChanged.onNext(message.resourceCalendarIds)
        }
    }

}
