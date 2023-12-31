//
//  WaterMark+Push.swift
//  LarkWaterMark
//
//  Created by 李晨 on 2021/4/26.
//

import Foundation
import RustPB
import LarkRustClient
import LKCommonsLogging
import LarkContainer

struct WaterMarkPushModel: PushMessage {
    let obviousEnabled: Bool
    let hiddenEnabled: Bool
    let userContent: String
    let clearStyle: [String: String]
}

final class WaterMarkPushHandler: BaseRustPushHandler<RustPB.Passport_V1_PushWaterMarkConfigResponse> {
    static var logger = Logger.log(WaterMarkPushHandler.self, category: "WaterMark")

    // swiftlint:disable all
    var pushCenter: PushNotificationCenter? = implicitResolver?.pushCenter
    // swiftlint:enable all
    
    override public func doProcessing(message: RustPB.Passport_V1_PushWaterMarkConfigResponse) {
        let logStr = """
            receive watermark push obviousEnabled:\(message.obviousEnabled)
            hiddenEnabled:\(message.hiddenEnabled)
            contentLength:\(message.content.count)
            obviousStyle:\(message.clearStyle_p)
            """
        WaterMarkPushHandler.logger.info(logStr)
        self.pushCenter?.post(
            WaterMarkPushModel(
                obviousEnabled: message.obviousEnabled,
                hiddenEnabled: message.hiddenEnabled,
                userContent: message.content,
                clearStyle: message.clearStyle_p
            )
        )
    }
}
