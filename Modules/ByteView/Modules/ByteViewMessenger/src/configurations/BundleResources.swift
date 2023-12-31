//Warning: Do Not Edit It!
//Created by EEScaffold, if you want to edit it please check the manual of EEScaffold
//Toolchains For EE
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

//swiftlint:disable all
class BundleResources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.ByteViewMessengerBundle, compatibleWith: nil) ?? UIImage()
    }
    /*
     * you can load image like that:
     *
     * static let tabbar_conversation_shadow = BundleResources.image(named: "tabbar_conversation_shadow")
     */
    class Chat {
        static let guest = BundleResources.image(named: "guest")
        static let icon_encryptied_call = BundleResources.image(named: "icon_encryptied_call")
        static let meet_banner_icon = BundleResources.image(named: "meet_banner_icon")
        static let meet_banner_live = BundleResources.image(named: "meet_banner_live")
        static let meet_banner_more = BundleResources.image(named: "meet_banner_more")
        static let meet_banner_rec = BundleResources.image(named: "meet_banner_rec")
        static let meet_bar_selected = BundleResources.image(named: "meet_bar_selected")
        static let meet_bar_unselect = BundleResources.image(named: "meet_bar_unselect")
        static let meet_call = BundleResources.image(named: "meet_call")
        static let meet_card_ended = BundleResources.image(named: "meet_card_ended")
        static let meet_card_event = BundleResources.image(named: "meet_card_event")
        static let meet_card_join = BundleResources.image(named: "meet_card_join")
        static let meet_card_lock = BundleResources.image(named: "meet_card_lock")
        static let meet_card_lock_disabled = BundleResources.image(named: "meet_card_lock_disabled")
        static let meet_card_lock_pressed = BundleResources.image(named: "meet_card_lock_pressed")
        static let pstnAvatar = BundleResources.image(named: "pstnAvatar")
        static let sipAvatar = BundleResources.image(named: "sipAvatar")
        static let unknownAvatar = BundleResources.image(named: "unknownAvatar")
        static let voice_call = BundleResources.image(named: "voice_call")
    }

    class MinutesPreview {
        static let fileVideoColorful = BundleResources.image(named: "fileVideoColorful")
        static let tabVideoColorful = BundleResources.image(named: "tabVideoColorful")
        class BG {
            static let Call = BundleResources.image(named: "Call")
            static let Generating = BundleResources.image(named: "Generating")
            static let Video = BundleResources.image(named: "Video")
        }
    }
}
//swiftlint:enable all
