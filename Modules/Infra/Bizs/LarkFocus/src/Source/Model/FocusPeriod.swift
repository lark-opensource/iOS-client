//
//  FocusPeriod.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2021/9/8.
//

import Foundation
import LarkTimeFormatUtils
import LarkFocusInterface

enum FocusPeriod {
    case minutes30
    case hour1
    case hour2
    case hour4
    case untilTonight
    /// 用户设置的自定义时间
    case customized(time: Date?)
    /// 系统预设的时间（无法自定义）
    case preset(time: Date?)
    case noEndTime

    var rawValue: Int {
        switch self {
        case .minutes30:    return 0
        case .hour1:        return 1
        case .hour2:        return 2
        case .hour4:        return 3
        case .untilTonight: return 4
        case .customized:   return 5
        case .preset:       return 6
        case .noEndTime:    return 7
        }
    }

    func name(is24Hour: Bool) -> String {
        switch self {
        case .minutes30:
            return BundleI18n.LarkFocus.Lark_Profile_ThirtyMins
        case .hour1:
            return BundleI18n.LarkFocus.Lark_Profile_AnHour
        case .hour2:
            return BundleI18n.LarkFocus.Lark_Profile_TwoHours
        case .hour4:
            return BundleI18n.LarkFocus.Lark_Profile_FourHours
        case .untilTonight:
            return BundleI18n.LarkFocus.Lark_Profile_UntilTonight
        case .customized(let date):
            guard let date = date else {
                // 没有结束时间，显示“其他时间”
                return BundleI18n.LarkFocus.Lark_Profile_OtherTimes
            }
            guard date != Date.distantFuture else {
                // 无限远的时间，只显示 “已开启“ or ”至会议结束”
                return BundleI18n.LarkFocus.Lark_Profile_StatusEndTimeTillMeetingEnds_Option
            }
            // 正常的结束时间，显示“持续至XX:XX”
            return BundleI18n.LarkFocus.Lark_Profile_LastUntilTime(date.readableString(is24Hour: is24Hour))
        case .preset(let date):
            guard let date = date else {
                // 没有结束时间，显示“其他时间”
                return BundleI18n.LarkFocus.Lark_Profile_OtherTimes
            }
            // 正常的结束时间，显示“至XX:XX”
            return BundleI18n.LarkFocus.Lark_Profile_UntilTime(date.readableString(is24Hour: is24Hour))
        case .noEndTime:
            return BundleI18n.LarkFocus.Lark_Core_SelectAStatusDuringFocus_NoEndingTime_Text
        }
    }

    var endTime: Date? {
        switch self {
        case .minutes30:
            return Date().later(timeInterval: 30 * 60)
        case .hour1:
            return Date().later(timeInterval: 60 * 60)
        case .hour2:
            return Date().later(timeInterval: 2 * 60 * 60)
        case .hour4:
            return Date().later(timeInterval: 4 * 60 * 60)
        case .untilTonight:
            return Calendar.current.date(bySettingHour: 23, minute: 59, second: 30, of: Date())!
        case .customized(let date):
            if let date = date {
                return Date(timeInterval: 1, since: date)
            } else {
                return nil
            }
        case .preset(let date):
            if let date = date {
                return Date(timeInterval: 1, since: date)
            } else {
                return nil
            }
        case .noEndTime:
            return nil
        }
    }
}

extension FocusPeriod: CustomStringConvertible {

    var description: String {
        switch self {
        case .minutes30:
            return "30min"
        case .hour1:
            return "1h"
        case .hour2:
            return "2h"
        case .hour4:
            return "4h"
        case .untilTonight:
            return "tonight"
        case .customized(let time):
            return "customized: \(time?.readableString(is24Hour: false) ?? "unknown")"
        case .preset(let time):
            return "preset: \(time?.readableString(is24Hour: false) ?? "unknown")"
        case .noEndTime:
            return "no ending time"
        }
    }
}

extension Date {

    /// User’s current calendar.
    var calendar: Calendar {
        return Calendar(identifier: Calendar.current.identifier)
    }

    var nextDay: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: morning)!
    }

    var morning: Date {
        return Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: self)!
    }

    /// Check if date is within today.
    var isInToday: Bool {
        return calendar.isDateInToday(self)
    }

    /// Check if date is within the current week.
    var isInCurrentWeek: Bool {
        return calendar.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }

    /// Check if date is within the current month.
    var isInCurrentMonth: Bool {
        return calendar.isDate(self, equalTo: Date(), toGranularity: .month)
    }

    /// Check if date is within the current year.
    var isInCurrentYear: Bool {
        return calendar.isDate(self, equalTo: Date(), toGranularity: .year)
    }

    /// 未来一小时，分钟以 5 分钟档位向上取整。
    ///
    ///   - 小时：当前的小时数往后一个格
    ///   - 分钟：当前分钟数往后一格
    ///   - 举例：当前时间为今天13：46-->自定义预设的时间为今天14：50
    var futureHour: Date {
        var components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second, .nanosecond],
            from: self)
        guard let hour = components.hour, let min = components.minute else {
            return self
        }
        components.hour = hour + 1
        components.minute = (min % 5 == 0 ? min / 5 : min / 5 + 1) * 5
        components.second = 0
        components.nanosecond = 0
        return calendar.date(from: components) ?? self
    }

    var rounded: Date {
        var components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second, .nanosecond],
            from: self)
        guard var seconds = components.second else {
            return self
        }
        if seconds <= 5 {
            seconds = 0
        } else if seconds >= 55 {
            seconds = 60
        }
        components.second = seconds
        components.nanosecond = 0
        return calendar.date(from: components) ?? self
    }

    func later(timeInterval: TimeInterval) -> Date {
        let now = Calendar.current.date(bySetting: .second, value: 30, of: self) ?? self
        return now.addingTimeInterval(timeInterval)
    }

    // Cyberpunk 2077，表示无限远的时间，用于不知道结束时间的场景
    static let distantFuture: Date = Date(timeIntervalSince1970: 3376656000)
}

extension UserFocusStatus {

    /// 当前状态生效的时间段（nil 表示当前未生效）
    var selectedPeriod: FocusPeriod? {
        guard isActive else { return nil }
        // 固定结束时间的系统状态（如请假中）
        if isSystemStatus {
            let endTime = systemValidInterval.endTime
            return .preset(time: FocusUtils.shared.getRelatedLocalTime(asServer: endTime))
        }
        if effectiveInterval.isOpenWithoutEndTime {
            return .noEndTime
        }
        // 不显示结束时间（视频会议等状态结束时间不确定）
        if !effectiveInterval.isShowEndTime {
            return .customized(time: Date.distantFuture)
        }
        // 自定义结束时间
        if hasLastCustomizedEndTime, lastCustomizedEndTime > 0 {
            return .customized(time: FocusUtils.shared.getRelatedLocalTime(asServer: lastCustomizedEndTime))
        }
        // 预设时间段（30分钟、1小时、2小时、4小时）
        switch lastSelectedDuration {
        case .minutes30:    return .minutes30
        case .hour1:        return .hour1
        case .hour2:        return .hour2
        case .hour4:        return .hour4
        case .untilTonight: return .untilTonight
        @unknown default:   return .hour1
        }
    }

    /// 上次选中的默认生效时间（不包括自定义时间段，用于快捷开启个人状态）
    internal var defaultPeriod: FocusPeriod {
        if isSystemStatus {
            let endTime = systemValidInterval.endTime
            return .preset(time: FocusUtils.shared.getRelatedLocalTime(asServer: endTime))
        }
        switch lastSelectedDuration {
        case .minutes30:    return .minutes30
        case .hour1:        return .hour1
        case .hour2:        return .hour2
        case .hour4:        return .hour4
        case .untilTonight: return .untilTonight
        @unknown default:   return .hour1
        }
    }

    internal var availablePeriods: [FocusPeriod] {
        if self.isSystemStatus {
            return getAvailablePeriodForSpecialStatus()
        } else {
            return getAvailablePeriodForGeneralStatus()
        }
    }

    private func getAvailablePeriodForSpecialStatus() -> [FocusPeriod] {
        let validDate = FocusUtils.shared.getRelatedLocalTime(asServer: systemValidInterval.endTime)
        return [.preset(time: validDate)]
    }

    private func getAvailablePeriodForGeneralStatus() -> [FocusPeriod] {
        var periods: [FocusPeriod] = [
            .minutes30,
            .hour1,
            .hour2,
            .hour4,
            .untilTonight
        ]
        let curTime = FocusUtils.shared.currentServerTime
        if effectiveInterval.isOpenWithoutEndTime {
            periods.append(.noEndTime)
        } else if hasLastCustomizedEndTime, lastCustomizedEndTime > curTime {
            if !effectiveInterval.isShowEndTime {
                periods.append(.customized(time: Date.distantFuture))
            } else {
                let validDate = FocusUtils.shared.getRelatedLocalTime(asServer: lastCustomizedEndTime)
                periods.append(.customized(time: validDate))
            }
        } else {
            periods.append(.customized(time: nil))
        }
        return periods
    }
}

// MARK: - Date Formatting

extension Date {

    func readableString(is24Hour: Bool) -> String {
        getReadableString(round: false, is24Hour: is24Hour)
    }

    func getReadableString(round: Bool, is24Hour: Bool) -> String {
        let date = round ? self.rounded : self
        if isInToday {
            // 同一天内，只显示时/分
            let option = Options(
                is12HourStyle: !is24Hour,
                timePrecisionType: .minute
            )
            return TimeFormatUtils.formatTime(from: date, with: option)
        } else if isInCurrentYear {
            // 同一年内，显示月/日/时/分
            let option = Options(
                is12HourStyle: !is24Hour,
                timeFormatType: .short,
                timePrecisionType: .minute,
                datePrecisionType: .day,
                dateStatusType: .absolute,
                shouldRemoveTrailingZeros: false
            )
            return TimeFormatUtils.formatDateTime(from: date, with: option)
        } else {
            // 不同年份，显示年/月/日/时/分
            let option = Options(
                is12HourStyle: !is24Hour,
                timeFormatType: .long,
                timePrecisionType: .minute,
                datePrecisionType: .day,
                dateStatusType: .absolute,
                shouldRemoveTrailingZeros: false
            )
            return TimeFormatUtils.formatDateTime(from: date, with: option)
        }
    }
}
