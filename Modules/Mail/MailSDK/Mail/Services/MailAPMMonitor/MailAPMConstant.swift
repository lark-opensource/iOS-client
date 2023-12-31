//
//  MailAPMConstant.swift
//  MailSDK
//
//  Created by tefeng liu on 2022/7/4.
//

import Foundation
import AppReciableSDK

enum MailAPMEventConstant {
    enum StartKey: String {
        /// when you dont need start. you can use it
        case unknown = ""
        case firstScreenLoaded = "email_apm_fmp_start"
        case threadListLoaded = "email_apm_threadlist_load_start"
        case threadMarkAllRead = "email_apm_thread_mark_all_read_start"
        case labelListLoaded = "email_apm_labellist_load_start"
        case messageListLoaded = "email_apm_messagelist_load_start"
        case draftCreated = "email_apm_create_draft_start"
        case sendDraft = "email_apm_send_draft_start"
        case saveDraft = "email_apm_save_draft_start"
        case search = "email_apm_searchlist_load_start"
        case searchMore = "email_apm_searchlist_load_more_start"
        // 以下是用于新的sladar埋点接口的点，为了代码统一。TEA也对应
        case labelManageAction = "mail_apm_label_manage_action_start"
    }

    enum EndKey: String, ReciableEventable {
        /// when you dont need end. you can use it
        case unknown = ""
        /// *** APMSCRIPT START ***  请不要改这个注释
        case firstScreenLoaded = "email_apm_fmp"
        case threadListLoaded = "email_apm_threadlist_load"
        case threadMarkAllRead = "email_apm_thread_mark_all_read"
        case labelListLoaded = "email_apm_labellist_load"
        case messageListLoaded = "email_apm_messagelist_load"
        case newMessageListLoaded = "email_apm_mail_message_list_load"
        case draftCreated = "email_apm_create_draft"
        case sendDraft = "email_apm_send_draft"
        case saveDraft = "email_apm_save_draft"
        case search = "email_apm_searchlist_load"
        case searchMore = "email_apm_searchlist_load_more"
        case rustCall = "email_apm_rust_call"
        case shown_error = "email_apm_shown_error"
        case offTrack = "email_apm_offtrack"
        case interactive_error = "email_apm_user_interactive_error"
        // 以下是用于新的sladar埋点接口的点，为了代码统一。TEA也对应，新增后续埋点也这样
        /// *** APMSCRIPT EVENTKEY *** 请不要改动这个注释
        case mail_stability_assert = "mail_stability_assert"
        case labelManageAction = "mail_apm_label_manage_action"
        case mailMessageImageLoad = "mail_message_image_load"
        case mailDraftContactSearch = "mail_draft_contact_search"
        case mailDraftUploadImage = "mail_draft_add_image"
        case mailDraftUploadAttachment = "mail_draft_add_attachment"
        case loadCoverListData = "mail_load_cover_data"
        case loadCoverImageData = "mail_load_cover_image"
        case mailClientCreateAccount = "mail_ptcl_create_account"
        case mailClientUpdateAccountConfig = "mail_ptcl_update_account_config"
        case mailClientDeleteAccount = "mail_ptcl_delete_account"
        case mailBlankCheck = "mail_blank_check"
        case mailLoadFileRiskInfos = "mail_load_file_risk_infos"
        case mailLoadFileBannedInfos = "mail_load_file_banned_infos"
        case mailTabUnreadCount = "mail_tab_unread_count"
        case mailContentSearch = "mail_content_search_result"
        case mailWebImageSanitize = "mail_web_image_sanitize"
        /// *** APMSCRIPT EVENTKEY_END *** 请不要改动这个注释

        var eventKey: String {
            return self.rawValue
        }
    }

    enum CommonParam: MailAPMEventParamAble, CaseIterable {
        case status_success
        case status_timeout
        case status_rust_fail
        case status_exception
        case status_render_fail
        case status_user_leave
        case status_http_fail
        case net_status(Int)
        case error_code(Int)
        case debug_message(String)
        case app_env(String)
        case error_log_id(String)
        case mail_account_type(String)
        case optimize_feat(String)
        case customKeyValue(key: String, value: Any)

        /// *** APMSCRIPT COMMON *** 请不要改动这个注释
        var key: String {
            switch self {
            case .status_success, .status_timeout,
                 .status_user_leave, .status_rust_fail,
                 .status_exception, .status_http_fail, .status_render_fail:
                return "status"
            case .net_status(_):
                return "net_status"
            case .error_code(_):
                return "error_code"
            case .debug_message:
                return "debug_message"
            case .app_env:
                return "app_env"
            case .error_log_id(_):
                return "log_id"
            case .mail_account_type(_):
                return "mail_account_type"
            case .optimize_feat(_):
                return "optimize_feat"
            case .customKeyValue(key: let key, value: _):
                return key
            }
        }
        /// *** APMSCRIPT COMMON_END *** 请不要改动这个注释

        var value: Any {
            switch self {
            case .status_success:
                return "success"
            case .status_timeout:
                return "timeout"
            case .status_rust_fail:
                return "rust_fail"
            case .status_exception:
                return "exception"
            case .status_user_leave:
                return "user_leave"
            case .status_render_fail:
                return "render_fail"
            case .status_http_fail:
                return "http_fail"
            case .net_status(let value):
                return value
            case .error_code(let value):
                return value
            case .debug_message(let value):
                return value
            case .app_env(let value):
                return value
            case .error_log_id(let value):
                return value
            case .mail_account_type(let value):
                return value
            case .customKeyValue(key: _, value: let value):
                return value
            case .optimize_feat(let value):
                return value
            }
        }

        static var allCases: [CommonParam] {
            return [CommonParam.status_success, CommonParam.status_timeout, CommonParam.status_rust_fail,
                    CommonParam.status_exception, CommonParam.status_user_leave, CommonParam.net_status(0), CommonParam.app_env(MailEnvConfig.appEnv)]
        }
    }
}

/// config for AppReciable event
struct MailAPMReciableConfig {
    enum Page: String {
        /// *** APMSCRIPT PAGE *** 请不要改动这个注释
        case fmp
        case label
        case thread
        case message
        case draft
        case search
        case account
        /// *** APMSCRIPT PAGE_END *** 请不要改动这个注释
    }

    let event: ReciableEventable

    let scene: Scene

    let page: Page?

    /// 需要填充到latencyDetail字段的key
    let latencyDetailKeys: [MailAPMEventParamAble]?

    /// 需要填充到metric字段的key
    let metricKeys: [MailAPMEventParamAble]?
}
/// *** APMSCRIPT END *** 请不要改这个注释

