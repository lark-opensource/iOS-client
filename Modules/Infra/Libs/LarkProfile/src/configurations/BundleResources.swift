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
        if let image: UIImage = ResourceManager.get(key: "LarkProfile.\(named)", type: "image") {
            return image
        }
        #endif
        return UIImage(named: named, in: BundleConfig.LarkProfileBundle, compatibleWith: nil) ?? UIImage()
    }
    /*
    * you can load image like that:
    *
    * static let tabbar_conversation_shadow = BundleResources.image(named: "tabbar_conversation_shadow")
    */
    final class LarkProfile {
        static let default_bg_image = BundleResources.image(named: "default_bg_image_thumb")
        static let background_image = BundleResources.image(named: "background_image")
        static let invalid_bg_image = BundleResources.image(named: "invalid_bg_image")
        static let more = BundleResources.image(named: "more")
        static let multi_language_avatar = BundleResources.image(named: "multi_language_avatar")
    }
}
//swiftlint:enable all
