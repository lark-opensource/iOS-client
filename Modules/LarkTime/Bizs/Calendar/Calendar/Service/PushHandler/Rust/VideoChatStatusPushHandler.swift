//
//  VideoChatStatusPushHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/22.
//

import LarkRustClient
import LarkContainer
import RustPB

final class VideoChatStatusPushHandler: UserPushHandler {

    @ScopedInjectedLazy var rustPushService: RustPushService?

    func process(push message: Rust.VideoChatStatusNotiPayload) throws {
        RustPushService.logger.info("receive VideoChatStatusNotiPayload: uniqueId =  \(message.id), status: = \(message.meetingInfo.meetingStatus)")
        var status: Rust.VideoMeetingStatus = .unknown
        switch message.idType {
        case .uniqueID, .interviewUid:
            if message.meetingInfo.meetingStatus == .meetingOnTheCall {
                status = .live
            }
        @unknown default:
            break
        }
        self.rustPushService?.rxVideoStatus.onNext((uniqueId: message.id, status: status))
    }

}
