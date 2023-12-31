//
//  GeneralConfigSettingsPushHandler.swift
//  LarkSDK
//
//  Created by Fangzhou Liu on 2019/8/9.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LKCommonsLogging

// GeneralConfigSettings
// 通用配置
/// @available(*, deprecated, message: "should migrate to LarkSetting")
public struct PushGeneralConfig: PushMessage {
    public let fieldGroups: [String: String]
    public init(fieldGroups: [String: String]) {
        self.fieldGroups = fieldGroups
    }
}

final class GeneralConfigSettingsPushHandler: BaseRustPushHandler<RustPB.Settings_V1_PushSettings> {
    static var logger = Logger.log(GeneralConfigSettingsPushHandler.self, category: "Rust.PushHandler")

    private let pushCenter: PushNotificationCenter

    init(pushCenter: PushNotificationCenter) {
        self.pushCenter = pushCenter
    }

    override func doProcessing(message: RustPB.Settings_V1_PushSettings) {
        self.pushCenter.post(PushGeneralConfig(fieldGroups: message.fieldGroups))
    }
}
