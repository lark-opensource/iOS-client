//
//  WebSocketStatusPushHandler.swift
//  Lark
//
//  Created by Yuguo on 2017/12/16.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface

import LKCommonsLogging

typealias GetWebSocketStatusResponse = Basic_V1_GetWebSocketStatusResponse
final class WebSocketStatusPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    static var logger = Logger.log(WebSocketStatusPushHandler.self, category: "Rust.PushHandler")

    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: GetWebSocketStatusResponse) {
        switch message.status {
        case .opening: SDKTracker.trackLongConnStart()
        case .success: SDKTracker.trackLongConnEnd()
        @unknown default: break
        }

        WebSocketStatusPushHandler.logger.debug("RustPB.Basic_V1_GetWebSocketStatusResponse.Status: \(message.status)")

        self.pushCenter?.post(PushWebSocketStatus(status: message.status))
    }
}
