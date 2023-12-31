//
//  AppLockSettingVerifyConstKey.swift
//  LarkEMM
//
//  Created by ByteDance on 2023/11/2.
//

import Foundation
import LarkSecurityComplianceInfra

struct AppLockSettingVerifyConstKey {
    static let baseHeight: CGFloat = 574
    static let padDisplayMaxContainerWidth: CGFloat = 375
    static let profileViewTopOffsetSizeIndex = 0
    static let padViewTopOffsetSizeIndex = 1
    static let assistantInfoViewTopOffsetSizeIndex = 2
    static let assistantInfoViewBottomOffsetSizeIndex = 3
    
    static var safeBaseHeight: CGFloat {
        Self.baseHeight + Self.safeAreaInsetsVertical
    }
    
    static var safeAreaInsetsVertical: CGFloat {
        LayoutConfig.safeAreaInsets.top + LayoutConfig.safeAreaInsets.bottom
    }
}
