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
import UniverseDesignEmpty

#if USE_DYNAMIC_RESOURCE
import LarkResource
import LarkMessageBase
#endif

//swiftlint:disable all
final class BundleResources {
    private static func image(named: String) -> UIImage {
        #if USE_DYNAMIC_RESOURCE
        if let image: UIImage = ResourceManager.get(key: "LarkContact.\(named)", type: "image") {
            return image
        }
        #endif
        return UIImage(named: named, in: BundleConfig.LarkContactBundle, compatibleWith: nil) ?? UIImage()
    }
    /*
    * you can load image like that:
    *
    * static let tabbar_conversation_shadow = BundleResources.image(named: "tabbar_conversation_shadow")
    */
    final class LarkContact {
        final class Contact {
            static let dark_right_arrow = BundleResources.image(named: "dark_right_arrow")
            static let edu_empty = BundleResources.image(named: "edu_empty")
            static let icon_global_back_black = BundleResources.image(named: "icon_global_back_black")
            static let icon_tenant_default = BundleResources.image(named: "icon_tenant_default")
            static let inactived_avatar = BundleResources.image(named: "inactived_avatar")
        }
        final class ContactApplication {
            static let add_friend_from_contact = BundleResources.image(named: "add_friend_from_contact")
        }
        final class ContactPickList {
            static let contacts_import_banner = BundleResources.image(named: "contacts_import_banner")
        }
        final class CreateGroup {
            static let descriptionImage_black_people = BundleResources.image(named: "descriptionImage_black_people")
            static let descriptionImage_chat = BundleResources.image(named: "descriptionImage_chat")
            static let descriptionImage_indian_people = BundleResources.image(named: "descriptionImage_indian_people")
            static let descriptionImage_secret = BundleResources.image(named: "descriptionImage_secret")
            static let descriptionImage_secret_title_icon = BundleResources.image(named: "descriptionImage_secret_title_icon")
            static let descriptionImage_thread = BundleResources.image(named: "descriptionImage_thread")
            static let descriptionImage_white_people = BundleResources.image(named: "descriptionImage_white_people")
            static let descriptionImage_yellow_people = BundleResources.image(named: "descriptionImage_yellow_people")
            static let description_bottom = BundleResources.image(named: "description_bottom")
            static let selected = BundleResources.image(named: "selected")
            static let unselected = BundleResources.image(named: "unselected")
        }
        final class CreateTeam {
            static let blue_check = BundleResources.image(named: "blue_check")
            static let close_dark_gray = BundleResources.image(named: "close_dark_gray")
        }
        final class Department {
            static let department_default_icon = BundleResources.image(named: "department_default_icon")
            static let department_picker_default_icon = BundleResources.image(named: "department_picker_default_icon")
        }
        final class Group {
            static let department = BundleResources.image(named: "department")
        }
        final class UserGroup {
            static let user_group = BundleResources.image(named: "user_group")
        }
        final class Intive {
            static let invite = BundleResources.image(named: "invite")
            static let invite_partners = BundleResources.image(named: "invite_partners")
            static let invite_scan = BundleResources.image(named: "invite_scan")
        }
        final class InviteUnion {
            static let arrow_down_country_code = BundleResources.image(named: "arrow_down_country_code")
            static let entrance_teamcode = BundleResources.image(named: "entrance_teamcode")
            static let external_invite_illustration = BundleResources.image(named: "external_invite_illustration")
            static let gradient_background = BundleResources.image(named: "gradient_background")
            static let invite_send_icon = BundleResources.image(named: "invite_send_icon")
            static let invite_send_icon_unable = BundleResources.image(named: "invite_send_icon_unable")
            static let member_invite_gif_cover = BundleResources.image(named: "member_invite_gif_cover")
            static let member_invite_illustration = BundleResources.image(named: "member_invite_illustration")
            static let member_link_invite_cover = BundleResources.image(named: "member_link_invite_cover")
            static let privary_protection = BundleResources.image(named: "privary_protection")
            static let red_packet_icon = BundleResources.image(named: "red_packet_icon")
            static let switch_to_link = BundleResources.image(named: "switch_to_link")
            static let switch_to_qrcode = BundleResources.image(named: "switch_to_qrcode")
            static let team_code_play = BundleResources.image(named: "team_code_play")
            static let teamcode_invite_icon = BundleResources.image(named: "teamcode_invite_icon")
            static let wechat_invite_icon = BundleResources.image(named: "wechat_invite_icon")
        }
        final class NameCard {
            static let icon_add_namecard = BundleResources.image(named: "icon_add_namecard")
            static let namecard_default_avatar = BundleResources.image(named: "namecard_default_avatar")
        }
        final class PhoneQueryLimit {
            static let clear_number_icon = BundleResources.image(named: "clear_number_icon")
        }
        final class TopStructure {
            static let contact_application = BundleResources.image(named: "contact_application")
            static let nameCard = BundleResources.image(named: "nameCard")
            static let team_conversion = BundleResources.image(named: "team_conversion")
        }
        final class MailProfile {
            static let mail_profile_background = BundleResources.image(named: "mail_profile_background")
        }
        final class UG {
            static let emoji_pin = BundleResources.image(named: "emoji_pin")
            static let emoji_status_privatemessage = BundleResources.image(named: "emoji_status_privatemessage")
            static let new_version_7 = BundleResources.image(named: "new_version_7.0")
            static let pad_guide_en = BundleResources.image(named: "pad_guide_en")
            static let pad_guide_zh = BundleResources.image(named: "pad_guide_zh")
            static let new_version_background_pad = BundleResources.image(named: "new_version_background_pad")
            static let new_version_background_phone = BundleResources.image(named: "new_version_background_phone")
        }
    }

}
//swiftlint:enable all
