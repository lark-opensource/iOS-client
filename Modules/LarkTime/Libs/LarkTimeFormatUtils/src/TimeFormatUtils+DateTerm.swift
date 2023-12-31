//
//  DateTerm.swift
//  LarkTimeFormatUtils
//
//  Created by Miao Cai on 2020/9/7.
//

import Foundation
import LarkLocalizations

extension TimeFormatUtils {
    /// Return ordinal string of day according to the number.
    /// - Parameter number: the ordinal number of day in the specific month.
    public static func ordinalDayString(number: Int, lang: Lang? = nil) -> String {
        guard number >= 1, number <= 31 else {
            assertionFailure("Invalid ordinal number")
            return ""
        }
        let map: [Int: String] = [
            1: BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_Day1(lang: lang),
            2: BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_Day2(lang: lang),
            3: BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_Day3(lang: lang),
            4: BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_Day4(lang: lang),
            5: BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_Day5(lang: lang),
            6: BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_Day6(lang: lang),
            7: BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_Day7(lang: lang),
            8: BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_Day8(lang: lang),
            9: BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_Day9(lang: lang),
            10: BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_Day10(lang: lang),
            11: BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_Day11(lang: lang),
            12: BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_Day12(lang: lang),
            13: BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_Day13(lang: lang),
            14: BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_Day14(lang: lang),
            15: BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_Day15(lang: lang),
            16: BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_Day16(lang: lang),
            17: BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_Day17(lang: lang),
            18: BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_Day18(lang: lang),
            19: BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_Day19(lang: lang),
            20: BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_Day20(lang: lang),
            21: BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_Day21(lang: lang),
            22: BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_Day22(lang: lang),
            23: BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_Day23(lang: lang),
            24: BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_Day24(lang: lang),
            25: BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_Day25(lang: lang),
            26: BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_Day26(lang: lang),
            27: BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_Day27(lang: lang),
            28: BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_Day28(lang: lang),
            29: BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_Day29(lang: lang),
            30: BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_Day30(lang: lang),
            31: BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_Day31(lang: lang)
        ]

        return map[number] ?? ""

    }

    /// Return abbreviation string of the month.
    /// - Parameter month: the ordinal number of month in the specific year.
    public static func monthAbbrString(month: Int, lang: Lang? = nil) -> String {
       // 显示月份的缩写
        guard month >= 1, month <= 12 else {
          assertionFailure("Invalid abbreviation string of the month")
          return " "
        }
        switch month {
        case 1:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthJanAbbr(lang: lang)
        case 2:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthFebAbbr(lang: lang)
        case 3:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthMarAbbr(lang: lang)
        case 4:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthAprAbbr(lang: lang)
        case 5:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthMayAbbr(lang: lang)
        case 6:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthJuneAbbr(lang: lang)
        case 7:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthJulyAbbr(lang: lang)
        case 8:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthAugAbbr(lang: lang)
        case 9:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthSeptAbbr(lang: lang)
        case 10:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthOctAbbr(lang: lang)
        case 11:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthNovAbbr(lang: lang)
        case 12:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthDecAbbr(lang: lang)
        default:
            assertionFailure("Invalid abbreviation string of the month")
            return ""
        }
    }

    /// Return full string of the month.
    /// - Parameter month: the ordinal number of month in the specific year.
    public static func monthFullString(month: Int, lang: Lang? = nil) -> String {
       // 显示月份的全写
        guard month >= 1, month <= 12 else {
          assertionFailure("Invalid full string of the month")
          return " "
        }
        switch month {
        case 1:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthJanFull(lang: lang)
        case 2:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthFebFull(lang: lang)
        case 3:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthMarFull(lang: lang)
        case 4:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthAprFull(lang: lang)
        case 5:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthMayFull(lang: lang)
        case 6:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthJuneFull(lang: lang)
        case 7:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthJulyFull(lang: lang)
        case 8:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthAugFull(lang: lang)
        case 9:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthSeptFull(lang: lang)
        case 10:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthOctFull(lang: lang)
        case 11:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthNovFull(lang: lang)
        case 12:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthDecFull(lang: lang)
        default:
            assertionFailure("Invalid full string of the month")
            return ""
        }
    }

    /// Return abbreviation string of the weekday.
    /// - Parameter weekday: the ordinal number of weekday in the specific week.
    public static func weekdayAbbrString(weekday: Int, lang: Lang? = nil) -> String {
        // 一、二、三、四、五、六、日
        // Sun, Mon, Tue, Wed,Thu, Fri, Sat
        guard weekday >= 1, weekday <= 7 else {
            assertionFailure("Invalid abbreviation string of the weekday")
            return " "
        }
        switch weekday {
        case 1:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdaySunAbbr(lang: lang)
        case 2:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayMonAbbr(lang: lang)
        case 3:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayTueAbbr(lang: lang)
        case 4:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayWedAbbr(lang: lang)
        case 5:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayThuAbbr(lang: lang)
        case 6:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayFriAbbr(lang: lang)
        case 7:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdaySatAbbr(lang: lang)
        default:
            assertionFailure("Invalid abbreviation string of the weekday")
            return " "
        }
    }

    /// Return short string of the weekday.
    /// - Parameter weekday: the ordinal number of weekday in the specific week.
    public static func weekdayShortString(weekday: Int, lang: Lang? = nil) -> String {
       // 周一、周二、周三、周四、周五、周六、周日
       // Sun, Mon, Tue, Wed,Thu, Fri, Sat
        guard weekday >= 1, weekday <= 7 else {
          assertionFailure("Invalid short string of the weekday")
          return " "
        }
        switch weekday {
        case 1:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdaySunShort(lang: lang)
        case 2:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayMonShort(lang: lang)
        case 3:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayTueShort(lang: lang)
        case 4:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayWedShort(lang: lang)
        case 5:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayThuShort(lang: lang)
        case 6:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayFriShort(lang: lang)
        case 7:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdaySatShort(lang: lang)
        default:
            assertionFailure("Invalid short string of the weekday")
            return " "
        }
    }

    /// Return full string of the weekday.
    /// - Parameter weekday: the ordinal number of weekday in the specific week.
    public static func weekdayFullString(weekday: Int, lang: Lang? = nil) -> String {
        // 周一、周二、周三、周四、周五、周六、周日
        // Sunday, Monday, Tuesday, Wednesday,Thursday, Friday, Saturday
        guard weekday >= 1, weekday <= 7 else {
          assertionFailure("Invalid full string of the weekday")
          return " "
        }
        switch weekday {
        case 1:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdaySunFull(lang: lang)
        case 2:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayMonFull(lang: lang)
        case 3:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayTueFull(lang: lang)
        case 4:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayWedFull(lang: lang)
        case 5:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayThuFull(lang: lang)
        case 6:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayFriFull(lang: lang)
        case 7:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdaySatFull(lang: lang)
        default:
            assertionFailure("Invalid full string of the weekday")
            return ""
        }
    }
}

extension TimeFormatUtils {
    public enum MonthsOfYearType: Int {
        /// Months of the year
        case jan, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dec
    }

    public enum DaysOfWeekType: Int {
        /// Days of the week.
        case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
    }

    /// Return abbreviation string of the month.
    /// - Parameter month: the specified month in the year.
    public static func monthAbbrString(month: MonthsOfYearType, lang: Lang? = nil) -> String {
       // 显示月份的缩写
        switch month {
        case .jan:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthJanAbbr(lang: lang)
        case .feb:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthFebAbbr(lang: lang)
        case .mar:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthMarAbbr(lang: lang)
        case .apr:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthAprAbbr(lang: lang)
        case .may:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthMayAbbr(lang: lang)
        case .jun:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthJuneAbbr(lang: lang)
        case .jul:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthJulyAbbr(lang: lang)
        case .aug:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthAugAbbr(lang: lang)
        case .sep:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthSeptAbbr(lang: lang)
        case .oct:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthOctAbbr(lang: lang)
        case .nov:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthNovAbbr(lang: lang)
        case .dec:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthDecAbbr(lang: lang)
        }
    }

    /// Return full string of the month.
    /// - Parameter month: the specified month in the year.
    public static func monthFullString(month: MonthsOfYearType, lang: Lang? = nil) -> String {
       // 显示月份的全写
        switch month {
        case .jan:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthJanFull(lang: lang)
        case .feb:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthFebFull(lang: lang)
        case .mar:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthMarFull(lang: lang)
        case .apr:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthAprFull(lang: lang)
        case .may:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthMayFull(lang: lang)
        case .jun:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthJuneFull(lang: lang)
        case .jul:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthJulyFull(lang: lang)
        case .aug:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthAugFull(lang: lang)
        case .sep:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthSeptFull(lang: lang)
        case .oct:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthOctFull(lang: lang)
        case .nov:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthNovFull(lang: lang)
        case .dec:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_MonthDecFull(lang: lang)
        }
    }

    /// Return abbreviation string of the weekday.
    /// - Parameter day: the specified day in the week.
    public static func weekdayAbbrString(day: DaysOfWeekType, lang: Lang? = nil) -> String {
        // 一、二、三、四、五、六、日
        // Sun, Mon, Tue, Wed,Thu, Fri, Sat
        switch day {
        case .sunday:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdaySunAbbr(lang: lang)
        case .monday:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayMonAbbr(lang: lang)
        case .tuesday:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayTueAbbr(lang: lang)
        case .wednesday:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayWedAbbr(lang: lang)
        case .thursday:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayThuAbbr(lang: lang)
        case .friday:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayFriAbbr(lang: lang)
        case .saturday:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdaySatAbbr(lang: lang)
        }
    }

    /// Return short string of the weekday.
    /// - Parameter day: the specified day in the week.
    public static func weekdayShortString(day: DaysOfWeekType, lang: Lang? = nil) -> String {
       // 周一、周二、周三、周四、周五、周六、周日
       // Sun, Mon, Tue, Wed,Thu, Fri, Sat
        switch day {
        case .sunday:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdaySunShort(lang: lang)
        case .monday:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayMonShort(lang: lang)
        case .tuesday:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayTueShort(lang: lang)
        case .wednesday:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayWedShort(lang: lang)
        case .thursday:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayThuShort(lang: lang)
        case .friday:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayFriShort(lang: lang)
        case .saturday:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdaySatShort(lang: lang)
        }
    }

    /// Return full string of the weekday.
    /// - Parameter day: the specified day in the week.
    public static func weekdayFullString(day: DaysOfWeekType, lang: Lang? = nil) -> String {
        // 周一、周二、周三、周四、周五、周六、周日
        // Sunday, Monday, Tuesday, Wednesday,Thursday, Friday, Saturday
        switch day {
        case .sunday:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdaySunFull(lang: lang)
        case .monday:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayMonFull(lang: lang)
        case .tuesday:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayTueFull(lang: lang)
        case .wednesday:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayWedFull(lang: lang)
        case .thursday:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayThuFull(lang: lang)
        case .friday:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdayFriFull(lang: lang)
        case .saturday:
            return BundleI18n.LarkTimeFormatUtils.Calendar_StandardTime_WeekdaySatFull(lang: lang)
        }
    }
}
