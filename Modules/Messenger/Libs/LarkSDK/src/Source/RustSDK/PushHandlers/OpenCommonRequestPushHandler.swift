//
//  OpenCommonRequestPushHandler.swift
//  LarkSDK
//
//  Created by tujinqiu on 2019/8/20.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface

final class OpenCommonRequestPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: PushOpenCommonRequest) {
        guard !message.events.isEmpty else {
            return
        }
        var events = [PushOpenCommonRequestEvent.OpenEvent]()
        for event in message.events {
            let type = PushOpenCommonRequestEvent.EventType(rawValue: event.eventType.rawValue)
            let e = PushOpenCommonRequestEvent.OpenEvent(type: type ?? .unknown,
                                                         pushTime: event.pushTime,
                                                         appID: event.hasAppID ? event.appID : nil,
                                                         payload: event.hasPayload ? event.payload : nil)
            events.append(e)
        }
        let pushEvent = PushOpenCommonRequestEvent(events: events)
        self.pushCenter?.post(pushEvent)
    }
}
