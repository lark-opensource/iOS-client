//Warning: Do Not Edit It!
//Created by EEScaffold, if you want to edit it please check the manual of EEScaffold
//Toolchains For EE, be fast
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

//swiftlint:disable all
final class BundleResources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkAIBundle, compatibleWith: nil) ?? UIImage()
    }
    /*
    * you can load image like that:
    *
    * static let tabbar_conversation_shadow = BundleResources.image(named: "tabbar_conversation_shadow")
    */
    final class LarkAI {
        static let menu_query_abbreviation = UDIcon.getIconByKey(.cardSearchOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_translate = UDIcon.getIconByKey(.translateOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_hide_translate = UDIcon.getIconByKey(.visibleLockOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_switchLanguage = UDIcon.getIconByKey(.transSwitchOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        final class Translate {
            static let translate_arrow = BundleResources.image(named: "translate_arrow")
            static let translate_close = BundleResources.image(named: "translate_close")
            static let translate_star_dark = BundleResources.image(named: "translate_star_dark")
            static let translate_star_light = BundleResources.image(named: "translate_star_light")
            static let translate_suggesion_nomal = BundleResources.image(named: "translate_suggesion_nomal")
            static let translate_suggesion_selected = BundleResources.image(named: "translate_suggesion_selected")
        }
    }

}
//swiftlint:enable all
