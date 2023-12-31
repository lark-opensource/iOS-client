//
//  DynamicNetStatusHandler.swift
//  LarkMail
//
//  Created by tefeng liu on 2021/4/7.
//

import Foundation
import LarkRustClient
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging
import RustPB
import MailSDK

class DynamicNetStatusHandler: UserPushHandler, AccountBasePushHandler {
    static let logger = Logger.log(DynamicNetStatusHandler.self, category: "DynamicNetStatusHandler")

    func process(push: RustPushPacket<Basic_V1_DynamicNetStatusResponse>) throws {
        guard checkAccount(push: push) else { return }
        DynamicNetStatusHandler.logger.info("mail receive dynamicNetStatus change")
        let change = DynamicNetTypeChange(netStatus: push.body.netStatus)
        PushDispatcher.shared.acceptLarkEventPush(push: .dynamicNetStatusChange(change))
    }
}

struct DynamicNetStatusPush: PushMessage {
    let dynamicNetStatus: RustPB.Basic_V1_DynamicNetStatusResponse.NetStatus
}
