//
//  InlineAITaskStatusPushHandler.swift
//  Calendar
//
//  Created by pluto on 2023/9/25.
//

import LarkRustClient
import LarkContainer
import RustPB

final class InlineAITaskStatusPushHandler: UserPushHandler {

    @ScopedInjectedLazy var rustPushService: RustPushService?

    func process(push message: Rust.InlineAITaskStatusPushResponse) throws {
        RustPushService.logger.info("receive InlineAITaskStatusPush: \(message.inlineAiTaskStatus)")
        self.rustPushService?.rxInlineAiTaskStatus.onNext(message)
    }

}
