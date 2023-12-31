//
//  EKRecurrenceRule+iCalendar.swift
//  EKRecurrenceRuleStringExtension
//
//  Created by Takayama Kyosuke on 2016/04/04.
//  Copyright © 2016年 aill inc. All rights reserved.
//

import Foundation
import EventKit

extension EKRecurrenceRule {

    public func stringForICalendar() -> String {
        let ret = fixFirstWeekDay(self.description)
        return "RRULE " + ret.components(separatedBy: " RRULE ")[1]
    }

    public func iCalendarString() -> String {
        let ret = fixRrule(self.description)
        return ret.components(separatedBy: " RRULE ")[1]
    }

    private func fixRrule(_ rruleString: String) -> String {
        let systemString = rruleString
        let fixWeekDayString = fixFirstWeekDay(systemString)
        let fixUntilString = fixUntil(fixWeekDayString, endDate: self.recurrenceEnd?.endDate)
        return fixUntilString
    }

    private func fixFirstWeekDay(_ val: String) -> String {
        guard let range = val.range(of: "WKST=SU") else {
            return val
        }
        switch firstDayOfTheWeek {
        case 1:
            return val.replacingCharacters(in: range, with: "WKST=SU")
        case 2:
            return val.replacingCharacters(in: range, with: "WKST=MO")
        case 3:
            return val.replacingCharacters(in: range, with: "WKST=TU")
        case 4:
            return val.replacingCharacters(in: range, with: "WKST=WE")
        case 5:
            return val.replacingCharacters(in: range, with: "WKST=TH")
        case 6:
            return val.replacingCharacters(in: range, with: "WKST=FR")
        case 7:
            return val.replacingCharacters(in: range, with: "WKST=SA")
        default:
            return val
        }
    }

    public func setFirstWeekDay(_ val: Int) {
        guard (0...7).contains(val) else {
            assertionFailureLog("set firstWeekDay out of range")
            return
        }
        self.setValuesForKeys(["firstDayOfTheWeek": val])
    }

    // 在iOS15.4及以上的系统，系统设置12小时情况下， rrule.description 的UNTIL字段会有问题（带上下午）： 如UNTIL=20240730T上午30540Z
    // 需要手动转换时间格式，并且设置Locale， 这里手动替换UNTIL字段的内容
    private func fixUntil(_ val: String, endDate: Date?) -> String {
        guard let date = endDate else {
            return val
        }

        let components = val.components(separatedBy: ";")
        guard let until = components.first(where: { $0.starts(with: "UNTIL") }) else {
            return val
        }

        let recurrenceDateFormatter = EKRecurrenceRule.generateEndDateFormatter(containsT: val.contains("T"))

        let dateString = recurrenceDateFormatter.string(from: date)

        let fixedUntilString = "UNTIL=" + dateString

        return val.replacingOccurrences(of: until, with: fixedUntilString)

    }
}

extension EKRecurrenceRule {

    // @param containsT: UNTIL格式字符串里是否是 xxxxTxxxxZ 格式
    // 手动生成截止时间格式， iOS 15.4及以上 通过系统description字段生成的结果会有问题
    static public func generateEndDateFormatter(containsT: Bool) -> DateFormatter {
        let recurrenceDateFormatter = DateFormatter()
        recurrenceDateFormatter.locale = Locale(identifier: "US")
        recurrenceDateFormatter.timeZone = TimeZone(identifier: "UTC")
        recurrenceDateFormatter.dateFormat = containsT ? "yyyyMMdd'T'HHmmss'Z'" : "yyyyMMdd"
        return recurrenceDateFormatter
    }
}
