//
//  NewCoreEvent.swift
//  MailSDK
//
//  Created by tefeng liu on 2021/5/19.
//

import Foundation

// 文档：https://bytedance.feishu.cn/sheets/shtcn0KIPCiwmR8JrzJvCVkQEce?sheet=fMbFWi
class NewCoreEvent {
    static let EVENT_KEY_CLICK = "click"
    static let EVENT_KEY_TARGET = "target"
    static let EVENT_KEY_ACTION_POSITION = "action_position"
    static let EVENT_KEY_ACTION_TYPE = "action_type"
    static let EVENT_KEY_IS_MULTISELECTED = "is_multi_selected"
    static let EVENT_KEY_MAIL_ACCOUNT_TYPE = "mail_account_type"

    enum EventName: String {
        case email_label_list_view
        case email_label_list_click
        case email_label_item_right_menu_view
        case email_label_item_right_menu_click
        case email_thread_list_view
        case email_thread_list_click
        case email_message_list_view
        case email_message_list_click
        case email_email_edit_view
        case email_email_edit_click
        case email_new_mail_click
        case email_search_contact_request_click
        case email_search_contact_result_view
        case email_search_contact_result_click
        case email_select_contact_from_picker_click
        case email_send_status_toast_click
        case email_send_status_toast_view
        case email_lark_setting_click
        case email_lark_setting_mail_signature_view
        case email_lark_setting_mail_signature_click
        case email_send_status_banner_view
        case email_send_status_banner_click
        case email_image_detail_view
        case email_image_detail_click
        case email_image_action_menu_view
        case email_image_action_menu_click
        case email_image_edit_finish_menu_view
        case email_image_edit_finish_menu_click
        case email_tab_click
        case email_doc_link_edit_click
        case email_doc_link_send_alert_view
        case email_doc_link_send_alert_click
        case email_message_list_clck
        case email_at_edit_menu_view
        case email_large_attachment_management_view
        case email_large_attachment_management_click
        case email_large_attachment_alert_view
        case email_large_attachment_alert_click
        case email_email_edit_myai_view
        case email_email_edit_myai_click
        case email_myai_window_view
        case email_myai_window_click
        case email_quit_myai_window_view
        case email_quit_myai_window_click
        case email_editor_right_menu_view
        case email_editor_right_menu_click
        case email_myai_onboard_window_view
        case email_myai_onboard_window_click
        case email_draft_ai_invoke
        case email_draft_ai_content_accept
        case email_draft_ai_task_create
        case email_draft_ai_task_feedback
        case email_myai_chat_view
        case email_navibar_click
        case email_myai_chat_click
        case email_focus_contact_recommend_banner_view
        case email_focus_contact_recommend_banner_click
    }

    enum ActionType: String {
        case mail_recall
        case edit_again
    }

    let event: EventName

    var params: [String: Any] = [:]

    init(event: EventName) {
        self.event = event
    }
}

extension NewCoreEvent {
    func post() {
        MailTracker.log(event: event.rawValue, params: params)
    }
}


// MARK: some convenient action
extension NewCoreEvent {
    static func accountType() -> String {
        var typeString = Store.settingData.getMailAccountType()
        if typeString == "unknown" {
            typeString = "None"
        }
        return typeString
    }
    static func threadListClickThread(filterType: MailThreadFilterType,
                                      labelItem: String,
                                      displayType: String) {
        let event = NewCoreEvent(event: .email_thread_list_click)
        event.params = ["click": "click_thread",
                        "target": "none",
                        "thread_list_type": filterType == .allMail ? "all_mail" : "unread_mail",
                        "label_item": labelItem,
                        "mail_display_type": displayType,
                        "mail_service_type": Store.settingData.getMailAccountListType()]
        event.post()
    }

    static func threadListThreadAction(isMultiSelected: Bool,
                                       position: String,
                                       actionType: String,
                                       filterType: MailThreadFilterType,
                                       labelItem: String,
                                       displayType: String,
                                       isTrashOrSpamList: String = "FALSE") {
        let event = NewCoreEvent(event: .email_thread_list_click)
        event.params = ["click": "thread_action",
                        "target": "none",
                        "select_type": isMultiSelected ? "multi_select" : "single",
                        "is_multi_selected": isMultiSelected ? "true" : "false",
                        "action_position": position,
                        "action_type": actionType,
                        "thread_list_type": filterType == .allMail ? "all_mail" : "unread_mail",
                        "label_item": labelItem,
                        "is_trash_or_spam_list": isTrashOrSpamList,
                        "mail_display_type": displayType,
                        "mail_display_mode": "list_mode",
                        "mail_service_type": Store.settingData.getMailAccountListType()]
        event.post()
    }

    static func messageListDownloadAttachment() -> NewCoreEvent {
        let event = NewCoreEvent(event: .email_message_list_click)
        event.params = [EVENT_KEY_CLICK: "attachment_download",
                        EVENT_KEY_TARGET: "none",
                        "attachment_position": "attachment_preview_top"]
        return event
    }

    static func messageListLocalOpenAttachment(fileType: String) -> NewCoreEvent {
        let event = NewCoreEvent(event: .email_message_list_click)
        event.params = [EVENT_KEY_CLICK: "attachment_local_open",
                        EVENT_KEY_TARGET: "none",
                        "file_type": fileType,
                        "attachment_position": "attachment_preview_top"]
        return event
    }

    static func messageListShareAttachment() -> NewCoreEvent {
        let event = NewCoreEvent(event: .email_message_list_click)
        event.params = [EVENT_KEY_CLICK: "attachment_share",
                        EVENT_KEY_TARGET: "none",
                        "attachment_position": "attachment_preview_top"]
        return event
    }

    static func messageListFlagAction(_ flag: Bool) -> NewCoreEvent {
        let event = NewCoreEvent(event: .email_message_list_click)
        event.params = [EVENT_KEY_CLICK: "thread_action",
                        EVENT_KEY_TARGET: "none",
                        EVENT_KEY_ACTION_POSITION: "thread_bar",
                        EVENT_KEY_ACTION_TYPE: flag ? "flag" : "unflag"]
        return event
    }

    static func threadListFlagAction(_ flag: Bool, isMultiSelected: Bool) -> NewCoreEvent {
        let event = NewCoreEvent(event: .email_thread_list_click)
        event.params = [EVENT_KEY_CLICK: "thread_action",
                        EVENT_KEY_TARGET: "none",
                        EVENT_KEY_ACTION_POSITION: "thread_hover",
                        EVENT_KEY_ACTION_TYPE: flag ? "flag" : "unflag",
                        EVENT_KEY_IS_MULTISELECTED: isMultiSelected,
                        "mail_service_type": Store.settingData.getMailAccountListType()]
        return event
    }

    static func outboxBannerClick(isClosed: Bool) {
        let event = NewCoreEvent(event: .email_send_status_banner_click)
        event.params = ["click": isClosed ? "close" : "mail_detail", "target": "none"]
        event.post()
    }
}
