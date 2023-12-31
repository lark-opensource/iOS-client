//
//  Monitor.swift
//  NewLarkDynamic
//
//  Created by MJXin on 2022/4/27.
//

import Foundation
import ECOProbeMeta
import ECOProbe
import ECOInfra
import LarkRustClient

public struct MonitorField {
    public enum ActionTypeValue: Int {
        case url = 0
        case request = 1
    }
    enum RenderTypeValue: Int {
        case cardInit = 0
        case cardUpdate = 1
    }
    public static let TraceID = "trace_id"
    public static let MessageID = "message_id"
    public static let ImageID = "image_id"
    public static let ContentLength = "content_length"
    public static let ActionID = "action_id"
    public static let RequestID = "request_id"
    public static let ActionType = "action_type"
    public static let UrlLength = "url_length"
    public static let HttpCode = "http_code"
    public static let UnknownTags = "unknown_tags"
    public static let UnknownElements = "unknown_elements"
    public static let Version = "version"
    public static let RenderType = "render_type"
    public static let ElementsCount = "elements_count"
    public static let ErrorStatus = "status"
    public static let TTLogId = "log_id"
    public static let EventName = "op_open_card"
    public static let BotID = "bot_id"
    public static let AppID = "app_id"
}

/// 消息卡片上报错误码
/// https://bytedance.feishu.cn/sheets/shtcnCCboz4CUWBUtZkdmZV0PLb?table=tblW5pLo1s&view=vewoNQ73QM#w5jtET
public final class MessageCardMonitorCode: OPMonitorCode {
    static public let messagecard_request_action_success = MessageCardMonitorCode(
        code: 10_006,
        level: OPMonitorLevelNormal,
        message: "messagecard_request_action_success"
    )
    static public let messagecard_request_action_fail = MessageCardMonitorCode(
        code: 10_007,
        level: OPMonitorLevelError,
        message: "messagecard_request_action_fail"
    )
    static public let messagecard_trigger_code_success = MessageCardMonitorCode(
        code: 10_008,
        level: OPMonitorLevelNormal,
        message: "messagecard_trigger_code_success"
    )
    static public let messagecard_trigger_code_fail = MessageCardMonitorCode(
        code: 10_009,
        level: OPMonitorLevelError,
        message: "messagecard_trigger_code_fail"
    )
    static public let messagecard_render_error = MessageCardMonitorCode(
        code: 10_010,
        level: OPMonitorLevelError,
        message: "messagecard_render_error"
    )
    static public let element_id_is_empty = MessageCardMonitorCode(
        code: 10_011,
        level: OPMonitorLevelWarn,
        message: "element_id_is_empty"
    )
    static public let messagecard_image_load_property_error = MessageCardMonitorCode(
        code: 10_012,
        level: OPMonitorLevelError,
        message: "messagecard_image_load_property_error"
    )
    static public let messagecard_image_load_origin_error = MessageCardMonitorCode(
        code: 10_013,
        level: OPMonitorLevelError,
        message: "messagecard_image_load_origin_error"
    )
    static public let messagecard_url_open_unsupport = MessageCardMonitorCode(
        code: 10_014,
        level: OPMonitorLevelError,
        message: "messagecard_url_open_unsupport"
    )
    static public let messagecard_url_open_without_triggercode_func = MessageCardMonitorCode(
        code: 10_015,
        level: OPMonitorLevelError,
        message: "messagecard_url_open_without_triggercode_func"
    )
    static public let messagecard_url_open_without_triggercode = MessageCardMonitorCode(
        code: 10_016,
        level: OPMonitorLevelError,
        message: "messagecard_url_open_without_triggercode"
    )
    static public let messagecard_url_open_url_invalid = MessageCardMonitorCode(
        code: 10_017,
        level: OPMonitorLevelError,
        message: "messagecard_url_open_url_invalid"
    )
    static public let messagecard_url_open_url_limt_interval = MessageCardMonitorCode(
        code: 10_018,
        level: OPMonitorLevelError,
        message: "messagecard_url_open_url_limt_interval"
    )
    static public let messagecard_request_not_allow = MessageCardMonitorCode(
        code: 10_019,
        level: OPMonitorLevelError,
        message: "messagecard_request_not_allow"
    )
    static public let messagecard_request_in_last_process = MessageCardMonitorCode(
        code: 10_020,
        level: OPMonitorLevelError,
        message: "messagecard_request_in_last_process"
    )
    static public let messagecard_request_response_fail = MessageCardMonitorCode(
        code: 10_021,
        level: OPMonitorLevelError,
        message: "messagecard_request_response_fail"
    )
    static public let messagecard_request_response_success = MessageCardMonitorCode(
        code: 10_022,
        level: OPMonitorLevelNormal,
        message: "messagecard_request_response_success"
    )
    private init(code: Int, level: OPMonitorLevel, message: String) {
        super.init(domain: MessageCardMonitorCode.domain,
                   code: code,
                   level: level,
                   message: message)
    }
    static public let domain = "client.open_platform.card"
}

extension OPMonitor {
    public func setActionType(_ type: MonitorField.ActionTypeValue?) -> OPMonitor {
        return self.addCategoryValue(MonitorField.ActionType, type?.rawValue)
    }
}

extension LDContext {
    /// 上报 Action 相关埋点
    /// - Parameters:
    ///   - trace: 当前上下文中的 Trace
    ///   - actionID: ActionID
    ///   - actionType: Action 类型
    ///   - start: 开始时间
    ///   - error: 错误
    public func reportAction(
        start: Date,
        trace: OPTrace?,
        actionID: String?,
        actionType: MonitorField.ActionTypeValue?,
        error: LDCardError.ActionError?
    ) {
        let duration = Date().timeIntervalSince(start)
        var monitor: OPMonitor?
        switch error {
        case .actionInvalid:
            monitor = OPMonitor(EPMClientOpenPlatformCardCode.messagecard_action_data_error)
                .setResultTypeFail()
                .setError(error)
        case .urlError:
            monitor = OPMonitor(EPMClientOpenPlatformCardCode.messagecard_action_url_error)
                .setResultTypeFail()
                .setError(error)
        case .openLinkUrlInvalid:
            monitor = OPMonitor(MessageCardMonitorCode.messagecard_url_open_url_invalid)
                .setResultTypeFail()
                .setError(error)
        case .openLinkUrlUnsupport:
            monitor = OPMonitor(MessageCardMonitorCode.messagecard_url_open_unsupport)
                .setResultTypeFail()
                .setError(error)
        case .openLinkLimitInterval:
            monitor = OPMonitor(MessageCardMonitorCode.messagecard_url_open_url_limt_interval)
                .setResultTypeFail()
                .setError(error)
        case .openLinkwithoutTriggercodeFunc:
            monitor = OPMonitor(MessageCardMonitorCode.messagecard_url_open_without_triggercode_func)
                .setResultTypeFail()
                .setError(error)
        case .openLinkWithoutTriggercode:
            monitor = OPMonitor(MessageCardMonitorCode.messagecard_url_open_without_triggercode)
                .setResultTypeFail()
                .setError(error)
        case .openLinkFail(_):
            monitor = OPMonitor(MessageCardMonitorCode.messagecard_url_open_unsupport)
                .setResultTypeFail()
                .setError(error)
        case .responseFail(let error):
            var errorInfo: BusinessErrorInfo?
            if case let .businessFailure( info) = error?.metaErrorStack.last as? RCError {
                errorInfo = info
            }
            monitor = OPMonitor(name: MonitorField.EventName, code: MessageCardMonitorCode.messagecard_request_response_fail)
                .setResultTypeFail()
                .setErrorCode(String(errorInfo?.errorCode ?? 0))
                .setErrorMessage(errorInfo?.debugMessage)
                .addCategoryValue(MonitorField.MessageID, self.messageID)
                .addCategoryValue(MonitorField.TTLogId, errorInfo?.ttLogId)
                .addCategoryValue(MonitorField.ErrorStatus, errorInfo?.errorStatus)
        case .actionProcessing:
            monitor = OPMonitor(MessageCardMonitorCode.messagecard_request_in_last_process)
                .setResultTypeFail()
                .setError(error)
        case .actionNotAllow:
            monitor = OPMonitor(MessageCardMonitorCode.messagecard_request_not_allow)
                .setResultTypeFail()
                .setError(error)
        case .none:
            monitor = OPMonitor(name: MonitorField.EventName, code: EPMClientOpenPlatformCardCode.messagecard_request_response_success)
                .setErrorMessage(error?.getMessage())
                .addCategoryValue(MonitorField.MessageID, self.messageID)
                .setDuration(duration)
                .setResultTypeSuccess()
        }
        monitor?
            .addCategoryValue(MonitorField.MessageID, messageID)
            .addCategoryValue(MonitorField.ActionID, actionID)
            .addCategoryValue(MonitorField.RequestID, trace?.getRequestID())
            .setActionType(actionType)
            .tracing(trace)
            .flush()
    }
}
