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

#if USE_DYNAMIC_RESOURCE
import LarkResource
#endif

//swiftlint:disable all
final class BundleResources {
    private static func image(named: String) -> UIImage {
        #if USE_DYNAMIC_RESOURCE
        if let image: UIImage = ResourceManager.get(key: "LarkOpenPlatform.\(named)", type: "image") {
            return image
        }
        #endif
        return UIImage(named: named, in: BundleConfig.LarkOpenPlatformBundle, compatibleWith: nil) ?? UIImage()
    }
    /*
    * you can load image like that:
    *
    * static let tabbar_conversation_shadow = BundleResources.image(named: "tabbar_conversation_shadow")
    */
    class LarkOpenPlatform {
        static let icon_robot_help = BundleResources.image(named: "icon_robot_help")
        static let more_chat_action = BundleResources.image(named: "more_chat_action")
        static let user_display_config_placehold = BundleResources.image(named: "user_display_config_placehold")
        static let user_display_config_placehold_darkmode = BundleResources.image(named: "user_display_config_placehold_darkmode")
        static let user_display_config_placehold_en = BundleResources.image(named: "user_display_config_placehold_en")
        static let user_display_config_placehold_en_darkmode = BundleResources.image(named: "user_display_config_placehold_en_darkmode")
        static let card_message_menu_copy = UDIcon.getIconByKey(.copyOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        class AppDetail {
            static let app_version_check_failed = BundleResources.image(named: "app_version_check_failed")
            static let app_version_upgrade = BundleResources.image(named: "app_version_upgrade")
            static let icon_warning_outlined = BundleResources.image(named: "icon_warning_outlined")
            static let isv_developer = BundleResources.image(named: "isv_developer")
            static let message_bot_tag = BundleResources.image(named: "message_bot_tag")
        }
    }

}
//swiftlint:enable all
