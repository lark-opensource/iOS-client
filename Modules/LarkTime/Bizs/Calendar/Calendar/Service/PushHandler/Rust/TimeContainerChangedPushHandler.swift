//
//  TimeContainerChangedPushHandler.swift
//  Calendar
//
//  Created by huoyunjie on 2023/11/17.
//

import LarkRustClient
import LarkContainer
import RustPB

final class TimeContainerChangedPushHandler: UserPushHandler {

    @ScopedInjectedLazy var rustPushService: RustPushService?

    func process(push message: Calendar_V1_PushTimeContainerChangeNotification) throws {
        RustPushService.logger.info("receive PushTimeContainerChangeNotification")
        self.rustPushService?.rxTimeContainerChanged.onNext(message.serverContainerIds)
    }

}

