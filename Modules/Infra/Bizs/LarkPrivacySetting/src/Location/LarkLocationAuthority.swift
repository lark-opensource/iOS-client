//
//  LarkLocationSetting.swift
//  LarkPrivacySetting
//
//  Created by aslan on 2022/4/7.
//

import UIKit
import Foundation
import LarkSecurityAudit
import UniverseDesignToast
import ServerPB

public final class LarkLocationAuthority {
    static public func checkAuthority() -> Bool {
        let securityAudit = SecurityAudit()
        let authResult = securityAudit.checkAuth(permType: .privacyGpsLocation)
        return authResult != .deny
    }

    static public func showDisableTip(on view: UIView) {
        let toast = BundleI18n.LarkPrivacySetting.Lark_Core_AdminSettingNoGPSPermission_Toast
        UDToast.showFailure(with: toast, on: view)
    }

    public static func checkAmapAuthority() -> Bool {
        let securityAudit = SecurityAudit()
        var object = ServerPB_Authorization_CustomizedEntity()
        object.id = String(ServerPB_Authorization_ThridPartySDKAuthEffectType.amapSdk.rawValue)
        object.entityType = "SDK"
        let authResult = securityAudit.checkAuth(permType: .sdkSwitch, object: object)
        return authResult != .deny
    }
}
