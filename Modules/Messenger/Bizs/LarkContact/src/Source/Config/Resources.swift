//
//  Resources.swift
//  LarkContact
//
//  Created by Sylar on 2018/3/21.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import UniverseDesignEmpty
import LarkLocalizations
import UniverseDesignIcon
import LarkIllustrationResource

#if USE_DYNAMIC_RESOURCE
import LarkResource
#endif

final class Resources {
    private static func image(named: String) -> UIImage {
        #if USE_DYNAMIC_RESOURCE
        if let image: UIImage = ResourceManager.get(key: "LarkContact.\(named)", type: "image") {
            return image
        }
        #endif
        return UIImage(named: named, in: LarkContactBundle, compatibleWith: nil) ?? UIImage()
    }

    // UDIcon替换 新增
    static let guide_team = UDIcon.getIconByKey(.teamCodeOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.primaryContentDefault)
    static let dispatch_next_arrow = UDIcon.rightOutlined
    static let icon_share_link = UDIcon.linkCopyOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let icon_contacts_invite = UDIcon.contactsOutlined
    static let icon_mail_invite = UDIcon.mailOutlined
    static let add_friend_from_contact = Resources.image(named: "add_friend_from_contact")
    static let group = UDIcon.getIconByKey(.groupOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulGreen)
    static let bot = UDIcon.getIconByKey(.robotOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulYellow)
    static let oncall = UDIcon.getIconByKey(.helpdeskOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulRed)
    static let structure = UDIcon.getIconByKey(.organizationOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulWathet)
    static let contact_application = Resources.image(named: "contact_application")
    static let userGroup = Resources.image(named: "userGroup")
    static let external = UDIcon.getIconByKey(.externalOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulIndigo)
    static let search = UDIcon.searchOutlineOutlined.ud.withTintColor(UIColor.ud.iconN1)
    static let reset_icon = UDIcon.getIconByKey(.refreshOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN2)

    static let department = Resources.image(named: "department")
    static let mine_right_arrow = UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 13, height: 13)).ud.withTintColor(UIColor.ud.iconN3)
    static let createNearbyGroup = UDIcon.getIconByKey(.nearbyGroupOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulYellow)
    static let faceToFaceKeyboardDeleteItem = UDIcon.deleteOutlined.ud.withTintColor(UIColor.ud.iconN2)

    static let navigation_close_light = UDIcon.closeOutlined.ud.withTintColor(UIColor.ud.iconN1)
    static let member_select_cancel = UDIcon.getIconByKey(.moreCloseOutlined, size: CGSize(width: 18, height: 18)).ud.withTintColor(UIColor.ud.iconN3)

    static let nameCard = Resources.image(named: "nameCard")
    static let namecardEditPhoneDown = UDIcon.getIconByKey(.downOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3)

    static let tabbar_contacts_light = UDIcon.getIconByKey(.contactsFilled, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.colorfulBlue)
    static let tabbar_contacts_shadow = UDIcon.getIconByKey(.contactsFilled, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconDisabled)

    static let close_white = UDIcon.closeOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let begin_edit_number_icon = UDIcon.getIconByKey(.editOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN2)
    static let clear_number_icon = Resources.image(named: "clear_number_icon")
    static let person_card_more_icon = UDIcon.moreOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)

    static let auth_tag = UDIcon.getIconByKey(.verifyFilled, size: CGSize(width: 12, height: 12)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let hideMore = UDIcon.getIconByKey(.upOutlined, size: CGSize(width: 10, height: 10)).ud.withTintColor(UIColor.ud.iconN2)
    static let right_arrow = UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 13, height: 13)).ud.withTintColor(UIColor.ud.iconN3)
    static let ShowDetail = UDIcon.getIconByKey(.downOutlined, size: CGSize(width: 10, height: 10)).ud.withTintColor(UIColor.ud.iconN2)

    static let subordinate = UDIcon.getIconByKey(.organizationOutlined, size: CGSize(width: 18, height: 18)).ud.withTintColor(UIColor.ud.colorfulWathet)
    static let invite = UDEmptyType.addFriends.defaultImage()
    static let invited = Resources.image(named: "invited")
    static let invite_partners = Resources.image(named: "invite_partners")
    static let invite_scan = Resources.image(named: "invite_scan")
    static let invite_search_contacts = UDIcon.getIconByKey(.memberAddOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulBlue)
    static let invite_search_empty = UDEmptyType.search.defaultImage()

    static let descriptionImage_chat = Resources.image(named: "descriptionImage_chat")
    static let descriptionImage_thread = Resources.image(named: "descriptionImage_thread")
    static let descriptionImage_secret = Resources.image(named: "descriptionImage_secret")
    static let descriptionImage_white_people = Resources.image(named: "descriptionImage_white_people")
    static let descriptionImage_black_people = Resources.image(named: "descriptionImage_black_people")
    static let descriptionImage_yellow_people = Resources.image(named: "descriptionImage_yellow_people")
    static let descriptionImage_indian_people = Resources.image(named: "descriptionImage_indian_people")
    static let descriptionImage_thread_share = UDIcon.getIconByKey(.shareOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let descriptionImage_secret_title_icon = Resources.image(named: "descriptionImage_secret_title_icon")
    static let descriptionImage_chat_arrow = UDIcon.getIconByKey(.expandRightFilled, size: CGSize(width: 12, height: 12)).ud.withTintColor(UIColor.ud.iconN1)
    static let description_bottom = Resources.image(named: "description_bottom")

    static let department_default_icon = Resources.image(named: "department_default_icon")
    static let department_picker_default_icon = Resources.image(named: "department_picker_default_icon")
    static let department_admin_icon = UDIcon.getIconByKey(.adminOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1)
    static let department_exit_team_icon = UDIcon.getIconByKey(.logoutOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1)

    static let language_select = UDIcon.getIconByKey(.listCheckOutlined, size: CGSize(width: 18, height: 18)).ud.withTintColor(UIColor.ud.colorfulBlue)

    static let unified_invite_icon = UDIcon.memberAddOutlined.ud.withTintColor(UIColor.ud.iconN1)
    static let invite_member_icon = UDIcon.getIconByKey(.teamAddOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulBlue)

    static let invite_contact_icon = UDIcon.getIconByKey(.memberAddOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulBlue)
    static let iconAddMember = UDIcon.memberAddOutlined.ud.withTintColor(UIColor.ud.iconN1)
    static let copy_qrcode = UDIcon.getIconByKey(.qrOutlined, size: CGSize(width: 18, height: 18)).ud.withTintColor(UIColor.ud.colorfulBlue)
    static let cancel_verify = UDIcon.getIconByKey(.closeOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3)
    static let arrow_down_country_code = Resources.image(named: "arrow_down_country_code")

    static let invite_help = UDIcon.maybeOutlined.ud.withTintColor(UIColor.ud.iconN1)
    static let switch_to_link_for_personalInfo = UDIcon.getIconByKey(.linkCopyOutlined, size: CGSize(width: 24, height: 24)).ud.withTintColor(UIColor.ud.iconN1)
    static let switch_to_qrcode_for_personalInfo = UDIcon.getIconByKey(.qrOutlined, size: CGSize(width: 24, height: 24)).ud.withTintColor(UIColor.ud.iconN1)
    static let external_invite_illustration = Resources.image(named: "external_invite_illustration")
    static let member_invite_illustration = Resources.image(named: "member_invite_illustration")
    static let add_from_contacts_icon = UDIcon.getIconByKey(.cellphoneOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulIndigo)
    static let createNearbyGroupFromContacts = UDIcon.getIconByKey(.nearbyGroupOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulGreen)
    static let invite_arrow = UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3)
    static let add_contact_icon = UDIcon.memberAddOutlined.ud.withTintColor(UIColor.ud.colorfulBlue)
    static let switch_to_qrcode = Resources.image(named: "switch_to_qrcode")
    static let switch_to_link = Resources.image(named: "switch_to_link")
    static let invite_send_icon = Resources.image(named: "invite_send_icon")
    static let invite_send_icon_unable = Resources.image(named: "invite_send_icon_unable")
    static let down_arrow = UDIcon.getIconByKey(.expandDownFilled, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN2)
    static let add_member_feedback = UDEmptyType.done.defaultImage()
    static let member_qrcode_refresh = UDIcon.getIconByKey(.refreshOutlined, size: CGSize(width: 12, height: 12)).ud.withTintColor(UIColor.ud.colorfulBlue)
    static let directed_invite_icon = UDIcon.getIconByKey(.editOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulBlue)
    static let qrcode_invite_icon = UDIcon.getIconByKey(.qrOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulWathet)
    static let link_invite_icon = UDIcon.getIconByKey(.linkCopyOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulOrange)
    static let split_channel_arrow = UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3)
    static let teamcode_invite_icon = Resources.image(named: "teamcode_invite_icon")
    static let feishu_invite_icon = UDIcon.getIconByKey(.larkOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulBlue)
    static let wechat_invite_icon = Resources.image(named: "wechat_invite_icon")
    static let red_packet_icon = Resources.image(named: "red_packet_icon")
    static let gradient_background = Resources.image(named: "gradient_background")
    static let member_invite_gif_cover = Resources.image(named: "member_invite_gif_cover")
    static let team_code_play = Resources.image(named: "team_code_play")
    static let addressbook_invite_icon = UDIcon.getIconByKey(.contactsOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulOrange)
    static let lark_split_contact = UDIcon.contactsOutlined.ud.withTintColor(UIColor.ud.colorfulGreen)
    static let lark_split_link = UDIcon.linkCopyOutlined.ud.withTintColor(UIColor.ud.colorfulOrange)
    static let lark_split_form = UDIcon.editOutlined.ud.withTintColor(UIColor.ud.colorfulWathet)
    static let lark_split_inapp = UDIcon.larkOutlined.ud.withTintColor(UIColor.ud.colorfulBlue)
    static let entrance_teamcode = Resources.image(named: "entrance_teamcode")
    static let entrance_qrcode = UDIcon.qrOutlined.ud.withTintColor(UIColor.ud.colorfulBlue)
    static let member_link_invite_cover = Resources.image(named: "member_link_invite_cover")
    static let switch_to_qrcode_for_member = UDIcon.getIconByKey(.qrOutlined, size: CGSize(width: 19, height: 19)).ud.withTintColor(UIColor.ud.iconN1)
    static let switch_to_link_for_member = UDIcon.linkCopyOutlined.ud.withTintColor(UIColor.ud.iconN1)
    static let my_qrcode_entrance = UDIcon.getIconByKey(.qrOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulWathet)
    static let privary_protection = Resources.image(named: "privary_protection")
    static let invite_external_guide = UDEmptyType.addFriends.defaultImage()
    static let contactEmpty = UDEmptyType.noContact.defaultImage()
    static let ldr_tips_icon = UDEmptyType.done.defaultImage()
    static let scan = UDIcon.getIconByKey(.scanOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulOrange)
    static let target_info = UDIcon.getIconByKey(.infoOutlined, iconColor: UIColor.ud.iconN3, size: CGSize(width: 20, height: 20))

    static let team_conversion = Resources.image(named: "team_conversion")
    static let team_conversion_close = UDIcon.getIconByKey(.closeOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3)
    static let profile_load_fail = UDEmptyType.loadingFailure.defaultImage()
    static let profile_load_empty = UDEmptyType.noContent.defaultImage()
    static let contact_permission_banner = LarkIllustrationResource.Resources.imSpecializedAllowAccessToAddressBook

    static let dark_right_arrow = Resources.image(named: "dark_right_arrow")
    static let icon_global_back_black = Resources.image(named: "icon_global_back_black")
    static let contacts_import_banner = Resources.image(named: "contacts_import_banner")

    static let warning = Resources.image(named: "warning")
    static let oncall_right_arrow = UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN2)
    static let defaultAvatarImage = Resources.image(named: "inactived_avatar")
    static let defaultTenantImage = Resources.image(named: "icon_tenant_default")

    static let collaboration_tenant = UDIcon.getIconByKey(.trustpartyOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulPurple)
    static let collaboration_invite = UDIcon.getIconByKey(.addTrustpartyOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulPurple)

    //edu
    static let parent_invite = UDIcon.getIconByKey(.teamAddOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulBlue) // note: 样式有点不一样
    static let icon_homeschool_outlined = UDIcon.getIconByKey(.organizationBookOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulTurquoise)
    static let edu_empty = Resources.image(named: "edu_empty")

    // 关联组织
    static let icon_associated_organization = UDIcon.getIconByKey(.trustpartyOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulPurple)

    static let hideMoreSize16 = UDIcon.getIconByKey(.upOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3)
    static let loadMore = UDIcon.getIconByKey(.downOutlined, size: CGSize(width: 12, height: 12)).ud.withTintColor(UIColor.ud.iconN2)
    static let showDetailSize16 = UDIcon.getIconByKey(.downOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3)

    // todo
    static let todoSelectAllImage = Resources.image(named: "todo_select_all")
}
