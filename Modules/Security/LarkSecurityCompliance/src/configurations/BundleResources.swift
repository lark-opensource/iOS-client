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
        if let image: UIImage = ResourceManager.get(key: "LarkSecurityCompliance.\(named)", type: "image") {
            return image
        }
#endif
        return UIImage(named: named, in: BundleConfig.LarkSecurityComplianceBundle, compatibleWith: nil) ?? UIImage()
    }
    /*
     * you can load image like that:
     *
     * static let tabbar_conversation_shadow = BundleResources.image(named: "tabbar_conversation_shadow")
     */
    class LarkSecurityCompliance {
        static let checkbox_selected = BundleResources.image(named: "checkbox_selected")
        static let device_refresh_icon = BundleResources.image(named: "device_refresh_icon")
        static let pattern_bg = BundleResources.image(named: "pattern_bg")
        static let pattern_bg_ipad = BundleResources.image(named: "pattern_bg_ipad")
        static let select_icon = BundleResources.image(named: "select_icon")
        class Encryption_upgrade {
            static let negative_failed = BundleResources.image(named: "negative_failed")
            static let negative_succeess = BundleResources.image(named: "negative_succeess")
            static let negative_upgrading = BundleResources.image(named: "negative_upgrading")
            static let positive_failed = BundleResources.image(named: "positive_failed")
            static let positive_success = BundleResources.image(named: "positive_success")
            static let positive_upgrading = BundleResources.image(named: "positive_upgrading")
        }
    }
    
}
// swiftlint:enable all
