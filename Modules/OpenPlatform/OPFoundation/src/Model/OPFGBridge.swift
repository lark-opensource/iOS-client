//
//  OPFGBridge.swift
//  OPFoundation
//
//  Created by Nicholas Tau on 2023/6/14.
//

import Foundation
import LarkFeatureGating
import LarkSetting
import LKCommonsLogging

@objcMembers public final class OPFGBridge: NSObject {
    private static let logger = Logger.oplog(OPFGBridge.self, category: "OPFoundation")
    /// 小程序关于页/API是否去除用 MD5 检查有更新的能力【默认不配置，走原逻辑】
    public static func disableAppUpdateCheckWithMD5Verify() -> Bool {
        let value = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.pkm.about.api.checkupdate.md5.disable.610"))
        logger.info("OPSDKFeatureGating->disableAppUpdateCheckWithMD5Verify value:\(value)")
        return value
    }
}

