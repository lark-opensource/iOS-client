//
//  Resources.swift
//  LarkChatSetting
//
//  Created by kongkaikai on 2019/12/13.
//

import UIKit
import Foundation
import LarkAppResources
import UniverseDesignEmpty
import UniverseDesignIcon

final class Resources {
    static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkChatSettingBundle, compatibleWith: nil) ?? UIImage()
    }

    // 设置
    static let group_no_description = UDEmptyType.noAnnouncement.defaultImage()
    static let right_arrow = UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 13, height: 13)).ud.withTintColor(UIColor.ud.iconN3)
    static let chatSetting_create_group = UDIcon.getIconByKey(.moreAddOutlined, size: CGSize(width: 18, height: 18)).ud.withTintColor(UIColor.ud.colorfulBlue)
    static let group_er_code = UDIcon.getIconByKey(.qrOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN3)
    static let selected = Resources.image(named: "selected")

    static let banning_edit = Resources.image(named: "banning_edit")
    static let member_select_cancel = UDIcon.getIconByKey(.moreCloseOutlined, size: CGSize(width: 18, height: 18)).ud.withTintColor(UIColor.ud.iconN3)
    static let approve_accept = Resources.image(named: "approve_accept")
    static let approve_reject = Resources.image(named: "approve_reject")
    static let succeedColorful = UDIcon.getIconByKey(.succeedColorful)

    static let chat_setting_doc_word = UDIcon.getIconByKey(.fileLinkWordOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.colorfulBlue)
    static let chat_setting_doc_sheet = UDIcon.getIconByKey(.fileLinkSheetOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.colorfulBlue)
    static let join_and_leave_doc_icon = Resources.image(named: "join_and_leave_doc_icon")
    static let join_and_leave_group_icon = Resources.image(named: "join_and_leave_group_icon")

    static let chat_chatters_empty = UDEmptyType.noContent.defaultImage()
    static let helpButton = UDIcon.getIconByKey(.maybeOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3)

    static let multiple_share_chat_icon = UDIcon.shareOutlined.ud.withTintColor(UIColor.ud.iconN1)
    static let load_fail = UDEmptyType.loadingFailure.defaultImage()
    static let icon_camera = Resources.image(named: "icon_camera")
    static let group_check_icon = Resources.image(named: "group_check_icon")
    static let listCheck = UDIcon.listCheckColorful
    static let icon_more_outlined = UDIcon.moreOutlined.ud.withTintColor(UIColor.ud.iconN1)
    static let icon_tag_crypto = Resources.image(named: "icon_tag_crypto")
    static let icon_clear = UDIcon.getIconByKey(.closeFilled, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconDisabled)

    // 颜色对应的默认群头像
    static let defalut_color_icon = Resources.image(named: "defalut_color_icon")
    // 这张图的原始大小 60 * 60
    static let newStyle_color_icon = UDIcon.getIconByKeyNoLimitSize(.groupFilled).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)

    //新会话扩展功能
    static let announce_chatExFunc = UDIcon.boardsColorful
    static let event_chatExFunc = UDIcon.calendarColorful
    static let freeBusy_chatExFunc = UDIcon.calendarChatColorful
    static let meetingSummary_chatExFunc = UDIcon.noteFilled.ud.withTintColor(UIColor.ud.colorfulGreen)
    static let pin_chatExFunc = Resources.image(named: "pin_chatExFunc")
    static let todo_chatExtFunc = UDIcon.tabTodoFilled.ud.withTintColor(UIColor.ud.colorfulIndigo)

    static let icon_personInfo_add = Resources.image(named: "icon_personInfo_add")
    // 搜索细节标签
    static let search_detail_docs = UDIcon.getIconByKey(.spaceOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN3)
    static let search_detail_image = UDIcon.getIconByKey(.imageOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN3)
    static let search_detail_message = UDIcon.getIconByKey(.chatOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN3)
    static let search_detail_link = UDIcon.getIconByKey(.linkCopyOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN3)
    static let search_detail_file = UDIcon.getIconByKey(.folderOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN3)

    // pano
    static let pano_edit = UDIcon.getIconByKey(.editOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN2)

    // 撤回
    static let department_picker_default_icon = Resources.image(named: "department_picker_default_icon")
    /// 返回按钮
    static let leftArrow = UDIcon.getIconByKey(.leftOutlined).ud.withTintColor(UIColor.ud.iconN1)

    static let fakeUser1 = Resources.image(named: "fakeuser1")
    static let fakeUser2 = Resources.image(named: "fakeuser2")
    static let fakeUser3 = Resources.image(named: "fakeuser3")
    static let fakeUser4 = Resources.image(named: "fakeuser4")
    static let fakeUser5 = Resources.image(named: "fakeuser5")

    //swiftlint:disable all
    // 底色#FFFFFF
    static let defaultAvatarBGColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    //swiftlint:enable all
    /// 头像加载的兜底图
    static let defaultAvatar = UDIcon.getIconByKey(.memberFilled).ud.withTintColor(Resources.defaultAvatarBGColor)
    static let uploadImageSetting = UDIcon.albumOutlined.ud.withTintColor(UIColor.ud.textLinkNormal)
    static let textSetting = UDIcon.editOutlined.ud.withTintColor(UIColor.ud.textLinkNormal)
    static let jointSetting = UDIcon.avatarcomboOutlined.ud.withTintColor(UIColor.ud.textLinkNormal)
    /// v-next
    static let cameraIcon = UDIcon.getIconByKey(.cameraFilled, size: CGSize(width: 17, height: 17)).ud.withTintColor(UIColor.ud.N600)
    static let groupDefaultIcon = UDIcon.getIconByKey(.groupFilled,
                                                      size: CGSize(width: 60, height: 60)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)

}
