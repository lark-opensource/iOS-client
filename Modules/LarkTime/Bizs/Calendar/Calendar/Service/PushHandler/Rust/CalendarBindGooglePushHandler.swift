//
//  CalendarBindGooglePushHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/19.
//

import LarkRustClient
import LarkContainer
import RustPB

final class CalendarBindGooglePushHandler: UserPushHandler {

    @ScopedInjectedLazy var rustPushService: RustPushService?

    func process(push message: PushCalendarBindGoogleNotification) throws {
        RustPushService.logger.info("receive PushCalendarBindGoogleNotification, isBound: \(message.isBound)")
        if message.isBound {
            // 绑定成功post account信息，跳转侧边栏对应地方
            self.rustPushService?.rxGoogleCalAccount.onNext(message.externalAccountEmail)
        }
    }

}
