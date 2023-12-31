//
//  Resources.swift
//  Module
//
//  Created by chengzhipeng-bytedance on 2018/3/15.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import LarkAppResources
import LarkLocalizations
#if USE_DYNAMIC_RESOURCE
import LarkResource
#endif
import UniverseDesignIcon

final class Resources {
    private static func image(named: String) -> UIImage {
        #if USE_DYNAMIC_RESOURCE
        if let image: UIImage = ResourceManager.get(key: "LarkMine.\(named)", type: "image") {
            return image
        }
        #endif
        return UIImage(named: named, in: BundleConfig.LarkMineBundle, compatibleWith: nil) ?? UIImage()
    }

    static let right_message_disable_icon = Resources.image(named: "right_message_disable_icon")
    static let right_message_select_icon = Resources.image(named: "right_message_select_icon")
    static let right_message_normal_icon = Resources.image(named: "right_message_normal_icon")

    static let left_method_normal_icon = Resources.image(named: "left_method_normal_icon")
    static let left_method_select_icon = Resources.image(named: "left_method_select_icon")
    static let message_disable_icon = UDIcon.getIconByKey(.editOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3)
    static let message_edit_icon = UDIcon.getIconByKey(.editOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.colorfulBlue)
    static let notice_alert = Resources.image(named: "notice_alert")
    static let delete_language_icon = UDIcon.getIconByKey(.closeOutlined, size: CGSize(width: 12, height: 12)).ud.withTintColor(UIColor.ud.iconN2)
    static let translate_icon = UDIcon.translateOutlined.ud.withTintColor(UIColor.ud.colorfulBlue) // note: 没有被用上
    static let account = UDIcon.getIconByKey(.cellphoneOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulWathet)
    static let customer_service = UDIcon.getIconByKey(.helpdeskOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulRed)
    static let delete_description = UDIcon.getIconByKey(.closeOutlined, size: CGSize(width: 10, height: 10)).ud.withTintColor(UIColor.ud.iconN3)
    static let favorite_icon = UDIcon.getIconByKey(.collectionOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulYellow)
    static let admin_icon = UDIcon.getIconByKey(.adminOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulBlue)
    static let do_not_disrurb_open = UDIcon.getIconByKey(.alertsOffFilled, size: CGSize(width: 19, height: 19)).ud.withTintColor(UIColor.ud.colorfulRed)
    static let icon_member_outlinedprofile = UDIcon.getIconByKey(.memberOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulBlue)
    static let do_not_disrurb_close = UDIcon.getIconByKey(.bellFilled, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconDisabled)
    static let do_not_disturb_loading = Resources.image(named: "do_not_disturb_loading")
    static let doc_highlight_icon = Resources.image(named: "doc_highlight_icon")
    static let clear_text_icon = UDIcon.getIconByKey(.closeOutlined, size: CGSize(width: 12, height: 12)).ud.withTintColor(UIColor.ud.iconN3)
    static let language_select = UDIcon.getIconByKey(.doneOutlined, size: CGSize(width: 18, height: 18)).ud.withTintColor(UIColor.ud.colorfulBlue)
    static let mine_right_arrow = UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3)
    static let name_edit_icon = UDIcon.getIconByKey(.editOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN2)
    static let setting = UDIcon.getIconByKey(.settingOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulBlue)
    static var ios_icon: UIImage { AppResources.ios_icon }
    static let auth_tag = UDIcon.getIconByKey(.verifyFilled, size: CGSize(width: 12, height: 12)).ud.withTintColor(UIColor.ud.udtokenTagTextSTurquoise)
    static var work_day: UIImage? { BundleI18n.image(named: "workDay", in: BundleConfig.LarkMineBundle) }
    static let wallet = UDIcon.getIconByKey(.walletOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulRed)
    static let device = UDIcon.getIconByKey(.phoneOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3)
    static let join_team = UDIcon.getIconByKey(.teamAddOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulBlue)
    static let my_qrcode = UDIcon.getIconByKey(.qrOutlined, size: CGSize(width: 20, height: 20))
    static let profile_arrow = Resources.image(named: "profile_arrow")
    static let mine_qrcode = Resources.image(named: "mine_qrcode")
    static let select_icon = Resources.image(named: "select_icon")
    static let powered_by = AppResources.share_icon_logo
    static let security_white_paper_icon = UDIcon.getIconByKey(.safePassOutlined, size: CGSize(width: 14, height: 14)).ud.withTintColor(UIColor.ud.colorfulGreen)
    static let mine_theme_followsystem = Resources.image(named: "mine_theme_followsystem")
    static let mine_theme_light = Resources.image(named: "mine_theme_light")
    static let mine_theme_dark = Resources.image(named: "mine_theme_dark")
    static let chat_avatar_layout_left = Resources.image(named: "ChatAvatarLeftLightMode")
    static let chat_avatar_layout_leftRight = Resources.image(named: "ChatAvatarLeftRightLightMode")
    static let netDiagnose_back = Resources.image(named: "netDiagnose_back")
}
