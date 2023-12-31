//
//  Options.swift
//  LarkTimeFormatUtils
//
//  Created by Miao Cai on 2020/9/7.
//

import Foundation
import LarkLocalizations
/// Time Format Options
/// Interface design document: https://bytedance.feishu.cn/docs/doccnNM4RKsOadEtm5TMkIatUQf
/// Guidebook: https://bytedance.feishu.cn/wiki/wikcncomscp8CYMBjCfFG3HVIMf
public struct Options {
    /// 时区
    public var timeZone: TimeZone
    /// 是否以 24 或 12 小时制显示
    public var is12HourStyle: Bool
    /// 是否信息 GMT 显示
    public var shouldShowGMT: Bool
    /// 是否清楚时间格式中不必要的 0
    public var shouldRemoveTrailingZeros: Bool
    /// 时间格式类型，分为三类: min/short/long
    public var timeFormatType: TimeFormatType
    /// 日期状态类型，分为两类: absolue/relative
    public var dateStatusType: DateStatusType
    /// 时间精度类型，分为三类: second/minute/hour
    public var timePrecisionType: TimePrecisionType
    /// 日期精度类型，分为两类: day/month
    public var datePrecisionType: DatePrecisionType
    /// 默认为当前语言
    public var lang: Lang?
    public var relativeDate: Date?

    /// Initializer of struct Options.
    ///
    /// ```
    /// // Can be simply used as
    /// let defaultOptions = Options()
    /// // Or manually configure required option:
    /// let customOptions = Options(
    ///    timeZone: TimeZone(identifier: "Asia/Shanghai")!,
    ///    is12HourStyle: true,
    ///    shouldShowGMT: true
    /// )
    /// ```
    /// - Parameter timeZone: An timezone identifier that could represent geopolitical regions.
    /// - Parameter is12HourStyle: To define whether to use 12-hour time or 24-hour time. Default is false.
    /// - Parameter shouldShowGMT: To show the specific GMT information. Default is false.
    /// - Parameter timeFormatType: To define the type of the time format. Default is long type.
    /// - Parameter timePrecisionType: To define the type of time precision. Default is hour type.
    /// - Parameter datePrecisionType: To define the type of date precision. Default is month type.
    /// - Parameter dateStatusType: To define the status of date. e.g., absolute or relative. Default is absolute type.
    /// - Parameter shouldRemoveTrailingZeros: To simplify the time by truncating tail with zero. Default is false.
    /// - Parameter Lang: appoint formatter language, defaule is current language
    public init(
        timeZone: TimeZone = TimeZone.current,
        is12HourStyle: Bool = false,
        shouldShowGMT: Bool = false,
        timeFormatType: TimeFormatType = .long,
        timePrecisionType: TimePrecisionType = .hour,
        datePrecisionType: DatePrecisionType = .month,
        dateStatusType: DateStatusType = .absolute,
        shouldRemoveTrailingZeros: Bool = false,
        lang: Lang? = nil
    ) {
        self.timeZone = timeZone
        self.is12HourStyle = is12HourStyle
        self.shouldShowGMT = shouldShowGMT
        self.timeFormatType = timeFormatType
        self.timePrecisionType = timePrecisionType
        self.datePrecisionType = datePrecisionType
        self.dateStatusType = dateStatusType
        self.shouldRemoveTrailingZeros = shouldRemoveTrailingZeros
        self.lang = lang
    }

    /// 兼容旧版本，后面需要删除
    public init(
        timeZone: TimeZone = TimeZone.current,
        is12HourStyle: Bool = false,
        shouldShowGMT: Bool = false,
        timeFormatType: TimeFormatType = .long,
        timePrecisionType: TimePrecisionType = .hour,
        datePrecisionType: DatePrecisionType = .month,
        dateStatusType: DateStatusType = .absolute,
        shouldRemoveTrailingZeros: Bool = false
    ) {
        self.init(
            timeZone: timeZone,
            is12HourStyle: is12HourStyle,
            shouldShowGMT: shouldShowGMT,
            timeFormatType: timeFormatType,
            timePrecisionType: timePrecisionType,
            datePrecisionType: datePrecisionType,
            dateStatusType: dateStatusType,
            shouldRemoveTrailingZeros: shouldRemoveTrailingZeros,
            lang: nil
        )
    }
}

extension Options {

    /// 时间格式类型，分为三类: min/short/long
    public enum TimeFormatType {
        case min, short, long
    }

    /// 时间精度类型，分为三类: second/minute/hour
    public enum TimePrecisionType {
        case second, minute, hour
    }

    /// 日期精度类型，分为两类: day/month
    public enum DatePrecisionType {
        case day, month
    }

    /// 日期状态类型，分为两类: absolue/relative
    public enum DateStatusType {
        // 引入一个日期状态的概念, 仅针对相对星期的表达方式:
        // 在最近三天, relative 类型支持翻译成昨天/今天/明天
        // 而 absolute 类型始终翻译成星期
        case absolute, relative
    }
}
