//
//  SlaMonitor.swift
//  Calendar
//
//  Created by Rico on 2023/4/11.
//

// 稳定性埋点建设
// https://bytedance.feishu.cn/wiki/E0kiwAVJziht4pk1p73c9a6Dn6h?table=tbll2tn99EDgkyTY&view=vewgvgO7zV&sheet=a4fd84

import Foundation
import LKCommonsTracker
import LKCommonsLogging
import LarkRustClient
import RxSwift

let ClientSlaErrorStatus: Int32 = 1000
let ClientSlaErrorCodeNotDefined: Int32 = -4001
let ClientSlaErrorStatusNotDefined: Int32 = -4002

// error_code
let saveEventSwitchCalendarFailed: Int32 = 100200
let saveEventNotSyncAttendee: Int32 = 100201

let eventDetailSelfNil: Int32 = 100300
let eventDetailCouldNotGetCalendar: Int32 = 100301
let eventDetailServerPBNotExist: Int32 = 100302
let eventDetailCouldNotGetEvent: Int32 = 100303
let eventDetailChatMeetingsEmpty: Int32 = 100304

struct SlaDefine {
    enum EventName: String {
        case CalendarView = "cal_sla_calendar_view_instance_dev"
        case EventDetail = "cal_sla_event_detail_dev"
        case FreeBusyInstance = "cal_sla_free_busy_instance_dev"
        case SaveEvent = "cal_sla_save_event_dev"
        case EventAddMeetingRoom = "cal_sla_book_meeting_room_dev"
        case MeetingRoomViewAddEvent = "cal_sla_meeting_room_view_dev"
        case ShareEventDetail = "cal_sla_event_share_dev"
    }
    
    enum Result {
        case success
        // 这里的error会尝试转换成SlaError，尝试转换不出数据会给一个undefined的error
        case failure(_ error: Error)
    }
}

struct SlaMonitor {
    
    private static let logger = Logger.log(SlaMonitor.self, category: "calendar.SlaMonitor")
    
    static func traceSuccess(_ eventName: SlaDefine.EventName,
                             action: String? = nil,
                             source: String? = nil,
                             additionalParam: [String: Any]? = nil) {
        trace(eventName,
              result: .success,
              action: action,
              source: source,
              additionalParam: additionalParam)
    }
    
    static func traceFailure(_ eventName: SlaDefine.EventName,
                             error: Error,
                             action: String? = nil,
                             source: String? = nil,
                             additionalParam: [String: Any]? = nil) {
        trace(eventName,
              result: .failure(error),
              action: action,
              source: source,
              additionalParam: additionalParam)
    }
    
    static private func trace(_ eventName: SlaDefine.EventName,
                              result: SlaDefine.Result,
                              action: String?,
                              source: String?,
                              additionalParam: [String: Any]?) {
        
        var params = additionalParam ?? [:]
        
        switch result {
        case .success:
            // 成功参数拼装
            params["is_success"] = 1
        case .failure(let error):
            // 失败参数拼装
            let slaError = error.toSlaMonitorError()
            params["is_success"] = 0
            params["error_code"] = slaError.errorCode
            params["error_status"] = slaError.errorStatus
            params["error_msg"] = slaError.errorMsg
            params["log_id"] = slaError.logId
        }
        
        if let action = action {
            params["action"] = action
        }
        if let source = source {
            params["source"] = source
        }
        
        logger.info("SlaMonitor: eventId: \(eventName.rawValue), params: \(params)")
        
        #if !LARK_NO_DEBUG
        Tracker.post(TeaEvent(eventName.rawValue, category: nil, params: params))
        #endif
    }
}


// MARK: - SlaMonitorError
// SlaMonitorError Error转换处理 各场景兼容

struct SlaMonitorError: Error {
    let errorCode: Int32
    let errorStatus: Int32
    let errorMsg: String
    let logId: String
}

// 转换出一个确定的Error
protocol SlaMonitorErrorConvertible {
    func convertToSlaMonitorError() -> SlaMonitorError
}

// 可空的error，空的话不会上报错误埋点，适用于业务场景定义的某些符合预期的错误
protocol MaybeSlaError {
    func tryExtractSlaError() -> SlaMonitorError?
}

extension SlaMonitorError: SlaMonitorErrorConvertible {
    func convertToSlaMonitorError() -> SlaMonitorError {
        self
    }
}

/// 编辑页错误定义 -> SlaError
extension EventEditViewModel.SaveTerminal: MaybeSlaError {

    func tryExtractSlaError() -> SlaMonitorError? {
        switch self {
        case let .failedToSave(sdkError: error): return error.toSlaMonitorError()
        case .notSyncAttendee: return .init(errorCode: saveEventNotSyncAttendee, errorStatus: ClientSlaErrorStatus, errorMsg: "not sync Attendee", logId: "")
        case .switchCalendarFailed: return .init(errorCode: saveEventSwitchCalendarFailed, errorStatus: ClientSlaErrorStatus, errorMsg: "switch calendar failed", logId: "")
        default: return nil
        }
    }
}

/// 详情页错误定义 -> SlaError
extension EventDetailMetaError: MaybeSlaError {
    
    func tryExtractSlaError() -> SlaMonitorError? {
        
        // apiError 直接上报
        if case let .apiError(error) = self {
            return error.toSlaMonitorError()
        }
        
        if let viewStatusError = toViewStatusError(),
           viewStatusError.canRetry == true {
            // 能被重试的错误，都算系统预期的失败
            return nil
        }
        
        switch self {
        case .unknown: return .init(errorCode: ClientSlaErrorCodeNotDefined, errorStatus: ClientSlaErrorStatus, errorMsg: "", logId: "")
        case .chatMeetingsEmpty: return .init(errorCode: eventDetailChatMeetingsEmpty, errorStatus: ClientSlaErrorStatus, errorMsg: "no chat meeting", logId: "")
        case .couldNotGetCalendar: return .init(errorCode: eventDetailCouldNotGetCalendar, errorStatus: ClientSlaErrorStatus, errorMsg: "could not get calendar", logId: "")
        case .couldNotGetEvent: return .init(errorCode: eventDetailCouldNotGetEvent, errorStatus: ClientSlaErrorStatus, errorMsg: "could not get event", logId: "")
        case .selfNil: return .init(errorCode: eventDetailSelfNil, errorStatus: ClientSlaErrorStatus, errorMsg: "self nil", logId: "")
        case .serverPBNotExist: return .init(errorCode: eventDetailServerPBNotExist, errorStatus: ClientSlaErrorStatus, errorMsg: "server pb not exist", logId: "")
        default: return nil
        }
    }
}

extension RCError: SlaMonitorErrorConvertible {
    
    func convertToSlaMonitorError() -> SlaMonitorError {
        
        var errorCode: Int32 = ClientSlaErrorCodeNotDefined
        var errorStatus: Int32 = ClientSlaErrorStatus
        // msg直接取rcError包装过后的
        let errorMsg = self.description
        var logId = ""
        
        if case let .businessFailure(businessErrorInfo) = self {
            // sdk包装的业务error （包含服务端）
            errorCode = businessErrorInfo.errorCode
            errorStatus = businessErrorInfo.errorStatus
            logId = businessErrorInfo.ttLogId ?? ""
        }
        
        return .init(errorCode: errorCode, errorStatus: errorStatus, errorMsg: errorMsg, logId: logId)
    }
    
}

// 尝试转换出SlaError
// SlaMonitorErrorConvertible > undefined error
extension Error {
    
    func toSlaMonitorError() -> SlaMonitorError {
        var errorCode: Int32 = ClientSlaErrorCodeNotDefined
        var errorStatus: Int32 = ClientSlaErrorStatusNotDefined
        var errorMsg = ""
        var logId = ""
        
        if let convertible = self as? SlaMonitorErrorConvertible {
            // 确定的error转换
            return convertible.convertToSlaMonitorError()
        }
        
        // 所有没有定义转换的Error的逻辑走到这里
        return .init(errorCode: errorCode, errorStatus: errorStatus, errorMsg: errorMsg, logId: logId)
    
    }
}

// MARK: Utils

/// 注意：直接用信号中的 Error 当做 SlaMonitor 的 Error
extension ObservableType {
    
    func collectSlaInfo(_ eventName: SlaDefine.EventName,
                        action: String? = nil,
                        source: String? = nil,
                        additionalParam: [String: Any]? = nil) -> Observable<Element> {
        self.do { _ in
            SlaMonitor.traceSuccess(eventName,
                                    action: action,
                                    source: source,
                                    additionalParam: additionalParam)
        } onError: { error in
            if let maybeSlaError = error as? MaybeSlaError {
                if let slaError = maybeSlaError.tryExtractSlaError() {
                    SlaMonitor.traceFailure(eventName,
                                            error: slaError,
                                            action: action,
                                            source: source,
                                            additionalParam: additionalParam)
                } else {
                    return
                }
            }
            else {
                SlaMonitor.traceFailure(eventName,
                                        error: error,
                                        action: action,
                                        source: source,
                                        additionalParam: additionalParam)
            }
        }
    }
}
