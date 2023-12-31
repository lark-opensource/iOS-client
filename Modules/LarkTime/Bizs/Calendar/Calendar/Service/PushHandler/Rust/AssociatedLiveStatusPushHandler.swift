//
//  AssociatedLiveStatusPushHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/22.
//

import LarkRustClient
import LarkContainer
import RustPB

final class AssociatedLiveStatusPushHandler: UserPushHandler {

    @ScopedInjectedLazy var rustPushService: RustPushService?

    func process(push message: Rust.AssociatedLiveStatus) throws {
        RustPushService.logger.info("receive AssociatedLiveStatus")
        self.rustPushService?.rxVideoLiveHostStatus.onNext(message)
    }

}
