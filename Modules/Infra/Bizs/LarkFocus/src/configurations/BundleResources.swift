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
        if let image: UIImage = ResourceManager.get(key: "LarkFocus.\(named)", type: "image") {
            return image
        }
        #endif
        return UIImage(named: named, in: BundleConfig.LarkFocusBundle, compatibleWith: nil) ?? UIImage()
    }
    /*
    * you can load image like that:
    *
    * static let tabbar_conversation_shadow = BundleResources.image(named: "tabbar_conversation_shadow")
    */
    final class LarkFocus {
        static let onboarding_custom = BundleResources.image(named: "custom_status_onboarding_custom")
        static let onboarding_mute = BundleResources.image(named: "custom_status_onboarding_mute")
        static let onboarding_sync = BundleResources.image(named: "custom_status_onboarding_sync")
        static let default_icon_rest = BundleResources.image(named: "default_icon_rest")
        static let default_icon_on_leave = BundleResources.image(named: "default_icon_on_leave")
        static let default_icon_in_meeting = BundleResources.image(named: "default_icon_in_meeting")
        static let default_icon_not_disturb = BundleResources.image(named: "default_icon_not_disturb")
    }
}
//swiftlint:enable all
