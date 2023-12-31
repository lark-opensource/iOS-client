//
//  DateContentModel.swift
//  UniverseDesignDatePicker
//
//  Created by LiangHongbin on 2020/11/22.
//
import UIKit
import Foundation
import LarkTimeFormatUtils
import LarkLocalizations

typealias JulianDay = Int
typealias JulianDayRange = Range<Int>
// textAlignment 默认居中
struct ColumnConfig: ExpressibleByFloatLiteral {
    init(floatLiteral value: Double) {
        width = value
    }
    var width: Double = 1
    var textAlignment: NSTextAlignment = .center
}
// DatePicker 数据
typealias ContentArray = [ColumnContent]

struct ColumnContent {
    internal init(_ type: ColumnType, _ content: [RowContentGetter], _ index: Int) {
        self.type = type
        self.content = content
        self.initialIndex = index
        // 初值无意义
        self.selectedIndex = -1
    }

    let type: ColumnType
    var content: [RowContentGetter]
    var initialIndex: Int
    var selectedIndex: Int
}

protocol RowContentGetter {
    func displayString() -> String
}

struct NormalRowModel: RowContentGetter {
    private let rowValue: String
    init(_ rowValue: String) {
        self.rowValue = rowValue
    }

    func displayString() -> String {
        return rowValue
    }
}

struct MonthDayWeekRowModel: RowContentGetter {
    private let rowValue: String

    init( _ rowValue: String) {
        self.rowValue = rowValue
    }

    // 动态计算，这个文案内容多，占内存大；这样可以动态拼装文案
    func displayString() -> String {
        let customOptions = Options(timeFormatType: .short,
                                    datePrecisionType: .day)
        let date = JulianDayUtil.date(from: JulianDay(self.rowValue) ?? -1)
        let labelText = TimeFormatUtils.formatDate(from: date, with: customOptions) + " " +
            TimeFormatUtils.formatWeekday(from: date, with: customOptions)
        return labelText
    }
}

protocol DateWheelContentModelType {
    var data: ContentArray { get }
    var dataType: DateWheelDataType { get }
    var uiConfig: [ColumnConfig] { get }
    var offset: Int { get }
    var startDay: JulianDay { get }
    var timeZone: TimeZone { get }
    var minDate: Date { get }
    var maxDate: Date { get }
    var minInterval: Int { get }
    func updateYearMonthDay(changedColumn: Int, selectedIndex: Int, columnType: ColumnType)
    func updateSelectedIndex(in column: Int, selectedIndex: Int)
}

class DateWheelContentModel: DateWheelContentModelType {
    var uiConfig: [ColumnConfig] = []
    var data: ContentArray = []
    var dataType: DateWheelDataType
    var offset: Int
    var startDay: JulianDay = -1
    var timeZone: TimeZone
    var minDate: Date
    var maxDate: Date
    var minInterval: Int

    var mins: [RowContentGetter] {
        let mins = stride(from: 0, to: 60, by: minInterval).map {
            NormalRowModel(rowString(with: $0, columnType: .minute))
        }
        return mins
    }

    var hours12: [RowContentGetter] {
        let hours = (1..<13).map {
            NormalRowModel(rowString(with: $0, columnType: .hour12))
        }
        return hours
    }

    var hours24: [RowContentGetter] {
        let hours = (0..<24).map {
            NormalRowModel(rowString(with: $0, columnType: .hour24))
        }
        return hours
    }

    var ampm: [RowContentGetter] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: TimeFormatUtils.languageIdentifier)
        formatter.dateFormat = ""
        let amValue = formatter.amSymbol ?? "AM"
        let pmValue = formatter.pmSymbol ?? "PM"
        var array = [amValue, pmValue]
        for _ in 0..<offset {
            array.insert("", at: 0)
            array.append("")
        }
        return array.map { NormalRowModel($0) }
    }

    private func yearModel(yearArray: [Int]) -> [RowContentGetter] {
        let yearModel = yearArray.map {
            NormalRowModel(rowString(with: $0, columnType: .year))
        }
        return yearModel
    }

    private func monthModel(monthArray: [Int]) -> [RowContentGetter] {
        let monthModel = monthArray.map {
            NormalRowModel(rowString(with: $0, columnType: .month))
        }
        return monthModel
    }

    // 月日周 - 日 - 日周
    private func dayModel(dayArray: [Int] = [],
                          initJulianday: JulianDay = -1 ,
                          dayType: ColumnType) -> [RowContentGetter] {
        let days: [Int]
        if dayArray.isEmpty {
            if initJulianday != -1 {
                days = Array(JulianDayUtil.julianDayRange(inSameMonthAs: initJulianday))
            } else {
                assertionFailure("Missing parameter")
                return []
            }
        } else { days = dayArray }

        let dayModel: [RowContentGetter]
        if dayType == .monthDayWeek {
            dayModel = days.map {
                MonthDayWeekRowModel(rowString(with: $0, columnType: dayType))
            }
        } else {
            dayModel = days.map {
                NormalRowModel(rowString(with: $0, columnType: dayType))
            }
        }
        return dayModel
    }

    init(type: DateWheelDataType, rows: Int,
         timeZone: TimeZone,
         minDate: Date, maxDate: Date,
         config: UDWheelsStyleConfig) {
        dataType = type
        offset = rows / 2
        self.minDate = minDate
        self.maxDate = maxDate
        self.timeZone = timeZone
        self.minInterval = config.minInterval
        // interval 校验
        if 60 % config.minInterval != 0 {
            assertionFailure("分钟的时间间隔应为 60 的因数，默认取 5")
            minInterval = 5
        }
        switch dataType {
        // 日历编辑页&people-tri hour min e.g.：11月14日 周六 - 04 - 00  or Nov 18 Wed 05 00
        case .dayHourMinute(let initDateTime, let start, let end):
            data = contentArrayOfDayHourMin(selectedTime: initDateTime,
                                            minTime: start, maxTime: end,
                                            is12Hour: config.is12Hour)
            if case .dayHourMinute(let twelveHourScale, let twentyFourHourScale) = config.mode {
                if config.is12Hour {
                    uiConfig = twelveHourScale.map( {ColumnConfig(floatLiteral: $0)})
                } else {
                    uiConfig = twentyFourHourScale.map( {ColumnConfig(floatLiteral: $0)})
                }
            } else {
                if config.is12Hour {
                    uiConfig = [3.0, 1.0, 1.0, 1.0]
                } else {
                    uiConfig = [2.0, 1.0, 1.0]
                }
            }
        // 日历我的工作时间 e.g.: 上午 - 11 - 25
        case .hourMinute(let initTime):
            if config.is12Hour {
                data = contentArrayOfHourMin(selectedTime: initTime, is12Hour: true)
                uiConfig = [1.0, 1.0, 1.0]
            } else {
                data = contentArrayOfHourMin(selectedTime: initTime, is12Hour: false)
                uiConfig = [1.0, 1.0]
            }
        // TodoTask  e.g.: 上午 - 11 - 25
        case .hourMinuteCenter(let initTime):
            if config.is12Hour {
                data = contentArrayOfHourMin(selectedTime: initTime, is12Hour: true)
                uiConfig = [135.0, 51.5, 135.0]
                uiConfig[0].textAlignment = .right
                uiConfig[1].textAlignment = .center
                uiConfig[2].textAlignment = .left
            } else {
                data = contentArrayOfHourMin(selectedTime: initTime, is12Hour: false)
                uiConfig = [1.0, 1.0]
                uiConfig[0].textAlignment = .right
                uiConfig[1].textAlignment = .left
            }
        // people休假 pending e.g.：2018年 - 3月 - 24日
        case .yearMonthDay(let initDate, let start, let end):
            data = contentArrayOfYearMonDay(selectedDate: initDate, minDate: start, maxDate: end, dayWithWeek: false)
            uiConfig = [1.0, 1.0, 1.0]

        // people pending e.g.：2020年 - 10月 - 31日 周日
        // 日历重复性规则截止日期 e.g.：2020年 - 10月 - 31日(周日)
        case .yearMonthDayWeek(let initDate, let start, let end):
            data = contentArrayOfYearMonDay(selectedDate: initDate, minDate: start, maxDate: end, dayWithWeek: true)
            uiConfig = [1.0, 1.0, 1.0]
        // ByteMoments e.g.: 2018年 - 3月 - 24日 - 16
        case .yearMonthDayHour(let initDateTime, let start, let end):
            data = contentArrayOfYearMonDayHour(selectedTime: initDateTime,
                                                minTime: start,
                                                maxTime: end)
            uiConfig = [1.0, 1.0, 1.0, 1.0]
        // 红包 e.g.: 2018年
        case .year(let initDate, let start, let end):
            guard let yearContent = contentArrayOfYearMonDay(selectedDate: initDate,
                                                             minDate: start,
                                                             maxDate: end,
                                                             dayWithWeek: false).first else {
                assertionFailure("year data error")
                return
            }
            data = [yearContent]
            uiConfig = [1.0]
        }
    }

    private func contentArrayOfDayHourMin(selectedTime: DayHourMinuteData,
                                          minTime: DayHourMinuteData?,
                                          maxTime: DayHourMinuteData?,
                                          is12Hour: Bool) -> ContentArray {
        let julianRange = DateWheelContentModel.dateTimePreprocess(minDate: minTime, maxDate: maxTime)
        let initJulian = JulianDayUtil.julianDay(fromYear: selectedTime.year,
                                                 month: selectedTime.month,
                                                 day: selectedTime.day)
        guard julianRange.contains(initJulian) else {
            assertionFailure("初始数据不在起止范围内")
            return []
        }

        guard let firstJulianDay = julianRange.first else {
            assertionFailure("范围为空，range.first解包失败")
            return []
        }

        startDay = firstJulianDay
        var dateContent: ContentArray = []
        var rowModels = dayModel(dayArray: Array(julianRange), dayType: .monthDayWeek)
        // 顶部/底部 留白
        (0..<offset).forEach {
            rowModels.insert(NormalRowModel(""), at: $0)
            rowModels.append(NormalRowModel(""))
        }

        let columnOfMonthDayWeek = ColumnContent(.monthDayWeek, rowModels, initJulian - firstJulianDay + offset)
        let columnOfMinute = ColumnContent(.minute, mins, selectedTime.min / minInterval)
        dateContent.append(columnOfMonthDayWeek)
        dateContent.append(columnOfMinute)

        if is12Hour {
            let ampmIndex = offset + (selectedTime.hour > 11 ? 1 : 0)
            let columnOfHour = ColumnContent(.hour12, hours12, selectedTime.hour - 1)
            dateContent.insert(columnOfHour, at: 1)
            let isAheadOfTime = TimeFormatUtils.languagesListForAheadMeridiemIndicator
                .contains(LanguageManager.currentLanguage)
            let columnOfAmpm = ColumnContent(.ampm, ampm, ampmIndex)
            if isAheadOfTime {
                dateContent.insert(columnOfAmpm, at: 1)
            } else {
                dateContent.append(columnOfAmpm)
            }
        } else {
            let columnOfHour = ColumnContent(.hour24, hours24, selectedTime.hour)
            dateContent.insert(columnOfHour, at: 1)
        }
        return dateContent
    }

    // 对于UDDatePickerView来讲，滚动到的位置就是数组下标
    private func contentArrayOfHourMin(selectedTime: HourMinuteData, is12Hour: Bool) -> ContentArray {
        var dateContent: ContentArray = []
        let aheadOfTime = TimeFormatUtils.languagesListForAheadMeridiemIndicator
            .contains(LanguageManager.currentLanguage)
        dateContent.append(ColumnContent(.minute, mins, selectedTime.min / minInterval))
        if is12Hour {
            let ampmIndex = offset + (selectedTime.hour > 11 ? 1 : 0)
            let columnOfHour = ColumnContent(.hour12, hours12, selectedTime.hour - 1)
            dateContent.insert(columnOfHour, at: 0)
            let columnOfAmpm = ColumnContent(.ampm, ampm, ampmIndex)
            if aheadOfTime {
                dateContent.insert(columnOfAmpm, at: 0)
            } else {
                dateContent.append(columnOfAmpm)
            }
        } else {
            let columnOfHour = ColumnContent(.hour24, hours24, selectedTime.hour)
            dateContent.insert(columnOfHour, at: 0)
        }
        return dateContent
    }

    private func contentArrayOfYearMonDay(selectedDate: YearMonthDayData,
                                          minDate: YearMonthDayData?,
                                          maxDate: YearMonthDayData?,
                                          dayWithWeek: Bool) -> ContentArray {
        let julianRange = DateWheelContentModel.datePreprocess(minDate: minDate, maxDate: maxDate)
        let initJulian = JulianDayUtil.julianDay(fromYear: selectedDate.year,
                                                 month: selectedDate.month,
                                                 day: selectedDate.day)
        guard julianRange.contains(initJulian) else {
            assertionFailure("初始数据不在起止范围内")
            return []
        }

        guard let firstJulianDay = julianRange.first, let lastJulianDay = julianRange.last else {
            assertionFailure("起止时间有误")
            return []
        }

        startDay = firstJulianDay
        let startYMD = JulianDayUtil.yearMonthDay(from: firstJulianDay)
        let endYMD = JulianDayUtil.yearMonthDay(from: lastJulianDay)
        var dateContent: ContentArray = []
        // 年月日类型特殊，暂时只支持到年这个维度的范围约束
        let year = startYMD.year...endYMD.year
        let month = 1...12

        var arrayYear = Array(year)
        for _ in 0..<offset {
            arrayYear.insert(0, at: 0)
            arrayYear.append(0)
        }
        let columnOfYear = ColumnContent(.year, yearModel(yearArray: arrayYear),
                                         selectedDate.year - startYMD.year + offset)
        let columnOfMonth = ColumnContent(.month, monthModel(monthArray: Array(month)),
                                          selectedDate.month - 1)
        // 传入 dayType 不同，people出差和休假
        let dayType: ColumnType = dayWithWeek ? .dayWeek : .day
        let columnOfDay = ColumnContent(dayType,
                                        dayModel(initJulianday: initJulian, dayType: dayType),
                                        selectedDate.day - 1)
        dateContent.append(columnOfYear)
        dateContent.append(columnOfMonth)
        dateContent.append(columnOfDay)
        return dateContent
    }

    private func contentArrayOfYearMonDayHour(selectedTime: DayHourMinuteData,
                                              minTime: DayHourMinuteData?,
                                              maxTime: DayHourMinuteData?) -> ContentArray {
        let julianRange = DateWheelContentModel.dateTimePreprocess(minDate: minTime, maxDate: maxTime)
        let initJulian = JulianDayUtil.julianDay(fromYear: selectedTime.year,
                                                 month: selectedTime.month,
                                                 day: selectedTime.day)
        guard julianRange.contains(initJulian) else {
            assertionFailure("初始数据不在起止范围内")
            return []
        }

        guard let firstJulianDay = julianRange.first, let lastJulianDay = julianRange.last else {
            assertionFailure("范围为空，range.first解包失败")
            return []
        }

        startDay = firstJulianDay
        var dateContent: ContentArray = []
        let startYMD = JulianDayUtil.yearMonthDay(from: firstJulianDay)
        let endYMD = JulianDayUtil.yearMonthDay(from: lastJulianDay)
        let selected = YearMonthDayData(year: selectedTime.year, month: selectedTime.month, day: selectedTime.day)
        let min = YearMonthDayData(year: startYMD.year, month: startYMD.month, day: startYMD.day)
        let max = YearMonthDayData(year: endYMD.year, month: endYMD.month, day: endYMD.day)
        dateContent = contentArrayOfYearMonDay(selectedDate: selected,
                                               minDate: min,
                                               maxDate: max,
                                               dayWithWeek: false)
        let columnOfHour = ColumnContent(.hour24, hours24, selectedTime.hour)
        dateContent.append(columnOfHour)
        return dateContent
    }

    // update()数据层面的，目前只有 yearMonthDay 类型需要
    func updateYearMonthDay(changedColumn: Int, selectedIndex: Int, columnType: ColumnType) {
        let minYearMonthDay = JulianDayUtil.yearMonthDay(from: startDay)
        guard data.count <= 4 else {
            assertionFailure("data 包含列数错误")
            return
        }
        let oldYear = data[0].selectedIndex + minYearMonthDay.year // 因为有前边的空白，不用加 offset
        let oldMonth = (data[1].selectedIndex + offset) % 12 + minYearMonthDay.month
        let oldDay = (data[2].selectedIndex + offset) % data[2].content.count + 1
        let newYear: Int
        let newMonth: Int
        if changedColumn == 0 {
            newYear = selectedIndex + minYearMonthDay.year
            newMonth = oldMonth
        } else {
            newYear = oldYear
            newMonth = (selectedIndex + offset) % 12 + minYearMonthDay.month
        }

        let firstMonthDay = JulianDayUtil.julianDay(fromYear: newYear, month: newMonth, day: 1)
        let maxNewDay = JulianDayUtil.julianDayRange(inSameMonthAs: firstMonthDay).count
        let newDay = oldDay < maxNewDay ? oldDay : maxNewDay
        let newJulianDay = JulianDayUtil.julianDay(fromYear: newYear, month: newMonth, day: newDay)

        data[2].content = dayModel(initJulianday: newJulianDay, dayType: columnType)
        data[2].initialIndex = newDay - 1
    }

    func updateSelectedIndex(in column: Int, selectedIndex: Int) {
        guard column < data.count else {
            assertionFailure("column index out range")
            return
        }
        data[column].selectedIndex = selectedIndex
    }

    private func rowString(with source: Int, columnType: ColumnType) -> String {
        switch columnType {
        case .minute, .hour12, .hour24:
            return String(format: "%02d", source)
        case .year:
            return source != 0 ? BundleI18n.UniverseDesignDatePicker.Calendar_StandardTime_YearOnlyString(source) : ""
        case .month:
            return TimeFormatUtils.monthAbbrString(month: source)
        case .week:
            return TimeFormatUtils.weekdayShortString(weekday: source)
        case .monthDayWeek:
            return String(source)
        case .dayWeek:
            let coustomOptions = Options(timeZone: timeZone, timeFormatType: .short)
            let date = JulianDayUtil.date(from: source, in: timeZone)
            let weekdayString = TimeFormatUtils.formatWeekday(from: date, with: coustomOptions)
            let day = JulianDayUtil.yearMonthDay(from: source).day
            return "\(BundleI18n.UniverseDesignDatePicker.Calendar_StandardTime_DayOnlyString(day)) (\(weekdayString))"
        case .day:
            let day = JulianDayUtil.yearMonthDay(from: source).day
            return "\(BundleI18n.UniverseDesignDatePicker.Calendar_StandardTime_DayOnlyString(day))"
        default:
            return ""
        }
    }

    static func datePreprocess(minDate: YearMonthDayData?,
                               maxDate: YearMonthDayData?) -> JulianDayRange {
        let min = minDate ?? YearMonthDayData(year: 1900, month: 01, day: 01)
        let max = maxDate ?? YearMonthDayData(year: 2100, month: 12, day: 31)
        let minJulian = JulianDayUtil.julianDay(fromYear: min.year, month: min.month, day: min.day)
        let maxJulian = JulianDayUtil.julianDay(fromYear: max.year, month: max.month, day: max.day)
        if minJulian > maxJulian {
            assertionFailure("日期设置不合规")
            return 0..<1
        } else {
            let min = JulianDayUtil.julianDay(fromYear: min.year, month: 1, day: 1)
            return min..<maxJulian + 1
        }
    }

    static func dateTimePreprocess(minDate: DayHourMinuteData?,
                                   maxDate: DayHourMinuteData?) -> JulianDayRange {
        // 默认 1900-01-01 00：00 参数校验
        let min = minDate ?? DayHourMinuteData(year: 1900, month: 01, day: 01, hour: 00, min: 00)
        // 默认 2100-12-31 23：55 参数校验
        let max = maxDate ?? DayHourMinuteData(year: 2100, month: 12, day: 31, hour: 23, min: 55)

        let minJulian = JulianDayUtil.julianDay(fromYear: min.year, month: min.month, day: min.day)
        let maxJulian = JulianDayUtil.julianDay(fromYear: max.year, month: max.month, day: max.day)

        if minJulian < maxJulian {
            return minJulian..<maxJulian + 1
        } else if minJulian == maxJulian {
            let minMinute = min.hour * 60 + min.min
            let maxMinute = max.hour * 60 + max.min
            if minMinute <= maxMinute {
                return minJulian..<maxJulian + 1
            } else {
                assertionFailure("时间设置不合规")
                return 0..<1
            }
        } else {
            assertionFailure("时间设置不合规")
            return 0..<1
        }
    }
}
