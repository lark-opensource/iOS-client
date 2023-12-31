//
//  Resource.swft.swift
//  AnimatedTabBar
//
//  Created by Aslan on 2021/9/14.
//

import Foundation
import UIKit
import UniverseDesignIcon

// swiftlint:disable all
final class Resources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.AnimatedTabBarBundle, compatibleWith: nil) ?? UIImage()
    }
    /*
    * you can load image like that:
    *
    * static let tabbar_conversation_shadow = BundleResources.image(named: "tabbar_conversation_shadow")
    */
    final class AnimatedTabBar {
        static let quick_tab_btn_add = UDIcon.getIconByKey(.addColorful, size: CGSize(width: 22, height: 22))
        static let quick_tab_btn_delete = UDIcon.getIconByKey(.deleteColorful, size: CGSize(width: 22, height: 22))
        static let tab_more_button_normal = UDIcon.getIconByKey(.moreOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN3)
        static let tab_more_button_selected = UDIcon.getIconByKey(.tabMoreColorful, size: CGSize(width: 22, height: 22))
        // TODO: @wanghaidong 等加入了 UDIcon 后换上
        static let tab_launch_button_normal = Resources.image(named: "icon_launcher_outlined")
        static let tab_launch_button_selected = Resources.image(named: "icon_launcher-exit_outlined")
        // static let tab_launch_button_normal = UDIcon.getIconByKey(.launcherOutlined, size: CGSize(width: 22, height: 22))
        // static let tab_launch_button_selected = UDIcon.getIconByKey(.launcherExitOutlined, size: CGSize(width: 22, height: 22))
        static let bgTabClear = Resources.image(named: "bg_tabbar_clear")
    }
}
//swiftlint:enable all
