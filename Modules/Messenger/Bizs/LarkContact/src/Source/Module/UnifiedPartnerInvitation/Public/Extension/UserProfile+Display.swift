//
//  UserProfile+Display.swift
//  LarkContact
//
//  Created by 开不了口的猫 on 2019/11/13.
//

import Foundation
import LarkModel
import LarkLocalizations
import LarkSDKInterface

extension UserProfile {
    var displayNameForSearch: String {
        if !alias.isEmpty {
            return alias
        } else {
            let currentLanguage: Lang = LanguageManager.currentLanguage
            let name = !localizedName.isEmpty ? localizedName : self.name
            switch currentLanguage {
            case .en_US:
                return !enName.isEmpty ? enName : name
            default:
                return name
            }
        }
    }
}
