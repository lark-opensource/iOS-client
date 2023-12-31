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

//swiftlint:disable all
final class BundleResources {
    private static func image(named: String) -> UIImage {
        #if USE_DYNAMIC_RESOURCE
        if let image: UIImage = ResourceManager.get(key: "ByteViewSetting.\(named)", type: "image") {
            return image
        }
        #endif
        return UIImage(named: named, in: BundleConfig.ByteViewSettingBundle, compatibleWith: nil) ?? UIImage()
    }
    /*
    * you can load image like that:
    *
    * static let tabbar_conversation_shadow = BundleResources.image(named: "tabbar_conversation_shadow")
    */
    class ByteViewSetting {
        class Settings {
            static let bot_reminder = BundleResources.image(named: "bot_reminder")
            static let fullScreen = BundleResources.image(named: "fullScreen")
            static let iconAvatarCalendarColorful = BundleResources.image(named: "iconAvatarCalendarColorful")
            static let record_layout_gride = BundleResources.image(named: "record_layout_gride")
            static let red_pot_reminder = BundleResources.image(named: "red_pot_reminder")
            static let sideBySide = BundleResources.image(named: "sideBySide")
            static let speaker = BundleResources.image(named: "speaker")
        }
    }

}
//swiftlint:enable all
