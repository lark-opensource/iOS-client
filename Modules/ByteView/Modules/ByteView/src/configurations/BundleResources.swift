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
        if let image: UIImage = ResourceManager.get(key: "ByteView.\(named)", type: "image") {
            return image
        }
        #endif
        return UIImage(named: named, in: BundleConfig.ByteViewBundle, compatibleWith: nil) ?? UIImage()
    }
    /*
    * you can load image like that:
    *
    * static let tabbar_conversation_shadow = BundleResources.image(named: "tabbar_conversation_shadow")
    */
    class ByteView {
        static let notes = BundleResources.image(named: "notes")
        static let notes_w = BundleResources.image(named: "notes_w")
        class Call {
            static let CallDecline = BundleResources.image(named: "CallDecline")
            static let deviceWarningIcon = BundleResources.image(named: "deviceWarningIcon")
        }
        class Definition {
            static let pic_1080p_mobile = BundleResources.image(named: "pic_1080p_mobile")
            static let pic_1080p_pad = BundleResources.image(named: "pic_1080p_pad")
            static let pic_2K_mobile = BundleResources.image(named: "pic_2K_mobile")
            static let pic_2k_pad = BundleResources.image(named: "pic_2k_pad")
            static let pic_4K_mobile = BundleResources.image(named: "pic_4K_mobile")
            static let pic_4k_pad = BundleResources.image(named: "pic_4k_pad")
        }
        class Interview {
            static let QuestionnaireIllustration = BundleResources.image(named: "QuestionnaireIllustration")
        }
        class JoinRoom {
            static let connect_to_room = BundleResources.image(named: "connect_to_room")
            static let pad_mute = BundleResources.image(named: "pad_mute")
            static let phone_mute = BundleResources.image(named: "phone_mute")
            static let room_connected = BundleResources.image(named: "room_connected")
            static let room_found = BundleResources.image(named: "room_found")
            static let room_mic_half = BundleResources.image(named: "room_mic_half")
            static let room_mic_off = BundleResources.image(named: "room_mic_off")
            static let room_mic_on = BundleResources.image(named: "room_mic_on")
            static let room_not_found = BundleResources.image(named: "room_not_found")
        }
        class Lab {
            static let ValueTriang = BundleResources.image(named: "ValueTriang")
            static let VirtualBg = BundleResources.image(named: "VirtualBg")
        }
        class Live {
            static let DepartmentAvatar = BundleResources.image(named: "DepartmentAvatar")
            static let FullScreenUnselected = BundleResources.image(named: "FullScreenUnselected")
            static let GalleryViewUnselected = BundleResources.image(named: "GalleryViewUnselected")
            static let ListViewUnselected = BundleResources.image(named: "ListViewUnselected")
        }
        class Meet {
            static let guide_click = BundleResources.image(named: "guide_click")
            static let iconBreakoutroomsSolid = BundleResources.image(named: "iconBreakoutroomsSolid")
            static let iconMicFilled02 = BundleResources.image(named: "iconMicFilled02")
            static let iconMobileWindow = BundleResources.image(named: "iconMobileWindow")
            class ExclusiveReaction {
                static let VC_CanNotSee_en = BundleResources.image(named: "VC_CanNotSee_en")
                static let VC_CanNotSee_zh = BundleResources.image(named: "VC_CanNotSee_zh")
                static let VC_LooksGood_en = BundleResources.image(named: "VC_LooksGood_en")
                static let VC_LooksGood_zh = BundleResources.image(named: "VC_LooksGood_zh")
                static let VC_NoSound_en = BundleResources.image(named: "VC_NoSound_en")
                static let VC_NoSound_zh = BundleResources.image(named: "VC_NoSound_zh")
                static let VC_SoundsClear_en = BundleResources.image(named: "VC_SoundsClear_en")
                static let VC_SoundsClear_zh = BundleResources.image(named: "VC_SoundsClear_zh")
            }
            class StatusEmoji {
                static let DarkHandsUp = BundleResources.image(named: "DarkHandsUp")
                static let HandsUp = BundleResources.image(named: "HandsUp")
                static let LightHandsUp = BundleResources.image(named: "LightHandsUp")
                static let MediumDarkHandsUp = BundleResources.image(named: "MediumDarkHandsUp")
                static let MediumHandsUp = BundleResources.image(named: "MediumHandsUp")
                static let MediumLightHandsUp = BundleResources.image(named: "MediumLightHandsUp")
                static let emoji_quickleave = BundleResources.image(named: "emoji_quickleave")
            }
        }
        class Participants {
            static let Dndisturbed = BundleResources.image(named: "Dndisturbed")
            static let PartcioantSearchTopLayer = BundleResources.image(named: "PartcioantSearchTopLayer")
        }
        class ToolBar {
            static let disable_icon = BundleResources.image(named: "disable_icon")
        }
    }

}
//swiftlint:enable all
