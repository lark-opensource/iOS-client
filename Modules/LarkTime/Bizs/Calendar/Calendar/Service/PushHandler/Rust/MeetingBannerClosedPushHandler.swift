//
//  MeetingBannerClosedPushHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/22.
//

import LarkRustClient
import LarkContainer
import RustPB
import ServerPB

final class MeetingBannerClosedPushHandler: UserPushHandler {

    @ScopedInjectedLazy var rustPushService: RustPushService?

    func process(push message: PushScrollClosedNotification) throws {
        RustPushService.logger.info("receive PushScrollClosedNotification, scrollType: \(message.scrollType)")
        // 考古逻辑：
        // message 里面的 scrollType 是 Calendar_V1_ScrollType 类型，
        // 但是这个 push 使用的地方需要 ServerPB_Entities_ScrollType 类型的，所以在源头这里做了个转换
        var scrollType: ServerPB_Entities_ScrollType = .eventInfo
        switch message.scrollType {
        case .eventInfo:
            scrollType = .eventInfo
        case .meetingTransferChat:
            scrollType = .meetingTransferChat
        @unknown default:
            break
        }
        self.rustPushService?.rxMeetingBannerClosed.onNext((message.chatID, scrollType))
    }

}
