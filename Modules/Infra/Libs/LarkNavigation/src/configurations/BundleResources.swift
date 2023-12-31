// Warning: Do Not Edit It!
// Created by EEScaffold, if you want to edit it please check the manual of EEScaffold
// Toolchains For EE, be fast
/*
*
*
*  ______ ______ _____        __
* |  ____|  ____|_   _|      / _|
* | |__  | |__    | |  _ __ | |_ _ __ __ _
* |  __| |  __|   | | | '_ \|  _| '__/ _` |
* | |____| |____ _| |_| | | | | | | | (_| |
* |______|______|_____|_| |_|_| |_|  \__,_|
*
*
*/

import Foundation
import UIKit
import UniverseDesignIcon

// swiftlint:disable all
final class BundleResources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkNavigationBundle, compatibleWith: nil) ?? UIImage()
    }
    /*
    * you can load image like that:
    *
    * static let tabbar_conversation_shadow = BundleResources.image(named: "tabbar_conversation_shadow")
    */
    final class LarkNavigation {
        static let navibar_avatar_do_not_disturb_icon = BundleResources.image(named: "navibar_avatar_do_not_disturb_icon")
        static let navibar_avatar_upgrade_icon = BundleResources.image(named: "navibar_avatar_upgrade_icon")
        static let tab_more_button_normal = UDIcon.getIconByKey(.moreBoldOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN2)
        static let tab_more_button_selected = UDIcon.getIconByKey(.moreBoldOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.colorfulBlue)
        static let tab_tenant_add = UDIcon.getIconByKey(.addOutlined, size: CGSize(width: 32, height: 32)).ud.withTintColor(UIColor.ud.iconN1)
        static let exlamationMark = BundleResources.image(named: "exlamationMark")
        static let refreshTabIcon = UDIcon.getIconByKey(.replaceOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.primaryContentDefault)
        static let closeTipIcon = UDIcon.getIconByKey(.closeOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.N800)
        static let bg_theme_default = BundleResources.image(named: "bg_theme_default")
        
        final class MainTab {
            static let tabbar_microApp_shadow = BundleResources.image(named: "tabbar_main_default")
            static let tabbar_microApp_light = BundleResources.image(named: "tabbar_main_selected_default")
        }
    }

}
//swiftlint:enable all
