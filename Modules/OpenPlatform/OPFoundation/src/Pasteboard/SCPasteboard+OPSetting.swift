//
//  SCPasteboard+OPSetting.swift
//  OPFoundation
//
//  Created by baojianjun on 2022/9/6.
//

import Foundation
import LarkEMM
import LarkSetting
import LKCommonsLogging

extension SCPasteboard {
    
    private static let op_logger = Logger.oplog(SCPasteboard.self, category: "OPSetting")
    private static let kOPSafePasteboardAlertDisable = UserSettingKey.make(userKeyLiteral: "openplatform_safe_pasteboard_alert_disable")
    
    private static func opAlertDisable(appID: String) -> Bool {
        // TODOZJX
        guard let setting: [String: Any] = try? SettingManager.shared.setting(with: kOPSafePasteboardAlertDisable) else {
            op_logger.error("cannot find setting with key: \(kOPSafePasteboardAlertDisable)")
            return false
        }
        if let whiteList = setting["white_list"] as? [String: Any],
           let whiteListValue = whiteList[appID] as? Bool {
            op_logger.info("appID: \(appID), value: \(whiteListValue) in white list")
            return whiteListValue
        }
        if let defaultResult = setting["default"] as? Bool {
            op_logger.info("appID: \(appID) with default value: \(defaultResult)")
            return defaultResult
        }
        op_logger.error("appID: \(appID) is not in white list, and cannot find default value")
        return false
    }
    
    public static func opApiGeneral(token: OPSensitivityEntryToken,  appID: String) -> SCPasteboard {
        let disableAlert = Self.opAlertDisable(appID: appID)
        return Self.general(PasteboardConfig(token: token.psdaToken, ignoreAlert: disableAlert ))
    }
}



@objcMembers
public final class SCPasteboardOCBridge: NSObject {
    
    // OC过来的appid认为可能为空, 并取魔数-1
    private static let nullDefaultAppID = "-1"
    
    @objc
    public static func opApiSetGeneral(token: OPSensitivityEntryToken, appID: String?, string: String?) {
        SCPasteboard.opApiGeneral(token: token, appID: appID ?? nullDefaultAppID).string = string
    }
    @objc
    public static func setGeneral(token: OPSensitivityEntryToken, string: String?) {
        let config = PasteboardConfig(token:token.psdaToken)
        SCPasteboard.general(config).string = string
    }
    
    @objc
    public static func getGeneralString(token: OPSensitivityEntryToken) -> String? {
        let config = PasteboardConfig(token:token.psdaToken)
        return SCPasteboard.general(config).string
    }
}
