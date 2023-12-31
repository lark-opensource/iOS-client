//
//  CTADomain.swift
//  CTADialog
//
//  Created by aslan on 2023/10/11.
//

import Foundation
import LarkContainer
import LarkSetting

struct CTADomain {
    static func getDomain(userResolver: UserResolver) -> String? {
        let settings = DomainSettingManager.shared.currentSetting
        return settings[.api]?.first ?? ""
    }
}
