//
//  File.swift
//  MailSDK
//
//  Created by tefeng liu on 2021/1/8.
//

import Foundation

// DOCS: https://bytedance.feishu.cn/docs/doccn3DtajxRn61etDgirQbOzNb?appid=2

enum MailAPMInteractiveErrorEvent: String {
    // alert
    case has_been_recall
    case shared_thread_removed_by_owner
    case send_attachment_blocked
    case send_docsurl_contacts_cannot_access
    case send_largefile_external_cannot_access
    case send_largefile_external_permission_change
    case share_mail_image_uploading
    case share_mail_not_reachable
    case send_compose_has_been_deleted
    case share_draft_discarded_by_owner
    case share_draft_sent_by_owner
    case send_more_save_draft_uploading_image
    case send_select_attachment_blocked
    case send_save_draft_image_uploading
    case schedule_send_time_invalid
    case ooo_save_date_time_invalid
    case migration_done_with_error
    case migration_terminated
    // toast
    case label_create_empty_name
    case folder_create_empty_name
    case recall_mail_fail_timeout
    case recall_mail_fail_not_sent
    case recall_mail_fail_has_been_recall
    case read_mail_translations_network_error
    case share_send_to_chat_fail
    case share_send_to_chat_no_target
    case share_send_to_chat_max_target
    case mailclient_oauth_access_denied_deleting
    case label_create_custom_fail
    case label_modify_custom_fail
    case label_delete_custom_fail
    case folder_create_custom_fail
    case folder_modify_custom_fail
    case folder_delete_custom_fail
    case mailclient_oauth_get_url_fail
    case mailclient_unbind_fail
    case read_calendar_reply_fail
    case share_quit_share_from_owner_fail
    case share_quit_share_fail
    case thread_delete_forever_fail
    case message_delete_forever_fail
    case read_unsubscribte_fail
    case schedule_send_cancel_fail
    case read_forward_not_recipient_fail
    case share_create_draft_fail
    case read_delete_draft_fail
    case share_attachment_add_no_permission
    case send_discard_draft_fail
    case send_save_draft_fail
    case ooo_save_draft_body_limit_fail
    case schedule_send_already_exist_fail
    case schedule_send_server_limit
    case send_insert_attachment_overlimit
    case share_add_image_no_permission_fail
    case send_compose_largefile_delete_fail
    case signature_edit_max_characters
    case thread_mark_all_read_fail
    case thread_empty_all_fail
    case read_preview_largefile_send_to_chat_fail
    case mail_setting_update_fail
    case folder_maximumfivelayersmobile
    case mail_translations_notsupported
    case translations_contenttoolarge
    case undo_failed
    case compose_attachment_upload_failed
    case mail_failed_tosend
    case delete_message_error
    case mail_cover_load_error
    case delete_search_address_error
    case mail_lable_or_folder_move_fail
    // error_page
    case messagelist_error_page
    case search_error_page
    case recall_detail_error_page
    case threadlist_error_page
    case labellist_error_page
    // flag
    case threadlist_no_net_flag
    case download_attachment_fail
}

enum MailAPMInteractiveErrorCode: Int {
    case client_error = 40001
    case rust_error = 40002
    case server_error = 50001
}

enum MailAPMInteractiveErrorType: String {
    case alert
    case toast
    case error_page
    case flag
}

enum MailAPMInteractiveErrorScene: String {
    case messagelist
    case threadlist
    case compose
    case outofoffice
    case notification
}

private typealias EndParams = MailAPMInteractiveErrorEndParam
enum MailAPMInteractiveErrorEndParam: MailAPMEventParamAble {
    // MARK: require
    case event(MailAPMInteractiveErrorEvent)
    case error_code(MailAPMInteractiveErrorCode)
    case tips_type(MailAPMInteractiveErrorType)
    // MARK: optional
    case category_scene(MailAPMInteractiveErrorScene)
    case error_message(String)
    // MARK: addtion
    case user_cause(Bool)

    var key: String {
        switch self {
        case .event(_):
            return "event"
        case .error_code(_):
            return "error_code"
        case .tips_type(_):
            return "tips_type"
        case .category_scene(_):
            return "category_scene"
        case .error_message(_):
            return "error_message"
        case .user_cause(_):
            return "user_cause"
        }
    }

    var value: Any {
        switch self {
        case .event(let value):
            return value.rawValue
        case .error_code(let value):
            return value.rawValue
        case .tips_type(let value):
            return value.rawValue
        case .category_scene(let value):
            return value.rawValue
        case .error_message(let value):
            return value
        case .user_cause(let value):
            return value ? 1 : 0
        }
    }
}

// MARK: 用户可感知错误，弹窗或者toast这一类
class MailAPMInteractiveError: MailAPMBaseEvent, MailAPMMonitorable {
    var reciableConfig: MailAPMReciableConfig? {
        return nil
    }

    var startKey: MailAPMEventConstant.StartKey {
        return .unknown
    }

    var requireStartParamsKey: Set<String> {
        return []
    }

    var endKey: MailAPMEventConstant.EndKey {
        return .interactive_error
    }

    var requireEndParamsKey: Set<String> {
        return [EndParams.event(.has_been_recall).key,
                EndParams.error_code(.client_error).key,
                EndParams.tips_type(.alert).key]
    }
}

class InteractiveErrorRecorder {
    static func recordError(event: MailAPMInteractiveErrorEvent,
                            errorCode: MailAPMInteractiveErrorCode = MailAPMInteractiveErrorCode.client_error,
                            tipsType: MailAPMInteractiveErrorType = MailAPMInteractiveErrorType.alert,
                            userCause: Bool = false,
                            scene: MailAPMInteractiveErrorScene? = nil,
                            errorMessage: String? = nil) {
        MailAPMMonitorService.shared.queue.async {
            let apmEvent = MailAPMInteractiveError()
            apmEvent.endParams.append(EndParams.event(event))
            apmEvent.endParams.append(EndParams.error_code(errorCode))
            apmEvent.endParams.append(EndParams.tips_type(tipsType))
            apmEvent.endParams.append(EndParams.user_cause(userCause))
            if let scene = scene {
                apmEvent.endParams.append(EndParams.category_scene(scene))
            }
            if let msg = errorMessage {
                apmEvent.endParams.append(EndParams.error_message(msg))
            }
            apmEvent.markPostStart()
            apmEvent.postEnd()
        }
    }
}

struct ToastErrorEvent {
    let event: MailAPMInteractiveErrorEvent
    var errorCode: MailAPMInteractiveErrorCode = MailAPMInteractiveErrorCode.client_error
    let tips: MailAPMInteractiveErrorType = MailAPMInteractiveErrorType.alert
    var userCause = false
    var scene: MailAPMInteractiveErrorScene?
    var errorMessage: String?
}

extension MailRoundedHUD {
    class func showFailure(with text: String,
                           on view: UIView,
                           event: ToastErrorEvent? = nil) {
        self.showFailure(with: text, on: view)
        if let event = event {
            InteractiveErrorRecorder.recordError(event: event.event,
                                                 errorCode: event.errorCode,
                                                 tipsType: event.tips,
                                                 userCause: event.userCause,
                                                 scene: event.scene,
                                                 errorMessage: event.errorMessage)
        }
    }

    class func showTips(with text: String,
                        on view: UIView,
                        delay: TimeInterval = 3.0,
                        event: ToastErrorEvent? = nil) {
        self.showTips(with: text, on: view, delay: delay)
        if let event = event {
            InteractiveErrorRecorder.recordError(event: event.event,
                                                 errorCode: event.errorCode,
                                                 tipsType: event.tips,
                                                 userCause: event.userCause,
                                                 scene: event.scene,
                                                 errorMessage: event.errorMessage)
        }
    }
}
