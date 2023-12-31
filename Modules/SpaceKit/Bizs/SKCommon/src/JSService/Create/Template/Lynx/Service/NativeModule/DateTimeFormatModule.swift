//
//  DateTimeFormatModule.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/11/10.
//  


import Foundation
import Lynx
import LarkTimeFormatUtils
import SKFoundation
import BDXBridgeKit

class DateTimeFormatModule: NSObject, LynxModule {

    private var handlers: [String: ([String: Any]) -> String?]?
    
    required override init() {
        super.init()
        handlers = [
            "formatDate": formatDate(params:),
            "formatFullDate": formatFullDate(params:),
            "formatTime": formatTime(params:),
            "formatDateTime": formatDateTime(params:),
            "formatFullDateTime": formatFullDateTime(params:),
            "formatTimeRange": formatTimeRange(params:),
            "formatDateRange": formatDateRange(params:),
            "formatDateTimeRange": formatDateTimeRange(params:),
            "formatMonth": formatMonth(params:),
            "formatWeekDay": formatWeekDay(params:),
            "formatMeridiem": formatMeridiem(params:)
        ]
    }
    required init(param: Any) {}
    
    static var methodLookup: [String: String] {
        return [
            "call": NSStringFromSelector(#selector(call(name:params:callback:)))
        ]
    }
    
    static var name: String {
        return "DateTimeFormatModule"
    }
    
    @objc
    private func call(name: String, params: [String: Any], callback: LynxCallbackBlock) {
        guard let handler = handlers?[name], let timeStr = handler(params) else {
            callback([
                "code": BDXBridgeStatusCode.failed.rawValue,
                "message": "fail"
            ])
            return
        }
        
        callback([
            "code": BDXBridgeStatusCode.succeeded.rawValue,
            "message": "Success",
            "data": timeStr
        ])
    }
    
    private func formatDateTime(params: [String: Any]) -> String? {
        guard let timestamp = params["timestamp"] as? String, let ms = TimeInterval(timestamp) else {
            return nil
        }
        let date = Date(timeIntervalSince1970: ms / 1000)
        let options = Options.createOptions(from: params)
        return TimeFormatUtils.formatDateTime(from: date, with: options)
    }
    private func formatDate(params: [String: Any]) -> String? {
        guard let timestamp = params["timestamp"] as? String, let ms = TimeInterval(timestamp) else {
            return nil
        }
        let date = Date(timeIntervalSince1970: ms / 1000)
        let options = Options.createOptions(from: params)
        return TimeFormatUtils.formatDate(from: date, with: options)
    }
    private func formatFullDate(params: [String: Any]) -> String? {
        guard let timestamp = params["timestamp"] as? String, let ms = TimeInterval(timestamp) else {
            return nil
        }
        let date = Date(timeIntervalSince1970: ms / 1000)
        let options = Options.createOptions(from: params)
        return TimeFormatUtils.formatFullDate(from: date, with: options)
    }
    private func formatTime(params: [String: Any]) -> String? {
        guard let timestamp = params["timestamp"] as? String, let ms = TimeInterval(timestamp) else {
            return nil
        }
        let date = Date(timeIntervalSince1970: ms / 1000)
        let options = Options.createOptions(from: params)
        return TimeFormatUtils.formatTime(from: date, with: options)
    }
    private func formatFullDateTime(params: [String: Any]) -> String? {
        guard let timestamp = params["timestamp"] as? String, let ms = TimeInterval(timestamp) else {
            return nil
        }
        let date = Date(timeIntervalSince1970: ms / 1000)
        let options = Options.createOptions(from: params)
        return TimeFormatUtils.formatFullDateTime(from: date, with: options)
    }
    private func formatTimeRange(params: [String: Any]) -> String? {
        guard let startTimestamp = params["startTimestamp"] as? String,
              let startMS = TimeInterval(startTimestamp),
              let endTimestamp = params["endTimestamp"] as? String,
              let endMS = TimeInterval(endTimestamp) else {
            return nil
        }
        let startDate = Date(timeIntervalSince1970: startMS / 1000)
        let endDate = Date(timeIntervalSince1970: endMS / 1000)
        let options = Options.createOptions(from: params)
        return TimeFormatUtils.formatTimeRange(startFrom: startDate, endAt: endDate, with: options)
    }
    private func formatDateRange(params: [String: Any]) -> String? {
        guard let startTimestamp = params["startTimestamp"] as? String,
              let startMS = TimeInterval(startTimestamp),
              let endTimestamp = params["endTimestamp"] as? String,
              let endMS = TimeInterval(endTimestamp) else {
            return nil
        }
        let startDate = Date(timeIntervalSince1970: startMS / 1000)
        let endDate = Date(timeIntervalSince1970: endMS / 1000)
        let options = Options.createOptions(from: params)
        return TimeFormatUtils.formatDateRange(startFrom: startDate, endAt: endDate, with: options)
    }
    private func formatDateTimeRange(params: [String: Any]) -> String? {
        guard let startTimestamp = params["startTimestamp"] as? String,
              let startMS = TimeInterval(startTimestamp),
              let endTimestamp = params["endTimestamp"] as? String,
              let endMS = TimeInterval(endTimestamp) else {
            return nil
        }
        let startDate = Date(timeIntervalSince1970: startMS / 1000)
        let endDate = Date(timeIntervalSince1970: endMS / 1000)
        let options = Options.createOptions(from: params)
        return TimeFormatUtils.formatDateTimeRange(startFrom: startDate, endAt: endDate, with: options)
    }
    private func formatMonth(params: [String: Any]) -> String? {
        guard let timestamp = params["timestamp"] as? String, let ms = TimeInterval(timestamp) else {
            return nil
        }
        let date = Date(timeIntervalSince1970: ms)
        let options = Options.createOptions(from: params)
        return TimeFormatUtils.formatMonth(from: date, with: options)
    }
    private func formatWeekDay(params: [String: Any]) -> String? {
        guard let timestamp = params["timestamp"] as? String, let ms = TimeInterval(timestamp) else {
            return nil
        }
        let date = Date(timeIntervalSince1970: ms / 1000)
        let options = Options.createOptions(from: params)
        return TimeFormatUtils.formatWeekday(from: date, with: options)
    }
    private func formatMeridiem(params: [String: Any]) -> String? {
        guard let timestamp = params["timestamp"] as? String, let ms = TimeInterval(timestamp) else {
            return nil
        }
        let date = Date(timeIntervalSince1970: ms / 1000)
        let options = Options.createOptions(from: params)
        return TimeFormatUtils.formatMeridiem(from: date, with: options)
    }
    
//    struct Params: Codable {
//        let timestamp: String?
//        let startTimestamp: String?
//        let endTimestamp: String?
//        let timezone: String?
//        let displayPattern: Int?
//        let lengthType: Int?
//        let datePreciseness: Int?
//        let timePreciseness: Int?
//        let isShowTimezone: Bool
//        let isTwelveHour: Bool?
//        let isTruncatingZeroTail: Bool?
//        let isTimeOptimize: Bool?
//
//
//    }
}
extension Options {
    static func createOptions(from params: [String: Any]) -> Options {
        var options = TimeFormatUtils.defaultOptions
        fill(params: params, to: &options)
        return options
    }
    // cyclomatic_complexity:ignores_case_statements: true
    static func fill(params: Params, to options: inout Options) {
        if let timezoneStr = params["timezone"] as? String, let timezone = TimeZone(identifier: timezoneStr) {
            options.timeZone = timezone
        }
        if let displayPattern = params["displayPattern"] as? Int, let dateStatusType = Options.DateStatusType(intValue: displayPattern) {
            options.dateStatusType = dateStatusType
        }
        if let lengthType = params["lengthType"] as? Int, let timeFormatType = Options.TimeFormatType(intValue: lengthType) {
            options.timeFormatType = timeFormatType
        }
        if let datePreciseness = params["datePreciseness"] as? Int, let datePrecisionType = Options.DatePrecisionType(intValue: datePreciseness) {
            options.datePrecisionType = datePrecisionType
        }
        if let timePreciseness = params["timePreciseness"] as? Int, let timePrecisionType = Options.TimePrecisionType(intValue: timePreciseness) {
            options.timePrecisionType = timePrecisionType
        }
        if let isShowTimezone = params["isShowTimezone"] as? Bool {
            options.shouldShowGMT = isShowTimezone
        }
        if let isTwelveHour = params["isTwelveHour"] as? Bool {
            options.is12HourStyle = isTwelveHour
        }
        if let isTruncatingZeroTail = params["isTruncatingZeroTail"] as? Bool {
            options.shouldRemoveTrailingZeros = isTruncatingZeroTail
        }
    }
}
extension Options.DateStatusType {
    init?(intValue: Int) {
        switch intValue {
        case 0: self = .absolute
        case 1: self = .relative
        default: return nil
        }
    }
}
extension Options.TimeFormatType {
    init?(intValue: Int) {
        switch intValue {
        case 0: self = .long
        case 1: self = .short
        case 2: self = .min
        default: return nil
        }
    }
}
extension Options.DatePrecisionType {
    init?(intValue: Int) {
        switch intValue {
        case 0: self = .day
        case 1: self = .month
        default: return nil
        }
    }
}
extension Options.TimePrecisionType {
    init?(intValue: Int) {
        switch intValue {
        case 0: self = .hour
        case 1: self = .minute
        case 2: self = .second
        default: return nil
        }
    }
}
