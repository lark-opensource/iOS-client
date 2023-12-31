//
//  PreloadUpdatedChatPushHandler.swift
//  LarkSDK
//
//  Created by zc09v on 2020/2/11.
//

import Foundation
import UIKit
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging

final class PreloadUpdatedChatPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    static var logger = Logger.log(PreloadUpdatedChatPushHandler.self, category: "Rust.PushHandler")
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Im_V1_PushPreloadUpdatedChats) {
        let ids = message.updatedItems.reduce("") { result, item in
            return result + " \(item.itemID)"
        }
        Self.logger.info("push handle pushPreloadUpdatedChatIds \(ids)")
        pushCenter?.post(PushPreloadUpdatedChatIds(ids: message.updatedItems.map({ return $0.itemID })))
    }
}
