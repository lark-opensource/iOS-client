//
//  MyAiInlineStageNotificationPushHandler.swift
//  Calendar
//
//  Created by pluto on 2023/9/25.
//

import Foundation
import LarkRustClient
import LarkContainer
import ServerPB

final class MyAiInlineStageNotificationPushHandler: UserPushHandler {

    @ScopedInjectedLazy var serverPushService: ServerPushService?

    func process(push message: Server.CalendarMyAIInlineStageInfo) throws {
        self.serverPushService?.rxMyAiInlineStage.onNext((message))
    }

}
