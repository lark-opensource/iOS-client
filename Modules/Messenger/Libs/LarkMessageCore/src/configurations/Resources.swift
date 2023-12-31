//
//  Resources.swift
//  LarkMessageCore
//
//  Created by panbinghua on 2021/8/19.
//

import Foundation
import UIKit
import UniverseDesignIcon
import UniverseDesignEmpty

public final class Resources {
    public static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkMessageCoreBundle, compatibleWith: nil) ?? UIImage()
    }
    //ephemeral card
    static let ephemeral_card_mark = UDIcon.getIconByKey(.visibleFilled, size: CGSize(width: 18, height: 18)).ud.withTintColor(UIColor.ud.iconN1)
    static let secret_single_head = Resources.image(named: "secretSingleHead")

    // translate
    public static let auto_translated_icon = UDIcon.getIconByKey(.languageOutlined, size: CGSize(width: 14, height: 14)).ud.withTintColor(UIColor.ud.colorfulBlue)

    // status
    // navigation bar
    public static let goChatSettingArrow = UDIcon.getIconByKey(.expandRightFilled, size: CGSize(width: 12, height: 12)).ud.withTintColor(UIColor.ud.iconN1)
    public static let phone_titlebar = UDIcon.callVideoOutlined.ud.withTintColor(UIColor.ud.iconN1)
    public static let video_titlebar = UDIcon.videoOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    public static let meeting_end_large = UDIcon.videoOutlined.ud.withTintColor(UIColor.ud.iconN1)
    public static let meeting_ing = UDIcon.videoFilled.ud.withTintColor(UIColor.ud.iconN1)
    public static let navibar_share = UDIcon.shareOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let navibar_more = UDIcon.getIconByKey(.moreOutlined, size: CGSize(width: 24, height: 24)).ud.withTintColor(UIColor.ud.iconN1)

    // multi checkbox
    static let search_icon = UDIcon.chatSearchSolidOutlined.ud.withTintColor(UIColor.ud.iconN1)
    static let add_member_icon = UDIcon.getIconByKey(.memberAddOutlined, size: CGSize(width: 24, height: 24)).ud.withTintColor(UIColor.ud.iconN1)
    static let close_alert_icon = UDIcon.getIconByKey(.closeOutlined, size: CGSize(width: 14, height: 14)).ud.withTintColor(UIColor.ud.iconN2)
    static let setting_outlined = UDIcon.getIconByKey(.settingOutlined, size: CGSize(width: 24, height: 24)).ud.withTintColor(UIColor.ud.iconN1)
    static let search_outlined = UDIcon.getIconByKey(.historySearchOutlined, size: CGSize(width: 24, height: 24)).ud.withTintColor(UIColor.ud.iconN1)
    static let myai_coloful = UDIcon.getIconByKey(.myaiColorful, size: CGSize(width: 24, height: 24))

    // image
    static let imageDownloadFailedReply = UDIcon.loadfailFilled.ud.withTintColor(UIColor.ud.iconDisabled)
    static let imageDownloadFailed = UDIcon.getIconByKey(.loadfailFilled, size: CGSize(width: 32, height: 32)).ud.withTintColor(UIColor.ud.iconN3)
    // call
    static let callback = UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.B700)

    // BottomView
    static let reply_message = UDIcon.replyFilled.ud.withTintColor(UIColor.ud.colorfulBlue)
    static let reply_message_feishu = UDIcon.replyCnFilled.ud.withTintColor(UIColor.ud.colorfulBlue)
    static let reply_quote = Resources.image(named: "reply_quote").ud.withTintColor(UIColor.ud.colorfulBlue)

    static let message_pin = UDIcon.chatPinFilled.ud.withTintColor(UIColor.ud.colorfulTurquoise)
    static let dlp_tip = UDIcon.getIconByKey(.warningRedColorful, size: CGSize(width: 14, height: 14))
    static let risk_file_tip = UDIcon.warningFilled.ud.withTintColor(UIColor.ud.functionWarningContentDefault)
    static let restrict_tip = UDIcon.getIconByKey(.lockFilled, size: CGSize(width: 12, height: 12)).ud.withTintColor(UIColor.ud.colorfulOrange)
    static let urgentGrayIcon = UDIcon.buzzFilled.ud.withTintColor(UIColor.ud.colorfulRed)
    static let message_audio_forward = UDIcon.forwardFilled.ud.withTintColor(UIColor.ud.iconN3)
    static let icon_belong_outlined = UDIcon.getIconByKey(.belongOutlined, size: CGSize(width: 14, height: 14)).ud.withTintColor(UIColor.ud.iconN2)
    // audio
    static let close_notice = UDIcon.getIconByKey(.closeOutlined, size: CGSize(width: 15, height: 15)).ud.withTintColor(UIColor.ud.iconN3)
    static let earphone_voice = UDIcon.getIconByKey(.earOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.colorfulGreen)
    static let mute_voice = UDIcon.getIconByKey(.speakerMuteOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.colorfulGreen)
    static let speaker_voice = UDIcon.getIconByKey(.speakerOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.colorfulGreen)

    // DocPreview
    static let arrow = UDIcon.expandDownFilled
    static let small_video_icon = UDIcon.getIconByKey(.videoFilled, size: CGSize(width: 12, height: 12)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    // unread
    static let blueUpUnreadTipArrow = UDIcon.getIconByKey(.upTopOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.colorfulBlue)
    static let blueDownUnreadTipArrow = UDIcon.getIconByKey(.downBottomOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.colorfulBlue)

    // SelectMenuController

    //emotion
    static let emotionSettingRightItemIcon = UDIcon.settingOutlined.ud.withTintColor(UIColor.ud.iconN3)
    static let emotionSettingHeartIcon = UDIcon.getIconByKey(.likeLineOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1)
    static let emotionSettingArrow = UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3)

    static let emotionShopShareIcon = UDIcon.getIconByKey(.shareOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1)
    static let emotionDeleteIcon = UDIcon.deleteTrashOutlined.ud.withTintColor(UIColor.ud.colorfulRed)

    public static let emotion_show_list_icon = UDIcon.addOutlined.ud.withTintColor(UIColor.ud.iconN1)

    // post
    static let closePost = UDIcon.minimizeOutlined.ud.withTintColor(UIColor.ud.iconN2)
    // singleContact
    static let ban_contact = UDIcon.getIconByKey(.banOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.primaryContentDefault)
    static let icon_member = UDIcon.getIconByKey(.memberAddOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.primaryContentDefault)
    static let icon_group = UDIcon.getIconByKey(.groupOutlined, size: CGSize(width: 18, height: 18)).ud.withTintColor(UIColor.ud.colorfulBlue)

    // folder
    static let icon_folder_message = UDIcon.getIconByKey(.fileFolderColorful, size: CGSize(width: 48, height: 48))

    static let close_topNotice_icon = UDIcon.getIconByKey(.closeOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN2)

    static let topNotice_chat = UDIcon.getIconByKey(.chatFilled, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.colorfulBlue)

    static let topNotice_announce = UDIcon.getIconByKey(.announceFilled, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.colorfulOrange)

    static let topNotice_calendar = UDIcon.getIconByKey(.calendarFilled, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.colorfulOrange)

    static let topNotice_video = UDIcon.getIconByKey(.videoFilled, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.colorfulBlue)

    static let topNotice_todo = UDIcon.getIconByKey(.todoFilled, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.colorfulBlue)

    static let topNotice_mailFilled = UDIcon.getIconByKey(.mailFilled, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.colorfulBlue)

    static let topNotice_fileFolderColorful = UDIcon.getIconByKey(.fileFolderColorful, size: CGSize(width: 16, height: 16))

    static let topNotice_noteColorful = UDIcon.getIconByKey(.noteColorful, size: CGSize(width: 16, height: 16))

    static let topNotice_vote = UDIcon.getIconByKey(.voteFilled, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.colorfulIndigo)

    static let topNotice_local = UDIcon.getIconByKey(.localFilled, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.colorfulBlue)

    static let topNotice_businessCard = UDIcon.getIconByKey(.businessCardFilled, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.colorfulBlue)

    static let topNotice_group = UDIcon.getIconByKey(.groupFilled, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.colorfulBlue)

    static let topNotice_mic = UDIcon.getIconByKey(.micFilled, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.colorfulBlue)

    static let topNotice_luckmoney = UDIcon.getIconByKey(.luckmoneyFilled, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.colorfulRed)

    static let approve_chat_tip_close = UDIcon.closeOutlined.ud.withTintColor(UIColor.ud.iconN3)

    static let topNotice_arrow = UDIcon.getIconByKey(.setTopOutlined, size: CGSize(width: 12, height: 12)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)

    static let no_preview_permission = UDIcon.getIconByKey(.banOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconDisabled)
    static let detail_arrow = UDIcon.getIconByKey(.insertDownOutlined, size: CGSize(width: 12, height: 12)).ud.withTintColor(UIColor.ud.primaryContentDefault)

    static let rectangle_corver = Resources.image(named: "rectangle_corver")

    /// megreForward
    static let replyInThreadForward = UDIcon.getIconByKey(.threadChatOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.T600)

    static let no_access = UDEmptyType.noAccess.defaultImage()
}
