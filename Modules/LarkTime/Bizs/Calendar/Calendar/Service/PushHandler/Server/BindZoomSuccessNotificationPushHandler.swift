//
//  BindZoomSuccessNotificationPushHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/18.
//

import LarkRustClient
import LarkContainer
import ServerPB

final class BindZoomSuccessNotificationPushHandler: UserPushHandler {

    @ScopedInjectedLazy var serverPushService: ServerPushService?

    func process(push message: Server.PushBindZoomSuccess) throws {
        self.serverPushService?.rxZoomBind.onNext(())
    }

}
