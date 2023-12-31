//
//  MailAPMEvent.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/10/4.
//

import Foundation
import AppReciableSDK

/// just for name space
enum MailAPMEvent {
    // MARK: first screen loaded (mail home)
    class FirstScreenLoaded: MailAPMBaseEvent, MailAPMMonitorable {
        var reciableConfig: MailAPMReciableConfig? {
            return MailAPMReciableConfig(event: Event.mailFmpLoad,
                                         scene: .MailFMP,
                                         page: .fmp,
                                         latencyDetailKeys: [EndParam.create_view_cost_time(0),
                                                             EndParam.load_label_list_cost_time(0),
                                                             EndParam.load_thread_list_cost_time(0)],
                                         metricKeys: nil)
        }

        enum CommonParam: MailAPMEventParamAble, CaseIterable {
            case sence_email_tab
            case sence_notification
            case sence_public_account_change

            var key: String {
                return "sence"
            }

            var value: Any {
                switch self {
                case .sence_email_tab:
                    return "email_tab"
                case .sence_notification:
                    return "notification"
                case .sence_public_account_change:
                    return "public_account_change"
                }
            }
        }

        enum EndParam: MailAPMEventParamAble, CaseIterable {
            case mode_cold_start
            case mode_hot_start
            case flag_user_leave(Int)
            case from_db(Int)
            case load_thread_list_cost_time(Int)
            case load_label_list_cost_time(Int)
            case create_view_cost_time(Int)
            case mail_display_type
            case has_first_label_cache(Int)
            case preload_with_unread_mail(Int)

            var key: String {
                switch self {
                case .mode_hot_start, .mode_cold_start:
                    return "mode"
                case .flag_user_leave(_):
                    return "user_leave"
                case .from_db(_):
                    return "from_db"
                case .load_thread_list_cost_time(_):
                    return "load_thread_list_cost_time"
                case .load_label_list_cost_time(_):
                    return "load_label_list_cost_time"
                case .create_view_cost_time(_):
                    return "create_view_cost_time"
                case .mail_display_type:
                    return "mail_display_type"
                case .has_first_label_cache(_):
                    return "has_first_label_cache"
                case .preload_with_unread_mail(_):
                    return "preload_with_unread_mail"
                }
            }

            var value: Any {
                switch self {
                case .mode_cold_start:
                    return "cold_start"
                case .mode_hot_start:
                    return "hot_start"
                case .flag_user_leave(let value):
                    return value
                case .from_db(let value):
                    return value
                case .load_thread_list_cost_time(let value):
                    return value
                case .load_label_list_cost_time(let value):
                    return value
                case .create_view_cost_time(let value):
                    return value
                case .mail_display_type:
                    return Store.settingData.threadDisplayType()
                case .has_first_label_cache(let value):
                    return value
                case .preload_with_unread_mail(let value):
                    return value
                }
            }

            static var allCases: [EndParam] {
                return [EndParam.mode_cold_start,
                        EndParam.mode_hot_start,
                        EndParam.flag_user_leave(0),
                        EndParam.from_db(1),
                        EndParam.load_thread_list_cost_time(-1)]
            }
        }

        var startKey: MailAPMEventConstant.StartKey {
            return .firstScreenLoaded
        }

        var requireStartParamsKey: Set<String> {
            return CommonParam.allKeys()
        }

        var endKey: MailAPMEventConstant.EndKey {
            return .firstScreenLoaded
        }

        var requireEndParamsKey: Set<String> {
            return Set(EndParam.allCases.map({ $0.key }))
        }

        func customPostEnd() {
            let user_leave_flag = endParams.first { (param) -> Bool in
                switch param as? MailAPMEvent.FirstScreenLoaded.EndParam {
                case .flag_user_leave(let flag):
                    return flag == 1
                default:
                    return false
                }
            }
            if user_leave_flag == nil {
                endParams.append(MailAPMEvent.FirstScreenLoaded.EndParam.flag_user_leave(0))
            }
            self.postEnd()
            // 防劣化需求的
            let event = self
            let status = event.endParams.first { (param) -> Bool in
                switch param as? MailAPMEventConstant.CommonParam {
                case .status_success:
                    return true
                default:
                    return false
                }
            }
            if status == nil {
                return
            }
            var paramArray = event.endParams
            if !event.commonParams.isEmpty {
                paramArray.append(contentsOf: event.commonParams)
            }
            var (param, recibaleParams) = paramArray.apmEventParams()
            // we will add cost time for end event
            param["time_cost_ms"] = event.totalCostTime * 1000
            recibaleParams["time_cost_ms"] = event.totalCostTime * 1000
            // check whether key is all covered
            var requireKeys = event.requireEndParamsKey
            for temp in param.keys {
                requireKeys.remove(temp)
            }
            MailTracker.log(event: "mail_startup_time", params: param)
            if let config = event.reciableConfig {
                MailAPMMonitorService.reciablePostEnd(config: config, params: recibaleParams)
            }
        }
    }

    // MARK: threadlist
    class ThreadListLoaded: MailAPMBaseEvent, MailAPMMonitorable {
        var reciableConfig: MailAPMReciableConfig? {
            return MailAPMReciableConfig(event: Event.mailThreadListLoad,
                                         scene: .MailRead,
                                         page: .thread,
                                         latencyDetailKeys: nil,
                                         metricKeys: nil)
        }

        enum CommonParam: MailAPMEventParamAble, CaseIterable {
            case sence_cold_start
            case sence_load_more
            case sence_reload
            case sence_change_label
            case sence_change_folder
            case sence_search
            case sence_filter_unread
            case sence_filter_all

            var key: String {
                return "sence"
            }

            var value: Any {
                switch self {
                case .sence_cold_start:
                    return "init"
                case .sence_load_more:
                    return "load_more"
                case .sence_reload:
                    return "reload"
                case .sence_change_label:
                    return "change_label"
                case .sence_change_folder:
                    return "change_folder"
                case .sence_search:
                    return "search"
                case .sence_filter_unread:
                    return "filter_unread"
                case .sence_filter_all:
                    return "filter_all"
                }
            }
        }

        enum EndParam: MailAPMEventParamAble, CaseIterable {
            case list_length(Int)
            case from_db(Int)
            case label_id(String)

            var key: String {
                switch self {
                case .list_length:
                    return "list_length"
                case .from_db(_):
                    return "from_db"
                case .label_id(_):
                    return "label_id"
                }
            }

            var value: Any {
                switch self {
                case .list_length(let value):
                    return value
                case .from_db(let value):
                    return value
                case .label_id(let value):
                    return value
                }
            }

            static var allCases: [EndParam] {
                return [EndParam.list_length(0), EndParam.from_db(1)]
            }
        }

        var startKey: MailAPMEventConstant.StartKey {
            return .threadListLoaded
        }

        var requireStartParamsKey: Set<String> {
            return CommonParam.allKeys()
        }

        var endKey: MailAPMEventConstant.EndKey {
            return .threadListLoaded
        }

        var requireEndParamsKey: Set<String> {
            return EndParam.allKeys().union(CommonParam.allKeys()).union(MailAPMEventConstant.CommonParam.allKeys())
        }
    }

    // MARK: thread_mark_all_read
    class ThreadMarkAllRead: MailAPMBaseEvent, MailAPMMonitorable {
        var reciableConfig: MailAPMReciableConfig? {
            return MailAPMReciableConfig(event: Event.mailThreadMarkAllRead,
                                         scene: .MailRead,
                                         page: .thread,
                                         latencyDetailKeys: nil,
                                         metricKeys: nil)
        }


        var requireStartParamsKey: Set<String> = []

        var startKey: MailAPMEventConstant.StartKey {
            return .threadMarkAllRead
        }

        var endKey: MailAPMEventConstant.EndKey {
            return .threadMarkAllRead
        }

        var requireEndParamsKey: Set<String> {
            return MailAPMEventConstant.CommonParam.allKeys()
        }
    }

    // MARK: labellist
    class LabelListLoaded: MailAPMBaseEvent, MailAPMMonitorable {
        var reciableConfig: MailAPMReciableConfig? {
            return MailAPMReciableConfig(event: Event.mailLabelListLoad,
                                         scene: .MailRead,
                                         page: .label,
                                         latencyDetailKeys: nil,
                                         metricKeys: nil)
        }

        enum CommonParam: MailAPMEventParamAble, CaseIterable {
            case sence_cold_start
            case sence_reload

            var key: String {
                return "sence"
            }

            var value: Any {
                switch self {
                case .sence_cold_start:
                    return "init"
                case .sence_reload:
                    return "reload"
                }
            }
        }

        enum EndParam: MailAPMEventParamAble, CaseIterable {
            case list_length(Int)
            var key: String {
                switch self {
                case .list_length:
                    return "list_length"
                }
            }
            var value: Any {
                switch self {
                case .list_length(let value):
                    return value
                }
            }

            static var allCases: [EndParam] {
                return [EndParam.list_length(0)]
            }
        }

        var startKey: MailAPMEventConstant.StartKey {
            return .labelListLoaded
        }

        var requireStartParamsKey: Set<String> {
            return CommonParam.allKeys()
        }

        var endKey: MailAPMEventConstant.EndKey {
            return .labelListLoaded
        }

        var requireEndParamsKey: Set<String> {
            return CommonParam.allKeys().union(MailAPMEventConstant.CommonParam.allKeys())
        }
    }

    // MARK: messagelist
    class MessageListLoaded: MailAPMBaseEvent, MailAPMMonitorable {
        var reciableConfig: MailAPMReciableConfig? {
            return MailAPMReciableConfig(event: Event.mailMessageListLoad,
                                         scene: .MailRead,
                                         page: .message,
                                         latencyDetailKeys: nil,
                                         metricKeys: nil)
        }

        var isFirstScreen = false
        /// 用户实际点击读信时间
        var actualStartTime: TimeInterval?
        var fetchDataStartTime: TimeInterval?
        var renderStartTime: TimeInterval?

        enum CommonParam: MailAPMEventParamAble, CaseIterable {
            case sence_select_thread
            case sence_swipe_thread
            case sence_notification
            case sence_search
            case sence_forward
            case sence_other(String)
            case from_db(Int)
            case userTotalTime(Double)
            case clickToInitTime(Double)
            case fetchDataTime(Double)
            case parseHTMLTime(Double)
            case totalRenderTime(Double)
            case scriptHandleTime(Double)
            case isRead(Int)
            case isConversation(Int)
            case isFirstRead(Int)
            case isUnreadPreload(Int)
            case isNewAtBottom(Int)
            case messageCount(Int)
            case logVersion(Int)
            case messageIDs(String)

            var key: String {
                switch self {
                case .sence_select_thread, .sence_swipe_thread,
                        .sence_notification, .sence_search, .sence_forward, .sence_other(_):
                    return "sence"
                case .from_db(_):
                    return "from_db"
                case .userTotalTime(_):
                    return "user_total_time"
                case .clickToInitTime(_):
                    return "click_to_create_time"
                case .fetchDataTime(_):
                    return "get_data_time"
                case .parseHTMLTime(_):
                    return "parse_time"
                case .totalRenderTime(_):
                    return "total_render_time"
                case .scriptHandleTime(_):
                    return "js_handle_time"
                case .isRead(_):
                    return "is_read"
                case .isConversation(_):
                    return "is_conversation"
                case .isFirstRead(_):
                    return "is_first_read"
                case .isUnreadPreload(_):
                    return "is_unread_preload"
                case .isNewAtBottom(_):
                    return "is_new_in_bottom"
                case .messageCount(_):
                    return "msg_count"
                case .logVersion(_):
                    return "log_version"
                case .messageIDs(_):
                    return "message_ids"
                }
            }

            var value: Any {
                switch self {
                case .sence_select_thread:
                    return "select_thread"
                case .sence_swipe_thread:
                    return "swipe_thread"
                case .sence_notification:
                    return "notification"
                case .sence_search:
                    return "search"
                case .sence_other(let scene):
                    return scene
                case .sence_forward:
                    return "forward"
                case .from_db(let value):
                    return value
                case .userTotalTime(let time):
                    return time
                case .clickToInitTime(let time):
                    return time
                case .fetchDataTime(let time):
                    return time
                case .parseHTMLTime(let time):
                    return time
                case .totalRenderTime(let time):
                    return time
                case .scriptHandleTime(let time):
                    return time
                case .isRead(let value):
                    return value
                case .isConversation(let value):
                    return value
                case .isFirstRead(let value):
                    return value
                case .isUnreadPreload(let value):
                    return value
                case .isNewAtBottom(let value):
                    return value
                case .messageCount(let count):
                    return count
                case .logVersion(let version):
                    return version
                case .messageIDs(let msgIds):
                    return msgIds
                }
            }

            static var allCases: [CommonParam] {
                return [CommonParam.sence_select_thread,
                        CommonParam.sence_swipe_thread,
                        CommonParam.sence_notification,
                        CommonParam.sence_search,
                        CommonParam.sence_forward,
                        CommonParam.from_db(1)]
            }
        }

        var startKey: MailAPMEventConstant.StartKey {
            return .messageListLoaded
        }

        var requireStartParamsKey: Set<String> {
            return [CommonParam.sence_select_thread.key,
                    CommonParam.sence_swipe_thread.key,
                    CommonParam.sence_notification.key,
                    CommonParam.sence_search.key,
                    CommonParam.sence_forward.key]
        }

        var endKey: MailAPMEventConstant.EndKey {
            return .messageListLoaded
        }

        var requireEndParamsKey: Set<String> {
            return CommonParam.allKeys().union(MailAPMEventConstant.CommonParam.allKeys())
        }
    }

    // MARK: new messagelist
    // https://bytedance.larkoffice.com/wiki/GgTdwoghTipECBkXqYjcygwanzg
    class NewMessageListLoaded: MailAPMBaseEvent, MailAPMMonitorable {
        var reciableConfig: MailAPMReciableConfig? {
            return nil
        }

        enum MessageLoadStage: String {
            case init_ui
            case get_thread_info
            case load_template
            case generate_html
            case webview_load_html
            case webview_parse_html
            case js_handle
            case js_first_scale
            case dom_ready
        }

        var stage: MessageLoadStage = .init_ui
        /// 用户实际点击读信时间
        var actualStartTime: TimeInterval?
        var fetchDataStartTime: TimeInterval?
        var userVisibleTime: TimeInterval?

        enum CommonParam: MailAPMEventParamAble, CaseIterable {
            case threadID(String)
            case messageCount(Int)
            case bodyHTMLLength(Int)
            case isLargeMail(Bool)
            case isFirstIndex(Bool)
            case mailStatus(String)
            case initUICost(Int)
            case waitHTMLCost(Int)
            case renderHTMLCost(Int)
            case renderAllCost(Int)
            case renderFirstFrameCost(Int)
            case getThreadInfoCost(Int)
            case loadTemplateCost(Int)
            case generateHTMLCost(Int)
            case webviewLoadHTMLCost(Int)
            case webviewParseHTMLCost(Int)
            case scriptHandleTime(Int)
            case firstScaleCost(Int)
            case timeTotalCost(Int)
            case userWaitingCost(Int)
            case isReuseWebView(Bool)
            case isThreadInfoReady(Bool)
            case isUserLeaveBlank(Bool)
            case userLeaveBlockStage(String)
            case isInBackground(Bool)

            var key: String {
                switch self {
                case .threadID: return "mail_thread_id"
                case .messageCount: return "mail_msg_count"
                case .bodyHTMLLength: return "mail_body_length"
                case .isLargeMail: return "mail_is_big_msg"
                case .isFirstIndex: return "is_first_index"
                case .mailStatus: return "mail_status"
                case .initUICost: return "init_ui_cost"
                case .waitHTMLCost: return "wait_html_cost"
                case .renderHTMLCost: return "render_html_cost"
                case .renderAllCost: return "render_all_cost"
                case .renderFirstFrameCost: return "render_first_frame_cost"
                case .getThreadInfoCost: return "get_thread_info_cost"
                case .loadTemplateCost: return "load_template_cost"
                case .generateHTMLCost: return "generate_html_cost"
                case .webviewLoadHTMLCost: return "webview_load_html_cost"
                case .webviewParseHTMLCost: return "webview_parse_html_cost"
                case .scriptHandleTime: return "js_handle_cost"
                case .firstScaleCost: return "js_first_scale_cost"
                case .timeTotalCost: return "time_total_cost"
                case .userWaitingCost: return "user_waiting_cost"
                case .isReuseWebView: return "is_ui_ready"
                case .isThreadInfoReady: return "is_thread_info_ready"
                case .isUserLeaveBlank: return "is_user_leave_blank"
                case .userLeaveBlockStage: return "user_leave_block_stage"
                case .isInBackground: return "is_in_background"
                }
            }

            var value: Any {
                switch self {
                case .threadID(let threadID): return threadID
                case .messageCount(let count): return count
                case .bodyHTMLLength(let length): return length
                case .isLargeMail(let isLarge): return isLarge ? "true" : "false"
                case .isFirstIndex(let isFirst): return isFirst ? "true" : "false"
                case .mailStatus(let status): return status
                case .initUICost(let cost): return cost
                case .waitHTMLCost(let cost): return cost
                case .renderHTMLCost(let cost): return cost
                case .renderAllCost(let cost): return cost
                case .renderFirstFrameCost(let cost): return cost
                case .getThreadInfoCost(let cost): return cost
                case .loadTemplateCost(let cost): return cost
                case .generateHTMLCost(let cost): return cost
                case .webviewLoadHTMLCost(let cost): return cost
                case .webviewParseHTMLCost(let cost): return cost
                case .scriptHandleTime(let time): return time
                case .firstScaleCost(let cost): return cost
                case .timeTotalCost(let cost): return cost
                case .userWaitingCost(let cost): return cost
                case .isReuseWebView(let isReady): return isReady ? "true" : "false"
                case .isThreadInfoReady(let isReady): return isReady ? "true" : "false"
                case .isUserLeaveBlank(let isLeave): return isLeave ? "true" : "false"
                case .userLeaveBlockStage(let stage): return stage
                case .isInBackground(let isBackground): return isBackground ? "true" : "false"
                }
            }

            static var allCases: [CommonParam] {
                return []
            }
        }

        var startKey: MailAPMEventConstant.StartKey {
            return .unknown
        }

        var requireStartParamsKey: Set<String> {
            return []
        }

        var endKey: MailAPMEventConstant.EndKey {
            return .newMessageListLoaded
        }

        var requireEndParamsKey: Set<String> {
            return []
        }
    }

    // MARK: Draft Load
    class DraftLoaded: MailAPMBaseEvent, MailAPMMonitorable {
        var reciableConfig: MailAPMReciableConfig? {
            return MailAPMReciableConfig(event: Event.mailDraftCreate,
                                         scene: .MailDraft,
                                         page: .draft,
                                         latencyDetailKeys: dynamicLatencyDetails,
                                         metricKeys: nil)
        }

        enum CommonParam: MailAPMEventParamAble {
            case sence_normal
            case sence_draft
            case sence_reply
            case sence_reply_all
            case sence_forward
            case sence_edit_again
            case sence_mail_to

            var key: String {
                return "sence"
            }

            var value: Any {
                switch self {
                case .sence_normal:
                    return "normal"
                case .sence_draft:
                    return "draft"
                case .sence_reply:
                    return "reply"
                case .sence_reply_all:
                    return "reply_all"
                case .sence_forward:
                    return "forward"
                case .sence_edit_again:
                    return "edit_again"
                case .sence_mail_to:
                    return "mail_to"

                }
            }
        }

        enum EndParam: MailAPMEventParamAble, CaseIterable {
            case mail_body_length(Int)
            case hit_edit_pre_render(Bool)
            case activity_created_cost_time(TimeInterval)
            case hit_edit_cache(Bool)
            case draft_id(String)

            var key: String {
                switch self {
                case .mail_body_length:
                    return "mail_body_length"
                case .hit_edit_pre_render:
                    return "hit_edit_pre_render"
                case .activity_created_cost_time:
                    return "activity_created_cost_time"
                case .hit_edit_cache:
                    return "hit_edit_cache"
                case .draft_id(_):
                    return "draft_id"
                }
            }

            var value: Any {
                switch self {
                case .mail_body_length(let value):
                    return value
                case .hit_edit_pre_render(let value):
                    return value
                case .activity_created_cost_time(let value):
                    return value
                case .hit_edit_cache(let value):
                    return value
                case .draft_id(let value):
                    return value
                }
            }

            static var allCases: [EndParam] {
                return [EndParam.mail_body_length(0), EndParam.hit_edit_pre_render(false), EndParam.hit_edit_cache(false)]
            }
        }

        var startKey: MailAPMEventConstant.StartKey {
            return .draftCreated
        }

        var requireStartParamsKey: Set<String> {
            return [CommonParam.sence_normal.key]
        }

        var endKey: MailAPMEventConstant.EndKey {
            return .draftCreated
        }

        var requireEndParamsKey: Set<String> {
            return EndParam.allKeys().union([CommonParam.sence_normal.key]).union(MailAPMEventConstant.CommonParam.allKeys())
        }

        // MARK: custom property
        private var dynamicLatencyDetails: [MailAPMEventParamAble] = []

        func appendCustomLantency(param: MailAPMEventParamAble) {
            dynamicLatencyDetails.append(param)
            endParams.append(param)
        }
    }

    // MARK: send draft
    class SendDraft: MailAPMBaseEvent, MailAPMMonitorable {
        var enableTimeoutCheck: Bool {
            return !Store.settingData.mailClient
        }
        var reciableConfig: MailAPMReciableConfig? {
            return MailAPMReciableConfig(event: Event.mailDraftSendDraft,
                                         scene: .MailDraft,
                                         page: .draft,
                                         latencyDetailKeys: [EndParam.time_get_html(0)] + dynamicLatencyDetails,
                                         metricKeys: nil)
        }

        enum EndParam: MailAPMEventParamAble, CaseIterable {
            case mail_body_length(Int)
            case time_get_html(TimeInterval)
            case status_user_cancel
            case status_blocking
            case draft_id(String)

            var key: String {
                switch self {
                case .time_get_html:
                    return "time_get_html_ms"
                case .mail_body_length:
                    return "mail_body_length"
                case .status_user_cancel, .status_blocking:
                    return "status"
                case .draft_id(_):
                    return "draft_id"
                }
            }

            var value: Any {
                switch self {
                case .time_get_html(let value):
                    return value
                case .mail_body_length(let value):
                    return value
                case .status_user_cancel:
                    return "user_cancel"
                case .status_blocking:
                    return "blocking"
                case .draft_id(let value):
                    return value
                }
            }

            static var allCases: [EndParam] {
                return [EndParam.time_get_html(0),
                        EndParam.mail_body_length(0)]
            }
        }

        var startKey: MailAPMEventConstant.StartKey {
            return .sendDraft
        }

        var requireStartParamsKey: Set<String> {
            return []
        }

        var endKey: MailAPMEventConstant.EndKey {
            return .sendDraft
        }

        var requireEndParamsKey: Set<String> {
            return EndParam.allKeys().union(MailAPMEventConstant.CommonParam.allKeys())
        }

        // MARK: custom property
        private var dynamicLatencyDetails: [MailAPMEventParamAble] = []

        func appendCustomLantency(param: MailAPMEventParamAble) {
            dynamicLatencyDetails.append(param)
            endParams.append(param)
        }
    }

    // MARK: send draft
    class SaveDraft: MailAPMBaseEvent, MailAPMMonitorable {
        var reciableConfig: MailAPMReciableConfig? {
            return MailAPMReciableConfig(event: Event.mailDraftSave,
                                         scene: .MailDraft,
                                         page: .draft,
                                         latencyDetailKeys: dynamicLatencyDetails,
                                         metricKeys: nil)
        }

        enum CommonParam: MailAPMEventParamAble, CaseIterable {
            case auto_save
            case background_save
            case user_save
            case ooo_save
            case mail_client_save

            var key: String {
                return "sence"
            }

            var value: Any {
                switch self {
                case .auto_save:
                    return "auto_save"
                case .background_save:
                    return "background_save"
                case .user_save:
                    return "user_save"
                case .ooo_save:
                    return "ooo_save"
                case .mail_client_save:
                    return "mail_client_save"
                }
            }
        }
        enum EndParam: MailAPMEventParamAble, CaseIterable {
            case mail_body_length(Int)
            var key: String {
                switch self {
                case .mail_body_length:
                    return "mail_body_length"
                }
            }
            var value: Any {
                switch self {
                case .mail_body_length(let value):
                    return value
                }
            }

            static var allCases: [EndParam] {
                return [EndParam.mail_body_length(0)]
            }
        }

        var startKey: MailAPMEventConstant.StartKey {
            return .saveDraft
        }

        var requireStartParamsKey: Set<String> {
            return CommonParam.allKeys()
        }

        var endKey: MailAPMEventConstant.EndKey {
            return .saveDraft
        }

        var requireEndParamsKey: Set<String> {
            return EndParam.allKeys().union(CommonParam.allKeys()).union(MailAPMEventConstant.CommonParam.allKeys())
        }

        // MARK: custom property
        private var dynamicLatencyDetails: [MailAPMEventParamAble] = []

        func appendCustomLantency(param: MailAPMEventParamAble) {
            dynamicLatencyDetails.append(param)
            endParams.append(param)
        }
    }

    // MARK: send draft
    class Search: MailAPMBaseEvent, MailAPMMonitorable {
        var reciableConfig: MailAPMReciableConfig? {
            return MailAPMReciableConfig(event: Event.mailSearchListLoad,
                                         scene: .MailSearch,
                                         page: .search,
                                         latencyDetailKeys: nil,
                                         metricKeys: nil)
        }

        enum EndParam: MailAPMEventParamAble, CaseIterable {
            case status_re_input

            var key: String {
                switch self {
                case .status_re_input:
                    return "status"
                }
            }

            var value: Any {
                switch self {
                case .status_re_input:
                    return "re_input"
                }
            }
        }

        var startKey: MailAPMEventConstant.StartKey {
            return .search
        }

        var requireStartParamsKey: Set<String> {
            return []
        }

        var endKey: MailAPMEventConstant.EndKey {
            return .search
        }

        var requireEndParamsKey: Set<String> {
            return MailAPMEventConstant.CommonParam.allKeys()
        }
    }

    // MARK: send draft
    class SearchLoadMore: MailAPMBaseEvent, MailAPMMonitorable {
        var reciableConfig: MailAPMReciableConfig? {
            return MailAPMReciableConfig(event: Event.mailSearchListLoadMore,
                                         scene: .MailSearch,
                                         page: .search,
                                         latencyDetailKeys: nil,
                                         metricKeys: nil)
        }


        var startKey: MailAPMEventConstant.StartKey {
            return .searchMore
        }

        var requireStartParamsKey: Set<String> {
            return []
        }

        var endKey: MailAPMEventConstant.EndKey {
            return .searchMore
        }

        var requireEndParamsKey: Set<String> {
            return MailAPMEventConstant.CommonParam.allKeys()
        }
    }

    // MARK: label manage action
    class LabelManageAction: MailAPMBaseEvent, MailAPMMonitorable {
        var reciableConfig: MailAPMReciableConfig? {
            return MailAPMReciableConfig(event: Event.mailLabelManageAction,
                                         scene: .MailRead,
                                         page: .label,
                                         latencyDetailKeys: nil,
                                         metricKeys: nil)
        }

        enum EndParam: MailAPMEventParamAble, CaseIterable {
            case action_type(String)
            case mailbox_type(String)

            var key: String {
                switch self {
                case .action_type(_):
                    return "action_type"
                case .mailbox_type(_):
                    return "mailbox_type"
                }
            }
            var value: Any {
                switch self {
                case .action_type(let value):
                    return value
                case .mailbox_type(let value):
                    return value
                }
            }

            static var allCases: [EndParam] {
                return [EndParam.action_type(""), EndParam.action_type("")]
            }
        }

        var startKey: MailAPMEventConstant.StartKey {
            return .labelManageAction
        }

        var requireStartParamsKey: Set<String> {
            return []
        }

        var endKey: MailAPMEventConstant.EndKey {
            return .labelManageAction
        }

        var requireEndParamsKey: Set<String> {
            return MailAPMEventConstant.CommonParam.allKeys()
        }
    }

    // MARK: messagelist image load
    class MessageImageLoad: MailAPMBaseEvent, MailAPMMonitorable {
        var enableTimeoutCheck: Bool {
            return false // 这个埋点不做自己的timeout
        }

        var reciableConfig: MailAPMReciableConfig? {
            return MailAPMReciableConfig(event: endKey,
                                         scene: .MailRead,
                                         page: .message,
                                         latencyDetailKeys: [EndParam.upload_ms(0)],
                                         metricKeys: [EndParam.resource_content_length(0)])
        }


        var startKey: MailAPMEventConstant.StartKey {
            return .unknown
        }

        var requireStartParamsKey: Set<String> {
            return []
        }

        var endKey: MailAPMEventConstant.EndKey {
            return .mailMessageImageLoad
        }

        enum EndParam: MailAPMEventParamAble {
            case resource_content_length(Int)
            case upload_ms(Int)
            case is_cache(Int)
            case optimize_feat(String)
            case in_queue_time(Int)
            case actual_download_time(Int)
            case scheme(String)
            case download_type(String)
            case is_blocked(Int)
            case is_current(Int)
            case total_cost_time(Int)
            case perceptible_wait_time(Int)
            var key: String {
                switch self {
                case .resource_content_length(_):
                    return "resource_content_length"
                case .upload_ms(_):
                    return "upload_ms"
                case .is_cache(_):
                    return "is_cache"
                case .optimize_feat:
                    return "optimize_feat"
                case .in_queue_time:
                    return "in_queue_time"
                case .actual_download_time:
                    return "actual_download_time"
                case .scheme:
                    return "scheme"
                case .download_type:
                    return "download_type"
                case .is_blocked(_):
                    return "is_blocked"
                case .is_current(_):
                    return "is_current"
                case .total_cost_time(_):
                    return "total_cost_time"
                case .perceptible_wait_time(_):
                    return "perceptible_wait_time"
                }
            }
            var value: Any {
                switch self {
                case .resource_content_length(let value):
                    return value
                case .upload_ms(let value):
                    return value
                case .is_cache(let value):
                    return value
                case .optimize_feat(let value):
                    return value
                case .in_queue_time(let value):
                    return value
                case .actual_download_time(let value):
                    return value
                case .scheme(let value):
                    return value
                case .download_type(let value):
                    return value
                case .is_blocked(let value):
                    return value
                case .is_current(let value):
                    return value
                case .total_cost_time(let value):
                    return value
                case .perceptible_wait_time(let value):
                    return value
                }
            }
        }

        var requireEndParamsKey: Set<String> {
            return MailAPMEventConstant.CommonParam.allKeys()
        }
    }

    // MARK: draftContactSearch
    class DraftContactSearch: MailAPMBaseEvent, MailAPMMonitorable {
        var enableTimeoutCheck: Bool {
            return false // 这个埋点不做自己的timeout
        }

        var reciableConfig: MailAPMReciableConfig? {
            return MailAPMReciableConfig(event: endKey,
                                         scene: .MailDraft,
                                         page: .draft,
                                         latencyDetailKeys: nil,
                                         metricKeys: nil)
        }


        var startKey: MailAPMEventConstant.StartKey {
            return .unknown
        }

        var requireStartParamsKey: Set<String> {
            return []
        }

        var endKey: MailAPMEventConstant.EndKey {
            return .mailDraftContactSearch
        }

        enum EndParam: MailAPMEventParamAble {
            case from_local_local
            case from_local_network

            var key: String {
                switch self {
                case .from_local_local, .from_local_network:
                    return "from_local"
                }
            }
            var value: Any {
                switch self {
                case .from_local_local:
                    return "local"
                case .from_local_network:
                    return "network"
                }
            }
        }

        var requireEndParamsKey: Set<String> {
            return MailAPMEventConstant.CommonParam.allKeys()
        }
    }

    // MARK: DraftUploadImage
    class DraftUploadImage: MailAPMBaseEvent, MailAPMMonitorable {
        var enableTimeoutCheck: Bool {
            return false // 这个埋点不做自己的timeout
        }

        var reciableConfig: MailAPMReciableConfig? {
            return MailAPMReciableConfig(event: endKey,
                                         scene: .MailDraft,
                                         page: .draft,
                                         latencyDetailKeys: [EndParam.upload_ms(0)],
                                         metricKeys: [EndParam.resource_content_length(0)])
        }


        var startKey: MailAPMEventConstant.StartKey {
            return .unknown
        }

        var requireStartParamsKey: Set<String> {
            return []
        }

        var endKey: MailAPMEventConstant.EndKey {
            return .mailDraftUploadImage
        }

        enum EndParam: MailAPMEventParamAble {
            case resource_content_length(Int)
            case upload_ms(Int)

            var key: String {
                switch self {
                    case .resource_content_length(_):
                        return "resource_content_length"
                    case .upload_ms(_):
                        return "upload_ms"
                }
            }
            var value: Any {
                switch self {
                case .resource_content_length(let value):
                    return value
                case .upload_ms(let value):
                    return value
                }
            }
        }

        var requireEndParamsKey: Set<String> {
            return MailAPMEventConstant.CommonParam.allKeys()
        }
    }

    // MARK: DraftUploadAttachment
    class DraftUploadAttachment: MailAPMBaseEvent, MailAPMMonitorable {
        var enableTimeoutCheck: Bool {
            return false // 这个埋点不做自己的timeout
        }

        var reciableConfig: MailAPMReciableConfig? {
            return MailAPMReciableConfig(event: endKey,
                                         scene: .MailDraft,
                                         page: .draft,
                                         latencyDetailKeys: [EndParam.upload_ms(0)],
                                         metricKeys: [EndParam.resource_content_length(0)])
        }

        var endKey: MailAPMEventConstant.EndKey {
            return .mailDraftUploadAttachment
        }

        enum EndParam: MailAPMEventParamAble {
            case resource_content_length(Int)
            case upload_ms(Int)

            var key: String {
                switch self {
                    case .resource_content_length(_):
                        return "resource_content_length"
                    case .upload_ms(_):
                        return "upload_ms"
                }
            }
            var value: Any {
                switch self {
                case .resource_content_length(let value):
                    return value
                case .upload_ms(let value):
                    return value
                }
            }
        }

        var requireEndParamsKey: Set<String> {
            return MailAPMEventConstant.CommonParam.allKeys()
        }
    }

    // MARK: 文件风险检测
    class LoadFileRiskInfos: MailAPMBaseEvent, MailAPMMonitorable {
        var reciableConfig: MailAPMReciableConfig? {
            return MailAPMReciableConfig(event: endKey,
                                         scene: customScene,
                                         page: .message,
                                         latencyDetailKeys: nil,
                                         metricKeys: nil)
        }

        // 场景默认读信
        var customScene: Scene = .MailRead

        enum EndParam: MailAPMEventParamAble {
            case requestSourceTerminal
            case requestFileTokensLength(Int)
            case responseRiskInfosLength(Int)

            var key: String {
                switch self {
                case .requestSourceTerminal:
                    return "request_source_terminal"
                case .requestFileTokensLength:
                    return "request_file_tokens_length"
                case .responseRiskInfosLength:
                    return "response_risk_infos_length"
                }
            }

            var value: Any {
                switch self {
                case .requestSourceTerminal:
                    return 3 // UNKNOWN: 0, Browser: 1, PC: 2, Mobile: 3
                case .requestFileTokensLength(let count), .responseRiskInfosLength(let count):
                    return count
                }
            }
        }

        var endKey: MailAPMEventConstant.EndKey {
            return .mailLoadFileRiskInfos
        }

        var requireEndParamsKey: Set<String> {
            return []
        }
    }

    // MARK: 文件内容安全检测
    class LoadFileBannedInfos: MailAPMBaseEvent, MailAPMMonitorable {
        var reciableConfig: MailAPMReciableConfig? {
            return MailAPMReciableConfig(event: endKey,
                                         scene: customScene,
                                         page: .message,
                                         latencyDetailKeys: nil,
                                         metricKeys: nil)
        }

        // 场景默认读信
        var customScene: Scene = .MailRead

        enum EndParam: MailAPMEventParamAble {
            case requestSourceTerminal
            case requestFileTokensLength(Int)
            case responseBannedInfosLength(Int)

            var key: String {
                switch self {
                case .requestSourceTerminal:
                    return "request_source_terminal"
                case .requestFileTokensLength:
                    return "request_file_tokens_length"
                case .responseBannedInfosLength:
                    return "response_banned_infos_length"
                }
            }

            var value: Any {
                switch self {
                case .requestSourceTerminal:
                    return 3 // UNKNOWN: 0, Browser: 1, PC: 2, Mobile: 3
                case .requestFileTokensLength(let count), .responseBannedInfosLength(let count):
                    return count
                }
            }
        }

        var endKey: MailAPMEventConstant.EndKey {
            return .mailLoadFileBannedInfos
        }

        var requireEndParamsKey: Set<String> {
            return []
        }
    }

    // MARK: Mail Cover
    enum MailCoverLoadScene: String {
        /// 点击添加
        case add
        /// 点击随机
        case random
        /// 从 panel 内选择
        case select
        /// 手动重试
        case customReload
        /// 自动重试
        case autoReload
    }

    /// 加载封面数据接口
    class MailLoadCoverListData: MailAPMBaseEvent, MailAPMMonitorable {
        var reciableConfig: MailAPMReciableConfig? {
            return MailAPMReciableConfig(event: endKey,
                                         scene: .MailDraft,
                                         page: .draft,
                                         latencyDetailKeys: nil,
                                         metricKeys: nil)
        }

        enum EndParam: MailAPMEventParamAble {
            case coverLoadScene(MailCoverLoadScene)
            case coverListGroupLength(Int)
            case coverListImageLength(Int)

            var key: String {
                switch self {
                case .coverListGroupLength:
                    return "group_length"
                case .coverListImageLength:
                    return "data_length"
                case .coverLoadScene:
                    return "scene_type"
                }
            }

            var value: Any {
                switch self {
                case .coverListGroupLength(let count), .coverListImageLength(let count):
                    return count
                case .coverLoadScene(let scene):
                    return scene.rawValue
                }
            }
        }

        var endKey: MailAPMEventConstant.EndKey {
            return .loadCoverListData
        }

        var requireEndParamsKey: Set<String> {
            return []
        }
    }

    /// 封面图片下载请求
    class MailLoadCoverData: MailAPMBaseEvent, MailAPMMonitorable {
        var reciableConfig: MailAPMReciableConfig? {
            return MailAPMReciableConfig(event: endKey,
                                         scene: customScene,
                                         page: .draft,
                                         latencyDetailKeys: nil,
                                         metricKeys: nil)
        }

        var customScene: Scene = .MailRead // 场景默认Read

        enum EndParam: MailAPMEventParamAble {
            case coverToken(String)
            case coverLoadScene(MailCoverLoadScene)

            var key: String {
                switch self {
                case .coverToken:
                    return "token"
                case .coverLoadScene:
                    return "scene_type"
                }
            }

            var value: Any {
                switch self {
                case .coverToken(let token):
                    return token
                case .coverLoadScene(let scene):
                    return scene.rawValue
                }
            }
        }

        var endKey: MailAPMEventConstant.EndKey {
            return .loadCoverImageData
        }

        var requireEndParamsKey: Set<String> {
            return []
        }
    }

    // MARK: mail client
    class MailClientCreateAccount: MailAPMBaseEvent, MailAPMMonitorable {
        var reciableConfig: MailAPMReciableConfig? {
            return MailAPMReciableConfig(event: endKey,
                                         scene: .MailAccount,
                                         page: .account,
                                         latencyDetailKeys: nil,
                                         metricKeys: nil)
        }

        enum EndParam: MailAPMEventParamAble, CaseIterable {
            case provider(Int)
            case login_pass_type(Int)
            case client_protocol(Int)
            case encryption(Int)

            var key: String {
                switch self {
                case .provider(_):
                    return "provider"
                case .login_pass_type(_):
                    return "login_pass_type"
                case .client_protocol(_):
                    return "protocol"
                case .encryption(_):
                    return "encryption"
                }
            }

            var value: Any {
                switch self {
                case .provider(let value):
                    return value
                case .login_pass_type(let value):
                    return value
                case .client_protocol(let value):
                    return value
                case .encryption(let value):
                    return value
                }
            }

            static var allCases: [EndParam] {
                return [EndParam.provider(0), EndParam.login_pass_type(1), EndParam.client_protocol(1), EndParam.encryption(0)]
            }
        }

        var startKey: MailAPMEventConstant.StartKey {
            return .unknown
        }

        var requireStartParamsKey: Set<String> {
            return []
        }

        var endKey: MailAPMEventConstant.EndKey {
            return .mailClientCreateAccount
        }

        var requireEndParamsKey: Set<String> {
            return EndParam.allKeys()
        }
    }

    class MailClientUpdateAccountConfig: MailAPMBaseEvent, MailAPMMonitorable {
        var reciableConfig: MailAPMReciableConfig? {
            return MailAPMReciableConfig(event: endKey,
                                         scene: .MailAccount,
                                         page: .account,
                                         latencyDetailKeys: nil,
                                         metricKeys: nil)
        }

        enum EndParam: MailAPMEventParamAble, CaseIterable {
            case provider(Int)
            case login_pass_type(Int)
            case client_protocol(Int)
            case encryption(Int)

            var key: String {
                switch self {
                case .provider(_):
                    return "provider"
                case .login_pass_type(_):
                    return "login_pass_type"
                case .client_protocol(_):
                    return "protocol"
                case .encryption(_):
                    return "encryption"
                }
            }

            var value: Any {
                switch self {
                case .provider(let value):
                    return value
                case .login_pass_type(let value):
                    return value
                case .client_protocol(let value):
                    return value
                case .encryption(let value):
                    return value
                }
            }

            static var allCases: [EndParam] {
                return [EndParam.provider(0), EndParam.login_pass_type(1), EndParam.client_protocol(1), EndParam.encryption(0)]
            }
        }

        var startKey: MailAPMEventConstant.StartKey {
            return .unknown
        }

        var requireStartParamsKey: Set<String> {
            return []
        }

        var endKey: MailAPMEventConstant.EndKey {
            return .mailClientUpdateAccountConfig
        }

        var requireEndParamsKey: Set<String> {
            return EndParam.allKeys()
        }
    }

    class MailClientDeleteAccount: MailAPMBaseEvent, MailAPMMonitorable {
        var reciableConfig: MailAPMReciableConfig? {
            return MailAPMReciableConfig(event: endKey,
                                         scene: .MailAccount,
                                         page: .account,
                                         latencyDetailKeys: nil,
                                         metricKeys: nil)
        }

        enum EndParam: MailAPMEventParamAble, CaseIterable {
            case provider(Int)
            var key: String {
                switch self {
                case .provider(_):
                    return "provider"
                }
            }

            var value: Any {
                switch self {
                case .provider(let value):
                    return value
                }
            }

            static var allCases: [EndParam] {
                return [EndParam.provider(0)]
            }
        }

        var startKey: MailAPMEventConstant.StartKey {
            return .unknown
        }

        var requireStartParamsKey: Set<String> {
            return []
        }

        var endKey: MailAPMEventConstant.EndKey {
            return .mailClientDeleteAccount
        }

        var requireEndParamsKey: Set<String> {
            return EndParam.allKeys()
        }
    }

    class TabUnreadCount: MailAPMBaseEvent, MailAPMMonitorable {
        var reciableConfig: MailAPMReciableConfig? {
            return MailAPMReciableConfig(event: endKey,
                                         scene: .MailAccount,
                                         page: .account,
                                         latencyDetailKeys:nil,
                                         metricKeys: nil)
        }

        var endKey: MailAPMEventConstant.EndKey {
            return .mailTabUnreadCount
        }

        enum EndParam: MailAPMEventParamAble, CaseIterable {
            case sync_status(Int)
            case tab_count_gap(Int)
            case tab_color_gap(Int)
            case account_label_gap(Int)
            case tab_active(Int)

            var key: String {
                switch self {
                case .sync_status(_):
                    return "sync_status"
                case .tab_count_gap(_):
                    return "tab_count_gap"
                case .tab_color_gap(_):
                    return "tab_color_gap"
                case .account_label_gap(_):
                    return "account_label_gap"
                case .tab_active(_):
                    return "tab_active"
                }
            }

            var value: Any {
                switch self {
                case .sync_status(let value):
                    return value
                case .tab_count_gap(let value):
                    return value
                case .tab_color_gap(let value):
                    return value
                case .account_label_gap(let value):
                    return value
                case .tab_active(let value):
                    return value
                }
            }


            static var allCases: [EndParam] {
                return [
                    EndParam.sync_status(0),
                    EndParam.tab_count_gap(0),
                    EndParam.tab_color_gap(0),
                    EndParam.account_label_gap(0),
                    EndParam.tab_active(0)
                ]
            }
        }

        var requireEndParamsKey: Set<String> {
            return EndParam.allKeys().union(MailAPMEventConstant.CommonParam.allKeys())
        }
    }
}

enum MailAPMEventSingle {
    class RustCall: MailAPMBaseEvent, MailAPMMonitorable {
        var reciableConfig: MailAPMReciableConfig? {
            return nil
        }

        enum EndParam: MailAPMEventParamAble {
            case error_message(String)
            case command(String)

            var key: String {
                switch self {
                case .command:
                    return "command"
                case .error_message:
                    return "error_message"
                }
            }

            var value: Any {
                switch self {
                case .command(let value):
                    return value
                case .error_message(let value):
                    return value
                }
            }
        }

        var startKey: MailAPMEventConstant.StartKey {
            return .unknown
        }

        var requireStartParamsKey: Set<String> {
            return []
        }

        var endKey: MailAPMEventConstant.EndKey {
            return .rustCall
        }

        var requireEndParamsKey: Set<String> {
            return MailAPMEventConstant.CommonParam.allKeys().union([EndParam.command("").key])
        }
    }

    class OffTrack: MailAPMBaseEvent, MailAPMMonitorable {
        var reciableConfig: MailAPMReciableConfig? {
            return nil
        }

        enum EndParam: MailAPMEventParamAble {
            case event_name(MailAPMEventConstant.EndKey)
            /// end时没有start
            case type_launch_without_start
            /// end时参数不完整
            case type_launch_without_fill
            /// start参数补齐
            case type_fill_without_start
            /// 重复开始
            case type_repeat_start
            case message(String)

            var key: String {
                switch self {
                case .event_name(_):
                    return "event_name"
                case .type_launch_without_start,
                     .type_launch_without_fill,
                     .type_repeat_start,
                     .type_fill_without_start:
                    return "type"
                case .message(_):
                    return "message"
                }
            }

            var value: Any {
                switch self {
                case .event_name(let name):
                    return name.rawValue
                case .type_launch_without_start:
                    return "launch_without_start"
                case .type_launch_without_fill:
                    return "launch_without_fill"
                case .type_repeat_start:
                    return "repeat_start"
                case .type_fill_without_start:
                    return "fill_without_start"
                case .message(let value):
                    return value
                }
            }
        }

        var startKey: MailAPMEventConstant.StartKey {
            return .unknown
        }

        var requireStartParamsKey: Set<String> {
            return []
        }

        var endKey: MailAPMEventConstant.EndKey {
            return .offTrack
        }

        /// 为了防止死循环，不做检查
        var requireEndParamsKey: Set<String> {
            return []
        }
    }

    class Assert: MailAPMBaseEvent, MailAPMMonitorable {
        var reciableConfig: MailAPMReciableConfig? {
            return MailAPMReciableConfig(event: Event.mailStabilityAssert,
                                         scene: .MailStability,
                                         page: nil,
                                         latencyDetailKeys: nil,
                                         metricKeys: nil)
        }

        enum EndParam: MailAPMEventParamAble {
            case error_message(String)
            case message(String)

            var key: String {
                switch self {
                case .message:
                    return "message"
                case .error_message:
                    return "error_message"
                }
            }

            var value: Any {
                switch self {
                case .message(let value):
                    return value
                case .error_message(let value):
                    return value
                }
            }
        }

        var startKey: MailAPMEventConstant.StartKey {
            return .unknown
        }

        var requireStartParamsKey: Set<String> {
            return []
        }

        var endKey: MailAPMEventConstant.EndKey {
            return .mail_stability_assert
        }

        var requireEndParamsKey: Set<String> {
            return ["message"]
        }
    }

    class BlankCheck: MailAPMBaseEvent, MailAPMMonitorable {
        var reciableConfig: MailAPMReciableConfig? {
            return MailAPMReciableConfig(event: Event.mailBlankCheck,
                                         scene: .MailBlankCheck,
                                         page: nil,
                                         latencyDetailKeys: nil,
                                         metricKeys: nil)
        }

        enum EndParam: MailAPMEventParamAble {
            case page_key(String)
            case is_blank(Int)
            case dom_ready(Int)
            case fcp_time(Int)
            case false_report(Int)
            var key: String {
                switch self {
                case .page_key:
                    return "page_key"
                case .is_blank:
                    return "is_blank"
                case .dom_ready:
                    return "dom_ready"
                case .fcp_time:
                    return "fcp_time"
                case .false_report:
                    return "false_report"
                }
            }

            var value: Any {
                switch self {
                case .page_key(let value):
                    return value
                case .is_blank(let value):
                    return value
                case .dom_ready(let value):
                    return value
                case .fcp_time(let value):
                    return value
                case .false_report(let value):
                    return value
                }
            }
        }

        var startKey: MailAPMEventConstant.StartKey {
            return .unknown
        }

        var requireStartParamsKey: Set<String> {
            return []
        }

        var endKey: MailAPMEventConstant.EndKey {
            return .mailBlankCheck
        }

        var requireEndParamsKey: Set<String> {
            return ["page_key", "is_blank"]
        }
    }

    class ContentSearch: MailAPMBaseEvent, MailAPMMonitorable {
        var reciableConfig: MailAPMReciableConfig? {
            return MailAPMReciableConfig(event: endKey,
                                         scene: .MailRead,
                                         page: nil,
                                         latencyDetailKeys: nil,
                                         metricKeys: nil)
        }

        enum EndParam: MailAPMEventParamAble {
            case result_count(Int)
            case html_length(Int)
            case message_count(Int)
            case messageIDs(String)

            var key: String {
                switch self {
                case .result_count(_):
                    return "result_count"
                case .html_length(_):
                    return "html_length"
                case .message_count(_):
                    return "message_count"
                case .messageIDs(_):
                    return "message_ids"
                }
            }

            var value: Any {
                switch self {
                case .result_count(let value):
                    return value
                case .html_length(let value):
                    return value
                case .message_count(let value):
                    return value
                case .messageIDs(let value):
                    return value
                }
            }
        }

        var startKey: MailAPMEventConstant.StartKey {
            return .unknown
        }

        var requireStartParamsKey: Set<String> {
            return []
        }

        var endKey: MailAPMEventConstant.EndKey {
            return .mailContentSearch
        }

        var requireEndParamsKey: Set<String> {
            return []
        }
    }

    class WebImageSanitize: MailAPMBaseEvent, MailAPMMonitorable {
        var reciableConfig: MailAPMReciableConfig? {
            return MailAPMReciableConfig(event: endKey,
                                         scene: .MailRead,
                                         page: nil,
                                         latencyDetailKeys: nil,
                                         metricKeys: nil)
        }

        enum EndParam: MailAPMEventParamAble {
            case has_web_image(String)
            case messageIDs(String)

            var key: String {
                switch self {
                case .has_web_image(_):
                    return "has_web_image"
                case .messageIDs(_):
                    return "message_ids"
                }
            }

            var value: Any {
                switch self {
                case .has_web_image(let value):
                    return value
                case .messageIDs(let value):
                    return value
                }
            }
        }

        var startKey: MailAPMEventConstant.StartKey {
            return .unknown
        }

        var requireStartParamsKey: Set<String> {
            return []
        }

        var endKey: MailAPMEventConstant.EndKey {
            return .mailWebImageSanitize
        }

        var requireEndParamsKey: Set<String> {
            return []
        }
    }
}
