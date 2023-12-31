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
import UniverseDesignEmpty
import UniverseDesignIcon

public final class Resources {
    public static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkChatBundle, compatibleWith: nil) ?? UIImage()
    }
    // phone query limit
    static let apply_arrow_right_icon = UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.colorfulBlue)
    static let call_phone_icon = UDIcon.getIconByKey(.callNetOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1) // note: 方向相反，但应该没问题
    static let navigation_close_light = UDIcon.closeOutlined.ud.withTintColor(UIColor.ud.iconN1)
    static let detail_arrow_right_icon = UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3)
    static let limit_alert_icon = Resources.image(named: "limit_alert_icon")
    static let limit_call_near_icon = Resources.image(named: "limit_call_near_icon")

    // chatTab
    static var goDoc: UIImage { return UDIcon.getIconByKey(.viewinchatOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1) }
    static let tabCellMore = UDIcon.getIconByKey(.moreOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1)

    // readstatus
    static let iconAt = Resources.image(named: "icon_at")
    static let readStatusEmpty = UDEmptyType.noPreview.defaultImage()
    // at
    static let contact_at_all = Resources.image(named: "contact_at_all")

    // doc
    static let tabbar_shadow = Resources.image(named: "tabbar_shadow")

    static let right_arrow = UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 13, height: 13)).ud.withTintColor(UIColor.ud.iconN3)

    static let back_dark = UDIcon.leftOutlined.ud.withTintColor(UIColor.ud.iconN1)
    static let not_in_organization_icon = Resources.image(named: "not_in_organization_icon")
    static let group_card_backgroud_image = Resources.image(named: "group_card_backgroud_image")

    // Input
    static let reply_close = UDIcon.getIconByKey(.closeOutlined, size: CGSize(width: 15, height: 15)).ud.withTintColor(UIColor.ud.iconN3)

    static let cloud_file = UDIcon.getIconByKey(.attachmentFilled).ud.withTintColor(UIColor.ud.colorfulOrange)
    // TODO: remove
    static let send_docs = UDIcon.getIconByKey(.spaceFilled).ud.withTintColor(UIColor.ud.primaryContentDefault)
    static let vote = UDIcon.getIconByKey(.voteFilled).ud.withTintColor(UIColor.ud.colorfulIndigo)

    static let sideMenuDocs = UDIcon.getIconByKey(.describeOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1) // note: 没有被用上
    static let sideMenuEvent = UDIcon.getIconByKey(.calendarOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1)

    /// pin
    static let pin_empty_view = UDEmptyType.pin.defaultImage()
    static let guide_select_language_icon = UDIcon.getIconByKey(.expandRightFilled, size: CGSize(width: 10, height: 10)).ud.withTintColor(UIColor.ud.iconN1)
    static let select_target_language_icon = UDIcon.getIconByKey(.doneOutlined, size: CGSize(width: 18, height: 18)).ud.withTintColor(UIColor.ud.colorfulBlue)
    static let pinCalenderTip = Resources.image(named: "pinCalenderTip")
    static let pinCalenderConfirmTip = Resources.image(named: "pinCalenderConfirmTip")
    static let pinVoteTip = Resources.image(named: "pinVoteTip")
    static let pinUrlPreviewIcon = Resources.image(named: "pin_url_preview_icon")
    static let pinFunction = Resources.image(named: "pinFunction")
    static let pinNotifyClock = UDIcon.bellOutlined.ud.withTintColor(UIColor.ud.iconN1)
    static let pinNotifyClockClose = UDIcon.alertsOffOutlined.ud.withTintColor(UIColor.ud.iconN1)

    /// hongbao
    static let send_hongbao = UDIcon.getIconByKey(.luckmoneyFilled).ud.withTintColor(UIColor.ud.colorfulRed)

    static let secret_1d = UDIcon.burnlifeDayOutlined.ud.withTintColor(UIColor.ud.iconN3)
    static let secret_1d_select = UDIcon.burnlifeDayOutlined.ud.withTintColor(UIColor.ud.colorfulBlue)
    static let secret_1h = UDIcon.burnlifeHourOutlined.ud.withTintColor(UIColor.ud.iconN3)
    static let secret_1h_select = UDIcon.burnlifeHourOutlined.ud.withTintColor(UIColor.ud.colorfulBlue)
    static let secret_1m = UDIcon.burnlifeMinuteOutlined.ud.withTintColor(UIColor.ud.iconN3)
    static let secret_1m_select = UDIcon.burnlifeMinuteOutlined.ud.withTintColor(UIColor.ud.colorfulBlue)
    static let secret_1w = UDIcon.burnlifeWeekOutlined.ud.withTintColor(UIColor.ud.iconN3)
    static let secret_1w_select = UDIcon.burnlifeWeekOutlined.ud.withTintColor(UIColor.ud.colorfulBlue)
    static let secret_small_lock = Resources.image(named: "ic_private_2")
    static let secret_single_head = Resources.image(named: "secretSingleHead")

    // location
    static let location_keyboard = UDIcon.getIconByKey(.localFilled).ud.withTintColor(UIColor.ud.primaryContentDefault)
    static let location_close = UDIcon.closeOutlined.ud.withTintColor(UIColor.ud.iconN1)

    // favorite
    static let forwardFavorite = UDIcon.forwardOutlined.ud.withTintColor(UIColor.ud.iconN1)
    static let deleteFavorite = UDIcon.deleteTrashOutlined.ud.withTintColor(UIColor.ud.iconN1)
    static let favoriteUnknown = Resources.image(named: "favoriteUnknown")

    static let favorite_detail_play = UDIcon.getIconByKey(.playFilled, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2)
    static let favorite_list_pause = UDIcon.getIconByKey(.pauseLivestreamOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN3)
    static let favorite_list_play = UDIcon.getIconByKey(.playFilled, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN3)

    static let favorite_empty = UDEmptyType.noFavourite.defaultImage()
    static let favorite_video_play = Resources.image(named: "favorite_video_play")

    // messageDetail
    static let forward_all_normal_icon = UDIcon.forwardOutlined.ud.withTintColor(UIColor.ud.iconN1)

    static let call_up_icon = UDIcon.phoneOutlined.ud.withTintColor(UIColor.ud.iconN1)
    static let voice_call_icon = UDIcon.callOutlined.ud.withTintColor(UIColor.ud.iconN1)
    static let video_call_icon = UDIcon.videoOutlined.ud.withTintColor(UIColor.ud.iconN1)
    static let encrypted_call_icon = UDIcon.callSecretOutlined.ud.withTintColor(UIColor.ud.iconN1)
    static let call_sos = UDIcon.alarmOutlined.ud.withTintColor(UIColor.ud.colorfulRed)

    ///ephemeral card
    static let ephemeral_card_mark = UDIcon.getIconByKey(.visibleFilled, size: CGSize(width: 18, height: 18)).ud.withTintColor(UIColor.ud.iconN1)

    // Timezone
    static let timezone = UDIcon.getIconByKey(.timeOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3)

    // Profile Card
    static let profile_card = UDIcon.getIconByKey(.businessCardFilled).ud.withTintColor(UIColor.ud.primaryContentDefault)

    // Schedule send
    static let scheduleSend = Resources.image(named: "schedule_send").ud.withTintColor(UIColor.ud.illustrationBlueE)

    //翻译助手
    static let transAssistantFilled = Resources.image(named: "transAssistantFilled")

    /// translate
    static let translate_arrow = Resources.image(named: "translate_arrow")

    // todo_task
    static let todo_pin = Resources.image(named: "todo_pin")

    // lan trans
    static let lan_Trans_Icon = Resources.image(named: "lan_Trans_Icon")
    // folder
    static let icon_folder_message = Resources.image(named: "icon_folder_message")

    // suspend (multitasking)
    static let suspend_icon_chat = UDIcon.chatOutlined.ud.withTintColor(UIColor.ud.iconN1)
    static let suspend_icon_bot = UDIcon.robotOutlined.ud.withTintColor(UIColor.ud.iconN1)
    static let suspend_icon_secret = UDIcon.chatSecretOutlined.ud.withTintColor(UIColor.ud.iconN1)
    static let suspend_icon_group = UDIcon.getIconByKey(.groupOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1)

    // Scene Switcher
    static let chatIcon = UDIcon.chatFilled.ud.withTintColor(UIColor.ud.iconN1)

    //页签管理
    static let tab_close_small_outlined = UDIcon.getIconByKey(.closeSmallOutlined, size: CGSize(width: 24, height: 24)).ud.withTintColor(UIColor.ud.iconN1)
    static let tab_icon_more_outlined = UDIcon.getIconByKey(.moreOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN3)
    static let tab_icon_menu_outlined = UDIcon.getIconByKey(.menuOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN3)

    // 群空间
    static let menu_outlined = UDIcon.getIconByKey(.menuOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3)
    // + 号菜单项 - Meego 创建工作项
    static let phone_titlebar = UDIcon.callVideoOutlined.ud.withTintColor(UIColor.ud.iconN1)
    static let video_titlebar = UDIcon.videoOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let meeting_end_large = UDIcon.videoOutlined.ud.withTintColor(UIColor.ud.iconN1)
    static let meeting_ing = UDIcon.videoFilled.ud.withTintColor(UIColor.ud.iconN1)
    static let no_preview_permission = UDIcon.getIconByKey(.banOutlined, size: CGSize(width: 24, height: 24)).ud.withTintColor(UIColor.ud.iconDisabled)
    static let add_member_icon = UDIcon.getIconByKey(.memberAddOutlined, size: CGSize(width: 24, height: 24)).ud.withTintColor(UIColor.ud.iconN1)
    static let navibar_more = UDIcon.getIconByKey(.moreOutlined, size: CGSize(width: 24, height: 24)).ud.withTintColor(UIColor.ud.iconN1)

    // 代码块详情
    static let codeDetailExitIcon = Resources.image(named: "code_detail_exit_icon")
    static let codeDetailOffWrapIcon = Resources.image(named: "turn_off_line_wrap_icon")
    static let codeDetailOnWrapIcon = Resources.image(named: "turn_on_line_wrap_icon")
    // MyAI
    static let imageDownloadFailed = UDIcon.getIconByKey(.loadfailFilled).ud.withTintColor(UIColor.ud.iconN3)
}
