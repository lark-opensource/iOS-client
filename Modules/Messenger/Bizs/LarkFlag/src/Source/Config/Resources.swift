//
//  Resources.swift
//  LarkFlag
//
//  Created by phoenix on 2022/5/29.
//

import Foundation
import UIKit
import LarkUIKit
import LarkAppResources
import UniverseDesignEmpty
import UniverseDesignIcon
import UniverseDesignColor

public final class Resources {
    public static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkFlagBundle, compatibleWith: nil) ?? UIImage()
    }

    static let quickSwitcher_toTop = UDIcon.getIconByKey(.setTopOutlined, size: CGSize(width: 18, height: 18)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let quickSwitcher_top = UDIcon.getIconByKey(.setTopCancelOutlined, size: CGSize(width: 18, height: 18)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let feed_create_scene_contextmenu = UDIcon.getContextMenuIconBy(key: .sepwindowOutlined).ud.withTintColor(UIColor.ud.iconN1)
    static let navi_plus_scan = UDIcon.getIconByKey(.scanOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2)
    static let label_contextmenu = UDIcon.getContextMenuIconBy(key: .labelCustomOutlined).ud.withTintColor(UIColor.ud.iconN1)
    static let team_contextmenu = UDIcon.getContextMenuIconBy(key: .communityTabOutlined).ud.withTintColor(UIColor.ud.iconN1)

    static let sidebar_filtertab_flag = UDIcon.getIconByKey(.flagOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2)
    static let sidebar_filtertab_flag_selected = UDIcon.getIconByKey(.flagOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.textLinkHover)
    static let clearUnreadBaged = UDIcon.getIconByKey(.clearUnreadOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1)
}
