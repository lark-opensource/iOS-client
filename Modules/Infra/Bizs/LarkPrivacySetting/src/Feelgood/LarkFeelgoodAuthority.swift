//
//  LarkFeelgoodAuthority.swift
//  LarkPrivacySetting
//
//  Created by Yuri on 2022/4/7.
//

import UIKit
import Foundation
import LarkSecurityAudit
import UniverseDesignToast
import ServerPB

public final class LarkFeelgoodAuthority {
    public static func checkSDKAuthority() -> Bool {
        let securityAudit = SecurityAudit()
        var object = ServerPB_Authorization_CustomizedEntity()
        object.id = String(ServerPB_Authorization_ThridPartySDKAuthEffectType.feelGood.rawValue)
        object.entityType = "SDK"
        let authResult = securityAudit.checkAuth(permType: .sdkSwitch, object: object)
        return authResult != .deny
    }
}
