//
//  Resources.swift
//  MailSDK
//
//  Created by 谭志远 on 2019/5/18.
//

import Foundation
import UIKit
import LarkUIKit
import LarkAppResources
import UniverseDesignEmpty
import UniverseDesignIcon
import LarkStorage

final class Resources {
    static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.MailSDKBundle, compatibleWith: nil) ?? UIImage()
    }

    private static func localizationsImage(named: String) -> UIImage {
            return BundleI18n.image(named: named, in: BundleConfig.MailSDKBundle) ?? UIImage()
    }
    
    static let mail_set_read = Resources.image(named: "mail_set_read")
    static let mail_set_unread = Resources.image(named: "mail_set_unread")
    static let mail_attachment = Resources.image(named: "mail_attachment")
    static let feed_empty_file_icon = UDEmptyType.noFile.defaultImage()
    static let feed_empty_data_icon = UDEmptyType.noMail.defaultImage()
    static let feed_error_icon = UDEmptyType.loadingFailure.defaultImage()
    static let mail_load_fail_icon = UDEmptyType.noPreview.defaultImage()
    static let mail_no_access = UDEmptyType.noAccess.defaultImage()
    
    static let mail_feed_im = UDEmptyType.emailDefault.defaultImage()
    
    static let mail_action_more = UDIcon.moreOutlined
    static let mail_action_flag = UDIcon.flagOutlined
    static let mail_action_unflag = Resources.image(named: "mail_action_unflag")
    static let mail_scene_icon = Resources.image(named: "scene_icon")
    static let mail_scene_close = UDIcon.closeOutlined
    static let mail_signature_close = Resources.image(named: "mail_signature_close")

    // MARK: Attachment
    static let attachment_delete = Resources.image(named: "attachment_delete")
    static let avatar_person = Resources.image(named: "avatar_person")

    // MARK: Toast
    static let toast_icon_success = Resources.image(named: "icon_success_white")
    static let toast_icon_fail = Resources.image(named: "icon_fail_white")
    static let toast_icon_loading = Resources.image(named: "icon_toast_loading")
    static let toast_icon_warning = Resources.image(named: "icon_warning_white")

    static let mail_filter_label_icon = UniverseDesignIcon.UDIcon.getIconByKey(.labelCustomOutlined)


    static let feed_archived_icon = Resources.image(named: "feed_archived_icon")
    static let badge_inbox_mute_more_icon = Resources.image(named: "badge_inbox_mute_more_icon")
    static let badge_inbox_more_icon = Resources.image(named: "badge_inbox_more_icon")
    static let badge_red_mute_icon = Resources.image(named: "badge_red_mute_icon")
    static let badge_done_more_icon = Resources.image(named: "badge_done_more_icon")
    static let badge_urgent_icon = Resources.image(named: "badge_urgent_icon")
    static let badge_mute_icon = Resources.image(named: "badge_mute_icon")
    static let badge_at_icon = Resources.image(named: "badge_at_icon")

    static let tabbar_mail_light = Resources.image(named: "tabbar_mail_light")
    static let tabbar_mail_shadow = Resources.image(named: "tabbar_mail_shadow")

    // MARK: Resources
    static let mail_action_reply = Resources.image(named: "mail_action_reply")
    static let mail_action_forward = Resources.image(named: "mail_action_forward")
    static let mail_action_reedit = Resources.image(named: "mail_action_reedit")
    static let mail_action_recall = Resources.image(named: "mail_action_recall")
    static let mail_action_replyall = Resources.image(named: "mail_action_replyall")
    static let mail_action_translate = Resources.image(named: "mail_action_translate")
    static let mail_action_unsubscribe = Resources.image(named: "mail_action_unsubscribe")
    static let mail_action_mail_icon = Resources.image(named: "mail_action_mail_icon")
    static let mail_action_thread_packup = Resources.image(named: "mail_action_thread_packup")
    static let mail_action_thread_unfold = Resources.image(named: "mail_action_thread_unfold")
    static let mail_action_move_to = Resources.image(named: "mail_action_move_to")
    static let mail_action_sent_cancel = Resources.image(named: "mail_action_sent_cancel")
    static let mail_action_revert_zoom = Resources.image(named: "mail_action_revert_zoom")
    static let mail_send_action_share = Resources.image(named: "mail_send_action_share")
    static let mail_send_action_discuss = Resources.image(named: "mail_send_action_discuss")
    static let mail_send_calendar = Resources.image(named: "mail_send_calendar")
    static let mail_action_content_search = Resources.image(named: "mail_action_content_search")
    static let mail_input_icon_unfold = Resources.image(named: "mail_input_icon_unfold")
    static let mail_contact_group_icon = Resources.image(named: "mail_contact_group_icon")
    static let navigation_drawer_menu = Resources.image(named: "navigation_drawer_menu")
    static let navigation_cancel = Resources.image(named: "navigation_cancel")

    static let mail_cell_option_selected = Resources.image(named: "mail_cell_option_selected")
    static let mail_cell_option = Resources.image(named: "mail_cell_option")
    static let mail_cell_option_disable = Resources.image(named: "mail_cell_option_disable")

    static let mail_cell_share_icon = Resources.image(named: "mail_cell_share_icon")
    static let mail_cell_icon_flag = Resources.image(named: "mail_cell_icon_flag")
    static let mail_cell_icon_flag_selected = Resources.image(named: "mail_cell_icon_flag_selected")
    
    static let mail_read_empty = UDEmptyType.noPreview.defaultImage()
    // MARK: Search
    static let mail_search_empty = UDEmptyType.noSearchResult.defaultImage()

    // MARK: Manage Label
    static let mail_icon_add_label = Resources.image(named: "mail_icon_add_label")
    static let mail_setting_icon_checkMark = Resources.image(named: "mail_setting_icon_checkMark")
    static let mail_setting_icon_left_arrow = Resources.image(named: "mail_setting_icon_left_arrow")
    static let mail_setting_icon_down_arrow = Resources.image(named: "mail_setting_icon_down_arrow")
    static let mail_setting_empty = UDEmptyType.noContent.defaultImage()
    static let mail_setting_net_err = UDEmptyType.loadingFailure.defaultImage()
    static let mail_sig_lock = Resources.image(named: "mail_sig_lock")
    static let mail_empty_icon = UDEmptyType.noContent.defaultImage()
    static let mail_tag_confirm = Resources.image(named: "mail_tag_confirm")
    
    // MARK: Mail Client
    static let mail_client_delete = UDEmptyType.noPreview.defaultImage()
    static let mail_client_tab_delete = Resources.image(named: "mailClient_tabDeleted")
    static let mail_client_thread_google_label_G = Resources.image(named: "mailClient_thread_google_label_G")
    static let mail_client_thread_google_label_bg = Resources.image(named: "mailClient_thread_google_label_bg_left")
    static let mail_client_account_gmail_icon = Resources.image(named: "mailClient_account_gmail_icon")

    static let exchange_icon = Resources.image(named: "exchange_icon")
    static let exchange_icon_round = Resources.image(named: "exchange_icon_round")

    // MARK: Alias
    static let mail_setting_icon_arrow = Resources.image(named: "mail_setting_icon_arrow")
    static let mail_setting_icon_arrow_small = Resources.image(named: "mail_setting_icon_arrow_small")

    static let mail_setting_icon_edit = Resources.image(named: "mail_setting_icon_edit")
    static let mail_setting_icon_warn = Resources.image(named: "mail_setting_icon_warn")

    static let mail_migration_icon_error = Resources.image(named: "mail_migration_icon_error")

    // MARK: Smart Inbox
    static let smartInbox_card_close = Resources.image(named: "smartInbox_card_close")

    // MARK: Mail Recall
    static let mail_recall_fail = Resources.image(named: "mail_recall_fail")
    static let mail_recalling = Resources.image(named: "mail_recalling")

    // MARK: Mail Send
    static let mail_icon_time_zone = Resources.image(named: "icon_time_zone")
    static let checked_accessory = Resources.image(named: "checked_accessory")
    static let local_mark = Resources.image(named: "local_mark")
    static let timezone_search = Resources.image(named: "timezone_search")

    // MARK: Mail Send Attri
    static let boldOutlined = UDIcon.boldOutlined
    static let italicOutlined = UDIcon.italicOutlined
    static let underlineOutlined = UDIcon.underlineOutlined
    static let strikethroughOutlined = UDIcon.strikethroughOutlined
    static let disordeListOutlined = UDIcon.disordeListOutlined
    static let ordeListOutlined = UDIcon.ordeListOutlined
    static let inlineViewOutlined = UDIcon.inlineViewOutlined
    static let codeblockOutlined = UDIcon.codeblockOutlined
    static let codeOutlined = UDIcon.codeOutlined
    static let leftAlignmentOutlined = UDIcon.leftAlignmentOutlined
    static let centerAlignmentOutlined = UDIcon.centerAlignmentOutlined
    static let rightAlignmentOutlined = UDIcon.rightAlignmentOutlined
    static let separateOutlined = UDIcon.separateOutlined
    static let horizontalLineOutlined = UDIcon.horizontalLineOutlined
    static let backTabOutlined = UDIcon.backTabOutlined
    static let attachmentOutlined = UDIcon.attachmentOutlined
    static let styleOutlined = UDIcon.styleOutlined
    static let imageOutlined = UDIcon.imageOutlined
    static let inlineAI = UDIcon.myaiColorful
    
    // MARK: Mail Notification Bot Guide
    static let guide_notify_bot_content = Resources.localizationsImage(named: "guide_notify_bot_content")
    
    static let stranger_onboard = Resources.image(named: "stranger_onboard")

    // MARK: Mail New Unread Count Guide
    static let guide_folder_icon = UDIcon.folderOutlined
    static let guide_mute_icon = UDIcon.alertsOffOutlined

    static let appIcon = AppResources.ios_icon
}

extension Resources {
    static func readInBundle(name: String, extensionName: String?) -> String? {
        if let filePath = BundleConfig.MailSDKBundle.path(forResource: name, ofType: extensionName) {
            do {
                let content = try String.read(from: AbsPath(filePath), encoding: String.Encoding.utf8)
                return content
            } catch {}
        }

        return nil
    }
}
