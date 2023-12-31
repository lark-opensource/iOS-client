//
//  BindExchangeSuccessNotificationPushHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/18.
//

import LarkRustClient
import LarkContainer
import ServerPB

final class BindExchangeSuccessNotificationPushHandler: UserPushHandler {

    @ScopedInjectedLazy var serverPushService: ServerPushService?

    func process(push message: ServerPB_Calendars_ExchangeOAuthSync) throws {
        self.serverPushService?.rxExchangeBind.onNext(())
    }

}
