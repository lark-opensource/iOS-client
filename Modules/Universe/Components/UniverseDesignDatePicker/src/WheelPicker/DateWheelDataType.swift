//
//  UDDatePickerDateType.swift
//  UniverseDesignDatePicker
//
//  Created by LiangHongbin on 2020/11/26.
//

import Foundation
import EventKit

/// 时间滚轮类型，关联数据
enum DateWheelDataType {
    case dayHourMinute(initDateTime: DayHourMinuteData,
                       start: DayHourMinuteData? = nil,
                       end: DayHourMinuteData? = nil)

    case hourMinute(initTime: HourMinuteData)

    case hourMinuteCenter(initTime: HourMinuteData)

    case year(initDate: YearMonthDayData,
                  start: YearMonthDayData? = nil,
                  end: YearMonthDayData? = nil)

    case yearMonthDay(initDate: YearMonthDayData,
                      start: YearMonthDayData? = nil,
                      end: YearMonthDayData? = nil)

    case yearMonthDayWeek(initData: YearMonthDayData,
                          start: YearMonthDayData? = nil,
                          end: YearMonthDayData? = nil)

    case yearMonthDayHour(initDateTime: DayHourMinuteData,
                          start: DayHourMinuteData? = nil,
                          end: DayHourMinuteData? = nil)
}

enum ColumnType {
    case minute // 分钟
    case hour12 // 小时
    case hour24
    case ampm // 上午下午
    case month // 月
    case year // 年
    case day // 日
    case week // 周
    case monthDayWeek // 月日星期 e.g.: 11月14日 周六
    case dayWeek // 日周 e.g.:  31日 周日
}

/// 年月日类型
struct YearMonthDayData {
    private(set) var year: Int
    private(set) var month: Int
    private(set) var day: Int
}
/// 时分类型
struct HourMinuteData {
    private(set) var hour: Int
    private(set) var min: Int
}
/// 日时分类型
struct DayHourMinuteData {
    private(set) var year: Int
    private(set) var month: Int
    private(set) var day: Int
    private(set) var hour: Int
    private(set) var min: Int
}
