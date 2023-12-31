//
//  EKRecurrenceRule+recurrenceRuleFromString.swift
//  EKRecurrenceRuleStringExtension
//
//  Created by Takayama Kyosuke on 2016/04/04.
//  Copyright © 2016年 aill inc. All rights reserved.
//

// Included OSS：EKRecurrenceRuleStringExtension
// Copyright © 2016年 aill inc.
// spdx license identifier: MIT

import Foundation
import EventKit
import RxSwift

extension EKRecurrenceRule {

   open class func recurrenceRuleFromString(_ ruleString: String) -> EKRecurrenceRule? {
      let parser = RecurrenceParser(ruleString: NSString(string: ruleString))

      guard let type = parser.type else {
         return nil
      }

       let rrule = self.init(recurrenceWith: type,
                             interval: parser.interval,
                             daysOfTheWeek: parser.days,
                             daysOfTheMonth: parser.monthDays,
                             monthsOfTheYear: parser.months,
                             weeksOfTheYear: parser.weeksOfTheYear,
                             daysOfTheYear: parser.daysOfTheYear,
                             setPositions: parser.setPositions,
                             end: parser.end)
       if let firstDayOfTheWeek = parser.firstDayOfTheWeek {
           rrule.setValuesForKeys(["firstDayOfTheWeek": firstDayOfTheWeek])
       }

       return rrule
   }

}

struct RecurrenceParser {

   let ruleString: NSString

   var interval: Int {
      let intervalArray = self.ruleString.components(separatedBy: "INTERVAL=")

      if intervalArray.count > 1 {
         if let intervalString = intervalArray.last?.components(separatedBy: ";").first {
            return Int(intervalString) ?? 1
         }
      }

      return 1
   }

   var type: EKRecurrenceFrequency? {
      if self.ruleString.contains("FREQ=DAILY") {
         return .daily
      } else if self.ruleString.contains("FREQ=WEEKLY") {
         return .weekly
      } else if self.ruleString.contains("FREQ=MONTHLY") {
         return .monthly
      } else if self.ruleString.contains("FREQ=YEARLY") {
         return .yearly
      } else {
         return nil
      }
   }

   var end: EKRecurrenceEnd? {
      let untilArray = self.ruleString.components(separatedBy: "UNTIL=")

      if untilArray.count > 1 {
         if let recurrenceEndDateString = untilArray.last!.components(separatedBy: ";").first {
            let recurrenceDateFormatter = EKRecurrenceRule.generateEndDateFormatter(containsT: recurrenceEndDateString.contains("T"))
            if let recurrenceEndDate = recurrenceDateFormatter.date(from: recurrenceEndDateString) {
               return EKRecurrenceEnd(end: recurrenceEndDate)
            }
         }
      } else {
         if let count = (processRegexp("COUNT=([\\d,-]*)") as [NSNumber]?)?.first {
            return EKRecurrenceEnd(occurrenceCount: count.intValue)
         }
      }

      return nil
   }

   // BYDAY => days
   var days: [EKRecurrenceDayOfWeek]? {
      guard var bydays: [NSString] =
        processRegexp("BYDAY=(([-+]?\\d{0,2}(SU|MO|TU|WE|TH|FR|SA|su|mo|tu|we|th|fr|sa),?)+)")
        else {
         return nil
      }
      bydays = bydays.map({
        $0.replacingOccurrences(of: "+", with: "")
      }) as [NSString]

      var days = [EKRecurrenceDayOfWeek]()

      for byday in bydays {
         var week = byday
         var weekNumber = -1

         if byday.length > 2 {
            weekNumber = Int(byday.substring(with: NSRange(location: 0, length: byday.length - 2))) ?? -100
            week = byday.substring(with: NSRange(location: byday.length - 2, length: 2)) as NSString
         }

         var dofw: EKWeekday?

        switch week {
        case "MO": dofw = .monday
        case "TU": dofw = .tuesday
        case "WE": dofw = .wednesday
        case "TH": dofw = .thursday
        case "FR": dofw = .friday
        case "SA": dofw = .saturday
        case "SU": dofw = .sunday
        default: dofw = nil
        }

         if let dofw = dofw {
            let dow = weekNumber > 0 ?
                EKRecurrenceDayOfWeek(dayOfTheWeek: dofw, weekNumber: weekNumber) :
                EKRecurrenceDayOfWeek(dofw)
            days.append(dow)
         }
      }

      return days
   }

   // BYMONTHDAY => monthDays
   var monthDays: [NSNumber]? {
      return processRegexp("BYMONTHDAY=([\\d,-]*)")
   }

   // BYMONTH => months
   var months: [NSNumber]? {
      return processRegexp("BYMONTH=([\\d,]*)")
   }

   // BYWEEKNO => weeksOfTheYear
   var weeksOfTheYear: [NSNumber]? {
      return processRegexp("BYWEEKNO=([\\d,-]*)")
   }

   // BYYEARDAY => daysOfTheYear
   var daysOfTheYear: [NSNumber]? {
      return processRegexp("BYYEARDAY=([\\d,-]*)")
   }

   // BYSETPOS => setPositions
   var setPositions: [NSNumber]? {
      return processRegexp("BYSETPOS=([\\d,-]*)")
   }

    var firstDayOfTheWeek: Int? {
        if self.ruleString.contains("WKST=SU") {
            return 1
        } else if self.ruleString.contains("WKST=MO") {
            return 2
        } else if self.ruleString.contains("WKST=TU") {
            return 3
        } else if self.ruleString.contains("WKST=WE") {
            return 4
        } else if self.ruleString.contains("WKST=TH") {
            return 5
        } else if self.ruleString.contains("WKST=FR") {
            return 6
        } else if self.ruleString.contains("WKST=SA") {
            return 7
        } else {
            return nil
        }
    }

   fileprivate func processRegexp(_ regexString: String) -> [NSString]? {
      let reg = try? NSRegularExpression(pattern: regexString, options: .caseInsensitive)
      if let match = reg?.firstMatch(in: String(self.ruleString),
                                           options: .reportProgress,
                                           range: NSRange(location: 0, length: self.ruleString.length)) {
        return self.ruleString.substring(with: match.range(at: 1)).components(separatedBy: ",") as [NSString]?
      }
      return nil
   }

   fileprivate func processRegexp(_ regexString: String) -> [NSNumber]? {
      guard let results: [NSString] = processRegexp(regexString) else {
         return nil
      }
      return results.map { NSNumber(value: $0.intValue) }
   }
}

public struct ReadableRRule {
    /// nl全部的重复性
    public let fullSentance: String
    /// nl中重复规则的部分
    public let repeatPart: String
    /// nl中截止日期的部分
    public let untilPart: String

    public init(fullSentance: String,
                repeatPart: String,
                untilPart: String) {
        self.fullSentance = fullSentance
        self.repeatPart = repeatPart
        self.untilPart = untilPart
    }
}

extension EKRecurrenceRule {
    public static var snycGetReadableRruleGetter: (() -> ((_ rrule: String, _ timezone: String) -> Observable<ReadableRRule>)?)?
    public func getReadableString() -> String {
        getReadableString(timezone: "")
    }

    public func getReadableString(timezone: String) -> String {
        let rrule = iCalendarString()
        var result = ""
        var disposeBag = DisposeBag()
        EKRecurrenceRule.snycGetReadableRruleGetter?()?(rrule, timezone).subscribe(onNext: { (readableRrule) in
            result = readableRrule.fullSentance
            disposeBag = DisposeBag()
        }).disposed(by: disposeBag)
        return result
    }

    // 获取重复性描述，用于埋点，输出如下：
    /// 1. daily：每天
    /// 2. weekly：每周
    /// 3. monthly：每月
    /// 4. yearly：每年
    /// 5. working_days：每个工作日
    /// 6. customize：自定义
    public func getFrequencyDesciption() -> String {
        switch self.frequency {
        case .daily:
            if interval == 1 {
                return "daily"
            }
            return "customize"
        case .weekly:
            if interval == 1, (daysOfTheWeek == nil) || daysOfTheWeek?.isEmpty == true {
                return "weekly"
            }
            // 判断是否是每个工作日
            let workingDaysOfWeek: [EKWeekday] = [.monday, .tuesday, .wednesday, .thursday, .friday]
            if interval == 1, daysOfTheWeek?.map({ $0.dayOfTheWeek }) == workingDaysOfWeek {
                return "working_days"
            }
            return "customize"
        case .monthly:
            if interval == 1, (daysOfTheMonth == nil) || daysOfTheMonth?.isEmpty == true {
                return "monthly"
            }
            return "customize"
        case .yearly:
            if interval == 1, (daysOfTheYear == nil) || daysOfTheYear?.isEmpty == true {
                return "yearly"
            }
            return "customize"
        @unknown default:
            return ""
        }
    }

    public func getReadableRecurrenceRepeatString(timezone: String) -> String {
        let rrule = iCalendarString()
        var result = ""
        var disposeBag = DisposeBag()
        EKRecurrenceRule.snycGetReadableRruleGetter?()?(rrule, timezone).subscribe(onNext: { (readableRrule) in
            result = readableRrule.repeatPart
            disposeBag = DisposeBag()
        }).disposed(by: disposeBag)
        return result
    }

    public func getReadableRecurrenceEndString(timezone: String) -> String {
        let rrule = iCalendarString()
        var result = ""
        var disposeBag = DisposeBag()
        EKRecurrenceRule.snycGetReadableRruleGetter?()?(rrule, timezone).subscribe(onNext: { (readableRrule) in
            result = readableRrule.untilPart
            disposeBag = DisposeBag()
        }).disposed(by: disposeBag)
        return result
    }

    public func repeatEndtimeDisplayText(timezone: String) -> (String, Bool) {
        if let recurrenceEnd = self.recurrenceEnd, recurrenceEnd.occurrenceCount != 0 {
            return (BundleI18n.Calendar.Calendar_RRule_NeverEnds, false)
        }
        if self.recurrenceEnd?.endDate == nil {
            return (BundleI18n.Calendar.Calendar_RRule_NeverEnds, true)
        }

        return (self.getReadableRecurrenceEndString(timezone: timezone), true)
    }

}
