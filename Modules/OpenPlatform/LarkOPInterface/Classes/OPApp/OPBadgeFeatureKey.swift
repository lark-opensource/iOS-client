//
//  OPBadgeFeatureKey.swift
//  LarkOPInterface
//
//  Created by ByteDance on 2023/10/19.
//

import Foundation
import LarkSetting

public enum OPBadgeFeatureKey: String {
    case newOpenAppTabBadge = "lark.open_platform.new_app_tab_badge"
    
    case enableGadgetAppBadge = "gadget.open_app.badge"
    
    case enableMainTabOpenplatformAppBadge = "openplatform.main_tab.op_app_badge"
    
    public var key: FeatureGatingManager.Key {
        FeatureGatingManager.Key(stringLiteral: rawValue)
    }
}
