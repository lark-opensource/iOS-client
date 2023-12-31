//
//  RRule.swift
//  CTFoundation
//
//  Created by 白言韬 on 2022/2/9.
//

import UIKit
import Foundation
import EventKit
import CalendarFoundation

public struct RRule { }

extension RRule {
    enum UIStyle {}

    public enum FirstWeekday {
        case saturday
        case sunday
        case monday
    }
}

extension RRule.UIStyle {
    enum Color {
        static let blueText = UIColor.ud.primaryContentDefault
        static let horizontalSeperator = UIColor.ud.lineDividerDefault
        static let normalText = UIColor.ud.textTitle
    }

    enum Layout {
        static let secondaryPageCellHeight = CGFloat(48)
        static let horizontalSeperatorHeight = CGFloat(1.0 / UIScreen.main.scale)
    }
}

extension EKRecurrenceRule {
    open func parseToString(firstWeekday: RRule.FirstWeekday? = nil) -> String {
        var ret = self.description.components(separatedBy: " RRULE ")[1]
        if let firstWeekday = firstWeekday {
            ret = fixFirstWeekDay(ret, firstWeekday)
        }
        return ret
    }

    private func fixFirstWeekDay(_ val: String, _ firstWeekday: RRule.FirstWeekday) -> String {
        guard let range = val.range(of: "WKST=SU") else {
            return val
        }
        switch firstWeekday {
        case .saturday:
            return val.replacingCharacters(in: range, with: "WKST=SA")
        case .monday:
            return val.replacingCharacters(in: range, with: "WKST=MO")
        default:
            return val
        }
    }
}

extension EKRecurrenceRule {

   open class func parseToRRule(with ruleString: String) -> EKRecurrenceRule? {
      let parser = RecurrenceParser(ruleString: NSString(string: ruleString))

      guard let type = parser.type else {
         return nil
      }

      return self.init(recurrenceWith: type,
         interval: parser.interval,
         daysOfTheWeek: parser.days,
         daysOfTheMonth: parser.monthDays,
         monthsOfTheYear: parser.months,
         weeksOfTheYear: parser.weeksOfTheYear,
         daysOfTheYear: parser.daysOfTheYear,
         setPositions: parser.setPositions,
         end: parser.end)
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
