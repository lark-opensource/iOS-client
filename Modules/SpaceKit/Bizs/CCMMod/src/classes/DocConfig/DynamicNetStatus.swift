//
//  DynamicNetStatus.swift
//  CCMMod
//
//  Created by Supeng on 2021/11/15.
//

import Foundation
import RustPB
import LarkContainer
import LarkRustClient
import LKCommonsLogging

struct PushDynamicNetStatus: PushMessage {
    let dynamicNetStatus: RustPB.Basic_V1_DynamicNetStatusResponse.NetStatus

    init(dynamicNetStatus: RustPB.Basic_V1_DynamicNetStatusResponse.NetStatus) {
        self.dynamicNetStatus = dynamicNetStatus
    }
}

class DynamicNetStatusPushHandler: BaseRustPushHandler<RustPB.Basic_V1_DynamicNetStatusResponse> {

    static var logger = Logger.log(DynamicNetStatusPushHandler.self, category: "Rust.PushHandler")

    private let pushCenter: PushNotificationCenter

    init(pushCenter: PushNotificationCenter) {
        self.pushCenter = pushCenter
    }

    override func doProcessing(message: RustPB.Basic_V1_DynamicNetStatusResponse) {
        self.pushCenter.post(PushDynamicNetStatus(dynamicNetStatus: message.netStatus))
        DynamicNetStatusPushHandler.logger.info("dynamicNetStatus: \(message.netStatus)")
    }
}
