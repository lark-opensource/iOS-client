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
import UniverseDesignIcon
import UniverseDesignColor

public final class BundleResources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkMessageCoreBundle, compatibleWith: nil) ?? UIImage()
    }
    public final class Menu {
        static let menu_close_preview = UDIcon.getIconByKey(.visibleLockOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_debug = UDIcon.getIconByKey(.helpdeskOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_quick_action_info = UDIcon.getIconByKey(.infoColorful, size: CGSize(width: 22, height: 22))
        static let menu_regenerate = UDIcon.getIconByKey(.resetOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.textCaption)
        static let menu_copy = UDIcon.getIconByKey(.copyOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_message_link_copy = UDIcon.getIconByKey(.blocklinkOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_delete = UDIcon.getIconByKey(.deleteTrashOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_earphone = UDIcon.getIconByKey(.earOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_favorite = UDIcon.getIconByKey(.collectionOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        public static let menu_flag = UDIcon.getIconByKey(.flagOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        public static let menu_unFlag = UDIcon.getIconByKey(.flagUnavailableOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_forward = UDIcon.getIconByKey(.forwardOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_forward_thread = UDIcon.getIconByKey(.forwardComOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_hide_audio_text = UDIcon.getIconByKey(.untextOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_multi = UDIcon.getIconByKey(.groupSelectionOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_mute_play = UDIcon.getIconByKey(.speakerMuteOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_pano = UDIcon.getIconByKey(.tagOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_pin = UDIcon.getIconByKey(.pinOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_Chatpin = UDIcon.getIconByKey(.chatPinOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_recall = UDIcon.getIconByKey(.recallOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_multiEdit = UDIcon.getIconByKey(.editOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_reply = UDIcon.getIconByKey(.replyOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_reply_feishu = UDIcon.getIconByKey(.replyCnOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_open_thread = UDIcon.getIconByKey(.threadChatOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_create_thread = UDIcon.getIconByKey(.threadChatOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_show_audio_text = UDIcon.getIconByKey(.textAaOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_speaker = UDIcon.getIconByKey(.speakerOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_sticker = UDIcon.getIconByKey(.emojiAddOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_takeActionV2 = UDIcon.getIconByKey(.keyboardOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_to_original = UDIcon.getIconByKey(.viewinchatOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_save_to = UDIcon.getIconByKey(.addOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_translate = UDIcon.getIconByKey(.translateOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let hide_translate = UDIcon.getIconByKey(.visibleLockOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_switchLanguage = UDIcon.getIconByKey(.transSwitchOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_unPin = UDIcon.getIconByKey(.unpinOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_urgent = UDIcon.getIconByKey(.buzzOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_todo = UDIcon.getIconByKey(.tabTodoOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_query_abbreviation = UDIcon.getIconByKey(.cardSearchOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_search = UDIcon.getIconByKey(.searchOutlineOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_image_edit = UDIcon.getIconByKey(.editOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_meego = UDIcon.getIconByKey(.meegoOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_top = UDIcon.getIconByKey(.setTopOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_cancelTop = UDIcon.getIconByKey(.setTopCancelOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_set_secret_message = UDIcon.getIconByKey(.noOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_cancel_secret_message = UDIcon.getIconByKey(.yesOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
        static let menu_quote = image(named: "menu_quote").ud.withTintColor(UIColor.ud.iconN1)
    }
    public static let status_send_fail_light = image(named: "status_send_fail_light")

    static let icon_chat_warning = image(named: "icon_chat_warning")
    // status
    public static let status_send_loading = image(named: "status_send_loading")
    public static let send_loading = image(named: "send_loading")

    // url preview
    public static let url_preview_icon = image(named: "url_preview_icon")
    public static let videoPreviewIcon = image(named: "video_preview_icon")

    // multi checkbox
    public static let pickerOn = image(named: "checkbox_on")
    public static let pickerOff = image(named: "checkbox_off")
    public static let pickerOff_Ban = image(named: "checkbox_off_ban")

    static let alert_background_icon = image(named: "alert_background_icon")
    static let confirm_alert_icon = image(named: "confirm_alert_icon")
    static let confirm_alert_select_icon = image(named: "confirm_alert_select_icon")

    // multi select
    static let meego = image(named: "meego")
    static let meegoHignlighted = image(named: "meego_highlighted")
    static let takeAction = image(named: "takeAction")
    static let takeActionHighlighted = image(named: "takeAction_highlighted")

    // bubble
    static let urgentIconLight = image(named: "urgent_icon_light")

    // image
    static let imageLoading = image(named: "image_loading")

    // video
    static let video_upload = image(named: "video_upload")
    static let continue_upload = image(named: "continue_upload")
    static let video_play = image(named: "video_play")
    static let video_file_deleted = image(named: "video_file_deleted")

    // BottomView
    static let thread_pin = image(named: "thread_pin")
    // hongbao
    static let hongbao_open_icon = image(named: "hongbao_open_icon")
    static let hongbao_close_icon = image(named: "hongbao_close_icon")
    static let hongbao_message_background = image(named: "hongbao_message_background")

    static let hongbao_bg_top = image(named: "hongbao_bg_top")
    static let hongbao_bg_top_mask = image(named: "hongbao_bg_top_mask")
    static let hongbao_bg_bottom = image(named: "hongbao_bg_bottom")

    static let hongbao_clicked_light = image(named: "hongbao_clicked_light")
    static let hongbao_selected_light = image(named: "hongbao_selected_light")

    static let new_hongbao_clicked_light = image(named: "hongbao_clicked_light")
    static let new_hongbao_selected_light = image(named: "hongbao_selected_light")

    static let hongbao_system_light = image(named: "hongbao_system_light")
    static var hongbao_rectangleCopy = image(named: "rectangleCopy")

    static let pinVoteTip = image(named: "pinVoteTip")
    // unread
    static let whiteUnReadTipLoading = image(named: "whiteUnReadTipLoading")

    static let emotionPlaceholderIcon = image(named: "emotion_placeholder")
    static let emotionEmptyIcon = image(named: "emotion_empty_icon")
    static let emotionBannerPlaceholderIcon = image(named: "emotion_placeholder_banner")
    static let emotionUnauthorizeIcon = image(named: "emotion_unauthorized_icon")

    // lan trans
    static let lan_Trans_Icon_light = image(named: "lan_Trans_Icon_light")

    public static let identitySelected = UDIcon.listCheckColorful

    static let identitySwitch = UDIcon.downBoldScreenshotOutlined.ud.withTintColor(.ud.iconN1, renderingMode: .alwaysOriginal)

    static let rightSmallCcmOutlined = UDIcon.getIconByKey(.rightSmallCcmOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3)

    // fold message
    public static let foldApproveButton = image(named: "flod_approve")
    public static let flodAppprovePlus = image(named: "flod_appprove_+")
    public static let flodAppprove0 = image(named: "flod_appprove_0")
    public static let flodAppprove1 = image(named: "flod_appprove_1")
    public static let flodAppprove2 = image(named: "flod_appprove_2")
    public static let flodAppprove3 = image(named: "flod_appprove_3")
    public static let flodAppprove4 = image(named: "flod_appprove_4")
    public static let flodAppprove5 = image(named: "flod_appprove_5")
    public static let flodAppprove6 = image(named: "flod_appprove_6")
    public static let flodAppprove7 = image(named: "flod_appprove_7")
    public static let flodAppprove8 = image(named: "flod_appprove_8")
    public static let flodAppprove9 = image(named: "flod_appprove_9")

    // my ai
    public static let myai_loading_icon_01 = image(named: "myai_loading_icon_01")
    public static let myai_loading_icon_02 = image(named: "myai_loading_icon_02")
    public static let myai_loading_icon_03 = image(named: "myai_loading_icon_03")
    public static let myai_loading_icon_04 = image(named: "myai_loading_icon_04")
    public static let myai_loading_icon_05 = image(named: "myai_loading_icon_05")
    public static let myai_loading_icon_06 = image(named: "myai_loading_icon_06")
}
