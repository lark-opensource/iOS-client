//
//  PushTimeBlocksChangeHandler.swift
//  Calendar
//
//  Created by JackZhao on 2023/11/23.
//

import RustPB
import LarkRustClient
import LarkContainer

final class PushTimeBlocksChangeHandler: UserPushHandler {

    @ScopedInjectedLazy var rustPushService: RustPushService?

    func process(push message: Calendar_V1_PushTimeBlocksChangeOnContainerNotification) throws {
        RustPushService.logger.info("receive PushTimeBlocksChangeOnContainerNotification")
        self.rustPushService?.rxTimeBlocksChange.onNext(message.containerIds)
    }

}
