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

#if USE_DYNAMIC_RESOURCE
import LarkResource
#endif

// swiftlint:disable all
final class BundleResources {
    private static func image(named: String) -> UIImage {
#if USE_DYNAMIC_RESOURCE
        if let image: UIImage = ResourceManager.get(key: "LarkEMM.\(named)", type: "image") {
            return image
        }
#endif
        return UIImage(named: named, in: BundleConfig.LarkEMMBundle, compatibleWith: nil) ?? UIImage()
    }
    /*
     * you can load image like that:
     *
     * static let tabbar_conversation_shadow = BundleResources.image(named: "tabbar_conversation_shadow")
     */
    class LarkEMM {
        static let app_lock_bg_icon = BundleResources.image(named: "app_lock_bg_icon")
        static let hide_pin_code_icon_1 = BundleResources.image(named: "hide_pin_code_icon_1")
        static let lock_numberpad_del_1 = BundleResources.image(named: "lock_numberpad_del_1")
        static let show_pin_code_icon_1 = BundleResources.image(named: "show_pin_code_icon_1")
    }
    
}
// swiftlint:enable all
