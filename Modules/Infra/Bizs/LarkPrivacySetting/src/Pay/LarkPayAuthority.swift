//
//  LarkPayAuthority.swift
//  LarkPrivacySetting
//
//  Created by ByteDance on 2023/7/10.
//

import UIKit
import Foundation
import LarkSecurityAudit
import UniverseDesignToast
import ServerPB

public final class LarkPayAuthority {
    public static func checkPayAuthority() -> Bool {
        let securityAudit = SecurityAudit()
        var object = ServerPB_Authorization_CustomizedEntity()
        object.id = String(ServerPB_Authorization_ThridPartySDKAuthEffectType.paySdk.rawValue)
        object.entityType = "SDK"
        let authResult = securityAudit.checkAuth(permType: .sdkSwitch, object: object)
        return authResult != .deny
    }
}
