//
//  MailTracker+AppReciableSDK.swift
//  MailSDK
//
//  Created by tanghaojin on 2021/6/7.
//

import Foundation
import AppReciableSDK

/*

enum ReciableMapper: String {
//    case firstScreenLoaded = "email_apm_fmp"
//    case labelListLoaded = "email_apm_labellist_load"
//    case threadListLoaded = "email_apm_threadlist_load"
//    case threadMarkAllRead = "email_apm_thread_mark_all_read"
//    case messageListLoaded = "email_apm_messagelist_load"
//    case messageImageLoaded = "email_apm_message_load_image"
//    case draftCreated = "email_apm_create_draft"
//    case draftSend = "email_apm_send_draft"
//    case draftSave = "email_apm_save_draft"
//    case draftContactSearch = "email_apm_draft_contact_search"
//    case draftUploadImage = "email_apm_send_upload_image"
//    case draftUploadAttachment = "email_apm_upload_attachment"
//    case searchListLoaded = "email_apm_searchlist_load"
//    case searchListLoadMore = "email_apm_searchlist_load_more"
//    case labelManageAction = "mail_apm_label_manage_action"
//    case mailStabilityAssert = "mail_stability_assert"

    func sceneMapper() -> Scene {
        switch self {
//        case .firstScreenLoaded:
//            return .MailFMP
//        case
//             .messageListLoaded, .labelManageAction:
//            return .MailRead
//        case .searchListLoaded, .searchListLoadMore:
//            return .MailSearch
//        case .draftUploadImage, .draftUploadAttachment:
//            return .MailDraft
//        case .mailStabilityAssert:
//            return .MailStability
        }
    }

    func eventMapper() -> Event {
        switch self {
//        case .firstScreenLoaded:
//            return .mailFmpLoad
//        case .labelListLoaded:
//            return .mailLabelListLoad
//        case .threadListLoaded:
//            return .mailThreadListLoad
//        case .threadMarkAllRead:
//            return .mailThreadMarkAllRead
//        case .messageListLoaded:
//            return .mailMessageListLoad
//        case .messageImageLoaded:
//            return .mailMessageImageLoad
//        case .searchListLoaded:
//            return .mailSearchListLoad
//        case .searchListLoadMore:
//            return .mailSearchListLoadMore
//        case .draftCreated:
//            return .mailDraftCreate
//        case .draftSend:
//            return .mailDraftSendDraft
//        case .draftSave:
//            return .mailDraftSave
//        case .draftContactSearch:
//            return .mailDraftContactSearch
//        case .draftUploadImage:
//            return .mailDraftUploadImage
//        case .draftUploadAttachment:
//            return .mailDraftUploadAttachment
        case .labelManageAction:
            return .mailLabelManageAction
//        case .mailStabilityAssert:
//            return .mailStabilityAssert
        }
    }

    func costMapper(param: [String: Any]) -> Int? {
        if let intValue = param["time_cost_ms"] as? Int {
            return intValue
        } else if let doubleValue = param["time_cost_ms"] as? Double {
            return doubleValue < Double.init(Int.max) ? Int.init(doubleValue) + 1 : Int.max
        } else if let intValue = param["cost_time"] as? Int {
            return intValue
        } else if let doubleValue = param["cost_time"] as? Double {
            return doubleValue < Double.init(Int.max) ? Int.init(doubleValue) + 1 : Int.max
        }
        return nil
    }

    func pageMapper() -> String? {
        switch self {
//        case .firstScreenLoaded:
//            return "fmp"
        case .labelManageAction:
            return "label"
//        case .threadListLoaded:
//            return "thread"
//        case .messageImageLoaded:
//            return "message"
        case .draftCreated,
             .draftUploadImage, .draftUploadAttachment:
            return "draft"
//        case .searchListLoaded, .searchListLoadMore:
//            return "search"
//        case .mailStabilityAssert:
//            return nil
//        }
    }

    func dicMapper(params: [String: Any],
                   keys: [String],
                   replaceKeys: [String: String] = ["sence": "scene_type",
                                                     "status": "mail_status"],
                   replaceValues: [String: String]? = nil) -> [String: Any]? {
        var res: [String: Any] = [:]
        for key in keys {
            if let value = params[key] {
                var newKey = key
                var newValue = value
                if replaceKeys.keys.contains(key), let temKey = replaceKeys[key] {
                    newKey = temKey
                }
                var strValue: String? = nil
                if let tem = value as? String {
                    strValue = tem
                } else if let tem = value as? Int {
                    strValue = String(tem)
                }
                if let values = replaceValues,
                   let strValue = strValue,
                   values.keys.contains(strValue),
                   let temValue = values[strValue] {
                    newValue = temValue
                }
                res[newKey] = newValue
            }
        }
        return res.isEmpty ? nil : res
    }

    func extraMapper(params: [String: Any]) -> Extra? {
        var latencyDetail: [String: Any]? = nil
        var category: [String: Any]? = nil
        var extra: [String: Any]? = nil
        var metric: [String: Any]? = nil
        var commCategoryKeys: [String] = ["status", "debug_message", "error_code", "app_env", "mail_account_type"]
        switch self {
//        case .firstScreenLoaded:
//            let detailKeys: [String] = ["create_view_cost_time",
//                                         "load_label_list_cost_time",
//                                         "load_thread_list_cost_time"]
//            latencyDetail = dicMapper(params: params, keys: detailKeys)
//
//            let categoryKeys: [String] = commCategoryKeys + ["sence", "mode", "from_db"]
//            category = dicMapper(params: params, keys: categoryKeys)
//        case .labelListLoaded:
//            let categoryKeys: [String] = commCategoryKeys + ["sence", "list_length"]
//            category = dicMapper(params: params, keys: categoryKeys)
//        case .threadListLoaded:
//            let categoryKeys: [String] = commCategoryKeys + ["sence",
//                                          "list_length",
//                                          "from_db"]
//            category = dicMapper(params: params, keys: categoryKeys)
//        case .threadMarkAllRead:
//            let categoryKeys: [String] = commCategoryKeys
//            category = dicMapper(params: params, keys: categoryKeys)
//        case .messageListLoaded:
//            let categoryKeys: [String] = commCategoryKeys + ["sence",
//                                          "from_db"]
//            category = dicMapper(params: params, keys: categoryKeys)
//        case .messageImageLoaded:
//            let categoryKeys: [String] = commCategoryKeys + ["is_cache"]
//            category = dicMapper(params: params,
//                                 keys: categoryKeys)
//            if let size = params["resource_content_length"] {
//                metric = ["resource_content_length": size]
//            }
//            if let upload_ms = params["upload_ms"] {
//                latencyDetail = ["upload_ms": upload_ms]
//            }
//        case .draftCreated:
//            let categoryKeys: [String] = commCategoryKeys + ["sence",
//                                          "mail_body_length",
//                                          "hit_edit_pre_render"]
//            category = dicMapper(params: params,
//                                 keys: categoryKeys,
//                                 replaceValues: ["normal": "compose"])
//        case .draftSend:
//            let detailKeys: [String] = ["time_get_html_ms"]
//            latencyDetail = dicMapper(params: params, keys: detailKeys)
//            let categoryKeys: [String] = commCategoryKeys + ["mail_body_length"]
//            category = dicMapper(params: params, keys: categoryKeys)
//        case .draftSave:
//            let categoryKeys: [String] = commCategoryKeys + ["sence", "mail_body_length"]
//            category = dicMapper(params: params, keys: categoryKeys)
//        case .draftContactSearch:
//            let categoryKeys: [String] = commCategoryKeys
//            category = dicMapper(params: params, keys: categoryKeys)
        case .draftUploadImage, .draftUploadAttachment:
            let categoryKeys: [String] = commCategoryKeys
            category = dicMapper(params: params, keys: categoryKeys)
            if let size = params["resource_content_length"] {
                metric = ["resource_content_length": size]
            }
            if let upload_ms = params["upload_ms"] {
                latencyDetail = ["upload_ms": upload_ms]
            }
//        case .searchListLoaded, .searchListLoadMore:
//            let categoryKeys: [String] = commCategoryKeys
//            category = dicMapper(params: params, keys: categoryKeys)
//        case .labelManageAction:
//            let categoryKeys: [String] = commCategoryKeys + ["action_type",
//                                          "mailbox_type"]
//            category = dicMapper(params: params, keys: categoryKeys)
//        case .mailStabilityAssert:
//            let categoryKeys: [String] = commCategoryKeys + ["message", "error_message"]
//            category = dicMapper(params: params, keys: categoryKeys)
        }
        return Extra.init(isNeedNet: true, latencyDetail: latencyDetail, metric: metric, category: category, extra: extra)

    }

    func reportTimeContainMustParam(params: [String: Any]) -> Bool {
        switch self {
//        case .firstScreenLoaded:
//            if let from = params["sence"] as? String, ["email_tab",
//                                                       "notification",
//                                                       "public_account_change"].contains(from) {
//                return true
//            }
//        case .labelListLoaded:
//            if let from = params["sence"] as? String,
//               ["init", "reload"].contains(from) {
//                return true
//            }
//        case .threadListLoaded:
//            if let from = params["sence"] as? String,
//               ["init", "reload", "load_more",
//                "change_label", "change_folder",
//                "search", "filter_unread", "filter_all"].contains(from) {
//                return true
//            }
        case .draftUploadImage, .draftUploadAttachment, .labelManageAction
            return true
//        case .messageListLoaded:
//            if let from = params["sence"] as? String,
//               ["select_thread", "swipe_thread", "notification", "search", "forward"].contains(from) {
//                return true
//            }
        case .draftCreated:
            if let from = params["sence"] as? String,
               ["normal", "draft", "reply", "reply_all", "forward", "edit_again", "mail_to"].contains(from) {
                return true
            }
        }
        return false
    }

    func shouldReportTimeCost(params: [String: Any]) -> TimeCostParams? {
        guard let cost = costMapper(param: params) else { return nil }
        if reportTimeContainMustParam(params: params) {
            return TimeCostParams(biz: .Mail,
                           scene: sceneMapper(),
                           event: eventMapper(),
                           cost: cost,
                           page: pageMapper(),
                           extra: extraMapper(params: params))
        }
        return nil
    }

    func reportErrorMustParam(params: [String: Any]) -> Bool {
        if reportTimeContainMustParam(params: params), let status = params["status"] as? String,
           ["timeout", "rust_fail", "exception"].contains(status) {
            return true
        }
        return false
    }

    func errorTypeMapper(params: [String: Any]) -> ErrorType {
        var type: ErrorType = .Unknown
        if let status = params["status"] as? String, status == "rust_fail", let errorCode = params["error_code"] as? Int32 {
            if errorCode == 10008 || errorCode == 10018 {
                type = .Network
            } else {
                type = .SDK
            }
        }
        return type
    }

    func errorCodeMapper(params: [String: Any]) -> Int {
        var code: Int = 0
        if let value = params["error_code"],
            let errorCode = Int(String(describing: value)) {
            code = errorCode
        }
        return code
    }

    func shouldReportError(params: [String: Any]) -> ErrorParams? {
        if reportErrorMustParam(params: params) {
            return ErrorParams.init(biz: .Mail,
                                    scene: sceneMapper(),
                                    event: eventMapper(),
                                    errorType: errorTypeMapper(params: params),
                                    errorLevel: .Fatal,
                                    errorCode: errorCodeMapper(params: params),
                                    userAction: nil, page: pageMapper(),
                                    errorMessage: params["status"] as? String ?? "",
                                    extra: extraMapper(params: params))
        }
        return nil
    }

    // 0: success, -1: Error
    func check_report_type(param: [String: Any]?) -> Int {
        guard let param = param else { return -1 }
        if let status_success = param["status"] as? String, status_success == "success" {
            return 0
        }
        return -1
    }
}

extension MailTracker {
    class func reportToAppReciableSDK(key: String, param: [String: Any]?) {
        if let key = ReciableMapper.init(rawValue: key) {
            if let param = param, let check_leave = param["user_leave"] as? Int, check_leave == 1 {
                // 排除user_leave的情况
                return
            }
            if key.check_report_type(param: param) == 0 {
                // 成功的上报耗时
                if let timeCostParams = key.shouldReportTimeCost(params: param ?? [:]) {
                    AppReciableSDK.shared.timeCost(params: timeCostParams)
                }
            } else {
                if let errorParams = key.shouldReportError(params: param ?? [:]) {
                    AppReciableSDK.shared.error(params: errorParams)
                }
            }
        }
    }
}

*/
