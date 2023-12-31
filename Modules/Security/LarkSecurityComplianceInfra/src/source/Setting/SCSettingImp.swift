//
//  SCSettingImp.swift
//  LarkSecurityComplianceInfra
//
//  Created by ByteDance on 2023/7/26.
//

import Foundation
import SwiftyJSON
import LarkContainer
import LarkSetting

struct SCSettingsIMP: SCSettingService {
    static let settingKey = UserSettingKey.make(userKeyLiteral: "lark_security_compliance_config")
    let json: JSON

    init(resolver: UserResolver) {
        do {
            let settingService = try resolver.resolve(assert: SettingService.self)
            let settings = try settingService.staticSetting(with: Self.settingKey)
            self.json = JSON(rawValue: settings) ?? JSON()
            SCLogger.info("SCStaticSettings init with settings \(settings)")
        } catch {
            self.json = JSON()
            SCLogger.info("SCStaticSettings init failed")
            SCMonitor.error(business: .settings,
                            eventName: "init_fail",
                            error: error)
        }
    }
}
