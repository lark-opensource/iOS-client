//
//  GoogleBindSettingPushHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/19.
//

import LarkRustClient
import LarkContainer
import RustPB

final class GoogleBindSettingPushHandler: UserPushHandler {

    @ScopedInjectedLazy var rustPushService: RustPushService?

    func process(push message: Rust.GoogleBindSetting) throws {
        RustPushService.logger.info("receive GoogleBindSetting")
        self.rustPushService?.rxGoogleBind.onNext(message)
    }

}
